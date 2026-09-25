
{ ============================================================================
  AsWish.Services.Scan

  File scanner: recursively scans project directory, classifies files
  according to protocol §14.1 priority rules, generates scan-report.yaml.
  ============================================================================ }

unit AsWish.Services.Scan;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TFileCategory = (
    fcIgnored,
    fcAiRules,
    fcDocuments,
    fcUI,
    fcCode,
    fcConfig,
    fcUnknown
  );

  TScanResult = record
    Category: TFileCategory;
    RelativePath: string;
  end;

  TAsWishScanService = class(TInterfacedObject)
  private
    FResults: TList<TScanResult>;
    function ClassifyFile(const ARelPath, AFileName: string): TFileCategory;
    function IsIgnoredDir(const ADirName: string): Boolean;
    function IsAiRulesFile(const ARelPath, AFileName: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ScanDirectory(const ARootPath: string);
    function GetFilesByCategory(ACategory: TFileCategory): TArray<string>;
    function TotalFiles: Integer;
    function CategoryCount(ACategory: TFileCategory): Integer;
    /// <summary>Name the stack this project is written in, from the files the
    ///  scan already classified. There is exactly one implementation because
    ///  there were two: the CLI reported "mixed" for code it could not name,
    ///  the desktop app reported "unknown", so the same repository got a
    ///  different recorded type depending on which entry point scanned it.
    ///  The value is metadata only -- displayed and written into project.yaml,
    ///  nothing branches on it -- but a project's own type must not depend on
    ///  which door you walked in through.</summary>
    function DetectProjectType: string;
    property Results: TList<TScanResult> read FResults;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils;

const
  IGNORED_DIRS: array[0..15] of string = (
    'node_modules', '.git', '.svn', '.hg', '__pycache__',
    '.pytest_cache', 'build', 'bin', 'dist', 'out',
    'target', 'debug', 'release', '__history', '.next',
    '.aswish'
  );

  AI_RULES_FILES: array[0..4] of string = (
    'claude.md', 'agents.md', '.cursorrules',
    'cursor-rules.md', '.windsurfrules'
  );

  DOC_EXTS: array[0..6] of string = (
    '.md', '.txt', '.rst', '.doc', '.docx', '.pdf', '.adoc'
  );

  UI_EXTS: array[0..10] of string = (
    '.dfm', '.fmx', '.html', '.htm', '.vue', '.jsx',
    '.tsx', '.svelte', '.astro', '.xaml', '.qml'
  );

  CODE_EXTS: array[0..17] of string = (
    '.pas', '.dpr', '.inc', '.py', '.ts', '.js', '.java',
    '.cs', '.go', '.rs', '.rb', '.php', '.swift', '.kt',
    '.c', '.cpp', '.h', '.hpp'
  );

  CONFIG_EXTS: array[0..11] of string = (
    '.yaml', '.yml', '.json', '.toml', '.ini', '.xml',
    '.env', '.properties', '.dproj', '.dpk', '.sln', '.csproj'
  );

constructor TAsWishScanService.Create;
begin
  inherited Create;
  FResults := TList<TScanResult>.Create;
end;

destructor TAsWishScanService.Destroy;
begin
  FResults.Free;
  inherited;
end;

function TAsWishScanService.IsIgnoredDir(const ADirName: string): Boolean;
begin
  for var LDir in IGNORED_DIRS do
    if SameText(ADirName, LDir) then
      Exit(True);
  Result := False;
end;

function TAsWishScanService.IsAiRulesFile(const ARelPath, AFileName: string): Boolean;
begin
  var LLower := LowerCase(AFileName);
  for var LName in AI_RULES_FILES do
    if LLower = LName then
      Exit(True);

  // Path-based rules
  var LRelLower := LowerCase(ARelPath);
  if LRelLower.Contains('.kiro/steering/') then
    Exit(True);
  if LRelLower.Contains('.github/copilot-instructions.md') then
    Exit(True);

  Result := False;
end;

function TAsWishScanService.ClassifyFile(const ARelPath, AFileName: string): TFileCategory;
begin
  var LExt := LowerCase(TPath.GetExtension(AFileName));

  // Priority 1: AI rules
  if IsAiRulesFile(ARelPath, AFileName) then
    Exit(fcAiRules);

  // Priority 2: Documents
  for var LDocExt in DOC_EXTS do
    if LExt = LDocExt then
      Exit(fcDocuments);

  // Priority 3: UI
  for var LUIExt in UI_EXTS do
    if LExt = LUIExt then
      Exit(fcUI);

  // Priority 4: Code
  for var LCodeExt in CODE_EXTS do
    if LExt = LCodeExt then
      Exit(fcCode);

  // Priority 5: Config
  for var LCfgExt in CONFIG_EXTS do
    if LExt = LCfgExt then
      Exit(fcConfig);

  Result := fcUnknown;
end;

procedure TAsWishScanService.ScanDirectory(const ARootPath: string);

  procedure ScanRecursive(const ADir, ARelBase: string);
  begin
    for var LFile in TDirectory.GetFiles(ADir) do
    begin
      var LFileName := TPath.GetFileName(LFile);
      var LRelPath: string;
      if ARelBase = '' then
        LRelPath := LFileName
      else
        LRelPath := ARelBase + '/' + LFileName;
      var LEntry: TScanResult;
      LEntry.RelativePath := LRelPath;
      LEntry.Category := ClassifyFile(LRelPath, LFileName);
      FResults.Add(LEntry);
    end;

    for var LSubDir in TDirectory.GetDirectories(ADir) do
    begin
      var LDirName := TPath.GetFileName(LSubDir);
      if IsIgnoredDir(LDirName) then
      begin
        var LEntry: TScanResult;
        if ARelBase = '' then
          LEntry.RelativePath := LDirName
        else
          LEntry.RelativePath := ARelBase + '/' + LDirName;
        LEntry.Category := fcIgnored;
        FResults.Add(LEntry);
        Continue;
      end;
      var LNewBase: string;
      if ARelBase = '' then
        LNewBase := LDirName
      else
        LNewBase := ARelBase + '/' + LDirName;
      ScanRecursive(LSubDir, LNewBase);
    end;
  end;

begin
  FResults.Clear;
  if not TDirectory.Exists(ARootPath) then
    Exit;
  ScanRecursive(ARootPath, '');
end;

function TAsWishScanService.GetFilesByCategory(ACategory: TFileCategory): TArray<string>;
begin
  var LList := TList<string>.Create;
  try
    for var LEntry in FResults do
      if LEntry.Category = ACategory then
        LList.Add(LEntry.RelativePath);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TAsWishScanService.TotalFiles: Integer;
begin
  Result := FResults.Count;
end;

function TAsWishScanService.CategoryCount(ACategory: TFileCategory): Integer;
begin
  Result := 0;
  for var LEntry in FResults do
    if LEntry.Category = ACategory then
      Inc(Result);
end;

function TAsWishScanService.DetectProjectType: string;

  function HasAnyExt(const ACodeFiles: TArray<string>;
    const AExts: TArray<string>): Boolean;
  begin
    for var LFile in ACodeFiles do
      for var LExt in AExts do
        if LFile.EndsWith(LExt) then
          Exit(True);
    Result := False;
  end;

  function HasAnyReactFile: Boolean;
  begin
    // WO-0057 1.1 (Route B): React projects may consist entirely of .tsx or .jsx
    // files, which protocol §14.1 classifies as fcUI rather than fcCode. We inspect
    // fcCode files (.ts) plus UI_EXTS whitelist (['.tsx', '.jsx']). Other UI extensions
    // such as .vue, .svelte, and .astro remain in UI_EXTS for UI asset counting but are
    // deliberately excluded here to avoid falsely classifying Vue/Svelte/Astro projects as React.
    for var LEntry in FResults do
    begin
      if (LEntry.Category = fcCode) and LEntry.RelativePath.EndsWith('.ts') then
        Exit(True);
      if (LEntry.Category = fcUI) and
         (LEntry.RelativePath.EndsWith('.tsx') or LEntry.RelativePath.EndsWith('.jsx')) then
        Exit(True);
    end;
    Result := False;
  end;

var
  LCodeFiles: TArray<string>;
  LHasCode, LHasReact: Boolean;
begin
  Result := 'unknown';
  LHasCode := CategoryCount(fcCode) > 0;
  LHasReact := HasAnyReactFile;

  if not LHasCode and not LHasReact then
    Exit;

  LCodeFiles := GetFilesByCategory(fcCode);
  // A fixed priority, not the order the files happen to be listed in: with a
  // file-order scan a repo holding both Python and TypeScript answered
  // differently after someone added an unrelated file.
  if HasAnyExt(LCodeFiles, ['.pas', '.dpr']) then
    Exit('delphi_vcl');
  if LHasReact then
    Exit('web_react');
  if HasAnyExt(LCodeFiles, ['.py']) then
    Exit('python_backend');
  if HasAnyExt(LCodeFiles, ['.go']) then
    Exit('mixed');

  // Code we have no name for still counts as a code project, and "mixed" is
  // what both previous implementations answered for Go; that fallback is kept
  // so a stack this build has never heard of is not downgraded to "unknown".
  if LHasCode then
    Result := 'mixed';
end;

end.
