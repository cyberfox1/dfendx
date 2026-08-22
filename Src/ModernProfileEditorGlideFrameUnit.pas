unit ModernProfileEditorGlideFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, GameDBUnit, ModernProfileEditorFormUnit,
  PrgConsts;

type
  TModernProfileEditorGlideFrame = class(TFrame, IModernProfileEditorFrame)
    ActivateGlideCheckBox: TCheckBox;
    GlideEmulationLabel: TLabel;
    GlideEmulationComboBox: TComboBox;
    GlideEmulationPortLabel: TLabel;
    GlideEmulationPortComboBox: TComboBox;
    GlideEmulationLFBLabel: TLabel;
    GlideEmulationLFBComboBox: TComboBox;
    cbVoodooMemory: TComboBox;
    lblVoodooMemSize: TLabel;
    cbVoodooPerf: TComboBox;
    lblVoodooCard: TLabel;
    cbVoodooThreads: TComboBox;
    lblVoodooThreads: TLabel;
    cbVoodooBilinear: TComboBox;
    lblBilinearFilt: TLabel;
    lblVoodoScale: TLabel;
    cbVoodooGamma: TComboBox;
    lblVoodooGamma: TLabel;
    imgVoodooLogo: TImage;
    cbVoodooScale: TComboBox;
  private
    FTempGame: TGame;
    FGlideEmulationConfOpt: String;
    FGlideEmulationPortConfOpt: String;
    FGlideEmulationLFBConfOpt: String;
    FGlideEmulationLFBXConfOpt: String;
    FGlideVoodooMemConfOpt: String;
    FGlideVoodooMemPureConfOpt: String;
    FGlideVoodooCardXConfOpt: String;
    FGlideVoodooPerfPureConfOpt: String;
    FGlideVoodooThreadsConfOpt: String;
    FGlideVoodooBilinearConfOpt: String;
    FGlideVoodooScaleConfOpt: String;
    FGlideVoodooGammaConfOpt: String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    procedure GetGlideCombos(var Combos: array of TComboBox);
    procedure ApplyKindEnable;
    procedure FillEnabledComboLists;
    procedure ApplyGameFieldsIfUnset;
    procedure SetGlideCombos(const KeepState: Boolean);
    procedure LoadVoodooLogo;
    procedure Invalidate(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure InitGUI(var InitData: TModernProfileEditorInitData);
    procedure SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
    procedure GetGame(const Game: TGame);
    procedure ShowFrame(Sender: TObject);
  end;

implementation

uses
  Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools,
  PrgSetupUnit, GameDBHelpers, GameDBToolsHelpers, HelpConsts;

{$R *.dfm}

function ResolveVoodooLogoPath: String;
begin
  Result := ProgramInstallDir + IconSetsFolder + '\Modern\glide.png';
  if not FileExists(Result) then
    Result := PrgDataDir + IconSetsFolder + '\Modern\glide.png';
  if not FileExists(Result) then
    Result := '';
end;

constructor TModernProfileEditorGlideFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame := nil;
  if AOwner is TModernProfileEditorForm then
    FTempGame := TModernProfileEditorForm(AOwner).TempGame;
end;

function TModernProfileEditorGlideFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  if (FTempGame = nil) and (Owner is TModernProfileEditorForm) then
    FTempGame := TModernProfileEditorForm(Owner).TempGame;
  if FTempGame <> nil then
    Result := FTempGame.DosBoxKind
  else
    Result := dbkUnknown;
end;

procedure TModernProfileEditorGlideFrame.GetGlideCombos(var Combos: array of TComboBox);
begin
  Combos[0] := GlideEmulationComboBox;
  Combos[1] := GlideEmulationPortComboBox;
  Combos[2] := GlideEmulationLFBComboBox;
  Combos[3] := cbVoodooMemory;
  Combos[4] := cbVoodooPerf;
  Combos[5] := cbVoodooThreads;
  Combos[6] := cbVoodooBilinear;
  Combos[7] := cbVoodooScale;
  Combos[8] := cbVoodooGamma;
end;

procedure TModernProfileEditorGlideFrame.ApplyKindEnable;
var
  Kind: TDOSBoxKind;
  OnAny, OnClassic, OnX, OnStagingNew, OnPure: Boolean;
  OnPort, OnLFB, OnMem, OnCardOrPerf, OnThreads, OnBilinear, OnScale, OnGamma: Boolean;
begin
  { Enable only options that exist for the selected DOSBox kind.
    Staging old (<0.83): no [voodoo] conf block like 0.83+ — only basic enable/mode. }
  Kind := GetSelectedDosBoxKind;
  OnX := Kind = dbkX;
  OnStagingNew := (Kind = dbkStaging) and (FTempGame <> nil) and (not FTempGame.IsOldStaging);
  OnPure := Kind = dbkPure;
  OnClassic := Kind = dbkStandard;
  OnAny := OnClassic or OnX or (Kind = dbkStaging) or OnPure;

  OnPort := OnClassic; { grport; dead on current X }
  OnLFB := OnClassic or OnX;
  OnMem := OnX or OnStagingNew or OnPure;
  OnCardOrPerf := OnX or OnPure; { X: voodoo_card; Pure: dosbox_pure_voodoo_perf }
  OnThreads := OnStagingNew;
  OnBilinear := OnStagingNew;
  OnScale := OnPure;
  OnGamma := OnPure;

  ActivateGlideCheckBox.Enabled := OnAny;
  GlideEmulationLabel.Enabled := OnAny;
  GlideEmulationComboBox.Enabled := OnAny;

  GlideEmulationPortLabel.Enabled := OnPort;
  GlideEmulationPortComboBox.Enabled := OnPort;

  GlideEmulationLFBLabel.Enabled := OnLFB;
  GlideEmulationLFBComboBox.Enabled := OnLFB;

  lblVoodooMemSize.Enabled := OnMem;
  cbVoodooMemory.Enabled := OnMem;

  lblVoodooCard.Enabled := OnCardOrPerf;
  cbVoodooPerf.Enabled := OnCardOrPerf;

  lblVoodooThreads.Enabled := OnThreads;
  cbVoodooThreads.Enabled := OnThreads;

  lblBilinearFilt.Enabled := OnBilinear;
  cbVoodooBilinear.Enabled := OnBilinear;

  lblVoodoScale.Enabled := OnScale;
  cbVoodooScale.Enabled := OnScale;

  lblVoodooGamma.Enabled := OnGamma;
  cbVoodooGamma.Enabled := OnGamma;
end;

procedure TModernProfileEditorGlideFrame.FillEnabledComboLists;
var
  Kind: TDOSBoxKind;
  ListSrc: String;
begin
  Kind := GetSelectedDosBoxKind;

  if GlideEmulationComboBox.Enabled then
    RebuildComboFromConfOpt(GlideEmulationComboBox, FGlideEmulationConfOpt, '');
  if GlideEmulationPortComboBox.Enabled then
    RebuildComboFromConfOpt(GlideEmulationPortComboBox, FGlideEmulationPortConfOpt, '');

  if GlideEmulationLFBComboBox.Enabled then begin
    if Kind = dbkX then
      ListSrc := FGlideEmulationLFBXConfOpt
    else
      ListSrc := FGlideEmulationLFBConfOpt;
    RebuildComboFromConfOpt(GlideEmulationLFBComboBox, ListSrc, '');
  end;

  if cbVoodooMemory.Enabled then begin
    if Kind = dbkPure then
      ListSrc := FGlideVoodooMemPureConfOpt
    else
      ListSrc := FGlideVoodooMemConfOpt;
    RebuildComboFromConfOpt(cbVoodooMemory, ListSrc, '');
  end;

  if cbVoodooPerf.Enabled then begin
    if Kind = dbkPure then
      ListSrc := FGlideVoodooPerfPureConfOpt
    else
      ListSrc := FGlideVoodooCardXConfOpt;
    RebuildComboFromConfOpt(cbVoodooPerf, ListSrc, '');
  end;

  if cbVoodooThreads.Enabled then
    RebuildComboFromConfOpt(cbVoodooThreads, FGlideVoodooThreadsConfOpt, '');
  if cbVoodooBilinear.Enabled then
    RebuildComboFromConfOpt(cbVoodooBilinear, FGlideVoodooBilinearConfOpt, '');
  if cbVoodooScale.Enabled then
    RebuildComboFromConfOpt(cbVoodooScale, FGlideVoodooScaleConfOpt, '');
  if cbVoodooGamma.Enabled then
    RebuildComboFromConfOpt(cbVoodooGamma, FGlideVoodooGammaConfOpt, '');
end;

procedure TModernProfileEditorGlideFrame.ApplyGameFieldsIfUnset;
var
  S: String;
begin
  if FTempGame = nil then Exit;

  if GlideEmulationComboBox.Enabled and (GlideEmulationComboBox.ItemIndex < 0) then begin
    S := Trim(ExtUpperCase(FTempGame.GlideEmulation));
    if (S = '0') or (S = 'FALSE') then S := LanguageSetup.Off
    else if (S = '1') or (S = 'TRUE') then S := LanguageSetup.On
    else S := Trim(FTempGame.GlideEmulation);
    if (S <> '') and ComboHasValue(GlideEmulationComboBox, S) then
      SelectComboValue(GlideEmulationComboBox, S);
  end;

  if GlideEmulationPortComboBox.Enabled and (GlideEmulationPortComboBox.ItemIndex < 0) then begin
    S := Trim(FTempGame.GlidePort);
    if (S <> '') and ComboHasValue(GlideEmulationPortComboBox, S) then
      SelectComboValue(GlideEmulationPortComboBox, S);
  end;

  if GlideEmulationLFBComboBox.Enabled and (GlideEmulationLFBComboBox.ItemIndex < 0) then begin
    S := Trim(FTempGame.GlideLFB);
    if (S <> '') and ComboHasValue(GlideEmulationLFBComboBox, S) then
      SelectComboValue(GlideEmulationLFBComboBox, S);
  end;

  if cbVoodooMemory.Enabled and (cbVoodooMemory.ItemIndex < 0) then begin
    S := Trim(FTempGame.GlideVoodooMem);
    if (S <> '') and ComboHasValue(cbVoodooMemory, S) then
      SelectComboValue(cbVoodooMemory, S);
  end;

  if cbVoodooPerf.Enabled and (cbVoodooPerf.ItemIndex < 0) then begin
    if GetSelectedDosBoxKind = dbkPure then
      S := Trim(FTempGame.GlidePurePerf)
    else
      S := Trim(FTempGame.GlideVoodooCard);
    if (S <> '') and ComboHasValue(cbVoodooPerf, S) then
      SelectComboValue(cbVoodooPerf, S);
  end;

  if cbVoodooThreads.Enabled and (cbVoodooThreads.ItemIndex < 0) then begin
    S := Trim(FTempGame.GlideVoodooThreads);
    if (S <> '') and ComboHasValue(cbVoodooThreads, S) then
      SelectComboValue(cbVoodooThreads, S);
  end;

  if cbVoodooBilinear.Enabled and (cbVoodooBilinear.ItemIndex < 0) then begin
    S := Trim(FTempGame.GlideBilinear);
    if (S <> '') and ComboHasValue(cbVoodooBilinear, S) then
      SelectComboValue(cbVoodooBilinear, S);
  end;

  if cbVoodooScale.Enabled and (cbVoodooScale.ItemIndex < 0) then begin
    S := Trim(FTempGame.GlideVoodooScale);
    if (S <> '') and ComboHasValue(cbVoodooScale, S) then
      SelectComboValue(cbVoodooScale, S);
  end;

  if cbVoodooGamma.Enabled and (cbVoodooGamma.ItemIndex < 0) then begin
    S := Trim(FTempGame.GlideVoodooGamma);
    if (S <> '') and ComboHasValue(cbVoodooGamma, S) then
      SelectComboValue(cbVoodooGamma, S);
  end;
end;

procedure TModernProfileEditorGlideFrame.SetGlideCombos(const KeepState: Boolean);
var
  Combos: array[0..8] of TComboBox;
  Saved: array[0..8] of String;
  I: Integer;
begin
  GetGlideCombos(Combos);

  { 1) Save current selections }
  for I := 0 to 8 do
    if Combos[I].ItemIndex >= 0 then
      Saved[I] := Combos[I].Items[Combos[I].ItemIndex]
    else
      Saved[I] := '';

  { 2) All combos → -1; disable those invalid for kind }
  for I := 0 to 8 do
    SetComboNoSelect(Combos[I]);
  ApplyKindEnable;

  { 3) Load lists for enabled combos (selection left at -1) }
  FillEnabledComboLists;

  { 4) Restore previous UI state when redisplaying }
  if KeepState then
    for I := 0 to 8 do
      if Combos[I].Enabled and (Saved[I] <> '') and ComboHasValue(Combos[I], Saved[I]) then
        SelectComboValue(Combos[I], Saved[I]);

  { 5) Fill remaining -1 from TGame when field is valid for current list }
  ApplyGameFieldsIfUnset;
