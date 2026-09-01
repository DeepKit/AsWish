# 实现计划：BUG-9 健康度看板（RenderIndex 重构 + 优化 Prompt 入口）

## Context（给无背景的实施者）

DeepSpec 是一个 Delphi/Object Pascal 写的「开发文档优化器」：读项目文档/代码/配置 → 生成 `.deepspec/` 下的 YAML（4 棵 spec 树：function/module/view/data + issues）→ 渲染静态 HTML 供 WebView2 审阅。三合一主线（雾→ticket→看板）的前两步（BUG-8 闭环、BUG-11 issues 数据层 + ticket 创建双入口）已完成并归档。

本步是主线的**第 3 步 BUG-9**：把当前极简的 `RenderIndex`（只有页面列表）升级成「健康度看板」，并接上「导出优化 Prompt」的 JS Bridge 入口。设计 spec：`docs/superpowers/specs/2026-07-09-bug9-health-dashboard-design.md`。

**关键事实：**
- `RenderIndex` 当前签名 `RenderIndex(const AProjectName: string; ATotalFiles: Integer; AHasDataTree: Boolean = True)`（`Render.pas:36` 声明 / `:165` 实现）。
- 它被调用 3 处：`Controller.pas:332`（RenderAll）、`:391`（RefreshFromYaml）、`:800`（RunScan）。**每处调用后**紧随的代码已为 `RenderProblemsPage` 算好节点列表 + `LoadIssuesForRender`——本步复用这些，不新增 IO。
- JS Bridge 路由在 `DeepSpec.Providers.MainView.pas` 的 `TBrowserNavigator.HandleWebMessage`，按 `action` 字段分发；已有 `node-confirm`/`node-reject`/`ticket-create`。新增 `export-optimization-prompt` 沿用同一模式（三层闭包：`TExportPromptProc`）。
- 编译方式：dcc64 直接从 Git-Bash 调用（见 memory `delphi-build-via-bash`）——**不要**用 .bat（cmd /c 下会失败）。
- Delphi 语法约束：**无**三元 `?:`；interface-uses 与 implementation-uses 不能出现同一单元（E2004）；`TrimRight(s)` 而非 `s.TrimEnd`；匿名方法 `reference to procedure` 可作参数/字段。

**枚举（来自 `DeepSpec.Models.pas`）：**
```
TConfidenceLevel = (clLow, clMedium, clHigh);
TIssueSeverity   = (isCritical, isHigh, isMedium, isLow, isInfo);
TIssueStatus    = (issOpen, issResolved, issWontfix, issDeferred);
TFogState        = (fsClear, fsMisty, fsFoggy, fsUnknownUnknowns);
TSpecIssue 字段：Id, Severity:TIssueSeverity, IssueType:TIssueType, Title, Status:TIssueStatus, ...
TSpecNode  字段：Id, Title, Confidence:TConfidenceLevel, FogState:TFogState, HasFogState:Boolean, RelatedModules/Views/Data: TArray<string>, GenStatus, ReviewStatus ...
TSpecEnums 静态 helper：ConfidenceToStr / FogStateToStr / IssueSeverityToStr / IssueStatusToStr / DefogOneStep
```

**confidence→数值映射（spec §2.2）：** clLow=0.3, clMedium=0.7, clHigh=1.0。

---

## 文件结构

| 文件 | 责任 | 改动类型 |
|------|------|----------|
| `src/services/DeepSpec.Services.Render.pas` | 渲染服务；新增健康度纯函数 `THealthMetrics`/`ComputeHealthMetrics` + 共享 `CountCrossTreeConflicts`；扩展 `RenderIndex` 渲染 4 看板区域 | 改 |
| `src/controllers/DeepSpec.Controller.pas` | 3 处 RenderIndex 调用传节点+issues；新增 `ExportOptimizationPrompt` | 改 |
| `src/providers/DeepSpec.Providers.MainView.pas` | `TExportPromptProc` + `FOnExportOptimizationPrompt`；`HandleWebMessage` 加分支；穿线 | 改 |
| `src/app/DeepSpec.Providers.pas` | `RegisterAllProviders` 加第二个闭包 | 改 |
| `tests/Test.DeepSpec.Models.pas` | `THealthMetricsTests`，4 例 | 改 |

不新建单元（健康度 helper 放 Render.pas，与既有局部 helper 同域）。

---

## Task 1：Render.pas — 健康度纯函数 + 单测先行（TDD）

> 目标：先写 `THealthMetrics` + `ComputeHealthMetrics` 纯函数并配单测。`CountCrossTreeConflicts` 也在此 task 一并落地（RenderProblemsPage 与 RenderIndex 都要用）。

**Context for this task：** Render.pas 的 interface 区在第 19-46 行声明 `TDeepSpecRenderService`。私有 helper（`FogStateCssClass` 等）在 `private` 区第 22-31 行。`ComputeHealthMetrics`/`CountCrossTreeConflicts` 放进同一 class 作为 `private` 类方法，便于单测可见性（单测文件 uses Render 单元，通过 `TDeepSpecRenderService` 类访问 class 方法）。**但单测需直接调它们**——故声明为 `public`。

- [ ] **Step 1：写失败单测**

打开 `tests/Test.DeepSpec.Models.pas`，在文件末尾、最后一个 `initialization` 之前追加 fixture。先确认文件末尾结构：

Run: `tail -30 "D:/_Progs/02Business/DeepSpec/tests/Test.DeepSpec.Models.pas"`

追加以下 fixture（注意：`ComputeHealthMetrics` 在 `DeepSpec.Services.Render` 单元，故此测试文件需 uses 该单元）：

