# ASWISH-FIRST-PUBLIC-EXPERIMENT-READINESS-REPORT

> 审计日期：2026-08-30
> 审计方式：基于当前仓库实际文件、代码、协议与测试的只读审计，未做任何代码修改。
> 审计范围：`README.md`、`SPEC.md`、`docs/`、`protocol/`、`src/`、`cli/`、`tests/`、`bin/`、`installer/`、`WO/`。
> 结论一句话：**主链前半段（材料 → 四投影 Spec → 视觉审阅 → 人类决策 → Prompt 导出）已经工程化落地；主链后半段（实现证据 → Difference → 实现后人类确认 → 修订闭环）在代码层面是结构性空白。距离"陌生人第一次真实实验"，缺的不是概念，而是三个可执行的工程环节。**

---

## 1. 当前能力地图

产品主链：`Problem Manifestation → Decision Confirmation → Co-construction → Specification → Visual Baseline → Agent Development → Implementation Evidence → Difference → Human Confirmation → Revision`

| 环节 | 状态 | 核心证据 |
|---|---|---|
| 自然语言输入 | 部分具备 | `src/services/AsWish.Services.LLM.pas`、`src/controllers/AsWish.Controller.pas` |
| Problem Manifestation（PFM） | 部分具备（以 Fog/defog/grilling 近似承载） | `src/services/AsWish.Services.Prompts.pas`（`WriteGrillingPrompt`、`fog_state`） |
| Decision Confirmation | **已具备** | `src/services/AsWish.Services.Decisions.pas`、CLI `decisions apply` / `bundle apply` |
| Co-construction / Candidate Ingest | 部分具备 | `src/services/AsWish.Services.CandidateIngest.pas`、CLI `ingest` |
| Specification / Representation | **已具备** | `src/services/AsWish.Services.TreeBuilder.pas`、`AsWish.Services.SpecStore.pas`、`AsWish.Services.Scan.pas` |
| Visual Baseline | 部分具备 | `src/services/AsWish.Services.Render.pas`、`src/providers/AsWish.Providers.MainView.pas`（WebView2 JS Bridge） |
| Agent 接入 | 部分具备 | `ExportPrompt`（`src/controllers/AsWish.Controller.pas`）、`src/services/AsWish.Services.Prompts.pas` |
| Implementation Evidence | **缺失** | `SpecStore` 仅创建空 `evidence/source-evidence.yaml`；无实现后采集逻辑 |
| Difference | **缺失** | 全库无 spec-vs-implementation / baseline-vs-current 对比代码 |
| Human Confirmation（实现后） | **缺失**（依赖前两项） | 无实现结果回人通道 |
| Revision / 迭代 | 部分具备 | `src/services/AsWish.Services.Snapshot.pas`（快照/列表/恢复） |

---

## 2. 已经具备的能力（可直接支撑第一次实验）

1. **协议与工作区骨架完整且语言无关**。`SPEC.md` v1.2-draft + `protocol/schemas/`、`state-machine.md`、`invariants.md`、`controlled-vocab.md`、`conformance/run.py`。`.AsWish/` 目录结构（trees / bundles / relations / evidence / issues / decisions / agents）全部有落盘位置。
2. **决策确认机制是真实实现，不是蓝图**。`AsWish.Services.Decisions.pas` 提供 `AddDecision / AcceptDecision / RejectDecision / PromotePending / ApplyNodeStatusTransitions`；GUI 有 Promote Pending Decisions 命令（`src/app/AsWish.Commands.pas`）；CLI 有 `decisions apply`、`bundle apply`。正交状态 `gen_status / review_status` 已入协议。
3. **四投影生成与存储闭环**。`Scan` → `TreeBuilder` → `SpecStore` 写入 `.AsWish/trees/*.yaml`；`Validate` 一致性检查；`Render` 出 HTML 审阅页。
4. **视觉审阅界面已工程化**。WebView2（TEdgeBrowser）+ JS Bridge 双向通信（`AsWish.Providers.MainView.pas`），人可以在 HTML 审阅页上确认/拒绝候选项，决策写回 `.AsWish/decisions/`。
5. **Prompt 导出 + 候选合并是可用的 Agent 接缝**。`ExportPrompt` 生成上下文包给外部 Agent；`CLI ingest` 校验候选 YAML 并按节点 ID 合并、保留人类审阅状态（`CandidateIngest`）。
6. **Fog of War / grilling 追问机制存在**。`fog_state`、`unknown_unknowns`、`WriteGrillingPrompt`、`DefogNodeById`，为"一次推进一个明确问题"提供了现成载体。
7. **冷环境零依赖启动路径存在**。`protocol/tools/init_workspace.py`（纯标准库）可在无 Delphi 环境初始化合规工作区；`protocol/readers/python|typescript` 提供程序化读取；`protocol/examples/` 有 4 个种子工程（docs-only / go-microservice / python-fastapi / react-web）。
8. **快照机制存在**。`AsWish.Services.Snapshot.pas` 的 `CreateSnapshot / ListSnapshots / RestoreSnapshot`，是未来 difference trace 的天然基座。
9. **质量基线可信**。DUnitX 126/126 通过，覆盖 Decisions / SpecStore / TreeBuilder / Render / Snapshot / CandidateIngest / Validation / Yaml.Parser 等核心服务。
10. **交付物已存在**。`bin/AsWish.exe`、`cli/bin/AsWish.CLI.exe`、Inno Setup 安装脚本（`installer/AsWish.iss`，含 WebView2 运行时检测与官方下载引导）。

