# WO-20260930-0073 · 工具链维护AI · gui-verify 烟雾门禁反事实自证失效与进程处置缺口整改

- 下发时间：2026-10-03 · 下发人：主控 · 依据：**主控对 WO-20260930-0071 的独立复核**
- 优先级：P1（A）/ P3（B）· 单 commit ≤200 行
- 上游：WO-20260930-0071（已判"有条件通过"，本单是其放行条件）

> **背景**：WO-0071 的新门禁 `H3.gui-verify-smoke` 确实能抓住本次真回归（无盘符 file URL），
> 但它自称承担的"反静默失败守卫"是纸面成立的：主控把 `WaitForWebViewReady` 置 0 重建后直跑门禁，
> 门禁**照样 PASS**。也就是说这道门禁的绿灯目前无法区分"产品真的就绪"与"等待逻辑被拆掉"。
> 门禁全绿与产品可交付之间不能靠"恰好这次抓到了"来维系，必须让反事实成为门禁自身的属性。

## 任务表（两项，逐条验收）

### A（P1，必做）：反事实必须由门禁自己跑，且 FAIL 腿不依赖 shell 环境变量继承

**问题（主控复现）**：

- 注入 `MainForm.pas:2083` → `WaitForWebViewReady(0)`，重建后
  `python tools/spw-gates/gate_gui_verify_smoke.py` → **`PASS RC=0 stdout=818B [PASS]=12`**。
- 下游 WO-0071 报告里那条 FAIL 腿，只在测试者 shell 继承了
  `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=<mirror>` 时才 FAIL；门禁代码本身不注入该变量。
- 机理：常态路径浏览器约 1s 内就绪，`WaitForWebViewReady(0)` 之后的
  `WaitForBrowserReady(..., 2000)`（`MainForm.pas:842`）消息泵足以消化创建过程，
  该调用点对门禁判定已不承重。

**默认路线**（不另行裁定，按此实现）：

1. 门禁内部增加**第二条反事实腿**，环境注入在门禁进程内完成（`os.environ` 传给子进程），
   **不许**依赖调用方 shell 已设变量、也不许改动 `mirror/` 内的共享 fixture 文件。
2. 反事实腿的可检测故障形态（择一实现，须说明理由）：
   - 用 `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER` 指向一个**空目录或不存在目录**——
     主控已验证该形态让 app 判 `GUI-VERIFY-NO-WEBVIEW (LastErrorCode: $80070002)`，足以触发三条断言；
   - 或指向一个"启动即退出"的探针可执行目录（探针源码随单入仓，编译产物不入仓），
     主控已验证该形态让 app 判 `$800700AA`。
3. 反事实腿的期望结果必须是**门禁 FAIL**（RC≠0）并把 findings 打全；正向腿继续要求 PASS。
   两腿的 RC 与输出尾段都要写进证据。
4. 修完自证：把 `MainForm.pas:2083` 的 3000 临时改成 0 再跑门禁，**FAIL 腿仍须 FAIL**
   （这是本单的验收判据）；随后还原、重建、贴还原后的 `git status`。
   ——注意：若反事实腿用的是"空目录浏览器"形态，则置 0 后 FAIL 腿仍 FAIL 属自动成立，
   此时必须**额外**自证"正向腿在置 0 时 FAIL"，否则本判据不满足。

### B（P3，必做）：门禁必须收尸并校验证据新鲜度

**问题（代码复核）**：`tools/spw-gates/gate_gui_verify_smoke.py:75` 用
`WaitForSingleObject(pi.hProcess, 30000)` 后**不检查返回值**，超时既不 `TerminateProcess` 也不判 FAIL；
证据文件 `dogfood_gui/gui-dual-surface.txt` 跑前不记录、跑后不校验是否被本次重写。
挂起场景会留下持有桌面与 WebView2 profile 的 `AsWish.exe`，且 evidence 可能是上一轮残留。

**默认路线**：

1. 判定 `WAIT_OBJECT_0` / `WAIT_TIMEOUT`；超时即 `TerminateProcess`、再 `WaitForSingleObject` 收尸，
   findings 增加"app 未在 30s 内退出"，判 FAIL。
2. 跑前记录 evidence 的 `st_mtime_ns` 与 `st_size`（不存在则记 None），跑后必须确认它已被重写，
   否则 findings 增加"evidence 未刷新（疑似挂起或未落盘）"，判 FAIL。
3. 超时分支同样 `CloseHandle`，不许漏句柄。

---

## 主控补充（2026-10-03 复跑，B 项的现实样本已出现）

**本机已真实出现"App 未在 30s 内退出"分支**，不是纸面推理：

