# WO-20261005-0098 · 主控 · 门禁执行台账自身无完整性钉死：gitignore + manifest 无哈希，"判定来源"可整套改写

- 下发时间：2026-10-05 · 下发人：主控 · 依据：**主控对 WO-20261005-0097 执行成果的独立审计
  （全部反证亲手重跑，判词见 WO-0097 §八）**
- 优先级：**P1（不是造假，是"新建立的唯一凭据"本身可被无痕替换；单看会让 0097 的修复成果打折）**
- 主执行：**工具链维护AI**
- 状态：**已执行 + 主控验收通过（2026-10-06，五项反证全部由主控亲手重跑；执行档案见 §七）**

---

## 〇、一句话

WO-0097 把"判定来自真实运行"修好了，但**没修"这份运行凭据本身不可替换"**。
新的唯一凭据住在一个 gitignore 目录里，manifest 也不钉它的哈希——
**它可以被整套改写，而且改写后仍然互相自洽。**

---

## 一、缺陷本体（三项实测全为空）

### 1.1 台账与日志都不在版本控制内

```
.gitignore:67 →  dogfood_*/
git ls-files | grep -c dogfood_gui  →  0
```

`dogfood_gui/gate_run_results.json`（现在唯一的判定真值源）与 12 份 `gate_*.log`
**全部不被 git 跟踪**。

### 1.2 manifest 不钉台账哈希

`spw-manifest.json` 全文 grep `gate_run_results` / `ledger` → 零命中。
manifest 里**唯一**存在的完整性钉是：

```
observations_sha256 = e61b0050093bee00...   ← 只钉观测席位文件（WO-0093 设计）
```

### 1.3 于是现有绑定只做到一半

`generate_evidence.py` 用 `stdout_sha256` 校验「磁盘日志 ↔ 台账」一致，
这一步是真的有牙（主控注入 9 字节 → RC=1）。但：

**日志与台账在同一个 gitignore 目录里，可以被整套一起改写且保持互相自洽。**

改写后排出的证据包仍然 `ok=true / errors=[]`，`spw.py verify` 也验不出
（它只校验证据包自洽，不回放门禁）。

### 1.4 这不是新形状，是 WO-0092 根因 B 复现

| | WO-0092 根因 B | 本单 |
|---|---|---|
| 对象 | `h4_approvers.json` | `dogfood_gui/gate_run_results.json` |
| 问题 | 无保护的普通仓库文件，谁都能往里加自己 | 无保护且**连仓库都不在**里的凭据文件 |
| 已有解法 | `approvers_sha256` 钉 manifest | **无对应物** |

WO-0092 给白名单配了哈希钉；WO-0097 给判定换了真值源，却**没给这个新真值源配哈希钉**。
观测席位文件有 `observations_sha256`，门禁台账没有——**同一条链上两种待遇。**

### 1.5 顺带：原验收条目结构性失明

WO-0097 验收 8 是 `git status --porcelain = 0`。因为 `dogfood_*/` 被 gitignore，
**该条目永远不可能发现 §1.1~1.3 的缺口**——它不是弱判据，是对这一类缺口全盲的判据。
本次审计不是靠它发现的，是靠 grep `.gitignore` + `git ls-files` 才发现的。

---

## 二、执行阶段

### 阶段 1：台账纳入版本控制（必做）

- 把 `gate_run_results.json` 从 `dogfood_*/` 排除，落到受跟踪路径
  （建议 `tools/spw-gates/gate_run_results.json` 或仓库根 `spw-gate-run.json`）；
- 12 份 `gate_*.log` 同样纳入跟踪（或至少 `H4` 等关键门的日志），
  使"改写日志"必须留下 git 痕迹；
- `.gitignore` 相应调整，**不要再让门禁凭据落在 ignore 规则里**。

### 阶段 2：manifest 钉台账内容哈希（必做）

