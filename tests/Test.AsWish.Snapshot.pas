{ ============================================================================
  Test.AsWish.Snapshot

  DUnitX tests for AsWish.Services.Snapshot -- full-tree snapshot, listing
  (newest first), restore round-trip with tamper/delete, the automatic
  pre-restore safety snapshot, and empty-project resilience (workorder
  WO-20260824-02).
  ============================================================================ }

unit Test.AsWish.Snapshot;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestAsWishSnapshot = class
  public
    [Test]
    procedure Test_Create_List_Restore_RoundTrip;
    [Test]
    procedure Test_Restore_CreatesPreRestoreSnapshot;
    [Test]
    procedure Test_ListSnapshots_DescendingOrder;
    [Test]
    procedure Test_EmptyProject_SnapshotAndRestoreDoNotCrash;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Test.AsWish.FixtureHelper,
  AsWish.Services.SpecStore,
  AsWish.Services.Snapshot;

function NewTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

function ListContains(AList: TArray<string>; const AName: string): Boolean;
var
  S: string;
begin
  Result := False;
  for S in AList do
    if S = AName then Exit(True);
end;

procedure WriteSpecFile(const AProjectDir, ARelPath, AContent: string);
var
  LFullPath, LDir: string;
begin
  LFullPath := TPath.Combine(AProjectDir, '.AsWish\' + ARelPath);
  LDir := TPath.GetDirectoryName(LFullPath);
  if not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);
  WriteFixtureText(LFullPath, AContent, TEncoding.UTF8);
end;

