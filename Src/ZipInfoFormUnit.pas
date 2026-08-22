unit ZipInfoFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons;

Type TZipMode=(zmExtract, zmCreate, zmAdd, zmCreateAndDelete, zmAddAndDelete, zmDeleteOnly);

Type TDeleteMode=(dmNo, dmFiles, dmFolder, dmNoNoWarning, dmFilesNoWarning, dmFolderNoWarning); {Warning = Overwrite zip files warining}

type
  TZipInfoForm = class(TForm)
    ProgressBar: TProgressBar;
    InfoLabel: TLabel;
    CancelButton: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    ZipFile, Folder : String;
    Mode : TZipMode;
    FDeleteMode : TDeleteMode;
    FProcessingCanceled : Boolean;
    FProcessHandle : THandle;

    Procedure PostShow(var Msg : TMessage); message WM_USER+1;
    Function ExternalWork(const Nr : Integer) : Boolean;
    Function DeleteFolder(Folder : String; const ThisIsMainFolder : Boolean) : Boolean;
    Function DeleteFiles : Boolean;
    Procedure SetBusyInfo;
  public
    Function Init(const AMode : TZipMode; const AZipFile, AFolder : String) : Boolean;
    property DeleteMode : TDeleteMode read FDeleteMode write FDeleteMode;
  end;

var
  ZipInfoForm: TZipInfoForm;

Function ExtractZipFile(const AOwner : TComponent; const AZipFile, ADestFolder : String) : Boolean;
Function CreateZipFile(const AOwner : TComponent; const AZipFile, ADestFolder : String; const DeleteMode : TDeleteMode = dmNo) : Boolean;
Function AddToZipFile(const AOwner : TComponent; const AZipFile, ADestFolder : String; const DeleteMode : TDeleteMode = dmNo) : Boolean;
Function DeleteUnpackedFiles(const AOwner : TComponent; const ADestFolder : String; const DeleteMode : TDeleteMode = dmNo) : Boolean;

Function ExtractZipDrive(const AOwner : TComponent; const AZipFile, AZipAddFolder, ADestFolder : String) : Boolean;

implementation

uses LanguageSetupUnit, PrgSetupUnit, CommonHelpers, CommonTools, DOSBoxUnit, PrgConsts,
     ZipFormHelpers, GameDBToolsUnit, VistaToolsUnit, System.UITypes;

{$R *.dfm}

procedure TZipInfoForm.FormCreate(Sender: TObject);
begin
  FProcessingCanceled:=false;
  FProcessHandle:=0;
  { DoubleBuffered + GlassFrame break marquee progress painting }
  DoubleBuffered:=False;
  ProgressBar.DoubleBuffered:=False;
  ProgressBar.Style:=pbstMarquee;
  ProgressBar.MarqueeInterval:=50;
end;

function TZipInfoForm.Init(const AMode: TZipMode; const AZipFile, AFolder: String): Boolean;
begin
  result:=False;

  Mode:=AMode;
  ZipFile:=AZipFile;
  Folder:=IncludeTrailingPathDelimiter(AFolder);

  If (Mode=zmExtract) or (Mode=zmAdd) or (Mode=zmAddAndDelete) then begin
    If not FileExists(ZipFile) then begin MessageDlg(Format(LanguageSetup.MessageCouldNotFindFile,[ZipFile]),mtError,[mbOK],0); exit; end;
  end;

  If (Mode=zmCreate) or (Mode=zmCreateAndDelete) then begin
    If FileExists(ZipFile) then begin
      If (FDeleteMode<>dmNoNoWarning) and (FDeleteMode<>dmFilesNoWarning) and (FDeleteMode<>dmFolderNoWarning) then begin
        If MessageDlg(Format(LanguageSetup.ZipFormOverwriteWarning,[ZipFile]),mtWarning,[mbYes,mbNo],0)<>mrYes then exit;
      end;
      If not ExtDeleteFileWithPause(ZipFile,ftZipOperation) then begin MessageDlg(Format(LanguageSetup.MessageCouldNotDeleteFile,[ZipFile]),mtError,[mbOK],0); exit; end;
    end;
  end;

  Case Mode of
    zmExtract                   : Caption:=LanguageSetup.ZipFormCaptionExtract;
    zmCreate, zmCreateAndDelete : Caption:=LanguageSetup.ZipFormCaptionCreate;
    zmAdd, zmAddAndDelete       : Caption:=LanguageSetup.ZipFormCaptionAdd;
    zmDeleteOnly                : Caption:=LanguageSetup.ZipFormCaptionDelete;
  end;
  SetBusyInfo;

  If Mode=zmExtract then begin
    If not ForceDirectories(Folder) then begin MessageDlg(Format(LanguageSetup.MessageCouldNotCreateDir,[Folder]),mtError,[mbOK],0); exit; end;
  end;

  If (Mode=zmCreate) or (Mode=zmAdd) or (Mode=zmCreateAndDelete) or (Mode=zmAddAndDelete) then begin
    If not DirectoryExists(Folder) then begin MessageDlg(Format(LanguageSetup.MessageDirectoryNotFound,[Folder]),mtError,[mbOK],0); exit; end;
  end;

  result:=True;
