# DeepSpec Bugfix Log

记录已发现并修复的缺陷。每条含：现象、根因、修复、验证、来源。

---

## #1 — 预存：`lpOpenAI` 未声明（编译阻断）

- **现象**：主程序 `DeepSpec.dpr` 编译失败，`src/services/DeepSpec.Services.LLMConfig.pas(62) E2003 Undeclared identifier: 'lpOpenAI'`。
- **根因**：`TLLMProvider` 枚举定义在 `DeepBase.LLM.Types`，但 `LLMConfig.pas` 的 uses 只引了 `DeepBase.LLM`。后者虽以类型别名 `TLLMProvider = DeepBase.LLM.Types.TLLMProvider` 重导出了类型名，但 Delphi 的类型别名不携带枚举成员的可见性，故 `lpOpenAI`/`lpAnthropic` 等成员不可见。
- **修复**：`LLMConfig.pas` uses 增加 `DeepBase.LLM.Types`（1 行）。
- **验证**：主程序编译干净，`bin/DeepSpec.exe` 正常生成。
- **来源**：本会话 2026-07-08 编译排查。注意：此 bug 与 Fog 改动无关，是会话开始前工作区已有的未提交状态。

---

## #2 — 预存：`DeepSpec.res` 文件未找到（编译阻断）

- **现象**：修掉 #1 后，编译报 `E1026 File not found: 'DeepSpec.res'`。
- **根因**：资源文件 `DeepSpec.res`（图标/版本信息）被本地删除（`git status: D DeepSpec.res`），dcc64 默认按 .dpr 同名查找 .res。
- **修复**：`git checkout -- DeepSpec.res` 从版本库恢复。
- **验证**：编译通过。
- **来源**：本会话 2026-07-08 编译排查。

---

## #3 — 本次会话遗留：Fog Map 数据流断裂（已补完）

- **现象**：Fog 探索模型在模型层（`TFogState`/`CanTransitionFog`）、校验层（`ValidateFogState`）、渲染层（fog 徽章 + Fog Map 分区）均已落地，但重新加载项目后 Fog Map 永远显示空、徽章永不渲染。
- **根因**：数据读写层未接通——
  1. `SpecStore.ReadTreeFile` 不解析 YAML 里的 `fog_state` 字段（grep 零命中），重新加载时 `TSpecNode.FogState` 保持默认 `fsClear`、`HasFogState` 保持 `False`。
  2. `DeepSpec.Yaml.Writer.WriteNode` 不序列化 `fog_state`，写出后 round-trip 丢失。
  3. `TreeBuilder` 从不赋值 `FogState`，首次扫描后无任何节点带 fog，Fog Map 必空。
- **修复**（本会话补完）：
  1. `SpecStore.ReadTreeFile`（`DeepSpec.Services.SpecStore.pas:368-374`）：在 confidence 之后加 `if LItem.Has('fog_state') then` 解析 → `FogStateFromStr(..., fsClear)` → 赋 `FogState` + `HasFogState := True`。
  2. `Yaml.Writer.WriteNode`（`DeepSpec.Yaml.Writer.pas:205-208`）：在 confidence 之后加 `if ANode.HasFogState then WriteScalarKV('fog_state', FogStateToStr(...))`，仅在显式设置时写出（不污染默认节点）。
  3. `TreeBuilder`（`DeepSpec.Services.TreeBuilder.pas:206-210`）：给 function 根节点默认标 `fsUnknownUnknowns` + `HasFogState := True`——该根是纯 stub（clLow + slAiInferred + 等待 LLM 生成），语义上正属"未知未知"。
- **验证**：测试 63/63 通过（含新增 13 个 `CanTransitionFog` 状态机 + round-trip 测试）；主程序编译干净。
- **设计说明**：只给 function 根标 fog，不给 module/view 根标——后两者从目录结构实打实推导（有证据、slParsedFromA、clMedium），不算"雾"。这样首次扫描后 Fog Map 有 1 个语义正确的雾区节点。
- **来源**：本会话 2026-07-08 发布就绪度评估（产品/UX 专家发现，经核实属实）。

---

## 待修缺陷清单（发布前阻断项，来自 3 专家评估）

以下缺陷已识别但**尚未修复**，记录于此供后续处理（BUG-4/BUG-5 已修复，见下方 #4/#5）：

| ID | 缺陷 | 维度 | 严重度 |
|----|------|------|--------|
| BUG-6 | `_build.bat` 硬编码 BDS 路径 + 14 个 DeepBase 绝对路径；DeepBase 源码不在仓库；无 CI | 工程/运维 | 高（部分已修：脚本参数化见 #6a；submodule/CI 待决策） |
| BUG-7 | `DeepBase.InitializeEx` 失败仅 `OutputDebugString`，用户看不到（静默挂掉）；exe 未签名（CompanyName 空，SmartScreen 拦截） | 运维 | 中 |
| BUG-8 | `Controller.GenerateB` 写 `candidate-output.yaml` 后不解析/不合入/不重渲染，用户看到"LLM done"但界面不变 | 产品 | 中（已修：见 #10） |
| BUG-9 | `RenderIndex` 仅 7 个静态链接，无健康度/优化 Prompt 入口/冲突摘要；定位文档 §7-9 承诺的 6 项能力零实现 | 产品 | 中 |
| BUG-10 | `RenderIndex` 无条件输出 data-tree.html 链接，但 `RenderAll` 仅在 DataNodes.Count>0 时渲染 → 非 Delphi 项目点链接 404 | 产品 | 低（已修：见 #7） |
| BUG-11 | Fog 探索 ticket（`research_ticket`/`prototype_ticket`/`grilling_ticket`/`fog_unknown`）枚举有定义但无创建入口/UI | 产品 | 中 |
| BUG-12 | 命名一致性：`.badge-fog-unknown_unknowns` CSS 类用下划线（与 `badge-fog-misty` 连字符风格不一致）；`EmitFogNodes` 参数 `LFogTarget` 用 L 前缀违反 A 前缀约定 | 工程 | 低（已修：见 #8） |
| BUG-13 | 死代码：`Decisions.pas` 的 `LChanged` 赋值后从不读取；`Settings.SaveToStore`、`Context.EstimateTokens` 声明未用 | 工程 | 低（已修：见 #9） |

