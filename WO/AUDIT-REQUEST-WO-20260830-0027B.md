# AUDIT-REQUEST · WO-20260830-0027B

- 工单：`WO-20260830-0027B-甲-结构化ChangeSet工单.md`
- 承接仓库：`D:\_Progs\02Business\AsWish`
- 执行方：甲（开发AI）
- 完成时间：2026-08-30
- 门禁规范：非睿智轻量门禁（G1~G5）
- 请求：请主控AI复审本工单并决定是否批准 CLOSE。

---

## 1. 目标与范围达成情况

| 验收项 | 契约要求 | 实施与验证证据 | 状态 |
|---|---|---|---|
| **AC-01** | 给定 CandidateIngest，得到结构化 Change Set | `TAsWishCandidateIngest.FormatChangeSetYaml` / `ParseChangeSetYaml` 完整实现 Change Set 结构化；CLI `changeset` 端到端支持。 | ✅ 已达成 |
| **AC-02** | Change Set 可定位到现有 Spec 节点 | `TChangeSet.IntentNodeId` 与 `TChangeItem.TargetNodeId` 精确定位目标 Spec 节点。 | ✅ 已达成 |
| **AC-03** | 能表达 Before / After | `TChangeItem.BeforeValue` 与 `TChangeItem.AfterValue` 完整记录变更前后的字段状态。 | ✅ 已达成 |
| **AC-04** | 区分 explicit / inferred / unknown | `TChangeSourceType = (cstExplicit, cstInferred, cstUnknown)` 强类型枚举严谨区分直接意图、逻辑推断与未知项。 | ✅ 已达成 |
| **AC-05** | 跨投影影响经 `semantic-bundles.yaml` 计算 | `TAsWishCandidateIngest.ComputeAffectedProjections` 根据节点所属语义绑定自动计算关联的 Function / Module / View / Data 投影。 | ✅ 已达成 |
| **AC-06** | 不生成第二套 Proposal 生命周期 | 零新增状态机枚举，完全复用现有 `TGenStatus`, `TReviewStatus` 及 `CandidateIngest` 体系。 | ✅ 已达成 |
| **AC-07** | 不写入 Canonical Spec | Change Set 仅持久化至 `.AsWish/llm/change-set.yaml`，`trees/` 下的 Canonical Spec 完全不受影响。 | ✅ 已达成 |
| **AC-08** | build + 全量测试输出存档为证据 | 原始日志归档至 `WO\evidence\build-tests-20260830-0027B.txt`、`test-run-20260830-0027B.txt`、`build-apps-20260830-0027B.txt`、`cli-changeset-20260830-0027B.txt`。 | ✅ 已达成 |

---

## 2. 修改文件明细

1. `src/models/AsWish.Models.pas`：定义 `TChangeSourceType` 枚举、`TChangeItem` 记录与 `TChangeSet` 记录；在 `TSpecEnums` 增加字符串互转方法。
2. `src/services/AsWish.Services.Prompts.pas`：实现 `WriteChangeInterpretPrompt`，生成将自然语言意向解释为结构化 Change Set 的专用 Prompt 文件。
3. `src/services/AsWish.Services.CandidateIngest.pas`：实现 `FormatChangeSetYaml`、`ParseChangeSetYaml`、`SaveChangeSet`、`LoadChangeSet` 与 `ComputeAffectedProjections`。
4. `cli/AsWish.CLI.dpr`：新增 `changeset` 命令行子命令，支持从自然语言意图一键生成 Change Set 与解释 Prompt。
5. `tests/Test.AsWish.CandidateIngest.pas`：新增 6 个单元测试用例，覆盖 ChangeSet 构造、YAML 往返、落盘加载、语义包投影计算、三种来源类型区分与 Canonical Spec 隔离性。
6. `tests/Test.AsWish.Prompts.pas`：新增 1 个单元测试用例，验证 ChangeInterpretPrompt 的生成与结构完备性。

---

## 3. 架构复用点

- **意图与候选解耦**：将“人类原始意图” (`user_intent`) 与“AI 解释后的候选变化” (`TChangeSet`) 分离，但均收敛在 `CandidateIngest` 与 `.AsWish/llm/`，未产生第三套平行存储或状态体系。
- **跨投影依赖**：直接复用 `TSemanticBundle` (CTF Semantic Bundle)，根据节点参与的 bundle 派生受影响投影，不新增独立图遍历机制。
- **追问与解释区分**：明确划分 `WriteGrillingPrompt`（问用户明确模糊意图）与 `WriteChangeInterpretPrompt`（解意图生成 ChangeSet），职责单一清晰。

---

## 4. 证据文件清单

- `WO\evidence\build-tests-20260830-0027B.txt` (测试工程编译日志：Delphi 37.0，0 Error / 0 Warning)
- `WO\evidence\test-run-20260830-0027B.txt` (DUnitX 全量测试日志：141 Passed / 0 Failed / 0 Leaked)
- `WO\evidence\build-apps-20260830-0027B.txt` (GUI 与 CLI 编译日志：0 Error / 0 Warning)
- `WO\evidence\cli-changeset-20260830-0027B.txt` (CLI `changeset` 端到端执行与 YAML 落盘验证日志)

---

## 5. 结论建议

`WO-20260830-0027B` 所有 8 项验收标准均已完成并通过全量验证。建议主控 AI 独立复核并裁定 **APPROVED**，予以 CLOSE。后续等待下一工程动作 `0027C`（ChangeSet 审阅与 Decisions 写回）。
