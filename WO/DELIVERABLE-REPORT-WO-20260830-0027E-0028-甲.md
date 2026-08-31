# AsWish 联合工程交付与请求审核报告

- **工单编号**：`WO-20260830-0027E` & `WO-20260830-0028`
- **承接仓库**：`D:\_Progs\02Business\AsWish`
- **执行角色**：开发甲
- **工单性质**：P0 核心基线与视觉规格工程实施
- **交付状态**：ALL PASS - READY FOR CODE REVIEW & ACCEPTANCE
- **完成时间**：2026-08-31 12:20:00 (UTC+8)

---

## 一、交付总览与执行摘要

本轮开发严格贯彻《连续执行纪律》与《非睿智轻量门禁规范》，由**开发甲**独立认领并一次性闭环完成 **WO-20260830-0027E（Accepted Baseline v0）** 与 **WO-20260830-0028（建立开发视觉规格基线）** 两项核心工单。

### 核心达成成果：
1. **Accepted Baseline v0 落地（WO-0027E）**：
   - 在 `I said → AI understood → We decided → Canonical Spec` 的现有决策链路中，当 Human 批准（Accept）变更时，自动计算快照级 `ContentHash` 与 `RelationHash`，并原子冻结生成不可变的 `Accepted Baseline`（编号格式 `B-0001`）。
   - 实现 **ContentHash 与 RelationHash 严格分离**：
     - 修改节点 `summary` 等业务字段：只改变 `ContentHash`，`RelationHash` 保持不变；
     - 修改节点 `parent_id` 等拓扑关系：只改变 `RelationHash`，`ContentHash` 保持不变。
   - 完整谱系回溯（`Lineage`: `ChangeSetId` + `IntentId`）。
   - 完全复用现有 `TAsWishSnapshotService` + `.AsWish/snapshots/<name>/snapshot.yaml`，未引入任何平行冗余实体；
   - 具备 Fail-closed 门禁机制：空快照/非法快照严禁晋升为 Accepted Baseline。
2. **开发视觉规格基线落地（WO-0028）**：
   - 确立“视觉基线不是截图，而是 View Spec 的确定性规格表达”；
   - 基于 `view-tree.yaml` 确定性渲染结构线框图（`Page -> Section -> Component -> Hierarchy`），生成包含 0–9 交互标准与语义色 Token 的 `visual-preview.html`（Renderer: `wireframe-v1.0`）；
   - 实现 `ConfirmVisualBaseline`，通过现有 `Decisions`（`dtConfirm`）与 `SnapshotService` 将视觉规格冻结为 Accepted Visual Baseline；
   - 扩展 `TBaselineContextSource`，支持将 Accepted Visual Baseline 导出至 AI Context Pack（AC-12）。
3. **全量测试与真实 Dogfood 全通**：
   - DUnitX 测试套件：**172 / 172 测试全部通过**（0 Failed, 0 Errored, 0 Leaked），包含 WO-0027E 要求的 11 项专用测试与 WO-0028 视觉基线专用测试；
   - 桌面 GUI 与 CLI 无警告/无错误编译通过；
   - CLI 真实工程 Dogfood 9 步闭环实测 100% 成功，所有原始日志与编译证据均已归档于 `WO/evidence/`。

---

## 二、WO-20260830-0027E 验收对照表（Accepted Baseline v0）

| 序号 | 需求与验收项 | 实现机制与代码位置 | 验证结果 |
| :--- | :--- | :--- | :--- |
| 1 | **基于已有快照体系** | 复用 `TAsWishSnapshotService`，在 `.AsWish/snapshots/<name>/snapshot.yaml` 扩展 `baseline:` 区块，无平行机制 | **PASS** |
| 2 | **ContentHash 包含 summary** | `TSpecHash.NodeContentHash` 显式哈希 `summary`，`SnapshotContentHash` 聚合排序节点 | **PASS** |
| 3 | **哈希分离：Summary 修改** | `Test06_ChangeSummary_OnlyContentHashChanges` 单元测试通过 | **PASS** |
| 4 | **哈希分离：ParentId 修改** | `Test07_ChangeParentId_OnlyRelationHashChanges` 单元测试通过 | **PASS** |
| 5 | **不可变性（Immutable）** | 历史基线只读；后续修改 live spec 不影响已固化的 snapshot.yaml 与 tree 文件（`Test09` 通过） | **PASS** |
| 6 | **Lineage 谱系记录** | `TBaselineLineage` 记录 `ChangeSetId` 与 `IntentId`，链条闭环可查（`Test10` 通过） | **PASS** |
| 7 | **Fail-closed 保护** | 0 节点快照抛出异常，阻止生成 Accepted Baseline（`Test11` 通过） | **PASS** |
| 8 | **11 项 DUnitX 最小测试清单** | 编写 `tests/Test.AsWish.Baseline.pas`，全部 11 项独立用例 100% PASS | **PASS** |