end;

procedure TZipInfoForm.FormShow(Sender: TObject);
begin
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);
  CancelButton.Caption:=LanguageSetup.Cancel;
  SetBusyInfo;
  ProgressBar.Style:=pbstMarquee;
  Application.ProcessMessages;

  PostMessage(Handle,WM_USER+1,0,0);
end;

procedure TZipInfoForm.SetBusyInfo;
Var S : String;
begin
  Case Mode of
    zmExtract                   : S:=LanguageSetup.ZipFormProgressExtract;
    zmCreate, zmCreateAndDelete : S:=LanguageSetup.ZipFormProgressCreate;
    zmAdd, zmAddAndDelete       : S:=LanguageSetup.ZipFormProgressAdd;
    else S:=Caption;
  end;
  If Mode=zmDeleteOnly
    then InfoLabel.Caption:=Caption
    else InfoLabel.Caption:=Format(S,[ExtractFileName(ZipFile)])+#13+#13+Folder;
end;

procedure TZipInfoForm.PostShow(var Msg: TMessage);
Var Ext,SaveDir : String;
    Ok, Handled : Boolean;
    I : Integer;
begin
  SaveDir:=GetCurrentDir;
  try
    SetCurrentDir(ExtractFilePath(ExpandFileName(Application.ExeName)));

    if Mode=zmDeleteOnly then begin
      Ok:=True;
    end else begin
      Ext:=Trim(UpperCase(ExtractFileExt(ZipFile)));

      If (Mode in [zmCreate, zmAdd, zmCreateAndDelete, zmAddAndDelete]) and (not DirectoryExists(Folder)) then begin
        MessageDlg(Format(LanguageSetup.MessageDirectoryNotFound,[Folder]),mtError,[mbOk],0);
        ModalResult:=mrCancel;
        PostMessage(Handle,WM_CLOSE,0,0);
        exit;
      end;

      EnsureBundled7zaPackerRow;

      Handled:=False; Ok:=False;
      For I:=0 to PrgSetup.PackerSettingsCount-1 do
        If ExtensionInList(Ext,PrgSetup.PackerSettings[I].FileExtensions) then begin
          Handled:=True;
          Ok:=ExternalWork(I);
          Break;
        end;

      If not Handled then begin
        MessageDlg(Format(LanguageSetup.ZipFormUnknownExtension,[Ext]),mtError,[mbOK],0);
      end;
    end;

    If Ok and ((Mode=zmCreateAndDelete) or (Mode=zmAddAndDelete) or (Mode=zmDeleteOnly)) then Ok:=DeleteFiles;
  finally
    SetCurrentDir(SaveDir);
  end;

  If Ok then ModalResult:=mrOK else ModalResult:=mrCancel;
  PostMessage(Handle,WM_CLOSE,0,0);
end;

Function TZipInfoForm.ExternalWork(const Nr : Integer) : Boolean;
Var PrgName,Parameters,ParametersOrig,Mx,CmdLine : String;
    StartupInfo : TStartupInfo;
    ProcessInformation : TProcessInformation;
    I : Integer;
    ExitCode : DWORD;
    Bundled : Boolean;
