# AsWish State Machine

> Status: v1.2-draft
>
> ### ⚠ 待裁定冲突标注（C-5）：本文状态定义 ≠ 代码实现
>
> **本文定义的 `gen_status` / `review_status` 与 `src/models/AsWish.Models.pas` 的实际枚举不一致，冲突待裁定。禁止在裁定前按任一侧擅自统一，也禁止新增第三套状态机。**
>
> | 项 | 本文（协议侧） | 代码（Models.pas） |
> |---|---|---|
> | gen | `pending \| generated \| failed` | `draft \| generated \| confirmed \| skipped` |
> | review | `pending \| accepted \| rejected \| locked` | `unreviewed \| accepted \| rejected \| deferred` |
>
> 差异：`confirmed` / `skipped` 只存在于代码；`failed` / `locked` 只存在于协议。`locked`（INV-7：锁定节点防 AI 覆盖）在代码中无对应实现。
>
> **裁定方向二选一**：(a) 协议追认代码（改本文 + `docs/05.协议-AsWish协议基线.md` §4 + `schemas/tree.schema.json`）；(b) 代码补齐协议语义（加 `failed` / `locked`）。
>
> 详见 `docs/07.工程-工程路线与Dogfood验收.md` §十六 · **C-5**。

AsWish separates generation state from review state.

## Generation State

```text
pending -> generated
pending -> failed
failed  -> pending
generated -> pending    when source evidence changes or regeneration is requested
```

## Review State

```text
pending -> accepted
pending -> rejected
pending -> locked
accepted -> pending     when evidence becomes stale or content_hash changes
accepted -> locked
rejected -> pending     when regenerated with different content
locked -> unlocked/pending only by human decision
```

## Legacy Mapping

```text
candidate  -> generated + pending
uncertain  -> generated + pending
confirmed  -> generated + accepted
rejected   -> generated + rejected
superseded -> generated + rejected
```

## Execution State

Execution lifecycle state is intentionally excluded. Values such as `running`, `done`, `failed`, and `verified` belong to orchestration or ODD, not to CTF specification formation.
