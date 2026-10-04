# WO-20260906-0030-甲 Dogfood & Evidence Review

> **目标**：验证 VCL High-Fidelity Visual Baseline 从协议建立到真实差异断言的纵切全链路。
> **状态**：Evidence 收口与事实校准（R1.2）

## 1. 真实复用与实验边界校准

本次 Spike 复用了真实的 `AsWish.Services.Snapshot` 以固化 `SpecSnapshot`。
对于 Spike 中引入的承载实体，做如下严格事实校准：

*   **`visual-binding.yaml`**：明确标记为 `SPIKE-LOCAL`、`NON-CANONICAL`、`NOT A PROTOCOL FILE`。该文件仅作为本次纵切的 fixture 承载，尚未被纳入现有 AsWish `05` 协议或正式 schema，且未侵入 canonical workspace 的正式事实。
*   **Difference 引擎状态**：
    *   `L2/L3 comparison semantics = VERIFIED BY SPIKE`
    *   `Existing Difference L2/L3 integration = NOT YET IMPLEMENTED`
    *   Spike Adapter 的运行仅证明“平台 Observation 可以被归一化并形成符合现有 Difference 语义的 L2/L3 Difference”，**绝不声称 Existing Difference 已经正式支持 L2/L3**。

## 2. 纵切实证：VCL Runtime Extractor 

我们使用 Delphi 原生 RTTI 构建了 `VCL Extractor`，该探针递归遍历 `Controls[]` 并提取客观的 Observation：
```json
{"Name": "AW_BtnConfirm", "Bounds": {"Left": 180, "Top": 160, "Width": 80, "Height": 30}, "FontColor": -16777208}
{"Name": "AW_Title", "Bounds": {"Left": 16, "Top": 16, "Width": 38, "Height": 25}, "FontColor": 255}
```
**【实证结论】**：Extractor 仅提供纯粹的事实观测（Bounds / Colors），**没有**逆向猜测意图。

## 3. 纵切实证：Layer 2 / Layer 3 Difference 触发

我们人为制造了两个受控的观察差异（Controlled Difference）：Confirm 按钮与 Cancel 发生 Layout Difference；Title 颜色发生 Appearance Difference。
Spike-Adapter 将上述 Observation 与 Baseline Constraints 比较，输出结构化 Difference：

*   **L2 Layout Difference**：`Expected Cancel left-of Confirm, but Observed Confirm (Left=180) left-of Cancel (Left=276).`
*   **L3 Appearance Difference**：`Expected clNavy (8388608) from token token.text.title, but Observed 255 (clRed).`

## 4. OJP Human Judgment Evidence

基于以上生成的事实，进入 `Observable → Human Judgment` 的完整可追溯记录。人类不是对“机器错误”盲从，而是针对呈现的 Difference 给出最终判定。

### L2 Layout Difference
*   **Human Judgment**: **Acceptable**
*   **Rationale / 理由**: 当前 VCL 平台/产品约定允许 Confirm 在左，因此观测到的位置 Difference 被人类接受。

### L3 Appearance Difference
*   **Human Judgment**: **Unacceptable**
*   **Rationale / 理由**: Title 颜色未能满足已确认的 Baseline，偏离严重，拒绝接受。

## 5. Spike 发现的架构断层 (Architecture Gaps)

1.  **Visual Baseline / Agent Handoff Application-Service Boundary Gap**
    *   **事实**：现有的 ConfirmVisualBaseline 与 Handoff 操作过度耦合 GUI Controller，导致 GUI、CLI、Test、Spike 无法共享干净的 Application Service 边界（CLI 是未来的 consumer，并非 Gap 本身）。
2.  **Missing L2/L3 Difference Plugin Seam**
    *   **事实**：目前的 `AsWish.Services.Difference.pas` 仅硬编码了 Layer 1 (内容与关系 hash) 的对比。我们需要的是在 **Existing Difference extension seam** 上提供正式的 Plugin 入口，而不是重新发明一个新的 Difference Engine。

## 6. Protocol Change Candidate Evidence

本轮实验不直接修改 `05`、schema 或 conformance，仅输出候选证据。本 Spike 实际用到的 Experimental Layout semantics 包含：
*   **必备项**：`left-of` / `right-of` (逻辑顺序约束)；`gap` (间距约束)；`Font.Color` ↔ Token Hash (样式绑定基础项)。
*   **实现便利项**：`direction` (推导便利项，非必须物理事实)。
*   **决议**：禁止将未在本次 Spike 中实际被断言的其他全套 Layout 属性打包进入协议。

## 7. 最终收口结论

### Verified
*   VCL Runtime structured observation；
*   `node.id` ↔ `implementation binding` 可工作；
*   `Declared Constraint` ↔ `Observed Relation` 可形成 L2 Difference；
*   `Expected Resolved Style` ↔ `Runtime Style` 可形成 L3 Difference；
*   `Difference ≠ Error`；
*   Human 可以分别给出 `Acceptable` / `Unacceptable` Judgment。

### Not Yet Integrated
*   official Difference L2/L3 Plugin Seam；
*   GUI-independent Visual Baseline / Handoff Application Service；
*   canonical layout protocol；
*   broad VCL visual coverage（尚未证明 OwnerDraw、Custom Paint、VCL Styles 完整覆盖、third-party control、dynamic reflow、cross-platform 的有效性）。

### WO Result
**WO-0030 Spike Objective: PASS**

*(注意：本 WO 的证明范围仅为 feasibility + architecture-gap discovery，不可以此声称 AsWish High-Fidelity Visual Baseline 已全面实现。)*
