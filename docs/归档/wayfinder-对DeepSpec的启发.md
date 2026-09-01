# 《雾中寻路：AI 怎么对付写不出 PRD 的大任务》对 DeepSpec 的启发

> 原文：葡萄边（前端开发），知乎专栏《Grapes的AI Agent学习笔记》，2026-07-07。
> 全文存档：[`wayfinder-fog-of-war.md`](./wayfinder-fog-of-war.md)
> 原始链接：https://zhuanlan.zhihu.com/p/2057862407343625873

这篇文章讲的是 Matt Pocock 的 **wayfinder** 技能——把"终点看不清的大任务"拆成 issue tracker 上一张会生长的探索地图，每张地图挂着若干探索型 ticket，一次只解一个，直到通往终点的路清晰。其核心概念是 **Fog of war（战争迷雾）** 与 **Frontier（前沿）**：只在前沿做决定，不在迷雾里做计划。

这与 DeepSpec 的设计是**同一思想谱系**——DeepSpec 已内置 `TFogState`（`fsClear/fsMisty/fsFoggy/fsUnknownUnknowns` 四态收敛）和 `TTicketType`（`itResearchTicket/itPrototypeTicket/itGrillingTicket/itFogUnknown`）。文章相当于给 DeepSpec 的模型做了一次外部校准，也照出了当前最关键的缺口。

---

## 一、思想对齐：DeepSpec 站在正确的谱系上

文章把 mattpocock 技能体系分两层：**找路层**（wayfinder：终点不清时拆 ticket 探索）与**走路层**（to-spec 把对话沉淀成 spec，to-tickets 把 spec 拆成可执行 ticket）。

DeepSpec 的产品定位恰好横跨这两层：
- **找路层**：`TFogState` 标记节点处于迷雾中（`fsUnknownUnknowns`→`fsFoggy`→`fsMisty`→`fsClear` 单向收敛），四类 ticket 是探索迷雾的工具。
- **走路层**：spec tree（function/module/view/data 四棵树 + problems/bundles 页）就是沉淀下来的 spec，决策（Decisions）是把候选 spec 确认/驳回的执行环节。

**结论**：DeepSpec 的骨架是对的。不要因为这篇文章去推翻模型，而是去**补全它承诺但还没接线的部分**。

---

## 二、文章照出的三个核心缺口（与 bugfix.md 高度重合）

### 缺口 1：探索型 ticket 有枚举、无入口（对应 BUG-11，P1）

文章描述的 wayfinder 主交互就是"画地图→拆 ticket→一次解一个"。DeepSpec 的 `TTicketType` 四值已定义，但：
- 没有 Controller 路径创建一张 wayfinder 地图 issue；
- 没有 UI 让用户从某个 `fsUnknownUnknowns` 节点出发，创建一张 `research_ticket` / `prototype_ticket` / `grilling_ticket`；
- problems 页的 `#fog-map` 区域只展示雾区节点，没有"为这个雾区开一张探索地图"的动作。

**文章给的最关键设计原则**：地图不是任务清单，而是**索引**；ticket 不是待办项，而是**待解的问题**。DeepSpec 落地时不要把它做成又一个 todo list——ticket 的标题必须是一个**可一句话精确问出的问题**，问不出的就留在"Not yet specified"区（即 `fsUnknownUnknowns`），不硬拆。

### 缺口 2：LLM 闭环断裂（对应 BUG-8，P1）

文章强调"一次只解一个 ticket"是在**保护 AI 的 context**——一个 ticket 解完，决策和结果写进地图，下一个 ticket 从新的稳定起点开始。这正是 DeepSpec `Controller.GenerateB` 该做的事，但现状是：写 `candidate-output.yaml` 后不解析、不合入树、不重渲染（BUG-8）。用户看到"LLM done"但地图没更新——等于 ticket 解完了结果没写回地图，下一个 session 从矛盾的状态起步。

