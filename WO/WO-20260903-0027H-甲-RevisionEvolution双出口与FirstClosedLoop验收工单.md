# WO-20260903-0027H · 甲（开发AI）· Human Judgment → Revision / Evolution 双出口 + First Closed Loop 验收

- 下发时间：2026-09-03 (GMT+8)
- 下发人：主控AI
- 承接方：**甲（开发AI，AsWish 仓库）**
- 工作仓库：`D:\_Progs\02Business\AsWish`
- 优先级：P0
- 依赖：`0027F`（Evidence）+ `0027G`（Difference + P2 修复）已交付
- 依据：`docs/07.工程-工程路线与Dogfood验收.md` §6.8b.3（Q3 结论）+ §6.9 / §6.10 + §一之三硬标准 + Q4 候选 B'（§6.8b.4，已采纳）
- 门禁：非睿智轻量门禁；双闸门（Engineering Green + Dogfood Green）+ **OJP Acceptance（本票涉 Human Judgment，必过）**；单 commit ≤200 行；build/test 原始输出存档；主控 APPROVED/RETURNED，未过不得 CLOSE

---

## 一、目标

把 `difference.yaml` 呈到人类面前，由人类做出判断，并走通**双出口**：

- **Revision（不可接受）**：回到 Human Intent，**重走完整链**（intent → changeset → review → accept → new baseline）；
- **Evolution（可接受/更好）**：记「接受差异」决策，**从当前实现现实直接冻结 New Baseline**（lineage parent = 当前 Baseline）。

并以此完成 **First Closed Loop 验收**：同一个真实任务贯穿 `0027A → 0028 → 0027F → 0027G → 0027H`，至少真实跑通**一次第二轮 Revision**（硬标准 §一之三）。

> 一句话：**差异摆在人面前，人说了算；改就真重走一遍链，认就直接认下现实——两路都不新建结构。**

## 二、Q3 红线（老板已裁定，违者 RETURN）

**不加任何新结构**。双出口都只复用现有机制：

| 维度 | Revision | Evolution |
|---|---|---|
| 人类判断 | 我要调整（Unacceptable） | 更好，我接受（Acceptable / 更好实现） |
| Decision | 复用 `TSpecDecision` 记「修订」决策 | 复用 `TSpecDecision` 记「接受差异」决策 |
| New Baseline | 从**新的 Human Intent** 重走链后 `CreateBaseline` | 从**当前实现现实**直接 `CreateBaseline`（lineage parent = 当前 Baseline） |
| 新建结构 | **禁止**（违 §十禁令） | **禁止**（违 §十禁令） |

**语义区分实现**：仅用 `TSpecDecision.DecisionType`（`src/models/AsWish.Models.pas:63` 现有枚举）扩展最小枚举值（如 `dtAcceptDifference`）或现有字段语义承载，**不新增字段、不新增第二套状态机、不新增独立 Baseline 实体**。取哪条路由开发裁量，取最短路径，交付报告注明。

## 三、范围一 · Human Judgment（6.9）

- 呈现：`difference.yaml` 可读呈现（CLI 即可，v0 不要求 GUI）；
- 裁决：复用现有 `Decisions` 服务记录到差异项（`TargetNodes` 指向差异 `node.id`），输出 `Acceptable / Unacceptable / Unresolved` 三值之一；
- **AI 不得代替人类判断**（OJP）。

## 四、范围二 · B' GUI 新建意图入口（Q4 已采纳，第二轮 Revision 的 Dogfood 载体）

补 §6.8b.4 核实的真实缺口：`ReviewChangeSet` 必须先有已存在 ChangeSet（`LoadChangeSet` 找不到即返回 "No change set found"），GUI 的 `9` 只能改已有意图。

- 新增「**从任意节点/空白发起新意图**」的 GUI 入口，打通 GUI 侧完整 `intent → changeset → review` 链；
- 入口落于 Decision Surface 既有 **0–9 交互框架**（`src/services/AsWish.Services.Render.pas`，0027D-R1 已实现），**不新建交互模式**；
- 复用 0027A 的 CandidateIngest 链路与 `FOnSubmitIntent` 既有接线（`src/providers/AsWish.Providers.MainView.pas:221-223`）。

## 五、CLI

裁决与双出口各配最小子命令（仿 `baseline` 模式，具体命名开发裁量）：

```text
aswish judge    <project-dir> <baseline-id>   # 呈现差异 + 记录人类裁决
aswish evolve   <project-dir> <baseline-id>   # Evolution 出口：接受差异 → 直接冻结 New Baseline
```

Revision 出口不需要新命令——它就是经 B' 入口重走既有链。

## 六、最小测试清单（DUnitX）

1. Unacceptable 裁决 → Decision 落盘、`TargetNodes` 指向差异项；
2. Acceptable 裁决 → `evolve` 从当前实现现实冻结 New Baseline，lineage parent = 当前 Baseline；
3. Evolution 新基线与当前基线哈希**不同**（除非实现零差异）且可 `VerifyBaseline`；
4. Revision 路径复用第一轮全部机制（不新建流程）：第二轮 Accept 后新基线 lineage 可回溯到第一轮；
5. `Unresolved` 可持久化，不强制二选一；
6. 双出口均无新增实体类型（结构回归：协议文件枚举/字段 diff 为证）；
7. B' 入口：从无 ChangeSet 的节点发起意图 → 走到 Review 页（GUI 链路可测部分用现有 Render 测试模式覆盖）；
8. `difference.yaml` 缺失时 `judge`/`evolve` fail-closed。

> 全 PASS 且既有基线不回退。原始 build/test 输出存档 `WO/evidence/`。

## 七、验收

### Engineering Acceptance
- 测试全绿；build 0 Error/0 Warning 原始输出存档；结构回归证明零新增实体。

### Dogfood Acceptance（First Closed Loop 硬标准，§一之三）
1. **同一个真实任务**贯穿全链（不换 Demo）；
2. **第二轮 Revision 真实完整跑通**：经 B' 入口发起真实修订意图 → changeset → human review/accept → Baseline v2，且 v2 与第一轮可对比、可追溯；
3. **Evolution 出口真实跑一次**：对某轮差异做出真实「接受」判断并冻结新基线（进化是证明 AsWish 不是"防错工具"的关键证据）；
4. 人类判断结果**不是预设的"通过"**（至少一处真实 Unacceptable 或真实修订）。

全部证据（命令原始输出）存档 `WO/evidence/`。

### OJP Acceptance（必过）
- [ ] Human 判断对象明确（`difference.yaml` 各项）
- [ ] 双出口 Baseline 均可追溯（lineage → Decision → ChangeSet → Intent / parent Baseline）
- [ ] 可重复查看（重载同 hash）
- [ ] AI 未代替 Human 判断
- [ ] 未新增平行实体 / 第二套状态机

## 八、非目标

不做：Conversation Surface（§一边界）；差异自动裁决；自动回滚；四投影全铺开；SaaS/协作。

## 九、完成后进入

First Closed Loop 验收报告（对照 §一之三三硬标准逐条打勾）→ 依 `docs/19.工程-下一阶段研发计划-FirstClosedLoop.md` 评估下一阶段。

## 完成定义

> 一个真实的人，对着真实任务的差异，做出真实判断：不接受就经 GUI 重走整条链再冻一个基线，接受就一条命令把现实认作新基线——两条路都没有新结构，且全程证据落盘、任何一步都可回溯到最初的那个意图。
