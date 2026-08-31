# AsWish 统一选择交互标准 v1（0–9 Universal Choice Standard）

> **English title**: Universal Choice Interaction Standard
> **版本**：v1.0（已冻结）
> **日期**：2026-08-30
> **状态**：**已冻结的统一交互约定**。后续工程讨论与实现以此为准，不再反复讨论本基础约定。
> **冻结依据**：老板于 2026-08-30 确认冻结（A 线工程讨论定稿）。
>
> **与既有文档的关系（SSOT 指向，不复制）**：
> - 本规范是 0–9 数字交互协议的**唯一独立语义源**；[`AsWish-双界面交互规范-DualSurface-v1.md`](AsWish-双界面交互规范-DualSurface-v1.md)（父框架）只引用、不重写。
> - 判断的可见性/追溯约束见 [`AsWish-可见判断规范-OJP-v1.md`](AsWish-可见判断规范-OJP-v1.md)。
> - Human / AI 边界（Human owns / AI may / AI must not）：见 [`AsWish-工程路线与Dogfood验收-v1.md`](AsWish-工程路线与Dogfood验收-v1.md) §十二
> - 所见即所得原则（凡是要求 Human 作判断的对象，必须有稳定、可观察、可重复查看的表现）：见 [`AsWish-产品功能与愿景蓝图-v1.md`](AsWish-产品功能与愿景蓝图-v1.md) §二十二

---

## 1. 全局固定规则

```text
1–7   当前上下文提供的候选选项
8     重新生成候选
9     自己输入文字
0     返回上一步
```

其中：

> **1–7 是动态语义；8、9、0 是全局固定语义。**

交互方式：鼠标点击与键盘数字键**完全等价**——用户不需要学习复杂快捷键，只需要记住 `1–9、0`。

---

## 2. `1–7`：候选选项

每个需要 Human 判断的地方，AI 最多提供 **7 个候选项**。

规则：

- `1`：默认推荐项；
- `2–7`：其他合理候选；
- 不要求必须有 7 项，可以只有 2、3、4……项；
- 不足 7 项时，不虚构选项；
- `1` 只是推荐，不代表正确答案；
- UI 不得暗示"你应该选 1"；措辞用"推荐方案"，不用"最佳方案"。

核心原则：

> **AI 提供候选空间，Human 选择。**

**AI 给不出候选是合法状态**（老板裁定 2026-08-31）：当 AI 无法可靠形成有意义的候选时，**不得为满足 `1–7` 格式强行制造候选**；可直接说明"当前无法可靠形成候选，请直接描述你的意思"，只提供 `9 / 0`。AI 不需要伪装确定。

---

## 3. `8`：重新生成候选

`8` 永远表示：

> **在当前上下文和约束下，让 AI 重新生成一组候选。**

行为：

```text
8 → AI 重新生成候选 → 新的 1–7
```

重要：

> **`8` 本身不是 Decision。**

不会修改 Canonical Spec，不产生 Accept / Reject / Clarify Decision。

**上下文锚**：重新生成时，**原始 Human Intent 与当前 Decision Context 必须保持为主要约束**；禁止候选逐轮漂移，以致无法判断新候选是否仍属于原始 Intent。

---

## 4. `9`：自己输入文字

`9` 永远表示：

> **我不想从 AI 提供的候选中选择，我自己描述。**

进入自然语言输入：

```text
9 → Human Natural Language → 当前上下文继续处理
```

因此：

> **`9` 不是"其他"。**

而是：

# Human Override / Natural Language Escape Hatch

它保证：

> **AI 的候选空间永远不会限制 Human Intent。**

这与 Human / AI Boundary 直接对应：`1–7 = AI 提供的候选空间`，`9 = Human 打破候选空间`。

**拒绝整个框架（Frame Rejection，老板裁定 2026-08-31）**：`9` 允许 Human 拒绝的不只是某个选项，而是**整个 AI 定义的问题框架**——例如"你给的选项都不是我真正要解决的问题"。系统应理解为 **Human rejects the frame**，而不是 "selected Other"。

---

## 5. `0`：返回上一步

`0` 永远表示：

> **返回上一层交互。**

它是 **UI Navigation，不是业务 Decision**。

```text
0 → Back
```

不产生 Candidate、ChangeSet、Decision，不修改 Canonical Spec。

**特别禁止**把 `0` 等同于 `Reject`：

> `0 = Back（导航）`；`Reject = Human Decision（裁决）`。两者是完全不同的语义，不得混用。

