{
    This file is part of the CustomLineNumbers plugin for Notepad++
    Author: Andreas Heim

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3 as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit dialog_TfrmSettings;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.IOUtils,
  System.Math, System.Types, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Samples.Spin, Vcl.Forms, Vcl.Dialogs,

  NppSupport, NppMenuCmdID, NppPlugin, NppPluginForms,

  DataModule;


type
  TfrmSettings = class(TNppPluginForm)

    chkHexLineNumbers: TCheckBox;

    lblLineNumberOffset: TLabel;
    spnLineNumberOffset: TSpinEdit;

    btnClose: TButton;

    procedure FormCreate(Sender: TObject);

    procedure chkHexLineNumbersClick(Sender: TObject);
    procedure spnLineNumberOffsetChange(Sender: TObject);

    procedure btnCloseClick(Sender: TObject);

  private
    FSettings: TSettings;

    procedure   LoadSettings(const AFilePath: string);

  public
    constructor Create(NppParent: TNppPlugin); override;
    destructor  Destroy; override;

    procedure   InitLanguage; override;

  end;


var
  frmSettings: TfrmSettings;



implementation

{$R *.dfm}


const
  TXT_CAPTION_CHK_HEXNUMBERS: string = 'Line numbers as hex numbers';
  TXT_CAPTION_SPN_OFFSET:     string = 'Line numbers start at';
  TXT_CAPTION_BTN_CLOSE:      string = 'Close';


// =============================================================================
// Class TfrmSettings
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TfrmSettings.Create(NppParent: TNppPlugin);
begin
  inherited;

  DefaultCloseAction := caHide;
end;


destructor TfrmSettings.Destroy;
begin
  FSettings.Free;

  inherited;
  frmSettings := nil;
end;


// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

// Perform basic initialization tasks
procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  Caption := Plugin.GetName;

  InitLanguage;
  LoadSettings(TSettings.FilePath);
end;


// Set caption of GUI controls
procedure TfrmSettings.InitLanguage;
begin
  inherited;

  chkHexLineNumbers.Caption   := TXT_CAPTION_CHK_HEXNUMBERS;
  lblLineNumberOffset.Caption := TXT_CAPTION_SPN_OFFSET;
  btnClose.Caption            := TXT_CAPTION_BTN_CLOSE;
end;


// Load settings from disk file
procedure TfrmSettings.LoadSettings(const AFilePath: string);
begin
  FSettings := TSettings.Create(AFilePath);

  chkHexLineNumbers.Checked := FSettings.LineNumbersAsHex;
  spnLineNumberOffset.Value := FSettings.LineNumbersOffset;
end;


// -----------------------------------------------------------------------------
// Event handlers
// -----------------------------------------------------------------------------

// Store new values from GUI to settings data model
procedure TfrmSettings.chkHexLineNumbersClick(Sender: TObject);
begin
  FSettings.LineNumbersAsHex := chkHexLineNumbers.Checked;
end;


procedure TfrmSettings.spnLineNumberOffsetChange(Sender: TObject);
begin
  FSettings.LineNumbersOffset := spnLineNumberOffset.Value;
end;


// Close dialog
procedure TfrmSettings.btnCloseClick(Sender: TObject);
begin
  Close;
end;


end.