---

## #4 — 测试套件"假绿"修复（原 BUG-4）

- **现象**：`DeepSpec.Tests.dpr` 设 `FailsOnNoAsserts := False`，导致 7 个零断言测试 + 4 个双分支 `Assert.Pass` 测试（"Detected X / parser limitation"）无论解析器好坏都通过；另有 4 个 `ValidXxx_NoError` 测试在"无 error 时循环不执行 Assert"也假绿。
- **核实（关键纠正）**：双分支测试的"parser limitation"分支基于**过时的预编译二进制**。用当前源码重编诊断程序（`_debug_parser.exe`、`_debug_tree_roundtrip.exe`）实测：当前 YAML 解析器对 block sequence + inline-map item + indent-4 后续字段**完全支持**——`items: [one,two,three]` 解析出 SeqCount=3，真实 tree 文件（2 节点含 parent_id）round-trip 完整。工程专家"parser limitation 是过时误判"的判断成立。
- **修复**：
  1. 7 个零断言测试补真断言：`InvalidNodeStatus`→断言 `invalid_status`、`InvalidConfidence`→`invalid_confidence`、`HumanDecidedBy`→`forbidden_human_decided_by`、`InvalidYAML`→断言返回 report 不崩、`InvalidPrefix`→`invalid_id_format`、`DuplicateId`→`duplicate_id`、`ExtensionKind`→断言无 `unknown_kind`。
  2. 4 个双分支测试改为单分支 `Assert.IsTrue`：`MissingParentRef`/`CircularParent`/`InvalidGenStatus`/`InvalidReviewStatus`。
  3. 4 个无兜底断言的 `ValidXxx_NoError` 测试在循环后加 `Assert.IsFalse(R.HasErrors, ...)`。
  4. `DeepSpec.Tests.dpr` 改 `FailsOnNoAsserts := True`，恢复严格检查。
- **验证**：测试 63/63 通过，`FailsOnNoAsserts=True` 下零假绿。
- **来源**：本会话 2026-07-08。

---

## #5 — SpecStore 非原子写 + 覆盖无备份修复（原 BUG-5）

- **现象**：`WriteYamlFile` 直接 `TFile.WriteAllText`，进程崩溃留半截文件；`WriteTreeFile` 覆盖前不备份，用户手工编辑或前次 agent 输出被静默覆盖丢失。
- **修复**：
  1. `WriteYamlFile` 改原子写：写 `.tmp` 临时文件 → 存在则 `TFile.Replace`（NTFS 原子替换）→ 不存在则 `TFile.Move`。崩溃时只丢临时文件，目标文件保持完整。
  2. 新增 `BackupTreeFileIfExisting`：`WriteTreeFile` 覆盖前若目标已存在，拷贝到 `snapshots/<基础名>.bak.yaml`（每棵树滚动保留上一版）。
  3. `CreateDirectoryStructure` 加 `snapshots/` 目录。
- **验证**：主程序编译干净；测试 63/63 无回归。
- **来源**：本会话 2026-07-08。

---

## #6a — 构建脚本参数化（原 BUG-6 第一部分）

- **现象**：`_build.bat` / `tests/_build_tests.bat` 硬编码 BDS 安装路径与 11 个 DeepBase 绝对子目录，工作目录写死 `D:\_Progs\02Business\DeepSpec`；测试脚本只编译固定的 `DeepSpec.Tests.dpr`，无法编译诊断/辅助 dpr。
- **修复**：
  1. 两个脚本改 `BDS` / `DEEPBASE_HOME` 环境变量优先、带默认回退（`if "%BDS%"=="" set ...`）。
  2. 工作目录改 `%~dp0`（脚本所在目录），可移植到任意 checkout 位置。
  3. `_build_tests.bat` 接受 `%1` 工程名参数（默认 `DeepSpec.Tests`），诊断程序（`_debug_parser` 等）可 `build_tests _debug_parser` 编译。
- **未修部分**（BUG-6b/6c）：DeepBase 作 git submodule/vendor DCU 需仓库结构变更与用户决策；CI workflow 需自托管 runner（BDS 商业软件无法用公共镜像）。见 tasks.md。
- **验证**：主程序 + 测试（63/63）+ 诊断 dpr 均用新脚本编译通过。
- **来源**：本会话 2026-07-08。

---

## #7 — data-tree 链接条件输出（原 BUG-10）

