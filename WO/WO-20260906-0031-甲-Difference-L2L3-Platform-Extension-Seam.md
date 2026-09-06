# WO-20260906-0031-甲-Difference-L2L3-Platform-Extension-Seam

## 1. 工单基础信息
* **工单号**: WO-20260906-0031
* **归属/执行者**: 甲
* **状态**: DONE / COMPLETED
* **关联文档**: `WO/AsWish-ADR-Post-0030-Difference-And-AppService.md`

## 2. 目标 (Goal)
为现存的 `TAsWishDifferenceService` 提供标准的 L2/L3 Platform Extension Seam（扩展缝隙），使外挂的 Comparator 能够安全地向系统内注入 Layout (L2) 和 Appearance (L3) 差异，而不污染 Difference Core 本身的代码与边界。

## 3. 验收标准 (AC)
1. Difference Core 零 VCL / Winapi 依赖。
2. Difference Core 零硬编码 observation/binding 文件路径。
3. VCL Comparator 能输出真实 L2/L3 的 `TSpecDifferenceItem`，其中 L3 暂时映射为 `daContent`。
4. 结果进入 existing `difference.yaml`，现有模块可无缝消费。
5. 决不新增第二持久化 Difference 模型。

## 4. 实施清单
- [x] 在 `AsWish.Services.Difference.pas` 中定义 `IPlatformDifferenceComparator` 与 `TPlatformComparisonContext`，并引入 `IPlatformIdentityResolver`。
- [x] 重构 `TAsWishDifferenceService.ComputeDifference`，允许注册并分发给 Comparator 提取扩展差异项，并持久化既有 `difference.yaml`。
- [x] 编写 VCL 平台专属的 Comparator 实现 `AsWish.Plugins.VCL.Difference.pas`，承接结构事实的验证责任（保持与 Core 解耦）。
- [x] 编写 `Test.AsWish.Difference.L2L3.pas` 自动化测试套件，全面覆盖 4 个必测用例与服务注册分发（211/211 PASS）。
