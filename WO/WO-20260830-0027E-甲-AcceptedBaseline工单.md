# WO-20260830-0027E · 甲（开发AI）· Accepted Baseline v0（不可变基线）

- 下发时间：2026-08-31 12:00 (GMT+8)
- 下发人：主控AI
- 承接方：**甲（开发AI，AsWish 仓库）**
- 工作仓库：`D:\_Progs\02Business\AsWish`
- 优先级：P0
- 依赖：`0027A/B/C/D` 已全部入 `main`（`AcceptChangeSet → ApplyChangeSet` 链路可用）
- 门禁：非睿智轻量门禁；**双闸门（Engineering Green + Dogfood Green）+ OJP Acceptance**；单 commit ≤200 行；build/test 原始输出存档；主控 APPROVED/RETURNED，未过不得 CLOSE

---

## 一、目标

当 Human Accept 一个 ChangeSet 后，把 resulting Canonical Spec state 冻结为一个 **immutable、hash-addressable、可重载**的 Baseline，并保留 Decision lineage，作为后续 Evidence / Difference 的**不可变比较起点**。

> 一句话：**证明 Human Accept 之后，我们能冻结一个以后不会被悄悄改变的 Spec 参照物。**

## 二、现状（已核实，勿重造）

- 已有 `TAsWishSnapshotService`：文件级快照 → `.AsWish/snapshots/<name>/` + `snapshot.yaml`（字段 `version/label/created_at/files`）。**无 hash、无 lineage、无不可变语义。**
- 已有 `TSpecNode.ContentHash` + `TSpecNode.RelationHash`（节点级）；`TSpecDecision.ContentHash`（决策级）。
- **不存在 `TSpecSnapshot` 类型**（0028 提到的"SpecSnapshot"实为上述 SnapshotService）。
- 缺：快照级 hash、lineage、不可变语义、Baseline 记录类型、Accept 后自动接快照的接线。

## 三、最小数据模型（Baseline 记录，不建 Framework）

```text
Baseline
  baseline_id      B-0001（稳定寻址）
  decision_id      Decision 关联（lineage 起点）
  snapshot_name    复用 TAsWishSnapshotService 的快照名
  tree_type        function / module / view / data
  content_hash     快照级（含各节点 summary / purpose + 内容）
  relation_hash    快照级（各节点 parent_id 归属关系）
  created_at
  lineage          decision_id → change_set_id → intent_id（引用链）
```

**老板裁定，必须遵守**：

1. **ContentHash 必须把节点 `summary`（即 purpose/功能）算进去**——否则 Difference 的 0 层（"为什么它存在"）没有数据可锚。
2. **ContentHash 与 RelationHash 两级分离**：改某节点 summary → 只有 ContentHash 变；只改 parent → 只有 RelationHash 变。
3. **不冻结** workspace / git repo / UI 截图 / 运行环境。**Baseline ≠ Git commit**（Git 是 implementation/world state，Baseline 是"Human 在这个 Decision 上正式认可的 Spec state"）。
4. **不新建平行实体**（`VisualState / VisualBaselineEntity / VisualApproval` 等）；Baseline 是快照的一个语义角色，复用 `TAsWishSnapshotService` + 节点级 hash。

## 四、文件布局（协议落盘，不建第二套目录）

复用 `.AsWish/snapshots/<name>/`；在 `snapshot.yaml` 的 meta 中**增加 baseline 字段块**：

```yaml
baseline:
  baseline_id: "B-0001"
  decision_id: "dec-000X"
  tree_type: "function"
  content_hash: "..."
  relation_hash: "..."
  lineage:
    change_set_id: "cs-..."
    intent_id: "intent-..."
```

## 五、API（Controller 接线，只读语义）

- 新增 `TAsWishBaselineService`（或并入 SnapshotService，由开发裁量，取最短路径）：
  - `CreateBaseline(ADecision, out ABaseline)`：Accept 后调用；
  - `LoadBaseline(ABaselineId)`：重载并回算 hash；
  - `VerifyBaseline(ABaselineId): Boolean`：重算 hash 与落盘比对。
- **不可变语义**：Baseline 创建后不再覆盖/修改；后续 `ApplyChangeSet` 只写 `trees/`，不得写入历史 Baseline 目录。

## 六、状态转换

```text
Accepted Decision
    ↓
ApplyChangeSet（现有）
    ↓
Canonical Spec 更新
    ↓
CreateSnapshot（复用现有）
    ↓
写 baseline 字段块 + 快照级 hash
    ↓
Baseline 落盘（此后只读）
```

## 七、最小测试清单（11 条 DUnitX）

1. Accepted Decision → Baseline 存在
2. Baseline 引用正确 `decision_id`
3. Baseline 含预期 snapshot 内容
4. `content_hash` 确定性（同一状态两次创建 → 相同 hash）
5. `relation_hash` 确定性
6. 改某节点 `summary` → `content_hash` 变、`relation_hash` 不变
7. 只改某节点 `parent_id` → `relation_hash` 变、`content_hash` 不变
8. 重载 Baseline → 相同 hash + 相同 lineage
9. 后续 Spec 修改不改变历史 Baseline（不可变）
10. lineage 可追溯（baseline → decision → change_set → intent）
11. 非法 / 空快照不能成为 Accepted Baseline（fail-closed）

> 11 条全 PASS 才算 Gap 1（Baseline）关闭。原始 build/test 输出存档 `WO/evidence/`。

## 八、验收

### Engineering Acceptance
- 11 条测试全绿；`149/149` 基线不回退（新增用例计入后总数递增）；build 0 Error/0 Warning 原始输出存档。
- 协议落盘与 SPEC §8.1 / §2 布局一致（`snapshot.yaml` 的 baseline 字段块需在 SPEC 登记或说明，见 §九）。

### Dogfood Acceptance
- 用真实自用任务（Dogfood Protocol v0 选定任务）走一次：`Accept → ApplyChangeSet → Baseline 落盘`，产生真实 `B-xxx`，并能 `VerifyBaseline` 通过。

### OJP Acceptance（本票涉 Human Confirmation，必过）
- [ ] Human 判断对象明确（Accept 的 ChangeSet）
- [ ] Baseline 可追溯（lineage → Decision → ChangeSet → Intent）
- [ ] 可重复查看（重载同 hash）
- [ ] AI 未代替 Human 判断
- [ ] 未新增平行实体

## 九、非目标

不做：视觉渲染 / Visual Baseline（0028）、Evidence、Difference、Baseline Framework、语义/运行时/API/DB/环境 baseline、git 集成、UI。

> 若 `snapshot.yaml` 新增字段需同步 SPEC：在交付报告注明，D0 协议补齐可并入本票或另立协议小票，由主控裁定。

## 十、完成后进入

`0028`（Visual Baseline，视觉层，本票为前置）→ `0027F`（Implementation Evidence v0）。

## 完成定义

> 对一个已被 Human Accept 的 Canonical Spec state，能冻结出不可变、hash 可寻址、带 lineage、确定性可重载的 Baseline；后续 Spec 修改不污染历史 Baseline。
