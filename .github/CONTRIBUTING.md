# Contributing to AsWish

> Authoritative product identity: [`ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md)  
> Documentation governance: [`ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md)

AsWish is the open engineering layer between **Human ↔ AI Coding Agent ↔ Software Implementation**. It keeps what humans and agents confirmed visible before development, and makes what was built comparable against it afterward — every difference is visible, traceable, and judged by a human.

AsWish is **not** a spec tool, spec editor, or coding agent.

Core research questions:
- **Are we still building the same thing?**
- **Where did the difference enter?**

The open source mission is: **Test my claim.** (Empowering third-party developers to download, run, inspect, replicate, and challenge our engineering and theoretical claims).

---

## 1. Contribution Priorities

1. **Make project facts easier to inspect**: improve scanners, parsers, and representations across four projections (`function`, `module`, `view`, `data`).
2. **Make specifications more traceable**: improve evidence linking, hash checking, and CTF Semantic Bundles.
3. **Make human review more consequential**: enhance visual review, natural language intent capture, and explicit decision write-backs.
4. **Make accepted baselines verifiable**: advance difference detection between accepted visual/structural baselines and actual implementation outputs.
5. **Keep protocol readers simple and robust**: ensure language-agnostic conformance and backward compatibility in `protocol/`.

---

## 2. Before You Start

- Read [`ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md) for product identity and boundaries.
- Read [`ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md) for document authority and single-source-of-truth rules.
- Read [`SPEC.md`](../SPEC.md) and [`protocol/README.md`](../protocol/README.md) for protocol expectations.
- Read [`docs/CTF.md`](../docs/CTF.md) for the CTF method.
- Prefer small, well-verified pull requests over massive refactors.
- Do not mix broad theoretical claims with routine engineering changes.

---

## 3. Engineering & Boundary Guidelines

- **Human / AI Boundary**: Humans judge and decide using natural language; humans never directly edit raw spec trees. AI assists and discovers, but never makes final decisions.
- **Difference ≠ Error**: Do not assume differences are always defects; provide paths for human review (Accept / Reject / Uncertain).
- **Stateless Deliverables**: Deliver clean, self-contained code and documents without temporary process notes.

---

## 4. Security & Privacy

- Never commit API keys, cookies, tokens, private project data, local database files, or generated binaries.
- If an example needs real-world context, anonymize all identifiers first.
