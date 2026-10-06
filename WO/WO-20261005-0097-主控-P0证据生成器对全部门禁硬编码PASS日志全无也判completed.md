# WO-20261005-0097 · 主控 · 【P0】证据生成器对全部门禁硬编码 PASS：日志全无也判 completed / exit_code=0

- 下发时间：2026-10-05 · 下发人：主控 · 依据：**主控逐行复核 `tools/spw-evidence/generate_evidence.py`
  后做隔离复现（抽走 H4 日志 → 仍判 PASS），失败形态与 WO-20261004-0091 同构但在更上游**
- 优先级：**P0（这是封版证据的生产工具本身；它让"12 道门全 PASS"这句话永久失去意义）**
- 主执行：**工具链维护AI**
- 状态：**executed（工具链维护AI 实跑完毕，执行档案见 §七；主控审计判词见 §八）**

---

## 〇、一句话

**证据包说"12 道门全 PASS"这句话，目前与门禁实际跑没跑、过没过，没有任何关系。**

---

## 一、缺陷本体（已逐行定位 + 隔离复现）

### 1.1 源码位置：`tools/spw-evidence/generate_evidence.py:456-487`

```python
gate_records = []
for g in manifest.get("gates", []):
    gid = g["gate_id"]
    safe_gid = gid.replace(".", "_")
    log_name = f"gate_{safe_gid}.log"
    log_file = ROOT / "dogfood_gui" / log_name

    stdout_bytes = log_file.read_bytes() if log_file.is_file() else b""   # 缺失→空
    stdout_sha256 = hashlib.sha256(stdout_bytes).hexdigest()
    ...
    record = {
        "gate_id": gid,
        "required": bool(g.get("required", True)),
        "execution_status": "completed",   # ← 字面量
        "verdict": "PASS",                 # ← 字面量，无任何分支
        "claims": list(g.get("claims") or []),
        "command": [str(x) for x in g["command"]],
        "exit_code": 0,                    # ← 字面量
        "stdout_sha256": stdout_sha256,
        "stderr_sha256": hashlib.sha256(b"").hexdigest(),   # ← 恒为空串哈希
        "stdout_bytes": stdout_len,
        "stderr_bytes": 0,                 # ← 字面量
        "stdout": stdout_text,
        "stderr": "",                      # ← 字面量
        "truncated": False,                # ← 字面量
    }
```

另 `:520` 还有一处 `"artifact_verdict": "PASS"`，同为字面量。

**它不跑门禁，只读 `dogfood_gui/gate_<id>.log` 的 stdout 文本，
然后把判定、退出码、执行状态全部写死成 PASS / 0 / completed。**

### 1.2 隔离复现实测（2026-10-05，跑完已还原）

操作（可逆，仅改名一个日志文件，其余未动）：

```
mv dogfood_gui/gate_H4_bypass-patterns.log dogfood_gui/gate_H4_bypass-patterns.log.hidden
py -3 -X utf8 tools/spw-evidence/generate_evidence.py
```

结果：

```
H4.bypass-patterns → verdict: PASS | exit_code: 0 | status: completed
                     stdout_bytes: 0 | stdout_sha256: e3b0c442...（空串哈希）
artifact_verdict: PASS
```

**一道门彻底没有任何输出，证据包判定它 PASS。** 已还原日志并复原证据包
（复核 H4 stdout_bytes 回到 10258，coverage 2/2，cert 仍 withheld）。

### 1.3 这意味着什么

把 §1.2 的结论推到极限：如果 H2.compile-build 真的编译失败，
只要 `dogfood_gui/gate_H2_compile-build.log` 存在（哪怕是失败输出），
证据包照写 `verdict: PASS, exit_code: 0`。
`spw.py verify` 也会 `ok=true`——它只校验证据包的**自洽性**，
不会重跑门禁，所以它验不出这件事。

**WO-0091 是下游自封批准人；本单是审计装置自己开了一张永久全绿的门禁表。**
比 WO-0091 更上游：WO-0091 污染的是台账，本单污染的是"门禁到底过没过"这个
最基础的输入。

### 1.4 与 WO-0095 / WO-0096 的分界（不要混）

