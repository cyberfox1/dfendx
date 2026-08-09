unit GameDBToolsHelpers;

interface

uses Classes, PrgConsts;

function IsWindowsExeMode(const ProfileMode: String): Boolean;
function TryStrToHex(const S: String; var Hex: Integer): Boolean;
function EncodeCSV(S: String): String;
function RemoveBackslash(const S: String): String;
function GroupMatch(const GameGroupUpper, SelectedGroupUpper: String): Boolean;
procedure CopyTemplates(Dir1, Dir2: String);
function GetGamesListExportXMLColumns: TStringList;
function RemoveDoubleEntrys(const St: TStringList): TStringList;
function UserInfoGetValue(const UserInfo, Key: String): String;
function UserDataContainValue(const UserInfo, Key, Value: String): Boolean;
{ CharsetHTMLTranslate: language-file pair list (char,entity,...) from caller. }
function EncodeUserHTMLSymbolsOnly(const S, CharsetHTMLTranslate: String): String;
function EncodeHTMLSymbols(const S, CharsetHTMLTranslate: String): String;
function DecodeHTMLSymbols(const S, CharsetHTMLTranslate: String): String;

function DetermineDosBoxKind(const Path, BaseDir: String): TDOSBoxKind;
function DOSBoxKindToDisplay(Kind: TDOSBoxKind): String;
function DOSBoxKindToIconFileName(Kind: TDOSBoxKind): String;
{ Multi-size ICO basename under IconSets\DOSBoxKind\ for the given kind. }
function DOSBoxKindToPreviewFileName(Kind: TDOSBoxKind): String;
{ Full-resolution PNG basename for profile-editor preview (not multi-size ICO). }

{ Exe directory without CommonTools/VCL (ParamStr(0)). }
function ProgramInstallDir: String;
function GetExeFileDescription(const ExePath: String): String;

{ Screenshot pane pick: lower prio first; same prio prefers larger file via inverted size key. }
{ True when taller than wide and h/w <= 1.8 (not overly elongated). }
function ImageIsPortrait(const ImageW, ImageH: Integer): Boolean;
function DetermineImagePriority(const FileNameOrPath: String; const IsPortrait: Boolean;
  const ImageW, ImageH: Integer): Integer;
function BuildScreenshotPaneSortKey(const Prio: Integer; const FileSize: Int64; const FilePath: String;
  const ImageW, ImageH: Integer): String;
function ExtractPathFromScreenshotPaneSortKey(const SortKey: String): String;

implementation

uses Windows, SysUtils, Math, CommonHelpers;

function ProgramInstallDir: String;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ExpandFileName(ParamStr(0))));
end;

function IsWindowsExeMode(const ProfileMode: String): Boolean;
begin
  result:=AnsiSameText(Trim(ProfileMode),'WINDOWS');
end;

function TryStrToHex(const S: String; var Hex: Integer): Boolean;
Var I : Integer;
begin
  result:=False;
  Hex:=0;
  For I:=1 to length(S) do begin
    Hex:=Hex*16;
    Case UpCase(S[I]) of
      '0'..'9' : Hex:=Hex+(ord(S[I])-ord('0'));
      'A'..'F' : Hex:=Hex+(ord(UpCase(S[I]))-ord('A')+10);
      else exit;
    End;
  end;
  result:=True;
end;

function EncodeCSV(S: String): String;
Var I : Integer;
begin
  result:='';
  I:=Pos('"',S);
  While I>0 do begin
    result:=result+Copy(S,1,I-1)+'""';
    S:=Copy(S,I+1,MaxInt);
    I:=Pos('"',S);
  end;
  result:=result+S;
end;

function RemoveBackslash(const S: String): String;
begin
  If S='\' then result:='' else result:=S;
end;

function GroupMatch(const GameGroupUpper, SelectedGroupUpper: String): Boolean;
Var I : Integer;
    S : String;
begin
  result:=True;
  If GameGroupUpper=SelectedGroupUpper then exit;

  S:=GameGroupUpper;
  I:=Pos(';',S);
  If I<>0 then While S<>'' do begin
    If I>0 then begin
      If Trim(Copy(S,1,I-1))=SelectedGroupUpper then exit;
      S:=Trim(Copy(S,I+1,MaxInt));
    end else begin
      If Trim(S)=SelectedGroupUpper then exit;
      break;
    end;
    I:=Pos(';',S);
  end;

  result:=False;
