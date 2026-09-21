{ ============================================================================
  Test.AsWish.Difference

  DUnitX tests for Structural Difference v0 & P2 Single-Tree Hash Fix (WO-20260903-0027G).
  Validates 8 core requirements:
  P2 Fix Group:
  1. Same content, different trigger tree -> baseline hashes different
  2. Single tree hash determinism
  3. Change summary -> content_hash changes; change parent_id -> relation_hash changes
  4. VerifyBaseline succeeds for single-tree baselines

  Difference Group:
  5. Missing / Extra / ContentChanged / RelationChanged scenarios
  6. Zero difference -> items empty
  7. Evidence file missing -> fail-closed
  8. difference.yaml round-trip readback
  ============================================================================ }

unit Test.AsWish.Difference;

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
  AsWish.Services.EvidenceCollector,
  AsWish.Services.Difference;

type
  [TestFixture]
  TTestAsWishDifference = class
  private
    FTestDir: string;
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    FCollector: TAsWishEvidenceCollectorService;
    FDifference: TAsWishDifferenceService;
    function MakeTestNode(const AId, ATitle, AKind, AParentId, ASummary: string;
      ATree: TTreeType = ttFunction): TSpecNode;
    procedure WriteMockEvidenceFile(const AReferencedNodeId: string);
  public
    [Setup]
    procedure SetUp;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test01_P2_DifferentTriggerTree_DifferentBaselineHash;
    [Test]
    procedure Test02_P2_SingleTreeHash_Determinism;
    [Test]
    procedure Test03_P2_SummaryChange_ContentHashChanges_ParentChange_RelationHashChanges;
    [Test]
    procedure Test04_P2_VerifyBaseline_SingleTree_Passes;
    [Test]
    procedure Test05_Difference_Missing_Extra_Changed_Scenarios;
    [Test]
    procedure Test06_Difference_ZeroDifference_EmptyItems;
    [Test]
    procedure Test07_Difference_MissingEvidence_FailClosed;
    [Test]
    procedure Test08_Difference_RoundTripReadback;
    [Test]
    procedure Test09_Difference_GracefulDegradation_WhenEvidenceEmpty;
    [Test]
    procedure Test10_Difference_NonVisual_GracefulHandling;
  end;

implementation

procedure TTestAsWishDifference.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-diff-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FTestDir);

  FStore := TAsWishStoreService.Create;
  FStore.Initialize(FTestDir);
  FStore.CreateDirectoryStructure;

  FSnapshot := TAsWishSnapshotService.Create(FStore);
  FCollector := TAsWishEvidenceCollectorService.Create(FStore, FSnapshot);
  FDifference := TAsWishDifferenceService.Create(FStore, FSnapshot);
end;

procedure TTestAsWishDifference.TearDown;
begin
  FDifference.Free;
  FCollector.Free;
  FSnapshot.Free;
  FStore.Free;

  if TDirectory.Exists(FTestDir) then
    try
      TDirectory.Delete(FTestDir, True);
    except
    end;
end;

function TTestAsWishDifference.MakeTestNode(const AId, ATitle, AKind, AParentId,
  ASummary: string; ATree: TTreeType): TSpecNode;
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

procedure TTestAsWishDifference.WriteMockEvidenceFile(const AReferencedNodeId: string);
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

procedure TTestAsWishDifference.Test01_P2_DifferentTriggerTree_DifferentBaselineHash;
var
  LFuncNodes, LViewNodes: TList<TSpecNode>;
  LCSFunc, LCSView: TChangeSet;
  LDec: TSpecDecision;
  LBaseFunc, LBaseView: TAsWishBaseline;
  LBaseId1, LBaseId2: string;
begin
  LFuncNodes := TList<TSpecNode>.Create;
  LViewNodes := TList<TSpecNode>.Create;
  try
    LFuncNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Func Summary', ttFunction));
    LViewNodes.Add(MakeTestNode('view-01', 'Page 1', 'page', '', 'View Summary', ttView));

    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LFuncNodes);
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LViewNodes);

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCSFunc := Default(TChangeSet);
    LCSFunc.Id := 'cs-func';
    LCSFunc.IntentTree := ttFunction;
    LCSFunc.IntentNodeId := 'func-01';

    LCSView := Default(TChangeSet);
    LCSView.Id := 'cs-view';
    LCSView.IntentTree := ttView;
    LCSView.IntentNodeId := 'view-01';

    LBaseId1 := FSnapshot.CreateBaseline(LDec, LCSFunc, LFuncNodes, nil, LViewNodes, nil, LBaseFunc);
    LBaseId2 := FSnapshot.CreateBaseline(LDec, LCSView, LFuncNodes, nil, LViewNodes, nil, LBaseView);

    Assert.AreEqual<string>('function', LBaseFunc.TreeType);
    Assert.AreEqual<string>('view', LBaseView.TreeType);
    Assert.AreNotEqual(LBaseFunc.ContentHash, LBaseView.ContentHash,
      'P2 Regression: Different trigger trees must produce different single-tree baseline hashes');
  finally
    LViewNodes.Free;
    LFuncNodes.Free;
  end;
