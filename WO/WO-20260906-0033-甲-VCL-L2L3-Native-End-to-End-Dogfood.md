# WO-20260906-0033-甲 VCL L2/L3 Native End-to-End Dogfood

- 工单编号: WO-20260906-0033-甲
- 状态: DONE
- 依赖: WO-0031 ✅, WO-0032 ✅
- 承接角色: 甲（开发AI）

---

## 一、目标

验证 AsWish 自身能否**原生承载** WO-0030 已证明可行的 VCL L2/L3 比较链，且**完全不依赖 SpikeAdapter**。

最终必须产生**真实 Dogfood Evidence**，证明：

```text
正式 Baseline
→ 正式 Handoff
→ VCL Implementation
→ Implementation Evidence
→ VCL Comparator
→ Existing Difference
→ Observable
→ Human Judgment
```

在真实 VCL 应用（如 Dogfood 项目）中完整跑通一次闭环。

---

## 二、范围与禁止项

**必须做**：

1. 选取一个真实的 VCL 项目（可以是 `batch_dogfood/proj_calc_tool` 或同类）作为 Dogfood 靶标。
2. 使用正式 `AsWish.CLI.exe` 或 GUI 执行完整流程：
   - `init` → `scan` → `intent` → `ingest` → `changeset accept` → `baseline create`
   - 生成 VCL Implementation Evidence（真实 VCL 源码改动）
   - `difference` → 确认 L2/L3 差异项由 `AsWish.Plugins.VCL.Difference.pas` 产生
   - `judge`（接受/拒绝）→ `evolve` → 新基线
3. 全过程不得使用或引用任何 `SpikeAdapter` 代码。
4. 留存：
   - 完整操作日志（CLI 或 GUI 原始输出）
   - 现场 `.AsWish/` 目录（含 `difference.yaml`、`decisions.yaml`、`snapshots/`）
   - 编译日志与测试结果
   - 最终 `baseline verify` 通过

**禁止做**：

- 修改 `AsWish.Services.Difference.pas` 核心逻辑
- 引入新的 Difference Engine 或平行差异模型
- 在 Dogfood 过程中手动修补差异输出
- 跳过任何步骤或伪造证据

---

## 三、验收标准（硬性）与达成情况

| # | 标准 | 验证方式 | 达成状态 | 实测事实 |
|---|------|----------|----------|----------|
| 1 | 靶标 VCL 项目在 Dogfood 前 clean，无残留 `.AsWish/` | 现场目录截图/日志 | ✅ PASS | `dogfood_vcl_native` 初始化前检查 `.AsWish/` 不存在，完全 clean |
| 2 | 初始基线建立成功（B‑0001） | `baseline verify B-0001` PASS | ✅ PASS | `[baseline verify] PASS: B-0001 integrity verified` |
| 3 | VCL Implementation Evidence 被 `evidence collect` 正确捕获 | 证据文件在盘 | ✅ PASS | 生成 `dogfood_vcl_native\.AsWish\evidence\implementation-evidence.yaml`，收集 2 项证据 |
| 4 | `difference` 输出 L2/L3 差异项（至少各 1 项）由正式 VCL Comparator 产生 | `difference.yaml` 中 `kind` 包含 `daRelation` 和 `daContent`（L3 临时映射） | ✅ PASS | 输出 2 项差异：`node_btn_confirm` (`daRelation`, L2 layout) 与 `node_title` (`daContent`, L3 appearance) |
| 5 | Human Judgment 通过 `judge` 执行（拒绝/接受任一）并记录决策 | `decisions.yaml` 新增 `dec-000X` | ✅ PASS | `requirement-decisions.yaml` 记录决策 `dec-0002` (acceptable) |
| 6 | `evolve` 生成新基线 B‑0002，`parent_baseline_id` 正确指向 B‑0001 | `snapshot.yaml` 验证 | ✅ PASS | `snapshot.yaml` 中 `parent_baseline_id: "B-0001"` 正确留存 |
| 7 | 全量测试 220/220 PASS（不影响已有通过项） | 回归测试输出 | ✅ PASS | DUnitX 测试 220/220 全部通过，0 fail，0 leak |
| 8 | 最终 `baseline verify B-0002` PASS | 命令输出 | ✅ PASS | `[baseline verify] PASS: B-0002 integrity verified` |
| 9 | **零 SpikeAdapter 引用**（`grep -r SpikeAdapter src/` 为空） | 代码扫描 | ✅ PASS | 全工程 `src/`、`cli/`、`tests/` 搜索 `SpikeAdapter` 结果为 0 |
| 10 | 证据包完整，无手工修补 | 主控复核 | ✅ PASS | 全链路命令由 CLI/编译器直接产出，日志留痕于 `WO/evidence/dogfood-0033-甲.log` |

---

## 四、交付物清单

1. **Dogfood 现场目录**：`dogfood_vcl_native/`（或指定路径），包含完整 `.AsWish/`
2. **操作日志**：`WO/evidence/dogfood-0033-甲.log`
3. **编译与测试日志**：`WO/evidence/build-0033-甲.txt`、`WO/evidence/tests-0033-甲.txt`
4. **关键截图**（可选但推荐）：`WO/evidence/screenshots/0033/`
5. **Git 提交**：本工单相关的 commit 须 ≤200 行，message 前缀 `feat(dogfood)` 或 `test(dogfood)`
6. **工单状态更新**：`WO/WO-20260906-0033-甲-VCL-L2L3-Native-End-to-End-Dogfood.md` 标记为 DONE

---

## 五、纪律提醒

- 本工单为 **0033**，在未收到主控明确 **PASS** 裁定前，**不得启动 Evidence Review 或 Layout Protocol Change Proposal**。
- 禁止越界修改协议。
- 所有证据必须真实、可复核。

---

## 六、执行与交付记录

- 状态: **DONE**（全流程已于 `dogfood_vcl_native` 真实闭环，10 项 AC 均通过）
- 操作日志: `WO/evidence/dogfood-0033-甲.log`
- 编译日志: `WO/evidence/build-0033-甲.txt`（GUI/CLI/Tests 均 0 error）
- 测试日志: `WO/evidence/tests-0033-甲.txt`（220/220 PASS, 0 fail, 0 leak）
- 代码洁净度: 全仓无 `SpikeAdapter` 引用
- 交付物已就绪，等待主控复核。

---

*工单创建时间: 2026-09-06*
*工单完成时间: 2026-09-07*
*版本: v1.1 (CLOSED)*