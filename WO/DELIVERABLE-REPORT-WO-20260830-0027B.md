# WO-20260830-0027B 交付汇报

- 交付工单：`WO-20260830-0027B · 甲（开发AI）· CandidateIngest → 结构化 Change Set`
- 交付时间：2026-08-30 19:17 (GMT+8)
- 承接仓库：`D:\_Progs\02Business\AsWish`
- 核心纪律：将“人类原始意图”与“AI 解释后的候选变化”解耦分开，全部收敛进现有 CandidateIngest / Decisions 体系，不修改 Canonical Spec，不新建平行实体。

---

## 1. 目标与处理链达成情况

达成链条：
```text
I said (TCandidateIntent) → AI understood (TChangeSet / Prompts) → We decided (Decisions / CandidateIngest)
```

| 验收项 | 契约要求 | 实施与验证证据 | 状态 |
|---|---|---|---|
| **AC-01** | 给定 CandidateIngest，得到结构化 Change Set | `TAsWishCandidateIngest.FormatChangeSetYaml` / `ParseChangeSetYaml` 完整实现 Change Set 序列化与解析；CLI `changeset` 端到端支持。 | ✅ 已达成 |
| **AC-02** | Change Set 可定位到现有 Spec 节点 | `TChangeSet.IntentNodeId` 与 `TChangeItem.TargetNodeId` 精确回溯目标 Spec 节点。 | ✅ 已达成 |
| **AC-03** | 能表达 Before / After | `TChangeItem.BeforeValue` 与 `TChangeItem.AfterValue` 完整记录字段变更前后的对照。 | ✅ 已达成 |
| **AC-04** | 区分 explicit / inferred / unknown | `TChangeSourceType = (cstExplicit, cstInferred, cstUnknown)` 强类型枚举严谨区分直接意图、逻辑推断与未知项。 | ✅ 已达成 |
| **AC-05** | 跨投影影响经 `semantic-bundles.yaml` 计算 | `TAsWishCandidateIngest.ComputeAffectedProjections` 根据节点所属语义绑定自动计算关联的 Function / Module / View / Data 投影。 | ✅ 已达成 |
| **AC-06** | 不生成第二套 Proposal 生命周期 | 零新增状态机枚举，完全复用现有 `TGenStatus`, `TReviewStatus` 及 `CandidateIngest` 体系。 | ✅ 已达成 |
| **AC-07** | 不写入 Canonical Spec | Change Set 仅持久化至 `.AsWish/llm/change-set.yaml`，`trees/` 下的 Canonical Spec 完全不受影响。 | ✅ 已达成 |
| **AC-08** | build + 全量测试输出存档为证据 | 原始日志归档至 `WO\evidence\build-tests-20260830-0027B.txt`、`test-run-20260830-0027B.txt`、`build-apps-20260830-0027B.txt`、`cli-changeset-20260830-0027B.txt`。 | ✅ 已达成 |

---

## 2. 修改文件清单

