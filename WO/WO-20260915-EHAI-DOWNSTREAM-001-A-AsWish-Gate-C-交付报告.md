# WO-20260915-EHAI-DOWNSTREAM-001-A
# AsWish Gate C Execution & Evidence Report
## EHAI Reference Product Binding 001 承接实测与证据报告

- **工单编号**：`WO-20260915-EHAI-DOWNSTREAM-001-A`
- **任务性质**：EHAI 下游首发产品（AsWish）Gate C 承接验证与证据归档
- **承接角色**：开发甲（串行执行 · AsWish Owner 阶段）
- **Owner Repo**：`AsWish` (`D:\_Progs\02Business\AsWish`)
- **消费上游基线**：DeepBase `fc213b4696d92bc8a836ef644abaeb74f0daa79e`（Gate B 裁定：`PASS WITH NON-BLOCKING FINDINGS`）
- **执行时间**：2026-09-15
- **工单状态建议**：`READY FOR GATE C REVIEW`（开发方严格遵守纪律，不自裁 PASS，等待主控/审计独立终审）

---

## 一、A-1｜Gate C Semantic Binding Matrix（语义绑定矩阵）

本矩阵逐项检验 EHAI Language Common Contract 十项核心语义在 AsWish 领域的真实落地与承接情况：

| # | Common Semantic | DeepBase/HB Realization | AsWish Domain Meaning | AsWish Implementation | Human Observable | Test Evidence | Verdict |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| 1 | **CandidateSpace** | `CandidateSpace <= 7` (1..7 候选槽位) | 单次需求变更/推荐方案的候选空间，严格约束于 1..7 | `THbChoiceAction.Key` (1..7) 映射至候选 ChangeSet | UI 卡片/Deck 上清晰呈现 1..7 选项，无无限膨胀 | `ASWISH_V_010`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 2 | **RecommendedMark** | `IsRecommended` 标志 (Key 1 推荐，非最优) | AI 推荐的默认实现路径，供人类优先权衡 | `THbChoiceItem.IsRecommended`，仅作高亮与提示，不触发自动提交 | 推荐项带明确视觉标识，但点击仍为审阅探索态 | `ASWISH_V_010`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 3 | **CandidateSelection** | `emaChoose` (Selection != Inherent Commitment) | 审阅特定 ChangeSet 的 4 层投影视角，不修改规范正本 | `FBinding.ProcessHbAction(cakCandidate)` -> `ReviewChangeSet` | 弹出/更新 4 层审阅界面，磁盘 Spec 树内容 0 字节变动 | `ASWISH_V_001`, `ASWISH_V_006`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 4 | **Regenerate** | `emaRegenerate` (Key 8，同框架纯探索) | 重新导出 Prompt 或重算候选方案，保持在当前节点框架内 | `FBinding.ProcessHbAction(cakRegenerate)` -> `ExportPrompt` | 触发 Prompt 重新生成，历史基线与决策完全不变 | `ASWISH_V_007`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 5 | **HumanOverride** | `emaReframe` (Key 9，候选否定/自由替代) | 用户在当前节点框架下提出自由自然语言意图 | `FBinding.ProcessHbAction(cakFreeInput)` -> `SubmitUserIntent` | 用户自由输入生成待审阅 ChangeSet，不直接写入主规范 | `ASWISH_V_005`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 6 | **FrameRejection** | `eokFrameRejection` (Key 9，框架否定/立论反驳) | 彻底否定当前节点成立前提，将高级意图推向更上游需求 | `SubmitFrameRejection` -> 标记节点 `frame_rejected` 并将意图上推 | 节点状态置为否定，未沦为“第 4 个选项”，原摘要未被篡改 | `ASWISH_V_004`, `ASWISH_V_009`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 7 | **BackNavigation** | `emaExit` (Key 0，无承诺退出 != Reject) | 退出当前审阅/交互流，绝不撤销历史既定决策 | `FBinding.ProcessHbAction(cakBack)` -> 纯信息态返回 | 界面退回上级或关闭 Deck，已有 Decision 与 Baseline 完好 | `ASWISH_V_008`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 8 | **SourceDistinction** | `TEhaiSource` (`esHuman` vs `esAI`) | 区分人类明确意图 (`cstExplicit`) 与 AI 推断派生 (`cstInferred`) | `TChangeItem.SourceType` 显式分类，YAML 存盘全周期保留 | 审阅界面明确标注“你提出”与“AI 推断”，禁止移花接木 | `ASWISH_V_011`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 9 | **CommitmentBoundary** | `eipAuthorize` / `eseAuthorized` 跨越承诺边界 | 人类对 ChangeSet 的正式裁定门禁 (`AcceptChangeSet`) | `ExecuteCommitmentGate` -> 修改磁盘 Spec 树，冻结新 Baseline | 必须由人类明确触发接受动作，规范正本方发生物理落盘变更 | `ASWISH_V_002`, `ASWISH_V_005`, `tests-ehai-downstream-001-A.txt` | **PASS** |
| 10 | **RecoverableLineage** | `TEhaiTraceRecord` / 父子追溯链 | 决策链与基线谱系不可变可追溯 (`ParentBaselineId`) | `TAsWishBaseline.Lineage` + `TChangeSet.Decisions` | 每次 Baseline 冻结均携带前驱 Baseline ID 与内容指纹 | `ASWISH_V_003`, `tests-ehai-downstream-001-A.txt` | **PASS** |

