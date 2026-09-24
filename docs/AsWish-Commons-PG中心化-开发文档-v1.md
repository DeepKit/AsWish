# AsWish Commons PG 中心化同步 — 开发文档 v1（待审阅）

- 日期：2026-09-24 · 撰写：Amy
- 法源：老板 2026-09-24 裁定（覆盖 WO-20260923-0046 选项 A/B/C 框架，裁定原文：
  "直接创建 PG 数据库，它会同步到服务器，以后所有的客户端都可以使用"）
- **状态（2026-09-24）：已批准开工。** 老板三勾裁定原文：
  "PG 就使用本机的就可以，它会自动同步到远程服务器；同意；执行"——即
  ① 本机 PG + 既有自动同步链，不另立库；② 种子 10 条不默认进公共库（P-2 附预审清单，逐条人工放行）；
  ③ 贡献者用匿名 client id，不绑身份体系。
  执行工单：WO-20260924-0048（PG 侧 P-1~P-3，外派）/ WO-20260924-0049（AsWish 侧 P-4~P-5）。

## 一、要达成什么

避坑经验库（Difference Commons）从"单机 yaml 文件"升级为 **PG 中心库**：
本机 AsWish 产生 lesson → 同步入 PG → PG 随既有备份/同步机制上服务器 → 任何客户端
（AsWish 实例、AI 工作台、未来 CLI）可拉取复用。

## 二、架构（三层，复用全现有）

```text
[AsWish 客户端]                [中心]                 [分发]
.AsWish/commons/*.yaml   →    PG bcw_runtime.       →   pull/注入
（本地工作存储，不变）         commons_lesson 表          各客户端 commons/
        ↑ 上传/拉取经 workbench.py commons-sync 子命令
```

关键原则：
1. **本地 yaml 仍是工作存储**——AsWish 零新增 DB 依赖（Delphi 侧不直连 PG），
   同步全部走 `workbench.py`（Python 侧已有 PG store、migrate_engine、governance-sync 全套设施，照抄模式）；
2. 同步是**显式动作**（`commons-sync push/pull`），不自动外发——老板裁定的"出本机"生效，
   但每一批出去的东西可审计；
3. PG 表结构走 migrate_engine 注册（吸取 BCW-TD20260814-002 教训：**建表必须同批注册
   schema_migrations 版本号**，否则 drift；具体版本号实现时取 migrate 引擎 next，不在文档写死）。

## 三、表设计（DDL 草案）

```sql
CREATE TABLE bcw_runtime.commons_lesson (
  lesson_id      text NOT NULL,           -- lesson-0001 / lesson-extract-<cs>
  pack_version   int  NOT NULL DEFAULT 1, -- schema 版本，冲突仲裁用
  content_hash   text NOT NULL,           -- TSpecHash.LessonContentHash 同算法
  title          text NOT NULL,
  trigger_pattern text,
  wrong_expression text,
  right_expression text,
  human_takeaway text,
  domain         text,
  story_mode     text,                    -- 沿用现有词表
  anchor_kind    text NOT NULL,           -- machine | narrative（0043 语义，强制声明）
  baseline_ref   text,
  difference_ref text,
  anchor_blob    jsonb,                   -- machine 锚: {path, sha256, slice_yaml} 自包含切片
  contributed_by text NOT NULL,           -- seed:aswish-dogfood | client:<id>
  publish_consent boolean NOT NULL DEFAULT false,  -- ★ 见隐私节
  redacted       boolean NOT NULL DEFAULT false,
  source_client  text,                    -- 客户端标识与仓库指纹
  created_at     timestamptz NOT NULL,
  updated_at     timestamptz NOT NULL,
  PRIMARY KEY (lesson_id, content_hash)
);
CREATE INDEX ON bcw_runtime.commons_lesson (domain, updated_at DESC);
```

要点：
- **主键含 content_hash**：同 id 不同内容 = 不同行（版本并存，客户端取 updated_at 最新，
  不覆盖历史——与"Immutable History"协议一致）；
- `anchor_blob` 自包含：machine 锚的**证据切片直接进库**（jsonb），解决 0045 在 PG 层的复现
  ——拉取方不再需要贡献者的 dogfood 目录，锚解析=对 blob 内 sha256 重算比对；
- `narrative` 锚永不自带可复核声明（界面角标逻辑随数据下发）。

## 四、隐私与外发边界（红线，实现前必读）

lesson 含人类裁定原文（意图/拒绝理由），外发默认关：
1. `publish_consent=false` 的行**禁止被 push 选中**（sync 工具 fail-closed）；
2. 客户端 🚩 按钮流程（0041 S-3）加一步可选勾选"愿分享给公共库"，默认不勾；
3. push 前自动脱敏：剥离绝对路径、用户名、机器名（正则清单固化进测试）；
   脱敏改动的行 `redacted=true`，审阅卡显示"已脱敏，原始在本机"；
4. pull 侧同样防污染：narrative 锚经验在 UI 永远带警示，machine 锚解析失败**拒绝入库**
   （复用 ResolveAnchor 拒灌逻辑，负例测试同构）；
5. 服务端零删除通道：不提供 delete API，只追加与修订（与 BCW 事件表审计留存一致）。

## 五、同步命令（workbench.py 新增子命令）

| 命令 | 行为 |
|---|---|
| `commons-sync push <AsWish项目路径> [--include-seed]` | 收集 commons/*.yaml → 脱敏 → 仅 consent 行 upsert PG；输出逐行判定（含拒因） |
| `commons-sync pull [domain]` | 拉公共行 → 落 `<项目>/.AsWish/commons/` 新文件（lesson-<clientid>-* 命名防撞）→ 锚完整性重算 |
| `commons-sync status` | 本地/远端计数差集 + consent 未推清单（不催，供报告） |

AsWish Delphi 侧**只加一件事**：读 yaml 目录不变，Ghosts/S-4 引擎零改动（PG 行拉回即本地 yaml 格式）。

## 六、实施拆分（批准后按此开票，每张 ≤200 行粒度）

- P-1 migrate 注册 + 建表 + 一致性测试（schema_migrations drift 回归必含）
- P-2 workbench commons-sync（push：脱敏/consent fail-closed + 单测）
- P-3 pull + 锚 blob 重算校验 + 防撞命名（单测）
- P-4 GUI 🚩流程加 consent 勾选与脱敏提示（含 GUI 自动化断言）
- P-5 端到端验收：双客户端场景——A 机推 3 条（1 拒 2 过），B 机拉取后 Ghosts 命中
  2 条、第 3 条因缺 consent 未出现（完整输出留证）；SPW 不回退

## 七、待老板审阅的决策点（三项，勾完即可开工）

| # | 问题 | Amy 建议 |
|---|---|---|
| ① | 服务器同步走**现有 BCW PG 备份通道**（PG 所在机器即服务器），还是另立独立 commons 库 | 走现有（少一个运维面） |
| ② | 种子 10 条（我们的翻车记录）默认进公共库？其内容含内部仓库路径与工作叙事 | **不进**，需人工脱敏审一遍再推（P-2 附种子预审清单） |
| ③ | 未来外部用户（非本机 AI）要贡献 lesson 时，`contributed_by` 要不要绑定身份体系 | 现阶段只 `client:<uuid>`，身份体系等公共化有真实外人再说 |

> 本文档批准 + 三勾定 ⇒ 按 P-1~P-5 开票派发。
