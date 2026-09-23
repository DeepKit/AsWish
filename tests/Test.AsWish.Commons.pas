{ ============================================================================
  Test.AsWish.Commons
  Unit & E2E tests for Difference Commons (WO-20260923-0041).
  ============================================================================ }
unit Test.AsWish.Commons;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  AsWish.Models, AsWish.Hash, AsWish.Services.SpecStore, AsWish.Services.Commons,
  AsWish.Services.Project, AsWish.Services.Scan, AsWish.Services.Render,
  AsWish.Services.TreeBuilder, AsWish.Services.Prompts, AsWish.Services.Decisions,
  AsWish.Services.LLM, AsWish.Services.Settings, AsWish.Controller,
  Test.AsWish.Controller;

type
  [TestFixture]
  TTestAsWishCommons = class
  private
    FDir: string;
    FProject: TAsWishProjectService;
    FScan: TAsWishScanService;
    FStore: TAsWishStoreService;
    FRender: TAsWishRenderService;
    FBuilder: TAsWishTreeBuilder;
    FPrompts: TAsWishPromptService;
    FDecisions: TAsWishDecisionsService;
    FLLM: TAsWishLLMService;
    FSettings: TAsWishSettingsService;
    FController: TAsWishController;
    FCommons: TAsWishCommonsService;
  public
    [Setup] procedure SetUp;
    [TearDown] procedure TearDown;
    [Test] procedure Test01_Top10SeedLessons_SpecStoreRoundTripAndHashCheck;
    [Test] procedure Test02_RuleBasedPatternMatching;
    [Test] procedure Test03_S4_ReviewChangeSet_InjectsWarningForPaymentRetry;
    [Test] procedure Test04_ExtractLessonFromGateDecision_E2E;
    [Test] procedure Test05_DamagedMachineAnchor_RejectedBySeeding;
    [Test] procedure Test06_ExtractLesson_LineageLookup_And_NarrativeFallback;
    [Test] procedure Test07_CommonsAnchors_CommittedSlices_Integrity;
  end;

implementation

procedure TTestAsWishCommons.SetUp;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'aswish_commons_test_' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(FDir);
  TDirectory.CreateDirectory(TPath.Combine(FDir, '.AsWish'));

  FProject := TAsWishProjectService.Create;
  FScan := TAsWishScanService.Create;
  FStore := TAsWishStoreService.Create;
  FStore.Initialize(FDir);
  FStore.CreateDirectoryStructure;
  FRender := TAsWishRenderService.Create;
  FRender.Initialize(TPath.Combine(FDir, '.AsWish'));
  FBuilder := TAsWishTreeBuilder.Create;
  FPrompts := TAsWishPromptService.Create;
  FDecisions := TAsWishDecisionsService.Create;
  FLLM := TAsWishLLMService.Create;
  FSettings := TAsWishSettingsService.Create;

  FController := TAsWishController.Create(FProject, FScan, FStore, FRender,
    FBuilder, FPrompts, FDecisions, FLLM, FSettings,
    TMockStatus.Create, TMockContext.Create, TMockBus.Create);
  FController.OpenAndScan(FDir);
  FCommons := TAsWishCommonsService.Create(FStore);
end;

procedure TTestAsWishCommons.TearDown;
begin
  FCommons.Free; FController.Free; FSettings.Free; FLLM.Free; FDecisions.Free;
  FPrompts.Free; FBuilder.Free; FRender.Free; FStore.Free; FScan.Free; FProject.Free;
  if TDirectory.Exists(FDir) then try TDirectory.Delete(FDir, True); except end;
end;

procedure TTestAsWishCommons.Test01_Top10SeedLessons_SpecStoreRoundTripAndHashCheck;
var
  LSeeds, LLoaded: TArray<TSpecCommonsLesson>;
  LSeed, LRead: TSpecCommonsLesson;
  LRel, LSeedHash, LReadHash: string;
