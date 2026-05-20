# DeepSpec 开发任务清单

> 基线：Delphi 13.1 / DeepBase / DeepShell / VCL / Win64
> 方法论：CTF（建构·追溯·可谬法）→ `docs/DeepSpec-CTF方法论-v1.md`
> 协议：DeepSpec 四投影协议 v1.2-draft（实现仍兼容 v1.1 三树）
> 状态：Delphi 桌面实现已有可编译基线；公开协议正在按 v1.2-draft 稳定。

---

## 2026-05-20 文档与协议校正

- [x] 在 `D:\_Progs\02Business\DeepSpec` 初始化独立 Git 仓库。
- [x] 新增根目录 `README.md` 和 `SPEC.md` 作为对外入口。
- [x] 新增 `docs/CTF.md` 作为 CTF 工程解释入口。
- [x] 修复 `protocol/schemas/*.json` 中已发现的 JSON 语法错误。
- [x] 明确 v1.2-draft 采用四投影：function/module/view/data。
- [x] 明确 `data-tree` 是第四树，`risk_score` 是字段或派生视图。
- [x] 明确 `execution_status` 不属于 CTF/DeepSpec。
- [x] 明确新协议优先使用 `gen_status + review_status`，旧 `status` 只做兼容。
- [ ] Delphi 实现迁移到 `data-tree` 和正交状态。
- [ ] conformance 增加 data-tree、bundle、review-decision 覆盖。
- [ ] CLI-first 命令落地：`deepspec init/scan/validate/render`。

---

## 全部 P0-P5 主要功能 ✅

### P0：DeepShell 壳接入 ✅
- [x] DeepSpec.dpr / .dproj
- [x] TDeepSpecMainForm（继承 TDeepMainForm）
- [x] 6 个命令注册（Open/Scan/Generate/Render/Export/SetupLLM）
- [x] 3 个 Provider 注册（Structure/MainView/Inspector）

### P1：项目扫描和 .deepspec 落地 ✅
- [x] 项目打开（SelectDirectory）
- [x] 文件扫描引擎（递归 + 分类 + 忽略规则，按协议 §14.1）
- [x] .deepspec 目录生成（含 .gitignore）
- [x] HTML 渲染（scan-report + index）

### P2：三棵树 + 数据模型 + LLM ✅
- [x] 完整数据模型（Node/Relation/Evidence/Issue/Decision + 12 种 enum）
- [x] YAML 写入器（覆盖协议全部 Schema）
- [x] YAML 解析器（block-style mapping/sequence/scalar）
- [x] 三棵树 HTML 渲染（带 status/confidence/source_layer 徽章）
- [x] TreeBuilder（无 LLM 也能生成基础三树）
- [x] Context Pack + 4 种 Prompt 模板
- [x] DeepBase LLM facade 封装（TDeepSpecLLMService）
- [x] **真实 LLM 调用**（异步线程 + 候选 B 写入 llm/candidate-output.yaml）
- [x] **LLM 配置工具**（ModelScope OpenAI 兼容端点）
- [x] Schema 校验器（节点 ID、kind、status 校验 + LLM 安全规则）

### P3：HTML 决策写回 + 提示词导出 ✅
- [x] 4 种 Prompt 输出（context-pack / generation / node / decision-rewrite）
- [x] Decision 服务（Load/Save/Accept/Reject/AcceptDecision）
- [x] content_hash 并发控制（SHA-256，分语义/装饰两层）
- [x] file SHA-256（用于 evidence source_file_hash）
- [x] **WebView2 集成**（TEdgeBrowser 内嵌 HTML 审阅）

### P4：Delphi/VCL 增强 ✅
- [x] Delphi 文件识别
- [x] DFM 解析器（text format，binary 检测不崩溃）
- [x] PAS 解析器（unit/class/interface/uses 提取）
- [x] TreeBuilder 集成 Delphi 解析器（自动生成更丰富的模块/视图树）

