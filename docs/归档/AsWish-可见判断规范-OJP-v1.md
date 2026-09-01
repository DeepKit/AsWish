# AsWish 可见判断开发规范（OJP）

> **English Title:** AsWish Observable Judgment Specification
> **简称：** OJS
> **核心原则：** Observable Judgment Principle（OJP）
> **版本：** v1.0
> **状态：** 开发规范（2026-08-31 落库，已按老板裁定合入 VC 6 个、Difference 四层比较、可比性断层三处）
> **适用阶段：** First Closed Loop 及以后
> **适用范围：** AsWish 所有涉及 Human Observation / Confirmation / Judgment 的功能与工程实现
>
> **与既有文档的关系（SSOT 指向，不复制）**：
> - 与 [`AsWish-双界面交互规范-DualSurface-v1.md`](AsWish-双界面交互规范-DualSurface-v1.md) **正交**：本规范管"判断必须被看见/可追溯"，双界面规范管"判断发生在哪、谁触发、何时触发"。Observable 在两个界面都可能出现。
> - 0–9 数字交互协议见 [`AsWish-统一选择交互标准-v1.md`](AsWish-统一选择交互标准-v1.md)（子文档）。
> - Human/AI 边界、工程路线与双闸门见 [`AsWish-工程路线与Dogfood验收-v1.md`](AsWish-工程路线与Dogfood验收-v1.md)。
> - 本规范是产品行为与工程设计规范，**不是理论命题**，不定义 Difference Monism、As We Wish 或其他理论内容。

---

# 一、规范目的

AsWish 的核心交互并不是让人直接编辑复杂结构，而是：

```text
Human Intent → AI Interpretation → Human Judgment → Confirmed Understanding
→ Implementation → Evidence → Difference → Human Judgment → Revision
```

因此，AsWish 必须保证：

> **人类的判断不是针对系统内部不可见的状态发生，而是针对一个人能够实际观察到的对象发生。**

本规范用于规定：什么必须被人看见；什么必须具有可观察表现；什么情况下必须形成稳定视觉表现；SVG 在整个系统中的位置；Observable、Artifact、Judgment 三者的边界；可见对象如何与事实、Decision、Snapshot、Evidence、Difference 建立追溯关系；后续工程票如何以本规范作为共同开发门禁。

---

# 二、核心原则

## OJP-01：可见判断原则

> **凡是要求 Human 进行确认、接受、拒绝、比较、判断或修订的对象，必须具有与该判断对象对应的、稳定、可观察、可重复查看的表现。**

```text
需要 Human Judgment → 必须存在 Observable → Human 对 Observable 作 Judgment
```

禁止：

```text
Hidden State → AI says "已经正确" → Human 点击确认
```

也禁止：

```text
Internal Structure → AI 自动判断 → Human 只看到"通过"
```

---

# 三、OJP 的真正含义

OJP 不等于"每一步都生成一张图"，也不等于"所有对象都必须使用 SVG"。OJP 真正要求的是：

```text
Human Judgment → Observable Object → Human Judgment
```

因此：**Observable ≠ SVG**。SVG 只是 AsWish 当前最重要的结构可视化实现方式之一。

---

# 四、三个必须分开的概念

## 4.1 Artifact
系统产生、保存或引用的事实 / 数据 / 结构化对象。例如：Human Intent、Candidate、Change Set、Decision、SpecSnapshot、Implementation Evidence、Difference。

## 4.2 Observable
Artifact 或多个 Artifact 对人的可观察表现。例如：文字、表格、Tree、结构化 Review、SVG、Preview、Overlay、Difference View。Observable 是**人实际看到的东西**。

## 4.3 Judgment
Human 针对 Observable 所作的判断。例如：Accept、Reject、Unresolved、Acceptable、Unacceptable、Revision。

三者关系：

```text
Artifact → Observable → Human Judgment
```

禁止把三者混成一个状态。

---

# 五、OJP-02：判断必须有对象

任何 Human Judgment 必须能够回答"你究竟在判断什么？"，因此每一次判断必须能够定位到对应 Observable。

禁止出现 `Human: "通过"` 而系统无法回答"通过了什么、依据什么、人看到了什么"。

---

# 六、OJP-03：需要判断的对象必须可观察

以下操作都属于 Human Judgment：确认、接受、拒绝、比较、是否正确、是否符合预期、是否存在重要差异、是否接受某项 Difference、是否需要修订。

> **只要工程流程要求 Human 作上述动作，就必须首先提供相应 Observable。**

---

# 七、OJP-04：Observable 必须与判断对象语义对应

"有界面"不等于"可判断"。必须满足：**Human 通过当前 Observable 能够理解自己正在判断的对象。**

