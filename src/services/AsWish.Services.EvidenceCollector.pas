unit AsWish.Services.EvidenceCollector;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.SpecStore,
  AsWish.Services.Snapshot;

type
  TAsWishEvidenceCollectorService = class
  private
    FStore: TAsWishStoreService;
    FSnapshot: TAsWishSnapshotService;
    function ExtractSampleLines(const AFilePath: string; const ALines: string): string;
    function ParseLineRange(const ALinesStr: string; out AStart, AEnd: Integer): Boolean;
  public
    constructor Create(AStore: TAsWishStoreService; ASnapshot: TAsWishSnapshotService);
    /// <param name="ADegradedCount">Receives the count of refs that could not be
    /// resolved to a real source file; those become low-confidence stale items
    /// instead of aborting the whole collection.</param>
    function CollectImplementationEvidence(const AProjectDir: string;
      const ABaselineId: string = ''; ADegradedCount: PInteger = nil): TArray<TSpecEvidence>;
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  System.Math,
  AsWish.Hash;

constructor TAsWishEvidenceCollectorService.Create(AStore: TAsWishStoreService;
  ASnapshot: TAsWishSnapshotService);
begin
  inherited Create;
  if AStore = nil then
    raise Exception.Create('TAsWishEvidenceCollectorService requires a store');
  if ASnapshot = nil then
    raise Exception.Create('TAsWishEvidenceCollectorService requires a snapshot service');
  FStore := AStore;
  FSnapshot := ASnapshot;
end;

function TAsWishEvidenceCollectorService.ParseLineRange(const ALinesStr: string;
  out AStart, AEnd: Integer): Boolean;
var
  LDashPos: Integer;
  LStartStr, LEndStr: string;
begin
  Result := False;
  AStart := 1;
  AEnd := 20;
  if ALinesStr.Trim = '' then Exit(False);

  LDashPos := Pos('-', ALinesStr);
  if LDashPos > 0 then
  begin
    LStartStr := Copy(ALinesStr, 1, LDashPos - 1).Trim;
    LEndStr := Copy(ALinesStr, LDashPos + 1, Length(ALinesStr)).Trim;
    if TryStrToInt(LStartStr, AStart) and TryStrToInt(LEndStr, AEnd) then
      Result := True;
  end
  else
  begin
    if TryStrToInt(ALinesStr.Trim, AStart) then
    begin
      AEnd := AStart;
      Result := True;
    end;
  end;
end;

function TAsWishEvidenceCollectorService.ExtractSampleLines(const AFilePath: string;
  const ALines: string): string;
var
  LAllLines: TStringList;
  LStart, LEnd, I: Integer;
  LSb: TStringBuilder;
begin
  Result := '';
  if not TFile.Exists(AFilePath) then Exit;

  LAllLines := TStringList.Create;
  LSb := TStringBuilder.Create;
  try
    LAllLines.LoadFromFile(AFilePath, TEncoding.UTF8);
    if LAllLines.Count = 0 then Exit('');

    if ParseLineRange(ALines, LStart, LEnd) then
    begin
      if LStart < 1 then LStart := 1;
      if LEnd > LAllLines.Count then LEnd := LAllLines.Count;
      if LStart > LAllLines.Count then LStart := LAllLines.Count;

      for I := LStart - 1 to LEnd - 1 do
      begin
        if LSb.Length > 0 then LSb.Append(sLineBreak);
        LSb.Append(LAllLines[I]);
      end;
    end
    else
    begin
      LEnd := LAllLines.Count;
      if LEnd > 20 then LEnd := 20;
      for I := 0 to LEnd - 1 do
      begin
        if LSb.Length > 0 then LSb.Append(sLineBreak);
        LSb.Append(LAllLines[I]);
      end;
    end;
    Result := LSb.ToString;
  finally
    LSb.Free;
    LAllLines.Free;
  end;
end;

function TAsWishEvidenceCollectorService.CollectImplementationEvidence(
  const AProjectDir: string; const ABaselineId: string = '';
  ADegradedCount: PInteger = nil): TArray<TSpecEvidence>;
