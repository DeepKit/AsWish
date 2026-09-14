# WO-20260914-EHAI-BINDING-001R1-甲 · AsWish · EHAI Reference Product Binding 001 整改工单

> **工单编号**：WO-20260914-EHAI-BINDING-001R1
> **上游工单**：EHAI Reference Product Binding 001（Reference Product Binding 001）
> **承接角色**：开发甲（AsWish 仓）
> **工程主仓**：`D:\_Progs\02Business\AsWish`
> **上游依赖仓**：`D:\_Progs\02Business\DeepBase`
> **唯一上游契约**：`D:\_Progs\一元论\90-跨层组合\高效AI人机交互体系-EHAI\common-contract\EHAI-Language-Neutral-Realization-Contract-v0.md`（CANONICAL SSOT）
> **整改依据**：`D:\_Progs\02Business\DeepBase\CodeReview\20260914-EHAI-三工单独立终审报告.md`
> **工单性质**：终审 START（附修正）后的整改。**不重定义公共语义、不越界改公共层**
> **对本工单的裁定**：原交付**架构与边界成立**（git 可核、零跨仓、复用公共层），但**收口结论不成立**（自称 0 债务，实际存在 2 处 Profile 漂移与 1 处证据不可核验）

---

## 0. 一句话结论

AsWish 是三份工单中**最干净的一份**：20 条提交零 `DeepBase/` 路径、8 项 Tier C 用例真实注册且全部落在正确层级、Frame Rejection 未退化为"选项 4"。

它的问题**只在收口口径**——绑定映射表与自己的代码对不上，且把这两处漂移登记成了"0 债务"。因此本工单**不做架构改动**，只做对齐与如实记账。

---

## 1. 前置条件（未满足不得开工）

| 条件 | 说明 |
| :--- | :--- |
| **【硬前置】公共层符号基准** | 必须等 DeepBase 仓 `WO-20260914-EHAI-001R1` 的 **R-00** 产出 `docs\EHAI-Delphi-Symbol-Baseline.md`。**在此之前，禁止在本仓以任何方式自行"推测"或"固化"公共层类型名 / 枚举成员** |
| **【硬前置】HB 三态入口修正** | `DeepBase` 的 **R-04**（`SubmitFreeInput` 默认值改 `eokNone`）未完成前，本仓 `eokFrameRejection` 分支在**真实键盘路径**上不可达，不得基于"分支存在"下结论 |
| **【硬前置】工厂 Profile 参数化** | `DeepBase` 的 **R-05** 未完成前，`AW-R05` 无法执行 |
| 冻结期 | 本仓不得修改 DeepBase 仓任何文件；公共语义层任何变更一律走 DeepBase 工单 |
| 范围纪律 | 当前工作区有 10 项未提交改动，**PR 前须确认归属**，不属于本工单范围的不得顺带提交 |

---

## 2. 整改项清单

| 项 | 名称 | 严重度 | 前置依赖 |
| :--- | :--- | :---: | :--- |
| **AW-R01** | 按公共层符号基准全量对齐 | 必做 | DeepBase R-00 |
| **AW-R02** | 绑定映射表与代码的 Profile 漂移对齐 | BLOCKER | — |
| **AW-R03** | 三态收敛如实记账 | MINOR | — |
| **AW-R04** | Tier C 证据带上用例名 | MINOR | — |
| **AW-R05** | 调用点显式传 Profile | MAJOR | DeepBase R-05 |
| **AW-R06** | 真实键盘路径的 FrameRejection 端到端复验 | MAJOR | DeepBase R-04 |

---

### AW-R01 · 按公共层符号基准全量对齐【必做】

**问题**：本仓的绑定单元与测试单元直接 `uses DeepBase.EHAI.Types` 与 `DeepBase.HB.Choice.Types`（编译路径 `..\DeepBase\Core;..\DeepBase\VCL`），即**源码级耦合**。经核验本仓目前使用的符号名恰好是对的，但这是巧合——公共层此前不存在任何机器可校验的符号基准，而原工单的两份交付文档给出的还是**另一套幻影符号**（如 `emaHumanOverride`、`esHumanSelected`、`TEhaiChoiceCardinality`，全仓 0 命中）。一旦有人照那份文档改代码，本仓会立刻编译失败或被误导。

