{ ============================================================================
  DeepSpec.Localization

  i18n integration hub for the DeepSpec desktop shell:
    - Detects the Windows UI language at startup (BCP-47 via
      DetectSystemLocale) and normalizes it to the locales DeepSpec ships
      string tables for (zh-CN / zh-TW / en-US).
    - Registers the DeepSpec key table plus the DeepShell built-in table
      (RegisterDefaultShellTexts is otherwise never called anywhere) for
      the detected locale, then switches the shell localization service to
      it, and mirrors the choice into DeepBase.Manager.CurrentLanguage so
      DeepBase's own DB-backed i18n follows the same language.

  Conventions (must keep):
    - String literals use #$XXXX escapes: Delphi sources are read as ANSI
      by dcc64, so raw UTF-8 text inside .pas would be mis-decoded.
    - One RegisterText call per line: implicit string concatenation across
      physical lines is fragile under GBK source decoding.
    - ASCII-only comments.
  ============================================================================ }

unit DeepSpec.Localization;

interface

uses
  DeepBase.VCL.DeepShell.Localization;

/// <summary>Detect the Windows UI language and normalize it to a locale
///  DeepSpec ships strings for. Returns 'zh-CN', 'zh-TW' or 'en-US'.</summary>
function DeepSpecDetectLocale: string;

/// <summary>Register DeepSpec + DeepShell text tables for the detected
///  locale, switch the shell localization service to it, and mirror the
///  choice into DeepBase.Manager.CurrentLanguage (best effort).</summary>
procedure DeepSpecApplyLocale(ALocSvc: TShellDefaultLocalizationService);

implementation

uses
  System.SysUtils,
  DeepBase.Consts,
  DeepBase.Manager,
  DeepBase.VCL.DeepShell;

procedure RegisterDeepSpecTexts(ALocSvc: TShellDefaultLocalizationService;
  const ALocale: string);
