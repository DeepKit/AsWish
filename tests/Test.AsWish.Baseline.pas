{ ============================================================================
  Test.AsWish.Baseline

  DUnitX tests for Accepted Baseline v0 (WO-20260830-0027E).
  Validates 11 core requirements:
  1. Accepted Decision -> Baseline exists
  2. Baseline references correct decision_id
  3. Baseline contains expected snapshot content
  4. content_hash determinism (same state twice -> identical hash)
  5. relation_hash determinism
  6. Change summary -> content_hash changes, relation_hash unchanged
  7. Change parent_id -> relation_hash changes, content_hash unchanged
  8. Reload Baseline -> identical hash + identical lineage
  9. Subsequent Spec modification does not alter historical Baseline (immutable)
  10. Lineage traceable (baseline -> decision -> change_set -> intent)
  11. Empty snapshot cannot become Accepted Baseline (fail-closed)
  ============================================================================ }

unit Test.AsWish.Baseline;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Hash,
  AsWish.Services.SpecStore,
  AsWish.Services.Snapshot,
  AsWish.Services.Decisions,
  AsWish.Services.CandidateIngest;

type
  [TestFixture]
  TTestAsWishBaseline = class
  private
    FTestDir: string;
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    function MakeTestNode(const AId, ATitle, AKind, AParentId, ASummary: string): TSpecNode;
    function MakeSampleChangeSet(const ACSId, AIntentId: string): TChangeSet;
    function MakeSampleDecision(const ADecId, ACSId: string): TSpecDecision;
  public
    [Setup]
    procedure SetUp;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test01_AcceptedDecision_BaselineExists;
    [Test]
    procedure Test02_Baseline_ReferencesCorrectDecisionId;
    [Test]
    procedure Test03_Baseline_ContainsExpectedSnapshotContent;
    [Test]
    procedure Test04_ContentHash_Determinism;
    [Test]
    procedure Test05_RelationHash_Determinism;
    [Test]
    procedure Test06_ChangeSummary_OnlyContentHashChanges;
    [Test]
    procedure Test07_ChangeParentId_OnlyRelationHashChanges;
    [Test]
    procedure Test08_ReloadBaseline_SameHashAndLineage;
    [Test]
    procedure Test09_SpecModification_DoesNotAlterHistoricalBaseline;
    [Test]
    procedure Test10_LineageTraceable_BaselineToDecisionToChangeSetToIntent;
    [Test]
    procedure Test11_EmptySnapshot_CannotBecomeAcceptedBaseline_FailClosed;
  end;

implementation

{ TTestAsWishBaseline }

function TTestAsWishBaseline.MakeTestNode(const AId, ATitle, AKind, AParentId,
  ASummary: string): TSpecNode;
begin
  Result := Default(TSpecNode);
  Result.Id := AId;
  Result.Title := ATitle;
  Result.Kind := AKind;
  Result.ParentId := AParentId;
  Result.Summary := ASummary;
  Result.Status := nsConfirmed;
  Result.Confidence := clHigh;
  Result.SourceLayer := slHumanDecision;
  Result.ContentHash := TSpecHash.NodeContentHash(Result);
  Result.RelationHash := TSpecHash.NodeRelationHash(Result);
end;

function TTestAsWishBaseline.MakeSampleChangeSet(const ACSId,
  AIntentId: string): TChangeSet;
begin
  Result := TChangeSet.CreateNew(ACSId, AIntentId, ttFunction, 'User intent description', 'human');
  SetLength(Result.Items, 1);
  Result.Items[0] := TChangeItem.CreateItem('func-001', ttFunction, 'summary', 'old summary', 'new summary', cstExplicit, 'user requested');
end;

function TTestAsWishBaseline.MakeSampleDecision(const ADecId,
  ACSId: string): TSpecDecision;
begin
  Result := Default(TSpecDecision);
  Result.Id := ADecId;
  Result.DecisionType := dtConfirm;
  Result.Title := 'Accept ChangeSet ' + ACSId;
  Result.DecisionText := 'Approved proposed changes.';
  Result.Rationale := 'Aligns with business goal.';
  Result.Status := dsAccepted;
  Result.DecidedBy := dbHuman;
  Result.Confidence := clHigh;
  Result.ChangeSetId := ACSId;
  Result.CreatedAt := Now;
  Result.UpdatedAt := Now;
