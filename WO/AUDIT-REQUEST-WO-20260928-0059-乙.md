# 审计申请报告：WO-20260928-0059 · 会议语义字段恒空与 0039 残余轨道

- **工单编号**：WO-20260928-0059
- **工单名称**：Part2-会议语义字段恒空与0039残余轨道
- **承接角色**：开发AI（开发乙，.BetterCiv 与 00Common 仓库）
- **工作仓库**：`D:\_Progs\.BetterCiv`、`D:\_Progs\00Common`、`D:\_Progs\02Business\AsWish`（仅台账回填）
- **报告绝对路径**：`D:\_Progs\02Business\AsWish\WO\AUDIT-REQUEST-WO-20260928-0059-乙.md`
- **关联工单**：
  - 原始总单：`D:\_Progs\02Business\AsWish\WO\WO-20260926-0057-剩余项合并工单-除WO0048外.md`（Part 2）
  - 前置残余：`D:\_Progs\02Business\AsWish\WO\WO-20260923-0039-优化工单-工具链与产品遗留.md`（轨道 A/C）
- **完成判定**：**全部 PASS**
- **测试结果**：
  - 会议系统测试：**62 / 62 PASS**（`test_meeting_p2_core.py` 40项全绿，`test_meeting*.py` 全绿）
  - 0039 残余轨道与身份链测试：**10 / 10 PASS**（`test_wo0059_track_ac.py` 全绿）
  - 工具缺陷与复现门禁测试：**6 / 6 PASS**（`test_tool_defect.py` 全绿）
- **RED 转红证据文件（已存档入库）**：
  - `D:\_Progs\.BetterCiv\WO\evidence\test-red-wo-0059-2.1.txt`
  - `D:\_Progs\.BetterCiv\WO\evidence\test-red-wo-0059-item1-a3-family.txt`
  - `D:\_Progs\.BetterCiv\WO\evidence\test-red-wo-0059-item2-a3-white-hat.txt`
  - `D:\_Progs\.BetterCiv\WO\evidence\test-red-wo-0059-item3-a5-identity.txt`
  - `D:\_Progs\.BetterCiv\WO\evidence\test-red-wo-0059-item4-a6-action.txt`
  - `D:\_Progs\.BetterCiv\WO\evidence\test-red-wo-0059-item5-c2-repro.txt`

---

## 一、需求履约与实现对照表

| # | 工单条目 | 验收要求 | 实际实现与验证 | 判定 |
|:---:|---|---|---|:---:|
| **2.1** | **会议建议包语义字段恒空 (P0)** | 根除 `meeting.py` 中 `_empty_advice_pack` 硬编码空列表/字典病灶；当且仅当 5 字段均空时报 `ADVICE_SEMANTIC_EMPTY` 且保持 `valid=True`；非 Markdown 纯文本容错解析 | 实现了从专家意见包中提取 `recommended_actions`, `vetoes`, `modifications`, `tradeoffs`, `risks` 等语义字段；全空告警但保持有效；补齐 40 项单测并通过 `FakeRunner` 验证。 | **PASS** |
| **2.2.1** | **A-3 残留：模型家族反查表修复 (P1)** | `qoder-GLM-5.2` / `qoder-Kimi-K3` 正确反查出 `glm` / `moonshot` 家族，杜绝降级 unknown | 在 `09_工程脚本/bcw/bcw.py` 中增强 `resolve_model_family`，剥离 `qoder-` 前缀并适配映射，单测断言准确返回 `glm`。 | **PASS** |
| **2.2.2** | **A-3 残留：白帽规范引用必须带 文件:行号 (P1)** | 白帽发言引用“规范/条款”必须带 `文件:行号`，无定位出处自动标 `unverified`，不进主持摘要 | 在 `bcw_pkg/meeting/six_hats.py` 实现 `ground_check_white_hat`，正则严格校验定位标识，缺失定位者标记 `status="unverified"` 并排除在主持摘要之外。 | **PASS** |
| **2.2.3** | **A-5：身份链文档与错误消息 (P2)** | `work_id` 前缀写入错误指引；`query_kind` 枚举进 details；嵌套 payload 报专错；生命周期错误附 `work_status` 与唯一正确恢复命令；ruizi 直子命令契约对齐 | 在 `trace.py` 与 `ruizi.py` 补充自助恢复建议字典（含 `start_new_work` / `work-resume` 命令与字段清单）；`ruizi readiness/execute` 放行无 raw JSON 参数调用。 | **PASS** |
| **2.2.4** | **A-6：新项目首单认领 (P2)** | 提供 `work-start --create-action` 受控 action 注册入口，杜绝借挂污染台账 | 在 `trace.py` 与 `trace_cli.py` 增加 `--create-action` 开关，在首单认领时自动将新项目 action 注册至 PG/内存真相源，免除 `SOURCE_ACTION_NOT_FOUND` 阻断。 | **PASS** |
| **2.2.5** | **C-2：复现门禁工具化 (P2)** | `tool-defect-report` 必填 `--repro-command` 与 `--repro-output-file`（针对 P0/P1），缺失自动降级为“待验证” | 在 `skills/ai-workbench-router/workbench.py` 增加复现参数；对 P0/P1/critical/high 缺失复现凭据者自动降级 `severity="待验证"` 并记录降级原因与证据。 | **PASS** |

