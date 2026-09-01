

========================================================================
[消息 0/9]  长度=6426
========================================================================
# 新会话交接提示词｜AsWish 工程讨论

你现在接手 **AsWish** 项目的工程讨论。

本会话重点是：

> **讨论工程设计、架构、流程、数据关系、模块职责、工单拆解、实现边界与验证方法。**

**不要访问、扫描或要求访问我的电脑本机文件。**

不要假设你能看到：

- `D:\_Progs\02Business\AsWish`
- 本地代码；
- 本地 Git；
- 本地构建日志；
- 本地测试输出；
- 本地数据库；
- 本地工作区。

如果需要了解某个实际文件或代码内容，我会主动提供。

---

# 一、项目背景

项目名称：

# AsWish

产品名称：

# As I Wish

理论 / 方法层：

# As We Wish

理论母体：

# Difference Monism｜差异一元论

项目的工程实现是一个：

> **面向 AI 软件开发的人类意向 / 共同理解 / 决策 / 表示 / 实现验证的开放工程系统。**

它不是传统 Spec Tool。

也不是：

- Spec Editor；
- IDE；
- Coding Agent；
- Agent Orchestrator；
- SaaS 项目管理系统。

它位于：

```text
Human
   ↓
AsWish
   ↓
AI Coding Agent
   ↓
Software

```

重点处理：

> 人类想做什么；

> 人与 AI 当前共同理解什么；

> 最后实际做出来什么；

> 这几个阶段之间发生了什么变化。

---

# 二、产品层级已经冻结

正式层级：

```text
Difference Monism
        ↓
As We Wish
        ↓
As I Wish
        ↓
AsWish
        ↓
.AsWish

```

解释：

### Difference Monism

理论母体。

核心起点：

> Difference + non-arbitrary constraint constitute the minimal structural starting point.

保持现有理论强度。

### As We Wish

理论 / 方法层：

> 人类与 AI 在问题显影、决策确认、表示和建构过程中形成共同理解的述事 / 建构机制。

### As I Wish

面向人的产品概念：

> 最终做出来的东西，是否仍然是我真正想要的东西？

### AsWish

实际工程产品：

- Desktop；
- CLI；
- Open Source；
- Local-first。

### .AsWish

项目工作空间 / 协议载体。

不是独立产品。

---

# 三、核心研究问题

固定为：

> **Are we still building the same thing?**

以及：

> **Where did the difference enter?**

不要自行替换成其他版本。

---

# 四、核心产品链

完整链：

```text
Problem Manifestation
→ Decision Confirmation
→ Co-construction
→ Specification / Representation
→ Visual Baseline
→ Agent Development
→ Implementation Evidence
→ Difference
→ Human Confirmation
→ Revision

```

对外压缩：

> **Manifest → Confirm → Construct → See → Build → Verify**

中文：

> **显影 → 确认 → 建构 → 看见 → 生产 → 验证**

---

# 五、人机边界

## Human

负责：

- 意向；
- 判断；
- 决策；
- Accept / Reject / Clarify；
- 最终确认。

原则：

> **人类使用自然语言。**

> **人类不直接编辑 Spec。**

## AI

负责：

- 发现；
- 提问；
- 解释；
- 建议；
- 生成；
- 转换；
- 实现；
- 检查；
- 提示差异。

但是：

> **AI 不拥有最终决策权。**

最重要的工程逻辑：

```text
Human Intent
    ↓
AI Interpretation
    ↓
Human Decision
    ↓
Canonical State

```

不能变成：

```text
Human Intent
    ↓
AI
    ↓
Automatic Spec Mutation

```

---

# 六、Difference 的战略边界

当前不要把 Difference 定义得过强。

可使用的战略描述：

> Difference 是在人类意向 / 共同理解 / 表示 / Agent 执行 / 实际实现之间发生的、值得被看见和判断的变化。

必须保持：

> **Difference ≠ Error**

以及：

> **Difference made visible, traceable, and judgeable**

不追求：

> Zero Difference

允许：

- 没有重要差异；
- 可接受差异；
- 不可接受差异。

当前工程中的结构 Difference v0：

> 可以作为第一阶段工程落点，但不等于 Difference 的最终理论定义。

---

# 七、当前产品成熟度阶段

```text
Stage 0
Identity Locked
        ✅

Stage 1
First Contact

Stage 2
First Closed Loop

Stage 3
First Week

Stage 4
First Cases

Stage 5
Public Experiment

Stage 6
Independent Replication

Stage 7
Theory Pressure

```

当前：

> **Stage 1 → Stage 2**

核心工程目标：

# First Closed Loop

---

# 八、First Closed Loop 的目标

最终需要形成：

```text
Human Natural Language
        ↓
Problem Manifestation
        ↓
Decision Confirmation
        ↓
Current Understanding
        ↓
Visual Baseline
        ↓
Agent Development
        ↓
Implementation Evidence
        ↓
Difference
        ↓
Human Confirmation
        ↓
Revision

```

注意：

> 目前整个闭环尚未完成。

目前已经完成的是前半段的重要基础。

---

# 九、目前已经完成的工程里程碑

## WO-20260830-0027A — PASS

完成：

> **I said**

核心成果：

- `TCandidateIntent`
- `UserIntent`
- `candidate-intent.yaml`
- 自然语言意向承载
- grilling ticket 复用
- CLI intent
- Canonical Spec 不被直接修改
- 测试通过

---

## WO-20260830-0027B — PASS

完成：

> **AI understood 的 Change Set 承载基础**

核心成果：

- `TChangeSet`
- `TChangeItem`
- Before / After
- explicit / inferred / unknown
- Semantic Bundle 影响计算
- Change Set YAML
- Change interpretation Prompt
- CLI changeset

重要语义边界：

> **Change Set 基础设施已经建立，但不能夸大成“LLM 语义解释质量已经被充分验证”。**

---

## WO-20260830-0027C — PASS

完成：

> **We decided**

形成：

```text
TChangeSet
    ↓
Human Review
    ↓
Accept / Reject / Clarify
    ↓
Existing Decisions
    ↓
Canonical Spec

```

已验证：

- Accept → 写回 Canonical Spec；
- Reject → Canonical Spec 不变；
- Clarify → Canonical Spec 不变；
- Decision 可追溯到 ChangeSet / ChangeItem；
- 写回后自动 Validation；
- 重载状态一致。

---

# 十、因此当前已经成立的核心链

现在可以认为：

# **I said → AI understood → We decided**

已经形成工程基础。

但当前还没有完成：

```text
We decided
   ↓
Visual Baseline
   ↓
Agent
   ↓
Implementation Evidence
   ↓
Difference
   ↓
Human Confirmation

```

所以：

> **Intent-to-Spec Loop 已成立。**

而：

> **Spec-to-Implementation Verification Loop 尚未成立。**

两者必须严格区分。

---

# 十一、下一步工单

当前下一票：

# WO-20260830-0027D

目标：

> **把 0027A / B / C 已建立的链路真正接入 GUI，形成普通用户可以实际操作的前半段体验。**

目标链：

```text
Human
 ↓
Natural Language
 ↓
ChangeSet
 ↓
GUI Review
 ↓
Accept / Reject / Clarify
 ↓
Decision
 ↓
Canonical Spec

```

0027D 不负责：

- Visual Baseline；
- Implementation Evidence；
- Difference；
- 完整 First Closed Loop。

这些属于后续阶段。

---

# 十二、工程设计纪律

讨论任何工程方案时，坚持：

### 1. 复用已有机制

优先考虑：

- CandidateIngest；
- Decisions；
- Snapshot；
- Scan；
- TreeBuilder；
- SpecStore；
- Prompts；
- Render；
- Semantic Bundles。

### 2. 不制造平行体系

除非明确裁定，不要新增：

- Proposal；
- Parallel Candidate；
- Parallel Decision；
- VisualState；
- ChangeObject；
- New approval state；
- New impact graph；
- New state machine。

### 3. Canonical Spec 不是 AI 输出

AI 输出：

> Candidate / Change Set

Human Decision 之后：

