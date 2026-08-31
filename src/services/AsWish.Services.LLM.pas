{ ============================================================================
  AsWish.Services.LLM
  ---------------------------------------------------------------------------
  Standalone, open-source LLM client for AsWish:
  - A -> B specification generation
  - Single node refinement
  - Decision write-back and prompt generation

  Connects directly to OpenAI-compatible endpoints (ModelScope, OpenAI,
  DeepSeek, Qwen, Ollama, vLLM, etc.) via Delphi's built-in System.Net.HttpClient.
  Zero external dependencies.
  ============================================================================ }

unit AsWish.Services.LLM;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Diagnostics,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  AsWish.Config,
  AsWish.Security,
  AsWish.Logger;

type
  TAsWishLLMResult = record
    Success: Boolean;
    Content: string;
    ErrorMessage: string;
    DurationMs: Int64;
    InputTokens: Integer;
    OutputTokens: Integer;
  end;

  TAsWishLLMService = class(TInterfacedObject)
  private
    FConfigName: string;
    function GetBaseUrl: string;
    function GetApiKey: string;
    function GetModel: string;
  public
    constructor Create(const AConfigName: string = 'Default');
    destructor Destroy; override;

    procedure SetConfig(const AConfigName: string);
    function IsAvailable: Boolean;
    function Generate(const APrompt: string): TAsWishLLMResult;
    function GenerateWithSystem(const ASystemPrompt, AUserPrompt: string): TAsWishLLMResult;

    property ConfigName: string read FConfigName;
  end;

implementation

const
  CFG_LLM_PREFIX = 'aswish.llm.';
  DEFAULT_MODELSCOPE_URL = 'https://api-inference.modelscope.cn/v1';
  DEFAULT_MODEL = 'Qwen/Qwen2.5-72B-Instruct';

{ TAsWishLLMService }

constructor TAsWishLLMService.Create(const AConfigName: string);
begin
  inherited Create;
  FConfigName := AConfigName;
  if FConfigName = '' then
    FConfigName := 'Default';
end;

destructor TAsWishLLMService.Destroy;
begin
  inherited;
end;

procedure TAsWishLLMService.SetConfig(const AConfigName: string);
begin
  FConfigName := AConfigName;
end;

function TAsWishLLMService.GetBaseUrl: string;
begin
  Result := GetConfig(CFG_LLM_PREFIX + FConfigName + '.base_url', DEFAULT_MODELSCOPE_URL);
end;

function TAsWishLLMService.GetApiKey: string;
var
  LEnc: string;
begin
  LEnc := GetConfig(CFG_LLM_PREFIX + FConfigName + '.api_key', '');
  Result := TAsWishSecurity.Unprotect(LEnc);
end;

function TAsWishLLMService.GetModel: string;
begin
  Result := GetConfig(CFG_LLM_PREFIX + FConfigName + '.model', DEFAULT_MODEL);
end;

function TAsWishLLMService.IsAvailable: Boolean;
var
  LKey: string;
begin
  LKey := GetApiKey;
  Result := (LKey <> '') and (GetBaseUrl <> '');
end;

function TAsWishLLMService.Generate(const APrompt: string): TAsWishLLMResult;
begin
  Result := GenerateWithSystem('', APrompt);
end;

function TAsWishLLMService.GenerateWithSystem(const ASystemPrompt,
  AUserPrompt: string): TAsWishLLMResult;
var
  LHttp: THTTPClient;
  LReqBody: TJSONObject;
  LMessages: TJSONArray;
  LSysMsg, LUserMsg: TJSONObject;
  LPostStream, LRespStream: TStringStream;
  LUrl, LApiKey, LModel, LRespText: string;
  LStopwatch: TStopwatch;
  LResp: IHTTPResponse;
  LJsonVal, LChoicesVal, LMsgVal, LUsageVal: TJSONValue;
  LJsonObj, LChoiceObj, LUsageObj: TJSONObject;
