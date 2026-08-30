# AsWish Strategic Closure Audit
# 战略与文档收口确认审计报告

> 审计日期：2026-08-30  
> 审计性质：**只读审计（零代码修改、零协议修改、零理论变更）**  
> 审计基准：`ASWISH-PRODUCT-IDENTITY.md` · `ASWISH-DOCUMENTATION-GOVERNANCE.md` · `SPEC.md` · `AGENTS.md` · `NOTICE`  
> 核心目标：裁定 AsWish 全仓“有效战略认知”是否已经达到直接指导后续工程开发的闭环状态。

---

## 1. Executive Verdict（审计裁定）

# **READY WITH CONDITIONS**

**裁定结论**：
全仓战略认知、产品层级、愿景定位、人机权责边界、核心追问、开源使命与理论确权体系**已完全收口并达成高度一致**。全仓已彻底清除旧 DeepSpec 时代的 Spec Tool / WYSIWYG Spec Editor 等降维认知，建立了以 `ASWISH-PRODUCT-IDENTITY.md` 与 `ASWISH-DOCUMENTATION-GOVERNANCE.md` 为核心的单一真相源（SSOT）体系。

当前阻隔直接开工的不是战略歧义或理念冲突，而是 **2 项前置管理裁定与 1 项工程范围约束**（详见 §8 与 §9），满足必要条件后即可无缝进入下一阶段工程实施（`GO WITH CONDITIONS`）。

---

## 2. Strategic Consistency（战略一致性核查）

对全仓 10 大战略维度的单向一致性检查结果如下：

| 战略维度 | 裁定基准口径 | 检查结论 | 评估说明 |
|---|---|---|---|
| **产品层级** | `Level 0 DM → Level 1 As We Wish → Level 2 As I Wish → Level 3 AsWish → .AsWish` | ✅ 完全一致 | 严禁将五层视为 4 个独立产品或简化为 Theory→Spec Tool→Code，全仓有效文档 100% 对齐该层级。 |
| **产品定位** | Human ↔ AI Coding Agent ↔ Software Implementation 之间的**开放工程层** | ✅ 完全一致 | 明确定位为规格控制与验证层，不是 Spec Editor、不是 IDE、不是 Coding Agent、不是 Orchestrator。 |
| **核心追问** | 1. *Are we still building the same thing?*<br>2. *Where did the difference enter?* | ✅ 完全一致 | 作为最高优先级研究问题贯穿 README、SPEC、PRODUCT-IDENTITY、AGENTS 等所有核心文件。 |
| **主链模型** | `显影 → 确认 → 建构 → 看见 → 生产 → 验证` (*Manifest → Confirm → Construct → See → Build → Verify*) | ✅ 完全一致 | 完整十步主链与六步对外压缩口径在产品蓝图、README、COPILOT 指令中完全统一。 |
| **人机边界** | **人类**：意向/判断/自然语言裁决/最终确认（**不直接编辑 Spec**）；<br>**AI**：发现/提问/生成/实现/提示差异（**无最终决策权**） | ✅ 完全一致 | 人机权责清晰，人类不直接写 YAML，AI 不越权锁定决策。 |
| **Difference** | 人类意向/共同理解/表示/Agent执行/实际实现间发生的变化；**Difference ≠ Error**；追求 *Difference made visible, traceable, and judgeable* | ✅ 完全一致 | 明确不追求 *Zero Difference*，允许人类裁决 Accept / Reject / Uncertain。 |
| **开源使命** | **Test my claim**（让第三方运行、复现、检验、质疑并反驳） | ✅ 完全一致 | 摒弃 "Try my tool" 营销宣传，确立“现实问题 → 真实实验 → 工程方法 → 理论”的传播顺序。 |
| **用户定位** | 第一圈：AI Coding 重度用户（Codex/Claude Code/Cursor/Gemini CLI 等）→ 第二圈：独立开发者/小团队 → 第三圈：研究者/PM | ✅ 完全一致 | 明确第一阶段不为企业市场提前引入 SSO/Team/SaaS 等复杂度。 |
| **第一阶段目标** | 追求真实使用证据与可证伪性（*First User → First Experiment → First Real Project → First Difference → First Case*） | ✅ 完全一致 | 坚决不以 GitHub Star、商业化营收或功能堆叠为第一阶段指标。 |
| **交付形态** | **Download → Run → Create Project → Start**（Windows Desktop / Local-first / 开源） | ✅ 完全一致 | 本地优先，无强制注册、无云端账号绑定、无 SaaS 依赖。 |