---

## 三、WO-20260830-0028 验收对照表（视觉规格基线）

| 验收项编号 | 验收项内容 | 实现位置与测试用例 | 验证结果 |
| :--- | :--- | :--- | :--- |
| **AC-01** | Wireframe/结构预览：从 View Spec 确定性生成线框 | `AsWish.Services.Render.pas` `RenderVisualPreview` | **PASS** |
| **AC-02** | 包含渲染器版本信息（如 `wireframe-v1.0`） | 写入 `snapshot.yaml` `renderer_version` 并在 HTML 头部展示 | **PASS** |
| **AC-03** | 视觉预览由 View Spec 驱动，无额外手写 layout 状态 | 直接从 `view-tree.yaml` 派生，单一真相源（SSOT） | **PASS** |
| **AC-04** | 结构表现：Page -> Section -> Component 层次可见 | CSS 类 `.wf-page`, `.wf-section`, `.wf-component` | **PASS** |
| **AC-05** | 非 UI 字段不干扰线框图渲染 | 线框图只使用 View Spec 的 title/kind/parent/summary | **PASS** |
| **AC-06** | 视觉基线实体基于 `SpecSnapshot` 扩展 | `TAsWishBaseline.RendererVersion` + `VisualBinding` | **PASS** |
| **AC-07** | 包含 `visual_binding` 字段指向预览产物 | 写入 `snapshot.yaml` `visual_binding: html/visual-preview.html` | **PASS** |
| **AC-08** | 确定性生成（同 Spec + 同 Renderer -> 同哈希产物） | `Test01_VisualPreview_DeterministicRendering` 验证通过 | **PASS** |
| **AC-09** | 视觉基线不可变性 | 历史快照独立隔离，后续 View Spec 变更不污染历史基线 | **PASS** |
| **AC-10** | 视觉基线与 Decision 关联 | 由 `ConfirmVisualBaseline` 生成 `dtConfirm` Decision 并关联 | **PASS** |
| **AC-11** | Human-in-the-loop：人类有确认/修改/回退权 | 提供 `[1] Confirm`, `[9] Propose Revision`, `[0] Back` 0–9 选项 | **PASS** |
| **AC-12** | 可经 context-pack / semantic-bundles 导出 | `AsWish.Services.Context.pas` `TBaselineContextSource` 导出 | **PASS** |
| **AC-13** | 单元测试覆盖 | `tests/Test.AsWish.VisualBaseline.pas` 6 大测试全部通过 | **PASS** |
| **AC-14** | 遵循既有架构约束 | 无新建平行表/无孤立实体/强类型 record | **PASS** |
| **AC-15** | 概念隔离：Screenshot vs Visual Preview 明确区分 | 文档与代码注释明确声明“Preview=规格表达，Screenshot=实现证据” | **PASS** |

---

## 四、测试证据与实测台账

### 1. DUnitX 单元测试全量输出
- **运行命令**：`tests\AsWish.Tests.exe`
- **证据文件路径**：`D:\_Progs\02Business\AsWish\WO\evidence\test-run-20260831-0027E-0028-甲.txt`
- **测试统计**：
  - Tests Found: **172**
  - Tests Passed: **172**
  - Tests Failed: **0**
  - Tests Errored: **0**
  - Tests Leaked: **0**

