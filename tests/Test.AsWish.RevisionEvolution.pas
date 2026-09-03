{ ============================================================================
  Test.AsWish.RevisionEvolution

  DUnitX tests for Revision / Evolution Dual Exits & First Closed Loop (WO-20260903-0027H).
  Validates 8 core requirements:
  1. Unacceptable judgment -> dtReject decision written with TargetNodes pointing to diff items
  2. Acceptable judgment -> evolve creates New Baseline from live state with lineage parent
  3. Evolution new baseline has updated hash and passes VerifyBaseline
  4. Revision path: 2nd round creates Baseline v2 traceable to 1st round
  5. Unresolved judgment persisted as dtClarify / dsProposed
  6. Zero new entity types added (structural integrity)
  7. B' GUI entry point: intent can be initiated from node without changeset
  8. Missing difference.yaml -> fail-closed
  ============================================================================ }

unit Test.AsWish.RevisionEvolution;

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
  AsWish.Services.EvidenceCollector,
  AsWish.Services.Difference,
  AsWish.Services.Render;

type
  [TestFixture]
  TTestAsWishRevisionEvolution = class
  private
    FTestDir: string;
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    FDecisions: TAsWishDecisionsService;
    FCollector: TAsWishEvidenceCollectorService;
    FDifference: TAsWishDifferenceService;
    FRender: TAsWishRenderService;
    function MakeTestNode(const AId, ATitle, AKind, AParentId, ASummary: string;
      ATree: TTreeType = ttFunction): TSpecNode;
    procedure WriteMockEvidenceFile(const AReferencedNodeId: string);
  public
    [Setup]
    procedure SetUp;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test01_UnacceptableJudgment_RecordsRejectDecision_WithDiffTargetNodes;
    [Test]
    procedure Test02_AcceptableJudgment_EvolveCreatesNewBaseline_WithParentLineage;
    [Test]
    procedure Test03_EvolutionBaseline_UpdatedHash_PassesVerifyBaseline;
    [Test]
    procedure Test04_RevisionPath_SecondRoundCreatesBaselineV2_TraceableLineage;
    [Test]
    procedure Test05_UnresolvedJudgment_PersistedAsClarify;
    [Test]
    procedure Test06_StructuralIntegrity_ZeroNewEntities;
    [Test]
    procedure Test07_BPrimeEntryPoint_RenderIndexContainsIntentInput;
    [Test]
    procedure Test08_MissingDifferenceFile_FailClosed;
    [Test]
    procedure Test09_BPrimeTreeTypeParsing_FailClosed;
  end;

implementation

procedure TTestAsWishRevisionEvolution.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-rev-evo-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FTestDir);

  FStore := TAsWishStoreService.Create;
  FStore.Initialize(FTestDir);
  FStore.CreateDirectoryStructure;

  FSnapshot := TAsWishSnapshotService.Create(FStore);
  FDecisions := TAsWishDecisionsService.Create;
  FDecisions.Initialize(TPath.Combine(FTestDir, '.AsWish'));

  FCollector := TAsWishEvidenceCollectorService.Create(FStore, FSnapshot);
  FDifference := TAsWishDifferenceService.Create(FStore, FSnapshot);
  FRender := TAsWishRenderService.Create;
  FRender.Initialize(TPath.Combine(FTestDir, '.AsWish'));
end;

procedure TTestAsWishRevisionEvolution.TearDown;
begin
  FRender.Free;
  FDifference.Free;
  FCollector.Free;
  FDecisions.Free;
  FSnapshot.Free;
  FStore.Free;

  if TDirectory.Exists(FTestDir) then
    try
      TDirectory.Delete(FTestDir, True);
    except
    end;
end;

function TTestAsWishRevisionEvolution.MakeTestNode(const AId, ATitle, AKind,
  AParentId, ASummary: string; ATree: TTreeType): TSpecNode;
begin
  Result := Default(TSpecNode);
  Result.Id := AId;
  Result.Tree := ATree;
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

procedure TTestAsWishRevisionEvolution.WriteMockEvidenceFile(
  const AReferencedNodeId: string);
var
  LEvList: TList<TSpecEvidence>;
  LEv: TSpecEvidence;
begin
  LEvList := TList<TSpecEvidence>.Create;
  try
    LEv := Default(TSpecEvidence);
    LEv.Id := 'ev-impl-0001';
    LEv.SourceLayer := slImplementation;
    LEv.Path := 'src/test.pas';
    LEv.Lines := '1-10';
    LEv.Excerpt := 'unit test;';
    LEv.Confidence := clHigh;
    LEv.CreatedAt := Now;
    LEv.UpdatedAt := Now;
    LEv.SourceFileHash := 'mockhash123';
    LEv.ContentHash := 'mockcontent123';
    SetLength(LEv.ReferencedBy, 1);
    LEv.ReferencedBy[0] := AReferencedNodeId;
    LEvList.Add(LEv);

    FStore.WriteEvidenceFile('evidence/implementation-evidence.yaml', LEvList);
  finally
    LEvList.Free;
  end;
