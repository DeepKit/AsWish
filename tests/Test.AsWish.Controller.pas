{ ============================================================================
  Test.AsWish.Controller

  Headless mock tests for the desktop-app workflow layer — the exact paths
  behind the GUI operations the user cannot automate from the CLI:
    - OpenAndScan        (Visualize button / open-project command)
    - RenderAll          (dashboard HTML)
    - ComputeHealthMetrics (dashboard numbers)
    - CreateTicket       (fog-map ticket-create button: defog + persist)
    - ApplyBundleDecisions (bundles.html Accept All / Reject All buttons)
    - restart persistence (decisions survive a fresh service instance)

  DeepShell interfaces are mocked (IShellStatusManager / IShellContextManager
  / IShellEventBus); all AsWish services are real. Project lives in a temp
  dir with a couple of sample files.

  String literals use #$XXXX escapes (dcc64 reads sources as ANSI; raw UTF-8
  text in .pas would be mis-decoded — repo convention, see bugfix #17).
  ============================================================================ }

unit Test.AsWish.Controller;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  AsWish.UI.Intf,
  AsWish.UI.Types,
  AsWish.Models,
  AsWish.Services.Project,
  AsWish.Services.Scan,
  AsWish.Services.SpecStore,
  AsWish.Services.TreeBuilder,
  AsWish.Services.Render,
  AsWish.Services.Prompts,
  AsWish.Services.Decisions,
  AsWish.Services.Settings,
  AsWish.Services.LLM,
  AsWish.Services.Snapshot,
  AsWish.Services.Difference,
  AsWish.Services.VisualWorkflow,
  AsWish.Shell.Headless,
  AsWish.Controller;

type
  TMockStatus = class(TInterfacedObject, IShellStatusManager)
  private
    FMessages: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const ASource, AMessage: string);
    procedure Warning(const ASource, AMessage: string);
    procedure LogError(const ASource, AMessage, ADetail: string);
    procedure ShellError(const ASource, AMessage, ADetail: string);
    procedure Progress(const ATaskId, ASource: string; APercent: Integer;
      const AMessage: string);
    procedure TaskStart(const ATaskId, ASource, AMessage: string);
    procedure TaskFinish(const ATaskId, AMessage: string);
    procedure Diagnostic(const ASource, AMessage: string);
    function GetEntries: TArray<TShellStatusEntry>;
    procedure ClearEntries;
    procedure SetSanitizer(ASanitizer: TShellStatusSanitizer);
    property Messages: TStringList read FMessages;
  end;

  TMockContext = class(TInterfacedObject, IShellContextManager)
  public
    function Current: TShellContext;
    procedure SetProject(const AProjectId, APath: string);
    procedure SetObject(const ARef: TShellObjectRef);
    procedure SetView(const AViewId, AViewType: string);
    procedure ClearProject;
  end;

  TMockBus = class(TInterfacedObject, IShellEventBus)
  private
    FEvents: TList<TDeepShellEvent>;
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(AKind: TDeepShellEventKind;
      AHandler: TShellEventHandler): string;
    function SubscribeAll(AHandler: TShellEventHandler): string;
    procedure Unsubscribe(const AToken: string);
    procedure Publish(const AEvent: TDeepShellEvent);
    procedure Shutdown;
    procedure SetOnDispatchError(AHandler: TProc<Exception, string>);
    property Events: TList<TDeepShellEvent> read FEvents;
  end;

  [TestFixture]
  TTestAsWishController = class
  private
    FDir: string;
    FProject: TAsWishProjectService;
    FScan: TAsWishScanService;
    FStore: TAsWishStoreService;
    FRender: TAsWishRenderService;
    FBuilder: TAsWishTreeBuilder;
    FPrompts: TAsWishPromptService;
    FDecisions: TAsWishDecisionsService;
    FSettings: TAsWishSettingsService;
    FLLM: TAsWishLLMService;
    FStatus: TMockStatus;
    FContext: TMockContext;
    FBus: TMockBus;
    FController: TAsWishController;
    function RootNodeId: string;
  public
    [Setup] procedure SetUp;
    [TearDown] procedure TearDown;
    /// <summary>Simulate an application restart: dispose the controller and
    ///  all services, rebuild them from the same project dir, and Load
    ///  persisted state (decisions).</summary>
    procedure RestartApp;

    [Test] procedure Test_OpenAndScan_BuildsEverything;
    [Test] procedure Test_OpenAndScan_PublishesProjectOpened;
    [Test] procedure Test_RenderAll_ProducesDashboardHtml;
    [Test] procedure Test_HealthMetrics_Numbers;
    [Test] procedure Test_CreateTicket_DefogsAndPersists;
    [Test] procedure Test_ApplyBundleDecisions_Accept;
    [Test] procedure Test_ApplyBundleDecisions_Reject;
    [Test] procedure Test_BundleApply_ResultContract_AndOriginNote;
    [Test] procedure Test_BundleApply_FailureCodes_WriteNoDecision;
    [Test] procedure Test_BundleApply_DiskFirst_DoesNotBlankRenderedTrees;
    [Test] procedure Test_Restart_KeepsDecisions;
    [Test] procedure Test_ChangeSet_EndToEnd_Accept;
    [Test] procedure Test_ChangeSet_Accept_IsIdempotent;
    [Test] procedure Test_ChangeSet_EndToEnd_Reject;
    [Test] procedure Test_ChangeSet_EndToEnd_Clarify;
    [Test] procedure Test_ChangeSet_DecisionResult_CarriesParsedIds;
    [Test] procedure Test_Accept_DiskFirst_DoesNotEmptyPersistedTree;
    [Test] procedure Test_ExportPrompt_AfterOpenOnly_StillDescribesTheTree;
    [Test] procedure Test_ComputeDifference_GeneratesReportAndHtml;
    [Test] procedure Test_RunScan_RendersEvidencePageBeforeTreePages;
    [Test] procedure Test_RecordDifferenceDecision_Unacceptable_PersistsDecision;
    [Test] procedure Test_EvolveBaseline_CreatesB0002_WithParentBaselineId;
  end;

  /// <summary>Drives the Controller the way the CLI does: with the real
  ///  headless shell (console status, in-memory context, in-process bus)
  ///  rather than mocks. This is the construction the CLI's scan command now
  ///  uses, so it is the only place that path is covered.</summary>
  [TestFixture]
  THeadlessShellTests = class
  private
    FDir: string;
    FProject: TAsWishProjectService;
    FScan: TAsWishScanService;
    FStore: TAsWishStoreService;
    FRender: TAsWishRenderService;
    FBuilder: TAsWishTreeBuilder;
    FPrompts: TAsWishPromptService;
    FDecisions: TAsWishDecisionsService;
    FSettings: TAsWishSettingsService;
    FLLM: TAsWishLLMService;
    FStatus: TConsoleStatusManager;
    FContext: THeadlessContextManager;
    FBus: THeadlessEventBus;
    FController: TAsWishController;
    FEventCount: Integer;
    procedure OnAnyEvent(const AEvent: TDeepShellEvent);
  public
    [Setup] procedure SetUp;
    [TearDown] procedure TearDown;
    [Test]
    procedure HeadlessScan_ProducesTheWholePageSet;
    [Test]
    procedure HeadlessScan_RecordsStatusAndContextAndEvent;
    [Test]
    procedure SilentStatusManager_StillRecordsEntries;
    [Test]
    procedure DifferencePath_MatchesWhatTheVisualWorkflowComputes;
  end;