**精确修改点**：

- `src\services\AsWish.Binding.HB.pas`（第 35–36 行 `uses` 及全文符号引用）
- `tests\Test.AsWish.EHAI.Binding.pas`（第 25–26 行 `uses` 及全文符号引用）

**改法**：

1. 以 `DeepBase\docs\EHAI-Delphi-Symbol-Baseline.md` 为**唯一**接口真相源，逐符号核对本仓用到的全部公共标识符；
2. 在 `src\services\AsWish.Binding.HB.pas` 文件头注释中写明：本单元依赖的公共符号基准版本（文件名 + 生成时间 + 源文件 SHA256），便于后续漂移检测；
3. 建议在构建脚本中加一条"符号基准存在性检查"：基准文件缺失或哈希与 `DeepBase\Core\DeepBase.EHAI.Types.pas` 不匹配时，构建**警告**（不阻断，但必须可见）。

**验收标准**：

- ✅ 本仓引用的每一个公共符号都能在符号基准中检索到，**0 例外**；
- ✅ 文件头已登记基准版本信息；
- ✅ `tests\AsWish.Tests.exe` 232/232 仍全绿（无回归）。

**证据要求**：符号核对输出 + 全量测试日志。

---

### AW-R02 · 绑定映射表与代码的 Profile 漂移对齐【BLOCKER】

**问题（终审 M-03）**：绑定映射表是本工单交给主控的 Tier C 验收契约，但它与**自己的代码**对不上。逐行核验：

| 映射表声明（`WO\evidence\AUDIT-REQUEST-...-甲.md` 第三节） | 代码实际 |
| :--- | :--- |
| `1..7 (emaChoose)` → Profile **`eipJudge`**（第 44 行） | `AsWish.Binding.HB.pas:167-168` 传入 **`eipInform`** |
| `8 (emaRegenerate)` → Profile **`eipProvide`**（第 45 行） | 走公共层工厂 `CreateRegenerate`，该工厂在 `DeepBase.EHAI.Types.pas:523` 硬编码 **`eipInform`** |

**为什么必须修**：Profile 是决定介入效力的关键输入（契约 §2.2：`Choose + applicable Profile + Decision Context → formal typed Human act`）。表错一行，等于效力判据错一格。更严重的是**自相矛盾**：候选选择以"告知（Inform）"画像下发，却产出"判断已记录（`eseJudgmentMade`）"效应——Profile 与 Effect 不同源。

**精确修改点**：

- `WO\evidence\AUDIT-REQUEST-EHAI-Reference-Product-Binding-001-甲.md`：第 44 行（`1..7` 行）、第 45 行（`8` 行）
- `src\services\AsWish.Binding.HB.pas`：第 167–168 行（`else` 分支的 `CreateCandidate(..., eipInform, ...)`）

**改法**：二选一，**但必须保持单一真相源**：

- **方案 A（推荐）**：改代码。候选选择在语义上确实是"人类主权裁决"，把 `AsWish.Binding.HB.pas:167-168` 的 `eipInform` 改为 **`eipJudge`**；`8`（Regenerate）在 DeepBase R-05 完成后由调用点显式传 **`eipProvide`**。表保持不变。
- **方案 B**：改表。把两行改为 `eipInform`。**不推荐**——`1..7` 产出 `eseJudgmentMade` 却声明 Inform 画像，Profile↔Effect 不自洽的问题依然存在。

无论选哪个，改完必须重跑 Tier C，确保用例中的 Profile 断言与最终值一致。

**验收标准**：

- ✅ 映射表中每一行的 Profile 值与代码实际传入值**逐格一致**；
- ✅ `1..7` 的 Profile 与效应（`eseJudgmentMade`）语义自洽；
- ✅ Tier C 全绿。

**证据要求**：映射表 diff + 代码 diff + 测试日志。

---

### AW-R03 · 三态收敛如实记账【MINOR】