```pascal
{ THealthMetricsTests — BUG-9 health metrics (pure function) }

interface

type
  [TestFixture]
  THealthMetricsTests = class
  public
    [Test] procedure Coverage_Partial;
    [Test] procedure AvgConfidence_Mixed;
    [Test] procedure FogCount_AcrossTrees;
    [Test] procedure Backlog_OpenOnly;
  end;

implementation

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  DeepSpec.Models,
  DeepSpec.Services.Render;   // TDeepSpecRenderService.ComputeHealthMetrics

{ 由于 ComputeHealthMetrics 是 TDeepSpecRenderService 的 public class function，
  构造节点 list 传入。此处只验纯计算，不写文件。 }

procedure THealthMetricsTests.Coverage_Partial;
var
  LList: TList<TSpecNode>;
  LEmpty: TList<TSpecNode>;
  LM: THealthMetrics;
  LN: TSpecNode;
begin
  LList := TList<TSpecNode>.Create;
  LEmpty := TList<TSpecNode>.Create;
  try
    // 2 confirmed (gen_status assumed mapped) + 1 candidate => coverage 2/3
    LN := Default(TSpecNode); LN.Id := 'f1'; LN.Title := 'A'; LN.Confidence := clHigh;
    LN.GenStatus := 'confirmed'; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'f2'; LN.Title := 'B'; LN.Confidence := clHigh;
    LN.GenStatus := 'confirmed'; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'f3'; LN.Title := 'C'; LN.Confidence := clMedium;
    LN.GenStatus := 'candidate'; LList.Add(LN);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LList, LEmpty, LEmpty, LEmpty);
    Assert.AreEqual(3, LM.TotalNodes);
    Assert.AreEqual(2, LM.ConfirmedNodes);
    Assert.AreEqual(Double(66.666), Double(LM.CoveragePct), 0.5);  // ~66.7%
  finally
    LList.Free; LEmpty.Free;
  end;
end;

procedure THealthMetricsTests.AvgConfidence_Mixed;
var
  LList: TList<TSpecNode>;
  LEmpty: TList<TSpecNode>;
  LM: THealthMetrics;
  LN: TSpecNode;
begin
  LList := TList<TSpecNode>.Create;
  LEmpty := TList<TSpecNode>.Create;
  try
    // low(0.3) + medium(0.7) + high(1.0) => avg 0.6667
    LN := Default(TSpecNode); LN.Id := 'a'; LN.Confidence := clLow; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'b'; LN.Confidence := clMedium; LList.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'c'; LN.Confidence := clHigh; LList.Add(LN);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LList, LEmpty, LEmpty, LEmpty);
    Assert.AreEqual(Double(0.6667), LM.AvgConfidence, 0.01);
  finally
    LList.Free; LEmpty.Free;
  end;
end;

procedure THealthMetricsTests.FogCount_AcrossTrees;
var
  LF, LMd, LV, LD: TList<TSpecNode>;
  LM: THealthMetrics;
  LN: TSpecNode;
begin
  LF := TList<TSpecNode>.Create; LMd := TList<TSpecNode>.Create;
  LV := TList<TSpecNode>.Create;  LD := TList<TSpecNode>.Create;
  try
    // function: 1 foggy + 1 clear ; module: 1 unknown_unknowns ; view: clear ; data: 1 misty
    LN := Default(TSpecNode); LN.Id := 'f1'; LN.HasFogState := True; LN.FogState := fsFoggy; LF.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'f2'; LN.HasFogState := False; LN.FogState := fsClear; LF.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'm1'; LN.HasFogState := True; LN.FogState := fsUnknownUnknowns; LMd.Add(LN);
    LN := Default(TSpecNode); LN.Id := 'd1'; LN.HasFogState := True; LN.FogState := fsMisty; LD.Add(LN);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LF, LMd, LV, LD);
    Assert.AreEqual(3, LM.FogCount);  // foggy + unknown_unknowns + misty
  finally
    LF.Free; LMd.Free; LV.Free; LD.Free;
  end;
end;

procedure THealthMetricsTests.Backlog_OpenOnly;
var
  LNodes, LEmpty: TList<TSpecNode>;
  LIssues: TList<TSpecIssue>;
  LM: THealthMetrics;
  LN: TSpecNode;
  LI: TSpecIssue;
begin
  LNodes := TList<TSpecNode>.Create; LEmpty := TList<TSpecNode>.Create;
  LIssues := TList<TSpecIssue>.Create;
  try
    LN := Default(TSpecNode); LN.Id := 'x'; LN.Confidence := clHigh; LN.GenStatus := 'confirmed';
    LNodes.Add(LN);
    // 2 open + 1 resolved => backlog 2 ; 1 open high-severity => HighRiskOpen 1
    LI := Default(TSpecIssue); LI.Id := 'i1'; LI.Status := issOpen; LI.Severity := isHigh;
    LIssues.Add(LI);
    LI := Default(TSpecIssue); LI.Id := 'i2'; LI.Status := issOpen; LI.Severity := isLow;
    LIssues.Add(LI);
    LI := Default(TSpecIssue); LI.Id := 'i3'; LI.Status := issResolved; LI.Severity := isCritical;
    LIssues.Add(LI);
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LNodes, LEmpty, LEmpty, LEmpty, LIssues);
    Assert.AreEqual(2, LM.DecisionBacklog);
    Assert.AreEqual(1, LM.HighRiskOpen);
  finally
    LNodes.Free; LEmpty.Free; LIssues.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(THealthMetricsTests);
```

> 注意 `Backlog_OpenOnly` 调用了带 `AIssues` 参数的 `ComputeHealthMetrics` 重载（见 Step 3）。`Coverage_Partial`/`AvgConfidence_Mixed`/`FogCount_AcrossTrees` 调用 4 参版（issues 默认 nil）。

- [ ] **Step 2：跑测试确认失败**

Run: `cd "D:/_Progs/02Business/DeepSpec/tests" && ./_build_tests.bat 2>&1 | tail -20 && ./DeepSpec.Tests.exe 2>&1 | tail -15`
Expected: 编译失败——`THealthMetrics` 与 `ComputeHealthMetrics` 未定义。

- [ ] **Step 3：实现 `THealthMetrics` + `ComputeHealthMetrics` + `CountCrossTreeConflicts`**

在 `DeepSpec.Services.Render.pas` interface 区（第 18 行 `type` 之前，即 unit 顶部 type 声明区）追加 record 与 class 方法声明：

在 `uses`（第 12-17 行）之后、`type TDeepSpecRenderService = class`（第 20 行）之前插入：