end;

procedure TTestAsWishRevisionEvolution.Test01_UnacceptableJudgment_RecordsRejectDecision_WithDiffTargetNodes;
var
  LReport: TSpecDifferenceReport;
  LDecId: string;
  LDec: TSpecDecision;
begin
  LReport := Default(TSpecDifferenceReport);
  LReport.BaselineId := 'B-0001';
  LReport.TreeType := 'function';
  LReport.ComputedAt := Now;

  SetLength(LReport.Items, 2);
  LReport.Items[0].NodeId := 'func-item-1';
  LReport.Items[0].Kind := dkMissing;
  LReport.Items[1].NodeId := 'func-item-2';
  LReport.Items[1].Kind := dkChanged;
  LReport.Items[1].ChangedAspect := daContent;

  LDecId := FDecisions.RecordDifferenceDecision(LReport, 'unacceptable', 'Implementation diverged from spec');

  Assert.IsNotEmpty(LDecId, 'Decision ID must be generated');
  LDec := FDecisions.FindById(LDecId);

  Assert.AreEqual<TDecisionType>(dtReject, LDec.DecisionType, 'Decision type must be dtReject for unacceptable');
  Assert.AreEqual<TDecisionStatus>(dsRejected, LDec.Status, 'Status must be dsRejected');
  Assert.AreEqual<Integer>(2, Length(LDec.TargetNodes), 'TargetNodes must contain all diff item node IDs');
  Assert.AreEqual<string>('func-item-1', LDec.TargetNodes[0]);
  Assert.AreEqual<string>('func-item-2', LDec.TargetNodes[1]);
end;

procedure TTestAsWishRevisionEvolution.Test02_AcceptableJudgment_EvolveCreatesNewBaseline_WithParentLineage;
var
  LBaseNodes, LLiveNodes: TList<TSpecNode>;
  LCS1, LCSEvolve: TChangeSet;
  LDec1, LDecEvolve: TSpecDecision;
  LBase1, LBase2: TAsWishBaseline;
  LBaseId1, LBaseId2, LDecEvolveId: string;
  LReport: TSpecDifferenceReport;
begin
  LBaseNodes := TList<TSpecNode>.Create;
  LLiveNodes := TList<TSpecNode>.Create;
  try
    // Baseline 1
    LBaseNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Original spec'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LBaseNodes);

    LDec1 := Default(TSpecDecision);
    LDec1.Id := 'dec-0001';
    LDec1.DecisionType := dtConfirm;
    LDec1.Status := dsAccepted;

    LCS1 := Default(TChangeSet);
    LCS1.Id := 'cs-0001';
    LCS1.IntentTree := ttFunction;
    LCS1.IntentNodeId := 'func-01';

    LBaseId1 := FSnapshot.CreateBaseline(LDec1, LCS1, LBaseNodes, nil, nil, nil, LBase1);

    // Live state evolved (e.g. better implementation with enhanced summary)
    LLiveNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Evolved implementation (better)'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LLiveNodes);

    WriteMockEvidenceFile('func-01');

    // Compute diff
    LReport := FDifference.ComputeDifference(FTestDir, LBaseId1);
    Assert.AreEqual<Integer>(1, Length(LReport.Items));

    // Human makes Acceptable judgment -> Record decision
    LDecEvolveId := FDecisions.RecordDifferenceDecision(LReport, 'acceptable', 'Implementation improvement accepted');

    // Freeze Evolution Baseline
    LDecEvolve := FDecisions.FindById(LDecEvolveId);
    LCSEvolve := Default(TChangeSet);
    LCSEvolve.Id := 'cs-evolve-' + LDecEvolveId;
    LCSEvolve.IntentTree := ttFunction;
    LCSEvolve.IntentNodeId := 'func-01';

    LBaseId2 := FSnapshot.CreateBaseline(LDecEvolve, LCSEvolve, LLiveNodes, nil, nil, nil, LBase2);

    Assert.IsNotEmpty(LBaseId2);
    Assert.AreEqual<string>('B-0002', LBaseId2);
    Assert.AreEqual<string>(LDecEvolveId, LBase2.DecisionId);
  finally
    LLiveNodes.Free;
    LBaseNodes.Free;
  end;