implementation

{ TMockStatus }

constructor TMockStatus.Create;
begin
  inherited Create;
  FMessages := TStringList.Create;
end;

destructor TMockStatus.Destroy;
begin
  FMessages.Free;
  inherited;
end;

procedure TMockStatus.Info(const ASource, AMessage: string);
begin
  FMessages.Add('I: ' + AMessage);
end;

procedure TMockStatus.Warning(const ASource, AMessage: string);
begin
  FMessages.Add('W: ' + AMessage);
end;

procedure TMockStatus.LogError(const ASource, AMessage, ADetail: string);
begin
  FMessages.Add('E: ' + AMessage);
end;

procedure TMockStatus.ShellError(const ASource, AMessage, ADetail: string);
begin
  FMessages.Add('E: ' + AMessage);
end;

procedure TMockStatus.Progress(const ATaskId, ASource: string;
  APercent: Integer; const AMessage: string);
begin
  // no-op
end;

procedure TMockStatus.TaskStart(const ATaskId, ASource, AMessage: string);
begin
  // no-op
end;

procedure TMockStatus.TaskFinish(const ATaskId, AMessage: string);
begin
  // no-op
end;

procedure TMockStatus.Diagnostic(const ASource, AMessage: string);
begin
  // no-op
end;

function TMockStatus.GetEntries: TArray<TShellStatusEntry>;
begin
  Result := nil;
end;

procedure TMockStatus.ClearEntries;
begin
  // no-op
end;

procedure TMockStatus.SetSanitizer(ASanitizer: TShellStatusSanitizer);
begin
  // no-op
end;

{ TMockContext }

function TMockContext.Current: TShellContext;
begin
  Result := Default(TShellContext);
end;

procedure TMockContext.SetProject(const AProjectId, APath: string);
begin
  // no-op
end;

procedure TMockContext.SetObject(const ARef: TShellObjectRef);
begin
  // no-op
end;

procedure TMockContext.SetView(const AViewId, AViewType: string);
begin
  // no-op
end;

procedure TMockContext.ClearProject;
begin
  // no-op
end;

{ TMockBus }

constructor TMockBus.Create;
begin
  inherited Create;
  FEvents := TList<TDeepShellEvent>.Create;
end;

destructor TMockBus.Destroy;
begin
  FEvents.Free;
  inherited;
end;

function TMockBus.Subscribe(AKind: TDeepShellEventKind;
  AHandler: TShellEventHandler): string;
begin
  Result := 'tok';
end;

function TMockBus.SubscribeAll(AHandler: TShellEventHandler): string;
begin
  Result := 'tok-all';
end;

procedure TMockBus.Unsubscribe(const AToken: string);
begin
  // no-op
end;

procedure TMockBus.Publish(const AEvent: TDeepShellEvent);
begin
  FEvents.Add(AEvent);
end;

procedure TMockBus.Shutdown;
begin
  // no-op
end;

procedure TMockBus.SetOnDispatchError(AHandler: TProc<Exception, string>);
begin
  // no-op
end;

{ TTestAsWishController }

function TTestAsWishController.RootNodeId: string;
begin
  Result := '';
  for var N in FBuilder.FunctionNodes do
    if N.ParentId = '' then
      Exit(N.Id);
end;

procedure TTestAsWishController.SetUp;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'aswish-ctl-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FDir);
  TFile.WriteAllText(TPath.Combine(FDir, 'README.md'),
    '# mock project' + sLineBreak + 'Sample docs for controller tests.',
    TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(FDir, 'app.py'),
    'def hello():' + sLineBreak + '    return 42' + sLineBreak,
    TEncoding.UTF8);

  FProject := TAsWishProjectService.Create;
  FScan := TAsWishScanService.Create;
  FStore := TAsWishStoreService.Create;
  FRender := TAsWishRenderService.Create;
  FBuilder := TAsWishTreeBuilder.Create;
  FPrompts := TAsWishPromptService.Create;
  FDecisions := TAsWishDecisionsService.Create;
  FSettings := TAsWishSettingsService.Create;
  FLLM := TAsWishLLMService.Create('Default');
  FStatus := TMockStatus.Create;
  FContext := TMockContext.Create;
  FBus := TMockBus.Create;

  FController := TAsWishController.Create(FProject, FScan, FStore, FRender,
    FBuilder, FPrompts, FDecisions, FLLM, FSettings,
    FStatus, FContext, FBus);
  FController.OpenAndScan(FDir);
end;

procedure TTestAsWishController.TearDown;
begin
  // FStatus/FContext/FBus are TInterfacedObjects owned by the controller's
  // interface references — FController.Free releases them automatically;
  // manual Free here would double-free (Invalid pointer operation).
  // FLLM is a TInterfacedObject with no interface owner — like MainForm,
  // we do NOT Free it either.
  FController.Free;
  FSettings.Free;
  FDecisions.Free;
  FPrompts.Free;
  FBuilder.Free;
  FRender.Free;
  FStore.Free;
  FScan.Free;
  FProject.Free;
  TDirectory.Delete(FDir, True);
end;

procedure TTestAsWishController.RestartApp;
begin
  // Dispose everything, rebuild from disk, Load persisted state.
  // (Mock shell services are released via FController's interface refs.)
  FController.Free;
  FSettings.Free;
  FDecisions.Free;
  FPrompts.Free;
  FBuilder.Free;
  FRender.Free;
  FStore.Free;
  FScan.Free;
  FProject.Free;

  FProject := TAsWishProjectService.Create;
  FScan := TAsWishScanService.Create;
  FStore := TAsWishStoreService.Create;
  FRender := TAsWishRenderService.Create;
  FBuilder := TAsWishTreeBuilder.Create;
  FPrompts := TAsWishPromptService.Create;
  FDecisions := TAsWishDecisionsService.Create;
  FSettings := TAsWishSettingsService.Create;
  FLLM := TAsWishLLMService.Create('Default');
  FStatus := TMockStatus.Create;
  FContext := TMockContext.Create;
  FBus := TMockBus.Create;

  FProject.OpenProject(FDir);
  FStore.Initialize(FDir);
  FRender.Initialize(FProject.AsWishPath);
  FPrompts.Initialize(FProject.AsWishPath);
  FDecisions.Initialize(FProject.AsWishPath);
  FDecisions.Load;

  FController := TAsWishController.Create(FProject, FScan, FStore, FRender,
    FBuilder, FPrompts, FDecisions, FLLM, FSettings,
    FStatus, FContext, FBus);
end;

