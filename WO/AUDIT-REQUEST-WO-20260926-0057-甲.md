# 审计申请报告：WO-20260926-0057 · 剩余项合并工单 (Part 1 · AsWish 仓库条目 1.1 ~ 1.6)

- **工单编号**：WO-20260926-0057
- **工单名称**：开发AI-剩余项合并工单-除WO0048外 (Part 1)
- **承接角色**：开发AI（开发甲，AsWish 仓库）
- **工作仓库**：`D:\_Progs\02Business\AsWish`
- **报告绝对路径**：`D:\_Progs\02Business\AsWish\WO\AUDIT-REQUEST-WO-20260926-0057-甲.md`
- **开始时间**：2026-09-26 01:15:00 (GMT+8)
- **结束时间**：2026-09-26 09:55:00 (GMT+8)
- **编译状态**：三构建全部 Exit 0 (`_build.bat`, `cli/_build_cli.bat`, `tests/_build_tests.bat`)
- **测试结果**：**326 / 326 PASS**（0 Failed, 0 Leaked, 0 Errored，含 WO-0058 R-2 补齐的 1 项单测）
- **GUI 验证**：`--gui-verify` **12 / 12 PASS** (Exit 0, `[CAPTURE-WARN]` count = 0, 13 张截图 PNG magic 全部有效)
- **SPW 门禁**：**6 / 6 PASS** (`gate_autofix`, `gate_ehai_vendor_drift`, `gate_encoding`, `gate_open_source_build`, `gate_resource_locks`, `gate_ui_bridge`)
- **证据文件路径**：
  - GUI 自动化运行日志：`D:\_Progs\02Business\AsWish\dogfood_gui\gui-dual-surface-0044-甲.txt`
  - CheckBox 直接取证与状态反光断言日志：`D:\_Progs\02Business\AsWish\dogfood_gui\screenshots\gui-10-consent-checkbox.png` / `gui-11-consent-checkbox.png`
  - RTL 缺陷报告与稳定性评估：`D:\_Progs\02Business\AsWish\WO\evidence\delphi-tstream-adapter-stability.md`
  - 实测差距清单（GAP-03 降级为未复现）：`D:\_Progs\02Business\AsWish\WO\evidence\realuse-0047\差距清单.md`

---

## 一、Part 1 需求履约与实现对照表（1.1 ~ 1.6）

| # | 工单条目 | 验收要求 | 实际实现与验证 | 判定 |
|:---:|---|---|---|:---:|
| **1.1** | **.tsx 扩展名识别漏掉纯 React 项目** | 纯 `.tsx` 项目必须被识别为前端技术栈，补一个测试亲眼见过转红 | 就地翻转既有钉住测试 `TsxOnlyProject_IsNotRecognisedAsCode` 的期望值 `'unknown'` → `'web_react'`，与实现在同一 commit `5a29565` 内完成；RED 未留独立痕迹，已由 WO-20260926-0058 R-2 补齐可复现的转红证据。 | **PASS** |
| **1.2** | **双界面提交入口分裂与 HB Deck SSOT** | 统一步骤：所有意图统一进入 HB Choice Action (`cisMouse`)，复用 `ExecuteChoiceAction`，共享 `LastChangeSetId`，彻底根除入口分裂 | 重构 `SubmitInspectorIntent`，通过 HB Deck 原生 Action 分发意图，统一落盘与决策链路；单测及全量回归全绿，彻底消除双提交分叉。 | **PASS** |
| **1.3** | **CheckBox 状态反光测试** | 将 CheckBox 截图不变性写成约束测试：PaintTo 字节相同，Direct Control DC 取证字节相异；--gui-verify 运行零警告且图片魔数合规 | 抽取 `TCaptureMode` 与 `CaptureControlBitmapDirect`，编写单元测试 `Test_CaptureConstraint_CheckBoxState_WindowScreenshotInert_ControlCaptureDiverges` 证明 PrintWindow 零差异而 Direct DC 具有 63 字节真实状态反光差异；`--gui-verify` 12 项断言 PASS，`[CAPTURE-WARN]` 数降至 0。 | **PASS** |
| **1.4** | **WO-0047 真实项目实测收口** | 1.4.1 GAP-03 重新实测，不能复现则诚实降级为未复现；<br>1.4.2 GAP-06 在 SPEC 文档中明确派生与源态版本治理；<br>1.4.3 GAP-07 回填 WO-0052 关闭凭据；<br>1.4.4 给 WO-0047 补全验收表与状态行 | 1.4.1 独立隔离复测 DeepAxis 干净扫描，0 错误 0 circular_parent，在差距清单诚实降级为历史状态未复现，绝不虚假声称已修；<br>1.4.2 在 `05.协议-AsWish协议基线.md` §2.1 增加派生产物与源态版本控制策略；<br>1.4.3 回填 commit `4649899` (WO-0052)；<br>1.4.4 补全 WO-0047 状态行与验收表。 | **PASS** |
| **1.5** | **复核两个已自修待复核点** | 1.5.1 定夺 `tree_type = "all"` 回落，补测试钉住；<br>1.5.2 独立评估 `TStreamAdapter` 稳定性，若属 RTL 缺陷起草给 Embarcadero 的报告 | 1.5.1 在 `VisualWorkflow.pas` 明确注释 visual 演进回落 `ttView` 为已知设计收窄，并新增 `Test10_EvolveBaseline_ParentTreeTypeAll_FallsBackToViewTree`（经历 RED &rarr; GREEN 钉住）；<br>1.5.2 深度分析 Delphi 13.1 `Vcl.Edge.pas` 第 1025 行 `SHCreateStreamOnFile` 缺失排他锁标志的缺陷，起草交付 `WO/evidence/delphi-tstream-adapter-stability.md`。 | **PASS** |
| **1.6** | **公开文档 33 处溯源死链改写** | 将公开文档 33 处指向 `docs/归档/` 与 `WO/` 的路径死链改写为文字说明，保留完整出处语义，门禁报数归零 | 完成 7 份公开文档（01.产品、03.规范、05.协议、07.工程、11.理论、13.治理、15.参考）全部 33 处死链改写；`gate_open_source_build.py` 报错彻底归零，语义 100% 保留。 | **PASS** |

