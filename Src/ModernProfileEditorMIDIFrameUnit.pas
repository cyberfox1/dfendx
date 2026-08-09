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
    FluidSynthGroupBox: TGroupBox;
    FluidSynthPathBox: TLabeledEdit;
    lbFluidSynthGainValue: TLabeledEdit;
    BtnFluidSynthPath: TSpeedButton;
    tbFluidSynthGainSlider: TTrackBar;
    MT32ModelComboBox: TComboBox;
    MT32ModelLabel: TLabel;
    MT32LevelLabel: TLabel;
    procedure MIDISelectButtonClick(Sender: TObject);
    procedure MIDISelectListBoxClick(Sender: TObject);
    procedure DeviceComboBoxChange(Sender: TObject);
    procedure BtnFluidSynthPathClick(Sender: TObject);
    procedure tbFluidSynthGainSliderChange(Sender: TObject);
  private
    FLoadedFluidPath: String;
    FLoadedFluidGain: String;
    FLoadedMT32RomDir: String;
    FLoadedMT32Model: String;
    FUpdatingFluidGainUI: Boolean;
    ProfileDOSBoxInstallation: PString;
    FMIDIDeviceConfOpt: String;
    FMIDIDeviceStagingConfOpt: String;
    FMIDIDeviceStagingOldConfOpt: String;
    FMIDIDeviceXConfOpt: String;
    FMT32ModelStagingConfOpt: String;
    FMT32ModelXConfOpt: String;
    LastMIDIDevice: String;
    procedure ApplyFluidSynthPathVisibility;
    procedure ClearFluidSynthUI;
    procedure LoadFluidGainUI(const GainStr: String);
    function FormatFluidGainDisplay(const N: Integer): String;
    function IsFluidSynthDevice: Boolean;
    function GetDOSBoxDir: String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    procedure ApplyMIDIDeviceList;
    procedure ApplyMT32ModelList;
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
    Version, S, ListSrc: String;
    I: Integer;
    NewStaging, OldStaging: Boolean;
    St: TStringList;
begin
  Kind:=GetSelectedDosBoxKind;
  Version:=CheckDOSBoxVersion(GetDOSBoxDir);
  OldStaging:=(Kind=dbkStaging) and (
    (Trim(Version)='') or (CompareDOSBoxVersion(Version,'0.83.0.0')<0));
  NewStaging:=(Kind=dbkStaging) and not OldStaging;

  { All device lists come from ConfOpt (same multi-list pattern as Render). }
  Case Kind of
    dbkStaging:
      If OldStaging then ListSrc:=FMIDIDeviceStagingOldConfOpt
      else ListSrc:=FMIDIDeviceStagingConfOpt;
    dbkX:
      ListSrc:=FMIDIDeviceXConfOpt;
    else
      ListSrc:=FMIDIDeviceConfOpt;
  end;

  DeviceComboBox.Items.BeginUpdate;
  try
    DeviceComboBox.Items.Clear;
    St:=ValueToList(ListSrc,';,');
    try
      DeviceComboBox.Items.AddStrings(St);
    finally
      St.Free;
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

  ApplyMT32ModelList;
end;

procedure TModernProfileEditorMIDIFrame.ApplyMT32ModelList;
Var Kind: TDOSBoxKind;
    S, Want: String;
    St: TStringList;
    I: Integer;
begin
  Kind:=GetSelectedDosBoxKind;
  Case Kind of
    dbkStaging: S:=FMT32ModelStagingConfOpt;
    dbkX:       S:=FMT32ModelXConfOpt;
    else        S:='';
  end;

  Want:=Trim(MT32ModelComboBox.Text);
  If Want='' then Want:=FLoadedMT32Model;
  If Want='' then Want:='auto';

  MT32ModelComboBox.Items.Clear;
  If S<>'' then begin
    St:=ValueToList(S,';,');
    try
      MT32ModelComboBox.Items.AddStrings(St);
    finally
      St.Free;
    end;
  end;
  MT32ModelComboBox.Enabled:=Kind in [dbkStaging,dbkX];
  MT32ModelLabel.Enabled:=MT32ModelComboBox.Enabled;

  MT32ModelComboBox.ItemIndex:=-1;
  for I:=0 to MT32ModelComboBox.Items.Count-1 do
    if SameText(Trim(MT32ModelComboBox.Items[I]),Want) then begin
      MT32ModelComboBox.ItemIndex:=I;
      break;
    end;
  { No match → leave -1; do not force first item (would show a false value). }
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
  { Path only; leave gain slider alone (shared across devices until SetGame). }
  FluidSynthPathBox.Text:='';
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
Var IsFS, IsMT: Boolean;
    Kind: TDOSBoxKind;
