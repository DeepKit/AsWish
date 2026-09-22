{ ============================================================================
  Test.AsWish.TreeBuilder

  Verifies that a non-Delphi project receives a useful data projection and
  that a project with no inferable data remains visibly fogged.
  ============================================================================ }

unit Test.AsWish.TreeBuilder;

interface

uses
  System.SysUtils,
  System.IOUtils,
  DUnitX.TestFramework,
  AsWish.Models,
  AsWish.Services.Scan,
  AsWish.Services.TreeBuilder;

type
  [TestFixture]
  TTreeBuilderDataTests = class
  public
    [Test]
    procedure Build_GenericProject_InfersDataEntities;
    [Test]
    procedure Build_GenericProjectWithoutData_EmitsFoggedPlaceholder;
    [Test]
    procedure Scan_IgnoresAsWishDirectory_CaseInsensitive;
    [Test]
    procedure MakeEvidenceForFile_CalculatesHash_Lines_And_Excerpt;
    [Test]
    procedure BuildFromScan_PopulatesEvidenceWithNonEmptyHashAndLines;
  end;

implementation

function NewTreeBuilderTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-treebuilder-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

procedure TTreeBuilderDataTests.Build_GenericProject_InfersDataEntities;
var
  LDir: string;
  LScan: TAsWishScanService;
  LBuilder: TAsWishTreeBuilder;
  LFoundEntity, LFoundField: Boolean;
  LNode: TSpecNode;
begin
  LDir := NewTreeBuilderTempDir;
  LScan := TAsWishScanService.Create;
  LBuilder := TAsWishTreeBuilder.Create;
  try
    TDirectory.CreateDirectory(TPath.Combine(LDir, 'models'));
    TDirectory.CreateDirectory(TPath.Combine(LDir, 'data'));
    TFile.WriteAllText(TPath.Combine(LDir, 'models/user.ts'),
      'export interface User {' + sLineBreak +
      '  id: string;' + sLineBreak +
      '  displayName: string;' + sLineBreak +
      '}' + sLineBreak, TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(LDir, 'data/users.json'),
      '{"profiles":[{"email":"Ada"}]}', TEncoding.UTF8);

    LScan.ScanDirectory(LDir);
    LBuilder.BuildFromScan(LScan, 'Demo', LDir);

    LFoundEntity := False;
    LFoundField := False;
    for LNode in LBuilder.DataNodes do
    begin
      if (LNode.Kind = 'entity') and SameText(LNode.Title, 'User') then
        LFoundEntity := True;
      if (LNode.Kind = 'field') and SameText(LNode.Title, 'id') and
         SameText(LNode.DataType, 'string') then
        LFoundField := True;
    end;

    Assert.IsTrue(LBuilder.DataNodes.Count >= 4,
      'generic data inference should emit root, entity, and fields');
    Assert.IsTrue(LFoundEntity, 'type definition should produce a data entity');
    Assert.IsTrue(LFoundField, 'type definition fields should be retained');
  finally
    LBuilder.Free;
    LScan.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTreeBuilderDataTests.Build_GenericProjectWithoutData_EmitsFoggedPlaceholder;
var
  LDir: string;
  LScan: TAsWishScanService;
  LBuilder: TAsWishTreeBuilder;
  LRoot, LPlaceholder: TSpecNode;
begin
  LDir := NewTreeBuilderTempDir;
  LScan := TAsWishScanService.Create;
  LBuilder := TAsWishTreeBuilder.Create;
  try
    TDirectory.CreateDirectory(LDir);
    TFile.WriteAllText(TPath.Combine(LDir, 'README.md'), '# Demo', TEncoding.UTF8);

    LScan.ScanDirectory(LDir);
    LBuilder.BuildFromScan(LScan, 'Demo', LDir);

    Assert.AreEqual<Integer>(2, LBuilder.DataNodes.Count,
      'fallback should contain a data root and one placeholder');
    LRoot := LBuilder.DataNodes[0];
    LPlaceholder := LBuilder.DataNodes[1];
    Assert.AreEqual(ttData, LRoot.Tree);
    Assert.AreEqual('', LRoot.ParentId);
    Assert.IsTrue(LRoot.HasFogState);
    Assert.AreEqual(fsMisty, LRoot.FogState,
      'the data root should advertise an unresolved but bounded gap');
    Assert.AreEqual(clLow, LPlaceholder.Confidence);
    Assert.IsTrue(LPlaceholder.HasFogState);
    Assert.AreEqual(fsFoggy, LPlaceholder.FogState);
    Assert.AreEqual(LRoot.Id, LPlaceholder.ParentId);
  finally
    LBuilder.Free;
    LScan.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTreeBuilderDataTests.Scan_IgnoresAsWishDirectory_CaseInsensitive;
var
  LDir: string;
  LScan: TAsWishScanService;
begin
  LDir := NewTreeBuilderTempDir;
  LScan := TAsWishScanService.Create;
  try
    TDirectory.CreateDirectory(LDir);
    TFile.WriteAllText(TPath.Combine(LDir, 'Main.pas'), 'unit Main; interface implementation end.', TEncoding.UTF8);

    // Create .AsWish and .aswish directory structures with internal files
    TDirectory.CreateDirectory(TPath.Combine(LDir, '.AsWish'));
    TDirectory.CreateDirectory(TPath.Combine(LDir, '.AsWish\snapshots'));
    TFile.WriteAllText(TPath.Combine(LDir, '.AsWish\project-spec.yaml'), 'name: test', TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(LDir, '.AsWish\snapshots\view-tree.yaml'), 'tree: view', TEncoding.UTF8);

    LScan.ScanDirectory(LDir);

    // Only Main.pas should be recognized as a user project file, .AsWish files must be ignored
    Assert.AreEqual<Integer>(1, LScan.CategoryCount(fcCode),
      'ScanDirectory must ignore files inside .AsWish regardless of letter casing');
    Assert.AreEqual<Integer>(1, LScan.CategoryCount(fcIgnored),
      '.AsWish directory should be recorded as fcIgnored');
    var LCodeFiles := LScan.GetFilesByCategory(fcCode);
    Assert.AreEqual<Integer>(1, Length(LCodeFiles));
    Assert.AreEqual('Main.pas', LCodeFiles[0]);
  finally
    LScan.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTreeBuilderDataTests.MakeEvidenceForFile_CalculatesHash_Lines_And_Excerpt;
