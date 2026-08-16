object ModernProfileEditorMIDIFrame: TModernProfileEditorMIDIFrame
  Left = 0
  Top = 0
  Width = 760
  Height = 578
  TabOrder = 0
  DesignSize = (
    760
    578)
  object TypeLabel: TLabel
    Left = 24
    Top = 24
    Width = 53
    Height = 15
    Caption = 'TypeLabel'
  end
  object DeviceLabel: TLabel
    Left = 24
    Top = 80
    Width = 63
    Height = 15
    Caption = 'DeviceLabel'
  end
  object MIDISelectLabel1: TLabel
    Left = 320
    Top = 179
    Width = 408
    Height = 38
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 
      'If no device is selected, the Windows default MIDI device will b' +
      'e used.'
    WordWrap = True
  end
  object MIDISelectLabel2: TLabel
    Left = 320
    Top = 241
    Width = 401
    Height = 48
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 
      'Clicking a device from the list will add it to the additionally ' +
      'MIDI settings field.'
    Visible = False
    WordWrap = True
  end
  object InfoLabel: TLabel
    Left = 190
    Top = 24
    Width = 408
    Height = 71
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 
      'The MIDI device will be available on address 330 and interrupt 2' +
      ' in DOSBox.'
    WordWrap = True
  end
  object TypeComboBox: TComboBox
    Left = 24
    Top = 43
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object DeviceComboBox: TComboBox
    Left = 24
    Top = 99
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 1
    OnChange = DeviceComboBoxChange
  end
  object AdditionalSettingsEdit: TLabeledEdit
    Left = 24
    Top = 152
    Width = 704
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 117
    EditLabel.Height = 15
    EditLabel.Caption = 'AdditionalSettingsEdit'
    TabOrder = 2
    Text = ''
  end
  object MIDISelectButton: TButton
    Left = 24
    Top = 179
    Width = 290
    Height = 25
    Caption = 'Select MIDI device from device manager'
    TabOrder = 3
    OnClick = MIDISelectButtonClick
  end
  object MIDISelectListBox: TListBox
    Left = 24
    Top = 210
    Width = 290
    Height = 97
    ItemHeight = 15
    TabOrder = 4
    Visible = False
    OnClick = MIDISelectListBoxClick
  end
  object MT32SettingsGroupBox: TGroupBox
    Left = 24
    Top = 313
    Width = 489
    Height = 81
    Caption = 'MT32SettingsGroupBox'
    TabOrder = 5
    object MT32ModeLabel: TLabel
      Left = 16
      Top = 24
      Width = 89
      Height = 15
      Caption = 'MT32ModeLabel'
    end
    object MT32TimeLabel: TLabel
      Left = 132
      Top = 24
      Width = 85
      Height = 15
      Caption = 'MT32TimeLabel'
    end
    object MT32ModelLabel: TLabel
      Left = 366
      Top = 24
      Width = 92
      Height = 15
      Caption = 'MT32ModelLabel'
    end
    object MT32LevelLabel: TLabel
      Left = 247
      Top = 24
      Width = 85
      Height = 15
      Caption = 'MT32LevelLabel'
    end
    object MT32ModeComboBox: TComboBox
      Left = 16
      Top = 40
      Width = 90
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object MT32TimeComboBox: TComboBox
      Left = 132
      Top = 40
      Width = 90
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
    object MT32LevelComboBox: TComboBox
      Left = 247
      Top = 40
      Width = 90
      Height = 23
      Style = csDropDownList
      TabOrder = 2
    end
    object MT32ModelComboBox: TComboBox
      Left = 366
      Top = 40
      Width = 90
      Height = 23
      Style = csDropDownList
      TabOrder = 3
    end
  end
  object FluidSynthGroupBox: TGroupBox
    Left = 24
    Top = 406
    Width = 489
    Height = 125
    Caption = 'FluidSynth Settings'
    TabOrder = 6
    DesignSize = (
      489
      125)
    object BtnFluidSynthPath: TSpeedButton
      Left = 431
      Top = 89
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
    end
    object FluidSynthPathBox: TLabeledEdit
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
      OnChange = FluidSynthPathBoxChange
    end
    object lbFluidSynthGainValue: TLabeledEdit
      Left = 425
      Top = 33
      Width = 40
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 24
      EditLabel.Height = 15
      EditLabel.Caption = 'Gain'
      TabOrder = 1
      Text = ''
    end
    object tbFluidSynthGainSlider: TTrackBar
      Left = 16
      Top = 32
      Width = 397
      Height = 26
      Constraints.MinWidth = 395
      Max = 800
      Frequency = 100
      TabOrder = 2
      TickStyle = tsManual
    end
  end
end
