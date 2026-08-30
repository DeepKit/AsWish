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
> - 战略口径见 `AsWish-战略定稿-v1.md`（免费/付费边界、市场楔子、进入第二层门槛）
> - 路线层次见 `AsWish-三层产品路线-v1.md`（需求可视化 → 需求所见即所得 → CLI 实现）
> - 理论归属与确权状态见 `理论确权清单-v1.md`（含 fog_state 待确权口径）
> - 方法论见 `AsWish-CTF方法论-v2.1.md`；Wayfinder 外部启发见 `wayfinder-对AsWish的启发.md`
> - 工程基线以 `../SPEC.md`（v1.2-draft）为准

---

## 一、产品一句话

AsWish 让人类与 AI Agent 在开发前看见、确认同一个软件应该是什么；开发后再验证，做出来的是否还是那个东西。

更完整的产品定义：

AsWish 是 AI 原生软件开发的 **Specification Control Layer（规格控制层）**：它把模糊问题显影、关键决策确认后的共同理解固化为可追溯的规格，以视觉化对象交给开发 Agent，并在开发完成后用真实实现证据验证规格是否仍然成立。

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
