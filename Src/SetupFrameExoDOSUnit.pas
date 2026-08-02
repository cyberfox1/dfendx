unit SetupFrameExoDOSUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, PrgSetupUnit, PrgConsts, SetupFormUnit,
  Vcl.Mask, Xml.XMLDoc, ExoDOSDBUnit;

const
  ExoDOSCacheFile='ExoDOSGames.txt';
  ExoDOSDBFile='ExoDOSGames.db';
  ExoDOSMediaDBFile='ExoDOSMedia.db';
  ExoDOSXMLFile='xml\all\MS-DOS.xml';
  ExoDOSVerFile='eXo\Update\ver\ver.txt';

type
  TExoDOSGamesList=class
  public
    function DetectAndValidate(const Path : String) : Boolean;
    function CacheFileExists : Boolean;
    function CacheFileHasContent : Boolean;
    function GetCachePath : String;
    function GetDBPath : String;
    function DBFileExists : Boolean;
    function LoadFromCache : TStringList;
    function LoadFromDB : TStringList;
    property CachePath : String read GetCachePath;
    property DBPath : String read GetDBPath;
  end;

  TExoDOSLoadThread=class(TThread)
  private
    FXMLDoc : TXMLDocument;
    FCachePath, FDBPath : String;
    FGameCount : Integer;
    procedure LoadGames;
  protected
    procedure Execute; override;
  public
    constructor Create(const AXMLDoc: TXMLDocument; const ACachePath, ADBPath : String);
    property GameCount : Integer read FGameCount;
  end;

  TExoDOSMediaScanThread=class(TThread)
  private
    FExoRoot : String;
    FMediaDBPath : String;
    FMediaCount : Integer;
    procedure ScanMedia;
    procedure ProcessMediaLine(const Line : String; DB : TExoDOSMediaDB);
  protected
    procedure Execute; override;
  public
    constructor Create(const AExoRoot, AMediaDBPath : String);
    property MediaCount : Integer read FMediaCount;
  end;

  TSetupFrameExoDOS=class(TFrame, ISetupFrame)
    ExoDOSDirEdit: TLabeledEdit;
    BrowseButton: TSpeedButton;
    FindButton: TSpeedButton;
    ExoDOSReadList: TBitBtn;
    ExoDOSShowList: TBitBtn;
    SpinnerLabel: TLabel;
    procedure ButtonWork(Sender: TObject);
    procedure ExoDOSDirEditChange(Sender: TObject);
  private
    PBaseDir : PString;
    FExoDOSXMLDoc : TXMLDocument;
    function UpdateExoDetectStatus : Boolean;
  public
    function GetName : String;
    procedure InitGUIAndLoadSetup(var InitData : TInitData);
    procedure BeforeChangeLanguage;
    procedure LoadLanguage;
    procedure DOSBoxDirChanged;
    procedure ShowFrame(const AdvancedMode : Boolean);
    procedure HideFrame;
    procedure RestoreDefaults;
    procedure SaveSetup;
  end;

var ExoDOSGamesList : TExoDOSGamesList;

function SearchForExoDOS : String;

implementation

uses
  ComCtrls, ShlObj,
  XMLIntf, Xml.XMLDom, Xml.Win.msxmldom, ActiveX,
  VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools,
  HelpConsts, IconLoaderUnit, Math, PackageDBToolsUnit, ListScummVMGamesFormUnit,
  LoggingUnit, System.JSON, ExoDOSHelpers;

type
  TExoDOSWaitDialog=class(TForm)
  private
    FThread1 : TExoDOSLoadThread;
    FThread2 : TExoDOSMediaScanThread;
    FSpinnerLabel : TLabel;
    FTimer : TTimer;
    FTimerCounter : Integer;
    FShownThread1Error : Boolean;
    FShownThread2Error : Boolean;
    procedure TimerOnTimer(Sender : TObject);
    procedure FormShow(Sender : TObject);
  public
    constructor Create(AOwner: TComponent; AThread1: TExoDOSLoadThread; AThread2: TExoDOSMediaScanThread; ASpinner: TLabel); reintroduce;
    destructor Destroy; override;
  end;

const
  SpinnerChars : array[0..9] of String = (
    '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'
  );
  ExoDetectFailMsg = 'Failed to detect valid eXoDOS';

{$R *.dfm}

{ TExoDOSGamesList }

