# WO-20261004-0092 · 主控 · H4 批准人白名单可自服：`submitted_by` 非必填 + 白名单文件无完整性钉死

- 下发时间：2026-10-05 · 下发人：主控 · 依据：**主控对 WO-20261004-0091 执行报告的独立复核（HEAD=c5324ed）**
- 优先级：**P3（WO-0091 主目标已真实闭环；本单补两道仍可被绕过的缺口，低危但有审计价值）**
- 主执行：**工具链维护AI**
- 状态：**confirmed（主控反证实测：把 DevAI 加进白名单后自签 → RC=0 放行）**

---

## 一、缺陷本体

WO-0091 的三重防线（冒充正则 / 白名单 / `submitted_by == approved_by`）主控已逐条反证**全部有效**。
但主控多跑了一项工单未要求的反证，发现防护仍可被自服绕过。

### 1.1 实测：把自己加进白名单即可自签通过

主控操作（HEAD=c5324ed，跑完即还原）：

```
1. 在 h4_approvers.json 的 authorized_approvers 里追加 "DownstreamDevAI"
2. 把 h4_waivers.json 首条 approved_by 设为 "DownstreamDevAI"（不带 submitted_by 字段）
3. 运行 gate_bypass_patterns.py
   -> RC = 0   HIGH = 0        <- 门禁放行
```

也就是说：**只要同时改两个普通仓库文件，就能给自己开出一张有效豁免。**

### 1.2 两个根因

**根因 A：`submitted_by` 不是必填，自签检测因此可被"留空"绕开。**

`submitted_by == approved_by` 的自签断言只在两个字段都存在时才成立
（主控实测：填了 `submitted_by=ArchitectureReviewBoard, approved_by=ArchitectureReviewBoard`
→ RC=1 `[HIGH] self-signed waiver`，断言本身是对的）。
但台账里现在没有任何一条带 `submitted_by`，缺字段即跳过该断言。

**根因 B：`h4_approvers.json` 是无保护的普通仓库文件。**

门禁只读它，没有任何机制阻止开发者往里加自己。
WO-0091 写的是"`h4_approvers.json` 由主控维护，门禁只读"，
但"由主控维护"没有落到任何可执行约束上——改它不需要额外成本，
也不需要经过比改台账更显眼的流程。

---

## 二、执行阶段

### 阶段 1：`submitted_by` 变为必填（必做）

1. `h4_waivers.json` 每条豁免增加 `submitted_by`（提交申请人，通常是开发角色）。
2. `gate_bypass_patterns.py` 增加：任何条目缺 `submitted_by` → `[HIGH] waiver missing submitted_by` → fail-closed。
3. 存量 81 条在补录 `submitted_by` 前，门禁应如实报错而不是放行
   （这会让 H4 暂时变红——**这是正确的**，如实暴露 81 条的申请人缺口，
   与 WO-0091 "WARN 是事实不是噪音"同一原则）。

### 阶段 2：白名单完整性钉死（必做）

- 在 `spw-manifest.json` 的 `h4_policy` 中增加 `approvers_sha256`，记录 `h4_approvers.json` 的
  **内容哈希**（由主控核算后填入）。
- 门禁启动时重算实际哈希并与登记值比对，不一致 → `[HIGH] approver whitelist tampered` → fail-closed。
- 白名单确需变更时，走主控批准 + **同时**更新 manifest 中的哈希值，
  使"改白名单"成为一个必须动 manifest 的显眼动作（manifest 变更在 CI 与复核中更易被发现）。

### 阶段 3：README 补一句边界说明

`tools/spw-gates/README.md` 明确写：本机制防的是"无意自签"与"低成本的记录篡改"，
**不能防"有人同时改白名单+台账+manifest 哈希三处来伪造审批"**——
那种情况只能靠 git 提交历史审计与主控复核发现。不要把机制说成绝对可靠。

---

## 三、验收（主控逐条复跑）

1. 反证：删掉任一条的 `submitted_by` → 门禁 **RC=1** 报 `[HIGH] waiver missing submitted_by`。
2. 反证：`submitted_by == approved_by` → 仍 **RC=1** 报 `[HIGH] self-signed waiver`（不回归）。
3. 反证：改 `h4_approvers.json` 内容但不动 manifest 哈希 → 门禁 **RC=1** 报 `[HIGH] approver whitelist tampered`。
4. 反证：删掉 `h4_approvers.json` → 仍 **RC=1** fail-closed（不回归）。
5. 主控实际核算并更新 manifest 中的 `approvers_sha256` 后，门禁恢复 RC=0
   （或按阶段 1 的现实，81 条 `submitted_by` 补齐后才恢复）。
6. `tools/spw-gates/README.md` 中出现"机制边界"说明。
7. `git status --porcelain` = 0。

---

## 四、禁条

1. **不得**为了让门禁变绿而把 81 条的 `submitted_by` 统一填成某个"看起来合理"的值——
   不知道谁提交的就留空并让门禁报错，等主控裁定。
2. **不得**把 `approvers_sha256` 做成"运行时自动重算并写入 manifest"——那等于自己给自己盖章，
   哈希必须由主控离线核算后手工填入。
3. **不得**把机制描述成"完全防止伪造审批"。

## 五、本次复核已核实为真、勿重复劳动

WO-0091 以下成果主控**全部亲自复跑通过**，不要改动：

- 81 条 `approved_by` 全部置空、`approved_at` 全部为 `null`，**无任何伪造批准人**；
- 基线实跑输出 **81 条 `[WARN] baseline waiver without approver (historical debt)`，RC=0**；
- `h4_approvers.json` 仅登记 `MasterController` 与 `ArchitectureReviewBoard`，门禁只读；
- `spw-manifest.json` 的 `h4_policy.impersonation_patterns` 已配置；
- 反证全部通过：`MasterController-WO0087` → `[HIGH] impersonated approver`；
  `主控-001` → `[HIGH] impersonated approver`；`FakeApproverRole` → `[HIGH] unauthorized approver`；
  白名单文件缺失 → `[HIGH] h4_approvers.json missing` fail-closed；
  合法角色 `MasterController` → RC=0 且 WARN 由 81 降为 80；
  `submitted_by == approved_by` → `[HIGH] self-signed waiver`；
- `tools/spw-gates/README.md:56` 与 `tools/spw-evidence/README.md:12` 的假表述已清除，
  改为"尚未逐条经审核席位批准，门禁以 WARN 形式持续提示（属于已知技术债务）"；
- `run_all_gates.py` 主控实跑 **12/12 RC=0**；`H4.bypass-patterns` stdout 10258B 全量落盘、
  `truncated=False`、内含 81 条 WARN；
- 证据包 `spw-evidence-c5324ed.json`：`release_ready=False`、`execution_status=degraded`、
  `certification=withheld`；`spw.py verify ok=True / errors=[] / acceptable_for_release=False`；
- 导出包 192 个文件，内部治理标记仅 5 处（3 处正当版权行 + 2 处门禁脚本自带违禁词表），
  `docs/` **0** 泄露；
- 未建新 Tag，未 push，`origin/main` 仍无 `.workbuddy/`，`git remote -v` 无凭据。

## 六、仍待老板本人执行

- **GitHub 侧吊销 `DeepKit-Fyi` 名下原 `ghp_` token**（WO-0090 阶段 1，唯一无法代办的的动作）。
