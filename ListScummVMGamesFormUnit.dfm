object ListScummVMGamesForm: TListScummVMGamesForm
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'ListScummVMGamesForm'
  ClientHeight = 510
  ClientWidth = 409
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object SearchEdit: TEdit
    Left = 0
    Top = 0
    Width = 409
    Height = 21
    Align = alTop
    TabOrder = 0
    OnChange = SearchEditChange
  end
  object ListBox: TListBox
    Left = 0
    Top = 21
    Width = 409
    Height = 455
    Align = alClient
    ItemHeight = 13
    TabOrder = 1
    OnDblClick = ListBoxDblClick
  end
  object Panel1: TPanel
    Left = 0
    Top = 451
    Width = 409
    Height = 34
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object CloseButton: TBitBtn
      Left = 4
      Top = 4
      Width = 97
      Height = 27
      TabOrder = 0
      Kind = bkClose
    end
    object OKButton: TBitBtn
      Left = 308
      Top = 4
      Width = 97
      Height = 27
      TabOrder = 1
      Kind = bkOK
      Visible = False
      OnClick = OKButtonClick
    end
  end
end
