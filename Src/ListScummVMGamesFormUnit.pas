unit ListScummVMGamesFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TListScummVMGamesForm = class(TForm)
    SearchEdit: TEdit;
    ListBox: TListBox;
    Panel1: TPanel;
    CloseButton: TBitBtn;
    OKButton: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure SearchEditChange(Sender: TObject);
    procedure ListBoxDblClick(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
  private
    FAllLines: TStringList;
    procedure ApplyFilter;
  public
    ExternalLines: TStringList;
    Selectable: Boolean;
    SelectedGame: String;
    constructor Create(AOwner: TComponent; AExternalLines: TStringList = nil); reintroduce; overload;
    destructor Destroy; override;
  end;

var
  ListScummVMGamesForm: TListScummVMGamesForm;

Procedure ShowListScummVMGamesDialog(const AOwner : TComponent);

implementation

uses VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools, ScummVMToolsUnit,
     IconLoaderUnit;

{$R *.dfm}

constructor TListScummVMGamesForm.Create(AOwner: TComponent; AExternalLines: TStringList);
begin
  ExternalLines := AExternalLines;
  Selectable := False;
  SelectedGame := '';
  FAllLines := TStringList.Create;
  inherited Create(AOwner);
end;

destructor TListScummVMGamesForm.Destroy;
begin
  FAllLines.Free;
  inherited Destroy;
end;

procedure TListScummVMGamesForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);
  NoFlicker(ListBox);

  Caption:=LanguageSetup.MenuHelpScummVMCompatibilityListCaption;
  CloseButton.Caption:=LanguageSetup.Close;

  UserIconLoader.DialogImage(DI_Close,CloseButton);

  If Assigned(ExternalLines) then begin
    FAllLines.AddStrings(ExternalLines);
  end else begin
    If ScummVMGamesList.Count=0 then ScummVMGamesList.LoadListFromScummVM(True);
    FAllLines.AddStrings(ScummVMGamesList.DescriptionList);
  end;
  FAllLines.Sorted:=True;

  ListBox.Items.BeginUpdate;
  try
    ListBox.Items.AddStrings(FAllLines);
  finally
    ListBox.Items.EndUpdate;
  end;
  ListBox.Sorted:=True;
end;

procedure TListScummVMGamesForm.ApplyFilter;
var
  Filter: String;
  I: Integer;
begin
  Filter := LowerCase(Trim(SearchEdit.Text));
  ListBox.Items.BeginUpdate;
  try
    ListBox.Items.Clear;
    if Filter = '' then begin
      ListBox.Items.AddStrings(FAllLines);
    end else begin
      for I := 0 to FAllLines.Count - 1 do
        if Pos(Filter, LowerCase(FAllLines[I])) > 0 then
          ListBox.Items.Add(FAllLines[I]);
    end;
  finally
    ListBox.Items.EndUpdate;
  end;
end;

procedure TListScummVMGamesForm.SearchEditChange(Sender: TObject);
begin
  ApplyFilter;
end;

procedure TListScummVMGamesForm.ListBoxDblClick(Sender: TObject);
begin
  if Selectable and (ListBox.ItemIndex >= 0) then begin
    SelectedGame := ListBox.Items[ListBox.ItemIndex];
    ModalResult := mrOK;
  end;
end;

procedure TListScummVMGamesForm.OKButtonClick(Sender: TObject);
begin
  if Selectable and (ListBox.ItemIndex >= 0) then
    SelectedGame := ListBox.Items[ListBox.ItemIndex];
end;

{ global }

Procedure ShowListScummVMGamesDialog(const AOwner : TComponent);
begin
  ListScummVMGamesForm:=TListScummVMGamesForm.Create(AOwner);
  try
    ListScummVMGamesForm.ShowModal;
  finally
    ListScummVMGamesForm.Free;
  end;
end;

end.
