# WO-20260830-0027A · 甲（开发AI）· CandidateIngest 自然语言 Spec 修订入口

- 下发时间：2026-08-30 11:05 (GMT+8)
- 下发人：主控AI
- 承接方：**甲（开发AI，DeepSpec 仓库）**
- 工作仓库：`D:\_Progs\02Business\DeepSpec`
- 优先级：P0
- 依赖：无（追问机制复用 `WO-20260830-001`）
- 门禁：非睿智轻量门禁；单 commit ≤200 行；build/test 原始输出存档证据；主控 APPROVED/RETURNED，未过不得 CLOSE。

---

## 一、目标

让用户在任意 Spec 节点上，用自然语言表达纠错 / 补充 / 修改 / 质疑，统一进入现有 `CandidateIngest`。

## 二、核心原则

- **不得新增 Proposal 一级实体**。定义：`CandidateIngest = 人类自然语言候选输入`。
- 本票只负责「承载」，不负责「理解」，**不修改 Canonical Spec**。

## 三、A↔B 切分点（主控钉死）

现有 `CandidateIngest.Ingest` 吃的是候选 YAML 节点，不是自然语言。本票边界：

1. 自然语言原文作为 **`user_intent` 原文字段**附着到 candidate，同时携带目标上下文（`node_id` / `projection`）。
2. 本票只持久化原文 + 目标上下文，**不解析、不生成节点**。
3. LLM 把 `user_intent` 解释成 Change Set 属 **0027B** 职责，本票不越界。

## 四、与 WO-20260830-001 的关系

复用现有 `grilling_ticket` 追问机制，不重新设计追问体系。

```text
CandidateIngest 信息不足 → grilling_ticket → 人类澄清 → CandidateIngest 更新
```

## 五、验收

- AC-01：用户可在 Spec 节点上下文提交自然语言修订。
- AC-02：自然语言原文以 `user_intent` 字段持久化进现有 CandidateIngest，不产生节点。
- AC-03：信息不足时复用现有 `grilling_ticket` 追问。
- AC-04：不直接修改 Canonical Spec。
- AC-05：不新增 proposal 生命周期 / 状态枚举。
- AC-06：既有 CandidateIngest 流程回归通过。
- AC-07：build + 全量测试输出存档为证据，主控独立复核。

## 六、非目标

不做：Change Set 生成 / Review UI / Accept·Reject / Spec 写回 / Baseline / Python / 新状态机。

## 交付物

代码 + `WO\evidence\` 证据 + `WO\AUDIT-REQUEST-WO-20260830-0027A.md` 复审请求。
