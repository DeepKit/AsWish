# BUG-9 设计：健康度看板（RenderIndex 重构 + 优化 Prompt 入口）

> 日期：2026-07-09
> 状态：设计稿（待评审）
> 关联：tasks.md P1「BUG-9」；定位文档 §7-9；wayfinder 主线第 3 步
> 前置：BUG-11 第 2 步（ticket 创建双入口）已完成并归档（bugfix.md #13），issues 这条线已具备真实数据来源。

---

## 1. 背景

三合一主线（雾→ticket→看板）的前两步已落地：
- BUG-8（GenerateB 闭环）+ BUG-11 第 1 步（issues 读写 + 校验）+ 第 2 步（ticket 创建双入口）。

当前 `RenderIndex`（`Render.pas:165`）是一个极简页面：只有「页面列表 `<ul>`」+ 首次扫描提示。**没有任何健康度指标、没有 issues、没有优化 Prompt 入口**。它被调用于 3 处（`Controller:332/391/800`），签名仅 `(ProjectName, TotalFiles, HasDataTree)`——但每次调用后，节点列表与 `LoadIssuesForRender` 都已在紧随其后的代码里算好（用于 `RenderProblemsPage`）。也就是说，**重构所需的数据本就在手边，只是没传给 RenderIndex**。

定位文档 §7-9 给出看板应有的区域：§7.2 文档健康度（文档集是否「足够让 AI 开发」）、§8 doc_issues（issue 类型，含四类探索 ticket）、§9 仪表盘区域 = 文档健康度 / 高风险问题 / 三树预览 / 无证据节点 / 冲突来源 / 优化 Prompt / 前后变化。

本步把 RenderIndex 从「静态页面索引」升级为「健康度看板」，并接上优化 Prompt 的 JS Bridge 入口——兑现定位文档 §1.1「旁路工具」的终局价值：用户把 Prompt 拷给自己的 AI 工具去优化底层文件。

## 2. 设计要点

### 2.1 RenderIndex 签名扩展

```
RenderIndex(AProjectName: string; ATotalFiles: Integer; AHasDataTree: Boolean;
            AFunc, AModule, AView, AData: TList<TSpecNode>;
            AIssues: TList<TSpecIssue>)
```

- 全部 nil 安全（与 `RenderProblemsPage` 同款防御）。
- 3 处 Controller 调用点复用**已经**为 `RenderProblemsPage` 算好的节点列表与 `LoadIssuesForRender`，**不增加额外文件 IO**。

### 2.2 健康度指标（纯函数提取）

新增 `THealthMetrics` record + `ComputeHealthMetrics(AFunc,AModule,AView,AData): THealthMetrics`，置于 Render.pas（与既有 `FogStateCssClass` 等局部 helper 同域），便于单测：

```
THealthMetrics = record
  TotalNodes, ConfirmedNodes: Integer;
  CoveragePct: Double;            // ConfirmedNodes / TotalNodes * 100
  AvgConfidence: Double;         // low=0.3 / medium=0.7 / high=1.0，均值
  DecisionBacklog: Integer;      // status=open 的 issue 数（由 RenderIndex 传入 issues 统计）
  FogCount: Integer;             // 4 棵树中 FogState <> fsClear 的节点数
  HighRiskOpen: Integer;         // severity in {critical,high} 且 status=open
end;
```

- 四项指标复用既有 `.stat` 卡片样式（Render.pas 既有 CSS），零新增样式即可呈现。
- Coverage/置信度/雾区数：纯由节点列表推导，可单测。
- DecisionBacklog/HighRiskOpen：由 issues 推导，也可单测（构造 issue 列表）。

### 2.3 看板区域（index.html 顶部，置于现有页面列表之上）

1. **文档健康度**：4 张 `.stat` 卡片（覆盖率 / 平均置信度 / 决策积压 / 雾区数）。覆盖率与置信度显示百分比并带一句中文释义（§7.2「文档够不够 AI 开发用」）。
2. **高风险问题（top 5）**：`severity ∈ {critical,high}` 且 `status=open` 的 issue，按 severity 降序取前 5，每条显示 id/title/severity 徽章，链接到 `problems.html`。空则显示「当前无高风险未决问题」。
3. **冲突摘要**：复用 `RenderProblemsPage` 既有的跨树断引用检测逻辑——**抽出为共享 helper** `CountCrossTreeConflicts(...)`，index 显示数量 + 链接到 problems.html，problems.html 显示详情（行为不变，仅共享代码，DRY）。
4. **优化 Prompt 入口**：单个 `<button data-action="export-optimization-prompt">导出优化 Prompt</button>`，点击经 JS Bridge `postMessage({action:'export-optimization-prompt'})` 回调 Controller。

