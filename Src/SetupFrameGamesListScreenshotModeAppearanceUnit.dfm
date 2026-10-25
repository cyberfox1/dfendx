object SetupFrameGamesListScreenshotModeAppearance: TSetupFrameGamesListScreenshotModeAppearance
  Left = 0
  Top = 0
  Width = 576
  Height = 375
  TabOrder = 0
  object gbCoverImagesView: TGroupBox
    Left = 16
    Top = 183
    Width = 262
    Height = 174
    Caption = 'Cover Images'
    TabOrder = 0
    DesignSize = (
      262
      174)
    object CoverWidthLabel: TLabel
      Left = 10
      Top = 24
      Width = 119
      Height = 15
      Caption = 'Width of cover images'
      FocusControl = CoverWidthEdit
    end
    object CoverHeightLabel: TLabel
      Left = 11
      Top = 80
      Width = 123
      Height = 15
      Caption = 'Height of cover images'
      FocusControl = CoverHeightEdit
    end
    object CoverWidthEdit: TSpinEdit
      Left = 11
      Top = 45
      Width = 89
      Height = 24
      MaxValue = 500
      MinValue = 10
      TabOrder = 0
      Value = 10
    end
    object CoverHeightEdit: TSpinEdit
      Left = 11
      Top = 101
      Width = 89
      Height = 24
      MaxValue = 500
      MinValue = 10
      TabOrder = 1
      Value = 10
    end
    object CoverShowCaptionsCheckBox: TCheckBox
      Left = 11
      Top = 139
      Width = 196
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Show titles'
      TabOrder = 2
    end
  end
  object gbScreenshotsView: TGroupBox
    Left = 16
    Top = 3
    Width = 262
    Height = 174
    Caption = 'Screenshots'
    TabOrder = 1
    DesignSize = (
      262
      174)
    object WidthLabel: TLabel
      Left = 16
      Top = 24
      Width = 116
      Height = 15
      Caption = '&Breite der Screenshots'
      FocusControl = WidthEdit
    end
    object HeightLabel: TLabel
      Left = 17
      Top = 80
      Width = 115
      Height = 15
      Caption = '&H'#246'he der Screenshots'
      FocusControl = HeightEdit
    end
    object WidthEdit: TSpinEdit
      Left = 16
      Top = 45
      Width = 89
      Height = 24
      MaxValue = 500
      MinValue = 10
      TabOrder = 0
      Value = 10
    end
    object HeightEdit: TSpinEdit
      Left = 16
      Top = 101
      Width = 89
      Height = 24
      MaxValue = 500
      MinValue = 10
      TabOrder = 1
      Value = 10
    end
    object ScreenshotShowCaptionsCheckBox: TCheckBox
      Left = 17
      Top = 139
      Width = 196
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Show titles'
      TabOrder = 2
    end
  end
end
