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
    [Test] procedure Test_Restart_KeepsDecisions;
    [Test] procedure Test_ChangeSet_EndToEnd_Accept;
    [Test] procedure Test_ChangeSet_EndToEnd_Reject;
    [Test] procedure Test_ChangeSet_EndToEnd_Clarify;
    [Test] procedure Test_ComputeDifference_GeneratesReportAndHtml;
    [Test] procedure Test_RecordDifferenceDecision_Unacceptable_PersistsDecision;
    [Test] procedure Test_EvolveBaseline_CreatesB0002_WithParentBaselineId;
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

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishController);

end.