## 3. 部分具备的能力

1. **自然语言输入**：目前唯一的自然语言消费点是 LLM 配置 + GUI "Generate B"（`AsWish.Services.LLM.pas` 的 `Generate/GenerateWithSystem`，OpenAI-compatible，ModelScope 默认端点）。没有"在任意 Spec 节点上用自然语言纠错/补充"的入口。`WO-20260830-0027A` 已规划此能力（`user_intent` 原文附着到 candidate），但尚未落进本仓库代码。
2. **Problem Manifestation**：无任何 `manifestation / intent / problem` 命名的代码。当前近似物是 Fog 探索（foggy / unknown_unknowns / defog / grilling）。PFM 作为方法论没有独立的工程承载——这不一定要新建实体，但"前线问题显影"目前在产品里没有明确入口。
3. **Visual Baseline**：现有 HTML 是一次性生成审阅页，不是"已确认、可留存、可被实现结果对比的视觉基线快照"。`WO-20260830-0028`（Accepted Visual Baseline）已规划且明确"本票不负责开发后截图比对"——即实现后视觉对比目前**无人认领**。
4. **Agent 接入**：协议里有 `agents/agent-results.yaml`、SPEC §7 要求记录 assumptions/tradeoffs/unresolved questions 等，但**代码中没有任何写入 agent-results 的路径**。Agent 接入是"导出 prompt + 手工回灌 ingest"，没有 Claude Code / Codex / Cursor 的对接机制或文档。
5. **多语言解析**：深度解析只有 Delphi（`AsWish.Delphi.PasParser.pas`、`AsWish.Delphi.DfmParser.pas`）；`.py/.ts/.js/.java/.c/.cpp/.vue/.xaml` 等仅做文件分类，不解析语义。非 Delphi 项目的四树主要由文档 + LLM 生成支撑。
6. **Revision**：有文件级快照/备份，无版本树、无自动状态演进、无 difference trace。

## 4. 完全缺失的能力

1. **Implementation Evidence（实现证据采集）**：`SpecStore` 只创建空的 `evidence/source-evidence.yaml`；scanner 不支持"实现后二次扫描并标注证据"。整个"AI 建完之后发生了什么"在工程上是盲区。
2. **Difference（差异检测）**：全库 grep `diff / difference / baseline / compare` 仅命中排序用 `TComparer`。这是产品核心研究问题（"Are we still building the same thing?"）的承载点，当前为 **0 代码**。
3. **实现后 Human Confirmation 通道**：依赖 1、2，不存在。
4. **Experiment / Case 形成机制**：没有任何把一次"问题→确认→实现→差异→判断"的过程导出为可分享 Case/实验记录的能力（协议与代码均无）。
5. **`agents/agent-results.yaml` 写入器**：协议有位、代码无实现。

## 5. 当前工程中可以直接复用的机制

