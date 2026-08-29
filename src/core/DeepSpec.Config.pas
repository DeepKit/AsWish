{ ============================================================================
  DeepSpec.Config
  ---------------------------------------------------------------------------
  Lightweight standalone configuration storage for DeepSpec.
  Persists key-value settings to a local JSON file in user profile or local dir.
  Fully open source with zero external dependencies.
  ============================================================================ }

unit DeepSpec.Config;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.JSON;

type
  TDeepSpecConfig = class
  private
    class var FInstance: TDeepSpecConfig;
    class var FLock: TCriticalSection;
    class var FConfigFile: string;
  private
    FSettings: TDictionary<string, string>;
    FModified: Boolean;
    procedure LoadFromFile;
    procedure SaveToFile;
    function GetDefaultConfigPath: string;
  public
    constructor Create;
    destructor Destroy; override;

    class procedure Initialize(const AConfigPath: string = '');
    class procedure Finalize;
    class function Instance: TDeepSpecConfig;

    function GetString(const AKey, ADefault: string): string;
    procedure SetString(const AKey, AValue: string);

    function GetInt(const AKey: string; ADefault: Integer): Integer;
    procedure SetInt(const AKey: string; AValue: Integer);

    function GetBool(const AKey: string; ADefault: Boolean): Boolean;
    procedure SetBool(const AKey: string; AValue: Boolean);

    procedure Remove(const AKey: string);
  end;

function GetConfig(const AKey, ADefault: string): string;
procedure SetConfig(const AKey, AValue: string);
function GetConfigInt(const AKey: string; ADefault: Integer = 0): Integer;
procedure SetConfigInt(const AKey: string; AValue: Integer);
function GetConfigBool(const AKey: string; ADefault: Boolean = False): Boolean;
procedure SetConfigBool(const AKey: string; AValue: Boolean);

implementation

uses
  System.IOUtils;

{ TDeepSpecConfig }

constructor TDeepSpecConfig.Create;
begin
  inherited Create;
  FSettings := TDictionary<string, string>.Create;
  FModified := False;
  LoadFromFile;
end;

destructor TDeepSpecConfig.Destroy;
begin
  if FModified then
    SaveToFile;
  FSettings.Free;
  inherited;
end;

function TDeepSpecConfig.GetDefaultConfigPath: string;
var
  LAppDir: string;
begin
  if FConfigFile <> '' then
    Exit(FConfigFile);

  LAppDir := TPath.Combine(TPath.GetHomePath, 'DeepSpec');
  if not TDirectory.Exists(LAppDir) then
    TDirectory.CreateDirectory(LAppDir);

  Result := TPath.Combine(LAppDir, 'deepspec.config.json');
end;

class procedure TDeepSpecConfig.Initialize(const AConfigPath: string);
begin
  if FLock = nil then
    FLock := TCriticalSection.Create;
  FLock.Enter;
  try
    FConfigFile := AConfigPath;
    if FInstance = nil then
      FInstance := TDeepSpecConfig.Create;
  finally
    FLock.Leave;
  end;
end;

class procedure TDeepSpecConfig.Finalize;
begin
  if FLock <> nil then
  begin
    FLock.Enter;
    try
      FreeAndNil(FInstance);
    finally
      FLock.Leave;
      FreeAndNil(FLock);
    end;
  end;
end;

class function TDeepSpecConfig.Instance: TDeepSpecConfig;
begin
  if FInstance = nil then
    Initialize;
  Result := FInstance;
end;

procedure TDeepSpecConfig.LoadFromFile;
var
  LPath, LContent: string;
  LVal: TJSONValue;
  LObj: TJSONObject;
  LPair: TJSONPair;
begin
  LPath := GetDefaultConfigPath;
  if not TFile.Exists(LPath) then Exit;

  try
    LContent := TFile.ReadAllText(LPath, TEncoding.UTF8);
    if LContent.Trim = '' then Exit;

    LVal := TJSONObject.ParseJSONValue(LContent);
    if LVal is TJSONObject then
    begin
      LObj := TJSONObject(LVal);
      try
        for var I := 0 to LObj.Count - 1 do
        begin
          LPair := LObj.Pairs[I];
          FSettings.AddOrSetValue(LPair.JsonString.Value, LPair.JsonValue.Value);
        end;
      finally
        LObj.Free;
      end;
    end
    else if LVal <> nil then
      LVal.Free;
  except
    // Non-fatal if config file has corrupt JSON
  end;
end;

procedure TDeepSpecConfig.SaveToFile;
var
  LPath, LDir: string;
  LObj: TJSONObject;
  LPair: TPair<string, string>;
begin
  LPath := GetDefaultConfigPath;
  LDir := ExtractFilePath(LPath);
  if (LDir <> '') and not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);

  LObj := TJSONObject.Create;
  try
    for LPair in FSettings do
      LObj.AddPair(LPair.Key, LPair.Value);
    TFile.WriteAllText(LPath, LObj.Format(2), TEncoding.UTF8);
    FModified := False;
  finally
    LObj.Free;
  end;
end;

function TDeepSpecConfig.GetString(const AKey, ADefault: string): string;
begin
  if not FSettings.TryGetValue(AKey, Result) then
    Result := ADefault;
end;

procedure TDeepSpecConfig.SetString(const AKey, AValue: string);
begin
  FSettings.AddOrSetValue(AKey, AValue);
  FModified := True;
  SaveToFile;
end;

function TDeepSpecConfig.GetInt(const AKey: string; ADefault: Integer): Integer;
var
  S: string;
begin
  if FSettings.TryGetValue(AKey, S) then
    Result := StrToIntDef(S, ADefault)
  else
    Result := ADefault;
end;

procedure TDeepSpecConfig.SetInt(const AKey: string; AValue: Integer);
begin
  SetString(AKey, IntToStr(AValue));
end;

function TDeepSpecConfig.GetBool(const AKey: string; ADefault: Boolean): Boolean;
var
  S: string;
begin
  if FSettings.TryGetValue(AKey, S) then
    Result := SameText(S, 'true') or (S = '1')
  else
    Result := ADefault;
end;

procedure TDeepSpecConfig.SetBool(const AKey: string; AValue: Boolean);
begin
  SetString(AKey, BoolToStr(AValue, True));
end;

procedure TDeepSpecConfig.Remove(const AKey: string);
begin
  if FSettings.ContainsKey(AKey) then
  begin
    FSettings.Remove(AKey);
    FModified := True;
    SaveToFile;
  end;
end;

{ Global helper functions }

function GetConfig(const AKey, ADefault: string): string;
begin
  Result := TDeepSpecConfig.Instance.GetString(AKey, ADefault);
end;

procedure SetConfig(const AKey, AValue: string);
begin
  TDeepSpecConfig.Instance.SetString(AKey, AValue);
end;

function GetConfigInt(const AKey: string; ADefault: Integer): Integer;
begin
  Result := TDeepSpecConfig.Instance.GetInt(AKey, ADefault);
end;

procedure SetConfigInt(const AKey: string; AValue: Integer);
begin
  TDeepSpecConfig.Instance.SetInt(AKey, AValue);
end;

function GetConfigBool(const AKey: string; ADefault: Boolean): Boolean;
begin
  Result := TDeepSpecConfig.Instance.GetBool(AKey, ADefault);
end;

procedure SetConfigBool(const AKey: string; AValue: Boolean);
begin
  TDeepSpecConfig.Instance.SetBool(AKey, AValue);
end;

initialization

finalization
  TDeepSpecConfig.Finalize;

end.