begin
  Result.Success := False;
  Result.Content := '';
  Result.ErrorMessage := '';
  Result.DurationMs := 0;
  Result.InputTokens := 0;
  Result.OutputTokens := 0;

  LApiKey := GetApiKey;
  if LApiKey = '' then
  begin
    Result.ErrorMessage := 'LLM is not configured. Configure your API key in AsWish settings.';
    Exit;
  end;

  LUrl := GetBaseUrl;
  if not LUrl.EndsWith('/') then
    LUrl := LUrl + '/';
  if not LUrl.EndsWith('chat/completions') then
    LUrl := LUrl + 'chat/completions';

  LModel := GetModel;

  LHttp := THTTPClient.Create;
  LReqBody := TJSONObject.Create;
  LPostStream := nil;
  LRespStream := nil;
  try
    LHttp.ConnectionTimeout := 30000;
    LHttp.ResponseTimeout := 120000;
    LHttp.CustomHeaders['Authorization'] := 'Bearer ' + LApiKey;

    LReqBody.AddPair('model', LModel);
    LReqBody.AddPair('temperature', TJSONNumber.Create(0.3));
    LReqBody.AddPair('max_tokens', TJSONNumber.Create(4096));

    LMessages := TJSONArray.Create;
    if ASystemPrompt <> '' then
    begin
      LSysMsg := TJSONObject.Create;
      LSysMsg.AddPair('role', 'system');
      LSysMsg.AddPair('content', ASystemPrompt);
      LMessages.AddElement(LSysMsg);
    end;

    LUserMsg := TJSONObject.Create;
    LUserMsg.AddPair('role', 'user');
    LUserMsg.AddPair('content', AUserPrompt);
    LMessages.AddElement(LUserMsg);

    LReqBody.AddPair('messages', LMessages);

    LPostStream := TStringStream.Create(LReqBody.ToJSON, TEncoding.UTF8);

    LStopwatch := TStopwatch.StartNew;
    try
      LResp := LHttp.Post(LUrl, LPostStream, nil, [
        TNameValuePair.Create('Content-Type', 'application/json')
      ]);
      LStopwatch.Stop;
      Result.DurationMs := LStopwatch.ElapsedMilliseconds;

      LRespText := LResp.ContentAsString(TEncoding.UTF8);

      if (LResp.StatusCode >= 200) and (LResp.StatusCode < 300) then
      begin
        LJsonVal := TJSONObject.ParseJSONValue(LRespText);
        if LJsonVal is TJSONObject then
        begin
          LJsonObj := TJSONObject(LJsonVal);
          try
            LChoicesVal := LJsonObj.GetValue<TJSONValue>('choices', nil);
            if (LChoicesVal is TJSONArray) and (TJSONArray(LChoicesVal).Count > 0) then
            begin
              LChoiceObj := TJSONArray(LChoicesVal).Items[0] as TJSONObject;
              if LChoiceObj <> nil then
              begin
                LMsgVal := LChoiceObj.GetValue<TJSONValue>('message', nil);
                if LMsgVal is TJSONObject then
                  Result.Content := TJSONObject(LMsgVal).GetValue<string>('content', '');
              end;
            end;

            LUsageVal := LJsonObj.GetValue<TJSONValue>('usage', nil);
            if LUsageVal is TJSONObject then
            begin
              LUsageObj := TJSONObject(LUsageVal);
              Result.InputTokens := LUsageObj.GetValue<Integer>('prompt_tokens', 0);
              Result.OutputTokens := LUsageObj.GetValue<Integer>('completion_tokens', 0);
            end;

            Result.Success := (Result.Content <> '');
            if not Result.Success then
              Result.ErrorMessage := 'LLM returned empty content.';
          finally
            LJsonObj.Free;
          end;
        end
        else
        begin
          if LJsonVal <> nil then LJsonVal.Free;
          Result.ErrorMessage := 'Invalid JSON response from LLM endpoint.';
        end;
      end
      else
      begin
        Result.ErrorMessage := Format('LLM HTTP %d: %s', [LResp.StatusCode, LRespText]);
      end;
    except
      on E: Exception do
      begin
        LStopwatch.Stop;
        Result.DurationMs := LStopwatch.ElapsedMilliseconds;
        Result.ErrorMessage := 'LLM request failed: ' + E.Message;
      end;
    end;
  finally
    LPostStream.Free;
    LRespStream.Free;
    LReqBody.Free;
    LHttp.Free;
  end;
end;

end.
