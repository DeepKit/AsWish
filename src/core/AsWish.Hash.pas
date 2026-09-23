
{ ============================================================================
  AsWish.Hash

  SHA-256 utilities for content_hash and relation_hash computation.
  Implements the hashing algorithm from protocol §4.3.
  ============================================================================ }

unit AsWish.Hash;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Hash,
  AsWish.Models;

type
  TSpecHash = class
  public
    /// <summary>
    /// Compute SHA-256 hex digest of a string.
    /// </summary>
    class function Sha256Hex(const AInput: string): string; static;

    /// <summary>
    /// Compute SHA-256 hex digest of a file.
    /// Returns empty string for files larger than AMaxBytes (default 10MB).
    /// </summary>
    class function FileSha256Hex(const APath: string;
      AMaxBytes: Int64 = 10 * 1024 * 1024): string; static;

    /// <summary>
    /// Compute content_hash for a node per protocol §4.3.
    /// Includes: id, title, kind, summary, status, confidence,
    /// source_refs (sorted by ref_id), source_layer, acceptance_criteria,
    /// not_doing. (parent_id is in RelationHash for clean separation).
    /// </summary>
    class function NodeContentHash(const ANode: TSpecNode): string; static;

    /// <summary>
    /// Compute relation_hash for a node per protocol §4.3.
    /// Includes: parent_id, decision_refs, issue_refs, related_*, tags.
    /// </summary>
    class function NodeRelationHash(const ANode: TSpecNode): string; static;

    /// <summary>
    /// Compute snapshot-level ContentHash across tree node lists (deterministic, sorted by ID).
    /// </summary>
    class function SnapshotContentHash(ANodes: TList<TSpecNode>): string; overload; static;
    class function SnapshotContentHash(AFunc, AMod, AView, AData: TList<TSpecNode>): string; overload; static;

    /// <summary>
    /// Compute snapshot-level RelationHash across tree node lists (deterministic, sorted by ID).
    /// </summary>
    class function SnapshotRelationHash(ANodes: TList<TSpecNode>): string; overload; static;
    class function SnapshotRelationHash(AFunc, AMod, AView, AData: TList<TSpecNode>): string; overload; static;

    /// <summary>
    /// Compute content hash for a commons lesson record.
    /// </summary>
    class function LessonContentHash(const ALesson: TSpecCommonsLesson): string; static;
  end;

implementation

uses
  System.IOUtils,
  System.Generics.Defaults;

class function TSpecHash.Sha256Hex(const AInput: string): string;
begin
  Result := LowerCase(THashSHA2.GetHashString(AInput, THashSHA2.TSHA2Version.SHA256));
end;

class function TSpecHash.FileSha256Hex(const APath: string; AMaxBytes: Int64): string;
begin
  if not TFile.Exists(APath) then
    Exit('');

  var LSize := TFile.GetSize(APath);
  if LSize > AMaxBytes then
    Exit('');

  var LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try
    Result := LowerCase(THashSHA2.GetHashString(LStream, THashSHA2.TSHA2Version.SHA256));
  finally
    LStream.Free;
  end;
end;

class function TSpecHash.NodeContentHash(const ANode: TSpecNode): string;
var
  LSb: TStringBuilder;
  LRefs: TArray<TSourceRef>;
begin
  LSb := TStringBuilder.Create;
  try
    // Field order matters for hash stability
    LSb.Append('id=').Append(ANode.Id).Append('|');
    LSb.Append('title=').Append(ANode.Title).Append('|');
    LSb.Append('kind=').Append(ANode.Kind).Append('|');
    LSb.Append('summary=').Append(ANode.Summary).Append('|');
    LSb.Append('status=').Append(TSpecEnums.NodeStatusToStr(ANode.Status)).Append('|');
    LSb.Append('confidence=').Append(TSpecEnums.ConfidenceToStr(ANode.Confidence)).Append('|');
    LSb.Append('source_layer=').Append(TSpecEnums.SourceLayerToStr(ANode.SourceLayer)).Append('|');

    // Sort source_refs by ref_id alphabetically (per §4.3)
    LRefs := Copy(ANode.SourceRefs);
    TArray.Sort<TSourceRef>(LRefs,
      TComparer<TSourceRef>.Construct(
        function(const A, B: TSourceRef): Integer
        begin
          Result := CompareStr(A.RefId, B.RefId);
        end));

    LSb.Append('source_refs=[');
    for var I := 0 to High(LRefs) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(LRefs[I].RefId);
      if LRefs[I].Relevance <> '' then
        LSb.Append(':').Append(LRefs[I].Relevance);
    end;
    LSb.Append(']|');

    LSb.Append('acceptance_criteria=[');
    for var I := 0 to High(ANode.AcceptanceCriteria) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.AcceptanceCriteria[I]);
    end;
    LSb.Append(']|');

    LSb.Append('not_doing=[');
    for var I := 0 to High(ANode.NotDoing) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.NotDoing[I]);
    end;
    LSb.Append(']');

    Result := Sha256Hex(LSb.ToString);
  finally
    LSb.Free;
  end;
end;

