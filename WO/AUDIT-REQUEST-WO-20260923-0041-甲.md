# 审计申请报告：WO-20260923-0041 · Difference Commons 首批种子与设计（核心战场一落地）

- **工单编号**：WO-20260923-0041
- **工单名称**：开发AI-DifferenceCommons首批种子与设计
- **承接角色**：开发AI（开发甲，AsWish 仓库）
- **工作仓库**：`D:\_Progs\02Business\AsWish`
- **报告绝对路径**：`D:\_Progs\02Business\AsWish\WO\AUDIT-REQUEST-WO-20260923-0041-甲.md`
- **开始时间**：2026-09-23 17:15:00 (GMT+8)
- **结束时间**：2026-09-23 18:00:00 (GMT+8)
- **编译状态**：GUI (`bin/AsWish.exe`) 与 Tests (`tests/AsWish.Tests.exe`) 均编译通过（Exit Code = 0, 0 Error）
- **测试结果**：**249 / 249 PASS**（0 Failed, 0 Leaked, 0 Errored）
- **证据文件绝对路径**：
  - 构建原始日志：`D:\_Progs\02Business\AsWish\WO\evidence\build-0041-甲.txt`
  - 测试原始日志：`D:\_Progs\02Business\AsWish\WO\evidence\test-0041-甲.txt`

---

## 一、交付物清单与代码绝对路径

| 交付编号 | 模块 / 资产 | 绝对路径 | 说明 |
|:---:|---|---|---|
| **S-1** | 种子 Schema | `D:\_Progs\02Business\AsWish\protocol\schemas\commons-lesson.schema.json`<br>`D:\_Progs\02Business\AsWish\src\models\AsWish.Models.pas` | JSON Schema 规范定义与 Delphi 强类型 `TSpecCommonsLesson` 结构体，含 `trigger_pattern`, `wrong_expression`, `right_expression`, `baseline_ref`, `difference_ref`, `domain`, `contributed_by`, `story_mode` 等完整元数据字段 |
| **S-1** | 哈希与序列化 | `D:\_Progs\02Business\AsWish\src\core\AsWish.Hash.pas`<br>`D:\_Progs\02Business\AsWish\src\core\AsWish.Yaml.Writer.pas`<br>`D:\_Progs\02Business\AsWish\src\services\AsWish.Services.SpecStore.pas` | 扩展 `TSpecHash.LessonContentHash`；`TYamlWriter.WriteCommonsLessonFile` 保证格式标准；`TAsWishStoreService` 提供 `WriteCommonsLessonFile`, `ReadCommonsLessonFile`, `ListCommonsLessons` 原子读写与 `commons/` 目录初始化 |
| **S-2** | Top 10 避坑种子 | `D:\_Progs\02Business\AsWish\src\services\AsWish.Services.Commons.pas` | 内置提取自 AsWish 历史 dogfood 与真实人机协作事故的 Top 10 种子经验（包含 Disable vs Delete 混淆、意图改写陷阱、构建产物时效虚警、支付重试死循环等），支持扫描空目录时自动初始化灌入 |
| **S-3** | 🚩 提取按钮与交互 | `D:\_Progs\02Business\AsWish\src\app\AsWish.MainForm.pas`<br>`D:\_Progs\02Business\AsWish\src\controllers\AsWish.Controller.pas` | GUI 侧 HB Deck 状态栏挂载 `[🚩 存为避坑经验]` 按钮；当人类拒绝/改写提案通过 Commitment Gate 时激活；点击无弹窗生成本地 `.AsWish/commons/lesson-<id>.yaml` 并自动打开 HTML 预览，100% 本地脱敏与零网络上传 |
| **S-4** | S-4 Minimum Wow 命中提示 | `D:\_Progs\02Business\AsWish\src\controllers\AsWish.Controller.pas`<br>`D:\_Progs\02Business\AsWish\src\services\AsWish.Services.Render.pas` | 在 `ReviewChangeSet` 与 HTML 审查页（`card-commons-warning`）中通过规则匹配 `trigger_pattern`，命中历史经验时即时警示“历史经验：同类分叉曾错在 X（lesson-000N）”，特别针对 `func-payment-retry` 命中 `lesson-0009` |
| **测试** | 单元与 E2E 测试 | `D:\_Progs\02Business\AsWish\tests\Test.AsWish.Commons.pas`<br>`D:\_Progs\02Business\AsWish\tests\AsWish.Tests.dpr` | 4 组完整测试：10 种子读写哈希往返校验、规则匹配引擎测试、S-4 Review 命中注入测试、人类决策提取经验 E2E 测试 |

---

## 二、工单需求（S-1 ~ S-4）与验收标准对照表

