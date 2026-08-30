{ ============================================================================
  Test.AsWish.CandidateIngest

  DUnitX tests for the strongly-typed candidate sandbox (BUG-8). These pin
  the contract that LLM output is never trusted raw: bad ids are rejected,
  foreign-key parent_ids are enforced, provenance/review authority is
  stripped, and the function root fog converges only when its summary
  actually changes.
  ============================================================================ }

unit Test.AsWish.CandidateIngest;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework,
  AsWish.Models,
  AsWish.Services.SpecStore,
  AsWish.Services.CandidateIngest;

type
  [TestFixture]
  TCandidateIngestTests = class
  private
    FStore: TAsWishStoreService;
    FCand: TAsWishCandidateIngest;
    function StubFunctionRoot: TList<TSpecNode>;
    function StubDataRoot: TList<TSpecNode>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    // SplitDocuments
    [Test]
    procedure Split_ThreeDocs_ReturnsThree;
    [Test]
    procedure Split_LeadingMarker_NoEmptyFirst;
    [Test]
    procedure Split_SingleDoc_NoMarkers_ReturnsOne;
    [Test]
    procedure Split_EmptyInput_ReturnsEmpty;

    // Ingest validation
    [Test]
    procedure Ingest_ValidFunctionNode_Accepted;
    [Test]
    procedure Ingest_BadIdPrefix_Rejected;
    [Test]
    procedure Ingest_ParentIdUnknown_Rejected;
    [Test]
    procedure Ingest_ParentIdKnown_Accepted;
    [Test]
    procedure Ingest_SourceLayerHuman_ForcedToAiInferred;
    [Test]
    procedure Ingest_GenStatusConfirmed_ForcedToGenerated;
    [Test]
    procedure Ingest_ReviewStatusNonUnreviewed_ForcedToUnreviewed;
    [Test]
    procedure Ingest_DataTree_AcceptedAndRouted;
    [Test]
    procedure Ingest_DataTree_InvalidId_Rejected;

    // MergeInto
    [Test]
    procedure Merge_ExistingId_OverwritesMutableFields;
    [Test]
    procedure Merge_ExistingId_PreservesReviewStatus;
    [Test]
    procedure Merge_ExistingId_AdvancesGenStatusToGenerated;
    [Test]
    procedure Merge_FunctionRootSummaryChanged_ConvergesFogToFoggy;
    [Test]
    procedure Merge_FunctionRootSummaryUnchanged_NoFogChange;
    [Test]
    procedure Merge_NewId_Appended;
    [Test]
    procedure Merge_DataTree_UpdatesFieldsPreservesReview;

    // Candidate User Intent (WO-20260830-0027A)
    [Test]
    procedure CandidateIntent_CreateNew_SetsFields;
    [Test]
    procedure CandidateIntent_FormatAndParseYaml_RoundTrip;
    [Test]
    procedure CandidateIntent_SaveAndLoad_PersistsToDisk;
    [Test]
    procedure CandidateIntent_CheckClarity_VagueIntent_GeneratesGrillingTicket;
    [Test]
    procedure CandidateIntent_CheckClarity_ClearIntent_ReturnsTrue;
    [Test]
    procedure Ingest_NodeWithUserIntent_PreservesUserIntentField;
    [Test]
    procedure Merge_NodeWithUserIntent_UpdatesUserIntentField;
    [Test]
    procedure Ingest_DoesNotMutateCanonicalSpec_UntilMerge;

    // Structured Change Set (WO-20260830-0027B)
    [Test]
    procedure ChangeSet_CreateNew_SetsFields;
    [Test]
    procedure ChangeSet_FormatAndParseYaml_RoundTrip;
    [Test]
    procedure ChangeSet_SaveAndLoad_PersistsToDisk;
    [Test]
    procedure ChangeSet_ComputeAffectedProjections_ViaSemanticBundles;
    [Test]
    procedure ChangeSet_DistinguishesExplicitInferredUnknown;
    [Test]
    procedure ChangeSet_DoesNotMutateCanonicalSpec;

    // Change Set Review & Decision Writeback (WO-20260830-0027C)
    [Test]
    procedure ChangeSet_ReviewSummary_FormatsSemanticChanges;
    [Test]
    procedure ChangeSet_Accept_AppliesChangesToCanonicalSpec;
    [Test]
    procedure ChangeSet_Reject_DoesNotMutateCanonicalSpec;
    [Test]
    procedure ChangeSet_Clarify_DoesNotMutateCanonicalSpec;

    // GUI Review Surface & Intent List (WO-20260830-0027D-R1)
    [Test]
    procedure CandidateIntent_ListCandidateIntents_ReturnsAll;
    [Test]
    procedure ChangeSet_RenderReviewPage_GeneratesValidHtml;
  end;

implementation

uses
  System.IOUtils,
  AsWish.Services.Render;

{ TCandidateIngestTests }

procedure TCandidateIngestTests.Setup;
begin
  // ParseTreeNodes does not touch disk, so an uninitialized store is fine.
  FStore := TAsWishStoreService.Create;
  FCand := TAsWishCandidateIngest.Create(FStore);
end;

procedure TCandidateIngestTests.TearDown;
begin
  FCand.Free;
  FStore.Free;
end;

function TCandidateIngestTests.StubFunctionRoot: TList<TSpecNode>;
var
  LNode: TSpecNode;
