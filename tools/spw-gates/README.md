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
- **真实日志落盘**：将各门禁真实 `stdout` 输出至 `dogfood_gui/gate_<id>.log`，供证据生成器（`generate_evidence.py`）打包；
- **Fail-Closed 退出码**：任意 `required: true` 门禁非零退出即整体验收失败。

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
  - `baseline`: 历史存量遗留项，经架构评审复核确认；
  - `ongoing`: 封版后日常新增项，必须经专门审批；
- `approved_by`: 批准人或批准角色（必填非空，禁止自签）；
- `approved_at`: 批准日期（`YYYY-MM-DD`）；
- `expires_at`: （可选）到期日，若填，到期后门禁立即 fail-closed。

### 2. 门禁硬校验规则
- **陈旧豁免断言（Stale Waiver）**：若台账中记录的 `file` 不存在、行号越界、或对应行不再命中该模式，门禁直接报 `[HIGH] stale waiver` 失败，防止代码修改后豁免暗中漂移；
- **未审批新增豁免（Unapproved Ongoing）**：`scope="ongoing"` 的条目若缺少 `approved_by` 或 `approved_at`，门禁报 `[HIGH] unapproved ongoing waiver` 失败；
- **过期豁免断言（Expired Waiver）**：若 `expires_at` 已过，门禁报 `[HIGH] waiver expired` 失败；
- **未登记违规（Un-waived Hit）**：任何未在台账中登记的模式命中均报 `[HIGH] un-waived hit` 并以 `RC=1` 阻断。

---

## 文档内部溯源说明
公开文档（如 `README.md`、`.github/CONTRIBUTING.md`）中存在少量对内部历史研发纪要及治理规范的学术溯源引用（如 `docs/13.*`、`docs/07.*`）。这些属于事实性出处标注（Provenance Citation），在源码导出包中作为外部历史参照，不影响软件开源构建与独立运行。
