# WO-20260830-001 Contract Brief

## Objective

为 `grilling_ticket` 提供可直接复制给外部 AI 工具的 grill-me 追问 Prompt 模板：以决策树拆解当前雾区，再依次澄清目标、边界和验收，并为每一问给出推荐答案。

## Scope

- 在 `src/services/DeepSpec.Services.Prompts.pas` 增加 `WriteGrillingPrompt`，复用既有 `WritePromptFile`。
- 按 issue id 输出 `prompts/grilling-ticket-<issue_id>.md`，列出受影响且处于 `misty`/`foggy` 的节点及待解问题。
- 新增 DUnitX 覆盖生成内容、路径和非 `grilling_ticket` 不生成。
- 在历史协议 §8.2 增加索引，唯一模板正文仍以代码为准。

## Out of scope

- 不修改 `itGrillingTicket`、`requires_human` 或其它数据模型。
- 不增加 ticket 创建入口 UI，不改变 BUG-11 的创建流程。
- 不引入 grill-me 外部依赖，不复制外部 SKILL 原文。

## Acceptance

- `itGrillingTicket` 生成结构化 Markdown，包含 3–6 条带依赖和顺序的决策分支、目标/边界/验收三问、每问推荐答案、受影响雾区节点和待解问题。
- 非 grilling issue 不写入 grilling prompt 文件。
- 主程序、测试工程和全量 DUnitX 测试通过，原始输出保存在 `WO/evidence/`。
- 文档只索引实现，不复制第二套模板正文。

## Contract digest

`sha256(work-order): 46984c8acb8eaec8a7439132cdcb05ba5d848ab2a8013aeff3f7eed53d745954`
