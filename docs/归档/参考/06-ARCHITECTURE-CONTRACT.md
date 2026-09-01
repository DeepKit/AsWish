# AsWish Architecture Contract v0.1

> Status: **Draft for Architect Review**
>
> Purpose: define architectural boundaries for implementing the current interaction/evidence model without creating parallel systems.

---

## 1. Layered responsibility

A working conceptual flow is:

```text
UI / WebView2
      ↓
Controller / Commands
      ↓
Domain mechanisms
      ↓
Persistence
      ↓
Artifacts / Evidence
```

The exact layer names and module boundaries must be checked against the actual repository.

---

## 2. UI responsibilities

UI may:

- display Observables;
- collect Human input;
- trigger Commands;
- navigate between Conversation and Decision;
- surface validation/errors;
- expose existing artifacts through user-facing representations.

UI must not:

- directly mutate Canonical Spec;
- invent a parallel Decision entity;
- infer a Human decision from display state;
- silently convert a visual state into domain truth.

---

## 3. Controller / Command responsibilities

Controllers/Commands coordinate:

```text
interaction
→ domain operation
→ persistence
→ resulting Observable
```

They should reuse existing commands/mechanisms such as:

```text
SubmitUserIntent
ReviewChangeSet
AcceptChangeSet
RejectChangeSet
ClarifyChangeSet
```

where already available.

---

## 4. Domain responsibilities

Domain mechanisms own semantics such as:

```text
ChangeSet
Decision
ApplyChangeSet
Canonical State
Validation
```

They must not depend on incidental UI state.

---

## 5. Persistence responsibilities

Persistence stores authoritative artifacts.

Potential current/proposed records include:

```text
Intent
ChangeSet
Decision
SpecSnapshot
Evidence
Difference
```

The architecture should prefer extending existing structures over introducing parallel stores.

---

## 6. Observable architecture

Rendering should be treated as a representation pipeline:

```text
Artifact / Snapshot
        ↓
Existing Render / Builder
        ↓
Observable
        ↓
UI
```

A visual representation is not automatically a new domain state.

---

## 7. Provenance architecture

Important transitions should preserve enough information to reconstruct:

```text
source
→ interpretation
→ decision
→ resulting state
```

Where existing provenance fields or snapshot IDs already exist, reuse them.

---

## 8. Command/event separation

The architecture should distinguish:

```text
User interaction event
```

from:

```text
Domain decision
```

For example:

```text
keypress 2
```

is not itself a domain fact.

It becomes a domain fact only after the applicable interaction semantics resolve it into a command/decision.

---

## 9. GUI implementation boundary

For R1, prefer:

```text
Existing WebView2
+
existing JS Bridge
+
existing Controller/Commands
+
THbChoiceDeck
```

over:

```text
new UI framework
new decision store
new proposal lifecycle
new visual entity model
```

---

## 10. Architecture review checklist

Before merging a feature, confirm:

```text
□ Reused existing artifact types
□ Reused existing persistence
□ Reused existing commands
□ No direct UI-to-Canonical mutation
□ Observable is traceable
□ Decision is domain-level
□ No parallel entity exists only because the UI needed one
□ Existing tests still cover old paths
```
