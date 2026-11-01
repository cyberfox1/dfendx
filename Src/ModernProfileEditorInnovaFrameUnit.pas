unit ModernProfileEditorInnovaFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, GameDBUnit, ModernProfileEditorFormUnit, StdCtrls;

type
  TModernProfileEditorInnovaFrame=class(TFrame, IModernProfileEditorFrame)
    EnableInnovaCheckBox: TCheckBox;
    InnovaSampleRateLabel: TLabel;
    InnovaBaseLabel: TLabel;
    InnovaQualityLabel: TLabel;
    InnovaSampleRateComboBox: TComboBox;
    InnovaBaseComboBox: TComboBox;
    InnovaQualityComboBox: TComboBox;
    cbInnovationEntertainer: TCheckBox;
  private
    { Private-Deklarationen }
    FTempGame : TGame;
    Procedure ShowFrame(Sender : TObject);
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

{ TModernProfileEditorInnovaFrame }

constructor TModernProfileEditorInnovaFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
end;

procedure TModernProfileEditorInnovaFrame.InitGUI(var InitData: TModernProfileEditorInitData);
Var St : TStringList;
begin
  NoFlicker(EnableInnovaCheckBox);
  NoFlicker(InnovaSampleRateComboBox);
  NoFlicker(InnovaBaseComboBox);
  NoFlicker(InnovaQualityComboBox);
  NoFlicker(cbInnovationEntertainer);

  EnableInnovaCheckBox.Caption:=LanguageSetup.ProfileEditorSoundInnovaEnable;
  cbInnovationEntertainer.Caption:=LanguageSetup.ProfileEditorSoundInnovaEntertainer;
  InnovaSampleRateLabel.Caption:=LanguageSetup.ProfileEditorSoundInnovaSampleRate;
  InnovaBaseLabel.Caption:=LanguageSetup.ProfileEditorSoundInnovaBaseAddress;
  InnovaQualityLabel.Caption:=LanguageSetup.ProfileEditorSoundInnovaQuality;

  St:=ValueToList(InitData.GameDB.ConfOpt.InnovaEmulationSampleRate,';,');
  try
    InnovaSampleRateComboBox.Items.Clear;
    InnovaSampleRateComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;

  St:=ValueToList(InitData.GameDB.ConfOpt.InnovaEmulationBaseAddress,';,');
  try
    InnovaBaseComboBox.Items.Clear;
    InnovaBaseComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;

  St:=ValueToList(InitData.GameDB.ConfOpt.InnovaEmulationQuality,';,');
  try
    InnovaQualityComboBox.Items.Clear;
    InnovaQualityComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;

  InitData.OnShowFrame:=ShowFrame;
  HelpContext:=ID_ProfileEditSoundInnova;
end;

procedure TModernProfileEditorInnovaFrame.ShowFrame(Sender: TObject);
begin
  cbInnovationEntertainer.Enabled:=FTempGame.IsNewStaging;
end;

procedure TModernProfileEditorInnovaFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
Var I : Integer;
    S : String;
begin
  EnableInnovaCheckBox.Checked:=Game.Innova;
  cbInnovationEntertainer.Checked:=Game.InnovaEntertainer;

  InnovaSampleRateComboBox.ItemIndex:=0;
  S:=Trim(ExtUpperCase(IntToStr(Game.InnovaRate)));
  For I:=0 to InnovaSampleRateComboBox.Items.Count-1 do If Trim(ExtUpperCase(InnovaSampleRateComboBox.Items[I]))=S then begin
    InnovaSampleRateComboBox.ItemIndex:=I; break;
  end;

  InnovaBaseComboBox.ItemIndex:=0;
  S:=Trim(ExtUpperCase(Game.InnovaBase));
  For I:=0 to InnovaBaseComboBox.Items.Count-1 do If Trim(ExtUpperCase(InnovaBaseComboBox.Items[I]))=S then begin
    InnovaBaseComboBox.ItemIndex:=I; break;
  end;

  InnovaQualityComboBox.ItemIndex:=0;
  S:=Trim(ExtUpperCase(IntToStr(Game.InnovaQuality)));
  For I:=0 to InnovaQualityComboBox.Items.Count-1 do If Trim(ExtUpperCase(InnovaQualityComboBox.Items[I]))=S then begin
    InnovaQualityComboBox.ItemIndex:=I; break;
  end;  
end;

procedure TModernProfileEditorInnovaFrame.GetGame(const Game: TGame);
Var I : Integer;
begin
  Game.Innova:=EnableInnovaCheckBox.Checked;
  Game.InnovaEntertainer:=cbInnovationEntertainer.Checked;
  If TryStrToInt(InnovaSampleRateComboBox.Items[InnovaSampleRateComboBox.ItemIndex],I) then Game.InnovaRate:=I;
  Game.InnovaBase:=InnovaBaseComboBox.Items[InnovaBaseComboBox.ItemIndex];
  If TryStrToInt(InnovaQualityComboBox.Items[InnovaQualityComboBox.ItemIndex],I) then Game.InnovaQuality:=I;
end;

end.
