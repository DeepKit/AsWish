
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
  AsWish.Services.VisualWorkflow,
  AsWish.Services.Commons,
  AsWish.Models;

type
  /// <summary>What a change-set decision actually produced. The two-argument
  /// Boolean methods below stay for the four callers that only need success;
  /// this carries the ids a headless caller must print, so it no longer has
  /// to re-read the change set off disk to learn what was decided.</summary>
  TChangeSetDecisionResult = record
    Ok: Boolean;
    ChangeSetId: string;
    DecisionId: string;
    /// <summary>Only Accept fills these. Reject and Clarify leave them empty,
    ///  because they freeze nothing.</summary>
    BaselineId: string;
    BaselineSnapshot: string;
    UpdatedNodes: Integer;
  end;

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
    FCommons: TAsWishCommonsService;
    FStatus: IShellStatusManager;
    FContext: IShellContextManager;
    FBus: IShellEventBus;
    FDocsFiles: TArray<string>;
    /// <summary>Set when RunScan could not finish. The desktop shell reports
    ///  through the status pane and carries on, but a headless caller has no
    ///  pane -- it needs to know the run failed so it can exit non-zero
    ///  instead of reporting success it did not achieve.</summary>
    FScanFailed: Boolean;
    procedure ScanDocsFirst;
    procedure WriteDocsSummary;
    /// <summary>Apply accepted/rejected formal decisions to every tree on
    ///  disk: read tree → ApplyNodeStatusTransitions → write back. Returns the
    ///  trees it actually rewrote, so a caller that reports per-tree output does
    ///  not have to re-derive the list. Shared by PromotePendingDecisions and
    ///  ApplyBundleDecisions.</summary>
    function ApplyAllTreeTransitions: TArray<string>;
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
    /// <summary>The one body behind AcceptChangeSet. ALoadTreesFromDisk is the
    ///  only difference between the two entry shapes: the desktop app has a
    ///  live builder to apply to, a one-shot CLI process does not.</summary>
    function AcceptChangeSetCore(const AChangeSetId, ARationale: string;
      ALoadTreesFromDisk: Boolean;
      out AResult: TChangeSetDecisionResult): Boolean;
  public
    /// <summary>Replace the builder's four trees with what is persisted on
    ///  disk. Only a headless caller needs this: a one-shot process has no scan
    ///  and no live builder, so anything that re-renders through the Controller
    ///  would otherwise describe empty trees and overwrite the real pages with
    ///  blanks. Never call this from a live session -- it discards whatever the
    ///  builder currently holds.</summary>
    procedure LoadPersistedTrees;
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

    procedure OpenProject(const APath: string);
    procedure OpenAndScan(const APath: string);
    procedure RunScan;
    /// <summary>True only while the last RunScan ended in an exception. Read
    ///  it after the call: RunScan reports through the status channel and
    ///  does not raise, so a caller with no status pane has no other way to
    ///  learn the scan did not happen.</summary>
    property ScanFailed: Boolean read FScanFailed;
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
    procedure PromotePendingDecisions; overload;
    /// <summary>Same promotion, but reports what it did. A headless caller has
    ///  no status pane, so "promoted N" and the per-tree lines it prints were
    ///  the only reason it kept its own copy of this orchestration.</summary>
    function PromotePendingDecisions(out ATreesTouched: TArray<string>): Integer; overload;

    // Natural Language -> Change Set -> Decision Commands (WO-20260830-0027D)
    function SubmitUserIntent(const AIntent: TCandidateIntent): string; overload;
    function SubmitUserIntent(const ANodeId, AIntentText: string): string; overload;
    function SubmitUserIntent(const ANodeId: string; ATree: TTreeType;
      const AIntentText: string): string; overload;
    function SubmitUserIntent(const AIntentText: string;
      ATree: TTreeType = ttFunction): string; overload;
    function SubmitFrameRejection(const ARejectedNodeId: string;
      ARejectedTree: TTreeType; const AIntentText: string;
      const ATargetTree: TTreeType = ttFunction;
      const ATargetNodeId: string = ''): string;
    function ReviewChangeSet(const AChangeSetId: string = ''): string;
    function AcceptChangeSet(const AChangeSetId: string;
      const ARationale: string = ''): Boolean; overload;
    /// <summary>Accept a change set from a process with no live session. Pass
    ///  ALoadTreesFromDisk=True and the persisted trees are read back into the
    ///  builder before the change set is applied -- otherwise the builder is
    ///  empty, ApplyChangeSet finds nothing to update, and the write-back that
    ///  follows would replace the Canonical Spec with empty trees.</summary>
    function AcceptChangeSet(const AChangeSetId: string;
      const ARationale: string; ALoadTreesFromDisk: Boolean;
      out AResult: TChangeSetDecisionResult): Boolean; overload;
    function RejectChangeSet(const AChangeSetId: string;
      const ARationale: string = ''): Boolean; overload;
    function RejectChangeSet(const AChangeSetId: string;
      const ARationale: string;
      out AResult: TChangeSetDecisionResult): Boolean; overload;
    function ClarifyChangeSet(const AChangeSetId: string;
      const AClarificationText: string): Boolean; overload;
    function ClarifyChangeSet(const AChangeSetId: string;
      const AClarificationText: string;
      out AResult: TChangeSetDecisionResult): Boolean; overload;
    function ListCandidateIntents: TArray<TCandidateIntent>;

    // Accepted Baseline & Visual Baseline (WO-20260830-0027E, WO-20260830-0028)
    function VerifyBaseline(const ABaselineId: string): Boolean;
    function ListBaselines: TArray<TAsWishBaseline>;
    function ConfirmVisualBaseline(const ARationale: string = ''): string;
    function ConfirmVisualBaselineFromDecision(const ADecisionId: string): string;

    // Structural Difference, Human Judgment & Evolution (WO-20260905-0029)
    function CollectEvidence(const ABaselineId: string = ''): TArray<TSpecEvidence>;
    function ComputeDifference(const ABaselineId: string): TSpecDifferenceReport;
    function RecordDifferenceDecision(const ABaselineId, AAction, ARationale: string): string;
    function EvolveBaseline(const ABaselineId, ANote: string;
      out ANewBaseline: TAsWishBaseline): string; overload;
    /// <summary>Same evolution, but hands back the decision it recorded. The
    ///  three-argument form above computes that id and only reports it through
    ///  the status pane, which a headless caller does not have -- so a CLI that
    ///  prints "Decision ID: ..." had to keep its own copy of the whole
    ///  orchestration just to learn it.</summary>
    function EvolveBaseline(const ABaselineId, ANote: string;
      out ANewBaseline: TAsWishBaseline; out ADecisionId: string): string; overload;
    function ListDecisions: TArray<TSpecDecision>;

    // Difference Commons (WO-20260923-0041)
    // WO-20260924-0049 P-4: AShareConsent defaults False so an unchecked
    // GUI checkbox can never publish a lesson to the public hub.
    function ExtractCommonsLesson(const AChangeSetId: string;
      const ATakeaway: string = ''; AShareConsent: Boolean = False): TSpecCommonsLesson;

    destructor Destroy; override;
    function IsProjectOpen: Boolean;
    property ProjectService: TAsWishProjectService read FProjectService;
    property ScanService: TAsWishScanService read FScanService;
    property TreeBuilder: TAsWishTreeBuilder read FTreeBuilder;
    property Decisions: TAsWishDecisionsService read FDecisions;
    property LLM: TAsWishLLMService read FLLM;
    property Settings: TAsWishSettingsService read FSettings;
    property Commons: TAsWishCommonsService read FCommons;
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
  FCommons := TAsWishCommonsService.Create(FSpecStore);
  FStatus := AStatus;
  FContext := AContext;
  FBus := ABus;
