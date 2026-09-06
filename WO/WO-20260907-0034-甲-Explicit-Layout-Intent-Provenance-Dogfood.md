# WO-20260907-0034-甲 Explicit Layout Intent Provenance Dogfood

- 工单编号: WO-20260907-0034-甲
- 工单名称: Explicit Layout Intent Provenance Dogfood
- 前置条件: WO-0031 [x], WO-0032 [x], WO-0033 [x], Evidence Review R1 校准已完成
- 承接角色: 甲（开发AI）
- 状态: DONE

---

## 一、唯一研究问题

当 Human 明确确认一个相对位置意图后，这个意图是否能够拥有明确 provenance，并完整穿越：

```text
Human explicit layout intent
        ↓
candidate canonical representation
        ↓
Accepted Visual Baseline
        ↓
Agent Handoff
        ↓
VCL implementation
        ↓
Runtime Observation
        ↓
Formal VCL Comparator
        ↓
Existing Difference
        ↓
Existing RenderDiff / Observable
        ↓
Existing Decisions
```

而不依赖隐含 handoff、fixture 或平台猜测？

---

## 二、目标闭环

必须真实执行：

```text
Human explicit layout intent
        ↓
candidate canonical representation
        ↓
Accepted Visual Baseline
        ↓
Agent Handoff
        ↓
VCL implementation
        ↓
Runtime Observation
        ↓
Formal VCL Comparator
        ↓
Existing Difference
        ↓
Existing RenderDiff / Observable
        ↓
Existing Decisions
```

---

## 三、测试语义范围

只使用 left-of 或其等价方向表达。
不得增加：above、below、gap、spacing、alignment、containment、grouping。
不得为了未来完整性扩大范围。

---

## 四、关键要求：Expected Relation 不得隐含

0034 中必须能够回答：

> **Expected left-of relation 来自哪里？**

必须存在明确 provenance。

禁止答案：
- Comparator knows it
- test fixture knows it
- developer knows it
- handoff prose implicitly says it
- 根据坐标猜的

必须追溯到：Human-confirmed intent / accepted baseline provenance。

---

## 五、非规范标记

为 Dogfood 可以使用：
- experimental candidate representation
- spike-local representation
- in-memory candidate DTO
- non-canonical fixture representation

但必须明确标记：
- NON-CANONICAL
- EVIDENCE-ONLY
- NOT PROTOCOL

---

## 六、验收标准（10 项）

| # | 标准 | 验证方式 | 结果 | 证据指针 |
|---|------|----------|------|----------|
| AC1 | Human 明确确认了 A left-of B，而非工程师隐含假设 | 决策记录可追溯 | PASS | `dogfood_vcl_provenance/.AsWish/requirement-decisions.yaml` (dec-0001) |
| AC2 | Expected relation 有明确 provenance | provenance 字段在盘可查 | PASS | `.AsWish/layout-constraints.json` 及 snapshot 记录完整 provenance 块 |
| AC3 | Agent Handoff 能获得该 intent | handoff 产物包含该关系 | PASS | `.AsWish/handoff/agent-handoff.md` 包含 relation 与 provenance 声明 |
| AC4 | Runtime Extractor 只提供 observation，不提供 intent | runtime-observation.json 无 intent 字段 | PASS | `runtime-observation.json` 仅提取 Name, ClassName, Bounds 事实 |
| AC5 | Comparator 比对 Declared Relation 与 Observed Relation，而非从 Bounds 猜测 | Comparator 代码确认 | PASS | `TAsWishVCLDifferenceComparator` 读取上下文 Declared 约束比对 live bounds |
| AC6 | 故意制造顺序倒置时，ChangedAspect = daRelation | difference.yaml 检验 | PASS | Case A 生成 1 项差异，ChangedAspect=daRelation，含 [provenance: dec-0001] |
| AC7 | 实现符合 relation 时，No important L2 Difference | difference.yaml 无差异项 | PASS | Case B 生成 0 项差异 (`items: []`) |
| AC8 | Human Judgment 仍只通过 Existing Decisions | 决策记录确认 | PASS | `judge` 成功记录决策 dec-0002 (unacceptable) 至 requirement-decisions.yaml |
| AC9 | Core 无 VCL 污染、无 concrete evidence filename、无 SpikeAdapter | 代码扫描 | PASS | Core 保持平台中立；`grep -r SpikeAdapter src/` 结果为空 |
| AC10 | Full Regression PASS | 223/223 | PASS | `WO/evidence/tests-0034-甲.txt`：223 tests passed, 0 leaked, 0 failed |

---

## 七、最终必答问题

只回答：
> Explicit relative-layout intent 是否已经被证明需要一种正式、平台无关、可追溯的 Canonical/Baseline 表达？

回答：**YES**

### Minimal Semantic Requirement（极小语义要求）

基于本次真实闭环 Dogfood 证据，显式相对布局意图穿透完整生命周期必须且仅需具备以下 4 个极小语义要素：

1. **`relation_type`** (相对关系原语):
   - 必须定义标准语义原语（例如 `left-of`），不得依赖具体平台专有属性（如 VCL Left、CSS float、WPF Canvas.Left）。
2. **`source_node_id`** (源视见规范节点标识):
   - 引用 Canonical View Spec 树中的抽象组件标识符（如 `node_btn_cancel`），跨越技术栈中立存在。
3. **`target_node_id`** (目标视见规范节点标识):
   - 引用相对基准组件的抽象标识符（如 `node_btn_confirm`）。
4. **`provenance`** (人类意图源头追溯元数据):
   - `decision_id`: 产生/确认该意图的人类决策标识符（如 `dec-0001`）。
   - `confirmed_by`: 确认主体（如 `human`）。
   - `statement`: 人类意图述语（如 `Cancel button must be placed left-of Confirm button`）。
   - `confirmed_at`: 确认时间戳（ISO 8601）。

**归因理由**：
若缺少 1~3，下游 Agent 实施与 Comparator 比对无法获取确定性拓扑结构，必然退化为不可移植的坐标硬编码或私下猜测；若缺少 4（`provenance`），生成的差异项（Difference）将脱离“预期与现实之差”的因果链条，人类裁决时无法获知预期来源，打破了 Difference 与 Decision 的不可辩驳追溯性。

---

## 八、明确不做

0034 不做：
- FMX
- Web
- L3 semantic token
- above/below
- gap
- alignment
- layout engine
- style protocol
- schema migration
- 正式 protocol modification

---

## 九、交付物

1. Dogfood 现场目录（含 .AsWish/ 完整产物）：`dogfood_vcl_provenance/`
2. 操作日志：`WO/evidence/dogfood-0034-甲.log`
3. 编译与测试日志：`WO/evidence/build-0034-甲.txt`、`WO/evidence/tests-0034-甲.txt`
4. Git 提交：每 commit <= 200 行，前缀 `feat(provenance)` 或 `test(provenance)`
5. 工单状态更新：标记为 DONE
6. 最终 YES/NO 答案：**YES**（含 Minimal Semantic Requirement）

---

## 十、纪律提醒

- 本工单为定向证据收集，不是 Protocol 实现。
- 所有 candidate representation 必须标记 NON-CANONICAL / EVIDENCE-ONLY。
- 未收到主控 PASS 裁定前，不得进入 Protocol Change Proposal。
- 完成后 STOP，提交结果等待 Human / Architecture Review。