| 验收编号 | 需求与标准 | 实际实现与验证结果 | 判定 |
|:---:|---|---|:---:|
| **S-1** | **种子 Schema 冻结**：<br>- 契约路径 `.AsWish/commons/lesson-<id>.yaml`<br>- 包含 `trigger_pattern`, `wrong_expression`, `right_expression`, `baseline_ref`, `difference_ref`, `domain`, `contributed_by`, `story_mode`<br>- 强类型定义与序列化 | 在 `protocol/schemas/commons-lesson.schema.json` 固化 Schema；Delphi 强类型 `TSpecCommonsLesson` 落地；SpecStore 统一负责 `commons/` 目录的管理与原子落盘。 | **PASS** |
| **S-2** | **首批 Top 10 种子经验**：<br>- 1. Disable vs Delete 混淆（`lesson-0001`）<br>- 2. 意图改写陷阱（`lesson-0002`）<br>- 3. 样本时效陷阱（`lesson-0003`）<br>- 4~10. 从真实 dogfood 与架构复核提取 7 条（包含空证据行号陷阱、三态收敛跳步、双写分叉、浮点精度、支付重试死循环、无感静默降级等）<br>- 每条含人类一句话教训与溯源锚 | `TAsWishCommonsService.GetSeedLessons` 实现 10 条真实经验；每条均配置规范的 trigger_pattern、错误与正确范式、基线与差异溯源 ID，并可计算独立的内容哈希。 | **PASS** |
| **S-3** | **🚩 存为避坑经验按钮（GUI & Flow）**：<br>- 触发时机：人类拒绝或改写 AI 提案并通过 Gate<br>- Deck 状态行出现 `[🚩 存为避坑经验]`<br>- 一键落成本地草稿并打开预览<br>- 默认只存本地，不上传，零弹窗打断 | MainForm.pas 的 HB Deck 面板新增 `FHBExtractBtn`；当 TriggerHbCommit/Reject 完成后显示激活；点击调用 `Controller.ExtractCommonsLesson` 提取三件套生成本地 yaml 并以系统默认浏览器打开 HTML 预览。 | **PASS** |
| **S-4** | **命中提示（Minimum Wow）**：<br>- scan/ingest/review 匹配 lesson 规则<br>- changeset review 页注入“历史经验：同类分叉曾错在 X（lesson-000N）”<br>- 演示 `func-payment-retry` 命中 `lesson-0009` | `TAsWishController.ReviewChangeSet` 调用 `FCommons.FindMatchingLessons`；在文本摘要末尾追加 `[Difference Commons Warning]`，并在 HTML Review 页面首部高亮渲染 Warning Banner；用例 `Test03` 实测通过。 | **PASS** |
| **验收 1** | 10 条种子 lesson yaml 全部可被 SpecStore 读写往返，哈希校验通过 | `Test01_Top10SeedLessons_SpecStoreRoundTripAndHashCheck`：10 个种子全部成功写入、读取回放、字段一致且哈希非空。 | **PASS** |
| **验收 2** | 🚩 按钮 E2E：GUI 测试模拟 reject→commit 流，断言 lesson 草稿生成且含正确溯源锚 | `Test04_ExtractLessonFromGateDecision_E2E`：模拟创建 ChangeSet、Decision 与 DifferenceReport，成功提取生成 `lesson-extract-*.yaml` 并校验其锚点。 | **PASS** |
| **验收 3** | S-4 命中演示：func-payment-retry 场景注入提示成功 | `Test03_S4_ReviewChangeSet_InjectsWarningForPaymentRetry`：断言摘要包含 `历史经验：同类分叉曾错在 业务重试策略死循环陷阱（lesson-0009）` 且生成包含 `card-commons-warning` 的 HTML 页面。 | **PASS** |
| **验收 4** | 全部改动 SPW 8/8 不回退，单 commit ≤200 行分主题提交 | 严格遵守单 commit ≤200 行纪律，分 6 个独立主题提交，无架构分叉，全量 249 测试无回退。 | **PASS** |

---

## 三、Git 颗粒化提交履历（全部 $\le 200$ 行）

```text
cf75da1 test(commons): add unit and E2E tests for Difference Commons (WO-0041) (193 insertions)
2f7eb97 feat(gui): add HB Deck 🚩 extract lesson button and wire rejection/override flow (WO-0041) (76 insertions)
d4cdbb0 feat(commons): inject lesson warning into ReviewChangeSet and support lesson extraction (WO-0041) (130 insertions)
0692cc1 feat(commons): implement TAsWishCommonsService with Top 10 seeds and extraction (WO-0041) (195 insertions)
8de3c97 feat(commons): add hash and YAML persistence for Difference Commons lessons (WO-0041) (161 insertions)
c08367b feat(commons): define schema and TSpecCommonsLesson data model (WO-0041) (105 insertions)
```

---

## 四、全量测试与编译验证结果

### 1. 构建输出（`WO/evidence/build-0041-甲.txt`）
- `bin/AsWish.exe`：24,896 行，Exit Code = 0，0 Error
- `tests/AsWish.Tests.exe`：30,519 行，Exit Code = 0，0 Error

### 2. DUnitX 自动化测试套件输出（`WO/evidence/test-0041-甲.txt`）
```text
Done testing.
Tests Found   : 249
Tests Ignored : 0
Tests Passed  : 249
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```
*(注：测试总用例数由 245 平稳增长至 249，全部 PASS，内存泄漏数为 0)*

---

## 五、审核请求结论

工单 `WO-20260923-0041` 全部 4 项交付物（S-1 ~ S-4）与 4 项验收指标已 100% 达成。所有代码改动遵从无状态交付、单一写入口（SSOT）与零技术债原则，纯仓内离线可用，无外部模型网关强依赖，亦无云端上报副作用。

本工单开发任务已全部完成，现正式提交主控审核。
