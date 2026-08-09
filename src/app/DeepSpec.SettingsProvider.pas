{ ============================================================================
  DeepSpec.SettingsProvider

  DeepShell settings-dialog pages for DeepSpec business settings:
    - Scan config: docs dir name + session-restore toggle
    - LLM config: ModelScope API Key / Model (Key stored via DeepBase LLM
      ApiKeyRef, never plaintext)

  Settings persist to DB1(ConfigDB).
  ============================================================================ }

unit DeepSpec.SettingsProvider;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  DeepBase.LLM,
  DeepBase.VCL.DeepShell.Intf;

type
  TDeepSpecSettingsProvider = class(TInterfacedObject, ISettingsPageProvider)
  private
    FLLM: TDeepBaseLLM;
    FEditDocs: TEdit;
    FCheckRestore: TCheckBox;
    FEditKey: TEdit;
    FEditModel: TEdit;
  public
    constructor Create(ALLM: TDeepBaseLLM);
    function PageId: string;
    function Caption: string;
    function GroupName: string;
    function CreatePage(AOwner: TComponent): TControl;
    procedure Apply;
    procedure Cancel;
    procedure RestoreDefaults;
  end;

implementation

uses
  Vcl.Graphics,
  DeepBase.Config,
  DeepSpec.Services.LLMConfig;

const
  KEY_DOCS_PATH = 'deepspec.docs_path';
  KEY_SESSION_RESTORE = 'deepspec.session.restore';

{ TDeepSpecSettingsProvider }

constructor TDeepSpecSettingsProvider.Create(ALLM: TDeepBaseLLM);
begin
  inherited Create;
  FLLM := ALLM;
end;

function TDeepSpecSettingsProvider.PageId: string;
begin
  Result := 'deepspec.settings';
end;

function TDeepSpecSettingsProvider.Caption: string;
begin
  Result := 'DeepSpec';
end;

function TDeepSpecSettingsProvider.GroupName: string;
begin
  Result := 'DeepSpec';
end;

function TDeepSpecSettingsProvider.CreatePage(AOwner: TComponent): TControl;
var
  LPanel: TPanel;
  LLabel: TLabel;
  LTop: Integer;
begin
  LPanel := TPanel.Create(AOwner);
  LPanel.Parent := nil;
  LPanel.BevelOuter := bvNone;
  LPanel.Align := alClient;
  LTop := 8;

  // Scan config group
  LLabel := TLabel.Create(LPanel);
  LLabel.Parent := LPanel;
  LLabel.Left := 8; LLabel.Top := LTop; LLabel.Caption := 'Docs dir';
  FEditDocs := TEdit.Create(LPanel);
  FEditDocs.Parent := LPanel;
  FEditDocs.Left := 140; FEditDocs.Top := LTop - 3; FEditDocs.Width := 240;
  FEditDocs.Text := GetConfig(KEY_DOCS_PATH, 'docs');
  Inc(LTop, 32);

  FCheckRestore := TCheckBox.Create(LPanel);
  FCheckRestore.Parent := LPanel;
  FCheckRestore.Left := 8; FCheckRestore.Top := LTop; FCheckRestore.Width := 300;
  FCheckRestore.Caption := 'Restore last session on startup';
  FCheckRestore.Checked := GetConfigBool(KEY_SESSION_RESTORE, True);
  Inc(LTop, 36);

  // LLM config group
  LLabel := TLabel.Create(LPanel);
  LLabel.Parent := LPanel;
  LLabel.Left := 8; LLabel.Top := LTop; LLabel.Caption := 'ModelScope API Key';
  FEditKey := TEdit.Create(LPanel);
  FEditKey.Parent := LPanel;
  FEditKey.Left := 140; FEditKey.Top := LTop - 3; FEditKey.Width := 240;
  FEditKey.PasswordChar := '*';
  FEditKey.TextHint := 'Leave empty to keep the saved key';
  Inc(LTop, 32);

  LLabel := TLabel.Create(LPanel);
  LLabel.Parent := LPanel;
  LLabel.Left := 8; LLabel.Top := LTop; LLabel.Caption := 'Model';
  FEditModel := TEdit.Create(LPanel);
  FEditModel.Parent := LPanel;
  FEditModel.Left := 140; FEditModel.Top := LTop - 3; FEditModel.Width := 240;
  FEditModel.Text := 'Qwen/Qwen2.5-72B-Instruct';
  Inc(LTop, 32);

  LLabel := TLabel.Create(LPanel);
  LLabel.Parent := LPanel;
  LLabel.Left := 8; LLabel.Top := LTop; LLabel.Width := 400;
  LLabel.Caption := 'API key is stored via DeepBase (ApiKeyRef), not plaintext.';
  LLabel.Font.Color := clGrayText;

  Result := LPanel;
end;

procedure TDeepSpecSettingsProvider.Apply;
var
  LModel: string;
begin
  if FEditDocs <> nil then
    SetConfig(KEY_DOCS_PATH, Trim(FEditDocs.Text));
  if FCheckRestore <> nil then
    SetConfigBool(KEY_SESSION_RESTORE, FCheckRestore.Checked);

  if (FLLM <> nil) and (FEditKey <> nil) and (Trim(FEditKey.Text) <> '') then
  begin
    LModel := Trim(FEditModel.Text);
    if LModel = '' then
      LModel := 'Qwen/Qwen2.5-72B-Instruct';
    TDeepSpecLLMConfigHelper.SaveModelScopeConfig(
      FLLM, Trim(FEditKey.Text), LModel);
  end;
end;

procedure TDeepSpecSettingsProvider.Cancel;
begin
  // Nothing to roll back: Apply is the only write point.
end;

procedure TDeepSpecSettingsProvider.RestoreDefaults;
begin
  if FCheckRestore <> nil then
    FCheckRestore.Checked := True;
  if FEditDocs <> nil then
    FEditDocs.Text := 'docs';
end;

end.