---

## 3. Document Consistency（文档一致性与分类核查）

### 3.1 一致项（Aligned Items）
1. **SSOT 结构**：`ASWISH-PRODUCT-IDENTITY.md`（身份）与 `ASWISH-DOCUMENTATION-GOVERNANCE.md`（治理）已被全仓有效文档（`README.md`、`AGENTS.md`、`SPEC.md`、`.github/copilot-instructions.md`、`protocol/README.md`、`docs/README.md`、`docs/AsWish-当前文档索引-v1.md` 等）作为唯一权威锚点显式引用。
2. **协议与工作区**：`SPEC.md`、`protocol/schemas/`、`protocol/invariants.md`、`protocol/state-machine.md` 统一将 `.AsWish/` 定义为事实载体，四投影固定为 `function`, `module`, `view`, `data`。
3. **连续执行纪律**：`AGENTS.md` 头部最高优先级“不停等”纪律与门禁要求保持强效，其他开发指导均服从该纪律。

### 3.2 冲突项（Conflicts Identified & Status）
1. **历史工单路径标注**：`WO/WO-20260830-0027A~D` 与 `WO-20260830-0028` 头部标注“工作仓库：`D:\_Progs\02Business\DeepSpec`”。
   * *状态*：属迁移前下发工单的历史遗留，正文机制完全适用于本仓库，待主控/老板在开工前统一定音改判（见 §8）。
2. **历史文件名与索引映射**：已在 `docs/AsWish-当前文档索引-v1.md` 中修正为实际物理文件名（`DeepSpec-*.md`），冲突已消除。

### 3.3 重复项（Duplicates & Convergence）
* 早期分散在多个设计稿中的愿景和哲学阐述已全部收敛至 `ASWISH-PRODUCT-IDENTITY.md`。
* 现有文档除唯一职责信息外，其余背景均通过 Markdown 链接指向权威文件，全仓无第二套平行理念文件。

### 3.4 过时项（Outdated Items Handled）
* 早期历史讨论中的“三棵树”（缺少 `data-tree`）与“WYSIWYG 开发文档优化器”口径，已全部隔离在 `docs/DeepSpec-*.md` 历史归档类（Class H）中，并在索引中显式注明其为“失效历史口径，不作为当前实现契约”。

---

## 4. Engineering Reality vs Strategic Claims（工程事实与战略契约对齐）

| 战略主张 (Strategic Claim) | 当前工程现状 (Engineering Reality) | 对齐状态 (Alignment) | 差距与工程要求 (Gap & Requirement) |
|---|---|---|---|
| **.AsWish 工作空间** | Delphi `SpecStore`、CLI 命令集、Python 初始化脚本及 Reader 完整支持 `.AsWish/` 目录与 YAML 事实。 | ✅ **完全对齐** | 协议骨架与读写机制已 100% 具备。 |
| **Desktop GUI 审阅** | `bin/AsWish.exe`（Delphi 13.1 VCL + WebView2）正常构建运行，JS Bridge 审阅决策双向打通。 | ✅ **完全对齐** | 桌面端交互审阅闭环已具备。 |
| **Headless CLI** | `cli/bin/AsWish.CLI.exe` 正常构建运行，支持 init/scan/validate/render/health/decisions/bundle/ingest。 | ✅ **完全对齐** | 自动化与命令行工具已具备。 |
| **Download & Run** | `installer/AsWish.iss` 打包脚本就绪，WebView2 检测与引导正常，Publisher 已对齐。 | ✅ **完全对齐** | 安装与离线运行支持具备。 |
| **自然语言修订入口** | 现有 `LLM.pas` 支持全局生成；尚无“在特定节点提交自然语言并附着 `user_intent`”的入口。 | ⚠️ **规划中 (P0)** | 对应 `WO-20260830-0027A`，工程挂载点在 `CandidateIngest.pas`。 |
| **Accepted Visual Baseline** | 现有 WebView2 支持实时 HTML 预览；尚无“人类确认后冻结为带 provenance 的基线快照”机制。 | ⚠️ **规划中 (P0)** | 对应 `WO-20260830-0028`，工程挂载点在 `Snapshot.pas` + `Render.pas`。 |
| **Agent 交付与结果写回** | `ExportPrompt` 输出 Context Pack；CLI `ingest` 支持候选合并；`agent-results.yaml` 协议有位但无自动写回器。 | ⚠️ **部分具备** | 手工 Prompt 导出可用；需补充一篇端到端 Agent 对接指南。 |
| **Implementation Evidence** | `SpecStore` 仅创建空的 `evidence/source-evidence.yaml`；无实现后二次采集代码。 | ❌ **结构性空白** | 下一阶段需实现 Evidence v0（二次扫描代码符号/截图关联）。 |
| **Difference 检测** | 全库仅有排序用 `TComparer`，无 spec-vs-implementation 差异对比代码。 | ❌ **结构性空白** | 下一阶段核心攻坚项：Difference v0（快照间结构差异对比）。 |
| **First Experiment 剧本** | `protocol/examples/` 有 4 个种子项目；尚缺一个 5 分钟端到端运行的引导式案例脚本。 | ⚠️ **待补齐** | 需在文档或 CLI 中固化 First Experiment 标准流程。 |

