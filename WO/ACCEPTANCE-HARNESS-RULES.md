# 验收 Harness 纪律与证据防污染规范

## 一、七项硬规则
1. **注入仅限单命令进程级**：必须使用 `cmd /c "set X=Y&& exe ..."` 或 `X=Y cmd //c ...`；严禁 PowerShell 会话级 `$env:X=...` 或 `setx`，防止同会话后续正常路径被悄悄污染而制造假因果。
2. **注入前后必须自证**：每条注入命令前后必须各打印一次环境变量（`echo %X%`），贴入证据，输出为空或未定义才算干净。
3. **计时必须指明测量点**：等待段（守卫进入至就绪/退出）以进程内日志时间戳或专用计时为准；进程总耗时单独列出，禁止混同等待段阈值直接比较。
4. **留痕必须精确可溯源**：回填引用的任何文件/日志，必须指出产生它的代码位置（文件:行号）；无法溯源的代码外留痕一律不许作为证据。
5. **严禁无差异空变体**：多轮尝试必须指明与上一轮的实质变量差异与预期影响；无实质变更的重复执行禁止列为有效尝试。
6. **未复现归因必须对照**：凡异常或未复现结论，必须附至少一条同会话单变量对照实验，未验证假设必须显式标注"未复现"或"归因假设，未验证"，禁止将未经对照的推测作为事实。
7. **必需门禁必须覆盖产品自身的真实运行路径**：`H3.deep-ui-test` 源码自述 "static bridge dispatch audit; deep UI runtime is the GUI test's job"，0.1s 跑完，属于静态审计；不得把静态审计的绿灯当作运行时绿灯的证据，必须配置真实 GUI 运行门禁（如 `H3.gui-verify-smoke`）直跑产品自身完整路径。

## 二、--gui-verify 验收命令模板（可直接复制）
### 1. 正常路径（无变量污染）
cmd /c "echo [PRE] %WEBVIEW2_BROWSER_EXECUTABLE_FOLDER% && bin\AsWish.exe --gui-verify dogfood_gui_site_final > out.txt 2> err.txt && echo [POST] %WEBVIEW2_BROWSER_EXECUTABLE_FOLDER%"

### 2. 强制失败路径（单进程内注入）
cmd /c "echo [PRE] %WEBVIEW2_BROWSER_EXECUTABLE_FOLDER% && set WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=D:\_repro\no_such_browser&& bin\AsWish.exe --gui-verify dogfood_gui_site_final > out.txt 2> err.txt && echo [POST] %WEBVIEW2_BROWSER_EXECUTABLE_FOLDER%"

## 三、下游证据自查表
| 序号 | 自查要求 | 落地准则 |
|---|---|---|
| 1 | 文案与数据溯源 | 汇报所有控制台文案与数字必须直接截取自原始输出或源码，严禁凭记忆改写。 |
| 2 | 汇报与工单一致 | 对话汇报若与工单回填不一致，以复现实测为准，并显式标注真实版本。 |
| 3 | 错误与状态复现 | 引用错误码/退出码必须附带完整、自包含且可直接复现的执行命令。 |
| 4 | 留痕代码可溯源 | 引用留痕/日志必须注明对应源码生成位置（文件:行号），禁止引用未入仓插桩。 |
| 5 | 尝试变体实质性 | 多次尝试必须列出与前次之实质参数/代码差异，杜绝无差异空变体。 |
| 6 | 异常归因有对照 | 未复现或异常现象必须附同会话对照实验，未验证项如实标注"未验证"。 |
| 7 | 门禁覆盖真实路径 | 不得以静态审计绿灯替代真实运行路径绿灯，必须直跑必需门禁（含真实 GUI 烟雾门禁）。 |