---

## 6. 视觉规范：语义色 Token

统一使用**语义色 Token**，而不是固定 RGB。四类：

```text
Choice.Option      1–7 普通候选色
Choice.Regenerate  8 重新生成语义色
Choice.Input       9 自定义输入语义色
Choice.Back        0 返回语义色
```

规则：

- **Light Theme / Dark Theme 各自定义颜色值，但语义 Token 不变**；
- `1–7` 中的默认推荐项（`1`）与 `8` / `9` / `0` 行的配色必须彼此区分；
- 同一套语义适用于所有客户端：VCL、WebView2、HTML、CLI、未来其他客户端；
- **不要让颜色只表达装饰，而要让颜色成为交互语义**——用户使用数次后形成肌肉记忆。

---

## 7. 与 Accept / Reject / Clarify 的关系

**0–9 是统一交互机制，不等于所有页面必须机械显示 10 个按钮。**

例如 ChangeSet Review 的呈现：

```text
AI 理解了你的意图：

1  接受这个理解
2  接受，但需要调整
…
7  …

8  重新生成理解
9  我自己说明
0  返回
```

但在**最终裁决层**，仍然保留 AsWish 的正式语义：

```text
Accept
Reject
Clarify
```

因此正式区分：

> **0–9 是 Interaction Protocol（交互协议）；Accept / Reject / Clarify 是 Decision Semantics（决策语义）。**

两个层级不能混淆。数字选择最终映射为哪种 Decision，由当前交互上下文决定。

---

## 8. 总原则

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

### 四条冻结原则

**① `1` 是默认推荐项，但不是强制项。**

**② `8 / 9 / 0` 是全局固定语义。**

**③ `0` 是导航，不是 Reject。**

**④ `9` 是 Human Override / Natural Language Escape Hatch，不是简单的"其他"。**

---

## 9. 与 Clarify 的配合（非聊天窗口）

AsWish 不是 ChatGPT。第一阶段的 Clarify 只需要：

```text
AI：
我无法确定你说的"深色模式"是否意味着：
1. 仅页面背景
2. 整个应用主题
…

[输入澄清内容____________]
[提交澄清]
```

然后重新进入：

```text
Candidate → ChangeSet → Review
```

> **Clarify 不是开启一个聊天系统，而是让当前意图继续显影。**

`8 / 9 / 0` 在此同样适用：`8` 换一批澄清候选，`9` 自己说明，`0` 返回不产生任何 Decision。

---

## 10. 术语呈现纪律

工程字段（如 `explicit` / `inferred` / `unknown`）不得作为术语直接教育用户。用户真正需要理解的是：

```text
你明确提出
AI 推断
尚未确定
```

具体文案由实际 ChangeSet 数据驱动，在 GUI 票中定稿。

---

## 11. 下一步接口

本标准冻结后，ChangeSet Review（0027D-R1）的交互模型随之明确：

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

待讨论的下一层：**ChangeSet Review 页面具体给 1–7 提供什么候选，以及 Accept / Reject / Clarify 如何映射到本协议。**

---

## 12. 工程落地：HB 预置控件

本标准的工程实现落地为 **DeepBase / HB 预置控件 `THbChoiceDeck`**，由 `DeepBase` 侧 `WO-20260830-005` 交付（2026-08-30 老板指令）。

- 四类语义色 Token（`Choice.Option / Regenerate / Input / Back`）在 HB `Palettes` 中定义，浅 / 深主题各一套颜色值，Token 名不变；
- `1–7 / 8 / 9 / 0` 的语义以本文为唯一语义源，HB 只做工程落地，不改变语义；
- AsWish 侧不私造等价控件，统一复用该预置控件。

> 关联：AsWish `WO-20260830-0027D-R1`（GUI Review Surface）依赖本控件的交付。

---

## 13. 理解 ≠ 决定（Understanding ≠ Decision）

> **AI 正确理解了 Human Intent，不等于 Human 一定同意采用该方案。**

`Understanding = Correct, Decision = Reject` 完全合法。"AI 理解得对吗？"与"采用这个变更吗？"是两个不同的问题，本协议不得把二者合并。

- AI 提供候选（`1–7`）只代表"这是我的理解/建议"，**不构成 Human 已同意**；
- Human 在 Decision Surface 的明确裁决（Accept / Reject / Clarify）才是唯一的决定；
- 即便 AI 的候选完全正确，Human 仍有权 Reject。
