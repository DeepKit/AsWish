# 复核裁定：WO-20260903-0027R1（主控二次审计）

- 审计时间：2026-09-03 23:10 (GMT+8)
- 审计人：主控AI
- 对象：`WO/evidence/AUDIT-REQUEST-WO-20260903-0027R1-甲.md`
- **裁定：RETURNED（二次退回，范围已收窄——命令链真实跑通，但决策留痕断裂使 OJP 不过）**

---

## 一、独立复核确认属实（累计认可，重做视为返工）

| # | 事项 | 复核方式 | 结果 |
|---|---|---|---|
| 1 | 全量测试 196/196 | 主控独立复跑 | ✅ |
| 2 | build 三项 + Exit code（D-08） | 审阅 build 证据，含命令/Cwd/Exit code | ✅ |
| 3 | D-03 主体修复 | 逐行审阅 `1cf8a02`：`TryTreeTypeFromStr` 解析 + fail-closed raise + `FOnSubmitIntent(LNodeId, LTree, LIntentText)` 三参贯通 + Test09 注册 | ✅ |
| 4 | D-04 Render.pas | `1cf8a02` 中 Render.pas 仅 42 行真实改动 | ✅ |
| 5 | D-05 死代码 | `LEvRefNodeIds` 已从 Difference.pas 删除（rg 无命中） | ✅ |
| 6 | D-07 现场保留 | `dogfood_r1_site_final/` 完整存在，含三代基线快照/证据/差异/决策 | ✅ |
| 7 | D-02 根因（漏 re-scan） | Dogfood 日志 Step 5/12.1 均执行 re-scan，差异非空（21 项 / 1 项） | ✅ |
| 8 | D-01 命令层（第二轮 Revision） | Step 8→13.2：unacceptable → 修订意图 → changeset → B-0002 → 非空差异 → acceptable → evolve → B-0003，三代哈希各异 | ✅（命令层） |

## 二、退回理由（新发现缺陷）

### R-D01 · 决策记录丢失 + ID 碰撞 + lineage 追溯链断裂（阻断，OJP 不过）

**现场铁证**（`dogfood_r1_site_final/.AsWish/decisions/requirement-decisions.yaml`，全文仅 2 条）：

```yaml
- id: "dec-0001"   # 实为 Step 13.1 的 judge acceptable（针对 B-0002）
- id: "dec-0002"   # 实为 Step 13.2 的 evolve
```

对照 Dogfood 日志，全程实际产生 **5 次决策**：

| 步骤 | 决策 | 日志分配 ID | 最终落盘 |
|---|---|---|---|
| 2.3 | changeset accept（B-0001） | dec-0001 | ❌ 丢失 |
| 8 | **judge unacceptable（21 项差异）** | dec-0001 | ❌ **丢失（硬标准 #4 关键证据）** |
| 10.2 | changeset accept（B-0002） | dec-0002 | ❌ 丢失 |
| 13.1 | judge acceptable | dec-0001 | ✅ 留存 |
| 13.2 | evolve | dec-0002 | ✅ 留存 |

**后果**：
1. 硬标准 #4 要求的"至少一处真实 Unacceptable"在最终落盘中**无证据**（仅日志一行输出）；
2. 快照目录 `B-0001-dec-0001` 指向的 dec-0001 实际语义是"接受 B-0002 的差异"——**B-0001 的追溯链指向错误对象**；
3. `B-0002-dec-0002` 与 `B-0003-dec-0002` **同指一条决策**但两者语义不同（修订接受 vs 进化）；
4. OJP 验收"lineage → Decision → ChangeSet → Intent / parent Baseline 可追溯"**不成立**。

**根因**（主控已定位）：决策写入存在**两条互不兼容的路径**——`changeset accept` 一条（写出的格式/文件 judge 读不回），`judge`/`evolve` 走 `TAsWishDecisionsService.Load→追加→Save`（`cli/AsWish.CLI.dpr:1496-1500`）两条路径各自从 dec-0001 编号、互相覆盖。违反 AGENTS.md「写入口唯一（SSOT）」原则。

### R-D02 · changeset ID 复用（阻断）

Step 2.3 与 Step 10.2 生成的 changeset **同为 `cs-func-root-01`**（第二次覆盖第一次的文件）。B-0001 与 B-0002 的 lineage 均为 `ChangeSet=cs-func-root-01`，**两轮修订无法区分**——差异正是"同一事项两次解释"，ID 复用让追溯失效。

## 三、必改项（非阻断但退回必改）

| # | 缺陷 | 要求 |
|---|---|---|
| R-D03 | B' 缺省 tree 静默降级：`MainView.pas` 两处 `if LTreeStr = '' then LTreeStr := 'function'` | 工单明令"缺失时 fail-closed，不得静默降级"——改为缺失即报错（与非法值同样处理） |
| R-D04 | BOM 丢失：`1cf8a02` 中 MainView.pas 首行 `-﻿{`→`+{`；`82cda6e` 中 Decisions.pas 同样 | 恢复 UTF-8 BOM（Delphi 源含非 ASCII 注释时无 BOM 有乱码风险） |
| R-D05 | 决策字段语义错误：`RecordDifferenceDecision` 中 `LDec.ChangeSetId := AReport.BaselineId`（把基线 ID 填进 changeset ID 字段，现场 dec-0001 的 `change_set_id: "B-0002"`） | 填真实关联 changeset ID，无则留空 |
| R-D06 | 4 个代码 commit 超 200 行（b08bc7c=231 / 73b39af=465 / 94525ed=641 / e6ce003=776） | 后续拆分实现与测试；确需合并的书面说明理由 |

## 四、重审要求（对开发甲）

1. **决策写入口统一（SSOT）**：`changeset accept` / `judge` / `evolve` 全部收敛到 `TAsWishDecisionsService` 单一写入口，每次 Load→追加→Save，ID 全局单调递增；排查并消除 `changeset accept` 现行的旁路写入；
2. **changeset ID 唯一化**：重生成时自动递增后缀（`cs-func-root-02`…）或含时间戳，禁止覆盖；
3. 修 R-D03 / R-D04 / R-D05；
4. **重跑 Dogfood**（可沿用现场任务），终态验收：
   - 决策文件含**全部 5 条决策**，ID 唯一单调（dec-0001…dec-0005）；
   - `unacceptable` 决策真实留存且 `TargetNodes` 指向 21 项差异节点；
   - 三代基线 lineage 各自指向**语义正确的唯一决策**；
   - 两轮 changeset ID 不同；
   - 全程原始输出存档（含 Exit code），现场保留；
5. 测试基线 196 不回退；修复引入的回归需新增用例覆盖（尤其：多命令交替写决策后 ID 不碰撞、changeset 重生成不覆盖）。

---

*裁定依据：WO-20260903-0027R1 工单验收条款、0027H 工单 OJP Acceptance、07.工程 §一之三硬标准 #4、AGENTS.md「写入口唯一」原则。*
