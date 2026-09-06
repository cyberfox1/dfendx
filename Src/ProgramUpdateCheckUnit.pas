unit ProgramUpdateCheckUnit;
interface

uses Classes;

Type TUpdateResult=(urNoUpdatesAvailable, urUpdateAvailable, urUpdateInstalled, urUpdateInstallCanceled);

Function ParseGitHubReleaseTagName(const Body : String) : String;
Function NormalizeReleaseTag(const Tag : String) : String;
Function RunUpdateCheck(const AOwner : TComponent; const Quiet, QuietOnError : Boolean; const AlwaysNotify : Boolean = False) : TUpdateResult;
Procedure RunUpdateCheckIfSetup(const AOwner : TComponent);
Procedure RunUpdateCheckIdleCloseHandle;
Procedure RunExternalUpdateCheck(const Quiet : Boolean);

implementation

uses Windows, SysUtils, Dialogs, Forms, Controls, ShellAPI, PrgSetupUnit,
     CommonHelpers, CommonTools, HTTPDownloadHelpers, LanguageSetupUnit, PrgConsts, MainUnit,
     UpdateAvailableFormUnit, System.JSON;

var UpdaterProcessHandleProcess : THandle = INVALID_HANDLE_VALUE;

Procedure RunExternalUpdateCheck(const Quiet : Boolean);
Var St : TStringList;
    FileName,Prg : String;
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
    St.Add(PrgSetup.UpdateCheckURL);
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

Function ParseGitHubReleaseTagName(const Body : String) : String;
Var Root : TJSONValue;
    Obj : TJSONObject;
    V : TJSONValue;
begin
  result:='';
  Root:=TJSONObject.ParseJSONValue(Body);
  If Root=nil then exit;
  try
    If not (Root is TJSONObject) then exit;
    Obj:=TJSONObject(Root);
    V:=Obj.Values['tag_name'];
    If Assigned(V) then result:=V.Value;
  finally
    Root.Free;
  end;
end;

Function NormalizeReleaseTag(const Tag : String) : String;
begin
  result:=Trim(Tag);
  If (Length(result)>=2) and ((result[1]='v') or (result[1]='V')) and (result[2] in ['0'..'9']) then Delete(result,1,1);
end;

Function RunUpdateCheck(const AOwner : TComponent; const Quiet, QuietOnError : Boolean; const AlwaysNotify : Boolean = False) : TUpdateResult;
Var URL,Body,Tag,Remote,Local : String;
    Status : Integer;
    OK : Boolean;
begin
  result:=urUpdateInstallCanceled;
  URL:='https://api.github.com/repos/'+GitHubUpdateOwner+'/'+GitHubUpdateRepo+'/releases/latest';
  OK:=THTTPDownloadHelper.HTTPRequestToString('GET',URL,nil,PrgSetup.HTTPUserAgent,'',30000,30000,Body,Status);
  If (not OK) or (not THTTPDownloadHelper.HTTPStatusOK(Status)) then begin
    If not QuietOnError then MessageDlg(Format(LanguageSetup.PackageManagerDownloadFailed,[URL]),mtError,[mbOK],0);
    exit;
  end;

  Tag:=ParseGitHubReleaseTagName(Body);
  If Tag='' then begin
    result:=urNoUpdatesAvailable;
    If not Quiet then MessageDlg(LanguageSetup.UpdateNoUpdates,mtInformation,[mbOK],0);
    exit;
  end;

  PrgSetup.LastUpdateCheck:=Round(Int(Date));
  Remote:=NormalizeReleaseTag(Tag);
  Local:=GetNormalFileVersionAsString;
  If VersionToInt(Remote)>VersionToInt(Local) then begin
    result:=urUpdateAvailable;
    If AlwaysNotify or (VersionToInt(Remote)>VersionToInt(PrgSetup.LastNotifiedUpdateVersion)) then begin
      URL:='https://github.com/'+GitHubUpdateOwner+'/'+GitHubUpdateRepo+'/releases/tag/'+Tag;
      ShowUpdateAvailableDialog(AOwner,Remote,Local,URL);
      PrgSetup.LastNotifiedUpdateVersion:=Remote;
    end;
  end else begin
    result:=urNoUpdatesAvailable;
    If not Quiet then MessageDlg(LanguageSetup.UpdateNoUpdates,mtInformation,[mbOK],0);
  end;
end;

Procedure RunUpdateCheckIfSetup(const AOwner : TComponent);
begin
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
