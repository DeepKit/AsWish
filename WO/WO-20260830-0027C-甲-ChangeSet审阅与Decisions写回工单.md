# WO-20260830-0027C · 甲（开发AI）· Change Set 审阅与 Decisions 写回

- 下发时间：2026-08-30 11:05 (GMT+8)
- 下发人：主控AI
- 承接方：**甲（开发AI，DeepSpec 仓库）**
- 工作仓库：`D:\_Progs\02Business\DeepSpec`
- 优先级：P0
- 依赖：`0027B` + `0027D` 的 **D0 里程碑**
- 门禁：非睿智轻量门禁；单 commit ≤200 行；build/test 原始输出存档证据；主控 APPROVED/RETURNED，未过不得 CLOSE。

---

## 一、目标

用户通过现有 `Decisions` 裁决 Change Set；**Accept 后才允许写回 Canonical Spec**。

## 二、Review 展示

语义变化，非 YAML Diff：

```text
原需求：用户可以删除账户
修改后：用户可以停用账户
原因：用户明确纠正
影响：Function / Module / View / Data
```

必要时允许展开底层 Spec 差异。

## 三、用户动作

仅接受 / 拒绝 / 继续自然语言修正，不要求用户直接编辑 Spec。

## 四、Decision ↔ Change Set 关联（主控补点）

现有 `Decision` 是对**节点**的裁决，本票需让 Decision 记录能引用 Change Set 的**具体 change 项**（如 decision 增加 `change_set_id` / `change_index` 引用字段）。Decision 是唯一人类裁决事实。

## 五、Accept 后写回（主控补点）

写回**复用 `CandidateIngest` 的 merge 语义**（同 ID 合并更新、保留 `review_status`/`decision_refs`），不另写第二套更新逻辑：

```text
Accepted Decision → Canonical Spec → Validation → Render
```

复用现有 `schema validation` / `consistency validation` / renderer，不建新验证系统。

## 六、验收

- AC-01：用户能看懂 Change Set。
- AC-02：用户能进行现有 Decisions 支持的正式裁决。
- AC-03：Reject 不修改 Canonical Spec。
- AC-04：Accept 才触发 Spec 写回。
- AC-05：写回后自动执行现有验证。
- AC-06：重新打开项目后 Accepted Spec 状态一致。
- AC-07：用户可继续自然语言修正上一轮结果。
- AC-08：Decision 记录可追溯到具体 change 项。
- AC-09：写回复用 CandidateIngest merge 语义，无第二套更新逻辑。
- AC-10：build + 全量测试输出存档为证据，主控独立复核。

## 七、非目标

不做：Baseline / Code·Spec consistency / Drift / Agent execution / Python / 新 Decision 状态机。

## 交付物

代码 + `WO\evidence\` 证据 + `WO\AUDIT-REQUEST-WO-20260830-0027C.md` 复审请求。
