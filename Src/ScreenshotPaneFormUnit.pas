unit ScreenshotPaneFormUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls;

const
  { Design-time starting list/content sizes from MainUnit.dfm — fixed, not measured at runtime. }
  ScreenshotPaneFixedWidth = 602;
  ScreenshotPaneFixedHeight = 669;

type
  TScreenshotPaneForm = class(TForm)
    Image: TImage;
    procedure FormCreate(Sender: TObject);
  private
    FOwnerMain: TWinControl;
    FOwnerBound: Boolean;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { Call once after Create: sets Windows owner HWND via CreateParams/PopupParent. }
    procedure BindOwnerWindow(const Main: TWinControl);
    procedure PositionBeside(const Main: TForm; const AlignTopScreen: Integer);
    procedure SetBitmap(const B: TBitmap);
    procedure ClearImage;
  end;

implementation

{$R *.dfm}

procedure TScreenshotPaneForm.FormCreate(Sender: TObject);
begin
  BorderStyle := bsNone;
  BorderIcons := [];
  FormStyle := fsNormal;
  ShowInTaskbar := False;
  Color := clBtnFace;
  ClientWidth := ScreenshotPaneFixedWidth;
  ClientHeight := ScreenshotPaneFixedHeight;
  Image.Align := alClient;
  Image.Center := True;
  Image.Stretch := False;
  Image.Proportional := False;
  FOwnerBound := False;
  FOwnerMain := nil;
end;

procedure TScreenshotPaneForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  { Owned popup: no taskbar button, owner HWND for Z-order grouping. }
  Params.ExStyle := (Params.ExStyle and not WS_EX_APPWINDOW) or WS_EX_TOOLWINDOW;
  if (FOwnerMain <> nil) and FOwnerMain.HandleAllocated then
    Params.WndParent := FOwnerMain.Handle
  else if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := TWinControl(Owner).Handle;
end;

procedure TScreenshotPaneForm.BindOwnerWindow(const Main: TWinControl);
begin
  if Main = nil then Exit;
  { Bind once — recreating the HWND on every activate greys out / breaks the form. }
  if FOwnerBound and (FOwnerMain = Main) then Exit;

  FOwnerMain := Main;
  PopupMode := pmExplicit;
  if Main is TCustomForm then
    PopupParent := TCustomForm(Main)
  else
    PopupParent := nil;

  if HandleAllocated then
    RecreateWnd
  else
    HandleNeeded;

  FOwnerBound := True;
end;

procedure TScreenshotPaneForm.PositionBeside(const Main: TForm; const AlignTopScreen: Integer);
begin
  if Main = nil then Exit;
  Left := Main.Left + Main.Width;
  Top := AlignTopScreen;
  ClientWidth := ScreenshotPaneFixedWidth;
  ClientHeight := ScreenshotPaneFixedHeight;
end;

procedure TScreenshotPaneForm.SetBitmap(const B: TBitmap);
begin
  if B = nil then begin
    ClearImage;
    Exit;
  end;
  Image.Picture.Assign(B);
end;

procedure TScreenshotPaneForm.ClearImage;
begin
  Image.Picture.Assign(nil);
end;

end.
