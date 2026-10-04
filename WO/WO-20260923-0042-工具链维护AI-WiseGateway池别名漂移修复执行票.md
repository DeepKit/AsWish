# WO-20260923-0042 · 工具链维护AI · WiseGateway 池别名漂移修复执行票（WO-0040 实施细则）

- **状态（2026-09-24）**：老板已批，**待转发**给有 `.BetterCiv`/`00Common/skills` 写权限的
  维护AI 执行。补丁包三件齐（remap_apply.py / README.md / review_queue.md，后者已回填
  主控 §C 五项裁定，无待老板项）。

> **2026-09-30 主控更新（实测，非采信票面）**：
> ① Phase 1 的 1:1 重映射**已被人执行过**——`remap_apply.py` dry-run 从开票时的 76 处
>    降为今天的 **0 处**可替换，但本票"执行记录"节仍为空，**无人回填**。
> ② Phase 1 冒烟判据**不过**：`bcw.py verify-pools` 今天退出码 **7**
>    （L1缺:主力别名不在网关models_usable / L2孤儿 / L3γ探针失败），
>    连重映射目标名 `claude-glm-5.3` / `claude-gpt-5.6-sol` / `claude-sonnet-5` /
>    `claude-qwen3.8-max` 也大量不在册。**先归因（网关目录变了，还是 `models_usable`
>    取法受 401 影响），不许照旧名单再 remap 一次。**
> ③ 票面声称"补齐"的 `README.md` 与 `review_queue.md` **不在盘上**
>    （`D:/BCW/inbox/bcw/aswish-wo0040/` 只有 `remap_apply.py` 和
>    `expert-model-policy.json.bak`），Phase 2 的 28 条队列无清单可执行。
> ④ Phase 3 六项加固锚点（`MODEL_NOT_IN_POOL` / `MEETING_NO_QUORUM` 等）0 命中 ⇒ 全未做。
>
> 以上全部由 **WO-20260930-0065** 承接（T-1 归因 / T-2 补清单并收口 Phase 2 /
> T-3 Phase 3 六项加固）。**本票不要再整体重新认领**；
> §C 五项主控裁定继续有效，直接采用，不要重复上报老板。

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

---

## 主控复核裁定（2026-09-23 17:2x，主控独立取证，非采信票面自述）

**结论：准，附条件执行 —— Phase 1 可跑；Phase 2 在补齐清单前不许开工。**

### A. 前提复核：漂移属实（主控实测，不是采信）
- 网关 8000 现暴露 **44 个模型**，全是 `claude-*` 前缀。
- 池里这些旧前缀名**在网关目录里全部不存在**：`commandcode-kimi-k3`、`duojie-glm-5.3`、`opencodego-kimi-k3`、`fccy-gpt-5.6-sol`、`claude-opus-5`、`deepseek-v4-flash`、`step-3.7-flash` ⇒ 客户端名单与网关契约脱节属实。
- **12 个重映射目标名主控已逐个验证存在于 44 目录**（`claude-kimi-k3`/`claude-glm-5.2`/`claude-gpt-5.6-sol`/`claude-minimax-m3`/`claude-kimi-k2.7-code`/`claude-laguna-s-2.1`/`claude-nemotron-120b-nim`/`claude-gpt-5.6-luna`/`claude-qwen3.8-max`/`claude-glm-5.3`/`claude-nemotron-550b-nim`/`claude-sonnet-5`）⇒ **缺失 0**，重映射不会把故障从"旧名"搬到"另一个不存在的名"。

### B. 执行前必须满足的 4 个条件
1. **补齐票面引用件**：补丁包 `D:/BCW/inbox/bcw/aswish-wo0040/` 现在**只有 `remap_apply.py`**，票面引用的 `README` 与 `review_queue.md`（28 条待审队列）**都不存在** ⇒ Phase 2 无清单即无法执行、无法验收，先补齐再开工。
2. **数字以实测回填**：主控 dry-run 实测 **76 处**（expert-model-policy 8 / model-roles 46 / model_pools 22）。票面"~77"基本吻合；但脚本 docstring 里的 "46" 只是 model-roles 一个文件的数，**不许当总数引用**。
3. **主控仪器边界**：`D:\_Progs\.BetterCiv\09_工程脚本\bcw\model_pools.yaml` 是主控登记的**主控仪器 / 成本档真相源** ⇒ 只允许替换别名字符串，**`cost`/`health`/`route` 字段必须零改动**（diff 可核）；改前 `.bak` + git 快照，改后 `verify-pools` 复跑。越界即按"被审方改审计仪器"处理。
4. **跨项目共享面**：`D:\_Progs\00Common\skills\_shared\expert-model-policy.json` 是跨仓共享配置 ⇒ 改前必须先列出谁在读它（影响面清单），再执行。

### C. Phase 2 五处 ★ 的主控裁定（能裁的已裁，不上推老板）
| ★ | 问题 | 主控裁定 | 依据 |
|:--|:--|:--|:--|
| 1 | opus 缺席，会议主审席用什么顶 | **用 `claude-sonnet-5`**（同族、定位最接近；`duojie-oai-001` 包月档）。可逆，老板一句话可改 | 目录实测存在；与 `claude-gpt-5.6-sol` 同为包月档，选同族 |
| 2 | stepfun 3.5→3.7 版本漂移是否接受 | **接受升 3.7** | 池里 3.5 有 5 处、3.7 有 9 处；网关侧只有 `step-3.7-flash`/`stepfun/Step-3.7-Flash`，**3.5 已无供给** |
| 3 | 免费位全部消失是否找网关侧补通道 | **不补通道，走重映射即可**（省一次花钱决策） | 网关侧免费档仍有 **26 条 tier / 19 个模型**，免费位没消失，是客户端名单没跟上 |
| 4 | deepseek v4→v4.1 统一升档 | **批准升档**（不是可选项） | 主控实测上游：`deepseek-ai/deepseek-v4-flash-0731` → **HTTP 410 Gone，2026-09-21 08:00Z 已 EOL**；裸名 `deepseek-v4-flash`/`deepseek-v4-pro` 亦不在 44 目录 |
| 5 | qoder-local / Cantus / 退役项清理 | **清**（无需再问老板） | 与既有约束「模型渠道/Qoder 停用」一致，老板 8 月已停用 |

### D. 仍然成立的两条纪律（票面已写，主控背书）
- 不动网关侧代码；不扩大模型池。
- Phase 3 六项防复发加固合理，可与 Phase 1 并行后排；每项必须有**带错误码的验收输出**（`MODEL_NOT_IN_POOL` / `MEETING_NO_QUORUM` 等），只写"已加固"不算完成。
