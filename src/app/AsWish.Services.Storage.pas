{ ============================================================================
  AsWish.Services.Storage
  ---------------------------------------------------------------------------
  Standalone JSON-backed implementations of desktop shell storage services:
  - IShellRecentService: MRU recent projects / files list
  - IShellSettingsStore: User / workspace configuration
  - IShellLayoutService: Window layout and tool panel positions

  Persists state directly into JSON configuration with no database dependencies.
  ============================================================================ }

unit AsWish.Services.Storage;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.JSON,
  AsWish.UI.Intf,
  AsWish.UI.Types;

type
  /// <summary>JSON-backed IShellRecentService.</summary>
  TAsWishRecentService = class(TInterfacedObject, IShellRecentService)
  private
    FItems: TList<TShellRecentItem>;
    FLock: TCriticalSection;
    FCapacity: Integer;
    procedure LoadFromJson;
    procedure SaveToJson;
    function FindIndex(AKind: TShellRecentKind; const AItemKey: string): Integer;
  public
    constructor Create(ACapacity: Integer = 10);
    destructor Destroy; override;
    procedure AddRecent(const AItem: TShellRecentItem);
    procedure AddRecentProject(const AProjectId, APath, ADisplayName, ALayoutKey: string);
    function GetRecent(AKind: TShellRecentKind): TArray<TShellRecentItem>;
    function GetRecentProjects: TArray<TShellRecentItem>;
    procedure MarkInvalid(AKind: TShellRecentKind; const AItemKey: string);
    procedure Remove(AKind: TShellRecentKind; const AItemKey: string);
    procedure Clear;
  end;

  /// <summary>JSON-backed IShellSettingsStore.</summary>
  TAsWishSettingsStore = class(TInterfacedObject, IShellSettingsStore)
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

  /// <summary>JSON-backed IShellLayoutService.</summary>
  TAsWishLayoutService = class(TInterfacedObject, IShellLayoutService)
  private
    function KeyFor(const AProjectId: string): string;
    function LayoutToJson(const AState: TShellLayoutState): string;
    function JsonToLayout(const AJson: string; out AState: TShellLayoutState): Boolean;
  public
    procedure SaveGlobalLayout(const AState: TShellLayoutState);
    function TryLoadGlobalLayout(out AState: TShellLayoutState): Boolean;
    procedure SaveProjectLayout(const AProjectId: string; const AState: TShellLayoutState);
    function TryLoadProjectLayout(const AProjectId: string; out AState: TShellLayoutState): Boolean;
    procedure ResetGlobalLayout;
    procedure ResetProjectLayout(const AProjectId: string);
  end;

implementation

uses
  System.DateUtils,
  AsWish.Config;

const
  CFG_RECENT = 'shell.recent.items';
  CFG_SETTINGS_PREFIX = 'shell.setting.';
  CFG_LAYOUT_PREFIX = 'shell.layout.';

{ TAsWishRecentService }

constructor TAsWishRecentService.Create(ACapacity: Integer);
begin
  inherited Create;
  FItems := TList<TShellRecentItem>.Create;
  FLock := TCriticalSection.Create;
  FCapacity := ACapacity;
  if FCapacity < 1 then
    FCapacity := 10;
  LoadFromJson;
end;

destructor TAsWishRecentService.Destroy;
begin
  FItems.Free;
  FLock.Free;
  inherited;
end;

function TAsWishRecentService.FindIndex(AKind: TShellRecentKind;
  const AItemKey: string): Integer;
begin
  Result := -1;
  for var I := 0 to FItems.Count - 1 do
  begin
    if (FItems[I].Kind = AKind) and SameText(FItems[I].ItemKey, AItemKey) then
      Exit(I);
  end;
end;

procedure TAsWishRecentService.LoadFromJson;
var
  LRaw: string;
  LVal: TJSONValue;
  LArr: TJSONArray;
  LObj: TJSONObject;
  LItem: TShellRecentItem;
begin
  LRaw := GetConfig(CFG_RECENT, '');
  if LRaw = '' then Exit;

  FLock.Enter;
  try
    FItems.Clear;
    LVal := TJSONObject.ParseJSONValue(LRaw);
    if LVal is TJSONArray then
    begin
      LArr := TJSONArray(LVal);
      for var I := 0 to LArr.Count - 1 do
      begin
        if LArr.Items[I] is TJSONObject then
        begin
          LObj := TJSONObject(LArr.Items[I]);
          LItem.Kind := TShellRecentKind(LObj.GetValue<Integer>('kind', 0));
          LItem.ItemKey := LObj.GetValue<string>('item_key', '');
          LItem.ProjectId := LObj.GetValue<string>('project_id', '');
          LItem.Path := LObj.GetValue<string>('path', '');
          LItem.DisplayName := LObj.GetValue<string>('display_name', '');
          LItem.LayoutKey := LObj.GetValue<string>('layout_key', '');
          LItem.LastOpenedAt := ISO8601ToDate(LObj.GetValue<string>('last_opened', ''), False);
          LItem.Invalid := LObj.GetValue<Boolean>('invalid', False);
          if LItem.ItemKey <> '' then
            FItems.Add(LItem);
        end;
      end;
      LArr.Free;
    end
    else if LVal <> nil then
      LVal.Free;
  finally
    FLock.Leave;
  end;
