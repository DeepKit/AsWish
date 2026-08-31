{ ============================================================================
  AsWish.Localization
  ---------------------------------------------------------------------------
  i18n integration hub for AsWish:
  - Detects Windows UI language (BCP-47) and normalizes to zh-CN / zh-TW / en-US.
  - Implements IShellLocalizationService for UI strings and commands.
  - String literals use #$XXXX escapes to avoid dcc64 ANSI mis-decoding.
  - Zero external dependencies.
  ============================================================================ }

unit AsWish.Localization;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.UI.Intf;

type
  TAsWishLocalizationService = class(TInterfacedObject, IShellLocalizationService)
  private
    FCurrentLocale: string;
    FStringTables: TDictionary<string, TDictionary<string, string>>;
    function GetTable(const ALocale: string): TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;

    function CurrentLocale: string;
    procedure SetLocale(const ALocale: string);
    function GetText(const AKey: string; const ADefault: string = ''): string;
    procedure RegisterText(const ALocale, AKey, AValue: string);
    function SupportedLocales: TArray<string>;
  end;

/// <summary>Detect the Windows UI language (zh-CN, zh-TW, en-US).</summary>
function AsWishDetectLocale: string;

/// <summary>Register AsWish string tables and apply detected locale.</summary>
procedure AsWishApplyLocale(const ALocSvc: IShellLocalizationService);

implementation

uses
  Winapi.Windows;

{ System locale detection via Win32 }

function DetectSystemLocale: string;
var
  LLangBuf: array[0..84] of WideChar;
  LLen: Integer;
begin
  LLen := GetUserDefaultLocaleName(@LLangBuf[0], Length(LLangBuf));
  if LLen > 0 then
    Result := string(LLangBuf)
  else
    Result := 'en-US';
end;

function AsWishDetectLocale: string;
var
  LLocale, LLower: string;
begin
  LLocale := DetectSystemLocale;
  LLower := LLocale.ToLower;
  if LLower.StartsWith('zh-hans') or LLower.StartsWith('zh-cn')
     or LLower.StartsWith('zh-sg') or (LLower = 'zh') then
    Exit('zh-CN');
  if LLower.StartsWith('zh-hant') or LLower.StartsWith('zh-tw')
     or LLower.StartsWith('zh-hk') or LLower.StartsWith('zh-mo') then
    Exit('zh-TW');
  Result := 'en-US';
end;

{ TAsWishLocalizationService }

constructor TAsWishLocalizationService.Create;
begin
  inherited Create;
  FStringTables := TDictionary<string, TDictionary<string, string>>.Create;
  FCurrentLocale := 'en-US';
end;

destructor TAsWishLocalizationService.Destroy;
var
  LPair: TPair<string, TDictionary<string, string>>;
begin
  for LPair in FStringTables do
    LPair.Value.Free;
  FStringTables.Free;
  inherited;
end;

function TAsWishLocalizationService.GetTable(
  const ALocale: string): TDictionary<string, string>;
begin
  if not FStringTables.TryGetValue(ALocale, Result) then
  begin
    Result := TDictionary<string, string>.Create;
    FStringTables.Add(ALocale, Result);
  end;
end;

function TAsWishLocalizationService.CurrentLocale: string;
begin
  Result := FCurrentLocale;
end;

procedure TAsWishLocalizationService.SetLocale(const ALocale: string);
begin
  if ALocale <> '' then
    FCurrentLocale := ALocale;
end;

function TAsWishLocalizationService.GetText(const AKey,
  ADefault: string): string;
var
  LTable: TDictionary<string, string>;
begin
  if FStringTables.TryGetValue(FCurrentLocale, LTable) then
  begin
    if LTable.TryGetValue(AKey, Result) then
      Exit;
  end;
  // Fallback to en-US
  if (FCurrentLocale <> 'en-US') and FStringTables.TryGetValue('en-US', LTable) then
  begin
    if LTable.TryGetValue(AKey, Result) then
      Exit;
  end;
  if ADefault <> '' then
    Result := ADefault
  else
    Result := AKey;
end;

procedure TAsWishLocalizationService.RegisterText(const ALocale, AKey,
  AValue: string);
begin
  GetTable(ALocale).AddOrSetValue(AKey, AValue);
end;

function TAsWishLocalizationService.SupportedLocales: TArray<string>;
var
  LList: TList<string>;
  LKey: string;
begin
  LList := TList<string>.Create;
  try
    for LKey in FStringTables.Keys do
      LList.Add(LKey);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure RegisterAsWishTexts(const ALocSvc: IShellLocalizationService;
  const ALocale: string);
