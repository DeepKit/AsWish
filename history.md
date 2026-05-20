# DeepSpec 开发历史

> 已完成的任务归档于此。按时间倒序排列。

---

## 2026-05-20 Data-Tree 全链路实现 (commit `2a799fe`)

### DT-1：TreeBuilder 生成 data-tree 节点
- [x] TreeBuilder 增加 `FDataNodes: TList<TSpecNode>`
- [x] 新增 `BuildDataTreeFromDelphi` 方法：从 .pas 文件 published 段提取字段声明
- [x] 为每个 class 生成 entity 节点 + field 子节点（含 data_type）
- [x] 去重：`LEntitySlugs` 防止同名类重复
- [x] 暴露 `property DataNodes`
- [x] 编译通过：dcc64 零错误

### DT-2：Controller 集成 data-tree
- [x] `RenderAll` 增加 data-tree 渲染（有节点时）
- [x] `RefreshFromYaml` 读取 `data-tree.yaml` 并渲染
- [x] `RunScan` 写入 `data-tree.yaml` 后渲染
- [x] 日志消息增加 data 节点计数

### DT-3：Render 渲染 data-tree HTML
- [x] `index.html` 导航增加 "Data Tree" 链接
- [x] RenderNode 展示 data-tree 专属字段：data_type / risk_score / persistence 徽章
- [x] 新增 CSS 样式：badge-data-type / badge-risk-* / badge-persistence

### DT-4：Commands 注册 data-tree 命令
- [x] `deepspec.data.render` 命令注册

### DT-5：SpecStore 写入 data-tree
- [x] `WriteProjectSpec` 写入 `trees/data-tree.yaml`
- [x] `WriteEmptyTrees` 生成空 `data-tree.yaml`
- [x] `project-spec.yaml` 填充 `data_tree` 字段

---

## 2026-05-20 编译错误修复 (commit `2a799fe`)

### BUG-COMPILER-001：Models.pas 三处语法错误
- [x] `RiskLevelToStr` 缺 `class` 关键字
- [x] `DataKindFromStr` 缺 `=` 号（`'state'` 条件无法编译）
- [x] `RiskLevelToStr` 缺 `:` 冒号（`rlCritical` 分支）

### BUG-COMPILER-002：Writer.pas 四处语法错误
- [x] `WriteBoolKV` 使用了非法的 `if ... then` 表达式语法，改为 `IfThen()`
- [x] `WriteQuotedKVtarget_entity` 缺少左引号和左括号
- [x] `A.Cardinality` 应为 `ANode.Cardinality`
- [x] uses 缺少 `System.StrUtils`（`IfThen` 所在单元）

---

## 2026-05-20 文档与协议校正 (commit `5b7a2e6`)

- [x] 在 `D:\_Progs\02Business\DeepSpec` 初始化独立 Git 仓库
- [x] 新增根目录 `README.md` 和 `SPEC.md`
- [x] 新增 `docs/CTF.md`
- [x] 修复 `protocol/schemas/*.json` JSON 语法错误
- [x] 明确 v1.2-draft 四投影：function/module/view/data
- [x] 明确 `data-tree` 是第四树，`risk_score` 是字段
- [x] 明确 `execution_status` 不属于 CTF/DeepSpec
- [x] 明确新协议优先 `gen_status + review_status`，旧 `status` 兼容

---

## 2026-05-19 P0-P5 基线完成 (commit `1dc6451`)

### P0：DeepShell 壳接入
- [x] DeepSpec.dpr + MainForm 注册到 DeepShell
- [x] 命令面板注册所有命令

### P1：项目扫描和 .deepspec 落地
- [x] ScanService 扫描项目目录，分类文件（code/ui/config/doc/data）
- [x] ProjectService 管理 .deepspec/ 目录结构

### P2：三棵树 + 数据模型 + LLM
- [x] Models 定义 TSpecNode / TSpecEvidence / TSpecDecision
- [x] TreeBuilder 从扫描结果构建 function/module/view 树
- [x] SpecStore YAML 读写
- [x] LLM 服务集成（ModelScope/Qwen）

### P3：HTML 决策写回 + 提示词导出
- [x] RenderService 生成树形 HTML
- [x] JS Bridge：Confirm/Reject 按钮通过 WebView2 postMessage 写回
- [x] PromptsService 导出 context-pack / system-prompt

### P4：Delphi/VCL 增强
- [x] DFM Parser 提取表单控件结构
- [x] PAS Parser 提取类/接口声明
- [x] Delphi 增强：module tree 补充 unit/class 层级，view tree 补充 DFM 控件

### P5：质量加固 + JS Bridge
- [x] 决策服务：PromotePendingDecisions
- [x] Validation 框架
- [x] Hash 内容/关系哈希
- [x] 协议文件：schemas + invariants + state-machine + controlled-vocab
