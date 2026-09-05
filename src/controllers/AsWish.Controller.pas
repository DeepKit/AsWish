
{ ============================================================================
  AsWish.Controller

  Coordinates the main workflow: open project → scan → generate .AsWish →
  refresh UI. Commands delegate to this controller.
  ============================================================================ }

unit AsWish.Controller;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.UI.Intf,
  AsWish.Services.Project,
  AsWish.Services.Scan,
  AsWish.Services.SpecStore,
  AsWish.Services.Render,
  AsWish.Services.TreeBuilder,
  AsWish.Services.Prompts,
  AsWish.Services.Decisions,
  AsWish.Services.LLM,
  AsWish.Services.Settings,
  AsWish.Services.CandidateIngest,
  AsWish.Services.Snapshot,
  AsWish.Services.Difference,
  AsWish.Services.EvidenceCollector,
  AsWish.Models;

type
  TAsWishController = class
  private
    FProjectService: TAsWishProjectService;
    FScanService: TAsWishScanService;
    FSpecStore: TAsWishStoreService;
    FRender: TAsWishRenderService;
    FTreeBuilder: TAsWishTreeBuilder;
    FPrompts: TAsWishPromptService;
    FDecisions: TAsWishDecisionsService;
    FLLM: TAsWishLLMService;
    FSettings: TAsWishSettingsService;
    FSnapshot: TAsWishSnapshotService;
    FStatus: IShellStatusManager;
    FContext: IShellContextManager;
    FBus: IShellEventBus;
    FDocsFiles: TArray<string>;
    procedure ScanDocsFirst;
    procedure WriteDocsSummary;
    /// <summary>Apply accepted/rejected formal decisions to every tree on
    ///  disk: read tree → ApplyNodeStatusTransitions → write back.
    ///  Shared by PromotePendingDecisions and ApplyBundleDecisions.</summary>
    procedure ApplyAllTreeTransitions;
    /// <summary>Reload the in-memory builder trees from disk after a
    ///  disk-first transition pass (ApplyAllTreeTransitions), so
    ///  RenderAll and FindNodeById see the new state.</summary>
    procedure ReloadInMemoryTrees;
    /// <summary>Defog one node by id (BUG-11 step 2): locate across the 4 trees,
    ///  advance its FogState one step toward clear, persist the owning tree.
    ///  Returns True if the node was found (and defogged if it had fog).</summary>
    function DefogNodeById(const ANodeId: string): Boolean;
    /// <summary>Read issues/doc-issues.yaml for rendering. Returns a caller-owned
    ///  list (empty if no file / no project open). Never nil.</summary>
    function LoadIssuesForRender: TList<TSpecIssue>;
  public
    constructor Create(
      AProjectService: TAsWishProjectService;
      AScanService: TAsWishScanService;
      ASpecStore: TAsWishStoreService;
      ARender: TAsWishRenderService;
      ATreeBuilder: TAsWishTreeBuilder;
      APrompts: TAsWishPromptService;
      ADecisions: TAsWishDecisionsService;
      ALLM: TAsWishLLMService;
      ASettings: TAsWishSettingsService;
      const AStatus: IShellStatusManager;
      const AContext: IShellContextManager;
      const ABus: IShellEventBus);

    procedure OpenAndScan(const APath: string);
    procedure RunScan;
    procedure ExportPrompt;
    procedure GenerateB;
    procedure RenderAll;
    procedure RefreshFromYaml;
    /// <summary>Open an exploration ticket for a fog node (BUG-11 step 2):
    ///  defogs the node one step, validates, persists to
    ///  issues/doc-issues.yaml, and re-renders. No-op if no project open.</summary>
    procedure CreateTicket(const ANodeId, ANodeTitle: string);
    /// <summary>BUG-9 §2.3.4: compute health metrics from the 4 trees + open
    ///  issues, write an optimization prompt (Markdown) into prompts\, and
    ///  report via status. No-op if no project open.</summary>
    procedure ExportOptimizationPrompt;
    /// <summary>Batch bundle review from bundles.html (Accept All /
    ///  Reject All): find the bundle, record one formal human decision over
    ///  all anchored nodes, apply state transitions to every tree, and
    ///  re-render. AAction is 'bundle-accept' or 'bundle-reject'.
    ///  No-op if no project open.</summary>
    procedure ApplyBundleDecisions(const AAction, ABundleId: string);
    procedure PromotePendingDecisions;

    // Natural Language -> Change Set -> Decision Commands (WO-20260830-0027D)
    function SubmitUserIntent(const ANodeId, AIntentText: string): string; overload;
    function SubmitUserIntent(const ANodeId: string; ATree: TTreeType;
      const AIntentText: string): string; overload;
    function ReviewChangeSet(const AChangeSetId: string = ''): string;
    function AcceptChangeSet(const AChangeSetId: string;
      const ARationale: string = ''): Boolean;
    function RejectChangeSet(const AChangeSetId: string;
      const ARationale: string = ''): Boolean;
    function ClarifyChangeSet(const AChangeSetId: string;
      const AClarificationText: string): Boolean;
    function ListCandidateIntents: TArray<TCandidateIntent>;

    // Accepted Baseline & Visual Baseline (WO-20260830-0027E, WO-20260830-0028)
    function VerifyBaseline(const ABaselineId: string): Boolean;
    function ListBaselines: TArray<TAsWishBaseline>;
    function ConfirmVisualBaseline(const ARationale: string = ''): string;

    // Structural Difference, Human Judgment & Evolution (WO-20260905-0029)
    function CollectEvidence(const ABaselineId: string = ''): TArray<TSpecEvidence>;
    function ComputeDifference(const ABaselineId: string): TSpecDifferenceReport;
    function RecordDifferenceDecision(const ABaselineId, AAction, ARationale: string): string;
    function EvolveBaseline(const ABaselineId, ANote: string;
      out ANewBaseline: TAsWishBaseline): string;
    function ListDecisions: TArray<TSpecDecision>;

    destructor Destroy; override;
    function IsProjectOpen: Boolean;
    property ProjectService: TAsWishProjectService read FProjectService;
    property ScanService: TAsWishScanService read FScanService;
    property TreeBuilder: TAsWishTreeBuilder read FTreeBuilder;
    property Decisions: TAsWishDecisionsService read FDecisions;
    property LLM: TAsWishLLMService read FLLM;
    property Settings: TAsWishSettingsService read FSettings;
    property SnapshotService: TAsWishSnapshotService read FSnapshot;
    property DocsFiles: TArray<string> read FDocsFiles;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  AsWish.UI.Types,
  AsWish.Validation,
  AsWish.Yaml.Writer;

constructor TAsWishController.Create(
  AProjectService: TAsWishProjectService;
  AScanService: TAsWishScanService;
  ASpecStore: TAsWishStoreService;
  ARender: TAsWishRenderService;
  ATreeBuilder: TAsWishTreeBuilder;
  APrompts: TAsWishPromptService;
  ADecisions: TAsWishDecisionsService;
  ALLM: TAsWishLLMService;
  ASettings: TAsWishSettingsService;
  const AStatus: IShellStatusManager;
  const AContext: IShellContextManager;
  const ABus: IShellEventBus);