| 复用点 | 位置 | 复用方式 |
|---|---|---|
| 决策体系 | `AsWish.Services.Decisions.pas` | 实现后确认直接复用 accept/reject/lock，不新建实体 |
| CandidateIngest | `AsWish.Services.CandidateIngest.pas` + CLI `ingest` | 自然语言修订入口（WO-0027A 方案）直接挂载 |
| 快照 | `AsWish.Services.Snapshot.pas` | Difference trace 以快照为基线来源 |
| Fog / grilling | `AsWish.Services.Prompts.pas` | PFM 显影入口复用追问机制 |
| Semantic Bundles | `bundles/semantic-bundles.yaml` | 跨投影影响定位复用，禁止新建 impact graph |
| Scan / TreeBuilder | `AsWish.Services.Scan.pas` / `TreeBuilder.pas` | 实现后二次扫描直接复用，产出对比输入 |
| 协议 `x_` 扩展位 | SPEC §10 | 差异/证据字段走扩展位，不动核心 schema |
| 冷启动 | `protocol/tools/init_workspace.py` + examples | 陌生用户/CI 初始化 |

## 6. Must have for First Experiment（第一次公开实验必须补）

1. **First Contact 修复**（详见 §10 冲突 1、2）：
   - 将 `docs/` 下 25 个 `DeepSpec-*` 前缀文件重命名为 `AsWish-*` 并对齐 `AsWish-当前文档索引-v1.md`（当前索引引用的 `AsWish-B事实模型与第一层所见即所得-v1.md` 等文件实际不存在，链接全断）。
   - `installer/AsWish.iss` 中 `MyAppPublisher "DeepKit"` 改为 AsWish 主体。
   - `WO/` 下工单仍写"工作仓库：`D:\_Progs\02Business\DeepSpec`"，需裁定：在制品 WO 是否迁移到本仓库执行（否则出现双仓分叉）。
   - README 增加"5 分钟第一次实验"快速上手段（现在 First Run 指向的说明文档存在但未包含一个端到端最小实验剧本）。
2. **自然语言修订入口（即 WO-0027A/0027B 链路落到本仓库）**：用户在节点上下文提交 `user_intent` → LLM 解释为 Change Set → 走 CandidateIngest。没有它，"人类只使用自然语言、不直接编辑 Spec"这条硬约束在第一次实验中就只能靠"手工写 YAML"违反原则来凑合。
3. **Accepted Visual Baseline（即 WO-0028 链路落到本仓库）**：决策通过后把审阅视图固化为带 provenance 的基线快照。复用现有 Decisions 与 Snapshot，不新建实体。
4. **Difference v0（最小可辩护版本）**：实现后二次 scan + 快照间树对比（新增/删除/修改/状态翻转节点），差异结果作为新候选走现有 Decisions 人工确认。v0 只做结构差异，不做视觉比对——但必须在报告里诚实标注这个边界，因为它恰是本产品的研究核心。
5. **Implementation Evidence v0**：二次扫描时把"实现后代码文件/符号"作为 source evidence 写入 `evidence/`，与差异项关联。复用现有 `WriteEvidenceFile` 占位接口。

> 2–5 项共同构成第一个可运行的闭环：`确认基线 → 导出 Prompt → Agent 实现 → 二次扫描 → 差异清单 → 人类确认`。

## 7. Needed for First Week（第一周真实使用必须补）

1. **非 Delphi 项目的诚实预期管理**：深度解析仅 Delphi。第一周用户大概率用 Python/TS/Go 项目，四树主要靠文档 + LLM。需要在文档中明确这个边界，并把 `protocol/examples/` 的种子工程变成可跟着做的实验剧本。
2. **Agent 对接一篇就够的指南**：Export Prompt 的产物如何喂给 Claude Code / Codex / Cursor，`ingest` 如何把 Agent 产出灌回（含 agent-results 的最小写入或手工约定）。现有 CLI 命令已够用，缺的是一条被验证过的路径文档。
3. **历史 evidence / difference trace 可查**：快照列表 + 差异结果持久化（复用 `Snapshot.ListSnapshots` + 差异落盘到 `evidence/` 或 `x_` 扩展），保证第二次使用时能回看第一次。
4. **LLM 配置的降级路径**：`Scan/Validate/Render/Decisions` 不需要 API Key（已满足），但 Generate/Change Set 解释需要。文档需写清"无 Key 时哪些步骤可用、哪些不可用"。
5. **实验记录导出（Case v0）**：把一次实验的项目名、时间、差异统计、人类判定导出为一份 markdown/JSON——这是增长飞轮 `Question → Experiment → Difference → Story → New Experiment` 的最低承载。

