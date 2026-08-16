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
    procedure DeviceComboBoxChange(Sender: TObject); overload;
    procedure BtnFluidSynthPathClick(Sender: TObject);
    procedure tbFluidSynthGainSliderChange(Sender: TObject);
    procedure FluidSynthPathBoxChange(Sender: TObject);
  private
    FLoadedMT32Model: String;
    FUpdatingFluidGainUI: Boolean;
    FGame: TGame;
    FTempGame: TGame;
    FMIDIDeviceConfOpt: String;
    FMIDIDeviceStagingConfOpt: String;
    FMIDIDeviceStagingOldConfOpt: String;
    FMIDIDeviceXConfOpt: String;
    FMIDIDevicePureConfOpt: String;
    FMT32ModelStagingConfOpt: String;
    FMT32ModelXConfOpt: String;
    LastMIDIDevice: String;
    procedure DeviceComboBoxChange(Sender: TObject; UpdatePath: Boolean); overload;
    procedure ApplyFluidSynthPathVisibility;
    procedure SetFluidSynthBoxPath;
    procedure ClearFluidSynthUI;
    procedure LoadFluidGainUI(const GainStr: String);
    function FormatFluidGainDisplay(const N: Integer): String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    procedure ApplyMIDIDeviceList;
    procedure ApplyMT32ModelList;
    procedure PopulatePureMT32Models;
    procedure ShowFrame(Sender: TObject);
    procedure Invalidate(Sender: TObject);
  public
    { Public-Deklarationen }
    Constructor Create(AOwner : TComponent); override;
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools, HelpConsts,
     PrgSetupUnit, MIDITools, GameDBHelpers, GameDBToolsHelpers, DOSBoxUnitHelpers;

{$R *.dfm}

{ TModernProfileEditorMIDIFrame }

constructor TModernProfileEditorMIDIFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
end;

function TModernProfileEditorMIDIFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  Result:=FTempGame.DosBoxKind;
end;

procedure TModernProfileEditorMIDIFrame.ApplyMIDIDeviceList;
Var Kind: TDOSBoxKind;
    S, ListSrc: String;
    I: Integer;
    St: TStringList;
    OldChange: TNotifyEvent;
begin
  Kind:=GetSelectedDosBoxKind;

  { All device lists come from ConfOpt (same multi-list pattern as Render). }
  Case Kind of
    dbkStaging:
      If FTempGame.IsOldStaging then ListSrc:=FMIDIDeviceStagingOldConfOpt
      else ListSrc:=FMIDIDeviceStagingConfOpt;
    dbkX:
      ListSrc:=FMIDIDeviceXConfOpt;
    dbkPure:
      ListSrc:=FMIDIDevicePureConfOpt;
    else
      ListSrc:=FMIDIDeviceConfOpt;
  end;

  S:=Trim(LastMIDIDevice);
  If (S='') or SameText(S,'none') then
    S:='none';
  If SameText(S,'fluidsynth') then
    S:='soundfont';

  OldChange:=DeviceComboBox.OnChange;
  DeviceComboBox.OnChange:=nil;
  DeviceComboBox.Items.BeginUpdate;
  DeviceComboBox.Items.Clear;
  St:=ValueToList(ListSrc,';,');
  DeviceComboBox.Items.AddStrings(St);
  St.Free;
  DeviceComboBox.Items.EndUpdate;
  DeviceComboBox.ItemIndex:=-1;
  for I:=0 to DeviceComboBox.Items.Count-1 do
    if SameText(Trim(DeviceComboBox.Items[I]),S) then begin
      DeviceComboBox.ItemIndex:=I;
      break;
    end;
  DeviceComboBox.OnChange:=OldChange;

  ApplyMT32ModelList;
end;

procedure TModernProfileEditorMIDIFrame.ApplyMT32ModelList;
Var Kind: TDOSBoxKind;
    S, Want: String;
    St: TStringList;
    I: Integer;
    ReverbOK, ModelOK: Boolean;