end;

procedure TTestAsWishDifference.Test02_P2_SingleTreeHash_Determinism;
var
  LNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LB1, LB2: TAsWishBaseline;
begin
  LNodes := TList<TSpecNode>.Create;
  try
    LNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Func Summary', ttFunction));

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-01';
    LCS.IntentTree := ttFunction;
    LCS.IntentNodeId := 'func-01';

    FSnapshot.CreateBaseline(LDec, LCS, LNodes, nil, nil, nil, LB1);
    FSnapshot.CreateBaseline(LDec, LCS, LNodes, nil, nil, nil, LB2);

    Assert.AreEqual<string>(LB1.ContentHash, LB2.ContentHash, 'Single-tree content hash must be deterministic');
    Assert.AreEqual<string>(LB1.RelationHash, LB2.RelationHash, 'Single-tree relation hash must be deterministic');
  finally
    LNodes.Free;
  end;
end;

procedure TTestAsWishDifference.Test03_P2_SummaryChange_ContentHashChanges_ParentChange_RelationHashChanges;
var
  LNodes1, LNodes2, LNodes3: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LB1, LB2, LB3: TAsWishBaseline;
begin
  LNodes1 := TList<TSpecNode>.Create;
  LNodes2 := TList<TSpecNode>.Create;
  LNodes3 := TList<TSpecNode>.Create;
  try
    LNodes1.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Original Summary', ttFunction));
    LNodes2.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Modified Summary', ttFunction));
    LNodes3.Add(MakeTestNode('func-01', 'Feature 1', 'feature', 'func-root', 'Original Summary', ttFunction));

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-01';
    LCS.IntentTree := ttFunction;
    LCS.IntentNodeId := 'func-01';

    FSnapshot.CreateBaseline(LDec, LCS, LNodes1, nil, nil, nil, LB1);
    FSnapshot.CreateBaseline(LDec, LCS, LNodes2, nil, nil, nil, LB2);
    FSnapshot.CreateBaseline(LDec, LCS, LNodes3, nil, nil, nil, LB3);

    Assert.AreNotEqual(LB1.ContentHash, LB2.ContentHash, 'Summary change must change ContentHash');
    Assert.AreEqual<string>(LB1.RelationHash, LB2.RelationHash, 'Summary change must not change RelationHash');

    Assert.AreEqual<string>(LB1.ContentHash, LB3.ContentHash, 'Parent change must not change ContentHash');
    Assert.AreNotEqual(LB1.RelationHash, LB3.RelationHash, 'Parent change must change RelationHash');
  finally
    LNodes3.Free;
    LNodes2.Free;
    LNodes1.Free;
  end;
end;

procedure TTestAsWishDifference.Test04_P2_VerifyBaseline_SingleTree_Passes;
var
  LNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LB: TAsWishBaseline;
  LBaseId: string;
begin
  LNodes := TList<TSpecNode>.Create;
  try
    LNodes.Add(MakeTestNode('func-01', 'Feature 1', 'feature', '', 'Func Summary', ttFunction));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-01';
    LCS.IntentTree := ttFunction;
    LCS.IntentNodeId := 'func-01';

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LNodes, nil, nil, nil, LB);
    Assert.IsTrue(FSnapshot.VerifyBaseline(LBaseId), 'VerifyBaseline must succeed for single-tree baseline');
  finally
    LNodes.Free;
  end;
end;

procedure TTestAsWishDifference.Test05_Difference_Missing_Extra_Changed_Scenarios;
var
  LBaseNodes, LLiveNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LB: TAsWishBaseline;
  LBaseId: string;
  LReport: TSpecDifferenceReport;
