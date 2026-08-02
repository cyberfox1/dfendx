unit GIFHelpers;

interface

function ByteAlignBit(Bits: Cardinal): Cardinal;
function WordAlignBit(Bits: Cardinal): Cardinal;
function DWordAlignBit(Bits: Cardinal): Cardinal;
function AlignBit(Bits, BitsPerPixel, Alignment: Cardinal): Cardinal;
function Colors2bpp(Colors: Integer): Integer;

implementation

function ByteAlignBit(Bits: Cardinal): Cardinal;
begin
  Result := (Bits+7) SHR 3;
end;

function WordAlignBit(Bits: Cardinal): Cardinal;
begin
  Result := ((Bits+15) SHR 4) SHL 1;
end;

function DWordAlignBit(Bits: Cardinal): Cardinal;
begin
  Result := ((Bits+31) SHR 5) SHL 2;
end;

function AlignBit(Bits, BitsPerPixel, Alignment: Cardinal): Cardinal;
begin
  Dec(Alignment);
  Result := ((Bits * BitsPerPixel) + Alignment) and not Alignment;
  Result := Result SHR 3;
end;

function Colors2bpp(Colors: integer): integer;
var
  MaxColor: integer;
begin
  if (Colors = 0) then
    Result := 0
  else
  begin
    Result := 1;
    MaxColor := 2;
    while (Colors > MaxColor) do
    begin
      inc(Result);
      MaxColor := MaxColor SHL 1;
    end;
  end;
end;

end.