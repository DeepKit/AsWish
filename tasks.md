# DeepSpec 开发任务清单

> 基线：Delphi 13.1 / DeepBase / DeepShell / VCL / Win64
> 方法论：CTF（建构·追溯·可谬法）→ `docs/CTF.md`
> 协议：DeepSpec 四投影协议 v1.2-draft（data-tree 已就绪）
> 当前 HEAD：`2a799fe`（data-tree 全链路 + 编译错误修复，已编译通过）
> 历史任务归档：`history.md`

---

## Phase 1: Data-Tree 全链路 ✅（已完成）

DT-1~6 全部完成，详见 `history.md`。

---

## Phase 2: 正交状态 + 单元测试（当前）

### C-P0：节点正交状态维度
- [ ] TSpecNode 增加 `GenStatus: TGenStatus` 字段（draft / generated / confirmed / skipped）
- [ ] TSpecNode 增加 `ReviewStatus: TReviewStatus` 字段（unreviewed / accepted / rejected / deferred）
- [ ] `TSpecEnums` 增加序列化/反序列化方法
- [ ] 旧 `Status: TNodeStatus` 映射逻辑：gen_status + review_status 组合兼容旧 status
- [ ] YAML Writer 输出新字段（gen_status, review_status），旧 status 保留用于向后兼容
- [ ] YAML Parser 读取新字段，回填旧 status
- [ ] Render HTML 展示双状态徽章
- [ ] 编译验证
- 关联公理：A4（正交性）

### A-P0：YAML Parser 单元测试
- [ ] 创建 `tests/Test.DeepSpec.Yaml.Parser.pas`（DUnitX）
- [ ] 测试用例：解析空树 / 单节点 / 嵌套子节点 / data-tree 专属字段 / 旧格式兼容
- [ ] 边界：非法 YAML / 缺失字段 / 未知字段忽略
- [ ] 编译并通过测试
- 关联公理：A2, A7

### A-P0：Validation 单元测试
- [ ] 创建 `tests/Test.DeepSpec.Validation.pas`（DUnitX）
- [ ] INV-1: ID 格式校验（前缀匹配树类型）
- [ ] INV-2: parent_id 引用存在性
- [ ] INV-3: Kind 受控词表校验
- [ ] INV-4: 状态迁移合法性
- [ ] INV-5: 循环依赖检测
- [ ] INV-6: content_hash 一致性
- [ ] 编译并通过测试
- 关联公理：A2, A7

---

## Phase 3: 认知干预

### D-P0：问题优先呈现
- [ ] Render 新增 `problems.html`：扫描结果先展示问题列表
- [ ] 问题类型：源文件提及但节点缺失 / 无证据 / 跨树不一致 / 低置信度
- [ ] index.html 导航增加 "Problems" 链接
- [ ] 编译验证
- 关联公理：A6

### D-P0：信任信号体系
- [ ] 节点卡片展示：证据源状态 / LLM 推理链 / 跨树一致性 / 冲突检测 / 人工决策历史
- [ ] 信任信号折叠式展示（默认收起，点击展开）
- [ ] 编译验证
- 关联公理：A2

---

## Phase 4: 上下文管线 + 语义束

### A-P1：上下文组装管线
- [ ] 可插拔上下文源接口
- [ ] token 预算动态裁剪
- [ ] 编译验证
- 关联公理：A5

### C-P1：语义束
- [ ] Models 增加 `TSemanticBundle` 记录
- [ ] 跨树一致性校验：同一 bundle 下节点状态冲突检测
- [ ] YAML 读写 bundles.yaml
- [ ] 按束审阅 UI
- [ ] 编译验证
- 关联公理：A1

### C-P1：决策写回状态机
- [ ] Delphi 实现 GenStatus + ReviewStatus 状态迁移验证
- [ ] 非法迁移拒绝 + 错误提示
- [ ] 编译验证
- 关联公理：A3, A4

---

## Phase 5: CLI + Tool Protocol

### B-P0：CLI-first 集成路径
- [ ] 拆分 DeepSpec.Core（库）+ DeepSpec.CLI（Console）+ DeepSpec.Desktop（VCL）
- [ ] 命令：`deepspec init / scan / generate / validate / render`
- [ ] 编译验证
- 关联公理：A5

### B-P1：DeepSpec Tool Protocol / MCP Server
- [ ] deepspec_read / deepspec_validate / deepspec_query / deepspec_update
- [ ] MCP Server 供 Claude / Cursor 调用
- 关联公理：A5

### B-P1：.deepspec/ 自动生成 CLAUDE.md
- [ ] init/scan 时生成 CLAUDE.md 提示 AI agent 参考 .deepspec/

---

## Phase 6: 加固与扩展

### D-P1：Accept 加摩擦 / Reject 减摩擦
- [ ] Accept 增加理由选择，区分"低置信度接受"
- 关联公理：A6

### D-P2：审阅节律 + 项目健康度仪表盘
- [ ] review_overdue 标记 + 仪表盘展示审阅积压
- [ ] 健康度指标：覆盖率 / 置信度 / 决策积压 / 新鲜度
- 关联公理：A2, A3, A6, A7

### C-P2：Kind 受控词表
- [ ] x_ 扩展前缀校验在 Validation 中实现
- 关联公理：A4

### A-P1：快照与回滚
- [ ] `.deepspec/snapshots/` + Generate 前自动快照
- 关联公理：A3, A7

### A-P1：部分成功模式
- [ ] 每棵树独立 gen_status / 错误信息
- 关联公理：A7

---

## 待做：Scan 增强

### DT-6：Scan 注册 data-tree 文件类型
- [ ] 识别 `.sql`, `.prisma`, `.migration.*` 数据模型文件
- [ ] Delphi: 识别 DataModule（.dfm + .pas 组合）
- [ ] 编译验证

---

## 待做：协议 conformance

### CF-1：data-tree conformance fixtures
- [ ] `valid-with-data-tree` fixture：含 data-tree.yaml 的完整 .deepspec
- [ ] 验证 data-tree 节点 kind 枚举、ID 前缀、data 专属字段

### CF-2：bundle + review-decision fixtures
- [ ] `valid-with-bundles` fixture：含 bundles.yaml
- [ ] `valid-with-review-decisions` fixture：含 review-decisions.yaml

---

## 推荐实施顺序

```
Phase 2 ← 当前：C-P0 正交状态 + A-P0 单元测试
Phase 3：D-P0 问题优先 + D-P0 信任信号
Phase 4：A-P1 上下文管线 + C-P1 语义束
Phase 5：B-P0 CLI + B-P1 Tool Protocol
Phase 6：其余 D/C/B/A P1/P2 按反馈推进
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