begin
  // Mirrors what TreeBuilder emits for an unscanned function root: a stub
  // sitting at the deepest fog level, awaiting LLM semantic content.
  Result := TList<TSpecNode>.Create;
  LNode := Default(TSpecNode);
  LNode.Id := 'func-demo';
  LNode.Tree := ttFunction;
  LNode.Title := 'demo';
  LNode.Kind := 'capability';
  LNode.Summary := 'Project root capability (stub)';
  LNode.FogState := fsUnknownUnknowns;
  LNode.HasFogState := True;
  LNode.GenStatus := gsDraft;
  LNode.ReviewStatus := rsUnreviewed;
  LNode.SourceLayer := slParsedFromA;
  Result.Add(LNode);
end;

function TCandidateIngestTests.StubDataRoot: TList<TSpecNode>;
var
  LNode: TSpecNode;
begin
  Result := TList<TSpecNode>.Create;
  LNode := TSpecNode.MakeNew('data-demo', ttData, 'demo data', 'entity');
  LNode.SourceLayer := slParsedFromA;
  Result.Add(LNode);
end;

// ---------------------------------------------------------------------------
// SplitDocuments
// ---------------------------------------------------------------------------

procedure TCandidateIngestTests.Split_ThreeDocs_ReturnsThree;
const
  CYAML = '---' + #10 + 'a: 1' + #10 + '---' + #10 + 'b: 2' + #10 + '---' + #10 + 'c: 3';
begin
  var LDocs := TAsWishCandidateIngest.SplitDocuments(CYAML);
  Assert.AreEqual<Integer>(3, Length(LDocs));
  Assert.IsTrue(LDocs[0].Contains('a: 1'));
  Assert.IsTrue(LDocs[2].Contains('c: 3'));
end;

procedure TCandidateIngestTests.Split_LeadingMarker_NoEmptyFirst;
const
  CYAML = '---' + #10 + 'a: 1' + #10 + '---' + #10 + 'b: 2';
begin
  var LDocs := TAsWishCandidateIngest.SplitDocuments(CYAML);
  Assert.AreEqual<Integer>(2, Length(LDocs));
  Assert.AreEqual('a: 1', LDocs[0].Trim);
end;

procedure TCandidateIngestTests.Split_SingleDoc_NoMarkers_ReturnsOne;
const
  CYAML = 'a: 1' + #10 + 'b: 2';
begin
  var LDocs := TAsWishCandidateIngest.SplitDocuments(CYAML);
  Assert.AreEqual<Integer>(1, Length(LDocs));
end;

procedure TCandidateIngestTests.Split_EmptyInput_ReturnsEmpty;
begin
  var LDocs := TAsWishCandidateIngest.SplitDocuments('');
  Assert.AreEqual<Integer>(0, Length(LDocs));
end;

// ---------------------------------------------------------------------------
// Ingest validation
// ---------------------------------------------------------------------------

procedure TCandidateIngestTests.Ingest_ValidFunctionNode_Accepted;
const
  CYAML = '# file: trees/function-tree.yaml' + #10 +
          'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: Real semantic summary' + #10 +
          '    status: candidate' + #10 +
          '    gen_status: generated' + #10 +
          '    review_status: unreviewed' + #10 +
          '    source_layer: ai_inferred' + #10 +
          '    fog_state: foggy';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(1, R.Accepted.Count, 'expected 1 accepted');
      Assert.AreEqual<Integer>(0, R.Rejected, 'expected 0 rejected');
      Assert.AreEqual('func-demo', R.Accepted[0].Id);
      Assert.AreEqual(ttFunction, R.Accepted[0].Tree);
      Assert.AreEqual<Integer>(1, R.FuncNodes.Count);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_BadIdPrefix_Rejected;
const
  // id lacks the func- prefix required for tree=function
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: demo' + #10 +
          '    kind: capability';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(1, R.Rejected, 'bad-prefix id must be rejected');
      Assert.AreEqual<Integer>(0, R.Accepted.Count);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_ParentIdUnknown_Rejected;
const
  // parent_id points at a node that does not exist anywhere
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-child' + #10 +
          '    kind: capability' + #10 +
          '    parent_id: func-ghost';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(1, R.Rejected, 'dangling parent_id must be rejected');
      Assert.AreEqual<Integer>(0, R.Accepted.Count);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_ParentIdKnown_Accepted;
const
  // parent_id=func-demo exists in the live function tree -> accepted
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-child' + #10 +
          '    kind: capability' + #10 +
          '    parent_id: func-demo' + #10 +
          '    summary: child capability';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(0, R.Rejected);
      Assert.AreEqual<Integer>(1, R.Accepted.Count);
      Assert.AreEqual('func-child', R.Accepted[0].Id);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_SourceLayerHuman_ForcedToAiInferred;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    source_layer: human_decision';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(1, R.Accepted.Count);
      Assert.AreEqual(slAiInferred, R.Accepted[0].SourceLayer,
        'LLM may not claim human_decision provenance');
      Assert.IsTrue(R.Warnings.Count > 0, 'expected a warning');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_GenStatusConfirmed_ForcedToGenerated;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    gen_status: confirmed';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(1, R.Accepted.Count);
      Assert.AreEqual(gsGenerated, R.Accepted[0].GenStatus,
        'LLM may not self-confirm; forced to generated');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_ReviewStatusNonUnreviewed_ForcedToUnreviewed;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    review_status: accepted';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(1, R.Accepted.Count);
      Assert.AreEqual(rsUnreviewed, R.Accepted[0].ReviewStatus,
        'LLM has no review authority; forced to unreviewed');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_DataTree_AcceptedAndRouted;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: data' + #10 +
          'nodes:' + #10 +
          '  - id: data-profile' + #10 +
          '    title: Profile' + #10 +
          '    kind: entity' + #10 +
          '    parent_id: data-demo' + #10 +
          '    data_type: object' + #10 +
          '    persistence: db';
