# AsWish Dogfood Protocol v0.1

> Status: **Draft for Architect Review**
>
> Purpose: define how AsWish uses itself to complete one real task and produce a credible first empirical case.

---

## 1. Dogfood principle

Dogfood is:

```text
real task
+
real Human
+
real AsWish
+
real Agent
+
real result
```

It is not a synthetic demo designed solely to pass acceptance.

---

## 2. Single-task rule

One First Closed Loop case must use:

```text
one real task
```

through the full cycle.

Do not switch to a more convenient demo after an inconvenient result.

---

## 3. Task selection criteria

The task should be:

```text
Small
Real
Actually needed
Modifiable
Verifiable
Somewhat ambiguous
Not excessively complex
```

Existing candidate directions include:

```text
A. CLI intent list / intent show
B. GUI natural-language intent entry
C. CLI help / wording / ordering
```

The final task is a Human/architect decision.

---

## 4. Case structure

Recommended case identifier:

```text
AW-DOGFOOD-001
```

Recommended record:

```text
Case ID
Task
Initial State
Human Intent
Problem Manifestation
AI Interpretation
Human Decision
Confirmed Understanding
Visual Baseline
Agent
Implementation Evidence
Implementation Result
Difference
Human Judgment
Revision
Rebuild
Result v2
Difference v2
Re-verification
Conclusion
```

---

## 5. Realism rules

Do not:

- manufacture a false problem;
- manufacture a Reject merely to prove rejection works;
- force inferred/unknown content for demonstration;
- intentionally introduce an error only to guarantee Difference;
- delete inconvenient evidence.

The case should be allowed to produce:

```text
No important difference
Acceptable difference
Unacceptable difference
Unresolved
```

according to reality.

---

## 6. First Closed Loop acceptance

At minimum:

```text
1. Same real task across all stages
2. Real Human participates
3. AI interpretation occurs
4. Human makes a real Decision
5. Baseline is actually observed
6. Agent implements the task
7. Implementation Evidence exists
8. Implementation Result is observed
9. Difference is surfaced
10. Human makes a Difference Judgment
11. Human produces a real Revision when required
12. Agent rebuilds
13. Result v2 is observed
14. Re-verification is performed
```

Only first-pass build is insufficient.

---

## 7. Engineering Green gate

Confirm:

```text
Build
Tests
CLI / GUI
Protocol
Regression
Git diff
Original evidence
```

Exact project-specific commands come from the current engineering process.

---

## 8. Dogfood Green gate

Confirm:

```text
□ Actual task was needed
□ Actual Human performed the judgment
□ AsWish itself was used
□ Agent performed the implementation
□ Real result was produced
□ At least one judgment was traceable
□ Revision/rebuild/re-verification occurred
```

---

## 9. Empirical case notes

After completion, record:

```text
What worked?
What failed?
Where did uncertainty appear?
Where did Human/AI boundaries become difficult?
Where did the Observable fail?
Where did Difference become ambiguous?
Did the theory-derived rule survive contact with reality?
```

Do not convert these answers into theory conclusions without identifying the supporting evidence.

---

## 10. Case closure

A case closes only when:

```text
Result v2
+
Human re-verification
+
Evidence preserved
+
Conclusion recorded
```

The conclusion may be:

```text
product works
product needs change
protocol issue
observable issue
evidence gap
theory claim challenged
theory claim supported in this case
```

"Supported in this case" must not be written as "proven."
