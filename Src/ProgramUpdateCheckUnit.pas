unit ProgramUpdateCheckUnit;
interface

uses Classes;

Type TUpdateResult=(urNoUpdatesAvailable, urUpdateAvailable, urUpdateInstalled, urUpdateInstallCanceled);

Function RunUpdateCheck(const AOwner : TComponent; const Quiet, QuietOnError : Boolean) : TUpdateResult;
Procedure RunUpdateCheckIfSetup(const AOwner : TComponent);
Procedure RunUpdateCheckIdleCloseHandle;
Procedure RunExternalUpdateCheck(const Quiet : Boolean);

implementation

uses Windows, SysUtils, Dialogs, Forms, Controls, ShellAPI, PrgSetupUnit,
     CommonHelpers, CommonTools, DownloadWaitFormUnit, LanguageSetupUnit, PrgConsts, MainUnit;

var UpdaterProcessHandleProcess : THandle = INVALID_HANDLE_VALUE;

Procedure RunExternalUpdateCheck(const Quiet : Boolean);
Var St : TStringList;
    FileName,Add,Prg : String;
    StartupInfo : TStartupInfo;
    ProcessInformation : TProcessInformation;
begin
  { Updates disabled for now — keep function for later re-enable. }
  exit;

  If (UpdaterProcessHandleProcess<>INVALID_HANDLE_VALUE) and (WaitForSingleObject(UpdaterProcessHandleProcess,0)=WAIT_OBJECT_0) then begin
    CloseHandle(UpdaterProcessHandleProcess); UpdaterProcessHandleProcess:=INVALID_HANDLE_VALUE;
  end;
  If UpdaterProcessHandleProcess<>INVALID_HANDLE_VALUE then begin
    MessageDlg(LanguageSetup.UpdateSingleInstanceMessage,mtError,[mbOK],0);
    exit;
  end;

  FileName:=TempDir+'UpdateCheckSetup.txt';

  St:=TStringList.Create;
  try
    St.Add(GetNormalFileVersionAsString);
    If PrgSetup.VersionSpecificUpdateCheck then Add:='?Version='+GetNormalFileVersionAsString else Add:='';
    St.Add(PrgSetup.UpdateCheckURL+Add);
    St.Add('DFendXUpdate.exe');
    St.Add(PrgDir);
    If Quiet then St.Add('silent') else St.Add('normal');
    St.Add(LanguageSetup.UpdateCannotFindFile);
    St.Add(LanguageSetup.UpdateDownloadFailed);
    St.Add(LanguageSetup.UpdateDownloadFailedBeforeURL);
    St.Add(LanguageSetup.UpdateDownloadFailedAfterURL);
    St.Add(LanguageSetup.UpdateURL);
    St.Add(LanguageSetup.UpdateDownloading);
    St.Add(LanguageSetup.UpdateConnecting);
    St.Add(LanguageSetup.UpdateFileName);
    St.Add(LanguageSetup.UpdateTransfered);
    St.Add(LanguageSetup.UpdateFileSize);
    St.Add(LanguageSetup.UpdateRamainingTime);
    St.Add(LanguageSetup.UpdateTotalTime);
    St.Add(LanguageSetup.UpdateCannotReadFile);
    St.Add(LanguageSetup.UpdateNoUpdates);
    St.Add(LanguageSetup.UpdateNewVersionPart1);
    St.Add(LanguageSetup.UpdateNewVersionPart2);
    St.Add(LanguageSetup.OK);
    St.Add(LanguageSetup.Yes);
    St.Add(LanguageSetup.No);

    St.SaveToFile(FileName);
  finally
    St.Free;
  end;

  Prg:='';
  If FileExists(PrgDir+'UpdateCheck.exe') then Prg:=PrgDir+'UpdateCheck.exe' else begin
    If FileExists(PrgDir+BinFolder+'\'+'UpdateCheck.exe') then Prg:=PrgDir+BinFolder+'\'+'UpdateCheck.exe';
  end;
  If Prg='' then begin
    If Quiet then exit;
    ShellExecute(Application.Handle,'open',PChar(LanguageSetup.MenuHelpUpdatesURL),nil,nil,SW_SHOW);
    MessageDlg(Format(LanguageSetup.MessageFileNotFound,[PrgDir+BinFolder+'\'+'UpdateCheck.exe']),mtError,[mbOK],0);
    exit;
  end;

  FillChar(StartupInfo,SizeOf(StartupInfo),0);
  StartupInfo.cb:=SizeOf(StartupInfo);
  If CreateProcess(PChar(Prg),PChar('"'+Prg+'" '+FileName),nil,nil,False,0,nil,PChar(PrgDir),StartupInfo,ProcessInformation) then begin
    UpdaterProcessHandleProcess:=ProcessInformation.hProcess;
    CloseHandle(ProcessInformation.hThread);
    If DFendReloadedMainForm.DeleteOnExit.IndexOf(FileName)<0 then DFendReloadedMainForm.DeleteOnExit.Add(FileName);
    PrgSetup.LastUpdateCheck:=Round(Int(Date));
  end;
end;

Function RunUpdateCheck(const AOwner : TComponent; const Quiet, QuietOnError : Boolean) : TUpdateResult;
Var URL, FileName : String;
    St : TStringList;
    B : Boolean;
begin
  { Updates disabled for now — silent success. }
  result:=urNoUpdatesAvailable;
  exit;

  result:=urUpdateInstallCanceled;

  FileName:=TempDir+'UpdateCheckSetup.txt';
  URL:=PrgSetup.UpdateCheckURL; If PrgSetup.VersionSpecificUpdateCheck then URL:=URL+'?Version='+GetNormalFileVersionAsString;

  If Quiet then begin
    B:=(DownloadFileWithOutDialog(AOwner,-1,'',URL,'',FileName)=drSuccess);
  end else begin
    B:=(DownloadFileWithDialog(AOwner,-1,'',URL,'',FileName)=drSuccess);
  end;

  If not B then begin
    If not QuietOnError then MessageDlg(Format(LanguageSetup.PackageManagerDownloadFailed,[URL]),mtError,[mbOK],0);
    exit;
  end;

  St:=TStringList.Create;
  try
    PrgSetup.LastUpdateCheck:=Round(Int(Date));

    try
      St.LoadFromFile(FileName);
      ExtDeleteFile(FileName,ftTemp);
    except
      MessageDlg(Format(LanguageSetup.MessageCouldNotOpenFile,[FileName]),mtError,[mbOK],0); exit;
    end;

    If (St.Count>1) and (VersionToInt(St[0])>VersionToInt(GetNormalFileVersionAsString)) then begin
      result:=urUpdateAvailable;
      RunExternalUpdateCheck(Quiet);
    end else begin
      result:=urNoUpdatesAvailable;
      If Quiet then exit;
      MessageDlg(LanguageSetup.UpdateNoUpdates,mtInformation,[mbOK],0);
    end;
  finally
    St.Free;
  end;
end;

Procedure RunUpdateCheckIfSetup(const AOwner : TComponent);
begin
  { Updates disabled for now — scheduled checks do not run. }
  exit;

  Case PrgSetup.CheckForUpdates of
    0 : {Do not check automatically};
    1 : If Round(Int(Date))>=PrgSetup.LastUpdateCheck+7 then RunUpdateCheck(AOwner,True,True);
    2 : If Round(Int(Date))>=PrgSetup.LastUpdateCheck+1 then RunUpdateCheck(AOwner,True,True);
    3 : RunUpdateCheck(AOwner,True,True);
  end;
end;

Procedure RunUpdateCheckIdleCloseHandle;
begin
  If (UpdaterProcessHandleProcess<>INVALID_HANDLE_VALUE) and (WaitForSingleObject(UpdaterProcessHandleProcess,0)=WAIT_OBJECT_0) then begin
    CloseHandle(UpdaterProcessHandleProcess); UpdaterProcessHandleProcess:=INVALID_HANDLE_VALUE;
  end;
end;

initialization
finalization
  If UpdaterProcessHandleProcess<>INVALID_HANDLE_VALUE then CloseHandle(UpdaterProcessHandleProcess);
end.
