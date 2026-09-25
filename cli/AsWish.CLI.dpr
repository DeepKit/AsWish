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
    AsWish.CLI changeset         <dir> <id> <tree> <intent> generate structured change set
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
  AsWish.Services.LLM in '..\src\services\AsWish.Services.LLM.pas',
  AsWish.Services.Settings in '..\src\services\AsWish.Services.Settings.pas',
  AsWish.Services.SpecStore in '..\src\services\AsWish.Services.SpecStore.pas',
  AsWish.Services.TreeBuilder in '..\src\services\AsWish.Services.TreeBuilder.pas',
  AsWish.Services.Render in '..\src\services\AsWish.Services.Render.pas',
  AsWish.Services.Prompts in '..\src\services\AsWish.Services.Prompts.pas',
  AsWish.Services.Decisions in '..\src\services\AsWish.Services.Decisions.pas',
  AsWish.Services.CandidateIngest in '..\src\services\AsWish.Services.CandidateIngest.pas',
  AsWish.Services.Snapshot in '..\src\services\AsWish.Services.Snapshot.pas',
  AsWish.Models in '..\src\models\AsWish.Models.pas',
  AsWish.Hash in '..\src\core\AsWish.Hash.pas',
  AsWish.TextIO in '..\src\core\AsWish.TextIO.pas',
  AsWish.Yaml.Writer in '..\src\core\AsWish.Yaml.Writer.pas',
  AsWish.Yaml.Parser in '..\src\core\AsWish.Yaml.Parser.pas',
  AsWish.Validation in '..\src\core\AsWish.Validation.pas',
  AsWish.Delphi.DfmParser in '..\src\core\AsWish.Delphi.DfmParser.pas',
  AsWish.Delphi.PasParser in '..\src\core\AsWish.Delphi.PasParser.pas',
  AsWish.Services.EvidenceCollector in '..\src\services\AsWish.Services.EvidenceCollector.pas',
  AsWish.Services.Difference in '..\src\services\AsWish.Services.Difference.pas',
  AsWish.Services.VisualWorkflow in '..\src\services\AsWish.Services.VisualWorkflow.pas',
  AsWish.Version in '..\src\core\AsWish.Version.pas',
  AsWish.UI.Intf in '..\src\core\AsWish.UI.Intf.pas',
  AsWish.Shell.Headless in '..\src\core\AsWish.Shell.Headless.pas',
  AsWish.Controller in '..\src\controllers\AsWish.Controller.pas',
  System.JSON;

// The project type is named by the scan service itself. The CLI used to carry
// its own copy, which disagreed with the desktop app about code it could not
// name; the scan already did the classification, so it owns the answer.

var
  GJsonOutput: Boolean = False;
  GJsonLines: TList<string>;

type
  // One owner for the twelve objects a command needs before it has a
  // Controller. TAsWishController.Destroy frees only FCommons and FSnapshot --
  // the two it creates itself -- so the injected services stay owned by
  // whoever built them. Handing them to a Controller and freeing the
  // Controller is therefore not enough, and copying this construction block
  // into seven more commands would give eight copies that drift.
  TControllerBundle = class
  private
    FProject: TAsWishProjectService;
    FScan: TAsWishScanService;
    FStore: TAsWishStoreService;
    FBuilder: TAsWishTreeBuilder;
    FRender: TAsWishRenderService;
    FPrompts: TAsWishPromptService;
    FDecisions: TAsWishDecisionsService;
    FSettings: TAsWishSettingsService;
    FLLM: TAsWishLLMService;
    FController: TAsWishController;
  public
    /// <summary>ASilentStatus suppresses the status channel's console echo.
    /// Commands that own a strict output format (JSON, or a fixed human line
    /// set) must pass True: the Controller narrates decisions through
    /// FStatus.Info, and that echo lands in the middle of the JSON stream.
    /// Commands that narrate themselves through the status channel -- scan
    /// above all -- need the default False.</summary>
    constructor Create(ASilentStatus: Boolean = False);
    destructor Destroy; override;
    property Controller: TAsWishController read FController;
    property Project: TAsWishProjectService read FProject;
  end;

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

procedure RunIntentList(const ADir: string);
var
  LIntents: TArray<TCandidateIntent>;
  I: Integer;
  LBundle: TControllerBundle;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[intent list] error: no .AsWish directory; run scan first');
    Halt(1);
  end;

  LBundle := TControllerBundle.Create;
  try
    LBundle.Controller.OpenProject(ADir);
    LIntents := LBundle.Controller.ListCandidateIntents;
    if GJsonOutput then
    begin
      WriteJsonHeader('intent_list');
      WriteJsonKVInt('total', Length(LIntents));
      WriteJsonFooter;
    end
    else
    begin
      Writeln(Format('Found %d candidate intent(s):', [Length(LIntents)]));
      for I := 0 to Length(LIntents) - 1 do
      begin
        Writeln(Format('  [%d] Node: %s (%s) | Author: %s',
          [I + 1, LIntents[I].NodeId, TSpecEnums.TreeTypeToStr(LIntents[I].Tree), LIntents[I].Author]));
        Writeln('      Intent: ' + LIntents[I].UserIntent);
      end;
    end;
  finally
    LBundle.Free;
  end;
end;

