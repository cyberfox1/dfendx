unit ModernProfileEditorSoundFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, GameDBUnit, ModernProfileEditorFormUnit;

type
  TModernProfileEditorSoundFrame = class(TFrame, IModernProfileEditorFrame)
    ActivateSoundCheckBox: TCheckBox;
    MixerGroupBox: TGroupBox;
    SampleRateLabel: TLabel;
    BlockSizeLabel: TLabel;
    PreBufferLabel: TLabel;
    SampleRateComboBox: TComboBox;
    BlockSizeComboBox: TComboBox;
    PreBufferComboBox: TComboBox;
    ActivatePCSpeakerCheckBox: TCheckBox;
    PCSpeakerSampleRateLabel: TLabel;
    PCSpeakerSampleRateComboBox: TComboBox;
    TandyRadioGroup: TRadioGroup;
    TandySampleRateLabel: TLabel;
    TandyComboBox: TComboBox;
    ActivateDisneyCheckBox: TCheckBox;
    LptDacLabel: TLabel;
    LptDacComboBox: TComboBox;
    SwapStereoCheckBox: TCheckBox;
    SampleAccurateCheckBox: TCheckBox;
    DCBiasCheckBox: TCheckBox;
    CompressorCheckBox: TCheckBox;
    CrossfeedLabel: TLabel;
    ReverbLabel: TLabel;
    ChorusLabel: TLabel;
    CrossfeedComboBox: TComboBox;
    ReverbComboBox: TComboBox;
    ChorusComboBox: TComboBox;
    LptDacFilterLabel: TLabel;
    LptDacFilterComboBox: TComboBox;
    ActivatePS1AudioCheckBox: TCheckBox;
    PS1AudioRateLabel: TLabel;
    PS1AudioRateComboBox: TComboBox;
    procedure ActivatePCSpeakerCheckBoxClick(Sender: TObject);
    procedure TandyRadioGroupClick(Sender: TObject);
    procedure ActivatePS1AudioCheckBoxClick(Sender: TObject);
  private
    { Private-Deklarationen }
    FTempGame : TGame;
    FOldSampleRate, FOldBlockSize, FOldPreBuffer, FOldSpeakerRate, FOldTandyRate : Integer;
    FLptDacStagingConfOpt : String;
    FCrossfeedStagingConfOpt, FReverbStagingConfOpt, FChorusStagingConfOpt : String;
    FLptDacFilterStagingConfOpt, FPS1AudioRateConfOpt : String;
    FLoadedLptDac : String;
    FLoadedCrossfeed, FLoadedReverb, FLoadedChorus : String;
    FLoadedLptDacFilter, FLoadedPS1AudioRate : String;
    Procedure CheckValue(Sender : TObject; var OK : Boolean);
    Procedure ApplyVisibility;
    Procedure ApplySampleRateEnabled;
    Procedure ShowFrame(Sender : TObject);
    Procedure Invalidate(Sender : TObject);
  public
    { Public-Deklarationen }
    Constructor Create(AOwner : TComponent); override;
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses VistaToolsUnit, LanguageSetupUnit, CommonHelpers, HelpConsts;

{$R *.dfm}

{ TModernProfileEditorSoundFrame }

constructor TModernProfileEditorSoundFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
end;

