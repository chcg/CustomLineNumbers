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

unit Main;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.DateUtils,
  System.IOUtils, System.Math, System.Types, System.Classes, System.Generics.Defaults,
  System.Generics.Collections,

  SciSupport, NppSupport, NppPlugin, NppPluginForms, NppPluginDockingForms,

  DataModule,

  dialog_TfrmSettings,
  dialog_TfrmAbout;


type
  // Plugin class
  TCustomLineNumbersPlugin = class(TNppPlugin)
  private type
    TBufferCatalog = TDictionary<integer, string>;

  private
    FSettings: TSettings;
    FBuffers:  TBufferCatalog;

    // Functions to handle Notepad++ document actions
    procedure   CheckBufferChanges;
    procedure   RemoveCurrentBufferFromCatalog;
    procedure   RemoveAllBuffersFromCatalog;

    // Function to write line numbers
    procedure   UpdateLineNumbers(StartLineNumber: integer); overload;

    // Getter/Setter
    function    GetEnabled: boolean;
    procedure   SetEnabled(Value: boolean);

  protected
    // Handler for certain Notepad++ events
    procedure   DoNppnReady; override;
    procedure   DoNppnBufferActivated; override;
    procedure   DoNppnFileBeforeClose; override;

    // Handler for certain Scintilla events
    procedure   DoScnnInsertText(LineNumber: integer); override;
    procedure   DoScnnDeleteText(LineNumber: integer); override;

  public
    constructor Create; override;
    destructor  Destroy; override;

    // Access to basic plugin functions
    procedure   LoadSettings();
    procedure   UnloadSettings();

    procedure   UpdateCurBuffer();
    procedure   Activate();

    property    Enabled: boolean read GetEnabled write SetEnabled;

  end;


var
  // Class type to create in startup code
  PluginClass: TNppPluginClass = TCustomLineNumbersPlugin;

  // Plugin instance variable, this is the reference to use in plugin's code
  Plugin: TCustomLineNumbersPlugin;



implementation

const
  // Plugin name
  TXT_PLUGIN_NAME:       string = 'CustomLineNumbers';

  TXT_MENUITEM_ACTIVE:   string = 'Active';
  TXT_MENUITEM_SETTINGS: string = 'Settings';
  TXT_MENUITEM_ABOUT:    string = 'About';

  IDX_MENUITEM_ACTIVE           = 0;
  IDX_MENUITEM_SETTINGS         = 1;
  IDX_MENUITEM_ABOUT            = 2;


// Functions associated to the plugin's Notepad++ menu entries
procedure ActivatePlugin; cdecl; forward;
procedure ShowSettings; cdecl; forward;
procedure ShowAbout; cdecl; forward;


// =============================================================================
// Class TCustomLineNumbersPlugin
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TCustomLineNumbersPlugin.Create;
begin
  inherited Create;

  // Store a reference to the instance in a global variable with an appropriate
  // type to get access to its properties and methods
  Plugin := Self;

  // This property is important to extract version infos from the DLL file,
  // so set it right now after creation of the object
  PluginName := TXT_PLUGIN_NAME;

  // Add plugins's menu entries to Notepad++
  AddFuncItem(TXT_MENUITEM_ACTIVE,   ActivatePlugin);
//  AddFuncItem(TXT_MENUITEM_SETTINGS, ShowSettings);
  AddFuncItem(TXT_MENUITEM_ABOUT,    ShowAbout);

  FBuffers := TBufferCatalog.Create;
end;


destructor TCustomLineNumbersPlugin.Destroy;
begin
  // Cleanup
  RemoveAllBuffersFromCatalog();
  UnloadSettings();

  // It's totally legal to call Free on already freed instances,
  // no checks needed
  frmAbout.Free;
  frmSettings.Free;

  inherited;
end;


// -----------------------------------------------------------------------------
// (De-)Initialization
// -----------------------------------------------------------------------------

// Read settings file
procedure TCustomLineNumbersPlugin.LoadSettings;
begin
  FSettings := TSettings.Create(TSettings.FilePath);
end;


// Free settings data model
procedure TCustomLineNumbersPlugin.UnloadSettings;
begin
  FreeAndNil(FSettings);
end;


// Emulate the activation of a document's tab in Notepad++
procedure TCustomLineNumbersPlugin.UpdateCurBuffer;
begin
  DoNppnBufferActivated();
end;


// Switch margin type according to plugin's activation state
procedure TCustomLineNumbersPlugin.Activate;
begin
  FSettings.Enabled := Enabled;

  if Enabled then
  begin
    SendMessage(NppData.ScintillaMainHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_RTEXT));
    SendMessage(NppData.ScintillaSecondHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_RTEXT));
    UpdateCurBuffer();
  end
  else
  begin
    SendMessage(NppData.ScintillaMainHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_NUMBER));
    SendMessage(NppData.ScintillaSecondHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_NUMBER));
    RemoveAllBuffersFromCatalog();
  end;
end;


// -----------------------------------------------------------------------------
// Getter/Setter
// -----------------------------------------------------------------------------

function TCustomLineNumbersPlugin.GetEnabled: boolean;
begin
  if Assigned(FSettings) then
    Result := FSettings.Enabled
  else
    Result := false;
end;