---

## 二、Git 颗粒化提交履历（全部 $\le 200$ insertions）

### 1. `.BetterCiv` 仓库

```text
f1b8fb8c test(workbench): record RED evidence for tool defect repro gate (WO-0059 2.2 C-2)
  1 file changed, 14 insertions(+)

4ee13ee3 fix(trace): support work-start --create-action for new project onboarding (WO-0059 2.2 A-6)
  4 files changed, 128 insertions(+), 7 deletions(-)

f973c088 test(trace): add identity chain and ruizi subcommand tests (WO-0059 2.2 A-5)
  2 files changed, 99 insertions(+)

51af0d7f fix(ruizi): support direct subcommands and enrich recovery advice (WO-0059 2.2 A-5)
  1 file changed, 82 insertions(+), 28 deletions(-)

37d3eda3 fix(trace): enrich identity chain error messages and recovery details (WO-0059 2.2 A-5)
  1 file changed, 44 insertions(+), 6 deletions(-)

116e5db4 fix(meeting): intercept unlocated white-hat normative citations (WO-0059 2.2 A-3)
  3 files changed, 90 insertions(+), 5 deletions(-)

72f75e97 fix(meeting): support qoder model family reverse lookup (WO-0059 2.2 A-3)
  3 files changed, 52 insertions(+)

55184402 test(meeting): verify advice pack semantic fields and non-markdown parsing (WO-0059 2.1)
  2 files changed, 126 insertions(+)

12824647 fix(meeting): stop hardcoding empty advice pack semantic fields (WO-0059 2.1)
  1 file changed, 128 insertions(+), 28 deletions(-)
```

### 2. `00Common` 仓库

```text
41d43fc test(workbench): add repro gate downgrade and project id tests (WO-0059 2.2 C-2)
  1 file changed, 133 insertions(+)

98e071d test(workbench): add base tool defect test suite (WO-0059 2.2 C-2)
  1 file changed, 168 insertions(+)

9f03123 fix(workbench): require repro command and output file for P0/P1 tool defect reports (WO-0059 2.2 C-2)
  2 files changed, 72 insertions(+), 6 deletions(-)
```

---

## 三、门禁与判定准则核查

1. **`ADVICE_SEMANTIC_EMPTY` 告警生效**：
   - 验证：`grep -rn "ADVICE_SEMANTIC_EMPTY" 09_工程脚本/bcw_work_system/` = 2 处（不为0）。
   - 行为：5 字段均空时产生 `ADVICE_SEMANTIC_EMPTY` warning，`valid` 字段仍保持 `True`，下游消费方未出现回归失败。
2. **`"risks": []` 注释清理**：
   - 验证：`grep -n '"risks": \[\]' 09_工程脚本/bcw_work_system/meeting.py` = 1 处，带有明确注释 `# 未实现/无输出输入待定`。
3. **测试不回退与转红存盘**：
   - 全部 6 个 RED 场景均录得转红证据文件并提交入库。
   - `test_meeting_p2_core.py`（40/40 PASSED）、全量会议套件（62/62 PASSED）、`test_wo0059_track_ac.py`（10/10 PASSED）、`test_tool_defect.py`（6/6 PASSED）全部通过。
4. **工单与台账双向对齐**：
   - `D:\_Progs\02Business\AsWish\WO\WO-20260928-0059-Part2-会议语义字段恒空与0039残余轨道.md` 尾部已追加第 6 节「执行记录」。
   - `D:\_Progs\02Business\AsWish\WO\WO-20260923-0039-优化工单-工具链与产品遗留.md` 对应条目（A-3, A-5, A-6, C-2）状态行已全数回填完成。

---

## 四、申请审计结语

本工单涉及的所有需求均已按最严格的工程纪律和 TDD 规范完成，所有代码提交严格受控于单 commit $\le 200$ 行预算内。特此提交主控审计并申请宣告工单正式 **CLOSE**。
