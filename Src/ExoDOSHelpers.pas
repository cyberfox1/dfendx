unit ExoDOSHelpers;

interface

uses
  Windows, SysUtils, Classes, Variants, XMLIntf, Xml.XMLDoc, CommonHelpers, ExoDOSDBUnit;

type
  TExoDOSAutoexecResult = class(TObject)
  public
    ExeName: String;
    Params: String;
    BootCommand: String;
end;

type
  TExoWaitResult = record
    ShowError1 : Boolean;
    ShowError2 : Boolean;
    Error1Shown : Boolean;
    Error2Shown : Boolean;
    ShouldSpin : Boolean;
    FinalCaption : String;
  end;

{$IFDEF FPC}
  TMediaFileEvent = procedure(const FullPath: String) of object;
{$ELSE}
  TMediaFileEvent = reference to procedure(const FullPath: String);
{$ENDIF}

{ Walk media directories (Images\MS-DOS, Videos\MS-DOS, manuals\MS-DOS) collecting files.
  Each result line: Category|FullPath. Recursion stops at depth 3.
  Only returns files with allowed media extensions and non-zero size. }
function GetExoMediaPaths(const ExoRoot : String; Callback : TMediaFileEvent = nil) : TStringList;

procedure ProcessExoDOSGames(const XMLDoc: TXMLDocument; const CachePath, DBPath: String; out GameCount: Integer);
function GetAutoExecSection(const ConfPath: String): TStringList;
function GetGameExe(const Lines: TStringList): TExoDOSAutoexecResult;
{ If GameRoot looks unpacked, find a setup-type program there.
  Name priority: setup, install, setsound, sound.
  Ext priority: .bat, .exe, .com.
  Returns full path or '' if none. Top-level of GameRoot only. }
function FindExoUnpackedSetupProgram(const GameRoot: String): String;
function ParseDataBlobValue(const DataBlob, Key : String) : String;
function GetGameDataByName(const ADB : TExoDOSDB; const Title : String; var Year, DataBlob : String) : Boolean;
function GetGameDataParamByName(const ADB : TExoDOSDB; const Title, Key : String) : String;

function NormalizeExoImageTitle(const Title : String) : String;
function ExoImageFileMatchesTitle(const FileName, Title : String) : Boolean;
{ DirPrefix: only dirs under Images\MS-DOS whose name starts with DirPrefix.
  If DirPrefix starts with '-', exclude dirs starting with the remainder (e.g. '-Screenshot -').
  Empty DirPrefix defaults to include 'Screenshot -'. Scans nested image files under each matching type dir. }
function ExoImagePathParts(const FullPath : String) : TStringList;
{ Directory segments under Images\MS-DOS for an extras image path (excludes filename). }
function ExoExtraImageSubdirs(const FullPath : String) : TStringList;
{ Caption: one segment => "TypeDir"; two+ => "Seg1 (Seg2)" (only first two used). }
function ExoExtraImageCaption(const FullPath : String) : String;
procedure CollectMedia(const Dir : String; const Extensions : array of String;
  Results : TStringList; Depth : Integer; MaxDepth : Integer = 3;
  Callback : TMediaFileEvent = nil);
function ExtractKind(const FullPath, Category : String) : String;
function StripExoTrailingYear(const S : String) : String;
function ExoMusicFileMatchesTitle(const FileName, Title : String; const ManualStem : String = '') : Boolean;
function GetExoMusicPaths(const ExoRoot, Title : String; const ADB : TExoDOSDB = nil) : TStringList;
{ Recurse under ExoRoot + ExtraRootPath + Extras for files whose extension is in Exts.
  ExtraRootPath is the game RootFolder (relative to ExoRoot). Exts: with or without leading dot. }
function GetExoGameExtrasPaths(const ExoRoot, ExtraRootPath : String;
  const Exts : array of String) : TStringList;

function GameExeIsUnderExoDOS(const GameExeFullPath, ExoDOSDir : String) : Boolean;

function NormalizeExoMediaKey(const S : String) : String;
function ExoMediaFilenameKey(const S : String) : String;