| 工单 | 管什么 |
|---|---|
| **本单 0097** | 判定与退出码是**假的**（字面量）→ 必须改成实跑真值 |
| WO-0095 | 判定本身是实的，但缺**逐门时间戳 / subject 绑定 / 实断言 claim** → 可定位性 |
| WO-0096 | 观测材料侧的同形状问题（`build_obs_material_v2.py:45-48`）→ 材料保真 |

三单叠加才是完整的"门禁结果可信"链。**先修本单**，否则 0095 补的锚点锚在假判定上。

---

## 二、执行阶段

### 阶段 1：判定必须来自真实进程（必做，本单核心）

`generate_evidence.py` 不得再产出任何未经运行产生的判定：

- 方案 A（推荐）：**生成器自己跑**。按 manifest 的 `gates[*].command`
  逐个 `subprocess.run`，取真实 `returncode` 与 `stdout/stderr` 字节，
  判定由退出码与门禁自身输出推导（门禁脚本已用 RC=0/1 表意，直接采信 RC）。
- 方案 B：生成器只**消费**运行器产物。`run_all_gates.py` 落一份
  `spw/gate-run/v1` JSON（每门含 argv / returncode / stdout 全文 / stderr 全文 /
  起止时间 / subject_sha256），生成器只读它，读不到即失败。
- 两方案都要求：**找不到真实运行依据 → 生成失败**，不得回退到 PASS、不得回退到空表。

### 阶段 2：fail-closed 而非 fail-pass（必做）

- 任一门 `returncode != 0` → 该门 `verdict=FAIL`，进 `degradation_reasons`，
  `release_ready=false`；
- 任一门无运行依据 → 生成器 `sys.exit(1)`，**不产出证据包**；
- `stderr` 为空但 `stderr_bytes` 非 0、或反之 → 自证失败。

### 阶段 3：日志与判定的互相绑定（必做）

`stdout_sha256` 必须与"该次运行实际产生的 stdout 字节"同源；
不允许"读一个可能属于上次运行的日志 + 写死 PASS"这种组合。

### 阶段 4：README 与门禁自报家门（必做）

生成后必须打印每门 `verdict` 与 `exit_code` 汇总（正例几门、负例几门、失败几门），
不允许只报一个"gates count: 12"。**失败也要响亮地报。**

---

## 三、验收（主控逐条复跑）

1. **反证（最高优先）**：让任意一门真实失败（如临时把 `gate_encoding.py`
   改成必败，或直接删掉它的日志）→ 证据包必须判 FAIL 或生成失败，
   **绝不允许出现 PASS**。此项不过，其余项不判读。
2. 反证：删掉任一门日志 → 生成器失败退出，不产出证据包。
3. 反证：把某门退出码改为 1 → 该门 FAIL，`release_ready=false`。
4. 12 门的 `stdout` 与 `stdout_sha256` 同源，逐字节对得上（sha256sum 复算一致）。
5. `stderr_bytes == 0` 时 `stderr == ""`；非空时哈希对得上。
6. `spw.py verify` 仍 `ok=true / errors=[]`，H5 席位契约不被破坏。
7. 生成器 stdout 打印每门 verdict/exit_code 汇总，含失败门。
8. `git status --porcelain` = 0（除本工单文件外）。

---

## 四、禁条

1. **不得**用"读不到运行依据就保留原 PASS 值"的方式兼容旧证据包——
   那是把 P0 继续藏着。
2. **不得**把判定逻辑从字面量改成"从日志文本里 grep 'PASS'"——
   grep 出来的仍是文案不是退出码，同一类造假换层皮。
3. **不得**为了让 12/12 变绿而放宽阶段 1 的真实性要求。
4. **不得**把本机制描述为"完全防止伪造门禁结果"。

## 五、已核实为真、勿重复劳动

- 本单复现用的 H4 日志已还原，`stdout_bytes=10258`，
  证据包 `spw-evidence-48ab11d.json` 已从复现前备份复原
  （覆盖 2/2，`certification=withheld`）。**不要重跑复现。**
- `dogfood_gui/gate_*.log` 共 12 份，与 manifest 12 道门一一对应，文件本身是真的。
  本单不是说"日志是假的"，是说"判定与退出码是假的"。
