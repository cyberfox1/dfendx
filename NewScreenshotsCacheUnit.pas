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
  public
    { Owns the SQLite store for ADBPath for the lifetime of this object. }
    constructor Create(const ADBPath: String);
    destructor Destroy; override;
    function GetThumbnail(const FileName: String; W, H: Integer): TBitmap;
    procedure Invalidate(const FileName: String);
    function IsCached(const FileName: String; W, H: Integer): Boolean;
    { Scaled thumbnail bitmap; caller owns the result. }
    function CalcThumbnail(const FileName: String; W, H: Integer): TBitmap;
  end;

function MakePathKey(const FullPath: String): String;

{ Owned by the main form for app lifetime; nil if create failed. }
var
  ScreenshotsCache: TScreenshotsCache = nil;

implementation

uses SysUtils, ZLib, CommonHelpers, CommonTools,
     ResampleHelpers, ImageStretch, LoggingUnit;

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

function TScreenshotsCache.GetThumbnail(const FileName: String; W, H: Integer): TBitmap;
var
  Key: String;
  StoredSize, ActualSize: Int64;
  StoredDate, ActualDate: TDateTime;
  Compressed: TMemoryStream;
  MetaOK: Boolean;
begin
  { Hit: Lookup + size/date match + Fetch + decompress.
    Miss/stale/corrupt: CalcThumbnail (bitmap) -> compress once for Store -> return bitmap.
    Never raise; return nil if file missing or generation fails. }
  Result := nil;
  try
    if FDB = nil then Exit;
    if not FileExists(FileName) then Exit;

    Key := MakeKey(FileName, W, H);
    ActualSize := GetFileSize(FileName);
    ActualDate := GetFileDate(FileName);

    MetaOK := FDB.Lookup(Key, StoredSize, StoredDate);
    if MetaOK then begin
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

    Result := CalcThumbnail(FileName, W, H);
    if Result = nil then
      Exit;

    Compressed := CompressBitmap(Result);
    try
      FDB.Store(Key, ActualSize, ActualDate, Compressed);
    finally
      Compressed.Free;
    end;
    { Result is the scaled bitmap — no decompress on miss. }
  except
    { Swallow EJPEG / IO errors so profile select cannot crash. }
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
begin
  Result := False;
  if FDB = nil then Exit;
  if not FileExists(FileName) then Exit;

  Key := MakeKey(FileName, W, H);

  if not FDB.Lookup(Key, StoredSize, StoredDate) then Exit;

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

function TScreenshotsCache.CalcThumbnail(const FileName: String; W, H: Integer): TBitmap;
var
  P: TPicture;
  B: TBitmap;
  NewW, NewH: Integer;
begin
  Result := nil;
  try
    P := LoadImageFromFile(FileName);
    if P = nil then Exit;
    try
      B := TBitmap.Create;
      try
        try
          B.Assign(P.Graphic);
        except
          on E: Exception do begin
            LogInfo('ScreenshotsCache: Assign graphic failed file="'+FileName+'" '+E.ClassName+': '+E.Message);
            Exit;
          end;
        end;

        Result := TBitmap.Create;
        try
          Result.SetSize(W, H);
          CalcWH(B.Width, B.Height, W, H, NewW, NewH);
          ScaleImage(B, Result, NewW, NewH);
        except
          on E: Exception do begin
            LogInfo('ScreenshotsCache: ScaleImage failed file="'+FileName+'" '+E.ClassName+': '+E.Message);
            FreeAndNil(Result);
          end;
        end;
      finally
        B.Free;
      end;
    finally
      P.Free;
    end;
  except
    on E: Exception do begin
      LogInfo('ScreenshotsCache: CalcThumbnail failed file="'+FileName+'" '+E.ClassName+': '+E.Message);
      FreeAndNil(Result);
    end;
  end;
end;

end.
