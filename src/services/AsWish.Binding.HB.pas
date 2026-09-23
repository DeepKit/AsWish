{ ============================================================================
  AsWish.Binding.HB - EHAI Reference Product Binding 001
  
  Formal Lineage:
    EHAI
    -> Language Common Contract
    -> DeepBase Delphi Implementation
    -> HB (Human-in-the-loop Bridge)
    -> AsWish Domain Binding (Reference Product Binding 001)

  Public Symbol Baseline Registration (AW-R01):
    - Baseline Version: EHAI-DELPHI-SYMBOL-BASELINE-v1.0
    - Baseline Document: DeepBase\docs\EHAI-Delphi-Symbol-Baseline.md
    - Generation Timestamp: 2026-09-14 09:50:00 +08:00
    - Source Fingerprints (SHA256 SSOT):
      * Core/DeepBase.EHAI.Types.pas:
        de9a32082dbf86ff1943c33677a89746eae187f646c116fd465dda9cbb2d0799
      * Core/DeepBase.HB.Choice.Types.pas:
        963fedd0ea91402085391af2b9ed69fa137c23ffd46b340bfe8996dd059ee79e

  Contract Compliance:
    - AsWish does not re-define public interaction semantics (0-9, HumanOverride,
      FrameRejection, Regenerate, Back).
    - CandidateSelection != Inherent Commitment (1..7 is exploratory review).
    - Regenerate (8) is non-committing candidate exploration within frame.
    - HumanOverride / FrameRejection (9) tri-state:
      * eokCandidateReject: reject candidates within frame
      * eokAlternativeExpression: custom expression within frame
      * eokFrameRejection: reject problem framing, refute premise (FR-AW-01)
    - BackNavigation (0) exit without commitment != Reject != Consent != Judgment.
    - Commitment Gate: AcceptChangeSet is AsWish product-specific commitment gate,
      crossing CommitmentBoundary into Canonical Spec mutation and Baseline freeze.
  ============================================================================ }

unit AsWish.Binding.HB;

