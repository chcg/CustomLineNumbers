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
    FSettings:    TSettings;
    FBuffers:     TBufferCatalog;
    FBlockEvents: boolean;

    // Functions to handle Notepad++ document actions
    procedure   CheckBufferChanges; overload;
    procedure   CheckBufferChanges(ViewIdx, BufferId: integer); overload;
    procedure   CheckTextChanges;
    procedure   ApplyFileChanges;
    procedure   RemoveCurrentBufferFromCatalog;
    procedure   RemoveAllBuffersFromCatalog;

    // Function to write line numbers
    procedure   UpdateLineNumbers(ViewIdx, StartLineNumber: integer); overload;

    // Getter/Setter
    function    GetEnabled: boolean;
    procedure   SetEnabled(Value: boolean);

  protected
    // Handler for certain Notepad++ events
    procedure   DoNppnReady; override;
    procedure   DoNppnFileBeforeLoad; override;
    procedure   DoNppnFileLoadFailed; override;
    procedure   DoNppnFileOpened; override;
    procedure   DoNppnFileBeforeClose; override;
    procedure   DoNppnBufferActivated; override;
    procedure   DoNppnFileRenamed; override;
    procedure   DoNppnShutdown; override;

    // Handler for certain Scintilla events
    procedure   DoScnnInsertText; override;
    procedure   DoScnnDeleteText; override;

  public
    constructor Create; override;
    destructor  Destroy; override;

    // Access to basic plugin functions
    procedure   LoadSettings();
    procedure   UnloadSettings();

    procedure   UpdateAllViews();
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

// The process of displaying custom line numbers is time consuming, especially
// when working with large files with 10000 lines or more (depends on the hard-
// ware Notepad++ runs on).
//
// The function should be called in the following cases:
//   * After startup of Notepad++ has been finished, depending on plugin's acti-
//     vation status loaded from the settings file.
//   * A file is loaded into Notepad++ to the main or the second view.
//   * A line is added to a document displayed in the main or the second view.
//   * A line is deleted from a document displayed in the main or the second view.
//   * A document is moved or cloned from one view to the other.
//   * A file is opened in a buffer whose file already has been closed, the
//     buffer gets reused for the new file and its ID remains the same.
//   * The plugin's settings are changed, the active documents of both views
//     have to be processed.
//   * The plugin is activated, the active documents of both views have to be
//     processed.
//   * A document's tab is activated or becomes visible after the plugin has
//     been reactivated.
//
// The function should NOT be called in the following cases:
//   * An unchanged document's tab is activated or becomes visible.
//   * A document is renamed (the content remains the same).
//   * During loading a file (ignore "line added" events).
//   * During exiting Notepad++.
//
// To prevent the function for custom line numbering to be called though it's
// not neccessary we need to do some bookkeeping. Already processed documents
// are stored in a dictionary as key-value pairs with the buffer ID as the key
// and the full path to the document as the value. If a document is found in
// the dictionary the function for custom line numbering is not called. Only
// "line added" and "line deleted" events are processed always (except the
// plugin is deactivated or Notepad++ is in state "loading a file").


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
  AddFuncItem(TXT_MENUITEM_SETTINGS, ShowSettings);
  AddFuncItem(TXT_MENUITEM_ABOUT,    ShowAbout);

  FBuffers     := TBufferCatalog.Create;
  FBlockEvents := false;
end;


destructor TCustomLineNumbersPlugin.Destroy;
begin
  // Cleanup
  FBuffers.Free;

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

  // Invert enabled status read from settings because
  // in ActivatePlugin it will be inverted again
  FSettings.Enabled := not FSettings.Enabled;
end;


// Free settings data model
procedure TCustomLineNumbersPlugin.UnloadSettings;
begin
  FreeAndNil(FSettings);
end;


// Update active document of all views
procedure TCustomLineNumbersPlugin.UpdateAllViews;
begin
  if not Enabled then exit;

  CheckBufferChanges();
end;


// Switch margin type according to plugin's activation state
procedure TCustomLineNumbersPlugin.Activate;
begin
  if Enabled then
  begin
    // Set type of margin 0 to right-aligned text
    SendMessage(NppData.ScintillaMainHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_RTEXT));
    SendMessage(NppData.ScintillaSecondHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_RTEXT));

    // Apply setting to the active document of all views
    UpdateAllViews();
  end
  else
  begin
    // Set type of margin 0 to line numbers
    SendMessage(NppData.ScintillaMainHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_NUMBER));
    SendMessage(NppData.ScintillaSecondHandle, SCI_SETMARGINTYPEN, WPARAM(0), LPARAM(SC_MARGIN_NUMBER));

    // Clear catalog of already processed documents
    RemoveAllBuffersFromCatalog();
  end;
end;


// -----------------------------------------------------------------------------
// Getter/Setter
// -----------------------------------------------------------------------------

// Read Enabled status from settings data model
function TCustomLineNumbersPlugin.GetEnabled: boolean;
begin
  if Assigned(FSettings) then
    Result := FSettings.Enabled
  else
    Result := false;
end;


// Write Enabled status to settings data model
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

  // Load settings and apply them to the active document of all views
  LoadSettings();
  ActivatePlugin();
end;


// Called before a file is loaded
procedure TCustomLineNumbersPlugin.DoNppnFileBeforeLoad;
begin
  if not Enabled then exit;

  FBlockEvents := true;
end;


