# AsWish 产品功能与愿景蓝图

> **English title**: Product Capability & Vision Blueprint
> **版本**：v1.0
> **日期**：2026-08-30
> **产品**：AsWish
> **产品形态**：Delphi/VCL Desktop + Headless CLI + Open Specification Protocol
> **许可证**：Apache-2.0（产品/协议开源边界以正式发布包为准）
> **状态**：当前产品功能与愿景基线
>
> **与既有文档的关系**：
> - 产品身份与层级的权威定义见根目录 [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md)；本文与其冲突时以该文件为准
> - 战略口径见历史文档 `DeepSpec-战略定稿-v1.md`（免费/付费边界、市场楔子、进入第二层门槛）
> - 路线层次见历史文档 `DeepSpec-三层产品路线-v1.md`（需求可视化 → 需求所见即所得 → CLI 实现）
> - 理论归属与确权状态见 `理论确权清单-v1.md`（含 fog_state 待确权口径）
> - 方法论见 [`CTF.md`](CTF.md)；历史方法论全文见 `DeepSpec-CTF方法论-v2.1.md`；Wayfinder 外部启发见 `wayfinder-对DeepSpec的启发.md`（历史讨论稿）
> - 工程基线以 [`../SPEC.md`](../SPEC.md)（v1.2-draft）为准

---

## 一、产品一句话

AsWish 让人类与 AI Agent 在开发前看见、确认同一个软件应该是什么；开发后再验证，做出来的是否还是那个东西。

更完整的产品定义：

AsWish 是 AI 原生软件开发的 **Specification Control Layer（规格控制层）**：它把模糊问题显影、关键决策确认后的共同理解固化为可追溯的规格，以视觉化对象交给开发 Agent，并在开发完成后用真实实现证据验证规格是否仍然成立。

### 产品层级（正式口径）

AsWish 不是一个孤立产品，而是同一个理论—产品—工程体系的 Level 3 层：

```text
Difference Monism   理论母体
        ↓
As We Wish          理论 / 方法层：人机共同理解的述事 / 建构机制
        ↓
As I Wish           产品概念：最终得到的是否仍然是我真正想要的
        ↓
AsWish              工程实现（本文档描述的对象）
        ↓
.AsWish             项目级可追踪工作空间 / 协议载体
```

层级定义、核心研究问题（Are we still building the same thing? / Where did the difference enter?）、人机边界与 Difference 战略地位的权威表述见 [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md)，本文不复述。

---

## 二、AsWish 不是什么

AsWish 不定位为：

- PRD 生成器；
- 普通需求管理系统；
- WYSIWYG Spec 编辑器；
- AI IDE；
- Coding Agent；
- 聊天机器人；
- 代码生成平台；
- 单纯 UI 截图比对工具；
- 取代 Cursor / Codex / Claude Code / 其他 Agent 的主开发环境。

AsWish 的位置是：

> 位于"人类意图"和"Agent 执行"之间，并向后延伸到"成品验证"的规格控制层。

---

## 三、AsWish 要解决的根问题

AI Coding 带来的核心变化不是"代码写得更快"这么简单，而是：

> **软件生产速度开始超过人类检查需求理解和实现偏差的速度。**

传统流程：

```text
需求 → 文档 → 开发 → 代码 → 人工验收
```

AI 原生开发逐渐变成：

```text
自然语言 → Agent 理解 → Agent 规划 → Agent 编码 → Agent 修改 → Agent 再编码
```

问题由此变成：

> **人在什么时候真正确认过"我们到底要做什么"？**
> **开发完成以后，做出来的到底是不是前面确认的那个东西？**

AsWish 针对的就是这两个断口。

---

## 四、核心产品闭环

AsWish 的完整主链：

```text
① 问题显影
↓
② 决策确认
↓
③ 规格建构
↓
④ 视觉确认
↓
⑤ Agent 开发
↓
⑥ 成品验证
↓
⑦ 证据回流
```

压缩成一句话：

```text
显影 → 确认 → 建构 → 看见 → 生产 → 验证
```

---

## 五、第一环：问题显影

### 5.1 目的

在进入正式规格之前，先处理：

- 模糊需求；
- 说不清的问题；
- 互相矛盾的表达；
- 弱信号；
- 规格断口；
- 证据不足；
- 当前未知。

这一层对应 **PFM** 的核心思想：