```pascal
type
  /// <summary>Health metrics for the index dashboard (BUG-9 §2.2).
  /// Pure computation over node lists (+ optional issues).</summary>
  THealthMetrics = record
    TotalNodes: Integer;
    ConfirmedNodes: Integer;   // GenStatus = 'confirmed'
    CoveragePct: Double;       // ConfirmedNodes / TotalNodes * 100 (0 if none)
    AvgConfidence: Double;     // low=0.3 / medium=0.7 / high=1.0, mean
    DecisionBacklog: Integer;  // issues with Status = issOpen
    FogCount: Integer;         // nodes with HasFogState and FogState <> fsClear
    HighRiskOpen: Integer;     // issues Status=issOpen and Severity in (isCritical,isHigh)
  end;
```

然后在 `TDeepSpecRenderService` 的 `public` 区（`RenderIndex` 声明所在的 public 段，第 33-45 行）追加两个 `class function` 声明（紧贴 `procedure RenderBundlesPage` 之后、`end;` 之前）：

```pascal
    /// <summary>Compute health metrics over 4 trees (+ optional issues).
    /// nil lists are treated as empty. Pure — no IO.</summary>
    class function ComputeHealthMetrics(AFunc, AModule, AView, AData: TList<TSpecNode>;
      AIssues: TList<TSpecIssue> = nil): THealthMetrics; static;
    /// <summary>Count broken cross-tree references (orphan refs).
    /// Shared by RenderIndex summary and RenderProblemsPage detail.</summary>
    class function CountCrossTreeConflicts(AFunc, AModule, AView, AData: TList<TSpecNode>): Integer; static;
```

在 implementation 区末尾（文件最后 `end.` 之前）追加实现：

```pascal
class function TDeepSpecRenderService.ComputeHealthMetrics(AFunc, AModule, AView,
  AData: TList<TSpecNode>; AIssues: TList<TSpecIssue>): THealthMetrics;
var
  LConfSum: Double;
  LCount: Integer;

  procedure Scan(ANodes: TList<TSpecNode>);
  var
    LN: TSpecNode;
    LConfVal: Double;
  begin
    if ANodes = nil then Exit;
    for LN in ANodes do
    begin
      Inc(Result.TotalNodes);
      case LN.Confidence of
        clLow:    LConfVal := 0.3;
        clMedium: LConfVal := 0.7;
        clHigh:   LConfVal := 1.0;
      else
        LConfVal := 0.7;
      end;
      LConfSum := LConfSum + LConfVal;
      Inc(LCount);
      if SameText(LN.GenStatus, 'confirmed') then
        Inc(Result.ConfirmedNodes);
      if LN.HasFogState and (LN.FogState <> fsClear) then
        Inc(Result.FogCount);
    end;
  end;

var
  LI: TSpecIssue;
begin
  Result := Default(THealthMetrics);
  LConfSum := 0; LCount := 0;
  Scan(AFunc);
  Scan(AModule);
  Scan(AView);
  Scan(AData);
  if (LCount > 0) then
    Result.AvgConfidence := LConfSum / LCount;
  if Result.TotalNodes > 0 then
    Result.CoveragePct := (Result.ConfirmedNodes / Result.TotalNodes) * 100.0;
  if AIssues <> nil then
    for LI in AIssues do
    begin
      if LI.Status = issOpen then
      begin
        Inc(Result.DecisionBacklog);
        if (LI.Severity = isCritical) or (LI.Severity = isHigh) then
          Inc(Result.HighRiskOpen);
      end;
    end;
end;

class function TDeepSpecRenderService.CountCrossTreeConflicts(AFunc, AModule,
  AView, AData: TList<TSpecNode>): Integer;
var
  LAllIds: TDictionary<string, Boolean>;
  LN: TSpecNode;
  LRef: string;

  procedure ScanRefs(ANodes: TList<TSpecNode>);
  begin
    if ANodes = nil then Exit;
    for LN in ANodes do
    begin
      for LRef in LN.RelatedModules do
        if not LAllIds.ContainsKey(LRef) then Inc(Result);
      for LRef in LN.RelatedViews do
        if not LAllIds.ContainsKey(LRef) then Inc(Result);
      for LRef in LN.RelatedData do
        if not LAllIds.ContainsKey(LRef) then Inc(Result);
    end;
  end;

begin
  Result := 0;
  LAllIds := TDictionary<string, Boolean>.Create;
  try
    if AFunc   <> nil then for LN in AFunc   do LAllIds.AddOrSetValue(LN.Id, True);
    if AModule <> nil then for LN in AModule do LAllIds.AddOrSetValue(LN.Id, True);
    if AView   <> nil then for LN in AView   do LAllIds.AddOrSetValue(LN.Id, True);
    if AData   <> nil then for LN in AData   do LAllIds.AddOrSetValue(LN.Id, True);
    ScanRefs(AFunc);
    ScanRefs(AModule);
    ScanRefs(AView);
    ScanRefs(AData);
  finally
    LAllIds.Free;
  end;
end;
```

> `Scan`/`ScanRefs` 嵌套过程可访问外层 `Result`（Delphi 嵌套过程闭包语义）。`TDictionary` 来自 `System.Generics.Collections`，已在 interface-uses（第 15 行）。

- [ ] **Step 4：跑测试确认通过**

Run: `cd "D:/_Progs/02Business/DeepSpec/tests" && ./_build_tests.bat 2>&1 | tail -8 && ./DeepSpec.Tests.exe 2>&1 | tail -8`
Expected: 编译 0 error；测试 **97/97**（93 + 4 新）。若 `Coverage_Partial` 的 `66.666` 误差超 0.5，把断言容差放宽到 `1.0`。

- [ ] **Step 5：提交**

