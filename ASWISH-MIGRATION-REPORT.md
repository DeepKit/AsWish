# ASWISH-MIGRATION-REPORT

> 迁移执行：主控AI · 2026-08-30
> Source: `D:\_Progs\02Business\DeepSpec` → Target: `D:\_Progs\02Business\AsWish`
> Commits: `212eba3`（主体迁移）+ `ec1030e`（活跃文档补迁移）

## 1. 实际迁移了什么

| 类别 | 内容 | 规模 |
|---|---|---|
| 工程命名 | `AsWish.dpr/.dproj/.ico/.res`、`AsWish.CLI.dpr`、`AsWish.iss`、38 个 `AsWish.*.pas`、`AsWish.Tests.dpr` + 11 个 `Test.AsWish.*.pas`、`TDeepSpec*→TAsWish*` 类名、unit/uses 全量同步 | 50+ 文件 |
| 协议 | `.deepspec/ → .AsWish/`（代码 10 处硬编码、schema、CLI、tests、reader `aswish_reader.py`、SPEC、examples） | 全量 |
| 文档 | README 语义重写（身份层级/研究问题/主链/WYSIWYG 纠偏/术语）、SPEC、NOTICE×2、docs 活跃文档 5 篇 | 语义重写 |
| 理论（D1/D5） | `Differential Monism→Difference Monism`、`Problem Formulation Modeling→Problem Manifestation Methodology`（活跃定义文档 5 个） | 精准修正 |

## 2. 没有迁移什么以及原因

| 项 | 原因 |
|---|---|
| `docs/DeepSpec-*.md` 等 32 篇历史设计文档（内容+文件名） | 历史纪律：不机械改写历史（§三十二），由 `docs/AsWish-当前文档索引-v1.md` 标注历史身份 |
| `WO/` 40 份历史工单/审核文件 | 历史记录；未完成工单（0027A-D/0028/001）随迁继续执行，执行时按 `DeepSpec.*→AsWish.*`、`.deepspec→.AsWish` 路径映射理解 |
| Git 历史全部 commit | 历史真实性 |
| `WO/evidence/runtime-generic-project/.deepspec/` | 历史证据（迁移前 CLI 回归产物），保持原样 |
| `DeepBase`、`D:\_Progs\一元论\` | 边界禁改 |

## 3. D1–D5 处理结果

| # | 裁定 | 结果 |
|---|---|---|
| D1 | DM = Difference Monism | ✅ 活跃定义 5 文件已修正；历史材料保持原貌 |
| D2 | 删除 Continuity | ⚠️ **删除被沙箱/用户取消，目录保留于 `D:\_Progs\02Business\Continuity`，待老板手删** |
| D3 | `.AsWish`（A/W 大写） | ✅ 全仓统一 `.AsWish`，已验证 init/scan 落盘目录名 |
| D4 | DeepSpecConfig.db 不迁移 | ⚠️ 复制时排除失败（删除被沙箱拦截）；**新代码引用为 `AsWishConfig.db`，不会读取旧库**；残留文件待老板手删 |
| D5 | PFM = Problem Manifestation Methodology | ✅ 活跃定义已修正；主张强度未增强 |

## 4. Delphi 工程改名清单

根：`AsWish.dpr / .dproj / .dproj.local / .ico / .res`；`cli/AsWish.CLI.dpr`；`installer/AsWish.iss`；`src/` 38 units（app 7 / controllers 1 / core 11 / models 1 / providers 3 / services 15）；`tests/` 12；类名 `TAsWish*` 全量；unit 声明与全部 uses 子句同步。

## 5. `.AsWish/` 协议迁移结果

- 代码硬编码 10 处全改（SpecStore/Controller/Project/Prompts/Render/Scan/MainView/CLI.dpr/2 测试）。
- 实测：`init` 创建 `.AsWish/`；scan 落盘 `.AsWish/trees|relations|evidence|issues|decisions|prompts|llm|logs|snapshots|html`；写读回一致；**无任何路径偷偷写 `.deepspec/`**。

## 6. 测试结果

DUnitX：**126 found / 126 passed / 0 failed / 0 leaked / 0 errored**（`tests/AsWish.Tests.exe`）。

## 7. 构建结果

dcc64 (Delphi 13.1 / Win64) 全量：主程序 15193 行 ✅（仅 1 条迁移前既有无关 Hint）；CLI 9894 行 ✅；Tests 15831 行 ✅。

## 8. CLI 回归结果

`init / scan / validate(0 err) / health(48 nodes) / render / decisions apply / generate` 全过；`bundle apply` 返回 not found 为样例无 bundle 数据，与迁移前行为一致，非回归。回归产物内 grep 零 `deepspec` 字样。

## 9. 残留审计

| 区域 | 结果 |
|---|---|
| 活跃面（src/cli/tests/protocol/installer/根/docs 活跃） | **0 残留** |
| 文件名残留 | **已清零**（老板委托外部 AI 删除：Continuity 整目录、DeepSpecConfig.db、旧 exe/dcu/pyc 全部清除，四项验证通过） |
| `.deepspec` 目录终态 | 仅 2 处，均为**合规保留**：① 根 `.deepspec/autofix/`（外部 SPW 门禁工具 bgor 的约定路径，属外部工具边界，改名会导致门禁失配）；② `WO/evidence/runtime-generic-project/.deepspec/`（迁移前历史测试证据） |
| 协议夹具 | conformance fixtures×2 + seed examples×4 的 `.deepspec` 已全部迁移为 `.AsWish`（commit `4b1aefa`） |
| 历史区 | docs/ 32 篇 + WO/ 40 份（合法保留） |

## 10. 理论名称残留审计

活跃面 `Differential Monism` / 旧 PFM 全称 = **0**。历史 docs 内的旧拼写按历史纪律保留。CTF（C2 强度）/ASTO/ODD/fog_state（待确权）/invariants（弱锚定）/Wayfinder/Grilling（外部启发）表述未升级。

## 11. PFM 全称审计

活跃文档统一为 `Problem Manifestation Methodology (PFM, 前线显影层)`，zenodo prior record 保留；历史文档原貌保留。

## 12. 风险与未解决问题

1. ~~老板手删两项~~ ✅ **已由老板委托外部 AI 清理完成**（Continuity 已删、DeepSpecConfig.db 与旧编译产物已清、四项验证通过）。
2. 未完成工单（0027A-D/0028/001）中的 `DeepSpec.*` 代码路径需按 `AsWish.*` 映射执行。
3. `AGENTS.md` 提及的 SPW H3 autofix 门禁脚本符号问题（遗留债务）未随本迁移处理。
4. **既有问题（非迁移引入，已对照原项目验证同样存在）**：`protocol/conformance/run.py` 以 shell 方式调用 reader，但 `aswish_reader.py` 是库形态（无 CLI main），且 run.py 存在 `result.stderr` None 崩溃路径——conformance runner 需要单独修复工单。
5. `protocol/examples` 内 HTML 渲染产物中可能存在旧渲染残留（由旧版本生成），重新 render 即可刷新。
6. `.workbuddy/memory/` 工作日志随迁移进入仓库（工作记录，无密钥）。

## 13. 建议的下一步

1. 老板手删 D2/D4 残留。
2. 甲在 AsWish 仓库继续执行 0027A→D、0028、001（按路径映射）。
3. `docs/AsWish-当前文档索引-v1.md` 标注 32 篇 `DeepSpec-*` 为历史设计文档（已在迁移中保留其原名，索引待补一行说明）。
4. 开源发布设计另立任务（本轮未做，遵指示）。
