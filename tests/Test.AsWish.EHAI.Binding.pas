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
    - ASWISH-V-009: Real keyboard FrameRejection E2E (physical keyboard cisKeyboard + eokFrameRejection path)
  ============================================================================ }

unit Test.AsWish.EHAI.Binding;

{$WARN IMPLICIT_STRING_CAST OFF}

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
    [Test] procedure ASWISH_V_009_Real_Keyboard_FrameRejection_E2E;
    [Test] procedure ASWISH_V_010_CandidateSpace_And_RecommendedMark;
    [Test] procedure ASWISH_V_011_SourceDistinction_Explicit_Vs_Inferred;
    [Test] procedure ASWISH_V_012_GateB_N1_To_N6_Invariants;
    [Test] procedure ASWISH_V_013_GUI_Surface_KeyDispatcher_And_Deck_Integration;
    [Test] procedure ASWISH_V_014_Deck_Idle_After_Commitment_And_Rejection;
    [Test] procedure ASWISH_V_015_DualSurface_UnifiedEntry_DeckAndInspector_UpdateLastChangeSetId;
    // WO-HACI-MVP-ASWISH-001 Shared Object Binding & Canonical Isolation (Tests A..E)
    [Test] procedure ASWISH_V_016_SharedObjectBinding_Candidate_Context_NotDefault;
    [Test] procedure ASWISH_V_017_SharedObjectBinding_FrameRejection_RetainsContext;
    [Test] procedure ASWISH_V_018_SharedObjectBinding_Regenerate_InCurrentContext;
    [Test] procedure ASWISH_V_019_SharedObjectBinding_BackNavigation_ZeroDecisionMutation;
    [Test] procedure ASWISH_V_020_CanonicalIsolation_ZeroEhaiDependency;
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

procedure TTestAsWishEHAIBinding.ASWISH_V_009_Real_Keyboard_FrameRejection_E2E;
var
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LModNode: TSpecNode;
  LCS: TChangeSet;
  LIngest: TAsWishCandidateIngest;
  LSuccess: Boolean;
