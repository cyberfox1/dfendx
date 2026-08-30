unit ModernProfileEditorScummVMSoundFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ExtCtrls, ComCtrls, Buttons, GameDBUnit, ModernProfileEditorFormUnit,
  Vcl.Mask;

type
  TModernProfileEditorScummVMSoundFrame = class(TFrame, IModernProfileEditorFrame)
    MusicVolumeLabel: TLabel;
    MusicVolumeEdit: TSpinEdit;
    SpeechVolumeLabel: TLabel;
    SpeechVolumeEdit: TSpinEdit;
    SFXVolumeLabel: TLabel;
    SFXVolumeEdit: TSpinEdit;
    OutputRateLabel: TLabel;
    OutputRateComboBox: TComboBox;
    MusicDriverLabel: TLabel;
    MusicDriverComboBox: TComboBox;
    OplDriverLabel: TLabel;
    OplDriverComboBox: TComboBox;
    SynthSettingsGroupBox: TGroupBox;
    SynthGainTrackBar: TTrackBar;
    SynthGainValueEdit: TLabeledEdit;
    SynthPathEdit: TLabeledEdit;
    SynthPathButton: TSpeedButton;
    NativeMT32CheckBox: TCheckBox;
    EnableGSCheckBox: TCheckBox;
    MultiMIDICheckBox: TCheckBox;
    SpeechMuteCheckBox: TCheckBox;
    procedure MusicDriverComboBoxChange(Sender: TObject);
    procedure SynthPathButtonClick(Sender: TObject);
    procedure SynthGainTrackBarChange(Sender: TObject);
  private
    FGame: TGame;
    FUpdatingGainUI: Boolean;
    Function SelectedMusicDriverCode: String;
    Function IsFluidSynthDriver: Boolean;
    Function IsMT32Driver: Boolean;
    Function IsAdlibDriver: Boolean;
    Function ComboStoredValue(const Combo: TComboBox): String;
    Procedure SelectComboValue(const Combo: TComboBox; const Value: String);
    Procedure UpdateDriverDependentPanels;
    Procedure LoadGainUI(const Gain: Integer);
  public
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools,
     HelpConsts, PrgSetupUnit;

{$R *.dfm}

{ TModernProfileEditorScummVMSoundFrame }

function TModernProfileEditorScummVMSoundFrame.SelectedMusicDriverCode: String;
Var S : String;
    I : Integer;
begin
  S:=Trim(MusicDriverComboBox.Text);
  If (S<>'') and (S[length(S)]=')') then begin
    For I:=length(S)-1 downto 1 do If S[I]='(' then begin S:=Trim(Copy(S,I+1,MaxInt)); break; end;
  end;
  If (S<>'') and (S[length(S)]=')') then SetLength(S,length(S)-1);
  Result:=LowerCase(Trim(S));
end;

function TModernProfileEditorScummVMSoundFrame.IsFluidSynthDriver: Boolean;
Var D : String;
begin
  D:=SelectedMusicDriverCode;
  Result:=(D='fluidsynth') or (D='fluid');
end;

function TModernProfileEditorScummVMSoundFrame.IsMT32Driver: Boolean;
begin
  Result:=(SelectedMusicDriverCode='mt32');
end;

function TModernProfileEditorScummVMSoundFrame.IsAdlibDriver: Boolean;
begin
  Result:=(SelectedMusicDriverCode='adlib');
end;

function TModernProfileEditorScummVMSoundFrame.ComboStoredValue(const Combo: TComboBox): String;
Var S : String;
begin
  S:=Combo.Text;
  If Pos('(',S)=0 then Result:=S else begin
    S:=Copy(S,Pos('(',S)+1,MaxInt);
    If Pos(')',S)=0 then Result:=Combo.Text else Result:=Copy(S,1,Pos(')',S)-1);
  end;
  If (Trim(ExtUpperCase(Result))='DEFAULT') or (Trim(ExtUpperCase(Result))='NONE') then Result:='';
end;

procedure TModernProfileEditorScummVMSoundFrame.SelectComboValue(const Combo: TComboBox; const Value: String);
Var S,T : String;
    I : Integer;
begin
  S:=Trim(ExtUpperCase(Value));
  Combo.ItemIndex:=0;
  If Combo.Items.Count=0 then exit;
  For I:=0 to Combo.Items.Count-1 do begin
    T:=Trim(ExtUpperCase(Combo.Items[I]));
    If Pos('(',T)=0 then begin
      If Trim(T)=S then begin Combo.ItemIndex:=I; exit; end;
    end else begin
      T:=Copy(T,Pos('(',T)+1,MaxInt);
      If Pos(')',T)=0 then continue;
      T:=Copy(T,1,Pos(')',T)-1);
      If Trim(T)=S then begin Combo.ItemIndex:=I; exit; end;
    end;
  end;
end;

