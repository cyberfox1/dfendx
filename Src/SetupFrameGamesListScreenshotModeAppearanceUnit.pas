unit SetupFrameGamesListScreenshotModeAppearanceUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Spin, SetupFormUnit;

type
  TSetupFrameGamesListScreenshotModeAppearance = class(TFrame, ISetupFrame)
    gbCoverImagesView: TGroupBox;
    CoverWidthLabel: TLabel;
    CoverWidthEdit: TSpinEdit;
    CoverHeightLabel: TLabel;
    CoverHeightEdit: TSpinEdit;
    CoverShowCaptionsCheckBox: TCheckBox;
    gbScreenshotsView: TGroupBox;
    WidthLabel: TLabel;
    WidthEdit: TSpinEdit;
    HeightLabel: TLabel;
    HeightEdit: TSpinEdit;
    ScreenshotShowCaptionsCheckBox: TCheckBox;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    Function GetName : String;
    Procedure InitGUIAndLoadSetup(var InitData : TInitData);
    Procedure BeforeChangeLanguage;
    Procedure LoadLanguage;
    Procedure DOSBoxDirChanged;
    Procedure ShowFrame(const AdvancedMode : Boolean);
    procedure HideFrame;
    Procedure RestoreDefaults;
    Procedure SaveSetup;
  end;

implementation

uses LanguageSetupUnit, VistaToolsUnit, PrgSetupUnit, CommonTools, HelpConsts;

{$R *.dfm}

{ TSetupFrameGamesListScreenshotModeAppearance }

function TSetupFrameGamesListScreenshotModeAppearance.GetName: String;
begin
  result:=LanguageSetup.SetupFormListViewSheet2b;
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.InitGUIAndLoadSetup(var InitData: TInitData);
begin
  NoFlicker(WidthEdit);
  NoFlicker(HeightEdit);
  NoFlicker(CoverWidthEdit);
  NoFlicker(CoverHeightEdit);
  NoFlicker(ScreenshotShowCaptionsCheckBox);
  NoFlicker(CoverShowCaptionsCheckBox);

  WidthEdit.Value:=PrgSetup.ScreenshotListViewWidth;
  HeightEdit.Value:=PrgSetup.ScreenshotListViewHeight;
  CoverWidthEdit.Value:=PrgSetup.CoverListViewWidth;
  CoverHeightEdit.Value:=PrgSetup.CoverListViewHeight;
  ScreenshotShowCaptionsCheckBox.Checked:=PrgSetup.ScreenshotListViewShowCaptions;
  CoverShowCaptionsCheckBox.Checked:=PrgSetup.CoverListViewShowCaptions;
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.BeforeChangeLanguage;
begin
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.LoadLanguage;
begin
  WidthLabel.Caption:=LanguageSetup.ScreenshotListViewWidth;
  HeightLabel.Caption:=LanguageSetup.ScreenshotListViewHeight;
  CoverWidthLabel.Caption:=LanguageSetup.CoverListViewWidth;
  CoverHeightLabel.Caption:=LanguageSetup.CoverListViewHeight;
  ScreenshotShowCaptionsCheckBox.Caption:=LanguageSetup.ScreenshotListViewShowCaptions;
  CoverShowCaptionsCheckBox.Caption:=LanguageSetup.ScreenshotListViewShowCaptions;

  HelpContext:=ID_FileOptionsListInScreenshotMode;
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.DOSBoxDirChanged;
begin
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.ShowFrame(const AdvancedMode: Boolean);
begin
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.HideFrame;
begin
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.RestoreDefaults;
begin
  WidthEdit.Value:=150;
  HeightEdit.Value:=100;
  CoverWidthEdit.Value:=150;
  CoverHeightEdit.Value:=200;
  ScreenshotShowCaptionsCheckBox.Checked:=True;
  CoverShowCaptionsCheckBox.Checked:=False;
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.SaveSetup;
begin
  PrgSetup.ScreenshotListViewWidth:=WidthEdit.Value;
  PrgSetup.ScreenshotListViewHeight:=HeightEdit.Value;
  PrgSetup.CoverListViewWidth:=CoverWidthEdit.Value;
  PrgSetup.CoverListViewHeight:=CoverHeightEdit.Value;
  PrgSetup.ScreenshotListViewShowCaptions:=ScreenshotShowCaptionsCheckBox.Checked;
  PrgSetup.CoverListViewShowCaptions:=CoverShowCaptionsCheckBox.Checked;
end;

end.
