{ ============================================================================
  DeepSpec.Commands
  ---------------------------------------------------------------------------
  Registers all DeepSpec commands into the desktop shell command manager.
  Commands delegate to TDeepSpecController via the MainForm reference.
  Zero external dependencies.
  ============================================================================ }

unit DeepSpec.Commands;

interface

uses
  System.SysUtils,
  Vcl.Forms,
  DeepSpec.UI.Intf,
  DeepSpec.UI.Types;

procedure RegisterAllCommands(const ACommands: IShellCommandManager;
  AForm: TForm);

implementation

uses
  Vcl.FileCtrl,
  Vcl.Dialogs,
  DeepSpec.Services.LLMConfig,
  DeepSpec.MainForm;

procedure RegisterAllCommands(const ACommands: IShellCommandManager;
  AForm: TForm);
var
  LCmd: TShellCommand;
  LForm: TDeepSpecMainForm;
begin
  LForm := AForm as TDeepSpecMainForm;

  LCmd := TShellCommand.Make('deepspec.project.open',
    LForm.ShellText('deepspec.cmd.open', 'Open Project'));
  LCmd.Category := 'File';
  LCmd.ShortcutText := 'Ctrl+O';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    var
      LDir: string;
    begin
      LDir := '';
      if SelectDirectory('Select project folder', '', LDir) then
      begin
        LForm.Controller.OpenAndScan(LDir);
        if LForm.Recent <> nil then
          LForm.Recent.AddRecentProject(LDir, LDir,
            ExtractFileName(ExcludeTrailingPathDelimiter(LDir)), '');
      end;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.scan.run',
    LForm.ShellText('deepspec.cmd.scan', 'Run Scan'));
  LCmd.Category := 'Run';
  LCmd.ShortcutText := 'F5';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RunScan;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.spec.generate',
    LForm.ShellText('deepspec.cmd.generate', 'Generate B'));
  LCmd.Category := 'Run';
  LCmd.RiskLevel := rlMedium;
  LCmd.Handler := procedure
    begin
      LForm.Controller.GenerateB;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.html.render',
    LForm.ShellText('deepspec.cmd.render', 'Render HTML'));
  LCmd.Category := 'View';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RenderAll;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.html.refresh-from-yaml',
    LForm.ShellText('deepspec.cmd.refresh', 'Refresh HTML from YAML'));
  LCmd.Category := 'View';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RefreshFromYaml;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.decisions.promote',
    LForm.ShellText('deepspec.cmd.promote', 'Promote Pending Decisions'));
  LCmd.Category := 'Tools';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.PromotePendingDecisions;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.prompt.export',
    LForm.ShellText('deepspec.cmd.export', 'Export Prompt'));
  LCmd.Category := 'Tools';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.ExportPrompt;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.data.render',
    LForm.ShellText('deepspec.cmd.renderdata', 'Render Data Tree'));
  LCmd.Category := 'View';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RenderAll;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('deepspec.llm.setup',
    LForm.ShellText('deepspec.cmd.llmsetup', 'Setup LLM (ModelScope)'));
  LCmd.Category := 'Tools';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    var
      LApiKey, LModel: string;
    begin
      LApiKey := '';
      if not InputQuery(LForm.ShellText('deepspec.llm.title', 'LLM Setup'),
        LForm.ShellText('deepspec.llm.apikey',
          'Enter ModelScope API Key:'), LApiKey) then
        Exit;
      if LApiKey.Trim = '' then Exit;

      LModel := 'Qwen/Qwen2.5-72B-Instruct';
      if not InputQuery(LForm.ShellText('deepspec.llm.title', 'LLM Setup'),
        LForm.ShellText('deepspec.llm.model',
          'Model name (default: Qwen/Qwen2.5-72B-Instruct):'), LModel) then
        Exit;
      if LModel.Trim = '' then
        LModel := 'Qwen/Qwen2.5-72B-Instruct';

      try
        TDeepSpecLLMConfigHelper.SaveModelScopeConfig(LApiKey.Trim, LModel.Trim);
        ShowMessage(LForm.ShellText('deepspec.llm.configured',
          'LLM configured successfully. Use Generate B to call it.'));
      except
        on E: Exception do
          ShowMessage(LForm.ShellText('deepspec.llm.savefail',
            'Failed to save LLM config: ') + E.Message);
      end;
    end;
  ACommands.RegisterCommand(LCmd);
end;

end.
