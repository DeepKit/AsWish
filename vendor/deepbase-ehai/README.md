# vendor/deepbase-ehai

这两个单元是 **vendored（收存）副本**，不是 AsWish 原创代码。放它们在这里的唯一原因：
AsWish 的开源发布必须能在**不依赖 DeepBase 私有仓**的情况下编译。

启用边界：`DeepBase/LICENSE`（Apache-2.0）覆盖这两个单元；
`DeepBase/LICENSE-BSL`（Business Source License 1.1）的参数段只覆盖
`Core/DeepBase.AutoFix*`、`FMX/DeepBase.AutoFix*`、`Features/DeepBase.Browser*`、
`Governance/DeepBase.Governance*`，**不含本目录两文件**。再分发合法，
归属与许可原文见本目录 `LICENSE`。

## 收存了什么

| 文件 | 上游 | 偏差 |
|---|---|---|
| `DeepBase.EHAI.Types.pas` | `DeepBase/Core/DeepBase.EHAI.Types.pas` | 无，去 BOM 后逐字节一致 |
| `DeepBase.HB.Choice.Types.pas` | `DeepBase/Core/DeepBase.HB.Choice.Types.pas` | 仅删除 `uses` 里的死引用 `DeepBase.HB.Core` |

死引用一事是实测结论，不是推断：上游 `DeepBase.HB.Choice.Types` 的 `uses` 子句
声明使用 `DeepBase.HB.Core`（1335 行的主题/令牌引擎），但全文未引用其任何符号。
把那一行删掉后单独编译，exit 0、979 行、无缺符号报错。不删的话，
脱离 DeepBase 的构建会以 `F2613 Unit 'DeepBase.HB.Core' not found` 失败。

单元名**故意保持 `DeepBase.*` 原名**：`AsWish.Binding.HB.pas` 头部登记的
SSOT 基线（`EHAI-DELPHI-SYMBOL-BASELINE-v1.0`）按这两个路径与 SHA256 记账，
改名会让登记值失效。

## 怎么保证不退化成"抄完就没人管"

`tools/spw-gates/gate_ehai_vendor_drift.py`（确定性门禁）：

- 上游可达时（`DEEPBASE_HOME` 或默认 `../DeepBase`）重算上游 SHA256，
  与 `upstream.json` 的登记值比对——上游一改就 FAIL，必须人工复核后重新收存；
- 上游不可达时（任何人从公开仓库克隆）SKIP 并说明原因，不阻塞构建；
- 另校验收存文件自身 SHA256，防本地误改。

指纹约定：对上游文件内容**去掉 UTF-8 BOM 后**取 SHA256。
`AsWish.Binding.HB.pas` 头部登记的两枚指纹就是这个约定下的值。

## 后续

若将来 DeepBase 的类型层要独立公开发布，正确做法是双方共同依赖一个小型
Apache-2.0 类型包，然后删掉本目录。那会改变 SSOT 归属，须单独立单，
不当作顺手清理。
