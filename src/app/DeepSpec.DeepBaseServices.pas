{ ============================================================================
  DeepSpec.DeepBaseServices

  DeepBase 深度集成（第一批）：把 DeepShell 默认的内存态服务替换为
  DB1(ConfigDB) 持久化实现，对齐 DeepBase 集成总览 §2.2 与 59 号文档
  （MRU/Layout/Settings 设计）：

    TDeepSpecDbRecentService   IShellRecentService   → DB1 Config JSON
    TDeepSpecDbSettingsStore   IShellSettingsStore   → DB1 Config 直映射
    TDeepSpecDbLayoutService   IShellLayoutService   → DB1 Config JSON

  注册方式：MainForm.RegisterServices 里用 Services.RegisterService 注册
  同名 CAP（shell.recent / shell.settings / shell.layout），DeepShell 的
  ResolveServicesFromRegistry 会自动替换默认内存实现（61 号文档扩展点）。

  可靠性：DB1 不可用时（InitializeEx 失败）全部回落内存行为，不抛异常；
  每次变更即写回（启动读取一次），upsert 语义、容量上限 10。
  ============================================================================ }

unit DeepSpec.DeepBaseServices;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DeepBase.VCL.DeepShell.Intf,
  DeepBase.VCL.DeepShell.Types;

type
  /// <summary>DB1-backed IShellRecentService. Persists the recent list as
  ///  JSON in the ConfigDB (key shell.recent.items). Falls back to in-memory
  ///  behaviour when DB1 is unavailable.</summary>
  TDeepSpecDbRecentService = class(TInterfacedObject, IShellRecentService)
  private
    FItems: TList<TShellRecentItem>;
    FLock: TObject;
    FCapacity: Integer;
    procedure LoadFromDb;
    procedure SaveToDb;
    function FindIndex(AKind: TShellRecentKind; const AItemKey: string): Integer;
  public
    constructor Create(ACapacity: Integer = 10);
    destructor Destroy; override;
    procedure AddRecent(const AItem: TShellRecentItem);
    procedure AddRecentProject(const AProjectId, APath, ADisplayName,
      ALayoutKey: string);
    function GetRecent(AKind: TShellRecentKind): TArray<TShellRecentItem>;
    function GetRecentProjects: TArray<TShellRecentItem>;
    procedure MarkInvalid(AKind: TShellRecentKind; const AItemKey: string);
    procedure Remove(AKind: TShellRecentKind; const AItemKey: string);
    procedure Clear;
  end;

  /// <summary>DB1-backed IShellSettingsStore: straight mapping to ConfigDB
  ///  keys (prefixed shell.setting.).</summary>
  TDeepSpecDbSettingsStore = class(TInterfacedObject, IShellSettingsStore)
  private
    function MapKey(const AKey: string): string;
  public
    function ReadString(const AKey, ADefault: string): string;
    procedure WriteString(const AKey, AValue: string);
    function ReadBool(const AKey: string; ADefault: Boolean): Boolean;
    procedure WriteBool(const AKey: string; AValue: Boolean);
    function ReadInteger(const AKey: string; ADefault: Integer): Integer;
    procedure WriteInteger(const AKey: string; AValue: Integer);
    procedure RemoveKey(const AKey: string);
  end;

  /// <summary>DB1-backed IShellLayoutService: persists global + per-project
  ///  window layout as JSON in ConfigDB.</summary>
  TDeepSpecDbLayoutService = class(TInterfacedObject, IShellLayoutService)
  private
    function KeyFor(const AProjectId: string): string;
  public
    procedure SaveGlobalLayout(const AState: TShellLayoutState);
    function TryLoadGlobalLayout(out AState: TShellLayoutState): Boolean;
    procedure SaveProjectLayout(const AProjectId: string;
      const AState: TShellLayoutState);
    function TryLoadProjectLayout(const AProjectId: string;
      out AState: TShellLayoutState): Boolean;
    procedure ResetGlobalLayout;
    procedure ResetProjectLayout(const AProjectId: string);
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.JSON,
  DeepBase.Config,
  DeepBase.Manager;

