unit DOSBoxFailedFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, GameDBUnit;

type
  TDOSBoxFailedForm = class(TForm)
    OKButton: TBitBtn;
    InfoLabel: TLabel;
    DoNotShowAgainCheckBox: TCheckBox;
    ProfileGroupBox: TGroupBox;
    CloseDOSBoxCheckBox: TCheckBox;
    ShowConsoleCheckBox: TCheckBox;
    RenderLabel: TLabel;
    RenderComboBox: TComboBox;
    GlobalGroupBox: TGroupBox;
    SDLLabel: TLabel;
    SDLComboBox: TComboBox;
    RemoteLabel: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private-Deklarationen }
    DOSBoxNr : Integer;
    Procedure LoadSettings;
  public
    { Public-Deklarationen }
    GameDB : TGameDB;
    Game : TGame;
  end;

var
  DOSBoxFailedForm: TDOSBoxFailedForm;

Procedure ShowDOSBoxFailedDialog(const AOwner : TComponent; const AGameDB : TGameDB; const AGame : TGame);

implementation

uses LanguageSetupUnit, VistaToolsUnit, CommonHelpers, CommonTools, IconLoaderUnit, PrgSetupUnit,
     GameDBToolsHelpers, GameDBHelpers, PrgConsts;

{$R *.dfm}

procedure TDOSBoxFailedForm.FormShow(Sender: TObject);
Var St : TStringList;
    ListSrc : String;
begin
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);

  Caption:=LanguageSetup.DOSBoxStartFailed;
  InfoLabel.Caption:=LanguageSetup.DOSBoxStartFailedInfo;

  ProfileGroupBox.Caption:=LanguageSetup.DOSBoxStartFailedProfileSettings;
  GlobalGroupBox.Caption:=LanguageSetup.DOSBoxStartFailedGlobalSettings;
  CloseDOSBoxCheckBox.Caption:=LanguageSetup.GameCloseDOSBoxAfterGameExit;
  ShowConsoleCheckBox.Caption:=LanguageSetup.DOSBoxStartFailedShowConsole;
  RenderLabel.Caption:=LanguageSetup.GameRender;
  Case Game.DosBoxKind of
    dbkStaging: ListSrc:=GameDB.ConfOpt.RenderStaging;
    dbkX:       ListSrc:=GameDB.ConfOpt.RenderX;
    else        ListSrc:=GameDB.ConfOpt.Render;
  end;
  St:=ValueToList(ListSrc,';,');
  try
    RenderComboBox.Items.Clear;
    RenderComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;
  SDLLabel.Caption:=LanguageSetup.SetupFormDOSBoxSDLVideodriver;
  SDLComboBox.Items[0]:=SDLComboBox.Items[0]+' ('+LanguageSetup.Default+')';
  RemoteLabel.Caption:=LanguageSetup.DOSBoxStartFailedRemoteInfo;
  DoNotShowAgainCheckBox.Caption:=LanguageSetup.DOSBoxStartFailedTurnOff;

  OKButton.Caption:=LanguageSetup.OK;
  UserIconLoader.DialogImage(DI_OK,OKButton);

  LoadSettings;
  DoNotShowAgainCheckBox.Checked:=False;
end;

procedure TDOSBoxFailedForm.LoadSettings;
Var S : String;
    I : Integer;
begin
  CloseDOSBoxCheckBox.Checked:=Game.CloseDosBoxAfterGameExit;

  DOSBoxNr:=ResolveDOSBoxInstallIndex(Game.CustomDOSBoxDir);
  If DOSBoxNr<0 then DOSBoxNr:=0; { custom path: use default install settings for this dialog }

  Case Game.ShowConsoleWindow of
    0 : ShowConsoleCheckBox.Checked:=False;
    2 : ShowConsoleCheckBox.Checked:=True;
    else {1 :} ShowConsoleCheckBox.Checked:=not PrgSetup.DOSBoxSettings[DOSBoxNr].HideDosBoxConsole;
  End;

  S:=Trim(ExtUpperCase(Game.Render));
  RenderComboBox.ItemIndex:=-1;
  For I:=0 to RenderComboBox.Items.Count-1 do If Trim(ExtUpperCase(RenderComboBox.Items[I]))=S then begin
    RenderComboBox.ItemIndex:=I; break;
  end;
  If (RenderComboBox.ItemIndex<0) and (RenderComboBox.Items.Count>0) then
    RenderComboBox.ItemIndex:=0;

  If Trim(ExtUpperCase(PrgSetup.DOSBoxSettings[0].SDLVideodriver))='WINDIB' then SDLComboBox.ItemIndex:=1 else SDLComboBox.ItemIndex:=0;
  RemoteLabel.Visible:=IsRemoteSession and (SDLComboBox.ItemIndex=0);
end;

procedure TDOSBoxFailedForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Game.CloseDosBoxAfterGameExit:=CloseDOSBoxCheckBox.Checked;
  If PrgSetup.DOSBoxSettings[DOSBoxNr].HideDosBoxConsole then begin
    If ShowConsoleCheckBox.Checked then Game.ShowConsoleWindow:=2 else Game.ShowConsoleWindow:=1;
  end else begin
    If ShowConsoleCheckBox.Checked then Game.ShowConsoleWindow:=1 else Game.ShowConsoleWindow:=0;
  end;
  If RenderComboBox.ItemIndex>=0 then
    Game.Render:=RenderComboBox.Text;
  Game.NoDOSBoxFailedDialog:=DoNotShowAgainCheckBox.Checked;
  Game.StoreAllValues;

  If SDLComboBox.ItemIndex=1 then PrgSetup.DOSBoxSettings[0].SDLVideodriver:='WinDIB' else PrgSetup.DOSBoxSettings[0].SDLVideodriver:='DirectX';
end;

{ global }

Procedure ShowDOSBoxFailedDialog(const AOwner : TComponent; const AGameDB : TGameDB; const AGame : TGame);
begin
  If AGame.NoDOSBoxFailedDialog then exit;
  DOSBoxFailedForm:=TDOSBoxFailedForm.Create(AOwner);
  try
    DOSBoxFailedForm.GameDB:=AGameDB;
    DOSBoxFailedForm.Game:=AGame;
    DOSBoxFailedForm.ShowModal;
  finally
    DOSBoxFailedForm.Free;
  end;
end;


end.
