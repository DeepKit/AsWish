{ ============================================================================
  Test.AsWish.Difference.L2L3.pas - WO-0031 Platform Extension Seam Tests
  ============================================================================ }
unit Test.AsWish.Difference.L2L3;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, AsWish.Models, AsWish.Services.SpecStore,
  AsWish.Services.Snapshot, AsWish.Services.Difference, AsWish.Plugins.VCL.Difference;

type
  [TestFixture]
  TTestAsWishDifferenceL2L3 = class
  private
    FComparator: IPlatformDifferenceComparator;
    function MakeResolver(const APairs: array of string): IPlatformIdentityResolver;
  public
    [Setup]
    procedure SetUp;
    [Test]
    procedure TestCase1_L2_LayoutConstraintFailure;
    [Test]
    procedure TestCase2_L3_AppearanceStyleFailure_DaContent;
    [Test]
    procedure TestCase3_CleanMatch_ZeroDifferences;
    [Test]
    procedure TestCase4_MissingIdentityMapping_FailClosed;
    [Test]
    procedure TestCase5_Registration_OnService;
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

procedure TTestAsWishDifferenceL2L3.TestCase1_L2_LayoutConstraintFailure;
var
  LCtx: TPlatformComparisonContext;
  LBase: TAsWishBaseline;
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  LCtx := Default(TPlatformComparisonContext);
  LCtx.TreeType := 'view';
  LCtx.ObservationJson := '{"Observations":[' +
    '{"Name":"AW_BtnCancel","Bounds":{"Left":276,"Top":160,"Width":80,"Height":30},"FontColor":-1},' +
    '{"Name":"AW_BtnConfirm","Bounds":{"Left":180,"Top":160,"Width":80,"Height":30},"FontColor":-1}' +
    ']}';
  LCtx.ConstraintsJson := '{"node_btn_cancel":{"relation":"left-of node_btn_confirm","gap":16}}';
  LCtx.IdentityResolver := MakeResolver(['AW_BtnCancel', 'node_btn_cancel', 'AW_BtnConfirm', 'node_btn_confirm']);
  LBase := Default(TAsWishBaseline);
  LBase.TreeType := 'view';

  LDiffs := FComparator.CompareL2L3(LCtx, LBase);
  Assert.AreEqual<Integer>(1, Length(LDiffs), 'Must detect exactly 1 L2 difference');
  Assert.AreEqual('node_btn_confirm', LDiffs[0].NodeId, 'NodeId must be canonical node.id');
  Assert.AreEqual(dkChanged, LDiffs[0].Kind);
  Assert.AreEqual(daRelation, LDiffs[0].ChangedAspect, 'L2 aspect must be daRelation');
  Assert.IsTrue(Pos('left-of', LDiffs[0].Note) > 0, 'Note must detail relational layout mismatch');
end;

procedure TTestAsWishDifferenceL2L3.TestCase2_L3_AppearanceStyleFailure_DaContent;
var
  LCtx: TPlatformComparisonContext;
  LBase: TAsWishBaseline;
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  LCtx := Default(TPlatformComparisonContext);
  LCtx.TreeType := 'view';
  LCtx.ObservationJson := '{"Observations":[' +
    '{"Name":"AW_Title","Bounds":{"Left":16,"Top":16,"Width":38,"Height":25},"FontColor":255}' +
    ']}';
  LCtx.ExpectedStylesJson := '{"node_title":{"FontColor":"clNavy","Token":"token.text.title"}}';
  LCtx.IdentityResolver := MakeResolver(['AW_Title', 'node_title']);
  LBase := Default(TAsWishBaseline);
  LBase.TreeType := 'view';

  LDiffs := FComparator.CompareL2L3(LCtx, LBase);
  Assert.AreEqual<Integer>(1, Length(LDiffs), 'Must detect exactly 1 L3 difference');
  Assert.AreEqual('node_title', LDiffs[0].NodeId, 'NodeId must be canonical node.id');
  Assert.AreEqual(dkChanged, LDiffs[0].Kind);
  // WO-0031 Mandatory rule: L3 appearance mapped to daContent as temporary compatibility
  Assert.AreEqual(daContent, LDiffs[0].ChangedAspect, 'L3 aspect must temporarily map to daContent');
  Assert.IsTrue(Pos('L3 Appearance Difference', LDiffs[0].Note) > 0);
  Assert.IsTrue(Pos('clNavy', LDiffs[0].Note) > 0);
  Assert.IsTrue(Pos('255', LDiffs[0].Note) > 0);
