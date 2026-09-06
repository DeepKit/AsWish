{ ============================================================================
  Test.AsWish.VisualWorkflow.Evolution.pas
  WO-0032: Automated Tests for Visual Workflow Application Service (ADR-2).
  Covers AC5 (Decisions Authority), AC6 (Evolution Guard), AC7 (Hash Equivalence).
  ============================================================================ }
unit Test.AsWish.VisualWorkflow.Evolution;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, AsWish.Models, AsWish.Hash,
  AsWish.Services.SpecStore, AsWish.Services.Snapshot, AsWish.Services.Decisions,
  AsWish.Services.Difference, AsWish.Services.VisualWorkflow;

type
  [TestFixture]
  TTestAsWishVisualWorkflowEvolution = class
  private
    FTestDir: string;
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    FDecisions: TAsWishDecisionsService;
    FDifference: TAsWishDifferenceService;
    FWorkflow: TAsWishVisualWorkflowService;
    function MakeViewNode(const AId, ATitle, AKind, AParentId: string): TSpecNode;
    function CreateSampleViewTree: TList<TSpecNode>;
  public
    [Setup] procedure SetUp;
    [TearDown] procedure TearDown;
    [Test] procedure Test05_EvolveBaseline_RequiresApprovedDecision;
    [Test] procedure Test06_Equivalence_DeterministicBaselineHash;
    [Test] procedure Test07_DecisionsAuthority_NoPrivateRationaleRules;
  end;

implementation

function TTestAsWishVisualWorkflowEvolution.MakeViewNode(const AId, ATitle, AKind, AParentId: string): TSpecNode;
begin
  Result := Default(TSpecNode);
  Result.Id := AId;
  Result.Title := ATitle;
  Result.Kind := AKind;
  Result.ParentId := AParentId;
  Result.Status := nsConfirmed;
  Result.Confidence := clHigh;
  Result.SourceLayer := slHumanDecision;
  Result.ContentHash := TSpecHash.NodeContentHash(Result);
  Result.RelationHash := TSpecHash.NodeRelationHash(Result);
end;

function TTestAsWishVisualWorkflowEvolution.CreateSampleViewTree: TList<TSpecNode>;
begin
  Result := TList<TSpecNode>.Create;
  Result.Add(MakeViewNode('view-main', 'Main Form', 'page', ''));
  Result.Add(MakeViewNode('view-btn-ok', 'OK Button', 'component', 'view-main'));
end;

procedure TTestAsWishVisualWorkflowEvolution.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-wf-evo-' + TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FTestDir);
  FStore := TAsWishStoreService.Create;
  FStore.Initialize(FTestDir);
  FStore.CreateDirectoryStructure;
  FSnapshot := TAsWishSnapshotService.Create(FStore);
  FDecisions := TAsWishDecisionsService.Create;
  FDecisions.Initialize(TPath.Combine(FTestDir, '.AsWish'));
  FDecisions.Load;
  FDifference := TAsWishDifferenceService.Create(FStore, FSnapshot);
  FWorkflow := TAsWishVisualWorkflowService.Create(FStore, FSnapshot, FDecisions, FDifference);
end;

procedure TTestAsWishVisualWorkflowEvolution.TearDown;
begin
  FWorkflow.Free;
  FDifference.Free;
  FDecisions.Free;
  FSnapshot.Free;
  FStore.Free;
  if TDirectory.Exists(FTestDir) then
    TDirectory.Delete(FTestDir, True);
end;

procedure TTestAsWishVisualWorkflowEvolution.Test05_EvolveBaseline_RequiresApprovedDecision;
var
  LNodes: TList<TSpecNode>;
  LDecId, LInitBaseId, LEvolveBaseId: string;
  LNewBaseline: TAsWishBaseline;
  LReport: TSpecDifferenceReport;
