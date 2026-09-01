

========================================================================
[消息 0/11]  长度=7753
========================================================================
# 新会话交接提示词｜AsWish 工程实施阶段

你现在接手 **AsWish** 项目的工程实施工作。

请把以下内容视为本会话的既定工程背景。**不要重新讨论项目战略、产品命名和理论定位，除非后续工程事实明确触发战略冲突。**

当前目标已经从：

> 战略设计 / 产品认知收口

正式进入：

> **工程实施与验证阶段。**

---

# 一、项目当前唯一工程仓库

正式工作目录：

```text
D:\_Progs\02Business\AsWish

```

以后所有新的：

- 代码修改；
- 工单执行；
- 测试；
- 构建；
- CLI 回归；
- 协议修改；
- 工程文档；

均在该仓库进行。

旧项目：

```text
D:\_Progs\02Business\DeepSpec

```

仅作为历史工程 / 对照存档，不再承担后续开发。

---

# 二、DeepSpec → AsWish 迁移已经完成

迁移已经实际执行并验证。

已完成：

- Delphi 工程名称迁移；
- 38 个 unit 等工程文件同步；
- `TDeepSpec → TAsWish`；
- `.deepspec → .AsWish`；
- CLI / tests / reader / schema 等同步；
- 活跃工程面 `DeepSpec` / `.deepspec` / `TDeepSpec` 残留为 0；
- `.AsWish/` 真实 init / scan / read/write 验证通过；
- 主程序 / CLI / Tests 构建通过；
- DUnitX **126/126 全绿**。

迁移报告：

```text
D:\_Progs\02Business\AsWish\ASWISH-MIGRATION-REPORT.md

```

不要再重新执行改名迁移。

---

# 三、产品战略已经正式冻结

本会话不要重新定义产品。

当前层级：

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

其含义：

### Difference Monism

理论母体。

### As We Wish

理论 / 方法层：

> 人类与 AI 在问题显影、决策确认、表示和建构过程中形成共同理解的述事 / 建构机制。

### As I Wish

面向人的产品概念：

> 最终做出来的东西，是否仍然是我真正想要的东西？

### AsWish

实际工程实现：

- Windows Desktop；
- Delphi / VCL；
- WebView2；
- Headless CLI；
- Open Source。

### .AsWish

项目级工作空间 / 协议载体。

不是独立产品。

---

# 四、核心问题已经冻结

两个核心研究问题：

> **Are we still building the same thing?**

> **Where did the difference enter?**

不要自行替换成其他更营销化的口号。

---

# 五、当前产品完整主链

战略上的完整链：

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

```text
Manifest
→ Confirm
→ Construct
→ See
→ Build
→ Verify

```

中文：

> **显影 → 确认 → 建构 → 看见 → 生产 → 验证**

注意：

这些是产品流程概念。

**不要求每个步骤都对应一个独立工程实体。**

---

# 六、最重要的人机边界

### Human

负责：

- intention；
- judgment；
- decision；
- accept / reject / unresolved；
- final confirmation。

原则：

> **人类使用自然语言。**

> **人类不直接编辑 Spec。**

### AI

可以：

- discover；
- ask；
- explain；
- suggest；
- generate；
- transform；
- implement；
- inspect；
- surface differences。

但：

> **AI 没有最终决策权。**

任何工程实现都不能破坏这一边界。

---

# 七、Difference 的当前战略边界

当前战略上：

> Difference 是在人类意向 / 共同理解 / 表示 / Agent 执行 / 实际实现之间发生的、值得被看见和判断的变化。

必须保持：

> **Difference ≠ Error**

并且：

> **Difference made visible, traceable, and judgeable**

不要擅自把 Difference 定义为：

> Spec 与代码不同。

也不要把 Difference 设计成：

> 必须被消灭。

允许：

```text
No important difference
Acceptable difference
Unacceptable difference

```

当前工程上的 Difference v0 可以先从结构差异开始，但这：

> **不是 Difference 的最终理论定义。**

---

# 八、当前产品成熟度阶段

采用以下阶段：

```text
Stage 0
Identity Locked
        ✅ 已完成

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

当前正式进入：

> **Stage 1 → Stage 2**

而当前真正的核心目标是：

# First Closed Loop

即：

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

---

# 九、工程审计已经确认的当前能力

当前已经真实具备：

### 已具备

- `.AsWish/` 工作区；
- 四投影；
- YAML 存储；
- Scan；
- TreeBuilder；
- SpecStore；
- Validate；
- Render；
- WebView2；
- JS Bridge；
- Decisions；
- CandidateIngest；
- Snapshot；
- Prompt Export；
- CLI；
- Python protocol init；
- Python / TypeScript readers；
- examples；
- DUnitX 测试；
- GUI / CLI 构建。

### 部分具备

- 自然语言输入；
- Problem Manifestation；
- Visual Baseline；
- Agent integration；
- Revision。

### 当前结构性缺失

- Implementation Evidence v0；
- Difference v0；
- 实现后 Human Confirmation；
- Experiment / Case；
- agent-results 写入器。

---

# 十、战略收口审计已经完成

以下文件构成当前 SSOT：

```text
ASWISH-PRODUCT-IDENTITY.md
ASWISH-DOCUMENTATION-GOVERNANCE.md
AGENTS.md
.github/copilot-instructions.md
SPEC.md
protocol/
NOTICE
docs/理论确权清单-v1.md
docs/AsWish-产品功能与愿景蓝图-v1.md
docs/AsWish-用户上手说明-v1.md
docs/AsWish-当前文档索引-v1.md

```

最近一次战略收口审计结果：

> **READY FOR ENGINEERING**

报告：

```text
ASWISH-STRATEGIC-CLOSURE-AUDIT.md

```

因此：

> 不要再次要求战略确认。

---

# 十一、理论归因纪律

必须严格保持当前主张强度：

- Difference Monism：按理论母库正式定义；
- ASTO：按既定定义；
- ODD：按既定定义；
- PFM = **Problem Manifestation Methodology**；
- CTF 必须使用完整限定词：**CTF Semantic Bundle**；
- CTF 主张强度：**C2**；
- fog\_state：待确权工程构造；
- invariants：弱锚定 / 待确认；
- Wayfinder / Grill-me：外部实践启发；
- 不把外部启发写成原创理论；
- 不为工程方便扩大理论主张；
- 不擅自重新定义理论。

若发现理论冲突：

> **标记并报告，不自行裁定理论。**

---

# 十二、当前已有两个重要工程审计报告

请先实际阅读：

```text
ASWISH-FIRST-PUBLIC-EXPERIMENT-READINESS-REPORT.md
ASWISH-STRATEGIC-CLOSURE-AUDIT.md

```

以及工程治理入口：

```text
ASWISH-PRODUCT-IDENTITY.md
ASWISH-DOCUMENTATION-GOVERNANCE.md
AGENTS.md
SPEC.md

```

不要凭本交接提示词猜测代码现状。

**必须以实际仓库内容为准。**

---

# 十三、当前工程重点

最近一次 Readiness Audit 得到：

## Stage 1 First Contact

主要工作：

- 首次运行入口；
- 文档入口；
- 5 分钟第一次实验；
- 安装器；
- 下载即用；
- Agent 接入说明；
- 实际运行验证。

## Stage 2 First Closed Loop

核心工作：

```text
Natural Language Intent
        ↓
Candidate / Change Set
        ↓
Decision
        ↓
Accepted Visual Baseline
        ↓
Agent Development
        ↓
Implementation Evidence
        ↓
Difference v0
        ↓
Human Confirmation
        ↓
Revision

```

---

# 十四、目前已经确定的工程优先级

不要并发开展整套生态。

按照依赖关系串行：

```text
0027A
  ↓
0027B
  ↓
0027C
  ↓
0027D
  ↓
0028
  ↓
Evidence v0
  ↓
Difference v0
  ↓
Human Confirmation
  ↓
First Closed Loop

```

当前工程票：

# WO-20260830-0027A

正式执行仓库：

```text
D:\_Progs\02Business\AsWish

```

目标：

> 建立“人类自然语言意向 → Candidate / Change Set → 现有 CandidateIngest / Decisions”入口。

核心原则：

```text
Human Intent
      ↓
Candidate / Change Set
      ↓
Existing CandidateIngest
      ↓
Existing Decision Mechanism
      ↓
Human Confirmation

```

**绝不能变成：**

```text
Human Natural Language
      ↓
Automatic Spec Mutation

```

---

# 十五、工程架构纪律

必须遵守：

### 1

优先复用：

- CandidateIngest；
- Decisions；
- Snapshot；
- Scan；
- TreeBuilder；
- SpecStore；
- Prompts；
- Render；
- Semantic Bundles。

### 2

禁止擅自增加平行实体：

- Proposal；
- Parallel Candidate；
- Parallel Decision；
- VisualState；
- ChangeObject；
- 新状态系统；
- 新 impact graph。

### 3

协议现有机制优先。

如果现有协议足以承载，不要重新建协议。

### 4

不要为了“产品完整”扩大本票范围。

---

# 十六、当前工程门禁

每一票：

1. 修改前阅读实际文件；
2. 明确复用点；
3. 尽量保持单 Commit ≤ 200 行；
4. 实际 Build；
5. 实际 Test；
6. 必要时执行 CLI；
7. 保留原始输出证据；
8. 检查 Git diff；
9. 检查是否出现理论主张漂移；
10. 完成后再进入下一票。

不要只报告：

> “代码看起来没问题。”

必须有实际验证。

---

# 十七、文件处理纪律

如果本会话中用户提供或引用项目文件：

> 优先读取实际文件。

不要凭旧对话推断仓库现状。

如果需要访问实际代码：

- 读取实际文件；
- 检查调用关系；
- 检查测试；
- 检查协议；
- 再提出方案。

---

# 十八、当前阶段特别不要做

除非后续明确下发：

- SaaS；
- 账号；
- Team；
- SSO；
- Enterprise；
- 自建 Agent Orchestrator；
- 大型 Benchmark；
- 社区平台；
- 自动理论推导；
- 多语言完整 AST；
- 自动 Difference 归因；
- 视觉像素级 Difference；
- Case 社区系统。

当前优先：

> **First Closed Loop。**

---

# 十九、以后如果你认为已有判断错误

不要为了维持旧结论而硬接。

必须明确：

```text
原判断
↓
新证据
↓
为什么冲突
↓
建议改变什么
↓
是否需要人类裁定

```

但是：

> 小的工程事实错误可以直接修正。

> 产品战略 / 理论边界问题不能擅自修正。

---

# 二十、本会话的工作方式

我接下来主要与你讨论：

- Delphi 工程实现；
- 协议；
- 数据结构；
- GUI；
- CLI；
- WebView2；
- Agent integration；
- 测试；
- 构建；
- 工单拆解；
- 工程风险；
- 实际代码问题；
- First Closed Loop 的工程实现。

不要再主动展开开源营销和战略讨论，除非我明确询问。

---

# 二十一、第一任务上下文

当前最新工程阶段：

> **Stage 1 → Stage 2**

当前主任务：

> **WO-20260830-0027A**

当前真正需要解决的工程问题：

> **如何在不破坏现有 CandidateIngest / Decisions / 协议的情况下，让人类通过自然语言表达修改意向，并形成可审阅、可确认的 Candidate / Change Set。**

先从实际仓库开始。

请第一步：

1. 阅读 `ASWISH-PRODUCT-IDENTITY.md`
2. 阅读 `ASWISH-DOCUMENTATION-GOVERNANCE.md`
3. 阅读 `AGENTS.md`
4. 阅读 `SPEC.md`
5. 阅读 `WO/WO-20260830-0027A-甲-CandidateIngest自然语言修订入口工单.md`
6. 检查当前相关代码：
   - `AsWish.Services.CandidateIngest.pas`
   - `AsWish.Services.Prompts.pas`
   - `AsWish.Services.Decisions.pas`
   - `AsWish.Controller.pas`
   - 相关 CLI / GUI command
   - 相关 tests

然后先给出：

> **当前工程事实 → 0027A 工单要求 → 二者差距 → 最小实施方案**

**第一轮不要修改代码。**

等方案确认后再开始实施。

========================================================================
[消息 1/11]  长度=671
========================================================================
powershell.exe -NoProfile -Command Set-Location 'D:\_Progs\02Business\AsWish'; Write-Output '---ROOT---'; Get-ChildItem -Force | Select-Object Mode,Length,LastWriteTime,Name; Write-Output '---TARGET FILES---'; $files=@('ASWISH-PRODUCT-IDENTITY.md','ASWISH-DOCUMENTATION-GOVERNANCE.md','AGENTS.md','SPEC.md','WO/WO-20260830-0027A-甲-CandidateIngest自然语言修订入口工单.md','AsWish.Services.CandidateIngest.pas','AsWish.Services.Prompts.pas','AsWish.Services.Decisions.pas','AsWish.Controller.pas'); foreach($f in $files){$p=Join-Path (Get-Location) $f; if(Test-Path $p){$i=Get-Item $p; Write-Output ("FOUND`t{0}`t{1} bytes" -f $f,$i.Length)}else{Write-Output ("MISSING`t{0}" -f $f)}}

========================================================================
[消息 2/11]  长度=1534
========================================================================
已接收交接，我会按这套工程约束继续，不重新打开战略和理论定位。

但第一步遇到了一个**实际环境限制**：

- 你指定的工程仓库是 `D:\_Progs\02Business\AsWish`
- 当前这个 ChatGPT 会话的文件工具只能读取已上传/Library 中的文件
- 我尝试直接访问该 Windows 本地路径，但当前执行环境没有挂载你的 `D:` 盘
- 在 Library 中也没有找到你列出的 AsWish 工程文件；现有检索结果主要是之前的理论资料，而不是当前仓库

因此，我现在**不能诚实地声称已经阅读了实际仓库**。这一步不能靠交接提示词猜。

尤其是你明确规定：

> **不要凭本交接提示词猜测代码现状，必须以实际仓库内容为准。**

我同意这个门禁。

### 当前需要的最小材料

请把下面这些文件上传到本会话即可，我就可以继续完成第一轮**只读分析，不改代码**：

```text
ASWISH-PRODUCT-IDENTITY.md
ASWISH-DOCUMENTATION-GOVERNANCE.md
AGENTS.md
SPEC.md

WO/
└─ WO-20260830-0027A-甲-CandidateIngest自然语言修订入口工单.md

AsWish.Services.CandidateIngest.pas
AsWish.Services.Prompts.pas
AsWish.Services.Decisions.pas
AsWish.Controller.pas
```

另外最好提供相关的：

```text
CLI command
GUI command
CandidateIngest tests
Decisions tests
Prompts tests
```

如果文件较多，**直接把整个 `AsWish` 仓库压成 ZIP 上传也可以**，反而最稳妥。我会以仓库实际内容为准进行检索，不需要你手工挑文件。

我还需要的两个审计报告：

```text
ASWISH-FIRST-PUBLIC-EXPERIMENT-READINESS-REPORT.md
ASWISH-STRATEGIC-CLOSURE-AUDIT.md
```

如果它们已经在仓库里，也可以随 ZIP 一起提供。

### 上传后我第一轮只做这四件事

```text
① 当前工程事实
        ↓
② 0027A 工单要求
        ↓
③ 二者差距
        ↓
④ 最小实施方案
```

并特别检查：

- CandidateIngest 当前输入/输出契约
- Decisions 当前状态与确认机制
- Prompts 当前是否已有自然语言入口能力
- Controller 如何串联这些服务
- CLI / GUI 当前入口
- 现有协议能否直接承载 Change Set
- 是否已经存在可以复用的 Candidate 数据结构
- 是否会产生新的平行实体
- 如何确保：

```text
Human Intent
    ↓
Candidate / Change Set
    ↓
CandidateIngest
    ↓
Decision
    ↓
Human Confirmation
```

而**绝不会变成**：

```text
Human Intent
    ↓
Automatic Spec Mutation
```

**这一轮我不修改任何代码、不改协议、不创建 Commit。**

把仓库 ZIP 或上述文件上传后，我直接开始做实际代码审计。

========================================================================
[消息 3/11]  长度=6072
========================================================================
可以。你让“秘书 AI”直接在 `D:\_Progs\02Business\AsWish` 里做一次**只读工程资料整理**，最后给我一个压缩包即可。

下面这段提示词可以直接复制给它：

:::writing{variant="chat_message" id="58321"}
你现在是 **AsWish 项目的工程秘书 / 资料整理员**。

你的任务不是修改工程，而是为另一个 AI 工程师准备 **WO-20260830-0027A** 的只读审查资料。

# 一、绝对规则

这是一次：

> **READ-ONLY / ZERO MODIFICATION**

严禁：

- 修改任何代码；
- 修改任何 Markdown / 协议文件；
- 修改项目配置；
- 修改测试；
- 运行会产生写入副作用的迁移、格式化、代码生成；
- 执行 git commit；
- 执行 git reset / checkout / clean；
- 修改 `.AsWish/`；
- 修改任何数据库、缓存或工程状态文件。

可以执行：

- 查看文件；
- 搜索代码；
- `git status`；
- `git log`；
- `git diff`；
- 编译 / 测试命令，但仅限不会修改源文件和工程状态的验证；
- 复制文件到临时资料目录；
- 创建一个最终的资料 ZIP。

不要对工程提出方案，也不要修改工程。

---

# 二、工作目录

正式仓库：

```text
D:\_Progs\02Business\AsWish
```

旧仓库：

```text
D:\_Progs\02Business\DeepSpec
```

**不要读取旧仓库作为当前工程事实来源。**

---

# 三、第一优先级：必须收集的文件

请检查并复制以下文件到一个临时资料目录，例如：

```text
D:\_Progs\02Business\AsWish\_handoff\WO-20260830-0027A\
```

必须包含：

```text
ASWISH-PRODUCT-IDENTITY.md
ASWISH-DOCUMENTATION-GOVERNANCE.md
AGENTS.md
SPEC.md

ASWISH-FIRST-PUBLIC-EXPERIMENT-READINESS-REPORT.md
ASWISH-STRATEGIC-CLOSURE-AUDIT.md

WO\WO-20260830-0027A-甲-CandidateIngest自然语言修订入口工单.md
```

如果上述文件实际路径不同：

> 请按照仓库实际路径寻找，不要凭文件名猜测。

同时记录实际路径。

---

# 四、第二优先级：0027A 直接相关代码