procedure TModernProfileEditorScummVMSoundFrame.LoadGainUI(const Gain: Integer);
begin
  FUpdatingGainUI:=True;
  try
    SynthGainTrackBar.Position:=Max(SynthGainTrackBar.Min,Min(SynthGainTrackBar.Max,Gain));
    SynthGainValueEdit.Text:=IntToStr(SynthGainTrackBar.Position);
  finally
    FUpdatingGainUI:=False;
  end;
end;

procedure TModernProfileEditorScummVMSoundFrame.SynthGainTrackBarChange(Sender: TObject);
begin
  If FUpdatingGainUI then exit;
  SynthGainValueEdit.Text:=IntToStr(SynthGainTrackBar.Position);
end;

procedure TModernProfileEditorScummVMSoundFrame.UpdateDriverDependentPanels;
begin
  OplDriverLabel.Visible:=IsAdlibDriver;
  OplDriverComboBox.Visible:=IsAdlibDriver;
  NativeMT32CheckBox.Enabled:=IsMT32Driver or (SelectedMusicDriverCode='windows') or (SelectedMusicDriverCode='windows_midi');

  SynthSettingsGroupBox.Visible:=IsFluidSynthDriver or IsMT32Driver;
  If not SynthSettingsGroupBox.Visible then exit;

  SynthSettingsGroupBox.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynth;
  SynthGainValueEdit.EditLabel.Caption:='Gain';

  If IsFluidSynthDriver then begin
    SynthPathEdit.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynthSoundfont;
    SynthPathButton.Hint:=LanguageSetup.ChooseFile;
    If FGame<>nil then SynthPathEdit.Text:=Trim(FGame.FluidSoundFont) else SynthPathEdit.Text:='';
  end else begin
    SynthPathEdit.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundMIDIMT32RomDir+' (overwrites extrapath)';
    SynthPathButton.Hint:=LanguageSetup.ChooseFolder;
    If FGame<>nil then SynthPathEdit.Text:=Trim(FGame.MIDIMT32RomDir) else SynthPathEdit.Text:='';
  end;
end;

procedure TModernProfileEditorScummVMSoundFrame.MusicDriverComboBoxChange(Sender: TObject);
begin
  UpdateDriverDependentPanels;
end;

procedure TModernProfileEditorScummVMSoundFrame.SynthPathButtonClick(Sender: TObject);
Var S : String;
    OD : TOpenDialog;
begin
  S:=Trim(SynthPathEdit.Text);
  If S='' then S:=PrgSetup.BaseDir else S:=MakeAbsPath(S,PrgSetup.BaseDir);

  If IsMT32Driver then begin
    If not DirectoryExists(S) then
      If DirectoryExists(ExtractFilePath(S)) then S:=ExtractFilePath(S) else S:=PrgSetup.BaseDir;
    If not SelectDirectory(Handle,LanguageSetup.ChooseFolder,S) then exit;
    S:=MakeRelPath(IncludeTrailingPathDelimiter(S),PrgSetup.BaseDir);
    If S='' then exit;
    SynthPathEdit.Text:=S;
    exit;
  end;

  If not IsFluidSynthDriver then exit;

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
    SynthPathEdit.Text:=S;
  finally
    OD.Free;
  end;
end;

procedure TModernProfileEditorScummVMSoundFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var St : TStringList;
begin
  NoFlicker(MusicVolumeEdit);
  NoFlicker(SpeechVolumeEdit);
  NoFlicker(SFXVolumeEdit);
  NoFlicker(OutputRateComboBox);
  NoFlicker(MusicDriverComboBox);
  NoFlicker(OplDriverComboBox);
  NoFlicker(SynthSettingsGroupBox);
  NoFlicker(SynthGainTrackBar);
  NoFlicker(SynthGainValueEdit);
  NoFlicker(SynthPathEdit);
  NoFlicker(NativeMT32CheckBox);
  NoFlicker(EnableGSCheckBox);
  NoFlicker(MultiMIDICheckBox);
  NoFlicker(SpeechMuteCheckBox);

  MusicVolumeLabel.Caption:=LanguageSetup.ProfileEditorScummVMMusicVolume;
  SpeechVolumeLabel.Caption:=LanguageSetup.ProfileEditorScummVMSpeechVolume;
  SFXVolumeLabel.Caption:=LanguageSetup.ProfileEditorScummVMSFXVolume;
  OutputRateLabel.Caption:=LanguageSetup.ProfileEditorSoundSampleRate;
  MusicDriverLabel.Caption:=LanguageSetup.ProfileEditorScummVMMusicDriver;
  OplDriverLabel.Caption:=LanguageSetup.ProfileEditorScummVMOplDriver;
  NativeMT32CheckBox.Caption:=LanguageSetup.ProfileEditorScummVMNativeMT32;
  EnableGSCheckBox.Caption:=LanguageSetup.ProfileEditorScummVMEnableGS;
  MultiMIDICheckBox.Caption:=LanguageSetup.ProfileEditorScummVMMultiMIDI;
  SpeechMuteCheckBox.Caption:=LanguageSetup.ProfileEditorScummVMSpeechMute;

  with OutputRateComboBox.Items do begin Add('11025'); Add('22050'); Add('44100'); end;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMMusicDriver,';,'); try MusicDriverComboBox.Items.AddStrings(St); finally St.Free; end;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMOplDriver,';,'); try OplDriverComboBox.Items.AddStrings(St); finally St.Free; end;

  AddDefaultValueHint(MusicDriverComboBox);
  AddDefaultValueHint(OplDriverComboBox);

  SynthSettingsGroupBox.Caption:=LanguageSetup.ProfileEditorSoundMIDIFluidSynth;
  SynthGainValueEdit.EditLabel.Caption:='Gain';
  SynthGainTrackBar.Min:=0;
  SynthGainTrackBar.Max:=1000;
  SynthGainTrackBar.Frequency:=100;
  LoadGainUI(100);

  SynthSettingsGroupBox.Visible:=False;
  OplDriverLabel.Visible:=False;
  OplDriverComboBox.Visible:=False;
  SynthPathButton.ShowHint:=True;

  HelpContext:=ID_ProfileEditSound;