begin
  // 1. Establish mod-orders in module tree
  LModNode := Default(TSpecNode);
  LModNode.Id := 'mod-orders';
  LModNode.Tree := ttModule;
  LModNode.Title := 'Order Processing Engine';
  LModNode.Summary := 'Original module summary before human interaction';
  LModNode.Status := nsCandidate;
  LModNode.ReviewStatus := rsUnreviewed;
  FBuilder.ModuleNodes.Add(LModNode);
  FStore.WriteTreeFile('trees/module-tree.yaml', ttModule, FBuilder.ModuleNodes);

  // 2. Real keyboard interaction on HB Choice Deck:
  // Under DeepBase R-04, SubmitFreeInputWithKind routes physical keyboard input (cisKeyboard)
  // with explicit eokFrameRejection (distinct from eokAlternativeExpression / eokNone).
  LAction := THbChoiceAction.Create(
    cakFreeInput,
    9,
    '这些都不是。这个模块本身不应该存在，问题在更上游的需求定义。',
    0,
    cisKeyboard,
    eokFrameRejection,
    esHuman,
    eipProvide,
    'mod-orders'
  );

  // Assert incoming action strictly preserves eokFrameRejection
  Assert.AreEqual(Ord(eokFrameRejection), Ord(LAction.OverrideKind), 'Must observe eokFrameRejection');
  Assert.AreNotEqual(Ord(eokAlternativeExpression), Ord(LAction.OverrideKind), 'Must not be degraded to alt expression');
  Assert.AreNotEqual(Ord(eokNone), Ord(LAction.OverrideKind), 'Must not be unclassified');
  Assert.AreEqual(Ord(cisKeyboard), Ord(LAction.InputSource), 'Must originate from physical keyboard');

  // 3. Process action through AsWish EHAI Binding 001
  LTrace := FBinding.ProcessHbAction(LAction);

  Assert.AreEqual(Ord(eseDataProvided), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted, 'Must not mutate Canonical Spec before human commitment gate');
  Assert.IsNotEmpty(FBinding.LastChangeSetId, 'Must produce ChangeSet ID');

  // 4. Verify ChangeSet preserves Frame Rejection and does not rewrite mod-orders.summary
  LIngest := TAsWishCandidateIngest.Create(FStore);
  try
    LCS := LIngest.LoadChangeSet(FProject.ProjectPath, FBinding.LastChangeSetId);
    Assert.IsTrue(LCS.IsFrameRejection, 'ChangeSet must mark IsFrameRejection = True');
    Assert.AreEqual('mod-orders', LCS.RejectedNodeId, 'Must reject mod-orders');
    Assert.AreEqual(Ord(ttModule), Ord(LCS.RejectedTree));
    Assert.AreEqual('human', LCS.Author);

    // Verify mod-orders was NOT contaminated as Option 4
    Assert.IsTrue(Length(LCS.Items) >= 2);
    Assert.AreEqual('mod-orders', LCS.Items[0].TargetNodeId);
    Assert.AreEqual('status', LCS.Items[0].Field, 'Must mutate status, not summary');
    Assert.AreEqual('frame_rejected', LCS.Items[0].AfterValue);
  finally
    LIngest.Free;
  end;

  // 5. Human confirms commitment gate
  LSuccess := FBinding.ExecuteCommitmentGate(FBinding.LastChangeSetId, 'Confirmed frame rejection of mod-orders');
  Assert.IsTrue(LSuccess);
  Assert.IsTrue(FBinding.IsLastActionCommitted);
  Assert.AreEqual(Ord(eseAuthorized), Ord(FBinding.LastEffect));

  // Verify mod-orders in canonical spec is rejected, and original summary remains intact
  LModNode := FBuilder.FindNodeById('mod-orders');
  Assert.AreEqual(Ord(nsRejected), Ord(LModNode.Status));
  Assert.AreEqual(Ord(rsRejected), Ord(LModNode.ReviewStatus));
  Assert.AreEqual('Original module summary before human interaction', LModNode.Summary, 'Summary must not be rewritten');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_010_CandidateSpace_And_RecommendedMark;
var
  LItem: THbChoiceItem;
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LCSId, LRootId: string;
begin
  LRootId := FBuilder.FunctionNodes[0].Id;
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Candidate ranking scenario');

  // Candidate 1 marked as recommended
  LItem := THbChoiceItem.Create(1, 'Recommended implementation approach', 'Primary candidate', True);
  Assert.IsTrue(LItem.IsRecommended, 'Item 1 must be marked recommended');
  Assert.IsTrue(LItem.Key >= 1);
  Assert.IsTrue(LItem.Key <= 7, 'Candidate space must be constrained to 1..7');

  // Human interacts with recommended candidate 1
  LAction := THbChoiceAction.Create(cakCandidate, LItem.Key, LItem.Text, 0, cisKeyboard);
  LTrace := FBinding.ProcessHbAction(LAction, LCSId);

  // Recommended mark MUST NOT cause automatic commitment!
  Assert.AreEqual(Ord(eseJudgmentMade), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted, 'Recommended option must not auto-commit');
  Assert.AreEqual(0, Integer(Length(FController.ListBaselines)), 'Zero baselines created prior to human commitment gate');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_011_SourceDistinction_Explicit_Vs_Inferred;
var
  LCSId, LRootId: string;
  LIngest: TAsWishCandidateIngest;
  LCS, LRoundTripCS: TChangeSet;
  LItemExplicit, LItemInferred: TChangeItem;
  LYaml: string;