错误：`Change Set → 显示"AI 建议已生成" → [确认]`
正确：`Change Set → 显示 原始意图 + 目标节点 + Before + After + explicit/inferred/unknown → Human Judgment`

---

# 八、OJP-05：需要结构判断时必须存在稳定结构表现

当 Human 需要判断"这个结构现在是什么样"，必须提供稳定的结构表现。当前 AsWish 优先采用 `Render + SVG`。SVG 的作用是**把结构变成人能够直接观察的对象**。

---

# 九、OJP-06：Current State 与 Confirmed Baseline 必须区分

两者可以共享同一视觉结果，但语义绝不能混淆：

```text
Current State = 现在是什么
Confirmed Baseline = 我们已经确认要的是什么
```

因此允许 `Current State SVG → Human Confirmation → Confirmed Baseline` 而无需机械生成第二张完全相同的 SVG。

---

# 十、OJP-07：Visual Baseline 必须可重复

```text
Accepted Visual Baseline = SpecSnapshot + 视觉绑定 + 确定的 Renderer Version
```

不允许为实现 Baseline 新建 `VisualState / VisualBaselineEntity / VisualApproval / VisualReviewState` 等平行实体。

> **保真度边界（0028 钉死，v0 必须遵守）**：第一阶段 Baseline 是**结构线框（wireframe）**，`TSpecNode` 无布局字段（layout/position/bounds 均缺），确定性渲染「页面→区域→组件→层级」，**不承诺相对位置与尺寸**。

---

# 十一、OJP-08：可见对象必须可追溯

最低追溯原则：

```text
Observable → Artifact / Snapshot → Decision / Change Set → Human Intent
```

例如：`Baseline SVG → SpecSnapshot #42 → Decision #18 → ChangeSet #07 → Intent #03`。系统必须能够回答"这张图为什么是这个样子？"。

---

# 十二、OJP-09：可重复查看必须获得一致结果

相同输入 + 相同 Renderer Version + 相同视觉规则 → 可重复的同一视觉结果。禁止同一个 Baseline 第一次长这样、第二次自动变样，除非变更本身有明确记录。

---

# 十三、OJP-10：SVG 是实现载体，不是产品定义

产品标准定义的是"Human 必须能够观察并判断"，不是"Human 必须看到 SVG"。未来允许 SVG、Canvas、HTML、Interactive Tree、Other Visual Representation，只要满足 OJP。

---

# 十四、OJP-11：Visual Checkpoint v0

First Closed Loop 当前正式定义以下视觉检查点（**以此为准，覆盖历史 5 检查点版本**）：

```text
VC-01 Current State
VC-02 Problem Manifestation
VC-03 Confirmed Baseline
VC-04 Implementation Result
VC-05 Difference
VC-06 Revised Result
```

---

# 十五、VC-01 Current State
问题"现在是什么？"；必须看到当前真实结构；优先实现 `Spec → Render → Current State SVG`；验收：Human 能指出当前对象是什么、结构是什么、与当前任务有关的部分在哪。

---

# 十六、VC-02 Problem Manifestation
问题"问题 / 断口 / 未知在哪里？"。**不要求独立 SVG**，优先 `Current State SVG + Problem Overlay / Marker`（Fog、Unknown、Issue、Ambiguity、Missing Relation）。作用是显影问题，而不是代替 Human 解决问题。

> 落地口径：问题标记优先映射现有 `fog_state` / `grilling_ticket`，不新造问题标记体系；`fog_state` 属"待确权工程构造"（见理论确权清单）。

---

# 十七、VC-03 Confirmed Baseline
问题"我们确认的东西到底是什么？"。要求 `Human → 看见 → 确认 → Accepted Visual Baseline`。Baseline 必须可重复查看、可追溯、不被静默覆盖、能与后续 Implementation Result 比较。

---

# 十八、VC-04 Implementation Result
问题"Agent 实际做出来的东西是什么？"。必须区分：

```text
Implementation Evidence = Agent 实际做了什么
Implementation Result  = 实际产生了什么
```

结果不能只通过"Agent 已完成"来表示。

> 落地点：Implementation Result 是**具体平台产物**（有布局、有尺寸），其可视呈现依赖平台提取（见 §19 插件系统），不是 Render 直接生成。

---

# 十九、VC-05 Difference

问题"实际结果和确认结果哪里不同？"。

### 19.1 比较语义：四层比较（2026-08-31 老板钉死，挂 OCGS）

Difference 的结构比较按**四层**进行，由本质到表象：

```text
0 功能    为什么它存在，用它来干什么         —— OCGS：为（Purpose）
1 实体    有没有、叫什么、谁包含谁、数量对不对 —— OCGS：能（Ability）+ 属集结构
2 相对位置 谁在谁上 / 下 / 左 / 右 / 里 / 外   —— 空间关系（ASTO 属集 / 边界）
3 配色    看起来像什么                       —— 感知表象
```

