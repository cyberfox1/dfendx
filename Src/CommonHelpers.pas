unit CommonHelpers;
interface

uses Windows, Classes;

Type TConfigRec=record
  Nr : Integer;
  Section, Key : String;
  DefaultBool : Boolean;
  DefaultInteger : Integer;
  DefaultString : String;
  Cached : Boolean;
  CacheValueBool : Boolean;
  CacheValueInteger : Integer;
  CacheValueString : String;
end;

Type TConfigRecArray=Array of TConfigRec;
     PConfigRec=^TConfigRec;
     PConfigRecArray=^TConfigRecArray;
     TConfigIndexArray=Array of Integer;

Type TConfigType=(ctBoolean,ctInteger,ctString);

Type TBasePrgSetupH=class
  private
    Function AddRec(const ANr : Integer; const ASection, AKey : String; var List : TConfigRecArray) : Integer;
    function AddRecFast(const ANr: Integer; const ASection, AKey: String; var List: TConfigRecArray; var UsedCounter : Integer) : Integer;
    Procedure LoadBinConfig(const St : TStream; const PConfig : PConfigRecArray; const ConfigType : TConfigType);
    Procedure StoreBinConfig(const St : TStream; const PConfig : PConfigRecArray; const ConfigType : TConfigType);
  protected
    BooleanList, IntegerList, StringList : TConfigRecArray;
    BooleanListUsed, IntegerListUsed, StringListUsed : Integer;
    BooleanIndex, IntegerIndex, StringIndex : TConfigIndexArray;
    FChanged : Boolean;
    FLastTimeStamp : DWord;
    Procedure ClearLists;
    Function IndexOf(const Nr : Integer; const List : TConfigRecArray; var Index : TConfigIndexArray) : Integer;
    function GetBoolean(const Index: Integer): Boolean; virtual;
    function GetInteger(const Index: Integer): Integer; virtual;
    function GetString(const Index: Integer): String; virtual;
  public
    Procedure FastAddRecStart;
    Procedure FastAddRecDone;
    Procedure AddBooleanRec(const Nr : Integer; const Section, Key : String; const Default : Boolean); inline;
    Procedure AddIntegerRec(const Nr : Integer; const Section, Key : String; const Default : Integer); inline;
    Procedure AddStringRec(const Nr : Integer; const Section, Key : String; const Default : String); inline;
    Constructor Create;
    Procedure SetChanged(Value: Boolean = True);
    Function GetBinaryVersionID : Integer;
    Procedure LoadFromStream(const St : TStream); virtual;
    Procedure SaveToStream(const St : TStream); virtual;
    property Changed : Boolean read FChanged;
end;

Function ExtUpperCase(const S : String) : String;
Function ExtLowerCase(const S : String) : String;

Function StrToFloatEx(S : String) : Double;

Function ValueToList(Value : String; const Divider : String = ';') : TStringList;
Function ListToValue(const St : TStrings; Divider : Char =';') : String;
Function IsValueInList(const List, Value : String) : Boolean;
Procedure Divide(const Data : String; Var Name, Value : String);

Function StringToStringList(S : String) : TStringList;
Function IsEmpty(const S : String) : Boolean;
Function StringListToString(const St : TStrings) : String; overload;
Function StringListToString(const S : String) : String; overload;
Function Replace(const S, FromSub, ToSub : String) : String;

Function FindStringInFile(const FileName : String; const SearchString : UnicodeString) : Boolean;

{Split Lines into DOS "echo" lines (max ~75 chars), after OEM conversion for DOSBox.}
Procedure SplitText(const St : TStringList; const Lines : String);

Function TempDir : String;

Function MakeRelPath(Path, Rel : String; const NoEmptyRelPath : Boolean =False) : String;
Function MakeAbsPath(Path, Rel : String) : string;
Function MakeExtRelPath(Path, Rel : String) : String;
Function MakeExtAbsPath(Path, Rel : String) : string;
Function ShortName(const LongName : String) : String;
Function RemoveIllegalFileNameChars(const Name : String) : String;

Function GetFileVersionEx(const AFileName: string) : Cardinal;
Function VersionToInt(Version : String) : Integer;
Function MainVersionStringToInt(S : String) : Integer;

{ HTTP User-Agent for THTTPClient.
  IsWow64 = IsWow64Process result (WOW64 vs Win32 in UA).
  Example: DFendX/2.0.1 (Windows NT 10.0; WOW64) Delphi 12 (THTTPClient) }
Function BuildDFendXHTTPUserAgent(const AppVersion: String; WinMajor, WinMinor: Integer; const IsWow64: Boolean): String;
Function GetDFendXHTTPUserAgent: String;

Function OldDOSBoxVersion(const Version : String) : Boolean;

Function GetFileDate(const FileName : String) : TDateTime;
Function GetDosFileDate(const FileName : String) : Integer;

function GetFileSize(const AFileName : String): Int64;
Function FileSizeToStr(const Size : Int64) : String;

Function GetScreensaverAllowStatus : Boolean;
Procedure SetScreensaverAllowStatus(const Enable : Boolean);

