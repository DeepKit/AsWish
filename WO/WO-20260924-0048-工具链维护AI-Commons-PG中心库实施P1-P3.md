# WO-20260924-0048 · 工具链维护AI · Commons PG 中心库实施（P-1~P-3）

- 下发时间：2026-09-24 · 下发人：Amy · 依据：**老板 2026-09-24 批准**（三勾记录见设计文档头部）
- 冻结契约：`docs/AsWish-Commons-PG中心化-开发文档-v1.md` §三/§四/§五（表结构、隐私闸、命令面）
- 承接方：有 `.BetterCiv` / `00Common/skills` 写权限的维护AI（与 WO-0042 同侧，可同人顺序执行）
- 优先级：P1 · 单 commit ≤200 行，按 P-1→P-2→P-3 顺序三批提交

> **2026-09-30 主控更新（零开工复核）**：主控按 `WO-20260924-0048-完工核验报告-未开工.md`
> 的口径重跑了一遍，结论不变——**仍是零行开工**：`bcw_work_system` 全树搜不到
> `commons_lesson` / `commons-sync` / `publish_consent`，`migrations/` 仍只有 3 个文件
> （最新 `2026-09-02_daily_record_and_production_line.sql`），无 commons 版本号。
> 老板 2026-09-26 已决定另找 AI 开发本单。**下游 WO-0049 的 P-5 端到端验收整条挂在本单上。**

## 任务（细节以设计文档为准，此处只列验收）

| 步 | 内容 | 硬验收 |
|---|---|---|
| P-1 | `bcw_runtime.commons_lesson` 建表 + **migrate_engine 同批注册版本号** | schema_reconcile 无 drift（BCW-TD20260814-002 回归）；重跑幂等 |
| P-2 | `commons-sync push`：consent fail-closed、自动脱敏（路径/用户名/机器名正则清单）、种子排除 | 无 consent 行 100% 拒推并逐行报因；脱敏正则负例单测 |
| P-3 | `commons-sync pull` + 锚 blob 重算校验 + `lesson-<clientid>-*` 防撞命名 | 篡改 anchor_blob.sha256 的行必被拒入库；双客户端模拟不撞 id |

## 红线

- `publish_consent` 默认 false；不提供 delete API（只追加/修订）；
- 种子 10 条不进首批 push——预审清单单独提交给老板勾放行；
- 表结构如需偏离设计稿，先回改动说明，不许边写边改契约。
