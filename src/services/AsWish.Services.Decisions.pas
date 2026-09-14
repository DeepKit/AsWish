
{ ============================================================================
  AsWish.Services.Decisions

  Manages decision write-back. Loads existing decisions, appends new ones,
  and serializes back to YAML per protocol §9.
  ============================================================================ }

unit AsWish.Services.Decisions;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Winapi.Windows,
  AsWish.Models;

type
  TAsWishDecisionsService = class(TInterfacedObject)
  private
    FBasePath: string;
    FDecisions: TList<TSpecDecision>;
    FNextSeq: Integer;
    function GenerateNextId: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Initialize(const AAsWishPath: string);
    procedure Load;
    procedure Save;

    function AddDecision(ADecisionType: TDecisionType;
      const ATitle, ADecisionText, ARationale: string;
      const ATargetNodes: TArray<string>): string;

    function FindById(const AId: string): TSpecDecision;
    function GetAccepted: TArray<TSpecDecision>;
    procedure AcceptDecision(const AId: string);
    procedure RejectDecision(const AId: string);

    /// <summary>
    /// Record a formal Human Decision for an AI-generated Change Set (WO-20260830-0027C).
    /// Links decision to ChangeSetId and records Accept / Reject / Clarify.
    /// </summary>
    function RecordChangeSetDecision(const AChangeSet: TChangeSet;
      AAction: TReviewStatus; const ARationale: string = '';
      AItemIndex: Integer = -1): string;

    /// <summary>
    /// Record a formal Human Decision for Structural Difference (WO-20260903-0027H, WO-20260903-2336-0027R2).
    /// Actions: 'acceptable', 'unacceptable', 'unresolved'.
    /// </summary>
    function RecordDifferenceDecision(const AReport: TSpecDifferenceReport;
      const AAction: string; const ARationale: string = '';
      const AChangeSetId: string = ''): string;

    /// <summary>
    /// Read pending-decisions.yaml (produced by the WebView2 JS Bridge),
    /// convert each entry to a formal decision via AddDecision, set its
    /// status to accepted/rejected based on the recorded action, then delete
    /// the pending file. Returns the count of promoted entries.
    /// </summary>
    function PromotePending: Integer;

    /// <summary>
    /// Apply state machine transitions to all trees for accepted/rejected
    /// decisions. Reads each tree, updates matching nodes via
    /// TSpecEnums.TryTransition*, writes back.
    /// </summary>
    procedure ApplyNodeStatusTransitions(
      const ATreeRelPath: string;
      AReadTree: TFunc<string, TList<TSpecNode>>;
      AWriteTree: TProc<string, TList<TSpecNode>>); overload;
    procedure ApplyNodeStatusTransitions(
      const ATreeRelPath: string;
      ANodes: TList<TSpecNode>); overload;

    property Decisions: TList<TSpecDecision> read FDecisions;
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  AsWish.Yaml.Writer,
  AsWish.Yaml.Parser,
  AsWish.Services.SpecStore;

constructor TAsWishDecisionsService.Create;
begin
  inherited Create;
  FDecisions := TList<TSpecDecision>.Create;
  FNextSeq := 1;
end;

destructor TAsWishDecisionsService.Destroy;
begin
  FDecisions.Free;
  inherited;
end;

procedure TAsWishDecisionsService.Initialize(const AAsWishPath: string);
begin
  FBasePath := TPath.Combine(AAsWishPath, 'decisions');
  if not TDirectory.Exists(FBasePath) then
    TDirectory.CreateDirectory(FBasePath);
end;

function TAsWishDecisionsService.GenerateNextId: string;
begin
  Result := Format('dec-%.4d', [FNextSeq]);
  Inc(FNextSeq);
end;

procedure TAsWishDecisionsService.Load;
var
  LParser: TYamlParser;
  LRoot: TYamlNode;
