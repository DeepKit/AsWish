# AsWish Product Identity

> 当前产品身份的权威说明（Single Source of Truth）。
> 任何 AI 或开发者接手 AsWish 工程，必须先读本文，再读 [ASWISH-DOCUMENTATION-GOVERNANCE.md](ASWISH-DOCUMENTATION-GOVERNANCE.md)。
> 本文件由老板裁定维护；其他文件描述产品身份时必须与本文一致，冲突时以本文为准。

---

## 1. What AsWish Is

AsWish 是一个开放的、免费的、理论驱动的实证工程系统，位于：

```text
Human  ↔  AI Coding Agent  ↔  Software Implementation
```

之间的**开放工程层**。

它解决的核心问题是：

> **Are we still building the same thing?**
> **Where did the difference enter?**

核心不是"Spec 是否正确"，而是：**人类意向、人机共同理解、表示、Agent 执行和最终实现之间发生了什么变化，以及这些变化能否被看见、追踪和由人判断。**

当前主要形态：Windows Desktop（Delphi/VCL + WebView2）/ Headless CLI / Open Source，以 `.AsWish/` 作为项目级协议工作空间。

## 2. What AsWish Is Not

禁止在任何当前有效文件中把 AsWish 表述为以下任何一种：

- Spec Tool / Spec Editor / WYSIWYG Spec Editor；
- AI Requirement Tool / 普通需求管理系统；
- AI Coding Tool / 代码生成平台；
- IDE / Coding Agent / LLM 本身；
- 帮助 AI 写代码的普通需求管理工具；
- 企业流程平台；
- Agent 编排器（orchestrator）。

这些表述不足以表达项目定位，均属旧 DeepSpec 时代的认知残留。

## 3. Product Hierarchy

正式产品层级。**这不是四个独立产品，而是同一个理论—产品—工程体系的不同层级：**

```text
Level 0
Difference Monism          理论母体
        ↓
Level 1
As We Wish                 理论 / 方法层：人机共同理解的述事 / 建构机制
        ↓
Level 2
As I Wish                  产品概念：面向真实使用者的核心追问
        ↓
Level 3
AsWish                     工程实现 / 开源实现名称（本仓库）
        ↓
Project Workspace
.AsWish                    项目级可追踪工作空间 / 协议载体
```

解释链：

```text
Theory
   ↓
Human-AI co-construction
   ↓
Product concept
   ↓
Engineering implementation
   ↓
Project workspace / protocol
```

禁止使用降维版本（如 `Theory → Spec Tool → Code`）描述整体关系。

## 4. Difference Monism（Level 0）

理论母体，中文"差异一元论"。

核心起点：

> **差异 + 非任意约束性构成最低结构起点。**

相关推导链：Difference → Structure → Boundary → Inheritance Trace → Entity → Law / Causality → Emergence → Temporary Stability → Internality → …

与 AsWish 最相关的理论接口：`distinguishability`、`non_arbitrary_constraint`、`structure`、`boundary`、`inheritance_trace`。

必须保持既有理论强度。两条纪律：

> **DM 是存在条件论，不是宇宙生成论。**
> **DM 是可受损、可修订、可缩限的研究纲领。**

不得在产品文件中为营销而增强理论主张。理论归属细节见 [NOTICE](NOTICE) 与 [docs/理论确权清单-v1.md](docs/理论确权清单-v1.md)。

## 5. As We Wish（Level 1）

理论 / 方法层。**它不是当前 Desktop 软件的产品名称。**

它代表：人类与 AI 在问题显影、决策确认、表示、建构过程中形成共同理解的述事 / 建构机制。

- **I Wish**：我的初始意向。
- **We Wish**：人与 AI 经过沟通、显影、确认、建构之后形成的共同理解。

```text
I Wish
   ↓
AI interprets
   ↓
We clarify
   ↓
We decide
   ↓
We build
```

重点不是"AI 猜中我的愿望"，而是：**人与 AI 如何逐渐形成"我们现在到底在做什么"的共同理解。**

与 CTF 的关系：CTF 主张——需求的形式和粒度是人机协作的建构产物，必须可追溯，且始终可谬。CTF 当前主张强度保持 C2；涉及正式理论归因时必须使用完整限定词 **CTF Semantic Bundle**，不得扩大 CTF 的理论主张。

## 6. As I Wish（Level 2）

面向真实使用者的产品概念。它表达：

> **经过显影、确认、共同建构、视觉确认和 Agent 开发之后，最终得到的东西，是否仍然是"我真正想要的东西"。**

As I Wish 不是"AI 按我的愿望写代码"。它关注的主链：

