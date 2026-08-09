unit ViewImageFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, ComCtrls, ToolWin, ExtCtrls, Menus, System.ImageList;

type
  TViewImageForm = class(TForm)
    CoolBar: TCoolBar;
    ToolBar: TToolBar;
    ToolButton2: TToolButton;
    CopyButton: TToolButton;
    SaveButton: TToolButton;
    ClearButton: TToolButton;
    ImageList: TImageList;
    Image: TImage;
    SaveDialog: TSaveDialog;
    ToolButton1: TToolButton;
    BackgroundButton: TToolButton;
    TitleImageButton: TToolButton;
    PreviousButton: TToolButton;
    NextButton: TToolButton;
    StatusBar: TStatusBar;
    ZoomButton: TToolButton;
    ZoomPopupMenu: TPopupMenu;
    ZoomMenuItem1: TMenuItem;
    ZoomMenuItem2: TMenuItem;
    ZoomMenuItem3: TMenuItem;
    ZoomMenuItem4: TMenuItem;
    ZoomMenuItem5: TMenuItem;
    ZoomMenuItem6: TMenuItem;
    ZoomMenuItem7: TMenuItem;
    ZoomMenuItem8: TMenuItem;
    ZoomMenuItem9: TMenuItem;
    ZoomMenuItem10: TMenuItem;
    ZoomMenuItem11: TMenuItem;
    ZoomMenuItem12: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure ButtonWork(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormResize(Sender: TObject);
    procedure ZoomPopupMenuPopup(Sender: TObject);
    procedure StatusBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private-Deklarationen }
    { Master decode for the open file (WIC). All quality scales use CreateScaledCopy from this. }
    FWicSource : TWICImage;
    FNativeW, FNativeH : Integer;
    { Content size at open; 100% zoom baseline. }
    FOpenW, FOpenH : Integer;
    { True while LoadImage mutates size — suppress FormResize WIC work. }
    FLoadingImage : Boolean;
    { True during ENTERSIZEMOVE..EXITSIZEMOVE: skip WIC; GDI Stretch of last view bitmap. }
    FInteractiveSizing : Boolean;
    { Outer size at ENTERSIZEMOVE — WIC only on EXIT if size actually changed (not pure move). }
    FEnterOuterW, FEnterOuterH : Integer;
    { Last WIC scale target; skip a second pass if client still matches. }
    FLastScaleW, FLastScaleH : Integer;
    Procedure CenterWindow;
    Procedure LoadImage(const MoveWindow : Boolean);
    Procedure Zoom(const ZoomDirection : Integer);
    Procedure ApplyZoomPercent(const Percent: Double);
    Procedure UpdateStatusBar;
    { WIC quality scale from FWicSource into the image client (or MaxW×MaxH). }
    Procedure ApplyViewScale; overload;
    Procedure ApplyViewScale(const MaxW, MaxH: Integer); overload;
    Procedure ClearWicSource;
    Procedure ShowEmptyImage;
    Procedure FailAndClose(const Msg: String);
    { Fit DesiredW×H into MaxW×H; scale down only; keep aspect. }
    Procedure FitDown(const DesiredW, DesiredH, MaxW, MaxH: Integer; out OutW, OutH: Integer);
    Procedure SetClientContentSize(const ContentW, ContentH: Integer);
    procedure WMEnterSizeMove(var Message: TMessage); message WM_ENTERSIZEMOVE;
    procedure WMExitSizeMove(var Message: TMessage); message WM_EXITSIZEMOVE;
  public
    { Public-Deklarationen }
    ImageFile : String;
    PrevImages, NextImages : TStringList;
    NonModal : Boolean;
    { Optional profile to update for "As title image"; nil = button no-ops store. }
    TitleImageGame : TObject;
    Procedure LoadLanguage;
    Procedure UpdateImageList;
  end;

var
  ViewImageForm: TViewImageForm = nil;

Procedure ShowNonModalImageDialog(const AOwner : TComponent; const AImageFile : String; APrevImages, ANextImages : TStringList; const ATitleImageGame : TObject = nil);
Procedure ShowImageDialog(const AOwner : TComponent; const AImageFile : String; const APrevImages, ANextImages : TStringList; const ATitleImageGame : TObject = nil);

implementation

uses Math, ClipBrd, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools,
     WallpaperStyleFormUnit, PrgSetupUnit, IconLoaderUnit, System.Types,
     System.UITypes, GameDBUnit, ResampleHelpers;

{$R *.dfm}

