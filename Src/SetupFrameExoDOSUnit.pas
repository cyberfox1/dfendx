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
  LoggingUnit, System.JSON, ExoDOSHelpers, HiddenWaitFormUnit, ProcThreadUnit;

const
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

function LoadGames(const XMLPath: String): Integer;
Var Owner : TComponent;
    XMLDoc : TXMLDocument;
    Err : String;
begin
  Result:=0;
  Owner:=TComponent.Create(nil);
  try
    Err:=LoadXMLDoc(XMLPath, XMLDoc, '', Owner);
    if Err<>'' then raise Exception.Create(Err);
    if XMLDoc=nil then exit;
    if XMLDoc.DocumentElement.NodeName<>'LaunchBox' then exit;
    ProcessExoDOSGames(XMLDoc, ExoDOSGamesList.GetCachePath, ExoDOSGamesList.GetDBPath, Result);
  finally
    Owner.Free;
  end;
end;

procedure ProcessMediaLine(const Line : String; DB : TExoDOSMediaDB; var MediaCount : Integer);
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
  Inc(MediaCount);
end;

function ScanMedia(const ExoRoot, MediaDBPath : String) : Integer;
Var DB : TExoDOSMediaDB;
    MediaCount : Integer;
begin
  MediaCount:=0;
  DB:=TExoDOSMediaDB.Create(MediaDBPath);
  try
    DB.Initialize;

    GetExoMediaPaths(ExoRoot,
      procedure(const Line : String)
      begin
        ProcessMediaLine(Line, DB, MediaCount);
      end);

    DB.FinalizeLoad;
  finally
    DB.Free;
  end;
  result:=MediaCount;
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

  HelpContext:=ID_FileOptionsExoDOS;
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
    Thread : TProcThread;
    MediaThread : TProcThread;
    Dialog : THiddenWaitDialog;
    R : TExoWaitResult;
    T1Err, T2Err : Boolean;
    XMLPath : String;
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
             XMLPath:=IncludeTrailingPathDelimiter(S)+ExoDOSXMLFile;
               Thread:=TProcThread.Create(
                 function : Integer
                 begin
                   Result:=LoadGames(XMLPath);
                 end);
              MediaThread:=TProcThread.Create(
                 function : Integer
                 begin
                   Result:=ScanMedia(S,PrgDataDir+ExoDOSMediaDBFile);
                 end);
             Dialog:=THiddenWaitDialog.Create(nil,Thread,MediaThread,SpinnerLabel);
             try
               Dialog.ShowModal;
             finally
               Dialog.Free;
             end;
             T1Err:=False;
             T2Err:=False;
             R:=EvaluateExoWaitState(Thread,T1Err,Thread.ResultCount,MediaThread,T2Err,MediaThread.ResultCount);
             if R.ShowError1 and (Thread.FatalException is Exception) then
               MessageDlg('Exception: '+Exception(Thread.FatalException).Message,mtError,[mbOK],0);
             if R.ShowError2 and (MediaThread.FatalException is Exception) then
               MessageDlg('Exception: '+Exception(MediaThread.FatalException).Message,mtError,[mbOK],0);
             SpinnerLabel.Caption:=R.FinalCaption;
             if Thread.ResultCount=0 then begin
               SysUtils.DeleteFile(ExoDOSGamesList.GetCachePath);
               SysUtils.DeleteFile(ExoDOSGamesList.GetDBPath);
             end;
             Thread.WaitFor;
             Thread.Free;
             MediaThread.WaitFor;
             MediaThread.Free;
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

initialization
  ExoDOSGamesList:=TExoDOSGamesList.Create;

finalization
  ExoDOSGamesList.Free;

end.