begin
  var LFunc := StubFunctionRoot;
  var LData := StubDataRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil, LData);
    try
      Assert.AreEqual<Integer>(1, R.Accepted.Count, 'data node should be accepted');
      Assert.AreEqual<Integer>(1, R.DataNodes.Count, 'data node should be routed');
      Assert.AreEqual(ttData, R.DataNodes[0].Tree);
      Assert.AreEqual('object', R.DataNodes[0].DataType);
      Assert.AreEqual<Integer>(0, R.Rejected);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
    LData.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_DataTree_InvalidId_Rejected;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: data' + #10 +
          'nodes:' + #10 +
          '  - id: profile' + #10 +
          '    title: Profile' + #10 +
          '    kind: entity';
begin
  var R := FCand.Ingest(CYAML, nil, nil, nil, nil);
  try
    Assert.AreEqual<Integer>(1, R.Rejected, 'data node without data- prefix must be rejected');
    Assert.AreEqual<Integer>(0, R.Accepted.Count);
    Assert.AreEqual<Integer>(0, R.DataNodes.Count);
  finally
    R.FreeOwned;
  end;
end;

// ---------------------------------------------------------------------------
// MergeInto
// ---------------------------------------------------------------------------

procedure TCandidateIngestTests.Merge_ExistingId_OverwritesMutableFields;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: NEW REAL SUMMARY' + #10 +
          '    source_layer: ai_inferred';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      var LStats := FCand.MergeInto(R.Accepted, LFunc, nil, nil);
      Assert.AreEqual<Integer>(1, LStats.Merged);
      Assert.AreEqual('NEW REAL SUMMARY', LFunc[0].Summary,
        'mutable summary must be overwritten');
      Assert.AreEqual(slAiInferred, LFunc[0].SourceLayer);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Merge_ExistingId_PreservesReviewStatus;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: new summary' + #10 +
          '    review_status: accepted';   // LLM tries to set accepted
begin
  var LFunc := StubFunctionRoot;
  try
    // Pretend a human already accepted this node before regeneration.
    var LNode := LFunc[0];
    LNode.ReviewStatus := rsAccepted;
    LNode.DecisionRefs := TArray<string>.Create('dec-1');
    LFunc[0] := LNode;

    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      FCand.MergeInto(R.Accepted, LFunc, nil, nil);
      // Ingest forced the candidate's review_status to unreviewed, but the
      // EXISTING node's human review must survive the merge.
      Assert.AreEqual(rsAccepted, LFunc[0].ReviewStatus,
        'human review_status must survive LLM regeneration');
      Assert.AreEqual<Integer>(1, Length(LFunc[0].DecisionRefs),
        'decision_refs must survive');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Merge_ExistingId_AdvancesGenStatusToGenerated;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: new summary';
begin
  var LFunc := StubFunctionRoot;
  try
    Assert.AreEqual(gsDraft, LFunc[0].GenStatus, 'precondition: starts at draft');
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      FCand.MergeInto(R.Accepted, LFunc, nil, nil);
      Assert.AreEqual(gsGenerated, LFunc[0].GenStatus,
        'merge must advance gen_status to generated');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Merge_FunctionRootSummaryChanged_ConvergesFogToFoggy;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: Real capability semantics replacing the stub';
begin
  var LFunc := StubFunctionRoot;
  try
    Assert.AreEqual(fsUnknownUnknowns, LFunc[0].FogState, 'precondition: deepest fog');
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      var LStats := FCand.MergeInto(R.Accepted, LFunc, nil, nil);
      Assert.AreEqual<Integer>(1, LStats.FogCleared, 'fog should converge one step');
      Assert.AreEqual(fsFoggy, LFunc[0].FogState,
        'unknown_unknowns -> foggy (not all the way to clear)');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Merge_FunctionRootSummaryUnchanged_NoFogChange;
const
  // summary matches the existing stub exactly -> no semantic advance -> no fog change
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: Project root capability (stub)';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      var LStats := FCand.MergeInto(R.Accepted, LFunc, nil, nil);
      Assert.AreEqual<Integer>(0, LStats.FogCleared, 'no summary change -> no fog change');
      Assert.AreEqual(fsUnknownUnknowns, LFunc[0].FogState);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Merge_NewId_Appended;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-child' + #10 +
          '    kind: capability' + #10 +
          '    parent_id: func-demo' + #10 +
          '    summary: a new child';
begin
  var LFunc := StubFunctionRoot;
  try
    Assert.AreEqual<Integer>(1, LFunc.Count, 'precondition: 1 root');
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      var LStats := FCand.MergeInto(R.Accepted, LFunc, nil, nil);
      Assert.AreEqual<Integer>(1, LStats.Added);
      Assert.AreEqual<Integer>(2, LFunc.Count, 'new node appended');
      Assert.AreEqual('func-child', LFunc[1].Id);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Merge_DataTree_UpdatesFieldsPreservesReview;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: data' + #10 +
          'nodes:' + #10 +
          '  - id: data-profile' + #10 +
          '    title: Profile v2' + #10 +
          '    kind: entity' + #10 +
          '    data_type: json' + #10 +
          '    nullable: true' + #10 +
          '    persistence: file' + #10 +
          '    field_constraints:' + #10 +
          '      - unique';