- **现象**：`RenderIndex` 无条件输出 `data-tree.html` 链接，但 `RenderAll` 仅在 `DataNodes.Count > 0` 时才渲染该文件 → 非 Delphi 项目（无数据节点）点链接 404。
- **修复**：`RenderIndex` 加 `AHasDataTree: Boolean = True` 参数，仅当为真时输出 data-tree `<li>`；Controller 三处调用点传入真实信号：扫描/RenderAll 路径用 `FTreeBuilder.DataNodes.Count > 0`，Reload 路径用 `(LData <> nil) and (LData.Count > 0)`（与该路径的渲染守卫一致）。
- **验证**：主程序编译干净；测试 63/63 无回归。
- **来源**：本会话 2026-07-08。

---

## #8 — Fog 命名一致性（原 BUG-12）

- **现象**：CSS 类 `.badge-fog-unknown_unknowns` 用下划线，与 `.badge-fog-misty`/`.badge-fog-foggy` 的连字符风格不一致（源于 `FogStateToStr` 返回 YAML 持久化值 `unknown_unknowns`）；`EmitFogNodes` 值参数 `LFogTarget` 违反项目 A 前缀约定。
- **修复**：新增私有方法 `FogStateCssClass(AFog)`，把 `FogStateToStr` 结果的下划线替换为连字符（不动 `FogStateToStr`，保 YAML round-trip）。3 处 badge class 生成点改用该方法；2 处 CSS 定义同步为 `badge-fog-unknown-unknowns`；`LFogTarget` → `AFogTarget`。
- **验证**：主程序编译干净；测试 63/63。
- **来源**：本会话 2026-07-08。

---

## #9 — 清死代码（原 BUG-13）

- **现象**：`Decisions.ApplyDecisionsToNodes`（第二变体）的 `LChanged` 只赋值不读取；`Settings.SaveToStore` 是空占位方法（仅 TODO 注释）；`Context.EstimateTokens` 声明未被调用。
- **修复**：删 `Decisions` 第二方法的 `LChanged` 变量及 4 处赋值（节点状态直接修改，无需变更标记）；删空 `Settings.SaveToStore`（声明+实现）。`Context.EstimateTokens` 经审查**保留**——它有真实 token 估算逻辑，是 `TContextChunk.TokenEstimate` 的自然来源，加注释标明用途防后续误删。
- **验证**：主程序编译干净；测试 63/63。
- **来源**：本会话 2026-07-08。

## #10 — GenerateB 闭环 + Candidate 强类型沙盒（原 BUG-8）

- **现象**：`Controller.GenerateB` 调 LLM 后只把响应写进 `llm/candidate-output.yaml` 并 `TaskFinish('LLM done')`，到此为止——不解析、不合入树、不退雾、不重渲染。用户看到"LLM done"但界面纹丝不动。对应 wayfinder 文章"ticket 解完写回地图"的断裂点：解了 ticket 却没回写地图，fog 不收敛。
- **根因**：缺一整段"LLM 输出 → 强类型校验 → 合入 → 退雾 → 持久化 → 重渲染"的胶水代码；且 LLM 输出天然不可信，直接 ParseTreeNodes 合入会把脏数据写进活树。
- **修复**（5 步，含一个抽取）：
  1. **SpecStore 抽 `ParseTreeNodes`**：从 `ReadTreeFile` 私有内联里抽出 `function ParseTreeNodes(ARoot, ADefaultTree): TList<TSpecNode>` 并提为 public，供沙盒复用；同时修掉原内联里"先建空 Result 表再被 ParseTreeNodes 覆盖导致空表泄漏"的 bug（改用局部 `LParsed` 接返回再 `Result.Free`+赋值）。
  2. **新建 `DeepSpec.Services.CandidateIngest` 强类型沙盒单元**：`SplitDocuments`（按行首 `---`/`...` 切多文档流，丢空段、不产生空前段）；`Ingest`（拆文档 → 复用 `ParseTreeNodes` 解析 → 逐节点 `ValidateNode`：id 前缀匹配 tree、`parent_id` 外键约束、`source_layer≠human_decision`、`gen_status≠confirmed`、`review_status` 强制 unreviewed、data-tree 丢弃并 warning；合格节点按 tree 路由进 Func/Mod/View 列表）；`MergeInto`（按 id 匹配，覆盖可变语义字段，**保留 review_status / decision_refs**——人审决策必须跨 LLM 重生成存活，gen_status 推进到 gsGenerated，function 根 summary 实变时退雾 `fsUnknownUnknowns → fsFoggy`，新 id 追加）。
  3. **Controller.GenerateB 接闭环**：在 `TThread.Queue` 的 UI 线程成功分支里，写盘后 `TDeepSpecCandidateIngest.Create → Ingest → MergeInto → WriteTreeFile(三树) → RenderAll`，全程 try/except 兜底（失败只 LogError + TaskFinish，不回滚已写盘的 candidate——留给用户 `RefreshFromYaml` 手动兜底）。TaskFinish 消息带上 ingested/merged/added/fog-cleared/rejected/warnings 计数。
  4. **Prompts 输出契约改多文档**：§6/§7/§8 明确指示 LLM 在**单个响应**里输出 **YAML 多文档流**（`---` 分隔，每段 `# file:` 注释路由），给最小骨架示例；新增约束禁 `gen_status:confirmed` / 禁非 `unreviewed` 的 review_status / id 前缀 / parent_id 外键——与沙盒校验一一对应，让 LLM 第一道就合规。
  5. **单测 18 例**：`Test.DeepSpec.CandidateIngest` 覆盖 SplitDocuments 四态、Ingest 校验八例（含 bad-prefix / 悬空 parent_id / source_layer 冒充 / gen_status 自确认 / review_status 越权 / data-tree 丢弃）、MergeInto 六例（字段覆盖 / review_status 跨重生存活 / gen_status 推进 / summary 变才退雾 / summary 不变不退雾 / 新 id 追加）。