procedure TTestAsWishController.Test_OpenAndScan_BuildsEverything;
begin
  // Visualize button path: OpenAndScan -> scan + trees + renders + prompts.
  Assert.IsTrue(FScan.TotalFiles >= 2, 'scan should classify the sample files');
  Assert.IsTrue(TFile.Exists(TPath.Combine(FStore.BasePath,
    'trees\function-tree.yaml')), 'function tree must be persisted');
  Assert.IsTrue(TFile.Exists(TPath.Combine(FStore.BasePath,
    'trees\module-tree.yaml')), 'module tree must be persisted');
  Assert.IsTrue(TFile.Exists(TPath.Combine(FStore.BasePath,
    'html\index.html')), 'dashboard html must be rendered');
  Assert.IsTrue(FBuilder.FunctionNodes.Count >= 1,
    'function tree should have the project root node');
  Assert.IsTrue(FBuilder.ModuleNodes.Count >= 1,
    'module tree should have the app.py module');
end;

procedure TTestAsWishController.Test_OpenAndScan_PublishesProjectOpened;
var
  LFound: Boolean;
begin
  // The GUI refreshes its panels on sekProjectOpened (HandleScanEvent).
  LFound := False;
  for var LE in FBus.Events do
    if LE.Kind = sekProjectOpened then
      LFound := True;
  Assert.IsTrue(LFound, 'OpenAndScan must publish sekProjectOpened');
end;

procedure TTestAsWishController.Test_RenderAll_ProducesDashboardHtml;
var
  LHtml: string;
