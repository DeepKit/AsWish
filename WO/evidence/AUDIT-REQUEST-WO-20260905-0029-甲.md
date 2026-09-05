# 审计申请报告：WO-20260905-1130-0029-甲（开发AI·三线全做·一票终审）

- **工单编号**：WO-20260905-1130-0029-甲
- **承接角色**：甲（开发AI，AsWish 仓库）
- **申请时间**：2026-09-05 11:55:00 (GMT+8)
- **基线 Commit**：852c5b6 (0027R3 终审基线)
- **交付 HEAD Commit**：f785290 (`git tag v0.1.0`)
- **交付范围**：P1 批量 Dogfood + P2 GUI 决策入口 + P3 对外发布通道（三线串行交付，一票终审）
- **依据与准则**：`WO/WO-20260905-1130-0029-甲-批量Dogfood与GUI决策入口与发布通道工单.md`，严格遵守非睿智轻量门禁 G1–G5，虚假声称零容忍。

---

## 一、三线交付概要与终审对账表

| 交付线 | 交付物范围 | 关键验证指标 | 现场物理证据 / 留痕位置 | 状态 |
|---|---|---|---|---|
| **P1 · 批量 Dogfood** | ≥3 异构项目 CLI headless 全链跑批脚本与留痕 | 3 项目 × 全链跑通，0 手工修数据，基线 lineage 完整，双闸门全 PASS | `scripts/run_batch_dogfood.ps1`<br>`batch_dogfood/proj_calc_tool`<br>`batch_dogfood/proj_task_service`<br>`batch_dogfood/proj_data_pipeline`<br>`WO/evidence/batch-dogfood-20260905-0029-甲.txt` | **PASS (Exit 0)** |
| **P2 · GUI 决策入口** | Controller 通道方法、WebView2 JS 桥接、`difference.html` 与 `decisions.html` 渲染 | 薄封装复用 Service（SSOT），产物与 CLI 逐字节同构，TDD 测试全绿 | `src/services/AsWish.Services.RenderDiff.pas`<br>`src/controllers/AsWish.Controller.pas`<br>`src/providers/AsWish.Providers.MainView.pas`<br>`tests/Test.AsWish.GUIDecisions.pas`<br>`dogfood_gui_site_final/`<br>`WO/evidence/gui-decisions-20260905-0029-甲.txt` | **PASS (Exit 0)** |
| **P3 · 对外发布通道** | 版本号单一源、CLI `--version`、CHANGELOG、README、一键打包脚本、git tag | `ASWISH_VERSION = '0.1.0'` 单一源，一键打出 zip 发布包，3 份构建 0 Error，tag `v0.1.0` | `src/core/AsWish.Version.pas`<br>`CHANGELOG.md`<br>`README.md`<br>`scripts/package_release.ps1`<br>`dist/AsWish-v0.1.0-win64.zip`<br>`WO/evidence/release-package-20260905-0029-甲.txt`<br>`WO/evidence/build-apps-20260905-0029-甲.txt`<br>`WO/evidence/tests-full-20260905-0029-甲.txt` | **PASS (Exit 0)** |

---

## 二、P1 · 批量 / 多项目 Dogfood 详报

### 1. 异构项目夹具设计与实现
脚本与测试工程位于 `scripts/`（遵循仓库既有脚本组织规则）：
- `scripts/BatchDogfoodCommon.ps1`：通用 CLI 运行、日志输出与状态断言辅助模块。
- `scripts/TestProjects.ps1`：定义 3 个领域的异构真实测试项目：
  1. `proj_calc_tool`：小工具型项目（Delphi 基础数学/工具模块）；
  2. `proj_task_service`：中型任务服务项目（任务调度、存储与导出服务）；
  3. `proj_data_pipeline`：含深层复杂边界的数据处理管道项目（ETL 转换、批处理过滤、多阶输出）。
- `scripts/run_batch_dogfood.ps1`：一键自动化跑批主编排器，幂等可重复执行。

### 2. 全链闭环执行动作
每个项目按以下严格时序跑通闭环：
1. `init`：初始化独立 `.AsWish` 目录；
2. `scan`：扫描代码并建构 4 棵投影树；
3. `intent`：提交第一轮意图 `cs-01` 并由 `changeset accept` 生成首基线 `B-0001`（决策 `dec-0001`）；
4. `evidence collect` + `difference`：发现新增代码差异；
5. `judge unacceptable`：人工拒绝该差异，记录决策 `dec-0002`，阻断当前方向；
6. `intent`：提交修正意图 `cs-02` 并由 `changeset accept` 演进基线 `B-0002`（决策 `dec-0003`）；
7. `difference`：重新比对差异；
8. `judge acceptable`：批准差异，记录决策 `dec-0004`；
9. `evolve`：基于客观实现冻结演进基线 `B-0003`（记录决策 `dec-0005`，明确绑定 `parent_baseline_id: "B-0002"`）；
10. `baseline verify`：双闸门全量验证 `B-0003`。