```bash
cd "D:/_Progs/02Business/DeepSpec"
git add src/services/DeepSpec.Services.Render.pas tests/Test.DeepSpec.Models.pas
git commit -m "feat(DeepSpec): BUG-9 health metrics pure fn + CountCrossTreeConflicts helper

THealthMetrics/ComputeHealthMetrics (coverage/confidence/backlog/fog/high-risk)
+ shared CountCrossTreeConflicts. 4 unit tests. 97/97.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2：Render.pas — RenderIndex 扩展渲染 4 看板区域

> 目标：RenderIndex 加 6 参数（4 树 + issues），渲染「健康度卡片 / 高风险问题 / 冲突摘要 / 优化 Prompt 按钮」。把 RenderProblemsPage 的冲突检测改调共享 `CountCrossTreeConflicts`（行为不变，DRY）。

**Context for this task：** 当前 `RenderIndex` 实现 `Render.pas:165-188`。它产出 `index.html`。既有 `.stat` 卡片 CSS 在 `RenderScanReport`（`:143`）已定义（全局 `.stat` 样式在 `PageHeader` 内嵌 `<style>`）。优化 Prompt 按钮复用 `.btn-ticket` 样式族（`:671`）。

- [ ] **Step 1：改 RenderIndex 签名（声明 + 实现）**

声明（`Render.pas:36-37`）改为：

```pascal
    procedure RenderIndex(const AProjectName: string; ATotalFiles: Integer;
      AFunc, AModule, AView, AData: TList<TSpecNode>;
      AIssues: TList<TSpecIssue>; AHasDataTree: Boolean = True);
```

> 参数顺序：把 `AHasDataTree` 移到最后（带默认值），新参数插中间。注意 `TList<TSpecNode>`/`TSpecIssue` 已在 interface-uses（`DeepSpec.Models`，第 17 行）可用。

实现（`Render.pas:165-188`）整体替换为：

```pascal
procedure TDeepSpecRenderService.RenderIndex(const AProjectName: string;
  ATotalFiles: Integer; AFunc, AModule, AView, AData: TList<TSpecNode>;
  AIssues: TList<TSpecIssue>; AHasDataTree: Boolean);
var
  LSb: TStringBuilder;
  LM: THealthMetrics;
  LConflicts: Integer;
  LHighShown, LIdx: Integer;
  LI: TSpecIssue;
  LSorted: TList<TSpecIssue>;
  LCovStr, LConfStr: string;
begin
  LSb := TStringBuilder.Create;
  LSorted := nil;
  try
    LSb.Append(PageHeader('Index'));
    LSb.AppendLine('<h1>DeepSpec: ' + HtmlEscape(AProjectName) + '</h1>');
    LSb.AppendLine('<p>项目规格健康度看板（BUG-9）。</p>');

    // --- §2.3.1 文档健康度（4 stat 卡片）---
    LM := ComputeHealthMetrics(AFunc, AModule, AView, AData, AIssues);
    LConflicts := CountCrossTreeConflicts(AFunc, AModule, AView, AData);
    LCovStr := LM.CoveragePct.ToString(ffFixed, nil, 1);
    LConfStr := (LM.AvgConfidence * 100.0).ToString(ffFixed, nil, 0);

    LSb.AppendLine('<h2>文档健康度</h2>');
    LSb.AppendLine('<div class="stat"><strong>' + LCovStr + '%</strong>覆盖率' +
      '<small>已确认节点占比。文档够不够 AI 开发用。</small></div>');
    LSb.AppendLine('<div class="stat"><strong>' + LConfStr + '%</strong>平均置信度' +
      '<small>low=30 / medium=70 / high=100</small></div>');
    LSb.AppendLine('<div class="stat"><strong>' + LM.DecisionBacklog.ToString +
      '</strong>决策积压<small>未决 issue 数（status=open）</small></div>');
    LSb.AppendLine('<div class="stat"><strong>' + LM.FogCount.ToString +
      '</strong>雾区数<small>处于迷雾中的节点（fog≠clear）</small></div>');

    // --- §2.3.2 高风险问题（top 5）---
    LSb.AppendLine('<h2>高风险问题</h2>');
    LSorted := TList<TSpecIssue>.Create;
    if AIssues <> nil then
      for LI in AIssues do
        if (LI.Status = issOpen) and ((LI.Severity = isCritical) or (LI.Severity = isHigh)) then
          LSorted.Add(LI);
    // sort by severity asc (critical=0 < high=1) so most severe first
    LSorted.Sort(TComparer<TSpecIssue>.Construct(
      function(const A, B: TSpecIssue): Integer
      begin
        Result := Ord(A.Severity) - Ord(B.Severity);
      end));
    LHighShown := 0;
    LSb.AppendLine('<ul style="padding-left: 0;">');
    for LIdx := 0 to LSorted.Count - 1 do
    begin
      if LHighShown >= 5 then Break;
      LI := LSorted[LIdx];
      Inc(LHighShown);
      LSb.AppendLine('<li class="problem"><span class="badge badge-conf-low">' +
        HtmlEscape(TSpecEnums.IssueSeverityToStr(LI.Severity)) + '</span> ' +
        '<a href="problems.html">' + HtmlEscape(LI.Title) + '</a>' +
        ' <code>' + HtmlEscape(LI.Id) + '</code></li>');
    end;
    LSb.AppendLine('</ul>');
    if LHighShown = 0 then
      LSb.AppendLine('<p><em>当前无高风险未决问题。</em></p>');

    // --- §2.3.3 冲突摘要 ---
    LSb.AppendLine('<h2>冲突摘要</h2>');
    LSb.AppendLine('<p>跨树断引用：' + LConflicts.ToString + ' 处。' +
      ' <a href="problems.html">查看详情</a></p>');

    // --- §2.3.4 优化 Prompt 入口 ---
    LSb.AppendLine('<h2>优化 Prompt</h2>');
    LSb.AppendLine('<p>依据当前健康度导出一段优化 Prompt，拷给原 AI 工具优化底层文件（旁路工具原则）。</p>');
    LSb.AppendLine('<button class="btn-ticket" data-action="export-optimization-prompt">' +
      '导出优化 Prompt</button>');

    // --- 原有页面列表 ---
    LSb.AppendLine('<h2>Pages</h2>');
    LSb.AppendLine('<ul>');
    LSb.AppendLine('  <li><a href="scan-report.html">Scan Report</a> (' +
      ATotalFiles.ToString + ' files)</li>');
    LSb.AppendLine('  <li><a href="problems.html">Problems</a></li>');
    LSb.AppendLine('  <li><a href="bundles.html">Bundles</a></li>');
    LSb.AppendLine('  <li><a href="function-tree.html">Function Tree</a></li>');
    LSb.AppendLine('  <li><a href="module-tree.html">Module Tree</a></li>');
    LSb.AppendLine('  <li><a href="view-tree.html">View Tree</a></li>');
    if AHasDataTree then
      LSb.AppendLine('  <li><a href="data-tree.html">Data Tree</a></li>');
    LSb.AppendLine('</ul>');

    LSb.Append(PageFooter);

    TFile.WriteAllText(TPath.Combine(FBasePath, 'index.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
    if LSorted <> nil then LSorted.Free;
  end;
end;
```

> `TComparer`/`TComparer<T>.Construct` 需 `System.Generics.Defaults`。implementation-uses 当前是 `System.IOUtils, System.DateUtils, System.StrUtils`（`:50-53`）——需追加 `System.Generics.Defaults`。`TSpecEnums` 在 `DeepSpec.Models`（interface-uses 已有）。

- [ ] **Step 2：implementation-uses 加 `System.Generics.Defaults`**

`Render.pas:50-53` 的 implementation uses 改为：

```pascal
uses
  System.IOUtils,
  System.DateUtils,
  System.StrUtils,
  System.Generics.Defaults;
```

- [ ] **Step 3：RenderProblemsPage 改调共享 CountCrossTreeConflicts（DRY，行为不变）**

RenderProblemsPage 当前（`:708-719`）用内联 `LAllIds` 字典做冲突检测。保留**详情输出**（`:717` 起的 `<ul>` + CheckNodeRefs），但把「是否有冲突」的计数改用共享 helper——具体：在 RenderProblemsPage 的 Cross-Tree Consistency 段开头加一行总数显示，复用 helper：

在 `Render.pas` 的 `RenderProblemsPage` 内、`LAllIds := TDictionary<string, Boolean>.Create;` 之前（约 `:710`），插入：

```pascal
      // 总数复用共享 helper（DRY，与 index.html 看板一致）
      LSb.AppendLine('<p>跨树断引用共 ' +
        CountCrossTreeConflicts(AFuncNodes, AModuleNodes, AViewNodes, ADataNodes).ToString +
        ' 处：</p>');
```

> 不删既有 LAllIds 详情逻辑（problems.html 仍需逐条列出），仅加总数行。`CountCrossTreeConflicts` 是 class function，RenderProblemsPage 作为同类方法可直接调。

- [ ] **Step 4：改 3 处 Controller 调用点签名**

打开 `DeepSpec.Controller.pas`。三处 `FRender.RenderIndex(...)`：

`RenderAll`（`:332`）改为：
```pascal
    FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
      FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
      FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, nil,
      FTreeBuilder.DataNodes.Count > 0);
```
> RenderAll 这里 issues 在下方 `:339` 才 LoadIssuesForRender。为避免顺序问题，把 LoadIssuesForRender **上移**到 RenderIndex 之前。见 Step 5。

`RefreshFromYaml`（`:391`）改为（复用已有 LFunc/LModule/LView/LData + LIssuesR）：
```pascal
      FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
        LFunc, LModule, LView, LData, LIssuesR,
        (LData <> nil) and (LData.Count > 0));