function TExoDOSGamesList.GetCachePath : String;
begin
  result:=PrgDataDir+ExoDOSCacheFile;
end;

function TExoDOSGamesList.DetectAndValidate(const Path : String) : Boolean;
Var XMLPath, VerPath : String;
begin
  result:=False;
  if Path='' then exit;

  XMLPath:=IncludeTrailingPathDelimiter(Path)+ExoDOSXMLFile;
  if not FileExists(XMLPath) then exit;
  if GetFileSize(XMLPath)<=0 then exit;

  VerPath:=IncludeTrailingPathDelimiter(Path)+ExoDOSVerFile;
  if not FileExists(VerPath) then exit;

  result:=True;
end;

function ReadExoDOSVersionFromInstall(const InstallRoot : String) : String;
Var VerPath : String;
    SL : TStringList;
begin
  result:='';
  VerPath:=IncludeTrailingPathDelimiter(InstallRoot)+ExoDOSVerFile;
  if not FileExists(VerPath) then exit;
  SL:=TStringList.Create;
  try
    SL.LoadFromFile(VerPath);
    if SL.Count=0 then exit;
    result:=Trim(SL[0]);
    if Pos('Version ',result)=1 then
      result:=Trim(Copy(result,9,MaxInt));
  finally
    SL.Free;
  end;
end;

function TExoDOSGamesList.CacheFileExists : Boolean;
begin
  result:=FileExists(GetCachePath);
end;

function TExoDOSGamesList.CacheFileHasContent : Boolean;
begin
  result:=FileExists(GetCachePath) and (GetFileSize(GetCachePath)>0);
end;

function TExoDOSGamesList.LoadFromCache : TStringList;
begin
  result:=TStringList.Create;
  if CacheFileExists then result.LoadFromFile(GetCachePath);
end;

function TExoDOSGamesList.GetDBPath : String;
begin
  result:=PrgDataDir+ExoDOSDBFile;
end;

function TExoDOSGamesList.DBFileExists : Boolean;
begin
  result:=FileExists(GetDBPath);
end;

function TExoDOSGamesList.LoadFromDB : TStringList;
Var DB : TExoDOSDB;
begin
  DB:=TExoDOSDB.Create(GetDBPath);
  try
    result:=DB.GetGamesAsTextList;
  finally
    DB.Free;
  end;
end;

{ TExoDOSLoadThread }

constructor TExoDOSLoadThread.Create(const AXMLDoc: TXMLDocument; const ACachePath, ADBPath : String);
begin
  FXMLDoc:=AXMLDoc;
  FCachePath:=ACachePath;
  FDBPath:=ADBPath;
  FGameCount:=0;
  inherited Create(False);
end;

procedure TExoDOSLoadThread.Execute;
begin
  LoadGames;
end;

procedure TExoDOSLoadThread.LoadGames;
begin
  ProcessExoDOSGames(FXMLDoc, FCachePath, FDBPath, FGameCount);
end;

{ TExoDOSMediaScanThread }

constructor TExoDOSMediaScanThread.Create(const AExoRoot, AMediaDBPath : String);
begin
  FExoRoot:=AExoRoot;
  FMediaDBPath:=AMediaDBPath;
  FMediaCount:=0;
  inherited Create(False);
end;

procedure TExoDOSMediaScanThread.Execute;
begin
  ScanMedia;
end;

  procedure TExoDOSMediaScanThread.ScanMedia;
Var DB : TExoDOSMediaDB;
begin
  DB:=TExoDOSMediaDB.Create(FMediaDBPath);
  try
    DB.Initialize;

    GetExoMediaPaths(FExoRoot,
      procedure(const Line : String)
      begin
        ProcessMediaLine(Line, DB);
      end);

    DB.FinalizeLoad;
  finally
    DB.Free;
  end;
end;

procedure TExoDOSMediaScanThread.ProcessMediaLine(const Line : String; DB : TExoDOSMediaDB);
Var DelimPos, J : Integer;
    Category, FullPath, TitleKey, Kind, Cleaned : String;
