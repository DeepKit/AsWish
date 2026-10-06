# SPW Quality Gates (`tools/spw-gates`)

本目录包含 AsWish 单程序员工作流（SPW）与持续集成管线中运行的所有确定性质量门禁与工具。

---

## 门禁总运行器 (`run_all_gates.py`)

仓库内提供门禁总运行器 `tools/spw-gates/run_all_gates.py`，负责从 `spw-manifest.json` 动态驱动并顺序执行全部门禁：

```bash
python -X utf8 tools/spw-gates/run_all_gates.py
```

### 核心特性
- **动态驱动**：直接从 `spw-manifest.json` 读取 `gates[]`，不硬编码门禁列表；
- **防脱管哨兵**：自动扫描本目录下所有 `gate_*.py`，若存在未在 manifest 登记的门禁脚本，立即报错中断（防门禁脱管，见 WO-20261004-0088）；
- **防遗漏断言**：对比当前工作树与 `HEAD:spw-manifest.json`，禁止悄悄删除必需门禁；
- **真实日志落盘**：将各门禁真实 `stdout` 输出至 `tools/spw-gates/gate-run/gate_<id>.log`，供证据生成器（`generate_evidence.py`）打包；
- **Fail-Closed 退出码**：任意 `required: true` 门禁非零退出即整体验收失败。

### 凭据与日志目录单一真值源 (WO-20261006-0100)
- 门禁执行凭据与日志目录路径（`GATE_RUN_DIR`）的唯一真值定义位于 `tools/spw-gates/gate_lib.py`：
  `GATE_RUN_DIR = ROOT / "tools" / "spw-gates" / "gate-run"`
- 门禁总运行器（`run_all_gates.py`）与证据生成器（`generate_evidence.py`）必须统一从此模块 import 该常量，严禁在下游脚本中二次硬编码或私自定义。
- `generate_evidence.py` 启动时内置强一致性运行时断言：若读取方与写入方所引用的 `GATE_RUN_DIR` 不一致，直接抛出 `RuntimeError` 并中断执行。

---

## 门禁清单与职责

| 门禁 ID | 脚本/命令 | 核心防护职责 |
|---|---|---|
| `H1.resource-locks` | `gate_resource_locks.py` | 验证只读依赖树锁定与资源一致性 |
| `H2.compile-build` | `_build.bat` | 编译 Delphi 生产 GUI 主程序 |
| `H2.compile-tests` | `tests/_build_tests.bat` | 编译 Delphi 单元测试工程 |
| `H2.unit-tests` | `tests/AsWish.Tests.exe` | 运行全部 348 项单元测试与不变量断言 |
| `H3.encoding-guard` | `gate_encoding.py` | 源码 UTF-8 编码与 CRLF 换行守卫 |
| `H3.runtime-autofix` | `gate_autofix.py` | 运行时 AutoFix 场景与边界白名单校验 |
| `H3.deep-ui-test` | `gate_ui_bridge.py` | UI Bridge 与事件派发完整性静态断言 |
| `H3.gui-verify-smoke` | `gate_gui_verify_smoke.py` | 端到端 GUI 烟雾门禁（Win32 Job Object 孤儿防护） |
| `H3.external-boundary` | `gate_external_boundary.py` | 外部边界守卫、敏感标记与明文凭据防护 |
| `H4.bypass-patterns` | `gate_bypass_patterns.py` | Pascal 反绕过模式静态扫描与豁免台账治理 |
| `G.open-source-build` | `gate_open_source_build.py` | 开源构建、导出完整性与未授权 Python 脚本检测 |
| `G.vendored-upstream-drift` | `gate_ehai_vendor_drift.py` | DeepBase EHAI 类型层上游防漂移门禁 |

---

## H4 豁免治理与审批流程 (WO-20261004-0089)