判定顺序 = 编号顺序（0 → 3）：**高层差异是本质差异（0 层几乎总是不接受），低层差异是表象差异（3 层通常可接受），阈值由人裁**。

纪律（BJ-2「为≠当」）：**"看起来像"（3 层表象）≠ "还是那个东西"（0 层功能）**。

### 19.2 实现架构：插件系统

```text
0 / 1 层   平台无关 → 一套通用比较器（所有平台共用）
2 / 3 层   平台相关 → 平台插件（VCL / FMX / HB / WEB 各提供一个提取器）
```

每个平台插件首先提供**功能提取器**（从本平台产物反推"这是干嘛的"：Delphi 靠方法名/注释/控件 caption，WEB 靠 DOM/aria，HB 靠控件类型）。

### 19.3 可比性断层（v0 必须写死）

**Baseline 是结构线框（无位置尺寸），Implementation Result 是有布局的实际产物，两者不能直接 Side-by-side / Overlay 硬比。** 比较必须落在**共同比较层**上——即四层比较的 0/1 层（平台无关）——而不是拿线框和截图硬叠。v0 先做 0 + 1 层，2 / 3 作为插件逐步接。

### 19.4 表现方式

可用 Side-by-side、Overlay、Highlight、Structural Change List；Difference 的职责只有"让变化被看见"。

---

# 二十、Difference 不等于 Error

严格保持 `Difference ≠ Error`。Difference 可以是：No important difference / Acceptable difference / Unacceptable difference / Unresolved。禁止 `Difference detected → System automatically marks Error`。

---

# 二十一、VC-06 Revised Result

Revision 后不能只通过"已经修复"结束。必须重新进入 `Revision → Implementation → Evidence → Result → Difference → Human Judgment`，至少产生 `Result v2 / Difference v2` 并再次由 Human 判断。

---

# 二十二、六个 Checkpoint 的最低标准

| Checkpoint | Human 需要看到什么 | Human 需要判断什么 | 是否必须独立 SVG |
|---|---|---|---|
| VC-01 Current State | 当前真实结构 | 现在是什么 | 是 |
| VC-02 Problem | 当前结构 + 问题标记 | 这是不是我要解决的问题 | 否，优先 Overlay |
| VC-03 Baseline | 已确认目标结构 | 这就是我要的吗 | 是 / 可复用 Current |
| VC-04 Result | Agent 实际结果 | 做出来是什么 | 是 |
| VC-05 Difference | Baseline 与 Result 的变化 | 哪里不同 | 比较视图 |
| VC-06 Revised Result | 修正后的结果 | 这次对了吗 | 是 |

---

# 二十三、Candidate / Decision / Evidence 不要求独立 SVG

**可见 ≠ 必须视觉化。** Candidate、Change Set、Decision、Evidence、Intent 可以采用语义化 UI（文本 / 语义化 Review / 裁决界面 / 事实记录界面）。只有当对象本身涉及结构空间、布局、视图状态等内容时，才需要进入结构视觉表现。

---

# 二十四、所有"确认"必须经过 Observable

任何 `Confirm / Approve / Accept / Reject / Judge` 实现都必须检查：①判断对象是谁 ②人看到了什么 ③Observable 来自哪里 ④人的判断记录在哪里 ⑤能否回溯到对应 Artifact。缺一项不得宣称完成。

---

# 二十五、Human / AI Boundary

## Human owns
Intent、Judgment、Decision、Accept、Reject、Unresolved、Difference Judgment、Revision Decision、Final Confirmation。

## AI may
Discover、Ask、Explain、Suggest、Transform、Generate、Render、Implement、Inspect、Surface Difference。

## AI must not
把猜测当确认、把 Candidate 当 Decision、把 Difference 当 Error、未经确认修改 Canonical Spec、替 Human 做最终判断、替 Human 宣布闭环完成。

---

# 二十六、OJP 与 First Closed Loop 的关系

完整链条（Human Intent → Problem Manifestation → Candidate/Interpretation → Human Confirmation → Confirmed Understanding → Visual Baseline → Agent Development → Implementation Evidence → Implementation Result → Difference → Human Judgment → Revision → Rebuild → Re-verification）中，每一次 Human Judgment 都必须能够找到对应 Observable。

---

# 二十七、OJP 与 Dogfood 的关系

第一个 Dogfood Task 必须真实产生：Current State、Problem Manifestation、Candidate、Human Confirmation、Confirmed Baseline、Implementation Evidence、Implementation Result、Difference、Human Judgment、Revision、Result v2、Difference v2、Human Re-verification。**不要求 13 张图**，要求的是每个真正需要 Human 判断的对象都真实出现并被 Human 观察。