```text
I Wish
   ↓
Problem Manifestation
   ↓
Decision Confirmation
   ↓
Shared / Current Understanding
   ↓
Representation
   ↓
Visual Baseline
   ↓
Agent Development
   ↓
Actual Software
   ↓
Implementation Evidence
   ↓
Difference
   ↓
Human Confirmation
   ↓
Revision
```

产品价值不是"生成 Spec"，而是帮助人类保持对**自己究竟在构建什么**的可见、可确认、可追踪状态。

## 7. AsWish（Level 3）

实际工程产品 / 开源实现名称（本仓库，`D:\_Progs\02Business\AsWish`）。

工程使命：

> **把 As I Wish 的核心思想变成任何开发者可以下载、运行、使用、检验、质疑和复现的真实工程系统。**

AsWish 不应该成为：IDE、Coding Agent、LLM 本身、传统 Spec 编辑器、企业流程平台。

它应该尽可能成为：**位于 Human ↔ AI Coding Agent ↔ Software Implementation 之间的开放工程层**。

## 8. .AsWish（Project Workspace）

`.AsWish` 是项目级工作空间 / 协议载体。**它不是第五个产品。**

它表示：一个 AsWish 项目在实际工程中的可追踪工作空间，承载实际项目运行所需的 protocol、state、decisions、evidence、representations、render、bundle、ingest、validation 等已有工程机制。

不得重新发明平行协议体系。协议权威来源：[SPEC.md](SPEC.md) 与 [protocol/](protocol/)。

## 9. Core Research Question

```text
Are we still building the same thing?
Where did the difference enter?
```

这两个问题贯穿全部产品、工程与研究活动，优先于任何功能性问题。

## 10. Core Workflow

核心主链：

```text
Problem Manifestation
        ↓
Decision Confirmation
        ↓
Co-construction
        ↓
Representation / Specification
        ↓
Visual Baseline
        ↓
Agent Development
        ↓
Actual Implementation
        ↓
Implementation Evidence
        ↓
Difference
        ↓
Human Confirmation
        ↓
Revision
```

对外压缩口径：

> **Manifest → Confirm → Construct → See → Build → Verify**
> **显影 → 确认 → 建构 → 看见 → 生产 → 验证**

不要机械要求每个文件完整重复这条链；按文件职责选择需要表达的部分。

## 11. Human / AI Boundary

### Human 负责

- 意向；
- 判断；
- 决策；
- 接受 / 拒绝差异；
- 最终确认。

### AI 可以

- 发现；
- 提问；
- 解释；
- 生成；
- 建议；
- 转换；
- 检查；
- 提示差异。

### 两条边界

> **AI 不拥有最终决策权。**
> **人类不直接编辑 Spec。** 人类使用自然语言表达和确认。

## 12. Difference

Difference 是当前产品最重要的研究对象之一。

- 不要把它简单定义成"Spec 和代码不同"。
- 不要为了工程方便提前给它一个未经裁定的强定义。
- 当前可用的表述：**Difference 是在人类意向 / 共同理解 / 表示 / Agent 执行 / 实际实现之间发生的、值得被看见和判断的变化。** 具体操作定义尚待后续实验和研究确定。

### Difference ≠ Error

```text
Difference
    ↓
Human reviews
    ↓
Accept / Reject / Uncertain
```

一个实现可能与此前理解不同，但人类认为"这样更好"——这仍然是有效的研究结果。

AsWish 追求的不是 Zero Difference，而是：

> **Difference made visible, traceable, and judgeable.**

## 13. Vision

当前愿景（禁止写成"成为最好的 Spec Tool / AI Coding Platform"）：

> **让理论真正进入真实世界，形成一个可以被真实开发者使用、产生工程证据、接受第三方检验、发现失败和反例，并反过来推动理论修正的开放工程系统。**

```text
Theory
 ↓
Protocol
 ↓
Reference Implementation
 ↓
Real Use
 ↓
Evidence
 ↓
Critique
 ↓
Theory Revision
```

核心原则：

> **真实使用证据 > 功能数量**
> **第三方反馈 > 内部自嗨**
> **理论可证伪 > 理论包装**
> **传播一个问题 > 宣传一堆功能**

## 14. Open Source Purpose

开源不是单纯"源码免费"，真正目的：

> **让第三方可以下载、运行、使用、检查、复现、质疑这个理论工程化过程。**

开源的核心传播不是 "Try my tool."，而是：

> **Test my claim.**

伴随的核心问题：**Are we still building the same thing?** 与 **Where did the difference enter?**

## 15. First-Stage Users

```text
第一圈   AI Coding 重度用户（Codex / Claude Code / Cursor / Gemini CLI / 其他 Agent 用户）
第二圈   独立开发者 / 小团队
第三圈   产品经理、技术负责人、AI 软件工程研究者
第四圈   企业团队
```

