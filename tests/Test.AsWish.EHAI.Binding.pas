{ ============================================================================
  Test.AsWish.EHAI.Binding
  
  Tier C Verification Suite for EHAI Reference Product Binding 001:
    - ASWISH-V-001: ReviewChangeSet surface is read-only presentation (zero canonical mutation)
    - ASWISH-V-002: Canonical mutation gate (AcceptChangeSet mutates spec only upon human commitment)
    - ASWISH-V-003: Accepted Baseline (AcceptChangeSet freezes immutable baseline with parent lineage)
    - ASWISH-V-004: Higher-level / unanchored Frame Rejection (FR-AW-01: does not become option 4,
                    does not rewrite rejected node summary, preserves frame rejection + human source + higher-level intent)
    - ASWISH-V-005: HB interaction -> Common Semantic -> AsWish Binding -> Product Effect (E2E)
    - ASWISH-V-006: CandidateSelection != Inherent Commitment
    - ASWISH-V-007: Regenerate (8) pure exploration within frame
    - ASWISH-V-008: BackNavigation (0) does not revoke prior decisions or alter baselines
  ============================================================================ }

unit Test.AsWish.EHAI.Binding;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  DeepBase.EHAI.Types,
  DeepBase.HB.Choice.Types,
  AsWish.Models,
  AsWish.UI.Intf,
  AsWish.UI.Types,
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
  AsWish.Binding.HB,
  AsWish.Controller;

type
  TMockStatus = class(TInterfacedObject, IShellStatusManager)
  public
    procedure Info(const ASource, AMessage: string);
    procedure Warning(const ASource, AMessage: string);
    procedure LogError(const ASource, AMessage, ADetail: string);
    procedure ShellError(const ASource, AMessage, ADetail: string);
    procedure Progress(const ATaskId, ASource: string; APercent: Integer; const AMessage: string);
    procedure TaskStart(const ATaskId, ASource, AMessage: string);
    procedure TaskFinish(const ATaskId, AMessage: string);
    procedure Diagnostic(const ASource, AMessage: string);
    function GetEntries: TArray<TShellStatusEntry>;
    procedure ClearEntries;
    procedure SetSanitizer(ASanitizer: TShellStatusSanitizer);
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
  public
    function Subscribe(AKind: TDeepShellEventKind; AHandler: TShellEventHandler): string;
    function SubscribeAll(AHandler: TShellEventHandler): string;
    procedure Unsubscribe(const AToken: string);
    procedure Publish(const AEvent: TDeepShellEvent);
    procedure Shutdown;
    procedure SetOnDispatchError(AHandler: TProc<Exception, string>);
  end;

  [TestFixture]
  TTestAsWishEHAIBinding = class
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
    FController: TAsWishController;
    FBinding: TAsWishHBBinding;
  public
    [Setup] procedure SetUp;
    [TearDown] procedure TearDown;

    [Test] procedure ASWISH_V_001_ReviewChangeSet_Surface_ReadOnly;
    [Test] procedure ASWISH_V_002_Canonical_Mutation_Gate;
    [Test] procedure ASWISH_V_003_Accepted_Baseline;
    [Test] procedure ASWISH_V_004_Frame_Rejection_Scenario_FR_AW_01;
    [Test] procedure ASWISH_V_005_HB_Interaction_Common_Semantic_E2E;
    [Test] procedure ASWISH_V_006_CandidateSelection_Not_Inherent_Commitment;
    [Test] procedure ASWISH_V_007_Regenerate_Pure_Exploration;
    [Test] procedure ASWISH_V_008_BackNavigation_Preserves_Decisions;
  end;

implementation

{ TMockStatus }
procedure TMockStatus.Info(const ASource, AMessage: string); begin end;
procedure TMockStatus.Warning(const ASource, AMessage: string); begin end;
procedure TMockStatus.LogError(const ASource, AMessage, ADetail: string); begin end;
procedure TMockStatus.ShellError(const ASource, AMessage, ADetail: string); begin end;
procedure TMockStatus.Progress(const ATaskId, ASource: string; APercent: Integer; const AMessage: string); begin end;
procedure TMockStatus.TaskStart(const ATaskId, ASource, AMessage: string); begin end;
procedure TMockStatus.TaskFinish(const ATaskId, AMessage: string); begin end;
procedure TMockStatus.Diagnostic(const ASource, AMessage: string); begin end;
function TMockStatus.GetEntries: TArray<TShellStatusEntry>; begin SetLength(Result, 0); end;
procedure TMockStatus.ClearEntries; begin end;
procedure TMockStatus.SetSanitizer(ASanitizer: TShellStatusSanitizer); begin end;

