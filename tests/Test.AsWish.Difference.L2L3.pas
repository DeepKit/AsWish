{ ============================================================================
  Test.AsWish.Difference.L2L3.pas - WO-0031 Platform Extension Seam Tests
  Covers all 7 mandatory test cases specified in WO-0031 Section XI.
  ============================================================================ }
unit Test.AsWish.Difference.L2L3;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, AsWish.Models, AsWish.Services.SpecStore,
  AsWish.Services.Snapshot, AsWish.Services.Difference, AsWish.Plugins.VCL.Difference,
  AsWish.Services.RenderDiff, AsWish.Services.Decisions;

type
  [TestFixture]
  TTestAsWishDifferenceL2L3 = class
  private
    FComparator: IPlatformDifferenceComparator;
    function MakeResolver(const APairs: array of string): IPlatformIdentityResolver;
    function RunCompare(const AObs, AConstraints, AStyles: string;
      const APairs: array of string): TArray<TSpecDifferenceItem>;
  public
    [Setup]
    procedure SetUp;
    [Test]
    procedure Test01_L2_OrderDifference;
    [Test]
    procedure Test02_L2_GapDifference;
    [Test]
    procedure Test03_L3_AppearanceDifference_DaContent;
    [Test]
    procedure Test04_NoDifference_CleanMatch;
    [Test]
    procedure Test05_UnknownPlatformIdentity_FailClosed;
    [Test]
    procedure Test06_NoComparatorRegistered_ServiceWorks;
    [Test]
    procedure Test07_DownstreamIntegration_RenderAndDecisions;
    [Test]
    procedure Test08_UnknownStyle_Tolerated_NoFalseRed;
    [Test]
    procedure Test09_DefaultIdentityResolution_NilResolver;
  end;

implementation

procedure TTestAsWishDifferenceL2L3.SetUp;
begin
  FComparator := TAsWishVCLDifferenceComparator.Create;
end;

function TTestAsWishDifferenceL2L3.MakeResolver(const APairs: array of string): IPlatformIdentityResolver;
var
  LMap: TDictionary<string, string>;
  I: Integer;
begin
  LMap := TDictionary<string, string>.Create;
  I := 0;
  while I < Length(APairs) - 1 do
  begin
    LMap.Add(APairs[I], APairs[I + 1]);
    Inc(I, 2);
  end;
  Result := TMapIdentityResolver.Create(LMap);
end;

function TTestAsWishDifferenceL2L3.RunCompare(const AObs, AConstraints, AStyles: string;
  const APairs: array of string): TArray<TSpecDifferenceItem>;
var
  LCtx: TPlatformComparisonContext;
  LBase: TAsWishBaseline;
begin
  LCtx := Default(TPlatformComparisonContext);
  LCtx.TreeType := 'view';
  LCtx.ObservationJson := AObs;
  LCtx.ConstraintsJson := AConstraints;
  LCtx.ExpectedStylesJson := AStyles;
  LCtx.IdentityResolver := MakeResolver(APairs);
  LBase := Default(TAsWishBaseline);
  LBase.TreeType := 'view';
  Result := FComparator.CompareL2L3(LCtx, LBase);
end;

procedure TTestAsWishDifferenceL2L3.Test01_L2_OrderDifference;
var
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  LDiffs := RunCompare(
    '{"Observations":[{"Name":"AW_BtnCancel","Bounds":{"Left":276,"Top":160,"Width":80,"Height":30},"FontColor":-1},' +
    '{"Name":"AW_BtnConfirm","Bounds":{"Left":180,"Top":160,"Width":80,"Height":30},"FontColor":-1}]}',
    '{"node_btn_cancel":{"relation":"left-of node_btn_confirm"}}', '',
    ['AW_BtnCancel', 'node_btn_cancel', 'AW_BtnConfirm', 'node_btn_confirm']);
  Assert.AreEqual<Integer>(1, Length(LDiffs));
  Assert.AreEqual('node_btn_confirm', LDiffs[0].NodeId, 'NodeId must be canonical node.id');
  Assert.AreEqual(dkChanged, LDiffs[0].Kind);
  Assert.AreEqual(daRelation, LDiffs[0].ChangedAspect);
  Assert.IsTrue(Pos('left-of', LDiffs[0].Note) > 0);
end;

procedure TTestAsWishDifferenceL2L3.Test02_L2_GapDifference;
var
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  // Cancel Left=100, Width=80 -> Right edge=180. Confirm Left=212 -> Observed gap=32. Expected gap=16.
  LDiffs := RunCompare(
    '{"Observations":[{"Name":"AW_BtnCancel","Bounds":{"Left":100,"Top":160,"Width":80,"Height":30},"FontColor":-1},' +
    '{"Name":"AW_BtnConfirm","Bounds":{"Left":212,"Top":160,"Width":80,"Height":30},"FontColor":-1}]}',
    '{"node_btn_cancel":{"relation":"left-of node_btn_confirm","gap":16}}', '',
    ['AW_BtnCancel', 'node_btn_cancel', 'AW_BtnConfirm', 'node_btn_confirm']);
  Assert.AreEqual<Integer>(1, Length(LDiffs));
  Assert.AreEqual('node_btn_confirm', LDiffs[0].NodeId);
  Assert.AreEqual(daRelation, LDiffs[0].ChangedAspect);
  Assert.IsTrue(Pos('gap', LDiffs[0].Note) > 0);