---

## 二、A-2｜领域语义边界自查（防私货反向污染）

1. **私有概念下沉隔离**：
   AsWish 私有领域概念包括：`Intent`, `Spec`, `SpecNode`, `Tree` (Function/Module/View/Data), `Bundle`, `ChangeSet`, `Baseline`, `Requirement Decision`, `Snapshot`, `Evidence`, `Issue`。
2. **血统单向流动**：
   - 严格保持 `Common Semantic -> AsWish Domain Binding` 单向继承消费；
   - 公共层（`DeepBase.EHAI.Types` / `DeepBase.HB.Choice.Types`）完全不包含 AsWish 专有类型定义；
   - AsWish 中的框架否定（FR-AW-01）在公共层消费通用的 `eokFrameRejection`，在 AsWish 内部落地为 `SubmitFrameRejection`（标记 SpecNode 为 `frame_rejected` 并将高层需求引向上游 Function 树），公共层未出现任何 `SpecFrameRejection` 或 `TreeRejection`。

---

## 三、A-3｜Human Authority 与 Commitment Boundary 验证

1. **探索态与承诺态严格分离**：
   - 用户在 HB Choice Deck 上的 1..7 点击或键盘操作，在 AsWish 中仅触发 `ReviewChangeSet`（四层投影视角审阅），磁盘上的 Canonical Spec 树（`function-tree.yaml`、`module-tree.yaml` 等）保持 **100% 字节不变**（`ASWISH_V_001`、`ASWISH_V_006` 实测通过）。
2. **唯一的正本变更通道**：
   - 只有通过显式的 Human Sovereign Gate——`AcceptChangeSet(LCSId, Rationale)`，携带人类的正式决策理由与授权（`eseAuthorized`），系统才会跨越 `CommitmentBoundary`，执行正本树的更新与不可变 Baseline 的冻结（`ASWISH_V_002` 实测通过）。
3. **AI 提案绝不自动晋升**：
   - AI 输出或推理出的任何候选内容均被隔离在 `TCandidateIntent` / `TChangeSet` 沙箱中，不具备自我赋权或默认通过路径。

---

## 四、A-4｜0–9 Interaction Grammar 在 AsWish 中的真实语义