begin
  if SameText(ALocale, 'zh-CN') then
  begin
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.dirs', #$76EE#$5F55);
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.func', #$529F#$80FD#$6811);
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.module', #$6A21#$5757#$6811);
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.view', #$754C#$9762#$6811);
    ALocSvc.RegisterText(ALocale, 'deepspec.btn.visualize', #$53EF#$89C6#$5316);
    ALocSvc.RegisterText(ALocale, 'deepspec.mru.hint', #$6700#$8FD1#$9879#$76EE'...');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.open', #$6253#$5F00#$9879#$76EE);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.scan', #$8FD0#$884C#$626B#$63CF);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.generate', #$751F#$6210' B');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.render', #$6E32#$67D3' HTML');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.refresh', #$4ECE' YAML '#$5237#$65B0' HTML');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.promote', #$63D0#$5347#$5F85#$51B3#$7B56);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.export', #$5BFC#$51FA#$63D0#$793A#$8BCD);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.renderdata', #$6E32#$67D3#$6570#$636E#$6811);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.llmsetup', #$8BBE#$7F6E' LLM (ModelScope)');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.title', 'LLM '#$8BBE#$7F6E);
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.apikey', #$8F93#$5165' ModelScope API '#$5BC6#$94A5' ('#$5C06#$5B89#$5168#$5B58#$50A8'):');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.model', #$6A21#$578B#$540D#$79F0' ('#$9ED8#$8BA4': Qwen/Qwen2.5-72B-Instruct):');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.notinit', 'DeepBase LLM '#$672A#$521D#$59CB#$5316#$3002#$68C0#$67E5' root.txt '#$4E0E' DB1.');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.configured', 'LLM '#$914D#$7F6E#$6210#$529F#$3002#$4F7F#$7528' Generate B '#$8C03#$7528#$5B83#$3002);
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.savefail', #$4FDD#$5B58' LLM '#$914D#$7F6E#$5931#$8D25'):');
    ALocSvc.RegisterText(ALocale, 'deepspec.status.ready', 'DeepSpec '#$5C31#$7EEA#$3002#$6253#$5F00#$9879#$76EE#$6587#$4EF6#$5939#$5F00#$59CB#$3002);
  end
  else if SameText(ALocale, 'zh-TW') then
  begin
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.dirs', #$76EE#$9304);
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.func', #$529F#$80FD#$6A39);
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.module', #$6A21#$7D44#$6A39);
    ALocSvc.RegisterText(ALocale, 'deepspec.tab.view', #$754C#$9762#$6A39);
    ALocSvc.RegisterText(ALocale, 'deepspec.btn.visualize', #$53EF#$8996#$5316);
    ALocSvc.RegisterText(ALocale, 'deepspec.mru.hint', #$6700#$8FD1#$5C08#$6848'...');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.open', #$958B#$555F#$5C08#$6848);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.scan', #$57F7#$884C#$6383#$63CF);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.generate', #$7522#$751F' B');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.render', #$8F89#$71D9' HTML');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.refresh', #$5F9E' YAML '#$91CD#$65B0#$6574#$7406' HTML');
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.promote', #$63D0#$5347#$5F85#$6C7A#$7B56);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.export', #$532F#$51FA#$63D0#$793A#$8A5E);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.renderdata', #$8F89#$71D9#$8CC7#$6599#$6A39);
    ALocSvc.RegisterText(ALocale, 'deepspec.cmd.llmsetup', #$8A2D#$5B9A' LLM (ModelScope)');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.title', 'LLM '#$8A2D#$5B9A);
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.apikey', #$8F38#$5165' ModelScope API '#$5BC6#$9470' ('#$5C07#$5B89#$5168#$5132#$5B58'):');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.model', #$6A21#$578B#$540D#$7A31' ('#$9ED8#$8A8D': Qwen/Qwen2.5-72B-Instruct):');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.notinit', 'DeepBase LLM '#$672A#$521D#$59CB#$5316#$3002#$6AA2#$67E5' root.txt '#$8207' DB1.');
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.configured', 'LLM '#$914D#$7F6E#$6210#$529F#$3002#$4F7F#$7528' Generate B '#$547C#$53EB#$5B83#$3002);
    ALocSvc.RegisterText(ALocale, 'deepspec.llm.savefail', #$5132#$5B58' LLM '#$914D#$7F6E#$5931#$6557'):');
    ALocSvc.RegisterText(ALocale, 'deepspec.status.ready', 'DeepSpec '#$5C31#$7E96#$3002#$958B#$555F#$5C08#$6848#$8CC7#$6599#$5935#$958B#$59CB#$3002);
  end;
end;

function DeepSpecDetectLocale: string;
var
  LLocale: string;
begin
  LLocale := DetectSystemLocale;
  var LLower := LLocale.ToLower;
  if LLower.StartsWith('zh-hans') or LLower.StartsWith('zh-cn')
     or LLower.StartsWith('zh-sg') or (LLower = 'zh') then
    Exit('zh-CN');
  if LLower.StartsWith('zh-hant') or LLower.StartsWith('zh-tw')
     or LLower.StartsWith('zh-hk') or LLower.StartsWith('zh-mo') then
    Exit('zh-TW');
  Result := 'en-US';
end;

procedure DeepSpecApplyLocale(ALocSvc: TShellDefaultLocalizationService);
var
  LLocale: string;
begin
  if ALocSvc = nil then Exit;

  // Ship both Chinese tables so a later SetLocale('zh-TW') works too.
  RegisterDeepSpecTexts(ALocSvc, 'zh-CN');
  RegisterDeepSpecTexts(ALocSvc, 'zh-TW');
  // DeepShell's own table is otherwise never registered anywhere.
  RegisterDefaultShellTexts(ALocSvc, 'zh-CN');
  RegisterDefaultShellTexts(ALocSvc, 'zh-TW');

  // Auto-switch to the Windows UI language (requirement: detect at startup,
  // then switch). SetLocale is a no-op when already on that locale.
  LLocale := DeepSpecDetectLocale;
  ALocSvc.SetLocale(LLocale);

  // Mirror into DeepBase so its DB-backed i18n follows the same language.
  try
    if DeepBase.Manager.DeepBase <> nil then
      DeepBase.Manager.DeepBase.CurrentLanguage := LLocale;
  except
    // DeepBase may be degraded (InitializeEx failure) - non-fatal here.
  end;
end;

end.