end;

procedure TTestAsWishBaseline.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-baseline-test-' + TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FTestDir);
  FStore := TAsWishStoreService.Create;
  FStore.Initialize(FTestDir);
  FStore.CreateDirectoryStructure;
  FSnapshot := TAsWishSnapshotService.Create(FStore);
end;

procedure TTestAsWishBaseline.TearDown;
begin
  FSnapshot.Free;
  FStore.Free;
  if TDirectory.Exists(FTestDir) then
    TDirectory.Delete(FTestDir, True);
end;

procedure TTestAsWishBaseline.Test01_AcceptedDecision_BaselineExists;
var
  LFuncNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LBaseline: TAsWishBaseline;
  LBaseId: string;
begin
  LFuncNodes := TList<TSpecNode>.Create;
  try
    LFuncNodes.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);

    LCS := MakeSampleChangeSet('cs-001', 'intent-001');
    LDec := MakeSampleDecision('dec-001', 'cs-001');

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LFuncNodes, nil, nil, nil, LBaseline);

    Assert.IsTrue(LBaseId.StartsWith('B-'), 'Baseline ID should start with B-');
    Assert.AreEqual(LBaseId, LBaseline.BaselineId, 'Returned ID must match record ID');
    Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId, LBaseline), 'Baseline must be loadable from disk');
  finally
    LFuncNodes.Free;
  end;
end;

procedure TTestAsWishBaseline.Test02_Baseline_ReferencesCorrectDecisionId;
var
  LFuncNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LBaseline, LLoaded: TAsWishBaseline;
  LBaseId: string;
begin
  LFuncNodes := TList<TSpecNode>.Create;
  try
    LFuncNodes.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);

    LCS := MakeSampleChangeSet('cs-002', 'intent-002');
    LDec := MakeSampleDecision('dec-target-99', 'cs-002');

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LFuncNodes, nil, nil, nil, LBaseline);

    Assert.AreEqual('dec-target-99', LBaseline.DecisionId, 'Baseline must record decision_id');
    Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId, LLoaded));
    Assert.AreEqual('dec-target-99', LLoaded.DecisionId, 'Loaded baseline must preserve decision_id');
  finally
    LFuncNodes.Free;
  end;
end;

procedure TTestAsWishBaseline.Test03_Baseline_ContainsExpectedSnapshotContent;
var
  LFuncNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LBaseline: TAsWishBaseline;
  LBaseId, LSnapDir: string;
begin
  LFuncNodes := TList<TSpecNode>.Create;
  try
    LFuncNodes.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);

    LCS := MakeSampleChangeSet('cs-003', 'intent-003');
    LDec := MakeSampleDecision('dec-003', 'cs-003');

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LFuncNodes, nil, nil, nil, LBaseline);

    LSnapDir := TPath.Combine(FStore.BasePath, 'snapshots\' + LBaseline.SnapshotName);
    Assert.IsTrue(TDirectory.Exists(LSnapDir), 'Snapshot subfolder must exist');
    Assert.IsTrue(TFile.Exists(TPath.Combine(LSnapDir, 'snapshot.yaml')), 'snapshot.yaml must exist');
    Assert.IsTrue(TFile.Exists(TPath.Combine(LSnapDir, 'trees\function-tree.yaml')), 'trees/function-tree.yaml must exist');
  finally
    LFuncNodes.Free;
  end;
end;

procedure TTestAsWishBaseline.Test04_ContentHash_Determinism;
var
  LNodes1, LNodes2: TList<TSpecNode>;
  LHash1, LHash2: string;
begin
  LNodes1 := TList<TSpecNode>.Create;
  LNodes2 := TList<TSpecNode>.Create;
  try
    LNodes1.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));
    LNodes1.Add(MakeTestNode('func-002', 'Payment Gateway', 'function', 'func-001', 'Handles payments'));

    // Insert in reverse order to verify sorting stability
    LNodes2.Add(MakeTestNode('func-002', 'Payment Gateway', 'function', 'func-001', 'Handles payments'));
    LNodes2.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));

    LHash1 := TSpecHash.SnapshotContentHash(LNodes1);
    LHash2 := TSpecHash.SnapshotContentHash(LNodes2);

    Assert.IsNotEmpty(LHash1, 'ContentHash must not be empty');
    Assert.AreEqual(LHash1, LHash2, 'ContentHash must be deterministic regardless of node list order');
  finally
    LNodes1.Free;
    LNodes2.Free;
  end;
