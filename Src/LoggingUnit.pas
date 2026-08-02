unit LoggingUnit;
interface

Procedure LogInfo(const Info : String; const ContinueLogging : Boolean = True);

implementation

uses SysUtils, ShlObj, CommonTools, SyncObjs;

var StartupLogFile : String ='';
    LogLock : TCriticalSection;

Procedure LogInfo(const Info : String; const ContinueLogging : Boolean);
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
    If not ContinueLogging then StartupLogFile:='';
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

finalization
  LogLock.Free;
end.