begin
  DelimPos:=Pos('|', Line);
  Category:=Copy(Line, 1, DelimPos-1);
  FullPath:=Copy(Line, DelimPos+1, MaxInt);

  Cleaned:=ExtractFileName(FullPath);

  for J:=Length(Cleaned) downto 1 do
    if Cleaned[J]='.' then begin
      Cleaned:=Copy(Cleaned, 1, J-1);
      break;
    end;

  J:=Length(Cleaned);
  if (J>=3) and (Cleaned[J] in ['0'..'9']) and (Cleaned[J-1] in ['0'..'9']) and (Cleaned[J-2]='-') then
    Cleaned:=Copy(Cleaned, 1, J-3)
  else if (J>=2) and (Cleaned[J] in ['0'..'9']) and (Cleaned[J-1]='-') then
    Cleaned:=Copy(Cleaned, 1, J-2);
  Cleaned:=Trim(Cleaned);

  if Pos('xmas lemmings', LowerCase(Cleaned)) = 0 then
    Cleaned:=StripExoTrailingYear(Cleaned);

  if Pos('Solidarno', Cleaned) > 0 then
    Cleaned:='solidarnosc';

  if Pos('xmas lemmings', LowerCase(Cleaned)) > 0 then
    Cleaned:=StringReplace(Cleaned, ' 1992 (1992)', ' (1992)', [rfReplaceAll]);

  TitleKey:=NormalizeExoMediaKey(Cleaned);
  try
    Kind:=ExtractKind(FullPath,Category);
    DB.InsertMedia(TitleKey,Category,Kind,FullPath);
  except
    on E : Exception do begin
      LogInfo('InsertMedia failed: '+E.ClassName+' '+E.Message+' file="'+ExtractFileName(FullPath)+'"');
      raise;
    end;
  end;
  Inc(FMediaCount);
end;

function TSetupFrameExoDOS.GetName : String;
begin
  result:=LanguageSetup.SetupFormExoDOS;
end;

procedure TSetupFrameExoDOS.InitGUIAndLoadSetup(var InitData : TInitData);
begin
  PBaseDir:=InitData.PBaseDir;
  NoFlicker(ExoDOSDirEdit);
  NoFlicker(ExoDOSReadList);
  NoFlicker(ExoDOSShowList);
  ExoDOSDirEdit.OnChange:=ExoDOSDirEditChange;
  ExoDOSDirEdit.Text:=PrgSetup.ExoDOSDir;
  SpinnerLabel.Visible:=False;
  ExoDOSReadList.Enabled:=False;
  ExoDOSShowList.Enabled:=False;
end;

procedure TSetupFrameExoDOS.ExoDOSDirEditChange(Sender: TObject);
begin
  UpdateExoDetectStatus;
end;

procedure TSetupFrameExoDOS.BeforeChangeLanguage;
begin
end;

procedure TSetupFrameExoDOS.LoadLanguage;
begin
  ExoDOSDirEdit.EditLabel.Caption:=LanguageSetup.SetupFormExoDOSDir;
  BrowseButton.Hint:=LanguageSetup.ChooseFolder;
  FindButton.Hint:=LanguageSetup.SetupFormSearchExoDOS;
  ExoDOSReadList.Caption:=LanguageSetup.SetupFormReadExoDOSGamesList;
  ExoDOSShowList.Caption:=LanguageSetup.SetupFormShowExoDOSGamesList;
  SpinnerLabel.Visible:=False;

  UserIconLoader.DialogImage(DI_SelectFolder,BrowseButton);
  UserIconLoader.DialogImage(DI_FindFile,FindButton);
  UserIconLoader.DialogImage(DI_ExoDOS,ExoDOSReadList);
  UserIconLoader.DialogImage(DI_Table,ExoDOSShowList);

  HelpContext:=ID_FileOptionsScummVM;
end;

procedure TSetupFrameExoDOS.DOSBoxDirChanged;
begin
end;

function TSetupFrameExoDOS.UpdateExoDetectStatus : Boolean;
Var S, Ver : String;
    Valid : Boolean;
begin
  result:=False;
  ExoDOSReadList.Enabled:=False;
  ExoDOSShowList.Enabled:=False;
  S:=Trim(ExoDOSDirEdit.Text);
  if S='' then begin
    SpinnerLabel.Visible:=False;
    SpinnerLabel.Caption:='';
    exit;
  end;
  S:=MakeAbsPath(S,IncludeTrailingPathDelimiter(PBaseDir^));
  SpinnerLabel.Visible:=True;
  Ver:=ReadExoDOSVersionFromInstall(S);
  Valid:=ExoDOSGamesList.DetectAndValidate(S) and (Ver<>'');
  result:=Valid;
  ExoDOSReadList.Enabled:=Valid;
  { List of games: valid install AND ExoDOSGames.txt present }
  if Valid and ExoDOSGamesList.CacheFileHasContent then
    ExoDOSShowList.Enabled:=True
  else
    ExoDOSShowList.Enabled:=False;
  if Valid then
    SpinnerLabel.Caption:='Found version '+Ver
  else
    SpinnerLabel.Caption:=ExoDetectFailMsg;
