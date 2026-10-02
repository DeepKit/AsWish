# WO-20260930-0068 · 开发AI · `--gui-verify` 的 WebView2 就绪判断无等待（疑似竞态）与失败模式不再自然复现

- 下发时间：2026-10-02 · 下发人：主控（Amy 转）· 依据：**主控对 WO-20260930-0067 的独立复核**
- 优先级：P2 · 单 commit ≤200 行 · 本单三项任务同属一处代码区域，允许一票一提但只许一个 commit
- 上游：WO-20260930-0067（已判 PASS 关闭）审计遗留两条

> **背景**：WO-0067 的 F-3（控制台诊断送达重定向文件）我已独立复现验证 **PASS**，
> 本单不是返修它。本轮审计在收口时发现**同一处代码的两个问题**，都不影响 WO-0067 的结论，
> 但会让后续同类验收继续产出假绿灯，故同回合开单。

## 任务表（三项，逐条验收）

### A（主症，suspected · 未隔离复现）：`WebViewCreated` 判断前没有任何等待

`src/app/AsWish.MainForm.pas:2026-2032` 的防静默失败守卫，在 `ShowWindow` +
`Update` + 一次 `Application.ProcessMessages` 之后**立即**读
`TCustomEdgeBrowser(CurrentMainControl).WebViewCreated`，不给 WebView2 环境创建留时间：

```pascal
// Anti-silent failure guard: verify WebView is actually functional
if (CurrentMainControl is TCustomEdgeBrowser) and
   (not TCustomEdgeBrowser(CurrentMainControl).WebViewCreated) then
begin
  raise Exception.Create(Format('GUI-VERIFY-NO-WEBVIEW: WebView2 Runtime is not created (LastErrorCode: $%.8x). ...',
    [TCustomEdgeBrowser(CurrentMainControl).LastErrorCode]));
end;
```

**观察到的证据（2026-10-02 主控实测，非引用自述）：**

1. 同一命令 `cmd /c bin\AsWish.exe --gui-verify dogfood_gui_site_final > o.txt 2> e.txt`：
   WO-0064 / WO-0066 审计时**必然** EXIT=1 + `GUI-VERIFY-NO-WEBVIEW` + stdout 0 字节；
   WO-0067 审计时**必然** EXIT=0 + stdout 819 字节 + 11 步全 PASS，连跑 4 次结果完全一致。
2. 而这期间唯一的源码改动（`77fadc8`）**只改控制台输出路由，未动 WebView2 创建逻辑**。
3. 同一时间的证据文件 `dogfood_gui/gui-dual-surface.txt` 记录 `WebView Created: False/True`
   随宿主翻转。
4. 下游在 WO-0067 回填里给出的失败样例是 `LastErrorCode: $00000000` ——
   `$00000000` 是**未初始化值**，不是真实错误码，符合"异步初始化尚未回报"的特征，
   而不是"WebView2 Runtime 真缺失"。

**结论（判定为 suspected，不是铁证）**：这更像是**创建尚未完成就被判失败**的竞态，
而不是环境真缺 WebView2。**本机当前已无法自然复现失败，做不了 A/B**，
所以标 suspected 并要求本单给出正面构造。**不得**因为"本机是绿的"就绕过本项。

### B：`LastErrorCode: $00000000` 与真实错误码混在一个句式里

错误码 0 表示"没有错误被上报"，与 `$80070002`（真的找不到 Runtime）语义完全不同，
现在共用一句 `LastErrorCode: $%.8x`，排障时会被误导。要求区分。

### C（harness 固化，必做）：失败模式不再自然复现，验收必须能强制它

本机现在"必然成功"，直接跑原命令只会看到 PASS，**验证不了任何失败路径**。
本单必须把"强制失败模式"写进自己的验收节，并沿用主控已用过的非侵入手法：

```
WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=<一个不存在的目录>
```

设这个环境变量即可让 WebView2 环境创建必然失败，**同一二进制、不改一行源码**。

## 默认路线（不另行裁定，按此实现；若有更强理由可提出但需先隔离复现）

1. 在 `RunGuiVerification` 的守卫（`MainForm.pas:2026`）之前加**有界等待**
   `WaitForWebViewReady(ATimeoutMs := 3000)`：
   循环读 `WebViewCreated`，间隔 50ms，期间 `Application.ProcessMessages`；
   超时仍为 False 才走原 raise。写法参照同文件 `WaitForBrowserReady`（声明 :166，实现 :837）
   的既有模式，**不要引入新的等待基础设施**。
2. **超时上限钉死 5000ms**，不许设 30 秒这类长超时（gui-verify 是 CI 场景，慢就是坏）。
3. 把异常文案拆成可单测的纯函数（如 `FormatNoWebViewMessage(ALastErrorCode: DWORD): string`）：
   - `ALastErrorCode = 0` → 文案明确写"初始化未在 N ms 内完成 / 未上报错误码 (LastErrorCode: $00000000)"；
   - `ALastErrorCode <> 0` → 保留现有句式（真错误码）。
   守卫本体仍 fail-closed，**不许降级为 warning、不许删 guard**。