```
> 但此处 `LIssuesR` 在 `:398` 才创建。需把 LoadIssuesForRender 上移到 RenderIndex 之前。见 Step 5。

`RunScan`（`:800`）改为：
```pascal
    FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
      FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
      FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesScan,
      FTreeBuilder.DataNodes.Count > 0);
```
> RunScan 此处需新创建一个 issues list（见 Step 5）。

- [ ] **Step 5：把 LoadIssuesForRender 上移到 RenderIndex 之前**

**RenderAll（`:329-343`）** 重排为：
```pascal
  try
    FRender.RenderScanReport(FScanService, FProjectService.ProjectName,
      FProjectService.ProjectType);
    var LIssuesR := LoadIssuesForRender;
    try
      FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
        FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesR,
        FTreeBuilder.DataNodes.Count > 0);
      FRender.RenderTree('function-tree', 'Function Tree', FTreeBuilder.FunctionNodes);
      FRender.RenderTree('module-tree', 'Module Tree', FTreeBuilder.ModuleNodes);
      FRender.RenderTree('view-tree', 'View Tree', FTreeBuilder.ViewNodes);
      if FTreeBuilder.DataNodes.Count > 0 then
        FRender.RenderTree('data-tree', 'Data Tree', FTreeBuilder.DataNodes);
      FRender.RenderProblemsPage(FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesR);
    finally
      LIssuesR.Free;
    end;
```
> 删掉原 `:339` 的重复 `var LIssuesR := LoadIssuesForRender;`（现已上移）。

**RefreshFromYaml（`:388-403`）** 重排为：
```pascal
      var LIssuesR := LoadIssuesForRender;
      try
        FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
          LFunc, LModule, LView, LData, LIssuesR,
          (LData <> nil) and (LData.Count > 0));
        FRender.RenderTree('function-tree', 'Function Tree', LFunc);
        FRender.RenderTree('module-tree', 'Module Tree', LModule);
        FRender.RenderTree('view-tree', 'View Tree', LView);
        if (LData <> nil) and (LData.Count > 0) then
          FRender.RenderTree('data-tree', 'Data Tree', LData);
        FRender.RenderProblemsPage(LFunc, LModule, LView, LData, LIssuesR);
      finally
        LIssuesR.Free;
      end;
```

**RunScan（`:800`）** 在 RenderIndex 调用前插入 LoadIssuesForRender：
```pascal
    FRender.RenderScanReport(FScanService, FProjectService.ProjectName, LType);
    var LIssuesScan := LoadIssuesForRender;
    try
      FRender.RenderIndex(FProjectService.ProjectName, FScanService.TotalFiles,
        FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesScan,
        FTreeBuilder.DataNodes.Count > 0);
      FRender.RenderTree('function-tree', 'Function Tree', FTreeBuilder.FunctionNodes);
      // ...（其余 RenderTree 调用保持不变，不在此改动）
      FRender.RenderProblemsPage(FTreeBuilder.FunctionNodes, FTreeBuilder.ModuleNodes,
        FTreeBuilder.ViewNodes, FTreeBuilder.DataNodes, LIssuesScan);
    finally
      LIssuesScan.Free;
    end;
