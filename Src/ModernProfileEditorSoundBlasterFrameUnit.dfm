object ModernProfileEditorSoundBlasterFrame: TModernProfileEditorSoundBlasterFrame
  Left = 0
  Top = 0
  Width = 599
  Height = 522
  TabOrder = 0
  DesignSize = (
    599
    522)
  object TypeLabel: TLabel
    Left = 24
    Top = 24
    Width = 49
    Height = 13
    Caption = 'TypeLabel'
  end
  object AddressLabel: TLabel
    Left = 24
    Top = 80
    Width = 64
    Height = 13
    Caption = 'AddressLabel'
  end
  object InterruptLabel: TLabel
    Left = 120
    Top = 80
    Width = 69
    Height = 13
    Caption = 'InterruptLabel'
  end
  object DMALabel: TLabel
    Left = 24
    Top = 136
    Width = 47
    Height = 13
    Caption = 'DMALabel'
  end
  object HDMALabel: TLabel
    Left = 120
    Top = 136
    Width = 54
    Height = 13
    Caption = 'HDMALabel'
  end
  object OplModeLabel: TLabel
    Left = 24
    Top = 192
    Width = 67
    Height = 13
    Caption = 'OplModeLabel'
  end
  object OplSampleRateLabel: TLabel
    Left = 216
    Top = 192
    Width = 98
    Height = 13
    Caption = 'OplSampleRateLabel'
  end
  object OplEmuLabel: TLabel
    Left = 120
    Top = 192
    Width = 61
    Height = 13
    Caption = 'OplEmuLabel'
  end
  object TypeComboBox: TComboBox
    Left = 24
    Top = 43
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 0
  end
  object AddressComboBox: TComboBox
    Left = 24
    Top = 99
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 1
  end
  object InterruptComboBox: TComboBox
    Left = 120
    Top = 99
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 2
  end
  object DMAComboBox: TComboBox
    Left = 24
    Top = 155
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 3
  end
  object HDMAComboBox: TComboBox
    Left = 120
    Top = 155
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 4
  end
  object OplModeComboBox: TComboBox
    Left = 24
    Top = 211
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 5
  end
  object OplSampleRateComboBox: TComboBox
    Left = 216
    Top = 211
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 7
  end
  object UseMixerCheckBox: TCheckBox
    Left = 24
    Top = 256
    Width = 553
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'UseMixerCheckBox'
    TabOrder = 8
  end
  object ActivateCMSCheckBox: TCheckBox
    Left = 24
    Top = 288
    Width = 553
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Activate CMS'
    TabOrder = 9
  end
  object GoldplayCheckBox: TCheckBox
    Left = 24
    Top = 344
    Width = 553
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Activate Goldplay'
    TabOrder = 10
  end
  object FilterLabel: TLabel
    Left = 24
    Top = 376
    Width = 51
    Height = 13
    Caption = 'FilterLabel'
  end
  object FilterComboBox: TComboBox
    Left = 24
    Top = 395
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 11
  end
  object FilterAlwaysOnCheckBox: TCheckBox
    Left = 24
    Top = 432
    Width = 553
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'FilterAlwaysOnCheckBox'
    TabOrder = 12
  end
  object WarmupLabel: TLabel
    Left = 24
    Top = 464
    Width = 64
    Height = 13
    Caption = 'WarmupLabel'
  end
  object WarmupEdit: TSpinEdit
    Left = 24
    Top = 483
    Width = 81
    Height = 22
    MaxValue = 100
    MinValue = 0
    TabOrder = 13
    Value = 100
  end
  object OplEmuComboBox: TComboBox
    Left = 120
    Top = 211
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 6
  end
end