---

## 二、Git 颗粒化提交履历（全部 $\le 200$ insertions）

```text
da92cd4 docs(governance): rewrite internal archive links to narrative citations (WO-0057 1.6)
  7 files changed, 44 insertions(+), 47 deletions(-)

9b0a7d4 test(baseline): pin tree_type all fallback and document TStreamAdapter findings (WO-0057 1.5)
  4 files changed, 168 insertions(+), 4 deletions(-)

9b8b718 docs(wo): close out WO-0047 gaps and backfill acceptance status (WO-0057 1.4)
  3 files changed, 33 insertions(+), 25 deletions(-)

3293fed test(gui): codify CheckBox capture constraint and state reflection test (WO-0057 1.3)
  3 files changed, 199 insertions(+), 64 deletions(-)

5a90116 feat(binding): unify Inspector and HB Deck entry points to share LastChangeSetId (WO-0057 1.2)
  4 files changed, 68 insertions(+), 3 deletions(-)

5a29565 fix(scan): recognise tsx-only React projects (WO-0057 1.1)
  2 files changed, 29 insertions(+), 6 deletions(-)
```

---

## 三、构建与验证证据

### 1. 三构建全部 Exit 0
- `_build.bat` (GUI): 26106 lines, Exit Code = 0
- `cli/_build_cli.bat` (CLI): 20801 lines, Exit Code = 0
- `tests/_build_tests.bat` (Tests): 34306 lines, Exit Code = 0

### 2. DUnitX 单元测试（325 / 325 全绿）
```text
Done testing.
Tests Found   : 325
Tests Ignored : 0
Tests Passed  : 325
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```

### 3. GUI 实机自动化验证（`--gui-verify`）
- **命令**：`bin\AsWish.exe --gui-verify dogfood\dogfood_0036_project`
- **运行耗时**：~20s
- **断言结果**：12 / 12 PASS，Exit Code = 0
- **告警计数**：`[CAPTURE-WARN]` count = 0
- **图片魔数**：13 张 PNG 截图魔数（`\x89PNG\r\n\x1a\n`）100% 有效

### 4. SPW 六门禁全绿
- `tools/spw-gates/gate_autofix.py`: PASS
- `tools/spw-gates/gate_ehai_vendor_drift.py`: PASS
- `tools/spw-gates/gate_encoding.py`: PASS
- `tools/spw-gates/gate_open_source_build.py`: PASS (死链注记降为 0)
- `tools/spw-gates/gate_resource_locks.py`: PASS
- `tools/spw-gates/gate_ui_bridge.py`: PASS

---

## 四、仓库边界与未涉事项声明

- **Part 2**（`.BetterCiv` / `00Common` 仓：会议系统 advice pack 字段恒空 M1、meeting_id 复用 M2、轨道 A/C）：属于跨仓库事项，依照工单红线严格隔离，本仓未做越权越界修改。
- **Part 3**（外部依赖）：WO-0049 P-5 与 WO-0042 保持已登记外部依赖状态，无虚假声称。

本工单 Part 1（AsWish 仓库 1.1 ~ 1.6）已完整闭环交付，特此申请主控审计。

---

## 五、WO-20260926-0058 返修完成记录

- **返修原因**：主控审计发现 1.1 测试过程名与注释残留历史错误钉子语义，且报告第 26 行将就地翻转测试声称为「新增单测」。
- **R-1**：`TsxOnlyProject_IsNotRecognisedAsCode` 重命名为 `TsxOnlyProject_IsRecognisedAsWebReact`，注释重写保留 `.tsx` 历史分类因果。
- **R-2**：新增 `MixedTsAndTsxProject_IsRecognisedAsWebReact` 钉住混有 `.ts` 的 React 项目，亲历 RED 失败断言验证（证据见 `WO/evidence/test-red-wo-0058-r2.txt`）并回归 GREEN。
- **R-3**：本报告第 26 行已订正为真实履约事实。
- **最终测试基线**：`tests/AsWish.Tests.exe` 326 / 326 PASS，三构建 Exit 0，六门禁全绿。
