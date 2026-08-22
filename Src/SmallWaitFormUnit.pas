unit SmallWaitFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TSmallWaitForm = class(TForm)
    Label1: TLabel;
    SpinnerLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FInfoText : String;
    FSpinIndex : Integer;
    FSpinTimer : TTimer;
    procedure SpinTimerTimer(Sender: TObject);
    procedure UpdateSpinnerCaption;
  public
  end;

var
  SmallWaitForm: TSmallWaitForm = nil;

Procedure LoadAndShowSmallWaitForm(Info : String =''; const LabelText : String = '');
Procedure FreeSmallWaitForm;
Function RunWorkWithSmallWaitForm(const Info : String; const Work : TProc) : Boolean; overload;
Function RunWorkWithSmallWaitForm(const Info, LabelText : String; const Work : TProc) : Boolean; overload;

implementation

uses VistaToolsUnit, CommonHelpers, CommonTools, LanguageSetupUnit;

{$R *.dfm}

procedure TSmallWaitForm.FormCreate(Sender: TObject);
begin
  DoubleBuffered:=True;
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);
  FSpinIndex:=0;
  FInfoText:='';
  FSpinTimer:=TTimer.Create(Self);
  FSpinTimer.Interval:=333;
  FSpinTimer.OnTimer:=SpinTimerTimer;
  FSpinTimer.Enabled:=False;
  SpinnerLabel.Visible:=False;
end;

procedure TSmallWaitForm.FormDestroy(Sender: TObject);
begin
  If Assigned(FSpinTimer) then FSpinTimer.Enabled:=False;
end;

procedure TSmallWaitForm.UpdateSpinnerCaption;
begin
  Label1.Caption:=FInfoText+StringOfChar('.',FSpinIndex+1);
end;

procedure TSmallWaitForm.SpinTimerTimer(Sender: TObject);
begin
  FSpinIndex:=(FSpinIndex+1) mod 4;
  UpdateSpinnerCaption;
end;

Procedure LoadAndShowSmallWaitForm(Info : String; const LabelText : String);
Var LabelBase : String;
begin
  If Application.MainForm.WindowState=wsMinimized then exit;
  SmallWaitForm:=TSmallWaitForm.Create(Application.MainForm);
  If Trim(Info)='' then Info:=LanguageSetup.ProgressFormCaption;
  If Trim(LabelText)<>'' then LabelBase:=LabelText else LabelBase:=Info;
  While (LabelBase<>'') and (LabelBase[Length(LabelBase)]='.') do
    SetLength(LabelBase,Length(LabelBase)-1);
  SmallWaitForm.Caption:=Info;
  SmallWaitForm.FInfoText:=LabelBase;
  SmallWaitForm.FSpinIndex:=0;
  SmallWaitForm.UpdateSpinnerCaption;
  SmallWaitForm.FSpinTimer.Enabled:=True;
  SmallWaitForm.Show;
  SmallWaitForm.BringToFront;
  Application.ProcessMessages;
  SmallWaitForm.Repaint;
end;

Procedure FreeSmallWaitForm;
begin
  If Assigned(SmallWaitForm) then begin
    If Assigned(SmallWaitForm.FSpinTimer) then SmallWaitForm.FSpinTimer.Enabled:=False;
    FreeAndNil(SmallWaitForm);
  end;
end;

Function RunWorkWithSmallWaitForm(const Info : String; const Work : TProc) : Boolean;
begin
  result:=RunWorkWithSmallWaitForm(Info,'',Work);
end;

Function RunWorkWithSmallWaitForm(const Info, LabelText : String; const Work : TProc) : Boolean;
Var Th : TThread;
    HasError : Boolean;
    ErrorMessage : String;
begin
  result:=False;
  If not Assigned(Work) then exit;

  HasError:=False;
  ErrorMessage:='';
  LoadAndShowSmallWaitForm(Info,LabelText);
  try
    Th:=TThread.CreateAnonymousThread(
      procedure
      begin
        try
          Work();
        except
          on E: Exception do begin
            HasError:=True;
            ErrorMessage:=E.ClassName+': '+E.Message;
          end;
          else begin
            HasError:=True;
            ErrorMessage:='Unknown exception object thrown.';
          end;
        end;
      end
    );
    Th.FreeOnTerminate:=False;
    Th.Start;
    try
      While not Th.Finished do begin
        Application.ProcessMessages;
        Sleep(20);
      end;
      Th.WaitFor;
    finally
      Th.Free;
    end;
  finally
    FreeSmallWaitForm;
  end;

  If HasError then
    raise Exception.Create(ErrorMessage);

  result:=True;
end;

end.
