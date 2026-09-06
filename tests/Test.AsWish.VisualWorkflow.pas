{ ============================================================================
  Test.AsWish.VisualWorkflow.pas
  WO-0032: Automated Tests for Visual Workflow Application Service (ADR-2).
  Covers AC1 (Headless), AC2 (Shared API), AC3 (Human Auth), AC4 (Traceability),
  and AC5 (4-Exit Difference Judgment).
  ============================================================================ }
unit Test.AsWish.VisualWorkflow;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, AsWish.Models, AsWish.Hash,
  AsWish.Services.SpecStore, AsWish.Services.Snapshot, AsWish.Services.Decisions,
  AsWish.Services.Difference, AsWish.Services.VisualWorkflow;

type
  [TestFixture]
  TTestAsWishVisualWorkflow = class
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
    [Test] procedure Test01_ZeroUiDependency_HeadlessExecution;
    [Test] procedure Test02_ConfirmVisualBaseline_ValidatesHumanDecision;
    [Test] procedure Test03_ConfirmVisualBaseline_Success_LinksDecisionAndSnapshot;
    [Test] procedure Test04_RecordDifferenceDecision_FourExits;
  end;

implementation

function TTestAsWishVisualWorkflow.MakeViewNode(const AId, ATitle, AKind, AParentId: string): TSpecNode;
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

function TTestAsWishVisualWorkflow.CreateSampleViewTree: TList<TSpecNode>;
begin
  Result := TList<TSpecNode>.Create;
  Result.Add(MakeViewNode('view-main', 'Main Form', 'page', ''));
  Result.Add(MakeViewNode('view-btn-ok', 'OK Button', 'component', 'view-main'));
end;

procedure TTestAsWishVisualWorkflow.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-wf-test-' + TGuid.NewGuid.ToString.Substring(1, 8));
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

procedure TTestAsWishVisualWorkflow.TearDown;
begin
  FWorkflow.Free;
  FDifference.Free;
  FDecisions.Free;
  FSnapshot.Free;
  FStore.Free;
  if TDirectory.Exists(FTestDir) then
    TDirectory.Delete(FTestDir, True);
end;

procedure TTestAsWishVisualWorkflow.Test01_ZeroUiDependency_HeadlessExecution;
begin
  // AC1 & AC2: Zero UI / IShell dependency, runs completely headless
  Assert.IsNotNull(FWorkflow, 'Workflow service must construct cleanly without UI/Shell dependencies');
end;

procedure TTestAsWishVisualWorkflow.Test02_ConfirmVisualBaseline_ValidatesHumanDecision;
var
  LNodes: TList<TSpecNode>;
  LDecId: string;
begin
  // AC3: Validates decision existence and human acceptance
  LNodes := CreateSampleViewTree;
  try
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LNodes);
  finally
    LNodes.Free;
  end;

  // 1. Empty decision ID
  Assert.WillRaise(procedure begin FWorkflow.ConfirmVisualBaseline(''); end,
    Exception, 'Empty DecisionId must be rejected');

  // 2. Non-existent decision ID
  Assert.WillRaise(procedure begin FWorkflow.ConfirmVisualBaseline('dec-nonexistent-0001'); end,
    Exception, 'Non-existent DecisionId must be rejected');

  // 3. Proposed (not accepted) decision
  LDecId := FDecisions.AddDecision(dtConfirm, 'Proposed confirm', 'Pending review', '', ['view-main']);
  FDecisions.Save;
  Assert.WillRaise(procedure begin FWorkflow.ConfirmVisualBaseline(LDecId); end,
    Exception, 'Unaccepted decision must be rejected');
end;

procedure TTestAsWishVisualWorkflow.Test03_ConfirmVisualBaseline_Success_LinksDecisionAndSnapshot;
var
  LNodes: TList<TSpecNode>;
  LDecId, LBaseId: string;
  LBaseline: TAsWishBaseline;
begin
  // AC3 & AC4: Observable and Decision strong bidirectional trace
  LNodes := CreateSampleViewTree;
  try
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LNodes);
  finally
    LNodes.Free;
  end;

  LDecId := FDecisions.AddDecision(dtConfirm, 'Confirm Visual Baseline',
    'Human accepts visual baseline', 'Accepted wireframe layout.', ['view-main', 'view-btn-ok']);
  FDecisions.AcceptDecision(LDecId);
  FDecisions.Save;

  LBaseId := FWorkflow.ConfirmVisualBaseline(LDecId, 'wireframe-v1.0', 'html/visual-preview.html');
  Assert.IsTrue(LBaseId.StartsWith('B-'), 'Baseline ID should start with B-');

  Assert.IsTrue(FSnapshot.LoadBaseline(LBaseId, LBaseline), 'Created baseline must be loadable');
  Assert.AreEqual(LDecId, LBaseline.DecisionId, 'Baseline must record the authoritative DecisionId');
  Assert.AreEqual('wireframe-v1.0', LBaseline.RendererVersion, 'Baseline must record renderer version');
  Assert.AreEqual('html/visual-preview.html', LBaseline.VisualBinding, 'Baseline must record visual binding');
end;

procedure TTestAsWishVisualWorkflow.Test04_RecordDifferenceDecision_FourExits;
var
  LReport: TSpecDifferenceReport;
  LItem: TSpecDifferenceItem;
  LDecId: string;
  LDec: TSpecDecision;
begin
  // AC4 & AC5: 4-exit difference judgment mapped to existing decisions
  LReport := Default(TSpecDifferenceReport);
  LReport.BaselineId := 'B-0001';
  LReport.TreeType := 'view';
  SetLength(LReport.Items, 1);
  LItem := Default(TSpecDifferenceItem);
  LItem.NodeId := 'view-btn-ok';
  LItem.Kind := dkChanged;
  LItem.ChangedAspect := daRelation;
  LItem.BaselineHash := 'base-hash-123';
  LItem.EvidenceHash := 'evid-hash-456';
  LItem.Note := 'parent relation mismatch';
  LReport.Items[0] := LItem;

  // Exit 1: djNoImportantDifference -> accepted
  LDecId := FWorkflow.RecordDifferenceDecision(LReport, djNoImportantDifference, 'Trivial layout delta');
  LDec := FDecisions.FindById(LDecId);
  Assert.AreEqual(Integer(dsAccepted), Integer(LDec.Status), 'djNoImportantDifference must be accepted');

  // Exit 2: djAcceptable -> accepted
  LDecId := FWorkflow.RecordDifferenceDecision(LReport, djAcceptable, 'Accept deliberate layout change');
  LDec := FDecisions.FindById(LDecId);
  Assert.AreEqual(Integer(dsAccepted), Integer(LDec.Status), 'djAcceptable must be accepted');

  // Exit 3: djUnacceptable -> rejected
  LDecId := FWorkflow.RecordDifferenceDecision(LReport, djUnacceptable, 'Button parent violates layout spec');
  LDec := FDecisions.FindById(LDecId);
  Assert.AreEqual(Integer(dsRejected), Integer(LDec.Status), 'djUnacceptable must be rejected');

  // Exit 4: djUnresolved -> proposed
  LDecId := FWorkflow.RecordDifferenceDecision(LReport, djUnresolved, 'Needs review with design team');
  LDec := FDecisions.FindById(LDecId);
  Assert.AreEqual(Integer(dsProposed), Integer(LDec.Status), 'djUnresolved must be proposed');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishVisualWorkflow);

end.