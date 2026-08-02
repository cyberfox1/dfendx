unit SetupDosBoxFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls;

Type TSearchType=(stDOSBox, stOggEnc, stLame, stScummVM, stQBasic);

{ Standard + DOSBox-X + Staging paths from SearchDosBoxAll. }
type
  TDOSBoxSearchResult = record
    StandardDir : String;
    XDir : String;
    StagingDir : String;
  end;

type
  TSetupDosBoxForm = class(TForm)
    InfoLabel: TLabel;
    AbortButton: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure AbortButtonClick(Sender: TObject);
    Procedure StartSearch(var Msg : TMessage); message WM_USER+1;
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
    Aborted : Boolean;
    Count : Integer;
    Function SearchDir(const Dir : String) : Boolean;
  public
    { Public-Deklarationen }
    SearchType : TSearchType;
    DOSBoxDir : String; {if SearchType=stDOSBox}
  end;

var
  SetupDosBoxForm: TSetupDosBoxForm;

{ Full search: existing standard discovery + X/Staging path lists.
  A path is kept only when DetermineDosBoxKind matches that bucket
  (dbkNone / dbkUnknown = reject). }
Function SearchDosBoxAll(const AOwner : TComponent; const HintDir : String;
  out R : TDOSBoxSearchResult) : Boolean;
{ Compatibility: SearchDosBoxAll then ADOSBoxDir := Standard, else X, else Staging. }
Function SearchDosBox(const AOwner : TComponent; var ADOSBoxDir : String) : Boolean;
{ Apply Standard → X → Staging: fill [0] if empty; else secondary for X/Staging only. }
Procedure ApplyDOSBoxSearchResult(const R : TDOSBoxSearchResult);
Function SearchOggEnc(const AOwner : TComponent) : Boolean;
Function SearchLame(const AOwner : TComponent) : Boolean;
Function SearchScummVM(const AOwner : TComponent) : Boolean;
Function SearchQBasicVM(const AOwner : TComponent) : Boolean;

Procedure FastSearchAllTools;

implementation

uses ShlObj, PrgSetupUnit, LanguageSetupUnit, PrgConsts, CommonHelpers, CommonTools,
     VistaToolsUnit, IconLoaderUnit, GameDBToolsHelpers;

{$R *.dfm}

procedure TSetupDosBoxForm.FormCreate(Sender: TObject);
begin
  SearchType:=stDOSBox;
end;

procedure TSetupDosBoxForm.FormShow(Sender: TObject);
begin
  DoubleBuffered:=True;
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);

  Case SearchType of
    stDOSBox  : Caption:=LanguageSetup.SetupDosBoxForm;
    stOggEnc  : Caption:=LanguageSetup.SetupDosBoxFormOggEnc;
    stLame    : Caption:=LanguageSetup.SetupDosBoxFormLame;
    stScummVM : Caption:=LanguageSetup.SetupDosBoxFormScummVM;
    stQBasic : Caption:=LanguageSetup.SetupDosBoxFormQBasic;
  end;
  AbortButton.Caption:=LanguageSetup.Abort;

  UserIconLoader.DialogImage(DI_Abort,AbortButton);

  PostMessage(Handle,WM_USER+1,0,0);
end;

procedure TSetupDosBoxForm.StartSearch(var Msg: TMessage);
begin
  Repaint;
  Application.ProcessMessages;

  Aborted:=False;
  Count:=0;

  try
    { Only search under the DFend install/data trees — never crawl whole drives. }
    If SearchDir(PrgDir) then begin ModalResult:=mrOK; exit; end;
    If PrgDataDir<>PrgDir then begin
      If SearchDir(PrgDataDir) then begin ModalResult:=mrOK; exit; end;
    end;
    ModalResult:=mrAbort;
  finally
    Close;
  end;
end;

function TSetupDosBoxForm.SearchDir(const Dir: String): Boolean;
Var Rec : TSearchRec;
    I : Integer;
