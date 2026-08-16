unit DosBoxUnit;
interface

uses Classes, GameDBUnit;

Procedure RunGame(const Game : TGame; const DeleteOnExit : TStringList; const RunSetup : Boolean = False; const DosBoxCommandLine : String =''; const Wait : Boolean = False);
Function RunGameAndGetHandle(const Game : TGame; const DeleteOnExit : TStringList; const RunSetup : Boolean = False; const DosBoxCommandLine : String ='') : THandle;
Procedure RunExtraFile(const Game : TGame; const DeleteOnExit : TStringList; const ExtraFile : Integer);
Procedure RunCommand(const Game : TGame; const DeleteOnExit : TStringList; const Command : String; const DisableFullscreen : Boolean = False);
Procedure RunCommandAndWait(const Game : TGame; const DeleteOnExit : TStringList; const Command : String; const DisableFullscreen : Boolean = False);
Function RunCommandAndGetHandle(const Game : TGame; const DeleteOnExit : TStringList; const Command : String; const DisableFullscreen : Boolean = False) : THandle;
Procedure RunWithCommandline(const Game : TGame; const DeleteOnExit : TStringList; const CommandLine : String; const DisableFullscreen : Boolean = False);
Procedure RunWithCommandlineAndWait(const Game : TGame; const DeleteOnExit : TStringList; const CommandLine : String; const DisableFullscreen : Boolean = False);

Function BuildConfFile(const Game : TGame; const RunSetup : Boolean; const WarnIfNotReachable : Boolean; const RunExtraFile : Integer; const DeleteOnExit : TStringList; const BuildForArchivePackage : Boolean) : TStringList;
Function BuildAutoexec(const Game : TGame; const RunSetup : Boolean; const St : TStringList; const WarnIfNotReachable : Boolean; const RunExtraFile : Integer; const WarnIfWindowsExe, SelectCD : Boolean; const BuildForArchivePackage : Boolean) : Boolean;
Function GetDOSBoxCommandLine(const DOSBoxNr : Integer; const ConfFile : String; const ShowConsole : Integer; const DosBoxCommandLine : String ='') : String;

var MinimizedAtDOSBoxStart : Boolean = False;

implementation

uses Winapi.Windows, SysUtils, ShellAPI, Forms, Dialogs, ShlObj, Math, System.IOUtils,
     CommonHelpers, CommonTools, PrgSetupUnit, PrgConsts, LanguageSetupUnit, GameDBToolsUnit,
     GameDBToolsHelpers, GameDBHelpers, ZipManagerUnit, ScreensaverControlUnit, FullscreenInfoFormUnit,
     DOSBoxCountUnit, DOSBoxShortNameUnit, RunPrgManagerUnit,
     SelectCDDriveToMountFormUnit, SelectCDDriveToMountByDataFormUnit, System.UITypes,
     FileNameConvertor, DOSBoxTempUnit, WindowsFileWarningFormUnit, MIDITools,
     HistoryUnit, DOSBoxUnitHelpers, DosBoxHelpers, BassMedia, ExoDOSHelpers,
     DOSBoxShadersHelpers, LoggingUnit, DosBoxConfUnit;

Procedure AppendCustomSettingsToConf(const Dest: TStrings; const Custom: String); forward;
Procedure AppendPureCustomSettingsToCfg(const Cfg: TStrings; const Custom: String); forward;
Function ParsePureCustomSettingLine(const Line: String; out Key, Val: String): Boolean; forward;
Procedure GeneratePureMidiCfg(const Game: TGame; const Cfg: TStrings; const WorkDir: String); forward;
Procedure GeneratePureGraphicsCfg(const Game: TGame; const Cfg: TStrings); forward;


var SpeedTestSt : TStringList = nil;
    LastSpeedTestStep : String = '';
    LastSpeedTestStep2 : String = '';
    LastSpeedTestTickCount : Cardinal;
    SpeedTest : Integer =-1;

Function SpeedTestLogFile : String;
begin
  result:=GetSpecialFolder(Application.MainForm.Handle,CSIDL_DESKTOPDIRECTORY)+'DFendX-DOSBoxStartLog.txt';
end;

Function IsSpeedTest : Boolean;
begin
  if SpeedTest=-1 then begin
    result:=PrgSetup.DOSBoxStartLogging or FileExists(SpeedTestLogFile);
    if result then SpeedTest:=1 else SpeedTest:=0;
  end else begin
    result:=(SpeedTest=1);
  end;
end;