begin
  FController.RenderAll;
  LHtml := TFile.ReadAllText(TPath.Combine(FStore.BasePath,
    'html\index.html'), TEncoding.UTF8);
  // Dashboard section title is rendered (UTF-8 文档健康度).
  Assert.IsTrue(LHtml.Contains(#$6587#$6863#$5065#$5EB7#$5EA6),
    'index.html must contain the health-dashboard section');
  Assert.IsTrue(LHtml.Contains('function-tree.html'),
    'index.html must link the function tree page');
end;

procedure TTestAsWishController.Test_HealthMetrics_Numbers;
var
  LFunc, LMod, LView, LData: TList<TSpecNode>;
  LIssues: TList<TSpecIssue>;
  LIssue: TSpecIssue;
  LM: THealthMetrics;
begin
  // Pure-function check of the dashboard numbers: 3 nodes, 1 confirmed
  // high-confidence, 1 foggy; 1 open high-severity issue.
  LFunc := TList<TSpecNode>.Create;
  LMod := TList<TSpecNode>.Create;
  LView := TList<TSpecNode>.Create;
  LData := TList<TSpecNode>.Create;
  LIssues := TList<TSpecIssue>.Create;
  try
    var LN1 := TSpecNode.MakeNew('func-1', ttFunction, 'F1', 'feature');
    LN1.GenStatus := gsConfirmed;
    LN1.Confidence := clHigh;
    LFunc.Add(LN1);

    var LN2 := TSpecNode.MakeNew('func-2', ttFunction, 'F2', 'feature');
    LN2.GenStatus := gsGenerated;
    LN2.Confidence := clMedium;
    LN2.FogState := fsFoggy;
    LN2.HasFogState := True;
    LFunc.Add(LN2);

    var LN3 := TSpecNode.MakeNew('mod-1', ttModule, 'M1', 'module');
    LN3.GenStatus := gsGenerated;
    LN3.Confidence := clMedium;
    LMod.Add(LN3);

    LIssue := Default(TSpecIssue);
    LIssue.Id := 'issue-1';
    LIssue.Status := issOpen;
    LIssue.Severity := isCritical;
    LIssues.Add(LIssue);

    LM := TAsWishRenderService.ComputeHealthMetrics(
      LFunc, LMod, LView, LData, LIssues);

    Assert.AreEqual<Integer>(3, LM.TotalNodes, 'TotalNodes should be 3');
    Assert.AreEqual<Integer>(1, LM.ConfirmedNodes,
      'ConfirmedNodes should be 1');
    Assert.AreEqual<Integer>(1, LM.FogCount, 'FogCount should be 1');
    Assert.AreEqual<Integer>(1, LM.HighRiskOpen,
      'HighRiskOpen should be 1');
    Assert.AreEqual<Integer>(1, LM.DecisionBacklog,
      'DecisionBacklog should be 1');
    Assert.IsTrue(Abs(LM.CoveragePct - 100.0 / 3.0) < 0.001,
      'CoveragePct should be 33.33');
    Assert.IsTrue(Abs(LM.AvgConfidence - 0.8) < 0.001,
      'AvgConfidence should be (1.0+0.7+0.7)/3 = 0.8');
  finally
    LIssues.Free;
    LData.Free;
    LView.Free;
    LMod.Free;
    LFunc.Free;
  end;
end;

procedure TTestAsWishController.Test_CreateTicket_DefogsAndPersists;
var
  LRootId: string;
  LIssues: TList<TSpecIssue>;
  LNode: TSpecNode;
begin
  // Fog-map ticket-create button path. The function root starts foggy
  // (fsUnknownUnknowns by TreeBuilder design); creating a ticket must
  // defog one step and persist issues/doc-issues.yaml.
  LRootId := RootNodeId;
  Assert.IsNotEmpty(LRootId, 'function root must exist after scan');

  LNode := FBuilder.FindNodeById(LRootId);
  Assert.IsTrue(LNode.HasFogState and (LNode.FogState = fsUnknownUnknowns),
    'function root should start at fsUnknownUnknowns');

  FController.CreateTicket(LRootId, 'Research root');

  LNode := FBuilder.FindNodeById(LRootId);
  Assert.AreEqual<Integer>(Ord(fsFoggy), Ord(LNode.FogState),
    'ticket creation must defog the node one step (unknown_unknowns -> foggy)');

  LIssues := FStore.ReadIssuesFile('issues/doc-issues.yaml');
  try
    Assert.AreEqual<Integer>(1, LIssues.Count,
      'one research ticket must be persisted');
    Assert.AreEqual<Integer>(Ord(itResearchTicket),
      Ord(LIssues[0].IssueType), 'ticket type must be research_ticket');
    Assert.AreEqual<string>(LRootId, LIssues[0].AffectedNodes[0],
      'ticket must reference the fog node');
    Assert.IsTrue(LIssues[0].HasRequiresHuman and not LIssues[0].RequiresHuman,
      'research ticket defaults to AFK');
  finally
    LIssues.Free;
  end;
end;

procedure TTestAsWishController.Test_ApplyBundleDecisions_Accept;
var
  LBundles: TList<TSemanticBundle>;
  LB: TSemanticBundle;
  LFuncId, LModId: string;
  LNode: TSpecNode;
begin
  // bundles.html "Accept All" button path: one formal human decision over
  // all anchored nodes, transitions applied to every tree.
  LFuncId := RootNodeId;
  LModId := '';
  if FBuilder.ModuleNodes.Count > 0 then
    LModId := FBuilder.ModuleNodes[0].Id;
  Assert.IsNotEmpty(LModId, 'module node must exist');

  LB := Default(TSemanticBundle);
  LB.Id := 'bnd-1';
  LB.Title := 'Mock bundle';
  SetLength(LB.NodeIds, 2);
  LB.NodeIds[0] := LFuncId;
  LB.NodeIds[1] := LModId;
  LBundles := TList<TSemanticBundle>.Create;
  try
    LBundles.Add(LB);
    FStore.WriteBundlesFile('bundles.yaml', LBundles);
  finally
    LBundles.Free;
  end;

  FController.ApplyBundleDecisions('bundle-accept', 'bnd-1');

  LNode := FBuilder.FindNodeById(LFuncId);
  Assert.AreEqual<Integer>(Ord(gsConfirmed), Ord(LNode.GenStatus),
    'Accept All must confirm anchored function nodes');
  Assert.AreEqual<Integer>(Ord(rsAccepted), Ord(LNode.ReviewStatus));

  LNode := FBuilder.FindNodeById(LModId);
  Assert.AreEqual<Integer>(Ord(gsConfirmed), Ord(LNode.GenStatus),
    'Accept All must confirm anchored module nodes');

  Assert.IsTrue(TFile.Exists(TPath.Combine(FStore.BasePath,
    'decisions\requirement-decisions.yaml')),
    'decision must be persisted');
end;

procedure TTestAsWishController.Test_ApplyBundleDecisions_Reject;
var
  LBundles: TList<TSemanticBundle>;
  LB: TSemanticBundle;
  LFuncId: string;
  LNode: TSpecNode;
begin
  LFuncId := RootNodeId;
  LB := Default(TSemanticBundle);
  LB.Id := 'bnd-2';
  LB.Title := 'Reject bundle';
  SetLength(LB.NodeIds, 1);
  LB.NodeIds[0] := LFuncId;
  LBundles := TList<TSemanticBundle>.Create;
  try
    LBundles.Add(LB);
    FStore.WriteBundlesFile('bundles.yaml', LBundles);
  finally
    LBundles.Free;
  end;

  FController.ApplyBundleDecisions('bundle-reject', 'bnd-2');

  LNode := FBuilder.FindNodeById(LFuncId);
  Assert.AreEqual<Integer>(Ord(gsSkipped), Ord(LNode.GenStatus),
    'Reject All must skip anchored nodes (bugfix #15 semantics)');
  Assert.AreEqual<Integer>(Ord(rsRejected), Ord(LNode.ReviewStatus));
end;

procedure TTestAsWishController.Test_BundleApply_ResultContract_AndOriginNote;
var
  LBundles: TList<TSemanticBundle>;
  LB: TSemanticBundle;
  LFuncId, LModId: string;
  LResult: TBundleApplyResult;
  LDec: TSpecDecision;
begin
  // The four-argument overload exists for a caller with no status pane: it
  // must hand back everything that surface prints instead of only narrating
  // it, which is what let the CLI drop its own copy of the whole batch
  // review (bundle lookup, decision recording, four-tree transition pass).
  LFuncId := RootNodeId;
  LModId := '';
  if FBuilder.ModuleNodes.Count > 0 then
    LModId := FBuilder.ModuleNodes[0].Id;
  Assert.IsNotEmpty(LModId, 'module node must exist');

  LB := Default(TSemanticBundle);
  LB.Id := 'bnd-r1';
  LB.Title := 'Result contract bundle';
  SetLength(LB.NodeIds, 2);
  LB.NodeIds[0] := LFuncId;
  LB.NodeIds[1] := LModId;
  LBundles := TList<TSemanticBundle>.Create;
  try
    LBundles.Add(LB);
    FStore.WriteBundlesFile('bundles.yaml', LBundles);
  finally
    LBundles.Free;
  end;

  Assert.IsTrue(FController.ApplyBundleDecisions('bundle-accept', 'bnd-r1',
    'Recorded via test', LResult), 'accepting a real bundle must succeed');
  Assert.IsTrue(LResult.Ok);
  Assert.AreEqual<string>('bnd-r1', LResult.BundleId);
  Assert.AreEqual<string>('Result contract bundle', LResult.BundleTitle);
  Assert.IsNotEmpty(LResult.DecisionId);
  Assert.AreEqual<Integer>(2, LResult.NodeCount);
  Assert.IsTrue(Length(LResult.TreesTouched) > 0,
    'the rewritten-tree list is what the per-tree lines are printed from');

  // The origin note is the ledger's "who decided". It has to arrive verbatim:
  // the GUI default names WebView2, and a CLI that reused it would file a
  // decision crediting a browser bridge that was never involved.
  LDec := FDecisions.FindById(LResult.DecisionId);
  Assert.AreEqual<string>('Recorded via test', LDec.Rationale);
end;

procedure TTestAsWishController.Test_BundleApply_FailureCodes_WriteNoDecision;
var
  LBundles: TList<TSemanticBundle>;
  LB: TSemanticBundle;
  LResult: TBundleApplyResult;
begin
  LB := Default(TSemanticBundle);
  LB.Id := 'bnd-empty';
  LB.Title := 'No anchored nodes';
  SetLength(LB.NodeIds, 0);
  LBundles := TList<TSemanticBundle>.Create;
  try
    LBundles.Add(LB);
    FStore.WriteBundlesFile('bundles.yaml', LBundles);
  finally
    LBundles.Free;
  end;

  Assert.IsFalse(FController.ApplyBundleDecisions('bundle-accept', 'nope',
    'Recorded via test', LResult), 'an unknown bundle must fail');
  Assert.AreEqual<string>('bundle-not-found', LResult.Failure);

  // The old CLI kept no such guard: it recorded a formal decision anchored
  // to zero nodes, then reported success. A decision nothing can ever act
  // on is a ledger entry that only looks like a decision.
  Assert.IsFalse(FController.ApplyBundleDecisions('bundle-accept', 'bnd-empty',
    'Recorded via test', LResult), 'a bundle with no anchored nodes must fail');
  Assert.AreEqual<string>('bundle-no-nodes', LResult.Failure);

  // Neither failure may leave anything behind: dec-0001 is the first id the
  // service hands out, so its absence proves no decision was recorded.
  Assert.IsEmpty(FDecisions.FindById('dec-0001').Id,
    'a refused batch review must not write a decision');
end;

procedure TTestAsWishController.Test_BundleApply_DiskFirst_DoesNotBlankRenderedTrees;
var
  LBundles: TList<TSemanticBundle>;
  LB: TSemanticBundle;
  LFuncId, LTreeHtml: string;
  LResult: TBundleApplyResult;
begin
  // A one-shot CLI process has no scan and no live builder, so this is the
  // state it batch-reviews in. The Controller reloads the builder from disk
  // after the transition pass precisely so the closing RenderAll describes
  // real trees; drop that reload and the pages get rewritten as blanks.
  LFuncId := RootNodeId;
  Assert.IsNotEmpty(LFuncId, 'fixture must have a root function node');

  LB := Default(TSemanticBundle);
  LB.Id := 'bnd-df';
  LB.Title := 'Disk-first bundle';
  SetLength(LB.NodeIds, 1);
  LB.NodeIds[0] := LFuncId;
  LBundles := TList<TSemanticBundle>.Create;
  try
    LBundles.Add(LB);
    FStore.WriteBundlesFile('bundles.yaml', LBundles);
  finally
    LBundles.Free;
  end;

  RestartApp;
  Assert.AreEqual<Integer>(0, FBuilder.FunctionNodes.Count,
    'a restarted controller starts with an empty builder, like a one-shot CLI');

  Assert.IsTrue(FController.ApplyBundleDecisions('bundle-accept', 'bnd-df',
    'Recorded via test', LResult), 'disk-first bundle accept must succeed');

  LTreeHtml := TFile.ReadAllText(TPath.Combine(FStore.BasePath, 'html',
    'function-tree.html'), TEncoding.UTF8);
  Assert.IsTrue(LTreeHtml.Contains(LFuncId),
    'RenderAll after a disk-first accept must not blank the rendered tree');
end;

procedure TTestAsWishController.Test_Restart_KeepsDecisions;
var
  LBundles: TList<TSemanticBundle>;
  LB: TSemanticBundle;
  LFuncId: string;
  LDec: TSpecDecision;
begin
  // Accept a bundle, then simulate an app restart. The persisted decision
  // (incl. target_nodes + type — bugfix #18) must survive and be loadable.
  LFuncId := RootNodeId;
  LB := Default(TSemanticBundle);
  LB.Id := 'bnd-3';
  LB.Title := 'Restart bundle';
  SetLength(LB.NodeIds, 1);
  LB.NodeIds[0] := LFuncId;
  LBundles := TList<TSemanticBundle>.Create;
  try
    LBundles.Add(LB);
    FStore.WriteBundlesFile('bundles.yaml', LBundles);
  finally
    LBundles.Free;
  end;
  FController.ApplyBundleDecisions('bundle-accept', 'bnd-3');

  RestartApp;

  // #18 regression: Load must read back type + target_nodes.
  LDec := FDecisions.FindById('dec-0001');
  Assert.IsNotEmpty(LDec.Id, 'decision must survive restart');
  Assert.AreEqual<Integer>(Ord(dtConfirm), Ord(LDec.DecisionType),
    'decision type must round-trip (bugfix #18)');
  Assert.AreEqual<Integer>(1, Length(LDec.TargetNodes),
    'target nodes must round-trip (bugfix #18)');
  Assert.AreEqual<string>(LFuncId, LDec.TargetNodes[0]);
end;

procedure TTestAsWishController.Test_ChangeSet_EndToEnd_Accept;
var
  LFuncId, LCSId, LReview: string;
  LOK: Boolean;
  LNode: TSpecNode;
  LDiskNodes: TList<TSpecNode>;
begin
  LFuncId := RootNodeId;
  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'User wants dark mode theme option');
  Assert.IsNotEmpty(LCSId, 'SubmitUserIntent must return ChangeSet ID');

  LReview := FController.ReviewChangeSet(LCSId);
  Assert.IsTrue(LReview.Contains('User wants dark mode theme option'), 'Review must show raw user intent');
  Assert.IsTrue(LReview.Contains(LFuncId), 'Review must show target node ID');

  LOK := FController.AcceptChangeSet(LCSId, 'Approved dark mode theme');
  Assert.IsTrue(LOK, 'AcceptChangeSet must succeed');

  // Verify memory tree
  LNode := FBuilder.FindNodeById(LFuncId);
  Assert.AreEqual('User wants dark mode theme option', LNode.Summary, 'Summary must be updated in memory');
  Assert.AreEqual<Integer>(Ord(rsAccepted), Ord(LNode.ReviewStatus), 'ReviewStatus must be accepted');
  Assert.AreEqual<Integer>(Ord(gsConfirmed), Ord(LNode.GenStatus), 'GenStatus must be confirmed');
  Assert.IsTrue(Length(LNode.DecisionRefs) > 0, 'DecisionRefs must be recorded');

  // Verify disk tree (Canonical Spec)
  LDiskNodes := FStore.ReadTreeFile('trees/function-tree.yaml');
  try
    Assert.AreEqual('User wants dark mode theme option', LDiskNodes[0].Summary,
      'Canonical Spec on disk must be updated after Accept');
  finally
    LDiskNodes.Free;
  end;