end;

destructor TAsWishController.Destroy;
begin
  FCommons.Free;
  FSnapshot.Free;
  inherited;
end;

function TAsWishController.IsProjectOpen: Boolean;
begin
  Result := FProjectService.IsOpen;
end;

// Opening is the half of OpenAndScan that twenty commands need without a
// scan. It lives here, once, so those commands can share it instead of each
// rebuilding the services and re-deriving the order they must be initialised
// in -- which is how the CLI and the desktop app drifted apart.
// The "Opening project" announcement stays in OpenAndScan: a read-only command
// that only needs the project open should not narrate it.
procedure TAsWishController.OpenProject(const APath: string);
begin
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
end;

procedure TAsWishController.OpenAndScan(const APath: string);
begin
  FStatus.Info('AsWish', 'Opening project: ' + APath);
  OpenProject(APath);

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

  // The pack describes the source tree, so it must be built from one. This
  // method used to consume whatever state the last scan happened to leave
  // behind, which only worked because the desktop button is reachable after a
  // Visualize click -- the CLI's generate command, which opens the project and
  // exports in one go, got a pack saying "Type: unknown" and zero files.
  // ScanDirectory is in-memory and deterministic, so refreshing here is free
  // and makes both entry points produce the same pack.
  FScanService.ScanDirectory(FProjectService.ProjectPath);
  FProjectService.SetProjectType(FScanService.DetectProjectType);

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
      FRender.RenderStandardPages(FProjectService.ProjectName,
        FScanService.TotalFiles, FTreeBuilder.FunctionNodes,
        FTreeBuilder.ModuleNodes, FTreeBuilder.ViewNodes,
        FTreeBuilder.DataNodes, LIssuesR, FSpecStore);
    finally
      LIssuesR.Free;
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
      // FTreeBuilder (which may be stale here); RenderStandardPages derives it
      // the same way from an empty list.
      var LIssuesR := LoadIssuesForRender;
      try
        FRender.RenderStandardPages(FProjectService.ProjectName,
          FScanService.TotalFiles, LFunc, LModule, LView, LData, LIssuesR,
          FSpecStore);
      finally
        LIssuesR.Free;
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
  LIgnored: TArray<string>;
