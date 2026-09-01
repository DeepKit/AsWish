# AsWish 双界面交互规范（Dual-Surface）

**English Title:** AsWish Dual-Surface Interaction Standard
**中文名称：** AsWish 双界面交互规范
**版本：** v1.0
**状态：** Normative / Frozen（2026-08-31 落库，含老板裁定：Conversation Surface 为新增层、多角色 AI 推迟、0–9 抽离为子规范）
**适用范围：** AsWish Desktop / WebView / GUI / 后续兼容客户端
**关联：** [`AsWish-统一选择交互标准-v1.md`](AsWish-统一选择交互标准-v1.md)（0–9 子规范）、[`AsWish-可见判断规范-OJP-v1.md`](AsWish-可见判断规范-OJP-v1.md)
**核心原则：** Human Exploration / Human Decision Separation

---

# 1. Purpose

本规范定义 AsWish 的基础人机交互结构。AsWish 将人机交互明确划分为两个平行的交互界面：

```text
Conversation Surface  自然对话界面（探索）
Decision Surface      交互决策界面（判断）
```

> **Conversation Surface 用于开放式探索、讨论、推演与共同理解。**

> **Decision Surface 用于在 Human 主动要求的情况下，将当前理解收敛为明确的人类判断。**

两个界面不得被混合为单一交互模式。

---

# 2. Core Principle

## 2.1 Dual-Surface Principle

```text
              AsWish
                 │
        ┌────────┴────────┐
        ▼                 ▼
Conversation Surface   Decision Surface
     自然对话             交互决策
        └────── Human ──────┘
```

二者平行、可相互切换、不同职责、不同交互密度、不同约束程度。**不得将 Decision Surface 设计成 Conversation Surface 的常驻替代物。**

---

# 3. Conversation Surface

## 3.1 Purpose
用于：Human 表达意图、发散思考、修改想法、提出尚未成熟的想法、讨论问题、与不同角色 AI 交流、AI 之间讨论质疑解释补充、形成共同理解、暂时保持不确定性。默认状态：**Open-ended / Non-committal**。

## 3.2 Human Freedom
不强迫 Human 在固定选项中选择、尽快形成决定、接受 AI 框架、对每句话结构化确认、把探索性表达立即转化为 Canonical State。Human 可以说"我还没想清楚""这个方向可能不对""刚才的说法作废"——这些默认属于 **Exploration Context**，不是 Canonical Decision。

## 3.3 AI Roles
Conversation Surface 可以存在多个 AI 角色（Product / Engineering / UX / Risk / Research AI 等），各角色可提出观点、互相质疑、提供证据、发现遗漏、解释差异、提供候选、帮助显影。但 **AI 角色不能因为参与 Conversation 就获得 Canonical Decision 权限**。

> **【落库裁定 2026-08-31】**：Conversation Surface 是**新增、尚未实现**的界面层（当前 AsWish 只有 CLI + 表单式 Review，无对话界面）。First Closed Loop 阶段：**多角色 AI 对话推迟**；Conversation Surface 先做"单人 + 单 AI 的开放对话"最小版（可先复用现有 grilling / 澄清机制）。

---

# 4. Decision Surface

## 4.1 Purpose
目的不是继续开放讨论，而是**帮助 Human 对当前已经形成的理解进行明确判断**。它是 **Constrained Human Judgment Space**，可用结构化选项，但结构化选项不得被视为 Human 思考的完整空间。

## 4.2 Activation
Decision Surface 必须由 Human 主动进入：`Conversation → Human 判断"现在需要做决定" → 进入 Decision Surface`。UI 必须提供明确入口（如"进入决定 / Decide"）。**AI 不得因为自己认为"应该做决定了"而强制切换。**

---

# 5. Separation Rule

```text
Conversation ≠ Decision
Decision ≠ Canonical Spec
```

完整表示：`Conversation → Context/Interpretation → Decision Surface → Human Decision → Canonical State`。

> **Conversation 本身默认不改变 Canonical Spec。只有正式 Human Decision 才可以成为 Canonical State 变更的授权边界。**

---

# 6. Decision Interaction Standard

