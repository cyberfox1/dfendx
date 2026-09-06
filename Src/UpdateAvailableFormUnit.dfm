object UpdateAvailableForm: TUpdateAvailableForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'DFendX Update Found'
  ClientHeight = 176
  ClientWidth = 419
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 13
  object NewerPrefixLabel: TLabel
    Left = 16
    Top = 16
    Width = 193
    Height = 13
    Caption = 'A newer version of DFendX is available: '
  end
  object NewerVersionLabel: TLabel
    Left = 236
    Top = 16
    Width = 26
    Height = 13
    Caption = '0.0.0'
  end
  object CurrentPrefixLabel: TLabel
    Left = 16
    Top = 37
    Width = 167
    Height = 13
    Caption = 'You are currently running version: '
  end
  object CurrentVersionLabel: TLabel
    Left = 194
    Top = 37
    Width = 26
    Height = 13
    Caption = '0.0.0'
  end
  object ReleaseNotesLabel: TLabel
    Left = 16
    Top = 58
    Width = 385
    Height = 37
    AutoSize = False
    Caption = 
      'You can view the release notes and download the new version here' +
      ':'
    WordWrap = True
  end
  object URLLabel: TLabel
    Left = 16
    Top = 101
    Width = 385
    Height = 26
    Cursor = crHandPoint
    AutoSize = False
    Caption = 'URLLabel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentFont = False
    WordWrap = True
    OnClick = URLLabelClick
  end
  object OKButton: TBitBtn
    Left = 333
    Top = 133
    Width = 75
    Height = 25
    Kind = bkOK
    NumGlyphs = 2
    TabOrder = 0
  end
end