end;

procedure TTestAsWishBaseline.Test05_RelationHash_Determinism;
var
  LNodes1, LNodes2: TList<TSpecNode>;
  LHash1, LHash2: string;
begin
  LNodes1 := TList<TSpecNode>.Create;
  LNodes2 := TList<TSpecNode>.Create;
  try
    LNodes1.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));
    LNodes1.Add(MakeTestNode('func-002', 'Payment Gateway', 'function', 'func-001', 'Handles payments'));

    LNodes2.Add(MakeTestNode('func-002', 'Payment Gateway', 'function', 'func-001', 'Handles payments'));
    LNodes2.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));

    LHash1 := TSpecHash.SnapshotRelationHash(LNodes1);
    LHash2 := TSpecHash.SnapshotRelationHash(LNodes2);

    Assert.IsNotEmpty(LHash1, 'RelationHash must not be empty');
    Assert.AreEqual(LHash1, LHash2, 'RelationHash must be deterministic regardless of node list order');
  finally
    LNodes1.Free;
    LNodes2.Free;
  end;
end;

procedure TTestAsWishBaseline.Test06_ChangeSummary_OnlyContentHashChanges;
var
  LNodesA, LNodesB: TList<TSpecNode>;
  LContentA, LContentB, LRelA, LRelB: string;
begin
  LNodesA := TList<TSpecNode>.Create;
  LNodesB := TList<TSpecNode>.Create;
  try
    LNodesA.Add(MakeTestNode('func-001', 'Order Processor', 'function', 'root', 'Initial purpose description'));
    LNodesB.Add(MakeTestNode('func-001', 'Order Processor', 'function', 'root', 'Modified purpose description'));

    LContentA := TSpecHash.SnapshotContentHash(LNodesA);
    LContentB := TSpecHash.SnapshotContentHash(LNodesB);

    LRelA := TSpecHash.SnapshotRelationHash(LNodesA);
    LRelB := TSpecHash.SnapshotRelationHash(LNodesB);

    Assert.AreNotEqual(LContentA, LContentB, 'Modifying summary MUST change content_hash');
    Assert.AreEqual(LRelA, LRelB, 'Modifying summary MUST NOT change relation_hash');
  finally
    LNodesA.Free;
    LNodesB.Free;
  end;
end;

procedure TTestAsWishBaseline.Test07_ChangeParentId_OnlyRelationHashChanges;
var
  LNodesA, LNodesB: TList<TSpecNode>;
  LContentA, LContentB, LRelA, LRelB: string;
begin
  LNodesA := TList<TSpecNode>.Create;
  LNodesB := TList<TSpecNode>.Create;
  try
    LNodesA.Add(MakeTestNode('func-001', 'Order Processor', 'function', 'parent-alpha', 'Same summary purpose'));
    LNodesB.Add(MakeTestNode('func-001', 'Order Processor', 'function', 'parent-beta', 'Same summary purpose'));

    LContentA := TSpecHash.SnapshotContentHash(LNodesA);
    LContentB := TSpecHash.SnapshotContentHash(LNodesB);

    LRelA := TSpecHash.SnapshotRelationHash(LNodesA);
    LRelB := TSpecHash.SnapshotRelationHash(LNodesB);

    Assert.AreEqual(LContentA, LContentB, 'Modifying parent_id MUST NOT change content_hash');
    Assert.AreNotEqual(LRelA, LRelB, 'Modifying parent_id MUST change relation_hash');
  finally
    LNodesA.Free;
    LNodesB.Free;
  end;
end;

procedure TTestAsWishBaseline.Test08_ReloadBaseline_SameHashAndLineage;
var
  LFuncNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LBaseline, LLoaded: TAsWishBaseline;
  LBaseId: string;
