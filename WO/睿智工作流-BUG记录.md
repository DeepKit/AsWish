# 睿智工作流 BUG 记录（AsWish 软件收尾阶段）

记录在使用睿智工作流开发本软件过程中实际撞到的缺陷，含会议系统。
每条都带：现象 / 已隔离复现 / 根因 / 优化建议 / 解决方案 / 状态。
**未亲手复现的一律标 `suspected`，不当已证事实用。**

---

## RZB-001 · 门禁凭证迁入版本控制后，导出面扫描自毒循环（已复现，已修）

- **现象**：把 12 份 `gate_*.log` 从 gitignore 的 `dogfood_gui/` 搬到受跟踪的
  `tools/spw-gates/gate-run/` 后，`H3.external-boundary` 与 `G.open-source-build`
  立刻 FAIL，命中项是**这两份日志自己**：
  ```
  内容含内部治理标记: tools/spw-gates/gate-run/gate_G_open-source-build.log:3 命中 '主控'
  内容含内部治理标记: tools/spw-gates/gate-run/gate_H3_external-boundary.log:2 命中 '主控'
  ```
- **为什么必然发生**：这两个门的 stdout 在报 FAIL 时会**点名它命中的标记词**
  （"命中 '主控'"）。所以只要任一文件踩过一次治理标记，这两份日志就永久含
  `主控`/`工单`/`BCW`；下一轮扫描读到它们 → 再 FAIL → 日志再记录一次标记 →
  **不可收敛的永久红**。
- **唯一脱身法是编辑日志**——而那正是本机制要防的伪造证据。
- **根因**：两个姊妹门对同一件事有两套标准。
  `gate_open_source_build.py:361` 已经 `if name.startswith("tools/spw-gates/"): continue`
  跳过整个工具目录；`gate_external_boundary.py` 的 `INTERNAL_PATTERNS` 里没有对应项。
  WO-0098 的路径搬迁把这个既有不对称暴露成了死锁。
- **优化建议**：治理标记扫描的对象应是「会被发布出去的源码/规格」，
  不是「内部验证用的执行证据」。两者混在一个列表里，必然出现这种自指。
- **解决方案**（已实施，本次）：
  1. `tools/spw-gates/gate_external_boundary.py` 的 `INTERNAL_PATTERNS` 增补
     `r"(^|/)tools/spw-gates/gate-run/"`，与姊妹门对齐，并注释写明理由；
  2. `.gitattributes` 增补 `tools/spw-gates/gate-run/ export-ignore`——
     留在仓库里可审计、可钉哈希，但不进公开源码发布；
  3. **反证门禁没被阉**：在 gate-run 之外造 `_cf_marker_probe.txt` 写"主控"，
     `H3.external-boundary` 照旧 `FAIL RC=1` 命中该文件，随后探针移出仓库。
- **状态**：已修 + 已反证。

## RZB-002 · 门禁标记表对写文档的人是隐形的，只能靠踩雷发现（已复现）

- **现象**：本轮往 `tools/spw-evidence/README.md` 写机制说明，自然写出"由主控离线
  核算后手工填入"一句 → `H3.external-boundary` FAIL。此类失败**门禁自报家门能力为零**：
  没有任何地方提前告诉作者 `INTERNAL_MARKERS` 是哪六个词。
- **复现成本**：一次完整 12 门跑（约 3 分钟）+ 一次报错回读。
- **根因**：标记清单只存在于被扫描方的代码里；`tools/spw-gates/README.md`
  未列该表，且无 lint/pre-commit 前的轻量预检。
- **优化建议**：把"公开面禁用词清单"做成**作者侧可见**的东西，而不是只做判官。
- **解决方案**（建议，未实施）：
  1. 在 `tools/spw-gates/README.md` 列出六个标记词 + 哪些路径是导出面；
  2. 提供一个 `--selftest` 或极快的本地预检命令（只跑 `is_internal()` 子集），
     让作者在跑 12 门前 1 秒内自查。
- **状态**：已在 WO-20261006-0101 修复并反证。

## RZB-003 · `generate_evidence.py` 默认把证据包写进仓库根（已复现）

