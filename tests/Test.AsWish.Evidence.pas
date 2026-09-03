{ ============================================================================
  Test.AsWish.Evidence

  DUnitX tests for Implementation Evidence v0 (WO-20260903-0027F).
  Validates 7 core requirements:
  1. Real file collection -> SourceFileHash = FileSha256Hex
  2. File content change -> re-collect -> SourceFileHash changes
  3. Structural sampling -> Lines / Excerpt non-empty and in range
  4. ReferencedBy correctly backfilled to Baseline node ID
  5. implementation-evidence.yaml round-trip readback
  6. source_refs pointing to non-existent file -> fail-closed
  7. Non-existent baseline-id -> fail-closed
  ============================================================================ }

unit Test.AsWish.Evidence;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Hash,
  AsWish.Services.SpecStore,
  AsWish.Services.Snapshot,
  AsWish.Services.EvidenceCollector;

type
  [TestFixture]
  TTestAsWishEvidence = class
  private
    FTestDir: string;
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    FCollector: TAsWishEvidenceCollectorService;
    FBaselineId: string;
    procedure CreateDummyProjectWithBaseline(const ASourceFileName: string;
      const ASourceContent: string; const ARefLines: string = '1-3');
  public
    [Setup]
    procedure SetUp;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test01_RealFileCollection_SourceFileHashMatches;
    [Test]
    procedure Test02_FileChange_ReCollect_SourceFileHashChanges;
    [Test]
    procedure Test03_StructuralSampling_LinesAndExcerptNonEmpty;
    [Test]
    procedure Test04_ReferencedBy_BackfilledToBaselineNodeId;
    [Test]
    procedure Test05_ImplementationEvidenceYaml_RoundTripReadback;
    [Test]
    procedure Test06_MissingSourceFile_FailClosed;
    [Test]
    procedure Test07_NonExistentBaselineId_FailClosed;
  end;

implementation

procedure TTestAsWishEvidence.SetUp;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'aswish-ev-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FTestDir);

  FStore := TAsWishStoreService.Create;
  FStore.Initialize(FTestDir);
  FStore.CreateDirectoryStructure;

  FSnapshot := TAsWishSnapshotService.Create(FStore);
  FCollector := TAsWishEvidenceCollectorService.Create(FStore, FSnapshot);
end;

procedure TTestAsWishEvidence.TearDown;
begin
  FCollector.Free;
  FSnapshot.Free;
  FStore.Free;

  if TDirectory.Exists(FTestDir) then
    try
      TDirectory.Delete(FTestDir, True);
    except
      // Ignore transient file lock on temp cleanup
    end;
end;

procedure TTestAsWishEvidence.CreateDummyProjectWithBaseline(
  const ASourceFileName: string; const ASourceContent: string;
  const ARefLines: string);
var
  LNodes: TList<TSpecNode>;
  LNode: TSpecNode;
  LRef: TSourceRef;
  LChangeSet: TChangeSet;
  LDecision: TSpecDecision;
  LBaseline: TAsWishBaseline;
  LAbsSourcePath: string;
