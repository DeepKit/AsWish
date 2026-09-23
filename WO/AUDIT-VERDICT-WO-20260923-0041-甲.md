# 审计裁决：WO-20260923-0041 · Difference Commons（审计人：Amy，2026-09-23）

- 被审报告：`WO/AUDIT-REQUEST-WO-20260923-0041-甲.md`
- 审计方式：BCW-D20260923-002 独立取证——全部关键数字与门禁由审计人本机重跑，未采信票面自述
- **裁决：RETURNED（退回返修一次）**——一次通过机会，修复项见 F-1；F-2/F-3 随批处理

## 一、复核通过项（独立实测）

| 票面主张 | 审计实测 | 结果 |
|---|---|---|
| GUI/Tests 编译 exit=0，24896/30519 行 | 本机重跑同形同数 | ✅ 吻合 |
| 249/249 PASS 0 Leaked | 本机重跑 249/249/0/0 | ✅ 吻合 |
| 单 commit ≤200 行 ×6 | git show --stat 逐个：194 最大 | ✅ |
| 零网络上传 | Commons 单元 grep 外发原语 = 0；🚩走 SpecStore 本地盘 | ✅ |
| S-3 与我侧 B-2（Gate 后清 LastChangeSetId）配合 | FLastGateCsId 在清态前捕获（1215/1247），按钮 1220 激活，提取用捕获值 | ✅ 时序正确 |
| Schema↔模型字段一致 / LessonContentHash 存在 | python 比对无缺漏；Hash.pas:304 实存 | ✅ |
| SPW 不回退 | 审计人独立跑 `WO/evidence/spw-audit-0041.json` **8/8 PASS verdict=PASS** | ✅ |

## 二、退回项

### F-1（必改）· 7/10 种子的溯源锚是虚构字符串
工单原文承诺"`baseline_ref`/`difference_ref`（**溯源锚，哈希校验**）"。实测：
- `bl-user-lifecycle-001`、`dec-gate-0001`、`diff-20260906-frame` 等锚点在
  `dogfood/` 全库 find 无一命中，不解析到任何已持久化产物；
- schema 里两字段是裸 `{"type":"string"}`，无任何验证语义。

**这恰是 lesson-0007 自己 preaching 的失效模式**（"缺乏可验引用的来源不是证据，只是口头声明"）——
种子库自身不可溯源，第一次安装用户的"历史经验防坑"震撼就是纸面震撼。
其中 lesson-0002/0003/0009 对应真实事故（c8d8113→ee66b35、payment-retry dogfood），可救；
其余按两条路线任选其一整改并在交付时明示：
(a) **实锚化**：锚点替换为仓库内可解析的真实产物路径/ID（decisions、baselines、diff yaml），
    并在 `SeedCommonsLessonsIfEmpty` 或读回路径加一条锚点存在性检查（不可解析 → 拒绝灌入）；
(b) **诚实降级**：schema 增加 `anchor_kind: machine|narrative` 字段，种子标 narrative
    并在 HTML 警示卡显示"经验教训源自实践总结，非可复核记录"——把话说对，不算违约。
禁止保持现状（字符串长得像可验锚却不声明不验）。

### F-2（随批）· 提取锚取错基线
`ExtractCommonsLesson` 取 `LBaselines[0]`（列表首位）当溯源锚。应经 Decision.ChangeSetId
→ Baseline.Lineage.ChangeSetId 反查**该次决断对应**的 baseline；查不到就留空并标 narrative，
不许张冠李戴。

### F-3（随批）· manifest 覆盖面重复犯 C-1 同类缺口
Commons 五件套（Services.Commons/Models/Hash/Writer/SpecStore 改动）均未进
`spw-manifest.json` subject_files——被审改动绕过门禁覆盖面，正是 WO-0039 C-1
要根治的问题。请补入后重跑 SPW 留证。

### F-4（文字）· 预览方式表述失实
票面"以系统默认浏览器打开 HTML 预览"，实现为 `OpenView`（shell 宿主面板内）。改措辞或改实现，二选一。

## 三、流程记录

- 本单是 BCW-D20260923-002 生效后收到的第一张真实审计申请，且"复现门禁"抓到的第一个
  缺陷类型恰好是**种子内容自身不可复现**——规则经受住了首次实战；
- 返修一次机会按 SPW/审计惯例执行；修复后仅重跑 F-1/F-2 相关断言 + SPW 即可 CLOSE，不必全量再审。
