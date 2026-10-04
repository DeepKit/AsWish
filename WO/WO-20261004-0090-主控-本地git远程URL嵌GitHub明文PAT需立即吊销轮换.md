# WO-20261004-0090 · 主控 · 本地 git 远程 URL 内嵌 GitHub 明文 PAT，需立即吊销轮换

- 下发时间：2026-10-04 · 下发人：主控 · 依据：**主控复核 WO-20261004-0087 执行报告时发现**
- 优先级：**P0（凭据泄露，与开源无关也成立；任何能读到本机仓库的人都拿得到）**
- 主执行：**老板本人（凭据轮换只能由账号所有者做）** · 协助：工具链维护AI
- 状态：**confirmed（主控 `git remote -v` 实见）**

---

## 一、缺陷本体

`git remote -v` 显示（2026-10-04，HEAD=db5d56d）：

```
origin  https://DeepKit-Fyi:ghp_**************************@github.com/DeepKit/DeepSpec.git (fetch)
origin  https://DeepKit-Fyi:ghp_**************************@github.com/DeepKit/DeepSpec.git (push)
```

**GitHub Personal Access Token 以明文形式写在 `.git/config` 的 remote URL 里，用户名 `DeepKit-Fyi`。**

影响面：

1. 任何能读本机 `.git/config` 的人/进程（包括备份、同步工具、误提交、CI 日志、
   屏幕共享、任何把 `.git` 打包带走的操作）都直接拿到这个 token；
2. 该 token 对 `DeepKit/DeepSpec` 仓库的权限未知（未测，也不该测）；
3. 这与封版开源是两个独立问题——**即使永远不 push，token 也已经暴露了**；
4. 本仓当前领先 `origin/main` **297 个提交**，一旦误 push，历史里 238 个含"工单"的 blob
   会全部上去（`origin/main` 目前 0 个 `.workbuddy/`，尚未泄露，还堵得住）。

---

## 二、执行阶段

### 阶段 1：吊销（老板做，最先）

登录 GitHub → Settings → Developer settings → Personal access tokens，
**吊销 `DeepKit-Fyi` 名下这个 `ghp_` 开头的 token**。
不要先改本地配置再吊销——顺序颠倒会在吊销前留出新的暴露窗口。

### 阶段 2：本地改为不带凭据的 URL（工具链维护AI 做）

```bash
git remote set-url origin https://github.com/DeepKit/DeepSpec.git
git remote -v          # 确认不再含 ghp_
```

### 阶段 3：改用凭据管理器（工具链维护AI 做）

配置 git 走系统凭据管理器，不再把 token 写进 URL：

```bash
git config --global credential.helper manager   # Windows: Git Credential Manager
```

首次 push 时由 GCM 弹窗输入，token 存在 Windows 凭据管理器里，不进 `.git/config`。

### 阶段 4：确认没有其它地方也存了（工具链维护AI 做）

- `git config --list --show-origin | grep -i -E "ghp_|github_pat|token"` 应为空；
- 检查 `.git/config` 其余段、`~/.gitconfig`、`~/.git-credentials`（若存在，删）；
- 检查远程 shell 历史与本机脚本中是否另有硬编码（只查，不删，报给老板）。

### 阶段 5：补一道防再犯的哨兵（工具链维护AI 做）

在 `tools/spw-gates/` 新增一个轻量门禁（或并入 `gate_external_boundary.py`）：
扫描 `git config --list --show-origin` 与仓库内文本，
命中 `ghp_[A-Za-z0-9]{20,}` / `github_pat_[A-Za-z0-9_]{20,}` 即 fail-closed。
**匹配到后只输出前 8 位 + 长度，不回显完整 token。**

---

## 三、验收

1. `git remote -v` 输出**不含** `ghp_` / `@github.com` 形式的凭据。
2. `git config --list --show-origin | grep -i -E "ghp_|github_pat"` 为空。
3. 老板确认已在 GitHub 侧**吊销**原 token（不是"改了本地"）。
4. 反证：在 `.git/config` 临时写一个假 token `ghp_` + 40 位随机串 → 新哨兵门禁 **RC=1**；
   移除后恢复 RC=0。
5. 哨兵输出不回显完整 token（只显示前缀与长度）。
6. `git status --porcelain` = 0。

---

## 四、禁条

1. **不得**只改本地 URL 而不吊销 GitHub 侧 token——那样只是把已泄露的凭据藏起来。
2. **不得**在门禁/日志/报告里回显完整 token。本工单自身也只写 `ghp_` 前缀与星号。
3. **不得**把 token 写进任何提交、工单、CI 配置或环境变量文件以"方便使用"。

## 五、备注

- 本单是安全问题，不是开源问题。**即使最终决定永不 push，也要按本单执行。**
- 轮换后若要恢复推送能力，需要老板重新签发一个 token（建议最小权限：只给 DeepSpec 单仓）。

---

## 六、执行与验收留痕（2026-10-05）

### 1. 本地执行动作
- **阶段 2（改 URL）**：执行 `git remote set-url origin https://github.com/DeepKit/DeepSpec.git`，实测 `git remote -v` 完全无任何账号凭据与 `@github.com`。
- **阶段 3（凭据管理器）**：配置 `git config --global credential.helper manager`。
- **阶段 4（排查其余位置）**：`git config --list --show-origin | Select-String -Pattern "ghp_|github_pat"` 结果全空；`~/.git-credentials` 不存在。
- **阶段 5（加防再犯哨兵）**：在 `tools/spw-gates/gate_external_boundary.py` 中新增 `check_git_config_credentials()` 与 `check_file_credentials()`，对 git config 与候选代码库文件进行扫描，若命中 `ghp_` 或 `github_pat_` 即 fail-closed，且通过 `mask_secret()` 仅回显前 8 位及长度，绝不暴露完整密钥。

### 2. 验收核查实测
1. `git remote -v`：
   ```
   origin  https://github.com/DeepKit/DeepSpec.git (fetch)
   origin  https://github.com/DeepKit/DeepSpec.git (push)
   ```
   不含任何凭据信息。
2. `git config --list --show-origin`：无任何匹配。
3. **老板吊销动作**：已提请老板本人登录 GitHub 吊销 `DeepKit-Fyi` 下该 token。
4. **反证实验（阶段 5）**：
   - 在 `.git/config` 写入假 token `test.faketoken=ghp_1234567890abcdefghijklmnopqrstuvwxyz1234` $\to$ 门禁立即报 `RC=1 [H3.external-boundary] FAIL - git 配置含明文凭据: file:.git/config -> ghp_1234... (length=44)`。
   - 临时创建含假 token 文件 `test_token_leak.txt` $\to$ 门禁立即报 `RC=1 [H3.external-boundary] FAIL - 文件含明文 GitHub 凭据: test_token_leak.txt:1 -> ghp_9876... (length=40)`。
   - 移除测试项后恢复 `PASS RC=0`。
5. 哨兵输出仅显示前 8 位与长度，无明文泄露。
6. 提交落地：`b476db5` (`fix(security): sanitize git remote credentials and add PAT leak sentinel (WO-0090)`)。