function EvaluateExoWaitState(
  Thread1 : TThread; var T1ErrorShown : Boolean; T1GameCount : Integer;
  Thread2 : TThread; var T2ErrorShown : Boolean; T2MediaCount : Integer
) : TExoWaitResult;

function InvertTheArticle(const S : String) : String;
function StripDiacritics(const S : String) : String;
function StripTrailingYear(const S : String) : String;
function NormalizeExoMediaStr(const S : String) : String;

implementation

uses LoggingUnit, PrgConsts;

function GetGameDataByName(const ADB : TExoDOSDB; const Title : String; var Year, DataBlob : String) : Boolean;
begin
  Year:='';
  DataBlob:='';
  result:=False;
  if (ADB=nil) or (Trim(Title)='') then exit;
  result:=ADB.GetGameDataByName(Title,Year,DataBlob);
end;

function GetGameDataParamByName(const ADB : TExoDOSDB; const Title, Key : String) : String;
Var Year, DataBlob : String;
begin
  result:='';
  if not GetGameDataByName(ADB,Title,Year,DataBlob) then exit;
  result:=ParseDataBlobValue(DataBlob,Key);
end;

function NormalizeExoImageTitle(const Title : String) : String;
Var I : Integer;
begin
  result:=Title;
  for I:=1 to Length(result) do
    if result[I]='''' then
      result[I]:='_';
end;

function ExoImageFileMatchesTitle(const FileName, Title : String) : Boolean;
Var Stem, Base, Rest : String;
    I : Integer;
begin
  result:=False;
  Base:=NormalizeExoImageTitle(Title);
  if Base='' then exit;
  Stem:=ChangeFileExt(ExtractFileName(FileName), '');
  if Length(Stem)<Length(Base)+2 then exit; {need Base + '-' + at least one digit}
  if not SameText(Copy(Stem, 1, Length(Base)+1), Base+'-') then exit;
  Rest:=Copy(Stem, Length(Base)+2, MaxInt);
  if Rest='' then exit;
  for I:=1 to Length(Rest) do
    if not (Rest[I] in ['0'..'9']) then exit;
  result:=True;
end;

function ExoImagePathParts(const FullPath : String) : TStringList;
Var DirName, Part : String;
    I, Start : Integer;
begin
  result:=TStringList.Create;
  DirName:=ExtractFileName(ExcludeTrailingPathDelimiter(ExtractFilePath(FullPath)));
  Start:=1;
  for I:=1 to Length(DirName)+1 do begin
    if (I>Length(DirName)) or (DirName[I]='-') then begin
      Part:=Trim(Copy(DirName, Start, I-Start));
      result.Add(Part);
      Start:=I+1;
    end;
  end;
end;

function ExoExtraImageSubdirs(const FullPath : String) : TStringList;
Var
  Marker, Norm, Rel, Seg : String;
  P, Start, I : Integer;
begin
  result:=TStringList.Create;
  if Trim(FullPath)='' then exit;

  Marker:='Images'+PathDelim+'MS-DOS'+PathDelim;
  Norm:=StringReplace(FullPath, '/', PathDelim, [rfReplaceAll]);
  P:=Pos(UpperCase(Marker), UpperCase(Norm));
  if P=0 then exit;

  Rel:=Copy(Norm, P+Length(Marker), MaxInt);
  Rel:=ExcludeTrailingPathDelimiter(ExtractFilePath(Rel));
  if Rel='' then exit;

  Start:=1;
  for I:=1 to Length(Rel)+1 do begin
    if (I>Length(Rel)) or (Rel[I]=PathDelim) then begin
      Seg:=Copy(Rel, Start, I-Start);
      if Seg<>'' then result.Add(Seg);
      Start:=I+1;
    end;
  end;
end;

function ExoExtraImageCaption(const FullPath : String) : String;
Var Sub : TStringList;
begin
  result:='';
  Sub:=ExoExtraImageSubdirs(FullPath);
  try
    if Sub.Count>=2 then
      result:=Sub[0]+' ('+Sub[1]+')'
    else if Sub.Count=1 then
      result:=Sub[0]
    else begin
      result:=ChangeFileExt(ExtractFileName(FullPath), '');
      if result='' then result:=ExtractFileName(FullPath);
    end;
  finally
    Sub.Free;
  end;
end;

function StripExoTrailingYear(const S : String) : String;
Var L : Integer;
begin
  result:=S;
  L:=Length(S);
  if (L>=7) and (S[L]=')') and (S[L-5]='(') and (S[L-6]=' ') and
     (S[L-1] in ['0'..'9']) and (S[L-2] in ['0'..'9']) and (S[L-3] in ['0'..'9']) and (S[L-4] in ['0'..'9']) then
    result:=Copy(S,1,L-7);
end;

function InvertTheArticle(const S : String) : String;
begin
  result:=S;
  if (Length(S)>=4) and SameText(Copy(S,1,4),'The ') then
    result:=Copy(S,5,MaxInt)+', The';
end;

function ExoMusicFileMatchesTitle(const FileName, Title : String; const ManualStem : String = '') : Boolean;
Var Stem, Base, Man : String;
begin
  result:=False;
  Base:=NormalizeExoImageTitle(Title);
  if Base='' then exit;
  Stem:=StripExoTrailingYear(ChangeFileExt(ExtractFileName(FileName), ''));
  if SameText(Stem, Base) then begin result:=True; exit; end;
  if SameText(Stem, InvertTheArticle(Base)) then begin result:=True; exit; end;
  Man:=StripExoTrailingYear(ManualStem);
  if (Man<>'') and SameText(Stem, Man) then begin result:=True; exit; end;
end;

function GetExoMusicPaths(const ExoRoot, Title : String; const ADB : TExoDOSDB = nil) : TStringList;
const
  MusicExts : array[0..4] of String = ('.mp3', '.ogg', '.wav', '.mid', '.midi');
Var
  MusicRoot, Full, Ext, ManualPath, ManualStem : String;
  Rec : TSearchRec;
  I, E : Integer;
begin
  result:=TStringList.Create;
  result.Sorted:=True;
  result.Duplicates:=dupIgnore;
  if (Trim(ExoRoot)='') or (Trim(Title)='') then exit;

  ManualStem:='';
  if ADB<>nil then begin
    ManualPath:=GetGameDataParamByName(ADB,Title,'ManualPath');
    if ManualPath<>'' then
      ManualStem:=StripExoTrailingYear(ChangeFileExt(ExtractFileName(ManualPath),''));
  end;

  MusicRoot:=IncludeTrailingPathDelimiter(ExoRoot)+'Music'+PathDelim+'MS-DOS'+PathDelim;
  if not DirectoryExists(MusicRoot) then exit;

  I:=FindFirst(MusicRoot+'*.*', faAnyFile, Rec);
  try
    while I=0 do begin
      if (Rec.Attr and faDirectory)=0 then begin
        Ext:=LowerCase(ExtractFileExt(Rec.Name));
        for E:=Low(MusicExts) to High(MusicExts) do
          if Ext=MusicExts[E] then begin
            if ExoMusicFileMatchesTitle(Rec.Name, Title, ManualStem) then begin
              Full:=MusicRoot+Rec.Name;
              result.Add(Full);
            end;
            break;
          end;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

procedure CollectMedia(const Dir : String; const Extensions : array of String;
  Results : TStringList; Depth : Integer; MaxDepth : Integer = 3;
  Callback : TMediaFileEvent = nil);
Var Rec : TSearchRec;
    I, L : Integer;
    FullPath, Ext : String;
begin
  if Depth>=MaxDepth then exit;
  I:=FindFirst(Dir+'*.*', faAnyFile, Rec);
  if I<>0 then exit;
  try
    while I=0 do begin
      if (Rec.Name<>'') and (Rec.Name[1]<>'.') then begin
        FullPath:=Dir+Rec.Name;
        if (Rec.Attr and faDirectory)<>0 then begin
          if (Rec.Name[1]<>'.') and (Rec.Name[1]<>'_') then
            CollectMedia(FullPath+PathDelim, Extensions, Results, Depth+1, MaxDepth, Callback);
        end else if Rec.Size>0 then begin
          Ext:=LowerCase(ExtractFileExt(Rec.Name));
          for L:=Low(Extensions) to High(Extensions) do begin
            if (Ext=LowerCase(Extensions[L])) or (Ext='.'+LowerCase(Extensions[L])) then begin
              if Assigned(Callback) then
                Callback(FullPath)
              else if Assigned(Results) then
                Results.Add(FullPath);
              break;
            end;
          end;
        end;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

function GetExoGameExtrasPaths(const ExoRoot, ExtraRootPath : String;
  const Exts : array of String) : TStringList;
Var
  RootFolder, ExtrasRoot : String;
begin
  result:=TStringList.Create;
  result.Sorted:=True;
  result.Duplicates:=dupIgnore;
  if (Trim(ExoRoot)='') or (Trim(ExtraRootPath)='') or (Length(Exts)=0) then exit;

  RootFolder:=StringReplace(ExtraRootPath,'/',PathDelim,[rfReplaceAll]);
  RootFolder:=StringReplace(RootFolder,'\',PathDelim,[rfReplaceAll]);

  ExtrasRoot:=IncludeTrailingPathDelimiter(ExoRoot)+ExcludeTrailingPathDelimiter(RootFolder)+PathDelim+'Extras'+PathDelim;
  if not DirectoryExists(ExtrasRoot) then exit;

  CollectMedia(ExtrasRoot, Exts, result, 0);
end;

function ExtractKind(const FullPath, Category : String) : String;
Var P : Integer;
begin
  result := '';
  if Category <> 'Images' then exit;
  P := Pos('MS-DOS' + PathDelim, FullPath);
  if P = 0 then exit;
  result := Copy(FullPath, P + Length('MS-DOS') + 1, MaxInt);
  P := LastDelimiter(PathDelim, result);
  if P > 0 then
    result := Copy(result, 1, P - 1)
  else
    result := '';
end;

{ GetExoMediaPaths }

function GetExoMediaPaths(const ExoRoot : String; Callback : TMediaFileEvent = nil) : TStringList;
const
  MediaDirs : array[0..3] of String = ('Images','Videos','manuals','Music');
var
  Root : String;
  I, J, OldCount : Integer;

  procedure CollectDir(const Dir, MediaDir : String; const Exts : array of String);
  var K : Integer;
  begin
{$IFDEF FPC}
    CollectMedia(Dir, Exts, result, 0);
    for K:=OldCount to result.Count-1 do
      result[K]:=MediaDir+'|'+result[K];
{$ELSE}
    if Assigned(Callback) then begin
      var Cat : String;
      Cat:=MediaDir;
      CollectMedia(Dir, Exts, nil, 0, 3,
        procedure(const FullPath: String)
        begin
          Callback(Cat+'|'+FullPath);
        end);
    end else begin
      CollectMedia(Dir, Exts, result, 0);
      for K:=OldCount to result.Count-1 do
        result[K]:=MediaDir+'|'+result[K];
    end;
{$ENDIF}
  end;

begin
  result:=TStringList.Create;
  if Trim(ExoRoot)='' then exit;
  Root:=IncludeTrailingPathDelimiter(ExoRoot);
  for I:=0 to High(MediaDirs) do begin
    OldCount:=result.Count;
    if MediaDirs[I]='Images' then
      CollectDir(Root+MediaDirs[I]+PathDelim+'MS-DOS'+PathDelim, MediaDirs[I], ImageExtensions)
    else if MediaDirs[I]='Videos' then
      CollectDir(Root+MediaDirs[I]+PathDelim+'MS-DOS'+PathDelim, MediaDirs[I], VideoExtensions)
    else if MediaDirs[I]='manuals' then
      CollectDir(Root+MediaDirs[I]+PathDelim+'MS-DOS'+PathDelim, MediaDirs[I], DocumentExtensions)
    else if MediaDirs[I]='Music' then
      CollectDir(Root+MediaDirs[I]+PathDelim+'MS-DOS'+PathDelim, MediaDirs[I], AudioExtensions);
  end;
end;

procedure ProcessExoDOSGames(const XMLDoc: TXMLDocument; const CachePath, DBPath: String; out GameCount: Integer);
Var I, J : Integer;
    N, NTitle, NRelease, NChild : IXMLNode;
    Title, Year, ReleaseDate : String;
    DB : TExoDOSDB;
    SB : TStringBuilder;
    JSONStr, delim, sValue : String;
    GamesFile : TextFile;
begin
  GameCount:=0;

  DB:=TExoDOSDB.Create(DBPath);
  try
    DB.Initialize;

    AssignFile(GamesFile,CachePath);
    Rewrite(GamesFile);
    SB:=TStringBuilder.Create;
    try
      For I:=0 to XMLDoc.DocumentElement.ChildNodes.Count-1 do begin
        N:=XMLDoc.DocumentElement.ChildNodes[I];
        if N.NodeName='Game' then begin
          NTitle:=N.ChildNodes.FindNode('Title');
          NRelease:=N.ChildNodes.FindNode('ReleaseDate');

          if NTitle<>nil then begin
            Title:=NTitle.NodeValue;
            Year:='';
            if NRelease<>nil then begin
              ReleaseDate:=NRelease.NodeValue;
              if Length(ReleaseDate)>=4 then Year:=Copy(ReleaseDate,1,4);
            end;

              delim := ',,';
              J := 0;
              while J < N.ChildNodes.Count do begin
                if J = 0 then begin
                  SB.Clear;
                  delim := delim + ',';
                end;
                NChild := N.ChildNodes[J];
                if (NChild.NodeName='Title') or (NChild.NodeName='ReleaseDate') then begin
                  Inc(J);
                  continue;
                end;
                if NChild.NodeValue <> Null then begin
                  sValue := String(NChild.NodeValue);
                  if Pos(delim, sValue) > 0 then begin
                    delim := delim + ',';
                    J := 0;
                    continue;
                  end;
                  if SB.Length > 0 then
                    SB.Append(delim);
                  SB.Append(NChild.NodeName).Append('=').Append(sValue);
                end;
                Inc(J);
              end;
              JSONStr := SB.ToString;
              JSONStr := IntToStr(Length(delim)) + ',' + JSONStr;

              DB.AddGame(Title, Year, JSONStr);

            if Year<>'' then WriteLn(GamesFile,Title+' ('+Year+')') else WriteLn(GamesFile,Title);
            Inc(GameCount);
          end;
        end;
      end;

    finally
      SB.Free;
      CloseFile(GamesFile);
    end;

    DB.FinalizeLoad;
  finally
    DB.Free;
  end;
end;

function GetAutoExecSection(const ConfPath: String): TStringList;
var
  Lines: TStringList;
  I, SectionStart: Integer;
  S: String;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(ConfPath);
    SectionStart := -1;
    for I := 0 to Lines.Count - 1 do
      if ExtUpperCase(Trim(Lines[I])) = '[AUTOEXEC]' then begin
        SectionStart := I + 1;
        break;
      end;
    if SectionStart < 0 then exit;
    for I := SectionStart to Lines.Count - 1 do begin
      S := Trim(Lines[I]);
      if S = '' then continue;
      if S[1] = '[' then break;
      Result.Add(S);
    end;
  finally
    Lines.Free;
  end;
end;

function GetGameExe(const Lines: TStringList): TExoDOSAutoexecResult;

  function FirstWord(const S: String; out Rest: String): String;
  var P: Integer;
  begin
    P := Pos(' ', S);
    if P > 0 then begin
      Result := Copy(S, 1, P - 1);
      Rest := Trim(Copy(S, P + 1, MaxInt));
    end else begin
      Result := S;
      Rest := '';
    end;
  end;

  function IsAutoexecNoise(const U: String): Boolean;
  begin
    Result := (U = '') or (U = 'EXIT') or (U = 'CLS') or
      (U = 'REM') or (U = '#') or (U = 'VER') or
      (U = 'MIXER') or (U = 'CD') or (U = 'SET') or (U = 'KEYB') or
      (Copy(U, 1, 4) = 'ECHO') or (Copy(U, 1, 5) = 'PAUSE') or
      (Copy(U, 1, 5) = 'MOUNT') or (Copy(U, 1, 7) = 'IMGMOUNT') or
      (Copy(U, 1, 3) = 'CD ') or (Copy(U, 1, 4) = 'SET ') or
      (Copy(U, 1, 5) = 'KEYB ') or (Copy(U, 1, 6) = 'MIXER ') or
      (Copy(U, 1, 5) = 'PATH=') or
      ((Length(U) = 2) and (U[2] = ':') and (U[1] in ['A'..'Z']));
  end;

  function IsBlacklistedCommand(const U: String): Boolean;
  begin
    Result := (U = 'SBFMDRV') or (U = 'CWSDPMI') or (U = 'LOADFIX') or
      (U = 'MOUSE') or (U = 'MOUSEOFF') or (U = 'MRESET') or
      (U = 'SETUP') or (U = 'KEYBOARD') or (U = 'SOUND') or
      (U = 'TANDY') or (U = 'CTMOUSE') or (U = 'MIXER') or
      (U = 'DOS4GW') or (U = 'JEMMEX') or (U = 'NOKEY') or
      (U = 'KF_FIX');
  end;

  function HasExeExtension(const U: String): Boolean;
  var L: Integer;
  begin
    L := Length(U);
    Result := (L > 4) and (
      (Copy(U, L - 3, 4) = '.EXE') or
      (Copy(U, L - 3, 4) = '.BAT') or
      (Copy(U, L - 3, 4) = '.COM'));
  end;

var
  Candidates, NonCandidates: TStringList;
  I: Integer;
  S, Stripped, Upper, Token, Rest: String;
  HasAtPrefix: Boolean;

begin
  Result := nil;
  Candidates := TStringList.Create;
  NonCandidates := TStringList.Create;
  try
    for I := 0 to Lines.Count - 1 do begin
      S := Trim(Lines[I]);
      if S = '' then continue;

      HasAtPrefix := (S[1] = '@');
      if HasAtPrefix then Stripped := Copy(S, 2, MaxInt)
      else Stripped := S;

      Upper := ExtUpperCase(Stripped);
      if IsAutoexecNoise(Upper) then continue;

      Token := FirstWord(Upper, Rest);
      if IsBlacklistedCommand(Token) then continue;

      if Token = 'CALL' then begin
        Candidates.Add(Stripped);
        continue;
      end;

      if Token = 'BOOT' then begin
        Candidates.Add(Stripped);
        continue;
      end;

      if HasExeExtension(Token) then begin
        Candidates.Add(Stripped);
        continue;
      end;

      if HasAtPrefix then begin
        Candidates.Add(Stripped);
        continue;
      end;

      NonCandidates.Add(Stripped);
    end;

    if Candidates.Count > 0 then begin
      S := Candidates[Candidates.Count - 1];
      Token := FirstWord(S, Rest);
      Result := TExoDOSAutoexecResult.Create;
      if ExtUpperCase(Token) = 'BOOT' then
        Result.BootCommand := S
      else if ExtUpperCase(Token) = 'CALL' then begin
        Result.ExeName := FirstWord(Rest, Result.Params);
      end else begin
        Result.ExeName := Token;
        Result.Params := Rest;
      end;
    end else if NonCandidates.Count > 0 then begin
      S := NonCandidates[NonCandidates.Count - 1];
      Token := FirstWord(S, Rest);
      Result := TExoDOSAutoexecResult.Create;
      Result.ExeName := Token;
      Result.Params := Rest;
    end;

  finally
    NonCandidates.Free;
    Candidates.Free;
  end;
end;

function FindExoUnpackedSetupProgram(const GameRoot: String): String;
const
  BaseNames: array[0..3] of String = ('setup', 'install', 'setsound', 'sound');
  Exts: array[0..2] of String = ('.bat', '.exe', '.com');
var
  Root, Candidate: String;
  I, J: Integer;
begin
  Result := '';
  Root := IncludeTrailingPathDelimiter(GameRoot);
  if (Trim(GameRoot) = '') or (not DirectoryExists(Root)) then
    Exit;

  for I := Low(BaseNames) to High(BaseNames) do
    for J := Low(Exts) to High(Exts) do
    begin
      Candidate := Root + BaseNames[I] + Exts[J];
      if FileExists(Candidate) then
      begin
        Result := Candidate;
        Exit;
      end;
    end;
end;

function ParseDataBlobValue(const DataBlob, Key : String) : String;
Var P, DelimLen : Integer;
    KeyEq, DelimStr, CurrentBlob : String;
    Pairs : TArray<String>;
    PairStr : String;
begin
  result:='';
  if (DataBlob='') or (Key='') then exit;
  P:=Pos(',',DataBlob);
  if P=0 then exit;
  DelimLen:=StrToIntDef(Copy(DataBlob,1,P-1), 0);
  DelimStr:=StringOfChar(',',DelimLen);
  CurrentBlob:=Copy(DataBlob,P+1,MaxInt);
  KeyEq:=Key+'=';
  if DelimLen = 0 then begin
    SetLength(Pairs, 1);
    Pairs[0]:=CurrentBlob;
  end else
    Pairs:=CurrentBlob.Split([DelimStr]);
  for PairStr in Pairs do begin
    if Length(PairStr) > Length(KeyEq) then begin
      if Copy(PairStr, 1, Length(KeyEq)) = KeyEq then begin
        result := Copy(PairStr, Length(KeyEq) + 1, MaxInt);
        exit;
      end;
    end;
  end;
end;

function GameExeIsUnderExoDOS(const GameExeFullPath, ExoDOSDir : String) : Boolean;
Var S, ED : String;
begin
  result:=False;
  S:=Trim(GameExeFullPath);
  ED:=IncludeTrailingPathDelimiter(Trim(ExoDOSDir));
  If (S='') or (ED='') then exit;
  { Case-insensitive: Windows paths; also used to suppress missing-exe / mount warnings. }
  result:=SameText(Copy(S,1,Length(ED)), ED);
end;

function StripDiacritics(const S : String) : String;
Var WS : WideString;
    Buff : array[0..511] of WideChar;
    Len : Integer;
begin
  WS:=WideString(S);
  try
    Len:=FoldStringW(MAP_FOLDCZONE,PWideChar(WS),Length(WS),Buff,512);
    if Len>0 then begin
      Buff[Len]:=#0;
      result:=String(WideCharToString(Buff));
    end else
      result:=S;
  except
    on E : Exception do begin
      LogInfo('StripDiacritics: FoldStringW failed, input="'+S+'" error='+E.ClassName+': '+E.Message);
      result:=S;
    end;
  end;
end;

function StripTrailingYear(const S : String) : String;
Var L : Integer;
begin
  result:=S;
  L:=Length(result);
  if L<7 then exit;
  if (result[L-5]='(') and (result[L]=')')
    and (result[L-4] in ['0'..'9'])
    and (result[L-3] in ['0'..'9'])
    and (result[L-2] in ['0'..'9'])
    and (result[L-1] in ['0'..'9']) then
    result:=Trim(Copy(result,1,L-6));
end;

function NormalizeExoMediaStr(const S : String) : String;
Var Cleaned : String;
    I : Integer;
    C : Char;
begin
  Cleaned:=Trim(S);
  { Replace apostrophe with space }
  for I:=1 to Length(Cleaned) do
    if Cleaned[I]='''' then Cleaned[I]:=' ';
  { Replace non-alphanumeric with space }
  for I:=1 to Length(Cleaned) do begin
    C:=Cleaned[I];
    if not (C in ['a'..'z','A'..'Z','0'..'9',' ']) then
      Cleaned[I]:=' ';
  end;
  { Collapse multiple spaces }
  result:='';
  for I:=1 to Length(Cleaned) do begin
    if (Cleaned[I]<>' ') or ((result<>'') and (result[Length(result)]<>' ')) then
      result:=result+Cleaned[I];
  end;
  result:=Trim(result);
  result:=SysUtils.LowerCase(result);
