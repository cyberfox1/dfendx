unit SingleInstanceUnit;
interface

Function InstanceRunning(var hEvent : THandle) : Boolean;

implementation

uses Windows;

Function InstanceRunning(var hEvent : THandle) : Boolean;
const EventName='DFX-running';
begin
  result:=False;
  hEvent:=CreateFileMapping(INVALID_HANDLE_VALUE,nil,PAGE_READONLY,0,1,EventName);
  if hEvent=0 then Exit;
  if GetLastError=ERROR_ALREADY_EXISTS then begin
    CloseHandle(hEvent);
    hEvent:=0;
    result:=True;
  end;
end;

end.