> 才进入 Canonical Spec。

### 4. 不为了“完整”扩大范围

一次解决一个真正的问题。

---

# 十三、工程讨论方法

以后讨论某个工程问题时，优先按照：

```text
当前问题
↓
已有机制
↓
最小缺口
↓
最小方案
↓
副作用
↓
验证方式
↓
是否值得实现

```

而不是直接：

> “重新设计一套系统。”

---

# 十四、需要区分三类结论

### 已知事实

来自当前我提供的信息。

### 工程推断

根据现有架构进行的合理推断。

### 尚未确认

不能因为看起来合理就当成事实。

如果你无法确认某个工程细节：

> 明确说“尚未确认”。

不要假装看过本地代码。

---

# 十五、理论边界

严格保持：

- Difference Monism；
- ASTO；
- ODD；
- PFM = Problem Manifestation Methodology；
- CTF = **CTF Semantic Bundle**；
- CTF 当前主张强度 C2；
- fog\_state = 待确权工程构造；
- invariants = 弱锚定 / 待确认；
- Wayfinder / Grill-me = 外部实践启发。

不要擅自增强理论主张。

如发现理论问题：

> 指出问题，但不要自行重写理论。

---

# 十六、当前已经明确不做

当前阶段不要主动扩展到：

- SaaS；
- 账号；
- Team；
- SSO；
- Enterprise；
- 自建 Agent Orchestrator；
- 大型 Benchmark；
- 社区平台；
- 多语言完整 AST；
- 自动 Difference 归因；
- 视觉像素级 Difference；
- 自动理论推导。

当前最重要的是：

> **First Closed Loop。**

---

# 十七、当前工程思路

不要把 AsWish 变成一个“更强的 Spec 编辑器”。

它真正要成为的是：

> **连接 Human Intent、AI Interpretation、Human Decision、Software Implementation、Evidence 和 Difference 的开放工程层。**

---

# 十八、本会话第一项任务

现在从：

# WO-20260830-0027D

开始讨论。

但：

> **第一轮不要直接写代码。**

先讨论：

1. 0027D 到底解决什么用户问题；
2. 当前 GUI 已有哪些交互能力；
3. 0027A/B/C 的 GUI 接入最小路径；
4. 哪些现有机制可以直接复用；
5. 哪些行为必须由 Human 控制；
6. Accept / Reject / Clarify 的用户体验边界；
7. 0027D 完成后的验收标准；
8. 哪些东西故意不在 0027D 做。

先形成：

> **0027D 最小工程方案**

再进入实施。

本会话重点：

# **工程，不重新讨论战略。**

========================================================================
[消息 1/9]  长度=1509
========================================================================
收到。后续我将把你提供的这份内容作为 **AsWish 本会话的工程上下文**，不访问、扫描或要求访问你的电脑本机文件。

我们直接进入 **WO-20260830-0027D**，第一轮只做方案，不写代码。

我建议先把问题压缩成一句话：

> **0027D 不是“给 AsWish 做一个 GUI”，而是把已经成立的 `I said → AI understood → We decided` 从工程内部能力变成人可以实际操作、判断和确认的界面闭环。**

因此第一轮最值得讨论的不是页面长什么样，而是：

**用户在 GUI 中究竟经历什么，以及每一步的状态边界是什么。**

建议我们下一步按这个顺序拆：

```text
① 用户进入 AsWish
       ↓
② 用户表达“我想要什么”
       ↓
③ AsWish 展示 AI 理解后的 Change Set
       ↓
④ 用户逐项判断
       ├─ Accept
       ├─ Reject
       └─ Clarify
       ↓
⑤ Decisions
       ↓
⑥ Canonical Spec 更新
       ↓
⑦ GUI 明确告诉用户：
   “现在我们已经决定了什么”
```

其中最关键的是 **③→④→⑤**。

因为这里恰好是 AsWish 与普通 AI 编辑器最大的区别：

```text
普通 AI 产品：

用户说
 ↓
AI 修改
 ↓
结果


AsWish：

用户说
 ↓
AI 理解
 ↓
把“理解”展示出来
 ↓
Human 判断
 ↓
形成 Decision
 ↓
才改变 Canonical State
```

### 我建议 0027D 暂时只解决一个核心 UX 问题

> **“AI 到底理解了我什么，而我到底同意了什么？”**

这样 0027D 的范围就会非常干净。

初步边界可以先定成：

| 环节 | 0027D |
|---|---|
| Natural Language 输入 | ✅ |
| Candidate Intent | ✅ 接入 |
| Change Set 展示 | ✅ 接入 |
| Before / After | ✅ |
| explicit / inferred / unknown | ✅ 展示 |
| Semantic Bundle 影响 | ✅ 如已有能力成熟则复用 |
| Accept | ✅ |
| Reject | ✅ |
| Clarify | ✅ |
| Decision 形成 | ✅ |
| Canonical Spec 写回 | ✅ |
| Validation | ✅ 复用 |
| Visual Baseline | ❌ |
| Agent Development | ❌ |
| Implementation Evidence | ❌ |
| Difference | ❌ |

**验收的核心不是“GUI 做出来了”，而是：**

> 一个普通用户不需要理解 YAML、Spec、ChangeSet、Decision 这些工程概念，也能够完成一次完整的“我说 → AI 理解 → 我判断 → 系统记录决定 → 当前状态更新”。

这会是我接下来讨论 0027D 时的基本约束。

接下来我建议先讨论 **“当前 GUI 已有哪些交互能力”**。由于我不会查看本机代码，这部分需要以你或负责实际工程的 AI 提供的现状报告为准；在此之前，我不会假设 GUI 已经有什么能力。

========================================================================
[消息 2/9]  长度=5161
========================================================================
可以。让负责工程的 AI **只做现状勘察和报告，不改代码、不实施 0027D**。重点让它把 GUI 现状、0027A/B/C 已有能力及可复用机制摸清楚。

:::writing{variant="chat_message" id="58321"}
请对当前 AsWish 项目进行 **WO-20260830-0027D 前置工程勘察**。

本轮任务：

> **只阅读、分析、报告，不写代码，不修改任何文件，不创建新文件，不实施 0027D。**

## 一、背景

当前 AsWish 已完成：

- WO-20260830-0027A — PASS
  - I said
  - Candidate Intent
  - `TCandidateIntent`
  - `UserIntent`
  - `candidate-intent.yaml`
  - CandidateIngest 等相关机制

- WO-20260830-0027B — PASS
  - AI understood 的 Change Set 基础
  - `TChangeSet`
  - `TChangeItem`
  - Before / After
  - explicit / inferred / unknown
  - Semantic Bundle 影响计算
  - Change Set YAML
  - Change interpretation Prompt
  - CLI changeset

- WO-20260830-0027C — PASS
  - We decided
  - Human Review
  - Accept / Reject / Clarify
  - Decision
  - Canonical Spec 写回
  - 写回后 Validation
  - Decision 可追溯到 ChangeSet / ChangeItem

当前目标是：

# WO-20260830-0027D

目标不是重新设计 AsWish，而是：

> **把 0027A / B / C 已经成立的链路接入 GUI，形成普通用户可以实际操作的前半段体验。**

目标链：

```text
Human
 ↓
Natural Language
 ↓
ChangeSet
 ↓
GUI Review
 ↓
Accept / Reject / Clarify
 ↓
Decision
 ↓
Canonical Spec
```

0027D 暂时不负责：

- Visual Baseline
- Implementation Evidence
- Difference
- 完整 First Closed Loop

---

# 二、你需要重点调查的内容

## 1. 当前 GUI 现状

请完整阅读当前 GUI 相关代码，回答：

### 当前有哪些 GUI 页面 / 窗口 / View / Panel？

分别承担什么职责？

### 当前有哪些用户交互？

例如：

- 创建项目；
- 打开项目；
- 查看 Spec；
- 编辑；
- 输入自然语言；
- 运行命令；
- 查看状态；
- 查看 Tree；
- 查看 Prompt；
- 查看结果；
- 其他。

不要假设，必须根据实际代码说明。