procedure RunChangeSet(const ADir, ANodeId, ATreeStr, AUserIntent: string);
var
  LStore: TAsWishStoreService;
  LIngest: TAsWishCandidateIngest;
  LPrompts: TAsWishPromptService;
  LTree: TTreeType;
  LIntent: TCandidateIntent;
  LChangeSet: TChangeSet;
  LBundles: TList<TSemanticBundle>;
  LNodes: TList<TSpecNode>;
  LTargetNode: TSpecNode;
  LTreeFile: string;
  LAffected: TArray<TTreeType>;
  LChangePath, LPromptPath: string;
  LItem: TChangeItem;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[changeset] error: no .AsWish directory; run scan first');
    Halt(1);
  end;

  LTree := TSpecEnums.TreeTypeFromStr(ATreeStr, ttFunction);
  LIntent := TCandidateIntent.CreateNew(ANodeId, LTree, AUserIntent, 'human');

  LStore := TAsWishStoreService.Create;
  LIngest := TAsWishCandidateIngest.Create(LStore);
  LPrompts := TAsWishPromptService.Create;
  try
    LStore.Initialize(ADir);
    LPrompts.Initialize(TPath.Combine(ADir, '.AsWish'));

    LBundles := LStore.ReadBundlesFile('bundles.yaml');
    try
      case LTree of
        ttFunction: LTreeFile := 'trees/function-tree.yaml';
        ttModule:   LTreeFile := 'trees/module-tree.yaml';
        ttView:     LTreeFile := 'trees/view-tree.yaml';
        ttData:     LTreeFile := 'trees/data-tree.yaml';
      end;
      LNodes := LStore.ReadTreeFile(LTreeFile);
      try
        LTargetNode := Default(TSpecNode);
        for var LN in LNodes do
          if LN.Id = ANodeId then
          begin
            LTargetNode := LN;
            Break;
          end;

        LAffected := LIngest.ComputeAffectedProjections(ANodeId, LBundles);

        var LCSId := LIngest.GenerateNextChangeSetId(ADir, ANodeId);
        LChangeSet := TChangeSet.CreateNew(LCSId, ANodeId, LTree, AUserIntent, 'human');
        LChangeSet.AffectedProjections := LAffected;

        LItem := TChangeItem.CreateItem(ANodeId, LTree, 'summary', LTargetNode.Summary, AUserIntent, cstExplicit, 'Interpreted from human user intent');
        LChangeSet.Items := TArray<TChangeItem>.Create(LItem);

        LChangePath := LIngest.SaveChangeSet(ADir, LChangeSet);
        LPromptPath := LPrompts.WriteChangeInterpretPrompt(LIntent, LTargetNode, LBundles);

        if GJsonOutput then
        begin
          WriteJsonHeader('changeset');
          WriteJsonKV('status', 'ok');
          WriteJsonKV('change_set_id', LChangeSet.Id);
          WriteJsonKV('node_id', ANodeId);
          WriteJsonKV('tree', TSpecEnums.TreeTypeToStr(LTree));
          WriteJsonKV('saved_to', LChangePath);
          WriteJsonKV('prompt_path', LPromptPath);
          WriteJsonKVInt('items_count', Length(LChangeSet.Items));
          WriteJsonFooter;
        end
        else
        begin
          Writeln(Format('[changeset] generated change set %s for %s (%s)',
            [LChangeSet.Id, ANodeId, TSpecEnums.TreeTypeToStr(LTree)]));
          Writeln('  saved change set: ' + LChangePath);
          Writeln('  saved prompt:     ' + LPromptPath);
        end;
      finally
        LNodes.Free;
      end;
    finally
      LBundles.Free;
    end;
  finally
    LPrompts.Free;
    LIngest.Free;
    LStore.Free;
  end;
end;

procedure RunChangeSetReview(const ADir, AChangeSetId: string);
var
  LStore: TAsWishStoreService;
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LFuncNodes: TList<TSpecNode>;
  LSummary: string;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[changeset] error: no .AsWish directory; run scan first');
    Halt(1);
  end;
  LStore := TAsWishStoreService.Create;
  LIngest := TAsWishCandidateIngest.Create(LStore);
  try
    LStore.Initialize(ADir);
    LCS := LIngest.LoadChangeSet(ADir, AChangeSetId);
    if LCS.Id = '' then
    begin
      Writeln('[changeset] error: change set not found: ' + AChangeSetId);
      Halt(1);
    end;
    LFuncNodes := LStore.ReadTreeFile('trees/function-tree.yaml');
    try
      LSummary := LIngest.FormatChangeSetReviewSummary(LCS, LFuncNodes);
      Writeln(LSummary);
    finally
      LFuncNodes.Free;
    end;
  finally
    LIngest.Free;
    LStore.Free;
  end;
end;

procedure RunChangeSetAccept(const ADir, AChangeSetId, ARationale: string);
var
  LBundle: TControllerBundle;
  LResult: TChangeSetDecisionResult;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[changeset] error: no .AsWish directory; run scan first');
    Halt(1);
  end;
  // The Controller owns this orchestration, exactly as the desktop app runs
  // it. This used to build its own four services, re-read the trees, apply the
  // change set and freeze a baseline here -- a second copy that had no
  // idempotency guard, so a repeated accept recorded a second decision and
  // froze a second baseline for the same change set. ALoadTreesFromDisk is
  // passed because this process has no live session to apply to.
  // Status echo off: the lines below are this command's whole contract.
  LBundle := TControllerBundle.Create(True);
  try
    LBundle.Controller.OpenProject(ADir);
    if not LBundle.Controller.AcceptChangeSet(AChangeSetId, ARationale, True, LResult) then
    begin
      Writeln('[changeset] error: change set not found: ' + AChangeSetId);
      Halt(1);
    end;

    if GJsonOutput then
    begin
      WriteJsonHeader('changeset_accept');
      WriteJsonKV('status', 'ok');
      WriteJsonKV('decision_id', LResult.DecisionId);
      WriteJsonKV('change_set_id', LResult.ChangeSetId);
      WriteJsonKV('baseline_id', LResult.BaselineId);
      WriteJsonKVInt('updated_nodes', LResult.UpdatedNodes);
      WriteJsonFooter;
    end
    else
    begin
      Writeln(Format('[changeset] ACCEPTED %s -> recorded Decision %s',
        [LResult.ChangeSetId, LResult.DecisionId]));
      Writeln(Format('  applied %d changes to Canonical Spec and validated',
        [LResult.UpdatedNodes]));
      Writeln(Format('  frozen Accepted Baseline %s (snapshot: %s)',
        [LResult.BaselineId, LResult.BaselineSnapshot]));
    end;
  finally
    LBundle.Free;
  end;
