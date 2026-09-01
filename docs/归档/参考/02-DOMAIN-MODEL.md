# AsWish Domain Model: Artifact / Observable / Judgment v0.1

> Status: **Draft for Architect Review**
>
> This is a conceptual domain boundary document. It is not a proposal to create every listed type as a new code entity.

---

## 1. Core triad

AsWish must keep three concepts separate:

```text
Artifact
Observable
Judgment
```

### Artifact

A system-recognizable fact, structure, snapshot, or record.

Examples:

```text
Intent
Candidate
ChangeSet
Decision
SpecSnapshot
Implementation Evidence
Implementation Result
Difference
Revision
```

### Observable

A human-facing manifestation of an Artifact.

Examples:

```text
Text
Table
Tree
Review
SVG
Preview
Overlay
Difference View
```

### Judgment

A Human assessment made against an Observable.

Examples:

```text
Accept
Reject
Clarify
Acceptable
Unacceptable
Unresolved
Revision
```

---

## 2. Canonical relationship

The minimum relationship is:

```text
Artifact
   ↓
Observable
   ↓
Human Judgment
   ↓
New Artifact
```

The UI may mediate the interaction, but it must not erase the underlying relationship.

---

## 3. Conceptual identity fields

A traceable Artifact should conceptually support:

```text
artifact_id
artifact_type
version
created_at
source
parent / predecessor
provenance
```

Exact field names and storage location are subject to existing schema review.

An Observable should conceptually support:

```text
observable_id
artifact_id
artifact_version
representation_type
created_at
source / renderer
stable_reference
```

A Judgment should conceptually support:

```text
judgment_id
judgment_type
actor
target_artifact
target_observable
created_at
decision_context
result
provenance
```

These are conceptual minimums, not mandatory new types.

---

## 4. Existing vs proposed conceptual artifacts

### Existing / expected from current project material

```text
CandidateIntent
ChangeSet
Decision
SpecSnapshot
Evidence
Difference
```

### Possible logical records needed by the empirical layer

```text
Case
Observation
Theory Claim
Counterexample
```

These should be introduced only if existing structures cannot already carry the required information.

---

## 5. Prohibited modeling drift

Do not create parallel entities merely because a new screen requires a state.

Avoid introducing conceptual duplicates such as:

```text
VisualDecision
VisualApproval
VisualProposal
VisualBaselineEntity
VisualReviewState
ParallelCandidate
ChangeObject
NewDecisionSystem
```

A UI mode, panel, or render state is not automatically a domain artifact.

---

## 6. Decision as a domain fact

A Decision is not merely:

```text
button_click = 1
```

The system must preserve the semantic result.

Example:

```text
Choice 2
→ Candidate selected
→ Domain Decision = Accept
```

or:

```text
Choice 9
→ Human text entered
→ new interpretation path
```

Therefore:

```text
Interaction Protocol
≠
Decision Semantics
```

---

## 7. Observable identity and repeatability

A Human should be able to return to the object that was judged.

Therefore an Observable used for an important judgment should be:

- stable enough to identify;
- reproducible enough to revisit;
- linked to its source Artifact/version;
- clear about what it represents.

"Currently on screen" is not a sufficient identity mechanism.

---

## 8. Snapshot principle

Whenever an Artifact is versioned or a decision depends on a state, the system should preserve enough context to reconstruct:

```text
What was the Artifact?
What version was observed?
What did the Human see?
What did the Human decide?
```

The exact snapshot strategy should reuse the existing Snapshot / SpecSnapshot mechanisms where possible.

---

## 9. Implementation Evidence vs Implementation Result

Keep the distinction:

```text
Implementation Evidence
=
record of what the Agent actually did

Implementation Result
=
the resulting artifact/product state
```

Evidence may include:

```text
commands
changed files
build/test output
agent actions
```

Result may include:

```text
actual GUI
CLI behavior
rendered output
new source state
```

The two must not be collapsed.

---

## 10. Domain invariants

The following are proposed invariants:

1. No canonical mutation without an authoritative Decision.
2. No required Human Judgment without a corresponding Observable.
3. No empirical conclusion without an identified Case / Evidence chain.
4. UI state must not silently become domain state.
5. Interaction digits must not be mistaken for domain Decisions.