begin
  // 1. Create source file in workspace
  LAbsSourcePath := TPath.Combine(FTestDir, ASourceFileName);
  var LSourceDir := TPath.GetDirectoryName(LAbsSourcePath);
  if not TDirectory.Exists(LSourceDir) then
    TDirectory.CreateDirectory(LSourceDir);
  TFile.WriteAllText(LAbsSourcePath, ASourceContent, TEncoding.UTF8);

  // 2. Create nodes with source_refs
  LNodes := TList<TSpecNode>.Create;
  try
    LNode := Default(TSpecNode);
    LNode.Id := 'func-test-item';
    LNode.Tree := ttFunction;
    LNode.Title := 'Test Item';
    LNode.Kind := 'feature';
    LNode.Status := nsConfirmed;
    LNode.Summary := 'A feature backed by source file';

    LRef := Default(TSourceRef);
    LRef.RefId := ASourceFileName;
    LRef.Relevance := 'primary';
    LRef.Note := ARefLines;
    SetLength(LNode.SourceRefs, 1);
    LNode.SourceRefs[0] := LRef;

    LNodes.Add(LNode);

    // Write function tree
    FStore.WriteTreeFile('trees/function-tree.yaml', ttFunction, LNodes);

    // 3. Create Baseline
    LDecision := Default(TSpecDecision);
    LDecision.Id := 'dec-test-01';
    LDecision.DecisionType := dtConfirm;
    LDecision.Status := dsAccepted;

    LChangeSet := Default(TChangeSet);
    LChangeSet.Id := 'cs-test-01';
    LChangeSet.IntentTree := ttFunction;
    LChangeSet.IntentNodeId := 'func-test-item';

    FBaselineId := FSnapshot.CreateBaseline(LDecision, LChangeSet,
      LNodes, nil, nil, nil, LBaseline);
  finally
    LNodes.Free;
  end;
end;

procedure TTestAsWishEvidence.Test01_RealFileCollection_SourceFileHashMatches;
var
  LEvidences: TArray<TSpecEvidence>;
  LSourceContent, LAbsFile, LExpectedHash: string;
begin
  LSourceContent := 'unit TestModule;' + sLineBreak +
                    'interface' + sLineBreak +
                    'implementation' + sLineBreak +
                    'end.';
  CreateDummyProjectWithBaseline('src\TestModule.pas', LSourceContent, '1-3');

  LEvidences := FCollector.CollectImplementationEvidence(FTestDir, FBaselineId);

  Assert.AreEqual<Integer>(1, Length(LEvidences), 'Should collect 1 evidence item');
  LAbsFile := TPath.Combine(FTestDir, 'src\TestModule.pas');
  LExpectedHash := TSpecHash.FileSha256Hex(LAbsFile);

  Assert.AreEqual<string>(LExpectedHash, LEvidences[0].SourceFileHash,
    'SourceFileHash must match FileSha256Hex of real file');
  Assert.AreEqual<TSourceLayer>(slImplementation, LEvidences[0].SourceLayer,
    'SourceLayer must be slImplementation');
end;

procedure TTestAsWishEvidence.Test02_FileChange_ReCollect_SourceFileHashChanges;
var
  LEv1, LEv2: TArray<TSpecEvidence>;
  LSourceContent1, LSourceContent2, LAbsFile: string;
begin
  LSourceContent1 := 'function Foo: Integer; begin Result := 1; end;';
  CreateDummyProjectWithBaseline('src\Foo.pas', LSourceContent1, '1-1');

  LEv1 := FCollector.CollectImplementationEvidence(FTestDir, FBaselineId);
  Assert.AreEqual<Integer>(1, Length(LEv1));

  // Change file content
  LAbsFile := TPath.Combine(FTestDir, 'src\Foo.pas');
  LSourceContent2 := 'function Foo: Integer; begin Result := 42; end; // modified';
  TFile.WriteAllText(LAbsFile, LSourceContent2, TEncoding.UTF8);

  // Re-collect
  LEv2 := FCollector.CollectImplementationEvidence(FTestDir, FBaselineId);
  Assert.AreEqual<Integer>(1, Length(LEv2));

  Assert.AreNotEqual(LEv1[0].SourceFileHash, LEv2[0].SourceFileHash,
    'SourceFileHash must change when file content changes');
  Assert.AreEqual<string>(TSpecHash.FileSha256Hex(LAbsFile), LEv2[0].SourceFileHash,
    'New hash must match new file SHA256');
end;

procedure TTestAsWishEvidence.Test03_StructuralSampling_LinesAndExcerptNonEmpty;
var
  LEvidences: TArray<TSpecEvidence>;
  LSourceContent: string;
