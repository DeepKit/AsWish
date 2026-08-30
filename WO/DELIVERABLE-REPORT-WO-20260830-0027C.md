# WO-20260830-0027C 交付汇报

- 交付工单：`WO-20260830-0027C · 甲（开发AI）· Change Set 审阅与 Decisions 写回`
- 交付时间：2026-08-30 19:32 (GMT+8)
- 承接仓库：`D:\_Progs\02Business\AsWish`
- 核心准则：**只有 Human Decision 才能把 ChangeSet 变成 Canonical Spec**；Reject/Clarify 严格不污染 Canonical Spec。

---

## 1. 目标与处理链达成情况

完整闭环链条：
```text
TChangeSet (AI understood)
    ↓
Human Review (FormatChangeSetReviewSummary / changeset review)
    ↓
Accept / Reject / Clarify
    ↓
Existing Decisions (RecordChangeSetDecision / requirement-decisions.yaml)
    ↓
Approved Changes (ApplyChangeSet)
    ↓
Canonical Spec (.AsWish/trees/ + Validation)
```

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

## 2. 修改文件清单

| 文件路径 | 变更类型 | 说明 |
|---|---|---|
| [`src/models/AsWish.Models.pas`](file:///d:/_Progs/02Business/AsWish/src/models/AsWish.Models.pas) | 修改 | `TSpecDecision` 增加 `ChangeSetId` 与 `ChangeItemIndex` 字段 |
| [`src/core/AsWish.Yaml.Writer.pas`](file:///d:/_Progs/02Business/AsWish/src/core/AsWish.Yaml.Writer.pas) | 修改 | `WriteDecision` 增加 `change_set_id` 与 `change_item_index` 序列化 |
| [`src/services/AsWish.Services.Decisions.pas`](file:///d:/_Progs/02Business/AsWish/src/services/AsWish.Services.Decisions.pas) | 修改 | 反序列化 ChangeSet 关联字段；新增 `RecordChangeSetDecision` 方法 |
| [`src/services/AsWish.Services.CandidateIngest.pas`](file:///d:/_Progs/02Business/AsWish/src/services/AsWish.Services.CandidateIngest.pas) | 修改 | 新增 `ApplyChangeSet` 与 `FormatChangeSetReviewSummary` |
| [`cli/AsWish.CLI.dpr`](file:///d:/_Progs/02Business/AsWish/cli/AsWish.CLI.dpr) | 修改 | 增加 `changeset review` / `accept` / `reject` 命令与自动化写回/验证流程 |
| [`tests/Test.AsWish.CandidateIngest.pas`](file:///d:/_Progs/02Business/AsWish/tests/Test.AsWish.CandidateIngest.pas) | 修改 | 新增 4 个单元测试用例（Review渲染、Accept写回、Reject隔离、Clarify隔离） |
| [`tests/Test.AsWish.Decisions.pas`](file:///d:/_Progs/02Business/AsWish/tests/Test.AsWish.Decisions.pas) | 修改 | 新增 1 个单元测试用例（Decision与ChangeSet关联字段往返） |
| [`WO/AUDIT-REQUEST-WO-20260830-0027C.md`](file:///d:/_Progs/02Business/AsWish/WO/AUDIT-REQUEST-WO-20260830-0027C.md) | 新建 | 复审请求与验收台账 |
| `WO/evidence/build-tests-20260830-0027C.txt` | 新建 | 测试套件编译日志证据（0 Error / 0 Warning） |
| `WO/evidence/test-run-20260830-0027C.txt` | 新建 | DUnitX 全量测试证据（146/146 Passed） |
| `WO/evidence/build-apps-20260830-0027C.txt` | 新建 | 主程序与 CLI 编译日志证据（0 Error / 0 Warning） |
| `WO/evidence/cli-changeset-20260830-0027C.txt` | 新建 | CLI 端到端实际执行证据（Review/Accept/Reject） |

---

## 3. Accept / Reject / Clarify 实际行为与 Canonical Spec 验证

### (1) Accept 行为与 Canonical Spec 写回
- **调用**：`AsWish.CLI.exe changeset accept <project-dir> <changeset-id> <rationale>`
- **行为**：
  1. 生成正式 `TSpecDecision`（`Status = dsAccepted`，`DecisionType = dtConfirm`，写入 `requirement-decisions.yaml`）；
  2. 触发 `ApplyChangeSet`，将 `TChangeItem.AfterValue` 写入目标节点的字段；
  3. 目标节点 `ReviewStatus := rsAccepted`，`GenStatus := gsConfirmed`，`Status := nsConfirmed`，追加 `decision_refs`；
  4. 将更新后的 Trees 规范原子写入 `.AsWish/trees/`；
  5. 触发 `TYamlValidator` 规范验证。
- **写回后 Spec 验证**：
  ```yaml
  nodes:
    - id: "func-inventory"
      tree: function
      title: "Inventory Management"
      summary: "REST API for inventory and real-time stock alert"
      status: confirmed
      gen_status: confirmed
      review_status: accepted
      decision_refs:
        - "dec-001"
        - "dec-0003"
  ```

### (2) Reject 行为与 Canonical Spec 绝对保护
- **调用**：`AsWish.CLI.exe changeset reject <project-dir> <changeset-id> <rationale>`
- **行为**：
  1. 生成正式 `TSpecDecision`（`Status = dsRejected`，`DecisionType = dtReject`，写入 `requirement-decisions.yaml`）；
  2. `ApplyChangeSet` 检测到非 Accept 状态，立即返回且 0 节点被修改；
  3. `.AsWish/trees/` 下的 Canonical Spec 完全保持不变。
- **验证**：`ChangeSet_Reject_DoesNotMutateCanonicalSpec` 单元测试与 CLI 端到端测试均 100% 证实 Canonical Spec 未受任何破坏。

### (3) Clarify 行为
- **行为**：
  1. 不得猜测或隐式写入；
  2. 记录 `dtClarify` 意向，保留原 Spec 不变，等待人类进一步自然语言输入。

---

## 4. 测试与 Build 验证（证据）

- **测试套件**：DUnitX 全量 **146 Tests Found / 146 Tests Passed / 0 Failed / 0 Errored / 0 Leaked**
- **主程序**：`bin/AsWish.exe` 编译成功（0 Error / 0 Warning）
- **CLI**：`cli/bin/AsWish.CLI.exe` 编译成功（0 Error / 0 Warning）
- **证据文件**：
  - `WO\evidence\build-tests-20260830-0027C.txt`
  - `WO\evidence\test-run-20260830-0027C.txt`
  - `WO\evidence\build-apps-20260830-0027C.txt`
  - `WO\evidence\cli-changeset-20260830-0027C.txt`

---

## 5. Git Commit

- **Commit Hash**：`ece79a25b11eb080f4f981dc64468f7b76aa9189`
- **Commit Message**：`feat(candidate): implement WO-20260830-0027C change set human review and decisions writeback`

---

## 6. 未解决问题（0 项）

本工单范围内所有目标均已达成，无 blocker。

---

## 7. 下一票建议

完成 `0027A`（自然语言意图输入）、`0027B`（结构化 Change Set 解释）和 `0027C`（人类审阅与 Decisions 安全写回）之后，已完全具备闭环核心能力。建议后续按计划进入 **`WO-20260830-0027D`（GUI 侧交互与 First Closed Loop 端到端集成）** 或 **D0 里程碑总体验收**。
