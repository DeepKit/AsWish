{ ============================================================================
  DeepSpec.CLI — headless command-line entry (Phase 5 B-P0).

  Reuses the same src/ services as the desktop app (no DeepShell/GUI
  dependency), so the full scan → validate → render pipeline can be
  exercised and tested without the GUI.

  Usage:
    DeepSpec.CLI init     <dir>   create .deepspec structure
    DeepSpec.CLI scan     <dir>   scan + build trees + render + prompts
    DeepSpec.CLI generate <dir>   export prompts (LLM call lives in the GUI)
    DeepSpec.CLI validate <dir>   validate trees/issues YAML, exit 1 on errors
    DeepSpec.CLI render   <dir>   re-render HTML from YAML on disk
  ============================================================================ }

program DeepSpec.CLI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  DeepSpec.Services.Project in '..\src\services\DeepSpec.Services.Project.pas',
  DeepSpec.Services.Scan in '..\src\services\DeepSpec.Services.Scan.pas',
  DeepSpec.Services.SpecStore in '..\src\services\DeepSpec.Services.SpecStore.pas',
  DeepSpec.Services.TreeBuilder in '..\src\services\DeepSpec.Services.TreeBuilder.pas',
  DeepSpec.Services.Render in '..\src\services\DeepSpec.Services.Render.pas',
  DeepSpec.Services.Prompts in '..\src\services\DeepSpec.Services.Prompts.pas',
  DeepSpec.Models in '..\src\models\DeepSpec.Models.pas',
  DeepSpec.Hash in '..\src\core\DeepSpec.Hash.pas',
  DeepSpec.Yaml.Writer in '..\src\core\DeepSpec.Yaml.Writer.pas',
  DeepSpec.Yaml.Parser in '..\src\core\DeepSpec.Yaml.Parser.pas',
  DeepSpec.Validation in '..\src\core\DeepSpec.Validation.pas',
  DeepSpec.Delphi.DfmParser in '..\src\core\DeepSpec.Delphi.DfmParser.pas',
  DeepSpec.Delphi.PasParser in '..\src\core\DeepSpec.Delphi.PasParser.pas';

function DetectProjectType(AScan: TDeepSpecScanService): string;
var
  LCodeFiles: TArray<string>;
begin
  Result := 'unknown';
  if AScan.CategoryCount(fcCode) = 0 then Exit;
  LCodeFiles := AScan.GetFilesByCategory(fcCode);
  for var LFile in LCodeFiles do
    if LFile.EndsWith('.pas') or LFile.EndsWith('.dpr') then
      Exit('delphi_vcl');
  for var LFile in LCodeFiles do
  begin
    if LFile.EndsWith('.ts') or LFile.EndsWith('.tsx') then
      Exit('web_react');
    if LFile.EndsWith('.py') then
      Exit('python_backend');
  end;
  Result := 'mixed';
end;

procedure RunScan(const ADir: string);
var
  LProject: TDeepSpecProjectService;
  LScan: TDeepSpecScanService;
  LStore: TDeepSpecStoreService;
  LBuilder: TDeepSpecTreeBuilder;
  LRender: TDeepSpecRenderService;
  LPrompts: TDeepSpecPromptService;
  LType: string;
