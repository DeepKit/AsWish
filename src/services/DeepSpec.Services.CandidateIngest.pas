{ ============================================================================
  DeepSpec.Services.CandidateIngest

  Strongly-typed sandbox for LLM-generated candidate YAML. The LLM output is
  unreliable, so before a single byte of it touches the live spec trees it is
  parsed into TSpecNode lists and validated field-by-field (id prefix, parent_id
  foreign key, enum legality, ...). Only nodes that pass become candidates for
  MergeInto. Constraints come from Delphi types + runtime checks, not from
  trusting the LLM to be well-behaved.

  See bugfix.md BUG-8 / docs/wayfinder-对DeepSpec的启发.md (gap 2).
  ============================================================================ }

unit DeepSpec.Services.CandidateIngest;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DeepSpec.Models,
  DeepSpec.Services.SpecStore;

type
  TMergeStats = record
    Merged: Integer;     // nodes whose fields were updated in-place
    Added: Integer;      // nodes appended (id did not exist)
    FogCleared: Integer; // function roots whose fog_state converged one step
  end;

  TCandidateIngestResult = record
    /// <summary>Validated nodes ready for MergeInto. Caller does NOT own the
    /// lists inside — they are owned by the TDeepSpecCandidateIngest instance
    /// that produced this result (see OwnershipNote below). Copy what you need
    /// before dropping the reference.</summary>
    Accepted: TList<TSpecNode>;
    Rejected: Integer;
    Warnings: TStringList;
    Errors: TStringList;
    /// <summary>Per-tree accepted lists, pre-routed by the node's Tree field.
    /// Owned by the instance.</summary>
    FuncNodes: TList<TSpecNode>;
    ModNodes: TList<TSpecNode>;
    ViewNodes: TList<TSpecNode>;
    procedure Init;
    procedure FreeOwned;
  end;

  TDeepSpecCandidateIngest = class(TObject)
  private
    FSpecStore: TDeepSpecStoreService;
    procedure ValidateNode(var ANode: TSpecNode;
      AAllKnownIds: TDictionary<string, Boolean>;
      var AResult: TCandidateIngestResult);
  public
    constructor Create(ASpecStore: TDeepSpecStoreService);

    /// <summary>Split a multi-document YAML stream on `---` markers into
    /// individual document strings. Blank segments are dropped. A leading
    /// `---` does not produce an empty first segment.</summary>
    class function SplitDocuments(const AYaml: string): TArray<string>; static;

    /// <summary>Parse + validate candidate YAML. AExistingFunc/Mod/View supply
    /// the known id set for parent_id foreign-key checks. Returns accepted
    /// nodes (also pre-routed into FuncNodes/ModNodes/ViewNodes) plus counts
    /// and diagnostic lists. The instance owns the returned lists.</summary>
    function Ingest(const ACandidateYaml: string;
      AExistingFunc, AExistingMod, AExistingView: TList<TSpecNode>): TCandidateIngestResult;

    /// <summary>Merge accepted candidate nodes into the live tree lists.
    /// Existing nodes matched by id have their mutable fields overwritten
    /// (review_status / decision_refs are preserved — human decisions must
    /// survive LLM regeneration); gen_status advances to gsGenerated; the
    /// function root whose Summary actually changed converges fog_state one
    /// step (fsUnknownUnknowns -> fsFoggy) via CanTransitionFog. New ids are
    /// appended. Returns counts.</summary>
    function MergeInto(AAccepted: TList<TSpecNode>;
      AFunc, AMod, AView: TList<TSpecNode>): TMergeStats;
  end;

implementation

uses
  DeepSpec.Yaml.Parser;

{ TCandidateIngestResult }

procedure TCandidateIngestResult.Init;
begin
  Accepted := TList<TSpecNode>.Create;
  FuncNodes := TList<TSpecNode>.Create;
  ModNodes := TList<TSpecNode>.Create;
  ViewNodes := TList<TSpecNode>.Create;
  Warnings := TStringList.Create;
  Errors := TStringList.Create;
  Rejected := 0;
