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
    function ComputeDifference(const AProjectDir, ABaselineId: string;
      const AAllowDegraded: Boolean = True): TSpecDifferenceReport;
    function RecordDifferenceDecision(const AReport: TSpecDifferenceReport;
      AJudgment: TDifferenceJudgment; const ARationale: string;
      const AChangeSetId: string = ''): string;
    function EvolveBaseline(const ABaselineId, ADecisionId: string;
      out ANewBaseline: TAsWishBaseline): string;
    function ExportAgentHandoff(const AProjectDir, ABaselineId: string): string;
  end;

implementation

uses
  System.JSON,
  AsWish.Plugins.VCL.Difference;

function LoadBindingResolver(const AFilePath: string): IPlatformIdentityResolver;
var
  LLines: TStringList;
  LMap: TDictionary<string, string>;
  I, LColonPos: Integer;
  LLine, LKey, LVal: string;
  LInMap: Boolean;
begin
  Result := nil;
  if not TFile.Exists(AFilePath) then Exit;
  LLines := TStringList.Create;
  LMap := TDictionary<string, string>.Create;
  try
    LLines.LoadFromFile(AFilePath, TEncoding.UTF8);
    LInMap := False;
    for I := 0 to LLines.Count - 1 do
    begin
      LLine := LLines[I].Trim;
      if LLine.StartsWith('identity_map:') then
      begin
        LInMap := True;
        Continue;
      end;
      if LInMap then
      begin
        if (LLine = '') or (not LLines[I].StartsWith('  ')) or LLine.EndsWith(':') then
        begin
          if LLine.EndsWith(':') and not LLine.StartsWith('identity_map:') then
            LInMap := False;
          Continue;
        end;
        LColonPos := Pos(':', LLine);
        if LColonPos > 0 then
        begin
          LKey := Copy(LLine, 1, LColonPos - 1).Trim;
          LVal := Copy(LLine, LColonPos + 1, Length(LLine)).Trim;
          if (LKey <> '') and (LVal <> '') then
            LMap.AddOrSetValue(LKey, LVal);
        end;
      end;
    end;
    Result := TMapIdentityResolver.Create(LMap);
  finally
    LMap.Free;
    LLines.Free;
  end;
end;

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
  ABaselineId: string; const AAllowDegraded: Boolean = True): TSpecDifferenceReport;
var
  LObsJson, LConstraintsJson, LStylesJson: string;
  LResolver: IPlatformIdentityResolver;
  LAsWishDir, LSnapDir, LCandidate: string;
  LBaseline: TAsWishBaseline;