end;

procedure TTestAsWishController.Test_ChangeSet_Accept_IsIdempotent;
var
  LFuncId, LCSId: string;
  LOK: Boolean;
  LNode: TSpecNode;
  LDecs: TArray<TSpecDecision>;
  LFirstDecisionRef: string;
  I: Integer;
begin
  LFuncId := RootNodeId;
  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'Duplicate accept probe');

  LOK := FController.AcceptChangeSet(LCSId, 'First accept');
  Assert.IsTrue(LOK, 'First AcceptChangeSet must succeed');

  LFirstDecisionRef := FBuilder.FindNodeById(LFuncId).DecisionRefs[0];

  // Second accept of the SAME changeset must be a no-op, not a second mutation
  LOK := FController.AcceptChangeSet(LCSId, 'Second accept (must be ignored)');
  Assert.IsTrue(LOK, 'Duplicate AcceptChangeSet must still report success');

  LNode := FBuilder.FindNodeById(LFuncId);
  Assert.AreEqual<Integer>(1, Length(LNode.DecisionRefs),
    'DecisionRefs must not grow on duplicate accept');
  Assert.AreEqual<string>(LFirstDecisionRef, LNode.DecisionRefs[0],
    'Original decision ref must be preserved on duplicate accept');

  LDecs := FDecisions.FindAcceptedByChangeSet(LCSId);
  Assert.AreEqual<Integer>(1, Length(LDecs),
    'Exactly one accepted decision per ChangeSet (idempotency invariant)');

  for I := 0 to High(LDecs) do
    Assert.AreEqual<string>(LFirstDecisionRef, LDecs[I].Id,
      'Accepted decision id must match the recorded DecisionRef');
end;

procedure TTestAsWishController.Test_ChangeSet_EndToEnd_Reject;
var
  LFuncId, LCSId, LOldSummary: string;
  LOK: Boolean;
  LNode: TSpecNode;
  LDiskNodes: TList<TSpecNode>;
begin
  LFuncId := RootNodeId;
  LOldSummary := FBuilder.FindNodeById(LFuncId).Summary;

  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'Unsafe dangerous change');
  Assert.IsNotEmpty(LCSId);

  LOK := FController.RejectChangeSet(LCSId, 'Unsafe modification rejected by human');
  Assert.IsTrue(LOK, 'RejectChangeSet must succeed');

  // Verify memory tree is untouched
  LNode := FBuilder.FindNodeById(LFuncId);
  Assert.AreEqual(LOldSummary, LNode.Summary, 'Memory tree must NOT be mutated on Reject');

  // Verify disk tree (Canonical Spec) is untouched
  LDiskNodes := FStore.ReadTreeFile('trees/function-tree.yaml');
  try
    Assert.AreEqual(LOldSummary, LDiskNodes[0].Summary, 'Canonical Spec on disk MUST NOT be modified on Reject');
  finally
    LDiskNodes.Free;
  end;
end;

