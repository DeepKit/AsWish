{ ============================================================================
  Test.DeepSpec.Models

  DUnitX tests for DeepSpec.Models state machines and enum round-trips.
  Focus: CanTransitionFog one-way convergence (the core of the Fog model).
  ============================================================================ }

unit Test.DeepSpec.Models;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DeepSpec.Models;

type
  [TestFixture]
  TFogStateMachineTests = class
  public
    // Convergence direction: unknown_unknowns -> foggy -> misty -> clear
    [Test]
    procedure SameState_IsAlwaysAllowed;

    [Test]
    procedure UnknownUnknowns_ToFoggy_Allowed;
    [Test]
    procedure Foggy_ToMisty_Allowed;
    [Test]
    procedure Misty_ToClear_Allowed;

    [Test]
    procedure UnknownUnknowns_ToClear_Allowed_SkipsLevels;
    [Test]
    procedure UnknownUnknowns_ToMisty_Allowed_SkipsLevel;
    [Test]
    procedure Foggy_ToClear_Allowed_SkipsLevel;

    [Test]
    procedure Clear_ToAnything_Forbidden_Terminal;
    [Test]
    procedure Misty_ToFoggy_Forbidden_ReverseDivergence;
    [Test]
    procedure Foggy_ToUnknownUnknowns_Forbidden_ReverseDivergence;
    [Test]
    procedure Misty_ToUnknownUnknowns_Forbidden_ReverseDivergence;
  end;

  [TestFixture]
  TFogStateRoundTripTests = class
  public
    [Test]
    procedure FogStateToStr_FromStr_RoundTrip_AllFourStates;
    [Test]
    procedure FogStateFromStr_UnknownValue_ReturnsDefault;
  end;

  [TestFixture]
  TDefogOneStepTests = class
  public
    [Test]
    procedure UnknownUnknowns_StepToFoggy;
    [Test]
    procedure Foggy_StepToMisty;
    [Test]
    procedure Misty_StepToClear;
    [Test]
    procedure Clear_Step_StaysClear;
  end;

  [TestFixture]
  THealthMetricsTests = class
  public
    [Test]
    procedure Coverage_Partial;
    [Test]
    procedure AvgConfidence_Mixed;
    [Test]
    procedure FogCount_AcrossTrees;
    [Test]
    procedure Backlog_OpenOnly;
  end;

implementation

uses
  System.Generics.Collections,
  DeepSpec.Services.Render;   // TDeepSpecRenderService.ComputeHealthMetrics / THealthMetrics

{ TFogStateMachineTests }

procedure TFogStateMachineTests.SameState_IsAlwaysAllowed;
begin
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsClear, fsClear),
    'clear->clear no-op must be allowed');
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsMisty, fsMisty),
    'misty->misty no-op must be allowed');
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsFoggy, fsFoggy),
    'foggy->foggy no-op must be allowed');
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsUnknownUnknowns, fsUnknownUnknowns),
    'unknown_unknowns->unknown_unknowns no-op must be allowed');
end;

procedure TFogStateMachineTests.UnknownUnknowns_ToFoggy_Allowed;
begin
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsUnknownUnknowns, fsFoggy),
    'unknown_unknowns->foggy is a legal convergence step');
end;

procedure TFogStateMachineTests.Foggy_ToMisty_Allowed;
begin
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsFoggy, fsMisty),
    'foggy->misty is a legal convergence step');
end;

procedure TFogStateMachineTests.Misty_ToClear_Allowed;
begin
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsMisty, fsClear),
    'misty->clear is a legal convergence step');
end;

procedure TFogStateMachineTests.UnknownUnknowns_ToClear_Allowed_SkipsLevels;
begin
  // Convergence may jump levels in one step (e.g. a single decision clears the fog).
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsUnknownUnknowns, fsClear),
    'unknown_unknowns->clear must be allowed (skip-level convergence)');
end;

procedure TFogStateMachineTests.UnknownUnknowns_ToMisty_Allowed_SkipsLevel;
begin
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsUnknownUnknowns, fsMisty),
    'unknown_unknowns->misty must be allowed (skip foggy)');
end;

procedure TFogStateMachineTests.Foggy_ToClear_Allowed_SkipsLevel;
begin
  Assert.IsTrue(TSpecEnums.CanTransitionFog(fsFoggy, fsClear),
    'foggy->clear must be allowed (skip misty)');
end;

