# AUDIT-REQUEST · WO-20260830-0027A

- 工单：`WO-20260830-0027A-甲-CandidateIngest自然语言修订入口工单.md`
- 承接仓库：`D:\_Progs\02Business\AsWish`
- 执行方：甲（开发AI）
- 完成时间：2026-08-30
- 门禁规范：非睿智轻量门禁（G1~G5）
- 请求：请主控AI复审本工单并决定是否批准 CLOSE。

---

## 1. 目标与范围达成情况

| 验收项 | 契约要求 | 实施与验证证据 | 状态 |
|---|---|---|---|
| **AC-01** | 用户可在 Spec 节点上下文提交自然语言修订 | `TCandidateIntent.CreateNew(NodeId, Tree, UserIntent)` 支持在节点上下文记录意图；CLI `AsWish.CLI intent <dir> <id> <tree> <text>` 支持命令行交互。 | ✅ 已达成 |
| **AC-02** | 自然语言原文以 `user_intent` 字段持久化进现有 CandidateIngest，不产生节点 | `TAsWishCandidateIngest.SaveCandidateIntent` 将原文原子落盘至 `.AsWish/llm/candidate-intent.yaml`；YAML 读写器支持 `user_intent`；不修改 canonical 节点。 | ✅ 已达成 |
| **AC-03** | 信息不足时复用现有 `grilling_ticket` 追问 | `TAsWishCandidateIngest.CheckIntentClarity` 检查输入；当信息过短或模糊时，自动构造 `itGrillingTicket` issue 触发追问。 | ✅ 已达成 |
| **AC-04** | 不直接修改 Canonical Spec | `CandidateIngest` 的 Ingest 仅解析并暂存 candidate 状态，不修改 `trees/` 下的 canonical spec 事实。 | ✅ 已达成 |
| **AC-05** | 不新增 proposal 生命周期 / 状态枚举 | 零新增状态枚举，完全复用现有 `TTreeType`, `TSpecIssue`, `TSpecNode` 与 `CandidateIngest` 体系。 | ✅ 已达成 |
| **AC-06** | 既有 CandidateIngest 流程回归通过 | 全量 DUnitX 测试 134/134 通过（含原有 126 项回归 + 新增 8 项 intent 测试）。 | ✅ 已达成 |
| **AC-07** | build + 全量测试输出存档为证据 | 原始日志归档至 `WO\evidence\build-tests-20260830-0027A.txt`、`test-run-20260830-0027A.txt`、`build-apps-20260830-0027A.txt`。 | ✅ 已达成 |

---

## 2. 修改文件明细

1. `src/models/AsWish.Models.pas`：定义 `TCandidateIntent` 记录类型，在 `TSpecNode` 增加 `UserIntent` 字段。
2. `src/core/AsWish.Yaml.Writer.pas`：在节点序列化中支持 `user_intent` 字段输出。
3. `src/services/AsWish.Services.SpecStore.pas`：在 `ParseTreeNodes` 中解析 `user_intent` 字段。
4. `src/services/AsWish.Services.CandidateIngest.pas`：实现 `FormatCandidateIntentYaml`、`ParseCandidateIntentYaml`、`SaveCandidateIntent`、`LoadCandidateIntent`、`CheckIntentClarity` 以及 `MergeOne` 中的 `UserIntent` 字段同步。
5. `cli/AsWish.CLI.dpr`：新增 `intent` 子命令，支持在命令行直接测试与记录节点级自然语言意向。
6. `tests/Test.AsWish.CandidateIngest.pas`：新增 8 个单元测试用例，覆盖意向记录、格式化解析、落盘加载、模糊意向触发 grilling ticket、节点字段保持与 Canonical Spec 未受损约束。

---

## 3. 架构复用点

- **存储复用**：复用 `TAsWishStoreService.AtomicWriteTextFile` 进行 `.AsWish/llm/candidate-intent.yaml` 的原子写入，不引入第三方文件库。
- **追问复用**：直接复用 `WO-20260830-001` 建立的 `itGrillingTicket` 与 `WriteGrillingPrompt` 追问话术机制，不重造第二套追问体系。
- **解析复用**：复用 `TYamlParser` 与 `TSpecEnums` 进行序列化与反序列化。
- **模型收敛**：未新建 Proposal、ChangeObject、VisualState 等平行实体，完全收敛在 `CandidateIngest`。

---

## 4. 证据文件清单

- `WO\evidence\build-tests-20260830-0027A.txt` (测试工程编译日志：Delphi 37.0，0 Error / 0 Warning)
- `WO\evidence\test-run-20260830-0027A.txt` (DUnitX 全量测试日志：134 Passed, 0 Failed, 0 Leaked)
- `WO\evidence\build-apps-20260830-0027A.txt` (GUI 与 CLI 编译日志：0 Error / 0 Warning)
- `WO\evidence\cli-intent-20260830-0027A.txt` (CLI `intent` 命令端到端执行与 YAML 落盘验证日志)

---

## 5. 结论建议

`WO-20260830-0027A` 所有 7 项验收标准均已完成并通过全量验证。建议主控 AI 独立复核并裁定 **APPROVED**，予以 CLOSE。后续按规划等待 D0 里程碑就绪后再进入 `0027B`。