var
  LData: TList<TSpecNode>;
  LExisting: TSpecNode;
begin
  LData := TList<TSpecNode>.Create;
  try
    LExisting := TSpecNode.MakeNew('data-profile', ttData, 'Profile', 'entity');
    LExisting.DataType := 'object';
    LExisting.ReviewStatus := rsAccepted;
    LExisting.DecisionRefs := TArray<string>.Create('dec-1');
    LData.Add(LExisting);

    var R := FCand.Ingest(CYAML, nil, nil, nil, LData);
    try
      var LStats := FCand.MergeInto(R.Accepted, nil, nil, nil, LData);
      Assert.AreEqual<Integer>(1, LStats.Merged);
      Assert.AreEqual('Profile v2', LData[0].Title);
      Assert.AreEqual('json', LData[0].DataType);
      Assert.IsTrue(LData[0].Nullable);
      Assert.AreEqual('file', LData[0].Persistence);
      Assert.AreEqual<Integer>(1, Length(LData[0].FieldConstraints));
      Assert.AreEqual(rsAccepted, LData[0].ReviewStatus,
        'human review must survive data regeneration');
      Assert.AreEqual<Integer>(1, Length(LData[0].DecisionRefs));
    finally
      R.FreeOwned;
    end;
  finally
    LData.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Candidate User Intent (WO-20260830-0027A)
// ---------------------------------------------------------------------------

procedure TCandidateIngestTests.CandidateIntent_CreateNew_SetsFields;
var
  LIntent: TCandidateIntent;
begin
  LIntent := TCandidateIntent.CreateNew('func-login', ttFunction, 'login page requires sms verification');
  Assert.AreEqual('func-login', LIntent.NodeId);
  Assert.AreEqual(ttFunction, LIntent.Tree);
  Assert.AreEqual('login page requires sms verification', LIntent.UserIntent);
  Assert.AreEqual('human', LIntent.Author);
  Assert.AreNotEqual<Double>(0.0, LIntent.CreatedAt);
end;

procedure TCandidateIngestTests.CandidateIntent_FormatAndParseYaml_RoundTrip;
var
  LOriginal, LParsed: TCandidateIntent;
  LYaml: string;
begin
  LOriginal := TCandidateIntent.CreateNew('view-main', ttView, 'add dark theme toggle button', 'alice');
  LYaml := TAsWishCandidateIngest.FormatCandidateIntentYaml(LOriginal);
  Assert.IsTrue(LYaml.Contains('view-main'));
  Assert.IsTrue(LYaml.Contains('add dark theme toggle button'));
  Assert.IsTrue(LYaml.Contains('alice'));

  LParsed := TAsWishCandidateIngest.ParseCandidateIntentYaml(LYaml);
  Assert.AreEqual('view-main', LParsed.NodeId);
  Assert.AreEqual(ttView, LParsed.Tree);
  Assert.AreEqual('add dark theme toggle button', LParsed.UserIntent);
  Assert.AreEqual('alice', LParsed.Author);
end;

procedure TCandidateIngestTests.CandidateIntent_SaveAndLoad_PersistsToDisk;
var
  LTempDir: string;
  LIntent, LLoaded: TCandidateIntent;
  LSavedPath: string;
begin
  LTempDir := TPath.Combine(TPath.GetTempPath, 'aswish_test_intent_' + FormatDateTime('hhnnsszzz', Now));
  try
    TDirectory.CreateDirectory(LTempDir);
    LIntent := TCandidateIntent.CreateNew('data-user', ttData, 'add user_status enum field');
    LSavedPath := FCand.SaveCandidateIntent(LTempDir, LIntent);
    Assert.IsTrue(TFile.Exists(LSavedPath), 'candidate-intent.yaml must exist');

    LLoaded := FCand.LoadCandidateIntent(LTempDir);
    Assert.AreEqual('data-user', LLoaded.NodeId);
    Assert.AreEqual(ttData, LLoaded.Tree);
    Assert.AreEqual('add user_status enum field', LLoaded.UserIntent);
  finally
    if TDirectory.Exists(LTempDir) then
      TDirectory.Delete(LTempDir, True);
  end;
end;

procedure TCandidateIngestTests.CandidateIntent_CheckClarity_VagueIntent_GeneratesGrillingTicket;
var
  LVagueIntent: TCandidateIntent;
  LIssue: TSpecIssue;
  LIsClear: Boolean;
begin
  LVagueIntent := TCandidateIntent.CreateNew('func-demo', ttFunction, 'fix');
  LIsClear := FCand.CheckIntentClarity(LVagueIntent, LIssue);
  Assert.IsFalse(LIsClear, 'vague intent should not pass clarity check');
  Assert.AreEqual(itGrillingTicket, LIssue.IssueType);
  Assert.IsTrue(LIssue.RequiresHuman);
  Assert.AreEqual<Integer>(1, Length(LIssue.AffectedNodes));
  Assert.AreEqual('func-demo', LIssue.AffectedNodes[0]);
end;

