unit ProcThreadUnit;

interface

uses Classes, SysUtils, ActiveX;

type
  TProcThread = class(TThread)
  private
    FProc : TProc;
    FFunc : TFunc<Integer>;
    FResultCount : Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AWork : TProc); overload;
    constructor Create(const AWork : TFunc<Integer>); overload;
    property ResultCount : Integer read FResultCount write FResultCount;
  end;

implementation

constructor TProcThread.Create(const AWork : TProc);
begin
  FProc := AWork;
  FFunc := nil;
  FResultCount := 0;
  FreeOnTerminate := False;
  inherited Create(False);
end;

constructor TProcThread.Create(const AWork : TFunc<Integer>);
begin
  FProc := nil;
  FFunc := AWork;
  FResultCount := 0;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TProcThread.Execute;
begin
  CoInitialize(nil);
  try
    if Assigned(FFunc) then
      FResultCount := FFunc()
    else if Assigned(FProc) then
      FProc();
  finally
    CoUninitialize;
  end;
end;

end.
