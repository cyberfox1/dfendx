object ModernProfileEditorCPUFrame: TModernProfileEditorCPUFrame
  Left = 0
  Top = 0
  Width = 601
  Height = 559
  TabOrder = 0
  DesignSize = (
    601
    559)
  object CyclesInfoLabel: TLabel
    Left = 32
    Top = 439
    Width = 513
    Height = 97
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'CyclesInfoLabel'
    WordWrap = True
  end
  object CPUTypeLabel: TLabel
    Left = 312
    Top = 24
    Width = 76
    Height = 15
    Caption = 'CPUTypeLabel'
  end
  object InfoLabel: TLabel
    Left = 312
    Top = 72
    Width = 233
    Height = 217
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'InfoLabel'
    WordWrap = True
  end
  object CPUCoreRadioGroup: TRadioGroup
    Left = 24
    Top = 24
    Width = 273
    Height = 137
    Caption = 'CPUCoreRadioGroup'
    TabOrder = 0
  end
  object CPUCyclesGroupBox: TGroupBox
    Left = 24
    Top = 176
    Width = 273
    Height = 247
    Caption = 'CPUCyclesGroupBox'
    TabOrder = 2
    object CyclesUpLabel: TLabel
      Left = 16
      Top = 121
      Width = 77
      Height = 15
      Caption = 'CyclesUpLabel'
    end
    object CyclesDownLabel: TLabel
      Left = 16
      Top = 180
      Width = 93
      Height = 15
      Caption = 'CyclesDownLabel'
    end
    object CyclesAutoRadioButton: TRadioButton
      Left = 16
      Top = 32
      Width = 113
      Height = 17
      Caption = 'Auto'
      TabOrder = 0
      OnClick = CPUCyclesChange
    end
    object CyclesMaxRadioButton: TRadioButton
      Left = 16
      Top = 56
      Width = 113
      Height = 17
      Caption = 'Max'
      TabOrder = 1
      OnClick = CPUCyclesChange
    end
    object CyclesValueRadioButton: TRadioButton
      Left = 16
      Top = 80
      Width = 113
      Height = 17
      Caption = 'Value'
      TabOrder = 3
      OnClick = CPUCyclesChange
    end
    object CyclesComboBox: TComboBox
      Left = 112
      Top = 76
      Width = 104
      Height = 23
      TabOrder = 4
    end
    object CyclesMaxLimitCheckBox: TCheckBox
      Left = 112
      Top = 57
      Width = 97
      Height = 17
      Caption = 'Limit value'
      TabOrder = 2
      OnClick = CPUCyclesChange
    end
    object CyclesDownEdit: TSpinEdit
      Left = 16
      Top = 201
      Width = 69
      Height = 24
      MaxValue = 50000
      MinValue = 1
      TabOrder = 7
      Value = 20
    end
    object CyclesUpComboBox: TComboBox
      Left = 112
      Top = 143
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 6
      OnChange = CyclesUpComboBoxChange
    end
    object CyclesUpEdit: TSpinEdit
      Left = 16
      Top = 142
      Width = 69
      Height = 24
      MaxValue = 50000
      MinValue = 1
      TabOrder = 5
      Value = 500
    end
    object CyclesDownComboBox: TComboBox
      Left = 112
      Top = 201
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 8
      OnChange = CyclesDownComboBoxChange
    end
  end
  object CPUTypeComboBox: TComboBox
    Left = 312
    Top = 43
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object GroupBox1: TGroupBox
    Left = 303
    Top = 295
    Width = 242
    Height = 128
    Caption = 'CPU Features'
    TabOrder = 3
    object cbEnableSSE2: TCheckBox
      Left = 16
      Top = 32
      Width = 193
      Height = 17
      Caption = 'Enable SSE2'
      TabOrder = 0
    end
  end
end