procedure TTestAsWishController.Test_ChangeSet_EndToEnd_Clarify;
var
  LFuncId, LCSId, LOldSummary: string;
  LOK: Boolean;
  LNode: TSpecNode;
  LDiskNodes: TList<TSpecNode>;
begin
  LFuncId := RootNodeId;
  LOldSummary := FBuilder.FindNodeById(LFuncId).Summary;

  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'Ambiguous intent');
  Assert.IsNotEmpty(LCSId);

  LOK := FController.ClarifyChangeSet(LCSId, 'Please specify which component should be changed');
  Assert.IsTrue(LOK, 'ClarifyChangeSet must succeed');

  // Verify memory tree is untouched
  LNode := FBuilder.FindNodeById(LFuncId);
  Assert.AreEqual(LOldSummary, LNode.Summary, 'Memory tree must NOT be mutated on Clarify');

  // Verify disk tree is untouched
  LDiskNodes := FStore.ReadTreeFile('trees/function-tree.yaml');
  try
    Assert.AreEqual(LOldSummary, LDiskNodes[0].Summary, 'Canonical Spec on disk MUST NOT be modified on Clarify');
  finally
    LDiskNodes.Free;
  end;
end;

procedure TTestAsWishController.Test_ChangeSet_DecisionResult_CarriesParsedIds;
var
  LCsDir, LCsFile: string;
  LResult: TChangeSetDecisionResult;
  procedure WriteCs(const AId, AIntent: string);
  begin
    TFile.WriteAllText(LCsFile, 'change_set_id: "' + AId + '"'#10 +
      'intent_node_id: "func-alias-probe"'#10 + 'intent_tree: "function"'#10 +
      'raw_user_intent: "' + AIntent + '"'#10 +
      'author: "test"'#10 + 'items: []'#10, TEncoding.UTF8);
  end;
begin
  // The CLI prints change_set_id straight out of this record. It has to be the
  // id the change set declares, not the id the caller typed: LoadChangeSet
  // resolves a filename alias down to whatever change_set_id the file holds,
  // so the two legitimately differ. A caller that echoed its own argument back
  // would print the alias -- which is what the CLI did before this record
  // existed, and what a shortcut implementation of it reverts to.
  LCsDir := TPath.Combine(TPath.Combine(FDir, '.AsWish'), 'llm');
  TDirectory.CreateDirectory(LCsDir);
  LCsFile := TPath.Combine(LCsDir, 'change-set-cs-alias.yaml');
  WriteCs('cs-internal-777', 'alias resolution probe');

  Assert.IsTrue(FController.RejectChangeSet('cs-alias', 'rejected by alias', LResult),
    'reject by filename alias must succeed');
  Assert.IsTrue(LResult.Ok, 'result must report success');
  Assert.AreEqual<string>('cs-internal-777', LResult.ChangeSetId,
    'the result must carry the parsed change set id, not the alias the caller passed');
  Assert.IsNotEmpty(LResult.DecisionId, 'the result must carry the recorded decision id');

  WriteCs('cs-internal-778', 'alias resolution probe 2');
  Assert.IsTrue(FController.ClarifyChangeSet('cs-alias', 'clarify by alias', LResult),
    'clarify by filename alias must succeed');
  Assert.AreEqual<string>('cs-internal-778', LResult.ChangeSetId,
    'clarify must carry the parsed change set id too');

  // A miss must leave every field empty, not whatever was on the stack.
  LResult.ChangeSetId := 'stale';
  LResult.DecisionId := 'stale';
  Assert.IsFalse(FController.RejectChangeSet('cs-no-such-set', 'x', LResult),
    'rejecting an unknown change set must fail');
  Assert.IsFalse(LResult.Ok, 'result must report failure');
  Assert.AreEqual<string>('', LResult.ChangeSetId,
    'a failed reject must clear the change set id');
  Assert.AreEqual<string>('', LResult.DecisionId,
    'a failed reject must clear the decision id');

  Assert.IsFalse(FController.ClarifyChangeSet('cs-no-such-set', 'x', LResult),
    'clarifying an unknown change set must fail');
  Assert.IsFalse(LResult.Ok, 'result must report failure');
  Assert.AreEqual<string>('', LResult.DecisionId,
    'a failed clarify must clear the decision id');
end;

procedure TTestAsWishController.Test_Accept_DiskFirst_DoesNotEmptyPersistedTree;
var
  LFuncId, LCSId, LTreeText: string;
  LResult: TChangeSetDecisionResult;
begin
  // Reproduces the CLI's state exactly: a controller opened from disk with
  // nothing in the builder. AcceptChangeSet applies to the live trees and then
  // writes them back, so if the disk-first path does not read the persisted
  // trees in first, ApplyChangeSet finds no nodes to update and the write-back
  // that follows replaces the Canonical Spec with empty tree files.
  LFuncId := RootNodeId;
  Assert.IsNotEmpty(LFuncId, 'fixture must have a root function node');
  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'Disk-first accept test');

  RestartApp;
  Assert.AreEqual<Integer>(0, FBuilder.FunctionNodes.Count,
    'a restarted controller starts with an empty builder, like a one-shot CLI');

  Assert.IsTrue(FController.AcceptChangeSet(LCSId, 'Accept from disk', True, LResult),
    'disk-first accept must succeed');
  Assert.IsTrue(LResult.Ok);
  Assert.AreEqual(LCSId, LResult.ChangeSetId);

  LTreeText := TFile.ReadAllText(TPath.Combine(FStore.BasePath,
    'trees\function-tree.yaml'), TEncoding.UTF8);
  Assert.IsTrue(LTreeText.Contains(LFuncId),
    'the persisted function tree must still hold the root node -- an empty tree '
    + 'file means the change set was applied to nothing and then written back');
end;

procedure TTestAsWishController.Test_ExportPrompt_AfterOpenOnly_StillDescribesTheTree;
var
  LPack, LGen: string;
begin
  // The CLI's generate command opens the project and exports the prompt pack
  // in one go, without a Visualize click in between. ExportPrompt used to
  // consume whatever the last scan left behind, so that command produced a
  // pack claiming the project had no files and an unknown type -- the pack was
  // correct only for a caller that happened to have scanned first.
  FController.OpenProject(FDir);
  FController.ExportPrompt;

  LPack := TFile.ReadAllText(TPath.Combine(FStore.BasePath,
    'prompts\context-pack.md'), TEncoding.UTF8);
  Assert.IsFalse(LPack.Contains('- Type: unknown'),
    'the context pack must not claim an unknown project type when the source tree is readable');
  Assert.IsFalse(LPack.Contains('| Total | 0 |'),
    'the context pack must count the project files, not report an empty scan');

  LGen := TFile.ReadAllText(TPath.Combine(FStore.BasePath,
    'prompts\doc-optimization-prompt.md'), TEncoding.UTF8);
  Assert.IsFalse(LGen.Contains('unknown project'),
    'the generation prompt must name the real project type');
end;

procedure TTestAsWishController.Test_ComputeDifference_GeneratesReportAndHtml;
var
  LFuncId, LCSId: string;
  LReport: TSpecDifferenceReport;
  LHtml: string;
