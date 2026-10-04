# AsWish Post-WO-0030 ADR: Difference Seam & Application Service (R1 校准通过版)

## 背景 (Context)
在 WO-0030 (VCL Vertical Spike) 中，我们成功证明了高保真 Visual Baseline 在物理层的可行性。但同时暴露了两个架构断层：
1. **Missing L2/L3 Difference Plugin Seam**：现有 Difference 缺乏插件扩展点，导致 Spike 只能外挂 Python 脚本处理 L2/L3 断言。
2. **Visual Baseline / Agent Handoff Application-Service Boundary Gap**：现有核心操作强耦合 GUI Controller，阻碍了 Headless CLI 与 Test 的自动化集成。

本 ADR 旨在修复这两处架构断层，为最终的全面协议化扫清工程障碍。

---

## 一、ADR-1: Difference Core 去文件化与 Plugin Seam

### 1. 核心架构决议
引入 `IPlatformDifferenceComparator` 扩展缝隙（Existing Difference extension seam）。
**核心边界约束**：Difference Core 彻底“去文件化”。Core 绝对不能知道 `runtime-observation.json`、`visual-binding.yaml` 或任何 VCL 文件路径。它只负责标准协议数据的流转。

### 2. 职责划分
**Difference Core 负责**：
*   Comparator 的注册 (registration) 与分发 (dispatch)。
*   聚合从 Comparator 返回的 `TSpecDifferenceItem`。
*   执行 existing difference 聚合落盘 (`difference.yaml`)。
*   支撑下游 Render / Decision 集成。

**Platform Comparator (如 VCL Comparator) 负责**：
*   解析传入的 platform observation（解耦于文件，由上层传入）。
*   利用提供的 Baseline / Binding Resolver 进行身份反解（`AW_xxx → node.id`）。
*   计算 L2 (observed relation) 与 L3 (runtime style)。
*   执行 Expected vs Observed 比较。
*   产出标准的 `TSpecDifferenceItem`。

### 3. 数据模型纪律
*   **不新增持久化实体**：绝不新增持久化领域实体或 Difference 数据模型。
*   **允许最小 Runtime DTO**：允许新增极其轻量的运行时调用上下文（如 `TPlatformComparisonContext`），但这仅用作内存间的数据传递结构，绝不落盘、不成为 SSOT 协议。
*   **L3 的兼容性映射**：针对 `Appearance`，在不扩充现有协议的前提下，暂时将 L3 映射为现有的 `daContent` 做 **temporary compatibility mapping**（通过 Note/hashes 携带 L3 事实）。这并非宣称 L3 的正式语义就是 `daContent`，是否扩充协议留待后续审查。
*   **Visual Binding 读取抽象**：Comparator 必须通过抽象接口（如 `ResolvePlatformIdentity`）读取 Binding，绝对禁止直接硬编码打开 `visual-binding.yaml`。明确重申：`visual-binding.yaml` 仅为 Spike-local / Non-canonical 实验物，**未被纳入正式 Protocol**。

---

## 二、ADR-2: Application-Service Boundary 修复

### 1. 核心架构决议
将 `ConfirmVisualBaseline`、`RecordDifferenceDecision`、`EvolveBaseline` 等操作从 GUI `Controller` 下沉到纯粹的 Application Service 层。GUI、CLI、Test 必须共享同一个 Application Service 且对其输入条件严格一致。

### 2. 移除所有临时 Human 规则
*   **废除 Rationale 强制规则**：Application Service 不得擅自创造新的 Human Judgment 治理规则（如强求 `--rationale`）。
*   **完全服从 Existing Decisions**：Reason/Rationale 是否必填、合规，完全由现有的 `TAsWishDecisionsService` 规范决定。

### 3. 严格锁定 Human Authority
*   **依赖真实 Decision**：不再使用 `FileExists + String Rationale` 来代表人类权威。
*   **API 签名重构**：如 `ConfirmVisualBaseline` 必须传入确切的 `DecisionId`。Service 内部严格验证：
    1.  Decision 是真实存在的。
    2.  Decision 确由 Human Judgment 产生。
    3.  Decision 正确指向了对应的 Observable / View Spec / Snapshot。
    4.  Decision 状态合法。

### 4. 复用现有四出口机制
`RecordDifferenceDecision` 不得使用松散的字符串 Action，必须严格复用现有 Difference Judgment 枚举：
*   `No important difference`
*   `Acceptable`
*   `Unacceptable`
*   `Unresolved`

### 5. Evolution 强依赖 Human Decision
`EvolveBaseline` 绝对禁止仅靠 `BaselineId + Note` 就直接演进。API 必须要求提供 `DecisionId`，并在验证“Decision outcome 明确允许 Evolution（如 Acceptable）”后，才允许向新的 Canonical Baseline 跨越。

*(注：Test/Automation 在调用这些 API 时可构造 Fixture Decision 来证明链路工作正常，但必须明确文档声明：Test fixture decision ≠ production Human Judgment，自动化无权代理人类权威。)*

---

## 三、后续 Work Order 规划

### WO-0031: 注入 Difference L2/L3 Plugin Seam
**AC (验收标准)**:
1. Difference Core 零 VCL / Winapi 依赖。
2. Difference Core 零硬编码 observation / binding 文件路径。
3. VCL Comparator 成功注册并能输出真实 L2/L3 的 `TSpecDifferenceItem`。
4. 比较结果无缝写入 existing `difference.yaml`。
5. Existing RenderDiff / Decisions 模块无需修改即可继续消费结果。
6. 不新增第二持久化 Difference 模型。

### WO-0032: 抽象 Visual Baseline Application Service
**AC (验收标准)**:
1. Application Service 零 `IShell*` (UI) 依赖。
2. GUI 与 CLI 可调用完全相同的 use-case 方法。
3. Human Judgment 完全且仅来自 Existing Decision 对象。
4. Observable 与 Decision 建立可追溯的强关联。
5. 不新增 rationale 强制验证等私有规则。
6. Evolve 操作被 Existing Human Decision 成功拦截与验证。
7. GUI/CLI 在同输入下能产生哈希等价的 Canonical artifacts。

### WO-0033: Native End-to-End Dogfood 最终检验
**AC (验收标准)**:
跑通完整 AsWish 闭环（彻底弃用 SpikeAdapter 脚本）：
`正式 Baseline → 正式 Handoff → VCL implementation → Implementation Evidence → VCL comparator → Existing Difference → OJP Observable → Human Judgment`
