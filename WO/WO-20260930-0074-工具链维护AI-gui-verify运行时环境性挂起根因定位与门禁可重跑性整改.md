# WO-20260930-0074 · 工具链维护AI · gui-verify 运行时环境性挂起根因定位与门禁可重跑性整改

- 下发时间：2026-10-03 · 下发人：主控 · 依据：**主控对 WO-20260930-0071 的复核复跑**
- 优先级：**P0（A）/ P2（B）**· 单 commit ≤200 行
- 上游：WO-20260930-0071（判词"有条件通过"）、WO-20260930-0073（同族门禁缺口）

> **背景（主控实测）**：WO-0071 的修复代码本身没问题（347/347、7/8 道 Required 门禁 RC=0），
> 但 `H3.gui-verify-smoke` 这道门禁**在本机已经跑不出 PASS 了**：`bin\AsWish.exe --gui-verify
> dogfood_gui_site_final` 起来后**不退出**（30s 后 `RC=259 STILL_ACTIVE`），
> 且**不写任何截图**（`dogfood_gui/screenshots/` 13 个文件全部停在 2026-10-03 11:32:25~29）。
> 主控做了 **HEAD 对照实验**：把 `src` 整个还原到 HEAD 重建，**挂起表现完全一样**——
> 所以这不是 WO-0071 引入的代码回归，是**环境侧**出现了问题。
> 本机最后一次完整成功的 gui-verify 是 **2026-10-03 11:32**（13 张截图 4.2 秒内写完）。

## 主控修正（2026-10-03 14:10 · 本单前提已被推翻，下游必读）

**"本机已经跑不出 PASS"这个论断，现在不成立了。挂起是间歇性的，不是稳定复现。**

14:04 与 14:05 两次连续实测（同一 exe、同一命令、同一工作目录）：

```
STATE=EXITED RC=0 ELAPSED=4.8   OUT_BYTES=818  ERR_BYTES=115
SHOTS_AFTER=13 CHANGED=13       EV_CHANGED=True（7722B → 7802B）
[H3.gui-verify-smoke] PASS RC=0 stdout=818B [PASS]=12
```

随后主控跑完全套 8 道 Required 门禁：**逐道 RC=0，REQUIRED_FAILED=0**；
`tests\AsWish.Tests.exe` **347/347**。

**因此本单指令按以下方式修正，不是取消：**

1. **默认路线第 1 条"先取卡点证据"的单次诊断方法论作废。**
   单次运行既不能证明"挂了"，也不能证明"好了"——今天同一天同一二进制
   挂了多轮（12:39、13:07，以及 14:02 主控复验的 45s 超时轮）、又好了两轮
   （14:04、14:05）。必须改为 **N 次重复测量**，见下方新增任务 C。
2. **B 项（防串味）比 A 项更重要，且与挂起是否复现无关。**
   挂起期间之所以被"文件大小"这种错误理由命中，正是因为证据不新鲜——
   这条缺陷**现在仍然完整存在**，不是历史问题。
3. 间歇性的存在**不削弱** B 项价值，反而加强：一个时好时坏的流程，
   比一个稳定失败的流程更容易让上一轮残骸冒充本轮结果。

### C（P2，新增，必做）：间歇性必须可测量，不许用单次运行下结论

1. 落一个可复跑脚本（≤120 行），对 `--gui-verify` 连续跑 **N=10** 次，
   每次记录：`rc / elapsed_ms / 截图重写数 / evidence mtime+size 是否变化 /
   运行前 msedgewebview2 进程数 / 运行后 msedgewebview2 进程数`。
2. 输出一行汇总：`PASS_n/N  HANG_n/N  最长耗时  平均耗时`。
   挂起率 ≥ 1/N 即判 FAIL，并附每次挂起时的进程数差值与 evidence 状态快照。
3. 该脚本必须**先跑一次贴数**作为本单起点基线，否则下游无法自证修好了。

### 已被今天实测排除的一项（不要再做）

- **管道 vs 文件重定向假设不成立**：主控曾怀疑挂起由 stdout 句柄类型引起
  （纪律："管道场景验证不了无效句柄分支"）。实测 **14:04 文件句柄场景 PASS、
  14:05 管道场景同样 PASS**，该方向不再追查。

## 任务表（两项，逐条验收）

### A（P0，必做）：定位并消除 gui-verify 的环境性挂起

**主控已排除的项（不许重做）**：

| 已排除 | 证据 |
|---|---|
| WO-0071 代码回归 | `git checkout -- src` 回 HEAD 重建，挂起表现逐字相同（RC=259、0B、0 截图） |
| 上一轮挂起的 App 残留 | `cleanenv.ps1` 杀掉全部 `AsWish.exe` + 持有 `E:\temp\AsWish-WebView2` 的 `msedgewebview2.exe`，`REMAINING=` 空，再跑照样挂 |
| WebView2 用户数据目录损坏 | 每次跑前删掉整个 `E:\temp\AsWish-WebView2`，照样挂 |
| 磁盘空间 | E: 余 1.2T、D: 余 92G |
| mirror fixture 被改坏 | `mirror/delay.txt` 已还原为 `1500`；单独启动 mirror `msedgewebview2.exe` 能正常跑 ~20s 后 `rc=0` |
| 浏览器进程窗口抢占/可见性 | 全桌面轮询 60ms 粒度 90s，`Chrome_WidgetWin_*` 全部 `IsWindowVisible=0`，无可见浏览器窗口 |

**主控已确认的现象（定位起点）**：

