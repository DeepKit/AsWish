{ ============================================================================
  Test.AsWish.VisualWorkflow.Provenance.Diff.pas
  WO-0034: Explicit Layout Intent Provenance Tests - Part 2 (Inverted Diff).
  Covers AC4 (Observation has no intent), AC5 (Declared vs Observed Comparator),
  and AC6 (Order Inversion -> daRelation).
  ============================================================================ }
unit Test.AsWish.VisualWorkflow.Provenance.Diff;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, AsWish.Models, AsWish.Hash,
  Test.AsWish.FixtureHelper,
  AsWish.Services.SpecStore, AsWish.Services.Snapshot, AsWish.Services.Decisions,
  AsWish.Services.Difference, AsWish.Services.VisualWorkflow;

type
  [TestFixture]
  TTestAsWishVisualWorkflowProvenanceDiff = class
  private
    FTestDir: string;
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    FDecisions: TAsWishDecisionsService;
    FDifference: TAsWishDifferenceService;
    FWorkflow: TAsWishVisualWorkflowService;
    function MakeViewNode(const AId, ATitle, AKind, AParentId: string): TSpecNode;
    function CreateSampleViewTree: TList<TSpecNode>;
    procedure WriteDummyImplementationEvidence(const ANodeId: string);
  public
    [Setup] procedure SetUp;
    [TearDown] procedure TearDown;
    [Test] procedure Test02_InvertedOrder_ProducesRelationDifferenceWithProvenance;
  end;

implementation

function TTestAsWishVisualWorkflowProvenanceDiff.MakeViewNode(const AId, ATitle, AKind, AParentId: string): TSpecNode;
begin
  Result := Default(TSpecNode);
  Result.Id := AId; Result.Title := ATitle; Result.Kind := AKind;
  Result.ParentId := AParentId; Result.Status := nsConfirmed; Result.Confidence := clHigh;
  Result.SourceLayer := slHumanDecision;
  Result.ContentHash := TSpecHash.NodeContentHash(Result);
  Result.RelationHash := TSpecHash.NodeRelationHash(Result);
end;

function TTestAsWishVisualWorkflowProvenanceDiff.CreateSampleViewTree: TList<TSpecNode>;
begin
  Result := TList<TSpecNode>.Create;
  Result.Add(MakeViewNode('node_view_root', 'Main Form', 'page', ''));
  Result.Add(MakeViewNode('node_btn_cancel', 'Cancel Button', 'component', 'node_view_root'));
  Result.Add(MakeViewNode('node_btn_confirm', 'Confirm Button', 'component', 'node_view_root'));
end;

procedure TTestAsWishVisualWorkflowProvenanceDiff.WriteDummyImplementationEvidence(const ANodeId: string);
var
  LEvList: TList<TSpecEvidence>;
  LEv: TSpecEvidence;
begin
  LEvList := TList<TSpecEvidence>.Create;
  try
    LEv := Default(TSpecEvidence);
    LEv.Id := 'ev-impl-0001';
    LEv.SourceLayer := slImplementation;
    LEv.Path := 'src/MainForm.pas';
    LEv.Lines := '1-10';
    LEv.Confidence := clHigh;
    LEv.CreatedAt := Now;
    LEv.UpdatedAt := Now;
    LEv.SourceFileHash := 'mockhash123';
    LEv.ContentHash := 'mockcontent123';
    SetLength(LEv.ReferencedBy, 1);
    LEv.ReferencedBy[0] := ANodeId;
    LEvList.Add(LEv);
    FStore.WriteEvidenceFile('evidence/implementation-evidence.yaml', LEvList);
  finally
    LEvList.Free;
  end;
end;

procedure TTestAsWishVisualWorkflowProvenanceDiff.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-wf-pdiff-' + TGuid.NewGuid.ToString.Substring(1, 8));
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

procedure TTestAsWishVisualWorkflowProvenanceDiff.TearDown;
begin
  FWorkflow.Free; FDifference.Free; FDecisions.Free; FSnapshot.Free; FStore.Free;
  if TDirectory.Exists(FTestDir) then TDirectory.Delete(FTestDir, True);
end;

procedure TTestAsWishVisualWorkflowProvenanceDiff.Test02_InvertedOrder_ProducesRelationDifferenceWithProvenance;
var
  LNodes: TList<TSpecNode>;
  LDecId, LBaseId, LAsWishDir, LObsJson, LBindingYaml, LConstraintsJson: string;
  LReport: TSpecDifferenceReport;
begin
  LAsWishDir := TPath.Combine(FTestDir, '.AsWish');
  LNodes := CreateSampleViewTree;
  try
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LNodes);
  finally
    LNodes.Free;
  end;

  LConstraintsJson :=
    '{' + sLineBreak +
    '  "node_btn_cancel": {' + sLineBreak +
    '    "relation": "left-of node_btn_confirm",' + sLineBreak +
    '    "provenance": {' + sLineBreak +
    '      "decision_id": "dec-0001",' + sLineBreak +
    '      "statement": "Cancel button must be placed left-of Confirm button"' + sLineBreak +
    '    }' + sLineBreak +
    '  }' + sLineBreak +
    '}';
  WriteFixtureText(TPath.Combine(LAsWishDir, 'layout-constraints.json'), LConstraintsJson, TEncoding.UTF8);

  LBindingYaml := 'identity_map:' + sLineBreak +
    '  AW_BtnConfirm: node_btn_confirm' + sLineBreak +
    '  AW_BtnCancel: node_btn_cancel' + sLineBreak;
  WriteFixtureText(TPath.Combine(LAsWishDir, 'visual-binding.yaml'), LBindingYaml, TEncoding.UTF8);

  LDecId := FDecisions.AddDecision(dtConfirm, 'Init Baseline', 'Init', 'Approved',
    ['node_btn_cancel', 'node_btn_confirm']);
  FDecisions.AcceptDecision(LDecId);
  FDecisions.Save;
  LBaseId := FWorkflow.ConfirmVisualBaseline(LDecId);

  WriteDummyImplementationEvidence('node_btn_confirm');

  // Observation has NO intent fields (AC4)
  LObsJson := '{"Platform": "VCL", "Observations": [' + sLineBreak +
    '  {"Name": "AW_BtnConfirm", "Bounds": {"Left": 180, "Top": 160, "Width": 80, "Height": 30}},' + sLineBreak +
    '  {"Name": "AW_BtnCancel", "Bounds": {"Left": 276, "Top": 160, "Width": 80, "Height": 30}}]}';
  WriteFixtureText(TPath.Combine(LAsWishDir, 'runtime-observation.json'), LObsJson, TEncoding.UTF8);

  LReport := FWorkflow.ComputeDifference(FTestDir, LBaseId);
  Assert.AreEqual(1, Integer(Length(LReport.Items)), 'Must report exactly 1 difference item for inverted layout');
  Assert.IsTrue(LReport.Items[0].ChangedAspect = daRelation, 'ChangedAspect must be daRelation (AC6)');
  Assert.IsTrue(Pos('[provenance: dec-0001]', LReport.Items[0].Note) > 0,
    'Difference note must trace provenance decision_id');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishVisualWorkflowProvenanceDiff);

end.