begin
  LFuncId := RootNodeId;
  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'Initial function spec');
  Assert.IsTrue(FController.AcceptChangeSet(LCSId, 'Accept initial baseline B-0001'));

  // Collect initial evidence and modify source file
  TFile.WriteAllText(TPath.Combine(FDir, 'app.py'),
    'def hello():' + sLineBreak + '    return 42' + sLineBreak +
    'def world():' + sLineBreak + '    return 100' + sLineBreak,
    TEncoding.UTF8);
  FController.RunScan;

  LReport := FController.ComputeDifference('B-0001');
  Assert.AreEqual('B-0001', LReport.BaselineId);
  Assert.IsTrue(Length(LReport.Items) > 0, 'Difference items must be detected');

  // Verify difference.html was generated
  LHtml := TFile.ReadAllText(TPath.Combine(FStore.BasePath, 'html\difference.html'), TEncoding.UTF8);
  Assert.IsTrue(LHtml.Contains('B-0001'), 'difference.html must contain baseline ID');
  Assert.IsTrue(LHtml.Contains('difference-judge'), 'difference.html must contain judgment action bridge');
end;

procedure TTestAsWishController.Test_RunScan_RendersEvidencePageBeforeTreePages;
var
  LHtmlDir: string;
  LFiles: TArray<string>;
  LFile: string;
  LAnyLink, LBareId: Boolean;
begin
  // GUI regression for the CLI/GUI fork: the Controller's own scan sequence
  // rendered the tree pages without ever writing evidence.html, so every
  // evidence id it printed stayed an unresolvable code in the desktop app
  // while the CLI already showed the fixed links.
  FController.RunScan;

  LHtmlDir := TPath.Combine(FStore.BasePath, 'html');
  Assert.IsTrue(TFile.Exists(TPath.Combine(LHtmlDir, 'evidence.html')),
    'Controller scan must write evidence.html, not just the tree pages');

  LAnyLink := False;
  LBareId := False;
  LFiles := TDirectory.GetFiles(LHtmlDir, '*-tree.html');
  Assert.IsTrue(Length(LFiles) > 0, 'fixture must produce tree pages');
  for LFile in LFiles do
  begin
    var LHtml := TFile.ReadAllText(LFile, TEncoding.UTF8);
    if LHtml.Contains('href="evidence.html#') then
      LAnyLink := True;
    if LHtml.Contains('<span class="trust-item trust-ref">') then
      LBareId := True;
  end;

  Assert.IsTrue(LAnyLink,
    'tree pages must link evidence ids into the evidence catalog');
  Assert.IsFalse(LBareId,
    'no tree page may print a bare evidence id once evidence.html exists');
end;

procedure TTestAsWishController.Test_RecordDifferenceDecision_Unacceptable_PersistsDecision;
var
  LFuncId, LCSId, LDecId, LHtml: string;
  LDec: TSpecDecision;
begin
  LFuncId := RootNodeId;
  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'Base feature spec');
  Assert.IsTrue(FController.AcceptChangeSet(LCSId, 'Accept B-0001'));

  // Alter code to cause structural diff
  TFile.WriteAllText(TPath.Combine(FDir, 'extra.py'), 'def extra(): pass' + sLineBreak, TEncoding.UTF8);
  FController.RunScan;

  LDecId := FController.RecordDifferenceDecision('B-0001', 'unacceptable', 'Feature rejected for revision');
  Assert.IsNotEmpty(LDecId, 'Decision ID must be returned');

  LDec := FDecisions.FindById(LDecId);
  Assert.AreEqual(dsRejected, LDec.Status, 'Decision status must be rejected');
  Assert.IsTrue(Length(LDec.TargetNodes) > 0, 'Decision must target difference nodes');

  // Verify decisions.html was rendered
  LHtml := TFile.ReadAllText(TPath.Combine(FStore.BasePath, 'html\decisions.html'), TEncoding.UTF8);
  Assert.IsTrue(LHtml.Contains(LDecId), 'decisions.html must contain decision ID');
end;

procedure TTestAsWishController.Test_EvolveBaseline_CreatesB0002_WithParentBaselineId;
var
  LFuncId, LCSId, LNewBaseId, LSnapText: string;
  LNewBaseline: TAsWishBaseline;
  LSnapFile: string;
