# WO-20260830-0027D-R1 · 甲（开发AI）· GUI Review Surface（ChangeSet 审阅与裁决界面）

- 下发时间：2026-08-30 21:25 (GMT+8)
- 下发人：主控AI
- 承接方：**甲（开发AI，AsWish 仓库）**
- 工作仓库：`D:\_Progs\02Business\AsWish`（**本票起，新工单一律直接写 AsWish 仓库，不再沿用 DeepSpec 字面残留**；裁定依据：工程路线 §十六 C-2）
- 优先级：P0
- 依赖：`0027A/B/C/D` 已全部入 `main`（`Controller` 五方法可用：`SubmitUserIntent / ReviewChangeSet / AcceptChangeSet / RejectChangeSet / ClarifyChangeSet`）；**新增前置：`DeepBase` 侧 `WO-20260830-005`（HB 0–9 选择控件 + 嵌套瀑布 + 信息粒度）交付后本票 UI 才可落地**
- 门禁：非睿智轻量门禁；**双闸门（Engineering Green + Dogfood Green）**；单 commit ≤200 行；build/test 原始输出存档证据；主控 APPROVED/RETURNED，未过不得 CLOSE

---

## 一、目标

把已经成立的 `I said → AI understood → We decided` 链路，从工程内部能力变成**人可以实际操作、判断和确认的界面闭环**。

处理链：

```text
Natural Language（GUI 输入）
    ↓
SubmitUserIntent（Controller，已存在）
    ↓
ChangeSet
    ↓
Review UI（四层信息模型，本票核心交付）
    ↓
Human Decision（Accept / Reject / Clarify，复用 RecordChangeSetDecision）
    ↓
Canonical Spec + Validation（已存在）
```

> 0027D 交付的是"底层链路 + Controller / Command 接入"；本票只补最后一层 `Commands / Controller → GUI UX`。**不重开大工单，不重构底层数据模型。**

---

## 二、核心架构纪律（钉死）

1. **只做 GUI 表现层**：复用 Controller 五方法，**不新增业务逻辑、数据模型、状态机**。
2. **复用 WebView2 JS Bridge**（`TAsWishMainViewProvider` / `TEdgeBrowser`）承载 Review 页面；前置勘察报告（`docs/WO-20260830-0027D-前置工程勘察报告.md`）判定"完全可以小步接入，无需重构"。
3. **控件尽量用 DeepBase 的 HB 视觉系统**（老板指令 2026-08-30）：主题 / Tokens / `THbSummaryBar` / `THbStreamBlock` / `THbBadge` 等已可直接用；缺失三件——0–9 选择控件、嵌套瀑布、信息粒度——由 `DeepBase/WO-20260830-005` 交付后使用，**本票不在 AsWish 侧私造等价控件**。
4. **交互遵循 [`docs/03.规范-可见判断与交互规范.md`](../docs/03.规范-可见判断与交互规范.md)**：0–9 协议 + 语义色 Token（`Choice.Option / Regenerate / Input / Back`），深浅色主题各定义一套颜色值；落地为 HB 预置控件 `THbChoiceDeck`。
5. **瀑布式、可扩展、有包含关系**：Review 信息用 HB 嵌套瀑布呈现——大问题包中问题包小问题（总意图 → 各理解 → 各变更项 → 字段级）；父卡可展开 / 收起子卡。
6. **随时可切信息粒度**：全局粒度开关 6 档（超粗 / 粗 / 适中 / 较细 / 细 / 极细），默认适中；瀑布按档位折叠到对应深度。**粒度只影响看多少，不影响数据真伪。**
7. **Review 页面的对象不是 ChangeSet YAML，而是"AI 对我的意图形成的当前理解"**——ChangeSet 只是它的工程承载物。
8. **Review 页面四层信息模型**（不把 YAML 全部倒给用户）：
   ```text
   ① I said          原始意图（用户自己刚说的）
   ② AI understood   AI 的理解（不是 Canonical Spec）
   ③ Changes         Before / After + Affected Projections
   ④ Decision        你是否同意这个理解（Accept / Reject / Clarify）
   ```
9. **Clarify 是表单，不是聊天窗口**：`AI 述说不确定点 → 选项/输入 → 重新进入 Candidate → ChangeSet → Review`。Clarify 是让当前意图继续显影，不是开启聊天系统。
10. **术语呈现纪律**：`explicit / inferred / unknown` 不得作为术语直接展示；呈现为"你明确提出 / AI 推断 / 尚未确定"。
11. **禁止新增实体**：`VisualState` / `VisualProposal` / `VisualDecision` / `VisualReviewState` / 新 Baseline 实体 / 第二套状态机——一律禁止。

