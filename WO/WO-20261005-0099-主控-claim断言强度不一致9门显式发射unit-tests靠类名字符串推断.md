# WO-20261005-0099 · 主控 · claim 断言强度不一致：9 门显式发射，H2.unit-tests 靠"测试类名出现在 stdout"推断

- 下发时间：2026-10-05 · 下发人：主控 · 依据：**主控对 WO-20261005-0097 / 0095 成果的独立审计**
- 优先级：**P2（当前锚在真实执行行上所以成立；属强度不足与不对称，非活缺陷）**
- 主执行：**工具链维护AI**
- 状态：**confirmed（`run_all_gates.py:121-127` 逐行留证 + 实测日志上下文）**

---

## 一、缺陷本体

### 1.1 10 个带 claim 的门禁，两种断言强度

**显式发射（9 门，强度正确）**：门禁自己打印 `[CLAIM_ASSERTED] <claim>`，
由 `run_all_gates.py:120` 正则捕获。其中 7 门走 `gate_lib.ok(..., claims=[...])`
（resource-locks / encoding / autofix / ui_bridge / gui_verify_smoke / external_boundary /
bypass_patterns），2 门直接 print（open_source_build / ehai_vendor_drift）。

**启发式推断（1 门，强度不足）**：`tools/spw-gates/run_all_gates.py:121-127`

```python
if gid == "H2.unit-tests" and rc == 0:
    if "TFogStateMachineTests" in stdout_text:
        claims_asserted.append("state_machine_check")
    if "Test01_P2_DifferentTriggerTree_DifferentBaselineHash" in stdout_text:
        claims_asserted.append("active_detail_trigger")
    if "ValidFogState_NoErrors" in stdout_text or "TValidationTreeFileTests" in stdout_text:
        claims_asserted.append("required_fields_on_activation")
```

即：**`rc==0` 且测试类名/测试方法名的字符串出现在 stdout 里 → 该 claim 算已断言。**

### 1.2 当前为什么还成立（主控实测）

`dogfood_gui/gate_H2_unit-tests.log`（164159B）里这三个字符串出现在真实执行轨迹上：

```
1455:  Test : Test.AsWish.Difference.Test01_P2_DifferentTriggerTree_DifferentBaselineHash
1457:  Running Setup for : Test01_P2_DifferentTriggerTree_DifferentBaselineHash
1459:  Executing Test : Test01_P2_DifferentTriggerTree_DifferentBaselineHash
1462:  Running Teardown for Test01_P2_DifferentTriggerTree_DifferentBaselineHash
2059:  Fixture : Test.AsWish.Models.TFogStateMachineTests
2061:  Test : Test.AsWish.Models.TFogStateMachineTests.SameState_IsAlwaysAllowed
```

是 `Executing Test :` / `Fixture :` 行，**不是启动时预打印的清单**。
所以目前三个 claim 确有真实执行背书。

### 1.3 但强度确实低于其余 9 门，有三类风险

1. **输出格式漂移即失真**：DUnitX 换成别的 runner、或改成先打印清单再执行，
   字符串照样命中 → claim 假断言。显式 `[CLAIM_ASSERTED]` 不受输出格式影响。
2. **类被改名 → claim 静默消失**：这会掉进 WO-0095 已实现的
   "真子集 → `GATE_CLAIMS_MISSING` 降级"安全网，**方向是安全的**
   （漏报会响，不会假绿）。但反方向——类名留着、测试体被掏空仍然全过——
   字符串照旧命中，claim 假断言，且没有任何机制会发现。
3. **不对称本身是维护陷阱**：换人维护时看到 9 门显式、1 门靠字符串匹配，
   极易误判"这里也是显式的"而在改 runner 时漏改。

### 1.4 与 WO-0095 的分界

WO-0095 管"缺逐门时间戳 / subject 绑定 / 实断言 claim"三类缺口的存在性；
本单管"**已实现的实断言在 1/10 上门是弱形式**"。WO-0095 阶段 2 禁条 3 禁的是
"从 manifest 的 claims 复制"；本单的启发式不是复制 manifest，是从真实 stdout 推，
所以不在 WO-0095 禁条内，但是同一族问题的弱化版。

---

## 二、执行阶段

### 阶段 1：让 Delphi 单测自己发射 claim（必做，首选）

`tests/AsWish.Tests.dpr`（或共用的测试注册单元）在跑完对应 fixture 后，
直接向 stdout 打印标准标记，与 Python 门禁同格式：

```
[CLAIM_ASSERTED] state_machine_check
[CLAIM_ASSERTED] active_detail_trigger
[CLAIM_ASSERTED] required_fields_on_activation
```

要求：标记**由该 claim 对应的测试真实跑完后**才打印（挂钩 fixture teardown 或
测试通过回调），不是启动时无条件打印。

### 阶段 2：移除 run_all_gates.py 的启发式（必做）

阶段 1 落地后，删掉 `:121-127` 的字符串匹配分支，改为与其余 9 门**同一条路径**
（只认 `[CLAIM_ASSERTED]`），消除不对称。

### 阶段 3：反证哑测（必做）

- 反证 A：把 `tests/` 里对应 fixture 的测试体掏空（保留类名）→ claim 不得出现，
  证据包须报 `GATE_CLAIMS_MISSING` 降级；
- 反证 B：改 runner 输出格式（如去掉 `Fixture :` / `Executing Test :` 行）→
  阶段 2 后 claim 仍须正确出现（证明不再依赖字符串格式）；
- 反证 C：恢复正常 → 12/12 且三门 claim 全断言。

---

## 三、验收（主控逐条复跑）

1. `run_all_gates.py` 中不再有 `H2.unit-tests` 专属的类名字符串匹配分支。
2. 反证 A：掏空测试体保留类名 → claim 缺失被降级捕获，**不出现假断言**。
3. 反证 B：改变 runner 输出格式 → claim 仍正确断言。
4. 反证 C：还原 → 12/12、三门 claim 全在、`spw.py verify ok=true / errors=[]`。
5. 10 个带 claim 的门禁，断言路径统一为显式发射，无分支特例。
6. `git status --porcelain` = 0（除本工单文件外）。

---

## 四、禁条

1. **不得**把启发式从"类名匹配"改成"从 manifest claims 复制"——
   那是 WO-0095 明令禁止的形状。
2. **不得**在启动处无条件打印三条 `[CLAIM_ASSERTED]` 冒充断言——
   那是换层皮的造假，比现状更糟。
3. **不得**为了让 claim 齐备而放松 tests 的真实断言。

## 五、已核实为真、勿重复劳动

- 三个字符串在 164159B 日志中的真实上下文已核（见 §1.2），是执行轨迹非预打印清单。
- 9 门显式发射的分布已核：7 门 `gate_lib.ok(..., claims=[...])` + 2 门直接 print。
- WO-0095 的"真子集 → `GATE_CLAIMS_MISSING`"降级路径存在且有牙（主控已反证：
  清空 H1 的 `claims_asserted` → 正确降级）。
- WO-0098 管台账哈希钉死，不属本单范围。
- 12/12 门禁、2/2 观测覆盖、fail-closed 证书门均已锁定，本单不得破坏。

## 六、仍待老板本人执行

- GitHub 侧吊销 `DeepKit-Fyi` 名下原 `ghp_` token（WO-0090 阶段 1）。