function ReadSpecFile(const AProjectDir, ARelPath: string): string;
begin
  Result := TFile.ReadAllText(
    TPath.Combine(AProjectDir, '.AsWish\' + ARelPath), TEncoding.UTF8);
end;

const
  FuncV1 = 'version: "1.0"' + sLineBreak + 'tree: function' + sLineBreak +
    'nodes: []' + sLineBreak;
  ModV1 = 'version: "1.0"' + sLineBreak + 'tree: module' + sLineBreak +
    'nodes: []' + sLineBreak;

{ TTestAsWishSnapshot }

procedure TTestAsWishSnapshot.Test_Create_List_Restore_RoundTrip;
var
  LProj: string;
  LStore: TAsWishStoreService;
  LSvc: TAsWishSnapshotService;
  LName: string;
begin
  LProj := NewTempDir;
  LStore := TAsWishStoreService.Create;
  LSvc := nil;
  try
    LStore.Initialize(LProj);
    LStore.CreateDirectoryStructure;
    LSvc := TAsWishSnapshotService.Create(LStore);

    WriteSpecFile(LProj, 'trees\function-tree.yaml', FuncV1);
    WriteSpecFile(LProj, 'trees\module-tree.yaml', ModV1);
    WriteSpecFile(LProj, 'issues\doc-issues.yaml',
      'issues: []' + sLineBreak);
    WriteSpecFile(LProj, 'bundles.yaml', 'bundles: []' + sLineBreak);

    LName := LSvc.CreateSnapshot('pre-generate');

    Assert.IsNotEmpty(LName, 'CreateSnapshot should return a name');
    Assert.IsTrue(ListContains(LSvc.ListSnapshots, LName),
      'ListSnapshots should contain the new snapshot');
    var LSnapDir := TPath.Combine(LProj, '.AsWish\snapshots\' + LName);
    Assert.IsTrue(TDirectory.Exists(LSnapDir),
      'snapshot directory should exist under snapshots/');
    Assert.IsTrue(TFile.Exists(TPath.Combine(LSnapDir, 'snapshot.yaml')),
      'snapshot metadata should exist');
    Assert.IsTrue(TFile.Exists(
      TPath.Combine(LSnapDir, 'trees\function-tree.yaml')),
      'tree files should be copied into the snapshot');

    // Tamper working tree
    WriteSpecFile(LProj, 'trees\function-tree.yaml', 'tampered');
    TFile.Delete(TPath.Combine(
      LProj, '.AsWish\trees\module-tree.yaml'));

    LSvc.RestoreSnapshot(LName);

    Assert.AreEqual(FuncV1, ReadSpecFile(LProj, 'trees\function-tree.yaml'),
      'restore should bring back the original tree content');
    Assert.IsTrue(TFile.Exists(
      TPath.Combine(LProj, '.AsWish\trees\module-tree.yaml')),
      'restore should recreate a deleted file');
    Assert.AreEqual(ModV1, ReadSpecFile(LProj, 'trees\module-tree.yaml'),
      'recreated file should match the snapshot content');
    Assert.AreEqual('bundles: []' + sLineBreak,
      ReadSpecFile(LProj, 'bundles.yaml'),
      'untouched root file should survive restore unchanged');
  finally
    LSvc.Free;
    LStore.Free;
    TDirectory.Delete(LProj, True);
  end;
end;

procedure TTestAsWishSnapshot.Test_Restore_CreatesPreRestoreSnapshot;
var
  LProj: string;
  LStore: TAsWishStoreService;
  LSvc: TAsWishSnapshotService;
  LName: string;
  LFoundPreRestore: Boolean;
begin
  LProj := NewTempDir;
  LStore := TAsWishStoreService.Create;
  LSvc := nil;
  try
    LStore.Initialize(LProj);
    LStore.CreateDirectoryStructure;
    LSvc := TAsWishSnapshotService.Create(LStore);

    WriteSpecFile(LProj, 'trees\function-tree.yaml', FuncV1);
    LName := LSvc.CreateSnapshot('snap-a');

    WriteSpecFile(LProj, 'trees\function-tree.yaml', 'current-state');
    LSvc.RestoreSnapshot(LName);

    LFoundPreRestore := False;
    for var S in LSvc.ListSnapshots do
      if S.Contains('-pre-restore') then
        LFoundPreRestore := True;
    Assert.IsTrue(LFoundPreRestore,
      'restore must auto-create a pre-restore snapshot of current state');
    Assert.AreEqual(FuncV1, ReadSpecFile(LProj, 'trees\function-tree.yaml'),
      'working tree should be rolled back to snap-a content');
  finally
    LSvc.Free;
    LStore.Free;
    TDirectory.Delete(LProj, True);
  end;
end;

procedure TTestAsWishSnapshot.Test_ListSnapshots_DescendingOrder;
var
  LProj: string;
  LStore: TAsWishStoreService;
  LSvc: TAsWishSnapshotService;
  LOlder, LNewer: string;
begin
  LProj := NewTempDir;
  LStore := TAsWishStoreService.Create;
  LSvc := nil;
  try
    LStore.Initialize(LProj);
    LStore.CreateDirectoryStructure;
    LSvc := TAsWishSnapshotService.Create(LStore);

    LOlder := LSvc.CreateSnapshot('older');
    Sleep(1100);
    LNewer := LSvc.CreateSnapshot('newer');

    var LList := LSvc.ListSnapshots;
    Assert.IsTrue(Length(LList) >= 2, 'both snapshots should be listed');
    Assert.AreEqual(LNewer, LList[0],
      'the newest snapshot should be listed first');
    Assert.IsTrue(ListContains(LList, LOlder),
      'the older snapshot should also be listed');
    Assert.IsTrue(Pos(LOlder, string.Join('|', LList)) >
      Pos(LNewer, string.Join('|', LList)),
      'listing order should be descending by creation time');
  finally
    LSvc.Free;
    LStore.Free;
    TDirectory.Delete(LProj, True);
  end;
end;

procedure TTestAsWishSnapshot.Test_EmptyProject_SnapshotAndRestoreDoNotCrash;
var
  LProj: string;
  LStore: TAsWishStoreService;
  LSvc: TAsWishSnapshotService;
  LName: string;
begin
  LProj := NewTempDir;
  LStore := TAsWishStoreService.Create;
  LSvc := nil;
  try
    LStore.Initialize(LProj);
    // No CreateDirectoryStructure: .AsWish does not even exist yet.
    LSvc := TAsWishSnapshotService.Create(LStore);

    LName := LSvc.CreateSnapshot('empty');
    Assert.IsNotEmpty(LName, 'empty-project snapshot should still succeed');
    Assert.IsTrue(TFile.Exists(TPath.Combine(LProj,
      '.AsWish\snapshots\' + LName + '\snapshot.yaml')),
      'snapshot metadata should be written even with no trees');

    LSvc.RestoreSnapshot(LName);
    Assert.IsNotEmpty(LSvc.ListSnapshots,
      'list after restore of an empty snapshot should not crash');
  finally
    LSvc.Free;
    LStore.Free;
    TDirectory.Delete(LProj, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishSnapshot);

end.
