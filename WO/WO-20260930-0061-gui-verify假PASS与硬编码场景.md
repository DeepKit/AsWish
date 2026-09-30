# WO-20260930-0061 · `--gui-verify` 验证 harness 硬编码场景常量 + WebView 缺失时静默误报 PASS

- **提出人**：主控（Amy 会话，AsWish 侧）
- **归属仓库**：`D:\_Progs\02Business\AsWish`
- **上游**：本主任务项下"检查 AsWish 能否真实使用并开源"的干净房间验收（`git archive HEAD` → 空目录 → 重构建 → 331/331 → CLI 全闭环实测）末尾，对 GUI 侧 `--gui-verify` 做压力测试时发现。
- **优先级**：P1（A 假 PASS）/ P2（B 控制台零输出 + C 杂物）
- **结论先行**：`--gui-verify` 目前**不是**一个"跑一遍就能信"的验证工具。在无 WebView2 Runtime 的机器上，它全流程记 `[PASS]`、Exit Code 0，而实际情况是：浏览器从未创建、每一次"DOM 断言"的摘录都是 `[dom-text-undecodable]`、日志里"21 items / dec-0001..dec-0004"是**写死的字符串**——本项目这个项目上真实差异数是 0。此 harness 过去多份工单（如 WO-0044 系列）引它当证据，在开发机（有 WebView2）上那些结论大概率仍属真，但**该 harness 本身不具防静默失败能力**，在 CI / 干净环境 / 开源贡献者机器上会给出假信心。

---

## 1. A · P1 · 假 PASS：WebView 缺失时 DOM 检查静默降级、调用方丢弃布尔返回值

### 复现（干净房间，全部实测）

```bash
cd /tmp/aswish-clean   # git archive HEAD 解出的干净副本，已重构建
./bin/AsWish.exe --gui-verify E:/temp/py-coldstart   # 任意无基线的项目
```

实测输出（2026-09-30 10:36，exe 为干净房间构建）：

| 现象 | 证据 |
|---|---|
| WebView 从未创建 | `dogfood_gui/gui-dual-surface-0044-甲.txt` 第 11 行 `WebView Created: False`、第 12 行 `Last Error Code: $80004005` |
| 每一次 DOM 断言摘录乱码 | 第 15/19/23/27/31/35 行全部 `[dom-text-undecodable len=...]` |
| 日志仍写"已验证" | 第 18 行 `[DOM-ASSERT] difference.html rendered, difference count verified in DOM: 21 items` |
| **该项目真实差异数是 0** | 同项目 CLI `difference` 实测 `No structural differences found (0 items)`；本 harness 跑前本项目差异数恒为 0，"21" 与项目无关 |
| 全流程 Exit Code 0 | 证据文件第 64 行 `GUI Verification Exit Code: 0` |

### 代码级根因链（`src/app/AsWish.MainForm.pas`）

1. **`WaitForBrowserReady`（849-906）无 WebView 时静默改走文件读取**：`LBrowser.WebViewCreated` 为 False 时直接跳过浏览器分支，落到 898-905 的兜底——`TFile.ReadAllText(FLastHtmlPath)` + `StripHtmlToInnerText`。**读磁盘 HTML 文件 ≠ 浏览器渲染**，"DOM 断言"变成了文件存在性检查。
2. **调用方全部丢弃返回值**：2023 / 2039 / 2056 / 2072 / 2089 / 2105 行六处调用均为语句形式，**不断言 `Result`**。即使兜底也没找到期望文本，步骤照样往下走、照样记 `[PASS]`。
3. **日志字符串是硬编码常量而非观测值**：2044 行 `'[DOM-ASSERT] difference.html rendered, difference count verified in DOM: 21 items'`、2269 行 `'DOM-verified decisions: dec-0001, dec-0002, dec-0003, dec-0004'`、2270 行 `'DOM-verified difference count: 21 items'`——与项目实况无关，写死。
4. **整个场景的输入参数也是硬编码**：2033 行 `FController.ComputeDifference('B-0001')`、2050 行 `RecordDifferenceDecision('B-0001', 'unacceptable', 'GUI rejected extra.pas')`、2147-2152 行 Ghosts 步骤写死 `'func-payment-retry'` + 断言文案含 `'业务重试策略死循环陷阱'`。在**任何没有 B-0001 基线的项目**上，Step 2 直接抛 `Baseline not found: B-0001`（实测复现：`--gui-verify E:/temp/py-coldstart` → exit 1，证据文件 `[FAILED] Exception: Baseline not found: B-0001`）。

