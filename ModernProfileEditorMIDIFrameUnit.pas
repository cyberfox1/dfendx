unit ModernProfileEditorMIDIFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, ExtCtrls, GameDBUnit, ModernProfileEditorFormUnit, Vcl.Mask,
  Vcl.ExtDlgs, Vcl.Buttons, Vcl.ComCtrls, PrgConsts;

type
  TModernProfileEditorMIDIFrame = class(TFrame, IModernProfileEditorFrame)
    TypeLabel: TLabel;
    TypeComboBox: TComboBox;
    DeviceLabel: TLabel;
    DeviceComboBox: TComboBox;
    AdditionalSettingsEdit: TLabeledEdit;
    MIDISelectButton: TButton;
    MIDISelectListBox: TListBox;
    MIDISelectLabel1: TLabel;
    MIDISelectLabel2: TLabel;
    InfoLabel: TLabel;
    MT32SettingsGroupBox: TGroupBox;
    MT32ModeComboBox: TComboBox;
    MT32TimeComboBox: TComboBox;
    MT32LevelComboBox: TComboBox;
    MT32ModeLabel: TLabel;
    MT32TimeLabel: TLabel;
    MT32LevelLabel: TLabel;
    FluidSynthGroupBox: TGroupBox;
    FluidSynthPathBox: TLabeledEdit;
    lbFluidSynthGainValue: TLabeledEdit;
    BtnFluidSynthPath: TSpeedButton;
    tbFluidSynthGainSlider: TTrackBar;
    procedure MIDISelectButtonClick(Sender: TObject);
    procedure MIDISelectListBoxClick(Sender: TObject);
    procedure DeviceComboBoxChange(Sender: TObject);
    procedure BtnFluidSynthPathClick(Sender: TObject);
    procedure tbFluidSynthGainSliderChange(Sender: TObject);
  private
    FLoadedFluidPath: String;
    FLoadedFluidGain: String;
    FUpdatingFluidGainUI: Boolean;
    ProfileDOSBoxInstallation: PString;
    FMIDIDeviceConfOpt: String;
    LastMIDIDevice: String;
    procedure ApplyFluidSynthPathVisibility;
    procedure ClearFluidSynthUI;
    procedure LoadFluidGainUI(const GainStr: String);
    function FormatFluidGainDisplay(const N: Integer): String;
    function IsFluidSynthDevice: Boolean;
    function GetDOSBoxDir: String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    { Fill DeviceComboBox with values valid for current install kind (std/X/old/new Staging). }
    procedure ApplyMIDIDeviceList;
    procedure ShowFrame(Sender: TObject);
  public
    { Public-Deklarationen }
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools, HelpConsts,
     PrgSetupUnit, MIDITools, GameDBHelpers, GameDBToolsHelpers, DOSBoxUnitHelpers;

{$R *.dfm}

{ TModernProfileEditorMIDIFrame }

function TModernProfileEditorMIDIFrame.IsFluidSynthDevice: Boolean;
begin
  Result:=SameText(Trim(DeviceComboBox.Text),'fluidsynth');
end;

function TModernProfileEditorMIDIFrame.GetDOSBoxDir: String;
begin
  if (ProfileDOSBoxInstallation=nil) or (ProfileDOSBoxInstallation^= '') then
    Result:=ResolveDOSBoxDir('')
  else
    Result:=ResolveDOSBoxDir(ProfileDOSBoxInstallation^);
end;

function TModernProfileEditorMIDIFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  Result:=DetermineDosBoxKind(GetDOSBoxDir, PrgSetup.BaseDir);
end;

procedure TModernProfileEditorMIDIFrame.ApplyMIDIDeviceList;
Var Kind: TDOSBoxKind;
    Version, S: String;
    I: Integer;
    NewStaging, OldStaging: Boolean;
    St: TStringList;