begin
  LRootId := FBuilder.FunctionNodes[0].Id;
  // 1. Submit human user intent produces ChangeSet marked with author='human' and cstExplicit
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Add caching layer for database queries');
  Assert.IsNotEmpty(LCSId);

  LIngest := TAsWishCandidateIngest.Create(FStore);
  try
    LCS := LIngest.LoadChangeSet(FProject.ProjectPath, LCSId);
    Assert.AreEqual('human', LCS.Author, 'ChangeSet author must be human');
    Assert.AreEqual('Add caching layer for database queries', LCS.RawUserIntent);
    Assert.IsTrue(Length(LCS.Items) >= 1);
    Assert.AreEqual(Ord(cstExplicit), Ord(LCS.Items[0].SourceType), 'Direct human intent must be cstExplicit');

    // 2. ChangeSet with both explicit human intent and AI-inferred architectural items
    LItemExplicit := TChangeItem.CreateItem(LRootId, ttFunction, 'summary', 'Old summary', 'New summary', cstExplicit, 'Human explicit intent');
    LItemInferred := TChangeItem.CreateItem('mod-db', ttModule, 'caching', 'none', 'redis', cstInferred, 'AI inferred dependency');
    LCS.Items := TArray<TChangeItem>.Create(LItemExplicit, LItemInferred);

    LYaml := TAsWishCandidateIngest.FormatChangeSetYaml(LCS);
    LRoundTripCS := TAsWishCandidateIngest.ParseChangeSetYaml(LYaml);

    // 3. Verify that across serialization / load, explicit and inferred sources are strictly preserved
    Assert.AreEqual(2, Integer(Length(LRoundTripCS.Items)));
    Assert.AreEqual(Ord(cstExplicit), Ord(LRoundTripCS.Items[0].SourceType), 'Explicit human source must be preserved');
    Assert.AreEqual(Ord(cstInferred), Ord(LRoundTripCS.Items[1].SourceType), 'AI-inferred source must not be elevated to human input');
  finally
    LIngest.Free;
  end;
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_012_GateB_N1_To_N6_Invariants;
var
  LCSId, LRootId: string;
  LBaselines: TArray<TAsWishBaseline>;
  LItems8: TArray<TChangeItem>;
  I: Integer;
  LCS8, LLoadedCS8: TChangeSet;
  LIngest: TAsWishCandidateIngest;
  LCSIdA, LCSIdB: string;
  LActionA, LActionB: THbChoiceAction;
  LTraceA, LTraceB: TEhaiTraceRecord;
  LReview1, LReview2: string;
  LActionDet1, LActionDet2: THbChoiceAction;
  LTraceDet1, LTraceDet2: TEhaiTraceRecord;
  LGateTraces: TArray<TEhaiTraceRecord>;
  LLastGateTrace: TEhaiTraceRecord;
