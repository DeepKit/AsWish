# AsWish High-Fidelity Visual Baseline 文档同步报告
> **性质**：非 SSOT (NON-SSOT)，仅作审计与留痕。
> **日期**：2026-09-06

## 1. 文档修改分布矩阵

| 文件 | 是否修改 | 修改原因与内容 | 新事实等级 | 是否改变协议 |
| :--- | :--- | :--- | :--- | :--- |
| `01.产品-AsWish产品身份与愿景蓝图.md` | 是 | 增加 WYSIWYG V0 边界说明，新增高保真规划及 VCL 第一验证平台方向。 | DESIGN / PLAN | **NO** |
| `03.规范-可见判断与交互规范.md` | 是 | 明确 OJP-07 保真度历史边界，补充 vNext 消除可比性断层的方向及 Layer 3 双证据原则（截图+结构）。 | FACT / DESIGN / PLAN | **NO** |
| `05.协议-AsWish协议基线.md` | **否** | 恪守纪律，协议 schema 必须等待 VCL Spike 真实验证后方可变更。刻意未修改。 | - | **NO** |
| `07.工程-工程路线与Dogfood验收.md` | 是 | 声明 0028 边界已完成其阶段使命。更新当前下一工程目标为 `VCL Vertical Spike` 并附带明确约束与 Spike AC。 | PLAN | **NO** |
| `13.治理-文档治理与工程纪律.md` | 是 | 于末尾追加登记 `WO/AsWish-高保真VisualBaseline专项调研.md` 为 NON-SSOT 决策支持研究。 | NON-SSOT | **NO** |
| `17.产品-开发随心的六脉神剑与用户价值.md` | **否** | 现有内容已充分布道价值层，为避免出现 `VCL/DTCG/UIA` 等技术词汇污染最高 SSOT，刻意未修改。 | - | **NO** |
| `WO/AsWish-高保真VisualBaseline专项调研.md` | 是 | R2.1 修正：移除“无可辩驳的 L3 证据”，改为“最终人眼 Render 仍由 Screenshot 补充”；移除“内存扫描”，改为“TComponent/RTTI”。 | NON-SSOT | **NO** |

---

## 2. 核心执行摘要
1. **修改了哪些文件**：01、03、07、13 以及调研报告。
2. **每个文件修改了哪几节**：在 01 中修正了 Visual Baseline v0 的历史说明并增加 High-Fidelity 章节；在 03 中修订了 OJP-07、可比性断层及 Layer 3 证据规范；在 07 中追加了 Next Architecture Task (Spike)。
3. **哪些旧文字保留为历史 v0**：所有关于“结构线框”、“L0/L1 差异比较”的文本均被作为 FACT 予以保留，仅在旁增加了阶段声明批注。
4. **哪些文字被改成 vNext DESIGN / PLAN**：VCL 提取器、Platform Profile、双证据合并等，均严格打上了 `DESIGN` 或 `PLAN` 标签。
5. **哪些文件刻意未修改，以及为什么**：`05` 协议（架构未实证前禁止盲目扩展 Schema）；`17` 用户价值（避免被工程与技术词汇反向污染）。
6. **是否修改 protocol schema**：绝对没有。
7. **是否新增任何实体 / 状态机 / Identity / Difference 体系**：绝对没有。坚决复用现有的 Baseline, node.id, Implementation Evidence 以及四层 Difference。
8. **全仓语义扫描结果**：经过对整个知识库语义及上下文的过滤，确认没有残留“stable_id”、“新 Difference Engine”或把“Flexbox 视为跨平台绝对标准”的越界断言。
9. **Git diff 摘要**（预估）：主要涉及 `.md` 文本的新增段落追加，整体架构无破坏性变更。

---

## 3. 最终架构师心智校验对齐

**问题：现在一个新的架构师只阅读现行 SSOT，能否得到下面这个一致认识？**

> Visual Baseline v0 已经完成结构线框闭环；
> 结构线框是历史阶段边界，不是永久产品上限；
> 下一阶段不新建视觉体系，而是增强现有 Accepted Visual Baseline；
> 第一条实证路线是 VCL Platform Profile / Vertical Spike；
> 协议 layout 字段尚未冻结，必须由真实 Spike + 架构裁定后才能进入 protocol；
> Difference / Evidence / node.id / Baseline 均继续复用现有体系。

**回答：完全可以。**
上述所有核心论点，均已被作为 FACT 或 PLAN 清晰、独立地写入了最权威的 01（愿景）、03（规范）和 07（工程路线）文件中。由于未修改 05 协议，架构师在阅卷时将清楚地知道“路线已定，但协议正在等待前端 Spike 的反哺验证”。语义逻辑处于完美连贯状态。