begin
  result:=False;

  Case SearchType of
    stDOSBox  : begin result:=FileExists(Dir+DosBoxFileName); if result then begin DOSBoxDir:=Dir; exit; end; end;
    stOggEnc  : begin result:=FileExists(Dir+OggEncPrgFile); if result then begin PrgSetup.WaveEncOgg:=Dir+OggEncPrgFile; exit; end; end;
    stLame    : begin result:=FileExists(Dir+LamePrgFile); if result then begin PrgSetup.WaveEncMp3:=Dir+LamePrgFile; exit; end; end;
    stScummVM : begin result:=FileExists(Dir+ScummPrgFile); if result then begin PrgSetup.ScummVMPath:=Dir; exit; end; end;
    stQBasic  : begin
                  result:=FileExists(Dir+QBasicPrgFile); if result then begin PrgSetup.QBasic:=Dir+QBasicPrgFile; exit; end;
                  result:=FileExists(Dir+QB45PrgFile); if result then begin PrgSetup.QBasic:=Dir+QB45PrgFile; exit; end;
                  result:=FileExists(Dir+QB71PrgFile); if result then begin PrgSetup.QBasic:=Dir+QB71PrgFile; exit; end;
                end;
  end;

  inc(Count);
  If Count mod 20=0 then begin
    InfoLabel.Caption:=Dir;
    Application.ProcessMessages;
    If Aborted then exit;
  end;

  I:=FindFirst(Dir+'*.*',faDirectory,Rec);
  try
    while I=0 do begin
      If ((Rec.Attr and faDirectory)<>0) and (Rec.Name<>'.') and (Rec.Name<>'..') then begin
        result:=SearchDir(Dir+Rec.Name+'\');
        if result or Aborted then exit;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

procedure TSetupDosBoxForm.AbortButtonClick(Sender: TObject);
begin
  Aborted:=True;
end;

{ global }

{ Version key from a folder name like "DOSBox-0.74.3" (highest key wins).
  Non-matching names return 0. Components are packed for numeric compare. }
Function DOSBoxFolderVersionKey(const FolderName : String) : Int64;
Var S, Part : String;
    I, P, Val, Shift : Integer;
begin
  result:=0;
  S:=FolderName;
  If (Length(S)>=7) and (Copy(ExtUpperCase(S),1,7)='DOSBOX-') then
    S:=Copy(S,8,MaxInt)
  else
    exit;

  Shift:=3; { up to 4 numeric components }
  While (S<>'') and (Shift>=0) do begin
    P:=Pos('.',S);
    If P=0 then begin Part:=S; S:=''; end else begin Part:=Copy(S,1,P-1); S:=Copy(S,P+1,MaxInt); end;
    Val:=0;
    For I:=1 to length(Part) do begin
      If (Part[I]>='0') and (Part[I]<='9') then Val:=Val*10+(Ord(Part[I])-Ord('0')) else break;
    end;
    result:=result or (Int64(Val) shl (Shift*16));
    Dec(Shift);
  end;
end;

{ CSIDL_PROGRAM_FILESX86 may be missing from older ShlObj units. }
const
  CSIDL_PROGRAM_FILESX86_Local = $002a;

Function ProgramFilesRoot(const Folder : Integer) : String;
begin
  result:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.Handle,Folder));
  If (result='') or (result='\') then result:='';
end;

Function DOSBoxExeExistsInDir(const Dir : String) : Boolean;
begin
  result:=(Dir<>'') and FileExists(IncludeTrailingPathDelimiter(Dir)+DosBoxFileName);
end;

{ Named installs under Program Files / Program Files (x86). First hit wins. }
Function FindNamedProgramFilesDOSBox(out ADOSBoxDir : String) : Boolean;
Const
  SubDirs : array[0..3] of String = (
    'DOSBox Staging\',
    'dosbox-staging\',
    'DOSBox-X\',
    'DOSBox\'
  );
Var
  Bases : array[0..1] of String;
  I, J : Integer;
  Candidate : String;
begin
  result:=False;
  ADOSBoxDir:='';
  Bases[0]:=ProgramFilesRoot(CSIDL_PROGRAM_FILES);
  Bases[1]:=ProgramFilesRoot(CSIDL_PROGRAM_FILESX86_Local);
  For I:=Low(SubDirs) to High(SubDirs) do
    For J:=Low(Bases) to High(Bases) do
      If Bases[J]<>'' then begin
        Candidate:=Bases[J]+SubDirs[I];
        If DOSBoxExeExistsInDir(Candidate) then begin
          ADOSBoxDir:=IncludeTrailingPathDelimiter(Candidate);
          result:=True;
          exit;
        end;
      end;
end;

{ Scan one Program Files root for DOSBOX-* dirs; update BestDir if a higher version is found. }
Procedure ScanVersionedDOSBoxFolders(const Base : String; var BestKey : Int64; var BestDir : String; var Found : Boolean);
Var Candidate : String;
    Rec : TSearchRec;
    I : Integer;
    Key : Int64;
begin
  If Base='' then exit;
  I:=FindFirst(Base+'*.*',faDirectory,Rec);
  try
    While I=0 do begin
      If (Rec.Name<>'.') and (Rec.Name<>'..') and (Copy(ExtUpperCase(Rec.Name),1,7)='DOSBOX-') then begin
        Candidate:=Base+Rec.Name+'\';
        If FileExists(Candidate+DosBoxFileName) then begin
          Key:=DOSBoxFolderVersionKey(Rec.Name);
          If (not Found) or (Key>BestKey) then begin
            BestKey:=Key;
            BestDir:=Candidate;
            Found:=True;
          end;
        end;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

{ Highest version under Program Files\DOSBox-0.x.y\ and Program Files (x86)\... }
Function FindHighestProgramFilesDOSBox(out ADOSBoxDir : String) : Boolean;
Var BestKey : Int64;
begin
  result:=False;
  ADOSBoxDir:='';
  BestKey:=-1;
  ScanVersionedDOSBoxFolders(ProgramFilesRoot(CSIDL_PROGRAM_FILES),BestKey,ADOSBoxDir,result);
  ScanVersionedDOSBoxFolders(ProgramFilesRoot(CSIDL_PROGRAM_FILESX86_Local),BestKey,ADOSBoxDir,result);
end;

Function KindAtDir(const Dir : String; const Want : TDOSBoxKind) : Boolean;
Var Base : String;
begin
  Base:='';
  If PrgSetup<>nil then Base:=PrgSetup.BaseDir;
  Result:=(Trim(Dir)<>'') and (DetermineDosBoxKind(Dir,Base)=Want);
end;

Function LocalAppDataRoot : String;
begin
  Result:=IncludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA'));
  If (Result='') or (Result='\') then Result:='';
end;

{ First path in list where DetermineDosBoxKind = Want. }
Function FindFirstDirOfKind(const Paths : array of String; const Want : TDOSBoxKind;
  out ADir : String) : Boolean;
Var I : Integer;
    Candidate : String;
begin
  Result:=False;
  ADir:='';
  For I:=Low(Paths) to High(Paths) do begin
    Candidate:=Trim(Paths[I]);
    If Candidate='' then Continue;
    Candidate:=IncludeTrailingPathDelimiter(Candidate);
    If KindAtDir(Candidate,Want) then begin
      ADir:=Candidate;
      Result:=True;
      Exit;
    end;
  end;
end;

{ Exact pre-change SearchDosBox body — no kind filter. }
Function SearchStandardDOSBoxDir(const AOwner : TComponent; const HintDir : String;
  out ADir : String) : Boolean;
Var S : String;
begin
  ADir:='';
  Result:=False;

  { 1. Already configured and valid }
  If DOSBoxExeExistsInDir(HintDir) then begin
    ADir:=IncludeTrailingPathDelimiter(HintDir);
    Result:=True;
    Exit;
  end;

  { 2. Known named installs (Staging, X, unversioned official) under PF / PFx86 }
  If FindNamedProgramFilesDOSBox(S) then begin ADir:=S; Result:=True; Exit; end;

  { 3. Highest version under Program Files\DOSBox-0.x.y\ (and x86) }
  If FindHighestProgramFilesDOSBox(S) then begin ADir:=S; Result:=True; Exit; end;

  { 4. Silent scan of install/data dirs only (portable / leftover copies). No whole-PC crawl. }
  SetupDosBoxForm:=TSetupDosBoxForm.Create(AOwner);
  try
    SetupDosBoxForm.SearchType:=stDOSBox;
    If SetupDosBoxForm.SearchDir(PrgDir) then begin
      Result:=True; ADir:=SetupDosBoxForm.DOSBoxDir; Exit;
    end;
    If PrgDataDir<>PrgDir then begin
      If SetupDosBoxForm.SearchDir(PrgDataDir) then begin
        Result:=True; ADir:=SetupDosBoxForm.DOSBoxDir; Exit;
      end;
    end;
  finally
    SetupDosBoxForm.Free;
  end;
end;

Function SearchDosBoxAll(const AOwner : TComponent; const HintDir : String;
  out R : TDOSBoxSearchResult) : Boolean;
Var LAD, StdDir, XDir, StagingDir : String;
    XPaths, StagingPaths : array[0..3] of String;
begin
  R.StandardDir:='';
  R.XDir:='';
  R.StagingDir:='';

  { Standard: original search only (no KindAtDir). }
  If SearchStandardDOSBoxDir(AOwner,HintDir,StdDir) then
    R.StandardDir:=IncludeTrailingPathDelimiter(StdDir);

  LAD:=LocalAppDataRoot;
  XPaths[0]:='C:\Program Files\DOSBox-X\';
  XPaths[1]:='C:\DOSBox-X\';
  XPaths[2]:=LAD+'Programs\DOSBox-X\';
  XPaths[3]:=LAD+'DOSBox-X\';
  If LAD='' then begin
    XPaths[2]:='';
    XPaths[3]:='';
  end;
  If FindFirstDirOfKind(XPaths,dbkX,XDir) then
    R.XDir:=XDir;

  StagingPaths[0]:='C:\Program Files\DOSBox Staging\';
  StagingPaths[1]:='C:\DOSBox Staging\';
  StagingPaths[2]:=LAD+'Programs\DOSBox Staging\';
  StagingPaths[3]:=LAD+'DOSBox Staging\';
  If LAD='' then begin
    StagingPaths[2]:='';
    StagingPaths[3]:='';
  end;
  If FindFirstDirOfKind(StagingPaths,dbkStaging,StagingDir) then
    R.StagingDir:=StagingDir;

  Result:=(R.StandardDir<>'') or (R.XDir<>'') or (R.StagingDir<>'');
end;

Function SearchDosBox(const AOwner : TComponent; var ADOSBoxDir : String) : Boolean;
Var R : TDOSBoxSearchResult;
begin
  Result:=SearchDosBoxAll(AOwner,ADOSBoxDir,R);
  If not Result then Exit;
  If R.StandardDir<>'' then ADOSBoxDir:=R.StandardDir
  else If R.XDir<>'' then ADOSBoxDir:=R.XDir
  else ADOSBoxDir:=R.StagingDir;
end;

Function PrimaryDOSBoxDirUnset : Boolean;
begin
  Result:=(PrgSetup=nil) or (PrgSetup.DOSBoxSettingsCount<=0) or
    (Trim(PrgSetup.DOSBoxSettings[0].DosBoxDir)='');
end;

Function DOSBoxInstallPathAlreadyUsed(const Dir : String) : Boolean;
Var I : Integer;
    AbsA, AbsB, Base : String;
begin
  Result:=False;
  If (PrgSetup=nil) or (Trim(Dir)='') then Exit;
  Base:=PrgSetup.BaseDir;
  AbsA:=IncludeTrailingPathDelimiter(ExtUpperCase(MakeAbsPath(Dir,Base)));
  For I:=0 to PrgSetup.DOSBoxSettingsCount-1 do begin
    AbsB:=IncludeTrailingPathDelimiter(ExtUpperCase(
      MakeAbsPath(PrgSetup.DOSBoxSettings[I].DosBoxDir,Base)));
    If AbsA=AbsB then begin Result:=True; Exit; end;
  end;
end;

Procedure ApplyOneDOSBoxSearchDir(const Dir, SecondaryName : String;
  const AllowSecondary : Boolean);
Var Idx : Integer;
begin
  If Trim(Dir)='' then Exit;
  If PrimaryDOSBoxDirUnset then begin
    PrgSetup.DOSBoxSettings[0].DosBoxDir:=IncludeTrailingPathDelimiter(Dir);
    Exit;
  end;
  If not AllowSecondary then Exit;
  If DOSBoxInstallPathAlreadyUsed(Dir) then Exit;
  Idx:=PrgSetup.AddDOSBoxSettings(SecondaryName);
  PrgSetup.DOSBoxSettings[Idx].DosBoxDir:=IncludeTrailingPathDelimiter(Dir);
end;

Procedure ApplyDOSBoxSearchResult(const R : TDOSBoxSearchResult);
begin
  { Order: standard → X → Staging. Standard never secondary. }
  ApplyOneDOSBoxSearchDir(R.StandardDir,'',False);
  ApplyOneDOSBoxSearchDir(R.XDir,'DOSBox-X',True);
  ApplyOneDOSBoxSearchDir(R.StagingDir,'DOSBox Staging',True);
end;

Function SearchOggEnc(const AOwner : TComponent) : Boolean;
begin
  If FileExists(PrgSetup.WaveEncOgg) then begin
    result:=True;
    exit;
  end;

  If FileExists(PrgDir+OggEncPrgFile) then begin
    PrgSetup.WaveEncOgg:=PrgDir+OggEncPrgFile;
    result:=True;
    exit;
  end;

  If FileExists(PrgDir+BinFolder+'\'+OggEncPrgFile) then begin
    PrgSetup.WaveEncOgg:=PrgDir+BinFolder+'\'+OggEncPrgFile;
    result:=True;
    exit;
  end;

  SetupDosBoxForm:=TSetupDosBoxForm.Create(AOwner);
  try
    SetupDosBoxForm.SearchType:=stOggEnc;
    result:=(SetupDosBoxForm.ShowModal<>mrAbort);
  finally
    SetupDosBoxForm.Free;
  end;
end;

Function SearchLame(const AOwner : TComponent) : Boolean;
Var S : String;
begin
  If FileExists(PrgSetup.WaveEncMp3) then begin
    result:=True;
    exit;
  end;

  S:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.MainForm.Handle,CSIDL_PROGRAM_FILES))+'Lame\'+LamePrgFile;
  If FileExists(S) then begin PrgSetup.WaveEncMp3:=S; result:=True; exit; end;

  S:=PrgDir+BinFolder+'\';
  If FileExists(S) then begin PrgSetup.WaveEncMp3:=S; result:=True; exit; end;

  SetupDosBoxForm:=TSetupDosBoxForm.Create(AOwner);
  try
    SetupDosBoxForm.SearchType:=stLame;
    result:=(SetupDosBoxForm.ShowModal<>mrAbort);
  finally
    SetupDosBoxForm.Free;
  end;
end;

Function SearchScummVM(const AOwner : TComponent) : Boolean;
Var S : String;
begin
  If DirectoryExists(PrgSetup.ScummVMPath) then begin
    result:=True;
    exit;
  end;

  S:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.MainForm.Handle,CSIDL_PROGRAM_FILES))+'ScummVM\';
  If FileExists(S+ScummPrgFile) then begin PrgSetup.ScummVMPath:=S; result:=True; exit; end;

  SetupDosBoxForm:=TSetupDosBoxForm.Create(AOwner);
  try
    SetupDosBoxForm.SearchType:=stScummVM;
    result:=(SetupDosBoxForm.ShowModal<>mrAbort);
  finally
    SetupDosBoxForm.Free;
  end;
