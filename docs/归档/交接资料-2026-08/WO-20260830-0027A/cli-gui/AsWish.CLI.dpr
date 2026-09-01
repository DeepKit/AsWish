{ ============================================================================
  AsWish.CLI -- headless command-line entry (Phase 5 B-P0).

  Reuses the same src/ services as the desktop app (no DeepShell/GUI
  dependency), so the full scan -> validate -> render pipeline can be
  exercised and tested without the GUI.

  Usage:
    AsWish.CLI init              <dir>              create .AsWish structure
    AsWish.CLI scan              <dir>              scan + build 4 projections + render
    AsWish.CLI generate          <dir>              export prompts (LLM call lives in the GUI)
    AsWish.CLI validate          <dir>              validate trees/issues YAML, exit 1 on errors
    AsWish.CLI render            <dir>              re-render HTML from YAML on disk
    AsWish.CLI health            <dir> [--json]     output health metrics snapshot
    AsWish.CLI decisions apply  <dir>              promote pending decisions
    AsWish.CLI bundle apply     <dir> <id> <act>   accept or reject a bundle
    AsWish.CLI ingest            <dir> <candidate> validate and merge candidate nodes
    AsWish.CLI intent            <dir> <id> <tree> <intent> record candidate user intent
  ============================================================================ }

program AsWish.CLI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  AsWish.Services.Project in '..\src\services\AsWish.Services.Project.pas',
  AsWish.Services.Scan in '..\src\services\AsWish.Services.Scan.pas',
  AsWish.Services.SpecStore in '..\src\services\AsWish.Services.SpecStore.pas',
  AsWish.Services.TreeBuilder in '..\src\services\AsWish.Services.TreeBuilder.pas',
  AsWish.Services.Render in '..\src\services\AsWish.Services.Render.pas',
  AsWish.Services.Prompts in '..\src\services\AsWish.Services.Prompts.pas',
  AsWish.Services.Decisions in '..\src\services\AsWish.Services.Decisions.pas',
  AsWish.Services.CandidateIngest in '..\src\services\AsWish.Services.CandidateIngest.pas',
  AsWish.Models in '..\src\models\AsWish.Models.pas',
  AsWish.Hash in '..\src\core\AsWish.Hash.pas',
  AsWish.Yaml.Writer in '..\src\core\AsWish.Yaml.Writer.pas',
  AsWish.Yaml.Parser in '..\src\core\AsWish.Yaml.Parser.pas',
  AsWish.Validation in '..\src\core\AsWish.Validation.pas',
  AsWish.Delphi.DfmParser in '..\src\core\AsWish.Delphi.DfmParser.pas',
  AsWish.Delphi.PasParser in '..\src\core\AsWish.Delphi.PasParser.pas',
  System.JSON;

function DetectProjectType(AScan: TAsWishScanService): string;
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

var
  GJsonOutput: Boolean = False;
  GJsonLines: TList<string>;

