# AsWish Documentation Governance

> 当前文档治理权威说明（Single Source of Truth for Documentation Governance）。
> 任何 AI 或开发者接手 AsWish 工程，必须先读 [ASWISH-PRODUCT-IDENTITY.md](ASWISH-PRODUCT-IDENTITY.md)，再读本文。
> 本文件由主控与老板裁定维护；其他文件描述文档职责与治理规则时必须与本文一致，冲突时以本文为准。

---

## 1. 权威文件注册表（Single Source of Truth 矩阵）

全仓遵循**单一真相源（SSOT）**原则：每个核心领域的权威定义只能存在于一个指定文件中，其他文件只做索引与指向，严禁在多个文件中自由复述或各自定义。

| 领域 / 职责 | 权威文件 | 权威说明 | 变更裁定者 |
|---|---|---|---|
| **产品身份 / 愿景 / 层级** | [`ASWISH-PRODUCT-IDENTITY.md`](ASWISH-PRODUCT-IDENTITY.md) | 产品层级、核心研究问题、主链、人机边界、Difference、愿景、第一阶段目标与开源使命的唯一定义源 | 老板 / 架构师 |
| **文档治理与全仓规范** | [`ASWISH-DOCUMENTATION-GOVERNANCE.md`](ASWISH-DOCUMENTATION-GOVERNANCE.md) | 权威注册表、文档分类、冲突裁定原则、术语纪律与引用规则的唯一治理源 | 主控 |
| **工程开发与执行纪律** | [`AGENTS.md`](AGENTS.md) + [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | 连续执行纪律（最高优先级）、行为规范、编码军规、质量门禁与 Agent 指令 | 主控 |
| **理论归因与法定确权** | [`NOTICE`](NOTICE) + [`docs/理论确权清单-v1.md`](docs/理论确权清单-v1.md) | 理论法源、DOI 永久档案、主张强度（如 CTF C2）、待确权项（fog_state）与署名规范 | 理论持有者（付毅） |
| **协议与工作空间规范** | [`SPEC.md`](SPEC.md) + [`protocol/`](protocol/) | `.AsWish/` 工作空间规范、JSON Schemas、状态机、不变量（`invariants.md`）、读者契约与协议治理（`protocol/GOVERNANCE.md`） | 协议维护组 |
| **产品功能蓝图** | [`docs/AsWish-产品功能与愿景蓝图-v1.md`](docs/AsWish-产品功能与愿景蓝图-v1.md) | 产品功能架构、七环闭环、所见即所得工程原则与 SVG / Visual Checkpoint Matrix；身份问题以 PRODUCT-IDENTITY 为准 | 产品负责人 |
| **工程路线与 Dogfood 验收** | [`docs/AsWish-工程路线与Dogfood验收-v1.md`](docs/AsWish-工程路线与Dogfood验收-v1.md) | 工程阶段（First Contact → First Closed Loop）、工单依赖顺序、双闸门（Engineering Green / Dogfood Green）验收、Dogfood 任务原则与待裁定冲突登记；各票原始需求与 AC 仍以 `WO/` 工单原文为准 | 主控 |
| **统一选择交互标准** | [`docs/AsWish-统一选择交互标准-v1.md`](docs/AsWish-统一选择交互标准-v1.md) | 0–9 Universal Choice 交互协议（1–7 候选 / 8 重新生成 / 9 自然语言 / 0 返回）、语义色 Token 与 Decision Semantics 分层；**已冻结，不再反复讨论**；为双界面规范的子文档 | 产品负责人 |
| **可见判断规范（OJP）** | [`docs/AsWish-可见判断规范-OJP-v1.md`](docs/AsWish-可见判断规范-OJP-v1.md) | 可见判断原则：Artifact / Observable / Judgment 边界、VC-01～06、Difference 四层比较与插件系统、OJP Acceptance；与双界面规范正交 | 产品负责人 |
| **双界面交互规范** | [`docs/AsWish-双界面交互规范-DualSurface-v1.md`](docs/AsWish-双界面交互规范-DualSurface-v1.md) | 双界面（Conversation 探索 / Decision 判断）切分、0–9 的父框架、Canonical Boundary；0–9 语义以子规范为准 | 产品负责人 |
| **CTF 工程方法** | [`docs/CTF.md`](docs/CTF.md) | CTF 方法在 AsWish 中的工程实现解释；理论主张强度以 NOTICE / 确权清单为准 | 架构师 |
| **用户操作与快速上手** | [`docs/AsWish-用户上手说明-v1.md`](docs/AsWish-用户上手说明-v1.md) | 桌面端首次运行、四投影审阅、LLM 配置与 CLI 运行路径 | 开发组 |
| **文档全景索引** | [`docs/AsWish-当前文档索引-v1.md`](docs/AsWish-当前文档索引-v1.md) | 全仓中文文档的导航定位与历史文档状态标识 | 文档维护者 |
| **对外项目总览** | [`README.md`](README.md) | 对外项目定位、快速开始、工程构建与对外传播首入口 | 维护团队 |
| **历史归档记录** | `docs/DeepSpec-*.md`（32 篇）、`WO/`（历史工单）、`ASWISH-MIGRATION-REPORT.md`、`MIGRATION-PLAN.md`、`migration-inventory.md`、`.workbuddy/`、`.claude/` | 历史事实只读存档；**不作为当前有效契约** | 只读（禁止篡改历史事实） |

---

## 2. 全仓文档分类体系

全仓所有文档严格归入以下 6 类：

### Class A：产品定位类（Product Positioning）
- **核心文件**：[`ASWISH-PRODUCT-IDENTITY.md`](ASWISH-PRODUCT-IDENTITY.md)、[`README.md`](README.md)、[`docs/AsWish-产品功能与愿景蓝图-v1.md`](docs/AsWish-产品功能与愿景蓝图-v1.md)
- **职责**：定义 AsWish 是什么、不是什么、解决什么核心问题、产品层级、工作流主链与开源愿景。
- **维护原则**：必须与 `ASWISH-PRODUCT-IDENTITY.md` 严格保持单向同步。

### Class B：开发指导类（Development Guidance）
- **核心文件**：[`AGENTS.md`](AGENTS.md)、[`.github/copilot-instructions.md`](.github/copilot-instructions.md)、[`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md)、[`docs/delphi程序开发约定指南.md`](docs/delphi程序开发约定指南.md)
- **职责**：指导人类开发者和 AI Coding Agent 开展开发，规定连续执行纪律、编码约束、测试门禁与 PR 验收标准。
- **维护原则**：强调可执行与可验证性，不得包含模糊或自相矛盾的规则。

### Class C：工程架构与协议类（Engineering Architecture & Protocol）
- **核心文件**：[`SPEC.md`](SPEC.md)、[`protocol/README.md`](protocol/README.md)、[`protocol/GOVERNANCE.md`](protocol/GOVERNANCE.md)、[`protocol/invariants.md`](protocol/invariants.md)、[`protocol/state-machine.md`](protocol/state-machine.md)、[`protocol/controlled-vocab.md`](protocol/controlled-vocab.md)、[`protocol/docs/*`](protocol/docs/)、[`protocol/schemas/*`](protocol/schemas/)
- **职责**：定义 `.AsWish/` 目录结构、YAML 字段规范、四投影树格式、Semantic Bundle、状态变迁、不变量约束与 Reader Profile。
- **维护原则**：保持语言无关性与向下兼容性；遵循 `protocol/GOVERNANCE.md` 的变更程序。

### Class D：理念与方法类（Philosophy & Methodology）
- **核心文件**：[`docs/CTF.md`](docs/CTF.md)、[`docs/理论确权清单-v1.md`](docs/理论确权清单-v1.md)、[`NOTICE`](NOTICE)、[`protocol/NOTICE`](protocol/NOTICE)
- **职责**：阐释 Difference Monism (DM)、ASTO、ODD、CTF、PFM 等理论在工程中的映射，记录学术 DOI、主张强度与法定归属。
- **维护原则**：严格遵守理论确权纪律，不扩大主张强度，不把外部实践（Wayfinder / Grill-me）标为原创。

### Class E：发布与开源治理类（Release & Open Source）
- **核心文件**：[`LICENSE`](LICENSE)、[`NOTICE`](NOTICE)、[`protocol/LICENSE`](protocol/LICENSE)、[`protocol/NOTICE`](protocol/NOTICE)、[`installer/AsWish.iss`](installer/AsWish.iss)、[`.github/SECURITY.md`](.github/SECURITY.md)
- **职责**：开源许可证条款、第三方依赖说明、安装包打包元数据与安全报告通道。
- **维护原则**：确保版权、署名和许可证文本的法定合规。

### Class H：历史归档类（Historical & Read-only Records）
- **核心文件**：`docs/DeepSpec-*.md`（32 篇历史讨论稿）、`WO/`（历史工单与验收审计）、`ASWISH-MIGRATION-REPORT.md`、`MIGRATION-PLAN.md`、`migration-inventory.md`、`.workbuddy/`、`.claude/`
- **职责**：记录项目演进过程、迁移审计、历史会议纪要与阶段性研究手稿。
- **维护原则**：**只读保留、原名原貌、禁止篡改**。历史文档内的失效口径（如“三棵树”）作为历史事实保留，不作为当前实现依据。

---

## 3. 单一真相源与引用纪律

1. **唯一信息 + 指向链接**：文档中只保留该文档职责范围内的**唯一信息**，其余背景、协议、理论或规则一律使用 Markdown 链接指向权威文件。
2. **禁止信息复制与复述**：严禁把代码逻辑、数据结构或产品定义用大段文字复制到多个文档中，防止未来修改时产生“文档分叉”和“认知漂移”。
3. **禁止新建平行理念文件**：严禁任何 AI 或开发者自行创建新的“愿景蓝图”“产品定位”“战略纲领”等平行文件。所有产品理念调整必须汇聚到 `ASWISH-PRODUCT-IDENTITY.md`。
4. **Stateless Deliverable（无状态交付）**：交付文档时保持产物直接可用，不包含过程性补丁说明或临时对话痕迹。

---

## 4. 冲突裁定顺序与仲裁协议

当不同文档之间出现表述不一致时，严格按以下仲裁优先级处理：

```text
[产品身份 / 愿景冲突]  →  以 ASWISH-PRODUCT-IDENTITY.md 为准（老板裁定维护）
[工程纪律 / 门禁冲突]  →  以 AGENTS.md 为准（连续执行纪律最高优先级）
[协议 / 工作空间冲突]  →  以 SPEC.md + protocol/ 为准
[理论归因 / DOI冲突]   →  以 NOTICE + docs/理论确权清单-v1.md 为准
[历史文档与当前冲突]  →  当前基线以权威文件为准；历史文档只读保留，不作为契约
```

### 理论母库冲突升级机制
若本仓库中关于 Difference Monism、ASTO、ODD、PFM 等理论的描述与理论母库（`D:\_Progs\一元论\`）存在冲突：
- **禁止 AI 或开发者自行裁定修改理论内容**；
- 必须在报告中标记冲突点并明确上报老板；
- 严格依据理论母库现有正式发表文献统一。

---

## 5. 术语与理论主张纪律（全仓速查）

全仓所有当前有效文档必须严格遵守以下术语纪律：

1. **正式产品五层层级**（严禁省略或写成四独立产品）：
   ```text
   Level 0: Difference Monism (差异一元论 · 理论母体)
           ↓
   Level 1: As We Wish (理论/方法层 · 人机共同述事与建构机制)
           ↓
   Level 2: As I Wish (产品概念 · “最终得到的是否仍是我真正想要的”)
           ↓
   Level 3: AsWish (工程实现 / 开源仓库)
           ↓
   Project Workspace: .AsWish (项目工作空间 / 协议载体)
   ```
2. **核心研究问题**（贯穿一切工程与研究）：
   * **Are we still building the same thing?**
   * **Where did the difference enter?**
3. **主链压缩口径**：
   $$\text{显影} \longrightarrow \text{确认} \longrightarrow \text{建构} \longrightarrow \text{看见} \longrightarrow \text{生产} \longrightarrow \text{验证}$$
   *(Manifest → Confirm → Construct → See → Build → Verify)*
4. **全仓严禁的降维表述**：
   * 严禁把 AsWish 称为 Spec Tool / Spec Editor / WYSIWYG Spec Editor / AI Requirement Tool / AI Coding Tool / 帮助 AI 写代码的普通需求管理工具。
5. **所见即所得（WYSIWYG）的正式定义**：
   * 开发前人机确认的视觉基线与开发后实际软件产出的实现证据之间，可进行可验证的对比与差异检查。人类使用自然语言表达，不直接手动编辑 Spec。
6. **Difference 的性质**：
   * Difference 是在人类意向/共同理解/表示/Agent执行/实际实现间发生的值得被看见与判断的变化。
   * **Difference ≠ Error**；追求 Difference made visible, traceable, and judgeable，不追求 Zero Difference。
7. **开源传播顺序**：
   $$\text{现实问题} \longrightarrow \text{真实实验} \longrightarrow \text{工程方法} \longrightarrow \text{理论}$$
   开源核心口径为 **Test my claim**，而非 "Try my tool"。
8. **第一阶段用户与目标**：
   * 优先聚焦 AI Coding 重度用户（Codex/Claude Code/Cursor/Gemini CLI 等）；
   * 坚持 **Download → Run → Create Project → Start**（本地优先、下载即用，不强制注册/SaaS/SSO）；
   * 核心指标是完成真实实验人数、真实项目数与 Difference 案例（而非 GitHub Stars）。
9. **理论归因与主张强度限定**：
   * **CTF** 必须使用完整限定词 **CTF Semantic Bundle**，主张强度严格保持 **C2**；
   * **fog_state** 显式标注为“待确权工程构造”；
   * **invariants** 显式标注为“弱锚定 / 待确认”；
   * **Wayfinder / Grill-me** 显式标注为“外部实践启发，不声称为原创理论”。

---

## 6. 新 AI / 开发者入场第一阅读顺序（Onboarding Reading Path）

任何新加入本项目的 AI Agent 或人类开发者，必须严格按以下顺序阅读：

```text
Step 1: 阅读 ASWISH-PRODUCT-IDENTITY.md        （建立产品认知基准，消除 Spec Tool 误区）
Step 2: 阅读 ASWISH-DOCUMENTATION-GOVERNANCE.md（掌握文档治理、权威映射与冲突规则）
Step 3: 阅读 AGENTS.md                         （掌握连续执行纪律、开发与测试门禁）
Step 4: 阅读 SPEC.md 与 protocol/README.md     （掌握 .AsWish/ 协议规范与工作空间结构）
Step 5: 阅读 docs/AsWish-用户上手说明-v1.md    （了解用户操作路径与桌面端/CLI 运行方式）
```

---

## 7. 文档生命周期与更新流程

1. **修改产品身份 / 愿景**：直接修改 `ASWISH-PRODUCT-IDENTITY.md`（须经老板裁定），其余文件只更新链接引用。
2. **新增有效文档**：必须在 `docs/AsWish-当前文档索引-v1.md` 登记一行，并在本文件 §1 注册表中声明其权威职责（若有）。
3. **废弃旧文档**：不得物理删除具有历史审计价值的文件；将文件移入历史索引并标注失效口径。
4. **历史文件引用**：引用历史文件时必须使用其真实文件名（如 `DeepSpec-*.md`），不得脑补伪造 `AsWish-*.md`。