procedure TModernProfileEditorSoundFrame.ApplyVisibility;
Var Staging, DBX : Boolean;
begin
  Staging:=FTempGame.IsStaging;
  DBX:=FTempGame.IsDBX;
  ActivatePCSpeakerCheckBox.Visible:=True;
  PCSpeakerSampleRateLabel.Visible:=not Staging;
  PCSpeakerSampleRateComboBox.Visible:=not Staging;
  TandySampleRateLabel.Visible:=not Staging;
  TandyComboBox.Visible:=not Staging;
  ActivateDisneyCheckBox.Visible:=not Staging;
  LptDacLabel.Visible:=Staging;
  LptDacComboBox.Visible:=Staging;
  SwapStereoCheckBox.Visible:=DBX;
  SampleAccurateCheckBox.Visible:=DBX;
  DCBiasCheckBox.Visible:=DBX;
  CompressorCheckBox.Visible:=Staging;
  CrossfeedLabel.Visible:=Staging;
  CrossfeedComboBox.Visible:=Staging;
  ReverbLabel.Visible:=Staging;
  ReverbComboBox.Visible:=Staging;
  ChorusLabel.Visible:=Staging;
  ChorusComboBox.Visible:=Staging;
  LptDacFilterLabel.Visible:=Staging;
  LptDacFilterComboBox.Visible:=Staging;
  ActivatePS1AudioCheckBox.Visible:=DBX;
  PS1AudioRateLabel.Visible:=DBX;
  PS1AudioRateComboBox.Visible:=DBX;
  If not Staging then begin
    SetComboNoSelect(LptDacComboBox);
    SetComboNoSelect(CrossfeedComboBox);
    SetComboNoSelect(ReverbComboBox);
    SetComboNoSelect(ChorusComboBox);
    SetComboNoSelect(LptDacFilterComboBox);
  end;
  If not DBX then
    SetComboNoSelect(PS1AudioRateComboBox);
  ApplySampleRateEnabled;
end;

procedure TModernProfileEditorSoundFrame.ApplySampleRateEnabled;
Var OnPC, OnTandy, OnPS1 : Boolean;
begin
  OnPC:=ActivatePCSpeakerCheckBox.Checked;
  OnTandy:=TandyRadioGroup.ItemIndex<>2;
  OnPS1:=ActivatePS1AudioCheckBox.Checked;
  PCSpeakerSampleRateLabel.Enabled:=OnPC;
  PCSpeakerSampleRateComboBox.Enabled:=OnPC;
  TandySampleRateLabel.Enabled:=OnTandy;
  TandyComboBox.Enabled:=OnTandy;
  PS1AudioRateLabel.Enabled:=OnPS1;
  PS1AudioRateComboBox.Enabled:=OnPS1;
end;

procedure TModernProfileEditorSoundFrame.ActivatePCSpeakerCheckBoxClick(Sender: TObject);
begin
  ApplySampleRateEnabled;
end;

procedure TModernProfileEditorSoundFrame.TandyRadioGroupClick(Sender: TObject);
begin
  ApplySampleRateEnabled;
end;

procedure TModernProfileEditorSoundFrame.ActivatePS1AudioCheckBoxClick(Sender: TObject);
begin
  ApplySampleRateEnabled;
end;

procedure TModernProfileEditorSoundFrame.ShowFrame(Sender: TObject);
begin
  ReloadComboFromConfOpt(LptDacComboBox,FLptDacStagingConfOpt,True,FLoadedLptDac);
  ReloadComboFromConfOpt(CrossfeedComboBox,FCrossfeedStagingConfOpt,True,FLoadedCrossfeed);
  ReloadComboFromConfOpt(ReverbComboBox,FReverbStagingConfOpt,True,FLoadedReverb);
  ReloadComboFromConfOpt(ChorusComboBox,FChorusStagingConfOpt,True,FLoadedChorus);
  ReloadComboFromConfOpt(LptDacFilterComboBox,FLptDacFilterStagingConfOpt,True,FLoadedLptDacFilter);
  ReloadComboFromConfOpt(PS1AudioRateComboBox,FPS1AudioRateConfOpt,True,FLoadedPS1AudioRate);
  ApplyVisibility;
end;

procedure TModernProfileEditorSoundFrame.Invalidate(Sender: TObject);
begin
  LptDacComboBox.ItemIndex:=-1;
  CrossfeedComboBox.ItemIndex:=-1;
  ReverbComboBox.ItemIndex:=-1;
  ChorusComboBox.ItemIndex:=-1;
  LptDacFilterComboBox.ItemIndex:=-1;
  PS1AudioRateComboBox.ItemIndex:=-1;
