unit Test.AsWish.GUIDecisions;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows,
  Test.AsWish.FixtureHelper,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Graphics,
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
  AsWish.Services.CandidateIngest,
  AsWish.Version,
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
    [Test] procedure Test_Version_Constant_Defined;
    [Test] procedure Test_DualSurface_D1_TreeFromNodePrefix_Inference;
    [Test] procedure Test_DualSurface_D1_SubmitUserIntent_WithTreeInference;
    [Test] procedure Test_DualSurface_D2_Ghosts_MatchingAndNarrativeBadge;
    [Test] procedure Test_CaptureConstraint_CheckBoxState_WindowScreenshotInert_ControlCaptureDiverges;
    [Test] procedure Test_WindowScreenshot_SingleColorGuard_RejectsBlank_AndEmitsWarning;
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
  WriteFixtureText(TPath.Combine(FDir, 'README.md'),
    '# GUI Decision Test Project' + sLineBreak + 'Specification docs.', TEncoding.UTF8);
  WriteFixtureText(TPath.Combine(FDir, 'main.pas'),
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

  // 2. Modify code and documentation to produce difference in function tree
  WriteFixtureText(TPath.Combine(FDir, 'extra.pas'),
    'unit extra; interface function ExtraFunc: string; implementation function ExtraFunc: string; begin Result := ''extra''; end; end.',
    TEncoding.UTF8);
  AppendFixtureText(TPath.Combine(FDir, 'README.md'),
    sLineBreak + '## Extra Feature' + sLineBreak + 'New capability implementation.' + sLineBreak,
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

procedure TTestAsWishGUIDecisions.Test_Version_Constant_Defined;
begin
  Assert.AreEqual('0.1.0', ASWISH_VERSION);
  Assert.AreEqual('AsWish v0.1.0', ASWISH_BANNER);
end;

procedure TTestAsWishGUIDecisions.Test_DualSurface_D1_TreeFromNodePrefix_Inference;
begin
  Assert.AreEqual(ttFunction, TSpecEnums.TreeFromNodePrefix('func-order-checkout'));
  Assert.AreEqual(ttModule, TSpecEnums.TreeFromNodePrefix('mod-billing-service'));
  Assert.AreEqual(ttView, TSpecEnums.TreeFromNodePrefix('view-main-form'));
  Assert.AreEqual(ttData, TSpecEnums.TreeFromNodePrefix('data-customer-table'));
  Assert.AreEqual(ttFunction, TSpecEnums.TreeFromNodePrefix('custom-unprefixed-node'));
end;

procedure TTestAsWishGUIDecisions.Test_DualSurface_D1_SubmitUserIntent_WithTreeInference;
var
  LCsId: string;
  LIngest: TAsWishCandidateIngest;
  LCs: TChangeSet;
begin
  LIngest := TAsWishCandidateIngest.Create(FStore);
  try
    // Submit intent for module node
    LCsId := FController.SubmitUserIntent('mod-billing-service',
      TSpecEnums.TreeFromNodePrefix('mod-billing-service'), 'Add invoice validation');
    Assert.IsNotEmpty(LCsId);

    LCs := LIngest.LoadChangeSet(FDir, LCsId);
    Assert.AreEqual('mod-billing-service', LCs.IntentNodeId);
    Assert.AreEqual(ttModule, LCs.IntentTree);
    Assert.AreEqual('Add invoice validation', LCs.RawUserIntent);

    // Submit intent for view node
    LCsId := FController.SubmitUserIntent('view-main-form',
      TSpecEnums.TreeFromNodePrefix('view-main-form'), 'Add responsive grid layout');
    Assert.IsNotEmpty(LCsId);

    LCs := LIngest.LoadChangeSet(FDir, LCsId);
    Assert.AreEqual('view-main-form', LCs.IntentNodeId);
    Assert.AreEqual(ttView, LCs.IntentTree);
    Assert.AreEqual('Add responsive grid layout', LCs.RawUserIntent);
  finally
    LIngest.Free;
  end;
end;

procedure TTestAsWishGUIDecisions.Test_DualSurface_D2_Ghosts_MatchingAndNarrativeBadge;
var
  LMatches: TArray<TSpecCommonsLesson>;
  LBadgeText: string;
begin
  // S-4 machine lesson matching
  LMatches := FController.Commons.FindMatchingLessons('func-payment-retry');
  Assert.IsTrue(Length(LMatches) > 0, 'Must match lesson-0009');
  Assert.AreEqual('lesson-0009', LMatches[0].Id);
  Assert.AreEqual('machine', LMatches[0].AnchorKind);

  // S-4 narrative lesson matching
  LMatches := FController.Commons.FindMatchingLessons('status=disabled and delete requested');
  Assert.IsTrue(Length(LMatches) > 0, 'Must match lesson-0001');
  Assert.AreEqual('lesson-0001', LMatches[0].Id);
  Assert.AreEqual('narrative', LMatches[0].AnchorKind);

  // Verify narrative badge generation format
  if SameText(LMatches[0].AnchorKind, 'narrative') then
    LBadgeText := '这类分叉曾错在 ' + LMatches[0].Title + '（' + LMatches[0].Id + '） [经验总结，非可复核记录]'
  else
    LBadgeText := '这类分叉曾错在 ' + LMatches[0].Title + '（' + LMatches[0].Id + '）';

  Assert.IsTrue(LBadgeText.Contains('[经验总结，非可复核记录]'), 'Narrative lesson badge must contain disclaimer');
end;

procedure TTestAsWishGUIDecisions.Test_CaptureConstraint_CheckBoxState_WindowScreenshotInert_ControlCaptureDiverges;
var
  LForm: TForm;
  LChk: TCheckBox;
  LWinUnchecked, LWinChecked, LCtrlUnchecked, LCtrlChecked: Vcl.Graphics.TBitmap;
  LDiag: string;
  LWinUncheckedStream, LWinCheckedStream, LCtrlUncheckedStream, LCtrlCheckedStream: TMemoryStream;
  LBottomPanel, LDeckPanel: TPanel;
begin
  // 1. Invariant: TCaptureMode semantic contract
  Assert.IsFalse(CaptureModeReflectsLiveState(cmWindowScreenshot),
    'cmWindowScreenshot must declare that it cannot reflect live control state');
  Assert.IsTrue(CaptureModeReflectsLiveState(cmDirectControlDc),
    'cmDirectControlDc must declare that it reflects live control state');

  // 2. Physical measurement: CheckBox state reflection on real VCL controls
  LForm := TForm.Create(nil);
  try
    LForm.SetBounds(100, 100, 300, 200);
    LForm.Visible := True;
    ShowWindow(LForm.Handle, SW_SHOW);
    LForm.Update;
    Application.ProcessMessages;

    LBottomPanel := TPanel.Create(LForm);
    LBottomPanel.Parent := LForm;
    LBottomPanel.SetBounds(10, 20, 200, 40);

    LDeckPanel := TPanel.Create(LBottomPanel);
    LDeckPanel.Parent := LBottomPanel;
    LDeckPanel.SetBounds(0, 0, 200, 30);

    LChk := TCheckBox.Create(LDeckPanel);
    LChk.Parent := LDeckPanel;
    LChk.SetBounds(0, 0, 132, 28);
    LChk.Caption := 'Evidence Opt-In';
    LChk.Checked := False;
    LChk.Visible := True;
    LForm.Update;
    Application.ProcessMessages;

    // Capture Unchecked: PaintTo (window screenshot baseline) vs Direct DC
    LWinUnchecked := Vcl.Graphics.TBitmap.Create;
    LWinUnchecked.SetSize(LChk.Width, LChk.Height);
    LChk.PaintTo(LWinUnchecked.Canvas.Handle, 0, 0);

    LCtrlUnchecked := Vcl.Graphics.TBitmap.Create;
    try
      Assert.IsTrue(CaptureControlBitmapDirect(LChk, LCtrlUnchecked, LDiag), 'Control capture unchecked failed: ' + LDiag);

      // Mutate state to Checked
      LChk.Checked := True;
      InvalidateRect(LChk.Handle, nil, True);
      UpdateWindow(LChk.Handle);
      Application.ProcessMessages;

      // Capture Checked: PaintTo (window screenshot baseline) vs Direct DC
      LWinChecked := Vcl.Graphics.TBitmap.Create;
      LWinChecked.SetSize(LChk.Width, LChk.Height);
      LChk.PaintTo(LWinChecked.Canvas.Handle, 0, 0);

      LCtrlChecked := Vcl.Graphics.TBitmap.Create;
      try
        Assert.IsTrue(CaptureControlBitmapDirect(LChk, LCtrlChecked, LDiag), 'Control capture checked failed: ' + LDiag);

        // Serialize to stream for strict byte-for-byte comparison
        LWinUncheckedStream := TMemoryStream.Create;
        LWinCheckedStream := TMemoryStream.Create;
        LCtrlUncheckedStream := TMemoryStream.Create;
        LCtrlCheckedStream := TMemoryStream.Create;
        try
          LWinUnchecked.SaveToStream(LWinUncheckedStream);
          LWinChecked.SaveToStream(LWinCheckedStream);
          LCtrlUnchecked.SaveToStream(LCtrlUncheckedStream);
          LCtrlChecked.SaveToStream(LCtrlCheckedStream);

          // Fact A: Window screenshot (PaintTo) produces IDENTICAL bytes (cannot capture CheckBox checked state)
          Assert.IsTrue(CompareMem(LWinUncheckedStream.Memory, LWinCheckedStream.Memory, LWinUncheckedStream.Size),
            'Window screenshot (PaintTo) fails to capture CheckBox checked state (bytes identical)');
          // Fact B: Direct control DC capture produces DIFFERENT bytes (captures real screen pixels)
          Assert.IsFalse(CompareMem(LCtrlUncheckedStream.Memory, LCtrlCheckedStream.Memory, LCtrlUncheckedStream.Size),
            'Direct control DC capture MUST capture CheckBox state divergence (bytes differ)');
        finally
          LWinUncheckedStream.Free;
          LWinCheckedStream.Free;
          LCtrlUncheckedStream.Free;
          LCtrlCheckedStream.Free;
        end;
      finally
        LCtrlChecked.Free;
        LWinChecked.Free;
      end;
    finally
      LCtrlUnchecked.Free;
      LWinUnchecked.Free;
    end;
  finally
    LForm.Free;
  end;
end;

procedure TTestAsWishGUIDecisions.Test_WindowScreenshot_SingleColorGuard_RejectsBlank_AndEmitsWarning;
var
  LBmp: Vcl.Graphics.TBitmap;
  LTempFile: string;
  LDiag: string;
  LWarnings: TStringList;
begin
  LTempFile := TPath.Combine(FDir, 'test-blank-guard.png');
  LBmp := Vcl.Graphics.TBitmap.Create;
  LWarnings := TStringList.Create;
  try
    LBmp.SetSize(200, 100);
    LBmp.Canvas.Brush.Color := clBlack;
    LBmp.Canvas.FillRect(Rect(0, 0, 200, 100));

    // Attempt save with content guard
    if not SaveBitmapWithContentGuard(LBmp, LTempFile, LDiag, 4) then
      LWarnings.Add('[CAPTURE-WARN] ' + LDiag);

    // Assert (a): File was NOT written
    Assert.IsFalse(TFile.Exists(LTempFile), 'Pure color bitmap must not be written to disk');
    // Assert (b): Warning was recorded
    Assert.AreEqual(1, LWarnings.Count, 'A capture warning must be emitted');
    Assert.IsTrue(LWarnings[0].Contains('[CAPTURE-WARN]'), 'Warning must contain [CAPTURE-WARN]');
    Assert.IsTrue(LWarnings[0].Contains('distinctColors=1'), 'Warning must report distinctColors=1');
    Assert.IsTrue(LWarnings[0].Contains('no visual evidence emitted'), 'Warning must state no visual evidence emitted');

    // Multi-color bitmap must pass
    LBmp.Canvas.Pixels[10, 10] := clWhite;
    LBmp.Canvas.Pixels[20, 20] := clRed;
    LWarnings.Clear;
    Assert.IsTrue(SaveBitmapWithContentGuard(LBmp, LTempFile, LDiag, 4), 'Multi-color bitmap should be saved');
    Assert.IsTrue(TFile.Exists(LTempFile), 'Multi-color bitmap must be written to disk');
    Assert.AreEqual(0, LWarnings.Count, 'No warning should be emitted for multi-color bitmap');
  finally
    LWarnings.Free;
    LBmp.Free;
    if TFile.Exists(LTempFile) then
      TFile.Delete(LTempFile);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishGUIDecisions);

end.
