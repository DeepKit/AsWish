{ ============================================================================
  Test.AsWish.VisualWorkflow.Provenance.pas
  WO-0034: Explicit Layout Intent Provenance Tests - Part 1 (Handoff & Storage).
  Covers AC1 (Human confirmation), AC2 (Provenance in disk), AC3 (Agent Handoff).
  ============================================================================ }
unit Test.AsWish.VisualWorkflow.Provenance;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, AsWish.Models, AsWish.Hash,
  AsWish.Services.SpecStore, AsWish.Services.Snapshot, AsWish.Services.Decisions,
  AsWish.Services.Difference, AsWish.Services.VisualWorkflow;

type
  [TestFixture]
  TTestAsWishVisualWorkflowProvenance = class
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
    [Test] procedure Test01_ExportAgentHandoff_ContainsLayoutIntentAndProvenance;
  end;

implementation

function TTestAsWishVisualWorkflowProvenance.MakeViewNode(const AId, ATitle, AKind, AParentId: string): TSpecNode;
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

function TTestAsWishVisualWorkflowProvenance.CreateSampleViewTree: TList<TSpecNode>;
begin
  Result := TList<TSpecNode>.Create;
  Result.Add(MakeViewNode('node_view_root', 'Main Form', 'page', ''));
  Result.Add(MakeViewNode('node_btn_cancel', 'Cancel Button', 'component', 'node_view_root'));
  Result.Add(MakeViewNode('node_btn_confirm', 'Confirm Button', 'component', 'node_view_root'));
end;

procedure TTestAsWishVisualWorkflowProvenance.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-wf-prov-' + TGuid.NewGuid.ToString.Substring(1, 8));
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

procedure TTestAsWishVisualWorkflowProvenance.TearDown;
begin
  FWorkflow.Free;
  FDifference.Free;
  FDecisions.Free;
  FSnapshot.Free;
  FStore.Free;
  if TDirectory.Exists(FTestDir) then
    TDirectory.Delete(FTestDir, True);
end;

procedure TTestAsWishVisualWorkflowProvenance.Test01_ExportAgentHandoff_ContainsLayoutIntentAndProvenance;
var
  LNodes: TList<TSpecNode>;
  LDecId, LBaseId, LHandoffFile, LHandoffContent, LAsWishDir: string;
  LConstraintsJson: string;
begin
  LAsWishDir := TPath.Combine(FTestDir, '.AsWish');
  LNodes := CreateSampleViewTree;
  try
    FStore.WriteTreeFile('trees/view-tree.yaml', ttView, LNodes);
  finally
    LNodes.Free;
  end;

  // Candidate layout constraints with explicit provenance (AC1, AC2)
  LConstraintsJson :=
    '{' + sLineBreak +
    '  "__comment": "NON-CANONICAL / EVIDENCE-ONLY / NOT PROTOCOL - WO-0034",' + sLineBreak +
    '  "node_btn_cancel": {' + sLineBreak +
    '    "relation": "left-of node_btn_confirm",' + sLineBreak +
    '    "provenance": {' + sLineBreak +
    '      "source_type": "human_intent",' + sLineBreak +
    '      "intent_id": "intent-layout-0001",' + sLineBreak +
    '      "decision_id": "dec-0001",' + sLineBreak +
    '      "author": "human",' + sLineBreak +
    '      "statement": "Cancel button must be placed left-of Confirm button",' + sLineBreak +
    '      "confirmed_at": "2026-09-07T08:00:00Z"' + sLineBreak +
    '    }' + sLineBreak +
    '  }' + sLineBreak +
    '}';
  TFile.WriteAllText(TPath.Combine(LAsWishDir, 'layout-constraints.json'), LConstraintsJson, TEncoding.UTF8);

  // Human confirmed baseline decision (AC1)
  LDecId := FDecisions.AddDecision(dtConfirm, 'Accepted Visual Baseline with Layout Intent',
    'Human confirmed Cancel button left-of Confirm button.', 'Approved relative order.',
    ['node_btn_cancel', 'node_btn_confirm']);
  FDecisions.AcceptDecision(LDecId);
  FDecisions.Save;
  LBaseId := FWorkflow.ConfirmVisualBaseline(LDecId);

  // Export Agent Handoff (AC3)
  LHandoffFile := FWorkflow.ExportAgentHandoff(FTestDir, LBaseId);
  Assert.IsTrue(TFile.Exists(LHandoffFile), 'Agent handoff file must exist on disk');

  LHandoffContent := TFile.ReadAllText(LHandoffFile, TEncoding.UTF8);
  Assert.IsTrue(Pos('NON-CANONICAL / EVIDENCE-ONLY / NOT PROTOCOL', LHandoffContent) > 0,
    'Handoff must contain non-canonical notice');
  Assert.IsTrue(Pos('node_btn_cancel', LHandoffContent) > 0, 'Handoff must mention node_btn_cancel');
  Assert.IsTrue(Pos('left-of node_btn_confirm', LHandoffContent) > 0, 'Handoff must contain left-of relation');
  Assert.IsTrue(Pos('dec-0001', LHandoffContent) > 0, 'Handoff must contain decision provenance');
  Assert.IsTrue(Pos('Cancel button must be placed left-of Confirm button', LHandoffContent) > 0,
    'Handoff must contain human statement');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishVisualWorkflowProvenance);

end.
