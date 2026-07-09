# DeepSpec 开发任务清单

> 基线：Delphi 13.1 / DeepBase / DeepShell / VCL / Win64
> 方法论：CTF（建构·追溯·可谬法）→ `docs/CTF.md`
> 协议：DeepSpec 四投影协议 v1.2-draft（data-tree 已就绪）
> 已完成：Phase 1~4（详见 `history.md`）
> Bug 记录：`bugfix.md`

---

## 当前：发布前阻断项（P0/P1）

> 2026-07-08 发布就绪度评估（3 专家）综合分 3.3/10，结论：当前为 0.1.0 原型，不可对外发布。
> 已修缺陷见 `bugfix.md` #1~#14（BUG-4/5/6a/8/9/10/12/13/14 完成 + BUG-11 第1步数据层+校验 + 第2步 ticket 双入口 + 第3步健康度看板）。待修：BUG-7、BUG-6b/6c。
> 路线图依据：wayfinder 文章对照分析 → `docs/wayfinder-对DeepSpec的启发.md`。

### P0：发布阻断（必须修复）

- [ ] **BUG-6b**：DeepBase 作 git submodule 或 vendor DCU（需用户决策：涉及仓库结构变更，DeepBase 须先有独立 git 仓库）
- [ ] **BUG-6c**：加 `.github/workflows/build.yml` CI（需自托管 runner：BDS 商业软件无法用 GitHub 公共镜像）

### P1：发布前应修（三合一主线：雾→ticket→看板）

> 文章核心：DeepSpec 已内建 fog 四态 + 四类探索 ticket 的**全部原语**，但只建了数据模型、没建工作流。以下构成"一次解一个 ticket"主循环，顺序执行。

- [x] **BUG-8（主循环闭环）**：`Controller.GenerateB` 闭环 — LLM 输出经 `CandidateIngest` 强类型沙盒合入活树 → 退雾一步 → `RenderAll` 重渲染。**已修（bugfix #10）**，18 例单测，归档于 `history.md`。
- [x] **BUG-11 第 1 步（数据层）**：issues 读写基础 + ticket 建模。**已修（bugfix #11）**，归档于 `history.md`。
- [x] **BUG-11 第 1 步剩余**：`Validation.ValidateIssue`/`ValidateIssuesFile`（校验 id 非空/枚举合法/affected_nodes 非空/requires_human 与 ticket 类型一致性）+ 8 例 issues 校验单测。**已修（bugfix #12）**，测试 89/89。
- [x] **BUG-11 第 2 步（ticket 创建双入口）**：`RenderProblemsPage` +AIssues 参数 + Fog Map 节点旁 `ticket-create` 按钮 + 挂 ticket 区（复用就绪的 `.ticket` CSS）；`MainView.HandleWebMessage` +`ticket-create` 分支；`MainForm` VCL 菜单/对话框兜底入口；`Controller.CreateTicket` 退雾一步 + 落盘前 `ValidateIssuesFile` + 重渲染。**已修（bugfix #13）**，测试 93/93。
- [x] **BUG-9（健康度看板）**：`RenderIndex` 重构 — 文档健康度（覆盖率/置信度/决策积压/雾区数 4 卡片）+ 高风险问题 + 冲突摘要 + 优化 Prompt 入口（`export-optimization-prompt` JS Bridge 贯通 MainView→Providers→Controller）；`Controller.RenderAll` 加载 issues 传入；`ComputeHealthMetrics`/`CountCrossTreeConflicts` 静态方法；`Controller.ExportOptimizationPrompt` 写 `prompts/optimization-prompt.md`。**已修（bugfix #14 + Task 3）**，测试 97/97。兑现定位文档 §7-9。
- [x] **端到端验证（静态）**：因 GUI/WebView2 无法在 AI 会话内 headless 实跑，改为静态验证——编译 0 error + 测试 97/97 + 逐文件审查 RenderIndex 输出 HTML（4 卡片 + 导出按钮 + 专用 JS Bridge 脚本就绪）。**过程中发现并修复 bugfix #14**（index 页漏 JS Bridge）。完整 runtime 验证（开 research_ticket 看数字变化）仍待用户在 GUI 中实跑确认。
- [ ] **BUG-7**：`DeepBase.InitializeEx` 失败改弹窗提示（替代静默 `OutputDebugString`）；exe 签名 + 补 `VerInfo_Keys` 的 CompanyName/LegalCopyright

### P2：质量改善

