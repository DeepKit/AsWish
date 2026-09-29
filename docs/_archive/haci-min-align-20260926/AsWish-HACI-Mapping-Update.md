# AsWish HACI 工程映射与最小优化规范 (AsWish-HACI-Mapping-Update)

> **SUPERSEDED 废止与历史归档声明 (2026-09-28)**：  
> 本文档引用之工单 `WO-HACI-MIN-ALIGN-001` 已不在册。  
> 其内容形成于 `HACI-MVP-PREDEV-REVISION-20260928` 冻结基线之前的旧讨论口径，仅作历史存档，不具备规范效力。  
> 现行工程映射与规范口径严格以 [`DeepBase/docs/EHAI-HACI-Implementation-Mapping.md`](file:///D:/_Progs/02Business/DeepBase/docs/EHAI-HACI-Implementation-Mapping.md) 为准。

---

> **任务编号**：`WO-HACI-MIN-ALIGN-001`  
> **文档性质**：HACI 最小原则工程映射规范（理论 $\rightarrow$ 工程映射校准，非架构重构）  
> **目标工程**：AsWish (`.AsWish/` 规范工作空间、CLI/GUI、Difference Engine)  
> **前置法源**：[`01.产品-AsWish产品身份与愿景蓝图.md`](01.产品-AsWish产品身份与愿景蓝图.md)、[`05.协议-AsWish协议基线.md`](05.协议-AsWish协议基线.md)  
> **面向受众**：AsWish 开发 AI 及维护团队  

---

## 一、最高原则与定位升级说明

### 1.1 最高原则：Human-AI Collaborative Intelligence (HACI)

本规范遵循人机协同智能最高公理：

```text
Human-AI Collaborative Intelligence (HACI)
=
Human主体 + AI能力扩展 + 共同认识 + 协同判断 + 现实反馈
```

工程不变量：
- **AI 不替代 Human**：AI 提供理解、提供候选、提供分析、提供执行辅助；
- **Human 保留主体地位**：Human 确定目标、选择方向、保留最终裁决权。

### 1.2 定位表述提升：从“需求契约系统”到“人机共同认识对象形成系统”

* **保持既有产品边界与工程现实**：
  AsWish 的现有工作空间结构（`.AsWish/`）、树状投影（`trees/`）、语义束（`bundles/`）、意图与变更集（`llm/`）、裁决记录（`decisions/`）以及快照基准（`snapshots/`）均保持 100% 稳定，不推翻、不重构。
* **补充认识论解释**：
  AsWish 在 HACI 闭环中不仅是“记录软件需求的机器可读契约”，更本质的是**“人机共同认识对象形成系统（Object Formation System）”**。
  - 在 AI 介入开发之前，Human 与 AI 必须对“讨论的目标对象到底是什么、边界在哪里”达成结构化的共同认识；
  - 这种共同认识不是虚无的提示词，而是落盘为可比对、可追溯、可审计的客观工程对象。

---

## 二、总体闭环在 AsWish 的贯通检查

检查 AsWish 是否完整承载 HACI 总体闭环：

```text
Human Intent (TCandidateIntent)
     ↓
Object Formation (共同认识对象形成：Object Context + Canonical Spec Trees)
     ↓
AI Candidate (TChangeSet / 推荐候选 1–7)
     ↓
Human Choice (TSpecDecision: Accept / Reject / Clarify / Override)
     ↓
Action (Downstream Coding Agents 实施开发)
     ↓
Evidence (Implementation Evidence: 真实代码独立提取)
     ↓
Difference (Difference Engine: 结构差异比对)
     ↓
Difference Impact (属集影响分析与禁元触碰判定)
     ↓
Experience (Snapshot Baseline / 形成演进经验)
```

**检查结论**：AsWish 原生具备该闭环的主干骨架，但在“认识对象上下文”与“差异业务影响（Difference Impact）”维度存在语义粒度偏弱的情况，需进行最小补充。

---

## 三、新增最小章节：Object Context（认识对象上下文）

在 AsWish 需求/意图流转与语义节点表达中，补充 **`Object Context`** 最小上下文元数据（可作为 `x_object_context` 扩展或节点注解，禁止破坏既有 Schema 必填约束）。

### 3.1 认识对象五大核心要素

每个被审阅或形成中的规格对象，必须能够回答以下五个核心问题：

1. **对象 (Object)**：当前人机讨论的核心实体到底是什么？
   - *示例*：订单结算按钮、联系人标签索引、差异报告渲染器。
2. **主体 (Subject)**：谁在关注并对此对象负责？
   - *示例*：末端业务操作员、安全审计员、架构主控。
3. **目标 (Objective)**：希望该对象发生什么改变？
   - *示例*：降低高频点击摩擦、消除跨平台渲染失真、收敛依赖。
4. **关键属集 (Essential Property Set)**：哪些属性和关联关系构成该对象的本质，不容失真？
   - *示例*：响应延迟 $\le 50\text{ms}$、颜色与品牌色系绑定、不可逆操作的二次确认防线。
5. **边界 (Boundary)**：哪些是不允许改变的禁元或硬性不变量？
   - *示例*：不得破坏既有 `0–9` 键位语义、不得引入未授权外部依赖、不得绕过本地证据存盘。

### 3.2 工程落地约束（针对 AsWish 开发 AI）

- 在 `llm/candidate-intent.yaml` 或 `bundles/semantic-bundles.yaml` 中，支持通过轻量字典或注记解析包含上述 5 个字段的上下文；
- **非侵入原则**：若历史意图未显式提供全量 5 要素，系统以默认缺省值容错（Fail-soft），绝不因字段缺失导致解析崩溃或阻断工作流。

---

## 四、Difference 增强：从“差异发现”升级为“差异影响（Difference Impact）”

### 4.1 现有能力基线
当前 AsWish 的 Difference Service（`AsWish.Services.Difference.pas`）能够准确比对 Accepted Baseline 与 Implementation Evidence，输出：
- 节点增删（Missing / Extra）；
- 属性变化（Changed）；
- 关系漂移（Relation Difference）。

### 4.2 补充扩展：Difference Impact（差异影响度与属集关联）

单纯的“发现差异”只是物理层的观测（*“代码与基线第 42 行颜色值不同”*）。HACI 要求系统向 Human 显影**该差异对属集、目标与边界的深层影响**：

$$\text{Difference} \xrightarrow{\text{关联分析}} \text{Difference Impact} (\text{属集影响} + \text{目标偏离度} + \text{禁元触碰判定})$$

#### 核心三问：
1. **差异影响哪个属集？**
   - *不是*：颜色代码从 `#1E1E1E` 变为 `#FFFFFF`；
   - *而是*：该差异直接影响【深色主题视觉一致性】与【夜间操作对比度】属集。
2. **是否偏离既定目标？**
   - 评估本次代码变动是在促进 Objective 达成，还是引入了意外的技术债务或侧面损伤。
3. **是否触碰禁元（Boundary Invariant Violation）？**
   - 检查差异是否打破了系统不变量（例如：静默删除了回退逻辑、将单次确认变成了无人值守自动提交）。触碰禁元的差异必须被标注为高危阻断（Blocking Alert）。

### 4.3 产物呈现指引
在 `.AsWish/difference.yaml` 或生成的 Review HTML 界面中，允许增设可选注记：

```yaml
impact:
  affected_property_set: "Brand Consistency & Contrast"
  objective_alignment: "Neutral / Drift"
  touches_forbidden_boundary: false
  rationale: "Button background hex drifted from design token; affects readability."
```

---

## 五、交付 AsWish 开发 AI 的自查与最小优化清单

开发 AI 在承接 AsWish 的最小优化时，必须先完成以下自查并输出方案：

### 5.1 开发 AI 必填自查表（前置门禁）
- [ ] **现状审查**：检查 `AsWish.Services.Difference.pas` 与 `AsWish.Models.pas` 中当前对 Intent 与 Difference 的数据结构定义；
- [ ] **差距分析**：确认当前是否有现成槽位承载 `Object Context` 5 要素与 `Difference Impact` 3 要素；
- [ ] **最小修改方案**：
  - 首选采用现有 `x_` 扩展字段或在 ChangeSet / Difference record 中增加可选描述字段；
  - **严禁改动已有核心文件的必填校验**，确保旧测试集 100% 保持绿色；
- [ ] **风险评估**：确认不引起 full rescan diff 爆炸，不修改已冻结协议文件名。

### 5.2 验收合格标志 (Acceptance Criteria)
1. **AC-AW-01**：在不破坏现有 `.AsWish/` 规格工作空间格式的前提下，成功支持声明与读取 `Object Context`；
2. **AC-AW-02**：Difference 报告或注记中可清晰表达“影响哪个属集”、“是否影响目标”、“是否触碰禁元”；
3. **AC-AW-03**：现有 AsWish 全部单元测试与回归测试全绿通过，无架构分叉。