当前：**不要为了企业市场增加企业级复杂度。**

## 16. First-Stage Goals

第一阶段重点不是：SaaS、收费、企业销售、用户规模、功能数量。

第一阶段真正目标：

> **让陌生开发者能够下载、运行、完成第一次真实实验，并愿意把 AsWish 带入自己的真实开发工作。**

优先路径：

```text
First User → First Experiment → First Real Project → First Difference
→ First Case → First Critique → More Experiments
```

重要指标不是 GitHub Star 数量，而是：

- 完成过真实实验的人数；
- 实际使用 AsWish 的真实项目数量；
- Difference 案例；
- 用户主动形成的 Case；
- 用户主动提出的失败；
- 第三方复现实验。

### 下载即用原则

第一阶段优先保持：**Download → Run → Create Project → Start**（Windows Desktop / Local-first）。不强制：注册、登录、云端账号、SaaS Workspace、团队权限、SSO、企业部署。未来是否增加这些能力，由真实使用证据决定。

## 17. Strategic Non-Goals

- 不做商业化第一阶段的推进（SaaS / 收费 / 企业销售）；
- 不替代任何 Coding Agent，不做 IDE；
- 不追求 Zero Difference；
- 不为营销增强理论主张；
- 不重新发明平行协议体系；
- 不为功能数量牺牲真实使用证据。

## 18. Relationship to AI Coding Agents

AsWish 允许并欢迎外部 Agent 存在：Codex、Claude Code、Cursor、Gemini CLI 及其他 Agent。

> **AsWish 不需要替代这些 Agent。**

AsWish 的边界是：告诉 Agent 应该做什么、已经确认的东西长什么样，并在 Agent 完成后用实现证据支持人类验证"做出来的还是不是那个东西"。开发执行本身始终由用户选择的 Agent / CLI / IDE 承担。

## 19. Relationship to Spec

Spec 在 AsWish 中的性质：**当前被人类接受、具有来源与证据、允许未来被推翻的共同规格状态**——traceable、reviewable、fallible。

Spec 不是目的，是主链中的一环（Representation / Specification → Visual Baseline → Agent Development → … → Difference → Revision）。因此：

- AsWish 需要 Spec，因为主链需要一个可追踪、可审阅、可谬的共同理解载体；
- AsWish 不只是 Spec Tool，因为 Spec 之外还有：问题显影、决策确认、视觉基线、Agent 交付、实现证据、差异裁决与修订闭环。

### 所见即所得（WYSIWYG）的正式含义

全仓必须消除旧理解。AsWish 所说的 WYSIWYG **不是** "WYSIWYG Spec Editor"，**不是**人类直接编辑 Spec。真正含义：

> **开发前，人类与 Agent 沟通、确认时所看到的视觉对象 / 表示，与开发后实际软件产生的视觉 / 实现结果之间，应该能够进行可验证的对应与差异检查。**

```text
Before: Human + Agent understanding
        ↓
Visual / Representation Baseline
        ↓
Development
        ↓
Actual Software
        ↓
Evidence
        ↓
Compare
```

## 20. Theory Attribution Rules

严格保持现有主张强度（权威细节见 [NOTICE](NOTICE) 与 [docs/理论确权清单-v1.md](docs/理论确权清单-v1.md)）：

| 项 | 纪律 |
|---|---|
| Difference Monism | 按理论母库现有正式表述；存在条件论，非宇宙生成论 |
| ASTO | 按现有正式定义 |
| ODD | 按现有正式定义 |
| PFM | Problem Manifestation Methodology |
| CTF | 必须使用完整限定词 **CTF Semantic Bundle**（跨投影绑定场景）；当前主张强度保持 C2 |
| fog_state | 待确权工程构造 |
| invariants | 弱锚定 / 待确认 |
| Wayfinder / Grill-me | 外部实践启发，不称为原创 |
| 一般纪律 | 不把外部实践启发说成原创；不为产品宣传增强理论主张；不自行创造新的理论归属 |

若仓库旧文本与理论母库冲突：不自行决定理论内容，标记冲突并依据现有正式材料统一。

---

## 传播顺序（对外文件适用）

官网、README、Release、博客、社交媒体、案例等传播文件遵循：

```text
现实问题 → 真实实验 → 工程方法 → 理论
```

第一层面向普通 AI Coding 用户：*AI 明明把代码写出来了，为什么做出来的不是我们想要的东西？*
第二层面向软件工程：Problem Manifestation / Decision Confirmation / Visual Baseline / Implementation Evidence / Difference。
第三层才介绍：Difference Monism / CTF / PFM / ASTO / ODD。