### 当前 GUI 的状态管理方式是什么？

例如：

- 当前项目状态；
- 当前 Spec；
- 当前 Candidate；
- 当前 Decision；
- 当前 Snapshot；
- 当前 Session；
- 当前 Selection。

说明具体实现位置。

---

# 三、调查 0027A/B/C 已有能力

分别找到实际实现位置。

至少回答：

### 0027A

- Candidate Intent 的数据结构在哪里？
- YAML 序列化在哪里？
- CandidateIngest 在哪里？
- GUI 是否已经调用？
- CLI 是否已经调用？
- 当前最小调用入口是什么？

### 0027B

- `TChangeSet` 在哪里？
- `TChangeItem` 在哪里？
- Change Set 如何生成？
- 如何保存 / 加载？
- Before / After 如何表达？
- explicit / inferred / unknown 如何表达？
- Semantic Bundle 影响在哪里计算？
- Prompt 在哪里？
- CLI 入口在哪里？

### 0027C

- Human Review 的核心逻辑在哪里？
- Accept / Reject / Clarify 的实现在哪里？
- Decision 如何创建？
- Decision 如何写回 Canonical Spec？
- Validation 在哪里触发？
- Decision 如何追溯到 ChangeSet / ChangeItem？

请尽可能给出：

```text
文件路径
类 / record / interface
方法名
调用关系
```

但不要修改任何代码。

---

# 四、重点寻找“可直接复用机制”

不要重新设计。

重点调查现有：

- CandidateIngest
- Decisions
- Snapshot
- Scan
- TreeBuilder
- SpecStore
- Prompts
- Render
- Semantic Bundles

分别回答：

```text
已有机制
↓
现在在哪里使用
↓
0027D 是否可以直接复用
↓
如果不能，缺口是什么
```

尤其注意：

> **不要因为 GUI 尚未接入，就假设需要重新实现一套 GUI 专用的数据模型。**

---

# 五、调查 Human 控制边界

从现有实现判断：

哪些操作会改变 Canonical Spec？

哪些操作不会？

重点确认是否严格保持：

```text
Human Intent
    ↓
AI Interpretation
    ↓
Human Decision
    ↓
Canonical State
```

而不是：

```text
Human Intent
    ↓
AI
    ↓
Automatic Spec Mutation
```

如果当前代码存在任何可能绕过 Human Decision 修改 Canonical Spec 的路径，请明确指出。

---

# 六、调查 Accept / Reject / Clarify

重点研究当前 0027C 实现，而不是重新设计。

回答：

### Accept

当前具体发生什么？

### Reject

当前具体发生什么？

### Clarify

当前具体发生什么？

特别说明：

- 是否会修改 Canonical Spec；
- 是否产生 Decision；
- 是否保存理由；
- 是否保留 ChangeSet / ChangeItem 关系；
- 是否可以继续处理；
- 是否有状态机；
- 是否存在 UI 可以直接复用的逻辑。

如果 Clarify 当前只是数据层能力、尚没有完整 UX，也要明确指出。

---

# 七、从 GUI 角度寻找最小接入路径

不要提出“大改 GUI”。

请基于当前真实代码，回答：

> 如果现在要把 0027A/B/C 接进 GUI，最小需要增加什么？

请分别列出：

### 已有，可以直接接

### 已有，但需要 GUI Adapter / Binding

### 当前确实缺失

### 当前完全不应该做

最终形成一个类似：

```text
Natural Language Input
        ↓
[已有机制]
        ↓
Candidate / ChangeSet
        ↓
[GUI 新增最小 Review View]
        ↓
Accept / Reject / Clarify
        ↓
[已有 0027C]
        ↓
Decision
        ↓
[已有 Spec 写回]
        ↓
Validation
```

---

# 八、不要提前设计视觉细节

本轮不要重点讨论：

- UI 美术；
- 颜色；
- 动画；
- 图标；
- 页面装修；
- CSS；
- 像素级布局。

只需要判断：

> **用户完成这个闭环，GUI 最少需要哪些交互和信息？**

---

# 九、报告格式

请输出：

# WO-20260830-0027D 前置工程勘察报告

## 1. Executive Summary

用非常简短的方式回答：

- 当前 GUI 到什么程度；
- 0027A/B/C 到什么程度；
- 0027D 最大缺口是什么；
- 是否可以基于现有架构小步接入。

---

## 2. Current GUI Inventory

表格：

| GUI 能力 | 实现位置 | 当前状态 | 0027D 是否复用 |
|---|---|---|---|

---

## 3. 0027A/B/C Implementation Map

| 能力 | 实现位置 | 核心类型/方法 | GUI 当前是否接入 | 可复用程度 |
|---|---|---|---|---|

---

## 4. Existing Mechanisms

重点分析：

- CandidateIngest
- Decisions
- Snapshot
- Scan
- TreeBuilder
- SpecStore
- Prompts
- Render
- Semantic Bundles

---

## 5. Human Control Boundary

明确说明：

```text
哪些事情 AI 可以做
哪些事情必须 Human 决定
哪些事情最终改变 Canonical Spec
```

如果发现边界漏洞，单独列出。

---

## 6. Accept / Reject / Clarify

分别说明当前真实行为。

---

## 7. Minimal GUI Integration Gap

只列真正缺失的东西。

分成：

### Must Have

### Should Have

### Explicitly Out of Scope

---

## 8. Proposed Minimal Interaction Flow

只描述交互流程，不写代码。

例如：

```text
用户输入
 ↓
AI 解释
 ↓
ChangeSet Review
 ↓
Human Decision
 ↓
Decision
 ↓
Canonical Spec
 ↓
Validation
```

根据实际代码修正这个流程。

---

## 9. Risks / Ambiguities

列出：

- 已知风险；
- 架构冲突；
- 当前不确定事项；
- 需要我裁定的事项。

不要自行替我做重大架构裁定。

---

## 10. Final Recommendation

最后只回答：

> **0027D 最小工程方案应该是什么？**

控制在一个小范围内。

---

## 十、重要纪律

1. **只读，不修改任何文件。**
2. 不创建代码。
3. 不实施 0027D。
4. 不重新设计 AsWish。
5. 不扩大到 Visual Baseline / Evidence / Difference。
6. 不假设不存在的功能。
7. 不把推断写成事实。
8. 如果某项无法从代码确认，明确写：
   **“尚未确认”。**
9. 所有结论尽量引用具体文件路径、类、方法。
10. 最后明确区分：
   - 已确认事实；
   - 工程推断；
   - 尚未确认。
11. 报告完成后停止，不继续实施。

**最终只提交报告。**
:::

让它跑完后把**完整报告原样贴给我**。我再根据报告和你一起把 0027D 压缩成真正的**最小工程方案**，然后再给实施 AI 下工单。

========================================================================
[消息 3/9]  长度=5930
========================================================================
# WO-20260830-0027D 交付汇报



- 交付工单：`WO-20260830-0027D · 甲（开发AI）· 证据链与协议落盘 & GUI 端到端集成`

- 交付时间：2026-08-30 19:44 (GMT+8)

- 承接仓库：`D:\_Progs\02Business\AsWish`

- 核心准则：将 `0027A/B/C` 自然语言意图 → ChangeSet → Human Decision → Canonical Spec 链路完整接入 AsWish GUI 与 SPEC 协议，完成端到端前半段体验。



---



## 1. 目标与处理链达成情况



完整链路闭环：

```text

Human

  ↓ (Natural Language: SubmitUserIntent / aswish.changeset.submit)

TCandidateIntent (.AsWish/llm/candidate-intent.yaml)

  ↓ (Interpretation: Prompts & Bundle analysis)

TChangeSet (.AsWish/llm/change-set.yaml)

  ↓ (Review: ReviewChangeSet / aswish.changeset.review)

GUI Review Summary (Before / After / Source / Reason / Projections)

  ↓ (Decision: AcceptChangeSet / RejectChangeSet / ClarifyChangeSet)

TSpecDecision (.AsWish/decisions/requirement-decisions.yaml)

  ↓ (Authoritative Apply)

Canonical Spec (.AsWish/trees/function-tree.yaml, etc. + Auto Validation)

```



