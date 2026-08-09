unit LinkFileHelpers;

interface

uses
  Classes, SysUtils, System.NetEncoding;

const
  LinkFileSettingsFolder = 'Settings';
  LinkFileBinFolder = 'Bin';

function GetLevel(const S: String): Integer;
function LoadLinkFileData(const FileNameOnly, PrgDataDirVal, PrgDirVal: String;
  Names, Links: TStringList): Boolean;

{ <GAMENAME> — keep A-Za-z0-9, else %XX (existing OpenLink rule). }
function EncodeGameNamePercent(const RealGameName: String): String;
{ <GAMENAME_PCGW> — space→_; keep A-Za-z0-9 and ':'; else %XX.
  e.g. Monkey Island 2: LeChuck's Revenge
    → Monkey_Island_2:_LeChuck%27s_Revenge }
function EncodeGameNamePCGW(const RealGameName: String): String;
{ <GAMENAME_SLUG> — space→_; keep A-Za-z0-9; drop other punctuation.
  e.g. Monkey Island 2: LeChuck's Revenge
    → Monkey_Island_2_LeChucks_Revenge }
function EncodeGameNameSlug(const RealGameName: String): String;
{ <GAMENAME_TGDB> — form-urlencoded query style: space→+; keep A-Za-z0-9; else %XX.
  e.g. Monkey Island 2: LeChuck's Revenge
    → Monkey+Island+2%3A+LeChuck%27s+Revenge
  Also: Home of the Underdogs, My Abandonware search queries. }
