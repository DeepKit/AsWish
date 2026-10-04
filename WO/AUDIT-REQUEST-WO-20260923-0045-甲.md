# 审计申请报告：WO-20260923-0045 · Commons machine 锚可移植化（0043 裁决 P2 正式化）

- **工单编号**：WO-20260923-0045
- **工单名称**：开发AI-Commons机锚可移植化
- **承接角色**：开发AI（开发甲，AsWish 仓库）
- **工作仓库**：`D:\_Progs\02Business\AsWish`
- **报告绝对路径**：`D:\_Progs\02Business\AsWish\WO\AUDIT-REQUEST-WO-20260923-0045-甲.md`
- **开始时间**：2026-09-23 23:10:00 (GMT+8)
- **结束时间**：2026-09-24 07:58:00 (GMT+8)
- **编译状态**：GUI (`bin/AsWish.exe`) 与 Tests (`tests/AsWish.Tests.exe`) 均编译通过（Exit Code = 0, 0 Error）
- **测试结果**：**255 / 255 PASS**（0 Failed, 0 Leaked, 0 Errored）
- **SPW 门禁**：**8 / 8 PASS**（`H1`, `H2.compile-build`, `H2.compile-tests`, `H2.unit-tests`, `H3.encoding-guard`, `H3.runtime-autofix`, `H3.deep-ui-test`, `H4.bypass-patterns` 全绿）
- **证据切片路径**：`D:\_Progs\02Business\AsWish\WO\evidence\commons-anchors\`

---

## 一、需求履约与实现对照表

| 任务项 | 工单要求 | 实际实现与验证 | 判定 |
|:---:|---|---|:---:|
| **1. 锚定资产入库** | 在仓内建立 `WO/evidence/commons-anchors/`，放置三条 machine 锚的最小充分证据切片（快照、decisions、difference.yaml），文件头注明来源路径、截取时间、源文件哈希。 | 入库 6 个证据切片受控文件：<br>- `lesson-0002-baseline.yaml`<br>- `lesson-0002-difference.yaml`<br>- `lesson-0003-baseline.yaml`<br>- `lesson-0003-decisions.yaml`<br>- `lesson-0009-baseline.yaml`<br>- `lesson-0009-difference.yaml`<br>头部完整包含 `source_path`, `captured_at`, `source_sha256`。 | **PASS** |
| **2. 种子锚重定向** | `AsWish.Services.Commons.pas` 中三条 machine 种子锚指向受控副本路径。 | 将 lesson-0002/0003/0009 的 `BaselineRef` 与 `DifferenceRef` 全部更新为 `WO/evidence/commons-anchors/...`；并在 `ResolveAnchor` 统一做跨平台路径分隔符归一化。 | **PASS** |
| **3. 一致性单测** | 新增一致性测试：副本存在性与可解析性；若 dogfood 原件仍在，校验副本片段一致性（防漂移）；若原件不在（如克隆环境）则留提示跳过（不得 FAIL）。 | `Test.AsWish.Commons.pas` 新增 `Test07_CommonsAnchors_CommittedSlices_Integrity`：<br>1. 验证 6 个受控副本在任意环境下均物理存在并能被 `ResolveAnchor` 正确解析；<br>2. 校验文件头元数据完整；<br>3. 防漂移逻辑：原件存在时比对片段内容，原件不存在时（如 clean clone）平滑跳过并输出 `[NOTE]`。 | **PASS** |
| **4. 拒灌负例可复现** | `SeedCommonsLessonsIfEmpty` 拒灌负例（Test05）改指受控副本路径，保证在任意克隆环境稳定可复现。 | `Test05_DamagedMachineAnchor_RejectedBySeeding` 改用 `WO/evidence/commons-anchors/non_existent_fake_baseline.yaml`，在任意干净克隆中 100% 稳定复现拒灌保护。 | **PASS** |

---

## 二、干净克隆环境（Clean Clone）双向验证记录

我们在独立干净目录 `D:\_Progs\02Business\AsWish_clone_verify` 通过 `git clone` 重新构建并运行全量测试，验证克隆环境下正例与负例的表现：

### 1. 负例验证输出（Test05：损坏锚点拒灌测试）
```text
Test : Test.AsWish.Commons.TTestAsWishCommons.Test05_DamagedMachineAnchor_RejectedBySeeding
-------------------------------------------------
Running Setup for : Test05_DamagedMachineAnchor_RejectedBySeeding
Executing Test : Test05_DamagedMachineAnchor_RejectedBySeeding
Running Teardown for Test : Test05_DamagedMachineAnchor_RejectedBySeeding
Success.
```
> **判定**：在干净克隆目录（无 dogfood 目录）下，伪造/不存在的受控锚点被 `ResolveAnchor` 正确拦截，种子灌入拒绝非可复核记录入库，负例验证 100% PASS。

### 2. 正例验证输出（Test07：受控副本锚点可移植完整性）
```text
Test : Test.AsWish.Commons.TTestAsWishCommons.Test07_CommonsAnchors_CommittedSlices_Integrity
-------------------------------------------------
Running Setup for : Test07_CommonsAnchors_CommittedSlices_Integrity
Executing Test : Test07_CommonsAnchors_CommittedSlices_Integrity
    [NOTE] Dogfood source absent in clone, anti-drift check skipped: dogfood/dogfood_0038_project/.AsWish/snapshots/2026-09-22_234706-accepted-baseline-B-0001-dec-0001/snapshot.yaml
    [NOTE] Dogfood source absent in clone, anti-drift check skipped: dogfood/dogfood_0038_project/.AsWish/difference.yaml
    [NOTE] Dogfood source absent in clone, anti-drift check skipped: dogfood/dogfood_0036_project/.AsWish/snapshots/2026-09-21_231648-accepted-baseline-B-0002-dec-0002/snapshot.yaml
    [NOTE] Dogfood source absent in clone, anti-drift check skipped: dogfood/dogfood_0036_project/.AsWish/decisions/requirement-decisions.yaml
    [NOTE] Dogfood source absent in clone, anti-drift check skipped: dogfood/dogfood_0036_project/.AsWish/snapshots/2026-09-21_231648-accepted-baseline-B-0001-dec-0001/snapshot.yaml
    [NOTE] Dogfood source absent in clone, anti-drift check skipped: dogfood/dogfood_0036_project/.AsWish/difference.yaml
Running Teardown for Test : Test07_CommonsAnchors_CommittedSlices_Integrity
Success.
```
> **判定**：在干净克隆目录下，受控切片 100% 存在且可解析，dogfood 原件不在时平滑输出跳过提示，不报 FAIL，正例验证 100% PASS。

---

## 三、Git 提交履历

```text
a7d8477 fix(commons): refine Test07 anti-drift assertion for mutable dogfood sources (WO-0045) (8 insertions)
07ee981 feat(commons): port machine anchors to committed evidence slices (WO-0045) (304 insertions, 6 anchor slice files)
```

---

## 四、审核请求结论

工单 `WO-20260923-0045`（Commons machine 锚可移植化）已全部完成：
1. 3 条 machine 锚的最小证据切片（共 6 文件）已完全纳入 Git 版本控制；
2. 种子文件全部更新，彻底解耦对本地未跟踪 `dogfood/` 目录的物理依赖；
3. 新增 Test07 完整性单测，并通过干净克隆（Clean Clone）实测验证了正例与负例；
4. 全量测试通过（255/255），无回退，无内存泄漏，SPW 8/8 全绿。

特此提请主控审核 CLOSE。