## 8. 可以明确推迟的能力（Later）

- 实现后**视觉**级比对（截图 diff、渲染像素对比）——WO-0028 明确不负责，且应先有结构差异数据。
- 多语言语义解析器（Python/TS AST 级）——先用文档驱动 + LLM 顶住。
- CLI 的 `generate`/`health` 增强、CI/CD 集成样板。
- 差异的原因归因（"difference entered where" 的自动定位）——先让人工确认差异，积累数据后再谈归因。
- agent-results.yaml 的完整 review signals 记录（assumptions/tradeoffs 全集）——先最小化记录。

## 9. 不应该现在做的能力（Do not build yet）

- 账号 / 团队协作 / SaaS 化 / 商业模式。
- 自建 Agent 编排器（SPEC §1 明确 "not an agent orchestrator"）。
- 任何平行 Candidate / Proposal / Decision / VisualState 新实体（WO-0028 架构纪律已明文禁止）。
- 把 Difference 预设为"必须消灭"的功能叙事；必须保留"无重要差异 / 可接受差异 / 不可接受差异"三种实验结果。
- 理论概念（DM / ASTO / ODD / CTF / PFM）的工程化重新定义。

## 10. 技术依赖与风险（含冲突裁定）

**冲突 1：文档索引与实际文件名断裂**
- 当前状态：`docs/AsWish-当前文档索引-v1.md` 引用 7+ 个 `AsWish-*` 文件名；实际 `docs/` 下 25 个文件仍是 `DeepSpec-*` 前缀，仅 3 个已改名。
- 战略要求：活跃工程面 DeepSpec 残留为 0；陌生用户 First Contact 干净。
- 冲突：文档索引宣称的入口不存在，首次点开即 404。
- 风险：First Contact 第一分钟崩塌；且索引声称"历史文档已标注失效口径"与事实不符（部分历史文件内仍用三棵树口径且未逐一标注）。
- **推荐裁定**：立即批量重命名 + 索引对齐（Must have #1）。

**冲突 2：在制品工单指向旧仓库**
- 当前状态：`WO/WO-20260830-0027A~D`、`WO-20260830-0028` 均写"工作仓库：`D:\_Progs\02Business\DeepSpec`"。
- 战略要求：本仓库是唯一工作目录。
- 冲突：P0 级核心链路工单（自然语言修订、Change Set、视觉基线）如果按字面执行，会落在旧仓库。
- 风险：架构分叉、双真相源，直接违反 SSOT 原则。
- **推荐裁定**：主控明确这批 WO 的承接仓库改判为本仓库（变更记录写入 WO 或新发修订版），在执行前由老板/主控裁定——此项需人确认。

**冲突 3：Difference 是核心主张但零实现**
- 当前状态：无任何差异检测代码。
- 战略要求：用户能看到/判断 Difference 是第一阶段第 4 优先目标。
- 冲突：README 与蓝图宣称的能力，代码里不存在；若现在发公开实验，用户走到主链第 7 步就断。
- 风险：首次公开实验会以"演示半截"告终，伤害可信度。
- **推荐裁定**：公开实验前必须落地 Difference v0（结构级），并诚实标注"视觉级比对未包含"。

**冲突 4：`agents/agent-results.yaml` 协议位存在但无写入器**
- 当前状态：SPEC §7 有完整要求，代码无实现。
- 风险：低（可用手工约定过渡），但公开协议与实现不一致会被第三方 conformance 审查发现。
- **推荐裁定**：第一周补最小写入器或先在 SPEC 标注"v1.2 中可选"。

**其他技术依赖/风险**
- WebView2 Runtime 是 GUI 审阅界面的硬依赖（安装器已做检测与官方下载引导，但离线/企业环境可能失败；CLI 路径不受影响）。
- 构建依赖 Delphi 13.1（`_build.bat` 硬编码 `BDS=d:\...\37.0`）——对陌生贡献者是门槛，但对"下载即用"用户无影响（exe 已提供）。
- LLM 依赖 OpenAI-compatible 端点 + API Key（仅 Generate/Change Set 需要；核心审阅链路无 Key 可用，已在设计上解耦）。
- 安装器尚未见构建产物（`bin/` 下无 `AsWish-Setup-*.exe`）；发布前需 `_build_installer.bat`（需 ISCC.exe）。