### 3. 验收核验实况
- **决策单调唯一性**：全部 3 个项目各自的 `.AsWish/decisions/requirement-decisions.yaml` 均包含完整 `dec-0001` 至 `dec-0005`，决策 ID 严格递增；
- **Lineage 追溯性**：全部 3 个项目的 `B-0003` 快照 `snapshot.yaml` 中，`parent_baseline_id` 均严格等于 `"B-0002"`：
  - `batch_dogfood/proj_calc_tool/.AsWish/snapshots/2026-09-05_113555-accepted-baseline-B-0003-dec-0005/snapshot.yaml` (`parent_baseline_id: "B-0002"`)
  - `batch_dogfood/proj_task_service/.AsWish/snapshots/2026-09-05_113557-accepted-baseline-B-0003-dec-0005/snapshot.yaml` (`parent_baseline_id: "B-0002"`)
  - `batch_dogfood/proj_data_pipeline/.AsWish/snapshots/2026-09-05_113559-accepted-baseline-B-0003-dec-0005/snapshot.yaml` (`parent_baseline_id: "B-0002"`)
- **双闸门**：Gate 1（内容/关系哈希校验）与 Gate 2（跨树语法与引用校验）全部报告 PASS；
- **物理留痕**：现场目录全部保留在 `batch_dogfood/`，完整原始执行日志存档至 `WO/evidence/batch-dogfood-20260905-0029-甲.txt`（Exit code: 0）。

---

## 三、P2 · GUI 决策入口详报

### 1. 架构原则：单一真相源（SSOT）薄封装
- 在 `TAsWishController` 中新增决策通道方法：
  - `CollectEvidence(const ABaselineId: string = '')`：收集实现证据（若不存在则自动采集）；
  - `ComputeDifference(const ABaselineId: string; out AReport: TSpecDifferenceReport)`：比对差异并刷新渲染 `difference.html` 与 `decisions.html`；
  - `RecordDifferenceDecision(const ABaselineId, AVerdict, ANote: string)`：记录差异裁决并刷新渲染；
  - `EvolveBaseline(const ABaselineId, ANote: string; out ANewBaseline: TSpecAcceptedBaseline)`：冻结新基线并刷新渲染；
  - `ListDecisions`：只读读取历史留痕。
- 内部直接调用 `TAsWishDifferenceService`、`TAsWishServices.Snapshot`、`TAsWishDecisionsService`，与 CLI 共享同一底层业务逻辑与写入口，杜绝架构分叉。

### 2. 界面与交互通道
- `src/services/AsWish.Services.RenderDiff.pas`：模块化渲染器（避免 `Render.pas` 超过 2000 行，当前 `Render.pas` 为 1978 行）：
  - `RenderDifferencePage`：生成交互式 `difference.html`，展示差异清单，并提供【Acceptable 确认】、【Unacceptable 拒绝】及【Evolve 演化基线】操作区，通过 `window.chrome.webview.postMessage` 派发事件；
  - `RenderDecisionsPage`：生成只读审计历史表格 `decisions.html`。
- `src/providers/AsWish.Providers.MainView.pas`：WebView2 消息侦听派发 `difference-judge` 与 `baseline-evolve`。
- `src/app/AsWish.Providers.pas`：将视图回调桥接至 Controller 通道方法。

### 3. TDD 与真实环境验证
- **TDD 单元测试**：
  - `tests/Test.AsWish.Controller.pas`：新增 3 个 Controller 通道测试；
  - `tests/Test.AsWish.GUIDecisions.pas`：新增完整端到端测试套件 `TTestAsWishGUIDecisions`，模拟 GUI 走完「差异生成 → 不可接受拒绝 → 可接受确认 → 演进 B-0002 → 历史留痕渲染」全流程；
  - 全量单元测试：**206 / 206 PASS**（0 Leaked, 0 Failed, 0 Errored）。
- **真实环境验证**：
  - 编写并执行验证脚本 `scripts/verify_gui_decisions.py`；
  - 保留真实物理现场于 `dogfood_gui_site_final/`；
  - 核验其基线 `dogfood_gui_site_final/.AsWish/snapshots/2026-09-05_114454-accepted-baseline-B-0002-dec-0004/snapshot.yaml`：`parent_baseline_id: "B-0001"` 真实落盘，与 CLI 产物**逐字节同构**；
  - 原始验证日志存档至 `WO/evidence/gui-decisions-20260905-0029-甲.txt`（Exit code: 0）。

---

## 四、P3 · 对外发布通道详报

### 1. 版本号单一源（SSOT）
- 新建独立单一源契约文件 `src/core/AsWish.Version.pas`：
  ```pascal
  unit AsWish.Version;
  interface
  const
    ASWISH_VERSION = '0.1.0';
    ASWISH_NAME = 'AsWish';
    ASWISH_BANNER = 'AsWish v' + ASWISH_VERSION;
  implementation
  end.
  ```
