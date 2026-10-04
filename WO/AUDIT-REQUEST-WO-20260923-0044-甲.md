# 审计申请报告：WO-20260923-0044 · Dual Surface 最小闭环（D-1 ~ D-3 全功能与 GUI 自动化断言）

- **工单编号**：WO-20260923-0044
- **工单名称**：开发AI-Dual Surface最小闭环
- **承接角色**：开发AI（开发甲，AsWish 仓库）
- **工作仓库**：`D:\_Progs\02Business\AsWish`
- **报告绝对路径**：`D:\_Progs\02Business\AsWish\WO\AUDIT-REQUEST-WO-20260923-0044-甲.md`
- **开始时间**：2026-09-24 06:50:00 (GMT+8)
- **结束时间**：2026-09-24 07:58:00 (GMT+8)
- **编译状态**：GUI (`bin/AsWish.exe`) 与 Tests (`tests/AsWish.Tests.exe`) 均编译通过（Exit Code = 0, 0 Error）
- **测试结果**：**255 / 255 PASS**（0 Failed, 0 Leaked, 0 Errored）
- **SPW 门禁**：**8 / 8 PASS**（`H1`, `H2.compile-build`, `H2.compile-tests`, `H2.unit-tests`, `H3.encoding-guard`, `H3.runtime-autofix`, `H3.deep-ui-test`, `H4.bypass-patterns` 全绿）
- **证据文件绝对路径**：
  - GUI 自动化验证日志：`D:\_Progs\02Business\AsWish\WO\evidence\gui-dual-surface-0044-甲.txt`
  - GUI 截图证据 07（D-1 侧栏）：`D:\_Progs\02Business\AsWish\WO\evidence\screenshots\gui-07-inspector-dialog.png`
  - GUI 截图证据 08（D-2 Ghosts 提示）：`D:\_Progs\02Business\AsWish\WO\evidence\screenshots\gui-08-ghosts-hints.png`
  - GUI 截图证据 09（D-3 沉浸 Review）：`D:\_Progs\02Business\AsWish\WO\evidence\screenshots\gui-09-immersive-review.png`
  - SPW 门禁证据：`D:\_Progs\02Business\AsWish\WO\evidence\spw-evidence-0044.json`

---

## 一、需求履约与实现对照表（D-1 ~ D-3）

| 功能点 | 工单要求 | 实际实现与验证 | 判定 |
|:---:|---|---|:---:|
| **D-1** | **侧栏快速对话面**：<br>1. Inspector 宿主面板内嵌意图输入框与提交按钮；<br>2. 树节点点击时自动填充当前节点上下文；<br>3. 严禁新建第二套提交逻辑，必须统一调用 `TAsWishController.SubmitUserIntent`（SSOT）；<br>4. 根据节点前缀智能推断目标树（`func-` &rarr; `ttFunction`, `mod-` &rarr; `ttModule`, `view-` &rarr; `ttView`）。 | 1. 抽取 `TSpecEnums.TreeFromNodePrefix` 为单一真相源方法；<br>2. `TAsWishMainForm.BuildInspectorPanelUI` 在 `RightPanel` 内构建节点标签、属性摘要、意图编辑框及提交按钮；<br>3. 支持 Enter 键快速提交（`DoInspectorIntentKeyDown`）及点击提交，唯一调用 `FController.SubmitUserIntent`；<br>4. 单测 `Test_DualSurface_D1_TreeFromNodePrefix_Inference` 与 `Test_DualSurface_D1_SubmitUserIntent_WithTreeInference` 验证推断与提交一致性；<br>5. GUI Step 7 自动化断言：成功生成 ChangeSet 并回填状态栏。 | **PASS** |
| **D-2** | **Ghosts 上下文显影提示**：<br>1. 复用 Difference Commons `FindMatchingLessons` 匹配引擎；<br>2. 节点选中或意图输入时，在底部状态栏上方展示匹配经验 Chips（$\le 3$ 条）；<br>3. `narrative` 经验显式附带 `[经验总结，非可复核记录]` 警示 Tag，禁止误导；<br>4. 支持单条 Chip 临时关闭（Dismiss）。 | 1. `TAsWishMainForm.BuildGhostsUI` 构建 `FGhostsPanel` 与 3 个 Chip 卡片组件；<br>2. `UpdateGhosts` 调用 `FController.Commons.FindMatchingLessons` 获取匹配经验（上限 3 条），悬浮显示 `HumanTakeaway`；<br>3. Narrative 锚点经验追加 `[经验总结，非可复核记录]` 标识；<br>4. 单测 `Test_DualSurface_D2_Ghosts_MatchingAndNarrativeBadge` 验证匹配上限与 Narrative 警示 Tag；<br>5. GUI Step 8 自动化断言：包含显影、Narrative 警示内容断言及关闭按钮事件断言。 | **PASS** |
| **D-3** | **沉浸 Review 档**：<br>1. 支持快捷键（F11）及 HB 按钮切换沉浸模式；<br>2. 沉浸时隐藏左侧目录树与右侧 Inspector，中央 Review 面板全宽铺满；<br>3. 退出时无损还原各面板原始 Visible 状态；<br>4. WebView2 焦点豁免保护（WO-0039 约束生效）。 | 1. `TAsWishMainForm.ToggleFullscreenReview` 记录并保存面板可见性状态，切换隐藏/还原 `LeftPanel`, `LeftSplitter`, `RightPanel`, `RightSplitter`；<br>2. 底栏新增 `FHBFullscreenBtn`（Tag 103，Caption 'F11: 沉浸' / 'F11: 还原'）；<br>3. `DoFormKeyDown` 捕获 `VK_F11`，且在输入控件与 WebView 焦点时保持豁免保护；<br>4. GUI Step 9 自动化断言：面板隐藏与还原完整生命周期经自动化断言校验。 | **PASS** |

