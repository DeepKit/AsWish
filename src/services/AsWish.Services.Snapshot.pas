unit AsWish.Services.Snapshot;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.SpecStore;

type
  TAsWishSnapshotService = class
  private
    FStore: TAsWishStoreService;
    function SnapshotsRoot: string;
    function SnapshotDir(const AName: string): string;
    function SanitizeLabel(const ALabel: string): string;
    function BuildSnapshotName(const ALabel: string): string;
    procedure ValidateSnapshotName(const AName: string);
    procedure CollectSnapshotFiles(AFiles: TStrings);
    procedure WriteSnapshotMeta(const ADir, ALabel: string; AFiles: TStrings;
      const ABaseline: TAsWishBaseline);
  public
    constructor Create(AStore: TAsWishStoreService);
    function CreateSnapshot(const ALabel: string): string;
    function ListSnapshots: TArray<string>;
    procedure RestoreSnapshot(const AName: string);

    // Accepted Baseline & Visual Baseline API (WO-20260830-0027E, WO-20260830-0028)
    function NextBaselineId: string;
    function CreateBaseline(const ADecision: TSpecDecision;
      const AChangeSet: TChangeSet;
      AFunc, AMod, AView, AData: TList<TSpecNode>;
      out ABaseline: TAsWishBaseline;
      const ARendererVersion: string = '';
      const AVisualBinding: string = ''): string;
    function LoadBaseline(const ABaselineId: string;
      out ABaseline: TAsWishBaseline): Boolean;
    function VerifyBaseline(const ABaselineId: string): Boolean;
    function ListBaselines: TArray<TAsWishBaseline>;
    class function ParseBaselineFromSnapshotYaml(const AYaml, ASnapshotName: string): TAsWishBaseline; static;
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  System.Generics.Defaults,
  AsWish.Hash;

constructor TAsWishSnapshotService.Create(AStore: TAsWishStoreService);
begin
  inherited Create;
  if AStore = nil then
    raise Exception.Create('TAsWishSnapshotService requires a store');
  FStore := AStore;
end;

function TAsWishSnapshotService.SnapshotsRoot: string;
begin
  Result := TPath.Combine(FStore.BasePath, 'snapshots');
end;

function TAsWishSnapshotService.SnapshotDir(const AName: string): string;
begin
  Result := TPath.Combine(SnapshotsRoot, AName);
end;

function TAsWishSnapshotService.SanitizeLabel(
  const ALabel: string): string;
