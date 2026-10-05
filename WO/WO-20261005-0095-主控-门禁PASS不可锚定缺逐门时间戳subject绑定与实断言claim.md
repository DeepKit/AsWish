# WO-20261005-0095 · 主控 · 门禁 PASS 不可锚定：无执行时间戳、无逐门 subject 绑定、无"实断言的 claim"

- 下发时间：2026-10-05 · 下发人：主控 · 依据：**WO-20261005-0093 阶段 3 观察发现，
  经主控逐项核实后重新定性（观察者的原始结论部分失实，核实过程见 §1.2）**
- 优先级：**P2（不是造假，是审计上"无法定位"；会让 PASS 在复核中不可用）**
- 主执行：**工具链维护AI**
- 状态：**executed（工具链维护AI 实跑完毕，执行档案见 §七）**

---

## 一、缺陷本体（已核实，非观察者原话）

### 1.1 证据包里**已经有**的（不要重复"补"）

`spw-evidence-<sha>.json` 的 `deterministic_gates[12]` 每条都带：

```
gate_id, required, execution_status, verdict, claims, command,
exit_code, stdout_sha256, stderr_sha256, stdout_bytes, stderr_bytes,
stdout, stderr, truncated
```

外加包级 `subject.sha256`（含 subject_files 全树逐文件哈希）与 `manifest_sha256`。
**`command` 与日志哈希都在。**观察者报的"没有命令、没有日志哈希"是**失实的**，
根因是喂给他们的观测材料是我手工裁剪的三字段子集，不是证据包本体——
该材料缺陷已改归 WO-20261005-0096，不在本单范围。

### 1.2 真正缺的三项（读实体后逐项确认）

| 缺失项 | 现状 | 后果 |
|---|---|---|
| **逐门执行时间戳** | 只有包级 `created_at`，无任何门有自己的 `executed_at` | 无法判断 12 道门是同一次运行，还是分多次拼起来的；无法与 subject 变更时序对齐 |
| **逐门 subject 绑定** | subject 只在包级，门级无 `subject_sha256` | 某道门的 stdout 哈希无法证明"它跑在这个 subject 上"。门可以先跑、源码后改，PASS 仍会被采信 |
| **实断言的 claim** | 只有 manifest 声明的 `claims`，无 `claims_asserted` | manifest 声明 `H2.unit-tests` 断言三项 claim，但没有任何字段记录本次**真的断言了它们**。声明可以是永不执行的摆设 |

补充一项**非缺失但脆弱**：`command` 与 `stdout` 可被同时改写而互相自洽
（无独立第三方交叉）。这一条治不了，只能记边界（见阶段 4）。

### 1.3 与 WO-0091 的关系（不是重复单）

WO-0091 修台账伪造批准人；本单修**运行结果无法定位到版本与时刻**。
一个是"谁批的"，一个是"什么时候在哪一版上跑出这个结果的"。

---

## 二、执行阶段

### 阶段 1：逐门补运行锚点（必做）

`deterministic_gates[*]` 增加：

- `executed_at`：ISO8601 带时区，取自该门禁**实际进程结束时刻**
- `duration_seconds`：实际耗时（可佐证时序合理性）
- `subject_sha256`：该门启动瞬间的 subject 树哈希（跑前快照，不是跑后）
- `claims_asserted`：本次实际断言过的 claim id 列表
- `command_sha256`：`json.dumps(command)` 的 sha256（便于 grep 定位与比对）

### 阶段 2：声明与实断言的差异必须显形（必做）

- 若某门 `claims_asserted` 是 `claims` 的真子集 → 记入 `degradation_reasons`，
  不允许静默；
- 若某门 `claims_asserted` 含 manifest 未声明的 claim → fail-closed
  （无源 claim）。

### 阶段 3：时序一致性自证（必做）

生成器自证：12 道门的 `executed_at` 全部落在
`[最早一门, 最晚一门 + 各门 duration]` 区间内且非倒挂；
出现倒挂或跨度过大 → 记 `degradation_reasons`，不静默。

### 阶段 4：README 写明能力边界（必做）

`tools/spw-evidence/README.md` 写明：本机制使 PASS **可定位、可复现**，
但不能防"有人同时改源码 + 日志 + verdicts + manifest 四处成套伪造"——
那种情况只能靠 git 提交历史审计与主控复核。不得写成绝对可靠。

---

## 三、验收（主控逐条复跑）

1. 任取一门，可凭证据包内字段回答"它何时、在哪一版上、跑了什么命令、
   断言了哪些 claim"，四项全部有据。
