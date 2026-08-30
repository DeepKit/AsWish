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
    procedure OpenView(const ARef: TShellObjectRef);
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
  AsWish.Commands,
  AsWish.Providers,
  AsWish.Localization,
  AsWish.Services.Storage,
  AsWish.SettingsProvider,
  AsWish.AutoFix,
  AsWish.Logger,
  AsWish.Config;

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
  Caption := 'AsWish';

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
end;

procedure TAsWishMainForm.AfterShellShown;
begin
  inherited AfterShellShown;

  BuildLeftPanelUI;

  TAsWishAutoFix.SendHealthSignal('startup', 1);
  TAsWishAutoFix.RegisterScenario('smoke', procedure
  begin
  end);

  SetStatusMessage(ShellText('aswish.status.ready',
    'AsWish ready. Open a project folder to begin.'));

  // Session restore
  try
    var LRestore := GetConfigBool('aswish.session.restore', True);
    if LRestore and (Recent <> nil) and (not FController.IsProjectOpen) then
    begin
      var LItems := Recent.GetRecentProjects;
      for var LItem in LItems do
        if (not LItem.Invalid) and TDirectory.Exists(LItem.Path) then
        begin
          SetStatusMessage('Restoring last session: ' + LItem.Path);
          FController.OpenAndScan(LItem.Path);
          PopulateMruCombo;
          Break;
        end;
    end;
  except
    on E: Exception do
      Logger.Error('Session restore failed: ' + E.Message, 'AsWish');
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
begin
  if Context <> nil then
    Context.SetObject(ARef);
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

end.