begin
  PromotePendingDecisions(LIgnored);
end;

function TAsWishController.PromotePendingDecisions(
  out ATreesTouched: TArray<string>): Integer;
var
  LCount: Integer;
begin
  ATreesTouched := TArray<string>.Create();
  Result := 0;
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

    // Reported before the transition pass, not after: the except below swallows
    // the failure so the desktop shell carries on, and a caller that only
    // learned the count afterwards would report 0 for decisions that really
    // were promoted.
    Result := LCount;

    // Apply state machine transitions to all trees
    ATreesTouched := ApplyAllTreeTransitions;
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

function TAsWishController.ApplyAllTreeTransitions: TArray<string>;
var
  LTreeNames: TArray<string>;
  LTouched: TList<string>;
begin
  LTreeNames := TArray<string>.Create(
    'trees/function-tree.yaml', 'trees/module-tree.yaml',
    'trees/view-tree.yaml', 'trees/data-tree.yaml');
  LTouched := TList<string>.Create;
  try
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
          LTouched.Add(LTree);
        end;
      finally
        LNodes.Free;
      end;
    end;
    Result := LTouched.ToArray;
  finally
    LTouched.Free;
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

  // The file-by-file list is diagnostic detail, not an announcement: printed
  // as Info it floods a console run with one line per document.
  for var I := 0 to High(FDocsFiles) do
    FStatus.Diagnostic('AsWish.Docs', ExtractFileName(FDocsFiles[I]));
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
  // Cleared up front so a caller reading ScanFailed after a run that never
  // happened (no project open) does not inherit the previous run's failure.
  FScanFailed := False;
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

    // Step 3: Detect project type. The scan service owns this: the desktop app
    // used to carry its own copy, which reported "unknown" for code it could
    // not name where the CLI reported "mixed", so a repository's recorded type
    // depended on which entry point scanned it.
    var LType := FScanService.DetectProjectType;
    FProjectService.SetProjectType(LType);
    FStatus.Progress('scan', 'AsWish.Scan', 50,
      'Detected project type: ' + LType);

    // Step 4: Write .AsWish structure
    FSpecStore.CreateDirectoryStructure;
    FCommons.SeedCommonsLessonsIfEmpty;
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

    // Degradation must be reported, not buried: a code-page fallback means the
    // excerpts for those files are best-effort decodes, and a disambiguated
    // evidence id is not the id the source file would have produced. The CLI
    // printed both of these; the desktop app said nothing.
    var LNonUtf8 := FTreeBuilder.NonUtf8Files;
    if Length(LNonUtf8) > 0 then
      FStatus.Warning('AsWish.Scan',
        Format('%d file(s) are not UTF-8 and were read with a code-page ' +
          'fallback; their excerpts may be lossy: %s',
          [Length(LNonUtf8), string.Join(', ', LNonUtf8)]));
    if FTreeBuilder.EvidenceIdCollisions > 0 then
      FStatus.Warning('AsWish.Scan',
        Format('%d evidence id collision(s) were disambiguated with a ' +
          'numeric suffix', [FTreeBuilder.EvidenceIdCollisions]));

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
    // The evidence catalog has to be rendered before the tree pages so the
    // evidence ids they print resolve to a real anchor. RenderAll and
    // RefreshFromYaml deliberately do not repeat this: they re-render from
    // in-memory state, and the page written here stays on disk.
    FRender.RenderEvidencePage(FTreeBuilder.EvidenceList,
      FProjectService.ProjectName);

    // Step 6: Render HTML
    FStatus.Progress('scan', 'AsWish.Scan', 85, 'Rendering HTML...');
    FRender.RenderScanReport(FScanService, FProjectService.ProjectName, LType);
    var LIssuesR := LoadIssuesForRender;
    try
      FRender.RenderStandardPages(FProjectService.ProjectName,
        FScanService.TotalFiles, FTreeBuilder.FunctionNodes,
        FTreeBuilder.ModuleNodes, FTreeBuilder.ViewNodes,
        FTreeBuilder.DataNodes, LIssuesR, FSpecStore);
    finally
      LIssuesR.Free;
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
    FScanFailed := False;
  except
    on E: Exception do
    begin
      FScanFailed := True;
      FStatus.LogError('AsWish.Scan', 'Scan failed: ' + E.Message, E.ClassName);
      FStatus.TaskFinish('scan', 'Scan failed');
    end;
  end;
end;

