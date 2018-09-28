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

library CustomLineNumbers;


uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,

  NppPlugin in 'Lib\NppPlugin.pas',
  NppPluginForms in 'Lib\NppPluginForms.pas' {NppPluginForm},
  NppPluginDockingForms in 'Lib\NppPluginDockingForms.pas' {NppPluginDockingForm},
  NppSupport in 'Lib\NppSupport.pas',
  NppMenuCmdID in 'Lib\NppMenuCmdID.pas',
  SciSupport in 'Lib\SciSupport.pas',

  Main in 'Main.pas',
  DataModule in 'DataModule.pas',
  FileVersionInfo in 'FileVersionInfo.pas',

  dialog_TfrmAbout in 'dialog_TfrmAbout.pas' {frmAbout},
  dialog_TfrmSettings in 'dialog_TfrmSettings.pas' {frmSettings};

{$R *.res}

var
  // For global management of plugin instance
  BasePlugin: TNppPlugin;


{$Include 'Lib\NppPluginInclude.pas'}


begin
  // Propagate DLL entry point to RTL
  DLLProc := @DLLEntryPoint;

  // Create plugin instance
  DLLEntryPoint(DLL_PROCESS_ATTACH);
end.