begin
  FDecisions.Clear;
  FNextSeq := 1;

  var LPath := TPath.Combine(FBasePath, 'requirement-decisions.yaml');
  if not TFile.Exists(LPath) then Exit;

  LParser := TYamlParser.Create;
  try
    LRoot := LParser.ParseFile(LPath);
    try
      var LDecSeq := LRoot.GetSeq('decisions');
      if LDecSeq = nil then Exit;

      for var I := 0 to LDecSeq.SeqCount - 1 do
      begin
        var LItem := LDecSeq.SeqItem(I);
        if LItem = nil then Continue;

        var LDec: TSpecDecision;
        LDec := Default(TSpecDecision);
        LDec.Id := LItem.GetString('id', '');
        LDec.Title := LItem.GetString('title', '');
        LDec.DecisionText := LItem.GetString('decision', '');
        LDec.Rationale := LItem.GetString('rationale', '');
        LDec.AiInstruction := LItem.GetString('ai_instruction', '');
        LDec.Release := LItem.GetString('release', '');
        LDec.SupersededBy := LItem.GetString('superseded_by', '');

        // DecisionType + target/affected node lists were never read back
        // (round-trip loss: after a restart, transitions had no targets and
        // no-op'd). Read them so Save/Load round-trips fully.
        LDec.DecisionType := TSpecEnums.DecisionTypeFromStr(
          LItem.GetString('type', ''), dtConfirm);
        var LTargets := LItem.GetSeq('target_nodes');
        if LTargets <> nil then
        begin
          SetLength(LDec.TargetNodes, LTargets.SeqCount);
          for var J := 0 to LTargets.SeqCount - 1 do
            LDec.TargetNodes[J] := LTargets.SeqItem(J).AsString;
        end;

        var LStatusStr := LItem.GetString('status', 'proposed');
        if LStatusStr = 'accepted' then LDec.Status := dsAccepted
        else if LStatusStr = 'rejected' then LDec.Status := dsRejected
        else if LStatusStr = 'superseded' then LDec.Status := dsSuperseded
        else if LStatusStr = 'rolled_back' then LDec.Status := dsRolledBack
        else if LStatusStr = 'withdrawn' then LDec.Status := dsWithdrawn
        else LDec.Status := dsProposed;

        var LDeciderStr := LItem.GetString('decided_by', 'system');
        if LDeciderStr = 'human' then LDec.DecidedBy := dbHuman else LDec.DecidedBy := dbSystem;

        LDec.ChangeSetId := LItem.GetString('change_set_id', '');
        LDec.ChangeItemIndex := LItem.GetInteger('change_item_index', -1);

        FDecisions.Add(LDec);

        // Track sequence number to avoid collisions
        if LDec.Id.StartsWith('dec-') then
        begin
          var LSeqNum := StrToIntDef(LDec.Id.Substring(4), 0);
          if LSeqNum >= FNextSeq then
            FNextSeq := LSeqNum + 1;
        end;
      end;
    finally
      LRoot.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TAsWishDecisionsService.Save;
var
  LWriter: TYamlWriter;
begin
  LWriter := TYamlWriter.Create;
  try
    LWriter.WriteDecisionsFile(FDecisions);
    // Atomic write (bugfix.md BUG-5 path) — never bypass the crash-safe
    // replace with a bare TFile.WriteAllText.
    TAsWishStoreService.AtomicWriteTextFile(
      TPath.Combine(FBasePath, 'requirement-decisions.yaml'),
      LWriter.ToString);
  finally
    LWriter.Free;
  end;
end;

function TAsWishDecisionsService.AddDecision(ADecisionType: TDecisionType;
  const ATitle, ADecisionText, ARationale: string;
  const ATargetNodes: TArray<string>): string;
var
  LDec: TSpecDecision;
begin
  LDec := Default(TSpecDecision);
  LDec.Id := GenerateNextId;
  LDec.DecisionType := ADecisionType;
  LDec.Title := ATitle;
  LDec.DecisionText := ADecisionText;
  LDec.Rationale := ARationale;
  LDec.TargetNodes := ATargetNodes;
  LDec.CreatedAt := Now;
  LDec.UpdatedAt := Now;
  LDec.DecidedBy := dbHuman;
  LDec.Confidence := clHigh;
  LDec.Status := dsProposed;

  FDecisions.Add(LDec);
  Result := LDec.Id;
  Save;
end;

function TAsWishDecisionsService.FindById(const AId: string): TSpecDecision;
begin
  for var LDec in FDecisions do
    if LDec.Id = AId then
      Exit(LDec);
  Result := Default(TSpecDecision);
end;

function TAsWishDecisionsService.GetAccepted: TArray<TSpecDecision>;
var
  LResult: TList<TSpecDecision>;
begin
  LResult := TList<TSpecDecision>.Create;
  try
    for var LDec in FDecisions do
      if LDec.Status = dsAccepted then
        LResult.Add(LDec);
    Result := LResult.ToArray;
  finally
    LResult.Free;
  end;