function TAsWishController.SubmitUserIntent(const AIntent: TCandidateIntent): string;
var
  LIngest: TAsWishCandidateIngest;
  LChangeSet: TChangeSet;
  LBundles: TList<TSemanticBundle>;
  LTargetNode, LRejectedNode: TSpecNode;
  LTreeNodes, LRejTreeNodes: TList<TSpecNode>;
  LAffected: TArray<TTreeType>;
  LItems: TList<TChangeItem>;
  LChangePath, LPromptPath: string;
  LCSId: string;
  procedure AddAffected(ATree: TTreeType);
  var
    LFound: Boolean;
  begin
    LFound := False;
    for var LT in LAffected do
      if LT = ATree then
      begin
        LFound := True;
        Break;
      end;
    if not LFound then
    begin
      SetLength(LAffected, Length(LAffected) + 1);
      LAffected[High(LAffected)] := ATree;
    end;
  end;
  function GetNodesForTree(ATree: TTreeType): TList<TSpecNode>;
  begin
    case ATree of
      ttFunction: Result := FTreeBuilder.FunctionNodes;
      ttModule:   Result := FTreeBuilder.ModuleNodes;
      ttView:     Result := FTreeBuilder.ViewNodes;
      ttData:     Result := FTreeBuilder.DataNodes;
    else
      Result := nil;
    end;
  end;
begin
  Result := '';
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    LIngest.SaveCandidateIntent(FProjectService.ProjectPath, AIntent);

    LBundles := FSpecStore.ReadBundlesFile('bundles.yaml');
    try
      LTargetNode := Default(TSpecNode);
      if AIntent.NodeId <> '' then
      begin
        LTreeNodes := GetNodesForTree(AIntent.Tree);
        if LTreeNodes <> nil then
          for var LN in LTreeNodes do
            if LN.Id = AIntent.NodeId then
            begin
              LTargetNode := LN;
              Break;
            end;
        LAffected := LIngest.ComputeAffectedProjections(AIntent.NodeId, LBundles);
      end
      else
        SetLength(LAffected, 0);

      LItems := TList<TChangeItem>.Create;
      try
        if AIntent.IsFrameRejection then
        begin
          LRejTreeNodes := GetNodesForTree(AIntent.RejectedTree);
          LRejectedNode := Default(TSpecNode);
          if LRejTreeNodes <> nil then
            for var LN in LRejTreeNodes do
              if LN.Id = AIntent.RejectedNodeId then
              begin
                LRejectedNode := LN;
                Break;
              end;

          AddAffected(AIntent.RejectedTree);
          AddAffected(AIntent.Tree);

          LCSId := LIngest.GenerateNextChangeSetId(FProjectService.ProjectPath, 'reframe-' + AIntent.RejectedNodeId);
          LChangeSet := TChangeSet.CreateFrameRejection(LCSId, AIntent.RejectedNodeId, AIntent.RejectedTree,
            AIntent.UserIntent, AIntent.NodeId, AIntent.Tree, AIntent.Author);

          // Item 1: mark rejected frame as frame_rejected
          LItems.Add(TChangeItem.CreateItem(AIntent.RejectedNodeId, AIntent.RejectedTree,
            'status', TSpecEnums.NodeStatusToStr(LRejectedNode.Status), 'frame_rejected',
            cstExplicit, 'Frame rejected by human: ' + AIntent.UserIntent));

          // Item 2: attach new higher-level intent to target projection / upstream node
          if AIntent.NodeId <> '' then
            LItems.Add(TChangeItem.CreateItem(AIntent.NodeId, AIntent.Tree,
              'user_intent', LTargetNode.UserIntent, AIntent.UserIntent,
              cstExplicit, 'Higher-level intent from human reframe'))
          else
            LItems.Add(TChangeItem.CreateItem('', AIntent.Tree,
              'user_intent', '', AIntent.UserIntent,
              cstExplicit, 'Higher-level unanchored intent from human reframe'));
        end
        else if AIntent.NodeId = '' then
        begin
          AddAffected(AIntent.Tree);
          LCSId := LIngest.GenerateNextChangeSetId(FProjectService.ProjectPath, 'unanchored');
          LChangeSet := TChangeSet.CreateNew(LCSId, '', AIntent.Tree, AIntent.UserIntent, AIntent.Author);
          LItems.Add(TChangeItem.CreateItem('', AIntent.Tree,
            'user_intent', '', AIntent.UserIntent,
            cstExplicit, 'Unanchored human user intent'));
        end
        else
        begin
          AddAffected(AIntent.Tree);
          LCSId := LIngest.GenerateNextChangeSetId(FProjectService.ProjectPath, AIntent.NodeId);
          LChangeSet := TChangeSet.CreateNew(LCSId, AIntent.NodeId, AIntent.Tree, AIntent.UserIntent, AIntent.Author);
          LItems.Add(TChangeItem.CreateItem(AIntent.NodeId, AIntent.Tree,
            'summary', LTargetNode.Summary, AIntent.UserIntent,
            cstExplicit, 'Interpreted from human user intent'));
        end;

        LChangeSet.AffectedProjections := LAffected;
        LChangeSet.Items := LItems.ToArray;
      finally
        LItems.Free;
      end;

      LChangePath := LIngest.SaveChangeSet(FProjectService.ProjectPath, LChangeSet);
      LPromptPath := FPrompts.WriteChangeInterpretPrompt(AIntent, LTargetNode, LBundles);

      // Render the 4-layer review surface
      FRender.RenderChangeSetReviewPage(LChangeSet, FTreeBuilder.FunctionNodes, FProjectService.ProjectName);

      Result := LCSId;
      FStatus.Info('AsWish.ChangeSet', Format('Created ChangeSet %s; Prompt saved at %s',
        [LCSId, LPromptPath]));
    finally
      LBundles.Free;
    end;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.SubmitUserIntent(const ANodeId, AIntentText: string): string;