procedure TFogStateMachineTests.Clear_ToAnything_Forbidden_Terminal;
begin
  // clear is the terminal state — no divergence allowed.
  Assert.IsFalse(TSpecEnums.CanTransitionFog(fsClear, fsMisty),
    'clear->misty must be forbidden (clear is terminal)');
  Assert.IsFalse(TSpecEnums.CanTransitionFog(fsClear, fsFoggy),
    'clear->foggy must be forbidden (clear is terminal)');
  Assert.IsFalse(TSpecEnums.CanTransitionFog(fsClear, fsUnknownUnknowns),
    'clear->unknown_unknowns must be forbidden (clear is terminal)');
end;

procedure TFogStateMachineTests.Misty_ToFoggy_Forbidden_ReverseDivergence;
begin
  Assert.IsFalse(TSpecEnums.CanTransitionFog(fsMisty, fsFoggy),
    'misty->foggy must be forbidden (reverse divergence)');
end;

procedure TFogStateMachineTests.Foggy_ToUnknownUnknowns_Forbidden_ReverseDivergence;
begin
  Assert.IsFalse(TSpecEnums.CanTransitionFog(fsFoggy, fsUnknownUnknowns),
    'foggy->unknown_unknowns must be forbidden (reverse divergence)');
end;

procedure TFogStateMachineTests.Misty_ToUnknownUnknowns_Forbidden_ReverseDivergence;
begin
  Assert.IsFalse(TSpecEnums.CanTransitionFog(fsMisty, fsUnknownUnknowns),
    'misty->unknown_unknowns must be forbidden (reverse divergence)');
end;

{ TFogStateRoundTripTests }

procedure TFogStateRoundTripTests.FogStateToStr_FromStr_RoundTrip_AllFourStates;
begin
  Assert.AreEqual<string>('clear',            TSpecEnums.FogStateToStr(fsClear));
  Assert.AreEqual<string>('misty',            TSpecEnums.FogStateToStr(fsMisty));
  Assert.AreEqual<string>('foggy',            TSpecEnums.FogStateToStr(fsFoggy));
  Assert.AreEqual<string>('unknown_unknowns', TSpecEnums.FogStateToStr(fsUnknownUnknowns));

  Assert.AreEqual<TFogState>(fsClear,           TSpecEnums.FogStateFromStr('clear', fsClear));
  Assert.AreEqual<TFogState>(fsMisty,           TSpecEnums.FogStateFromStr('misty', fsClear));
  Assert.AreEqual<TFogState>(fsFoggy,           TSpecEnums.FogStateFromStr('foggy', fsClear));
  Assert.AreEqual<TFogState>(fsUnknownUnknowns, TSpecEnums.FogStateFromStr('unknown_unknowns', fsClear));

  // Case-insensitive + whitespace-tolerant
  Assert.AreEqual<TFogState>(fsFoggy, TSpecEnums.FogStateFromStr('  FOGGY  ', fsClear));
  Assert.AreEqual<TFogState>(fsMisty, TSpecEnums.FogStateFromStr('MISTY', fsClear));
end;

procedure TFogStateRoundTripTests.FogStateFromStr_UnknownValue_ReturnsDefault;
begin
  Assert.AreEqual<TFogState>(fsClear,           TSpecEnums.FogStateFromStr('blurry', fsClear),
    'unknown value should fall back to default');
  Assert.AreEqual<TFogState>(fsUnknownUnknowns, TSpecEnums.FogStateFromStr('', fsUnknownUnknowns),
    'empty value should fall back to default');
  Assert.AreEqual<TFogState>(fsMisty,           TSpecEnums.FogStateFromStr('nonsense', fsMisty),
    'garbage value should fall back to default');
end;

{ TDefogOneStepTests }

procedure TDefogOneStepTests.UnknownUnknowns_StepToFoggy;
begin
  Assert.AreEqual<TFogState>(fsFoggy,
    TSpecEnums.DefogOneStep(fsUnknownUnknowns),
    'unknown_unknowns defogs one step to foggy');
end;

procedure TDefogOneStepTests.Foggy_StepToMisty;
begin
  Assert.AreEqual<TFogState>(fsMisty,
    TSpecEnums.DefogOneStep(fsFoggy),
    'foggy defogs one step to misty');
end;

procedure TDefogOneStepTests.Misty_StepToClear;
begin
  Assert.AreEqual<TFogState>(fsClear,
    TSpecEnums.DefogOneStep(fsMisty),
    'misty defogs one step to clear');
end;

procedure TDefogOneStepTests.Clear_Step_StaysClear;
begin
  Assert.AreEqual<TFogState>(fsClear,
    TSpecEnums.DefogOneStep(fsClear),
    'clear is terminal -- defog stays at clear');
end;

{ THealthMetricsTests — BUG-9 health metrics (pure function) }

procedure THealthMetricsTests.Coverage_Partial;
var
  LList, LEmpty: TList<TSpecNode>;
  LM: THealthMetrics;
  LN: TSpecNode;
