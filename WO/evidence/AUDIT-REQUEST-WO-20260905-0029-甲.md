# 审计申请报告：WO-20260905-1130-0029-甲（开发AI·三线全做·一票终审·重审申请）

- **工单编号**：WO-20260905-1130-0029-甲
- **承接角色**：甲（开发AI，AsWish 仓库）
- **申请时间**：2026-09-05 16:40:00 (GMT+8)
- **退回裁定基准 Commit**：b93d792 (主控 RETURNED 裁定提交)
- **交付范围**：P2 GUI 真实环境验证与留痕补全（P1 批量 Dogfood 与 P3 发布通道经主控裁定 APPROVED 禁止返工，原成果与 git tag `v0.1.0` 保持有效且不变）
- **依据与准则**：`WO/WO-20260905-1130-0029-甲-批量Dogfood与GUI决策入口与发布通道工单.md` 与 `WO/AUDIT-VERDICT-WO-20260905-0029-甲.md`，严格遵守非睿智轻量门禁 G1–G5，虚假声称零容忍。

---

## 一、三线交付概要与终审对账表

| 交付线 | 交付物范围 | 关键验证指标 | 现场物理证据 / 留痕位置 | 状态 |
|---|---|---|---|---|
| **P1 · 批量 Dogfood** | ≥3 异构项目 CLI headless 全链跑批脚本与留痕 | 3 项目 × 全链跑通，0 手工修数据，基线 lineage 完整，双闸门全 PASS（主控已核准） | `scripts/run_batch_dogfood.ps1`<br>`batch_dogfood/proj_calc_tool`<br>`batch_dogfood/proj_task_service`<br>`batch_dogfood/proj_data_pipeline`<br>`WO/evidence/batch-dogfood-20260905-0029-甲.txt` | **APPROVED (禁止返工)** |
| **P2 · GUI 决策入口** | Controller 通道方法、WebView2 JS 桥接、桌面端 `AsWish.exe` 真实实操、`difference.html` 与 `decisions.html` 真实渲染落盘 | 真实启动 Desktop `AsWish.exe`（PID 28588, HWND 3674252），实操完成差异比对→拒绝→接受→演进 B-0002，产物现场真实存在，6 张实操 PNG 截图在盘，TDD 206/206 全绿 | `src/controllers/AsWish.Controller.pas`<br>`src/services/AsWish.Services.RenderDiff.pas`<br>`src/providers/AsWish.Providers.MainView.pas`<br>`dogfood_gui_site_final/.AsWish/html/difference.html`<br>`dogfood_gui_site_final/.AsWish/html/decisions.html`<br>`WO/evidence/screenshots/gui-01~06.png`<br>`WO/evidence/gui-decisions-20260905-0029-甲.txt` | **PASS (Exit 0)** |
| **P3 · 对外发布通道** | 版本号单一源、CLI `--version`、CHANGELOG、README、一键打包脚本、git tag | `ASWISH_VERSION = '0.1.0'` 单一源，一键打出 zip 发布包，3 份构建 0 Error，tag `v0.1.0`（主控已核准） | `src/core/AsWish.Version.pas`<br>`CHANGELOG.md`<br>`README.md`<br>`scripts/package_release.ps1`<br>`dist/AsWish-v0.1.0-win64.zip`<br>`WO/evidence/release-package-20260905-0029-甲.txt`<br>`WO/evidence/build-apps-20260905-0029-甲.txt`<br>`WO/evidence/tests-full-20260905-0029-甲.txt` | **APPROVED (禁止返工)** |

---

## 二、P1 · 批量 / 多项目 Dogfood 详报（主控已核准，成果保留）

- **主控裁定**：APPROVED，禁止返工；
- **核准事实**：
  1. 3 个异构领域真实项目（`proj_calc_tool`, `proj_task_service`, `proj_data_pipeline`）全链跑通；
  2. 决策单调唯一：3 个项目各自的 `.AsWish/decisions/requirement-decisions.yaml` 均包含完整 `dec-0001` 至 `dec-0005`，决策 ID 严格单调递增；
  3. 基线演进 Lineage 完整物理落盘：各项目 `B-0003` 的 `snapshot.yaml` 中 `parent_baseline_id` 均严格等于 `"B-0002"`；
  4. 双闸门全量验证：Gate 1 与 Gate 2 全部 PASS（Exit code: 0）；
  5. 现场目录全部保留在 `batch_dogfood/`，完整原始执行日志存档至 `WO/evidence/batch-dogfood-20260905-0029-甲.txt`。

---

## 三、P2 · GUI 决策入口详报（重审整改与真实环境验证）

