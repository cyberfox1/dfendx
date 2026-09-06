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
    procedure Force2ButtonsCheckBoxClick(Sender: TObject);
  private
    FTempGame: TGame;
    FMouseDriverModelConfOpt: String;
    FMouseMoveThresholdConfOpt: String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    function IsNewStaging: Boolean;
    function CaptionFromMouseModelToken(const Token: String): String;
    function TokenFromMouseModelCaption(const Caption: String): String;
    procedure FillMouseModelCombo;
    procedure SelectMouseModel(const Token: String);
    procedure ApplyStagingMouseVisible;
    procedure ApplyForce2ButtonModel;
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

procedure TModernProfileEditorMouseFrame.ApplyForce2ButtonModel;
begin
  if not IsNewStaging then Exit;
  if Force2ButtonsCheckBox.Checked then begin
    SelectMouseModel('2button');
    MouseDriverModelComboBox.Enabled := False;
  end else
    MouseDriverModelComboBox.Enabled := True;
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
  if Vis then
    ApplyForce2ButtonModel
  else
    MouseDriverModelComboBox.Enabled := True;
end;

procedure TModernProfileEditorMouseFrame.Force2ButtonsCheckBoxClick(Sender: TObject);
begin
  ApplyForce2ButtonModel;
end;

procedure TModernProfileEditorMouseFrame.ShowFrame(Sender: TObject);
begin
  ApplyStagingMouseVisible;
end;

procedure TModernProfileEditorMouseFrame.Invalidate(Sender: TObject);
begin
  ApplyStagingMouseVisible;
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

  FMouseDriverModelConfOpt := InitData.GameDB.ConfOpt.MouseDriverModelStaging;
  FMouseMoveThresholdConfOpt := InitData.GameDB.ConfOpt.MouseMoveThresholdStaging;

  LockMouseCheckBox.Caption := LanguageSetup.GameAutoLockMouse;
  LockMouseLabel.Caption := LanguageSetup.GameAutoLockMouseInfo;
  MouseSensitivityLabel.Caption := LanguageSetup.GameMouseSensitivity;
  Force2ButtonsCheckBox.Caption := LanguageSetup.GameForce2ButtonMouseMode;
  Force2ButtonsInfoLabel.Caption := LanguageSetup.ProfileEditorNeedFreeDOS;
  if DirectoryExists(IncludeTrailingPathDelimiter(MakeAbsPath(PrgSetup.PathToFREEDOS, PrgSetup.BaseDir))) then
    Force2ButtonsInfoLabel.Font.Color := clGrayText
  else
    Force2ButtonsInfoLabel.Font.Color := clRed;
  SwapButtonsCheckBox.Caption := LanguageSetup.GameSwapMouseButtons;
  SwapButtonsInfoLabel.Caption := LanguageSetup.ProfileEditorNeedFreeDOS;
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

  ApplyStagingMouseVisible;
end;

procedure TModernProfileEditorMouseFrame.GetGame(const Game: TGame);
var
  Opt: String;
begin
  Game.AutoLockMouse := LockMouseCheckBox.Checked;
  Game.MouseSensitivity := Min(1000, Max(1, MouseSensitivityEdit.Value));
  Game.Force2ButtonMouseMode := Force2ButtonsCheckBox.Checked;
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
end;

end.
