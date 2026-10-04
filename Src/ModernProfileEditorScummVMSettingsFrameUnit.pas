unit ModernProfileEditorScummVMSettingsFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Spin, GameDBUnit, ModernProfileEditorFormUnit,
  ScummVMGameOptions, ModernProfileEditorScummVMSettingsHelpers;

type
  TModernProfileEditorScummVMSettingsFrame = class(TFrame, IModernProfileEditorFrame)
    VariantLabel: TLabel;
    VariantComboBox: TComboBox;
    OptionsScrollBox: TScrollBox;
    procedure VariantComboBoxChange(Sender: TObject);
  private
    FOpts: TScummVMGameOptionArray;
    FCheckBoxes: array of TCheckBox;
    FSpinEdits: array of TSpinEdit;
    FIntLabels: array of TLabel;
    FSpecialCheckBoxes: array of TCheckBox;
    FHasSpecial: String;
    FData: TScummVMSettingsData;
    FStoredExtra: String;
    FSuppressChange: Boolean;
    LastGameName: String;
    CurrentGameName: PString;
    procedure ClearOptionControls;
    procedure RebuildVariantCombo(const GameId, PreferVariant: String);
    procedure RebuildOptionControls(const GameId, Variant: String);
    function SelectedGameId: String;
    function SelectedVariant: String;
    procedure CaptureValuesToStored;
    function SpecialCheckBoxesBlob: String;
    procedure ShowFrame(Sender: TObject);
    procedure ApplyGameId(const GameId, PreferVariant: String; const ResetStoredIfDifferent: Boolean);
  public
    procedure InitGUI(var InitData: TModernProfileEditorInitData);
    procedure SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
    procedure GetGame(const Game: TGame);
  end;

implementation

uses
  Math, VistaToolsUnit, LanguageSetupUnit;

{$R *.dfm}

procedure TModernProfileEditorScummVMSettingsFrame.ClearOptionControls;
var
  I: Integer;
begin
  for I := 0 to High(FCheckBoxes) do
    FreeAndNil(FCheckBoxes[I]);
  for I := 0 to High(FSpinEdits) do
    FreeAndNil(FSpinEdits[I]);
  for I := 0 to High(FIntLabels) do
    FreeAndNil(FIntLabels[I]);
  for I := 0 to High(FSpecialCheckBoxes) do
    FreeAndNil(FSpecialCheckBoxes[I]);
  SetLength(FCheckBoxes, 0);
  SetLength(FSpinEdits, 0);
  SetLength(FIntLabels, 0);
  SetLength(FSpecialCheckBoxes, 0);
  SetLength(FOpts, 0);
  FHasSpecial := '';
end;

function TModernProfileEditorScummVMSettingsFrame.SelectedGameId: String;
var
  Dummy: String;
begin
  Result := '';
  if (CurrentGameName = nil) or (Trim(CurrentGameName^) = '') then Exit;
  ScummVMSettingsParseGameToken(CurrentGameName^, Result, Dummy);
end;

function TModernProfileEditorScummVMSettingsFrame.SelectedVariant: String;
begin
  Result := '';
  if VariantComboBox.ItemIndex <= 0 then Exit;
  Result := VariantComboBox.Text;
end;

procedure TModernProfileEditorScummVMSettingsFrame.CaptureValuesToStored;
var
  BoolValues: array of Boolean;
  IntValues: array of Integer;
  I: Integer;
begin
  if Length(FOpts) = 0 then Exit;
  SetLength(BoolValues, Length(FOpts));
  SetLength(IntValues, Length(FOpts));
  for I := 0 to High(FOpts) do begin
    BoolValues[I] := FOpts[I].DefaultBool;
    IntValues[I] := FOpts[I].DefaultInt;
    if FOpts[I].Kind = sgokInteger then begin
      if (I <= High(FSpinEdits)) and (FSpinEdits[I] <> nil) then
        IntValues[I] := FSpinEdits[I].Value;
    end else if FOpts[I].Kind <> sgokSpecial then begin
      if (I <= High(FCheckBoxes)) and (FCheckBoxes[I] <> nil) then
        BoolValues[I] := FCheckBoxes[I].Checked;
    end;
  end;
  FStoredExtra := ScummVMSettingsJoinOptionsBlob(
    ScummVMSettingsEncodeOptions(FOpts, BoolValues, IntValues),
    SpecialCheckBoxesBlob);
