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
    Width = 70
    Height = 15
    Caption = 'AddressLabel'
  end
  object SampleRateLabel: TLabel
    Left = 128
    Top = 64
    Width = 90
    Height = 15
    Caption = 'SampleRateLabel'
  end
  object Interrupt1Label: TLabel
    Left = 24
    Top = 120
    Width = 80
    Height = 15
    Caption = 'Interrupt1Label'
  end
  object DMA1Label: TLabel
    Left = 24
    Top = 176
    Width = 61
    Height = 15
    Caption = 'DMA1Label'
  end
  object FilterLabel: TLabel
    Left = 24
    Top = 288
    Width = 54
    Height = 15
    Caption = 'FilterLabel'
  end
  object TypeLabel: TLabel
    Left = 24
    Top = 344
    Width = 53
    Height = 15
    Caption = 'TypeLabel'
  end
  object MemSizeLabel: TLabel
    Left = 160
    Top = 344
    Width = 76
    Height = 15
    Caption = 'MemSizeLabel'
  end
  object MasterVolumeLabel: TLabel
    Left = 296
    Top = 344
    Width = 104
    Height = 15
    Caption = 'MasterVolumeLabel'
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
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object SampleRateComboBox: TComboBox
    Left = 128
    Top = 83
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object Interrupt1ComboBox: TComboBox
    Left = 24
    Top = 139
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object DMA1ComboBox: TComboBox
    Left = 24
    Top = 195
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 4
  end
  object PathEdit: TLabeledEdit
    Left = 24
    Top = 248
    Width = 577
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 44
    EditLabel.Height = 15
    EditLabel.Caption = 'PathEdit'
    TabOrder = 5
    Text = ''
  end
  object FilterComboBox: TComboBox
    Left = 24
    Top = 307
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 6
  end
  object TypeComboBox: TComboBox
    Left = 24
    Top = 363
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 7
  end
  object MemSizeComboBox: TComboBox
    Left = 160
    Top = 363
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 8
  end
  object MasterVolumeComboBox: TComboBox
    Left = 296
    Top = 363
    Width = 81
    Height = 23
    TabOrder = 9
  end
end
