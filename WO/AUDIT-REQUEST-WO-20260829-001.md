# WO-20260829-001 · 开发完成审核请求

## 工单

- 工单：`D:\_Progs\02Business\DeepSpec\WO\WO-20260829-001-开发AI-DeepSpec用户视角收口工单.md`
- 承接方：开发AI
- 状态：T1–T3 开发完成，申请主控复核；未申请 CLOSE
- 结束时间：2026-08-30 00:34:32 +08:00
- Git commit：未创建，等待主控复核后按工单门禁处理
- 契约 brief：`D:\_Progs\02Business\DeepSpec\WO\WO-20260829-001-contract-brief.md`
- 工单 digest：`sha256(work-order)=117fa315fecdba72c684c64c2abef06f11fc63cec75aaf8f870f8476fd0e01d3`

## 完成项

### T1 · data-tree 摄入闭环

- `CandidateIngest` 增加 `DataNodes` 路由；保留原三参数重载，兼容既有调用方。
- data 候选按现有 ID、父节点和合并规则处理；同 ID 合并更新数据字段，保留 `review_status` 与 `decision_refs`。
- 桌面控制器和 CLI 的 `ingest` 均加载、合并并持久化 `trees/data-tree.yaml`。
- 非 Delphi 项目从 JSON、YAML、键值配置、CSV、SQL、GraphQL/类型定义等材料推导实体和字段；混合项目不会因存在 Pascal 文件而跳过通用材料。无法推导时生成低置信 `data` 根节点与 `foggy` 占位节点。
- `Validation` 增加 data kind、风险、持久化、基数、执行位置、布尔值、列表、迁移元数据等校验。
- `SpecStore` 原有 data-tree 读写实现保持为唯一实现入口；新增全字段 round-trip 测试确认读写覆盖。
- 新增 CandidateIngest、TreeBuilder、Validation、SpecStore、Render 测试。

### T2 · 四投影口径

- 五份指定历史“三棵树/三树”文档增加失效口径和 `../SPEC.md` 映射标注，未删除历史内容。
- `docs/README.md`、`docs/DeepSpec-当前文档索引-v1.md` 指向四投影唯一入口。
- CLI 顶部 usage 已列出九条命令：`init`、`scan`、`generate`、`validate`、`render`、`health`、`decisions apply`、`bundle apply`、`ingest`。
- A→B/context prompt 已同步 `data-tree` 和 v1.2-draft 口径。

### T3 · 用户上手

- 新增 `D:\_Progs\02Business\DeepSpec\docs\DeepSpec-用户上手说明-v1.md`，包含一句话定位、四投影用途和操作、CTF/fog/gen_status/review_status 人话解释、桌面首次运行、ModelScope endpoint/API Key 配置、审阅决策写回、提示词导出及 CLI 路径。
- 根 README 的 First Run 和 docs 索引均指向该说明，避免形成第二套操作说明。

## 验证结果

| 检查 | 结果 | 原始证据 |
|---|---|---|
| 主程序与测试工程构建 | PASS，exit 0 | `D:\_Progs\02Business\DeepSpec\WO\evidence\spw-H2-compile-build-20260830.txt` |
| DUnitX 全量测试 | PASS，124 found / 124 passed / 0 failed / 0 leaked | `D:\_Progs\02Business\DeepSpec\WO\evidence\spw-H2-unit-tests-20260830.txt` |
| CLI 构建 | PASS，exit 0 | `D:\_Progs\02Business\DeepSpec\WO\evidence\build-cli-20260830.txt` |
| 通用/混合项目 CLI scan | PASS，输出 `data 6` | `D:\_Progs\02Business\DeepSpec\WO\evidence\cli-scan-generic-20260830.txt` |
| CLI data-tree validate | PASS，四树和 issues 均 0 error / 0 warning | `D:\_Progs\02Business\DeepSpec\WO\evidence\cli-validate-generic-20260830.txt` |
| CLI HTML render | PASS，生成 data-tree 页面 | `D:\_Progs\02Business\DeepSpec\WO\evidence\cli-render-generic-20260830.txt` |
| CLI health JSON | PASS，`totalNodes=10`、`status=ok` | `D:\_Progs\02Business\DeepSpec\WO\evidence\cli-health-generic-20260830.txt` |
| CLI data candidate ingest | PASS，`accepted=1 rejected=0 added=1` | `D:\_Progs\02Business\DeepSpec\WO\evidence\cli-ingest-data-20260830.txt` |
| ingest 后再次校验 | PASS，四树和 issues 均 0 error / 0 warning | `D:\_Progs\02Business\DeepSpec\WO\evidence\cli-validate-after-ingest-20260830.txt` |
| Git diff whitespace | PASS | `D:\_Progs\02Business\DeepSpec\WO\evidence\diff-check-20260830.txt` |

真实 CLI 样例目录：`D:\_Progs\02Business\DeepSpec\WO\evidence\runtime-generic-project`。样例同时包含 Python、TypeScript、JSON 和 Pascal 文件，用于验证混合项目分支；产物中的 `.deepspec/trees/data-tree.yaml` 和 `html/data-tree.html` 已生成。

## SPW 补充门禁

- H1 resource-locks：PASS，见 `D:\_Progs\02Business\DeepSpec\WO\evidence\spw-H1-resource-locks-20260830.txt`。
- H3 encoding：PASS，见 `D:\_Progs\02Business\DeepSpec\WO\evidence\spw-H3-encoding-20260830.txt`。
- H3 deep-ui：PASS，见 `D:\_Progs\02Business\DeepSpec\WO\evidence\spw-H3-deep-ui-20260830.txt`。
- H3 runtime-autofix：FAIL，见 `D:\_Progs\02Business\DeepSpec\WO\evidence\spw-H3-autofix-20260830.txt`。该静态脚本要求 `AutoFix.Install`、`AutoFix.RegisterScenario` 和 `TAutoFixScenarioRunner.RegisterScenario`；当前基线实际使用 `TDeepSpecAutoFix.Install`、`TDeepSpecAutoFix.RegisterScenario`，且这些基线调用在 `git show HEAD` 中已存在。本单未改动该无关命名/门禁规则，保留给主控决定是否另立工单修复。

## 复核入口

请主控复核：

1. data-tree 通用推导启发式的覆盖范围和误报取舍；
2. data 字段合并后是否需要在后续协议版本将数据字段纳入 content hash；
3. SPW runtime-autofix 静态脚本与现有 AutoFix API 命名不一致的问题。

本报告只请求审核，不把专家/脚本结果升格为正式决议，也不关闭工单。