Function CharsetNameToFontCharSet(const Name : String) : Byte;

Function CompareFiles(const File1, File2 : String) : Boolean;

Function CPUCount : Integer;
function IsRemoteSession: Boolean;

const AllowedCharsDefault='ABCDEFGHIJKLMNOPQRSTUVWXYZ'#$C4#$D6#$DC'abcdefghijklmnopqrstuvwxyz'#$E4#$F6#$FC#$DF'01234567890-_=.,;!()$#@{}&''`~'#246#255#$A0#$E5;

implementation

uses SysUtils, PrgConsts, Math;

Function ExtUpperCase(const S : String) : String;
Var I,J : Integer;
begin
  result:=Trim(S);
  For I:=1 to length(result) do begin
    If (result[I]>='a') and (result[I]<='z') then begin
      result[I]:=chr(ord(result[I])-(ord('a')-ord('A')));
      continue;
    end;
    J:=Pos(result[I],LanguageSpecialLowerCase);
    If (J>0) and (J<=Length(LanguageSpecialUpperCase)) then
      result[I]:=LanguageSpecialUpperCase[J];
  end;
end;

Function ExtLowerCase(const S : String) : String;
Var I,J : Integer;
begin
  result:=Trim(S);
  For I:=1 to length(result) do begin
    If (result[I]>='A') and (result[I]<='Z') then begin
      result[I]:=chr(ord(result[I])+(ord('a')-ord('A')));
      continue;
    end;
    J:=Pos(result[I],LanguageSpecialUpperCase);
    If (J>0) and (J<=Length(LanguageSpecialLowerCase)) then
      result[I]:=LanguageSpecialLowerCase[J];
  end;
end;

Function StrToFloatEx(S : String) : Double;
Var I : Integer;
begin
  For I:=1 to length(S) do If (S[I]='.') or (S[I]=',') then S[I]:=FormatSettings.DecimalSeparator;
  result:=StrToFloat(S);
end;

Function ValueToList(Value : String; const Divider : String) : TStringList;
Var I,J : Integer;
begin
  result:=TStringList.Create;
  Value:=Trim(Value);

  while Value<>'' do begin
    I:=0;
    For J:=1 to length(Value) do If Pos(Value[J],Divider)<>0 then begin I:=J; break; end;

    If I>0 then begin
      result.Add(Trim(Copy(Value,1,I-1)));
      Value:=Trim(Copy(Value,I+1,MaxInt));
    end else begin
      result.Add(Value);
      Value:='';
    end;
  end;

  If Divider=';' then For I:=0 to result.count-1 do result[I]:=StringReplace(result[I],'<semicolon>',';',[rfReplaceAll,rfIgnoreCase]);
end;

Function ListToValue(const St : TStrings; Divider : Char) : String;
Var I : Integer;
    S : String;
begin
  result:='';
  For I:=0 to St.Count-1 do begin
    S:=Trim(St[I]); If S='' then continue;
    S:=StringReplace(S,';','<semicolon>',[rfReplaceAll]);
    If result<>'' then result:=result+Divider;
    result:=result+S;
  end;
end;

Function IsValueInList(const List, Value : String) : Boolean;
Var St : TStringList;
    I : Integer;
    S : String;
begin
  result:=False;
  if Value='' then exit;
  S:=Trim(ExtUpperCase(Value));
  St:=ValueToList(List,';,');
  try
    For I:=0 to St.Count-1 do
      If Trim(ExtUpperCase(St[I]))=S then begin result:=True; exit; end;
  finally
    St.Free;
  end;
end;

Procedure Divide(const Data : String; Var Name, Value : String);
Var I : Integer;
begin
  I:=Pos(':',Data);
  If I=0 then begin
    Name:=Data;
    Value:='';
  end else begin
    Name:=Trim(Copy(Data,1,I-1));
    Value:=Trim(Copy(Data,I+1,MaxInt));
  end;
end;

Function StringToStringList(S : String) : TStringList;
Var T : String;
    I,J : Integer;
begin
  T:='';
  while S<>'' do begin
    I:=Pos('[',S);
    If I=0 then begin T:=T+S; S:=''; continue; end;
    T:=T+Copy(S,1,I-1); S:=Copy(S,I+1,MaxInt);
    I:=Pos(']',S);
    If I=0 then begin T:=T+'['+S; S:=''; continue; end;
    if (not TryStrToInt(Copy(S,1,I-1),J)) or (J<0) or (J>255) then begin T:=T+'['; continue; end;
    T:=T+chr(J); S:=Copy(S,I+1,MaxInt);
  end;

  result:=TStringList.Create;
  result.Text:=T;
end;

Function IsEmpty(const S : String) : Boolean;
Var I : Integer;
    St : TStringList;
begin
  result:=False;
  St:=StringToStringList(S);
  try
    For I:=0 to St.Count-1 do If Trim(St[I])<>'' then exit;
  finally
    St.Free;
  end;
  result:=True;
end;

Function StringListToString(const St : TStrings) : String;
Var I : Integer;
    S : String;
