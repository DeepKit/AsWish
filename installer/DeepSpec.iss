; ============================================================================
; DeepSpec installer (Inno Setup 6)
;
; Build:  ISCC.exe installer\DeepSpec.iss
; Prereq: bin\DeepSpec.exe built via _build.bat (run it first).
;
; Notes:
;   - WebView2 Runtime is NOT bundled; the installer checks and points the
;     user to the Evergreen bootstrapper (Microsoft requires the runtime to
;     be installed separately; see WebView2 distribution docs).
;   - root.txt is created on first run? No — DeepBase requires root.txt next
;     to the EXE; we ship a template and ask the user to point it at their
;     DeepBase project root after install.
; ============================================================================

#define MyAppName "DeepSpec"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "DeepKit"
#define MyAppExeName "DeepSpec.exe"

[Setup]
AppId={{8E1D8C4E-5F0A-4B7E-9C2D-DeepSpec01}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
OutputDir=..\dist
OutputBaseFilename=DeepSpec-setup-{#MyAppVersion}
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\bin\DeepSpec.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\root.txt.example"; DestDir: "{app}"; DestName: "root.txt"; Flags: onlyifdoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function WebView2Installed: Boolean;
var
  Key: string;
begin
  Result := RegKeyExists(HKLM,
    'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and (not WebView2Installed) then
    MsgBox('WebView2 Runtime 未安装。DeepSpec 的主视图（HTML 审阅页）需要它。' + #13#10 +
      '请从 https://developer.microsoft.com/microsoft-edge/webview2/ 安装 Evergreen Runtime 后重启 DeepSpec。',
      mbInformation, MB_OK);
end;