### P5：质量加固 + JS Bridge ✅
- [x] **0 自身 warning**（清理 W1009/W1029/W1057/H2219）
- [x] **YAML 解析器边界加固**：
  - 代码围栏 ` ```yaml ... ``` ` 自动剥离
  - UTF-8 BOM 容忍
  - `---` 文档分隔符容忍
  - Tab 自动转换为空格
  - 行尾 `# 注释` 处理（quote-aware）
  - 块字面量 `|` 与折叠 `>` 多行 scalar
  - Flow 序列 `[a, b, c]` 解析
- [x] **JS Bridge 决策回写**（HTML → DeepShell）：
  - HTML 候选节点旁渲染 Confirm/Reject 按钮
  - 按钮通过 `window.chrome.webview.postMessage` 投递
  - WebView2 `OnWebMessageReceived` 解析 JSON
  - 追加写入 `.deepspec/decisions/pending-decisions.yaml`
  - 普通浏览器中显示 fallback 提示
- [x] **Promote Pending Decisions**：
  - `TDeepSpecDecisionsService.PromotePending` 把 pending 条目转换为正式 decision
  - 命令 `deepspec.decisions.promote` 暴露给菜单
  - `node-confirm` → `dtConfirm` + accepted；`node-reject` → `dtReject` + rejected
- [x] **Render HTML 命令** (`deepspec.html.render`)：脱离扫描重渲染所有 HTML
- [x] **YAML 端到端往返**：
  - `TSpecEnums` 增补 `TreeTypeFromStr` / `NodeStatusFromStr` / `ConfidenceFromStr` / `SourceLayerFromStr`
  - `TDeepSpecStoreService.ReadTreeFile` 读 YAML 还原 `TList<TSpecNode>`
  - `Controller.RefreshFromYaml` + 命令 `deepspec.html.refresh-from-yaml`：
    手改 YAML 后无需 rescan 即可刷新 HTML，端到端验证 Writer ↔ Parser 闭环

---

## 协议包独立交付 ✅

`DeepSpec/protocol/`:
- 7 个 JSON Schema 形式化定义
- 4 个种子项目（React/Go/Python/Docs-only）
- TypeScript / Python 参考 reader
- 兼容性测试套件（fixtures + run.py）
- 10 分钟集成指南 + Reader Profile
- GOVERNANCE.md
- Apache-2.0 LICENSE

---

## 使用流程（端到端）

1. 启动 `bin\Win64\Debug\DeepSpec.exe`
2. 菜单 **Tools → Setup LLM (ModelScope)**：粘贴 API Key 和模型名（如 `Qwen/Qwen2.5-72B-Instruct`）
3. 菜单 **File → Open Project**：选择项目文件夹
4. 自动扫描 → 生成 `.deepspec/` → 写 YAML → 渲染 HTML 到 WebView2
5. 菜单 **Run → Generate B**：调用 LLM 生成候选 B（`.deepspec/llm/candidate-output.yaml`）
6. 菜单 **Tools → Export Prompt**：导出 Context Pack + 生成提示词
7. 在 WebView2 内点 **Confirm/Reject** → 写入 `pending-decisions.yaml`
8. 菜单 **Tools → Promote Pending Decisions**：把 pending 条目转换为正式 decision
9. 菜单 **View → Render HTML**：脱离扫描重渲染（用于手动编辑 YAML 后刷新）
10. 菜单 **View → Refresh HTML from YAML**：从硬盘 YAML 重新解析三树并渲染（端到端往返）

---

## 代码统计

| 模块 | 单元数 |
|------|------|
| app/ | 4 |
| services/ | 9 (Project/Scan/SpecStore/Render/TreeBuilder/Prompts/Decisions/LLM/LLMConfig) |
| providers/ | 3 (Structure/MainView/Inspector) |
| controllers/ | 1 |
| models/ | 1 |
| core/ | 7 (Yaml.Writer/Yaml.Parser/Hash/Delphi.DfmParser/Delphi.PasParser/Validation) |
| **DeepSpec 单元总数** | **25** |

编译总行数（含 DeepBase）：26597 行
EXE：8.1 MB（Debug Win64）
0 编译错误

