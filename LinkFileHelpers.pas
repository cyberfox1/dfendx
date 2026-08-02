unit LinkFileHelpers;

interface

uses
  Classes, SysUtils;

const
  LinkFileSettingsFolder = 'Settings';
  LinkFileBinFolder = 'Bin';

function GetLevel(const S: String): Integer;
function LoadLinkFileData(const FileNameOnly, PrgDataDirVal, PrgDirVal: String;
  Names, Links: TStringList): Boolean;

implementation

function GetLevel(const S: String): Integer;
var
  I: Integer;
begin
  result := 0;
  for I := 1 to length(S) do
    if S[I] = '=' then
      inc(result)
    else
      exit;
end;

function LoadLinkFileData(const FileNameOnly, PrgDataDirVal, PrgDirVal: String;
  Names, Links: TStringList): Boolean;
var
  S: String;
  FSt: TStringList;
  I: Integer;
begin
  result := False;

  S := '';
  if FileExists(PrgDataDirVal + LinkFileSettingsFolder + '\' + FileNameOnly) then
    S := PrgDataDirVal + LinkFileSettingsFolder + '\' + FileNameOnly;
  if (S = '') and FileExists(PrgDataDirVal + FileNameOnly) then
    S := PrgDataDirVal + FileNameOnly;
  if (S = '') and FileExists(PrgDirVal + FileNameOnly) then
    S := PrgDirVal + FileNameOnly;
  if (S = '') and FileExists(PrgDirVal + LinkFileBinFolder + '\' + FileNameOnly) then
    S := PrgDirVal + LinkFileBinFolder + '\' + FileNameOnly;
  if S = '' then
    exit;

  FSt := TStringList.Create;
  try
    try
      FSt.LoadFromFile(S);
    except
      exit;
    end;
    for I := 0 to FSt.Count - 1 do
    begin
      S := Trim(FSt[I]);
      if S = '' then
        continue;
      if (S = '-') or (S = '---') then
      begin
        Names.Add('');
        Links.Add('');
      end;
      if Pos(';', S) = 0 then
        continue;
      if (Trim(Copy(S, 1, Pos(';', S) - 1)) = '-') or
         (Trim(Copy(S, 1, Pos(';', S) - 1)) = '---') then
      begin
        Names.Add('');
        Links.Add('');
        continue;
      end;
      Names.Add(Trim(Copy(S, 1, Pos(';', S) - 1)));
      Links.Add(Trim(Copy(S, Pos(';', S) + 1, MaxInt)));
    end;
  finally
    FSt.Free;
  end;

  result := True;
end;

end.