procedure TCandidateIngestTests.CandidateIntent_CheckClarity_ClearIntent_ReturnsTrue;
var
  LClearIntent: TCandidateIntent;
  LIssue: TSpecIssue;
  LIsClear: Boolean;
begin
  LClearIntent := TCandidateIntent.CreateNew('func-demo', ttFunction, 'redirect to dashboard automatically after successful login');
  LIsClear := FCand.CheckIntentClarity(LClearIntent, LIssue);
  Assert.IsTrue(LIsClear, 'clear intent should pass clarity check');
end;

procedure TCandidateIngestTests.Ingest_NodeWithUserIntent_PreservesUserIntentField;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: semantic summary' + #10 +
          '    user_intent: "require sms verification on login"';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      Assert.AreEqual<Integer>(1, R.Accepted.Count);
      Assert.AreEqual('require sms verification on login', R.Accepted[0].UserIntent);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Merge_NodeWithUserIntent_UpdatesUserIntentField;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: new summary' + #10 +
          '    user_intent: "require sms verification on login"';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      FCand.MergeInto(R.Accepted, LFunc, nil, nil);
      Assert.AreEqual('require sms verification on login', LFunc[0].UserIntent);
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.Ingest_DoesNotMutateCanonicalSpec_UntilMerge;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: function' + #10 +
          'nodes:' + #10 +
          '  - id: func-demo' + #10 +
          '    kind: capability' + #10 +
          '    summary: completely rewritten summary';
var
  LFunc: TList<TSpecNode>;
begin
  LFunc := StubFunctionRoot;
  try
    var LOldSummary := LFunc[0].Summary;
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      // Ingest step only validates into Accepted list; does NOT mutate LFunc
      Assert.AreEqual(LOldSummary, LFunc[0].Summary, 'Ingest alone must not touch live canonical spec');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Structured Change Set (WO-20260830-0027B)
// ---------------------------------------------------------------------------

procedure TCandidateIngestTests.ChangeSet_CreateNew_SetsFields;
var
  LCS: TChangeSet;
  LItem: TChangeItem;
begin
  LCS := TChangeSet.CreateNew('cs-01', 'func-orders', ttFunction, 'add discount percentage');
  LItem := TChangeItem.CreateItem('func-orders', ttFunction, 'summary', 'old summary', 'new summary with discount', cstExplicit, 'user requested');
  LCS.Items := TArray<TChangeItem>.Create(LItem);

  Assert.AreEqual('cs-01', LCS.Id);
  Assert.AreEqual('func-orders', LCS.IntentNodeId);
  Assert.AreEqual(ttFunction, LCS.IntentTree);
  Assert.AreEqual('add discount percentage', LCS.RawUserIntent);
  Assert.AreEqual<Integer>(1, Length(LCS.Items));
  Assert.AreEqual('summary', LCS.Items[0].Field);
  Assert.AreEqual(cstExplicit, LCS.Items[0].SourceType);
end;

procedure TCandidateIngestTests.ChangeSet_FormatAndParseYaml_RoundTrip;
var
  LOriginal, LParsed: TChangeSet;
  LItem1, LItem2: TChangeItem;
  LYaml: string;
begin
  LOriginal := TChangeSet.CreateNew('cs-demo-01', 'func-demo', ttFunction, 'add auto-refresh', 'bob');
  LOriginal.AffectedProjections := TArray<TTreeType>.Create(ttFunction, ttView);
  LItem1 := TChangeItem.CreateItem('func-demo', ttFunction, 'summary', 'Static view', 'Auto-refreshing view', cstExplicit, 'direct intent');
  LItem2 := TChangeItem.CreateItem('view-demo', ttView, 'kind', 'page', 'live_page', cstInferred, 'inferred view change');
  LOriginal.Items := TArray<TChangeItem>.Create(LItem1, LItem2);

  LYaml := TAsWishCandidateIngest.FormatChangeSetYaml(LOriginal);
  Assert.IsTrue(LYaml.Contains('cs-demo-01'));
  Assert.IsTrue(LYaml.Contains('func-demo'));
  Assert.IsTrue(LYaml.Contains('view-demo'));
  Assert.IsTrue(LYaml.Contains('auto-refresh'));
  Assert.IsTrue(LYaml.Contains('explicit'));
  Assert.IsTrue(LYaml.Contains('inferred'));

  LParsed := TAsWishCandidateIngest.ParseChangeSetYaml(LYaml);
  Assert.AreEqual('cs-demo-01', LParsed.Id);
  Assert.AreEqual('func-demo', LParsed.IntentNodeId);
  Assert.AreEqual(ttFunction, LParsed.IntentTree);
  Assert.AreEqual('add auto-refresh', LParsed.RawUserIntent);
  Assert.AreEqual('bob', LParsed.Author);
  Assert.AreEqual<Integer>(2, Length(LParsed.AffectedProjections));
  Assert.AreEqual<Integer>(2, Length(LParsed.Items));
  Assert.AreEqual('func-demo', LParsed.Items[0].TargetNodeId);
  Assert.AreEqual('summary', LParsed.Items[0].Field);
  Assert.AreEqual('Static view', LParsed.Items[0].BeforeValue);
  Assert.AreEqual('Auto-refreshing view', LParsed.Items[0].AfterValue);
  Assert.AreEqual(cstExplicit, LParsed.Items[0].SourceType);
  Assert.AreEqual('view-demo', LParsed.Items[1].TargetNodeId);
  Assert.AreEqual(cstInferred, LParsed.Items[1].SourceType);
