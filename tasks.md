# DeepSpec 开发任务清单

> 基线：Delphi 13.1 / DeepBase / DeepShell / VCL / Win64
> 方法论：CTF（建构·追溯·可谬法）→ `docs/CTF.md`
> 协议：DeepSpec 四投影协议 v1.2-draft（实现仍兼容 v1.1 三树）
> 状态：HEAD `5b7a2e6` 包含完整 P0-P5 基线 + 协议包 + 文档

---

## 2026-05-20 文档与协议校正 ✅

- [x] 在 `D:\_Progs\02Business\DeepSpec` 初始化独立 Git 仓库
- [x] 新增根目录 `README.md` 和 `SPEC.md`
- [x] 新增 `docs/CTF.md`
- [x] 修复 `protocol/schemas/*.json` JSON 语法错误
- [x] 明确 v1.2-draft 四投影：function/module/view/data
- [x] 明确 `data-tree` 是第四树，`risk_score` 是字段
- [x] 明确 `execution_status` 不属于 CTF/DeepSpec
- [x] 明确新协议优先 `gen_status + review_status`，旧 `status` 兼容

---

## 2026-05-20 编译错误修复 ✅

- [x] Models.pas: `RiskLevelToStr` 加 `class` 关键字
- [x] Models.pas: `DataKindFromStr` 缺 `=` 号
- [x] Models.pas: `RiskLevelToStr` 缺 `:` 冒号
- [x] Writer.pas: `WriteBoolKV` 的 `if then` 改为 `IfThen()`
- [x] Writer.pas: `WriteQuotedKVtarget_entity` 引号和括号修复
- [x] Writer.pas: `A.Cardinality` 改为 `ANode.Cardinality`
- [x] Writer.pas: uses 增加 `System.StrUtils`

---

## 全部 P0-P5 主要功能 ✅

### P0：DeepShell 壳接入 ✅
### P1：项目扫描和 .deepspec 落地 ✅
### P2：三棵树 + 数据模型 + LLM ✅
### P3：HTML 决策写回 + 提示词导出 ✅
### P4：Delphi/VCL 增强 ✅
### P5：质量加固 + JS Bridge ✅

（详细内容见 git log `5b7a2e6`）

---

## 当前工作：Delphi 实现迁移到 data-tree（v1.2-draft）

> 协议层已完成（schema + seed data-tree.yaml），Delphi 数据模型和 YAML 读写已就绪。
> 需要让 TreeBuilder、Controller、Render、Commands 全链路支持第四棵树。

### DT-1：TreeBuilder 生成 data-tree 节点
- [ ] TreeBuilder 增加 `FDataNodes: TList<TSpecNode>`
- [ ] `BuildFromScan` 中扫描数据库/模型文件（.sql, .prisma, .migration, Delphi data module）生成 entity/field 节点
- [ ] 对已扫描的 Delphi .pas 文件提取 published 字段推断 data entity
- [ ] 暴露 `property DataNodes`

### DT-2：Controller 集成 data-tree
- [ ] Controller 增加 `FDataNodes` 字段
- [ ] `BuildTrees` 后收集 TreeBuilder.DataNodes
- [ ] `RefreshFromYaml` 支持读 `data-tree.yaml`
- [ ] Store 写入时输出 `data-tree.yaml`

### DT-3：Render 渲染 data-tree HTML
- [ ] Render 生成 `data-tree.html`
- [ ] data-tree 节点卡片展示：kind badge + data_type + risk_score + persistence + valid_states
- [ ] index.html 导航增加 "Data Tree" 链接
- [ ] 语义束视图：同一 bundle 下四棵树节点联动

### DT-4：Commands 注册 data-tree 命令
- [ ] `deepspec.data.render` 渲染 data-tree HTML
- [ ] `deepspec.validate` 覆盖 data-tree 不变量（ID 前缀 `data-`）

### DT-5：SpecStore 写入 data-tree
- [ ] `SaveProject` 时写入 `trees/data-tree.yaml`
- [ ] `project-spec.yaml` 的 `trees.data_tree` 字段填充

### DT-6：Scan 注册 data-tree 文件类型
- [ ] 识别 `.sql`, `.prisma`, `.migration.*`, 数据模型文件
- [ ] Delphi: 识别 DataModule（.dfm + .pas）

---

## 协议 conformance 扩展

### CF-1：data-tree conformance fixtures
- [ ] `valid-with-data-tree` fixture：含 data-tree.yaml 的完整 .deepspec
- [ ] 验证 data-tree 节点 kind 枚举、ID 前缀、data 专属字段

### CF-2：bundle + review-decision fixtures
- [ ] `valid-with-bundles` fixture：含 bundles.yaml
- [ ] `valid-with-review-decisions` fixture：含 review-decisions.yaml

---

## CLI-first 路径

### CLI-1：DeepSpec Core 分离
- [ ] 拆分为 DeepSpec.Core（库）+ DeepSpec.CLI（Console）+ DeepSpec.Desktop（VCL）
- [ ] 命令：`deepspec init / scan / generate / validate / render`

---

## CTF 方法论优化任务（按四层模型分类）