end;

function TModernProfileEditorScummVMSettingsFrame.SpecialCheckBoxesBlob: String;
var
  G1, G2, G3, G4: Boolean;
begin
  Result := '';
  if FHasSpecial = '' then Exit;
  G1 := False;
  G2 := False;
  G3 := False;
  G4 := False;
  if SameText(FHasSpecial, 'macs2-enhancements') then begin
    if Length(FSpecialCheckBoxes) >= 2 then begin
      G2 := FSpecialCheckBoxes[0].Checked;
      G4 := FSpecialCheckBoxes[1].Checked;
    end;
  end else if Length(FSpecialCheckBoxes) >= 4 then begin
    G1 := FSpecialCheckBoxes[0].Checked;
    G2 := FSpecialCheckBoxes[1].Checked;
    G3 := FSpecialCheckBoxes[2].Checked;
    G4 := FSpecialCheckBoxes[3].Checked;
  end;
  Result := ScummVMSettingsEncodeEnhancementGroups(FHasSpecial, G1, G2, G3, G4);
end;

procedure TModernProfileEditorScummVMSettingsFrame.RebuildVariantCombo(const GameId, PreferVariant: String);
var
  St: TStringList;
  Prefer: String;
  Idx, I: Integer;
begin
  Prefer := Trim(PreferVariant);
  FSuppressChange := True;
  try
    VariantComboBox.Items.Clear;
    VariantComboBox.Items.Add('');
    St := TStringList.Create;
    try
      ScummVMSettingsCollectVariants(GameId, St);
      VariantComboBox.Items.AddStrings(St);
    finally
      St.Free;
    end;
    Idx := 0;
    if Prefer <> '' then
      for I := 0 to VariantComboBox.Items.Count - 1 do
        if SameText(VariantComboBox.Items[I], Prefer) then begin
          Idx := I;
          Break;
        end;
    VariantComboBox.ItemIndex := Idx;
    VariantComboBox.Enabled := VariantComboBox.Items.Count > 1;
  finally
    FSuppressChange := False;
  end;
end;

procedure TModernProfileEditorScummVMSettingsFrame.RebuildOptionControls(const GameId, Variant: String);
var
  I, Y, RowH, Gap, LineH: Integer;
  CB: TCheckBox;
  SE: TSpinEdit;
  Lbl: TLabel;
  BoolValues: array of Boolean;
  IntValues: array of Integer;
  G1, G2, G3, G4: Boolean;
  SpecialCaptions: array[0..3] of String;
  SpecialStates: array[0..3] of Boolean;
  S: Integer;