end;

procedure TAsWishDecisionsService.AcceptDecision(const AId: string);
begin
  for var I := 0 to FDecisions.Count - 1 do
    if FDecisions[I].Id = AId then
    begin
      var LDec := FDecisions[I];
      LDec.Status := dsAccepted;
      LDec.UpdatedAt := Now;
      FDecisions[I] := LDec;
      Save;
      Exit;
    end;
end;

procedure TAsWishDecisionsService.RejectDecision(const AId: string);
begin
  for var I := 0 to FDecisions.Count - 1 do
    if FDecisions[I].Id = AId then
    begin
      var LDec := FDecisions[I];
      LDec.Status := dsRejected;
      LDec.UpdatedAt := Now;
      FDecisions[I] := LDec;
      Save;
      Exit;
    end;
end;

function TAsWishDecisionsService.RecordChangeSetDecision(
  const AChangeSet: TChangeSet; AAction: TReviewStatus;
  const ARationale: string; AItemIndex: Integer): string;
var
  LDec: TSpecDecision;
  LTitle: string;
begin
  LDec := Default(TSpecDecision);
  LDec.Id := GenerateNextId;
  LDec.CreatedAt := Now;
  LDec.UpdatedAt := Now;
  LDec.DecidedBy := dbHuman;
  LDec.Confidence := clHigh;
  LDec.ChangeSetId := AChangeSet.Id;
  LDec.ChangeItemIndex := AItemIndex;
  if AChangeSet.IsFrameRejection then
  begin
    if (AChangeSet.RejectedNodeId <> '') and (AChangeSet.IntentNodeId <> '') then
      LDec.TargetNodes := TArray<string>.Create(AChangeSet.RejectedNodeId, AChangeSet.IntentNodeId)
    else if AChangeSet.RejectedNodeId <> '' then
      LDec.TargetNodes := TArray<string>.Create(AChangeSet.RejectedNodeId)
    else if AChangeSet.IntentNodeId <> '' then
      LDec.TargetNodes := TArray<string>.Create(AChangeSet.IntentNodeId)
    else
      SetLength(LDec.TargetNodes, 0);
  end
  else if AChangeSet.IntentNodeId <> '' then
    LDec.TargetNodes := TArray<string>.Create(AChangeSet.IntentNodeId)
  else
    SetLength(LDec.TargetNodes, 0);
  LDec.Rationale := ARationale;

  case AAction of
    rsAccepted:
    begin
      if AChangeSet.IsFrameRejection then
      begin
        LDec.DecisionType := dtReject;
        LDec.Status := dsAccepted;
        LTitle := 'Frame Rejection: ' + AChangeSet.RejectedNodeId;
        LDec.DecisionText := 'Frame rejected for node ' + AChangeSet.RejectedNodeId +
          ' based on intent: ' + AChangeSet.RawUserIntent;
      end
      else
      begin
        LDec.DecisionType := dtConfirm;
        LDec.Status := dsAccepted;
        LTitle := 'Accept ChangeSet: ' + AChangeSet.Id;
        LDec.DecisionText := 'Accept interpreted changes for node ' + AChangeSet.IntentNodeId +
          ' based on intent: ' + AChangeSet.RawUserIntent;
      end;
    end;
    rsRejected:
    begin
      LDec.DecisionType := dtReject;
      LDec.Status := dsRejected;
      LTitle := 'Reject ChangeSet: ' + AChangeSet.Id;
      LDec.DecisionText := 'Reject interpreted changes for node ' + AChangeSet.IntentNodeId +
        ' based on intent: ' + AChangeSet.RawUserIntent;
    end;
    rsDeferred:
    begin
      LDec.DecisionType := dtClarify;
      LDec.Status := dsProposed;
      LTitle := 'Clarify ChangeSet: ' + AChangeSet.Id;
      LDec.DecisionText := 'Request human clarification for node ' + AChangeSet.IntentNodeId +
        ' based on intent: ' + AChangeSet.RawUserIntent;
    end;
  else
    LDec.DecisionType := dtClarify;
    LDec.Status := dsProposed;
    LTitle := 'Review ChangeSet: ' + AChangeSet.Id;
    LDec.DecisionText := 'Pending review for node ' + AChangeSet.IntentNodeId;
  end;

  LDec.Title := LTitle;
  if LDec.Rationale = '' then
    LDec.Rationale := 'Human review decision for ChangeSet ' + AChangeSet.Id;

  FDecisions.Add(LDec);
  Result := LDec.Id;
  Save;