begin
  result:=False;
  FProcessHandle:=0;

  PrgName:=PrgSetup.PackerSettings[Nr].ZipFileName;
  If not FileExists(PrgName) then begin
    MessageDlg(Format(LanguageSetup.MessageFileNotFound,[PrgName]),mtError,[mbOK],0);
    exit;
  end;

  Case Mode of
    zmExtract : Parameters:=PrgSetup.PackerSettings[Nr].ExtractFile;
    zmCreate, zmCreateAndDelete : Parameters:=PrgSetup.PackerSettings[Nr].CreateFile;
    zmAdd, zmAddAndDelete : Parameters:=PrgSetup.PackerSettings[Nr].UpdateFile;
  end;
  ParametersOrig:=Parameters;

  I:=Pos('%1',Parameters);
  If I=0 then begin
    MessageDlg(Format(LanguageSetup.ZipFormInvalidParameters,[ParametersOrig]),mtError,[mbOK],0);
    exit;
  end;
  Parameters:=Copy(Parameters,1,I-1)+ZipFile+Copy(Parameters,I+2,MaxInt);

  I:=Pos('%2',Parameters);
  If I=0 then begin
    MessageDlg(Format(LanguageSetup.ZipFormInvalidParameters,[ParametersOrig]),mtError,[mbOK],0);
    exit;
  end;
  If PrgSetup.PackerSettings[Nr].TrailingBackslash then begin
    Parameters:=Copy(Parameters,1,I-1)+IncludeTrailingPathDelimiter(Folder)+Copy(Parameters,I+2,MaxInt);
  end else begin
    Parameters:=Copy(Parameters,1,I-1)+ExcludeTrailingPathDelimiter(Folder)+Copy(Parameters,I+2,MaxInt);
  end;

  Bundled:=IsBundled7zaPath(PrgName);
  If Bundled and (Mode in [zmCreate, zmCreateAndDelete, zmAdd, zmAddAndDelete]) then begin
    Mx:='-mx='+IntToStr(CompressionLevelTo7zMx(PrgSetup.CompressionLevel));
    If Pos(Mx, Parameters)=0 then Parameters:=Parameters+' '+Mx;
  end;

  CancelButton.Enabled:=True;
  SetBusyInfo;
  ProgressBar.Style:=pbstMarquee;
  Application.ProcessMessages;

  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb:=SizeOf(StartupInfo);
  StartupInfo.dwFlags:=STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow:=SW_HIDE;

  { CreateProcessW may write into the command line buffer — must be unique/writable }
  CmdLine:='"'+PrgName+'" '+Parameters;
  UniqueString(CmdLine);

  If not CreateProcess(PChar(PrgName),PChar(CmdLine),nil,nil,False,CREATE_NO_WINDOW,nil,nil,StartupInfo,ProcessInformation) then begin
    MessageDlg(Format(LanguageSetup.MessageCouldNotStartProgram,[PrgName]),mtError,[mbOK],0);
    CancelButton.Enabled:=False;
    exit;
  end;

  FProcessHandle:=ProcessInformation.hProcess;
  CloseHandle(ProcessInformation.hThread);

  try
    While WaitForSingleObject(FProcessHandle,50)<>WAIT_OBJECT_0 do begin
      Application.ProcessMessages;
      ProgressBar.Repaint;
      If FProcessingCanceled then begin
        TerminateProcess(FProcessHandle,1);
        Break;
      end;
    end;

    If FProcessingCanceled then begin
      result:=False;
      exit;
    end;

    If not GetExitCodeProcess(FProcessHandle, ExitCode) then ExitCode:=1;
    If ExitCode=0 then begin
      result:=True;
    end else begin
      result:=False;
      If Mode=zmExtract
        then MessageDlg(LanguageSetup.ZipFormErrorExtract,mtError,[mbOK],0)
        else MessageDlg(LanguageSetup.ZipFormErrorCompress,mtError,[mbOK],0);
    end;
  finally
    CloseHandle(FProcessHandle);
    FProcessHandle:=0;
    CancelButton.Enabled:=False;
  end;
end;

Function TZipInfoForm.DeleteFolder(Folder : String; const ThisIsMainFolder : Boolean) : Boolean;
Var Rec : TSearchRec;
    I : Integer;
begin
  result:=False;
  Folder:=IncludeTrailingPathDelimiter(Folder);
  If length(Folder)=3 then exit;

  If not DirectoryExists(Folder) then begin result:=True; exit; end;

  If not BaseDirSecuriryCheck(Folder) then exit;

  I:=FindFirst(Folder+'*.*',faAnyFile,Rec);
  try
    while I=0 do begin
      If (Rec.Attr and faDirectory)<>0 then begin
        If (Rec.Name<>'.') and (Rec.Name<>'..') then begin
          if not DeleteFolder(Folder+Rec.Name,False) then exit;
        end;
      end else begin
        If not ExtDeleteFile(Folder+Rec.Name,ftZipOperation) then begin
          MessageDlg(Format(LanguageSetup.MessageCouldNotDeleteFile,[Folder+Rec.Name]),mtError,[mbOK],0);
          exit;
        end;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;

  If (not ThisIsMainFolder) or (FDeleteMode=dmFolder) or (FDeleteMode=dmFolderNoWarning) then begin
    if not ExtDeleteFolder(Folder,ftZipOperation) then begin
      MessageDlg(Format(LanguageSetup.MessageCouldNotDeleteDir,[Folder]),mtError,[mbOK],0);
      exit;
    end;
  end;

  result:=True;