begin
  LBaseNodes := TList<TSpecNode>.Create;
  LLiveNodes := TList<TSpecNode>.Create;
  try
    // Baseline has func-stay, func-will-change, func-will-miss
    LBaseNodes.Add(MakeTestNode('func-stay', 'Stay', 'feature', '', 'Stay Summary'));
    LBaseNodes.Add(MakeTestNode('func-change', 'Change', 'feature', '', 'Before Change Summary'));
    LBaseNodes.Add(MakeTestNode('func-miss', 'Missing Node', 'feature', '', 'Missing Summary'));

    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LBaseNodes);

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-diff-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-diff-01';
    LCS.IntentTree := ttFunction;
    LCS.IntentNodeId := 'func-change';

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LBaseNodes, nil, nil, nil, LB);

    // Live has func-stay (same), func-change (modified summary), func-extra (new node), but func-miss deleted!
    LLiveNodes.Add(MakeTestNode('func-stay', 'Stay', 'feature', '', 'Stay Summary'));
    LLiveNodes.Add(MakeTestNode('func-change', 'Change', 'feature', '', 'After Change Summary (Modified)'));
    LLiveNodes.Add(MakeTestNode('func-extra', 'Extra Node', 'feature', '', 'Extra Summary'));

    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LLiveNodes);

    // Write implementation evidence
    WriteMockEvidenceFile('func-stay');

    // Run difference
    LReport := FDifference.ComputeDifference(FTestDir, LBaseId);

    Assert.AreEqual<Integer>(3, Length(LReport.Items), 'Should detect exactly 3 differences: missing, changed, extra');

    var LFoundMissing := False;
    var LFoundChanged := False;
    var LFoundExtra := False;

    for var LItem in LReport.Items do
    begin
      if (LItem.NodeId = 'func-miss') and (LItem.Kind = dkMissing) then
        LFoundMissing := True;
      if (LItem.NodeId = 'func-change') and (LItem.Kind = dkChanged) and (LItem.ChangedAspect = daContent) then
        LFoundChanged := True;
      if (LItem.NodeId = 'func-extra') and (LItem.Kind = dkExtra) then
        LFoundExtra := True;
    end;

    Assert.IsTrue(LFoundMissing, 'Must detect func-miss as dkMissing');
    Assert.IsTrue(LFoundChanged, 'Must detect func-change as dkChanged with daContent');
    Assert.IsTrue(LFoundExtra, 'Must detect func-extra as dkExtra');
  finally
    LLiveNodes.Free;
    LBaseNodes.Free;
  end;
end;

procedure TTestAsWishDifference.Test06_Difference_ZeroDifference_EmptyItems;
var
  LNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LB: TAsWishBaseline;
  LBaseId: string;
  LReport: TSpecDifferenceReport;