begin
  Kind:=GetSelectedDosBoxKind;
  Version:=CheckDOSBoxVersion(GetDOSBoxDir);
  OldStaging:=(Kind=dbkStaging) and (
    (Trim(Version)='') or (CompareDOSBoxVersion(Version,'0.83.0.0')<0));
  NewStaging:=(Kind=dbkStaging) and not OldStaging;

  DeviceComboBox.Items.BeginUpdate;
  try
    DeviceComboBox.Items.Clear;
    Case Kind of
      dbkStaging: begin
        If NewStaging then begin
          { 0.83: port (host MIDI; replaces auto/win32/…), fluidsynth, mt32, none.
            soundcanvas/coreaudio omitted (optional/platform-specific). }
          DeviceComboBox.Items.Add('port');
          DeviceComboBox.Items.Add('fluidsynth');
          DeviceComboBox.Items.Add('mt32');
          DeviceComboBox.Items.Add('none');
        end else begin
          { Pre-0.83 Staging: auto + host backends + synths. Windows-focused list. }
          DeviceComboBox.Items.Add('auto');
          DeviceComboBox.Items.Add('win32');
          DeviceComboBox.Items.Add('fluidsynth');
          DeviceComboBox.Items.Add('mt32');
          DeviceComboBox.Items.Add('none');
        end;
      end;
      dbkX: begin
        DeviceComboBox.Items.Add('default');
        DeviceComboBox.Items.Add('win32');
        DeviceComboBox.Items.Add('fluidsynth');
        DeviceComboBox.Items.Add('mt32');
        DeviceComboBox.Items.Add('synth');
        DeviceComboBox.Items.Add('timidity');
        DeviceComboBox.Items.Add('none');
      end;
      else begin
        { Classic DOSBox: ConfOpt list only (no fluidsynth — Staging/X only). }
        St:=ValueToList(FMIDIDeviceConfOpt,';,');
        try
          DeviceComboBox.Items.AddStrings(St);
        finally
          St.Free;
        end;
      end;
    end;
  finally
    DeviceComboBox.Items.EndUpdate;
  end;

  S:=Trim(LastMIDIDevice);
  { Aliases → canonical default for selection (DropDownList shows blank if still unknown). }
  If NewStaging then begin
    If (S='') or SameText(S,'default') or SameText(S,'auto') or SameText(S,'win32')
       or SameText(S,'alsa') or SameText(S,'oss') or SameText(S,'coremidi') then
      S:='port';
  end else If OldStaging then begin
    If (S='') or SameText(S,'default') then
      S:='auto';
  end else begin
    If S='' then S:='default';
  end;

  DeviceComboBox.ItemIndex:=-1;
  for I:=0 to DeviceComboBox.Items.Count-1 do
    if SameText(Trim(DeviceComboBox.Items[I]),S) then begin
      DeviceComboBox.ItemIndex:=I;
      break;
    end;
end;

procedure TModernProfileEditorMIDIFrame.ShowFrame(Sender: TObject);
begin
  if DeviceComboBox.ItemIndex>=0 then
    LastMIDIDevice:=DeviceComboBox.Text;
  ApplyMIDIDeviceList;
  DeviceComboBoxChange(Self);
end;

function TModernProfileEditorMIDIFrame.FormatFluidGainDisplay(const N: Integer): String;
begin
  Result:=IntToStr(N)+'%';
end;

procedure TModernProfileEditorMIDIFrame.ClearFluidSynthUI;
begin
  FluidSynthPathBox.Text:='';
  FUpdatingFluidGainUI:=True;
  try
    lbFluidSynthGainValue.Text:='';
    tbFluidSynthGainSlider.Position:=100;
  finally
    FUpdatingFluidGainUI:=False;
  end;
end;

procedure TModernProfileEditorMIDIFrame.LoadFluidGainUI(const GainStr: String);
Var N: Integer;
begin
  FUpdatingFluidGainUI:=True;
  try
    If TryStrToInt(Trim(GainStr),N) then begin
      N:=Max(tbFluidSynthGainSlider.Min,Min(tbFluidSynthGainSlider.Max,N));
      tbFluidSynthGainSlider.Position:=N;
      lbFluidSynthGainValue.Text:=FormatFluidGainDisplay(N);
    end else begin
      lbFluidSynthGainValue.Text:='';
      tbFluidSynthGainSlider.Position:=100;
    end;
  finally
    FUpdatingFluidGainUI:=False;
  end;
end;

procedure TModernProfileEditorMIDIFrame.ApplyFluidSynthPathVisibility;
begin
  FluidSynthGroupBox.Visible:=IsFluidSynthDevice;
end;

procedure TModernProfileEditorMIDIFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var St : TStringList;
begin
  NoFlicker(TypeComboBox);
  NoFlicker(DeviceComboBox);
  NoFlicker(AdditionalSettingsEdit);
  NoFlicker(MIDISelectButton);
  NoFlicker(MIDISelectListBox);
  NoFlicker(MT32SettingsGroupBox);
  NoFlicker(MT32ModeComboBox);
  NoFlicker(MT32TimeComboBox);
  NoFlicker(MT32LevelComboBox);
  NoFlicker(FluidSynthGroupBox);
  NoFlicker(FluidSynthPathBox);
  NoFlicker(tbFluidSynthGainSlider);
  NoFlicker(lbFluidSynthGainValue);

  ProfileDOSBoxInstallation:=InitData.CurrentDOSBoxInstallation;
  FMIDIDeviceConfOpt:=InitData.GameDB.ConfOpt.MIDIDevice;
  InitData.OnShowFrame:=ShowFrame;

  InfoLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIInfo;
  TypeLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIType;
  St:=ValueToList(InitData.GameDB.ConfOpt.MPU401,';,'); try TypeComboBox.Items.AddStrings(St); finally St.Free; end;
  DeviceLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIDevice;
  LastMIDIDevice:='';
  ApplyMIDIDeviceList;
  AdditionalSettingsEdit.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIConfigInfo;
  MIDISelectButton.Caption:=LanguageSetup.ProfileEditorSoundMIDIConfigButton;
  MIDISelectLabel1.Caption:=LanguageSetup.ProfileEditorSoundMIDIConfigButtonInfo;
  MIDISelectLabel2.Caption:=LanguageSetup.ProfileEditorSoundMIDIConfigIDInfo;
  AddDefaultValueHint(TypeComboBox);
  AddDefaultValueHint(DeviceComboBox);

  FluidSynthGroupBox.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynth;
  FluidSynthPathBox.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynthSoundfont;
  BtnFluidSynthPath.Hint:=LanguageSetup.ChooseFile;
  BtnFluidSynthPath.ShowHint:=True;
  BtnFluidSynthPath.OnClick:=BtnFluidSynthPathClick;

  { Min/Max come from the DFM (0..800); do not override here. }
  tbFluidSynthGainSlider.OnChange:=tbFluidSynthGainSliderChange;
  lbFluidSynthGainValue.ReadOnly:=True;
  lbFluidSynthGainValue.TabStop:=False;
  lbFluidSynthGainValue.Text:='';

  MT32SettingsGroupBox.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32;
  MT32ModeLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32Mode;
  MT32TimeLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32Time;
  MT32LevelLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32Level;

  St:=ValueToList(InitData.GameDB.ConfOpt.MT32ReverbMode,';,');
  try
    MT32ModeComboBox.Items.Clear;
    MT32ModeComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;

  St:=ValueToList(InitData.GameDB.ConfOpt.MT32ReverbTime,';,');
  try
    MT32TimeComboBox.Items.Clear;
    MT32TimeComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;

  St:=ValueToList(InitData.GameDB.ConfOpt.MT32ReverbLevel,';,');
  try
    MT32LevelComboBox.Items.Clear;
    MT32LevelComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;

  { Start hidden until device selection is known (SetGame / combo change). }
  ApplyFluidSynthPathVisibility;

  HelpContext:=ID_ProfileEditSoundMIDI;
end;

Procedure SetComboBox(const ComboBox : TComboBox; const Value : String; const Default : Integer); overload;
Var S : String;
    I : Integer;
begin
  try ComboBox.ItemIndex:=Default; except end;
  S:=Trim(ExtUpperCase(Value));
  For I:=0 to ComboBox.Items.Count-1 do If Trim(ExtUpperCase(ComboBox.Items[I]))=S then begin
    ComboBox.ItemIndex:=I; break;
  end;
end;

procedure TModernProfileEditorMIDIFrame.tbFluidSynthGainSliderChange(Sender: TObject);
begin
  If FUpdatingFluidGainUI then Exit;
  lbFluidSynthGainValue.Text:=FormatFluidGainDisplay(tbFluidSynthGainSlider.Position);
end;

Procedure SetComboBox(const ComboBox : TComboBox; const Value : String; const Default : String); overload;
begin
  SetComboBox(ComboBox,Default,0);
  SetComboBox(ComboBox,Value,ComboBox.ItemIndex);
end;

procedure TModernProfileEditorMIDIFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
begin
  SetComboBox(TypeComboBox,Game.MIDIType,'intelligent');
  LastMIDIDevice:=Game.MIDIDevice;
  ApplyMIDIDeviceList;
  AdditionalSettingsEdit.Text:=Game.MIDIConfig;

  FLoadedFluidPath:=Trim(Game.FluidSoundFont);
  FLoadedFluidGain:=Trim(Game.FluidSoundFontGain);
  FluidSynthPathBox.Text:=FLoadedFluidPath;
  LoadFluidGainUI(FLoadedFluidGain);

  MT32ModeComboBox.ItemIndex:=Max(0,MT32ModeComboBox.Items.IndexOf(Game.MIDIMT32Mode));
  MT32TimeComboBox.ItemIndex:=Max(0,MT32TimeComboBox.Items.IndexOf(Game.MIDIMT32Time));
  MT32LevelComboBox.ItemIndex:=Max(0,MT32LevelComboBox.Items.IndexOf(Game.MIDIMT32Level));

  DeviceComboBoxChange(self);
