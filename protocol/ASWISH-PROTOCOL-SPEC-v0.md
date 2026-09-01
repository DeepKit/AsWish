# AsWish Protocol Specification

**Version:** v0
**Status:** DRAFT (First Closed Loop Verification)
**Date:** 2026-09-01

## 1. Abstract & Positioning

The AsWish Protocol is:
> An open protocol for maintaining traceable relationships between human intention, engineering decisions, software reality, evidence, differences, and human judgment in AI-assisted software development.
> （一个用于连接人的意图、工程决策、软件现实、客观证据、差异信息和人的最终判断的开放工程协议。）

The protocol addresses a fundamental challenge: As software development increasingly relies on AI and automation, how can humans retain the ability to understand, judge, and steer the changes occurring in their software systems.

**What this protocol is NOT:**
- NOT an AI Coding protocol.
- NOT an Agent control protocol.
- NOT an automated programming protocol.
- NOT a traditional requirements management protocol.
- NOT a project management protocol.
- NOT a bug or error detection protocol.

---

## 2. Protocol Principles

### 2.1 Human Authority
The Human retains absolute authority over the software lifecycle:
- **Intent Authority:** Only humans can initiate a binding intent.
- **Decision Authority:** Only humans can authorize a transition to a canonical state.
- **Judgment Authority:** Only humans can assign final meaning (e.g., acceptable, unacceptable) to a divergence.

Machines (Agents/Tools) CAN propose, generate, analyze, observe, and provide evidence.
Machines MUST NOT forge human decisions, automatically elevate state without human consensus, or substitute the final human judgment.

### 2.2 Difference Neutrality
**Difference ≠ Error.**
A Difference is strictly defined as an observable change or variation between two defined states (e.g., between an Expected Baseline and an Observed Evidence). 
A Difference may eventually be judged by a human as accepted, rejected, a necessary adjustment, a natural evolution, or an issue. The protocol itself assigns no premature value judgment to a difference.

### 2.3 Provenance First
Any critical object in the protocol MUST be able to answer:
- Who generated it?
- When was it generated?
- What was it based on?
- Which object does it correspond to?
- From which state did it derive?
- How can it be verified?
All core objects MUST support rigorous provenance tracking.

### 2.4 Immutable History
The protocol mandates history retention and state evolution without overwriting facts.
- **Forbidden:** Silently overwriting historical states, altering past facts, or deleting critical judgment chains.
- **Mandated:** Evolving states forward by creating new records and preserving the immutable historical lineage.

### 2.5 Separation of Semantic Model and Serialization
Protocol ≠ File Format.
The protocol strictly defines semantics, lifecycles, permissions, relationships, and constraints. Implementers MAY choose YAML, JSON, Database schemas, API structures, or any other serialization format to persist and transport the protocol objects, provided the semantic constraints are upheld.

---

## 3. Protocol Holistic Model

The protocol orchestrates a continuous, traceable evolution of state rather than a linear approval flow:

```text
  Human Intent
        |
        v
    Decision
        |
        v
Canonical State / Baseline
        |
        v
     Context
        |
        v
  Implementation
        |
        v
    Evidence
        |
        v
   Difference
        |
        v
 Human Judgment
        |
        v
Revision / Evolution
        |
        v
New Intent / Decision
```

---

## 4. Core Protocol Objects

Version 0 of the protocol intentionally limits its scope to the following core objects to prevent over-specification of internal engineering entities:

1. `Intent`
2. `Decision`
3. `Baseline`
4. `Context`
5. `Evidence`
6. `Difference`
7. `Judgment`

---

## 5. Object Specifications

### 5.1 Intent Object
**Definition:** An expression of the direction in which a human desires the software to evolve.
**Semantics:** An `Intent` can be incomplete, ambiguous, exploratory, or undetermined. It is NOT equivalent to a formal Specification, Requirement, or Decision. Intents may spawn new Intents as understanding evolves. Historical Intents MUST NOT be overwritten.

**Schema Attributes (Minimal):**
- `id`
- `creator`
- `created_time`
- `content`
- `references`
- `status`
- `parent_relationship`
- `provenance`

### 5.2 Decision Object
**Definition:** A formal judgment made by a Human regarding an `Intent` or a `Difference`.
**Semantics:** Only an authorized human entity can emit a valid `Decision`. It marks the boundary where an exploratory process enters a canonical, determined state.
**Actions (Non-exhaustive):** `accept`, `reject`, `defer`, `revise`, `adopt`.

**Schema Attributes (Minimal):**
- `id`
- `actor`
- `subject`
- `action`
- `timestamp`
- `result`
- `provenance`

### 5.3 Baseline Object
**Definition:** A reference state accepted by a Human at a specific point in time.
**Semantics:** Used for subsequent Reality Comparisons. Baselines are strictly **immutable**. Any new canonical state transition MUST result in the generation of a new Baseline.