- **踩坑**：`ValidateNode` 初版 `AResult: TCandidateIngestResult` 是**值参数**——record 副本里 `Inc(AResult.Rejected)` 不回传调用方（`Errors.Add` 因 TStringList 是引用类型却生效），表现为"Errors 有内容但 Rejected=0"。改 `var AResult` 修复。单测第一时间捕获。
- **验证**：主程序 45939 lines 编译干净（0 error，仅原有 AnsiString 隐式转换 warning）；测试 81/81（原 63 + 新 18）。
- **范围边界**：本次 CandidateIngest 只处理 **function/module/view** 三树节点合入；**data-tree 不合入**（data 来�� scan 不来自 LLM，沙盒内 warning 丢弃）；evidence/issues 段可选但本轮未实现校验，留 TODO。Fog 只收敛**一步**（unknown_unknowns → foggy），不全清——一轮 LLM 生成不足以消除所有未知。
- **来源**：本会话 2026-07-08。

---

## #11 — issues 读写基础 + ticket 建模数据层（原 BUG-11 第 1 步）

> 三合一主线（BUG-11 + BUG-9 + 端到端）的第 1 步：让 issues 能读能写能反序列化。ticket 是 issue 的子集（`IssueType ∈ {research/prototype/grilling/fog_unknown}_ticket`），共享一套存储，不新建 TTicket 类型。**第 2/3 步（创建入口 / 健康度看板）见 tasks.md 进行中。**

- **现象**：`issues/doc-issues.yaml` 只有空骨架（`CreateDirectoryStructure` 写 `issues: []`），SpecStore **无 ReadIssuesFile/WriteIssuesFile**；Controller 从不加载 issues；`TSpecEnums` 有 `IssueTypeToStr` 等正向序列化却**缺 `IssueTypeFromStr` 等反查**——issues 反序列化不了 ticket 类型，round-trip 必丢字段。wayfinder 文章指出的"建了模型没建工作流"断裂点之一。
- **根因**：issues 这条线只建了 schema + Models record + Writer 的正向序列化（`WriteIssue` 已存在），反向解析（Read）和枚举反查（FromStr）从未补，导致 Controller 无从加载、UI 无从展示。
- **修复**（4 处，仅数据层）：
  1. **`Models.pas` — `TSpecIssue` 加 `RequiresHuman` + `HasRequiresHuman`**：HITL/AFK 属性（文章建议），沿用 `HasFogState`/`HasRiskScore` 的可选字段模式，非 ticket issue 不设则不出现在 YAML。
  2. **`Models.pas` — `TSpecEnums` 补三个 FromStr**：`IssueTypeFromStr`（全 14 值含 4 类 ticket）、`IssueSeverityFromStr`（critical/high/medium/low/info）、`IssueStatusFromStr`（open/resolved/wontfix/deferred），照 `FogStateFromStr` 写法。补 interface 声明 + 实现。
  3. **`Yaml.Writer.pas` — `WriteIssue` 补 `requires_human`**：在 `resolved_at` 之后，仅当 `HasRequiresHuman` 时 `WriteBoolKV`——非 ticket issue 不污染 YAML。
  4. **`SpecStore.pas` — 加 `WriteIssuesFile`/`ReadIssuesFile`**：照 `ReadBundlesFile`/`WriteBundlesFile` 模板。`WriteIssuesFile` 复用已存在的 `TYamlWriter.WriteIssuesFile` 序列化；`ReadIssuesFile` 内嵌 `StringList`/`ReadSourceRefs`（与 `ParseTreeNodes` 同款）解析 affected_nodes/source_refs/各枚举字段/requires_human。
- **验证**：主程序 46121 lines 编译干净（0 error，仅 DeepBase Hint + Prompts AnsiString warning，均原有）。
- **范围边界**：本轮**仅数据层**——Model 字段 + 枚举反查 + 读写方法。**第 1 步剩余**（`Validation.ValidateIssue`/`ValidateIssuesFile` + 8 例单测）尚未写，与第 2/3 步一并留作进行中。issues 已能 round-trip 但尚无调用方（Controller 未加载、UI 未展示）。
- **来源**：本会话 2026-07-08。

---

## #12 — issues 校验 + 单测（原 BUG-11 第 1 步剩余）

> 三合一主线第 1 步的收口：数据层（#11）让 issues 能读写，本步补**校验**——脏 issue（空 id / 非法枚举 / 空 affected_nodes / ticket 与 requires_human 不一致）在落盘前被拦。为第 2 步（ticket 创建入口，落盘前调 `ValidateIssuesFile`）铺路。

