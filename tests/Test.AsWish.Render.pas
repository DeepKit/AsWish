{ ============================================================================
  Test.AsWish.Render

  Verifies that the data projection is rendered as a first-class review page
  with its metadata and fog signal visible to a user.
  ============================================================================ }

unit Test.AsWish.Render;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  AsWish.Models,
  AsWish.Services.Render;

type
  [TestFixture]
  TRenderDataTreeTests = class
  public
    [Test]
    procedure Render_DataTree_ContainsNodeAndMetadata;
  end;

implementation

function NewRenderTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-render-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

procedure TRenderDataTreeTests.Render_DataTree_ContainsNodeAndMetadata;
var
  LDir, LHtml: string;
  LRender: TAsWishRenderService;
  LNodes: TList<TSpecNode>;
  LRoot, LNode: TSpecNode;
  LContent: string;
begin
  LDir := NewRenderTempDir;
  LRender := TAsWishRenderService.Create;
  LNodes := TList<TSpecNode>.Create;
  try
    LRoot := TSpecNode.MakeNew('data-demo', ttData, 'Demo Data', 'entity');
    LNode := TSpecNode.MakeNew('data-user', ttData, 'User', 'entity');
    LNode.ParentId := LRoot.Id;
    LNode.DataType := 'object';
    LNode.Persistence := 'db';
    LNode.FogState := fsFoggy;
    LNode.HasFogState := True;
    LRoot.Children := TArray<string>.Create(LNode.Id);
    LNodes.Add(LRoot);
    LNodes.Add(LNode);

    LRender.Initialize(LDir);
    LRender.RenderTree('data-tree', 'Data Tree', LNodes);

    LHtml := TPath.Combine(LDir, 'html\data-tree.html');
    Assert.IsTrue(TFile.Exists(LHtml), 'data-tree.html should be generated');
    LContent := TFile.ReadAllText(LHtml, TEncoding.UTF8);
    Assert.IsTrue(LContent.Contains('User'), 'render should contain the data node');
    Assert.IsTrue(LContent.Contains('badge-data-type'),
      'render should expose data type metadata');
    Assert.IsTrue(LContent.Contains('badge-persistence'),
      'render should expose persistence metadata');
    Assert.IsTrue(LContent.Contains('badge-fog-foggy'),
      'render should expose the data node fog state');
  finally
    LNodes.Free;
    LRender.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRenderDataTreeTests);

end.