end;

procedure TCandidateIngestTests.ChangeSet_SaveAndLoad_PersistsToDisk;
var
  LTempDir: string;
  LCS, LLoaded: TChangeSet;
  LItem: TChangeItem;
  LSavedPath: string;
begin
  LTempDir := TPath.Combine(TPath.GetTempPath, 'aswish_test_cs_' + FormatDateTime('hhnnsszzz', Now));
  try
    TDirectory.CreateDirectory(LTempDir);
    LCS := TChangeSet.CreateNew('cs-test-99', 'mod-core', ttModule, 'refactor parser');
    LItem := TChangeItem.CreateItem('mod-core', ttModule, 'summary', 'old parser', 'new parser', cstExplicit, 'refactor');
    LCS.Items := TArray<TChangeItem>.Create(LItem);

    LSavedPath := FCand.SaveChangeSet(LTempDir, LCS);
    Assert.IsTrue(TFile.Exists(LSavedPath), 'change set yaml must exist');

    LLoaded := FCand.LoadChangeSet(LTempDir, 'cs-test-99');
    Assert.AreEqual('cs-test-99', LLoaded.Id);
    Assert.AreEqual('mod-core', LLoaded.IntentNodeId);
    Assert.AreEqual('refactor parser', LLoaded.RawUserIntent);
    Assert.AreEqual<Integer>(1, Length(LLoaded.Items));
    Assert.AreEqual('new parser', LLoaded.Items[0].AfterValue);
  finally
    if TDirectory.Exists(LTempDir) then
      TDirectory.Delete(LTempDir, True);
  end;
end;

procedure TCandidateIngestTests.ChangeSet_ComputeAffectedProjections_ViaSemanticBundles;
var
  LBundles: TList<TSemanticBundle>;
  LBundle: TSemanticBundle;
  LAffected: TArray<TTreeType>;
begin
  LBundles := TList<TSemanticBundle>.Create;
  try
    LBundle := Default(TSemanticBundle);
    LBundle.Id := 'bundle-auth';
    LBundle.Title := 'Auth Flow';
    LBundle.NodeIds := TArray<string>.Create('func-login', 'mod-auth', 'view-login', 'data-user');
    LBundles.Add(LBundle);

    LAffected := FCand.ComputeAffectedProjections('func-login', LBundles);
    Assert.AreEqual<Integer>(4, Length(LAffected), 'bundle with 4 trees should yield 4 affected projections');
  finally
    LBundles.Free;
  end;
end;

procedure TCandidateIngestTests.ChangeSet_DistinguishesExplicitInferredUnknown;
var
  LCS, LParsed: TChangeSet;
  LItem1, LItem2, LItem3: TChangeItem;
  LYaml: string;
begin
  LCS := TChangeSet.CreateNew('cs-diff-01', 'func-pay', ttFunction, 'pay with points');
  LItem1 := TChangeItem.CreateItem('func-pay', ttFunction, 'summary', 'cash only', 'points supported', cstExplicit, 'user explicitly stated');
  LItem2 := TChangeItem.CreateItem('data-pay', ttData, 'points_balance', '0', 'points field added', cstInferred, 'deduced data field');
  LItem3 := TChangeItem.CreateItem('view-pay', ttView, 'points_input', 'none', 'input field or slider?', cstUnknown, 'UI widget not specified');
  LCS.Items := TArray<TChangeItem>.Create(LItem1, LItem2, LItem3);

  LYaml := TAsWishCandidateIngest.FormatChangeSetYaml(LCS);
  LParsed := TAsWishCandidateIngest.ParseChangeSetYaml(LYaml);

  Assert.AreEqual<Integer>(3, Length(LParsed.Items));
  Assert.AreEqual(cstExplicit, LParsed.Items[0].SourceType);
  Assert.AreEqual(cstInferred, LParsed.Items[1].SourceType);
  Assert.AreEqual(cstUnknown, LParsed.Items[2].SourceType);
end;

procedure TCandidateIngestTests.ChangeSet_DoesNotMutateCanonicalSpec;
var
  LFunc: TList<TSpecNode>;
  LCS: TChangeSet;
  LItem: TChangeItem;
begin
  LFunc := StubFunctionRoot;
  try
    var LOldSummary := LFunc[0].Summary;
    LCS := TChangeSet.CreateNew('cs-test-01', 'func-demo', ttFunction, 'mutating intent text');
    LItem := TChangeItem.CreateItem('func-demo', ttFunction, 'summary', LOldSummary, 'RADICAL CHANGE', cstExplicit, 'test');
    LCS.Items := TArray<TChangeItem>.Create(LItem);

    // Formatting and creating ChangeSet must not affect in-memory live tree
    Assert.AreEqual(LOldSummary, LFunc[0].Summary, 'ChangeSet generation alone must not mutate live spec');
  finally
    LFunc.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Change Set Review & Decision Writeback (WO-20260830-0027C)
// ---------------------------------------------------------------------------

procedure TCandidateIngestTests.ChangeSet_ReviewSummary_FormatsSemanticChanges;
var
  LCS: TChangeSet;
  LItem: TChangeItem;
  LNodes: TList<TSpecNode>;
  LSummary: string;