end;

function NormalizeExoMediaKey(const S : String) : String;
Var Cleaned : String;
    Tokens : TStringList;
    I : Integer;
begin
  Cleaned:=Trim(S);
  Cleaned:=NormalizeExoMediaStr(Cleaned);
  Tokens:=TStringList.Create;
  try
    Tokens.DelimitedText:=Cleaned;
    for I:=Tokens.Count-1 downto 0 do
      if SameText(Tokens[I],'a') or SameText(Tokens[I],'an')
         or SameText(Tokens[I],'the') or SameText(Tokens[I],'and') then
        Tokens.Delete(I);
    result:='';
    for I:=0 to Tokens.Count-1 do begin
      if I>0 then result:=result+' ';
      result:=result+Tokens[I];
    end;
  finally
    Tokens.Free;
  end;
end;

function ExoMediaFilenameKey(const S : String) : String;
Var Cleaned : String;
    I : Integer;
begin
  Cleaned:=Trim(S);
  { Strip extension }
  for I:=Length(Cleaned) downto 1 do
    if Cleaned[I]='.' then begin
      Cleaned:=Copy(Cleaned,1,I-1);
      break;
    end;
  { Strip trailing -NN (hyphen digits) }
  I:=Length(Cleaned);
  if (I>=3) and (Cleaned[I] in ['0'..'9']) and (Cleaned[I-1] in ['0'..'9']) and (Cleaned[I-2]='-') then begin
    Cleaned:=Copy(Cleaned,1,I-3);
  end else if (I>=2) and (Cleaned[I] in ['0'..'9']) and (Cleaned[I-1]='-') then begin
    Cleaned:=Copy(Cleaned,1,I-2);
  end;
  Cleaned:=Trim(Cleaned);
  Cleaned:=StripTrailingYear(Cleaned);
  Cleaned:=NormalizeExoMediaKey(Cleaned);
  result:=Cleaned;
