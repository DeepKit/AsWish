# AsWish 当前文档索引 v1

> 更新：2026-08-30
> 本索引只负责定位；协议、实现和用户说明分别以链接目标为唯一信息源。

## 当前入口

| 入口 | 唯一职责 |
|---|---|
| [`../README.md`](../README.md) | 对外项目定位、构建入口和 CLI 总览 |
| [`../SPEC.md`](../SPEC.md) | 当前 v1.2-draft 协议基线 |
| [`CTF.md`](CTF.md) | CTF 方法的工程解释 |
| [`AsWish-用户上手说明-v1.md`](AsWish-用户上手说明-v1.md) | 首次运行、审阅、LLM 配置和 CLI 操作路径 |
| [`../protocol/`](../protocol/) | JSON Schema、状态机、不变量和读者契约 |
| [`AsWish-文档优化审查报告-2026-05-20.md`](AsWish-文档优化审查报告-2026-05-20.md) | 文档清理审查记录 |

## 四投影

当前协议固定使用：

```text
function-tree / module-tree / view-tree / data-tree
```

四投影语义、字段和边界只看 [`../SPEC.md`](../SPEC.md) §3；用户操作只看 [`AsWish-用户上手说明-v1.md`](AsWish-用户上手说明-v1.md)。

## 产品与实现参考

- 定位与战略：[`AsWish-产品功能与愿景蓝图-v1.md`](AsWish-产品功能与愿景蓝图-v1.md)（当前产品功能与愿景基线）、[`AsWish-定位升级-所见即所得开发文档优化器-v1.md`](AsWish-定位升级-所见即所得开发文档优化器-v1.md)、[`AsWish-产品蓝图与蓝海判断-v1.md`](AsWish-产品蓝图与蓝海判断-v1.md)、[`AsWish-战略定稿-v1.md`](AsWish-战略定稿-v1.md)。
- 事实、审阅与决策：`AsWish-B事实模型与第一层所见即所得-v1.md`、`AsWish-人类决策写回与AI影响机制-v1.md`、`AsWish-旁路查阅与提示词规范-v1.md`。
- 实施与样板：`AsWish-DeepBase复用清单-v1.md`、`AsWish-借力DeepBase实施方案-v1.md`、`AsWish-DelphiVCL项目分析样板-v1.md`。
- 图表与体验：`AsWish-第一层图表设计-v2.md`、`AsWish-HTML图表与JS Bridge设计-v1.md`、`AsWish-Wayfinder与Fog可视化-v1.md`。

## 历史文档

以下文件保留为历史材料，文件内已标注“三棵树”是失效口径：

- `AsWish-三棵树通用协议-v1.md`
- `AsWish-三棵树通用协议-第一轮审阅意见-v1.md`
- `AsWish-三棵树通用协议-第二轮审阅意见-v1.md`
- `AsWish-三棵树通用协议-标准化圆桌讨论-v1.md`
- `AsWish-MVP实施蓝图-旁路查阅与三树-v1.md`

其它旧讨论文档若与 [`../SPEC.md`](../SPEC.md) 冲突，以 [`../SPEC.md`](../SPEC.md) 为准；历史材料不作为当前实现契约。
