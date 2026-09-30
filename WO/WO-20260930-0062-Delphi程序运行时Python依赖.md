# WO-20260930-0062 · Delphi 独立程序存在运行时 Python 依赖（截图兜底断裂 + 冷启动双实现漂移）

- **提出人**：老板（第一性原理质疑："Delphi 独立版本程序的为什么还要依赖 python"）→ 主控核实后开单
- **归属仓库**：`D:\_Progs\02Business\AsWish`
- **上游**：2026-09-30 干净房间开源验收（WO-0061 同场）的延伸。老板看到验收记录里 Python 冷启动路径后质疑。**核实结论：质疑属实，且比表面更严重**——一处是 GUI exe 的真实运行时依赖且在安装包内断裂；另一处是双实现漂移。
- **优先级**：P1（A、B）/ P3（C）
- **结论先行**：AsWish 是 Delphi 独立程序，但 (1) 界面程序有一条截图兜底路径会在运行时 `python scripts\render_view.py`；(2) README 教没有 Delphi 的用户用 Python 脚本冷启动工作区，而该脚本与 CLI `init` 是两份独立实现、结构已经漂移。两处都该收掉。

---

## 1. A · P1 · GUI exe 运行时调用 Python，且安装包里这条依赖是断的

### 代码事实（`src/app/AsWish.MainForm.pas`）

`SaveWindowScreenshot` 的离屏/虚拟会话兜底路径（1919-1943 行）：

```pascal
LRepoRoot := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..'));
LScript   := TPath.Combine(LRepoRoot, 'scripts\render_view.py');
LCmd      := Format('python "%s" "%s" "%s" %d %d',
  [LScript, FLastHtmlPath, LTempPng, CenterPanel.Width, CenterPanel.Height]);
ExecuteCommandSync(LCmd);
if TFile.Exists(LTempPng) then   // 图没生成也不报，静默跳过
```

### 为什么说"断"（三条断裂叠加）

| 断裂 | 证据 |
|---|---|
| 安装包不装 `scripts/` | `installer/AsWish.iss` [Files] 段只打包 `bin\AsWish.exe`、`WebView2Loader.dll`、`cli\bin\AsWish.CLI.exe`——**`scripts/render_view.py` 不在安装包内** |
| 脚本路径按"exe 目录的父级"拼 | 安装版 exe 在 `{autopf}\AsWish\AsWish.exe`，父级即 Program Files 根 → 即使有人手动放脚本也找不到 |
| 两类失败全静默 | `ExecuteCommandSync`（781-799 行）CreateProcess 失败（没装 Python / 脚本不存在）时**无返回值、无日志、无计数**，仅 WaitForSingleObject 15s 后返回；结果被 1929 行 `if TFile.Exists(LTempPng)` 吞掉 |

**用户可见后果**：安装版用户在离屏/无头会话场景下，截图里浏览器区域空白，程序无任何提示（不确定度标注：本机无 WebView2，未能实机复现安装版该路径的最终观感；代码级断裂链已逐条读实）。

### 为什么"非得 Python"不成立

`scripts/render_view.py` 的实际能力（已读全）：**纯标准库**（sys/os/subprocess/shutil），逻辑 = 找到 msedge/chrome → `--headless --screenshot` 渲染 HTML 成 PNG。没有第三方 Python 包。等价能力在 Delphi 侧一次 `ShellExecuteEx`/`CreateProcess` 即可完成，**Python 中介不提供任何增量价值**，只增加一个运行时依赖 + 一条断裂链。

---

## 2. B · P1 · 冷启动双实现已漂移：`init_workspace.py` vs CLI `init`

### 实测对比（2026-09-30 干净房间，两个全新目录，各只跑一次 init）

| 维度 | `protocol/tools/init_workspace.py`（Python） | `AsWish.CLI.exe init`（Delphi） |
|---|---|---|
| 产物文件数 | 9 | 10 |
| decisions 文件名 | `decisions/review-decisions.yaml` | `decisions/requirement-decisions.yaml` |
| `.gitignore` | 无 | 有 |
| schema version | `"1.2"`（字符串） | `"1.0"`（带 UTF-8 BOM） |
| project-spec 字段 | `root/description/primary_language/initialized_at`；summary=`function_count/module_count/view_count/data_count` | `path/type/scan_time`；summary=`total_nodes/confirmed_nodes/uncertain_nodes/open_issues/decisions_count`；另有 `relations/evidence/issues/decisions/imports` 映射 |
| generator | `AsWish-L0-Init/1.0` | `aswish-scan` |

### 漂移的实质伤害

协议读者 `protocol/readers/python/aswish_reader.py:135` 读的是 **`decisions/requirement-decisions.yaml`**——Python init 建的工作区里该文件不存在（它建的是 `review-decisions.yaml`）。reader 的 `decisions()` 因 FileNotFoundError 保护返回空列表而不报错，**静默读不到真实决策文件**。即：README 教用户用 Python 冷启动，拿到的工作区与协议读者、CLI 生态的结构都不匹配。

---

## 3. C · P3 · 发布面包袱（育种后处理）