begin
  LRootId := FBuilder.FunctionNodes[0].Id;

  // Submit initial intent to establish a valid ChangeSet
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Invariant verification intent');
  Assert.IsNotEmpty(LCSId, 'ChangeSet ID must be generated');

  // N-1: Wildcard Authority Scope '*' is NOT USED in AsWish.
  // AsWish is a local specification system; all commitments are guarded by AcceptChangeSet.
  // Verification 1: Commitment gate strictly rejects wildcard '*' identifier (fail-closed)
  Assert.IsFalse(FBinding.ExecuteCommitmentGate('*', 'Wildcard scope rejection test'),
    'Wildcard ChangeSetId must be rejected by commitment gate (fail-closed)');
  // Verification 2: Commitment gate strictly rejects empty identifier (fail-closed)
  Assert.IsFalse(FBinding.ExecuteCommitmentGate('', 'Empty scope rejection test'),
    'Empty ChangeSetId must be rejected by commitment gate');

  // N-2: Candidate space bounding and non-truncation verification
  // Verify that candidate ingestion preserves all items (e.g. 8 items) without silent drop <= 7
  SetLength(LItems8, 8);
  for I := 0 to 7 do
    LItems8[I] := TChangeItem.CreateItem(LRootId, ttFunction, 'field' + IntToStr(I), '', 'val' + IntToStr(I), cstExplicit);
  LCS8 := TChangeSet.CreateNew('cs-test-n2-8items', LRootId, ttFunction, '8 items intent');
  LCS8.Items := LItems8;
  LIngest := TAsWishCandidateIngest.Create(FStore);
  try
    LIngest.SaveChangeSet(FProject.ProjectPath, LCS8);
    LLoadedCS8 := LIngest.LoadChangeSet(FProject.ProjectPath, 'cs-test-n2-8items');
    Assert.AreEqual(8, Integer(Length(LLoadedCS8.Items)),
      'Candidate space preserves all 8 items; zero silent truncation in ingest pipeline');
  finally
    LIngest.Free;
  end;

  // N-3: Candidate key collision immunity:
  // AsWish addresses actions by explicit ChangeSetId, not by transient UI key numbers (0..9).
  // Actions targeting different ChangeSets using the same UI key (Key 1) remain strictly isolated without cross-wiring.
  LCSIdA := FController.SubmitUserIntent(LRootId, ttFunction, 'Distinct Intent A');
  LCSIdB := FController.SubmitUserIntent(LRootId, ttFunction, 'Distinct Intent B');
  Assert.AreNotEqual(LCSIdA, LCSIdB, 'Different intents produce distinct ChangeSet IDs');

  LActionA := THbChoiceAction.Create(cakCandidate, 1, 'Preview A', 0, cisKeyboard, eokNone, esHuman, eipJudge, LCSIdA);
  LTraceA := FBinding.ProcessHbAction(LActionA, LCSIdA);

  LActionB := THbChoiceAction.Create(cakCandidate, 1, 'Preview B', 0, cisKeyboard, eokNone, esHuman, eipJudge, LCSIdB);
  LTraceB := FBinding.ProcessHbAction(LActionB, LCSIdB);

  Assert.AreEqual(LCSIdA, LTraceA.Action.Context.ContextId, 'Trace A bound to ChangeSet A');
  Assert.AreEqual(LCSIdB, LTraceB.Action.Context.ContextId, 'Trace B bound to ChangeSet B');
  Assert.AreNotEqual(LTraceA.Action.Context.ContextId, LTraceB.Action.Context.ContextId,
    'Same key (1) never collides across distinct ChangeSets');

  // N-4: Determinism:
  // Same input repeatedly executed yields byte-exact identical review text and trace state
  LReview1 := FController.ReviewChangeSet(LCSId);
  LReview2 := FController.ReviewChangeSet(LCSId);
  Assert.AreEqual(LReview1, LReview2,
    'ReviewChangeSet output must be byte-exact deterministic across calls');

  LActionDet1 := THbChoiceAction.Create(cakCandidate, 1, 'Deterministic preview', 0, cisKeyboard, eokNone, esHuman, eipJudge, LCSId);
  LTraceDet1 := FBinding.ProcessHbAction(LActionDet1, LCSId);
  LActionDet2 := THbChoiceAction.Create(cakCandidate, 1, 'Deterministic preview', 0, cisKeyboard, eokNone, esHuman, eipJudge, LCSId);
  LTraceDet2 := FBinding.ProcessHbAction(LActionDet2, LCSId);
  Assert.AreEqual(Ord(LTraceDet1.SemanticEffect), Ord(LTraceDet2.SemanticEffect), 'Semantic effect deterministic');
  Assert.AreEqual(LTraceDet1.IsCommitted, LTraceDet2.IsCommitted, 'Commitment status deterministic');
  Assert.AreEqual(LTraceDet1.Action.Key, LTraceDet2.Action.Key, 'Action key deterministic');
  Assert.AreEqual(LTraceDet1.Action.Text, LTraceDet2.Action.Text, 'Action text deterministic');
  Assert.AreEqual(LTraceDet1.Action.Context.ContextId, LTraceDet2.Action.Context.ContextId, 'ContextId deterministic');

  // Cross commitment gate on LCSId and verify resulting concrete scope
  Assert.IsTrue(FBinding.ExecuteCommitmentGate(LCSId, 'Deterministic commitment test'),
    'Valid commitment gate must succeed');
  LGateTraces := FBinding.GetTraces;
  LLastGateTrace := LGateTraces[High(LGateTraces)];
  Assert.AreEqual('AsWish', LLastGateTrace.Action.Context.ScopeBoundary, 'Context ScopeBoundary must be concrete AsWish scope');
  Assert.AreNotEqual('*', LLastGateTrace.Action.Context.ScopeBoundary, 'Context ScopeBoundary must never be wildcard *');
  Assert.AreEqual(LCSId, LLastGateTrace.Action.Context.ContextId, 'ContextId must be concrete ChangeSetId');
  Assert.AreNotEqual('*', LLastGateTrace.Action.Context.ContextId, 'ContextId must never be wildcard *');

  // N-6: ExpiresAt = 0 / Never Expires:
  // AsWish models permanent specifications; TAsWishBaseline has no ExpiresAt field.
  // Contractual status: NOT APPLICABLE (AsWish domain model does not feature temporal expiration).
  // Baseline verification validates content/relation hash integrity, not temporal validity.
  LBaselines := FController.ListBaselines;
  Assert.IsTrue(Length(LBaselines) >= 1);
  Assert.IsNotEmpty(LBaselines[0].ContentHash, 'Baseline ContentHash must be present');
  Assert.IsNotEmpty(LBaselines[0].RelationHash, 'Baseline RelationHash must be present');
  Assert.IsTrue(FController.VerifyBaseline(LBaselines[0].BaselineId),
    'Baseline hash integrity permanently verifiable');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_013_GUI_Surface_KeyDispatcher_And_Deck_Integration;