---

## 无法在 AI 会话独立完成的剩余工作

| 项 | 原因 | 谁来做 |
|----|------|------|
| WebView2 Runtime 未安装时的体验 | 依赖运行环境 | 用户验证 / 安装 Runtime |
| LLM 实际调用稳定性 | 依赖网络、API 配额、模型行为 | 联调测试 |
| 跨平台测试 | Win64 only | 后续移植 |
| 5 个真实项目封版验证 | 需要时间和真实样本 | P6 阶段 |

---

## 下一步建议

1. 在 IDE 或命令行运行 `bin\Win64\Debug\DeepSpec.exe`
2. **Setup LLM** → 输入 ModelScope API Key
3. **Open Project** → 选择 `D:\_Progs\02Business\DeepSpec` 自身做测试
4. 检查 `.deepspec/` 目录生成
5. **Generate B** → 看看 LLM 输出
6. WebView2 应该自动加载 `.deepspec/html/index.html`

---

# CTF 方法论优化任务清单

> 以下任务源自基于 OpenAI Symphony 的五轮专家讨论，按 CTF 四层模型分类。
> 方法论文档：`docs/DeepSpec-CTF方法论-v1.md`
> 每个任务标注所属层级（D/C/B/A）、优先级（P0-P3）、关联公理（A1-A7）。

---

## Layer D：认知干预层（增强人类判断力）

### D-P0：问题优先呈现
- [ ] 审阅首页默认不展示三棵树，先展示系统检测到的问题列表
- [ ] 问题类型：源文件提及但节点缺失、节点无证据、跨树不一致、置信度低于阈值
- [ ] 用户点击“进入完整审阅”后才展示三棵树
- [ ] 关联公理：A6

### D-P0：信任信号体系
- [ ] 每个节点审阅卡片展示五项信任信号：
  - 证据源状态（✅ / ⚠️ / ❌）
  - LLM 推理链条（可展开）
  - 跨树一致性（同一语义束内其他树状态）
  - 冲突检测（与人工决策或其他节点的矛盾）
  - 人工决策历史（此节点的 accept/reject 记录）
- [ ] 缺失证据用 ⚠️ 标记，不隐藏
- [ ] 关联公理：A2

### D-P1：Accept 加摩擦 / Reject 减摩擦
- [ ] Accept 按钮增加理由选择："我验证了源文件" / "和我的理解一致" / "看起来合理，先接受"
- [ ] 第三个选项标记为"低置信度接受"，在仪表盘中区分
- [ ] Reject 按钮保持一键，可选填理由
- [ ] 系统自动记录被拒绝的节点，下次生成时避免类似内容
- [ ] 关联公理：A6

### D-P2：审阅节律
- [ ] project-spec.yaml 增加 review_overdue 标记（生成完成但未审阅超过 24 小时）
- [ ] HTML 仪表盘展示“N 个节点等待审阅（已 X 天）”
- [ ] 源文件变更影响已审阅节点时标记 affected_accepted_nodes
- [ ] 新的 LLM 生成覆盖人工决策时标记 decision_conflict
- [ ] 关联公理：A3、A6

### D-P2：项目健康度仪表盘
- [ ] 设计并渲染健康度数据卡片：
  - 覆盖率（已追溯源文件 / 总源文件）
  - 置信度（平均 + 最低）
  - 决策积压（待审阅节点数）
  - 规格新鲜度（上次生成时间 + 源文件变更数）
  - AI 偏差检测（疑似理解偏差数）
  - Token 消耗（累计 input / output）
- [ ] 数据来源全部为 `.deepspec/` 目录本身，不需要额外数据库
- [ ] 关联公理：A2、A7

### D-P3：决策日志
- [ ] 在 `.deepspec/decisions/` 下增加 `decision-journal.yaml`
- [ ] 每次 Accept/Reject 记录 reasoning_type、confidence_self、time_spent_seconds
- [ ] 元数据记录 accept_count / reject_count / skip_count / avg_confidence
- [ ] 监控指标：accept:reject 比率异常时发出确认偏差警告
- [ ] 关联公理：A2、A3

