unit DeepSpec.Services.Snapshot;

interface

uses
  System.SysUtils,
  System.Classes,
  DeepSpec.Services.SpecStore;

type
  TDeepSpecSnapshotService = class
  private
    FStore: TDeepSpecStoreService;
    function SnapshotsRoot: string;
    function SnapshotDir(const AName: string): string;
    function SanitizeLabel(const ALabel: string): string;
    function BuildSnapshotName(const ALabel: string): string;
    procedure ValidateSnapshotName(const AName: string);
    procedure WriteSnapshotMeta(const ADir, ALabel: string; AFiles: TStrings);
  public
    constructor Create(AStore: TDeepSpecStoreService);
    function CreateSnapshot(const ALabel: string): string;
    function ListSnapshots: TArray<string>;
    procedure RestoreSnapshot(const AName: string);
  end;

implementation

uses
  System.IOUtils,
  System.Generics.Collections,
  System.Generics.Defaults;

constructor TDeepSpecSnapshotService.Create(AStore: TDeepSpecStoreService);
begin
  inherited Create;
  if AStore = nil then
    raise Exception.Create('TDeepSpecSnapshotService requires a store');
  FStore := AStore;
end;

function TDeepSpecSnapshotService.SnapshotsRoot: string;
begin
  Result := TPath.Combine(FStore.BasePath, 'snapshots');
end;

function TDeepSpecSnapshotService.SnapshotDir(const AName: string): string;
begin
  Result := TPath.Combine(SnapshotsRoot, AName);
end;

function TDeepSpecSnapshotService.SanitizeLabel(
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

function TDeepSpecSnapshotService.BuildSnapshotName(
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

procedure TDeepSpecSnapshotService.ValidateSnapshotName(const AName: string);
var
  LCh: Char;
begin
  if (AName = '') or (Pos('..', AName) > 0) then
    raise Exception.Create('Invalid snapshot name: ' + AName);
  for LCh in AName do
    if CharInSet(LCh, ['/', '\', ':']) then
      raise Exception.Create('Invalid snapshot name: ' + AName);
end;

procedure TDeepSpecSnapshotService.WriteSnapshotMeta(
  const ADir, ALabel: string; AFiles: TStrings);
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
    if AFiles.Count = 0 then
      LSb.AppendLine('  []')
    else
      for LRel in AFiles do
        LSb.AppendLine('  - "' +
          StringReplace(LRel, '\', '/', [rfReplaceAll]) + '"');
    TDeepSpecStoreService.AtomicWriteTextFile(
      TPath.Combine(ADir, 'snapshot.yaml'), LSb.ToString);
  finally
    LSb.Free;
  end;
end;

function TDeepSpecSnapshotService.CreateSnapshot(
  const ALabel: string): string;
var
  LFiles: TStringList;
  LName, LDst: string;

  procedure CollectDirFiles(const ARelDir: string);
  var
    LDir, LF, LRel: string;
  begin
    LDir := TPath.Combine(FStore.BasePath, ARelDir);
    if not TDirectory.Exists(LDir) then Exit;
    for LF in TDirectory.GetFiles(LDir, '*.yaml') do
    begin
      LRel := ARelDir + '\' + TPath.GetFileName(LF);
      LFiles.Add(StringReplace(LRel, '\', '/', [rfReplaceAll]));
    end;
  end;

  procedure CollectRootFile(const ARelFile: string);
  begin
    if TFile.Exists(TPath.Combine(FStore.BasePath, ARelFile)) then
      LFiles.Add(ARelFile.Replace('\', '/'));
  end;

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
    CollectDirFiles('trees');
    CollectDirFiles('issues');
    CollectRootFile('bundles.yaml');
    CollectRootFile(TPath.Combine('decisions', 'review-decisions.yaml'));

    for var LRel in LFiles do
    begin
      var LFrom := TPath.Combine(FStore.BasePath, LRel);
      var LTo := TPath.Combine(LDst, LRel);
      var LToDir := TPath.GetDirectoryName(LTo);
      if not TDirectory.Exists(LToDir) then
        TDirectory.CreateDirectory(LToDir);
      TFile.Copy(LFrom, LTo, True);
    end;

    WriteSnapshotMeta(LDst, ALabel, LFiles);
  finally
    LFiles.Free;
  end;
  Result := LName;
end;

function TDeepSpecSnapshotService.ListSnapshots: TArray<string>;
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

procedure TDeepSpecSnapshotService.RestoreSnapshot(const AName: string);
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
    TDeepSpecStoreService.AtomicWriteTextFile(LTarget,
      TFile.ReadAllText(LFile, TEncoding.UTF8));
  end;
end;

end.
