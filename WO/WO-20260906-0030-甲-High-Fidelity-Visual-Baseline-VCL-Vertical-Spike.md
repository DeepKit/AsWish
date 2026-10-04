# WO-20260906-0030-甲-High-Fidelity-Visual-Baseline-VCL-Vertical-Spike

## 1. 工单基础信息
* **工单号**: WO-20260906-0030
* **归属/执行者**: 甲
* **状态**: CLOSED / PASSED (CONDITIONAL)
* **关联文档**: `WO/AsWish-HighFidelity-VCL-Spike-Architecture.md`

## 2. 目标 (Goal)
执行一次纵向穿透的 Spike，在受控的 VCL 环境中，验证“High-Fidelity Visual Baseline”可行性，证实“开发前所见”可通过严密的证据提取与差异比对机制，有效印证“开发后所得”，以推进布局与高保真协议的正式落地。

## 3. 立票门槛达成清单 (R1 Passed)
- [x] Identity mapping 无损且不新增 canonical identity。
- [x] Layout 是 experimental candidate，不提前污染 protocol。
- [x] L2 是 Constraint → Observation Compare。
- [x] L3 是 Expected Resolved Style → Runtime Observation Compare。
- [x] Comparison Profile 可复现。
- [x] Difference ≠ Error (由 Human judgment)。
- [x] Spike 的证明范围严格限定在 VCL Profile 可行性与协议前实证。

## 4. 实施纵切序列
* **S1. Identity Binding**: `node.id` ↔ `AW_xxx` 双向无损映射。
* **S2. Experimental Layout**: 注入实验性最小布局候选（不改 schema）。
* **S3. VCL Preview**: 基于实验性布局渲染 VCL 预览表单。
* **S4. Human Baseline**: `SpecSnapshot + Visual Binding`（录入预期 Token）。
* **S5. Agent Handoff**: 输送 Baseline，约束代码生成。
* **S6. Runtime Extract**: 从编译出的 VCL 执行体中，抽取 TControl Bounds, Color, Font，记录 Profile，并截图。
* **S7. L2 Verification**: 检测人为制造的错位，观测引擎报告 Layout Difference。
* **S8. L3 Verification**: 人为制造一个受控 Layer 3 配色差异，观测引擎报告 Appearance Difference。
* **S9. Dogfood Review**: 在最终报告呈现双重 Evidence 并执行 Judgment。

## 5. 验收标准 (AC)
1. Extractor 仅提供 Observation 数据，Difference 层仅进行 Compare 而非反推意图。
2. 完整跑通 S1 - S9 链路，生成包含 L2 及 L3 Difference 记录的验证报告。
3. `AW_xxx` 能通过 Visual Binding 被准确还原至 `node.id`，身份不断链。
4. 提供含真实报错判定截图的最终 Dogfood Evidence。
