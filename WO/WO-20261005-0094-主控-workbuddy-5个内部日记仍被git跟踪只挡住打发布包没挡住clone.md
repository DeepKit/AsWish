# WO-20261005-0094 · 主控 · `.workbuddy/` 5 个内部日记仍被 git 跟踪：只挡住了打发布包，没挡住 clone

- 下发时间：2026-10-05 · 下发人：主控 · 依据：**主控 `git ls-files` 实测（HEAD=c5324ed）**
- 优先级：**P2（不阻塞门禁运行，阻塞开源交付；内部过程痕迹外泄面）**
- 主执行：**工具链维护AI**
- 状态：**confirmed（主控实测 5 个文件在 `git ls-files` 中，`.gitignore` 无对应条目）**

---

## 一、缺陷本体

### 1.1 实测清单

```
git ls-files | grep -i workbuddy
  .workbuddy/memory/2026-08-29.md     1851 B
  .workbuddy/memory/2026-08-30.md    14083 B
  .workbuddy/memory/2026-08-31.md    18390 B
  .workbuddy/memory/2026-09-01.md     5522 B
  .workbuddy/memory/2026-09-03.md     1104 B
合计 40950 B，最后改动 commit 27ad8b2（2026-09-03），历史共 7 个提交碰过。
```

### 1.2 现状：只挡住了"打发布包"，没挡住"clone"

`.gitattributes:15` 有 `.workbuddy/ export-ignore`，
所以 `git archive` 打出来的发布包**不含**这 5 个文件——这一步是对的。
但 `git ls-files` 仍把它们列在跟踪区，意味着：

- **任何人 `git clone` 本仓库，就能读到全部 5 个文件**；
- 在 GitHub 上点开仓库文件树同样看得到；
- `git log -p -- .workbuddy/` 能翻出历史版本（含已删除/已改写的中间稿）。

内容是 WorkBuddy 的内部每日 memory 日记：待裁定决策清单、研究笔记、会话交接记录。
与软件功能无关，属于**内部治理过程痕迹**，不应随源码分发。

### 1.3 与 WO-0088 的关系

WO-0088 阶段记录当时判定"`.workbuddy/` 仍 5 个被跟踪（**仅因**方案 B + export-ignore 而含住）"。
本单把"仅因"这个临时条件落实成结构性约束。

---

## 二、执行阶段

### 阶段 1：停止跟踪 + 忽略（必做）

1. `git rm -r --cached .workbuddy/`（**只动索引，不动磁盘文件**——
   本地日记必须保留，那是正在使用的运行态）；
2. `.gitignore` 增加 `.workbuddy/`（当前 `.gitignore` **没有**该条目，已实测确认）；
3. 提交，信息如实说明"停止跟踪内部治理日记，文件保留在本地"。

### 阶段 2：历史清除（必做，需老板授权后执行）

阶段 1 只让**未来**提交不含这些文件；历史 blob 仍在。
由于本仓**从未 push**（`origin/main` 落后本地 304 个提交，且 origin 侧不含 `.workbuddy/`，
主控已实测），重写历史的代价为零、无外部影响：

1. 用 `git filter-repo --path .workbuddy/ --invert-paths` 从全部历史中移除该目录
   （若工具不可用，退 `git filter-branch --index-filter` + `git gc`，须逐条验证 blob 已消失）；
2. 重建后必须验证：
   - `git rev-list --objects --all | grep workbuddy` → **空**；
   - `git log --oneline -- .workbuddy` → **空**；
   - `git cat-file -t <原blob hash>` 逐个确认 `bf8b0c4 / b9f1888 / f446383 / 2918f35 / 092f99c` → `missing`；
3. 重写后重新生成一次证据包（H4 门禁读的是工作树，行为应不变），
   12 门禁须仍 RC=0；
4. **本阶段执行前必须取得老板明确授权**（历史重写不可逆）。

### 阶段 3：哨兵门禁（必做，防止再犯）

`G.open-source-build` 或 `gate_external_boundary.py` 增加断言：
仓库内不得出现 WorkBuddy/BCW 内部运行态目录被 `git ls-files` 跟踪，
一旦出现 → RC=1。列出明确的目录名清单（`.workbuddy/`、`.claude/sessions/` 等），
写进 manifest 而不是硬编码。

---

## 三、验收（主控逐条复跑）

1. `git ls-files | grep -c workbuddy` → **0**；
2. `grep -n workbuddy .gitignore` → 有对应条目；
3. `git rev-list --objects --all | grep -c workbuddy` → **0**（阶段 2 完成后）；
4. 本地磁盘 `.workbuddy/memory/*.md` 5 个文件**仍然存在且内容未变**
   （`sha256` 与阶段 1 前一致——停止跟踪不等于删内容）；
5. 反证：`git add .workbuddy/memory/2026-09-03.md` → 门禁 RC=1；
6. 阶段 2 后 `git log --oneline | wc -l` 与 `origin/main` 的差距如实记录，
   全量 12 门禁仍 RC=0；
7. `git status --porcelain` = 0（除本单自身工单文件外）。

---

## 四、禁条

1. **不得**用 `git rm -r .workbuddy/`（不带 `--cached`）删掉本地文件——
   那会毁掉正在运行的 WorkBuddy 运行态。
2. **不得**保留历史 blob"以防万一"。要么清干净，要么不开源，没有中间态。
3. **不得**在阶段 2 未获老板授权前执行 history rewrite。
4. **不得**把 `.workbuddy/` 从 export-ignore 里删掉来"统一口径"——
   打发布包不含它是正确的，缺的是 clone 侧。