begin
  LNodes := TList<TSpecNode>.Create;
  try
    LNodes.Add(MakeTestNode('func-01', 'F1', 'feature', '', 'Summary 1'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-01';
    LCS.IntentTree := ttFunction;
    LCS.IntentNodeId := 'func-01';

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LNodes, nil, nil, nil, LB);
    WriteMockEvidenceFile('func-01');

    LReport := FDifference.ComputeDifference(FTestDir, LBaseId);
    Assert.AreEqual<Integer>(0, Length(LReport.Items), 'Zero difference should produce 0 items');
  finally
    LNodes.Free;
  end;
end;

procedure TTestAsWishDifference.Test07_Difference_MissingEvidence_FailClosed;
var
  LNodes: TList<TSpecNode>;
  LCS: TChangeSet;
  LDec: TSpecDecision;
  LB: TAsWishBaseline;
  LBaseId: string;
  LEx: Boolean;
begin
  LNodes := TList<TSpecNode>.Create;
  try
    LNodes.Add(MakeTestNode('func-01', 'F1', 'feature', '', 'Summary 1'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-01';
    LCS.IntentTree := ttFunction;
    LCS.IntentNodeId := 'func-01';

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LNodes, nil, nil, nil, LB);

    // Note: implementation-evidence.yaml is NOT written
    LEx := False;
    try
      FDifference.ComputeDifference(FTestDir, LBaseId);
    except
      on E: Exception do
        LEx := True;
    end;

    Assert.IsTrue(LEx, 'Must fail-closed when implementation evidence is missing');
  finally
    LNodes.Free;
  end;
end;

procedure TTestAsWishDifference.Test08_Difference_RoundTripReadback;
var
  LReport1, LReport2: TSpecDifferenceReport;
  LItem: TSpecDifferenceItem;
begin
  LReport1 := Default(TSpecDifferenceReport);
  LReport1.BaselineId := 'B-test-01';
  LReport1.TreeType := 'function';
  LReport1.ComputedAt := Now;

  SetLength(LReport1.Items, 2);
  LItem := Default(TSpecDifferenceItem);
  LItem.NodeId := 'func-01';
  LItem.Kind := dkMissing;
  LItem.BaselineHash := 'hash-base-1';
  LReport1.Items[0] := LItem;

  LItem := Default(TSpecDifferenceItem);
  LItem.NodeId := 'func-02';
  LItem.Kind := dkChanged;
  LItem.ChangedAspect := daBoth;
  LItem.BaselineHash := 'hash-base-2';
  LItem.EvidenceHash := 'hash-ev-2';
  LReport1.Items[1] := LItem;

  FDifference.WriteDifferenceFile('difference.yaml', LReport1);
  Assert.IsTrue(TFile.Exists(TPath.Combine(FTestDir, '.AsWish\difference.yaml')));

  LReport2 := FDifference.ReadDifferenceFile('difference.yaml');
  Assert.AreEqual<string>('B-test-01', LReport2.BaselineId);
  Assert.AreEqual<string>('function', LReport2.TreeType);
  Assert.AreEqual<Integer>(2, Length(LReport2.Items));
  Assert.AreEqual<string>('func-01', LReport2.Items[0].NodeId);
  Assert.AreEqual<TDifferenceKind>(dkMissing, LReport2.Items[0].Kind);
  Assert.AreEqual<string>('func-02', LReport2.Items[1].NodeId);
  Assert.AreEqual<TDifferenceKind>(dkChanged, LReport2.Items[1].Kind);
  Assert.AreEqual<TDifferenceAspect>(daBoth, LReport2.Items[1].ChangedAspect);
end;

procedure TTestAsWishDifference.Test09_Difference_GracefulDegradation_WhenEvidenceEmpty;
var
  LNodes: TList<TSpecNode>;
  LDec: TSpecDecision;
  LCS: TChangeSet;
  LB: TAsWishBaseline;
  LBaseId: string;
  LReport: TSpecDifferenceReport;
begin
  LNodes := TList<TSpecNode>.Create;
  try
    LNodes.Add(MakeTestNode('func-01', 'Func One', 'feature', '', 'Summary 1'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-01';
    LCS.IntentNodeId := 'func-01';

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LNodes, nil, nil, nil, LB);

    // Call with AAllowDegraded = True when implementation-evidence.yaml is absent
    LReport := FDifference.ComputeDifference(FTestDir, LBaseId, nil, '', '', '', True);

    Assert.AreEqual<string>(LBaseId, LReport.BaselineId);
    Assert.IsTrue(LReport.IsDegraded, 'Report must be marked as degraded');
    Assert.IsTrue(LReport.DegradedReason.Contains('Implementation evidence missing'),
      'Degraded reason must explain missing implementation evidence');
    Assert.AreEqual<Integer>(0, Length(LReport.Items), 'Items should be 0 because baseline and live nodes match');
  finally
    LNodes.Free;
  end;
end;

procedure TTestAsWishDifference.Test10_Difference_NonVisual_GracefulHandling;
var
  LNodes: TList<TSpecNode>;
  LDec: TSpecDecision;
  LCS: TChangeSet;
  LB: TAsWishBaseline;
  LBaseId: string;
  LReport: TSpecDifferenceReport;
begin
  LNodes := TList<TSpecNode>.Create;
  try
    // Baseline has func-01
    LNodes.Add(MakeTestNode('func-01', 'Func One', 'feature', '', 'Summary 1'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    LDec := Default(TSpecDecision);
    LDec.Id := 'dec-01';
    LDec.DecisionType := dtConfirm;
    LDec.Status := dsAccepted;

    LCS := Default(TChangeSet);
    LCS.Id := 'cs-01';
    LCS.IntentNodeId := 'func-01';

    LBaseId := FSnapshot.CreateBaseline(LDec, LCS, LNodes, nil, nil, nil, LB);

    // Mutate live: add func-02 (extra)
    LNodes.Add(MakeTestNode('func-02', 'Func Two', 'feature', '', 'Summary 2'));
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    WriteMockEvidenceFile('func-01');

    // Call on function tree without any visual comparator: must compute L1 extra cleanly
    LReport := FDifference.ComputeDifference(FTestDir, LBaseId, nil, '', '', '', True);

    Assert.AreEqual<string>(LBaseId, LReport.BaselineId);
    Assert.AreEqual<Integer>(1, Length(LReport.Items), 'Should detect exactly 1 extra node in L1');
    Assert.AreEqual<string>('func-02', LReport.Items[0].NodeId);
    Assert.AreEqual<TDifferenceKind>(dkExtra, LReport.Items[0].Kind);
  finally
    LNodes.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishDifference);

end.