const
  CFG_RECENT = 'shell.recent.items';
  CFG_SETTINGS_PREFIX = 'shell.setting.';
  CFG_LAYOUT_PREFIX = 'shell.layout.';

function ConfigAvailable: Boolean;
begin
  Result := False;
  try
    Result := DeepBase.Manager.DeepBase <> nil;
  except
    Result := False;
  end;
end;

{ ---------- JSON helpers ---------- }

function RecentToJson(const AItem: TShellRecentItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('kind', TJSONNumber.Create(Ord(AItem.Kind)));
  Result.AddPair('key', AItem.ItemKey);
  Result.AddPair('pid', AItem.ProjectId);
  Result.AddPair('path', AItem.Path);
  Result.AddPair('name', AItem.DisplayName);
  Result.AddPair('layout', AItem.LayoutKey);
  Result.AddPair('at', TJSONNumber.Create(
    Int64(DateTimeToUnix(AItem.LastOpenedAt))));
  Result.AddPair('invalid', AItem.Invalid);
end;

function JsonToRecent(const AObj: TJSONObject): TShellRecentItem;
begin
  Result := Default(TShellRecentItem);
  Result.Kind := TShellRecentKind(AObj.GetValue<Integer>('kind', 0));
  Result.ItemKey := AObj.GetValue<string>('key', '');
  Result.ProjectId := AObj.GetValue<string>('pid', '');
  Result.Path := AObj.GetValue<string>('path', '');
  Result.DisplayName := AObj.GetValue<string>('name', '');
  Result.LayoutKey := AObj.GetValue<string>('layout', '');
  Result.LastOpenedAt := UnixToDateTime(
    AObj.GetValue<Int64>('at', 0), False);
  Result.Invalid := AObj.GetValue<Boolean>('invalid', False);
end;

function LayoutToJson(const AState: TShellLayoutState): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('key', AState.LayoutKey);
  Result.AddPair('updated', TJSONNumber.Create(
    Int64(DateTimeToUnix(AState.UpdatedAt))));
  Result.AddPair('seq', TJSONNumber.Create(AState.Sequence));
  Result.AddPair('writer', AState.WriterInstanceId);
  Result.AddPair('left', TJSONNumber.Create(AState.MainLeft));
  Result.AddPair('top', TJSONNumber.Create(AState.MainTop));
  Result.AddPair('width', TJSONNumber.Create(AState.MainWidth));
  Result.AddPair('height', TJSONNumber.Create(AState.MainHeight));
  Result.AddPair('maximized', AState.Maximized);
  Result.AddPair('view', AState.CurrentViewId);
  Result.AddPair('tab', AState.CurrentTabId);
  Result.AddPair('twLeft', TJSONNumber.Create(AState.LeftToolWindow.Left));
  Result.AddPair('twTop', TJSONNumber.Create(AState.LeftToolWindow.Top));
  Result.AddPair('twWidth', TJSONNumber.Create(AState.LeftToolWindow.Width));
  Result.AddPair('twHeight', TJSONNumber.Create(AState.LeftToolWindow.Height));
  Result.AddPair('twVisible', AState.LeftToolWindow.Visible);
end;

function JsonToLayout(const AObj: TJSONObject): TShellLayoutState;
begin
  Result := Default(TShellLayoutState);
  Result.LayoutKey := AObj.GetValue<string>('key', '');
  Result.UpdatedAt := UnixToDateTime(
    AObj.GetValue<Int64>('updated', 0), False);
  Result.Sequence := AObj.GetValue<Int64>('seq', 0);
  Result.WriterInstanceId := AObj.GetValue<string>('writer', '');
  Result.MainLeft := AObj.GetValue<Integer>('left', 0);
  Result.MainTop := AObj.GetValue<Integer>('top', 0);
  Result.MainWidth := AObj.GetValue<Integer>('width', 0);
  Result.MainHeight := AObj.GetValue<Integer>('height', 0);
  Result.Maximized := AObj.GetValue<Boolean>('maximized', False);
  Result.CurrentViewId := AObj.GetValue<string>('view', '');
  Result.CurrentTabId := AObj.GetValue<string>('tab', '');
  Result.LeftToolWindow.Left := AObj.GetValue<Integer>('twLeft', 0);
  Result.LeftToolWindow.Top := AObj.GetValue<Integer>('twTop', 0);
  Result.LeftToolWindow.Width := AObj.GetValue<Integer>('twWidth', 0);
  Result.LeftToolWindow.Height := AObj.GetValue<Integer>('twHeight', 0);
  Result.LeftToolWindow.Visible := AObj.GetValue<Boolean>('twVisible', False);
end;

{ ---------- TDeepSpecDbRecentService ---------- }

constructor TDeepSpecDbRecentService.Create(ACapacity: Integer);
begin
  inherited Create;
  FItems := TList<TShellRecentItem>.Create;
  FLock := TObject.Create;
  FCapacity := ACapacity;
  LoadFromDb;
end;

destructor TDeepSpecDbRecentService.Destroy;
begin
  FItems.Free;
  FLock.Free;
  inherited;
end;

procedure TDeepSpecDbRecentService.LoadFromDb;
var
  LJson: string;
  LArr: TJSONArray;
  I: Integer;
begin
  if not ConfigAvailable then Exit;
  try
    // Defensive: never append to a stale list if Load is ever re-invoked
    // (multi-LLM review finding; construction-time call only today).
    FItems.Clear;
    LJson := DeepBase.Config.GetConfig(CFG_RECENT, '');
    if LJson = '' then Exit;
    LArr := TJSONObject.ParseJSONValue(LJson) as TJSONArray;
    if LArr = nil then Exit;
    try
      for I := 0 to LArr.Count - 1 do
        if LArr.Items[I] is TJSONObject then
          FItems.Add(JsonToRecent(TJSONObject(LArr.Items[I])));
    finally
      LArr.Free;
    end;
  except
    // Corrupt or unreadable config: start empty, keep the app usable.
    FItems.Clear;
  end;
end;

procedure TDeepSpecDbRecentService.SaveToDb;
var
  LArr: TJSONArray;
  LItem: TShellRecentItem;
begin
  if not ConfigAvailable then Exit;
  try
    LArr := TJSONArray.Create;
    try
      for LItem in FItems do
        LArr.AddElement(RecentToJson(LItem));
      DeepBase.Config.SetConfig(CFG_RECENT, LArr.ToJSON);
    finally
      LArr.Free;
    end;
  except
    // DB write failure must never crash the shell.
  end;
end;

function TDeepSpecDbRecentService.FindIndex(AKind: TShellRecentKind;
  const AItemKey: string): Integer;
begin
  for Result := 0 to FItems.Count - 1 do
    if (FItems[Result].Kind = AKind) and
       (FItems[Result].ItemKey = AItemKey) then
      Exit;
  Result := -1;
end;

procedure TDeepSpecDbRecentService.AddRecent(const AItem: TShellRecentItem);
var
  LIdx: Integer;
begin
  if AItem.ItemKey = '' then Exit;
  LIdx := FindIndex(AItem.Kind, AItem.ItemKey);
  if LIdx >= 0 then
  begin
    var LExisting := FItems[LIdx];
    LExisting.DisplayName := AItem.DisplayName;
    LExisting.Path := AItem.Path;
    LExisting.ProjectId := AItem.ProjectId;
    LExisting.LayoutKey := AItem.LayoutKey;
    LExisting.LastOpenedAt := AItem.LastOpenedAt;
    LExisting.Invalid := False;
    FItems.Delete(LIdx);
    FItems.Insert(0, LExisting);
  end
  else
  begin
    // Upsert semantics: newest first, cap capacity.
    FItems.Insert(0, AItem);
    while FItems.Count > FCapacity do
      FItems.Delete(FItems.Count - 1);
  end;
  SaveToDb;
end;

procedure TDeepSpecDbRecentService.AddRecentProject(const AProjectId, APath,
  ADisplayName, ALayoutKey: string);
var
  LItem: TShellRecentItem;
begin
  LItem := Default(TShellRecentItem);
  LItem.Kind := rkProject;
  LItem.ItemKey := APath;
  LItem.ProjectId := AProjectId;
  LItem.Path := APath;
  LItem.DisplayName := ADisplayName;
  LItem.LayoutKey := ALayoutKey;
  LItem.LastOpenedAt := Now;
  AddRecent(LItem);
end;

function TDeepSpecDbRecentService.GetRecent(
  AKind: TShellRecentKind): TArray<TShellRecentItem>;
var
  LResult: TList<TShellRecentItem>;
begin
  LResult := TList<TShellRecentItem>.Create;
  try
    for var LItem in FItems do
      if LItem.Kind = AKind then
        LResult.Add(LItem);
    Result := LResult.ToArray;
  finally
    LResult.Free;
  end;
end;

function TDeepSpecDbRecentService.GetRecentProjects: TArray<TShellRecentItem>;
begin
  Result := GetRecent(rkProject);
end;

procedure TDeepSpecDbRecentService.MarkInvalid(AKind: TShellRecentKind;
  const AItemKey: string);
var
  LIdx: Integer;
begin
  LIdx := FindIndex(AKind, AItemKey);
  if LIdx >= 0 then
  begin
    var LItem := FItems[LIdx];
    LItem.Invalid := True;
    FItems[LIdx] := LItem;
    SaveToDb;
  end;
end;

procedure TDeepSpecDbRecentService.Remove(AKind: TShellRecentKind;
  const AItemKey: string);
var
  LIdx: Integer;
begin
  LIdx := FindIndex(AKind, AItemKey);
  if LIdx >= 0 then
  begin
    FItems.Delete(LIdx);
    SaveToDb;
  end;
end;

procedure TDeepSpecDbRecentService.Clear;
begin
  FItems.Clear;
  SaveToDb;
end;

{ ---------- TDeepSpecDbSettingsStore ---------- }

function TDeepSpecDbSettingsStore.MapKey(const AKey: string): string;
begin
  Result := CFG_SETTINGS_PREFIX + AKey;
end;

function TDeepSpecDbSettingsStore.ReadString(const AKey,
  ADefault: string): string;
begin
  Result := ADefault;
  if not ConfigAvailable then Exit;
  try
    Result := DeepBase.Config.GetConfig(MapKey(AKey), ADefault);
  except
    Result := ADefault;
  end;
end;

procedure TDeepSpecDbSettingsStore.WriteString(const AKey, AValue: string);
begin
  if not ConfigAvailable then Exit;
  try
    DeepBase.Config.SetConfig(MapKey(AKey), AValue);
  except
  end;
end;

function TDeepSpecDbSettingsStore.ReadBool(const AKey: string;
  ADefault: Boolean): Boolean;
begin
  Result := ADefault;
  if not ConfigAvailable then Exit;
  try
    Result := DeepBase.Config.GetConfigBool(MapKey(AKey), ADefault);
  except
    Result := ADefault;
  end;
end;

procedure TDeepSpecDbSettingsStore.WriteBool(const AKey: string;
  AValue: Boolean);
begin
  if not ConfigAvailable then Exit;
  try
    DeepBase.Config.SetConfigBool(MapKey(AKey), AValue);
  except
  end;
end;

function TDeepSpecDbSettingsStore.ReadInteger(const AKey: string;
  ADefault: Integer): Integer;
begin
  Result := ADefault;
  if not ConfigAvailable then Exit;
  try
    Result := DeepBase.Config.GetConfigInt(MapKey(AKey), ADefault);
  except
    Result := ADefault;
  end;
end;

procedure TDeepSpecDbSettingsStore.WriteInteger(const AKey: string;
  AValue: Integer);
begin
  if not ConfigAvailable then Exit;
  try
    DeepBase.Config.SetConfigInt(MapKey(AKey), AValue);
  except
  end;
end;

procedure TDeepSpecDbSettingsStore.RemoveKey(const AKey: string);
begin
  if not ConfigAvailable then Exit;
  try
    DeepBase.Config.SetConfig(MapKey(AKey), '');
  except
  end;
end;

{ ---------- TDeepSpecDbLayoutService ---------- }

function TDeepSpecDbLayoutService.KeyFor(const AProjectId: string): string;
begin
  if AProjectId = '' then
    Result := CFG_LAYOUT_PREFIX + 'main'
  else
    Result := CFG_LAYOUT_PREFIX + 'project.' + AProjectId;
end;

procedure TDeepSpecDbLayoutService.SaveGlobalLayout(
  const AState: TShellLayoutState);
begin
  if not ConfigAvailable then Exit;
  try
    var LState := AState;
    LState.LayoutKey := 'main';
    LState.UpdatedAt := Now;
    var LJson := LayoutToJson(LState);
    try
      DeepBase.Config.SetConfig(KeyFor(''), LJson.ToJSON);
    finally
      LJson.Free;
    end;
  except
  end;
end;

function TDeepSpecDbLayoutService.TryLoadGlobalLayout(
  out AState: TShellLayoutState): Boolean;
var
  LJson: string;
  LObj: TJSONObject;
begin
  Result := False;
  AState := Default(TShellLayoutState);
  if not ConfigAvailable then Exit;
  try
    LJson := DeepBase.Config.GetConfig(KeyFor(''), '');
    if LJson = '' then Exit;
    LObj := TJSONObject.ParseJSONValue(LJson) as TJSONObject;
    if LObj = nil then Exit;
    try
      AState := JsonToLayout(LObj);
      Result := AState.MainWidth > 0;
    finally
      LObj.Free;
    end;
  except
    Result := False;
  end;
end;

procedure TDeepSpecDbLayoutService.SaveProjectLayout(const AProjectId: string;
  const AState: TShellLayoutState);
begin
  if not ConfigAvailable then Exit;
  try
    var LState := AState;
    LState.LayoutKey := 'project:' + AProjectId;
    LState.UpdatedAt := Now;
    var LJson := LayoutToJson(LState);
    try
      DeepBase.Config.SetConfig(KeyFor(AProjectId), LJson.ToJSON);
    finally
      LJson.Free;
    end;
  except
  end;
end;

function TDeepSpecDbLayoutService.TryLoadProjectLayout(const AProjectId: string;
  out AState: TShellLayoutState): Boolean;
var
  LJson: string;
  LObj: TJSONObject;
begin
  Result := False;
  AState := Default(TShellLayoutState);
  if not ConfigAvailable then Exit;
  try
    LJson := DeepBase.Config.GetConfig(KeyFor(AProjectId), '');
    if LJson = '' then Exit;
    LObj := TJSONObject.ParseJSONValue(LJson) as TJSONObject;
    if LObj = nil then Exit;
    try
      AState := JsonToLayout(LObj);
      Result := AState.MainWidth > 0;
    finally
      LObj.Free;
    end;
  except
    Result := False;
  end;
end;

procedure TDeepSpecDbLayoutService.ResetGlobalLayout;
begin
  if not ConfigAvailable then Exit;
  try
    DeepBase.Config.SetConfig(KeyFor(''), '');
  except
  end;
end;

procedure TDeepSpecDbLayoutService.ResetProjectLayout(const AProjectId: string);
begin
  if not ConfigAvailable then Exit;
  try
    DeepBase.Config.SetConfig(KeyFor(AProjectId), '');
  except
  end;
end;

end.
