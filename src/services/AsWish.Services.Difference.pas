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
  TAsWishDifferenceService = class
  private
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
  public
    constructor Create(AStore: TAsWishStoreService; ASnapshot: TAsWishSnapshotService);
    function ComputeDifference(const AProjectDir: string;
      const ABaselineId: string): TSpecDifferenceReport;
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
end;

procedure TAsWishDifferenceService.WriteDifferenceFile(const ARelPath: string;
  const AReport: TSpecDifferenceReport);
var
  LSb: TStringBuilder;

  function EscapeStr(const S: string): string;
  begin
    Result := S.Replace('\', '\\').Replace('"', '\"');
  end;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('baseline_id: "' + EscapeStr(AReport.BaselineId) + '"');
    LSb.AppendLine('tree_type: "' + EscapeStr(AReport.TreeType) + '"');
    LSb.AppendLine('computed_at: "' + DateToISO8601(AReport.ComputedAt, False) + '"');

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
  const ABaselineId: string): TSpecDifferenceReport;
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

  // Load implementation evidence (fail-closed if missing)
  LEvList := FStore.ReadEvidenceFile('evidence/implementation-evidence.yaml');
  if (LEvList = nil) or (LEvList.Count = 0) then
  begin
    LEvList.Free;
    raise Exception.Create('Implementation evidence missing or empty: .AsWish/evidence/implementation-evidence.yaml');
  end;
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