- [ ] 关键路径补单测：TreeBuilder / Render / Decisions / Context / SpecStore 写回路径
- [ ] README 加"安装/首次配置 LLM/选目录"章节；移除 `MainForm:260` 的 `TAutoFixScenarioRunner` 硬编码路径
- [ ] Inno Setup 安装包 + WebView2 Runtime 依赖声明

---

## 已完成：编译验证 + 收尾

### 编译验证（全部 Phase）
- [x] Phase 2~4 所有新增/修改代码在 Delphi 13.1 中编译通过 ✅
- [x] DUnitX 单元测试全部通过（81/81，含 18 个 CandidateIngest 闭环测试 + 13 个 Fog 状态机测试；`FailsOnNoAsserts=True` 零假绿） ✅
- 关联：C-P0 / A-P0 / D-P0 / A-P1 / C-P1

### 遗留：未完成的 Validation 用例
- [x] INV-2: parent_id 引用存在性 ✅
- [x] INV-4: gen_status / review_status 值合法性 ✅
- [x] INV-5: 循环依赖检测 ✅
- [x] INV-6: content_hash 一致性（ValidateNodeHashes 方法） ✅
- 关联公理：A2, A7

### 遗留：语义束 UI
- [x] 按束审阅 UI（bundles.html + Accept All / Reject All 按钮 + JS Bridge） ✅
- 关联公理：A1

---

## Phase 5: CLI + Tool Protocol

### B-P0：CLI-first 集成路径
- [ ] 拆分 DeepSpec.Core（库）+ DeepSpec.CLI（Console）+ DeepSpec.Desktop（VCL）
- [ ] 命令：`deepspec init / scan / generate / validate / render`
- [ ] 编译验证
- 关联公理：A5

### B-P1：DeepSpec Tool Protocol / MCP Server
- [ ] deepspec_read / deepspec_validate / deepspec_query / deepspec_update
- [ ] MCP Server 供 Claude / Cursor 调用
- 关联公理：A5

### B-P1：.deepspec/ 自动生成 CLAUDE.md
- [ ] init/scan 时生成 CLAUDE.md 提示 AI agent 参考 .deepspec/

---

## Phase 6: 加固与扩展

### D-P1：Accept 加摩擦 / Reject 减摩擦
- [ ] Accept 增加理由选择，区分"低置信度接受"
- 关联公理：A6

### D-P2：审阅节律 + 项目健康度仪表盘
- [ ] review_overdue 标记 + 仪表盘展示审阅积压
- [ ] 健康度指标：覆盖率 / 置信度 / 决策积压 / 新鲜度
- 关联公理：A2, A3, A6, A7

### C-P2：Kind 受控词表
- [ ] x_ 扩展前缀校验在 Validation 中实现
- 关联公理：A4

### A-P1：快照与回滚
- [ ] `.deepspec/snapshots/` + Generate 前自动快照
- 关联公理：A3, A7

### A-P1：部分成功模式
- [ ] 每棵树独立 gen_status / 错误信息
- 关联公理：A7

---

## 待做：Scan 增强

### DT-6：Scan 注册 data-tree 文件类型
- [ ] 识别 `.sql`, `.prisma`, `.migration.*` 数据模型文件
- [ ] Delphi: 识别 DataModule（.dfm + .pas 组合）

---

## 待做：协议 conformance

### CF-1：data-tree conformance fixtures
- [ ] `valid-with-data-tree` fixture：含 data-tree.yaml 的完整 .deepspec
- [ ] 验证 data-tree 节点 kind 枚举、ID 前缀、data 专属字段

### CF-2：bundle + review-decision fixtures
- [ ] `valid-with-bundles` fixture：含 bundles.yaml
- [ ] `valid-with-review-decisions` fixture：含 review-decisions.yaml

---

## 推荐实施顺序

```
当前 ← 编译验证（Delphi 13.1 dcc64）
Phase 5：B-P0 CLI + B-P1 Tool Protocol
Phase 6：其余 D/C/B/A P1/P2 按反馈推进
```

---

## 代码统计

| 模块 | 单元数 |
|------|--------|
| app/ | 4 |
| services/ | 10（+Context） |
| providers/ | 3 |
| controllers/ | 1 |
| models/ | 1 |
| core/ | 7 |
| **DeepSpec 单元总数** | **26** |

---

## 无法在 AI 会话独立完成的剩余工作

| 项 | 原因 | 谁来做 |
|----|------|--------|
| WebView2 Runtime 未安装时的体验 | 依赖运行环境 | 用户验证 |
| LLM 实际调用稳定性 | 依赖网络/模型 | 联调测试 |
| 跨平台测试 | Win64 only | 后续移植 |
| 真实项目封版验证 | 需要时间和样本 | P6 阶段 |