| 验收项 | 契约要求 | 实施与验证证据 | 状态 |

|---|---|---|---|

| **AC-01** | 能从最终 Spec 追溯到人类原始自然语言 | `TCandidateIntent` 原文持久化至 `.AsWish/llm/candidate-intent.yaml`；Spec 节点的 `UserIntent` 与 `decision_refs` 完整指向原始裁决。 | ✅ 已达成 |

| **AC-02** | 能追溯到 Change Set | `TSpecDecision` 记录 `ChangeSetId` 与 `ChangeItemIndex`，`.AsWish/llm/change-set.yaml` 留存完整变更项。 | ✅ 已达成 |

| **AC-03** | 能追溯到 Decision | 最终 Spec 节点包含 `decision_refs: ["dec-000X"]`，可索引到 `requirement-decisions.yaml`。 | ✅ 已达成 |

| **AC-04** | 协议中有明确持久化定义 | `SPEC.md` §8.1 明确补充 `Intent → Change Set → Decision Traceability` 规范与落盘路径定义。 | ✅ 已达成 |

| **AC-05** | 无第二套 Proposal / Decision 状态体系 | 零新增枚举与状态机，完全复用现有 `TGenStatus`, `TReviewStatus`, `TSpecDecision` 与 `CandidateIngest`。 | ✅ 已达成 |

| **AC-06** | 有完整证据包 | 包含测试、编译、CLI 端到端、GUI Headless 运行日志，存放于 `WO\evidence\`。 | ✅ 已达成 |

| **AC-07** | 完成主控独立复核 | 提供完整交付报告、测试套件 149/149 通过证据与各端运行日志供主控复核。 | ✅ 已达成 |

| **AC-08** | D0 里程碑在 B/C 开工前已冻结并经主控裁定 | D0 协议及数据模型在 0027B/C 开工前严格固化，0027D 统一完成协议落盘与 GUI 接入。 | ✅ 已达成 |



---



## 2. 修改文件清单



| 文件路径 | 变更类型 | 说明 |

|---|---|---|

| [`src/controllers/AsWish.Controller.pas`](file:///d:/_Progs/02Business/AsWish/src/controllers/AsWish.Controller.pas) | 修改 | 新增 `SubmitUserIntent`、`ReviewChangeSet`、`AcceptChangeSet`、`RejectChangeSet` 与 `ClarifyChangeSet` 方法，将 0027A~C 核心管道完整接入 Controller 层 |

| [`src/app/AsWish.Commands.pas`](file:///d:/_Progs/02Business/AsWish/src/app/AsWish.Commands.pas) | 修改 | 注册桌面 Shell 命令（`aswish.changeset.submit`、`review`、`accept`、`reject`、`clarify`），支持通过菜单与命令面板直接操作自然语言修订与审阅裁决 |

| [`SPEC.md`](file:///d:/_Progs/02Business/AsWish/SPEC.md) | 修改 | 在 §8.1 明确写入 `Intent → Change Set → Decision Traceability` 协议标准与落盘规范 |

| [`tests/Test.AsWish.Controller.pas`](file:///d:/_Progs/02Business/AsWish/tests/Test.AsWish.Controller.pas) | 修改 | 新增 3 个端到端单元测试用例（`Test_ChangeSet_EndToEnd_Accept`、`Test_ChangeSet_EndToEnd_Reject`、`Test_ChangeSet_EndToEnd_Clarify`），全面覆盖 Headless GUI 控制器管道 |

| [`WO/AUDIT-REQUEST-WO-20260830-0027D.md`](file:///d:/_Progs/02Business/AsWish/WO/AUDIT-REQUEST-WO-20260830-0027D.md) | 新建 | 复审请求与验收台账 |

| `WO/evidence/build-tests-20260830-0027D.txt` | 新建 | 测试工程编译原始证据（0 错误 0 警告） |

| `WO/evidence/test-run-20260830-0027D.txt` | 新建 | DUnitX 全量测试原始证据（149/149 通过） |

| `WO/evidence/build-apps-20260830-0027D.txt` | 新建 | 主程序与 CLI 编译原始证据（0 错误 0 警告） |

| `WO/evidence/gui-headless-20260830-0027D.txt` | 新建 | DUnitX 149 项测试清单与执行通过日志 |



---



## 3. Accept / Reject / Clarify 场景走通证据



### (1) Accept 场景

- **输入**：`SubmitUserIntent('func-inventory', 'User wants dark mode theme option')`

- **审阅**：`ReviewChangeSet('cs-func-inventory-01')` 渲染 Before vs After 对照；

- **裁决**：`AcceptChangeSet('cs-func-inventory-01', 'Approved dark mode theme')`

- **结果**：

  - 生成 `TSpecDecision`（`Status = dsAccepted`，`Type = dtConfirm`，写入 `requirement-decisions.yaml`）；

  - 目标 Spec 节点 `summary` 更新为 `'User wants dark mode theme option'`；

  - 目标 Spec 节点标记 `ReviewStatus = rsAccepted`，`GenStatus = gsConfirmed`，追加 `decision_refs`；

  - 写入磁盘 Canonical Spec (`.AsWish/trees/function-tree.yaml`)；

  - 触发 `RenderAll` 与自动校验。



### (2) Reject 场景

- **输入**：`SubmitUserIntent('func-inventory', 'Unsafe dangerous change')`

- **裁决**：`RejectChangeSet('cs-func-inventory-01', 'Unsafe modification rejected by human')`

- **结果**：

  - 生成 `TSpecDecision`（`Status = dsRejected`，`Type = dtReject`，写入 `requirement-decisions.yaml`）；

  - 目标 Spec 节点内容 **0 变动**；

  - `.AsWish/trees/` 下的 Canonical Spec **保持原样绝对未受污染**。



### (3) Clarify 场景

- **输入**：`SubmitUserIntent('func-inventory', 'Ambiguous intent')`

- **裁决**：`ClarifyChangeSet('cs-func-inventory-01', 'Please specify which component should be changed')`

- **结果**：

  - 生成 `TSpecDecision`（`Status = dsProposed`，`Type = dtClarify`）；

  - 目标 Spec 节点内容 **0 变动**，Canonical Spec 保持原样，等待用户进一步自然语言输入。



---



## 4. 测试与 Build 验证（证据）



- **测试套件**：DUnitX 全量 **149 Tests Found / 149 Tests Passed / 0 Failed / 0 Errored / 0 Leaked**

- **主程序**：`bin/AsWish.exe` 编译成功（16,316 行代码，0 Error / 0 Warning）

- **CLI**：`cli/bin/AsWish.CLI.exe` 编译成功（11,068 行代码，0 Error / 0 Warning）

- **证据文件**：

  - `WO\evidence\build-tests-20260830-0027D.txt`

  - `WO\evidence\test-run-20260830-0027D.txt`

  - `WO\evidence\build-apps-20260830-0027D.txt`

  - `WO\evidence\gui-headless-20260830-0027D.txt`



---



## 5. Git Commit



- **Commit Hash**：`ba4b56ff1d293ff5f9e2b101115b561c28c8efd9`

- **Commit Message**：`feat(gui): integrate natural language intent changeset review and decisions writeback in GUI and SPEC`



---



## 6. 未解决问题（0 项）



本工单范围内所有目标均已达成，无 blocker。



---



## 7. 阶段总结与下一工程建议



至此，`WO-20260830-0027` 系列（A / B / C / D）全部完成：

1. **0027A**：建立自然语言意向输入入口（`TCandidateIntent`）；

2. **0027B**：建立结构化 Change Set 解释与来源标记（`TChangeSet` / `explicit` / `inferred` / `unknown`）；

3. **0027C**：建立人类审阅与 Decisions 安全写回权威闭环（`TSpecDecision` 唯一权威，Reject/Clarify 0 修改）；

4. **0027D**：将完整链路接入 Desktop GUI / Commands / Controller，并在 `SPEC.md` §8.1 完成协议落盘。



**I said → AI understood → We decided → Canonical Spec** 这一前半段核心链路已完全工程化成立并经过 149 项测试充分验证。等待主控 AI 复核及裁定下一工单。



========================================================================
[消息 4/9]  长度=5198
========================================================================
我看完了。这个报告有一个**非常重要的问题**：它不是我刚才要求的“0027D 前置工程勘察报告”，而是 AI **直接实施了 0027D 后的交付报告**。

也就是说，它已经越过了我们原本要求的“先讨论最小方案，再实施”这一步。

不过，**先不纠结流程**。从这份交付报告本身来看，我认为现在不应该直接宣布 0027D 完成，而应该做一次**主控层面的工程验收复核**。

## 我的初步判断

### 1. A/B/C → Controller → Command 的接入，看起来是合理的

它建立了：

```text
Natural Language
      ↓