begin
  S:=St.Text;
  result:='';

  result:='';
  For I:=1 to length(S) do
    If S[I]<#32 then result:=result+'['+IntToStr(Ord(S[I]))+']' else result:=result+S[I];
end;

Function StringListToString(const S : String) : String;
Var I : Integer;
begin
  result:='';

  result:='';
  For I:=1 to length(S) do
    If S[I]<#32 then result:=result+'['+IntToStr(Ord(S[I]))+']' else result:=result+S[I];
end;

Function Replace(const S, FromSub, ToSub : String) : String;
Var I : Integer;
    Text : String;
begin
  Text:=S; result:='';
  I:=Pos(FromSub,Text);
  while I>0 do begin
    If (ToSub<>'') and (FromSub=ToSub[1]) and (Copy(Text,I,length(ToSub))=ToSub) then begin
      result:=result+Copy(Text,1,I+length(ToSub)-1);
      Text:=Copy(Text,I+length(ToSub),MaxInt);
    end else begin
      result:=result+Copy(Text,1,I-1)+ToSub;
      Text:=Copy(Text,I+length(FromSub),MaxInt);
    end;
    I:=Pos(FromSub,Text);
  end;
  result:=result+Text;
end;

Type TByteArray=Array[0..0] of Byte;

Function FindStringInFile(const FileName : String; const SearchString : UnicodeString) : Boolean;
{Scan raw file bytes for the UTF-8 encoding of SearchString. ASCII needles
 (e.g. DOS4GW) are unchanged; wide chars must not match via low-byte truncation.}
Var MSt : TMemoryStream;
    I,J : Integer;
    B : Boolean;
    Needle : UTF8String;
begin
  result:=False;
  If not FileExists(FileName) then exit;
  Needle:=UTF8Encode(SearchString);
  If length(Needle)=0 then exit;
  MSt:=TMemoryStream.Create;
  try
    try MSt.LoadFromFile(FileName); except exit; end;
    For I:=0 to MSt.Size-length(Needle) do begin
      If TByteArray(MSt.Memory^)[I]<>Byte(Needle[1]) then continue;
      B:=True;
      for J:=2 to length(Needle) do
        If TByteArray(MSt.Memory^)[I+J-1]<>Byte(Needle[J]) then begin B:=False; break; end;
      if B then begin result:=True; exit; end;
    end;
  finally
    MSt.Free;
  end;
end;

Procedure SplitText(const St : TStringList; const Lines : String);
Var I : Integer;
    S : String;
    Src, Dst : AnsiString;
begin
  {CharToOemA needs real AnsiString buffers — not PAnsiChar(AnsiString(temp)).}
  Src:=AnsiString(Lines);
  SetLength(Dst,Length(Src)*2);
  If Length(Src)>0 then
    CharToOemA(PAnsiChar(Src),PAnsiChar(Dst));
  SetLength(Dst,lstrlenA(PAnsiChar(Dst)));
  S:=String(Dst);

  While length(S)>75 do begin
    I:=75;
    While (I>1) and (S[I]<>' ') do dec(I);
    If S[I]=' ' then begin
      {space in first 75 chars}
      St.Add('echo '+Trim(Copy(S,1,I-1)));
      S:=Trim(Copy(S,I+1,MaxInt));
    end else begin
      {no space in 1..75}
      I:=76;
      While (I<length(S)) and (S[I]<>' ') do inc(I);
      If I=length(S) then begin
        {no space at all}
        St.Add('echo '+Trim(S));
        exit;
      end else begin
        {space after 75}
        St.Add('echo '+Trim(Copy(S,1,I-1)));
        S:=Trim(Copy(S,I+1,MaxInt));
      end;
    end;
  end;
  St.Add('echo '+Trim(S));
end;

Function TempDir : String;
begin
  SetLength(result,515);
  GetTempPath(512,PChar(result));
  SetLength(result,StrLen(PChar(result)));
  result:=IncludeTrailingPathDelimiter(result);
end;

Function ShortName(const LongName : String) : String;
begin
  SetLength(result,MAX_PATH+10);
  if GetShortPathName(PChar(LongName),PChar(result),MAX_PATH)=0
    then result:=LongName
    else SetLength(result,StrLen(PChar(result)));
end;