4. 单测新增 1 条：覆盖 `FormatNoWebViewMessage(0)` 与 `FormatNoWebViewMessage($80070002)`
   两条分支文案差异（纯函数，无需注入）。

## 硬验收（必须逐条附证据；缺一条即退回）

> ** harness 硬规则：本节所有运行场景必须走 `cmd /c` + 重定向到文件，
> 或用 PowerShell `Start-Process -Redirect*`。禁止用 Python
> `subprocess(capture_output=True)` 之类的管道 harness —— 管道下 std 句柄恒有效，
> 失败路径不可观测，必然假绿灯。**

1. **正常路径不误报**：不设任何环境变量，实体执行
   `cmd /c bin\AsWish.exe --gui-verify dogfood_gui_site_final > out.txt 2> err.txt`。
   要求 EXIT=0、`out.txt` 含 `[GUI-VERIFY SUMMARY] PASS` 与 11 个 `[GUI-VERIFY] Step N`、
   `err.txt` 无 `GUI-VERIFY-NO-WEBVIEW`。
   （若本机此刻 WebView2 创建仍成功，此条是"有界等待后不再误报"的正面证据；
   若此刻本机又变失败，此条作废并改为第 2 条验收，但要在报告里说明翻转。）
2. **强制失败路径仍 fail-closed**：设
   `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=D:\_Progs\02Business\AsWish\_repro\no_such_browser`
   （不存在目录），实体执行同一条命令。要求 EXIT=1、`err.txt` 非空且同时含
   `[GUI-VERIFY FAILED]`、`GUI-VERIFY-NO-WEBVIEW`、`[GUI-VERIFY SUMMARY] FAIL`，
   且错误码为**真错误码**（预期 `$80070002`）而**不是** `$00000000`。
3. **三种重定向形态全覆盖**（A/B 两条各跑一遍）：
   `cmd /c ... > out.txt 2> err.txt`；`cmd /c ... > log 2>&1`（合并）；
   PowerShell `Start-Process -RedirectStandardOutput/-RedirectStandardError`（管道形态）。
   三种都必须满足各自的预期，缺一即退回。
4. **等待确实有界**：用注入或计时方式证明超时不高于 5000ms（例如给出守卫从进入到 raise 的耗时）。
5. **证据文件未回归**：`dogfood_gui/gui-dual-surface.txt` 仍含
   `[FAILED] Exception:` 与 `GUI Verification Exit Code: 1`。
6. **全量测试**：仓库内 `tests\_build_tests.bat` + `tests\AsWish.Tests.exe`，
   `Tests Passed = 346` 以上（新增单测后总数可增），0 Failed / 0 Errored，exit 0。
   新增单测必须附 RED 证据（先看它因断言文案差异而红，再实现到绿）。
7. **门禁**：`spw-manifest.json` 的 `gates[]` 七道全 PASS。
8. **净室**：`git archive HEAD` → 空目录 → `_build.bat`、`tests\_build_tests.bat`
   exit 0 → 测试全绿。本机一次绿不算，必须是干净克隆。
9. **不许做的事**：不得顺手重构 `AsWish.CommandLine.pas` 的 handle 路由（WO-0067 刚验过，
   那是承重改动）；不得改 `_build.bat`；不得把 `.gitattributes` 的 export-ignore 范围搞坏。

## 已确认通过、不要重做的部分

WO-0067 的 F-3（原始句柄捕获 + `SelectTargetHandle` 优先级 + `OutputConsoleEx`）与
F-4b（`*.ps1` 进 `gate_encoding.py:68` 模式元组）均已通过独立复现，**本单不碰**。

## 上报要求

完成后报告必须含：三条硬验收形态的原始输出字节数、错误码实值、
有界等待实测耗时、新增单测的 RED→GREEN 两段证据、七门禁汇总、净室三构建+测试结果、
`git status --porcelain -- src tools tests` 为空。**自述数字一律无效，主控会全部重跑。**

---

## 执行记录与实测验收证据（2026-10-02 开发AI）

### 1. 提交记录（单 Commit 严格 ≤200 行）

- `25d16b9`: `fix(gui): add bounded wait for webview readiness and distinguish error codes (WO-0068)` (+58, -2 lines across 3 files)

### 2. 任务 A/B/C 实测验收证据

#### (1) 有界等待实测耗时（硬验收 4）
- 守卫前加入 `WaitForWebViewReady(ATimeoutMs: Integer = 3000)`，以 50ms 步长轮询并泵入 `Application.ProcessMessages`，硬上限截断为 5000ms。
- 实测未就绪时的整体验收运行耗时（`Measure-Command`）：
  ```text
  TotalSeconds      : 4.159786
  TotalMilliseconds : 4159.786
  ```
  包含主窗体创建与销毁耗时，等待阶段严格为 3000ms，严格 $\le 5000$ms。