end;

procedure TModernProfileEditorSoundFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var St : TStringList;
begin
  InitData.OnCheckValue:=CheckValue;
  InitData.OnShowFrame:=ShowFrame;
  InitData.OnInvalidate:=Invalidate;

  NoFlicker(ActivateSoundCheckBox);
  NoFlicker(MixerGroupBox);
  NoFlicker(SampleRateComboBox);
  NoFlicker(BlockSizeComboBox);
  NoFlicker(PreBufferComboBox);
  NoFlicker(ActivatePCSpeakerCheckBox);
  NoFlicker(PCSpeakerSampleRateComboBox);
  NoFlicker(TandyComboBox);
  NoFlicker(LptDacComboBox);
  NoFlicker(SwapStereoCheckBox);
  NoFlicker(SampleAccurateCheckBox);
  NoFlicker(DCBiasCheckBox);
  NoFlicker(CompressorCheckBox);
  NoFlicker(CrossfeedComboBox);
  NoFlicker(ReverbComboBox);
  NoFlicker(ChorusComboBox);
  NoFlicker(LptDacFilterComboBox);
  NoFlicker(ActivatePS1AudioCheckBox);
  NoFlicker(PS1AudioRateComboBox);

  FLptDacStagingConfOpt:=InitData.GameDB.ConfOpt.LptDacStaging;
  FCrossfeedStagingConfOpt:=InitData.GameDB.ConfOpt.CrossfeedStaging;
  FReverbStagingConfOpt:=InitData.GameDB.ConfOpt.ReverbStaging;
  FChorusStagingConfOpt:=InitData.GameDB.ConfOpt.ChorusStaging;
  FLptDacFilterStagingConfOpt:=InitData.GameDB.ConfOpt.LptDacFilterStaging;
  FPS1AudioRateConfOpt:=InitData.GameDB.ConfOpt.Rate;

  ActivateSoundCheckBox.Caption:=LanguageSetup.ProfileEditorSoundEnableSound;
  MixerGroupBox.Caption:=LanguageSetup.ProfileEditorSoundMixer;
  SampleRateLabel.Caption:=LanguageSetup.ProfileEditorSoundSampleRate;
  St:=ValueToList(InitData.GameDB.ConfOpt.Rate,';,'); try SampleRateComboBox.Items.AddStrings(St); finally St.Free; end;
  BlockSizeLabel.Caption:=LanguageSetup.ProfileEditorSoundBlockSize;
  St:=ValueToList(InitData.GameDB.ConfOpt.Blocksize,';,'); try BlockSizeComboBox.Items.AddStrings(St); finally St.Free; end;
  PreBufferLabel.Caption:=LanguageSetup.ProfileEditorSoundPrebuffer;
  PreBufferComboBox.Items.BeginUpdate;
  try
    with PreBufferComboBox.Items do begin Add('1'); Add('5'); Add('10'); Add('15'); Add('20'); Add('25'); Add('30'); end;
  finally
    PreBufferComboBox.Items.EndUpdate;
  end;

  ActivatePCSpeakerCheckBox.Caption:=LanguageSetup.ProfileEditorSoundMiscEnablePCSpeaker;
  PCSpeakerSampleRateLabel.Caption:=LanguageSetup.ProfileEditorSoundMiscPCSpeakerRate;
  St:=ValueToList(InitData.GameDB.ConfOpt.PCRate,';,'); try PCSpeakerSampleRateComboBox.Items.AddStrings(St); finally St.Free; end;

  TandyRadioGroup.Caption:=LanguageSetup.ProfileEditorSoundMiscEnableTandy;
  TandyRadioGroup.Items[0]:=LanguageSetup.ProfileEditorSoundMiscEnableTandyAuto;
  TandyRadioGroup.Items[1]:=LanguageSetup.On;
  TandyRadioGroup.Items[2]:=LanguageSetup.Off;

  TandySampleRateLabel.Caption:=LanguageSetup.ProfileEditorSoundMiscTandyRate;
  St:=ValueToList(InitData.GameDB.ConfOpt.TandyRate,';,'); try TandyComboBox.Items.AddStrings(St); finally St.Free; end;

  ActivateDisneyCheckBox.Caption:=LanguageSetup.ProfileEditorSoundMiscEnableDisneySoundsSource;
  LptDacLabel.Caption:=LanguageSetup.ProfileEditorSoundMiscLptDac;
  SwapStereoCheckBox.Caption:=LanguageSetup.ProfileEditorSoundMixerSwapStereo;
  SampleAccurateCheckBox.Caption:=LanguageSetup.ProfileEditorSoundMixerSampleAccurate;
  DCBiasCheckBox.Caption:=LanguageSetup.ProfileEditorSoundMixerDCBiasCorrection;
  CompressorCheckBox.Caption:=LanguageSetup.ProfileEditorSoundMixerCompressor;
  CrossfeedLabel.Caption:=LanguageSetup.ProfileEditorSoundMixerCrossfeed;
  ReverbLabel.Caption:=LanguageSetup.ProfileEditorSoundMixerReverb;
  ChorusLabel.Caption:=LanguageSetup.ProfileEditorSoundMixerChorus;
  LptDacFilterLabel.Caption:=LanguageSetup.ProfileEditorSoundMiscLptDacFilter;
  ActivatePS1AudioCheckBox.Caption:=LanguageSetup.ProfileEditorSoundMiscPS1Audio;
  PS1AudioRateLabel.Caption:=LanguageSetup.ProfileEditorSoundMiscPS1AudioRate;
  RebuildComboFromConfOpt(LptDacComboBox,FLptDacStagingConfOpt,'');
  RebuildComboFromConfOpt(CrossfeedComboBox,FCrossfeedStagingConfOpt,'');
  RebuildComboFromConfOpt(ReverbComboBox,FReverbStagingConfOpt,'');
  RebuildComboFromConfOpt(ChorusComboBox,FChorusStagingConfOpt,'');
  RebuildComboFromConfOpt(LptDacFilterComboBox,FLptDacFilterStagingConfOpt,'');
  RebuildComboFromConfOpt(PS1AudioRateComboBox,FPS1AudioRateConfOpt,'');

  AddDefaultValueHint(SampleRateComboBox);
  AddDefaultValueHint(BlockSizeComboBox);
  AddDefaultValueHint(LptDacComboBox);
  AddDefaultValueHint(CrossfeedComboBox);
  AddDefaultValueHint(ReverbComboBox);
  AddDefaultValueHint(ChorusComboBox);
  AddDefaultValueHint(LptDacFilterComboBox);
  AddDefaultValueHint(PS1AudioRateComboBox);

  HelpContext:=ID_ProfileEditSound;
