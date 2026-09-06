{ ============================================================================
  AsWish.Services.VisualWorkflow.pas
  WO-0032: Visual Workflow Application Service Extraction (ADR-2).
  Orchestrates Visual Baseline confirmation, Difference evaluation,
  Decision recording, and Baseline evolution without any UI/Shell dependencies.
  ============================================================================ }
unit AsWish.Services.VisualWorkflow;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  AsWish.Models, AsWish.Services.SpecStore, AsWish.Services.Snapshot,
  AsWish.Services.Decisions, AsWish.Services.Difference;

type
  TAsWishVisualWorkflowService = class
  private
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    FDecisions: TAsWishDecisionsService;
    FDifference: TAsWishDifferenceService;
  public
    constructor Create(AStore: TAsWishStoreService; ASnapshot: TAsWishSnapshotService;
      ADecisions: TAsWishDecisionsService; ADifference: TAsWishDifferenceService);
    function ConfirmVisualBaseline(const ADecisionId: string;
      const ARendererVersion: string = 'wireframe-v1.0';
      const AVisualBinding: string = 'html/visual-preview.html'): string;
    function ComputeDifference(const AProjectDir, ABaselineId: string): TSpecDifferenceReport;
    function RecordDifferenceDecision(const AReport: TSpecDifferenceReport;
      AJudgment: TDifferenceJudgment; const ARationale: string;
      const AChangeSetId: string = ''): string;
    function EvolveBaseline(const ABaselineId, ADecisionId: string;
      out ANewBaseline: TAsWishBaseline): string;
  end;

implementation

constructor TAsWishVisualWorkflowService.Create(AStore: TAsWishStoreService;
  ASnapshot: TAsWishSnapshotService; ADecisions: TAsWishDecisionsService;
  ADifference: TAsWishDifferenceService);
begin
  inherited Create;
  if AStore = nil then raise Exception.Create('TAsWishVisualWorkflowService requires AStore');
  if ASnapshot = nil then raise Exception.Create('TAsWishVisualWorkflowService requires ASnapshot');
  if ADecisions = nil then raise Exception.Create('TAsWishVisualWorkflowService requires ADecisions');
  if ADifference = nil then raise Exception.Create('TAsWishVisualWorkflowService requires ADifference');
  FStore := AStore;
  FSnapshot := ASnapshot;
  FDecisions := ADecisions;
  FDifference := ADifference;
end;

function TAsWishVisualWorkflowService.ConfirmVisualBaseline(const ADecisionId: string;
  const ARendererVersion, AVisualBinding: string): string;
var
  LDec: TSpecDecision;
  LBaseline: TAsWishBaseline;
  LCS: TChangeSet;
  LFunc, LMod, LView, LData: TList<TSpecNode>;
begin
  if ADecisionId.Trim = '' then
    raise Exception.Create('ConfirmVisualBaseline requires a non-empty DecisionId');

  LDec := FDecisions.FindById(ADecisionId);
  if LDec.Id = '' then
    raise Exception.CreateFmt('Decision "%s" not found', [ADecisionId]);
  if LDec.Status <> dsAccepted then
    raise Exception.CreateFmt('Decision "%s" is not accepted (status: %s)',
      [ADecisionId, TSpecEnums.DecisionStatusToStr(LDec.Status)]);

  LView := FStore.ReadTreeFile('trees/view-tree.yaml');
  if (LView = nil) or (LView.Count = 0) then
  begin
    if LView <> nil then LView.Free;
    raise Exception.Create('No View Spec nodes available to confirm visual baseline');
  end;

  LFunc := FStore.ReadTreeFile('trees/function-tree.yaml');
  LMod := FStore.ReadTreeFile('trees/module-tree.yaml');
  LData := FStore.ReadTreeFile('trees/data-tree.yaml');
  try
    var LCSId := LDec.ChangeSetId;
    if LCSId = '' then LCSId := 'cs-visual-baseline';
    LCS := TChangeSet.CreateNew(LCSId, 'root-view', ttView, 'Confirm Visual Baseline', 'human');

    Result := FSnapshot.CreateBaseline(LDec, LCS, LFunc, LMod, LView, LData,
      LBaseline, ARendererVersion, AVisualBinding);
  finally
    if LData <> nil then LData.Free;
    if LMod <> nil then LMod.Free;
    if LFunc <> nil then LFunc.Free;
    LView.Free;
  end;
end;

function TAsWishVisualWorkflowService.ComputeDifference(const AProjectDir,
  ABaselineId: string): TSpecDifferenceReport;
begin
  Result := FDifference.ComputeDifference(AProjectDir, ABaselineId);
end;

function TAsWishVisualWorkflowService.RecordDifferenceDecision(
  const AReport: TSpecDifferenceReport; AJudgment: TDifferenceJudgment;
  const ARationale, AChangeSetId: string): string;
var
  LAction: string;
begin
  case AJudgment of
    djAcceptable, djNoImportantDifference: LAction := 'acceptable';
    djUnacceptable: LAction := 'unacceptable';
  else
    LAction := 'unresolved';
  end;
  Result := FDecisions.RecordDifferenceDecision(AReport, LAction, ARationale, AChangeSetId);
  FDecisions.Save;
end;

function TAsWishVisualWorkflowService.EvolveBaseline(const ABaselineId,
  ADecisionId: string; out ANewBaseline: TAsWishBaseline): string;
var
  LDec: TSpecDecision;
  LCS: TChangeSet;
  LFunc, LMod, LView, LData: TList<TSpecNode>;
begin
  ANewBaseline := Default(TAsWishBaseline);
  if ADecisionId.Trim = '' then
    raise Exception.Create('EvolveBaseline requires an approved DecisionId');

  LDec := FDecisions.FindById(ADecisionId);
  if LDec.Id = '' then
    raise Exception.CreateFmt('Decision "%s" not found for evolution', [ADecisionId]);
  if LDec.Status <> dsAccepted then
    raise Exception.CreateFmt('Decision "%s" must be accepted to evolve baseline (status: %s)',
      [ADecisionId, TSpecEnums.DecisionStatusToStr(LDec.Status)]);
  if not ((LDec.DecisionType = dtConfirm) or (LDec.DecisionType = dtAcceptDifference)) then
    raise Exception.CreateFmt('Decision "%s" type (%s) does not permit baseline evolution',
      [ADecisionId, TSpecEnums.DecisionTypeToStr(LDec.DecisionType)]);

  LCS := Default(TChangeSet);
  LCS.Id := 'cs-evolve-' + ABaselineId;
  LCS.IntentTree := ttView;
  LCS.IntentNodeId := 'diff-evolve';

  LFunc := FStore.ReadTreeFile('trees/function-tree.yaml');
  LMod := FStore.ReadTreeFile('trees/module-tree.yaml');
  LView := FStore.ReadTreeFile('trees/view-tree.yaml');
  LData := FStore.ReadTreeFile('trees/data-tree.yaml');
  try
    Result := FSnapshot.CreateBaseline(LDec, LCS, LFunc, LMod, LView, LData,
      ANewBaseline, '', '', ABaselineId);
  finally
    if LData <> nil then LData.Free;
    if LView <> nil then LView.Free;
    if LMod <> nil then LMod.Free;
    if LFunc <> nil then LFunc.Free;
  end;
end;

end.