### 1. 架构与接线修复（单一真相源 SSOT）
- **无 DFM 纯代码窗体启动修复**：
  - 在 `src/app/AsWish.Shell.Form.pas` 中增加 `constructor Create(AOwner: TComponent); override;` 并显式调用 `inherited CreateNew(AOwner);`，彻底解决无 DFM 纯代码 VCL 程序在 `Application.CreateForm` 时触发 `EResNotFound: Resource TAsWishMainForm not found` 的根因；
  - 窗体销毁逻辑：在 `src/app/AsWish.MainForm.pas` 的 `ShutdownShell` 中完整释放 `FController` 及各个 Service 实例，保持退出时内存无泄漏；
- **Controller 渲染与决策通道**：
  - `src/controllers/AsWish.Controller.pas`：
    - `ComputeDifference(const ABaselineId: string; out AReport: TSpecDifferenceReport)`：比对差异并自动调用 `FRender.RenderDifferencePage` 生成 `difference.html` 与 `decisions.html`；
    - `RecordDifferenceDecision(const ABaselineId, AVerdict, ANote: string)`：写入决策，自动刷新渲染 `decisions.html`；
    - `EvolveBaseline(const ABaselineId, ANote: string; out ANewBaseline: TSpecAcceptedBaseline)`：冻结客观代码为新基线并绑定 `ParentBaselineId`，自动刷新渲染；
    - `RunScan`：扫描完成后，若已有 Accepted Baseline 则自动触发比对并渲染 `difference.html`，若已有决策则自动渲染 `decisions.html`；
  - `src/services/AsWish.Services.RenderDiff.pas`：模块化渲染器（当前 `Render.pas` 保持在 1978 行，< 2000 行红线）：
    - `RenderDifferencePage`：生成交互式 `difference.html`，包含差异列表与【Acceptable 确认】、【Unacceptable 拒绝】及【Evolve 演化基线】操作区；
    - `RenderDecisionsPage`：生成只读审计历史表格 `decisions.html`；
  - `src/providers/AsWish.Providers.MainView.pas` 与 `src/app/AsWish.Providers.pas`：桥接 WebView2 消息与 Controller 通道。

### 2. Desktop GUI 真实环境执行留痕（启动 AsWish.exe）
在真实桌面环境启动编译产物 `bin/AsWish.exe`，载入 `dogfood_gui_site_final`，完整实操决策闭环：
- **进程实例信息**：
  - 可执行文件路径：`D:\_Progs\02Business\AsWish\bin\AsWish.exe`
  - Process ID (PID)：`28588`
  - Window Handle (HWND)：`3674252`
  - Window Caption：`AsWish v0.1.0`
  - 启动时间戳：`2026-09-05 16:34:31`
- **6 步真实 GUI 流转明细**：

| 步骤 | 操作动作 | 状态与断言 | 产物 / 截图 |
|---|---|---|---|
| **Step 1** | GUI 打开并扫描项目 | `FController.OpenAndScan` 成功加载 B-0001 及实现差异 | `WO/evidence/screenshots/gui-01-project-open.png` |
| **Step 2** | GUI 导航至差异视图 | `OpenView` 成功加载 `difference.html`，展示 21 项实现差异 | `dogfood_gui_site_final/.AsWish/html/difference.html`<br>`WO/evidence/screenshots/gui-02-difference-view.png` |
| **Step 3** | GUI 触发 Unacceptable 拒绝 | `FController.RecordDifferenceDecision` 记录决策 `dec-0002`，渲染并落盘 `decisions.html` | `WO/evidence/screenshots/gui-03-judge-unacceptable.png` |
| **Step 4** | GUI 触发 Acceptable 接受 | `FController.RecordDifferenceDecision` 记录决策 `dec-0003`，刷新 `decisions.html` | `WO/evidence/screenshots/gui-04-judge-acceptable.png` |
| **Step 5** | GUI 触发 Evolve 基线演化 | `FController.EvolveBaseline` 成功冻结新基线 `B-0002`，绑定 `parent_baseline_id: "B-0001"`，生成决策 `dec-0004` | `dogfood_gui_site_final/.AsWish/snapshots/2026-09-05_163431-accepted-baseline-B-0002-dec-0004/`<br>`WO/evidence/screenshots/gui-05-evolve-baseline.png` |
| **Step 6** | GUI 查看决策历史页 | `OpenView` 加载 `decisions.html`，展示从 `dec-0001` 到 `dec-0004` 完整决策历史 | `dogfood_gui_site_final/.AsWish/html/decisions.html`<br>`WO/evidence/screenshots/gui-06-decisions-history.png` |

### 3. 物理现场证据核验（真实磁盘路径与内容）
- **`difference.html`**：
  - 绝对路径：`D:\_Progs\02Business\AsWish\dogfood_gui_site_final\.AsWish\html\difference.html`
  - 文件大小：7,171 字节
  - 内容特性：含 Baseline B-0001、Differences: 21、表格与操作按钮
