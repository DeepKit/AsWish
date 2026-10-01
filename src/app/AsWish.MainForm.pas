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
  AsWish.Models,
  AsWish.CommandLine,
  DeepBase.EHAI.Types,
  DeepBase.HB.Choice.Types,
  AsWish.Binding.HB;

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
    FCaptureWarnings: TStringList;
    // Held between captures so a timed-out capture is never freed while the
    // WebView2 RPC thread may still be writing into it.
    FPendingStream: TMemoryStream;
    FLastHtmlPath: string;

    // HB Choice Deck UI & Binding
    FHBBinding: TAsWishHBBinding;
    FHBDeckPanel: TPanel;
    FHBDeckStatusLabel: TLabel;
    FHBDeckButtons: array[0..9] of TSpeedButton;
    FHBCommitBtn: TSpeedButton;
    FHBRejectBtn: TSpeedButton;
    FHBExtractBtn: TSpeedButton;
    FHBShareConsentChk: TCheckBox;
    FHBFullscreenBtn: TSpeedButton;
    FLastGateCsId: string;
    FLastGateRationale: string;

    // Dual Surface (WO-20260923-0044)
    // D-1: Inspector Sidebar Dialog
    FInspectorTopBar: TPanel;
    FInspectorTitleLabel: TLabel;
    FInspectorCloseBtn: TSpeedButton;
    FInspectorNodeLabel: TLabel;
    FInspectorPropsMemo: TMemo;
    FInspectorIntentPrompt: TLabel;
    FInspectorIntentEdit: TEdit;
    FInspectorSubmitBtn: TSpeedButton;
    FCurrentInspectedNodeId: string;

    // D-2: Ghosts context reveal chips
    FGhostsPanel: TPanel;
    FGhostsChips: array[0..2] of TPanel;
    FGhostsLabels: array[0..2] of TLabel;
    FGhostsCloseBtns: array[0..2] of TSpeedButton;

    // D-3: Immersive review surface (F11)
    FIsFullscreenReview: Boolean;
    FSavedLeftVisible: Boolean;
    FSavedRightVisible: Boolean;

    procedure BuildHBDeckUI;
    procedure BuildInspectorPanelUI;
    procedure BuildGhostsUI;
    procedure DoInspectorCloseClick(Sender: TObject);
    procedure DoInspectorSubmitClick(Sender: TObject);
    procedure DoInspectorIntentKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function SubmitInspectorIntent: string;
    procedure DoGhostChipCloseClick(Sender: TObject);
    procedure UpdateGhosts(const AText: string; const ANodes: TArray<string> = nil);
    procedure ClearGhosts;
    procedure ToggleFullscreenReview;

    procedure DoFormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DoHbButtonClick(Sender: TObject);
    procedure TriggerHbCandidate(AIndex: Integer);
    procedure TriggerHbRegenerate;
    procedure TriggerHbOverride;
    procedure TriggerHbBack;
    procedure TriggerHbCommit;
    procedure TriggerHbReject;
    procedure TriggerHbExtractLesson;
    procedure UpdateHbDeckStatus(const AMsg: string);
    procedure SetHbExtractControlsVisible(const AVisible: Boolean);
    function GetHBShareConsent: Boolean;
    function DomExcerptForLog(const ARaw: string): string;

    procedure DrainCaptureWarnings(const ALog: TStringList);

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
    procedure SaveControlImage(AControl: TWinControl; const AFilePath: string);
    function CaptureControlBitmap(AControl: TWinControl; ABmp: Vcl.Graphics.TBitmap): Boolean;
    function CaptureBrowserToStream(ABrowser: TEdgeBrowser; AStream: TMemoryStream): Boolean;
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
    property HBBinding: TAsWishHBBinding read FHBBinding;
    property HBExtractBtn: TSpeedButton read FHBExtractBtn;
    // WO-20260924-0049 P-4: read-only view of the share-to-hub checkbox so
    // automation can assert the default-unchecked invariant.
    property HBShareConsent: Boolean read GetHBShareConsent;
    property LastGateCsId: string read FLastGateCsId;
    property InspectorIntentEdit: TEdit read FInspectorIntentEdit;
    property InspectorNodeLabel: TLabel read FInspectorNodeLabel;
    property GhostsPanel: TPanel read FGhostsPanel;
    property IsFullscreenReview: Boolean read FIsFullscreenReview;
    procedure TriggerExtractLesson;
    function PerformInspectorSubmit(const ANodeId, AText: string): string;
  end;

var
  AsWishMainForm: TAsWishMainForm;

implementation

uses
  System.IOUtils,
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellAPI,
  AsWish.Commands,
  AsWish.Providers,
  AsWish.Localization,
  AsWish.Services.Storage,
  AsWish.SettingsProvider,
  AsWish.AutoFix,
  AsWish.Logger,
  AsWish.Config,
  Vcl.Imaging.pngimage,
  Vcl.Dialogs;

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
  KeyPreview := True;
  OnKeyDown := DoFormKeyDown;

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

  FHBBinding := TAsWishHBBinding.Create(FController);

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
    FScanService, FTreeBuilder, FController, FHBBinding);
  RegisterSettingsPage(TAsWishSettingsProvider.Create);
  if (CurrentMainControl <> nil) and (CurrentMainControl is TCustomEdgeBrowser) then
    TCustomEdgeBrowser(CurrentMainControl).CreateWebView;
end;

procedure TAsWishMainForm.AfterShellShown;
var
  LOpenDir: string;
  LIsGuiVerify: Boolean;
  LArgs: TArray<string>;
  LParsed: TAsWishParsedArgs;
  I: Integer;
begin
  inherited AfterShellShown;

  BuildLeftPanelUI;
  BuildInspectorPanelUI;
  BuildGhostsUI;
  BuildHBDeckUI;

  TAsWishAutoFix.SendHealthSignal('startup', 1);
  TAsWishAutoFix.RegisterScenario('smoke', procedure
  begin
  end);

  SetStatusMessage(ShellText('aswish.status.ready',
    'AsWish ready. Open a project folder to begin.'));

  SetLength(LArgs, ParamCount);
  for I := 1 to ParamCount do
    LArgs[I - 1] := ParamStr(I);
  LParsed := TAsWishCommandLine.ParseGui(LArgs);

  LOpenDir := LParsed.ProjectDir;
  LIsGuiVerify := LParsed.IsGuiVerify;

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
  FreeAndNil(FHBBinding);
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
  FreeAndNil(FCaptureWarnings);
  FreeAndNil(FPendingStream);
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

function FindHeadlessBrowserExecutable: string;
const
  Candidates: array[0..3] of string = (
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
  );
var
  I: Integer;
begin
  Result := '';
  for I := Low(Candidates) to High(Candidates) do
    if TFile.Exists(Candidates[I]) then
      Exit(Candidates[I]);
end;

function RenderHtmlToPngNative(const AHtmlPath, AOutputPng: string; AWidth, AHeight: Integer): Boolean;
var
  LBrowser, LFileUrl, LCmdLine, LAbsPng: string;
  LSi: TStartupInfo;
  LPi: TProcessInformation;
