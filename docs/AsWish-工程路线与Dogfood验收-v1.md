# AsWish 工程路线与 Dogfood 验收 v1

> **English title**: Engineering Roadmap & Dogfood Acceptance  
> **版本**：v1.0  
> **日期**：2026-08-30  
> **产品**：AsWish  
> **状态**：当前工程执行基线
>
> **与既有文档的关系（SSOT 指向，不复制）**：
>
> - 产品身份、层级、核心研究问题、Difference 性质：权威定义见 [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md)，本文不复述
> - 产品功能架构、七环闭环、所见即所得与视觉阶段：见 [`AsWish-产品功能与愿景蓝图-v1.md`](AsWish-产品功能与愿景蓝图-v1.md)
> - 协议与 `.AsWish/` 结构：权威见 [`../SPEC.md`](../SPEC.md) 与 [`../protocol/`](../protocol/)
> - 工程纪律、门禁与提交规则：见 [`../AGENTS.md`](../AGENTS.md)
> - 文档治理与权威注册表：见 [`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md)
> - 各票原始需求与 AC：见 `WO/` 下对应工单；**工单原文为需求权威，本文只定义路线顺序与双闸门验收**

---

## 一、为什么现在进入 First Closed Loop

AsWish 当前阶段判定：

```text
Stage 1  First Contact    —— 陌生开发者能下载、运行、理解、完成第一次实验
        ↓
Stage 2  First Closed Loop —— AsWish 自己完成一次完整闭环
```

进入 Stage 2 的理由是工程性的，不是市场性的：

- 主链**前半段**（意图承载 → 结构化解释 → 决策）已有真实代码，但**后半段**（实现证据 → 差异 → 人类裁决 → 修订）在代码层仍为空白；
- 未跑通整条链之前，任何"Difference 被看见"的主张都只是设计稿，不构成工程证据；
- 公开发布的第一个实验若由第三方完成，失败成本与解释成本都由第三方承担；由 AsWish 自己先承担，才能确定链本身是否成立。

因此 Stage 2 的第一目标不是"功能变多"，而是：

> **让 AsWish 成为自己的第一个真实用户，亲自用 AsWish 完成一次完整闭环。**

即：

> **AsWish 自己开发 AsWish，同时使用 AsWish 验证 AsWish。**

---

## 二、为什么 AsWish 必须自己 Dogfood

三条工程理由：

1. **可信度**：`Test my claim` 的前提是 claim 先在自己身上被检验。自己不跑，无权邀请第三方跑。
2. **反例优先权**：最有可能推翻 AsWish 主张的，是真实使用中的失败。Dogfood 让失败先发生在内部，成本最低。
3. **链的完整性不可分段证明**：单独证明"能生成 Change Set"或"能渲染"都不等于闭环。只有同一任务贯穿全程，才能证明链是连通的。

Dogfood 不是演示，不是营销，是**主张的自检验**。

---

## 三、双闸门：Engineering Green + Dogfood Green

工程推进不再以"代码完成 + 测试通过"为唯一放行条件。每一票必须过两道门：

```text
Engineering Acceptance → Engineering Green
Dogfood Acceptance     → Dogfood Green

Engineering Green + Dogfood Green  →  方可进入下一票
```

两者的分工：

| 闸门                    | 回答的问题                 | 证明方式                                |
| --------------------- | --------------------- | ----------------------------------- |
| **Engineering Green** | 这一票的代码是否正确、可回归、可交付？   | build 原始输出存档 + DUnitX 全量通过 + 主控独立复核 |
| **Dogfood Green**     | 这一票的能力在真实使用中真的被用起来了吗？ | 用 AsWish 自身任务跑通本票环节，产生真实工程证据        |

> 只过 Engineering Green **不等于完工**。  
> `134/134` 只是 Engineering Green，不是 Dogfood Green。

### Engineering Green 检查单

```text
Build        构建成功，原始输出存档
Tests        DUnitX 全量通过，原始输出存档
CLI / GUI    涉及入口可手动走通
Protocol     落盘产物符合现有协议，通过 schema / validation 校验
Regression   受影响模块测试 + 全量测试通过
Git diff     变更范围与本票声明一致，无越界修改
```

### Dogfood Green 检查单（"五真实"，缺一不可）

```text
真实任务     选定的 Dogfood Task，不是构造样例
真实人类     由人做出真实判断；否决与修正同样算真实判断
真实 AsWish  使用当前 AsWish 本体（CLI / GUI / 协议落盘）
真实 Agent   实施由外部 Agent（Claude Code / Codex / Cursor 等）完成
真实结果     产出真实的 Evidence / Difference / Revision 记录
```

> 自动化测试通过**不能替代**以上任何一项。

门禁执行细则（build/test 证据存档、单 commit 规模、APPROVED/RETURNED）以 [`../AGENTS.md`](../AGENTS.md) 与《非睿智轻量门禁规范-v1》为准。

---

## 四、工单依赖顺序

正式采用的顺序：

```text
0027A  ✓ 已实现（main，27c268d）
  ↓
0027B  ✓ 已实现（main，78d8e0c）
  ↓
0027D-D0   Change Set schema 冻结            ✓ 已实现（main，SPEC §8.1 追认冻结）
  ↓
0027C  Change Set 审阅与 Decisions 写回       ✓ 已实现（main，ece79a2）
  ↓
0027D-D1   证据链落盘与协议收口               ✓ 已实现（main，ba4b56f）
  ↓
0027D-R1   GUI Review Surface（建议票，待裁定立票）
  ↓
0028   Accepted Visual Baseline
  ↓
Implementation Evidence v0
  ↓
Difference v0
  ↓
Human Confirmation
  ↓
Revision
  ↓
First Closed Loop 验收
```

当前测试基线：DUnitX **149 / 149 全绿**（证据：`WO/evidence/test-run-20260830-0027D.txt`）。

纪律：

- **不并发扩展整套生态**。一次只推一票，一票过双闸门才进下一票。
- **0027D 拆成两个里程碑**：D0 是 B/C 的协议前置，D1 是收口。工单原文见 `WO/WO-20260830-0027D-甲-证据链与协议落盘工单.md` §二。
- 0028 与 Difference v0 **不得合并**（工单原文 §十二明确"两票不得合并"）。
- **⚠ 注意**：0027A～D 目前只过 Engineering Green（149/149 + 证据存档）；**尚未过 Dogfood Green**——链路还没有被一次真实自用任务跑通。双闸门要求见 §三。

---

## 五、工单统一模板

以后每一票至少包含以下 8 项，缺项不得开工：

```text
1. 这一票解决什么能力
2. 这一票明确不解决什么
3. 工程完成条件
4. AsWish 自用任务
5. 真实使用必须发生什么
6. Engineering Acceptance
7. Dogfood Acceptance
8. 完成后才能进入哪一票
```

模板用法见 §六每票实例；工单原文的 Goal / Implementation / Test 仍保留在 `WO/` 中，本文不复制。

---

## 六、每票能力变化与双闸门验收

### 6.1 WO-20260830-0027A · CandidateIngest 自然语言修订入口

**产品问句**：我想改什么？  
**输出**：`Human Intent`

| 项                         | 内容                                                                                 |
| ------------------------- | ---------------------------------------------------------------------------------- |
| 1. 解决什么能力                 | 人类用自然语言告诉 AsWish"我想改什么"，意图被承载并持久化                                                  |
| 2. 明确不解决什么                | AI 解释意图、Change Set、自动修改 Spec、完整 Decision、Difference                                |
| 3. 工程完成条件                 | CLI `intent` 可提交；持久化到 `.AsWish/llm/candidate-intent.yaml`；不清晰时复用 `grilling_ticket` |
| 4. AsWish 自用任务            | 用 CLI `intent` 提交一个针对 AsWish 自身的真实修改意图                                             |
| 5. 真实使用必须发生什么             | 意图原文被原样保存，未触发任何 Canonical Spec 变更                                                  |
| 6. Engineering Acceptance | 落盘可回读；grilling 分支可触发；DUnitX 全量通过；build 输出存档                                        |
| 7. Dogfood Acceptance     | 存在一个由真实任务产生的 `candidate-intent.yaml`，可追溯到具体节点                                      |
| 8. 完成后进入                  | 0027B                                                                              |

> 边界纪律：`Human Natural Language → Automatic Spec Mutation` 是被明确禁止的形态。本票只承载，不解释、不改 Spec。

**状态**：✓ 已实现并入 `main`（`27c268d`）。

---

### 6.2 WO-20260830-0027B · 结构化 Change Set

**产品问句**：你的意思是不是这样？  
**输出**：`Candidate / Change Set`  
**人类决定**：Accept / Reject / Unresolved

| 项                         | 内容                                                                                                                          |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1. 解决什么能力                 | 把 0027A 的自然语言意图，经 LLM 解释成结构化 Change Set                                                                                     |
| 2. 明确不解决什么                | 人类裁决与写回（0027C）、Canonical Spec 修改、视觉表现                                                                                       |
| 3. 工程完成条件                 | `TChangeSet` / `TChangeItem`；`WriteChangeInterpretPrompt`；落盘 `.AsWish/llm/change-set.yaml`；区分 explicit / inferred / unknown |
| 4. AsWish 自用任务            | 对 0027A 已提交的那一条真实意图，生成结构化 Change Set                                                                                        |
| 5. 真实使用必须发生什么             | Change Set 可定位到现有 Spec 节点，可表达 Before / After                                                                                |
| 6. Engineering Acceptance | 格式往返一致；跨投影影响经 `semantic-bundles.yaml`；不生成第二套 Proposal 生命周期；不写 Canonical Spec；DUnitX 全量通过                                    |
| 7. Dogfood Acceptance     | 该真实意图产生的 Change Set 中，至少有一条 `inferred` 或 `unknown` 被人指出"解释错了"或"解释对了"，并记录该判断                                                 |
| 8. 完成后进入                  | 0027D-D0 → 0027C                                                                                                            |

> Change Set 是 CandidateIngest 的**解释结果**，不是新的 Proposal 实体。

**状态**：✓ 已实现并入 `main`（`78d8e0c`）。协议 schema 已由 SPEC §8.1 追认冻结（见 §十六 C-1）。

---

### 6.3 WO-20260830-0027D · D0 里程碑（Change Set schema 冻结）

**产品问句**：我们用什么结构承载"AI 的解释"？  
**输出**：冻结的最小协议 schema

| 项                         | 内容                                                     |
| ------------------------- | ------------------------------------------------------ |
| 1. 解决什么能力                 | 冻结 Change Set schema、落盘位置、Decision 关联字段，作为 B/C 的协议前置   |
| 2. 明确不解决什么                | 证据链落盘（D1）、实现机制、视觉表现                                    |
| 3. 工程完成条件                 | schema 定义 + 落盘位置 + Decision 关联字段三项冻结并报裁定               |
| 4. AsWish 自用任务            | 用 0027B 已产生的真实 `change-set.yaml` 反向校验 schema 是否够用      |
| 5. 真实使用必须发生什么             | 已落盘的真实 Change Set 能被 schema 完整描述，不丢字段                  |
| 6. Engineering Acceptance | schema 通过协议校验；与既有 `decisions` / `trees` 字段不冲突；协议变更记录存档 |
| 7. Dogfood Acceptance     | 真实 Change Set 文件通过 schema 校验，无需为迁就 schema 删减真实字段       |
| 8. 完成后进入                  | 0027C                                                  |

**状态**：✓ 已实现（**追认方式**，`main`）。`SPEC.md` §8.1 已冻结 Intent → Change Set → Decision Traceability 链与落盘路径（`.AsWish/llm/`、`.AsWish/decisions/`）。
> 历史注记：0027D 交付报告 AC-08 称"D0 在 B/C 开工前严格固化"，与实际时序不符——B/C 实现在先、协议 §8.1 追认在后。**终态一致**，但作为工程事实的时序以本注记为准（详见 §十六 C-1）。

---

### 6.4 WO-20260830-0027C · Change Set 审阅与 Decisions 写回

**产品问句**：我们确认的到底是什么？  
**输出**：`Decision` + 可见 Baseline 前的一致性确认

| 项                         | 内容                                                                                           |
| ------------------------- | -------------------------------------------------------------------------------------------- |
| 1. 解决什么能力                 | 人类用现有 `Decisions` 裁决 Change Set；Accept 后才写回 Canonical Spec                                   |
| 2. 明确不解决什么                | 视觉基线（0028）、实现证据、Difference；不新建裁决实体                                                           |
| 3. 工程完成条件                 | 语义化 Review 展示（非 YAML Diff）；Decision 可引用具体 change 项；Accept 触发写回并复用 `CandidateIngest` merge 语义 |
| 4. AsWish 自用任务            | 对 0027B 产生的真实 Change Set 做出真实裁决（至少一次 Reject 或修正）                                             |
| 5. 真实使用必须发生什么             | 人类能看懂 Change Set；Reject 不改 Spec；Accept 才改；重开项目状态一致                                           |
| 6. Engineering Acceptance | AC-01～AC-06（见工单原文）；写回后自动执行现有验证；DUnitX 全量通过                                                   |
| 7. Dogfood Acceptance     | 至少发生一次**真实的人类否决或修正**，且该否决导致 Change Set 与后续 Spec 状态发生改变，证据可追溯                                 |
| 8. 完成后进入                  | 0027D-D1 → 0028                                                                              |

> Decision 是唯一人类裁决事实。禁止 `VisualDecision` / `VisualApproval` / `VisualProposal` / `VisualReviewState` 等平行实体。

**状态**：✓ 已实现并入 `main`（`ece79a2`，交付报告 `417bb1b`）。

已落地实现面：

```text
CLI       RunChangeSetReview  / RunChangeSetAccept
Service   TAsWishCandidateIngest.ApplyChangeSet（Accept → 写回 Canonical Spec）
          TAsWishCandidateIngest.FormatChangeSetReviewSummary（语义化 Review 展示）
Decisions TAsWishDecisionsService.RecordChangeSetDecision（Decision 关联 ChangeSetId）
```

**⚠ Engineering Green 已过（149/149 + 证据存档），Dogfood Green 未过**：尚未用真实自用任务跑出一次真实的人类裁决（本票第 4、5、7 项）。

---

### 6.5 WO-20260830-0027D · D1 里程碑（证据链落盘）

**产品问句**：这次确认是怎么来的？  
**输出**：可审计的 Spec Revision Provenance

| 项                         | 内容                                                                            |
| ------------------------- | ----------------------------------------------------------------------------- |
| 1. 解决什么能力                 | 形成 `Human NL → CandidateIngest → Change Set → Decision → Committed Spec` 可追溯链 |
| 2. 明确不解决什么                | 实现后证据（Evidence v0）、Difference、视觉表现                                            |
| 3. 工程完成条件                 | 每次裁决可追溯：输入 / AI 解释 / 提议变更 / 人类裁决 / 最终 Spec                                    |
| 4. AsWish 自用任务            | 把 0027A→B→C 的真实链路记录完整落盘                                                       |
| 5. 真实使用必须发生什么             | 从最终 Spec 能倒查回人类原始自然语言                                                         |
| 6. Engineering Acceptance | AC-01～AC-02（见工单原文）；证据归档；主控独立复核                                                |
| 7. Dogfood Acceptance     | 对真实链路执行一次完整倒查，中途无断点                                                           |
| 8. 完成后进入                  | 0028                                                                          |

**状态**：✓ 已实现（**管道层**，`main`，`ba4b56f`）。Controller `SubmitUserIntent / Review / Accept / Reject / Clarify` 全链接入；`TSpecDecision` 记录 `ChangeSetId` 与 `ChangeItemIndex`；SPEC §8.1 落盘；149/149；证据包 `WO/evidence/*-20260830-0027D.txt`。
> 范围注记：0027D 实际交付的是**底层链路 + Controller / Command 接入**，GUI Review UX 仍为缺口（当前命令走 `InputQuery` 模态弹窗）。补口票为 §6.11 **0027D-R1**。Dogfood Green 未过。

---

### 6.6 WO-20260830-0028 · Accepted Visual Baseline

**产品问句**：我们确认的东西长什么样？  
**输出**：`可见 Baseline`

| 项                         | 内容                                                                                      |
| ------------------------- | --------------------------------------------------------------------------------------- |
| 1. 解决什么能力                 | 把 View Spec 渲染成可确认、可复现、可追溯的视觉规格基线                                                       |
| 2. 明确不解决什么                | 开发后截图比对 / Overlay / Pixel Diff / Drift / 自动改代码 / Agent 调度 / View Spec 布局 schema 扩展（另立票） |
| 3. 工程完成条件                 | 结构线框确定性渲染；复用现有 `SpecSnapshot` 承载 Baseline 视觉绑定；`renderer_version` 固定                    |
| 4. AsWish 自用任务            | 对真实任务对应的 View Spec 生成 Baseline，并由人类确认                                                   |
| 5. 真实使用必须发生什么             | 人类看着 Preview 说出"对，这就是我要的"或"不对"，该判断被记录                                                   |
| 6. Engineering Acceptance | AC-01～AC-15（见工单原文）；相同 View Spec + Renderer Version 重复渲染一致；旧 Baseline 不被静默覆盖             |
| 7. Dogfood Acceptance     | 存在一个真实任务产生的 Accepted Visual Baseline，可追溯到 Decision 与 SpecSnapshot                       |
| 8. 完成后进入                  | Implementation Evidence v0                                                              |

> 核心架构纪律（工单原文钉死）：**Accepted Visual Baseline = 现有 `SpecSnapshot` + 视觉绑定**，不得新建独立 Baseline 实体。

**状态**：未开工。

---

### 6.7 Implementation Evidence v0 · 实现证据

**产品问句**：Agent 实际做了什么？  
**输出**：`Implementation Evidence`

| 项                         | 内容                                            |
| ------------------------- | --------------------------------------------- |
| 1. 解决什么能力                 | 采集 Agent 实施后的真实结果，作为可比较对象                     |
| 2. 明确不解决什么                | 自动差异判定、自动质量评分、CI                              |
| 3. 工程完成条件                 | 实现后结果可被再次采集并落盘到 `evidence/`；与 Baseline 建立引用关系 |
| 4. AsWish 自用任务            | 让 Agent 实施 6.6 中确认的那个真实任务，并采集证据               |
| 5. 真实使用必须发生什么             | 产生一份真实的实现结果记录，可复现查看                           |
| 6. Engineering Acceptance | 证据文件结构可被协议描述；落盘位置明确；DUnitX 全量通过               |
| 7. Dogfood Acceptance     | 该证据来自真实 Agent 实施，不是人工构造的样例                    |
| 8. 完成后进入                  | Difference v0                                 |

**状态**：未开工，**当前无对应工单**（需立票）。

---

### 6.8 Difference v0 · 差异

**产品问句**：实际做出来的东西，和我们确认的东西哪里不同？  
**输出**：`Difference`

| 项                         | 内容                                                   |
| ------------------------- | ---------------------------------------------------- |
| 1. 解决什么能力                 | 让 Baseline 与实现结果之间的结构差异被看见                           |
| 2. 明确不解决什么                | 自动判定对错；Pixel Diff；自动修复                               |
| 3. 工程完成条件                 | v0 先做**结构差异**；诚实标注当前不含视觉比对                           |
| 4. AsWish 自用任务            | 对真实任务的 Baseline 与 Evidence 做一次差异计算                   |
| 5. 真实使用必须发生什么             | 人类能看见差异清单，即便结论是"没有重要差异"                              |
| 6. Engineering Acceptance | 差异结果可复现；结构差异项可定位到节点；DUnitX 全量通过                      |
| 7. Dogfood Acceptance     | 真实跑出一次差异结果，且允许结论为「无重要差异 / 可接受差异 / 不可接受差异 / 未决」中的任意一种 |
| 8. 完成后进入                  | Human Confirmation                                   |

> `Difference ≠ Error`。追求 Difference made visible, traceable, and judgeable，不追求 Zero Difference。  
> 实验必须允许得到"没有重要差异"或"存在可接受差异"的结果。

**状态**：未开工，**当前无对应工单，代码层为 0**（需立票）。

---

### 6.9 Human Confirmation · 人类裁决

**产品问句**：这个 Difference 我接受吗？  
**输出**：`Acceptable` / `Unacceptable` / `Unresolved`

| 项                         | 内容                                        |
| ------------------------- | ----------------------------------------- |
| 1. 解决什么能力                 | 把实现结果回到人类面前，由人类对 Difference 做出判断          |
| 2. 明确不解决什么                | 自动裁决；自动回滚                                 |
| 3. 工程完成条件                 | 复用现有 `Decisions` 承载裁决，记录到差异项              |
| 4. AsWish 自用任务            | 对 6.8 的真实差异做出真实判断                         |
| 5. 真实使用必须发生什么             | 至少一次人类判断被记录，且判断结果不是预设的"通过"                |
| 6. Engineering Acceptance | 裁决可持久化、可回读；与 Difference 项建立引用；DUnitX 全量通过 |
| 7. Dogfood Acceptance     | 存在一条真实的人类裁决记录，能说明为什么接受或不接受                |
| 8. 完成后进入                  | Revision                                  |

**状态**：未开工，**当前无对应工单**（需立票）。

---

### 6.10 Revision · 修订与再验证

**产品问句**：我要怎么改？  
**输出**：回到 `Human Intent`，形成真正循环

| 项                         | 内容                                                            |
| ------------------------- | ------------------------------------------------------------- |
| 1. 解决什么能力                 | 人类基于差异再次提出自然语言修订，重新走完整链                                       |
| 2. 明确不解决什么                | 自动修复；自动重试直到通过                                                 |
| 3. 工程完成条件                 | 第二轮能复用第一轮全部机制，不新建第二套流程                                        |
| 4. AsWish 自用任务            | 对 6.9 的判断提出真实修订，重跑到再次看见结果                                     |
| 5. 真实使用必须发生什么             | 完整跑通第二轮，并产生 `Baseline v2 / Implementation v2 / Difference v2` |
| 6. Engineering Acceptance | 第二轮产物可追溯、可与第一轮对比；DUnitX 全量通过                                  |
| 7. Dogfood Acceptance     | **至少真实完整跑通一次第二轮 Revision**，这是 First Closed Loop 的硬条件          |
| 8. 完成后进入                  | First Closed Loop 验收                                          |

**状态**：未开工，**当前无对应工单**（需立票）。

---

### 6.11 0027D-R1 · GUI Review Surface（建议票，待裁定）

**产品问句**：我在屏幕上，到底怎么看见并裁决"AI 对我的理解"？
**输出**：可被普通人操作的 ChangeSet 审阅与裁决界面

> 本票为补口小票（不重开大工单）：0027D 已交付底层链路 + Controller / Command 接入，本票只补 `Commands / Controller → GUI UX` 的最后一层。**已正式立票（2026-08-30，老板指示）：`WO/WO-20260830-0027D-R1-甲-GUIReviewSurface工单.md`，承接仓库 AsWish。**

| 项 | 内容 |
|---|---|
| 1. 解决什么能力 | 把已成立的 `I said → AI understood → We decided` 从工程内部能力变成人可实际操作的界面闭环；复用 WebView2 JS Bridge（勘察报告判定"完全可以小步接入"） |
| 2. 明确不解决什么 | Visual Baseline（0028）、Evidence、Difference；不做聊天窗口；不做新数据模型或新状态机；不做完整 GUI 重设计 |
| 3. 工程完成条件 | Review 页面四层信息模型：**① 原始意图（I said）→ ② AI 理解（AI understood）→ ③ Before / After + Affected Projections → ④ Human Decision**；裁决按钮映射 Accept / Reject / Clarify；交互遵循 [`AsWish-统一选择交互标准-v1.md`](AsWish-统一选择交互标准-v1.md)（0–9 协议 + 语义色 Token） |
| 4. AsWish 自用任务 | 在 GUI 里对一个真实自用意图完成一次完整审阅与裁决 |
| 5. 真实使用必须发生什么 | 普通用户不理解 YAML / Spec / ChangeSet / Decision 工程概念，也能完成"我说 → AI 理解 → 我判断 → 系统记录决定 → 状态更新" |
| 6. Engineering Acceptance | 复用 Controller 五方法，不新增业务逻辑；149/149 全量回归通过；build / GUI 运行日志存档 |
| 7. Dogfood Acceptance | **真人操作场景**：打开项目 → 选节点 → 自然语言表达 → 看到 AI 理解与 Before/After → 逐项判断（含至少一次 Reject 或 Clarify）→ 看到系统明确告知"现在我们决定了什么"；不接受仅 `InputQuery` 弹窗形态 |
| 8. 完成后进入 | 0028 |

> 术语呈现纪律：`explicit / inferred / unknown` 不得作为术语直接展示给用户（呈现为"你明确提出 / AI 推断 / 尚未确定"）。
> Review 页面的对象不是 ChangeSet 本身，而是**"AI 对我的意图形成的当前理解"**——ChangeSet 只是它的工程承载物。

---

## 七、Dogfood Protocol v0（第一个自用任务）

**不每阶段换一个 Demo。** 选择：

> **一个真实、足够小、确实需要修改的 AsWish 自身任务**

让它一路贯穿：

```text
0027A → 0027B → 0027C → 0027D → 0028 → Evidence → Difference → Human Judgment → Revision → Rebuild → Re-verify
```

### Protocol v0 最小要求

任务必须同时满足：

```text
小           改动面可控（单票 / 少文件）
真实         确实需要被修改，不是为了演示造的
可修改       落在 AsWish 自身工程范围内
可验证       改完能明确判断对不对
有一定歧义   足以产生 explicit / inferred / unknown 的分化
不复杂       不跨几十个文件
```

**一旦选定：同一个任务贯穿所有阶段，不每一票换 Demo。**  
**不使用复杂的大型功能作为第一案例。**

### 选择原则

```text
小          改动面可控
真实        确实需要被修改，不是为了演示造的
可修改      落在 AsWish 自身工程范围内
可验证      改完能明确判断对不对
有歧义      足以产生 explicit / inferred / unknown 的分化
不复杂      不跨几十个文件
```

### 优先类型

```text
CLI 小改动
GUI 小改动
文档入口小改动
Prompt 行为小改动
测试行为小改动
```

**不要一开始选择几十文件的大型功能。**

### 第一批候选（供裁定，非决定）

| 候选                                          | 改动面 | 歧义点                   | 备注                                  |
| ------------------------------------------- | --- | --------------------- | ----------------------------------- |
| A. CLI 增加 `intent list` / `intent show` 子命令 | 单文件 | 显示哪些字段、如何排序、未处理意图如何呈现 | 与 0027A 已实现能力直接衔接，歧义适中              |
| B. GUI 增加自然语言意图输入入口                         | 中等  | 入口位置、与现有命令表的关系        | 同时补 0027A 的 GUI 缺口，但改动面大于 A         |
| C. CLI help / 命令文案与排序小调整                    | 极小  | 语义分组口径                | 歧义偏少，可能跑不出有意义的 `inferred / unknown` |

> **倾向 A**：足够小、真实、可验证，且具备真实歧义，能在 0027B 阶段产生有意义的解释分化。  
> **最终选择由主控 / 老板裁定**，一旦选定，**不再更换**。

---

## 八、First Closed Loop v0 · 正式验收

**定义**：First Closed Loop v0 是一个**可实现、可观察、可验收的最小产品闭环**——不是理论解释，而是可以逐阶段打勾的验收对象。

必须真实完整跑通以下主链（同一任务、同一项目）：

```text
Human Intent
    ↓
Problem Manifestation
    ↓
AI Interpretation / Candidate
    ↓
Human Confirmation
    ↓
Confirmed Understanding
    ↓
Visual Baseline
    ↓
Agent Development
    ↓
Implementation Evidence
    ↓
Implementation Result
    ↓
Difference
    ↓
Human Judgment
    ↓
Revision
    ↓
Rebuild
    ↓
Re-verification
```

硬性条件：

1. 全程使用**同一个真实任务**；
2. 每一环节都产生**真实工程证据**，不是构造样例；
3. 人类判断是**真实的**，允许出现否决与修正；
4. **至少真实完整跑通一次第二轮 Revision / Rebuild / Re-verification**。

### 不完成条件（出现任何一条，即不得宣布成功）

```text
Human 没有明确确认
没有稳定 Baseline
Agent 修改无法追踪
没有 Implementation Evidence
无法看到 Implementation Result
没有 Difference
Difference 没有 Human Judgment
Human 无法发起 Revision
Revision 没有重新进入流程
没有第二轮验证
```

以下情况**单独或合计均不构成验收**：

```text
Build 成功
Tests 全绿
Agent 说 Done
Human 看一眼
```

> 阶段逐项标准（输入 / AI 职责 / Human 职责 / 必须可见什么 / 产物 / 完成条件）见 §十一阶段标准表。

---

## 九、已实现 / 进行中 / 下一步 / Non-goals

### 已实现（当前 `main` HEAD `8957660`，DUnitX 149/149）

| 能力                              | 落点                                                                                     |
| ------------------------------- | -------------------------------------------------------------------------------------- |
| 自然语言意图承载（0027A）               | CLI `intent` → `.AsWish/llm/candidate-intent.yaml`                                     |
| 结构化 Change Set 解释（0027B）      | CLI `changeset` → `.AsWish/llm/change-set.yaml`                                        |
| Change Set 审阅与 Decisions 写回（0027C） | `RunChangeSetReview` / `ApplyChangeSet` / `RecordChangeSetDecision`（`ece79a2`）        |
| 证据链与协议落盘（0027D）                | Controller 五方法全链接入、SPEC §8.1、`aswish.changeset.*` 命令、证据包（`ba4b56f`）             |
| 四投影树与 Spec 存储                   | `SpecStore` / `TreeBuilder`                                                            |
| 渲染与快照                           | `Render` / `Snapshot`（均有对应测试单元）                                                          |
| 决策机制（通用）                        | `Decisions` 服务                                                                          |
| 追问机制                            | `grilling_ticket` + `WriteGrillingPrompt`                                              |
| 统一选择交互标准                        | [`AsWish-统一选择交互标准-v1.md`](AsWish-统一选择交互标准-v1.md)（0–9 协议，已冻结，尚待 GUI 实现）              |

> 0027A～D 均只过 Engineering Green；**Dogfood Green 全部未过**——链路尚未被一次真实自用任务贯穿跑通。

### 下一步（First Closed Loop 范围内）

```text
0027D-R1（GUI Review Surface，建议票待裁定）→ 0028 → Evidence v0 → Difference v0 → Human Confirmation → Revision
```

其中 0027D-R1 为 A 线建议的补口小票（见 §6.11）；Evidence v0 / Difference v0 / Human Confirmation / Revision **当前无工单，需立票**。

工程状态纪律：本表只记"票的能力语义与验收标准"；commit 号与测试数仅为登记时快照，**当前真实进展一律以 `git log` 与 `WO/evidence/` 为准**。

### Non-goals（当前阶段明确不做）

```text
SaaS / Team / Enterprise 协作
账号体系
商业模式设计
Agent Orchestrator（Agent 调度编排）
复杂 Case 平台 / 完整未来 Case System
大型 Benchmark
自动 Difference 归因
视觉像素级 Difference（Pixel Diff）
自动理论推导
多语言 AST（当前解析仅 Delphi）
大量 AI 模型能力扩展
CI / 自动验证
Python / 跨平台扩展
View Spec 布局 schema 扩展（0028 §十一明确另立票）
社区与生态建设
```

> 当前只解决：**First Closed Loop v0**。

---

## 十、禁止新增的平行实体

在 First Closed Loop 全过程中严格遵守：

**禁止新增**

```text
VisualState
Proposal
ParallelCandidate
ChangeObject
NewDecisionSystem
NewImpactGraph
VisualDecision
VisualApproval
VisualProposal
VisualReviewState
独立 Baseline 实体
第二套状态机
第五棵树
```

**优先复用**

```text
CandidateIngest
Decisions
SpecSnapshot
Render
TreeBuilder
SpecStore
Prompts
semantic-bundles（现有 Semantic Bundles）
gen_status / review_status（现有状态字段）
```

> 何时才允许新增：只有现有协议**确实无法表达**且经主控裁定后，才允许新增最小结构（依据 `WO/WO-20260830-0027D-甲-证据链与协议落盘工单.md` §三）。

---

## 十一、First Closed Loop v0 阶段标准表

> 重点不是技术实现，而是**用户实际经历什么**。各阶段产物落盘位置与协议以 [`../SPEC.md`](../SPEC.md) 与各工单原文为准，本表不复述协议细节。

| Stage                           | 输入                             | AI 职责                                 | Human 职责                                                 | 必须可见什么                            | 产物                                            | 完成条件                                                     | 不完成条件                 |
| ------------------------------- | ------------------------------ | ------------------------------------- | -------------------------------------------------------- | --------------------------------- | --------------------------------------------- | -------------------------------------------------------- | --------------------- |
| 1 Human Intent                  | 人的自然语言表达                       | 接收、澄清（必要时 grilling）                   | 用自然语言说清想改什么                                              | 已提交的意图原文                          | `candidate-intent.yaml`                       | 意图被承载并持久化                                                | 意图被自动解释为 Spec 修改      |
| 2 Problem Manifestation         | 意图 + 项目上下文                     | 显影问题：指出模糊、断口、未知                       | 辨认"这确实是我要解决的问题"                                          | 模糊点与断口可见                          | fog / grilling 状态标注                           | 关键断口被指出                                                  | 问题被 AI 擅自"解决"掉        |
| 3 AI Interpretation / Candidate | 意图原文 + 节点上下文                   | 解释："我理解你可能是这个意思"                      | 判断解释对不对                                                  | 结构化 Change Set（语义化展示，非 YAML diff） | `change-set.yaml`                             | 可定位节点；Before / After 可见；explicit / inferred / unknown 区分 | 把 AI 理解直接当成 Decision  |
| 4 Human Confirmation            | Change Set                     | 呈现影响、回答追问                             | 明确 Accept / Reject / Unresolved                          | 裁决界面与裁决结果                         | Decision 记录                                   | 裁决被记录且可追溯                                                | 无人类裁决；Reject 仍写回      |
| 5 Confirmed Understanding       | Accepted Decision              | 固化确认结果，写回 Canonical Spec（复用 merge 语义） | 复核写回后的 Spec 状态                                           | 写回后的 Spec 与 Decision 的关联          | Committed Spec + provenance                   | 写回可追溯；重开项目状态一致                                           | 未确认内容混入 Spec          |
| 6 Visual Baseline               | 确认后的 View Spec                 | 确定性渲染结构线框                             | 看着它说"对，这就是我要的"                                           | 可重复查看的视觉基线                        | Accepted Visual Baseline（SpecSnapshot + 视觉绑定） | 相同输入渲染一致；与 Decision / Snapshot 可追溯                       | Baseline 不可复现 / 被静默覆盖 |
| 7 Agent Development             | Baseline + Spec + Decisions 导出 | 组装 context-pack 交付；外部 Agent 实施        | 选择并启动 Agent                                              | 交付内容与实施边界可见                       | Agent 交接记录                                    | Agent 按已确认内容实施                                           | Agent 收到未确认或矛盾信息      |
| 8 Implementation Evidence       | Agent 实际产出                     | **采集事实记录**（不是 AI 自我评价）                | 提供、确认实施事实                                                | "Agent 实际做了什么"的原始记录               | `evidence/` 落盘                                | 事实可复现查看                                                  | 只有 AI 声称，无可查记录        |
| 9 Implementation Result         | Evidence                       | 呈现实际结果                                | 查看实际结果                                                   | 实际结果的可视呈现（VC-03）                  | Implementation Result                         | 人能看到结果                                                   | 结果不可见、不可复现            |
| 10 Difference                   | Baseline vs Result             | 计算并呈现结构差异（**不判对错**）                   | 看见差异清单                                                   | 差异被看见（VC-04）                      | Difference v0 记录                              | 差异可复现、可定位到节点                                             | 差异被自动定义为 Error / 被隐藏  |
| 11 Human Judgment               | Difference                     | 呈现证据，不代替判断                            | 给出：No important / Acceptable / Unacceptable / Unresolved | 判断选项与后果可见                         | 人类判断记录                                        | 判断被记录并关联差异项                                              | AI 代替人做最终判断           |
| 12 Revision                     | 人类判断                           | 接收修订意图（= 回到 Stage 1）                  | 用自然语言提出要怎么改                                              | 修订意图被承载                           | 新 `candidate-intent`                          | 重新进入既有流程                                                 | 建立第二套修改机制             |
| 13 Rebuild                      | Revision 意图链                   | 重跑 Stage 3 → 9                        | 再确认、再实施                                                  | 第二轮产物（v2）                         | Baseline v2 / Implementation v2               | 第二轮真实发生                                                  | 复用第一轮结果冒充             |
| 14 Re-verification              | v2 Evidence                    | 重新计算 Difference v2                    | 再次判断                                                     | v2 差异可见                           | Difference v2 + 判断                            | 判断形成闭环结论                                                 | 无第二轮验证                |

---

## 十二、Human / AI Boundary（共同门禁）

### Human owns

```text
Intention              意图
Judgment               判断
Decision               决策
Accept / Reject        接受 / 拒绝
Difference Judgment    差异判断
Final Confirmation     最终确认
Revision Decision      修订决定
```

### AI may

```text
Discover               发现
Ask                    提问
Explain                解释
Suggest                建议
Transform              转换
Generate               生成
Render                 渲染
Implement              实施
Inspect                检查
Surface Difference     让差异可见
```

### AI must not

```text
把推测当确认
把 Candidate 当 Decision
把 Difference 当 Error
未经确认修改 Canonical Spec
未经确认结束闭环
代替 Human 完成最终判断
```

> **本边界是所有后续工程票的共同门禁**：每张工单的 AC 必须包含"不违反边界"的检查项；违反即 RETURNED，不得 CLOSE。

---

## 十三、标准 ≠ 实现

### Product / Behavioral Standard（产品行为标准，长期不变）

规定：

```text
Human must see          人必须能看见
Human must judge        人必须能判断
Human must confirm      人必须能确认
Difference must be visible   差异必须可见
Revision must be explicit    修订必须显式
```

### Current Engineering Implementation（当前工程载体，可演进）

当前采用：

```text
CandidateIngest
Decisions
Snapshot
Render / SVG
YAML
CLI / GUI
外部 Agent
```

> **不让当前实现反过来定义产品概念。** 例如：SVG 是当前实现载体的选择，不是"所见即所得"的定义；`.AsWish/llm/` 是当前落盘位置，不是协议概念；CLI `intent` 是当前入口，不是"自然语言表达"的定义本身。

---

## 十四、工程票 → First Closed Loop v0 映射表

| 工程票 / 阶段                    | 解决什么问题              | First Closed Loop v0 中的位置                         | Engineering Acceptance | Dogfood Acceptance |
| --------------------------- | ------------------- | ------------------------------------------------- | ---------------------- | ------------------ |
| **0027A**                   | 我想改什么？              | Stage 1–2（Intent / Manifestation）                 | §6.1                   | §6.1               |
| **0027B**                   | 你的意思是不是这样？          | Stage 3（Interpretation / Candidate）               | §6.2                   | §6.2               |
| **0027D-D0**                | 用什么结构承载 AI 的解释      | Stage 3 协议前置                                      | §6.3                   | §6.3               |
| **0027C**                   | 我们确认的到底是什么？         | Stage 4–5（Confirmation / Confirmed Understanding） | §6.4                   | §6.4               |
| **0027D-D1**                | 这次确认是怎么来的           | Stage 5（provenance）                               | §6.5                   | §6.5               |
| **0028**                    | 我们确认的东西长什么样？        | Stage 6（Visual Baseline）                          | §6.6                   | §6.6               |
| **Evidence v0**（待立票）        | Agent 实际做了什么？       | Stage 7–9（Agent Dev / Evidence / Result）          | §6.7                   | §6.7               |
| **Difference v0**（待立票）      | 实际结果与确认内容哪里不同？      | Stage 10（Difference）                              | §6.8                   | §6.8               |
| **Human Confirmation**（待立票） | 这个 Difference 是否接受？ | Stage 11（Human Judgment）                          | §6.9                   | §6.9               |
| **Revision**（待立票）           | 我要求怎么改？             | Stage 12–14（Revision / Rebuild / Re-verification） | §6.10                  | §6.10              |

> 本表只是索引；每票验收的**唯一详源是 §六**，冲突时以 §六为准。

---

## 十五、文档 12 问自检

资料更新后，项目文档必须能直接回答：

| #  | 问题                              | 答案位置                                         |
| -- | ------------------------------- | -------------------------------------------- |
| 1  | 什么叫 First Closed Loop？          | 本文 §一、§八；[蓝图 §二十一](AsWish-产品功能与愿景蓝图-v1.md)   |
| 2  | 最小闭环需要哪些阶段？                     | 本文 §八（v0 主链）、§十一（阶段标准表）                      |
| 3  | 每阶段 Human 做什么？                  | 本文 §十一                                       |
| 4  | 每阶段 AI 做什么？                     | 本文 §十一                                       |
| 5  | 哪些决定 Human 必须拥有？                | 本文 §十二（Human owns）                           |
| 6  | 哪些事情 AI 禁止做？                    | 本文 §十二（AI must not）                          |
| 7  | 什么东西必须被看见？                      | 蓝图 §二十二、§二十三                                 |
| 8  | SVG 在哪里出现？                      | 蓝图 §二十三、§二十四（VC-01～05）                       |
| 9  | 什么叫 Visual Baseline？            | 蓝图 §八.3 / §二十三第二阶段；0028 工单                   |
| 10 | 什么叫 Implementation Evidence？    | 蓝图 §十；本文 §6.7；0028 §六（Screenshot = Evidence） |
| 11 | 什么叫 Difference v0？              | 本文 §6.8；蓝图 §二十四（VC-04）                       |
| 12 | 什么条件下可以宣布 First Closed Loop 成功？ | 本文 §八（硬性条件 + 不完成条件）                          |

---

## 十六、待裁定冲突登记

以下冲突**只做记录，不做自行裁决**（依据 [`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md) §4 冲突裁定顺序）：

### C-1 · D0 前置被跳过（已由 SPEC §8.1 追认解决）

- **事实链**：0027B/C 的实现先于 D0 协议冻结落地；随后 `SPEC.md` §8.1 以**追认方式**冻结了 Intent → Change Set → Decision Traceability 链与落盘路径，0027D（`ba4b56f`）完成协议写入并交付 149/149 证据。
- **裁定结论**：D0 以"追认现有实现"方式生效，**终态一致**，冲突解除。
- **残留注记**：0027D 交付报告 AC-08 声称"D0 在 B/C 开工前严格固化"，与实际时序不符。工程时序事实以 §6.3 状态注记为准；交付报告原文不改动（历史存档纪律）。
- **状态**：✅ 已解决（追认）。

### C-2 · 工单表头工作仓库仍为 DeepSpec

- **事实**：`WO-20260830-0027A/B/C/D`、`WO-20260830-0028` 表头均写"工作仓库：`D:\_Progs\02Business\DeepSpec`"，而 0027A/B/C/D 的实现**全部实际落在 AsWish 仓库 `main`**（交付报告亦载明"承接仓库：AsWish"）。
- **风险**：后续开发 AI 按工单字面在 DeepSpec 仓库开工，造成双仓分叉。
- **风险升级**：0028 与未来新票仍暴露在字面误导下。
- **建议裁定**：将未执行工单（0028 及后续）的承接仓库正式改判为 AsWish 仓库，或在新票上直接写 AsWish。
- **状态**：◐ 部分解决（2026-08-30 起，新工单（0027D-R1）已按老板指示直接写 AsWish 仓库；存量工单表头字面残留保留不改）。

### C-3 · `WO/` 在治理中被归类为只读历史归档，但仍在承载活跃工单

- **事实**：[`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md) §1 与 §2-Class H 将 `WO/` 列为"历史归档类 / 只读保留、禁止篡改"；但 0027C/0027D 的交付报告、复审请求与 `evidence/` 证据包正持续写入 `WO/`，属于**活跃使用**。
- **风险**：治理与实际用法不一致——按字面应只读的目录正被当作活跃工程区使用，新人按治理理解会得出错误结论。
- **建议裁定**：将活跃工单重新归类为当前有效工程文档（如 Class B），或建立活跃工单的新归档位置，历史工单继续只读。
- **当前处理**：本文承载每票双闸门验收；`WO/` 既有文件本会话未做任何修改（新增的交付报告 / 证据为工程侧产物）。
- **状态**：待裁定（紧迫性上升：活跃使用持续发生）。

### C-4 · `.AsWish/llm/` 落盘位置与 schema（部分解决）

- **事实**：`candidate-intent.yaml` 与 `change-set.yaml` 落盘于 `.AsWish/llm/`，`SPEC.md` §8.1 已正式定义该链路与落盘路径，**协议层面已闭环**；但 `protocol/schemas/` 仍无对应 JSON Schema，SPEC §2 布局小节是否同步登记该目录待确认。
- **风险**：协议与实现不一致，公开实验中读者无法按协议找到产物。
- **建议裁定**：为 `candidate-intent.yaml` 与 `change-set.yaml` 补 JSON Schema（可并入下一张协议小票）。
- **状态**：◐ 部分解决（SPEC §8.1 已定义，schema 仍缺）。