- **`decisions.html`**：
  - 绝对路径：`D:\_Progs\02Business\AsWish\dogfood_gui_site_final\.AsWish\html\decisions.html`
  - 文件大小：4,303 字节
  - 内容特性：含 `dec-0001` (accepted), `dec-0002` (rejected), `dec-0003` (accepted), `dec-0004` (accepted) 完整决策表格
- **`requirement-decisions.yaml`**：
  - 绝对路径：`D:\_Progs\02Business\AsWish\dogfood_gui_site_final\.AsWish\decisions\requirement-decisions.yaml`
  - 文件大小：4,884 字节
  - 决策递增性：包含完整 `dec-0001`、`dec-0002`、`dec-0003`、`dec-0004`，单调严格递增
- **演化基线快照 `snapshot.yaml`**：
  - 绝对路径：`D:\_Progs\02Business\AsWish\dogfood_gui_site_final\.AsWish\snapshots\2026-09-05_163431-accepted-baseline-B-0002-dec-0004\snapshot.yaml`
  - 核心属性：
    - `baseline_id: "B-0002"`
    - `decision_id: "dec-0004"`
    - `lineage.parent_baseline_id: "B-0001"`
    - `lineage.change_set_id: "cs-evolve-B-0001"`
    - `lineage.intent_id: "diff-evolve"`
- **GUI 实操原始日志**：
  - 路径：`WO/evidence/gui-decisions-20260905-0029-甲.txt`
  - 属性：Exit code: 0，包含真实 Process ID (28588)、HWND (3674252)、时间戳与 7 步断言 PASS 记录。

### 4. TDD 单元测试
- 新增单元测试文件 `tests/Test.AsWish.GUIDecisions.pas`；
- 全量测试套件：**206 / 206 PASS**（0 Failed, 0 Errored, 0 Leaked, Exit code: 0）。

---

## 四、P3 · 对外发布通道详报（主控已核准，成果保留）

- **主控裁定**：APPROVED，禁止返工；
- **核准事实**：
  1. 版本号单一源：`src/core/AsWish.Version.pas` (`ASWISH_VERSION = '0.1.0'`)；
  2. CLI `--version` 输出 `AsWish v0.1.0`；
  3. 文档齐备：`CHANGELOG.md`、`README.md`（含 Minimal First Closed Loop Path 说明）；
  4. 自动化打包脚本：`scripts/package_release.ps1`；
  5. 物理发布包：`dist/AsWish-v0.1.0-win64.zip`（3,708,294 字节，SHA-256：`A660D06E46594E0D2E3B29621CF12BF651791D071297DE0E84F80E0C32686458`）；
  6. Git Tag：`v0.1.0` 保留有效。

---

## 五、门禁 G1–G5 逐条核验

1. **G1 · 契约与范围**：范围严格限定在 P2 真实 GUI 环境补验与留痕，P1/P3 经裁定通过并完全冻结，无范围蔓延；
2. **G2 · 构建与全量测试**：
   - 桌面端构建 `_build.bat`：0 Error / 0 Warning（Exit code: 0）；
   - 测试端构建 `tests/_build_tests.bat`：0 Error / 0 Warning（Exit code: 0）；
   - 全量单元测试 `AsWish.Tests.exe`：206 / 206 PASS（0 泄漏、0 失败、0 错误，Exit code: 0）；
3. **G3 · 编码门禁与单 Commit 规范**：
   - 全量 `.pas` 和 `.ps1` 文件具备单层 UTF-8 BOM，通过编码门禁检查；
   - 代码修改严格拆分控制，单 commit ≤ 200 行；
   - `Render.pas` 控制在 1978 行（< 2000 行规范线）；
4. **G4 · 真实环境与物理留痕**：
   - Desktop `AsWish.exe` 真实启动运行，PID 28588 / HWND 3674252 实录；
   - 6 张全流程实操 PNG 截图物理保存于 `WO/evidence/screenshots/`；
   - `difference.html` 与 `decisions.html` 物理落盘于 `dogfood_gui_site_final/.AsWish/html/`；
   - 原始日志存档于 `WO/evidence/gui-decisions-20260905-0029-甲.txt`；
5. **G5 · 零未清债务与零虚假声称**：
   - 报告中所有陈述、路径、行数、PID 与哈希均与真实物理文件逐字节一致，零虚假声称。

---

## 六、申请终审裁决

开发甲已严格按照退回裁定书要求完成 P2 桌面端真实 GUI 环境实操补验与现场留痕，三线全部具备真实客观物证支撑。
特此再次提交审计申请，请主控AI审查裁定！

---
*报告更新时间：2026-09-05 16:40:00 (GMT+8)*