begin
  inherited Create;
  FProjectService := AProjectService;
  FScanService := AScanService;
  FSpecStore := ASpecStore;
  FRender := ARender;
  FTreeBuilder := ATreeBuilder;
  FPrompts := APrompts;
  FDecisions := ADecisions;
  FLLM := ALLM;
  FSettings := ASettings;
  FSnapshot := TAsWishSnapshotService.Create(FSpecStore);
  FStatus := AStatus;
  FContext := AContext;
  FBus := ABus;
end;

destructor TAsWishController.Destroy;
begin
  FSnapshot.Free;
  inherited;
end;

function TAsWishController.IsProjectOpen: Boolean;
begin
  Result := FProjectService.IsOpen;
end;

procedure TAsWishController.OpenAndScan(const APath: string);
begin
  FStatus.Info('AsWish', 'Opening project: ' + APath);

  // Open project
  FProjectService.OpenProject(APath);
  FContext.SetProject(FProjectService.ProjectName, APath);

  // Initialize settings (docs path)
  FSettings.Initialize(APath);

  // Initialize spec store, render, prompts, and decisions services
  FSpecStore.Initialize(APath);
  FRender.Initialize(FProjectService.AsWishPath);
  FPrompts.Initialize(FProjectService.AsWishPath);
  FDecisions.Initialize(FProjectService.AsWishPath);
  FDecisions.Load;

  // Run scan (includes docs-first reading)
  RunScan;
end;