**文章给的对齐标准**：一次 ticket session 的产出，必须让"地图收缩一点"（一个未知被回答）或"地图生长一点"（暴露新未知）。DeepSpec 的 GenerateB 闭环必须做到：candidate → 解析 → 合入对应树 → 更新该节点 fog_state（往 `fsClear` 方向收敛一步）→ `RenderAll` 重渲染，让用户**看见地图变了**。

### 缺口 3：Fog Map 的"Not yet specified"语义（对应 BUG-9，P1）

文章反复强调地图里那个 **Not yet specified** 区是刻意保留的迷雾——"你还不知道怎么描述的问题"。判断标准是"能不能用一句话精确地问出来"。

DeepSpec 当前 `RenderProblemsPage` 的 `#fog-map` 只按 fog_state 分组罗列雾区节点，没有体现"这个节点为什么在雾里、要问什么问题才能让它退雾"。**启发**：每个雾区节点应附带一句"待解问题"字段（即 ticket 的 question 文本），Fog Map 分组标题下应直接列出该雾区挂着的 ticket 及其状态。这样 Fog Map 才是真正的"探索地图"，而非只是"有问题的节点清单"。

---

## 三、可直接照搬的四个设计细节

1. **四种 ticket 的 HITL/AFK 属性**（文章原文）：
   - `research_ticket`：可 AFK（读文档/源码产出摘要，AI 自跑）。
   - `prototype_ticket`：必 HITL（粗糙原型，人要过来看一眼给反馈）——对应 DeepSpec 已有的 Tracer Bullet 思路。
   - `grilling_ticket`：默认 HITL（一问一答把模糊问题问清楚）——对应 DDD 的 Ubiquitous Language，产出通用词汇表。
   - `fog_unknown`：不是 ticket，是"还问不出来的问题"，留在雾里不硬拆。

   DeepSpec 可在 ticket 模型上加 `RequiresHuman: Boolean` 字段，UI 用它决定是自动跑还是等人。

2. **地图会生长也会收缩**：解完一个 ticket，可能让一个 `fsUnknownUnknowns` 退到 `fsFoggy`（收缩），也可能暴露新的 `fsUnknownUnknowns`（生长）。DeepSpec 的 `TFogState` 收敛是单向的（只能往 clear 走），但**新节点的 fog_state 可以是 `fsUnknownUnknowns`**——生长靠新雾区节点出现，收缩靠现节点退雾。这个机制已在数据模型里，需在闭环里实际触发。

3. **spec vs ticket 的层级**（文章原文）：spec 是跨多 session 的计划，ticket 是单 session 的计划。DeepSpec 的树节点（spec 层）和 ticket 应是父子关系——ticket 是某节点退雾的探索单元，挂在节点下。建议 `TTicket` 加 `ParentNodeId` 字段。

4. **晴天别开雾灯**：文章明确"终点明确就别绕路，直接 to-spec"。DeepSpec 不应给所有节点强标 fog——首次扫描只给真正"证据不足、靠推断"的 function 根标 fog（已是当前设计，见 bugfix.md #3 设计说明），其余从结构实打实推导的不算雾。

---

## 四、一句话总结

DeepSpec 已经内建了 wayfinder 的全部原语（fog 四态 + 四类探索 ticket），但**只建了数据模型，没建工作流**。文章给的路线图很清晰：先补 BUG-11（ticket 创建入口 + Fog Map 挂 ticket）和 BUG-8（GenerateB 闭环把 ticket 结果写回树、退雾、重渲染），DeepSpec 就从"静态 spec 浏览器"升级成"会生长的探索地图"——这正是 wayfinder 的核心价值，也是 DeepSpec 产品定位里最该兑现的那一层。

下一步建议优先级：**BUG-8（闭环）→ BUG-11（ticket 入口）→ BUG-9（Fog Map 展示 ticket）**，三者构成完整的"一次解一个 ticket"主循环。
