# WO-20260829-001 Contract Brief

## Objective

Close the approved DeepSpec user-view gaps in T1–T3: make `data-tree` ingestible and generatable for non-Delphi projects, align data-tree validation and persistence with the other projections, unify documentation around four projections, complete the CLI usage index, and provide a first-run guide.

## Scope

- T1: `CandidateIngest`, `TreeBuilder`, `Validation`, `SpecStore`, controller/CLI data-tree plumbing, and DUnitX coverage for ingest, generic generation, persistence, and rendering.
- T2: historical three-tree mapping markers, current documentation indexes, and the CLI header usage list.
- T3: one authoritative user onboarding document linked from the public README and docs index.
- Out of scope: unrelated business logic, deletion of historical documents, credentials, and strategic/product-boundary changes.

## Acceptance

- Data candidates with valid `data-` IDs are accepted, routed, merged, and persisted; invalid IDs are rejected and same-ID merges update data fields while preserving human review fields.
- Non-Delphi scans infer data entities from supported configuration/type/data files; when none are inferable, the data tree contains a low-confidence fogged root and placeholder.
- Data kinds and data-specific fields are validated; data-tree read/write round-trips preserve the supported schema fields; rendered data-tree output is verifiable.
- Documentation points to `SPEC.md` as the four-projection source of truth and the CLI header lists all nine commands.
- Main build, CLI build, and full DUnitX suite pass with raw output files under `WO/evidence/`.

## Contract digest

`sha256(work-order): 117fa315fecdba72c684c64c2abef06f11fc63cec75aaf8f870f8476fd0e01d3`