```
> 注意：RunScan 原本 `:800` 之后到 RenderProblemsPage 之间可能已有其他渲染调用。实施时**只**把 RenderIndex 那行改签名 + 在其前加 `LIssuesScan` 块，把同块内既有的 RenderProblemsPage 调用改用 `LIssuesScan`，其余代码不动。若 RunScan 此处本就没有 RenderProblemsPage 调用（需先 grep 确认），则只改 RenderIndex 签名 + 用临时块释放 LIssuesScan。先跑 `grep -n "RenderProblemsPage" src/controllers/DeepSpec.Controller.pas` 确认 RunScan 是否调它。

- [ ] **Step 6：编译主程序确认 0 error**

Run（按 memory `delphi-build-via-bash`，直接调 dcc64，**不要**用 .bat）：
```bash
cd "D:/_Progs/02Business/DeepSpec" && ./_build.bat 2>&1 | tail -15
```
Expected: 0 errors（DeepBase Hints + Prompts AnsiString 警告可忽略）。若报 `E2003`/`E2004`，检查 uses 重复或类型未引入。

> 若 RunScan 签名/顺序实施不确定，先只编译，按编译器报错精确定位再改。

- [ ] **Step 7：提交**

```bash
cd "D:/_Progs/02Business/DeepSpec"
git add src/services/DeepSpec.Services.Render.pas src/controllers/DeepSpec.Controller.pas
git commit -m "feat(DeepSpec): BUG-9 RenderIndex → health dashboard (4 regions)

健康度卡片(覆盖率/置信度/积压/雾区) + 高风险top5 + 冲突摘要 +
导出优化Prompt按钮。RenderProblemsPage 改调共享 CountCrossTreeConflicts。

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3：JS Bridge + Controller — export-optimization-prompt 链路

> 目标：MainView 的 `HandleWebMessage` 加 `export-optimization-prompt` 分支 → 三层闭包 `TExportPromptProc` → Controller.ExportOptimizationPrompt（组装静态 Prompt + 写盘 `.deepspec/prompts/optimization-prompt.md` + 日志）。

**Context for this task：** 镜像 BUG-11 第 2 步的 `TCreateTicketProc` 三层闭包模式。MainView 当前已穿 `FOnCreateTicket`（`:89`/`:94`/`:145`/`:193`/`:197`/`:246`）。Providers.pas `RegisterAllProviders` 已接 `AController` 并传了一个闭包（`:46-50`）。

- [ ] **Step 1：MainView interface 区定义 TExportPromptProc + 字段**

`DeepSpec.Providers.MainView.pas` interface 区（`TCreateTicketProc` 定义之后）加：

```pascal
  /// <summary>BUG-9: export-optimization-prompt JS Bridge callback.
  /// No args — Controller assembles the prompt from current health state.</summary>
  TExportPromptProc = reference to procedure;
```

`TBrowserNavigator` 类加字段（紧贴 `FOnCreateTicket` 之后）：
```pascal
    FOnExportOptimizationPrompt: TExportPromptProc;
```
`TDeepSpecMainViewProvider` 类加字段（紧贴其 `FOnCreateTicket` 之后）：
```pascal
    FOnExportOptimizationPrompt: TExportPromptProc;
```

- [ ] **Step 2：TBrowserNavigator 构造与 CreateFor 增参**

`TBrowserNavigator.CreateFor` 签名（`:89` 附近）加末参：
```pascal
    AOnCreateTicket: TCreateTicketProc; AOnExportOptimizationPrompt: TExportPromptProc);
```
实现里赋值（`:94` 附近，FOnCreateTicket 赋值之后）：
```pascal
    FOnExportOptimizationPrompt := AOnExportOptimizationPrompt;
```

`TDeepSpecMainViewProvider.Create` 同理加 `AOnExportOptimizationPrompt: TExportPromptProc`（`:193` 附近签名 + `:197` 赋值）。

`TDeepSpecMainViewProvider.CreateViewControl` 里 `TBrowserNavigator.CreateFor(...)` 调用（`:245-246`）末尾追加 `FOnExportOptimizationPrompt`：
```pascal
    LNavigator := TBrowserNavigator.CreateFor(LBrowser, LUrl, FProjectService,
      FOnCreateTicket, FOnExportOptimizationPrompt);
```

- [ ] **Step 3：HandleWebMessage 加 export-optimization-prompt 分支**

`HandleWebMessage`（`:145` 附近，`ticket-create` 分支之后）加：

```pascal
      if LAction = 'export-optimization-prompt' then
      begin
        if Assigned(FOnExportOptimizationPrompt) then
          FOnExportOptimizationPrompt;
        Exit;
      end;
```

- [ ] **Step 4：Controller 加 ExportOptimizationPrompt**

`DeepSpec.Controller.pas` public 区（`CreateTicket` 声明之后）加：
```pascal
    procedure ExportOptimizationPrompt;
```

implementation 区（`CreateTicket` 实现之后）加：

