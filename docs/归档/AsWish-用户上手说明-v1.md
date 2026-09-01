# AsWish 用户上手说明

## 一句话定位

AsWish 让你与 AI Agent 在开发前看见并确认同一个软件应该是什么；开发后验证做出来的是否还是那个东西。它把项目材料转成可追溯、可审阅、可决策的四投影规格，供人和 AI 共同使用。

产品身份与核心研究问题见 [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md)；协议字段和状态以 [`../SPEC.md`](../SPEC.md) 为准；本文只保留首次使用所需的操作路径。

## 桌面端首次运行

1. 启动 `bin\AsWish.exe`。界面会按系统语言选择 `zh-CN`、`zh-TW` 或 `en-US`。
2. 打开 **Tools → Setup LLM (ModelScope)**，输入 API Key 和模型名。默认模型是 `Qwen/Qwen2.5-72B-Instruct`，默认 OpenAI-compatible endpoint 是 `https://api-inference.modelscope.cn/v1`。API Key 只保存到本机受保护配置，不要写入项目文件或提交到仓库。
3. 在目录面板选择项目，点击 **Visualize**。AsWish 会扫描材料、生成 `.AsWish/` 事实文件，并打开 HTML 审阅界面。
4. 依次查看四个投影页面；优先处理低置信度、`foggy`/`unknown_unknowns` 和 `unreviewed` 节点，并沿来源引用回到原文件。
5. 在界面中确认或拒绝候选项。决策写入 `.AsWish/decisions/`；完成后执行 **Promote Pending Decisions**，再重新渲染检查结果。
6. 使用 **Export Prompt** 生成给原 AI/IDE 的上下文。保留 `.AsWish/` 和 HTML 产物，作为下一轮开发的共同基线。

## 四投影怎么用

| 投影 | 主要回答的问题 | 首次查看重点 |
|---|---|---|
| `function-tree` | 系统应该做什么？ | 能力、需求、规则和未澄清目标 |
| `module-tree` | 行为由哪里承载？ | 单元、组件、命名空间和责任边界 |
| `view-tree` | 用户看见并操作什么？ | 窗体、页面、控件和交互路径 |
| `data-tree` | 数据是什么、如何持久化和迁移？ | 实体、字段、关系、状态、约束和迁移 |

四个投影是同一份规格的不同观察面，不是四套互相独立的需求。`risk_score` 是节点属性或派生视图，不是第五个投影。

## CTF 的四个操作概念

- **CTF**：先把材料整理成可追溯事实，再让 AI 生成候选规格。
- **四投影**：分别审阅行为、结构、界面和数据，并通过来源与关系交叉核对。
- **Fog 探索**：`foggy` 与 `unknown_unknowns` 表示仍需探索的需求端点；一次只推进一个明确问题。
- **正交状态**：`gen_status` 表示生成进度，`review_status` 表示人类审阅结果，二者不能互相替代。

## 无界面路径

在没有 Delphi 运行环境的机器上，可先用标准库初始化协议工作区：

```bash
python protocol/tools/init_workspace.py /path/to/project --project-name "MyProject"
```

构建 CLI 后，常用流程是：

```bat
AsWish.CLI init <dir>
AsWish.CLI scan <dir>
AsWish.CLI validate <dir>
AsWish.CLI render <dir>
AsWish.CLI health <dir> --json
AsWish.CLI ingest <dir> <candidate.yaml>
```

`scan` 会生成四投影和 HTML；`validate` 只报告协议问题；`ingest` 会校验候选 YAML，再按节点 ID 合并，保留已有的人类审阅状态。CLI 的完整参数以 [`../cli/AsWish.CLI.dpr`](../cli/AsWish.CLI.dpr) 顶部说明和 `README.md` 为准。

## 继续阅读

- 协议基线：[`../SPEC.md`](../SPEC.md)
- CTF 方法：[`CTF.md`](CTF.md)
- 当前文档入口：[`AsWish-当前文档索引-v1.md`](AsWish-当前文档索引-v1.md)