- **1–7（Choose）**：审阅与比较对应的候选方案/变更集，为人类评估提供结构化呈现，绝非自动决定；
- **8（Regenerate）**：在当前节点问题定义框架内，重新触发 Prompt 导出与探索；
- **9（HumanOverride / FrameRejection）**：
  - 子类型 1 & 2（候选否定/局部替代）：人类在当前框架内提出直接意图；
  - 子类型 3（框架否定 `eokFrameRejection`，FR-AW-01）：人类彻底拒绝当前节点的立论前提。在 AsWish 中，被否定节点标记为 `nsRejected`/`frame_rejected`，原始摘要保留不被篡改，新自然语言需求直接挂载至更上游需求节点（`ASWISH_V_004`、`ASWISH_V_009` 实测通过）；
- **0（Back / Exit）**：退出当前交互模式，不代表拒绝、不代表同意、不产生裁定，历史已有决策与 Baseline 完好无损（`ASWISH_V_008` 实测通过）。

---

## 五、A-5｜Human Source 与 AI Interpretation 溯源隔离

- `TChangeItem` 明确区分来源元数据：
  - `cstExplicit`：人类直接提出的明确需求；
  - `cstInferred`：AI 根据上下文逻辑推断衍生的结构化修改；
  - `cstUnknown`：尚未确定的项。
- 经过 YAML 存盘、重新加载、基线生成等整个生命周期，来源标记保持不可变与不漂移，禁止将 AI 推测在持久化后篡改为“人类提出”（`ASWISH_V_011` 实测通过）。

---

## 六、A-6｜Gate B 下传项 N-1～N-6 AsWish 专项核验

