# WO-20260914-EHAI-BINDING-001R2-甲 · AsWish · R2 微校准工单

> **工单编号**：WO-20260914-EHAI-BINDING-001R2
> **上游工单**：WO-20260914-EHAI-BINDING-001R1（整改）
> **承接角色**：开发甲（AsWish 仓）
> **工程主仓**：`D:\_Progs\02Business\AsWish`
> **上游裁定**：`D:\_Progs\02Business\DeepBase\CodeReview\20260914-EHAI-R1三工单复核评价.md`
> **本仓状态**：`START / CONTINUE`
> **本工单只有一项任务**：`B-1 构建证据微校准`（`NON-BLOCKING`）

---

## 0. 裁定摘要

```text
R1 六项整改（AW-R01 ~ AW-R06）+ 12 条验收：全部 PASS（独立复核确认）

唯一瑕疵：
  B-1  构建证据能够证明「0 Error」，但不能证明「0 Warning」

本仓开发状态：
  START / CONTINUE —— 已解锁，可正式继续 Reference Product Binding 001
```

**复核确认的可信项**（无需返工，列出以便对齐）：

```text
✓ 三个提交 f8d46af / 7db33ce / d5fce9b 真实存在且范围干净（零跨仓路径）
✓ 233/233 通过，ASWISH_V_001 ~ ASWISH_V_009 九个用例名全部可检索
✓ Profile 漂移已对齐：168 eipJudge / 170 eipProvide / 173 eipProvide / 175 eipInform
✓ 符号基准登记的两个源文件 SHA256 与 DeepBase 基准逐字符一致
  （de9a3208... / 963fedd0...）—— 跨仓交叉校验成立
✓ 遗留项台账 L-01 ~ L-05 实名登记且标注终审编号，可追溯
```

---

## 1. B-1｜构建证据微校准【本工单唯一任务】

### 1.1 问题

`WO\evidence\build-ehai-binding-001R1.txt` 内容为：

```text
=== 1. GUI Application (AsWish.dpr) ===
Embarcadero Delphi for Win64 compiler version 37.0
21036 lines, 2.75 seconds, 6797632 bytes code, 685064 bytes data.
Exit Code: 0
（CLI / Tests 同构）
```

该证据能证明：

```text
Exit Code = 0
Build succeeded
0 Error
```

**不能**证明：

```text
0 Warning      ← 文件中没有任何 warning 计数或编译器告警行
```

> 对照事实：同一轮 DeepBase 的构建日志实测含 **144 条 Warning**。因此"编译器输出里没有告警行"本身不是常态，需要计数才能成立。

### 1.2 处置（二选一）

**方案 A（推荐）**：改措辞，删除未经证据支持的表述。

报告与证据文件中统一改为：

```text
Build succeeded / Exit Code 0 / 0 Error
```

**删除** `0 Warning` 之类的声明。

**方案 B**：重新生成包含**明确 warning count** 的构建证据（在证据文件中显式打印 `Warning Count: N`，并保留告警明细行）。

### 1.3 约束

```text
✗ 不得因本项重新开发 AsWish
✗ 不得改动任何业务代码
✗ 不得重跑或重建测试套件（233/233 已复核通过，无需重跑）
✓ 只动证据文件与报告中的相应措辞/计数行
```

**本项 `NON-BLOCKING`**——不阻塞本仓开发，也不阻塞本仓其他验收。

---

## 2. 下游开发纪律｜共享能力缺口

现在允许正式继续编码。但若发现 DeepBase 公共能力缺失：

```text
✗ 不得直接修改 DeepBase
✓ 只能提交「Shared Capability Gap」
```

该提交至少说明五点：

```text
1. 产品需要什么
2. 当前公共接口缺什么
3. 为什么不能在 Product Binding 内解决
4. 为什么认为它具有跨产品公共意义
5. 对 Common Contract 是否有影响
```

然后由主控裁定。

---

## 3. 收口时序（重要）

```text
本仓开发：            START / CONTINUE（即刻可继续，无需等待）

本仓最终 Gate C / L7 Conformance closure：
    ↓ 必须等待
DeepBase A-2 全量 HB regression PASS
    （WO-20260914-EHAI-001R2）
```

即：**可以开发，不可宣告 Conformance 收口。**

---

## 4. 永久工程证据纪律（自本轮生效，本仓适用）

以下两类验收**禁止再由文字自报**：

### 4.1 Commit Evidence

声称 `Committed` / `Isolated Commit` / `Clean Commit` 时，必须提供：

```text
commit SHA
changed file list
git object evidence
```

```text
Commit Claim  ≤  Git Evidence
```

### 4.2 Full Regression Evidence

声称 `Full Regression PASS` / `All Tests PASS` 时，必须提供：

```text
declared suite scope
suite names
case counts
pass / fail / skip counts
raw result artifact
```

```text
Regression Claim Strength  ≤  Executed Test Scope
```

```text
✗ 13 tests executed        →  claim 50-test full regression
✗ 14 declared packages built  →  claim all repository packages built
```

---

## 5. 本工单返回格式，只返回一项

```text
B-1 correction diff
```

**不要重新写巨大总结报告。**

---

## 6. 验收清单

| 条件 | 判定 |
| :--- | :---: |
| 构建证据/报告中的 `0 Warning` 表述已删除，或已补 warning count | ☐ |
| 业务代码零改动 | ☐ |
| 未重跑测试套件（233/233 仍以既有证据为准） | ☐ |
| 变更已提交且提供 commit SHA + changed file list | ☐ |

**打勾 → 本仓 `DEVELOPMENT CONTINUES`**（Conformance closure 仍待 DeepBase A-2）
