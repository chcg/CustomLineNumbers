object frmAbout: TfrmAbout
  Left = 272
  Top = 227
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  ClientHeight = 145
  ClientWidth = 257
  Color = clBtnFace
  DefaultMonitor = dmDesktop
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PopupMode = pmExplicit
  Position = poDefault
  OnCreate = FormCreate
  DesignSize = (
    257
    145)
  PixelsPerInch = 96
  TextHeight = 13
  object lblHeader: TLabel
    Left = 16
    Top = 24
    Width = 224
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Header'
    ExplicitWidth = 257
  end
  object lblInfo: TLabel
    Left = 16
    Top = 56
    Width = 224
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Info'
    ExplicitWidth = 257
  end
  object lblReadInfos: TLabel
    Left = 16
    Top = 85
    Width = 224
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Read some infos'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = lblReadInfosClick
    ExplicitWidth = 257
  end
  object btnOK: TButton
    Left = 177
    Top = 112
    Width = 72
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    TabOrder = 0
    OnClick = btnOKClick
    ExplicitLeft = 187
  end
end