end;

procedure TTestAsWishDifferenceL2L3.TestCase3_CleanMatch_ZeroDifferences;
var
  LCtx: TPlatformComparisonContext;
  LBase: TAsWishBaseline;
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  LCtx := Default(TPlatformComparisonContext);
  LCtx.TreeType := 'view';
  // AW_BtnCancel Left=100, Width=80 -> Right edge=180. AW_BtnConfirm Left=196 -> Gap=16. Matches left-of and gap=16.
  LCtx.ObservationJson := '{"Observations":[' +
    '{"Name":"AW_BtnCancel","Bounds":{"Left":100,"Top":160,"Width":80,"Height":30},"FontColor":-1},' +
    '{"Name":"AW_BtnConfirm","Bounds":{"Left":196,"Top":160,"Width":80,"Height":30},"FontColor":-1},' +
    '{"Name":"AW_Title","Bounds":{"Left":16,"Top":16,"Width":38,"Height":25},"FontColor":8388608}' +
    ']}';
  LCtx.ConstraintsJson := '{"node_btn_cancel":{"relation":"left-of node_btn_confirm","gap":16}}';
  LCtx.ExpectedStylesJson := '{"node_title":{"FontColor":"clNavy"}}';
  LCtx.IdentityResolver := MakeResolver([
    'AW_BtnCancel', 'node_btn_cancel', 'AW_BtnConfirm', 'node_btn_confirm', 'AW_Title', 'node_title'
  ]);
  LBase := Default(TAsWishBaseline);
  LBase.TreeType := 'view';

  LDiffs := FComparator.CompareL2L3(LCtx, LBase);
  Assert.AreEqual<Integer>(0, Length(LDiffs), 'Matching observation and constraints must yield 0 differences');
end;

procedure TTestAsWishDifferenceL2L3.TestCase4_MissingIdentityMapping_FailClosed;
var
  LCtx: TPlatformComparisonContext;
  LBase: TAsWishBaseline;
  LDiffs: TArray<TSpecDifferenceItem>;
begin
  LCtx := Default(TPlatformComparisonContext);
  LCtx.TreeType := 'view';
  LCtx.ObservationJson := '{"Observations":[' +
    '{"Name":"AW_Unknown","Bounds":{"Left":10,"Top":10,"Width":50,"Height":20},"FontColor":0}' +
    ']}';
  LCtx.IdentityResolver := MakeResolver([]); // No mapping for AW_Unknown
  LBase := Default(TAsWishBaseline);

  LDiffs := FComparator.CompareL2L3(LCtx, LBase);
  Assert.AreEqual<Integer>(1, Length(LDiffs), 'Must report missing identity mapping');
  Assert.AreEqual('', LDiffs[0].NodeId, 'Must fail-closed without guessing canonical node.id');
  Assert.AreNotEqual('AW_Unknown', LDiffs[0].NodeId);
  Assert.IsTrue(Pos('AW_Unknown', LDiffs[0].Note) > 0);
  Assert.IsTrue(Pos('fail-closed', LowerCase(LDiffs[0].Note)) > 0);
end;

procedure TTestAsWishDifferenceL2L3.TestCase5_Registration_OnService;
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
          LSvc.RegisterComparator(FComparator);
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
    if TDirectory.Exists(LTempDir) then
      TDirectory.Delete(LTempDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishDifferenceL2L3);

end.