Decision Surface 使用统一的数字交互协议。**0–9 的完整语义以子规范 [`AsWish-统一选择交互标准-v1.md`](AsWish-统一选择交互标准-v1.md) 为唯一来源，本规范不重复定义**（治理 §3.1 禁止信息复制）。速记：

```text
1–7   当前候选选项
8     重新生成候选
9     自己输入文字
0     返回
```

该协议适用于鼠标、键盘、数字键及后续兼容输入方式。

---

# 7. 1–7 Candidate Options
最多 7 项，不要求满 7 项，禁止为凑 7 项生成低价值/虚构选项。`1` 可作为 AI 当前最推荐候选，但**不拥有更高决策权**，不得通过视觉/位置/动画制造"1 就是正确答案"的暗示。**`1–7` 不构成封闭选择空间**——任何时候 Human 都可用 `9` 超出候选。

---

# 8. 8 — Regenerate
`8` 固定语义：根据当前 Decision Context 重新生成一组候选。`8` 本身不得修改 Canonical Spec、不得产生 Accept/Reject/Clarify Decision，只是候选重构操作。

## 8.2 Context Anchor
重新生成时，**原始 Human Intent 与当前 Decision Context 必须保持为主要约束**，禁止候选漂移以致无法判断新候选是否仍属原始 Intent。

---

# 9. 9 — Human Natural Language Input
`9` 固定语义："我自己说"，是 **Human Open Expression**，不是"其他"。它允许 Human 否定整个候选框架、修改部分内容、组合多候选、加新条件、引入全新方向、重新定义问题。**`9` 输入的文字不能直接成为 Canonical Spec**，仍须 `Human Input → AI Interpretation → Human Review → Decision`。

---

# 10. 0 — Back
`0` 固定语义：返回上一交互层（Decision → Conversation）。它是 **Navigation Action**，不是 Reject、不是 Cancel、不是 Delete、不是 Undo。按下 `0` 不得创建 Decision、修改 Canonical Spec、自动 Reject/Clarify、生成新 Candidate。

---

# 11. Decision Semantics

Decision Surface 的交互选择与领域 Decision 必须语义分离。当前正式 Decision Semantics：**Accept / Reject / Clarify**。

## 11.1 Accept
Human 同意当前理解/变更，并授权其成为 Canonical State 的一部分：`Accept → Decision → Apply → Canonical Spec`。

## 11.2 Reject
Human 明确不同意当前 ChangeSet：`Reject → Decision → Canonical Spec 不变`。**Reject 不得与 `0 Back` 混淆。**

## 11.3 Clarify
Human 认为当前理解/变更尚不足以作最终决定，需进一步澄清：`Clarify → Decision → Canonical Spec 不变 → 继续自然语言交流/下一轮理解`。Clarify 不等于 Reject。

> **【落库裁定 2026-08-31 · Clarify 双重性钉死】**：Clarify 是一个**合法 Decision（落盘，如 `dsProposed`/`dtClarify`）**，其**下一步动作**是触发回到 Conversation Surface 继续显影。它"既是 Decision、又触发回对话"，实现上两件事都必须成立：落盘一条 Decision + 返回到对话，缺一不可。

---

# 12. Understanding and Decision

> **Understanding ≠ Decision**

AI 正确理解 Human Intent ≠ Human 一定同意采用该方案（`Understanding=Correct, Decision=Reject` 完全合法）。"AI 理解得对吗？"与"采用这个变更吗？"是两个不同的问题。

---

# 13. Conversation-to-Decision Transition

`Conversation → Human 主动进入 Decision → Decision Context → AI 提供候选 → Human 1–7/8/9/0 → Human Decision → Accept/Reject/Clarify`。任何环节 Human 都不应因 AI 提供候选而被视为已同意。

---

# 14. Decision-to-Conversation Transition

- Accept → Canonical State → 返回 Conversation
- Reject → Canonical State 不变 → 返回 Conversation
- Clarify → Canonical State 不变 → 返回 Conversation / 进入下一轮澄清

---

# 15. Conversation UI 不得被 Decision UI 污染