begin
  ClearOptionControls;
  FOpts := ScummVMSettingsLoadOptions(GameId, Variant);
  if Length(FOpts) > 30 then
    SetLength(FOpts, 30);
  SetLength(FCheckBoxes, Length(FOpts));
  SetLength(FSpinEdits, Length(FOpts));
  SetLength(FIntLabels, Length(FOpts));
  SetLength(BoolValues, Length(FOpts));
  SetLength(IntValues, Length(FOpts));
  ScummVMSettingsValuesFromStored(FOpts, FStoredExtra, BoolValues, IntValues);
  Y := 0;
  LineH := Abs(Font.Height);
  if LineH <= 0 then LineH := 13;
  Gap := (LineH * 5) div 4; { +0.25 line height between options }
  RowH := Max(LineH + 8, 22);
  for I := 0 to High(FOpts) do begin
    if (FOpts[I].Kind = sgokSpecial) and SameText(FOpts[I].Caption, 'scumm-enhancements') then begin
      FHasSpecial := FOpts[I].Caption;
      SpecialCaptions[0] := 'Fix original bugs';
      SpecialCaptions[1] := 'Audio-visual improvements';
      SpecialCaptions[2] := 'Restored content';
      SpecialCaptions[3] := 'Modern UI/UX adjustments';
      ScummVMSettingsReadEnhancementGroups(FStoredExtra, G1, G2, G3, G4);
      SpecialStates[0] := G1;
      SpecialStates[1] := G2;
      SpecialStates[2] := G3;
      SpecialStates[3] := G4;
      SetLength(FSpecialCheckBoxes, 4);
      for S := 0 to 3 do begin
        CB := TCheckBox.Create(Self);
        CB.Parent := OptionsScrollBox;
        CB.Left := 0;
        CB.Top := Y;
        CB.Width := OptionsScrollBox.ClientWidth - 8;
        CB.Anchors := [akLeft, akTop, akRight];
        CB.Caption := SpecialCaptions[S];
        CB.Checked := SpecialStates[S];
        CB.Tag := I;
        NoFlicker(CB);
        FSpecialCheckBoxes[S] := CB;
        Inc(Y, CB.Height + Gap);
      end;
    end else if (FOpts[I].Kind = sgokSpecial) and SameText(FOpts[I].Caption, 'macs2-enhancements') then begin
      FHasSpecial := FOpts[I].Caption;
      SpecialCaptions[0] := 'Audio-visual improvements';
      SpecialCaptions[1] := 'Modern UI/UX adjustments';
      ScummVMSettingsReadEnhancementGroups(FStoredExtra, G1, G2, G3, G4);
      SpecialStates[0] := G2;
      SpecialStates[1] := G4;
      SetLength(FSpecialCheckBoxes, 2);
      for S := 0 to 1 do begin
        CB := TCheckBox.Create(Self);
        CB.Parent := OptionsScrollBox;
        CB.Left := 0;
        CB.Top := Y;
        CB.Width := OptionsScrollBox.ClientWidth - 8;
        CB.Anchors := [akLeft, akTop, akRight];
        CB.Caption := SpecialCaptions[S];
        CB.Checked := SpecialStates[S];
        CB.Tag := I;
        NoFlicker(CB);
        FSpecialCheckBoxes[S] := CB;
        Inc(Y, CB.Height + Gap);
      end;
    end else if FOpts[I].Kind = sgokInteger then begin
      SE := TSpinEdit.Create(Self);
      SE.Parent := OptionsScrollBox;
      SE.Left := 0;
      SE.Top := Y;
      SE.Width := 56;
      SE.Anchors := [akLeft, akTop];
      SE.MinValue := -100000;
      SE.MaxValue := 100000;
      SE.Value := IntValues[I];
      SE.Tag := I;
      NoFlicker(SE);
      FSpinEdits[I] := SE;

      Lbl := TLabel.Create(Self);
      Lbl.Parent := OptionsScrollBox;
      Lbl.Left := SE.Left + SE.Width + 8;
      Lbl.Top := Y + 4;
      Lbl.Caption := FOpts[I].Caption;
      Lbl.Anchors := [akLeft, akTop];
      FIntLabels[I] := Lbl;

      Inc(Y, Max(SE.Height, RowH) + Gap);
    end else begin
      CB := TCheckBox.Create(Self);
      CB.Parent := OptionsScrollBox;
      CB.Left := 0;
      CB.Top := Y;
      CB.Width := OptionsScrollBox.ClientWidth - 8;
      CB.Anchors := [akLeft, akTop, akRight];
      CB.Caption := FOpts[I].Caption;
      CB.Checked := BoolValues[I];
      CB.Tag := I;
      NoFlicker(CB);
      FCheckBoxes[I] := CB;
      Inc(Y, CB.Height + Gap);
    end;
  end;
end;

procedure TModernProfileEditorScummVMSettingsFrame.InitGUI(var InitData: TModernProfileEditorInitData);
begin
  InitData.OnShowFrame := ShowFrame;
  CurrentGameName := InitData.CurrentScummVMGameName;
  LastGameName := '';

  NoFlicker(VariantComboBox);
  NoFlicker(OptionsScrollBox);

  VariantLabel.Caption := LanguageSetup.ProfileEditorScummVMSettingsVariant;

  FSuppressChange := True;
  try
    VariantComboBox.Items.Clear;
    VariantComboBox.Items.Add('');
    VariantComboBox.ItemIndex := 0;
    VariantComboBox.Enabled := False;
  finally
    FSuppressChange := False;
  end;

  ClearOptionControls;