> 让说不清的问题，变得可说、可见、可承接。

### 5.2 AsWish 中的表现

项目材料经过：

```text
scan → ingest → generate
```

形成初步规格。

对于无法确定的内容：

```text
clear / misty / foggy / unknown_unknowns
```

等机制用于表达当前不确定状态。

> 注意：fog_state 当前属于 AsWish 的工程构造，理论归属继续保持"待确权"口径（详见 `理论确权清单-v1.md`）。

---

## 六、第二环：决策确认

### 6.1 核心问题

问题显影之后，真正的困难通常不是"AI 不会生成"，而是：

> **哪些关键决策其实还没有确认？**

因此 AsWish 不追求让 AI 一次性猜完整，而是：

> 找到当前最关键的未决断口，一次解决一个。

### 6.2 与外部 Wayfinder / Grilling 的关系

AsWish 可以吸收外部实践中的：

- frontier；
- fog of war；
- 一次一个决策；
- 代码优先查证；
- 人类确认；

等工作方式。

但 AsWish 的产品机制不等于 Wayfinder，也不把其概念强归为一元论理论。

AsWish 自己的核心表达是：

```text
Decision Confirmation
```

即：

```text
发现未决断口 → 提供证据 → 提出当前判断/选项 → 人类确认 → 继续下一个断口
```

---

## 七、第三环：规格建构

这是 AsWish 的核心产品层。

### 7.1 四投影

AsWish 使用四个核心投影：

```text
Function / Module / View / Data
```

它们不是四份互相独立的需求文档，而是：

> 同一需求在行为、架构、界面、数据四个维度上的投影。

### 7.2 Semantic Bundle

跨四投影描述同一个事项时，通过：

```text
CTF Semantic Bundle
```

进行绑定。

> 禁止另建一套跨投影关系系统。

### 7.3 Spec 的性质

AsWish 中的 Spec 不是永久真理，而是：

> 当前被人类接受、具有来源与证据、允许未来被推翻的共同规格状态。

因此它具备：

```text
traceable；
reviewable；
fallible。
```

---

## 八、第四环：视觉确认

这是 AsWish 区别于传统 Spec 工具的关键产品能力之一。

### 8.1 不是"编辑 Spec"

人类不直接修改 YAML、节点或 View Tree。人类通过自然语言表达：

- "登录页应该先显示账号，再显示验证码。"
- "提交按钮放到页面底部。"
- "这个页面不应该出现删除按钮。"

AsWish 根据现有 CandidateIngest / Decisions 机制形成新的规格判断。

### 8.2 View Spec 必须能够被"看见"

View Tree 不应只告诉 Agent"页面有一个按钮"，而应该进一步形成：

> 开发前可以直接看到的软件视觉对象。

即：

```text
View Spec → Visual Renderer → Visual Preview
```

这个 Preview 是规格的可观察结果，不是孤立设计稿。

### 8.3 Visual Baseline

当人类确认"这就是我们准备开发的样子"时，AsWish 保存：

```text
Accepted Visual Baseline
```

它与：

```text
View Spec；
Spec snapshot；
relevant semantic bundle；
Human Decision；
```

形成可追溯关联。

---

## 九、第五环：Agent 开发

AsWish 不自己成为 Coding Agent，而是将：

```text
Accepted Spec + View Spec + Visual Baseline + Relevant Decisions + Evidence
```

交给用户选择的 Agent / CLI / IDE。

因此 AsWish 的边界是：

> 告诉 Agent 应该做什么，以及已经确认的东西长什么样。

而不是：

> 自己接管整个开发环境。

---

## 十、第六环：成品验证

这是"开发所见即所得"的真正终点。

开发完成后，得到：

```text
Implementation Evidence
```

第一阶段最重要的形态就是：

- 实际软件截图；
- 实际页面状态截图；
- 必要时多个交互状态的截图。

然后：

```text
Accepted Visual Baseline → Actual Implementation → Visual Comparison
```

比较关注：

- **Structural Match**：页面、区域、组件、状态、主要层级是否一致。
- **Semantic Match**：界面表达的功能与交互含义是否一致。
- **Visual Match**：布局、位置、层级、主要视觉结构是否一致。

> Pixel-perfect 不是第一阶段硬门槛。

---

## 十一、视觉差异不是自动裁决

AsWish 发现"前后不一致"不意味着"开发错误"，因为开发者可能有正当理由进行修改。

