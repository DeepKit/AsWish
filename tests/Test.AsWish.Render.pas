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

  [TestFixture]
  TEvidencePageTests = class
  public
    [Test]
    procedure RenderEvidencePage_AnchorsEveryEntry_WithPathAndExcerpt;
    [Test]
    procedure RenderEvidencePage_EmptyCatalog_WritesNoEvidenceState;
    [Test]
    procedure RenderTree_EvidenceId_IsLink_WhenEvidencePageExists;
    [Test]
    procedure RenderTree_EvidenceId_StaysBare_WhenEvidencePageMissing;
  end;

implementation

function NewRenderTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-render-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

function MakeEvidence(const AId, APath, ALines, AExcerpt: string;
  const AReferencedBy: TArray<string>; const ANote: string = '';
  const AIsStale: Boolean = False): TSpecEvidence;
begin
  Result := Default(TSpecEvidence);
  Result.Id := AId;
  Result.SourceLayer := slImplementation;
  Result.Path := APath;
  Result.Lines := ALines;
  Result.Excerpt := AExcerpt;
  Result.Confidence := clHigh;
  Result.ReferencedBy := AReferencedBy;
  Result.Note := ANote;
  Result.IsStale := AIsStale;
end;

function MakeNodeWithRefs(const AId: string;
  const ARefIds: TArray<string>): TSpecNode;
begin
  Result := TSpecNode.MakeNew(AId, ttModule, AId + ' title', 'unit');
  SetLength(Result.SourceRefs, Length(ARefIds));
  for var I := 0 to High(ARefIds) do
  begin
    Result.SourceRefs[I].RefId := ARefIds[I];
    Result.SourceRefs[I].Relevance := 'primary';
  end;
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

procedure TEvidencePageTests.RenderEvidencePage_AnchorsEveryEntry_WithPathAndExcerpt;
var
  LDir, LHtml, LContent: string;
  LRender: TAsWishRenderService;
  LEvidence: TList<TSpecEvidence>;
begin
  LDir := NewRenderTempDir;
  LRender := TAsWishRenderService.Create;
  LEvidence := TList<TSpecEvidence>.Create;
  try
    LEvidence.Add(MakeEvidence('ev-src-a-pas-1_10', 'src/a.pas', '1-10',
      'unit a;', TArray<string>.Create('mod-a'), 'stale since last scan', True));
    LEvidence.Add(MakeEvidence('ev-src-b-pas-5_20', 'src/b.pas', '5-20',
      'unit b;', TArray<string>.Create('mod-a', 'mod-b')));

    LRender.Initialize(LDir);
    LRender.RenderEvidencePage(LEvidence);

    LHtml := TPath.Combine(LDir, 'html\evidence.html');
    Assert.IsTrue(TFile.Exists(LHtml), 'evidence.html should be generated');
    LContent := TFile.ReadAllText(LHtml, TEncoding.UTF8);

    Assert.IsTrue(LContent.Contains('id="ev-src-a-pas-1_10"'),
      'each evidence entry needs an anchor so tree-page ids resolve');
    Assert.IsTrue(LContent.Contains('id="ev-src-b-pas-5_20"'),
      'each evidence entry needs an anchor so tree-page ids resolve');
    Assert.IsTrue(LContent.Contains('src/a.pas'),
      'the evidence page must show the source path, not just the id');
    Assert.IsTrue(LContent.Contains('1-10'),
      'the evidence page must show the line range');
    Assert.IsTrue(LContent.Contains('unit a;'),
      'the evidence page must show the excerpt');
    Assert.IsTrue(LContent.Contains('stale since last scan'),
      'the evidence page must surface the note');
    Assert.IsTrue(LContent.Contains('mod-a, mod-b'),
      'the evidence page must show which nodes reference the evidence');
  finally
    LEvidence.Free;
    LRender.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TEvidencePageTests.RenderEvidencePage_EmptyCatalog_WritesNoEvidenceState;
var
  LDir, LHtml, LContent: string;
  LRender: TAsWishRenderService;
begin
  LDir := NewRenderTempDir;
  LRender := TAsWishRenderService.Create;
  try
    LRender.Initialize(LDir);
    LRender.RenderEvidencePage(nil);

    LHtml := TPath.Combine(LDir, 'html\evidence.html');
    Assert.IsTrue(TFile.Exists(LHtml), 'evidence.html should be generated');
    LContent := TFile.ReadAllText(LHtml, TEncoding.UTF8);
    Assert.IsTrue(LContent.Contains('>0<'),
      'an empty catalog must report zero entries rather than crashing');
  finally
    LRender.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TEvidencePageTests.RenderTree_EvidenceId_IsLink_WhenEvidencePageExists;
var
  LDir, LHtml, LContent: string;
  LRender: TAsWishRenderService;
  LNodes: TList<TSpecNode>;
  LEvidence: TList<TSpecEvidence>;
begin
  LDir := NewRenderTempDir;
  LRender := TAsWishRenderService.Create;
  LNodes := TList<TSpecNode>.Create;
  LEvidence := TList<TSpecEvidence>.Create;
  try
    LNodes.Add(MakeNodeWithRefs('mod-a', TArray<string>.Create('ev-src-a-pas-1_10')));

    LRender.Initialize(LDir);
    LRender.RenderEvidencePage(LEvidence);
    LRender.RenderTree('module-tree', 'Module Tree', LNodes);

    LHtml := TPath.Combine(LDir, 'html\module-tree.html');
    Assert.IsTrue(TFile.Exists(LHtml), 'module-tree.html should be generated');
    LContent := TFile.ReadAllText(LHtml, TEncoding.UTF8);

    Assert.IsTrue(LContent.Contains('href="evidence.html#ev-src-a-pas-1_10"'),
      'an evidence id in a tree page must resolve to its evidence entry');
    Assert.IsFalse(LContent.Contains('<span class="trust-item trust-ref">ev-src-'),
      'the bare non-clickable evidence code must not survive once the page exists');
  finally
    LEvidence.Free;
    LNodes.Free;
    LRender.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TEvidencePageTests.RenderTree_EvidenceId_StaysBare_WhenEvidencePageMissing;
var
  LDir, LHtml, LContent: string;
  LRender: TAsWishRenderService;
  LNodes: TList<TSpecNode>;
begin
  LDir := NewRenderTempDir;
  LRender := TAsWishRenderService.Create;
  LNodes := TList<TSpecNode>.Create;
  try
    LNodes.Add(MakeNodeWithRefs('mod-a', TArray<string>.Create('ev-src-a-pas-1_10')));

    LRender.Initialize(LDir);
    LRender.RenderTree('module-tree', 'Module Tree', LNodes);

    LHtml := TPath.Combine(LDir, 'html\module-tree.html');
    LContent := TFile.ReadAllText(LHtml, TEncoding.UTF8);

    Assert.IsTrue(LContent.Contains('<span class="trust-item trust-ref">ev-src-'),
      'without an evidence page the id must stay a bare code, never a dead link');
    Assert.IsFalse(LContent.Contains('href="evidence.html#'),
      'a tree page rendered in isolation must not link to a missing page');
  finally
    LNodes.Free;
    LRender.Free;
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRenderDataTreeTests);
  TDUnitX.RegisterTestFixture(TEvidencePageTests);

end.