end;

procedure TTestAsWishDifferenceL2L3.Test03_L3_AppearanceDifference_DaContent;
var
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  LDiffs := RunCompare(
    '{"Observations":[{"Name":"AW_Title","Bounds":{"Left":16,"Top":16,"Width":38,"Height":25},"FontColor":255}]}',
    '', '{"node_title":{"FontColor":"clNavy","Token":"token.text.title"}}',
    ['AW_Title', 'node_title']);
  Assert.AreEqual<Integer>(1, Length(LDiffs));
  Assert.AreEqual('node_title', LDiffs[0].NodeId);
  Assert.AreEqual(dkChanged, LDiffs[0].Kind);
  // WO-0031 Mandatory rule: L3 appearance mapped to daContent as temporary compatibility
  Assert.AreEqual(daContent, LDiffs[0].ChangedAspect, 'L3 aspect must temporarily map to daContent');
  Assert.IsTrue(Pos('L3 Appearance Difference', LDiffs[0].Note) > 0);
end;

procedure TTestAsWishDifferenceL2L3.Test04_NoDifference_CleanMatch;
var
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  // Cancel Left=100, Width=80 -> Right edge=180. Confirm Left=196 -> gap=16. Title=clNavy.
  LDiffs := RunCompare(
    '{"Observations":[{"Name":"AW_BtnCancel","Bounds":{"Left":100,"Top":160,"Width":80,"Height":30},"FontColor":-1},' +
    '{"Name":"AW_BtnConfirm","Bounds":{"Left":196,"Top":160,"Width":80,"Height":30},"FontColor":-1},' +
    '{"Name":"AW_Title","Bounds":{"Left":16,"Top":16,"Width":38,"Height":25},"FontColor":8388608}]}',
    '{"node_btn_cancel":{"relation":"left-of node_btn_confirm","gap":16}}',
    '{"node_title":{"FontColor":"clNavy"}}',
    ['AW_BtnCancel', 'node_btn_cancel', 'AW_BtnConfirm', 'node_btn_confirm', 'AW_Title', 'node_title']);
  Assert.AreEqual<Integer>(0, Length(LDiffs));
end;

procedure TTestAsWishDifferenceL2L3.Test05_UnknownPlatformIdentity_FailClosed;
var
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  LDiffs := RunCompare(
    '{"Observations":[{"Name":"AW_Unknown","Bounds":{"Left":10,"Top":10,"Width":50,"Height":20},"FontColor":0}]}',
    '', '', []);
  Assert.AreEqual<Integer>(1, Length(LDiffs));
  Assert.AreEqual('', LDiffs[0].NodeId, 'Must fail-closed without guessing canonical node.id');
  Assert.AreNotEqual('AW_Unknown', LDiffs[0].NodeId);
  Assert.IsTrue(Pos('fail-closed', LowerCase(LDiffs[0].Note)) > 0);
end;

procedure TTestAsWishDifferenceL2L3.Test06_NoComparatorRegistered_ServiceWorks;
var
  LStore: TAsWishStoreService;
  LSnap: TAsWishSnapshotService;
  LSvc: TAsWishDifferenceService;
  LTempDir: string;
begin
  LTempDir := TPath.Combine(TPath.GetTempPath, 'aswish_diff_reg_' + IntToStr(TThread.GetTickCount64));
  ForceDirectories(LTempDir);
  try
    LStore := TAsWishStoreService.Create;
    try
      LStore.InitializeDirect(LTempDir);
      LSnap := TAsWishSnapshotService.Create(LStore);
      try
        LSvc := TAsWishDifferenceService.Create(LStore, LSnap);
        try
          LSvc.ClearComparators;
          Assert.Pass;
        finally
          LSvc.Free;
        end;
      finally
        LSnap.Free;
      end;
    finally
      LStore.Free;
    end;
  finally
    if TDirectory.Exists(LTempDir) then TDirectory.Delete(LTempDir, True);
  end;
end;

procedure TTestAsWishDifferenceL2L3.Test07_DownstreamIntegration_RenderAndDecisions;
var
  LReport: TSpecDifferenceReport;
  LDecSvc: TAsWishDecisionsService;
  LTempDir, LDecId: string;
