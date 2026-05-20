# CTF in DeepSpec

CTF means Constructive Traceable Fallibilist Method.

It is the method used by DeepSpec to turn project material and AI output into specifications that humans can inspect and repair.

## One Sentence

A requirement is a constructed human-AI artifact. It must be traceable to evidence, and it must remain open to correction.

## Boundary

CTF belongs before execution.

```text
CTF / DeepSpec: form a trustworthy specification
Symphony-style orchestration: keep agents working on tasks
ODD: verify, seal, and rework implementation outputs
```

Do not put execution lifecycle state inside CTF. Once an objective is ready for execution, orchestration or ODD owns it.

## Core Workflow

```text
messy project material
        -> four projections
        -> semantic bundles
        -> evidence links
        -> trust signals
        -> human review decision
        -> SpecSnapshot / ContractCandidate
```

## Four Projections

```text
function-tree: behavior and capability
module-tree: implementation ownership and structure
view-tree: user-visible workflow and UI
data-tree: schema, state, persistence, migrations, and boundaries
```

The fourth tree is `data-tree`, not `risk-tree`. Risk is derived from all projections, with data drift often being the highest-risk source.

## Trust Signals

A reviewer should be able to see:

- evidence source status
- confidence
- generation status
- review status
- semantic bundle completeness
- conflicts with previous decisions
- stale source evidence
- agent assumptions, blockers, alternatives, and coverage

## State Model

Preferred node states are orthogonal:

```yaml
gen_status: pending | generated | failed
review_status: pending | accepted | rejected | locked
```

Legacy `status` is only a compatibility field.

## Review Discipline

Accept should be deliberate. Reject should be easy.

`accept_level` records responsibility:

```text
low_risk      acceptable local inference
provisional   usable but must be revisited
release       suitable for release gating
accountable   reviewer accepts responsibility for high-impact use
```

## Why It Helps AI Engineering

AI engineering fails when generated work looks plausible but cannot be traced, reviewed, or corrected. CTF adds the missing quality gate between agent output and human acceptance.

It does not promise that the AI is correct. It makes incorrectness discoverable and recoverable.
