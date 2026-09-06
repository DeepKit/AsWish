# WO-20260906-0032-甲-Visual-Workflow-Application-Service-Extraction
* 状态: DONE (已完成)
* 依赖: WO-0031 (PASS)
* 范围: 抽象纯净、无 UI / IShell 依赖的 Visual Workflow Application Service (ADR-2)

---

## 1. 交付目标达成情况 (Acceptance Criteria)

| AC 编号 | 验收标准 | 实施结果 | 证据/测试用例 |
|---|---|---|---|
| **AC 1** | Application Service 零 `IShell*` (UI) 依赖 | `TAsWishVisualWorkflowService` 仅依赖 Store, Snapshot, Decisions, Difference 基础服务，零 UI/Winapi 依赖 | `Test01_ZeroUiDependency_HeadlessExecution` |
| **AC 2** | GUI 与 CLI 可调用完全相同的 use-case 方法 | GUI `TAsWishController` 与 `AsWish.CLI.dpr` 统一委托给 `TAsWishVisualWorkflowService` (`ConfirmVisualBaseline`, `RecordDifferenceDecision`, `EvolveBaseline`) | `AsWish.Controller.pas`, `AsWish.CLI.dpr` |
| **AC 3** | Human Judgment 完全且仅来自 Existing Decision 对象 | `ConfirmVisualBaseline` 严格以 `DecisionId` 为前置凭证，拦截空 ID、不存在 ID 及未接受决策 | `Test02_ConfirmVisualBaseline_ValidatesHumanDecision` |
| **AC 4** | Observable 与 Decision 建立可追溯的强关联 | Baseline 记录权威 `DecisionId` 与快照，关联 View 树节点，形成闭环溯源 | `Test03_ConfirmVisualBaseline_Success_LinksDecisionAndSnapshot` |
| **AC 5** | 不新增 rationale 强制验证等私有规则，四出口对齐 | 引入 `TDifferenceJudgment` 4 出口枚举；Rationale 校验与权威完全归由 `TAsWishDecisionsService` 管辖 | `Test04_RecordDifferenceDecision_FourExits`, `Test07_DecisionsAuthority_NoPrivateRationaleRules` |
| **AC 6** | Evolve 操作被 Existing Human Decision 成功拦截与验证 | 拦截未授权决策、空决策或驳回决策；仅允许 `dtConfirm` / `dtAcceptDifference` 演进并记录 `ParentBaselineId` | `Test05_EvolveBaseline_RequiresApprovedDecision` |
| **AC 7** | GUI/CLI 在同输入下能产生哈希等价的 Canonical artifacts | 相同输入确定性生成完全相同的 `ContentHash` 和 `RelationHash` | `Test06_Equivalence_DeterministicBaselineHash` |

---

## 2. 提交台账 (Commit Log)

1. `00e73bf`: `feat(model): add TDifferenceJudgment enum and string conversion helpers`
2. `0ab3ca6`: `feat(workflow): implement TAsWishVisualWorkflowService headless application service`
3. `a003340`: `refactor(controller): delegate visual baseline and difference workflow to TAsWishVisualWorkflowService`
4. `3c626c0`: `refactor(cli): delegate visual confirm, judge, and evolve to TAsWishVisualWorkflowService`
5. `1723fba`: `test(workflow): add automated tests for visual workflow service (AC1-AC4)`
6. `bb57c17`: `test(workflow): add automated tests for evolution guard and hash equivalence (AC5-AC7)`

---

## 3. 测试验证 (Verification Evidence)

* 测试运行器: DUnitX Win64 Console Test Runner
* 执行命令: `tests\AsWish.Tests.exe`
* 结果: 220 Tests Found, 220 Passed, 0 Leaked, 0 Failed, 0 Errored.
* 编译器: Embarcadero Delphi 13.1 (dcc64). GUI (`_build.bat`), CLI (`cli\_build_cli.bat`), Tests (`tests\_build_tests.bat`) 全绿通过。