{ TMockContext }
function TMockContext.Current: TShellContext; begin Result := Default(TShellContext); end;
procedure TMockContext.SetProject(const AProjectId, APath: string); begin end;
procedure TMockContext.SetObject(const ARef: TShellObjectRef); begin end;
procedure TMockContext.SetView(const AViewId, AViewType: string); begin end;
procedure TMockContext.ClearProject; begin end;

{ TMockBus }
function TMockBus.Subscribe(AKind: TDeepShellEventKind; AHandler: TShellEventHandler): string; begin Result := 'tok'; end;
function TMockBus.SubscribeAll(AHandler: TShellEventHandler): string; begin Result := 'tok'; end;
procedure TMockBus.Unsubscribe(const AToken: string); begin end;
procedure TMockBus.Publish(const AEvent: TDeepShellEvent); begin end;
procedure TMockBus.Shutdown; begin end;
procedure TMockBus.SetOnDispatchError(AHandler: TProc<Exception, string>); begin end;

{ TTestAsWishEHAIBinding }

procedure TTestAsWishEHAIBinding.SetUp;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'aswish-ehai-' + TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FDir);

  TFile.WriteAllText(TPath.Combine(FDir, 'README.md'),
    '# EHAI Binding Test Project' + sLineBreak + 'Initial requirements documentation.', TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(FDir, 'main.pas'),
    'unit main; interface procedure RunApp; implementation procedure RunApp; begin end; end.', TEncoding.UTF8);

  FProject := TAsWishProjectService.Create;
  FScan := TAsWishScanService.Create;
  FStore := TAsWishStoreService.Create;
  FRender := TAsWishRenderService.Create;
  FBuilder := TAsWishTreeBuilder.Create;
  FPrompts := TAsWishPromptService.Create;
  FDecisions := TAsWishDecisionsService.Create;
  FSettings := TAsWishSettingsService.Create;
  FLLM := TAsWishLLMService.Create('Default');

  FController := TAsWishController.Create(FProject, FScan, FStore, FRender,
    FBuilder, FPrompts, FDecisions, FLLM, FSettings,
    TMockStatus.Create, TMockContext.Create, TMockBus.Create);

  FController.OpenAndScan(FDir);
  FBinding := TAsWishHBBinding.Create(FController);
end;

procedure TTestAsWishEHAIBinding.TearDown;
begin
  FBinding.Free;
  FController.Free;
  if TDirectory.Exists(FDir) then
    TDirectory.Delete(FDir, True);
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_001_ReviewChangeSet_Surface_ReadOnly;
var
  LCSId, LRootId: string;
  LReviewSummary: string;
  LTreePath: string;
  LBeforeSpec, LAfterSpec: string;
begin
  LTreePath := TPath.Combine(FDir, '.AsWish\trees\function-tree.yaml');
  LBeforeSpec := TFile.ReadAllText(LTreePath, TEncoding.UTF8);
  LRootId := FBuilder.FunctionNodes[0].Id;

  // Submit candidate intent -> creates ChangeSet
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Add comprehensive audit logging');
  Assert.IsNotEmpty(LCSId, 'ChangeSet ID must be generated');

  // ReviewChangeSet renders 4-layer review surface and returns review summary
  LReviewSummary := FController.ReviewChangeSet(LCSId);
  Assert.IsTrue(LReviewSummary.Contains(LCSId), 'Summary must contain ChangeSet ID');
  Assert.IsTrue(LReviewSummary.Contains('audit logging'), 'Summary must contain user intent text');

  // Verification ASWISH-V-001: Canonical Spec trees on disk MUST NOT be mutated!
  LAfterSpec := TFile.ReadAllText(LTreePath, TEncoding.UTF8);
  Assert.AreEqual(LBeforeSpec, LAfterSpec, 'Canonical Spec must remain 100% untouched during ReviewChangeSet');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_002_Canonical_Mutation_Gate;