begin
  Kind:=GetSelectedDosBoxKind;
  ReverbOK:=Kind in [dbkStandard,dbkX];
  ModelOK:=Kind in [dbkStaging,dbkX,dbkPure];
  Case Kind of
    dbkStaging: S:=FMT32ModelStagingConfOpt;
    dbkX:       S:=FMT32ModelXConfOpt;
    else        S:='';
  end;

  Want:=Trim(MT32ModelComboBox.Text);
  If Want='' then Want:=FLoadedMT32Model;
  If Want='' then Want:='auto';

  MT32ModelComboBox.Items.Clear;
  MT32ModelComboBox.ItemIndex:=-1;
  MT32ModelComboBox.Text:='';
  If S<>'' then begin
    St:=ValueToList(S,';,');
    MT32ModelComboBox.Items.AddStrings(St);
    St.Free;
  end;
  MT32ModelComboBox.Enabled:=ModelOK;
  MT32ModelLabel.Enabled:=ModelOK;
  MT32ModeComboBox.Enabled:=ReverbOK;
  MT32TimeComboBox.Enabled:=ReverbOK;
  MT32LevelComboBox.Enabled:=ReverbOK;
  MT32ModeLabel.Enabled:=ReverbOK;
  MT32TimeLabel.Enabled:=ReverbOK;
  MT32LevelLabel.Enabled:=ReverbOK;

  if ModelOK then
    for I:=0 to MT32ModelComboBox.Items.Count-1 do
      if SameText(Trim(MT32ModelComboBox.Items[I]),Want) then begin
        MT32ModelComboBox.ItemIndex:=I;
        break;
      end;
end;

procedure CollectPureMT32Models(const Dir: String; Names: TStringList; Depth: Integer; MaxDepth: Integer = 32);
const
  ControlSuffix = '_CONTROL.ROM';
Var Rec: TSearchRec;
    I: Integer;
    Full, EntryU, DeviceName: String;
begin
  If Depth>=MaxDepth then exit;
  I:=FindFirst(Dir+'*.*',faAnyFile,Rec);
  If I<>0 then exit;
  try
    While I=0 do begin
      If (Rec.Name<>'') and (Rec.Name<>'.') and (Rec.Name<>'..') then begin
        Full:=Dir+Rec.Name;
        If (Rec.Attr and faDirectory)<>0 then
          CollectPureMT32Models(Full+PathDelim,Names,Depth+1,MaxDepth)
        else begin
          EntryU:=ExtUpperCase(Rec.Name);
          If (Length(EntryU)>Length(ControlSuffix)) and
             (Copy(EntryU,Length(EntryU)-Length(ControlSuffix)+1,MaxInt)=ControlSuffix) then begin
            DeviceName:=Copy(Rec.Name,1,Length(Rec.Name)-Length(ControlSuffix));
            If (DeviceName<>'') and FileExists(Dir+DeviceName+'_PCM.ROM') then
              Names.Add(DeviceName);
          end;
        end;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

procedure TModernProfileEditorMIDIFrame.PopulatePureMT32Models;
Var Root, Want: String;
    Names: TStringList;
    I: Integer;
begin
  If GetSelectedDosBoxKind<>dbkPure then exit;

  Want:=Trim(MT32ModelComboBox.Text);
  If Want='' then Want:=FLoadedMT32Model;

  MT32ModelComboBox.Items.Clear;
  MT32ModelComboBox.ItemIndex:=-1;

  Root:=Trim(FluidSynthPathBox.Text);
  If Root='' then exit;
  Root:=IncludeTrailingPathDelimiter(MakeAbsPath(Root,PrgSetup.BaseDir));
  If not DirectoryExists(Root) then exit;

  Names:=TStringList.Create;
  try
    Names.Sorted:=True;
    Names.Duplicates:=dupIgnore;
    Names.CaseSensitive:=False;
    CollectPureMT32Models(Root,Names,0);
    MT32ModelComboBox.Items.BeginUpdate;
    try
      MT32ModelComboBox.Items.AddStrings(Names);
    finally
      MT32ModelComboBox.Items.EndUpdate;
    end;
  finally
    Names.Free;
  end;

  for I:=0 to MT32ModelComboBox.Items.Count-1 do
    if SameText(Trim(MT32ModelComboBox.Items[I]),Want) then begin
      MT32ModelComboBox.ItemIndex:=I;
      break;
    end;
end;

procedure TModernProfileEditorMIDIFrame.ShowFrame(Sender: TObject);
begin
  if DeviceComboBox.ItemIndex>=0 then
    LastMIDIDevice:=DeviceComboBox.Text;
  ApplyMIDIDeviceList;
  DeviceComboBoxChange(Self,False);
end;

