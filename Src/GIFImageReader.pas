unit GIFImageReader;

{ Pure Object Pascal GIF decoder.
  This unit contains the file format decoding logic with no VCL dependencies.
  It can be used by both Delphi VCL (via GIFImage.pas wrapper) and FPC/LCL.
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

interface

uses
  SysUtils, Classes;

type
  TGIFVersion = (gvUnknown, gv87a, gv89a);
  TGIFVersionRec = array[0..2] of AnsiChar;

const
  GIFVersions: array[gv87a..gv89a] of TGIFVersionRec = ('87a', '89a');

type
  TGIFHeaderRec = packed record
    Signature: array[0..2] of AnsiChar; { 'GIF' }
    Version: TGIFVersionRec;
  end;

  // Logical Screen Descriptor
  TGIFLogicalScreenDescriptor = packed record
    ScreenWidth: Word;
    ScreenHeight: Word;
    PackedFields: Byte;
    BackgroundColorIndex: Byte;
    AspectRatio: Byte;
  end;

  // Color
  TGIFColor = packed record
    Red, Green, Blue: Byte;
  end;
  PGIFColor = ^TGIFColor;

  TGIFColorMap = array of TGIFColor;

  // Image Descriptor
  TGIFImageDescriptor = packed record
    ImageLeft: Word;
    ImageTop: Word;
    ImageWidth: Word;
    ImageHeight: Word;
    PackedFields: Byte;
  end;

  // Graphic Control Extension
  TGIFGraphicControlExtension = packed record
    BlockSize: Byte;
    PackedFields: Byte;
    DelayTime: Word;
    TransparentColorIndex: Byte;
    Terminator: Byte;
  end;

  // The core decoded data structures (pure)
  TGIFImageData = class
  public
    Descriptor: TGIFImageDescriptor;
    ColorMap: TGIFColorMap;
    Data: TBytes;  // Decompressed pixel indices
    GraphicControlExtension: TGIFGraphicControlExtension;
    Transparent: Boolean;
    Interlaced: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

  TGIFData = class
  public
    Header: TGIFHeaderRec;
    LogicalScreen: TGIFLogicalScreenDescriptor;
    GlobalColorMap: TGIFColorMap;
    Images: TList;  // list of TGIFImageData
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  // The reader class - does the actual file decoding
  TGIFReader = class
  private
    FData: TGIFData;
    FPendingGCE: TGIFGraphicControlExtension;
    FHasPendingGCE: Boolean;
    procedure ReadHeader(Stream: TStream);
    procedure ReadLogicalScreenDescriptor(Stream: TStream);
    procedure ReadGlobalColorMap(Stream: TStream);
    procedure ReadImage(Stream: TStream);
    procedure ReadExtension(Stream: TStream);
    procedure ReadGraphicControlExtension(Stream: TStream);
    procedure ReadDataBlock(Stream: TStream; var Buffer: TBytes);
    procedure DecodeLZW(Stream: TStream; var Pixels: TBytes; Width, Height: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromStream(Stream: TStream): TGIFData;
    function LoadFromFile(const FileName: string): TGIFData;
    property Data: TGIFData read FData;
  end;

function IsValidGIFSignature(const Header: TGIFHeaderRec): Boolean;
function ReadLZWCode(const Data: TBytes; var BitPos: Integer; CodeSize: Integer): Integer;

implementation

function IsValidGIFSignature(const Header: TGIFHeaderRec): Boolean;
var
  s: AnsiString;
begin
  SetString(s, PAnsiChar(@Header.Signature), 3);
  Result := UpperCase(string(s)) = 'GIF';
end;

{ TGIFImageData }

constructor TGIFImageData.Create;
begin
  inherited;
end;

destructor TGIFImageData.Destroy;
begin
  inherited;
end;

{ TGIFData }

constructor TGIFData.Create;
begin
  inherited;
  Images := TList.Create;
end;

destructor TGIFData.Destroy;
var
  i: Integer;
begin
  for i := 0 to Images.Count - 1 do
    TGIFImageData(Images[i]).Free;
  Images.Free;
  inherited;
end;

procedure TGIFData.Clear;
var
  i: Integer;
begin
  for i := 0 to Images.Count - 1 do
    TGIFImageData(Images[i]).Free;
  Images.Clear;
  FillChar(Header, SizeOf(Header), 0);
  FillChar(LogicalScreen, SizeOf(LogicalScreen), 0);
  SetLength(GlobalColorMap, 0);
end;

{ TGIFReader }

constructor TGIFReader.Create;
begin
  inherited;
  FData := TGIFData.Create;
end;

destructor TGIFReader.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TGIFReader.ReadHeader(Stream: TStream);
var
  GifHeader: TGIFHeaderRec;
  Position: Int64;
  s: AnsiString;
begin
  Position := Stream.Position;
  Stream.ReadBuffer(GifHeader, SizeOf(GifHeader));

  SetString(s, PAnsiChar(@GifHeader.Signature), 3);
  if (UpperCase(string(s)) <> 'GIF') then
  begin
    // rxLib recovery
    Stream.Position := Position;
    Stream.Seek(SizeOf(LongInt), soFromCurrent);
    Stream.ReadBuffer(GifHeader, SizeOf(GifHeader));
    SetString(s, PAnsiChar(@GifHeader.Signature), 3);
    if (UpperCase(string(s)) <> 'GIF') then
      raise Exception.Create('Invalid GIF signature');
  end;

  FData.Header := GifHeader;
end;

procedure TGIFReader.ReadLogicalScreenDescriptor(Stream: TStream);
begin
  Stream.ReadBuffer(FData.LogicalScreen, SizeOf(FData.LogicalScreen));
end;

procedure TGIFReader.ReadGlobalColorMap(Stream: TStream);
var
  ColorCount: Integer;
  i: Integer;
begin
  if (FData.LogicalScreen.PackedFields and $80) = $80 then
  begin
    ColorCount := 2 shl (FData.LogicalScreen.PackedFields and $07);
    SetLength(FData.GlobalColorMap, ColorCount);
    for i := 0 to ColorCount - 1 do
      Stream.ReadBuffer(FData.GlobalColorMap[i], SizeOf(TGIFColor));
  end;
end;

procedure TGIFReader.ReadDataBlock(Stream: TStream; var Buffer: TBytes);
var
  Size: Byte;
begin
  Stream.ReadBuffer(Size, 1);
  SetLength(Buffer, Size);
  if Size > 0 then
    Stream.ReadBuffer(Buffer[0], Size);
end;

function ReadLZWCode(const Data: TBytes; var BitPos: Integer; CodeSize: Integer): Integer;
var
  i, ByteIdx, BitIdx: Integer;
begin
  Result := 0;
  for i := 0 to CodeSize - 1 do
  begin
    ByteIdx := (BitPos + i) shr 3;
    BitIdx := (BitPos + i) and 7;
    if ByteIdx < Length(Data) then
    begin
      if ((Data[ByteIdx] shr BitIdx) and 1) <> 0 then
        Result := Result or (1 shl i);
    end;
  end;
  Inc(BitPos, CodeSize);
end;

procedure TGIFReader.DecodeLZW(Stream: TStream; var Pixels: TBytes; Width, Height: Integer);
var
  MinCodeSize: Byte;
  ClearCode, EOICode: Integer;
  CodeSize, MaxCode: Integer;
  Dict: array[0..4095] of TBytes;
  DictSize: Integer;
  i, OutPos: Integer;
  DataBlocks: TBytes;
  Block: TBytes;
  BitPos: Integer;
  PrevCode, Code: Integer;
  NewEntry: TBytes;
begin
  Stream.ReadBuffer(MinCodeSize, 1);

  DataBlocks := nil;
  repeat
    ReadDataBlock(Stream, Block);
    if Length(Block) > 0 then
    begin
      i := Length(DataBlocks);
      SetLength(DataBlocks, i + Length(Block));
      Move(Block[0], DataBlocks[i], Length(Block));
    end;
  until Length(Block) = 0;

  ClearCode := 1 shl MinCodeSize;
  EOICode := ClearCode + 1;
  CodeSize := MinCodeSize + 1;
  MaxCode := (1 shl CodeSize) - 1;

  for i := 0 to ClearCode - 1 do
  begin
    SetLength(Dict[i], 1);
    Dict[i][0] := Byte(i);
  end;
  DictSize := ClearCode + 2;

  if (Width = 0) or (Height = 0) then
  begin
    SetLength(Pixels, 0);
    Exit;
  end;

  SetLength(Pixels, Width * Height);
  OutPos := 0;
  BitPos := 0;
  PrevCode := -1;

  while OutPos < Length(Pixels) do
  begin
    if BitPos + CodeSize > Length(DataBlocks) * 8 then
      Break;

    Code := ReadLZWCode(DataBlocks, BitPos, CodeSize);

    if Code = ClearCode then
    begin
      DictSize := ClearCode + 2;
      CodeSize := MinCodeSize + 1;
      MaxCode := (1 shl CodeSize) - 1;
      PrevCode := -1;
      Continue;
    end;

    if Code = EOICode then
      Break;

    if Code < DictSize then
    begin
      if OutPos + Length(Dict[Code]) <= Length(Pixels) then
      begin
        Move(Dict[Code][0], Pixels[OutPos], Length(Dict[Code]));
        Inc(OutPos, Length(Dict[Code]));
      end;

      if PrevCode >= 0 then
      begin
        SetLength(NewEntry, Length(Dict[PrevCode]) + 1);
        Move(Dict[PrevCode][0], NewEntry[0], Length(Dict[PrevCode]));
        NewEntry[Length(Dict[PrevCode])] := Dict[Code][0];
        Dict[DictSize] := NewEntry;
        Inc(DictSize);
        if (DictSize > MaxCode) and (CodeSize < 12) then
        begin
          Inc(CodeSize);
          MaxCode := (1 shl CodeSize) - 1;
        end;
      end;
    end
    else if Code = DictSize then
    begin
      if PrevCode >= 0 then
      begin
        SetLength(NewEntry, Length(Dict[PrevCode]) + 1);
        Move(Dict[PrevCode][0], NewEntry[0], Length(Dict[PrevCode]));
        NewEntry[Length(Dict[PrevCode])] := Dict[PrevCode][0];
        Dict[DictSize] := NewEntry;
        Inc(DictSize);
        if (DictSize > MaxCode) and (CodeSize < 12) then
        begin
          Inc(CodeSize);
          MaxCode := (1 shl CodeSize) - 1;
        end;
        if OutPos + Length(NewEntry) <= Length(Pixels) then
        begin
          Move(NewEntry[0], Pixels[OutPos], Length(NewEntry));
          Inc(OutPos, Length(NewEntry));
        end;
      end;
    end;

    PrevCode := Code;
  end;
end;

procedure TGIFReader.ReadImage(Stream: TStream);
var
  ImageData: TGIFImageData;
  Descriptor: TGIFImageDescriptor;
  ColorCount: Integer;
  i: Integer;
begin
  ImageData := TGIFImageData.Create;
  try
    Stream.ReadBuffer(Descriptor, SizeOf(Descriptor));
    ImageData.Descriptor := Descriptor;
    ImageData.Interlaced := (Descriptor.PackedFields and $40) = $40;

    if (Descriptor.PackedFields and $80) = $80 then
    begin
      ColorCount := 2 shl (Descriptor.PackedFields and $07);
      SetLength(ImageData.ColorMap, ColorCount);
      for i := 0 to ColorCount - 1 do
        Stream.ReadBuffer(ImageData.ColorMap[i], SizeOf(TGIFColor));
    end;

    DecodeLZW(Stream, ImageData.Data, Descriptor.ImageWidth, Descriptor.ImageHeight);

    if FHasPendingGCE then
    begin
      ImageData.GraphicControlExtension := FPendingGCE;
      ImageData.Transparent := (FPendingGCE.PackedFields and $01) = $01;
      FHasPendingGCE := False;
    end;

    FData.Images.Add(ImageData);
  except
    ImageData.Free;
    raise;
  end;
end;

procedure TGIFReader.ReadGraphicControlExtension(Stream: TStream);
var
  Size: Byte;
begin
  Stream.ReadBuffer(Size, 1);
  if Size = 4 then
  begin
    Stream.ReadBuffer(FPendingGCE.PackedFields, 1);
    Stream.ReadBuffer(FPendingGCE.DelayTime, 2);
    Stream.ReadBuffer(FPendingGCE.TransparentColorIndex, 1);
    FPendingGCE.BlockSize := 4;
    FHasPendingGCE := True;
  end
  else
    Stream.Seek(Size, soFromCurrent);

  // Read terminator
  Stream.ReadBuffer(Size, 1);
end;

procedure TGIFReader.ReadExtension(Stream: TStream);
var
  LabelByte: Byte;
  Block: TBytes;
begin
  Stream.ReadBuffer(LabelByte, 1);
  case LabelByte of
    $F9: ReadGraphicControlExtension(Stream);
  else
    repeat
      ReadDataBlock(Stream, Block);
    until Length(Block) = 0;
  end;
end;

function TGIFReader.LoadFromStream(Stream: TStream): TGIFData;
var
  b: Byte;
begin
  FData.Clear;
  FHasPendingGCE := False;

  ReadHeader(Stream);
  ReadLogicalScreenDescriptor(Stream);
  ReadGlobalColorMap(Stream);

  repeat
    Stream.ReadBuffer(b, 1);
    case b of
      $2C: ReadImage(Stream);      // Image separator
      $21: ReadExtension(Stream);  // Extension introducer
      $3B: break;                  // Trailer
    else
      // Unknown
    end;
  until False;

  Result := FData;
end;

function TGIFReader.LoadFromFile(const FileName: string): TGIFData;
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := LoadFromStream(FS);
  finally
    FS.Free;
  end;
end;

end.