end;

procedure TModernProfileEditorGlideFrame.LoadVoodooLogo;
var
  Path: String;
  P: TPicture;
begin
  imgVoodooLogo.Stretch := True;
  imgVoodooLogo.Proportional := True;
  imgVoodooLogo.Center := True;
  imgVoodooLogo.Picture.Assign(nil);
  Path := ResolveVoodooLogoPath;
  if Path = '' then Exit;
  P := LoadImageFromFile(Path);
  if P = nil then Exit;
  try
    try
      imgVoodooLogo.Picture.Assign(P);
    except
    end;
  finally
    P.Free;
  end;
end;

procedure TModernProfileEditorGlideFrame.InitGUI(var InitData: TModernProfileEditorInitData);
var
  St: TStringList;
  I: Integer;
  S: String;
begin
  InitData.OnShowFrame := ShowFrame;
  InitData.OnInvalidate := Invalidate;

  NoFlicker(ActivateGlideCheckBox);
  NoFlicker(GlideEmulationComboBox);
  NoFlicker(GlideEmulationPortComboBox);
  NoFlicker(GlideEmulationLFBComboBox);
  NoFlicker(cbVoodooMemory);
  NoFlicker(cbVoodooPerf);
  NoFlicker(cbVoodooThreads);
  NoFlicker(cbVoodooBilinear);
  NoFlicker(cbVoodooScale);
  NoFlicker(cbVoodooGamma);

  ActivateGlideCheckBox.Caption := LanguageSetup.ProfileEditorGlideEnabled;
  GlideEmulationLabel.Caption := LanguageSetup.GameGlideEmulation;
  GlideEmulationPortLabel.Caption := LanguageSetup.GameGlideEmulationPort;
  GlideEmulationLFBLabel.Caption := LanguageSetup.GameGlideEmulationLFB;
  lblVoodooMemSize.Caption := LanguageSetup.GameGlideVoodooMem;
  lblVoodooCard.Caption := LanguageSetup.GameGlideVoodooCard;
  lblVoodooThreads.Caption := LanguageSetup.GameGlideVoodooThreads;
  lblBilinearFilt.Caption := LanguageSetup.GameGlideBilinear;
  lblVoodoScale.Caption := LanguageSetup.GameGlideScale;
  lblVoodooGamma.Caption := LanguageSetup.GameGlideGamma;

  St := ValueToList(InitData.GameDB.ConfOpt.GlideEmulation, ',');
  for I := 0 to St.Count - 1 do begin
    S := Trim(ExtUpperCase(St[I]));
    if S = 'FALSE' then St[I] := LanguageSetup.Off;
    if S = 'TRUE' then St[I] := LanguageSetup.On;
  end;
  FGlideEmulationConfOpt := '';
  for I := 0 to St.Count - 1 do begin
    if I > 0 then FGlideEmulationConfOpt := FGlideEmulationConfOpt + ',';
    FGlideEmulationConfOpt := FGlideEmulationConfOpt + St[I];
  end;
  St.Free;

  FGlideEmulationPortConfOpt := InitData.GameDB.ConfOpt.GlideEmulationPort;
  FGlideEmulationLFBConfOpt := InitData.GameDB.ConfOpt.GlideEmulationLFB;
  FGlideEmulationLFBXConfOpt := InitData.GameDB.ConfOpt.GlideEmulationLFBX;
  FGlideVoodooMemConfOpt := InitData.GameDB.ConfOpt.GlideVoodooMem;
  FGlideVoodooMemPureConfOpt := InitData.GameDB.ConfOpt.GlideVoodooMemPure;
  FGlideVoodooCardXConfOpt := InitData.GameDB.ConfOpt.GlideVoodooCardX;
  FGlideVoodooPerfPureConfOpt := InitData.GameDB.ConfOpt.GlideVoodooPerfPure;
  FGlideVoodooThreadsConfOpt := InitData.GameDB.ConfOpt.GlideVoodooThreads;
  FGlideVoodooBilinearConfOpt := InitData.GameDB.ConfOpt.GlideVoodooBilinear;
  FGlideVoodooScaleConfOpt := InitData.GameDB.ConfOpt.GlideVoodooScale;
  FGlideVoodooGammaConfOpt := InitData.GameDB.ConfOpt.GlideVoodooGamma;

  LoadVoodooLogo;

  HelpContext := ID_ProfileEditGraphics;