begin
  LCS := TChangeSet.CreateNew('cs-rev-01', 'func-demo', ttFunction, 'allow users to deactivate account');
  LCS.AffectedProjections := TArray<TTreeType>.Create(ttFunction, ttView);
  LItem := TChangeItem.CreateItem('func-demo', ttFunction, 'summary', 'delete account permanently', 'deactivate account temporarily', cstExplicit, 'user requested soft delete');
  LCS.Items := TArray<TChangeItem>.Create(LItem);

  LNodes := StubFunctionRoot;
  try
    LSummary := FCand.FormatChangeSetReviewSummary(LCS, LNodes);
    Assert.IsTrue(LSummary.Contains('cs-rev-01'), 'review summary must contain ChangeSet ID');
    Assert.IsTrue(LSummary.Contains('func-demo'), 'review summary must contain target node ID');
    Assert.IsTrue(LSummary.Contains('delete account permanently'), 'review summary must contain Before value');
    Assert.IsTrue(LSummary.Contains('deactivate account temporarily'), 'review summary must contain After value');
    Assert.IsTrue(LSummary.Contains('explicit'), 'review summary must contain Source Type');
    Assert.IsTrue(LSummary.Contains('user requested soft delete'), 'review summary must contain Reason');
  finally
    LNodes.Free;
  end;
end;

procedure TCandidateIngestTests.ChangeSet_Accept_AppliesChangesToCanonicalSpec;
var
  LCS: TChangeSet;
  LItem: TChangeItem;
  LDec: TSpecDecision;
  LFunc: TList<TSpecNode>;
  LStats: TMergeStats;
begin
  LCS := TChangeSet.CreateNew('cs-acc-01', 'func-demo', ttFunction, 'update checkout flow');
  LItem := TChangeItem.CreateItem('func-demo', ttFunction, 'summary', 'legacy checkout', 'fast 1-click checkout', cstExplicit, 'intent');
  LCS.Items := TArray<TChangeItem>.Create(LItem);

  LDec := Default(TSpecDecision);
  LDec.Id := 'dec-0099';
  LDec.DecisionType := dtConfirm;
  LDec.Status := dsAccepted;
  LDec.TargetNodes := TArray<string>.Create('func-demo');

  LFunc := StubFunctionRoot;
  try
    LStats := FCand.ApplyChangeSet(LCS, LDec, LFunc, nil, nil, nil);
    Assert.AreEqual<Integer>(1, LStats.Merged, 'one node must be updated');
    Assert.AreEqual('fast 1-click checkout', LFunc[0].Summary, 'node summary must be updated to After value');
    Assert.AreEqual(rsAccepted, LFunc[0].ReviewStatus, 'review status must become accepted');
    Assert.AreEqual(gsConfirmed, LFunc[0].GenStatus, 'gen status must become confirmed');
    Assert.AreEqual<Integer>(1, Length(LFunc[0].DecisionRefs), 'decision reference must be recorded');
    Assert.AreEqual('dec-0099', LFunc[0].DecisionRefs[0]);
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.ChangeSet_Reject_DoesNotMutateCanonicalSpec;
var
  LCS: TChangeSet;
  LItem: TChangeItem;
  LDec: TSpecDecision;
  LFunc: TList<TSpecNode>;
  LStats: TMergeStats;
  LOldSummary: string;
begin
  LCS := TChangeSet.CreateNew('cs-rej-01', 'func-demo', ttFunction, 'unwanted change');
  LItem := TChangeItem.CreateItem('func-demo', ttFunction, 'summary', 'original summary', 'REJECTED VALUE', cstExplicit, 'intent');
  LCS.Items := TArray<TChangeItem>.Create(LItem);

  LDec := Default(TSpecDecision);
  LDec.Id := 'dec-0100';
  LDec.DecisionType := dtReject;
  LDec.Status := dsRejected;
  LDec.TargetNodes := TArray<string>.Create('func-demo');

  LFunc := StubFunctionRoot;
  try
    LOldSummary := LFunc[0].Summary;
    LStats := FCand.ApplyChangeSet(LCS, LDec, LFunc, nil, nil, nil);
    Assert.AreEqual<Integer>(0, LStats.Merged, 'no node should be updated on reject');
    Assert.AreEqual(LOldSummary, LFunc[0].Summary, 'Canonical spec summary MUST NOT be mutated on Reject');
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.ChangeSet_Clarify_DoesNotMutateCanonicalSpec;
var
  LCS: TChangeSet;
  LItem: TChangeItem;
  LDec: TSpecDecision;
  LFunc: TList<TSpecNode>;
  LStats: TMergeStats;
  LOldSummary: string;
begin
  LCS := TChangeSet.CreateNew('cs-cla-01', 'func-demo', ttFunction, 'unclear intent');
  LItem := TChangeItem.CreateItem('func-demo', ttFunction, 'summary', 'original summary', 'UNCONFIRMED GUESS', cstUnknown, 'intent');
  LCS.Items := TArray<TChangeItem>.Create(LItem);

  LDec := Default(TSpecDecision);
  LDec.Id := 'dec-0101';
  LDec.DecisionType := dtClarify;
  LDec.Status := dsProposed;
  LDec.TargetNodes := TArray<string>.Create('func-demo');

  LFunc := StubFunctionRoot;
  try
    LOldSummary := LFunc[0].Summary;
    LStats := FCand.ApplyChangeSet(LCS, LDec, LFunc, nil, nil, nil);
    Assert.AreEqual<Integer>(0, LStats.Merged, 'no node should be updated on clarify');
    Assert.AreEqual(LOldSummary, LFunc[0].Summary, 'Canonical spec summary MUST NOT be mutated on Clarify');
  finally
    LFunc.Free;
  end;