begin
  Result := SubmitUserIntent(TCandidateIntent.CreateNew(ANodeId, ttFunction, AIntentText, 'human'));
end;

function TAsWishController.SubmitUserIntent(const ANodeId: string;
  ATree: TTreeType; const AIntentText: string): string;
begin
  Result := SubmitUserIntent(TCandidateIntent.CreateNew(ANodeId, ATree, AIntentText, 'human'));
end;

function TAsWishController.SubmitUserIntent(const AIntentText: string;
  ATree: TTreeType): string;
begin
  Result := SubmitUserIntent(TCandidateIntent.CreateUnanchored(ATree, AIntentText, 'human'));
end;

function TAsWishController.SubmitFrameRejection(const ARejectedNodeId: string;
  ARejectedTree: TTreeType; const AIntentText: string;
  const ATargetTree: TTreeType; const ATargetNodeId: string): string;
begin
  Result := SubmitUserIntent(TCandidateIntent.CreateFrameRejection(ARejectedNodeId,
    ARejectedTree, AIntentText, ATargetNodeId, ATargetTree, 'human'));
end;

function TAsWishController.ReviewChangeSet(const AChangeSetId: string): string;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LMatches: TArray<TSpecCommonsLesson>;
  LWarningMsg: string;
  LNodeIds: TArray<string>;
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

    SetLength(LNodeIds, Length(LCS.Items) + 1);
    LNodeIds[0] := LCS.IntentNodeId;
    for var I := 0 to High(LCS.Items) do
      LNodeIds[I + 1] := LCS.Items[I].TargetNodeId;

    LMatches := FCommons.FindMatchingLessons(LCS.RawUserIntent + ' ' + LCS.IntentNodeId, LNodeIds);
    LWarningMsg := '';
    if Length(LMatches) > 0 then
    begin
      if SameText(LMatches[0].AnchorKind, 'narrative') then
        LWarningMsg := Format('历史经验：同类分叉曾错在 %s（%s） [源自实践总结，非可复核记录]',
          [LMatches[0].Title, LMatches[0].Id])
      else
        LWarningMsg := Format('历史经验：同类分叉曾错在 %s（%s）',
          [LMatches[0].Title, LMatches[0].Id]);
    end;

    FRender.RenderChangeSetReviewPage(LCS, FTreeBuilder.FunctionNodes, FProjectService.ProjectName, LWarningMsg);
    Result := LIngest.FormatChangeSetReviewSummary(LCS, FTreeBuilder.FunctionNodes);
    if LWarningMsg <> '' then
      Result := Result + sLineBreak + '[Difference Commons Warning]' + sLineBreak + LWarningMsg + sLineBreak;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.ExtractCommonsLesson(const AChangeSetId: string;
  const ATakeaway: string; AShareConsent: Boolean): TSpecCommonsLesson;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LDiff: TSpecDifferenceReport;
  LBaselines: TArray<TAsWishBaseline>;
begin
  Result := Default(TSpecCommonsLesson);
  if not FProjectService.IsOpen then Exit;

  LIngest := TAsWishCandidateIngest.Create(FSpecStore);
  try
    LCS := LIngest.LoadChangeSet(FProjectService.ProjectPath, AChangeSetId);
    if LCS.Id = '' then Exit;

    LDec := Default(TSpecDecision);
    if FDecisions <> nil then
      for var LD in FDecisions.Decisions do
        if LD.ChangeSetId = AChangeSetId then
        begin
          LDec := LD;
          Break;
        end;

    LDiff := Default(TSpecDifferenceReport);
    LBaselines := FSnapshot.ListBaselines;
    // F-2: Reverse lookup Baseline via Decision lineage (Lineage.ChangeSetId or DecisionId)
    for var LB in LBaselines do
    begin
      if (LDec.ChangeSetId <> '') and (LB.Lineage.ChangeSetId = LDec.ChangeSetId) then
      begin
        LDiff.BaselineId := LB.BaselineId;
        Break;
      end
      else if (LDec.Id <> '') and (LB.DecisionId = LDec.Id) then
      begin
        LDiff.BaselineId := LB.BaselineId;
        Break;
      end;
    end;

    Result := FCommons.ExtractLessonFromChangeSet(LCS, LDec, LDiff, ATakeaway);
    // WO-20260924-0049 P-4: consent is applied before the single atomic
    // write so the yaml on disk is correct in one pass (no double write).
    Result.PublishConsent := AShareConsent;
    FCommons.SaveLessonDraft(Result);
    FStatus.Info('AsWish.Commons', Format('Extracted lesson draft: %s (%s)', [Result.Id, Result.Title]));
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.AcceptChangeSet(const AChangeSetId, ARationale: string): Boolean;
var
  LResult: TChangeSetDecisionResult;
