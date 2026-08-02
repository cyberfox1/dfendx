unit ToggleSwitchExUnit;

interface

uses
  Classes, Types, Controls, WinXCtrls, Messages, Windows;

type
  { Interposer for TToggleSwitch: only the switch glyph toggles on click, not the
    caption text. Caption accelerators (e.g. Autop&lay) still toggle via Alt.
    Named TToggleSwitch so DFM streaming uses the stock class name (designer
    finds it); compile/runtime use this unit's interposer when it is in uses. }
  TToggleSwitch = class(WinXCtrls.TToggleSwitch)
  protected
    function SwitchClientRect: TRect;
    function PointInSwitch(const X, Y: Integer): Boolean;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
  end;

implementation

uses
  SysUtils, Forms; { IsAccel }

function TToggleSwitch.SwitchClientRect: TRect;
var
  X, Y: Integer;
begin
  { Match VCL paint path (GetGlyphPosition), not a hard-coded Alignment guess. }
  GetGlyphPosition(X, Y);
  Result := Bounds(X, Y, SwitchWidth, SwitchHeight);
end;

function TToggleSwitch.PointInSwitch(const X, Y: Integer): Boolean;
begin
  Result := PtInRect(SwitchClientRect, Point(X, Y));
end;

procedure TToggleSwitch.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  { Base class sets FUsingMouse on any left-down; MouseUp then ChangeState if
    the up is still inside the full control. Skip inherited when the click is
    on the caption so caption clicks do nothing. }
  if (Button = mbLeft) and not PointInSwitch(X, Y) then
    Exit;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TToggleSwitch.CMDialogChar(var Message: TCMDialogChar);
var
  AccelMatch: Boolean;
  NewState: TToggleSwitchState;
begin
  AccelMatch := IsAccel(Message.CharCode, StateCaptions.CaptionOn)
    or IsAccel(Message.CharCode, StateCaptions.CaptionOff);
  if Enabled and Visible and Showing and AccelMatch then
  begin
    if Self.State = tssOn then
      NewState := tssOff
    else
      NewState := tssOn;
    Self.State := NewState;
    Click;
    Message.Result := 1;
  end
  else
    inherited;
end;

end.