end;

procedure TSetupFrameExoDOS.ShowFrame(const AdvancedMode : Boolean);
begin
  UpdateExoDetectStatus;
end;

procedure TSetupFrameExoDOS.HideFrame;
begin
end;

procedure TSetupFrameExoDOS.RestoreDefaults;
begin
  ExoDOSDirEdit.Text:='';
  SpinnerLabel.Visible:=False;
  ExoDOSReadList.Enabled:=False;
  ExoDOSShowList.Enabled:=False;
end;

procedure TSetupFrameExoDOS.SaveSetup;
begin
  PrgSetup.ExoDOSDir:=Trim(ExoDOSDirEdit.Text);
end;

procedure TSetupFrameExoDOS.ButtonWork(Sender : TObject);
Var S : String;
    SL, SL2 : TStringList;
    Thread : TExoDOSLoadThread;
    MediaThread : TExoDOSMediaScanThread;
    Dialog : TExoDOSWaitDialog;
    XMLDoc : TXMLDocument;
begin
  Case (Sender as TComponent).Tag of
    16 : begin
           S:=ExoDOSDirEdit.Text;
           if Trim(S)='' then S:=IncludeTrailingPathDelimiter(PBaseDir^);
           S:=MakeAbsPath(S,IncludeTrailingPathDelimiter(PBaseDir^));
           if SelectDirectory(Handle,LanguageSetup.SetupFormExoDOSDir,S) then begin
             ExoDOSDirEdit.Text:=MakeRelPath(S,IncludeTrailingPathDelimiter(PBaseDir^),True);
             UpdateExoDetectStatus;
           end;
         end;
    17 : begin
           S:=SearchForExoDOS;
           if S<>'' then begin
             ExoDOSDirEdit.Text:=S;
             UpdateExoDetectStatus;
           end else begin
             MessageDlg('eXoDOS installation not found.',mtInformation,[mbOK],0);
           end;
         end;
       18 : begin
             if not UpdateExoDetectStatus then exit;
             S:=MakeAbsPath(Trim(ExoDOSDirEdit.Text),IncludeTrailingPathDelimiter(PBaseDir^));
             PrgSetup.ExoDOSDir:=S;
             PrgSetup.ExoDOSVersion:=ReadExoDOSVersionFromInstall(S);
              SysUtils.DeleteFile(ExoDOSGamesList.GetCachePath);
              SysUtils.DeleteFile(ExoDOSGamesList.GetDBPath);
              SysUtils.DeleteFile(PrgDataDir+ExoDOSMediaDBFile);
              SpinnerLabel.Visible:=True;
             XMLDoc:=LoadXMLDoc(IncludeTrailingPathDelimiter(S)+ExoDOSXMLFile);
             if XMLDoc=nil then begin
               SpinnerLabel.Caption:='Failed to read XML games list';
               SysUtils.DeleteFile(ExoDOSGamesList.GetCachePath);
               SysUtils.DeleteFile(ExoDOSGamesList.GetDBPath);
               exit;
             end;
             if XMLDoc.DocumentElement.NodeName<>'LaunchBox' then begin
               SpinnerLabel.Caption:='Failed to read XML games list';
               XMLDoc.Free;
               SysUtils.DeleteFile(ExoDOSGamesList.GetCachePath);
               SysUtils.DeleteFile(ExoDOSGamesList.GetDBPath);
               exit;
             end;
               Thread:=TExoDOSLoadThread.Create(XMLDoc,ExoDOSGamesList.GetCachePath,ExoDOSGamesList.GetDBPath);
              MediaThread:=TExoDOSMediaScanThread.Create(S,PrgDataDir+ExoDOSMediaDBFile);
             Dialog:=TExoDOSWaitDialog.Create(nil,Thread,MediaThread,SpinnerLabel);
             try
               Dialog.ShowModal;
             finally
               Dialog.Free;
               if Thread.GameCount=0 then begin
                 SysUtils.DeleteFile(ExoDOSGamesList.GetCachePath);
                 SysUtils.DeleteFile(ExoDOSGamesList.GetDBPath);
               end;
                Thread.WaitFor;
                Thread.Free;
                MediaThread.WaitFor;
                MediaThread.Free;
               Self.FExoDOSXMLDoc:=XMLDoc;
             end;
            ExoDOSShowList.Enabled:=ExoDOSReadList.Enabled and ExoDOSGamesList.CacheFileHasContent;
          end;
     19 : begin
            SL:=TStringList.Create;
            try
              if ExoDOSGamesList.DBFileExists then begin
                SL2:=ExoDOSGamesList.LoadFromDB;
                try
                  SL.AddStrings(SL2);
                finally
                  SL2.Free;
                end;
              end else if FileExists(ExoDOSGamesList.CachePath) then
                SL.LoadFromFile(ExoDOSGamesList.CachePath);
              ListScummVMGamesForm:=TListScummVMGamesForm.Create(self,SL);
              try
                ListScummVMGamesForm.ShowModal;
              finally
                ListScummVMGamesForm.Free;
              end;
            finally
              SL.Free;
            end;
          end;
  end;