Function MakeRelPath(Path, Rel : String; const NoEmptyRelPath : Boolean) : String;
Var FileName : String;
begin
  {No conversion if path DOSBox relative to DOSBox internal file system}
  If (ExtUpperCase(Copy(Trim(Path),1,7))='DOSBOX:') or (Trim(Path)='') then begin result:=Path; exit; end;

  {Check base path}
  Rel:=Trim(Rel); if Rel='' then begin result:=Path; exit; end;
  Rel:=IncludeTrailingPathDelimiter(Rel);

  {Split path into path an file name}
  If DirectoryExists(Path) then begin
    FileName:='';
    Path:=IncludeTrailingPathDelimiter(Path);
  end else begin
    FileName:=ExtractFileName(Path);
    Path:=IncludeTrailingPathDelimiter(ExtractFilePath(Path));
  end;

  {Convert}
  If (length(Path)>=length(Rel)) and (ExtUpperCase(Copy(Path,1,length(Rel)))=ExtUpperCase(Rel)) then begin
    {Path is relative to Rel}
    Path:='.\'+Copy(Path,length(Rel)+1,MaxInt);
  end else begin
    Rel:=IncludeTrailingPathDelimiter(ShortName(Rel));
    {May be Path is relative to the short version of Rel}
    If (length(Path)>=length(Rel)) and (ExtUpperCase(Copy(Path,1,length(Rel)))=ExtUpperCase(Rel)) then
      Path:='.\'+Copy(Path,length(Rel)+1,MaxInt);
  end;

  {Remove useless parts}
  If (Path='.\') or (Path='\') then Path:='';

  {Add file name again}
  result:=Path+FileName;

  {Set path to ".\" if empty and empty not allowed}
  if NoEmptyRelPath and (result='') then result:='.\';
end;

Function MakeAbsPath(Path, Rel : String) : string;
begin
  {No conversion if path DOSBox relative to DOSBox internal file system}
  If (ExtUpperCase(Copy(Trim(Path),1,7))='DOSBOX:') or (Trim(Path)='') then begin result:=Path; exit; end;

  {Check base path}
  Rel:=Trim(Rel); if Rel='' then begin result:=Path; exit; end;
  Rel:=IncludeTrailingPathDelimiter(Rel);

  {Check if path is already absolute}
  If (length(Path)>=2) and ((Path[2]=':') or (copy(Path,1,2)='\\')) then begin result:=Path; exit; end;

  {Remove leading ".\" or "\"}
  Path:=Trim(Path);
  If Copy(Path,1,2)='.\' then Path:=Trim(Copy(Path,3,MaxInt));
  If Copy(Path,1,1)='\' then Path:=Trim(Copy(Path,2,MaxInt));

  {Combine base path and relative path}
  result:=Rel+Path;
end;

Function MakeExtRelPath(Path, Rel : String) : String;
Var FileName,S,T,ShortPath : String;
    C : Integer;
begin
  {No conversion if path DOSBox relative to DOSBox internal file system}
  If (ExtUpperCase(Copy(Trim(Path),1,7))='DOSBOX:') or (Trim(Path)='') then begin result:=Path; exit; end;

  {Check base path}
  Rel:=Trim(Rel); if Rel='' then begin result:=Path; exit; end;
  Rel:=IncludeTrailingPathDelimiter(Rel);

  {Split path into path an file name}
  If DirectoryExists(Path) then begin
    FileName:='';
    Path:=IncludeTrailingPathDelimiter(Path);
  end else begin
    FileName:=ExtractFileName(Path);
    Path:=IncludeTrailingPathDelimiter(ExtractFilePath(Path));
  end;

  {Convert}
  If (length(Path)>=length(Rel)) and (ExtUpperCase(Copy(Path,1,length(Rel)))=ExtUpperCase(Rel)) then begin
    {Path is relative to Rel}
    Path:='.\'+Copy(Path,length(Rel)+1,MaxInt);
  end else begin
    {May be Path is relative to the short version of Rel}
    Rel:=IncludeTrailingPathDelimiter(ShortName(Rel));
    If (length(Path)>=length(Rel)) and (ExtUpperCase(Copy(Path,1,length(Rel)))=ExtUpperCase(Rel)) then
      Path:='.\'+Copy(Path,length(Rel)+1,MaxInt);
  end;

  {Check if path is ".." path to base path}
  If Copy(Path,1,2)<>'.\' then begin
    C:=0;
    S:=ShortName(Rel);
    ShortPath:=ShortName(Path);
    repeat
      If S<>'' then SetLength(S,length(S)-1);
      While (S<>'') and (S[length(S)]<>'\') do SetLength(S,length(S)-1);
      If S='' then break;
      inc(C);
      If (length(ShortPath)>=length(S)) and (ExtUpperCase(Copy(ShortPath,1,length(S)))=ExtUpperCase(S)) then begin
        T:=''; while C>0 do begin T:=T+'..\'; dec(C); end;
        Path:=T+Copy(ShortPath,length(S)+1,MaxInt);
        break;
      end;
    until False;
  end;

  {Remove useless parts}
  If Path='.\' then Path:='';

  {Combine base path and relative path}
  result:=Path+FileName;
end;

Function MakeExtAbsPath(Path, Rel : String) : string;
begin
  {No conversion if path DOSBox relative to DOSBox internal file system}
  If (ExtUpperCase(Copy(Trim(Path),1,7))='DOSBOX:') or (Trim(Path)='') then begin result:=Path; exit; end;

  {Check base path}
  Rel:=Trim(Rel); if Rel='' then begin result:=Path; exit; end;
  Rel:=IncludeTrailingPathDelimiter(Rel);

  {Check if path is already absolute}
  If (length(Path)>=2) and ((Path[2]=':') or (copy(Path,1,2)='\\')) then begin result:=Path; exit; end;

  Path:=Trim(Path);

  {Remove leading ".\" and directly combine base path and relative path (so next rule can't apply)}
  If Copy(Path,1,2)='.\' then begin
    Path:=Trim(Copy(Path,3,MaxInt));
    result:=Rel+Path;
    exit;
  end;

  {If path starts with "..\": remove it and remove last part in base path}
  If Copy(Path,1,3)='..\' then begin
    while Copy(Path,1,3)='..\' do begin
      If Rel='' then break;
      SetLength(Rel,length(Rel)-1);
      While (Rel<>'') and (Rel[length(Rel)]<>'\') do SetLength(Rel,length(Rel)-1);
      Path:=Copy(Path,4,MaxInt);
    end;
    result:=Rel+Path;
    exit;
  end;

  {Combine base path and relative path}
  result:=Rel+Path;
end;

Function RemoveIllegalFileNameChars(const Name : String) : String;
Var I : Integer;
begin
  result:='';
  For I:=1 to length(Name) do If Pos(Name[I],AllowedCharsDefault)>0 then result:=result+Name[I];
end;

Function GetFileVersionEx(const AFileName: string) : Cardinal;
var
  FileName: string;
  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  FI: PVSFixedFileInfo;
  VerSize: DWORD;
begin
  Result := Cardinal(-1);
  FileName := AFileName;
  UniqueString(FileName);
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Wnd);
  if InfoSize <> 0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if GetFileVersionInfo(PChar(FileName), Wnd, InfoSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then
          Result:= FI.dwFileVersionLS;
    finally
      FreeMem(VerBuf);
    end;
  end;
end;

Function BuildDFendXHTTPUserAgent(const AppVersion: String; WinMajor, WinMinor: Integer; const IsWow64: Boolean): String;
Var Arch: String;
begin
  if IsWow64 then Arch := 'WOW64' else Arch := 'Win32';
  Result := Format('DFendX/%s (Windows NT %d.%d; %s) Delphi 12 (THTTPClient)',
    [AppVersion, WinMajor, WinMinor, Arch]);
end;

Function IsWow64ProcessThis: Boolean;
{ IsWow64Process(GetCurrentProcess): True → WOW64 token, else Win32. }
Var
  Wow64: BOOL;
  IsWow64ProcessFn: function(hProcess: THandle; var Wow64Process: BOOL): BOOL; stdcall;
begin
  Result := False;
  IsWow64ProcessFn := GetProcAddress(GetModuleHandle(kernel32), 'IsWow64Process');
  if not Assigned(IsWow64ProcessFn) then Exit;
  if not IsWow64ProcessFn(GetCurrentProcess, Wow64) then Exit;
  Result := Wow64;
end;

Function GetThisModuleFileVersionString: String;
{ VS_VERSION_INFO from the loaded module (HInstance) — not GetFileVersionInfo(path). }
Var
  hResInfo: THandle;
  hResData: THandle;
  pRes: Pointer;
  pFileInfo: PVSFixedFileInfo;
  puLen: UINT;
begin
  Result := '0.0.0';
  hResInfo := FindResource(HInstance, MakeIntResource(1), RT_VERSION);
  if hResInfo = 0 then Exit;
  hResData := LoadResource(HInstance, hResInfo);
  if hResData = 0 then Exit;
  pRes := LockResource(hResData);
  if pRes = nil then Exit;
  if VerQueryValue(pRes, '\', Pointer(pFileInfo), puLen) then
    Result := Format('%d.%d.%d',
      [HiWord(pFileInfo.dwFileVersionMS), LoWord(pFileInfo.dwFileVersionMS),
       HiWord(pFileInfo.dwFileVersionLS)]);
end;

Function GetHostWindowsNTVersion(out WinMajor, WinMinor: Integer): Boolean;
Var
  vi: TOSVersionInfo;
begin
  { GetVersionEx: host OS as seen by this process (manifest may cap the value). }
  Result := False;
  WinMajor := 0;
  WinMinor := 0;
  FillChar(vi, SizeOf(vi), 0);
  vi.dwOSVersionInfoSize := SizeOf(vi);
  if not GetVersionEx(vi) then Exit;
  WinMajor := Integer(vi.dwMajorVersion);
  WinMinor := Integer(vi.dwMinorVersion);
  Result := True;
end;

Function GetDFendXHTTPUserAgent: String;
{ Builds the UA string. Call once at PrgSetup.Create and store on PrgSetup.HTTPUserAgent. }
Var
  WinMajor, WinMinor: Integer;
begin
  if not GetHostWindowsNTVersion(WinMajor, WinMinor) then begin
    WinMajor := 0;
    WinMinor := 0;
  end;
  Result := BuildDFendXHTTPUserAgent(
    GetThisModuleFileVersionString,
    WinMajor,
    WinMinor,
    IsWow64ProcessThis);
end;

Function VersionToInt(Version : String) : Integer;
Var I,J : Integer;
begin
  result:=0;
  I:=Pos('.',Version);
  while I>0 do begin
    J:=0; TryStrToInt(Copy(Version,1,I-1),J); Version:=Copy(Version,I+1,MaxInt);
    result:=result*100+J;
    I:=Pos('.',Version);
  end;
  J:=0; TryStrToInt(Version,J);
  result:=result*100+J;
end;

Function MainVersionStringToInt(S : String) : Integer;
Var I : Integer;
    T : String;
begin
  result:=0;
  S:=Trim(S);

  I:=Pos('.',S);
  If I=0 then begin T:=S; S:=''; end else begin T:=Trim(Copy(S,1,I-1)); S:=Trim(Copy(S,I+1,MaxInt)); end;
  try result:=result+StrToInt(T)*256*256; except end;

  I:=Pos('.',S);
  If I=0 then begin T:=S; S:=''; end else begin T:=Trim(Copy(S,1,I-1)); S:=Trim(Copy(S,I+1,MaxInt)); end;
  try result:=result+StrToInt(T)*256; except end;
end;

Function OldDOSBoxVersion(const Version : String) : Boolean;
Var D : Double;
    S : String;
    I : Integer;
begin
  result:=False;
  S:=Trim(Version);
  If Trim(S)='' then exit;
  For I:=1 to length(S) do If (S[I]=',') or (S[I]='.') then S[I]:=FormatSettings.DecimalSeparator;
  If not TryStrToFloat(S,D) then exit;
  result:=(D<MinSupportedDOSBoxVersion-0.0000001);
end;

Function GetFileDate(const FileName : String) : TDateTime;
Var hFile : THandle;
begin
  result:=0;

  hFile:=CreateFile(PChar(FileName),GENERIC_READ,FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,0,0);
  if hFile=INVALID_HANDLE_VALUE then exit;
  try
    result:=FileDateToDateTime(FileGetDate(hFile));
  finally
    CloseHandle(hFile);
  end;
end;

Function GetDosFileDate(const FileName : String) : Integer;
begin
  result:=DateTimeToFileDate(GetFileDate(FileName));
end;

function GetFileSize(const AFileName : String): Int64;
Var Rec : TSearchRec;
    I : Integer;
begin
  result:=0;
  I:=FindFirst(AFileName,faAnyFile,Rec);
  try
    If I=0 then result:=Rec.Size;
  finally
    FindClose(Rec);
  end;
end;

Function FileSizeToStr(const Size : Int64) : String;
begin
  If Size<1024 then begin result:=IntToStr(Size)+' Bytes'; exit; end;
  If Size<1024*1024 then begin result:=Format('%.1fKB',[Size/1024]); exit; end;
  If Size<1024*1024*1024 then begin result:=Format('%.1fMB',[Size/1024/1024]); exit; end;
  result:=Format('%.1fGB',[Size/1024/1024/1024]);
end;

Function GetScreensaverAllowStatus : Boolean;
Var I : Integer;
begin
  SystemParametersInfo(SPI_GETSCREENSAVEACTIVE,0,@I,0);
  result:=(I<>0);
end;

Procedure SetScreensaverAllowStatus(const Enable : Boolean);
begin
  SystemParametersInfo(SPI_SETSCREENSAVEACTIVE,Cardinal(Enable),nil,0);
end;

Type TCharsetNameRecord=record
  Name : String;
  Nr : Integer;
end;

const  CharsetNamesList : Array[0..17] of TCharsetNameRecord=(
  (Name: 'ANSI_CHARSET'; Nr: 0),
  (Name: 'DEFAULT_CHARSET'; Nr: 1),
  (Name: 'SYMBOL_CHARSET'; Nr: 2),
  (Name: 'SHIFTJIS_CHARSET'; Nr: $80),
  (Name: 'HANGEUL_CHARSET'; Nr: 129),
  (Name: 'GB2312_CHARSET'; Nr: 134),
  (Name: 'CHINESEBIG5_CHARSET'; Nr: 136),
  (Name: 'OEM_CHARSET'; Nr: 255),
  (Name: 'JOHAB_CHARSET'; Nr: 130),
  (Name: 'HEBREW_CHARSET'; Nr: 177),
  (Name: 'ARABIC_CHARSET'; Nr: 178),
  (Name: 'GREEK_CHARSET'; Nr: 161),
  (Name: 'TURKISH_CHARSET'; Nr: 162),
  (Name: 'VIETNAMESE_CHARSET'; Nr: 163),
  (Name: 'BALTIC_CHARSET'; Nr: 186),
  (Name: 'THAI_CHARSET'; Nr: 222),
  (Name: 'EASTEUROPE_CHARSET'; Nr: 238),
  (Name: 'RUSSIAN_CHARSET'; Nr: 204)
);

Function CharsetNameToFontCharSet(const Name : String) : Byte;
Var S : String;
    I,Nr : Integer;
begin
  result:=DEFAULT_CHARSET;

  S:=Trim(ExtUpperCase(Name));
  If not TryStrToInt(S,Nr) then Nr:=-1;
  For I:=Low(CharsetNamesList) to High(CharsetNamesList) do If (Trim(ExtUpperCase(CharsetNamesList[I].Name))=S) or (CharsetNamesList[I].Nr=Nr) then begin
    result:=CharsetNamesList[I].Nr; exit;
  end;
end;

Function CompareFiles(const File1, File2 : String) : Boolean;
const BSize=4096;
Var FSt1,FSt2 : TFileStream;
    B1,B2 : Array[0..BSize-1] of Byte;
    C : Cardinal;
    I,J : Integer;
begin
  result:=False;

  FSt1:=TFileStream.Create(File1,fmOpenRead);
  try
    FSt2:=TFileStream.Create(File2,fmOpenRead);
    try
      If FSt1.Size<>FSt2.Size then exit;
      C:=FSt1.Size;
      While C>0 do begin
        I:=Min(C,BSize);
        FSt1.ReadBuffer(B1,I);
        FSt2.ReadBuffer(B2,I);
        For J:=0 to I-1 do If B1[J]<>B2[J] then exit;
        dec(C,I);
      end;
    finally
      FSt2.Free;
    end;
  finally
    FSt1.Free;
  end;
  result:=True;
end;

Function CPUCount : Integer;
Var SystemInfo : TSystemInfo;
begin
  GetSystemInfo(SystemInfo);
  result:=SystemInfo.dwNumberOfProcessors;
end;

function IsRemoteSession: Boolean;
begin
  result:=(GetSystemMetrics(SM_REMOTESESSION)<>0);
end;

{ TBasePrgSetupH }

constructor TBasePrgSetupH.Create;
begin
  inherited Create;
  BooleanListUsed:=-1;
  IntegerListUsed:=-1;
  StringListUsed:=-1;
  FLastTimeStamp:=0;
  FChanged:=False;
end;

Procedure TBasePrgSetupH.ClearLists;
begin
  SetLength(BooleanList,0);
  SetLength(IntegerList,0);
  SetLength(StringList,0);
  SetLength(BooleanIndex,0);
  SetLength(IntegerIndex,0);
  SetLength(StringIndex,0);
end;

Function TBasePrgSetupH.IndexOf(const Nr : Integer; const List : TConfigRecArray; var Index : TConfigIndexArray) : Integer;
Var I : Integer;
begin
  If length(List)=0 then begin result:=-1; exit; end;
  If length(Index)=0 then begin
    SetLength(Index,List[length(List)-1].Nr+1);
    For I:=0 to length(Index)-1 do Index[I]:=-1;
    For I:=0 to length(List)-1 do Index[List[I].Nr]:=I;
  end;
  result:=Index[Nr];
end;

function TBasePrgSetupH.AddRec(const ANr: Integer; const ASection, AKey: String; var List: TConfigRecArray) : Integer;
Var I,J : Integer;
begin
  result:=length(List);
  SetLength(List,result+1);

  J:=result;
  If (result>0) and (ANr<List[result-1].Nr) then begin
    For I:=0 to result-1 do If ANr<List[I].Nr then begin J:=I; break; end;
    For I:=result-1 downto J do List[I+1]:=List[I];
    result:=J;
  end;

  with List[J] do begin
    Nr:=ANr;
    Section:=ASection;
    Key:=AKey;
    Cached:=False;
  end;
end;

function TBasePrgSetupH.AddRecFast(const ANr: Integer; const ASection, AKey: String; var List: TConfigRecArray; var UsedCounter : Integer) : Integer;
Var I,J : Integer;
begin
  if UsedCounter=length(List) then SetLength(List,UsedCounter+50);
  result:=UsedCounter;
  inc(UsedCounter);

  J:=result;
  If (result>0) and (ANr<List[result-1].Nr) then begin
    For I:=0 to result-1 do If ANr<List[I].Nr then begin J:=I; break; end;
    For I:=result-1 downto J do List[I+1]:=List[I];
    result:=J;
  end;

  with List[J] do begin
    Nr:=ANr;
    Section:=ASection;
    Key:=AKey;
    Cached:=False;
  end;
end;

procedure TBasePrgSetupH.FastAddRecDone;
begin
  if BooleanListUsed>=0 then SetLength(BooleanList,BooleanListUsed);
  If IntegerListUsed>=0 then SetLength(IntegerList,IntegerListUsed);
  If StringListUsed>=0 then SetLength(StringList,StringListUsed);
end;

procedure TBasePrgSetupH.FastAddRecStart;
begin
  BooleanListUsed:=0;
  IntegerListUsed:=0;
  StringListUsed:=0;
  SetLength(BooleanList,50);
  SetLength(IntegerList,50);
  SetLength(StringList,50);
end;

procedure TBasePrgSetupH.AddBooleanRec(const Nr: Integer; const Section, Key: String; const Default : Boolean);
Var I : Integer;
begin
  if BooleanListUsed>=0
    then I:=AddRecFast(Nr,Section,Key,BooleanList,BooleanListUsed)
    else I:=AddRec(Nr,Section,Key,BooleanList);
  BooleanList[I].DefaultBool:=Default;
  { IndexOf caches positions; must rebuild after any add. }
  SetLength(BooleanIndex,0);
end;

procedure TBasePrgSetupH.AddIntegerRec(const Nr: Integer; const Section, Key: String; const Default : Integer);
Var I : Integer;
begin
  If IntegerListUsed>=0
    then I:=AddRecFast(Nr,Section,Key,IntegerList,IntegerListUsed)
    else I:=AddRec(Nr,Section,Key,IntegerList);
  IntegerList[I].DefaultInteger:=Default;
  SetLength(IntegerIndex,0);
end;

procedure TBasePrgSetupH.AddStringRec(const Nr: Integer; const Section, Key: String; const Default : String);
Var I : Integer;
begin
  If StringListUsed>=0
    then I:=AddRecFast(Nr,Section,Key,StringList,StringListUsed)
    else I:=AddRec(Nr,Section,Key,StringList);
  StringList[I].DefaultString:=Default;
  SetLength(StringIndex,0);
end;

Procedure TBasePrgSetupH.SetChanged(Value: Boolean = True);
begin
  FChanged:=Value;
end;

Function TBasePrgSetupH.GetBinaryVersionID : Integer;
begin
  result:=1000*1000*length(BooleanList)+1000*length(IntegerList)+length(StringList);
end;

function TBasePrgSetupH.GetBoolean(const Index: Integer): Boolean;
Var I : Integer;
begin
  I:=IndexOf(Index,BooleanList,BooleanIndex);
  if I<0 then begin result:=False; exit; end;
  result:=BooleanList[I].DefaultBool;
end;

function TBasePrgSetupH.GetInteger(const Index: Integer): Integer;
Var I : Integer;
begin
  I:=IndexOf(Index,IntegerList,IntegerIndex);
  if I<0 then begin result:=0; exit; end;
  result:=IntegerList[I].DefaultInteger;
end;

function TBasePrgSetupH.GetString(const Index: Integer): String;
Var I : Integer;
begin
  I:=IndexOf(Index,StringList,StringIndex);
  if I<0 then begin result:=''; exit; end;
  result:=StringList[I].DefaultString;
end;

Procedure TBasePrgSetupH.LoadBinConfig(const St : TStream; const PConfig : PConfigRecArray; const ConfigType : TConfigType);
Var I,J : Integer;
    A : AnsiString;
begin
  {On-disk strings are byte-oriented (Ansi length + payload). Stream via AnsiString
   so Delphi UnicodeString is not half-written with Length as a byte count.}
  Case ConfigType of
    ctBoolean : For I:=0 to length(PConfig^)-1 do begin St.Read(PConfig^[I].CacheValueBool,SizeOf(Boolean)); PConfig^[I].Cached:=True; end;
    ctInteger : For I:=0 to length(PConfig^)-1 do begin St.Read(PConfig^[I].CacheValueInteger,SizeOf(Integer)); PConfig^[I].Cached:=True; end;
    ctString : For I:=0 to length(PConfig^)-1 do begin
                 St.Read(J,SizeOf(Integer));
                 If J>0 then begin
                   SetLength(A,J); St.Read(A[1],J);
                   PConfig^[I].CacheValueString:=String(A);
                 end else begin
                   PConfig^[I].CacheValueString:='';
                 end;
                 PConfig^[I].Cached:=True;
               end;
  end;
end;

Procedure TBasePrgSetupH.StoreBinConfig(const St : TStream; const PConfig : PConfigRecArray; const ConfigType : TConfigType);
Var I,J : Integer;
    A : AnsiString;
begin
  For I:=0 to length(PConfig^)-1 do Case ConfigType of
    ctBoolean : begin
                  If not PConfig^[I].Cached then GetBoolean(PConfig^[I].Nr);
                  St.WriteBuffer(PConfig^[I].CacheValueBool,SizeOf(Boolean));
                end;
    ctInteger : begin
                  If not PConfig^[I].Cached then GetInteger(PConfig^[I].Nr);
                  St.WriteBuffer(PConfig^[I].CacheValueInteger,SizeOf(Integer));
                end;
    ctString : begin
                 If not PConfig^[I].Cached then GetString(PConfig^[I].Nr);
                 A:=AnsiString(PConfig^[I].CacheValueString);
                 J:=Length(A);
                 St.WriteBuffer(J,SizeOf(Integer));
                 If J>0 then St.WriteBuffer(A[1],J);
               end;
  end;
end;

Procedure TBasePrgSetupH.LoadFromStream(const St : TStream);
begin
  LoadBinConfig(St,@BooleanList,ctBoolean);
  LoadBinConfig(St,@IntegerList,ctInteger);
  LoadBinConfig(St,@StringList,ctString);
  St.Read(FLastTimeStamp,SizeOf(FLastTimeStamp));
  FChanged:=False;
end;

Procedure TBasePrgSetupH.SaveToStream(const St : TStream);
begin
  StoreBinConfig(St,@BooleanList,ctBoolean);
  StoreBinConfig(St,@IntegerList,ctInteger);
  StoreBinConfig(St,@StringList,ctString);
  St.WriteBuffer(FLastTimeStamp,SizeOf(FLastTimeStamp));
end;

end.
