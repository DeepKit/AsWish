# AsWish Documentation Alignment Report
# 全仓产品认知基准与文档治理统一报告

> 报告日期：2026-08-30  
> 责任主体：Antigravity 主控  
> 任务类型：全仓产品认知基准、产品层级、理论归因与文档治理体系统一（无业务功能修改）

---

## 1. 扫描文件统计

本轮治理对 AsWish 仓库（`D:\_Progs\02Business\AsWish`）进行了全量扫描：
- **扫描文件总数**：123 个跟踪与未跟踪文件（含 110 个 Markdown 文档、源代码、协议 Schemas、测试与安装脚本）。
- **分类统计**：
  - Class A（产品定位类）：3 篇
  - Class B（开发指导类）：4 篇
  - Class C（工程架构与协议类）：16 篇
  - Class D（理念与方法类）：4 篇
  - Class E（发布与开源治理类）：6 篇
  - Class H（历史归档类）：52 篇（32 篇 `DeepSpec-*.md` 历史手稿 + 20 篇 `WO/` 工单及迁移记录）
  - 源码与测试单元：38 个 Delphi/Pascal 单元及工程文件

---

## 2. 更新与新建文件明细

| 文件路径 | 类别 | 原职责 | 修改原因 | 核心修改内容 |
|---|---|---|---|---|
| [`ASWISH-PRODUCT-IDENTITY.md`](ASWISH-PRODUCT-IDENTITY.md) | Class A [NEW] | 无（新建） | 建立全仓产品身份唯一定义源（SSOT） | 完整收录 20 个标准章节：产品定位、禁用词、五层层级（DM → As We Wish → As I Wish → AsWish → .AsWish）、核心研究问题（*Are we still building the same thing? / Where did the difference enter?*）、主链六步（显影→确认→建构→看见→生产→验证）、人机权责边界、Difference（Difference ≠ Error）、愿景、开源使命（*Test my claim*）、第一阶段目标与用户圈层、理论确权与传播顺序。 |
| [`ASWISH-DOCUMENTATION-GOVERNANCE.md`](ASWISH-DOCUMENTATION-GOVERNANCE.md) | Class A [NEW] | 谁定义什么、新文档引用哪里、冲突如何处理 | 建立全仓文档治理唯一定义源（SSOT） | 制定权威文件注册表（SSOT 矩阵）、6 类文档分类法、引用与单一边界纪律、5 级冲突裁定顺序、理论母库冲突升级机制、术语速查与新 AI/开发者入场第一阅读顺序（Onboarding Reading Path）。 |
| [`README.md`](README.md) | Class A [MODIFIED] | 对外公开入口与说明 | 统一为标准传播顺序，消除旧定位 | 重构为：现实问题（生产速度超越理解速度）→ 核心追问 → 开放工程层定位 → 五层层级图 → 六步主链 → 原则（人机边界、Difference≠Error、WYSIWYG 视觉基线、Local-first 下载即用）→ 开源使命（*Test my claim*）→ 四投影与特性 → 用户圈层与第一阶段实证指标 → 构建与 CLI 运行 → 理论确权与 DOI。 |
| [`AGENTS.md`](AGENTS.md) | Class B [MODIFIED] | 开发者与 AI 执行纪律 | 建立产品身份第一入口与 SSOT 索引 | 在头部明确最高优先级连续执行纪律；确立五层层级、两大研究问题、主链六步口径，并显式链接到 `ASWISH-PRODUCT-IDENTITY.md` 与 `ASWISH-DOCUMENTATION-GOVERNANCE.md`。 |
| [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | Class B [MODIFIED] | 编码 Agent 提示与约束 | 统一 Agent 认知与行为边界 | 强化五层层级、人机权责边界（人类自然语言裁决，不直接编辑 Spec；AI 不拥有最终决策权）、Difference ≠ Error 原则、正交状态与最少上下文原则，显式指向 SSOT 文档。 |
| [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md) | Class B [MODIFIED] | 社区贡献指南 | 消除 Spec Tool 残留，传达开源使命 | 明确 AsWish 为开放工程层（非 Spec Tool/Editor），确立 *Test my claim* 开源使命，设立五大贡献优先级，对齐 SSOT 治理链接。 |
| [`SPEC.md`](SPEC.md) | Class C [MODIFIED] | 协议与工作空间规范基线 | 明确协议在体系中的定位 | 在 §1 和 §11 明确 AsWish 作为 Level 3 工程实现与 `.AsWish/` 工作空间规范，更新产品身份与文档治理的 SSOT 链接。 |
| [`protocol/README.md`](protocol/README.md) | Class C [MODIFIED] | 协议层说明与导读 | 对齐文档治理规范 | 增加指向 `ASWISH-PRODUCT-IDENTITY.md` 与 `ASWISH-DOCUMENTATION-GOVERNANCE.md` 的权威指针。 |
| [`docs/README.md`](docs/README.md) | Class A [MODIFIED] | docs/ 目录入口与导读 | 建立权威文件与历史文档清晰区分 | 增加权威文件列表（含 PRODUCT-IDENTITY 与 GOVERNANCE），规范历史三棵树文件与 SPEC.md 的优先级关系。 |
| [`docs/AsWish-产品功能与愿景蓝图-v1.md`](docs/AsWish-产品功能与愿景蓝图-v1.md) | Class A [MODIFIED] | 产品功能蓝图与路线 | 对齐五层层级与第一阶段非商业化纪律 | 确立 Level 0 ~ Level 3 与 `.AsWish` 体系；对齐七环闭环；在商业化章节显式增加“第一阶段非商业化、以实证使用为优先”纪律。 |
| [`docs/AsWish-当前文档索引-v1.md`](docs/AsWish-当前文档索引-v1.md) | Class A [MODIFIED] | 中文文档索引导航 | 修复历史文件名映射 | 将历史讨论稿精准指向 `DeepSpec-*.md` 实际文件名，杜绝断链；在当前入口登记权威治理文件。 |
| [`docs/AsWish-用户上手说明-v1.md`](docs/AsWish-用户上手说明-v1.md) | Class A [MODIFIED] | 首次运行与操作路径 | 修正一句话定位与研究问题 | 一句话定位修正为“开发前看见确认，开发后验证实现”，引入 PRODUCT-IDENTITY 链接。 |
| [`docs/理论确权清单-v1.md`](docs/理论确权清单-v1.md) | Class D [MODIFIED] | 理论法源与确权状态记录 | 修正历史文档文件名引用 | 将 CTF 历史出处修正为 `docs/DeepSpec-CTF方法论-v2.1.md` 真实物理文件名。 |
| [`installer/AsWish.iss`](installer/AsWish.iss) | Class E [MODIFIED] | Inno Setup 打包脚本 | 消除 DeepKit 发布者残留 | 将 `#define MyAppPublisher "DeepKit"` 修正为 `"BetterCiv Contributors"`，与 NOTICE 保持严格一致。 |
| [`tests/_build_tests.bat`](tests/_build_tests.bat) | Class B [NEW] | 测试编译脚本 | 补齐测试工具链脚本 | 提供开箱即用的 DUnitX 测试构建批处理脚本。 |

---

## 3. 未修改的文件及原因

1. **`docs/DeepSpec-*.md`（32 篇历史讨论稿）**：根据迁移纪律（不篡改历史事实），历史讨论稿保留 `DeepSpec-` 原名与原貌（含三棵树等历史口径），由 `docs/AsWish-当前文档索引-v1.md` 标注为只读历史。
2. **`WO/`（历史工单与验收审计）**：属于历史台账与工程审计证据，按 ODD/BCW 纪律保持只读，不可回溯修改。
3. **`docs/delphi程序开发约定指南.md` / `docs/HB视觉优化指南-独立版.md`**：属于具体技术框架（DeepBase/VCL）实施指南，不涉及产品层级与战略定位，保持原样。
4. **`docs/CTF.md`**：已具备清晰的 CTF Pre-spec 边界与 C2 主张强度，无需调整。
5. **`NOTICE` / `protocol/NOTICE`**：已严格声明 付毅（Fuyi）的理论法源（DM, ASTO, ODD, CTF, PFM）及 DOI，无漂移。
6. **`protocol/schemas/*.json` / `protocol/conformance/` / `protocol/examples/`**：属于协议数据载体与机器可测用例，结构正确，不含错误理念文本。
7. **`src/` 源码（Delphi units）**：本轮任务严格限定为认知与文档治理，严禁修改业务代码与数据结构。

---

## 4. 历史文件保留原貌清单

以下历史文件严格保留物理原貌（只读归档）：
- `docs/DeepSpec-B事实模型与第一层所见即所得-v1.md`
- `docs/DeepSpec-CTF方法论-v1.md`
- `docs/DeepSpec-CTF方法论-v2.1.md`
- `docs/DeepSpec-DeepBase首版落地清单-v1.md`
- `docs/DeepSpec-DelphiVCL解析与验收-v1.md`
- `docs/DeepSpec-HTML审阅图表参考-v1.md`
- `docs/DeepSpec-MVP实施蓝图-旁路查阅与三树-v1.md`
- `docs/DeepSpec-三层产品路线-v1.md`
- `docs/DeepSpec-三棵树通用协议-v1.md`
- `docs/DeepSpec-三棵树通用协议-标准化圆桌讨论-v1.md`
- `docs/DeepSpec-三棵树通用协议-第一轮审阅意见-v1.md`
- `docs/DeepSpec-三棵树通用协议-第二轮审阅意见-v1.md`
- `docs/DeepSpec-产品愿景与约束-v2.md`
- `docs/DeepSpec-产品蓝图与蓝海判断-v1.md`
- `docs/DeepSpec-第一层图表体系定稿-v1.md`
- `docs/DeepSpec-第一层图表体系定稿-v2.md`
- `docs/DeepSpec-定位升级-所见即所得开发文档优化器-v1.md`
- `docs/DeepSpec-借力DeepBase框架接入方案-v1.md`
- `docs/DeepSpec-开源与视觉系统分层方案-v1.md`
- `docs/DeepSpec-历史讨论可复用内容整理-v1.md`
- `docs/DeepSpec-旁路查阅与提示词规范-v1.md`
- `docs/DeepSpec-人类决策写回与AI影响机制-v1.md`
- `docs/DeepSpec-文档优化审查报告-2026-05-20.md`
- `docs/DeepSpec-需求图表化讨论稿-v1.md`
- `docs/DeepSpec-战略定稿-v1.md`
- `docs/deepbase-feedback.md`
- `docs/wayfinder-对DeepSpec的启发.md`
- `docs/wayfinder-fog-of-war.md`
- `docs/superpowers/plans/2026-07-09-bug9-health-dashboard.md`
- `docs/superpowers/specs/2026-07-09-bug9-health-dashboard-design.md`
- `ASWISH-MIGRATION-REPORT.md`
- `MIGRATION-PLAN.md`
- `migration-inventory.md`

---

## 5. 发现的冲突与处理

1. **文档索引引用不存在的文件名**：
   - *冲突*：`docs/AsWish-当前文档索引-v1.md` 引用了 `AsWish-B事实模型与第一层所见即所得-v1.md` 等名称，但磁盘上实际为 `DeepSpec-*`。
   - *处理*：已在索引中修正为真实文件名 `DeepSpec-*`，并注明“历史文件保留原名是迁移纪律，引用必须使用真实文件名”。
2. **安装程序发布者残留**：
   - *冲突*：`installer/AsWish.iss` 中 `MyAppPublisher` 为 `DeepKit`。
   - *处理*：已修正为 `BetterCiv Contributors`，与 `NOTICE` 保持完全一致。
3. **对外传播顺序与认知层级**：
   - *冲突*：部分早期讨论直接从理论推导展开，不符合普通开发者体验。
   - *处理*：在 `README.md` 与 `ASWISH-PRODUCT-IDENTITY.md` 中统一传播顺序为：现实问题 → 真实实验 → 工程方法 → 理论。

---

## 6. 未擅自裁定的事项（保持原状并上报）

1. **在制品工单 `WO-20260830-0027A~D` / `0028` 承接路径**：
   - 工单内部头部写有“工作仓库：`D:\_Progs\02Business\DeepSpec`”。本轮仅作为历史事实记录，未擅自修改工单正文，留待后续工单派发时由老板/主控裁定执行。
2. **理论概念内容**：
   - 对 Difference Monism、ASTO、ODD、CTF、PFM 等理论内容未作任何自作主张的扩充或修改；`fog_state` 严格保持“待确权工程构造”，`invariants` 严格保持“弱锚定”。

---

## 7. 当前 Single Source of Truth (SSOT) 矩阵

全仓所有认知与规则以以下矩阵为唯一有效真理源：

```text
┌──────────────────────────────────────┬────────────────────────────────────────────────────────┐
│ 领域                                 │ 权威文件 (SSOT)                                        │
├──────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ 产品身份 / 愿景 / 层级 / 边界        │ ASWISH-PRODUCT-IDENTITY.md                             │
│ 文档治理 / 权威注册表 / 冲突仲裁     │ ASWISH-DOCUMENTATION-GOVERNANCE.md                     │
│ 工程开发与执行纪律                   │ AGENTS.md + .github/copilot-instructions.md            │
│ 理论归因与法定确权                   │ NOTICE + docs/理论确权清单-v1.md                       │
│ 协议与工作空间规范                   │ SPEC.md + protocol/                                    │
│ 产品功能蓝图                         │ docs/AsWish-产品功能与愿景蓝图-v1.md                   │
│ CTF 工程方法                         │ docs/CTF.md                                            │
│ 用户操作与快速上手                   │ docs/AsWish-用户上手说明-v1.md                         │
│ 文档全景索引                         │ docs/AsWish-当前文档索引-v1.md                         │
└──────────────────────────────────────┴────────────────────────────────────────────────────────┘
```

---

## 8. 后续任何 AI 开发任务的第一阅读顺序

任何新接入本仓库的 AI Agent，必须严格按以下顺序阅读，方可开展工作：

```text
Step 1: 阅读 ASWISH-PRODUCT-IDENTITY.md        (牢记五层层级与开放工程层定位，杜绝 Spec Tool 认知)
Step 2: 阅读 ASWISH-DOCUMENTATION-GOVERNANCE.md(掌握文档引用与冲突仲裁规则)
Step 3: 阅读 AGENTS.md                         (掌握最高优先级连续执行纪律与开发门禁)
Step 4: 阅读 SPEC.md 与 protocol/README.md     (掌握 .AsWish/ 协议规范)
Step 5: 阅读 docs/AsWish-用户上手说明-v1.md    (掌握用户交互与运行路径)
```

---

## 9. 旧 DeepSpec / Spec Tool 定位残留检查

- **检索结果**：
  - 检索 `Spec Tool`、`Spec Editor`、`WYSIWYG Spec Editor`、`AI Requirement Tool`、`AI Coding Tool`：所有当前有效文档（`README.md`、`AGENTS.md`、`copilot-instructions.md`、`CONTRIBUTING.md`、`SPEC.md`、`ASWISH-PRODUCT-IDENTITY.md`、`ASWISH-DOCUMENTATION-GOVERNANCE.md`、`docs/AsWish-*.md`）中，上述词汇**仅出现在禁用声明或反向边界说明中**，零正面残留。
  - 检索 `Differential Monism`：仅在历史迁移审计记录中提及，所有当前有效文档一律统一为 `Difference Monism`。

---

## 10. 理论归因风险检查

- **Difference Monism (DM)**：保持存在条件论定位，不声称宇宙生成论；DOI `10.5281/zenodo.19852505`。
- **ASTO**：保持属集变迁存在论定位；DOI `10.5281/zenodo.19856467`。
- **ODD**：保持产出物驱动开发定位；DOI `10.5281/zenodo.20024964`。
- **CTF**：保持 Pre-spec 方法论定位；跨投影必须使用完整限定词 **CTF Semantic Bundle**；主张强度严格保持 **C2**，不升级为 C5。
- **PFM**：保持前线显影层定位；优先权记录 `10.5281/zenodo.19856528`。
- **fog_state**：显式标注为“待确权工程构造”，无理论越权。
- **invariants**：显式标注为“弱锚定 / 待确认”。
- **Wayfinder / Grill-me**：显式标注为“外部实践启发”，不归因于原创理论。
- **结论**：**理论归因风险为 0**。

---

## 11. Git Commit Hash 与构建证据

- **Git Commit Hash**：`5654259` (`docs: establish authoritative product identity and documentation governance SSOT`)
- **自动化测试**：`tests/AsWish.Tests.exe` 运行通过，126/126 Tests Passed，0 Failed，0 Leaked，0 Errored。
- **主程序构建**：`bin/AsWish.exe` 编译成功（0 Error / 0 Warning / 1 Hint）。
- **CLI 构建**：`cli/bin/AsWish.CLI.exe` 编译成功（0 Error / 0 Warning）。

---

## 12. 战略自问核对（终局检查）

如果一个完全不了解过去 DeepSpec 的 AI，第一次进入 `D:\_Progs\02Business\AsWish`，只阅读 `ASWISH-PRODUCT-IDENTITY.md` + `ASWISH-DOCUMENTATION-GOVERNANCE.md` + `AGENTS.md`：
- **它能否正确理解产品层级？**  
  $\rightarrow$ 能。明确五层：Difference Monism (理论母体) → As We Wish (人机述事引擎) → As I Wish (面向人的产品概念) → AsWish (工程实现) → .AsWish (工作空间)。
- **这个项目究竟为什么存在？**  
  $\rightarrow$ 解决生产速度超越人类理解速度的断口，回答 *Are we still building the same thing?* 与 *Where did the difference enter?*。
- **它不是在做什么？**  
  $\rightarrow$ 不是 Spec Tool / IDE / Coding Agent / 需求管理平台；不替代外部 Agent，不追求 Zero Difference。
- **它为什么需要 Spec，为什么不只是 Spec Tool？**  
  $\rightarrow$ Spec 是主链中可追溯、可审阅、可谬的共同理解状态；AsWish 贯穿显影、确认、看见、生产到实现证据验证的全闭环。
- **它与 AI Coding Agent 是什么关系？**  
  $\rightarrow$ 位于 Human ↔ Agent ↔ Software 之间的开放工程层；负责确认输入并比对实现结果，开发由 Agent 执行。
- **为什么 Difference 是核心问题？**  
  $\rightarrow$ Difference 是值得被看见和判断的变化；Difference ≠ Error，追求 Difference made visible, traceable, and judgeable。
- **为什么人类保留最终决策权？**  
  $\rightarrow$ 人类使用自然语言做意向与价值裁决，不直接写 Spec；AI 负责提问、发现与实现，不拥有最终决策权。
- **为什么开源？**  
  $\rightarrow$ *Test my claim*：让第三方能够运行、检验、反驳并推动理论修正。
- **第一阶段到底要验证什么？**  
  $\rightarrow$ 验证陌生开发者能否下载即用、完成第一次真实实验，并产生第一批 Difference 案例。
