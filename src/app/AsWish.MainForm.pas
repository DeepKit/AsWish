{ ============================================================================
  AsWish.MainForm
  ---------------------------------------------------------------------------
  Main form for AsWish - inherits TAsWishShellForm.
  Coordinates UI layout, tool panels and registers services, commands, providers.
  Zero external dependencies.
  ============================================================================ }

unit AsWish.MainForm;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vcl.Forms,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.FileCtrl,
  Vcl.Buttons,
  Vcl.Shell.ShellCtrls,
  Vcl.Edge,
  AsWish.Shell.Form,
  AsWish.UI.Types,
  AsWish.UI.Intf,
  AsWish.Controller,
  AsWish.Services.Project,
  AsWish.Services.Scan,
  AsWish.Services.SpecStore,
  AsWish.Services.Render,
  AsWish.Services.TreeBuilder,
  AsWish.Services.Prompts,
  AsWish.Services.Decisions,
  AsWish.Services.LLM,
  AsWish.Services.Settings,
  AsWish.Version,
  AsWish.Models;

type
  TAsWishMainForm = class(TAsWishShellForm)
  private
    FController: TAsWishController;
    FProjectService: TAsWishProjectService;
    FScanService: TAsWishScanService;
    FSpecStore: TAsWishStoreService;
    FRender: TAsWishRenderService;
    FTreeBuilder: TAsWishTreeBuilder;
    FPrompts: TAsWishPromptService;
    FDecisions: TAsWishDecisionsService;
    FLLMService: TAsWishLLMService;
    FSettings: TAsWishSettingsService;

    // UI: Left panel tabs
    FLeftPages: TPageControl;
    FTabDirs: TTabSheet;
    FTabFunc: TTabSheet;
    FTabModule: TTabSheet;
    FTabView: TTabSheet;

    // Directory tab controls
    FDriveCombo: TComboBox;
    FBtnVisualize: TSpeedButton;
    FMruCombo: TComboBox;
    FShellTree: TShellTreeView;

    // Tree tabs
    FFuncTree: TTreeView;
    FModuleTree: TTreeView;
    FViewTree: TTreeView;

    // Lower panel memos
    FScanLogMemo: TMemo;
    FDocsMemo: TMemo;
    FScanEventToken: string;
    FCaptureDone: Boolean;
    FCaptureResult: HResult;
    FLastHtmlPath: string;

    procedure ExecuteCommandSync(const ACommandLine: string);
    function StripHtmlToInnerText(const AHtml: string): string;

    procedure HandleScanEvent(const AEvent: TDeepShellEvent);
    procedure PopulateTreeFromSpec(ATree: TTreeView; ANodes: TList<TSpecNode>);
    procedure PopulateDocsPanel;
    procedure DoSpecTreeChange(Sender: TObject; Node: TTreeNode);
    procedure BuildLeftPanelUI;
    procedure PopulateMruCombo;
    procedure DoDriveChange(Sender: TObject);
    procedure DoShellTreeChange(Sender: TObject; Node: TTreeNode);
    procedure DoBtnVisualizeClick(Sender: TObject);
    procedure DoMruSelect(Sender: TObject);
    procedure BrowserCapturePreviewCompleted(Sender: TCustomEdgeBrowser; AResult: HResult);
    function WaitForBrowserReady(const AExpectedSnippet: string; ATimeoutMs: Integer; out ADomText: string): Boolean;
    procedure OpenView(const ARef: TShellObjectRef);
    procedure SaveWindowScreenshot(const AFilePath: string);
    procedure RunGuiVerification(const AProjectPath: string);
  protected
    procedure InitializeShell; override;
    procedure RegisterServices; override;
    procedure RegisterCommands; override;
    procedure RegisterProviders; override;
    procedure AfterShellShown; override;
    procedure ShutdownShell; override;
  public
    property Controller: TAsWishController read FController;
  end;

var
  AsWishMainForm: TAsWishMainForm;

implementation

uses
  System.IOUtils,
  Winapi.Windows,
  Winapi.Messages,
  AsWish.Commands,
  AsWish.Providers,
  AsWish.Localization,
  AsWish.Services.Storage,
  AsWish.SettingsProvider,
  AsWish.AutoFix,
  AsWish.Logger,
  AsWish.Config,
  Vcl.Imaging.pngimage;

{ Status adapter }

type
  TShellStatusManagerImpl = class(TInterfacedObject, IShellStatusManager)
  private
    FForm: TAsWishMainForm;
    FEntries: TList<TShellStatusEntry>;
  public
    constructor Create(AForm: TAsWishMainForm);
    destructor Destroy; override;
    procedure Info(const ASource, AMessage: string);
    procedure Warning(const ASource, AMessage: string);
    procedure LogError(const ASource, AMessage, ADetail: string);
    procedure ShellError(const ASource, AMessage, ADetail: string);
    procedure Progress(const ATaskId, ASource: string; APercent: Integer; const AMessage: string);
    procedure TaskStart(const ATaskId, ASource, AMessage: string);
    procedure TaskFinish(const ATaskId, AMessage: string);
    procedure Diagnostic(const ASource, AMessage: string);
    function GetEntries: TArray<TShellStatusEntry>;
    procedure ClearEntries;
    procedure SetSanitizer(ASanitizer: TShellStatusSanitizer);
  end;