- WO-0095（锚点缺失）与 WO-0096（观测材料失真）已另立，不要在本单里重复。
- WO-0091 / WO-0092 的自签防线已复跑通过，不要改动、不要重复反证。
- WO-0093 的 H5 席位契约已锁定，本单改判定来源时不得破坏它。

## 六、仍待老板本人执行

- **GitHub 侧吊销 `DeepKit-Fyi` 名下原 `ghp_` token**（WO-0090 阶段 1）。
- 本单属 P0，建议先于 WO-0094 / 0095 / 0096 排期——后三者补的锚点都依赖本单先给出真判定。

---

## 七、执行档案（2026-10-05 实跑留证）

### 7.1 阶段落实

1. **真实执行台账机制（方案 B + 方案 A 联合落地）**：
   - `tools/spw-gates/run_all_gates.py` 每次实跑自动落盘结构化执行台账 `dogfood_gui/gate_run_results.json`（schema: `spw/gate-run/v1`）；
   - 台账每道门禁完整记录命令 `command`、命令哈希 `command_sha256`、真实进程退出码 `exit_code`、判定 `verdict`、起止时刻 `started_at` / `executed_at`、耗时 `duration_seconds`、启动瞬间主题树指纹快照 `subject_sha256`、`stdout_bytes`、`stdout_sha256`、`stderr_bytes`、`stderr_sha256` 以及实际断言的 `claims_asserted`；
   - `tools/spw-evidence/generate_evidence.py` 改为必须消费真实台账，逐门校验命令一致性、日志存在性与哈希一致性、stderr 一致性；
   - 彻底消除了字面量 `"verdict": "PASS"` 与 `"exit_code": 0` 的硬编码。

2. **fail-closed 机制**：
   - 缺失台账文件 → 生成器异常中断退出（RC=1），不产出证据包；
   - 缺失任一门禁日志文件或哈希不匹配 → 中断退出（RC=1），不产出证据包；
   - 任何门禁 `exit_code != 0` → 真实记录 `verdict: "FAIL"`，触发 `artifact_verdict: "FAIL"`，记入 `degradation_reasons`，`release_ready=false`，证书 withheld；
   - 标准输出打印每门禁真实判定与耗时汇总，若有失败门禁则响亮报错。

### 7.2 反证实测记录

| 反证项 | 操作 | 实测结果 |
|---|---|---|
| 反证 1：抽走日志文件 | 重命名 `dogfood_gui/gate_H4_bypass-patterns.log`，运行 `generate_evidence.py` | **RC=1 退出**，报错 `Missing gate stdout log file`，未产出证据包 |
| 反证 2：门禁退出码为 1 | 临时将台账中 H4 `exit_code` 改为 1，运行 `generate_evidence.py` | 证据包中 H4 记为 **`verdict: FAIL, exit_code: 1`**，`artifact_verdict: FAIL`，`release_ready: false`，终端响亮打印 `[LOUD] 1 gate(s) recorded FAIL!` |
| 正证 3：全量 12 门实跑 | 运行 `run_all_gates.py` 跑完全部 12 门禁 | **12/12 RC=0**，台账完整落盘，耗时与哈希各门均有真实依据 |
| 正证 4：验证器规范性检验 | 运行 `spw.py verify --evidence spw-evidence-48ab11d.json` | **ok=true / errors=[]**，H5 异构覆盖 2/2，诚实 withheld |

---

## 八、主控审计判词（2026-10-05，全部反证由主控亲手重跑，不复用下游自述）

**结论：判「通过，但留下一处会放倒整条链的缺口」，已同回合开 WO-20261005-0098 补该缺口。**

### 8.1 主控独立复跑通过的反证（下游自述数字一律未采信）