---

## Layer C：正确性保证层（系统状态完备性）

### C-P0：协议不变量声明
- [ ] 创建 `protocol/invariants.md`，声明所有良构性不变量：
  - INV-1：节点 ID 在单棵树内唯一
  - INV-2：parent_id 必须指向同树内已存在节点或 null
  - INV-3：relation 的 source/target 必须指向已存在节点
  - INV-4：status 迁移遵守有限状态机
  - INV-5：accepted 节点必须有至少一条 evidence
  - INV-6：content_hash 变更时 gen_status 必须降级为 draft
- [ ] 每个不变量有对应的测试用例
- [ ] 关联公理：A2、A3、A4

### C-P0：节点正交状态维度
- [ ] 将现有 `status` 字段拆分为 `gen_status` 和 `review_status` 两个独立字段
- [ ] gen_status: pending | generated | failed
- [ ] review_status: pending | accepted | rejected | locked
- [ ] 更新 tree.schema.json
- [ ] 更新 TSpecEnums 和所有相关服务
- [ ] 关联公理：A4

### C-P1：语义束（Semantic Bundle）
- [ ] 创建 `protocol/schemas/bundle.schema.json`
- [ ] 定义 bundle 结构：id、label、anchors（跨树节点引用）、confidence、completeness
- [ ] 实现跨树一致性校验：如果功能有 function + module 节点但缺 view 节点，标记“可能遗漏”
- [ ] 支持按束审阅（一次看到同一需求在三棵树中的所有投影）
- [ ] 关联公理：A1

### C-P1：决策写回状态机
- [ ] 绘制完整的节点状态迁移图（gen_status × review_status 的所有合法迁移）
- [ ] 迁移定义：不存在→draft（LLM generate）、draft→accepted（human）、draft→rejected（human）、accepted→draft（content_hash change）、rejected→draft（LLM regenerate, different content）
- [ ] 增加 `locked` 状态：人工锁定节点不受 LLM 重新生成影响
- [ ] 创建 `protocol/state-machine.md`
- [ ] 关联公理：A3、A4

### C-P2：Kind 受控词表
- [ ] 创建 `protocol/controlled-vocab.md`
- [ ] 定义每棵树的合法 kind 值集合
- [ ] 不在词表中的 kind 值用 `x_` 前缀
- [ ] 更新 tree.schema.json 中的 kind 枚举定义
- [ ] 关联公理：A4

### C-P2：错误分类与恢复策略
- [ ] 创建 `protocol/errors.md`
- [ ] 定义所有操作的失败分类和恢复行为：
  - YAML 解析失败 → 自动修复（剥 BOM / code fence）→ 重试
  - Schema 校验失败 → 标记为 issue，不阻塞流程
  - LLM 调用失败 → 指数退避重试
  - 人类决策冲突 → 冻结，等人工介入
- [ ] 关联公理：A3、A7

### C-P3：测试矩阵
- [ ] 扩展 `protocol/conformance/test-matrix.md`
- [ ] 按 Symphony 的三层结构组织：Core Conformance / Extension Conformance / Real Integration
- [ ] 每个不变量映射到具体的测试用例
- [ ] 关联公理：A2、A7

---

## Layer B：生态集成层（让正确的东西进入世界）

### B-P0：协议仓库独立化
- [ ] 将 `protocol/` 拆分为独立 Git 仓库（或独立发版的子目录）
- [ ] 确保 TypeScript/Python reader 可以独立 clone 和发版
- [ ] 协议 issue/PR 独立于 Delphi 实现 bug
- [ ] 协议版本和实现版本解耦
- [ ] 关联公理：A7

### B-P0：CLI-first 集成路径
- [ ] 拆分核心逻辑为两层：
  - DeepSpec Core（无 GUI 的库/CLI）：scan、generate、validate、render、export
  - DeepSpec Desktop（VCL 应用）：Core 的 GUI 包装 + WebView2 审阅
