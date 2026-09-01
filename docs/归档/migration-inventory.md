# AsWish Migration Inventory

> 调查时间：2026-08-30
> 来源项目：`D:\_Progs\02Business\DeepSpec`
> 目标项目：`D:\_Progs\02Business\AsWish`（尚未创建，第一轮只调查）
> 分类：RENAME / REWRITE / KEEP / KEEP-AS-LEGACY / REVIEW / DO-NOT-TOUCH

---

## 1. 引用总量

| 维度 | 数量 |
|---|---|
| 文件名含 `DeepSpec` | ~90 文件 |
| 文件内容含 `DeepSpec`（大写） | 187 文件 |
| 文件内容含 `.deepspec` | 61 文件 |
| 文件内容含 `deepspec`（小写，含目录路径） | 216 文件 |
| `TDeepSpec` 类名出现 | 37 文件（src+tests） |
| `.deepspec` 硬编码于代码 | 10 文件 |

---

## 2. 分类清单

### A. 工程身份（action = RENAME）

| 位置 | 文件 | 迁移为 |
|---|---|---|
| 根 | `DeepSpec.dpr` / `.dproj` / `.dproj.local` / `.ico` / `.res` | `AsWish.*` |
| 根 | `DeepSpecConfig.db` | 待定（见 DECISION） |
| cli | `cli/DeepSpec.CLI.dpr` | `cli/AsWish.CLI.dpr` |
| installer | `installer/DeepSpec.iss` | `installer/AsWish.iss` |
| src | 38 个 `DeepSpec.*.pas` | `AsWish.*.pas`（含 unit 声明 + uses 子句） |
| tests | `DeepSpec.Tests.dpr` + 11 个 `Test.DeepSpec.*.pas` | `AsWish.Tests.dpr` + `Test.AsWish.*.pas` |
| .claude | `.claude/memory/project-deepspec.md` | `project-aswish.md` |

### B. 协议身份 `.deepspec/ → .AsWish/`（action = RENAME，全量）

硬编码 `.deepspec` 的代码文件（10 处，须全部改，不得遗留）：

- `src/controllers/DeepSpec.Controller.pas`
- `src/providers/DeepSpec.Providers.MainView.pas`
- `src/services/DeepSpec.Services.Project.pas`
- `src/services/DeepSpec.Services.Prompts.pas`
- `src/services/DeepSpec.Services.Render.pas`
- `src/services/DeepSpec.Services.Scan.pas`
- `src/services/DeepSpec.Services.SpecStore.pas`
- `cli/DeepSpec.CLI.dpr`
- `tests/Test.DeepSpec.Snapshot.pas`
- `tests/Test.DeepSpec.SpecStore.pas`

另含：`protocol/readers/python/deepspec_reader.py`（+ `__pycache__`）、`SPEC.md`、`protocol/schemas/*.json`、`protocol/examples/`、`protocol/tools/`、`protocol/readers/` 中的 `.deepspec` 引用。

### C. 产品品牌（action = REWRITE，语义重写非替换）

- `README.md`、`SPEC.md`、`NOTICE`、`LICENSE`（品牌与署名部分）
- `docs/` 30 个 `DeepSpec-*.md` 产品/方法论文档
- `docs/wayfinder-对DeepSpec的启发.md`
- `spw-manifest.json`、`boundary.json`（如含品牌）

### D. 理论 / 方法 / 第三方（action = DO-NOT-TOUCH / REVIEW）

| 概念 | 出现文件数 | action | 说明 |
|---|---|---|---|
| DM（差异一元论） | 见 DECISION | REVIEW | 拼写不一致，见下 |
| ASTO | 6 | DO-NOT-TOUCH | 理论名 |
| ODD | 14 | DO-NOT-TOUCH | 理论名 |
| CTF | 21 | DO-NOT-TOUCH | 核心方法论，主张强度不得升级 |
| PFM | 6 | REVIEW | 见 DECISION |
| fog_state | 21 | DO-NOT-TOUCH | 待确权工程构造 |
| invariants | 12 | DO-NOT-TOUCH | 弱锚定 |
| Wayfinder | 3 | KEEP | 外部启发 |
| Grilling | 13 | REVIEW | 外部启发，产品口径改 Decision Confirmation |

### E. 历史记录（action = KEEP / DO-NOT-TOUCH）

- Git 历史（全部 commit）
- `WO/` 历史工单（含 `WO-20260829-001-开发AI-DeepSpec用户视角收口工单.md`）
- `tests/dunitx-results.xml` 历史测试记录

---

## 3. DECISION REQUIRED（需主控/老板裁定）

| # | 问题 | 当前事实 | 推荐 | 风险 |
|---|---|---|---|---|
| D1 | **DM 理论名拼写**：任务文档写 `Difference Monism`，DeepSpec README 写 `Differential Monism` | 两者不一致，理论母库 `D:\_Progs\一元论\` 为 canonical source | 以理论母库为准，迁移时统一 | 理论名写错 → 学术归因错误 |
| D2 | **Continuity 目录残留**：上一轮复制产物 `D:\_Progs\02Business\Continuity` 仍存在 | 名字已废弃（改为 AsWish） | 删除 Continuity（确认其非回滚源后） | 误删？它是 cp 副本，非原始数据 |
| D3 | **`.AsWish/` 大小写**：任务文档写 `.AsWish/`（大写 W），`.deepspec` 为全小写 | Windows 文件系统大小写不敏感，但协议文档/git 敏感 | 统一为 `.aswish/` 或 `.AsWish/` 二选一，全仓一致 | 大小写不一致 → 协议混乱 |
| D4 | **DeepSpecConfig.db**：运行时本地配置库（475KB，含 LLM 配置/布局/密钥） | 属运行时状态，非源码 | 不迁移，新项目首跑重建（或改名 `AsWishConfig.db`） | 密钥残留风险 |
| D5 | **PFM 全称**：DeepSpec 用 `Problem Formulation Modeling`，AsWish 文档用 `Problem Manifestation Methodology` | 理论全称 vs 产品层表述 | PFM 缩写保留，全称表述迁移到 Manifestation 但标注与 Formulation 的承接关系 | 悄悄改理论名 |

---

## 4. 外部依赖风险

- **DeepBase**（`D:\_Progs\02Business\DeepBase`）：技术底座，边界不得改动，仅引用。
- **理论母库** `D:\_Progs\一元论\`：canonical source，只读引用，禁止修改。
- **Delphi/RAD Studio 13.1**（dcc64）：构建依赖，与改名无关。
- **WebView2 Runtime**：运行依赖，与改名无关。

## 5. 建议迁移顺序

Phase A 复制 → B 协议 `.AsWish/` → C 工程命名 → D 协议命名 → E 文档重写 → F 理论映射 → G 测试修复 → H 构建 → I CLI 回归 → J 审计。
