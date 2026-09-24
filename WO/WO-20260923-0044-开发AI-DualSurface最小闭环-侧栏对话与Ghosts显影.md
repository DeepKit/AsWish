# WO-20260923-0044 · 开发AI · Dual Surface 最小闭环（核心战场二启动）

- **终态（2026-09-24）**：**CLOSE / APPROVED**。审计裁决 `WO/AUDIT-VERDICT-WO-20260923-0044-0045-甲.md`。

- 下发时间：2026-09-23 (GMT+8) · 下发人：Amy
- 依据：`docs/AsWish-新产品经理交接包-v1.md` §四 核心战场二；
  实测缺口：MainForm 中 Ghost 足迹=0、Inspector 面板挂接=0（grep 证据在案）
- 承接方：AsWish 开发AI
- 优先级：P1（产品体验主线的第一块拼图）；纯仓内、无模型网关依赖
- 原则：**只做用户视角三种表面的最小可用闭环，不做大重构**；单 commit ≤200 行

## D-1 · 侧栏快速对话面（最小档）

现成件复用：`AsWish.Providers.Inspector`（FindNodeById 已注册）+ `SubmitUserIntent`。
把 Inspector 从"未挂载的提供者"接成右侧可停靠面板：选中树上节点 → 面板显示节点摘要
+ 一个输入框 → 回车即 `SubmitUserIntent(nodeId, 推断树, text)`（树类型走 0041 已修的前缀推断）。
**禁止新建第二套意图提交路径**（SSOT：与 Deck 9 键同一 Controller 入口）。

## D-2 · Ghosts 上下文显影提示（最小档）

Deck 状态行之上挂一行提示带（≤3 个 chip，可关）：内容来自 Commons `FindMatchingLessons`
（S-4 已有引擎，零新算法），输入意图/评审时命中即显"这类分叉曾错在 X（lesson-000N）"。
narrative 锚的 chip 必须带"经验总结，非可复核记录"角标（0043 语义延续）。

## D-3 · 沉浸 Review 档

现有大窗即沉浸面，本档只补两件事：
(a) 全屏化按钮/`F11`（隐藏左右面板，只留 HTML+Deck）；
(b) 与 HB Deck 快捷键不冲突（复用 B-1 的 WebView 焦点豁免）。

## 验收

- 三表面各有 GUI 自动化断言（沿用 RunGuiVerification 管线扩展，非手工）；
- D-1/D-2 新逻辑单测覆盖；全量测试 ≥251 不回退；SPW 8/8；
- 交付后提 AUDIT-REQUEST，按 0041/0043 流程走审计。