var
  LDir: string;
  LBuilder: TAsWishTreeBuilder;
  LEv: TSpecEvidence;
  LContent: string;
begin
  LDir := NewTreeBuilderTempDir;
  LBuilder := TAsWishTreeBuilder.Create;
  try
    TDirectory.CreateDirectory(LDir);
    LContent :=
      'unit SampleOrder;' + sLineBreak +
      'interface' + sLineBreak +
      'type' + sLineBreak +
      '  TSampleOrder = class' + sLineBreak +
      '  end;' + sLineBreak +
      'implementation' + sLineBreak +
      'end.' + sLineBreak;
    TFile.WriteAllText(TPath.Combine(LDir, 'SampleOrder.pas'), LContent, TEncoding.UTF8);

    LBuilder.ProjectRootPath := LDir;
    LEv := LBuilder.MakeEvidenceForFile('SampleOrder.pas');

    Assert.AreEqual('ev-sampleorder-pas', LEv.Id);
    Assert.IsNotEmpty(LEv.SourceFileHash, 'SourceFileHash must not be empty');
    Assert.AreEqual<Integer>(64, Length(LEv.SourceFileHash), 'SourceFileHash must be 64-char sha256');
    Assert.AreEqual('1-7', LEv.Lines, 'Lines must match file line count 1-N');
    Assert.AreEqual('unit SampleOrder;', LEv.Excerpt, 'Excerpt must capture first non-empty line');
    Assert.IsFalse(LEv.ExcerptTruncated);
    Assert.IsNotEmpty(LEv.ContentHash, 'ContentHash must not be empty');
    Assert.AreEqual<Integer>(64, Length(LEv.ContentHash), 'ContentHash must be 64-char sha256');
  finally
    LBuilder.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTreeBuilderDataTests.BuildFromScan_PopulatesEvidenceWithNonEmptyHashAndLines;
var
  LDir: string;
  LScan: TAsWishScanService;
  LBuilder: TAsWishTreeBuilder;
  LEv: TSpecEvidence;
begin
  LDir := NewTreeBuilderTempDir;
  LScan := TAsWishScanService.Create;
  LBuilder := TAsWishTreeBuilder.Create;
  try
    TDirectory.CreateDirectory(LDir);
    TDirectory.CreateDirectory(TPath.Combine(LDir, 'docs'));
    TDirectory.CreateDirectory(TPath.Combine(LDir, 'src'));

    TFile.WriteAllText(TPath.Combine(LDir, 'docs\01_req.md'),
      '# Requirements' + sLineBreak +
      'Must process payments.' + sLineBreak +
      '## SubRequirement' + sLineBreak +
      'Must record audit.' + sLineBreak, TEncoding.UTF8);

    TFile.WriteAllText(TPath.Combine(LDir, 'src\App.pas'),
      'unit App;' + sLineBreak +
      'interface' + sLineBreak +
      'type' + sLineBreak +
      '  TAppEntity = class' + sLineBreak +
      '  published' + sLineBreak +
      '    Title: string;' + sLineBreak +
      '  end;' + sLineBreak +
      'implementation' + sLineBreak +
      'end.' + sLineBreak, TEncoding.UTF8);

    TFile.WriteAllText(TPath.Combine(LDir, 'src\MainForm.dfm'),
      'object MainForm: TMainForm' + sLineBreak +
      '  Caption = ''Main''' + sLineBreak +
      'end' + sLineBreak, TEncoding.UTF8);

    LScan.ScanDirectory(LDir);
    LBuilder.BuildFromScan(LScan, 'DemoProject', LDir);

    Assert.IsTrue(LBuilder.EvidenceList.Count > 0, 'EvidenceList must contain items');

    for LEv in LBuilder.EvidenceList do
    begin
      Assert.IsNotEmpty(LEv.SourceFileHash,
        'Every evidence item must have a non-empty SourceFileHash (path: ' + LEv.Path + ')');
      Assert.AreEqual<Integer>(64, Length(LEv.SourceFileHash),
        'SourceFileHash must be 64-char SHA256 hex');
      Assert.IsNotEmpty(LEv.Lines,
        'Every evidence item must have a non-empty Lines range (path: ' + LEv.Path + ')');
      Assert.IsTrue(LEv.Lines.Contains('-'),
        'Lines must follow start-end format: ' + LEv.Lines);
      Assert.IsNotEmpty(LEv.Excerpt,
        'Every evidence item must have a non-empty Excerpt');
      Assert.AreNotEqual('File: ' + LEv.Path, LEv.Excerpt,
        'Excerpt must not be a dead path restatement: ' + LEv.Excerpt);
      Assert.IsNotEmpty(LEv.ContentHash,
        'Every evidence item must have a non-empty ContentHash');
      Assert.AreEqual<Integer>(64, Length(LEv.ContentHash),
        'ContentHash must be 64-char SHA256 hex');
    end;
  finally
    LBuilder.Free;
    LScan.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTreeBuilderDataTests);

end.