end;

function TAsWishDecisionsService.RecordDifferenceDecision(
  const AReport: TSpecDifferenceReport; const AAction: string;
  const ARationale: string; const AChangeSetId: string): string;
var
  LDec: TSpecDecision;
  LActionLower: string;
  LTargetNodes: TList<string>;
begin
  LDec := Default(TSpecDecision);
  LDec.Id := GenerateNextId;
  LDec.CreatedAt := Now;
  LDec.UpdatedAt := Now;
  LDec.DecidedBy := dbHuman;
  LDec.Confidence := clHigh;
  LDec.ChangeSetId := AChangeSetId;
  LDec.Rationale := ARationale;

  LTargetNodes := TList<string>.Create;
  try
    for var LItem in AReport.Items do
      if LItem.NodeId <> '' then
        LTargetNodes.Add(LItem.NodeId);
    LDec.TargetNodes := LTargetNodes.ToArray;
  finally
    LTargetNodes.Free;
  end;

  LActionLower := LowerCase(AAction.Trim);
  if (LActionLower = 'acceptable') or (LActionLower = 'accept') then
  begin
    LDec.DecisionType := dtAcceptDifference;
    LDec.Status := dsAccepted;
    LDec.Title := 'Accept Difference for Baseline ' + AReport.BaselineId;
    LDec.DecisionText := Format('Accept structural differences (%d items) against baseline %s',
      [Length(AReport.Items), AReport.BaselineId]);
  end
  else if (LActionLower = 'unacceptable') or (LActionLower = 'reject') then
  begin
    LDec.DecisionType := dtReject;
    LDec.Status := dsRejected;
    LDec.Title := 'Reject Difference for Baseline ' + AReport.BaselineId;
    LDec.DecisionText := Format('Reject structural differences (%d items) against baseline %s',
      [Length(AReport.Items), AReport.BaselineId]);
  end
  else
  begin
    LDec.DecisionType := dtClarify;
    LDec.Status := dsProposed;
    LDec.Title := 'Unresolved Difference for Baseline ' + AReport.BaselineId;
    LDec.DecisionText := Format('Unresolved structural differences (%d items) against baseline %s',
      [Length(AReport.Items), AReport.BaselineId]);
  end;

  FDecisions.Add(LDec);
  Save;
  Result := LDec.Id;
end;

function TAsWishDecisionsService.PromotePending: Integer;
var
  LParser: TYamlParser;
  LRoot, LSeq: TYamlNode;
  LPath, LAction, LNodeId, LNodeTitle, LDecId, LTitle: string;
  LDecType: TDecisionType;
begin
  Result := 0;
  LPath := TPath.Combine(FBasePath, 'pending-decisions.yaml');
  if not TFile.Exists(LPath) then Exit;

  LParser := TYamlParser.Create;
  try
    LRoot := LParser.ParseFile(LPath);
    if LRoot = nil then Exit;
    try
      LSeq := LRoot.GetSeq('pending_decisions');
      if LSeq = nil then Exit;

      for var I := 0 to LSeq.SeqCount - 1 do
      begin
        var LItem := LSeq.SeqItem(I);
        if LItem = nil then Continue;

        LAction := LItem.GetString('action', '');
        LNodeId := LItem.GetString('node_id', '');
        LNodeTitle := LItem.GetString('node_title', '');

        if (LNodeId = '') or
           ((LAction <> 'node-confirm') and (LAction <> 'node-reject')) then
          Continue;

        if LAction = 'node-confirm' then
        begin
          LDecType := dtConfirm;
          LTitle := 'Confirm: ' + LNodeTitle;
        end
        else
        begin
          LDecType := dtReject;
          LTitle := 'Reject: ' + LNodeTitle;
        end;

        LDecId := AddDecision(LDecType, LTitle,
          LAction + ' (target: ' + LNodeId + ')',
          'Recorded via WebView2 JS Bridge', [LNodeId]);

        if LAction = 'node-confirm' then
          AcceptDecision(LDecId)
        else
          RejectDecision(LDecId);

        Inc(Result);
      end;
    finally
      LRoot.Free;
    end;
  finally
    LParser.Free;
  end;

  // Clear pending file once promoted
  if Result > 0 then
    TFile.Delete(LPath);
end;