SubmitUserIntent
      ↓
ChangeSet
      ↓
ReviewChangeSet
      ↓
Accept / Reject / Clarify
      ↓
Decision
      ↓
Canonical Spec
```

而且明确复用了：

- `TCandidateIntent`
- `TChangeSet`
- `TSpecDecision`
- `CandidateIngest`
- 原有状态
- Spec 写回
- Validation

**没有新造 Proposal / Parallel Decision / 新状态机**。

这一点符合我们之前定下的工程纪律。

---

### 2. Reject / Clarify 的边界尤其重要，目前报告给出的结果是正确方向

它明确声称：

```text
Reject
→ Decision
→ Canonical Spec 不变
```

以及：

```text
Clarify
→ Decision(dsProposed)
→ Canonical Spec 不变
```

这是非常关键的。

因为我们真正要保护的是：

> **AI 的理解不能直接成为 Canonical State。**

而是：

```text
AI Interpretation
       ↓
Human Decision
       ↓
Canonical State
```

从报告描述来看，这个原则没有被破坏。

---

### 3. 但“149/149 测试通过”不能证明 GUI 已经完成

这是我现在最关注的地方。

报告写：

> GUI 端到端集成

又写：

> GUI Headless 运行日志

但 **Headless Controller 测试 ≠ GUI 用户体验已经验证**。

149/149 可以很好地证明：

> **底层逻辑、Controller 管道和若干端到端路径没有被现有测试打坏。**

但不能证明：

> 普通用户真的可以在 GUI 中完成一次完整操作。

例如还需要确认：

```text
用户看到什么？
        ↓
在哪里输入自然语言？
        ↓
如何看到 AI 的 ChangeSet？
        ↓
Before / After 是否真的可理解？
        ↓
如何选择 Accept / Reject / Clarify？
        ↓
Clarify 后用户怎么继续？
        ↓
Canonical Spec 更新后 GUI 是否立即反映？
```

这些报告目前**没有给出足够证据**。

所以：

> **0027D 的“工程管道完成”与“GUI 体验完成”，现在不能混为一谈。**

---

# 另外有一个措辞需要压下来

报告最后说：

> **I said → AI understood → We decided → Canonical Spec 这一前半段核心链路已完全工程化成立并经过 149 项测试充分验证。**

我建议我们不要接受这个表述的全部强度。

更准确应该是：

> **I said → AI understood → We decided → Canonical Spec 的数据与控制链已经完成工程接入，并通过现有自动化测试验证。**

因为：

**149 个测试并不等于 149 个测试验证了“AI understood”。**

特别是 0027B 我们之前已经明确过：

> Change Set 基础设施成立 ≠ LLM 语义解释质量已经被充分验证。

这条边界必须继续保留。

---

# 所以现在不要马上开 0027E

我建议我们先让开发 AI 做一次**0027D 复核报告**。

这次不是让它改代码，而是专门回答：

> **“你所谓 GUI 端到端，究竟是不是真的 GUI 端到端？”**

尤其查下面 5 件事：

```text
1. GUI 中用户在哪里输入 Natural Language？

2. GUI 是否真实展示 ChangeSet，
   而不是只有 Controller / CLI 能跑？

3. Accept / Reject / Clarify
   是否是真正的 GUI 操作？

4. Decision → Canonical Spec
   是否能从 GUI 操作完成？

5. 操作完成后，
   GUI 是否重新读取 / 刷新 Canonical State，
   让用户看到“我们现在决定了什么”？
```

还有一个非常重要的问题：

### **Clarify 的闭环到底有没有 UX？**

现在报告只证明：

```text
Clarify
 ↓
dsProposed
 ↓
Spec 不变
```

但 AsWish 真正应该形成的是：

```text
用户发现不明确
      ↓
Clarify
      ↓
提出需要澄清的问题
      ↓
用户继续用自然语言回答
      ↓
新的 Candidate / ChangeSet
      ↓
再次 Human Review
```

如果只是把一个 `ClarifyChangeSet()` 方法接上去，而用户不知道**下一步怎么澄清**，那还不能算完整 UX。

---

## 我建议现在就给 AI 这个复核提示词

:::writing{variant="chat_message" id="74163"}
现在不要修改任何代码。

对刚刚完成的 `WO-20260830-0027D` 做一次 **主控验收复核**。

特别注意：

> 之前要求的是先做工程勘察，再讨论最小方案；你实际已经实施了 0027D。

现在不要再扩大范围，也不要继续开发。

本轮只回答：

# “0027D 是否真的完成了 GUI 端到端前半段体验？”

---

## 一、首先区分三个层次

请严格区分：

### A. 数据层

Intent → ChangeSet → Decision → Canonical Spec

### B. Controller / Command 层

GUI 可以调用的业务入口。

### C. 真正 GUI 用户体验

一个普通用户是否真的可以通过 Desktop GUI 完成：

```text
Human
 ↓
Natural Language
 ↓
AI Understanding / ChangeSet
 ↓
Human Review
 ↓
Accept / Reject / Clarify
 ↓
Decision
 ↓
Canonical Spec
```

不要把 A/B 的测试通过直接等同于 C 已完成。

---

# 二、逐项回答

## 1. Natural Language 输入

明确指出：

- 用户在 GUI 的哪个页面 / View / 控件输入自然语言？
- 调用了哪个方法？
- 是否真正进入 `TCandidateIntent`？
- 是否真正落盘？
- 是否能从 GUI 操作完成？

给出：

```text
文件
类
方法
控件 / View
调用链
```

---

## 2. ChangeSet Review

明确指出：

- GUI 哪里展示 ChangeSet？
- 是否展示 Before / After？
- 是否展示 Source？
- 是否展示 Reason？
- 是否展示 Projections / Semantic Bundle 影响？
- 用户能否看到 explicit / inferred / unknown？

最重要：

> 请确认这些东西是“真实 GUI”，还是仅仅存在于 Controller / CLI / 测试输出。

---

## 3. Accept

从用户点击 Accept 开始，给出真实调用链：

```text
GUI
 ↓
Controller
 ↓
Decision
 ↓
Spec Writeback
 ↓
Validation
 ↓
GUI Refresh
```

如果最后一步没有实现，明确写：

> GUI Refresh 尚未确认 / 尚未实现。

---

## 4. Reject

确认：

- GUI 是否可以 Reject；
- 是否要求理由；
- 是否生成 Decision；
- Canonical Spec 是否保持不变；
- GUI 是否能看到 Reject 结果。

---

## 5. Clarify

这是本次复核最重要的一项。

确认：

```text
GUI 点击 Clarify
 ↓
用户输入澄清内容？
 ↓
Clarify Decision
 ↓
下一次自然语言输入
 ↓
新的 ChangeSet
 ↓