- 挂起时 App 的主窗体**存在但 `IsWindowVisible=0`**（`TAsWishMainForm 78,139 1280x800`）。
- 挂起时 `NoDebug` 的 `msedgewebview2.exe` **子进程会出现，并且会累积**：同一轮 run 内
  2 → 3 → 5 个（12:39 与 13:07 两次观察一致），说明 WebView2 在**反复拉起浏览器进程**。
- 浏览器自己的顶层窗口确实存在且全部隐藏：`Chrome_WidgetWin_0 1440x727`、
  `Chrome_WidgetWin_1 961x1019`、`GDI+ Hook Window Class 1x1`、`crashpad_SessionEndWatcher 136x39`。
- 挂起发生在 **Step 1 截图之前**：App 从不写 `gui-01-project-open.png`。
- **时间分界**：11:32 成功；11:40 主控曾改 `AsWish.Services.Project.pas`；11:54 重建后至今全部挂起。
  （注：改回 HEAD 也挂，所以分界更可能是 11:32–11:54 之间的**机器/会话状态变化**，不是代码。）

**默认路线（按此实现，须说明理由）**：

1. 先取**卡点证据**：用可用的最小手段（`procdump -ma` / `cdb -kv` / 事件追踪 / 线程栈）
   抓到挂起 App 的主线程调用栈，明确卡在哪一行。若工具不可用，退而用
   「`TAsWishMainForm` 是否已经 `ShowWindow(SW_SHOW)` 过」+「`CurrentMainControl` 的
   `BrowserControlState` / `WebViewCreated` / `LastErrorCode` 三个值」做二分，
   **必须给出可复现的判定脚本**，不许只写"疑似"。
2. 根因若是**环境/机器侧**（不是产品代码）：在 `tools/` 下落一个**可复跑的自检脚本**
   （`gui_verify_env_precheck.py` 之类，≤120 行），跑门禁前先自查并明确报 FAIL 原因；
   自检至少覆盖：WebView2 Runtime 存在性与版本、`E:\temp\AsWish-WebView2` 可写、
   桌面会话可交互（`OpenInputDesktop`/`GetThreadDesktop`）、
   本机 `msedgewebview2.exe` 进程数阈值。
3. 根因若是**产品代码侧**：按缺陷单正常流程修，**不许**用"把 3000 改大/加 Sleep"糊过去。

### B（P2，必做）：证据必须自带防串味，跨轮次不许靠同名文件蒙混

**问题（主控实测）**：`dogfood_gui/gui-dual-surface.txt` 与
`dogfood_gui/screenshots/*.png` 都是**同名覆盖写**，跑前不记录快照、跑后不校验新鲜度。
本轮挂起时这两处文件**纹丝不动**（分别停在 11:53 与 11:32），
单看文件存在性完全无法分辨"本轮真的跑过"还是"上一轮的残骸"。
WO-0073 的 B 项已要求对 evidence 做新鲜度校验，本单把它**扩展到截图目录**并做成
**门禁自身的前置断言**（不许只依赖测试者肉眼比对 mtime）。

**默认路线**：

1. 门禁跑前记录 `gui-dual-surface.txt` 的 `st_mtime_ns`/`st_size` **以及**
   `screenshots/` 下全部 `*.png` 的 `{name: (mtime_ns, size)}` 字典；不存在记 `None`。
2. 跑后必须确认（a）evidence 被重写；（b）**每一个 `gui-01..gui-11` 截图文件都被重写**。
   任一不满足即 findings 增加对应条目并判 FAIL。
3. 断言语义与 WO-0071 已确认通过的三条断言（RC=0 / stdout≥800B / `[PASS]`≥11）**不冲突、不替换**。

## 已确认通过、不要重做

- WO-0071 的根因判定、两处 `TPath.GetFullPath` 修复、`FormatDomDiagnostic`/`FailDomAssert`、
  347/347、Required 门禁里除 `H3.gui-verify-smoke` 外 7 道 RC=0 —— 主控已亲手复现，**本单不许改其语义**。
- WO-0073 的反事实腿与收尸/证据新鲜度设计仍在流程中，**本单不重开**；
  本单 B 项只在其基础上扩展"截图目录"这一层。
- 347/347 基准、Required 门禁总数 8 道不许变。

## 硬验收（必须逐条附证据；缺一条即退回）

1. **卡点证据**：贴挂起 App 的主线程栈（或等价二分判定脚本输出），指明卡点位置。
2. **根因闭环**：根因判定 + 修复/自检脚本 + 修复后 `bin\AsWish.exe --gui-verify
   dogfood_gui_site_final` **真实退出**（贴 RC 与 13 张截图的新 mtime）。
3. **门禁回绿**：`H3.gui-verify-smoke` RC=0 且 Forward 腿证据齐全（不许引用主控数字，自建自跑）。
4. **防串味**：贴跑前/跑后 evidence 与 13 张截图的 mtime/size 自证行。
5. **规模**：新增/改动脚本 ≤120 行；全单 commit ≤200 行。
6. **回归**：自建自跑 `tests\AsWish.Tests.exe` 347/347；`spw-manifest.json` Required
   门禁逐道 **RC=0**（含 `H3.gui-verify-smoke`）。
7. **临时改动清零**：`git status --porcelain -- src tools tests` 除本单文件与本工单外为空。

## 上报要求

- 全部实测证据回填本文件；**自建自跑**，不许引用主控数字。涉及计时写测量点。
- 发现新缺陷/遗留/疑似项**同回合开工单**（含默认路线），不许写"建议另开单"。