end;

{ Global helpers }

function SearchForExoDOS : String;
Var I : Integer;
    Paths : Array[0..4] of String;
begin
  result:='';
  Paths[0]:='D:\eXoDOS\';
  Paths[1]:='C:\eXoDOS\';
  Paths[2]:=IncludeTrailingPathDelimiter(GetSpecialFolder(Application.MainForm.Handle,CSIDL_PROGRAM_FILES))+'eXoDOS\';
  Paths[3]:=IncludeTrailingPathDelimiter(PrgDir)+'..\eXoDOS\';
  Paths[4]:=IncludeTrailingPathDelimiter(PrgDir)+'eXoDOS\';

  For I:=0 to 4 do begin
    if ExoDOSGamesList.DetectAndValidate(Paths[I]) then begin
      result:=Paths[I];
      exit;
    end;
  end;
end;

{ TExoDOSWaitDialog }

constructor TExoDOSWaitDialog.Create(AOwner: TComponent; AThread1: TExoDOSLoadThread; AThread2: TExoDOSMediaScanThread; ASpinner: TLabel);
begin
  inherited CreateNew(AOwner);
  FThread1:=AThread1;
  FThread2:=AThread2;
  FSpinnerLabel:=ASpinner;
  FTimerCounter:=0;
  FShownThread1Error:=False;
  FShownThread2Error:=False;
  BorderStyle:=bsNone;
  Left:=-100;
  Top:=-100;
  Width:=1;
  Height:=1;
  AlphaBlend:=True;
  AlphaBlendValue:=1;
  FTimer:=TTimer.Create(self);
  FTimer.Interval:=50;
  FTimer.Enabled:=False;
  FTimer.OnTimer:=TimerOnTimer;
  OnShow:=FormShow;
end;

destructor TExoDOSWaitDialog.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TExoDOSWaitDialog.FormShow(Sender : TObject);
begin
  FTimer.Enabled:=True;
end;

procedure TExoDOSWaitDialog.TimerOnTimer(Sender : TObject);
Var R : TExoWaitResult;
begin
  FTimer.Enabled:=False;

  R:=EvaluateExoWaitState(
    FThread1, FShownThread1Error, FThread1.GameCount,
    FThread2, FShownThread2Error, FThread2.MediaCount
  );

  if R.ShowError1 and (FThread1.FatalException is Exception) then
    MessageDlg('Exception: '+Exception(FThread1.FatalException).Message,mtError,[mbOK],0);
  if R.ShowError2 and (FThread2<>nil) and (FThread2.FatalException is Exception) then
    MessageDlg('Exception: '+Exception(FThread2.FatalException).Message,mtError,[mbOK],0);

  if R.ShouldSpin then begin
    Inc(FTimerCounter);
    FSpinnerLabel.Caption:=SpinnerChars[FTimerCounter mod 10];
    FTimer.Enabled:=True;
    exit;
  end;

  FSpinnerLabel.Caption:=R.FinalCaption;
  Close;
end;

initialization
  ExoDOSGamesList:=TExoDOSGamesList.Create;

finalization
  ExoDOSGamesList.Free;

end.
