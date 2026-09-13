object ModernProfileEditorMouseFrame: TModernProfileEditorMouseFrame
  Left = 0
  Top = 0
  Width = 545
  Height = 587
  TabOrder = 0
  DesignSize = (
    545
    587)
  object LockMouseLabel: TLabel
    Left = 36
    Top = 47
    Width = 494
    Height = 35
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'LockMouseLabel'
    WordWrap = True
  end
  object MouseSensitivityLabel: TLabel
    Left = 16
    Top = 88
    Width = 117
    Height = 15
    Caption = 'MouseSensitivityLabel'
  end
  object Force2ButtonsInfoLabel: TLabel
    Left = 16
    Top = 360
    Width = 457
    Height = 34
    AutoSize = False
    Caption = 'Force2ButtonsInfoLabel'
    WordWrap = True
  end
  object SwapButtonsInfoLabel: TLabel
    Left = 16
    Top = 423
    Width = 457
    Height = 30
    AutoSize = False
    Caption = 'Force2ButtonsInfoLabel'
    WordWrap = True
  end
  object MouseDriverModelLabel: TLabel
    Left = 16
    Top = 152
    Width = 129
    Height = 15
    Caption = 'MouseDriverModelLabel'
    Visible = False
  end
  object MouseMoveThresholdLabel: TLabel
    Left = 192
    Top = 152
    Width = 147
    Height = 15
    Caption = 'MouseMoveThresholdLabel'
    Visible = False
  end
  object Ps2ModelLabel: TLabel
    Left = 222
    Top = 483
    Width = 80
    Height = 15
    Caption = 'Ps2ModelLabel'
  end
  object Ps2ReportRateLabel: TLabel
    Left = 360
    Top = 459
    Width = 104
    Height = 15
    Caption = 'Ps2ReportRateLabel'
  end
  object LockMouseCheckBox: TCheckBox
    Left = 16
    Top = 24
    Width = 514
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'LockMouseCheckBox'
    TabOrder = 0
  end
  object MouseSensitivityEdit: TSpinEdit
    Left = 16
    Top = 109
    Width = 65
    Height = 24
    MaxValue = 1000
    MinValue = 1
    TabOrder = 1
    Value = 100
  end
  object Force2ButtonsCheckBox: TCheckBox
    Left = 16
    Top = 337
    Width = 473
    Height = 17
    Caption = 'Force2ButtonsCheckBox'
    TabOrder = 2
    OnClick = Force2ButtonsCheckBoxClick
  end
  object SwapButtonsCheckBox: TCheckBox
    Left = 16
    Top = 400
    Width = 473
    Height = 17
    Caption = 'SwapButtonsCheckBox'
    TabOrder = 3
  end
  object MouseDriverModelComboBox: TComboBox
    Left = 17
    Top = 175
    Width = 160
    Height = 23
    Style = csDropDownList
    TabOrder = 4
    Visible = False
  end
  object MouseMoveThresholdComboBox: TComboBox
    Left = 192
    Top = 175
    Width = 80
    Height = 23
    Style = csDropDownList
    TabOrder = 5
    Visible = False
  end
  object MouseDriverOptionsGroupBox: TGroupBox
    Left = 16
    Top = 215
    Width = 448
    Height = 60
    Caption = 'MouseDriverOptionsGroupBox'
    TabOrder = 6
    Visible = False
    object MouseImmediateCheckBox: TCheckBox
      Left = 16
      Top = 24
      Width = 145
      Height = 17
      Caption = 'Immediate'
      TabOrder = 0
    end
    object MouseModernCheckBox: TCheckBox
      Left = 167
      Top = 24
      Width = 145
      Height = 17
      Caption = 'Modern'
      TabOrder = 1
    end
    object MouseNoGranularityCheckBox: TCheckBox
      Left = 319
      Top = 24
      Width = 178
      Height = 17
      Caption = 'No granularity'
      TabOrder = 2
    end
  end
  object Ps2CheckBox: TCheckBox
    Left = 16
    Top = 314
    Width = 250
    Height = 17
    Caption = 'Ps2CheckBox'
    TabOrder = 7
    OnClick = Ps2CheckBoxClick
  end
  object CtmouseCheckBox: TCheckBox
    Left = 292
    Top = 515
    Width = 197
    Height = 17
    Caption = 'CtmouseCheckBox'
    TabOrder = 8
  end
  object Ps2ModelComboBox: TComboBox
    Left = 16
    Top = 480
    Width = 200
    Height = 23
    Style = csDropDownList
    TabOrder = 9
  end
  object Ps2ReportRateComboBox: TComboBox
    Left = 360
    Top = 480
    Width = 100
    Height = 23
    Style = csDropDownList
    TabOrder = 10
  end
  object VMwareCheckBox: TCheckBox
    Left = 16
    Top = 515
    Width = 160
    Height = 17
    Caption = 'VMwareCheckBox'
    TabOrder = 11
  end
  object VirtualBoxCheckBox: TCheckBox
    Left = 16
    Top = 543
    Width = 160
    Height = 17
    Caption = 'VirtualBoxCheckBox'
    TabOrder = 12
  end
  object BiosPs2CheckBox: TCheckBox
    Left = 292
    Top = 543
    Width = 197
    Height = 17
    Caption = 'BiosPs2CheckBox'
    TabOrder = 13
  end
end