procedure TAsWishDecisionsService.ApplyNodeStatusTransitions(
  const ATreeRelPath: string;
  AReadTree: TFunc<string, TList<TSpecNode>>;
  AWriteTree: TProc<string, TList<TSpecNode>>);
var
  LNodes: TList<TSpecNode>;
  LChanged: Boolean;
  LError: string;
begin
  LNodes := AReadTree(ATreeRelPath);
  if LNodes = nil then Exit;
  try
    LChanged := False;
    for var I := 0 to LNodes.Count - 1 do
    begin
      var LNode := LNodes[I];

      // Find accepted/rejected decisions targeting this node (a rejected
      // decision must also apply its transitions — Reject All on bundles
      // and node-reject depend on this)
      for var LDec in FDecisions do
      begin
        if (LDec.Status <> dsAccepted) and (LDec.Status <> dsRejected) then Continue;
        var LTargetsNode := False;
        for var LT in LDec.TargetNodes do
          if LT = LNode.Id then begin LTargetsNode := True; Break; end;
        if not LTargetsNode then Continue;

        case LDec.DecisionType of
          dtConfirm:
          begin
            // Confirm: gen draft/generated → confirmed, review unreviewed → accepted
            if TSpecEnums.TryTransitionGen(LNode.GenStatus, gsConfirmed, LError) then
              LChanged := True
            else
              OutputDebugString(PChar('AsWish: ' + LError));
            if TSpecEnums.TryTransitionReview(LNode.ReviewStatus, rsAccepted, LError) then
              LChanged := True
            else
              OutputDebugString(PChar('AsWish: ' + LError));
            // Also update legacy Status
            LNode.Status := nsConfirmed;
          end;
          dtReject:
          begin
            // Reject: gen → skipped, review → rejected
            if TSpecEnums.TryTransitionGen(LNode.GenStatus, gsSkipped, LError) then
              LChanged := True
            else
              OutputDebugString(PChar('AsWish: ' + LError));
            if TSpecEnums.TryTransitionReview(LNode.ReviewStatus, rsRejected, LError) then
              LChanged := True
            else
              OutputDebugString(PChar('AsWish: ' + LError));
            LNode.Status := nsRejected;
          end;
        end;
      end;

      LNodes[I] := LNode;
    end;

    if LChanged then
      AWriteTree(ATreeRelPath, LNodes);
  finally
    LNodes.Free;
  end;
end;

procedure TAsWishDecisionsService.ApplyNodeStatusTransitions(
  const ATreeRelPath: string; ANodes: TList<TSpecNode>);
var
  LError: string;
  LIndex: TDictionary<string, TList<TSpecDecision>>;
  LDecs: TList<TSpecDecision>;
begin
  if ANodes = nil then Exit;

  // Index accepted/rejected decisions by target node id ONCE (O(M)) instead
  // of rescanning every decision for every node (O(N*M)) — multi-LLM review
  // optimization; also makes the apply pass order-independent.
  LIndex := TDictionary<string, TList<TSpecDecision>>.Create;
  try
    for var LDec in FDecisions do
    begin
      if (LDec.Status <> dsAccepted) and (LDec.Status <> dsRejected) then Continue;
      for var LT in LDec.TargetNodes do
      begin
        if not LIndex.TryGetValue(LT, LDecs) then
        begin
          LDecs := TList<TSpecDecision>.Create;
          LIndex.Add(LT, LDecs);
        end;
        LDecs.Add(LDec);
      end;
    end;

    for var I := 0 to ANodes.Count - 1 do
    begin
      var LNode := ANodes[I];
      if LIndex.TryGetValue(LNode.Id, LDecs) then
        for var LDec in LDecs do
        begin
          case LDec.DecisionType of
            dtConfirm:
            begin
              TSpecEnums.TryTransitionGen(LNode.GenStatus, gsConfirmed, LError);
              TSpecEnums.TryTransitionReview(LNode.ReviewStatus, rsAccepted, LError);
              LNode.Status := nsConfirmed;
            end;
            dtReject:
            begin
              TSpecEnums.TryTransitionGen(LNode.GenStatus, gsSkipped, LError);
              TSpecEnums.TryTransitionReview(LNode.ReviewStatus, rsRejected, LError);
              LNode.Status := nsRejected;
            end;
          end;
        end;
      ANodes[I] := LNode;
    end;
  finally
    for var LList in LIndex.Values do
      LList.Free;
    LIndex.Free;
  end;
end;

end.
