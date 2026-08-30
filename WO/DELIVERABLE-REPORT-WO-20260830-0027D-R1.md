# 工单交付报告：WO-20260830-0027D-R1

## 一、工单交付基本信息

- **工单编号**：`WO-20260830-0027D-R1`
- **工单标题**：GUI Review Surface — ChangeSet 审阅与裁决界面
- **执行仓库**：`D:\_Progs\02Business\AsWish`
- **执行时间**：2026-08-30 21:38:00
- **当前状态**：**COMPLETE / READY FOR REVIEW**
- **承接关系**：承接 0027A（意图入口）、0027B（ChangeSet 结构承载）、0027C（Review 闭环写回）、0027D（Controller 方法与 CLI）

---

## 二、交付要点总结

### 1. GUI Review 表现层（Four-Layer Information Model）
- **① 我说 (I said)**：完整展示用户原始意图 (`RawUserIntent`)、目标节点 ID/标题、提出方与时间戳。
- **② AI 理解 (AI understood)**：明确标明 AI 结构化解释摘要为“待审阅提议（Proposal）”，未被批准前绝不修改正式规范。
- **③ 准备改变什么 (Changes & Affected Projections)**：
  - 结构化对比表：Before (当前值) vs After (提议值)。
  - **来源性质人话化**：严格映射为“你明确提出” (`cstExplicit`)、“AI 推断” (`cstInferred`)、“尚未确定” (`cstUnknown`)，无代码枚举暴露。
  - 受影响投影：基于语义束（Semantic Bundles）展示 Function / Module / View / Data 投影标签。
- **④ 你的裁决 (Decision - 0–9 Universal Choice)**：
  - `[1]` 接受 (Accept) 并应用到规范（推荐高亮）。
  - `[2]` 逐项分项确认 (Itemized Review)。
  - `[3]` 补充细节 / 修改后接受 (Clarify) 独立表单。
  - `[4]` 拒绝 (Reject) 该理解（规范保持不变）。
  - `[8]` 让 AI 重新生成理解 (Regenerate，非决策)。
  - `[9]` 我自己说明 / 输入新意图 (Escape Hatch)。
  - `[0]` 返回上一步 (Back，纯导航不作裁决)。
  - 全局键盘监听器与鼠标点击双模支持。

### 2. 节点详情页自然语言提议入口
- 在 `node-detail.html` 底部增设 **人类自然语言修订（我说）** 卡片，包含意图输入多行文本框与 `[9] 提交意图` 按钮，通过 WebView2 JS Bridge 发送 `changeset-submit` 消息。

### 3. WebView2 JS Bridge 交互桥接
- 在 `TBrowserNavigator.HandleWebMessage` 与 `TAsWishMainViewProvider` 中完整支持 `changeset-submit`、`changeset-accept`、`changeset-reject`、`changeset-clarify`、`changeset-regenerate` 消息路由。
- 直接复用 `TAsWishController` 现有五大方法，零新增平行实体。

### 4. Dogfood 验收（候选任务 A：`intent list` 命令 + 真实 Reject/Clarify 场景）
- 交付 CLI 命令：`aswish intent list <project-dir>` 与 GUI 命令：`aswish.intent.list`（快捷查看待处理/已提交的自然语言意向）。
- 真实 Dogfood 场景验证：
  - 录入真实意向；
  - 查看意向列表；
  - 生成 ChangeSet；
  - 审阅 ChangeSet；
  - 执行真实 Clarify 操作（记录决策 `dec-0001`，规范保持不变）；
  - 执行真实 Reject 操作（记录决策 `dec-0002`，规范保持不变）。

---

## 三、构建与验证数据

- **Delphi 13.1 win64 单元测试**：
  - 151 Tests Found, 151 Tests Passed, 0 Failed, 0 Errored, 0 Leaked.
- **GUI 构建 (`_build.bat`)**：
  - 0 Error, 0 Warning.
- **CLI 构建 (`cli\_build_cli.bat`)**：
  - 0 Error, 0 Warning.
- **证据文件归档**：
  - `WO/evidence/build-tests-20260830-0027D-R1.txt`
  - `WO/evidence/test-run-20260830-0027D-R1.txt`
  - `WO/evidence/build-apps-20260830-0027D-R1.txt`
  - `WO/evidence/dogfood-run-20260830-0027D-R1.txt`

---

## 四、修改文件清单

1. `src/services/AsWish.Services.Render.pas`：HTML 表现层、CSS 语义色 Token、4 层 Review 页面与节点详情意图卡片渲染。
2. `src/services/AsWish.Services.CandidateIngest.pas`：`ListCandidateIntents` 与 ChangeSet 自动加载回退。
3. `src/controllers/AsWish.Controller.pas`：`ListCandidateIntents`、Review 页面重新渲染联动。
4. `src/providers/AsWish.Providers.MainView.pas`：WebView2 JS Bridge `changeset-*` 消息路由分发。
5. `src/app/AsWish.Providers.pas`：GUI Provider 桥接绑定。
6. `src/app/AsWish.Commands.pas`：`aswish.intent.list` 注册与类型限定。
7. `cli/AsWish.CLI.dpr`：`intent list` 与 `changeset clarify` 命令行支持。
8. `tests/Test.AsWish.CandidateIngest.pas`：151 项全量测试（新增 Review HTML 与 Intent List 测试）。
