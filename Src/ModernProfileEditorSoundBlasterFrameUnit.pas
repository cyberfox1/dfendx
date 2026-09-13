unit ModernProfileEditorSoundBlasterFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Spin, GameDBUnit, ModernProfileEditorFormUnit, PrgConsts;

type
  TModernProfileEditorSoundBlasterFrame = class(TFrame, IModernProfileEditorFrame)
    TypeLabel: TLabel;
    TypeComboBox: TComboBox;
    AddressComboBox: TComboBox;
    AddressLabel: TLabel;
    InterruptComboBox: TComboBox;
    InterruptLabel: TLabel;
    DMAComboBox: TComboBox;
    DMALabel: TLabel;
    HDMAComboBox: TComboBox;
    HDMALabel: TLabel;
    OplModeComboBox: TComboBox;
    OplModeLabel: TLabel;
    OplSampleRateComboBox: TComboBox;
    OplSampleRateLabel: TLabel;
    UseMixerCheckBox: TCheckBox;
    OplEmuComboBox: TComboBox;
    OplEmuLabel: TLabel;
    ActivateCMSCheckBox: TCheckBox;
    GoldplayCheckBox: TCheckBox;
    FilterLabel: TLabel;
    FilterComboBox: TComboBox;
    FilterAlwaysOnCheckBox: TCheckBox;
    WarmupLabel: TLabel;
    WarmupEdit: TSpinEdit;
  private
    { Private-Deklarationen }
    FTempGame : TGame;
    FSblasterConfOpt, FSblasterStagingConfOpt, FSblasterXConfOpt : String;
    FOplmodeConfOpt, FOplmodeStagingConfOpt, FOplmodeXConfOpt : String;
    FOplEmuConfOpt, FOplEmuXConfOpt, FOplEmuPureConfOpt : String;
    FSBFilterStagingConfOpt : String;
    FLoadedSBType, FLoadedOplMode, FLoadedOplEmu, FLoadedSBFilter : String;
    function GetSelectedDosBoxKind : TDOSBoxKind;
    procedure ApplyLists;
    procedure ApplyVisibility;
    procedure ShowFrame(Sender : TObject);
    procedure Invalidate(Sender : TObject);
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

{ TModernProfileEditorSoundBlasterFrame }

constructor TModernProfileEditorSoundBlasterFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
end;

procedure TModernProfileEditorSoundBlasterFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var St : TStringList;
begin
  NoFlicker(TypeComboBox);
  NoFlicker(AddressComboBox);
  NoFlicker(InterruptComboBox);
  NoFlicker(DMAComboBox);
  NoFlicker(HDMAComboBox);
  NoFlicker(OplModeComboBox);
  NoFlicker(OplEmuComboBox);
  NoFlicker(OplSampleRateComboBox);
  NoFlicker(UseMixerCheckBox);
  NoFlicker(ActivateCMSCheckBox);
  NoFlicker(GoldplayCheckBox);
  NoFlicker(FilterComboBox);
  NoFlicker(FilterAlwaysOnCheckBox);
  NoFlicker(WarmupEdit);

  FSblasterConfOpt:=InitData.GameDB.ConfOpt.Sblaster;
  FSblasterStagingConfOpt:=InitData.GameDB.ConfOpt.SblasterStaging;
  FSblasterXConfOpt:=InitData.GameDB.ConfOpt.SblasterX;
  FOplmodeConfOpt:=InitData.GameDB.ConfOpt.Oplmode;
  FOplmodeStagingConfOpt:=InitData.GameDB.ConfOpt.OplmodeStaging;
  FOplmodeXConfOpt:=InitData.GameDB.ConfOpt.OplmodeX;
  FOplEmuConfOpt:=InitData.GameDB.ConfOpt.OplEmu;
  FOplEmuXConfOpt:=InitData.GameDB.ConfOpt.OplEmuX;
  FOplEmuPureConfOpt:=InitData.GameDB.ConfOpt.OplEmuPure;
  FSBFilterStagingConfOpt:=InitData.GameDB.ConfOpt.SBFilterStaging;
  InitData.OnShowFrame:=ShowFrame;
  InitData.OnInvalidate:=Invalidate;

  TypeLabel.Caption:=LanguageSetup.ProfileEditorSoundSBType;
  AddressLabel.Caption:=LanguageSetup.ProfileEditorSoundSBAddress;
  St:=ValueToList(InitData.GameDB.ConfOpt.SBBase,';,'); try AddressComboBox.Items.AddStrings(St); finally St.Free; end;
  InterruptLabel.Caption:=LanguageSetup.ProfileEditorSoundSBIRQ;
  St:=ValueToList(InitData.GameDB.ConfOpt.IRQ,';,'); try InterruptComboBox.Items.AddStrings(St); finally St.Free; end;
  DMALabel.Caption:=LanguageSetup.ProfileEditorSoundSBDMA;
  St:=ValueToList(InitData.GameDB.ConfOpt.DMA,';,'); try DMAComboBox.Items.AddStrings(St); finally St.Free; end;
  HDMALabel.Caption:=LanguageSetup.ProfileEditorSoundSBHDMA;
  St:=ValueToList(InitData.GameDB.ConfOpt.HDMA,';,'); try HDMAComboBox.Items.AddStrings(St); finally St.Free; end;
  OplModeLabel.Caption:=LanguageSetup.ProfileEditorSoundSBOplMode;
  OplEmuLabel.Caption:=LanguageSetup.GameOplemu;
  OplSampleRateLabel.Caption:=LanguageSetup.ProfileEditorSoundSBOplRate;
  St:=ValueToList(InitData.GameDB.ConfOpt.OPLRate,';,'); try OplSampleRateComboBox.Items.AddStrings(St); finally St.Free; end;
  UseMixerCheckBox.Caption:=LanguageSetup.ProfileEditorSoundSBUseMixer;
  ActivateCMSCheckBox.Caption:=LanguageSetup.ProfileEditorSoundSBCMS;
  GoldplayCheckBox.Caption:=LanguageSetup.ProfileEditorSoundSBGoldplay;
  FilterLabel.Caption:=LanguageSetup.ProfileEditorSoundSBFilter;
  FilterAlwaysOnCheckBox.Caption:=LanguageSetup.ProfileEditorSoundSBFilterAlwaysOn;
  WarmupLabel.Caption:=LanguageSetup.ProfileEditorSoundSBWarmup;

  AddDefaultValueHint(TypeComboBox);
  AddDefaultValueHint(AddressComboBox);
  AddDefaultValueHint(InterruptComboBox);
  AddDefaultValueHint(DMAComboBox);
  AddDefaultValueHint(HDMAComboBox);
  AddDefaultValueHint(OplModeComboBox);
  AddDefaultValueHint(OplEmuComboBox);
  AddDefaultValueHint(OplSampleRateComboBox);
  AddDefaultValueHint(FilterComboBox);

  HelpContext:=ID_ProfileEditSoundSoundBlaster;
end;

Procedure SetComboBox(const ComboBox : TComboBox; const Value : String; const Default : Integer); overload;
Var S : String;
    I : Integer;
begin
  ComboBox.ItemIndex:=Default;
  S:=Trim(ExtUpperCase(Value));
  For I:=0 to ComboBox.Items.Count-1 do If Trim(ExtUpperCase(ComboBox.Items[I]))=S then begin
    ComboBox.ItemIndex:=I; break;
  end;
end;

Procedure SetComboBox(const ComboBox : TComboBox; const Value : String; const Default : String); overload;
begin
  SetComboBox(ComboBox,Default,0);
  SetComboBox(ComboBox,Value,ComboBox.ItemIndex);
end;

function TModernProfileEditorSoundBlasterFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  Result:=FTempGame.DosBoxKind;
end;

procedure TModernProfileEditorSoundBlasterFrame.ApplyLists;
Var Kind : TDOSBoxKind;
    TypeList, ModeList, EmuList : String;
begin
  Kind:=GetSelectedDosBoxKind;
  Case Kind of
    dbkStaging: TypeList:=FSblasterStagingConfOpt;
    dbkX:       TypeList:=FSblasterXConfOpt;
    else        TypeList:=FSblasterConfOpt;
  end;
  Case Kind of
    dbkStaging: ModeList:=FOplmodeStagingConfOpt;
    dbkX:       ModeList:=FOplmodeXConfOpt;
    else        ModeList:=FOplmodeConfOpt;
  end;
  Case Kind of
    dbkX:    EmuList:=FOplEmuXConfOpt;
    dbkPure: EmuList:=FOplEmuPureConfOpt;
    else     EmuList:=FOplEmuConfOpt;
  end;
  ReloadComboFromConfOpt(TypeComboBox,TypeList,True,FLoadedSBType);
  ReloadComboFromConfOpt(OplModeComboBox,ModeList,True,FLoadedOplMode);
  ReloadComboFromConfOpt(OplEmuComboBox,EmuList,True,FLoadedOplEmu);
end;

