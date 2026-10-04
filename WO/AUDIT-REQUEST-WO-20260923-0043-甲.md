# 审计申请报告：WO-20260923-0043 · WO-0041 返修票（Commons 锚点整改 F-1~F-4）

- **工单编号**：WO-20260923-0043
- **工单名称**：开发AI-WO0041返修票-Commons锚点整改
- **承接角色**：开发AI（开发甲，AsWish 仓库）
- **工作仓库**：`D:\_Progs\02Business\AsWish`
- **报告绝对路径**：`D:\_Progs\02Business\AsWish\WO\AUDIT-REQUEST-WO-20260923-0043-甲.md`
- **开始时间**：2026-09-23 19:16:25 (GMT+8)
- **结束时间**：2026-09-23 19:35:00 (GMT+8)
- **编译状态**：GUI (`bin/AsWish.exe`) 与 Tests (`tests/AsWish.Tests.exe`) 均编译通过（Exit Code = 0, 0 Error）
- **测试结果**：**251 / 251 PASS**（0 Failed, 0 Leaked, 0 Errored）
- **SPW 门禁**：**8 / 8 PASS**（`H1`, `H2.compile-build`, `H2.compile-tests`, `H2.unit-tests`, `H3.encoding-guard`, `H3.runtime-autofix`, `H3.deep-ui-test`, `H4.bypass-patterns` 全绿）
- **证据文件绝对路径**：
  - SPW 门禁证据：`D:\_Progs\02Business\AsWish\WO\evidence\spw-evidence-0043.json`
  - 构建原始日志：`D:\_Progs\02Business\AsWish\WO\evidence\build-0043-甲.txt`
  - 测试原始日志：`D:\_Progs\02Business\AsWish\WO\evidence\test-0043-甲.txt`

---

## 一、返修项（F-1 ~ F-4）整改完成对照表

| 返修编号 | 审计退回项要求 | 实际实现与验证 | 判定 |
|:---:|---|---|:---:|
| **F-1** | **种子锚点诚实化（混合路线）**：<br>1. 真事故三条走实锚化（lesson-0002, 0003, 0009）：改为仓内可解析的真实持久化产物路径，灌入前加存在性检查，未解析拒绝灌入并 W1057 留痕；<br>2. 其余七条走诚实降级：schema 增 `anchor_kind: machine\|narrative`（默认 narrative），警示卡显示“源自实践总结，非可复核记录”，禁止裸字符串假装有锚；<br>3. Test01 扩展断言：machine 锚必须真实可解析，narrative 锚必须带标记。 | 1. `commons-lesson.schema.json` 与 `AsWish.Models.pas` 扩充 `anchor_kind: "machine" \| "narrative"`；<br>2. lesson-0002 锚定 `dogfood_0038` 真实 baseline 与 diff，lesson-0003 锚定 `dogfood_0036` B-0002 与 decisions，lesson-0009 锚定 `dogfood_0036` B-0001 与 diff；<br>3. 其余 7 条清空虚假 ref 字符串，显式标注 `anchor_kind := 'narrative'`；<br>4. 实现 `TAsWishCommonsService.ResolveAnchor` 全路径解析校验，`SeedCommonsLessonsIfEmpty` 对不可解析 machine 锚拒绝落盘并输出 `[W1057]` 留痕；<br>5. Review 警示与 HTML 警示卡对 narrative 种子注入 `[源自实践总结，非可复核记录]`；<br>6. Test01 实测校验 machine 锚 100% 解析、narrative 锚 100% 诚实标记；Test05 验证故意损坏 machine 锚被拒绝灌入。 | **PASS** |
| **F-2** | **提取基线张冠李戴修正**：<br>`TAsWishController.ExtractCommonsLesson` 不再取 `LBaselines[0]`；经 `Decision.ChangeSetId → Baseline.Lineage.ChangeSetId` 或 `DecisionId` 反查决断对应 baseline；查不到留空并标 narrative，并加单测。 | 重写 `ExtractCommonsLesson` 基线定位逻辑：遍历 `LBaselines` 比对 `LB.Lineage.ChangeSetId = LDec.ChangeSetId` 或 `LB.DecisionId = LDec.Id`。查不到时 `BaselineId` 留空，`ExtractLessonFromChangeSet` 自动将 `BaselineRef` 置空并赋值 `AnchorKind := 'narrative'`。新增单测 `Test06` 覆盖反查命中（machine）与未命中（narrative 降级）双分支。 | **PASS** |
| **F-3** | **manifest 覆盖面补登记**：<br>`spw-manifest.json` subject_files 补入 `src/services/AsWish.Services.Commons.pas` 及本票新改动文件；重跑 SPW 留证。 | `spw-manifest.json` 补入 `src/services/AsWish.Services.Commons.pas`；重跑 SPW 生成全新证据 `WO/evidence/spw-evidence-0043.json`，8 门禁全数通过（verdict=PASS）。 | **PASS** |
| **F-4** | **措辞修正**：<br>票面/注释中“系统默认浏览器”改为与实际实现一致的“shell 宿主预览面板（OpenView）”。 | 检查并确认代码中为 `OpenView` 宿主面板预览；在 `AsWish.MainForm.pas:1286` 补齐明确注释（WO-0043 F-4）；本交付报告与相关文档彻底校正措辞。 | **PASS** |