end;

procedure TAsWishRecentService.SaveToJson;
var
  LArr: TJSONArray;
  LObj: TJSONObject;
begin
  FLock.Enter;
  try
    LArr := TJSONArray.Create;
    try
      for var I := 0 to FItems.Count - 1 do
      begin
        LObj := TJSONObject.Create;
        LObj.AddPair('kind', TJSONNumber.Create(Ord(FItems[I].Kind)));
        LObj.AddPair('item_key', FItems[I].ItemKey);
        LObj.AddPair('project_id', FItems[I].ProjectId);
        LObj.AddPair('path', FItems[I].Path);
        LObj.AddPair('display_name', FItems[I].DisplayName);
        LObj.AddPair('layout_key', FItems[I].LayoutKey);
        LObj.AddPair('last_opened', DateToISO8601(FItems[I].LastOpenedAt, False));
        LObj.AddPair('invalid', TJSONBool.Create(FItems[I].Invalid));
        LArr.AddElement(LObj);
      end;
      SetConfig(CFG_RECENT, LArr.ToJSON);
    finally
      LArr.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAsWishRecentService.AddRecent(const AItem: TShellRecentItem);
var
  LIdx: Integer;
begin
  FLock.Enter;
  try
    LIdx := FindIndex(AItem.Kind, AItem.ItemKey);
    if LIdx >= 0 then
      FItems.Delete(LIdx);
    FItems.Insert(0, AItem);
    while FItems.Count > FCapacity do
      FItems.Delete(FItems.Count - 1);
  finally
    FLock.Leave;
  end;
  SaveToJson;
end;

procedure TAsWishRecentService.AddRecentProject(const AProjectId, APath,
  ADisplayName, ALayoutKey: string);
var
  LItem: TShellRecentItem;
begin
  LItem.Kind := rkProject;
  LItem.ItemKey := APath;
  LItem.ProjectId := AProjectId;
  LItem.Path := APath;
  LItem.DisplayName := ADisplayName;
  if LItem.DisplayName = '' then
    LItem.DisplayName := ExtractFileName(ExcludeTrailingPathDelimiter(APath));
  LItem.LayoutKey := ALayoutKey;
  LItem.LastOpenedAt := Now;
  LItem.Invalid := False;
  AddRecent(LItem);
end;

function TAsWishRecentService.GetRecent(
  AKind: TShellRecentKind): TArray<TShellRecentItem>;
var
  LList: TList<TShellRecentItem>;
begin
  FLock.Enter;
  try
    LList := TList<TShellRecentItem>.Create;
    try
      for var I := 0 to FItems.Count - 1 do
      begin
        if FItems[I].Kind = AKind then
          LList.Add(FItems[I]);
      end;
      Result := LList.ToArray;
    finally
      LList.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

function TAsWishRecentService.GetRecentProjects: TArray<TShellRecentItem>;
begin
  Result := GetRecent(rkProject);
end;

procedure TAsWishRecentService.MarkInvalid(AKind: TShellRecentKind;
  const AItemKey: string);
var
  LIdx: Integer;
  LItem: TShellRecentItem;
begin
  FLock.Enter;
  try
    LIdx := FindIndex(AKind, AItemKey);
    if LIdx >= 0 then
    begin
      LItem := FItems[LIdx];
      LItem.Invalid := True;
      FItems[LIdx] := LItem;
    end;
  finally
    FLock.Leave;
  end;
  SaveToJson;
end;

procedure TAsWishRecentService.Remove(AKind: TShellRecentKind;
  const AItemKey: string);
var
  LIdx: Integer;
begin
  FLock.Enter;
  try
    LIdx := FindIndex(AKind, AItemKey);
    if LIdx >= 0 then
      FItems.Delete(LIdx);
  finally
    FLock.Leave;
  end;
  SaveToJson;
end;

procedure TAsWishRecentService.Clear;
begin
  FLock.Enter;
  try
    FItems.Clear;
  finally
    FLock.Leave;
  end;
  SaveToJson;
