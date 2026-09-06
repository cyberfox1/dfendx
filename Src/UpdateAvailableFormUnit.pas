unit UpdateAvailableFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TUpdateAvailableForm = class(TForm)
    NewerPrefixLabel: TLabel;
    NewerVersionLabel: TLabel;
    CurrentPrefixLabel: TLabel;
    CurrentVersionLabel: TLabel;
    ReleaseNotesLabel: TLabel;
    URLLabel: TLabel;
    OKButton: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure URLLabelClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

Procedure ShowUpdateAvailableDialog(const AOwner : TComponent; const RemoteVersion, LocalVersion, ReleaseURL : String);

implementation

uses ShellAPI, LanguageSetupUnit, VistaToolsUnit, CommonHelpers, CommonTools, IconLoaderUnit;

{$R *.dfm}

procedure TUpdateAvailableForm.FormCreate(Sender: TObject);
begin
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);

  Caption:=LanguageSetup.UpdateAvailableTitle;
  NewerPrefixLabel.Caption:=Format(LanguageSetup.UpdateAvailableNewerVersion,['']);
  CurrentPrefixLabel.Caption:=Format(LanguageSetup.UpdateAvailableCurrentVersion,['']);
  ReleaseNotesLabel.Caption:=LanguageSetup.UpdateAvailableReleaseNotes;
  OKButton.Caption:=LanguageSetup.OK;
  OKButton.Default:=True;
  OKButton.ModalResult:=mrOk;

  NewerVersionLabel.Font.Assign(Font);
  NewerVersionLabel.Font.Style:=[fsBold];
  CurrentVersionLabel.Font.Assign(Font);
  CurrentVersionLabel.Font.Style:=[fsBold];
  with URLLabel.Font do begin Color:=clBlue; Style:=[fsUnderline]; end;
  URLLabel.Cursor:=crHandPoint;

  UserIconLoader.DialogImage(DI_OK,OKButton);
end;

procedure TUpdateAvailableForm.URLLabelClick(Sender: TObject);
begin
  ShellExecute(Handle,'open',PChar(URLLabel.Caption),nil,nil,SW_SHOW);
end;

Procedure ShowUpdateAvailableDialog(const AOwner : TComponent; const RemoteVersion, LocalVersion, ReleaseURL : String);
Var Form : TUpdateAvailableForm;
begin
  Form:=TUpdateAvailableForm.Create(AOwner);
  try
    Form.NewerVersionLabel.Caption:=RemoteVersion;
    Form.NewerVersionLabel.Left:=Form.NewerPrefixLabel.Left+Form.NewerPrefixLabel.Width;
    Form.CurrentVersionLabel.Caption:=LocalVersion;
    Form.CurrentVersionLabel.Left:=Form.CurrentPrefixLabel.Left+Form.CurrentPrefixLabel.Width;
    Form.URLLabel.Caption:=ReleaseURL;
    Form.PopupMode:=pmAuto;
    If AOwner is TCustomForm then Form.PopupParent:=TCustomForm(AOwner);
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.