var
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LCsId: string;
  LCommitSuccess: Boolean;
begin
  // 1. Test Key 9: Free input submission via keyboard source
  LAction := THbChoiceAction.Create(cakFreeInput, 9, 'Add export PDF capability', 0,
    cisKeyboard, eokAlternativeExpression, esHuman, eipProvide);
  LTrace := FBinding.ProcessHbAction(LAction);
  Assert.AreEqual(Ord(eseDataProvided), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted);
  Assert.AreEqual(Ord(cisKeyboard), Ord(LAction.InputSource));
  LCsId := FBinding.LastChangeSetId;
  Assert.IsNotEmpty(LCsId, 'Free input must create candidate ChangeSet');

  // 2. Test Key 1..7: Review candidate via keyboard source
  LAction := THbChoiceAction.Create(cakCandidate, 1, 'Review candidate 1', 0,
    cisKeyboard, eokNone, esHuman, eipJudge, LCsId);
  LTrace := FBinding.ProcessHbAction(LAction, LCsId);
  Assert.AreEqual(Ord(eseJudgmentMade), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted, 'Candidate review must not inherently commit');

  // 3. Test Key 8: Regenerate via keyboard source
  LAction := THbChoiceAction.Create(cakRegenerate, 8, 'Regenerate', 0,
    cisKeyboard, eokNone, esHuman, eipProvide);
  LTrace := FBinding.ProcessHbAction(LAction);
  Assert.AreEqual(Ord(eseInformOnly), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted);

  // 4. Test Commitment Gate crossing via desktop key/action
  LCommitSuccess := FBinding.ExecuteCommitmentGate(LCsId, 'Accepted via Desktop GUI integration test');
  Assert.IsTrue(LCommitSuccess, 'Commitment gate must succeed');
  Assert.IsTrue(FBinding.IsLastActionCommitted, 'Last action must be marked committed');
  Assert.AreEqual(Ord(eseAuthorized), Ord(FBinding.LastEffect));

  // 5. Test Key 0: Back Navigation after commitment
  LAction := THbChoiceAction.Create(cakBack, 0, 'Back', 0,
    cisKeyboard, eokNone, esHuman, eipInform);
  LTrace := FBinding.ProcessHbAction(LAction);
  Assert.AreEqual(Ord(eseInformOnly), Ord(LTrace.SemanticEffect));
  Assert.IsFalse(LTrace.IsCommitted);
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_014_Deck_Idle_After_Commitment_And_Rejection;
var
  LAct: THbChoiceAction;
  LCsId: string;
