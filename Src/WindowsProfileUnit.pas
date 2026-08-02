unit WindowsProfileUnit;
interface

uses GameDBUnit;

Procedure RunWindowsGame(const Game : TGame; const RunSetup : Boolean = False);
Procedure RunWindowssExtraFile(const Game : TGame; Nr : Integer);

Var MinimizedAtWindowsGameStart : Boolean = False;
    MinimizedAtWindowsGameStartTime : TDateTime;

implementation

uses Windows, SysUtils, Dialogs, Forms, ShellAPI, LanguageSetupUnit,
     CommonHelpers, CommonTools, PrgSetupUnit, GameDBToolsUnit, DOSBoxUnit, DOSBoxUnitHelpers, RunPrgManagerUnit,
     DOSBoxCountUnit, HistoryUnit, PrgConsts, LoggingUnit, BassMedia;


Function RunFile2(const FileName, Parameters: String; const asAdmin : Boolean): THandle;
var ShellExecInfo: SHELLEXECUTEINFO;
    S : String;
begin
  if asAdmin then begin
    result:=INVALID_HANDLE_VALUE;
    S:=IncludeTrailingPathDelimiter((ExtractFilePath(FileName)));
    ShellExecute(
      Application.MainForm.Handle,
      'open',
      PChar(PrgDir+BinFolder+'\AdminLauncher.exe'),
      PChar('/dir='+S+' /run="'+FileName+'" '+Parameters),
      PChar(S),
      SW_SHOW
    );
    exit;
  end;

    FillChar(ShellExecInfo, SizeOf(ShellExecInfo), 0);
    with ShellExecInfo do begin
        cbSize := SizeOf(ShellExecInfo);
        fMask := SEE_MASK_NOCLOSEPROCESS;
        Wnd := Application.MainForm.Handle;
        lpVerb := 'open';
        lpFile := PChar(FileName);
        lpParameters := PChar(Parameters);
        lpDirectory := PChar(IncludeTrailingPathDelimiter((ExtractFilePath(FileName))));
        nShow := SW_SHOW;
    end;

    if ShellExecuteEx(@ShellExecInfo) then begin
        Result := ShellExecInfo.hProcess;
    end else begin
        Application.Restore;
        MessageDlg(Format(LanguageSetup.MessageCouldNotStartProgram,[FileName]),mtError,[mbOK],0);
        Result := INVALID_HANDLE_VALUE;
        exit;
    end;

  If PrgSetup.MinimizeOnWindowsGameStart then begin
    Sleep(1000);
    {MinimizedAtWindowsGameStart:=True; -> RunWindowsGame/RunWindowssExtraFile}
  end;

  WindowsGameCounter.Add(result);
end;


Function WindowsRunCheck(var FileName : String) : Boolean;
begin
  result:=False;

  If FileName='' then begin
    Application.Restore;
    MessageDlg(LanguageSetup.MessageNoFileName,mtError,[mbOK],0);
    exit;
  end;
  FileName:=MakeAbsPath(FileName,PrgSetup.BaseDir);

  If not FileExists(FileName) then begin
    Application.Restore;
    MessageDlg(Format(LanguageSetup.MessageFileNotFound,[FileName]),mtError,[mbOK],0);
    exit;
  end;

  If IsDOSExe(FileName) then begin
    Application.Restore;
    MessageDlg(Format(LanguageSetup.MessageDOSExeExecuteWarning,[FileName]),mtError,[mbOK],0);
  end;

  result:=True;
end;

Procedure RunWindowsGame(const Game : TGame; const RunSetup : Boolean);
Var S,T : String;
    Handle : THandle;
    AlreadyMinimized : Boolean;
begin
  AlreadyMinimized:=False;

  If RunSetup then begin
    S:=Trim(Game.SetupExe);
    T:=Game.SetupParameters;
  end else begin
    S:=Trim(Game.GameExe);
    T:=Game.GameParameters;
  end;

  If not WindowsRunCheck(S) then exit;
  if not RunCheck(Game,RunSetup) then exit;
  History.Add(Game.Name);

  try
    RunPrgManager.RunBeforeExecutionCommand(Game);

    If PrgSetup.MinimizeOnWindowsGameStart then begin
      AlreadyMinimized:=(Application.MainForm.WindowState=wsMinimized);
      Application.Minimize;
    end;

    PauseAmbientSoundtrack;
    Handle:=RunFile2(S,T,Game.RunAsAdmin and PrgSetup.OfferRunAsAdmin);
    try
      RunPrgManager.AddCommand(Game,Handle);
    finally
      if Handle <> INVALID_HANDLE_VALUE then CloseHandle(Handle);
    end;
  finally
    If PrgSetup.MinimizeOnWindowsGameStart and (not AlreadyMinimized) then begin
      MinimizedAtWindowsGameStart:=True;
      MinimizedAtWindowsGameStartTime:=Now;
    end;
  end;
end;

Procedure RunWindowssExtraFile(const Game : TGame; Nr : Integer);
Var S,T : String;
    I : Integer;
    Handle : THandle;
    AlreadyMinimized : Boolean;
begin
  try
    if (Nr < 0) or (Nr > 49) then
      raise Exception.CreateFmt('RunWindowssExtraFile: Index %d out of range [0..49]', [Nr]);

    AlreadyMinimized:=False;

    S:=Trim(Game.ExtraPrgFile[Nr]); I:=Pos(';',S);
    If (S='') or (I=0) then begin
      S:=Trim(Game.GameExe); T:=Game.GameParameters;
    end else begin
      S:=Copy(S,I+1,MaxInt);
      T:=Game.ExtraPrgFileParameter[Nr];
    end;

    If not WindowsRunCheck(S) then exit;
    if not RunCheck(Game,False,Nr) then exit;
    History.Add(Game.Name);

    try
      RunPrgManager.RunBeforeExecutionCommand(Game);

      If PrgSetup.MinimizeOnWindowsGameStart then begin
        AlreadyMinimized:=(Application.MainForm.WindowState=wsMinimized);
        Application.Minimize;
      end;

      PauseAmbientSoundtrack;
      Handle:=RunFile2(S,T,Game.RunAsAdmin and PrgSetup.OfferRunAsAdmin);
      try
        RunPrgManager.AddCommand(Game,Handle);
      finally
        if Handle <> INVALID_HANDLE_VALUE then CloseHandle(Handle);
      end;
    finally
      If PrgSetup.MinimizeOnWindowsGameStart and (not AlreadyMinimized) then begin
        MinimizedAtWindowsGameStart:=True;
        MinimizedAtWindowsGameStartTime:=Now;
      end;
    end;
  except
    on E: Exception do LogInfo('WindowsProfileUnit.RunWindowssExtraFile: ' + E.Message);
  end;
end;

end.