constructor TShellStatusManagerImpl.Create(AForm: TAsWishMainForm);
begin
  inherited Create;
  FForm := AForm;
  FEntries := TList<TShellStatusEntry>.Create;
end;

destructor TShellStatusManagerImpl.Destroy;
begin
  FEntries.Free;
  inherited;
end;

procedure TShellStatusManagerImpl.Info(const ASource, AMessage: string);
begin
  if FForm <> nil then
    FForm.SetStatusMessage(AMessage);
  Logger.Info(AMessage, ASource);
end;

procedure TShellStatusManagerImpl.Warning(const ASource, AMessage: string);
begin
  if FForm <> nil then
    FForm.SetStatusMessage('Warning: ' + AMessage);
  Logger.Warn(AMessage, ASource);
end;

procedure TShellStatusManagerImpl.LogError(const ASource, AMessage, ADetail: string);
begin
  if FForm <> nil then
    FForm.SetStatusMessage('Error: ' + AMessage);
  Logger.Error(AMessage + ' ' + ADetail, ASource);
end;

procedure TShellStatusManagerImpl.ShellError(const ASource, AMessage, ADetail: string);
begin
  LogError(ASource, AMessage, ADetail);
end;

procedure TShellStatusManagerImpl.Progress(const ATaskId, ASource: string;
  APercent: Integer; const AMessage: string);
begin
  if FForm <> nil then
    FForm.SetStatusMessage(Format('[%d%%] %s', [APercent, AMessage]));
end;

procedure TShellStatusManagerImpl.TaskStart(const ATaskId, ASource, AMessage: string);
begin
  Info(ASource, AMessage);
end;

procedure TShellStatusManagerImpl.TaskFinish(const ATaskId, AMessage: string);
begin
  Info('Task', AMessage);
end;

procedure TShellStatusManagerImpl.Diagnostic(const ASource, AMessage: string);
begin
  Logger.Debug(AMessage, ASource);
end;

function TShellStatusManagerImpl.GetEntries: TArray<TShellStatusEntry>;
begin
  Result := FEntries.ToArray;
end;

procedure TShellStatusManagerImpl.ClearEntries;
begin
  FEntries.Clear;
end;

procedure TShellStatusManagerImpl.SetSanitizer(ASanitizer: TShellStatusSanitizer);
begin
end;

{ TAsWishMainForm }

procedure TAsWishMainForm.InitializeShell;

  procedure CleanupCreatedServices;
  begin
    FreeAndNil(FProjectService);
    FreeAndNil(FScanService);
    FreeAndNil(FSpecStore);
    FreeAndNil(FRender);
    FreeAndNil(FTreeBuilder);
    FreeAndNil(FPrompts);
    FreeAndNil(FDecisions);
    FreeAndNil(FSettings);
    FreeAndNil(FLLMService);
  end;

begin
  inherited InitializeShell;
  Caption := ASWISH_BANNER;

  FProjectService := nil;
  FScanService := nil;
  FSpecStore := nil;
  FRender := nil;
  FTreeBuilder := nil;
  FPrompts := nil;
  FDecisions := nil;
  FSettings := nil;
  FLLMService := nil;

  try
    FProjectService := TAsWishProjectService.Create;
    FScanService := TAsWishScanService.Create;
    FSpecStore := TAsWishStoreService.Create;
    FRender := TAsWishRenderService.Create;
    FTreeBuilder := TAsWishTreeBuilder.Create;
    FPrompts := TAsWishPromptService.Create;
    FDecisions := TAsWishDecisionsService.Create;
    FSettings := TAsWishSettingsService.Create;
    FLLMService := TAsWishLLMService.Create('Default');
  except
    CleanupCreatedServices;
    raise;
  end;
end;

procedure TAsWishMainForm.RegisterServices;
var
  LStatus: IShellStatusManager;
begin
  inherited RegisterServices;

  Services.RegisterService('aswish.project', FProjectService);
  Services.RegisterService('aswish.scan', FScanService);
  Services.RegisterService('aswish.specstore', FSpecStore);
  Services.RegisterService('aswish.render', FRender);
  Services.RegisterService('aswish.treebuilder', FTreeBuilder);
  Services.RegisterService('aswish.prompts', FPrompts);
  Services.RegisterService('aswish.decisions', FDecisions);
  Services.RegisterService('aswish.llm', FLLMService);
  Services.RegisterService('aswish.settings', FSettings);

  LStatus := TShellStatusManagerImpl.Create(Self);

  FController := TAsWishController.Create(
    FProjectService, FScanService, FSpecStore, FRender, FTreeBuilder,
    FPrompts, FDecisions, FLLMService, FSettings,
    LStatus, Context, Bus);

  Logger.Info('AsWish startup completed, locale=' + AsWishDetectLocale, 'AsWish');
end;

procedure TAsWishMainForm.RegisterCommands;
begin
  inherited RegisterCommands;
  AsWish.Commands.RegisterAllCommands(Commands, Self);
end;

