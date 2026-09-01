# AsWish Empirical Research Protocol v0.1

> Status: **Draft for Architect Review**
>
> Purpose: define a lightweight discipline for turning real AsWish cases into theory-relevant observations without turning the product into a research bureaucracy.

---

## 1. Research loop

Use:

```text
Theory Claim
    ↓
Operational Definition
    ↓
Engineering Mechanism
    ↓
Real Case
    ↓
Observable
    ↓
Human / System Event
    ↓
Evidence
    ↓
Observation
    ↓
Interpretation
    ↓
Challenge / Support
    ↓
Revision
    ↓
Retest
```

---

## 2. Claim vs observation vs interpretation

These must remain separate.

### Claim

A theory-derived statement.

### Observation

What the case actually shows.

### Interpretation

What the observation may mean.

Example:

```text
Observation:
Human rejected the presented ChangeSet and wrote that the real
problem was different.

Interpretation:
The Human rejected the AI frame.

Potential theoretical relevance:
Evidence for the importance of Frame Rejection.
```

The interpretation must not be written as though it were directly observed.

---

## 3. Operationalization

A theory claim is operationalized when the team can state:

```text
Under what conditions would we say this claim is instantiated?
What Observable would exist?
What event would count?
What evidence would record it?
What observation would challenge it?
```

If these questions cannot be answered, the claim is not yet operationalized.

---

## 4. Counterexample discipline

When a case appears to contradict a claim:

```text
1. Preserve raw evidence.
2. Confirm the case actually satisfied the operational conditions.
3. Check for implementation defects.
4. Check for missing/incorrect Observable.
5. Check for ambiguity in interpretation.
6. Decide whether the claim itself needs revision.
7. Record the reasoning.
8. Retest where practical.
```

Do not bury a counterexample merely because it is inconvenient.

---

## 5. Competing explanations

Where possible, distinguish among:

```text
Theory problem
Engineering defect
UX/Observable defect
Insufficient evidence
Human/context variation
```

A single observed failure should not be assigned to theory merely because the feature embodies the theory.

---

## 6. Theory status lifecycle

Recommended vocabulary:

```text
Proposed
→ Operationalized
→ Implemented
→ Observed
→ Supported
→ Challenged
→ Revised
→ Retested
```

These are evidence states, not product release states.

---

## 7. Case report template

For each significant case:

```text
Case ID:

Claim ID:

Context:

Starting State:

Operational Condition:

Observable:

Human/System Event:

Evidence:

Observation:

Alternative Explanations:

Interpretation:

Challenge / Support:

Decision:

Engineering Change:

Theory Change:

Retest Plan:

Status:
```

---

## 8. What makes a case strong

A stronger case generally has:

```text
real task
clear starting condition
clear Observable
actual Human judgment
complete provenance
unmodified evidence
repeatable observation
explicit interpretation
```

A weak case may still be useful, but should be labeled accordingly.

---

## 9. No statistical overclaiming

First Closed Loop is primarily a qualitative and engineering validation case.

One case may demonstrate:

```text
feasibility
observability
traceability
presence of a mechanism
presence of a counterexample
```

It does not establish universal causal claims.

---

## 10. Empirical facility feedback

The research loop should be bidirectional:

```text
Theory
→
Engineering

and

Engineering Cases
→
Theory Revision
```

A useful outcome may therefore be:

```text
new product mechanism
new protocol clarification
new edge case
theory refinement
new experimental question
```

---

## 11. Minimal research overhead

Do not build a separate research bureaucracy for First Closed Loop.

Prefer existing:

```text
Artifacts
Snapshots
Evidence
Decisions
Difference
Dogfood Case
```

Only add a dedicated research entity if the current structures cannot preserve the required information.

---

## 12. Long-term target

The long-term empirical facility should make it possible to answer:

```text
Which claims have been operationalized?
Which have real cases?
Which have counterexamples?
Which engineering mechanisms implement them?
Which claims have been revised?
Which observations remain unresolved?
```

That is the research value of AsWish.