procedure TAsWishController.ExportPrompt;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  FPrompts.WriteContextPack(FScanService, FProjectService.ProjectName,
    FProjectService.ProjectType);
  FPrompts.WriteGenerationPrompt(FProjectService.ProjectName,
    FProjectService.ProjectType);

  FStatus.Info('AsWish.Prompts',
    'Exported prompts to ' + FProjectService.AsWishPath + '\prompts\');
end;

function TAsWishController.LoadIssuesForRender: TList<TSpecIssue>;
begin
  Result := nil;
  if FProjectService.IsOpen then
    Result := FSpecStore.ReadIssuesFile('issues/doc-issues.yaml');
  if Result = nil then
    Result := TList<TSpecIssue>.Create;
end;

function TAsWishController.DefogNodeById(const ANodeId: string): Boolean;

  // Search one tree; if the node is found and still has fog, advance its
  // FogState one step, write the node back, persist the owning tree file.
  // Returns True only when a defog actually happened.
  function TryDefog(ANodes: TList<TSpecNode>;
    const ARel: string; ATree: TTreeType): Boolean;
  var
    I: Integer;
    LN: TSpecNode;
  begin
    Result := False;
    if ANodes = nil then Exit;
    for I := 0 to ANodes.Count - 1 do
      if ANodes[I].Id = ANodeId then
      begin
        LN := ANodes[I];
        if LN.HasFogState and (LN.FogState <> AsWish.Models.fsClear) then
        begin
          LN.FogState := AsWish.Models.TSpecEnums.DefogOneStep(LN.FogState);
          LN.UpdatedAt := Now;
          ANodes[I] := LN;
          FSpecStore.WriteTreeFile(ARel, ATree, ANodes);
          Result := True;
        end;
        Exit;
      end;
  end;

begin
  Result := False;
  if not FProjectService.IsOpen then Exit;

  // Node ids are unique across trees; the first hit wins. A node already at
  // clear yields no defog, but the ticket was still created against it.
  Result := TryDefog(FTreeBuilder.FunctionNodes, 'trees/function-tree.yaml', ttFunction)
    or TryDefog(FTreeBuilder.ModuleNodes, 'trees/module-tree.yaml', ttModule)
    or TryDefog(FTreeBuilder.ViewNodes, 'trees/view-tree.yaml', ttView)
    or TryDefog(FTreeBuilder.DataNodes, 'trees/data-tree.yaml', ttData);
end;

procedure TAsWishController.CreateTicket(const ANodeId, ANodeTitle: string);
var
  LIssues: TList<TSpecIssue>;
  LIssue: TSpecIssue;
  LMaxNum, LN: Integer;
  LId: string;
  LWriter: TYamlWriter;
  LReport: TValidationReport;
  LFoundNode: TSpecNode;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open — cannot create ticket');
    Exit;
  end;

  // Locate the fog node (value copy). Empty Id => not found.
  LFoundNode := FTreeBuilder.FindNodeById(ANodeId);
  if LFoundNode.Id = '' then
  begin
    FStatus.LogError('AsWish', 'Cannot create ticket: node not found: ' + ANodeId, '');
    Exit;
  end;

  // Build the ticket with research defaults (AFK-eligible exploration).
  // id = issue-<next ordinal>, deduped against existing issues.
  LIssues := FSpecStore.ReadIssuesFile('issues/doc-issues.yaml');
  try
    LMaxNum := 0;
    for var LExisting in LIssues do
    begin
      var LRest := LExisting.Id;
      if LRest.StartsWith('issue-', True) then
        LRest := LRest.Substring('issue-'.Length);
      if TryStrToInt(LRest, LN) and (LN > LMaxNum) then
        LMaxNum := LN;
    end;
    LId := 'issue-' + (LMaxNum + 1).ToString;

    LIssue := Default(TSpecIssue);
    LIssue.Id := LId;
    LIssue.Severity := AsWish.Models.isMedium;
    LIssue.IssueType := AsWish.Models.itResearchTicket;
    if ANodeTitle <> '' then
      LIssue.Title := 'Research: ' + ANodeTitle
    else
      LIssue.Title := 'Research: ' + ANodeId;
    LIssue.Description := 'Explore foggy requirement endpoint ' + ANodeId +
      ' and converge its fog state toward clear.';
    SetLength(LIssue.AffectedNodes, 1);
    LIssue.AffectedNodes[0] := ANodeId;
    LIssue.Status := AsWish.Models.issOpen;
    LIssue.HasRequiresHuman := True;
    LIssue.RequiresHuman := False; // research ticket is AFK-eligible by default
    LIssue.CreatedAt := Now;
    LIssue.UpdatedAt := Now;
    LIssues.Add(LIssue);

    // Validate the assembled YAML before persisting (BUG-11 step 1 layer).
    LWriter := TYamlWriter.Create;
    try
      LWriter.WriteIssuesFile(LIssues);
      var LYaml := LWriter.ToString;
      var LValidator := TYamlValidator.Create;
      try
        LReport := LValidator.ValidateIssuesFile(LYaml);
        if LReport.HasErrors then
        begin
          var LMsg := 'Ticket validation failed — not persisted: ';
          for var LR in LReport.Errors do
            if LR.Severity = vsError then
              LMsg := LMsg + LR.Rule + ' ';
          LMsg := TrimRight(LMsg);
          FStatus.LogError('AsWish', LMsg,
            TPath.Combine(FProjectService.AsWishPath, 'issues\doc-issues.yaml'));
          Exit;
        end;
      finally
        LValidator.Free;
      end;

      FSpecStore.WriteIssuesFile('issues/doc-issues.yaml', LIssues);
    finally
      LWriter.Free;
    end;
  finally
    LIssues.Free;
  end;

  // Defog the node one step + persist the owning tree.
  DefogNodeById(ANodeId);

  // Re-render so the Fog Map and Open Tickets reflect the new state.
  RenderAll;

  FStatus.Info('AsWish',
    'Created ticket ' + LId + ' for node ' + ANodeId +
    ' (defogged one step). See issues/doc-issues.yaml.');
end;

procedure TAsWishController.ExportOptimizationPrompt;
var
  LIssues: TList<TSpecIssue>;
  LM: THealthMetrics;
  LConflicts: Integer;
  LDir, LPath: string;
  LSb: TStringBuilder;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open — cannot export prompt');
    Exit;
  end;

  // Compute metrics from the in-memory trees + persisted issues (same sources
  // as the index dashboard), so the prompt and the dashboard agree.
  LIssues := LoadIssuesForRender;
  LSb := TStringBuilder.Create;
  try
    LM := TAsWishRenderService.ComputeHealthMetrics(FTreeBuilder.FunctionNodes,
      FTreeBuilder.ModuleNodes, FTreeBuilder.ViewNodes,
      FTreeBuilder.DataNodes, LIssues);
    LConflicts := TAsWishRenderService.CountCrossTreeConflicts(FTreeBuilder.FunctionNodes,
      FTreeBuilder.ModuleNodes, FTreeBuilder.ViewNodes,
      FTreeBuilder.DataNodes);

    LSb.AppendLine('# AsWish 文档优化 Prompt');
    LSb.AppendLine;
    LSb.AppendLine('> 旁路工具原则：AsWish 只做诊断，不改源代码。把本 Prompt 拷给原 AI 开发工具，优化底层规格文件。');
    LSb.AppendLine;
    LSb.AppendLine('## 当前健康度快照');
    LSb.AppendLine('- 覆盖率（已确认节点占比）：' + FormatFloat('0.0', LM.CoveragePct) + '%');
    LSb.AppendLine('- 平均置信度：' + FormatFloat('0', LM.AvgConfidence * 100.0) + '%');
    LSb.AppendLine('- 决策积压（未决 issue 数）：' + LM.DecisionBacklog.ToString);
    LSb.AppendLine('- 雾区数：' + LM.FogCount.ToString);
    LSb.AppendLine('- 高风险未决 issue 数：' + LM.HighRiskOpen.ToString);
    LSb.AppendLine('- 跨树断引用：' + LConflicts.ToString + ' 处');
    LSb.AppendLine;
    LSb.AppendLine('## 优化目标');
    if LM.DecisionBacklog > 0 then
      LSb.AppendLine('- 处理积压决策：逐个 issue 给出结论并 close。当前积压 ' +
        LM.DecisionBacklog.ToString + ' 个。');
    if LM.FogCount > 0 then
      LSb.AppendLine('- 探索雾区：对 ' + LM.FogCount.ToString +
        ' 个迷雾节点补一个 research_ticket / prototype，把信息从迷雾拉到迷雾→清晰。');
    if LM.HighRiskOpen > 0 then
      LSb.AppendLine('- 优先处理 ' + LM.HighRiskOpen.ToString +
        ' 个高风险/critical issue（见 problems.html）。');
    if LConflicts > 0 then
      LSb.AppendLine('- 修复 ' + LConflicts.ToString +
        ' 处跨树断引用（模块树/视图树引用了不存在的节点）。');
    if LM.CoveragePct < 70.0 then
      LSb.AppendLine('- 提升覆盖率：当前仅 ' + FormatFloat('0.0', LM.CoveragePct) +
        '%，目标 ≥70%。补充已有节点的确认证据。');
    LSb.AppendLine;
    LSb.AppendLine('## 要求');
    LSb.AppendLine('1. 只改 .AsWish/ 下的规格文件（tree/issues/docs），不改源代码。');
    LSb.AppendLine('2. 每次改动后给出 diff 摘要，便于 AsWish 重新扫描对照。');
    LSb.AppendLine('3. 优先级：高风险 issue > 断引用 > 雾区 > 覆盖率/置信度。');

    LDir := TPath.Combine(FProjectService.AsWishPath, 'prompts');
    TDirectory.CreateDirectory(LDir);
    LPath := TPath.Combine(LDir, 'optimization-prompt.md');
    TFile.WriteAllText(LPath, LSb.ToString, TEncoding.UTF8);

    FStatus.Info('AsWish',
      'Exported optimization prompt to ' + LPath +
      ' (coverage=' + FormatFloat('0.0', LM.CoveragePct) +
      '% backlog=' + LM.DecisionBacklog.ToString + ')');
  finally
    LIssues.Free;
    LSb.Free;
  end;
end;

procedure TAsWishController.RenderAll;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  try
    FRender.RenderScanReport(FScanService, FProjectService.ProjectName,
      FProjectService.ProjectType);
    var LIssuesR := LoadIssuesForRender;
    try
      FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
        FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesR,
        FTreeBuilder.DataNodes.Count > 0);
      FRender.RenderTree('function-tree', 'Function Tree', FTreeBuilder.FunctionNodes);
      FRender.RenderTree('module-tree', 'Module Tree', FTreeBuilder.ModuleNodes);
      FRender.RenderTree('view-tree', 'View Tree', FTreeBuilder.ViewNodes);
      if FTreeBuilder.DataNodes.Count > 0 then
        FRender.RenderTree('data-tree', 'Data Tree', FTreeBuilder.DataNodes);
      FRender.RenderProblemsPage(FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesR);
    finally
      LIssuesR.Free;
    end;

    var LBundlePath := TPath.Combine(FProjectService.AsWishPath, 'bundles.yaml');
    if TFile.Exists(LBundlePath) then
    begin
      var LBundles := FSpecStore.ReadBundlesFile(LBundlePath);
      try
        FRender.RenderBundlesPage(LBundles, FTreeBuilder.FunctionNodes,
          FTreeBuilder.ModuleNodes, FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes);
      finally
        LBundles.Free;
      end;
    end;

    // Render active ChangeSet review page if present
    var LIngestR := TAsWishCandidateIngest.Create(FSpecStore);
    try
      var LCSR := LIngestR.LoadChangeSet(FProjectService.ProjectPath, '');
      if LCSR.Id <> '' then
        FRender.RenderChangeSetReviewPage(LCSR, FTreeBuilder.FunctionNodes, FProjectService.ProjectName);
    finally
      LIngestR.Free;
    end;

    // Render deterministic Visual Preview wireframe (WO-20260830-0028)
    FRender.RenderVisualPreview(FTreeBuilder.ViewNodes, FProjectService.ProjectName);

    // Render requirement decisions history page (WO-20260905-0029)
    FRender.RenderDecisionsPage(ListDecisions, FProjectService.ProjectName);

    FStatus.Info('AsWish.Render',
      'Re-rendered HTML to ' + FProjectService.AsWishPath + '\html\');
  except
    on E: Exception do
      FStatus.LogError('AsWish.Render', 'Render failed: ' + E.Message, E.ClassName);
  end;
end;

procedure TAsWishController.RefreshFromYaml;
var
  LFunc, LModule, LView, LData: TList<TSpecNode>;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  LFunc := nil;
  LModule := nil;
  LView := nil;
  LData := nil;
  try
    try
      LFunc := FSpecStore.ReadTreeFile('trees/function-tree.yaml');
      LModule := FSpecStore.ReadTreeFile('trees/module-tree.yaml');
      LView := FSpecStore.ReadTreeFile('trees/view-tree.yaml');
      if TFile.Exists(TPath.Combine(FProjectService.AsWishPath, 'trees\data-tree.yaml')) then
        LData := FSpecStore.ReadTreeFile('trees/data-tree.yaml');

      // Reload path: data tree presence follows the loaded LData, not
      // FTreeBuilder (which may be stale here). Mirrors the render guard below.
      var LIssuesR := LoadIssuesForRender;
      try
        FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
          LFunc, LModule, LView, LData, LIssuesR,
          (LData <> nil) and (LData.Count > 0));
        FRender.RenderTree('function-tree', 'Function Tree', LFunc);
        FRender.RenderTree('module-tree', 'Module Tree', LModule);
        FRender.RenderTree('view-tree', 'View Tree', LView);
        if (LData <> nil) and (LData.Count > 0) then
          FRender.RenderTree('data-tree', 'Data Tree', LData);
        FRender.RenderProblemsPage(LFunc, LModule, LView, LData, LIssuesR);
      finally
        LIssuesR.Free;
      end;

      // Bundles page
      var LBundlePath := TPath.Combine(FProjectService.AsWishPath, 'bundles.yaml');
      if TFile.Exists(LBundlePath) then
      begin
        var LBundles := FSpecStore.ReadBundlesFile(LBundlePath);
        try
          FRender.RenderBundlesPage(LBundles, LFunc, LModule, LView, LData);
        finally
          LBundles.Free;
        end;
      end;

      var LMsg := Format('Refreshed HTML from YAML: %d func / %d module / %d view',
        [LFunc.Count, LModule.Count, LView.Count]);
      if LData <> nil then
        LMsg := LMsg + Format(' / %d data nodes.', [LData.Count])
      else
        LMsg := LMsg + '.';
      FStatus.Info('AsWish.Render', LMsg);
    except
      on E: Exception do
        FStatus.LogError('AsWish.Render', 'RefreshFromYaml failed: ' + E.Message,
          E.ClassName);
    end;
  finally
    LFunc.Free;
    LModule.Free;
    LView.Free;
    LData.Free;
  end;