end;

procedure TModernProfileEditorScummVMSoundFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
Var S,T : String;
    I,J : Integer;
begin
  FGame:=Game;
  MusicVolumeEdit.Value:=Max(0,Min(255,Game.ScummVMMusicVolume));
  SpeechVolumeEdit.Value:=Max(0,Min(255,Game.ScummVMSpeechVolume));
  SFXVolumeEdit.Value:=Max(0,Min(255,Game.ScummVMSFXVolume));
  LoadGainUI(Game.ScummVMMIDIGain);
  Case Game.ScummVMSampleRate of
    11025 : OutputRateComboBox.ItemIndex:=0;
    22050 : OutputRateComboBox.ItemIndex:=1;
    44100 : OutputRateComboBox.ItemIndex:=2;
    else OutputRateComboBox.ItemIndex:=1;
  end;
  If MusicDriverComboBox.Items.Count>1 then MusicDriverComboBox.ItemIndex:=1;
  S:=Trim(ExtUpperCase(Game.ScummVMMusicDriver));
  If (S<>'') and (S[length(S)]=')') then SetLength(S,length(S)-1);
  For I:=0 to MusicDriverComboBox.Items.Count-1 do begin
    T:=Trim(MusicDriverComboBox.Items[I]);
    If (T<>'') and (T[length(T)]=')') then begin
      For J:=length(T)-1 downto 1 do If T[J]='(' then begin T:=Trim(Copy(T,J+1,MaxInt)); break; end;
    end;
    If (T<>'') and (T[length(T)]=')') then SetLength(T,length(T)-1);
    If ExtUpperCase(T)=S then begin MusicDriverComboBox.ItemIndex:=I; break; end;
  end;
  SelectComboValue(OplDriverComboBox,Game.ScummVMOplDriver);
  NativeMT32CheckBox.Checked:=Game.ScummVMNativeMT32;
  EnableGSCheckBox.Checked:=Game.ScummVMEnableGS;
  MultiMIDICheckBox.Checked:=Game.ScummVMMultiMIDI;
  SpeechMuteCheckBox.Checked:=Game.ScummVMSpeechMute;
  UpdateDriverDependentPanels;
end;

procedure TModernProfileEditorScummVMSoundFrame.GetGame(const Game: TGame);
Var S : String;
    I : Integer;
begin
  Game.ScummVMMusicVolume:=MusicVolumeEdit.Value;
  Game.ScummVMSpeechVolume:=SpeechVolumeEdit.Value;
  Game.ScummVMSFXVolume:=SFXVolumeEdit.Value;
  Game.ScummVMMIDIGain:=SynthGainTrackBar.Position;
  Case OutputRateComboBox.ItemIndex of
    0 : Game.ScummVMSampleRate:=11025;
    1 : Game.ScummVMSampleRate:=22050;
    2 : Game.ScummVMSampleRate:=44100;
  end;

  S:=Trim(MusicDriverComboBox.Text);
  If (S<>'') and (S[length(S)]=')') then begin
    For I:=length(S)-1 downto 1 do If S[I]='(' then begin S:=Trim(Copy(S,I+1,MaxInt)); break; end;
  end;
  If (S<>'') and (S[length(S)]=')') then SetLength(S,length(S)-1);
  Game.ScummVMMusicDriver:=S;
  Game.ScummVMOplDriver:=ComboStoredValue(OplDriverComboBox);

  If IsFluidSynthDriver then
    Game.FluidSoundFont:=Trim(SynthPathEdit.Text)
  else If IsMT32Driver then
    Game.MIDIMT32RomDir:=Trim(SynthPathEdit.Text);

  Game.ScummVMNativeMT32:=NativeMT32CheckBox.Checked;
  Game.ScummVMEnableGS:=EnableGSCheckBox.Checked;
  Game.ScummVMMultiMIDI:=MultiMIDICheckBox.Checked;
  Game.ScummVMSpeechMute:=SpeechMuteCheckBox.Checked;
end;

end.