### 2. 编译与构建证据
- **证据文件路径**：`D:\_Progs\02Business\AsWish\WO\evidence\build-apps-20260831-0027E-0028-甲.txt`
- **构建结果**：
  - `AsWish.Tests.exe`: PASS (0 Errors, 0 Warnings)
  - `AsWish.CLI.exe`: PASS (0 Errors, 0 Warnings)
  - `AsWish.exe` (GUI): PASS (0 Errors, 0 Warnings)

### 3. CLI 端到端 Dogfood 实测证据
- **证据文件路径**：`D:\_Progs\02Business\AsWish\WO\evidence\dogfood-run-20260831-0027E-0028-甲.txt`
- **实测完整链条记录**：
  1. `scan`: 扫描生成 4 棵 Spec 树；
  2. `changeset`: 提交自然语言意图，生成候选变更集 `cs-func-001-01`；
  3. `changeset accept`: 人类批准变更，写入决策 `dec-0001`，写回规范并**自动冻结 Accepted Baseline `B-0001`**；
  4. `baseline list`: 列出已固化基线 `B-0001`；
  5. `baseline verify B-0001`: **PASS**，内容与拓扑双哈希严格匹配；
  6. `visual preview`: 确定性生成视觉规格线框图 `visual-preview.html`；
  7. `visual confirm`: 确认视觉表现，写入决策 `dec-0002`，**自动冻结 Accepted Visual Baseline `B-0002`**（带 `wireframe-v1.0` 与 `visual_binding`）；
  8. `baseline list`: 列出功能基线 `B-0001` 与视觉基线 `B-0002`；
  9. `baseline verify B-0002`: **PASS**，视觉基线完整性校验通过。

---

## 五、代码与文件变更清单

```text
src/
├── models/
│   └── AsWish.Models.pas            # 新增 TBaselineLineage, TAsWishBaseline
├── core/
│   └── AsWish.Hash.pas              # Node/Snapshot ContentHash 与 RelationHash 分离与确定性计算
├── services/
│   ├── AsWish.Services.SpecStore.pas# 新增 InitializeDirect 支持快照隔离读取
│   ├── AsWish.Services.Snapshot.pas # 扩展 CreateBaseline, LoadBaseline, VerifyBaseline, ListBaselines
│   ├── AsWish.Services.Render.pas   # 实现 RenderVisualPreview (Wireframe 结构线框图) 与索引入口
│   └── AsWish.Services.Context.pas  # 新增 TBaselineContextSource 支持视觉基线上下文包导出
├── controllers/
│   └── AsWish.Controller.pas        # 接入 Baseline 冻结/查询/校验与 ConfirmVisualBaseline
├── providers/
│   └── AsWish.Providers.MainView.pas# 接入 visual-confirm WebView2 JS Bridge 动作
├── app/
│   ├── AsWish.Providers.pas         # 绑定 Controller.ConfirmVisualBaseline 回调
│   └── AsWish.Commands.pas          # 注册 aswish.baseline.list/verify, aswish.visual.preview/confirm
cli/
└── AsWish.CLI.dpr                   # 接入 baseline list/verify 与 visual preview/confirm 子命令
tests/
├── Test.AsWish.Baseline.pas         # WO-0027E 规定的 11 项 DUnitX 最小单元测试
├── Test.AsWish.VisualBaseline.pas   # WO-0028 规定的视觉基线 6 项 DUnitX 单元测试
└── AsWish.Tests.dpr                 # 注册 Baseline 与 VisualBaseline 测试夹具
WO/
└── evidence/
    ├── test-run-20260831-0027E-0028-甲.txt
    ├── build-apps-20260831-0027E-0028-甲.txt
    └── dogfood-run-20260831-0027E-0028-甲.txt
```

---

## 六、请求审核确认

本工单涉及之所有功能与测试已按《非睿智轻量门禁规范-v1》完成交付。

- [x] G1 目标/范围/验收指标对齐
- [x] G2 原始构建/测试日志归档 (`WO/evidence/`)
- [x] G3 172/172 单元测试全数 PASS
- [x] G4 真实环境 Dogfood 闭环验证 PASS
- [x] G5 无未清技术债，架构无分叉

**开发人员**：开发甲  
**请求审核状态**：REQUEST FOR AUDIT & CLOSE  
