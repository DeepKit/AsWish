# AsWish Empirical Facility Documents v0.1

This package is a **draft architecture-review set** for turning AsWish into an empirical facility for the theory/method layer.

It is intentionally not a replacement for the existing AsWish document system.

## Included documents

```text
00-EMPIRICAL-FACILITY-CHARTER.md
01-THEORY-ENGINEERING-MAP.md
02-DOMAIN-MODEL.md
03-PROTOCOL-SPEC.md
04-OBSERVABILITY-SPEC.md
05-INTERACTION-SPEC.md
06-ARCHITECTURE-CONTRACT.md
07-EVIDENCE-SPEC.md
08-DOGFOOD-PROTOCOL.md
09-EMPIRICAL-RESEARCH-PROTOCOL.md
```

## Intended relationship

```text
Theory / Method
      ↓
Empirical Facility Charter
      ↓
Theory → Engineering Map
      ↓
Domain / Protocol / Observable / Architecture
      ↓
Evidence
      ↓
Dogfood
      ↓
Empirical Research Loop
```

## Important review posture

These documents are **proposals**, not current authoritative project truth.

An architect should determine:

- which concepts already exist in current documents;
- which documents should be merged;
- which should become appendices;
- which fields already exist in the actual schema;
- which proposed structures would be redundant;
- which items should remain research governance rather than engineering specification.

## Strong constraint

The package must not be used to silently introduce:

```text
new proposal lifecycle
new decision system
new visual entity system
new baseline entity
new evidence database
```

unless existing architecture is proven insufficient and the addition is explicitly approved.

## Suggested integration order

```text
1. Charter
2. Theory → Engineering Map
3. Existing document inventory / conflict matrix
4. Domain + Protocol consolidation
5. Observable / Interaction consolidation
6. Evidence + Dogfood integration
7. Empirical Research notes
```