---

## 5. Theory Attribution Check（理论确权与归因合规核查）

严格依据 [`NOTICE`](NOTICE) 与 [`docs/理论确权清单-v1.md`](docs/理论确权清单-v1.md) 进行合规性审查：

1. **Difference Monism (DM, 差异一元论)**：
   * 理论性质：严格保持“存在条件论”，严禁写成“宇宙生成论”；
   * 学术 DOI：`10.5281/zenodo.19852505`；署名主体：付毅（Fu Yi）；
   * 结论：**合规（无理论主张增强）**。
2. **ASTO (属集变迁存在论)**：
   * 学术 DOI：`10.5281/zenodo.19856467`；署名主体：付毅（Fu Yi）；
   * 结论：**合规**。
3. **ODD (产出物驱动开发)**：
   * 学术 DOI：`10.5281/zenodo.20024964`；署名主体：付毅（Fu Yi）；
   * 结论：**合规**。
4. **CTF (建构追溯可谬规格方法论)**：
   * 形式限定：跨投影绑定场景必须使用完整限定词 **CTF Semantic Bundle**；
   * 主张强度：严格保持 **C2**（工程协议/分析框架），严禁升级为主张 C5；
   * 结论：**合规（未夸大主张）**。
5. **PFM (前线显影层)**：
   * 正式全称：**Problem Manifestation Methodology**；优先权 DOI：`10.5281/zenodo.19856528`；
   * 结论：**合规（术语无漂移）**。
6. **待确权与外部实践项**：
   * `fog_state`：显式标注为“待确权工程构造”，不强归因于一元论母板；
   * `invariants`：显式标注为“弱锚定 / 待确认”；
   * `Wayfinder / Grill-me`：显式标注为“外部实践启发”，严禁称为原创理论；
   * 结论：**合规（边界清晰）**。

---

## 6. SSOT Validation（单一真相源有效性验证）

全仓真相源架构已建立单向无环依赖：

```text
                     ┌──────────────────────────────┐
                     │ ASWISH-PRODUCT-IDENTITY.md   │ ◄── 最高产品身份权威
                     └──────────────┬───────────────┘
                                    │
                                    ▼
                     ┌──────────────────────────────┐
                     │ASWISH-DOCUMENTATION-GOVERNANC│ ◄── 最高治理与仲裁权威
                     └──────┬───────────────┬───────┘
                            │               │
            ┌───────────────┘               └───────────────┐
            ▼                                               ▼
┌──────────────────────────────┐                ┌──────────────────────────────┐
│ AGENTS.md / Copilot Instruct │                │ SPEC.md / protocol/README.md │
│ (最高工程纪律与行为规范)     │                │ (协议与工作空间规范)         │
└──────────────────────────────┘                └──────────────────────────────┘
```

