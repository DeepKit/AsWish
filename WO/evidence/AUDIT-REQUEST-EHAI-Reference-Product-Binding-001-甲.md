# 审计申请报告：EHAI Reference Product Binding 001R1

- **工单编号**：WO-20260914-EHAI-BINDING-001R1
- **上游工单**：EHAI Reference Product Binding 001
- **承接角色**：甲（开发AI，AsWish 仓库）
- **工程主仓**：`D:\_Progs\02Business\AsWish`
- **上游依赖仓**：`D:\_Progs\02Business\DeepBase`
- **唯一上游契约**：`D:\_Progs\一元论\90-跨层组合\高效AI人机交互体系-EHAI\common-contract\EHAI-Language-Neutral-Realization-Contract-v0.md`（CANONICAL SSOT）
- **公共符号基准**：`DeepBase\docs\EHAI-Delphi-Symbol-Baseline.md`（基准版本：`EHAI-DELPHI-SYMBOL-BASELINE-v1.0`）
  - `Core/DeepBase.EHAI.Types.pas` (SHA256: `de9a32082dbf86ff1943c33677a89746eae187f646c116fd465dda9cbb2d0799`)
  - `Core/DeepBase.HB.Choice.Types.pas` (SHA256: `963fedd0ea91402085391af2b9ed69fa137c23ffd46b340bfe8996dd059ee79e`)
- **测试结果**：**233 / 233 PASS** (0 Failed, 0 Leaked, 0 Errored)
- **交付日期**：2026-09-14

---

## 一、唯一架构定位与正式承接链

AsWish 不再私自拥有或重新定义 `0–9`、`HumanOverride`、`FrameRejection`、`Regenerate`、`Back` 等公共交互语义。

正式承接链：

$$\text{EHAI} \longrightarrow \text{Language Common Contract} \longrightarrow \text{DeepBase Delphi Implementation} \longrightarrow \text{HB} \longrightarrow \text{AsWish Domain Binding (001)}$$

AsWish 正式作为 **Reference Product Binding 001**，通过 `AsWish.Binding.HB.pas` 将通用交互文法与 AsWish 领域模型清晰解耦。

---

## 二、整改项（AW-R01 ~ AW-R06）完成状态

| 整改编号 | 整改项名称 | 严重度 | 状态 | 对应代码与留痕位置 |
|---|---|:---:|:---:|---|
| **AW-R01** | 按公共层符号基准全量对齐 | 必做 | ✅ 完成 | `AsWish.Binding.HB.pas` 文件头登记基准版本与 SHA256；所有公共符号 100% 检索对齐（0 例外） |
| **AW-R02** | 绑定映射表与代码 Profile 漂移对齐 | BLOCKER | ✅ 完成 | 代码显式传入 `eipJudge`、`eipProvide`、`eipProvide`、`eipInform`，映射表与代码逐格一致 |
| **AW-R03** | 三态收敛如实记账 | MINOR | ✅ 完成 | 本报告第三节与第八节显式声明产品侧收敛简化，三态能力由公共层保证 |
| **AW-R04** | Tier C 证据带上用例名 | MINOR | ✅ 完成 | `tests/AsWish.Tests.dpr` 默认 verbose 输出，`WO/evidence/tests-ehai-binding-001R1.txt` 含全部 233 项用例名与通过标记 |
| **AW-R05** | 调用点显式传 Profile | MAJOR | ✅ 完成 | `AsWish.Binding.HB.pas:167-178` 四处调用点全部显式传 Profile |
| **AW-R06** | 真实键盘路径 FrameRejection 端到端复验 | MAJOR | ✅ 完成 | 新增 `ASWISH_V_009_Real_Keyboard_FrameRejection_E2E` 用例，验证物理键盘 `cisKeyboard` + `eokFrameRejection` 链路可达且不退化 |

---

## 三、最新语义与交互映射表（逐格一致）