{ TViewImageForm }

procedure TViewImageForm.CenterWindow;
Var P : TForm;
    F : TFrame;
begin
  If Owner is TForm then begin
    P:=Owner as TForm;
    Left:=Max(0,(P.Left+P.Width div 2)-Width div 2);
    Top:=Max(0,(P.Top+P.Height div 2)-Height div 2);
  end;

  If Owner is TFrame then begin
    F:=Owner as TFrame;
    Left:=Max(0,(F.Left+F.Width div 2)-Width div 2);
    Top:=Max(0,(F.Top+F.Height div 2)-Height div 2);
  end;
end;

procedure TViewImageForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  If (Action=caHide) and NonModal then Action:=caFree;
end;

procedure TViewImageForm.FormCreate(Sender: TObject);
var
  B: TBitmap;
begin
  SetVistaFonts(self);
  DoubleBuffered:=True;

  PrevImages:=TStringList.Create;
  NextImages:=TStringList.Create;

  NonModal:=False;
  TitleImageGame:=nil;

  { Ensure ImageList has a slot for TitleImageButton (index 7) before DialogImage. }
  while ImageList.Count<8 do begin
    B:=TBitmap.Create;
    try
      B.SetSize(16,16);
      ImageList.Add(B,nil);
    finally
      B.Free;
    end;
  end;
end;

procedure TViewImageForm.FormShow(Sender: TObject);
begin
  LoadLanguage;
  LoadImage(True);
end;

procedure TViewImageForm.LoadLanguage;
begin
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);
  Caption:=LanguageSetup.ViewImageForm;
  PreviousButton.Caption:=LanguageSetup.Previous;
  PreviousButton.Hint:=LanguageSetup.PreviousHintMediaViewer;
  NextButton.Caption:=LanguageSetup.Next;
  NextButton.Hint:=LanguageSetup.NextHintMediaViewer;
  CopyButton.Caption:=LanguageSetup.Copy;
  CopyButton.Hint:=LanguageSetup.CopyHintImageViewer;
  SaveButton.Caption:=LanguageSetup.Save;
  SaveButton.Hint:=LanguageSetup.SaveHintImageViewer;
  ClearButton.Caption:=LanguageSetup.Clear;
  ClearButton.Hint:=LanguageSetup.ClearMediaViewer;
  ZoomButton.Caption:=LanguageSetup.ViewImageFormZoomButton;
  ZoomButton.Hint:=LanguageSetup.ViewImageFormZoomButtonHint;
  BackgroundButton.Caption:=LanguageSetup.ViewImageFormBackgroundButton;
  BackgroundButton.Hint:=LanguageSetup.ViewImageFormBackgroundButtonHint;
  TitleImageButton.Caption:=LanguageSetup.ViewImageFormTitleImageButton;
  TitleImageButton.Hint:=LanguageSetup.ViewImageFormTitleImageButtonHint;

  CoolBar.Font.Size:=PrgSetup.ToolbarFontSize;

  UserIconLoader.DialogImage(DI_CopyToClipboard,ImageList,0);
  UserIconLoader.DialogImage(DI_Save,ImageList,1);
  UserIconLoader.DialogImage(DI_Clear,ImageList,2);
  UserIconLoader.DialogImage(DI_BackgroundImage,ImageList,3);
  UserIconLoader.DialogImage(DI_Previous,ImageList,4);
  UserIconLoader.DialogImage(DI_Next,ImageList,5);
  UserIconLoader.DialogImage(DI_Zoom,ImageList,6);
  { Same small image icon as context menu (DI_Image). }
  UserIconLoader.DialogImage(DI_Image,ImageList,7);
end;

procedure TViewImageForm.ClearWicSource;
begin
  FreeAndNil(FWicSource);
end;

procedure TViewImageForm.ShowEmptyImage;
begin
  Image.Picture.Bitmap.SetSize(10, 10);
  Image.Picture.Bitmap.Canvas.Brush.Color := clBlack;
  Image.Picture.Bitmap.Canvas.FillRect(Rect(0, 0, 10, 10));
end;

procedure TViewImageForm.FailAndClose(const Msg: String);
begin
  try
    MessageDlg(Msg, mtError, [mbOK], 0);
  except
  end;
  Close;
end;

procedure TViewImageForm.FitDown(const DesiredW, DesiredH, MaxW, MaxH: Integer; out OutW, OutH: Integer);
var
  Scale: Double;
  MW, MH: Integer;