function EncodeGameNameTGDB(const RealGameName: String): String;
{ <GAMENAME_LAUNCHBOX> — strip ':' first, then lowercase; space→%20; keep A-Za-z0-9 and ';
  else %XX. e.g. Monkey Island 2: LeChuck's Revenge
    → monkey%20island%202%20lechuck's%20revenge }
function EncodeGameNameLaunchBox(const RealGameName: String): String;
{ <GAMENAME_HG101> — lowercase slug path: space→-; drop non A-Za-z0-9 (incl. : ').
  e.g. Monkey Island 2: LeChuck's Revenge
    → monkey-island-2-lechucks-revenge
  Direct article path on hardcoregaming101.net. }
function EncodeGameNameHG101(const RealGameName: String): String;

{ Pick site token in LinkTemplate (longer first), encode RealGameName, splice.
  DefaultPlaceHolder used when no site-specific token (usually '<GAMENAME>').
  Returns '' if the chosen placeholder is not present in the template. }
function ResolveGameLinkURL(const LinkTemplate, DefaultPlaceHolder,
  RealGameName: String): String;

implementation

function CollapseSpaces(const RealGameName: String): String;
var
  I: Integer;
  C: Char;
  PrevSpace: Boolean;
  S: String;
begin
  Result := '';
  S := Trim(RealGameName);
  PrevSpace := False;
  for I := 1 to Length(S) do begin
    C := S[I];
    if C = ' ' then begin
      if PrevSpace then Continue;
      PrevSpace := True;
      Result := Result + ' ';
    end else begin
      PrevSpace := False;
      Result := Result + C;
    end;
  end;
end;

function EncodeGameNamePercent(const RealGameName: String): String;
begin
  { Keep A-Za-z0-9; URL-encode the rest (incl. spaces as %20). }
  Result := TNetEncoding.URL.Encode(CollapseSpaces(RealGameName));
end;

function EncodeGameNamePCGW(const RealGameName: String): String;
var
  I: Integer;
  S: String;
  C: Char;
begin
  { space→_; keep A-Za-z0-9 and ':'; else URL-encode. }
  Result := '';
  S := CollapseSpaces(RealGameName);
  for I := 1 to Length(S) do begin
    C := S[I];
    if C = ' ' then
      Result := Result + '_'
    else if Pos(C, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789:') <> 0 then
      Result := Result + C
    else
      Result := Result + TNetEncoding.URL.Encode(C);
  end;
end;

function EncodeGameNameSlug(const RealGameName: String): String;
var
  I: Integer;
  S: String;
  C: Char;
begin
  { space→_; keep A-Za-z0-9; drop other punctuation. }
  Result := '';
  S := CollapseSpaces(RealGameName);
  for I := 1 to Length(S) do begin
    C := S[I];
    if C = ' ' then
      Result := Result + '_'
    else if Pos(C, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') <> 0 then
      Result := Result + C;
  end;
end;

function EncodeGameNameTGDB(const RealGameName: String): String;
begin
  { Form-style query: URL-encode then space as + (not %20). }
  Result := TNetEncoding.URL.Encode(CollapseSpaces(RealGameName));
  Result := StringReplace(Result, '%20', '+', [rfReplaceAll]);
end;

function EncodeGameNameLaunchBox(const RealGameName: String): String;
var
  I: Integer;
  S: String;
  C: Char;
begin
  { ':' removed before other rules; lowercase; space→%20; keep alnum and apostrophe. }
  Result := '';
  S := CollapseSpaces(RealGameName);
  S := StringReplace(S, ':', '', [rfReplaceAll]);
  S := LowerCase(S);
  for I := 1 to Length(S) do begin
    C := S[I];
    if C = ' ' then
      Result := Result + '%20'
    else if Pos(C, 'abcdefghijklmnopqrstuvwxyz0123456789''') <> 0 then
      Result := Result + C
    else
      Result := Result + TNetEncoding.URL.Encode(C);
  end;
end;

function EncodeGameNameHG101(const RealGameName: String): String;
var
  I: Integer;
  S: String;
  C: Char;
  PrevHyphen: Boolean;
begin
  { Lowercase path slug: spaces→hyphens; drop punctuation (incl. : and '). }
  Result := '';
  S := LowerCase(CollapseSpaces(RealGameName));
  PrevHyphen := False;
  for I := 1 to Length(S) do begin
    C := S[I];
    if C = ' ' then begin
      if not PrevHyphen and (Result <> '') then begin
        Result := Result + '-';
        PrevHyphen := True;
      end;
    end else if Pos(C, 'abcdefghijklmnopqrstuvwxyz0123456789') <> 0 then begin
      Result := Result + C;
      PrevHyphen := False;
    end;
  end;
  while (Result <> '') and (Result[Length(Result)] = '-') do
    Delete(Result, Length(Result), 1);
end;

function ResolveGameLinkURL(const LinkTemplate, DefaultPlaceHolder,
  RealGameName: String): String;
var
  UpperLink, PlaceHolder, Encoded, UpperPH: String;
  I: Integer;
begin
  Result := '';
  UpperLink := UpperCase(LinkTemplate);
  { Longer tokens first so GAMENAME_LAUNCHBOX is not treated as GAMENAME. }
  if Pos('<GAMENAME_LAUNCHBOX>', UpperLink) > 0 then begin
    PlaceHolder := '<GAMENAME_LAUNCHBOX>';
    Encoded := EncodeGameNameLaunchBox(RealGameName);
  end else if Pos('<GAMENAME_HG101>', UpperLink) > 0 then begin
    PlaceHolder := '<GAMENAME_HG101>';
    Encoded := EncodeGameNameHG101(RealGameName);
  end else if Pos('<GAMENAME_PCGW>', UpperLink) > 0 then begin
    PlaceHolder := '<GAMENAME_PCGW>';
    Encoded := EncodeGameNamePCGW(RealGameName);
  end else if Pos('<GAMENAME_SLUG>', UpperLink) > 0 then begin
    PlaceHolder := '<GAMENAME_SLUG>';
    Encoded := EncodeGameNameSlug(RealGameName);
  end else if Pos('<GAMENAME_TGDB>', UpperLink) > 0 then begin
    PlaceHolder := '<GAMENAME_TGDB>';
    Encoded := EncodeGameNameTGDB(RealGameName);
  end else begin
    PlaceHolder := DefaultPlaceHolder;
    Encoded := EncodeGameNamePercent(RealGameName);
  end;
  UpperPH := UpperCase(PlaceHolder);
  I := Pos(UpperPH, UpperLink);
  if I = 0 then Exit;
  Result := Copy(LinkTemplate, 1, I - 1) + Encoded +
    Copy(LinkTemplate, I + Length(PlaceHolder), MaxInt);
end;

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