end;

procedure CopyTemplates(Dir1, Dir2: String);
Var Rec : TSearchRec;
    I : Integer;
begin
  Dir1:=IncludeTrailingPathDelimiter(Dir1);
  Dir2:=IncludeTrailingPathDelimiter(Dir2);
  I:=SysUtils.FindFirst(Dir1+'*.prof',faAnyFile,Rec);
  try
    While I=0 do begin
      Windows.CopyFile(PChar(Dir1+Rec.Name),PChar(Dir2+Rec.Name),False);
      I:=SysUtils.FindNext(Rec);
    end;
  finally
    SysUtils.FindClose(Rec);
  end;
end;

function GetGamesListExportXMLColumns: TStringList;
begin
  result:=TStringList.Create;

  result.Add('Name');
  result.Add('EmulationType');
  result.Add('Genre');
  result.Add('Developer');
  result.Add('Publisher');
  result.Add('Year');
  result.Add('Language');
  result.Add('WWW');
  result.Add('License');
  result.Add('StartCount');
end;

function RemoveDoubleEntrys(const St: TStringList): TStringList;
Var I : Integer;
    Upper : TStringList;
    S : String;
begin
  result:=St;

  Upper:=TStringList.Create;
  try
    I:=0;
    While I<St.Count do begin
      If Trim(St[I])='' then begin St.Delete(I); continue; end;
      S:=ExtUpperCase(St[I]);
      If Upper.IndexOf(S)>=0 then begin St.Delete(I); continue; end;
      Upper.Add(S); inc(I);
    end;
  finally
    Upper.Free;
  end;
end;

function UserInfoGetValue(const UserInfo, Key: String): String;
Var I,J : Integer;
    St : TStringList;
    S,KeyUpper : String;
begin
 result:='';
 KeyUpper:=ExtUpperCase(Key);

  St:=StringToStringList(UserInfo);
  try
    For I:=0 to St.Count-1 do begin
      S:=Trim(ExtUpperCase(St[I]));
      J:=Pos('=',S);
      If J=0 then continue;
      If Trim(Copy(S,1,J-1))=KeyUpper then begin
        result:=Trim(Copy(Trim(St[I]),J+1,MaxInt));
        exit;
      end;
    end;
  finally
    St.Free;
  end;
end;

function UserDataContainValue(const UserInfo, Key, Value: String): Boolean;
Var St : TStringList;
    I,J : Integer;
    S,T : String;
begin
  result:=False;

  St:=StringToStringList(UserInfo);
  try
    For I:=0 to St.Count-1 do begin
      S:=Trim(ExtUpperCase(St[I]));
      J:=Pos('=',S);
      If J=0 then continue;
      T:=Trim(Copy(S,J+1,MaxInt));
      S:=Trim(Copy(S,1,J-1));
      If (S=Key) and GroupMatch(T,Value) then begin result:=True; exit; end;
    end;
  finally
    St.Free;
  end;
end;

function EncodeUserHTMLSymbolsOnly(const S, CharsetHTMLTranslate: String): String;
Var I : Integer;
    St : TStringList;
    A,B : String;
begin
  result:=S;

  St:=ValueToList(CharsetHTMLTranslate,',');
  try
    If St.Count mod 2=1 then St.Add(St[St.Count-1]);
    For I:=0 to (St.Count div 2)-1 do begin
      A:=St[2*I]; If length(A)=0 then continue;
      B:=St[2*I+1]; If (B<>'') and (B[length(B)]<>';') then B:=B+';';
      If (A[1]='&') or (ExtUpperCase(B)='&AMP;') then continue;
      result:=Replace(result,A[1],B);
    end;
  finally
    St.Free;
  end;
end;

function EncodeHTMLSymbols(const S, CharsetHTMLTranslate: String): String;
begin
  result:=S;
  result:=Replace(result,'&','&amp;');
  result:=Replace(result,'<','&lt;');
  result:=Replace(result,'>','&gt;');
  result:=Replace(result,'"','&quot;');
  result:=EncodeUserHTMLSymbolsOnly(result, CharsetHTMLTranslate);
end;

function DecodeHTMLSymbols(const S, CharsetHTMLTranslate: String): String;
Var I,J,K : Integer;
    St : TStringList;
    A,B : String;