必须收集：

```text
AsWish.Services.CandidateIngest.pas
AsWish.Services.Prompts.pas
AsWish.Services.Decisions.pas
AsWish.Controller.pas
```

并找到这些文件的实际路径。

---

# 五、第三优先级：必须继续向调用关系追踪

不要只收集上面四个文件。

请检查：

## CandidateIngest

搜索：

```text
CandidateIngest
TCandidate
Candidate
Ingest
```

找出：

- 谁创建 CandidateIngest；
- 谁调用 CandidateIngest；
- CandidateIngest 输入是什么；
- CandidateIngest 输出是什么；
- Candidate 数据结构在哪里定义；
- Candidate 是否已有 Change Set / Patch / Modification 类结构；
- 是否已经存在自然语言相关入口。

把真正相关的 unit 一并复制。

---

## Decisions

搜索：

```text
Decision
Decisions
Accept
Reject
Unresolved
Confirm
```

确认：

- Decision 数据结构在哪里；
- Decision 生命周期在哪里；
- 如何创建 Decision；
- 如何确认 / 接受 / 拒绝；
- 谁调用 Decision；
- 是否已经支持 candidate → decision。

把真正相关的 unit 一并复制。

---

## Prompts

搜索：

```text
Prompt
Prompts
instruction
natural language
intent
```

确认：

- 是否已经存在自然语言 Prompt；
- Prompt 如何生成；
- 是否已有系统提示词；
- 是否已有 Candidate 生成提示；
- 是否已有用户意图 → 结构化结果的机制。

把真正相关的代码和配置一并复制。

---

# 六、第四优先级：Controller / CLI / GUI 入口

重点检查：

```text
AsWish.Controller.pas
```

并继续寻找：

- CLI command；
- GUI command；
- CandidateIngest command；
- Decision command；
- Prompt command；
- 任何用户输入入口；
- WebView2 / JS Bridge 中可能调用这些服务的入口。

搜索关键词：

```text
CandidateIngest
Decision
Prompt
Intent
Command
Execute
Handle
Route
Bridge
```

请把**真正涉及这些调用链的文件**一起复制。

不要把整个仓库所有文件都塞进 ZIP。

---

# 七、第五优先级：测试

必须寻找：

```text
CandidateIngest
Decision
Prompt
Controller
CLI
```

相关测试。

重点寻找：

```text
*CandidateIngest*Test*.pas
*Decision*Test*.pas
*Prompt*Test*.pas
*Controller*Test*.pas
```

以及仓库中实际存在的相关 DUnitX tests。

请复制真正覆盖这些能力的测试文件。

同时记录：

- 测试项目；
- 测试入口；
- 当前测试数量；
- 与 0027A 直接相关的测试。

---

# 八、第六优先级：协议 / 数据结构

请检查 Candidate、Decision 是否受已有协议约束。

重点搜索：

```text
protocol
candidate
decision
change set
snapshot
schema
yaml
```

尤其确认：

- Candidate 是否已经在协议中定义；
- Decision 是否已经在协议中定义；
- 是否已有 Change Set；
- 是否已有 revision / patch / delta 结构；
- 是否已有用户确认状态；
- 是否需要新协议字段。

把真正相关的 protocol/schema 文件复制出来。

**不要自行设计新协议。**

---

# 九、第七优先级：项目结构和 Git 状态

请在仓库根目录执行只读命令并记录原始输出：

```powershell
git status --short
git branch --show-current
git log -5 --oneline --decorate
```

再记录当前目录的大致工程结构。

可以执行：

```powershell
tree /F /A
```

但如果输出过大，只整理与以下内容相关的目录：

```text
src
source
app
cli
gui
tests
protocol
WO
docs
```

---

# 十、第八优先级：当前构建 / 测试证据

在不修改任何文件的前提下：

1. 确认当前正式 Delphi 工程；
2. 确认 CLI 工程；
3. 确认 Tests 工程；
4. 如果现有工程支持直接 Build/Test，则可以执行；
5. 保留**原始命令和原始输出**。

特别需要知道：

```text
当前构建是否成功
当前 DUnitX 测试数量
当前测试是否全绿
```

如果无法执行，也不要修复环境。

只记录：

> 无法执行，以及具体原因。

---

# 十一、重点：做“调用链事实图”

不要提出设计建议，只根据代码事实整理：

```text
Human / CLI / GUI Input
        ↓
???
        ↓
Prompt / Intent processing
        ↓
CandidateIngest
        ↓
Candidate
        ↓
Decisions
        ↓
Decision
        ↓
Spec / Snapshot / Render / ...
```

把实际代码中的调用关系填进去。

对于不确定的地方标记：

```text
UNKNOWN
```

不要猜。

---

# 十二、重点：找出 0027A 的“现状证据”

根据工单和代码，整理四栏：

```text
已有能力
缺失能力
可以直接复用
可能需要新增
```

但：

> 不要提出最终实施方案。

例如只写：

```text
CandidateIngest 已存在
Decision 已存在
自然语言入口尚未发现
Candidate 已存在
...
```

必须引用具体：

```text
文件路径
类名
方法名
```

---

# 十三、最终交付物

请创建：

```text
D:\_Progs\02Business\AsWish\_handoff\WO-20260830-0027A\
```

目录结构建议：

```text
WO-20260830-0027A\
│
├─ 00-MANIFEST.md
├─ 01-READONLY-AUDIT.md
├─ 02-GIT-STATUS.txt
├─ 03-BUILD-TEST-EVIDENCE.txt
│
├─ docs\
├─ wo\
├─ source\
├─ tests\
├─ protocol\
├─ cli-gui\
└─ evidence\
```

其中：

### `00-MANIFEST.md`

列出：

- 每个文件原始路径；
- 复制后的路径；
- 文件用途；
- 是否为 0027A 直接相关；
- 是否属于调用链。

### `01-READONLY-AUDIT.md`

只记录工程事实，至少包含：

```text
1. 当前仓库状态
2. 0027A 工单核心要求
3. CandidateIngest 当前实现
4. Decisions 当前实现
5. Prompts 当前实现
6. Controller 当前实现
7. CLI / GUI 当前入口
8. 相关测试
9. 相关协议
10. 实际调用链
11. 已存在能力
12. 缺失能力
13. 未确定事项
```

注意：

> 不给出实施方案。

### `02-GIT-STATUS.txt`

保存原始：

```text
git status --short
git branch --show-current
git log -5 --oneline --decorate
```

### `03-BUILD-TEST-EVIDENCE.txt`

保存：

- 实际执行的命令；
- 完整原始输出；
- Build 结果；
- Test 结果；
- DUnitX 数量。

---

# 十四、最后创建 ZIP

完成资料整理后，创建：

```text
D:\_Progs\02Business\AsWish\_handoff\WO-20260830-0027A.zip
```

ZIP 中包含：

```text
00-MANIFEST.md
01-READONLY-AUDIT.md
02-GIT-STATUS.txt
03-BUILD-TEST-EVIDENCE.txt
docs\
wo\
source\
tests\
protocol\
cli-gui\
evidence\
```

不要把：

```text
.git
bin
lib
临时编译文件
巨大缓存
node_modules
```

放进去。

---

# 十五、最后回复我

只需要告诉我：

```text
[整理完成]

仓库：
D:\_Progs\02Business\AsWish

资料目录：
D:\_Progs\02Business\AsWish\_handoff\WO-20260830-0027A\

ZIP：
D:\_Progs\02Business\AsWish\_handoff\WO-20260830-0027A.zip

状态：
READ-ONLY，无代码修改

并简要说明：
1. 找到了哪些核心文件
2. CandidateIngest 调用链是否完整
3. Decisions 调用链是否完整
4. CLI / GUI 是否找到自然语言入口
5. Build/Test 是否成功
6. 是否存在无法确认的关键事实
```

再次强调：

> **不要修改 AsWish 仓库。**
>
> **不要做 0027A 实施。**
>
> **不要重命名任何工程文件。**
>
> **不要设计新的 Candidate / Decision / ChangeSet 实体。**
>
> **不要修改协议。**
>
> 本次唯一目标是：**把真实工程事实完整、可追溯地交给下一位工程 AI。**
:::

秘书 AI 整理完后，把这个：

```text
WO-20260830-0027A.zip
```

上传给我就够了。

我收到后会直接从**实际代码**开始做你要求的第一轮：

> **当前工程事实 → 0027A 工单要求 → 差距 → 最小实施方案**

第一轮仍然**不改代码**。

========================================================================
[消息 4/11]  长度=15511
========================================================================
# WO-20260830-0027A 只读交接大文档（单文件版）



> 仓库：`D:\_Progs\02Business\AsWish`（AsWish 当前正式仓库）

> 旧仓库 `D:\_Progs\02Business\DeepSpec` 未作为事实来源。

> **本交接为 READ-ONLY：未修改 AsWish 仓库任何源/文档/配置/测试/`.AsWish/` 文件；仅向 `_handoff/` 写入副本并执行了一份预编译测试 exe 作证据。**



---



## 00 - 文件清单（MANIFEST）



| # | 原路径（AsWish 仓库内） | 用途 | 0027A相关 | 在调用链 |

|---|---|---|---|---|

| 1 | `ASWISH-PRODUCT-IDENTITY.md` | 产品/理论身份 SSOT | No | No |

| 2 | `ASWISH-DOCUMENTATION-GOVERNANCE.md` | 文档治理 SSOT | No | No |

| 3 | `AGENTS.md` | 工程纪律/门禁 | No | No |

| 4 | `SPEC.md` | v1.2-draft 协议基线 | Partial | Yes (candidate/decision 协议) |

| 5 | `ASWISH-FIRST-PUBLIC-EXPERIMENT-READINESS-REPORT.md` | 公开实验就绪审计 | No | No |

| 6 | `ASWISH-STRATEGIC-CLOSURE-AUDIT.md` | 战略收口审计 | No | No |

| 7 | `WO/WO-20260830-0027A-甲-CandidateIngest自然语言修订入口工单.md` | 工单原文（需求/AC） | **Yes** | Yes (ticket source of truth) |

| 8 | `src/services/AsWish.Services.CandidateIngest.pas` | CandidateIngest 服务（含 0027A 方法） | **Yes** | **Core** |

| 9 | `src/services/AsWish.Services.Prompts.pas` | Prompt 生成（含 grilling） | Partial | Yes (grilling 复用) |

| 10 | `src/services/AsWish.Services.Decisions.pas` | Decision 生命周期 | Partial | Yes (下游确认) |

| 11 | `src/controllers/AsWish.Controller.pas` | 工作流协调 / LLM 生成闭环 | Partial | Yes (Ingest 调用) |

| 12 | `src/models/AsWish.Models.pas` | `TCandidateIntent` / `TSpecNode.UserIntent` / `TSpecDecision` 定义 | **Yes** | **Core (types)** |

| 13 | `src/services/AsWish.Services.SpecStore.pas` | 解析/写盘；`ParseTreeNodes`、UserIntent 解析 | Partial | Yes |

| 14 | `src/core/AsWish.Yaml.Writer.pas` | YAML 写盘；`user_intent` 字段写出 | Partial | Yes |

| 15 | `tests/Test.AsWish.CandidateIngest.pas` | CandidateIngest 单测（含 0027A 方法） | **Yes** | Yes |

| 16 | `tests/Test.AsWish.Decisions.pas` | Decisions 单测 | Partial | Yes |

| 17 | `tests/Test.AsWish.Prompts.pas` | Prompts 单测 | Partial | Yes |

| 18 | `tests/Test.AsWish.Controller.pas` | Controller 单测 | Partial | Yes |

| 19 | `tests/Test.AsWish.Models.pas` | Models 单测（含 TCandidateIntent） | **Yes** | Yes |

| 20 | `protocol/schemas/decisions.schema.json` | Decision 协议 schema | Partial | Yes |

| 21 | `protocol/schemas/review-decision.schema.json` | Review Decision 协议 schema | Partial | Yes |

| 22 | `protocol/schemas/tree.schema.json` | 四投影树 schema（含 legacy/decision_refs） | Partial | Yes |

| 23 | `protocol/schemas/project-spec.schema.json` | 工程索引 schema（decisions_count） | No | No |

| 24 | `protocol/schemas/agent-result.schema.json` | Agent 结果 schema（SPEC §7） | No | No |

| 25 | `cli/AsWish.CLI.dpr` | CLI 入口；含 `intent` / `ingest` 子命令 | **Yes** | **Core (entry)** |

| 26 | `src/app/AsWish.Commands.pas` | GUI 命令表（无 NL 入口，见审计） | Partial | Yes (negative evidence) |

| 27 | `src/app/AsWish.MainForm.pas` | GUI 主窗体（无 NL 入口，见审计） | Partial | Yes (negative evidence) |



**本审计产出的顶层文件**：`00-MANIFEST.md`、`01-READONLY-AUDIT.md`、`02-GIT-STATUS.txt`、`03-BUILD-TEST-EVIDENCE.txt`、`evidence/test-run.log`。



**刻意未包含**：`.git/`、`bin/`、`dcu/`、`cli/bin/`、`cli/dcu/`、构建产物、`_build*.bat`；完整 `docs/`（38 文件，仅 6 份第一优先级）、完整 `protocol/`（仅 5 schema）、完整 `src/`（53 文件，仅 7 个 0027A 相关单元）、完整 `WO/`（52 文件，仅本工单）。



---



## 01 - 只读审计报告（仅事实，无方案）



### 1. 当前仓库状态

- 工作树干净，仅有本审计刻意创建的 `_handoff/` 目录。

- 分支：`main`。

- HEAD 提交：`27c268d (HEAD -> main) feat(candidate): implement WO-20260830-0027A natural language user intent entry`。

- 前序提交：战略收口审计、身份/治理 SSOT、迁移清理。

- DUnitX：**134 个测试，134 通过，0 失败**（预编译 `tests/AsWish.Tests.exe`，只读执行取证据；见 §03）。

- 编译器可用（Studio 37.0 `dcc64`），但**未重新构建**（只读约束）。



> **重要事实：WO-20260830-0027A 已经实现并提交（HEAD `27c268d`）。** 本交接记录的是*当前已实现状态*，不是空白起步。下一位工程师应验证/扩展，而非假设未开始。



### 2. WO-20260830-0027A 核心要求（摘自工单）

- 目标：让用户在任何 Spec 节点提交自然语言修订/补充，路由进现有 `CandidateIngest`。

- 原则：不新建 "Proposal" 实体；`CandidateIngest = 人类 NL 候选输入`。

- 边界（A↔B）：NL 原始文本以 `user_intent` 字段 + 目标上下文（`node_id`/`projection`）持久化；工单仅*承载*，不解释/生成节点。LLM 解释 → Change Set 超出范围（归 0027B）。

- 复用 `grilling_ticket` 处理输入不足（不新建提问系统）。

- AC-01..AC-07：提交 NL / 持久化为 user_intent / 复用 grilling / 不修改 Canonical Spec / 不新建 proposal 生命周期 / 回归通过 / 构建+测试证据。



> 注意：工单表头仍写"工作仓库：D:\_Progs\02Business\DeepSpec"。实现实际落在 AsWish 仓库（HEAD `27c268d`）。见 §13。



### 3. CandidateIngest 当前实现

文件：`src/services/AsWish.Services.CandidateIngest.pas`。



**既有（0027A 前）核心：**

- `TAsWishCandidateIngest.Ingest(candidateYaml, existingFunc/Mod/View[/Data])` → `TCandidateIngestResult`（解析+校验节点，路由进 4 投影列表）。

- `MergeInto(accepted, Func/Mod/View[/Data])` → `TMergeStats`（Merged/Added/FogCleared）。保留人类 `review_status`/`decision_refs`；推进 `gen_status` 为 generated；函数根摘要变化时令 `fog_state` 前进一步。

- 强校验：id 前缀、parent_id 外键、禁止 `human_decision` source_layer、强制 LLM 输出 `gen_status<=generated` 且 `review_status=unreviewed`。



**为 0027A 新增（代码中明确标注）：**

- `TCandidateIntent` 记录（定义于 `src/models/AsWish.Models.pas:151`）：`NodeId, Tree, UserIntent, CreatedAt, Author, SourceRefs`。`TCandidateIntent.CreateNew(...)` 工厂在 `AsWish.Models.pas:347`。

- `FormatCandidateIntentYaml(const AIntent)` —— 序列化为 YAML（`version/tree/node_id/user_intent/author/created_at`）。

- `ParseCandidateIntentYaml(const AYaml)` —— 反解析。

- `SaveCandidateIntent(AProjectPath, AIntent)` → 写入 `.AsWish/llm/candidate-intent.yaml`（经 `TAsWishStoreService.AtomicWriteTextFile`）。

- `LoadCandidateIntent(AProjectPath)` → 读回。

- `CheckIntentClarity(AIntent, out AIssue)` → 若意图过短/过泛，构造 `grilling_ticket` 的 `TSpecIssue`（id `issue-grill-<ts>`）；否则返回 True。

- `TSpecNode.UserIntent: string` 字段已加（models:139）；在 `SpecStore.pas:487` 解析；在 `Yaml.Writer.pas:221-222` 写出。



### 4. Decisions 当前实现

文件：`src/services/AsWish.Services.Decisions.pas`。

- `TAsWishDecisionsService`：`AddDecision / FindById / GetAccepted / AcceptDecision / RejectDecision / PromotePending / ApplyNodeStatusTransitions`。

- `TSpecDecision` 记录：`Id, DecisionType, Title, DecisionText, Rationale, TargetNodes, ..., Status, DecidedBy, ...`（models:223）。

- `PromotePending` 读取 `pending-decisions.yaml`（来自 WebView2 JS Bridge）→ 正式 decisions；`ApplyNodeStatusTransitions` 修改树节点状态。

- **与 0027A 的关系**：candidate → decision 流一般存在，但 0027A 的 `user_intent` 持久化路径**尚未创建/消费任何 Decision**。AC-04（不修改 Canonical Spec）结构上已满足；没有将持久化意图链接到任何 decision。



### 5. Prompts 当前实现

文件：`src/services/AsWish.Services.Prompts.pas`。

- `WriteContextPack`、`WriteGenerationPrompt`、`WriteNodePrompt`、`WriteDecisionRewritePrompt`、`WriteGrillingPrompt`。