begin
  // Register VCL platform comparator
  FDifference.RegisterComparator(TAsWishVCLDifferenceComparator.Create);

  LAsWishDir := TPath.Combine(AProjectDir, '.AsWish');
  LObsJson := '';
  LConstraintsJson := '';
  LStylesJson := '';
  LResolver := nil;
  LSnapDir := '';

  // 1. Discover runtime observation JSON
  for var LSub in ['evidence\runtime-observation.json', 'runtime-observation.json', 'RuntimeObservation.json'] do
  begin
    LCandidate := TPath.Combine(LAsWishDir, LSub);
    if TFile.Exists(LCandidate) then
    begin
      LObsJson := TFile.ReadAllText(LCandidate, TEncoding.UTF8);
      Break;
    end;
  end;
  if (LObsJson = '') and TFile.Exists(TPath.Combine(AProjectDir, 'RuntimeObservation.json')) then
    LObsJson := TFile.ReadAllText(TPath.Combine(AProjectDir, 'RuntimeObservation.json'), TEncoding.UTF8);

  // 2. Discover visual binding YAML
  for var LSub in ['visual-binding.yaml', 'evidence\visual-binding.yaml', 'binding.yaml'] do
  begin
    LCandidate := TPath.Combine(LAsWishDir, LSub);
    if TFile.Exists(LCandidate) then
    begin
      LResolver := LoadBindingResolver(LCandidate);
      Break;
    end;
  end;
  if (LResolver = nil) and TFile.Exists(TPath.Combine(AProjectDir, 'visual-binding.yaml')) then
    LResolver := LoadBindingResolver(TPath.Combine(AProjectDir, 'visual-binding.yaml'));

  // 3. Discover layout constraints JSON (from project or baseline snapshot)
  for var LSub in ['layout-constraints.json', 'evidence\layout-constraints.json', 'trees\layout-constraints.json'] do
  begin
    LCandidate := TPath.Combine(LAsWishDir, LSub);
    if TFile.Exists(LCandidate) then
    begin
      LConstraintsJson := TFile.ReadAllText(LCandidate, TEncoding.UTF8);
      Break;
    end;
  end;
  if (LConstraintsJson = '') and FSnapshot.LoadBaseline(ABaselineId, LBaseline) then
  begin
    LSnapDir := TPath.Combine(LAsWishDir, 'snapshots\' + LBaseline.SnapshotName);
    LCandidate := TPath.Combine(LSnapDir, 'layout-constraints.json');
    if TFile.Exists(LCandidate) then
      LConstraintsJson := TFile.ReadAllText(LCandidate, TEncoding.UTF8);
  end;

  // 4. Discover expected styles JSON (from project or baseline snapshot)
  for var LSub in ['expected-styles.json', 'evidence\expected-styles.json', 'trees\expected-styles.json'] do
  begin
    LCandidate := TPath.Combine(LAsWishDir, LSub);
    if TFile.Exists(LCandidate) then
    begin
      LStylesJson := TFile.ReadAllText(LCandidate, TEncoding.UTF8);
      Break;
    end;
  end;
  if (LStylesJson = '') and (LSnapDir <> '') then
  begin
    LCandidate := TPath.Combine(LSnapDir, 'expected-styles.json');
    if TFile.Exists(LCandidate) then
      LStylesJson := TFile.ReadAllText(LCandidate, TEncoding.UTF8);
  end;

  Result := FDifference.ComputeDifference(AProjectDir, ABaselineId,
    LResolver, LObsJson, LConstraintsJson, LStylesJson, AAllowDegraded);
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
  LParent: TAsWishBaseline;
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
  LCS.IntentNodeId := 'diff-evolve';

  // The evolved baseline covers the same slice of the spec as its parent, so
  // the tree type has to be inherited rather than invented. Hardcoding ttView
  // here stamped tree_type "view" onto every evolved baseline regardless of
  // what the parent covered: `difference` then read only the view tree and
  // reported no differences for a project whose function tree had changed.
  if not FSnapshot.LoadBaseline(ABaselineId, LParent) then
    raise Exception.CreateFmt('Baseline "%s" not found for evolution', [ABaselineId]);
  // A parent with tree_type "all" hashes the first non-empty tree (function
  // wins in SnapshotService) but has no single-tree TTreeType representation.
  // In the Visual Workflow Service, visual difference decisions operate on
  // the visual surface (view tree). Falling back to ttView is therefore a
  // known, intentional narrowing: evolving an all-scope baseline via visual
  // workflow narrows the lineage to the view tree where the visual decision
  // was made (pinned by Test10).
  if not TSpecEnums.TryTreeTypeFromStr(LParent.TreeType, LCS.IntentTree) then
    LCS.IntentTree := ttView;

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

function TAsWishVisualWorkflowService.ExportAgentHandoff(const AProjectDir,
  ABaselineId: string): string;
var
  LAsWishDir, LHandoffDir, LHandoffFile, LSnapDir: string;
  LBaseline: TAsWishBaseline;
  LConstraintsJson: string;
  LViewNodes: TList<TSpecNode>;
  LSb: TStringBuilder;
  LConstraintsRoot: TJSONObject;
begin
  LAsWishDir := TPath.Combine(AProjectDir, '.AsWish');
  LHandoffDir := TPath.Combine(LAsWishDir, 'handoff');
  if not TDirectory.Exists(LHandoffDir) then
    TDirectory.CreateDirectory(LHandoffDir);

  LHandoffFile := TPath.Combine(LHandoffDir, 'agent-handoff.md');
  LConstraintsJson := '';

  if not FSnapshot.LoadBaseline(ABaselineId, LBaseline) then
    raise Exception.CreateFmt('Baseline "%s" not found for handoff export', [ABaselineId]);

  LSnapDir := TPath.Combine(LAsWishDir, 'snapshots\' + LBaseline.SnapshotName);

  for var LSub in [TPath.Combine(LSnapDir, 'layout-constraints.json'),
                   TPath.Combine(LAsWishDir, 'layout-constraints.json'),
                   TPath.Combine(LAsWishDir, 'evidence\layout-constraints.json')] do
  begin
    if TFile.Exists(LSub) then
    begin
      LConstraintsJson := TFile.ReadAllText(LSub, TEncoding.UTF8);
      Break;
    end;
  end;

  LViewNodes := FStore.ReadTreeFile(TPath.Combine('snapshots\' + LBaseline.SnapshotName, 'trees\view-tree.yaml'));
  if LViewNodes = nil then
    LViewNodes := FStore.ReadTreeFile('trees/view-tree.yaml');

  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# Agent Handoff Package');
    LSb.AppendLine('');
    LSb.AppendLine('> **NON-CANONICAL / EVIDENCE-ONLY / NOT PROTOCOL** (Accepted Baseline Handoff Specification)');
    LSb.AppendLine('');
    LSb.AppendLine('## 1. Baseline Target');
    LSb.AppendLine('- Baseline ID: ' + LBaseline.BaselineId);
    LSb.AppendLine('- Snapshot Name: ' + LBaseline.SnapshotName);
    LSb.AppendLine('- Decision ID: ' + LBaseline.DecisionId);
    LSb.AppendLine('- Content Hash: ' + LBaseline.ContentHash);
    LSb.AppendLine('- Relation Hash: ' + LBaseline.RelationHash);
    LSb.AppendLine('');
    LSb.AppendLine('## 2. Declared View Components');
    if LViewNodes <> nil then
    begin
      for var LN in LViewNodes do
        LSb.AppendLine(Format('- Node `%s`: %s (type: %s)', [LN.Id, LN.Summary, LN.Kind]));
    end;
    LSb.AppendLine('');
    LSb.AppendLine('## 3. Declared Relative Layout Intent & Provenance');
    if LConstraintsJson <> '' then
    begin
      LConstraintsRoot := TJSONObject.ParseJSONValue(LConstraintsJson) as TJSONObject;
      if LConstraintsRoot <> nil then
      try
        for var I := 0 to LConstraintsRoot.Count - 1 do
        begin
          var LPair := LConstraintsRoot.Pairs[I];
          if not (LPair.JsonValue is TJSONObject) then Continue;
          var LNodeId := LPair.JsonString.Value;
          var LObj := TJSONObject(LPair.JsonValue);
          var LRel := LObj.GetValue<string>('relation', '');
          var LProvObj := LObj.GetValue<TJSONObject>('provenance', nil);
          LSb.AppendLine(Format('### Constraint: `%s` %s', [LNodeId, LRel]));
          if LProvObj <> nil then
          begin
            LSb.AppendLine('- **Provenance Source**: ' + LProvObj.GetValue<string>('source_type', 'human_intent'));
            LSb.AppendLine('- **Intent ID**: ' + LProvObj.GetValue<string>('intent_id', ''));
            LSb.AppendLine('- **Confirmed By**: ' + LProvObj.GetValue<string>('author', 'human'));
            LSb.AppendLine('- **Decision ID**: ' + LProvObj.GetValue<string>('decision_id', ''));
            LSb.AppendLine('- **Statement**: ' + LProvObj.GetValue<string>('statement', ''));
            LSb.AppendLine('- **Confirmed At**: ' + LProvObj.GetValue<string>('confirmed_at', ''));
          end;
          LSb.AppendLine('');
        end;
      finally
        LConstraintsRoot.Free;
      end;
    end
    else
      LSb.AppendLine('- No explicit layout constraints found.');

    LSb.AppendLine('## 4. Implementation Guidance for Agent');
    LSb.AppendLine('Implement the VCL UI controls to strictly satisfy the declared layout constraints above.');
    LSb.AppendLine('Do NOT reverse the relative ordering confirmed by Human.');

    TAsWishStoreService.AtomicWriteTextFile(LHandoffFile, LSb.ToString);
    Result := LHandoffFile;
  finally
    if LViewNodes <> nil then LViewNodes.Free;
    LSb.Free;
  end;
end;

end.