## 11. 建议实施顺序

```text
第 0 步（裁定，非编码）
  └─ 老板/主控裁定 WO-0027/0028 承接仓库改判为本仓库          ← 需人确认

第 1 步 · First Contact 修复（半天级）
  ├─ docs/ 25 个文件重命名 + 索引对齐
  ├─ installer Publisher / README 快速实验段
  └─ 跑一遍"下载 → 安装 → 首扫 → 审阅 → 决策 → 导出"全链验证并留证据

第 2 步 · 自然语言修订入口（WO-0027A/B 链路）
  └─ user_intent 附着 → Change Set 解释 → CandidateIngest

第 3 步 · Accepted Visual Baseline（WO-0028 链路）
  └─ 决策通过后基线快照落盘（复用 Snapshot + Decisions）

第 4 步 · Difference v0 + Implementation Evidence v0
  ├─ 二次扫描 → 快照间树对比 → 差异清单落盘
  ├─ 实现后证据写入 evidence/
  └─ 差异项走现有 Decisions 人类确认

第 5 步 · 第一周配套
  ├─ 非实验剧本（examples 改造）+ Agent 对接指南
  ├─ Case v0 导出
  └─ SPEC 标注 agent-results 实现状态

第 6 步 · 公开发布（构建安装器 → 首个公开实验征集）
```

每步完成后按非睿智轻量门禁留 build/test 证据。

## 12. 每项建议的代码 / 文件 / 协议依据（速查）

| 建议 | 依据 |
|---|---|
| 文档重命名 | `docs/` 实际清单（25×`DeepSpec-*`）vs `docs/AsWish-当前文档索引-v1.md` 引用名 |
| 安装器命名 | `installer/AsWish.iss` `#define MyAppPublisher "DeepKit"` |
| WO 仓库改判 | `WO/WO-20260830-0027A..D`、`WO-20260830-0028` 头部"工作仓库"字段 |
| 自然语言入口 | `WO/WO-20260830-0027A-甲-CandidateIngest自然语言修订入口工单.md`；挂载点 `src/services/AsWish.Services.CandidateIngest.pas`、`AsWish.Services.Prompts.pas` |
| 视觉基线 | `WO/WO-20260830-0028-甲-建立开发视觉规格基线工单.md`；挂载点 `src/services/AsWish.Services.Snapshot.pas`、`AsWish.Services.Render.pas` |
| Difference v0 | 缺失证据：全库无 diff/difference/compare 业务代码（仅 `TComparer` 排序）；复用点：`AsWish.Services.Scan.pas`、`Snapshot.pas`、`Decisions.pas`、SPEC §10 `x_` 扩展位 |
| Evidence v0 | 挂载点：`src/services/AsWish.Services.SpecStore.pas`（现有 `WriteEvidenceFile` 占位、空 `source-evidence.yaml`）；协议位：SPEC §2 `evidence/`、§5 Traceability |
| agent-results | SPEC §7 vs 代码 grep 无写入路径；协议位：`.AsWish/agents/agent-results.yaml` |
| 快速实验剧本 | `protocol/examples/seed-{docs-only,go-microservice,python-fastapi,react-web}`、`protocol/tools/init_workspace.py`、`docs/AsWish-用户上手说明-v1.md` |
| 测试扩展 | `tests/`（11 个 .pas，未覆盖 Scan/LLM/差异）；126/126 通过 |

---

## Recommended Next Engineering Step

**第一步：First Contact 修复包（半天级、零架构风险）**——
① `docs/` 25 个 `DeepSpec-*` 文件重命名为 `AsWish-*` 并对齐文档索引断链；② 修正安装器 `DeepKit` 发布者残留；③ README 增加"5 分钟第一次实验"剧本并实测"下载→运行→首扫→审阅→决策→导出"全链留证。

**同时请求一项裁定（非编码）**：`WO-20260830-0027A~D / 0028` 的承接仓库是否正式改判为本仓库（`D:\_Progs\02Business\AsWish`）执行。这是后续自然语言入口与视觉基线落地的前提，需老板确认后开工。
