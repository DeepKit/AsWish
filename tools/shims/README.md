# Toolchain Shims (`tools/shims`)

本目录受 Git 版本控制，包含外部工具链与宿主 CLI 执行环境的修补与加固垫片组件（阶段 4 治理交付）。

---

## 1. 组件清单

### `safe-delete-bulk-guard.cjs`
宿主环境 CLI 安全删除保护钩子（`check` / `approve` 命令守卫）。

- **目标安装路径**：
  `<CLI_RUNTIME_DIR>/resources/app.asar.unpacked/cli/vendor/shim/safe-delete-bulk-guard.cjs`
- **治理与修复背景**：
  - 解决多轮持续开发后因回合删除累计达阈值（$\ge 50$）将开发者自己刚生成的临时反证探针文件误拦截为危险批量删除的问题，引入小量自建探针放行机制；
  - 彻底修复原先用 `max(birthtime, ctime, mtime)` 导致既有文件被写入或改属性即被冒充为“自建探针”的缺陷；改为严谨的 `birthtimeMs` 单项时间窗口与 Git 未跟踪校验，杜绝旧文件被静默放行删除。

---

## 2. 外部组件与升级失效声明 (升级风险提示)

> ⚠️ **重要声明**：
> - 位于宿主软件安装目录下的运行垫片属于外部宿主软件的覆盖组件；
> - **宿主软件版本更新、热修复或重装将自动覆盖并回退该垫片**；
> - 升级后需由维护者人工复核，并将本目录下受版本控制的权威源文件重新部署同步至安装路径。

---

## 3. 部署与同步操作

当宿主 CLI 环境重新安装或升级后，运行同步命令即可恢复垫片：

```bash
# 从仓库受控源覆盖至宿主 CLI 垫片安装目录
copy /y tools\shims\safe-delete-bulk-guard.cjs "<CLI_RUNTIME_DIR>\resources\app.asar.unpacked\cli\vendor\shim\safe-delete-bulk-guard.cjs"
```

同步后可运行回归测试验证有效性：
```bash
python D:\_repro\hookaudit\run_cf2.py
```
