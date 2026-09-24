{ ============================================================================
  Test.AsWish.SpecStore

  DUnitX tests for AsWish.Services.SpecStore persistence — focused on the
  atomic-write path (bugfix #5 + #17). Includes the bugfix #17 regression:
  overwriting an existing file went through TFile.Replace(..., '') whose RTL
  implementation calls TPath.DoGetFullPath('') and raises EInOutArgumentException
  "Path is empty" — every re-scan of an existing project crashed before the
  ReplaceFileW fix.
  ============================================================================ }

unit Test.AsWish.SpecStore;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestAsWishSpecStore = class
  public
    [Test]
    procedure Test_AtomicWrite_FirstWrite;
    [Test]
    procedure Test_AtomicWrite_Overwrite;
    [Test]
    procedure Test_WriteTreeFile_Overwrite_RoundTrip;
    [Test]
    procedure Test_WriteTreeFile_CreatesSnapshotBackup;
    [Test]
    procedure Test_WriteDataTreeFile_RoundTrip;
    [Test]
    procedure Test_WriteGitIgnore_CoversRegenerableArtifacts;
    [Test]
    procedure Test_WriteGitIgnore_RefreshesStaleContent;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.SpecStore;

function NewTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

{ TTestAsWishSpecStore }

procedure TTestAsWishSpecStore.Test_AtomicWrite_FirstWrite;
var
  LDir, LPath: string;
begin
  LDir := NewTempDir;
  try
    TDirectory.CreateDirectory(LDir);
    LPath := TPath.Combine(LDir, 'sample.yaml');
    TAsWishStoreService.AtomicWriteTextFile(LPath, 'version: "1.0"');

    Assert.IsTrue(TFile.Exists(LPath), 'first write should create the file');
    Assert.AreEqual('version: "1.0"',
      TFile.ReadAllText(LPath, TEncoding.UTF8));
  finally
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishSpecStore.Test_AtomicWrite_Overwrite;
var
  LDir, LPath: string;
begin
  LDir := NewTempDir;
  try
    TDirectory.CreateDirectory(LDir);
    LPath := TPath.Combine(LDir, 'sample.yaml');
    TAsWishStoreService.AtomicWriteTextFile(LPath, 'v1');
    // bugfix #17 regression: overwrite went through TFile.Replace('', ...)
    // which raised "Path is empty". Must not raise now.
    TAsWishStoreService.AtomicWriteTextFile(LPath, 'v2');

    Assert.AreEqual('v2', TFile.ReadAllText(LPath, TEncoding.UTF8),
      'overwrite should replace content atomically');
    Assert.IsFalse(TFile.Exists(LPath + '.tmp'),
      'temp file must not remain after atomic write');
  finally
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishSpecStore.Test_WriteTreeFile_Overwrite_RoundTrip;
var
  LDir: string;
  LStore: TAsWishStoreService;
  LNodes, LRead: TList<TSpecNode>;
  LNode: TSpecNode;
begin
  LDir := NewTempDir;
  LStore := TAsWishStoreService.Create;
  LNodes := TList<TSpecNode>.Create;
  LRead := nil;
  try
    TDirectory.CreateDirectory(LDir);
    LStore.Initialize(LDir);

    LNode := TSpecNode.MakeNew('func-1', ttFunction, 'F1', 'feature');
    LNodes.Add(LNode);
    LStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);
    // Second write overwrites the existing file (ReplaceFileW branch).
    LStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    LRead := LStore.ReadTreeFile('trees/function-tree.yaml');
    Assert.IsNotNull(LRead, 'round trip should parse the tree');
    Assert.AreEqual<Integer>(1, LRead.Count);
    Assert.AreEqual<string>('func-1', LRead[0].Id);
    Assert.AreEqual<string>('F1', LRead[0].Title);
  finally
    LRead.Free;
    LNodes.Free;
    LStore.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishSpecStore.Test_WriteTreeFile_CreatesSnapshotBackup;
var
  LDir: string;
  LStore: TAsWishStoreService;
  LNodes: TList<TSpecNode>;
  LNode: TSpecNode;
begin
  LDir := NewTempDir;
  LStore := TAsWishStoreService.Create;
  LNodes := TList<TSpecNode>.Create;
  try
    TDirectory.CreateDirectory(LDir);
    LStore.Initialize(LDir);
    LStore.CreateDirectoryStructure;

    LNode := TSpecNode.MakeNew('func-1', ttFunction, 'F1', 'feature');
    LNodes.Add(LNode);
    LStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);
    // Second write: the previous version must be snapshotted first.
    LStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    Assert.IsTrue(TFile.Exists(
      TPath.Combine(LDir, '.AsWish\snapshots\function-tree.bak.yaml')),
      'overwrite should keep a snapshot backup of the previous version');
  finally
    LNodes.Free;
    LStore.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishSpecStore.Test_WriteDataTreeFile_RoundTrip;
var
  LDir: string;
  LStore: TAsWishStoreService;
  LNodes, LRead: TList<TSpecNode>;
  LNode: TSpecNode;
