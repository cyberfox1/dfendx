object ModernProfileEditorInnovaFrame: TModernProfileEditorInnovaFrame
  Left = 0
  Top = 0
  Width = 701
  Height = 417
  TabOrder = 0
  DesignSize = (
    701
    417)
  object InnovaSampleRateLabel: TLabel
    Left = 24
    Top = 88
    Width = 168
    Height = 15
    Caption = 'Innovation SSI-2001 sample rate'
  end
  object InnovaBaseLabel: TLabel
    Left = 24
    Top = 152
    Width = 174
    Height = 15
    Caption = 'Innovation SSI-2001 base address'
  end
  object InnovaQualityLabel: TLabel
    Left = 24
    Top = 216
    Width = 200
    Height = 15
    Caption = 'Innovation SSI-2001 emulation quality'
  end
  object EnableInnovaCheckBox: TCheckBox
    Left = 24
    Top = 24
    Width = 665
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Enable Innovation SSI-2001 emulation'
    TabOrder = 0
  end
  object InnovaSampleRateComboBox: TComboBox
    Left = 24
    Top = 107
    Width = 113
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object InnovaBaseComboBox: TComboBox
    Left = 24
    Top = 171
    Width = 113
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object InnovaQualityComboBox: TComboBox
    Left = 24
    Top = 235
    Width = 113
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object cbInnovationEntertainer: TCheckBox
    Left = 24
    Top = 56
    Width = 665
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Enable Entertainer'
    TabOrder = 4
  end
end