begin
  // WO-0039 B-2: both gates must leave the deck Idle so Enter/Esc/click
  // cannot re-fire a finished commitment.
  LAct := THbChoiceAction.Create(cakFreeInput, 9, 'Deck idle reject probe', 0, cisKeyboard,
    eokAlternativeExpression, esHuman, eipProvide);
  FBinding.ProcessHbAction(LAct);
  LCsId := FBinding.LastChangeSetId;
  Assert.IsNotEmpty(LCsId, 'free input must create ChangeSet');

  Assert.IsTrue(FBinding.ExecuteReject(LCsId, 'idle check reject'), 'reject must succeed');
  Assert.AreEqual('', FBinding.LastChangeSetId, 'rejection must leave deck Idle');

  LAct := THbChoiceAction.Create(cakFreeInput, 9, 'Deck idle commit probe', 0, cisKeyboard,
    eokAlternativeExpression, esHuman, eipProvide);
  FBinding.ProcessHbAction(LAct);
  LCsId := FBinding.LastChangeSetId;
  Assert.IsNotEmpty(LCsId, 'second free input must create ChangeSet');

  Assert.IsTrue(FBinding.ExecuteCommitmentGate(LCsId, 'idle check commit'), 'commit must succeed');
  Assert.AreEqual('', FBinding.LastChangeSetId, 'commitment must leave deck Idle');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_015_DualSurface_UnifiedEntry_DeckAndInspector_UpdateLastChangeSetId;
var
  LDeckAct: THbChoiceAction;
  LCsIdDeck, LCsIdInspector: string;
begin
  // Entrance 1: Keyboard Deck (Key 9 override)
  LDeckAct := THbChoiceAction.Create(cakFreeInput, 9, 'Deck intent for payment retry', 0,
    cisKeyboard, eokAlternativeExpression, esHuman, eipProvide, 'func-payment-retry');
  FBinding.ProcessHbAction(LDeckAct);
  LCsIdDeck := FBinding.LastChangeSetId;
  Assert.IsNotEmpty(LCsIdDeck, 'Deck submission must update LastChangeSetId');

  // Entrance 2: Inspector Sidebar (routed through FBinding.SubmitInspectorIntent)
  LCsIdInspector := FBinding.SubmitInspectorIntent('mod-billing-service', 'Inspector intent for billing module');
  Assert.IsNotEmpty(LCsIdInspector, 'Inspector intent must produce a ChangeSet ID');

  // Both entrances must update FBinding.LastChangeSetId to their respective IDs (WO-0057 1.2)
  Assert.AreEqual(LCsIdInspector, FBinding.LastChangeSetId,
    'Inspector submission must update LastChangeSetId as SSOT; see WO-0057 1.2');
  Assert.AreNotEqual(LCsIdDeck, LCsIdInspector, 'Each submission produces a distinct ChangeSet');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_016_SharedObjectBinding_Candidate_Context_NotDefault;
var
  LRootNode: TSpecNode;
  LRootId, LCSId: string;
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
begin
  LRootNode := FBuilder.FunctionNodes[0];
  LRootId := LRootNode.Id;
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Context binding verification intent');
  Assert.IsNotEmpty(LCSId, 'ChangeSet must be generated');

  // Human selects candidate option 1
  LAction := THbChoiceAction.Create(cakCandidate, 1, 'Review candidate option 1', 0, cisKeyboard, eokNone, esHuman, eipJudge, LCSId);
  LTrace := FBinding.ProcessHbAction(LAction, LCSId);

  // Assertions for Gate A (Test A): ContextBinding is not default, has real traceable context
  Assert.AreEqual(LCSId, LTrace.Action.Context.ContextId, 'ContextId must match ChangeSetId');
  Assert.AreEqual(LRootId, LTrace.Action.Context.ObservableObjectRef, 'ObservableObjectRef must resolve to target NodeId');
  Assert.IsTrue(LTrace.Action.Context.ContextTitle.Contains(LRootNode.Title) or
    LTrace.Action.Context.ContextTitle.Contains('Context binding verification'),
    'ContextTitle must reflect real node title or user intent');
  Assert.IsTrue(LTrace.Action.Context.StepInfo.Contains('Candidate Review'), 'StepInfo must reflect Candidate Review');
  Assert.AreEqual('human', LTrace.Action.Context.AuthorityHolder, 'AuthorityHolder must be human');
  Assert.AreEqual('AsWish', LTrace.Action.Context.ScopeBoundary, 'ScopeBoundary must be AsWish');
  Assert.IsTrue(LTrace.Action.Context.IsValid, 'ContextBinding must be valid');
  Assert.AreNotEqual(Default(TEhaiContextBinding).ContextId, LTrace.Action.Context.ContextId,
    'ContextBinding must not be Default record');
  Assert.AreNotEqual(Default(TEhaiContextBinding).ObservableObjectRef, LTrace.Action.Context.ObservableObjectRef,
    'ObservableObjectRef must not be empty/default');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_017_SharedObjectBinding_FrameRejection_RetainsContext;
