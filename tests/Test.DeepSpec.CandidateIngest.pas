{ ============================================================================
  Test.DeepSpec.CandidateIngest

  DUnitX tests for the strongly-typed candidate sandbox (BUG-8). These pin
  the contract that LLM output is never trusted raw: bad ids are rejected,
  foreign-key parent_ids are enforced, provenance/review authority is
  stripped, and the function root fog converges only when its summary
  actually changes.
  ============================================================================ }

unit Test.DeepSpec.CandidateIngest;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DeepSpec.Models,
  DeepSpec.Services.SpecStore,
  DeepSpec.Services.CandidateIngest;

type
  [TestFixture]
  TCandidateIngestTests = class
  private
    FStore: TDeepSpecStoreService;
    FCand: TDeepSpecCandidateIngest;
    function StubFunctionRoot: TList<TSpecNode>;
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
    procedure Ingest_DataTree_DroppedWithWarning;

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
  end;

implementation

{ TCandidateIngestTests }

procedure TCandidateIngestTests.Setup;
begin
  // ParseTreeNodes does not touch disk, so an uninitialized store is fine.
  FStore := TDeepSpecStoreService.Create;
  FCand := TDeepSpecCandidateIngest.Create(FStore);
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

// ---------------------------------------------------------------------------
// SplitDocuments
// ---------------------------------------------------------------------------

procedure TCandidateIngestTests.Split_ThreeDocs_ReturnsThree;
const
  CYAML = '---' + #10 + 'a: 1' + #10 + '---' + #10 + 'b: 2' + #10 + '---' + #10 + 'c: 3';
begin
  var LDocs := TDeepSpecCandidateIngest.SplitDocuments(CYAML);
  Assert.AreEqual<Integer>(3, Length(LDocs));
  Assert.IsTrue(LDocs[0].Contains('a: 1'));
  Assert.IsTrue(LDocs[2].Contains('c: 3'));
end;

procedure TCandidateIngestTests.Split_LeadingMarker_NoEmptyFirst;
const
  CYAML = '---' + #10 + 'a: 1' + #10 + '---' + #10 + 'b: 2';
begin
  var LDocs := TDeepSpecCandidateIngest.SplitDocuments(CYAML);
  Assert.AreEqual<Integer>(2, Length(LDocs));
  Assert.AreEqual('a: 1', LDocs[0].Trim);
end;

procedure TCandidateIngestTests.Split_SingleDoc_NoMarkers_ReturnsOne;
const
  CYAML = 'a: 1' + #10 + 'b: 2';
begin
  var LDocs := TDeepSpecCandidateIngest.SplitDocuments(CYAML);
  Assert.AreEqual<Integer>(1, Length(LDocs));
end;

procedure TCandidateIngestTests.Split_EmptyInput_ReturnsEmpty;
begin
  var LDocs := TDeepSpecCandidateIngest.SplitDocuments('');
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

procedure TCandidateIngestTests.Ingest_DataTree_DroppedWithWarning;
const
  CYAML = 'version: "1.0"' + #10 +
          'tree: data' + #10 +
          'nodes:' + #10 +
          '  - id: data-thing' + #10 +
          '    kind: entity';
begin
  var LFunc := StubFunctionRoot;
  try
    var R := FCand.Ingest(CYAML, LFunc, nil, nil);
    try
      // data nodes come from scan, not LLM — ingest must not touch them.
      Assert.AreEqual<Integer>(0, R.Accepted.Count);
      Assert.IsTrue(R.Warnings.Count > 0, 'expected a warning for data drop');
    finally
      R.FreeOwned;
    end;
  finally
    LFunc.Free;
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

initialization
  TDUnitX.RegisterTestFixture(TCandidateIngestTests);

end.