begin
  LList := TList<TSpecNode>.Create;
  LEmpty := TList<TSpecNode>.Create;
  try
    // 2 confirmed + 1 candidate => coverage 2/3
    LN := Default(TSpecNode); LN.Id := 'f1'; LN.Title := 'A'; LN.Confidence := clHigh;
    LN.GenStatus := gsConfirmed; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'f2'; LN.Title := 'B'; LN.Confidence := clHigh;
    LN.GenStatus := gsConfirmed; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'f3'; LN.Title := 'C'; LN.Confidence := clMedium;
    LN.GenStatus := gsGenerated; LList.Add(LN);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LList, LEmpty, LEmpty, LEmpty);
    Assert.AreEqual(3, LM.TotalNodes);
    Assert.AreEqual(2, LM.ConfirmedNodes);
    Assert.AreEqual(Double(66.666), Double(LM.CoveragePct), 1.0);  // ~66.7%
  finally
    LList.Free; LEmpty.Free;
  end;
end;

procedure THealthMetricsTests.AvgConfidence_Mixed;
var
  LList, LEmpty: TList<TSpecNode>;
  LM: THealthMetrics;
  LN: TSpecNode;
begin
  LList := TList<TSpecNode>.Create;
  LEmpty := TList<TSpecNode>.Create;
  try
    // low(0.3) + medium(0.7) + high(1.0) => avg 0.6667
    LN := Default(TSpecNode); LN.Id := 'a'; LN.Confidence := clLow; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'b'; LN.Confidence := clMedium; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'c'; LN.Confidence := clHigh; LList.Add(LN);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LList, LEmpty, LEmpty, LEmpty);
    Assert.AreEqual(Double(0.6667), LM.AvgConfidence, 0.01);
  finally
    LList.Free; LEmpty.Free;
  end;
end;

procedure THealthMetricsTests.FogCount_AcrossTrees;
var
  LF, LMd, LV, LD: TList<TSpecNode>;
  LM: THealthMetrics;
  LN: TSpecNode;
begin
  LF := TList<TSpecNode>.Create; LMd := TList<TSpecNode>.Create;
  LV := TList<TSpecNode>.Create;  LD := TList<TSpecNode>.Create;
  try
    // function: 1 foggy + 1 clear ; module: 1 unknown_unknowns ; view: empty(clear) ; data: 1 misty
    LN := Default(TSpecNode); LN.Id := 'f1'; LN.HasFogState := True; LN.FogState := fsFoggy; LF.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'f2'; LN.HasFogState := False; LN.FogState := fsClear; LF.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'm1'; LN.HasFogState := True; LN.FogState := fsUnknownUnknowns; LMd.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'd1'; LN.HasFogState := True; LN.FogState := fsMisty; LD.Add(LN);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LF, LMd, LV, LD);
    Assert.AreEqual(3, LM.FogCount);  // foggy + unknown_unknowns + misty
  finally
    LF.Free; LMd.Free; LV.Free; LD.Free;
  end;
end;

procedure THealthMetricsTests.Backlog_OpenOnly;
var
  LNodes, LEmpty: TList<TSpecNode>;
  LIssues: TList<TSpecIssue>;
  LM: THealthMetrics;
  LN: TSpecNode;
  LI: TSpecIssue;
begin
  LNodes := TList<TSpecNode>.Create; LEmpty := TList<TSpecNode>.Create;
  LIssues := TList<TSpecIssue>.Create;
  try
    LN := Default(TSpecNode); LN.Id := 'x'; LN.Confidence := clHigh; LN.GenStatus := gsConfirmed;
    LNodes.Add(LN);
    // 2 open + 1 resolved => backlog 2 ; 1 open high => HighRiskOpen 1
    LI := Default(TSpecIssue); LI.Id := 'i1'; LI.Status := issOpen; LI.Severity := isHigh;
    LIssues.Add(LI);
    LI := Default(TSpecIssue); LI.Id := 'i2'; LI.Status := issOpen; LI.Severity := isLow;
    LIssues.Add(LI);
    LI := Default(TSpecIssue); LI.Id := 'i3'; LI.Status := issResolved; LI.Severity := isCritical;
    LIssues.Add(LI);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LNodes, LEmpty, LEmpty, LEmpty, LIssues);
    Assert.AreEqual(2, LM.DecisionBacklog);
    Assert.AreEqual(1, LM.HighRiskOpen);
  finally
    LNodes.Free; LEmpty.Free; LIssues.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFogStateMachineTests);
  TDUnitX.RegisterTestFixture(TFogStateRoundTripTests);
  TDUnitX.RegisterTestFixture(TDefogOneStepTests);
  TDUnitX.RegisterTestFixture(THealthMetricsTests);

end.