end;

procedure TCandidateIngestResult.FreeOwned;
begin
  Accepted.Free;
  FuncNodes.Free;
  ModNodes.Free;
  ViewNodes.Free;
  Warnings.Free;
  Errors.Free;
end;

{ TDeepSpecCandidateIngest }

constructor TDeepSpecCandidateIngest.Create(ASpecStore: TDeepSpecStoreService);
begin
  inherited Create;
  FSpecStore := ASpecStore;
end;

class function TDeepSpecCandidateIngest.SplitDocuments(
  const AYaml: string): TArray<string>;
var
  LLines: TArray<string>;
  LSb: TStringBuilder;
  LResults: TList<string>;
  I: Integer;
  LTrim: string;
begin
  Result := nil;
  if AYaml = '' then Exit;
  LLines := AYaml.Split([#10]);

  LSb := TStringBuilder.Create;
  LResults := TList<string>.Create;
  try
    for I := 0 to High(LLines) do
    begin
      LTrim := LLines[I].Trim;
      // A line whose trimmed content is exactly `---` starts a new document.
      // (`...` end marker also terminates a document — treat the same.)
      if (LTrim = '---') or (LTrim = '...') then
      begin
        if LSb.Length > 0 then
          LResults.Add(LSb.ToString);
        LSb.Clear;
      end
      else
      begin
        if LSb.Length > 0 then
          LSb.AppendLine;
        LSb.Append(LLines[I]);
      end;
    end;
    if LSb.Length > 0 then
      LResults.Add(LSb.ToString);
    Result := LResults.ToArray;
  finally
    LSb.Free;
    LResults.Free;
  end;
end;

function TDeepSpecCandidateIngest.Ingest(const ACandidateYaml: string;
  AExistingFunc, AExistingMod, AExistingView: TList<TSpecNode>): TCandidateIngestResult;
var
  LDocs: TArray<string>;
  LAllKnownIds: TDictionary<string, Boolean>;
  LParser: TYamlParser;
  LRoot: TYamlNode;
  LDefaultTree: TTreeType;
  LParsed: TList<TSpecNode>;
  LNode: TSpecNode;
  LDocIndex: Integer;
begin
  Result.Init;
  if ACandidateYaml = '' then Exit;

  // Build the set of ids the LLM may legally reference as parent_id: every
  // node already in the live trees plus every node accepted so far in this
  // ingest pass (so a candidate document may reference siblings defined in an
  // earlier document of the same stream).
  LAllKnownIds := TDictionary<string, Boolean>.Create;
  try
    if AExistingFunc <> nil then
      for var L in AExistingFunc do LAllKnownIds.AddOrSetValue(L.Id, True);
    if AExistingMod <> nil then
      for var L in AExistingMod do LAllKnownIds.AddOrSetValue(L.Id, True);
    if AExistingView <> nil then
      for var L in AExistingView do LAllKnownIds.AddOrSetValue(L.Id, True);

    LParser := TYamlParser.Create;
    try
      LDocs := SplitDocuments(ACandidateYaml);
      for LDocIndex := 0 to High(LDocs) do
      begin
        LRoot := LParser.Parse(LDocs[LDocIndex]);
        if LRoot = nil then
        begin
          Result.Errors.Add(Format('Document %d: unparseable YAML, skipped',
            [LDocIndex + 1]));
          Continue;
        end;
        try
          LDefaultTree := TSpecEnums.TreeTypeFromStr(LRoot.GetString('tree', ''));
          // Reject documents that fail to declare a tree — without it we
          // cannot route nodes, and silent misrouting would corrupt trees.
          if not LRoot.Has('tree') then
          begin
            Result.Errors.Add(Format('Document %d: missing tree field, skipped',
              [LDocIndex + 1]));
            Continue;
          end;

          LParsed := FSpecStore.ParseTreeNodes(LRoot, LDefaultTree);
          try
            // Validate each parsed node in place (index access — for-in gives
            // a value copy, which would discard our reject markers). Accepted
            // nodes are added to the known-id set so later documents/siblings
            // can reference them as parent_id.
            for var J := 0 to LParsed.Count - 1 do
            begin
              LNode := LParsed[J];
              ValidateNode(LNode, LAllKnownIds, Result);
              LParsed[J] := LNode; // write back so the accept check sees changes

              // ValidateNode zeroes Id on reject — skip those.
              if LNode.Id = '' then
                Continue;

              // data-tree is not ingestable by candidate (data nodes come
              // from scan, not LLM). Warn and drop rather than route.
              if LNode.Tree = ttData then
              begin
                Result.Warnings.Add(Format(
                  'Node %s: tree=data not ingestable by candidate; dropped',
                  [LNode.Id]));
                Continue;
              end;

              Result.Accepted.Add(LNode);
              LAllKnownIds.AddOrSetValue(LNode.Id, True);
              case LNode.Tree of
                ttFunction: Result.FuncNodes.Add(LNode);
                ttModule:   Result.ModNodes.Add(LNode);
                ttView:     Result.ViewNodes.Add(LNode);
              end;
            end;
          finally
            LParsed.Free;
          end;
        finally
          LRoot.Free;
        end;
      end;
    finally
      LParser.Free;
    end;
  finally
    LAllKnownIds.Free;
  end;
end;

procedure TDeepSpecCandidateIngest.ValidateNode(var ANode: TSpecNode;
  AAllKnownIds: TDictionary<string, Boolean>;
  var AResult: TCandidateIngestResult);

  function IdPrefixMatches(const AId: string; ATree: TTreeType): Boolean;
  const
    // Index aligns with TTreeType = (ttFunction, ttModule, ttView, ttData).
    CPREFIX: array [TTreeType] of string = ('func-', 'mod-', 'view-', 'data-');
  begin
    Result := AId.StartsWith(CPREFIX[ATree]);
  end;

var
  LId: string;
begin
  LId := ANode.Id;

  // id: non-empty + prefix matches its tree. On failure, zero the id so the
  // caller's accept loop skips this node (can't trust routing it).
  if (LId = '') or not IdPrefixMatches(LId, ANode.Tree) then
  begin
    AResult.Errors.Add(Format(
      'Node id "%s" does not match prefix for tree %s; rejected',
      [LId, TSpecEnums.TreeTypeToStr(ANode.Tree)]));
    Inc(AResult.Rejected);
    ANode.Id := '';
    Exit;
  end;

  // kind: non-empty. Warn but keep (callers tolerate empty kind).
  if ANode.Kind = '' then
    AResult.Warnings.Add(Format('Node %s: empty kind', [LId]));

  // parent_id: a node may omit it (root) but if present it must reference a
  // known node (existing live tree or an already-accepted candidate). This
  // is the foreign-key constraint that keeps the tree acyclic & connected.
  if ANode.ParentId <> '' then
    if not AAllKnownIds.ContainsKey(ANode.ParentId) then
    begin
      AResult.Errors.Add(Format(
        'Node %s: parent_id "%s" not found in known nodes; rejected',
        [LId, ANode.ParentId]));
      Inc(AResult.Rejected);
      ANode.Id := '';
      Exit;
    end;

  // source_layer: LLM must not claim human_decision provenance.
  if ANode.SourceLayer = slHumanDecision then
  begin
    AResult.Warnings.Add(Format(
      'Node %s: source_layer=human_decision not allowed for LLM output; forced to ai_inferred',
      [LId]));
    ANode.SourceLayer := slAiInferred;
  end;

  // gen_status: LLM-generated content is at most gsGenerated; never confirmed
  // (confirmation is a human/UI action). Force-confirming would bypass review.
  if ANode.GenStatus = gsConfirmed then
  begin
    AResult.Warnings.Add(Format(
      'Node %s: gen_status=confirmed not allowed for LLM output; forced to generated',
      [LId]));
    ANode.GenStatus := gsGenerated;
  end;

  // review_status: LLM has no review authority. Drop any non-unreviewed value.
  if ANode.ReviewStatus <> rsUnreviewed then
  begin
    AResult.Warnings.Add(Format(
      'Node %s: review_status=%s not allowed for LLM output; forced to unreviewed',
      [LId, TSpecEnums.ReviewStatusToStr(ANode.ReviewStatus)]));
    ANode.ReviewStatus := rsUnreviewed;
  end;
end;

function TDeepSpecCandidateIngest.MergeInto(AAccepted: TList<TSpecNode>;
  AFunc, AMod, AView: TList<TSpecNode>): TMergeStats;

  procedure MergeOne(ATarget: TList<TSpecNode>; const ACand: TSpecNode);
  var
    LFound: Integer;
    LExisting: TSpecNode;
    LIdx: Integer;
  begin
    LFound := -1;
    for LIdx := 0 to ATarget.Count - 1 do
      if ATarget[LIdx].Id = ACand.Id then
      begin
        LFound := LIdx;
        Break;
      end;

    if LFound >= 0 then
    begin
      LExisting := ATarget[LFound];
      // Snapshot the old summary to detect whether this merge actually
      // advances the function root out of its stub — that is the trigger
      // for fog convergence.
      var LOldSummary := LExisting.Summary;

      // Overwrite mutable semantic fields. These describe what the node IS,
      // and the LLM is the authority for them (post-validation).
      LExisting.Title := ACand.Title;
      LExisting.Kind := ACand.Kind;
      if ACand.Summary <> '' then
        LExisting.Summary := ACand.Summary;
      LExisting.ParentId := ACand.ParentId;
      LExisting.SourceLayer := ACand.SourceLayer;
      if Length(ACand.SourceRefs) > 0 then
        LExisting.SourceRefs := ACand.SourceRefs;
      LExisting.RelatedFunctions := ACand.RelatedFunctions;
      LExisting.RelatedModules := ACand.RelatedModules;
      LExisting.RelatedViews := ACand.RelatedViews;
      LExisting.RelatedData := ACand.RelatedData;
      LExisting.Children := ACand.Children;
      LExisting.Tags := ACand.Tags;
      LExisting.AcceptanceCriteria := ACand.AcceptanceCriteria;
      LExisting.NotDoing := ACand.NotDoing;

      // gen_status: advance to generated (never regress). Review status and
      // decision_refs are PRESERVED — human decisions survive regeneration.
      if TSpecEnums.CanTransitionGen(LExisting.GenStatus, gsGenerated) then
        LExisting.GenStatus := gsGenerated;

      // Fog convergence: if this is a function root whose summary actually
      // changed (stub -> real semantic content), nudge fog one step toward
      // clear. One round of LLM generation does not fully clear the fog.
      if (ACand.Tree = ttFunction) and LExisting.HasFogState and
         (LOldSummary <> LExisting.Summary) and
         TSpecEnums.CanTransitionFog(LExisting.FogState, fsFoggy) then
      begin
        LExisting.FogState := fsFoggy;
        Inc(Result.FogCleared);
      end;

      ATarget[LFound] := LExisting;
      Inc(Result.Merged);
    end
    else
    begin
      // New id: append. It is already validated & defaulted by Ingest.
      ATarget.Add(ACand);
      Inc(Result.Added);
    end;
  end;

begin
  Result := Default(TMergeStats);
  if AAccepted = nil then Exit;
  for var L in AAccepted do
  begin
    case L.Tree of
      ttFunction: if AFunc <> nil then MergeOne(AFunc, L);
      ttModule:   if AMod <> nil then MergeOne(AMod, L);
      ttView:     if AView <> nil then MergeOne(AView, L);
    end;
  end;
end;

end.
