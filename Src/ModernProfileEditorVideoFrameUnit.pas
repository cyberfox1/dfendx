unit ModernProfileEditorVideoFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, GameDBUnit, ModernProfileEditorFormUnit, PrgConsts;

type
  TModernProfileEditorVideoFrame = class(TFrame, IModernProfileEditorFrame)
    ReelMagicGroupBox: TGroupBox;
    ReelMagicModeLabel: TLabel;
    ReelMagicKeyLabel: TLabel;
    ReelMagicFCodeLabel: TLabel;
    ReelMagicModeComboBox: TComboBox;
    ReelMagicKeyComboBox: TComboBox;
    ReelMagicFCodeComboBox: TComboBox;
  private
    FTempGame: TGame;
    FReelMagicConfOpt, FReelMagicKeyConfOpt, FReelMagicFCodeConfOpt: String;
    FLoadedReelMagic, FLoadedReelMagicKey, FLoadedReelMagicFCode: String;
    function GetSelectedDosBoxKind: TDOSBoxKind;
    procedure ApplyVisibility(Sender: TObject);
    procedure ShowFrame(Sender: TObject);
    procedure Invalidate(Sender: TObject);
  public
    Constructor Create(AOwner: TComponent); override;
    Procedure InitGUI(var InitData: TModernProfileEditorInitData);
    Procedure SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
    Procedure GetGame(const Game: TGame);
  end;

implementation

uses VistaToolsUnit, LanguageSetupUnit, CommonHelpers, HelpConsts;

{$R *.dfm}

constructor TModernProfileEditorVideoFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
end;

function TModernProfileEditorVideoFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  Result:=FTempGame.DosBoxKind;
end;

procedure TModernProfileEditorVideoFrame.ApplyVisibility(Sender: TObject);
Var Staging, OnRM: Boolean;
begin
  Staging:=GetSelectedDosBoxKind=dbkStaging;
  OnRM:=Staging and (ReelMagicModeComboBox.ItemIndex>=0) and (not SameText(Trim(ReelMagicModeComboBox.Text),'off'));
  ReelMagicGroupBox.Enabled:=Staging;
  ReelMagicModeLabel.Enabled:=Staging;
  ReelMagicModeComboBox.Enabled:=Staging;
  ReelMagicKeyLabel.Enabled:=OnRM;
  ReelMagicFCodeLabel.Enabled:=OnRM;
  ReelMagicKeyComboBox.Enabled:=OnRM;
  ReelMagicFCodeComboBox.Enabled:=OnRM;
  If not Staging then
    SetComboNoSelect(ReelMagicModeComboBox);
  If not OnRM then begin
    SetComboNoSelect(ReelMagicKeyComboBox);
    SetComboNoSelect(ReelMagicFCodeComboBox);
  end;
end;

procedure TModernProfileEditorVideoFrame.ShowFrame(Sender: TObject);
begin
  ReloadComboFromConfOpt(ReelMagicModeComboBox,FReelMagicConfOpt,True,FLoadedReelMagic);
  ReloadComboFromConfOpt(ReelMagicKeyComboBox,FReelMagicKeyConfOpt,True,FLoadedReelMagicKey);
  ReloadComboFromConfOpt(ReelMagicFCodeComboBox,FReelMagicFCodeConfOpt,True,FLoadedReelMagicFCode);
  ApplyVisibility(Sender);
end;

procedure TModernProfileEditorVideoFrame.Invalidate(Sender: TObject);
begin
  ReelMagicModeComboBox.ItemIndex:=-1;
  ReelMagicKeyComboBox.ItemIndex:=-1;
  ReelMagicFCodeComboBox.ItemIndex:=-1;
end;

procedure TModernProfileEditorVideoFrame.InitGUI(var InitData: TModernProfileEditorInitData);
begin
  NoFlicker(ReelMagicGroupBox);
  NoFlicker(ReelMagicModeComboBox);
  NoFlicker(ReelMagicKeyComboBox);
  NoFlicker(ReelMagicFCodeComboBox);

  FReelMagicConfOpt:=InitData.GameDB.ConfOpt.ReelMagic;
  FReelMagicKeyConfOpt:=InitData.GameDB.ConfOpt.ReelMagicKey;
  FReelMagicFCodeConfOpt:=InitData.GameDB.ConfOpt.ReelMagicFCode;
  InitData.OnShowFrame:=ShowFrame;
  InitData.OnInvalidate:=Invalidate;
  ReelMagicModeComboBox.OnChange:=ApplyVisibility;

  ReelMagicGroupBox.Caption:=LanguageSetup.ProfileEditorVideoReelMagic;
  ReelMagicModeLabel.Caption:=LanguageSetup.ProfileEditorVideoReelMagicMode;
  ReelMagicKeyLabel.Caption:=LanguageSetup.ProfileEditorVideoReelMagicKey;
  ReelMagicFCodeLabel.Caption:=LanguageSetup.ProfileEditorVideoReelMagicFCode;
  AddDefaultValueHint(ReelMagicModeComboBox);
  AddDefaultValueHint(ReelMagicKeyComboBox);
  AddDefaultValueHint(ReelMagicFCodeComboBox);

  HelpContext:=ID_ProfileEditVideo;
end;

procedure TModernProfileEditorVideoFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
begin
  FLoadedReelMagic:=Trim(Game.ReelMagic);
  FLoadedReelMagicKey:=Trim(Game.ReelMagicKey);
  FLoadedReelMagicFCode:=Trim(Game.ReelMagicFCode);
  ShowFrame(nil);
end;

procedure TModernProfileEditorVideoFrame.GetGame(const Game: TGame);
begin
  If GetSelectedDosBoxKind=dbkStaging then begin
    If ReelMagicModeComboBox.ItemIndex>=0 then
      Game.ReelMagic:=ReelMagicModeComboBox.Text;
    If ReelMagicKeyComboBox.ItemIndex>=0 then
      Game.ReelMagicKey:=ReelMagicKeyComboBox.Text;
    If ReelMagicFCodeComboBox.ItemIndex>=0 then
      Game.ReelMagicFCode:=ReelMagicFCodeComboBox.Text;
  end;
end;

end.