begin
  LDir := NewTempDir;
  LStore := TAsWishStoreService.Create;
  LNodes := TList<TSpecNode>.Create;
  LRead := nil;
  try
    TDirectory.CreateDirectory(LDir);
    LStore.Initialize(LDir);
    LStore.CreateDirectoryStructure;

    LNode := TSpecNode.MakeNew('data-user', ttData, 'User', 'entity');
    LNode.DataType := 'object';
    LNode.Nullable := False;
    LNode.HasNullable := True;
    LNode.DefaultValue := 'guest';
    LNode.FieldConstraints := TArray<string>.Create('unique', 'max_length: 80');
    LNode.Persistence := 'db';
    LNode.SourceEntity := 'User';
    LNode.TargetEntity := 'Account';
    LNode.Cardinality := 'one_to_one';
    LNode.Cascade := 'delete';
    LNode.ValidStates := TArray<string>.Create('active', 'disabled');
    LNode.Transitions := TArray<TPair<string, string>>.Create(
      TPair<string, string>.Create('active', 'disabled'));
    LNode.BackwardCompatible := True;
    LNode.HasBackwardCompatible := True;
    LNode.HasRollback := True;
    LNode.HasHasRollback := True;
    LNode.Scope := 'tenant';
    LNode.Enforcement := 'both';
    LNodes.Add(LNode);

    LStore.WriteTreeFile('trees/data-tree.yaml', ttData, LNodes);
    LRead := LStore.ReadTreeFile('trees/data-tree.yaml');

    Assert.AreEqual<Integer>(1, LRead.Count);
    Assert.AreEqual(ttData, LRead[0].Tree);
    Assert.AreEqual('object', LRead[0].DataType);
    Assert.IsTrue(LRead[0].HasNullable);
    Assert.IsFalse(LRead[0].Nullable);
    Assert.AreEqual('guest', LRead[0].DefaultValue);
    Assert.AreEqual<Integer>(2, Length(LRead[0].FieldConstraints));
    Assert.AreEqual('db', LRead[0].Persistence);
    Assert.AreEqual('User', LRead[0].SourceEntity);
    Assert.AreEqual('Account', LRead[0].TargetEntity);
    Assert.AreEqual('one_to_one', LRead[0].Cardinality);
    Assert.AreEqual('delete', LRead[0].Cascade);
    Assert.AreEqual<Integer>(2, Length(LRead[0].ValidStates));
    Assert.AreEqual<Integer>(1, Length(LRead[0].Transitions));
    Assert.AreEqual('active', LRead[0].Transitions[0].Key);
    Assert.AreEqual('disabled', LRead[0].Transitions[0].Value);
    Assert.IsTrue(LRead[0].HasBackwardCompatible);
    Assert.IsTrue(LRead[0].BackwardCompatible);
    Assert.IsTrue(LRead[0].HasHasRollback);
    Assert.IsTrue(LRead[0].HasRollback);
    Assert.AreEqual('tenant', LRead[0].Scope);
    Assert.AreEqual('both', LRead[0].Enforcement);
  finally
    LRead.Free;
    LNodes.Free;
    LStore.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishSpecStore.Test_WriteGitIgnore_CoversRegenerableArtifacts;
var
  LDir, LPath, LContent: string;
  LStore: TAsWishStoreService;
begin
  LDir := NewTempDir;
  LStore := TAsWishStoreService.Create;
  try
    TDirectory.CreateDirectory(LDir);
    LStore.Initialize(LDir);
    LStore.CreateDirectoryStructure;
    LStore.WriteGitIgnore;

    LPath := TPath.Combine(LDir, '.AsWish\.gitignore');
    Assert.IsTrue(TFile.Exists(LPath), '.AsWish/.gitignore should be written');
    LContent := TFile.ReadAllText(LPath, TEncoding.UTF8);

    // Every artifact a scan regenerates from scratch must be ignored, or a
    // plain "git add -A" in the scanned project commits generated churn.
    Assert.IsTrue(LContent.Contains('snapshots/'),
      'rolling .bak.yaml backups are regenerated on every scan');
    Assert.IsTrue(LContent.Contains('scan-report.yaml'),
      'scan-report.yaml is pure scan output');
    Assert.IsTrue(LContent.Contains('project-spec.yaml'),
      'project-spec.yaml is pure scan output');
    Assert.IsTrue(LContent.Contains('html/'), 'html/ is a derived view');
  finally
    LStore.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestAsWishSpecStore.Test_WriteGitIgnore_RefreshesStaleContent;
var
  LDir, LPath, LContent: string;
  LStore: TAsWishStoreService;
begin
  LDir := NewTempDir;
  LStore := TAsWishStoreService.Create;
  try
    TDirectory.CreateDirectory(LDir);
    LStore.Initialize(LDir);
    LStore.CreateDirectoryStructure;

    // A .gitignore written by an older build must be refreshed, otherwise a
    // generated file silently stays stale for every existing project and the
    // fix never reaches anyone who already ran the tool.
    LPath := TPath.Combine(LDir, '.AsWish\.gitignore');
    TFile.WriteAllText(LPath, '# stale' + sLineBreak + 'html/', TEncoding.UTF8);

    LStore.WriteGitIgnore;
    LContent := TFile.ReadAllText(LPath, TEncoding.UTF8);

    Assert.IsTrue(LContent.Contains('snapshots/'),
      'an existing .gitignore must be refreshed, not left stale');
    Assert.IsFalse(LContent.Contains('# stale'),
      'refreshing should replace the outdated content');
  finally
    LStore.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishSpecStore);

end.