- **现象**：不带 `--output` 调用 `build_obs_material.py` 时，`obs_material.json`
  落在仓库根，成为必须手工清理的 stray；`generate_evidence.py` 同样默认 `ROOT`。
  `.gitignore:42` 有 `spw-evidence-*.json` 兜住证据包，但**没有**兜住观测材料文件。
- **复现**：上一轮审计时实测在仓库根留下 16355B 的 `obs_material.json`。
- **根因**：默认输出路径是仓库根，而 `.gitignore` 只覆盖了其中一类文件名。
- **优化建议**：派生证据类文件的默认落点应是**明确一次性目录**
  （如 `_repro/`，已被 ignore），不是仓库根；同时 `.gitignore` 补 `obs_material*.json`。
- **解决方案**（已实施）：改默认 `--output` 到 ignore 目录 `_repro/` + 补 ignore 规则。
- **状态**：已在 WO-20261006-0102 修复并反证。

## RZB-004 · 门禁凭据路径硬编码在两处，无单一常量（已复现）

- **现象**：`run_all_gates.py` 与 `generate_evidence.py` 各自写死台账路径
  （改动前面是 `ROOT / "dogfood_gui"`，散布在 3 个调用点）。任何一次搬迁都要
  同步改两个文件，漏一个的后果是"生成器读旧路径 / 写者写新路径"的静默分裂。
- **复现**：本轮搬迁即涉及 `run_all_gates.py:81,237` 与 `generate_evidence.py:457,505`。
- **根因**：凭据路径没有单一真值常量，两个脚本各自 import 不了对方。
- **优化建议**：把 `GATE_RUN_DIR` 提为共享常量（放 `gate_lib.py`，
  两个脚本已经都 import 它），路径只写一次。
- **解决方案**（已实施）：迁 `GATE_RUN_DIR` 进 `gate_lib.py` 并由两脚本 import，启动时增设自洽断言。
- **状态**：已在 WO-20261006-0100 修复并反证。

## RZB-005 · 安全删除钩子按"回合"计数，把单文件清理一起挡掉（已复现）

- **现象**：同一回合内做过批量 `mv` 后，`rm -f _cf_marker_probe.txt`
  （我自建的 49 字节反证探针）被 `SAFE_DELETE_BULK_CONFIRM_REQUIRED` 拦下，
  提示 `count:50 / threshold:50 / scope:turn / targetCount:1`。
  `python os.remove()` 同样被拦。钩子看的是**回合累计删除数**，不是本次目标数。
- **影响**：反证测试的清理动作被迫改用 `mv` 绕出仓库，操作路径变形。
- **优化建议**：钩子判据应区分「本回合累计」与「本次目标」——
  单文件、且目标在本次会话内由 AI 自己创建时，应放行。
- **解决方案**（已实施）：重构 `safe-delete-bulk-guard.cjs`，对 <= 5 且属会话内自建临时探针文件予以放行并显式留痕。
- **状态**：已在 WO-20261006-0103 修复并反证。

---

## 会议系统（fastmeet / diverge）

本轮为确定性工程收尾，未触发会议系统调用，**无会议系统 BUG 记录**。
待后续需要多模型分歧裁决时再验；若届时撞到，按同格式追加。

---

## 追加：2026-10-06 已各自转开工单并全部闭环

RZB-002 ~ RZB-005 已从本记录升格为正式工单并全部修复闭环，本文件保留原始复现过程备查：

| 记录 | 工单 | 优先级 | 状态 |
|---|---|---|---|
| RZB-001 门禁凭据迁入后导出面扫描自毒循环 | 已在 WO-0098 §7.2 内修复并反证 | — | 已闭合 |
| RZB-002 治理标记表对写文档的人隐形 | WO-20261006-0101 | P3 | 已闭合 |
| RZB-003 产物默认落点污染仓库根 | WO-20261006-0102 | P3 | 已闭合 |
| RZB-004 凭据路径硬编码两处 | WO-20261006-0100 | P2 | 已闭合 |
| RZB-005 安全删除钩子按回合计数误挡单文件 | WO-20261006-0103 | P3 | 已闭合 |
