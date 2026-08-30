object ModernProfileEditorScummVMSettingsFrame: TModernProfileEditorScummVMSettingsFrame
  Left = 0
  Top = 0
  Width = 701
  Height = 480
  TabOrder = 0
  DesignSize = (
    701
    480)
  object VariantLabel: TLabel
    Left = 16
    Top = 16
    Width = 64
    Height = 13
    Caption = 'Game variant'
  end
  object VariantComboBox: TComboBox
    Left = 16
    Top = 35
    Width = 665
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 13
    TabOrder = 0
    OnChange = VariantComboBoxChange
  end
  object OptionsScrollBox: TScrollBox
    Left = 16
    Top = 72
    Width = 665
    Height = 344
    Anchors = [akLeft, akTop, akRight, akBottom]
    BorderStyle = bsNone
    TabOrder = 1
  end
end