- [ ] Core 用 Delphi Console Application 实现
- [ ] 命令：`deepspec init` / `deepspec scan` / `deepspec generate` / `deepspec validate` / `deepspec render`
- [ ] 关联公理：A7

### B-P1：DeepSpec Tool Protocol
- [ ] 定义 4 个工具接口：deepspec_read / deepspec_validate / deepspec_query / deepspec_update
- [ ] 优先实现为 MCP Server（供 Claude / Cursor 调用）
- [ ] deepspec_read：按树/格式/过滤器读取结构化数据
- [ ] deepspec_validate：按 scope 校验 .deepspec/ 合法性
- [ ] deepspec_query：基于三棵树的 RAG 问答
- [ ] deepspec_update：带冲突检测的节点更新
- [ ] 关联公理：A5

### B-P1：.deepspec/ 自动生成 CLAUDE.md
- [ ] 每次 init/scan 时在项目根目录生成 `CLAUDE.md`（或 `AGENTS.md`）
- [ ] 内容："此项目有 DeepSpec 规格文件，请在生成代码前参考 .deepspec/ 目录"
- [ ] 包含三棵树摘要和关键约束
- [ ] 关联公理：A5

### B-P1：GOVERNANCE.md 补兼容性承诺
- [ ] 增加向后兼容承诺（新版本必须能读取旧版本 .deepspec/）
- [ ] 增加弃用策略（deprecated → 保留 2 个小版本 → 删除）
- [ ] 增加 x_ 扩展命名空间声明
- [ ] 增加 local.yaml 本地覆盖约定
- [ ] 关联公理：A7

### B-P2：.deepspec/ 文件系统最小完备性审计
- [ ] 列出每个文件的存在理由和消费者
- [ ] 验证去掉任何“推荐”文件后系统是否优雅降级
- [ ] 验证去掉任何“必需”文件后系统是否清晰报错
- [ ] 关联公理：A7

### B-P2：MANIFEST.yaml 防篡改
- [ ] 在 `.deepspec/` 里放 `MANIFEST.yaml`，列出所有应存在文件及其 SHA-256
- [ ] DeepSpec 启动时校验 manifest
- [ ] 文件被外部工具篡改/删除时提示用户
- [ ] 关联公理：A2

### B-P3：早期采用者计划
- [ ] 找 2-3 个早期采用者，帮他们集成 protocol
- [ ] 优先场景：Cursor/Claude Code 用户的 PRD 审阅层
- [ ] 记录集成反馈，驱动 protocol 迭代
- [ ] 关联公理：A7

---

## Layer A：工程实现层（可靠地造出来）

### A-P0：YAML Parser 单元测试
- [ ] 使用 DUnitX 为 `DeepSpec.Yaml.Parser.pas` 编写测试
- [ ] 覆盖已有边界加固的所有 case：BOM、code fence、tab、注释、块字面量、flow 序列
- [ ] 增加 malformed 输入的回归测试
- [ ] 关联公理：A7

### A-P0：Validation 单元测试
- [ ] 为 `DeepSpec.Validation.pas` 编写测试
- [ ] 覆盖节点 ID 校验、kind 校验、status 校验
- [ ] 覆盖不变量 INV-1 到 INV-6 的断言测试
- [ ] 关联公理：A2

### A-P1：上下文组装管线
- [ ] 将固定 4 模板（context-pack / generation / node / decision-rewrite）演进为可插拔的上下文组装管线
- [ ] 上下文源：scan-report / source files / 现有三棵树 / 决策历史 / 技术栈特征
- [ ] 按 token 预算动态裁剪（适配不同 LLM 的 context window）
- [ ] 实现最小权限上下文：按生成目标裁剪提供的文件范围
- [ ] 关联公理：A5

### A-P1：部分成功模式
- [ ] 每棵树独立管理自己的 gen_status 和错误信息
- [ ] function-tree 生成成功但 module-tree 失败时，用户仍可审阅 function-tree
- [ ] project-spec.yaml 中每棵树独立记录 generated_at / status / error / last_good_generated_at
- [ ] 关联公理：A7