因此：

```text
Difference → Human Review → Existing Decisions → Accepted / Rejected
```

仍由人类做最终裁决。

---

## 十二、第七环：证据回流

AsWish 的最终价值不只是"检查页面"，而是逐渐形成：

```text
问题 → 决策 → 规格 → 开发 → 成品 → 验证 → 差异 → 新决策 → 新规格
```

这形成：

```text
Specification Feedback Loop
```

> 规格不是静态文档，而是一个可以接受现实反作用的对象。

---

## 十三、产品功能架构

AsWish 的功能可以分为七层：

```text
Layer A  Problem Manifestation      问题显影
Layer B  Decision Confirmation      决策确认
Layer C  Specification Construction 规格建构
Layer D  Visual Specification       视觉规格
Layer E  Agent Handoff              Agent 交付
Layer F  Implementation Verification 成品验证
Layer G  Evidence / Provenance       证据与追溯
```

底层统一由：

```text
.AsWish/
  YAML Schema
  Validation
  Decisions
  Semantic Bundles
  Evidence
```

承载。

---

## 十四、当前已存在的产品能力

根据当前仓库状态，AsWish 已经具备第一阶段基础：

**Desktop**
- Delphi/VCL GUI；
- WebView2；
- HTML rendering；
- 可视化审阅界面。

**CLI**
当前已有：

```text
init / scan / generate / validate / render / health / decisions / bundle / ingest
intent / changeset
```

**Protocol**
- `.AsWish/`
- YAML facts
- 四投影；
- Semantic Bundles；
- Decisions；
- Evidence；
- State；
- Invariants；
- Extension rules。

**工程质量**
当前已有完整测试与 CLI 验证基础。

### 能力分层（已实现 / 下一步 / 未来）

| 层级 | 内容 |
|---|---|
| **已实现** | 自然语言意图承载、结构化 Change Set 解释、四投影树与 Spec 存储、渲染与快照、通用决策机制、追问机制 |
| **下一步**（First Closed Loop 范围） | Change Set 审阅与 Decisions 写回、协议冻结与证据链落盘、Accepted Visual Baseline、实现证据、差异、人类裁决、修订再验证 |
| **未来**（明确推迟） | 团队协作、账号体系、SaaS 化、商业模式、CI / 自动验证、Agent 调度、Python / 跨平台扩展、社区生态 |

> 每票的双闸门验收、依赖顺序与 Dogfood 要求，见 [`AsWish-工程路线与Dogfood验收-v1.md`](AsWish-工程路线与Dogfood验收-v1.md)；本文不复制。

> 这些能力现在的任务不是继续无限扩张，而是被组织进真正的端到端产品闭环。

---

## 十五、理论与产品的关系

AsWish 不是简单"贴了一层理论品牌"，它是部分理论构造的工程化实现。

**DM —— 差异一元论**

主要贡献：可追溯性与来源意识。

对应：

```text
traceability；
evidence；
source；
snapshot；
inheritance trace。
```

**ASTO —— 属集变迁存在论**

主要贡献：状态、变迁、边界和多投影结构。

对应：

```text
state；
transition；
actor；
boundary；
four projections；
runtime invariants。
```

**ODD —— 产出物驱动开发**

主要贡献：契约、验证、证据、封存与人类裁决的工程骨架。

AsWish 位于：

> 开发产出发生之前的规格控制层。

**CTF —— 建构追溯可谬规格方法论**

这是 AsWish 最直接、最核心的方法论来源。

核心思想：

> 需求的形式和粒度是人机协作的建构产物，必须可追溯，且始终可谬。

AsWish 的：

```text
traceable；
reviewable；
fallible；
四投影；
CTF Semantic Bundle；
review decision；
```

都与此直接相关。

> 当前 CTF 仍按 C2 候选研究纲领表述，不提高主张强度。

**PFM —— 问题显影方法论**

主要负责：规格形成以前，让模糊问题和问题断口出现。

它回答：

> "我们为什么知道这里值得继续问？"

而不是：

> "这里最终应该怎么解决？"

---

## 十六、外部 Wayfinder / Grilling 的关系

AsWish 可兼容、吸收以下外部工作方式：

```text
frontier；
fog of war；
exploration ticket；
one decision at a time；
grilling；
code-first evidence gathering。
```

但产品归属必须保持清楚：