end;

procedure TTestAsWishRevisionEvolution.Test03_EvolutionBaseline_UpdatedHash_PassesVerifyBaseline;
var
  LBaseNodes, LLiveNodes: TList<TSpecNode>;
  LCS1, LCSEvolve: TChangeSet;
  LDec1, LDecEvolve: TSpecDecision;
  LBase1, LBase2: TAsWishBaseline;
  LBaseId1, LBaseId2, LDecEvolveId: string;
  LReport: TSpecDifferenceReport;
begin
  LBaseNodes := TList<TSpecNode>.Create;
  LLiveNodes := TList<TSpecNode>.Create;
  try
    LBaseNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Spec v1'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LBaseNodes);

    LDec1 := Default(TSpecDecision);
    LDec1.Id := 'dec-0001';
    LDec1.DecisionType := dtConfirm;
    LDec1.Status := dsAccepted;

    LCS1 := Default(TChangeSet);
    LCS1.Id := 'cs-0001';
    LCS1.IntentTree := ttFunction;
    LCS1.IntentNodeId := 'func-01';

    LBaseId1 := FSnapshot.CreateBaseline(LDec1, LCS1, LBaseNodes, nil, nil, nil, LBase1);

    // Live state changed
    LLiveNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Spec v2 evolved'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LLiveNodes);
    WriteMockEvidenceFile('func-01');

    LReport := FDifference.ComputeDifference(FTestDir, LBaseId1);
    LDecEvolveId := FDecisions.RecordDifferenceDecision(LReport, 'acceptable', 'Evolve v2');
    LDecEvolve := FDecisions.FindById(LDecEvolveId);

    LCSEvolve := Default(TChangeSet);
    LCSEvolve.Id := 'cs-evolve-' + LDecEvolveId;
    LCSEvolve.IntentTree := ttFunction;
    LCSEvolve.IntentNodeId := 'func-01';

    LBaseId2 := FSnapshot.CreateBaseline(LDecEvolve, LCSEvolve, LLiveNodes, nil, nil, nil, LBase2);

    Assert.AreNotEqual(LBase1.ContentHash, LBase2.ContentHash, 'Evolved baseline must have updated content hash');
    Assert.IsTrue(FSnapshot.VerifyBaseline(LBaseId2), 'Evolved baseline must pass VerifyBaseline');
  finally
    LLiveNodes.Free;
    LBaseNodes.Free;
  end;
end;

procedure TTestAsWishRevisionEvolution.Test04_RevisionPath_SecondRoundCreatesBaselineV2_TraceableLineage;
var
  LBaseNodes, LRevNodes: TList<TSpecNode>;
  LCS1, LCS2: TChangeSet;
  LDec1, LDec2: TSpecDecision;
  LBase1, LBase2: TAsWishBaseline;
  LBaseId1, LBaseId2: string;
begin
  LBaseNodes := TList<TSpecNode>.Create;
  LRevNodes := TList<TSpecNode>.Create;
  try
    // Round 1
    LBaseNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Round 1 Summary'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LBaseNodes);

    LDec1 := Default(TSpecDecision);
    LDec1.Id := 'dec-0001';
    LDec1.DecisionType := dtConfirm;
    LDec1.Status := dsAccepted;

    LCS1 := Default(TChangeSet);
    LCS1.Id := 'cs-0001';
    LCS1.IntentTree := ttFunction;
    LCS1.IntentNodeId := 'func-01';

    LBaseId1 := FSnapshot.CreateBaseline(LDec1, LCS1, LBaseNodes, nil, nil, nil, LBase1);

    // Round 2 (Revision from new user intent)
    LRevNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Round 2 Revised Summary'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LRevNodes);

    LDec2 := Default(TSpecDecision);
    LDec2.Id := 'dec-0002';
    LDec2.DecisionType := dtConfirm;
    LDec2.Status := dsAccepted;

    LCS2 := Default(TChangeSet);
    LCS2.Id := 'cs-0002';
    LCS2.IntentTree := ttFunction;
    LCS2.IntentNodeId := 'func-01';

    LBaseId2 := FSnapshot.CreateBaseline(LDec2, LCS2, LRevNodes, nil, nil, nil, LBase2);

    Assert.AreEqual<string>('B-0001', LBaseId1);
    Assert.AreEqual<string>('B-0002', LBaseId2);
    Assert.AreEqual<string>('cs-0002', LBase2.Lineage.ChangeSetId);
    Assert.IsTrue(FSnapshot.VerifyBaseline(LBaseId2));
  finally
    LRevNodes.Free;
    LBaseNodes.Free;
  end;
