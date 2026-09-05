unit Test.AsWish.GUIDecisions;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  AsWish.Models,
  AsWish.UI.Intf,
  AsWish.UI.Types,
  AsWish.Services.Project,
  AsWish.Services.Scan,
  AsWish.Services.SpecStore,
  AsWish.Services.Render,
  AsWish.Services.TreeBuilder,
  AsWish.Services.Prompts,
  AsWish.Services.Decisions,
  AsWish.Services.LLM,
  AsWish.Services.Settings,
  AsWish.Services.Snapshot,
  AsWish.Services.Difference,
  AsWish.Services.EvidenceCollector,
  AsWish.Controller;

type
  TMockStatus = class(TInterfacedObject, IShellStatusManager)
  public
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

  TMockContext = class(TInterfacedObject, IShellContextManager)
  public
    function Current: TShellContext;
    procedure SetProject(const AProjectId, APath: string);
    procedure SetObject(const ARef: TShellObjectRef);
    procedure SetView(const AViewId, AViewType: string);
    procedure ClearProject;
  end;

  TMockBus = class(TInterfacedObject, IShellEventBus)
  public
    function Subscribe(AKind: TDeepShellEventKind; AHandler: TShellEventHandler): string;
    function SubscribeAll(AHandler: TShellEventHandler): string;
    procedure Unsubscribe(const AToken: string);
    procedure Publish(const AEvent: TDeepShellEvent);
    procedure Shutdown;
    procedure SetOnDispatchError(AHandler: TProc<Exception, string>);
  end;

  [TestFixture]
  TTestAsWishGUIDecisions = class
  private
    FDir: string;
    FProject: TAsWishProjectService;
    FScan: TAsWishScanService;
    FStore: TAsWishStoreService;
    FRender: TAsWishRenderService;
    FBuilder: TAsWishTreeBuilder;
    FPrompts: TAsWishPromptService;
    FDecisions: TAsWishDecisionsService;
    FSettings: TAsWishSettingsService;
    FLLM: TAsWishLLMService;
    FController: TAsWishController;
  public
    [Setup] procedure SetUp;
    [TearDown] procedure TearDown;

    [Test] procedure Test_GUI_Decision_Workflow_EndToEnd;
  end;

implementation

{ TMockStatus }
procedure TMockStatus.Info(const ASource, AMessage: string); begin end;
procedure TMockStatus.Warning(const ASource, AMessage: string); begin end;
procedure TMockStatus.LogError(const ASource, AMessage, ADetail: string); begin end;
procedure TMockStatus.ShellError(const ASource, AMessage, ADetail: string); begin end;
procedure TMockStatus.Progress(const ATaskId, ASource: string; APercent: Integer; const AMessage: string); begin end;
procedure TMockStatus.TaskStart(const ATaskId, ASource, AMessage: string); begin end;
procedure TMockStatus.TaskFinish(const ATaskId, AMessage: string); begin end;
procedure TMockStatus.Diagnostic(const ASource, AMessage: string); begin end;
function TMockStatus.GetEntries: TArray<TShellStatusEntry>; begin SetLength(Result, 0); end;
procedure TMockStatus.ClearEntries; begin end;
procedure TMockStatus.SetSanitizer(ASanitizer: TShellStatusSanitizer); begin end;

{ TMockContext }
function TMockContext.Current: TShellContext; begin Result := Default(TShellContext); end;
procedure TMockContext.SetProject(const AProjectId, APath: string); begin end;
procedure TMockContext.SetObject(const ARef: TShellObjectRef); begin end;
procedure TMockContext.SetView(const AViewId, AViewType: string); begin end;
procedure TMockContext.ClearProject; begin end;

{ TMockBus }
function TMockBus.Subscribe(AKind: TDeepShellEventKind; AHandler: TShellEventHandler): string; begin Result := 'tok'; end;
function TMockBus.SubscribeAll(AHandler: TShellEventHandler): string; begin Result := 'tok'; end;
procedure TMockBus.Unsubscribe(const AToken: string); begin end;
procedure TMockBus.Publish(const AEvent: TDeepShellEvent); begin end;
procedure TMockBus.Shutdown; begin end;
procedure TMockBus.SetOnDispatchError(AHandler: TProc<Exception, string>); begin end;