function JsonEscape(const AValue: string): string;
begin
  Result := AValue.Replace('\', '\\').Replace('"', '\"');
end;

function ParseCliOptions: Boolean;
var
  I: Integer;
  LS: string;
begin
  Result := True;
  for I := 1 to ParamCount do
  begin
    LS := LowerCase(ParamStr(I));
    if (LS = '--json') or (LS = '-json') or (LS = '/json') then
    begin
      GJsonOutput := True;
      Exit;
    end;
  end;
end;

procedure WriteJsonHeader(const ACommand: string);
begin
  GJsonLines := TList<string>.Create;
  GJsonLines.Add('  "command": "' + JsonEscape(ACommand) + '"');
end;

procedure WriteJsonFooter;
var
  I: Integer;
begin
  Writeln('{');
  for I := 0 to GJsonLines.Count - 1 do
  begin
    if I < GJsonLines.Count - 1 then
      Writeln(GJsonLines[I] + ',')
    else
      Writeln(GJsonLines[I]);
  end;
  Writeln('}');
  GJsonLines.Free;
end;

procedure WriteJsonKV(const AKey, AValue: string);
begin
  GJsonLines.Add('  "' + AKey + '": "' + JsonEscape(AValue) + '"');
end;

procedure WriteJsonKVInt(const AKey: string; AValue: Integer);
begin
  GJsonLines.Add(Format('  "%s": %d', [AKey, AValue]));
end;

procedure WriteJsonKVDouble(const AKey: string; AValue: Double);
begin
  GJsonLines.Add(Format('  "%s": %.2f', [AKey, AValue]));
end;

procedure WriteJsonBool(const AKey: string; AValue: Boolean);
begin
  GJsonLines.Add(Format('  "%s": %s', [AKey, LowerCase(BoolToStr(AValue, True))]));
end;

procedure RunDecisionsApply(const ADir: string);
var
  LProject: TAsWishProjectService;
  LStore: TAsWishStoreService;
  LDecisions: TAsWishDecisionsService;
  LCount: Integer;
  LTreeNames: TArray<string>;
  LNodes: TList<TSpecNode>;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[decisions-apply] error: no .AsWish directory; run scan first');
    Halt(1);
  end;
  LProject := TAsWishProjectService.Create;
  LStore := TAsWishStoreService.Create;
  LDecisions := TAsWishDecisionsService.Create;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LDecisions.Initialize(LProject.AsWishPath);
    LDecisions.Load;

    LCount := LDecisions.PromotePending;
    if GJsonOutput then
    begin
      WriteJsonHeader('decisions-apply');
      WriteJsonKVInt('promoted', LCount);
    end
    else
      Writeln(Format('[decisions-apply] promoted %d pending decisions', [LCount]));

    if LCount > 0 then
    begin
      LTreeNames := TArray<string>.Create(
        'trees/function-tree.yaml', 'trees/module-tree.yaml',
        'trees/view-tree.yaml', 'trees/data-tree.yaml');
      for var LTree in LTreeNames do
      begin
        if not TFile.Exists(TPath.Combine(LStore.BasePath, LTree)) then Continue;
        LNodes := LStore.ReadTreeFile(LTree);
        try
          if (LNodes <> nil) and (LNodes.Count > 0) then
          begin
            LDecisions.ApplyNodeStatusTransitions(LTree, LNodes);
            LStore.WriteTreeFile(LTree, LNodes[0].Tree, LNodes);
            if not GJsonOutput then
              Writeln(Format('[decisions-apply] transitions applied to %s', [LTree]));
          end;
        finally
          LNodes.Free;
        end;
      end;
    end;

    if GJsonOutput then
    begin
      WriteJsonKV('status', 'ok');
      WriteJsonFooter;
    end
    else
      Writeln('[decisions-apply] done');
  finally
    LDecisions.Free;
    LStore.Free;
    LProject.Free;
  end;
end;

procedure RunHealth(const ADir: string);
var
  LProject: TAsWishProjectService;
  LStore: TAsWishStoreService;
  LRender: TAsWishRenderService;
  LFunc, LModule, LView, LData: TList<TSpecNode>;
  LIssues: TList<TSpecIssue>;
  LMetrics: THealthMetrics;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[health] error: no .AsWish directory; run scan first');
    Halt(1);
  end;
  LProject := TAsWishProjectService.Create;
  LStore := TAsWishStoreService.Create;
  LRender := TAsWishRenderService.Create;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LRender.Initialize(LProject.AsWishPath);

    LFunc := LStore.ReadTreeFile('trees/function-tree.yaml');
    LModule := LStore.ReadTreeFile('trees/module-tree.yaml');
    LView := LStore.ReadTreeFile('trees/view-tree.yaml');
    if TFile.Exists(TPath.Combine(LStore.BasePath, 'trees\data-tree.yaml')) then
      LData := LStore.ReadTreeFile('trees/data-tree.yaml')
    else
      LData := nil;

    if TFile.Exists(TPath.Combine(LStore.BasePath, 'issues\doc-issues.yaml')) then
      LIssues := LStore.ReadIssuesFile('issues/doc-issues.yaml')
    else
      LIssues := nil;

    try
      LMetrics := LRender.ComputeHealthMetrics(LFunc, LModule, LView, LData, LIssues);

      if GJsonOutput then
      begin
        WriteJsonHeader('health');
        WriteJsonKVInt('totalNodes', LMetrics.TotalNodes);
        WriteJsonKVInt('confirmedNodes', LMetrics.ConfirmedNodes);
        WriteJsonKVDouble('coveragePct', LMetrics.CoveragePct);
        WriteJsonKVDouble('avgConfidence', LMetrics.AvgConfidence);
        WriteJsonKVInt('decisionBacklog', LMetrics.DecisionBacklog);
        WriteJsonKVInt('fogCount', LMetrics.FogCount);
        WriteJsonKVInt('highRiskOpen', LMetrics.HighRiskOpen);
        WriteJsonKV('status', 'ok');
        WriteJsonFooter;
      end
      else
      begin
        Writeln('[health]');
        Writeln(Format('  totalNodes       : %d', [LMetrics.TotalNodes]));
        Writeln(Format('  confirmedNodes   : %d', [LMetrics.ConfirmedNodes]));
        Writeln(Format('  coveragePct      : %.1f%%', [LMetrics.CoveragePct]));
        Writeln(Format('  avgConfidence    : %.2f', [LMetrics.AvgConfidence]));
        Writeln(Format('  decisionBacklog  : %d', [LMetrics.DecisionBacklog]));
        Writeln(Format('  fogCount         : %d', [LMetrics.FogCount]));
        Writeln(Format('  highRiskOpen     : %d', [LMetrics.HighRiskOpen]));
        Writeln('[health] done');
      end;
    finally
      LIssues.Free;
      LData.Free;
      LView.Free;
      LModule.Free;
      LFunc.Free;
    end;
  finally
    LRender.Free;
    LStore.Free;
    LProject.Free;
  end;
end;

procedure RunBundleApply(const ADir, ABundleId, AAction: string);
var
  LProject: TAsWishProjectService;
  LStore: TAsWishStoreService;
  LDecisions: TAsWishDecisionsService;
  LBundles: TList<TSemanticBundle>;
  LFound: TSemanticBundle;
  LDecisionType: TDecisionType;
  LDecId: string;
  LTreeNames: TArray<string>;
  LNodes: TList<TSpecNode>;
  LAppliedCount: Integer;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[bundle-apply] error: no .AsWish directory; run scan first');
    Halt(1);
  end;

  if (AAction <> 'accept') and (AAction <> 'reject') then
  begin
    Writeln('[bundle-apply] error: action must be accept or reject');
    Halt(1);
  end;

  LProject := TAsWishProjectService.Create;
  LStore := TAsWishStoreService.Create;
  LDecisions := TAsWishDecisionsService.Create;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LDecisions.Initialize(LProject.AsWishPath);
    LDecisions.Load;

    var LBundlePath := TPath.Combine(LProject.AsWishPath, 'bundles.yaml');
    if not TFile.Exists(LBundlePath) then
    begin
      Writeln('[bundle-apply] error: bundles.yaml not found');
      Halt(1);
    end;

    LBundles := LStore.ReadBundlesFile('bundles.yaml');
    try
      LFound.Id := '';
      for var LB in LBundles do
        if SameText(LB.Id, ABundleId) then
        begin
          LFound := LB;
          Break;
        end;

      if LFound.Id = '' then
      begin
        Writeln(Format('[bundle-apply] error: bundle not found: %s', [ABundleId]));
        Halt(1);
      end;

      if AAction = 'accept' then
        LDecisionType := dtConfirm
      else
        LDecisionType := dtReject;

      LDecId := LDecisions.AddDecision(
        LDecisionType,
        Format('%s: %s', [AAction, LFound.Title]),
        Format('CLI %s for bundle %s', [AAction, LFound.Id]),
        Format('Applied to %d nodes via CLI', [Length(LFound.NodeIds)]),
        LFound.NodeIds
      );

      if AAction = 'accept' then
        LDecisions.AcceptDecision(LDecId)
      else
        LDecisions.RejectDecision(LDecId);
      LAppliedCount := 1;
      if GJsonOutput then
      begin
        WriteJsonHeader('bundle-apply');
        WriteJsonKV('bundleId', LFound.Id);
        WriteJsonKV('action', AAction);
        WriteJsonKVInt('nodes', Length(LFound.NodeIds));
        WriteJsonKV('decisionId', LDecId);
        WriteJsonKVInt('promoted', LAppliedCount);
      end
      else
        Writeln(Format('[bundle-apply] %s bundle %s (%d nodes, decision %s)',
          [AAction, LFound.Id, Length(LFound.NodeIds), LDecId]));

      if LAppliedCount > 0 then
      begin
        LTreeNames := TArray<string>.Create(
          'trees/function-tree.yaml', 'trees/module-tree.yaml',
          'trees/view-tree.yaml', 'trees/data-tree.yaml');
        for var LTree in LTreeNames do
        begin
          if not TFile.Exists(TPath.Combine(LStore.BasePath, LTree)) then Continue;
          LNodes := LStore.ReadTreeFile(LTree);
          try
            if (LNodes <> nil) and (LNodes.Count > 0) then
            begin
              LDecisions.ApplyNodeStatusTransitions(LTree, LNodes);
              LStore.WriteTreeFile(LTree, LNodes[0].Tree, LNodes);
              if not GJsonOutput then
                Writeln(Format('[bundle-apply] transitions applied to %s', [LTree]));
            end;
          finally
            LNodes.Free;
          end;
        end;
      end;

      if GJsonOutput then
      begin
        WriteJsonKV('status', 'ok');
        WriteJsonFooter;
      end
      else
        Writeln('[bundle-apply] done');
    finally
      LBundles.Free;
    end;
  finally
    LDecisions.Free;
    LStore.Free;
    LProject.Free;
  end;
end;

procedure RunIngest(const ADir, ACandidatePath: string);
var
  LProject: TAsWishProjectService;
  LStore: TAsWishStoreService;
  LIngest: TAsWishCandidateIngest;
  LFunctions, LModules, LViews, LData: TList<TSpecNode>;
  LContent: string;
  LResult: TCandidateIngestResult;
  LMerged: TMergeStats;
begin
  if not TFile.Exists(ACandidatePath) then
  begin
    Writeln('[ingest] error: candidate file not found: ' + ACandidatePath);
    Halt(1);
  end;
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[ingest] error: no .AsWish directory; run scan first');
    Halt(1);
  end;

  LProject := TAsWishProjectService.Create;
  LStore := TAsWishStoreService.Create;
  LIngest := TAsWishCandidateIngest.Create(LStore);
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);

    LFunctions := LStore.ReadTreeFile('trees/function-tree.yaml');
    LModules := LStore.ReadTreeFile('trees/module-tree.yaml');
    LViews := LStore.ReadTreeFile('trees/view-tree.yaml');
    LData := LStore.ReadTreeFile('trees/data-tree.yaml');
    try
      LContent := TFile.ReadAllText(ACandidatePath, TEncoding.UTF8);
      LResult := LIngest.Ingest(LContent, LFunctions, LModules, LViews, LData);
      try
        if (LResult.Errors.Count > 0) or (LResult.Rejected > 0) then
        begin
          if GJsonOutput then
          begin
            WriteJsonHeader('ingest');
            WriteJsonKV('status', 'error');
            WriteJsonKVInt('errors', LResult.Errors.Count);
            WriteJsonKVInt('rejected', LResult.Rejected);
            WriteJsonFooter;
          end
          else
          begin
            Writeln('[ingest] validation failed');
            for var LErr in LResult.Errors do
              Writeln('  error: ' + LErr);
            Writeln(Format('[ingest] rejected nodes: %d', [LResult.Rejected]));
          end;
          ExitCode := 1;
          Exit;
        end;

        LMerged := LIngest.MergeInto(
          LResult.Accepted,
          LFunctions, LModules, LViews, LData
        );

        if LMerged.Merged + LMerged.Added > 0 then
        begin
          if LResult.FuncNodes.Count > 0 then
            LStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFunctions);
          if LResult.ModNodes.Count > 0 then
            LStore.WriteTreeFile('trees/module-tree.yaml', ttModule, LModules);
          if LResult.ViewNodes.Count > 0 then
            LStore.WriteTreeFile('trees/view-tree.yaml', ttView, LViews);
          if LResult.DataNodes.Count > 0 then
            LStore.WriteTreeFile('trees/data-tree.yaml', ttData, LData);
        end;

        if GJsonOutput then
        begin
          WriteJsonHeader('ingest');
          WriteJsonKV('status', 'ok');
          WriteJsonKVInt('accepted', LResult.Accepted.Count);
          WriteJsonKVInt('rejected', LResult.Rejected);
          WriteJsonKVInt('merged', LMerged.Merged);
          WriteJsonKVInt('added', LMerged.Added);
          WriteJsonKVInt('fogCleared', LMerged.FogCleared);
          WriteJsonFooter;
        end
        else
        begin
          Writeln(Format('[ingest] accepted=%d rejected=%d merged=%d added=%d fogCleared=%d',
            [
              LResult.Accepted.Count,
              LResult.Rejected,
              LMerged.Merged,
              LMerged.Added,
              LMerged.FogCleared
            ]));
        end;
      finally
        LResult.FreeOwned;
      end;
    finally
      LFunctions.Free;
      LModules.Free;
      LViews.Free;
      LData.Free;
    end;
  finally
    LIngest.Free;
    LStore.Free;
    LProject.Free;
  end;