var
  LCSId, LRootId: string;
  LTreePath: string;
  LBeforeSpec, LAfterSpec: string;
  LSuccess: Boolean;
  LNode: TSpecNode;
begin
  LTreePath := TPath.Combine(FDir, '.AsWish\trees\function-tree.yaml');
  LBeforeSpec := TFile.ReadAllText(LTreePath, TEncoding.UTF8);
  LRootId := FBuilder.FunctionNodes[0].Id;

  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Implement customer checkout capability');
  Assert.IsNotEmpty(LCSId);

  // Still uncommitted
  Assert.AreEqual(LBeforeSpec, TFile.ReadAllText(LTreePath, TEncoding.UTF8));

  // Cross commitment gate via human sovereign judgment
  LSuccess := FController.AcceptChangeSet(LCSId, 'Human authorized customer checkout');
  Assert.IsTrue(LSuccess, 'AcceptChangeSet must succeed');

  // Verification ASWISH-V-002: Canonical Spec is now updated with human confirmation
  LAfterSpec := TFile.ReadAllText(LTreePath, TEncoding.UTF8);
  Assert.AreNotEqual(LBeforeSpec, LAfterSpec, 'Canonical Spec must be mutated upon human commitment');

  LNode := FBuilder.FindNodeById(LRootId);
  Assert.AreEqual(LRootId, LNode.Id);
  Assert.AreEqual(Ord(rsAccepted), Ord(LNode.ReviewStatus));
  Assert.AreEqual(Ord(gsConfirmed), Ord(LNode.GenStatus));
  Assert.AreEqual(Ord(nsConfirmed), Ord(LNode.Status));
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_003_Accepted_Baseline;
var
  LCSId1, LCSId2, LRootId: string;
  LBaselines: TArray<TAsWishBaseline>;
begin
  LRootId := FBuilder.FunctionNodes[0].Id;

  // Initial change set -> Baseline B-0001
  LCSId1 := FController.SubmitUserIntent(LRootId, ttFunction, 'Initial foundational capability');
  Assert.IsTrue(FController.AcceptChangeSet(LCSId1, 'Accept root specification'));

  Assert.IsTrue(FController.VerifyBaseline('B-0001'), 'B-0001 must verify PASS');

  // Subsequent change set -> Baseline B-0002 with recoverable lineage
  LCSId2 := FController.SubmitUserIntent(LRootId, ttFunction, 'Add billing integration module');
  Assert.IsTrue(FController.AcceptChangeSet(LCSId2, 'Accept billing module'));

  Assert.IsTrue(FController.VerifyBaseline('B-0002'), 'B-0002 must verify PASS');

  // Verification ASWISH-V-003: Baseline lineage correctly preserves parent_baseline_id (ListBaselines sorts newest first)
  LBaselines := FController.ListBaselines;
  Assert.AreEqual(2, Integer(Length(LBaselines)));
  Assert.AreEqual('B-0002', LBaselines[0].BaselineId);
  Assert.AreEqual('B-0001', LBaselines[0].Lineage.ParentBaselineId);
  Assert.AreEqual('B-0001', LBaselines[1].BaselineId);
  Assert.AreEqual('', LBaselines[1].Lineage.ParentBaselineId);
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_004_Frame_Rejection_Scenario_FR_AW_01;
var
  LIngest: TAsWishCandidateIngest;
  LCSId, LRootId: string;
  LCS: TChangeSet;
  LModNode: TSpecNode;
  LSuccess: Boolean;
  LDec: TSpecDecision;