**问题（终审 n-03）**：`src\services\AsWish.Binding.HB.pas` 第 226–242 行，`eokCandidateReject` 与 `eokAlternativeExpression` 走**同一分支、同一 `SubmitUserIntent` 调用、同一 `eseDataProvided` 效应**，仅 `eokFrameRejection`（第 210 行）分流。即：公共层的三态在 AsWish 侧实际收敛为**两态**。

这本身是可接受的产品侧简化（AsWish 的领域处理确实相同），但必须在台账中**显式登记**，而不是隐含在代码里。

**精确修改点**：`WO\evidence\AUDIT-REQUEST-EHAI-Reference-Product-Binding-001-甲.md` 第三节与第七节

**改法**：在映射表中明确写出「`eokCandidateReject` 与 `eokAlternativeExpression` 在 AsWish 领域侧收敛为同一处理（`SubmitUserIntent` + `eseDataProvided`），此为**产品侧有意简化**，非语义丢失；三态区分能力由公共层与 HB 层保证」。

**验收标准**：✅ 台账中存在该显式声明；✅ 与代码行为一致。

---

### AW-R04 · Tier C 证据带上用例名【MINOR】

**问题（终审 m-05）**：`WO\evidence\tests-ehai-binding-001.txt` 是 DUnitX 默认点阵输出（`Tests Found: 232`），**不含测试名**。8 项 `ASWISH-V-001~008` 用例本身真实存在（`tests\Test.AsWish.EHAI.Binding.pas` 中 8 个 `procedure`，已注册于 `tests\AsWish.Tests.dpr:40`），但这份证据**无法证明它们被逐一执行并通过**——"证据不能自立"。

**精确修改点**：重新产出 `WO\evidence\tests-ehai-binding-001R1.txt`

**改法**：用 DUnitX 的 verbose / 用例名输出模式（或按 fixture 过滤运行）重跑，输出中须含每个用例名与结果（如 `[PASS] ASWISH_V_004_Frame_Rejection_Scenario_FR_AW_01`）。

**验收标准**：

- ✅ 新证据文件中可检索到 `ASWISH_V_001` ~ `ASWISH_V_008` **全部 8 个用例名**，且逐一标注通过；
- ✅ 总数仍为 232/232（0 Failed / 0 Leaked / 0 Errored）。

**证据要求**：`D:\_Progs\02Business\AsWish\WO\evidence\tests-ehai-binding-001R1.txt`（原始 stdout）。

---

### AW-R05 · 调用点显式传 Profile【MAJOR】

**前置**：DeepBase `WO-20260914-EHAI-001R1` 的 **R-05** 完成（工厂 Profile 参数化）。

**问题（终审 M-04 的 AsWish 侧）**：本仓调用 `TEhaiInteractionAction.CreateRegenerate` / `CreateOverride` / `CreateExit`（`AsWish.Binding.HB.pas` 第 160、162、165 行）时，Profile 由**公共层工厂内部硬编码**填充。等于把产品自己的介入画像决定权交给了公共层。

**改法**：R-05 完成后，三个调用点改为显式传入 Profile，值由 AsWish 的领域语义决定（并同步写进 AW-R02 的映射表）。

**验收标准**：✅ 三个调用点均显式传 Profile；✅ 映射表与之一致。

---

### AW-R06 · 真实键盘路径的 FrameRejection 端到端复验【MAJOR】

**前置**：DeepBase **R-04** 完成。

**问题**：本仓的 Frame Rejection 正确性目前是**单元级**证明的（`ASWISH-V-004` 构造 `eokFrameRejection` 后调用绑定）。但真实路径上，人类在 HB 控件里键入"这些都不是，这个模块本身就不该存在"时，走的是 HB 的 `SubmitFreeInput` 遗留重载——而该重载在修正前硬编码 `eokAlternativeExpression`，**框架否定根本到不了本仓的 `eokFrameRejection` 分支**。

**改法**：DeepBase R-04 落地后，补一条端到端复验（可仿照现有 `ASWISH-V-005` 的全链路风格）：从 HB 控件自由输入 → 三态标记 → 绑定分流 → `SubmitFrameRejection` → ChangeSet `IsFrameRejection = True`，验证 `mod-orders` 未被污染为选项 4。

**验收标准**：