- `WriteGrillingPrompt(AIssue, ANodes)` 产出面问人类的澄清提示（目标：Claude Code / Cursor / Codex）。0027A 的 `CheckIntentClarity` 产生 grilling issue；其提示文本可由该方法生成——复用路径，无需新提示实体。

- 尚无专门的 "user_intent → 结构化结果" 提示（超出 0027A 范围，属 0027B）。



### 6. Controller 当前实现

文件：`src/controllers/AsWish.Controller.pas`。

- LLM 生成循环已调用 `TAsWishCandidateIngest.Create → Ingest → MergeInto` 闭环（约 line 722–807）：写入 `.AsWish/llm/candidate-output.yaml`，ingest，合并进实时树。

- 这是 A→B（LLM 生成候选 → ingest）路径，**不是**人类 NL 意图入口。Controller 中无对 `SaveCandidateIntent` / `CheckIntentClarity` 的调用。



### 7. CLI / GUI 当前入口

**CLI：** `cli/AsWish.CLI.dpr`。

- `ingest <dir> <file.yaml>` → `RunIngest` → `Ingest` + `MergeInto`（约 line 409–515）。

- `intent <dir> <id> <tree> <text>` → `RunIntent`（约 line 521–562）：构造 `TCandidateIntent.CreateNew(id, tree, text, 'human')`，调用 `CheckIntentClarity`（不清晰则 grilling issue），再 `SaveCandidateIntent`。**这是 0027A 的 NL 入口，已在 CLI 完整接通。**

- CLI help 列出 `ingest` 与 `intent`。



**GUI：** `src/app/AsWish.Commands.pas`、`src/app/AsWish.MainForm.pas`。

- 命令表：File/Open、Run/Scan、Generate B、View/Render、Tools（Promote Pending Decisions、Export Prompt、Setup LLM）。**未发现任何 NL 意图入口命令 / 无 "submit user_intent" 对话框。** 在 `AsWish.Commands.pas`/`AsWish.MainForm.pas` 中 grep `Intent|Candidate|Ingest` 无 0027A 接线。

- WebView2 JS Bridge（`src/providers/AsWish.Providers.MainView.pas`）处理 accept/reject decisions；那里也未发现 NL-intent 界面。



> 结论：0027A NL 入口**仅存在于 CLI**；**GUI 无 NL 入口**（AC-01 "用户可在 Spec 节点上下文提交自然语言修订" 部分满足——CLI 路径有，GUI 无）。



### 8. 相关测试

- `tests/Test.AsWish.CandidateIngest.pas` —— 覆盖 Ingest/MergeInto 及（按 HEAD）0027A intent 方法。

- `tests/Test.AsWish.Decisions.pas`、`Test.AsWish.Prompts.pas`、`Test.AsWish.Controller.pas`、`Test.AsWish.Models.pas` —— 覆盖相邻单元。

- 套件总计 134，全绿。测试项目：DUnitX；入口 `tests/AsWish.Tests.dpr`（预编译 `tests/AsWish.Tests.exe`）。`tests/` 含 11 个 `.pas` 测试单元。



### 9. 相关协议

复制到 `protocol/` 的 schema：

- `decisions.schema.json` —— 必填 `id,type,title,decision,rationale,target_nodes,decided_by,status`；定义 decision_type/decision_status。

- `review-decision.schema.json` —— `decision_action ∈ {accept,reject,request_changes,lock,unlock}`；`required: id, decision_action, target_nodes, created_at, reviewer`。

- `tree.schema.json` —— 节点 schema；含 `legacy_node_status`、`revision`、`decision_refs`；**未定义 `user_intent`** 字段。

- `project-spec.schema.json`、`agent-result.schema.json` —— 仅上下文。



> **协议缺口**：`user_intent`（持久化于 `.AsWish/llm/candidate-intent.yaml`）与 `TCandidateIntent` **不被 `protocol/schemas/` 中任何 schema 描述**。`candidate-intent.yaml` 的位置也不在 `SPEC.md §2` 的 `.AsWish/` 布局内。尚无 Change Set / patch / revision delta schema（用户变更语义尚未建模——与 0027A 仅承载、不解释一致）。



### 10. 实际调用链（事实）

```

[CLI]  AsWish.CLI.dpr :: RunIntent(dir,id,tree,text)

        │  TCandidateIntent.CreateNew(id, tree, text, 'human')

        ▼

[Models] TCandidateIntent (record)

        │

        ▼

[Service] TAsWishCandidateIngest.CheckIntentClarity(intent, out issue)

        │  ├─ unclear (<=3 chars / generic) → builds TSpecIssue(itGrillingTicket)

        │  └─ clear → returns True

        ▼

[Service] TAsWishCandidateIngest.SaveCandidateIntent(dir, intent)

        │  FormatCandidateIntentYaml → .AsWish/llm/candidate-intent.yaml

        ▼

   (persisted; NOT merged into trees; NOT turned into nodes — AC-02/AC-04)

   (LLM interpretation → Change Set = UNKNOWN / out of scope 0027B)



[Separate, pre-existing] LLM generation path:

[Controller] Run Scan / "Generate B"

        → .AsWish/llm/candidate-output.yaml

        → TAsWishCandidateIngest.Ingest → MergeInto → live trees

        (Candidate → Trees, not via user_intent)

```

Decision 链接：`user_intent` →（未创建 Decision）。`Candidate`（YAML 节点）→ `Decisions` 一般经 `DecisionsService`，但 0027A intent 路径未调用它。



### 11. 已有能力（0027A）

- `TCandidateIntent` 类型 + `CreateNew` 工厂 —— `AsWish.Models.pas:151/347`。

- `Format/Parse/Load/SaveCandidateIntent` —— `AsWish.Services.CandidateIngest.pas`。

- `CheckIntentClarity` → grilling issue —— `AsWish.Services.CandidateIngest.pas:584`。

- `SaveCandidateIntent` 写入 `.AsWish/llm/candidate-intent.yaml`。

- CLI `intent` 子命令完整接通 —— `cli/AsWish.CLI.dpr:521-562`。

- `TSpecNode.UserIntent` 字段经 `SpecStore` + `Yaml.Writer` 持久化。

- `grilling_ticket` issue 类型 + `WriteGrillingPrompt` 复用路径存在。

- 测试覆盖存在且全绿（134/134）。



### 12. 缺失 / 不确定能力（0027A）

- **GUI NL 入口缺失**（AC-01 仅经 CLI 满足）。

- **无协议 schema** 描述 `user_intent` / `candidate-intent.yaml`（§9 缺口）。

- **未从持久化意图创建任何 Decision**（无对意图的 accept/reject）。

- **无 LLM 解释 / Change Set** 由 `user_intent` 生成（明确归 0027B）。

- **不确定**：`Test.AsWish.CandidateIngest.pas` 是否真断言了新的 0027A 方法（此处未逐行读；标记给下一位工程师核实 AC-06 回归 + AC-07 证据是否覆盖）。

- **不确定**：旧 DeepSpec 仓库是否仍存有本工作的分叉副本（工单表头指向那里）。未读取（按指令只读，不读旧仓库）。



### 13. 未定 / 待裁决事项（事实，非决定）

- 工单表头 "工作仓库：DeepSpec" vs 实现在 AsWish 仓库（`27c268d`）。需负责人确认 0027A 的 canonical 仓库。

- `.AsWish/llm/candidate-intent.yaml` 不在 `SPEC.md §2` 布局 → 公开发布前可能需要协议更新（就绪审计报告将此列为 First Contact 风险类）。

- 无 GUI 意图入口界面 —— 须决定 AC-01 是否要求 GUI。



---



## 02 - GIT 状态（原始输出）



```

### git status --short ###

?? _handoff/



### git branch --show-current ###

main



### git log -5 --oneline --decorate ###

27c268d (HEAD -> main) feat(candidate): implement WO-20260830-0027A natural language user intent entry

75c8973 docs: complete AsWish strategic closure audit (READY WITH CONDITIONS)

e1bfed0 docs: finalize alignment report with commit hash

5654259 docs: establish authoritative product identity and documentation governance SSOT

62cb7ff Update migration report: cleanup verified, fixture migration, conformance runner pre-existing issue recorded



### note: '_handoff/' is the handoff deliverable created by this audit; it is untracked by design. ###

```



---



## 03 - 构建 / 测试证据（只读审计）



### A. 编译器可用性检查（未执行构建）

命令：

```

where dcc64

ls "D:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc64.exe"

```

结果：

```

D:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc64.exe  (FOUND)

D:\Program Files (x86)\Embarcadero\Studio\37.0\bin64\dcc64.exe (FOUND)

```

结论：Embarcadero Delphi / RAD Studio 13.1（Studio 37.0）Win64 编译器已安装可用。完整重建 AsWish.dpr / AsWish.CLI.dpr / AsWish.Tests.dpr 技术上可行。



**构建决定（只读约束）**：未执行完整重建。任务指令严格只读（"不要修改任何代码 / 不要运行会产生写入副作用的迁移、格式化、代码生成"；编译/测试命令"仅限不会修改源文件和工程状态的验证"）。`dcc64 -B` 重建会再生成 dcu/ 和 bin/ 产物，即修改构建状态。为遵守零修改规则，本审计使用工作树中已存在的**预编译测试二进制**（`tests/AsWish.Tests.exe`）执行，不触及任何源/产物文件。



工作树中发现的预编译二进制：

```

tests/AsWish.Tests.exe        (10,251,776 bytes)  -> 用于测试证据

cli/bin/AsWish.CLI.exe        ( 3,361,792 bytes)

bin/AsWish.exe                (GUI, present)

```



### B. 测试执行（只读，预编译二进制）

命令：

```

cd D:\_Progs\02Business\AsWish\tests

D:\_Progs\02Business\AsWish\tests\AsWish.Tests.exe -b

(output redirected to evidence\test-run.log)

```

原始输出尾部：

```

DUnitX - [AsWish.Tests.exe] - Starting Tests.

...................................................................

    (134 dots = 134 test cases executed)

Tests Found   : 134

Tests Ignored : 0

Tests Passed  : 134

Tests Leaked  : 0

Tests Failed  : 0

Tests Errored : 0

```

退出码：0。



完整原始日志：`evidence\test-run.log`（本次审计中捕获）。



### C. 解读

- DUnitX 套件：134 测试，**全绿**（0 失败 / 0 错误 / 0 泄漏）。

- 取代早先流传的 "126/126"：WO-20260830-0027A 实现新增测试用例（见 `Test.AsWish.CandidateIngest.pas`），总数升至 134。

- CandidateIngest 相关测试：存在且通过。

- Decisions 相关测试：存在且通过。

- Prompts 相关测试：存在且通过。

- Controller 相关测试：存在且通过。



### D. 若下一位工程师需要全新构建（仅参考，本交接未执行）

```

_build.bat                       -> bin\AsWish.exe

cd tests && _build_tests.bat    -> tests\AsWish.Tests.exe

cd cli && _build_cli.bat        -> cli\bin\AsWish.CLI.exe

```



---



## 04 - 现状证据四栏（只列事实，不提实施方案）



| 维度 | 已有能力 (file:class.method) | 缺失能力 | 可直接复用 | 可能需新增 |

|---|---|---|---|---|

| NL 入口 | CLI `intent` (`AsWish.CLI.dpr:RunIntent`) | GUI NL 入口 | `TCandidateIntent.CreateNew` | GUI 对话框/命令 |

| Intent 持久化 | `SaveCandidateIntent` → `.AsWish/llm/candidate-intent.yaml` | 协议 schema | `TAsWishStoreService.AtomicWriteTextFile` | candidate-intent schema |

| 清晰度检查 | `CheckIntentClarity` → grilling issue | — | `WriteGrillingPrompt` | — |

| Node 字段 | `TSpecNode.UserIntent` (Models/SpecStore/Yaml.Writer) | — | Yaml round-trip | — |

| Candidate 合并 | `Ingest` / `MergeInto` | — | 现有流程 | — |

| Decision 关联 | `TAsWishDecisionsService` | intent→decision 链接 | `AddDecision`/`PromotePending` | 视决定而定 |

| LLM 解释 | — | Change Set 生成 | — | 0027B（非本票） |



**示例事实陈述**（供下一位工程师直接引用）：

- CandidateIngest 已存在（含 0027A 方法）。

- Decision 已存在（`TAsWishDecisionsService` 生命周期完整）。

- CLI 自然语言入口已发现（`intent` 子命令）。

- GUI 自然语言入口尚未发现。

- Candidate 已存在（`TCandidateIntent` + `TSpecNode.UserIntent`）。

- 调用链：CLI `RunIntent` → `TCandidateIntent.CreateNew` → `CheckIntentClarity` → `SaveCandidateIntent` → `.AsWish/llm/candidate-intent.yaml`（持久化，不合并进树，不生成节点）。

- 未确定：GUI 入口、协议 schema、intent→decision 链接、LLM 解释（0027B）。



---



## 05 - 关键事实摘要（给下一位工程师的速览）



1. **仓库干净，0027A 已实现并提交**（HEAD `27c268d`）。不要当作空白起步。

2. **CLI 是 0027A 唯一 NL 入口**；GUI 完全没有。

3. **CandidateIngest 库代码完整且有 0027A 新增**，但仅由 CLI 接通；Controller 不调用。

4. **Decisions 生命周期完整**，但 0027A 的 `user_intent` 路径不创建任何 Decision。

5. **协议缺口**：`user_intent` / `candidate-intent.yaml` 无对应 schema，且位置不在 SPEC §2 布局内。

6. **测试 134/134 全绿**，但 `Test.AsWish.CandidateIngest.pas` 是否逐行断言了 0027A 新方法需核实。

7. **工单表头写 DeepSpec，实现在 AsWish**——canonical 仓库需裁决。

8. 本交接**未做 0027A 实施、未重命名/新增实体、未改协议**，仅交付可追溯事实。



========================================================================
[消息 5/11]  长度=2405
========================================================================
我已经读完你贴出的这份交接文档。它已经把**工程现状的骨架**交代清楚了，但还不能替代源码审查。

目前我可以先确认几个很重要的事实：

### 1. 0027A 实际上已经做完第一版

当前 HEAD：

```text
27c268d feat(candidate): implement WO-20260830-0027A natural language user intent entry
```

而且测试证据是：

```text
134 / 134 passed
```

所以我们接下来不是“设计 0027A”，而是：

> **审查 27c268d 是否真正符合 0027A 的边界，以及它是否为 0027B 留下了正确接口。**

### 2. 从交接文档看，我已经发现几个必须检查的点

这些现在还不能直接判定为 Bug，需要看代码。

**第一，`TCandidateIntent` 的定位。**

工单要求：

> 不新建 Proposal / Parallel Candidate。

但实现新增了：

```text
TCandidateIntent
```

它究竟只是 `CandidateIngest` 内部对“人类自然语言候选输入”的数据表示，还是实际上形成了一个新的平行 Candidate 生命周期，这一点必须通过 `Models.pas`、`CandidateIngest.pas` 和测试确认。

**第二，“进入 CandidateIngest”目前很可能是语义上的，而不是现有 Ingest pipeline。**

当前链路是：

```text
CLI RunIntent
  ↓
TCandidateIntent.CreateNew
  ↓
CheckIntentClarity
  ↓
SaveCandidateIntent
```

并没有：

```text
RunIntent
  ↓
TAsWishCandidateIngest.Ingest(...)
```

所以需要判断工单所说的：

> “路由进现有 CandidateIngest”

究竟要求的是**复用 CandidateIngest service**，还是要求进入现有的 `Ingest → MergeInto` 候选处理流水线。

这两个含义差别很大。

**第三，`candidate-intent.yaml` 的持久化方式很值得重点检查。**

目前报告显示：

```text
.AsWish/llm/candidate-intent.yaml
```

这是一个固定路径。

而用户意向又是：

```text
node_id
projection
user_intent
created_at
...
```

需要确认多个节点、连续多次提交时到底是：

```text
一个文件一个 intent
```

还是：

```text
一个文件一个 intent 历史集合
```

否则“任何 Spec 节点提交自然语言修订”可能会出现覆盖问题。

**第四，`TSpecNode.UserIntent` 与 `TCandidateIntent` 存在两个承载面。**

现在看起来是：

```text
TSpecNode.UserIntent
```

同时又有：

```text
TCandidateIntent
    ↓
candidate-intent.yaml
```

这两个东西的职责是否重复，是这次审查非常关键的一点。

否则很容易形成：

```text
Node.UserIntent
CandidateIntent
candidate-intent.yaml
```

三个地方表达同一件事情。

---

## 所以现在我不建议继续凭这份报告给实施方案

因为你在交接要求里明确规定了：

> **必须以实际仓库内容为准。**

而我现在还没有看到：

```text
AsWish.Models.pas
AsWish.Services.CandidateIngest.pas
AsWish.Services.Prompts.pas
AsWish.Services.Decisions.pas
AsWish.Controller.pas
AsWish.CLI.dpr
Test.AsWish.CandidateIngest.pas
Test.AsWish.Models.pas
SPEC.md
0027A 工单原文
```

特别是我要逐行检查：

```text
TCandidateIntent
CreateNew
FormatCandidateIntentYaml
ParseCandidateIntentYaml
SaveCandidateIntent
LoadCandidateIntent
CheckIntentClarity
RunIntent
```

以及对应测试。

### 你现在只需要让秘书 AI 再给我这部分

不用再做一份大审计了。

直接把**上述实际源码 + 测试 + SPEC + 0027A 工单**打成一个 ZIP 上传给我即可。

我拿到之后，第一轮就严格输出：

```text
一、实际工程事实
二、0027A AC-01～AC-07逐项核验
三、现有实现与工单的差距
四、发现的结构性风险
五、最小实施/修正方案
六、是否建议进入0027B
```

而且我会特别回答一个核心问题：

> **27c268d 这个实现到底是“正确完成了 0027A”，还是只是“实现了一个能工作的第一版 CLI intent 功能”。**

这两个结论，目前从你这份交接文档看，**还不能划等号**。

========================================================================
[消息 6/11]  长度=6735
========================================================================
对。这样更合理。

你现在真正需要建立的不是“工程任务清单”，而是一个**以 AsWish 自己为实验对象的工程推进节奏**：

> **每完成一项能力，就立刻拿 AsWish 自己做真实任务验证；验证通过，才进入下一项。**

这样最终不是“代码都写完了，理论上能闭环”，而是：

