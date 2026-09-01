# AsWish 当前文档索引 v1

> 更新：2026-08-30
> 本索引只负责定位；协议、实现和用户说明分别以链接目标为唯一信息源。
> 权威文件注册表与冲突处理规则见根目录 [`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md)。

## 当前入口

| 入口 | 唯一职责 |
|---|---|
| [`../README.md`](../README.md) | 对外项目定位、构建入口和 CLI 总览 |
| [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md) | 产品身份权威定义（层级/研究问题/主链/人机边界/Difference/愿景） |
| [`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md) | 文档治理权威（权威注册表/引用规则/冲突处理） |
| [`../SPEC.md`](../SPEC.md) | 当前 v1.2-draft 协议基线 |
| [`CTF.md`](CTF.md) | CTF 方法的工程解释 |
| [`AsWish-用户上手说明-v1.md`](AsWish-用户上手说明-v1.md) | 首次运行、审阅、LLM 配置和 CLI 操作路径 |
| [`AsWish-工程路线与Dogfood验收-v1.md`](AsWish-工程路线与Dogfood验收-v1.md) | 工程阶段、工单依赖顺序、双闸门（Engineering / Dogfood）验收与 First Closed Loop 验收 |
| [`AsWish-统一选择交互标准-v1.md`](AsWish-统一选择交互标准-v1.md) | 0–9 统一选择交互协议（1–7 候选 / 8 重新生成 / 9 自然语言 / 0 返回）与语义色 Token，已冻结 |
| [`AsWish-可见判断规范-OJP-v1.md`](AsWish-可见判断规范-OJP-v1.md) | 可见判断原则（Artifact / Observable / Judgment、VC-01～06、Difference 四层比较与插件系统） |
| [`AsWish-双界面交互规范-DualSurface-v1.md`](AsWish-双界面交互规范-DualSurface-v1.md) | 双界面（Conversation 探索 / Decision 判断）切分与 0–9 的父框架 |
| [`WO-20260830-0027D-前置工程勘察报告.md`](WO-20260830-0027D-前置工程勘察报告.md) | 0027D 前置工程勘察：GUI 现状盘点、0027A/B/C 能力映射与复用判断 |
| [`../protocol/`](../protocol/) | JSON Schema、状态机、不变量和读者契约 |
| [`理论确权清单-v1.md`](理论确权清单-v1.md) | 理论归因、DOI、主张强度与待确权项 |

## 四投影

当前协议固定使用：

```text
function-tree / module-tree / view-tree / data-tree
```

四投影语义、字段和边界只看 [`../SPEC.md`](../SPEC.md) §3；用户操作只看 [`AsWish-用户上手说明-v1.md`](AsWish-用户上手说明-v1.md)。

## 产品与实现参考

- 定位与战略：[`AsWish-产品功能与愿景蓝图-v1.md`](AsWish-产品功能与愿景蓝图-v1.md)（当前产品功能与愿景基线）；历史讨论稿：`DeepSpec-定位升级-所见即所得开发文档优化器-v1.md`、`DeepSpec-产品蓝图与蓝海判断-v1.md`、`DeepSpec-战略定稿-v1.md`。
- 事实、审阅与决策（历史设计稿）：`DeepSpec-B事实模型与第一层所见即所得-v1.md`、`DeepSpec-人类决策写回与AI影响机制-v1.md`、`DeepSpec-旁路查阅与提示词规范-v1.md`。
- 实施与样板（历史设计稿）：`DeepSpec-DeepBase首版落地清单-v1.md`、`DeepSpec-借力DeepBase框架接入方案-v1.md`、`DeepSpec-DelphiVCL解析与验收-v1.md`。
- 图表与体验（历史设计稿）：`DeepSpec-第一层图表体系定稿-v2.md`、`DeepSpec-HTML审阅图表参考-v1.md`、`DeepSpec-开源与视觉系统分层方案-v1.md`。
- 外部实践启发：`wayfinder-fog-of-war.md`（原文存档）、`wayfinder-对DeepSpec的启发.md`（历史启发记录，Wayfinder/Grill-me 为外部实践，不属原创理论）。

## 历史文档

以下文件保留为历史材料，文件内已标注"三棵树"是失效口径：

- `DeepSpec-三棵树通用协议-v1.md`
- `DeepSpec-三棵树通用协议-第一轮审阅意见-v1.md`
- `DeepSpec-三棵树通用协议-第二轮审阅意见-v1.md`
- `DeepSpec-三棵树通用协议-标准化圆桌讨论-v1.md`
- `DeepSpec-MVP实施蓝图-旁路查阅与三树-v1.md`

其它旧讨论文档若与 [`../SPEC.md`](../SPEC.md) 冲突，以 [`../SPEC.md`](../SPEC.md) 为准；历史材料不作为当前实现契约。历史文件保留 `DeepSpec-` 原名是迁移纪律（不篡改历史），引用时必须使用真实文件名。
