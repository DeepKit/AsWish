{ ============================================================================
  DeepSpec.Services.LLMConfig
  ---------------------------------------------------------------------------
  Helper to configure LLM providers (ModelScope, OpenAI, Ollama, DeepSeek).
  Saves provider parameters to DeepSpec configuration with key protection.
  Zero external dependencies.
  ============================================================================ }

unit DeepSpec.Services.LLMConfig;

interface

uses
  System.SysUtils,
  DeepSpec.Config,
  DeepSpec.Security;

type
  TDeepSpecLLMConfigHelper = class
  public
    /// <summary>Save a ModelScope (OpenAI-compatible) LLM configuration.</summary>
    class procedure SaveModelScopeConfig(const AApiKey, AModel: string;
      const AConfigName: string = 'Default'); static;

    /// <summary>Save a generic OpenAI-compatible LLM configuration.</summary>
    class procedure SaveOpenAICompatible(const AConfigName, ABaseUrl,
      AApiKey, AModel: string); static;

    /// <summary>Check if an LLM configuration has a valid API key.</summary>
    class function IsConfigured(const AConfigName: string = 'Default'): Boolean; static;
  end;

implementation

const
  CFG_LLM_PREFIX = 'deepspec.llm.';
  DEFAULT_MODELSCOPE_URL = 'https://api-inference.modelscope.cn/v1';

class procedure TDeepSpecLLMConfigHelper.SaveModelScopeConfig(
  const AApiKey, AModel: string; const AConfigName: string);
begin
  SaveOpenAICompatible(AConfigName, DEFAULT_MODELSCOPE_URL, AApiKey, AModel);
end;

class procedure TDeepSpecLLMConfigHelper.SaveOpenAICompatible(
  const AConfigName, ABaseUrl, AApiKey, AModel: string);
var
  LCfgName, LPrefix: string;
begin
  LCfgName := AConfigName;
  if LCfgName = '' then
    LCfgName := 'Default';
  LPrefix := CFG_LLM_PREFIX + LCfgName + '.';

  SetConfig(LPrefix + 'base_url', ABaseUrl);
  SetConfig(LPrefix + 'api_key', TDeepSpecSecurity.Protect(AApiKey));
  SetConfig(LPrefix + 'model', AModel);
  SetConfigBool(LPrefix + 'enabled', True);
end;

class function TDeepSpecLLMConfigHelper.IsConfigured(
  const AConfigName: string): Boolean;
var
  LCfgName, LPrefix, LKey, LUrl: string;
begin
  LCfgName := AConfigName;
  if LCfgName = '' then
    LCfgName := 'Default';
  LPrefix := CFG_LLM_PREFIX + LCfgName + '.';

  LKey := GetConfig(LPrefix + 'api_key', '');
  LUrl := GetConfig(LPrefix + 'base_url', '');
  Result := (LKey <> '') and (LUrl <> '');
end;

end.
