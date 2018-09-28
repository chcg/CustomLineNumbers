object frmSettings: TfrmSettings
  Left = 300
  Top = 190
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  ClientHeight = 425
  ClientWidth = 418
  Color = clBtnFace
  Constraints.MinHeight = 461
  Constraints.MinWidth = 434
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
    418
    425)
  PixelsPerInch = 96
  TextHeight = 13
  object btnClose: TButton
    Left = 314
    Top = 392
    Width = 95
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    TabOrder = 0
    OnClick = btnCloseClick
  end
end