end;

procedure TAsWishController.PromotePendingDecisions;
var
  LCount: Integer;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  try
    LCount := FDecisions.PromotePending;
    if LCount = 0 then
    begin
      FStatus.Info('AsWish.Decisions', 'No pending decisions to promote.');
      Exit;
    end;

    FStatus.Info('AsWish.Decisions',
      Format('Promoted %d pending decision(s) to formal decisions.', [LCount]));

    // Apply state machine transitions to all trees
    ApplyAllTreeTransitions;
    ReloadInMemoryTrees;
  except
    on E: Exception do
      FStatus.LogError('AsWish.Decisions',
        'Promote failed: ' + E.Message, E.ClassName);
  end;
end;

procedure TAsWishController.ReloadInMemoryTrees;
var
  LFunc, LModule, LView, LData: TList<TSpecNode>;
begin
  LFunc := FSpecStore.ReadTreeFile('trees/function-tree.yaml');
  LModule := FSpecStore.ReadTreeFile('trees/module-tree.yaml');
  LView := FSpecStore.ReadTreeFile('trees/view-tree.yaml');
  LData := FSpecStore.ReadTreeFile('trees/data-tree.yaml');
  try
    FTreeBuilder.FunctionNodes.Clear;
    FTreeBuilder.FunctionNodes.AddRange(LFunc);
    FTreeBuilder.ModuleNodes.Clear;
    FTreeBuilder.ModuleNodes.AddRange(LModule);
    FTreeBuilder.ViewNodes.Clear;
    FTreeBuilder.ViewNodes.AddRange(LView);
    FTreeBuilder.DataNodes.Clear;
    FTreeBuilder.DataNodes.AddRange(LData);
  finally
    LData.Free;
    LView.Free;
    LModule.Free;
    LFunc.Free;
  end;
end;

procedure TAsWishController.ApplyAllTreeTransitions;
var
  LTreeNames: TArray<string>;
begin
  LTreeNames := TArray<string>.Create(
    'trees/function-tree.yaml', 'trees/module-tree.yaml',
    'trees/view-tree.yaml', 'trees/data-tree.yaml');

  for var LTree in LTreeNames do
  begin
    if not TFile.Exists(TPath.Combine(FProjectService.AsWishPath, LTree)) then Continue;

    // Read and write back transitions inline
    var LNodes := FSpecStore.ReadTreeFile(LTree);
    try
      if LNodes <> nil then
      begin
        if LNodes.Count = 0 then
          // Empty tree (e.g. no view nodes in a backend-only project):
          // nothing to transition, nothing to write back.
          Continue;
        FDecisions.ApplyNodeStatusTransitions(LTree, LNodes);
        FSpecStore.WriteTreeFile(LTree, LNodes[0].Tree, LNodes);
      end;
    finally
      LNodes.Free;
    end;
  end;
end;

procedure TAsWishController.ApplyBundleDecisions(
  const AAction, ABundleId: string);
var
  LBundles: TList<TSemanticBundle>;
  LFound: Boolean;
  LDecisionType: TDecisionType;
  LDecId: string;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open — cannot review bundles');
    Exit;
  end;

  if (AAction <> 'bundle-accept') and (AAction <> 'bundle-reject') then
  begin
    FStatus.LogError('AsWish', 'Unknown bundle action: ' + AAction, '');
    Exit;
  end;

  LBundles := FSpecStore.ReadBundlesFile('bundles.yaml');
  try
    LFound := False;
    for var LB in LBundles do
    begin
      if LB.Id <> ABundleId then Continue;
      LFound := True;
      if Length(LB.NodeIds) = 0 then
      begin
        FStatus.LogError('AsWish', 'Bundle has no anchored nodes: ' + ABundleId, '');
        Exit;
      end;

      if AAction = 'bundle-accept' then
        LDecisionType := dtConfirm
      else
        LDecisionType := dtReject;

      // One formal human decision covering every anchored node; status set
      // immediately so ApplyAllTreeTransitions sees it (same flow as
      // PromotePendingDecisions for node-confirm/node-reject).
      LDecId := FDecisions.AddDecision(LDecisionType,
        (IfThen(AAction = 'bundle-accept', 'Accept bundle: ',
          'Reject bundle: ') + LB.Title),
        AAction + ' (bundle: ' + ABundleId + ')',
        'Recorded via WebView2 JS Bridge (batch review)', LB.NodeIds);
      if AAction = 'bundle-accept' then
        FDecisions.AcceptDecision(LDecId)
      else
        FDecisions.RejectDecision(LDecId);

      ApplyAllTreeTransitions;
      // Disk-first pass leaves the in-memory builder trees stale; reload
      // them so RenderAll / FindNodeById reflect the new state.
      ReloadInMemoryTrees;
      RenderAll;

      FStatus.Info('AsWish',
        Format('%s bundle %s (%d nodes): %s',
          [IfThen(AAction = 'bundle-accept', 'Accepted', 'Rejected'),
           ABundleId, Length(LB.NodeIds), LDecId]));
      Break;
    end;

    if not LFound then
      FStatus.LogError('AsWish', 'Bundle not found: ' + ABundleId, '');
  finally
    LBundles.Free;
  end;
