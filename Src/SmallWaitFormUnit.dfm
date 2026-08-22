object SmallWaitForm: TSmallWaitForm
  Left = 0
  Top = 0
  BorderIcons = [biHelp]
  BorderStyle = bsDialog
  Caption = 'DFendX'
  ClientHeight = 51
  ClientWidth = 300
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  GlassFrame.Enabled = False
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 245
    Height = 17
    AutoSize = False
    Caption = 'Das "DOSBox DOS" Profil wird erstellt...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object SpinnerLabel: TLabel
    Left = 268
    Top = 14
    Width = 24
    Height = 21
    Alignment = taCenter
    AutoSize = False
    Caption = ''
  end
end