begin
  if SameText(ALocale, 'zh-CN') then
  begin
    ALocSvc.RegisterText(ALocale, 'aswish.tab.dirs', #$76EE#$5F55);
    ALocSvc.RegisterText(ALocale, 'aswish.tab.func', #$529F#$80FD#$6811);
    ALocSvc.RegisterText(ALocale, 'aswish.tab.module', #$6A21#$5757#$6811);
    ALocSvc.RegisterText(ALocale, 'aswish.tab.view', #$754C#$9762#$6811);
    ALocSvc.RegisterText(ALocale, 'aswish.btn.visualize', #$53EF#$89C6#$5316);
    ALocSvc.RegisterText(ALocale, 'aswish.mru.hint', #$6700#$8FD1#$9879#$76EE'...');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.open', #$6253#$5F00#$9879#$76EE);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.scan', #$8FD0#$884C#$626B#$63CF);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.generate', #$751F#$6210' B');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.render', #$6E32#$67D3' HTML');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.refresh', #$4ECE' YAML '#$5237#$65B0' HTML');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.promote', #$63D0#$5347#$5F85#$51B3#$7B56);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.export', #$5BFC#$51FA#$63D0#$793A#$8BCD);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.renderdata', #$6E32#$67D3#$6570#$636E#$6811);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.llmsetup', #$8BBE#$7F6E' LLM (ModelScope)');
    ALocSvc.RegisterText(ALocale, 'aswish.llm.title', 'LLM '#$8BBE#$7F6E);
    ALocSvc.RegisterText(ALocale, 'aswish.llm.apikey', #$8F93#$5165' ModelScope API '#$5BC6#$94A5':');
    ALocSvc.RegisterText(ALocale, 'aswish.llm.model', #$6A21#$578B#$540D#$79F0' ('#$9ED8#$8BA4': Qwen/Qwen2.5-72B-Instruct):');
    ALocSvc.RegisterText(ALocale, 'aswish.llm.notinit', 'LLM '#$672A#$914D#$7F6E#$3002#$8BF7#$5148#$8FDB#$884C#$8BBE#$7F6E#$3002);
    ALocSvc.RegisterText(ALocale, 'aswish.llm.configured', 'LLM '#$914D#$7F6E#$6210#$529F#$3002#$4F7F#$7528' Generate B '#$8C03#$7528#$5B83#$3002);
    ALocSvc.RegisterText(ALocale, 'aswish.llm.savefail', #$4FDD#$5B58' LLM '#$914D#$7F6E#$5931#$8D25': ');
    ALocSvc.RegisterText(ALocale, 'aswish.status.ready', 'AsWish '#$5C31#$7EEA#$3002#$6253#$5F00#$9879#$76EE#$6587#$4EF6#$5939#$5F00#$59CB#$3002);
  end
  else if SameText(ALocale, 'zh-TW') then
  begin
    ALocSvc.RegisterText(ALocale, 'aswish.tab.dirs', #$76EE#$9304);
    ALocSvc.RegisterText(ALocale, 'aswish.tab.func', #$529F#$80FD#$6A39);
    ALocSvc.RegisterText(ALocale, 'aswish.tab.module', #$6A21#$7D44#$6A39);
    ALocSvc.RegisterText(ALocale, 'aswish.tab.view', #$754C#$9762#$6A39);
    ALocSvc.RegisterText(ALocale, 'aswish.btn.visualize', #$53EF#$8996#$5316);
    ALocSvc.RegisterText(ALocale, 'aswish.mru.hint', #$6700#$8FD1#$5C08#$6848'...');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.open', #$958B#$555F#$5C08#$6848);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.scan', #$57F7#$884C#$6383#$63CF);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.generate', #$7522#$751F' B');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.render', #$8F89#$71D9' HTML');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.refresh', #$5F9E' YAML '#$91CD#$65B0#$6574#$7406' HTML');
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.promote', #$63D0#$5347#$5F85#$6C7A#$7B56);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.export', #$532F#$51FA#$63D0#$793A#$8A5E);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.renderdata', #$8F89#$71D9#$8CC7#$6599#$6A39);
    ALocSvc.RegisterText(ALocale, 'aswish.cmd.llmsetup', #$8A2D#$5B9A' LLM (ModelScope)');
    ALocSvc.RegisterText(ALocale, 'aswish.llm.title', 'LLM '#$8A2D#$5B9A);
    ALocSvc.RegisterText(ALocale, 'aswish.llm.apikey', #$8F38#$5165' ModelScope API '#$5BC6#$9470':');
    ALocSvc.RegisterText(ALocale, 'aswish.llm.model', #$6A21#$578B#$540D#$7A31' ('#$9ED8#$8A8D': Qwen/Qwen2.5-72B-Instruct):');
    ALocSvc.RegisterText(ALocale, 'aswish.llm.notinit', 'LLM '#$672A#$8A2D#$5B9A#$3002#$8ACB#$5148#$9032#$884C#$8A2D#$5B9A#$3002);
    ALocSvc.RegisterText(ALocale, 'aswish.llm.configured', 'LLM '#$914D#$7F6E#$6210#$529F#$3002#$4F7F#$7528' Generate B '#$547C#$53EB#$5B83#$3002);
    ALocSvc.RegisterText(ALocale, 'aswish.llm.savefail', #$4FDD#$5B58' LLM '#$914D#$7F6E#$5931#$8D25': ');
    ALocSvc.RegisterText(ALocale, 'aswish.status.ready', 'AsWish '#$5C31#$7E96#$3002#$958B#$555F#$5C08#$6848#$8CC7#$6599#$5935#$958B#$59CB#$3002);
  end;
end;

procedure AsWishApplyLocale(const ALocSvc: IShellLocalizationService);
var
  LLocale: string;
begin
  if ALocSvc = nil then Exit;

  RegisterAsWishTexts(ALocSvc, 'zh-CN');
  RegisterAsWishTexts(ALocSvc, 'zh-TW');

  LLocale := AsWishDetectLocale;
  ALocSvc.SetLocale(LLocale);
end;

end.
