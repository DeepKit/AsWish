
{ ============================================================================
  AsWish.Services.CandidateIngest

  Strongly-typed sandbox for LLM-generated candidate YAML. The LLM output is
  unreliable, so before a single byte of it touches the live spec trees it is
  parsed into TSpecNode lists and validated field-by-field (id prefix, parent_id
  foreign key, enum legality, ...). Only nodes that pass become candidates for
  MergeInto. Constraints come from Delphi types + runtime checks, not from
  trusting the LLM to be well-behaved.

  See bugfix.md BUG-8 / docs/wayfinder-对AsWish的启发.md (gap 2).
  ============================================================================ }

unit AsWish.Services.CandidateIngest;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.SpecStore;

type
  TMergeStats = record
    Merged: Integer;     // nodes whose fields were updated in-place
    Added: Integer;      // nodes appended (id did not exist)
    FogCleared: Integer; // function roots whose fog_state converged one step
  end;

  TCandidateIngestResult = record
    /// <summary>Validated nodes ready for MergeInto. Caller does NOT own the
    /// lists inside — they are owned by the TAsWishCandidateIngest instance
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
    DataNodes: TList<TSpecNode>;
    procedure Init;
    procedure FreeOwned;
  end;

  TAsWishCandidateIngest = class(TObject)
  private
    FSpecStore: TAsWishStoreService;
    procedure ValidateNode(var ANode: TSpecNode;
      AAllKnownIds: TDictionary<string, Boolean>;
      var AResult: TCandidateIngestResult);
  public
    constructor Create(ASpecStore: TAsWishStoreService);

    /// <summary>Split a multi-document YAML stream on `---` markers into
    /// individual document strings. Blank segments are dropped. A leading
    /// `---` does not produce an empty first segment.</summary>
    class function SplitDocuments(const AYaml: string): TArray<string>; static;

    /// <summary>Parse + validate candidate YAML. Existing tree lists supply
    /// the known id set for parent_id foreign-key checks. Returns accepted
    /// nodes (also pre-routed into the four projection lists) plus counts and
    /// diagnostic lists. The instance owns the returned lists.</summary>
    function Ingest(const ACandidateYaml: string;
      AExistingFunc, AExistingMod, AExistingView: TList<TSpecNode>): TCandidateIngestResult; overload;
    function Ingest(const ACandidateYaml: string;
      AExistingFunc, AExistingMod, AExistingView, AExistingData: TList<TSpecNode>): TCandidateIngestResult; overload;

    /// <summary>Merge accepted candidate nodes into the live tree lists.
    /// Existing nodes matched by id have their mutable fields overwritten
    /// (review_status / decision_refs are preserved — human decisions must
    /// survive LLM regeneration); gen_status advances to gsGenerated; the
    /// function root whose Summary actually changed converges fog_state one
    /// step (fsUnknownUnknowns -> fsFoggy) via CanTransitionFog. Data-tree
    /// fields use the same mutable merge path; human review fields are kept.
    /// New ids are appended. Returns counts.</summary>
    function MergeInto(AAccepted: TList<TSpecNode>;
      AFunc, AMod, AView: TList<TSpecNode>): TMergeStats; overload;
    function MergeInto(AAccepted: TList<TSpecNode>;
      AFunc, AMod, AView, AData: TList<TSpecNode>): TMergeStats; overload;

    /// <summary>Format human natural language candidate intent into YAML string (WO-20260830-0027A).</summary>
    class function FormatCandidateIntentYaml(const AIntent: TCandidateIntent): string; static;
    /// <summary>Parse YAML string into TCandidateIntent record (WO-20260830-0027A).</summary>
    class function ParseCandidateIntentYaml(const AYaml: string): TCandidateIntent; static;

    /// <summary>Persist human natural language candidate intent to .AsWish/llm/candidate-intent.yaml (WO-20260830-0027A).</summary>
    function SaveCandidateIntent(const AProjectPath: string; const AIntent: TCandidateIntent): string;
    /// <summary>Load candidate intent from .AsWish/llm/candidate-intent.yaml (WO-20260830-0027A).</summary>
    function LoadCandidateIntent(const AProjectPath: string): TCandidateIntent;
    /// <summary>List all candidate intents in .AsWish/llm/ (Dogfood intent list).</summary>
    function ListCandidateIntents(const AProjectPath: string): TArray<TCandidateIntent>;

    /// <summary>Check if natural language intent has sufficient clarity for LLM interpretation.
    /// If insufficient (empty/vague), constructs a grilling_ticket issue for human clarification (AC-03).</summary>
    function CheckIntentClarity(const AIntent: TCandidateIntent; out AIssue: TSpecIssue): Boolean;

    /// <summary>Format structured Change Set into YAML string (WO-20260830-0027B).</summary>
    class function FormatChangeSetYaml(const AChangeSet: TChangeSet): string; static;
    /// <summary>Parse YAML string into TChangeSet record (WO-20260830-0027B).</summary>
    class function ParseChangeSetYaml(const AYaml: string): TChangeSet; static;

    /// <summary>Generate monotonic unique Change Set ID for a node (e.g. cs-func-root-01, cs-func-root-02).</summary>
    function GenerateNextChangeSetId(const AProjectPath, ANodeId: string): string;
    /// <summary>Persist structured Change Set to .AsWish/llm/change-set.yaml (WO-20260830-0027B).</summary>
    function SaveChangeSet(const AProjectPath: string; const AChangeSet: TChangeSet): string;
    /// <summary>Load structured Change Set from .AsWish/llm/ (WO-20260830-0027B).</summary>
    function LoadChangeSet(const AProjectPath: string; const AChangeSetId: string = ''): TChangeSet;

    /// <summary>Compute affected projections for a node across semantic bundles (WO-20260830-0027B).</summary>
    function ComputeAffectedProjections(const ANodeId: string;
      const ABundles: TList<TSemanticBundle>): TArray<TTreeType>;

    /// <summary>
    /// Apply human-reviewed decision for a Change Set to live Canonical Spec trees (WO-20260830-0027C).
    /// Mutates trees ONLY when ADecision.Status = dsAccepted (or dtConfirm).
    /// Reject/Clarify decisions leave Canonical Spec untouched.
    /// </summary>
    function ApplyChangeSet(const AChangeSet: TChangeSet; const ADecision: TSpecDecision;
      AFunc, AMod, AView, AData: TList<TSpecNode>): TMergeStats;

    /// <summary>Format human-readable semantic review summary for a Change Set (WO-20260830-0027C).</summary>
    function FormatChangeSetReviewSummary(const AChangeSet: TChangeSet;
      const ANodes: TList<TSpecNode>): string;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  AsWish.Yaml.Parser;