干净房间 186 文件里随包的开发侧 Python：`scripts/render_view.py`、`scripts/verify_gui_decisions.py`、`protocol/conformance/run.py`、`tools/spw-gates/*.py`（6 个门禁）、`protocol/tools/init_workspace.py`。需逐类裁定：协议 conformance/门禁脚本对开源共建者有价值（保留建议）；init_workspace.py 见 §2；render_view.py 见 §1。

---

## 4. 修复要求（默认路线，承接方可提替代方案但须先过主控）

1. **A-1 Pascal 原生化**：删除 1925-1928 的 Python 调用，改为 Delphi 内直接 `CreateProcess` 起 msedge/chrome headless `--screenshot`（`render_view.py` 的全部逻辑可 1:1 翻译，无需第三方组件）。**同时**给 `ExecuteCommandSync`（或新函数）补上真实错误路径：失败必须在日志/状态栏可见，不许再静默。
2. **A-2 回归验证**：截一张已知 HTML 的图，新路径必须产出非空 PNG；把 `python` 从 PATH 移除/架空前重跑同类场景，验证不再有任何"找 python"行为（可用 strace/进程监控或代码走查 + 门禁 grep：`src/` 全域禁用 `python` 字样命令行）。
3. **B-1 单一真相源**：**删除 `protocol/tools/init_workspace.py`**，README "Standalone Cold-Start (Zero Delphi Dependencies)" 章节改写为引导用户下载/构建 CLI exe 后 `AsWish.CLI init <dir>`（零安装、零运行时依赖、原生 64 位）。协议 Python/TS **reader 保留**（跨语言只读是协议层应有的能力，不砍）。
4. **B-2 门禁防再漂移**：`gate_encoding` 或新门禁里加一条——发布包内若存在 `.py` 必需有 README 说明其归属（开发侧/协议侧），`src/` 与 `cli/` 的 Pascal 代码全域禁止 `python` 命令行调用。
5. **C-1** §3 各类脚本逐类给出去留裁定并执行。

## 5. 边界（不许动）

- 不改协议 schema 本身（1.0/1.2 的归一属协议治理，另单讨论）；本单只让"两份 init 实现归一"，不动 schema 内容。
- 不改 CLI 已验收行为（331/331 是基准，`init` 产物结构以 Delphi 版为准绳）。
- 不动 WO-0061（gui-verify）范围，不碰 WO-0060（.BetterCiv 侧）。

## 6. 验收标准

1. `grep -rn "python" src/ cli/ --include=*.pas` 在可执行代码路径零命中（注释/扫描器语言检测字符串除外，且须有注释说明）。
2. 离屏截图路径在**未装 Python** 的环境产出非空 PNG（本机可架空 PATH 验证）。
3. `protocol/tools/init_workspace.py` 从发布包移除；README 冷启动章节改写后照其步骤可 0 依赖初始化。
4. 干净房间三构建 exit 0 + 331/331 不回退 + `git archive HEAD` 186 文件中 `.py` 清单与本单 §3 裁定一致。

### 验收执行回填（2026-09-30 实测）

1. **第 6.1 条（Pascal 可执行代码零 Python 命中）**：**PASS**
   - 执行 `git grep -n -i "python" src/ cli/`。
   - 仅命中 `src/services/AsWish.Services.Scan.pas:283`（项目分类检测注释）与 `290`（`Exit('python_backend')` 静态语言分类返回），在可执行命令行路径 0 命中。
2. **第 6.2 条（离屏截图原生无 Python 化）**：**PASS**
   - `SaveWindowScreenshot` 兜底路径已改由 Pascal 原生函数 `RenderHtmlToPngNative` 承接，通过 Win32 `CreateProcess` 直接拉起 `msedge.exe`/`chrome.exe` headless `--screenshot`，不依赖系统安装 Python，且增加了非静默告警与目录自动创建。
3. **第 6.3 条（单一真相源冷启动）**：**PASS**
   - 已删除 `protocol/tools/init_workspace.py`。
   - `README.md`、`protocol/README.md`、`docs/01.产品-AsWish产品身份与愿景蓝图.md` 全面更新为引导用户使用原生 64 位无依赖的 `AsWish.CLI.exe init <dir>`。
   - 实测在干净临时目录执行 `AsWish.CLI.exe init`，成功生成标准 `.AsWish/` 工作区，零外部运行时依赖。
4. **第 6.4 条（三构建 + 331/331 + 发布包归属治理门禁）**：**PASS**
   - `_build.bat` 构建 GUI `bin/AsWish.exe`：Exit 0。
   - `cli/_build_cli.bat` 构建 CLI `cli/bin/AsWish.CLI.exe`：Exit 0。
   - `tests/_build_tests.bat` 构建并运行 `tests/AsWish.Tests.exe`：Exit 0，331/331 全部 PASS。
   - 删除废弃/漂移脚本（`init_workspace.py`、`render_view.py`、`verify_gui_decisions.py`），新增 `tools/spw-gates/README.md` 与 `scripts/README.md` 说明归属。
   - 门禁 `gate_open_source_build.py` 补充 Pascal 禁止 Python 命令行与导出 Python 归属检查；实测 185 文件归属明确，门禁全绿（PASS）。
