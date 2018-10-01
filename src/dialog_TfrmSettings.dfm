object frmSettings: TfrmSettings
  Left = 300
  Top = 190
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  ClientHeight = 121
  ClientWidth = 227
  Color = clBtnFace
  Constraints.MinHeight = 157
  Constraints.MinWidth = 243
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
    227
    121)
  PixelsPerInch = 96
  TextHeight = 13
  object lblLineNumberOffset: TLabel
    Left = 16
    Top = 48
    Width = 137
    Height = 13
    AutoSize = False
    Caption = 'Line numbers start at'
  end
  object btnClose: TButton
    Left = 123
    Top = 88
    Width = 95
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    Default = True
    TabOrder = 2
    OnClick = btnCloseClick
  end
  object chkHexLineNumbers: TCheckBox
    Left = 16
    Top = 16
    Width = 201
    Height = 17
    Alignment = taLeftJustify
    Caption = 'Line numbers as  hex numbers'
    TabOrder = 0
    OnClick = chkHexLineNumbersClick
  end
  object spnLineNumberOffset: TSpinEdit
    Left = 173
    Top = 45
    Width = 44
    Height = 22
    AutoSize = False
    Ctl3D = True
    MaxValue = 2147483647
    MinValue = 0
    ParentCtl3D = False
    TabOrder = 1
    Value = 0
    OnChange = spnLineNumberOffsetChange
  end
end