begin
  LProject := TDeepSpecProjectService.Create;
  LScan := TDeepSpecScanService.Create;
  LStore := TDeepSpecStoreService.Create;
  LBuilder := TDeepSpecTreeBuilder.Create;
  LRender := TDeepSpecRenderService.Create;
  LPrompts := TDeepSpecPromptService.Create;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LRender.Initialize(LProject.DeepSpecPath);
    LPrompts.Initialize(LProject.DeepSpecPath);

    Writeln('[scan] scanning ' + ADir);
    LScan.ScanDirectory(ADir);
    LType := DetectProjectType(LScan);
    LProject.SetProjectType(LType);
    Writeln(Format('[scan] %d files, type=%s',
      [LScan.TotalFiles, LType]));

    LStore.CreateDirectoryStructure;
    LStore.WriteScanReport(LScan);
    LStore.WriteProjectSpec(LProject.ProjectName, LType, 0);
    LStore.WriteEmptyTrees;
    LStore.WriteGitIgnore;

    LBuilder.BuildFromScan(LScan, LProject.ProjectName, LProject.ProjectPath);
    Writeln(Format('[scan] trees: function %d / module %d / view %d / data %d',
      [LBuilder.FunctionNodes.Count, LBuilder.ModuleNodes.Count,
       LBuilder.ViewNodes.Count, LBuilder.DataNodes.Count]));

    LStore.WriteTreeFile('trees/function-tree.yaml', ttFunction,
      LBuilder.FunctionNodes);
    LStore.WriteTreeFile('trees/module-tree.yaml', ttModule,
      LBuilder.ModuleNodes);
    LStore.WriteTreeFile('trees/view-tree.yaml', ttView,
      LBuilder.ViewNodes);
    if LBuilder.DataNodes.Count > 0 then
      LStore.WriteTreeFile('trees/data-tree.yaml', ttData,
        LBuilder.DataNodes);
    LStore.WriteEvidenceFile('evidence/source-evidence.yaml',
      LBuilder.EvidenceList);

    LRender.RenderScanReport(LScan, LProject.ProjectName, LType);
    var LIssues := LStore.ReadIssuesFile('issues/doc-issues.yaml');
    try
      LRender.RenderIndex(LProject.ProjectName, LScan.TotalFiles,
        LBuilder.FunctionNodes, LBuilder.ModuleNodes,
        LBuilder.ViewNodes, LBuilder.DataNodes, LIssues,
        LBuilder.DataNodes.Count > 0);
      LRender.RenderTree('function-tree', 'Function Tree',
        LBuilder.FunctionNodes);
      LRender.RenderTree('module-tree', 'Module Tree',
        LBuilder.ModuleNodes);
      LRender.RenderTree('view-tree', 'View Tree', LBuilder.ViewNodes);
      if LBuilder.DataNodes.Count > 0 then
        LRender.RenderTree('data-tree', 'Data Tree', LBuilder.DataNodes);
      LRender.RenderProblemsPage(LBuilder.FunctionNodes,
        LBuilder.ModuleNodes, LBuilder.ViewNodes, LBuilder.DataNodes,
        LIssues);
    finally
      LIssues.Free;
    end;

    var LBundlePath := TPath.Combine(LProject.DeepSpecPath, 'bundles.yaml');
    if TFile.Exists(LBundlePath) then
    begin
      var LBundles := LStore.ReadBundlesFile('bundles.yaml');
      try
        LRender.RenderBundlesPage(LBundles, LBuilder.FunctionNodes,
          LBuilder.ModuleNodes, LBuilder.ViewNodes, LBuilder.DataNodes);
      finally
        LBundles.Free;
      end;
    end;

    LPrompts.WriteContextPack(LScan, LProject.ProjectName, LType);
    LPrompts.WriteGenerationPrompt(LProject.ProjectName, LType);

    Writeln('[scan] done -> ' + LProject.DeepSpecPath + '\html\');
  finally
    LPrompts.Free;
    LRender.Free;
    LBuilder.Free;
    LStore.Free;
    LScan.Free;
    LProject.Free;
  end;
end;

procedure RunInit(const ADir: string);
var
  LProject: TDeepSpecProjectService;
  LStore: TDeepSpecStoreService;
begin
  if not TDirectory.Exists(ADir) then
  begin
    Writeln('[init] error: directory does not exist: ' + ADir);
    Halt(1);
  end;
  LProject := TDeepSpecProjectService.Create;
  LStore := TDeepSpecStoreService.Create;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LStore.CreateDirectoryStructure;
    LStore.WriteEmptyTrees;
    LStore.WriteProjectSpec(LProject.ProjectName, 'unknown', 0);
    LStore.WriteGitIgnore;
    Writeln('[init] initialized: ' + LProject.DeepSpecPath);
  finally
    LStore.Free;
    LProject.Free;
  end;
end;

procedure RunGenerate(const ADir: string);
var
  LProject: TDeepSpecProjectService;
  LScan: TDeepSpecScanService;
  LPrompts: TDeepSpecPromptService;
begin
  LProject := TDeepSpecProjectService.Create;
  LScan := TDeepSpecScanService.Create;
  LPrompts := TDeepSpecPromptService.Create;
  try
    LProject.OpenProject(ADir);
    LPrompts.Initialize(LProject.DeepSpecPath);
    LScan.ScanDirectory(ADir);
    LPrompts.WriteContextPack(LScan, LProject.ProjectName,
      DetectProjectType(LScan));
    LPrompts.WriteGenerationPrompt(LProject.ProjectName,
      DetectProjectType(LScan));
    Writeln('[generate] prompts written to ' + LProject.DeepSpecPath
      + '\prompts\');
    Writeln('[generate] note: the LLM call itself runs in the desktop app '
      + '(Generate B command); this command exports the prompt pack.');
  finally
    LPrompts.Free;
    LScan.Free;
    LProject.Free;
  end;
end;

procedure RunValidate(const ADir: string);
var
  LStore: TDeepSpecStoreService;
  LValidator: TYamlValidator;
  LErrorCount: Integer;
  LBase: string;
begin
  LStore := TDeepSpecStoreService.Create;
  LValidator := TYamlValidator.Create;
  try
    LStore.Initialize(ADir);
    LBase := LStore.BasePath;
    LErrorCount := 0;

    for var LRel in TArray<string>.Create(
      'trees/function-tree.yaml', 'trees/module-tree.yaml',
      'trees/view-tree.yaml', 'trees/data-tree.yaml') do
    begin
      var LPath := TPath.Combine(LBase, LRel);
      if not TFile.Exists(LPath) then
      begin
        Writeln('[validate] skip (missing): ' + LRel);
        Continue;
      end;
      var LReport := LValidator.ValidateTreeFile(
        TFile.ReadAllText(LPath, TEncoding.UTF8));
      Writeln(Format('[validate] %s: %d error(s), %d warning(s)',
        [LRel, LReport.ErrorCount, LReport.WarningCount]));
      for var LE in LReport.Errors do
        Writeln(Format('  [%s] %s @%s - %s', [LE.Rule, LE.MessageText,
          LE.Path, LE.FixHint]));
      if LReport.HasErrors then
        Inc(LErrorCount, LReport.ErrorCount);
      LReport.Free;
    end;

    var LIssuesPath := TPath.Combine(LBase, 'issues\doc-issues.yaml');
    if TFile.Exists(LIssuesPath) then
    begin
      var LReport := LValidator.ValidateIssuesFile(
        TFile.ReadAllText(LIssuesPath, TEncoding.UTF8));
      Writeln(Format('[validate] issues/doc-issues.yaml: %d error(s), %d warning(s)',
        [LReport.ErrorCount, LReport.WarningCount]));
      for var LE in LReport.Errors do
        Writeln(Format('  [%s] %s @%s - %s', [LE.Rule, LE.MessageText,
          LE.Path, LE.FixHint]));
      if LReport.HasErrors then
        Inc(LErrorCount, LReport.ErrorCount);
      LReport.Free;
    end;

    if LErrorCount > 0 then
    begin
      Writeln(Format('[validate] FAILED: %d error(s)', [LErrorCount]));
      Halt(1);
    end;
    Writeln('[validate] OK');
  finally
    LValidator.Free;
    LStore.Free;
  end;
end;

procedure RunRender(const ADir: string);
var
  LProject: TDeepSpecProjectService;
  LStore: TDeepSpecStoreService;
  LRender: TDeepSpecRenderService;
  LFunc, LModule, LView, LData: TList<TSpecNode>;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.deepspec')) then
  begin
    Writeln('[render] error: no .deepspec directory; run scan first');
    Halt(1);
  end;
  LProject := TDeepSpecProjectService.Create;
  LStore := TDeepSpecStoreService.Create;
  LRender := TDeepSpecRenderService.Create;
  LFunc := nil; LModule := nil; LView := nil; LData := nil;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LRender.Initialize(LProject.DeepSpecPath);
    LFunc := LStore.ReadTreeFile('trees/function-tree.yaml');
    LModule := LStore.ReadTreeFile('trees/module-tree.yaml');
    LView := LStore.ReadTreeFile('trees/view-tree.yaml');
    if TFile.Exists(TPath.Combine(LStore.BasePath, 'trees\data-tree.yaml')) then
      LData := LStore.ReadTreeFile('trees/data-tree.yaml');

    var LIssues := LStore.ReadIssuesFile('issues/doc-issues.yaml');
    try
      LRender.RenderIndex(LProject.ProjectName, LFunc.Count + LModule.Count
        + LView.Count, LFunc, LModule, LView, LData, LIssues,
        (LData <> nil) and (LData.Count > 0));
      LRender.RenderTree('function-tree', 'Function Tree', LFunc);
      LRender.RenderTree('module-tree', 'Module Tree', LModule);
      LRender.RenderTree('view-tree', 'View Tree', LView);
      if (LData <> nil) and (LData.Count > 0) then
        LRender.RenderTree('data-tree', 'Data Tree', LData);
      LRender.RenderProblemsPage(LFunc, LModule, LView, LData, LIssues);
    finally
      LIssues.Free;
    end;

    var LBundlePath := TPath.Combine(LProject.DeepSpecPath, 'bundles.yaml');
    if TFile.Exists(LBundlePath) then
    begin
      var LBundles := LStore.ReadBundlesFile('bundles.yaml');
      try
        LRender.RenderBundlesPage(LBundles, LFunc, LModule, LView, LData);
      finally
        LBundles.Free;
      end;
    end;

    Writeln('[render] done -> ' + LProject.DeepSpecPath + '\html\');
  finally
    LData.Free;
    LView.Free;
    LModule.Free;
    LFunc.Free;
    LRender.Free;
    LStore.Free;
    LProject.Free;
  end;
end;

var
  LCommand, LDir: string;
begin
  if ParamCount < 2 then
  begin
    Writeln('DeepSpec.CLI  <command>  <project-dir>');
    Writeln('  init       create .deepspec structure');
    Writeln('  scan       scan + build trees + render + prompts');
    Writeln('  generate   export prompts (LLM call runs in the GUI)');
    Writeln('  validate   validate trees/issues YAML (exit 1 on errors)');
    Writeln('  render     re-render HTML from YAML on disk');
    Halt(2);
  end;

  LCommand := LowerCase(ParamStr(1));
  LDir := ParamStr(2);

  if LCommand = 'init' then
    RunInit(LDir)
  else if LCommand = 'scan' then
    RunScan(LDir)
  else if LCommand = 'generate' then
    RunGenerate(LDir)
  else if LCommand = 'validate' then
    RunValidate(LDir)
  else if LCommand = 'render' then
    RunRender(LDir)
  else
  begin
    Writeln('DeepSpec.CLI: unknown command: ' + LCommand);
    Halt(2);
  end;
end.
