# AsWish 非 UI 核心功能实现步骤、要点与核心问题探索资料包 (v1.0)

> **文档定位**：本资料包专为深入探索 AsWish 软件的**底层引擎、协议规范、数据流转、状态收敛、证据链体系及差异判定算法**而编制，**完全剥离并排除所有 UI/GUI 表现层细节**（如窗体、控件、WebView2 桥接、CSS、像素布局等），聚焦于系统作为“Human ↔ AI Coding Agent ↔ Software Implementation 开放工程层”的核心实现逻辑。

---

## 目录

1. [第一部分：AsWish 软件本质与非 UI 核心定位](#第一部分aswish-软件本质与非-ui-核心定位)
2. [第二部分：全生命周期功能实现步骤（从零到闭环流水线）](#第二部分全生命周期功能实现步骤从零到闭环流水线)
3. [第三部分：底层核心机制与工程实现要点](#第三部分底层核心机制与工程实现要点)
4. [第四部分：深水区核心问题与理论难题探讨](#第四部分深水区核心问题与理论难题探讨)
5. [第五部分：当前工程资产存量与技术断口清单](#第五部分当前工程资产存量与技术断口清单)

---

## 第一部分：AsWish 软件本质与非 UI 核心定位

### 1.1 软件定位定界（What It Is / What It Is Not）

接手或探索 AsWish 的核心前提，是彻底摒弃旧时代“Spec Editor / AI Requirement Tool / AI Coding Tool”的局限视角。

```text
       ┌──────────┐
       │  Human   │ (意向主体，终审裁决)
       └────┬─────┘
            │  I said / We decided
            ▼
┌─────────────────────────┐
│     AsWish 开放工程层     │ ◄── [本资料包探索的核心领域]
│  (.AsWish/ Protocol)    │     (显影 ➔ 确认 ➔ 建构 ➔ 看见 ➔ 生产 ➔ 验证)
└───────────┬─────────────┘
            │  Context Pack / Verified Baseline
            ▼
┌─────────────────────────┐
│  AI Coding Agent (外部)  │ (Claude Code / Codex / Cursor / Gemini CLI)
└───────────┬─────────────┘
            │  Code Execution / Artifacts
            ▼
┌─────────────────────────┐
│ Software Implementation │ (最终运行的代码与软件系统)
└─────────────────────────┘
```

- **What It Is**：
  AsWish 是位于人类、外部 AI 编码智能体与实际软件实现之间的**开放工程系统与可审计协议载体**。它解决的核心问题不是“需求规格是否写得漂亮”，而是：
  > **Are we still building the same thing?**（我们是否还在构建同一个东西？）  
  > **Where did the difference enter?**（差异究竟从哪里进入了系统？）
- **What It Is Not**：
  - 严禁将其简化为普通的需求管理系统（Jira/Linear 替代品）；
  - 严禁将其视为代码生成工具或 IDE 本身；
  - 严禁将其视为 Agent 编排调度器（Orchestrator）。开发执行始终由外部 Agent 完成，AsWish 负责确立可验证事实、采集实现证据并暴露差异。

### 1.2 理论母体在非 UI 工程层的映射

- **差异一元论 (Difference Monism, DM)**：
  - 核心命题：**差异 + 非任意约束性 = 产生结构的最低起点**。
  - 工程投射：需求不是凭空完美的先验文本，代码也不是无因生成的字符流。从人类原始愿望，到人机共同澄清的规格，再到编译出的二进制与代码 AST，每一个转化阶段都在注入“差异（Difference）”。
  - 目标追求：**不追求零差异（Zero Difference）**，而是追求：
    > **Difference made visible, traceable, and judgeable.**（让差异能够被看见、被追溯、被人类判断）。

### 1.3 核心处理主链

非 UI 视角下的主链压缩口径为六步递进：

```text
显影 (Manifest) ➔ 确认 (Confirm) ➔ 建构 (Construct) ➔ 看见 (See) ➔ 生产 (Build) ➔ 验证 (Verify)
```

1. **显影**：把隐藏在人类脑海或遗留代码中的断口、模糊、未知（Fog of War）暴露出来。
2. **确认**：AI 提出结构化候选理解（ChangeSet），人类以正式决策（Decision）予以裁决。
3. **建构**：将确认项安全并入单一事实源（Canonical Spec 规范树）。
4. **看见**：固化确定性的规格基线（Baseline），提供无可争辩的比对靶标。
5. **生产**：装配无歧义上下文，交付给外部 Coding Agent 独立执行编码。
6. **验证**：采集 Agent 的客观实现证据（Implementation Evidence），计算与基线的差异，闭环重入。

---

## 第二部分：全生命周期功能实现步骤（从零到闭环流水线）

整个软件在无 UI 介入下的完整自动化与半自动化流转共分为九个连续功能步骤：

```text
Step 1: 代码与文档扫描 (Level 0 Scanner)
   ↓
Step 2: 自然语言意向摄入 (Candidate Ingest)
   ↓
Step 3: 结构化候选解释 (Change Set Generation)
   ↓
Step 4: 人类决策与主规格写回 (Decisions & Canonical Merge)
   ↓
Step 5: 视觉/语义基线固化 (Accepted Baseline Anchoring)
   ↓
Step 6: 外部 Agent 任务封包交付 (Context Pack Export)
   ↓
Step 7: 实现事实证据客观采集 (Evidence Harvesting)
   ↓
Step 8: 结构与语义差异计算 (Difference Computation)
   ↓
Step 9: 人类差异裁决与修订循环 (Judgment & Revision Loop)
```

---

### Step 1：冷启动与四投影扫描（Level 0 Scanner & Tree Building）

- **功能目标**：
  在不依赖任何外部 LLM 的前提下，纯通过本地确定性规则与解析器，扫描项目目录，建立 `.AsWish/` 工程空间，并产出四棵投影树的冷启动骨架。
- **数据流与实现机制**：
  1. `TAsWishScanService.ScanDirectory`：分类遍历文件，归为 Documents, Code, UI, Config, AI Rules, Ignored 六大类。
  2. `TAsWishTreeBuilder.BuildFromScan`：
     - **Function Tree**：生成根节点存根 `func-<project>`，标记 `fog_state = unknown_unknowns`，自动解析 `docs/` 下的 Markdown H1/H2 作为子能力。
     - **Module Tree**：根据源码物理目录深度排序，按父子关系派生 `package` / `unit` 结构。
     - **View Tree**：根据 `.dfm` / `.html` / `.vue` / `.tsx` 文件识别窗体与页面，解析组件层级。
     - **Data Tree**：解析代码实体类或数据模式，提取实体、字段、状态转移。
  3. `TAsWishStoreService.WriteTreeFile`：原子落盘至 `.AsWish/trees/*.yaml`。

---

### Step 2：自然语言意向摄入（Candidate Ingest / I said）

- **功能目标**：
  承载人类非正规的、带有歧义或情感倾向的自然语言修改愿望，将其精确绑定到某个已有节点或新建上下文，**绝对禁止直接修改 Canonical Spec**。
- **数据流与实现机制**：
  1. 输入载荷：接收 `NodeId`, `TreeType`, `UserIntent`（如：“把库存列表加一个实时缺货预警字段”）。
  2. 清晰度检测：调用 `TAsWishCandidateIngest.CheckIntentClarity`：
     - 若输入极短（如“修改一下”、“优化”）或缺乏动宾结构，自动构造 `itGrillingTicket` 追问工作项。
  3. 独立持久化：调用 `SaveCandidateIntent`，原子写入 `.AsWish/llm/candidate-intent.yaml`。
  4. 节点注入：在内存 `TSpecNode` 中暂存 `UserIntent`，等待解释器介入。

---

### Step 3：结构化候选解释（Structured Change Set / AI understood）

- **功能目标**：
  AI 将人类的自然语言意图解释为不可混淆的、具备字段级对照的候选变更集（`TChangeSet`），明确区分“你明说的”、“我推断的”与“尚不知道的”。
- **数据流与实现机制**：
  1. 提示词生成：调用 `TAsWishPromptService.WriteChangeInterpretPrompt`，组装包含目标节点上下文、所属语义束与格式约束的解释提示词。
  2. 结构化构建：LLM（或内置解释模块）产出 YAML，反序列化为 `TChangeSet`：
     - `change_set_id`：全局唯一 ID（如 `cs-func-orders-01`）；
     - `raw_user_intent`：完整保留人类意向原文；
     - `items`：变更项数组，每项包含 `target_node_id`, `field`, `before`, `after`, `source_type`, `reason`。
  3. 来源三元分类：
     - `cstExplicit`：人类直接指明的修改（高可信）；
     - `cstInferred`：AI 根据上下文逻辑推导派生的变更（待定）；
     - `cstUnknown`：人类意图中存在模糊、需要反向追问的空缺项。
  4. 持久化隔离：保存于 `.AsWish/llm/change-set-<id>.yaml`，主规格树保持零改动。

---

### Step 4：跨投影影响扩散计算（Semantic Bundle Impact Calculation）

- **功能目标**：
  单一功能点的修改往往引发跨系统多层级震荡。本步骤负责基于语义绑定（Semantic Bundle），自动推导该意图将波及哪些投影。
- **数据流与实现机制**：
  1. 调用 `TAsWishCandidateIngest.ComputeAffectedProjections(ANodeId, ABundles)`。
  2. 检索 `bundles.yaml` 中包含该 `NodeId` 的所有 `TSemanticBundle`。
  3. 遍历 Bundle 内锚定的全部关联节点，推导其命中的投影集合：
     - 例如：修改 `func-orders`（Function）➔ 关联到 `mod-order-service`（Module）、`view-order-detail`（View）、`data-order-item`（Data）。
  4. 将派生结果记录进 `TChangeSet.AffectedProjections`，作为后续审阅与测试影响范围的基准。

---

### Step 5：人类决策收口与权威写回（Decisions Authority & Spec Writeback）

- **功能目标**：
  人类对 `TChangeSet` 行使终审裁决权。**只有人类的 Accept 决策拥有写入 Canonical Spec 的唯一权力**。
- **数据流与实现机制**：
  1. **三种裁决分支**：
     - **Accept**：
       - `TAsWishDecisionsService.RecordChangeSetDecision(LCS, rsAccepted, Rationale)` ➔ 生成 `TSpecDecision`（`Status = dsAccepted`，`DecisionType = dtConfirm`，写入 `requirement-decisions.yaml`）。
       - `TAsWishCandidateIngest.ApplyChangeSet` ➔ 将 `AfterValue` 写入内存节点，更新 `ReviewStatus := rsAccepted`、`GenStatus := gsConfirmed`、`Status := nsConfirmed`，追加 `decision_refs`。
       - 原子写回磁盘：`FSpecStore.WriteTreeFile` 写入 `.AsWish/trees/`。
       - 自动触发协议验证：`TYamlValidator.ValidateTreeFile`。
     - **Reject**：
       - 生成 `Status = dsRejected`、`DecisionType = dtReject` 决策，记录拒绝理由与 `ChangeSetId`。
       - `ApplyChangeSet` 检查状态后**立即 return**，Canonical Spec 变更数为 0。
     - **Clarify**：
       - 生成 `Status = dsProposed`、`DecisionType = dtClarify` 决策，记录待澄清细节，主规格完全不变，等待发起下一轮意向。
  2. **写前快照备份**：在覆盖任何 `trees/*.yaml` 之前，`BackupTreeFileIfExisting` 自动拷贝至 `snapshots/<tree>.bak.yaml`，防止历史丢失。

---

### Step 6：视觉与语义基线固化（Accepted Baseline Anchoring）

- **功能目标**：
  在外部 Agent 动手写代码之前，冻结并持久化一份“已确认事实与视觉规格基线”，形成后续比对不可篡改的锚点。
- **数据流与实现机制**：
  1. 架构纪律：**禁止新建平行的 `VisualBaseline` 实体**，完全复用现有 `TSpecSnapshot` 机制。
  2. 基线内容：包含当前已接受的所有 `view-tree` 节点、布局约束、字段定义及其关联的 `DecisionId`。
  3. 版本与哈希锚定：计算 `ContentHash` 与 `RelationHash`，记录固定的 `renderer_version`，保证相同规格在任何时候重放渲染均保持绝对确定性。

---

### Step 7：外部 Agent 任务封包交付（Context Pack Export）

- **功能目标**：
  AsWish 不替代 Agent（如 Claude Code / Cursor / Codex），而是为其生成高密度、无歧义、强约束的上下文任务包。
- **数据流与实现机制**：
  1. 调用 `TAsWishPromptService.WriteContextPack` 与 `WriteGenerationPrompt`。
  2. 导出产物：
     - `context-pack.md`：工程概貌、四投影关系、代码物理结构、已有权威决策。
     - 严格约束注入：明确声明禁止越界修改 `.AsWish/` 之外的受限目录，要求 Agent 输出实现证据。

---

### Step 8：客观实现事实证据采集（Implementation Evidence Harvesting v0）

- **功能目标**：
  **绝不相信 Agent 的自我陈述（“Agent 汇报说做完了”不等于事实）**。系统必须主动从代码仓库与文件系统中采集客观物理证据。
- **数据流与实现机制**：
  1. 变动采集器：扫描 Agent 执行后的工作区，采集受影响的文件列表、行号区间、类/函数声明 AST、数据迁移脚本。
  2. 结构化构建：生成 `TSpecEvidence` 实体：
     - `Id`：唯一证据 ID（如 `ev-code-order-discount`）；
     - `SourceLayer := slParsedFromA`；
     - `Path`、`Lines`、`Excerpt`；
     - `ContentHash` 与 `SourceFileHash`（用于未来检测证据是否失效/stale）。
  3. 原子持久化：写入 `.AsWish/evidence/source-evidence.yaml`。

---

### Step 9：差异计算引擎与修订闭环（Difference Computation & Revision）

- **功能目标**：
  比对“Step 6 固化的基线（What we confirmed）”与“Step 8 采集的客观证据（What was actually built）”，计算并输出结构性差异。
- **数据流与实现机制**：
  1. 差异计算（Difference v0 - 结构差异算子）：
     - **存在性差异**：基线声明的字段/函数在代码证据中缺失（Missing Implementation）。
     - **越界差异**：代码证据中出现了基线中声明 `not_doing` 或未声明的额外副作用（Unintended Mutation）。
     - **跨投影断裂**：数据树字段已改，但模块树中的调用方未感知（Broken Reference）。
  2. 产出 `Difference v0` 记录：列出差异项，**系统保持中立，不判定对错（Difference ≠ Error）**。
  3. 人类裁决重入：
     - 人类判定“此差异是好的进化” ➔ 触发 Accept ➔ 自动回补主规格（反向学习）。
     - 人类判定“此差异是 Bug” ➔ 提出自然语言修正 ➔ **无缝重新进入 Step 2（I said）**，开启第二轮循环。

---

## 第三部分：底层核心机制与工程实现要点

### 要点 1：四树正交投影与单一事实源（SSOT）

```text
               ┌──────────────────────┐
               │    project-spec      │ (索引与全局版本)
               └──────────┬───────────┘
     ┌──────────────┬─────┴────────┬──────────────┐
     ▼              ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Function │  │  Module  │  │   View   │  │   Data   │
│   Tree   │  │   Tree   │  │   Tree   │  │   Tree   │
│ (做什么)  │  │ (在哪做)  │  │ (看见啥)  │  │(数据/状态)│
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

1. **投影单一职责**：
   - `function-tree`：纯语义功能能力，描述业务逻辑，无实现细节。
   - `module-tree`：代码所有权结构（Package, Unit, Class, Service）。
   - `view-tree`：用户可操作的工作流与视觉构件。
   - `data-tree`：**第四棵树绝非泛型风险树**，而是明确承载 Schema、实体、字段、状态转移、持久化与数据迁移风险。
2. **SSOT 原则**：
   - 唯一的真相源是 `.AsWish/trees/*.yaml`。
   - 任何导出的 Markdown、HTML、图表均为瞬态投影，**禁止从衍生视图反向反编译篡改主规格**。

---

### 要点 2：双正交状态机与战争迷雾（Fog of War）收敛机制

AsWish 摒弃了一维的 `Status` 字符串，采用严格解耦的正交状态模型：

```text
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   gen_status    │   ×   │  review_status  │   ×   │    fog_state    │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ gsDraft         │       │ rsUnreviewed    │       │ fsUnknownUnknowns│
│ gsGenerated     │       │ rsAccepted      │       │ fsFoggy         │
│ gsConfirmed     │       │ rsRejected      │       │ fsMisty         │
│ gsSkipped       │       │ rsDeferred      │       │ fsClear         │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

1. **正交约束**：
   - `gen_status`：描述内容的**生成演进**（AI 算出来了没有）。
   - `review_status`：描述内容的**人类政治地位**（人类认不认可）。
   - 典型组合：`gen_status = gsGenerated` + `review_status = rsAccepted` ➔ 稳态事实；`gen_status = gsGenerated` + `review_status = rsUnreviewed` ➔ 待审候选。
2. **迷雾单向收敛纪律（Fog Monotonic Convergence）**：
   - 理论依据：来自 Wayfinder 与战争迷雾思想。大任务在动手前终点必定在雾里。
   - 状态转移单向不可逆：`fsUnknownUnknowns` ➔ `fsFoggy` ➔ `fsMisty` ➔ `fsClear`。
   - **禁止 LLM 一次性消除迷雾**：LLM 的单次生成只能将节点从存根推进到 `fsFoggy`；只有经过研究、原型或人类正式 Decision 裁决，才能逐步逼近 `fsClear`。

---

### 要点 3：严苛的人机权力边界（Human Control Boundary）

工程代码中硬编码了人机权力的绝对物理隔离：

| 权限领域 | AI / LLM 边界 | Human 边界 |
| :--- | :--- | :--- |
| **主张属性** | 只能生成 `source_layer: ai_inferred`，严禁伪造 `human_decision` | 独占 `source_layer: human_decision` |
| **状态擢升** | `gen_status` 最高只能到 `generated`，**严禁自行标记 `confirmed`** | 唯有人类可将节点置为 `confirmed` |
| **审阅状态** | `review_status` 强制重置为 `unreviewed`，无权自我标记 `accepted` | 唯有人类可做出 `accepted` / `rejected` |
| **落盘权限** | 仅允许写入 `.AsWish/llm/` 临时空间 | 独占写回 `.AsWish/trees/` Canonical Spec 权力 |

---

### 要点 4：CTF Semantic Bundle（跨投影语义束）与影响控制

- **定义**：语义束（`TSemanticBundle`）是将跨越四棵树、服务于同一个业务概念的一组节点锚定在一起的语义绳结。
- **作用**：
  1. 避免全局图遍历的高昂开销，以 $O(1)$ 的直接索引计算变更的影响扩散范围（Blast Radius）；
  2. 保证批量审阅的原子性（Batch Review）：对一个 Bundle 执行 Accept，其锚定的所有树节点同批次跃迁，防止出现“接口改了但界面未确认”的半吊子状态。

---

### 要点 5：协议不变式（Invariants INV-1 ~ INV-10）与原子写保护

所有非 UI 服务在修改磁盘状态时，必须接受协议不变式的物理约束：

1. **INV-1 & INV-2 (DAG 拓扑完整性)**：节点 ID 树内唯一；`parent_id` 必须指向同树中已存在的合法节点，防止悬挂孤儿。
2. **INV-5 (证据倒查)**：处于 Accepted 状态的节点，其 `source_refs` 或 `decision_refs` 至少有一个非空。
3. **INV-7 (锁保护)**：已锁定的节点，AI 再次生成时直接跳过，绝不静默覆盖。
4. **底层原子落盘机制 (`AtomicWriteTextFile`)**：
   - 绝不使用裸文件写流（防止断电或崩溃产生 0 字节半截文件）；
   - 算法：先写入临时文件 `.tmp-<UUID>` ➔ 调用 Win32 `ReplaceFileW` 实施原子置换 ➔ 失败时降级 `MoveFileExW` 保持原文件不灭。

---

## 第四部分：深水区核心问题与理论难题探讨

在脱离 UI 的工程与协议底层，存在五个极深的核心问题，是支撑 AsWish 持续演进的理论高地。

---

### 探讨 1：“Are we still building the same thing?” —— 语义同一性的判定困境

#### 问题的严峻性
传统软件工程假设“PRD 是一张图纸，代码是按图施工的砖瓦”。但在 AI 编程时代，自然语言意图极其灵活，代码实现极其多变，**我们如何证明代码实现与最初意图是“同一个东西”？**

#### 探索结论与解法
1. **直接比对的不可能性**：无法用自然语言和 AST 代码直接求 Diff。两者处于完全不同的表示空间（Representation Space）。
2. **正交投影作为度量中介**：
   AsWish 提出的解法是构建四投影规范（四棵树）。当用户说“增加折扣功能”时，系统将其分解为：
   - 行为空间（Function 是否增加能力？）
   - 归属空间（Module 是否在对应类中实现？）
   - 视图空间（View 是否增加折扣显示？）
   - 数据空间（Data 是否引入持久化字段？）
3. **同一性判据**：
   若且唯若这四个投影的预期事实与采集到的代码物理证据（Evidence）在关键断言上**满足非任意约束的一致性映射**，系统才宣布“我们还在构建同一个东西”。否则，差异发生。

---

### 2. 探讨 2：“Where did the difference enter?” —— 差异注入链与误差放大模型

#### 差异产生路径分析
差异不是在代码敲完那一刻突然出现的，而是在链路中逐级渗透放大的：

```text
[人类潜意识真实愿望]
   │  Δ1: 表达差异 (无法用语言完全说清)
   ▼
[I said: 原始意图文本]
   │  Δ2: 解释差异 (LLM 误解、幻觉或过度推断)
   ▼
[Change Set: 候选变更集]
   │  Δ3: 确认漂移 (人类不仔细看，误点了 Accept)
   ▼
[Canonical Spec: 固化规格]
   │  Δ4: 实施偏离 (外部 Agent 采用了不同的架构模式)
   ▼
[Actual Implementation: 最终代码]
```

#### 应对机制
AsWish 的非 UI 核心正是通过在每个转化节点设立“留痕哨卡”来锁定泄漏源头：
- `candidate-intent.yaml` 冻结原始输入（捕获 $\Delta 1$）；
- `change-set.yaml` 显式划分 `explicit` / `inferred` / `unknown`（隔离 $\Delta 2$）；
- `requirement-decisions.yaml` 记录每一次决策的裁决者与理由（锁定 $\Delta 3$）；
- `source-evidence.yaml` 捕获最终物理证据，通过结构比对暴露 $\Delta 4$。
由此，当最终结果不对劲时，系统可以精确回溯出：**差异究竟是在第几级被引入的**。

---

### 探讨 3：Difference ≠ Error 的本质与反向吸收

#### 核心洞察
在传统的编译器或测试框架中，差异即报错（Mismatch = Failure）。但在人机共创中，**外部 Agent 制造的差异，经常包含着更优秀的技术构想**。
- 例如：人类意图要求在数据库存一个浮点数字段，而 Agent 依据性能与货币精度考虑，在代码中采用了定点数 `Decimal` 并增加了幂等校验。
- 如果将此简单判为 Error 并强行回滚，AI 的智慧就被抹杀了。

#### 工程模型
AsWish 规定 Difference 是中性的“客观存在的事实差异”：
```text
                  ┌────────────────────┐
                  │ Computed Difference│
                  └─────────┬──────────┘
                            │
               Human Judgment / Review
                            │
           ┌────────────────┴────────────────┐
           ▼                                 ▼
   [Unacceptable Error]             [Acceptable Evolution]
           │                                 │
     进入 Revision                     触发 Reverse Writeback
  (提出修正，打回重做)               (主规格吸收该差异，提升为规范)
```
这种设计让系统具备了**反向学习（Reverse Specification Ingestion）**的能力。

---

### 探讨 4：客观实现证据采集困境（The Evidence Grounding Problem）

#### 为什么禁止 Agent “自说自话”？
目前几乎所有 AI Coding 流程最大的漏洞在于：**由负责写代码的 Agent 自己向人类汇报“我搞定了”**。
- LLM 会为了迎合人类而产生谄媚性输出（Sycophancy）；
- LLM 会认为自己改了代码，但实际上漏掉了核心边缘分支；
- LLM 自称“测试全通”，但实际上测试脚本本身被它偷梁换柱。

#### 事实接地（Fact Grounding）原则
AsWish 的非 UI 实现坚决将“证据采集”剥离给独立执行模块：
1. **独立探针**：绕过 Agent 的对话流，直接分析物理文件系统的差异；
2. **确定性哈希**：通过对文件内容计算 SHA256，与原代码基线比对，证明哪些文件发生了真实改变；
3. **AST 级事实提取**：直接解析源码符号表，提取类名、方法名、注解，作为无可辩驳的证据存入 `source-evidence.yaml`。

---

### 探讨 5：多轮修订（Revision）的循环收敛性定理

#### 陷入震荡的工程风险
当系统引入了 `Human Intent ➔ Implementation ➔ Difference ➔ Revision` 闭环后，最危险的工程灾难是**无限震荡**：
- 人类提要求 ➔ Agent 改偏了 ➔ 人类提修正 ➔ Agent 改对了局部但毁了全局 ➔ 规格文件碎片化膨胀。

#### 收敛性控制要点
为了保证循环必定收敛，系统设立了三大非 UI 纪律：
1. **版本快照强制滚动**：每一次进入新一轮 Revision，旧基线自动封存为不可修改的历史快照，新基线必须基于继承链演进；
2. **不变式守护网（Invariant Gate）**：新一轮的 ChangeSet 无论如何调整，必须在写入前跑通全量拓扑验证（`ValidateTreeFile`），阻断断裂引用；
3. **单一任务穿透（Dogfood Task Discipline）**：在闭环演进期间，禁止半途扩大业务范围，必须用同一个小任务贯彻始终，直至形成完全清楚的确认闭环。

---

## 第五部分：当前工程资产存量与技术断口清单

### 5.1 已经成立并就绪的非 UI 底座（Ready & Verified）

经过 `0027A`、`0027B`、`0027C`、`0027D` 的四轮严苛交付与主控复核，以下能力已在 `main` 分支完整就绪并通过全量测试（**DUnitX 149/149 PASS**）：

1. **意图层（Intent Layer）**：
   - 数据模型：`TCandidateIntent`（`src/models/AsWish.Models.pas`）；
   - 存储服务：`SaveCandidateIntent` / `LoadCandidateIntent`（`src/services/AsWish.Services.CandidateIngest.pas`）；
   - 模糊检测：`CheckIntentClarity` 触发 `grilling_ticket`。
2. **候选解释层（Change Set Layer）**：
   - 数据模型：`TChangeSet`, `TChangeItem`, `TChangeSourceType`；
   - 格式化与解析：`FormatChangeSetYaml` / `ParseChangeSetYaml`；
   - 影响计算：`ComputeAffectedProjections`（基于 `TSemanticBundle`）；
   - 解释提示词导出：`WriteChangeInterpretPrompt`（`src/services/AsWish.Services.Prompts.pas`）。
3. **裁决与写回层（Decisions & Writeback Layer）**：
   - 决策模型：`TSpecDecision` 支持 `ChangeSetId` 与 `ChangeItemIndex` 深度追溯；
   - 写回引擎：`ApplyChangeSet` 独占主规格写回权限，安全转移状态机（`rsAccepted`, `gsConfirmed`）；
   - 隔离机制：`RejectChangeSet` 与 `ClarifyChangeSet` 严密保护 Canonical Spec 零变动；
   - 规范验证：`TYamlValidator.ValidateTreeFile`；
   - 自动备份：`BackupTreeFileIfExisting` 滚动备份至 `snapshots/`。
4. **控制与无头 CLI 接口**：
   - `TAsWishController` 五大方法全套就绪；
   - `cli/bin/AsWish.CLI.exe` 完整支持 `init`, `scan`, `validate`, `intent`, `changeset review/accept/reject`。

---

### 5.2 亟待攻克的非 UI 技术断口（Gaps to Close）

为了迈向真正的 `First Closed Loop`（第一闭环自检验），后续仍有四个非 UI 核心断口需要立票研发：

```text
[已就绪: 0027A~D] 
       ↓
[断口 1: WO-20260830-0028] Accepted Visual Baseline（固化基线快照）
       ↓
[断口 2: Implementation Evidence v0] 实施事实客观采集器
       ↓
[断口 3: Difference v0] 结构差异计算算子（非像素级 Diff）
       ↓
[断口 4: Revision Loop Protocol] 多轮闭环协议重入与收敛控制
```

1. **断口 1：Accepted Visual Baseline 协议固化（WO-20260830-0028）**
   - 缺口：目前尚未实现将 `view-tree` + 布局约束固定为确定性结构线框快照的持久化机制。
   - 要点：复用 `SpecSnapshot`，锁定 `renderer_version`。
2. **断口 2：Implementation Evidence v0 采集器**
   - 缺口：目前代码库缺乏在 Agent 运行后、自动分析源码变更并生成 `source-evidence.yaml` 的无头采集服务。
   - 要点：不依赖 AI 自报，纯代码物理分析。
3. **断口 3：Difference v0 结构差异算子**
   - 缺口：目前尚无代码能自动比对“基线快照”与“实现证据”，产出结构性差异报告。
   - 要点：定义差异数据模型 `TSpecDifference`，只陈述事实，不判对错。
4. **断口 4：Revision 多轮闭环自检验（Dogfood Green）**
   - 缺口：全流程虽然单点跑通，但尚未由 AsWish 自身选定一个真实微型任务，完整跑通从意图到二次修订的端到端真实闭环。

---

## 结论与行动建议

本资料包梳理表明：**AsWish 的非 UI 核心引擎已经具备了非常扎实、高密度且逻辑严密的工程底座**。
在剥离所有 UI 纷扰后，系统的本质是一个**以四树投影为坐标系、以不变式和正交状态机为轨道、以可审计证据链为支柱的差异收敛与验证引擎**。

后续工程推进应严格遵守：
1. **不增设任何平行实体**；
2. **坚决捍卫 Human Decision 权威边界**；
3. **以 Dogfood Protocol 选定单一真实微型任务穿透全程**；
4. **优先补齐 Evidence 采集与 Difference 结构计算两大非 UI 断口**，最终达成 First Closed Loop 的战略目标。
