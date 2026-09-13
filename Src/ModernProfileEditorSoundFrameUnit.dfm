object ModernProfileEditorSoundFrame: TModernProfileEditorSoundFrame
  Left = 0
  Top = 0
  Width = 556
  Height = 541
  TabOrder = 0
  DesignSize = (
    556
    541)
  object PCSpeakerSampleRateLabel: TLabel
    Left = 24
    Top = 277
    Width = 146
    Height = 15
    Caption = 'PCSpeakerSampleRateLabel'
  end
  object TandySampleRateLabel: TLabel
    Left = 384
    Top = 248
    Width = 122
    Height = 15
    Caption = 'TandySampleRateLabel'
  end
  object LptDacLabel: TLabel
    Left = 208
    Top = 398
    Width = 65
    Height = 15
    Caption = 'LptDacLabel'
  end
  object LptDacFilterLabel: TLabel
    Left = 208
    Top = 343
    Width = 91
    Height = 15
    Caption = 'LptDacFilterLabel'
  end
  object PS1AudioRateLabel: TLabel
    Left = 24
    Top = 374
    Width = 102
    Height = 15
    Caption = 'PS1AudioRateLabel'
  end
  object ActivatePS1AudioCheckBox: TCheckBox
    Left = 24
    Top = 343
    Width = 178
    Height = 17
    Caption = 'Activate PS/1 audio'
    TabOrder = 10
    OnClick = ActivatePS1AudioCheckBoxClick
  end
  object ActivateSoundCheckBox: TCheckBox
    Left = 24
    Top = 24
    Width = 508
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'ActivateSoundCheckBox'
    TabOrder = 0
  end
  object MixerGroupBox: TGroupBox
    Left = 40
    Top = 56
    Width = 492
    Height = 177
    Caption = 'MixerGroupBox'
    TabOrder = 1
    object SampleRateLabel: TLabel
      Left = 16
      Top = 32
      Width = 90
      Height = 15
      Caption = 'SampleRateLabel'
    end
    object BlockSizeLabel: TLabel
      Left = 184
      Top = 32
      Width = 77
      Height = 15
      Caption = 'BlockSizeLabel'
    end
    object PreBufferLabel: TLabel
      Left = 360
      Top = 34
      Width = 77
      Height = 15
      Caption = 'PreBufferLabel'
    end
    object CrossfeedLabel: TLabel
      Left = 16
      Top = 112
      Width = 80
      Height = 15
      Caption = 'CrossfeedLabel'
    end
    object ReverbLabel: TLabel
      Left = 184
      Top = 112
      Width = 64
      Height = 15
      Caption = 'ReverbLabel'
    end
    object ChorusLabel: TLabel
      Left = 360
      Top = 112
      Width = 66
      Height = 15
      Caption = 'ChorusLabel'
    end
    object SampleRateComboBox: TComboBox
      Left = 16
      Top = 51
      Width = 82
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object BlockSizeComboBox: TComboBox
      Left = 184
      Top = 51
      Width = 82
      Height = 23
      TabOrder = 1
    end
    object PreBufferComboBox: TComboBox
      Left = 360
      Top = 53
      Width = 82
      Height = 23
      TabOrder = 2
    end
    object SwapStereoCheckBox: TCheckBox
      Left = 16
      Top = 88
      Width = 150
      Height = 17
      Caption = 'SwapStereoCheckBox'
      TabOrder = 3
    end
    object SampleAccurateCheckBox: TCheckBox
      Left = 168
      Top = 88
      Width = 150
      Height = 17
      Caption = 'SampleAccurateCheckBox'
      TabOrder = 4
    end
    object DCBiasCheckBox: TCheckBox
      Left = 320
      Top = 88
      Width = 156
      Height = 17
      Caption = 'DCBiasCheckBox'
      TabOrder = 5
    end
    object CompressorCheckBox: TCheckBox
      Left = 16
      Top = 88
      Width = 150
      Height = 17
      Caption = 'CompressorCheckBox'
      TabOrder = 6
    end
    object CrossfeedComboBox: TComboBox
      Left = 16
      Top = 131
      Width = 82
      Height = 23
      Style = csDropDownList
      TabOrder = 7
    end
    object ReverbComboBox: TComboBox
      Left = 184
      Top = 131
      Width = 82
      Height = 23
      Style = csDropDownList
      TabOrder = 8
    end
    object ChorusComboBox: TComboBox
      Left = 360
      Top = 131
      Width = 82
      Height = 23
      Style = csDropDownList
      TabOrder = 9
    end
  end
  object ActivatePCSpeakerCheckBox: TCheckBox
    Left = 24
    Top = 248
    Width = 193
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'ActivatePCSpeakerCheckBox'
    TabOrder = 2
    OnClick = ActivatePCSpeakerCheckBoxClick
  end
  object PCSpeakerSampleRateComboBox: TComboBox
    Left = 24
    Top = 298
    Width = 82
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object TandyRadioGroup: TRadioGroup
    Left = 208
    Top = 248
    Width = 150
    Height = 89
    Caption = 'TandyRadioGroup'
    Items.Strings = (
      'auto'
      'on'
      'off')
    TabOrder = 4
    OnClick = TandyRadioGroupClick
  end
  object TandyComboBox: TComboBox
    Left = 384
    Top = 269
    Width = 82
    Height = 23
    Style = csDropDownList
    TabOrder = 5
  end
  object ActivateDisneyCheckBox: TCheckBox
    Left = 24
    Top = 474
    Width = 169
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'ActivateDisneyCheckBox'
    TabOrder = 6
  end
  object LptDacComboBox: TComboBox
    Left = 208
    Top = 419
    Width = 82
    Height = 23
    Style = csDropDownList
    TabOrder = 7
  end
  object LptDacFilterComboBox: TComboBox
    Left = 208
    Top = 364
    Width = 82
    Height = 23
    Style = csDropDownList
    TabOrder = 8
  end
  object PS1AudioRateComboBox: TComboBox
    Left = 24
    Top = 395
    Width = 82
    Height = 23
    Style = csDropDownList
    TabOrder = 9
  end
end
