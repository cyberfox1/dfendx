object ModernProfileEditorGUSFrame: TModernProfileEditorGUSFrame
  Left = 0
  Top = 0
  Width = 621
  Height = 489
  TabOrder = 0
  DesignSize = (
    621
    489)
  object AddressLabel: TLabel
    Left = 24
    Top = 64
    Width = 64
    Height = 13
    Caption = 'AddressLabel'
  end
  object SampleRateLabel: TLabel
    Left = 128
    Top = 64
    Width = 82
    Height = 13
    Caption = 'SampleRateLabel'
  end
  object Interrupt1Label: TLabel
    Left = 24
    Top = 120
    Width = 75
    Height = 13
    Caption = 'Interrupt1Label'
  end
  object DMA1Label: TLabel
    Left = 24
    Top = 176
    Width = 53
    Height = 13
    Caption = 'DMA1Label'
  end
  object ActivateGUSCheckBox: TCheckBox
    Left = 24
    Top = 24
    Width = 569
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'ActivateGUSCheckBox'
    TabOrder = 0
  end
  object AddressComboBox: TComboBox
    Left = 24
    Top = 83
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 1
  end
  object SampleRateComboBox: TComboBox
    Left = 128
    Top = 83
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 2
  end
  object Interrupt1ComboBox: TComboBox
    Left = 24
    Top = 139
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 3
  end
  object DMA1ComboBox: TComboBox
    Left = 24
    Top = 195
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 4
  end
  object PathEdit: TLabeledEdit
    Left = 24
    Top = 248
    Width = 577
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 40
    EditLabel.Height = 13
    EditLabel.Caption = 'PathEdit'
    TabOrder = 5
  end
  object FilterLabel: TLabel
    Left = 24
    Top = 288
    Width = 51
    Height = 13
    Caption = 'FilterLabel'
  end
  object TypeLabel: TLabel
    Left = 24
    Top = 344
    Width = 49
    Height = 13
    Caption = 'TypeLabel'
  end
  object MemSizeLabel: TLabel
    Left = 128
    Top = 344
    Width = 67
    Height = 13
    Caption = 'MemSizeLabel'
  end
  object MasterVolumeLabel: TLabel
    Left = 232
    Top = 344
    Width = 97
    Height = 13
    Caption = 'MasterVolumeLabel'
  end
  object FilterComboBox: TComboBox
    Left = 24
    Top = 307
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 6
  end
  object TypeComboBox: TComboBox
    Left = 24
    Top = 363
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 7
  end
  object MemSizeComboBox: TComboBox
    Left = 128
    Top = 363
    Width = 81
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 8
  end
  object MasterVolumeComboBox: TComboBox
    Left = 232
    Top = 363
    Width = 81
    Height = 21
    ItemHeight = 0
    TabOrder = 9
  end
end