end;

procedure TCandidateIngestTests.CandidateIntent_ListCandidateIntents_ReturnsAll;
var
  LTempDir, LPath2: string;
  LIntent1, LIntent2: TCandidateIntent;
  LList: TArray<TCandidateIntent>;
begin
  LTempDir := TPath.Combine(TPath.GetTempPath, 'aswish_test_intent_list_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(LTempDir);
  try
    LIntent1 := TCandidateIntent.CreateNew('func-inventory', ttFunction, 'first intent', 'alice');
    LIntent2 := TCandidateIntent.CreateNew('mod-auth', ttModule, 'second intent', 'bob');

    FCand.SaveCandidateIntent(LTempDir, LIntent1);
    // Write second intent with distinct filename
    LPath2 := TPath.Combine(TPath.Combine(TPath.Combine(LTempDir, '.AsWish'), 'llm'), 'candidate-intent-02.yaml');
    TFile.WriteAllText(LPath2, TAsWishCandidateIngest.FormatCandidateIntentYaml(LIntent2), TEncoding.UTF8);

    LList := FCand.ListCandidateIntents(LTempDir);
    Assert.AreEqual<Integer>(2, Length(LList), 'ListCandidateIntents must return all saved candidate intents');
  finally
    if TDirectory.Exists(LTempDir) then
      TDirectory.Delete(LTempDir, True);
  end;
end;

procedure TCandidateIngestTests.ChangeSet_RenderReviewPage_GeneratesValidHtml;
var
  LTempDir, LHtmlPath, LHtml: string;
  LCS: TChangeSet;
  LItem: TChangeItem;
  LRender: TAsWishRenderService;
  LFunc: TList<TSpecNode>;
begin
  LTempDir := TPath.Combine(TPath.GetTempPath, 'aswish_test_review_page_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(LTempDir);
  LRender := TAsWishRenderService.Create;
  try
    LRender.Initialize(LTempDir);
    LCS := TChangeSet.CreateNew('cs-test-01', 'func-demo', ttFunction, 'User wants dark mode theme option', 'human');
    LItem := TChangeItem.CreateItem('func-demo', ttFunction, 'summary', 'Old summary', 'User wants dark mode theme option', cstExplicit, 'Interpreted from user');
    LCS.Items := TArray<TChangeItem>.Create(LItem);
    LCS.AffectedProjections := TArray<TTreeType>.Create(ttFunction, ttView);

    LFunc := StubFunctionRoot;
    try
      LRender.RenderChangeSetReviewPage(LCS, LFunc, 'TestProject');
    finally
      LFunc.Free;
    end;

    LHtmlPath := TPath.Combine(TPath.Combine(LTempDir, 'html'), 'changeset-review.html');
    Assert.IsTrue(TFile.Exists(LHtmlPath), 'changeset-review.html must exist on disk');

    LHtml := TFile.ReadAllText(LHtmlPath, TEncoding.UTF8);
    // Four-layer information model check (supports localized chrome)
    Assert.IsTrue(LHtml.Contains('1. I said') or LHtml.Contains('1. 我说') or LHtml.Contains('card-i-said'), 'Must contain Layer 1 (I said)');
    Assert.IsTrue(LHtml.Contains('User wants dark mode theme option'), 'Must display raw intent text');
    Assert.IsTrue(LHtml.Contains('2. AI understood') or LHtml.Contains('2. AI 理解') or LHtml.Contains('card-ai-understood'), 'Must contain Layer 2 (AI understood)');
    Assert.IsTrue(LHtml.Contains('3. Changes') or LHtml.Contains('3. 准备改变什么') or LHtml.Contains('card-changes'), 'Must contain Layer 3 (Changes)');
    Assert.IsTrue(LHtml.Contains('4. Decision') or LHtml.Contains('4. 你的裁决') or LHtml.Contains('card-decision'), 'Must contain Layer 4 (Decision)');

    // Human-readable source type check (NOT raw code tokens)
    Assert.IsTrue(LHtml.Contains('Explicitly Requested') or LHtml.Contains('你明确提出') or LHtml.Contains('badge-source-explicit'),
      'Must use human-readable source type (e.g. Explicitly Requested / 你明确提出)');

    // 0..9 Universal Choice buttons & Clarify Form check
    Assert.IsTrue(LHtml.Contains('btn-choice-opt'), 'Must have Choice.Option buttons');
    Assert.IsTrue(LHtml.Contains('btn-choice-regen'), 'Must have Choice.Regenerate (8) button');
    Assert.IsTrue(LHtml.Contains('btn-choice-input'), 'Must have Choice.Input (9) button');
    Assert.IsTrue(LHtml.Contains('btn-choice-back'), 'Must have Choice.Back (0) button');
    Assert.IsTrue(LHtml.Contains('clarify-panel'), 'Must have Clarify form panel');
    Assert.IsTrue(LHtml.Contains('postMessage'), 'Must have JS Bridge postMessage handler');
  finally
    LRender.Free;
    if TDirectory.Exists(LTempDir) then
      TDirectory.Delete(LTempDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCandidateIngestTests);

end.