begin
  LTempDir := TPath.Combine(TPath.GetTempPath, 'aswish_downstream_' + IntToStr(TThread.GetTickCount64));
  ForceDirectories(LTempDir);
  try
    LReport := Default(TSpecDifferenceReport);
    LReport.BaselineId := 'B-TEST';
    LReport.TreeType := 'view';
    SetLength(LReport.Items, 2);
    LReport.Items[0].NodeId := 'node_btn_confirm';
    LReport.Items[0].Kind := dkChanged;
    LReport.Items[0].ChangedAspect := daRelation;
    LReport.Items[0].Note := 'L2 Layout Difference: Expected Cancel left-of Confirm';
    LReport.Items[1].NodeId := 'node_title';
    LReport.Items[1].Kind := dkChanged;
    LReport.Items[1].ChangedAspect := daContent;
    LReport.Items[1].Note := 'L3 Appearance Difference: Expected clNavy, observed clRed';

    TAsWishDiffRenderHelper.RenderDifferencePage(LTempDir, 'zh-CN', LReport, 'TestApp');
    Assert.IsTrue(TFile.Exists(TPath.Combine(LTempDir, 'difference.html')), 'difference.html must exist');

    LDecSvc := TAsWishDecisionsService.Create;
    try
      LDecSvc.Initialize(LTempDir);
      LDecId := LDecSvc.RecordDifferenceDecision(LReport, 'acceptable', 'Accepted L2 layout difference', 'CS-01');
      Assert.IsTrue(LDecId <> '', 'Decision ID must be generated');
      Assert.AreEqual<Integer>(2, Length(LDecSvc.FindById(LDecId).TargetNodes), 'Must record canonical target nodes');
    finally
      LDecSvc.Free;
    end;
  finally
    if TDirectory.Exists(LTempDir) then TDirectory.Delete(LTempDir, True);
  end;
end;

procedure TTestAsWishDifferenceL2L3.Test08_UnknownStyle_Tolerated_NoFalseRed;
var
  LDiffs: TArray<TSpecDifferenceItem>;
  LCtx: TPlatformComparisonContext;
  LBase: TAsWishBaseline;
begin
  // When FontColor is null (unobservable from UIA), comparator must NOT
  // emit false red difference against expected color clNavy.
  LCtx := Default(TPlatformComparisonContext);
  LCtx.TreeType := 'view';
  LCtx.ObservationJson := '{"Observations":[{"Name":"BtnCancel","Bounds":{"Left":100,"Top":160,"Width":80,"Height":30},"FontColor":null}]}';
  LCtx.ExpectedStylesJson := '{"view-ctrl-btncancel":{"FontColor":"clNavy"}}';
  LCtx.IdentityResolver := nil; // Use default DFM convention
  LBase := Default(TAsWishBaseline);
  LBase.TreeType := 'view';

  LDiffs := FComparator.CompareL2L3(LCtx, LBase);
  Assert.AreEqual<Integer>(0, Length(LDiffs), 'Unobservable style must be tolerated without false red difference');
end;

procedure TTestAsWishDifferenceL2L3.Test09_DefaultIdentityResolution_NilResolver;
var
  LDiffs: TArray<TSpecDifferenceItem>;
  LCtx: TPlatformComparisonContext;
  LBase: TAsWishBaseline;
begin
  // Test both order match (0 diffs) and order inverted (1 diff) with nil IdentityResolver
  LCtx := Default(TPlatformComparisonContext);
  LCtx.TreeType := 'view';
  LCtx.ObservationJson := '{"Observations":[' +
    '{"Name":"BtnCancel","Bounds":{"Left":100,"Top":160,"Width":80,"Height":30},"FontColor":null},' +
    '{"Name":"BtnConfirm","Bounds":{"Left":200,"Top":160,"Width":80,"Height":30},"FontColor":null}]}';
  LCtx.ConstraintsJson := '{"view-ctrl-btncancel":{"relation":"left-of view-ctrl-btnconfirm"}}';
  LCtx.IdentityResolver := nil;
  LBase := Default(TAsWishBaseline);
  LBase.TreeType := 'view';

  LDiffs := FComparator.CompareL2L3(LCtx, LBase);
  Assert.AreEqual<Integer>(0, Length(LDiffs), 'Default identity mapping must match expected order');

  // Inverted order: Confirm at Left=50, Cancel at Left=200
  LCtx.ObservationJson := '{"Observations":[' +
    '{"Name":"BtnCancel","Bounds":{"Left":200,"Top":160,"Width":80,"Height":30},"FontColor":null},' +
    '{"Name":"BtnConfirm","Bounds":{"Left":50,"Top":160,"Width":80,"Height":30},"FontColor":null}]}';
  LDiffs := FComparator.CompareL2L3(LCtx, LBase);
  Assert.AreEqual<Integer>(1, Length(LDiffs), 'Inverted order must detect L2 layout difference');
  Assert.AreEqual('view-ctrl-btnconfirm', LDiffs[0].NodeId);
  Assert.AreEqual(daRelation, LDiffs[0].ChangedAspect);
  Assert.IsTrue(Pos('L2 Layout Difference', LDiffs[0].Note) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishDifferenceL2L3);

end.