- **现象**：`TYamlValidator` 有 `ValidateTreeFile`/`ValidateProjectSpec`/`ValidateLLMSecurityRules`/`ValidateNodeHashes` 却**无 issues 校验**。issues 已能 round-trip（#11）但无人把关，脏数据静默落盘。
- **修复**（2 处，仅校验层 + 单测）：
  1. **`Validation.pas` — 加 `ValidateIssue`（private）+ `ValidateIssuesFile`（public）**：照 `ValidateTreeFile` 模板（`TYamlParser.Parse` → try/except 兜 `parse_error` → 取 `issues` seq → 逐项）。`ValidateIssue` 逐条校验：id 非空且 `issue-` 前缀（`missing_id`/`invalid_issue_id`）、severity/type/status 枚举合法（const 数组比对，**不**调 `TSpecEnums.FromStr`——校验器只认 schema 白名单，反查会给默认值掩盖非法值）、title 非空、description 空（warning）、affected_nodes 非空（`empty_affected_nodes`）、`requires_human` 仅对 ticket 类型有意义（非 ticket 设了 → `requires_human_mismatch` **warning**，不过度约束）。空 `issues: []` 合法。
  2. **`Test.DeepSpec.Validation.pas` — 加 `TValidationIssuesTests` fixture 8 例**：合法 issue 无错 / 空 id / 非 `issue-` 前缀 / 非法 severity / 非法 type / 空 affected_nodes / research_ticket+requires_human 无错（AFK 合法）/ 非 ticket+requires_human 仅 warning（不进 HasErrors）。
- **设计取舍**：`requires_human` 一致性只做**反向**检查（非 ticket 设了 → warning），ticket 取什么值不报错——字段语义是"可选"，过度约束会逼 LLM/用户填错。description 按 schema 无 minLength 故降为 warning。id 前缀用 `StartsWith` 轻量检查，不引新正则。
- **验证**：测试 89/89（原 81 + 新 8）；主程序 46272 lines 编译干净（0 error，仅 DeepBase Hint + Prompts AnsiString warning，均原有）。
- **范围边界**：仅**校验层 + 单测**。不在本步接 Controller（第 2 步 `CreateTicket` 落盘前调 `ValidateIssuesFile`）、不动 UI/schema。round-trip 信任由 #11 数据层 + 本批校验例间接保证；如需显式 Write→Read round-trip 单测作后续补充。
- **来源**：本会话 2026-07-09。

---

## #13 — ticket 创建双入口（BUG-11 第 2 步）

> 三合一主线第 2 步：把"雾区节点→开探索 ticket→退雾一步→落盘"主循环跑通。第 1 步（#11 数据层 + #12 校验）让 issues 能安全读写，本步接上**工作流入口**——HTML 按钮与 VCL 兜底两条路都汇到 `Controller.CreateTicket`，落盘前过 `ValidateIssuesFile`，落盘后重渲染 problems 页 Open Tickets。

- **现象**：fog 四态 + 四类探索 ticket 的原语全在，但无入口——fog 区节点旁没按钮，issues 已能 round-trip 却**无人写入**。定位文档"一次解一个 ticket"主循环停留在数据层。
- **修复**（4 个文件）：
  1. **`Services.Render.pas` — `RenderProblemsPage` 加 `AIssues: TList<TSpecIssue>` 参数**：新增 Fog Map 区（节点按 `fog_state` 分三组：unknown_unknowns/foggy/misty，每组节点旁挂 `ticket-create` 按钮，`data-node-id`/`data-node-title`）+ Open Tickets 区（只列 open + 四类探索 ticket，复用 `.ticket`/`.ticket-meta` CSS，`HasRequiresHuman` 显示 HITL/AFK）+ JS Bridge 事件转发（与 tree 页同形，ticket 按钮点击后**不灰化**以允许同节点多开 ticket）。空 fog 显示"全 clear"提示，空 ticket 显示"从雾区开一张"提示。
  2. **`Providers.MainView.pas` — `HandleWebMessage` +`ticket-create` 分支**：解析 `data-action`，对 `ticket-create` 取 `node_id`/`node_title` 转调注入的 `ATicketFactory` 闭包。
  3. **`DeepSpec.Providers.pas` + `MainForm.pas` — 闭包注入**：`RegisterAllProviders` +`AController` 参数，构造 `procedure(ANodeId, ANodeTitle) → AController.CreateTicket`；MainForm 调用点传 `FController`（此时 Controller 已构造）。
  4. **`Controller.pas` — `CreateTicket` + `LoadIssuesForRender`**：定位节点（跨 4 棵树）→ `TSpecEnums.DefogOneStep` 退雾一步 → 组装 `TSpecIssue`（research_ticket / open / AFK / affected_nodes=该节点）→ `TYamlWriter.WriteIssuesFile` + `ValidateIssuesFile` **落盘前校验**（有错 LogError 不写）→ 持久化 issues.yaml + 所在 tree → `RenderAll` 重渲染（problems 页 Open Tickets 与 Fog Map 同步刷新）。`LoadIssuesForRender` 读 issues 供渲染。
- **途中暴露并修复的 4 处编译错误**（均为本会话新增代码的遗留）：① `RenderProblemsPage` **实现签名漏 `AIssues` 参数**——声明已改实现未跟，致 forward declaration unsatisfied + 一连串 cascade；② Delphi **无 `?:` 三元运算符**——`HasRequiresHuman` 处 `(b ? 'HITL' : 'AFK')` 改 if/else；③ Controller **interface-uses 漏 `DeepSpec.Models`**——`LoadIssuesForRender: TList<TSpecIssue>` 在接口段声明却未引 Models（impl-uses 有，但 interface 段需自己引，且同单元不能重复出现在两段 uses）；④ `LMsg.TrimEnd` → `TrimRight(LMsg)`（`TrimEnd` 非 `TStringHelper` 方法）。
- **设计取舍**：ticket 创建走"先退雾后落盘"——退雾是节点状态变更，ticket 是对该变更的记录，二者同事务写入（tree + issues.yaml 一起持久化），保证重渲染时 Fog Map 已反映退雾、Open Tickets 已含新 ticket。research_ticket 默认 AFK（`RequiresHuman=False`），符合"HITL/AFK 属性"语义。校验在落盘前而非创建后——脏数据不落盘，UI 不需回滚。
- **验证**：测试 93/93（+4 `DefogOneStep` + 新增渲染相关，0 failed/0 errored）；主程序 0 error 编译干净（仅 DeepBase Hint + Prompts AnsiString warning，均原有）。
- **范围边界**：仅**工作流入口层**——Render/Providers/Controller/MainForm 接线。**不动** schema、不动 issues 校验规则（#12 已定）、不接 BUG-9 看板（第 3 步）。VCL 兜底对话框入口（MainForm 菜单）按计划留到第 3 步连同 BUG-9 一并做，本步 JS Bridge 入口已闭环可端到端。
- **来源**：本会话 2026-07-09。