> **AsWish 是我们自己第一个真实用户，也是第一个 Case。**

---

# 一、我建议把工程节奏改成“能力阶梯”

你原来的依赖关系：

```text
0027A
  ↓
0027B
  ↓
0027C
  ↓
0027D
  ↓
0028
  ↓
Evidence v0
  ↓
Difference v0
  ↓
Human Confirmation
  ↓
First Closed Loop
```

这个顺序本身是对的。

但每一票不要只看“代码完成”，而要同时有两个验收：

```text
工程验收
+
AsWish 自用验收
```

只有二者都通过，才算真正完成。

---

# 二、Step 0：0027A —— 让“人说话”真正进入 AsWish

这一票现在已经有实现，所以接下来不是继续扩功能，而是**拿 AsWish 自己使用它**。

### 完成什么

建立最小的人类自然语言入口：

```text
人类
 ↓
“我想把这里改成……”
 ↓
Candidate Intent
 ↓
必要时 Grill
 ↓
保存
```

这里暂时**不要求 AI 理解成 Change Set**。

也就是说：

> 0027A 解决的是“我想改什么，能够被 AsWish 接住”。

不是“我说完以后 AsWish 自动知道该怎么改”。

### AsWish 自用实验

选 3 个真实的小任务，在 AsWish 自己身上提交。

例如可以分别测试：

```text
① 明确修改
“把 CLI 的 XXX 提示改得更容易理解。”

② 补充需求
“这里还需要能够显示 XXX。”

③ 模糊需求
“这里感觉不太对，应该改一下。”
```

第三种特别重要，因为它应该触发 Grill，而不是偷偷替人猜。

### 0027A 验收标准

工程：

```text
✓ 人可以只用自然语言输入
✓ 能绑定目标节点 / 上下文
✓ 意图被保存
✓ 不直接修改 Canonical Spec
✓ 模糊意图进入 Grill
✓ 不产生 Proposal 平行生命周期
```

自用：

```text
✓ 我们自己真的用它提交了 AsWish 修改意图
✓ 第二天还能准确找到“我当时想改什么”
✓ 模糊输入确实会让我重新说明
✓ AsWish 没有擅自替我做决定
```

### 这一票的真正结束条件

不是：

> `134/134`

而是：

> **我们已经产生第一批真实 AsWish User Intent。**

这是非常重要的区别。

---

# 三、Step 1：0027B —— 从“我想改什么”到“可能怎么改”

这是整个系统第一次真正进入：

> **共同建构。**

核心：

```text
Human Intent
      ↓
AI interpretation
      ↓
Candidate / Change Set
      ↓
Human review
```

这里才开始让 AI 去理解：

> “你这句话可能意味着什么？”

### 完成什么

AI 根据：

```text
User Intent
+
Current Spec / Context
+
相关现状
```

形成一个**候选修改集合**。

重点不是直接修改，而是：

> **把 AI 的理解摊给人看。**

### 验收标准

工程：

```text
✓ 能从 Intent 生成候选解释
✓ 候选与目标节点有明确对应关系
✓ 不自动写入 Canonical Spec
✓ 候选可以被 Accept / Reject / Unresolved
✓ AI 无最终决定权
```

自用：

我们拿 Step 0 那几个真实任务继续做，不换测试数据。

例如：

```text
我：
“CLI 这里的提示太技术化，我希望新用户能看懂。”

AI：
“我理解为：
1. 保留技术信息；
2. 增加面向普通用户的说明；
3. 不改变命令行为。

是否正确？”
```

然后人可以：

```text
Accept
Reject
修改
Unresolved
```

### 这一票真正证明的是

> **AI 是否真的在帮助人形成共同理解，而不是偷偷替人完成 Spec。**

---

# 四、Step 2：0027C —— 从候选理解到“确认后的东西”

这一步开始解决：

> **“我们到底确认了什么？”**

### 完成什么

建立：

```text
Candidate
 ↓
Decision
 ↓
Accepted Understanding
 ↓
Visual / Structured Baseline
```

注意不是新增一个叫 `VisualState` 的大实体，而是利用现有：

```text
Decision
Snapshot
Render
Spec
```

把**已经被人确认的理解**固定下来。

### 验收标准

工程：

```text
✓ Candidate 可以进入 Decision
✓ 人明确 Accept / Reject
✓ Accept 后形成可重现的 baseline
✓ baseline 可以再次查看
✓ Canonical Spec 的变化具有明确的人类决策来源
```

自用：

我们继续使用同一个真实任务。

最终必须能回答：

> **“在 Agent 开始写代码以前，我们到底确认了什么？”**

而不是：

> “大概就是这个意思。”

---

# 五、Step 3：0027D —— 把确认后的东西真正交给 Agent

到这里才进入：

> **Build**

也就是：

```text
Confirmed Baseline
        ↓
Agent
        ↓
Implementation
```

### 完成什么

建立 AsWish → Agent 的实际工作入口。

重点不是自己造一个大型 Agent Orchestrator，而是：

> **把“已经确认的人类意向”连同必要上下文交给现有 Agent。**

例如：

```text
Confirmed Understanding
+
Relevant Spec
+
Prompt / Context Pack
+
Task boundary
        ↓
Claude Code / Codex / Cursor
```

### 验收标准

工程：

```text
✓ Agent 能拿到确认后的目标
✓ Agent 能拿到必要上下文
✓ Agent 不需要人重新把整个任务讲一遍
✓ Agent 工作边界明确
✓ 实际代码修改可以追踪
```

自用：

拿前面的真实 AsWish 任务真正让 Agent 去做。

最终人自己回答：

> **“Agent 实现的是刚才我们确认的那个东西吗？”**

---

# 六、Step 4：0028 —— Implementation Evidence

这一步我建议非常明确地把目标压缩成：

> **不要先判断对不对，先证明发生了什么。**

也就是：

```text
Agent
 ↓
实际修改
 ↓
Implementation Evidence
```

### Evidence 至少要回答

```text
改了什么？
改了哪些文件？
执行了什么？
测试了什么？
产生了什么结果？
```

这里暂时不要急着做“智能评价”。

### 验收标准

```text
✓ Agent 修改有记录
✓ 修改文件可追踪
✓ Build/Test 有实际结果
✓ CLI / GUI 行为有证据
✓ Evidence 与这一次任务可以关联
✓ Evidence 是事实记录，不是 AI 自我评价
```

自用时尤其重要：

> **我们自己做一次完整任务，然后不靠 Agent 的一句“完成了”，而是看 Evidence。**

---

# 七、Step 5：Difference v0 —— 第一次真正回答核心问题

到这里才做：

# Where did the difference enter?

第一版不要碰最终理论。

只做结构上可验证的 Difference：

```text
Confirmed Baseline
        ↓
Implementation
        ↓
Actual Result
        ↓
Difference v0
```

### Difference v0 的职责

不是：

> “代码错误了。”

而是：

> “确认的东西，与最后实际产生的东西有什么不同？”

例如：

```text
Intent：
增加普通用户说明

Confirmed：
保留技术信息 + 增加用户说明

Implementation：
增加了说明，但删除了原有技术信息

Difference：
“保留技术信息”这一要求未出现在最终实现中
```

这时候 Difference 才第一次具有真正产品意义。

### 验收标准

```text
✓ 能发现至少一类实际结构差异
✓ 差异有来源
✓ 能指向 baseline / implementation evidence
✓ 不自动判定为 Error
✓ 可以人工判断：
   Acceptable
   Unacceptable
   Unresolved
```

---

# 八、Step 6：Human Confirmation + Revision

这是第一闭环最后一道门。

整个链条：

```text
Intent
 ↓
Interpret
 ↓
Confirm
 ↓
Baseline
 ↓
Agent
 ↓
Evidence
 ↓
Difference
 ↓
Human Judgment
 ↓
Revision
```

### 核心变化

以前：

```text
Difference
 ↓
系统自己修
```

这里必须保持：

```text
Difference
 ↓
Human
 ↓
Accept / Reject / Revise
```

### 验收标准

必须至少真实完成一次：

```text
发现 Difference
      ↓
人判断
      ↓
要求修改
      ↓
Agent 再次实施
      ↓
再次 Evidence
      ↓
再次 Difference
```

也就是说：

> **必须出现第二轮。**

如果只有：

```text
Build
 ↓
看一下
 ↓
Done
```

还不能叫 First Closed Loop。

---

# 九、真正的 First Closed Loop 验收

我建议把最终验收压缩成下面这一张表：

| 环节 | 必须发生 |
|---|---|
| Manifest | 人用自然语言说出想要什么 |
| Confirm | AI 与人确认理解 |
| Construct | 形成候选修改 |
| See | 人确认 baseline |
| Build | Agent 实际实现 |
| Verify | 有 Implementation Evidence |
| Difference | AsWish 找出实际变化 |
| Judge | 人判断 Difference |
| Revise | 人要求修正 |
| Rebuild | Agent 再实施 |
| Re-verify | 再次验证 |

最后必须做到：

```text
同一个真实任务

至少经过：

人 → AI → 人 → Agent → Evidence
→ Difference → 人 → Agent → Evidence

完整走通一次。
```

---

# 十、而且我建议不要一开始就做“复杂 Case”

第一批 Dogfood 应该故意很小。

因为现在我们不是证明 AsWish 能管理大型项目。

我们只证明：

> **AsWish 能不能帮助一个人把一个本来模糊的小修改，从“我觉得应该这样”，一路变成“我确认的是这个，Agent 实现的是这个，最后实际产生的是这个”。**

所以第一批真实任务最好满足：

```text
小
真实
可修改
可验证
有一定歧义
但不能太复杂
```

例如 AsWish 自己的：

```text
CLI 小改动
GUI 小改动
文档入口小改动
Prompt 行为小改动
一个测试行为小改动
```

都比拿一个几十文件的大功能合适。

---

# 十一、以后每一张工程票都采用同一种验收格式

我建议以后你让我安排工单时，不再只有：

```text
目标
实现
测试
```

统一改成：

```text
WO-XXXX

一、这一票解决什么能力

二、这一票不解决什么

三、工程完成条件

四、AsWish 自用任务

五、真实使用必须发生什么

六、验收标准

A. 工程验收
B. 人机交互验收
C. AsWish Dogfood 验收

七、完成后才能进入哪一票
```

这样工程节奏会非常稳。

---

# 十二、还有一个我认为很重要的变化

从现在开始：

> **不要把“测试通过”当成产品进度。**

例如：

```text
134/134
```

只能证明：

> 现有代码没有被已有自动化测试击穿。

但真正的阶段进度应该是：

```text
我们能不能真的用 AsWish 完成一次任务？
```

所以我建议建立两套绿灯：

```text
Engineering Green
    ↓
代码 / Build / Tests / Protocol

Dogfood Green
    ↓
真实人类使用 / Agent 使用 / 真实结果
```

只有：

```text
Engineering Green
        +
Dogfood Green
        ↓
进入下一票
```

---

## 我认为当前最合适的工程节奏

```text
现在
 ↓
0027A
“我能不能用自然语言告诉 AsWish 我想改什么？”
 ↓
Dogfood #1

 ↓
0027B
“AI 能不能把我的意思变成可审阅的候选理解？”
 ↓
Dogfood #1 延续

 ↓
0027C
“我们到底确认了什么？”
 ↓
Dogfood #1 延续

 ↓
0027D
“Agent 是否真的按这个去做？”
 ↓
Dogfood #1 延续

 ↓
0028
“Agent 到底做了什么？”
 ↓
Dogfood #1 延续

 ↓
Evidence v0
 ↓
Difference v0
“实际产生的东西和确认的东西哪里不同？”
 ↓
Human Confirmation
 ↓
Revision
 ↓
第二轮实现
 ↓
First Closed Loop
```

**最关键的一点：不要每完成一票就换一个 Demo。**

最好从现在开始就选定**一个真实的 AsWish 内部小任务**，让它一路经过 0027A → 0027B → 0027C → 0027D → Evidence → Difference → Revision。

这样当我们宣布：

> **AsWish First Closed Loop 成功**

我们手里不是一堆单元测试，而是一个真正可以复述的：

> **AsWish 自己使用 AsWish 完成 AsWish 的案例。**

这会比再写一大堆“架构已经完整”的文档有价值很多。

========================================================================
[消息 7/11]  长度=8611
========================================================================
对，这里要补上一个非常重要的原则：

> **AsWish 不是“先做完，再画图”。**
>
> **“所见即所得”本身就是闭环的一部分：人在哪一个阶段确认，就必须能看到那个阶段所确认的东西。**

因此 SVG 不是一个单独的“展示功能”，而应该成为 `See / Baseline / Verify / Difference` 这些阶段的实际载体。

我先把我们刚才讨论的内容整理成一份**给资料 AI 的开发任务 + PRD 更新提示词**。你直接交给它即可。

:::writing{variant="chat_message" id="74162"}
你现在是 **AsWish 项目的产品工程资料 AI**。

请根据下面这份最新讨论结果，**更新 AsWish 的 PRD / 开发任务 / 工程路线资料**。

这次任务不是写代码，而是把最新确定的工程节奏、Dogfood 方式、First Closed Loop 验收方式，以及“所见即所得 / SVG 可视化”要求，正式写入现有项目文档体系。

必须以 AsWish 当前仓库已有的 SSOT / 文档治理规则为准，不要创建与现有治理体系冲突的新文档体系。

---

# 一、当前阶段已经确定

AsWish 当前：

```text
Stage 1 → Stage 2
First Contact → First Closed Loop
```

当前第一目标不是“功能很多”，而是：

> **让 AsWish 自己成为第一个真实用户，亲自使用 AsWish 完成一次完整闭环。**

也就是说：

> **AsWish 自己开发 AsWish，同时使用 AsWish 验证 AsWish。**

---

# 二、核心工程策略已经确定

以后工程推进不再单纯按照：

```text
代码完成
→
测试通过
→
下一票
```

而采用：

```text
工程验收
+
AsWish 自用验收
```

两道门。

只有：

```text
Engineering Green
+
Dogfood Green
```

才能进入下一票。

---

# 三、当前工程依赖顺序

正式采用：

```text
0027A
  ↓
0027B
  ↓
0027C
  ↓
0027D
  ↓
0028
  ↓
Implementation Evidence v0
  ↓
Difference v0
  ↓
Human Confirmation
  ↓
Revision
  ↓
First Closed Loop
```

不要为了“产品完整”并发扩展整套生态。

---

# 四、每一票都必须同时定义两套验收

以后开发任务不能只写：

```text
Goal
Implementation
Test
```

统一增加：

```text
Engineering Acceptance
+
Dogfood Acceptance
```

每张工单应至少包含：

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

---

# 五、0027A

0027A 当前实际上已经实现并进入 HEAD：

```text
27c268d
```

第一版功能边界保持不变。

目标：

> **人类可以用自然语言告诉 AsWish “我想改什么”。**

链路：

```text
Human Intent
    ↓
Candidate Intent
    ↓
必要时 Grill
    ↓
持久化
```

禁止变成：

```text
Human Natural Language
    ↓
Automatic Spec Mutation
```

0027A 不负责：

- AI 解释意图；
- Change Set；
- 自动修改 Spec；
- 完整 Decision；
- Difference。

这些交给后续阶段。

---

# 六、但从现在开始必须加入一个新原则

# 所见即所得必须贯穿整个 AsWish 流程

当前产品已经确定：

```text
显影 → 确认 → 建构 → 看见 → 生产 → 验证
```

以及完整闭环：

```text
Intent
 ↓
Interpret
 ↓
Confirm
 ↓
Baseline
 ↓
Agent
 ↓
Evidence
 ↓
Difference
 ↓
Human Judgment
 ↓
Revision
 ↓
Rebuild
 ↓
Re-verify
```

这里的：

> **See / 看见**

不是一个孤立阶段。

而是要求：

> **每一次人类需要确认“这就是我要的东西”时，AsWish 都必须提供一个可直接观察的表现。**

因此：

> **SVG / Visual Representation 是闭环基础设施的一部分，而不是装饰性 UI。**

---

# 七、请重新梳理 SVG / Visual Baseline 的阶段

不要擅自创造新的理论实体。

需要在 PRD 与开发路线中明确：

## SVG 第一阶段：Problem / Current State

在人类描述问题后，AsWish 应能够把当前相关结构以可视方式呈现。

目的不是美化，而是：

> **让人看见当前对象，而不是只阅读 YAML / 文本。**

---

## SVG 第二阶段：Confirmed Understanding / Baseline

当人确认：

> “对，这就是我想要的。”

必须形成一个**可重复查看的视觉基线**。

核心要求：

```text
Human
 ↓
看到
 ↓
确认
 ↓
Baseline
```

Baseline 不等于 Spec 文本本身。

它是：

> **当前已确认理解的可见表现。**

要继续研究怎样最大限度复用现有 Render / Snapshot，不要提前创建名为 `VisualState` 的新实体。

---

## SVG 第三阶段：After Agent Implementation

Agent 开始修改后，需要能够再次把：

```text
Implementation Result
```

以可视形式呈现。

也就是：

```text
Baseline SVG
        ↓
Agent
        ↓
Actual Result SVG
```

这样人才有条件回答：

> “Agent 做出来的东西，看起来是不是刚才确认的那个东西？”

---

## SVG 第四阶段：Difference View

Difference v0 初期可以先做结构差异。

因此至少需要一种：

```text
Baseline
vs
Actual Result
```

的视觉比较。

不是为了宣布：

> Error

而是：

> **让差异被看见。**

Difference 的判断仍然由 Human 完成：

```text
No important difference
Acceptable difference
Unacceptable difference
Unresolved
```

---

## SVG 第五阶段：Revision / Rebuild

当 Human 判断：

> “这里不对，我要改。”

再次经过：

```text
Intent
→
Candidate
→
Confirm
→
Baseline
→
Agent
```

之后，需要重新产生可视结果。

也就是说：

```text
Baseline v1
    ↓
Implementation v1
    ↓
Difference v1
    ↓
Human Revision
    ↓
Baseline / Confirmed Revision
    ↓
Implementation v2
    ↓
Difference v2
```

整个循环都必须可以通过视觉结果观察。

---

# 八、请在 PRD 中明确一个原则

建议原文表达为：

> **AsWish 的“所见即所得”不是传统 UI 意义上的即时渲染，而是“人类确认对象必须具备稳定、可重复、可比较的视觉表现”。**

