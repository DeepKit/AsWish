# 审计裁决：WO-20260923-0043 返修 · **APPROVED / CLOSE**（审计人：Amy，2026-09-23）

- 被审：`WO/AUDIT-REQUEST-WO-20260923-0043-甲.md`（0041 返修，二次审计）
- 范围：按 0041 裁决书约定缩减复验（F-1/F-2 断言 + 全量 + SPW），全部独立重跑，未采信票面

## 复验结果

| 项 | 审计实测 | 判定 |
|---|---|---|
| 4 commits ≤200 行 | 最大 86 insertions（git show --stat 逐个） | ✅ |
| F-1 机制 | `anchor_kind` 入 schema/模型，空值默认 narrative（禁裸串伪装） | ✅ |
| F-1 实锚三条 | lesson-0002/0003/0009 锚点=**真实存在的工作区产物文件**（6 路径 find 实测全 EXISTS） | ✅ |
| F-1 拒灌 | `SeedCommonsLessonsIfEmpty` machine 锚解析失败拒灌；负例 Test05 实存 | ✅ |
| F-2 血统反查 | 经 Decision.ChangeSetId 反查 baseline，失败降级 narrative；Test06 覆盖 | ✅ |
| F-3 覆盖 | Commons 单元入 subject_files（其余四文件原本在册） | ✅ |
| F-4 | 措辞改 OpenView 宿主面板 | ✅ |
| 全量测试 | 本机重跑 **251/251**（0 fail/leaked/errored） | ✅ |
| SPW | 独立全新构建跑 8/8 PASS（`WO/evidence/spw-audit-0043.json`），`release_ready=false` 仅 H5 专家池 outage（WO-0042 范围，与本单无关） | ✅ |

## 已知限制（P2 记录，不重开返修）

**machine 锚当前指向 `dogfood/` 下未被 git 跟踪的产物**——在产生它的机器上可解析，
换克隆即解析失败（拒灌逻辑会正确生效，诚实性不受损，但"可复核"不可移植）。
后续二选一即可，不阻塞合入：(a) 把三个锚文件纳入版本控制；(b) schema 增 `machine:local` 层级。
建议随 Difference Commons 社区化时一并定夺（届时本就要定上传/便携边界）。

## 结论

WO-0041 主链 + WO-0043 返修 **全部 CLOSE**。Commons S-1~S-4 达到工单承诺：
能验的验，不能验的明说——种子库自身不再犯 lesson-0007。
