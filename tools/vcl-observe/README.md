# VCL Reality Observer (`tools/vcl-observe`)

本目录包含 AsWish 的 VCL 现实观察工具，用于在不修改目标程序源码、不依赖 DLL 注入的前提下，无侵入观察运行中 Windows VCL 桌面程序的真实界面控件与布局状态（WO-20261009-0108 Stage 2.5 WP2）。

## 核心脚本

- `observe_vcl.py`:
  - 基于 Windows 原生 UI Automation (UIA) 和 Win32 Accessibility 标准接口；
  - 启动或连接目标 VCL 可执行文件进程，无侵入提取顶级窗口及其子控件实际坐标 (`Left`, `Top`, `Width`, `Height`)；
  - 支持读取 DFM 源码目录 (`--dfm-dir`)，将 Windows 控件句柄/类名优雅映射回 View Spec 节点标识（如 `BtnConfirm` -> `view-ctrl-btnconfirm`）；
  - 对无法通过通用 UIA 获取的样式属性（如字体颜色）明确输出 `FontColor: null`，供比对插件触发 UNKNOWN 容错（不误报红、不误报绿）；
  - 具备超时安全看门狗与进程树安全清理机制 (`job_object` / Win32 `TerminateProcess`)，避免残留孤儿进程；
  - 产出标准化 `runtime-observation.json`，供 `AsWish.Plugins.VCL.Difference` 消费。

## 使用方法

```powershell
python tools/vcl-observe/observe_vcl.py --exe <path-to-vcl-exe> --output <output-json-path> [--dfm-dir <dfm-source-dir>] [--timeout 10]
```