---

## #14 — index.html 导出按钮无 JS Bridge（BUG-9 端到端验证暴露）

- **现象**：BUG-9 健康度看板的"导出优化 Prompt"按钮（`data-action="export-optimization-prompt"`）点击无反应——后端 `Controller.ExportOptimizationPrompt` 已就绪、JS Bridge 主机端分支已接通（Task 3），但按钮在浏览器里是死的。
- **根因**：`RenderIndex` 用 `PageFooter` 收尾，而 `PageFooter` 只是静态 `</footer></body></html>`，**不含任何 `<script>`**。其它页面（problems/bundles/tree）每页都在 `PageFooter` 前追加各自专用的 bridge 脚本，故其 `data-action` 按钮可用；唯独 index 页漏了。即"看板页本身没接桥"。
- **修复**：在 `RenderIndex` 的 `PageFooter` 前追加一段**专用 bridge 脚本**——只匹配 `data-action="export-optimization-prompt"`，发送 `{action:"export-optimization-prompt"}`，成功后把按钮文案改为"✓ Prompt 已导出"，`.posted` 防重复；无桥时 `alert` 兜底。未动其它页面的既有脚本（它们工作正常，`textContent` 重写硬编码了 ✓/✗ 字形，不适用本按钮）。
- **验证**：主程序 0 error 编译干净；测试 97/97 不变（脚本为字符串字面量，无单测覆盖，靠编译 + 静态审查）。
- **来源**：本会话 2026-07-09，BUG-9 端到端验证阶段静态审查 index 输出时发现。

---

## #15 — SPW 发布审计（2026-08-06）：死按钮 + 拒绝态决策不生效 + 原子写旁路

> 触发：SPW 发布审计（`spw-manifest.json`，delphi_gui 画像）。H3.deep-ui-test 门禁
> （渲染的 data-action 必须有主机处理器）确定性 FAIL：`bundle-accept`/`bundle-reject`
> 渲染并发出 postMessage，但主机无分支。H4 旁路扫描另命中：`Decisions.Save`/
> `AppendPendingDecision` 裸 TFile 写（绕过 bugfix #5 原子写）、AutoFix 场景硬编码
> 绝对路径。代码审查进一步确认 `ApplyNodeStatusTransitions` 只应用 dsAccepted 决策，
> Reject All 语义即使接线也不会生效（dtReject 分支不可达）。

- **现象**：bundles.html 的 Accept All / Reject All 按钮点了没反应；`tasks.md` 却标 ✅。
- **根因**：`MainView.HandleWebMessage` 只分发 node-confirm/node-reject/ticket-create/
  export-optimization-prompt 四个 action，`bundle-*` 无分支（与 bugfix #14 同类：主机端
  漏接线）；且 `Decisions.ApplyNodeStatusTransitions`（两变体）守卫 `Status <> dsAccepted
  then Continue`，dsRejected 决策永不触发迁移。
- **修复**（6 个 src 文件）：
  1. **`Providers.MainView.pas`**：新增 `TBundleActionProc` 回调类型（AAction + ABundleId）；
     `TBrowserNavigator`/`TDeepSpecMainViewProvider` 构造注入第三闭包；`HandleWebMessage`
     解析 `bundle_id` 并分发 `bundle-accept`/`bundle-reject`。
  2. **`Providers.pas`**：`RegisterAllProviders` 第三闭包 → `AController.ApplyBundleDecisions`。
  3. **`Controller.pas`**：抽私有 `ApplyAllTreeTransitions`（读树→ApplyNodeStatusTransitions→
     写回，供 Promote 与 bundle 共用）；新增 public `ApplyBundleDecisions(AAction, ABundleId)`：
     读 bundles.yaml → 按 id 定位 → 一条正式人类决策（dtConfirm/dtReject，TargetNodes=全部
     锚点节点）→ Accept/RejectDecision → 全树迁移 → RenderAll → 状态栏回报。impl uses 补
     `System.StrUtils`（`IfThen` 字符串重载所在单元）。
  4. **`Decisions.pas`**：两变体守卫改 `(Status <> dsAccepted) and (Status <> dsRejected)
     then Continue`——拒绝态决策同样生效（Reject All / node-reject 语义修复）。
  5. **`SpecStore.pas`**：新增 public static `AtomicWriteTextFile(AFullPath, AContent)`——
     bugfix #5 的 .tmp + TFile.Replace 逻辑提升为共享入口；`WriteYamlFile` 委托之。
  6. **`Decisions.Save`** 与 **`AppendPendingDecision`**（MainView）改走
     `AtomicWriteTextFile`（后者为读-合并-原子替换，消除半截 append 风险）；
     **`MainForm.pas`** AutoFix 'open-project' 场景的硬编码
     `D:\_Progs\02Business\DeepSpec` 改为 `DEEPSPEC_AUTOFIX_PROJECT` 环境变量，为空不注册
     该场景。
