# AsWish 高保真 Visual Baseline 专项调研 (R2 校准版)
> **调研目标**：不发明新概念，依托 AsWish 现有实体，通过“最小的、不可避免的协议与 Adapter 增量”，使开发前视觉基线与开发后实现达成同构可验证。
> **日期**：2026-09-06

---

## 01. 核心架构红线确认

本报告严格遵循 R2 冻结约束：
*   **不新建 Baseline**
*   **不新建 Identity**（沿用现存 `node.id`）
*   **不新建 Evidence 体系**
*   **不新建 Difference Engine**
*   **不新建 Visual Tree / Style Contract**

所有技术建议收敛于：**Platform Adapter 映射规则、Existing Difference 扩展、以及现存实体的精细化引用。**

---

## 02. Identity 的全链路不断链方案 (`node.id` 映射)

**现状与结论**：AsWish 现有的 `node.id` 完全可以继续承担 Canonical Identity 的唯一职责。不需要引入新的 `stable_id` 概念，我们真正需要的是建立 **Implementation Binding / Adapter** 来处理双向映射。

| 平台 | 映射方案与局限性调查 |
| :--- | :--- |
| **Web** | 映射至 `data-testid`、`data-cy` 或特定自动化测试属性。最为稳定，行业生态最成熟。 |
| **Windows UIA** | 映射至 `AutomationId`。**注**：Microsoft 官方文档明确表示 AutomationId 非强制属性，且跨版本不保证绝对稳定。 |
| **Delphi VCL** | 通过 Adapter 优先映射至 `Component.Name` (TControl.Name)。此属性具有强约束且与 VCL 实例指针强绑定。 |

**回答要求**：是的，我们只需要“Implementation Binding / Adapter”，无需增加第二个身份字段。

---

## 03. Layout 的共同参考语义集 (Profile)

**结论**：不要试图创造大一统跨端布局规范，应将 **CSS Flexbox** 视作 AsWish Layout 的 **“参考语义集 / 第一实现 Profile”**，寻找最小共同 Layout Vocabulary。

*   **Web**：可直接无损映射。
*   **VCL / Flutter / Qt**：需要各自的 Platform Adapter 翻译。例如 VCL 的 `Align=alClient` 映射为特定约束，或者使用新版 VCL 容器映射部分语义。
*   **最小共同 Vocabulary**：
    仅抽取最核心的排版意图（如 `direction`, `alignment`, `gap`, `padding`），放弃特定平台的高级或冷门布局特性。那些无法标准化的细节交给各平台环境。

---

## 04. Design Tokens 与视觉状态的不可变性

### 1. 规范正名
针对设计变量，引入规范的准确全称为：**`DTCG Design Tokens 2025.10 stable specification`**。
*   **注**：这是由 W3C Design Tokens Community Group (DTCG) 发布的，**官方明确声明它不是 W3C Standards Track specification**，但已成行业事实标准。

### 2. Token 的不可变性 (Immutability) 问题
AsWish Baseline 绝不允许静默变化。如果未来 Token 变了，历史 Baseline 必须锁定当时的状态。
*   **结论**：绝对不另建 Style Contract。
*   **方案**：利用现有 **`SpecSnapshot + Visual Binding`**。在 Visual Binding 中不仅要存储 Token 的引用名，更必须保存 `token bundle version / hash`，甚至直接在 Snapshot 时解析并冻结 `resolved token snapshot`，以保证未来 L3 比较的不可变基准。

---

## 05. Runtime Evidence：多源组合与 VCL 专属提取

### 1. 降低 UIA 的能力预期
UIA (UI Automation) 应被定位为 **“黑盒环境下的 external Evidence Adapter”**。
*   **擅长**：Control Tree 拓扑, role, Name, State, BoundingRectangle。
*   **不保证**：Font, Color, Border, Radius, 完整 Style 以及跨 Build 的绝对稳定 identity。