begin
  Result := AcceptChangeSetCore(AChangeSetId, ARationale, False, LResult);
end;

function TAsWishController.AcceptChangeSet(const AChangeSetId, ARationale: string;
  ALoadTreesFromDisk: Boolean;
  out AResult: TChangeSetDecisionResult): Boolean;
begin
  Result := AcceptChangeSetCore(AChangeSetId, ARationale, ALoadTreesFromDisk, AResult);
end;

procedure TAsWishController.LoadPersistedTrees;
var
  LFunc, LMod, LView, LData: TList<TSpecNode>;

  procedure Replace(ADst: TList<TSpecNode>; ASrc: TList<TSpecNode>);
  begin
    ADst.Clear;
    if ASrc = nil then Exit;
    for var LN in ASrc do
      ADst.Add(LN);
    // The nodes now live in the builder's list, which frees them; releasing
    // the container here would double-free the nodes it still points at.
    ASrc.Free;
  end;

begin
  LFunc := FSpecStore.ReadTreeFile('trees/function-tree.yaml');
  LMod := FSpecStore.ReadTreeFile('trees/module-tree.yaml');
  LView := FSpecStore.ReadTreeFile('trees/view-tree.yaml');
  LData := FSpecStore.ReadTreeFile('trees/data-tree.yaml');
  try
    Replace(FTreeBuilder.FunctionNodes, LFunc);
    Replace(FTreeBuilder.ModuleNodes, LMod);
    Replace(FTreeBuilder.ViewNodes, LView);
    Replace(FTreeBuilder.DataNodes, LData);
  except
    // A partially moved set would leave the builder owning nodes the freed
    // containers still reference. Nothing is recoverable here, so let the
    // caller see the failure rather than continue on half-loaded trees.
    if LFunc <> nil then LFunc.Free;
    if LMod <> nil then LMod.Free;
    if LView <> nil then LView.Free;
    if LData <> nil then LData.Free;
    raise;
  end;
end;

function TAsWishController.AcceptChangeSetCore(const AChangeSetId, ARationale: string;
  ALoadTreesFromDisk: Boolean;
  out AResult: TChangeSetDecisionResult): Boolean;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LDecId: string;
  LDec: TSpecDecision;
  LStats: TMergeStats;
begin
  AResult := Default(TChangeSetDecisionResult);
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
    AResult.ChangeSetId := LCS.Id;

    // Idempotency guard: an already-accepted ChangeSet must not be re-applied
    // (duplicate tree mutations, duplicate decision refs, duplicate Baselines).
    // The prior decision and its baseline are reported back, because a caller
    // with no status pane has to be able to say what already happened.
    var LPriorAccepted := FDecisions.FindAcceptedByChangeSet(AChangeSetId);
    if Length(LPriorAccepted) > 0 then
    begin
      AResult.Ok := True;
      AResult.DecisionId := LPriorAccepted[0].Id;
      AResult.UpdatedNodes := 0;
      for var LExisting in FSnapshot.ListBaselines do
        if LExisting.DecisionId = LPriorAccepted[0].Id then
        begin
          AResult.BaselineId := LExisting.BaselineId;
          AResult.BaselineSnapshot := LExisting.SnapshotName;
          Break;
        end;
      FStatus.Info('AsWish.ChangeSet', Format('ChangeSet %s already accepted (Decision %s); skipping duplicate application',
        [AChangeSetId, LPriorAccepted[0].Id]));
      Result := True;
      Exit;
    end;

    // A one-shot process has no live builder, so the trees it must apply to
    // are the ones on disk. Without this the builder is empty and the
    // write-back below would overwrite the Canonical Spec with empty trees.
    if ALoadTreesFromDisk then
      LoadPersistedTrees;

    // Record formal decision
    LDecId := FDecisions.RecordChangeSetDecision(LCS, rsAccepted, ARationale);
    LDec := FDecisions.FindById(LDecId);
    AResult.DecisionId := LDecId;

    // Apply to live memory trees
    LStats := LIngest.ApplyChangeSet(LCS, LDec,
      FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
      FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes);
    AResult.UpdatedNodes := LStats.Merged;

    // Write updated trees back to disk (Canonical Spec)
    FSpecStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, FTreeBuilder.FunctionNodes);
    FSpecStore.WriteTreeFile('trees/module-tree.yaml', ttModule, FTreeBuilder.ModuleNodes);
    FSpecStore.WriteTreeFile('trees/view-tree.yaml', ttView, FTreeBuilder.ViewNodes);
    FSpecStore.WriteTreeFile('trees/data-tree.yaml', ttData, FTreeBuilder.DataNodes);

    // Freeze resulting Canonical Spec state into immutable Accepted Baseline (WO-20260830-0027E)
    var LParentBaseId := '';
    var LExistingBaselines := FSnapshot.ListBaselines;
    if Length(LExistingBaselines) > 0 then
      LParentBaseId := LExistingBaselines[0].BaselineId;

    var LBaseline: TAsWishBaseline;
    var LBaseId := FSnapshot.CreateBaseline(LDec, LCS,
      FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
      FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LBaseline,
      '', '', LParentBaseId);
    AResult.BaselineId := LBaseId;
    AResult.BaselineSnapshot := LBaseline.SnapshotName;

    // Re-render
    RenderAll;

    AResult.Ok := True;
    FStatus.Info('AsWish.ChangeSet', Format('Accepted %s -> Decision %s recorded; Baseline %s frozen; %d nodes updated in Canonical Spec',
      [LCS.Id, LDecId, LBaseId, LStats.Merged]));
    Result := True;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.RejectChangeSet(const AChangeSetId, ARationale: string): Boolean;