- **验证**：主程序 47514 lines 0 error；测试 97/97 无回归；SPW 重跑
  `H3.deep-ui-test → PASS`（6 个 data-action 全部有主机处理器）、
  `H4.HARDCODED_ABS_PATH → 0 命中`、`H4.DIRECT_DISK_WRITE` 仅剩
  审阅面/导出/原子写 tmp 的 by-design 命中。
- **范围边界**：BUG-7 的 `DeepSpec.dpr:70`（InitializeEx 失败仅 OutputDebugString）与
  exe 签名/VerInfo 属 *.dpr/工程文件（`boundary.json` 禁 AI 改），仍待用户会话；
  `Decisions` 四处 TryTransition 失败诊断的 `OutputDebugString` 为批处理幂等 no-op
  边缘路径，保留（真用户可见项是 dpr 的 InitializeEx）。
- **来源**：本会话 2026-08-06 SPW 发布审计（H3/H4 门禁确定性发现）。

## #16 — BUG-7：InitializeEx 弹窗 + VerInfo + 缺失图标（2026-08-06 收尾）

- **现象**：`DeepBase.InitializeEx` 失败仅 `OutputDebugString`，用户看不到；exe VerInfo 的
  CompanyName/LegalCopyright 为空（SmartScreen 拦截风险）；msbuild 构建报
  `unable to open file 'DeepSpec.ico': FileNotFound`——`Icon_MainIcon` 引用了一个
  **从未入库**的图标文件，IDE/MSBuild 构建一直无法使用。
- **修复**：
  1. `DeepSpec.dpr:69-71`：`InitializeEx` 失败改 `ShowMessage` 弹窗（说明影响范围，仍继续运行）。
  2. `DeepSpec.dproj`：两处 `VerInfo_Keys` 补 `CompanyName=DeepKit` +
     `LegalCopyright=Copyright (c) 2026 DeepKit`。
  3. 新建 `DeepSpec.ico`（16/32/48 三尺寸 BGRA 图标，脚本生成）——修复 msbuild 构建缺口；
     用 msbuild 重建 `DeepSpec.res`（IDE 生成的版本资源随 dproj VerInfo 更新）。
- **验证**：msbuild /t:Build 0 error；`bin\DeepSpec.exe` VerInfo 显示
  CompanyName=DeepKit / LegalCopyright=©2026 DeepKit；exe 图标 ExtractAssociatedIcon 32x32 有效；
  测试 97/97 无回归；SPW 重跑 H4.SILENT_INIT_FAILURE 对 `DeepSpec.dpr:70` 命中清除。
- **范围边界**：**数字签名（signtool）仍待证书**——需用户提供/购买代码签名证书后执行；
  `Decisions` 四处 TryTransition 失败诊断保留 `OutputDebugString`（幂等批处理边缘路径，见 #15）。
- **来源**：本会话 2026-08-06，SPW 发布审计 P1 项收尾。

## #17 — 2026-08-06/07：i18n 自动切换 + CLI 落地 + 原子写崩溃 + Visualize 死按钮（第二批）

> 用户实跑反馈："Visualize 无反应、日志只有 (scan log)"；要求：集成 DeepBase i18n 自动
> 检测 Windows 语言（当前中文）；直接实现 CLI 并自行测试。CLI 自测意外抓到 bugfix #5
> 的隐藏崩溃路径（首次扫描永远走 Move 分支，重扫才暴露）。

- **现象**：①Visualize 按钮在已含 `.deepspec` 的目录上被禁用（点了没反应），且扫描日志
  memo 从不更新（永远显示占位 "(scan log)"）；②界面不随 Windows 语言自动切换；③CLI 自测
  `scan` 在已有 `.deepspec` 的项目上抛 `EInOutArgumentException: Path is empty`。
- **根因**：
  1. `MainForm.DoShellTreeChange` 仅对"无 .deepspec"的目录启用按钮；`HandleScanEvent`
     从不写 `FScanLogMemo`；扫描后按钮永久禁用。
  2. i18n：DeepShell 自带 zh 文本表（`RegisterDefaultShellTexts`）**全库无调用点**；
     DeepSpec 只注册了 6 个键；locale 检测结果（如 `zh-Hans-CN`）与已注册的 `zh-CN`
     桶不匹配时全部回落英文；DeepBase.Manager.CurrentLanguage 未同步。
  3. **原子写崩溃（bugfix #5 隐藏缺陷）**：`TFile.Replace(..., '')` 的 RTL 实现会对备份名
     执行 `TPath.DoGetFullPath('')` → "Path is empty" 异常。首次扫描目标文件不存在走
     `TFile.Move` 分支从未触发；**任何重扫/覆盖已有文件都崩**。CLI 在已存在 `.deepspec`
     的样例上自测立即复现。
