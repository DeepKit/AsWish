# AsWish SPEC

> Status: v1.2-draft  
> Scope: protocol and workflow baseline for `.AsWish/` workspaces

## 1. Objective

AsWish defines a project-local specification workspace that humans and AI agents can both read. The workspace must make generated requirements traceable, reviewable, fallible, and usable as input to downstream coding agents.

AsWish is not an agent orchestrator, an IDE, a coding agent, or a generic spec editor. It is Level 3 (engineering implementation) of the unified system (`Difference Monism → As We Wish → As I Wish → AsWish → .AsWish`), acting as the open engineering layer between **Human ↔ AI Coding Agent ↔ Software Implementation**: it forms the confirmed representation before development and holds implementation evidence against it afterward. Product identity is defined in [`ASWISH-PRODUCT-IDENTITY.md`](ASWISH-PRODUCT-IDENTITY.md); documentation governance in [`ASWISH-DOCUMENTATION-GOVERNANCE.md`](ASWISH-DOCUMENTATION-GOVERNANCE.md); this document is the protocol baseline only.

## 2. Workspace

A AsWish-enabled project contains a `.AsWish/` directory.

```text
.AsWish/
  project-spec.yaml
  trees/
    function-tree.yaml
    module-tree.yaml
    view-tree.yaml
    data-tree.yaml
  bundles/
    semantic-bundles.yaml
  relations/
    requirement-relations.yaml
  evidence/
    source-evidence.yaml
  issues/
    doc-issues.yaml
  decisions/
    requirement-decisions.yaml
    review-decisions.yaml
  agents/
    agent-results.yaml
```

`project-spec.yaml` is the index. YAML files are the fact source. HTML is a generated review surface and must not be treated as the source of truth.

## 3. Four Projections

AsWish represents a requirement through four weakly coupled projections.

| Projection | Question | Main risk it controls |
|---|---|---|
| function-tree | What should the system do? | missing or ambiguous behavior |
| module-tree | Where does the behavior live? | implementation ownership drift |
| view-tree | What does the user see or operate? | UI and workflow mismatch |
| data-tree | What data exists and how does it change? | schema, migration, persistence, and state drift |

The first three trees remain readable on their own. `data-tree` adds the data model projection and should not be replaced by a generic risk tree. Risk is a field and derived view, not the fourth tree.

## 4. Node State

New protocol work uses orthogonal states:

```yaml
gen_status: pending | generated | failed
review_status: pending | accepted | rejected | locked
```

Legacy `status` remains readable:

```yaml
status: candidate | confirmed | uncertain | rejected | superseded
```

Readers should map legacy status conservatively:

| legacy status | gen_status | review_status |
|---|---|---|
| candidate | generated | pending |
| uncertain | generated | pending |
| confirmed | generated | accepted |
| rejected | generated | rejected |
| superseded | generated | rejected |

Execution state does not belong to CTF/AsWish. Task execution state belongs to orchestration or ODD layers.

## 5. Traceability

Every accepted or high-confidence fact should be connected to at least one of:

- source evidence
- explicit human decision
- previous accepted snapshot
- generated result with recorded assumptions and coverage

Accepted nodes without evidence are allowed only as provisional decisions and must stay visible as trust gaps.

## 6. Semantic Bundles

A semantic bundle groups the same requirement across projections.

```yaml
bundles:
  - id: bnd-login
    label: User login
    anchors:
      - tree: function
        node_ids: [func-login]
      - tree: module
        node_ids: [mod-auth-service]
      - tree: view
        node_ids: [view-login-form]
      - tree: data
        node_ids: [data-user, data-session]
    confidence: high
    completeness:
      has_function: true
      has_module: true
      has_view: true
      has_data: true
      has_evidence: true
      has_decision: false
```

Bundles support cross-tree review and detect projection gaps.

## 7. Agent Results

When an AI agent produces a proposal, AsWish should record more than the final answer.

Required review signals:

- assumptions
- tradeoffs
- unresolved questions
- blockers encountered
- alternatives considered and rejected
- coverage added
- coverage not added

This lets human reviewers judge whether the result is reasonable, not only whether it exists.

## 8. Review Decisions

Review decisions are facts, not UI state.

```yaml
decision_action: accept | reject | request_changes | lock | unlock
accept_level: low_risk | provisional | release | accountable
lock_status: unlocked | locked
```

Accept levels must be decided before implementation details are hardened because they affect schema, UI, audit logs, and downstream release gates.

## 9. Invariants

AsWish implementations should enforce the protocol invariants in `protocol/invariants.md` and state transitions in `protocol/state-machine.md`.

Minimum invariants:

- node IDs are unique within a tree
- `parent_id` points to an existing node in the same tree or is null
- relations point to existing nodes
- accepted nodes have evidence or an explicit provisional/accountable decision
- generated content cannot silently overwrite locked human decisions
- stale evidence keeps historical value but must be visible

## 10. Extension Rules

Use `x_` for extension fields and kinds. Readers must ignore unknown `x_` fields and warn on unknown non-extension core fields.

```yaml
kind: x_workflow
x_vendor_score: 0.82
```

Do not use `x-` for kind names.

## 11. Public Message

Core research questions lead; the mechanism follows:

```text
Are we still building the same thing?
Where did the difference enter?

AsWish keeps what humans and agents confirmed visible before development,
and makes what was actually built comparable against it afterward —
so every difference is visible, traceable, and judged by a human.
```

Recommended comparison:

```text
Symphony makes every task runnable by agents.
AsWish keeps every agent task answerable to the thing humans confirmed.
ODD makes accepted outputs verifiable.
```

Public framing follows the propagation order: real problem → real experiment → engineering method → theory (see [ASWISH-PRODUCT-IDENTITY.md](ASWISH-PRODUCT-IDENTITY.md)).
