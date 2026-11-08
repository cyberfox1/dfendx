object ModernProfileEditorKeyboardFrame: TModernProfileEditorKeyboardFrame
  Left = 0
  Top = 0
  Width = 641
  Height = 639
  TabOrder = 0
  DesignSize = (
    641
    639)
  object KeyboardLayoutLabel: TLabel
    Left = 24
    Top = 56
    Width = 114
    Height = 15
    Caption = 'KeyboardLayoutLabel'
  end
  object KeyboardLayoutInfoLabel: TLabel
    Left = 24
    Top = 102
    Width = 250
    Height = 123
    AutoSize = False
    Caption = 'KeyboardLayoutInfoLabel'
    WordWrap = True
  end
  object KeyLockInfoLabel: TLabel
    Left = 24
    Top = 343
    Width = 489
    Height = 42
    AutoSize = False
    Caption = 'KeyLockInfoLabel'
    WordWrap = True
  end
  object CodepageLabel: TLabel
    Left = 288
    Top = 56
    Width = 82
    Height = 15
    Caption = 'CodepageLabel'
  end
  object CustomKeyMapperButton: TSpeedButton
    Left = 608
    Top = 470
    Width = 23
    Height = 22
    Anchors = [akTop, akRight]
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000120B0000120B00001000000000000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
      5555555555555555555555555555555555555555555555555555555555555555
      555555555555555555555555555555555555555FFFFFFFFFF555550000000000
      55555577777777775F55500B8B8B8B8B05555775F555555575F550F0B8B8B8B8
      B05557F75F555555575F50BF0B8B8B8B8B0557F575FFFFFFFF7F50FBF0000000
      000557F557777777777550BFBFBFBFB0555557F555555557F55550FBFBFBFBF0
      555557F555555FF7555550BFBFBF00055555575F555577755555550BFBF05555
      55555575FFF75555555555700007555555555557777555555555555555555555
      5555555555555555555555555555555555555555555555555555}
    NumGlyphs = 2
    ParentShowHint = False
    ShowHint = True
    OnClick = CustomKeyMapperButtonClick
  end
  object KeyboardLayoutComboBox: TComboBox
    Left = 24
    Top = 75
    Width = 233
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object UseScancodesCheckBox: TCheckBox
    Left = 24
    Top = 25
    Width = 601
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'UseScancodesCheckBox'
    TabOrder = 0
  end
  object NumLockRadioGroup: TRadioGroup
    Left = 24
    Top = 240
    Width = 153
    Height = 89
    Caption = 'NumLockRadioGroup'
    ItemIndex = 0
    Items.Strings = (
      'Do not change'
      'off'
      'on')
    TabOrder = 4
  end
  object CapsLockRadioGroup: TRadioGroup
    Left = 193
    Top = 240
    Width = 153
    Height = 89
    Caption = 'CapsLockRadioGroup'
    ItemIndex = 0
    Items.Strings = (
      'Do not change'
      'off'
      'on')
    TabOrder = 5
  end
  object ScrollLockRadioGroup: TRadioGroup
    Left = 360
    Top = 240
    Width = 153
    Height = 89
    Caption = 'ScrollLockRadioGroup'
    ItemIndex = 0
    Items.Strings = (
      'Do not change'
      'off'
      'on')
    TabOrder = 6
  end
  object CodepageComboBox: TComboBox
    Left = 288
    Top = 75
    Width = 233
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object LocalePeriodGroupBox: TGroupBox
    Left = 288
    Top = 104
    Width = 233
    Height = 105
    Caption = 'LocalePeriodGroupBox'
    TabOrder = 3
    object LocalePeriodHistoricRadioButton: TRadioButton
      Left = 13
      Top = 49
      Width = 204
      Height = 17
      Caption = 'Historic'
      TabOrder = 0
    end
    object LocalePeriodModernRadioButton: TRadioButton
      Left = 13
      Top = 72
      Width = 204
      Height = 17
      Caption = 'Modern'
      TabOrder = 1
    end
    object LocalePeriodNoneRadioButton: TRadioButton
      Left = 13
      Top = 26
      Width = 204
      Height = 17
      Caption = 'None'
      TabOrder = 2
    end
  end
  object DefaultKeyMapperFileRadioButton: TRadioButton
    Left = 24
    Top = 424
    Width = 578
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'DefaultKeyMapperFileRadioButton'
    TabOrder = 7
  end
  object CustomKeyMapperFileRadioButton: TRadioButton
    Left = 24
    Top = 447
    Width = 578
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'CustomKeyMapperFileRadioButton'
    TabOrder = 8
  end
  object CustomKeyMapperEdit: TEdit
    Left = 40
    Top = 470
    Width = 562
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 9
    OnChange = CustomKeyMapperEditChange
  end
  object DosBoxTxtOpenDialog: TOpenDialog
    DefaultExt = 'txt'
    Left = 24
    Top = 505
  end
end