```pascal
procedure TDeepSpecController.ExportOptimizationPrompt;
var
  LM: THealthMetrics;
  LFunc, LModule, LView, LData: TList<TSpecNode>;
  LSb: TStringBuilder;
  LPath, LPromptsDir: string;
  LI: TSpecIssue;
  LHighShown: Integer;
begin
  if not FProjectService.IsOpen then
  begin
    FStatus.Warning('DeepSpec', 'No project open');
    Exit;
  end;

  LFunc := FTreeBuilder.FunctionNodes;
  LModule := FTreeBuilder.ModuleNodes;
  LView := FTreeBuilder.ViewNodes;
  LData := FTreeBuilder.DataNodes;

  // 复用既有 LoadIssuesForRender 获取 issues（含已落盘 ticket）
  var LIssues := LoadIssuesForRender;
  try
    LM := TDeepSpecRenderService.ComputeHealthMetrics(LFunc, LModule, LView, LData, LIssues);

    LSb := TStringBuilder.Create;
    try
      LSb.AppendLine('# 优化 Prompt（DeepSpec 自动生成）');
      LSb.AppendLine('');
      LSb.AppendLine('> 项目：' + FProjectService.ProjectName);
      LSb.AppendLine('> 来源：DeepSpec 健康度看板（BUG-9）。请把本 Prompt 拷给你的 AI 工具去优化底层文件。');
      LSb.AppendLine('');
      LSb.AppendLine('## 当前健康度');
      LSb.AppendLine(Format('- 覆盖率：%.1f%%（已确认节点占比，文档够不够 AI 开发用）',
        [LM.CoveragePct]));
      LSb.AppendLine(Format('- 平均置信度：%.0f%%', [LM.AvgConfidence * 100.0]));
      LSb.AppendLine('- 决策积压：' + LM.DecisionBacklog.ToString + ' 个未决 issue');
      LSb.AppendLine('- 雾区数：' + LM.FogCount.ToString + ' 个处于迷雾中的节点');
      LSb.AppendLine('');
      LSb.AppendLine('## 优化目标');
      LSb.AppendLine('1. 提升覆盖率：把更多节点从 candidate/derived 推进到 confirmed（补证据）。');
      LSb.AppendLine('2. 退雾：对雾区节点开探索 ticket，逐张收敛到 clear。');
      LSb.AppendLine('3. 清决策积压：处理未决 issue。');
      LSb.AppendLine('');
      LSb.AppendLine('## 高风险未决问题（请优先处理）');
      LHighShown := 0;
      if LIssues <> nil then
        for LI in LIssues do
        begin
          if (LI.Status = issOpen) and ((LI.Severity = isCritical) or (LI.Severity = isHigh)) then
          begin
            Inc(LHighShown);
            LSb.AppendLine('- [' + TSpecEnums.IssueSeverityToStr(LI.Severity) + '] ' +
              LI.Title + ' (' + LI.Id + ')');
            if LHighShown >= 10 then Break;
          end;
        end;
      if LHighShown = 0 then
        LSb.AppendLine('- （当前无高风险未决问题）');
      LSb.AppendLine('');
      LSb.AppendLine('## 任务');
      LSb.AppendLine('请阅读 .deepspec/ 下的四棵 spec 树与 issues，按上述目标逐项优化底层文件，');
      LSb.AppendLine('然后让 DeepSpec 重新扫描以更新健康度。');

      LPromptsDir := TPath.Combine(FProjectService.DeepSpecPath, 'prompts');
      if not TDirectory.Exists(LPromptsDir) then
        TDirectory.CreateDirectory(LPromptsDir);
      LPath := TPath.Combine(LPromptsDir, 'optimization-prompt.md');
      TFile.WriteAllText(LPath, LSb.ToString, TEncoding.UTF8);

      FStatus.Info('DeepSpec', '优化 Prompt 已导出：' + LPath);
    finally
      LSb.Free;
    end;
  finally
    LIssues.Free;
  end;
end;
```

> 需确认 Controller uses 是否已含 `TDeepSpecRenderService`（Render 单元）与 `THealthMetrics`。先 grep：
> `grep -n "DeepSpec.Services.Render\|THealthMetrics\|TDirectory\|TPath\|TFile" src/controllers/DeepSpec.Controller.pas | head`
> 若 Render 单元未在 Controller 的 uses，需加入（注意 interface/implementation uses 不重复）。
> `TDirectory`/`TFile`/`TPath` 来自 `System.IOUtils`——Controller 若未含需加。
> `FStatus.Info` 需确认 FStatus 是否有 Info 方法；若无，改用既有的 `FStatus.Warning` 或 `FStatus.Progress`（先 grep `FStatus.` 看 API）。

- [ ] **Step 5：Providers.pas RegisterAllProviders 加第二个闭包**

`DeepSpec.Providers.pas`（`:46-50` 附近，第一个闭包之后）加：

```pascal
      // BUG-9: JS Bridge export-optimization-prompt → Controller.ExportOptimizationPrompt
      procedure
      begin
        AController.ExportOptimizationPrompt;
      end);
```

> 即在构造 `TDeepSpecMainViewProvider` 时，第二个闭包参数位传上面匿名方法。需确认 `TDeepSpecMainViewProvider.Create` 构造调用是否已含新参数位（Task 3 Step 2 已加 `AOnExportOptimizationPrompt`）。把构造调用改成传入两个闭包。

先看当前构造调用：
Run: `grep -n "TDeepSpecMainViewProvider.Create" src/app/DeepSpec.Providers.pas`
按其当前实参列表末尾追加第二个闭包。

- [ ] **Step 6：编译主程序 + 测试**

Run:
```bash
cd "D:/_Progs/02Business/DeepSpec" && ./_build.bat 2>&1 | tail -15
```
Expected: 0 errors。若有 `E2003 undeclared 'TExportPromptProc'`，检查 MainView interface 区声明位置在 type 块内。

测试也应仍 97/97（本 task 不动单测，但 Controller 改动可能影响——跑一次）：
```bash
cd "D:/_Progs/02Business/DeepSpec/tests" && ./_build_tests.bat 2>&1 | tail -8 && ./DeepSpec.Tests.exe 2>&1 | tail -6
```

- [ ] **Step 7：提交**

