# AsWish Theory → Engineering Map v0.1

> Status: **Draft for Architect Review**
>
> This document maps theory/method claims to engineering mechanisms. It does not declare that any claim is empirically established.

---

## 1. Purpose

The map prevents two failure modes:

1. theory statements remaining too abstract to test;
2. engineering mechanisms being mistaken for proof of the theory.

Each row should be read as:

```text
Claim
→ Operationalization
→ Engineering mechanism
→ Observable
→ Evidence
→ Challenge question
```

---

## 2. Core mapping

| Theory / method concept | Operationalized as | Engineering mechanism | Primary Observable | Evidence target | Challenge question |
|---|---|---|---|---|---|
| Human Intent | An explicitly stored user-originated statement | CandidateIntent / Intent persistence | Intent text / intent view | Intent artifact + provenance | Can the later system state be traced back to what the Human said? |
| AI Interpretation | Structured candidate interpretation of Human Intent | ChangeSet / CandidateIngest | Review surface | ChangeSet + source + context | Can interpretation be distinguished from Human decision? |
| Human Judgment | A deliberate assessment of an observable | Decision / Judgment action | Decision Surface | Decision record + target observable | Did the Human actually judge the presented object? |
| Canonical State | State changed only by a formal decision | ApplyChangeSet / SpecStore | Updated Spec / Tree | Before/after snapshot + Decision | Can any path mutate canonical state without Decision? |
| OJP | Every required judgment has a corresponding observable | Observable binding / stable render | Review, Tree, SVG, Diff view | Artifact → Observable → Judgment chain | Is there any judgment whose object was not directly observable? |
| Dual-Surface | Exploration and commitment occupy distinct interaction spaces | Conversation Surface + Decision Surface | Current active surface | UI/event trace | Did exploratory language accidentally become canonical? |
| 0–9 protocol | Stable interaction semantics across decision contexts | THbChoiceDeck | Number + semantic label | Interaction event / resulting command | Does any control reinterpret the reserved digits? |
| Frame Rejection | Human can reject the candidate frame itself | 9 Human Input + recorded text | Human statement | Decision/interaction + context | Can the system distinguish "none of these" from rejecting the question frame? |
| Clarify duality | Clarify is a Decision and a route back to exploration | Decision persistence + Conversation return | Clarify result + conversation | Decision + navigation event | Is one side recorded while the other silently disappears? |
| Difference | Observable divergence between compared artifacts/states | Difference v0 | Difference View | Comparison inputs + result + Human judgment | Is difference being incorrectly treated as error? |
| Revision | Human judgment can cause a new implementation cycle | Revision → Rebuild | Revised Result | Revision + v2 evidence | Is revision merely a status flag, or did it produce a real second result? |
| Provenance | Every important state transition retains origin and context | Artifact links / evidence chain | Provenance view or record | Linked artifacts | Can final state be traced to origin and decision? |

---

## 3. Required distinction: implementation vs empirical claim

Example:

```text
"OJP requires an Observable"
```

and:

```text
"ChangeSetReview uses a rendered Observable"
```

are not the same statement.

The first is a conceptual claim.

The second is an implementation fact.

A third statement is needed for empirical evaluation:

```text
"In real cases, when the required judgment object is presented
through the defined Observable, the Human can identify and judge
that object without relying on hidden system state."
```

That third statement is testable.

---

## 4. Theory claim template

Every theory-derived claim that enters engineering should eventually be expressible as:

```text
Claim ID:
Title:
Claim:
Operational Definition:
Required Conditions:
Observable:
Expected Human/System Event:
Evidence:
Possible Counterexample:
Interpretation Rule:
Current Status:
```

---

## 5. Initial candidate claim registry

### OJP-001

**Claim:** Human judgment must target an Observable representation rather than hidden internal state.

**Operational condition:** A required judgment interaction must expose a stable, corresponding Observable and retain its traceability.

**Potential counterexample:** A judgment is accepted by the product while the target object was only available internally or indirectly.

**Status:** Proposed / operationalized by current OJP rules; empirical status unconfirmed.

---

### BND-001

**Claim:** Human Decision is distinct from AI Understanding.

**Operational condition:** The system can record a correct AI interpretation followed by Human Reject.

**Potential counterexample:** Accept is automatically emitted from a correct interpretation.

**Status:** Proposed; partially represented by existing Decision semantics.

---

### DS-001

**Claim:** Open exploration and formal commitment should remain distinct surfaces.

**Operational condition:** Conversation content can remain non-canonical until a Human enters the Decision flow and produces a formal Decision.

**Potential counterexample:** A conversational utterance mutates canonical state without formal Decision.

**Status:** Proposed / operationalized by current boundary.

---

### DIF-001

**Claim:** Difference is not intrinsically Error.

**Operational condition:** Difference output permits at least acceptable, unacceptable, unresolved, and no-important-difference interpretations.

**Potential counterexample:** Every detected divergence is automatically classified as failure.

**Status:** Proposed / operationalized in current semantics.

---

## 6. Theory revision rule

When an observation conflicts with a claim, the default response is:

```text
Record observation
→ Verify evidence
→ Check operationalization
→ Distinguish implementation defect from claim challenge
→ Decide whether engineering or theory needs revision
→ Retest
```

Do not jump directly from one anomalous case to theory rejection.

Likewise, do not dismiss an anomaly as "implementation noise" without documenting why.

---

## 7. Architect decisions needed

- Which theory claim IDs are authoritative?
- Where should the claim registry live?
- Which existing domain objects can carry claim/case references?
- Which evidence is product evidence vs theory evidence?
- Which mappings belong in stable specification and which belong in research notes?