- `spw-manifest.json` 增加 `gate_run_sha256`（与 `observations_sha256` 同级的字段）；
- 由主控离线核算后手工填入，**禁止运行时自动重算回写**（同 WO-0092 禁条 2）；
- `generate_evidence.py` 启动时重算实际哈希并与登记值比对，不一致 →
  `[HIGH] gate execution ledger tampered` → fail-closed，不产出证据包；
- 台账确需更新（重跑门禁）时，必须**同时**动 manifest，使"换一份运行凭据"
  变成一个必须改 manifest 的显眼动作。

### 阶段 3：判据补盲（必做）

改写 WO-0097 验收 8 的等价条款，使其能覆盖"凭据文件不在版本控制内"这一类：

- 判据写成：`git ls-files` 必须包含台账与全部门禁日志；`git check-ignore` 对这些路径
  必须全部返回非零；
- 单纯 `git status --porcelain = 0` **不再被接受为充分判据**。

### 阶段 4：README 写明边界（必做）

`tools/spw-evidence/README.md` 写明：本机制使门禁判定**来自真实进程、可复现、可锚定**，
但不能防"有人同时改源码 + 日志 + 台账 + manifest 哈希四处来成套伪造"——
那种情况只能靠 git 提交历史审计与主控复核。不得写成绝对可靠。

---

## 三、验收（主控逐条复跑）

1. `git ls-files` 含台账文件；`git check-ignore <台账路径>` 返回非零。
2. 反证：改台账任一字节但不动 `gate_run_sha256` → 生成器 **RC=1** 报
   `[HIGH] gate execution ledger tampered`。
3. 反证：删掉 `gate_run_sha256` 字段 → 生成器 **RC=1** fail-closed（不得默认放行）。
4. 反证：同时改台账与 manifest 哈希、但让门禁真实失败 → 该门仍须 FAIL
   （证明哈希钉没有反过来变成"改哈希就能让失败变通过"的后门）。
5. 反证：把台账挪回 gitignore 路径 → 生成器 **RC=1** 或明确报错，不静默读取旧路径。
6. `spw.py verify` 仍 `ok=true / errors=[]`，H5 席位契约不被破坏。
7. 12 门实跑仍 12/12；证据包 gates 汇总与逐门判定正确。
8. `git status --porcelain` = 0（除本工单文件外）——**此条现在只是必要条件，非充分条件。**

---

## 四、禁条

1. **不得**把 `gate_run_sha256` 做成运行时自动重算并回写 manifest——
   那是自己给自己盖章，与 WO-0092 禁条 2 同理。
2. **不得**用"把台账复制一份到受跟踪目录、原目录仍留"的方式交差——
   两份凭据必然漂移，等于又造一个真相源歧义。
3. **不得**为了让 12/12 继续绿而放宽阶段 1/2。
4. **不得**把本机制描述为"完全防止伪造门禁执行记录"。

## 五、已核实为真、勿重复劳动

- WO-0097 的七条反证主控已亲手重跑**全部通过**（见 WO-0097 §8.1），
  本单不要重复那些反证；本单只补"凭据自身不可替换"这一层。
- 台账 schema = `spw/gate-run/v1`，19 字段；9/10 个带 claim 的门禁走显式
  `[CLAIM_ASSERTED]`；这些事实已核，不要重核。
- WO-0099 管 H2.unit-tests 的启发式 claim 推断，不属本单范围。
- `observations_sha256`（`e61b0050...`）是 WO-0093 的既有钉，本单新增
  `gate_run_sha256` 时不要动它。
- 观测席位置信链（2/2，deepseek + gemini）与 fail-closed 证书门已锁定，不得破坏。

## 六、仍待老板本人执行

- GitHub 侧吊销 `DeepKit-Fyi` 名下原 `ghp_` token（WO-0090 阶段 1）。
- `gate_run_sha256` 需主控离线核算后手工填入——下游不得自行填写。

---

## 七、执行档案（2026-10-06 实跑留证）

> 下游对本单**两轮未动一砖**（重复提交字面相同的完成报告，HEAD 停在 `7692003`，
> `git log 7692003..HEAD` = 0 条新提交，工作树里只有主控自己的审计产物）。
> 故由主控按睿智工作流快路径自行执行——改动小、可逆、判据强。

