object ModernProfileEditorMouseFrame: TModernProfileEditorMouseFrame
  Left = 0
  Top = 0
  Width = 545
  Height = 530
  TabOrder = 0
  DesignSize = (
    545
    530)
  object LockMouseLabel: TLabel
    Left = 36
    Top = 47
    Width = 494
    Height = 51
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'LockMouseLabel'
    WordWrap = True
    ExplicitWidth = 709
  end
  object MouseSensitivityLabel: TLabel
    Left = 16
    Top = 112
    Width = 105
    Height = 13
    Caption = 'MouseSensitivityLabel'
  end
  object Force2ButtonsInfoLabel: TLabel
    Left = 32
    Top = 199
    Width = 498
    Height = 42
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Force2ButtonsInfoLabel'
    WordWrap = True
    ExplicitWidth = 724
  end
  object SwapButtonsInfoLabel: TLabel
    Left = 32
    Top = 287
    Width = 498
    Height = 42
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Force2ButtonsInfoLabel'
    WordWrap = True
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
    Top = 131
    Width = 65
    Height = 22
    MaxValue = 1000
    MinValue = 1
    TabOrder = 1
    Value = 100
  end
  object Force2ButtonsCheckBox: TCheckBox
    Left = 16
    Top = 176
    Width = 514
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Force2ButtonsCheckBox'
    TabOrder = 2
    OnClick = Force2ButtonsCheckBoxClick
  end
  object SwapButtonsCheckBox: TCheckBox
    Left = 16
    Top = 264
    Width = 514
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'SwapButtonsCheckBox'
    TabOrder = 3
  end
  object MouseDriverModelLabel: TLabel
    Left = 16
    Top = 340
    Width = 120
    Height = 15
    Caption = 'MouseDriverModelLabel'
    Visible = False
  end
  object MouseMoveThresholdLabel: TLabel
    Left = 192
    Top = 340
    Width = 140
    Height = 15
    Caption = 'MouseMoveThresholdLabel'
    Visible = False
  end
  object MouseDriverModelComboBox: TComboBox
    Left = 16
    Top = 359
    Width = 160
    Height = 23
    Style = csDropDownList
    TabOrder = 4
    Visible = False
  end
  object MouseMoveThresholdComboBox: TComboBox
    Left = 192
    Top = 359
    Width = 80
    Height = 23
    Style = csDropDownList
    TabOrder = 5
    Visible = False
  end
  object MouseDriverOptionsGroupBox: TGroupBox
    Left = 16
    Top = 396
    Width = 514
    Height = 64
    Anchors = [akLeft, akTop, akRight]
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
      Left = 168
      Top = 24
      Width = 145
      Height = 17
      Caption = 'Modern'
      TabOrder = 1
    end
    object MouseNoGranularityCheckBox: TCheckBox
      Left = 320
      Top = 24
      Width = 178
      Height = 17
      Caption = 'No granularity'
      TabOrder = 2
    end
  end
end