const
  UnsafeChars = ['<', '>', '"', '/', '\', '|', ':', '*', '?'];
var
  LCh: Char;
begin
  Result := '';
  for LCh in ALabel.Trim do
  begin
    if (Ord(LCh) < 32) or CharInSet(LCh, UnsafeChars) then
      Result := Result + '-'
    else
      Result := Result + LCh;
  end;
  Result := Result.Trim(['-', '.', ' ']);
  if Result = '' then
    Result := 'unlabeled';
end;

function TAsWishSnapshotService.BuildSnapshotName(
  const ALabel: string): string;
var
  LSanitized: string;
  LN: Integer;
begin
  LSanitized := SanitizeLabel(ALabel);
  Result := FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '-' + LSanitized;
  LN := 2;
  while TDirectory.Exists(SnapshotDir(Result)) do
  begin
    Result := FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '-' +
      LSanitized + '_' + IntToStr(LN);
    Inc(LN);
  end;
end;

procedure TAsWishSnapshotService.ValidateSnapshotName(const AName: string);
var
  LCh: Char;
begin
  if (AName = '') or (Pos('..', AName) > 0) then
    raise Exception.Create('Invalid snapshot name: ' + AName);
  for LCh in AName do
    if CharInSet(LCh, ['/', '\', ':']) then
      raise Exception.Create('Invalid snapshot name: ' + AName);
end;

procedure TAsWishSnapshotService.CollectSnapshotFiles(AFiles: TStrings);
  procedure CollectDir(const ARelDir: string);
  var
    LDir, LF, LRel: string;
  begin
    LDir := TPath.Combine(FStore.BasePath, ARelDir);
    if not TDirectory.Exists(LDir) then Exit;
    for LF in TDirectory.GetFiles(LDir, '*.yaml') do
    begin
      LRel := ARelDir + '\' + TPath.GetFileName(LF);
      AFiles.Add(StringReplace(LRel, '\', '/', [rfReplaceAll]));
    end;
  end;
  procedure CollectRoot(const ARelFile: string);
  begin
    if TFile.Exists(TPath.Combine(FStore.BasePath, ARelFile)) then
      AFiles.Add(ARelFile.Replace('\', '/'));
  end;
begin
  CollectDir('trees');
  CollectDir('issues');
  CollectRoot('bundles.yaml');
  CollectRoot(TPath.Combine('decisions', 'review-decisions.yaml'));
  CollectRoot(TPath.Combine('decisions', 'decisions.yaml'));
end;

procedure TAsWishSnapshotService.WriteSnapshotMeta(
  const ADir, ALabel: string; AFiles: TStrings;
  const ABaseline: TAsWishBaseline);
var
  LSb: TStringBuilder;
  LRel: string;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('version: "1.0"');
    LSb.AppendLine('label: "' + ALabel.Replace('"', '""') + '"');
    LSb.AppendLine('created_at: "' +
      FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now) + '"');
    LSb.AppendLine('files:');
    if (AFiles = nil) or (AFiles.Count = 0) then
      LSb.AppendLine('  []')
    else
      for LRel in AFiles do
        LSb.AppendLine('  - "' +
          StringReplace(LRel, '\', '/', [rfReplaceAll]) + '"');

    if ABaseline.BaselineId <> '' then
    begin
      LSb.AppendLine('baseline:');
      LSb.AppendLine('  baseline_id: "' + ABaseline.BaselineId + '"');
      LSb.AppendLine('  decision_id: "' + ABaseline.DecisionId + '"');
      LSb.AppendLine('  snapshot_name: "' + ABaseline.SnapshotName + '"');
      LSb.AppendLine('  tree_type: "' + ABaseline.TreeType + '"');
      LSb.AppendLine('  content_hash: "' + ABaseline.ContentHash + '"');
      LSb.AppendLine('  relation_hash: "' + ABaseline.RelationHash + '"');
      LSb.AppendLine('  created_at: "' + DateToISO8601(ABaseline.CreatedAt, False) + '"');
      if ABaseline.RendererVersion <> '' then
        LSb.AppendLine('  renderer_version: "' + ABaseline.RendererVersion + '"');
      if ABaseline.VisualBinding <> '' then
        LSb.AppendLine('  visual_binding: "' + ABaseline.VisualBinding + '"');
      LSb.AppendLine('  lineage:');
      LSb.AppendLine('    change_set_id: "' + ABaseline.Lineage.ChangeSetId + '"');
      LSb.AppendLine('    intent_id: "' + ABaseline.Lineage.IntentId + '"');
    end;

    TAsWishStoreService.AtomicWriteTextFile(
      TPath.Combine(ADir, 'snapshot.yaml'), LSb.ToString);
  finally
    LSb.Free;
  end;
end;

function TAsWishSnapshotService.CreateSnapshot(
  const ALabel: string): string;
var
  LFiles: TStringList;
  LName, LDst: string;
begin
  if FStore.BasePath = '' then
    raise Exception.Create(
      'Snapshot requires an initialized store (BasePath is empty)');

  if not TDirectory.Exists(FStore.BasePath) then
    TDirectory.CreateDirectory(FStore.BasePath);

  LName := BuildSnapshotName(ALabel);
  LDst := SnapshotDir(LName);
  TDirectory.CreateDirectory(LDst);

  LFiles := TStringList.Create;
  try
    CollectSnapshotFiles(LFiles);

    for var LRel in LFiles do
    begin
      var LFrom := TPath.Combine(FStore.BasePath, LRel);
      var LTo := TPath.Combine(LDst, LRel);
      var LToDir := TPath.GetDirectoryName(LTo);
      if not TDirectory.Exists(LToDir) then
        TDirectory.CreateDirectory(LToDir);
      TFile.Copy(LFrom, LTo, True);
    end;

    WriteSnapshotMeta(LDst, ALabel, LFiles, Default(TAsWishBaseline));
  finally
    LFiles.Free;
  end;
  Result := LName;
end;

function TAsWishSnapshotService.ListSnapshots: TArray<string>;
var
  LList: TList<string>;
begin
  Result := nil;
  if (FStore.BasePath = '') or not TDirectory.Exists(SnapshotsRoot) then Exit;

  LList := TList<string>.Create;
  try
    for var LDir in TDirectory.GetDirectories(SnapshotsRoot) do
      LList.Add(TPath.GetFileName(LDir));
    Result := LList.ToArray;
    TArray.Sort<string>(Result,
      TComparer<string>.Construct(
        function(const ALeft, ARight: string): Integer
        begin
          Result := CompareStr(ARight, ALeft);
        end));
  finally
    LList.Free;
  end;
end;

procedure TAsWishSnapshotService.RestoreSnapshot(const AName: string);
var
  LSnapDir, LFile, LRel, LTarget: string;
begin
  ValidateSnapshotName(AName);

  LSnapDir := SnapshotDir(AName);
  if not TDirectory.Exists(LSnapDir) then
    raise Exception.Create('Snapshot not found: ' + AName);

  CreateSnapshot('pre-restore');

  for LFile in TDirectory.GetFiles(LSnapDir, '*.yaml',
    TSearchOption.soAllDirectories) do
  begin
    LRel := Copy(LFile, Length(LSnapDir) + 2, MaxInt);
    if SameText(LRel, 'snapshot.yaml') then Continue;
    LTarget := TPath.Combine(FStore.BasePath, LRel);
    TAsWishStoreService.AtomicWriteTextFile(LTarget,
      TFile.ReadAllText(LFile, TEncoding.UTF8));
  end;
end;

function TAsWishSnapshotService.NextBaselineId: string;
var
  LList: TArray<TAsWishBaseline>;
  LMaxNum, LNum: Integer;
begin
  LList := ListBaselines;
  LMaxNum := 0;
  for var LB in LList do
  begin
    if LB.BaselineId.StartsWith('B-') then
    begin
      var LDigits := LB.BaselineId.Substring(2);
      if TryStrToInt(LDigits, LNum) and (LNum > LMaxNum) then
        LMaxNum := LNum;
    end;
  end;
  Result := Format('B-%.4d', [LMaxNum + 1]);
end;

function TAsWishSnapshotService.CreateBaseline(
  const ADecision: TSpecDecision; const AChangeSet: TChangeSet;
  AFunc, AMod, AView, AData: TList<TSpecNode>;
  out ABaseline: TAsWishBaseline; const ARendererVersion: string;
  const AVisualBinding: string): string;
var
  LFiles: TStringList;
  LName, LDst, LLabel, LBaseId, LTreeType: string;
  LContentHash, LRelationHash: string;
  LLineage: TBaselineLineage;
  LTotalNodes: Integer;
begin
  ABaseline := Default(TAsWishBaseline);
  if FStore.BasePath = '' then
    raise Exception.Create('Snapshot requires an initialized store (BasePath is empty)');

  LTotalNodes := 0;
  if AFunc <> nil then Inc(LTotalNodes, AFunc.Count);
  if AMod <> nil then Inc(LTotalNodes, AMod.Count);
  if AView <> nil then Inc(LTotalNodes, AView.Count);
  if AData <> nil then Inc(LTotalNodes, AData.Count);

  // §七.11: Fail-closed on empty / invalid snapshot
  if LTotalNodes = 0 then
    raise Exception.Create('Cannot create Accepted Baseline from empty spec state');

  if not TDirectory.Exists(FStore.BasePath) then
    TDirectory.CreateDirectory(FStore.BasePath);

  LBaseId := NextBaselineId;
  LLabel := 'accepted-baseline-' + LBaseId;
  if ADecision.Id <> '' then
    LLabel := LLabel + '-' + ADecision.Id;

  LName := BuildSnapshotName(LLabel);
  LDst := SnapshotDir(LName);
  TDirectory.CreateDirectory(LDst);

  LContentHash := TSpecHash.SnapshotContentHash(AFunc, AMod, AView, AData);
  LRelationHash := TSpecHash.SnapshotRelationHash(AFunc, AMod, AView, AData);

  LTreeType := 'all';
  if AChangeSet.IntentTree = ttFunction then LTreeType := 'function'
  else if AChangeSet.IntentTree = ttView then LTreeType := 'view'
  else if AChangeSet.IntentTree = ttModule then LTreeType := 'module'
  else if AChangeSet.IntentTree = ttData then LTreeType := 'data';

  LLineage := TBaselineLineage.CreateNew(AChangeSet.Id, AChangeSet.IntentNodeId);
  ABaseline := TAsWishBaseline.CreateNew(LBaseId, ADecision.Id, LName, LTreeType,
    LContentHash, LRelationHash, LLineage, ARendererVersion, AVisualBinding);

  LFiles := TStringList.Create;
  try
    CollectSnapshotFiles(LFiles);

    for var LRel in LFiles do
    begin
      var LFrom := TPath.Combine(FStore.BasePath, LRel);
      var LTo := TPath.Combine(LDst, LRel);
      var LToDir := TPath.GetDirectoryName(LTo);
      if not TDirectory.Exists(LToDir) then
        TDirectory.CreateDirectory(LToDir);
      TFile.Copy(LFrom, LTo, True);
    end;

    WriteSnapshotMeta(LDst, LLabel, LFiles, ABaseline);
  finally
    LFiles.Free;
  end;
  Result := LBaseId;
end;

function TAsWishSnapshotService.LoadBaseline(
  const ABaselineId: string; out ABaseline: TAsWishBaseline): Boolean;
var
  LBaselines: TArray<TAsWishBaseline>;
begin
  ABaseline := Default(TAsWishBaseline);
  Result := False;
  if ABaselineId = '' then Exit;
  LBaselines := ListBaselines;
  for var LB in LBaselines do
    if (LB.BaselineId = ABaselineId) or (LB.SnapshotName = ABaselineId) then
    begin
      ABaseline := LB;
      Exit(True);
    end;
end;

function TAsWishSnapshotService.VerifyBaseline(const ABaselineId: string): Boolean;
var
  LBaseline: TAsWishBaseline;
  LSnapDir, LFuncFile, LModFile, LViewFile, LDataFile: string;
  LFunc, LMod, LView, LData: TList<TSpecNode>;
  LCompContentHash, LCompRelationHash: string;
  LTempStore: TAsWishStoreService;
begin
  Result := False;
  if not LoadBaseline(ABaselineId, LBaseline) then Exit;

  LSnapDir := SnapshotDir(LBaseline.SnapshotName);
  if not TDirectory.Exists(LSnapDir) then Exit;

  LTempStore := TAsWishStoreService.Create;
  try
    LTempStore.InitializeDirect(LSnapDir);
    LFunc := nil; LMod := nil; LView := nil; LData := nil;
    try
      LFuncFile := TPath.Combine(LSnapDir, 'trees\function-tree.yaml');
      if TFile.Exists(LFuncFile) then
        LFunc := LTempStore.ReadTreeFile('trees/function-tree.yaml');

      LModFile := TPath.Combine(LSnapDir, 'trees\module-tree.yaml');
      if TFile.Exists(LModFile) then
        LMod := LTempStore.ReadTreeFile('trees/module-tree.yaml');

      LViewFile := TPath.Combine(LSnapDir, 'trees\view-tree.yaml');
      if TFile.Exists(LViewFile) then
        LView := LTempStore.ReadTreeFile('trees/view-tree.yaml');

      LDataFile := TPath.Combine(LSnapDir, 'trees\data-tree.yaml');
      if TFile.Exists(LDataFile) then
        LData := LTempStore.ReadTreeFile('trees/data-tree.yaml');

      LCompContentHash := TSpecHash.SnapshotContentHash(LFunc, LMod, LView, LData);
      LCompRelationHash := TSpecHash.SnapshotRelationHash(LFunc, LMod, LView, LData);

      Result := (LCompContentHash = LBaseline.ContentHash) and
                (LCompRelationHash = LBaseline.RelationHash);
    finally
      LFunc.Free;
      LMod.Free;
      LView.Free;
      LData.Free;
    end;
  finally
    LTempStore.Free;
  end;
end;

function TAsWishSnapshotService.ListBaselines: TArray<TAsWishBaseline>;
var
  LList: TList<TAsWishBaseline>;
  LMetaFile, LYaml: string;
  LBaseline: TAsWishBaseline;
begin
  Result := nil;
  if (FStore.BasePath = '') or not TDirectory.Exists(SnapshotsRoot) then Exit;

  LList := TList<TAsWishBaseline>.Create;
  try
    for var LDir in TDirectory.GetDirectories(SnapshotsRoot) do
    begin
      LMetaFile := TPath.Combine(LDir, 'snapshot.yaml');
      if TFile.Exists(LMetaFile) then
      begin
        LYaml := TFile.ReadAllText(LMetaFile, TEncoding.UTF8);
        LBaseline := ParseBaselineFromSnapshotYaml(LYaml, TPath.GetFileName(LDir));
        if LBaseline.BaselineId <> '' then
          LList.Add(LBaseline);
      end;
    end;
    Result := LList.ToArray;
    TArray.Sort<TAsWishBaseline>(Result,
      TComparer<TAsWishBaseline>.Construct(
        function(const A, B: TAsWishBaseline): Integer
        begin
          Result := CompareStr(B.BaselineId, A.BaselineId);
        end));
  finally
    LList.Free;
  end;
end;

class function TAsWishSnapshotService.ParseBaselineFromSnapshotYaml(
  const AYaml, ASnapshotName: string): TAsWishBaseline;
var
  LLines: TArray<string>;
  LLine, LTrim: string;
  LInBaseline, LInLineage: Boolean;
begin
  Result := Default(TAsWishBaseline);
  Result.SnapshotName := ASnapshotName;
  LLines := AYaml.Split([#13#10, #10, #13]);
  LInBaseline := False;
  LInLineage := False;

  for LLine in LLines do
  begin
    LTrim := LLine.Trim;
    if LTrim.StartsWith('baseline:') then
    begin
      LInBaseline := True;
      LInLineage := False;
      Continue;
    end;

    if LInBaseline then
    begin
      if (LLine <> '') and (LLine[1] <> ' ') and (LLine[1] <> #9) then
      begin
        // Exited baseline section
        LInBaseline := False;
        LInLineage := False;
        Continue;
      end;

      if LTrim.StartsWith('lineage:') then
      begin
        LInLineage := True;
        Continue;
      end;

      if LInLineage then
      begin
        if LTrim.StartsWith('change_set_id:') then
          Result.Lineage.ChangeSetId := LTrim.Substring(14).Trim.Trim(['"'])
        else if LTrim.StartsWith('intent_id:') then
          Result.Lineage.IntentId := LTrim.Substring(10).Trim.Trim(['"']);
      end
      else
      begin
        if LTrim.StartsWith('baseline_id:') then
          Result.BaselineId := LTrim.Substring(12).Trim.Trim(['"'])
        else if LTrim.StartsWith('decision_id:') then
          Result.DecisionId := LTrim.Substring(12).Trim.Trim(['"'])
        else if LTrim.StartsWith('snapshot_name:') then
          Result.SnapshotName := LTrim.Substring(14).Trim.Trim(['"'])
        else if LTrim.StartsWith('tree_type:') then
          Result.TreeType := LTrim.Substring(10).Trim.Trim(['"'])
        else if LTrim.StartsWith('content_hash:') then
          Result.ContentHash := LTrim.Substring(13).Trim.Trim(['"'])
        else if LTrim.StartsWith('relation_hash:') then
          Result.RelationHash := LTrim.Substring(14).Trim.Trim(['"'])
        else if LTrim.StartsWith('renderer_version:') then
          Result.RendererVersion := LTrim.Substring(17).Trim.Trim(['"'])
        else if LTrim.StartsWith('visual_binding:') then
          Result.VisualBinding := LTrim.Substring(15).Trim.Trim(['"'])
        else if LTrim.StartsWith('created_at:') then
        begin
          var LDateStr := LTrim.Substring(11).Trim.Trim(['"']);
          try
            Result.CreatedAt := ISO8601ToDate(LDateStr);
          except
            Result.CreatedAt := Now;
          end;
        end;
      end;
    end;
  end;
end;

end.