---

## 三、1–7 候选与 Decision 映射（开工前须主控确认）

0–9 是 Interaction Protocol；Accept / Reject / Clarify 是 Decision Semantics。本票的候选映射**建议初稿如下，开工前由主控/老板确认**：

| 键 | 候选项 | 映射 Decision |
|---|---|---|
| `1` | 接受这个理解 | Accept |
| `2` | 逐项裁决（对 explicit / inferred 分项确认） | 分项 Accept / Reject |
| `3` | 修改一个细节后接受 | Clarify（带修订意见） |
| `4` | 拒绝这个理解 | Reject |
| `5–7` | 上下文相关预留（如"只接受明确提出的项"） | 视上下文 |
| `8` | 重新生成理解 | **非 Decision**（不落盘裁决） |
| `9` | 我自己说明 | 自然语言 → Clarify / 新 Intent |
| `0` | 返回 | **非 Decision**（纯导航，禁止等同 Reject） |

> **待讨论的核心子问题**：整体裁决 vs 逐项裁决——ChangeSet 含多个 change 项，数据层已支持 item 级（`TSpecDecision.ChangeItemIndex`），但 CLI 当前是整票 Accept/Reject。此选择决定 Review 页面结构。

---

## 四、AC（Engineering Acceptance）

- **AC-01**：打开项目后，选中 Spec 节点可通过 GUI 提交自然语言意图（替换 `InputQuery` 模态弹窗形态）。
- **AC-02**：Review 界面按四层信息模型展示（§二.5）；`8` 键重新生成不产生 Decision。
- **AC-03**：裁决动作映射 Accept / Reject / Clarify，经 Controller 落盘 Decision（复用 `RecordChangeSetDecision`）；**Reject / Clarify 不改 Canonical Spec**；Accept 才写回并触发 Validation。
- **AC-04**：交互符合 0–9 标准：`1–7` 可鼠标可数字键；`8/9/0` 全局固定语义；四类语义色 Token 在深浅主题下各自定义。
- **AC-05**：相同数据重复渲染结果一致（确定性渲染）。
- **AC-06**：DUnitX 全量回归通过（当前基线 149/149 不得回退）+ 新增 GUI 管道测试用例。
- **AC-07**：build / test / GUI 运行日志原始输出存档 `WO/evidence/`。
- **AC-08**：Human / AI Boundary 逐条自检（工程路线 §十二 AI must not 六条），写入交付报告。

---

## 五、Dogfood Acceptance（真人操作场景）

```text
新建 / 打开一个项目
    ↓
选择一个 Spec 节点
    ↓
用自然语言表达一个修改意图
    ↓
看到 AI 的理解（I said → AI understood）
    ↓
看到它准备改变什么（Before / After + Affected）
    ↓
逐项判断（含至少一次 Reject 或 Clarify）
    ↓
系统明确告知"现在我们决定了什么"
    ↓
重开项目，Accepted Spec 状态一致
```

硬条件：

- **真实任务、真实人类、真实 AsWish、真实结果**（真实 Agent 环节属 Evidence v0，不在本票）；
- 普通用户**不理解 YAML / Spec / ChangeSet / Decision 工程概念**也能完成全程；
- **不接受仅 `InputQuery` 弹窗形态**；
- 149/149 只是 Engineering Green，**不构成本票完工**。

---

## 六、Dogfood 任务（建议票内锁定，最终由老板裁定）

建议选定后**贯穿后续所有阶段，不每一票换 Demo**：

> **候选 A：为 CLI / GUI 增加 `intent list`（查看已提交、未处理的 user_intent）**

理由：小、真实、可验证、有真实歧义（显示哪些字段、如何排序、未处理意图如何呈现），且为 **Delphi 代码改动**——这是为后续 Difference v0 保留结构比较对象（`PasParser` / `DfmParser` 仅支持 Delphi）的前提。

**Dogfood 任务一经选定不得更换**；本票的 Dogfood 验收即以此任务为真实意图来源。

---

## 七、非目标

不做：聊天窗口 / Visual Baseline（0028）/ Implementation Evidence / Difference / 完整 GUI 重设计 / 0–9 之外的快捷键体系 / 多语言 / Pixel Diff / Agent 接入 / 布局 schema 扩展。

## 八、交付物

代码 + `WO/evidence/` 证据包 + `WO/AUDIT-REQUEST-WO-20260830-0027D-R1.md` 复审请求 + 交付报告。

## 完成定义

> 一个普通人，在 AsWish 桌面端，不需要理解任何工程概念，就能完成一次"我说 → AI 理解 → 我判断 → 系统记录决定 → 状态更新"，并且至少发生一次真实的否决或澄清。