> Wayfinder 是外部启发与兼容对象；AsWish 将其与 PFM、CTF、四投影、Decision、Visual Baseline 等机制组合成自己的规格控制链。

因此：

> 不强行声称 fog_state、Grilling 等属于一元论理论。

---

## 十七、商业化路线

> **第一阶段纪律**：第一阶段不是商业化阶段。分层路线是长期结构参考，当前优先目标是让陌生开发者下载、运行、完成第一次真实实验并带入真实项目（First User → First Experiment → First Real Project → First Difference → First Case）。不为企业市场增加企业级复杂度；免费/付费边界的推进由真实使用证据决定。指标见 [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md) §16。

**第一层：Understand（免费）**

帮助用户看见 AI 理解了什么、哪里不确定、哪里存在规格断口。

包括：

```text
scan；
ingest；
generate；
四投影；
visual preview；
基础决策确认；
render；
validation。
```

**第二层：Control（付费核心）**

帮助用户让已经确认的规格持续约束开发过程。

重点：

```text
Visual Baseline；
Spec / implementation comparison；
Drift；
Review Pack；
advanced evidence；
team policy；
rule feedback。
```

**第三层：Automate（高阶能力）**

例如：

```text
Agent/CLI 调度；
自动验证；
CI；
private model；
enterprise integration。
```

> 但 AsWish 始终不以"最好用的 Coding Agent"为战略目标。

---

## 十八、真正的护城河

不是：

```text
Delphi；
WebView2；
四棵树；
YAML；
某个 UI；
某个 LLM。
```

真正的长期资产是：

```text
Natural Language
→ Problem / Decision
→ Specification
→ Visual Baseline
→ Agent Execution
→ Implementation Evidence
→ Verification
→ Decision Feedback
```

也就是：

> **一条连续的 Specification Provenance / Verification Chain。**

---

## 十九、三阶段产品愿景

**Phase 1 — See**

让人看见 AI 理解的是什么。

核心：

```text
Spec + Decision + Visual Preview
```

**Phase 2 — Control**

让已经确认的规格真正约束开发。

核心：

```text
Baseline + Evidence + Comparison + Drift
```

**Phase 3 — Orchestrate**

让规格成为 Agent 工作流的控制接口。

核心：

```text
Protocol + SDK + CLI + Agent integrations
```

> 这一阶段才值得逐步扩大 Python / 跨平台能力。

---

## 二十、最终产品愿景

AsWish 最终不是一个"AI 需求文档工具"，而应该成为：

> **AI 原生软件开发中的规格控制层。**

更根本的愿景（权威表述见 [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md) §13）：

> **让理论真正进入真实世界，形成一个可以被真实开发者使用、产生工程证据、接受第三方检验、发现失败和反例，并反过来推动理论修正的开放工程系统。**

开源的核心传播是 **Test my claim**，而不是 Try my tool。核心原则：真实使用证据 > 功能数量；第三方反馈 > 内部自嗨；理论可证伪 > 理论包装；传播一个问题 > 宣传一堆功能。

其最终闭环：

```text
人类的问题
→ 问题显影
→ 决策确认
→ 共同理解
→ 可追溯 Spec
→ 视觉规格
→ 人类确认
→ Agent
→ 实际软件
→ 实现证据
→ 规格验证
→ 人类裁决
→ 新的共同理解
```

最终形成：

```text
Human Intent → Specification → Agent → Software → Evidence → Verification
```

而 AsWish 的核心承诺可以压缩成：

> **先让人和 Agent 对同一个东西达成可见的共识，再让 Agent 去做；做完以后，再证明它做的还是那个东西。**

---

## 二十一、当前工程阶段：First Contact → First Closed Loop

```text
Stage 1  First Contact     陌生开发者能下载、运行、理解、完成第一次实验
   ↓
Stage 2  First Closed Loop  AsWish 自己完成一次完整闭环
```

Stage 2 的第一目标不是"功能变多"，而是：

> **让 AsWish 成为自己的第一个真实用户，亲自用 AsWish 完成一次完整闭环。**

即：

> **AsWish 自己开发 AsWish，同时使用 AsWish 验证 AsWish。**

理由与验收：Stage 2 之前，主链后半段（实现证据 → 差异 → 人类裁决 → 修订）在代码层仍为空白；未跑通整条链，"Difference 被看见"就只是设计稿而非工程证据。由 AsWish 自己先承担第一次实验，失败成本最低、反例发现最早。