进一步明确：

```text
文本
负责表达

结构
负责承载

SVG
负责让人看见

Human
负责判断
```

但不要把这句话写成理论主张。

它是：

> **产品交互原则 / 工程设计原则。**

---

# 九、SVG 不是每个阶段都必须重新生成一张图

这里要特别避免过度工程化。

不要设计成：

```text
每个步骤一张新 SVG
```

而应该研究：

> **哪些阶段需要新的视觉基线，哪些阶段只是复用已有 Render。**

当前建议至少存在以下几个视觉检查点：

```text
① Current State
当前状态

② Confirmed Baseline
人类确认后的基线

③ Implementation Result
Agent 实际结果

④ Difference
基线与实际结果的可见差异

⑤ Revised Result
修正后的结果
```

其中：

```text
Current State
```

和

```text
Confirmed Baseline
```

有可能视觉上相同，但语义上不同：

```text
Current State
= “现在是什么”

Confirmed Baseline
= “我们确认要的是什么”
```

这一差别需要在 PRD 中明确。

---

# 十、Dogfood 的方式也正式确定

不要每个阶段换一个 Demo。

选择：

> **一个真实、足够小、确实需要修改的 AsWish 自身任务**

然后让这个任务一路贯穿：

```text
0027A
 ↓
0027B
 ↓
0027C
 ↓
0027D
 ↓
Evidence
 ↓
Difference
 ↓
Human Judgment
 ↓
Revision
 ↓
Rebuild
 ↓
Re-verify
```

也就是说：

> **同一个真实任务贯穿整条工程链。**

---

# 十一、第一批 Dogfood 任务的选择原则

任务应该：

```text
小
真实
可修改
可验证
有一定歧义
但不能过于复杂
```

可以优先选择：

```text
CLI 小改动
GUI 小改动
文档入口小改动
Prompt 行为小改动
测试行为小改动
```

不要一开始选择几十文件的大型功能。

---

# 十二、Dogfood 成功标准

不能只看：

```text
134/134
```

测试通过只是：

> Engineering Green

真正还必须证明：

```text
Dogfood Green
```

至少做到：

```text
我们自己提交一个真实任务
        ↓
AsWish 接住自然语言
        ↓
AI 帮助理解
        ↓
人确认
        ↓
形成可见 Baseline
        ↓
Agent 实施
        ↓
产生 Evidence
        ↓
看到实施结果
        ↓
发现 Difference
        ↓
人做判断
        ↓
人提出 Revision
        ↓
再次实施
        ↓
再次看到结果
```

---

# 十三、First Closed Loop 最终验收

真正的 First Closed Loop 必须满足：

```text
Human Intent
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
    ↓
Rebuild
    ↓
Re-verification
```

并且：

> **至少真实完整跑通一次第二轮 Revision。**

只有：

```text
Build
→
Look
→
Done
```

不算 First Closed Loop。

---

# 十四、不要新增平行实体

在整理 PRD / 工单时严格遵守：

禁止因为上述视觉流程新增：

```text
VisualState
Proposal
ParallelCandidate
ChangeObject
NewDecisionSystem
NewImpactGraph
```

优先复用：

```text
CandidateIngest
Decisions
Snapshot
Render
TreeBuilder
SpecStore
Prompts
现有 Semantic Bundles
```

---

# 十五、0027A → 0027B → 0027C → 0027D 的产品能力变化

请在开发路线中用这样的方式表达：

### 0027A

```text
我想改什么？
```

输出：

```text
Human Intent
```

---

### 0027B

```text
你的意思是不是这样？
```

输出：

```text
Candidate / Change Set
```

Human 决定：

```text
Accept
Reject
Unresolved
```

---

### 0027C

```text
我们确认的到底是什么？
```

输出：

```text
Decision
+
可见 Baseline
```

---

### 0027D

```text
Agent 按我们确认的东西去做。
```

输出：

```text
Implementation
```

---

### Evidence v0

```text
Agent 实际做了什么？
```

输出：

```text
Implementation Evidence
```

---

### Difference v0

```text
实际做出来的东西和我们确认的东西哪里不同？
```

输出：

```text
Difference
```

---

### Human Confirmation

```text
这个 Difference 我接受吗？
```

输出：

```text
Acceptable
Unacceptable
Unresolved
```

---

### Revision

```text
我要怎么改？
```

重新回到：

```text
Human Intent
```

于是形成真正循环。

---

# 十六、PRD 中请明确一个非常重要的产品判断

不要把 AsWish 做成：

> 一个更加复杂的 Spec 编辑器。

而应该保持：

> **人类用自然语言表达，AI 协助显影、理解、建构和实现；人类在关键节点通过“看见”来确认。**

因此：

```text
Human
不会直接编辑 Spec

Human
不会直接编辑复杂结构

Human
主要通过自然语言 + 可见结果进行判断
```

---

# 十七、请输出 / 更新的资料

根据仓库现有文档治理体系，找到最合适的已有：

```text
PRD
Product Blueprint
Development Roadmap
WO
Engineering Tasks
```

进行更新。

不要因为本次任务随意新造一套平行 PRD 体系。

至少要让资料最终能够回答：

```text
1. 为什么现在进入 First Closed Loop
2. 为什么 AsWish 必须自己 Dogfood
3. 工程票的依赖顺序是什么
4. 每一票完成什么
5. 每一票 Engineering Acceptance 是什么
6. 每一票 Dogfood Acceptance 是什么
7. First Closed Loop 如何验收
8. SVG / Visual Representation 在哪些阶段出现
9. Current State / Baseline / Implementation / Difference / Revision 各自怎么看
10. 为什么不需要新增 VisualState 等平行实体
```

---

# 十八、特别重要：不要修改产品战略

不要重新讨论：

```text
As Wish
As We Wish
AsWish
Difference Monism
产品命名
核心口号
理论定位
```

这些已经冻结。

不要增强、削弱或重新解释理论。

如果现有文档与本任务出现冲突：

```text
指出冲突
↓
记录
↓
不要自行裁决
```

---

# 十九、最终交付

请：

1. 阅读当前 PRD / Blueprint / Roadmap / WO；
2. 找到最合适的文档位置；
3. 把上述内容正式写入现有开发资料；
4. 明确哪些是“当前已经实现”；
5. 明确哪些是“下一步开发”；
6. 明确哪些是“未来阶段，不属于当前票”；
7. 给出一份更新后的开发顺序；
8. 给出每票的 Engineering / Dogfood Acceptance；
9. 单独整理一份 **SVG / Visual Checkpoint Matrix**；
10. 不修改代码。

---

# 二十、SVG / Visual Checkpoint Matrix 必须出现

至少整理成：

| 阶段 | 人看到什么 | 为什么需要看到 | 是否形成可复现 Baseline | 是否需要 Difference |
|---|---|---|---|---|
| Current State | 当前真实结构 | 显影 | 否 | 否 |
| Confirmed Baseline | 人确认后的目标表现 | 决策确认 | 是 | 否 |
| Implementation Result | Agent 实际结果 | 验证 | 是/可复现 | 是 |
| Difference | Baseline vs Result | 看见变化 | 否 | 是 |
| Revised Result | 修正后的结果 | 再验证 | 是 | 再比较 |

对“是否需要重新生成 SVG”，不要机械回答“每阶段都生成”。

请根据现有 Render / Snapshot 能力判断：

> **哪些阶段应该复用现有 SVG，哪些阶段必须产生新的视觉结果，哪些阶段只需要比较两个已有结果。**

最终形成：

```text
AsWish Visual Checkpoint Matrix v0
```

但除非当前文档治理规定需要单独建文件，否则优先写入现有 PRD / Blueprint / Roadmap。

---

最后请汇报：

```text
[资料更新完成]

更新了哪些 PRD / Roadmap / WO：
...

新增 / 调整的工程阶段：
...

新增的 Dogfood 要求：
...

新增的 SVG / Visual Checkpoint Matrix：
...

下一张最应该执行的工程票：
...

是否发现战略 / 理论冲突：
是 / 否
```

**本任务是资料更新任务，不执行代码修改。**
:::

我特别建议资料 AI 把 **SVG / Visual Checkpoint Matrix** 单独整理出来。这样我们下一步讨论工程拆票时，就可以把“画什么图、什么时候画、谁确认、图和哪个状态绑定”直接落到每一票的验收标准里，而不是后面再补视觉层。

========================================================================
[消息 8/11]  长度=10931
========================================================================
我认为下一步**不应该继续拆代码票**，而应该先把：

# First Closed Loop v0 的“行为标准与边界”定死

因为现在我们已经知道“要做什么”，但还没有把下面几个问题压实：

> **做到什么程度，才叫 AsWish 真正完成了一次闭环？**

以及：

> **哪些东西必须让用户看见？哪些东西必须由人确认？哪些事情 AsWish 绝不能替人做？**

这一步一旦定清楚，后面的 0027B、0027C、0027D、Evidence、Difference 才不会各自长出自己的解释。

---

# 一、下一轮我们应该讨论的核心内容

我建议只讨论 6 件事。

## 1. 定义 First Closed Loop v0 的“最小实例”

不是抽象流程，而是一个**最小可运行案例**。

明确：

```text
一个人
+
一个真实问题
+
一个真实修改意图
+
一次 AI 理解
+
一次人类确认
+
一次 Agent 实施
+
一次实施结果
+
一次 Difference
+
一次人类判断
+
至少一次 Revision
+
再次实施
```

最终必须回答：

> 什么情况下，我们可以说“这个闭环真的跑通了”？

---

## 2. 定义每个阶段的“输入 / 输出 / 人的动作 / 可见结果”

这是最重要的一张表。

例如：

| 阶段 | 输入 | AI做什么 | 人做什么 | 必须看到什么 | 产生什么 |
|---|---|---|---|---|---|
| Intent | 自然语言 | 接收/澄清 | 表达 | 当前对象 | Intent |
| Construct | Intent | 提出理解 | 判断 | 候选理解 | Candidate |
| Confirm | Candidate | 解释 | Accept/Reject | 确认对象 | Decision |
| Baseline | Decision | 呈现 | 确认 | SVG/可见结果 | Baseline |
| Build | Baseline | 实施 | 观察 | 过程/结果 | Implementation |
| Evidence | Implementation | 汇总事实 | 查看 | 证据 | Evidence |
| Difference | Baseline+Result | 找差异 | 判断 | 差异 | Difference |
| Revision | Difference | 提议修改 | 决定 | 修订后结果 | 下一轮 |

这里才会真正把你刚才强调的：

> **所有见及所得，必须通过这个流程体现出来**

落实下来。

---

# 3. 定义“人”和“AI”的不可越过边界

这个要非常硬。

例如：

### Human 必须拥有

```text
Intent
Accept / Reject
Decision
Difference 判断
Final Confirmation
Revision 决定
```

### AI 可以做

```text
Ask
Explain
Suggest
Transform
Render
Implement
Inspect
Surface Difference
```

### AI 永远不能做

```text
把猜测当确认
把 Candidate 当 Decision
把 Difference 当 Error
未经确认修改 Canonical Spec
未经确认结束闭环
```

这一部分以后就是所有工程票的总门禁。

---

# 4. 定义“什么必须被看见”

这是你刚刚提出的 SVG 问题的更上层标准。

不要直接规定：

> “这里必须画 SVG”。

应该规定：

> **凡是要求人作判断的对象，必须有可观察表现。**

然后再让 SVG 成为当前的主要实现手段。

也就是：

```text
Need Human Judgment
        ↓
Must Be Observable
        ↓
Current Implementation = SVG / Visual Render
```

这样以后即使未来不是 SVG，也不会破坏产品原则。

---

# 5. 定义每个视觉检查点的最低标准

建议形成：

### Visual Checkpoint v0

只定义 5 个检查点：

```text
VC-01 Current State
VC-02 Confirmed Baseline
VC-03 Implementation Result
VC-04 Difference
VC-05 Revised Result
```

但是这里最关键的不是“有五张 SVG”。

而是：

> **每一个检查点，用户到底要看见什么，才能完成他的判断？**

例如：

### Current State

回答：

> “现在是什么？”

### Confirmed Baseline

回答：

> “我们确认我要的是什么？”

### Implementation Result

回答：

> “实际做出来是什么？”

### Difference

回答：

> “哪里不一样？”

### Revised Result

回答：

> “修完以后是不是现在这个？”

---

# 6. 定义“完成”和“不完成”

这是最容易被工程偷换掉的地方。

例如：

### 不算闭环

```text
AI 生成代码
✓

Build 成功
✓

Tests 全绿
✓

```

但：

```text
人没有确认 Baseline
→ 不算

没有 Implementation Evidence
→ 不算

没有 Difference
→ 不算

没有 Human Judgment
→ 不算

没有第二轮 Revision
→ 不算 First Closed Loop
```

---

# 二、这一轮资料 AI 真正应该整理的，不是普通 PRD

我建议让它形成一个非常核心的文件：

# `FIRST-CLOSED-LOOP-V0-BOUNDARY-AND-ACCEPTANCE`

名字可以由现有文档治理体系决定，不必照这个名字建文件。

它的职责只有一个：

> **定义“什么才叫 AsWish 的第一个闭环”。**

而不是设计所有未来功能。

内容最好分成：

```text
1. Purpose
2. Scope
3. First Closed Loop Definition
4. Stage Model
5. Human / AI Boundary
6. Observable / Visual Standard
7. Artifact Boundary
8. Acceptance Gates
9. Dogfood Protocol
10. Failure / Non-completion Conditions
11. Explicit Non-goals
12. Mapping to 0027A → 0028 → Difference → Revision
```

---

# 三、另外单独把“标准”和“实现”分开

这个特别重要。

资料 AI 要明确区分：

### Product Standard

必须做到：

```text
Human can see
Human can judge
Human confirms
Difference is visible
Revision is explicit
```

### Engineering Implementation

当前可以采用：

```text
YAML
Snapshot
Render
SVG
CandidateIngest
Decisions
Prompt
Agent
CLI / GUI
```

但这些都属于：

> **当前实现方式**

不能反过来成为产品定义。

否则以后很容易出现：

> “因为现在 SVG 是这样实现的，所以 AsWish 的概念就是 SVG 状态机。”

我们不要走这个方向。

---

# 四、Dogfood 也应该标准化

下一步还应该正式规定：

> **AsWish 如何使用自己。**

最小 Dogfood Protocol：

```text
Dogfood Task
 ↓
Intent
 ↓
Construct
 ↓
Human Confirm
 ↓
Visual Baseline
 ↓
Agent Build
 ↓
Evidence
 ↓
Difference
 ↓
Human Judgment
 ↓
Revision
 ↓
Agent Build Again
 ↓
Final Verification
```

每一步必须留下最小证据。

但**不要求一开始就做复杂的 Case 管理系统**。

---

# 五、所以你现在可以直接把下面这段给资料 AI

:::writing{variant="chat_message" id="31467"}
继续作为 AsWish 的产品工程资料 AI。

现在不要继续扩展功能，也不要写代码。

我们需要把前面已经形成的工程节奏进一步**标准化、边界化、验收化**。

这一次的核心任务是：

# Formalize “First Closed Loop v0”

请以现有 AsWish 的 PRD / Blueprint / Roadmap / WO / 文档治理体系为基础，整理并写入最合适的现有文档位置。

如果现有体系已经有合适的文档，就优先修改现有文档，不要创建平行文档体系。

---

# 一、当前总体原则

AsWish 当前阶段：

```text
Stage 1 → Stage 2
First Contact → First Closed Loop
```

第一目标不是功能数量，而是：

> **AsWish 自己使用 AsWish，真实完成一个完整闭环。**

也就是说：

> **AsWish 是自己的第一个 Dogfood 用户。**

---

# 二、请正式定义 First Closed Loop v0

目标不是解释理论，而是建立一个：

> **可实现、可观察、可验收的最小产品闭环。**

建议主链：

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

注意：

不要因为这条链创建新的平行实体。

优先复用现有：

```text
CandidateIngest
Decisions
Snapshot
Render
SpecStore
Prompts
现有协议
```

---

# 三、为每个阶段建立统一标准表

至少包含：

| Stage | 输入 | AI职责 | Human职责 | 必须可见什么 | 产物 | 完成条件 | 不完成条件 |
|---|---|---|---|---|---|---|---|

重点不是技术实现，而是：

> **用户实际经历什么。**

例如：

### Intent

Human 用自然语言表达。

AI 可以接收和澄清。

不能自动修改 Canonical Spec。

---

### Candidate / Interpretation

AI 表达：

> “我理解你可能是这个意思。”

Human 必须能够判断。

不能把 AI 理解直接当成 Decision。

---

### Confirmation

Human 明确：

```text
Accept
Reject
Unresolved
```

确认后的内容才能进入 Baseline。

---

### Visual Baseline

必须让 Human 能看到：

> “我们刚才确认的到底是什么。”

---

### Implementation

Agent 根据已确认内容实施。

---

### Evidence

必须能够回答：

> “Agent 实际做了什么？”

Evidence 是事实记录，不是 AI 自我评价。

---

### Difference

必须能够回答：

> “确认的东西和实际产生的东西哪里不同？”

第一版可以只做结构差异。

不要把 Difference 自动定义为 Error。

---

### Human Judgment

Human 判断：

```text
No important difference
Acceptable difference
Unacceptable difference
Unresolved
```

AI 不得代替 Human 做最终判断。

---

### Revision

如果 Human 判断需要修改：

```text
Revision Intent
→
重新进入已有流程
```

而不是建立第二套修改机制。

---

# 四、正式定义 Human / AI Boundary

请建立明确边界：

## Human owns

```text
Intention
Judgment
Decision
Accept / Reject
Difference Judgment
Final Confirmation
Revision Decision
```

## AI may

```text
Discover
Ask
Explain
Suggest
Transform
Generate
Render
Implement
Inspect
Surface Difference
```

## AI must not

```text
把推测当确认
把 Candidate 当 Decision
把 Difference 当 Error
未经确认修改 Canonical Spec
未经确认结束闭环
代替 Human 完成最终判断
```

这部分应作为所有后续工程票的共同门禁。

---

# 五、正式定义“所见即所得”的产品标准

不要把它定义成：

> 每个阶段必须生成一张 SVG。

正确的上层原则应该是：

> **凡是要求 Human 作判断的对象，都必须具有稳定、可观察、可重复查看的表现。**