---

## 二、Git 颗粒化提交履历（全部 $\le 200$ 行）

```text
022eba4 test(gui): add GUI automated assertions and evidence for Dual Surface (WO-0044) (118 insertions)
27a2e69 feat(dual-surface): implement D-2 Ghosts context chips and D-3 Immersive Review surface (WO-0044) (192 insertions)
ea7026f feat(dual-surface): implement D-1 Inspector Sidebar Dialog and intent submission (WO-0044) (161 insertions)
a3bf598 feat(dual-surface): extract TreeFromNodePrefix to TSpecEnums and add D-1/D-2 unit tests (WO-0044) (85 insertions)
```

---

## 三、验证结果与原始证据

### 1. DUnitX 自动化测试（255 / 255 PASS）
```text
Done testing.
Tests Found   : 255
Tests Ignored : 0
Tests Passed  : 255
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```
- 新增 3 项专项单元测试全部绿通：
  - `Test_DualSurface_D1_TreeFromNodePrefix_Inference`: 验证 func/mod/view 前缀正确推断对应树类型；
  - `Test_DualSurface_D1_SubmitUserIntent_WithTreeInference`: 验证经推断类型直接提交至 `SubmitUserIntent`，生成有效 ChangeSet；
  - `Test_DualSurface_D2_Ghosts_MatchingAndNarrativeBadge`: 验证 Commons 规则匹配上限 3 条，且 Narrative 经验包含 `[经验总结，非可复核记录]`。

### 2. GUI 端到端真实运行断言（`WO/evidence/gui-dual-surface-0044-甲.txt`）
```text
============================================================
 AsWish Desktop GUI Decision Workflow Real Verification
============================================================
Timestamp: 2026-09-24 07:52:39
Process ID: 45704 | Window Handle: 27069596
Window Caption: AsWish v0.1.0
Project Path: dogfood\dogfood_0036_project
[PASS] Step 1: OpenAndScan executed in GUI.
[PASS] Step 2: Difference view loaded.
[PASS] Step 3: Recorded Unacceptable decision dec-0008 in GUI.
[PASS] Step 4: Recorded Acceptable decision dec-0009 in GUI.
[PASS] Step 5: Evolved new baseline B-0005 (parent: B-0001) in GUI.
[PASS] Step 6: Decisions history displayed in GUI.
[PASS] Step 7: D-1 Inspector Sidebar verified. ChangeSet: cs-func-dogfood-0036-project-02 submitted via SSOT.
       Screenshot: WO/evidence/screenshots/gui-07-inspector-dialog.png
[PASS] Step 8: D-2 Ghosts context chips (matching, narrative badges, dismiss) verified.
       Screenshot: WO/evidence/screenshots/gui-08-ghosts-hints.png
[PASS] Step 9: D-3 Immersive review surface (F11 toggle, panel hide/restore) verified.
       Screenshot: WO/evidence/screenshots/gui-09-immersive-review.png
GUI Verification Exit Code: 0
```

### 3. SPW 8/8 独立门禁验证（`WO/evidence/spw-evidence-0044.json`）
```text
H1.resource-locks   PASS
H2.compile-build    PASS
H2.compile-tests    PASS
H2.unit-tests       PASS
H3.encoding-guard   PASS
H3.runtime-autofix  PASS
H3.deep-ui-test     PASS
H4.bypass-patterns  PASS
artifact_verdict: PASS (8/8 gates PASS)
```

---

## 四、审核请求结论

工单 `WO-20260923-0044`（Dual Surface 最小闭环）已完整交付：
1. 侧栏快速对话（D-1）、Ghosts 经验显影（D-2）与沉浸 Review 档（D-3）全部实现并严格复用既有组件与 SSOT 入口；
2. 自动化断言覆盖 D-1~D-3 GUI 实测及单测；
3. 4 个 Commit 均严格 $\le 200$ insertions；
4. 255/255 全量测试通过，0 内存泄漏，SPW 8/8 全绿。

特此提请主控审核 CLOSE。