2. 反证：删掉任一门的 `subject_sha256` → fail-closed，不得默认放行。
3. 反证：把某门 `executed_at` 拨到 `created_at` 之前 → 被记入
   `degradation_reasons`（或 fail-closed），不静默。
4. 反证：manifest 声明某门断言 claim X，但 `claims_asserted` 为空 →
   显式记入 `degradation_reasons`。
5. 反证：`claims_asserted` 含 manifest 未声明的 claim → fail-closed。
6. `spw.py verify` 仍 `ok=true / errors=[]`，且 H5 席位契约
   （`observer_seat_outcomes[*].final_observation`）不被破坏。
7. `git status --porcelain` = 0（除本工单文件外）。

---

## 四、禁条

1. **不得**把 `subject_sha256` 用"包级 subject"充当门级绑定——
   那等于没绑。必须是该门启动瞬间的快照。
2. **不得**让 `executed_at` 由"生成证据包的时刻"回填——
   时间戳必须来自门禁进程自身，任何事后填写都会重演 WO-0091 的自签形状。
3. **不得**把 `claims_asserted` 直接从 manifest 的 `claims` 复制——
   复制来的就是声明不是断言，正是本单要治的。
4. **不得**把本机制描述为"完全防止伪造门禁结果"。

## 五、已核实为真、勿重复劳动

- 本次证据包（HEAD=48ab11d）**12 道门全部真跑真 PASS**，
  `stdout_bytes` / `truncated=False` / `stdout_sha256` 均在，日志确实落盘。
  本单不质疑"有没有跑"。
- WO-0091 / WO-0092 的三重自签防线已复跑通过，不要改动、不要重复反证。
- WO-0093 的 H5 席位契约已锁定，本单新增字段不得破坏它；
  若要改席位形状，另开工单。
- 观察者关于"没有命令 / 没有日志哈希"的表述**失实**，
  已在 WO-0093 §7.7 标注撤回，不要据此再开单。

## 六、仍待老板本人执行

- GitHub 侧吊销 `DeepKit-Fyi` 名下原 `ghp_` token（WO-0090 阶段 1）。

---

## 七、执行档案（2026-10-05 实跑留证）

### 7.1 阶段落实

1. **逐门运行锚点补充（阶段 1）**：
   - 每道门禁在 `gate_run_results.json` 与 `spw-evidence-<commit_sha>.json` 中均补充了：
     - `executed_at`：ISO8601 带时区，取自进程结束瞬间；
     - `duration_seconds`：真实执行耗时（秒）；
     - `subject_sha256`：启动瞬间主题源码树哈希快照（跑前快照）；
     - `claims_asserted`：实际断言的 claim 列表；
     - `command_sha256`：命令 JSON 序列化后的 sha256 摘要。
2. **声明与断言差异显形（阶段 2）**：
   - 若某门断言未在 manifest 声明的 claim → fail-closed 退出（RC=1）；
   - 若某门声明了 claims 但断言为空 → 记入 `degradation_reasons`（`GATE_CLAIMS_MISSING`）；
   - 若断言为声明的真子集 → 记入 `degradation_reasons`（`GATE_CLAIMS_INCOMPLETE`）。
3. **时序一致性校验（阶段 3）**：
   - 逐门校验 `executed_at`：不得早于运行启动时刻，不得超前当前时间（时钟漂移 > 60s），否则记入 `degradation_reasons`。
4. **README 边界说明（阶段 4）**：
   - `tools/spw-evidence/README.md` 补充"机制能力边界"，明确声明可定位、可复现但不可防御全链路协同篡改。

### 7.2 反证实测记录

| 反证项 | 操作 | 实测结果 |
|---|---|---|
| 反证 1：删掉 `subject_sha256` | 将台账中某门 `subject_sha256` 置空，运行生成器 | **RC=1 退出**，报错 `Missing subject_sha256 binding`，fail-closed |
| 反证 2：断言未声明的 claim | 注入未在 manifest 声明的 claim，运行生成器 | **RC=1 退出**，报错 `asserted claims not declared in manifest`，fail-closed |
| 反证 3：声明了 claim 但未断言 | 将某门 `claims_asserted` 置空，运行生成器 | 证据包如实记入 **`degradation_reasons: [GATE_CLAIMS_MISSING: ...]`**，不静默放行 |
| 反证 4：时序倒挂 | 将某门 `executed_at` 拨回至历史时刻（早于启动），运行生成器 | 证据包如实记入 **`degradation_reasons: [TEMPORAL_INCONSISTENCY: ...]`**，不静默放行 |
| 正证 5：规范性验证 | 运行 `spw.py verify --evidence spw-evidence-48ab11d.json` | **ok=true / errors=[]**，H5 席位契约完整保留 |
