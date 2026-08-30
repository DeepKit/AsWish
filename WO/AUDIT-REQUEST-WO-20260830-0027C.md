# AUDIT-REQUEST · WO-20260830-0027C

- 工单：`WO-20260830-0027C-甲-ChangeSet审阅与Decisions写回工单.md`
- 承接仓库：`D:\_Progs\02Business\AsWish`
- 执行方：甲（开发AI）
- 完成时间：2026-08-30
- 门禁规范：非睿智轻量门禁（G1~G5）
- 请求：请主控AI复审本工单并决定是否批准 CLOSE。

---

## 1. 目标与范围达成情况

| 验收项 | 契约要求 | 实施与验证证据 | 状态 |
|---|---|---|---|
| **AC-01** | 用户能看懂 Change Set（语义变化渲染） | `TAsWishCandidateIngest.FormatChangeSetReviewSummary` 格式化语义 Before/After、来源、原因与受影响投影；CLI `changeset review` 支持。 | ✅ 已达成 |
| **AC-02** | 用户能进行现有 Decisions 支持的正式裁决 | `TAsWishDecisionsService.RecordChangeSetDecision` 记录标准 `TSpecDecision`（`dtConfirm` / `dtReject` / `dtClarify`）；CLI `changeset accept/reject` 支持。 | ✅ 已达成 |
| **AC-03** | Reject 不修改 Canonical Spec | `ApplyChangeSet` 在 Reject / Clarify 时直接返回；CLI 验证与单元测试 `ChangeSet_Reject_DoesNotMutateCanonicalSpec` 严格证明 Canonical Spec 0 变动。 | ✅ 已达成 |
| **AC-04** | Accept 才触发 Spec 写回 | `ApplyChangeSet` 仅在 `ADecision.Status = dsAccepted` 时更新节点内容、标记 `ReviewStatus = rsAccepted` 并记录 `DecisionRefs`。 | ✅ 已达成 |
| **AC-05** | 写回后自动执行现有验证 | `RunChangeSetAccept` 写回后调用 `TYamlValidator.ValidateTreeFile` 完成规范验证。 | ✅ 已达成 |
| **AC-06** | 重新打开项目后 Accepted Spec 状态一致 | 重新加载 `trees/` 与 `requirement-decisions.yaml`，节点状态 `accepted`/`confirmed` 与 `decision_refs` 完整一致。 | ✅ 已达成 |
| **AC-07** | 用户可继续自然语言修正上一轮结果 | 支持多次运行 `changeset`，在上一轮 Canonical Spec 状态上继续叠代新意图。 | ✅ 已达成 |
| **AC-08** | Decision 记录可追溯到具体 change 项 | `TSpecDecision` 新增 `ChangeSetId` 与 `ChangeItemIndex` 字段，并在 YAML 序列化/反序列化中完整双向保持。 | ✅ 已达成 |
| **AC-09** | 写回复用 CandidateIngest merge 语义，无第二套更新逻辑 | 完全复用 `CandidateIngest` 节点定位、字段更新、`ReviewStatus`、`GenStatus` 与 `DecisionRefs` 规约。 | ✅ 已达成 |
| **AC-10** | build + 全量测试输出存档为证据，主控独立复核 | 原始证据归档至 `WO\evidence\build-tests-20260830-0027C.txt`、`test-run-20260830-0027C.txt`、`build-apps-20260830-0027C.txt`、`cli-changeset-20260830-0027C.txt`。 | ✅ 已达成 |

---

## 2. 修改文件明细

1. `src/models/AsWish.Models.pas`：在 `TSpecDecision` 增加 `ChangeSetId` 与 `ChangeItemIndex` 字段，建立 Decision 到 ChangeSet 的明确回溯链。
2. `src/core/AsWish.Yaml.Writer.pas`：在 `TYamlWriter.WriteDecision` 中支持 `change_set_id` 与 `change_item_index` 序列化。
3. `src/services/AsWish.Services.Decisions.pas`：在 `Load` 中反序列化 `change_set_id` 与 `change_item_index`；新增 `RecordChangeSetDecision` 方法。
4. `src/services/AsWish.Services.CandidateIngest.pas`：新增 `ApplyChangeSet`（仅在 Accept 时写回 Canonical Spec，Reject/Clarify 严格不变更）与 `FormatChangeSetReviewSummary`（语义化呈现）。
5. `cli/AsWish.CLI.dpr`：增加 `changeset review`、`changeset accept`、`changeset reject` 命令行子命令及端到端写回与校验流程。
6. `tests/Test.AsWish.CandidateIngest.pas`：新增 4 个单元测试用例，覆盖 ChangeSet 语义渲染、Accept 写回、Reject 隔离与 Clarify 隔离。
7. `tests/Test.AsWish.Decisions.pas`：新增 1 个单元测试用例，验证 ChangeSet Decision 的创建、字段关联与磁盘往返一致性。

---

## 3. 架构复用点

- **决策收敛**：完全复用 `TSpecDecision` 与 `decisions/requirement-decisions.yaml`，未建立任何平行审批状态机；
- **状态机复用**：完全复用 `TReviewStatus` (`rsAccepted`/`rsRejected`/`rsUnreviewed`) 与 `TGenStatus` (`gsConfirmed`/`gsDraft`/`gsSkipped`)；
- **写入复用**：完全复用 `TAsWishStoreService.WriteTreeFile` 与 `AtomicWriteTextFile`；
- **校验复用**：写回后复用 `TYamlValidator`。

---

## 4. 证据文件清单

- `WO\evidence\build-tests-20260830-0027C.txt` (测试工程编译日志：Delphi 37.0，0 Error / 0 Warning)
- `WO\evidence\test-run-20260830-0027C.txt` (DUnitX 全量测试日志：146 Passed / 0 Failed / 0 Leaked)
- `WO\evidence\build-apps-20260830-0027C.txt` (GUI 与 CLI 编译日志：0 Error / 0 Warning)
- `WO\evidence\cli-changeset-20260830-0027C.txt` (CLI `changeset review` / `accept` / `reject` 端到端执行与 Canonical Spec 隔离验证日志)

---

## 5. 结论建议

`WO-20260830-0027C` 所有 10 项验收标准均已完成并通过全量验证。只有经过人类 Decision 裁决才能写回 Canonical Spec 的安全闭环已经建立。建议主控 AI 独立复核并裁定 **APPROVED**，予以 CLOSE。