```
[H3.gui-verify-smoke] FAIL
  - non-zero exit code: 259 (stderr: )
  - stdout file size below threshold: 0 bytes < 800 bytes
  - insufficient [PASS] entries: 0 < 11
```

- `RC=259` = `STILL_ACTIVE`，即 `WaitForSingleObject(pi.hProcess, 30000)` 超时返回
  `WAIT_TIMEOUT` 而门禁**没有判 FAIL、没有收尸**，只是照常读了空 stdout/evidence 后
  因为"文件太小"才 FAIL。**FAIL 命中的是文件大小，不是超时本身**——一旦 evidence
  恰好是上一轮残留且够长，这道门禁会给出错误结论。
- 超时后实测残留：`AsWish.exe` 存活，且**它的 `msedgewebview2.exe` 子进程一并存活**
  （实测一次残留 1 个 App + 6 个浏览器子进程，共同持有 `E:\temp\AsWish-WebView2\EBWebView`）。
  下一轮 run 前必须显式清理，否则跨轮次互相污染。
- 由此产生的新事实：**门禁跑后不留干净机器状态**，与 B 项第 1、2 条是同一个根因，
  本单必须一并收口（超时分支 `TerminateProcess` 后**连带**处理子进程，
  或在门禁入口先做一次环境自检——后者主控已在 WO-20260930-0074 单列）。
- 该挂起本身的根因不在本单范围，已开 **WO-20260930-0074** 跟踪；本单只负责
  "挂起时门禁必须 FAIL 得正确 + 不留脏状态"。

### 主控再补（2026-10-03 14:10 · 上文"门禁跑不出 PASS"已不成立）

14:05 实测：`[H3.gui-verify-smoke] PASS RC=0 stdout=818B [PASS]=12`。
全套 8 道 Required 门禁**逐道 RC=0**，`tests\AsWish.Tests.exe` **347/347**。

**这一条只解除"门禁现在能不能跑绿"，不解除本单 A、B 两项任务：**

- 挂起是**间歇性**的（同一天挂了多轮又好两轮，详见 WO-0074 的主控修正节）。
  间歇性意味着上面那三个 FAIL findings **随时会再出现**，收尸与证据新鲜度
  两条仍按原判据做完。
- B 项的核心指控——"FAIL 命中的是文件大小，不是超时本身"——与门禁当前绿不绿
  **完全无关**，是代码路径上的真缺口，不许因今天跑绿就跳过。
- 另开 **WO-20260930-0075**（挂起时零证据：阶段日志只在终点落盘）与
  **WO-20260930-0076**（窗口/浏览器截图缺纯色守卫）。两者与本单的
  反事实/收尸是不同切口，互不替代。

## 已确认通过、不要重做

- WO-0071 的根因判定、`TPath.GetFullPath` 两处修复、`FormatDomDiagnostic`/`FailDomAssert`、
  门禁正向三断言（RC=0 / stdout≥800B / `[PASS]`≥11）、`ACCEPTANCE-HARNESS-RULES.md` 第 7 条
  ——全部已被主控亲手复现，**本单不许改其语义**。
- WO-0072 的 fixture 清理、`Sleeper.dpr` 死开关、测量点分层三项仍在流程中，**本单不重开**。
- 347/347、Required 门禁基准不许变（本单新增门禁腿后总数仍为 8 道，逐道 RC=0）。

## 硬验收（必须逐条附证据；缺一条即退回）

1. **反事实自证**：门禁内置反事实腿存在且不依赖调用方 env；门禁正常跑法下 FAIL 腿判 FAIL，
   证据贴两条腿的 RC 与输出尾段。
2. **置 0 判据**：按 A 第 4 条完成"守卫置 0 → 指定腿 FAIL → 还原 → 重建 → `git status` 干净"闭环。
3. **收尸**：构造或推理验证超时分支判 FAIL（无挂起样本时至少贴代码位置与分支判据）。
4. **证据新鲜度**：贴跑前/跑后 evidence 的 mtime/size 自证行。
5. **规模**：`gate_gui_verify_smoke.py` ≤160 行；全单 commit ≤200 行。
6. **回归**：自建自跑 `tests\AsWish.Tests.exe` **347/347**；`spw-manifest.json` Required 门禁逐道 **RC=0**。
7. **临时改动清零**：`git status --porcelain -- src tools tests` 除本单文件与本工单外为空。

## 上报要求

- 全部实测证据回填本文件；**自建自跑**，不许引用主控数字。涉及计时写测量点。
- 发现新缺陷/遗留/疑似项**同回合开工单**（含默认路线），不许写"建议另开单"。