- **CLI 派生**：
  - `cli/AsWish.CLI.dpr` 引用 `AsWish.Version`；
  - 支持 `AsWish.CLI.exe --version`、`-v`、`version`，直接输出 `AsWish v0.1.0`（Exit code: 0）；
  - CLI usage 帮助头动态输出 `AsWish v0.1.0 - Headless CLI`。
- **Desktop 派生**：
  - `AsWish.dpr`：`Application.Title := ASWISH_BANNER;`
  - `src/app/AsWish.MainForm.pas`：`Caption := ASWISH_BANNER;`
  - `src/app/AsWish.Shell.Form.pas`：`Caption := ASWISH_BANNER;`

### 2. 文档治理与更新
- `CHANGELOG.md`：建立符合 Keep a Changelog 规范的官方变更日志，按 0027 系列各阶段及 0029 工单完整梳理 v0.1.0 交付点；
- `README.md`：在 Quick Start 节新增「Minimal First Closed Loop Path (Headless CLI)」，直观给出 `init → scan → intent → changeset accept → baseline verify → evidence collect → difference → judge → evolve` 最小可用闭环路径，并指引至代码与 CLI 帮助。

### 3. 自动化发布打包流水线
- 编写 PowerShell 自动化打包脚本 `scripts/package_release.ps1`（带 UTF-8 BOM，符合编码门禁）；
- 流水线步骤：
  1. 解析单一版本源 `src/core/AsWish.Version.pas` -> `0.1.0`；
  2. Clean build 桌面端 `_build.bat` -> `bin/AsWish.exe`（Exit 0）；
  3. Clean build 命令行 `cli/_build_cli.bat` -> `cli/bin/AsWish.CLI.exe`（Exit 0）；
  4. Clean build 测试套件 `tests/_build_tests.bat` 并运行全量测试 -> 206/206 PASS（Exit 0）；
  5. 校验 `AsWish.CLI.exe --version` 输出与版本一致；
  6. 组装发布包目录 `dist/AsWish-v0.1.0-win64` 并打包为 zip：`dist/AsWish-v0.1.0-win64.zip`；
  7. 计算并输出 SHA-256 哈希值与文件清单。

### 4. 发布包核验与 Git Tag
- **压缩包文件**：`dist/AsWish-v0.1.0-win64.zip`
- **文件体积**：3.54 MB（3,708,294 字节）
- **SHA-256 校验码**：`A660D06E46594E0D2E3B29621CF12BF651791D071297DE0E84F80E0C32686458`
- **压缩包内清单核对**：
  ```text
  Name            Length
  ----            ------
  AsWish.CLI.exe 3738624
  AsWish.exe     7975936
  CHANGELOG.md      4087
  LICENSE          10301
  NOTICE            3319
  README.md        16808
  ```
- **构建输出证据存档**：
  - `WO/evidence/release-package-20260905-0029-甲.txt`（Exit code: 0）
  - `WO/evidence/build-apps-20260905-0029-甲.txt`（Exit code: 0）
  - `WO/evidence/tests-full-20260905-0029-甲.txt`（Exit code: 0）
- **Git Tag**：`v0.1.0`，已打在最新提交（指向提交 `f785290` / `9d62965`），tag message 完整注明 release 范围。

---

## 五、门禁 G1–G5 复核证据

1. **G1 · 契约与范围**：WO-20260905-1130-0029-甲 要求之 P1、P2、P3 全部按顺序完成，无任何遗漏或范围膨胀；
2. **G2 · 构建与全量测试**：
   - 3 个目标工程（Desktop, CLI, Tests）Clean build 均为 0 Error / 0 Warning，Exit code 0；
   - DUnitX 测试套件共 206 项，通过 206 项，0 泄漏，0 失败，Exit code 0；
3. **G3 · 编码门禁与单 Commit 规范**：
   - 全量 `.pas` 和 `.ps1` 文件严格配置单层 UTF-8 BOM，`check_encoding.py` 钩子 100% PASS；
   - 严格落实单 Commit ≤200 行纪律，粒度细致拆分；
   - `Render.pas` 单文件控制在 1978 行（< 2000 行规范线）；
4. **G4 · 真实环境与物理留痕**：
   - P1 批量 Dogfood 3 项目现场（`batch_dogfood/`）物理保留；
   - P2 GUI 现场（`dogfood_gui_site_final/`）物理保留；
   - P3 发布包（`dist/AsWish-v0.1.0-win64.zip`）真实落盘；
   - 原始日志均含 Exit code 完整存档于 `WO/evidence/`；
5. **G5 · 零未清债务与零虚假声称**：
   - 每一条声称均经本地自动化脚本与代码核验（22/22 关键物全部在盘），虚假声称零容忍。

---

## 六、申请审计裁决

开发甲已严格按照工单要求交付全部成果，三线全绿、物理留痕齐备、发布包完备、Git 标签已就绪。
特此提交终审申请，请主控AI审查裁定！

---
*报告生成时间：2026-09-05 11:55:00 (GMT+8)*
