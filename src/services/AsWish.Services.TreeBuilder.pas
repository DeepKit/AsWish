
{ ============================================================================
  AsWish.Services.TreeBuilder

  Builds the four projection trees from scan results without LLM.
  This provides "Level 0 Scanner" value: a starting structure that the
  user (or LLM) can refine.

  Module tree   ← from code files (one node per top-level package/dir)
  View tree     ← from UI files (.dfm/.html/etc)
  Function tree ← stub root plus document headings
  Data tree     ← Delphi published fields or generic data-source heuristics

  All generated nodes are marked status=candidate, source_layer=ai_inferred,
  confidence=low (since they're heuristic, not LLM-generated).
  ============================================================================ }

unit AsWish.Services.TreeBuilder;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.TextIO,
  AsWish.Services.Scan;

type
  TAsWishTreeBuilder = class(TInterfacedObject)
  private
    FFunctionNodes: TList<TSpecNode>;
    FModuleNodes: TList<TSpecNode>;
    FViewNodes: TList<TSpecNode>;
    FDataNodes: TList<TSpecNode>;
    FEvidenceList: TList<TSpecEvidence>;
    FProjectRootPath: string;
    FUsedIds: TDictionary<string, Integer>;
    FUsedEvidenceIds: TDictionary<string, Integer>;
    FEvidenceIdCollisions: Integer;
    FNonUtf8Files: TStringList;
    function MakeSlug(const ATitle: string): string;
    /// <summary>Allocate an evidence id that is unique across the whole list.
    ///  The base id encodes the file and its line range, so the common case
    ///  (one file split into per-section evidence) is distinguishable by
    ///  construction. Two entries that still collide fall back to a numeric
    ///  suffix and are counted, because a collision means the caller asked for
    ///  the same file+range twice with different content.</summary>
    function UniqueEvidenceId(const APathSlug, ALines: string): string;
    /// <summary>Reads a text file as lines, never raising. Records a file that
    ///  had to be decoded as non-UTF-8 so the lossy read stays visible.</summary>
    function ReadLinesTolerant(const APath, ARelPath: string): TArray<string>;
    /// <summary>Same, but also reports which encoding actually decoded the file.</summary>
    function ReadLinesTolerantEnc(const APath, ARelPath: string;
      out AEncoding: TAsWishTextEncoding): TArray<string>;
    function GetNonUtf8Files: TArray<string>;
    procedure EnhanceFromDelphi(AScan: TAsWishScanService);
    /// <summary>Extract H1/H2 headings from docs markdown files into
    ///  function-tree children under the stub root.</summary>
    procedure BuildDocsFunctions(AScan: TAsWishScanService;
      const ARootId: string);
    procedure BuildDataTreeFromDelphi(AScan: TAsWishScanService);
    procedure BuildDataTreeFromGeneric(AScan: TAsWishScanService;
      const AProjectName: string);
    procedure SetGenStatusGenerated(ANodes: TList<TSpecNode>);
  public
    /// <summary>Allocate a node id that is unique across the whole tree and
    ///  that satisfies the validator's id rule. Callers pass a base that
    ///  already carries the tree prefix; the length cap is applied here,
    ///  because the prefix length is the caller's business and a cap on the
    ///  slug alone cannot see it. Public so a test can assert the generator
    ///  against the validator's own rule instead of a copied number.</summary>
    function UniqueId(const ABaseId: string): string;
    constructor Create;
    destructor Destroy; override;
    procedure BuildFromScan(AScan: TAsWishScanService;
      const AProjectName, AProjectRootPath: string);
    function FindNodeById(const ANodeId: string): TSpecNode;
    /// <summary>Fill in every node's Children from the ParentId recorded
    ///  across the list, so Children and ParentId cannot disagree. RenderTree
    ///  walks Children, so a node that only sets ParentId is invisible in the
    ///  HTML pages even though it is persisted.</summary>
    procedure LinkChildren(ANodes: TList<TSpecNode>);
    function MakeEvidenceForFile(const ARelPath: string): TSpecEvidence; overload;
    /// <summary>Same as the single-argument overload, but the caller already
    ///  knows which line range the evidence covers. The range must be passed in
    ///  rather than assigned afterwards, because the id is derived from it.</summary>
    function MakeEvidenceForFile(const ARelPath: string;
      const ALines: string): TSpecEvidence; overload;
    property ProjectRootPath: string read FProjectRootPath write FProjectRootPath;
    property FunctionNodes: TList<TSpecNode> read FFunctionNodes;
    property ModuleNodes: TList<TSpecNode> read FModuleNodes;
    property ViewNodes: TList<TSpecNode> read FViewNodes;
    property DataNodes: TList<TSpecNode> read FDataNodes;
    property EvidenceList: TList<TSpecEvidence> read FEvidenceList;
    /// <summary>How many times two evidence entries asked for the same
    ///  file+range. Zero means every id is unique by construction. A non-zero
    ///  value is reported by the scan rather than silently absorbed.</summary>
    property EvidenceIdCollisions: Integer read FEvidenceIdCollisions;
    /// <summary>Files whose bytes did not decode as UTF-8 and had to fall back
    ///  to the system code page. Non-empty means some excerpts are lossy; the
    ///  scan reports this instead of pretending the decode was clean.</summary>
    property NonUtf8Files: TArray<string> read GetNonUtf8Files;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.Character,
  System.Generics.Defaults,
  System.JSON,
  AsWish.Hash,
  AsWish.Delphi.DfmParser,
  AsWish.Delphi.PasParser,
  AsWish.Yaml.Parser;

constructor TAsWishTreeBuilder.Create;
begin
  inherited Create;
  FFunctionNodes := TList<TSpecNode>.Create;
  FModuleNodes := TList<TSpecNode>.Create;
  FViewNodes := TList<TSpecNode>.Create;
  FDataNodes := TList<TSpecNode>.Create;
  FEvidenceList := TList<TSpecEvidence>.Create;
  FUsedIds := TDictionary<string, Integer>.Create;
  FUsedEvidenceIds := TDictionary<string, Integer>.Create;
  FEvidenceIdCollisions := 0;
  FNonUtf8Files := TStringList.Create;
  FNonUtf8Files.Sorted := True;
  FNonUtf8Files.Duplicates := TDuplicates.dupIgnore;
end;

destructor TAsWishTreeBuilder.Destroy;
begin
  FFunctionNodes.Free;
  FModuleNodes.Free;
  FViewNodes.Free;
  FDataNodes.Free;
  FEvidenceList.Free;
  FUsedIds.Free;
  FUsedEvidenceIds.Free;
  FNonUtf8Files.Free;
  inherited;
end;

function TAsWishTreeBuilder.GetNonUtf8Files: TArray<string>;
begin
  Result := FNonUtf8Files.ToStringArray;
end;

function TAsWishTreeBuilder.ReadLinesTolerant(const APath, ARelPath: string): TArray<string>;
var
  LEnc: TAsWishTextEncoding;
begin
  Result := ReadLinesTolerantEnc(APath, ARelPath, LEnc);
end;

function TAsWishTreeBuilder.ReadLinesTolerantEnc(const APath, ARelPath: string;
  out AEncoding: TAsWishTextEncoding): TArray<string>;
begin
  Result := ReadTextLinesTolerant(APath, AEncoding);
  // teUtf8Bom is still UTF-8; only a genuine code-page fallback is lossy.
  if (AEncoding = teAnsi) or (AEncoding = teUnknown) then
    FNonUtf8Files.Add(ARelPath);
end;

function TAsWishTreeBuilder.MakeSlug(const ATitle: string): string;
begin
  var LSb := TStringBuilder.Create;
  try
    var LLastDash := False;
    for var LCh in ATitle do
    begin
      if (LCh >= 'a') and (LCh <= 'z') then
      begin
        LSb.Append(LCh);
        LLastDash := False;
      end
      else if (LCh >= 'A') and (LCh <= 'Z') then
      begin
        LSb.Append(Char(Ord(LCh) + 32));
        LLastDash := False;
      end
      else if (LCh >= '0') and (LCh <= '9') then
      begin
        LSb.Append(LCh);
        LLastDash := False;
      end
      else if not LLastDash then
      begin
        LSb.Append('-');
        LLastDash := True;
      end;
    end;
    Result := LSb.ToString.Trim(['-']);
    if Result.Length > 40 then
      Result := Result.Substring(0, 40).Trim(['-']);
    if Result = '' then
      Result := 'unnamed';
  finally
    LSb.Free;
  end;
end;

function TAsWishTreeBuilder.UniqueId(const ABaseId: string): string;
var
  LExisting: Integer;
  LBase, LSuffix: string;
begin
  // The cap is enforced here on the finished id, not inside MakeSlug: callers
  // prepend their own prefix ('data-field-', 'mod-pkg-', ...), so a cap on the
  // slug alone still lets the total overflow the validator's limit. That drift
  // is what made 206 nodes fail validation on every DeepAxis scan.
  LBase := ABaseId;
  if LBase.Length > CAsWishMaxNodeIdLength then
    LBase := LBase.Substring(0, CAsWishMaxNodeIdLength).Trim(['-']);
  if LBase = '' then
    LBase := 'unnamed';

  if FUsedIds.TryGetValue(LBase, LExisting) then
  begin
    Inc(LExisting);
    FUsedIds[LBase] := LExisting;
  end
  else
  begin
    LExisting := 0;
    FUsedIds.Add(LBase, 0);
  end;

  if LExisting > 0 then
    LSuffix := '-' + IntToStr(LExisting)
  else
    LSuffix := '';

  if LSuffix = '' then
    Result := LBase
  else
    // Reserve room for the suffix so a disambiguated id also satisfies the cap.
    Result := LBase.Substring(0, CAsWishMaxNodeIdLength - LSuffix.Length)
      .Trim(['-']) + LSuffix;
end;

function TAsWishTreeBuilder.UniqueEvidenceId(const APathSlug, ALines: string): string;
var
  LBase: string;
  LExisting: Integer;
begin
  LBase := 'ev-' + APathSlug;
  if ALines <> '' then
    LBase := LBase + '-' + StringReplace(ALines, '-', '_', [rfReplaceAll]);

  if not FUsedEvidenceIds.TryGetValue(LBase, LExisting) then
  begin
    Result := LBase;
    FUsedEvidenceIds.Add(LBase, 0);
  end
  else
  begin
    Inc(FEvidenceIdCollisions);
    Result := LBase + '-' + IntToStr(LExisting + 1);
    FUsedEvidenceIds[LBase] := LExisting + 1;
  end;
end;

function TAsWishTreeBuilder.MakeEvidenceForFile(const ARelPath: string): TSpecEvidence;
begin
  Result := MakeEvidenceForFile(ARelPath, '');
end;

function TAsWishTreeBuilder.MakeEvidenceForFile(const ARelPath: string;
  const ALines: string): TSpecEvidence;
var
  LAbsPath: string;
  LLines: TArray<string>;
  LLineCount: Integer;
  LFirstLine: string;
  LEnc: TAsWishTextEncoding;
  I: Integer;
begin
  Result := Default(TSpecEvidence);
  Result.SourceLayer := slParsedFromA;
  Result.Path := ARelPath;
  // ALines (a section range) wins over the whole-file default computed below.
  Result.Lines := ALines;
  Result.Excerpt := '';
  Result.ExcerptTruncated := False;
  Result.Confidence := clHigh;
  Result.CreatedAt := Now;
  Result.UpdatedAt := Now;
  Result.IsStale := False;

  if TPath.IsPathRooted(ARelPath) then
    LAbsPath := ARelPath
  else if FProjectRootPath <> '' then
    LAbsPath := TPath.Combine(FProjectRootPath, StringReplace(ARelPath, '/', '\', [rfReplaceAll]))
  else
    LAbsPath := '';

  if (LAbsPath <> '') and TFile.Exists(LAbsPath) then
  begin
    Result.SourceFileHash := TSpecHash.FileSha256Hex(LAbsPath);
    try
      LLines := ReadLinesTolerantEnc(LAbsPath, ARelPath, LEnc);
      LLineCount := Length(LLines);
      if LLineCount > 0 then
      begin
        if ALines = '' then
          Result.Lines := Format('1-%d', [LLineCount]);
        LFirstLine := '';
        for I := 0 to High(LLines) do
        begin
          if LLines[I].Trim <> '' then
          begin
            LFirstLine := LLines[I].Trim;
            Break;
          end;
        end;

        if LFirstLine <> '' then
        begin
          if Length(LFirstLine) > 200 then
          begin
            Result.Excerpt := Copy(LFirstLine, 1, 200);
            Result.ExcerptTruncated := True;
          end
          else
            Result.Excerpt := LFirstLine;
        end
        else
          Result.Excerpt := ARelPath;
      end
      else
        Result.Lines := '1-1';

      // A code-page fallback means the excerpt is a best-effort decode. Say so
      // on the evidence itself rather than letting a lossy read look clean.
      if (LEnc = teAnsi) or (LEnc = teUnknown) then
        Result.Note := Format('decoded as %s, not utf8; excerpt may be lossy',
          [CAsWishTextEncodingNames[LEnc]]);
    except
      // The tolerant reader already absorbs decode failures; reaching here means
      // the hash or line-count step itself failed, so the excerpt is unproven.
      if Result.Lines = '' then
        Result.Lines := '1-1';
      if Result.Excerpt = '' then
        Result.Excerpt := ARelPath;
    end;
  end
  else
  begin
    Result.SourceFileHash := '';
    Result.Lines := '';
    Result.Excerpt := ARelPath;
  end;

  if Result.Excerpt <> '' then
    Result.ContentHash := TSpecHash.Sha256Hex(Result.Excerpt);

  // The id must be derived from the final line range: deriving it up front is
  // what let 91 per-section entries of one file share a single id.
  Result.Id := UniqueEvidenceId(MakeSlug(ARelPath), Result.Lines);
end;

function TAsWishTreeBuilder.FindNodeById(const ANodeId: string): TSpecNode;
begin
  Result := Default(TSpecNode);
  for var I := 0 to FFunctionNodes.Count - 1 do
    if FFunctionNodes[I].Id = ANodeId then Exit(FFunctionNodes[I]);
  for var I := 0 to FModuleNodes.Count - 1 do
    if FModuleNodes[I].Id = ANodeId then Exit(FModuleNodes[I]);
  for var I := 0 to FViewNodes.Count - 1 do
    if FViewNodes[I].Id = ANodeId then Exit(FViewNodes[I]);
  for var I := 0 to FDataNodes.Count - 1 do
    if FDataNodes[I].Id = ANodeId then Exit(FDataNodes[I]);
end;

procedure TAsWishTreeBuilder.BuildFromScan(AScan: TAsWishScanService;
  const AProjectName, AProjectRootPath: string);
begin
  FFunctionNodes.Clear;
  FModuleNodes.Clear;
  FViewNodes.Clear;
  FDataNodes.Clear;
  FEvidenceList.Clear;
  FUsedIds.Clear;
  FUsedEvidenceIds.Clear;
  FEvidenceIdCollisions := 0;
  FProjectRootPath := AProjectRootPath;

  // ============ Function Tree: stub root + doc-derived placeholders ============
  var LRootSlug := MakeSlug(AProjectName);
  if LRootSlug = '' then LRootSlug := 'project';

  // The root id must go through UniqueId so it is reserved before any child
  // claims a slug. Building it by hand let a doc heading whose slug matches the
  // project name take the very same id: RenderTree then resolved that id to the
  // child instead of the root, and every sibling was orphaned out of the page
  // (201 persisted function nodes, 1 rendered).
  var LFuncRootId := UniqueId('func-' + LRootSlug);
  var LFuncRoot := TSpecNode.MakeNew(LFuncRootId, ttFunction,
    AProjectName, 'capability');
  LFuncRoot.Summary := 'Project root capability (stub - run LLM generation for semantic content)';
  LFuncRoot.Status := nsCandidate;
  LFuncRoot.Confidence := clLow;
  LFuncRoot.SourceLayer := slAiInferred;
  // Mark the function root as deepest fog: it is a stub awaiting LLM generation,
  // so the project starts inside the fog and converges to clear as the LLM
  // fills in semantic content. Without this the Fog Map is empty on first scan.
  LFuncRoot.FogState := fsUnknownUnknowns;
  LFuncRoot.HasFogState := True;
  LFuncRoot.ContentHash := TSpecHash.NodeContentHash(LFuncRoot);
  LFuncRoot.RelationHash := TSpecHash.NodeRelationHash(LFuncRoot);
  FFunctionNodes.Add(LFuncRoot);

  // Doc-derived function nodes: H1/H2 headings from docs markdown become
  // capability/feature children, so the function tree is not just a stub.
  BuildDocsFunctions(AScan, LFuncRootId);

  // ============ Module Tree: hierarchical directory structure ============
  // Every directory that contains code files (plus all its ancestors)
  // becomes a package node; parents are assigned deterministically:
  // directories are sorted by depth so a parent is always created before
  // its children (multi-LLM review: TDictionary iteration order is not
  // guaranteed, so a naive single pass could hang children on the root).
  var LDirSet := TDictionary<string, Boolean>.Create;
  try
    for var LFile in AScan.GetFilesByCategory(fcCode) do
    begin
      // Scan stores relative paths with forward slashes; ExtractFilePath
      // only understands backslashes on Windows, so split manually.
      var LPos := LFile.LastIndexOf('/');
      while LPos > 0 do
      begin
        var LDir := LFile.Substring(0, LPos);
        LDirSet.AddOrSetValue(LDir, True);
        LPos := LDir.LastIndexOf('/');
      end;
    end;

    var LModRootId := UniqueId('mod-' + LRootSlug);
    var LModRoot := TSpecNode.MakeNew(LModRootId, ttModule,
      AProjectName + ' Modules', 'package');
    LModRoot.Summary := 'Module structure derived from directory layout';
    LModRoot.Status := nsCandidate;
    LModRoot.Confidence := clMedium;
    LModRoot.SourceLayer := slParsedFromA;

    // Depth-ordered stable list of directories (shallowest first).
    var LDirList := TList<string>.Create;
    try
      for var LDir in LDirSet.Keys do
        LDirList.Add(LDir);
      LDirList.Sort(
        TComparer<string>.Construct(
          function(const A, B: string): Integer
          begin
            var LD := Length(A) - Length(B);
            if LD <> 0 then Exit(LD);
            Result := CompareText(A, B);
          end));
      // NOTE: depth by string length is a safe proxy for '/' count because
      // every ancestor is strictly shorter than its descendant.

      var LDirNodes := TDictionary<string, string>.Create;
      try
        // Pass 1: create every directory node (parent resolved later).
        for var LDir in LDirList do
        begin
          var LDirSlug := MakeSlug(LDir);
          var LDirId := UniqueId('mod-' + LDirSlug);
          var LDirNode := TSpecNode.MakeNew(LDirId, ttModule, LDir, 'package');
          LDirNode.Status := nsCandidate;
          LDirNode.Confidence := clMedium;
          LDirNode.SourceLayer := slParsedFromA;
          LDirNode.Summary := 'Module rooted at ' + LDir + '/';

          // Evidence: first code file under this directory.
          for var LFile in AScan.GetFilesByCategory(fcCode) do
            if LFile.StartsWith(LDir + '/') then
            begin
              var LEv := MakeEvidenceForFile(LFile);
              LEv.Excerpt := 'Directory: ' + LDir;
              LEv.ContentHash := TSpecHash.Sha256Hex(LEv.Excerpt);
              FEvidenceList.Add(LEv);
              var LRef: TSourceRef;
              LRef.RefId := LEv.Id;
              LRef.Relevance := 'primary';
              LDirNode.SourceRefs := [LRef];
              Break;
            end;

          LDirNode.ContentHash := TSpecHash.NodeContentHash(LDirNode);
          LDirNode.RelationHash := TSpecHash.NodeRelationHash(LDirNode);
          LDirNodes.Add(LDir, LDirId);
          FModuleNodes.Add(LDirNode);
        end;

        // Pass 2: assign parents (ancestors are guaranteed present).
        for var LDir in LDirList do
        begin
          var LParentId := LModRootId;
          var LPos := LDir.LastIndexOf('/');
          while LPos > 0 do
          begin
            var LParentDir := LDir.Substring(0, LPos);
            if LDirNodes.TryGetValue(LParentDir, LParentId) then Break;
            LPos := LParentDir.LastIndexOf('/');
          end;
          var LIdx := -1;
          for var I := 0 to FModuleNodes.Count - 1 do
            if FModuleNodes[I].Id = LDirNodes[LDir] then
            begin
              LIdx := I;
              Break;
            end;
          if LIdx >= 0 then
          begin
            var LNode := FModuleNodes[LIdx];
            LNode.ParentId := LParentId;
            LNode.ContentHash := TSpecHash.NodeContentHash(LNode);
            LNode.RelationHash := TSpecHash.NodeRelationHash(LNode);
            FModuleNodes[LIdx] := LNode;
          end;
        end;
      finally
        LDirNodes.Free;
      end;

      LModRoot.ContentHash := TSpecHash.NodeContentHash(LModRoot);
      LModRoot.RelationHash := TSpecHash.NodeRelationHash(LModRoot);
      FModuleNodes.Insert(0, LModRoot);  // root first
    finally
      LDirList.Free;
    end;
  finally
    LDirSet.Free;
  end;

  // ============ View Tree: from UI files ============
  var LUIFiles := AScan.GetFilesByCategory(fcUI);
  if Length(LUIFiles) > 0 then
  begin
    var LViewRootId := UniqueId('view-' + LRootSlug);
    var LViewRoot := TSpecNode.MakeNew(LViewRootId, ttView,
      AProjectName + ' Views', 'application');
    LViewRoot.Summary := 'UI structure derived from UI files';
    LViewRoot.Status := nsCandidate;
    LViewRoot.Confidence := clMedium;
    LViewRoot.SourceLayer := slParsedFromA;

    var LViewChildren: TList<string>;
    LViewChildren := TList<string>.Create;
    try
      // Limit to first 20 UI files to avoid bloat in P0
      var LCount := Length(LUIFiles);
      if LCount > 20 then LCount := 20;

      for var I := 0 to LCount - 1 do
      begin
        var LFile := LUIFiles[I];
        var LFileName := TPath.GetFileNameWithoutExtension(LFile);
        var LSlug := MakeSlug(LFileName);
        var LId := UniqueId('view-' + LSlug);

        // Determine view kind by extension
        var LExt := LowerCase(TPath.GetExtension(LFile));
        var LKind := 'window';
        if (LExt = '.dfm') or (LExt = '.fmx') then
          LKind := 'window'
        else if LExt = '.html' then
          LKind := 'page'
        else if (LExt = '.vue') or (LExt = '.jsx') or (LExt = '.tsx') then
          LKind := 'page'
        else if (LExt = '.xaml') then
          LKind := 'window';

        var LViewNode := TSpecNode.MakeNew(LId, ttView, LFileName, LKind);
        LViewNode.ParentId := LViewRootId;
        LViewNode.Summary := 'View defined in ' + LFile;
        LViewNode.Status := nsCandidate;
        LViewNode.Confidence := clMedium;
        LViewNode.SourceLayer := slParsedFromA;

        var LEv := MakeEvidenceForFile(LFile);
        FEvidenceList.Add(LEv);

        var LRef: TSourceRef;
        LRef.RefId := LEv.Id;
        LRef.Relevance := 'primary';
        LViewNode.SourceRefs := [LRef];

        LViewNode.ContentHash := TSpecHash.NodeContentHash(LViewNode);
        LViewNode.RelationHash := TSpecHash.NodeRelationHash(LViewNode);
        FViewNodes.Add(LViewNode);
        LViewChildren.Add(LId);
      end;

      LViewRoot.Children := LViewChildren.ToArray;
      LViewRoot.ContentHash := TSpecHash.NodeContentHash(LViewRoot);
      LViewRoot.RelationHash := TSpecHash.NodeRelationHash(LViewRoot);
      FViewNodes.Insert(0, LViewRoot);
    finally
      LViewChildren.Free;
    end;
  end;

  // ============ Delphi-specific enhancement ============
  EnhanceFromDelphi(AScan);

  // ============ Data Tree: Delphi fields or generic project sources ============
  var LHasDelphi := False;
  var LHasNonDelphiCode := False;
  for var LEntry in AScan.Results do
    if LEntry.Category = fcCode then
    begin
      var LExt := LowerCase(TPath.GetExtension(LEntry.RelativePath));
      if (LExt = '.pas') or (LExt = '.dpr') then
        LHasDelphi := True
      else
        LHasNonDelphiCode := True;
    end;
  // A mixed repository must not discard its non-Delphi models/configuration
  // merely because one legacy Pascal project is present.
  if LHasDelphi and not LHasNonDelphiCode then
    BuildDataTreeFromDelphi(AScan)
  else
    BuildDataTreeFromGeneric(AScan, AProjectName);

  // ============ Derive Children from ParentId ============
  LinkChildren(FFunctionNodes);
  LinkChildren(FModuleNodes);
  LinkChildren(FViewNodes);
  LinkChildren(FDataNodes);

  // ============ Set gen_status = generated for all scan-built nodes ============
  SetGenStatusGenerated(FFunctionNodes);
  SetGenStatusGenerated(FModuleNodes);
  SetGenStatusGenerated(FViewNodes);
  SetGenStatusGenerated(FDataNodes);
end;

procedure TAsWishTreeBuilder.BuildDocsFunctions(
  AScan: TAsWishScanService; const ARootId: string);
var
  LCount: Integer;
begin
  LCount := 0;
  for var LFile in AScan.GetFilesByCategory(fcDocuments) do
  begin
    var LExt := LowerCase(TPath.GetExtension(LFile));
    if (LExt <> '.md') and (LExt <> '.txt') and (LExt <> '.rst') then Continue;

    var LFullPath := TPath.Combine(FProjectRootPath, LFile.Replace('/', '\\'));
    if not TFile.Exists(LFullPath) then Continue;

      var LLines := ReadLinesTolerant(LFullPath, LFile);
      for var LI := 0 to High(LLines) do
      begin
        var LL := LLines[LI];
        var LTrimmed := LL.Trim;
        if (Length(LTrimmed) > 0) and
           (LTrimmed.StartsWith('# ') or LTrimmed.StartsWith('## ')) then
        begin
          var LTitle := LTrimmed;
          if LTitle.StartsWith('## ') then LTitle := LTitle.Substring(3).Trim
          else if LTitle.StartsWith('# ') then LTitle := LTitle.Substring(2).Trim;
          if LTitle = '' then Continue;

          var LSlug := MakeSlug(LTitle);
          if LSlug = '' then LSlug := 'doc-' + LCount.ToString;
          var LId := UniqueId('func-' + LSlug);

          var LNode := TSpecNode.MakeNew(LId, ttFunction, LTitle, 'feature');
          LNode.ParentId := ARootId;
          LNode.Summary := 'Requirement extracted from ' + LFile;
          LNode.Status := nsCandidate;
          LNode.Confidence := clLow;
          LNode.SourceLayer := slParsedFromA;

          var LStartLine := LI + 1;
          var LEndLine := Length(LLines);
          for var LJ := LI + 1 to High(LLines) do
          begin
            var LNextTrim := LLines[LJ].Trim;
            if (Length(LNextTrim) > 0) and
               (LNextTrim.StartsWith('# ') or LNextTrim.StartsWith('## ')) then
            begin
              LEndLine := LJ;
              Break;
            end;
          end;
          if LEndLine < LStartLine then LEndLine := LStartLine;

          var LEv := MakeEvidenceForFile(LFile,
            Format('%d-%d', [LStartLine, LEndLine]));
          LEv.Excerpt := LTrimmed;
          LEv.ExcerptTruncated := Length(LTrimmed) > 200;
          if Length(LTrimmed) > 200 then
            LEv.Excerpt := Copy(LTrimmed, 1, 200);
          LEv.ContentHash := TSpecHash.Sha256Hex(LEv.Excerpt);
          FEvidenceList.Add(LEv);
          var LRef: TSourceRef;
          LRef.RefId := LEv.Id;
          LRef.Relevance := 'primary';
          LNode.SourceRefs := [LRef];

          LNode.ContentHash := TSpecHash.NodeContentHash(LNode);
          LNode.RelationHash := TSpecHash.NodeRelationHash(LNode);
          FFunctionNodes.Add(LNode);
          Inc(LCount);
          if LCount >= 200 then Break;
        end;
        if LCount >= 200 then Break;
      end;
      if LCount >= 200 then Break;
    end;
end;

procedure TAsWishTreeBuilder.LinkChildren(ANodes: TList<TSpecNode>);
var
  LGroups: TDictionary<string, TList<string>>;
  LPair: TPair<string, TList<string>>;
begin
  LGroups := TDictionary<string, TList<string>>.Create;
  try
    for var LNode in ANodes do
      // A self-parent would make RenderNode recurse into itself forever; that
      // id collision is what produced the orphaned trees this pass fixes.
      if (LNode.ParentId <> '') and (LNode.ParentId <> LNode.Id) then
      begin
        if not LGroups.ContainsKey(LNode.ParentId) then
          LGroups.Add(LNode.ParentId, TList<string>.Create);
        LGroups[LNode.ParentId].Add(LNode.Id);
      end;

    for var LI := 0 to ANodes.Count - 1 do
    begin
      var LNode := ANodes[LI];
      var LKids: TList<string>;
      if LGroups.TryGetValue(LNode.Id, LKids) then
      begin
        LNode.Children := LKids.ToArray;
        LNode.ContentHash := TSpecHash.NodeContentHash(LNode);
        LNode.RelationHash := TSpecHash.NodeRelationHash(LNode);
        ANodes[LI] := LNode;
      end;
    end;
  finally
    for LPair in LGroups do
      LPair.Value.Free;
    LGroups.Free;
  end;
end;

procedure TAsWishTreeBuilder.SetGenStatusGenerated(ANodes: TList<TSpecNode>);
begin
  for var I := 0 to ANodes.Count - 1 do
  begin
    var LNode := ANodes[I];
    LNode.GenStatus := gsGenerated;
    ANodes[I] := LNode;
  end;
end;

procedure TAsWishTreeBuilder.EnhanceFromDelphi(AScan: TAsWishScanService);
begin
  // Only apply if we have .pas or .dfm files
  var LHasDelphi := False;
  for var LFile in AScan.GetFilesByCategory(fcCode) do
    if LFile.EndsWith('.pas') or LFile.EndsWith('.dpr') then
    begin
      LHasDelphi := True;
      Break;
    end;
  if not LHasDelphi then Exit;

  // Parse a sample of .pas files (limit to avoid bloat)
  var LPasParser := TPasParser.Create;
  try
    var LCount := 0;
    for var LFile in AScan.GetFilesByCategory(fcCode) do
    begin
      if LCount >= 30 then Break; // limit P0
      if not (LFile.EndsWith('.pas') or LFile.EndsWith('.dpr')) then Continue;

      var LFullPath := TPath.Combine(FProjectRootPath, LFile.Replace('/', '\'));
      if not TFile.Exists(LFullPath) then Continue;

      var LInfo := LPasParser.ParseFile(LFullPath);
      if LInfo = nil then Continue;
      try
        if LInfo.UnitName = '' then Continue;

        var LUnitSlug := MakeSlug(LInfo.UnitName);
        var LUnitId := UniqueId('mod-unit-' + LUnitSlug);

        var LUnitNode := TSpecNode.MakeNew(LUnitId, ttModule, LInfo.UnitName, 'unit');
        LUnitNode.Summary := 'Pascal unit declared in ' + LFile;
        LUnitNode.Status := nsCandidate;
        LUnitNode.Confidence := clHigh;
        LUnitNode.SourceLayer := slParsedFromA;

        // Add evidence
        var LEv := MakeEvidenceForFile(LFile);
        LEv.Excerpt := 'unit ' + LInfo.UnitName + ';';
        LEv.ContentHash := TSpecHash.Sha256Hex(LEv.Excerpt);
        FEvidenceList.Add(LEv);
        var LRef: TSourceRef;
        LRef.RefId := LEv.Id;
        LRef.Relevance := 'primary';
        LUnitNode.SourceRefs := [LRef];

        // Add classes/interfaces as related items
        var LRelMods: TList<string>;
        LRelMods := TList<string>.Create;
        try
          for var LItem in LInfo.Items do
          begin
            var LItemKindStr: string;
            if LItem.Kind = pikInterface then LItemKindStr := 'interface' else LItemKindStr := 'class';
            var LItemSlug := MakeSlug(LItem.Name);
            var LItemId := UniqueId('mod-' + LItemKindStr + '-' + LItemSlug);

            var LItemNode := TSpecNode.MakeNew(LItemId, ttModule, LItem.Name, LItemKindStr);
            LItemNode.ParentId := LUnitId;
            if LItem.AncestorOrInterface <> '' then
              LItemNode.Summary := 'Inherits from ' + LItem.AncestorOrInterface
            else
              LItemNode.Summary := LItem.Name + ' declaration in ' + LInfo.UnitName;
            LItemNode.Status := nsCandidate;
            LItemNode.Confidence := clHigh;
            LItemNode.SourceLayer := slParsedFromA;
            LItemNode.SourceRefs := [LRef];
            LItemNode.ContentHash := TSpecHash.NodeContentHash(LItemNode);
            LItemNode.RelationHash := TSpecHash.NodeRelationHash(LItemNode);
            FModuleNodes.Add(LItemNode);
            LRelMods.Add(LItemId);
          end;
          LUnitNode.Children := LRelMods.ToArray;
        finally
          LRelMods.Free;
        end;

        LUnitNode.ContentHash := TSpecHash.NodeContentHash(LUnitNode);
        LUnitNode.RelationHash := TSpecHash.NodeRelationHash(LUnitNode);
        FModuleNodes.Add(LUnitNode);
        Inc(LCount);
      finally
        LInfo.Free;
      end;
    end;
  finally
    LPasParser.Free;
  end;

  // Parse DFM files for view tree
  var LDfmParser := TDfmParser.Create;
  try
    var LCount := 0;
    for var LFile in AScan.GetFilesByCategory(fcUI) do
    begin
      if LCount >= 20 then Break;
      if not LFile.EndsWith('.dfm') then Continue;

      var LFullPath := TPath.Combine(FProjectRootPath, LFile.Replace('/', '\'));
      if not TFile.Exists(LFullPath) then Continue;

      var LDfm := LDfmParser.ParseFile(LFullPath);
      if LDfm = nil then Continue;
      try
        if LDfm.Name = '' then Continue;

        var LFormSlug := MakeSlug(LDfm.Name);
        var LFormId := UniqueId('view-form-' + LFormSlug);

        var LFormNode := TSpecNode.MakeNew(LFormId, ttView, LDfm.Name, 'window');
        if LDfm.Caption <> '' then
          LFormNode.Summary := 'Form: ' + LDfm.Caption
        else
          LFormNode.Summary := LDfm.ClassName + ' defined in ' + LFile;
        LFormNode.Status := nsCandidate;
        LFormNode.Confidence := clHigh;
        LFormNode.SourceLayer := slParsedFromA;

        var LEv := MakeEvidenceForFile(LFile);
        LEv.Excerpt := 'object ' + LDfm.Name + ': ' + LDfm.ClassName;
        LEv.ContentHash := TSpecHash.Sha256Hex(LEv.Excerpt);
        FEvidenceList.Add(LEv);
        var LRef: TSourceRef;
        LRef.RefId := LEv.Id;
        LRef.Relevance := 'primary';
        LFormNode.SourceRefs := [LRef];

        // Add up to 30 child controls
        var LChildList: TList<string>;
        LChildList := TList<string>.Create;
        try
          var LCtrlCount := 0;
          for var LCtrl in LDfm.Children do
          begin
            if LCtrlCount >= 30 then Break;
            if LCtrl.Name = '' then Continue;
            var LCtrlSlug := MakeSlug(LCtrl.Name);
            var LCtrlId := UniqueId('view-ctrl-' + LCtrlSlug);

            var LCtrlNode := TSpecNode.MakeNew(LCtrlId, ttView, LCtrl.Name, 'control');
            LCtrlNode.ParentId := LFormId;
            if LCtrl.Caption <> '' then
              LCtrlNode.Summary := LCtrl.ClassName + ': "' + LCtrl.Caption + '"'
            else
              LCtrlNode.Summary := LCtrl.ClassName + ' control';
            LCtrlNode.Status := nsCandidate;
            LCtrlNode.Confidence := clHigh;
            LCtrlNode.SourceLayer := slParsedFromA;
            LCtrlNode.SourceRefs := [LRef];
            LCtrlNode.ContentHash := TSpecHash.NodeContentHash(LCtrlNode);
            LCtrlNode.RelationHash := TSpecHash.NodeRelationHash(LCtrlNode);
            FViewNodes.Add(LCtrlNode);
            LChildList.Add(LCtrlId);
            Inc(LCtrlCount);
          end;
          LFormNode.Children := LChildList.ToArray;
        finally
          LChildList.Free;
        end;

        LFormNode.ContentHash := TSpecHash.NodeContentHash(LFormNode);
        LFormNode.RelationHash := TSpecHash.NodeRelationHash(LFormNode);
        FViewNodes.Add(LFormNode);
        Inc(LCount);
      finally
        LDfm.Free;
      end;
    end;
  finally
    LDfmParser.Free;
  end;
end;

procedure TAsWishTreeBuilder.BuildDataTreeFromDelphi(AScan: TAsWishScanService);
var
  LPasParser: TPasParser;
  LEntitySlugs: TDictionary<string, Boolean>;
begin
  var LHasDelphi := False;
  for var LFile in AScan.GetFilesByCategory(fcCode) do
    if LFile.EndsWith('.pas') or LFile.EndsWith('.dpr') then
    begin
      LHasDelphi := True;
      Break;
    end;
  if not LHasDelphi then Exit;

  LEntitySlugs := TDictionary<string, Boolean>.Create;
  LPasParser := TPasParser.Create;
  try
    var LCount := 0;
    for var LFile in AScan.GetFilesByCategory(fcCode) do
    begin
      if LCount >= 30 then Break;
      if not (LFile.EndsWith('.pas') or LFile.EndsWith('.dpr')) then Continue;

      var LFullPath := TPath.Combine(FProjectRootPath, LFile.Replace('/', '\'));
      if not TFile.Exists(LFullPath) then Continue;

      var LInfo := LPasParser.ParseFile(LFullPath);
      if LInfo = nil then Continue;
      try
        // For each class, create an entity node and scan published fields
        for var LItem in LInfo.Items do
        begin
          if LItem.Kind <> pikClass then Continue;

          var LEntitySlug := MakeSlug(LItem.Name);
          if LEntitySlugs.ContainsKey(LEntitySlug) then Continue;
          LEntitySlugs.Add(LEntitySlug, True);

          var LEntityId := UniqueId('data-entity-' + LEntitySlug);
          var LEntityNode := TSpecNode.MakeNew(LEntityId, ttData,
            LItem.Name, 'entity');
          LEntityNode.Summary := 'Data entity from class ' + LItem.Name +
            ' in ' + LFile;
          LEntityNode.Status := nsCandidate;
          LEntityNode.Confidence := clMedium;
          LEntityNode.SourceLayer := slParsedFromA;

          var LLines := ReadLinesTolerant(LFullPath, LFile);
          var LClassStart := 1;
          var LClassEnd := Length(LLines);
          var LClassExcerpt := 'type ' + LItem.Name + ' = class';
          if Length(LLines) > 0 then
          begin
            for var LIdx := 0 to High(LLines) do
            begin
              var LLineTrim := LLines[LIdx].Trim;
              if (Pos(LItem.Name, LLineTrim) > 0) and (Pos('class', LLineTrim) > 0) then
              begin
                LClassStart := LIdx + 1;
                LClassExcerpt := LLineTrim;
                for var LEndIdx := LIdx + 1 to High(LLines) do
                begin
                  var LEndTrim := LLines[LEndIdx].Trim;
                  if (LEndTrim = 'end;') or LEndTrim.StartsWith('end;') then
                  begin
                    LClassEnd := LEndIdx + 1;
                    Break;
                  end;
                end;
                Break;
              end;
            end;
          end;

          var LClassLines := '';
          if LClassStart > 1 then
            LClassLines := Format('%d-%d', [LClassStart, LClassEnd]);
          var LEv := MakeEvidenceForFile(LFile, LClassLines);
          LEv.Excerpt := LClassExcerpt;
          LEv.ContentHash := TSpecHash.Sha256Hex(LEv.Excerpt);
          FEvidenceList.Add(LEv);
          var LRef: TSourceRef;
          LRef.RefId := LEv.Id;
          LRef.Relevance := 'primary';
          LEntityNode.SourceRefs := [LRef];

          // Scan published fields from source file
          var LFieldList: TList<string>;
          LFieldList := TList<string>.Create;
          try
            var LInPublished := False;
            var LFieldCount := 0;
            for var LI := 0 to High(LLines) do
            begin
              var LLine := LLines[LI].Trim;
              if LLine = '' then Continue;

              // Detect section boundaries
              if LLine.StartsWith('published') then
              begin
                LInPublished := True;
                Continue;
              end;
              if LLine.StartsWith('private') or LLine.StartsWith('protected') or
                 LLine.StartsWith('public') or LLine.StartsWith('strict private') or
                 LLine.StartsWith('strict protected') then
              begin
                LInPublished := False;
                Continue;
              end;
              if LLine.StartsWith('end;') then
              begin
                LInPublished := False;
                Continue;
              end;

              if not LInPublished then Continue;
              if LFieldCount >= 50 then Break;

              // Match field declarations: Name: Type;
              var LColonPos := LLine.IndexOf(':');
              if LColonPos < 0 then Continue;
              var LName := LLine.Substring(0, LColonPos).Trim;
              if LName = '' then Continue;
              // Skip property declarations, we want field declarations
              if LName.StartsWith('property ') then Continue;
              if LName.StartsWith('function ') then Continue;
              if LName.StartsWith('procedure ') then Continue;
              if LName.StartsWith('constructor ') then Continue;
              if LName.StartsWith('destructor ') then Continue;
              if LName.StartsWith('class ') then Continue;

              var LTypeRaw := LLine.Substring(LColonPos + 1);
              var LSemiPos := LTypeRaw.IndexOf(';');
              if LSemiPos >= 0 then
                LTypeRaw := LTypeRaw.Substring(0, LSemiPos);
              LTypeRaw := LTypeRaw.Trim;

              var LFieldSlug := MakeSlug(LName);
              var LFieldId := UniqueId('data-field-' + LEntitySlug + '-' + LFieldSlug);

              var LFieldNode := TSpecNode.MakeNew(LFieldId, ttData,
                LName, 'field');
              LFieldNode.ParentId := LEntityId;
              LFieldNode.DataType := LTypeRaw;
              LFieldNode.Summary := LName + ': ' + LTypeRaw;
              LFieldNode.Status := nsCandidate;
              LFieldNode.Confidence := clMedium;
              LFieldNode.SourceLayer := slParsedFromA;
              LFieldNode.SourceRefs := [LRef];
              LFieldNode.ContentHash := TSpecHash.NodeContentHash(LFieldNode);
              LFieldNode.RelationHash := TSpecHash.NodeRelationHash(LFieldNode);
              FDataNodes.Add(LFieldNode);
              LFieldList.Add(LFieldId);
              Inc(LFieldCount);
            end;

            LEntityNode.Children := LFieldList.ToArray;
          finally
            LFieldList.Free;
          end;

          LEntityNode.ContentHash := TSpecHash.NodeContentHash(LEntityNode);
          LEntityNode.RelationHash := TSpecHash.NodeRelationHash(LEntityNode);
          FDataNodes.Add(LEntityNode);
        end;

        Inc(LCount);
      finally
        LInfo.Free;
      end;
    end;
  finally
    LPasParser.Free;
    LEntitySlugs.Free;
  end;
end;

procedure TAsWishTreeBuilder.BuildDataTreeFromGeneric(AScan: TAsWishScanService;
  const AProjectName: string);
var
  LDataRoot: TSpecNode;
  LRootChildren: TList<string>;
  LEntities: TDictionary<string, Integer>;
  LFields: TDictionary<string, Boolean>;
  LInferredEntities: Integer;

  function Singularize(const AName: string): string;
  var
    LName: string;
  begin
    LName := AName.Trim(['"', '''', '`', '[', ']']);
    if LName.Contains('.') then
      LName := LName.Substring(LName.LastIndexOf('.') + 1);
    if LName.EndsWith('ies') and (LName.Length > 3) then
      LName := LName.Substring(0, LName.Length - 3) + 'y'
    else if LName.EndsWith('sses') then
      LName := LName.Substring(0, LName.Length - 2)
    else if LName.EndsWith('s') and not LName.EndsWith('ss') and
            not LName.EndsWith('us') and not LName.EndsWith('is') then
      LName := LName.Substring(0, LName.Length - 1);
    Result := LName;
  end;

  function DisplayName(const AName: string): string;
  begin
    Result := Singularize(AName).Replace('_', ' ').Replace('-', ' ').Trim;
    if Result = '' then
      Result := 'Unknown data';
    if Result.Length > 0 then
      Result[1] := UpCase(Result[1]);
  end;

  function EntityKey(const AName: string): string;
  begin
    Result := LowerCase(MakeSlug(Singularize(AName)));
  end;

  function IsToolingFile(const APath: string): Boolean;
  var
    LName: string;
  begin
    LName := LowerCase(TPath.GetFileName(APath));
    Result := (LName = 'package.json') or (LName = 'package-lock.json') or
      (LName = 'yarn.lock') or (LName = 'pnpm-lock.yaml') or
      (LName = 'tsconfig.json') or (LName = 'jsconfig.json') or
      (LName = 'pyproject.toml') or (LName = 'cargo.toml') or
      (LName = 'composer.json') or (LName = 'pom.xml');
  end;

  function IsDataLikePath(const APath: string): Boolean;
  var
    LLower, LExt: string;
  begin
    LLower := LowerCase(APath.Replace('\', '/'));
    LExt := LowerCase(TPath.GetExtension(APath));
    Result := (LExt = '.json') or (LExt = '.yaml') or (LExt = '.yml') or
      (LExt = '.toml') or (LExt = '.ini') or (LExt = '.properties') or
      (LExt = '.env') or (LExt = '.sql') or (LExt = '.graphql') or
      (LExt = '.gql') or (LExt = '.prisma') or (LExt = '.proto') or
      (LExt = '.csv') or LLower.Contains('/data/') or
      LLower.Contains('/models/') or LLower.Contains('/schema/') or
      LLower.Contains('/fixtures/') or LLower.Contains('/seeds/') or
      LLower.Contains('/migrations/');
  end;

  function SourceRefFor(const APath: string): TSourceRef;
  var
    LEvidence: TSpecEvidence;
  begin
    LEvidence := MakeEvidenceForFile(APath);
    FEvidenceList.Add(LEvidence);
    Result := Default(TSourceRef);
    Result.RefId := LEvidence.Id;
    Result.Relevance := 'primary';
  end;

  function AddEntity(const AName, APath: string;
    const ASourceRef: TSourceRef): Integer;
  var
    LKey, LTitle, LEntityId: string;
    LNode: TSpecNode;
  begin
    Result := -1;
    LKey := EntityKey(AName);
    if LKey = '' then Exit;
    if LEntities.TryGetValue(LKey, Result) then Exit;

    LTitle := DisplayName(AName);
    LEntityId := UniqueId('data-entity-' + MakeSlug(LTitle));
    LNode := TSpecNode.MakeNew(LEntityId, ttData, LTitle, 'entity');
    LNode.ParentId := LDataRoot.Id;
    LNode.Summary := 'Data entity inferred from ' + APath;
    LNode.Status := nsCandidate;
    LNode.Confidence := clMedium;
    LNode.SourceLayer := slParsedFromA;
    LNode.SourceRefs := [ASourceRef];
    LNode.ContentHash := TSpecHash.NodeContentHash(LNode);
    LNode.RelationHash := TSpecHash.NodeRelationHash(LNode);
    FDataNodes.Add(LNode);
    Result := FDataNodes.Count - 1;
    LEntities.Add(LKey, Result);
    LRootChildren.Add(LEntityId);
    Inc(LInferredEntities);
  end;

  procedure AddField(AEntityIndex: Integer; const AName, ADataType,
    APath: string; const ASourceRef: TSourceRef);
  var
    LEntity, LField: TSpecNode;
    LFieldName, LFieldKey, LFieldId, LType: string;
  begin
    if (AEntityIndex < 0) or (AEntityIndex >= FDataNodes.Count) then Exit;
    LFieldName := AName.Trim(['"', '''', '`', '[', ']', '?', '!']);
    if LFieldName = '' then Exit;
    LFieldKey := FDataNodes[AEntityIndex].Id + '/' +
      LowerCase(MakeSlug(LFieldName));
    if LFields.ContainsKey(LFieldKey) then Exit;
    LFields.Add(LFieldKey, True);

    LType := ADataType.Trim;
    if LType = '' then LType := 'unknown';
    LFieldId := UniqueId('data-field-' +
      MakeSlug(FDataNodes[AEntityIndex].Title) + '-' + MakeSlug(LFieldName));
    LField := TSpecNode.MakeNew(LFieldId, ttData, LFieldName, 'field');
    LField.ParentId := FDataNodes[AEntityIndex].Id;
    LField.DataType := LType;
    LField.Summary := LFieldName + ': ' + LType + ' (inferred from ' + APath + ')';
    LField.Status := nsCandidate;
    LField.Confidence := clMedium;
    LField.SourceLayer := slParsedFromA;
    LField.SourceRefs := [ASourceRef];
    LField.ContentHash := TSpecHash.NodeContentHash(LField);
    LField.RelationHash := TSpecHash.NodeRelationHash(LField);
    FDataNodes.Add(LField);

    LEntity := FDataNodes[AEntityIndex];
    SetLength(LEntity.Children, Length(LEntity.Children) + 1);
    LEntity.Children[High(LEntity.Children)] := LFieldId;
    LEntity.ContentHash := TSpecHash.NodeContentHash(LEntity);
    LEntity.RelationHash := TSpecHash.NodeRelationHash(LEntity);
    FDataNodes[AEntityIndex] := LEntity;
  end;

  function JsonValueType(AValue: TJSONValue): string;
  begin
    if AValue = nil then Exit('unknown');
    if AValue is TJSONString then Exit('string');
    if AValue is TJSONNumber then Exit('number');
    if AValue is TJSONObject then Exit('object');
    if AValue is TJSONArray then Exit('array');
    if LowerCase(AValue.ClassName).Contains('bool') then Exit('boolean');
    if LowerCase(AValue.ClassName).Contains('null') then Exit('null');
    Result := 'unknown';
  end;

  procedure AddJsonFields(AEntityIndex: Integer; AObject: TJSONObject;
    const APath: string; const ASourceRef: TSourceRef);
  var
    LPair: TJSONPair;
    LValue: TJSONValue;
  begin
    if AObject = nil then Exit;
    for var I := 0 to AObject.Count - 1 do
    begin
      LPair := AObject.Pairs[I];
      LValue := LPair.JsonValue;
      AddField(AEntityIndex, LPair.JsonString.Value,
        JsonValueType(LValue), APath, ASourceRef);
    end;
  end;

  procedure ProcessJson(const APath: string; const ASourceRef: TSourceRef);
  var
    LJson: TJSONValue;
    LObject: TJSONObject;
    LArray: TJSONArray;
    LPair: TJSONPair;
    LValue: TJSONValue;
    LEntityIndex: Integer;
    LFoundNested: Boolean;
    LStem: string;
  begin
    try
      LJson := TJSONValue.ParseJSONValue(
        TFile.ReadAllText(TPath.Combine(FProjectRootPath, APath.Replace('/', '\')), TEncoding.UTF8));
    except
      Exit;
    end;
    if LJson = nil then Exit;
    try
      LStem := TPath.GetFileNameWithoutExtension(APath);
      if LJson is TJSONObject then
      begin
        LObject := TJSONObject(LJson);
        LFoundNested := False;
        for var I := 0 to LObject.Count - 1 do
        begin
          LPair := LObject.Pairs[I];
          LValue := LPair.JsonValue;
          if LValue is TJSONObject then
          begin
            LEntityIndex := AddEntity(LPair.JsonString.Value, APath, ASourceRef);
            AddJsonFields(LEntityIndex, TJSONObject(LValue), APath, ASourceRef);
            LFoundNested := True;
          end
          else if LValue is TJSONArray then
          begin
            if (TJSONArray(LValue).Count > 0) and
               (TJSONArray(LValue).Items[0] is TJSONObject) then
            begin
              LEntityIndex := AddEntity(LPair.JsonString.Value, APath, ASourceRef);
              AddJsonFields(LEntityIndex,
                TJSONObject(TJSONArray(LValue).Items[0]),
                APath, ASourceRef);
              LFoundNested := True;
            end;
          end;
        end;
        if not LFoundNested and IsDataLikePath(APath) then
        begin
          LEntityIndex := AddEntity(LStem, APath, ASourceRef);
          AddJsonFields(LEntityIndex, LObject, APath, ASourceRef);
        end;
      end
      else if LJson is TJSONArray then
      begin
        LArray := TJSONArray(LJson);
        if (LArray.Count > 0) and (LArray.Items[0] is TJSONObject) then
        begin
          LEntityIndex := AddEntity(LStem, APath, ASourceRef);
          AddJsonFields(LEntityIndex, TJSONObject(LArray.Items[0]),
            APath, ASourceRef);
        end;
      end;
    finally
      LJson.Free;
    end;
  end;

  function YamlScalarType(AValue: TYamlNode): string;
  var
    LText: string;
    LInteger: Integer;
  begin
    if (AValue = nil) or (AValue.Kind <> ykScalar) then Exit('unknown');
    LText := AValue.AsString('');
    if SameText(LText, 'true') or SameText(LText, 'false') then
      Exit('boolean');
    if TryStrToInt(LText, LInteger) then
      Exit('integer');
    if LText.Contains('.') then
      Exit('number');
    Result := 'string';
  end;

  procedure AddYamlFields(AEntityIndex: Integer; AObject: TYamlNode;
    const APath: string; const ASourceRef: TSourceRef);
  begin
    if (AObject = nil) or (AObject.Kind <> ykMap) then Exit;
    for var LKey in AObject.MapKeys do
    begin
      var LValue := AObject.Get(LKey);
      if (LValue <> nil) and (LValue.Kind = ykScalar) then
        AddField(AEntityIndex, LKey, YamlScalarType(LValue), APath, ASourceRef);
    end;
  end;

  procedure ProcessYaml(const APath: string; const ASourceRef: TSourceRef);
  var
    LParser: TYamlParser;
    LRoot, LValue, LItem: TYamlNode;
    LEntityIndex: Integer;
    LFoundNested: Boolean;
    LStem: string;
  begin
    LParser := TYamlParser.Create;
    LRoot := nil;
    try
      try
        LRoot := LParser.ParseFile(
          TPath.Combine(FProjectRootPath, APath.Replace('/', '\')));
      except
        Exit;
      end;
      LStem := TPath.GetFileNameWithoutExtension(APath);
      if (LRoot <> nil) and (LRoot.Kind = ykMap) then
      begin
        LFoundNested := False;
        for var LKey in LRoot.MapKeys do
        begin
          LValue := LRoot.Get(LKey);
          if (LValue <> nil) and (LValue.Kind = ykMap) then
          begin
            LEntityIndex := AddEntity(LKey, APath, ASourceRef);
            AddYamlFields(LEntityIndex, LValue, APath, ASourceRef);
            LFoundNested := True;
          end
          else if (LValue <> nil) and (LValue.Kind = ykSequence) and
                  (LValue.SeqCount > 0) then
          begin
            LItem := LValue.SeqItem(0);
            if (LItem <> nil) and (LItem.Kind = ykMap) then
            begin
              LEntityIndex := AddEntity(LKey, APath, ASourceRef);
              AddYamlFields(LEntityIndex, LItem, APath, ASourceRef);
              LFoundNested := True;
            end;
          end;
        end;
        if not LFoundNested and IsDataLikePath(APath) then
        begin
          LEntityIndex := AddEntity(LStem, APath, ASourceRef);
          AddYamlFields(LEntityIndex, LRoot, APath, ASourceRef);
        end;
      end
      else if (LRoot <> nil) and (LRoot.Kind = ykSequence) and
              (LRoot.SeqCount > 0) then
      begin
        LItem := LRoot.SeqItem(0);
        if (LItem <> nil) and (LItem.Kind = ykMap) then
        begin
          LEntityIndex := AddEntity(LStem, APath, ASourceRef);
          AddYamlFields(LEntityIndex, LItem, APath, ASourceRef);
        end;
      end;
    finally
      LRoot.Free;
      LParser.Free;
    end;
  end;

  function ScalarTextType(const AValue: string): string;
  var
    LInteger: Integer;
  begin
    if SameText(AValue, 'true') or SameText(AValue, 'false') then
      Exit('boolean');
    if TryStrToInt(AValue, LInteger) then
      Exit('integer');
    if AValue.Contains('.') then
      Exit('number');
    Result := 'string';
  end;

  procedure ProcessKeyValue(const APath: string; const ASourceRef: TSourceRef);
  var
    LLines: TArray<string>;
    LCurrentEntity: Integer;
    LRawLine, LLine, LSection, LKey, LValue: string;
    LPos, LEnd: Integer;
  begin
    try
      LLines := ReadLinesTolerant(
        TPath.Combine(FProjectRootPath, APath.Replace('/', '\')), APath);
    except
      Exit;
    end;
    LCurrentEntity := -1;
    for LRawLine in LLines do
    begin
      LLine := LRawLine.Trim;
      if (LLine = '') or LLine.StartsWith('#') or LLine.StartsWith(';') then Continue;
      if LLine.StartsWith('[[') and LLine.EndsWith(']]') then
      begin
        LSection := LLine.Substring(2, LLine.Length - 4).Trim;
        LCurrentEntity := AddEntity(LSection, APath, ASourceRef);
        Continue;
      end;
      if LLine.StartsWith('[') and LLine.EndsWith(']') then
      begin
        LSection := LLine.Substring(1, LLine.Length - 2).Trim;
        LCurrentEntity := AddEntity(LSection, APath, ASourceRef);
        Continue;
      end;
      LPos := LLine.IndexOf('=');
      if LPos < 0 then LPos := LLine.IndexOf(':');
      if LPos <= 0 then Continue;
      LKey := LLine.Substring(0, LPos).Trim;
      LValue := LLine.Substring(LPos + 1).Trim;
      if LCurrentEntity < 0 then
      begin
        if not IsDataLikePath(APath) then Continue;
        LCurrentEntity := AddEntity(TPath.GetFileNameWithoutExtension(APath),
          APath, ASourceRef);
      end;
      LEnd := LValue.IndexOf(' #');
      if LEnd >= 0 then LValue := LValue.Substring(0, LEnd).Trim;
      AddField(LCurrentEntity, LKey, ScalarTextType(LValue.Trim(['"', ''''])),
        APath, ASourceRef);
    end;
  end;

  procedure ProcessCsv(const APath: string; const ASourceRef: TSourceRef);
  var
    LLines: TArray<string>;
    LEntityIndex: Integer;
  begin
    try
      LLines := ReadLinesTolerant(
        TPath.Combine(FProjectRootPath, APath.Replace('/', '\')), APath);
    except
      Exit;
    end;
    if Length(LLines) = 0 then Exit;
    LEntityIndex := AddEntity(TPath.GetFileNameWithoutExtension(APath),
      APath, ASourceRef);
    for var LColumn in LLines[0].Split([',']) do
      AddField(LEntityIndex, LColumn.Trim(['"', '''']), 'string', APath, ASourceRef);
  end;

  function CountChar(const AText: string; AChar: Char): Integer;
  begin
    Result := 0;
    for var LChar in AText do
      if LChar = AChar then Inc(Result);
  end;

  function LeadingSpaces(const AText: string): Integer;
  begin
    Result := 0;
    while (Result < AText.Length) and (AText.Chars[Result] = ' ') do Inc(Result);
  end;

  function StripLineComment(const ALine: string): string;
  var
    LPos: Integer;
  begin
    Result := ALine;
    LPos := Result.IndexOf('//');
    if LPos >= 0 then Result := Result.Substring(0, LPos);
    LPos := Result.IndexOf('#');
    if LPos = 0 then Result := '';
  end;

  function TryDeclarationName(const ALine: string; out AName: string): Boolean;
  var
    LLine, LLower, LRest: string;
    LKeyword: string;
    LPos, LI: Integer;
  begin
    Result := False;
    AName := '';
    LLine := ALine.Trim;
    for var LPrefix in ['export ', 'default ', 'public ', 'private ',
      'protected ', 'internal ', 'abstract ', 'partial ', 'sealed ',
      'static ', 'final ', 'pub '] do
      if LLine.ToLower.StartsWith(LPrefix) then
        LLine := LLine.Substring(LPrefix.Length).Trim;
    LLower := LowerCase(LLine);
    LKeyword := '';
    for var LCandidate in ['interface', 'class', 'struct', 'record',
      'model', 'input', 'message', 'type'] do
      if LLower.StartsWith(LCandidate + ' ') then
      begin
        LKeyword := LCandidate;
        Break;
      end;
    if LKeyword = '' then Exit;
    LPos := LKeyword.Length + 1;
    while (LPos <= LLine.Length) and (LLine.Chars[LPos - 1] = ' ') do Inc(LPos);
    LRest := LLine.Substring(LPos - 1).Trim;
    if LRest = '' then Exit;
    LI := 0;
    while (LI < LRest.Length) and not CharInSet(LRest.Chars[LI],
      [' ', #9, '<', '{', '(', ':', '=', ';']) do Inc(LI);
    if LI = 0 then Exit;
    AName := LRest.Substring(0, LI).Trim;
    Result := EntityKey(AName) <> '';
  end;

  function SplitWords(const AText: string): TArray<string>;
  var
    LWords: TList<string>;
    LToken: string;
  begin
    LWords := TList<string>.Create;
    try
      LToken := '';
      for var LChar in AText do
      begin
        if CharInSet(LChar, [' ', #9, #13, #10]) then
        begin
          if LToken <> '' then
          begin
            LWords.Add(LToken);
            LToken := '';
          end;
        end
        else
          LToken := LToken + LChar;
      end;
      if LToken <> '' then LWords.Add(LToken);
      Result := LWords.ToArray;
    finally
      LWords.Free;
    end;
  end;

  function TryField(const ALine: string; out AName, AType: string): Boolean;
  const
    MODIFIERS: array[0..9] of string = (
      'public', 'private', 'protected', 'internal', 'readonly',
      'static', 'final', 'required', 'optional', 'var');
    COMMON_TYPES: array[0..13] of string = (
      'string', 'str', 'text', 'int', 'integer', 'long', 'short',
      'float', 'double', 'decimal', 'bool', 'boolean', 'date', 'datetime');
  var
    LLine, LLeft, LRight: string;
    LColon, LEqual, LAt, LBrace: Integer;
    LWords: TArray<string>;
    LStart: Integer;

    function IsIn(const AValue: string; const AList: array of string): Boolean;
    begin
      for var LValue in AList do
        if SameText(LValue, AValue) then Exit(True);
      Result := False;
    end;

    function CleanName(const AValue: string): string;
    begin
      Result := AValue.Trim(['"', '''', '`', '[', ']', '?', '!', ',', ';']);
      while Result.Contains(' ') do
        Result := Result.Substring(Result.LastIndexOf(' ') + 1);
    end;

    function CleanType(const AValue: string): string;
    begin
      Result := AValue.Trim;
      LEqual := Result.IndexOf('=');
      if LEqual >= 0 then Result := Result.Substring(0, LEqual).Trim;
      LAt := Result.IndexOf('@');
      if LAt >= 0 then Result := Result.Substring(0, LAt).Trim;
      LBrace := Result.IndexOf('{');
      if LBrace >= 0 then Result := Result.Substring(0, LBrace).Trim;
      Result := Result.Trim(['"', '''', '`', ',', ';', '!']);
    end;
  begin
    Result := False;
    AName := '';
    AType := '';
    LLine := StripLineComment(ALine).Trim;
    if (LLine = '') or LLine.StartsWith('}') or LLine.StartsWith('{') then Exit;
    for var LKeyword in ['function ', 'procedure ', 'def ', 'func ', 'return ',
      'if ', 'for ', 'while ', 'import ', 'from ', 'using ', 'package ',
      'const ', 'let ', 'var ', 'class ', 'interface ', 'type ', 'struct ',
      'model ', 'enum ', 'message '] do
      if LLine.ToLower.StartsWith(LKeyword) then Exit;

    LColon := LLine.IndexOf(':');
    if LColon > 0 then
    begin
      LLeft := LLine.Substring(0, LColon).Trim;
      LRight := LLine.Substring(LColon + 1).Trim;
      AName := CleanName(LLeft);
      AType := CleanType(LRight);
    end
    else
    begin
      LWords := SplitWords(LLine.Trim([';', ',']));
      if Length(LWords) < 2 then Exit;
      LStart := 0;
      while (LStart < Length(LWords)) and IsIn(LWords[LStart], MODIFIERS) do Inc(LStart);
      if Length(LWords) - LStart < 2 then Exit;
      if IsIn(LWords[LStart + 1], COMMON_TYPES) and
         not IsIn(LWords[LStart], COMMON_TYPES) then
      begin
        // Go/proto-style declarations put the field name before a primitive
        // type (for example: ID string or id int32).
        AName := CleanName(LWords[LStart]);
        AType := CleanType(LWords[LStart + 1]);
      end
      else if IsIn(LWords[LStart], COMMON_TYPES) or
         ((LWords[LStart].Length > 0) and
          CharInSet(LWords[LStart].Chars[0], ['A'..'Z'])) then
      begin
        AType := CleanType(LWords[LStart]);
        AName := CleanName(LWords[LStart + 1]);
      end
      else
      begin
        AName := CleanName(LWords[LStart]);
        AType := CleanType(LWords[LStart + 1]);
      end;
    end;
    if (AName = '') or (MakeSlug(AName) = '') or (AName.Contains('(')) then Exit;
    if AType = '' then AType := 'unknown';
    Result := True;
  end;

  procedure ProcessTypedCode(const APath: string; const ASourceRef: TSourceRef);
  var
    LLines: TArray<string>;
    LActiveEntity, LBraceDepth, LClassIndent: Integer;
    LUsesIndentation: Boolean;
    LRawLine, LLine, LName, LType, LBody: string;
    LEntityIndex: Integer;
  begin
    try
      LLines := ReadLinesTolerant(
        TPath.Combine(FProjectRootPath, APath.Replace('/', '\')), APath);
    except
      Exit;
    end;
    LActiveEntity := -1;
    LBraceDepth := 0;
    LClassIndent := 0;
    LUsesIndentation := False;
    for LRawLine in LLines do
    begin
      LLine := LRawLine;
      if TryDeclarationName(LLine, LName) then
      begin
        LEntityIndex := AddEntity(LName, APath, ASourceRef);
        LActiveEntity := LEntityIndex;
        LBraceDepth := CountChar(LLine, '{') - CountChar(LLine, '}');
        LClassIndent := LeadingSpaces(LLine);
        LUsesIndentation := (LBraceDepth = 0) and LLine.Trim.EndsWith(':');
        LBody := LLine;
        if LBody.IndexOf('{') >= 0 then
        begin
          LBody := LBody.Substring(LBody.IndexOf('{') + 1);
          if LBody.LastIndexOf('}') >= 0 then
            LBody := LBody.Substring(0, LBody.LastIndexOf('}'));
          for var LPart in LBody.Split([';', ',']) do
            if TryField(LPart, LName, LType) then
              AddField(LEntityIndex, LName, LType, APath, ASourceRef);
        end;
        if (LBraceDepth <= 0) and not LUsesIndentation then
          LActiveEntity := -1;
        Continue;
      end;

      if LActiveEntity < 0 then Continue;
      LLine := StripLineComment(LLine);
      if LLine.Trim = '' then Continue;
      if LUsesIndentation and (LeadingSpaces(LLine) <= LClassIndent) then
      begin
        LActiveEntity := -1;
        Continue;
      end;
      if TryField(LLine, LName, LType) then
        AddField(LActiveEntity, LName, LType, APath, ASourceRef);
      if not LUsesIndentation then
      begin
        LBraceDepth := LBraceDepth + CountChar(LLine, '{') - CountChar(LLine, '}');
        if LBraceDepth <= 0 then LActiveEntity := -1;
      end;
    end;
  end;

  procedure ProcessSql(const APath: string; const ASourceRef: TSourceRef);
  var
    LLines: TArray<string>;
    LInside: Boolean;
    LEntityIndex: Integer;
    LRawLine, LLine, LUpper, LRest, LColumnName, LColumnType: string;
    LPos, LEnd, LSpace: Integer;
  begin
    try
      LLines := ReadLinesTolerant(
        TPath.Combine(FProjectRootPath, APath.Replace('/', '\')), APath);
    except
      Exit;
    end;
    LInside := False;
    LEntityIndex := -1;
    for LRawLine in LLines do
    begin
      LLine := LRawLine.Trim;
      LUpper := UpperCase(LLine);
      LPos := LUpper.IndexOf('CREATE TABLE');
      if LPos >= 0 then
      begin
        LRest := LLine.Substring(LPos + Length('CREATE TABLE')).Trim;
        if LRest.ToUpper.StartsWith('IF NOT EXISTS') then
          LRest := LRest.Substring(Length('IF NOT EXISTS')).Trim;
        LEnd := LRest.IndexOf(' ');
        if (LEnd < 0) or ((LRest.IndexOf('(') >= 0) and
           (LRest.IndexOf('(') < LEnd)) then LEnd := LRest.IndexOf('(');
        if LEnd < 0 then LEnd := LRest.Length;
        LEntityIndex := AddEntity(LRest.Substring(0, LEnd).Trim,
          APath, ASourceRef);
        LInside := LRest.Contains('(') and not LRest.Contains(');');
        Continue;
      end;
      if not LInside then Continue;
      if LLine.StartsWith(')') then
      begin
        LInside := False;
        Continue;
      end;
      if LUpper.StartsWith('PRIMARY ') or LUpper.StartsWith('FOREIGN ') or
         LUpper.StartsWith('UNIQUE ') or LUpper.StartsWith('CONSTRAINT ') or
         LUpper.StartsWith('CHECK ') or LUpper.StartsWith('INDEX ') then Continue;
      LLine := LLine.Trim(['(', ')', ',', ';']);
      if LLine = '' then Continue;
      LSpace := LLine.IndexOf(' ');
      if LSpace < 0 then Continue;
      LColumnName := LLine.Substring(0, LSpace).Trim(['"', '`', '[', ']']);
      LColumnType := LLine.Substring(LSpace + 1).Trim;
      LEnd := LColumnType.IndexOf(' ');
      if LEnd < 0 then LEnd := LColumnType.Length;
      AddField(LEntityIndex, LColumnName, LColumnType.Substring(0, LEnd),
        APath, ASourceRef);
    end;
  end;

  procedure ProcessFile(const APath: string; ACategory: TFileCategory);
  var
    LExt: string;
    LSourceRef: TSourceRef;
  begin
    if IsToolingFile(APath) then Exit;
    if not (ACategory in [fcCode, fcConfig, fcUnknown]) then Exit;
    LExt := LowerCase(TPath.GetExtension(APath));
    if not IsDataLikePath(APath) and not (ACategory = fcCode) then Exit;
    LSourceRef := SourceRefFor(APath);
    if LExt = '.json' then ProcessJson(APath, LSourceRef)
    else if (LExt = '.yaml') or (LExt = '.yml') then ProcessYaml(APath, LSourceRef)
    else if (LExt = '.toml') or (LExt = '.ini') or (LExt = '.properties') or
            (LExt = '.env') then ProcessKeyValue(APath, LSourceRef)
    else if LExt = '.csv' then ProcessCsv(APath, LSourceRef)
    else if LExt = '.sql' then ProcessSql(APath, LSourceRef)
    else ProcessTypedCode(APath, LSourceRef);
  end;

var
  LEntry: TScanResult;
  LPlaceholder: TSpecNode;
begin
  LRootChildren := TList<string>.Create;
  LEntities := TDictionary<string, Integer>.Create;
  LFields := TDictionary<string, Boolean>.Create;
  try
    LInferredEntities := 0;
    LDataRoot := TSpecNode.MakeNew(UniqueId('data-' + MakeSlug(AProjectName)),
      ttData, AProjectName + ' Data', 'entity');
    LDataRoot.Summary := 'Data projection inferred from project sources';
    LDataRoot.Status := nsCandidate;
    LDataRoot.Confidence := clMedium;
    LDataRoot.SourceLayer := slParsedFromA;
    FDataNodes.Add(LDataRoot);

    for LEntry in AScan.Results do
      ProcessFile(LEntry.RelativePath, LEntry.Category);

    if LInferredEntities = 0 then
    begin
      LDataRoot.Summary := 'No data entities could be inferred from project sources';
      LDataRoot.Confidence := clLow;
      LDataRoot.SourceLayer := slGeneratedSummary;
      LDataRoot.FogState := fsMisty;
      LDataRoot.HasFogState := True;

      LPlaceholder := TSpecNode.MakeNew(UniqueId('data-unknown-data'), ttData,
        'Unknown data model', 'entity');
      LPlaceholder.ParentId := LDataRoot.Id;
      LPlaceholder.Summary := 'Data entities, fields, and persistence boundaries require review';
      LPlaceholder.Status := nsCandidate;
      LPlaceholder.Confidence := clLow;
      LPlaceholder.SourceLayer := slAiInferred;
      LPlaceholder.FogState := fsFoggy;
      LPlaceholder.HasFogState := True;
      LPlaceholder.ContentHash := TSpecHash.NodeContentHash(LPlaceholder);
      LPlaceholder.RelationHash := TSpecHash.NodeRelationHash(LPlaceholder);
      FDataNodes.Add(LPlaceholder);
      LRootChildren.Add(LPlaceholder.Id);
    end;

    LDataRoot.Children := LRootChildren.ToArray;
    LDataRoot.ContentHash := TSpecHash.NodeContentHash(LDataRoot);
    LDataRoot.RelationHash := TSpecHash.NodeRelationHash(LDataRoot);
    FDataNodes[0] := LDataRoot;
  finally
    LFields.Free;
    LEntities.Free;
    LRootChildren.Free;
  end;
end;

end.
