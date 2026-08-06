{ ============================================================================
  Test.DeepSpec.SpecStore

  DUnitX tests for DeepSpec.Services.SpecStore persistence — focused on the
  atomic-write path (bugfix #5 + #17). Includes the bugfix #17 regression:
  overwriting an existing file went through TFile.Replace(..., '') whose RTL
  implementation calls TPath.DoGetFullPath('') and raises EInOutArgumentException
  "Path is empty" — every re-scan of an existing project crashed before the
  ReplaceFileW fix.
  ============================================================================ }

unit Test.DeepSpec.SpecStore;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDeepSpecSpecStore = class
  public
    [Test]
    procedure Test_AtomicWrite_FirstWrite;
    [Test]
    procedure Test_AtomicWrite_Overwrite;
    [Test]
    procedure Test_WriteTreeFile_Overwrite_RoundTrip;
    [Test]
    procedure Test_WriteTreeFile_CreatesSnapshotBackup;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  DeepSpec.Models,
  DeepSpec.Services.SpecStore;

function NewTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'deepspec-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

{ TTestDeepSpecSpecStore }

procedure TTestDeepSpecSpecStore.Test_AtomicWrite_FirstWrite;
var
  LDir, LPath: string;
begin
  LDir := NewTempDir;
  try
    TDirectory.CreateDirectory(LDir);
    LPath := TPath.Combine(LDir, 'sample.yaml');
    TDeepSpecStoreService.AtomicWriteTextFile(LPath, 'version: "1.0"');

    Assert.IsTrue(TFile.Exists(LPath), 'first write should create the file');
    Assert.AreEqual('version: "1.0"',
      TFile.ReadAllText(LPath, TEncoding.UTF8));
  finally
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestDeepSpecSpecStore.Test_AtomicWrite_Overwrite;
var
  LDir, LPath: string;
begin
  LDir := NewTempDir;
  try
    TDirectory.CreateDirectory(LDir);
    LPath := TPath.Combine(LDir, 'sample.yaml');
    TDeepSpecStoreService.AtomicWriteTextFile(LPath, 'v1');
    // bugfix #17 regression: overwrite went through TFile.Replace('', ...)
    // which raised "Path is empty". Must not raise now.
    TDeepSpecStoreService.AtomicWriteTextFile(LPath, 'v2');

    Assert.AreEqual('v2', TFile.ReadAllText(LPath, TEncoding.UTF8),
      'overwrite should replace content atomically');
    Assert.IsFalse(TFile.Exists(LPath + '.tmp'),
      'temp file must not remain after atomic write');
  finally
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TTestDeepSpecSpecStore.Test_WriteTreeFile_Overwrite_RoundTrip;
var
  LDir: string;
  LStore: TDeepSpecStoreService;
  LNodes, LRead: TList<TSpecNode>;
  LNode: TSpecNode;
begin
  LDir := NewTempDir;
  LStore := TDeepSpecStoreService.Create;
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

procedure TTestDeepSpecSpecStore.Test_WriteTreeFile_CreatesSnapshotBackup;
var
  LDir: string;
  LStore: TDeepSpecStoreService;
  LNodes: TList<TSpecNode>;
  LNode: TSpecNode;
begin
  LDir := NewTempDir;
  LStore := TDeepSpecStoreService.Create;
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
      TPath.Combine(LDir, '.deepspec\snapshots\function-tree.bak.yaml')),
      'overwrite should keep a snapshot backup of the previous version');
  finally
    LNodes.Free;
    LStore.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeepSpecSpecStore);

end.