5. **不得**顺手清理其它内部目录（如 `docs/` 下其它文件）超出本单范围，
   发现新痕迹另开工单。

## 五、执行与验收留痕（2026-10-05，主控执行，老板已授权"清"）

### 1. 前置安全措施（执行 history rewrite 之前）

| 措施 | 结果 |
|---|---|
| `git clone --mirror` 到 `D:\_repro\aswish-mirror-backup-20261005` | 成功，HEAD 一致 `c5324ed`，5 个 blob + 7 个提交 + 2 个 tag 全在备份中 |
| 5 个本地文件拷至 `D:\_repro\workbuddy-archive-20261005` 并记录 sha256 | 成功，重写后逐一比对**完全一致** |
| 3 个 git worktree 的 index 备份至 `D:\_repro\worktree-index-backup` | 成功 |

### 2. 实际执行序列（含两个计划外的坑，均已查明并处置）

1. **`git filter-repo --invert-paths --path .workbuddy/ --force`** → 324 commits 重写，
   HEAD `c5324ed` → **`f37f39e`**。filter-repo 按其设计移除了 origin remote。
2. **坑一：本地文件被 reset 清掉**。`filter-repo` 收尾的 `reset --hard` 删掉了
   tracked 的 `.workbuddy/memory/*.md`（禁条 1 警告的情形**真的发生了**）。
   已从备份恢复，**5 个 sha256 与重写前逐一相同**（3494b883 / 5750f32e /
   28c95b19 / b4d4b5e1 / 38f43d87）。
3. **坑二：`gc --prune=now` 与 `repack -Ad` 都清不掉 5 个 blob**。
   端到端验证（`git clone --no-local` 到新目录）证明 clone 侧早已干净——0 跟踪、
   0 历史、blob 不可读；但本地 pack 里仍有。
4. **根因查明**：`.git/worktrees/` 下有 **3 个已注册 worktree**
   （`D:/Temp/wt-p4`、`wt-pre5`、`wt-render`，均 detached HEAD）。
   三者的**暂存区各自 `git add` 了 `.workbuddy/` 的 5 个文件**（`git status` 显示
   `A  .workbuddy/memory/...`，且这是它们唯一的暂存内容，无任何真实代码改动）。
   `pack-objects` 把 worktree index 当可达性根，所以 blob 永远 prune 不掉。
   → 对三个 worktree 各执行 `git read-tree HEAD` 重建索引（**不碰工作树、不碰
   HEAD、不碰分支**），暂存状态清空，`A` 变 `?? .workbuddy/`，无任何内容丢失。
5. **本地对象库重建**：旧 pack 移至 `D:\_repro\oldpack-backup`，
   换入从 `git rev-list --objects --all | git pack-objects` 生成的可达对象 pack。

### 3. 验收逐条实测

| # | 验收项 | 实测结果 |
|---|---|---|
| 1 | `git ls-files \| grep -c workbuddy` | **0** |
| 2 | `.gitignore` 含 `.workbuddy/` | 已加（连同 `.claude/sessions/`） |
| 3 | `git rev-list --objects --all \| grep -c workbuddy` | **0** |
| 4 | 本地 5 个文件仍在、内容未变 | **5 个 sha256 与重写前完全一致** |
| 5 | 反证 `git add -f .workbuddy/memory/2026-09-03.md` | **RC=1** `git 跟踪了内部运行态目录 .workbuddy/: 1 个` |
| 6 | `git fsck --full` | **完全干净，0 行输出**（含 worktree 修复后） |
| 7 | `git status --porcelain` | 仅本单自身改动 + 3 个工单文件，无 `.workbuddy/` |
| 8 | 12 门禁回归 | **12/12 RC=0，RUNNER_EXIT=0**；H4 stdout 10258B 不变 |
| 9 | 全新 clone 端到端 | `.workbuddy` 不存在、0 跟踪、0 历史、blob `could not get object info` |
| 10 | 旧 HEAD `c5324ed` 可读性 | **不可读**（`could not get object info`），历史已彻底替换 |

### 4. 遗留与副作用（须如实记录）

- **历史 hash 全变**：主分支 HEAD `c5324ed` → `f37f39e`；tag
  `audit/ehai-downstream-001-closed` `4a21a0b` → `3690226d`、
  `v0.1.0` `19aa98ff` → `7c7e1340`；3 个 `autofix/*` 分支 hash 未变（本就不含
  `.workbuddy/`）。**此前所有工单与证据包里引用的 commit hash 已失效**，
  引用时须换算或以提交信息为准。
- **origin remote 被 filter-repo 移除**（原 `https://github.com/DeepKit/DeepSpec.git`）。
  将来要 push 须重新 `git remote add`。此变更与本仓"从未 push"纪律一致，
  且额外提供一道"不会误推重写后历史"的保险。
- **3 个 `D:/Temp/` worktree** 仍在使用中，未删除。已修复其索引一致性；
  各自工作树的 `.workbuddy/` 变为 untracked（本地文件未动）。
- 证据包 `spw-evidence-c5324ed.json` 引用已不存在的 HEAD，需随本次提交重新生成。

## 六、本次复核已核实为真、勿重复劳动

- `.gitattributes:15` 的 `.workbuddy/ export-ignore` 已生效（192 文件导出包实测 0 泄露）；
- `origin/main` 侧不含 `.workbuddy/`，本地领先 304 提交，从未 push；
- H5 观测席位问题在 WO-20261005-0093，不在本单范围。

## 六、仍待老板本人执行

- GitHub 侧吊销 `DeepKit-Fyi` 名下原 `ghp_` token（WO-0090 阶段 1）。