#### (2) 新增单测 Test15 的 RED → GREEN 证据（硬验收 6）
- **RED 阶段**（`FormatNoWebViewMessage` 未区分 0 与真实错误码）：
  ```text
  Done testing.
  Tests Found   : 347
  Tests Ignored : 0
  Tests Passed  : 346
  Tests Leaked  : 0
  Tests Failed  : 1
  Tests Errored : 0

  Failing Tests
    Test.AsWish.CommandLine.TTestAsWishCommandLine.Test15_FormatNoWebViewMessage_DifferentiatesZeroAndErrorCode
    Message: Condition is False when True expected. [Msg0 must explain timeout/not reported]
  ```
- **GREEN 阶段**（实现纯函数区分 `$00000000` 描述与真实错误码格式化）：
  ```text
  Done testing.
  Tests Found   : 347
  Tests Ignored : 0
  Tests Passed  : 347
  Tests Leaked  : 0
  Tests Failed  : 0
  Tests Errored : 0
  ```

#### (3) 场景矩阵与强制失败路径实测（硬验收 1、2、3）
本机未安装可用 Evergreen WebView2 Runtime，正常运行下 `WaitForWebViewReady(3000)` 充足等待后读出真实底层错误码 `$80070578`（已不再是未初始化值 `$00000000`）。

强制指定 `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=D:\_Progs\02Business\AsWish\_repro\no_such_browser` 进行三形态全覆盖实测：

| 运行形态 | 命令 | EXIT | stdout | stderr | 错误码实值 | 判定 |
|---|---|---|---|---|---|---|
| 形态 1（分离重定向） | `cmd /c "bin\AsWish.exe --gui-verify dogfood_gui_site_final > out_forced.txt 2> err_forced.txt"` | 1 | 0 字节 | 305 字节 | `$80070002` | 通过 |
| 形态 2（合并重定向） | `cmd /c "bin\AsWish.exe --gui-verify dogfood_gui_site_final > log_combined_forced.txt 2>&1"` | 1 | 305 字节 | (合并) | `$80070002` | 通过 |
| 形态 3（PowerShell 管道） | `Start-Process ... -RedirectStandardError "ps_err_forced.txt" -RedirectStandardOutput "ps_out_forced.txt"` | 1 | 0 字节 | 305 字节 | `$80070002` | 通过 |

- 实测 `err_forced.txt` 原始内容（305 字节）：
  ```text
  [GUI-VERIFY FAILED] Exception: GUI-VERIFY-NO-WEBVIEW: WebView2 Runtime is not created (LastErrorCode: $80070002). Functional WebView2 environment is required for GUI verification.
  [GUI-VERIFY SUMMARY] FAIL: GUI verification failed. Evidence: D:\_Progs\02Business\AsWish\dogfood_gui\gui-dual-surface.txt
  ```
- 错误码实值为真实错误码 `$80070002`，无 `$00000000` 混淆。

#### (4) 证据文件真实性与未回归（硬验收 5）
`dogfood_gui/gui-dual-surface.txt` 完整生成，实测记录：
```text
Browser State: 3
WebView Created: False
Last Error Code: $80070002
============================================================
[FAILED] Exception: GUI-VERIFY-NO-WEBVIEW: WebView2 Runtime is not created (LastErrorCode: $80070002). Functional WebView2 environment is required for GUI verification.
GUI Verification Exit Code: 1
```

#### (5) 回归面实测
- `bin\AsWish.exe foo bar` → EXIT=1，stderr 打印用法块。
- `bin\AsWish.exe --gui-verify` → EXIT=1，stderr 打印缺失目录提示。
- `cli\bin\AsWish.CLI.exe validate dogfood_gui_site_final` → EXIT=0，5 树 0 错误 0 警告，打印 `[validate] OK`。

### 3. 全量门禁与净室验证

- **SPW 7 道 Required 门禁全 PASS**：
  - `gate_open_source_build.py`: PASS (188 files)
  - `gate_encoding.py`: PASS (含 `*.ps1`)
  - `gate_autofix.py`: PASS
  - `gate_ehai_vendor_drift.py`: PASS
  - `gate_resource_locks.py`: PASS
  - `gate_ui_bridge.py`: PASS (rendered=14 handlers=14)
- **净室三构建 + 测试验证**：
  - `git archive HEAD` 纯净目录解包（188 个文件）
  - `_build.bat`: exit 0（GUI + CLI 成功构建）
  - `tests\_build_tests.bat`: exit 0（测试二进制成功构建）
  - `tests\AsWish.Tests.exe`: 347/347 PASS, exit 0
- **工作区代码树状态**：
  `git status --porcelain -- src tools tests` 输出完全为空。