class function TSpecHash.NodeRelationHash(const ANode: TSpecNode): string;
var
  LSb: TStringBuilder;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.Append('parent_id=').Append(ANode.ParentId).Append('|');

    LSb.Append('decision_refs=[');
    for var I := 0 to High(ANode.DecisionRefs) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.DecisionRefs[I]);
    end;
    LSb.Append(']|');

    LSb.Append('issue_refs=[');
    for var I := 0 to High(ANode.IssueRefs) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.IssueRefs[I]);
    end;
    LSb.Append(']|');

    LSb.Append('related_functions=[');
    for var I := 0 to High(ANode.RelatedFunctions) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.RelatedFunctions[I]);
    end;
    LSb.Append(']|');

    LSb.Append('related_modules=[');
    for var I := 0 to High(ANode.RelatedModules) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.RelatedModules[I]);
    end;
    LSb.Append(']|');

    LSb.Append('related_views=[');
    for var I := 0 to High(ANode.RelatedViews) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.RelatedViews[I]);
    end;
    LSb.Append(']|');

    LSb.Append('tags=[');
    for var I := 0 to High(ANode.Tags) do
    begin
      if I > 0 then LSb.Append(',');
      LSb.Append(ANode.Tags[I]);
    end;
    LSb.Append(']');

    Result := Sha256Hex(LSb.ToString);
  finally
    LSb.Free;
  end;
end;

class function TSpecHash.SnapshotContentHash(ANodes: TList<TSpecNode>): string;
var
  LSb: TStringBuilder;
  LSorted: TList<TSpecNode>;
begin
  if (ANodes = nil) or (ANodes.Count = 0) then
    Exit(Sha256Hex(''));

  LSorted := TList<TSpecNode>.Create;
  LSb := TStringBuilder.Create;
  try
    LSorted.AddRange(ANodes);
    LSorted.Sort(TComparer<TSpecNode>.Construct(
      function(const A, B: TSpecNode): Integer
      begin
        Result := CompareStr(A.Id, B.Id);
      end));

    for var LNode in LSorted do
      LSb.Append(LNode.Id).Append(':').Append(NodeContentHash(LNode)).Append(';');

    Result := Sha256Hex(LSb.ToString);
  finally
    LSb.Free;
    LSorted.Free;
  end;
end;

class function TSpecHash.SnapshotContentHash(AFunc, AMod, AView,
  AData: TList<TSpecNode>): string;
var
  LAll: TList<TSpecNode>;
begin
  LAll := TList<TSpecNode>.Create;
  try
    if AFunc <> nil then LAll.AddRange(AFunc);
    if AMod <> nil then LAll.AddRange(AMod);
    if AView <> nil then LAll.AddRange(AView);
    if AData <> nil then LAll.AddRange(AData);
    Result := SnapshotContentHash(LAll);
  finally
    LAll.Free;
  end;
end;

class function TSpecHash.SnapshotRelationHash(ANodes: TList<TSpecNode>): string;
var
  LSb: TStringBuilder;
  LSorted: TList<TSpecNode>;
begin
  if (ANodes = nil) or (ANodes.Count = 0) then
    Exit(Sha256Hex(''));

  LSorted := TList<TSpecNode>.Create;
  LSb := TStringBuilder.Create;
  try
    LSorted.AddRange(ANodes);
    LSorted.Sort(TComparer<TSpecNode>.Construct(
      function(const A, B: TSpecNode): Integer
      begin
        Result := CompareStr(A.Id, B.Id);
      end));

    for var LNode in LSorted do
      LSb.Append(LNode.Id).Append(':').Append(NodeRelationHash(LNode)).Append(';');

    Result := Sha256Hex(LSb.ToString);
  finally
    LSb.Free;
    LSorted.Free;
  end;
end;

class function TSpecHash.SnapshotRelationHash(AFunc, AMod, AView,
  AData: TList<TSpecNode>): string;
var
  LAll: TList<TSpecNode>;
begin
  LAll := TList<TSpecNode>.Create;
  try
    if AFunc <> nil then LAll.AddRange(AFunc);
    if AMod <> nil then LAll.AddRange(AMod);
    if AView <> nil then LAll.AddRange(AView);
    if AData <> nil then LAll.AddRange(AData);
    Result := SnapshotRelationHash(LAll);
  finally
    LAll.Free;
  end;
end;

class function TSpecHash.LessonContentHash(const ALesson: TSpecCommonsLesson): string;
var
  LSb: TStringBuilder;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.Append('id=').Append(ALesson.Id).Append('|');
    LSb.Append('title=').Append(ALesson.Title).Append('|');
    LSb.Append('human_takeaway=').Append(ALesson.HumanTakeaway).Append('|');
    LSb.Append('trigger_pattern=').Append(ALesson.TriggerPattern).Append('|');
    LSb.Append('wrong_expression=').Append(ALesson.WrongExpression).Append('|');
    LSb.Append('right_expression=').Append(ALesson.RightExpression).Append('|');
    LSb.Append('baseline_ref=').Append(ALesson.BaselineRef).Append('|');
    LSb.Append('difference_ref=').Append(ALesson.DifferenceRef).Append('|');
    LSb.Append('domain=').Append(ALesson.Domain).Append('|');
    LSb.Append('contributed_by=').Append(ALesson.ContributedBy).Append('|');
    LSb.Append('story_mode=').Append(ALesson.StoryMode);
    Result := Sha256Hex(LSb.ToString);
  finally
    LSb.Free;
  end;
end;

end.