begin
  // AC6: Evolve operation intercepted unless backed by accepted decision
  LNodes := CreateSampleViewTree;
  try
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LNodes);
  finally
    LNodes.Free;
  end;

  LDecId := FDecisions.AddDecision(dtConfirm, 'Initial Confirm', 'Init', 'Approved', ['view-main']);
  FDecisions.AcceptDecision(LDecId);
  FDecisions.Save;
  LInitBaseId := FWorkflow.ConfirmVisualBaseline(LDecId);

  // 1. Attempt evolution with empty decision -> rejected
  Assert.WillRaise(procedure begin FWorkflow.EvolveBaseline(LInitBaseId, '', LNewBaseline); end,
    Exception, 'Empty DecisionId must block baseline evolution');

  // 2. Attempt evolution with rejected decision -> blocked
  LReport := Default(TSpecDifferenceReport);
  LReport.BaselineId := LInitBaseId;
  LReport.TreeType := 'view';
  var LRejectDecId := FWorkflow.RecordDifferenceDecision(LReport, djUnacceptable, 'Broken layout');
  Assert.WillRaise(procedure begin FWorkflow.EvolveBaseline(LInitBaseId, LRejectDecId, LNewBaseline); end,
    Exception, 'Rejected decision must block baseline evolution');

  // 3. Evolution with accepted decision -> succeeds
  var LAcceptDecId := FWorkflow.RecordDifferenceDecision(LReport, djAcceptable, 'Evolving layout');
  LEvolveBaseId := FWorkflow.EvolveBaseline(LInitBaseId, LAcceptDecId, LNewBaseline);
  Assert.IsTrue(LEvolveBaseId.StartsWith('B-'), 'Evolved baseline must have valid ID');
  Assert.AreEqual(LInitBaseId, LNewBaseline.Lineage.ParentBaselineId, 'Evolved baseline must link to parent baseline');
  Assert.AreEqual(LAcceptDecId, LNewBaseline.DecisionId, 'Evolved baseline must link to evolution decision');
end;

procedure TTestAsWishVisualWorkflowEvolution.Test06_Equivalence_DeterministicBaselineHash;
var
  LNodes1, LNodes2: TList<TSpecNode>;
  LDecId1, LDecId2, LBaseId1, LBaseId2: string;
  LBase1, LBase2: TAsWishBaseline;
begin
  // AC7: GUI/CLI equivalence produces deterministic canonical artifacts
  LNodes1 := CreateSampleViewTree;
  try
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LNodes1);
  finally
    LNodes1.Free;
  end;

  LDecId1 := FDecisions.AddDecision(dtConfirm, 'Confirm', 'Text', 'Rationale', ['view-main']);
  FDecisions.AcceptDecision(LDecId1);
  FDecisions.Save;
  LBaseId1 := FWorkflow.ConfirmVisualBaseline(LDecId1);
  Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId1, LBase1));

  // Re-write identical view spec and create second baseline
  LNodes2 := CreateSampleViewTree;
  try
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LNodes2);
  finally
    LNodes2.Free;
  end;

  LDecId2 := FDecisions.AddDecision(dtConfirm, 'Confirm', 'Text', 'Rationale', ['view-main']);
  FDecisions.AcceptDecision(LDecId2);
  FDecisions.Save;
  LBaseId2 := FWorkflow.ConfirmVisualBaseline(LDecId2);
  Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId2, LBase2));

  Assert.AreEqual(LBase1.ContentHash, LBase2.ContentHash, 'Identical trees must produce identical ContentHash');
  Assert.AreEqual(LBase1.RelationHash, LBase2.RelationHash, 'Identical trees must produce identical RelationHash');
end;

procedure TTestAsWishVisualWorkflowEvolution.Test07_DecisionsAuthority_NoPrivateRationaleRules;
var
  LReport: TSpecDifferenceReport;
  LDecId: string;
  LDec: TSpecDecision;
begin
  // AC5: No private rationale rules invented by Application Service
  LReport := Default(TSpecDifferenceReport);
  LReport.BaselineId := 'B-0001';
  LReport.TreeType := 'view';

  // Allowed to record decision even when rationale is empty or custom
  LDecId := FWorkflow.RecordDifferenceDecision(LReport, djAcceptable, '');
  Assert.IsTrue(LDecId <> '', 'Workflow service must not add custom mandatory rationale vetoes');
  LDec := FDecisions.FindById(LDecId);
  Assert.IsTrue(LDec.Id <> '', 'Decision must be stored in FDecisions');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishVisualWorkflowEvolution);

end.