{ IMPLICIT_STRING_CAST OFF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DeepBase.EHAI.Types,
  DeepBase.HB.Choice.Types,
  AsWish.Models,
  AsWish.Controller;

type
  /// <summary>
  /// AsWish Reference Product Binding 001 for EHAI / HB.
  /// Decouples generic interaction grammar from AsWish domain models.
  /// </summary>
  TAsWishHBBinding = class(TObject)
  private
    FController: TAsWishController;
    FTraces: TList<TEhaiTraceRecord>;
    FLastChangeSetId: string;
    FLastEffect: TEhaiSemanticEffectKind;
    FIsLastActionCommitted: Boolean;
    FLastReviewText: string;
    FTraceSeq: Integer;
    function TreeFromNodePrefix(const ANodeId: string): TTreeType;
    function NextTraceId: string;
    function RecordTrace(const AAction: TEhaiInteractionAction;
      AEffect: TEhaiSemanticEffectKind; ACommitted: Boolean;
      const AActor: string = 'human'): TEhaiTraceRecord;
  public
    constructor Create(AController: TAsWishController);
    destructor Destroy; override;

    /// <summary>
    /// Process a standard HB 0-9 Choice Deck action.
    /// Maps 1..7 (Candidate), 8 (Regenerate), 9 (Override/Frame Rejection), 0 (Back).
    /// Exploration effects only - does NOT commit Canonical Spec.
    /// </summary>
    function ProcessHbAction(const AAction: THbChoiceAction;
      const AChangeSetId: string = ''): TEhaiTraceRecord;

    /// <summary>
    /// Process a language-neutral EHAI interaction action.
    /// Exploration effects only - does NOT commit Canonical Spec.
    /// </summary>
    function ProcessEhaiAction(const AAction: TEhaiInteractionAction;
      const AChangeSetId: string = ''): TEhaiTraceRecord;

    /// <summary>
    /// Formal Product-Specific Commitment Gate (AcceptChangeSet).
    /// Crosses CommitmentBoundary: mutates Canonical Spec and freezes immutable Baseline.
    /// </summary>
    function ExecuteCommitmentGate(const AChangeSetId: string;
      const ARationale: string = ''): Boolean;

    /// <summary>
    /// Formal Rejection of ChangeSet.
    /// Records dtReject / dsRejected decision; leaves Canonical Spec untouched.
    /// </summary>
    function ExecuteReject(const AChangeSetId: string;
      const ARationale: string = ''): Boolean;

    /// <summary>Get all recorded audit trace records in order.</summary>
    function GetTraces: TArray<TEhaiTraceRecord>;

    /// <summary>Clear audit trace history.</summary>
    procedure ClearTraces;

    function GetTraceCount: Integer;
    property Controller: TAsWishController read FController;
    property LastChangeSetId: string read FLastChangeSetId;
    property LastEffect: TEhaiSemanticEffectKind read FLastEffect;
    /// <summary>WO-0039 B-5: review summary produced by the last candidate
    /// exploration (key 1..7), for the deck status line.</summary>
    property LastReviewText: string read FLastReviewText;
    property IsLastActionCommitted: Boolean read FIsLastActionCommitted;
    property TraceCount: Integer read GetTraceCount;
  end;

implementation

{ TAsWishHBBinding }

constructor TAsWishHBBinding.Create(AController: TAsWishController);
begin
  inherited Create;
  FController := AController;
  FTraces := TList<TEhaiTraceRecord>.Create;
  FLastChangeSetId := '';
  FLastEffect := eseInformOnly;
  FIsLastActionCommitted := False;
  FTraceSeq := 0;
end;

destructor TAsWishHBBinding.Destroy;
begin
  FTraces.Free;
  inherited Destroy;
end;

function TAsWishHBBinding.GetTraceCount: Integer;
begin
  Result := FTraces.Count;
end;

// WO-0039 B-5: node-id prefix carries the tree (same convention as
// TAsWishCandidateIngest.ComputeAffectedProjections); unknown prefix keeps
// the historical ttFunction default.
function TAsWishHBBinding.TreeFromNodePrefix(const ANodeId: string): TTreeType;
begin
  if ANodeId.StartsWith('func-') then Exit(ttFunction);
  if ANodeId.StartsWith('mod-') then Exit(ttModule);
  if ANodeId.StartsWith('view-') then Exit(ttView);
  if ANodeId.StartsWith('data-') then Exit(ttData);
  Result := ttFunction;
end;

function TAsWishHBBinding.NextTraceId: string;
begin
  Inc(FTraceSeq);
  Result := Format('trace-aw001-%s-%.4d', [FormatDateTime('yyyymmdd', Now), FTraceSeq]);
end;

function TAsWishHBBinding.RecordTrace(const AAction: TEhaiInteractionAction;
  AEffect: TEhaiSemanticEffectKind; ACommitted: Boolean;
  const AActor: string): TEhaiTraceRecord;
begin
  Result := TEhaiTraceRecord.Create(NextTraceId, AActor, AAction, AEffect, ACommitted);
  FTraces.Add(Result);
  FLastEffect := AEffect;
  FIsLastActionCommitted := ACommitted;
end;

function TAsWishHBBinding.ProcessHbAction(const AAction: THbChoiceAction;
  const AChangeSetId: string): TEhaiTraceRecord;
var
  LEhaiAction: TEhaiInteractionAction;
  LContext: TEhaiContextBinding;
begin
  LContext := TEhaiContextBinding.Create(AAction.ContextId, 'HB Choice Context',
    'User interaction via HB Choice Deck', AAction.ContextId, 'AsWish', 'human');

  case AAction.Kind of
    cakCandidate:
      LEhaiAction := TEhaiInteractionAction.CreateCandidate(AAction.Key, AAction.Text,
        eipJudge, LContext, AAction.Payload, AAction.Source);
    cakRegenerate:
      LEhaiAction := TEhaiInteractionAction.CreateRegenerate(eipProvide, LContext, AAction.Payload, AAction.Source);
    cakFreeInput:
      LEhaiAction := TEhaiInteractionAction.CreateOverride(AAction.OverrideKind, AAction.Text,
        eipProvide, LContext, AAction.Payload, AAction.Source);
    cakBack:
      LEhaiAction := TEhaiInteractionAction.CreateExit(eipInform, LContext, AAction.Payload, AAction.Source);
  else
    LEhaiAction := TEhaiInteractionAction.CreateCandidate(AAction.Key, AAction.Text,
      eipJudge, LContext, AAction.Payload, AAction.Source);
  end;

  Result := ProcessEhaiAction(LEhaiAction, AChangeSetId);
end;

function TAsWishHBBinding.ProcessEhaiAction(const AAction: TEhaiInteractionAction;
  const AChangeSetId: string): TEhaiTraceRecord;
var
  LTargetCsId: string;
  LReviewText: string;
  LSubmittedCsId: string;
begin
  LTargetCsId := AChangeSetId;
  if (LTargetCsId = '') and (FLastChangeSetId <> '') then
    LTargetCsId := FLastChangeSetId;

  case AAction.MetaAction of
    emaChoose:
    begin
      // 1..7: Candidate Selection Exploration (CandidateSelection != Inherent Commitment)
      // Presents / reviews ChangeSet for human valuation, without mutating Canonical Spec.
      if FController <> nil then
      begin
        LReviewText := FController.ReviewChangeSet(LTargetCsId);
        FLastReviewText := LReviewText;
        if LTargetCsId <> '' then
          FLastChangeSetId := LTargetCsId;
      end;
      Result := RecordTrace(AAction, eseJudgmentMade, False);
    end;

    emaRegenerate:
    begin
      // 8: Regenerate within current frame (8 != Judgment, pure exploration)
      if FController <> nil then
        FController.ExportPrompt;
      Result := RecordTrace(AAction, eseInformOnly, False);
    end;

    emaReframe:
    begin
      // 9: Human Override / Frame Rejection
      if AAction.OverrideKind = eokFrameRejection then
      begin
        // Sub-kind 3: Frame Rejection (FR-AW-01)
        // Explicitly refutes the framing of the current node, captures higher-level intent
        if FController <> nil then
        begin
          LSubmittedCsId := FController.SubmitFrameRejection(
            AAction.Context.ObservableObjectRef,               // Rejected Node
            TreeFromNodePrefix(AAction.Context.ObservableObjectRef), // Rejected Tree (WO-0039 B-5: infer, no module hardcode)
            AAction.Text,                                      // Human reframe intent
            ttFunction                                         // Upstream requirement tree (by design)
          );
          FLastChangeSetId := LSubmittedCsId;
        end;
        Result := RecordTrace(AAction, eseDataProvided, False);
      end
      else
      begin
        // Sub-kind 1 & 2: Candidate Rejection or Alternative Expression within frame
        if FController <> nil then
        begin
          if AAction.Context.ObservableObjectRef <> '' then
            LSubmittedCsId := FController.SubmitUserIntent(
              AAction.Context.ObservableObjectRef,
              TreeFromNodePrefix(AAction.Context.ObservableObjectRef), // WO-0039 B-5
              AAction.Text
            )
          else
            LSubmittedCsId := FController.SubmitUserIntent(AAction.Text, ttFunction);
          FLastChangeSetId := LSubmittedCsId;
        end;
        Result := RecordTrace(AAction, eseDataProvided, False);
      end;
    end;

    emaExit:
    begin
      // 0: BackNavigation (Exit without commitment != Reject != Consent != Judgment)
      // Strictly does NOT revoke prior decisions or alter Canonical Spec
      Result := RecordTrace(AAction, eseInformOnly, False);
    end;
  else
    Result := RecordTrace(AAction, eseInformOnly, False);
  end;
end;

function TAsWishHBBinding.ExecuteCommitmentGate(const AChangeSetId: string;
  const ARationale: string): Boolean;
var
  LContext: TEhaiContextBinding;
  LAction: TEhaiInteractionAction;
begin
  Result := False;
  // Gate C invariant: reject empty or wildcard identifiers (fail-closed)
  if (FController = nil) or (AChangeSetId.Trim = '') or (AChangeSetId = '*') then Exit;

  // Crosses Commitment Boundary: AcceptChangeSet mutates trees & freezes Baseline
  Result := FController.AcceptChangeSet(AChangeSetId, ARationale);
  if Result then
  begin
    FLastChangeSetId := AChangeSetId;
    LContext := TEhaiContextBinding.Create(AChangeSetId, 'Commitment Gate Context',
      'Commitment Gate crossing', AChangeSetId, 'AsWish', 'human');
    LAction := TEhaiInteractionAction.CreateCandidate(1, 'Accept ChangeSet: ' + AChangeSetId,
      eipAuthorize, LContext, 0, esHuman);
    RecordTrace(LAction, eseAuthorized, True);
    // WO-0039 B-2: commitment closes the exploration cycle; the deck must not
    // keep a live CsId that Enter/Esc/button clicks would re-fire.
    FLastChangeSetId := '';
  end;
end;

function TAsWishHBBinding.ExecuteReject(const AChangeSetId: string;
  const ARationale: string): Boolean;
var
  LContext: TEhaiContextBinding;
  LAction: TEhaiInteractionAction;
begin
  Result := False;
  // Gate C invariant: reject empty or wildcard identifiers (fail-closed)
  if (FController = nil) or (AChangeSetId.Trim = '') or (AChangeSetId = '*') then Exit;

  Result := FController.RejectChangeSet(AChangeSetId, ARationale);
  if Result then
  begin
    FLastChangeSetId := AChangeSetId;
    LContext := TEhaiContextBinding.Create(AChangeSetId, 'Rejection Context',
      'ChangeSet Rejection', AChangeSetId, 'AsWish', 'human');
    LAction := TEhaiInteractionAction.CreateCandidate(0, 'Reject ChangeSet: ' + AChangeSetId,
      eipJudge, LContext, 0, esHuman);
    RecordTrace(LAction, eseJudgmentMade, False);
    // WO-0039 B-2: rejection also closes the cycle (Spec untouched, deck Idle).
    FLastChangeSetId := '';
  end;
end;

function TAsWishHBBinding.GetTraces: TArray<TEhaiTraceRecord>;
begin
  Result := FTraces.ToArray;
end;

procedure TAsWishHBBinding.ClearTraces;
begin
  FTraces.Clear;
  FLastEffect := eseInformOnly;
  FIsLastActionCommitted := False;
end;

end.
