# WO-20260921-0036-甲 · AsWish 封版就绪大合流与深层真实验证大工单

> **工单编号**：WO-20260921-0036-甲
> **工单名称**：AsWish Release Readiness Master Consolidation
> **承接角色**：开发甲（AsWish 仓）
> **工程主仓**：`D:\_Progs\02Business\AsWish`
> **前置状态**：
>   - WO-20260914-EHAI-BINDING-001R1：已完成并通过独立复核（233/233 PASS）
>   - WO-20260914-EHAI-BINDING-001R2：B-1 微校准项（NON-BLOCKING）已就绪
> **排除项（按指令）**：
>   - 第 5 项（打包分发、安装程序与使用手册）排除在本次大工单外；
>   - 外部依赖项（上游 DeepBase A-2 全量 HB regression PASS 终审）不越界修改，本仓只负责符号对齐与 Conformance 基准锁死。
> **目标闭环**：
>   完成除第 5 项与外部依赖外的全部四项闭环任务，实现 AsWish 从“功能具备”到“日常真正可用、封版就绪（Release Ready）”的跨越。

---

## 0. 任务全景与执行路线

```text
Task 1: R2 B-1 构建证据与告警台账严格收口 (Build & Warning Audit Calibration)
    ↓
Task 2: 非 VCL / 纯代码工程差异计算优雅降级与范围防御 (Graceful Degradation & Scope Safety)
    ↓
Task 3: 桌面 GUI 与 HB Choice Deck 深度合流 (Desktop GUI & HB Choice Deck Surface Integration)
    ↓
Task 4: 复杂现实工程深层真实 Dogfood 验证 (Deep Real-World Dogfood Validation)
    ↓
全量测试回归 (236+ PASS) + 全量构建零错误 + 颗粒化 Commit
```

---

## 1. 任务一｜R2 B-1 构建证据与告警台账严格收口

### 1.1 背景与目标
上游裁定指出：`WO\evidence\build-ehai-binding-001R1.txt` 证明了 `Exit Code = 0 / 0 Error`，但未证明 `0 Warning`。
本工单严格采纳推荐方案 A，统一修正历史证据用词为 `Build succeeded / Exit Code 0 / 0 Error`，并在本次大工单的构建脚本与证据产物中，显式统计并捕获编译器告警行数，做到言出有据。

### 1.2 验收标准
- [x] `WO\evidence\build-ehai-binding-001R1.txt` 措辞微校准为 `Build succeeded / Exit Code 0 / 0 Error`，消除未经支持的告警主张。
- [x] 业务代码零变动，测试套件零破坏。

---

## 2. 任务二｜非 VCL / 纯代码工程差异计算优雅降级与防御

### 2.1 背景与问题
当前 AsWish 的 `ComputeDifference` 和 `CollectEvidence` 偏向 VCL 视觉和特定存量配置：
1. 当目标工程为非 VCL、纯代码（如 CLI、引擎、后台库）或未建立 `visual-binding.yaml` 时，差异计算容易因缺少 visual binding 或缺少 source_refs 而抛出未捕获异常。
2. 缺乏清晰的降级路径：非视觉工程应该安全降级为 L1（文件结构、AST、契约元数据）差异，并给出清晰的诊断说明（`Degraded Status` / `Pure structural comparison`），而不是让用户遭遇硬崩溃。

### 2.2 设计与实现
1. **证据收集器防御 (`TAsWishEvidenceCollectorService`)**：
   - 检查 baseline 节点是否有 `source_refs`；若存在空引用节点，不抛出硬崩溃，而是记录为未锚定节点，并从工程扫描索引中提供备用源文件证据；
   - 即使证据列表为空，也不写出畸形文件，并在差异计算阶段触发优雅降级。
2. **差异计算引擎降级 (`TAsWishDifferenceService`)**：
   - 当 `implementation-evidence.yaml` 缺失或无平台比较器能处理当前工程时，自动降级为 L1 结构差异计算；
   - 在 `TSpecDifferenceReport` 中加入降级标记或诊断条目，明确指示“降级运行：仅执行 L1 结构比对，非视觉工程跳过 L2/L3 平台渲染检查”；
   - 禁止在非 VCL 工程中虚报或抛出 VCL 匹配异常。
