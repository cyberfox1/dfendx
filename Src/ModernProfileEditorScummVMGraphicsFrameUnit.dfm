object ModernProfileEditorScummVMGraphicsFrame: TModernProfileEditorScummVMGraphicsFrame
  Left = 0
  Top = 0
  Width = 602
  Height = 620
  TabOrder = 0
  DesignSize = (
    602
    620)
  object FilterLabel: TLabel
    Left = 24
    Top = 13
    Width = 54
    Height = 15
    Caption = 'FilterLabel'
  end
  object RenderModeLabel: TLabel
    Left = 24
    Top = 69
    Width = 96
    Height = 15
    Caption = 'RenderModeLabel'
  end
  object GfxModeLabel: TLabel
    Left = 25
    Top = 160
    Width = 76
    Height = 15
    Caption = 'GfxModeLabel'
  end
  object ScalerLabel: TLabel
    Left = 25
    Top = 216
    Width = 59
    Height = 15
    Caption = 'ScalerLabel'
  end
  object ScaleFactorLabel: TLabel
    Left = 25
    Top = 266
    Width = 88
    Height = 15
    Caption = 'ScaleFactorLabel'
  end
  object StretchModeLabel: TLabel
    Left = 25
    Top = 316
    Width = 96
    Height = 15
    Caption = 'StretchModeLabel'
  end
  object ShaderLabel: TLabel
    Left = 25
    Top = 366
    Width = 64
    Height = 15
    Caption = 'ShaderLabel'
  end
  object RendererLabel: TLabel
    Left = 26
    Top = 448
    Width = 75
    Height = 15
    Caption = 'RendererLabel'
  end
  object AntialiasingLabel: TLabel
    Left = 25
    Top = 504
    Width = 90
    Height = 15
    Caption = 'AntialiasingLabel'
  end
  object VSyncLabel: TLabel
    Left = 377
    Top = 417
    Width = 37
    Height = 15
    Caption = 'V-Sync'
  end
  object FilterComboBox: TComboBox
    Left = 24
    Top = 32
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = FilterChange
  end
  object StartFullscreenCheckBox: TCheckBox
    Left = 25
    Top = 128
    Width = 177
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'StartFullscreenCheckBox'
    TabOrder = 2
  end
  object KeepAspectRatioCheckBox: TCheckBox
    Left = 336
    Top = 128
    Width = 233
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'KeepAspectRatioCheckBox'
    TabOrder = 3
  end
  object RenderModeComboBox: TComboBox
    Left = 24
    Top = 88
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
  end
  object GfxModeComboBox: TComboBox
    Left = 25
    Top = 181
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
  end
  object ScalerComboBox: TComboBox
    Left = 25
    Top = 237
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
    OnChange = ModernScalerChange
  end
  object ScaleFactorComboBox: TComboBox
    Left = 25
    Top = 287
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 6
    OnChange = ModernScalerChange
  end
  object StretchModeComboBox: TComboBox
    Left = 25
    Top = 337
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 7
  end
  object ShaderEdit: TEdit
    Left = 25
    Top = 387
    Width = 533
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 8
  end
  object ShaderButton: TButton
    Left = 563
    Top = 387
    Width = 23
    Height = 23
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 13
    OnClick = ShaderButtonClick
  end
  object FilteringCheckBox: TCheckBox
    Left = 25
    Top = 416
    Width = 177
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'FilteringCheckBox'
    TabOrder = 9
  end
  object VSyncComboBox: TComboBox
    Left = 420
    Top = 414
    Width = 165
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 10
  end
  object RendererComboBox: TComboBox
    Left = 26
    Top = 469
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 11
  end
  object AntialiasingComboBox: TComboBox
    Left = 25
    Top = 525
    Width = 561
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 12
  end
  object ShaderOpenDialog: TOpenDialog
    DefaultExt = 'glslp'
    Filter = 'ScummVM shaders (*.glslp)|*.glslp|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 280
    Top = 400
  end
end