| 0-9 键位 / EHAI MetaAction | DeepBase / HB Action | Profile（声明与代码实际） | AsWish Controller 映射 | AsWish 领域对象效应 | 语义效应类型 (`TEhaiSemanticEffectKind`) | 提交状态 (`IsCommitted`) |
|---|---|---|---|---|---|---|
| **1..7** (`emaChoose`) | `cakCandidate` | `eipJudge`（代码: `CreateCandidate(..., eipJudge, ...)`） | `ReviewChangeSet(AChangeSetId)` | 渲染 4 层审查视口与 ChangeSet Review Summary | `eseJudgmentMade` | **False** (探索呈现，零基线与 Spec 变更) |
| **8** (`emaRegenerate`) | `cakRegenerate` | `eipProvide`（代码: `CreateRegenerate(eipProvide, ...)`） | `ExportPrompt` | 在当前框架内重新生成 Prompt，不触动 live tree | `eseInformOnly` | **False** (纯探索，零变更) |
| **9** (`emaReframe` - `eokCandidateReject`) | `cakFreeInput` | `eipProvide`（代码: `CreateOverride(..., eipProvide, ...)`） | `SubmitUserIntent(AIntentText, ATree)` | 在当前框架内提交补充/备选意图，生成 ChangeSet | `eseDataProvided` | **False** (待人类审查) |
| **9** (`emaReframe` - `eokAlternativeExpression`) | `cakFreeInput` | `eipProvide`（代码: `CreateOverride(..., eipProvide, ...)`） | `SubmitUserIntent(AIntentText, ATree)` | 在当前框架内表达自定义参数/自然语言，生成 ChangeSet | `eseDataProvided` | **False** (待人类审查) |
| **9** (`emaReframe` - `eokFrameRejection`) | `cakFreeInput` | `eipProvide`（代码: `CreateOverride(..., eipProvide, ...)`） | `SubmitFrameRejection(ARejectedNode, ARejectedTree, AText, ATargetTree, ATargetNode)` | 驳回问题框架，生成 `IsFrameRejection = True` 之 ChangeSet | `eseDataProvided` | **False** (显式记录人类否定原模块，不改 summary) |
| **0** (`emaExit`) | `cakBack` | `eipInform`（代码: `CreateExit(eipInform, ...)`） | 导航返回 / 视口回退 | 非提交退出（Exit without Commitment != Reject != Consent） | `eseInformOnly` | **False** (绝不吊销历史决策与基线) |
| **Commitment Gate** | `ExecuteCommitmentGate` | `eipAuthorize`（代码: `eipAuthorize`） | `AcceptChangeSet(AChangeSetId, ARationale)` | **越过承诺边界**：修改 Canonical Spec trees，记录 formal decision，冻结不可变 Accepted Baseline | `eseAuthorized` | **True** (正式状态持久化提交) |

> **注（三态收敛显式记账，AW-R03）**：  
> 在 `AsWish.Binding.HB.pas` 中，`eokCandidateReject` 与 `eokAlternativeExpression` 走同一分支（`SubmitUserIntent` + `eseDataProvided`），仅 `eokFrameRejection` 单独分流走 `SubmitFrameRejection`。即公共层与 HB 层的三态在 AsWish 领域侧收敛为两态处理。  
> 此为**产品侧有意简化**（因为 AsWish 领域内同框架的候选拒绝与同框架的参数自定义均表现为生成待审 ChangeSet，无需分立数据结构），非语义丢失；三态区分能力由公共层与 HB 表面层保证。

---

## 四、Frame Rejection 领域设计与 FR-AW-01 场景处置

### 1. 架构突破与根因解决
在原有实现中，`SubmitUserIntent` 过度依赖既有 `ANodeId` 的框架，若人类输入否定意图，系统容易强行作为选项 4 覆盖原节点的 `summary`。
本次重构将 `FrameRejection` 作为 AsWish 的一等公民（First-class Domain Concept）：
- `TCandidateIntent` 增加 `IsFrameRejection: Boolean`、`RejectedNodeId: string`、`RejectedTree: TTreeType`。
- `TChangeSet` 增加 `IsFrameRejection: Boolean`、`RejectedNodeId: string`、`RejectedTree: TTreeType`。
- `AsWish.Controller.pas` 引入重载方法：
  - `SubmitUserIntent(const AIntent: TCandidateIntent): string;`
  - `SubmitUserIntent(const AIntentText: string; ATree: TTreeType = ttFunction): string;`（支持无锚点高层意图）
  - `SubmitFrameRejection(const ARejectedNodeId: string; ARejectedTree: TTreeType; const AIntentText: string; const ATargetTree: TTreeType = ttFunction; const ATargetNodeId: string = ''): string;`

### 2. 场景 FR-AW-01 落地事实
- **场景**：AI 针对模块 `mod-orders` 给出候选 1..3。人类输入：“这些都不是。这个模块本身不应该存在，问题在更上游的需求定义。”
- **AsWish 处置事实**：
  1. 绝不成为 `mod-orders` 的选项 4；
  2. 绝不把人类这句否定填入 `mod-orders.summary`；
  3. ChangeSet Item 0：`TargetNodeId = 'mod-orders'`, `Field = 'status'`, `AfterValue = 'frame_rejected'`, `SourceType = cstExplicit`, `Reason = 'Frame rejected by human'`；
  4. ChangeSet Item 1：`TargetNodeId = 'func-root'`（或空无锚点），`TargetTree = ttFunction`, `Field = 'user_intent'`, 完整保留人类高级重构意图；
  5. 承诺网关执行后：`mod-orders.Status` 变为 `nsRejected`，`ReviewStatus` 变为 `rsRejected`；记录 `dtReject` / `dsAccepted` 决策；冻结不可变基线；上游需求树承接新意图。