begin
  result:=S;
  result:=Replace(result,'&amp;','&');
  result:=Replace(result,'&lt;','<');
  result:=Replace(result,'&gt;','>');
  result:=Replace(result,'&quot;','"');
  result:=Replace(result,'&apos;','''');

  I:=1;
  While I<length(result)-1 do begin
    If (result[I]='&') and (result[I+1]='#') then begin
      If (I<length(result)-2) and (result[I+2]='x') then begin
        J:=0; while (I+3+J<length(result)) and (result[I+3+J]<>';') do inc(J);
        If (J>=1) and (J<=3) and TryStrToHex(Copy(result,I+3,J),K) then result:=copy(result,1,I-1)+chr(K)+copy(result,I+4+J);
      end else begin
        J:=0; while (I+2+J<length(result)) and (result[I+2+J]<>';') do inc(J);
        If (J>=1) and (J<=2) and TryStrToInt(Copy(result,I+2,J),K) then result:=copy(result,1,I-1)+chr(K)+copy(result,I+3+J);
      end;
    end;
    inc(I);
  end;

  St:=ValueToList(CharsetHTMLTranslate,',');
  try
    If St.Count mod 2=1 then St.Add(St[St.Count-1]);
    For I:=0 to (St.Count div 2)-1 do begin
      A:=St[2*I]; If length(A)=0 then continue;
      B:=St[2*I+1]; If (B<>'') and (B[length(B)]<>';') then B:=B+';';
      If (A[1]='&') or (ExtUpperCase(B)='&AMP;') then continue;
      result:=Replace(result,B,A[1]);
    end;
  finally
    St.Free;
  end;
end;

function GetExeFileDescription(const ExePath: String): String;
var
  Size, Handle: DWORD;
  Buffer: Pointer;
  Len: UINT;
  Value: Pointer;
  Trans: PLongWord;
  LangCharset, Query: String;
  FileName: String;
begin
  Result := '';
  FileName := ExePath;
  UniqueString(FileName);
  Size := GetFileVersionInfoSize(PChar(FileName), Handle);
  if Size = 0 then Exit;
  GetMem(Buffer, Size);
  try
    if not GetFileVersionInfo(PChar(FileName), Handle, Size, Buffer) then Exit;
    if not VerQueryValue(Buffer, '\VarFileInfo\Translation', Pointer(Trans), Len) then Exit;
    if (Trans = nil) or (Len < SizeOf(LongWord)) then Exit;
    LangCharset := IntToHex(LoWord(Trans^), 4) + IntToHex(HiWord(Trans^), 4);
    Query := '\StringFileInfo\' + LangCharset + '\FileDescription';
    if VerQueryValue(Buffer, PChar(Query), Value, Len) and (Value <> nil) then
      Result := PChar(Value);
  finally
    FreeMem(Buffer);
  end;
end;

function DetermineDosBoxKind(const Path, BaseDir: String): TDOSBoxKind;
var
  AbsDir, ExeName, Desc, UpperDesc: String;
  SR: TSearchRec;
  Found: Boolean;
begin
  Result := dbkNone;
  if Trim(Path) = '' then Exit;

  Result := dbkUnknown;
  AbsDir := IncludeTrailingPathDelimiter(MakeAbsPath(Path, BaseDir));
  if not DirectoryExists(AbsDir) then Exit;

  Found := False;
  ExeName := '';
  if FindFirst(AbsDir + 'dosbox*.exe', faAnyFile, SR) = 0 then
  try
    repeat
      if (SR.Attr and faDirectory) = 0 then
      begin
        ExeName := SR.Name;
        Found := True;
        Break;
      end;
    until FindNext(SR) <> 0;
  finally
    SysUtils.FindClose(SR);
  end;
  if not Found then Exit;

  Desc := GetExeFileDescription(AbsDir + ExeName);
  UpperDesc := ExtUpperCase(Desc);

  if Pos('DOSBOX-X', UpperDesc) > 0 then
    Result := dbkX
  else if Pos('STAGING', UpperDesc) > 0 then
    Result := dbkStaging
  else if SameText(ExeName, 'dosbox.exe') and (Pos('DOSBOX', UpperDesc) > 0) then
    Result := dbkStandard
  else
    Result := dbkUnknown;
end;

function DOSBoxKindToDisplay(Kind: TDOSBoxKind): String;
begin
  case Kind of
    dbkStandard: Result := DosBoxKindStandard;
    dbkX:        Result := DosBoxKindX;
    dbkStaging:  Result := DosBoxKindStaging;
    dbkUnknown:  Result := DosBoxKindUnknown;
  else
    Result := '';
  end;
end;

function DOSBoxKindToIconFileName(Kind: TDOSBoxKind): String;
begin
  case Kind of
    dbkStandard: Result := 'dosbox-standard.ico';
    dbkX:        Result := 'dosbox-x.ico';
    dbkStaging:  Result := 'dosbox-staging.ico';
  else
    { dbkNone, dbkUnknown }
    Result := 'dosbox-unknown.ico';
  end;
end;

function DOSBoxKindToPreviewFileName(Kind: TDOSBoxKind): String;
begin
  case Kind of
    dbkStandard: Result := 'dosbox-standard.png';
    dbkX:        Result := 'dosbox-x.png';
    dbkStaging:  Result := 'dosbox-staging.png';
  else
    Result := 'dosbox-unknown.png';
  end;
end;

function ImageIsPortrait(const ImageW, ImageH: Integer): Boolean;
begin
  Result := False;
  if (ImageW < 1) or (ImageH < 1) then Exit;
  if ImageH <= ImageW then Exit;
  if ImageH / ImageW > 1.8 then Exit;
  Result := True;
end;

function DetermineImagePriority(const FileNameOrPath: String; const IsPortrait: Boolean;
  const ImageW, ImageH: Integer): Integer;
var
  Name: String;
  Words: TStringList;
  I: Integer;
  Prio: Integer;
begin
  if (ImageW < 1) or (ImageH < 1) or (ImageW + ImageH < 300) then begin
    Result := 9;
    Exit;
  end;

  Name := AnsiLowerCase(FileNameOrPath);
  for I := 1 to Length(Name) do
    if not (Name[I] in ['a'..'z']) then
      Name[I] := ' ';

  Words := TStringList.Create;
  Words.AddStrings(Name.Split([' ', #9], TStringSplitOptions.ExcludeEmpty));

  Prio := -1;
  if Words.IndexOf('title') >= 0 then
    Prio := 0
  else if Words.IndexOf('cover') >= 0 then
    Prio := 1
  else if (Words.IndexOf('box') >= 0) and (Words.IndexOf('front') >= 0) then
    Prio := 2
  else if Words.IndexOf('poster') >= 0 then
    Prio := 3;

  if (Prio > -1) and (not IsPortrait) then
    Prio := Prio + 4;

  if Prio < 0 then begin
    if (Words.IndexOf('gameplay') >= 0) or (Words.IndexOf('screenshot') >= 0) then
      Prio := 8
    else
      Prio := 9;
  end;

  Words.Free;
  Result := Prio;
end;

function BuildScreenshotPaneSortKey(const Prio: Integer; const FileSize: Int64; const FilePath: String;
  const ImageW, ImageH: Integer): String;
var
  Inv: Int64;
  ScaleF, R: Double;
  Size: Int64;
begin
  { Ascending key: lower prio first; inverted size (MaxInt-size) so larger files sort first. }
  if (ImageW < 1) or (ImageH < 1) then
    Size := 0
  else begin
    ScaleF := Min(ImageH, ImageW) / Max(ImageH, ImageW);
    R := ImageH / ImageW;
    if (R >= 1.0) and (R <= 1.33) then
      ScaleF := 1.0 + (R - 1.0) / (1.33 - 1.0) * 0.1        { 1.0 → 1.1 }
    else if (R > 1.33) and (R <= 1.8) then
      ScaleF := 1.1 + (R - 1.33) / (1.8 - 1.33) * (ScaleF - 1.1); { 1.1 → base }
    Size := Trunc(FileSize * ScaleF);
  end;

  Inv := Int64(High(Integer)) - Size;
  if Inv < 0 then
    Inv := 0;
  Result := IntToStr(Prio) + ',' + Format('%.10d', [Inv]) + ',' + FilePath;
end;

function ExtractPathFromScreenshotPaneSortKey(const SortKey: String): String;
var
  P1, P2: Integer;
begin
  Result := '';
  P1 := Pos(',', SortKey);
  if P1 <= 0 then Exit;
  P2 := Pos(',', Copy(SortKey, P1 + 1, MaxInt));
  if P2 <= 0 then Exit;
  Result := Copy(SortKey, P1 + 1 + P2, MaxInt);
end;

end.