begin
  Kind:=GetSelectedDosBoxKind;
  IsFS:=SameText(Trim(DeviceComboBox.Text),'fluidsynth');
  IsMT:=SameText(Trim(DeviceComboBox.Text),'mt32');
  { Synth settings (soundfont/ROM dir + gain): Staging/X only, not classic. }
  FluidSynthGroupBox.Visible:=(Kind in [dbkStaging,dbkX]) and (IsFS or IsMT);
  If not FluidSynthGroupBox.Visible then exit;

  FluidSynthGroupBox.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynth;
  If IsFS then begin
    FluidSynthPathBox.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynthSoundfont;
    BtnFluidSynthPath.Hint:=LanguageSetup.ChooseFile;
    FluidSynthPathBox.Text:=FLoadedFluidPath;
  end else begin
    { device is mt32 }
    FluidSynthPathBox.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32RomDir;
    BtnFluidSynthPath.Hint:=LanguageSetup.ChooseFolder;
    FluidSynthPathBox.Text:=FLoadedMT32RomDir;
  end;
  { Gain slider is shared; do not reload profile gain on device change. }
  tbFluidSynthGainSlider.Enabled:=True;
  lbFluidSynthGainValue.Enabled:=True;
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
  NoFlicker(MT32ModelComboBox);
  NoFlicker(FluidSynthGroupBox);
  NoFlicker(FluidSynthPathBox);
  NoFlicker(tbFluidSynthGainSlider);
  NoFlicker(lbFluidSynthGainValue);

  ProfileDOSBoxInstallation:=InitData.CurrentDOSBoxInstallation;
  FMIDIDeviceConfOpt:=InitData.GameDB.ConfOpt.MIDIDevice;
  FMIDIDeviceStagingConfOpt:=InitData.GameDB.ConfOpt.MIDIDeviceStaging;
  FMIDIDeviceStagingOldConfOpt:=InitData.GameDB.ConfOpt.MIDIDeviceStagingOld;
  FMIDIDeviceXConfOpt:=InitData.GameDB.ConfOpt.MIDIDeviceX;
  FMT32ModelStagingConfOpt:=InitData.GameDB.ConfOpt.MT32ModelStaging;
  FMT32ModelXConfOpt:=InitData.GameDB.ConfOpt.MT32ModelX;
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
  MT32ModelLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32Model;

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

  FLoadedFluidPath:=Trim(Game.FluidSoundFont);
  FLoadedFluidGain:=Trim(Game.MIDIDeviceGainValue);
  FLoadedMT32RomDir:=Trim(Game.MIDIMT32RomDir);
  FLoadedMT32Model:=Trim(Game.MIDIMT32Model);
  If FLoadedMT32Model='' then FLoadedMT32Model:='auto';

  ApplyMIDIDeviceList;
  AdditionalSettingsEdit.Text:=Game.MIDIConfig;

  MT32ModeComboBox.ItemIndex:=Max(0,MT32ModeComboBox.Items.IndexOf(Game.MIDIMT32Mode));
  MT32TimeComboBox.ItemIndex:=Max(0,MT32TimeComboBox.Items.IndexOf(Game.MIDIMT32Time));
  MT32LevelComboBox.ItemIndex:=Max(0,MT32LevelComboBox.Items.IndexOf(Game.MIDIMT32Level));

  { Profile gain once per open; device switches leave the slider alone. }
  LoadFluidGainUI(FLoadedFluidGain);

  { Do not treat as a device change: keep loaded ROM dir / model. }
  DeviceComboBoxChange(self);