var
  LBaseline: TAsWishBaseline;
  LBaselines: TArray<TAsWishBaseline>;
  LSnapDir: string;
  LTempStore: TAsWishStoreService;
  LNodes: TList<TSpecNode>;
  LTreeNodes: TList<TSpecNode>;
  LSourceEvList: TList<TSpecEvidence>;
  LSourceEvMap: TDictionary<string, TSpecEvidence>;
  LCollectedList: TList<TSpecEvidence>;
  LCollectedMap: TDictionary<string, Integer>; // Path -> Index in LCollectedList
  LExistingEvidence: TList<TSpecEvidence>;
  LExistingHashMap: TDictionary<string, string>; // Path -> SourceFileHash
  LEv: TSpecEvidence;
  LDupSourceIds: TStringList;
  LUnresolvedCount: Integer;
  LTreeFiles: TArray<string>;
  LTreeFile: string;
  LRelPath, LAbsPath, LLines, LExcerpt, LFileHash: string;
  LFoundRef: Boolean;
  LMatchedEv: TSpecEvidence;
begin
  LUnresolvedCount := 0;
  if not TDirectory.Exists(AProjectDir) then
    raise Exception.Create('Project directory does not exist: ' + AProjectDir);

  if not TDirectory.Exists(TPath.Combine(AProjectDir, '.AsWish')) then
    raise Exception.Create('Project does not contain .AsWish folder: ' + AProjectDir);

  if ABaselineId <> '' then
  begin
    if not FSnapshot.LoadBaseline(ABaselineId, LBaseline) then
      raise Exception.Create('Baseline not found: ' + ABaselineId);
  end
  else
  begin
    LBaselines := FSnapshot.ListBaselines;
    if Length(LBaselines) = 0 then
      raise Exception.Create('No accepted baseline found in project');
    LBaseline := LBaselines[High(LBaselines)];
  end;

  LSnapDir := TPath.Combine(FStore.BasePath, 'snapshots\' + LBaseline.SnapshotName);
  if not TDirectory.Exists(LSnapDir) then
    raise Exception.Create('Baseline snapshot directory missing: ' + LSnapDir);

  LTempStore := TAsWishStoreService.Create;
  LNodes := TList<TSpecNode>.Create;
  LSourceEvMap := TDictionary<string, TSpecEvidence>.Create;
  LCollectedList := TList<TSpecEvidence>.Create;
  LCollectedMap := TDictionary<string, Integer>.Create;
  LExistingHashMap := TDictionary<string, string>.Create;
  try
    LTempStore.InitializeDirect(LSnapDir);

    // 1. Load source evidences from snapshot or project store
    LSourceEvList := LTempStore.ReadEvidenceFile('evidence/source-evidence.yaml');
    try
      if (LSourceEvList = nil) or (LSourceEvList.Count = 0) then
      begin
        LSourceEvList.Free;
        LSourceEvList := FStore.ReadEvidenceFile('evidence/source-evidence.yaml');
        if (LSourceEvList = nil) or (LSourceEvList.Count = 0) then
        begin
          LSourceEvList.Free;
          LSourceEvList := FStore.ReadEvidenceFile('source-evidence.yaml');
        end;
      end;

      if LSourceEvList <> nil then
      begin
        // A duplicate id means two different evidence entries claim the same
        // identity, so which one a node's ref resolves to would be decided by
        // list order rather than by content. That is a data defect, not a
        // tie to break: refuse rather than pick one silently.
        LDupSourceIds := TStringList.Create;
        try
          LDupSourceIds.Sorted := True;
          LDupSourceIds.Duplicates := TDuplicates.dupIgnore;
          for var LSev in LSourceEvList do
            if LSev.Id <> '' then
            begin
              if LSourceEvMap.ContainsKey(LSev.Id) then
                LDupSourceIds.Add(LSev.Id)
              else
                LSourceEvMap.Add(LSev.Id, LSev);
            end;
          if LDupSourceIds.Count > 0 then
            raise Exception.Create(Format(
              'source-evidence.yaml has %d duplicate evidence id(s); ' +
              'refs cannot be resolved unambiguously. First offenders: %s',
              [LDupSourceIds.Count,
               string.Join(', ', Copy(LDupSourceIds.ToStringArray, 0,
                 Min(5, LDupSourceIds.Count)))]));
        finally
          LDupSourceIds.Free;
        end;
      end;
    finally
      LSourceEvList.Free;
    end;

    // 2. Load existing implementation evidence to detect hash changes / stales
    LExistingEvidence := FStore.ReadEvidenceFile('evidence/implementation-evidence.yaml');
    try
      if LExistingEvidence <> nil then
      begin
        for var LEvItem in LExistingEvidence do
          LExistingHashMap.AddOrSetValue(LEvItem.Path, LEvItem.SourceFileHash);
      end;
    finally
      LExistingEvidence.Free;
    end;

    // 3. Load all nodes from trees in baseline snapshot
    LTreeFiles := TArray<string>.Create(
      'trees/function-tree.yaml',
      'trees/module-tree.yaml',
      'trees/view-tree.yaml',
      'trees/data-tree.yaml'
    );

    for LTreeFile in LTreeFiles do
    begin
      var LFullPath := TPath.Combine(LSnapDir, StringReplace(LTreeFile, '/', '\', [rfReplaceAll]));
      if TFile.Exists(LFullPath) then
      begin
        LTreeNodes := LTempStore.ReadTreeFile(LTreeFile);
        if LTreeNodes <> nil then
        begin
          try
            LNodes.AddRange(LTreeNodes);
          finally
            LTreeNodes.Free;
          end;
        end;
      end;
    end;

    // 4. Iterate over baseline nodes and collect evidence
    for var LNode in LNodes do
    begin
      if Length(LNode.SourceRefs) = 0 then Continue;

      for var LSR in LNode.SourceRefs do
      begin
        LFoundRef := False;
        LRelPath := '';
        LLines := '';

        if LSourceEvMap.TryGetValue(LSR.RefId, LMatchedEv) then
        begin
          LRelPath := LMatchedEv.Path;
          LLines := LMatchedEv.Lines;
          LFoundRef := True;
        end
        else if (LSR.RefId <> '') and (TFile.Exists(TPath.Combine(AProjectDir, LSR.RefId))) then
        begin
          LRelPath := LSR.RefId;
          LFoundRef := True;
        end
        else if (LSR.Note <> '') and (TFile.Exists(TPath.Combine(AProjectDir, LSR.Note))) then
        begin
          LRelPath := LSR.Note;
          LFoundRef := True;
        end;

        if not LFoundRef or (LRelPath = '') then
        begin
          // Degrade instead of aborting: one unresolvable ref must not kill
          // evidence for the whole baseline (code-fix: single-point failure).
          LEv := Default(TSpecEvidence);
          LEv.Id := Format('ev-impl-unresolved-%s', [LNode.Id]);
          LEv.SourceLayer := slImplementation;
          LEv.Path := LSR.RefId;
          LEv.Lines := '';
          LEv.Excerpt := '';
          LEv.ExcerptTruncated := False;
          LEv.Confidence := clLow;
          LEv.CreatedAt := Now;
          LEv.UpdatedAt := Now;
          LEv.SourceFileHash := '';
          LEv.ContentHash := '';
          LEv.IsStale := True;
          SetLength(LEv.ReferencedBy, 1);
          LEv.ReferencedBy[0] := LNode.Id;
          LEv.Note := 'Unresolvable source ref (evidence collection degraded)';
          LUnresolvedCount := LUnresolvedCount + 1;
          LCollectedList.Add(LEv);
          Continue;
        end;

        LAbsPath := TPath.Combine(AProjectDir, StringReplace(LRelPath, '/', '\', [rfReplaceAll]));
        if not TFile.Exists(LAbsPath) then
        begin
          LEv := Default(TSpecEvidence);
          LEv.Id := Format('ev-impl-missing-%s', [LNode.Id]);
          LEv.SourceLayer := slImplementation;
          LEv.Path := LRelPath;
          LEv.Lines := LLines;
          LEv.Excerpt := '';
          LEv.ExcerptTruncated := False;
          LEv.Confidence := clLow;
          LEv.CreatedAt := Now;
          LEv.UpdatedAt := Now;
          LEv.SourceFileHash := '';
          LEv.ContentHash := '';
          LEv.IsStale := True;
          SetLength(LEv.ReferencedBy, 1);
          LEv.ReferencedBy[0] := LNode.Id;
          LEv.Note := 'Source file missing on disk (evidence collection degraded)';
          LUnresolvedCount := LUnresolvedCount + 1;
          LCollectedList.Add(LEv);
          Continue;
        end;

        LFileHash := TSpecHash.FileSha256Hex(LAbsPath);
        LExcerpt := ExtractSampleLines(LAbsPath, LLines);

        var LKey := LRelPath;
        var LExistingIdx: Integer;
        if LCollectedMap.TryGetValue(LKey, LExistingIdx) then
        begin
          // Evidence already recorded for this path; add node reference if not present
          var LExistingEv := LCollectedList[LExistingIdx];
          var LHasNode := False;
          for var LRefId in LExistingEv.ReferencedBy do
            if LRefId = LNode.Id then
            begin
              LHasNode := True;
              Break;
            end;
          if not LHasNode then
          begin
            SetLength(LExistingEv.ReferencedBy, Length(LExistingEv.ReferencedBy) + 1);
            LExistingEv.ReferencedBy[High(LExistingEv.ReferencedBy)] := LNode.Id;
            LCollectedList[LExistingIdx] := LExistingEv;
          end;
        end
        else
        begin
          LEv := Default(TSpecEvidence);
          LEv.Id := Format('ev-impl-%.4d', [LCollectedList.Count + 1]);
          LEv.SourceLayer := slImplementation;
          LEv.Path := LRelPath;
          LEv.Lines := LLines;
          LEv.Excerpt := LExcerpt;
          LEv.ExcerptTruncated := False;
          LEv.Confidence := clHigh;
          LEv.CreatedAt := Now;
          LEv.UpdatedAt := Now;
          LEv.SourceFileHash := LFileHash;
          LEv.ContentHash := TSpecHash.Sha256Hex(LExcerpt);
          LEv.IsStale := False;
          SetLength(LEv.ReferencedBy, 1);
          LEv.ReferencedBy[0] := LNode.Id;

          // Check if previously recorded hash changed -> if file changed, we update and note
          var LOldHash: string;
          if LExistingHashMap.TryGetValue(LRelPath, LOldHash) then
          begin
            if (LOldHash <> '') and (LOldHash <> LFileHash) then
              LEv.Note := 'source_file_hash changed since previous collection';
          end;

          LCollectedMap.Add(LKey, LCollectedList.Count);
          LCollectedList.Add(LEv);
        end;
      end;
    end;

    // 4b. Fallback for projects where baseline nodes do not have explicit source_refs
    if LCollectedList.Count = 0 then
    begin
      if LSourceEvMap.Count > 0 then
      begin
        for var LSev in LSourceEvMap.Values do
        begin
          LAbsPath := TPath.Combine(AProjectDir, StringReplace(LSev.Path, '/', '\', [rfReplaceAll]));
          if TFile.Exists(LAbsPath) then
          begin
            LFileHash := TSpecHash.FileSha256Hex(LAbsPath);
            LExcerpt := ExtractSampleLines(LAbsPath, LSev.Lines);
            LEv := Default(TSpecEvidence);
            LEv.Id := Format('ev-impl-%.4d', [LCollectedList.Count + 1]);
            LEv.SourceLayer := slImplementation;
            LEv.Path := LSev.Path;
            LEv.Lines := LSev.Lines;
            LEv.Excerpt := LExcerpt;
            LEv.ExcerptTruncated := False;
            LEv.Confidence := clMedium;
            LEv.CreatedAt := Now;
            LEv.UpdatedAt := Now;
            LEv.SourceFileHash := LFileHash;
            LEv.ContentHash := TSpecHash.Sha256Hex(LExcerpt);
            LEv.Note := 'Project source fallback (unanchored)';
            LCollectedList.Add(LEv);
          end;
        end;
      end;

      if LCollectedList.Count = 0 then
      begin
        LEv := Default(TSpecEvidence);
        LEv.Id := 'ev-impl-0001';
        LEv.SourceLayer := slImplementation;
        LEv.Path := '.AsWish';
        LEv.Lines := '1-1';
        LEv.Excerpt := '(pure spec baseline)';
        LEv.ExcerptTruncated := False;
        LEv.Confidence := clLow;
        LEv.CreatedAt := Now;
        LEv.UpdatedAt := Now;
        LEv.SourceFileHash := '';
        LEv.ContentHash := TSpecHash.Sha256Hex('pure-spec');
        LEv.Note := 'Graceful fallback: pure spec baseline';
        LCollectedList.Add(LEv);
      end;
    end;

    // 5. Write to .AsWish/evidence/implementation-evidence.yaml
    FStore.WriteEvidenceFile('evidence/implementation-evidence.yaml', LCollectedList);

    if ADegradedCount <> nil then
      ADegradedCount^ := LUnresolvedCount;

    Result := LCollectedList.ToArray;
  finally
    LExistingHashMap.Free;
    LCollectedMap.Free;
    LCollectedList.Free;
    LSourceEvMap.Free;
    LNodes.Free;
    LTempStore.Free;
  end;
end;

end.