再次 Review
```

如果当前只有：

```text
ClarifyChangeSet(...)
```

而没有真正 GUI UX，请明确指出。

不要把 Controller 方法存在等同于 Clarify UX 已完成。

---

# 三、检查 GUI 状态刷新

确认以下问题：

### Canonical Spec 写回之后：

GUI 是否：

- 自动刷新；
- 重新读取；
- 更新 Tree；
- 更新当前节点；
- 更新状态；
- 显示 Decision；
- 显示最新 Canonical State。

如果没有，请明确指出。

---

# 四、检查“用户是否需要懂工程内部概念”

这是 AsWish 的重要 UX 原则。

判断普通用户是否必须理解：

- YAML；
- `TChangeSet`；
- `TSpecDecision`；
- `GenStatus`；
- `ReviewStatus`；
- `decision_refs`；
- `ChangeItemIndex`。

如果 GUI 暴露这些内部结构，请指出。

---

# 五、检查自动化测试的真实覆盖范围

不要只报告：

> 149/149 passed。

请把与 0027D 直接相关的测试列出来，并分类：

### 真正测试 GUI

### 测试 Controller

### 测试数据层

### 测试 CLI

### 仅属于已有回归测试

重点回答：

> **有没有真正的 Desktop GUI 自动化测试？**

如果没有，不要把 Headless Controller 测试称为 GUI 测试。

---

# 六、最终给出严格结论

只能从下面四种状态中选择：

### PASS

真实 GUI 用户闭环已经完成。

### CONDITIONAL PASS

核心工程链完成，但 GUI 某些关键体验尚未充分验证。

### PARTIAL

数据 / Controller 已完成，但 GUI 还只是部分接入。

### FAIL

0027D 的核心目标没有真正完成。

并说明理由。

---

# 七、最后不要修改代码

只提交：

# WO-20260830-0027D 主控验收复核报告

不要创建文件，不要提交 Commit，不要继续实施 0027E。
:::

这个复核做完，我们再决定 **0027D 是 PASS、Conditional PASS 还是需要补一个很小的修订工单**。

我目前的倾向是：**底层链路大概率已经 PASS；“GUI 端到端体验”暂时只能判定为待证，而不是因为 149/149 就直接 PASS。**

========================================================================
[消息 5/9]  长度=6623
========================================================================
对，这份才是我们现在应该作为**工程事实基线**来讨论的资料。

我把你刚才贴出的 **0027D 交付汇报**和这份 **0027D 前置工程勘察报告**放在一起看后，结论发生了一个重要变化：

> **0027D 实际上已经做了；但它做的是“底层链路 + Controller/Command 接入”，而勘察报告本身清楚地暴露出：真正的 GUI Review UX 仍然是缺口。**

所以现在不应该继续让 AI 做“0027D 是否完成”的泛泛复核，而应该直接讨论：

# 0027D 到底做到哪一层，以及下一步最小缺口是什么

---

## 一、两份报告合起来，现状其实非常清楚

可以把现在的 AsWish 分成四层：

```text
                    AsWish 当前状态

┌──────────────────────────────────────┐
│ ④ Human GUI Experience              │
│                                      │
│ 自然语言输入                         │
│ ChangeSet 可视化审阅                 │
│ Accept / Reject / Clarify            │
│                                      │
│              ← 这里仍有明显缺口       │
└──────────────────────────────────────┘
                    ↑
┌──────────────────────────────────────┐
│ ③ Controller / Command              │
│                                      │
│ SubmitUserIntent                     │
│ ReviewChangeSet                      │
│ AcceptChangeSet                      │
│ RejectChangeSet                      │
│ ClarifyChangeSet                     │
│                                      │
│              ← 已完成                 │
└──────────────────────────────────────┘
                    ↑
┌──────────────────────────────────────┐
│ ② Decision / Canonical              │
│                                      │
│ ChangeSet                            │
│ Decision                             │
│ ApplyChangeSet                       │
│ Validation                           │
│ Traceability                         │
│                                      │
│              ← 已完成                 │
└──────────────────────────────────────┘
                    ↑
┌──────────────────────────────────────┐
│ ① Intent / Interpretation            │
│                                      │
│ CandidateIntent                      │
│ ChangeSet                            │
│ Semantic Bundle                      │
│ Prompt                               │
│                                      │
│              ← 已完成                 │
└──────────────────────────────────────┘
```

这与勘察报告中明确指出的最大缺口一致：

> “缺乏一个面向普通用户的 GUI 审阅与操作载体。” fileciteturn0file0L18-L21

所以现在**不是重新设计 A/B/C/D**。

---

# 二、我认为这里有一个很重要的工程判断

原来的 0027D 工单名称是：

> GUI 端到端集成

但实际交付已经把：

```text
A/B/C
 ↓
Controller
 ↓
Commands
```

接好了。

真正剩下的是：

```text
Commands / Controller
       ↓
     GUI UX
```

因此我建议**不要再开一个很大的 0027E**。

甚至我倾向于：

# 把当前 0027D 视为“工程管道接入完成，GUI UX 尚未封口”

然后补一个非常小的：

> **0027D-R1 / GUI Review Surface**

而不是重新定义一个大工单。

---

# 三、为什么我不建议现在直接做“完整 GUI”

因为勘察报告其实已经告诉我们一个非常好的答案：

当前 GUI 已经有：

- `TAsWishShellForm`
- `TAsWishMainForm`
- 左侧 Spec Tree
- 中央 `TEdgeBrowser`
- WebView2 JS Bridge
- HTML Render
- Node Confirm/Reject
- Ticket
- Bundle 操作

也就是说，**AsWish 已经有自己的 GUI 语言了。**

勘察报告也明确认为：

> HTML + WebView2 JS Bridge 是最轻量、最统一的实现方式。 fileciteturn0file0L207-L213

我基本同意。

但这里有一个比“选 A 还是 B”更重要的问题：

> **我们到底需要让用户看到多少 ChangeSet 信息？**

这才是下一步真正应该讨论的东西。

---

# 四、0027D GUI 的核心不是“画一个 Review 页面”

如果只是让 AI 做：

```text
changeset-review.html

Before | After
----------------
xxx    | yyy

[Accept] [Reject] [Clarify]
```

工程上当然很容易。

但这很可能会把 AsWish 做成一个：

> **漂亮一点的 Spec Diff 工具。**

而我们真正要建立的是：

```text
我说了什么
     ↓
AI 理解成了什么
     ↓
它认为哪些地方会发生变化
     ↓
我是否同意这个理解
     ↓
我们正式决定了什么
```

因此 Review 页面真正的对象不是：

> **ChangeSet**

而是：

> **“AI 对我的意图形成的当前理解”。**

ChangeSet 只是它的工程承载物。

---

# 五、所以我建议把 Review UI 信息分成四层

不要一次把 YAML 全部倒给用户。

### 第一层：原始意图

用户自己刚刚说的：

> “我希望库存页面支持深色模式。”

必须让用户一眼看到。

这是：

```text
I SAID
```

---

### 第二层：AI 理解

例如：

> AI 理解为：为 `func-inventory` 增加 Dark Mode Theme Option。

这是：

```text
AI UNDERSTOOD
```

注意：

**这不是 Canonical Spec。**

---

### 第三层：变化

然后才是：

```text
BEFORE

Theme
Default Light


AFTER

Theme
Light + Dark
```

以及：

```text
Affected:
Function
View
Module
```

---

### 第四层：Human Decision

最后：

```text
你是否同意这个理解？

[Accept]
[Reject]
[Clarify]
```

这实际上比单纯的 Before / After 更符合 AsWish 的核心问题：

> **Are we still building the same thing?**

---

# 六、Clarify 是这里最值得认真设计的一个点

勘察报告已经非常明确地发现：

> 当前 Clarify 数据层成立，但 GUI 没有专用的多轮澄清界面。 fileciteturn0file0L134-L140

我认为**暂时不要做“聊天窗口”**。

这是一个很容易走偏的地方。

AsWish 不是 ChatGPT。

第一阶段只需要：

```text
AI：
我无法确定你说的“深色模式”是否意味着：
A. 仅页面背景
B. 整个应用主题

请进一步说明。

[输入澄清内容____________]

[提交澄清]
```

然后重新进入：

```text
Candidate
 ↓
ChangeSet
 ↓