end;

{ TAsWishSettingsStore }

function TAsWishSettingsStore.MapKey(const AKey: string): string;
begin
  Result := CFG_SETTINGS_PREFIX + AKey;
end;

function TAsWishSettingsStore.ReadString(const AKey, ADefault: string): string;
begin
  Result := GetConfig(MapKey(AKey), ADefault);
end;

procedure TAsWishSettingsStore.WriteString(const AKey, AValue: string);
begin
  SetConfig(MapKey(AKey), AValue);
end;

function TAsWishSettingsStore.ReadBool(const AKey: string;
  ADefault: Boolean): Boolean;
begin
  Result := GetConfigBool(MapKey(AKey), ADefault);
end;

procedure TAsWishSettingsStore.WriteBool(const AKey: string; AValue: Boolean);
begin
  SetConfigBool(MapKey(AKey), AValue);
end;

function TAsWishSettingsStore.ReadInteger(const AKey: string;
  ADefault: Integer): Integer;
begin
  Result := GetConfigInt(MapKey(AKey), ADefault);
end;

procedure TAsWishSettingsStore.WriteInteger(const AKey: string;
  AValue: Integer);
begin
  SetConfigInt(MapKey(AKey), AValue);
end;

procedure TAsWishSettingsStore.RemoveKey(const AKey: string);
begin
  TAsWishConfig.Instance.Remove(MapKey(AKey));
end;

{ TAsWishLayoutService }

function TAsWishLayoutService.KeyFor(const AProjectId: string): string;
begin
  if AProjectId = '' then
    Result := CFG_LAYOUT_PREFIX + 'global'
  else
    Result := CFG_LAYOUT_PREFIX + 'project.' + AProjectId;
end;

function TAsWishLayoutService.LayoutToJson(
  const AState: TShellLayoutState): string;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  try
    LObj.AddPair('main_left', TJSONNumber.Create(AState.MainLeft));
    LObj.AddPair('main_top', TJSONNumber.Create(AState.MainTop));
    LObj.AddPair('main_width', TJSONNumber.Create(AState.MainWidth));
    LObj.AddPair('main_height', TJSONNumber.Create(AState.MainHeight));
    LObj.AddPair('maximized', TJSONBool.Create(AState.Maximized));
    LObj.AddPair('current_view', AState.CurrentViewId);
    Result := LObj.ToJSON;
  finally
    LObj.Free;
  end;
end;

function TAsWishLayoutService.JsonToLayout(const AJson: string;
  out AState: TShellLayoutState): Boolean;
var
  LVal: TJSONValue;
  LObj: TJSONObject;
begin
  Result := False;
  AState := TShellLayoutState.Empty;
  if AJson = '' then Exit;

  LVal := TJSONObject.ParseJSONValue(AJson);
  if LVal is TJSONObject then
  begin
    LObj := TJSONObject(LVal);
    try
      AState.MainLeft := LObj.GetValue<Integer>('main_left', 100);
      AState.MainTop := LObj.GetValue<Integer>('main_top', 100);
      AState.MainWidth := LObj.GetValue<Integer>('main_width', 1200);
      AState.MainHeight := LObj.GetValue<Integer>('main_height', 800);
      AState.Maximized := LObj.GetValue<Boolean>('maximized', False);
      AState.CurrentViewId := LObj.GetValue<string>('current_view', '');
      Result := True;
    finally
      LObj.Free;
    end;
  end
  else if LVal <> nil then
    LVal.Free;
end;

procedure TAsWishLayoutService.SaveGlobalLayout(
  const AState: TShellLayoutState);
begin
  SetConfig(KeyFor(''), LayoutToJson(AState));
end;

function TAsWishLayoutService.TryLoadGlobalLayout(
  out AState: TShellLayoutState): Boolean;
begin
  Result := JsonToLayout(GetConfig(KeyFor(''), ''), AState);
end;

procedure TAsWishLayoutService.SaveProjectLayout(const AProjectId: string;
  const AState: TShellLayoutState);
begin
  SetConfig(KeyFor(AProjectId), LayoutToJson(AState));
end;

function TAsWishLayoutService.TryLoadProjectLayout(const AProjectId: string;
  out AState: TShellLayoutState): Boolean;
begin
  Result := JsonToLayout(GetConfig(KeyFor(AProjectId), ''), AState);
end;

procedure TAsWishLayoutService.ResetGlobalLayout;
begin
  TAsWishConfig.Instance.Remove(KeyFor(''));
end;

procedure TAsWishLayoutService.ResetProjectLayout(const AProjectId: string);
begin
  TAsWishConfig.Instance.Remove(KeyFor(AProjectId));
end;

end.