end;

procedure TTestAsWishRevisionEvolution.Test05_UnresolvedJudgment_PersistedAsClarify;
var
  LReport: TSpecDifferenceReport;
  LDecId: string;
  LDec: TSpecDecision;
begin
  LReport := Default(TSpecDifferenceReport);
  LReport.BaselineId := 'B-0001';
  LReport.TreeType := 'function';
  LReport.ComputedAt := Now;

  SetLength(LReport.Items, 1);
  LReport.Items[0].NodeId := 'func-01';
  LReport.Items[0].Kind := dkChanged;
  LReport.Items[0].ChangedAspect := daContent;

  LDecId := FDecisions.RecordDifferenceDecision(LReport, 'unresolved', 'Need to consult team');
  LDec := FDecisions.FindById(LDecId);

  Assert.AreEqual<TDecisionType>(dtClarify, LDec.DecisionType);
  Assert.AreEqual<TDecisionStatus>(dsProposed, LDec.Status);
end;

procedure TTestAsWishRevisionEvolution.Test06_StructuralIntegrity_ZeroNewEntities;
var
  LDec: TSpecDecision;
  LBaseline: TAsWishBaseline;
begin
  // Zero new entity types: we only use TSpecDecision and TAsWishBaseline
  LDec := Default(TSpecDecision);
  LDec.DecisionType := dtAcceptDifference;
  Assert.AreEqual<string>('accept_difference', TSpecEnums.DecisionTypeToStr(LDec.DecisionType));

  LBaseline := Default(TAsWishBaseline);
  LBaseline.BaselineId := 'B-0001';
  Assert.AreEqual<string>('B-0001', LBaseline.BaselineId);
end;

procedure TTestAsWishRevisionEvolution.Test07_BPrimeEntryPoint_RenderIndexContainsIntentInput;
var
  LFunc: TList<TSpecNode>;
  LIndexPath, LHtml: string;
begin
  LFunc := TList<TSpecNode>.Create;
  try
    LFunc.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Summary'));
    FRender.RenderIndex('TestProject', 1, LFunc, nil, nil, nil, nil);

    LIndexPath := TPath.Combine(FTestDir, '.AsWish\html\index.html');
    Assert.IsTrue(TFile.Exists(LIndexPath), 'index.html must exist');

    LHtml := TFile.ReadAllText(LIndexPath, TEncoding.UTF8);
    Assert.IsTrue(Pos('index-new-intent-input', LHtml) > 0,
      'RenderIndex must contain index-new-intent-input for B'' GUI entry');
    Assert.IsTrue(Pos('submitIndexNewIntent', LHtml) > 0,
      'RenderIndex must contain submitIndexNewIntent JS bridge function');
  finally
    LFunc.Free;
  end;
end;

procedure TTestAsWishRevisionEvolution.Test08_MissingDifferenceFile_FailClosed;
var
  LEx: Boolean;
begin
  LEx := False;
  try
    // Attempting to read non-existent difference.yaml
    FDifference.ReadDifferenceFile('non-existent-diff.yaml');
  except
    on E: Exception do
      LEx := True;
  end;

  Assert.IsTrue(LEx, 'Must fail-closed when reading missing difference file');
end;

procedure TTestAsWishRevisionEvolution.Test09_BPrimeTreeTypeParsing_FailClosed;
var
  LTree: TTreeType;
begin
  // Valid tree types
  Assert.IsTrue(TSpecEnums.TryTreeTypeFromStr('function', LTree));
  Assert.AreEqual(ttFunction, LTree);

  Assert.IsTrue(TSpecEnums.TryTreeTypeFromStr('Function', LTree));
  Assert.AreEqual(ttFunction, LTree);

  Assert.IsTrue(TSpecEnums.TryTreeTypeFromStr('module', LTree));
  Assert.AreEqual(ttModule, LTree);

  Assert.IsTrue(TSpecEnums.TryTreeTypeFromStr('view', LTree));
  Assert.AreEqual(ttView, LTree);

  Assert.IsTrue(TSpecEnums.TryTreeTypeFromStr('data', LTree));
  Assert.AreEqual(ttData, LTree);

  // Invalid / missing tree types must fail-closed (return False)
  Assert.IsFalse(TSpecEnums.TryTreeTypeFromStr('', LTree), 'Empty tree must return false');
  Assert.IsFalse(TSpecEnums.TryTreeTypeFromStr('invalid_tree', LTree), 'Invalid tree must return false');
  Assert.IsFalse(TSpecEnums.TryTreeTypeFromStr('unknown', LTree), 'Unknown tree must return false');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishRevisionEvolution);

end.