end;

procedure TModernProfileEditorMIDIFrame.DeviceComboBoxChange(Sender: TObject);
begin
  MT32SettingsGroupBox.Visible:=(ExtUpperCase(DeviceComboBox.Text)='MT32');
  If not IsFluidSynthDevice then
    ClearFluidSynthUI;
  ApplyFluidSynthPathVisibility;
end;

procedure TModernProfileEditorMIDIFrame.BtnFluidSynthPathClick(Sender: TObject);
Var S: String;
    OD: TOpenDialog;
begin
  { Same path pattern as DOSBox install browse: abs for dialog, rel back into edit. }
  S:=Trim(FluidSynthPathBox.Text);
  If S='' then S:=PrgSetup.BaseDir else S:=MakeAbsPath(S,PrgSetup.BaseDir);

  OD:=TOpenDialog.Create(Self);
  try
    OD.Title:=LanguageSetup.ChooseFile;
    OD.DefaultExt:='sf2';
    OD.Filter:='SoundFont (*.sf2;*.sf3)|*.sf2;*.sf3|All files (*.*)|*.*';
    OD.Options:=OD.Options+[ofFileMustExist,ofPathMustExist,ofHideReadOnly];
    If FileExists(S) then begin
      OD.InitialDir:=ExtractFilePath(S);
      OD.FileName:=ExtractFileName(S);
    end else If DirectoryExists(S) then
      OD.InitialDir:=S
    else If DirectoryExists(ExtractFilePath(S)) then
      OD.InitialDir:=ExtractFilePath(S)
    else
      OD.InitialDir:=PrgSetup.BaseDir;
    if not OD.Execute then exit;
    S:=MakeRelPath(OD.FileName,PrgSetup.BaseDir);
    If S='' then exit;
    FluidSynthPathBox.Text:=S;
  finally
    OD.Free;
  end;
end;

procedure TModernProfileEditorMIDIFrame.GetGame(const Game: TGame);
Var PathNow, GainNow: String;
begin
  Game.MIDIType:=TypeComboBox.Text;
  Game.MIDIDevice:=DeviceComboBox.Text;
  Game.MIDIConfig:=AdditionalSettingsEdit.Text;

  If not IsFluidSynthDevice then begin
    Game.FluidSoundFont:='';
    Game.FluidSoundFontGain:='';
  end else begin
    PathNow:=Trim(FluidSynthPathBox.Text);
    GainNow:=IntToStr(tbFluidSynthGainSlider.Position);
    If PathNow<>FLoadedFluidPath then
      Game.FluidSoundFont:=PathNow;
    If GainNow<>FLoadedFluidGain then
      Game.FluidSoundFontGain:=GainNow;
  end;

  Game.MIDIMT32Mode:=MT32ModeComboBox.Text;
  Game.MIDIMT32Time:=MT32TimeComboBox.Text;
  Game.MIDIMT32Level:=MT32LevelComboBox.Text;
end;

procedure TModernProfileEditorMIDIFrame.MIDISelectButtonClick(Sender: TObject);
Var St : TStringList;
    I : Integer;
begin
  St:=GetMIDIDevices;
  try
    MIDISelectListBox.Visible:=(St.Count>0);
    MIDISelectLabel2.Visible:=(St.Count>0);
    MIDISelectListBox.Items.BeginUpdate;
    try
      MIDISelectListBox.Items.Clear;
      { Keep Objects = device id (AddStrings is not enough on all TStrings). }
      For I:=0 to St.Count-1 do
        MIDISelectListBox.Items.AddObject(St[I],St.Objects[I]);
    finally
      MIDISelectListBox.Items.EndUpdate;
    end;
  finally
    St.Free;
  end;
end;

procedure TModernProfileEditorMIDIFrame.MIDISelectListBoxClick(Sender: TObject);
begin
  If MIDISelectListBox.ItemIndex<0 then exit;
  { Store numeric WinMM/DOSBox device id in the profile, not the display name. }
  AdditionalSettingsEdit.Text:=IntToStr(Integer(MIDISelectListBox.Items.Objects[MIDISelectListBox.ItemIndex]));
end;

end.