begin
  { Scale down only so both axes stay within Max; never expand. Aspect preserved. }
  MW := Max(1, MaxW);
  MH := Max(1, MaxH);
  if (DesiredW <= 0) or (DesiredH <= 0) then begin
    OutW := 1;
    OutH := 1;
    Exit;
  end;
  if (DesiredW <= MW) and (DesiredH <= MH) then begin
    OutW := DesiredW;
    OutH := DesiredH;
    Exit;
  end;
  Scale := Min(MW / DesiredW, MH / DesiredH);
  OutW := Max(1, Round(DesiredW * Scale));
  OutH := Max(1, Round(DesiredH * Scale));
end;

procedure TViewImageForm.SetClientContentSize(const ContentW, ContentH: Integer);
var
  FrameW, FrameH, ChromeH: Integer;
  CW, CH: Integer;
begin
  FrameW := Width - ClientWidth;
  FrameH := Height - ClientHeight;
  ChromeH := ClientHeight - Image.Height;
  if ChromeH < 0 then ChromeH := 0;
  CW := Max(1, ContentW);
  CH := Max(1, ContentH) + ChromeH;
  ClientWidth := CW;
  ClientHeight := CH;
  { Re-clamp if frame/chrome made us exceed work area (joint, aspect from content). }
  if (Width > Screen.WorkAreaWidth - 10) or (Height > Screen.WorkAreaHeight - 10) then begin
    FitDown(CW, Max(1, ContentH),
      Max(1, Screen.WorkAreaWidth - 10 - FrameW),
      Max(1, Screen.WorkAreaHeight - 10 - FrameH - ChromeH),
      CW, CH);
    ClientWidth := CW;
    ClientHeight := CH + ChromeH;
  end;
end;

procedure TViewImageForm.LoadImage(const MoveWindow: Boolean);
var
  MaxTw, MaxTh: Integer;
  ChromeH, FrameW, FrameH: Integer;
  NewSrc: TWICImage;
  ContentW, ContentH: Integer;
