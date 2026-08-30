# GitHub Copilot / Coding Agent Instructions for AsWish

> Authoritative product identity: [`ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md)  
> Documentation governance: [`ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md)

AsWish is the open engineering layer between **Human ↔ AI Coding Agent ↔ Software Implementation**. It makes what should be built visible and confirmable before development, and makes what was built comparable against implementation evidence afterward.

Core research questions:
- **Are we still building the same thing?**
- **Where did the difference enter?**

---

## 1. Product Hierarchy & Context

AsWish is Level 3 of a single unified system:

```text
Level 0: Difference Monism (差异一元论 · Theory)
        ↓
Level 1: As We Wish (Co-construction & Shared Understanding · Theory/Method)
        ↓
Level 2: As I Wish (Product Concept: "Is it still what I really wanted?")
        ↓
Level 3: AsWish (Engineering Implementation, this repo)
        ↓
Project Workspace: .AsWish (Project Workspace / Protocol Carrier)
```

Core main chain:
$$\text{Manifest} \longrightarrow \text{Confirm} \longrightarrow \text{Construct} \longrightarrow \text{See} \longrightarrow \text{Build} \longrightarrow \text{Verify}$$
$$(\text{显影} \longrightarrow \text{确认} \longrightarrow \text{建构} \longrightarrow \text{看见} \longrightarrow \text{生产} \longrightarrow \text{验证})$$

---

## 2. Human / AI Boundary (Non-Negotiable)

- **Human Responsibility**: Intent, judgment, decisions, difference evaluation (Accept / Reject / Uncertain), final confirmation. Humans communicate in natural language and **never directly edit raw spec trees**.
- **AI Capability**: Discover, question, explain, generate, suggest, transform, check, and highlight differences. **AI never possesses final decision authority.**
- **Difference ≠ Error**: A difference between specification and implementation is not automatically a defect; humans judge whether a difference is accepted, rejected, or uncertain. Do not attempt to force *Zero Difference*.

---

## 3. Architecture & Workspace Expectations

- **`.AsWish/`** is the project-local specification workspace.
- **`protocol/`** defines Schemas, state machines, invariants, and reader expectations.
- **`src/core/`** must stay independent from UI concerns.
- **`src/services/`** coordinates parsing, storage, rendering, LLM calls, candidate ingest, and decisions.
- **`src/app/`**, **`src/providers/`**, and **`src/controllers/`** are application/UI integration layers.

---

## 4. Engineering Principles

- **Traceability**: Every generated node, relation, decision, and issue must point back to source evidence or an explicit human decision.
- **Fallibility**: No generated specification is permanently frozen; accepted nodes become stale when source evidence changes.
- **Orthogonal States**: `gen_status` (pending/generated/failed) and `review_status` (pending/accepted/rejected/locked) must remain separated.
- **Partial Success**: Failure in one parser, tree, LLM call, or validation step must not crash or block unrelated readable facts.
- **Least-Privilege Context**: Provide the smallest sufficient context pack for AI operations; never dump entire workspaces into prompts unnecessarily.
- **Stateless Deliverable**: Keep changes and deliverables clean, self-contained, and devoid of transient meta-commentary.

---

## 5. Required Checks Before Submitting Changes

- Validate changed JSON schemas against `protocol/schemas/` if schemas were modified.
- Run DUnitX test suite (`tests/_build_tests.bat && AsWish.Tests.exe`) when Delphi units are modified.
- Confirm zero secrets, API keys, tokens, local credentials, or private project data are committed.
- Confirm changes do not weaken traceability, evidence requirements, or documentation SSOT.