### 2.4 JS Bridge：export-optimization-prompt

- `HandleWebMessage` 增 `else if LAction = 'export-optimization-prompt' then ...` → 新回调 `FOnExportOptimizationPrompt: TExportPromptProc`。
- **Controller.ExportOptimizationPrompt**：依据当前健康度组装一段**静态**优化 Prompt 字符串（项目名 + 主要缺口：覆盖率不足 / 雾区节点清单 / 高风险问题清单 / 冲突清单）→ 写入 `.deepspec/prompts/optimization-prompt.md` → 日志输出路径供用户复制。**不调用 LLM**——Prompt 由当前健康态静态拼装，用户自行拷给原 AI 工具（§1.1 旁路原则）。
- 复用既有 `DeepSpec.Services.Prompts` 的风格/格式约定，不引新基础设施。

### 2.5 接线（镜像 BUG-11 第 2 步的三层闭包模式）

- `DeepSpec.Providers.MainView.pas`：定义 `TExportPromptProc = reference to procedure;` + `FOnExportOptimizationPrompt` 字段，穿入 `TBrowserNavigator.CreateFor` / provider 构造（与 `TCreateTicketProc` 同款三层）。
- `DeepSpec.Providers.pas` `RegisterAllProviders`：再加一个闭包包装 `AController.ExportOptimizationPrompt`。
- `MainForm`：无需改动（已传 `FController`）。

### 2.6 单测

新增 `THealthMetricsTests` fixture，4 例：`Coverage_ZeroNodes`/`Coverage_Partial`、`AvgConfidence_Mixed`、`FogCount_AcrossTrees`、`Backlog_OpenOnly`。期望 **97/97**（93 + 4）。

> Controller.ExportOptimizationPrompt 依赖文件 IO，不在单测覆盖；静态 Prompt 拼装信任由健康度单测 + 既有 Render 路径保证。

## 3. 改动文件

| 文件 | 改动 |
|------|------|
| `src/services/DeepSpec.Services.Render.pas` | RenderIndex 加 6 参数；新增 `THealthMetrics` + `ComputeHealthMetrics`；新增共享 `CountCrossTreeConflicts`；4 看板区域渲染；既有 RenderProblemsPage 的冲突检测改调共享 helper |
| `src/controllers/DeepSpec.Controller.pas` | 3 处 RenderIndex 调用传节点+issues；新增 `ExportOptimizationPrompt`（组装 Prompt + 写盘 + 日志） |
| `src/providers/DeepSpec.Providers.MainView.pas` | `TExportPromptProc` + `FOnExportOptimizationPrompt` 字段；`HandleWebMessage` 加 `export-optimization-prompt` 分支；穿入 CreateFor/构造 |
| `src/app/DeepSpec.Providers.pas` | `RegisterAllProviders` 加第二个闭包（ExportOptimizationPrompt） |
| `tests/Test.DeepSpec.Models.pas` | 新增 `THealthMetricsTests`，4 例 |

## 4. 编译与验证

1. 编译测试（dcc64，见 memory `delphi-build-via-bash`）→ 期望 0 error。
2. 跑测试 `tests/DeepSpec.Tests.exe` → 期望 **97/97**。
3. 编译主程序 → 期望 0 error。
4. 端到端（第 3 步正式做，本步先静态确认链路通）：实跑扫描 → index.html 出现 4 张健康卡片 + 高风险区 + 冲突数 + 优化 Prompt 按钮 → 点按钮 → `.deepspec/prompts/optimization-prompt.md` 落盘 → 日志显示路径。

## 5. 范围边界

- 仅健康度看板 + 优化 Prompt 入口。**不做**：schema 变更、新校验规则、export-prompt 的 VCL 兜底入口（与 ticket VCL 兜底同处理：记 tasks.md 待办）、§9「前后变化」diff 视图（需快照历史，超范围，记 TODO）。
- 冲突检测保持共享 helper，problems.html 行为不变（仅共享代码）。
- 优化 Prompt 为**静态**拼装字符串，非 LLM 调用。
- 健康度 helper 放 Render.pas（与既有局部 helper 同域），不新建单元。

## 6. 跟踪文件对齐（收尾）

实现完成后：
- `tasks.md`：BUG-9 `[x]`，标 bugfix #14。
- `history.md`：归档 BUG-9。
- `bugfix.md`：追加 #14（现象/修复/设计取舍/验证/范围边界）。
