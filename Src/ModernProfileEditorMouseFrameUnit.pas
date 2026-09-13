unit ModernProfileEditorMouseFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, GameDBUnit, ModernProfileEditorFormUnit, PrgConsts;

type
  TModernProfileEditorMouseFrame = class(TFrame, IModernProfileEditorFrame)
    LockMouseCheckBox: TCheckBox;
    LockMouseLabel: TLabel;
    MouseSensitivityEdit: TSpinEdit;
    MouseSensitivityLabel: TLabel;
    Force2ButtonsCheckBox: TCheckBox;
    SwapButtonsCheckBox: TCheckBox;
    Force2ButtonsInfoLabel: TLabel;
    SwapButtonsInfoLabel: TLabel;
    MouseDriverModelLabel: TLabel;
    MouseDriverModelComboBox: TComboBox;
    MouseMoveThresholdLabel: TLabel;
    MouseMoveThresholdComboBox: TComboBox;
    MouseDriverOptionsGroupBox: TGroupBox;
    MouseImmediateCheckBox: TCheckBox;
    MouseModernCheckBox: TCheckBox;
    MouseNoGranularityCheckBox: TCheckBox;
    Ps2CheckBox: TCheckBox;
    Ps2ModelLabel: TLabel;
    Ps2ModelComboBox: TComboBox;
    Ps2ReportRateLabel: TLabel;
    Ps2ReportRateComboBox: TComboBox;
    VMwareCheckBox: TCheckBox;
    VirtualBoxCheckBox: TCheckBox;
    BiosPs2CheckBox: TCheckBox;
    CtmouseCheckBox: TCheckBox;
    procedure Force2ButtonsCheckBoxClick(Sender: TObject);
    procedure Ps2CheckBoxClick(Sender: TObject);
  private
    FGame: TGame;
    FTempGame: TGame;
    FMouseDriverModelConfOpt: String;
    FMouseMoveThresholdConfOpt: String;
    FPs2ModelStagingConfOpt: String;
    FPs2ModelXConfOpt: String;
    FPs2ReportRateStagingConfOpt: String;
    FPs2ReportRateXConfOpt: String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    function IsNewStaging: Boolean;
    function CaptionFromMouseModelToken(const Token: String): String;
    function TokenFromMouseModelCaption(const Caption: String): String;
    function Ps2ModelConfOpt: String;
    function Ps2ReportRateConfOpt: String;
    procedure ReloadPs2Combos(const KeepState: Boolean);
    procedure FillMouseModelCombo;
    procedure SelectMouseModel(const Token: String);
    procedure ApplyStagingMouseVisible;
    procedure ApplyPs2Enable;
    procedure ShowFrame(Sender: TObject);
    procedure Invalidate(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure InitGUI(var InitData: TModernProfileEditorInitData);
    procedure SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
    procedure GetGame(const Game: TGame);
  end;

implementation

uses Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools, PrgSetupUnit, HelpConsts;

{$R *.dfm}

constructor TModernProfileEditorMouseFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FGame := nil;
  FTempGame := nil;
  if AOwner is TModernProfileEditorForm then
    FTempGame := TModernProfileEditorForm(AOwner).TempGame;
end;

function TModernProfileEditorMouseFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  if (FTempGame = nil) and (Owner is TModernProfileEditorForm) then
    FTempGame := TModernProfileEditorForm(Owner).TempGame;
  if FTempGame <> nil then
    Result := FTempGame.DosBoxKind
  else
    Result := dbkUnknown;
end;

function TModernProfileEditorMouseFrame.IsNewStaging: Boolean;
begin
  Result := (GetSelectedDosBoxKind = dbkStaging) and (FTempGame <> nil) and (not FTempGame.IsOldStaging);
end;

function TModernProfileEditorMouseFrame.CaptionFromMouseModelToken(const Token: String): String;
var
  S: String;
begin
  S := Trim(Token);
  if SameText(S, '2button') then
    Result := LanguageSetup.ProfileEditorMouseDriverModel2Button
  else if SameText(S, '3button') then
    Result := LanguageSetup.ProfileEditorMouseDriverModel3Button
  else if SameText(S, 'wheel') then
    Result := LanguageSetup.ProfileEditorMouseDriverModelWheel
  else
    Result := S;
end;

function TModernProfileEditorMouseFrame.TokenFromMouseModelCaption(const Caption: String): String;
var
  S: String;
begin
  S := Trim(Caption);
  if SameText(S, LanguageSetup.ProfileEditorMouseDriverModel2Button) then
    Result := '2button'
  else if SameText(S, LanguageSetup.ProfileEditorMouseDriverModel3Button) then
    Result := '3button'
  else if SameText(S, LanguageSetup.ProfileEditorMouseDriverModelWheel) then
    Result := 'wheel'
  else
    Result := S;
end;

procedure TModernProfileEditorMouseFrame.FillMouseModelCombo;
var
  St: TStringList;
  I: Integer;
  Tok: String;
begin
  MouseDriverModelComboBox.Items.BeginUpdate;
  try
    MouseDriverModelComboBox.Items.Clear;
    St := ValueToList(FMouseDriverModelConfOpt, ',');
    try
      for I := 0 to St.Count - 1 do begin
        Tok := Trim(St[I]);
        if Tok <> '' then
          MouseDriverModelComboBox.Items.Add(CaptionFromMouseModelToken(Tok));
      end;
    finally
      St.Free;
    end;
  finally
    MouseDriverModelComboBox.Items.EndUpdate;
  end;
  SetComboNoSelect(MouseDriverModelComboBox);
end;

procedure TModernProfileEditorMouseFrame.SelectMouseModel(const Token: String);
var
  S: String;
begin
  S := Trim(Token);
  if S = '' then begin
    SetComboNoSelect(MouseDriverModelComboBox);
    Exit;
  end;
  SelectComboValue(MouseDriverModelComboBox, CaptionFromMouseModelToken(S));
  if MouseDriverModelComboBox.ItemIndex < 0 then
    SelectComboValue(MouseDriverModelComboBox, S);
end;

procedure TModernProfileEditorMouseFrame.ApplyStagingMouseVisible;
var
  Vis: Boolean;
begin
  Vis := IsNewStaging;
  MouseDriverModelLabel.Visible := Vis;
  MouseDriverModelComboBox.Visible := Vis;
  MouseMoveThresholdLabel.Visible := Vis;
  MouseMoveThresholdComboBox.Visible := Vis;
  MouseDriverOptionsGroupBox.Visible := Vis;
  MouseDriverModelComboBox.Enabled := True;
end;

function TModernProfileEditorMouseFrame.Ps2ModelConfOpt: String;
begin
  case GetSelectedDosBoxKind of
    dbkStaging: Result := FPs2ModelStagingConfOpt;
    dbkX: Result := FPs2ModelXConfOpt;
    else Result := '';
  end;
end;

function TModernProfileEditorMouseFrame.Ps2ReportRateConfOpt: String;
begin
  case GetSelectedDosBoxKind of
    dbkStaging: Result := FPs2ReportRateStagingConfOpt;
    dbkX: Result := FPs2ReportRateXConfOpt;
    else Result := '';
  end;
end;

procedure TModernProfileEditorMouseFrame.ReloadPs2Combos(const KeepState: Boolean);
var
  ModelVal, RateVal: String;
begin
  ModelVal := '';
  RateVal := '';
  if FGame <> nil then begin
    ModelVal := FGame.Ps2MouseModel;
    RateVal := FGame.Ps2ReportRate;
  end;
  ReloadComboFromConfOpt(Ps2ModelComboBox, Ps2ModelConfOpt, KeepState, ModelVal);
  ReloadComboFromConfOpt(Ps2ReportRateComboBox, Ps2ReportRateConfOpt, KeepState, RateVal);
end;

procedure TModernProfileEditorMouseFrame.ApplyPs2Enable;
var
  Kind: TDOSBoxKind;
  KindOK, OnPs2: Boolean;
begin
  Kind := GetSelectedDosBoxKind;
  KindOK := Kind in [dbkStaging, dbkX];
  Ps2CheckBox.Enabled := Kind in [dbkStandard, dbkStaging, dbkX, dbkPure];
  OnPs2 := Ps2CheckBox.Enabled and Ps2CheckBox.Checked;
  Force2ButtonsCheckBox.Enabled := OnPs2;
  SwapButtonsCheckBox.Enabled := OnPs2;
  Force2ButtonsInfoLabel.Enabled := OnPs2;
  SwapButtonsInfoLabel.Enabled := OnPs2;
  Ps2ModelLabel.Enabled := OnPs2 and KindOK;
  Ps2ModelComboBox.Enabled := OnPs2 and KindOK;
  Ps2ReportRateLabel.Enabled := OnPs2 and KindOK;
  Ps2ReportRateComboBox.Enabled := OnPs2 and KindOK;
  VMwareCheckBox.Enabled := OnPs2 and KindOK;
  VirtualBoxCheckBox.Enabled := OnPs2 and (Kind = dbkStaging);
  BiosPs2CheckBox.Enabled := OnPs2 and (Kind = dbkX);
  CtmouseCheckBox.Enabled := OnPs2 and KindOK;
  if OnPs2 and KindOK and (Force2ButtonsCheckBox.Checked or SwapButtonsCheckBox.Checked) then begin
    CtmouseCheckBox.Checked := True;
    CtmouseCheckBox.Enabled := False;
  end;
end;

procedure TModernProfileEditorMouseFrame.Ps2CheckBoxClick(Sender: TObject);
begin
  ApplyPs2Enable;
end;

procedure TModernProfileEditorMouseFrame.Force2ButtonsCheckBoxClick(Sender: TObject);
begin
  ApplyPs2Enable;
end;

procedure TModernProfileEditorMouseFrame.ShowFrame(Sender: TObject);
begin
  ApplyStagingMouseVisible;
  ApplyPs2Enable;
  ReloadPs2Combos(True);
end;

procedure TModernProfileEditorMouseFrame.Invalidate(Sender: TObject);
begin
  ApplyStagingMouseVisible;
  ApplyPs2Enable;
  ReloadPs2Combos(True);
end;

procedure TModernProfileEditorMouseFrame.InitGUI(var InitData: TModernProfileEditorInitData);
begin
  NoFlicker(LockMouseCheckBox);
  NoFlicker(MouseSensitivityEdit);
  NoFlicker(Force2ButtonsCheckBox);
  NoFlicker(SwapButtonsCheckBox);
  NoFlicker(MouseDriverModelComboBox);
  NoFlicker(MouseMoveThresholdComboBox);
  NoFlicker(MouseImmediateCheckBox);
  NoFlicker(MouseModernCheckBox);
  NoFlicker(MouseNoGranularityCheckBox);
  NoFlicker(Ps2CheckBox);
  NoFlicker(Ps2ModelComboBox);
  NoFlicker(Ps2ReportRateComboBox);
  NoFlicker(VMwareCheckBox);
  NoFlicker(VirtualBoxCheckBox);
  NoFlicker(BiosPs2CheckBox);
  NoFlicker(CtmouseCheckBox);
  SwapButtonsCheckBox.OnClick := Force2ButtonsCheckBoxClick;

  FMouseDriverModelConfOpt := InitData.GameDB.ConfOpt.MouseDriverModelStaging;
  FMouseMoveThresholdConfOpt := InitData.GameDB.ConfOpt.MouseMoveThresholdStaging;
  FPs2ModelStagingConfOpt := InitData.GameDB.ConfOpt.Ps2MouseModelStaging;
  FPs2ModelXConfOpt := InitData.GameDB.ConfOpt.Ps2MouseModelX;
  FPs2ReportRateStagingConfOpt := InitData.GameDB.ConfOpt.Ps2ReportRateStaging;
  FPs2ReportRateXConfOpt := InitData.GameDB.ConfOpt.Ps2ReportRateX;

  LockMouseCheckBox.Caption := LanguageSetup.GameAutoLockMouse;
  LockMouseLabel.Caption := LanguageSetup.GameAutoLockMouseInfo;
  MouseSensitivityLabel.Caption := LanguageSetup.GameMouseSensitivity;
  Force2ButtonsCheckBox.Caption := LanguageSetup.GameForce2ButtonMouseMode;
  Force2ButtonsInfoLabel.Caption := 'This feature will enable the CTMOUSE mouse driver in autoexec.bat';
  if DirectoryExists(IncludeTrailingPathDelimiter(MakeAbsPath(PrgSetup.PathToFREEDOS, PrgSetup.BaseDir))) then
    Force2ButtonsInfoLabel.Font.Color := clGrayText
  else
    Force2ButtonsInfoLabel.Font.Color := clRed;
  SwapButtonsCheckBox.Caption := LanguageSetup.GameSwapMouseButtons;
  SwapButtonsInfoLabel.Caption := 'This feature will enable the CTMOUSE mouse driver in autoexec.bat';
  if DirectoryExists(IncludeTrailingPathDelimiter(MakeAbsPath(PrgSetup.PathToFREEDOS, PrgSetup.BaseDir))) then
    SwapButtonsInfoLabel.Font.Color := clGrayText
  else
    SwapButtonsInfoLabel.Font.Color := clRed;

  MouseDriverModelLabel.Caption := LanguageSetup.ProfileEditorMouseDriverModel;
  MouseMoveThresholdLabel.Caption := LanguageSetup.ProfileEditorMouseMoveThreshold;
  MouseDriverOptionsGroupBox.Caption := LanguageSetup.ProfileEditorMouseDriverOptions;
  MouseImmediateCheckBox.Caption := LanguageSetup.ProfileEditorMouseDriverImmediate;
  MouseModernCheckBox.Caption := LanguageSetup.ProfileEditorMouseDriverModern;
  MouseNoGranularityCheckBox.Caption := LanguageSetup.ProfileEditorMouseDriverNoGranularity;
  Ps2CheckBox.Caption := LanguageSetup.ProfileEditorMousePs2;
  Ps2ModelLabel.Caption := LanguageSetup.ProfileEditorMousePs2Model;
  Ps2ReportRateLabel.Caption := LanguageSetup.ProfileEditorMousePs2ReportRate;
  VMwareCheckBox.Caption := LanguageSetup.ProfileEditorMouseVMware;
  VirtualBoxCheckBox.Caption := LanguageSetup.ProfileEditorMouseVirtualBox;
  BiosPs2CheckBox.Caption := LanguageSetup.ProfileEditorMouseBiosPs2;
  CtmouseCheckBox.Caption := LanguageSetup.ProfileEditorMouseCtmouse;

  FillMouseModelCombo;
  RebuildComboFromConfOpt(MouseMoveThresholdComboBox, FMouseMoveThresholdConfOpt, '');

  InitData.OnShowFrame := ShowFrame;
  InitData.OnInvalidate := Invalidate;
  HelpContext := ID_ProfileEditMouse;
end;

procedure TModernProfileEditorMouseFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
var
  S: String;
begin
  FGame := Game;
  LockMouseCheckBox.Checked := Game.AutoLockMouse;
  MouseSensitivityEdit.Value := Game.MouseSensitivity;
  Force2ButtonsCheckBox.Checked := Game.Force2ButtonMouseMode;
  SwapButtonsCheckBox.Checked := Game.SwapMouseButtons;

  SelectMouseModel(Game.MouseDriverModel);
  if ComboHasValue(MouseMoveThresholdComboBox, Game.MouseMoveThreshold) then
    SelectComboValue(MouseMoveThresholdComboBox, Game.MouseMoveThreshold)
  else
    MouseMoveThresholdComboBox.ItemIndex := -1;

  S := ExtUpperCase(Game.MouseDriverOptions);
  MouseImmediateCheckBox.Checked := Pos('IMMEDIATE', S) > 0;
  MouseModernCheckBox.Checked := Pos('MODERN', S) > 0;
  MouseNoGranularityCheckBox.Checked := Pos('NO-GRANULARITY', S) > 0;

  Ps2CheckBox.Checked := Game.Ps2MouseEnabled;
  VMwareCheckBox.Checked := Game.VMwareMouse;
  VirtualBoxCheckBox.Checked := Game.VirtualBoxMouse;
  BiosPs2CheckBox.Checked := Game.BiosPs2;
  CtmouseCheckBox.Checked := Game.CtmouseEnabled;

  ApplyStagingMouseVisible;
  ApplyPs2Enable;
  ReloadPs2Combos(False);
end;

procedure TModernProfileEditorMouseFrame.GetGame(const Game: TGame);
var
  Opt: String;
begin
  Game.AutoLockMouse := LockMouseCheckBox.Checked;
  Game.MouseSensitivity := Min(1000, Max(1, MouseSensitivityEdit.Value));
  if Force2ButtonsCheckBox.Enabled then
    Game.Force2ButtonMouseMode := Force2ButtonsCheckBox.Checked;
  if SwapButtonsCheckBox.Enabled then
    Game.SwapMouseButtons := SwapButtonsCheckBox.Checked;
  if MouseDriverModelComboBox.Visible and (MouseDriverModelComboBox.ItemIndex >= 0) then
    Game.MouseDriverModel := TokenFromMouseModelCaption(MouseDriverModelComboBox.Items[MouseDriverModelComboBox.ItemIndex]);
  if MouseMoveThresholdComboBox.Visible and (MouseMoveThresholdComboBox.ItemIndex >= 0) then
    Game.MouseMoveThreshold := Trim(MouseMoveThresholdComboBox.Text);
  if MouseDriverOptionsGroupBox.Visible then begin
    Opt := '';
    if MouseImmediateCheckBox.Checked then Opt := 'immediate';
    if MouseModernCheckBox.Checked then begin
      if Opt <> '' then Opt := Opt + ' ';
      Opt := Opt + 'modern';
    end;
    if MouseNoGranularityCheckBox.Checked then begin
      if Opt <> '' then Opt := Opt + ' ';
      Opt := Opt + 'no-granularity';
    end;
    Game.MouseDriverOptions := Opt;
  end;
  if Ps2CheckBox.Enabled then
    Game.Ps2MouseEnabled := Ps2CheckBox.Checked;
  if Ps2ModelComboBox.Enabled and (Ps2ModelComboBox.ItemIndex >= 0) then
    Game.Ps2MouseModel := Trim(Ps2ModelComboBox.Items[Ps2ModelComboBox.ItemIndex]);
  if Ps2ReportRateComboBox.Enabled and (Ps2ReportRateComboBox.ItemIndex >= 0) then
    Game.Ps2ReportRate := Trim(Ps2ReportRateComboBox.Items[Ps2ReportRateComboBox.ItemIndex]);
  if VMwareCheckBox.Enabled then
    Game.VMwareMouse := VMwareCheckBox.Checked;
  if VirtualBoxCheckBox.Enabled then
    Game.VirtualBoxMouse := VirtualBoxCheckBox.Checked;
  if BiosPs2CheckBox.Enabled then
    Game.BiosPs2 := BiosPs2CheckBox.Checked;
  if Ps2CheckBox.Enabled and Ps2CheckBox.Checked and (GetSelectedDosBoxKind in [dbkStaging, dbkX]) then
    Game.CtmouseEnabled := CtmouseCheckBox.Checked;
end;

end.
