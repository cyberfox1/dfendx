object DownloadWaitForm: TDownloadWaitForm
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Downloading'
  ClientHeight = 37
  ClientWidth = 458
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  GlassFrame.Enabled = True
  GlassFrame.SheetOfGlass = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 13
  object ProgressBar: TProgressBar
    Left = 8
    Top = 8
    Width = 353
    Height = 17
    TabOrder = 0
  end
  object AbortButton: TButton
    Left = 375
    Top = 4
    Width = 75
    Height = 25
    Caption = 'Abort'
    TabOrder = 1
    OnClick = AbortButtonClick
  end
end