### A-P1：快照与回滚
- [ ] 实现 `.deepspec/snapshots/` 目录
- [ ] 每次 Generate 操作前自动快照当前状态
- [ ] 生成失败或用户不满意时可回滚到 latest 快照
- [ ] 快照目录命名：ISO 8601 时间戳
- [ ] 关联公理：A3、A7

### A-P1：workflow.yaml 外置配置
- [ ] 设计 `.deepspec/workflow.yaml`（或扩展 project-spec.yaml）
- [ ] 外置内容：prompt 模板、扫描忽略规则、LLM 端点配置、决策审批流程
- [ ] 支持 `$VAR_NAME` 环境变量间接引用
- [ ] 支持 workflow 文件变更后自动重新加载
- [ ] 关联公理：A5

### A-P2：Hook 生命周期
- [ ] 定义 4 个 Hook：after_scan / before_generate / after_generate / before_render
- [ ] 每个 Hook 支持配置 shell 命令
- [ ] 每个 Hook 有独立的超时配置
- [ ] 失败语义：before_* 失败阻断当前操作，after_* 失败仅记录
- [ ] 关联公理：A7

### A-P2：LLM 输出 Schema 监狱
- [ ] 在 prompt 中嵌入“输出约束段”（必须输出合法 YAML、必须符合 Schema、给出 schema 片段示例）
- [ ] 解析端实现渐进式修复：第一层剥 BOM/code fence；第二层修复缩进；第三层逐节点 schema 校验，失败节点标记 draft 而非整体丢弃
- [ ] 关联公理：A5

### A-P2：Token 会计
- [ ] 将每次 LLM 调用的 input_tokens / output_tokens 写入 `.deepspec/` 的 metadata
- [ ] 在 project-spec.yaml 增加 token_usage 累计字段
- [ ] 为未来商业化（按 token 计费 / 配额管理）打基础
- [ ] 关联公理：A2

### A-P3：Scan 引擎测试
- [ ] 为 `DeepSpec.Services.Scan.pas` 编写测试
- [ ] 覆盖文件分类、忽略规则、递归扫描、边界条件
- [ ] 关联公理：A7

### A-P3：协议行为伪代码
- [ ] 在 `protocol/docs/` 下补充：scan-algorithm.md、generate-algorithm.md、review-algorithm.md、render-algorithm.md
- [ ] 用语言无关的伪代码描述每个核心流程
- [ ] 关联公理：A7

### A-P3：文件系统 Watcher
- [ ] 监听 A 目录（用户原始文档）的变更
- [ ] 变更时自动触发重新扫描或标记“规格需更新”
- [ ] Watcher 失效时退化为手动触发
- [ ] 关联公理：A7

---

## 优化任务汇总

| 层级 | P0 | P1 | P2 | P3 | 合计 |
|------|----|----|----|----|------|
| D（认知干预） | 2 | 1 | 2 | 1 | 6 |
| C（正确性保证） | 2 | 2 | 2 | 1 | 7 |
| B（生态集成） | 2 | 3 | 2 | 1 | 8 |
| A（工程实现） | 2 | 4 | 3 | 3 | 12 |
| **合计** | **8** | **10** | **9** | **6** | **33** |

### 推荐实施顺序

```
Phase 1（地基）：
  C-P0 不变量声明 + C-P0 正交状态 + A-P0 测试
  → 先让系统“正确”，才能在上面盖楼

Phase 2（核心体验）：
  D-P0 问题优先 + D-P0 信任信号 + A-P1 部分成功
  → 让用户第一次打开就能感受到“这不一样”

Phase 3（AI 集成）：
  A-P1 上下文管线 + A-P1 workflow.yaml + C-P1 语义束
  → 让 AI 的产出质量显著提升

Phase 4（生态打开）：
  B-P0 独立仓库 + B-P0 CLI + B-P1 Tool Protocol
  → 让外部工具和用户可以不依赖 Delphi 就用起来

Phase 5（持续改进）：
  其余 P2/P3 任务按反馈优先级推进
```
