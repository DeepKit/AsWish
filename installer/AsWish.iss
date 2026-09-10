; ============================================================================
;  AsWish installer (Inno Setup 6)
;  Packages bin\AsWish.exe (+ CLI if built). Declares WebView2 Runtime
;  dependency by guiding the user to the official evergreen bootstrapper
;  download page instead of bundling the installer (license reasons).
;
;  Build: run _build_installer.bat (needs ISCC.exe from jrsoftware.org)
; ============================================================================

#define MyAppName "AsWish"
#define MyAppVersion "0.1.0.0"
#define MyAppPublisher "BetterCiv Contributors"
#define MyAppExeName "AsWish.exe"

[Setup]
AppId={{7E1F5D9A-6B34-4C2E-9A18-5E2A50010001}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
DisableProgramGroupPage=yes
OutputDir=..\bin\installer
OutputBaseFilename=AsWish-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; \
    GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\bin\AsWish.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\WebView2Loader.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\cli\bin\AsWish.CLI.exe"; DestDir: "{app}\tools"; \
    Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; \
    Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; \
    Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Intentionally empty: user project data (.AsWish workspaces, settings)
; must survive uninstall. Only files we installed under {app} are removed.

[Code]
// WebView2 Runtime official fixed GUID (Evergreen):
// HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
// The 'pv' value holds the runtime version when installed.
const
  WebView2Guid = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
  WebView2Url = 'https://developer.microsoft.com/microsoft-edge/webview2/';

function WebView2Installed(): Boolean;
var
  Pv: String;
begin
  Result :=
    (RegQueryStringValue(HKLM,
       'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\' + WebView2Guid,
       'pv', Pv) and (Pv <> '')) or
    (RegQueryStringValue(HKCU,
       'Software\Microsoft\EdgeUpdate\Clients\' + WebView2Guid,
       'pv', Pv) and (Pv <> ''));
end;

function InitializeSetup(): Boolean;
var
  ErrorCode: Integer;
begin
  Result := True;
  if not WebView2Installed() then
  begin
    if MsgBox(
        'AsWish embeds web-based review pages rendered by Microsoft Edge WebView2.' #13#10 +
        'The WebView2 Runtime was not detected on this machine.' #13#10 #13#10 +
        'Yes  - open the official download page (recommended, then re-run Setup)' #13#10 +
        'No   - continue installing without WebView2 (review pages will not render)',
        mbConfirmation, MB_YESNO) = IDYES then
      ShellExec('open', WebView2Url, '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
    // Always proceed with installation either way; the app itself starts
    // fine and only the embedded review browser requires the runtime.
  end;
end;