end;

procedure RunChangeSetReject(const ADir, AChangeSetId, ARationale: string);
var
  LBundle: TControllerBundle;
  LResult: TChangeSetDecisionResult;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[changeset] error: no .AsWish directory; run scan first');
    Halt(1);
  end;
  // The decision is recorded by the Controller, exactly as the desktop app
  // records it. This used to build the ingest and decisions services here and
  // call RecordChangeSetDecision itself -- a second copy of the orchestration
  // that could drift from the one the GUI follows. The status channel is
  // silenced: this command owns its output format.
  LBundle := TControllerBundle.Create(True);
  try
    LBundle.Controller.OpenProject(ADir);
    if not LBundle.Controller.RejectChangeSet(AChangeSetId, ARationale, LResult) then
    begin
      Writeln('[changeset] error: change set not found: ' + AChangeSetId);
      Halt(1);
    end;

    if GJsonOutput then
    begin
      WriteJsonHeader('changeset_reject');
      WriteJsonKV('status', 'ok');
      WriteJsonKV('decision_id', LResult.DecisionId);
      WriteJsonKV('change_set_id', LResult.ChangeSetId);
      WriteJsonKV('canonical_spec', 'untouched');
      WriteJsonFooter;
    end
    else
    begin
      Writeln(Format('[changeset] REJECTED %s -> recorded Decision %s (Canonical Spec untouched)',
        [LResult.ChangeSetId, LResult.DecisionId]));
    end;
  finally
    LBundle.Free;
  end;
end;

procedure RunChangeSetClarify(const ADir, AChangeSetId, AClarification: string);
var
  LBundle: TControllerBundle;
  LResult: TChangeSetDecisionResult;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[changeset] error: no .AsWish directory; run scan first');
    Halt(1);
  end;
  // Same as RunChangeSetReject: the Controller owns the orchestration, this
  // command only renders the result.
  LBundle := TControllerBundle.Create(True);
  try
    LBundle.Controller.OpenProject(ADir);
    if not LBundle.Controller.ClarifyChangeSet(AChangeSetId, AClarification, LResult) then
    begin
      Writeln('[changeset] error: change set not found: ' + AChangeSetId);
      Halt(1);
    end;

    if GJsonOutput then
    begin
      WriteJsonHeader('changeset_clarify');
      WriteJsonKV('status', 'ok');
      WriteJsonKV('decision_id', LResult.DecisionId);
      WriteJsonKV('change_set_id', LResult.ChangeSetId);
      WriteJsonKV('canonical_spec', 'untouched');
      WriteJsonFooter;
    end
    else
    begin
      Writeln(Format('[changeset] CLARIFIED %s -> recorded Decision %s (Canonical Spec untouched)',
        [LResult.ChangeSetId, LResult.DecisionId]));
      Writeln('  Clarification detail: ' + AClarification);
    end;
  finally
    LBundle.Free;
  end;
end;

constructor TControllerBundle.Create(ASilentStatus: Boolean);
var
  LStatus: IShellStatusManager;
  LContext: IShellContextManager;
  LBus: IShellEventBus;
begin
  FProject := TAsWishProjectService.Create;
  FScan := TAsWishScanService.Create;
  FStore := TAsWishStoreService.Create;
  FBuilder := TAsWishTreeBuilder.Create;
  FRender := TAsWishRenderService.Create;
  FPrompts := TAsWishPromptService.Create;
  FDecisions := TAsWishDecisionsService.Create;
  FSettings := TAsWishSettingsService.Create;
  FLLM := TAsWishLLMService.Create('Default');
  LStatus := TConsoleStatusManager.Create(ASilentStatus);
  LContext := THeadlessContextManager.Create;
  LBus := THeadlessEventBus.Create;
  try
    FController := TAsWishController.Create(
      FProject, FScan, FStore, FRender, FBuilder, FPrompts, FDecisions,
      FLLM, FSettings, LStatus, LContext, LBus);
  except
    // A half-built bundle must not leak; the fields are cleared as we go so a
    // later Destroy cannot double-free what this block already released.
    FController := nil;
    FLLM.Free;
    FSettings.Free;
    FDecisions.Free;
    FPrompts.Free;
    FRender.Free;
    FBuilder.Free;
    FStore.Free;
    FScan.Free;
    FProject.Free;
    FLLM := nil;
    FSettings := nil;
    FDecisions := nil;
    FPrompts := nil;
    FRender := nil;
    FBuilder := nil;
    FStore := nil;
    FScan := nil;
    FProject := nil;
    raise;
  end;
end;

destructor TControllerBundle.Destroy;
begin
  // The three shell objects need no field: the Controller keeps them as
  // interface fields, so they are released when it is freed.
  FController.Free;
  FLLM.Free;
  FSettings.Free;
  FDecisions.Free;
  FPrompts.Free;
  FRender.Free;
  FBuilder.Free;
  FStore.Free;
  FScan.Free;
  FProject.Free;
  inherited;
end;