end;

procedure RunIntent(const ADir, ANodeId, ATreeStr, AUserIntent: string);
var
  LStore: TAsWishStoreService;
  LIngest: TAsWishCandidateIngest;
  LTree: TTreeType;
  LIntent: TCandidateIntent;
  LIssue: TSpecIssue;
  LPath: string;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[intent] error: no .AsWish directory; run scan first');
    Halt(1);
  end;

  LTree := TSpecEnums.TreeTypeFromStr(ATreeStr, ttFunction);
  LIntent := TCandidateIntent.CreateNew(ANodeId, LTree, AUserIntent, 'human');

  LStore := TAsWishStoreService.Create;
  LIngest := TAsWishCandidateIngest.Create(LStore);
  try
    if not LIngest.CheckIntentClarity(LIntent, LIssue) then
    begin
      Writeln('[intent] warning: intent unclear, grilling ticket required: ' + LIssue.Title);
    end;
    LPath := LIngest.SaveCandidateIntent(ADir, LIntent);
    if GJsonOutput then
    begin
      WriteJsonHeader('intent');
      WriteJsonKV('status', 'ok');
      WriteJsonKV('node_id', ANodeId);
      WriteJsonKV('tree', TSpecEnums.TreeTypeToStr(LTree));
      WriteJsonKV('saved_to', LPath);
      WriteJsonFooter;
    end
    else
    begin
      Writeln(Format('[intent] saved candidate intent for %s (%s) to %s',
        [ANodeId, TSpecEnums.TreeTypeToStr(LTree), LPath]));
    end;
  finally
    LIngest.Free;
    LStore.Free;
  end;