var
  LResult: TChangeSetDecisionResult;
begin
  Result := RejectChangeSet(AChangeSetId, ARationale, LResult);
end;

function TAsWishController.RejectChangeSet(const AChangeSetId, ARationale: string;
  out AResult: TChangeSetDecisionResult): Boolean;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LDecId: string;
begin
  AResult := Default(TChangeSetDecisionResult);
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
    AResult.Ok := True;
    AResult.ChangeSetId := LCS.Id;
    AResult.DecisionId := LDecId;
    Result := True;
  finally
    LIngest.Free;
  end;
end;

function TAsWishController.ClarifyChangeSet(const AChangeSetId, AClarificationText: string): Boolean;
var
  LResult: TChangeSetDecisionResult;
begin
  Result := ClarifyChangeSet(AChangeSetId, AClarificationText, LResult);
end;

function TAsWishController.ClarifyChangeSet(const AChangeSetId, AClarificationText: string;
  out AResult: TChangeSetDecisionResult): Boolean;
var
  LIngest: TAsWishCandidateIngest;
  LCS: TChangeSet;
  LDecId: string;
begin
  AResult := Default(TChangeSetDecisionResult);
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
    AResult.Ok := True;
    AResult.ChangeSetId := LCS.Id;
    AResult.DecisionId := LDecId;
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

function TAsWishController.ConfirmVisualBaselineFromDecision(const ADecisionId: string): string;
var
  LWorkflow: TAsWishVisualWorkflowService;
  LDifference: TAsWishDifferenceService;
begin
  Result := '';
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('AsWish', 'No project open');
    Exit;
  end;
  LDifference := TAsWishDifferenceService.Create(FSpecStore, FSnapshot);
  try
    LWorkflow := TAsWishVisualWorkflowService.Create(FSpecStore, FSnapshot, FDecisions, LDifference);
    try
      Result := LWorkflow.ConfirmVisualBaseline(ADecisionId);
      RenderAll;
      FStatus.Info('AsWish.VisualBaseline', Format('Accepted Visual Baseline %s created (decision: %s)',
        [Result, ADecisionId]));
    finally
      LWorkflow.Free;
    end;
  finally
    LDifference.Free;
  end;
end;

function TAsWishController.ConfirmVisualBaseline(const ARationale: string): string;
var
  LDecId: string;
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

  // If ARationale is already an existing decision ID, delegate directly
  if (ARationale <> '') and (FDecisions.FindById(ARationale).Id <> '') then
    Exit(ConfirmVisualBaselineFromDecision(ARationale));

  // Collect affected view IDs and create formal decision
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
  finally
    LViewIds.Free;
  end;

  Result := ConfirmVisualBaselineFromDecision(LDecId);
end;

function TAsWishController.CollectEvidence(const ABaselineId: string): TArray<TSpecEvidence>;
var
  LCollector: TAsWishEvidenceCollectorService;
  LDegraded: Integer;
begin
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');
  LDegraded := 0;
  LCollector := TAsWishEvidenceCollectorService.Create(FSpecStore, FSnapshot);
  try
    Result := LCollector.CollectImplementationEvidence(FProjectService.ProjectPath,
      ABaselineId, @LDegraded);
    FStatus.Info('AsWish.Evidence', Format('Collected %d evidence items for baseline %s (%d degraded refs)',
      [Length(Result), ABaselineId, LDegraded]));
  finally
    LCollector.Free;
  end;