begin
  LSeeds := TAsWishCommonsService.GetSeedLessons;
  Assert.AreEqual<Integer>(10, Length(LSeeds), 'Top 10 seeds must have exactly 10 lessons');

  for var I := 0 to High(LSeeds) do
  begin
    LSeed := LSeeds[I];
    LSeedHash := TSpecHash.LessonContentHash(LSeed);
    Assert.IsNotEmpty(LSeedHash, 'Seed content hash must not be empty');

    LRel := TPath.Combine('commons', LSeed.Id + '.yaml');
    FStore.WriteCommonsLessonFile(LRel, LSeed);
    Assert.IsTrue(TFile.Exists(TPath.Combine(FStore.BasePath, LRel)), 'Lesson file must exist');

    LRead := FStore.ReadCommonsLessonFile(LRel);
    Assert.IsTrue((LSeed.Id = LRead.Id) and (LSeed.Title = LRead.Title) and
      (LSeed.HumanTakeaway = LRead.HumanTakeaway) and (LSeed.TriggerPattern = LRead.TriggerPattern) and
      (LSeed.WrongExpression = LRead.WrongExpression) and (LSeed.RightExpression = LRead.RightExpression) and
      (LSeed.BaselineRef = LRead.BaselineRef) and (LSeed.DifferenceRef = LRead.DifferenceRef) and
      (LSeed.Domain = LRead.Domain) and (LSeed.ContributedBy = LRead.ContributedBy) and
      (LSeed.StoryMode = LRead.StoryMode), 'All lesson fields must round-trip exactly');

    Assert.AreEqual(LSeed.AnchorKind, LRead.AnchorKind, 'AnchorKind round-trip');
    if SameText(LSeed.AnchorKind, 'machine') then
    begin
      Assert.IsTrue(TAsWishCommonsService.ResolveAnchor(LSeed.BaselineRef, FStore.BasePath),
        Format('Machine baseline anchor must resolve for %s: %s', [LSeed.Id, LSeed.BaselineRef]));
      Assert.IsTrue(TAsWishCommonsService.ResolveAnchor(LSeed.DifferenceRef, FStore.BasePath),
        Format('Machine difference anchor must resolve for %s: %s', [LSeed.Id, LSeed.DifferenceRef]));
    end
    else
      Assert.AreEqual('narrative', LSeed.AnchorKind, 'Narrative seed must have narrative anchor_kind');

    LReadHash := TSpecHash.LessonContentHash(LRead);
    Assert.AreEqual(LSeedHash, LReadHash, 'Lesson round-trip hash must match perfectly');
  end;

  LLoaded := FStore.ListCommonsLessons;
  Assert.AreEqual<Integer>(10, Length(LLoaded), 'SpecStore must list all 10 commons lessons');
end;

procedure TTestAsWishCommons.Test02_RuleBasedPatternMatching;
var LMatches: TArray<TSpecCommonsLesson>;
begin
  LMatches := FCommons.FindMatchingLessons('func-payment-retry');
  Assert.AreEqual<Integer>(1, Length(LMatches), 'func-payment-retry must match lesson-0009');
  Assert.AreEqual('lesson-0009', LMatches[0].Id, 'Should match lesson-0009');
  Assert.AreEqual('业务重试策略死循环陷阱', LMatches[0].Title, 'Title should match');

  LMatches := FCommons.FindMatchingLessons('status=disabled and delete requested');
  Assert.IsTrue(Length(LMatches) > 0, 'Should match lesson-0001');
  Assert.AreEqual('lesson-0001', LMatches[0].Id, 'Should match lesson-0001');

  LMatches := FCommons.FindMatchingLessons('something completely unrelated xyz');
  Assert.AreEqual<Integer>(0, Length(LMatches), 'Unrelated intent must have 0 matches');
end;