begin
  LRootId := FBuilder.FunctionNodes[0].Id;

  // First establish mod-orders in the module tree
  LModNode := Default(TSpecNode);
  LModNode.Id := 'mod-orders';
  LModNode.Tree := ttModule;
  LModNode.Title := 'Order Management Module';
  LModNode.Summary := 'Handles order creation and processing';
  LModNode.Status := nsCandidate;
  LModNode.ReviewStatus := rsUnreviewed;
  FBuilder.ModuleNodes.Add(LModNode);
  FStore.WriteTreeFile('trees/module-tree.yaml', ttModule, FBuilder.ModuleNodes);

  // Scenario FR-AW-01:
  // AI offers choices 1..3 on mod-orders. Human rejects the problem framing:
  // '这些都不是。这个模块本身不应该存在，问题在更上游的需求定义。'
  LCSId := FController.SubmitFrameRejection(
    'mod-orders',
    ttModule,
    '这些都不是。这个模块本身不应该存在，问题在更上游的需求定义。',
    ttFunction,
    LRootId
  );
  Assert.IsNotEmpty(LCSId, 'Frame Rejection ChangeSet ID must be generated');

  // Verification ASWISH-V-004 part A: ChangeSet structure & semantics
  LIngest := TAsWishCandidateIngest.Create(FStore);
  try
    LCS := LIngest.LoadChangeSet(FProject.ProjectPath, LCSId);
    Assert.IsTrue(LCS.IsFrameRejection, 'ChangeSet must mark IsFrameRejection = True');
    Assert.AreEqual('mod-orders', LCS.RejectedNodeId, 'Rejected node must be mod-orders');
    Assert.AreEqual(Ord(ttModule), Ord(LCS.RejectedTree), 'Rejected tree must be ttModule');
    Assert.AreEqual('human', LCS.Author, 'Author must be human');

    // Must NOT become Option 4 on mod-orders; must NOT rewrite mod-orders.summary!
    Assert.IsTrue(Length(LCS.Items) >= 2, 'Must contain at least 2 change items');
    Assert.AreEqual('mod-orders', LCS.Items[0].TargetNodeId);
    Assert.AreEqual('status', LCS.Items[0].Field, 'Item 0 must modify status, not summary');
    Assert.AreEqual('frame_rejected', LCS.Items[0].AfterValue);
    Assert.AreEqual(Ord(cstExplicit), Ord(LCS.Items[0].SourceType), 'Source type must be explicit human');

    // Item 1 directs new higher-level intent to upstream requirement
    Assert.AreEqual(LRootId, LCS.Items[1].TargetNodeId);
    Assert.AreEqual(Ord(ttFunction), Ord(LCS.Items[1].TargetTree));
    Assert.AreEqual('user_intent', LCS.Items[1].Field);
  finally
    LIngest.Free;
  end;

  // Verification ASWISH-V-004 part B: Canonical mutation gate execution
  LSuccess := FController.AcceptChangeSet(LCSId, 'Human confirmed frame rejection of mod-orders');
  Assert.IsTrue(LSuccess);

  // Node mod-orders is now rejected
  LModNode := FBuilder.FindNodeById('mod-orders');
  Assert.AreEqual(Ord(nsRejected), Ord(LModNode.Status), 'mod-orders status must be nsRejected');
  Assert.AreEqual(Ord(rsRejected), Ord(LModNode.ReviewStatus), 'mod-orders review status must be rsRejected');

  // Decision record traces frame rejection
  LDec := FDecisions.Decisions[FDecisions.Decisions.Count - 1];
  Assert.AreEqual(Ord(dtReject), Ord(LDec.DecisionType), 'Decision type must be dtReject');
  Assert.AreEqual(Ord(dsAccepted), Ord(LDec.Status), 'Decision status must be dsAccepted');
  Assert.IsTrue(LDec.Title.Contains('Frame Rejection'), 'Title must indicate Frame Rejection');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_005_HB_Interaction_Common_Semantic_E2E;
var
  LActionReframe, LActionChoose: THbChoiceAction;
  LTraceReframe, LTraceChoose: TEhaiTraceRecord;
  LSuccess: Boolean;