Conversation Surface 不应常驻显示 `1.–0.`，也不应频繁强迫结构化选择（`1–7` 是 Decision Interaction Protocol，不是 General Conversation Protocol；自然对话中偶然的普通数字列表不受限）。

---

# 16. Decision UI 不得假装成开放对话

Decision Surface 可允许 `9` 输入文字，但 `9` 的输入仍属于当前 Decision Context，不得绕过 Human Decision Boundary。

---

# 17. Mouse + Keyboard Equivalence
同一 Decision Action 必须同时支持 Mouse 与 Keyboard（鼠标点 [1] = 键盘按 1，余同）。两种方式不得有不同业务语义。

---

# 18. Semantic Color Standard
采用语义颜色 Token，不固定具体 RGB。Token：`Choice.Option(1–7) / Choice.Regenerate(8) / Choice.Input(9) / Choice.Back(0)`。必须同时支持 Light / Dark Theme，颜色值可不同，**语义 Token 不得改变**。不得仅用颜色表达语义——每个交互项至少"数字 + 文字"。

---

# 19. Visual Priority Rules
颜色只表达**交互类别**，不得表达 AI 判断的真伪或价值等级。`1` 可作默认焦点但不得像"绝对正确"，`8` 不得像错误，`9` 不得像低级备用入口，`0` 不得被误认为 Reject。

---

# 20. Human Judgment Protection

> **Simplicity of operation must never become simplification of human judgment.**
> **操作可以极简，判断不能被简化。**

AI 的作用是帮助显影、整理、比较、解释，不是替 Human 定义唯一合理答案。

---

# 21. Open Candidate Principle
`1–7` 是判断材料，不是封闭决策空间。任何 Decision Surface 必须保留 `9`。`AI Candidate Space ≠ Human Intent Space`。

---

# 22. AI Uncertainty
AI 不得为满足 `1–7` 格式强行制造候选。无法可靠给候选时可直说"当前无法可靠形成候选，请直接描述你的意思"，只提供 `9 / 0`。**"无法可靠给出候选"是合法状态。**

---

# 23. Frame Rejection
Human 可以拒绝的不只是某个选项，还可以拒绝**整个 AI 定义的问题框架**（如 `9` 输入"你给的选项都不是我真正要解决的问题"）。系统应理解为 **Human rejects the frame**，而非 "selected Other"。

---

# 24. Canonical Boundary
严格保持 `Conversation → AI Interpretation → Human Decision → Canonical Spec`。禁止 `Conversation → AI → Automatic Canonical Mutation`，也禁止 `Decision Candidate → Automatic Canonical Mutation`。只有正式 Human Decision 才可触发 Canonical State 变更。

---

# 25. What This Standard Does Not Define
本规范暂不规定：AI 模型选择、ChangeSet 生成、Semantic Bundle 计算、Canonical Spec 数据模型、Difference 算法、Visual Baseline、Implementation Evidence、Agent Orchestration、理论模型最终定义、具体 HTML/CSS/VCL 实现、具体 RGB 色值。

---

# 26. Minimal Reference Model

```text
                HUMAN
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
 Conversation Surface   Decision Surface
   自然对话/多角色/探索      1–7/8/9/0 → Accept/Reject/Clarify
        └────────┬─────────┘
                 ▼
          Human Decision
        ┌────┬────┬────┐
      Accept Reject Clarify
        │     │      │
        ▼     ▼      ▼
   Canonical  不变   下一轮
     State
```

---

# 27. Normative Summary

- Conversation Surface：**负责探索，不负责承诺。**
- Decision Surface：**负责判断，不负责替人思考。**
- Human：**可以自由探索，并主动决定何时进入决策。**
- AI：**可以帮助显影、整理和提供候选，但不能取得最终决策权。**
- 0–9：`1–7 候选判断 / 8 重新生成 / 9 自己输入 / 0 返回`（详见于子规范）。
- Decision：`Accept / Reject / Clarify`。
- Canonical Spec：**只能通过正式 Human Decision 改变。**

---

# 28. Frozen Principle

> **Let Human think openly. Let AI help clarify. Let Human decide explicitly.**

中文：**让人自由思考，让 AI 帮助显影，让人明确决定。**
