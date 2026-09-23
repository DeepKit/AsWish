unit AsWish.Services.Difference;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.SpecStore,
  AsWish.Services.Snapshot;

type
  /// <summary>Non-persistent identity resolver context passed to comparators.</summary>
  IPlatformIdentityResolver = interface
    ['{3A9E8C1F-5D2B-4E7A-9B6C-1F0E8D7C6B5A}']
    function ResolveNodeId(const APlatformId: string): string;
    function TryResolveNodeId(const APlatformId: string; out ANodeId: string): Boolean;
  end;

  /// <summary>In-memory map identity resolver for testing and caller-supplied bindings.</summary>
  TMapIdentityResolver = class(TInterfacedObject, IPlatformIdentityResolver)
  private
    FMap: TDictionary<string, string>;
  public
    constructor Create(const AMap: TDictionary<string, string>);
    destructor Destroy; override;
    function ResolveNodeId(const APlatformId: string): string;
    function TryResolveNodeId(const APlatformId: string; out ANodeId: string): Boolean;
  end;

  /// <summary>Non-persistent comparison context passed to platform comparators.</summary>
  TPlatformComparisonContext = record
    ProjectDir: string;
    TreeType: string;
    BaselineId: string;
    SnapshotDir: string;
    ObservationJson: string;
    ConstraintsJson: string;
    ExpectedStylesJson: string;
    IdentityResolver: IPlatformIdentityResolver;
  end;

  /// <summary>Extension seam for platform L2/L3 comparators.</summary>
  IPlatformDifferenceComparator = interface
    ['{8F5A9A1E-2B6C-4D8E-9A3F-7E1D2C5B4A01}']
    function GetPlatformName: string;
    function CanHandle(const AContext: TPlatformComparisonContext;
      const ABaseline: TAsWishBaseline): Boolean;
    function CompareL2L3(const AContext: TPlatformComparisonContext;
      const ABaseline: TAsWishBaseline): TArray<TSpecDifferenceItem>;
  end;

  TAsWishDifferenceService = class
  private
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    FComparators: TList<IPlatformDifferenceComparator>;
  public
    constructor Create(AStore: TAsWishStoreService; ASnapshot: TAsWishSnapshotService);
    destructor Destroy; override;
    procedure RegisterComparator(const AComparator: IPlatformDifferenceComparator);
    procedure ClearComparators;
    function ComputeDifference(const AProjectDir: string;
      const ABaselineId: string;
      const AResolver: IPlatformIdentityResolver = nil;
      const AObservationJson: string = '';
      const AConstraintsJson: string = '';
      const AExpectedStylesJson: string = '';
      const AAllowDegraded: Boolean = False): TSpecDifferenceReport;
    procedure WriteDifferenceFile(const ARelPath: string;
      const AReport: TSpecDifferenceReport);
    function ReadDifferenceFile(const ARelPath: string = 'difference.yaml'): TSpecDifferenceReport;
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  AsWish.Hash,
  AsWish.Yaml.Parser,
  AsWish.Yaml.Writer;

constructor TMapIdentityResolver.Create(const AMap: TDictionary<string, string>);
begin
  inherited Create;
  FMap := TDictionary<string, string>.Create;
  if AMap <> nil then
    for var LPair in AMap do
      FMap.AddOrSetValue(LPair.Key, LPair.Value);
end;

destructor TMapIdentityResolver.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

function TMapIdentityResolver.ResolveNodeId(const APlatformId: string): string;
begin
  if not TryResolveNodeId(APlatformId, Result) then
    Result := '';
end;

function TMapIdentityResolver.TryResolveNodeId(const APlatformId: string; out ANodeId: string): Boolean;
begin
  Result := FMap.TryGetValue(APlatformId, ANodeId);
end;

constructor TAsWishDifferenceService.Create(AStore: TAsWishStoreService;
  ASnapshot: TAsWishSnapshotService);
begin
  inherited Create;
  if AStore = nil then
    raise Exception.Create('TAsWishDifferenceService requires a store');
  if ASnapshot = nil then
    raise Exception.Create('TAsWishDifferenceService requires a snapshot service');
  FStore := AStore;
  FSnapshot := ASnapshot;
  FComparators := TList<IPlatformDifferenceComparator>.Create;
end;

destructor TAsWishDifferenceService.Destroy;
begin
  FComparators.Free;
  inherited Destroy;
end;

procedure TAsWishDifferenceService.RegisterComparator(const AComparator: IPlatformDifferenceComparator);
begin
  if (AComparator <> nil) and not FComparators.Contains(AComparator) then
    FComparators.Add(AComparator);