### AsWish-N1｜显式通配 Authority Scope '*'
1. **产生源头**：AsWish 全仓**不产生、不使用**通配权限 `'*'`；
2. **创建主体**：无；
3. **自由输入可达性**：否，用户自由输入被收敛在 `UserIntent` 文本字段；
4. **AI 输出可达性**：否，LLM 输出通过 `CandidateIngest` 强类型校验；
5. **外部导入/配置持久化恢复**：无；
6. **可信边界**：AsWish 为纯本地规范工具，所有承诺均由本地人类通过 `AcceptChangeSet` 显式确认；
7. **授权追溯**：人类通过 `AcceptChangeSet` 显式传入 `Rationale`，固化于 `TChangeSet.Decisions`；
8. **默认生成**：否。
- **源码检索证据**：归档原始 `git grep -n "'\*'" src/` 输出于 [`WO/evidence/git-grep-wildcard-aswish.txt`](file:///D:/_Progs/02Business/AsWish/WO/evidence/git-grep-wildcard-aswish.txt)（全仓源码仅 4 处命中，除密码掩码与路径非法字符外，绑定层仅作为 fail-closed 防护 `or (AChangeSetId = '*') then Exit`，零通配构造与调用）；
- **实测断言**：`ASWISH_V_012` 实测断言 `ExecuteCommitmentGate('*', ...)` 与 `ExecuteCommitmentGate('', ...)` 严格返回 `False`（fail-closed），且合法提交门禁产出的 `ScopeBoundary` 恒为具体 `'AsWish'`、`ContextId` 恒为具体 `ChangeSetId`，二者均不等于 `'*'`；
- **结论**：**NOT USED**（源码级检索证实 + `ASWISH_V_012` 实质断言双重确认）。

### AsWish-N2｜超过 7 个候选静默丢弃
- **全链路源码位置**：
  1. **候选摄入**：`src/services/AsWish.Services.CandidateIngest.pas:216-310`（`TAsWishCandidateIngest.Ingest`），完整解析与验证 YAML 文档节点，无任何静默丢弃或截断逻辑；
  2. **意图创建与呈现**：`src/controllers/AsWish.Controller.pas:1150-1285`（`TAsWishController.SubmitUserIntent`），构建 `TChangeSet` 时将全部变更项（`LItems.ToArray`）完整存盘（`:1280` `LIngest.SaveChangeSet`），并通过 `FRender.RenderChangeSetReviewPage`（`:1284`）完整渲染 4 层审阅界面，无静默上限过滤；
  3. **交互 Deck 槽位映射**：`src/services/AsWish.Binding.HB.pas:195-208`（`ProcessEhaiAction`），1..7 槽位定向审阅目标 ChangeSet（`ReviewChangeSet`），不涉及外部候选隐式过滤；
- **实测验证**：`ASWISH_V_012` 构造包含 8 项变更的 ChangeSet（`cs-test-n2-8items`），存盘并重新加载后，断言 `Length(Items) = 8`，实证全生命周期 0 静默丢弃、0 截断；
- **结论**：**ESTABLISHED**（源码全路径定位与测试实测验证）。

### AsWish-N3｜Candidate Key 不查重
- **机制原理**：AsWish 绑定层处理交互动作时，以具体变更集的 `ChangeSetId`（如 `cs-...`）为寻址依据，不以瞬时数字 Key 寻址（源码位置：`src/services/AsWish.Binding.HB.pas:184-207`）；
- **实测验证**：`ASWISH_V_012` 分别创建 `LCSIdA` 与 `LCSIdB`，均通过相同的数字按键（Key 1）触发 HB 候选预览动作，断言 `Trace A` 与 `Trace B` 分别严格绑定对应 ChangeSet ID（`Trace A <> Trace B`），实证同一瞬时 Key 在不同变更集间彻底免疫冲突与错绑；
- **结论**：**PASS**（`ASWISH_V_012` 实质断言验证）。

### AsWish-N4｜Covers() 内部使用 Now（时钟确定性）
- **机制原理**：AsWish 内部不调用 `Covers()`；其 Trace 生成仅使用 `Now` 构造人类可读 ID（如 `trace-aw001-20260915-0001`），决策有效性与 Baseline 指纹基于内容 SHA256 哈希，不依赖实时时钟；
- **实测验证**：`ASWISH_V_012` 验证针对同一 ChangeSet 多次执行 `ReviewChangeSet` 输出逐字节完全一致；对同一 HB 动作重复执行产生的 `TEhaiTraceRecord` 之 `SemanticEffect`、`IsCommitted`、`Key`、`Text`、`ContextId` 逐项恒等；冻结的 Baseline `ContentHash` 与 `RelationHash` 经 `VerifyBaseline` 验证具备 100% 确定性；
- **结论**：**PASS**（`ASWISH_V_012` 实测确定性通过）。

### AsWish-N5｜Demo 中性语义
- DeepBase Demo 中的 `Contact List` 属于 AXIS 领域词，AsWish 仓内无任何 `Contact List` 概念与依赖，无语义误导与冲突；
- **结论**：**NOT APPLICABLE**。

### AsWish-N6｜ExpiresAt = 0 双义消除
- **事实**：AsWish 的工程规范基线（`TAsWishBaseline`，`src/models/AsWish.Models.pas:335-350`）仅包含 `BaselineId`, `DecisionId`, `SnapshotName`, `TreeType`, `ContentHash`, `RelationHash`, `Lineage` 等不可变哈希与谱系属性，**无任何 `ExpiresAt` 字段**；AsWish 作为规范定义工具，基线属于永久有效的不变规格资产，不涉及临时租期或过期逻辑；
- **实测验证**：`ASWISH_V_012` 断言基线哈希存在且 `VerifyBaseline` 永久有效可验证；
- **结论**：**NOT APPLICABLE（AsWish 领域模型无 ExpiresAt 字段，不可变基线永不过期）**。

---

## 七、A-7｜测试执行结果与证据索引

本次针对 AsWish 执行了全量单元回归与针对 Gate C 专项验收套件（`ASWISH-V-001` ～ `ASWISH-V-012`）：

| Test Suite | Total Tests | Passed | Failed | Leaked | Skipped | Exit Code |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **AsWish Full Regression + Gate C Targeted** | **236** | **236** | **0** | **0** | **0** | **0** |

**原始证据快照**：
- 编译证据：[`WO/evidence/build-ehai-downstream-001-A-R1.txt`](file:///D:/_Progs/02Business/AsWish/WO/evidence/build-ehai-downstream-001-A-R1.txt)（Win64 编译完成，Exit Code = 0，日志中无 Error/Warning 行，0 Error, 0 Warning, 0 Hint）
- 测试实录：[`WO/evidence/tests-ehai-downstream-001-A-R1.txt`](file:///D:/_Progs/02Business/AsWish/WO/evidence/tests-ehai-downstream-001-A-R1.txt)（236 项全绿，Passed 236, Failed 0, Exit Code = 0）
- 通配检索：[`WO/evidence/git-grep-wildcard-aswish.txt`](file:///D:/_Progs/02Business/AsWish/WO/evidence/git-grep-wildcard-aswish.txt)（全仓源码检索证实通配权限未被使用，Exit Code = 0）

---

## 八、A-8｜Shared Capability Gap 审查

在 AsWish 承接验证过程中，经对 Language Common Contract 与 DeepBase/HB 运行时的全面实测核对：
1. **公共层能力表现**：公共层抽象（`CandidateSpace`, `ChoiceDeck`, `InteractionAction`, `OverrideKind`, `TEhaiTraceRecord` 等）完备、正交且无污染，充分满足 AsWish 对候选展示、框架否定、不可变审阅与承诺门禁的全部诉求；
2. **审查结论**：**`NO SHARED CAPABILITY GAP IDENTIFIED`**（未发现需要公共层上收或调整的新缺口）。

---

## 九、A-9｜AsWish R1 提交与隔离台账

```text
Upstream Baseline:   fc213b4696d92bc8a836ef644abaeb74f0daa79e (DeepBase, FROZEN)
Starting HEAD:       7af59e4eff1c9f60e519ef0b4c99f52cb8a2f2f4
R1 Commit SHA:       41471c8b974030c041e281d9e1bdf9466998a43d
Parent SHA:          7af59e4eff1c9f60e519ef0b4c99f52cb8a2f2f4
Owner Repo:          AsWish (D:\_Progs\02Business\AsWish)
Working Tree Status: Clean (0 dirty files in scope; 11 pre-existing untracked files isolated)
Changed Files:       6 files changed, 2480 insertions(+), 39 deletions(-)
```

**涉及文件清单**：
- `src/services/AsWish.Binding.HB.pas`（承诺门禁与拒绝入口增加空值及通配 `'*'` fail-closed 拦截）
- `tests/Test.AsWish.EHAI.Binding.pas`（ASWISH_V_012 消除恒真断言，落地 N1~N6 实质断言与确定性检验）
- `WO/evidence/build-ehai-downstream-001-A-R1.txt`（构建原始日志，含 Exit Code 0）
- `WO/evidence/tests-ehai-downstream-001-A-R1.txt`（236 测试全量回归原始日志，含 Exit Code 0）
- `WO/evidence/git-grep-wildcard-aswish.txt`（源码通配使用检索原始日志）
- `WO/WO-20260915-EHAI-DOWNSTREAM-001-A-AsWish-Gate-C-交付报告.md`（交付报告更新）

---

## 十、A-10｜Phase A R1 结论与阶段移交

```text
========================================================================
PHASE A R1 结论：
  AsWish Reference Product Binding 001 Gate C 最小整改项（A-R1-1, A-R1-2, A-R1-3）全部闭环。
  全量测试 236/236 PASS，消除所有恒真断言，落地真实确定性与错绑免疫断言，
  N-2 给出全链路源码定位并经测试实测验证，N-6 如实标定 NOT APPLICABLE。
  未修改 DeepBase，未修改 EHAI，未修改 AXIS。

工单状态建议：
  DEV COMPLETE — READY FOR INDEPENDENT REVIEW
========================================================================
```

*(本阶段整改完成，开发甲彻底退出 AsWish 仓，不作任何滞留修改，依序切入 Phase B R1 · AXIS)*