---

## 二、交付物清单与代码绝对路径

| 交付物 | 绝对路径 | 核心变动说明 |
|---|---|---|
| Schema 契约 | `D:\_Progs\02Business\AsWish\protocol\schemas\commons-lesson.schema.json` | 新增 `anchor_kind: "machine" \| "narrative"` 规范 |
| 数据模型 | `D:\_Progs\02Business\AsWish\src\models\AsWish.Models.pas` | `TSpecCommonsLesson` 增 `AnchorKind` 字段及 `CreateNew` 构造重载 |
| 哈希与序列化 | `D:\_Progs\02Business\AsWish\src\core\AsWish.Hash.pas`<br>`D:\_Progs\02Business\AsWish\src\core\AsWish.Yaml.Writer.pas`<br>`D:\_Progs\02Business\AsWish\src\services\AsWish.Services.SpecStore.pas` | `LessonContentHash` 纳入 `AnchorKind` 计算；`Yaml.Writer` 与 `SpecStore.ReadCommonsLessonFile` 保证 `anchor_kind` 往返持久化 |
| 避坑服务 | `D:\_Progs\02Business\AsWish\src\services\AsWish.Services.Commons.pas` | 1. 3 条实锚 + 7 条诚实 narrative 降级；<br>2. `ResolveAnchor` 锚点解析器；<br>3. `SeedCommonsLessonsIfEmpty` 锚点防线与 `[W1057]` 留痕；<br>4. `ExtractLessonFromChangeSet` 动态判定 machine / narrative |
| 控制器与前端 | `D:\_Progs\02Business\AsWish\src\controllers\AsWish.Controller.pas`<br>`D:\_Progs\02Business\AsWish\src\app\AsWish.MainForm.pas` | 1. `ExtractCommonsLesson` 执行血统反查；<br>2. `ReviewChangeSet` 对 narrative 经验追加“源自实践总结，非可复核记录”提示；<br>3. `MainForm.pas` 明确 OpenView 宿主面板预览逻辑 |
| 门禁清单 | `D:\_Progs\02Business\AsWish\spw-manifest.json` | subject_files 登记 `src/services/AsWish.Services.Commons.pas` |
| 单元与集成测试 | `D:\_Progs\02Business\AsWish\tests\Test.AsWish.Commons.pas` | 扩充 Test01（断言 machine/narrative 锚）；新增 Test05（负例损坏锚拒灌）、Test06（反查命中与未命中降级） |

---

## 三、Git 颗粒化提交履历（全部 $\le 200$ 行）

```text
81f816d test(commons): add tests for machine anchor verification and lineage extraction (WO-0043) (64 lines diff)
f0e7ceb feat(commons): implement F-2 lineage reverse lookup and narrative warning indicator (WO-0043) (28 lines diff)
1ae0860 feat(commons): implement machine anchor verification and seed honesty (WO-0043) (101 lines diff)
8ca86bc feat(commons): add anchor_kind field to schema and data model (WO-0043) (18 lines diff)
```

---

## 四、验证结果与原始证据

### 1. DUnitX 自动化测试套件（`WO/evidence/test-0043-甲.txt`）
```text
Done testing.
Tests Found   : 251
Tests Ignored : 0
Tests Passed  : 251
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```
- Test01 ~ Test06 全部 PASS：
  - `Test01`：10 个种子往返一致，3 个 machine 锚真实解析成功，7 个 narrative 锚正确标记；
  - `Test05`：伪造/损坏的 machine 锚无法通过 `ResolveAnchor`，`SeedCommonsLessonsIfEmpty` 拒绝灌入并输出 `[W1057]` 留痕；
  - `Test06`：无血统基线时生成 narrative 空锚草稿，有血统基线时生成对应 machine 锚草稿；
- 全量 251 测试 0 回退、0 失败、0 内存泄漏。

### 2. SPW 8/8 独立门禁验证（`WO/evidence/spw-evidence-0043.json`）
```json
{
  "gate_id": "H1.resource-locks", "verdict": "PASS",
  "gate_id": "H2.compile-build",  "verdict": "PASS",
  "gate_id": "H2.compile-tests",  "verdict": "PASS",
  "gate_id": "H2.unit-tests",     "verdict": "PASS",
  "gate_id": "H3.encoding-guard", "verdict": "PASS",
  "gate_id": "H3.runtime-autofix","verdict": "PASS",
  "gate_id": "H3.deep-ui-test",   "verdict": "PASS",
  "gate_id": "H4.bypass-patterns","verdict": "PASS"
}
```

---

## 五、审核请求结论

工单 `WO-20260923-0043`（裁决 F-1 ~ F-4 返修项）已 100% 完成整改：
1. 种子经验溯源做到 100% 诚实：真事故实锚化可机器复核，总结性教训诚实标明 narrative 且界面公开提示；
2. 提取经验彻底根除张冠李戴，按决策血统精确反查基线；
3. SPW manifest 覆盖面补登记，8 项门禁全绿通过并存档；
4. 4 次 Git 提交均严格控制在 200 行以内。

现正式提请主控审核 CLOSE。