H4 门禁用于防范代码中绕过 SpecStore 原子写/备份机制或隐藏错误的绕过模式（如 `TFile` 直写磁盘、`OutputDebugString` 静默吞错、硬编码绝对路径等）。

为杜绝“开发者自签免罪牌”，所有豁免必须在 `h4_waivers.json` 中统一纳管，并遵守以下治理规范：

### 1. 台账字段规范
每条豁免记录必须包含以下字段：
- `pattern_id`: 命中的模式标识符（如 `H4.DIRECT_DISK_WRITE`）；
- `file` / `line`: 命中的源文件相对路径与代码行号（1-based）；
- `code`: 命中的具体代码片段；
- `rationale`: 具体的业务理由或变更出处；
- `scope`: 范围分类：
  - `baseline`: 历史存量，尚未逐条经审核席位批准，门禁以 WARN 形式持续提示（属于已知技术债务）；
  - `ongoing`: 封版后日常新增项，必须经专门审批；
- `approved_by`: 批准人或批准角色（仅限 `h4_approvers.json` 登记角色，禁止自签或冒充，存量项可留空）；
- `approved_at`: 批准日期（`YYYY-MM-DD`）；
- `expires_at`: （可选）到期日，若填，到期后门禁立即 fail-closed。

### 2. 门禁硬校验规则
- **陈旧豁免断言（Stale Waiver）**：若台账中记录的 `file` 不存在、行号越界、或对应行不再命中该模式，门禁直接报 `[HIGH] stale waiver` 失败，防止代码修改后豁免暗中漂移；
- **冒充与未授权批准人阻断（Impersonation & Whitelist）**：`approved_by` 命中冒充模式（如 `MasterController-*`、`SPW-*`）或未在 `h4_approvers.json` 登记时直接报 `[HIGH] impersonated approver` 或 `[HIGH] unauthorized approver` 失败；
- **自签阻断（Self-Signing）**：若 `submitted_by` 与 `approved_by` 相同，直接报 `[HIGH] self-signed waiver` 失败；
- **未审批新增豁免（Unapproved Ongoing）**：`scope="ongoing"` 的条目若缺少 `approved_by` 或 `approved_at`，门禁报 `[HIGH] unapproved ongoing waiver` 失败；
- **过期豁免断言（Expired Waiver）**：若 `expires_at` 已过，门禁报 `[HIGH] waiver expired` 失败；
- **未登记违规（Un-waived Hit）**：任何未在台账中登记的模式命中均报 `[HIGH] un-waived hit` 并以 `RC=1` 阻断。

### 3. 审批权责与申请流程 (WO-20261004-0091)
- **有效批准人清单**：有效角色统一由 `tools/spw-gates/h4_approvers.json` 维护，门禁只读白名单。该文件缺失时门禁自动 fail-closed。
- **豁免申请规范**：下游开发角色严禁自填批准人。当新功能开发确实需要豁免时，需提交工程变更申请并如实填写 `submitted_by`，由独立审核角色（Master Controller）批准后登记真实的 `approved_by` 与 `approved_at`。未获正式核准的豁免一律不得并入基线。

---

## 文档内部溯源说明
公开文档（如 `README.md`、`.github/CONTRIBUTING.md`）中存在少量对内部历史研发纪要及治理规范的学术溯源引用（如 `docs/13.*`、`docs/07.*`）。这些属于事实性出处标注（Provenance Citation），在源码导出包中作为外部历史参照，不影响软件开源构建与独立运行。

---

## 发布面边界规则与本地自检 (WO-20261006-0101)

为确保开源代码仓库与发布包的纯净性，门禁 `H3.external-boundary` 与 `G.open-source-build` 对公开面内容实施静态审查。

> ⚠️ **写 README / docs 前先看一眼这里**：严禁在面向外部发布的源码与公开文档中引入内部治理标记或未导出的私有路径引用。