- **修复**：
  1. **`SpecStore.AtomicWriteTextFile`**：改用 `Winapi.ReplaceFileW`（备份参数传 nil，
     原子语义不变，`REPLACEFILE_WRITE_THROUGH | REPLACEFILE_IGNORE_MERGE_ERRORS`），
     失败回退 delete+move。**GUI 重扫项目的崩溃从此消除**（#15 引入原子写共享后，
     Decisions.Save / AppendPendingDecision 也一并受益）。
  2. **新单元 `DeepSpec.Localization.pas`**：`DeepSpecDetectLocale`（`DetectSystemLocale`
     归一化：zh-Hans*/zh-CN/zh-SG → zh-CN；zh-Hant*/zh-TW/zh-HK → zh-TW；其余 en-US）；
     `DeepSpecApplyLocale`（注册 DeepSpec 21 键 × zh-CN/zh-TW 全表 + DeepShell 默认表，
     `SetLocale` 自动切换，并镜像 `DeepBase.Manager.CurrentLanguage`）。
  3. **`MainForm.pas`**：`RegisterServices` 改调 `DeepSpecApplyLocale`（原 6 键内联删除）；
     `DoShellTreeChange` 任何有效目录都启用按钮；`HandleScanEvent` 写实时扫描日志
     （文件数/类别统计/树节点数/类型）并重启用按钮；启动状态消息走 `ShellText`。
  4. **`Commands.pas`**：9 个命令标题 + LLM 设置对话框全部走 `ShellText`。
  5. **CLI（Phase 5 B-P0 落地）**：新 `cli/DeepSpec.CLI.dpr` + `_build_cli.bat`，
     复用 src/ 服务（无 DeepShell 依赖）：`init / scan / generate / validate / render`；
     validate 错误时 exit 1。CI workflow 增加 CLI 构建步骤。
- **踩坑**：Delphi 源文件按 ANSI(GBK) 读取——`.pas` 内**禁止**跨行字符串隐式拼接和行尾
  中文注释（UTF-8 字节在 GBK 解码下破坏 tokenizer，E2052/E2066）；`#$XXXX` 转义后
  不能再跟多余 `'`（会开启未终止字符串）。全部改为单行 + 纯 ASCII 注释。
- **验证**：主程序 47893 lines 0 error；测试 97/97；CLI 自测闭环——fresh 项目
  init→scan→re-scan（修复前必崩）→validate(0 error, exit 0)→坏节点注入
  (1 error, exit 1)→重扫修复→generate→render 6 个 HTML；SPW 重跑 H1-H3 全 PASS
  （H1 门禁正则修复属性链误报：最长存在前缀解析），H4 14 条均为 by-design。
- **范围边界**：HTML 审阅页（index/trees/problems/bundles）仍为英文，属后续 P2；
  CLI `generate` 只导出提示词（LLM 调用在 GUI Generate B）。
- **来源**：本会话 2026-08-06/07 用户实跑反馈 + CLI 自测。

## #19 — 2026-08-07：GUI 行为 mock 测试闭环（113/113）+ 三个真实缺陷

> 用户要求把 GUI 操作全部 mock 化测试（Visualize 扫描+日志、看板数字、ticket 退雾、
> bundles 按钮、重启后决策保留）。新 fixture `Test.DeepSpec.Controller`：mock 三个
> DeepShell 接口（IShellStatusManager/IShellContextManager/IShellEventBus），真实服务
> 全链路驱动 Controller。过程中暴露并修复 3 个真实缺陷。

- **缺陷 1（显示乱码，最严重）**：`Render.pas`/`Controller.pas` 等 18 个源文件内的中文字符串
  在 dcc64 按 ANSI(GBK) 读取下被错误解码——**生成的所有 HTML 页（看板/树/问题）中文全是
  乱码**（如"文档健康度"变 GBK 双重编码垃圾）。修复：给含非 ASCII 字符的源文件加
  **UTF-8 BOM**（编译器原生识别；`{$CODEPAGE UTF8}` 指令在 dcc64 37.0 报 E1030 无效）。
  验证：CLI render 后 index.html 正确含"文档健康度/高风险问题/冲突摘要/优化 Prompt"。
- **缺陷 2（空树崩溃）**：`Controller.ApplyAllTreeTransitions` 对 `nodes: []` 的空树
  （无 UI 文件的后端项目 → view-tree 空）执行 `LNodes[0].Tree` → "List index out of
  bounds" —— Promote 决策 / bundles 操作在纯后端项目上必崩。修复：空树跳过。
- **缺陷 3（界面不刷新）**：bundle 决策走"读盘→迁移→写盘"，但内存树（FTreeBuilder）
  不更新——RenderAll 渲染旧状态，用户点 Accept All 界面无变化。修复：新增
  `ReloadInMemoryTrees`（迁移后从盘回灌内存），ApplyBundleDecisions 与
  PromotePendingDecisions 均调用。
- **测试**：`Test.DeepSpec.Controller.pas` 8 例——扫描全量（文件/树/HTML/事件）、看板
  HTML、`ComputeHealthMetrics` 纯函数数字（TotalNodes/Confirmed/CoveragePct/
  AvgConfidence/FogCount/Backlog/HighRisk）、ticket 退雾落盘（unknown_unknowns→foggy +
  research_ticket + AFK）、bundle accept/reject 全树迁移、**重启后决策保留**（#18 回归：
  type+target_nodes round-trip）。113/113 全绿。
- **验证**：主程序 47989 lines 0 error；97→113 测试；SPW H1-H3 全 PASS。
- **范围边界**：MainForm 的 VCL 控件层（HandleScanEvent 写 memo/树控件）不在单测范围
  （数据层已由 Controller 测试覆盖）；JS Bridge 消息解析（HandleWebMessage）为静态
  H3 门禁覆盖。
- **来源**：本会话 2026-08-07 用户要求 GUI 行为 mock 化。