end;

procedure TZipInfoForm.CancelButtonClick(Sender: TObject);
begin
  CancelButton.Enabled:=False;
  FProcessingCanceled:=true;
  If FProcessHandle<>0 then TerminateProcess(FProcessHandle,1);
end;

function TZipInfoForm.DeleteFiles: Boolean;
begin
  DeleteFolder(Folder,True);
  result:=True;
end;

{ global }

Function ZipDialogWork(const AOwner : TComponent; const AZipFile, ADestFolder : String; const AZipMode : TZipMode; const ADeleteMode : TDeleteMode) : Boolean;
begin
  result:=False;
  ZipInfoForm:=TZipInfoForm.Create(AOwner);
  try
    ZipInfoForm.DeleteMode:=ADeleteMode;
    if not ZipInfoForm.Init(AZipMode,AZipFile,ADestFolder) then exit;
    result:=(ZipInfoForm.ShowModal=mrOK);
  finally
    ZipInfoForm.Free;
  end;
end;

Function ExtractZipFile(const AOwner : TComponent; const AZipFile, ADestFolder : String) : Boolean;
begin
  result:=ZipDialogWork(AOwner,AZipFile,ADestFolder,zmExtract,dmNo);
end;

Function CreateZipFile(const AOwner : TComponent; const AZipFile, ADestFolder : String; const DeleteMode : TDeleteMode) : Boolean;
begin
  If (DeleteMode<>dmNo) and (DeleteMode<>dmNoNoWarning)
    then result:=ZipDialogWork(AOwner,AZipFile,ADestFolder,zmCreateAndDelete,DeleteMode)
    else result:=ZipDialogWork(AOwner,AZipFile,ADestFolder,zmCreate,DeleteMode);
end;

Function AddToZipFile(const AOwner : TComponent; const AZipFile, ADestFolder : String; const DeleteMode : TDeleteMode) : Boolean;
begin
  If (DeleteMode<>dmNo) and (DeleteMode<>dmNoNoWarning)
    then result:=ZipDialogWork(AOwner,AZipFile,ADestFolder,zmAddAndDelete,DeleteMode)
    else result:=ZipDialogWork(AOwner,AZipFile,ADestFolder,zmAdd,DeleteMode);
end;

Function DeleteUnpackedFiles(const AOwner : TComponent; const ADestFolder : String; const DeleteMode : TDeleteMode = dmNo) : Boolean;
begin
  If (DeleteMode=dmNo) or (DeleteMode=dmNoNoWarning) then begin result:=True; exit; end;
  result:=ZipDialogWork(AOwner,'',ADestFolder,zmDeleteOnly,DeleteMode);
end;

Function ExtractZipDrive(const AOwner : TComponent; const AZipFile, AZipAddFolder, ADestFolder : String) : Boolean;
begin
  If AZipAddFolder=ADestFolder then begin
    {DestFolder->TempFolder}
    result:=ExtDeleteFolder(TempDir+ZipTempDir,ftTemp); if not result then exit;
    ForceDirectories(TempDir+ZipTempDir);
    try
      CopyFiles(ADestFolder,TempDir+ZipTempDir,True,True);
      {ZipFile+TempFolder -> DestFolder}
      result:=ExtractZipFile(AOwner,AZipFile,ADestFolder); if not result then exit;
      result:=CopyFiles(TempDir+ZipTempDir,ADestFolder,True,True);
    finally
      {Delete TempFolder}
      ExtDeleteFolder(TempDir+ZipTempDir,ftTemp);
    end;
  end else begin
    {ZipFile+ZipAddFolder -> DestFolder}
    result:=ExtractZipFile(AOwner,AZipFile,ADestFolder);
    if not result then exit;
    result:=CopyFiles(AZipAddFolder,ADestFolder,True,True);
  end;
end;

end.
