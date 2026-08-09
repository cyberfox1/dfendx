unit NewScreenshotsCacheUnit;

interface

uses Classes, Graphics, ScreenshotsDBUnit;

type
  TScreenshotsCache = class
  private
    FDB: TScreenshotsDB;
    function MakeKey(const FileName: String; W, H: Integer): String;
    function DecompressToBitmap(const Compressed: TMemoryStream): TBitmap;
    function CompressBitmap(const B: TBitmap): TMemoryStream;
    { Aspect-fit Source into W×H cell via WIC (same compose as file CalcThumbnail). }
    function CalcThumbnailFromBitmap(const Source: TBitmap; W, H: Integer; out OrigW, OrigH: Integer): TBitmap;
  public
    { Owns the SQLite store for ADBPath for the lifetime of this object. }
    constructor Create(const ADBPath: String);
    destructor Destroy; override;
    { Cached path: Lookup/Fetch or generate+Store. Caller owns Result. }
    function GetThumbnail(const FileName: String; W, H: Integer): TBitmap;
    { No DB: generate only (old NoCache=True path). Caller owns Result. }
    function GetThumbnailNoCache(const FileName: String; W, H: Integer): TBitmap;
    { Meta only: Lookup; no Fetch/file I/O. False if miss. }
    function GetCachedMeta(const FileName: String; W, H: Integer;
      out FileSize: Int64; out OrigW, OrigH: Integer): Boolean;
    { Same return/ownership as GetThumbnail. Key is caller-defined (not a file path);
      cache id is Key:W:H. Freshness uses Source pixel size (W*H*4); date unused (0).
      NoCache=True: scale only, no Lookup/Fetch/Store. }
    function GetThumbnailFromBitmap(const Source: TBitmap; const Key: String; W, H: Integer;
      const NoCache: Boolean = False): TBitmap;
    procedure Invalidate(const FileName: String);
    function IsCached(const FileName: String; W, H: Integer): Boolean;
    { Scaled thumbnail bitmap; caller owns the result. }
    function CalcThumbnail(const FileName: String; W, H: Integer; out OrigW, OrigH: Integer): TBitmap;
  end;

function MakePathKey(const FullPath: String): String;

{ Owned by the main form for app lifetime; nil if create failed. }
var
  ScreenshotsCache: TScreenshotsCache = nil;

implementation

uses SysUtils, ZLib, CommonHelpers, CommonTools,
     ResampleHelpers, LoggingUnit;

function MakePathKey(const FullPath: String): String;
var
  Expanded: String;