end;

{ EvaluateExoWaitState }

function EvaluateExoWaitState(
  Thread1 : TThread; var T1ErrorShown : Boolean; T1GameCount : Integer;
  Thread2 : TThread; var T2ErrorShown : Boolean; T2MediaCount : Integer
) : TExoWaitResult;
Var
  T1Done, T2Done : Boolean;
begin
  result.ShowError1:=False;
  result.ShowError2:=False;
  result.Error1Shown:=False;
  result.Error2Shown:=False;
  result.ShouldSpin:=False;
  result.FinalCaption:='';

  if Thread1=nil then begin
    T1Done:=True;
  end else begin
    T1Done:=WaitForSingleObject(Thread1.Handle,0)=WAIT_OBJECT_0;
    if T1Done and (Thread1.FatalException<>nil) and (not T1ErrorShown) then begin
      result.ShowError1:=True;
      T1ErrorShown:=True;
    end;
  end;
  result.Error1Shown:=T1ErrorShown;

  if Thread2=nil then begin
    T2Done:=True;
  end else begin
    T2Done:=WaitForSingleObject(Thread2.Handle,0)=WAIT_OBJECT_0;
    if T2Done and (Thread2.FatalException<>nil) and (not T2ErrorShown) then begin
      result.ShowError2:=True;
      T2ErrorShown:=True;
    end;
  end;
  result.Error2Shown:=T2ErrorShown;

  if not (T1Done and T2Done) then begin
    result.ShouldSpin:=True;
    exit;
  end;

  { Both threads done }
  if (Thread2<>nil) and ((Thread2.FatalException<>nil) or (T2MediaCount<1)) then
    result.FinalCaption:='Failed to load media';

  if (Thread1=nil) or (Thread1.FatalException<>nil) or (T1GameCount<1) then
    result.FinalCaption:='Failed to read XML games list'
  else if result.FinalCaption='' then
    result.FinalCaption:='Read '+IntToStr(T1GameCount)+' games';
end;

end.