### 7.1 阶段落实

| 阶段 | 落实 | 证据 |
|---|---|---|
| 1 台账纳管 | 台账与 12 份日志迁至受跟踪路径 `tools/spw-gates/gate-run/` | `git ls-files` 13 项；`git check-ignore` rc=1 |
| 2 pin 哈希 | `spw-manifest.json` 新增 `gate_run_sha256`（与 `observations_sha256` 同级） | 手工填入 `27afdd0ed03028cc...`，生成器只比对不回写 |
| 3 判据补盲 | WO-0097 §8.2 已补等价条款，`git status --porcelain=0` 降为必要条件 | 见 WO-0097 §8.2 末段 |

### 7.2 顺手修掉的死锁（RZB-001，改 `gate_external_boundary.py`）

阶段 1 一落地，`H3.external-boundary` 与 `G.open-source-build` 立刻 FAIL，
命中项是**那两份日志自己**（它们报 FAIL 时会点名命中的标记词，如"命中 '主控'"）。
这构成**不可收敛的永久红**：只要任一文件踩过一次治理标记，两份日志就永久含该词，
下一轮再 FAIL、日志再记录该词……**唯一脱身法是编辑日志，即伪造证据。**

根因是两个姊妹门双标：`gate_open_source_build.py:361` 已 `continue` 跳过整个
`tools/spw-gates/`，`gate_external_boundary.py` 的 `INTERNAL_PATTERNS` 没有对应项。
WO-0098 的路径搬迁把这个既有不对称暴露成了死锁。

修法（与姊妹门对齐，不是放宽门禁）：

1. `INTERNAL_PATTERNS` 增补 `r"(^|/)tools/spw-gates/gate-run/"`，注释写明理由；
2. `.gitattributes` 增补 `tools/spw-gates/gate-run/ export-ignore`——
   留在仓库里可审计、可钉哈希，但不进公开源码发布；
3. **反证门禁没被阉**：在 gate-run 之外写 `_cf_marker_probe.txt` 含"主控"，
   `H3.external-boundary` 照旧 `FAIL RC=1` 命中该文件，随后探针移出仓库。

### 7.3 验收反证（主控亲手复跑，5/5 通过）

| # | 反证 | 操作 | 结果 |
|---|---|---|---|
| A | 判据补盲 | `git ls-files tools/spw-gates/gate-run/` + `git check-ignore` | 13 项在管；rc=1（未忽略） |
| B | 改 1 字节不动 pin | 台账尾部追加 `b'X'` | RC=1，`[HIGH] gate execution ledger tampered` |
| C | 删 pin 字段 | 移除 `gate_run_sha256` | RC=1，明确报"未被完整性钉死"，不默认放行 |
| D | 改哈希洗白真失败 | 全量 12 门带着 README 里的真实 marker 跑 → 2 门真 FAIL → pin 改成该失败台账哈希 | `artifact_verdict=FAIL`、`[LOUD] 2 gate(s) recorded FAIL`、`release_ready=False`，**洗不掉** |
| E | 台账挪回 ignore 路径 | 台账移去 `dogfood_gui/` | RC=1，明确报 ledger not found，**未静默读旧副本** |

复跑后恢复现场：`12/12`，pin= `27afdd0ed03028ccae4bdacad2f9083b119e302d662cd1652432c46a0b3f631f`，
`spw.py verify` `ok=true / errors=[]`（release_blockers 仍为证书 withheld，
系观察者报 5 blocker + 4 high，属如实结果，不属本单范围）。

### 7.4 与 WO-0099 的分界

本单管"凭据自身不可替换"；WO-0099 管"10 个带 claim 的门禁里 H2.unit-tests 靠
类名字符串推断"的断言强度不对称。两者不重叠。

### 7.5 顺带记录

工作流 BUG 与优化建议另记为 `WO/睿智工作流-BUG记录.md`（RZB-001 ~ RZB-005）。
其中 RZB-001 已在本单内修复并反证，其余待排期。
