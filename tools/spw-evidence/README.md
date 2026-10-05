# SPW Evidence Generator (`tools/spw-evidence`)

本目录包含 AsWish 运行时证据包生成工具，负责执行 `spw-manifest.json` 中登记的确定性门禁并生成符合规范的 SPW 证据包。

## 核心脚本

- `generate_evidence.py`:
  - 自动读取 `spw-manifest.json`，执行所有配置的门禁；
  - 记录各门禁命令的 `command`、`exit_code`、耗时 `duration_ms`；
  - 完整记录 `stdout`、`stdout_bytes` 以及 `stdout_sha256`，杜绝任何截断失真；
  - 诚实记录 H5 异构观察席位状态，当缺乏外部观察席位时如实申报 `degraded` 降级，避免违规发证；
  - 诚实保留 H4 反绕过历史欠账告警（81 项 baseline 豁免尚未经审核席位批准，以 WARN 形式如实落盘）；
  - 将证据包结构化输出至仓库根目录 `spw-evidence-<commit_sha>.json`，并通过 `spw.py verify` 进行规范性验证。

- `build_obs_material.py`:
  - 为 H5 外部异构只读观察席位生成中性、无偏见且剥离自指字段的观测材料；
  - 判定真值直接继承自已生成的 SPW 证据包，禁止硬编码假绿灯；
  - 强制执行自指键名扫描与结论偏见词检测，阻断自循环审计。

## H5 异构只读观察席位（WO-20261005-0093）

H5 是"另一个家族的外部模型以只读方式复核本项目材料"的环节。席位不是脚本自己填的，
而是由认证席位维护在 `spw-observations.json` 中，生成器只做**逐席复核**，不做任何代填。

`evaluate_h5()` 按以下顺序验证，任何一步不过整包即降级为 `degraded` + 证书
`withheld` + `release_ready=false`：

1. manifest 必须有 `observer_family_whitelist`（未登记家族不得计入）；
2. `runtime_contract.observer_input` 指向的文件必须存在；
3. manifest 必须钉死 `observations_sha256` —— 未钉死等于允许手工填写席位；
4. 席位数 > 0，且文件内 `subject_sha256` 必须等于本次证据包主题哈希；
5. 每席：家族已登记、同家族只计一席（第二席不计入）、席内 `subject_sha256` 一致、
   `raw_file` 存在于 `WO/evidence/h5/`、`response_digest` 重算相符、
   **每条 finding 的 description 前 50 字必须能在原始回复里找到**。

第 6 条是反自签的关键：没有它，这个文件就只是一个"用来填写没人收到过的结论"的地方。

### degraded/withheld 是正常且诚实的结果

当 live 席位不足 `min_observer_families`（当前 2）时，证据如实申报降级、证书暂扣、
`release_ready=false`。**这不是故障，也不应该被修成"看起来绿"**。想要真正发证，
必须去跑真实的席位，而不是改这个文件。

### 谁可以增加席位家族

只有具备授权的认证席位，且必须：

- 先把候选家族写进 manifest 的 `observer_family_whitelist`；
- 用真实的第三方模型跑一次观察，原始回复全文落盘到 `WO/evidence/h5/raw-*.txt`；
- 重新计算 `spw-observations.json` 的 sha256 并**手工**更新 manifest 的
  `observations_sha256`（生成器绝不自动回写该字段）；
- 一个家族只保留一席。同家族换模型重跑**不会**让覆盖率 +1。

## 机制能力边界（WO-20261005-0095 / WO-20261005-0097）

本机制保证全部门禁判定必须源自真实进程执行与结构化执行台账（`gate_run_results.json`），
绑定执行时刻 `executed_at`、耗时 `duration_seconds`、执行前源码主题快照 `subject_sha256` 以及
实际断言的 `claims_asserted`，使得 PASS **可定位、可复现、可核验**。缺失运行依据或执行失败一律 fail-closed，绝无硬编码假绿灯。

**边界说明**：本机制防范的是单点伪造、无意假绿灯与低成本数据篡改；
但不能防范"协同改写源码 + 日志 + 退出码 + 台账四处成套伪造"的高级攻击——
那种情况必须依靠 Git 提交历史审计与独立第三方复核。本机制不声明绝对防御。

## 观测材料边界（WO-20261005-0096）

观察者材料（`build_obs_material.py`）必须源自真实证据包实体，强制排除任何 H5 认证层自身状态
（如 `valid_observer_families`、`certification`、`pending_h5_findings` 等自指字段），
以确保外部观察者审查的是被测软件本体，而非审计装置自身的历史状态。

## 运行方式

```bash
python -X utf8 tools/spw-evidence/generate_evidence.py
```

标准输出会自报覆盖率、有效家族、H5 裁决、各门禁真实退出码与降级原因，便于核对：
`observer coverage: 2/2 families=['deepseek', 'gemini']`。

