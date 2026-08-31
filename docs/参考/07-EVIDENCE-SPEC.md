# AsWish Evidence & Provenance Specification v0.1

> Status: **Draft for Architect Review**
>
> Purpose: define the minimum evidence chain required for engineering verification and later empirical interpretation.

---

## 1. Evidence principle

Evidence is a record of what actually happened.

It is not:

```text
what should have happened
```

and not:

```text
what the developer believes happened
```

---

## 2. Engineering evidence vs theory evidence

### Engineering evidence

Examples:

```text
Build result
Test result
CLI output
GUI behavior
Git diff
Changed files
Validation report
```

### Theory-relevant evidence

Requires an additional interpretive chain:

```text
Case
+
Claim
+
Observable
+
Human/System event
+
Provenance
```

Engineering evidence can be reused as theory evidence only when this relation is explicit.

---

## 3. Evidence chain

The First Closed Loop may produce:

```text
Human Intent
    ↓
Candidate
    ↓
ChangeSet
    ↓
Observable
    ↓
Decision
    ↓
SpecSnapshot
    ↓
Baseline
    ↓
Implementation Evidence
    ↓
Implementation Result
    ↓
Difference
    ↓
Human Judgment
    ↓
Revision
    ↓
Rebuild
    ↓
Result v2
    ↓
Difference v2
    ↓
Re-verification
```

---

## 4. Provenance minimum

A major event should be traceable to:

```text
who / what actor
when
source artifact
source version
action
result artifact
related observable
related decision
```

Exact schema should be reconciled with existing project data structures.

---

## 5. Decision provenance

For a Decision, preserve enough information to answer:

```text
What was being judged?
What did the Human see?
Which Candidate / ChangeSet was involved?
What did the Human decide?
What Canonical state changed, if any?
```

---

## 6. Difference provenance

A Difference should identify:

```text
comparison source A
comparison source B
comparison level
detected difference
Human interpretation / judgment
```

The current Difference v0 boundary is:

```text
0 Function
1 Entity
2 Relative Position
3 Color
```

For the first closed loop, the practical comparison priority remains:

```text
0 → 1
```

because the current Baseline and Implementation Result are not necessarily geometrically comparable.

---

## 7. Evidence quality levels

### E0 — Statement

Someone reports an outcome.

### E1 — Artifact

The claimed object exists in persistence.

### E2 — Traceable

Artifact is linked to source/action/result.

### E3 — Observable

The relevant artifact can be directly inspected.

### E4 — Reproducible

The evidence path can be replayed or reconstructed.

### E5 — Empirically useful

The record supports a stated theory claim and identifies possible counterexamples.

First Closed Loop should aim for E3–E4 on the key judgment chain.

---

## 8. Evidence cannot silently overwrite history

Important evidence should be append-oriented or versioned.

Do not silently replace:

```text
v1 evidence
```

with:

```text
v2 evidence
```

Revision must preserve the previous case.

---

## 9. Evidence acceptance checklist

```text
□ Artifact identified
□ Source identified
□ Version identified
□ Observable identified where judgment was required
□ Human/System action recorded
□ Result recorded
□ Provenance preserved
□ Contradictory evidence retained
```

---

## 10. Research interpretation

The Evidence layer records.

It should not secretly interpret.

For example:

```text
Evidence:
Human rejected candidate #2.
```

is different from:

```text
Interpretation:
The Human rejected the AI frame.
```

The latter requires evidence showing that the Human's actual statement rejected the frame.

Separate observation from interpretation.
