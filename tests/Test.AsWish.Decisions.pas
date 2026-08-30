{ ============================================================================
  Test.AsWish.Decisions

  DUnitX tests for AsWish.Services.Decisions — decision persistence and
  state-machine application. Includes the bugfix #15 regression: rejected
  decisions must apply dtReject transitions (previously only dsAccepted
  decisions were applied, so Reject All / node-reject changed nothing).
  ============================================================================ }

unit Test.AsWish.Decisions;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestAsWishDecisions = class
  public
    [Test]
    procedure Test_AddDecision_RoundTrip;
    [Test]
    procedure Test_ApplyAcceptedDecision_Transitions;
    [Test]
    procedure Test_ApplyRejectedDecision_Transitions;
    [Test]
    procedure Test_NoTransitionForProposedDecision;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.Decisions;

function NewTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

{ TTestAsWishDecisions }

procedure TTestAsWishDecisions.Test_AddDecision_RoundTrip;
var
  LDir: string;
  LDecisions: TAsWishDecisionsService;
  LDecId, LFoundId: string;
  LFound: TSpecDecision;
begin
  LDir := NewTempDir;
  LDecisions := TAsWishDecisionsService.Create;
  try
    LDecisions.Initialize(LDir);
    LDecisions.Load;
    LDecId := LDecisions.AddDecision(dtConfirm, 'Roundtrip decision',
      'confirm func-1', 'test rationale', ['func-1']);

    // Save wrote through AtomicWriteTextFile; a fresh instance must see it.
    LDecisions.Free;
    LDecisions := TAsWishDecisionsService.Create;
    LDecisions.Initialize(LDir);
    LDecisions.Load;

    LFound := LDecisions.FindById(LDecId);
    LFoundId := LFound.Id;
    Assert.IsNotEmpty(LFoundId, 'decision should survive Save/Load round trip');
    Assert.AreEqual<Integer>(Ord(dtConfirm), Ord(LFound.DecisionType));
    Assert.AreEqual<Integer>(1, Length(LFound.TargetNodes));
    Assert.AreEqual('func-1', LFound.TargetNodes[0]);
  finally
    LDecisions.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishDecisions.Test_ApplyAcceptedDecision_Transitions;
var
  LDir: string;
  LDecisions: TAsWishDecisionsService;
  LNodes: TList<TSpecNode>;
  LNode: TSpecNode;
  LDecId: string;
begin
  LDir := NewTempDir;
  LDecisions := TAsWishDecisionsService.Create;
  try
    LDecisions.Initialize(LDir);
    LDecisions.Load;
    LNodes := TList<TSpecNode>.Create;
    try
      LNode := TSpecNode.MakeNew('func-1', ttFunction, 'F1', 'feature');
      // Real-world path: CandidateIngest merges nodes as gsGenerated, then a
      // human confirms (draft -> confirmed directly is not a legal
      // transition in the state machine).
      LNode.GenStatus := gsGenerated;
      LNode.ReviewStatus := rsUnreviewed;
      LNodes.Add(LNode);

      LDecId := LDecisions.AddDecision(dtConfirm, 'Confirm F1',
        'ok', 'test', ['func-1']);
      LDecisions.AcceptDecision(LDecId);
      LDecisions.ApplyNodeStatusTransitions('trees/function-tree.yaml', LNodes);

      Assert.AreEqual(gsConfirmed, LNodes[0].GenStatus,
        'accepted confirm decision should move gen_status to confirmed');
      Assert.AreEqual(rsAccepted, LNodes[0].ReviewStatus,
        'accepted confirm decision should move review_status to accepted');
    finally
      LNodes.Free;
    end;
  finally
    LDecisions.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishDecisions.Test_ApplyRejectedDecision_Transitions;
var
  LDir: string;
  LDecisions: TAsWishDecisionsService;
  LNodes: TList<TSpecNode>;
  LNode: TSpecNode;
  LDecId: string;
begin
  LDir := NewTempDir;
  LDecisions := TAsWishDecisionsService.Create;
  try
    LDecisions.Initialize(LDir);
    LDecisions.Load;
    LNodes := TList<TSpecNode>.Create;
    try
      LNode := TSpecNode.MakeNew('func-1', ttFunction, 'F1', 'feature');
      LNode.GenStatus := gsGenerated;
      LNode.ReviewStatus := rsUnreviewed;
      LNodes.Add(LNode);

      LDecId := LDecisions.AddDecision(dtReject, 'Reject F1',
        'not needed', 'test', ['func-1']);
      LDecisions.RejectDecision(LDecId);
      LDecisions.ApplyNodeStatusTransitions('trees/function-tree.yaml', LNodes);

      // bugfix #15 regression: dsRejected decisions must apply transitions.
      // Before the fix, the guard `Status <> dsAccepted then Continue` made
      // the dtReject branch unreachable — Reject All / node-reject no-ops.
      Assert.AreEqual(gsSkipped, LNodes[0].GenStatus,
        'rejected decision should move gen_status to skipped');
      Assert.AreEqual(rsRejected, LNodes[0].ReviewStatus,
        'rejected decision should move review_status to rejected');
    finally
      LNodes.Free;
    end;
  finally
    LDecisions.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishDecisions.Test_NoTransitionForProposedDecision;
var
  LDir: string;
  LDecisions: TAsWishDecisionsService;
  LNodes: TList<TSpecNode>;
  LNode: TSpecNode;
begin
  LDir := NewTempDir;
  LDecisions := TAsWishDecisionsService.Create;
  try
    LDecisions.Initialize(LDir);
    LDecisions.Load;
    LNodes := TList<TSpecNode>.Create;
    try
      LNode := TSpecNode.MakeNew('func-1', ttFunction, 'F1', 'feature');
      LNode.GenStatus := gsDraft;
      LNode.ReviewStatus := rsUnreviewed;
      LNodes.Add(LNode);

      // dsProposed decision (freshly added, not accepted/rejected yet) must
      // NOT apply transitions.
      LDecisions.AddDecision(dtConfirm, 'Pending confirm', 'later', 'test',
        ['func-1']);
      LDecisions.ApplyNodeStatusTransitions('trees/function-tree.yaml', LNodes);

      Assert.AreEqual(gsDraft, LNodes[0].GenStatus,
        'proposed decision must not transition nodes');
      Assert.AreEqual(rsUnreviewed, LNodes[0].ReviewStatus);
    finally
      LNodes.Free;
    end;
  finally
    LDecisions.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishDecisions);

end.
