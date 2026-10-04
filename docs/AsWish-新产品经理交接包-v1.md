# AsWish 新产品经理交接包 (Onboarding Pack)

> **交接日期**：2026-09-06
> **当前阶段**：First Closed Loop (第一闭环) 工程化竣工，核心协议冻结，即将进入“差异社区 (Difference Commons) 建设”与“产品体验深化”期。

欢迎加入 AsWish 团队！
这是一份为您准备的核心概念与进度交接文档。它抛弃了冗长的历史代码细节，直接带您理解 AsWish 最核心的产品灵魂、工程进度以及您接下来需要接手的核心命题。

---

## 一、 产品灵魂：我们在做什么？

AsWish 不是传统意义上的“需求管理工具”或“AI 写代码辅助工具”。它的底层哲学是 **“差异一元论 (Difference Monism)”**。

### 1. 核心哲学：Difference ≠ Error
传统软件工程总是试图“消灭错误、防范偏离”。但在 AI 时代，人的意图是流动的，AI 的生成是涌现的，差异是永恒的。
AsWish 认为：**偏离预想不是 Error，而是正常的 Difference（差异）**。
我们要做的不是把 AI 关在笼子里，而是：**让差异清晰可见，让人类随心驾驭。**

### 2. 产品定位：开发随心的“六脉神剑”
AsWish 是一套帮助人类在差异丛生的工程中“随心开发”的基础设施。它包含六大核心脉络：
1. **显影 (Surfacing)**：人类随心表达，AI 帮助模糊意图显形。
2. **对齐 (Aligning)**：通过 GUI 结构线框（Visual Preview），让人心所想与眼前所见极早对齐。
3. **结构化 (Structuring)**：将人类 Confirm 的决定转化为机器严谨的 `TChangeSet`。
4. **追踪差异 (Tracking Difference)**：现实代码生成后，AsWish 自动计算 Baseline 与现实 Evidence 之间的差异。
5. **差异调整 (Adjusting)**：人类看着差异，随心决定是打回重做，还是“顺势接受（Accept Difference）”。
6. **经验积累 (Accumulating)**：将这次人机分岔的轨迹，沉淀为未来的开发经验。

---

## 二、 协议底座：AsWish Protocol Specification v0

为了支撑上述理念，我们制定了极具野心的**开放工程协议**（详见 `protocol/ASWISH-PROTOCOL-SPEC-v0.md`）。

**协议的最核心铁律：**
- **Human Authority**：机器（Agent）只有提案权、观察权；人类拥有绝对的“意图发起权”和“最终裁断权（Judgment）”。
- **Immutable History & Provenance**：所有历史状态（Intent -> Decision -> Baseline -> Context -> Implementation -> Evidence -> Difference -> Judgment）均不可静默覆盖，来源 100% 可追溯。

这确保了无论 AI 如何狂奔，人类始终掌握着软件状态演化的方向盘。

---

## 三、 工程进度汇报：我们进行到了哪里？

在您接手时，研发团队刚刚进行了一次极其惨烈的工程冲锋（经历了 `WO-0027A` 到 `H`，以及 `0027R1~R3` 的多次审计阻断与重构），**目前 AsWish 已经 100% 打通了 First Closed Loop（第一完整闭环）**。

### 1. 人机决策闭环（已竣工）
- 自然语言意图 (`TCandidateIntent`) 自动转换为结构化变更集 (`TChangeSet`)。
- 在桌面端 GUI (WebView2) 渲染变更的 Diff，支持 `0-9 规范交互`（[1] Accept, [9] Clarify）。
- 决断后，自动写入不可变的哈希基线（`Accepted Baseline v0` 与 `Visual Spec Baseline`）。

### 2. 差异追踪与演化闭环（已竣工）
- **实现证据采集 (Implementation Evidence)**：系统已能从真实目录中提取代码与结构现状。
- **结构化差异引擎 (Structural Difference)**：精确计算 Baseline 与现实状态的差别，不带主观报错，仅客观陈述 Difference。
- **演化修订双出口 (Revision Evolution)**：人类可以根据 Difference 发起 `Judgment`，选择修正代码或修正基线。

### 3. GUI 真实环境验证机制（刚交付）
- 我们刚刚通过了极度严苛的 `WO-0029`。AsWish 现在具备了在真实桌面环境（非 CLI 伪造）中拉起 GUI、渲染差异、通过 DOM 节点级断言验证交互结果，并进行快照存档的自动化能力。工程护城河已建立。

---

## 四、 您的使命：接下来做什么？

底层协议和核心工程流闭环后，现在最大的命题是：**让这款软件好用、产生公众价值、并建立独一无二的社区文化**。

### 核心战场一：Difference Commons（差异共同经验库）的落地
详见目录下的 `docs/AsWish-公众价值层与差异社区理念-v1.md`。
- **不做低级积分库**：我们要像 GitHub 存代码一样，存下人类与 AI 协作时产生的“经典语义分叉轨迹”。
- **设计首批种子（冷启动）**：系统在 Day 1 需要内置 Top 50 的通用语义雷区（如 Disable 与 Delete 的混淆），用户怎样才能在第一次安装时就感受到“历史经验帮我防坑”的震撼？
- **设计 🚩 提取按钮**：如何在人类纠正完 AI 的那一刻，提供一个不打扰、所见即所传的“贡献为避坑经验”的丝滑按钮。

### 核心战场二：产品交互（Dual Surface）打磨
- 目前 CLI 和桌面 GUI 的底层引擎已经互通，接下来需要以用户视角梳理：何时用大窗沉浸 Review，何时用侧边栏快速对话，何时用微型残影 (Ghosts) 进行上下文显影提示。

---

祝您在 AsWish 开启一段愉快且极具开创性的产品设计之旅！如果需要重温某段具体的历史推演或设计协议，随时可以通过查询 `docs/` 和 `protocol/` 目录获取第一手真相。
