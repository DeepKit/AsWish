{ ============================================================================
  AsWish.Commands
  ---------------------------------------------------------------------------
  Registers all AsWish commands into the desktop shell command manager.
  Commands delegate to TAsWishController via the MainForm reference.
  Zero external dependencies.
  ============================================================================ }

unit AsWish.Commands;

interface

uses
  System.SysUtils,
  Vcl.Forms,
  AsWish.UI.Intf,
  AsWish.UI.Types;

procedure RegisterAllCommands(const ACommands: IShellCommandManager;
  AForm: TForm);

implementation

uses
  Vcl.FileCtrl,
  Vcl.Dialogs,
  AsWish.Services.LLMConfig,
  AsWish.MainForm;

procedure RegisterAllCommands(const ACommands: IShellCommandManager;
  AForm: TForm);
var
  LCmd: TShellCommand;
  LForm: TAsWishMainForm;
begin
  LForm := AForm as TAsWishMainForm;

  LCmd := TShellCommand.Make('aswish.project.open',
    LForm.ShellText('aswish.cmd.open', 'Open Project'));
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

  LCmd := TShellCommand.Make('aswish.scan.run',
    LForm.ShellText('aswish.cmd.scan', 'Run Scan'));
  LCmd.Category := 'Run';
  LCmd.ShortcutText := 'F5';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RunScan;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.spec.generate',
    LForm.ShellText('aswish.cmd.generate', 'Generate B'));
  LCmd.Category := 'Run';
  LCmd.RiskLevel := rlMedium;
  LCmd.Handler := procedure
    begin
      LForm.Controller.GenerateB;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.html.render',
    LForm.ShellText('aswish.cmd.render', 'Render HTML'));
  LCmd.Category := 'View';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RenderAll;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.html.refresh-from-yaml',
    LForm.ShellText('aswish.cmd.refresh', 'Refresh HTML from YAML'));
  LCmd.Category := 'View';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RefreshFromYaml;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.decisions.promote',
    LForm.ShellText('aswish.cmd.promote', 'Promote Pending Decisions'));
  LCmd.Category := 'Tools';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.PromotePendingDecisions;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.prompt.export',
    LForm.ShellText('aswish.cmd.export', 'Export Prompt'));
  LCmd.Category := 'Tools';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.ExportPrompt;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.data.render',
    LForm.ShellText('aswish.cmd.renderdata', 'Render Data Tree'));
  LCmd.Category := 'View';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    begin
      LForm.Controller.RenderAll;
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.llm.setup',
    LForm.ShellText('aswish.cmd.llmsetup', 'Setup LLM (ModelScope)'));
  LCmd.Category := 'Tools';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    var
      LApiKey, LModel: string;
    begin
      LApiKey := '';
      if not InputQuery(LForm.ShellText('aswish.llm.title', 'LLM Setup'),
        LForm.ShellText('aswish.llm.apikey',
          'Enter ModelScope API Key:'), LApiKey) then
        Exit;
      if LApiKey.Trim = '' then Exit;

      LModel := 'Qwen/Qwen2.5-72B-Instruct';
      if not InputQuery(LForm.ShellText('aswish.llm.title', 'LLM Setup'),
        LForm.ShellText('aswish.llm.model',
          'Model name (default: Qwen/Qwen2.5-72B-Instruct):'), LModel) then
        Exit;
      if LModel.Trim = '' then
        LModel := 'Qwen/Qwen2.5-72B-Instruct';

      try
        TAsWishLLMConfigHelper.SaveModelScopeConfig(LApiKey.Trim, LModel.Trim);
        ShowMessage(LForm.ShellText('aswish.llm.configured',
          'LLM configured successfully. Use Generate B to call it.'));
      except
        on E: Exception do
          ShowMessage(LForm.ShellText('aswish.llm.savefail',
            'Failed to save LLM config: ') + E.Message);
      end;
    end;
  ACommands.RegisterCommand(LCmd);

  // Natural Language Intent -> Change Set -> Decision Commands (WO-20260830-0027D)
  LCmd := TShellCommand.Make('aswish.changeset.submit',
    LForm.ShellText('aswish.cmd.submitintent', 'Submit Natural Language Intent...'));
  LCmd.Category := 'Spec';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    var
      LNodeId, LIntent, LCSId: string;
    begin
      LNodeId := '';
      if not InputQuery('Natural Language Revision', 'Target Node ID (e.g. func-inventory):', LNodeId) then Exit;
      if LNodeId.Trim = '' then Exit;
      LIntent := '';
      if not InputQuery('Natural Language Revision', 'What is your intended change?', LIntent) then Exit;
      if LIntent.Trim = '' then Exit;

      LCSId := LForm.Controller.SubmitUserIntent(LNodeId.Trim, LIntent.Trim);
      if LCSId <> '' then
        ShowMessage('Created ChangeSet ' + LCSId + #13#10 + 'Use "Review Change Set" to inspect interpreted changes.');
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.changeset.review',
    LForm.ShellText('aswish.cmd.reviewchangeset', 'Review Change Set...'));
  LCmd.Category := 'Spec';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    var
      LCSId, LReview: string;
    begin
      LCSId := '';
      InputQuery('Review Change Set', 'ChangeSet ID (leave empty for latest):', LCSId);
      LReview := LForm.Controller.ReviewChangeSet(LCSId.Trim);
      ShowMessage(LReview);
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.changeset.accept',
    LForm.ShellText('aswish.cmd.acceptchangeset', 'Accept Change Set...'));
  LCmd.Category := 'Spec';
  LCmd.RiskLevel := rlMedium;
  LCmd.Handler := procedure
    var
      LCSId, LRationale: string;
    begin
      LCSId := '';
      InputQuery('Accept Change Set', 'ChangeSet ID (leave empty for latest):', LCSId);
      LRationale := '';
      InputQuery('Accept Change Set', 'Rationale / Reason:', LRationale);
      if LForm.Controller.AcceptChangeSet(LCSId.Trim, LRationale.Trim) then
        ShowMessage('ChangeSet ' + LCSId + ' ACCEPTED and applied to Canonical Spec.');
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.changeset.reject',
    LForm.ShellText('aswish.cmd.rejectchangeset', 'Reject Change Set...'));
  LCmd.Category := 'Spec';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    var
      LCSId, LRationale: string;
    begin
      LCSId := '';
      InputQuery('Reject Change Set', 'ChangeSet ID (leave empty for latest):', LCSId);
      LRationale := '';
      InputQuery('Reject Change Set', 'Rejection Reason:', LRationale);
      if LForm.Controller.RejectChangeSet(LCSId.Trim, LRationale.Trim) then
        ShowMessage('ChangeSet ' + LCSId + ' REJECTED. Canonical Spec remains untouched.');
    end;
  ACommands.RegisterCommand(LCmd);

  LCmd := TShellCommand.Make('aswish.changeset.clarify',
    LForm.ShellText('aswish.cmd.clarifychangeset', 'Clarify Change Set...'));
  LCmd.Category := 'Spec';
  LCmd.RiskLevel := rlLow;
  LCmd.Handler := procedure
    var
      LCSId, LClarification: string;
    begin
      LCSId := '';
      InputQuery('Clarify Change Set', 'ChangeSet ID (leave empty for latest):', LCSId);
      LClarification := '';
      InputQuery('Clarify Change Set', 'Clarification details:', LClarification);
      if LForm.Controller.ClarifyChangeSet(LCSId.Trim, LClarification.Trim) then
        ShowMessage('Clarification recorded for ChangeSet ' + LCSId + '. Canonical Spec remains untouched.');
    end;
  ACommands.RegisterCommand(LCmd);
end;

end.