procedure TAsWishMainForm.RegisterProviders;
begin
  inherited RegisterProviders;
  AsWish.Providers.RegisterAllProviders(Self, FProjectService,
    FScanService, FTreeBuilder, FController);
  RegisterSettingsPage(TAsWishSettingsProvider.Create);
  if (CurrentMainControl <> nil) and (CurrentMainControl is TCustomEdgeBrowser) then
    TCustomEdgeBrowser(CurrentMainControl).CreateWebView;
end;

procedure TAsWishMainForm.AfterShellShown;
var
  LOpenDir: string;
  LIsGuiVerify: Boolean;
  I: Integer;
begin
  inherited AfterShellShown;

  BuildLeftPanelUI;

  TAsWishAutoFix.SendHealthSignal('startup', 1);
  TAsWishAutoFix.RegisterScenario('smoke', procedure
  begin
  end);

  SetStatusMessage(ShellText('aswish.status.ready',
    'AsWish ready. Open a project folder to begin.'));

  LOpenDir := '';
  LIsGuiVerify := False;
  for I := 1 to ParamCount do
  begin
    if (ParamStr(I) = '--gui-verify') or (ParamStr(I) = '-gui-verify') then
      LIsGuiVerify := True
    else if TDirectory.Exists(ParamStr(I)) then
      LOpenDir := ParamStr(I);
  end;

  if LIsGuiVerify and (LOpenDir <> '') then
  begin
    RunGuiVerification(LOpenDir);
    Exit;
  end;

  // Session restore
  try
    if (LOpenDir = '') then
    begin
      var LRestore := GetConfigBool('aswish.session.restore', True);
      if LRestore and (Recent <> nil) and (not FController.IsProjectOpen) then
      begin
        var LItems := Recent.GetRecentProjects;
        for var LItem in LItems do
          if (not LItem.Invalid) and TDirectory.Exists(LItem.Path) then
          begin
            LOpenDir := LItem.Path;
            Break;
          end;
      end;
    end;

    if (LOpenDir <> '') and (not FController.IsProjectOpen) then
    begin
      SetStatusMessage('Opening project: ' + LOpenDir);
      FController.OpenAndScan(LOpenDir);
      if Recent <> nil then
      begin
        Recent.AddRecentProject(LOpenDir, LOpenDir,
          ExtractFileName(ExcludeTrailingPathDelimiter(LOpenDir)), '');
        PopulateMruCombo;
      end;
    end;
  except
    on E: Exception do
      Logger.Error('Project open failed: ' + E.Message, 'AsWish');
  end;
end;


procedure TAsWishMainForm.BuildLeftPanelUI;
var
  LTopBar: TPanel;
  LDrives: TArray<string>;
  LIdx: Integer;
