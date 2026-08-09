object SetupFrameGamesListScreenshotModeAppearance: TSetupFrameGamesListScreenshotModeAppearance
  Left = 0
  Top = 0
  Width = 576
  Height = 375
  TabOrder = 0
  DesignSize = (
    576
    375)
  object WidthLabel: TLabel
    Left = 16
    Top = 16
    Width = 109
    Height = 13
    Caption = '&Breite der Screenshots'
    FocusControl = WidthEdit
  end
  object HeightLabel: TLabel
    Left = 16
    Top = 80
    Width = 106
    Height = 13
    Caption = '&H'#246'he der Screenshots'
    FocusControl = HeightEdit
  end
  object WidthEdit: TSpinEdit
    Left = 16
    Top = 35
    Width = 89
    Height = 22
    MaxValue = 500
    MinValue = 10
    TabOrder = 0
    Value = 10
  end
  object HeightEdit: TSpinEdit
    Left = 16
    Top = 99
    Width = 89
    Height = 22
    MaxValue = 500
    MinValue = 10
    TabOrder = 1
    Value = 10
  end
end