当前主要实现方式可以是：

```text
Visual Render / SVG
```

但：

> SVG 属于当前工程实现，不等于产品理论定义。

---

# 六、建立 Visual Checkpoint v0

正式定义以下最小视觉检查点：

```text
VC-01 Current State
VC-02 Confirmed Baseline
VC-03 Implementation Result
VC-04 Difference
VC-05 Revised Result
```

建立：

# Visual Checkpoint Matrix v0

至少包含：

| Checkpoint | Human 要看到什么 | Human 要判断什么 | 数据来源 | 是否形成稳定基线 | 是否参与 Difference |
|---|---|---|---|---|---|
| Current State | 当前真实结构 | “现在是什么？” | 现有 Spec / Render | 否 | 否 |
| Confirmed Baseline | 已确认目标 | “这就是我要的吗？” | Confirmed understanding | 是 | 是 |
| Implementation Result | Agent 实际结果 | “做出来了吗？” | Implementation Evidence / 实际结果 | 可复现 | 是 |
| Difference | 两者变化 | “哪里不同？” | Baseline vs Result | 否 | 是 |
| Revised Result | 修改后的结果 | “这次对了吗？” | Revision + Implementation | 是 | 再比较 |

特别注意：

> 不要机械要求每个 checkpoint 新生成独立 SVG。

请研究和记录：

```text
哪些阶段可以复用现有 Render；
哪些阶段需要新的视觉结果；
哪些阶段只是比较两个已有结果。
```

优先复用现有：

```text
Render
Snapshot
Tree
SpecStore
```

不要新增：

```text
VisualState
VisualObject
NewBaselineEntity
```

---

# 七、正式定义“双绿灯”验收

以后工程票统一：

```text
Engineering Green
+
Dogfood Green
```

## Engineering Green

至少检查：

```text
Build
Tests
CLI / GUI
Protocol
Regression
Git diff
```

## Dogfood Green

至少证明：

```text
真实任务
真实人类
真实 AsWish
真实 Agent
真实结果
```

而不是只通过自动化测试。

---

# 八、正式定义 First Closed Loop 的最终验收

至少真实完整跑通：

```text
同一个任务
↓
Intent
↓
Candidate / Interpretation
↓
Human Confirmation
↓
Visual Baseline
↓
Agent Implementation
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

必须至少出现：

> **第二轮 Revision / Rebuild。**

以下不能视为 First Closed Loop：

```text
Build 成功
Tests 全绿
Agent 说 Done
Human 看一眼
```

---

# 九、Dogfood Protocol v0

请正式定义 AsWish 第一个自用任务的最小要求。

任务必须：

```text
小
真实
可修改
可验证
有一定歧义
```

不要使用一个复杂的大型功能作为第一案例。

一旦选择 Dogfood Task：

> **同一个任务贯穿所有阶段，不要每一票换一个 Demo。**

---

# 十、定义“不完成”条件

明确哪些情况不能宣布 First Closed Loop 成功。

至少包括：

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

---

# 十一、明确当前阶段 Non-goals

这一版不要纳入：

```text
SaaS
Team
Enterprise
Agent Orchestrator
复杂 Case 平台
大型 Benchmark
自动 Difference 归因
视觉像素级 Difference
自动理论推导
多语言 AST
社区体系
```

也不要设计完整的未来 Case System。

当前只解决：

> **First Closed Loop v0**

---

# 十二、将 0027A → 0027B → 0027C → 0027D → Evidence → Difference → Revision 映射到 First Closed Loop

建立一张路线映射表：

| 工程票 / 阶段 | 解决什么问题 | First Closed Loop 中的位置 | Engineering Acceptance | Dogfood Acceptance |
|---|---|---|---|---|

当前建议：

```text
0027A
我想改什么？

0027B
你的意思是不是这样？

0027C
我们确认的到底是什么？

0027D
Agent 按确认内容做。

0028 / Evidence v0
Agent 实际做了什么？

Difference v0
实际结果与确认内容哪里不同？

Human Confirmation
这个 Difference 是否接受？

Revision
我要求怎么改？
```

---

# 十三、最重要的边界：标准 ≠ 实现

请明确区分：

## Product / Behavioral Standard

规定：

```text
Human must see
Human must judge
Human must confirm
Difference must be visible
Revision must be explicit
```

## Current Engineering Implementation

当前可以采用：

```text
CandidateIngest
Decision
Snapshot
Render
SVG
YAML
CLI
GUI
Agent
```

不要让当前实现反过来定义产品概念。

---

# 十四、最终资料必须回答 12 个问题

整理完成后，项目文档必须能够直接回答：

```text
1. 什么叫 First Closed Loop？
2. 最小闭环需要哪些阶段？
3. 每阶段 Human 做什么？
4. 每阶段 AI 做什么？
5. 哪些决定 Human 必须拥有？
6. 哪些事情 AI 禁止做？
7. 什么东西必须被看见？
8. SVG 在哪里出现？
9. 什么叫 Visual Baseline？
10. 什么叫 Implementation Evidence？
11. 什么叫 Difference v0？
12. 什么条件下可以宣布 First Closed Loop 成功？
```

---

# 十五、执行要求

这次只修改产品 / 开发资料：

> **不要修改代码。**

先阅读当前：

```text
ASWISH-PRODUCT-IDENTITY.md
ASWISH-DOCUMENTATION-GOVERNANCE.md
AGENTS.md
SPEC.md
现有 PRD / Blueprint
现有 Roadmap
现有 0027A～0028 工单
```

然后：

1. 找到最合适的现有文档位置；
2. 写入 First Closed Loop v0 的标准与边界；
3. 写入 Visual Checkpoint Matrix v0；
4. 写入 Engineering / Dogfood 双验收；
5. 写入 Human / AI Boundary；
6. 写入 Non-goals；
7. 写入工程票映射；
8. 不修改代码；
9. 不重新讨论产品命名和理论定位。

最后报告：

```text
[资料更新完成]

更新文档：
...

First Closed Loop v0：
已定义 / 未定义

Visual Checkpoint Matrix：
已定义 / 未定义

Human / AI Boundary：
已定义 / 未定义

Engineering / Dogfood 双验收：
已定义 / 未定义

当前下一步：
...

发现冲突：
是 / 否
```
:::

---

# 六、资料 AI 做完后，我们下一步就很好办了

到那时我们**不要立刻继续开 0027B**。

我们先拿它整理出来的标准，做一次非常具体的讨论：

> **“第一个 AsWish Dogfood 任务，究竟选什么？”**

一旦这个真实任务选定，后面所有工程票都围绕**同一个任务**走。

比如：

```text
AsWish 内部某个 GUI/CLI 小问题
        ↓
0027A
        ↓
我们第一次用 AsWish 说出它
        ↓
0027B
        ↓
我们看 AI 理解
        ↓
0027C
        ↓
我们确认
        ↓
SVG Baseline
        ↓
0027D
        ↓
让 Agent 做
        ↓
Evidence
        ↓
SVG Result
        ↓
Difference
        ↓
人判断
        ↓
Revision
```

这时候，**工程节奏、PRD、SVG、Dogfood、验收标准就真正合成一件事情了。**

而我认为这才是现在 AsWish 最值得做的下一步：**先把“闭环是什么”标准化，再用一个真实小任务把它跑出来。**

========================================================================
[消息 9/11]  长度=2721
========================================================================
我已经把资料 AI 整理出的 `AsWish 工程路线与 Dogfood 验收 v1` 看完了。它已经把我们上一轮讨论的核心东西正式化了，尤其是**双闸门、同一 Dogfood 任务贯穿、First Closed Loop 硬条件、SVG/Visual Checkpoint**，这一版方向是对的。fileciteturn3file0L25-L42

现在我认为**不要继续泛化 PRD，也暂时不要继续拆工单**。下一步应该进入一个更关键的讨论：

# 把“人到底看见什么，才算看见”标准化

这是目前 AsWish 最容易继续模糊的地方。

资料已经定义：

```text
Current State
Confirmed Baseline
Implementation Result
Difference
Revised Result
```

也定义了：

> 凡是要求 Human 作判断的对象，都必须具有稳定、可观察、可重复查看的表现。

但是还缺一层：

> **什么信息必须进入这个“可见表现”？**

否则最后很容易变成：

```text
有 SVG
✓

有 Preview
✓

但人仍然不知道：
“这个到底是不是我刚才确认的东西？”
```

---

# 我建议下一轮只讨论 5 个标准

## 1. “看见”到底服务于哪个判断

不要先讨论 SVG 长什么样，而是先定义：

| 检查点 | 人到底在判断什么 |
|---|---|
| Current State | 现在究竟是什么 |
| Candidate | AI 理解的是不是我的意思 |
| Confirmed Baseline | 这是不是我确认的目标 |
| Implementation Result | Agent 实际做出来的是什么 |
| Difference | 哪些地方发生了变化 |
| Revised Result | 修正后是不是我现在要的 |

这会把视觉系统从“画图”提升为：

> **Human Judgment Interface**

---

## 2. 什么是“可见对象”

比如一个 View Spec，不能只要求：

```text
SVG 能渲染
```

而要规定最低信息：

```text
对象身份
结构层级
关键属性
关系
状态
修改位置
```

否则不同阶段虽然都能画图，人却无法有效比较。

---

## 3. Baseline 到底“冻结”什么

现在文档已经明确：

> Accepted Visual Baseline = 现有 `SpecSnapshot` + 视觉绑定，不新建独立 Baseline 实体。fileciteturn3file0L665-L760

下一步应该定义：

> **冻结的是“图”本身，还是“可生成这张图的状态”？**

我倾向后者。

也就是：

```text
Baseline
≠ 一张 SVG 文件

Baseline
= 某个已确认 Snapshot
  +
确定 Renderer
  +
确定视觉表现
```

这样以后才能稳定重现和比较。

---

# 4. Difference 的“看见标准”

现在路线已经正确地明确：

> Difference ≠ Error。fileciteturn3file0L865-L960

但是还要再定义一个东西：

> **Difference 最少要让人看到什么？**

我建议 v0 不要追求智能解释。

至少做到：

```text
Baseline
    ↓
[Node A]
  title: X → Y
[Node B]
  removed
[Node C]
  added
```

然后再让 Human 判断：

```text
Acceptable
Unacceptable
Unresolved
```

这样“看见 Difference”与“解释 Difference”是分开的。

---

# 5. 最后定义一个总的 Visual Acceptance Gate

我建议形成一个非常简单的硬标准：

> **任何要求人作判断的状态，如果人无法仅通过当前可见表现回答“我要不要接受”，则该状态不算可验收。**

这个标准以后可以成为所有 Visual / SVG 工程票的总门禁。

---

# 还有一个资料 AI 已经暴露出来的问题

这不是让我去审代码，而是**项目资料内部状态需要先统一**。

文档前面说：

```text
0027A 已完成
0027B 已完成
0027C 进行中
```

但后面“已实现 / 下一步”的记录又出现：

```text
当前 main HEAD c20536b
```

而我们此前拿到的工程交接事实是：

```text
27c268d
```

同时文档自己还明确登记了：

> **D0 尚未冻结，但 B 已落地，C 已经具备写回能力。** fileciteturn3file0L1427-L1445

这个问题我不会替你裁定。

但资料 AI 下一轮应该把它作为：

```text
Engineering State Consistency
```

单独整理出来，避免后面开发 AI 按文档错误判断“哪一票已经完成”。

---

# 所以我建议我们的下一轮讨论顺序

不是：

```text
继续拆 0027E
```

而是：

```text
① Visual Judgment Standard
        ↓
② Baseline Standard
        ↓
③ Difference Visibility Standard
        ↓
④ Dogfood 实际任务
        ↓
⑤ 再据此拆下一张工单
```

其中**最值得我们现在花时间讨论的是第 ① 项**：

# “AsWish 的 See 到底是什么？”

因为一旦这个定义清楚：

```text
SVG 怎么画
什么时候 Render
什么叫 Baseline
Difference 怎么显示
Revision 怎么重新看
```

都会自然收敛。

而不是工程师每张票自己决定“画一张图就算完成”。

资料 AI 已经把路线骨架搭好了；现在我们应该开始把 **“See / 看见”这个产品行为标准**钉死。fileciteturn3file0L666-L760

========================================================================
[消息 10/11]  长度=22513
========================================================================
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
>
> * 产品功能架构、七环闭环、所见即所得与视觉阶段：见 [`AsWish-产品功能与愿景蓝图-v1.md`](AsWish-产品功能与愿景蓝图-v1.md)
>
> - 协议与 `.AsWish/` 结构：权威见 [`../SPEC.md`](../SPEC.md) 与 [`../protocol/`](../protocol/)
>
> * 工程纪律、门禁与提交规则：见 [`../AGENTS.md`](../AGENTS.md)
>
> - 文档治理与权威注册表：见 [`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md)
>
> * 各票原始需求与 AC：见 `WO/` 下对应工单；**工单原文为需求权威，本文只定义路线顺序与双闸门验收**

---

## 一、为什么现在进入 First Closed Loop

AsWish 当前阶段判定：

```
```

进入 Stage 2 的理由是工程性的，不是市场性的：

- 主链**前半段**（意图承载 → 结构化解释 → 决策）已有真实代码，但**后半段**（实现证据 → 差异 → 人类裁决 → 修订）在代码层仍为空白；

* 未跑通整条链之前，任何"Difference 被看见"的主张都只是设计稿，不构成工程证据；

- 公开发布的第一个实验若由第三方完成，失败成本与解释成本都由第三方承担；由 AsWish 自己先承担，才能确定链本身是否成立。

因此 Stage 2 的第一目标不是"功能变多"，而是：

> **让 AsWish 成为自己的第一个真实用户，亲自用 AsWish 完成一次完整闭环。**

即：

> **AsWish 自己开发 AsWish，同时使用 AsWish 验证 AsWish。**

---

## 二、为什么 AsWish 必须自己 Dogfood

三条工程理由：

1. **可信度**：`Test my claim` 的前提是 claim 先在自己身上被检验。自己不跑，无权邀请第三方跑。

1) **反例优先权**：最有可能推翻 AsWish 主张的，是真实使用中的失败。Dogfood 让失败先发生在内部，成本最低。

1. **链的完整性不可分段证明**：单独证明"能生成 Change Set"或"能渲染"都不等于闭环。只有同一任务贯穿全程，才能证明链是连通的。

Dogfood 不是演示，不是营销，是**主张的自检验**。

---

## 三、双闸门：Engineering Green + Dogfood Green

工程推进不再以"代码完成 + 测试通过"为唯一放行条件。每一票必须过两道门：

```
```

两者的分工：

|   |
| - |

闸门

|   |
| - |

回答的问题

|   |
| - |

证明方式

|   |
| - |

**Engineering Green**

|   |
| - |

这一票的代码是否正确、可回归、可交付？

|   |
| - |

build 原始输出存档 + DUnitX 全量通过 + 主控独立复核

|   |
| - |

**Dogfood Green**

|   |
| - |

这一票的能力在真实使用中真的被用起来了吗？

|   |
| - |

用 AsWish 自身任务跑通本票环节，产生真实工程证据

> 只过 Engineering Green **不等于完工**。
> `134/134` 只是 Engineering Green，不是 Dogfood Green。

### Engineering Green 检查单

```
```

### Dogfood Green 检查单（"五真实"，缺一不可）

```
```

> 自动化测试通过**不能替代**以上任何一项。

门禁执行细则（build/test 证据存档、单 commit 规模、APPROVED/RETURNED）以 [`../AGENTS.md`](../AGENTS.md) 与《非睿智轻量门禁规范-v1》为准。

---

## 四、工单依赖顺序

正式采用的顺序：

```
```

纪律：

- **不并发扩展整套生态**。一次只推一票，一票过双闸门才进下一票。

* **0027D 拆成两个里程碑**：D0 是 B/C 的协议前置，D1 是收口。工单原文见 `WO/WO-20260830-0027D-甲-证据链与协议落盘工单.md` §二。

- 0028 与 Difference v0 **不得合并**（工单原文 §十二明确"两票不得合并"）。

---

## 五、工单统一模板

以后每一票至少包含以下 8 项，缺项不得开工：

```
```

模板用法见 §六每票实例；工单原文的 Goal / Implementation / Test 仍保留在 `WO/` 中，本文不复制。

---

## 六、每票能力变化与双闸门验收

### 6.1 WO-20260830-0027A · CandidateIngest 自然语言修订入口

**产品问句**：我想改什么？
**输出**：`Human Intent`

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

人类用自然语言告诉 AsWish"我想改什么"，意图被承载并持久化

|   |
| - |

2\. 明确不解决什么

|   |
| - |

AI 解释意图、Change Set、自动修改 Spec、完整 Decision、Difference

|   |
| - |

3\. 工程完成条件

|   |
| - |

CLI `intent` 可提交；持久化到 `.AsWish/llm/candidate-intent.yaml`；不清晰时复用 `grilling_ticket`

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

用 CLI `intent` 提交一个针对 AsWish 自身的真实修改意图

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

意图原文被原样保存，未触发任何 Canonical Spec 变更

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

落盘可回读；grilling 分支可触发；DUnitX 全量通过；build 输出存档

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

存在一个由真实任务产生的 `candidate-intent.yaml`，可追溯到具体节点

|   |
| - |

8\. 完成后进入

|   |
| - |

0027B

> 边界纪律：`Human Natural Language → Automatic Spec Mutation` 是被明确禁止的形态。本票只承载，不解释、不改 Spec。

**状态**：✓ 已实现并入 `main`（`27c268d`）。

---

### 6.2 WO-20260830-0027B · 结构化 Change Set

**产品问句**：你的意思是不是这样？
**输出**：`Candidate / Change Set`
**人类决定**：Accept / Reject / Unresolved

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

把 0027A 的自然语言意图，经 LLM 解释成结构化 Change Set

|   |
| - |

2\. 明确不解决什么

|   |
| - |

人类裁决与写回（0027C）、Canonical Spec 修改、视觉表现

|   |
| - |

3\. 工程完成条件

|   |
| - |

`TChangeSet` / `TChangeItem`；`WriteChangeInterpretPrompt`；落盘 `.AsWish/llm/change-set.yaml`；区分 explicit / inferred / unknown

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

对 0027A 已提交的那一条真实意图，生成结构化 Change Set

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

