# AsWish Empirical Facility Charter v0.1

> Status: **Draft for Architect Review**
>
> Purpose: define how AsWish may serve as an empirical facility for **As We Wish / Difference Monism**, without redefining the frozen product identity, interaction principles, or existing engineering contracts.

---

## 1. Purpose

AsWish is both:

1. an engineering product that must work for a real user; and
2. a controlled environment in which claims from the theory/method layer can be operationalized, observed, challenged, and revised.

This charter defines the boundary between those two roles.

The central principle is:

> **AsWish must not be treated as a machine that proves the theory. It is a facility in which theory-derived claims can be made operational and exposed to evidence, including contrary evidence.**

---

## 2. Scope

This charter governs the relationship among:

```text
Difference Monism
        ↓
As We Wish
        ↓
AsWish engineering
        ↓
Observed cases
        ↓
Evidence
        ↓
Theory evaluation
```

It does not replace:

- existing product specifications;
- OJP;
- Dual-Surface;
- 0–9 Universal Choice Standard;
- current protocol schemas;
- current architecture;
- existing work orders;
- implementation tickets.

Architectural integration is intentionally left open for review.

---

## 3. What the empirical facility is trying to make possible

For a theory-derived claim, AsWish should make it possible to answer:

```text
What is the claim?
↓
What would count as an observable instance of it?
↓
What engineering mechanism exposes that instance?
↓
What human action or system event is recorded?
↓
What evidence supports or challenges the claim?
↓
What changed in the theory, engineering, or both?
```

A useful operational chain is:

```text
Theory Claim
→ Operational Definition
→ Engineering Mechanism
→ Observable
→ Human / System Event
→ Evidence
→ Interpretation
→ Challenge / Support
→ Revision
→ Retest
```

---

## 4. What does NOT count as empirical evidence

The following are insufficient by themselves:

- "The architecture looks consistent with the theory."
- "The code implements the rule."
- "The UI contains the required buttons."
- "The tests are green."
- "The developer reports that the behavior is correct."
- "A human could probably understand the screen."
- "The product team agrees with the hypothesis."

These may be engineering evidence, design evidence, or stakeholder judgment, but they are not automatically theory evidence.

A theory-relevant evidence claim must identify:

```text
Case
Artifact / Event
Observable
Human or system action
Recorded provenance
Interpretation
```

---

## 5. The anti-circularity rule

AsWish must avoid:

```text
Theory defines rule
→
Software is built to satisfy rule
→
Software satisfies rule
→
Therefore theory is proven
```

That is implementation conformance, not empirical validation.

The empirical loop must instead allow:

```text
Theory claim
→
Operationalization
→
Real case
→
Observation
→
Unexpected result / counterexample
→
Challenge
→
Revision
```

A case that contradicts a claim is valuable evidence.

---

## 6. Engineering Green vs Empirical Green

The existing engineering gate remains:

```text
Engineering Green
```

meaning the implementation is technically correct and regressions are controlled.

For empirical use, add a separate conceptual gate:

```text
Empirical Evidence Ready
```

This means the case contains sufficient provenance and observation to support a theory-related interpretation.

These must not be conflated.

A successful build does not imply empirical support.

A failed build does not automatically refute a theory.

---

## 7. Dogfood is not proof by usage

Dogfood has two roles:

### Product role

Determine whether AsWish can actually be used by its intended operator to accomplish a real task.

### Research role

Produce naturally occurring cases in which theory-derived mechanisms are exercised under real conditions.

Dogfood should therefore preserve:

- successful paths;
- rejected paths;
- clarification;
- uncertainty;
- unexpected behavior;
- revision;
- second-round outcomes.

The protocol must not optimize cases to make the theory look successful.

---

## 8. Minimum theory-evidence record

Every theory-relevant claim/case should be traceable through:

```text
Claim ID
Case ID
Operational Definition
Input / Starting State
Observable
Human/System Action
Artifact(s)
Evidence
Observed Outcome
Interpretation
Alternative Explanation
Status
```

Recommended status vocabulary:

```text
Proposed
Operationalized
Implemented
Observed
Supported
Challenged
Revised
Retested
```

"Supported" is not equivalent to "Proven."

---

## 9. Relationship to OJP

OJP is an engineering and interaction principle:

> Human judges what AsWish makes observable, not hidden system state.

For empirical work, this produces a useful test condition:

```text
Artifact
→ Observable
→ Human Judgment
```

If a judgment cannot be tied to an observable representation, the case has an OJP failure.

That failure is itself a potentially important observation. It must not be silently excluded from the record.

---

## 10. Relationship to Difference

Difference serves two distinct roles:

### Product role

Help a human determine whether the implemented result still corresponds to what was confirmed.

### Empirical role

Expose where implementation, interpretation, or revision diverged from the prior state.

Therefore:

```text
Difference ≠ Error
Difference ≠ Theory Refutation
Difference = Observable divergence
```

Interpretation remains a human/research judgment.

---

## 11. Empirical facility maturity

This charter proposes four maturity levels:

### Level 1 — Traceable
Artifacts and decisions can be traced.

### Level 2 — Observable
Judgment objects have stable observables.

### Level 3 — Reproducible
The same case can be revisited and its evidence reconstructed.

### Level 4 — Challengable
The system preserves contrary cases and supports theory revision.

First Closed Loop needs Levels 1–2 at minimum. Level 3 is a major target. Level 4 is the long-term research objective.

---

## 12. Non-goals

This charter does not define:

- a scientific publication methodology;
- statistical inference requirements;
- user study ethics procedures;
- a research database;
- a new proposal lifecycle;
- a replacement decision system;
- a replacement evidence system.

Those may be added later if justified.

---

## 13. Success condition

The charter is successful when an architect can identify, for any important theory-derived rule:

```text
where it lives,
how it is operationalized,
what can be observed,
what evidence records it,
how a human can challenge it,
and how a counterexample feeds back into theory or engineering.
```

---

## 14. Architect review questions

Before adoption, confirm:

1. Where should this charter live in the existing document hierarchy?
2. Which concepts already have authoritative documents?
3. Which proposed artifacts duplicate existing structures?
4. Which provenance fields already exist?
5. Which parts belong to protocol, architecture, or research governance rather than product specification?
6. What is the smallest addition needed to support the empirical loop?