// Called after a file load operation has failed
procedure TCustomLineNumbersPlugin.DoNppnFileLoadFailed;
begin
  if not Enabled then exit;

  FBlockEvents := false;
end;


// Called after a file is opened
procedure TCustomLineNumbersPlugin.DoNppnFileOpened;
begin
  if not Enabled then exit;

  FBlockEvents := false;
end;


// Called before a file and its tab is closed
procedure TCustomLineNumbersPlugin.DoNppnFileBeforeClose;
begin
  if not Enabled  then exit;
  if FBlockEvents then exit;

  RemoveCurrentBufferFromCatalog();
end;


// Called after activating the tab of a file
procedure TCustomLineNumbersPlugin.DoNppnBufferActivated;
var
  NotUsed: integer;
  ViewIdx: integer;

begin
  if not Enabled  then exit;
  if FBlockEvents then exit;

  ViewIdx := GetPosFromBufferId(SCNotification.nmhdr.idFrom, NotUsed);
  CheckBufferChanges(ViewIdx, SCNotification.nmhdr.idFrom);
end;


// Called after a file is renamed
procedure TCustomLineNumbersPlugin.DoNppnFileRenamed;
begin
  if not Enabled  then exit;
  if FBlockEvents then exit;

  ApplyFileChanges();
end;


// Called before Notepad++ shuts down
procedure TCustomLineNumbersPlugin.DoNppnShutdown;
begin
  FBlockEvents := true;
end;


// Called after a line of text has been inserted into the current document
procedure TCustomLineNumbersPlugin.DoScnnInsertText;
begin
  if not Enabled  then exit;
  if FBlockEvents then exit;

  CheckTextChanges();
end;


// Called after a line of text has been deleted from the current document
procedure TCustomLineNumbersPlugin.DoScnnDeleteText;
begin
  if not Enabled  then exit;
  if FBlockEvents then exit;

  CheckTextChanges();
end;


// -----------------------------------------------------------------------------
// Worker methods
// -----------------------------------------------------------------------------

// Init line numbers of current text buffer in all views
procedure TCustomLineNumbersPlugin.CheckBufferChanges;
var
  CurViewIdx:  integer;
  CurDocIdx:   integer;
  CurBufferId: integer;

begin
  // Iterate over both main and sub view
  for CurViewIdx := MAIN_VIEW to SUB_VIEW do
  begin
    // Retrieve index of active document in current view
    CurDocIdx := GetCurrentDocIndex(CurViewIdx);

    // If view is visible...
    if CurDocIdx <> -1 then
    begin
      // ...retrieve text buffer ID of active document
      // and init line numbers if neccessary
      CurBufferId := GetBufferIdFromPos(CurViewIdx, CurDocIdx);
      CheckBufferChanges(CurViewIdx, CurBufferId);
    end;
  end;
end;


// Init line numbers of a certain text buffer
procedure TCustomLineNumbersPlugin.CheckBufferChanges(ViewIdx, BufferId: integer);
var
  FileName: string;

begin
  // Retrieve file name of document opened in text buffer
  FileName := GetFullPathFromBufferId(BufferId);

  // Only init line numbers if it hasn't been done already
  if not FBuffers.ContainsKey(BufferId)             or
     not SameFileName(FBuffers[BufferId], FileName) then
  begin
    // Remember text buffer ID and its related file name
    FBuffers.AddOrSetValue(BufferId, FileName);

    // Init line numbers
    UpdateLineNumbers(ViewIdx, 0);
  end;
end;


// Init line numbers of a certain text buffer after text changes
procedure TCustomLineNumbersPlugin.CheckTextChanges;
var
  ViewIdx: integer;

begin
  if SCNotification.linesAdded <> 0 then
  begin
    ViewIdx := GetCurrentViewIdx();
    UpdateLineNumbers(ViewIdx, GetLineFromPosition(ViewIdx, SCNotification.position));
  end;
end;


// Change related file name of current text buffer
procedure TCustomLineNumbersPlugin.ApplyFileChanges;
var
  BufferId: integer;

begin
  // Get current buffer ID
  BufferId := GetCurrentBufferId();

  // If catalog contains buffer id change related file name
  if FBuffers.ContainsKey(BufferId) then
    FBuffers.AddOrSetValue(BufferId, GetFullPathFromBufferId(BufferId));
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
procedure TCustomLineNumbersPlugin.UpdateLineNumbers(ViewIdx, StartLineNumber: integer);
var
  StopLineNumber: integer;
  FormatString:   string;
  Idx:            integer;
  Number:         string;

begin
  StopLineNumber := GetLineCount(ViewIdx);

  if FSettings.LineNumbersAsHex then
    FormatString := '%.2x'
  else
    FormatString := '%d';

  for Idx := StartLineNumber to Pred(StopLineNumber) do
  begin
    Number := Format(FormatString, [Idx + FSettings.LineNumbersOffset]);

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



// =============================================================================
// Plugin menu items
// =============================================================================

// (De)-Activate Plugin
procedure ActivatePlugin; cdecl;
begin
  Plugin.Enabled := not Plugin.Enabled;

  Plugin.CheckMenuItem(IDX_MENUITEM_ACTIVE, Plugin.Enabled);
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

    // Load maybe updated settings...
    Plugin.LoadSettings();
    Plugin.RemoveAllBuffersFromCatalog();

    // ...and apply it to active Notepad++ document
    ActivatePlugin();
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