- ✅ 端到端链路中，本仓确实观测到 `eokFrameRejection`（而非 `eokAlternativeExpression`）；
- ✅ `FR-AW-01` 场景处置结果与既有断言一致。

**证据要求**：新增用例 + 带用例名的运行日志。

---

## 3. 严禁事项（边界纪律）

```text
禁止 重定义 0–9 / HumanOverride / FrameRejection / Regenerate / Back
禁止 在本仓新建任何公共交互语义枚举或 0–9 映射表
禁止 修改 DeepBase 仓任何文件（含 Core / VCL / FMX / Tests）
禁止 把 AsWish 领域模型（TCandidateIntent / TChangeSet / SpecNode / 规范树 / Accepted Baseline）上收到 DeepBase / HB / Common Contract
禁止 把公共符号"顺手统一"成自己觉得更好听的名字
禁止 在未拿到 DeepBase 符号基准前冻结本仓接口
禁止 在 Profile 漂移未修完的情况下宣告 CLOSE
```

**本仓仍然是 Reference Product Binding 001**：

```text
EHAI → Language Common Contract → DeepBase Delphi → HB → AsWish Domain Binding (001)
```

---

## 4. 交付物与证据归档

| 交付物 | 路径 |
| :--- | :--- |
| 修订后的审计申请报告（含映射表 / 台账 / 收敛记账） | `D:\_Progs\02Business\AsWish\WO\evidence\AUDIT-REQUEST-EHAI-Reference-Product-Binding-001-甲.md` |
| 带用例名的 Tier C 证据 | `D:\_Progs\02Business\AsWish\WO\evidence\tests-ehai-binding-001R1.txt` |
| 构建证据（GUI / CLI / Tests 三端） | `D:\_Progs\02Business\AsWish\WO\evidence\build-ehai-binding-001R1.txt` |
| 绑定单元（含基准版本头注释） | `D:\_Progs\02Business\AsWish\src\services\AsWish.Binding.HB.pas` |
| Tier C 测试单元 | `D:\_Progs\02Business\AsWish\tests\Test.AsWish.EHAI.Binding.pas` |

**证据纪律**：所有数字必须可追溯到原始日志；文档内自报的 PASS 文本不作为证据。

---

## 5. 验收清单

| # | 验收项 | 判定 |
| :--- | :--- | :---: |
| 1 | 已拿到 DeepBase 公共层符号基准，并逐符号核对完毕（0 例外） | ☐ |
| 2 | 绑定单元文件头已登记基准版本（文件名 + 生成时间 + SHA256） | ☐ |
| 3 | 映射表与代码的 2 处 Profile 漂移已对齐（逐格一致） | ☐ |
| 4 | `1..7` 的 Profile 与 `eseJudgmentMade` 语义自洽 | ☐ |
| 5 | 三态收敛已显式记账 | ☐ |
| 6 | 新证据含 `ASWISH_V_001~008` 全部 8 个用例名与结果 | ☐ |
| 7 | 三个工厂调用点已显式传 Profile | ☐ |
| 8 | FrameRejection 端到端路径复验通过（真实 HB 入口可达） | ☐ |
| 9 | 全量测试 232/232（0 Failed / 0 Leaked / 0 Errored） | ☐ |
| 10 | GUI / CLI / Tests 三端 0 Error 编译 | ☐ |
| 11 | 提交隔离：每个提交仅含本工单范围文件，无跨仓路径 | ☐ |
| 12 | 遗留项台账如实登记（**不得再出现"NIL / 0 债务"**，除非确实清零并有证据） | ☐ |

**全部 12 项打勾后方可宣告本工单 CLOSE**；存在未清项一律禁止 CLOSE。

---

## 6. 依赖与顺序

```text
【等待】DeepBase R-00（符号基准）  ──→  AW-R01  ──→  AW-R02 / AW-R03 / AW-R04
【等待】DeepBase R-05（Profile 参数化） ──→  AW-R05
【等待】DeepBase R-04（SubmitFreeInput）──→  AW-R06
                                                    │
                                                    ▼
                                              全量回归 + 隔离提交 + 收口
```

**可提前并行**：`AW-R03`（记账）与 `AW-R04`（证据格式）不依赖任何前置，可立即开始。