---

## 五、代码修改清单与 Commit 留痕

本次整改严格遵守连续执行纪律与单 Commit $\le 200$ 行规范：

1. **Commit 1 (`111a29e`)**: `feat(models): add Frame Rejection and unanchored intent support to TCandidateIntent and TChangeSet`
2. **Commit 2 (`9dae7d8`)**: `feat(ingest): add frame rejection serialization and status handling in CandidateIngest`
3. **Commit 3 (`aa5a8f7`)**: `feat(prompts, decisions): support frame rejection prompts and decisions`
4. **Commit 4 (`417d397`)**: `feat(controller): implement SubmitUserIntent overloads and SubmitFrameRejection`
5. **Commit 5 (`e6709a7`)**: `build: add DeepBase search paths to build scripts`
6. **Commit 6 (`c0f7f94`)**: `feat(binding): implement EHAI Reference Product Binding 001 for AsWish`
7. **Commit 7 (`11412c2`)**: `fix(controller, ingest): preserve parent baseline ID in AcceptChangeSet and fix ApplyChangeSet decision check`
8. **Commit 8 (`78a8a7b`)**: `test(ehai): add Tier C test suite ASWISH-V-001 to ASWISH-V-008`
9. **Commit 9 (`57921b7`)**: `docs(evidence): add build, test, and audit request evidence for EHAI Binding 001`
10. **整改 Commit 10 (AW-R01/R02/R05)**: `fix(binding): register symbol baseline v1.0 and align profile parameters with mapping table`
11. **整改 Commit 11 (AW-R04/R06)**: `test(binding): add ASWISH-V-009 keyboard E2E test and enable verbose runner output`
12. **整改 Commit 12 (Evidence)**: `docs(evidence): add R1 build and test evidence and update audit request`

---

## 六、迁移与兼容性说明

1. **向后兼容**：
   - 原有 `SubmitUserIntent(const ANodeId, AIntentText: string)` 与 `SubmitUserIntent(const ANodeId: string; ATree: TTreeType; const AIntentText: string)` 作为转发重载完全保留，现有 CLI 命令与 GUI 按钮 100% 正常运行。
2. **构建脚本解耦**：
   - 依赖通过 Delphi RTL `-U"..\DeepBase\Core;..\DeepBase\VCL"` 标准搜索路径解析，零外部二进制包强耦合。
3. **编码格式**：
   - 所有新增与修改的 Pascal 源码文件均保持 UTF-8 BOM (`\xef\xbb\xbf`)，保证跨环境非 ASCII 注释与字符串绝对安全。

---

## 七、Tier C 自动化测试与物理证据

### 1. 9 项 Tier C 用例清单与断言
- **`ASWISH-V-001`**: `ASWISH_V_001_ReviewChangeSet_Surface_ReadOnly` —— 验证审查 ChangeSet 时仅生成预览视口，Canonical Spec 磁盘文件 100% 保持未修改（PASS）。
- **`ASWISH-V-002`**: `ASWISH_V_002_Canonical_Mutation_Gate` —— 验证未承诺前 Spec 保持原样，经由 `AcceptChangeSet` 人类主权授权后，Spec 真实持久化写入且状态推进为 Confirmed（PASS）。
- **`ASWISH-V-003`**: `ASWISH_V_003_Accepted_Baseline` —— 验证基线演进完整保留不可变父基线关系（`B-0002.Lineage.ParentBaselineId = 'B-0001'`），双向可追溯（PASS）。
- **`ASWISH-V-004`**: `ASWISH_V_004_Frame_Rejection_Scenario_FR_AW_01` —— 验证 FR-AW-01 场景下模块被正确标记 `frame_rejected` 并推进为 `nsRejected`/`rsRejected`，未被污染为选项 4，高层需求意图正确锚向需求树（PASS）。
- **`ASWISH-V-005`**: `ASWISH_V_005_HB_Interaction_Common_Semantic_E2E` —— 验证 HB 0-9 动作 → 通用语义 → AsWish 绑定 → 产生效果全链路（Key 9 输入 → Key 1 预览 → Commitment Gate 授权，全程 trace 完整，状态一致）（PASS）。
- **`ASWISH-V-006`**: `ASWISH_V_006_CandidateSelection_Not_Inherent_Commitment` —— 验证候选选中仅产生评估价值断言（`eseJudgmentMade`），绝不产生非预期的基线冻结或 Spec 写入（PASS）。
- **`ASWISH-V-007`**: `ASWISH_V_007_Regenerate_Pure_Exploration` —— 验证 Key 8（Regenerate）产生 `eseInformOnly`，零 Canonical 变更（PASS）。
- **`ASWISH-V-008`**: `ASWISH_V_008_BackNavigation_Preserves_Decisions` —— 验证 Key 0（BackNavigation）为非提交退出，绝不吊销或影响已有决策与基线合法性（PASS）。
- **`ASWISH-V-009`**: `ASWISH_V_009_Real_Keyboard_FrameRejection_E2E` —— 验证物理键盘 `cisKeyboard` + `eokFrameRejection` 真实端到端路径，验证 HB 控件输入否定后正确分流并执行承诺网关，`mod-orders` 不被污染为选项 4 且原始 summary 完整保留（PASS）。

