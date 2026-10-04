# AsWish 架构论证与纵切设计：High-Fidelity Visual Baseline · VCL Vertical Spike
> **任务定位**：架构论证 + 最小纵切立票设计 (R1 校准通过版)
> **日期**：2026-09-06

---

## 1. Existing Architecture Reuse Map (现有架构复用全景)

本 Spike 坚决不造新轮子，以下 AsWish 现有资产将被 100% 沿用并作为承载体：

*   **View Tree / View Spec**：继续作为骨架承载实体与层级，不对其做全局强制性纯粹化假设。
*   **node.id**：继续作为绝对的 Canonical Identity，贯穿设计到运行时，不建新 `stable_id`。
*   **SpecSnapshot + Visual Binding**：继续合体作为 `Accepted Visual Baseline`。
*   **renderer_version / 环境配置**：继续用于固化受控的 VCL Comparison Profile（复现环境）。
*   **Human Decision / OJP**：继续承担确认基线与裁断差异的职责。
*   **Implementation Evidence**：继续作为运行时数据回流的统一终点。
*   **Difference Engine**：继续沿用现存 0-3 层。本次通过 Platform Plugin 把标准化的 Observed 事实喂给现有的 Layer 2 和 Layer 3。

---

## 2. Minimal Architecture Delta (最小架构增量)

为补齐“高保真断层”，需要在现有架构上做如下**最小增量**：

1.  **View Spec `layout candidate` 实验性增量**：Spike 内实现实验性表达，不直接修改 canonical protocol schema。测试完成后，根据 Evidence 再提请 Protocol Change Proposal。
2.  **Visual Binding 增量**：增加 `node.id -> token ref` 的映射，并利用 `token bundle hash` 检测基线依赖的静默漂移，验证历史 Baseline 引用是否仍与确认时一致。
3.  **VCL Preview Renderer**：直接实例化真实的 VCL Form 展现给用户，确保开发前的预览源于真实 VCL 控件体系。
4.  **VCL Runtime Extractor**：基于 VCL 对象模型的观察探针。仅负责提供 Observation（如 `node.id`, `parent`, `bounds`, `size`, `position` 以及 `TColor/TFont`），不反推意图。
5.  **Identity Binding 规则**：建立 `node.id` 到 `deterministic valid VCL key` 的映射（如注入为 `TComponent.Name = AW_xxx`）。要求防碰撞、合法，并可通过 Existing Visual Binding 逆向反解回确切的 `node.id`，不引入第二 canonical identity。
6.  **Difference L2/L3 适配器**：
    *   **L2 适配**：从 Extractor 采集的观察值（Bounds, Position）计算出拓扑关系（left-of, above, observed gap），与 Baseline **已声明的 Constraint** 比较。严禁从结果反推原始布局意图。
    *   **L3 适配**：将 Runtime 的 `TColor/TFont` 或 Screenshot 与 Baseline 解析出的 **Expected Resolved Style** 直接比较。严禁从 Runtime 颜色反推 Semantic Token。

---

## 3. Vertical Spike Sequence (纵切实现流)

开发顺序绝对纵向击穿，只针对一个极小 Form（标题, 说明, Edit, 取消, 确认按钮）。

*   **S1. Identity Binding**：打通 `node.id ↔ AW_xxx (VCL Name)` 的合法映射与反解。
*   **S2. Experimental Layout**：在 Spike 内注入极简候选布局字段以支撑表单排版，暂不污染 Protocol。
*   **S3. VCL Preview**：将包含 S2 候选字段的 Spec 渲染为真实的 VCL 预览窗口。
*   **S4. Human Baseline**：固化 `SpecSnapshot + Visual Binding`。
*   **S5. Agent Handoff**：将 Baseline 传给 Agent，约束其使用合法的 VCL 身份绑定生成代码。
*   **S6. Runtime Extract**：编译运行 VCL 软件，采集 Observation（Bounds, Properties）及 Screenshot。
*   **S7. Difference L2 验证**：测试环境制造错位，验证引擎报出 Layer 2 Difference。
*   **S8. Difference L3 验证**：人为制造一个受控 Layer 3 配色差异，验证引擎报出 Layer 3 Difference。
*   **S9. Dogfood & Human Judgment**：在 OJP 展示 Screenshot + 结构化差异，人类判定差异是否可接受。

---

## 4. VCL Comparison Profile 记录清单

Before 与 After 需在冻结的 Profile 下具备可重复、同构的 Observable。Spike 将至少提取并裁剪以下核心环境记录：
*   `DPI` 与 `DPI awareness mode`
*   `PixelsPerInch`
*   `window/client size`
*   `VCL Style` (Theme)
*   `font` 与 `locale/text`
*   `control class` 与 `parent hierarchy`
*   `AutoSize` 与 `relevant runtime state`
*   `renderer version`

---

## 5. Risk / Unknown List (风险与未知清单)

*   **L3 双证据兜底**：`OwnerDraw` / `Custom Paint` / `VCL Styles` / `第三方控件` 可能造成结构化属性与最终 Render 不完全一致，因此需要 Structured Runtime Style Evidence + Screenshot 双证据补充。必须通过 `Structured Runtime Style Evidence + Screenshot` 双证据模式优雅降级。本 Spike 不要求 Pixel-perfect。
*   **动态环境漂移**：文字长度变化、系统字号强制接管可能触发 AutoSize 导致 Bounds 变动。差异计算（Difference）不代表实现错误（Error），最终靠 Human Judgment。

---

## 6. WO Proposal (工单立票)

已具备立票条件，分配正式工单：
**WO-20260906-0030-甲-High-Fidelity-Visual-Baseline-VCL-Vertical-Spike**
详细执行将在该工单内直接 Coding -> Dogfood -> Evidence Review。

---

## 7. 致老板的核心回答 (R1 校准)

### Q1：View Spec 本轮是否真的只需要新增 `layout`？
**回答**：对本次最小 VCL Spike，目前唯一已发现、且必须实证的 View Spec 协议候选增量是 `layout`；但 Spike 不能证明未来永远不需要其他增量。

### Q2：Style 是否可以全部留在现有 Visual Binding，而不污染 View Tree？
**回答**：本 Spike 优先将 Style / Token Binding 放入现有 Visual Binding，以保持 View Spec 的最小增量。这是本次 Spike 的架构假设，非永久协议原则，最终边界由 Spike 证据裁定。

### Q3：AsWish `node.id` 怎样最稳定地贯穿到 VCL Component？
**回答**：通过确定的合法映射规则，将 `node.id` 转译为合法的 Delphi 标识符（如 `AW_xxx`）赋予 `TComponent.Name`，同时在已有的 Visual Binding 层记录该映射，以便在 Runtime Extract 时无损且安全地反解回 `node.id`。

### Q4：开发前 VCL Preview 与开发后真实 VCL 软件，在哪些条件下可比较？
**回答**：当 Before 与 After 在冻结的 `VCL Comparison Profile`（包含相同的 DPI 模式、VCL Style、分辨率尺寸与控件渲染管线）下，便能产生可重复、足够同构的 Observable，进入 Difference 比较。

### Q5：本 Spike 如果成功，足以证明什么？
**回答**：Spike 成功可以证明 High-Fidelity Visual Baseline 在受控 VCL Profile 上具备工程可行性，并为 layout 正式协议化提供实证依据。这并非证明 AsWish 已普遍完成高保真验证，后续覆盖度推广属于演进步骤。
