unit HiddenWaitFormUnit;

interface

uses
  Windows, Classes, Controls, Forms, ExtCtrls, StdCtrls;

type
  THiddenWaitDialog = class(TForm)
  private
    FThread1 : TThread;
    FThread2 : TThread;
    FSpinnerLabel : TLabel;
    FTimer : TTimer;
    FTimerCounter : Integer;
    procedure TimerOnTimer(Sender : TObject);
    procedure FormShow(Sender : TObject);
  public
    constructor Create(AOwner : TComponent; AThread1 : TThread; AThread2 : TThread; ASpinner : TLabel); reintroduce;
    destructor Destroy; override;
  end;

implementation

const
  SpinnerChars : array[0..9] of String = (
    #$280B, #$2819, #$2839, #$2838, #$283C, #$2834, #$2826, #$2827, #$2807, #$280F
  );

constructor THiddenWaitDialog.Create(AOwner : TComponent; AThread1 : TThread; AThread2 : TThread; ASpinner : TLabel);
begin
  inherited CreateNew(AOwner);
  FThread1 := AThread1;
  FThread2 := AThread2;
  FSpinnerLabel := ASpinner;
  FTimerCounter := 0;
  BorderStyle := bsNone;
  Left := -100;
  Top := -100;
  Width := 1;
  Height := 1;
  AlphaBlend := True;
  AlphaBlendValue := 1;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 50;
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerOnTimer;
  OnShow := FormShow;
end;

destructor THiddenWaitDialog.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure THiddenWaitDialog.FormShow(Sender : TObject);
begin
  if FSpinnerLabel <> nil then
    FSpinnerLabel.Caption := SpinnerChars[0];
  FTimer.Enabled := True;
end;

procedure THiddenWaitDialog.TimerOnTimer(Sender : TObject);
var
  T1Done, T2Done : Boolean;
begin
  FTimer.Enabled := False;

  if FThread1 = nil then
    T1Done := True
  else
    T1Done := WaitForSingleObject(FThread1.Handle, 0) = WAIT_OBJECT_0;

  if FThread2 = nil then
    T2Done := True
  else
    T2Done := WaitForSingleObject(FThread2.Handle, 0) = WAIT_OBJECT_0;

  if not (T1Done and T2Done) then begin
    Inc(FTimerCounter);
    if FSpinnerLabel <> nil then
      FSpinnerLabel.Caption := SpinnerChars[FTimerCounter mod 10];
    FTimer.Enabled := True;
    Exit;
  end;

  Close;
end;

end.
