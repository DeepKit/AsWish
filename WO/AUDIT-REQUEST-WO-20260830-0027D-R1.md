# 审计请求单：WO-20260830-0027D-R1 (GUI Review Surface & Intent List)

## 一、工单基本信息

- **工单编号**：`WO-20260830-0027D-R1`
- **工单标题**：GUI Review Surface — ChangeSet 审阅与裁决界面
- **执行仓库**：`D:\_Progs\02Business\AsWish`
- **优先级**：P0
- **承接基线**：WO-20260830-0027D (PASS, Commit `ba4b56ff` / `89576609`)
- **审计发起时间**：2026-08-30 21:37:00

---

## 二、验收标准（AC）逐项自检

| 编号 | 验收标准 | 实施状态 | 验证方式 / 证据 |
|:---|:---|:---:|:---|
| **AC-01** | **Review 四层信息模型完整呈现**<br>① I said 原始意图、目标节点、提出方、时间<br>② AI understood 解释摘要（提议非生效）<br>③ 准备改变什么：Before/After 结构化对比表 + 受影响投影<br>④ 你是否同意：0–9 统一选择交互区域 | **PASS** | `changeset-review.html` 渲染模板，151/151 单元测试验证 |
| **AC-02** | **来源性质人话化呈现**<br>禁止在 UI 上暴露 `cstExplicit`/`cstInferred`/`cstUnknown` 等代码枚举；使用“你明确提出”、“AI 推断”、“尚未确定” | **PASS** | `RenderChangeSetReviewPage` 中 `LSourceText` 本地化转换，单元测试验证 |
| **AC-03** | **0–9 统一选择交互标准与语义色 Token**<br>[1] 接受 (推荐高亮)<br>[2] 逐项审阅<br>[3] 补充细节 (Clarify 表单)<br>[4] 拒绝<br>[8] 重新生成<br>[9] 人类意图输入<br>[0] 返回上一步 (纯导航，不等于 Reject)<br>支持鼠标点击与全局数字快捷键 | **PASS** | CSS 变量 `--choice-opt-*`, `--choice-rec-*`, `--choice-regen-*`, `--choice-input-*`, `--choice-back-*` 与键盘事件监听器 |
| **AC-04** | **Clarify 必须是独立输入表单，不是聊天窗口**<br>单向提交补充信息后进入决策 `rsDeferred`，不修改 Canonical Spec | **PASS** | `#clarify-panel` 嵌入式表单，提交 `changeset-clarify` 消息，Dogfood 验证 Canonical Spec 保持不变 |
| **AC-05** | **交互完全复用 Controller 现有方法与 JS Bridge**<br>无任何新增业务实体，通过 `window.chrome.webview.postMessage` 触发 Controller | **PASS** | `TBrowserNavigator.HandleWebMessage` 分发 `changeset-submit/accept/reject/clarify/regenerate` |
| **AC-06** | **节点详情页自然语言提议入口**<br>在 `node-detail.html` 增加自然语言修订意图输入卡片与 `[9]` 提交按钮 | **PASS** | `RenderNodeDetail` 更新，通过 JS Bridge 触发 `changeset-submit` |
| **AC-07** | **Dogfood 验收验证**<br>实现候选任务 A（`intent list` 命令 + 真实 Reject/Clarify 场景） | **PASS** | CLI `intent list`，GUI `aswish.intent.list`，Dogfood 真实 Reject/Clarify 证据存档 |
| **AC-08** | **Human/AI Boundary 守门自检**<br>AI 解释只是 Proposal，必须经人类 Decision 才进入 Canonical Spec | **PASS** | 测试与 Dogfood 证明 Reject/Clarify 时规范树 0 变更，只有 Accept 时才合并写入 |

---

## 三、构建与测试证据

1. **测试编译与运行**：`WO/evidence/build-tests-20260830-0027D-R1.txt` & `WO/evidence/test-run-20260830-0027D-R1.txt`
   - **结果**：151 Tests Found, 151 Tests Passed, 0 Failed, 0 Errored, 0 Leaked.
2. **应用构建**：`WO/evidence/build-apps-20260830-0027D-R1.txt`
   - **GUI (`AsWish.exe`)**：0 Error, 0 Warning.
   - **CLI (`AsWish.CLI.exe`)**：0 Error, 0 Warning.
3. **Dogfood 证据**：`WO/evidence/dogfood-run-20260830-0027D-R1.txt`
   - 真实执行 `scan` → `intent` → `intent list` → `changeset` → `changeset review` → `changeset clarify` → `changeset reject` 完整链路。
