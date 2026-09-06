unit ModernProfileEditorImageQualityFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ExtCtrls, GameDBUnit, ModernProfileEditorFormUnit,
  PrgConsts;

type
  TModernProfileEditorImageQualityFrame = class(TFrame, IModernProfileEditorFrame)
    DeinterlacingLabel: TLabel;
    DeinterlacingComboBox: TComboBox;
    DeditheringLabel: TLabel;
    DeditheringComboBox: TComboBox;
    CrtColorProfileLabel: TLabel;
    CrtColorProfileComboBox: TComboBox;
    ColorSpaceLabel: TLabel;
    ColorSpaceComboBox: TComboBox;
    IntegerScalingLabel: TLabel;
    IntegerScalingComboBox: TComboBox;
    ImageAdjustmentsCheckBox: TCheckBox;
    ImageAdjustmentsGroupBox: TGroupBox;
    BrightnessLabel: TLabel;
    BrightnessEdit: TSpinEdit;
    ContrastLabel: TLabel;
    ContrastEdit: TSpinEdit;
    SaturationLabel: TLabel;
    SaturationEdit: TSpinEdit;
    ColorTemperatureLabel: TLabel;
    ColorTemperatureComboBox: TComboBox;
    procedure ImageAdjustmentsCheckBoxClick(Sender: TObject);
  private
    FTempGame: TGame;
    FDeinterlacingConfOpt: String;
    FDeditheringConfOpt: String;
    FCrtColorProfileConfOpt: String;
    FColorSpaceConfOpt: String;
    FIntegerScalingConfOpt: String;
    FColorTemperatureConfOpt: String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    function IsNewStaging: Boolean;
    procedure SelectQualityCombo(Combo: TComboBox; const GameValue: String);
    procedure ApplyKindEnable;
    procedure ApplyAdjustEnable;
    procedure ShowFrame(Sender: TObject);
    procedure Invalidate(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure InitGUI(var InitData: TModernProfileEditorInitData);
    procedure SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
    procedure GetGame(const Game: TGame);
  end;

implementation

uses
  Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, HelpConsts;

{$R *.dfm}

constructor TModernProfileEditorImageQualityFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame := nil;
  if AOwner is TModernProfileEditorForm then
    FTempGame := TModernProfileEditorForm(AOwner).TempGame;
end;

function TModernProfileEditorImageQualityFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  if (FTempGame = nil) and (Owner is TModernProfileEditorForm) then
    FTempGame := TModernProfileEditorForm(Owner).TempGame;
  if FTempGame <> nil then
    Result := FTempGame.DosBoxKind
  else
    Result := dbkUnknown;
end;

function TModernProfileEditorImageQualityFrame.IsNewStaging: Boolean;
begin
  Result := (GetSelectedDosBoxKind = dbkStaging) and (FTempGame <> nil) and (not FTempGame.IsOldStaging);
end;

procedure SetSpinEnabled(Edit: TSpinEdit; const En: Boolean);
begin
  Edit.Enabled := En;
  if En then
    Edit.Color := clWindow
  else
    Edit.Color := clBtnFace;
end;

procedure TModernProfileEditorImageQualityFrame.ApplyAdjustEnable;
var
  OnAdj: Boolean;
begin
  OnAdj := IsNewStaging and ImageAdjustmentsCheckBox.Checked;
  BrightnessLabel.Enabled := OnAdj;
  SetSpinEnabled(BrightnessEdit, OnAdj);
  ContrastLabel.Enabled := OnAdj;
  SetSpinEnabled(ContrastEdit, OnAdj);
  SaturationLabel.Enabled := OnAdj;
  SetSpinEnabled(SaturationEdit, OnAdj);
  ColorTemperatureLabel.Enabled := OnAdj;
  ColorTemperatureComboBox.Enabled := OnAdj;
  if not OnAdj then
    SetComboNoSelect(ColorTemperatureComboBox)
  else if (FTempGame <> nil) and (ColorTemperatureComboBox.ItemIndex < 0) then
    SelectQualityCombo(ColorTemperatureComboBox, FTempGame.ImageColorTemperature);
end;

procedure TModernProfileEditorImageQualityFrame.ApplyKindEnable;
var
  OnNew: Boolean;
begin
  OnNew := IsNewStaging;
  DeinterlacingLabel.Enabled := OnNew;
  DeinterlacingComboBox.Enabled := OnNew;
  DeditheringLabel.Enabled := OnNew;
  DeditheringComboBox.Enabled := OnNew;
  CrtColorProfileLabel.Enabled := OnNew;
  CrtColorProfileComboBox.Enabled := OnNew;
  ColorSpaceLabel.Enabled := OnNew;
  ColorSpaceComboBox.Enabled := OnNew;
  IntegerScalingLabel.Enabled := OnNew;
  IntegerScalingComboBox.Enabled := OnNew;
  ImageAdjustmentsCheckBox.Enabled := OnNew;
  if not OnNew then begin
    SetComboNoSelect(DeinterlacingComboBox);
    SetComboNoSelect(DeditheringComboBox);
    SetComboNoSelect(CrtColorProfileComboBox);
    SetComboNoSelect(ColorSpaceComboBox);
    SetComboNoSelect(IntegerScalingComboBox);
    SetComboNoSelect(ColorTemperatureComboBox);
  end else if FTempGame <> nil then begin
    if DeinterlacingComboBox.ItemIndex < 0 then
      SelectQualityCombo(DeinterlacingComboBox, FTempGame.Deinterlacing);
    if DeditheringComboBox.ItemIndex < 0 then
      SelectQualityCombo(DeditheringComboBox, FTempGame.Dedithering);
    if CrtColorProfileComboBox.ItemIndex < 0 then
      SelectQualityCombo(CrtColorProfileComboBox, FTempGame.CrtColorProfile);
    if ColorSpaceComboBox.ItemIndex < 0 then
      SelectQualityCombo(ColorSpaceComboBox, FTempGame.ColorSpace);
    if IntegerScalingComboBox.ItemIndex < 0 then
      SelectQualityCombo(IntegerScalingComboBox, FTempGame.IntegerScaling);
  end;
  ApplyAdjustEnable;
end;

procedure TModernProfileEditorImageQualityFrame.ImageAdjustmentsCheckBoxClick(Sender: TObject);
begin
  ApplyAdjustEnable;
end;

procedure TModernProfileEditorImageQualityFrame.ShowFrame(Sender: TObject);
begin
  ApplyKindEnable;
end;

procedure TModernProfileEditorImageQualityFrame.Invalidate(Sender: TObject);
begin
  ApplyKindEnable;
end;

procedure TModernProfileEditorImageQualityFrame.InitGUI(var InitData: TModernProfileEditorInitData);
begin
  NoFlicker(DeinterlacingComboBox);
  NoFlicker(DeditheringComboBox);
  NoFlicker(CrtColorProfileComboBox);
  NoFlicker(ColorSpaceComboBox);
  NoFlicker(IntegerScalingComboBox);
  NoFlicker(ImageAdjustmentsCheckBox);
  NoFlicker(ColorTemperatureComboBox);

  FDeinterlacingConfOpt := InitData.GameDB.ConfOpt.DeinterlacingStaging;
  FDeditheringConfOpt := InitData.GameDB.ConfOpt.DeditheringStaging;
  FCrtColorProfileConfOpt := InitData.GameDB.ConfOpt.CrtColorProfileStaging;
  FColorSpaceConfOpt := InitData.GameDB.ConfOpt.ColorSpaceStaging;
  FIntegerScalingConfOpt := InitData.GameDB.ConfOpt.IntegerScalingStaging;
  FColorTemperatureConfOpt := InitData.GameDB.ConfOpt.ColorTemperatureStaging;

  DeinterlacingLabel.Caption := LanguageSetup.ProfileEditorImageQualityDeinterlacing;
  DeditheringLabel.Caption := LanguageSetup.ProfileEditorImageQualityDedithering;
  CrtColorProfileLabel.Caption := LanguageSetup.ProfileEditorImageQualityCrtColorProfile;
  ColorSpaceLabel.Caption := LanguageSetup.ProfileEditorImageQualityColorSpace;
  IntegerScalingLabel.Caption := LanguageSetup.ProfileEditorImageQualityIntegerScaling;
  ImageAdjustmentsCheckBox.Caption := LanguageSetup.ProfileEditorImageQualityImageAdjustments;
  ImageAdjustmentsGroupBox.Caption := '';
  BrightnessLabel.Caption := LanguageSetup.ProfileEditorImageQualityBrightness;
  ContrastLabel.Caption := LanguageSetup.ProfileEditorImageQualityContrast;
  SaturationLabel.Caption := LanguageSetup.ProfileEditorImageQualitySaturation;
  ColorTemperatureLabel.Caption := LanguageSetup.ProfileEditorImageQualityColorTemperature;

  RebuildComboFromConfOpt(DeinterlacingComboBox, FDeinterlacingConfOpt, '');
  RebuildComboFromConfOpt(DeditheringComboBox, FDeditheringConfOpt, '');
  RebuildComboFromConfOpt(CrtColorProfileComboBox, FCrtColorProfileConfOpt, '');
  RebuildComboFromConfOpt(ColorSpaceComboBox, FColorSpaceConfOpt, '');
  RebuildComboFromConfOpt(IntegerScalingComboBox, FIntegerScalingConfOpt, '');
  RebuildComboFromConfOpt(ColorTemperatureComboBox, FColorTemperatureConfOpt, '');

  InitData.OnShowFrame := ShowFrame;
  InitData.OnInvalidate := Invalidate;
  HelpContext := ID_ProfileEditImageQuality;
end;

procedure TModernProfileEditorImageQualityFrame.SelectQualityCombo(Combo: TComboBox; const GameValue: String);
begin
  if ComboHasValue(Combo, GameValue) then
    SelectComboValue(Combo, GameValue)
  else
    SetComboNoSelect(Combo);
end;

procedure TModernProfileEditorImageQualityFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
begin
  SelectQualityCombo(DeinterlacingComboBox, Game.Deinterlacing);
  SelectQualityCombo(DeditheringComboBox, Game.Dedithering);
  SelectQualityCombo(CrtColorProfileComboBox, Game.CrtColorProfile);
  SelectQualityCombo(ColorSpaceComboBox, Game.ColorSpace);
  SelectQualityCombo(IntegerScalingComboBox, Game.IntegerScaling);
  ImageAdjustmentsCheckBox.Checked := Game.ImageAdjustments;
  BrightnessEdit.Value := Min(100, Max(0, Game.ImageBrightness));
  ContrastEdit.Value := Min(100, Max(0, Game.ImageContrast));
  SaturationEdit.Value := Min(50, Max(-50, Game.ImageSaturation));
  SelectQualityCombo(ColorTemperatureComboBox, Game.ImageColorTemperature);
  ApplyKindEnable;
end;

procedure TModernProfileEditorImageQualityFrame.GetGame(const Game: TGame);
begin
  if DeinterlacingComboBox.ItemIndex >= 0 then
    Game.Deinterlacing := Trim(DeinterlacingComboBox.Text);
  if DeditheringComboBox.ItemIndex >= 0 then
    Game.Dedithering := Trim(DeditheringComboBox.Text);
  if CrtColorProfileComboBox.ItemIndex >= 0 then
    Game.CrtColorProfile := Trim(CrtColorProfileComboBox.Text);
  if ColorSpaceComboBox.ItemIndex >= 0 then
    Game.ColorSpace := Trim(ColorSpaceComboBox.Text);
  if IntegerScalingComboBox.ItemIndex >= 0 then
    Game.IntegerScaling := Trim(IntegerScalingComboBox.Text);
  Game.ImageAdjustments := ImageAdjustmentsCheckBox.Checked;
  Game.ImageBrightness := Min(100, Max(0, BrightnessEdit.Value));
  Game.ImageContrast := Min(100, Max(0, ContrastEdit.Value));
  Game.ImageSaturation := Min(50, Max(-50, SaturationEdit.Value));
  if ColorTemperatureComboBox.ItemIndex >= 0 then
    Game.ImageColorTemperature := Trim(ColorTemperatureComboBox.Text);
end;

end.