procedure TCustomLineNumbersPlugin.SetEnabled(Value: boolean);
begin
  if Assigned(FSettings) then
    FSettings.Enabled := Value;
end;


// -----------------------------------------------------------------------------
// Event handler
// -----------------------------------------------------------------------------

// Called after Notepad++ has started and is ready for work
procedure TCustomLineNumbersPlugin.DoNppnReady;
begin
  inherited;

  // Load settings and apply them to the active document
  LoadSettings();
  ActivatePlugin();
end;


// Called after activating the tab of a file
procedure TCustomLineNumbersPlugin.DoNppnBufferActivated;
begin
  if not Enabled then exit;
  CheckBufferChanges();
end;


// Called just before a file and its tab is closed
procedure TCustomLineNumbersPlugin.DoNppnFileBeforeClose;
begin
  RemoveCurrentBufferFromCatalog();
end;


// Called after a line of text has been inserted into the current document
procedure TCustomLineNumbersPlugin.DoScnnInsertText(LineNumber: integer);
begin
  if not Enabled then exit;

  if SCNotification.linesAdded <> 0 then
    UpdateLineNumbers(LineNumber);
end;


// Called after a line of text has been deleted from the current document
procedure TCustomLineNumbersPlugin.DoScnnDeleteText(LineNumber: integer);
begin
  if not Enabled then exit;

  if SCNotification.linesAdded <> 0 then
    UpdateLineNumbers(LineNumber);
end;


// -----------------------------------------------------------------------------
// Worker methods
// -----------------------------------------------------------------------------

// Init line numbers of current text buffer
procedure TCustomLineNumbersPlugin.CheckBufferChanges;
var
  CurBufferId:       integer;
  CurBufferFileName: string;

begin
  CurBufferId       := GetCurrentBufferId();
  CurBufferFileName := GetFullPathFromBufferId(CurBufferId);

  // Only init line numbers if it hasn't been done already
  if not FBuffers.ContainsKey(CurBufferId)                            or
     not SameFileName(FBuffers.Items[CurBufferId], CurBufferFileName) then
  begin
    // Remember buffer ID
    FBuffers.AddOrSetValue(CurBufferId, CurBufferFileName);

    // Init line numbers
    UpdateLineNumbers(0);
  end;
end;


// Delete reference to current text buffer
procedure TCustomLineNumbersPlugin.RemoveCurrentBufferFromCatalog;
begin
  FBuffers.Remove(GetCurrentBufferId());
end;


// Delete references to all text buffers
procedure TCustomLineNumbersPlugin.RemoveAllBuffersFromCatalog;
begin
  FBuffers.Clear;
end;


// Write line numbers to line number margin
procedure TCustomLineNumbersPlugin.UpdateLineNumbers(StartLineNumber: integer);
var
  ViewIdx:        integer;
  StopLineNumber: integer;
  Idx:            integer;
  Number:         string;

begin
  ViewIdx        := GetCurrentView();
  StopLineNumber := GetLineCount();

  for Idx := StartLineNumber to Pred(StopLineNumber) do
  begin
    Number := Format('%.2x', [Idx]);

    case ViewIdx of
      MAIN_VIEW:
      begin
        SendMessage(NppData.ScintillaMainHandle, SCI_MARGINSETSTYLE, WPARAM(Idx), LPARAM(STYLE_LINENUMBER));
        SendMessage(NppData.ScintillaMainHandle, SCI_MARGINSETTEXT, WPARAM(Idx), LPARAM(sciBString(Number)));
      end;

      SUB_VIEW:
      begin
        SendMessage(NppData.ScintillaSecondHandle, SCI_MARGINSETSTYLE, WPARAM(Idx), LPARAM(STYLE_LINENUMBER));
        SendMessage(NppData.ScintillaSecondHandle, SCI_MARGINSETTEXT, WPARAM(Idx), LPARAM(sciBString(Number)));
      end;
    end;
  end;
end;



// -----------------------------------------------------------------------------
// Plugin menu items
// -----------------------------------------------------------------------------

// (De)-Activate Plugin
procedure ActivatePlugin; cdecl;
begin
  Plugin.Enabled := not Plugin.Enabled;

  Plugin.CheckMenuEntry(IDX_MENUITEM_ACTIVE, Plugin.Enabled);
  Plugin.Activate();
end;


// Show "Settings" dialog in Notepad++
procedure ShowSettings; cdecl;
begin
  if not Assigned(frmSettings) then
  begin
    // Before opening the settings dialog discard own settings object
    Plugin.UnloadSettings();

    // Show settings dialog in a modal state and destroy it after close
    frmSettings := TfrmSettings.Create(Plugin);
    frmSettings.ShowModal;
    frmSettings.Free;

    // Load maybe updated settings and apply it to the active Notepad++ document
    Plugin.LoadSettings();
    Plugin.RemoveAllBuffersFromCatalog();
    Plugin.UpdateCurBuffer();
  end;
end;


// Show "About" dialog in Notepad++
procedure ShowAbout; cdecl;
begin
  if not Assigned(frmAbout) then
  begin
    // Show about dialog in a modal state and destroy it after close
    frmAbout := TfrmAbout.Create(Plugin);
    frmAbout.ShowModal;
    frmAbout.Free;
  end;
end;


end.
