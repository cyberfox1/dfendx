unit SetupFrameGamesListScreenshotModeAppearanceUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Spin, SetupFormUnit;

type
  TSetupFrameGamesListScreenshotModeAppearance = class(TFrame, ISetupFrame)
    WidthLabel: TLabel;
    HeightLabel: TLabel;
    WidthEdit: TSpinEdit;
    HeightEdit: TSpinEdit;
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

  WidthEdit.Value:=PrgSetup.ScreenshotListViewWidth;
  HeightEdit.Value:=PrgSetup.ScreenshotListViewHeight;
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.BeforeChangeLanguage;
begin
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.LoadLanguage;
begin
  WidthLabel.Caption:=LanguageSetup.ScreenshotListViewWidth;
  HeightLabel.Caption:=LanguageSetup.ScreenshotListViewHeight;

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
end;

procedure TSetupFrameGamesListScreenshotModeAppearance.SaveSetup;
begin
  PrgSetup.ScreenshotListViewWidth:=WidthEdit.Value;
  PrgSetup.ScreenshotListViewHeight:=HeightEdit.Value;
end;

end.
