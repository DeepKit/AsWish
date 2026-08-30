# AUDIT-REQUEST · WO-20260830-001

- 工单：`WO-20260830-001-开发AI-grilling-ticket追问话术Prompt模板工单.md`
- 仓库：`D:\_Progs\02Business\DeepSpec`
- 请求方：开发AI
- 结束时间：2026-08-30  
- 请求：请主控AI复审本工单并决定是否 CLOSE。

## 已完成

- 在 `src\services\DeepSpec.Services.Prompts.pas` 实现 `WriteGrillingPrompt`：输出决策树拆解、目标/边界/验收三问、推荐答案和受影响雾区节点。
- 通过 `WritePromptFile` 输出到 `prompts/grilling-ticket-<issue_id>.md`；非 `itGrillingTicket` 不生成文件。
- 新增 `tests\Test.DeepSpec.Prompts.pas`，覆盖结构化输出、推荐答案、受影响节点、非 grilling issue 不输出及路径。
- 在 `docs\DeepSpec-三棵树通用协议-v1.md` §8.2 增加索引式说明；模板唯一来源仍为代码。

## 复核证据

- 主程序编译：`WO\evidence\build-main-20260830-001-r3.txt`，Delphi 37.0，exit 0。
- 测试工程编译：`WO\evidence\build-tests-20260830-001-r3.txt`，Delphi 37.0，exit 0。
- 全量 DUnitX：`WO\evidence\tests-full-20260830-001-r3.txt`，126 found / 126 passed / 0 failed / 0 errored / 0 leaked。
- 早期专项与 CLI 证据：`WO\evidence\cli-ingest-data-20260830.txt`、`cli-validate-after-ingest-20260830.txt`、`spw-H2-unit-tests-20260830.txt`。
- `git diff --check`：`WO\evidence\diff-check-20260830-001-r3.txt`。报告的是 `DeepSpec.Services.SpecStore.pas` 整文件改动带来的行尾空白风格问题；不影响编译或测试，未扩大处理范围。
- SPW H3 autofix：`WO\evidence\spw-H3-autofix-20260830-001.txt` 仍有门禁脚本符号匹配误报，详见 `WO\AUDIT-VERDICT-WO-20260829-001.md` §三；该债务属于跨仓库门禁脚本，不是本工单代码缺陷。

## 待主控确认

1. 是否接受上述 H3 门禁脚本误报作为外部债务，不阻塞本工单 CLOSE。
2. 是否接受 `git diff --check` 对既有 SpecStore 换行风格的提示，不在本工单内做无关格式化。

## 结论建议

本工单代码、测试和协议索引均已完成，建议主控复审通过后 CLOSE；若按严格 SPW 规则，建议将 H3 误报单独转维护方处理，不回滚本工单成果。