Change Set 可定位到现有 Spec 节点，可表达 Before / After

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

格式往返一致；跨投影影响经 `semantic-bundles.yaml`；不生成第二套 Proposal 生命周期；不写 Canonical Spec；DUnitX 全量通过

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

该真实意图产生的 Change Set 中，至少有一条 `inferred` 或 `unknown` 被人指出"解释错了"或"解释对了"，并记录该判断

|   |
| - |

8\. 完成后进入

|   |
| - |

0027D-D0 → 0027C

> Change Set 是 CandidateIngest 的**解释结果**，不是新的 Proposal 实体。

**状态**：✓ 已实现并入 `main`（`78d8e0c`）。协议 schema 冻结情况见 §十一冲突登记。

---

### 6.3 WO-20260830-0027D · D0 里程碑（Change Set schema 冻结）

**产品问句**：我们用什么结构承载"AI 的解释"？
**输出**：冻结的最小协议 schema

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

冻结 Change Set schema、落盘位置、Decision 关联字段，作为 B/C 的协议前置

|   |
| - |

2\. 明确不解决什么

|   |
| - |

证据链落盘（D1）、实现机制、视觉表现

|   |
| - |

3\. 工程完成条件

|   |
| - |

schema 定义 + 落盘位置 + Decision 关联字段三项冻结并报裁定

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

用 0027B 已产生的真实 `change-set.yaml` 反向校验 schema 是否够用

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

已落盘的真实 Change Set 能被 schema 完整描述，不丢字段

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

schema 通过协议校验；与既有 `decisions` / `trees` 字段不冲突；协议变更记录存档

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

真实 Change Set 文件通过 schema 校验，无需为迁就 schema 删减真实字段

|   |
| - |

8\. 完成后进入

|   |
| - |

0027C

**状态**：未开工。

---

### 6.4 WO-20260830-0027C · Change Set 审阅与 Decisions 写回

**产品问句**：我们确认的到底是什么？
**输出**：`Decision` + 可见 Baseline 前的一致性确认

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

人类用现有 `Decisions` 裁决 Change Set；Accept 后才写回 Canonical Spec

|   |
| - |

2\. 明确不解决什么

|   |
| - |

视觉基线（0028）、实现证据、Difference；不新建裁决实体

|   |
| - |

3\. 工程完成条件

|   |
| - |

语义化 Review 展示（非 YAML Diff）；Decision 可引用具体 change 项；Accept 触发写回并复用 `CandidateIngest` merge 语义

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

对 0027B 产生的真实 Change Set 做出真实裁决（至少一次 Reject 或修正）

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

人类能看懂 Change Set；Reject 不改 Spec；Accept 才改；重开项目状态一致

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

AC-01～AC-06（见工单原文）；写回后自动执行现有验证；DUnitX 全量通过

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

至少发生一次**真实的人类否决或修正**，且该否决导致 Change Set 与后续 Spec 状态发生改变，证据可追溯

|   |
| - |

8\. 完成后进入

|   |
| - |

0027D-D1 → 0028

> Decision 是唯一人类裁决事实。禁止 `VisualDecision` / `VisualApproval` / `VisualProposal` / `VisualReviewState` 等平行实体。

**状态**：◐ **进行中（工作树未提交，未入** **`main`****）**。

工作树中已出现的实现面（未提交、未经双闸门）：

```
```

> 上述实现**尚未过 Engineering Green，更未过 Dogfood Green**，不得视为完成。
> 且 `ApplyChangeSet` 已具备写回 Canonical Spec 的能力，而 D0 schema 仍未冻结 —— 风险见 §十一 C-1。

---

### 6.5 WO-20260830-0027D · D1 里程碑（证据链落盘）

**产品问句**：这次确认是怎么来的？
**输出**：可审计的 Spec Revision Provenance

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

形成 `Human NL → CandidateIngest → Change Set → Decision → Committed Spec` 可追溯链

|   |
| - |

2\. 明确不解决什么

|   |
| - |

实现后证据（Evidence v0）、Difference、视觉表现

|   |
| - |

3\. 工程完成条件

|   |
| - |

每次裁决可追溯：输入 / AI 解释 / 提议变更 / 人类裁决 / 最终 Spec

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

把 0027A→B→C 的真实链路记录完整落盘

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

从最终 Spec 能倒查回人类原始自然语言

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

AC-01～AC-02（见工单原文）；证据归档；主控独立复核

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

对真实链路执行一次完整倒查，中途无断点

|   |
| - |

8\. 完成后进入

|   |
| - |

0028

**状态**：未开工。

---

### 6.6 WO-20260830-0028 · Accepted Visual Baseline

**产品问句**：我们确认的东西长什么样？
**输出**：`可见 Baseline`

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

把 View Spec 渲染成可确认、可复现、可追溯的视觉规格基线

|   |
| - |

2\. 明确不解决什么

|   |
| - |

开发后截图比对 / Overlay / Pixel Diff / Drift / 自动改代码 / Agent 调度 / View Spec 布局 schema 扩展（另立票）

|   |
| - |

3\. 工程完成条件

|   |
| - |

结构线框确定性渲染；复用现有 `SpecSnapshot` 承载 Baseline 视觉绑定；`renderer_version` 固定

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

对真实任务对应的 View Spec 生成 Baseline，并由人类确认

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

人类看着 Preview 说出"对，这就是我要的"或"不对"，该判断被记录

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

AC-01～AC-15（见工单原文）；相同 View Spec + Renderer Version 重复渲染一致；旧 Baseline 不被静默覆盖

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

存在一个真实任务产生的 Accepted Visual Baseline，可追溯到 Decision 与 SpecSnapshot

|   |
| - |

8\. 完成后进入

|   |
| - |

Implementation Evidence v0

> 核心架构纪律（工单原文钉死）：**Accepted Visual Baseline = 现有** **`SpecSnapshot`** **+ 视觉绑定**，不得新建独立 Baseline 实体。

**状态**：未开工。

---

### 6.7 Implementation Evidence v0 · 实现证据

**产品问句**：Agent 实际做了什么？
**输出**：`Implementation Evidence`

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

采集 Agent 实施后的真实结果，作为可比较对象

|   |
| - |

2\. 明确不解决什么

|   |
| - |

自动差异判定、自动质量评分、CI

|   |
| - |

3\. 工程完成条件

|   |
| - |

实现后结果可被再次采集并落盘到 `evidence/`；与 Baseline 建立引用关系

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

让 Agent 实施 6.6 中确认的那个真实任务，并采集证据

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

产生一份真实的实现结果记录，可复现查看

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

证据文件结构可被协议描述；落盘位置明确；DUnitX 全量通过

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

该证据来自真实 Agent 实施，不是人工构造的样例

|   |
| - |

8\. 完成后进入

|   |
| - |

Difference v0

**状态**：未开工，**当前无对应工单**（需立票）。

---

### 6.8 Difference v0 · 差异

**产品问句**：实际做出来的东西，和我们确认的东西哪里不同？
**输出**：`Difference`

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

让 Baseline 与实现结果之间的结构差异被看见

|   |
| - |

2\. 明确不解决什么

|   |
| - |

自动判定对错；Pixel Diff；自动修复

|   |
| - |

3\. 工程完成条件

|   |
| - |

v0 先做**结构差异**；诚实标注当前不含视觉比对

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

对真实任务的 Baseline 与 Evidence 做一次差异计算

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

人类能看见差异清单，即便结论是"没有重要差异"

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

差异结果可复现；结构差异项可定位到节点；DUnitX 全量通过

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

真实跑出一次差异结果，且允许结论为「无重要差异 / 可接受差异 / 不可接受差异 / 未决」中的任意一种

|   |
| - |

8\. 完成后进入

|   |
| - |

Human Confirmation

> `Difference ≠ Error`。追求 Difference made visible, traceable, and judgeable，不追求 Zero Difference。
> 实验必须允许得到"没有重要差异"或"存在可接受差异"的结果。

**状态**：未开工，**当前无对应工单，代码层为 0**（需立票）。

---

### 6.9 Human Confirmation · 人类裁决

**产品问句**：这个 Difference 我接受吗？
**输出**：`Acceptable` / `Unacceptable` / `Unresolved`

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

把实现结果回到人类面前，由人类对 Difference 做出判断

|   |
| - |

2\. 明确不解决什么

|   |
| - |

自动裁决；自动回滚

|   |
| - |

3\. 工程完成条件

|   |
| - |

复用现有 `Decisions` 承载裁决，记录到差异项

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

对 6.8 的真实差异做出真实判断

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

至少一次人类判断被记录，且判断结果不是预设的"通过"

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

裁决可持久化、可回读；与 Difference 项建立引用；DUnitX 全量通过

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

存在一条真实的人类裁决记录，能说明为什么接受或不接受

|   |
| - |

8\. 完成后进入

|   |
| - |

Revision

**状态**：未开工，**当前无对应工单**（需立票）。

---

### 6.10 Revision · 修订与再验证

**产品问句**：我要怎么改？
**输出**：回到 `Human Intent`，形成真正循环

|   |
| - |

项

|   |
| - |

内容

|   |
| - |

1\. 解决什么能力

|   |
| - |

人类基于差异再次提出自然语言修订，重新走完整链

|   |
| - |

2\. 明确不解决什么

|   |
| - |

自动修复；自动重试直到通过

|   |
| - |

3\. 工程完成条件

|   |
| - |

第二轮能复用第一轮全部机制，不新建第二套流程

|   |
| - |

4\. AsWish 自用任务

|   |
| - |

对 6.9 的判断提出真实修订，重跑到再次看见结果

|   |
| - |

5\. 真实使用必须发生什么

|   |
| - |

完整跑通第二轮，并产生 `Baseline v2 / Implementation v2 / Difference v2`

|   |
| - |

6\. Engineering Acceptance

|   |
| - |

第二轮产物可追溯、可与第一轮对比；DUnitX 全量通过

|   |
| - |

7\. Dogfood Acceptance

|   |
| - |

**至少真实完整跑通一次第二轮 Revision**，这是 First Closed Loop 的硬条件

|   |
| - |

8\. 完成后进入

|   |
| - |

First Closed Loop 验收

**状态**：未开工，**当前无对应工单**（需立票）。

---

## 七、Dogfood Protocol v0（第一个自用任务）

**不每阶段换一个 Demo。** 选择：

> **一个真实、足够小、确实需要修改的 AsWish 自身任务**

让它一路贯穿：

```
```

### Protocol v0 最小要求

任务必须同时满足：

```
```

**一旦选定：同一个任务贯穿所有阶段，不每一票换 Demo。**
**不使用复杂的大型功能作为第一案例。**

### 选择原则

```
```

### 优先类型

```
```

**不要一开始选择几十文件的大型功能。**

### 第一批候选（供裁定，非决定）

|   |
| - |

候选

|   |
| - |

改动面

|   |
| - |

歧义点

|   |
| - |

备注

|   |
| - |

A. CLI 增加 `intent list` / `intent show` 子命令

|   |
| - |

单文件

|   |
| - |

显示哪些字段、如何排序、未处理意图如何呈现

|   |
| - |

与 0027A 已实现能力直接衔接，歧义适中

|   |
| - |

B. GUI 增加自然语言意图输入入口

|   |
| - |

中等

|   |
| - |

入口位置、与现有命令表的关系

|   |
| - |

同时补 0027A 的 GUI 缺口，但改动面大于 A

|   |
| - |

C. CLI help / 命令文案与排序小调整

|   |
| - |

极小

|   |
| - |

语义分组口径

|   |
| - |

歧义偏少，可能跑不出有意义的 `inferred / unknown`

> **倾向 A**：足够小、真实、可验证，且具备真实歧义，能在 0027B 阶段产生有意义的解释分化。
> **最终选择由主控 / 老板裁定**，一旦选定，**不再更换**。

---

## 八、First Closed Loop v0 · 正式验收

**定义**：First Closed Loop v0 是一个**可实现、可观察、可验收的最小产品闭环**——不是理论解释，而是可以逐阶段打勾的验收对象。

必须真实完整跑通以下主链（同一任务、同一项目）：

```
```

硬性条件：

1. 全程使用**同一个真实任务**；

1) 每一环节都产生**真实工程证据**，不是构造样例；

1. 人类判断是**真实的**，允许出现否决与修正；

1) **至少真实完整跑通一次第二轮 Revision / Rebuild / Re-verification**。

### 不完成条件（出现任何一条，即不得宣布成功）

```
```

以下情况**单独或合计均不构成验收**：

```
```

> 阶段逐项标准（输入 / AI 职责 / Human 职责 / 必须可见什么 / 产物 / 完成条件）见 §十一阶段标准表。

---

## 九、已实现 / 进行中 / 下一步 / Non-goals

### 已实现（当前 `main` HEAD `c20536b`）

|   |
| - |

能力

|   |
| - |

落点

|   |
| - |

自然语言意图承载（0027A）

|   |
| - |

CLI `intent` → `.AsWish/llm/candidate-intent.yaml`

|   |
| - |

结构化 Change Set 解释（0027B）

|   |
| - |

CLI `changeset` → `.AsWish/llm/change-set.yaml`

|   |
| - |

四投影树与 Spec 存储

|   |
| - |

`SpecStore` / `TreeBuilder`

|   |
| - |

渲染与快照

|   |
| - |

`Render` / `Snapshot`（均有对应测试单元）

|   |
| - |

决策机制（通用）

|   |
| - |

`Decisions` 服务

|   |
| - |

追问机制

|   |
| - |

`grilling_ticket` + `WriteGrillingPrompt`

### 进行中（工作树未提交，未过闸门）

|   |
| - |

能力

|   |
| - |

落点

|   |
| - |

Change Set 审阅与 Decisions 写回（0027C）

|   |
| - |

`RunChangeSetReview` / `RunChangeSetAccept` / `ApplyChangeSet` / `RecordChangeSetDecision`

> 未提交代码不视为已实现能力，不参与 First Closed Loop 验收。

### 下一步（First Closed Loop 范围内）

```
```

其中 Evidence v0 / Difference v0 / Human Confirmation / Revision **当前无工单，需立票**。

### Non-goals（当前阶段明确不做）

```
```

> 当前只解决：**First Closed Loop v0**。

---

## 十、禁止新增的平行实体

在 First Closed Loop 全过程中严格遵守：

**禁止新增**

```
```

**优先复用**

```
```

> 何时才允许新增：只有现有协议**确实无法表达**且经主控裁定后，才允许新增最小结构（依据 `WO/WO-20260830-0027D-甲-证据链与协议落盘工单.md` §三）。

---

## 十一、First Closed Loop v0 阶段标准表

> 重点不是技术实现，而是**用户实际经历什么**。各阶段产物落盘位置与协议以 [`../SPEC.md`](../SPEC.md) 与各工单原文为准，本表不复述协议细节。

|   |
| - |

Stage

|   |
| - |

输入

|   |
| - |

AI 职责

|   |
| - |

Human 职责

|   |
| - |

必须可见什么

|   |
| - |

产物

|   |
| - |

完成条件

|   |
| - |

不完成条件

|   |
| - |

1 Human Intent

|   |
| - |

人的自然语言表达

|   |
| - |

接收、澄清（必要时 grilling）

|   |
| - |

用自然语言说清想改什么

|   |
| - |

已提交的意图原文

|   |
| - |

`candidate-intent.yaml`

|   |
| - |

意图被承载并持久化

|   |
| - |

意图被自动解释为 Spec 修改

|   |
| - |

2 Problem Manifestation

|   |
| - |

意图 + 项目上下文

|   |
| - |

显影问题：指出模糊、断口、未知

|   |
| - |

辨认"这确实是我要解决的问题"

|   |
| - |

模糊点与断口可见

|   |
| - |

fog / grilling 状态标注

|   |
| - |

关键断口被指出

|   |
| - |

问题被 AI 擅自"解决"掉

|   |
| - |

3 AI Interpretation / Candidate

|   |
| - |

意图原文 + 节点上下文

|   |
| - |

解释："我理解你可能是这个意思"

|   |
| - |

判断解释对不对

|   |
| - |

结构化 Change Set（语义化展示，非 YAML diff）

|   |
| - |

`change-set.yaml`

|   |
| - |

可定位节点；Before / After 可见；explicit / inferred / unknown 区分

|   |
| - |

把 AI 理解直接当成 Decision

|   |
| - |

4 Human Confirmation

|   |
| - |

Change Set

|   |
| - |

呈现影响、回答追问

|   |
| - |

明确 Accept / Reject / Unresolved

|   |
| - |

裁决界面与裁决结果

|   |
| - |

Decision 记录

|   |
| - |

裁决被记录且可追溯

|   |
| - |

无人类裁决；Reject 仍写回

|   |
| - |

5 Confirmed Understanding

|   |
| - |

Accepted Decision

|   |
| - |

固化确认结果，写回 Canonical Spec（复用 merge 语义）

|   |
| - |

复核写回后的 Spec 状态

|   |
| - |

写回后的 Spec 与 Decision 的关联

|   |
| - |

Committed Spec + provenance

|   |
| - |

写回可追溯；重开项目状态一致

|   |
| - |

未确认内容混入 Spec

|   |
| - |

6 Visual Baseline

|   |
| - |

确认后的 View Spec

|   |
| - |

确定性渲染结构线框

|   |
| - |

看着它说"对，这就是我要的"

|   |
| - |

可重复查看的视觉基线

|   |
| - |

Accepted Visual Baseline（SpecSnapshot + 视觉绑定）

|   |
| - |

相同输入渲染一致；与 Decision / Snapshot 可追溯

|   |
| - |

Baseline 不可复现 / 被静默覆盖

|   |
| - |

7 Agent Development

|   |
| - |

Baseline + Spec + Decisions 导出

|   |
| - |

组装 context-pack 交付；外部 Agent 实施

|   |
| - |

选择并启动 Agent

|   |
| - |

交付内容与实施边界可见

|   |
| - |

Agent 交接记录

|   |
| - |

Agent 按已确认内容实施

|   |
| - |

Agent 收到未确认或矛盾信息

|   |
| - |

8 Implementation Evidence

|   |
| - |

Agent 实际产出

|   |
| - |

**采集事实记录**（不是 AI 自我评价）

|   |
| - |

提供、确认实施事实

|   |
| - |

"Agent 实际做了什么"的原始记录

|   |
| - |

`evidence/` 落盘

|   |
| - |

事实可复现查看