* **循环引用排查**：零循环引用；所有下级文件单向依赖 `PRODUCT-IDENTITY` 与 `GOVERNANCE`。
* **重复定义排查**：零重复定义；通用术语、愿景口径一律通过链接索引。

---

## 7. Developer / AI Onboarding Validation（开发 AI 入场检验）

对“新接入开发 AI”的 10 项必备认知进行虚拟入场核验：

1. **知道 AsWish 是什么**？ $\rightarrow$ 是 Human ↔ Agent ↔ Software 之间的开放工程层与规格控制层。
2. **知道 AsWish 不是什么**？ $\rightarrow$ 不是 Spec Tool、不是 Spec Editor、不是 IDE、不是 Coding Agent、不是需求管理平台。
3. **知道产品五层层级**？ $\rightarrow$ Level 0 DM → Level 1 As We Wish → Level 2 As I Wish → Level 3 AsWish → .AsWish。
4. **知道人机权责边界**？ $\rightarrow$ 人类自然语言裁决（不直接写 Spec）；AI 发现生成（无最终决策权）。
5. **知道第一阶段战略**？ $\rightarrow$ 验证可证伪性与真实实验（*Test my claim*），不搞商业化与功能堆砌。
6. **知道当前工程成熟度**？ $\rightarrow$ L1 可用基本达成，L2 可验证（Difference v0 / Evidence v0）是当前攻坚目标。
7. **知道当前哪些能力已具备**？ $\rightarrow$ 四投影扫描、YAML 存储、HTML WebView2 审阅、JS Bridge 决策写回、快照、CLI 工具链。
8. **知道哪些能力仍缺失**？ $\rightarrow$ 自然语言修改入口（0027A）、视觉基线（0028）、实现证据采集、Difference 对比。
9. **知道禁止擅自增加什么**？ $\rightarrow$ 严禁增加 SaaS、账号、团队权限、并行 Candidate/Decision 实体、复杂 AST。
10. **知道理论归因红线**？ $\rightarrow$ CTF 保持 C2 / CTF Semantic Bundle，不夸大理论，外部启发不标原创。

**检验结论**：**通过。任何新 AI 严格按 Onboarding 顺序阅读后，均具备精准执行开发工单的完整认知。**

---

## 8. Remaining Strategic Decisions（待裁定事项）

当前仅剩 **1 项管理裁定**，无战略层重大歧义：

* **裁定项：在制品工单承接仓库正式改判**
  * **事实**：`WO/WO-20260830-0027A~D` 与 `WO-20260830-0028` 头部写有“工作仓库：`D:\_Progs\02Business\DeepSpec`”。
  * **裁定建议**：由主控/老板正式批准将这批工单的执行目标改判为本仓库（`D:\_Progs\02Business\AsWish`），开发 AI 接单时在此仓库直接开工，避免产生双仓分叉。

---

## 9. Recommended Engineering Gate（工程实施门禁裁定）

# **GO WITH CONDITIONS**

### 准入必要条件（3 项）：
1. **[管理前置]** 主控确认 `WO-20260830-0027A~D` 与 `WO-20260830-0028` 承接仓库改判为本仓库 `D:\_Progs\02Business\AsWish`；
2. **[范围约束]** 严格遵循“单 Commit ≤ 200 行，build/test 原始输出留存证据”的非睿智轻量门禁纪律；
3. **[架构收敛]** 坚决禁止新建 Proposal / Parallel Decision 等平行实体，全部复用现有 `CandidateIngest.pas`、`Decisions.pas` 与 `Snapshot.pas`。

---

## 10. Recommended Next Step（推荐下一项工程动作）

不要一次性并发分发全部工单，建议按严格依赖链路**单票串行推进**：

```text
下一项唯一步骤：
执行 WO-20260830-0027A（甲 · CandidateIngest 自然语言 Spec 修订入口）
```

* **目标**：在 `AsWish.Services.CandidateIngest.pas` 与 `AsWish.Services.Prompts.pas` 中打通 `user_intent` 原文附着与上下文携带；
* **预期产出**：人类可通过自然语言提交候选修改意向，保持“人类不直接编辑 Spec”的核心产品战略。
