# WO-20260903-0027G · 甲（开发AI）· Structural Difference v0（结构差异 + P2 单树哈希修复）

- 下发时间：2026-09-03 (GMT+8)
- 下发人：主控AI
- 承接方：**甲（开发AI，AsWish 仓库）**
- 工作仓库：`D:\_Progs\02Business\AsWish`
- 优先级：P0
- 依赖：`0027F` 已交付（`implementation-evidence.yaml` 为 Evidence 侧输入）
- 依据：`docs/07.工程-工程路线与Dogfood验收.md` §6.8b.1（Q1 结论，已采纳）+ **P2 裁定（2026-09-03 老板拍板：`tree_type` = 触发冻结的那棵树，基线哈希按单树粒度计算）**
- 门禁：非睿智轻量门禁；双闸门（Engineering Green + Dogfood Green）；单 commit ≤200 行；build/test 原始输出存档；主控 APPROVED/RETURNED，未过不得 CLOSE

---

## 一、目标

计算「同一投影树的**结构差异**」：Baseline 树 vs 0027F 采集的 Evidence 侧结构，用 ContentHash / RelationHash 程序化判定 Missing / Extra / Changed，落成 `difference.yaml`，供 0027H Human Judgment 消费。

> 一句话：**Baseline 和实现之间到底差在哪，机器可判定、人类可审阅。**

## 二、前置 · P2 单树哈希修复（本票第一件事，Q1 落地前提）

**问题**：`TAsWishSnapshotService.CreateBaseline`（`src/services/AsWish.Services.Snapshot.pas:333`）与 `VerifyBaseline`（同文件 :419）调用 `TSpecHash.SnapshotContentHash(AFunc, AMod, AView, AData)`（`src/core/AsWish.Hash.pas:236-251`）把**四棵树合并**后算单哈希 → 不同快照只要内容集合相同，B-0001(function) 与 B-0002(view) 哈希**相同**，差异无法定位到投影。

**裁定**：`tree_type` 语义 = 「触发冻结的那棵树」，基线哈希按**单树粒度**计算（非四树合并）。

**修法**：`CreateBaseline` / `VerifyBaseline` 改为只对 `tree_type` 对应的那棵树计算快照级 `content_hash` / `relation_hash`（单树粒度，节点级 `NodeContentHash` / `NodeRelationHash` 不动）。

**兼容性注记**：修复会改变既有 dogfood 基线的哈希值；当前无生产数据，既有 dogfood 基线直接重建即可（在交付报告注明），不做双轨兼容。

## 三、v0 差异判定规则（Q1 结论，三条，全可程序化）

仅做「**功能投影（function tree）一层**」（Q1 已采纳：v0 只做功能投影，不铺四层）：

1. **Missing**：Baseline 里有、Evidence 里没有的 `node.id`；
2. **Extra**：Evidence 里有、Baseline 里没有的 `node.id`；
3. **Changed**：同一 `node.id` 的 ContentHash 或 RelationHash 与 Baseline 不一致（细分 ContentChanged / RelationChanged，按哪个哈希变了判定）。

**明确不做**：四层全部铺开（只做功能投影一层）；视觉像素 Diff；措辞/语义级 Diff；任何需要 NLP 才能判定的"差异"。

## 四、落盘与 CLI

- 落盘：`.AsWish/difference.yaml`（与 `evidence/` / `snapshots/` 同级单文件，v0 一份活跃差异报告；字段最少集）：

```yaml
baseline_id: "B-xxxx"
tree_type: "function"
computed_at: "..."
items:
  - node_id: "..."
    kind: missing | extra | changed
    changed_aspect: content | relation | both   # 仅 kind=changed 时
    baseline_hash: "..."
    evidence_hash: "..."
```

- CLI 新增子命令（仿 `baseline verify` 模式）：

```text
aswish difference <project-dir> <baseline-id>
```

## 五、红线

- 差异判定**只用哈希与节点集合**，不引入 NLP/LLM 判定；
- 不新建第二套哈希算法（复用 `NodeContentHash` / `NodeRelationHash` / 单树版快照哈希）；
- 不新建 Difference 实体生命周期/状态机（`difference.yaml` 是**计算产物**，不是被审阅的协议实体；对它的裁决走 0027H 的 `Decisions`）。

## 六、最小测试清单（DUnitX）

P2 修复组：
1. 同内容不同触发树（function-only vs view-only）→ 两基线哈希**不同**（P2 回归钉子）；
2. 单树哈希确定性：同一树两次创建 → 相同哈希；
3. 改单树内节点 `summary` → 该基线 `content_hash` 变；只改 `parent_id` → `relation_hash` 变；
4. `VerifyBaseline` 对单树粒度哈希通过。

差异判定组：
5. 构造 Missing / Extra / ContentChanged / RelationChanged 四场景 → 各自 `kind` / `changed_aspect` 判定正确；
6. 无差异 → `items` 为空且命令成功退出；
7. Evidence 文件缺失/损坏 → fail-closed 报错，不产出半截 difference；
8. `difference.yaml` 可被回读（0027H 消费格式即契约）。

> 全 PASS 且既有基线（`172/172` + 0027F 新增）不回退。原始 build/test 输出存档 `WO/evidence/`。

## 七、验收

### Engineering Acceptance
- P2 修复后 `baseline verify` 对新建单树基线全部通过；测试全绿；build 0 Error/0 Warning 原始输出存档。

### Dogfood Acceptance
- 用 0027F 产出的真实 `implementation-evidence.yaml` 对一个真实 Accepted Baseline 跑一次 `difference`，产出真实 `difference.yaml`，差异项（或空差异）与人工抽查一致。

## 八、非目标

不做：Human Confirmation / Revision / Evolution（0027H）；视觉差异（0028 已另立）；四投影全铺开；差异自动裁决；GUI。

## 九、完成后进入

`0027H`（Human Judgment → Revision/Evolution 双出口 + First Closed Loop 验收，本票 `difference.yaml` 为其输入）。

## 完成定义

> 修完 P2 后，任意两个 Accepted Baseline 的哈希能区分触发树；一条命令能对真实 Baseline + 真实 Evidence 算出程序化可判定的 `difference.yaml`，其中每一项差异都能回指到具体 `node.id` 和哪个哈希变了。