|   |
| - |

只有 AI 声称，无可查记录

|   |
| - |

9 Implementation Result

|   |
| - |

Evidence

|   |
| - |

呈现实际结果

|   |
| - |

查看实际结果

|   |
| - |

实际结果的可视呈现（VC-03）

|   |
| - |

Implementation Result

|   |
| - |

人能看到结果

|   |
| - |

结果不可见、不可复现

|   |
| - |

10 Difference

|   |
| - |

Baseline vs Result

|   |
| - |

计算并呈现结构差异（**不判对错**）

|   |
| - |

看见差异清单

|   |
| - |

差异被看见（VC-04）

|   |
| - |

Difference v0 记录

|   |
| - |

差异可复现、可定位到节点

|   |
| - |

差异被自动定义为 Error / 被隐藏

|   |
| - |

11 Human Judgment

|   |
| - |

Difference

|   |
| - |

呈现证据，不代替判断

|   |
| - |

给出：No important / Acceptable / Unacceptable / Unresolved

|   |
| - |

判断选项与后果可见

|   |
| - |

人类判断记录

|   |
| - |

判断被记录并关联差异项

|   |
| - |

AI 代替人做最终判断

|   |
| - |

12 Revision

|   |
| - |

人类判断

|   |
| - |

接收修订意图（= 回到 Stage 1）

|   |
| - |

用自然语言提出要怎么改

|   |
| - |

修订意图被承载

|   |
| - |

新 `candidate-intent`

|   |
| - |

重新进入既有流程

|   |
| - |

建立第二套修改机制

|   |
| - |

13 Rebuild

|   |
| - |

Revision 意图链

|   |
| - |

重跑 Stage 3 → 9

|   |
| - |

再确认、再实施

|   |
| - |

第二轮产物（v2）

|   |
| - |

Baseline v2 / Implementation v2

|   |
| - |

第二轮真实发生

|   |
| - |

复用第一轮结果冒充

|   |
| - |

14 Re-verification

|   |
| - |

v2 Evidence

|   |
| - |

重新计算 Difference v2

|   |
| - |

再次判断

|   |
| - |

v2 差异可见

|   |
| - |

Difference v2 + 判断

|   |
| - |

判断形成闭环结论

|   |
| - |

无第二轮验证

---

## 十二、Human / AI Boundary（共同门禁）

### Human owns

```
```

### AI may

```
```

### AI must not

```
```

> **本边界是所有后续工程票的共同门禁**：每张工单的 AC 必须包含"不违反边界"的检查项；违反即 RETURNED，不得 CLOSE。

---

## 十三、标准 ≠ 实现

### Product / Behavioral Standard（产品行为标准，长期不变）

规定：

```
```

### Current Engineering Implementation（当前工程载体，可演进）

当前采用：

```
```

> **不让当前实现反过来定义产品概念。** 例如：SVG 是当前实现载体的选择，不是"所见即所得"的定义；`.AsWish/llm/` 是当前落盘位置，不是协议概念；CLI `intent` 是当前入口，不是"自然语言表达"的定义本身。

---

## 十四、工程票 → First Closed Loop v0 映射表

|   |
| - |

工程票 / 阶段

|   |
| - |

解决什么问题

|   |
| - |

First Closed Loop v0 中的位置

|   |
| - |

Engineering Acceptance

|   |
| - |

Dogfood Acceptance

|   |
| - |

**0027A**

|   |
| - |

我想改什么？

|   |
| - |

Stage 1–2（Intent / Manifestation）

|   |
| - |

§6.1

|   |
| - |

§6.1

|   |
| - |

**0027B**

|   |
| - |

你的意思是不是这样？

|   |
| - |

Stage 3（Interpretation / Candidate）

|   |
| - |

§6.2

|   |
| - |

§6.2

|   |
| - |

**0027D-D0**

|   |
| - |

用什么结构承载 AI 的解释

|   |
| - |

Stage 3 协议前置

|   |
| - |

§6.3

|   |
| - |

§6.3

|   |
| - |

**0027C**

|   |
| - |

我们确认的到底是什么？

|   |
| - |

Stage 4–5（Confirmation / Confirmed Understanding）

|   |
| - |

§6.4

|   |
| - |

§6.4

|   |
| - |

**0027D-D1**

|   |
| - |

这次确认是怎么来的

|   |
| - |

Stage 5（provenance）

|   |
| - |

§6.5

|   |
| - |

§6.5

|   |
| - |

**0028**

|   |
| - |

我们确认的东西长什么样？

|   |
| - |

Stage 6（Visual Baseline）

|   |
| - |

§6.6

|   |
| - |

§6.6

|   |
| - |

**Evidence v0**（待立票）

|   |
| - |

Agent 实际做了什么？

|   |
| - |

Stage 7–9（Agent Dev / Evidence / Result）

|   |
| - |

§6.7

|   |
| - |

§6.7

|   |
| - |

**Difference v0**（待立票）

|   |
| - |

实际结果与确认内容哪里不同？

|   |
| - |

Stage 10（Difference）

|   |
| - |

§6.8

|   |
| - |

§6.8

|   |
| - |

**Human Confirmation**（待立票）

|   |
| - |

这个 Difference 是否接受？

|   |
| - |

Stage 11（Human Judgment）

|   |
| - |

§6.9

|   |
| - |

§6.9

|   |
| - |

**Revision**（待立票）

|   |
| - |

我要求怎么改？

|   |
| - |

Stage 12–14（Revision / Rebuild / Re-verification）

|   |
| - |

§6.10

|   |
| - |

§6.10

> 本表只是索引；每票验收的**唯一详源是 §六**，冲突时以 §六为准。

---

## 十五、文档 12 问自检

资料更新后，项目文档必须能直接回答：

|   |
| - |

\#

|   |
| - |

问题

|   |
| - |

答案位置

|   |
| - |

1

|   |
| - |

什么叫 First Closed Loop？

|   |
| - |

本文 §一、§八；[蓝图 §二十一](AsWish-产品功能与愿景蓝图-v1.md)

|   |
| - |

2

|   |
| - |

最小闭环需要哪些阶段？

|   |
| - |

本文 §八（v0 主链）、§十一（阶段标准表）

|   |
| - |

3

|   |
| - |

每阶段 Human 做什么？

|   |
| - |

本文 §十一

|   |
| - |

4

|   |
| - |

每阶段 AI 做什么？

|   |
| - |

本文 §十一

|   |
| - |

5

|   |
| - |

哪些决定 Human 必须拥有？

|   |
| - |

本文 §十二（Human owns）

|   |
| - |

6

|   |
| - |

哪些事情 AI 禁止做？

|   |
| - |

本文 §十二（AI must not）

|   |
| - |

7

|   |
| - |

什么东西必须被看见？

|   |
| - |

蓝图 §二十二、§二十三

|   |
| - |

8

|   |
| - |

SVG 在哪里出现？

|   |
| - |

蓝图 §二十三、§二十四（VC-01～05）

|   |
| - |

9

|   |
| - |

什么叫 Visual Baseline？

|   |
| - |

蓝图 §八.3 / §二十三第二阶段；0028 工单

|   |
| - |

10

|   |
| - |

什么叫 Implementation Evidence？

|   |
| - |

蓝图 §十；本文 §6.7；0028 §六（Screenshot = Evidence）

|   |
| - |

11

|   |
| - |

什么叫 Difference v0？

|   |
| - |

本文 §6.8；蓝图 §二十四（VC-04）

|   |
| - |

12

|   |
| - |

什么条件下可以宣布 First Closed Loop 成功？

|   |
| - |

本文 §八（硬性条件 + 不完成条件）

---

## 十六、待裁定冲突登记

以下冲突**只做记录，不做自行裁决**（依据 [`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md) §4 冲突裁定顺序）：

### C-1 · D0 前置被跳过：B 已落地、C 已写回，而 schema 未冻结

- **事实链**：
  1. `WO-20260830-0027B` 声明"依赖 `0027D` 的 D0 里程碑（Change Set schema 已冻结）"；
  1) 0027B 已实现并入 `main`（`78d8e0c`），Change Set 落盘于 `.AsWish/llm/change-set.yaml`；
  1. 0027C 正在工作树中实现（未提交），其中 `ApplyChangeSet` **已具备 Accept 后写回 Canonical Spec 的能力**；
  1) **D0 schema 至今未冻结**。

* **风险**（较原记录升级）：
  - 协议后置冻结时，schema 可能与实际字段不一致，导致返工或协议分叉；
  * 更严重的是：写回 Canonical Spec 的路径已经存在，而承载它的协议尚未被裁定 —— **一旦 schema 后续变更，已写回的真实 Spec 数据可能失去可追溯性**，直接冲击 0027D「能从最终 Spec 倒查回人类原始自然语言」这一核心主张。

- **建议裁定**：**优先冻结 D0**，再继续 0027C 的写回路径；明确 D0 是"追认现有实现"还是"修订实现"。

* **状态**：待裁定，**建议提级处理**。

### C-2 · 工单表头工作仓库仍为 DeepSpec

- **事实**：`WO-20260830-0027A/B/C/D`、`WO-20260830-0028` 表头均写"工作仓库：`D:\_Progs\02Business\DeepSpec`"，但 0027A/0027B 的实现实际落在 AsWish 仓库 `main`。

* **风险**：后续开发 AI 按工单字面在 DeepSpec 仓库开工，造成双仓分叉。

- **建议裁定**：将未执行工单（0027C/0027D/0028）的承接仓库正式改判为 AsWish 仓库。

* **状态**：待裁定（与历史审计发现一致）。

### C-3 · `WO/` 在治理中被归类为只读历史归档，但仍在承载活跃工单

- **事实**：[`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md) §1 与 §2-Class H 将 `WO/` 列为"历史归档类 / 只读保留、禁止篡改"；但 0027C/0027D/0028 为当前活跃工单，且本文 §五要求每票补齐 8 项验收。

* **风险**：按治理字面不得修改 `WO/`，则"每票双闸门验收"无法写回工单本体。

- **建议裁定**：将活跃工单重新归类为当前有效工程文档（如 Class B），或建立活跃工单的新归档位置，历史工单继续只读。

* **当前处理**：本文（当前有效工程路线文档）已承载每票双闸门验收内容；`WO/` 文件**未做任何修改**。

### C-4 · `.AsWish/llm/` 下的落盘位置不在 SPEC §2 布局内

- **事实**：`candidate-intent.yaml` 与 `change-set.yaml` 落盘于 `.AsWish/llm/`，该位置未见于 [`../SPEC.md`](../SPEC.md) §2 工作空间布局，也无对应 JSON Schema。

* **风险**：协议与实现不一致，公开实验中读者无法按协议找到产物。

- **建议裁定**：在 0027D-D0 中一并纳入协议补齐。

* **状态**：待裁定。

========================================================================
[消息 11/11]  长度=4424
========================================================================
这版资料已经把我们上一轮讨论的大部分内容正式化了：双闸门、同一 Dogfood 任务、First Closed Loop 硬条件、阶段标准表、Visual Checkpoint 都已经进入工程基线。fileciteturn3file0L25-L42

但我现在反而认为，**下一步不要继续拆 0027B/0027C 的工单细节**。

我们应该再往上抽一层，把一个此前还没有真正钉死的产品标准定下来：

# “AsWish 的每一步，到底如何被人看见？”

因为现在文档里虽然有：

```text
Current State
Confirmed Baseline
Implementation Result
Difference
Revised Result
```

但这些是**视觉检查点**；还没有完全形成一个更基础的规则：

> **流程中的每一个重要产物，都必须拥有一个人可以直接观察和判断的表现。**

目前文档已经规定 Visual Baseline 是 `SpecSnapshot + 视觉绑定`，且不能新增独立 Baseline 实体。fileciteturn3file0L665-L760  
同时 Difference 也明确要求“被看见”，而不是自动宣布 Error。fileciteturn3file0L865-L960

但这还差最后一层。

---

# 一、我建议把 See 从“一个阶段”提升成“贯穿全流程的产品不变量”

现在阶段表容易让人理解成：

```text
1 Intent
2 Manifestation
3 Candidate
4 Confirmation
5 Confirmed Understanding
6 Visual Baseline
7 Agent
8 Evidence
9 Result
10 Difference
11 Judgment
12 Revision
...
```

然后到了第 6 步才开始“看”。

我认为这不够准确。

应该是：

```text
             SEE
              ↓
Intent → Manifest → Candidate → Confirm → Baseline
              ↓
             SEE
              ↓
Agent → Evidence → Result → Difference → Judgment
              ↓
             SEE
              ↓
Revision → Rebuild → Re-verification
```

也就是说：

> **See 不是 Stage 6。**
>
> **See 是每个需要人判断的阶段的共同要求。**

这与你说的：

> **“所有见及所得，必须通过这个流程体现出来”**

是完全一致的。

---

# 二、我们下一步真正应该定义“四个对象层”

我建议把 AsWish 的显示标准分成四层，而不是简单说“SVG”。

### ① 原始事实

例如：

```text
Human Intent
Decision
Spec
Snapshot
Agent output
Evidence
Difference
```

这些是系统实际拥有的事实。

### ② 语义对象

例如：

```text
Candidate
Change Set
Decision
Baseline
Implementation Result
Difference
```

这是“这个事实是什么意思”。

### ③ 可见表现

例如：

```text
文字
结构化表格
Tree
SVG
Preview
Diff View
```

这是：

> **人实际看到了什么。**

### ④ 人类判断

```text
Accept
Reject
Unresolved
Acceptable
Unacceptable
Revision
```

也就是：

> **看见之后，人做了什么。**

---

# 三、这样一来，“所见即所得”才真正清楚了

我建议不要把它定义为：

> 所见即所得 = UI 看到什么，系统就保存什么。

这容易回到传统编辑器思路。

AsWish 更准确的产品定义应该是：

> **凡是需要人确认、判断或修订的对象，系统必须提供与该对象对应的、稳定且可追溯的可见表现；人类的判断必须针对这个可见对象发生。**

于是形成：

```text
事实
 ↓
语义
 ↓
可见表现
 ↓
人类判断
 ↓
新的事实
```

这就是 AsWish 自己的“看见—确认”机制。

---

# 四、这会直接影响我们后面的 SVG 设计

目前路线写了 5 个 Visual Checkpoint：

```text
VC-01 Current State
VC-02 Confirmed Baseline
VC-03 Implementation Result
VC-04 Difference
VC-05 Revised Result
```

这个方向没问题。

但我会增加一个概念：

# Visual Contract v0

不是规定“每一步画什么 SVG”，而是规定：

| 阶段 | 必须能回答的问题 | 最低可见表现 |
|---|---|---|
| Intent | 我刚才说了什么？ | 原始意图 |
| Manifestation | 我究竟在解决什么？ | 问题/断口 |
| Candidate | AI 理解成什么？ | Change Set |
| Confirmation | 我确认了什么？ | Decision 对象 |
| Baseline | 确认的东西长什么样？ | Render / SVG |
| Agent | Agent 根据什么做？ | Context / Task boundary |
| Evidence | Agent 实际做了什么？ | Evidence |
| Result | 实际产生什么？ | Result View / SVG |
| Difference | 哪里不同？ | Difference View |
| Judgment | 我怎么判断这个差异？ | Judgment |
| Revision | 我要怎么改？ | 新 Intent |
| Re-verification | 修完以后怎样？ | Result v2 / Difference v2 |

这样就真正实现：

> **“所有见及所得，都通过流程体现出来。”**

---

# 五、这里还有一个非常重要的边界

不是：

> **每个阶段必须生成一个新的 Artifact。**

而是：

> **每个阶段必须有一个可被人观察的有效表现。**

所以完全允许：

```text
一个 Snapshot
    ↓
Current State View
    ↓
Baseline View
```

两个阶段复用同一数据。

也允许：

```text
Baseline SVG
+
Result SVG
    ↓
Difference View
```

Difference 根本不一定自己保存一张 SVG，它可以是**两个已有视觉表现的比较结果**。

这样不会把系统搞成：

```text
14 个 Stage
=
14 个数据库实体
=
14 个文件
=
14 张 SVG
```

这正好符合你一直要求的：

> **不要为了完整产品而制造一堆平行实体。**

---

# 六、因此我认为现在有一个比“立下一票工单”更优先的动作

让资料 AI 把目前 v1 再标准化一个东西：

# `Observable / Visual Contract v0`

它应该和现在的：

```text
Engineering Roadmap
+
Dogfood Acceptance
```

并列成为工程基准。

内容只解决：

```text
1. 什么东西必须被看见
2. 为什么必须被看见
3. 人在哪里进行判断
4. 每个判断对应什么可见对象
5. 什么情况下现有 Render 可以复用
6. 什么情况下必须产生新的视觉结果
7. SVG 是实现手段，而不是产品定义
8. 看见的对象如何与事实/Decision/Snapshot 建立追溯关系
9. Difference 如何被看见但不自动被判错
```

---

# 七、还有一个问题要先处理

这份 v1 自身出现了一个**工程状态一致性问题**：

文档前面记录 0027A 为 `27c268d`，0027B 为 `78d8e0c`；后面的“已实现”又把当前 `main HEAD` 写成 `c20536b`。fileciteturn3file0L155-L252 fileciteturn3file0L1297-L1393

而且文档明确登记：

```text
0027C
进行中、未提交

D0
未开工

D1
未开工
```

以及：

> B 已落地、C 已经具备写回能力，但 D0 schema 尚未冻结。fileciteturn3file0L1427-L1445

这个不是现在要我们去审代码，而是**资料层面的状态必须唯一化**。

所以接下来有两个并行但都很小的动作：

```text
A. 先定 Observable / Visual Contract v0
B. 清理 Engineering State 的 SSOT 状态
```

之后再决定下一张工单。

---

# 八、我建议我们的下一次产品讨论就只谈这个

我会把问题压缩成一句：

> **“当 AsWish 说‘请确认’，人到底必须看到什么，才能真正作出这个确认？”**

然后沿着：

```text
Intent
→ Candidate
→ Decision
→ Baseline
→ Implementation
→ Evidence
→ Result
→ Difference
→ Judgment
→ Revision
```

一项一项过。

这次讨论完成以后，**SVG 到底画哪些图、哪些图复用、哪些图形成 Snapshot、Difference 怎么可视化、GUI 应该怎么布局**，就会自然落下来。

这比现在继续开 0027E 更重要。