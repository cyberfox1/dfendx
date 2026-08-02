unit MakeBootImageFromProfileFormHelpers;

interface

uses
  Classes, SysUtils;

procedure CalcDestDirs(const SourceDirs, DestDirs: TStringList);
function IsDirectSubDir(const ShortParent, LongTestDir: String): Boolean;

implementation

uses
  CommonHelpers;

procedure CalcDestDirs(const SourceDirs, DestDirs: TStringList);
var
  I, J: Integer;
  S, T: String;
begin
  for I := 0 to SourceDirs.Count - 1 do
  begin
    S := ''; T := SourceDirs[I];
    if T <> '' then while T[length(T)] = '\' do SetLength(T, length(T) - 1);
    J := Pos('\', T);
    while J > 0 do
    begin
      T := Copy(T, J + 1, MaxInt);
      J := Pos('\', T);
    end;
    for J := 1 to length(T) do
    begin
      if T[J] <> ' ' then S := S + T[J];
      if length(S) >= 8 then break;
    end;
    T := ExtUpperCase(S);
    J := 1;
    S := T;
    while DestDirs.IndexOf(S) >= 0 do
    begin
      S := '~' + IntToStr(J);
      S := Copy(T, 1, 8 - length(S)) + S;
      inc(J);
    end;
    DestDirs.Add(S);
  end;
end;

function IsDirectSubDir(const ShortParent, LongTestDir: String): Boolean;
var
  ShortTestDir, S: String;
begin
  result := False;
  ShortTestDir := ShortName(LongTestDir);
  if ExtUpperCase(Copy(ShortTestDir, 1, length(ShortParent))) <> ExtUpperCase(ShortParent) then exit;
  S := Copy(ShortTestDir, length(ShortParent) + 1, MaxInt);
  if (S <> '') and (S[1] = '\') then S := Copy(S, 2, MaxInt);
  if (S <> '') and (S[length(S)] = '\') then SetLength(S, length(S) - 1);
  S := Trim(S);
  if S = '' then exit;
  if Pos('\', S) > 0 then exit;
  result := True;
end;

end.