procedure TModernProfileEditorSoundBlasterFrame.ApplyVisibility;
Var Staging, ShowCMS, ShowGoldplay : Boolean;
begin
  Staging:=FTempGame.IsStaging;
  ShowCMS:=Staging or FTempGame.IsDBX;
  ShowGoldplay:=FTempGame.IsDBX;
  OplEmuLabel.Visible:=not Staging;
  OplEmuComboBox.Visible:=not Staging;
  OplSampleRateLabel.Visible:=not Staging;
  OplSampleRateComboBox.Visible:=not Staging;
  ActivateCMSCheckBox.Visible:=ShowCMS;
  GoldplayCheckBox.Visible:=ShowGoldplay;
  FilterLabel.Visible:=Staging;
  FilterComboBox.Visible:=Staging;
  FilterAlwaysOnCheckBox.Visible:=Staging;
  WarmupLabel.Visible:=Staging;
  WarmupEdit.Visible:=Staging;
  If not Staging then SetComboNoSelect(FilterComboBox);
end;

procedure TModernProfileEditorSoundBlasterFrame.ShowFrame(Sender: TObject);
begin
  ApplyLists;
  ReloadComboFromConfOpt(FilterComboBox,FSBFilterStagingConfOpt,True,FLoadedSBFilter);
  ApplyVisibility;
end;

procedure TModernProfileEditorSoundBlasterFrame.Invalidate(Sender: TObject);
begin
  TypeComboBox.ItemIndex:=-1;
  OplModeComboBox.ItemIndex:=-1;
  OplEmuComboBox.ItemIndex:=-1;
  FilterComboBox.ItemIndex:=-1;
end;

procedure TModernProfileEditorSoundBlasterFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
begin
  FLoadedSBType:=Game.SBType;
  FLoadedOplMode:=Game.SBOplMode;
  FLoadedOplEmu:=Game.SBOplEmu;
  FLoadedSBFilter:=Game.SBFilter;
  SetComboBox(AddressComboBox,Game.SBBase,'220');
  SetComboBox(InterruptComboBox,IntToStr(Game.SBIRQ),'7');
  SetComboBox(DMAComboBox,IntToStr(Game.SBDMA),'1');
  SetComboBox(HDMAComboBox,IntToStr(Game.SBHDMA),'5');
  SetComboBox(OplSampleRateComboBox,IntToStr(Game.SBOplRate),'22050');
  UseMixerCheckBox.Checked:=Game.SBMixer;
  ActivateCMSCheckBox.Checked:=Game.SBCMS;
  GoldplayCheckBox.Checked:=Game.SBGoldplay;
  FilterAlwaysOnCheckBox.Checked:=Game.SBFilterAlwaysOn;
  WarmupEdit.Value:=Game.SBWarmup;
  ShowFrame(nil);
end;

procedure TModernProfileEditorSoundBlasterFrame.GetGame(const Game: TGame);
begin
  If TypeComboBox.ItemIndex>=0 then
    Game.SBType:=TypeComboBox.Text;
  If AddressComboBox.ItemIndex>=0 then
    try Game.SBBase:=AddressComboBox.Text; except end;
  If InterruptComboBox.ItemIndex>=0 then
    try Game.SBIRQ:=StrToInt(InterruptComboBox.Text); except end;
  If DMAComboBox.ItemIndex>=0 then
    try Game.SBDMA:=StrToInt(DMAComboBox.Text); except end;
  If HDMAComboBox.ItemIndex>=0 then
    try Game.SBHDMA:=StrToInt(HDMAComboBox.Text); except end;
  If OplModeComboBox.ItemIndex>=0 then
    Game.SBOplMode:=OplModeComboBox.Text;
  If not FTempGame.IsStaging then begin
    If OplEmuComboBox.ItemIndex>=0 then
      Game.SBOplEmu:=OplEmuComboBox.Text;
    If OplSampleRateComboBox.ItemIndex>=0 then
      try Game.SBOplRate:=StrToInt(OplSampleRateComboBox.Text); except end;
  end;
  Game.SBMixer:=UseMixerCheckBox.Checked;
  If FTempGame.IsStaging or FTempGame.IsDBX then
    Game.SBCMS:=ActivateCMSCheckBox.Checked;
  If FTempGame.IsDBX then
    Game.SBGoldplay:=GoldplayCheckBox.Checked;
  If FTempGame.IsStaging then begin
    If FilterComboBox.ItemIndex>=0 then
      Game.SBFilter:=FilterComboBox.Text;
    Game.SBFilterAlwaysOn:=FilterAlwaysOnCheckBox.Checked;
    Game.SBWarmup:=WarmupEdit.Value;
  end;
end;

end.