begin
  // Step 1: User invokes Human Override / Frame Rejection via HB choice deck (Key 9)
  LActionReframe := THbChoiceAction.Create(
    cakFreeInput,
    9,
    '模块架构错误，需重构上游领域模型',
    0,
    cisKeyboard,
    eokFrameRejection,
    esHuman,
    eipProvide,
    'mod-root'
  );
  LTraceReframe := FBinding.ProcessHbAction(LActionReframe);

  Assert.AreEqual(Ord(eseDataProvided), Ord(LTraceReframe.SemanticEffect));
  Assert.IsFalse(LTraceReframe.IsCommitted, 'Action must not commit Canonical Spec');
  Assert.IsNotEmpty(FBinding.LastChangeSetId, 'Must generate ChangeSet');

  // Step 2: User previews candidate options (Key 1)
  LActionChoose := THbChoiceAction.Create(
    cakCandidate,
    1,
    'Preview interpreted changes',
    0,
    cisKeyboard,
    eokNone,
    esHuman,
    eipJudge,
    FBinding.LastChangeSetId
  );
  LTraceChoose := FBinding.ProcessHbAction(LActionChoose);

  Assert.AreEqual(Ord(eseJudgmentMade), Ord(LTraceChoose.SemanticEffect));
  Assert.IsFalse(LTraceChoose.IsCommitted, 'CandidateSelection != Inherent Commitment');

  // Step 3: Sovereign human decision executes commitment gate
  LSuccess := FBinding.ExecuteCommitmentGate(FBinding.LastChangeSetId, 'Approved by human architect');
  Assert.IsTrue(LSuccess);
  Assert.IsTrue(FBinding.IsLastActionCommitted, 'Binding must reflect committed status');
  Assert.AreEqual(Ord(eseAuthorized), Ord(FBinding.LastEffect), 'Committed effect must be eseAuthorized');
  Assert.IsTrue(FBinding.TraceCount >= 3, 'Must record full audit trace');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_006_CandidateSelection_Not_Inherent_Commitment;
var
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LCSId, LRootId: string;
  LBaselinesBefore: Integer;
begin
  LRootId := FBuilder.FunctionNodes[0].Id;
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Exploratory candidate generation');
  LBaselinesBefore := Length(FController.ListBaselines);

  // Select option 1
  LAction := THbChoiceAction.Create(cakCandidate, 1, 'Option 1', 0, cisKeyboard);
  LTrace := FBinding.ProcessHbAction(LAction, LCSId);
  Assert.AreEqual(Ord(eseJudgmentMade), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted);

  // Select option 2
  LAction := THbChoiceAction.Create(cakCandidate, 2, 'Option 2', 0, cisKeyboard);
  LTrace := FBinding.ProcessHbAction(LAction, LCSId);
  Assert.AreEqual(Ord(eseJudgmentMade), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted);

  // Verification ASWISH-V-006: Candidate selections produce 0 baselines and 0 canonical commits
  Assert.AreEqual(LBaselinesBefore, Integer(Length(FController.ListBaselines)));
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_007_Regenerate_Pure_Exploration;
var
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LBaselinesBefore: Integer;
begin
  LBaselinesBefore := Length(FController.ListBaselines);

  // Key 8: Regenerate within current frame
  LAction := THbChoiceAction.Create(cakRegenerate, 8, 'Regenerate', 0, cisKeyboard);
  LTrace := FBinding.ProcessHbAction(LAction);

  Assert.AreEqual(Ord(eseInformOnly), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted);

  // Verification ASWISH-V-007: 8 != Judgment; zero canonical mutation
  Assert.AreEqual(LBaselinesBefore, Integer(Length(FController.ListBaselines)));
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_008_BackNavigation_Preserves_Decisions;
var
  LCSId, LRootId: string;
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LDecisionsCount: Integer;
begin
  LRootId := FBuilder.FunctionNodes[0].Id;

  // Commit one baseline decision
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Baseline intent');
  Assert.IsTrue(FController.AcceptChangeSet(LCSId, 'Authorized'));
  LDecisionsCount := FDecisions.Decisions.Count;
  Assert.IsTrue(LDecisionsCount > 0);

  // User hits 0 (BackNavigation / Exit without commitment)
  LAction := THbChoiceAction.Create(cakBack, 0, 'Back', 0, cisKeyboard);
  LTrace := FBinding.ProcessHbAction(LAction);

  Assert.AreEqual(Ord(eseInformOnly), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted);

  // Verification ASWISH-V-008: Prior decisions and baselines remain intact
  Assert.AreEqual(LDecisionsCount, Integer(FDecisions.Decisions.Count), 'BackNavigation must not revoke prior decisions');
  Assert.IsTrue(FController.VerifyBaseline('B-0001'), 'Prior baseline B-0001 must still be valid');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishEHAIBinding);

end.