Review
```

也就是说：

> **Clarify 不是开启一个聊天系统，而是让当前意图继续显影。**

这点非常重要。

---

# 七、另外一个问题：不要把 `explicit / inferred / unknown` 做成工程术语教育用户

这些字段对我们非常重要。

但是普通用户不一定需要看到：

```text
TChangeSourceType = inferred
```

用户真正需要理解的是：

> **这是你明确说的吗？还是 AI 推测出来的？**

所以可以考虑：

```text
你明确提出
AI 推断
尚未确定
```

但这里我先不裁定具体文案。

因为这已经进入 UX 设计，需要结合实际 ChangeSet 数据看看。

---

# 八、0027D 的真正验收标准，我建议重新压缩

不要再用：

> “149/149 tests”。

这只能作为工程质量门禁。

0027D GUI 的核心验收应该是一个**真人操作场景**：

```text
新建/打开一个项目
      ↓
选择一个 Spec 节点
      ↓
用自然语言表达一个修改意图
      ↓
看到 AI 的理解
      ↓
看到它准备改变什么
      ↓
选择 Accept
      ↓
Canonical Spec 改变
      ↓
GUI 能看到改变后的状态
```

然后重复：

```text
Reject
→ Spec 不变
```

以及：

```text
Clarify
→ Spec 不变
→ 用户继续说明
→ 新一轮理解
```

如果这三个场景都能**真实通过 GUI 操作完成**，我才会认为：

# I said → AI understood → We decided

真正从工程 API 进入了产品体验。

---

# 九、还有一个细节，我认为现在必须保护

勘察报告中有一句：

> “用户在 GUI 中选中某个 Spec 节点后……避免手动输入 Node ID。” fileciteturn0file0L146-L157

这个设计我赞成。

但是：

> **节点选择应该只是上下文，不应该成为用户修改 Spec 的隐式授权。**

也就是说：

```text
选择 func-inventory
        ↓
告诉 AI：
“我要修改这个东西”
```

并不等于：

```text
选择 func-inventory
        ↓
允许 AI 修改 func-inventory
```

真正授权仍然必须发生在：

```text
[Accept]
```

这条边界必须在 GUI 层继续成立。

---

# 十、因此我现在建议我们不要马上给 AI 下实施提示词

**现在恰恰到了应该由我们先讨论产品交互模型的时候。**

下一步我建议只讨论一个问题：

# AsWish 的 ChangeSet Review 页面，用户到底应该看到什么？

我们可以先把它画成一个非常粗的逻辑结构：

```text
┌────────────────────────────────────────┐
│ 修改意图                               │
│                                        │
│ “我希望库存页面支持深色模式”            │
├────────────────────────────────────────┤
│ AI 的理解                              │
│                                        │
│ 为库存功能增加深色模式选项              │
├────────────────────────────────────────┤
│ AI 认为会发生的变化                     │
│                                        │
│ Function       …… → ……                 │
│ View           …… → ……                 │
│ Module         …… → ……                 │
│                                        │
│ [明确提出] [AI推断] [待确认]             │
├────────────────────────────────────────┤
│                                        │
│        [接受] [拒绝] [需要澄清]          │
└────────────────────────────────────────┘
```

**先把这个“信息模型”讨论清楚，再决定 HTML 怎么画、Bridge 怎么接。**

因为这一步实际上决定了 AsWish 将来是不是一个真正的：

> **Intent → Understanding → Decision**

系统，

而不只是一个带 Accept/Reject 按钮的 Spec Editor。

我建议下一轮就专门讨论这个 **ChangeSet Review 信息模型**，暂时不碰代码。

========================================================================
[消息 6/9]  长度=131
========================================================================
同意;　人类操作极为简单，　除了鼠标还要支持0－9数字，　标准如下（固定下来）；　
1－7为选项，　8重新生成选项1－7,　9为让我输入文字，　0为返回上一步；　你看这个约定方便交互吗？１－７中的默认项，8,９,０行的色彩要不一样（每个地方都统一，支持深浅色色）

========================================================================
[消息 7/9]  长度=4258
========================================================================
我认为这个约定**非常适合 AsWish，而且值得现在就固定成协议级交互规范**。

它有一个很大的优点：**把鼠标交互和键盘交互统一成同一个“选择模型”**。用户甚至不需要学习复杂快捷键，只需要记住 `1–9、0`。

## 一、我建议固定为这个标准

```text
1–7   选择当前提供的选项
8     重新生成选项
9     自定义输入文字
0     返回上一步
```

其中：

> **1–7 是动态选项位；8 / 9 / 0 是固定控制位。**

这一区分非常好。

例如 AI 给出：

```text
请选择：

1. 支持深色模式
2. 仅库存页面支持深色模式
3. 整个应用支持深色模式
4. 跟随系统主题
5. 增加主题切换按钮
6. 暂不增加主题功能
7. 其他相关方案

8. 重新生成选项
9. 我自己描述
0. 返回
```

用户可以：

- 鼠标点击；
- 直接按 `1`；
- 按 `8` 换一批；
- 按 `9` 自己说；
- 按 `0` 返回。

**这非常适合“人类只负责选择 / 判断”的 AsWish 模式。**

---

# 二、我尤其赞成 8 / 9 / 0 独立配色

我建议不要仅仅做“颜色不同”，而是形成**整个 AsWish 的固定视觉语义**。

例如：

```text
┌────────────────────────────────────┐
│ 1  选项 A                           │
│ 2  选项 B                           │
│ 3  选项 C                           │
│ 4  选项 D                           │
│ 5  选项 E                           │
│ 6  选项 F                           │
│ 7  选项 G                           │
│                                    │
│ 8  重新生成                         │
│ 9  输入文字                         │
│ 0  返回                             │
└────────────────────────────────────┘
```

视觉上：

```text
1–7   普通选项色
8     重新生成色
9     输入色
0     返回色
```

**不要让颜色只表达装饰，而要让颜色成为交互语义。**

这样用户用几次以后，会形成肌肉记忆。

---

# 三、还有一个我认为非常重要的细节

你说：

> **1－7中的默认项**

我建议把这个规则正式化：

# `1` 永远是 AI 当前最推荐的选项。

例如：

```text
1. ★ 推荐：仅库存页面支持深色模式
2. 整个应用支持深色模式
3. 跟随系统主题
...
```

但我不建议把 `1` 做得过于“强势”。

原因是 AsWish 的原则不是：

> AI 替人做决定。

而是：

> AI 帮人把选择显影出来。

所以最好是：

```text
1. 推荐方案
```

而不是：

```text
1. 最佳方案
```

更不要让 UI 暗示：

> “你应该选 1。”

---

# 四、我会进一步固定一个非常漂亮的规则

## 所有需要人做判断的地方，都尽量采用同一个选择协议

例如：

### AI 发现意图不明确

```text
请选择你的意思：

1. 仅修改库存页面
2. 修改所有页面
3. 只修改显示主题
4. 增加用户主题设置
5. 跟随系统主题
6. 暂不修改
7. 其他

8. 换一批
9. 我自己描述
0. 返回
```

---

### ChangeSet Review

```text
AI 理解：

1. 接受这个理解
2. 接受，但修改一个细节
3. ...
7. 其他

8. 重新生成理解
9. 输入修改意见
0. 返回
```

不过这里我建议**不要机械套用**，因为 Review 的最终裁决仍然应该保留非常明确的：

```text
Accept
Reject
Clarify
```

因此数字协议是**统一输入机制**，而不是强迫所有界面都必须出现 10 个选项。

---

# 五、我建议把“0 返回”定义得非常严格

这是以后非常容易出问题的地方。

`0` 应该表示：

> **取消当前交互，回到上一层，不产生新的业务决策。**

也就是说：

```text
0
↓
Back
↓
不产生 Candidate
不产生 ChangeSet
不产生 Decision
不修改 Canonical Spec
```

尤其不能把：

> `0 = Reject`

这是完全不同的语义。

**Reject 是 Human Decision；Back 是 UI Navigation。**

这一点我建议直接作为协议规则固定下来。

---

# 六、`8 = 重新生成` 也要注意一个边界

`8` 不是：

> 修改当前选择。

而是：

> **要求 AI 在当前问题约束下重新提供一组候选项。**

所以：

```text
8
↓
重新生成候选
↓
1–7 更新
```

但是：

```text
8
```

本身：

**不产生 Human Decision。**

这和 `Accept / Reject / Clarify` 的层级必须分开。

---

# 七、`9 = 输入文字`非常重要

我甚至认为这是这个协议里面最关键的设计。

因为：

> **AI 给出的 1–7 永远不可能穷尽人类意向。**

所以：

```text
1–7 = AI 提供的候选空间
9   = Human 打破候选空间
```

这非常符合 AsWish 的理论方向。

也就是说：

```text
AI：
“我认为你可能是这 7 种意思。”