### 双闸门

工程推进不再以"代码完成 + 测试通过"为唯一放行条件：

```text
Engineering Green  +  Dogfood Green  →  方可进入下一票
```

| 闸门 | 回答的问题 |
|---|---|
| **Engineering Green** | 代码是否正确、可回归、可交付？ |
| **Dogfood Green** | 该能力在真实使用中真的被用起来了吗？ |

> 测试全绿只是 Engineering Green，**不是 Dogfood Green**。

依赖顺序、每票双闸门验收与 Dogfood 要求见 [`AsWish-工程路线与Dogfood验收-v1.md`](AsWish-工程路线与Dogfood验收-v1.md)。

---

## 二十二、所见即所得的工程原则

主链：

```text
显影 → 确认 → 建构 → 看见 → 生产 → 验证
```

完整闭环：

```text
Intent → Interpret → Confirm → Baseline → Agent → Evidence → Difference → Human Judgment → Revision → Rebuild → Re-verify
```

其中的 **See / 看见** 不是一个孤立阶段，而是一条贯穿性要求：

> **每一次人类需要确认"这就是我要的东西"时，AsWish 都必须提供一个可直接观察的表现。**

因此：

> **SVG / Visual Representation 是闭环基础设施的一部分，而不是装饰性 UI。**

### 正式表达（产品交互原则）

> **凡是要求 Human 作判断的对象，都必须具有稳定、可观察、可重复查看的表现。**

也就是说，AsWish 的"所见即所得"**不是传统 UI 意义上的即时渲染**。Visual Render / SVG 是当前阶段的工程实现载体——属于实现选择，**不等于产品定义**；实现载体未来可以替换，上述原则本身不变。

分工：

```text
文本   负责表达
结构   负责承载
SVG    负责让人看见
Human  负责判断
```

> **性质声明**：以上四条是**产品交互原则与工程设计原则**，**不是理论主张**，不构成对 Difference Monism / ASTO / ODD / CTF / PFM 的任何增强、削弱或重新解释。理论口径以 [`理论确权清单-v1.md`](理论确权清单-v1.md) 与 [`../NOTICE`](../NOTICE) 为准。

---

## 二十三、SVG / Visual Representation 的阶段

SVG 不是每个阶段都重新生成一张图。**哪些阶段需要新的视觉基线，哪些只是复用已有 Render**，由 §二十四 的矩阵裁定。

### 第一阶段：Problem / Current State

人类描述问题后，把当前相关结构以可视方式呈现。

目的不是美化，而是：

> **让人看见当前对象，而不是只阅读 YAML / 文本。**

### 第二阶段：Confirmed Understanding / Baseline

当人确认"对，这就是我想要的"，必须形成**可重复查看的视觉基线**：

```text
Human → 看到 → 确认 → Baseline
```

Baseline 不等于 Spec 文本本身。它是：

> **当前已确认理解的可见表现。**

> 承载机制沿用现有 `SpecSnapshot` + 视觉绑定（view-tree 引用 + `renderer_version` + decision 引用），**不新建名为 `VisualState` 的实体**。

### 第三阶段：After Agent Implementation

Agent 实施后，再次把 Implementation Result 以可视形式呈现：

```text
Baseline SVG → Agent → Actual Result SVG
```

这样人才有条件回答：

> "Agent 做出来的东西，看起来是不是刚才确认的那个东西？"

> 依据：`Screenshot = Implementation Evidence`；`Visual Preview = Specification Representation`。实现结果是**证据**，不是规格渲染产物，因此不能由 Render 生成，必须采集。

### 第四阶段：Difference View

Difference v0 初期先做结构差异，至少需要一种：

```text
Baseline  vs  Actual Result
```

的视觉比较。目的不是宣布 Error，而是：

> **让差异被看见。**

判断仍由 Human 完成：

```text
No important difference / Acceptable difference / Unacceptable difference / Unresolved
```

### 第五阶段：Revision / Rebuild

人类判断"这里不对，我要改"后，重新经过：

```text
Intent → Candidate → Confirm → Baseline → Agent
```

再次产生可视结果：

```text
Baseline v1 → Implementation v1 → Difference v1
    ↓
Human Revision
    ↓
Baseline / Confirmed Revision → Implementation v2 → Difference v2
```

整个循环都必须可以通过视觉结果观察。