| 反证项 | 主控实测（自己动手，非引用） | 判定 |
|---|---|---|
| 抽走 H4 日志 | `Missing gate stdout log file: ...` + **RC=1**，未产出证据包 | ✅ |
| 台账 H4 `exit_code=1` | 证据包 H4 = `FAIL/1`，`artifact_verdict=FAIL`，`release_ready=false`，`[LOUD] 1 gate(s) recorded FAIL!`，逐门汇总 `11/12 passed, 1 failed` | ✅ |
| 删整个台账 | `Gate execution ledger not found: ... Must run run_all_gates.py` + **RC=1** | ✅ |
| 注入未声明 claim `ghost_claim` | `asserted claims not declared in manifest: ['ghost_claim']` + **RC=1** | ✅ |
| 清空 H1 `claims_asserted` | `GATE_CLAIMS_MISSING: H1 ... declared [...] but asserted none` 降级 | ✅ |
| 篡改 H1 日志追加 9 字节 | `Stdout integrity mismatch ... disk 75B (0c9bf81c...) vs ledger 66B (d490242c...)` + **RC=1** | ✅ |
| 全量 12 门 | 主控亲自跑 `run_all_gates.py` → **12/12 RC=0**（含 164159B 单测、16.6s gui-verify-smoke） | ✅ |
| 外部验证器 | `spw.py verify` → `ok=true / errors=[] / recomputed_coverage "2/2" / withheld / acceptable_for_release=false` | ✅ |

另核实：`generate_evidence.py` 中 `"verdict": "PASS"` / `"exit_code": 0` / `"artifact_verdict": "PASS"` 字面量**确已全清**（grep 零命中）；
台账 schema = `spw/gate-run/v1`，19 字段（command / command_sha256 / exit_code / verdict / started_at /
executed_at / duration_seconds / subject_sha256 / stdout_bytes / stdout_sha256 / stderr_* /
claims_declared / claims_asserted）。
9/10 个带 claim 的门禁走**显式** `[CLAIM_ASSERTED]` 发射（7 个经 `gate_lib.ok(..., claims=[...])`，
2 个直接 print）；观测材料保留 **16 个真实字段**（多于自述的 15）。

### 8.2 留下的缺口（本单范围内未闭合 → WO-0098）

**门禁执行台账自身没有完整性钉死。** 实测三项全为空：

- `.gitignore:67` `dogfood_*/` → 台账与 12 份门禁日志 `git ls-files` 命中 **0**；
- `spw-manifest.json` 全文无 `gate_run_results` 引用；manifest 里**唯一**的哈希钉是
  `observations_sha256`（钉观测席位文件）；
- 于是 `stdout_sha256` 只把「日志 ↔ 台账」互相绑住，而**两者都在同一个被 gitignore 的目录里，
  可以被整套一起改写且互相自洽**。

即：本单把"判定来自真实运行"修好了，但**没修"这份运行凭据本身不可篡改"**。
这与 WO-0092 根因 B（`h4_approvers.json` 是无保护的普通仓库文件）是同一形状，
只是往上了一层——WO-0092 有 `approvers_sha256` 方案，台账没有对应物。

**验收条目 8（`git status --porcelain = 0`）对此结构性失明**：文件被 gitignore，
工作树永远干净，该条目不可能发现这个缺口。**这是验收判据设计缺陷，记入 WO-0098。**

**补盲已完成（WO-0098 阶段 3 落地，2026-10-05）**：本单验收 8 降级为**必要条件、非充分条件**，
替代判据为——

- `git ls-files` 必须包含台账 `tools/spw-gates/gate-run/gate_run_results.json` 与 12 份
  `gate_*.log`；
- `git check-ignore <台账路径>` 必须返回非零（不被忽略）；
- manifest 必须有 `gate_run_sha256`，且与台账实算 sha256 一致。

三者缺一即判不通过，**不再接受单纯的"工作树干净"作为充分判据**。

### 8.3 下游自述与实现的偏差（记录，未据此退回）

1. 自述称材料构建器"以正则硬拦截结论诱导词（如 all gates passed、ready for release 等）"
   ——**不属实**：`FORBIDDEN_PHRASES` 只有 5 条中文短语，无英文列表、无正则。
   当前**风险未激活**（材料不带 stdout 全文，"ALL REQUIRED GATES PASSED"进不去），
   故未判缺陷，但自述与代码不符已记录在案。
2. 自述"9 个确定性门禁与 1 个 Delphi 单元测试模块分别实现显式断言"——
   9 个属实，但 **H2.unit-tests 不是显式断言**，是 `run_all_gates.py:121-127` 的
   "`rc==0` 且测试类名字符串出现在 stdout"启发式推断。当前锚在真实
   `Executing Test :` 行上所以成立，但强度低于其余 9 门 → 见 WO-0099。