end;

procedure TAsWishDifferenceService.ClearComparators;
begin
  FComparators.Clear;
end;

procedure TAsWishDifferenceService.WriteDifferenceFile(const ARelPath: string;
  const AReport: TSpecDifferenceReport);
var
  LSb: TStringBuilder;

  function EscapeStr(const S: string): string;
  begin
    // WO-0039 B-4: newlines must not break YAML line structure (Notes carry
    // multi-line rationale from difference judgments).
    Result := S.Replace('\', '\\').Replace('"', '\"')
      .Replace(#13#10, '\n').Replace(#10, '\n').Replace(#13, '\r');
  end;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('baseline_id: "' + EscapeStr(AReport.BaselineId) + '"');
    LSb.AppendLine('tree_type: "' + EscapeStr(AReport.TreeType) + '"');
    LSb.AppendLine('computed_at: "' + DateToISO8601(AReport.ComputedAt, False) + '"');
    if AReport.IsDegraded then
    begin
      LSb.AppendLine('is_degraded: true');
      if AReport.DegradedReason <> '' then
        LSb.AppendLine('degraded_reason: "' + EscapeStr(AReport.DegradedReason) + '"');
    end;

    if Length(AReport.Items) = 0 then
      LSb.AppendLine('items: []')
    else
    begin
      LSb.AppendLine('items:');
      for var LItem in AReport.Items do
      begin
        LSb.AppendLine('  - node_id: "' + EscapeStr(LItem.NodeId) + '"');
        LSb.AppendLine('    kind: ' + TSpecEnums.DifferenceKindToStr(LItem.Kind));
        if LItem.Kind = dkChanged then
          LSb.AppendLine('    changed_aspect: ' + TSpecEnums.DifferenceAspectToStr(LItem.ChangedAspect));
        if LItem.BaselineHash <> '' then
          LSb.AppendLine('    baseline_hash: "' + EscapeStr(LItem.BaselineHash) + '"')
        else
          LSb.AppendLine('    baseline_hash: null');
        if LItem.EvidenceHash <> '' then
          LSb.AppendLine('    evidence_hash: "' + EscapeStr(LItem.EvidenceHash) + '"')
        else
          LSb.AppendLine('    evidence_hash: null');
        if LItem.Note <> '' then
          LSb.AppendLine('    note: "' + EscapeStr(LItem.Note) + '"');
      end;
    end;

    TAsWishStoreService.AtomicWriteTextFile(TPath.Combine(FStore.BasePath, ARelPath), LSb.ToString);
  finally
    LSb.Free;
  end;
end;

function TAsWishDifferenceService.ReadDifferenceFile(
  const ARelPath: string): TSpecDifferenceReport;
var
  LFullPath, LYaml: string;
  LParser: TYamlParser;
  LRoot, LItemsSeq, LItemNode: TYamlNode;
  LItemsList: TList<TSpecDifferenceItem>;
  LItem: TSpecDifferenceItem;
begin
  Result := Default(TSpecDifferenceReport);
  LFullPath := TPath.Combine(FStore.BasePath, ARelPath);
  if not TFile.Exists(LFullPath) then
    raise Exception.Create('difference.yaml not found: ' + LFullPath);

  LYaml := TFile.ReadAllText(LFullPath, TEncoding.UTF8);
  LParser := TYamlParser.Create;
  try
    LRoot := LParser.Parse(LYaml);
    if LRoot = nil then
      raise Exception.Create('Failed to parse difference.yaml: ' + LFullPath);
    try
      Result.BaselineId := LRoot.GetString('baseline_id', '');
      Result.TreeType := LRoot.GetString('tree_type', 'function');
      if LRoot.Has('computed_at') then
        Result.ComputedAt := ISO8601ToDate(LRoot.GetString('computed_at', ''), False)
      else
        Result.ComputedAt := Now;
      Result.IsDegraded := LRoot.GetBoolean('is_degraded', False);
      Result.DegradedReason := LRoot.GetString('degraded_reason', '');

      LItemsSeq := LRoot.Get('items');
      LItemsList := TList<TSpecDifferenceItem>.Create;
      try
        if (LItemsSeq <> nil) and (LItemsSeq.Kind = ykSequence) then
        begin
          for var I := 0 to LItemsSeq.SeqCount - 1 do
          begin
            LItemNode := LItemsSeq.SeqItem(I);
            if (LItemNode = nil) or (LItemNode.Kind <> ykMap) then Continue;

            LItem := Default(TSpecDifferenceItem);
            LItem.NodeId := LItemNode.GetString('node_id', '');
            LItem.Kind := TSpecEnums.DifferenceKindFromStr(LItemNode.GetString('kind', 'missing'));
            if LItemNode.Has('changed_aspect') then
              LItem.ChangedAspect := TSpecEnums.DifferenceAspectFromStr(LItemNode.GetString('changed_aspect', 'none'))
            else
              LItem.ChangedAspect := daNone;
            LItem.BaselineHash := LItemNode.GetString('baseline_hash', '');
            LItem.EvidenceHash := LItemNode.GetString('evidence_hash', '');
            if LItemNode.Has('note') then
              LItem.Note := LItemNode.GetString('note', '')
            else if LItemNode.Has('message') then
              LItem.Note := LItemNode.GetString('message', '');

            LItemsList.Add(LItem);
          end;
        end;
        Result.Items := LItemsList.ToArray;
      finally
        LItemsList.Free;
      end;
    finally
      LRoot.Free;
    end;
  finally
    LParser.Free;
  end;
end;

function TAsWishDifferenceService.ComputeDifference(const AProjectDir: string;
  const ABaselineId: string;
  const AResolver: IPlatformIdentityResolver;
  const AObservationJson: string;
  const AConstraintsJson: string;
  const AExpectedStylesJson: string;
  const AAllowDegraded: Boolean): TSpecDifferenceReport;
var
  LBaseline: TAsWishBaseline;
  LSnapDir, LTreeFileName: string;
  LTempStore: TAsWishStoreService;
  LEvList: TList<TSpecEvidence>;
  LBaseNodes, LLiveNodes: TList<TSpecNode>;
  LBaseMap, LLiveMap: TDictionary<string, TSpecNode>;
  LDiffItems: TList<TSpecDifferenceItem>;
  LItem: TSpecDifferenceItem;
  LBaseNode, LLiveNode: TSpecNode;
  LBaseContentHash, LLiveContentHash: string;
  LBaseRelHash, LLiveRelHash: string;
begin
  Result := Default(TSpecDifferenceReport);

  if not TDirectory.Exists(AProjectDir) then
    raise Exception.Create('Project directory does not exist: ' + AProjectDir);

  if not TDirectory.Exists(TPath.Combine(AProjectDir, '.AsWish')) then
    raise Exception.Create('Project does not contain .AsWish folder: ' + AProjectDir);

  if not FSnapshot.LoadBaseline(ABaselineId, LBaseline) then
    raise Exception.Create('Baseline not found: ' + ABaselineId);

  LSnapDir := TPath.Combine(FStore.BasePath, 'snapshots\' + LBaseline.SnapshotName);
  if not TDirectory.Exists(LSnapDir) then
    raise Exception.Create('Baseline snapshot directory missing: ' + LSnapDir);

  // Load implementation evidence (fail-closed if missing unless AAllowDegraded is True)
  LEvList := FStore.ReadEvidenceFile('evidence/implementation-evidence.yaml');
  if (LEvList = nil) or (LEvList.Count = 0) then
  begin
    LEvList.Free;
    if not AAllowDegraded then
      raise Exception.Create('Implementation evidence missing or empty: .AsWish/evidence/implementation-evidence.yaml');
    Result.IsDegraded := True;
    Result.DegradedReason := 'Degraded: Implementation evidence missing or empty; L1 structural comparison only.';
  end
  else
    LEvList.Free;

  LTreeFileName := 'trees/function-tree.yaml';
  if LBaseline.TreeType = 'view' then LTreeFileName := 'trees/view-tree.yaml'
  else if LBaseline.TreeType = 'module' then LTreeFileName := 'trees/module-tree.yaml'
  else if LBaseline.TreeType = 'data' then LTreeFileName := 'trees/data-tree.yaml';

  LTempStore := TAsWishStoreService.Create;
  LBaseMap := TDictionary<string, TSpecNode>.Create;
  LLiveMap := TDictionary<string, TSpecNode>.Create;
  LDiffItems := TList<TSpecDifferenceItem>.Create;
  try
    LTempStore.InitializeDirect(LSnapDir);

    LBaseNodes := LTempStore.ReadTreeFile(LTreeFileName);
    LLiveNodes := FStore.ReadTreeFile(LTreeFileName);
    try
      if LBaseNodes <> nil then
        for var LNode in LBaseNodes do
          LBaseMap.AddOrSetValue(LNode.Id, LNode);

      if LLiveNodes <> nil then
        for var LNode in LLiveNodes do
          LLiveMap.AddOrSetValue(LNode.Id, LNode);

      // 1. Check Baseline Nodes against Live & Evidence (Missing & Changed)
      for var LPair in LBaseMap do
      begin
        LBaseNode := LPair.Value;
        LBaseContentHash := TSpecHash.NodeContentHash(LBaseNode);
        LBaseRelHash := TSpecHash.NodeRelationHash(LBaseNode);

        if not LLiveMap.TryGetValue(LBaseNode.Id, LLiveNode) then
        begin
          // Missing: In Baseline, completely absent from Live
          LItem := Default(TSpecDifferenceItem);
          LItem.NodeId := LBaseNode.Id;
          LItem.Kind := dkMissing;
          LItem.ChangedAspect := daNone;
          LItem.BaselineHash := LBaseContentHash;
          LItem.EvidenceHash := '';
          LDiffItems.Add(LItem);
        end
        else
        begin
          // Node present in both: check if hashes changed
          LLiveContentHash := TSpecHash.NodeContentHash(LLiveNode);
          LLiveRelHash := TSpecHash.NodeRelationHash(LLiveNode);

          if (LBaseContentHash <> LLiveContentHash) or (LBaseRelHash <> LLiveRelHash) then
          begin
            LItem := Default(TSpecDifferenceItem);
            LItem.NodeId := LBaseNode.Id;
            LItem.Kind := dkChanged;
            if (LBaseContentHash <> LLiveContentHash) and (LBaseRelHash <> LLiveRelHash) then
              LItem.ChangedAspect := daBoth
            else if (LBaseContentHash <> LLiveContentHash) then
              LItem.ChangedAspect := daContent
            else
              LItem.ChangedAspect := daRelation;

            LItem.BaselineHash := LBaseContentHash;
            LItem.EvidenceHash := LLiveContentHash;
            LDiffItems.Add(LItem);
          end;
        end;
      end;

      // 2. Check Live Nodes against Baseline (Extra)
      for var LPair in LLiveMap do
      begin
        LLiveNode := LPair.Value;
        if not LBaseMap.ContainsKey(LLiveNode.Id) then
        begin
          LItem := Default(TSpecDifferenceItem);
          LItem.NodeId := LLiveNode.Id;
          LItem.Kind := dkExtra;
          LItem.ChangedAspect := daNone;
          LItem.BaselineHash := '';
          LItem.EvidenceHash := TSpecHash.NodeContentHash(LLiveNode);
          LDiffItems.Add(LItem);
        end;
      end;

      // 3. Dispatch registered Platform Comparators for L2/L3 extension
      var LHandledByPlatform := False;
      if FComparators.Count > 0 then
      begin
        var LCtx: TPlatformComparisonContext;
        LCtx.ProjectDir := AProjectDir;
        LCtx.TreeType := LBaseline.TreeType;
        LCtx.BaselineId := LBaseline.BaselineId;
        LCtx.SnapshotDir := LSnapDir;
        LCtx.ObservationJson := AObservationJson;
        LCtx.ConstraintsJson := AConstraintsJson;
        LCtx.ExpectedStylesJson := AExpectedStylesJson;
        LCtx.IdentityResolver := AResolver;

        for var LComp in FComparators do
        begin
          if (LComp <> nil) and LComp.CanHandle(LCtx, LBaseline) then
          begin
            LHandledByPlatform := True;
            var LPlatformItems := LComp.CompareL2L3(LCtx, LBaseline);
            for var LPlatItem in LPlatformItems do
              LDiffItems.Add(LPlatItem);
          end;
        end;
      end;

      if not LHandledByPlatform and (LBaseline.TreeType = 'view') and AAllowDegraded then
      begin
        if not Result.IsDegraded then
        begin
          Result.IsDegraded := True;
          Result.DegradedReason := 'Degraded: No platform visual comparator handled baseline; skipped L2/L3 visual comparison.';
        end;
      end;

      Result.BaselineId := LBaseline.BaselineId;
      Result.TreeType := LBaseline.TreeType;
      Result.ComputedAt := Now;
      Result.Items := LDiffItems.ToArray;

      // Write to .AsWish/difference.yaml
      WriteDifferenceFile('difference.yaml', Result);
    finally
      LLiveNodes.Free;
      LBaseNodes.Free;
    end;
  finally
    LDiffItems.Free;
    LLiveMap.Free;
    LBaseMap.Free;
    LTempStore.Free;
  end;
end;

end.