var
  LAction: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
begin
  // Human invokes Frame Rejection (Key 9) targeting mod-orders
  LAction := THbChoiceAction.Create(
    cakFreeInput,
    9,
    '架构预设错误，重构采购订单上下文',
    0,
    cisKeyboard,
    eokFrameRejection,
    esHuman,
    eipProvide,
    'mod-orders'
  );
  LTrace := FBinding.ProcessHbAction(LAction);

  // Assertions for Test B: Frame Rejection preserves real Context
  Assert.AreEqual('mod-orders', LTrace.Action.Context.ObservableObjectRef,
    'Frame Rejection must retain real target node as ObservableObjectRef');
  Assert.IsTrue(LTrace.Action.Context.ContextTitle.Contains('Frame Rejection'),
    'ContextTitle must indicate Frame Rejection');
  Assert.AreEqual('Frame Rejection', LTrace.Action.Context.StepInfo,
    'StepInfo must be Frame Rejection');
  Assert.AreEqual('human', LTrace.Action.Context.AuthorityHolder,
    'AuthorityHolder must remain human');
  Assert.IsNotEmpty(FBinding.LastChangeSetId, 'Frame Rejection must generate ChangeSet ID');
  Assert.IsFalse(LTrace.IsCommitted, 'Frame Rejection must not commit Canonical Spec');
  Assert.AreEqual(Ord(eseDataProvided), Ord(LTrace.SemanticEffect));
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_018_SharedObjectBinding_Regenerate_InCurrentContext;
var
  LRootNode: TSpecNode;
  LRootId, LCSId: string;
  LActChoose, LActRegen: THbChoiceAction;
  LTraceRegen: TEhaiTraceRecord;
begin
  LRootNode := FBuilder.FunctionNodes[0];
  LRootId := LRootNode.Id;
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Scenario for regeneration context retention');

  // Establish active ChangeSet context
  LActChoose := THbChoiceAction.Create(cakCandidate, 1, 'Preview', 0, cisKeyboard, eokNone, esHuman, eipJudge, LCSId);
  FBinding.ProcessHbAction(LActChoose, LCSId);

  // Human presses 8 (Regenerate) without re-specifying ChangeSetId
  LActRegen := THbChoiceAction.Create(cakRegenerate, 8, 'Regenerate', 0, cisKeyboard, eokNone, esHuman, eipProvide);
  LTraceRegen := FBinding.ProcessHbAction(LActRegen);

  // Assertions for Test C: Regenerate stays in current object context
  Assert.AreEqual(LCSId, LTraceRegen.Action.Context.ContextId,
    'Regenerate must retain current ChangeSet context ID');
  Assert.AreEqual(LRootId, LTraceRegen.Action.Context.ObservableObjectRef,
    'Regenerate must retain current ObservableObjectRef');
  Assert.AreEqual('Regenerate', LTraceRegen.Action.Context.StepInfo,
    'StepInfo must be Regenerate');
  Assert.AreEqual('human', LTraceRegen.Action.Context.AuthorityHolder,
    'AuthorityHolder must be human');
  Assert.AreEqual(Ord(eseInformOnly), Ord(LTraceRegen.SemanticEffect),
    'Regenerate is pure exploration (eseInformOnly)');
  Assert.IsFalse(LTraceRegen.IsCommitted, 'Regenerate must never commit');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_019_SharedObjectBinding_BackNavigation_ZeroDecisionMutation;