end;

procedure RunScan(const ADir: string);
var
  LProject: TAsWishProjectService;
  LScan: TAsWishScanService;
  LStore: TAsWishStoreService;
  LBuilder: TAsWishTreeBuilder;
  LRender: TAsWishRenderService;
  LPrompts: TAsWishPromptService;
  LType: string;
begin
  LProject := TAsWishProjectService.Create;
  LScan := TAsWishScanService.Create;
  LStore := TAsWishStoreService.Create;
  LBuilder := TAsWishTreeBuilder.Create;
  LRender := TAsWishRenderService.Create;
  LPrompts := TAsWishPromptService.Create;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LRender.Initialize(LProject.AsWishPath);
    LPrompts.Initialize(LProject.AsWishPath);

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

    var LBundlePath := TPath.Combine(LProject.AsWishPath, 'bundles.yaml');
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

    Writeln('[scan] done -> ' + LProject.AsWishPath + '\html\');
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
  LProject: TAsWishProjectService;
  LStore: TAsWishStoreService;
begin
  if not TDirectory.Exists(ADir) then
  begin
    Writeln('[init] error: directory does not exist: ' + ADir);
    Halt(1);
  end;
  LProject := TAsWishProjectService.Create;
  LStore := TAsWishStoreService.Create;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LStore.CreateDirectoryStructure;
    LStore.WriteEmptyTrees;
    LStore.WriteProjectSpec(LProject.ProjectName, 'unknown', 0);
    LStore.WriteGitIgnore;
    Writeln('[init] initialized: ' + LProject.AsWishPath);
  finally
    LStore.Free;
    LProject.Free;
  end;
end;

procedure RunGenerate(const ADir: string);
var
  LProject: TAsWishProjectService;
  LScan: TAsWishScanService;
  LPrompts: TAsWishPromptService;
begin
  LProject := TAsWishProjectService.Create;
  LScan := TAsWishScanService.Create;
  LPrompts := TAsWishPromptService.Create;
  try
    LProject.OpenProject(ADir);
    LPrompts.Initialize(LProject.AsWishPath);
    LScan.ScanDirectory(ADir);
    LPrompts.WriteContextPack(LScan, LProject.ProjectName,
      DetectProjectType(LScan));
    LPrompts.WriteGenerationPrompt(LProject.ProjectName,
      DetectProjectType(LScan));
    Writeln('[generate] prompts written to ' + LProject.AsWishPath
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
  LStore: TAsWishStoreService;
  LValidator: TYamlValidator;
  LErrorCount: Integer;
  LBase: string;
begin
  LStore := TAsWishStoreService.Create;
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
  LProject: TAsWishProjectService;
  LStore: TAsWishStoreService;
  LRender: TAsWishRenderService;
  LFunc, LModule, LView, LData: TList<TSpecNode>;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[render] error: no .AsWish directory; run scan first');
    Halt(1);
  end;
  LProject := TAsWishProjectService.Create;
  LStore := TAsWishStoreService.Create;
  LRender := TAsWishRenderService.Create;
  LFunc := nil; LModule := nil; LView := nil; LData := nil;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LRender.Initialize(LProject.AsWishPath);
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

    var LBundlePath := TPath.Combine(LProject.AsWishPath, 'bundles.yaml');
    if TFile.Exists(LBundlePath) then
    begin
      var LBundles := LStore.ReadBundlesFile('bundles.yaml');
      try
        LRender.RenderBundlesPage(LBundles, LFunc, LModule, LView, LData);
      finally
        LBundles.Free;
      end;
    end;

    Writeln('[render] done -> ' + LProject.AsWishPath + '\html\');
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
  ParseCliOptions;

  if ParamCount < 2 then
  begin
    Writeln('AsWish.CLI [--json] <command> <project-dir>');
    Writeln('  init              create .AsWish structure');
    Writeln('  scan              scan + build trees + render + prompts');
    Writeln('  generate          export prompts (LLM call runs in the GUI)');
    Writeln('  validate          validate trees/issues YAML (exit 1 on errors)');
    Writeln('  render            re-render HTML from YAML on disk');
    Writeln('  health            print health metrics (add --json for machine output)');
    Writeln('  decisions apply <dir>     promote pending + apply transitions');
    Writeln('  bundle apply <dir> <id> <accept|reject>');
    Writeln('  ingest <dir> <file.yaml>  validate + merge LLM candidate nodes');
    Writeln('  intent <dir> <id> <tree> <text> record candidate user intent');
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
  else if LCommand = 'health' then
    RunHealth(LDir)
  else if LCommand = 'decisions' then
  begin
    if (ParamCount >= 3) and (LowerCase(ParamStr(2)) = 'apply') then
      RunDecisionsApply(ParamStr(3))
    else
    begin
      Writeln('AsWish.CLI decisions: expected: decisions apply <project-dir>');
      Halt(2);
    end;
  end
  else if LCommand = 'bundle' then
  begin
    if (ParamCount >= 5) and (LowerCase(ParamStr(2)) = 'apply') then
      RunBundleApply(ParamStr(3), ParamStr(4), LowerCase(ParamStr(5)))
    else
    begin
      Writeln('AsWish.CLI bundle: expected: bundle apply <project-dir> <bundle-id> <accept|reject>');
      Halt(2);
    end;
  end
  else if LCommand = 'ingest' then
  begin
    if ParamCount < 3 then
    begin
      Writeln('AsWish.CLI ingest <candidate.yaml>');
      Halt(2);
    end;
    RunIngest(LDir, ParamStr(3));
  end
  else if LCommand = 'intent' then
  begin
    if ParamCount < 5 then
    begin
      Writeln('AsWish.CLI intent <project-dir> <node-id> <tree> <user_intent>');
      Halt(2);
    end;
    RunIntent(LDir, ParamStr(3), ParamStr(4), ParamStr(5));
  end
  else
  begin
    Writeln('AsWish.CLI: unknown command: ' + LCommand);
    Halt(2);
  end;
end.
