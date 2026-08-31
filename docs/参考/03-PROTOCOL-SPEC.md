# AsWish Protocol Specification v0.1

> Status: **Draft for Architect Review**
>
> Purpose: collect the protocol-level invariants already established in the current project context so engineers can refer to one contract.

---

## 1. Intent protocol

```text
Human Natural Language
        ↓
CandidateIntent
        ↓
Persistence
```

Human Natural Language must not directly mutate Canonical Spec.

---

## 2. Interpretation protocol

```text
CandidateIntent
        ↓
AI Interpretation
        ↓
ChangeSet
```

ChangeSet describes an interpretation of intent.

It is not itself a Decision and not itself permission to mutate Canonical Spec.

---

## 3. Decision protocol

```text
ChangeSet
    ↓
Human Review
    ↓
Decision
```

The Decision is the authoritative Human judgment.

---

## 4. Accept

```text
Decision.Accept
    ↓
ApplyChangeSet
    ↓
Canonical Spec
    ↓
Validation
```

The exact validation sequence should reuse the existing implementation.

---

## 5. Reject

```text
Decision.Reject
    ↓
Canonical Spec unchanged
```

Reject is a real decision event and must remain traceable.

---

## 6. Clarify

Clarify has two effects:

```text
Decision.Clarify
    ↓
Decision persisted
    +
Canonical Spec unchanged
    +
Conversation resumed
```

Clarify is not:

```text
Reject
Cancel
Back
```

---

## 7. 0–9 interaction protocol

Only on a Decision Surface:

```text
1–7 = Candidate Option
8   = Regenerate Candidates
9   = Human Input
0   = Back
```

Rules:

- 1–7 may contain fewer than seven candidates.
- 8 is not a Decision.
- 9 is an open escape hatch, not "Other".
- 0 is navigation and does not create a Decision.
- Keyboard and mouse semantics must be equivalent.

---

## 8. Regenerate protocol

```text
8
↓
Regenerate candidates
↓
New 1–7 set
```

Regeneration must be anchored to:

```text
Original Human Intent
+
Current Decision Context
```

Regeneration alone must not mutate Canonical Spec.

---

## 9. Human Input protocol

```text
9
↓
Human natural-language input
```

The input may:

- reject the frame;
- combine candidates;
- add constraints;
- replace assumptions;
- redefine the problem.

The system must preserve the Human expression as an authoritative source input.

---

## 10. Back protocol

```text
0
↓
Return to previous interaction layer
```

0 must not create:

```text
Candidate
ChangeSet
Decision
Canonical Spec mutation
```

---

## 11. Human / AI authority boundary

### Human owns

```text
Intent
Judgment
Decision
Accept
Reject
Clarify
Unresolved
Difference Judgment
Revision Decision
Final Confirmation
```

### AI may

```text
Discover
Ask
Explain
Suggest
Transform
Generate
Render
Implement
Inspect
Surface Difference
```

### AI must not

```text
Treat guess as confirmation
Treat Candidate as Decision
Treat Difference as Error automatically
Mutate Canonical Spec without Human Decision
Declare final closure for the Human
```

---

## 12. Canonical boundary

Forbidden:

```text
Conversation
→
AI
→
Automatic Canonical Mutation
```

Required:

```text
Conversation
→
Interpretation
→
Human Decision
→
Canonical State
```

---

## 13. Protocol conformance tests

At minimum, test:

### Accept path

```text
ChangeSet
→ Accept
→ Decision persisted
→ Canonical mutation
```

### Reject path

```text
ChangeSet
→ Reject
→ Decision persisted
→ Canonical unchanged
```

### Clarify path

```text
ChangeSet
→ Clarify
→ Decision persisted
→ Canonical unchanged
→ Conversation resumed
```

### Back path

```text
Decision Surface
→ 0
→ no Decision created
```

### Regenerate path

```text
Decision Surface
→ 8
→ candidates regenerated
→ no Canonical mutation
→ no Decision
```

### Human Input path

```text
Decision Surface
→ 9
→ Human text
→ retained as source input
```