begin
  LFuncId := RootNodeId;
  LCSId := FController.SubmitUserIntent(LFuncId, ttFunction, 'Baseline evolution test');
  Assert.IsTrue(FController.AcceptChangeSet(LCSId, 'Accept B-0001'));

  // Add new implementation
  TFile.WriteAllText(TPath.Combine(FDir, 'service.py'), 'def serve(): return True' + sLineBreak, TEncoding.UTF8);
  FController.RunScan;

  LNewBaseId := FController.EvolveBaseline('B-0001', 'Evolve B-0002 from reality', LNewBaseline);
  Assert.AreEqual('B-0002', LNewBaseId, 'Evolved baseline must be B-0002');
  Assert.AreEqual('B-0001', LNewBaseline.Lineage.ParentBaselineId, 'Parent baseline must be B-0001');

  // Verify snapshot file on disk contains parent_baseline_id
  LSnapFile := TPath.Combine(FStore.BasePath, 'snapshots\' + LNewBaseline.SnapshotName + '\snapshot.yaml');
  Assert.IsTrue(TFile.Exists(LSnapFile), 'Snapshot file must exist on disk');
  LSnapText := TFile.ReadAllText(LSnapFile, TEncoding.UTF8);
  Assert.IsTrue(LSnapText.Contains('parent_baseline_id: "B-0001"'), 'Snapshot must contain parent_baseline_id');

  // Verify dual gates
  Assert.IsTrue(FController.VerifyBaseline('B-0001'), 'B-0001 must verify');
  Assert.IsTrue(FController.VerifyBaseline('B-0002'), 'B-0002 must verify');
end;

{ THeadlessShellTests }

procedure THeadlessShellTests.SetUp;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'aswish-headless-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FDir);
  TFile.WriteAllText(TPath.Combine(FDir, 'README.md'),
    '# headless fixture' + sLineBreak + 'Sample docs for headless tests.',
    TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(FDir, 'app.pas'),
    'unit app;' + sLineBreak + 'end.' + sLineBreak, TEncoding.UTF8);

  FEventCount := 0;
  FProject := TAsWishProjectService.Create;
  FScan := TAsWishScanService.Create;
  FStore := TAsWishStoreService.Create;
  FRender := TAsWishRenderService.Create;
  FBuilder := TAsWishTreeBuilder.Create;
  FPrompts := TAsWishPromptService.Create;
  FDecisions := TAsWishDecisionsService.Create;
  FSettings := TAsWishSettingsService.Create;
  FLLM := TAsWishLLMService.Create('Default');
  // Silent: a scan under test must not write to the test runner's console.
  FStatus := TConsoleStatusManager.Create(True);
  FContext := THeadlessContextManager.Create;
  FBus := THeadlessEventBus.Create;

  FController := TAsWishController.Create(FProject, FScan, FStore, FRender,
    FBuilder, FPrompts, FDecisions, FLLM, FSettings,
    FStatus, FContext, FBus);
  FBus.SubscribeAll(OnAnyEvent);
end;

procedure THeadlessShellTests.TearDown;
begin
  // The headless shell objects are released through the controller's
  // interface references, like the mocks above.
  FController.Free;
  FSettings.Free;
  FDecisions.Free;
  FPrompts.Free;
  FBuilder.Free;
  FRender.Free;
  FStore.Free;
  FScan.Free;
  FProject.Free;
  if TDirectory.Exists(FDir) then
    TDirectory.Delete(FDir, True);
end;

procedure THeadlessShellTests.OnAnyEvent(const AEvent: TDeepShellEvent);
begin
  Inc(FEventCount);
end;

procedure THeadlessShellTests.HeadlessScan_ProducesTheWholePageSet;
var
  LHtmlDir: string;
begin
  // The CLI no longer lists the pages itself, so the only thing that can go
  // wrong here is the headless shell itself failing to carry the run.
  FController.OpenAndScan(FDir);

  Assert.IsFalse(FController.ScanFailed, 'a clean scan must not report failure');
  LHtmlDir := TPath.Combine(FStore.BasePath, 'html');
  for var LName in TArray<string>.Create('index.html', 'scan-report.html',
    'evidence.html', 'function-tree.html', 'module-tree.html',
    'view-tree.html', 'problems.html') do
    Assert.IsTrue(TFile.Exists(TPath.Combine(LHtmlDir, LName)),
      LName + ' must be produced by a headless scan');

  var LFuncHtml := TFile.ReadAllText(
    TPath.Combine(LHtmlDir, 'function-tree.html'), TEncoding.UTF8);
  Assert.IsTrue(LFuncHtml.Contains('href="evidence.html#'),
    'a headless scan must render the evidence catalog before the tree pages');
end;

procedure THeadlessShellTests.HeadlessScan_RecordsStatusAndContextAndEvent;
begin
  FController.OpenAndScan(FDir);

  Assert.IsTrue(Length(FStatus.GetEntries) > 0,
    'the status channel must carry the run, not swallow it');
  Assert.IsTrue(FEventCount > 0,
    'the scan-complete event must reach a subscriber through the headless bus');
  // The project service names a project after its directory, so that is what
  // the context must end up holding -- the point is that the controller told
  // the shell which project it opened.
  Assert.AreEqual<string>(TPath.GetFileName(FDir), FContext.Current.ProjectId,
    'the headless context must record the project the controller opened');
end;

procedure THeadlessShellTests.SilentStatusManager_StillRecordsEntries;
var
  LStatus: TConsoleStatusManager;
begin
  // Silence must suppress printing only. Dropping the entries would leave a
  // headless caller with no way to report what happened.
  LStatus := TConsoleStatusManager.Create(True);
  try
    LStatus.Warning('AsWish.Scan', 'degraded excerpt');
    LStatus.Info('AsWish.Scan', 'plain note');
    Assert.AreEqual<Integer>(2, Length(LStatus.GetEntries),
      'silent mode must still record every entry');
  finally
    LStatus.Free;
  end;
end;

// The desktop app and the CLI are two doors into the same computation. This
// pins them together: whatever TAsWishController.ComputeDifference answers must
// be what the visual workflow answers, item for item. Before WO-20260925-0053
// the Controller called the Difference service directly with a nil resolver,
// which left the VCL comparator unregistered -- so the desktop app never ran
// the L2/L3 visual comparison and always reported it as degraded, while the
// CLI ran it. The two doors answered different questions.
procedure THeadlessShellTests.DifferencePath_MatchesWhatTheVisualWorkflowComputes;
var
  LBaseId: string;
  LControllerReport, LWorkflowReport: TSpecDifferenceReport;
  LSnapshot: TAsWishSnapshotService;
  LDifference: TAsWishDifferenceService;
  LWorkflow: TAsWishVisualWorkflowService;
  LControllerIds, LWorkflowIds: TStringList;
  LItem: TSpecDifferenceItem;
begin
  // A .dfm gives the scan View Spec nodes, which is what a visual baseline is
  // built from -- and a view baseline is the only kind the VCL comparator can
  // handle, so it is the only kind that can expose the divergence.
  ForceDirectories(TPath.Combine(FDir, 'src'));
  TFile.WriteAllText(TPath.Combine(FDir, 'src\MainForm.dfm'),
    'object MainForm: TMainForm' + sLineBreak +
    '  Caption = ''Main''' + sLineBreak +
    'end' + sLineBreak, TEncoding.UTF8);
  FController.OpenAndScan(FDir);

  LBaseId := FController.ConfirmVisualBaseline('visual baseline for difference comparison');
  Assert.AreEqual('B-0001', LBaseId, 'fixture must produce a visual baseline');
  Assert.AreEqual('view', FController.ListBaselines[0].TreeType,
    'fixture sanity: the baseline must be a view baseline');

  LControllerReport := FController.ComputeDifference(LBaseId);
  Assert.IsFalse(LControllerReport.IsDegraded,
    'the Controller path must not degrade the visual comparison; it did before ' +
    'WO-20260925-0053 because it never registered the VCL comparator. Reason: ' +
    LControllerReport.DegradedReason);

  // Now the same computation through the workflow, which is what the CLI uses.
  LSnapshot := TAsWishSnapshotService.Create(FStore);
  try
    LDifference := TAsWishDifferenceService.Create(FStore, LSnapshot);
    try
      LWorkflow := TAsWishVisualWorkflowService.Create(FStore, LSnapshot,
        FDecisions, LDifference);
      try
        LWorkflowReport := LWorkflow.ComputeDifference(FDir, LBaseId);
      finally
        LWorkflow.Free;
      end;
    finally
      LDifference.Free;
    end;
  finally
    LSnapshot.Free;
  end;

  LControllerIds := TStringList.Create;
  LWorkflowIds := TStringList.Create;
  try
    LControllerIds.Sorted := True;
    LWorkflowIds.Sorted := True;
    LControllerIds.Duplicates := TDuplicates.dupAccept;
    LWorkflowIds.Duplicates := TDuplicates.dupAccept;
    for LItem in LControllerReport.Items do
      LControllerIds.Add(LItem.NodeId + '|' + TSpecEnums.DifferenceKindToStr(LItem.Kind));
    for LItem in LWorkflowReport.Items do
      LWorkflowIds.Add(LItem.NodeId + '|' + TSpecEnums.DifferenceKindToStr(LItem.Kind));

    Assert.AreEqual(LWorkflowIds.Count, LControllerIds.Count,
      'the Controller and the workflow must find the same number of differences');
    for var I := 0 to LWorkflowIds.Count - 1 do
      Assert.AreEqual(LWorkflowIds[I], LControllerIds[I],
        'difference ' + IntToStr(I) + ' must match between the two entry points');
  finally
    LControllerIds.Free;
    LWorkflowIds.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishController);
  TDUnitX.RegisterTestFixture(THeadlessShellTests);

end.