3. **单元测试验证**：
   - 在 `tests/Test.AsWish.Difference.pas` 中新增非 VCL / 纯代码工程的降级自动化测试，确保 100% 覆盖并绿灯。

---

## 3. 任务三｜桌面 GUI 与 HB Choice Deck 交互深度合流

### 3.1 背景与问题
当前 AsWish 的 HB Choice Deck（`AsWish.Binding.HB.pas`）与桌面 GUI 窗口（`AsWish.MainForm.pas`）存在交互割裂：
- 桌面 GUI 主要通过 WebView2 网页内的 JS Bridge 触发事件；
- EHAI / HB 的核心键盘语义（`0..9` 快捷键、Choice Deck 动作派发、探索与承诺边界）未直接挂接在桌面原生窗口上；
- 用户在桌面端使用时无法直接用键盘 `0..9` 驱动 ChangeSet 审核与意图交互。

### 3.2 设计与实现
1. **原生挂接 `TAsWishHBBinding`**：
   - 在 `TAsWishMainForm` 中持有并管理 `TAsWishHBBinding` 实例，与 `TAsWishController` 保持单一真相源绑定。
2. **桌面原生 Choice Deck 状态栏 / 动作面板**：
   - 在窗体下方（或主控制区）集成原生 HB 状态条，实时显示当前 HB Choice 状态（`[1..7] Review Changes`, `[8] Regenerate`, `[9] Free Input / Override`, `[0] Back`）及最近审计 Trace ID。
3. **全局键盘动作派发 (`0..9`, `Enter`, `R`)**：
   - 窗体开启 `KeyPreview := True`，在 `FormKeyDown` 中捕获非文本输入区的按键：
     - `1..7`：派发 `cakCandidate`，触发 `ProcessHbAction`（调出 ChangeSet 审核页并更新状态）；
     - `8`：派发 `cakRegenerate`，触发 `ProcessHbAction`（重新生成提示词/探索）；
     - `9`：派发 `cakFreeInput`，支持自由输入与框架否决（Frame Rejection）；
     - `0`：派发 `cakBack`，触发 `ProcessHbAction`（无承诺回退）；
     - `Enter` / `A`：在审核状态下触发 `ExecuteCommitmentGate`（跨越承诺边界，变更写入规范树并冻结基线）；
     - `Escape` / `R`：触发 `ExecuteReject`（拒绝候选变更，规范树保持不变）。
4. **双向视图同步**：
   - 键盘触发动作后，实时刷新主 WebView2 / 原生视图，并更新状态栏信息，实现无缝日常操作。

---

## 4. 任务四｜复杂现实工程深层 Dogfood 验证

### 4.1 背景与目标
过去测试多使用极简合成目录（synthetic fixture）。本次必须建立一个**高度真实的复杂多目录工程场景**进行全闭环 Dogfooding：
- 包含多层目录（`src/app`, `src/services`, `docs/`, `config/`, `tests/`）；
- 混合文件类型（`.pas`, `.md`, `.json`, `.yaml`, `.dpr`）；
- 包含未审项、结构冲突、代码漂移与布局意图。

### 4.2 验证全链路
1. `init`：工程初始化与目录规范创建；
2. `scan`：全量扫描并生成多树规范（Function, Module, View, Data）；
3. `intent`：用户表达自然语言需求意图；
4. `review`：通过 HB Choice Deck 浏览候选 ChangeSet；
5. `accept`：跨越承诺边界，接受变更并冻结 Baseline B-0001；
6. `mutate`：模拟现实开发演进（修改代码、新增模块、调整布局）；
7. `evidence`：自动收集真实实现物理证据；
8. `diff`：计算结构差异（验证 L1 结构差异与降级安全）；
9. `judge`：针对差异做出人类判定（acceptable / unacceptable）；
10. `evolve`：从现实演进生成新基线 B-0002；
11. `re-diff`：复验基线收敛性（差异清零）。