| 文件路径 | 变更类型 | 说明 |
|---|---|---|
| [`src/models/AsWish.Models.pas`](file:///d:/_Progs/02Business/AsWish/src/models/AsWish.Models.pas) | 修改 | 定义 `TChangeSourceType` 枚举、`TChangeItem` 记录与 `TChangeSet` 记录；在 `TSpecEnums` 增加字符串互转方法 |
| [`src/services/AsWish.Services.Prompts.pas`](file:///d:/_Progs/02Business/AsWish/src/services/AsWish.Services.Prompts.pas) | 修改 | 实现 `WriteChangeInterpretPrompt`，生成将自然语言意向解释为结构化 Change Set 的专用 Prompt 文件 |
| [`src/services/AsWish.Services.CandidateIngest.pas`](file:///d:/_Progs/02Business/AsWish/src/services/AsWish.Services.CandidateIngest.pas) | 修改 | 实现 `FormatChangeSetYaml`、`ParseChangeSetYaml`、`SaveChangeSet`、`LoadChangeSet` 与 `ComputeAffectedProjections` |
| [`cli/AsWish.CLI.dpr`](file:///d:/_Progs/02Business/AsWish/cli/AsWish.CLI.dpr) | 修改 | 新增 `changeset` 命令行子命令，支持从自然语言意图一键生成 Change Set 与解释 Prompt |
| [`tests/Test.AsWish.CandidateIngest.pas`](file:///d:/_Progs/02Business/AsWish/tests/Test.AsWish.CandidateIngest.pas) | 修改 | 新增 6 个单元测试用例，覆盖 ChangeSet 构造、YAML 往返、落盘加载、语义包投影计算、三种来源类型区分与 Canonical Spec 隔离性 |
| [`tests/Test.AsWish.Prompts.pas`](file:///d:/_Progs/02Business/AsWish/tests/Test.AsWish.Prompts.pas) | 修改 | 新增 1 个单元测试用例，验证 ChangeInterpretPrompt 的生成与结构完备性 |
| [`WO/AUDIT-REQUEST-WO-20260830-0027B.md`](file:///d:/_Progs/02Business/AsWish/WO/AUDIT-REQUEST-WO-20260830-0027B.md) | 新建 | 复审请求与验收台账 |
| `WO/evidence/build-tests-20260830-0027B.txt` | 新建 | 测试工程编译原始证据（0 错误 0 警告） |
| `WO/evidence/test-run-20260830-0027B.txt` | 新建 | DUnitX 全量测试原始证据（141/141 通过） |
| `WO/evidence/build-apps-20260830-0027B.txt` | 新建 | 主程序与 CLI 编译原始证据（0 错误 0 警告） |
| `WO/evidence/cli-changeset-20260830-0027B.txt` | 新建 | CLI `changeset` 端到端执行与 YAML 落盘验证日志 |

---

## 3. 架构复用点

- **意图与候选解耦**：将“人类原始意图” (`user_intent`) 与“AI 解释后的候选变化” (`TChangeSet`) 分离，但均收敛在 `CandidateIngest` 与 `.AsWish/llm/`，未产生第三套平行存储或状态体系；
- **跨投影依赖**：直接复用 `TSemanticBundle` (CTF Semantic Bundle)，根据节点参与的 bundle 派生受影响投影，不新增独立图遍历机制；
- **追问与解释区分**：明确划分 `WriteGrillingPrompt`（问用户明确模糊意图）与 `WriteChangeInterpretPrompt`（解意图生成 ChangeSet），职责单一清晰；
- **单一写入保护**：完全复用 `TAsWishStoreService.AtomicWriteTextFile`，保证候选落盘为原子操作。

---

## 4. 测试结果（证据）

* **测试框架**：DUnitX
* **运行结果**：**141 Tests Found / 141 Tests Passed / 0 Failed / 0 Errored / 0 Leaked**
* **回归情况**：既有 134 项测试（含原有测试与 0027A 测试）全部通过，新增 7 项 WO-0027B 专用测试全部通过。
* **原始日志**：[`WO/evidence/test-run-20260830-0027B.txt`](file:///d:/_Progs/02Business/AsWish/WO/evidence/test-run-20260830-0027B.txt)

---

## 5. Build 结果（证据）

* **主程序 (`bin/AsWish.exe`)**：Delphi 13.1 Win64 编译通过（15,773 行代码，0 Error / 0 Warning / 1 Hint）；
* **CLI (`cli/bin/AsWish.CLI.exe`)**：Delphi 13.1 Win64 编译通过（10,634 行代码，0 Error / 0 Warning）；
* **测试套件 (`tests/AsWish.Tests.exe`)**：Delphi 13.1 Win64 编译通过（16,798 行代码，0 Error / 0 Warning）；
* **原始日志**：[`WO/evidence/build-apps-20260830-0027B.txt`](file:///d:/_Progs/02Business/AsWish/WO/evidence/build-apps-20260830-0027B.txt) · [`WO/evidence/build-tests-20260830-0027B.txt`](file:///d:/_Progs/02Business/AsWish/WO/evidence/build-tests-20260830-0027B.txt)

---

## 6. CLI / 实际运行结果

执行命令：
```powershell
cli\bin\AsWish.CLI.exe changeset protocol\examples\seed-python-fastapi func-orders function "Add discount percentage field to order line items"
```
输出：
```text
[changeset] generated change set cs-func-orders-01 for func-orders (function)
  saved change set: protocol\examples\seed-python-fastapi\.AsWish\llm\change-set-cs-func-orders-01.yaml
  saved prompt:     protocol\examples\seed-python-fastapi\.AsWish\prompts\change-interpret-func-orders.md
```
生成的 Change Set 持久化内容：
```yaml
version: "1.2"
change_set_id: "cs-func-orders-01"
intent_node_id: "func-orders"
intent_tree: function
raw_user_intent: "Add discount percentage field to order line items"
author: "human"
created_at: "2026-08-30T19:16:00+08:00"
affected_projections:
  - function
items:
  - target_node_id: "func-orders"
    target_projection: function
    field: "summary"
    before: ""
    after: "Add discount percentage field to order line items"
    source_type: explicit
    reason: "Interpreted from human user intent"
```
* **原始日志**：[`WO/evidence/cli-changeset-20260830-0027B.txt`](file:///d:/_Progs/02Business/AsWish/WO/evidence/cli-changeset-20260830-0027B.txt)

---

## 7. Git Commit

* **Commit Hash**：`78d8e0ce9a0f023d8c1c4f24f469956d3ea089e9`
* **Commit Message**：`feat(candidate): implement WO-20260830-0027B structured change set interpretation`
* **工作区状态**：Clean

---

## 8. 未解决问题（0 项）

本工单范围内无未决 blocker。

---

## 9. 下一步建议

按工单规划，后续工程动作进入 **`WO-20260830-0027C`（ChangeSet 审阅与 Decisions 写回）**：
* 承接已生成的 `TChangeSet`；
* 用户/主控完成审阅（Accept / Reject / Clarify）；
* 触发既有 `Decisions` 决策合并并安全写回 Canonical Spec (`trees/`)。
