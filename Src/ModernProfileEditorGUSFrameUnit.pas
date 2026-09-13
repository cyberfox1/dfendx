unit ModernProfileEditorGUSFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, ExtCtrls, GameDBUnit, ModernProfileEditorFormUnit;

type
  TModernProfileEditorGUSFrame = class(TFrame, IModernProfileEditorFrame)
    ActivateGUSCheckBox: TCheckBox;
    AddressLabel: TLabel;
    AddressComboBox: TComboBox;
    SampleRateLabel: TLabel;
    SampleRateComboBox: TComboBox;
    Interrupt1ComboBox: TComboBox;
    Interrupt1Label: TLabel;
    DMA1ComboBox: TComboBox;
    DMA1Label: TLabel;
    PathEdit: TLabeledEdit;
    FilterLabel: TLabel;
    FilterComboBox: TComboBox;
    TypeLabel: TLabel;
    TypeComboBox: TComboBox;
    MemSizeLabel: TLabel;
    MemSizeComboBox: TComboBox;
    MasterVolumeLabel: TLabel;
    MasterVolumeComboBox: TComboBox;
  private
    { Private-Deklarationen }
    FTempGame : TGame;
    FGUSFilterStagingConfOpt, FGUSMemSizeXConfOpt, FGUSTypeXConfOpt, FGUSMasterVolumeXConfOpt : String;
    FLoadedGUSFilter, FLoadedGUSType, FLoadedGUSMemSize, FLoadedGUSMasterVolume : String;
    Procedure ApplyVisibility;
    Procedure ApplyEnabled;
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

{ TFrame1 }

constructor TModernProfileEditorGUSFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
end;

procedure TModernProfileEditorGUSFrame.ApplyVisibility;
Var Staging : Boolean;
begin
  Staging:=FTempGame.IsStaging;
  SampleRateLabel.Visible:=not Staging;
  SampleRateComboBox.Visible:=not Staging;
end;

procedure TModernProfileEditorGUSFrame.ApplyEnabled;
Var Staging, DBX : Boolean;
begin
  Staging:=FTempGame.IsStaging;
  DBX:=FTempGame.IsDBX;
  FilterLabel.Enabled:=Staging;
  FilterComboBox.Enabled:=Staging;
  TypeLabel.Enabled:=DBX;
  TypeComboBox.Enabled:=DBX;
  MemSizeLabel.Enabled:=DBX;
  MemSizeComboBox.Enabled:=DBX;
  MasterVolumeLabel.Enabled:=DBX;
  MasterVolumeComboBox.Enabled:=DBX;
  If not Staging then SetComboNoSelect(FilterComboBox);
  If not DBX then begin
    SetComboNoSelect(TypeComboBox);
    SetComboNoSelect(MemSizeComboBox);
    SetComboNoSelect(MasterVolumeComboBox);
  end;
end;

procedure TModernProfileEditorGUSFrame.ShowFrame(Sender: TObject);
begin
  ReloadComboFromConfOpt(FilterComboBox,FGUSFilterStagingConfOpt,True,FLoadedGUSFilter);
  ReloadComboFromConfOpt(TypeComboBox,FGUSTypeXConfOpt,True,FLoadedGUSType);
  ReloadComboFromConfOpt(MemSizeComboBox,FGUSMemSizeXConfOpt,True,FLoadedGUSMemSize);
  ReloadComboFromConfOpt(MasterVolumeComboBox,FGUSMasterVolumeXConfOpt,True,FLoadedGUSMasterVolume);
  ApplyVisibility;
  ApplyEnabled;
end;

procedure TModernProfileEditorGUSFrame.Invalidate(Sender: TObject);
begin
  FilterComboBox.ItemIndex:=-1;
  TypeComboBox.ItemIndex:=-1;
  MemSizeComboBox.ItemIndex:=-1;
  MasterVolumeComboBox.ItemIndex:=-1;
end;

procedure TModernProfileEditorGUSFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var St : TStringList;
begin
  InitData.OnShowFrame:=ShowFrame;
  InitData.OnInvalidate:=Invalidate;

  NoFlicker(ActivateGUSCheckBox);
  NoFlicker(AddressComboBox);
  NoFlicker(SampleRateComboBox);
  NoFlicker(Interrupt1ComboBox);
  NoFlicker(DMA1ComboBox);
  NoFlicker(PathEdit);
  NoFlicker(FilterComboBox);
  NoFlicker(TypeComboBox);
  NoFlicker(MemSizeComboBox);
  NoFlicker(MasterVolumeComboBox);

  FGUSFilterStagingConfOpt:=InitData.GameDB.ConfOpt.GUSFilterStaging;
  FGUSMemSizeXConfOpt:=InitData.GameDB.ConfOpt.GUSMemSizeX;
  FGUSTypeXConfOpt:=InitData.GameDB.ConfOpt.GUSTypeX;
  FGUSMasterVolumeXConfOpt:=InitData.GameDB.ConfOpt.GUSMasterVolumeX;

  ActivateGUSCheckBox.Caption:=LanguageSetup.ProfileEditorSoundGUSEnabled;
  AddressLabel.Caption:=LanguageSetup.ProfileEditorSoundGUSAddress;
  St:=ValueToList(InitData.GameDB.ConfOpt.GUSBase,';,'); try AddressComboBox.Items.AddStrings(St); finally St.Free; end;
  SampleRateLabel.Caption:=LanguageSetup.ProfileEditorSoundGUSRate;
  St:=ValueToList(InitData.GameDB.ConfOpt.GUSRate,';,'); try SampleRateComboBox.Items.AddStrings(St); finally St.Free; end;
  Interrupt1Label.Caption:=LanguageSetup.ProfileEditorSoundGUSIRQ;
  St:=ValueToList(InitData.GameDB.ConfOpt.GUSIRQ,';,'); try Interrupt1ComboBox.Items.AddStrings(St); finally St.Free; end;
  DMA1Label.Caption:=LanguageSetup.ProfileEditorSoundGUSDMA;
  St:=ValueToList(InitData.GameDB.ConfOpt.GUSDma,';,'); try DMA1ComboBox.Items.AddStrings(St); finally St.Free; end;
  PathEdit.EditLabel.Caption:=LanguageSetup.ProfileEditorSoundGUSPath;
  RebuildComboFromConfOpt(FilterComboBox,FGUSFilterStagingConfOpt,'');
  RebuildComboFromConfOpt(TypeComboBox,FGUSTypeXConfOpt,'');
  RebuildComboFromConfOpt(MemSizeComboBox,FGUSMemSizeXConfOpt,'');
  RebuildComboFromConfOpt(MasterVolumeComboBox,FGUSMasterVolumeXConfOpt,'');
  FilterLabel.Caption:=LanguageSetup.ProfileEditorSoundGUSFilter;
  TypeLabel.Caption:=LanguageSetup.ProfileEditorSoundGUSType;
  MemSizeLabel.Caption:=LanguageSetup.ProfileEditorSoundGUSMemSize;
  MasterVolumeLabel.Caption:=LanguageSetup.ProfileEditorSoundGUSMasterVolume;

  AddDefaultValueHint(AddressComboBox);
  AddDefaultValueHint(SampleRateComboBox);
  AddDefaultValueHint(Interrupt1ComboBox);
  AddDefaultValueHint(DMA1ComboBox);
  AddDefaultValueHint(FilterComboBox);
  AddDefaultValueHint(TypeComboBox);
  AddDefaultValueHint(MemSizeComboBox);
  AddDefaultValueHint(MasterVolumeComboBox);

  HelpContext:=ID_ProfileEditSoundGUS;
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

procedure TModernProfileEditorGUSFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
begin
  ActivateGUSCheckBox.Checked:=Game.GUS;
  SetComboBox(AddressComboBox,Game.GUSBase,'240');
  SetComboBox(SampleRateComboBox,IntToStr(Game.GUSRate),'22050');
  SetComboBox(Interrupt1ComboBox,IntToStr(Game.GUSIRQ),'5');
  SetComboBox(DMA1ComboBox,IntToStr(Game.GUSDMA),'1');
  PathEdit.Text:=Game.GUSUltraDir;
  FLoadedGUSFilter:=Game.GUSFilter;
  FLoadedGUSType:=Game.GUSType;
  FLoadedGUSMemSize:=Trim(Game.GUSMemSize);
  FLoadedGUSMasterVolume:=Game.GUSMasterVolume;
  ShowFrame(nil);
end;

procedure TModernProfileEditorGUSFrame.GetGame(const Game: TGame);
begin
  Game.GUS:=ActivateGUSCheckBox.Checked;
  If AddressComboBox.ItemIndex>=0 then
    Game.GUSBase:=AddressComboBox.Text;
  If (not FTempGame.IsStaging) and (SampleRateComboBox.ItemIndex>=0) then
    try Game.GUSRate:=StrtoInt(SampleRateComboBox.Text); except end;
  If Interrupt1ComboBox.ItemIndex>=0 then
    try Game.GUSIRQ:=StrtoInt(Interrupt1ComboBox.Text); except end;
  If DMA1ComboBox.ItemIndex>=0 then
    try Game.GUSDMA:=StrtoInt(DMA1ComboBox.Text); except end;
  Game.GUSUltraDir:=PathEdit.Text;
  If FTempGame.IsStaging and (FilterComboBox.ItemIndex>=0) then
    Game.GUSFilter:=FilterComboBox.Text;
  If FTempGame.IsDBX then begin
    If TypeComboBox.ItemIndex>=0 then
      Game.GUSType:=TypeComboBox.Text;
    If MemSizeComboBox.ItemIndex>=0 then
      Game.GUSMemSize:=MemSizeComboBox.Text;
    If MasterVolumeComboBox.ItemIndex>=0 then
      Game.GUSMasterVolume:=Trim(MasterVolumeComboBox.Text);
  end;
end;

end.
