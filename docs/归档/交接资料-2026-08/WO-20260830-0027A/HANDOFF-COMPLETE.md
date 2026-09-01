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