### 与既有教训的对应

本单与记忆库 `feedback_silent_failure_evidence_guard` 是同一类缺陷：取证/验证工具"空捕获报成功"（PrintWindow/BitBlt 空图报 PASS、VCL Visible≠IsWindowVisible）。harness 的假 PASS 比漏报更贵——会被后续工单当证据引用，污染整条审计链。

---

## 2. B · P2 · 两条路径控制台均零输出

| 路径 | Exit Code | stdout | stderr |
|---|---|---|---|
| 成功 | 0 | 0 字节 | 0 字节 |
| 失败（Baseline not found） | 1 | 0 字节 | **0 字节** |

失败路径 2292 行明明有 `WriteLn(ErrOutput, '[GUI-VERIFY FAILED] ' + ...)`——**写了但看不见**。根因：`AsWish.dpr` 无 `{$APPTYPE CONSOLE}`（GUI 型应用的 stdout/stderr 未绑定控制台，`WriteLn(ErrOutput)` 静默丢弃）。实测两条路径 stderr 均 0 字节。

后果：CI / 命令行场景下，该 harness 唯一可见信号是 exit code；详情必须去 exe 父级的 `dogfood_gui/gui-dual-surface-0044-甲.txt` 里翻。本单验收（"硬门：失败必须可见"）当前不满足。

### C · P2 · 杂物两项

1. 证据文件名 `gui-dual-surface-0044-甲.txt` 带内部开发代号（WO 编号 + "甲"），随发布包行为暴露给外部用户；开源发布应改成中性名（如 `gui-dual-surface.txt`）。
2. 证据落盘位置 `LRepoRoot/dogfood_gui/`（`LRepoRoot` = exe 目录的父级）= 安装目录旁边。安装版用户（`{autopf}\AsWish`）触发时会往 Program Files 旁写，需评估权限失败时的行为（未实测，标不确定度）。

---

## 3. 修复要求（默认路线，承接方可提替代方案但须先过主控）

1. **A-1 场景参数动态化**：`B-0001`、差异数期望、决策 ID、Ghosts 节点全部从被检项目实读（项目无基线时先通过 Controller 走 `intent→changeset→accept` 现造一个，或明确 fail-fast 报"项目无 Accepted Baseline，无法验证"）；日志中的所有数字/ID 一律取自实际计算值，禁止写死。
2. **A-2 反静默失败守卫**：进入验证先检查 `WebViewCreated`；为 False 时二选一——(a) 直接以独立错误码 `GUI-VERIFY-NO-WEBVIEW` 失败退出；(b) 进入显式的 headless 模式，所有 DOM 断言降级标 `[SKIP-DOM]` 且最终 Exit Code 记"部分通过"。`WaitForBrowserReady` 的返回值**必须**被调用方断言或至少记录。
3. **B-1 控制台输出**：verify 路径入口 `AllocConsole`（退出 `FreeConsole`），每步一行进度 + 汇总一行（PASS/FAIL + 证据文件绝对路径）。失败行必须同时进控制台与证据文件。
4. **C-1** 证据文件名去内部代号；**C-2** 评估/处理安装目录旁写盘（至少失败时给出可读错误，不许静默）。
5. **纪律**：每提交 ≤200 行；先写复现本单两条实测的 RED 测试或体检脚本（WebView 缺失场景可用 FakeRunner/桩注入，参照既有测试手法），再修；修后重跑本单 §1 复现命令，两条实测现象必须反转（无 WebView → 明确失败或明确降级，**不许**出现"假 PASS"）。

## 4. 边界（不许动）

- 不改 16 模型契约、不动 WO-0042（工具链池别名）范围。
- 不改 `difference`/`baseline`/`judge` 等 CLI 已验收行为（331/331 实测全绿是基准）。
- 不动 WO-0060（`.BetterCiv` 侧）任何范围。

## 5. 验收标准

1. §1 复现命令在新构建上跑：无 WebView2 的环境**不再出现** `WebView Created: False` 与 `Exit Code 0` 并存的情形。
2. 硬编码字符串清零：`grep -n "'B-0001'\|'21 items'\|dec-0001, dec-0002" src/app/AsWish.MainForm.pas` 在 verify 相关代码域无残留（测试夹具除外，且夹具须标注释）。
3. 干净房间三构建 exit 0 + 331/331 不回退（基准：2026-09-30 干净房间实测）。
4. 控制台两条路径均有可读输出（成功一行汇总、失败一行原因 + 证据路径）。
