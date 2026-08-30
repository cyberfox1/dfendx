object ModernProfileEditorScummVMSoundFrame: TModernProfileEditorScummVMSoundFrame
  Left = 0
  Top = 0
  Width = 602
  Height = 540
  TabOrder = 0
  DesignSize = (
    602
    540)
  object MusicVolumeLabel: TLabel
    Left = 16
    Top = 16
    Width = 100
    Height = 15
    Caption = 'MusicVolumeLabel'
  end
  object SpeechVolumeLabel: TLabel
    Left = 160
    Top = 16
    Width = 106
    Height = 15
    Caption = 'SpeechVolumeLabel'
  end
  object SFXVolumeLabel: TLabel
    Left = 304
    Top = 16
    Width = 87
    Height = 15
    Caption = 'SFXVolumeLabel'
  end
  object OutputRateLabel: TLabel
    Left = 16
    Top = 80
    Width = 89
    Height = 15
    Caption = 'OutputRateLabel'
  end
  object MusicDriverLabel: TLabel
    Left = 16
    Top = 136
    Width = 91
    Height = 15
    Caption = 'MusicDriverLabel'
  end
  object OplDriverLabel: TLabel
    Left = 16
    Top = 188
    Width = 78
    Height = 15
    Caption = 'OplDriverLabel'
  end
  object MusicVolumeEdit: TSpinEdit
    Left = 16
    Top = 35
    Width = 77
    Height = 24
    MaxValue = 255
    MinValue = 0
    TabOrder = 0
    Value = 192
  end
  object SpeechVolumeEdit: TSpinEdit
    Left = 160
    Top = 35
    Width = 77
    Height = 24
    MaxValue = 255
    MinValue = 0
    TabOrder = 1
    Value = 192
  end
  object SFXVolumeEdit: TSpinEdit
    Left = 304
    Top = 35
    Width = 77
    Height = 24
    MaxValue = 255
    MinValue = 0
    TabOrder = 2
    Value = 192
  end
  object OutputRateComboBox: TComboBox
    Left = 16
    Top = 99
    Width = 94
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object MusicDriverComboBox: TComboBox
    Left = 16
    Top = 155
    Width = 569
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
    OnChange = MusicDriverComboBoxChange
  end
  object OplDriverComboBox: TComboBox
    Left = 16
    Top = 207
    Width = 569
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 10
  end
  object SynthSettingsGroupBox: TGroupBox
    Left = 16
    Top = 240
    Width = 489
    Height = 125
    Caption = 'FluidSynth Settings'
    TabOrder = 5
    DesignSize = (
      489
      125)
    object SynthPathButton: TSpeedButton
      Left = 427
      Top = 86
      Width = 25
      Height = 23
      Anchors = [akTop, akRight]
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        04000000000000010000120B0000120B00001000000000000000000000000000
        800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
        5555555555555555555555555555555555555555555555555555555555555555
        555555555555555555555555555555555555555FFFFFFFFFF555550000000000
        55555577777777775F55500B8B8B8B8B05555775F555555575F550F0B8B8B8B8
        B05557F75F555555575F50BF0B8B8B8B8B0557F575FFFFFFFF7F50FBF0000000
        000557F557777777777550BFBFBFBFB0555557F555555557F55550FBFBFBFBF0
        555557F555555FF7555550BFBFBF00055555575F555577755555550BFBF05555
        55555575FFF75555555555700007555555555557777555555555555555555555
        5555555555555555555555555555555555555555555555555555}
      NumGlyphs = 2
      ParentShowHint = False
      ShowHint = True
      OnClick = SynthPathButtonClick
    end
    object SynthPathEdit: TLabeledEdit
      Left = 16
      Top = 86
      Width = 409
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Constraints.MinWidth = 395
      EditLabel.Width = 83
      EditLabel.Height = 15
      EditLabel.Caption = 'Soundfont path'
      TabOrder = 0
      Text = ''
    end
    object SynthGainValueEdit: TLabeledEdit
      Left = 425
      Top = 33
      Width = 40
      Height = 23
      TabStop = False
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 24
      EditLabel.Height = 15
      EditLabel.Caption = 'Gain'
      ReadOnly = True
      TabOrder = 1
      Text = ''
    end
    object SynthGainTrackBar: TTrackBar
      Left = 16
      Top = 32
      Width = 397
      Height = 26
      Constraints.MinWidth = 395
      Max = 1000
      Frequency = 100
      Position = 100
      TabOrder = 2
      TickStyle = tsManual
      OnChange = SynthGainTrackBarChange
    end
  end
  object NativeMT32CheckBox: TCheckBox
    Left = 16
    Top = 380
    Width = 569
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'NativeMT32CheckBox'
    TabOrder = 6
  end
  object EnableGSCheckBox: TCheckBox
    Left = 16
    Top = 412
    Width = 569
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'EnableGSCheckBox'
    TabOrder = 7
  end
  object MultiMIDICheckBox: TCheckBox
    Left = 16
    Top = 444
    Width = 569
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'MultiMIDICheckBox'
    TabOrder = 8
  end
  object SpeechMuteCheckBox: TCheckBox
    Left = 16
    Top = 476
    Width = 569
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'SpeechMuteCheckBox'
    TabOrder = 9
  end
end