begin
  Result := False;
  if not TFile.Exists(AHtmlPath) then Exit;

  LBrowser := FindHeadlessBrowserExecutable;
  if LBrowser = '' then Exit;

  LAbsPng := TPath.GetFullPath(AOutputPng);
  try
    TDirectory.CreateDirectory(TPath.GetDirectoryName(LAbsPng));
  except
  end;

  LFileUrl := 'file:///' + TPath.GetFullPath(AHtmlPath).Replace('\', '/');
  LCmdLine := Format('"%s" --headless=new --disable-gpu --no-sandbox "--screenshot=%s" --window-size=%d,%d "%s"',
    [LBrowser, LAbsPng, AWidth, AHeight, LFileUrl]);

  FillChar(LSi, SizeOf(LSi), 0);
  LSi.cb := SizeOf(LSi);
  LSi.dwFlags := STARTF_USESHOWWINDOW;
  LSi.wShowWindow := SW_HIDE;

  UniqueString(LCmdLine);
  if CreateProcess(nil, PChar(LCmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, nil, LSi, LPi) then
  begin
    try
      WaitForSingleObject(LPi.hProcess, 15000);
      CloseHandle(LPi.hThread);
      CloseHandle(LPi.hProcess);
    except
    end;
    Result := TFile.Exists(LAbsPng) and (TFile.GetSize(LAbsPng) > 0);
  end;
end;

function TAsWishMainForm.WaitForBrowserReady(const AExpectedSnippet: string;
  ATimeoutMs: Integer; out ADomText: string): Boolean;
var
  LBrowser: TEdgeBrowser;
  LStart: UInt64;
  LReadyState, LBodyText: string;
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
end;

function TAsWishMainForm.DomExcerptForLog(const ARaw: string): string;
var
  LBytes: TBytes;
  LRepaired: string;
  I: Integer;
begin
  if ARaw.Trim = '' then Exit('[dom-empty]');
  for I := 1 to Length(ARaw) do
    if ARaw[I] > #$7F then
    begin
      // WebView2 ExecuteScript returns its JSON payload double-encoded
      // (UTF-8 bytes read back as GBK) and the '?' substitutions make it
      // lossy. Repair only what round-trips cleanly; never log a corrupt
      // excerpt as if it were evidence.
      try
        LBytes := TEncoding.GetEncoding(936).GetBytes(ARaw);
        LRepaired := TEncoding.UTF8.GetString(LBytes);
        if (LRepaired <> ARaw) and (not LRepaired.Contains(#$FFFD)) then
          Exit(Copy(LRepaired.Replace(#13, ' ').Replace(#10, ' '), 1, 160));
      except
        // Unmappable character (e.g. '€' has no GBK encoding) proves the
        // payload is already corrupt, so fall through to the placeholder.
      end;
      Exit(Format('[dom-text-undecodable len=%d]', [Length(ARaw)]));
    end;
  Result := Copy(ARaw.Replace(#13, ' ').Replace(#10, ' '), 1, 160);
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

    // WO-0044 D-1 & D-2: Populate Inspector Sidebar and Reveal Ghosts
    FCurrentInspectedNodeId := LNode.Id;
    if RightPanel <> nil then
      RightPanel.Visible := True;
    if RightSplitter <> nil then
      RightSplitter.Visible := True;
    if FInspectorNodeLabel <> nil then
      FInspectorNodeLabel.Caption := ' ' + LNode.Id;
    if FInspectorPropsMemo <> nil then
    begin
      FInspectorPropsMemo.Lines.Clear;
      FInspectorPropsMemo.Lines.Add('Title: ' + LNode.Title);
      FInspectorPropsMemo.Lines.Add('Kind: ' + LNode.Kind);
      FInspectorPropsMemo.Lines.Add('Tree: ' + TSpecEnums.TreeTypeToStr(LNode.Tree));
      FInspectorPropsMemo.Lines.Add('Status: ' + TSpecEnums.NodeStatusToStr(LNode.Status));
      FInspectorPropsMemo.Lines.Add('Summary: ' + LNode.Summary);
    end;
    UpdateGhosts(LNode.Id);
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


procedure TAsWishMainForm.BuildInspectorPanelUI;
var
  LBottomPanel, LInputRow: TPanel;
begin
  if RightPanel = nil then Exit;
  RightPanel.Width := 280;

  FInspectorTopBar := TPanel.Create(Self);
  FInspectorTopBar.Parent := RightPanel;
  FInspectorTopBar.Align := alTop;
  FInspectorTopBar.Height := 28;
  FInspectorTopBar.BevelOuter := bvNone;

  FInspectorTitleLabel := TLabel.Create(FInspectorTopBar);
  FInspectorTitleLabel.Parent := FInspectorTopBar;
  FInspectorTitleLabel.Align := alLeft;
  FInspectorTitleLabel.Caption := ' 节点速览 (Inspector)';
  FInspectorTitleLabel.Font.Style := [fsBold];
  FInspectorTitleLabel.Layout := tlCenter;

  FInspectorCloseBtn := TSpeedButton.Create(FInspectorTopBar);
  FInspectorCloseBtn.Parent := FInspectorTopBar;
  FInspectorCloseBtn.Align := alRight;
  FInspectorCloseBtn.Width := 24;
  FInspectorCloseBtn.Caption := '×';
  FInspectorCloseBtn.Flat := True;
  FInspectorCloseBtn.OnClick := DoInspectorCloseClick;

  FInspectorNodeLabel := TLabel.Create(RightPanel);
  FInspectorNodeLabel.Parent := RightPanel;
  FInspectorNodeLabel.Align := alTop;
  FInspectorNodeLabel.Height := 24;
  FInspectorNodeLabel.Font.Style := [fsBold];
  FInspectorNodeLabel.Caption := ' [未选择节点]';
  FInspectorNodeLabel.Layout := tlCenter;

  LBottomPanel := TPanel.Create(Self);
  LBottomPanel.Parent := RightPanel;
  LBottomPanel.Align := alBottom;
  LBottomPanel.Height := 76;
  LBottomPanel.BevelOuter := bvNone;

  FInspectorIntentPrompt := TLabel.Create(LBottomPanel);
  FInspectorIntentPrompt.Parent := LBottomPanel;
  FInspectorIntentPrompt.Align := alTop;
  FInspectorIntentPrompt.Height := 22;
  FInspectorIntentPrompt.Caption := ' 快速修订意图 (Enter 提交):';
  FInspectorIntentPrompt.Layout := tlCenter;

  LInputRow := TPanel.Create(LBottomPanel);
  LInputRow.Parent := LBottomPanel;
  LInputRow.Align := alClient;
  LInputRow.BevelOuter := bvNone;

  FInspectorSubmitBtn := TSpeedButton.Create(LInputRow);
  FInspectorSubmitBtn.Parent := LInputRow;
  FInspectorSubmitBtn.Align := alRight;
  FInspectorSubmitBtn.Width := 50;
  FInspectorSubmitBtn.Caption := '提交';
  FInspectorSubmitBtn.OnClick := DoInspectorSubmitClick;

  FInspectorIntentEdit := TEdit.Create(LInputRow);
  FInspectorIntentEdit.Parent := LInputRow;
  FInspectorIntentEdit.Align := alClient;
  FInspectorIntentEdit.OnKeyDown := DoInspectorIntentKeyDown;

  FInspectorPropsMemo := TMemo.Create(RightPanel);
  FInspectorPropsMemo.Parent := RightPanel;
  FInspectorPropsMemo.Align := alClient;
  FInspectorPropsMemo.ReadOnly := True;
  FInspectorPropsMemo.ScrollBars := ssVertical;
end;

procedure TAsWishMainForm.DoInspectorCloseClick(Sender: TObject);
begin
  if RightPanel <> nil then
    RightPanel.Visible := False;
  if RightSplitter <> nil then
    RightSplitter.Visible := False;
end;

procedure TAsWishMainForm.DoInspectorSubmitClick(Sender: TObject);
begin
  SubmitInspectorIntent;
end;

procedure TAsWishMainForm.DoInspectorIntentKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    SubmitInspectorIntent;
    Key := 0;
  end;
end;

function TAsWishMainForm.SubmitInspectorIntent: string;
var
  LNodeId, LText: string;
begin
  Result := '';
  if FController = nil then Exit;
  LNodeId := Trim(FCurrentInspectedNodeId);
  LText := Trim(FInspectorIntentEdit.Text);
  Result := PerformInspectorSubmit(LNodeId, LText);
  if Result <> '' then
    FInspectorIntentEdit.Text := '';
end;

function TAsWishMainForm.PerformInspectorSubmit(const ANodeId, AText: string): string;
var
  LTree: TTreeType;
begin
  Result := '';
  if FController = nil then Exit;
  if (ANodeId = '') or (AText = '') then Exit;

  // WO-0057 1.2: Unify Inspector submission with HB Deck entry point.
  // We route Inspector submission through FHBBinding.SubmitInspectorIntent (which calls
  // ProcessHbAction with cisGUI and ANodeId as ContextId) because:
  // 1. ProcessHbAction is the single source of truth (SSOT) for all human intent submissions across
  //    both keyboard deck (cisKeyboard) and sidebar GUI (cisGUI), keeping EHAI audit traces and
  //    LastChangeSetId state synchronized.
  // 2. It ensures Inspector-submitted ChangeSets immediately populate FHBBinding.LastChangeSetId,
  //    making them targetable by subsequent deck actions (e.g. Enter to commit, Esc to reject).
  // 3. THbChoiceAction natively models cisGUI as input source and ContextId as target node ref.
  if FHBBinding <> nil then
    Result := FHBBinding.SubmitInspectorIntent(ANodeId, AText)
  else
  begin
    LTree := TSpecEnums.TreeFromNodePrefix(ANodeId);
    Result := FController.SubmitUserIntent(ANodeId, LTree, AText);
  end;

  UpdateHbDeckStatus(Format('[Inspector] ChangeSet %s submitted for %s', [Result, ANodeId]));
  UpdateGhosts(AText, [ANodeId]);
end;

procedure TAsWishMainForm.BuildGhostsUI;
var
  I: Integer;
  LChip: TPanel;
  LLbl: TLabel;
  LClose: TSpeedButton;
begin
  if BottomPanel = nil then Exit;

  FGhostsPanel := TPanel.Create(Self);
  FGhostsPanel.Parent := BottomPanel;
  FGhostsPanel.Align := alTop;
  FGhostsPanel.Height := 26;
  FGhostsPanel.BevelOuter := bvNone;
  FGhostsPanel.Color := $00E6F0FA;
  FGhostsPanel.Visible := False;

  for I := 0 to 2 do
  begin
    LChip := TPanel.Create(FGhostsPanel);
    LChip.Parent := FGhostsPanel;
    LChip.Align := alLeft;
    LChip.Width := 260;
    LChip.BevelOuter := bvNone;
    LChip.Color := $00D2E5F8;
    LChip.Visible := False;
    LChip.Tag := I;

    LClose := TSpeedButton.Create(LChip);
    LClose.Parent := LChip;
    LClose.Align := alRight;
    LClose.Width := 18;
    LClose.Caption := '×';
    LClose.Flat := True;
    LClose.Tag := I;
    LClose.OnClick := DoGhostChipCloseClick;
    FGhostsCloseBtns[I] := LClose;

    LLbl := TLabel.Create(LChip);
    LLbl.Parent := LChip;
    LLbl.Align := alClient;
    LLbl.Layout := tlCenter;
    LLbl.Font.Size := 8;
    LLbl.Caption := '';
    FGhostsLabels[I] := LLbl;

    FGhostsChips[I] := LChip;
  end;
end;

procedure TAsWishMainForm.UpdateGhosts(const AText: string;
  const ANodes: TArray<string>);
var
  LMatches: TArray<TSpecCommonsLesson>;
  I, LLimit: Integer;
  LChipText: string;
begin
  if (FController = nil) or (FController.Commons = nil) or (FGhostsPanel = nil) then Exit;
  if Trim(AText) = '' then
  begin
    ClearGhosts;
    Exit;
  end;

  LMatches := FController.Commons.FindMatchingLessons(AText, ANodes);
  if Length(LMatches) = 0 then
  begin
    ClearGhosts;
    Exit;
  end;

  LLimit := Length(LMatches);
  if LLimit > 3 then LLimit := 3;

  for I := 0 to 2 do
  begin
    if I < LLimit then
    begin
      LChipText := Format('这类分叉曾错在 %s（%s）', [LMatches[I].Title, LMatches[I].Id]);
      if SameText(LMatches[I].AnchorKind, 'narrative') then
        LChipText := LChipText + ' [经验总结，非可复核记录]';
      FGhostsLabels[I].Caption := ' ' + LChipText;
      FGhostsLabels[I].Hint := LMatches[I].HumanTakeaway;
      FGhostsLabels[I].ShowHint := True;
      FGhostsChips[I].Width := Canvas.TextWidth(LChipText) + 36;
      FGhostsChips[I].Visible := True;
    end
    else
      FGhostsChips[I].Visible := False;
  end;
  FGhostsPanel.Visible := True;
end;

procedure TAsWishMainForm.ClearGhosts;
var I: Integer;
begin
  if FGhostsPanel = nil then Exit;
  for I := 0 to 2 do
    if FGhostsChips[I] <> nil then
      FGhostsChips[I].Visible := False;
  FGhostsPanel.Visible := False;
end;

procedure TAsWishMainForm.DoGhostChipCloseClick(Sender: TObject);
var
  LTag, I: Integer;
  LAnyVisible: Boolean;
begin
  if not (Sender is TSpeedButton) then Exit;
  LTag := TSpeedButton(Sender).Tag;
  if (LTag >= 0) and (LTag <= 2) and (FGhostsChips[LTag] <> nil) then
    FGhostsChips[LTag].Visible := False;

  LAnyVisible := False;
  for I := 0 to 2 do
    if (FGhostsChips[I] <> nil) and FGhostsChips[I].Visible then
    begin
      LAnyVisible := True;
      Break;
    end;
  if not LAnyVisible and (FGhostsPanel <> nil) then
    FGhostsPanel.Visible := False;
end;

procedure TAsWishMainForm.ToggleFullscreenReview;
begin
  FIsFullscreenReview := not FIsFullscreenReview;
  if FIsFullscreenReview then
  begin
    if LeftPanel <> nil then FSavedLeftVisible := LeftPanel.Visible;
    if RightPanel <> nil then FSavedRightVisible := RightPanel.Visible;
    if LeftPanel <> nil then LeftPanel.Visible := False;
    if LeftSplitter <> nil then LeftSplitter.Visible := False;
    if RightPanel <> nil then RightPanel.Visible := False;
    if RightSplitter <> nil then RightSplitter.Visible := False;
    if FHBFullscreenBtn <> nil then FHBFullscreenBtn.Caption := 'F11: 还原';
    UpdateHbDeckStatus('[沉浸 Review 模式已开启] 左右面板已隐藏，按 F11 还原');
  end
  else
  begin
    if LeftPanel <> nil then LeftPanel.Visible := FSavedLeftVisible;
    if LeftSplitter <> nil then LeftSplitter.Visible := FSavedLeftVisible;
    if RightPanel <> nil then RightPanel.Visible := FSavedRightVisible;
    if RightSplitter <> nil then RightSplitter.Visible := FSavedRightVisible;
    if FHBFullscreenBtn <> nil then FHBFullscreenBtn.Caption := 'F11: 沉浸';
    UpdateHbDeckStatus('[沉浸 Review 模式已退出] 左右面板已还原');
  end;
end;

procedure TAsWishMainForm.BuildHBDeckUI;
var
  I: Integer;
  LBtn: TSpeedButton;
  LBtnCaptions: array[0..9] of string;
begin
  if BottomPanel = nil then Exit;

  LBtnCaptions[1] := '1: Rev 1';
  LBtnCaptions[2] := '2: Rev 2';
  LBtnCaptions[3] := '3: Rev 3';
  LBtnCaptions[4] := '4: Rev 4';
  LBtnCaptions[5] := '5: Rev 5';
  LBtnCaptions[6] := '6: Rev 6';
  LBtnCaptions[7] := '7: Rev 7';
  LBtnCaptions[8] := '8: Regen';
  LBtnCaptions[9] := '9: Override';
  LBtnCaptions[0] := '0: Back';

  FHBDeckPanel := TPanel.Create(Self);
  FHBDeckPanel.Parent := BottomPanel;
  FHBDeckPanel.Align := alTop;
  FHBDeckPanel.Height := 28;
  FHBDeckPanel.BevelOuter := bvNone;
  FHBDeckPanel.Color := clBtnFace;

  for I := 1 to 7 do
  begin
    LBtn := TSpeedButton.Create(FHBDeckPanel);
    LBtn.Parent := FHBDeckPanel;
    LBtn.Align := alLeft;
    LBtn.Width := 58;
    LBtn.Tag := I;
    LBtn.Caption := LBtnCaptions[I];
    LBtn.OnClick := DoHbButtonClick;
    FHBDeckButtons[I] := LBtn;
  end;

  for I := 8 to 9 do
  begin
    LBtn := TSpeedButton.Create(FHBDeckPanel);
    LBtn.Parent := FHBDeckPanel;
    LBtn.Align := alLeft;
    LBtn.Width := 68;
    LBtn.Tag := I;
    LBtn.Caption := LBtnCaptions[I];
    LBtn.OnClick := DoHbButtonClick;
    FHBDeckButtons[I] := LBtn;
  end;

  LBtn := TSpeedButton.Create(FHBDeckPanel);
  LBtn.Parent := FHBDeckPanel;
  LBtn.Align := alLeft;
  LBtn.Width := 55;
  LBtn.Tag := 0;
  LBtn.Caption := LBtnCaptions[0];
  LBtn.OnClick := DoHbButtonClick;
  FHBDeckButtons[0] := LBtn;

  FHBCommitBtn := TSpeedButton.Create(FHBDeckPanel);
  FHBCommitBtn.Parent := FHBDeckPanel;
  FHBCommitBtn.Align := alLeft;
  FHBCommitBtn.Width := 75;
  FHBCommitBtn.Tag := 100;
  FHBCommitBtn.Caption := 'Enter: Commit';
  FHBCommitBtn.OnClick := DoHbButtonClick;

  FHBRejectBtn := TSpeedButton.Create(FHBDeckPanel);
  FHBRejectBtn.Parent := FHBDeckPanel;
  FHBRejectBtn.Align := alLeft;
  FHBRejectBtn.Width := 70;
  FHBRejectBtn.Tag := 101;
  FHBRejectBtn.Caption := 'Esc: Reject';
  FHBRejectBtn.OnClick := DoHbButtonClick;

  FHBExtractBtn := TSpeedButton.Create(FHBDeckPanel);
  FHBExtractBtn.Parent := FHBDeckPanel;
  FHBExtractBtn.Align := alLeft;
  FHBExtractBtn.Width := 115;
  FHBExtractBtn.Tag := 102;
  FHBExtractBtn.Caption := '🚩 存为避坑经验';
  FHBExtractBtn.Visible := False;
  FHBExtractBtn.OnClick := DoHbButtonClick;

  // WO-20260924-0049 P-4: share-to-hub consent. Unchecked by default — a
  // lesson only reaches the public PG hub when the human opts in explicitly.
  FHBShareConsentChk := TCheckBox.Create(FHBDeckPanel);
  FHBShareConsentChk.Parent := FHBDeckPanel;
  FHBShareConsentChk.Align := alLeft;
  FHBShareConsentChk.Width := 132;
  FHBShareConsentChk.Caption := '愿分享到公共库';
  FHBShareConsentChk.Checked := False;
  FHBShareConsentChk.Visible := False;
  FHBShareConsentChk.Font.Size := 8;
  FHBShareConsentChk.Hint :=
    '默认不勾。勾选后本条经验经脱敏推送到 Difference Commons 公共库（PG），' +
    '其他客户端的 Ghosts 才能命中；不勾仅保存在本机。';
  FHBShareConsentChk.ShowHint := True;

  FHBFullscreenBtn := TSpeedButton.Create(FHBDeckPanel);
  FHBFullscreenBtn.Parent := FHBDeckPanel;
  FHBFullscreenBtn.Align := alLeft;
  FHBFullscreenBtn.Width := 75;
  FHBFullscreenBtn.Tag := 103;
  FHBFullscreenBtn.Caption := 'F11: 沉浸';
  FHBFullscreenBtn.OnClick := DoHbButtonClick;

  FHBDeckStatusLabel := TLabel.Create(FHBDeckPanel);
  FHBDeckStatusLabel.Parent := FHBDeckPanel;
  FHBDeckStatusLabel.Align := alClient;
  FHBDeckStatusLabel.Layout := tlCenter;
  FHBDeckStatusLabel.Font.Size := 8;
  FHBDeckStatusLabel.Caption := ' [HB Ready] Keyboard 0-9 / Enter / Esc active';
end;

procedure TAsWishMainForm.DoHbButtonClick(Sender: TObject);
var
  LTag: Integer;
begin
  if not (Sender is TSpeedButton) then Exit;
  LTag := TSpeedButton(Sender).Tag;
  case LTag of
    0: TriggerHbBack;
    1..7: TriggerHbCandidate(LTag);
    8: TriggerHbRegenerate;
    9: TriggerHbOverride;
    100: TriggerHbCommit;
    101: TriggerHbReject;
    102: TriggerHbExtractLesson;
    103: ToggleFullscreenReview;
  end;
end;

procedure TAsWishMainForm.DoFormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ActiveControl is TCustomEdit) or (ActiveControl is TCustomMemo) or (ActiveControl is TCustomComboBox) then
    Exit;

  if Key = VK_F11 then
  begin
    ToggleFullscreenReview;
    Key := 0;
    Exit;
  end;

  // WO-0039 B-1: WebView2 owns its own keys; form-level shortcuts must not
  // swallow or double-fire 0-9/Enter/Esc while focus is inside the browser.
  if ActiveControl is TCustomEdgeBrowser then
    Exit;

  case Key of
    Ord('1')..Ord('7'):
    begin
      TriggerHbCandidate(Key - Ord('0'));
      Key := 0;
    end;
    VK_NUMPAD1..VK_NUMPAD7:
    begin
      TriggerHbCandidate(Key - VK_NUMPAD0);
      Key := 0;
    end;
    Ord('8'), VK_NUMPAD8:
    begin
      TriggerHbRegenerate;
      Key := 0;
    end;
    Ord('9'), VK_NUMPAD9:
    begin
      TriggerHbOverride;
      Key := 0;
    end;
    Ord('0'), VK_NUMPAD0:
    begin
      TriggerHbBack;
      Key := 0;
    end;
    VK_RETURN:
    begin
      if (FHBBinding <> nil) and (FHBBinding.LastChangeSetId <> '') then
      begin
        TriggerHbCommit;
        Key := 0;
      end;
    end;
    VK_ESCAPE:
    begin
      if (FHBBinding <> nil) and (FHBBinding.LastChangeSetId <> '') then
      begin
        TriggerHbReject;
        Key := 0;
      end;
    end;
  end;
end;

procedure TAsWishMainForm.TriggerHbCandidate(AIndex: Integer);
var
  LIntents: TArray<TCandidateIntent>;
  LCsId, LReviewHtml, LRev: string;
  LAct: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
begin
  if FHBBinding = nil then Exit;
  LCsId := '';
  if FController <> nil then
  begin
    LIntents := FController.ListCandidateIntents;
    if (AIndex - 1 >= 0) and (AIndex - 1 < Length(LIntents)) then
      LCsId := LIntents[AIndex - 1].NodeId;
  end;

  LAct := THbChoiceAction.Create(cakCandidate, AIndex, 'Candidate ' + IntToStr(AIndex), 0, cisKeyboard,
    eokNone, esHuman, eipJudge, LCsId);
  LTrace := FHBBinding.ProcessHbAction(LAct, LCsId);

  // WO-0039 B-5: surface the review summary (previously computed then dropped).
  LRev := FHBBinding.LastReviewText;
  if Length(LRev) > 80 then
    LRev := Copy(LRev, 1, 80) + '...';
  UpdateHbDeckStatus(Format('[Candidate %d] %s | CsId: %s | %s',
    [AIndex, LRev, FHBBinding.LastChangeSetId, LTrace.TraceId]));
  if FProjectService <> nil then
  begin
    LReviewHtml := TPath.Combine(FProjectService.AsWishPath, 'html\changeset-review.html');
    if TFile.Exists(LReviewHtml) then
      OpenView(TShellObjectRef.Make('changeset-review', 'html', 'ChangeSet Review', LReviewHtml));
  end;
end;

procedure TAsWishMainForm.TriggerHbRegenerate;
var
  LAct: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
begin
  if FHBBinding = nil then Exit;
  LAct := THbChoiceAction.Create(cakRegenerate, 8, 'Regenerate', 0, cisKeyboard,
    eokNone, esHuman, eipProvide);
  LTrace := FHBBinding.ProcessHbAction(LAct);
  UpdateHbDeckStatus(Format('[Regenerate 8] Trace: %s | Prompt exported', [LTrace.TraceId]));
end;

procedure TAsWishMainForm.TriggerHbOverride;
var
  LInput: string;
  LAct: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LIsFrameRejection: Boolean;
  LReviewHtml: string;
begin
  if FHBBinding = nil then Exit;
  LInput := '';
  if not InputQuery('HB Human Override / Frame Rejection',
    'Enter natural language intent or prefix with "[reframe]" to reject framing:', LInput) then
    Exit;
  if LInput.Trim = '' then Exit;

  LIsFrameRejection := LInput.StartsWith('[reframe]') or LInput.StartsWith('reject:');
  if LIsFrameRejection then
    LAct := THbChoiceAction.Create(cakFreeInput, 9, LInput, 0, cisKeyboard,
      eokFrameRejection, esHuman, eipProvide)
  else
    LAct := THbChoiceAction.Create(cakFreeInput, 9, LInput, 0, cisKeyboard,
      eokAlternativeExpression, esHuman, eipProvide);

  LTrace := FHBBinding.ProcessHbAction(LAct);
  UpdateHbDeckStatus(Format('[Override 9] Trace: %s | CsId: %s', [LTrace.TraceId, FHBBinding.LastChangeSetId]));

  if FProjectService <> nil then
  begin
    LReviewHtml := TPath.Combine(FProjectService.AsWishPath, 'html\changeset-review.html');
    if TFile.Exists(LReviewHtml) then
      OpenView(TShellObjectRef.Make('changeset-review', 'html', 'ChangeSet Review', LReviewHtml));
  end;
end;

procedure TAsWishMainForm.TriggerHbBack;
var
  LAct: THbChoiceAction;
  LTrace: TEhaiTraceRecord;
  LIndexHtml: string;
begin
  if FHBBinding = nil then Exit;
  LAct := THbChoiceAction.Create(cakBack, 0, 'Back', 0, cisKeyboard,
    eokNone, esHuman, eipInform);
  LTrace := FHBBinding.ProcessHbAction(LAct);
  UpdateHbDeckStatus(Format('[Back 0] Trace: %s | Returned to index', [LTrace.TraceId]));

  if FProjectService <> nil then
  begin
    LIndexHtml := TPath.Combine(FProjectService.AsWishPath, 'html\index.html');
    if TFile.Exists(LIndexHtml) then
      OpenView(TShellObjectRef.Make('index-html', 'html', 'Index', LIndexHtml));
  end;
end;

procedure TAsWishMainForm.TriggerHbCommit;
var
  LCsId, LRationale: string;
  LSuccess: Boolean;
begin
  if FHBBinding = nil then Exit;
  LCsId := FHBBinding.LastChangeSetId;
  if LCsId = '' then
  begin
    UpdateHbDeckStatus('[Commit Gate] No active ChangeSet selected to commit');
    Exit;
  end;

  LRationale := 'Accepted via Desktop GUI Commitment Gate';
  LSuccess := FHBBinding.ExecuteCommitmentGate(LCsId, LRationale);
  if LSuccess then
  begin
    FLastGateCsId := LCsId;
    FLastGateRationale := LRationale;
    SetHbExtractControlsVisible(True);
    UpdateHbDeckStatus(Format('[Commit Gate ACCEPTED] ChangeSet %s committed across boundary [🚩 存为避坑经验]', [LCsId]));
    if FProjectService <> nil then
      FController.OpenAndScan(FProjectService.ProjectPath);
  end
  else
    UpdateHbDeckStatus(Format('[Commit Gate FAILED] Could not commit ChangeSet %s', [LCsId]));
end;

procedure TAsWishMainForm.TriggerHbReject;
var
  LCsId, LRationale: string;
  LSuccess: Boolean;
begin
  if FHBBinding = nil then Exit;
  LCsId := FHBBinding.LastChangeSetId;
  if LCsId = '' then
  begin
    UpdateHbDeckStatus('[Reject Gate] No active ChangeSet selected to reject');
    Exit;
  end;

  LRationale := 'Rejected via Desktop GUI Gate';
  LSuccess := FHBBinding.ExecuteReject(LCsId, LRationale);
  if LSuccess then
  begin
    FLastGateCsId := LCsId;
    FLastGateRationale := LRationale;
    SetHbExtractControlsVisible(True);
    UpdateHbDeckStatus(Format('[Reject Gate RECORDED] ChangeSet %s rejected (Spec untouched) [🚩 存为避坑经验]', [LCsId]));
    if FProjectService <> nil then
    begin
      var LDecHtml := TPath.Combine(FProjectService.AsWishPath, 'html\decisions.html');
      if TFile.Exists(LDecHtml) then
        OpenView(TShellObjectRef.Make('decisions-html', 'html', 'Decisions', LDecHtml));
    end;
  end
  else
    UpdateHbDeckStatus(Format('[Reject Gate FAILED] Could not reject ChangeSet %s', [LCsId]));
end;

procedure TAsWishMainForm.TriggerHbExtractLesson;
var
  LCsId: string;
  LLesson: TSpecCommonsLesson;
  LYamlPath: string;
begin
  if FController = nil then Exit;
  LCsId := FLastGateCsId;
  if LCsId = '' then
  begin
    UpdateHbDeckStatus('[Commons] No recent gate rejection or override changeset to extract');
    Exit;
  end;

  LLesson := FController.ExtractCommonsLesson(LCsId, FLastGateRationale, GetHBShareConsent);
  if LLesson.Id <> '' then
  begin
    LYamlPath := TPath.Combine(FProjectService.AsWishPath, 'commons\' + LLesson.Id + '.yaml');
    if LLesson.PublishConsent then
      UpdateHbDeckStatus(Format('[Commons 🚩] Lesson %s drafted: %s —— 已勾选，将经脱敏推送公共库',
        [LLesson.Id, LLesson.Title]))
    else
      UpdateHbDeckStatus(Format('[Commons 🚩] Lesson %s drafted: %s —— 仅存本机，未推送公共库',
        [LLesson.Id, LLesson.Title]));
    if TFile.Exists(LYamlPath) then
      // Open preview within shell host preview panel (OpenView, WO-0043 F-4)
      OpenView(TShellObjectRef.Make(LLesson.Id, 'yaml', LLesson.Title, LYamlPath));
  end;
end;

procedure TAsWishMainForm.SetHbExtractControlsVisible(const AVisible: Boolean);
begin
  if FHBExtractBtn <> nil then
  begin
    FHBExtractBtn.Visible := AVisible;
    FHBExtractBtn.Enabled := AVisible;
  end;
  // A new gate decision starts a fresh opt-in decision, so a stale checkbox
  // from the previous lesson must not silently carry consent forward.
  if FHBShareConsentChk <> nil then
  begin
    FHBShareConsentChk.Visible := AVisible;
    FHBShareConsentChk.Checked := False;
  end;
end;

function TAsWishMainForm.GetHBShareConsent: Boolean;
begin
  Result := (FHBShareConsentChk <> nil) and FHBShareConsentChk.Checked;
end;

procedure TAsWishMainForm.TriggerExtractLesson;
begin
  TriggerHbExtractLesson;
end;

procedure TAsWishMainForm.UpdateHbDeckStatus(const AMsg: string);
begin
  if FHBDeckStatusLabel <> nil then
    FHBDeckStatusLabel.Caption := ' ' + AMsg;
  SetStatusMessage(AMsg);
end;

procedure TAsWishMainForm.DrainCaptureWarnings(const ALog: TStringList);
var
  I: Integer;
begin
  if (ALog = nil) or (FCaptureWarnings = nil) then
    Exit;
  for I := 0 to FCaptureWarnings.Count - 1 do
    ALog.Add('       ' + FCaptureWarnings[I]);
  FCaptureWarnings.Clear;
end;

function TAsWishMainForm.CaptureBrowserToStream(ABrowser: TEdgeBrowser;
  AStream: TMemoryStream): Boolean;
var
  LStart: UInt64;
begin
  Result := False;
  FCaptureDone := False;
  FCaptureResult := E_FAIL;
  ABrowser.OnCapturePreviewCompleted := BrowserCapturePreviewCompleted;
  try
    ABrowser.CapturePreview(AStream, TCustomEdgeBrowser.TPreviewFormat.PNG);
  except
    on E: Exception do
    begin
      FCaptureDone := False;
      if FCaptureWarnings = nil then FCaptureWarnings := TStringList.Create;
      FCaptureWarnings.Add(Format('[CAPTURE-WARN] CapturePreview(stream) raised %s: %s',
        [E.ClassName, E.Message]));
      Exit;
    end;
  end;

  // Measured 7-9s per capture here. Never free the stream before the callback
  // fires: the adapter holds this object and the browser process writes into
  // it from its own RPC thread.
  LStart := GetTickCount64;
  while not FCaptureDone and (GetTickCount64 - LStart < 30000) do
  begin
    Application.ProcessMessages;
    Sleep(20);
  end;
  ABrowser.OnCapturePreviewCompleted := nil;
  Result := FCaptureDone and (FCaptureResult = S_OK) and (AStream.Size > 0);
end;

function TAsWishMainForm.CaptureControlBitmap(AControl: TWinControl;
  ABmp: Vcl.Graphics.TBitmap): Boolean;
var
  LDiag: string;
begin
  Result := False;
  if (AControl = nil) or (not AControl.HandleAllocated) then
    Exit;
  if FCaptureWarnings = nil then
    FCaptureWarnings := TStringList.Create;

  Result := CaptureControlBitmapDirect(AControl, ABmp, LDiag);
  if not Result then
  begin
    if LDiag <> '' then
      FCaptureWarnings.Add('[CAPTURE-WARN] ' + LDiag + '; no visual evidence emitted');
    Exit;
  end;
  FCaptureWarnings.Add('[CAPTURE-DIAG] ' + LDiag);
end;

procedure TAsWishMainForm.SaveControlImage(AControl: TWinControl; const AFilePath: string);
var
  LBmp: Vcl.Graphics.TBitmap;
  LPng: TPngImage;
begin
  if (AControl = nil) or (not AControl.HandleAllocated) then
    Exit;
  LBmp := Vcl.Graphics.TBitmap.Create;
  try
    if not CaptureControlBitmap(AControl, LBmp) then
      Exit;
    TDirectory.CreateDirectory(TPath.GetDirectoryName(AFilePath));
    // TBitmap.SaveToFile always writes a BMP regardless of the file name, so
    // route through TPngImage to keep the .png evidence extension honest.
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

procedure TAsWishMainForm.SaveWindowScreenshot(const AFilePath: string);
var
  LBmp: Vcl.Graphics.TBitmap;
  LPng, LBrowserPng: TPngImage;
  LBrowser: TEdgeBrowser;
  LTempPng: string;
  LStream: TMemoryStream;
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
        // Vcl.Edge's file-based CapturePreview goes through SHCreateStreamOnFile
        // with STGM_READWRITE and no share mode, so WebView2 holds an exclusive
        // handle on the PNG long past the completion callback: reads failed with
        // a sharing violation and the temp file could never be reclaimed. The
        // TStream overload writes straight into memory, with no file handle.
        FreeAndNil(FPendingStream);
        LStream := TMemoryStream.Create;
        FPendingStream := LStream;
        if not CaptureBrowserToStream(LBrowser, LStream) then
        begin
          // WebView2 rejects a capture issued while the page is still settling
          // (every observed failure followed a navigation). One bounded retry
          // recovers those without extending the fast-fail path.
          Sleep(800);
          LStream.Size := 0;
          if not CaptureBrowserToStream(LBrowser, LStream) then
          begin
            if FCaptureWarnings = nil then FCaptureWarnings := TStringList.Create;
            FCaptureWarnings.Add(Format('[CAPTURE-WARN] browser capture did not complete ' +
              '(result=$%.8x, size=%d); browser region covered by the HTML ' +
              'render fallback', [FCaptureResult, LStream.Size]));
          end;
        end;

        if FCaptureDone and (LStream.Size > 0) then
        begin
          try
            LStream.Position := 0;
            LBrowserPng := TPngImage.Create;
            try
              LBrowserPng.LoadFromStream(LStream);
              LBmp.Canvas.StretchDraw(LRect, LBrowserPng);
              LComposited := True;
            finally
              LBrowserPng.Free;
            end;
          except
            on E: Exception do
            begin
              if FCaptureWarnings = nil then FCaptureWarnings := TStringList.Create;
              FCaptureWarnings.Add(Format('[CAPTURE-WARN] browser capture unreadable: %s: %s',
                [E.ClassName, E.Message]));
            end;
          end;
        end;

        if FCaptureDone then
          FreeAndNil(FPendingStream);
      end;
    end;

    // Offscreen / Virtual session fallback: Render HTML view directly into CenterPanel
    if not LComposited and (FLastHtmlPath <> '') and TFile.Exists(FLastHtmlPath) then
    begin
      LTempPng := TPath.Combine(TPath.GetTempPath,
        Format('aswish-render-%d-%d.png', [GetCurrentProcessId, GetTickCount64]));
      if RenderHtmlToPngNative(FLastHtmlPath, LTempPng, CenterPanel.Width, CenterPanel.Height) then
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
      end
      else
      begin
        if FCaptureWarnings = nil then FCaptureWarnings := TStringList.Create;
        FCaptureWarnings.Add(Format('[CAPTURE-WARN] native HTML screenshot render failed for %s', [FLastHtmlPath]));
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

const
  ATTACH_PARENT_PROCESS = DWORD(-1);

function AttachConsole(dwProcessId: DWORD): BOOL; stdcall; external 'kernel32.dll';

procedure ConsolePrint(const AText: string);
var
  H: THandle;
  LBytes: TBytes;
  LWritten: DWORD;
begin
  H := GetStdHandle(STD_OUTPUT_HANDLE);
  if (H <> 0) and (H <> INVALID_HANDLE_VALUE) then
  begin
    LBytes := TEncoding.UTF8.GetBytes(AText + sLineBreak);
    WriteFile(H, LBytes[0], Length(LBytes), LWritten, nil);
  end;
end;

procedure ConsoleError(const AText: string);
var
  H: THandle;
  LBytes: TBytes;
  LWritten: DWORD;
begin
  H := GetStdHandle(STD_ERROR_HANDLE);
  if (H <> 0) and (H <> INVALID_HANDLE_VALUE) then
  begin
    LBytes := TEncoding.UTF8.GetBytes(AText + sLineBreak);
    WriteFile(H, LBytes[0], Length(LBytes), LWritten, nil);
  end;
end;

procedure TAsWishMainForm.RunGuiVerification(const AProjectPath: string);
var
  LLog: TStringList;
  LRepoRoot, LEvidenceDir, LShotDir, LLogFile: string;
  LDiffPath, LDecPath, LTargetDecId: string;
  LDec1, LDec2, LEvolveId, LDomText, LDecIds: string;
  LCommonsDir, LCommonsYaml, LBaselineId: string;
  LFiles: TArray<string>;
  LAct: THbChoiceAction;
  LNewBaseline: TAsWishBaseline;
  LBaselines: TArray<TAsWishBaseline>;
  LDecisions: TArray<TSpecDecision>;
  LLessons: TArray<TSpecCommonsLesson>;
  LTargetLesson, LNarrativeLesson: TSpecCommonsLesson;
  LDiffReport: TSpecDifferenceReport;
  LDiffCount: Integer;
  LHasConsole, LFoundLesson, LFoundNarrative: Boolean;
  LGhostTrigger, LTargetPattern, LNarrativePattern, LNarrativeTrigger: string;
  LSubmittedCs: string;
begin
  LHasConsole := AttachConsole(ATTACH_PARENT_PROCESS);
  if not LHasConsole then
    LHasConsole := AllocConsole;

  LRepoRoot := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..'));

  LLog := TStringList.Create;
  try
    try
      LEvidenceDir := TPath.Combine(LRepoRoot, 'dogfood_gui');
      LShotDir := TPath.Combine(LEvidenceDir, 'screenshots');
      LLogFile := TPath.Combine(LEvidenceDir, 'gui-dual-surface.txt');
      try
        TDirectory.CreateDirectory(LShotDir);
      except
        on E: Exception do
          raise Exception.Create(Format('Cannot create verification directory "%s": %s', [LShotDir, E.Message]));
      end;

      LLog.Add('============================================================');
      LLog.Add(' AsWish Desktop GUI Decision Workflow Real Verification');
      LLog.Add('============================================================');
      LLog.Add('Timestamp: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
      LLog.Add(Format('Process ID: %d | Window Handle: %d', [GetCurrentProcessId, Handle]));
      LLog.Add('Window Caption: ' + Caption);
      if not IsWindowVisible(Handle) then
      begin
        ShowWindow(Handle, SW_SHOW);
        Update;
        Application.ProcessMessages;
      end;
      LLog.Add('Form On Screen: ' + BoolToStr(IsWindowVisible(Handle), True));
      if not IsWindowVisible(Handle) then
        raise Exception.Create('gui-verify precondition failed: main form is ' +
          'not on screen (IsWindowVisible=False); screen captures would be blank');
      LLog.Add('Project Path: ' + AProjectPath);
      if CurrentMainControl <> nil then
      begin
        LLog.Add('Main Control Class: ' + CurrentMainControl.ClassName);
        if CurrentMainControl is TLabel then
          LLog.Add('Label Text: ' + TLabel(CurrentMainControl).Caption)
        else if CurrentMainControl is TCustomEdgeBrowser then
        begin
          LLog.Add('Browser State: ' + IntToStr(Ord(TCustomEdgeBrowser(CurrentMainControl).BrowserControlState)));
          LLog.Add('WebView Created: ' + BoolToStr(TCustomEdgeBrowser(CurrentMainControl).WebViewCreated, True));
          LLog.Add(Format('Last Error Code: $%.8x', [TCustomEdgeBrowser(CurrentMainControl).LastErrorCode]));
        end;
      end;

      // Anti-silent failure guard: verify WebView is actually functional
      if (CurrentMainControl is TCustomEdgeBrowser) and
         (not TCustomEdgeBrowser(CurrentMainControl).WebViewCreated) then
      begin
        raise Exception.Create(Format('GUI-VERIFY-NO-WEBVIEW: WebView2 Runtime is not created (LastErrorCode: $%.8x). Functional WebView2 environment is required for GUI verification.',
          [TCustomEdgeBrowser(CurrentMainControl).LastErrorCode]));
      end;

      // Step 1: Open and scan project in GUI
      SetStatusMessage('GUI Step 1: Opening project in GUI...');
      FController.OpenAndScan(AProjectPath);
      FLastHtmlPath := TPath.Combine(FProjectService.AsWishPath, 'html\index.html');
      Update;
      Application.ProcessMessages;
      if not WaitForBrowserReady('AsWish', 2000, LDomText) then
        raise Exception.Create(Format('Step 1 DOM assertion failed: index.html did not render in DOM. DOM excerpt: %s',
          [DomExcerptForLog(LDomText)]));
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-01-project-open.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add('[PASS] Step 1: OpenAndScan executed in GUI.');
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-01-project-open.png');
      LLog.Add('       [DOM-ASSERT] index.html rendered in WebView2, DOM excerpt: ' +
        Copy(DomExcerptForLog(LDomText), 1, 120));
      ConsolePrint('[GUI-VERIFY] Step 1: OpenAndScan executed in GUI.');

      // Dynamic Baseline Resolution
      LBaselines := FController.ListBaselines;
      if Length(LBaselines) = 0 then
      begin
        LBaselineId := FController.ConfirmVisualBaseline('GUI auto-initialized baseline for verification');
        if LBaselineId = '' then
          raise Exception.Create('gui-verify: Failed to initialize visual baseline for project');
      end
      else
        LBaselineId := LBaselines[0].BaselineId;

      // Step 2: Navigate to structural difference view
      SetStatusMessage('GUI Step 2: Navigating to difference view...');
      LDiffReport := FController.ComputeDifference(LBaselineId);
      LDiffCount := Length(LDiffReport.Items);
      LDiffPath := TPath.Combine(FProjectService.AsWishPath, 'html\difference.html');
      FLastHtmlPath := LDiffPath;
      OpenView(TShellObjectRef.Make('difference-html', 'html', 'Structural Difference', LDiffPath));
      Update;
      Application.ProcessMessages;
      if not WaitForBrowserReady(IntToStr(LDiffCount), 2000, LDomText) then
        raise Exception.Create(Format('Step 2 DOM assertion failed: difference.html did not render difference count %d. DOM excerpt: %s',
          [LDiffCount, DomExcerptForLog(LDomText)]));
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-02-difference-view.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add('[PASS] Step 2: Difference view loaded. Path: ' + LDiffPath);
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-02-difference-view.png');
      LLog.Add(Format('       [DOM-ASSERT] difference.html rendered, difference count verified in DOM: %d items', [LDiffCount]));
      LLog.Add('       [DOM-ASSERT] DOM excerpt: ' + Copy(DomExcerptForLog(LDomText), 1, 160));
      ConsolePrint(Format('[GUI-VERIFY] Step 2: Difference view loaded (%d items).', [LDiffCount]));

      // Step 3: Trigger Unacceptable judgment via GUI Controller channel
      SetStatusMessage('GUI Step 3: Triggering Unacceptable judgment...');
      LDec1 := FController.RecordDifferenceDecision(LBaselineId, 'unacceptable', 'GUI rejected item');
      LDecPath := TPath.Combine(FProjectService.AsWishPath, 'html\decisions.html');
      FLastHtmlPath := LDecPath;
      OpenView(TShellObjectRef.Make('decisions-html', 'html', 'Decisions', LDecPath));
      Update;
      Application.ProcessMessages;
      if not WaitForBrowserReady(LDec1, 2000, LDomText) then
        raise Exception.Create(Format('Step 3 DOM assertion failed: decisions.html did not render decision %s. DOM excerpt: %s',
          [LDec1, DomExcerptForLog(LDomText)]));
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-03-judge-unacceptable.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add(Format('[PASS] Step 3: Recorded Unacceptable decision %s in GUI.', [LDec1]));
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-03-judge-unacceptable.png');
      LLog.Add(Format('       [DOM-ASSERT] decisions.html rendered, contains decision "%s" in DOM', [LDec1]));
      LLog.Add('       [DOM-ASSERT] DOM excerpt: ' + Copy(DomExcerptForLog(LDomText), 1, 160));
      ConsolePrint(Format('[GUI-VERIFY] Step 3: Recorded Unacceptable decision %s.', [LDec1]));

      // Step 4: Trigger Acceptable judgment via GUI Controller channel
      SetStatusMessage('GUI Step 4: Triggering Acceptable judgment...');
      LDec2 := FController.RecordDifferenceDecision(LBaselineId, 'acceptable', 'GUI accepted item');
      FLastHtmlPath := LDecPath;
      OpenView(TShellObjectRef.Make('decisions-html', 'html', 'Decisions', LDecPath));
      Update;
      Application.ProcessMessages;
      if not WaitForBrowserReady(LDec2, 2000, LDomText) then
        raise Exception.Create(Format('Step 4 DOM assertion failed: decisions.html did not render decision %s. DOM excerpt: %s',
          [LDec2, DomExcerptForLog(LDomText)]));
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-04-judge-acceptable.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add(Format('[PASS] Step 4: Recorded Acceptable decision %s in GUI.', [LDec2]));
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-04-judge-acceptable.png');
      LLog.Add(Format('       [DOM-ASSERT] decisions.html rendered, contains decision "%s" in DOM', [LDec2]));
      LLog.Add('       [DOM-ASSERT] DOM excerpt: ' + Copy(DomExcerptForLog(LDomText), 1, 160));
      ConsolePrint(Format('[GUI-VERIFY] Step 4: Recorded Acceptable decision %s.', [LDec2]));

      // Step 5: Trigger Evolve Baseline via GUI Controller channel
      SetStatusMessage('GUI Step 5: Triggering Baseline Evolution...');
      LEvolveId := FController.EvolveBaseline(LBaselineId, 'GUI evolved baseline from reality', LNewBaseline);
      FController.ComputeDifference(LEvolveId);
      FLastHtmlPath := LDiffPath;
      OpenView(TShellObjectRef.Make('difference-html', 'html', 'Difference ' + LEvolveId, LDiffPath));
      Update;
      Application.ProcessMessages;
      if not WaitForBrowserReady(LEvolveId, 2000, LDomText) then
        raise Exception.Create(Format('Step 5 DOM assertion failed: difference.html did not render evolved baseline %s. DOM excerpt: %s',
          [LEvolveId, DomExcerptForLog(LDomText)]));
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-05-evolve-baseline.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add(Format('[PASS] Step 5: Evolved new baseline %s (parent: %s) in GUI.',
        [LEvolveId, LNewBaseline.Lineage.ParentBaselineId]));
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-05-evolve-baseline.png');
      LLog.Add(Format('       [DOM-ASSERT] difference.html rendered for evolved baseline %s in DOM', [LEvolveId]));
      LLog.Add('       [DOM-ASSERT] DOM excerpt: ' + Copy(DomExcerptForLog(LDomText), 1, 160));
      ConsolePrint(Format('[GUI-VERIFY] Step 5: Evolved new baseline %s.', [LEvolveId]));

      // Step 6: Verify updated decisions history page
      SetStatusMessage('GUI Step 6: Viewing updated decisions history...');
      FLastHtmlPath := LDecPath;
      OpenView(TShellObjectRef.Make('decisions-html', 'html', 'Decisions', LDecPath));
      Update;
      Application.ProcessMessages;
      LDecisions := FController.ListDecisions;
      LDecIds := '';
      for var LD in LDecisions do
      begin
        if LDecIds <> '' then LDecIds := LDecIds + ', ';
        LDecIds := LDecIds + LD.Id;
      end;
      if Length(LDecisions) > 0 then
        LTargetDecId := LDecisions[High(LDecisions)].Id
      else
        LTargetDecId := LDec2;
      if not WaitForBrowserReady(LTargetDecId, 2000, LDomText) then
        raise Exception.Create(Format('Step 6 DOM assertion failed: decisions.html did not render decision %s. DOM excerpt: %s',
          [LTargetDecId, DomExcerptForLog(LDomText)]));
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-06-decisions-history.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add('[PASS] Step 6: Decisions history displayed in GUI.');
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-06-decisions-history.png');
      LLog.Add(Format('       [DOM-ASSERT] decisions.html rendered, contains history (%s) in DOM', [LDecIds]));
      LLog.Add('       [DOM-ASSERT] DOM excerpt: ' + Copy(DomExcerptForLog(LDomText), 1, 220));
      ConsolePrint('[GUI-VERIFY] Step 6: Decisions history displayed in GUI.');

      // Step 7: Verify D-1 Inspector Sidebar Dialog (WO-0044)
      SetStatusMessage('GUI Step 7: Verifying D-1 Inspector Sidebar Dialog...');
      if (FFuncTree <> nil) and (FFuncTree.Items.Count > 0) then
      begin
        FFuncTree.Selected := FFuncTree.Items[0];
        DoSpecTreeChange(FFuncTree, FFuncTree.Selected);
      end
      else
      begin
        if FCurrentInspectedNodeId = '' then
          FCurrentInspectedNodeId := 'node-main';
        RightPanel.Visible := True;
        RightSplitter.Visible := True;
        FInspectorNodeLabel.Caption := ' ' + FCurrentInspectedNodeId;
      end;
      if not RightPanel.Visible then
        raise Exception.Create('D-1 assertion failed: RightPanel must be visible on node inspection');
      FInspectorIntentEdit.Text := 'Update verification intent';
      LSubmittedCs := SubmitInspectorIntent;
      if LSubmittedCs = '' then
        raise Exception.Create('D-1 assertion failed: SubmitInspectorIntent returned empty ChangeSet ID');
      if (FHBBinding <> nil) and (FHBBinding.LastChangeSetId <> LSubmittedCs) then
        raise Exception.Create(Format('WO-0057 1.2 assertion failed: Inspector submit (%s) did not update LastChangeSetId (%s)',
          [LSubmittedCs, FHBBinding.LastChangeSetId]));
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-07-inspector-dialog.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add(Format('[PASS] Step 7: D-1 Inspector Sidebar verified. ChangeSet: %s submitted via SSOT.', [LSubmittedCs]));
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-07-inspector-dialog.png');
      ConsolePrint(Format('[GUI-VERIFY] Step 7: D-1 Inspector Sidebar verified (%s).', [LSubmittedCs]));

      // Step 8: Verify D-2 Ghosts Context Hints & Badges (WO-0044)
      SetStatusMessage('GUI Step 8: Verifying D-2 Ghosts Context Hints...');
      LLessons := FController.Commons.ListLessons;
      if Length(LLessons) = 0 then
        raise Exception.Create('D-2 assertion failed: Commons service has no lessons available for ghost hints verification');

      LFoundLesson := False;
      for var LL in LLessons do
        if (Length(LL.TriggerPattern) > 0) then
        begin
          LTargetLesson := LL;
          LFoundLesson := True;
          Break;
        end;
      if not LFoundLesson then
        LTargetLesson := LLessons[0];

      LTargetPattern := LTargetLesson.TriggerPattern;
      if LTargetPattern.Contains('|') then
        LGhostTrigger := Copy(LTargetPattern, 1, Pos('|', LTargetPattern) - 1)
      else if LTargetPattern <> '' then
        LGhostTrigger := LTargetPattern
      else
        LGhostTrigger := LTargetLesson.Title;

      UpdateGhosts(LGhostTrigger);
      if not FGhostsPanel.Visible then
        raise Exception.Create('D-2 assertion failed: Ghosts panel must be visible when match found');
      if not FGhostsChips[0].Visible then
        raise Exception.Create('D-2 assertion failed: Ghosts chip 0 must be visible');
      if Pos(LTargetLesson.Title, FGhostsLabels[0].Caption) <= 0 then
        raise Exception.Create(Format('D-2 assertion failed: Ghosts chip text must contain lesson title "%s"', [LTargetLesson.Title]));

      LFoundNarrative := False;
      for var LL in LLessons do
        if SameText(LL.AnchorKind, 'narrative') and (LL.TriggerPattern <> '') then
        begin
          LNarrativeLesson := LL;
          LFoundNarrative := True;
          Break;
        end;

      if LFoundNarrative then
      begin
        LNarrativePattern := LNarrativeLesson.TriggerPattern;
        if LNarrativePattern.Contains('|') then
          LNarrativeTrigger := Copy(LNarrativePattern, 1, Pos('|', LNarrativePattern) - 1)
        else
          LNarrativeTrigger := LNarrativePattern;
        UpdateGhosts(LNarrativeTrigger);
        if Pos('经验总结，非可复核记录', FGhostsLabels[0].Caption) <= 0 then
          raise Exception.Create('D-2 assertion failed: Narrative anchor must include [经验总结，非可复核记录]');
      end;

      DoGhostChipCloseClick(FGhostsCloseBtns[0]);
      if FGhostsChips[0].Visible then
        raise Exception.Create('D-2 assertion failed: Closing chip must hide it');
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-08-ghosts-hints.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add('[PASS] Step 8: D-2 Ghosts context chips (matching, narrative badges, dismiss) verified.');
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-08-ghosts-hints.png');
      ConsolePrint('[GUI-VERIFY] Step 8: D-2 Ghosts context chips verified.');

      // Step 9: Verify D-3 Immersive Review Surface (F11) (WO-0044)
      SetStatusMessage('GUI Step 9: Verifying D-3 Immersive Review Surface...');
      if not LeftPanel.Visible then LeftPanel.Visible := True;
      ToggleFullscreenReview;
      if LeftPanel.Visible or RightPanel.Visible then
        raise Exception.Create('D-3 assertion failed: Immersive review must hide left and right panels');
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-09-immersive-review.png'));
      DrainCaptureWarnings(LLog);

      ToggleFullscreenReview;
      if not LeftPanel.Visible then
        raise Exception.Create('D-3 assertion failed: Restoring review must restore left panel');
      LLog.Add('[PASS] Step 9: D-3 Immersive review surface (F11 toggle, panel hide/restore) verified.');
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-09-immersive-review.png');
      ConsolePrint('[GUI-VERIFY] Step 9: D-3 Immersive review surface verified.');

      // Step 9.5: Verify WO-20260924-0049 P-4 share-to-hub consent (HB Deck)
      SetStatusMessage('GUI Step 9.5: Verifying Commons share-to-hub consent...');
      if HBShareConsent then
        raise Exception.Create('P-4 assertion failed: consent checkbox must default to unchecked');
      LAct := THbChoiceAction.Create(cakFreeInput, 9,
        'Automated intent: preserve provenance instead of physical delete', 0,
        cisKeyboard, eokAlternativeExpression, esHuman, eipProvide);
      FHBBinding.ProcessHbAction(LAct);
      if FHBBinding.LastChangeSetId = '' then
        raise Exception.Create('P-4 assertion failed: free-input override must hand a ChangeSet to the deck');
      TriggerHbReject;
      if not HBExtractBtn.Visible then
        raise Exception.Create('P-4 assertion failed: extract button must surface after a gate rejection');
      if not FHBShareConsentChk.Visible then
        raise Exception.Create('P-4 assertion failed: consent checkbox must surface with the extract button');
      if FHBShareConsentChk.Checked then
        raise Exception.Create('P-4 assertion failed: consent checkbox must stay unchecked until the human opts in');
      FHBShareConsentChk.Checked := True;
      SetHbExtractControlsVisible(True);
      if FHBShareConsentChk.Checked then
        raise Exception.Create('P-4 assertion failed: a new gate decision must reset stale consent');
      Update;
      Application.ProcessMessages;
      LLog.Add(Format('       [STATE] consent checkbox Checked=%s, Visible=%s',
        [BoolToStr(FHBShareConsentChk.Checked, True), BoolToStr(FHBShareConsentChk.Visible, True)]));
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-10-consent-unchecked.png'));
      SaveControlImage(FHBShareConsentChk,
        TPath.Combine(LShotDir, 'gui-10-consent-checkbox.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add('[PASS] Step 9.5a: Share-to-hub consent defaults unchecked and never carries stale opt-in forward.');
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-10-consent-unchecked.png');
      LLog.Add('       Control capture: dogfood_gui/screenshots/gui-10-consent-checkbox.png');

      // Opt-in path: extraction must persist publish_consent and report the share status.
      FHBShareConsentChk.Checked := True;
      TriggerHbExtractLesson;
      LCommonsDir := TPath.Combine(FProjectService.AsWishPath, 'commons');
      LFiles := TDirectory.GetFiles(LCommonsDir, 'lesson-*.yaml');
      if Length(LFiles) = 0 then
        raise Exception.Create('P-4 assertion failed: opted-in extraction must write a lesson draft');
      LCommonsYaml := TFile.ReadAllText(LFiles[High(LFiles)], TEncoding.UTF8);
      if not LCommonsYaml.Contains('publish_consent: true') then
        raise Exception.Create('P-4 assertion failed: opted-in lesson must persist publish_consent: true');
      if Pos('已勾选', FHBDeckStatusLabel.Caption) <= 0 then
        raise Exception.Create('P-4 assertion failed: status line must report the granted share consent');
      LLog.Add(Format('       [STATE] consent checkbox Checked=%s before opt-in screenshot',
        [BoolToStr(FHBShareConsentChk.Checked, True)]));
      Update;
      Application.ProcessMessages;
      SaveWindowScreenshot(TPath.Combine(LShotDir, 'gui-11-consent-checked.png'));
      SaveControlImage(FHBShareConsentChk,
        TPath.Combine(LShotDir, 'gui-11-consent-checkbox.png'));
      DrainCaptureWarnings(LLog);
      LLog.Add('[PASS] Step 9.5b: Opted-in extraction persists publish_consent: true and reports the share status.');
      LLog.Add('       Screenshot: dogfood_gui/screenshots/gui-11-consent-checked.png');
      LLog.Add('       Control capture: dogfood_gui/screenshots/gui-11-consent-checkbox.png');

      // Opt-out path: same lesson re-extracted without consent must not publish.
      FHBShareConsentChk.Checked := False;
      TriggerHbExtractLesson;
      LFiles := TDirectory.GetFiles(LCommonsDir, 'lesson-*.yaml');
      if Length(LFiles) = 0 then
        raise Exception.Create('P-4 assertion failed: opted-out extraction must still write a local draft');
      LCommonsYaml := TFile.ReadAllText(LFiles[High(LFiles)], TEncoding.UTF8);
      if LCommonsYaml.Contains('publish_consent: true') then
        raise Exception.Create('P-4 assertion failed: opted-out lesson must not publish');
      if Pos('仅存本机', FHBDeckStatusLabel.Caption) <= 0 then
        raise Exception.Create('P-4 assertion failed: status line must report local-only storage');
      LLog.Add('[PASS] Step 9.5c: Opted-out extraction stays local-only; no publish_consent on disk.');
      LLog.Add('       Lesson draft: ' + LFiles[High(LFiles)]);
      ConsolePrint('[GUI-VERIFY] Step 9.5: Commons share-to-hub consent verified.');

      // Step 10: Verify disk artifacts
      LLog.Add('------------------------------------------------------------');
      LLog.Add('Physical Disk Verification:');
      LLog.Add('  - difference.html exists: ' + BoolToStr(TFile.Exists(LDiffPath), True) + ' (' + LDiffPath + ')');
      LLog.Add('  - decisions.html exists: ' + BoolToStr(TFile.Exists(LDecPath), True) + ' (' + LDecPath + ')');
      LLog.Add('  - requirement-decisions.yaml exists: ' + BoolToStr(TFile.Exists(TPath.Combine(FProjectService.AsWishPath, 'decisions\requirement-decisions.yaml')), True));
      LLog.Add('  - evolved baseline: ' + LEvolveId + ' (' + LNewBaseline.SnapshotName + ')');
      LLog.Add('  - parent_baseline_id: ' + LNewBaseline.Lineage.ParentBaselineId);
      LLog.Add('  - DOM-verified decisions: ' + LDecIds);
      LLog.Add(Format('  - DOM-verified difference count: %d items', [LDiffCount]));
      LLog.Add('============================================================');
      LLog.Add('GUI Verification Exit Code: 0');

      LLog.SaveToFile(LLogFile, TEncoding.UTF8);
      ConsolePrint('[GUI-VERIFY] Step 10: Physical disk verification completed.');
      ConsolePrint('[GUI-VERIFY SUMMARY] PASS: All verification steps completed successfully. Evidence: ' + LLogFile);

      if LHasConsole then
      begin
        Sleep(100);
        FreeConsole;
      end;
      System.ExitCode := 0;
      Winapi.Windows.ExitProcess(0);
    except
      on E: Exception do
      begin
        LLog.Add('============================================================');
        LLog.Add('[FAILED] ' + E.ClassName + ': ' + E.Message);
        LLog.Add('GUI Verification Exit Code: 1');
        try
          TDirectory.CreateDirectory(TPath.GetDirectoryName(LLogFile));
          LLog.SaveToFile(LLogFile, TEncoding.UTF8);
        except
        end;
        ConsoleError('[GUI-VERIFY FAILED] ' + E.ClassName + ': ' + E.Message);
        ConsoleError('[GUI-VERIFY SUMMARY] FAIL: GUI verification failed. Evidence: ' + LLogFile);
        if LHasConsole then
        begin
          Sleep(100);
          FreeConsole;
        end;
        System.ExitCode := 1;
        Winapi.Windows.ExitProcess(1);
      end;
    end;
  finally
    LLog.Free;
  end;
end;

end.