end;

procedure TModernProfileEditorSoundFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
Var I : Integer;
    S : String;
begin
  ActivateSoundCheckBox.Checked:=not Game.MixerNosound;
  SampleRateComboBox.ItemIndex:=SampleRateComboBox.Items.Count-2;
  For I:=0 to SampleRateComboBox.Items.Count-1 do If IntToStr(Game.MixerRate)=SampleRateComboBox.Items[I] then begin
    SampleRateComboBox.ItemIndex:=I; break;
  end;
  FOldSampleRate:=Game.MixerRate;
  BlockSizeComboBox.Text:=IntToStr(Game.MixerBlocksize);
  FOldBlockSize:=Game.MixerBlocksize;
  PreBufferComboBox.Text:=IntToStr(Game.MixerPrebuffer);
  FOldPreBuffer:=Game.MixerPrebuffer;

  ActivatePCSpeakerCheckBox.Checked:=Game.SpeakerPC;
  PCSpeakerSampleRateComboBox.ItemIndex:=PCSpeakerSampleRateComboBox.Items.Count-2;
  For I:=0 to PCSpeakerSampleRateComboBox.Items.Count-1 do If IntToStr(Game.SpeakerRate)=PCSpeakerSampleRateComboBox.Items[I] then begin
    PCSpeakerSampleRateComboBox.ItemIndex:=I; break;
  end;
  FOldSpeakerRate:=Game.SpeakerRate;

  S:=Trim(ExtUpperCase(Game.SpeakerTandy));
  TandyRadioGroup.ItemIndex:=0;
  If (S='AUTO') or (S='DEFAULT') or (S='') then TandyRadioGroup.ItemIndex:=0;
  If S='ON' then TandyRadioGroup.ItemIndex:=1;
  If S='OFF' then TandyRadioGroup.ItemIndex:=2;
  TandyComboBox.ItemIndex:=TandyComboBox.Items.Count-2;
  For I:=0 to TandyComboBox.Items.Count-1 do If IntToStr(Game.SpeakerTandyRate)=TandyComboBox.Items[I] then begin
    TandyComboBox.ItemIndex:=I; break;
  end;
  FOldTandyRate:=Game.SpeakerTandyRate;

  ActivateDisneyCheckBox.Checked:=Game.SpeakerDisney;
  SwapStereoCheckBox.Checked:=Game.MixerSwapStereo;
  SampleAccurateCheckBox.Checked:=Game.MixerSampleAccurate;
  DCBiasCheckBox.Checked:=Game.MixerDCBiasCorrection;
  CompressorCheckBox.Checked:=Game.MixerCompressor;
  FLoadedLptDac:=Trim(Game.SpeakerLptDac);
  FLoadedCrossfeed:=Trim(Game.MixerCrossfeed);
  FLoadedReverb:=Trim(Game.MixerReverb);
  FLoadedChorus:=Trim(Game.MixerChorus);
  FLoadedLptDacFilter:=Trim(Game.SpeakerLptDacFilter);
  ActivatePS1AudioCheckBox.Checked:=Game.PS1Audio;
  FLoadedPS1AudioRate:=Trim(Game.PS1AudioRate);
  ShowFrame(nil);
