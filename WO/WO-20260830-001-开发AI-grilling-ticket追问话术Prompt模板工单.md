# WO-20260830-001 · 开发AI · grilling_ticket 追问话术 Prompt 模板工单

- 下发时间：2026-08-30 00:35 (GMT+8)
- 下发人：主控AI
- 承接方：**开发AI（DeepSpec 仓库）**
- 工作仓库：`D:\_Progs\02Business\DeepSpec`
- 背景：主控识别到 grill-me（mattpocock/skills，62 万安装）的追问话术已被 DeepSpec 文档定位为 `grilling_ticket` 的参考实现（`docs/wayfinder-fog-of-war.md:100`），但当前只建了枚举、没建话术。本单把"怎么问"补上。
- 门禁：非睿智轻量门禁；单 commit ≤200 行；build/test 原始输出存档证据；合并由主控复核。

---

## 1. 背景与根因（主控已定位）

| 证据位置 | 事实 |
|---|---|
| `src\models\DeepSpec.Models.pas:412` | `itGrillingTicket` 枚举已定义 |
| `src\core\DeepSpec.Validation.pas:505` | `grilling_ticket` 类型已纳入校验 |
| `src\services\DeepSpec.Services.Prompts.pas` | **无任何 ticket/grilling 追问话术生成逻辑**（仅有 ContextPack/Generation/Node/DecisionRewrite 四类 Prompt） |
| `docs\wayfinder-对DeepSpec的启发.md:27-34` | 缺口 1：探索型 ticket 有枚举、无入口、无追问话术 |

结论：`grilling_ticket` 目前只是 issue 枚举 + `requires_human` 标记，缺"对一个雾区节点，该怎么一句句问用户"的话术模板。

## 2. 任务范围

1. **新增追问话术生成**：在 `Prompts.pas` 增加 `WriteGrillingPrompt`（或等价方法），当 issue 类型为 `itGrillingTicket` 时生成结构化追问 Prompt，写入 `prompts\grilling-ticket-<issue_id>.md`。话术吸收 grill-me 方法论（不照抄、不引入外部依赖），至少包含：
   - **决策树拆解**：把该雾区节点拆成 3–6 条顶层决策分支，标依赖关系，说明先问哪条。
   - **目标 / 边界 / 验收三问**：每问先给推荐答案，再等用户选择或自由作答。
   - **受影响雾区节点**：关联 `fog_state ∈ {misty, foggy}` 的节点，标注"待解问题"一句。
2. **导出复用**：复用 `WritePromptFile`，产出可直接粘贴给用户原 AI 工具（Claude Code / Cursor / Codex）的追问清单；按 `DeepSpec-MVP实施蓝图-v1.md` §14 的提示词导出适配规范做轻量适配。
3. **测试**：DUnitX 用例覆盖——grilling ticket prompt 生成（含三问、含推荐答案、含受影响节点）、非 ticket 类型不生成、输出文件路径正确。build + 全量测试输出存档为证据文件。
4. **文档**：`docs\DeepSpec-三棵树通用协议-v1.md` §8.2 Fog 探索模型补充 grilling_ticket 的追问话术说明（索引式，指向代码，不复制逻辑）。

## 3. 边界（禁止事项）

- **不重造数据模型**：`itGrillingTicket` 枚举、`requires_human` 字段已存在，直接复用。
- **不新建 ticket 创建入口 UI**（属 BUG-11 独立工单，本单只做 Prompt 话术生成层）。
- 不引入 grill-me 外部依赖或照搬其 SKILL.md 原文；只吸收方法论为本项目话术。

## 4. 验收标准（主控复验项）

1. 对任一 `fsFoggy`/`fsMisty` 节点开 `grilling_ticket`，能导出一份含"决策树拆解 + 目标/边界/验收三问 + 推荐答案"的追问清单，可直接粘贴给用户 AI。
2. 非 grilling 类型 issue 不触发该 Prompt，行为不回归。
3. 测试全绿，证据存档；`docs` 协议文档同步到位。
4. 主控复核通过后方可 CLOSE。

## 交付物

代码 + `WO\evidence\` 证据 + `WO\AUDIT-REQUEST-WO-20260830-001.md` 复审请求。