### 2. 测试执行摘要
- 运行二进制：`tests/AsWish.Tests.exe`
- 测试总数：**233 项**
- 结果：**233 Passed / 0 Failed / 0 Leaked / 0 Errored**
- 原始证据文件：`WO/evidence/tests-ehai-binding-001R1.txt`（包含全部 233 项用例名与逐项执行结果）
- 构建证据文件：`WO/evidence/build-ehai-binding-001R1.txt`（GUI、CLI、Tests 全部 0 错误 0 警告编译）

---

## 八、遗留项与对账台账（Unresolved Items Ledger）

| 编号 | 涉及模块 | 整改前状态 | 整改后对账事实与证据 | 最终结论 |
|---|---|---|---|:---:|
| **L-01** | Profile 漂移 (`1..7`, `8`) | 映射表声明 `eipJudge` / `eipProvide`，代码传入 `eipInform`（终审 M-03） | `AsWish.Binding.HB.pas:168` 传入 `eipJudge`；第 170 行显式传入 `eipProvide`；第 173 行显式传入 `eipProvide`；第 175 行显式传入 `eipInform`。映射表与代码逐格一致，断言通过。 | ✅ 已消除 |
| **L-02** | 三态收敛记账 | 映射表未显式登记 `eokCandidateReject` 与 `eokAlternativeExpression` 合流（终审 n-03） | 第三节与第八节显式登记：此为产品侧有意简化，非语义丢失；三态区分能力由公共层保证。 | ✅ 如实记账 |
| **L-03** | Tier C 证据自立 | `tests-ehai-binding-001.txt` 为点阵输出，不可逐项核验用例名（终审 m-05） | `tests/AsWish.Tests.dpr` 控制台输出调整为 Verbose；`WO/evidence/tests-ehai-binding-001R1.txt` 完整包含全部 233 项用例名（`ASWISH_V_001` ~ `ASWISH_V_009` 逐一标注 `Success`）。 | ✅ 已消除 |
| **L-04** | 真实键盘路径 FrameRejection 复验 | 仅有单选/单元级测试，HB 遗留入口可达性存疑 | 新增 `ASWISH_V_009` 端到端用例，使用 `cisKeyboard` + `eokFrameRejection` 验证全链路闭环，DeepBase R-04 完成后路径通畅。 | ✅ 已消除 |
| **L-05** | 公共层符号基准对齐 | 缺乏机器可核对符号源，文档存在漂移风险 | 严格对齐 `DeepBase\docs\EHAI-Delphi-Symbol-Baseline.md`（v1.0），并在 `AsWish.Binding.HB.pas` 头注释登记 SHA256 指纹。 | ✅ 已消除 |

> **台账结论**：经过 5 项对账与闭环修正，AsWish 仓内已知债务均已如实对账清零，无悬空项，无隐蔽降级。

---

## 九、结论与申请

**WO-20260914-EHAI-BINDING-001R1** 整改工单的 6 项整改要求（AW-R01 ~ AW-R06）与 12 项验收标准全部达成：
- 符号基准严格核对（0 例外）并已登记指纹；
- Profile 漂移已对齐；
- 三态收敛已如实记账；
- Tier C 原始证据含全部 233 个用例名且 100% 通过（0 Failed, 0 Leaked, 0 Errored）；
- GUI / CLI / Tests 三端 0 Warning 0 Error 纯净编译；
- 物理键盘路径真实端到端复验通过。

申请主控/异族模型进行最终核验并裁定 CLOSE。