end;

Procedure TModernProfileEditorSoundFrame.CheckValue(Sender : TObject; var OK : Boolean);
Var I : Integer;
begin
  Ok:=True;

  If (not TryStrToInt(Trim(SampleRateComboBox.Text),I)) or (I<1) or (I>65536) then begin
    If MessageDlg(Format(LanguageSetup.MessageInvalidValue,[SampleRateComboBox.Text,LanguageSetup.ProfileEditorSoundSampleRate,IntToStr(FOldSampleRate)]),mtWarning,[mbYes,mbNo],0)<>mrYes then begin
      Ok:=False; exit;
    end;
  end;

  If (not TryStrToInt(Trim(BlockSizeComboBox.Text),I)) or (I<1) or (I>65536) then begin
    If MessageDlg(Format(LanguageSetup.MessageInvalidValue,[BlockSizeComboBox.Text,LanguageSetup.ProfileEditorSoundBlockSize,IntToStr(FOldBlockSize)]),mtWarning,[mbYes,mbNo],0)<>mrYes then begin
      Ok:=False; exit;
    end;
  end;

  If (not TryStrToInt(Trim(PreBufferComboBox.Text),I)) or (I<1) or (I>65536) then begin
    If MessageDlg(Format(LanguageSetup.MessageInvalidValue,[PreBufferComboBox.Text,LanguageSetup.ProfileEditorSoundPrebuffer,IntToStr(FOldPreBuffer)]),mtWarning,[mbYes,mbNo],0)<>mrYes then begin
      Ok:=False; exit;
    end;
  end;

  If not FTempGame.IsStaging then begin
    If PCSpeakerSampleRateComboBox.Enabled and ((not TryStrToInt(Trim(PCSpeakerSampleRateComboBox.Text),I)) or (I<1) or (I>65536)) then begin
      If MessageDlg(Format(LanguageSetup.MessageInvalidValue,[PCSpeakerSampleRateComboBox.Text,LanguageSetup.ProfileEditorSoundMiscPCSpeakerRate,IntToStr(FOldSpeakerRate)]),mtWarning,[mbYes,mbNo],0)<>mrYes then begin
        Ok:=False; exit;
      end;
    end;

    If TandyComboBox.Enabled and ((not TryStrToInt(Trim(TandyComboBox.Text),I)) or (I<1) or (I>65536)) then begin
      If MessageDlg(Format(LanguageSetup.MessageInvalidValue,[TandyComboBox.Text,LanguageSetup.ProfileEditorSoundMiscTandyRate,IntToStr(FOldTandyRate)]),mtWarning,[mbYes,mbNo],0)<>mrYes then begin
        Ok:=False; exit;
      end;
    end;
  end;
