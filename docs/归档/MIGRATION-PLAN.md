# AsWish MIGRATION-PLAN

> 依据 `migration-inventory.md`，第一轮调查产物。
> 待主控/老板确认 D1–D5 决策后进入执行阶段。

---

## 前置决策（D1–D5，阻塞执行）

1. D1 DM 理论名拼写 —— 以理论母库为准。
2. D2 Continuity 目录 —— 是否删除。
3. D3 `.AsWish/` 大小写 —— 统一口径。
4. D4 DeepSpecConfig.db —— 不迁移/改名。
5. D5 PFM 全称 —— 承接关系标注方式。

---

## Phase A — 复制项目

- `cp -r DeepSpec AsWish`，保留 `.git` 历史。
- 清理编译产物（`.dcu` / `.exe` / `dcu/` / `bin/`）与工作区数据（`.workbuddy/`）。
- 原 DeepSpec 保持原样不动。

## Phase B — 协议目录 `.deepspec/ → .AsWish/`

- 代码层 10 处硬编码路径全量改。
- `protocol/readers/python/deepspec_reader.py` → `aswish_reader.py`（含 import 引用）。
- `SPEC.md`、`protocol/schemas/*.json`、`examples/`、`tools/` 同步。
- 本项目未正式发布，默认优先新协议名，不设 legacy alias（除非 D3 决定需要）。

## Phase C — 工程命名迁移

- 根工程文件 `DeepSpec.*` → `AsWish.*`。
- `src/` 38 个 `DeepSpec.*.pas` → `AsWish.*.pas`：文件名 + `unit` 声明 + 全部 `uses` 子句 + `TDeepSpec*` 类名。
- `cli/DeepSpec.CLI.dpr`、`installer/DeepSpec.iss`、`tests/` 工程与测试文件。
- `.claude/memory/project-deepspec.md` → `project-aswish.md`。

## Phase D — 协议命名迁移

- `DeepSpec Protocol` / `DeepSpec schema` 表述 → `AsWish Protocol` / `AsWish schema`。
- 确保新项目内无"品牌 AsWish 但协议仍叫 DeepSpec"的混乱。

## Phase E — 产品文档重写（语义重写，非替换）

- `README.md`：第一屏回答"什么是 As I Wish / 为什么存在 / 核心问题 / 层级关系"。
- `SPEC.md`、`docs/` 30 篇产品/方法论文档按新身份重写。
- 统一口径：As I Wish（产品）/ As We Wish（述事引擎）/ AsWish（工程）/ `.AsWish/`（工作空间）/ Difference Monism（理论）/ Decision Confirmation（机制）。
- 产品主链：显影 → 确认 → 建构 → 看见 → 生产 → 验证。

## Phase F — 理论映射适配

- 严格保持 DM / ASTO / ODD / CTF / PFM 归属，不得升级主张强度。
- `fog_state` / `invariants` 保持待确权 / 弱锚定。
- Wayfinder / Grill-me 保持外部启发定位。

## Phase G — 测试修复

- 测试工程名、测试用例中的 DeepSpec 引用、`.deepspec` 路径。

## Phase H / I — 构建 + CLI 回归

- dcc64 全量编译；CLI 全链路（init/scan/generate/validate/render/health/decisions/bundle/ingest）回归。
- 重点真实验证：init → 写入 `.AsWish/` → 重读 → validate → render，确认底层不残留 `.deepspec/`。

## Phase J — 最终审计

- 产出 `ASWISH-MIGRATION-REPORT.md`。
- 主控独立复核，未过不得宣告完成。

---

## 风险提示

- Delphi 单元名/类名强耦合（文件名=unit=uses 引用），改名须全量同步，否则编译失败。
- 改名后必须全量编译 + 全量测试，禁止仅"看起来改完"。
- 理论归因是最高风险区，AI 执行时不得擅改理论表述，理论相关改动逐条主控复核。