### 2. Delphi/VCL 专用 Runtime Extractor
针对 VCL 开发后 UI 的高保真证据采集，不能仅靠 UIA。应构建 VCL 专属的反射/结构提取探针：
*   直接在进程内存/钩子层级遍历 `TControl / TWinControl hierarchy`。
*   采集并精确提取：`Name`, `Parent`, `BoundsRect`, `Align`, `Anchors`, `Margins`, `Padding`, `Font`, `Color`, `Visible`, `Enabled`, `Caption/Text`。这能完美且无损地提供 L2/L3 所需的原生属性。

### 3. Web Evidence 的多源组合
不能盲目迷信单一的 Accessibility Tree。
*   **正确方案**：`DOM + layout geometry + CDP Computed Style + Accessibility semantics + Screenshot`。
*   **注**：Accessibility Tree 作为语义证据（Semantic Evidence），但不作为唯一事实树。此外，Chrome DevTools Protocol (CDP) 的 Accessibility Domain 目前部分接口仍为 Experimental，需引入降级策略。

---

## 06. 真正的 Build 任务：归一化与扩展

禁止重写或新建 Difference Engine。AsWish 现有的 4 层模型和 `0/1 通用比较` + `2/3 Platform Plugin` 设计依然适用。

本次为了打通“所见即所得”，我们真正需要自行 Build 的工程节点是：
**Runtime Evidence Normalization + Platform Adapter + Existing Difference Layer 2/3 extension**

技术流：
`Platform Runtime` → `Extractor` (UIA / CDP / VCL 专有探针) → `Normalized Comparable Evidence` (清洗成同构的 L2/L3 数据结构) → 投递入 `Existing Difference Engine`。

---

## 07. 最终回答 4 个核心工程问题

### A. 除 `layout` 外，View Spec 是否真的还需要增加字段？
**回答**：不需要。
View Spec 保持其纯净的结构化定义。样式的引用完全可以外移至 `Visual Binding` 中；运行时身份追踪直接复用现存的 `node.id`；渲染环境锁定依靠已有的 `renderer_version` 和 `SpecSnapshot` 机制。

### B. `style_refs` 应位于 node、Visual Binding 还是其他现有结构？给出最小侵入建议。
**回答**：应置于现有的 **`Visual Binding`** 层，并随 **`SpecSnapshot`** 被共同冻结。
最小侵入：不改动 `node` 结构本身，仅在 `Visual Binding` 中建立 `<node.id, DTCG token reference>` 映射关系，并在 Snapshot 时固化 Token 解析值或其 Hash，确保历史基线不可变。

### C. 怎样保证同一个 `node.id` 从 View Spec → Agent → Real UI → Runtime Evidence 一路不断链？
**回答**：通过**“Agent 强制注入协议 + Platform Adapter 逆向恢复”**。
1.  Agent 从 View Spec 获取 `node.id`，并在写代码时强制转换为特定平台的稳定语义特征（如 Web 的 `data-testid` 或 VCL 的 `TControl.Name`）。
2.  编译后，Real UI 中天然包含了这些注入的平台标识。
3.  Runtime Extractor (CDP / VCL Probe) 提取整棵树和附带标识。
4.  最终，`Platform Adapter` 在读取 Evidence 时，通过查表/映射逆向将 `data-testid` 或 `Name` 恢复为原始的 `node.id`。

### D. 怎样让 VCL 和 Web 分别产生与 Baseline 可比较的 Layer 2 / Layer 3 Evidence？
**回答**：通过**原生多源提取**和**归一化适配器**。
*   **Web**：调用 CDP 的 `DOM.getBoxModel` 和 `CSS.getComputedStyleForNode`，结合 DOM 树采集出绝对几何边界和计算后色值字体；
*   **VCL**：使用专门构建的 VCL Runtime Extractor (白盒/半白盒) 直接遍历 TControl 获取 `BoundsRect` (L2)、`Align/Anchors` (L2)、`Color` (L3) 和 `Font` (L3)；
*   以上两组截然不同的 Runtime Data，将在进入 AsWish Difference 层之前，被各自的 Platform Adapter **归一化 (Normalization)** 转换成 Baseline 所期待的数据格式。L2/L3 的 Plugin 基于这些纯净、同构的数据，执行比对算法并得出最终的差异结果。