procedure TTestAsWishGUIDecisions.SetUp;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'aswish-gui-' + TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FDir);
  TFile.WriteAllText(TPath.Combine(FDir, 'README.md'),
    '# GUI Decision Test Project' + sLineBreak + 'Specification docs.', TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(FDir, 'main.pas'),
    'unit main; interface function RunApp: Integer; implementation function RunApp: Integer; begin Result := 1; end; end.', TEncoding.UTF8);

  FProject := TAsWishProjectService.Create;
  FScan := TAsWishScanService.Create;
  FStore := TAsWishStoreService.Create;
  FRender := TAsWishRenderService.Create;
  FBuilder := TAsWishTreeBuilder.Create;
  FPrompts := TAsWishPromptService.Create;
  FDecisions := TAsWishDecisionsService.Create;
  FSettings := TAsWishSettingsService.Create;
  FLLM := TAsWishLLMService.Create('Default');

  FController := TAsWishController.Create(FProject, FScan, FStore, FRender,
    FBuilder, FPrompts, FDecisions, FLLM, FSettings,
    TMockStatus.Create, TMockContext.Create, TMockBus.Create);

  FController.OpenAndScan(FDir);
end;

procedure TTestAsWishGUIDecisions.TearDown;
begin
  FController.Free;
  if TDirectory.Exists(FDir) then
    TDirectory.Delete(FDir, True);
end;

procedure TTestAsWishGUIDecisions.Test_GUI_Decision_Workflow_EndToEnd;
var
  LCSId, LDecId, LNewBaseId, LSnapFile, LSnapText, LDecText: string;
  LNewBaseline: TAsWishBaseline;
  LReport: TSpecDifferenceReport;
begin
  // 1. Initial intent & freeze B-0001
  LCSId := FController.SubmitUserIntent('func-root', ttFunction, 'Initial specification for GUI decision test');
  Assert.IsTrue(FController.AcceptChangeSet(LCSId, 'Accept B-0001'));

  // 2. Modify code to produce difference
  TFile.WriteAllText(TPath.Combine(FDir, 'extra.pas'),
    'unit extra; interface function ExtraFunc: string; implementation function ExtraFunc: string; begin Result := ''extra''; end; end.',
    TEncoding.UTF8);
  FController.RunScan;

  // 3. GUI triggers Difference view
  LReport := FController.ComputeDifference('B-0001');
  Assert.AreEqual('B-0001', LReport.BaselineId);
  Assert.IsTrue(Length(LReport.Items) > 0);
  Assert.IsTrue(TFile.Exists(TPath.Combine(FDir, '.AsWish\html\difference.html')));

  // 4. GUI triggers Judge Unacceptable (reject)
  LDecId := FController.RecordDifferenceDecision('B-0001', 'unacceptable', 'GUI rejected extra.pas');
  Assert.IsNotEmpty(LDecId);
  Assert.AreEqual(dsRejected, FDecisions.FindById(LDecId).Status);

  // 5. GUI triggers Accept Difference
  LDecId := FController.RecordDifferenceDecision('B-0001', 'acceptable', 'GUI accepted extra.pas');
  Assert.IsNotEmpty(LDecId);
  Assert.AreEqual(dsAccepted, FDecisions.FindById(LDecId).Status);

  // 6. GUI triggers Evolve to B-0002
  LNewBaseId := FController.EvolveBaseline('B-0001', 'GUI evolution to B-0002', LNewBaseline);
  Assert.AreEqual('B-0002', LNewBaseId);
  Assert.AreEqual('B-0001', LNewBaseline.Lineage.ParentBaselineId);

  // 7. Verify disk artifacts
  LSnapFile := TPath.Combine(FDir, '.AsWish\snapshots\' + LNewBaseline.SnapshotName + '\snapshot.yaml');
  Assert.IsTrue(TFile.Exists(LSnapFile));
  LSnapText := TFile.ReadAllText(LSnapFile, TEncoding.UTF8);
  Assert.IsTrue(LSnapText.Contains('parent_baseline_id: "B-0001"'));

  LDecText := TFile.ReadAllText(TPath.Combine(FDir, '.AsWish\decisions\requirement-decisions.yaml'), TEncoding.UTF8);
  Assert.IsTrue(LDecText.Contains('dec-0001'));
  Assert.IsTrue(LDecText.Contains('dec-0002'));
  Assert.IsTrue(LDecText.Contains('dec-0003'));
  Assert.IsTrue(LDecText.Contains('dec-0004'));

  // 8. Verify HTML decisions table
  Assert.IsTrue(TFile.Exists(TPath.Combine(FDir, '.AsWish\html\decisions.html')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishGUIDecisions);

end.