end;

procedure TModernProfileEditorScummVMSettingsFrame.ApplyGameId(const GameId, PreferVariant: String; const ResetStoredIfDifferent: Boolean);
var
  Id: String;
begin
  Id := ScummVMSettingsBareGameId(GameId);
  if ResetStoredIfDifferent and (not SameText(FData.GameId, Id)) then
    FStoredExtra := '';
  LastGameName := LowerCase(Id);
  RebuildVariantCombo(Id, PreferVariant);
  RebuildOptionControls(Id, SelectedVariant);
end;

procedure TModernProfileEditorScummVMSettingsFrame.ShowFrame(Sender: TObject);
var
  Id, Prefer: String;
begin
  Id := SelectedGameId;
  if LowerCase(Id) = LastGameName then Exit;
  Prefer := '';
  if SameText(FData.GameId, Id) then Prefer := FData.Variant;
  ApplyGameId(Id, Prefer, True);
end;

procedure TModernProfileEditorScummVMSettingsFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
var
  Id, Prefer: String;
begin
  ScummVMSettingsLoadData(Game.ScummVMGame, Game.ScummGameOptions, FData);
  if Trim(Game.ScummVMExtraVariant) <> '' then
    FData.Variant := Trim(Game.ScummVMExtraVariant);
  FStoredExtra := FData.ExtraOptions;
  Id := SelectedGameId;
  if Id = '' then Id := FData.GameId;
  Prefer := '';
  if SameText(FData.GameId, Id) then Prefer := FData.Variant;
  ApplyGameId(Id, Prefer, False);
end;

procedure TModernProfileEditorScummVMSettingsFrame.GetGame(const Game: TGame);
var
  BoolValues: array of Boolean;
  IntValues: array of Integer;
  I: Integer;
  OutData: TScummVMSettingsData;
  GameToken, Id, Variant: String;
begin
  Id := SelectedGameId;
  if Id = '' then Id := FData.GameId;
  if LowerCase(Id) = LastGameName then
    Variant := SelectedVariant
  else if SameText(FData.GameId, Id) then
    Variant := FData.Variant
  else
    Variant := '';
  if LowerCase(Id) = LastGameName then begin
    SetLength(BoolValues, Length(FOpts));
    SetLength(IntValues, Length(FOpts));
    for I := 0 to High(FOpts) do begin
      BoolValues[I] := FOpts[I].DefaultBool;
      IntValues[I] := FOpts[I].DefaultInt;
      if FOpts[I].Kind = sgokInteger then begin
        if (I <= High(FSpinEdits)) and (FSpinEdits[I] <> nil) then
          IntValues[I] := FSpinEdits[I].Value;
      end else if FOpts[I].Kind <> sgokSpecial then begin
        if (I <= High(FCheckBoxes)) and (FCheckBoxes[I] <> nil) then
          BoolValues[I] := FCheckBoxes[I].Checked;
      end;
    end;
    ScummVMSettingsSaveData(FData, Id, True, Variant, FOpts, BoolValues, IntValues, OutData, GameToken);
    OutData.ExtraOptions := ScummVMSettingsJoinOptionsBlob(OutData.ExtraOptions, SpecialCheckBoxesBlob);
  end else begin
    OutData.GameId := Id;
    OutData.Variant := Variant;
    if SameText(FData.GameId, Id) then
      OutData.ExtraOptions := FStoredExtra
    else
      OutData.ExtraOptions := '';
  end;
  Game.ScummVMExtraVariant := Variant;
  Game.ScummGameOptions := OutData.ExtraOptions;
  if FHasSpecial <> '' then
    Game.ScummVMHasSpecialOptions := 'enhancements'
  else
    Game.ScummVMHasSpecialOptions := '';
  FData := OutData;
  FStoredExtra := OutData.ExtraOptions;
end;

procedure TModernProfileEditorScummVMSettingsFrame.VariantComboBoxChange(Sender: TObject);
begin
  if FSuppressChange then Exit;
  CaptureValuesToStored;
  RebuildOptionControls(LastGameName, SelectedVariant);
end;

end.
