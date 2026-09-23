# WO-20260923-0042 · 工具链维护AI · WiseGateway 池别名漂移修复执行票（WO-0040 实施细则）

- 下发时间：2026-09-23 (GMT+8)
- 下发人：Amy（代甲的执行成果打包）
- 承接方：有 `D:\_Progs\.BetterCiv` 与 `D:\_Progs\00Common\skills` 写权限的维护AI（bcw/luoji）
- 优先级：P0 —— invoke 双通道、六帽、fastmeet、睿智派发全被此一处漂移卡死
- 根因与探测证据：见 `WO-20260923-0040`（本票不重复论证，只给动作）
- 补丁包：`D:/BCW/inbox/bcw/aswish-wo0040/`（已沙箱 dry-run 验证）

> 本票三个阶段。**Phase 1 做完系统即恢复可用**；Phase 2 有 5 处标 ★ 必须回给老板裁定，
> 不许自行降档；Phase 3 是防复发加固，可并行排后。

---

## Phase 1 · 别名重映射（预计 10 分钟，系统解阻）

1. 快照回滚点：
   ```
   git -C D:/_Progs/.BetterCiv add -A && git -C D:/_Progs/.BetterCiv commit -m "pre-wo0042 snapshot"
   备份 D:\_Progs\00Common\skills\_shared\expert-model-policy.json 到 inbox 同目录 .bak
   ```
2. 核对与执行：
   ```
   python -X utf8 D:/BCW/inbox/bcw/aswish-wo0040/remap_apply.py          # dry-run，预期合计 ~77 处、三文件计数见 README
   python -X utf8 D:/BCW/inbox/bcw/aswish-wo0040/remap_apply.py --apply
   ```
3. 冒烟（全过才算完）：
   - `bcw.py verify-pools`：无 `no_candidate`；
   - 任一 AWT 任务 `workbench.py invoke --provider wisegateway` 端到端成功、task.json 落 `specialist_run_ref`；
   - `fastmeet` 最小局（3+1）跑通一次。
4. 回滚：git checkout 快照点 + 恢复 .bak。

## Phase 2 · 待审队列 28 条（`review_queue.md`）

- 逐条落"替换/降级/移除"三选一结论，能自裁的写理由直接改；
- **5 处 ★ 必须出老板裁定请求（请示五字段）**，不许静默执行：
  1. opus 旗舰缺席 → 会议主审席用什么顶（claude-sonnet-5 还是 gpt-5.6-sol）；
  2. stepfun 3.5→3.7 版本漂移是否接受；
  3. 免费位全部消失是否找网关侧补通道；
  4. deepseek v4→v4.1 统一升档；
  5. qoder-local/Cantus/已退役项的清理确认（Cantus 老板 8 月已停用，移除即可，但要书面确认）。
- 完成后全池 `verify-pools` 复跑 + `diverge` 满席实测一次。

## Phase 3 · 防复发加固（BUG 台账对应项）

| # | 锚点 | 动作 | 验收 |
|---|---|---|---|
| 1 | workbench.py `_gateway_messages_call`（~4967）`_resolve_route_id`（~4785） | channel 解析空且别名不在池 → 抛 `MODEL_NOT_IN_POOL`，附前 10 个 live 别名 | 用假别名 invoke，报 MODEL_NOT_IN_POOL 而非网关 404/422 |
| 2 | workbench.py `roundtable_init`（~1437） | 默认 session-dir 改 `D:/BCW/runs/bcw/roundtable/<task_id>` | 不带 `--session-dir` init→step 不触边界（BUG-M2） |
| 3 | spw/scripts/spw.py gate 执行 | 支持可选 `cwd` 字段；`cmd /c` 含 `&&` 时给引号保留行为提示 | `cmd /c "A && B"` 型 gate 可跑或明确拒绝（BUG-M8 通用面） |
| 4 | bcw six-hats/fastmeet 开场 | 池探测可用席位 < 配置下限 → `MEETING_NO_QUORUM` fail-closed | 拔 2/3 席位模拟 → 拒开不空转（BUG-M3，与 BCW-TD20260811-002 并案） |
| 5 | workbench.py claude-code provider（~5424 `--safe-mode`） | 参数集按本机 `claude --help` 探测生成 | `invoke --provider claude-code` 端到端一次（BUG-M6） |
| 6 | spw manifest 校验器 | gates 引用的脚本路径不在所在仓版本控制内 → fail-closed | 指向 Temp 的 gate 被校验器直接拒（WO-0039 C-1） |

## 完成定义

Phase 1 全冒烟绿 + Phase 2 队列清零（★ 项有老板裁定号）+ Phase 3 六项各有带错误码的验收输出，
并在本票尾部回填「执行记录」节（执行人/时间/命令输出摘要）。单 commit ≤200 行分主题提交。

## 明确不做

- 不动网关侧代码（别名改名本身可能是网关有意为之，客户端跟配置即可；若需网关恢复旧别名兼容层，另开工单问老板）；
- 不扩大模型池（补通道归网关/老板，不在本票）。