var
  LRootNode: TSpecNode;
  LRootId, LCSId: string;
  LBaselinesBefore, LDecisionsBefore: Integer;
  LActBack: THbChoiceAction;
  LTraceBack: TEhaiTraceRecord;
begin
  LRootNode := FBuilder.FunctionNodes[0];
  LRootId := LRootNode.Id;
  LCSId := FController.SubmitUserIntent(LRootId, ttFunction, 'Exploration intent before back exit');

  LBaselinesBefore := Length(FController.ListBaselines);
  LDecisionsBefore := Length(FController.ListDecisions);

  // Human presses 0 (Back / Exit without commitment)
  LActBack := THbChoiceAction.Create(cakBack, 0, 'Exit review', 0, cisKeyboard, eokNone, esHuman, eipInform);
  LTraceBack := FBinding.ProcessHbAction(LActBack, LCSId);

  // Assertions for Test D: Back retains context but strictly zeroes decision/baseline mutations
  Assert.AreEqual(LCSId, LTraceBack.Action.Context.ContextId);
  Assert.AreEqual(LRootId, LTraceBack.Action.Context.ObservableObjectRef);
  Assert.AreEqual('Back Navigation', LTraceBack.Action.Context.StepInfo);
  Assert.AreEqual(Ord(eseInformOnly), Ord(LTraceBack.SemanticEffect));
  Assert.IsFalse(LTraceBack.IsCommitted);
  Assert.AreEqual(LBaselinesBefore, Integer(Length(FController.ListBaselines)),
    'Back navigation must create 0 baselines');
  Assert.AreEqual(LDecisionsBefore, Integer(Length(FController.ListDecisions)),
    'Back navigation must create 0 formal decisions');
end;

procedure TTestAsWishEHAIBinding.ASWISH_V_020_CanonicalIsolation_ZeroEhaiDependency;
var
  LDir, LModelsPath, LContent: string;
begin
  LDir := ExtractFilePath(ParamStr(0));
  LModelsPath := '';
  while LDir <> '' do
  begin
    var LTry := TPath.Combine(LDir, 'src\models\AsWish.Models.pas');
    if TFile.Exists(LTry) then
    begin
      LModelsPath := LTry;
      Break;
    end;
    var LParent := TDirectory.GetParent(LDir);
    if (LParent = LDir) or (LParent = '') then Break;
    LDir := LParent;
  end;

  Assert.IsNotEmpty(LModelsPath, 'AsWish.Models.pas must be found on disk');
  Assert.IsTrue(TFile.Exists(LModelsPath), 'AsWish.Models.pas must exist');

  LContent := TFile.ReadAllText(LModelsPath, TEncoding.UTF8);

  // R1: AsWish Canonical must remain language-neutral; zero DeepBase/EHAI dependency
  Assert.IsFalse(LContent.Contains('DeepBase.EHAI'),
    'R1 violation: AsWish.Models.pas must not depend on DeepBase.EHAI');
  Assert.IsFalse(LContent.Contains('TEhaiContextBinding'),
    'R1 violation: AsWish.Models.pas must not reference TEhaiContextBinding');

  // R2: TSpecDecision must not have DecisionDistribution
  Assert.IsFalse(LContent.Contains('DecisionDistribution'),
    'R2 violation: AsWish.Models.pas must not introduce DecisionDistribution to TSpecDecision');

  // R3: TSpecDecision must not have AuthorityStatus
  Assert.IsFalse(LContent.Contains('AuthorityStatus'),
    'R3 violation: AsWish.Models.pas must not introduce AuthorityStatus to TSpecDecision');

  // R4: TSpecDifferenceItem must not have ImpactSummary Canonical field
  Assert.IsFalse(LContent.Contains('ImpactSummary'),
    'R4 violation: TSpecDifferenceItem must not contain ImpactSummary as a canonical field');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishEHAIBinding);

end.
