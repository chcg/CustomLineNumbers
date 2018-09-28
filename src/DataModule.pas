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

unit DataModule;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.DateUtils,
  System.IOUtils, System.Math, System.Types, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.IniFiles,

  NppSupport, NppMenuCmdID, NppPlugin;


type
  // Abstraction of the settings file
  TSettings = class(TObject)
  strict private
    FIniFile:      TIniFile;
    FValid:        boolean;
    FEnabled:      boolean;

    class function GetFilePath: string; static;

    procedure   LoadSettings;
    procedure   SaveSettings;

  public
    constructor Create(const AFilePath: string);
    destructor  Destroy; override;

    // Class properties
    class property FilePath: string  read GetFilePath;

    // Common properties
    property    Valid:       boolean read FValid;
    property    Enabled:     boolean read FEnabled write FEnabled;

  end;



implementation

uses
  Main;


const
  // Data for INI file section "Header"
  SECTION_HEADER:            string = 'Header';
  KEY_VERSION:               string = 'Version';
  VALUE_VERSION:             string = '1.0';

  // Data for INI file section "Settings"
  SECTION_SETTINGS:          string = 'Settings';
  KEY_SETTINGS_ENABLED_NAME: string = 'enabled';


// =============================================================================
// Class TSettings
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TSettings.Create(const AFilePath: string);
begin
  inherited Create;

  FValid   := false;
  FIniFile := TIniFile.Create(AFilePath);

  LoadSettings;
end;


destructor TSettings.Destroy;
begin
  // Settings are saved to disk at instance destruction
  SaveSettings;

  FIniFile.Free;

  inherited;
end;


// -----------------------------------------------------------------------------
// Getter / Setter
// -----------------------------------------------------------------------------

// Get path of settings file
class function TSettings.GetFilePath: string;
begin
  Result := TPath.Combine(Plugin.GetPluginsConfigDir, ReplaceStr(Plugin.GetName, ' ', '') + '.ini');
end;


// -----------------------------------------------------------------------------
// I/O methods
// -----------------------------------------------------------------------------

// Parse settings file and store its content in a data model
procedure TSettings.LoadSettings;
var
  Header:   TStringList;
  Settings: TStringList;

begin
  Header               := TStringList.Create;
  Header.Sorted        := false;
  Header.CaseSensitive := false;
  Header.Duplicates    := dupIgnore;
  Header.Delimiter     := ';';

  try
    // Skip header checking if the settings file doesn't exist
    if FileExists(FIniFile.FileName) then
    begin
      // In future versions of the plugin here we could call an update function
      // for the settings file of older plugin versions
      FIniFile.ReadSectionValues(SECTION_HEADER, Header);
      if not SameText(Header.Values[KEY_VERSION], VALUE_VERSION) then exit;
    end;

    Settings               := TStringList.Create;
    Settings.Sorted        := false;
    Settings.CaseSensitive := false;
    Settings.Duplicates    := dupIgnore;
    Settings.Delimiter     := ';';

    try
      // Retrieve settings data...
      FIniFile.ReadSectionValues(SECTION_SETTINGS, Settings);

      // ...and transfer it to the datamodel
      if Settings.IndexOfName(KEY_SETTINGS_ENABLED_NAME) >= 0 then
        FEnabled := not StrToBool(Settings.Values[KEY_SETTINGS_ENABLED_NAME])
      else
        FEnabled := false;

      // If we reached this point we can mark settings as valid
      FValid := true;

    finally
      Settings.Free;
    end;

  finally
    Header.Free;
  end;
end;


// Save settings data model to a disk file
procedure TSettings.SaveSettings;
var
  Settings: TStringList;
  Cnt:      integer;

begin
  if not FValid then exit;

  // Clear whole settings file
  Settings := TStringList.Create;

  try
    FIniFile.ReadSections(Settings);

    for Cnt := 0 to Pred(Settings.Count) do
      FIniFile.EraseSection(Settings[Cnt]);

  finally
    Settings.Free;
  end;

  // Write Header
  FIniFile.WriteString(SECTION_HEADER, KEY_VERSION, VALUE_VERSION);

  // Write settings data
  FIniFile.WriteString(SECTION_SETTINGS, KEY_SETTINGS_ENABLED_NAME, BoolToStr(FEnabled, true));
end;


end.
