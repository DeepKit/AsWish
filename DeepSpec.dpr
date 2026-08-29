{ ============================================================================
  DeepSpec
  ---------------------------------------------------------------------------
  AI-native requirement specification tool.
  Fully decoupled, open-source architecture.
  Zero external database or proprietary framework dependencies.
  ============================================================================ }

program DeepSpec;

uses
  System.SysUtils,
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Dialogs,
  DeepSpec.AutoFix in 'src\core\DeepSpec.AutoFix.pas',
  DeepSpec.Security in 'src\core\DeepSpec.Security.pas',
  DeepSpec.Config in 'src\core\DeepSpec.Config.pas',
  DeepSpec.Logger in 'src\core\DeepSpec.Logger.pas',
  DeepSpec.UI.Types in 'src\core\DeepSpec.UI.Types.pas',
  DeepSpec.UI.Intf in 'src\core\DeepSpec.UI.Intf.pas',
  DeepSpec.Shell.Form in 'src\app\DeepSpec.Shell.Form.pas',
  DeepSpec.Localization in 'src\app\DeepSpec.Localization.pas',
  DeepSpec.SettingsProvider in 'src\app\DeepSpec.SettingsProvider.pas',
  DeepSpec.Services.Storage in 'src\app\DeepSpec.Services.Storage.pas',
  DeepSpec.MainForm in 'src\app\DeepSpec.MainForm.pas',
  DeepSpec.Commands in 'src\app\DeepSpec.Commands.pas',
  DeepSpec.Providers in 'src\app\DeepSpec.Providers.pas',
  DeepSpec.Services.Project in 'src\services\DeepSpec.Services.Project.pas',
  DeepSpec.Services.Scan in 'src\services\DeepSpec.Services.Scan.pas',
  DeepSpec.Services.SpecStore in 'src\services\DeepSpec.Services.SpecStore.pas',
  DeepSpec.Services.Render in 'src\services\DeepSpec.Services.Render.pas',
  DeepSpec.Services.TreeBuilder in 'src\services\DeepSpec.Services.TreeBuilder.pas',
  DeepSpec.Services.Prompts in 'src\services\DeepSpec.Services.Prompts.pas',
  DeepSpec.Services.Decisions in 'src\services\DeepSpec.Services.Decisions.pas',
  DeepSpec.Services.LLM in 'src\services\DeepSpec.Services.LLM.pas',
  DeepSpec.Services.LLMConfig in 'src\services\DeepSpec.Services.LLMConfig.pas',
  DeepSpec.Services.Context in 'src\services\DeepSpec.Services.Context.pas',
  DeepSpec.Models in 'src\models\DeepSpec.Models.pas',
  DeepSpec.Hash in 'src\core\DeepSpec.Hash.pas',
  DeepSpec.Yaml.Writer in 'src\core\DeepSpec.Yaml.Writer.pas',
  DeepSpec.Yaml.Parser in 'src\core\DeepSpec.Yaml.Parser.pas',
  DeepSpec.Delphi.DfmParser in 'src\core\DeepSpec.Delphi.DfmParser.pas',
  DeepSpec.Delphi.PasParser in 'src\core\DeepSpec.Delphi.PasParser.pas',
  DeepSpec.Validation in 'src\core\DeepSpec.Validation.pas',
  DeepSpec.Controller in 'src\controllers\DeepSpec.Controller.pas',
  DeepSpec.Providers.Structure in 'src\providers\DeepSpec.Providers.Structure.pas',
  DeepSpec.Providers.MainView in 'src\providers\DeepSpec.Providers.MainView.pas',
  DeepSpec.Providers.Inspector in 'src\providers\DeepSpec.Providers.Inspector.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  InstallAIErrorHandler;
  TDeepSpecAutoFix.Install;
  TAutoFixVclHook.Install;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'DeepSpec';

  try
    Application.CreateForm(TDeepSpecMainForm, DeepSpecMainForm);
  except
    on E: Exception do
    begin
      ShowMessage('FATAL: Form creation failed: ' + E.ClassName + ': ' + E.Message);
      Exit;
    end;
  end;

  TDeepSpecAutoFix.RegisterScenario('smoke', procedure
  begin
  end);

  Application.Run;
end.