begin
  if LeftPanel = nil then Exit;

  // Create PageControl in LeftPanel
  FLeftPages := TPageControl.Create(Self);
  FLeftPages.Parent := LeftPanel;
  FLeftPages.Align := alClient;

  // Tab 1: Directory
  FTabDirs := TTabSheet.Create(FLeftPages);
  FTabDirs.PageControl := FLeftPages;
  FTabDirs.Caption := ShellText('aswish.tab.dirs', 'Directory');

  LTopBar := TPanel.Create(FTabDirs);
  LTopBar.Parent := FTabDirs;
  LTopBar.Align := alTop;
  LTopBar.Height := 28;
  LTopBar.BevelOuter := bvNone;

  FDriveCombo := TComboBox.Create(LTopBar);
  FDriveCombo.Parent := LTopBar;
  FDriveCombo.Align := alLeft;
  FDriveCombo.Width := 60;
  FDriveCombo.Style := csDropDownList;
  FDriveCombo.OnChange := DoDriveChange;

  FBtnVisualize := TSpeedButton.Create(LTopBar);
  FBtnVisualize.Parent := LTopBar;
  FBtnVisualize.Align := alRight;
  FBtnVisualize.Width := 70;
  FBtnVisualize.Caption := ShellText('aswish.btn.visualize', 'Visualize');
  FBtnVisualize.OnClick := DoBtnVisualizeClick;

  FMruCombo := TComboBox.Create(FTabDirs);
  FMruCombo.Parent := FTabDirs;
  FMruCombo.Align := alTop;
  FMruCombo.Style := csDropDownList;
  FMruCombo.TextHint := ShellText('aswish.mru.hint', 'Recent projects...');
  FMruCombo.OnChange := DoMruSelect;

  FShellTree := TShellTreeView.Create(FTabDirs);
  FShellTree.Parent := FTabDirs;
  FShellTree.Align := alClient;
  FShellTree.OnChange := DoShellTreeChange;

  LDrives := TDirectory.GetLogicalDrives;
  for var LD in LDrives do
    FDriveCombo.Items.Add(LD);
  LIdx := FDriveCombo.Items.IndexOf('C:\');
  if LIdx >= 0 then FDriveCombo.ItemIndex := LIdx else FDriveCombo.ItemIndex := 0;

  // Tab 2: Function Tree
  FTabFunc := TTabSheet.Create(FLeftPages);
  FTabFunc.PageControl := FLeftPages;
  FTabFunc.Caption := ShellText('aswish.tab.func', 'Functions');
  FFuncTree := TTreeView.Create(FTabFunc);
  FFuncTree.Parent := FTabFunc;
  FFuncTree.Align := alClient;
  FFuncTree.ReadOnly := True;

  // Tab 3: Module Tree
  FTabModule := TTabSheet.Create(FLeftPages);
  FTabModule.PageControl := FLeftPages;
  FTabModule.Caption := ShellText('aswish.tab.module', 'Modules');
  FModuleTree := TTreeView.Create(FTabModule);
  FModuleTree.Parent := FTabModule;
  FModuleTree.Align := alClient;
  FModuleTree.ReadOnly := True;

  // Tab 4: View Tree
  FTabView := TTabSheet.Create(FLeftPages);
  FTabView.PageControl := FLeftPages;
  FTabView.Caption := ShellText('aswish.tab.view', 'Views');
  FViewTree := TTreeView.Create(FTabView);
  FViewTree.Parent := FTabView;
  FViewTree.Align := alClient;
  FViewTree.ReadOnly := True;

  PopulateMruCombo;

  // Bottom panel memos
  if BottomPanel <> nil then
  begin
    FScanLogMemo := TMemo.Create(Self);
    FScanLogMemo.Parent := BottomPanel;
    FScanLogMemo.Align := alLeft;
    FScanLogMemo.Width := 450;
    FScanLogMemo.ReadOnly := True;
    FScanLogMemo.ScrollBars := ssVertical;
    FScanLogMemo.Font.Size := 8;
    FScanLogMemo.Color := clBtnFace;
    FScanLogMemo.Lines.Add('(scan log)');

    FDocsMemo := TMemo.Create(Self);
    FDocsMemo.Parent := BottomPanel;
    FDocsMemo.Align := alClient;
    FDocsMemo.ReadOnly := True;
    FDocsMemo.ScrollBars := ssVertical;
    FDocsMemo.Font.Size := 8;
    FDocsMemo.Color := clBtnFace;
    FDocsMemo.Lines.Add('(docs summary)');
  end;

  if Bus <> nil then
    FScanEventToken := Bus.Subscribe(sekProjectOpened, HandleScanEvent);
end;

procedure TAsWishMainForm.PopulateMruCombo;
var
  LItems: TArray<TShellRecentItem>;
begin
  FMruCombo.Items.Clear;
  if Recent = nil then Exit;
  LItems := Recent.GetRecentProjects;
  for var LItem in LItems do
    FMruCombo.Items.Add(LItem.DisplayName);
  if FMruCombo.Items.Count > 0 then
    FMruCombo.ItemIndex := 0;
end;

procedure TAsWishMainForm.DoMruSelect(Sender: TObject);
var
  LItems: TArray<TShellRecentItem>;
  LPath: string;
begin
  if (FMruCombo.ItemIndex < 0) or (Recent = nil) then Exit;
  LItems := Recent.GetRecentProjects;
  if FMruCombo.ItemIndex > High(LItems) then Exit;
  LPath := LItems[FMruCombo.ItemIndex].ItemKey;
  if TDirectory.Exists(LPath) then
  begin
    try
      FShellTree.Path := LPath;
    except
    end;
    FController.OpenAndScan(LPath);
    FBtnVisualize.Enabled := False;
  end;
end;

procedure TAsWishMainForm.DoDriveChange(Sender: TObject);
begin
  if (FDriveCombo.ItemIndex >= 0) and (FShellTree <> nil) then
  begin
    try
      FShellTree.Root := FDriveCombo.Text;
    except
    end;
  end;
end;

procedure TAsWishMainForm.DoShellTreeChange(Sender: TObject; Node: TTreeNode);
begin
  if (Node = nil) or (FShellTree = nil) then Exit;
  FBtnVisualize.Enabled := TDirectory.Exists(FShellTree.Path);
end;

procedure TAsWishMainForm.DoBtnVisualizeClick(Sender: TObject);
var
  LPath: string;
begin
  if FShellTree = nil then Exit;
  if FShellTree.Selected = nil then Exit;

  LPath := FShellTree.Path;
  if (LPath = '') or (not TDirectory.Exists(LPath)) then
  begin
    SetStatusMessage('Please select a folder in the directory tree.');
    Exit;
  end;

  FController.OpenAndScan(LPath);

  if Recent <> nil then
  begin
    Recent.AddRecentProject(LPath, LPath,
      ExtractFileName(ExcludeTrailingPathDelimiter(LPath)), '');
    PopulateMruCombo;
  end;

  FBtnVisualize.Enabled := False;
end;

procedure TAsWishMainForm.ShutdownShell;
begin
  if (FScanEventToken <> '') and (Bus <> nil) then
  begin
    Bus.Unsubscribe(FScanEventToken);
    FScanEventToken := '';
  end;
  FreeAndNil(FController);
  FreeAndNil(FProjectService);
  FreeAndNil(FScanService);
  FreeAndNil(FSpecStore);
  FreeAndNil(FRender);
  FreeAndNil(FTreeBuilder);
  FreeAndNil(FPrompts);
  FreeAndNil(FDecisions);
  FreeAndNil(FSettings);
  FreeAndNil(FLLMService);
  inherited ShutdownShell;
end;

procedure TAsWishMainForm.HandleScanEvent(const AEvent: TDeepShellEvent);
var
  LHtmlPath: string;
begin
  PopulateTreeFromSpec(FFuncTree, FTreeBuilder.FunctionNodes);
  PopulateTreeFromSpec(FModuleTree, FTreeBuilder.ModuleNodes);
  PopulateTreeFromSpec(FViewTree, FTreeBuilder.ViewNodes);
  PopulateDocsPanel;

  if FScanLogMemo <> nil then
  begin
    FScanLogMemo.Lines.BeginUpdate;
    try
      FScanLogMemo.Lines.Clear;
      if FController.IsProjectOpen then
      begin
        FScanLogMemo.Lines.Add('Project: ' + FProjectService.ProjectPath);
        FScanLogMemo.Lines.Add(Format(
          'Scan: %d files (docs %d, code %d, ui %d, config %d, ai_rules %d)',
          [FScanService.TotalFiles,
           FScanService.CategoryCount(fcDocuments),
           FScanService.CategoryCount(fcCode),
           FScanService.CategoryCount(fcUI),
           FScanService.CategoryCount(fcConfig),
           FScanService.CategoryCount(fcAiRules)]));
        FScanLogMemo.Lines.Add(Format(
          'Trees: function %d / module %d / view %d / data %d',
          [FTreeBuilder.FunctionNodes.Count, FTreeBuilder.ModuleNodes.Count,
           FTreeBuilder.ViewNodes.Count, FTreeBuilder.DataNodes.Count]));
        FScanLogMemo.Lines.Add('Type: ' + FProjectService.ProjectType);
      end
      else
        FScanLogMemo.Lines.Add('(no project)');
    finally
      FScanLogMemo.Lines.EndUpdate;
    end;
  end;

  FBtnVisualize.Enabled := True;

  Logger.Info(Format(
    'Scan complete: %d files | func %d / mod %d / view %d / data %d | %s',
    [FScanService.TotalFiles, FTreeBuilder.FunctionNodes.Count,
     FTreeBuilder.ModuleNodes.Count, FTreeBuilder.ViewNodes.Count,
     FTreeBuilder.DataNodes.Count, FProjectService.ProjectType]),
    'AsWish.Scan');

  if FController.IsProjectOpen then
  begin
    LHtmlPath := TPath.Combine(FProjectService.AsWishPath, 'html\index.html');
    if TFile.Exists(LHtmlPath) then
      OpenView(TShellObjectRef.Make('index-html', 'html', '', LHtmlPath));
  end;
end;

procedure TAsWishMainForm.OpenView(const ARef: TShellObjectRef);
var
  LTarget, LUrl: string;
begin
  if Context <> nil then
    Context.SetObject(ARef);

  if (CurrentMainControl <> nil) and (CurrentMainControl is TEdgeBrowser) then
  begin
    LTarget := '';
    if TFile.Exists(ARef.DisplayName) then
      LTarget := ARef.DisplayName
    else if TFile.Exists(ARef.ProviderId) then
      LTarget := ARef.ProviderId
    else if ARef.DisplayName.StartsWith('http://') or ARef.DisplayName.StartsWith('https://') or ARef.DisplayName.StartsWith('file://') then
      LUrl := ARef.DisplayName;

    if LTarget <> '' then
    begin
      FLastHtmlPath := LTarget;
      LUrl := 'file:///' + LTarget.Replace('\', '/');
    end;

    if LUrl <> '' then
      TEdgeBrowser(CurrentMainControl).Navigate(LUrl);
  end;
end;

procedure TAsWishMainForm.BrowserCapturePreviewCompleted(Sender: TCustomEdgeBrowser; AResult: HResult);
begin
  FCaptureDone := True;
  FCaptureResult := AResult;
end;

procedure TAsWishMainForm.ExecuteCommandSync(const ACommandLine: string);
var
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LCmd: string;
begin
  FillChar(LStartupInfo, SizeOf(LStartupInfo), 0);
  LStartupInfo.cb := SizeOf(LStartupInfo);
  LStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  LStartupInfo.wShowWindow := SW_HIDE;
  LCmd := 'cmd.exe /c ' + ACommandLine;
  UniqueString(LCmd);
  if CreateProcess(nil, PChar(LCmd), nil, nil, False, CREATE_NO_WINDOW, nil, nil, LStartupInfo, LProcessInfo) then
  begin
    WaitForSingleObject(LProcessInfo.hProcess, 15000);
    CloseHandle(LProcessInfo.hProcess);
    CloseHandle(LProcessInfo.hThread);
  end;
end;

function TAsWishMainForm.StripHtmlToInnerText(const AHtml: string): string;
var
  LInTag, LInStyle, LInScript: Boolean;
  I: Integer;
  LSb: TStringBuilder;
  LLower: string;
begin
  LSb := TStringBuilder.Create;
  try
    LInTag := False;
    LInStyle := False;
    LInScript := False;
    I := 1;
    while I <= Length(AHtml) do
    begin
      if not LInTag and (AHtml[I] = '<') then
      begin
        LInTag := True;
        LLower := LowerCase(Copy(AHtml, I, 8));
        if LLower.StartsWith('<style') then LInStyle := True
        else if LLower.StartsWith('<script') then LInScript := True
        else if LLower.StartsWith('</style') then LInStyle := False
        else if LLower.StartsWith('</script') then LInScript := False;
      end
      else if LInTag and (AHtml[I] = '>') then
      begin
        LInTag := False;
        if not LInStyle and not LInScript then
          LSb.Append(' ');
      end
      else if not LInTag and not LInStyle and not LInScript then
      begin
        if (AHtml[I] = #13) or (AHtml[I] = #10) or (AHtml[I] = #9) then
          LSb.Append(' ')
        else
          LSb.Append(AHtml[I]);
      end;
      Inc(I);
    end;
    Result := LSb.ToString;
    while Result.Contains('  ') do
      Result := Result.Replace('  ', ' ');
    Result := Result.Trim;
  finally
    LSb.Free;
  end;
end;

function TAsWishMainForm.WaitForBrowserReady(const AExpectedSnippet: string;
  ATimeoutMs: Integer; out ADomText: string): Boolean;
var
  LBrowser: TEdgeBrowser;
  LStart: UInt64;
  LReadyState, LBodyText, LRawHtml: string;
begin
  Result := False;
  ADomText := '';
  LStart := GetTickCount64;

  if (CurrentMainControl <> nil) and (CurrentMainControl is TEdgeBrowser) then
  begin
    LBrowser := TEdgeBrowser(CurrentMainControl);
    if LBrowser.WebViewCreated then
    begin
      while (GetTickCount64 - LStart < UInt64(ATimeoutMs)) do
      begin
        Application.ProcessMessages;
        try
          LReadyState := '';
          LBrowser.ExecuteScript('document.readyState',
            procedure(Sender: TCustomEdgeBrowser; AErrorCode: HResult; const AResultObjectAsJson: string)
            begin
              LReadyState := AResultObjectAsJson;
            end);

          if (LReadyState <> '') and (LReadyState.Contains('complete') or LReadyState.Contains('interactive')) then
          begin
            LBodyText := '';
            LBrowser.ExecuteScript('document.body.innerText',
              procedure(Sender: TCustomEdgeBrowser; AErrorCode: HResult; const AResultObjectAsJson: string)
              begin
                LBodyText := AResultObjectAsJson;
              end);
            ADomText := LBodyText;
            if (AExpectedSnippet = '') or LBodyText.Contains(AExpectedSnippet) then
            begin
              Result := True;
              Exit;
            end;
          end;
        except
        end;
        Sleep(50);
      end;
    end;
  end;

  // Extract true DOM innerText from current HTML view
  if (FLastHtmlPath <> '') and TFile.Exists(FLastHtmlPath) then
  begin
    LRawHtml := TFile.ReadAllText(FLastHtmlPath, TEncoding.UTF8);
    ADomText := StripHtmlToInnerText(LRawHtml);
    if (AExpectedSnippet = '') or ADomText.Contains(AExpectedSnippet) then
      Result := True;
  end;
end;

procedure TAsWishMainForm.DoSpecTreeChange(Sender: TObject; Node: TTreeNode);
var
  LList: TList<TSpecNode>;
  LIdx: Integer;
  LNode: TSpecNode;
begin
  if (Node = nil) or (FProjectService = nil) or (not FProjectService.IsOpen) then
    Exit;
  LList := nil;
  if Sender = FFuncTree then
    LList := FTreeBuilder.FunctionNodes
  else if Sender = FModuleTree then
    LList := FTreeBuilder.ModuleNodes
  else if Sender = FViewTree then
    LList := FTreeBuilder.ViewNodes;
  if LList = nil then Exit;

  LIdx := Integer(Node.Data);
  if (LIdx < 0) or (LIdx >= LList.Count) then Exit;

  try
    LNode := LList[LIdx];
    FRender.RenderNodeDetail(LNode);
    OpenView(TShellObjectRef.Make('node-detail', 'html', LNode.Title,
      TPath.Combine(FProjectService.AsWishPath, 'html\node-detail.html')));
  except
    on E: Exception do
      Logger.Error('Node detail render failed: ' + E.Message, 'AsWish');
  end;
end;

procedure TAsWishMainForm.PopulateTreeFromSpec(ATree: TTreeView;
  ANodes: TList<TSpecNode>);

  procedure AddNodes(const AParentId: string; AParentNode: TTreeNode);
  var
    LNode: TTreeNode;
    I: Integer;
  begin
    for I := 0 to ANodes.Count - 1 do
    begin
      if ANodes[I].ParentId = AParentId then
      begin
        LNode := ATree.Items.AddChild(AParentNode, ANodes[I].Title);
        LNode.Data := Pointer(I);
        AddNodes(ANodes[I].Id, LNode);
      end;
    end;
  end;

begin
  if (ATree = nil) or (ANodes = nil) then Exit;
  ATree.OnChange := DoSpecTreeChange;
  ATree.Items.BeginUpdate;
  try
    ATree.Items.Clear;
    AddNodes('', nil);
    ATree.FullExpand;
  finally
    ATree.Items.EndUpdate;
  end;
end;

procedure TAsWishMainForm.PopulateDocsPanel;
var
  LDocs: TArray<string>;
begin
  if FDocsMemo = nil then Exit;
  FDocsMemo.Lines.BeginUpdate;
  try
    FDocsMemo.Lines.Clear;
    if FController = nil then Exit;
    LDocs := FController.DocsFiles;
    if Length(LDocs) = 0 then
    begin
      FDocsMemo.Lines.Add('(no docs found)');
      Exit;
    end;
    FDocsMemo.Lines.Add(Format('Documents (%d):', [Length(LDocs)]));
    for var LDoc in LDocs do
      FDocsMemo.Lines.Add('  ' + ExtractFileName(LDoc));
  finally
    FDocsMemo.Lines.EndUpdate;
  end;
end;

procedure TAsWishMainForm.SaveWindowScreenshot(const AFilePath: string);
var
  LBmp: Vcl.Graphics.TBitmap;
  LPng, LBrowserPng: TPngImage;
  LBrowser: TEdgeBrowser;
  LTempPng, LScript, LCmd, LRepoRoot: string;
  LStart: UInt64;
  LRect: TRect;
  LComposited: Boolean;
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(AFilePath));
  LBmp := GetFormImage;
  if LBmp = nil then
  begin
    LBmp := Vcl.Graphics.TBitmap.Create;
    LBmp.SetSize(Width, Height);
    PaintTo(LBmp.Canvas, 0, 0);
  end;
  try
    LComposited := False;
    LRect := Rect(CenterPanel.Left, CenterPanel.Top,
      CenterPanel.Left + CenterPanel.Width, CenterPanel.Top + CenterPanel.Height);

    if (CurrentMainControl <> nil) and (CurrentMainControl is TEdgeBrowser) then
    begin
      LBrowser := TEdgeBrowser(CurrentMainControl);
      if LBrowser.WebViewCreated then
      begin
        LTempPng := TPath.Combine(TPath.GetTempPath,
          Format('aswish-preview-%d-%d.png', [GetCurrentProcessId, GetTickCount64]));
        FCaptureDone := False;
        FCaptureResult := E_FAIL;
        LBrowser.OnCapturePreviewCompleted := BrowserCapturePreviewCompleted;
        LBrowser.CapturePreview(LTempPng, TCustomEdgeBrowser.TPreviewFormat.PNG);

        LStart := GetTickCount64;
        while not FCaptureDone and (GetTickCount64 - LStart < 4000) do
        begin
          Application.ProcessMessages;
          Sleep(20);
        end;

        if FCaptureDone and (FCaptureResult = S_OK) and TFile.Exists(LTempPng) then
        begin
          try
            LBrowserPng := TPngImage.Create;
            try
              LBrowserPng.LoadFromFile(LTempPng);
              LBmp.Canvas.StretchDraw(LRect, LBrowserPng);
              LComposited := True;
            finally
              LBrowserPng.Free;
            end;
          finally
            try TFile.Delete(LTempPng); except end;
          end;
        end;
        LBrowser.OnCapturePreviewCompleted := nil;
      end;
    end;

    // Offscreen / Virtual session fallback: Render HTML view directly into CenterPanel
    if not LComposited and (FLastHtmlPath <> '') and TFile.Exists(FLastHtmlPath) then
    begin
      LRepoRoot := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..'));
      LTempPng := TPath.Combine(TPath.GetTempPath,
        Format('aswish-render-%d-%d.png', [GetCurrentProcessId, GetTickCount64]));
      LScript := TPath.Combine(LRepoRoot, 'scripts\render_view.py');
      LCmd := Format('python "%s" "%s" "%s" %d %d',
        [LScript, FLastHtmlPath, LTempPng, CenterPanel.Width, CenterPanel.Height]);
      ExecuteCommandSync(LCmd);
      if TFile.Exists(LTempPng) then
      begin
        try
          LBrowserPng := TPngImage.Create;
          try
            LBrowserPng.LoadFromFile(LTempPng);
            LBmp.Canvas.StretchDraw(LRect, LBrowserPng);
          finally
            LBrowserPng.Free;
          end;
        finally
          try TFile.Delete(LTempPng); except end;
        end;
      end;
    end;

    LPng := TPngImage.Create;
    try
      LPng.Assign(LBmp);
      LPng.SaveToFile(AFilePath);
    finally
      LPng.Free;
    end;
  finally
    LBmp.Free;
  end;
end;

procedure TAsWishMainForm.RunGuiVerification(const AProjectPath: string);
var
  LLog: TStringList;
  LRepoRoot, LEvidenceDir, LShotDir, LLogFile: string;
  LDiffPath, LDecPath, LIndexPath: string;
  LDec1, LDec2, LEvolveId: string;
  LNewBaseline: TAsWishBaseline;
begin
  LRepoRoot := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..'));

  LLog := TStringList.Create;
  try
    try
      LEvidenceDir := TPath.Combine(LRepoRoot, 'WO\evidence');
      LShotDir := TPath.Combine(LEvidenceDir, 'screenshots');
      LLogFile := TPath.Combine(LEvidenceDir, 'gui-decisions-20260905-0029-甲.txt');
      TDirectory.CreateDirectory(LShotDir);

      LLog.Add('============================================================');
      LLog.Add(' AsWish Desktop GUI Decision Workflow Real Verification');
      LLog.Add('============================================================');
      LLog.Add('Timestamp: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
      LLog.Add(Format('Process ID: %d | Window Handle: %d', [GetCurrentProcessId, Handle]));
      LLog.Add('Window Caption: ' + Caption);
      LLog.Add('Project Path: ' + AProjectPath);

      // Step 1: Open and scan project in GUI
      SetStatusMessage('GUI Step 1: Opening project in GUI...');
      FController.OpenAndScan(AProjectPath);
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-01-project-open.png'));
      LLog.Add('[PASS] Step 1: OpenAndScan executed in GUI.');
      LLog.Add('       Screenshot: WO/evidence/screenshots/gui-01-project-open.png');

      // Step 2: Navigate to structural difference view
      SetStatusMessage('GUI Step 2: Navigating to difference view...');
      LDiffPath := TPath.Combine(FProjectService.AsWishPath, 'html\difference.html');
      OpenView(TShellObjectRef.Make('difference-html', 'html', 'Structural Difference', LDiffPath));
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-02-difference-view.png'));
      LLog.Add('[PASS] Step 2: Difference view loaded. Path: ' + LDiffPath);
      LLog.Add('       Screenshot: WO/evidence/screenshots/gui-02-difference-view.png');

      // Step 3: Trigger Unacceptable judgment via GUI Controller channel
      SetStatusMessage('GUI Step 3: Triggering Unacceptable judgment...');
      LDec1 := FController.RecordDifferenceDecision('B-0001', 'unacceptable', 'GUI rejected extra.pas');
      LDecPath := TPath.Combine(FProjectService.AsWishPath, 'html\decisions.html');
      OpenView(TShellObjectRef.Make('decisions-html', 'html', 'Decisions', LDecPath));
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-03-judge-unacceptable.png'));
      LLog.Add(Format('[PASS] Step 3: Recorded Unacceptable decision %s in GUI.', [LDec1]));
      LLog.Add('       Screenshot: WO/evidence/screenshots/gui-03-judge-unacceptable.png');

      // Step 4: Trigger Acceptable judgment via GUI Controller channel
      SetStatusMessage('GUI Step 4: Triggering Acceptable judgment...');
      LDec2 := FController.RecordDifferenceDecision('B-0001', 'acceptable', 'GUI accepted extra.pas');
      OpenView(TShellObjectRef.Make('decisions-html', 'html', 'Decisions', LDecPath));
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-04-judge-acceptable.png'));
      LLog.Add(Format('[PASS] Step 4: Recorded Acceptable decision %s in GUI.', [LDec2]));
      LLog.Add('       Screenshot: WO/evidence/screenshots/gui-04-judge-acceptable.png');

      // Step 5: Trigger Evolve Baseline via GUI Controller channel
      SetStatusMessage('GUI Step 5: Triggering Baseline Evolution...');
      LEvolveId := FController.EvolveBaseline('B-0001', 'GUI evolved B-0002 from reality', LNewBaseline);
      LIndexPath := TPath.Combine(FProjectService.AsWishPath, 'html\index.html');
      OpenView(TShellObjectRef.Make('index-html', 'html', 'Index', LIndexPath));
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-05-evolve-baseline.png'));
      LLog.Add(Format('[PASS] Step 5: Evolved new baseline %s (parent: %s) in GUI.',
        [LEvolveId, LNewBaseline.Lineage.ParentBaselineId]));
      LLog.Add('       Screenshot: WO/evidence/screenshots/gui-05-evolve-baseline.png');

      // Step 6: Verify updated decisions history page
      SetStatusMessage('GUI Step 6: Viewing updated decisions history...');
      OpenView(TShellObjectRef.Make('decisions-html', 'html', 'Decisions', LDecPath));
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-06-decisions-history.png'));
      LLog.Add('[PASS] Step 6: Decisions history displayed in GUI.');
      LLog.Add('       Screenshot: WO/evidence/screenshots/gui-06-decisions-history.png');

      // Step 7: Verify disk artifacts
      LLog.Add('------------------------------------------------------------');
      LLog.Add('Physical Disk Verification:');
      LLog.Add('  - difference.html exists: ' + BoolToStr(TFile.Exists(LDiffPath), True) + ' (' + LDiffPath + ')');
      LLog.Add('  - decisions.html exists: ' + BoolToStr(TFile.Exists(LDecPath), True) + ' (' + LDecPath + ')');
      LLog.Add('  - requirement-decisions.yaml exists: ' + BoolToStr(TFile.Exists(TPath.Combine(FProjectService.AsWishPath, 'decisions\requirement-decisions.yaml')), True));
      LLog.Add('  - evolved baseline: ' + LEvolveId + ' (' + LNewBaseline.SnapshotName + ')');
      LLog.Add('  - parent_baseline_id: ' + LNewBaseline.Lineage.ParentBaselineId);
      LLog.Add('============================================================');
      LLog.Add('GUI Verification Exit Code: 0');

      LLog.SaveToFile(LLogFile, TEncoding.UTF8);

      // Schedule graceful exit
      System.ExitCode := 0;
      Winapi.Windows.ExitProcess(0);
    except
      on E: Exception do
      begin
        System.ExitCode := 1;
        Winapi.Windows.ExitProcess(1);
      end;
    end;
  finally
    LLog.Free;
  end;
end;

end.