end;

procedure TModernProfileEditorSoundFrame.GetGame(const Game: TGame);
Var I : Integer;
begin
  Game.MixerNosound:=not ActivateSoundCheckBox.Checked;
  If TryStrToInt(Trim(SampleRateComboBox.Text),I) and (I>=1) and (I<=65536) then Game.MixerRate:=I;
  If TryStrToInt(Trim(BlockSizeComboBox.Text),I) and (I>=1) and (I<=65536) then Game.MixerBlocksize:=I;
  If TryStrToInt(Trim(PreBufferComboBox.Text),I) and (I>=1) and (I<=65536) then Game.MixerPrebuffer:=I;

  Game.SpeakerPC:=ActivatePCSpeakerCheckBox.Checked;
  Game.SpeakerDisney:=ActivateDisneyCheckBox.Checked;
  If FTempGame.IsStaging then begin
    If LptDacComboBox.ItemIndex>=0 then
      Game.SpeakerLptDac:=LptDacComboBox.Text;
    Game.MixerCompressor:=CompressorCheckBox.Checked;
    If CrossfeedComboBox.ItemIndex>=0 then
      Game.MixerCrossfeed:=CrossfeedComboBox.Text;
    If ReverbComboBox.ItemIndex>=0 then
      Game.MixerReverb:=ReverbComboBox.Text;
    If ChorusComboBox.ItemIndex>=0 then
      Game.MixerChorus:=ChorusComboBox.Text;
    If LptDacFilterComboBox.ItemIndex>=0 then
      Game.SpeakerLptDacFilter:=LptDacFilterComboBox.Text;
  end else begin
    If PCSpeakerSampleRateComboBox.Enabled and TryStrToInt(Trim(PCSpeakerSampleRateComboBox.Text),I) and (I>=1) and (I<=65536) then Game.SpeakerRate:=I;
  end;
  If FTempGame.IsDBX then begin
    Game.MixerSwapStereo:=SwapStereoCheckBox.Checked;
    Game.MixerSampleAccurate:=SampleAccurateCheckBox.Checked;
    Game.MixerDCBiasCorrection:=DCBiasCheckBox.Checked;
    Game.PS1Audio:=ActivatePS1AudioCheckBox.Checked;
    If PS1AudioRateComboBox.Enabled and (PS1AudioRateComboBox.ItemIndex>=0) then
      Game.PS1AudioRate:=PS1AudioRateComboBox.Text;
  end;

  Case TandyRadioGroup.ItemIndex of
    0 : Game.SpeakerTandy:='auto';
    1 : Game.SpeakerTandy:='on';
    2 : Game.SpeakerTandy:='off';
  end;
  If (not FTempGame.IsStaging) and TandyComboBox.Enabled then
    If TryStrToInt(Trim(TandyComboBox.Text),I) and (I>=1) and (I<=65536) then Game.SpeakerTandyRate:=I;
end;

end.