procedure TModernProfileEditorMIDIFrame.Invalidate(Sender: TObject);
begin
  DeviceComboBox.ItemIndex:=-1;
  MT32ModelComboBox.ItemIndex:=-1;
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
    Pure: Boolean;
begin
  Pure:=GetSelectedDosBoxKind=dbkPure;
  If Pure then
    tbFluidSynthGainSlider.Max:=500
  else
    tbFluidSynthGainSlider.Max:=800;
  FUpdatingFluidGainUI:=True;
  try
    If TryStrToInt(Trim(GainStr),N) and (N>=tbFluidSynthGainSlider.Min) and (N<=tbFluidSynthGainSlider.Max) then begin
      tbFluidSynthGainSlider.Position:=N;
      lbFluidSynthGainValue.Text:=FormatFluidGainDisplay(N);
    end else begin
      { Empty or out of range for this kind → unselected (same as no stored value). }
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
  IsFS:=SameText(Trim(DeviceComboBox.Text),'soundfont');
  IsMT:=SameText(Trim(DeviceComboBox.Text),'mt32');
  FluidSynthGroupBox.Visible:=(Kind in [dbkStaging,dbkX,dbkPure]) and (IsFS or IsMT);
  If not FluidSynthGroupBox.Visible then exit;

  FluidSynthGroupBox.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynth;
  If IsFS then begin
    FluidSynthPathBox.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynthSoundfont;
    BtnFluidSynthPath.Hint:=LanguageSetup.ChooseFile;
  end else begin
    FluidSynthPathBox.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32RomDir;
    BtnFluidSynthPath.Hint:=LanguageSetup.ChooseFolder;
    If Kind=dbkPure then PopulatePureMT32Models;
  end;
  { Gain slider is shared; do not reload profile gain on device change. }
  tbFluidSynthGainSlider.Enabled:=True;
  lbFluidSynthGainValue.Enabled:=True;
end;

procedure TModernProfileEditorMIDIFrame.SetFluidSynthBoxPath;
Var Cur: String;
begin
  Cur:=Trim(DeviceComboBox.Text);
  If SameText(Cur,'soundfont') then begin
    If FGame<>nil then FluidSynthPathBox.Text:=Trim(FGame.FluidSoundFont) else FluidSynthPathBox.Text:='';
  end else If SameText(Cur,'mt32') then begin
    If FGame<>nil then FluidSynthPathBox.Text:=Trim(FGame.MIDIMT32RomDir) else FluidSynthPathBox.Text:='';
  end else
    FluidSynthPathBox.Text:='';
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

  FMIDIDeviceConfOpt:=InitData.GameDB.ConfOpt.MIDIDevice;
  FMIDIDeviceStagingConfOpt:=InitData.GameDB.ConfOpt.MIDIDeviceStaging;
  FMIDIDeviceStagingOldConfOpt:=InitData.GameDB.ConfOpt.MIDIDeviceStagingOld;
  FMIDIDeviceXConfOpt:=InitData.GameDB.ConfOpt.MIDIDeviceX;
  FMIDIDevicePureConfOpt:=InitData.GameDB.ConfOpt.MIDIDevicePure;
  FMT32ModelStagingConfOpt:=InitData.GameDB.ConfOpt.MT32ModelStaging;
  FMT32ModelXConfOpt:=InitData.GameDB.ConfOpt.MT32ModelX;
  InitData.OnShowFrame:=ShowFrame;
  InitData.OnInvalidate:=Invalidate;

  InfoLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIInfo;
  TypeLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIType;
  St:=ValueToList(InitData.GameDB.ConfOpt.MPU401,';,'); try TypeComboBox.Items.AddStrings(St); finally St.Free; end;
  DeviceLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIDevice;
  LastMIDIDevice:='';
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

  FluidSynthGroupBox.Visible:=False;
  MT32SettingsGroupBox.Visible:=False;

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
  FTempGame.MIDIDeviceGainValue:=IntToStr(tbFluidSynthGainSlider.Position);
end;

Procedure SetComboBox(const ComboBox : TComboBox; const Value : String; const Default : String); overload;
begin
  SetComboBox(ComboBox,Default,0);
  SetComboBox(ComboBox,Value,ComboBox.ItemIndex);
end;

procedure TModernProfileEditorMIDIFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
begin
  FGame:=Game;
  SetComboBox(TypeComboBox,Game.MIDIType,'intelligent');
  LastMIDIDevice:=Game.MIDIDevice;

  FLoadedMT32Model:=Trim(Game.MIDIMT32Model);
  If FLoadedMT32Model='' then FLoadedMT32Model:='auto';

  ApplyMIDIDeviceList;
  AdditionalSettingsEdit.Text:=Game.MIDIConfig;

  MT32ModeComboBox.ItemIndex:=Max(0,MT32ModeComboBox.Items.IndexOf(Game.MIDIMT32Mode));
  MT32TimeComboBox.ItemIndex:=Max(0,MT32TimeComboBox.Items.IndexOf(Game.MIDIMT32Time));
  MT32LevelComboBox.ItemIndex:=Max(0,MT32LevelComboBox.Items.IndexOf(Game.MIDIMT32Level));

  LoadFluidGainUI(Trim(Game.MIDIDeviceGainValue));
  FTempGame.MIDIDeviceGainValue:='';

  DeviceComboBoxChange(self);
end;

procedure TModernProfileEditorMIDIFrame.DeviceComboBoxChange(Sender: TObject);
begin
  DeviceComboBoxChange(Sender,True);
end;

procedure TModernProfileEditorMIDIFrame.DeviceComboBoxChange(Sender: TObject; UpdatePath: Boolean);
Var Cur: String;
begin
  Cur:=Trim(DeviceComboBox.Text);
  LastMIDIDevice:=Cur;

  MT32SettingsGroupBox.Visible:=SameText(Cur,'mt32');
  If not SameText(Cur,'soundfont') and not SameText(Cur,'mt32') then
    ClearFluidSynthUI;
  ApplyFluidSynthPathVisibility;
  If UpdatePath then
    SetFluidSynthBoxPath;
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
    PopulatePureMT32Models;
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
  finally
    OD.Free;
  end;
end;

procedure TModernProfileEditorMIDIFrame.FluidSynthPathBoxChange(Sender: TObject);
Var Root: String;
begin
  If GetSelectedDosBoxKind<>dbkPure then exit;
  If not SameText(Trim(DeviceComboBox.Text),'mt32') then exit;
  Root:=Trim(FluidSynthPathBox.Text);
  If Root='' then exit;
  Root:=IncludeTrailingPathDelimiter(MakeAbsPath(Root,PrgSetup.BaseDir));
  If not DirectoryExists(Root) then exit;
  PopulatePureMT32Models;
end;

procedure TModernProfileEditorMIDIFrame.GetGame(const Game: TGame);
Var PathNow: String;
    Kind: TDOSBoxKind;
    IsFS, IsMT: Boolean;
begin
  Game.MIDIType:=TypeComboBox.Text;
  If DeviceComboBox.ItemIndex>=0 then
    Game.MIDIDevice:=DeviceComboBox.Text;
  Game.MIDIConfig:=AdditionalSettingsEdit.Text;

  IsFS:=(DeviceComboBox.ItemIndex>=0) and SameText(Trim(DeviceComboBox.Text),'soundfont');
  IsMT:=(DeviceComboBox.ItemIndex>=0) and SameText(Trim(DeviceComboBox.Text),'mt32');
  PathNow:=Trim(FluidSynthPathBox.Text);
  Kind:=GetSelectedDosBoxKind;

  If (IsFS or IsMT) and (Trim(FTempGame.MIDIDeviceGainValue)<>'') then
    Game.MIDIDeviceGainValue:=IntToStr(tbFluidSynthGainSlider.Position);

  If (Kind in [dbkStaging,dbkX,dbkPure]) and IsFS then
    Game.FluidSoundFont:=PathNow;

  If IsMT then begin
    If Kind in [dbkStandard,dbkX] then begin
      Game.MIDIMT32Mode:=MT32ModeComboBox.Text;
      Game.MIDIMT32Time:=MT32TimeComboBox.Text;
      Game.MIDIMT32Level:=MT32LevelComboBox.Text;
    end;
    If Kind in [dbkStaging,dbkX,dbkPure] then begin
      If MT32ModelComboBox.ItemIndex>=0 then begin
        Game.MIDIMT32Model:=MT32ModelComboBox.Text;
        FLoadedMT32Model:=Game.MIDIMT32Model;
      end;
    end;
    If Kind in [dbkStaging,dbkX,dbkPure] then
      Game.MIDIMT32RomDir:=PathNow;
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