### Layer D：认知干预层

#### D-P0：问题优先呈现
- [ ] 审阅首页先展示问题列表，后展示四棵树
- [ ] 问题类型：源文件提及但节点缺失、无证据、跨树不一致、低置信度
- [ ] 关联公理：A6

#### D-P0：信任信号体系
- [ ] 节点卡片展示：证据源状态 / LLM 推理链 / 跨树一致性 / 冲突检测 / 人工决策历史
- [ ] 关联公理：A2

#### D-P1：Accept 加摩擦 / Reject 减摩擦
- [ ] Accept 增加理由选择，区分"低置信度接受"
- [ ] 关联公理：A6

#### D-P2：审阅节律 + 项目健康度仪表盘
- [ ] review_overdue 标记 + 仪表盘展示审阅积压
- [ ] 健康度：覆盖率 / 置信度 / 决策积压 / 新鲜度 / AI 偏差 / Token 消耗
- [ ] 关联公理：A2, A3, A6, A7

#### D-P3：决策日志
- [ ] decision-journal.yaml 记录 reasoning_type / confidence_self
- [ ] accept:reject 比率异常警告
- [ ] 关联公理：A2, A3

### Layer C：正确性保证层

#### C-P0：协议不变量声明 ✅（已提交 `protocol/invariants.md`）
- [ ] 对应 Delphi 单元测试

#### C-P0：节点正交状态维度
- [ ] TSpecNode 增加 `GenStatus` / `ReviewStatus` 字段
- [ ] 旧 `Status` 映射到 gen_status + review_status
- [ ] YAML 读写兼容新旧格式
- [ ] 关联公理：A4

#### C-P1：语义束
- [ ] `bundle.schema.json` 已提交
- [ ] Delphi 实现 SemanticBundle 记录 + 跨树一致性校验
- [ ] 按束审阅 UI
- [ ] 关联公理：A1

#### C-P1：决策写回状态机
- [ ] `state-machine.md` 已提交
- [ ] Delphi 实现状态迁移验证
- [ ] 关联公理：A3, A4

#### C-P2：Kind 受控词表
- [ ] `controlled-vocab.md` 已提交
- [ ] x_ 扩展前缀校验在 Validation 中实现
- [ ] 关联公理：A4

#### C-P2：错误分类与恢复策略
- [ ] 创建 `protocol/errors.md`
- [ ] 关联公理：A3, A7

### Layer B：生态集成层

#### B-P0：CLI-first 集成路径（同 CLI-1）

#### B-P1：DeepSpec Tool Protocol / MCP Server
- [ ] deepspec_read / deepspec_validate / deepspec_query / deepspec_update
- [ ] MCP Server 供 Claude / Cursor 调用
- [ ] 关联公理：A5

#### B-P1：.deepspec/ 自动生成 CLAUDE.md
- [ ] init/scan 时生成 CLAUDE.md 提示 AI agent 参考 .deepspec/

#### B-P1：GOVERNANCE.md 补兼容性承诺
- [ ] 向后兼容 + 弃用策略 + x_ 扩展命名空间 + local.yaml 约定

### Layer A：工程实现层

#### A-P0：单元测试
- [ ] YAML Parser DUnitX 测试
- [ ] Validation DUnitX 测试（INV-1~INV-6）
- [ ] 关联公理：A2, A7

#### A-P1：上下文组装管线
- [ ] 可插拔上下文源 + token 预算动态裁剪
- [ ] 关联公理：A5

#### A-P1：部分成功模式
- [ ] 每棵树独立 gen_status / 错误信息
- [ ] 关联公理：A7

#### A-P1：快照与回滚
- [ ] `.deepspec/snapshots/` + Generate 前自动快照
- [ ] 关联公理：A3, A7

#### A-P1：workflow.yaml 外置配置
- [ ] 外置 prompt 模板 / 扫描忽略 / LLM 端点
- [ ] 关联公理：A5

---

## 推荐实施顺序

```
Phase 1（当前）：DT-1~6 → Delphi 全链路支持 data-tree
Phase 2：C-P0 正交状态 + A-P0 单元测试
Phase 3：D-P0 问题优先 + D-P0 信任信号
Phase 4：A-P1 上下文管线 + C-P1 语义束
Phase 5：B-P0 CLI + B-P1 Tool Protocol
Phase 6：其余 D/C/B/A P2/P3 按反馈推进
```

---

## 代码统计

| 模块 | 单元数 |
|------|--------|
| app/ | 4 |
| services/ | 9 |
| providers/ | 3 |
| controllers/ | 1 |
| models/ | 1 |
| core/ | 7 |
| **DeepSpec 单元总数** | **25** |

---

## 无法在 AI 会话独立完成的剩余工作

| 项 | 原因 | 谁来做 |
|----|------|--------|
| WebView2 Runtime 未安装时的体验 | 依赖运行环境 | 用户验证 |
| LLM 实际调用稳定性 | 依赖网络/模型 | 联调测试 |
| 跨平台测试 | Win64 only | 后续移植 |
| 真实项目封版验证 | 需要时间和样本 | P6 阶段 |
