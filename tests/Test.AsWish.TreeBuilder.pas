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

initialization
  TDUnitX.RegisterTestFixture(TTreeBuilderDataTests);

end.
