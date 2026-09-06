object ModernProfileEditorImageQualityFrame: TModernProfileEditorImageQualityFrame
  Left = 0
  Top = 0
  Width = 621
  Height = 520
  TabOrder = 0
  DesignSize = (
    621
    520)
  object DeinterlacingLabel: TLabel
    Left = 24
    Top = 16
    Width = 90
    Height = 15
    Caption = 'DeinterlacingLabel'
  end
  object DeditheringLabel: TLabel
    Left = 200
    Top = 16
    Width = 90
    Height = 15
    Caption = 'DeditheringLabel'
  end
  object CrtColorProfileLabel: TLabel
    Left = 24
    Top = 80
    Width = 107
    Height = 15
    Caption = 'CrtColorProfileLabel'
  end
  object ColorSpaceLabel: TLabel
    Left = 200
    Top = 80
    Width = 84
    Height = 15
    Caption = 'ColorSpaceLabel'
  end
  object IntegerScalingLabel: TLabel
    Left = 376
    Top = 80
    Width = 102
    Height = 15
    Caption = 'IntegerScalingLabel'
  end
  object DeinterlacingComboBox: TComboBox
    Left = 24
    Top = 35
    Width = 160
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object DeditheringComboBox: TComboBox
    Left = 200
    Top = 35
    Width = 160
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object CrtColorProfileComboBox: TComboBox
    Left = 24
    Top = 99
    Width = 160
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object ColorSpaceComboBox: TComboBox
    Left = 200
    Top = 99
    Width = 160
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object IntegerScalingComboBox: TComboBox
    Left = 376
    Top = 99
    Width = 160
    Height = 23
    Style = csDropDownList
    TabOrder = 4
  end
  object ImageAdjustmentsCheckBox: TCheckBox
    Left = 24
    Top = 144
    Width = 512
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'ImageAdjustmentsCheckBox'
    TabOrder = 5
    OnClick = ImageAdjustmentsCheckBoxClick
  end
  object ImageAdjustmentsGroupBox: TGroupBox
    Left = 24
    Top = 176
    Width = 512
    Height = 185
    Anchors = [akLeft, akTop, akRight]
    Caption = ''
    TabOrder = 6
    object BrightnessLabel: TLabel
      Left = 16
      Top = 24
      Width = 84
      Height = 15
      Caption = 'BrightnessLabel'
    end
    object ContrastLabel: TLabel
      Left = 176
      Top = 24
      Width = 74
      Height = 15
      Caption = 'ContrastLabel'
    end
    object SaturationLabel: TLabel
      Left = 336
      Top = 24
      Width = 84
      Height = 15
      Caption = 'SaturationLabel'
    end
    object ColorTemperatureLabel: TLabel
      Left = 16
      Top = 96
      Width = 122
      Height = 15
      Caption = 'ColorTemperatureLabel'
    end
    object BrightnessEdit: TSpinEdit
      Left = 16
      Top = 43
      Width = 80
      Height = 24
      MaxValue = 100
      MinValue = 0
      TabOrder = 0
      Value = 45
    end
    object ContrastEdit: TSpinEdit
      Left = 176
      Top = 43
      Width = 80
      Height = 24
      MaxValue = 100
      MinValue = 0
      TabOrder = 1
      Value = 65
    end
    object SaturationEdit: TSpinEdit
      Left = 336
      Top = 43
      Width = 80
      Height = 24
      MaxValue = 50
      MinValue = -50
      TabOrder = 2
      Value = 0
    end
    object ColorTemperatureComboBox: TComboBox
      Left = 16
      Top = 115
      Width = 160
      Height = 23
      Style = csDropDownList
      TabOrder = 3
    end
  end
end
