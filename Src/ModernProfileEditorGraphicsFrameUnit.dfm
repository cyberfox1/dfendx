object ModernProfileEditorGraphicsFrame: TModernProfileEditorGraphicsFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 586
  TabOrder = 0
  object WindowResolutionLabel: TLabel
    Left = 24
    Top = 13
    Width = 128
    Height = 15
    Caption = 'WindowResolutionLabel'
  end
  object FullscreenResolutionLabel: TLabel
    Left = 184
    Top = 13
    Width = 137
    Height = 15
    Caption = 'FullscreenResolutionLabel'
  end
  object FullscreenInfoLabel: TLabel
    Left = 40
    Top = 138
    Width = 341
    Height = 35
    AutoSize = False
    Caption = 'FullscreenInfoLabel'
    WordWrap = True
  end
  object ResolutionInfoLabel: TLabel
    Left = 24
    Top = 59
    Width = 357
    Height = 46
    AutoSize = False
    Caption = 'ResolutionInfoLabel'
    Constraints.MinWidth = 357
    WordWrap = True
  end
  object VSyncLabel: TLabel
    Left = 349
    Top = 194
    Width = 32
    Height = 15
    Caption = 'VSync'
  end
  object WindowResolutionComboBox: TComboBox
    Left = 24
    Top = 32
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object FullscreenResolutionComboBox: TComboBox
    Left = 184
    Top = 32
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object StartFullscreenCheckBox: TCheckBox
    Left = 24
    Top = 120
    Width = 344
    Height = 12
    Caption = 'StartFullscreenCheckBox'
    TabOrder = 2
  end
  object DoublebufferingCheckBox: TCheckBox
    Left = 24
    Top = 176
    Width = 217
    Height = 17
    Caption = 'DoublebufferingCheckBox'
    TabOrder = 3
  end
  object KeepAspectRatioCheckBox: TCheckBox
    Left = 24
    Top = 208
    Width = 217
    Height = 17
    Caption = 'KeepAspectRatioCheckBox'
    TabOrder = 4
  end
  object TextModeLinesRadioGroup: TRadioGroup
    Left = 3
    Top = 456
    Width = 169
    Height = 105
    Caption = 'TextModeLinesRadioGroup'
    ItemIndex = 0
    Items.Strings = (
      '25'
      '28'
      '50')
    TabOrder = 6
    Visible = False
  end
  object VGASettingsGroupBox: TGroupBox
    Left = 184
    Top = 456
    Width = 364
    Height = 105
    Caption = 'VGASettingsGroupBox'
    TabOrder = 8
    Visible = False
    object VGAChipsetLabel: TLabel
      Left = 16
      Top = 26
      Width = 91
      Height = 15
      Caption = 'VGAChipsetLabel'
    end
    object VideoRamLabel: TLabel
      Left = 199
      Top = 26
      Width = 82
      Height = 15
      Caption = 'VideoRamLabel'
    end
    object VGASettingsLabel: TLabel
      Left = 24
      Top = 76
      Width = 385
      Height = 34
      AutoSize = False
      Caption = 'This settings are only used if video card type is "vga".'
      WordWrap = True
    end
    object VGAChipsetComboBox: TComboBox
      Left = 16
      Top = 47
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object VideoRamComboBox: TComboBox
      Left = 199
      Top = 47
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
  end
  object VSyncComboBox: TComboBox
    Left = 387
    Top = 191
    Width = 161
    Height = 23
    Style = csDropDownList
    TabOrder = 5
  end
  object rgScreenInactive: TRadioGroup
    Left = 387
    Top = 44
    Width = 161
    Height = 129
    Caption = 'When Screen Inactive'
    Items.Strings = (
      'Do nothing'
      'Mute'
      'Pause')
    TabOrder = 7
  end
  object GroupBox1: TGroupBox
    Left = 3
    Top = 240
    Width = 545
    Height = 210
    Caption = 'Render Options'
    TabOrder = 9
    object RenderLabel: TLabel
      Left = 17
      Top = 29
      Width = 38
      Height = 15
      Caption = 'Output'
    end
    object VideoCardLabel: TLabel
      Left = 176
      Top = 29
      Width = 83
      Height = 15
      Caption = 'VideoCardLabel'
    end
    object ScaleLabel: TLabel
      Left = 16
      Top = 87
      Width = 55
      Height = 15
      Caption = 'ScaleLabel'
    end
    object FrameSkipLabel: TLabel
      Left = 414
      Top = 88
      Width = 83
      Height = 15
      Caption = 'FrameSkipLabel'
    end
    object PixelShaderLabel: TLabel
      Left = 17
      Top = 148
      Width = 88
      Height = 15
      Caption = 'PixelShaderLabel'
    end
    object ShaderPresetLabel: TLabel
      Left = 418
      Top = 148
      Width = 88
      Height = 15
      Caption = 'PixelShaderLabel'
    end
    object RenderComboBox: TComboBox
      Left = 16
      Top = 50
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object VideoCardComboBox: TComboBox
      Left = 176
      Top = 50
      Width = 330
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
    object ScaleComboBox: TComboBox
      Left = 16
      Top = 109
      Width = 385
      Height = 23
      Style = csDropDownList
      Constraints.MinWidth = 371
      TabOrder = 2
    end
    object FrameSkipEdit: TSpinEdit
      Left = 414
      Top = 109
      Width = 92
      Height = 24
      MaxValue = 10
      MinValue = 0
      TabOrder = 3
      Value = 0
    end
    object PixelShaderComboBox: TComboBox
      Left = 16
      Top = 169
      Width = 385
      Height = 23
      TabOrder = 4
      OnChange = PixelShaderComboBoxChange
    end
    object ShaderPresetComboBox: TComboBox
      Left = 414
      Top = 169
      Width = 126
      Height = 23
      TabOrder = 5
      OnChange = PixelShaderComboBoxChange
    end
  end
end