begin
  { Pipeline:
      1) WIC LoadFromFile → FWicSource (master, once per file)
      2) Fit open window (aspect + work area; min client 640×100 like old form)
      3) WIC CreateScaledCopy into Image
    Next/prev: replace master before resize so old pixels are never stretched into the new frame. }
  FLoadingImage := True;
  try
    PreviousButton.Enabled:=(PrevImages.Count>0);
    NextButton.Enabled:=(NextImages.Count>0);

    Caption:=LanguageSetup.ViewImageForm+' ['+MakeRelPath(ImageFile,PrgSetup.BaseDir)+']';

    FrameW := Width - ClientWidth;
    FrameH := Height - ClientHeight;
    ChromeH := ClientHeight - Image.Height;
    if ChromeH < 0 then ChromeH := 0;
    MaxTw := Max(1, Screen.WorkAreaWidth - 10 - FrameW);
    MaxTh := Max(1, Screen.WorkAreaHeight - 10 - FrameH - ChromeH);

    NewSrc := TWICImage.Create;
    try
      if (ImageFile <> '') and FileExists(ImageFile) then
        NewSrc.LoadFromFile(ImageFile);
    except
      on E: Exception do begin
        FreeAndNil(NewSrc);
        FailAndClose('Could not load image:'#13#10+E.Message);
        Exit;
      end;
    end;
    ClearWicSource;
    FWicSource := NewSrc;

    FNativeW := 0;
    FNativeH := 0;
    FOpenW := 10;
    FOpenH := 10;
    FLastScaleW := 0;
    FLastScaleH := 0;
    if (not FWicSource.Empty) and (FWicSource.Width > 0) and (FWicSource.Height > 0) then begin
      FNativeW := FWicSource.Width;
      FNativeH := FWicSource.Height;
      if (FNativeW <= MaxTw) and (FNativeH <= MaxTh) then begin
        FOpenW := FNativeW;
        FOpenH := FNativeH;
      end else
        FitDown(FNativeW, FNativeH, MaxTw, MaxTh, FOpenW, FOpenH);
    end;

    { Old behaviour: content = image open size; client min width 640 / min height 100
      without forcing image height to scale up with the min width. }
    ContentW := FOpenW;
    ContentH := FOpenH;

    Image.Stretch := True;
    Image.Proportional := True;
    Image.Center := True;
    if (not FWicSource.Empty) and (FWicSource.Width > 0) then
      ApplyViewScale(ContentW, ContentH)
    else
      ShowEmptyImage;

    { Client size: Max(640, contentW) × Max(100, contentH+chrome), clamped to work area. }
    ClientWidth := Min(Max(640, ContentW), MaxTw);
    ClientHeight := Min(Max(100, ContentH + ChromeH),
      Max(1, Screen.WorkAreaHeight - 10 - FrameH));

    If MoveWindow or (Left+Width>=Screen.WorkAreaWidth-10) or (Top+Height>=Screen.WorkAreaHeight-10) then CenterWindow;

    { Second WIC pass only if real image client differs from the pre-size target. }
    if (Image.ClientWidth <> FLastScaleW) or (Image.ClientHeight <> FLastScaleH) then
      ApplyViewScale;
    UpdateStatusBar;
  finally
    FLoadingImage := False;
  end;
end;

procedure TViewImageForm.UpdateImageList;
begin
  LoadImage(False);
end;

procedure TViewImageForm.StatusBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var P : TPoint;
begin
  If X>StatusBar.Panels[0].Width+StatusBar.Panels[1].Width then exit;
  P:=StatusBar.ClientToScreen(Point(X,Y));
  ZoomPopupMenu.Popup(P.X+5,P.Y+5);
end;

procedure TViewImageForm.ApplyZoomPercent(const Percent: Double);
var
  FrameW, FrameH, ChromeH: Integer;
  DesireW, DesireH, ContentW, ContentH, MaxW, MaxH: Integer;
  F: Double;
begin
  if (FOpenW <= 0) or (FOpenH <= 0) then Exit;
  F := Percent;
  if F < 0.1 then F := 0.1;

  FrameW := Width - ClientWidth;
  FrameH := Height - ClientHeight;
  ChromeH := ClientHeight - Image.Height;
  if ChromeH < 0 then ChromeH := 0;
  MaxW := Max(1, Screen.WorkAreaWidth - 10 - FrameW);
  MaxH := Max(1, Screen.WorkAreaHeight - 10 - FrameH - ChromeH);

  DesireW := Max(1, Round(F * FOpenW));
  DesireH := Max(1, Round(F * FOpenH));
  { Joint fit: when either edge hits the work area, both stop (aspect preserved). }
  FitDown(DesireW, DesireH, MaxW, MaxH, ContentW, ContentH);

  FLoadingImage := True;
  try
    SetClientContentSize(ContentW, ContentH);
    if ClientHeight < 100 then ClientHeight := 100;
    CenterWindow;
    ApplyViewScale;
    UpdateStatusBar;
  finally
    FLoadingImage := False;
  end;
end;

procedure TViewImageForm.Zoom(const ZoomDirection: Integer);
Var I,J : Integer;
begin
  if (FOpenW <= 0) or (FOpenH <= 0) then Exit;

  I:=Round(Image.ClientWidth/FOpenW*100);
  J:=Round(Image.ClientHeight/FOpenH*100);

  I:=Round(Min(I,J)/25)*25;
  If ZoomDirection=0 then I:=100 else begin
    If ZoomDirection<0 then I:=Max(10,I-25) else I:=Max(10,I+25);
  end;

  ApplyZoomPercent(I/100);
end;

procedure TViewImageForm.ZoomPopupMenuPopup(Sender: TObject);
Var I,J,Z,M : Integer;
    S : String;
begin
  if (FOpenW <= 0) or (FOpenH <= 0) then Exit;
  I:=Round(Image.ClientWidth/FOpenW*100);
  J:=Round(Image.ClientHeight/FOpenH*100);
  Z:=Min(I,J);

  For I:=0 to ZoomPopupMenu.Items.Count-1 do begin
    ZoomPopupMenu.Items[I].ShortCut:=0;
    S:=RemoveUnderline(ZoomPopupMenu.Items[I].Caption);
    M:=StrToInt(Copy(S,1,length(S)-1));
    ZoomPopupMenu.Items[I].Enabled:=(M<>Z);
    If (M<Z) and (M+25>=Z) then ZoomPopupMenu.Items[I].ShortCut:=ShortCut(VK_OEM_MINUS,[]);
    If (M>Z) and (M-25<=Z) then ZoomPopupMenu.Items[I].ShortCut:=ShortCut(VK_OEM_PLUS,[]);
    If M=100 then ZoomPopupMenu.Items[I].ShortCut:=ShortCut(ord('0'),[]);
  end;
end;

procedure TViewImageForm.ButtonWork(Sender: TObject);
Var WPStype : TWallpaperStyle;
    S : String;
    F : Double;
begin
  Case (Sender as TComponent).Tag of
    1 : if FWicSource <> nil then Clipboard.Assign(FWicSource);
    2 : begin
          SaveDialog.FileName:='';
          SaveDialog.Title:=LanguageSetup.ViewImageFormSaveTitle;
          SaveDialog.Filter:=LanguageSetup.ViewImageFormSaveFilter;
          if not SaveDialog.Execute then exit;
          SaveImageToFile(ImageFile,SaveDialog.FileName);
        end;
    3 : begin
          if not ExtDeleteFile(ImageFile,ftMediaViewer) then begin
            MessageDlg(Format(LanguageSetup.MessageCouldNotDeleteFile,[ImageFile]),mtError,[mbOK],0);
            exit;
          end;
          Close;
        end;
    4 : begin
          If not ShowWallpaperStyleDialog(self,WPStype) then exit;
          SetDesktopWallpaper(ImageFile,WPStype);
        end;
    8 : begin
          If (TitleImageGame=nil) or (ImageFile='') then exit;
          If not FileExists(ImageFile) then exit;
          TGame(TitleImageGame).SelectedTitleImage:=MakeRelPath(ImageFile,PrgSetup.BaseDir);
          TGame(TitleImageGame).StoreAllValues;
          { Refresh title-image pane if main form is listening (avoids circular unit). }
          if Application.MainForm<>nil then
            PostMessage(Application.MainForm.Handle,WM_USER+3,0,0);
        end;
    5 : If PrevImages.Count>0 then begin
          NextImages.Insert(0,ImageFile);
          ImageFile:=PrevImages[PrevImages.Count-1];
          PrevImages.Delete(PrevImages.Count-1);
          LoadImage(False);
        end;
    6 : if NextImages.Count>0 then begin
          PrevImages.Add(ImageFile);
          ImageFile:=NextImages[0];
          NextImages.Delete(0);
          LoadImage(False);
        end;
    7 : begin
          { Zoom popup menu items (10%..400%) all share Tag=7. }
          If WindowState=wsMaximized then WindowState:=wsNormal;
          S:=RemoveUnderline((Sender as TMenuItem).Caption);
          F:=StrToInt(Copy(S,1,length(S)-1))/100;
          ApplyZoomPercent(F);
        end;
  end;
end;

procedure TViewImageForm.FormDestroy(Sender: TObject);
begin
  PrevImages.Free;
  NextImages.Free;
  ClearWicSource;
  If NonModal then ViewImageForm:=nil;
end;

procedure TViewImageForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  If Shift=[] then Case Key of
    VK_LEFT, VK_UP, VK_PRIOR : ButtonWork(PreviousButton);
    VK_RIGHT, VK_DOWN, VK_NEXT : ButtonWork(NextButton);
    VK_ADD, VK_OEM_PLUS : Zoom(1);
    VK_SUBTRACT, VK_OEM_MINUS  : Zoom(-1);
    ord('0'), VK_MULTIPLY, VK_NUMPAD0 : Zoom(0);
    VK_ESCAPE : Close;
  end;
end;

procedure TViewImageForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  If Shift=[] then begin
    If WheelDelta>0 then ButtonWork(PreviousButton) else ButtonWork(NextButton);
  end else begin
    If WheelDelta>0 then Zoom(-1) else Zoom(1);
  end;
end;

procedure TViewImageForm.UpdateStatusBar;
var
  D: Double;
begin
  if FWicSource = nil then Exit;
  if (FNativeW > 0) and (FNativeH > 0) then
    StatusBar.Panels[0].Text := IntToStr(FNativeW)+'x'+IntToStr(FNativeH)
  else
    StatusBar.Panels[0].Text := IntToStr(FOpenW)+'x'+IntToStr(FOpenH);
  if (FOpenW > 0) and (FOpenH > 0) then
    D := Min(Image.ClientWidth/FOpenW, Image.ClientHeight/FOpenH)
  else
    D := 1;
  StatusBar.Panels[1].Text := IntToStr(Round(D*100))+'%';
  StatusBar.Panels[2].Text := ImageFile;
end;

procedure TViewImageForm.ApplyViewScale;
begin
  ApplyViewScale(Image.ClientWidth, Image.ClientHeight);
end;

procedure TViewImageForm.ApplyViewScale(const MaxW, MaxH: Integer);
var
  Scaled: TWICImage;
  NewW, NewH: Integer;
begin
  { Settled quality path — WIC scaler from master FWicSource only.
    Not used during interactive border drag (GDI Stretch of last view bitmap). }
  if FInteractiveSizing then Exit;
  if (FWicSource = nil) or FWicSource.Empty then Exit;
  if (FWicSource.Width <= 0) or (FWicSource.Height <= 0) then Exit;
  if (MaxW <= 0) or (MaxH <= 0) then Exit;

  try
    CalcWH(FWicSource.Width, FWicSource.Height, MaxW, MaxH, NewW, NewH);
    if (NewW <= 0) or (NewH <= 0) then Exit;

    Image.Stretch := True;
    Image.Proportional := True;
    Image.Center := True;

    if (NewW = FWicSource.Width) and (NewH = FWicSource.Height) then
      Image.Picture.Assign(FWicSource)
    else begin
      Scaled := FWicSource.CreateScaledCopy(NewW, NewH, wipmHighQualityCubic);
      try
        Image.Picture.Assign(Scaled);
      finally
        Scaled.Free;
      end;
    end;
    FLastScaleW := MaxW;
    FLastScaleH := MaxH;
    Image.Invalidate;
  except
    on E: Exception do
      FailAndClose('Could not display image:'#13#10+E.Message);
  end;
end;

procedure TViewImageForm.WMEnterSizeMove(var Message: TMessage);
begin
  { Live drag/move: keep last view bitmap; GDI Stretch while the control resizes.
    WIC only runs on EXIT if outer size actually changed (resize, not pure move). }
  FInteractiveSizing := True;
  FEnterOuterW := Width;
  FEnterOuterH := Height;
  Image.Stretch := True;
  Image.Proportional := True;
  Image.Center := True;
  Message.Result := 0;
end;

procedure TViewImageForm.WMExitSizeMove(var Message: TMessage);
begin
  FInteractiveSizing := False;
  if (Width <> FEnterOuterW) or (Height <> FEnterOuterH) then
    ApplyViewScale;
  UpdateStatusBar;
  Message.Result := 0;
end;

procedure TViewImageForm.FormResize(Sender: TObject);
begin
  if FLoadingImage then begin
    UpdateStatusBar;
    Exit;
  end;
  if FInteractiveSizing then begin
    { GDI Stretch handles live paint when "Show window contents while dragging" is on. }
    UpdateStatusBar;
    Exit;
  end;
  { Non-drag size changes (zoom buttons, restore, etc.): WIC quality scale. }
  ApplyViewScale;
  UpdateStatusBar;
end;

{ global }

Procedure ShowNonModalImageDialog(const AOwner : TComponent; const AImageFile : String; APrevImages, ANextImages : TStringList; const ATitleImageGame : TObject = nil);
begin
  If AImageFile<>'' then begin
    If OpenMediaFile(PrgSetup.ImageViewer,AImageFile) then exit;
  end;

  If not Assigned(ViewImageForm) then ViewImageForm:=TViewImageForm.Create(AOwner);
  ViewImageForm.ImageFile:=AImageFile;
  ViewImageForm.TitleImageGame:=ATitleImageGame;
  If APrevImages<>nil then ViewImageForm.PrevImages.Assign(APrevImages);
  If ANextImages<>nil then ViewImageForm.NextImages.Assign(ANextImages);
  ViewImageForm.NonModal:=True;
  If ViewImageForm.Visible then ViewImageForm.UpdateImageList else ViewImageForm.Show;
end;

Procedure ShowImageDialog(const AOwner : TComponent; const AImageFile : String; const APrevImages, ANextImages : TStringList; const ATitleImageGame : TObject = nil);
begin
  If OpenMediaFile(PrgSetup.ImageViewer,AImageFile) then exit;
  If Assigned(ViewImageForm) then FreeAndNil(ViewImageForm);

  ViewImageForm:=TViewImageForm.Create(AOwner);
  try
    ViewImageForm.ImageFile:=AImageFile;
    ViewImageForm.TitleImageGame:=ATitleImageGame;
    If APrevImages<>nil then ViewImageForm.PrevImages.Assign(APrevImages);
    If ANextImages<>nil then ViewImageForm.NextImages.Assign(ANextImages);
    If (APrevImages=nil) and (ANextImages=nil) then begin
      ViewImageForm.PreviousButton.Visible:=False;
      ViewImageForm.NextButton.Visible:=False;
      ViewImageForm.ToolButton2.Visible:=False;
    end;
    ViewImageForm.ShowModal;
  finally
    FreeAndNil(ViewImageForm);
  end;
end;

end.
