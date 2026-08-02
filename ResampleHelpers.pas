unit ResampleHelpers;

interface

type
  TFilterProc = function(Value: Single): Single;

  TColorRGB = packed record
    r, g, b: BYTE;
  end;
  PColorRGB = ^TColorRGB;

function SinC(Value: Single): Single;
function SplineFilter(Value: Single): Single;
function BellFilter(Value: Single): Single;
function TriangleFilter(Value: Single): Single;
function BoxFilter(Value: Single): Single;
function HermiteFilter(Value: Single): Single;
function Lanczos3Filter(Value: Single): Single;
function MitchellFilter(Value: Single): Single;
procedure CalcWH(const OldW, OldH, MaxW, MaxH: Integer; var NewW, NewH: Integer);
function Color2RGB(Color: Longint): TColorRGB;
function RGB2Color(Color: TColorRGB): Longint;

const
  ResampleFilters: array[0..6] of record
    Name: string;
    Filter: TFilterProc;
    Width: Single;
  end = (
    (Name: 'Box';       Filter: BoxFilter;      Width: 0.5),
    (Name: 'Triangle';  Filter: TriangleFilter;  Width: 1.0),
    (Name: 'Hermite';   Filter: HermiteFilter;   Width: 1.0),
    (Name: 'Bell';      Filter: BellFilter;      Width: 1.5),
    (Name: 'B-Spline';  Filter: SplineFilter;    Width: 2.0),
    (Name: 'Lanczos3';  Filter: Lanczos3Filter;  Width: 3.0),
    (Name: 'Mitchell';  Filter: MitchellFilter;  Width: 2.0)
    );

implementation

uses
  Math, SysUtils;

function HermiteFilter(Value: Single): Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 1.0) then
    Result := (2.0 * Value - 3.0) * Sqr(Value) + 1.0
  else
    Result := 0.0;
end;

function BoxFilter(Value: Single): Single;
begin
  if (Value >= -0.5) and (Value < 0.5) then
    Result := 1.0
  else
    Result := 0.0;
end;

function TriangleFilter(Value: Single): Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 1.0) then
    Result := 1.0 - Value
  else
    Result := 0.0;
end;

function BellFilter(Value: Single): Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 0.5) then
    Result := 0.75 - Sqr(Value)
  else if (Value < 1.5) then
  begin
    Value := Value - 1.5;
    Result := 0.5 * Sqr(Value);
  end else
    Result := 0.0;
end;

function SplineFilter(Value: Single): Single;
var
  tt: Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 1.0) then
  begin
    tt := Sqr(Value);
    Result := 0.5 * tt * Value - tt + 2.0 / 3.0;
  end else if (Value < 2.0) then
  begin
    Value := 2.0 - Value;
    Result := 1.0 / 6.0 * Sqr(Value) * Value;
  end else
    Result := 0.0;
end;

function SinC(Value: Single): Single;
begin
  if (Value <> 0.0) then
  begin
    Value := Value * Pi;
    Result := Sin(Value) / Value
  end else
    Result := 1.0;
end;

function Lanczos3Filter(Value: Single): Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 3.0) then
    Result := SinC(Value) * SinC(Value / 3.0)
  else
    Result := 0.0;
end;

function MitchellFilter(Value: Single): Single;
const
  B = (1.0 / 3.0);
  C = (1.0 / 3.0);
var
  tt: Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  tt := Sqr(Value);
  if (Value < 1.0) then
  begin
    Value := (((12.0 - 9.0 * B - 6.0 * C) * (Value * tt))
      + ((-18.0 + 12.0 * B + 6.0 * C) * tt)
      + (6.0 - 2 * B));
    Result := Value / 6.0;
  end else if (Value < 2.0) then
  begin
    Value := (((-1.0 * B - 6.0 * C) * (Value * tt))
      + ((6.0 * B + 30.0 * C) * tt)
      + ((-12.0 * B - 48.0 * C) * Value)
      + (8.0 * B + 24.0 * C));
    Result := Value / 6.0;
  end else
    Result := 0.0;
end;

Procedure CalcWH(const OldW, OldH, MaxW, MaxH : Integer; var NewW, NewH : Integer);
Var F : Double;
begin
  if OldH=0 then begin NewW:=0; NewH:=0; exit; end;
  F:=OldW/OldH;

  If (OldW<=MaxW) and (OldH<=MaxH) then begin
    {too small scale up}
    If MaxH*F>MaxW then begin NewW:=MaxW; NewH:=Round(NewW/F); end else begin NewH:=MaxH; NewW:=Round(NewH*F); end;
    exit;
  end;

  {scale down}
  If OldW>MaxW then begin
    {too wide}
    NewW:=MaxW; NewH:=Round(NewW/F);
    {also too high ?}
    If NewH>MaxH then begin NewH:=MaxH; NewW:=Round(NewH*F); end;
    exit;
  end;

  {too high}
  NewH:=MaxH; NewW:=Round(NewH*F);
  {also too wide ?}
  If NewW>MaxW then begin NewW:=MaxW; NewH:=Round(NewW/F); end;
end;

function Color2RGB(Color: Longint): TColorRGB;
begin
  Result.r := Color AND $000000FF;
  Result.g := (Color AND $0000FF00) SHR 8;
  Result.b := (Color AND $00FF0000) SHR 16;
end;

function RGB2Color(Color: TColorRGB): Longint;
begin
  Result := Color.r OR (Color.g SHL 8) OR (Color.b SHL 16);
end;

end.