end;

procedure TModernProfileEditorMIDIFrame.DeviceComboBoxChange(Sender: TObject);
Var Prev, Cur: String;
begin
  Prev:=Trim(LastMIDIDevice);
  Cur:=Trim(DeviceComboBox.Text);

  { Only capture path when actually leaving fluidsynth/mt32 for another device. }
  If not SameText(Prev,Cur) then begin
    If SameText(Prev,'fluidsynth') then
      FLoadedFluidPath:=Trim(FluidSynthPathBox.Text)
    else If SameText(Prev,'mt32') then
      FLoadedMT32RomDir:=Trim(FluidSynthPathBox.Text);
  end;
  LastMIDIDevice:=Cur;

  MT32SettingsGroupBox.Visible:=SameText(Cur,'mt32');
  If not SameText(Cur,'fluidsynth') and not SameText(Cur,'mt32') then
    ClearFluidSynthUI;
  ApplyFluidSynthPathVisibility;
end;

procedure TModernProfileEditorMIDIFrame.BtnFluidSynthPathClick(Sender: TObject);
Var S: String;
    OD: TOpenDialog;
begin
  S:=Trim(FluidSynthPathBox.Text);
  If S='' then S:=PrgSetup.BaseDir else S:=MakeAbsPath(S,PrgSetup.BaseDir);

  If SameText(Trim(DeviceComboBox.Text),'mt32') then begin
    If not DirectoryExists(S) then
      If DirectoryExists(ExtractFilePath(S)) then S:=ExtractFilePath(S) else S:=PrgSetup.BaseDir;
    If not SelectDirectory(Handle,LanguageSetup.ChooseFolder,S) then exit;
    S:=MakeRelPath(IncludeTrailingPathDelimiter(S),PrgSetup.BaseDir);
    If S='' then exit;
    FluidSynthPathBox.Text:=S;
    FLoadedMT32RomDir:=S;
    exit;
  end;

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
    FLoadedFluidPath:=S;
  finally
    OD.Free;
  end;
end;

procedure TModernProfileEditorMIDIFrame.GetGame(const Game: TGame);
Var PathNow, GainNow: String;
    Kind: TDOSBoxKind;
    IsFS, IsMT: Boolean;
begin
  Game.MIDIType:=TypeComboBox.Text;
  Game.MIDIDevice:=DeviceComboBox.Text;
  Game.MIDIConfig:=AdditionalSettingsEdit.Text;

  IsFS:=SameText(Trim(DeviceComboBox.Text),'fluidsynth');
  IsMT:=SameText(Trim(DeviceComboBox.Text),'mt32');
  PathNow:=Trim(FluidSynthPathBox.Text);
  GainNow:=IntToStr(tbFluidSynthGainSlider.Position);
  Kind:=GetSelectedDosBoxKind;

  { Gain/path when Synth settings is usable (Staging/X + fluidsynth|mt32). }
  If (Kind in [dbkStaging,dbkX]) and (IsFS or IsMT) then begin
    If GainNow<>FLoadedFluidGain then begin
      Game.MIDIDeviceGainValue:=GainNow;
      FLoadedFluidGain:=GainNow;
    end;
    If IsFS and (PathNow<>FLoadedFluidPath) then
      Game.FluidSoundFont:=PathNow;
  end;

  { MT-32 keys: only write when device is mt32; leave profile keys otherwise. }
  If IsMT then begin
    Game.MIDIMT32Mode:=MT32ModeComboBox.Text;
    Game.MIDIMT32Time:=MT32TimeComboBox.Text;
    Game.MIDIMT32Level:=MT32LevelComboBox.Text;
    If Kind in [dbkStaging,dbkX] then begin
      If MT32ModelComboBox.ItemIndex>=0 then begin
        Game.MIDIMT32Model:=MT32ModelComboBox.Text;
        FLoadedMT32Model:=Game.MIDIMT32Model;
      end;
      { Always write path when Staging/X + mt32 (empty clears). }
      Game.MIDIMT32RomDir:=PathNow;
      FLoadedMT32RomDir:=PathNow;
    end;
  end;
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
