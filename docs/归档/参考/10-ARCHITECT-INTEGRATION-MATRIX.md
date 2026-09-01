# AsWish Architect Integration Matrix v0.1

> Status: **Review aid only**
>
> This file does not establish new product requirements. It is a working matrix for deciding where the proposed documents belong in the existing hierarchy.

---

## 1. Proposed document → likely authority level

| Proposed file | Primary role | Likely existing-document integration | New entity required? |
|---|---|---|---|
| Charter | Governance / research boundary | Existing architecture/product governance | No |
| Theory → Engineering Map | Traceability | Theory/method + architecture index | No, unless claim registry is absent |
| Domain Model | Semantic model | Domain model / protocol docs | Prefer no |
| Protocol Spec | Machine/engineer contract | Existing protocol/spec docs | Prefer no |
| Observability Spec | OJP implementation contract | Interaction / visual / render docs | Prefer no |
| Interaction Spec | UX interaction contract | Existing UX/UI docs | No |
| Architecture Contract | Engineering boundaries | Architecture docs | No |
| Evidence Spec | Evidence/provenance contract | Existing evidence docs | Prefer no |
| Dogfood Protocol | Product validation + case protocol | Engineering validation / dogfood docs | Maybe Case record, only if needed |
| Empirical Research Protocol | Research governance | Theory/research docs | Prefer no |

---

## 2. Merge candidates

The architect may reasonably choose to merge:

```text
Domain Model + Protocol Spec
```

if the project already uses one canonical domain/protocol document.

Likewise:

```text
Observability Spec + Interaction Spec
```

may be merged if the current UI specification already contains OJP.

And:

```text
Evidence Spec + Dogfood Protocol
```

may remain together if there is already a single evidence/case discipline.

The point is not to maximize document count.

---

## 3. Suggested hierarchy

A possible final hierarchy is:

```text
Theory / Method
├── Theory Claims
├── Theory → Engineering Map
└── Empirical Research Protocol

Product / Engineering
├── Domain Model
├── Protocol
├── Architecture
├── Interaction / OJP
└── Evidence

Validation
└── Dogfood / First Closed Loop
```

But this is intentionally non-authoritative.

---

## 4. Conflict resolution

When these drafts conflict with current project documents:

```text
Existing authoritative spec
        ↓
Identify exact conflict
        ↓
Record conflict
        ↓
Architect / Human decision
        ↓
Update merged document
```

Do not silently overwrite the existing authority with this draft package.

---

## 5. Minimum questions for architecture review

1. What is already authoritative today?
2. Where is the current Artifact model?
3. Where is the current provenance model?
4. Where is OJP currently documented?
5. Where are the current Decision / ChangeSet schemas defined?
6. Where should Visual Checkpoints live?
7. Where is the current Difference contract?
8. Where is Engineering Green / Dogfood Green defined?
9. Do current files already support the required traceability?
10. What is the smallest set of new documents required after merge?

---

## 6. Recommended outcome of review

The desired result is not:

```text
11 more permanent documents
```

The desired result is:

```text
Existing AsWish document system
+
smallest necessary empirical layer
+
clear authority boundaries
+
traceable theory → engineering → evidence loop
```