Procedure SpeedTestInfo(const Info : String; const Init : Boolean=False);
begin
  if not IsSpeedTest then exit;

  If Assigned(SpeedTestSt) then begin
    SpeedTestSt.Add(LastSpeedTestStep+': '+IntToStr(GetTickCount-LastSpeedTestTickCount)+'ms');
    If LastSpeedTestStep2<>'' then SpeedTestSt.Add('  '+LastSpeedTestStep2);
    LastSpeedTestStep:=Info;
    LastSpeedTestStep2:='';
    LastSpeedTestTickCount:=GetTickCount;
    exit;
  end;

  LastSpeedTestStep:='';
  LastSpeedTestStep2:='';

  If not Init then exit;

  SpeedTestSt:=TStringList.Create;
  SpeedTestSt.Add(TimeToStr(Now)+' ### Benchmarking DOSBox start ###'+#13);
  LastSpeedTestStep:=Info;
  LastSpeedTestTickCount:=GetTickCount;
end;

Procedure SpeedTestInfoOnly(const Info : String);
begin
  if not IsSpeedTest then exit;

  If Assigned(SpeedTestSt) then begin
    LastSpeedTestStep2:=Info;
  end;
end;

Procedure SpeedTestDone;
Var St : TStringList;
begin
  if not IsSpeedTest then exit;

  If not Assigned(SpeedTestSt) then exit;
  SpeedTestInfo('');
  try
    St:=TStringList.Create;
      If FileExists(SpeedTestLogFile) then begin
        try
          St.LoadFromFile(SpeedTestLogFile);
        finally
        end;
      end;
      St.Add('');
      St.AddStrings(SpeedTestSt);
      St.SaveToFile(SpeedTestLogFile);
  finally
    FreeAndNil(SpeedTestSt);
  end;
end;

{ Always-on launch diagnostics (TEMP\DFendX-Log.txt via LoggingUnit). }
function IsShaderConfLine(const Line: String): Boolean;
var
  U: String;
begin
  U:=Trim(ExtUpperCase(Line));
  Result:=(Copy(U,1,7)='SHADER=') or (Copy(U,1,9)='GLSHADER=') or
    (Copy(U,1,12)='PIXELSHADER=');
end;

procedure LogConfShaderAndPath(const Conf: TStrings; const ConfPath: String;
  const Game: TGame);
var
  I: Integer;
  Found: Boolean;
begin
  LogInfo('DOSBox conf path: '+ConfPath);
  if (Game<>nil) and (Game.DosBoxKind=dbkPure) then exit;
  if Game<>nil then
    LogInfo('Profile shaders: PixelShader="'+Game.PixelShader+
      '" ShaderPreset="'+Game.ShaderPreset+
      '" Kind='+IntToStr(Ord(Game.DosBoxKind)));
  Found:=False;
  if Conf<>nil then
    for I:=0 to Conf.Count-1 do
      if IsShaderConfLine(Conf[I]) then begin
        LogInfo('  conf line: '+Conf[I]);
        Found:=True;
      end;
  if not Found then
    LogInfo('  conf line: (no shader=/glshader=/pixelshader= lines written)');
end;

{ BoolToStr moved to DosBoxHelpers }

{ ShortName moved to DosBoxHelpers }

{ LongPath moved to DosBoxHelpers }

{Function LongPath(const Root, ShortPath : String) : String; -> WinExpandLongPathName
Var Rec : TSearchRec;
    I : Integer;
    LongRoot, ShortRoot : String;
begin
  LongRoot:=IncludeTrailingPathDelimiter(Root);
  ShortRoot:=ExtUpperCase(IncludeTrailingPathDelimiter(ShortName(LongRoot)));

  result:=ShortPath;

  I:=FindFirst(LongRoot+'*.*',faAnyFile,Rec);
  try
    While I=0 do begin
      I:=FindNext(Rec);
      If ExtUpperCase(ShortName(LongRoot+Rec.Name))=ShortRoot+ExtUpperCase(ShortPath) then begin
        result:=Rec.Name; exit;
      end;
    end;
  finally
    FindClose(Rec);
  end;
end;}

{ AllSameDir moved to DosBoxHelpers }

Function MakeDOSBoxPath(Part, Root : String) : String;
Var S : String;
    I : Integer;
begin
  Root:=IncludeTrailingPathDelimiter(Root);
  result:='';
  Part:=ExcludeTrailingPathDelimiter(Part);
  If (Part<>'') and (Part[1]='\') then Part:=Copy(Part,2,MaxInt);

  while Part<>'' do begin
    I:=Pos('\',Part);
    If I=0 then begin S:=Part; Part:=''; end else begin S:=Copy(Part,1,I-1); Part:=Copy(Part,I+1,MaxInt); end;
    S:=WinExpandLongPathName(Root,S);
    result:=result+'\'+DOSBoxShortName(MakeAbsPath(Root,PrgSetup.BaseDir),S);
    Root:=Root+S+'\';
  end;

  If result='' then result:='\';
end;

Function SpecialMultiImgMount(const DriveLetter : String; const Imgs : TStringList; const FreeDriveLetters : String; const MountCommandAdd : String) : String;
Var I : Integer;
    TempDrive : Char;
    Path,S : String;
begin
  TempDrive:='Y';
  For I:=length(FreeDriveLetters) downto 1 do If FreeDriveLetters[I]<>'-' then begin TempDrive:=FreeDriveLetters[I]; break; end;
  {There must be free drive letters, because there are only 10 mounts}

  Path:=IncludeTrailingPathDelimiter(ExtractFilePath(ShortName(Imgs[0])));

  S:='"'+TempDrive+':\'+DOSBoxShortName(ExtractFilePath(Imgs[0]),ExtractFileName(Imgs[0]))+'"';
  For I:=1 to Imgs.Count-1 do S:=S+' "'+TempDrive+':\'+DOSBoxShortName(ExtractFilePath(Imgs[I]),ExtractFileName(Imgs[I]))+'"';

  result:=
    'mount '+TempDrive+' "'+UnmapDrive(Path,ptMount)+'"'+#13+
    'imgmount '+DriveLetter+' '+S+' '+MountCommandAdd+#13+
    'mount -u '+TempDrive;
end;

Function GetCDDrives : String;
Var C : Char;
begin
  result:='';
  For C:='A' to 'Z' do if GetDriveType(PChar(C+':\'))=DRIVE_CDROM then result:=result+C;
end;

Function SpecialCDDriveMounting(var Folder : String; const DriveLetter : String; const ProfileName : String; const SelectCD : Boolean; var SpecialMountedCDDrives : String) : Boolean;
Var S,T,U,Drives : String;
    I : Integer;
begin
  result:=True;
  S:=Trim(ExtUpperCase(Folder));

  {ASK /  NUMBER:x /  LABEL:x / FILE:x / FOLDER:x}

  If S='ASK' then begin
    Drives:=GetCDDrives;
    If length(Drives)=0 then begin
      If SelectCD then begin
        MessageDlg(Format(LanguageSetup.MessageNoCDDriveMount,[DriveLetter]),mtError,[mbOK],0);
        result:=False;
      end;
      Folder:=''; exit;
    end;
    If (length(Drives)=1) or (not SelectCD) then begin Folder:=Drives[1]+':\'; SpecialMountedCDDrives:=SpecialMountedCDDrives+Drives[1]; exit; end;
    result:=ShowSelectCDDriveToMountDialog(Application.MainForm,Drives,DriveLetter,ProfileName,Folder);
    if result then SpecialMountedCDDrives:=SpecialMountedCDDrives+Folder[1];
    exit;
  end;

  If Pos(':',S)=0 then exit;
  T:=Copy(S,Pos(':',S)+1,MaxInt);
  S:=Copy(S,1,Pos(':',S)-1);

  Drives:=GetCDDrives;
  If length(Drives)=0 then begin
    If SelectCD and (S='LABEL') or (S='FILE') or (S='FOLDER') then begin
      MessageDlg(Format(LanguageSetup.MessageNoCDDriveMount,[DriveLetter]),mtError,[mbOK],0);
      result:=False;
      Folder:=''; exit;
    end;
  end;

  If S='NUMBER' then begin
    If not TryStrToInt(T,I) then I:=1;
    I:=Max(1,Min(length(Drives),I));
    SpecialMountedCDDrives:=SpecialMountedCDDrives+Drives[I];
    Folder:=Drives[I]+':\'; exit;
  end;
  If SelectCD then begin
    If S='LABEL' then begin
      result:=ShowSelectCDDriveToMountByDataDialog(Application.MainForm,mbLabel,T,DriveLetter,ProfileName,U);
      If result then begin Folder:=U+':\'; SpecialMountedCDDrives:=SpecialMountedCDDrives+U; end else Folder:='';
      exit;
    end;
    If S='FILE' then begin
      result:=ShowSelectCDDriveToMountByDataDialog(Application.MainForm,mbFile,T,DriveLetter,ProfileName,U);
      If result then begin Folder:=U+':\'; SpecialMountedCDDrives:=SpecialMountedCDDrives+U; end else Folder:='';
      exit;
    end;
    If S='FOLDER' then begin
      result:=ShowSelectCDDriveToMountByDataDialog(Application.MainForm,mbFolder,T,DriveLetter,ProfileName,U);
      If result then begin Folder:=U+':\'; SpecialMountedCDDrives:=SpecialMountedCDDrives+U; end else Folder:='';
      exit;
    end;
  end;
end;

Function BuildMountData(const ProfString : String; const DOSBoxVersion : Double; var FreeDriveLetters : String; const ProfileName : String; const SelectCD : Boolean; var OK : Boolean; var SpecialMountedCDDrives : String; const BuildForArchivePackage : Boolean) : String;
Procedure MarkDriveUsed(S : String);
begin
  S:=Trim(ExtUpperCase(S)); If length(S)<>1 then exit;
  If (S[1]<'A') or (S[1]>'Z') then exit;
  FreeDriveLetters[Ord(S[1])-Ord('A')+1]:='-';
end;
Var St,St2 : TStringList;
    S,T,U,V : String;
    I : Integer;
begin
  result:=''; OK:=True;

  St:=ValueToList(ProfString);
  St2:=TStringList.Create;
  try
    If St.Count<3 then exit;

    S:=Trim(St[0]);
    T:=Trim(ExtUpperCase(St[1]));
    I:=Pos('$',S);
    While I>0 do begin St2.Add(Trim(Copy(S,1,I-1))); S:=Trim(Copy(S,I+1,MaxInt)); I:=Pos('$',S); end;
    St2.Add(S);
    For I:=0 to St2.Count-1 do begin
      S:=Trim(ExtUpperCase(St2[I]));
      If (T='CDROM') and ((S='ASK') or (Copy(S,1,7)='NUMBER:') or (Copy(S,1,6)='LABEL:') or (Copy(S,1,5)='FILE:') or (Copy(S,1,7)='FOLDER:')) then continue;
      St2[I]:=MakeAbsPath(St2[I],PrgSetup.BaseDir);
    end;
    S:=St2[0];

    {general: RealFolder;Type;Letter;IO;Label;FreeSpace}
    If St.Count=3 then St.Add('false');
    If St.Count=4 then St.Add('');
    If St.Count=5 then St.Add('');


    If T='DRIVE' then begin
      {RealFolder;DRIVE;Letter;False;;FreeSpace}
      MarkDriveUsed(St[2]);
      U:=UnmapDrive(ShortName(S),ptMount);
      if BuildForArchivePackage then U:=MakeRelPath(U,PrgDataDir);
      result:='mount '+St[2]+' "'+U+'"';
      If (St.Count>=6) and (St[5]<>'') then result:=result+' -freesize '+St[5];
    end;

    If T='FLOPPY' then begin
      {RealFolder;FLOPPY;Letter;False;;}
      MarkDriveUsed(St[2]);
      U:=UnmapDrive(ShortName(S),ptMount);
      if BuildForArchivePackage then U:=MakeRelPath(U,PrgDataDir);
      result:='mount '+St[2]+' "'+U+'" -t floppy';
    end;

    If T='CDROM' then begin
      {RealFolder;CDROM;Letter;IO;Label; (ASK /  NUMBER:x /  LABEL:x / FILE:x / FOLDER:x)}
      if not SpecialCDDriveMounting(S,St[2],ProfileName,SelectCD,SpecialMountedCDDrives) then begin OK:=False; exit; end;
      MarkDriveUsed(St[2]);
      U:=UnmapDrive(ShortName(S),ptMount);
      if BuildForArchivePackage then U:=MakeRelPath(U,PrgDataDir);
      result:='mount '+St[2]+' "'+U+'" -t cdrom';
      If Trim(UpperCase(St[3]))='TRUE' then result:=result+' -IOCTL';
      If Trim(UpperCase(St[3]))='NOIOCTL' then result:=result+' -NOIOCTL';
      If Trim(UpperCase(St[3]))='DX' then result:=result+' -IOCTL_DX';
      If Trim(UpperCase(St[3]))='DIO' then result:=result+' -IOCTL_DIO';
      If Trim(UpperCase(St[3]))='MCI' then result:=result+' -IOCTL_MCI';
      If St[4]<>'' then result:=result+' -label '+St[4];
    end;

    If T='FLOPPYIMAGE' then begin
      {ImageFile;FLOPPYIMAGE;Letter;;;}
      If (Trim(St[2])='0') or (Trim(St[2])='1') then U:='none' else U:='fat';
      MarkDriveUsed(St[2]);
      If AllSameDir(St2) then begin
        result:=SpecialMultiImgMount(St[2],St2,FreeDriveLetters,'-t floppy -fs '+U);
      end else begin
        S:='"'+ShortName(St2[0])+'"'; For I:=1 to St2.Count-1 do S:=S+' "'+ShortName(St2[I])+'"';
        result:='imgmount '+St[2]+' '+S+' -t floppy -fs '+U;
      end;
    end;

    If T='CDROMIMAGE' then begin
      {ImageFile;CDROMIMAGE;Letter;;;}
      MarkDriveUsed(St[2]);
      If AllSameDir(St2) then begin
        If DOSBoxVersion>0.73 then begin
          result:=SpecialMultiImgMount(St[2],St2,FreeDriveLetters,'-t cdrom');
        end else begin
          result:=SpecialMultiImgMount(St[2],St2,FreeDriveLetters,'-t iso -fs iso');
        end;
      end else begin
        S:='"'+ShortName(St2[0])+'"'; For I:=1 to St2.Count-1 do S:=S+' "'+ShortName(St2[I])+'"';
        If DOSBoxVersion>0.73 then begin
          result:='imgmount '+St[2]+' '+S+' -t cdrom';
        end else begin
          result:='imgmount '+St[2]+' '+S+' -t iso -fs iso';
        end;
      end;
    end;

    If T='IMAGE' then begin
      {ImageFile;IMAGE;LetterOR23;;;geometry}
      If St.Count>=6 then begin
        If (Trim(St[2])='2') or (Trim(St[2])='3') then U:='none' else U:='fat';
        MarkDriveUsed(St[2]);
        result:='imgmount '+St[2]+' "'+ShortName(S)+'" -t hdd -fs '+U+' -size '+St[5];
      end;
    end;

    If T='PHYSFS' then begin
      {RealFolder$ZipFile;PHYSFS;Letter;False;;FreeSpace}
      If St2.Count=2 then begin
        MarkDriveUsed(St[2]);
        CreateDir(MakeAbsPath(St2[0],PrgSetup.BaseDir));
        U:=UnmapDrive(ShortName(St2[0]),ptMount);
        V:=UnmapDrive(ShortName(St2[1]),ptMount);
        if BuildForArchivePackage then U:=MakeRelPath(U,PrgDataDir);
        if BuildForArchivePackage then V:=MakeRelPath(V,PrgDataDir);
        result:='mount '+St[2]+' "'+U+':'+V+':/"';
        If (St.Count>=6) and (St[5]<>'') then result:=result+' -freesize '+St[5];
      end;
    end;

    If T='ZIP' then begin
      {RealFolder$ZipFile;ZIP;Letter;False;;FreeSpace;DeleteMode(no;files;folder)}
      If St2.Count=2 then begin
        MarkDriveUsed(St[2]);
        U:=UnmapDrive(ShortName(St2[0]),ptMount);
        if BuildForArchivePackage then U:=MakeRelPath(U,PrgDataDir);
        result:='mount '+St[2]+' "'+U+'"';
        If (St.Count>=6) and (St[5]<>'') then result:=result+' -freesize '+St[5];
      end;
    end;

  finally
    St.Free;
    St2.Free;
  end;
end;

Procedure TempMountFreeDOSDir(const Game : TGame; FreeDriveLetters : String; var UseDir, Mount, UnMount : String);
Var FreeDOSPath : String;
    I : Integer;
    St : TStringList;
    S : String;
    TempDrive : Char;
begin
  UseDir:=''; Mount:=''; UnMount:='';

  FreeDOSPath:=IncludeTrailingPathDelimiter(MakeAbsPath(PrgSetup.PathToFREEDOS,PrgSetup.BaseDir));
  If not DirectoryExists(FreeDOSPath) then exit;

  UseDir:='';
  For I:=0 to Game.NrOfMounts-1 do begin
    St:=ValueToList(Game.Mount[I]);
    try
      S:=IncludeTrailingPathDelimiter(MakeAbsPath(IncludeTrailingPathDelimiter(St[0]),PrgSetup.BaseDir));
      If ExtUpperCase(Copy(FreeDOSPath,1,length(S)))=ExtUpperCase(S) then begin
        UseDir:=St[2]+':\'+Copy(FreeDOSPath,length(S)+1,MaxInt);
        break;
      end;
    finally
      St.Free;
    end;
  end;
  If UseDir='' then begin
    TempDrive:='Y';
    For I:=length(FreeDriveLetters) downto 1 do If FreeDriveLetters[I]<>'-' then begin TempDrive:=FreeDriveLetters[I]; break; end;
    {There must be free drive letters, because there are only 10 mounts}

    Mount:='mount '+TempDrive+': "'+UnmapDrive(ShortName(FreeDOSPath),ptMount)+'"';
    UseDir:=''+TempDrive+':\';
    Unmount:='mount -u '+TempDrive;
  end;
end;

Function MakePathShort(const S : String) : String;
Var Temp : String;
begin
  SetLength(Temp,MAX_PATH+10);
  If GetShortPathName(PChar(S),PChar(Temp),MAX_PATH)<>0 then begin
    SetLength(Temp,StrLen(PChar(Temp))); result:=Trim(ExtUpperCase(Temp));
  end else begin
    result:=S;
  end;
end;

Procedure BuildLocalRunCommands(const St : TStringList; const ProgramFile, ProgramParameters : String; const UseLoadFix : Boolean; const LoadFixMemory : Integer; const Use4DOS, UseDOS32A : Boolean; const Game : TGame; const FreeDriveLetters : String; const WarnIfNotReachable : Boolean);
Var T : String;
begin
  T:=MakePathShort(Trim(ExtractFilePath(ProgramFile)));

  If (length(T)>=2) and (T[2]=':') then begin
    St.Add(Copy(T,1,2));
    St.Add('cd\');
    T:=Trim(Copy(T,3,MaxInt));
  end;

  If T<>'' then begin
    If T[1]<>'\' then T:='\'+T;
    if T[length(T)]='\' then SetLength(T,length(T)-1);    
    St.Add('cd '+T);
  end;
end;

Function MountQBasic(const Autoexec : TStringList; const Game : TGame; const FreeDriveLetters : String; var QBasicPathAndFile : String) : Boolean;
Var QBFile,S,T,Path,Drive : String;
    I : Integer;
    St : TStringList;
begin
  result:=False;
  QBasicPathAndFile:='QBasic.exe';

  QBFile:=Trim(PrgSetup.QBasic);
  If (QBFile='') or (not FileExists(QBFile)) then exit;

  T:=MakePathShort(Trim(ExtractFilePath(QBFile)));
  Path:=''; Drive:='';
  For I:=0 to Game.NrOfMounts-1 do begin
    St:=ValueToList(Game.Mount[I]);
    try
      If St.Count=3 then St.Add('false');
      If St.Count=4 then St.Add('');
      If St.Count<5 then continue;
      If (Trim(ExtUpperCase(St[1]))<>'DRIVE') and (Trim(ExtUpperCase(St[1]))<>'CDROM') and (Trim(ExtUpperCase(St[1]))<>'FLOPPY') then continue;
      S:=MakePathShort(MakeAbsPath(IncludeTrailingPathDelimiter(St[0]),PrgSetup.BaseDir));

      If Copy(T,1,length(S))=S then begin
        S:=Copy(T,length(S)+1,MaxInt);
        If (Drive='') or (length(S)<length(Path)) then begin Path:=S; Drive:=St[2]+':'; end;
      end;
    finally
      St.Free;
    end;
  end;
  If Drive='' then begin
    For I:=length(FreeDriveLetters) downto 1 do If FreeDriveLetters[I]<>'-' then begin
      Autoexec.Add('mount '+FreeDriveLetters[I]+' '+UnmapDrive(ExtractFilePath(T),ptMount));
      QBasicPathAndFile:=FreeDriveLetters[I]+':\'+ExtractFileName(QBFile);
      break;
    end;
  end else begin
    If (Path<>'') and (Path[1]='\') then Path:=Copy(Path,2,MaxInt);
    QBasicPathAndFile:=IncludeTrailingPathDelimiter(Drive+'\'+Path)+ExtractFileName(QBFile);
  end;

  result:=True;
end;

Function MountUserInterpreter(const Autoexec : TStringList; const Game : TGame; const FreeDriveLetters : String; var InterpreterPathAndFile : String; const InterpreterNr : Integer) : Boolean;
Var InterpreterFile,S,T,Path,Drive : String;
    I : Integer;
    St : TStringList;
begin
  result:=False;

  If InterpreterNr>=PrgSetup.DOSBoxBasedUserInterpretersPrograms.Count then exit;

  InterpreterPathAndFile:=ExtractFileName(PrgSetup.DOSBoxBasedUserInterpretersPrograms[InterpreterNr]);

  InterpreterFile:=Trim(MakeAbsPath(PrgSetup.DOSBoxBasedUserInterpretersPrograms[InterpreterNr],PrgSetup.BaseDir));
  If (InterpreterFile='') or (not FileExists(InterpreterFile)) then exit;

  T:=MakePathShort(Trim(ExtractFilePath(InterpreterFile)));
  Path:=''; Drive:='';
  For I:=0 to Game.NrOfMounts-1 do begin
    St:=ValueToList(Game.Mount[I]);
    try
      If St.Count=3 then St.Add('false');
      If St.Count=4 then St.Add('');
      If St.Count<5 then continue;
      If (Trim(ExtUpperCase(St[1]))<>'DRIVE') and (Trim(ExtUpperCase(St[1]))<>'CDROM') and (Trim(ExtUpperCase(St[1]))<>'FLOPPY') then continue;
      S:=MakePathShort(MakeAbsPath(IncludeTrailingPathDelimiter(St[0]),PrgSetup.BaseDir));

      If Copy(T,1,length(S))=S then begin
        S:=Copy(T,length(S)+1,MaxInt);
        If (Drive='') or (length(S)<length(Path)) then begin Path:=S; Drive:=St[2]+':'; end;
      end;
    finally
      St.Free;
    end;
  end;
  If Drive='' then begin
    For I:=length(FreeDriveLetters) downto 1 do If FreeDriveLetters[I]<>'-' then begin
      Autoexec.Add('mount '+FreeDriveLetters[I]+' '+UnmapDrive(ExtractFilePath(T),ptMount));
      InterpreterPathAndFile:=FreeDriveLetters[I]+':\'+ExtractFileName(InterpreterFile);
      break;
    end;
  end else begin
    If (Path<>'') and (Path[1]='\') then Path:=Copy(Path,2,MaxInt);
    InterpreterPathAndFile:=IncludeTrailingPathDelimiter(Drive+'\'+Path)+ExtractFileName(InterpreterFile);
  end;

  result:=True;
end;

Function RunViaUserInterpreter(const ProgramFile : String) : Integer;
Var I,J : Integer;
    Ext : String;
    St : TStringList;
begin
  result:=-1;
  Ext:=Trim(ExtUpperCase(ExtractFileExt(ProgramFile)));
  If (Ext<>'') and (Ext[1]='.') then Ext:=Copy(Ext,2,MaxInt);

  For I:=0 to PrgSetup.DOSBoxBasedUserInterpretersExtensions.Count-1 do begin
    St:=ValueToList(PrgSetup.DOSBoxBasedUserInterpretersExtensions[I]);
    try
      For J:=0 to St.Count-1 do If Trim(ExtUpperCase(St[J]))=Ext then begin result:=I; exit; end;
    finally
      St.Free;
    end;
  end;
end;

Function BuildRunCommands(const St : TStringList; const ProgramFile, ProgramParameters : String; const UseLoadFix : Boolean; const LoadFixMemory : Integer; const Use4DOS, UseDOS32A : Boolean; const Game : TGame; const FreeDriveLetters : String; const WarnIfNotReachable, WarnIfWindowsExe : Boolean) : Boolean;
Var Prefix,S,T,UsePath,Mount,Unmount : String;
    I : Integer;
    St2 : TStringList;
    NoFreeDOS : Boolean;
    Path, Drive, RootPath, RootPathTemp : String;
    B : Boolean;
begin
  result:=True;

  {Find path to FreeDOS and mount it if needed}
  SpeedTestInfo('Find path to FreeDOS and mount it if needed');
  TempMountFreeDOSDir(Game,FreeDriveLetters,UsePath,Mount,Unmount);
  NoFreeDOS:=(UsePath='');
  SpeedTestInfoOnly('FreeDOS path inside DOSBox: '+UsePath+' mount command (only if needed): '+Mount);
  If Use4DOS or UseDOS32A then begin
    If Mount<>'' then St.Add(Mount);
  end;

  S:=Trim(ExtUpperCase(ProgramFile));
  If (Copy(S,1,7)='DOSBOX:') and (length(S)>7) then begin
    {No path to file needed, because file is in image etc. and given path is local to DOSBox directory structure}
    SpeedTestInfo('Build run command for DOSBox local file');
    BuildLocalRunCommands(St,Trim(Copy(Trim(ProgramFile),8,MaxInt)),ProgramParameters,UseLoadFix,LoadFixMemory,Use4DOS,UseDOS32A,Game,FreeDriveLetters,WarnIfNotReachable);
  end else begin
    {Find path to file}
    SpeedTestInfo('Find file to run');
    If (Trim(ProgramFile)<>'') and WarnIfNotReachable then begin
      If not GameExeIsUnderExoDOS(MakeAbsPath(ProgramFile,PrgSetup.BaseDir),PrgSetup.ExoDOSDir) then begin
        If not FileExists(MakeAbsPath(ProgramFile,PrgSetup.BaseDir)) then begin
          Application.Restore;
          MessageDlg(Format(LanguageSetup.MessageCouldNotFindFile,[MakeAbsPath(ProgramFile,PrgSetup.BaseDir)]),mtError,[mbOK],0);
          result:=false;
          exit;
        end;
      end;
    end;

    SpeedTestInfo('Windows file check');
    If IsWindowsExe(MakeAbsPath(ProgramFile,PrgSetup.BaseDir)) and WarnIfNotReachable and WarnIfWindowsExe then begin
      If not Game.IgnoreWindowsFileWarnings then begin
        Application.Restore;
        B:=False;
        ShowWindowsFileWarningDialog(Application.MainForm,MakeAbsPath(ProgramFile,PrgSetup.BaseDir),B);
        If B then begin Game.IgnoreWindowsFileWarnings:=True; Game.StoreAllValues; end;
      end;
    end;

    T:=MakePathShort(Trim(ExtractFilePath(MakeAbsPath(ProgramFile,PrgSetup.BaseDir))));

    SpeedTestInfo('Build directory change commands to select program direcotry');
    If (Trim(ProgramFile)<>'') and (T<>'') then begin
      Path:=''; Drive:=''; RootPath:='';
      For I:=0 to Game.NrOfMounts-1 do begin
        St2:=ValueToList(Game.Mount[I]);
        try
          If St2.Count=3 then St2.Add('false');
          If St2.Count=4 then St2.Add('');
          If St2.Count<5 then continue;
          If (Trim(ExtUpperCase(St2[1]))<>'DRIVE') and (Trim(ExtUpperCase(St2[1]))<>'CDROM') and (Trim(ExtUpperCase(St2[1]))<>'FLOPPY') then continue;
          S:=MakePathShort(MakeAbsPath(IncludeTrailingPathDelimiter(St2[0]),PrgSetup.BaseDir));

          If Copy(T,1,length(S))=S then begin
            RootPathTemp:=LongPath(S);
            S:=Copy(T,length(S)+1,MaxInt);
            If (Drive='') or (length(S)<length(Path)) then begin Path:=S; Drive:=St2[2]+':'; RootPath:=RootPathTemp; end;
          end;
        finally
          St2.Free;
        end;
      end;
      If Drive<>'' then begin
        St.Add(Drive);
        St.Add('cd\');
        S:=Path;
        If S<>'' then begin
          If S[1]<>'\' then S:='\'+S;
          S:=MakeDOSBoxPath(S,RootPath);
          St.Add('cd '+S);
        end;
      end else begin
        St.Add('Rem !!! The program file is not reachable via any mounted drive. !!!');
        St.Add('Rem !!! Trying to interpret the path to the file as a DOSBox relative path. !!!');
        BuildLocalRunCommands(St,Trim(ProgramFile),ProgramParameters,UseLoadFix,LoadFixMemory,Use4DOS,UseDOS32A,Game,FreeDriveLetters,WarnIfNotReachable);
        If WarnIfNotReachable and
           (not GameExeIsUnderExoDOS(MakeAbsPath(ProgramFile,PrgSetup.BaseDir),PrgSetup.ExoDOSDir)) then begin
          Application.Restore;
          MessageDlg(Format(LanguageSetup.MessageNoMountToReachFolder,[ExtractFilePath(MakeAbsPath(ProgramFile,PrgSetup.BaseDir))]),mtError,[mbOK],0);
          result:=False;
        end;
      end;
    end;
  end;

  If UseLoadFix then Prefix:='loadfix -'+IntToStr(LoadFixMemory)+' ' else Prefix:='';

  SpeedTestInfo('Run via user interpreter check');
  I:=RunViaUserInterpreter(ProgramFile);
  If I>=0 then begin
    SpeedTestInfoOnly('  User interpreter '+IntToStr(I)+' (zero based)');
    {Run via user defined interpreter}
    SpeedTestInfo('Try to mount user interpreter directory');
    SpeedTestInfoOnly('Interpreter: '+S);
    if not MountUserInterpreter(St,Game,FreeDriveLetters,S,I) then begin
      If WarnIfNotReachable then begin
        Application.Restore;
        MessageDlg(Format(LanguageSetup.MessageUserInterpreterNeededToExecuteFile,[PrgSetup.DOSBoxBasedUserInterpretersPrograms[I],ExtractFileName(ProgramFile)]),mtError,[mbOK],0);
      end;
    end;
    SpeedTestInfo('Build run command');
    If PrgSetup.DOSBoxBasedUserInterpretersParameters.Count>I then T:=Trim(PrgSetup.DOSBoxBasedUserInterpretersParameters[I]) else T:='';
    If T='' then T:='%s';
    try T:=Format(T,[ExtractFileName(ProgramFile)]); except T:=Format('%s',[ExtractFileName(ProgramFile)]); end;
    T:=S+' '+T;
  end else begin
    If ExtUpperCase(ExtractFileExt(ProgramFile))='.BAS' then begin
      {Run via QBasic}
      SpeedTestInfo('Try to mount QBasic');
      if not MountQBasic(St,Game,FreeDriveLetters,S) then begin
        If WarnIfNotReachable then begin
          Application.Restore;
          MessageDlg(Format(LanguageSetup.MessageQBasicNeededToExecuteFile,[ExtractFileName(ProgramFile)]),mtError,[mbOK],0);
        end;
      end;
      SpeedTestInfo('Build run command');
      T:=Trim(PrgSetup.QBasicParam); If T='' then T:='/run %s';
      try T:=Format(T,[ExtractFileName(ProgramFile)]); except T:=Format('/run %s',[ExtractFileName(ProgramFile)]); end;
      T:=S+' '+T;
    end else begin
      {Just run in DOSBox}
      SpeedTestInfo('Build run command');
      If (not UseLoadFix) and (not Use4DOS) and (not UseDOS32A) and (Trim(ExtUpperCase(ExtractFileExt(ProgramFile)))='.BAT') then Prefix:='call ';

      If (T<>'') and (Trim(ProgramParameters)<>'') then T:=' '+ProgramParameters else T:='';
      If Copy(Trim(ExtUpperCase(ProgramFile)),1,7)='DOSBOX:' then begin
        S:=ExtractFileName(ProgramFile);
      end else begin
        SpeedTestInfo('Make DOSBox short path name');
        S:=MakeDOSBoxPath(ExtractFileName(ProgramFile),ExtractFilePath(ProgramFile));
        If (S<>'') and (S[1]='\') then S:=Copy(S,2,MaxInt);
      end;
      T:=S+T;

      SpeedTestInfo('Optionally add DOS32A or 4DOS commands');

      If UseDOS32A and (not NoFreeDOS) then begin
        St.Add(UsePath+'DOS32A.EXE '+T);
        SpeedTestInfoOnly('Command: '+UsePath+'DOS32A.EXE '+T);
        exit;
      end;

      If Use4DOS and (not NoFreeDOS) then begin
        If T<>'' then T:=' /C '+T;
        St.Add(UsePath+'4DOS.COM'+T);
        SpeedTestInfoOnly('Command: '+UsePath+'4DOS.COM'+T);
        exit;
      end;
    end;
  end;

  If Game.SecureMode then St.Add('Z:\config.com -securemode > nul');

  St.Add(Prefix+T);
end;

{ MultiLineAdd moved to DosBoxHelpers }

Procedure BuildFloppyBoot(const Autoexec : TStringList; Images : String; const FreeDriveLetters : String; const BuildForArchivePackage : Boolean);
Var Imgs : TStringList;
    I : Integer;
    TempDrive : Char;
    Path,S,T : String;
begin
  Imgs:=TStringList.Create;
  try
    I:=Pos('$',Images);
    While I<>0 do begin Imgs.Add(MakeAbsPath(Copy(Images,1,I-1),PrgSetup.BaseDir)); Images:=Copy(Images,I+1,MaxInt); I:=Pos('$',Images); end;
    Imgs.Add(MakeAbsPath(Images,PrgSetup.BaseDir));

    If AllSameDir(Imgs) then begin
      TempDrive:='Y';
      For I:=length(FreeDriveLetters) downto 1 do If FreeDriveLetters[I]<>'-' then begin TempDrive:=FreeDriveLetters[I]; break; end;
      {There must be free drive letters, because there are only 10 mounts}

      Path:=IncludeTrailingPathDelimiter(ExtractFilePath(ShortName(Imgs[0])));

      S:='"'+TempDrive+':\'+ExtractFileName(ShortName(Imgs[0]))+'"';
      For I:=1 to Imgs.Count-1 do S:=S+' "'+TempDrive+':\'+ExtractFileName(ShortName(Imgs[I]))+'"';

      T:=UnmapDrive(Path,ptMount);
      if BuildForArchivePackage then T:=MakeRelPath(T,PrgDataDir);
      Autoexec.Add('mount '+TempDrive+' "'+T+'"');
      Autoexec.Add('boot '+S);
    end else begin

      S:='"'+IncludeTrailingPathDelimiter(ExtractFilePath(ShortName(Imgs[0])))+ExtractFileName(ShortName(Imgs[0]))+'"';
      For I:=1 to Imgs.Count-1 do S:=S+' "'+IncludeTrailingPathDelimiter(ExtractFilePath(ShortName(Imgs[I])))+ExtractFileName(ShortName(Imgs[I]))+'"';
      Autoexec.Add('boot '+S);
    end;
  finally
    Imgs.Free;
  end;
end;

Procedure AutoMountCDs(const St : TStringList; const Game : TGame; const DOSBoxVersion : Double; var FreeDriveLetters, SpecialMountedCDDrives : String; const BuildForArchivePackage : Boolean);
Var AlreadyMounted,S,T : String;
    I : Integer;
    C,D : Char;
    St2 : TStringList;
    lpSectorsPerCluster,lpBytesPerSector,lpNumberOfFreeClusters,lpTotalNumberOfClusters : Cardinal;
    OK : Boolean;
begin
  {SpecialMountedCDDrives <- mounted by ASK, NUMBER, LABEL, FOLDER or FILE (not detectable my scanning the mount list)}
  AlreadyMounted:=SpecialMountedCDDrives;

  {Check which CD drives are mounted regularly}
  For I:=0 to Game.NrOfMounts do begin
    S:=Game.Mount[I];
    St2:=ValueToList(S);
    try
      If St2.Count<2 then continue;
      If Trim(ExtUpperCase(St2[1]))<>'CDROM' then continue;
      S:=Trim(ExtUpperCase(St2[0]));
      If S='' then continue;
      If (S[1]<'A') or (S[1]>'Z') then continue;
      If length(S)>3 then continue;
      If (length(S)>=2) and (S[2]<>':') then continue;
      If (length(S)>=3) and (S[2]<>'\') then continue;
      AlreadyMounted:=AlreadyMounted+S[1];
    finally
      St2.Free;
    end;
  end;

  {Find CDs and autmount them}
  For C:='C' to 'Z' do begin
    If GetDriveType(PChar(C+':\'))<>DRIVE_CDROM then continue;
    If Pos(C,AlreadyMounted)<>0 then continue;
    if not GetDiskFreeSpace(PChar(C+':\'),lpSectorsPerCluster,lpBytesPerSector,lpNumberOfFreeClusters,lpTotalNumberOfClusters) then continue;
    If lpTotalNumberOfClusters=0 then continue;
    If Pos(C,FreeDriveLetters)>0 then S:=C else begin
      S:='';
      For D:=Chr(ord(C)+1) to 'Y' do If Pos(D,FreeDriveLetters)>0 then begin S:=D; break; end;
      If S='' then For D:='A' to Chr(ord(C)-1) do If Pos(D,FreeDriveLetters)>0 then begin S:=D; break; end;
    end;
    S:=C+':\;CDROM;'+S+';TRUE;;';
    St.Add(BuildMountData(S,DOSBoxVersion,FreeDriveLetters,'',True,OK,T,BuildForArchivePackage)); {"''", "OK" and "T" can be ignored; only for user interactive mounting}
  end;
end;

Function BuildAutoexec(const Game : TGame; const RunSetup : Boolean; const St : TStringList; const WarnIfNotReachable : Boolean; const RunExtraFile : Integer; const WarnIfWindowsExe, SelectCD : Boolean; const BuildForArchivePackage : Boolean) : Boolean;
  Procedure SetVolume(const Channel : String; const Left,Right : Integer);
  begin If (Left<>100) or (Right<>100) then St.Add('mixer '+Channel+' '+IntToStr(Left)+':'+IntToStr(Right)+' /NOSHOW'); end;
Var S,T,U,NumCommands,MouseCommands,UsePath,Mount,UnMount : String;
    I : Integer;
    B : Boolean;
    FreeDriveLetters : String;
    St2 : TStringList;
    DOSBoxNr : Integer;
    OK : Boolean;
    SpecialMountedCDDrives : String;
    DOSBoxVersion : Double;
begin
  result:=True;

  DOSBoxNr:=GetDOSBoxNr(Game);
  If DOSBoxNr<0 then DOSBoxNr:=0; { settings still from primary install when path is bare }
  S:=PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxVersion;
  S:=ShortDOSBoxVersion(S);
  If S=''
    then DOSBoxVersion:=MinSupportedDOSBoxVersion
    else try DOSBoxVersion:=StrToFloatEx(S); except DOSBoxVersion:=MinSupportedDOSBoxVersion; end;

  St.Add('');
  St.Add('[autoexec]');
  St.Add('@echo off');

  { Environment variables }


  SpeedTestInfo('Adding environment variables to [autoexec] section of DOSBox conf file');

  St2:=StringToStringList(Game.Environment);
  try
    For I:=0 to St2.Count-1 do If Trim(St2[I])<>'' then St.Add('SET '+St2[I]);
  finally
    St2.Free;
  end;

  { Keyboard layout }

  SpeedTestInfo('Adding keyboard settings to [autoexec] section of DOSBox conf file');
  GenerateAutoExecKeyboardConf(Game,St,DOSBoxNr);
  SpeedTestInfo('Adding reported DOS version settings to [autoexec] section of DOSBox conf file');
  GenerateAutoExecDOSVerConf(Game,St);

  { Text mode lines }

  SpeedTestInfo('Adding text mode settings to [autoexec] section of DOSBox conf file');

  If PrgSetup.AllowTextModeLineChange then begin
    If Game.TextModeLines=28 then St.Add('Z:\28.COM');
    If Game.TextModeLines=50 then St.Add('Z:\50.COM');
  end;

  { IPX connect }

  SpeedTestInfo('Adding IPX init to [autoexec] section of DOSBox conf file');

  S:=Trim(ExtUpperCase(Game.IPXType));
  If S='CLIENT' then St.Add('IPXNET CONNECT '+Game.IPXAddress+' '+Game.IPXPort);
  If S='SERVER' then St.Add('IPXNET STARTSERVER '+Game.IPXPort);

  { Mounting }

  SpeedTestInfo('Adding mount commands to [autoexec] section of DOSBox conf file');

  { A–C and Z already reserved. Also skip letters commonly pre-mounted by forks
    (e.g. Staging resources/drives/y) so free-letter mounts do not collide. }
  FreeDriveLetters:='---DEFGHIJKLMNOPQRSTUVWX--';
  SpecialMountedCDDrives:=''; {CD drives mounted by ASK, NUMBER, LABEL, FOLDER or FILE -> for AutoMountCDs to avoid double mounting}
  if not Game.AutoexecOverrideMount then begin
    For I:=0 to 9 do begin
      If Game.NrOfMounts>=I+1 then begin
        MultiLineAdd(St,BuildMountData(Game.Mount[I],DOSBoxVersion,FreeDriveLetters,Game.CacheName,SelectCD,OK,SpecialMountedCDDrives,BuildForArchivePackage));
        If not OK then begin result:=False; exit; end;
      end else begin
        break;
      end;
    end;
    If Game.AutoMountCDs then AutoMountCDs(St,Game,DOSBoxVersion,FreeDriveLetters,SpecialMountedCDDrives,BuildForArchivePackage);
  end;
  U:='';
  If GameExeIsUnderExoDOS(MakeAbsPath(Game.GameExe,PrgSetup.BaseDir),PrgSetup.ExoDOSDir) then begin
    S:=IncludeTrailingPathDelimiter(PrgDir)+BinFolder;
    If DirectoryExists(S) then begin
      For I:=Length(FreeDriveLetters) downto 1 do
        If FreeDriveLetters[I]<>'-' then begin
          U:=FreeDriveLetters[I];
          FreeDriveLetters[I]:='-';
          break;
        end;
      If U<>'' then
        St.Add('mount '+U+' "'+UnmapDrive(ShortName(IncludeTrailingPathDelimiter(S)),ptMount)+'"');
    end;
  end;

  { Mixer }

  SpeedTestInfo('Adding mixer settings to [autoexec] section of DOSBox conf file');

  SetVolume('MASTER',Game.MixerVolumeMasterLeft,Game.MixerVolumeMasterRight);
  if Game.DosBoxKind<>dbkPure then begin
    SetVolume('DISNEY',Game.MixerVolumeDisneyLeft,Game.MixerVolumeDisneyRight);
    If Game.IsNewStaging then begin
      SetVolume('PCSPEAKER',Game.MixerVolumeSpeakerLeft,Game.MixerVolumeSpeakerRight);
      SetVolume('OPL',Game.MixerVolumeFMLeft,Game.MixerVolumeFMRight);
    end else begin
      SetVolume('SPKR',Game.MixerVolumeSpeakerLeft,Game.MixerVolumeSpeakerRight);
      SetVolume('FM',Game.MixerVolumeFMLeft,Game.MixerVolumeFMRight);
    end;
    SetVolume('GUS',Game.MixerVolumeGUSLeft,Game.MixerVolumeGUSRight);
    SetVolume('SB',Game.MixerVolumeSBLeft,Game.MixerVolumeSBRight);
    SetVolume('CDAUDIO',Game.MixerVolumeCDLeft,Game.MixerVolumeCDRight);
    { Staging: MT-32 level via mixer channel (no [mt32] gain key). }
    If Game.IsStaging and Game.MIDIDeviceIs('mt32') then begin
      If Game.GetValidMidiGain(I) then
        St.Add('mixer MT32 '+IntToStr(I)+' /NOSHOW');
    end;
  end;

  { Setting num, caps and scroll lock and CuteMouse }

  SpeedTestInfo('Adding num, caps, scroll and mouse settings to [autoexec] section of DOSBox conf file');

  NumCommands:='';
  S:=Trim(ExtUpperCase(Game.NumLockStatus));
  If (S='ON') or (S='1') or (S='TRUE') then NumCommands:='/N1';
  If (S='OFF') or (S='0') or (S='FALSE') then NumCommands:='/N0';
  S:=Trim(ExtUpperCase(Game.CapsLockStatus));
  If (S='ON') or (S='1') or (S='TRUE') then begin If NumCommands<>'' then NumCommands:=NumCommands+' '; NumCommands:=NumCommands+'/C1'; end;
  If (S='OFF') or (S='0') or (S='FALSE') then begin If NumCommands<>'' then NumCommands:=NumCommands+' '; NumCommands:=NumCommands+'/C0'; end;
  S:=Trim(ExtUpperCase(Game.ScrollLockStatus));
  If (S='ON') or (S='1') or (S='TRUE') then begin If NumCommands<>'' then NumCommands:=NumCommands+' '; NumCommands:=NumCommands+'/S1'; end;
  If (S='OFF') or (S='0') or (S='FALSE') then begin If NumCommands<>'' then NumCommands:=NumCommands+' '; NumCommands:=NumCommands+'/S0'; end;

  MouseCommands:='';
  If Game.Force2ButtonMouseMode then MouseCommands:='/Y';
  If Game.SwapMouseButtons then begin If MouseCommands<>'' then MouseCommands:=MouseCommands+' '; MouseCommands:=MouseCommands+'/L'; end;

  SpeedTestInfo('Determining how to temporary mount the FreeDOS directory');

  TempMountFreeDOSDir(Game,FreeDriveLetters,UsePath,Mount,UnMount);
  SpeedTestInfoOnly('FreeDOS directory inside DOSBox: '+UsePath+' mount command (only if needed): '+Mount);

  If ((NumCommands<>'') or (MouseCommands<>'')) and (UsePath<>'') then begin
    If Mount<>'' then St.Add(Mount);
    If NumCommands<>'' then St.Add(UsePath+'4dos.com /C Keybd '+NumCommands);
    If MouseCommands<>'' then St.Add(UsePath+'ctmouse '+MouseCommands);
    If UnMount<>'' then St.Add(UnMount);
  end;
  If U<>'' then
    St.Add('SET PATH='+U+':\;Z:\');

  { User defined Autoexec }

  SpeedTestInfo('Adding user defined autoexec lines to [autoexec] section of DOSBox conf file');

  St2:=StringToStringList(Game.Autoexec);
  try
    B:=False;
    If (St2.Count>0) then for I:=0 to Min(St2.Count-1,2) do If ExtUpperCase(St2[I])='ECHO.' then begin B:=True; break; end;
    If not B then St.Add('echo.');
    St.AddStrings(St2);
  finally
    St2.Free;
  end;

  { Run command }

  S:=Trim(Game.AutoexecBootImage);
  If S<>'' then begin
    SpeedTestInfo('Building image boot command');
    If (S='2') or (S='3') then begin
      If S='2' then St.Add('boot -l C') else St.Add('boot -l D');
    end else begin
      BuildFloppyBoot(St,S,FreeDriveLetters,BuildForArchivePackage);
    end;
    SpeedTestInfoOnly('Command: '+St[St.Count-1]);
  end else begin
    If Game.AutoexecOverrideGamestart then begin
      If Game.SecureMode then St.Add('Z:\config.com -securemode > nul');
    end else begin
      SpeedTestInfo('Selecting file to run');
      If RunExtraFile>=0 then begin
        T:=Trim(Game.ExtraPrgFile[RunExtraFile]);
        I:=Pos(';',T); {ExtraPrgFile=Description;PathAndFile}
        If (T='') or (I=0) then begin
          result:=BuildRunCommands(St,Game.GameExe,Game.GameParameters,Game.LoadFix,Game.LoadFixMemory,Game.Use4DOS,Game.UseDOS32A,Game,FreeDriveLetters,WarnIfNotReachable,WarnIfWindowsExe);
        end else begin
          T:=Copy(T,I+1,MaxInt);
          result:=BuildRunCommands(St,T,Game.ExtraPrgFileParameter[RunExtraFile],Game.LoadFix,Game.LoadFixMemory,Game.Use4DOS,False,Game,FreeDriveLetters,WarnIfNotReachable,WarnIfWindowsExe);
        end;
      end else begin
        If RunSetup then begin
          result:=BuildRunCommands(St,Game.SetupExe,Game.SetupParameters,Game.LoadFix,Game.LoadFixMemory,Game.Use4DOS,False,Game,FreeDriveLetters,WarnIfNotReachable,WarnIfWindowsExe);
        end else begin
          result:=BuildRunCommands(St,Game.GameExe,Game.GameParameters,Game.LoadFix,Game.LoadFixMemory,Game.Use4DOS,Game.UseDOS32A,Game,FreeDriveLetters,WarnIfNotReachable,WarnIfWindowsExe);
        end;
      end;
    end;
  end;

  { User defined Finalization }

  St2:=StringToStringList(Game.AutoexecFinalization);
  try St.AddStrings(St2); finally St2.Free; end;

  { Conditionally close DOSBox }

  If (S='') and (not Game.AutoexecOverridegamestart) and Game.CloseDosBoxAfterGameExit then begin
    If RunExtraFile>=0 then begin
      St.Add('exit');
    end else begin
      If RunSetup then begin
        If Trim(Game.SetupExe)<>'' then St.Add('exit');
      end else begin
        If Trim(Game.GameExe)<>'' then St.Add('exit');
      end;
    end;
  end;
end;

Function BuildConfFile(const Game : TGame; const RunSetup : Boolean; const WarnIfNotReachable : Boolean; const RunExtraFile : Integer; const DeleteOnExit : TStringList; const BuildForArchivePackage : Boolean) : TStringList;
Var St : TStringList;
    S,T,DOSBoxVersionStr,CapturePath,MidiDev : String;
    DOSBoxNr : Integer;
    DOSBoxVersion : Double;
    I : Integer;
    IsStaging, IsOldStaging, IsNewStaging, IsPure : Boolean;
begin
  SpeedTestInfo('Check DOSBox version');
  DOSBoxNr:=GetDOSBoxNr(Game);
  If DOSBoxNr<0 then DOSBoxNr:=0; { settings still from primary install when path is bare }
  S:=PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxVersion;
  DOSBoxVersionStr:=S;
  S:=ShortDOSBoxVersion(S);
  If S=''
    then DOSBoxVersion:=MinSupportedDOSBoxVersion
    else try DOSBoxVersion:=StrToFloatEx(S); except DOSBoxVersion:=MinSupportedDOSBoxVersion; end;
  SpeedTestInfoOnly('DOSBox version: '+FloatToStr(DOSBoxVersion));

  SpeedTestInfo('Build [sdl] section of DOSBox conf file');
  result:=TStringList.Create;

  IsStaging:=Game.IsStaging;
  IsPure:=Game.IsPure;
  IsOldStaging:=Game.IsOldStaging;
  IsNewStaging:=Game.IsNewStaging;

  GenerateSDLConf(Game,result,DOSBoxNr,BuildForArchivePackage);

  If IsStaging then begin
    result.Add('');
    result.Add('[mouse]');
    result.Add('mouse_sensitivity='+IntToStr(Game.MouseSensitivity));
    { Same Auto lock checkbox: on → onclick, off → seamless. }
    If Game.AutoLockMouse
      then result.Add('mouse_capture=onclick')
      else result.Add('mouse_capture=seamless');
  end;

  SpeedTestInfo('Build [dosbox] section of DOSBox conf file');
  GenerateCoreDOSBoxConf(Game,result,DOSBoxNr,DOSBoxVersion,BuildForArchivePackage,DeleteOnExit);

  If IsStaging then begin
    CapturePath:=UnmapDrive(MakeAbsPath(Game.CaptureFolder,PrgSetup.BaseDir),ptScreenshot);
    if BuildForArchivePackage then CapturePath:=MakeRelPath(CapturePath,PrgDataDir);
    result.Add('');
    result.Add('[capture]');
    result.Add('capture_dir='+CapturePath);
  end;

  GenerateGraphicsConf(Game,result);
  GenerateSpecialMachineConf(Game,result);

  SpeedTestInfo('Build [vga, glide, cpi, midi, sblaster, gus and speaker] sections of DOSBox conf file');

  { Classic Daum-style [vga] only for standard DOSBox (not Staging/X). }
  If PrgSetup.AllowVGAChipsetSettings and not (Game.DosBoxKind in [dbkX,dbkStaging]) then begin
    result.Add('');
    result.Add('[vga]');
    result.Add('svgachipset='+Game.VGAChipset);
    result.Add('videoram='+IntToStr(Game.VideoRam));
  end;

  If PrgSetup.AllowGlideSettings then
    GenerateGlideConf(Game,result);

  GenerateCPUConf(Game,result,DOSBoxVersion);

  result.Add('');
  result.Add('[mixer]');
  result.Add('nosound='+BoolToStr(Game.MixerNosound));
  result.Add('rate='+IntToStr(Game.MixerRate));
  result.Add('blocksize='+IntToStr(Game.MixerBlocksize));
  result.Add('prebuffer='+IntToStr(Game.MixerPrebuffer));

  GenerateMidiConf(Game,result,DOSBoxVersion,Game.IsStaging,Game.IsOldStaging);
  GenerateSoundDeviceConf(Game,result,DOSBoxVersion);
  GenerateInnovaConf(Game,result,Game.IsStaging,Game.IsOldStaging);

  SpeedTestInfo('Build [dos] section of DOSBox conf file');
  GenerateMSDOSConf(Game,result,DOSBoxNr);
  SpeedTestInfo('Build [joystick, serial, ipx, printer] section of DOSBox conf file');

  result.Add('');
  result.Add('[joystick]');
  result.Add('joysticktype='+Game.JoystickType);
  result.Add('timed='+BoolToStr(Game.JoystickTimed));
  result.Add('autofire='+BoolToStr(Game.JoystickAutoFire));
  result.Add('swap34='+BoolToStr(Game.JoystickSwap34));
  result.Add('buttonwrap='+BoolToStr(Game.JoystickButtonwrap));

  If PrgSetup.AllowNe2000 then
    GenerateNetworkConf(Game,result);

  result.Add('');
  result.Add('[serial]');
  S:=ExtLowerCase(Game.Serial1);
  result.Add('serial1='+S);
  S:=ExtLowerCase(Game.Serial2);
  result.Add('serial2='+S);
  S:=ExtLowerCase(Game.Serial3);
  result.Add('serial3='+S);
  S:=ExtLowerCase(Game.Serial4);
  result.Add('serial4='+S);

  If Game.IPX then begin
    result.Add('');
    result.Add('[ipx]');
    result.Add('ipx=true');
  end;

  If PrgSetup.AllowPrinterSettings then begin
    result.Add('');
    result.Add('[printer]');
    result.Add('printer='+BoolToStr(Game.EnablePrinterEmulation));
    T:=UnmapDrive(MakeAbsPath(Game.CaptureFolder,PrgSetup.BaseDir),ptScreenshot);
    if BuildForArchivePackage then T:=MakeRelPath(T,PrgDataDir);
    result.Add('docpath='+T);
    result.Add('dpi='+IntToStr(Game.PrinterResolution));
    result.Add('width='+IntToStr(Game.PaperWidth));
    result.Add('height='+IntToStr(Game.PaperHeight));
    result.Add('printoutput='+Game.PrinterOutputFormat);
    result.Add('multipage='+BoolToStr(Game.PrinterMultiPage));
  end;

  if not BuildAutoexec(Game,RunSetup,result,WarnIfNotReachable,RunExtraFile,True,True,BuildForArchivePackage) then begin result.Free; result:=nil; exit; end;

  SpeedTestInfo('Add custom settings to DOSBox conf file');

  AppendCustomSettingsToConf(result,PrgSetup.DOSBoxSettings[DOSBoxNr].CustomSettings);
  AppendCustomSettingsToConf(result,Game.CustomSettings);
end;

Procedure FindAlternativeDOSBoxFile(var PrgFile : String);
Var Rec : TSearchRec;
    I : Integer;
    Dir : String;
begin
  Dir:=IncludeTrailingPathDelimiter(ExtractFilePath(PrgFile));
  I:=FindFirst(Dir+'dosbox*.exe',faAnyFile,Rec);
  try
    While I=0 do begin
      If ((Rec.Attr and faDirectory)=0) and (Pos('DEBUG',ExtUpperCase(Rec.Name))=0) then begin
        PrgFile:=Dir+Rec.Name;
        exit;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

Function GetDOSBoxCommandLine(const DOSBoxNr : Integer; const ConfFile : String; const ShowConsole : Integer; const DosBoxCommandLine : String ='') : String;
Var Add : String;
    SettingsNr : Integer;
    WantConsole : Boolean;
    Kind : TDOSBoxKind;
begin
  SettingsNr:=DOSBoxNr;
  If SettingsNr<0 then SettingsNr:=0; { bare path: borrow primary install settings }
  Add:='';
  WantConsole:=False;
  Case ShowConsole of
    0 : begin
          Add:=' -NOCONSOLE';
          WantConsole:=False;
        end;
    2 : WantConsole:=True; {always show console}
    else {1 :} begin
      WantConsole:=not PrgSetup.DOSBoxSettings[SettingsNr].HideDosBoxConsole;
      if not WantConsole then Add:=' -NOCONSOLE';
    end;
  End;
  { DOSBox-X is a Win32 GUI app: it does not open a log console unless -console
    is passed (sdlmain.cpp). Staging uses the opposite model (-NOCONSOLE to hide). }
  if WantConsole and (SettingsNr<PrgSetup.DOSBoxSettingsCount) then begin
    Kind:=PrgSetup.DOSBoxSettings[SettingsNr].DosBoxKind;
    if Kind=dbkX then Add:=Add+' -console';
  end;
  If Trim(PrgSetup.DOSBoxSettings[SettingsNr].CommandLineParameters)<>'' then
    Add:=Add+' '+Trim(PrgSetup.DOSBoxSettings[SettingsNr].CommandLineParameters);
  If DosBoxCommandLine<>'' then Add:=Add+' '+DosBoxCommandLine;
  result:='-CONF "'+ConfFile+'"'+Add;
end;

Function CreateDOSBoxProcess(const PrgFile, Params, Cwd : String; EnvBlock : Pointer; CreationFlags : DWORD; out ProcessId : DWORD) : THandle;
Var StartupInfo : TStartupInfo;
    ProcessInformation : TProcessInformation;
    WorkDir : String;
begin
  result:=INVALID_HANDLE_VALUE;
  ProcessId:=0;
  WorkDir:=Cwd;
  if WorkDir='' then
    WorkDir:=ExtractFilePath(PrgFile);

  SpeedTestInfo('Starting DOSBox');
  SpeedTestInfoOnly('Command: "'+PrgFile+'" '+Params);
  LogInfo('DOSBox CreateProcess: "'+PrgFile+'" '+Params);
  LogInfo('DOSBox cwd: '+WorkDir);

  FillChar(StartupInfo,SizeOf(StartupInfo),0);
  StartupInfo.cb:=SizeOf(TStartupInfo);

  if not CreateProcess(
    PChar(PrgFile),
    PChar('"'+PrgFile+'" '+Params),
    nil,
    nil,
    False,
    CreationFlags,
    EnvBlock,
    PChar(WorkDir),
    StartupInfo,
    ProcessInformation
  ) then begin
    LogInfo('DOSBox CreateProcess FAILED: "'+PrgFile+'" '+Params);
    Application.Restore;
    If Assigned(Application.MainForm) then begin
      Application.MainForm.Visible:=True;
      Application.MainForm.Enabled:=True;
    end;
    MessageDlg(Format(LanguageSetup.MessageCouldNotStartProgram,[PrgFile]),mtError,[mbOK],0);
    exit;
  end;

  SpeedTestInfo('DOSBox started');
  If ProcessInformation.hProcess<>INVALID_HANDLE_VALUE then begin
    SpeedTestInfoOnly('DOSBox successfully started');
    LogInfo('DOSBox CreateProcess OK handle='+IntToStr(ProcessInformation.hProcess));
  end;

  result:=ProcessInformation.hProcess;
  ProcessId:=ProcessInformation.dwProcessId;
  CloseHandle(ProcessInformation.hThread);
  DOSBoxCounter.Add(result);
end;

Function RunDosBox(const DOSBoxPath : String; const DOSBoxNr : Integer; const ConfFile : String; const FullScreen : Boolean; const ShowConsole : Integer; const asAdmin : Boolean; const DosBoxCommandLine : String ='') : THandle;
Var PrgFile, Params, Env, S : String;
    Size : Integer;
    EnvSrc : PChar;
    EnvBlock : Pointer;
    Q : Array of Char;
    Waited : Boolean;
    CreationFlags : DWORD;
    ProcessId : DWORD;
begin
  SpeedTestInfo('Building DOSBox command line');
  Params:=GetDOSBoxCommandLine(DOSBoxNr,ConfFile,ShowConsole,DosBoxCommandLine);
  LogInfo('DOSBox conf arg: '+ConfFile);
  LogInfo('DOSBox cmdline params: '+Params);

  SpeedTestInfo('Searching DOSBox program file');
  { Callers should pass ResolveDOSBoxDir (abs dir). Empty/DEFAULT: last-resort settings dir. }
  PrgFile:=Trim(DOSBoxPath);
  If (PrgFile='') or (ExtUpperCase(PrgFile)='DEFAULT') then begin
    If (DOSBoxNr>=0) and (DOSBoxNr<PrgSetup.DOSBoxSettingsCount) and
       (Trim(PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxDir)<>'') then
      PrgFile:=IncludeTrailingPathDelimiter(MakeAbsPath(PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxDir,PrgSetup.BaseDir))+DosBoxFileName
    else
      PrgFile:='';
  end else If ExtUpperCase(ExtractFileExt(PrgFile))<>'.EXE' then
    PrgFile:=IncludeTrailingPathDelimiter(MakeAbsPath(PrgFile,PrgSetup.BaseDir))+DosBoxFileName;
  If not FileExists(PrgFile) then FindAlternativeDOSBoxFile(PrgFile);
  if not FileExists(PrgFile) then begin
    LogInfo('DOSBox exe not found: '+PrgFile);
    Application.Restore;
    If Assigned(Application.MainForm) then begin
      Application.MainForm.Visible:=True;
      Application.MainForm.Enabled:=True;
    end;
    MessageDlg(Format(LanguageSetup.MessageCouldNotFindDosBox,[PrgFile]),mtError,[mbOK],0);
    result:=INVALID_HANDLE_VALUE;
    exit;
  end;
  PrgFile:=UnmapDrive(PrgFile,ptDOSBox);

  SpeedTestInfoOnly('DOSBox program file: '+PrgFile);
  LogInfo('DOSBox exe: '+PrgFile);
  LogInfo('DOSBox full command: "'+PrgFile+'" '+Params);

  If FullScreen then ShowFullscreenInfoDialog(Application.MainForm);

  if asAdmin then begin
    S:=Trim(ExtUpperCase(PrgSetup.DOSBoxSettings[DOSBoxNr].SDLVideodriver));
    Env:='';
    If S='WINDIB' then Env:='windib';
    { DirectX env only for standard DOSBox on XP or earlier (Win32 major < 6). }
    If (S='DIRECTX') and (Win32MajorVersion<6) and
       not (PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxKind in [dbkX,dbkStaging]) then
      Env:='directx';
    result:=INVALID_HANDLE_VALUE;
    S:=IncludeTrailingPathDelimiter((ExtractFilePath(PrgFile)));
    LogInfo('DOSBox launch via AdminLauncher: /driver='+Env+' /dir='+S+
      ' /run="'+PrgFile+'" '+Params);
    ShellExecute(
      Application.MainForm.Handle,
      'open',
      PChar(PrgDir+BinFolder+'\AdminLauncher.exe'),
      PChar('/driver='+Env+' /dir='+S+' /run="'+PrgFile+'" '+Params),
      PChar(S),
      SW_SHOW
    );
    exit;
  end;

  S:=Trim(ExtUpperCase(PrgSetup.DOSBoxSettings[DOSBoxNr].SDLVideodriver));
  Env:='';
  If S='WINDIB' then Env:='windib';
  { DirectX env only for standard DOSBox on XP or earlier (Win32 major < 6). }
  If (S='DIRECTX') and (Win32MajorVersion<6) and
     not (PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxKind in [dbkX,dbkStaging]) then
    Env:='directx';
  CreationFlags:=0;
  EnvBlock:=nil;
  If Env<>'' then begin
    SpeedTestInfo('Setting up environment variables for DOSBox');
    Env:='SDL_VIDEODRIVER='+Env;
    EnvSrc:=GetEnvironmentStringsW;
    try
      Size:=0;
      While not ((EnvSrc[Size]=#0) and (EnvSrc[Size+1]=#0)) do Inc(Size);
      Inc(Size);
      SetLength(Q,Size+length(Env)+1+1);
      Move(EnvSrc^,Q[0],Size*SizeOf(Char));
      Move(Env[1],Q[Size],length(Env)*SizeOf(Char));
      Q[Size+length(Env)]:=#0;
      Q[Size+length(Env)+1]:=#0;
    finally
      FreeEnvironmentStringsW(EnvSrc);
    end;
    SpeedTestInfoOnly('Added '+Env);
    EnvBlock:=@Q[0];
    CreationFlags:=CREATE_UNICODE_ENVIRONMENT;
  end;

  result:=CreateDOSBoxProcess(PrgFile,Params,ExtractFilePath(PrgFile),EnvBlock,CreationFlags,ProcessId);
  if result=INVALID_HANDLE_VALUE then exit;

  {ShellExecute(Application.MainForm.Handle,'open',PChar(IncludeTrailingPathDelimiter(PrgSetup.DosBoxDir)+DosBoxFileName),PChar('-CONF "'+ConfFile+'"'+Add),PChar(IncludeTrailingPathDelimiter((ExtractFilePath(ConfFile)))),SW_SHOW);}

  { Post-launch Win32 center: standard DOSBox only. Staging/X use conf
    window_position / windowposition instead. }
  If PrgSetup.DOSBoxSettings[DOSBoxNr].CenterDOSBoxWindow and (not FullScreen) and
     not (PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxKind in [dbkX,dbkStaging]) then begin
    SpeedTestInfo('Center DOSBox window');
    Sleep(1000); Waited:=True;
    CenterWindowFromProcessID(ProcessId);
  end else begin
    Waited:=False;
  end;

  If PrgSetup.MinimizeOnDosBoxStart then begin
    If not Waited then Sleep(1000);
    {MinimizedAtDOSBoxStart:=True; -> RunGameInt}
  end;
end;

Procedure ScheduleDeletePureWorkDir(const ProcessHandle : THandle; const Dir : String);
Var h : THandle;
    D : String;
begin
  D:=Dir;
  if (D='') or (ProcessHandle=0) or (ProcessHandle=INVALID_HANDLE_VALUE) then Exit;
  if not DuplicateHandle(GetCurrentProcess,ProcessHandle,GetCurrentProcess,@h,0,False,DUPLICATE_SAME_ACCESS) then
    Exit;
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        WaitForSingleObject(h,INFINITE);
      finally
        CloseHandle(h);
      end;
      try
        if TDirectory.Exists(D) then
          TDirectory.Delete(D,True);
      except
      end;
    end).Start;
end;

Function PureNearestVolumeStep(const Target : String) : String;
const
  Steps: array[0..41] of Double = (
    0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5,
    0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0,
    1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0,
    2.25, 2.5, 2.75, 3.0, 3.25, 3.5, 3.75, 4.0, 4.25, 4.5, 4.75, 5.0);
  StepStr: array[0..41] of String = (
    '0.05','0.1','0.15','0.2','0.25','0.3','0.35','0.4','0.45','0.5',
    '0.55','0.6','0.65','0.7','0.75','0.8','0.85','0.9','0.95','1.0',
    '1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9','2.0',
    '2.25','2.5','2.75','3.0','3.25','3.5','3.75','4.0','4.25','4.5','4.75','5.0');
Var
  V, BestDiff, Diff : Double;
  I, Best : Integer;
begin
  Result:='';
  if not TryStrToFloat(Trim(Target),V) then Exit;
  if (V<0) or (V>5.0) then Exit;
  Best:=0;
  BestDiff:=Abs(Steps[0]-V);
  for I:=1 to High(Steps) do begin
    Diff:=Abs(Steps[I]-V);
    if Diff<BestDiff then begin
      BestDiff:=Diff;
      Best:=I;
    end;
  end;
  Result:=StepStr[Best];
end;

Function PureMidiVolumeOption(const GainPct : Integer) : String;
Var G : Integer;
begin
  G:=GainPct;
  If G<0 then G:=0 else If G>500 then G:=500;
  { UI 0..500 maps to Pure volume 0..5.0 (snapped). }
  Result:=PureNearestVolumeStep(FloatToStr(G/100.0));
end;

Function JsonString(const S : String) : String;
begin
  Result:=StringReplace(S,'\','\\',[rfReplaceAll]);
  Result:=StringReplace(Result,'"','\"',[rfReplaceAll]);
end;

Function ParsePureCustomSettingLine(const Line: String; out Key, Val: String): Boolean;
Var S: String;
    P: Integer;
begin
  Result:=False;
  Key:='';
  Val:='';
  S:=Trim(Line);
  If S='' then exit;
  If (S[1]='#') or (S[1]=';') then exit;
  P:=Pos('=',S);
  If P<=1 then exit;
  Key:=Trim(Copy(S,1,P-1));
  Val:=Trim(Copy(S,P+1,MaxInt));
  Result:=(Length(Key)>=12) and SameText(Copy(Key,1,12),'dosbox_pure_');
end;

Procedure AppendCustomSettingsToConf(const Dest: TStrings; const Custom: String);
Var St: TStringList;
    I: Integer;
    Key, Val: String;
begin
  If (Dest=nil) or (Trim(Custom)='') then exit;
  St:=StringToStringList(Custom);
  try
    for I:=0 to St.Count-1 do
      if not ParsePureCustomSettingLine(St[I],Key,Val) then
        Dest.Add(St[I]);
  finally
    St.Free;
  end;
end;

Procedure AppendPureCustomSettingsToCfg(const Cfg: TStrings; const Custom: String);
Var St: TStringList;
    I, J, Idx: Integer;
    Key, Val, Line, Prefix: String;
begin
  If (Cfg=nil) or (Trim(Custom)='') then exit;
  St:=StringToStringList(Custom);
  try
    for I:=0 to St.Count-1 do
      if ParsePureCustomSettingLine(St[I],Key,Val) then begin
        Line:='"'+JsonString(Key)+'" : "'+JsonString(Val)+'"';
        Prefix:='"'+Key+'"';
        Idx:=-1;
        for J:=0 to Cfg.Count-1 do
          if SameText(Copy(Trim(Cfg[J]),1,Length(Prefix)),Prefix) then begin
            Idx:=J;
            break;
          end;
        if Idx>=0 then
          Cfg[Idx]:=Line
        else
          Cfg.Add(Line);
      end;
  finally
    St.Free;
  end;
end;

Procedure GeneratePureMidiCfg(const Game: TGame; const Cfg: TStrings; const WorkDir: String);
Var S, RomDir, SoundFontSrc, SoundFontName, WorkDirSlash, VolOpt: String;
    GainPct: Integer;
begin
  if Game.MIDIDeviceIs('mt32') then begin
    S:=Trim(Game.MIDIMT32Model);
    RomDir:=Trim(Game.MIDIMT32RomDir);
    if (S<>'') and (RomDir<>'') then begin
      RomDir:=StringReplace(ExcludeTrailingPathDelimiter(MakeAbsPath(RomDir,PrgSetup.BaseDir)),'\','/',[rfReplaceAll]);
      Cfg.Add('"path_system" : "'+JsonString(RomDir)+'"');
      Cfg.Add('"dosbox_pure_midi" : "'+JsonString(S+'_CONTROL.ROM')+'"');
    end;
  end else if Game.MIDIDeviceIs('soundfont') then begin
    SoundFontSrc:=Trim(Game.FluidSoundFont);
    if SoundFontSrc<>'' then begin
      SoundFontSrc:=MakeAbsPath(SoundFontSrc,PrgSetup.BaseDir);
      if FileExists(SoundFontSrc) then begin
        SoundFontName:=ExtractFileName(SoundFontSrc);
        if CopyFile(PChar(SoundFontSrc),PChar(WorkDir+SoundFontName),False) then begin
          WorkDirSlash:=StringReplace(ExcludeTrailingPathDelimiter(WorkDir),'\','/',[rfReplaceAll]);
          Cfg.Add('"path_system" : "'+JsonString(WorkDirSlash)+'"');
          Cfg.Add('"dosbox_pure_midi" : "'+JsonString(SoundFontName)+'"');
        end;
      end;
    end;
  end else if Game.MIDIDeviceIs('port') then
    Cfg.Add('"dosbox_pure_midi" : "system"');
  if (Game.MIDIDeviceIs('mt32') or Game.MIDIDeviceIs('soundfont'))
     and Game.GetValidMidiGain(GainPct) then begin
    VolOpt:=PureMidiVolumeOption(GainPct);
    Cfg.Add('"dosbox_pure_volume_midi" : "'+JsonString(VolOpt)+'"');
  end;
end;

Procedure GeneratePureGraphicsCfg(const Game: TGame; const Cfg: TStrings);
Var S: String;
    ScreenW, ScreenH, I: Integer;
begin
  {
    Pure vsync: "Force 60fps" → true, otherwise false. Pure will pick a default if
    the value is invalid or empty.
  }
  if SameText(Trim(Game.VSync),'Force 60fps') then
    Cfg.Add('"dosbox_pure_force60fps" : "true"');
  if Game.StartFullscreen then
    Cfg.Add('"screen_fullscreen" : "true"');
  if Game.AspectCorrection then
    Cfg.Add('"dosbox_pure_aspect_correction" : "true"')
  else
    Cfg.Add('"dosbox_pure_aspect_correction" : "false"');

  {
    Pure screen resolution: use profile window resolution if valid, otherwise
    let Pure pick a default. Pure will pick a default if the width or height is
    zero or invalid.
  }  
  ScreenW:=0;
  ScreenH:=0;
  S:=Trim(Game.WindowResolution);
  I:=Pos('x',ExtLowerCase(S));
  if I>1 then begin
    TryStrToInt(Copy(S,1,I-1),ScreenW);
    TryStrToInt(Copy(S,I+1,MaxInt),ScreenH);
  end;
  if (ScreenW>0) and (ScreenH>0) then begin
    Cfg.Add('"screen_width" : "'+IntToStr(ScreenW)+'"');
    Cfg.Add('"screen_height" : "'+IntToStr(ScreenH)+'"');
  end;

  {
    Pure Voodoo settings: 8mb (default) or off. Pure will pick a default if the
    value is invalid or empty.
  }
  if Game.isGlideEnabled then begin
    Cfg.Add('"dosbox_pure_voodoo" : "8mb"');
    Cfg.Add('"dosbox_pure_voodoo_perf" : "auto"');
  end else
    Cfg.Add('"dosbox_pure_voodoo" : "off"');
  S:=Trim(Game.Scale);
  
  {
    Pure interface scaling/shader
  }
  if IsValidConfOptValue(Game.GameDB.ConfOpt.ScalePure,S) then
    Cfg.Add('"interface_scaling" : "'+JsonString(S)+'"');
  S:=Trim(Game.PixelShader);
  if IsValidConfOptValue(Game.GameDB.ConfOpt.ShaderPure,S) then
    Cfg.Add('"interface_crtfilter" : "'+JsonString(S)+'"');
end;

Procedure WritePureWorkDirFiles(const Game : TGame; const ConfLines : TStrings; out WorkDir, ConfPath : String);
Var CfgPath, Body, DataDir, PureSavesDir, VolOpt : String;
    Cfg : TStringList;
    I : Integer;
begin
  WorkDir:=IncludeTrailingPathDelimiter(TPath.GetTempPath)+
    'DFendX-Pure-'+IntToStr(GetTickCount64)+PathDelim;
  ConfPath:=WorkDir+DosBoxConfFileName;
  CfgPath:=WorkDir+'DOSBoxPure.cfg';
  ForceDirectories(WorkDir);
  ConfLines.SaveToFile(ConfPath);
  Cfg:=TStringList.Create;
  try
    {
      Pure saves dir: use the profile data dir if it exists, otherwise use the
      Pure work dir. The Pure work dir is deleted after DOSBox exits, so we
      cannot store saves there.
    }
    DataDir:=Game.ResolveDataDir;
    if (DataDir<>'') and DirectoryExists(DataDir) then begin
      PureSavesDir:=IncludeTrailingPathDelimiter(DataDir)+'.pure';
      ForceDirectories(PureSavesDir);
      PureSavesDir:=StringReplace(ExcludeTrailingPathDelimiter(PureSavesDir),'\','/',[rfReplaceAll]);
      Cfg.Add('"path_saves" : "'+JsonString(PureSavesDir)+'"');
    end;
    GeneratePureMidiCfg(Game,Cfg,WorkDir);
    GeneratePureGraphicsCfg(Game,Cfg);
    if Game.GUS then
      Cfg.Add('"dosbox_pure_gus" : "true"')
    else
      Cfg.Add('"dosbox_pure_gus" : "false"');

    {
      Pure volume boost: 0..200 (UI) maps to 0.0..5.0 (Pure) in steps of 0.05.
      UI 100 = Pure 2.5 (default). UI 200 = Pure 5.0 (max). UI 0 = Pure 0.0 (mute).
      Pure volume boost is applied to all channels: SB, AdLib, Speaker, CD-ROM, Other.
    }
    if TryStrToInt(Trim(Game.PureVolumeBoost),I) then begin
      if I<0 then I:=0 else if I>200 then I:=200;
      VolOpt:=PureNearestVolumeStep(FloatToStr(I/40.0));
      if VolOpt<>'' then begin
        Cfg.Add('"dosbox_pure_volume_sb" : "'+JsonString(VolOpt)+'"');
        Cfg.Add('"dosbox_pure_volume_adlib" : "'+JsonString(VolOpt)+'"');
        Cfg.Add('"dosbox_pure_volume_speaker" : "'+JsonString(VolOpt)+'"');
        Cfg.Add('"dosbox_pure_volume_cdrom" : "'+JsonString(VolOpt)+'"');
        Cfg.Add('"dosbox_pure_volume_other" : "'+JsonString(VolOpt)+'"');
      end;
    end;

    {
      Pure custom settings: append to cfg, overriding any existing keys.
      Settings from the DOSBox installation are applied first, then profile settings.
    }
    I:=GetDOSBoxNr(Game);
    if I<0 then I:=0;
    AppendPureCustomSettingsToCfg(Cfg,PrgSetup.DOSBoxSettings[I].CustomSettings);
    AppendPureCustomSettingsToCfg(Cfg,Game.CustomSettings);
    LogInfo('Writing Pure cfg: '+CfgPath);
    Body:='{'+#13#10;
    for I:=0 to Cfg.Count-1 do begin
      LogInfo('  Pure cfg: '+Cfg[I]);
      if I<Cfg.Count-1 then
        Body:=Body+#9+Cfg[I]+','+#13#10
      else
        Body:=Body+#9+Cfg[I]+#13#10;
    end;
    Body:=Body+'}';
    Cfg.Clear;
    Cfg.Text:=Body;
    Cfg.SaveToFile(CfgPath);
  finally
    Cfg.Free;
  end;
end;

Function InvokeDOSBoxPure(const InstallDir, ConfPath, WorkDir : String; const FullScreen : Boolean; const ExtraCmd : String) : THandle;
Var PrgFile, Params : String;
    ProcessId : DWORD;
begin
  result:=INVALID_HANDLE_VALUE;
  PrgFile:=IncludeTrailingPathDelimiter(MakeAbsPath(InstallDir,PrgSetup.BaseDir))+DosBoxFileName;
  if not FileExists(PrgFile) then
    FindAlternativeDOSBoxFile(PrgFile);
  if not FileExists(PrgFile) then begin
    LogInfo('DOSBox Pure exe not found under: '+InstallDir);
    Application.Restore;
    if Assigned(Application.MainForm) then begin
      Application.MainForm.Visible:=True;
      Application.MainForm.Enabled:=True;
    end;
    MessageDlg(Format(LanguageSetup.MessageCouldNotFindDosBox,[PrgFile]),mtError,[mbOK],0);
    Exit;
  end;
  PrgFile:=UnmapDrive(PrgFile,ptDOSBox);

  Params:='"'+ConfPath+'"';
  if Trim(ExtraCmd)<>'' then
    Params:=Params+' '+Trim(ExtraCmd);

  if FullScreen then
    ShowFullscreenInfoDialog(Application.MainForm);

  LogInfo('DOSBox Pure conf (content): '+ConfPath);
  result:=CreateDOSBoxProcess(PrgFile,Params,IncludeTrailingPathDelimiter(WorkDir),nil,0,ProcessId);
  if result<>INVALID_HANDLE_VALUE then
    ScheduleDeletePureWorkDir(result,WorkDir);
end;

Function RunGameInt(const Game : TGame; const RunSetup : Boolean; const DosBoxCommandLine : String; const DeleteOnExit : TStringList; const RunExtraFile : Integer = -1) : THandle;
Var St,St2 : TStringList;
    T, ConfPath, PureWorkDir : String;
    ZipRecNr : Integer;
    Error : Boolean;
    DOSBoxNr : Integer;
    AlreadyMinimized : Boolean;
    RunAsAdmin : Boolean;
    DOSBoxStartedOk : Boolean;
begin
  result:=INVALID_HANDLE_VALUE;
  AlreadyMinimized:=False;
  DOSBoxStartedOk:=False;
  RunAsAdmin:=False;
  PureWorkDir:='';
  ConfPath:='';

  SpeedTestInfo('Starting profile '+Game.SetupFile,True);
  SpeedTestInfo('File checksum test');
  If not RunCheck(Game,RunSetup,RunExtraFile) then exit;

  SpeedTestInfo('DOSBox installation selection');
  DOSBoxNr:=GetDOSBoxNr(Game);
  If DOSBoxNr<0 then DOSBoxNr:=0; { bare path: settings from primary install; path via ResolveDOSBoxDir }
  SpeedTestInfoOnly('Selected DOSBox installation number '+IntToStr(DOSBoxNr));

  try
    SpeedTestInfo('Capture folder check');
    If Trim(Game.CaptureFolder)='' then begin
      Game.CaptureFolder:=MakeRelPath(PrgSetup.CaptureDir,PrgSetup.BaseDir);
      Game.StoreAllValues;
    end;
    T:=MakeAbsPath(Game.CaptureFolder,PrgSetup.BaseDir);
    ForceDirectories(T);
    SpeedTestInfoOnly('Capture folder: '+T);

    St:=BuildConfFile(Game,RunSetup,True,RunExtraFile,DeleteOnExit,false);
    If St=nil then exit;

    try
      try
        SpeedTestInfo('Storing conf file');
        if Game.DosBoxKind=dbkPure then
          WritePureWorkDirFiles(Game,St,PureWorkDir,ConfPath)
        else begin
          ConfPath:=TempDir+DosBoxConfFileName;
          St.SaveToFile(ConfPath);
        end;
        SpeedTestInfoOnly('Conf filename:'+ConfPath);
        LogConfShaderAndPath(St,ConfPath,Game);
        SpeedTestInfoOnly('Logged conf path + shader lines to DFendX-Log.txt');
      except
        Application.Restore;
        MessageDlg(Format(LanguageSetup.MessageCouldNotSaveFile,[ConfPath]),mtError,[mbOK],0);
        exit;
      end;
      If Game.CacheName<>TempDOSBoxName then begin
        SpeedTestInfo('Adding historiy');
        SpeedTestInfoOnly('Game name: '+Game.CacheName);
        History.Add(Game.CacheName);
      end;

      T:=Game.GetDBInstallPath;

      SpeedTestInfo('Process zipped drives');
      ZipRecNr:=ZipManager.AddGame(Game,Error);
      If Error then exit;

      SpeedTestInfo('Process run before main file');
      RunPrgManager.RunBeforeExecutionCommand(Game);

      PauseAmbientSoundtrack;

      If PrgSetup.MinimizeOnDosBoxStart then begin
        SpeedTestInfo('Minimize main window');
        AlreadyMinimized:=(Application.MainForm.WindowState=wsMinimized);
        Application.Minimize;
      end;

      if Game.RunAsAdmin and PrgSetup.OfferRunAsAdmin then begin
        if ZipRecNr<0 then RunAsAdmin:=True else MessageDlg(LanguageSetup.ProfileMountingZipAdminError,mtError,[mbOK],0);
      end;

      if Game.DosBoxKind=dbkPure then
        result:=InvokeDOSBoxPure(T,ConfPath,PureWorkDir,Game.StartFullscreen,DosBoxCommandLine)
      else
        result:=RunDosBox(T,DOSBoxNr,ConfPath,Game.StartFullscreen,Game.ShowConsoleWindow,RunAsAdmin,DosBoxCommandLine);
      { asAdmin uses ShellExecute and intentionally returns INVALID_HANDLE_VALUE }
      DOSBoxStartedOk:=(result<>INVALID_HANDLE_VALUE) or RunAsAdmin;

      St2:=TStringList.Create;
      try
        St2.LoadFromFile(Game.SetupFile);
        SpeedTestInfoOnly(#13+#13+'### Content of prof file:'+#13+#13+St2.Text+#13+#13+'### Content of conf file:'+#13+#13+St.Text);
      finally
        St2.Free;
      end;
      SpeedTestDone;

      If ZipRecNr>=0 then ZipManager.ActivateRepackCheck(ZipRecNr,result);

      If not DOSBoxStartedOk then begin
        { CreateProcess failed: do not register fake process handles; restore UI. }
        Application.Restore;
        If Assigned(Application.MainForm) then begin
          Application.MainForm.Visible:=True;
          Application.MainForm.Enabled:=True;
        end;
        exit;
      end;

      RunPrgManager.AddCommand(Game,result);
      ScreensaverControl.DOSBoxStarted(result,PrgSetup.DOSBoxSettings[DOSBoxNr].DisableScreensaver);

    finally
      St.Free;
    end;
  finally
    If DOSBoxStartedOk and PrgSetup.MinimizeOnDosBoxStart and (not AlreadyMinimized) then MinimizedAtDOSBoxStart:=True;
  end;
end;

Procedure RunGame(const Game : TGame; const DeleteOnExit : TStringList; const RunSetup : Boolean; const DosBoxCommandLine : String; const Wait : Boolean);
Var DOSBoxHandle : THandle;
    B : Boolean;
begin
  DOSBoxHandle:=RunGameInt(Game,RunSetup,DosBoxCommandLine,DeleteOnExit);
  try
    If DOSBoxHandle=INVALID_HANDLE_VALUE then exit;

    If Wait then begin
      WaitForSingleObject(DOSBoxHandle,INFINITE);
    end else begin
      B:=(DosBoxCommandLine='');
      If B and (not Game.IgnoreWindowsFileWarnings) then begin
        If RunSetup then begin
          If (Trim(Game.SetupExe)<>'') and (ExtUpperCase(Copy(Trim(Game.SetupExe),1,7))<>'DOSBOX:') then B:=not IsWindowsExe(MakeAbsPath(Game.SetupExe,PrgSetup.BaseDir));
        end else begin
          If (Trim(Game.GameExe)<>'') and (ExtUpperCase(Copy(Trim(Game.GameExe),1,7))<>'DOSBOX:') then B:=not IsWindowsExe(MakeAbsPath(Game.GameExe,PrgSetup.BaseDir));
        end;
      end;
      if B then begin
        LastDOSBoxStartTime:=GetTickCount;
        LastDOSBoxProfile:=Game;
      end;
    end;
  finally
    If DOSBoxHandle<>INVALID_HANDLE_VALUE then CloseHandle(DOSBoxHandle);
  end;
end;

Function RunGameAndGetHandle(const Game : TGame; const DeleteOnExit : TStringList; const RunSetup : Boolean = False; const DosBoxCommandLine : String ='') : THandle;
begin
  result:=RunGameInt(Game,RunSetup,DosBoxCommandLine,DeleteOnExit);
end;

Procedure RunExtraFile(const Game : TGame; const DeleteOnExit : TStringList; const ExtraFile : Integer);
Var DOSBoxHandle : THandle;
begin
  DOSBoxHandle:=RunGameInt(Game,False,'',DeleteOnExit,ExtraFile);
  If DOSBoxHandle<>INVALID_HANDLE_VALUE then CloseHandle(DOSBoxHandle);
end;

Function RunCommandInt(const Game : TGame; const DeleteOnExit : TStringList; const Command : String; const DisableFullscreen : Boolean) : THandle;
Var St : TStringList;
    AutoexecSave, FinalizationSave : String;
    FullscreenSave : Boolean;
begin
  FullscreenSave:=Game.StartFullscreen;
  AutoexecSave:=Game.Autoexec;
  FinalizationSave:=Game.AutoexecFinalization;
  try
    St:=StringToStringList(AutoexecSave);
    try
      If Command<>'' then St.Add(Command);
      Game.Autoexec:=StringListToString(St);
    finally
      St.Free;
    end;
    if DisableFullscreen then Game.StartFullscreen:=False;
    result:=RunGameAndGetHandle(Game,DeleteOnExit,False,'');
  finally
    Game.Autoexec:=AutoexecSave;
    Game.AutoexecFinalization:=FinalizationSave;
    Game.StartFullscreen:=FullscreenSave;
  end;
end;

Procedure RunCommand(const Game : TGame; const DeleteOnExit : TStringList; const Command : String; const DisableFullscreen : Boolean);
Var DOSBoxHandle : THandle;
begin
  DOSBoxHandle:=RunCommandInt(Game,DeleteOnExit,Command,DisableFullscreen);
  If DOSBoxHandle<>INVALID_HANDLE_VALUE then CloseHandle(DOSBoxHandle);
end;

Procedure RunCommandAndWait(const Game : TGame; const DeleteOnExit : TStringList; const Command : String; const DisableFullscreen : Boolean);
Var DOSBoxHandle : THandle;
begin
  DOSBoxHandle:=RunCommandInt(Game,DeleteOnExit,Command,DisableFullscreen);
  If DOSBoxHandle=INVALID_HANDLE_VALUE then exit;
  try
    WaitForSingleObject(DOSBoxHandle,INFINITE);
  finally
    CloseHandle(DOSBoxHandle);
  end;
end;

Function RunCommandAndGetHandle(const Game : TGame; const DeleteOnExit : TStringList; const Command : String; const DisableFullscreen : Boolean = False) : THandle;
begin
  result:=RunCommandInt(Game,DeleteOnExit,Command,DisableFullscreen);
end;

Procedure RunWithCommandline(const Game : TGame; const DeleteOnExit : TStringList; const CommandLine : String; const DisableFullscreen : Boolean = False);
Var FullscreenSave : Boolean;
begin
  FullscreenSave:=Game.StartFullscreen;
  try
    if DisableFullscreen then Game.StartFullscreen:=False;
    RunGame(Game,DeleteOnExit,False,CommandLine);
  finally
    Game.StartFullscreen:=FullscreenSave;
  end;
end;

Procedure RunWithCommandlineAndWait(const Game : TGame; const DeleteOnExit : TStringList; const CommandLine : String; const DisableFullscreen : Boolean = False);
Var FullscreenSave : Boolean;
begin
  FullscreenSave:=Game.StartFullscreen;
  try
    if DisableFullscreen then Game.StartFullscreen:=False;
    RunGame(Game,DeleteOnExit,False,CommandLine,True);
  finally
    Game.StartFullscreen:=FullscreenSave;
  end;
end;

end.