begin
  LFuncNodes := TList<TSpecNode>.Create;
  try
    LFuncNodes.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Processes checkout orders'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);

    LCS := MakeSampleChangeSet('cs-reload-01', 'intent-reload-01');
    LDec := MakeSampleDecision('dec-reload-01', 'cs-reload-01');

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LFuncNodes, nil, nil, nil, LBaseline);

    Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId, LLoaded), 'Should load baseline');
    Assert.AreEqual(LBaseline.BaselineId, LLoaded.BaselineId);
    Assert.AreEqual(LBaseline.ContentHash, LLoaded.ContentHash);
    Assert.AreEqual(LBaseline.RelationHash, LLoaded.RelationHash);
    Assert.AreEqual('cs-reload-01', LLoaded.Lineage.ChangeSetId);
    Assert.AreEqual('intent-reload-01', LLoaded.Lineage.IntentId);
    Assert.IsTrue(FSnapshot.VerifyBaseline(LBaseId), 'VerifyBaseline should pass for untouched snapshot');
  finally
    LFuncNodes.Free;
  end;
end;

procedure TTestAsWishBaseline.Test09_SpecModification_DoesNotAlterHistoricalBaseline;
var
  LFuncNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LBaseline: TAsWishBaseline;
  LBaseId: string;
  LOriginalContentHash: string;
begin
  LFuncNodes := TList<TSpecNode>.Create;
  try
    LFuncNodes.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Version 1 summary'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);

    LCS := MakeSampleChangeSet('cs-hist-01', 'intent-hist-01');
    LDec := MakeSampleDecision('dec-hist-01', 'cs-hist-01');

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LFuncNodes, nil, nil, nil, LBaseline);
    LOriginalContentHash := LBaseline.ContentHash;

    // Mutate live canonical spec
    LFuncNodes.Clear;
    LFuncNodes.Add(MakeTestNode('func-001', 'Order Processor', 'function', '', 'Version 2 drastically modified'));
    LFuncNodes.Add(MakeTestNode('func-999', 'New Rogue Node', 'function', '', 'Extra node'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);

    // Verify historical baseline remains unchanged and verified
    Assert.IsTrue(FSnapshot.VerifyBaseline(LBaseId), 'Historical baseline files must remain intact and verified');
    var LReloaded: TAsWishBaseline;
    Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId, LReloaded));
    Assert.AreEqual(LOriginalContentHash, LReloaded.ContentHash, 'Historical baseline content hash must not drift');
  finally
    LFuncNodes.Free;
  end;
end;

procedure TTestAsWishBaseline.Test10_LineageTraceable_BaselineToDecisionToChangeSetToIntent;
var
  LFuncNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LBaseline, LLoaded: TAsWishBaseline;
  LBaseId: string;
begin
  LFuncNodes := TList<TSpecNode>.Create;
  try
    LFuncNodes.Add(MakeTestNode('func-trace', 'Trace Node', 'function', '', 'Traceability test'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);

    LCS := MakeSampleChangeSet('cs-trace-100', 'intent-trace-200');
    LDec := MakeSampleDecision('dec-trace-50', 'cs-trace-100');

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LFuncNodes, nil, nil, nil, LBaseline);

    Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId, LLoaded));
    // Full lineage chain: Baseline -> Decision -> ChangeSet -> Intent
    Assert.AreEqual('dec-trace-50', LLoaded.DecisionId, 'Step 1: Baseline -> Decision');
    Assert.AreEqual('cs-trace-100', LLoaded.Lineage.ChangeSetId, 'Step 2: Decision -> ChangeSet');
    Assert.AreEqual('intent-trace-200', LLoaded.Lineage.IntentId, 'Step 3: ChangeSet -> Intent');
  finally
    LFuncNodes.Free;
  end;
end;

procedure TTestAsWishBaseline.Test11_EmptySnapshot_CannotBecomeAcceptedBaseline_FailClosed;
var
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LBaseline: TAsWishBaseline;
  LThrew: Boolean;
begin
  LCS := MakeSampleChangeSet('cs-empty', 'intent-empty');
  LDec := MakeSampleDecision('dec-empty', 'cs-empty');

  LThrew := False;
  try
    // Passing nil lists (0 nodes)
    FSnapshot.CreateBaseline(LDec, LCS, nil, nil, nil, nil, LBaseline);
  except
    on E: Exception do
      LThrew := True;
  end;

  Assert.IsTrue(LThrew, 'Creating an Accepted Baseline from empty spec state MUST fail-closed');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishBaseline);

end.