end;

procedure TModernProfileEditorGlideFrame.Invalidate(Sender: TObject);
var
  Combos: array[0..8] of TComboBox;
  I: Integer;
begin
  GetGlideCombos(Combos);
  for I := 0 to 8 do
    SetComboNoSelect(Combos[I]);
end;

procedure TModernProfileEditorGlideFrame.ShowFrame(Sender: TObject);
begin
  if (FTempGame = nil) and (Owner is TModernProfileEditorForm) then
    FTempGame := TModernProfileEditorForm(Owner).TempGame;
  SetGlideCombos(True);
end;

procedure TModernProfileEditorGlideFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
begin
  if (FTempGame = nil) and (Owner is TModernProfileEditorForm) then
    FTempGame := TModernProfileEditorForm(Owner).TempGame;

  ActivateGlideCheckBox.Checked := Game.GlideEnabled;
  SetGlideCombos(False);
end;

procedure TModernProfileEditorGlideFrame.GetGame(const Game: TGame);
var
  S: String;
  Kind: TDOSBoxKind;
begin
  Kind := GetSelectedDosBoxKind;

  Game.GlideEnabled := ActivateGlideCheckBox.Checked;

  if GlideEmulationComboBox.ItemIndex >= 0 then begin
    S := GlideEmulationComboBox.Items[GlideEmulationComboBox.ItemIndex];
    if S = LanguageSetup.On then S := 'true';
    if S = LanguageSetup.Off then S := 'false';
    Game.GlideEmulation := S;
  end;
  if GlideEmulationPortComboBox.ItemIndex >= 0 then
    Game.GlidePort := GlideEmulationPortComboBox.Items[GlideEmulationPortComboBox.ItemIndex];
  if GlideEmulationLFBComboBox.ItemIndex >= 0 then
    Game.GlideLFB := GlideEmulationLFBComboBox.Items[GlideEmulationLFBComboBox.ItemIndex];
  if cbVoodooMemory.ItemIndex >= 0 then
    Game.GlideVoodooMem := cbVoodooMemory.Items[cbVoodooMemory.ItemIndex];
  if cbVoodooPerf.ItemIndex >= 0 then begin
    if Kind = dbkPure then
      Game.GlidePurePerf := cbVoodooPerf.Items[cbVoodooPerf.ItemIndex]
    else if Kind = dbkX then
      Game.GlideVoodooCard := cbVoodooPerf.Items[cbVoodooPerf.ItemIndex];
  end;
  if cbVoodooThreads.ItemIndex >= 0 then
    Game.GlideVoodooThreads := cbVoodooThreads.Items[cbVoodooThreads.ItemIndex];
  if cbVoodooBilinear.ItemIndex >= 0 then
    Game.GlideBilinear := cbVoodooBilinear.Items[cbVoodooBilinear.ItemIndex];
  if cbVoodooScale.ItemIndex >= 0 then
    Game.GlideVoodooScale := cbVoodooScale.Items[cbVoodooScale.ItemIndex];
  if cbVoodooGamma.ItemIndex >= 0 then
    Game.GlideVoodooGamma := cbVoodooGamma.Items[cbVoodooGamma.ItemIndex];
end;

end.