end;

Function SearchQBasicVM(const AOwner : TComponent) : Boolean;
Var S : String;
begin
  If FileExists(PrgSetup.QBasic) then begin
    result:=True;
    exit;
  end;

  S:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.MainForm.Handle,CSIDL_PROGRAM_FILES))+'QBasic\';
  If FileExists(S+QBasicPrgFile) then begin PrgSetup.QBasic:=S+QBasicPrgFile; result:=True; exit; end;

  S:=PrgDir+BinFolder+'\';
  If FileExists(S+QBasicPrgFile) then begin PrgSetup.QBasic:=S+QBasicPrgFile; result:=True; exit; end;

  SetupDosBoxForm:=TSetupDosBoxForm.Create(AOwner);
  try
    SetupDosBoxForm.SearchType:=stQBasic;
    result:=(SetupDosBoxForm.ShowModal<>mrAbort);
  finally
    SetupDosBoxForm.Free;
  end;
end;

Procedure FastSearchAllTools;
Var S : String;
begin
  If not FileExists(PrgSetup.WaveEncOgg) then begin
    If FileExists(PrgDir+OggEncPrgFile) then PrgSetup.WaveEncOgg:=PrgDir+OggEncPrgFile else begin
      If FileExists(PrgDir+BinFolder+'\'+OggEncPrgFile) then PrgSetup.WaveEncOgg:=PrgDir+BinFolder+'\'+OggEncPrgFile;
    end;
  end;

  If not FileExists(PrgSetup.WaveEncMp3) then begin
    S:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.MainForm.Handle,CSIDL_PROGRAM_FILES))+'Lame\'+LamePrgFile;
    If FileExists(S) then PrgSetup.WaveEncMp3:=S else begin
      If FileExists(PrgDir+BinFolder+'\'+LamePrgFile) then PrgSetup.WaveEncMp3:=PrgDir+BinFolder+'\'+LamePrgFile;
    end;
  end;

  If not DirectoryExists(PrgSetup.ScummVMPath) then begin
    S:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.MainForm.Handle,CSIDL_PROGRAM_FILES))+'ScummVM\';
    If FileExists(S+ScummPrgFile) then PrgSetup.ScummVMPath:=S;
  end;

  If not FileExists(PrgSetup.QBasic) then begin
    S:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.MainForm.Handle,CSIDL_PROGRAM_FILES))+'QBasic\';
    If FileExists(S+QBasicPrgFile) then PrgSetup.QBasic:=S+QBasicPrgFile else begin
      If FileExists(PrgDir+BinFolder+'\'+QBasicPrgFile) then PrgSetup.QBasic:=PrgDir+BinFolder+'\'+QBasicPrgFile;
    end;
  end;
end;

end.
