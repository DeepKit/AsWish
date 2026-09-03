# AsWish State Machine

> Status: v1.2-draft
>
> **C-5 已裁定（2026-09-03，方向 (a) 协议追认代码）**：本文枚举与转移规则以代码 `src/models/AsWish.Models.pas`（`TGenStatus` / `TReviewStatus` / `TSpecEnums`）为准，与其保持一致。`failed` / `locked` 为预留语义（未实现），将来经 `protocol/GOVERNANCE.md` 治理流程按需加回。裁定记录见 `docs/07.工程-工程路线与Dogfood验收.md` §十六 · C-5。

AsWish separates generation state from review state.

## Generation State

```text
draft -> generated
draft -> skipped
generated -> confirmed
generated -> skipped
confirmed    terminal
skipped      terminal
```

## Review State

```text
unreviewed -> accepted
unreviewed -> rejected
unreviewed -> deferred
deferred -> accepted
deferred -> rejected
accepted    terminal
rejected    terminal
```

## Legacy Mapping

```text
candidate  -> generated + unreviewed
uncertain  -> generated + unreviewed
confirmed  -> generated + accepted
rejected   -> generated + rejected
superseded -> generated + rejected
```

## Execution State

Execution lifecycle state is intentionally excluded. Values such as `running`, `done`, `failed`, and `verified` belong to orchestration or ODD, not to CTF specification formation.
