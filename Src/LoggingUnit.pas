unit LoggingUnit;
interface

uses PrgConsts;

{ Default llInfo so startup logs run until SetLogLevel(llOff). }
var CurrentLogLevel : TLogLevel = llInfo;

{ Inline gate only — body must be a separate interface symbol or dcc32 E2441
  (inline in interface cannot touch LogLock / SysUtils / etc.). }
Procedure LogInfo(const Info : String); inline;
Procedure LogInfoWrite(const Info : String);
Procedure SetLogLevel(const Level : TLogLevel); overload;
Procedure SetLogLevel(const Level : String); overload;
Function GetLogLevel : TLogLevel;

implementation

uses SysUtils, ShlObj, CommonTools, CommonHelpers, SyncObjs, PrgSetupUnit;

var StartupLogFile : String ='';
    LogLock : TCriticalSection;

Procedure SetLogLevel(const Level : TLogLevel);
begin
  CurrentLogLevel:=Level;
end;

Procedure SetLogLevel(const Level : String);
Var S : String;
begin
  S:=ExtUpperCase(Trim(Level));
  If S=LogLevelInfo then SetLogLevel(llInfo)
  else If S=LogLevelWarning then SetLogLevel(llWarning)
  else If S=LogLevelCritical then SetLogLevel(llCritical)
  else SetLogLevel(llOff);
end;

Function GetLogLevel : TLogLevel;
begin
  result:=CurrentLogLevel;
end;

Procedure LogInfo(const Info : String);
begin
  If CurrentLogLevel=llOff then exit;
  LogInfoWrite(Info);
end;

Procedure LogInfoWrite(const Info : String);
Var F : TextFile;
begin
  LogLock.Enter;
  try
    If StartupLogFile='' then exit;
    If not FileExists(StartupLogFile) then exit;

    try
      AssignFile(F,StartupLogFile);
      Append(F);
      try
        Writeln(F,TimeToStr(Now)+' '+Info);
      finally
        CloseFile(F);
      end;
    except
      try
        WriteLn(TimeToStr(Now)+' '+Info);
      except
      end;
      WriteLn(ErrOutput, '!!! CRITICAL LOGGING ERROR !!!');
    end;
  finally
    LogLock.Leave;
  end;
end;

initialization
  LogLock:=TCriticalSection.Create;
  StartupLogFile:=GetEnvironmentVariable('TEMP');
  if StartupLogFile='' then
    StartupLogFile:=GetSpecialFolder(0, CSIDL_DESKTOPDIRECTORY);
  StartupLogFile:=IncludeTrailingPathDelimiter(StartupLogFile)+'DFendX-Log.txt';
  if not FileExists(StartupLogFile) then begin
    try FileClose(FileCreate(StartupLogFile)); except
      WriteLn(ErrOutput, 'Could not create log file: '+StartupLogFile);
      StartupLogFile:='';
    end;
  end;
  { PrgSetupUnit inits first (uses dependency); apply [ProgramSets] LogLevel. }
  SetLogLevel(PrgSetup.LogLevel);

finalization
  LogLock.Free;
end.
