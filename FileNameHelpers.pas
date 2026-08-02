unit FileNameHelpers;

interface

function IsOnlyDots(FileName: String): Boolean;
{ DOSBox/DOS short-name rules (see PrgConsts.DosBoxShortNameAllowedChars), not Windows Unicode validation. }
function HasForbiddenChars(FileName: String; UseExtendedAscii: Boolean): Boolean;
function FileNameOnly(const S: String): String;

implementation

uses PrgConsts;

function FileNameOnly(const S: String): String;
var I: Integer;
begin
  result := S;
  I := Pos('/', result);
  while I > 0 do begin
    result := Copy(result, I + 1, MaxInt);
    I := Pos('/', result);
  end;
  I := Pos('\', result);
  while I > 0 do begin
    result := Copy(result, I + 1, MaxInt);
    I := Pos('\', result);
  end;
end;

function IsOnlyDots(FileName: String) : Boolean;
var I: Integer;
begin
 Result:=false;
 if FileName='' then exit;
 Result:=true;
 for I:=1 to Length(FileName) do
    if FileName[I]<>'.' then Result:=false;
end;

function HasForbiddenChars(FileName : String; UseExtendedAscii:Boolean) : Boolean;
Var I, Dot : Integer;
begin
  Result:=False;
  Dot:=Pos('.',FileName);
  if not IsOnlyDots(FileName) and
    (Dot>0) and (Dot<Length(FileName)) and (Pos('.',Copy(FileName,dot+1,MaxInt))>0) then
  begin
    Result:=true;
    exit;
  end;
  For I:=1 to Length(FileName) do
  begin
  if (Pos(FileName[I],DosBoxShortNameAllowedChars)<=0) and
     ((Ord(FileName[I])<$80) or (not UseExtendedAscii))
  then
  begin
    Result:=True;
    Exit;
  end;
  end;
end;

end.