{ TCandidateIngestResult }

procedure TCandidateIngestResult.Init;
begin
  Accepted := TList<TSpecNode>.Create;
  FuncNodes := TList<TSpecNode>.Create;
  ModNodes := TList<TSpecNode>.Create;
  ViewNodes := TList<TSpecNode>.Create;
  DataNodes := TList<TSpecNode>.Create;
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
  DataNodes.Free;
  Warnings.Free;
  Errors.Free;
end;

{ TAsWishCandidateIngest }

constructor TAsWishCandidateIngest.Create(ASpecStore: TAsWishStoreService);
begin
  inherited Create;
  FSpecStore := ASpecStore;
end;

class function TAsWishCandidateIngest.SplitDocuments(
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

function TAsWishCandidateIngest.Ingest(const ACandidateYaml: string;
  AExistingFunc, AExistingMod, AExistingView: TList<TSpecNode>): TCandidateIngestResult;
begin
  Result := Ingest(ACandidateYaml, AExistingFunc, AExistingMod, AExistingView, nil);
end;

function TAsWishCandidateIngest.Ingest(const ACandidateYaml: string;
  AExistingFunc, AExistingMod, AExistingView, AExistingData: TList<TSpecNode>): TCandidateIngestResult;
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
    if AExistingData <> nil then
      for var L in AExistingData do LAllKnownIds.AddOrSetValue(L.Id, True);

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

              Result.Accepted.Add(LNode);
              LAllKnownIds.AddOrSetValue(LNode.Id, True);
              case LNode.Tree of
                ttFunction: Result.FuncNodes.Add(LNode);
                ttModule:   Result.ModNodes.Add(LNode);
                ttView:     Result.ViewNodes.Add(LNode);
                ttData:     Result.DataNodes.Add(LNode);
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

procedure TAsWishCandidateIngest.ValidateNode(var ANode: TSpecNode;
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

function TAsWishCandidateIngest.MergeInto(AAccepted: TList<TSpecNode>;
  AFunc, AMod, AView: TList<TSpecNode>): TMergeStats;
begin
  Result := MergeInto(AAccepted, AFunc, AMod, AView, nil);
end;

function TAsWishCandidateIngest.MergeInto(AAccepted: TList<TSpecNode>;
  AFunc, AMod, AView, AData: TList<TSpecNode>): TMergeStats;

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
      if ACand.UserIntent <> '' then
        LExisting.UserIntent := ACand.UserIntent;

      // Data metadata is part of the node contract. An omitted optional field
      // must not erase a known schema fact, while presence flags preserve
      // explicit false values such as nullable=false or has_rollback=false.
      if ACand.Tree = ttData then
      begin
        if ACand.HasRiskScore then
        begin
          LExisting.HasRiskScore := True;
          LExisting.RiskScore := ACand.RiskScore;
        end;
        if ACand.DataType <> '' then
          LExisting.DataType := ACand.DataType;
        if ACand.HasNullable then
        begin
          LExisting.HasNullable := True;
          LExisting.Nullable := ACand.Nullable;
        end;
        if ACand.DefaultValue <> '' then
          LExisting.DefaultValue := ACand.DefaultValue;
        if Length(ACand.FieldConstraints) > 0 then
          LExisting.FieldConstraints := ACand.FieldConstraints;
        if ACand.Persistence <> '' then
          LExisting.Persistence := ACand.Persistence;
        if ACand.SourceEntity <> '' then
          LExisting.SourceEntity := ACand.SourceEntity;
        if ACand.TargetEntity <> '' then
          LExisting.TargetEntity := ACand.TargetEntity;
        if ACand.Cardinality <> '' then
          LExisting.Cardinality := ACand.Cardinality;
        if ACand.Cascade <> '' then
          LExisting.Cascade := ACand.Cascade;
        if Length(ACand.ValidStates) > 0 then
          LExisting.ValidStates := ACand.ValidStates;
        if Length(ACand.Transitions) > 0 then
          LExisting.Transitions := ACand.Transitions;
        if ACand.HasBackwardCompatible then
        begin
          LExisting.HasBackwardCompatible := True;
          LExisting.BackwardCompatible := ACand.BackwardCompatible;
        end;
        if ACand.HasHasRollback then
        begin
          LExisting.HasHasRollback := True;
          LExisting.HasRollback := ACand.HasRollback;
        end;
        if ACand.Scope <> '' then
          LExisting.Scope := ACand.Scope;
        if ACand.Enforcement <> '' then
          LExisting.Enforcement := ACand.Enforcement;
      end;

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
      ttData:     if AData <> nil then MergeOne(AData, L);
    end;
  end;
end;

class function TAsWishCandidateIngest.FormatCandidateIntentYaml(
  const AIntent: TCandidateIntent): string;
var
  LSb: TStringBuilder;
  LEscapedIntent: string;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('version: "1.2"');
    LSb.AppendLine('tree: ' + TSpecEnums.TreeTypeToStr(AIntent.Tree));
    LSb.AppendLine('node_id: "' + AIntent.NodeId + '"');
    LEscapedIntent := AIntent.UserIntent.Replace('\', '\\').Replace('"', '\"').Replace(#13, '\r').Replace(#10, '\n');
    LSb.AppendLine('user_intent: "' + LEscapedIntent + '"');
    LSb.AppendLine('author: "' + AIntent.Author + '"');
    if AIntent.CreatedAt <> 0 then
      LSb.AppendLine('created_at: "' + FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"+08:00"', AIntent.CreatedAt) + '"')
    else
      LSb.AppendLine('created_at: "' + FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"+08:00"', Now) + '"');
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

class function TAsWishCandidateIngest.ParseCandidateIntentYaml(
  const AYaml: string): TCandidateIntent;
var
  LParser: TYamlParser;
  LRoot: TYamlNode;
begin
  Result := Default(TCandidateIntent);
  if AYaml = '' then Exit;
  LParser := TYamlParser.Create;
  try
    LRoot := LParser.Parse(AYaml);
    if LRoot <> nil then
    begin
      try
        Result.Tree := TSpecEnums.TreeTypeFromStr(LRoot.GetString('tree', ''));
        Result.NodeId := LRoot.GetString('node_id', '');
        Result.UserIntent := LRoot.GetString('user_intent', '');
        Result.Author := LRoot.GetString('author', 'human');
        Result.CreatedAt := Now;
      finally
        LRoot.Free;
      end;
    end;
  finally
    LParser.Free;
  end;
end;

function TAsWishCandidateIngest.SaveCandidateIntent(
  const AProjectPath: string; const AIntent: TCandidateIntent): string;
var
  LLlmDir: string;
  LFilePath: string;
  LYaml: string;
begin
  LLlmDir := TPath.Combine(TPath.Combine(AProjectPath, '.AsWish'), 'llm');
  if not TDirectory.Exists(LLlmDir) then
    TDirectory.CreateDirectory(LLlmDir);
  LFilePath := TPath.Combine(LLlmDir, 'candidate-intent.yaml');
  LYaml := FormatCandidateIntentYaml(AIntent);
  TAsWishStoreService.AtomicWriteTextFile(LFilePath, LYaml);
  Result := LFilePath;
end;

function TAsWishCandidateIngest.LoadCandidateIntent(
  const AProjectPath: string): TCandidateIntent;
var
  LFilePath: string;
begin
  Result := Default(TCandidateIntent);
  LFilePath := TPath.Combine(TPath.Combine(TPath.Combine(AProjectPath, '.AsWish'), 'llm'), 'candidate-intent.yaml');
  if TFile.Exists(LFilePath) then
    Result := ParseCandidateIntentYaml(TFile.ReadAllText(LFilePath, TEncoding.UTF8));
end;

function TAsWishCandidateIngest.ListCandidateIntents(
  const AProjectPath: string): TArray<TCandidateIntent>;
var
  LDir: string;
  LFiles: TArray<string>;
  LList: TList<TCandidateIntent>;
  LIntent: TCandidateIntent;
begin
  LList := TList<TCandidateIntent>.Create;
  try
    LDir := TPath.Combine(TPath.Combine(TPath.Combine(AProjectPath, '.AsWish'), 'llm'), '');
    if TDirectory.Exists(LDir) then
    begin
      LFiles := TDirectory.GetFiles(LDir, 'candidate-intent*.yaml');
      for var LFile in LFiles do
      begin
        try
          LIntent := ParseCandidateIntentYaml(TFile.ReadAllText(LFile, TEncoding.UTF8));
          if LIntent.NodeId <> '' then
            LList.Add(LIntent);
        except
          // Skip malformed
        end;
      end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TAsWishCandidateIngest.CheckIntentClarity(
  const AIntent: TCandidateIntent; out AIssue: TSpecIssue): Boolean;
var
  LTrimmed: string;
begin
  AIssue := Default(TSpecIssue);
  LTrimmed := AIntent.UserIntent.Trim;
  // If intent is blank or too short (< 4 chars) or generic words, trigger grilling ticket
  if (LTrimmed.Length < 4) or SameText(LTrimmed, 'fix') or SameText(LTrimmed, 'change') or
     SameText(LTrimmed, 'update') or SameText(LTrimmed, 'todo') or
     (LTrimmed = #$4FEE#$6539) or (LTrimmed = #$6539#$4E00#$4E0B) or (LTrimmed = #$4F18#$5316) then
  begin
    AIssue.Id := 'issue-grill-' + FormatDateTime('yyyymmdd-hhnnss', Now);
    AIssue.IssueType := itGrillingTicket;
    AIssue.Severity := isHigh;
    AIssue.Status := issOpen;
    AIssue.Title := 'Clarify intent for node: ' + AIntent.NodeId;
    AIssue.Description := 'Human user intent input is insufficient or ambiguous ("' + LTrimmed +
      '"), clarification via grilling ticket is required for target, boundary, and acceptance criteria.';
    AIssue.RequiresHuman := True;
    AIssue.AffectedNodes := TArray<string>.Create(AIntent.NodeId);
    AIssue.SuggestedAction := 'Clarify user intent via grilling prompt';
    AIssue.SuggestedPrompt := 'Clarify specific outcome, constraints, and acceptance criteria for node ' + AIntent.NodeId;
    AIssue.CreatedAt := Now;
    AIssue.UpdatedAt := Now;
    Result := False;
  end
  else
    Result := True;
end;

class function TAsWishCandidateIngest.FormatChangeSetYaml(
  const AChangeSet: TChangeSet): string;
var
  LSb: TStringBuilder;
  function Escape(const S: string): string;
  begin
    Result := S.Replace('\', '\\').Replace('"', '\"').Replace(#13, '\r').Replace(#10, '\n');
  end;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('version: "1.2"');
    LSb.AppendLine('change_set_id: "' + Escape(AChangeSet.Id) + '"');
    LSb.AppendLine('intent_node_id: "' + Escape(AChangeSet.IntentNodeId) + '"');
    LSb.AppendLine('intent_tree: ' + TSpecEnums.TreeTypeToStr(AChangeSet.IntentTree));
    LSb.AppendLine('raw_user_intent: "' + Escape(AChangeSet.RawUserIntent) + '"');
    LSb.AppendLine('author: "' + Escape(AChangeSet.Author) + '"');
    if AChangeSet.CreatedAt <> 0 then
      LSb.AppendLine('created_at: "' + FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"+08:00"', AChangeSet.CreatedAt) + '"')
    else
      LSb.AppendLine('created_at: "' + FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"+08:00"', Now) + '"');

    if Length(AChangeSet.AffectedProjections) > 0 then
    begin
      LSb.AppendLine('affected_projections:');
      for var LP in AChangeSet.AffectedProjections do
        LSb.AppendLine('  - ' + TSpecEnums.TreeTypeToStr(LP));
    end
    else
      LSb.AppendLine('affected_projections: []');

    if Length(AChangeSet.Items) > 0 then
    begin
      LSb.AppendLine('items:');
      for var LItem in AChangeSet.Items do
      begin
        LSb.AppendLine('  - target_node_id: "' + Escape(LItem.TargetNodeId) + '"');
        LSb.AppendLine('    target_projection: ' + TSpecEnums.TreeTypeToStr(LItem.TargetTree));
        LSb.AppendLine('    field: "' + Escape(LItem.Field) + '"');
        LSb.AppendLine('    before: "' + Escape(LItem.BeforeValue) + '"');
        LSb.AppendLine('    after: "' + Escape(LItem.AfterValue) + '"');
        LSb.AppendLine('    source_type: ' + TSpecEnums.ChangeSourceTypeToStr(LItem.SourceType));
        if LItem.Reason <> '' then
          LSb.AppendLine('    reason: "' + Escape(LItem.Reason) + '"');
      end;
    end
    else
      LSb.AppendLine('items: []');

    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

class function TAsWishCandidateIngest.ParseChangeSetYaml(
  const AYaml: string): TChangeSet;
var
  LParser: TYamlParser;
  LRoot: TYamlNode;
  LItemsSeq: TYamlNode;
  LProjSeq: TYamlNode;
  LItemsList: TList<TChangeItem>;
  LProjList: TList<TTreeType>;
begin
  Result := Default(TChangeSet);
  if AYaml = '' then Exit;
  LParser := TYamlParser.Create;
  try
    LRoot := LParser.Parse(AYaml);
    if LRoot <> nil then
    begin
      try
        Result.Id := LRoot.GetString('change_set_id', LRoot.GetString('id', ''));
        Result.IntentNodeId := LRoot.GetString('intent_node_id', LRoot.GetString('target_node_id', ''));
        Result.IntentTree := TSpecEnums.TreeTypeFromStr(LRoot.GetString('intent_tree', LRoot.GetString('target_projection', '')));
        Result.RawUserIntent := LRoot.GetString('raw_user_intent', LRoot.GetString('user_intent', ''));
        Result.Author := LRoot.GetString('author', 'human');
        Result.CreatedAt := Now;

        LProjSeq := LRoot.GetSeq('affected_projections');
        if LProjSeq <> nil then
        begin
          LProjList := TList<TTreeType>.Create;
          try
            for var I := 0 to LProjSeq.SeqCount - 1 do
            begin
              var LItemNode := LProjSeq.SeqItem(I);
              if LItemNode <> nil then
                LProjList.Add(TSpecEnums.TreeTypeFromStr(LItemNode.AsString));
            end;
            Result.AffectedProjections := LProjList.ToArray;
          finally
            LProjList.Free;
          end;
        end;

        LItemsSeq := LRoot.GetSeq('items');
        if LItemsSeq <> nil then
        begin
          LItemsList := TList<TChangeItem>.Create;
          try
            for var I := 0 to LItemsSeq.SeqCount - 1 do
            begin
              var LMap := LItemsSeq.SeqItem(I);
              if (LMap <> nil) and (LMap.Kind = ykMap) then
              begin
                var LItem: TChangeItem;
                LItem.TargetNodeId := LMap.GetString('target_node_id', Result.IntentNodeId);
                LItem.TargetTree := TSpecEnums.TreeTypeFromStr(LMap.GetString('target_projection', ''), Result.IntentTree);
                LItem.Field := LMap.GetString('field', '');
                LItem.BeforeValue := LMap.GetString('before', '');
                LItem.AfterValue := LMap.GetString('after', '');
                LItem.SourceType := TSpecEnums.ChangeSourceTypeFromStr(LMap.GetString('source_type', 'explicit'));
                LItem.Reason := LMap.GetString('reason', '');
                LItemsList.Add(LItem);
              end;
            end;
            Result.Items := LItemsList.ToArray;
          finally
            LItemsList.Free;
          end;
        end;
      finally
        LRoot.Free;
      end;
    end;
  finally
    LParser.Free;
  end;
end;

function TAsWishCandidateIngest.GenerateNextChangeSetId(
  const AProjectPath, ANodeId: string): string;
var
  LLlmDir, LCandidateId, LFilePath: string;
  LSeq: Integer;
begin
  LLlmDir := TPath.Combine(TPath.Combine(AProjectPath, '.AsWish'), 'llm');
  LSeq := 1;
  while True do
  begin
    LCandidateId := Format('cs-%s-%.2d', [ANodeId, LSeq]);
    LFilePath := TPath.Combine(LLlmDir, 'change-set-' + LCandidateId + '.yaml');
    if not TFile.Exists(LFilePath) then
      Exit(LCandidateId);
    Inc(LSeq);
  end;
end;

function TAsWishCandidateIngest.SaveChangeSet(
  const AProjectPath: string; const AChangeSet: TChangeSet): string;
var
  LLlmDir: string;
  LFilePath, LLatestPath: string;
  LYaml: string;
begin
  LLlmDir := TPath.Combine(TPath.Combine(AProjectPath, '.AsWish'), 'llm');
  if not TDirectory.Exists(LLlmDir) then
    TDirectory.CreateDirectory(LLlmDir);
  if AChangeSet.Id <> '' then
    LFilePath := TPath.Combine(LLlmDir, 'change-set-' + AChangeSet.Id + '.yaml')
  else
    LFilePath := TPath.Combine(LLlmDir, 'change-set.yaml');
  LYaml := FormatChangeSetYaml(AChangeSet);
  TAsWishStoreService.AtomicWriteTextFile(LFilePath, LYaml);

  // Also write/update change-set.yaml as latest active pointer
  LLatestPath := TPath.Combine(LLlmDir, 'change-set.yaml');
  TAsWishStoreService.AtomicWriteTextFile(LLatestPath, LYaml);

  Result := LFilePath;
end;

function TAsWishCandidateIngest.LoadChangeSet(
  const AProjectPath: string; const AChangeSetId: string): TChangeSet;
var
  LLlmDir, LFilePath: string;
  LFiles: TArray<string>;
begin
  Result := Default(TChangeSet);
  LLlmDir := TPath.Combine(TPath.Combine(AProjectPath, '.AsWish'), 'llm');

  if AChangeSetId <> '' then
  begin
    LFilePath := TPath.Combine(LLlmDir, 'change-set-' + AChangeSetId + '.yaml');
    if not TFile.Exists(LFilePath) then
      LFilePath := TPath.Combine(LLlmDir, AChangeSetId);
  end
  else
  begin
    LFilePath := TPath.Combine(LLlmDir, 'change-set.yaml');
    if not TFile.Exists(LFilePath) and TDirectory.Exists(LLlmDir) then
    begin
      LFiles := TDirectory.GetFiles(LLlmDir, 'change-set*.yaml');
      if Length(LFiles) > 0 then
        LFilePath := LFiles[0];
    end;
  end;

  if TFile.Exists(LFilePath) then
    Result := ParseChangeSetYaml(TFile.ReadAllText(LFilePath, TEncoding.UTF8));
end;

function TAsWishCandidateIngest.ComputeAffectedProjections(
  const ANodeId: string; const ABundles: TList<TSemanticBundle>): TArray<TTreeType>;
var
  LList: TList<TTreeType>;
  procedure AddIfMissing(ATree: TTreeType);
  begin
    if not LList.Contains(ATree) then
      LList.Add(ATree);
  end;
begin
  LList := TList<TTreeType>.Create;
  try
    if ANodeId.StartsWith('func-') then AddIfMissing(ttFunction)
    else if ANodeId.StartsWith('mod-') then AddIfMissing(ttModule)
    else if ANodeId.StartsWith('view-') then AddIfMissing(ttView)
    else if ANodeId.StartsWith('data-') then AddIfMissing(ttData);

    if ABundles <> nil then
      for var LB in ABundles do
      begin
        var LInBundle := False;
        for var LNId in LB.NodeIds do
          if LNId = ANodeId then
          begin
            LInBundle := True;
            Break;
          end;
        if LInBundle then
        begin
          for var LNId in LB.NodeIds do
          begin
            if LNId.StartsWith('func-') then AddIfMissing(ttFunction)
            else if LNId.StartsWith('mod-') then AddIfMissing(ttModule)
            else if LNId.StartsWith('view-') then AddIfMissing(ttView)
            else if LNId.StartsWith('data-') then AddIfMissing(ttData);
          end;
        end;
      end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TAsWishCandidateIngest.ApplyChangeSet(
  const AChangeSet: TChangeSet; const ADecision: TSpecDecision;
  AFunc, AMod, AView, AData: TList<TSpecNode>): TMergeStats;
var
  LTargetList: TList<TSpecNode>;
  procedure EnsureDecisionRef(var ANode: TSpecNode);
  var
    LFound: Boolean;
  begin
    LFound := False;
    for var LRef in ANode.DecisionRefs do
      if LRef = ADecision.Id then
      begin
        LFound := True;
        Break;
      end;
    if not LFound and (ADecision.Id <> '') then
    begin
      SetLength(ANode.DecisionRefs, Length(ANode.DecisionRefs) + 1);
      ANode.DecisionRefs[High(ANode.DecisionRefs)] := ADecision.Id;
    end;
  end;
begin
  Result := Default(TMergeStats);

  // If decision is rejected or clarify, Canonical Spec MUST NOT be mutated (AC-03, AC-07)
  if (ADecision.Status = dsRejected) or (ADecision.DecisionType = dtReject) or
     (ADecision.DecisionType = dtClarify) then
  begin
    Exit;
  end;

  // Accept decision: apply each change item to the target node
  for var LItem in AChangeSet.Items do
  begin
    case LItem.TargetTree of
      ttFunction: LTargetList := AFunc;
      ttModule:   LTargetList := AMod;
      ttView:     LTargetList := AView;
      ttData:     LTargetList := AData;
    else
      LTargetList := nil;
    end;

    if LTargetList = nil then Continue;

    var LNodeIdx := -1;
    for var I := 0 to LTargetList.Count - 1 do
      if LTargetList[I].Id = LItem.TargetNodeId then
      begin
        LNodeIdx := I;
        Break;
      end;

    if LNodeIdx >= 0 then
    begin
      var LNode := LTargetList[LNodeIdx];
      var LFieldLower := LowerCase(LItem.Field.Trim);

      if LFieldLower = 'summary' then
        LNode.Summary := LItem.AfterValue
      else if LFieldLower = 'title' then
        LNode.Title := LItem.AfterValue
      else if LFieldLower = 'kind' then
        LNode.Kind := LItem.AfterValue
      else if LFieldLower = 'user_intent' then
        LNode.UserIntent := LItem.AfterValue;

      // Update review & gen status
      LNode.ReviewStatus := rsAccepted;
      LNode.GenStatus := gsConfirmed;
      LNode.Status := nsConfirmed;
      LNode.UpdatedAt := Now;
      EnsureDecisionRef(LNode);

      LTargetList[LNodeIdx] := LNode;
      Inc(Result.Merged);
    end;
  end;
end;

function TAsWishCandidateIngest.FormatChangeSetReviewSummary(
  const AChangeSet: TChangeSet; const ANodes: TList<TSpecNode>): string;
var
  LSb: TStringBuilder;
  LTitle: string;
begin
  LSb := TStringBuilder.Create;
  try
    LTitle := AChangeSet.IntentNodeId;
    if ANodes <> nil then
      for var LN in ANodes do
        if LN.Id = AChangeSet.IntentNodeId then
        begin
          if LN.Title <> '' then
            LTitle := LN.Title + ' (' + LN.Id + ')';
          Break;
        end;

    LSb.AppendLine('================================================================');
    LSb.AppendLine(' AsWish Change Set Review: ' + AChangeSet.Id);
    LSb.AppendLine('================================================================');
    LSb.AppendLine('Target Node:     ' + LTitle);
    LSb.AppendLine('Projection:      ' + TSpecEnums.TreeTypeToStr(AChangeSet.IntentTree));
    LSb.AppendLine('Raw User Intent: "' + AChangeSet.RawUserIntent + '"');
    LSb.AppendLine('Author:          ' + AChangeSet.Author);
    if Length(AChangeSet.AffectedProjections) > 0 then
    begin
      var LProjStr := '';
      for var LP in AChangeSet.AffectedProjections do
        LProjStr := LProjStr + TSpecEnums.TreeTypeToStr(LP) + ' ';
      LSb.AppendLine('Affected Projs:  ' + LProjStr.Trim);
    end;
    LSb.AppendLine('----------------------------------------------------------------');
    LSb.AppendLine('Proposed Changes:');
    if Length(AChangeSet.Items) = 0 then
      LSb.AppendLine('  (No change items)')
    else
      for var I := 0 to High(AChangeSet.Items) do
      begin
        var LItem := AChangeSet.Items[I];
        LSb.AppendLine(Format('  [%d] Node: %s (%s) | Field: %s | Source: %s',
          [I + 1, LItem.TargetNodeId, TSpecEnums.TreeTypeToStr(LItem.TargetTree),
           LItem.Field, TSpecEnums.ChangeSourceTypeToStr(LItem.SourceType)]));
        LSb.AppendLine('      Before: ' + IfThen(LItem.BeforeValue <> '', LItem.BeforeValue, '(empty)'));
        LSb.AppendLine('      After:  ' + IfThen(LItem.AfterValue <> '', LItem.AfterValue, '(empty)'));
        if LItem.Reason <> '' then
          LSb.AppendLine('      Reason: ' + LItem.Reason);
      end;
    LSb.AppendLine('================================================================');
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

end.
