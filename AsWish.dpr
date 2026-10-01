{ ============================================================================
  AsWish
  ---------------------------------------------------------------------------
  AI-native requirement specification tool.
  Fully decoupled, open-source architecture.
  Zero external database or proprietary framework dependencies.
  ============================================================================ }

program AsWish;

uses
  System.SysUtils,
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Dialogs,
  AsWish.AutoFix in 'src\core\AsWish.AutoFix.pas',
  AsWish.Security in 'src\core\AsWish.Security.pas',
  AsWish.Config in 'src\core\AsWish.Config.pas',
  AsWish.Logger in 'src\core\AsWish.Logger.pas',
  AsWish.UI.Types in 'src\core\AsWish.UI.Types.pas',
  AsWish.UI.Intf in 'src\core\AsWish.UI.Intf.pas',
  AsWish.Shell.Form in 'src\app\AsWish.Shell.Form.pas',
  AsWish.Localization in 'src\app\AsWish.Localization.pas',
  AsWish.SettingsProvider in 'src\app\AsWish.SettingsProvider.pas',
  AsWish.Services.Storage in 'src\app\AsWish.Services.Storage.pas',
  AsWish.MainForm in 'src\app\AsWish.MainForm.pas',
  AsWish.Commands in 'src\app\AsWish.Commands.pas',
  AsWish.Providers in 'src\app\AsWish.Providers.pas',
  AsWish.Services.Project in 'src\services\AsWish.Services.Project.pas',
  AsWish.Services.Scan in 'src\services\AsWish.Services.Scan.pas',
  AsWish.Services.SpecStore in 'src\services\AsWish.Services.SpecStore.pas',
  AsWish.Services.Render in 'src\services\AsWish.Services.Render.pas',
  AsWish.Services.TreeBuilder in 'src\services\AsWish.Services.TreeBuilder.pas',
  AsWish.Services.Prompts in 'src\services\AsWish.Services.Prompts.pas',
  AsWish.Services.Decisions in 'src\services\AsWish.Services.Decisions.pas',
  AsWish.Services.LLM in 'src\services\AsWish.Services.LLM.pas',
  AsWish.Services.LLMConfig in 'src\services\AsWish.Services.LLMConfig.pas',
  AsWish.Services.Context in 'src\services\AsWish.Services.Context.pas',
  AsWish.Models in 'src\models\AsWish.Models.pas',
  AsWish.Hash in 'src\core\AsWish.Hash.pas',
  AsWish.TextIO in 'src\core\AsWish.TextIO.pas',
  AsWish.Yaml.Writer in 'src\core\AsWish.Yaml.Writer.pas',
  AsWish.Yaml.Parser in 'src\core\AsWish.Yaml.Parser.pas',
  AsWish.Delphi.DfmParser in 'src\core\AsWish.Delphi.DfmParser.pas',
  AsWish.Delphi.PasParser in 'src\core\AsWish.Delphi.PasParser.pas',
  AsWish.Validation in 'src\core\AsWish.Validation.pas',
  AsWish.Controller in 'src\controllers\AsWish.Controller.pas',
  AsWish.Providers.Structure in 'src\providers\AsWish.Providers.Structure.pas',
  AsWish.Providers.MainView in 'src\providers\AsWish.Providers.MainView.pas',
  AsWish.Providers.Inspector in 'src\providers\AsWish.Providers.Inspector.pas',
  AsWish.CommandLine in 'src\core\AsWish.CommandLine.pas',
  AsWish.Version in 'src\core\AsWish.Version.pas';

{$R *.res}

var
  LArgs: TArray<string>;
  LParsed: TAsWishParsedArgs;
  I: Integer;
begin
  SetLength(LArgs, ParamCount);
  for I := 1 to ParamCount do
    LArgs[I - 1] := ParamStr(I);

  LParsed := TAsWishCommandLine.ParseGui(LArgs);
  if not LParsed.IsValid then
  begin
    TAsWishCommandLine.OutputConsoleError(Format(
      '[AsWish.exe ERROR] %s'#13#10 +
      'Usage:'#13#10 +
      '  AsWish.exe [project-directory]'#13#10 +
      '  AsWish.exe --gui-verify <project-directory>'#13#10 +
      'Note: For headless CLI operations (such as validate, scan, difference), use cli\bin\AsWish.CLI.exe.',
      [LParsed.ErrorMessage]));
    Halt(1);
  end;

  ReportMemoryLeaksOnShutdown := not LParsed.IsGuiVerify;
  InstallAIErrorHandler;
  TAsWishAutoFix.Install;
  TAutoFixVclHook.Install;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := ASWISH_BANNER;

  try
    Application.CreateForm(TAsWishMainForm, AsWishMainForm);
  except
    on E: Exception do
    begin
      Exit;
    end;
  end;

  TAsWishAutoFix.RegisterScenario('smoke', procedure
  begin
  end);

  Application.Run;
end.