begin
  Expanded := ExpandFileName(FullPath);
  if (Length(Expanded) >= 2) and (Expanded[1] = '\') and (Expanded[2] = '\') then
    Result := Expanded
  else
    Result := Copy(Expanded, 3, MaxInt);
end;

{ TScreenshotsCache }

constructor TScreenshotsCache.Create(const ADBPath: String);
begin
  inherited Create;
  FDB := TScreenshotsDB.Create(ADBPath);
end;

destructor TScreenshotsCache.Destroy;
begin
  FreeAndNil(FDB);
  inherited Destroy;
end;

function TScreenshotsCache.MakeKey(const FileName: String; W, H: Integer): String;
begin
  { Path without drive letter (see MakePathKey), then target size. }
  Result := Format('%s:%d:%d', [MakePathKey(FileName), W, H]);
end;

function TScreenshotsCache.CompressBitmap(const B: TBitmap): TMemoryStream;
var
  BitmapStream: TMemoryStream;
  Compress: TCompressionStream;
begin
  { zlib clFastest — no Snappy/LZ4 in tree; this is the fast built-in level. }
  Result := TMemoryStream.Create;
  BitmapStream := TMemoryStream.Create;
  try
    B.SaveToStream(BitmapStream);
    BitmapStream.Position := 0;
    Compress := TCompressionStream.Create(clFastest, Result);
    try
      if BitmapStream.Size > 0 then
        Compress.Write(BitmapStream.Memory^, BitmapStream.Size);
    finally
      Compress.Free;
    end;
  finally
    BitmapStream.Free;
  end;
end;

function TScreenshotsCache.GetThumbnailNoCache(const FileName: String; W, H: Integer): TBitmap;
var
  OW, OH: Integer;
begin
  { Generate only — no Lookup/Fetch/Store. }
  Result :=  CalcThumbnail(FileName, W, H, OW, OH);
end;

function TScreenshotsCache.GetCachedMeta(const FileName: String; W, H: Integer;
  out FileSize: Int64; out OrigW, OrigH: Integer): Boolean;
var
  StoredDate: TDateTime;
begin
  { Lookup only — no Fetch, no disk. }
  Result := False;
  FileSize := 0;
  OrigW := 0;
  OrigH := 0;
  if FDB = nil then Exit;
  if Trim(FileName) = '' then Exit;
  Result := FDB.Lookup(MakeKey(FileName, W, H), FileSize, StoredDate, OrigW, OrigH);
end;

function TScreenshotsCache.GetThumbnail(const FileName: String; W, H: Integer): TBitmap;
var
  Key: String;
  StoredSize, ActualSize: Int64;
  StoredDate, ActualDate: TDateTime;
  OW, OH: Integer;
  Compressed: TMemoryStream;
begin
  { Hit: Lookup + size/date match + Fetch + decompress.
    Miss/stale/corrupt: CalcThumbnail -> Store -> return bitmap.
    Never raise; return nil if file missing or generation fails. }
  Result := nil;
  try
    if not FileExists(FileName) then Exit;
    if FDB = nil then Exit;

    Key := MakeKey(FileName, W, H);
    ActualSize := GetFileSize(FileName);
    ActualDate := GetFileDate(FileName);

    if FDB.Lookup(Key, StoredSize, StoredDate, OW, OH) then begin
      if (StoredSize = ActualSize) and (Abs(StoredDate - ActualDate) < 1e-6) then begin
        Compressed := FDB.Fetch(Key);
        if Compressed <> nil then
        try
          Result := DecompressToBitmap(Compressed);
          if Result <> nil then
            Exit; { cache hit }
        finally
          Compressed.Free;
        end;
        FDB.Remove(Key);
      end else
        FDB.Remove(Key);
    end;

    Result := CalcThumbnail(FileName, W, H, OW, OH);
    if Result = nil then
      Exit;

    Compressed := CompressBitmap(Result);
    try
      FDB.Store(Key, ActualSize, ActualDate, OW, OH, Compressed);
    finally
      Compressed.Free;
    end;
  except
    on E: Exception do begin
      LogInfo('ScreenshotsCache: GetThumbnail failed file="'+FileName+'" '+E.ClassName+': '+E.Message);
      FreeAndNil(Result);
    end;
  end;
end;

function TScreenshotsCache.IsCached(const FileName: String; W, H: Integer): Boolean;
var
  Key: String;
  StoredSize, ActualSize: Int64;
  StoredDate, ActualDate: TDateTime;
  StoredOrigW, StoredOrigH: Integer;
begin
  Result := False;
  if FDB = nil then Exit;
  if not FileExists(FileName) then Exit;

  Key := MakeKey(FileName, W, H);

  if not FDB.Lookup(Key, StoredSize, StoredDate, StoredOrigW, StoredOrigH) then Exit;

  ActualSize := GetFileSize(FileName);
  ActualDate := GetFileDate(FileName);
  Result := (StoredSize = ActualSize) and (Abs(StoredDate - ActualDate) < 1e-6);
end;

procedure TScreenshotsCache.Invalidate(const FileName: String);
var
  PathKey: String;
begin
  if FDB = nil then Exit;
  PathKey := MakePathKey(FileName);
  FDB.RemoveLike(PathKey + ':%');
end;

function TScreenshotsCache.DecompressToBitmap(const Compressed: TMemoryStream): TBitmap;
var
  DecompStream: TDecompressionStream;
  ImageStream: TMemoryStream;
begin
  ImageStream := TMemoryStream.Create;
  try
    Compressed.Position := 0;
    DecompStream := TDecompressionStream.Create(Compressed);
    try
      ImageStream.CopyFrom(DecompStream, 0);
    finally
      DecompStream.Free;
    end;
    ImageStream.Position := 0;
    Result := TBitmap.Create;
    try
      Result.LoadFromStream(ImageStream);
    except
      on E: Exception do begin
        LogInfo('ScreenshotsCache: DecompressToBitmap load failed: '+E.ClassName+': '+E.Message);
        FreeAndNil(Result);
      end;
    end;
  finally
    ImageStream.Free;
  end;
end;

function TScreenshotsCache.CalcThumbnail(const FileName: String; W, H: Integer; out OrigW, OrigH: Integer): TBitmap;
var
  Wic, Scaled: TWICImage;
  NewW, NewH, X, Y: Integer;
  DrawSrc: TGraphic;
begin
  { Decode/scale via Delphi TWICImage (Windows Imaging Component).
    No LoadImageFromFile / full-res VCL JPEG path. Caller owns Result. }
  Result := nil;
  OrigW := 0;
  OrigH := 0;
  if (W <= 0) or (H <= 0) then Exit;
  try
    Wic := TWICImage.Create;
    try
      Wic.LoadFromFile(FileName);
      if Wic.Empty or (Wic.Width <= 0) or (Wic.Height <= 0) then Exit;
      OrigW := Wic.Width;
      OrigH := Wic.Height;

      CalcWH(Wic.Width, Wic.Height, W, H, NewW, NewH);
      if (NewW <= 0) or (NewH <= 0) then Exit;

      Scaled := nil;
      if (NewW <> Wic.Width) or (NewH <> Wic.Height) then
        Scaled := Wic.CreateScaledCopy(NewW, NewH, wipmFant);
      try
        if Scaled <> nil then DrawSrc := Scaled else DrawSrc := Wic;

        Result := TBitmap.Create;
        try
          Result.PixelFormat := pf24bit;
          Result.SetSize(W, H);
          Result.Canvas.Brush.Style := bsSolid;
          Result.Canvas.Brush.Color := clBlack;
          Result.Canvas.FillRect(Rect(0, 0, W, H));
          X := (W - NewW) div 2;
          Y := (H - NewH) div 2;
          Result.Canvas.Draw(X, Y, DrawSrc);
        except
          on E: Exception do begin
            LogInfo('ScreenshotsCache: WIC compose failed file="'+FileName+'" '+E.ClassName+': '+E.Message);
            FreeAndNil(Result);
          end;
        end;
      finally
        Scaled.Free;
      end;
    finally
      Wic.Free;
    end;
  except
    on E: Exception do begin
      LogInfo('ScreenshotsCache: CalcThumbnail failed file="'+FileName+'" '+E.ClassName+': '+E.Message);
      FreeAndNil(Result);
    end;
  end;
end;

function TScreenshotsCache.CalcThumbnailFromBitmap(const Source: TBitmap; W, H: Integer; out OrigW, OrigH: Integer): TBitmap;
var
  Wic, Scaled: TWICImage;
  NewW, NewH, X, Y: Integer;
  DrawSrc: TGraphic;
begin
  { Same WIC aspect-fit compose as CalcThumbnail; source is in-memory bitmap. }
  Result := nil;
  OrigW := 0;
  OrigH := 0;
  if (Source = nil) or (W <= 0) or (H <= 0) then Exit;
  if (Source.Width <= 0) or (Source.Height <= 0) then Exit;
  OrigW := Source.Width;
  OrigH := Source.Height;
  try
    Wic := TWICImage.Create;
    try
      Wic.Assign(Source);
      if Wic.Empty or (Wic.Width <= 0) or (Wic.Height <= 0) then Exit;

      CalcWH(Wic.Width, Wic.Height, W, H, NewW, NewH);
      if (NewW <= 0) or (NewH <= 0) then Exit;

      Scaled := nil;
      if (NewW <> Wic.Width) or (NewH <> Wic.Height) then
        Scaled := Wic.CreateScaledCopy(NewW, NewH, wipmFant);
      try
        if Scaled <> nil then DrawSrc := Scaled else DrawSrc := Wic;

        Result := TBitmap.Create;
        try
          Result.PixelFormat := pf24bit;
          Result.SetSize(W, H);
          Result.Canvas.Brush.Style := bsSolid;
          Result.Canvas.Brush.Color := clBlack;
          Result.Canvas.FillRect(Rect(0, 0, W, H));
          X := (W - NewW) div 2;
          Y := (H - NewH) div 2;
          Result.Canvas.Draw(X, Y, DrawSrc);
        except
          on E: Exception do begin
            LogInfo('ScreenshotsCache: WIC compose failed bitmap '+E.ClassName+': '+E.Message);
            FreeAndNil(Result);
          end;
        end;
      finally
        Scaled.Free;
      end;
    finally
      Wic.Free;
    end;
  except
    on E: Exception do begin
      LogInfo('ScreenshotsCache: CalcThumbnailFromBitmap failed '+E.ClassName+': '+E.Message);
      FreeAndNil(Result);
    end;
  end;
end;

function TScreenshotsCache.GetThumbnailFromBitmap(const Source: TBitmap; const Key: String;
  W, H: Integer; const NoCache: Boolean): TBitmap;
var
  FullKey: String;
  StoredSize, ActualSize: Int64;
  StoredDate, ActualDate: TDateTime;
  StoredOrigW, StoredOrigH, NewOrigW, NewOrigH: Integer;
  Compressed: TMemoryStream;
  MetaOK: Boolean;
begin
  { Parallel to GetThumbnail: hit Lookup+Fetch, miss CalcThumbnailFromBitmap+Store.
    Key is not path-normalized (caller-defined). ActualSize = W*H*4 of Source. }
  Result := nil;
  try
    if (Source = nil) or (Trim(Key) = '') then Exit;
    if (Source.Width <= 0) or (Source.Height <= 0) then Exit;
    if (W <= 0) or (H <= 0) then Exit;

    if NoCache then begin
      Result := CalcThumbnailFromBitmap(Source, W, H, NewOrigW, NewOrigH);
      Exit;
    end;

    if FDB = nil then Exit;

    FullKey := Format('%s:%d:%d', [Key, W, H]);
    ActualSize := Int64(Source.Width) * Int64(Source.Height) * 4;
    ActualDate := 0;

    MetaOK := FDB.Lookup(FullKey, StoredSize, StoredDate, StoredOrigW, StoredOrigH);
    if MetaOK then begin
      if (StoredSize = ActualSize) and (Abs(StoredDate - ActualDate) < 1e-6) then begin
        Compressed := FDB.Fetch(FullKey);
        if Compressed <> nil then
        try
          Result := DecompressToBitmap(Compressed);
          if Result <> nil then
            Exit;
        finally
          Compressed.Free;
        end;
        FDB.Remove(FullKey);
      end else
        FDB.Remove(FullKey);
    end;

    Result := CalcThumbnailFromBitmap(Source, W, H, NewOrigW, NewOrigH);
    if Result = nil then
      Exit;

    Compressed := CompressBitmap(Result);
    try
      FDB.Store(FullKey, ActualSize, ActualDate, NewOrigW, NewOrigH, Compressed);
    finally
      Compressed.Free;
    end;
  except
    on E: Exception do begin
      LogInfo('ScreenshotsCache: GetThumbnailFromBitmap failed key="'+Key+'" '+E.ClassName+': '+E.Message);
      FreeAndNil(Result);
    end;
  end;
end;

end.