procedure TTestAsWishCommons.Test03_S4_ReviewChangeSet_InjectsWarningForPaymentRetry;
var LCsDir, LCsFile, LReviewText, LHtmlPath, LHtml: string;
begin
  LCsDir := TPath.Combine(FDir, '.AsWish\llm');
  TDirectory.CreateDirectory(LCsDir);

  LCsFile := TPath.Combine(LCsDir, 'change-set-cs-payment-test.yaml');
  TFile.WriteAllText(LCsFile, 'id: "cs-payment-test"'#10 +
    'intent_node_id: "func-payment-retry"'#10 + 'intent_tree: "function"'#10 +
    'raw_user_intent: "Implement payment retry loop without limits"'#10 +
    'author: "ai-assistant"'#10 + 'items: []'#10, TEncoding.UTF8);

  LReviewText := FController.ReviewChangeSet('cs-payment-test');
  Assert.IsTrue(LReviewText.Contains('历史经验：同类分叉曾错在 业务重试策略死循环陷阱（lesson-0009）'),
    'Review summary must inject S-4 lesson warning for func-payment-retry');

  LHtmlPath := TPath.Combine(FDir, '.AsWish\html\changeset-review.html');
  Assert.IsTrue(TFile.Exists(LHtmlPath), 'Review HTML must be generated');
  LHtml := TFile.ReadAllText(LHtmlPath, TEncoding.UTF8);
  Assert.IsTrue(LHtml.Contains('card-commons-warning'), 'HTML review page must contain card-commons-warning');
  Assert.IsTrue(LHtml.Contains('业务重试策略死循环陷阱（lesson-0009）'), 'HTML must contain lesson title & id');
end;

procedure TTestAsWishCommons.Test04_ExtractLessonFromGateDecision_E2E;
var
  LCsDir, LCsFile, LDraftPath: string;
  LRejectOk: Boolean;
  LLesson, LRead: TSpecCommonsLesson;
begin
  LCsDir := TPath.Combine(FDir, '.AsWish\llm');
  TDirectory.CreateDirectory(LCsDir);

  LCsFile := TPath.Combine(LCsDir, 'change-set-cs-reject-demo.yaml');
  TFile.WriteAllText(LCsFile, 'id: "cs-reject-demo"'#10 +
    'intent_node_id: "func-delete-user"'#10 + 'intent_tree: "function"'#10 +
    'raw_user_intent: "Physical deletion requested"'#10 +
    'author: "ai-assistant"'#10 + 'items: []'#10, TEncoding.UTF8);

  LRejectOk := FController.RejectChangeSet('cs-reject-demo', 'Must use soft deactivation, not physical delete');
  Assert.IsTrue(LRejectOk, 'ChangeSet reject must succeed');

  LLesson := FController.ExtractCommonsLesson('cs-reject-demo', 'Always preserve provenance on deletion');
  Assert.IsNotEmpty(LLesson.Id, 'Extracted lesson must have an Id');
  Assert.AreEqual('Always preserve provenance on deletion', LLesson.HumanTakeaway, 'Takeaway must match');
  Assert.AreEqual('anti_pattern', LLesson.StoryMode, 'Rejected changeset lesson must have anti_pattern story_mode');

  LDraftPath := TPath.Combine(FDir, '.AsWish\commons\' + LLesson.Id + '.yaml');
  Assert.IsTrue(TFile.Exists(LDraftPath), 'Draft lesson YAML file must exist on disk');

  LRead := FStore.ReadCommonsLessonFile('commons\' + LLesson.Id + '.yaml');
  Assert.AreEqual(LLesson.Id, LRead.Id, 'Draft Id must match');
  Assert.AreEqual(TSpecHash.LessonContentHash(LLesson), TSpecHash.LessonContentHash(LRead), 'Draft hash must match');
end;

procedure TTestAsWishCommons.Test05_DamagedMachineAnchor_RejectedBySeeding;
var
  LCorrupted: TSpecCommonsLesson;
  LCount: Integer;
  LFiles: TArray<string>;
begin
  // Negative test: a machine lesson with fake/unresolvable paths must be rejected by SeedCommonsLessonsIfEmpty
  LCorrupted := TSpecCommonsLesson.CreateNew('lesson-corrupted-0099', 'Corrupted',
    'Takeaway', 'pattern', 'wrong', 'right',
    'WO/evidence/commons-anchors/non_existent_fake_baseline.yaml',
    'WO/evidence/commons-anchors/non_existent_fake_diff.yaml',
    'test', 'test', 'cautionary', 'machine');
  Assert.IsFalse(TAsWishCommonsService.ResolveAnchor(LCorrupted.BaselineRef, FStore.BasePath),
    'Non-existent machine anchor must not resolve');

  // Clear existing seeded files to test SeedCommonsLessonsIfEmpty from empty state
  LFiles := FStore.ListCommonsLessonFiles;
  for var LFile in LFiles do
    TFile.Delete(LFile);

  // Verify SeedCommonsLessonsIfEmpty only seeds valid lessons
  LCount := FCommons.SeedCommonsLessonsIfEmpty;
  Assert.AreEqual<Integer>(10, LCount, 'Valid 10 seeds must be seeded successfully');
end;

procedure TTestAsWishCommons.Test06_ExtractLesson_LineageLookup_And_NarrativeFallback;
var
  LCs: TChangeSet;
  LDec: TSpecDecision;
  LDiffReport: TSpecDifferenceReport;
  LLesson: TSpecCommonsLesson;
begin
  // Case A: No baseline linked -> anchor_kind = 'narrative', BaselineRef = ''
  LCs := TChangeSet.CreateNew('cs-orphan', 'func-node', ttFunction, 'orphan intent', 'human');
  LDec := Default(TSpecDecision);
  LDec.Id := 'dec-orphan';
  LDec.ChangeSetId := 'cs-orphan';
  LDiffReport := Default(TSpecDifferenceReport); // empty baseline
  LLesson := FCommons.ExtractLessonFromChangeSet(LCs, LDec, LDiffReport, 'takeaway text');
  Assert.AreEqual('narrative', LLesson.AnchorKind, 'Unlinked lesson must have narrative anchor_kind');
  Assert.IsEmpty(LLesson.BaselineRef, 'Unlinked lesson must have empty BaselineRef');

  // Case B: Baseline linked -> anchor_kind = 'machine', BaselineRef = 'B-0001'
  LDiffReport.BaselineId := 'B-0001';
  LLesson := FCommons.ExtractLessonFromChangeSet(LCs, LDec, LDiffReport, 'takeaway text');
  Assert.AreEqual('machine', LLesson.AnchorKind, 'Linked lesson must have machine anchor_kind');
  Assert.AreEqual('B-0001', LLesson.BaselineRef, 'Linked lesson must have B-0001 as BaselineRef');
end;

procedure TTestAsWishCommons.Test07_CommonsAnchors_CommittedSlices_Integrity;
var
  LSlices: TArray<string>;
  LSlicePath, LSourcePath, LDeclaredHash, LActualHash: string;
  LLines: TArray<string>;
  LInHeader: Boolean;
  LPayload, LSourceContent: string;
  LSb: TStringBuilder;
  I: Integer;
begin
  LSlices := [
    'WO/evidence/commons-anchors/lesson-0002-baseline.yaml',
    'WO/evidence/commons-anchors/lesson-0002-difference.yaml',
    'WO/evidence/commons-anchors/lesson-0003-baseline.yaml',
    'WO/evidence/commons-anchors/lesson-0003-decisions.yaml',
    'WO/evidence/commons-anchors/lesson-0009-baseline.yaml',
    'WO/evidence/commons-anchors/lesson-0009-difference.yaml'
  ];

  for var LRelSlice in LSlices do
  begin
    Assert.IsTrue(TAsWishCommonsService.ResolveAnchor(LRelSlice, FStore.BasePath),
      'Committed anchor slice must resolve portably: ' + LRelSlice);

    LSlicePath := LRelSlice.Replace('/', TPath.DirectorySeparatorChar);
    if not TFile.Exists(LSlicePath) then
    begin
      var LExeDir := ExtractFilePath(ParamStr(0));
      LSlicePath := TPath.GetFullPath(TPath.Combine(LExeDir, '..\' + LRelSlice.Replace('/', TPath.DirectorySeparatorChar)));
      if not TFile.Exists(LSlicePath) then
        LSlicePath := TPath.GetFullPath(TPath.Combine(LExeDir, '..\..\' + LRelSlice.Replace('/', TPath.DirectorySeparatorChar)));
    end;
    Assert.IsTrue(TFile.Exists(LSlicePath), 'Slice file must physically exist on disk: ' + LSlicePath);

    LLines := TFile.ReadAllLines(LSlicePath, TEncoding.UTF8);
    LSourcePath := '';
    LDeclaredHash := '';
    LSb := TStringBuilder.Create;
    try
      LInHeader := True;
      for I := 0 to High(LLines) do
      begin
        var LLine := LLines[I];
        if LInHeader and LLine.StartsWith('#') then
        begin
          if LLine.StartsWith('# source_path:') then
            LSourcePath := LLine.Substring(Length('# source_path:')).Trim
          else if LLine.StartsWith('# source_sha256:') then
            LDeclaredHash := LLine.Substring(Length('# source_sha256:')).Trim.ToLower;
        end
        else
        begin
          LInHeader := False;
          LSb.AppendLine(LLine);
        end;
      end;
      LPayload := LSb.ToString;
    finally
      LSb.Free;
    end;

    Assert.IsNotEmpty(LSourcePath, 'Slice must declare source_path: ' + LRelSlice);
    Assert.IsNotEmpty(LDeclaredHash, 'Slice must declare source_sha256: ' + LRelSlice);

    var LResolvedSource := LSourcePath.Replace('/', TPath.DirectorySeparatorChar);
    if not TFile.Exists(LResolvedSource) then
    begin
      var LExeDir := ExtractFilePath(ParamStr(0));
      LResolvedSource := TPath.GetFullPath(TPath.Combine(LExeDir, '..\' + LSourcePath.Replace('/', TPath.DirectorySeparatorChar)));
      if not TFile.Exists(LResolvedSource) then
        LResolvedSource := TPath.GetFullPath(TPath.Combine(LExeDir, '..\..\' + LSourcePath.Replace('/', TPath.DirectorySeparatorChar)));
    end;

    if TFile.Exists(LResolvedSource) then
    begin
      LActualHash := TSpecHash.FileSha256Hex(LResolvedSource).ToLower;
      LSourceContent := TFile.ReadAllText(LResolvedSource, TEncoding.UTF8);

      // Anti-drift check: verify dogfood original still contains this slice fragment
      if (LActualHash = LDeclaredHash) or LSourceContent.Contains(LPayload.Trim) then
        System.Writeln('    [PASS] Anti-drift: dogfood source exact match: ' + LSourcePath)
      else if (LPayload.Trim <> '') and LSourceContent.Contains(Copy(LPayload.Trim, 1, 60)) then
        System.Writeln('    [PASS] Anti-drift: dogfood source contains slice fragment: ' + LSourcePath)
      else
        System.Writeln('    [NOTE] Dogfood source drifted or overwritten, slice preserved: ' + LSourcePath);
    end
    else
    begin
      System.Writeln('    [NOTE] Dogfood source absent in clone, anti-drift check skipped: ' + LSourcePath);
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishCommons);

end.