procedure RunScan(const ADir: string);
var
  LBundle: TControllerBundle;
begin
  // The scan is orchestrated by the Controller, exactly as the desktop app
  // orchestrates it. This used to be a second, shorter copy of the same
  // sequence held here in the program body -- which is how the evidence
  // catalog came to exist in the CLI's pages and in nobody else's. The
  // bundle only builds the objects and hands them over: nothing below this
  // line decides what a scan does.
  LBundle := TControllerBundle.Create;
  try
    Writeln('[scan] scanning ' + ADir);
    LBundle.Controller.OpenAndScan(ADir);

    if LBundle.Controller.ScanFailed then
    begin
      // The Controller reports through the status channel and does not raise;
      // a console run must not print success it did not get.
      Writeln('[scan] failed');
      Halt(1);
    end;

    Writeln('[scan] done -> ' + LBundle.Project.AsWishPath + '\html\');
    // The scan writes the spec state into the user's repository, which leaves
    // their "git status" dirty. Say so instead of letting them discover it.
    Writeln('[scan] note: derived output is gitignored; spec state ' +
      '(trees/ evidence/ issues/ decisions/ relations/) is not. ' +
      'Add ".AsWish/" to your .gitignore if you do not want it tracked.');
  finally
    LBundle.Free;
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
  LBundle: TControllerBundle;
begin
  // Same orchestration the desktop app's Export Prompt button follows. This
  // used to build its own scan and prompt services and detect the project type
  // here -- a second copy of a sequence the Controller already owns.
  // Status echo off: the two lines below are this command's whole contract.
  LBundle := TControllerBundle.Create(True);
  try
    LBundle.Controller.OpenProject(ADir);
    LBundle.Controller.ExportPrompt;
    Writeln('[generate] prompts written to ' + LBundle.Project.AsWishPath
      + '\prompts\');
    Writeln('[generate] note: the LLM call itself runs in the desktop app '
      + '(Generate B command); this command exports the prompt pack.');
  finally
    LBundle.Free;
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
      // The reload path has no scan service to ask, so the file count on the
      // dashboard is the node total. Every other entry point passes the real
      // scanned file count; that difference is a per-entry input, not a second
      // copy of the page sequence.
      LRender.RenderStandardPages(LProject.ProjectName,
        LFunc.Count + LModule.Count + LView.Count, LFunc, LModule, LView,
        LData, LIssues, LStore);
    finally
      LIssues.Free;
    end;

    var LDecFile := TPath.Combine(LProject.AsWishPath, 'decisions.yaml');
    if TFile.Exists(LDecFile) then
    begin
      var LDecService := TAsWishDecisionsService.Create;
      try
        LDecService.Initialize(LProject.AsWishPath);
        LDecService.Load;
        LRender.RenderDecisionsPage(LDecService.Decisions.ToArray, LProject.ProjectName);
      finally
        LDecService.Free;
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

procedure RunBaselineList(const ADir: string);
var
  LBaselines: TArray<TAsWishBaseline>;
  I: Integer;
  LBundle: TControllerBundle;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[baseline] error: no .AsWish directory');
    Halt(1);
  end;
  LBundle := TControllerBundle.Create;
  try
    LBundle.Controller.OpenProject(ADir);
    LBaselines := LBundle.Controller.ListBaselines;
    if Length(LBaselines) = 0 then
    begin
      Writeln('[baseline] no Accepted Baselines found');
      Exit;
    end;
    Writeln(Format('[baseline] found %d Accepted Baseline(s):', [Length(LBaselines)]));
    for I := 0 to Length(LBaselines) - 1 do
    begin
      Writeln(Format('  - ID: %s | Decision: %s | Snapshot: %s | Tree: %s',
        [LBaselines[I].BaselineId, LBaselines[I].DecisionId, LBaselines[I].SnapshotName, LBaselines[I].TreeType]));
      Writeln(Format('    ContentHash: %s | RelationHash: %s',
        [LBaselines[I].ContentHash, LBaselines[I].RelationHash]));
      if LBaselines[I].RendererVersion <> '' then
        Writeln(Format('    Renderer: %s | VisualBinding: %s',
          [LBaselines[I].RendererVersion, LBaselines[I].VisualBinding]));
      if LBaselines[I].Lineage.ParentBaselineId <> '' then
        Writeln(Format('    Lineage: ChangeSet=%s, Intent=%s, ParentBaseline=%s',
          [LBaselines[I].Lineage.ChangeSetId, LBaselines[I].Lineage.IntentId, LBaselines[I].Lineage.ParentBaselineId]))
      else
        Writeln(Format('    Lineage: ChangeSet=%s, Intent=%s',
          [LBaselines[I].Lineage.ChangeSetId, LBaselines[I].Lineage.IntentId]));
    end;
  finally
    LBundle.Free;
  end;
end;

procedure RunBaselineVerify(const ADir, ABaselineId: string);
var
  LValid: Boolean;
  LBundle: TControllerBundle;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[baseline] error: no .AsWish directory');
    Halt(1);
  end;
  LBundle := TControllerBundle.Create;
  try
    LBundle.Controller.OpenProject(ADir);
    LValid := LBundle.Controller.VerifyBaseline(ABaselineId);
    if LValid then
      Writeln(Format('[baseline verify] PASS: %s integrity verified (content & relation hashes match)', [ABaselineId]))
    else
    begin
      Writeln(Format('[baseline verify] FAIL: %s verification failed or baseline not found', [ABaselineId]));
      Halt(1);
    end;
  finally
    LBundle.Free;
  end;
end;

procedure RunVisualPreview(const ADir: string);
var
  LProject: TAsWishProjectService;
  LStore: TAsWishStoreService;
  LRender: TAsWishRenderService;
  LView: TList<TSpecNode>;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[visual] error: no .AsWish directory');
    Halt(1);
  end;
  LProject := TAsWishProjectService.Create;
  LStore := TAsWishStoreService.Create;
  LRender := TAsWishRenderService.Create;
  LView := nil;
  try
    LProject.OpenProject(ADir);
    LStore.Initialize(ADir);
    LRender.Initialize(LProject.AsWishPath);
    LView := LStore.ReadTreeFile('trees/view-tree.yaml');
    LRender.RenderVisualPreview(LView, LProject.ProjectName);
    Writeln('[visual preview] rendered -> ' + TPath.Combine(LProject.AsWishPath, 'html\visual-preview.html'));
  finally
    LView.Free;
    LRender.Free;
    LStore.Free;
    LProject.Free;
  end;
end;

procedure RunVisualConfirm(const ADir, ARationale: string);
var
  LStore: TAsWishStoreService;
  LDecService: TAsWishDecisionsService;
  LSnap: TAsWishSnapshotService;
  LDiff: TAsWishDifferenceService;
  LWorkflow: TAsWishVisualWorkflowService;
  LDecId, LBaseId: string;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[visual] error: no .AsWish directory');
    Halt(1);
  end;
  LStore := TAsWishStoreService.Create;
  try
    LStore.Initialize(ADir);
    LSnap := TAsWishSnapshotService.Create(LStore);
    try
      LDecService := TAsWishDecisionsService.Create;
      try
        LDecService.Initialize(TPath.Combine(ADir, '.AsWish'));
        LDecService.Load;
        LDiff := TAsWishDifferenceService.Create(LStore, LSnap);
        try
          LWorkflow := TAsWishVisualWorkflowService.Create(LStore, LSnap, LDecService, LDiff);
          try
            // If ARationale is an existing Decision ID, use it directly
            if (ARationale <> '') and (LDecService.FindById(ARationale).Id <> '') then
              LDecId := ARationale
            else
            begin
              var LView := LStore.ReadTreeFile('trees/view-tree.yaml');
              if (LView = nil) or (LView.Count = 0) then
              begin
                if LView <> nil then LView.Free;
                Writeln('[visual confirm] error: no View Spec nodes to confirm');
                Halt(1);
              end;
              var LViewIds := TList<string>.Create;
              try
                for var LN in LView do LViewIds.Add(LN.Id);
                var LRat := ARationale;
                if LRat = '' then LRat := 'CLI visual confirm.';
                LDecId := LDecService.AddDecision(dtConfirm,
                  'Accepted Visual Baseline for View Spec',
                  'Human confirmed current View Spec representation (wireframe-v1.0) as Accepted Visual Baseline.',
                  LRat, LViewIds.ToArray);
                LDecService.AcceptDecision(LDecId);
                LDecService.Save;
              finally
                LViewIds.Free;
                LView.Free;
              end;
            end;
            LBaseId := LWorkflow.ConfirmVisualBaseline(LDecId);
            Writeln(Format('[visual confirm] created Accepted Visual Baseline %s (decision: %s)',
              [LBaseId, LDecId]));
          finally
            LWorkflow.Free;
          end;
        finally
          LDiff.Free;
        end;
      finally
        LDecService.Free;
      end;
    finally
      LSnap.Free;
    end;
  finally
    LStore.Free;
  end;
end;

procedure RunHandoff(const ADir, ABaselineId: string);
var
  LStore: TAsWishStoreService;
  LSnap: TAsWishSnapshotService;
  LDecService: TAsWishDecisionsService;
  LDiff: TAsWishDifferenceService;
  LWorkflow: TAsWishVisualWorkflowService;
  LBaseId, LFile: string;
begin
  if not TDirectory.Exists(TPath.Combine(ADir, '.AsWish')) then
  begin
    Writeln('[handoff] error: no .AsWish directory');
    Halt(1);
  end;
  LBaseId := ABaselineId;
  if LBaseId = '' then LBaseId := 'B-0001';
  LStore := TAsWishStoreService.Create;
  try
    LStore.Initialize(ADir);
    LSnap := TAsWishSnapshotService.Create(LStore);
    try
      LDecService := TAsWishDecisionsService.Create;
      try
        LDecService.Initialize(TPath.Combine(ADir, '.AsWish'));
        LDecService.Load;
        LDiff := TAsWishDifferenceService.Create(LStore, LSnap);
        try
          LWorkflow := TAsWishVisualWorkflowService.Create(LStore, LSnap, LDecService, LDiff);
          try
            LFile := LWorkflow.ExportAgentHandoff(ADir, LBaseId);
            Writeln('[handoff] exported agent handoff package to ' + LFile);
          finally
            LWorkflow.Free;
          end;
        finally
          LDiff.Free;
        end;
      finally
        LDecService.Free;
      end;
    finally
      LSnap.Free;
    end;
  finally
    LStore.Free;
  end;
end;

procedure RunEvidenceCollect(const AProjectDir, ABaselineId: string);
var
  LStore: TAsWishStoreService;
  LSnapshot: TAsWishSnapshotService;
  LCollector: TAsWishEvidenceCollectorService;
  LEvidences: TArray<TSpecEvidence>;
begin
  LStore := TAsWishStoreService.Create;
  try
    LStore.Initialize(AProjectDir);
    LSnapshot := TAsWishSnapshotService.Create(LStore);
    try
      LCollector := TAsWishEvidenceCollectorService.Create(LStore, LSnapshot);
      try
        LEvidences := LCollector.CollectImplementationEvidence(AProjectDir, ABaselineId);
        Writeln(Format('Collected %d implementation evidence item(s) to .AsWish/evidence/implementation-evidence.yaml',
          [Length(LEvidences)]));
        for var LEv in LEvidences do
          Writeln(Format('  - %s: %s (lines: %s, hash: %s)',
            [LEv.Id, LEv.Path, LEv.Lines, Copy(LEv.SourceFileHash, 1, 12)]));
      finally
        LCollector.Free;
      end;
    finally
      LSnapshot.Free;
    end;
  finally
    LStore.Free;
  end;
end;

procedure RunDifference(const AProjectDir, ABaselineId: string);
var
  LStore: TAsWishStoreService;
  LSnapshot: TAsWishSnapshotService;
  LDecisions: TAsWishDecisionsService;
  LDifference: TAsWishDifferenceService;
  LWorkflow: TAsWishVisualWorkflowService;
  LReport: TSpecDifferenceReport;
begin
  LStore := TAsWishStoreService.Create;
  try
    LStore.Initialize(AProjectDir);
    LSnapshot := TAsWishSnapshotService.Create(LStore);
    try
      LDecisions := TAsWishDecisionsService.Create;
      try
        LDecisions.Initialize(TPath.Combine(AProjectDir, '.AsWish'));
        LDecisions.Load;
        LDifference := TAsWishDifferenceService.Create(LStore, LSnapshot);
        try
          LWorkflow := TAsWishVisualWorkflowService.Create(LStore, LSnapshot, LDecisions, LDifference);
          try
            LReport := LWorkflow.ComputeDifference(AProjectDir, ABaselineId);
            Writeln(Format('Computed difference report against baseline "%s" (tree: %s):',
              [LReport.BaselineId, LReport.TreeType]));
            if Length(LReport.Items) = 0 then
              Writeln('  No structural differences found (0 items).')
            else
            begin
              Writeln(Format('  Found %d structural difference(s):', [Length(LReport.Items)]));
              for var LItem in LReport.Items do
              begin
                var LAspectStr := '';
                if LItem.Kind = dkChanged then
                  LAspectStr := ' (' + TSpecEnums.DifferenceAspectToStr(LItem.ChangedAspect) + ')';
                Writeln(Format('  - [%s%s] node: %s (baseline: %s, live/ev: %s)',
                  [TSpecEnums.DifferenceKindToStr(LItem.Kind), LAspectStr, LItem.NodeId,
                   Copy(LItem.BaselineHash, 1, 8), Copy(LItem.EvidenceHash, 1, 8)]));
              end;
            end;
            Writeln('Saved difference report to .AsWish/difference.yaml');
            var LRender := TAsWishRenderService.Create;
            try
              LRender.Initialize(TPath.Combine(AProjectDir, '.AsWish'));
              LRender.RenderDifferencePage(LReport, ExtractFileName(ExcludeTrailingPathDelimiter(AProjectDir)));
              LRender.RenderDecisionsPage(LDecisions.Decisions.ToArray, ExtractFileName(ExcludeTrailingPathDelimiter(AProjectDir)));
              Writeln('Rendered difference report to .AsWish/html/difference.html');
            finally
              LRender.Free;
            end;
          finally
            LWorkflow.Free;
          end;
        finally
          LDifference.Free;
        end;
      finally
        LDecisions.Free;
      end;
    finally
      LSnapshot.Free;
    end;
  finally
    LStore.Free;
  end;
end;

procedure RunJudge(const AProjectDir, ABaselineId, AAction, ANote: string);
var
  LStore: TAsWishStoreService;
  LSnapshot: TAsWishSnapshotService;
  LDifference: TAsWishDifferenceService;
  LDecisions: TAsWishDecisionsService;
  LWorkflow: TAsWishVisualWorkflowService;
  LReport: TSpecDifferenceReport;
  LDecId: string;
  LJudgment: TDifferenceJudgment;
begin
  LStore := TAsWishStoreService.Create;
  try
    LStore.Initialize(AProjectDir);
    LSnapshot := TAsWishSnapshotService.Create(LStore);
    try
      LDecisions := TAsWishDecisionsService.Create;
      try
        LDecisions.Initialize(TPath.Combine(AProjectDir, '.AsWish'));
        LDecisions.Load;
        LDifference := TAsWishDifferenceService.Create(LStore, LSnapshot);
        try
          LWorkflow := TAsWishVisualWorkflowService.Create(LStore, LSnapshot, LDecisions, LDifference);
          try
            LReport := LWorkflow.ComputeDifference(AProjectDir, ABaselineId);
            LJudgment := TSpecEnums.DifferenceJudgmentFromStr(AAction);
            LDecId := LWorkflow.RecordDifferenceDecision(LReport, LJudgment, ANote);
            Writeln(Format('Recorded human judgment decision "%s" (%s) for baseline %s (%d difference items).',
              [LDecId, AAction, ABaselineId, Length(LReport.Items)]));
            var LRender := TAsWishRenderService.Create;
            try
              LRender.Initialize(TPath.Combine(AProjectDir, '.AsWish'));
              LRender.RenderDifferencePage(LReport, ExtractFileName(ExcludeTrailingPathDelimiter(AProjectDir)));
              LRender.RenderDecisionsPage(LDecisions.Decisions.ToArray, ExtractFileName(ExcludeTrailingPathDelimiter(AProjectDir)));
              Writeln('Rendered decisions history to .AsWish/html/decisions.html');
            finally
              LRender.Free;
            end;
          finally
            LWorkflow.Free;
          end;
        finally
          LDifference.Free;
        end;
      finally
        LDecisions.Free;
      end;
    finally
      LSnapshot.Free;
    end;
  finally
    LStore.Free;
  end;
end;

procedure RunEvolve(const AProjectDir, ABaselineId, ANote: string);
var
  LStore: TAsWishStoreService;
  LSnapshot: TAsWishSnapshotService;
  LDifference: TAsWishDifferenceService;
  LDecisions: TAsWishDecisionsService;
  LWorkflow: TAsWishVisualWorkflowService;
  LReport: TSpecDifferenceReport;
  LDecId, LNewBaseId: string;
  LNewBaseline: TAsWishBaseline;
begin
  LStore := TAsWishStoreService.Create;
  try
    LStore.Initialize(AProjectDir);
    LSnapshot := TAsWishSnapshotService.Create(LStore);
    try
      LDecisions := TAsWishDecisionsService.Create;
      try
        LDecisions.Initialize(TPath.Combine(AProjectDir, '.AsWish'));
        LDecisions.Load;
        LDifference := TAsWishDifferenceService.Create(LStore, LSnapshot);
        try
          LWorkflow := TAsWishVisualWorkflowService.Create(LStore, LSnapshot, LDecisions, LDifference);
          try
            LReport := LWorkflow.ComputeDifference(AProjectDir, ABaselineId);
            LDecId := LWorkflow.RecordDifferenceDecision(LReport, djAcceptable, ANote, 'cs-evolve-' + ABaselineId);
            LNewBaseId := LWorkflow.EvolveBaseline(ABaselineId, LDecId, LNewBaseline);
            Writeln(Format('Evolved new Accepted Baseline "%s" (snapshot: %s) from current implementation reality.',
              [LNewBaseId, LNewBaseline.SnapshotName]));
            Writeln(Format('  - Decision ID: %s', [LDecId]));
            Writeln(Format('  - Content Hash: %s', [Copy(LNewBaseline.ContentHash, 1, 16)]));
            Writeln(Format('  - Relation Hash: %s', [Copy(LNewBaseline.RelationHash, 1, 16)]));
            var LRender := TAsWishRenderService.Create;
            try
              LRender.Initialize(TPath.Combine(AProjectDir, '.AsWish'));
              LRender.RenderDifferencePage(LReport, ExtractFileName(ExcludeTrailingPathDelimiter(AProjectDir)));
              LRender.RenderDecisionsPage(LDecisions.Decisions.ToArray, ExtractFileName(ExcludeTrailingPathDelimiter(AProjectDir)));
              Writeln('Rendered decisions history to .AsWish/html/decisions.html');
            finally
              LRender.Free;
            end;
          finally
            LWorkflow.Free;
          end;
        finally
          LDifference.Free;
        end;
      finally
        LDecisions.Free;
      end;
    finally
      LSnapshot.Free;
    end;
  finally
    LStore.Free;
  end;
end;

var
  LCommand, LDir: string;
  I: Integer;
  LOpt: string;
begin
  for I := 1 to ParamCount do
  begin
    LOpt := LowerCase(ParamStr(I));
    if (LOpt = '--version') or (LOpt = '-v') or (LOpt = 'version') or (LOpt = '/v') then
    begin
      Writeln(ASWISH_BANNER);
      Halt(0);
    end;
  end;

  ParseCliOptions;

  if ParamCount < 2 then
  begin
    Writeln(ASWISH_BANNER + ' - Headless CLI');
    Writeln('Usage: AsWish.CLI [--version] [--json] <command> <project-dir>');
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
    Writeln('  intent list <dir>         list candidate intents');
    Writeln('  changeset <dir> <id> <tree> <text> generate structured change set');
    Writeln('  changeset accept <dir> [id] [rationale] accept change set & freeze baseline');
    Writeln('  changeset reject <dir> [id] [rationale] reject change set');
    Writeln('  changeset review <dir> [id] review candidate change set');
    Writeln('  baseline list <dir>       list Accepted Baselines');
    Writeln('  baseline verify <dir> <id> verify integrity of Accepted Baseline');
    Writeln('  evidence collect <dir> [baseline-id] collect implementation evidence');
    Writeln('  difference <dir> <baseline-id> compute structural difference');
    Writeln('  judge <dir> <baseline-id> <acceptable|unacceptable|unresolved> [note]');
    Writeln('  evolve <dir> <baseline-id> [note] freeze new baseline from implementation reality');
    Writeln('  visual preview <dir>      render Visual Preview wireframe');
    Writeln('  visual confirm <dir> [txt] confirm Accepted Visual Baseline');
    Writeln('  handoff <dir> [baseline-id] export Agent Handoff package');
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
    var LSub := LowerCase(ParamStr(2));
    if LSub = 'list' then
    begin
      RunIntentList(ParamStr(3));
    end
    else if LowerCase(ParamStr(3)) = 'list' then
    begin
      RunIntentList(ParamStr(2));
    end
    else
    begin
      if ParamCount < 5 then
      begin
        Writeln('AsWish.CLI intent <project-dir> <node-id> <tree> <user_intent>');
        Writeln('  or: AsWish.CLI intent list <project-dir>');
        Halt(2);
      end;
      RunIntent(LDir, ParamStr(3), ParamStr(4), ParamStr(5));
    end;
  end
  else if LCommand = 'changeset' then
  begin
    var LSubAction := LowerCase(ParamStr(2));
    if LSubAction = 'review' then
    begin
      if ParamCount < 3 then
      begin
        Writeln('AsWish.CLI changeset review <project-dir> [changeset-id]');
        Halt(2);
      end;
      RunChangeSetReview(ParamStr(3), ParamStr(4));
    end
    else if LSubAction = 'accept' then
    begin
      if ParamCount < 3 then
      begin
        Writeln('AsWish.CLI changeset accept <project-dir> [changeset-id] [rationale]');
        Halt(2);
      end;
      var LCSId := ParamStr(4);
      var LRationale := ParamStr(5);
      if (ParamCount = 4) and not LCSId.StartsWith('cs-') then
      begin
        LRationale := LCSId;
        LCSId := '';
      end;
      RunChangeSetAccept(ParamStr(3), LCSId, LRationale);
    end
    else if LSubAction = 'reject' then
    begin
      if ParamCount < 3 then
      begin
        Writeln('AsWish.CLI changeset reject <project-dir> [changeset-id] [rationale]');
        Halt(2);
      end;
      var LCSId := ParamStr(4);
      var LRationale := ParamStr(5);
      if (ParamCount = 4) and not LCSId.StartsWith('cs-') then
      begin
        LRationale := LCSId;
        LCSId := '';
      end;
      RunChangeSetReject(ParamStr(3), LCSId, LRationale);
    end
    else if LSubAction = 'clarify' then
    begin
      if ParamCount < 3 then
      begin
        Writeln('AsWish.CLI changeset clarify <project-dir> [changeset-id] <clarification>');
        Halt(2);
      end;
      var LCSId := ParamStr(4);
      var LClarification := ParamStr(5);
      if (ParamCount = 4) and not LCSId.StartsWith('cs-') then
      begin
        LClarification := LCSId;
        LCSId := '';
      end;
      RunChangeSetClarify(ParamStr(3), LCSId, LClarification);
    end
    else
    begin
      if ParamCount < 5 then
      begin
        Writeln('AsWish.CLI changeset <project-dir> <node-id> <tree> <user_intent>');
        Writeln('  or: AsWish.CLI changeset review <project-dir> [changeset-id]');
        Writeln('  or: AsWish.CLI changeset accept <project-dir> [changeset-id] [rationale]');
        Writeln('  or: AsWish.CLI changeset reject <project-dir> [changeset-id] [rationale]');
        Writeln('  or: AsWish.CLI changeset clarify <project-dir> [changeset-id] <clarification>');
        Halt(2);
      end;
      RunChangeSet(LDir, ParamStr(3), ParamStr(4), ParamStr(5));
    end;
  end
  else if LCommand = 'baseline' then
  begin
    var LSub := LowerCase(ParamStr(2));
    if LSub = 'list' then
    begin
      RunBaselineList(ParamStr(3));
    end
    else if LowerCase(ParamStr(3)) = 'list' then
    begin
      RunBaselineList(ParamStr(2));
    end
    else if LSub = 'verify' then
    begin
      if ParamCount < 4 then
      begin
        Writeln('AsWish.CLI baseline verify <project-dir> <baseline-id>');
        Halt(2);
      end;
      RunBaselineVerify(ParamStr(3), ParamStr(4));
    end
    else
    begin
      Writeln('AsWish.CLI baseline list <project-dir>');
      Writeln('  or: AsWish.CLI baseline verify <project-dir> <baseline-id>');
      Halt(2);
    end;
  end
  else if LCommand = 'evidence' then
  begin
    var LSub := LowerCase(ParamStr(2));
    if LSub = 'collect' then
    begin
      if ParamCount < 3 then
      begin
        Writeln('AsWish.CLI evidence collect <project-dir> [baseline-id]');
        Halt(2);
      end;
      RunEvidenceCollect(ParamStr(3), ParamStr(4));
    end
    else
    begin
      Writeln('AsWish.CLI evidence collect <project-dir> [baseline-id]');
      Halt(2);
    end;
  end
  else if (LCommand = 'difference') or (LCommand = 'diff') then
  begin
    if ParamCount < 3 then
    begin
      Writeln('AsWish.CLI difference <project-dir> <baseline-id>');
      Halt(2);
    end;
    RunDifference(ParamStr(2), ParamStr(3));
  end
  else if LCommand = 'judge' then
  begin
    if ParamCount < 4 then
    begin
      Writeln('AsWish.CLI judge <project-dir> <baseline-id> <acceptable|unacceptable|unresolved> [note]');
      Halt(2);
    end;
    RunJudge(ParamStr(2), ParamStr(3), ParamStr(4), ParamStr(5));
  end
  else if LCommand = 'evolve' then
  begin
    if ParamCount < 3 then
    begin
      Writeln('AsWish.CLI evolve <project-dir> <baseline-id> [note]');
      Halt(2);
    end;
    RunEvolve(ParamStr(2), ParamStr(3), ParamStr(4));
  end
  else if LCommand = 'visual' then
  begin
    var LSub := LowerCase(ParamStr(2));
    if LSub = 'preview' then
    begin
      RunVisualPreview(ParamStr(3));
    end
    else if LowerCase(ParamStr(3)) = 'preview' then
    begin
      RunVisualPreview(ParamStr(2));
    end
    else if LSub = 'confirm' then
    begin
      var LRationale := ParamStr(4);
      RunVisualConfirm(ParamStr(3), LRationale);
    end
    else
    begin
      Writeln('AsWish.CLI visual preview <project-dir>');
      Writeln('  or: AsWish.CLI visual confirm <project-dir> [rationale]');
      Halt(2);
    end;
  end
  else if LCommand = 'handoff' then
  begin
    if ParamCount < 2 then
    begin
      Writeln('AsWish.CLI handoff <project-dir> [baseline-id]');
      Halt(2);
    end;
    RunHandoff(ParamStr(2), ParamStr(3));
  end
  else
  begin
    Writeln('AsWish.CLI: unknown command: ' + LCommand);
    Halt(2);
  end;
end.
