# AsWish Observability Specification v0.1

> Status: **Draft for Architect Review**
>
> Foundation: OJP — Observable Judgment Principle.

---

## 1. Normative principle

> **Human does not judge what the system knows internally; Human judges what AsWish makes observable.**

Therefore:

```text
Artifact
→ Observable
→ Human Judgment
```

must be explicit for any interaction that requires meaningful Human judgment.

---

## 2. Observable requirements

An Observable used for a Human judgment should satisfy:

```text
Identity
Correspondence
Visibility
Stability
Repeatability
Traceability
```

### Identity

The system can determine which Artifact/version it represents.

### Correspondence

The Observable semantically represents the target Artifact.

### Visibility

The Human can directly inspect it in the product.

### Stability

The representation does not silently change under the same underlying state.

### Repeatability

The Human can revisit the representation.

### Traceability

The system can connect the Observable to its source Artifact and the resulting Judgment.

---

## 3. OJP acceptance gate

For any Human Confirmation / Decision / Comparison / Revision interaction:

```text
□ Human judgment object is explicit
□ Target object is identifiable
□ Observable exists
□ Observable corresponds to the target
□ Human can directly observe it
□ Observable source is traceable
□ Observable can be revisited
□ AI has not silently substituted its own judgment
□ No parallel domain entity was created only for rendering
```

Failure of any required gate means the feature is not OJP-complete.

---

## 4. Observable classes

Use existing or natural representations where appropriate:

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

There is no rule requiring every stage to produce SVG.

SVG is only one Observable representation.

---

## 5. Current Visual Checkpoints

The current First Closed Loop uses:

```text
VC-01 Current State
VC-02 Problem Manifestation
VC-03 Confirmed Baseline
VC-04 Implementation Result
VC-05 Difference
VC-06 Revised Result
```

### VC-01

Human observes current real structure.

### VC-02

Human observes current structure plus problem/ambiguity/unknown markers.

### VC-03

Human observes the confirmed target structure.

### VC-04

Human observes the actual implementation result.

### VC-05

Human observes the difference between accepted baseline and actual result.

### VC-06

Human observes the revised result after the revision cycle.

---

## 6. Observable provenance

For a significant Observable, conceptually preserve:

```text
observable_id
source_artifact_id
source_version
representation_type
renderer / generator
created_at
```

Exact schema should reuse existing mechanisms where possible.

---

## 7. Current-state rendering rule

Where the existing system already renders a Spec / Tree / SVG, reuse that capability.

Do not introduce:

```text
VisualState
VisualSnapshot
VisualApproval
```

merely because a screen needs to display a state.

The target is a representation, not a new domain fact.

---

## 8. Review Surface rule

A review surface should make the Human able to answer:

```text
What did I say?
What did the AI understand?
What exactly is being proposed/changed?
What am I being asked to judge?
```

The UI should minimize the need to infer hidden system state.

---

## 9. Observable vs Judgment

Do not encode:

```text
Green button = Accept is already true
```

Instead:

```text
Observable
+
Human interaction
→
Decision
```

Color may classify interaction semantics, but must not substitute for the Human judgment.

---

## 10. Reproducibility test

An Observable passes the basic repeatability test when:

1. the Human can leave the page;
2. return to the relevant state;
3. identify the same target Artifact/version;
4. inspect the corresponding representation;
5. understand what was previously judged.