end;

procedure TAsWishController.GenerateB;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  if not FLLM.IsAvailable then
  begin
    FStatus.Warning('AsWish.LLM',
      'LLM not configured. Configure it in AsWish settings (LLM tab) or ' +
      'use Export Prompt to copy the prompt to your external AI tool.');
    Exit;
  end;

  // Run async to avoid blocking UI
  FStatus.TaskStart('llm-gen', 'AsWish.LLM',
    'Calling LLM to generate B (this may take 10-60 seconds)...');

  var LLLMRef := FLLM; // capture before thread
  var LAsWishPath := FProjectService.AsWishPath;

  TThread.CreateAnonymousThread(
    procedure
    var
      LContextPath: string;
      LPrompt: string;
      LResult: TAsWishLLMResult;
      LStatus: IShellStatusManager;
      LCandidatePath: string;
    begin
      LStatus := FStatus; // capture
      LCandidatePath := TPath.Combine(LAsWishPath, 'llm\candidate-output.yaml');
      LContextPath := TPath.Combine(LAsWishPath, 'prompts\context-pack.md');

      try
        if TFile.Exists(LContextPath) then
          LPrompt := TFile.ReadAllText(LContextPath, TEncoding.UTF8)
        else
        begin
          var LErrProc: TThreadProcedure :=
            procedure
            begin
              LStatus.LogError('AsWish.LLM',
                'Context pack not found. Run scan first.', LContextPath);
              LStatus.TaskFinish('llm-gen', 'Failed: no context pack');
            end;
          TThread.Synchronize(nil, LErrProc);
          Exit;
        end;

        LResult := LLLMRef.Generate(LPrompt);

        var LQueueProc: TThreadProcedure :=
          procedure
          begin
            // Ensure llm directory exists
            var LDir := TPath.GetDirectoryName(LCandidatePath);
            if not TDirectory.Exists(LDir) then
              TDirectory.CreateDirectory(LDir);

            if LResult.Success then
            begin
              TFile.WriteAllText(LCandidatePath, LResult.Content, TEncoding.UTF8);
              // BUG-8 close the loop: ingest candidate through the strongly-
              // typed sandbox, merge into live trees, persist, and re-render.
              // All on the UI thread (we are inside TThread.Queue). Failure
              // here must not unwind the already-written candidate — log and
              // let the user RefreshFromYaml manually as a fallback.
              try
                var LCand := TAsWishCandidateIngest.Create(FSpecStore);
                try
                  var LIngest := LCand.Ingest(LResult.Content,
                    FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
                    FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes);
                  try
                    var LStats := LCand.MergeInto(LIngest.Accepted,
                      FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
                      FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes);

                    // Persist the merged trees so disk matches memory and a
                    // later RefreshFromYaml / next session sees the same state.
                    FSpecStore.WriteTreeFile('trees/function-tree.yaml',
                      ttFunction, FTreeBuilder.FunctionNodes);
                    FSpecStore.WriteTreeFile('trees/module-tree.yaml',
                      ttModule, FTreeBuilder.ModuleNodes);
                    FSpecStore.WriteTreeFile('trees/view-tree.yaml',
                      ttView, FTreeBuilder.ViewNodes);
                    if LIngest.DataNodes.Count > 0 then
                      FSpecStore.WriteTreeFile('trees/data-tree.yaml',
                        ttData, FTreeBuilder.DataNodes);

                    // Fog convergence + re-render from the updated memory trees.
                    RenderAll;

                    LStatus.TaskFinish('llm-gen',
                      Format('LLM done %dms (in/out %d/%d). Ingested %d nodes: %d merged, %d added, %d fog cleared; rejected %d, %d warnings.',
                        [LResult.DurationMs, LResult.InputTokens,
                         LResult.OutputTokens, LIngest.Accepted.Count,
                         LStats.Merged, LStats.Added, LStats.FogCleared,
                         LIngest.Rejected, LIngest.Warnings.Count]));
                  finally
                    LIngest.FreeOwned;
                  end;
                finally
                  LCand.Free;
                end;
              except
                on E: Exception do
                begin
                  LStatus.LogError('AsWish.Candidate',
                    'Candidate ingest/merge failed: ' + E.Message, E.ClassName);
                  LStatus.TaskFinish('llm-gen',
                    Format('LLM done %dms but ingest failed: %s (candidate saved at %s)',
                      [LResult.DurationMs, E.Message, LCandidatePath]));
                end;
              end;
            end
            else
            begin
              LStatus.LogError('AsWish.LLM', 'LLM call failed', LResult.ErrorMessage);
              LStatus.TaskFinish('llm-gen', 'Failed: ' + LResult.ErrorMessage);
            end;
          end;
        TThread.Queue(nil, LQueueProc);
      except
        on E: Exception do
        begin
          var LMsg := E.Message;
          var LExProc: TThreadProcedure :=
            procedure
            begin
              LStatus.LogError('AsWish.LLM', 'LLM exception', LMsg);
              LStatus.TaskFinish('llm-gen', 'Failed: ' + LMsg);
            end;
          TThread.Queue(nil, LExProc);
        end;
      end;
    end).Start;
end;

procedure TAsWishController.ScanDocsFirst;
var
  LDocsPath: string;
  LDocFiles: TArray<string>;
begin
  LDocsPath := FSettings.DocsFullPath;
  if not TDirectory.Exists(LDocsPath) then
  begin
    FStatus.Info('AsWish.Docs', 'No docs directory found at ' + LDocsPath);
    FDocsFiles := nil;
    Exit;
  end;

  FStatus.Progress('scan', 'AsWish.Docs', 5, 'Reading docs from ' + LDocsPath);

  LDocFiles := TDirectory.GetFiles(LDocsPath, '*.md',
    TSearchOption.soAllDirectories);
  var LMoreDocs := TDirectory.GetFiles(LDocsPath, '*.txt',
    TSearchOption.soAllDirectories);

  var LList := TList<string>.Create;
  try
    for var Lf in LDocFiles do
      LList.Add(Lf);
    for var Lf in LMoreDocs do
      LList.Add(Lf);
    FDocsFiles := LList.ToArray;
  finally
    LList.Free;
  end;

  FStatus.Progress('scan', 'AsWish.Docs', 15,
    Format('Found %d document(s) in docs/', [Length(FDocsFiles)]));

  for var I := 0 to High(FDocsFiles) do
    FStatus.Info('AsWish.Docs', '  ' + ExtractFileName(FDocsFiles[I]));
end;

procedure TAsWishController.WriteDocsSummary;
var
  LSb: TStringBuilder;
  LOutPath: string;
