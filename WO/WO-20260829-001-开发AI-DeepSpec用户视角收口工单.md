# WO-20260829-001 · 开发AI · DeepSpec 用户视角收口工单

- 下发时间：2026-08-29 23:47 (GMT+8)
- 下发人：主控AI
- 承接方：**开发AI（DeepSpec 仓库）**
- 工作仓库：`D:\_Progs\02Business\DeepSpec`
- 背景：主控从用户视角审读，核定 3 个一般问题（非战略，主控已定调）。本单为一次性收口：先补引擎缺口，再统一口径，最后降上手门槛。
- 门禁：非睿智轻量门禁；单 commit ≤200 行；build/test 原始输出存档证据；合并由主控复核。

---

## T1 · data-tree 第四投影摄入闭环（核心引擎）

**根因（主控已定位）**：
- `src\services\DeepSpec.Services.CandidateIngest.pas:229-237`：`if LNode.Tree = ttData then` 无条件 warn + drop，注释"data nodes come from scan, not LLM"——导致 LLM 生成的 data 候选无法合并进 B。
- `src\services\DeepSpec.Services.TreeBuilder.pas:669` `BuildDataTreeFromDelphi` 仅从 Delphi published fields 生成 data 节点，通用项目（web_react/python/mixed）data-tree 恒空。
- 渲染层已就绪（`Render.pas` 有 `data-tree.html` 与 `ttData` 分支），断点只在"生成→摄入"。

**要求**：
1. `CandidateIngest` 放开 `ttData` 摄入：data 候选正常路由进 `DataNodes`，不再 drop；与扫描生成的 data 节点按既有冲突规则（`merge` 语义）处理，而非一律拒绝。
2. `TreeBuilder` 为非 Delphi 项目补 data-tree 生成兜底（从配置/类型定义/数据文件推导 data 实体，推导不出则生成 data 根节点 + 低置信占位，`fog_state` 置 misty/foggy）。
3. `Validation` / `SpecStore` 对齐 data-tree 的完整校验与读写，确认与 function/module/view 三树一致。
4. 测试：补 DUnitX 用例——`CandidateIngest` 的 data 摄入（接受/冲突/非法 id 拒绝）、`TreeBuilder` 通用项目 data 生成、data-tree 渲染。build + 全量测试输出存档为证据文件，禁止仅自报 PASS。

## T2 · 四投影口径统一（文档一致性）

**根因**：`docs\` 大量 `DeepSpec-*三棵树*` 历史文档沿用"三棵树"旧口径，与 `SPEC.md`/`CTF.md` "四投影"（function/module/view/data）不一致；`cli\DeepSpec.CLI.dpr:1-16` 头部注释只列 5 命令，实际已实现 9 条。

**要求**：
1. 为历史"三棵树"文档加失效/映射标注（指向 `../SPEC.md` 四投影口径），不删除历史内容；`docs\README.md` 与 `DeepSpec-当前文档索引-v1.md` 同步为四投影索引。文档只保留"唯一信息 + 索引"，不复述代码逻辑。
2. `cli\DeepSpec.CLI.dpr` 头部 usage 注释补全 9 条命令（`init/scan/generate/validate/render/health/decisions apply/bundle apply/ingest`），与 `README.md` Headless CLI Usage 对齐。

## T3 · 用户上手收口（易用性）

**要求**：
1. 产出《DeepSpec 用户上手说明》（README 一节或 `docs\` 独立篇）：一句话定位；四投影分别"解决什么问题、怎么操作"；典型路径（拖入项目 → 配 LLM key → 生成 → 审阅 → 决策写回 → 导出提示词）；首次运行引导（LLM endpoint/API key 配置步骤）。
2. 概念通俗化：CTF、四投影、雾探索（fog）、正交状态（gen/review）各用一句人话解释，降低新用户认知门槛。
3. 验收：新用户照文档 10 分钟内完成首次拖入项目并理解四投影含义。

## 边界（禁止事项）

- 不改 `.pas` 业务逻辑之外的无关代码；CLI 头部注释属文档性改动，允许。
- 不删除历史讨论文档，只加映射标注。
- 不新增与代码重复的信息源。

## 交付物

T1–T3 代码/文档 + `WO\evidence\` 证据 + `WO\AUDIT-REQUEST-WO-20260829-001.md` 复审请求。主控复核通过后方可 CLOSE。