### 保真度边界（第一阶段）

`TSpecNode` 无布局字段（layout / position / bounds 均缺），View Tree 是需求侧结构树。因此第一阶段 Visual Preview = **结构线框（wireframe）**，确定性渲染「页面 → 区域 → 组件 → 层级」，**不承诺相对位置与尺寸**。

渲染必须确定性：

```text
相同 View Spec + Renderer Version → 相同 Preview
```

第一阶段为纯确定性映射渲染，**不引入 LLM 视觉解释**。若要表达位置 / 尺寸，需先扩展 View Spec 布局 schema（**另立协议票**）。

---

## 二十四、AsWish Visual Checkpoint Matrix v0

### 关于 Current State 与 Confirmed Baseline 的语义差别

两者**有可能视觉上完全相同，但语义不同**，必须在产品与工程上区分：

```text
Current State      = "现在是什么"
Confirmed Baseline = "我们确认要的是什么"
```

相同的图像，前者是观察结果，后者是人类承诺。混淆二者会使 Difference 失去比较基准。

### Visual Checkpoint Matrix v0

| Checkpoint | Human 要看到什么 | Human 要判断什么 | 数据来源 | 是否形成稳定基线 | 是否参与 Difference |
|---|---|---|---|---|---|
| **VC-01 Current State** | 当前真实结构（view-tree 结构线框） | "现在是什么？" | 现有 Spec / Render（**复用**） | 否 | 否 |
| **VC-02 Confirmed Baseline** | 已确认目标（与 VC-01 可能同图、语义不同） | "这就是我要的吗？" | Confirmed Understanding（经 Decision 固化） | **是**（固定 `renderer_version` 保证可复现） | **是**（作为比较基准） |
| **VC-03 Implementation Result** | Agent 实际结果（截图 / 实际页面状态） | "做出来了吗？做成什么样？" | Implementation Evidence（**采集**，非 Render 生成） | 可复现保存 | **是** |
| **VC-04 Difference** | Baseline vs Result 的可见变化 | "哪里不同？" | VC-02 vs VC-03 **比较**，不生成新图 | 否 | **是** |
| **VC-05 Revised Result** | 修改后的结果 | "这次对了吗？" | Revision 重跑 VC-02 / 03 / 04 | 是 | 再比较 |

> **不机械要求每个 checkpoint 新生成独立 SVG**。生成策略见下方结论；承载机制只复用现有 `Render` / `Snapshot` / `SpecStore`，**不新增** `VisualState` / `VisualObject` / 新 Baseline 实体。

### 生成策略结论

```text
复用现有 Render             → VC-01 Current State
复用现有 Snapshot + 视觉绑定  → VC-02 Confirmed Baseline（不新建 Baseline 实体）
必须新增采集能力             → VC-03 Implementation Result（Render 生成不了证据）
只比较，不生成新视觉          → VC-04 Difference
零新机制，整轮复用           → VC-05 Revised Result
```

> 因此**不需要**"每个步骤一张新 SVG"。真正需要新增能力的只有 VC-03（采集）与 VC-04（比较）两处。

---

## 二十五、产品判断：不是更复杂的 Spec 编辑器

AsWish 不应被做成：

> 一个更加复杂的 Spec 编辑器。

而应保持：

> **人类用自然语言表达，AI 协助显影、理解、建构和实现；人类在关键节点通过"看见"来确认。**

因此：

```text
Human 不会直接编辑 Spec
Human 不会直接编辑复杂结构
Human 主要通过自然语言 + 可见结果进行判断
```

这条判断直接约束工程实现：不提供 YAML 编辑器、不提供字段编辑器、不提供节点拖拽式编辑。所有规格变更都经 `CandidateIngest` 自然语言入口进入，经 `Decisions` 裁决后才写回。

### 禁止新增的平行实体

```text
VisualState / Proposal / ParallelCandidate / ChangeObject
NewDecisionSystem / NewImpactGraph
VisualDecision / VisualApproval / VisualProposal / VisualReviewState
独立 Baseline 实体 / 第二套状态机 / 第五棵树
```

优先复用：

```text
CandidateIngest / Decisions / SpecSnapshot / Render / TreeBuilder / SpecStore / Prompts
现有 Semantic Bundles / gen_status / review_status
```

> 只有现有协议确实无法表达、且经主控裁定后，才允许新增最小结构。