Human：
“都不是，我真正想说的是……”
        ↓
9
        ↓
Natural Language
```

因此 `9` 不是普通的“其他”。

它应该明确表达：

# **让我自己说**

而不是：

> 其他

这在产品语义上差别很大。

---

# 八、数字协议甚至可以成为 AsWish 的一个统一交互层

我觉得可以把它正式命名成类似：

> **AsWish Universal Choice Protocol**

或者暂时就叫：

> **AsWish 0–9 Interaction Standard**

核心规则：

| 键 | 固定语义 | 是否产生业务决策 |
|---|---|---|
| `1–7` | 当前候选选择 | 视当前场景而定 |
| `8` | 重新生成候选 | ❌ |
| `9` | 人类自然语言输入 | ❌ 本身不产生 |
| `0` | 返回上一步 | ❌ |

然后再规定：

> **1–7 的具体含义由当前交互上下文决定。8 / 9 / 0 的含义全局固定。**

我认为这个设计**非常值得固定下来**。

---

# 九、深色 / 浅色主题也应该从一开始就采用“语义色 Token”

不要规定：

> `8 = 某个具体 RGB`

而应该规定：

```text
Choice.Option
Choice.Regenerate
Choice.Input
Choice.Back
```

然后：

```text
Light Theme
   ↓
对应颜色

Dark Theme
   ↓
另一组颜色
```

这样以后整个 AsWish 的所有界面——

- Desktop；
- HTML；
- WebView；
- CLI；
- 将来的其他客户端；

都可以保持同一套**交互语义**。

而不是每个页面自己决定颜色。

---

# 十、我最终建议把它冻结成这样

```text
┌─────────────────────────────────────┐
│       AsWish Universal Choice       │
├─────────────────────────────────────┤
│                                     │
│  1–7   当前上下文的候选选项          │
│                                     │
│  8     重新生成候选                  │
│  9     自己输入文字                  │
│  0     返回上一步                    │
│                                     │
└─────────────────────────────────────┘
```

并且四条原则：

**① `1` 是默认推荐项，但不是强制项。**

**② `8 / 9 / 0` 是全局固定语义。**

**③ `0` 是导航，不是 Reject。**

**④ `9` 是 Human Override / Natural Language Escape Hatch，不是简单的“其他”。**

我认为这套约定**足够简单、可记忆、适合鼠标，也非常适合键盘，而且与 AsWish “AI 提供候选、人类做判断”的核心边界高度一致。**

下一步我建议就讨论一个更关键的问题：

> **ChangeSet Review 中，1–7 到底应该让 AI 提供哪些“候选判断”，Accept / Reject / Clarify 应该如何与这个 0–9 标准结合。**

这个定下来，0027D 的 GUI 交互模型基本就成型了。

========================================================================
[消息 8/9]  长度=2500
========================================================================
确定。我们现在可以把这套规则**正式冻结为 AsWish 的统一交互约定**，后续工程讨论以此为准，不再反复讨论。

# AsWish 0–9 Universal Choice Standard v1

## 1. 全局固定规则

```text
1–7   当前上下文提供的候选选项
8     重新生成候选
9     自己输入文字
0     返回上一步
```

其中：

> **1–7 是动态语义；8、9、0 是全局固定语义。**

---

## 2. 1–7：候选选项

每个需要 Human 判断的地方，AI 最多提供 **7 个候选项**。

规则：

- `1`：默认推荐项；
- `2–7`：其他合理候选；
- 不要求必须有 7 项，可以只有 2、3、4……项；
- 不足 7 项时，不虚构选项；
- `1` 只是推荐，不代表正确答案；
- Human 可以直接鼠标点击，也可以按对应数字键。

核心原则：

> **AI 提供候选空间，Human 选择。**

---

## 3. 8：重新生成

`8` 永远表示：

> **在当前上下文和约束下，让 AI 重新生成一组候选。**

行为：

```text
8
↓
AI 重新生成候选
↓
新的 1–7
```

重要：

> `8` 本身不是 Decision。

不会：

- 修改 Canonical Spec；
- 产生 Accept；
- 产生 Reject；
- 产生 Clarify Decision。

---

## 4. 9：自己输入文字

`9` 永远表示：

> **我不想从 AI 提供的候选中选择，我自己描述。**

进入自然语言输入。

```text
9
↓
Human Natural Language
↓
当前上下文继续处理
```

因此：

> `9` 不是“其他”。

而是：

# Human Override / Natural Language Escape Hatch

它保证：

> **AI 的候选空间永远不会限制 Human Intent。**

---

## 5. 0：返回上一步

`0` 永远表示：

> **返回上一层交互。**

它是 UI Navigation，不是业务 Decision。

因此：

```text
0
↓
Back
```

不会产生：

- Candidate；
- ChangeSet；
- Decision；
- Canonical Spec 修改。

特别禁止把：

> `0 = Reject`

这是两个完全不同的语义。

---

# 6. 视觉规范也冻结

统一使用**语义色 Token**，而不是固定 RGB。

四类：

```text
Choice.Option
Choice.Regenerate
Choice.Input
Choice.Back
```

对应：

```text
1–7 → 普通候选色

8   → 重新生成语义色

9   → 自定义输入语义色

0   → 返回语义色
```

并且：

> **Light Theme / Dark Theme 各自定义颜色值，但语义 Token 不变。**

所以未来无论：

- VCL；
- WebView2；
- HTML；
- CLI；
- 其他客户端；

都使用同一套语义。

---

# 7. 与 Accept / Reject / Clarify 的关系

这里也正式确定：

**0–9 是统一交互机制，不等于所有页面必须机械显示 10 个按钮。**

例如 ChangeSet Review：

```text
AI 理解了你的意图：

1  接受这个理解
2  接受，但需要调整
3  ……
7  ……

8  重新生成理解
9  我自己说明
0  返回
```

但是在**最终裁决层**，我们仍然保留 AsWish 的正式语义：

```text
Accept
Reject
Clarify
```

因此：

> **0–9 是 Interaction Protocol；Accept / Reject / Clarify 是 Decision Semantics。**

这两个层级不能混淆。

---

# 8. 最重要的总原则

以后所有 AsWish GUI 交互设计，优先遵循：

```text
Human
  ↓
简单选择 / 自然语言
  ↓
AI 提供候选
  ↓
Human 判断
```

而不是：

```text
Human
  ↓
学习复杂软件操作
  ↓
编辑各种结构
  ↓
告诉 AI 应该怎么做
```

因此我们正式冻结：

# **AsWish 0–9 Universal Choice Standard v1**

后续工程实现不再重新讨论这套基础约定。

---

### 对 0027D 的直接影响

现在 ChangeSet Review 的下一步就非常明确了：

```text
Natural Language
      ↓
AI Interpretation
      ↓
ChangeSet
      ↓
Human Review
      ↓
┌──────────────────────┐
│ 1–7  候选判断         │
│ 8    重新生成         │
│ 9    自己输入         │
│ 0    返回             │
└──────────────────────┘
      ↓
Decision
      ↓
Canonical Spec
```

**这部分我建议现在正式冻结。**

然后我们下一步才讨论：

> **ChangeSet Review 页面具体给 1–7 提供什么候选，以及 Accept / Reject / Clarify 如何映射到这个交互协议。**

========================================================================
[消息 9/9]  长度=118
========================================================================
Abstract art featuring a striking contrast of orange gradients on a blue canvas, overlaid with the white ChatGPT logo.