---

# 二十八、工程票必须增加 OJP Acceptance

任何涉及 Human Confirmation / Decision / Visual Baseline / Difference / Revision 的工单，必须加入 OJP Acceptance：

```text
□ Human 判断对象明确
□ 对象具有 Observable
□ Observable 与判断对象语义对应
□ Human 能直接观察
□ Observable 可以追溯
□ 可重复查看
□ AI 没有代替 Human 判断
□ 没有为了视觉功能增加平行实体
```

任何一项违反 → RETURNED，不得 CLOSE。

---

# 二十九、禁止模式

29.1 Hidden Approval（AI 内部完成判断 → Human 只点 OK）禁止。29.2 Blind Decision（Human 不知道具体对象 → Accept）禁止。29.3 Status-as-Observation（`status=completed` 不能替代 Actual Result）禁止。29.4 AI-as-Judge（AI"Difference 不重要"+Human[确认]）禁止。29.5 SVG-as-Product 禁止。29.6 One-SVG-per-Stage 禁止（优先判断是否可复用、是否只是 Overlay、是否只是比较、是否真的需要新视觉结果）。

---

# 三十、Artifact / Observable / Judgment 的基本链

```text
Artifact（系统事实/对象）→ Observable（人可观察表现）→ Judgment（人类判断）→ 新的 Artifact
```

AsWish 的真正闭环不是 `Data → UI → Done`，而是 `Artifact → Observable → Human Judgment → New Artifact`。

---

# 三十一、视觉表现的最小要求

视觉表现首先必须：准确、稳定、可读、可比较、可追溯；其次才考虑美观、动画、交互效果、视觉风格。First Closed Loop 阶段：**正确看见优先于漂亮看见。**

---

# 三十二、OJP 不要求自动解释一切

可观察不等于必须解释。例如 Difference View 可直接显示 `Node A title Before:X After:Y`，而不必自动生成"这意味着 Agent 误解了你的需求"（后者属于判断）。OJP 要求的是把事实和变化呈现出来，让 Human 有条件判断。

---

# 三十三、第一版能力边界

OJP v1 不要求 Pixel Diff、视觉 AI 自动评分、自动审美评价、自动错误归因、自动修复、自动接受 Difference、自动回滚。当前只要求：可见、可追溯、可重复、可比较、可判断。

---

# 三十四、与现有 AsWish 架构的关系

OJP 不新增独立架构层，优先复用 CandidateIngest、Decisions、Snapshot、Render、TreeBuilder、SpecStore、Prompts、Semantic Bundles、Evidence、Difference；不新增 VisualState、VisualDecision、VisualApproval、VisualProposal、VisualBaselineEntity、VisualReviewState。

---

# 三十五、开发设计时的五个问题

① Human 在这里需要判断什么？② Human 判断的具体对象是什么？③ Human 在哪里看见这个对象？④ 这个 Observable 从哪个 Artifact / Snapshot 得到？⑤ Human 的判断如何与这个 Observable 建立追溯关系？回答不了 → 该交互尚未达到可验收标准。

---

# 三十六、First Closed Loop 的最终 OJP 验收

Intent / Candidate / Baseline / Implementation / Difference / Revision 六段各自必须形成 `Observable → Judgment`，且同一真实任务至少完整经历 `v1 → Difference → Human Judgment → Revision → v2 → Difference v2 → Human Re-verification`。

---

# 三十七、最终原则

> **Human does not judge what the system knows internally; Human judges what AsWish makes observable.**

中文：**人类不判断系统内部不可见的状态；人类判断 AsWish 显现出来的对象。**

```text
没有可见对象 → 没有有效判断
没有人类判断 → 没有最终确认
没有可追溯的判断 → 没有完整闭环
```

---

# 三十八、与"所见即所得"的关系

AsWish 的"所见即所得"在 OJP 下应理解为：**不是"看到什么就保存什么"，而是"需要人确认的东西必须先被可靠地显现出来，人类的判断针对显现对象发生，并成为后续状态的依据"**。

```text
See → Judge → Confirm → Build → See Again → Compare → Judge Again
```

---

# 三十九、规范优先级

当工程实现与 OJP 冲突时：`OJP > 单票工程便利 > 当前 UI 实现`。但 OJP 本身不覆盖产品身份、理论定义、协议法源、工单具体 AC（仍遵循既有 SSOT 与文档治理规则）。若 OJP 与既有 SSOT 冲突：标记冲突，不自行裁决。

---

# 四十、版本演进

OJP v1 只建立"可见、可判断、可追溯的最小闭环"。未来 v2/v3/v4 可扩展更丰富视觉比较、跨版本比较、交互式可视化等，但任何扩展都不得破坏 `Human Judgment + Observable + Traceability` 三个核心约束。
