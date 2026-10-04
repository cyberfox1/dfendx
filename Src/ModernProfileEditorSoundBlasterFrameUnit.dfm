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
    Width = 53
    Height = 15
    Caption = 'TypeLabel'
  end
  object AddressLabel: TLabel
    Left = 24
    Top = 80
    Width = 70
    Height = 15
    Caption = 'AddressLabel'
  end
  object InterruptLabel: TLabel
    Left = 120
    Top = 80
    Width = 74
    Height = 15
    Caption = 'InterruptLabel'
  end
  object DMALabel: TLabel
    Left = 24
    Top = 136
    Width = 55
    Height = 15
    Caption = 'DMALabel'
  end
  object HDMALabel: TLabel
    Left = 120
    Top = 136
    Width = 64
    Height = 15
    Caption = 'HDMALabel'
  end
  object OplModeLabel: TLabel
    Left = 24
    Top = 192
    Width = 78
    Height = 15
    Caption = 'OplModeLabel'
  end
  object OplSampleRateLabel: TLabel
    Left = 216
    Top = 192
    Width = 109
    Height = 15
    Caption = 'OplSampleRateLabel'
  end
  object OplEmuLabel: TLabel
    Left = 120
    Top = 192
    Width = 71
    Height = 15
    Caption = 'OplEmuLabel'
  end
  object FilterLabel: TLabel
    Left = 24
    Top = 376
    Width = 54
    Height = 15
    Caption = 'FilterLabel'
  end
  object WarmupLabel: TLabel
    Left = 24
    Top = 464
    Width = 74
    Height = 15
    Caption = 'WarmupLabel'
  end
  object TypeComboBox: TComboBox
    Left = 24
    Top = 43
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object AddressComboBox: TComboBox
    Left = 24
    Top = 99
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object InterruptComboBox: TComboBox
    Left = 120
    Top = 99
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object DMAComboBox: TComboBox
    Left = 24
    Top = 155
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object HDMAComboBox: TComboBox
    Left = 120
    Top = 155
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 4
  end
  object OplModeComboBox: TComboBox
    Left = 24
    Top = 211
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 5
  end
  object OplSampleRateComboBox: TComboBox
    Left = 216
    Top = 211
    Width = 81
    Height = 23
    Style = csDropDownList
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
  object FilterComboBox: TComboBox
    Left = 24
    Top = 395
    Width = 81
    Height = 23
    Style = csDropDownList
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
  object WarmupEdit: TSpinEdit
    Left = 24
    Top = 483
    Width = 81
    Height = 24
    MaxValue = 100
    MinValue = 0
    TabOrder = 13
    Value = 100
  end
  object OplEmuComboBox: TComboBox
    Left = 120
    Top = 211
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 6
  end
end