**Schema Attributes (Minimal):**
- `baseline_id`
- `source_decision`
- `snapshot_reference`
- `content_hash`
- `relation_hash`
- `created_time`
- `lineage`

### 5.4 Context Object
**Definition:** The scoped boundary of understanding provided for a specific implementation activity.
**Semantics:** A `Context` is a derived, read-only projection. It defines the relevant scope for a current task and does not necessitate the inclusion of the entire project.
**Constraint:** A `Context` MUST NOT be used to retroactively modify the Canonical State it was derived from.

### 5.5 Evidence Object
**Definition:** A verifiable observation of the true software state.
**Semantics:** An Agent's claim or generated description is NOT Evidence. Evidence MUST originate from factual sources (e.g., workspace observations, source analysis, build results, test results, runtime telemetry). Evidence records a fact at a specific time, not an eternal truth, and MUST support freshness constraints.

**Schema Attributes (Minimal):**
- `evidence_id`
- `observer`
- `source`
- `observed_time`
- `target`
- `observation`
- `verification`
- `hash_reference`

### 5.6 Difference Object
**Definition:** An observable variance between a Baseline and an Evidence, or between two defined states.
**Semantics:** Differences MUST NOT default to categories like `bug`, `error`, or `failure` at the protocol layer.

**Schema Attributes (Minimal):**
- `difference_id`
- `source_state`
- `target_state`
- `difference_type` (e.g., `missing`, `mutation`, `addition`, `reference_change`, `structure_change`)
- `location`
- `description`
- `provenance`

### 5.7 Judgment Object
**Definition:** The assignment of human meaning to a `Difference`.
**Semantics:** A `Difference` possesses no ultimate meaning until a `Judgment` determines its trajectory (e.g., adjusting the implementation, or updating the Baseline to absorb the difference).

**Schema Attributes (Minimal):**
- `judgment_id`
- `actor`
- `difference_reference`
- `decision`
- `reason`
- `timestamp`
- `provenance`

---

## 6. Object Lifecycle

The protocol dictates a continuous evolution lifecycle, diverging from traditional `Open -> Closed -> Done` paradigms.

Core states/actions in the lifecycle:
1. **Create:** Instantiating intents or proposing changes.
2. **Observe:** Extracting factual evidence from the environment.
3. **Reference:** Establishing the linkage to baselines and historical provenances.
4. **Compare:** Computing neutral differences between baselines and evidence.
5. **Judge:** Humans assigning authoritative meaning to observations or differences.
6. **Evolve:** Moving the canonical state forward based on judgment.

---

## 7. Protocol Invariants

Implementations MUST uphold the following invariants at all times:

- **INV-001 [Identity]:** Every critical object MUST possess a globally unique identifier.
- **INV-002 [Traceability]:** Any state transition MUST preserve a traceable provenance lineage.
- **INV-003 [Actor Accountability]:** Every `Decision` MUST explicitly identify its authorizing actor (Human).
- **INV-004 [Evidence Source]:** Every `Evidence` MUST trace back to its objective observation source.
- **INV-005 [Difference Neutrality]:** A `Difference` DOES NOT automatically represent an error or defect.
- **INV-006 [Immutability]:** Historical states, baselines, and decisions CANNOT be silently overwritten or mutated.
- **INV-007 [Directional Integrity]:** Derived objects (e.g., `Context`) CANNOT retroactively modify their source objects.

---

## 8. Relationship with AI Agents

The AsWish Protocol **does not control Agents**. 
An Agent is merely one participant in the protocol. 

An Agent CAN:
- Read `Context`.
- Propose an `Implementation`.
- Generate suggestions and interpretations.

The protocol DOES NOT mandate:
- Which underlying LLM or reasoning engine the Agent uses.
- The internal methodology the Agent employs to generate implementations.
- That the Agent's output is automatically accepted.

The protocol encapsulates the Agent's outputs as proposals, subjecting them to Evidence observation and Human Judgment.

---

## 9. Protocol Openness & Implementation Independence

The protocol is completely independent of any specific language, tool, or platform. 

Implementations can take the form of:
- IDE Plugins
- Command Line Interfaces (CLI)
- Continuous Integration (CI) Pipelines
- Autonomous Agents
- Scanners and Telemetry Tools
- Code Review Tools

As long as an implementation strictly adheres to the protocol's object semantics, permission rules, provenance requirements, and lifecycles, it achieves full interoperability.

---

## 10. Versioning Strategy

This document represents **Protocol v0**. 
The goal of v0 is not exhaustiveness, but to verify the foundational viability of the First Closed Loop.

Future versions will evolve based solely on real-world engineering case studies and empirical data, progressively expanding the object graph and state constraints as needed.
