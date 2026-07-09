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