### 1. 内部治理标记词清单（SSOT 定义源：`tools/spw-gates/gate_external_boundary.py:45`）
以下 6 个词汇为内部治理标记，除在法律许可/历史学术归因声明（`STATUTORY_ALLOWLIST`）指定的三元组文件行外，**严禁出现在任何公开面代码或文档中**：
1. `主控`
2. `开发AI`
3. `WorkBuddy`
4. `工单`
5. `BCW`
6. `BetterCiv`

### 2. 公开面 vs 内部面路径定义
- **内部面路径（受排除，不作为公开面扫描）**：
  - `WO/`（内部工单与测试留痕）
  - `.workbuddy/`（工作区本地工作日志）
  - `.AsWish/`、`.ai-workbench/`、`_repro/`、`.claude/`
  - `docs/归档/`、`docs/_archive/`、`docs/*交接*`
  - 内部文档规范：`docs/07.*`、`docs/13.*`、`docs/15.*`、`docs/AsWish-Commons-PG.*`
  - 治理协议与审计件：`AGENTS.md`、`AUDIT-REQUEST-*`、`spw-evidence-*.json`
  - 门禁自身定义与执行凭据：`gate_external_boundary.py`、`gate_open_source_build.py`、`tools/spw-gates/README.md`、`tools/spw-gates/gate-run/`
- **公开面路径**：除上述受排除模式以外的所有源码（`src/`、`cli/`、`tests/`）、公开规范文档（`docs/01.*` ~ `docs/06.*` 等）、项目根目录公开文档（`README.md`、`LICENSE`、`NOTICE`、`.github/`）等。

### 3. 1 秒级本地极速预检
在提交前或编写文档后，作者可运行极速自查命令（耗时 < 1 秒，不依赖慢速的 `git archive` 或 `git add -A`）：
```bash
python -X utf8 tools/spw-gates/gate_external_boundary.py --selftest
```
该命令与正式门禁共享完全相同的 `INTERNAL_MARKERS` 与 `INTERNAL_PATTERNS` 判定逻辑，若命中标记将按文件归类打印精确行号与代码片段，便于即时修正。

### 4. 公开文档未导出出处引用台账 (8 处死链欠账明细)
公开文档中当前存在 8 处指向未导出内部出处（`docs/` 内部规范或内部文件）的引用。门禁 `G.open-source-build` 当前以 **WARN** 形式提示且不阻断发布构建。账目明细如下：

| 序号 | 所在文件及行号 | 引用的未导出内部路径 | 账目性质与处理建议 |
|---|---|---|---|
| 1 | `.github/CONTRIBUTING.md:4` | `docs/13.治理-文档治理与工程纪律.md` | 内部规范引用；保留内部溯源注记或替换为站内公开贡献说明 |
| 2 | `.github/CONTRIBUTING.md:31` | `docs/13.治理-文档治理与工程纪律.md` | 同上 |
| 3 | `.github/copilot-instructions.md:4` | `docs/13.治理-文档治理与工程纪律.md` | 内部规范引用；保留或替换为公开指引 |
| 4 | `README.md:87` | `docs/13.治理-文档治理与工程纪律.md` | 事实性溯源引用；属于已知技术债务，保留 WARN 不阻断 |
| 5 | `README.md:201` | `docs/07.工程-工程路线与Dogfood验收.md` | 事实性出处引用；保留 WARN 不阻断 |
| 6 | `README.md:228` | `AGENTS.md` | 内部 Agent 执行纪律指针；保留 WARN 不阻断 |
| 7 | `docs/11.理论-理论归因与CTF.md:130` | `docs/15.参考-工程与外部参考资料.md` | 理论外部参考引用；保留内部溯源注记 |
| 8 | `protocol/invariants.md:22` | `docs/07.工程-工程路线与Dogfood验收.md` | 协议事实出处引用；保留 WARN 不阻断 |
| 9 | `protocol/state-machine.md:5` | `docs/07.工程-工程路线与Dogfood验收.md` | 协议事实出处引用；保留 WARN 不阻断 |
