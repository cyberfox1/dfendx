object ModernProfileEditorSoundBlasterFrame: TModernProfileEditorSoundBlasterFrame
  Left = 0
  Top = 0
  Width = 599
  Height = 522
  TabOrder = 0
  DesignSize = (
    599
    522)
  object TypeLabel: TLabel
    Left = 24
    Top = 24
    Width = 53
    Height = 15
    Caption = 'TypeLabel'
  end
  object AddressLabel: TLabel
    Left = 24
    Top = 80
    Width = 70
    Height = 15
    Caption = 'AddressLabel'
  end
  object InterruptLabel: TLabel
    Left = 120
    Top = 80
    Width = 74
    Height = 15
    Caption = 'InterruptLabel'
  end
  object DMALabel: TLabel
    Left = 24
    Top = 136
    Width = 55
    Height = 15
    Caption = 'DMALabel'
  end
  object HDMALabel: TLabel
    Left = 120
    Top = 136
    Width = 64
    Height = 15
    Caption = 'HDMALabel'
  end
  object OplModeLabel: TLabel
    Left = 24
    Top = 192
    Width = 78
    Height = 15
    Caption = 'OplModeLabel'
  end
  object OplSampleRateLabel: TLabel
    Left = 216
    Top = 192
    Width = 109
    Height = 15
    Caption = 'OplSampleRateLabel'
  end
  object OplEmuLabel: TLabel
    Left = 120
    Top = 192
    Width = 71
    Height = 15
    Caption = 'OplEmuLabel'
  end
  object FilterLabel: TLabel
    Left = 24
    Top = 247
    Width = 54
    Height = 15
    Caption = 'FilterLabel'
  end
  object WarmupLabel: TLabel
    Left = 120
    Top = 247
    Width = 74
    Height = 15
    Caption = 'WarmupLabel'
  end
  object TypeComboBox: TComboBox
    Left = 24
    Top = 43
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    OnChange = TypeComboBoxChange
  end
  object AddressComboBox: TComboBox
    Left = 24
    Top = 99
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object InterruptComboBox: TComboBox
    Left = 120
    Top = 99
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object DMAComboBox: TComboBox
    Left = 24
    Top = 155
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object HDMAComboBox: TComboBox
    Left = 120
    Top = 155
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 4
  end
  object OplModeComboBox: TComboBox
    Left = 24
    Top = 211
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 5
  end
  object OplSampleRateComboBox: TComboBox
    Left = 216
    Top = 211
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 7
  end
  object FilterComboBox: TComboBox
    Left = 24
    Top = 268
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 8
  end
  object FilterAlwaysOnCheckBox: TCheckBox
    Left = 24
    Top = 304
    Width = 553
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'FilterAlwaysOnCheckBox'
    TabOrder = 9
  end
  object WarmupEdit: TSpinEdit
    Left = 120
    Top = 268
    Width = 81
    Height = 24
    MaxValue = 100
    MinValue = 0
    TabOrder = 10
    Value = 100
  end
  object OplEmuComboBox: TComboBox
    Left = 120
    Top = 211
    Width = 81
    Height = 23
    Style = csDropDownList
    TabOrder = 6
  end
  object emu8kSettings: TGroupBox
    Left = 24
    Top = 340
    Width = 553
    Height = 123
    Anchors = [akLeft, akTop, akRight]
    Caption = 'AWE32 Settings'
    TabOrder = 11
    Visible = False
    DesignSize = (
      553
      123)
    object AWE32MemSizeLabel: TLabel
      Left = 16
      Top = 20
      Width = 112
      Height = 15
      Caption = 'AWE32MemSizeLabel'
    end
    object AWE32RomFileButton: TSpeedButton
      Left = 512
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
      OnClick = AWE32RomFileButtonClick
      ExplicitLeft = 320
    end
    object AWE32MemSizeComboBox: TComboBox
      Left = 16
      Top = 39
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object AWE32RomFileEdit: TLabeledEdit
      Left = 16
      Top = 86
      Width = 494
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 46
      EditLabel.Height = 15
      EditLabel.Caption = 'ROM file'
      TabOrder = 1
      Text = ''
      ExplicitWidth = 302
    end
  end
  object sbFeatures: TGroupBox
    Left = 253
    Top = 43
    Width = 281
    Height = 105
    Caption = 'Extra Features'
    TabOrder = 12
    DesignSize = (
      281
      105)
    object UseMixerCheckBox: TCheckBox
      Left = 16
      Top = 27
      Width = 201
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'UseMixerCheckBox'
      TabOrder = 0
      ExplicitWidth = 153
    end
    object ActivateCMSCheckBox: TCheckBox
      Left = 16
      Top = 50
      Width = 201
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Activate CMS'
      TabOrder = 1
      ExplicitWidth = 153
    end
    object GoldplayCheckBox: TCheckBox
      Left = 16
      Top = 73
      Width = 225
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Activate Goldplay'
      TabOrder = 2
      ExplicitWidth = 177
    end
  end
end