end;

function TAsWishController.ComputeDifference(const ABaselineId: string): TSpecDifferenceReport;
var
  LDifference: TAsWishDifferenceService;
  LWorkflow: TAsWishVisualWorkflowService;
  LEvidencePath: string;
begin
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');

  LEvidencePath := TPath.Combine(FProjectService.AsWishPath, 'evidence\implementation-evidence.yaml');
  if not TFile.Exists(LEvidencePath) then
    CollectEvidence(ABaselineId);

  LDifference := TAsWishDifferenceService.Create(FSpecStore, FSnapshot);
  try
    // Through the workflow, not the Difference service directly: the workflow
    // is what registers the VCL comparator and discovers the observation,
    // binding, constraint and style inputs. Calling the service directly -- as
    // this method used to -- left FComparators empty, so every view baseline
    // came back "Degraded: No platform visual comparator handled baseline" and
    // the L2/L3 visual comparison silently never ran in the desktop app. The
    // CLI had already gone through the workflow, so the two entry points were
    // answering different questions about the same repository.
    LWorkflow := TAsWishVisualWorkflowService.Create(FSpecStore, FSnapshot, FDecisions, LDifference);
    try
      Result := LWorkflow.ComputeDifference(FProjectService.ProjectPath, ABaselineId);
    finally
      LWorkflow.Free;
    end;
    FRender.RenderDifferencePage(Result, FProjectService.ProjectName);
    if Result.IsDegraded then
      FStatus.Info('AsWish.Difference', Format('Computed %d differences against baseline %s (Degraded: %s)',
        [Length(Result.Items), ABaselineId, Result.DegradedReason]))
    else
      FStatus.Info('AsWish.Difference', Format('Computed %d differences against baseline %s',
        [Length(Result.Items), ABaselineId]));
  finally
    LDifference.Free;
  end;
end;

function TAsWishController.RecordDifferenceDecision(const ABaselineId, AAction, ARationale: string): string;
var
  LWorkflow: TAsWishVisualWorkflowService;
  LDifference: TAsWishDifferenceService;
  LReport: TSpecDifferenceReport;
  LJudgment: TDifferenceJudgment;
begin
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');
  LDifference := TAsWishDifferenceService.Create(FSpecStore, FSnapshot);
  try
    LWorkflow := TAsWishVisualWorkflowService.Create(FSpecStore, FSnapshot, FDecisions, LDifference);
    try
      LReport := ComputeDifference(ABaselineId);
      LJudgment := TSpecEnums.DifferenceJudgmentFromStr(AAction);
      Result := LWorkflow.RecordDifferenceDecision(LReport, LJudgment, ARationale);
      FRender.RenderDecisionsPage(ListDecisions, FProjectService.ProjectName);
      FStatus.Info('AsWish.Difference', Format('Recorded decision %s (%s) for baseline %s',
        [Result, AAction, ABaselineId]));
    finally
      LWorkflow.Free;
    end;
  finally
    LDifference.Free;
  end;
end;

function TAsWishController.EvolveBaseline(const ABaselineId, ANote: string;
  out ANewBaseline: TAsWishBaseline): string;
var
  LDecId: string;
begin
  Result := EvolveBaseline(ABaselineId, ANote, ANewBaseline, LDecId);
end;

function TAsWishController.EvolveBaseline(const ABaselineId, ANote: string;
  out ANewBaseline: TAsWishBaseline; out ADecisionId: string): string;
var
  LWorkflow: TAsWishVisualWorkflowService;
  LDifference: TAsWishDifferenceService;
  LReport: TSpecDifferenceReport;
  LDecId: string;
begin
  ANewBaseline := Default(TAsWishBaseline);
  ADecisionId := '';
  if not FProjectService.IsOpen then
    raise Exception.Create('No project open');
  LDifference := TAsWishDifferenceService.Create(FSpecStore, FSnapshot);
  try
    LWorkflow := TAsWishVisualWorkflowService.Create(FSpecStore, FSnapshot, FDecisions, LDifference);
    try
      LReport := ComputeDifference(ABaselineId);
      LDecId := LWorkflow.RecordDifferenceDecision(LReport, djAcceptable, ANote, 'cs-evolve-' + ABaselineId);
      Result := LWorkflow.EvolveBaseline(ABaselineId, LDecId, ANewBaseline);
      RenderAll;
      FRender.RenderDecisionsPage(ListDecisions, FProjectService.ProjectName);
      ADecisionId := LDecId;
      FStatus.Info('AsWish.Evolve', Format('Evolved new Accepted Baseline %s (snapshot: %s, parent: %s)',
        [Result, ANewBaseline.SnapshotName, ABaselineId]));
    finally
      LWorkflow.Free;
    end;
  finally
    LDifference.Free;
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