begin
  LSourceContent := 'line 1: header' + sLineBreak +
                    'line 2: target symbol' + sLineBreak +
                    'line 3: footer';
  CreateDummyProjectWithBaseline('src\Sample.pas', LSourceContent, '2-3');

  LEvidences := FCollector.CollectImplementationEvidence(FTestDir, FBaselineId);
  Assert.AreEqual<Integer>(1, Length(LEvidences));
  Assert.IsNotEmpty(LEvidences[0].Excerpt, 'Excerpt must not be empty');
  Assert.IsTrue(Pos('line 2: target symbol', LEvidences[0].Excerpt) > 0,
    'Excerpt should contain sample lines');
end;

procedure TTestAsWishEvidence.Test04_ReferencedBy_BackfilledToBaselineNodeId;
var
  LEvidences: TArray<TSpecEvidence>;
  LSourceContent: string;
begin
  LSourceContent := 'procedure DoWork; begin end;';
  CreateDummyProjectWithBaseline('src\Work.pas', LSourceContent, '1-1');

  LEvidences := FCollector.CollectImplementationEvidence(FTestDir, FBaselineId);
  Assert.AreEqual<Integer>(1, Length(LEvidences));
  Assert.AreEqual<Integer>(1, Length(LEvidences[0].ReferencedBy), 'ReferencedBy length should be 1');
  Assert.AreEqual<string>('func-test-item', LEvidences[0].ReferencedBy[0],
    'ReferencedBy must backfill the baseline node ID');
end;

procedure TTestAsWishEvidence.Test05_ImplementationEvidenceYaml_RoundTripReadback;
var
  LEvidences: TArray<TSpecEvidence>;
  LReadList: TList<TSpecEvidence>;
  LSourceContent, LYamlPath: string;
begin
  LSourceContent := 'unit RoundTrip; interface implementation end.';
  CreateDummyProjectWithBaseline('src\RoundTrip.pas', LSourceContent, '1-1');

  LEvidences := FCollector.CollectImplementationEvidence(FTestDir, FBaselineId);
  Assert.AreEqual<Integer>(1, Length(LEvidences));

  LYamlPath := TPath.Combine(FTestDir, '.AsWish\evidence\implementation-evidence.yaml');
  Assert.IsTrue(TFile.Exists(LYamlPath), 'implementation-evidence.yaml must be written');

  LReadList := FStore.ReadEvidenceFile('evidence/implementation-evidence.yaml');
  try
    Assert.IsNotNull(LReadList);
    Assert.AreEqual<Integer>(1, LReadList.Count, 'Should read back 1 evidence item');
    Assert.AreEqual<string>(LEvidences[0].Path, LReadList[0].Path);
    Assert.AreEqual<string>(LEvidences[0].SourceFileHash, LReadList[0].SourceFileHash);
    Assert.AreEqual<Integer>(1, Length(LReadList[0].ReferencedBy));
    Assert.AreEqual<string>('func-test-item', LReadList[0].ReferencedBy[0]);
  finally
    LReadList.Free;
  end;
end;

procedure TTestAsWishEvidence.Test06_MissingSourceFile_FailClosed;
var
  LEx: Boolean;
begin
  CreateDummyProjectWithBaseline('src\NonExistent.pas', 'some content', '1-1');
  // Delete the file to simulate missing file
  TFile.Delete(TPath.Combine(FTestDir, 'src\NonExistent.pas'));

  LEx := False;
  try
    FCollector.CollectImplementationEvidence(FTestDir, FBaselineId);
  except
    on E: Exception do
      LEx := True;
  end;

  Assert.IsTrue(LEx, 'Must fail-closed with exception when source file is missing');
end;

procedure TTestAsWishEvidence.Test07_NonExistentBaselineId_FailClosed;
var
  LEx: Boolean;
begin
  CreateDummyProjectWithBaseline('src\Valid.pas', 'content', '1-1');

  LEx := False;
  try
    FCollector.CollectImplementationEvidence(FTestDir, 'B-9999-invalid');
  except
    on E: Exception do
      LEx := True;
  end;

  Assert.IsTrue(LEx, 'Must fail-closed when baseline ID does not exist');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishEvidence);

end.