```bash
cd "D:/_Progs/02Business/DeepSpec"
git add src/providers/DeepSpec.Providers.MainView.pas src/controllers/DeepSpec.Controller.pas src/app/DeepSpec.Providers.pas
git commit -m "feat(DeepSpec): BUG-9 export-optimization-prompt JS Bridge → Controller

三层闭包 TExportPromptProc；Controller.ExportOptimizationPrompt 组装
静态 Prompt 写 .deepspec/prompts/optimization-prompt.md + 日志路径。

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4：端到端验证 + 跟踪文件对齐

> 目标：实跑扫描 → 确认 index.html 看板渲染 → 点导出按钮 → prompt 落盘 → 对齐 tasks/history/bugfix。

- [ ] **Step 1：实跑扫描，确认 index.html 看板**

启动 DeepSpec.exe（或 MainForm 里 Open Project + Scan）。预期 `index.html` 出现：
- 4 张健康度卡片（覆盖率%/置信度%/积压数/雾区数）
- 高风险问题区（空则显示提示）
- 冲突摘要（断引用数 + 链接）
- 「导出优化 Prompt」按钮
- 雾区数应 >0（function 根首次扫描为 fsUnknownUnknowns，bugfix #3 设计）

若无法 GUI 实跑（无显示环境），静态验证：用 `_debug_parser.exe` 或写一个最小 dpr 调 `Controller.RenderAll` 后读 `index.html` 确认含 `class="stat"` 与 `export-optimization-prompt`。

- [ ] **Step 2：点导出按钮，确认 prompt 落盘**

在 WebView2 里点「导出优化 Prompt」。预期：
- `.deepspec/prompts/optimization-prompt.md` 生成
- 内容含「当前健康度」4 项数值 + 高风险问题段
- 日志/状态栏显示路径

若 JS Bridge 未触发（无 WebView2），静态验证：临时写最小 dpr 直接调 `Controller.ExportOptimizationPrompt`，确认文件生成。

- [ ] **Step 3：对齐 tasks.md**

`tasks.md:30` BUG-9 行改 `[x]` 并标 bugfix #14。`tasks.md:14` 头注「待修」列表去掉 BUG-9（留 BUG-7、BUG-6b/6c）。

`tasks.md:37` P2 区补一条 VCL 兜底入口 TODO（与 ticket VCL 兜底并列）：
```
- [ ] **BUG-9 VCL 兜底入口**：export-optimization-prompt 的 MainView 无 WebView2 时的菜单/对话框入口（当前仅 JS Bridge）
```
另补 §9「前后变化」diff TODO：
```
- [ ] **BUG-9 前后变化视图**：§9 列出的"文档优化前后规格结构变化"diff（需快照历史，超 BUG-9 范围）
```

- [ ] **Step 4：对齐 history.md**

在 history.md 末尾「进行中」段把 BUG-9 从「进行中」改为已完成，归档细节（4 看板区域 + 优化 Prompt 链路 + 97/97）。

- [ ] **Step 5：对齐 bugfix.md**

追加 #14：

```
## #14 BUG-9：RenderIndex 升级为健康度看板 + 优化 Prompt 入口（2026-07-09）

**现象**：index.html 仅页面列表，无健康度指标、无 issues、无优化 Prompt 入口；
定位文档 §7-9 的看板区域未兑现。

**修复**：
- RenderIndex 加 6 参（4 树 + issues），渲染 4 区域：健康度卡片（覆盖率/置信度/积压/雾区）
  + 高风险top5 + 冲突摘要 + 导出优化Prompt按钮。
- 新增纯函数 THealthMetrics/ComputeHealthMetrics（可单测）+ 共享 CountCrossTreeConflicts
  （RenderProblemsPage 复用，DRY）。
- JS Bridge export-optimization-prompt 三层闭包（TExportPromptProc）→
  Controller.ExportOptimizationPrompt 组装静态 Prompt 写
  .deepspec/prompts/optimization-prompt.md + 日志。

**设计取舍**：
- 健康度 helper 放 Render.pas（与既有局部 helper 同域），不新建单元。
- 优化 Prompt 为静态拼装（依据当前健康态），非 LLM 调用——兑现 §1.1 旁路工具原则。
- 复用 RenderProblemsPage 已算好的节点+issues，3 处调用点不新增 IO（LoadIssuesForRender 上移到 RenderIndex 之前）。
- 排序用 TComparer<TSpecIssue>.Construct（Delphi 无三元，闭包写比较函数）。

**验证**：主程序 0 error；测试 97/97（93 + 4 新 THealthMetricsTests）；
index.html 渲染 4 区域；优化 Prompt 落盘 + 路径日志。

**范围边界**：不做 schema 变更、不做新校验规则、不做 export-prompt 的 VCL 兜底入口
（记 tasks.md TODO，与 ticket VCL 兜底同处理）、不做 §9「前后变化」diff 视图
（需快照历史，记 TODO）。
```

- [ ] **Step 6：提交对齐**

```bash
cd "D:/_Progs/02Business/DeepSpec"
git add tasks.md history.md bugfix.md
git commit -m "docs(DeepSpec): align tracking files for BUG-9 (bugfix #14)

tasks BUG-9 [x] + VCL-fallback/前后变化 TODOs; history archive; bugfix #14.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Self-Review（计划写完后自查）

**1. Spec 覆盖：**
- §2.1 RenderIndex 签名扩展 → Task 2 Step 1 ✅
- §2.2 THealthMetrics + ComputeHealthMetrics → Task 1 Step 3 ✅
- §2.3.1 健康度卡片 → Task 2 Step 1（§2.3.1 段）✅
- §2.3.2 高风险 top5 → Task 2 Step 1（§2.3.2 段）✅
- §2.3.3 冲突摘要 + 共享 helper → Task 1 Step 3（CountCrossTreeConflicts）+ Task 2 Step 1/3 ✅
- §2.3.4 优化 Prompt 按钮 → Task 2 Step 1（§2.3.4 段）✅
- §2.4 JS Bridge export-optimization-prompt + Controller → Task 3 ✅
- §2.5 三层闭包接线 → Task 3 Step 1-2 + Step 5 ✅
- §2.6 单测 4 例 → Task 1 Step 1 ✅
- §3 改动文件清单 → Task 1-3 全覆盖 ✅
- §4 编译验证 → 各 Task Step ✅
- §5 范围边界（VCL 兜底 TODO + 前后变化 TODO）→ Task 4 Step 3 ✅

**2. 占位符扫描：** 无 TBD/TODO-as-instruction；所有代码块完整。RunScan 处有「先 grep 确认」的指引（非占位，是必要的前置确认），已给出具体 grep 命令。✅

**3. 类型一致性：** `THealthMetrics` 字段名（TotalNodes/ConfirmedNodes/CoveragePct/AvgConfidence/DecisionBacklog/FogCount/HighRiskOpen）在 Task 1 Step 3 定义、Task 1 Step 1 单测、Task 2 Step 1 渲染、Task 3 Step 4 Controller 中**全部一致** ✅。`ComputeHealthMetrics` 签名（4 树 + 可选 issues）一致 ✅。`TExportPromptProc` 在 Task 3 Step 1-5 一致 ✅。severity 比较 `isCritical`/`isHigh`、status `issOpen`、fog `fsClear` 全部匹配 Models 枚举 ✅。