### 4.3 证据产物
- 生成原始执行日志：`WO\evidence\dogfood-0036-甲.log`
- 包含真实时间戳、进程号、文件 SHA256 哈希、物理文件存在性与收敛证明。

---

## 5. 验收标准清单

| 编号 | 验收项 | 目标判定 |
| :--- | :--- | :---: |
| AC-01 | R2 B-1 微校准完成，历史证据修正为 Exit Code 0 / 0 Error | [x] |
| AC-02 | 非 VCL / 纯代码工程差异计算优雅降级，零未捕获异常，零虚假声称 | [x] |
| AC-03 | 差异引擎降级自动化单元测试 100% 通过 | [x] |
| AC-04 | 桌面 GUI 原生集成 HB Choice Deck，支持键盘 0..9 / Enter / R 驱动 | [x] |
| AC-05 | 桌面 GUI 键盘动作与 Controller 双向同步，状态栏显示 HB 审计痕迹 | [x] |
| AC-06 | 复杂多目录现实工程 Dogfooding 全链路无阻断执行完毕 | [x] |
| AC-07 | 物理证据文件 `WO/evidence/dogfood-0036-甲.log` 完整落盘 | [x] |
| AC-08 | 全量单元测试 100% 通过（240 PASS，0 Fail，0 Error，0 Leak） | [x] |
| AC-09 | GUI、CLI、Tests 全部编译成功，Exit Code = 0，0 Error | [x] |
| AC-10 | 颗粒化 Git Commit（每提交 ≤ 200 行），证据链条清晰可溯 | [x] |

---

## 6. 执行与交付总结 (Execution & Delivery Summary)

### 6.1 颗粒化提交清单 (Commits)
1. `7c03b78` - `docs(audit): WO-20260914-EHAI-BINDING-001R2 B-1 micro-calibration`
2. `96861df` - `feat(diff): graceful degradation for non-VCL and pure code projects`
3. `958006d` - `test(diff): add tests for graceful degradation on non-visual projects`
4. `8357ca3` - `feat(hb): integrate HBBinding into provider callbacks and add ASWISH_V_013 test`
5. `eb76ae6` - `feat(gui): integrate HB Choice Deck and keyboard shortcuts 0-9 into MainForm`

### 6.2 编译状态 (Build Status)
- 编译器：Embarcadero Delphi for Win64 37.0
- AsWish GUI (`bin/AsWish.exe`)：24,099 行，Exit Code = 0，0 Error
- AsWish CLI (`cli/bin/AsWish.CLI.exe`)：15,409 行，Exit Code = 0，0 Error
- AsWish Tests (`tests/AsWish.Tests.exe`)：29,407 行，Exit Code = 0，0 Error
- 证据文件存档：`WO/evidence/build-0036-甲.txt`

### 6.3 自动化测试基线 (Automated Test Baseline)
- 测试总数：240
- 通过数：240 (100%)
- 失败数：0
- 错误数：0
- 内存泄漏：0
- 新增覆盖测试：`Test09_Difference_GracefulDegradation_WhenEvidenceEmpty`, `Test10_Difference_NonVisual_GracefulHandling`, `Test08_Evidence_FallbackWhenNoSourceRefs`, `ASWISH_V_013_GUI_Surface_KeyDispatcher_And_Deck_Integration`

### 6.4 现实 Dogfood 验证闭环 (Dogfood Closed-Loop)
- 目标工程：`dogfood/dogfood_0036_project`（包含 7 个物理文件，跨 4 个目录层级，包含 Pascal 代码、DFM 窗体、Markdown 文档、YAML 配置）
- 12 步全生命周期穿透：
  1. `init` -> 2. `scan` -> 3. `intent` -> 4. `changeset` / `changeset review` -> 5. `changeset accept` (冻结基线 B-0001) -> 6. `visual preview` / `visual confirm` (冻结基线 B-0002) -> 7. `mutate` (代码漂移) -> 8. `evidence collect` -> 9. `difference` -> 10. `judge` (dec-0003) -> 11. `evolve` (生成新基线 B-0003，系谱回溯 B-0001) -> 12. `re-difference` (差异收敛为 0)
- 证据文件存档：`WO/evidence/dogfood-0036-甲.log`