begin
  if Length(FDocsFiles) = 0 then Exit;

  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('version: "1.0"');
    LSb.AppendLine('docs_path: "' + FSettings.DocsFullPath.Replace('\', '/') + '"');
    LSb.AppendLine('count: ' + Length(FDocsFiles).ToString);
    LSb.AppendLine('files:');

    for var LFile in FDocsFiles do
    begin
      var LRoot := FSettings.DocsFullPath;
      if not LFile.StartsWith(LRoot, True) then Continue;
      var LRelPath := LFile.Substring(Length(LRoot) + 1);
      LSb.AppendLine('  - path: "' + LRelPath.Replace('\', '/') + '"');
      LSb.AppendLine('    name: "' + ExtractFileName(LFile) + '"');

      // Read first line as title hint
      try
        var LLines := TFile.ReadAllLines(LFile, TEncoding.UTF8);
        if Length(LLines) > 0 then
        begin
          var LTitle := LLines[0].Trim;
          if LTitle.StartsWith('#') then
            LTitle := LTitle.Trim(['#']).Trim;
          LSb.AppendLine('    title: "' + LTitle + '"');
        end;
      except
        LSb.AppendLine('    title: ""');
      end;
    end;

    LOutPath := TPath.Combine(FProjectService.AsWishPath, 'docs-summary.yaml');
    TFile.WriteAllText(LOutPath, LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
  end;
end;

procedure TAsWishController.RunScan;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  var LPath := FProjectService.ProjectPath;
  FStatus.TaskStart('scan', 'AsWish.Scan', 'Scanning ' + LPath);

  try
    // Step 1: Read docs directory first
    ScanDocsFirst;

    // Step 2: Full project scan
    FStatus.Progress('scan', 'AsWish.Scan', 30, 'Scanning project files...');
    FScanService.ScanDirectory(LPath);
    FStatus.Progress('scan', 'AsWish.Scan', 40,
      'Classified ' + FScanService.TotalFiles.ToString + ' files');

    // Step 3: Detect project type
    var LType := 'unknown';
    if FScanService.CategoryCount(fcCode) > 0 then
    begin
      var LCodeFiles := FScanService.GetFilesByCategory(fcCode);
      for var LFile in LCodeFiles do
        if LFile.EndsWith('.pas') or LFile.EndsWith('.dpr') then
        begin
          LType := 'delphi_vcl';
          Break;
        end;
      if LType = 'unknown' then
        for var LFile in LCodeFiles do
        begin
          if LFile.EndsWith('.ts') or LFile.EndsWith('.tsx') then
          begin
            LType := 'web_react';
            Break;
          end;
          if LFile.EndsWith('.py') then
          begin
            LType := 'python_backend';
            Break;
          end;
          if LFile.EndsWith('.go') then
          begin
            LType := 'mixed';
            Break;
          end;
        end;
    end;
    FProjectService.SetProjectType(LType);
    FStatus.Progress('scan', 'AsWish.Scan', 50,
      'Detected project type: ' + LType);

    // Step 4: Write .AsWish structure
    FSpecStore.CreateDirectoryStructure;
    FStatus.Progress('scan', 'AsWish.Scan', 55, 'Writing .AsWish...');
    FSpecStore.WriteScanReport(FScanService);
    FSpecStore.WriteProjectSpec(FProjectService.ProjectName, LType, 0);
    FSpecStore.WriteEmptyTrees;
    FSpecStore.WriteGitIgnore;

    // Write docs summary
    WriteDocsSummary;

    // Step 5: Build trees from scan
    FTreeBuilder.BuildFromScan(FScanService, FProjectService.ProjectName,
      FProjectService.ProjectPath);
    FStatus.Progress('scan', 'AsWish.Scan', 70,
      Format('Building trees (%d modules, %d views, %d data)',
        [FTreeBuilder.ModuleNodes.Count,
         FTreeBuilder.ViewNodes.Count,
         FTreeBuilder.DataNodes.Count]));

    // Write populated trees
    FSpecStore.WriteTreeFile('trees/function-tree.yaml', ttFunction,
      FTreeBuilder.FunctionNodes);
    FSpecStore.WriteTreeFile('trees/module-tree.yaml', ttModule,
      FTreeBuilder.ModuleNodes);
    FSpecStore.WriteTreeFile('trees/view-tree.yaml', ttView,
      FTreeBuilder.ViewNodes);
    if FTreeBuilder.DataNodes.Count > 0 then
      FSpecStore.WriteTreeFile('trees/data-tree.yaml', ttData,
        FTreeBuilder.DataNodes);
    FSpecStore.WriteEvidenceFile('evidence/source-evidence.yaml',
      FTreeBuilder.EvidenceList);

    // Step 6: Render HTML
    FStatus.Progress('scan', 'AsWish.Scan', 85, 'Rendering HTML...');
    FRender.RenderScanReport(FScanService, FProjectService.ProjectName, LType);
    var LIssuesR := LoadIssuesForRender;
    try
      FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
        FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesR,
        FTreeBuilder.DataNodes.Count > 0);
      FRender.RenderTree('function-tree', 'Function Tree', FTreeBuilder.FunctionNodes);
      FRender.RenderTree('module-tree', 'Module Tree', FTreeBuilder.ModuleNodes);
      FRender.RenderTree('view-tree', 'View Tree', FTreeBuilder.ViewNodes);
      if FTreeBuilder.DataNodes.Count > 0 then
        FRender.RenderTree('data-tree', 'Data Tree', FTreeBuilder.DataNodes);
      FRender.RenderProblemsPage(FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesR);
    finally
      LIssuesR.Free;
    end;

    // Bundles page
    var LBundlePath := TPath.Combine(FProjectService.AsWishPath, 'bundles.yaml');
    if TFile.Exists(LBundlePath) then
    begin
      var LBundles := FSpecStore.ReadBundlesFile(LBundlePath);
      try
        FRender.RenderBundlesPage(LBundles, FTreeBuilder.FunctionNodes,
          FTreeBuilder.ModuleNodes, FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes);
      finally
        LBundles.Free;
      end;
    end;

    // Step 6b: Render decisions and difference pages (WO-20260905-0029)
    var LDecList := ListDecisions;
    if Length(LDecList) > 0 then
      FRender.RenderDecisionsPage(LDecList, FProjectService.ProjectName);

    var LBaselines := FSnapshot.ListBaselines;
    if Length(LBaselines) > 0 then
    begin
      try
        ComputeDifference(LBaselines[High(LBaselines)].BaselineId);
      except
        on E: Exception do
          FStatus.Warning('AsWish.Scan', 'Initial difference computation skipped: ' + E.Message);
      end;
    end;

    // Step 7: Generate prompts
    FStatus.Progress('scan', 'AsWish.Scan', 95, 'Generating LLM prompts...');
    FPrompts.WriteContextPack(FScanService, FProjectService.ProjectName, LType);
    FPrompts.WriteGenerationPrompt(FProjectService.ProjectName, LType);

    FStatus.Progress('scan', 'AsWish.Scan', 100, 'Done');
    FStatus.TaskFinish('scan',
      Format('Scan complete: %d files (%d docs, %d code, %d ui, %d config, %d ai_rules) | %d docs in docs/',
        [FScanService.TotalFiles,
         FScanService.CategoryCount(fcDocuments),
         FScanService.CategoryCount(fcCode),
         FScanService.CategoryCount(fcUI),
         FScanService.CategoryCount(fcConfig),
         FScanService.CategoryCount(fcAiRules),
         Length(FDocsFiles)]));

    // Notify UI to refresh
    var LEvent: TDeepShellEvent;
    LEvent := Default(TDeepShellEvent);
    LEvent.Kind := sekProjectOpened;
    LEvent.Context := FContext.Current;
    FBus.Publish(LEvent);
  except
    on E: Exception do
    begin
      FStatus.LogError('AsWish.Scan', 'Scan failed: ' + E.Message, E.ClassName);
      FStatus.TaskFinish('scan', 'Scan failed');
    end;
  end;
end;

function TAsWishController.SubmitUserIntent(const ANodeId, AIntentText: string): string;
begin
  Result := SubmitUserIntent(ANodeId, ttFunction, AIntentText);
end;

function TAsWishController.SubmitUserIntent(const ANodeId: string;
  ATree: TTreeType; const AIntentText: string): string;
var
  LIngest: TAsWishCandidateIngest;
  LIntent: TCandidateIntent;
  LChangeSet: TChangeSet;
  LBundles: TList<TSemanticBundle>;
  LTargetNode: TSpecNode;
  LTreeNodes: TList<TSpecNode>;
  LAffected: TArray<TTreeType>;
  LItem: TChangeItem;
  LChangePath, LPromptPath: string;
  LCSId: string;
begin
  Result := '';
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    LIntent := TCandidateIntent.CreateNew(ANodeId, ATree, AIntentText, 'human');
    LIngest.SaveCandidateIntent(FProjectService.ProjectPath, LIntent);

    // Read bundles for affected projections
    LBundles := FSpecStore.ReadBundlesFile('bundles.yaml');
    try
      case ATree of
        ttFunction: LTreeNodes := FTreeBuilder.FunctionNodes;
        ttModule:   LTreeNodes := FTreeBuilder.ModuleNodes;
        ttView:     LTreeNodes := FTreeBuilder.ViewNodes;
        ttData:     LTreeNodes := FTreeBuilder.DataNodes;
      else
        LTreeNodes := nil;
      end;

      LTargetNode := Default(TSpecNode);
      if LTreeNodes <> nil then
        for var LN in LTreeNodes do
          if LN.Id = ANodeId then
          begin
            LTargetNode := LN;
            Break;
          end;

      LAffected := LIngest.ComputeAffectedProjections(ANodeId, LBundles);

      LCSId := LIngest.GenerateNextChangeSetId(FProjectService.ProjectPath, ANodeId);
      LChangeSet := TChangeSet.CreateNew(LCSId, ANodeId, ATree, AIntentText, 'human');
      LChangeSet.AffectedProjections := LAffected;

      LItem := TChangeItem.CreateItem(ANodeId, ATree, 'summary', LTargetNode.Summary, AIntentText, cstExplicit, 'Interpreted from human user intent');
      LChangeSet.Items := TArray<TChangeItem>.Create(LItem);

      LChangePath := LIngest.SaveChangeSet(FProjectService.ProjectPath, LChangeSet);
      LPromptPath := FPrompts.WriteChangeInterpretPrompt(LIntent, LTargetNode, LBundles);

      // Render the 4-layer review surface
      FRender.RenderChangeSetReviewPage(LChangeSet, FTreeBuilder.FunctionNodes, FProjectService.ProjectName);

      Result := LCSId;
      FStatus.Info('AsWish.ChangeSet', Format('Created ChangeSet %s for %s; Prompt saved at %s',
        [LCSId, ANodeId, LPromptPath]));
    finally
      LBundles.Free;
    end;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.ReviewChangeSet(const AChangeSetId: string): string;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
begin
  Result := '';
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    LCS := LIngest.LoadChangeSet(FProjectService.ProjectPath, AChangeSetId);
    if LCS.Id = '' then
    begin
      Result := 'No change set found.';
      Exit;
    end;
    FRender.RenderChangeSetReviewPage(LCS, FTreeBuilder.FunctionNodes, FProjectService.ProjectName);
    Result := LIngest.FormatChangeSetReviewSummary(LCS, FTreeBuilder.FunctionNodes);
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.AcceptChangeSet(const AChangeSetId, ARationale: string): Boolean;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LDecId: string;
  LDec: TSpecDecision;
  LStats: TMergeStats;
begin
  Result := False;
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    LCS := LIngest.LoadChangeSet(FProjectService.ProjectPath, AChangeSetId);
    if LCS.Id = '' then
    begin
      FStatus.LogError('AsWish.ChangeSet', 'ChangeSet not found: ' + AChangeSetId, '');
      Exit;
    end;

    // Record formal decision
    LDecId := FDecisions.RecordChangeSetDecision(LCS, rsAccepted, ARationale);
    LDec := FDecisions.FindById(LDecId);

    // Apply to live memory trees
    LStats := LIngest.ApplyChangeSet(LCS, LDec,
      FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
      FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes);

    // Write updated trees back to disk (Canonical Spec)
    FSpecStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, FTreeBuilder.FunctionNodes);
    FSpecStore.WriteTreeFile('trees/module-tree.yaml', ttModule, FTreeBuilder.ModuleNodes);
    FSpecStore.WriteTreeFile('trees/view-tree.yaml', ttView, FTreeBuilder.ViewNodes);
    FSpecStore.WriteTreeFile('trees/data-tree.yaml', ttData, FTreeBuilder.DataNodes);

    // Freeze resulting Canonical Spec state into immutable Accepted Baseline (WO-20260830-0027E)
    var LBaseline: TAsWishBaseline;
    var LBaseId := FSnapshot.CreateBaseline(LDec, LCS,
      FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
      FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LBaseline);

    // Re-render
    RenderAll;

    FStatus.Info('AsWish.ChangeSet', Format('Accepted %s -> Decision %s recorded; Baseline %s frozen; %d nodes updated in Canonical Spec',
      [LCS.Id, LDecId, LBaseId, LStats.Merged]));
    Result := True;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.RejectChangeSet(const AChangeSetId, ARationale: string): Boolean;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LDecId: string;
begin
  Result := False;
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    LCS := LIngest.LoadChangeSet(FProjectService.ProjectPath, AChangeSetId);
    if LCS.Id = '' then
    begin
      FStatus.LogError('AsWish.ChangeSet', 'ChangeSet not found: ' + AChangeSetId, '');
      Exit;
    end;

    // Record formal decision with status rejected (Canonical Spec trees remain untouched)
    LDecId := FDecisions.RecordChangeSetDecision(LCS, rsRejected, ARationale);

    FStatus.Info('AsWish.ChangeSet', Format('Rejected %s -> Decision %s recorded (Canonical Spec untouched)',
      [LCS.Id, LDecId]));
    Result := True;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.ClarifyChangeSet(const AChangeSetId, AClarificationText: string): Boolean;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LDecId: string;
begin
  Result := False;
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    LCS := LIngest.LoadChangeSet(FProjectService.ProjectPath, AChangeSetId);
    if LCS.Id = '' then
    begin
      FStatus.LogError('AsWish.ChangeSet', 'ChangeSet not found: ' + AChangeSetId, '');
      Exit;
    end;

    // Record formal decision with status proposed/clarify (Canonical Spec trees remain untouched)
    LDecId := FDecisions.RecordChangeSetDecision(LCS, rsDeferred, AClarificationText);

    FStatus.Info('AsWish.ChangeSet', Format('Clarification requested for %s -> Decision %s recorded',
      [LCS.Id, LDecId]));
    Result := True;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.ListCandidateIntents: TArray<TCandidateIntent>;
var
  LIngest: TAsWishCandidateIngest;
begin
  SetLength(Result, 0);
  if not FProjectService.IsOpen then Exit;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    Result := LIngest.ListCandidateIntents(FProjectService.ProjectPath);
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.VerifyBaseline(const ABaselineId: string): Boolean;
begin
  Result := FSnapshot.VerifyBaseline(ABaselineId);
end;

function TAsWishController.ListBaselines: TArray<TAsWishBaseline>;
begin
  Result := FSnapshot.ListBaselines;
end;

function TAsWishController.ConfirmVisualBaseline(const ARationale: string): string;
var
  LDecId: string;
  LDec: TSpecDecision;
  LBaseline: TAsWishBaseline;
  LCS: TChangeSet;
  LViewIds: TList<string>;
begin
  Result := '';
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  if (FTreeBuilder.ViewNodes = nil) or (FTreeBuilder.ViewNodes.Count = 0) then
  begin
    FStatus.Warning('AsWish.VisualBaseline', 'No View Spec nodes to confirm');
    Exit;
  end;

  // Collect affected view IDs
  LViewIds := TList<string>.Create;
  try
    for var LN in FTreeBuilder.ViewNodes do
      LViewIds.Add(LN.Id);

    var LRat := ARationale;
    if LRat = '' then
      LRat := 'Visual preview confirmed via UI / Decision.';

    LDecId := FDecisions.AddDecision(dtConfirm,
      'Accepted Visual Baseline for View Spec',
      'Human confirmed current View Spec representation (wireframe-v1.0) as Accepted Visual Baseline.',
      LRat, LViewIds.ToArray);
    FDecisions.AcceptDecision(LDecId);
    FDecisions.Save;
    LDec := FDecisions.FindById(LDecId);
  finally
    LViewIds.Free;
  end;

  // Synthesize ChangeSet lineage for baseline
  LCS := TChangeSet.CreateNew('cs-visual-baseline', 'root-view', ttView, 'Confirm Visual Baseline', 'human');

  Result := FSnapshot.CreateBaseline(LDec, LCS,
    FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
    FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes,
    LBaseline, 'wireframe-v1.0', 'html/visual-preview.html');

  RenderAll;

  FStatus.Info('AsWish.VisualBaseline', Format('Accepted Visual Baseline %s created (decision: %s, snapshot: %s)',
    [Result, LDecId, LBaseline.SnapshotName]));
end;

function TAsWishController.CollectEvidence(const ABaselineId: string): TArray<TSpecEvidence>;
var
  LCollector: TAsWishEvidenceCollectorService;
begin
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');
  LCollector := TAsWishEvidenceCollectorService.Create(FSpecStore, FSnapshot);
  try
    Result := LCollector.CollectImplementationEvidence(FProjectService.ProjectPath, ABaselineId);
    FStatus.Info('AsWish.Evidence', Format('Collected %d evidence items for baseline %s',
      [Length(Result), ABaselineId]));
  finally
    LCollector.Free;
  end;
end;

function TAsWishController.ComputeDifference(const ABaselineId: string): TSpecDifferenceReport;
var
  LDifference: TAsWishDifferenceService;
  LEvidencePath: string;
begin
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');

  LEvidencePath := TPath.Combine(FProjectService.AsWishPath, 'evidence\implementation-evidence.yaml');
  if not TFile.Exists(LEvidencePath) then
    CollectEvidence(ABaselineId);

  LDifference := TAsWishDifferenceService.Create(FSpecStore, FSnapshot);
  try
    Result := LDifference.ComputeDifference(FProjectService.ProjectPath, ABaselineId);
    FRender.RenderDifferencePage(Result, FProjectService.ProjectName);
    FStatus.Info('AsWish.Difference', Format('Computed %d differences against baseline %s',
      [Length(Result.Items), ABaselineId]));
  finally
    LDifference.Free;
  end;
end;

function TAsWishController.RecordDifferenceDecision(const ABaselineId, AAction, ARationale: string): string;
var
  LReport: TSpecDifferenceReport;
begin
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');
  LReport := ComputeDifference(ABaselineId);
  FDecisions.Initialize(FProjectService.AsWishPath);
  FDecisions.Load;
  Result := FDecisions.RecordDifferenceDecision(LReport, AAction, ARationale);
  FRender.RenderDecisionsPage(ListDecisions, FProjectService.ProjectName);
  FStatus.Info('AsWish.Difference', Format('Recorded decision %s (%s) for baseline %s',
    [Result, AAction, ABaselineId]));
end;

function TAsWishController.EvolveBaseline(const ABaselineId, ANote: string;
  out ANewBaseline: TAsWishBaseline): string;
var
  LReport: TSpecDifferenceReport;
  LDecId: string;
  LDec: TSpecDecision;
  LCS: TChangeSet;
  LFunc, LMod, LView, LData: TList<TSpecNode>;
begin
  ANewBaseline := Default(TAsWishBaseline);
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');
  LReport := ComputeDifference(ABaselineId);
  FDecisions.Initialize(FProjectService.AsWishPath);
  FDecisions.Load;

  LCS := Default(TChangeSet);
  LCS.Id := 'cs-evolve-' + ABaselineId;
  if LReport.TreeType = 'view' then LCS.IntentTree := ttView
  else if LReport.TreeType = 'module' then LCS.IntentTree := ttModule
  else if LReport.TreeType = 'data' then LCS.IntentTree := ttData
  else LCS.IntentTree := ttFunction;
  LCS.IntentNodeId := 'diff-evolve';

  LDecId := FDecisions.RecordDifferenceDecision(LReport, 'acceptable', ANote, LCS.Id);
  LDec := FDecisions.FindById(LDecId);

  LFunc := FSpecStore.ReadTreeFile('trees/function-tree.yaml');
  LMod := FSpecStore.ReadTreeFile('trees/module-tree.yaml');
  LView := FSpecStore.ReadTreeFile('trees/view-tree.yaml');
  LData := FSpecStore.ReadTreeFile('trees/data-tree.yaml');
  try
    Result := FSnapshot.CreateBaseline(LDec, LCS, LFunc, LMod, LView, LData, ANewBaseline, '', '', ABaselineId);
    RenderAll;
    FRender.RenderDecisionsPage(ListDecisions, FProjectService.ProjectName);
    FStatus.Info('AsWish.Evolve', Format('Evolved new Accepted Baseline %s (snapshot: %s, parent: %s)',
      [Result, ANewBaseline.SnapshotName, ABaselineId]));
  finally
    LData.Free;
    LView.Free;
    LMod.Free;
    LFunc.Free;
  end;
end;

function TAsWishController.ListDecisions: TArray<TSpecDecision>;
begin
  if not FProjectService.IsOpen then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  FDecisions.Initialize(FProjectService.AsWishPath);
  FDecisions.Load;
  Result := FDecisions.Decisions.ToArray;
end;

end.
