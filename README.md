# AsWish

> **Are we still building the same thing?**  
> **Where did the difference enter?**

**As I Wish** is an open, free, theory-driven empirical system for AI-native software development. This repository is **AsWish** — its reference engineering implementation (Delphi/VCL Desktop + Headless CLI), with **`.AsWish/`** as the project-level protocol workspace.

AsWish is **not** a spec tool, spec editor, or AI coding tool. It is the open engineering layer between **Human ↔ AI Coding Agent ↔ Software Implementation**.

> Authoritative product identity: [`ASWISH-PRODUCT-IDENTITY.md`](ASWISH-PRODUCT-IDENTITY.md)  
> Documentation governance: [`ASWISH-DOCUMENTATION-GOVERNANCE.md`](ASWISH-DOCUMENTATION-GOVERNANCE.md)  
> Protocol specification: [`SPEC.md`](SPEC.md) · Theory attribution: [`NOTICE`](NOTICE)

---

## The Real-World Problem

AI coding agents (Codex, Claude Code, Cursor, Gemini CLI, and others) can write and refactor code at superhuman speed. But software production speed has outpaced human comprehension:

> *AI wrote the code, all tests pass — why is the delivered software still not what we actually wanted?*

The critical breakdown is not whether the AI can generate syntax or follow an ambiguous PRD. The breakdown is:
1. **Did humans and AI ever reach a shared, observable understanding of what was being built *before* code was generated?**
2. **After code was generated, can humans verify whether the actual software matches that shared understanding, and where the differences entered?**

AsWish makes what should be built visible and confirmable *before* development, and makes the actual software comparable against implementation evidence *afterward*.

---

## Identity Layers

AsWish is Level 3 of a single, unified theory–product–engineering system (not four separate products):

```text
Level 0
Difference Monism (差异一元论)          Foundational ontology (Difference + Non-arbitrary constraint)
        ↓
Level 1
As We Wish                           Theory / Method layer (Human-AI co-construction & shared understanding)
        ↓
Level 2
As I Wish                            Product concept ("Is the delivered software still what I really wanted?")
        ↓
Level 3
AsWish                               Engineering implementation (Delphi/VCL Desktop + Headless CLI, this repo)
        ↓
Project Workspace
.AsWish                              Project-local traceable workspace / protocol carrier
```

---

## Core Product Pipeline

```text
Problem Manifestation ──► Decision Confirmation ──► Co-construction ──► Specification
         │
         ▼
Visual Baseline ──► Agent Development ──► Actual Implementation ──► Implementation Evidence
         │
         ▼
    Difference ──► Human Confirmation ──► Revision / Feedback Loop
```

Compressed workflow:

$$\textbf{Manifest} \longrightarrow \textbf{Confirm} \longrightarrow \textbf{Construct} \longrightarrow \textbf{See} \longrightarrow \textbf{Build} \longrightarrow \textbf{Verify}$$
$$(\text{显影} \longrightarrow \text{确认} \longrightarrow \text{建构} \longrightarrow \text{看见} \longrightarrow \text{生产} \longrightarrow \text{验证})$$

---

## Core Principles

- **Human / AI Boundary**:
  - **Humans** own intent, judgment, decisions, difference acceptance/rejection, and final confirmation. Humans communicate in natural language and *never* directly edit raw specification trees.
  - **AI** discovers, questions, generates, transforms, and highlights differences. AI *never* possesses final decision authority.
- **Difference ≠ Error**:
  - A difference between initial understanding and final implementation is not automatically a bug. Humans may review a difference and conclude *"this is actually better"*.
  - AsWish does not pursue *Zero Difference*. It pursues **Difference made visible, traceable, and judgeable**.
- **Visual Baseline (WYSIWYG)**:
  - What humans and agents confirm visually *before* development and the actual product produced *after* development are directly comparable through evidence. This is *not* a WYSIWYG spec editor.
- **Local-First & Download-and-Run**:
  - Windows Desktop / CLI out-of-the-box. Zero forced account registration, cloud sign-in, SaaS workspace, or SSO.
- **Open Source Mission**:
  - Open source here is not merely "free code". Its core message is:
    $$\textbf{Test my claim.}$$
    Empowering any third-party developer to download, run, inspect, replicate, challenge, and falsify the engineering and theoretical claims.

---

## Key Features

- **Four Projections**: The same intent projected across four weakly-coupled dimensions:
  - `function-tree`: What the system should do (behavior projection).
  - `module-tree`: Where the behavior lives (architecture projection).
  - `view-tree`: What users interact with (interface projection).
  - `data-tree`: What data exists, persists, moves, and migrates (data projection).
- **CTF Semantic Bundles**: Cross-projection grouping binding the same requirement across all trees into a single reviewable unit.
- **Fog of War & Frontier Exploration**: Explicit tracking of verified facts vs candidate inferences vs unmapped requirement frontiers (`clear`, `misty`, `foggy`, `unknown_unknowns`).
- **Interactive Visualizer & Decision Capture**: Built-in WebView2 renderer with interactive tree inspection and JS Bridge writing decisions directly back to `.AsWish/decisions/`.
- **Standalone & Lightweight**: Zero external database dependencies; local JSON/YAML persistence.
- **OpenAI-Compatible LLM Integration**: Pluggable backend for ModelScope, OpenAI, DeepSeek, Qwen, Ollama, and compatible endpoints.
- **Headless CLI & VCL Desktop GUI**: Run scans, validations, and renders in CI/CD headlessly or interactively on Windows.

---

## Target Users & First-Stage Goals

### User Circles
1. **Primary**: Heavy AI Coding Agent users (Codex, Claude Code, Cursor, Gemini CLI, etc.).
2. **Secondary**: Indie developers and small teams.
3. **Tertiary**: Product leads, engineering managers, and AI-SE researchers.
4. **Quaternary**: Enterprise engineering teams (without adding enterprise complexity prematurely).

### First-Stage Empirical Metrics
The first stage focuses on empirical validation, not commercialization or star counts:
- Developers who complete a first real experiment;
- Real projects using `.AsWish/` workspaces;
- Concrete difference cases discovered, tracked, and judged;
- User-reported failures, counterexamples, and critiques to drive theory revision.

---

## Repository Map

```text
LICENSE                           Apache-2.0 License
NOTICE                            Statutory theory attribution and copyright notice
README.md                         Public project entry point
SPEC.md                           AsWish protocol specification overview
ASWISH-PRODUCT-IDENTITY.md        Authoritative product identity SSOT
ASWISH-DOCUMENTATION-GOVERNANCE.md Authoritative documentation governance SSOT
protocol/                         Machine-readable JSON Schemas and conformance tests
src/                              Delphi/VCL desktop GUI and services implementation
  ├── app/                        Shell form, main window, commands, localization
  ├── controllers/                Workflow coordination and state transitions
  ├── core/                       Parsers, hash, validation, config, logger, UI contracts
  ├── models/                     Domain entities, nodes, issues, enums
  ├── providers/                  Structure, MainView, Inspector providers
  └── services/                   Scanner, tree builder, spec store, render, LLM
cli/                              Headless CLI executable (AsWish.CLI.dpr)
tests/                            DUnitX automated test suite
docs/                             Methodology, protocol, and design guides
installer/                        Inno Setup packaging script
```

---

## Quick Start (Desktop & CLI)

### Desktop Application (Delphi / Win64)

1. **Prerequisites**:
   - Embarcadero Delphi / RAD Studio 13.1 (or 12.x / 11.x) with `dcc64`.
   - Microsoft Edge WebView2 Runtime.
2. **Build**:
   ```bat
   :: 1. Build Main GUI application -> bin\AsWish.exe
   _build.bat

   :: 2. Build and run test suite
   cd tests && _build_tests.bat && AsWish.Tests.exe

   :: 3. Build Headless CLI -> cli\bin\AsWish.CLI.exe
   cd cli && _build_cli.bat
   ```
3. **First Run Guide**: Follow [`docs/AsWish-用户上手说明-v1.md`](docs/AsWish-用户上手说明-v1.md).

### Headless CLI Commands

```bat
AsWish.CLI init <dir>                      :: Initialize a fresh .AsWish directory
AsWish.CLI scan <dir>                      :: Scan project codebase and build 4 trees
AsWish.CLI generate <dir>                  :: Export AI generation prompt pack
AsWish.CLI validate <dir>                  :: Validate .AsWish YAML consistency
AsWish.CLI render <dir>                    :: Re-render HTML review pages
AsWish.CLI health <dir> [--json]           :: Output health metrics snapshot
AsWish.CLI decisions apply <dir>           :: Promote pending decisions to formal tree states
AsWish.CLI bundle apply <dir> <id> <act>   :: Batch accept or reject a bundle
AsWish.CLI ingest <dir> <candidate.yaml>   :: Validate and merge candidate nodes
```

### Standalone Cold-Start (Zero Delphi Dependencies)

In environments without Delphi compiler tools, initialize a standard `.AsWish/` workspace directly using Python (standard library only):

```bash
python protocol/tools/init_workspace.py /path/to/project --project-name "MyProject"
```

Python readers are available in `protocol/readers/python/` for programmatic tree access.

---

## Theoretical Foundations & Statutory Attribution

**AsWish is a theory-driven empirical engineering system — it is not a proof of any theory.** Real usage, real failures, and empirical deviations are valid research evidence that actively informs and challenges the theory.

### Theoretical Sources
AsWish embodies theoretical achievements created and authored by **付毅 (Fuyi)**:

1. **Difference Monism (DM, 差异一元论)**: Foundational ontology replacing substance ontology with differential ontology. Academic DOI: [10.5281/zenodo.19852505](https://doi.org/10.5281/zenodo.19852505).
2. **Attributive Set Transition Ontology (ASTO, 属集变迁存在论)**: Multi-state phase transitions, structural boundaries, and formal encoding. Academic DOI: [10.5281/zenodo.19856467](https://doi.org/10.5281/zenodo.19856467).
3. **Output-Driven Development (ODD, 产出物驱动开发)**: Engineering discipline mandating frozen specification deliverables and deterministic gates before production. Academic DOI: [10.5281/zenodo.20024964](https://doi.org/10.5281/zenodo.20024964).
4. **Constructive Traceable Fallibilist Specification (CTF, 建构追溯可谬规格方法论)**: Pre-specification layer of ODD (theory source `ODD.P03`) converting human-AI intent into traceable, reviewable, defeasible specification snapshots. Academic DOI pending (preprint prepared 2026-08-29). Claim strength **C2**.
5. **Problem Manifestation Methodology (PFM, 前线显影层)**: Front-line intent modeling methodology uncovering latent constraints and acceptance criteria. Prior public record: [10.5281/zenodo.19856528](https://doi.org/10.5281/zenodo.19856528).

Canonical Theory Source Repository: `D:\_Progs\一元论\`  
Upstream Problem Contract: `PC-20260828-AsWish-OpenSource`

### Terminology Notes
- **Decision Confirmation** is the native product mechanism for resolving gaps one decision at a time. External practices (Wayfinder / Grill-me) are external inspirations.
- `fog_state` is a pending-attribution engineering construct; `invariants` remain weakly anchored.
- Cross-projection links are carried by the **CTF Semantic Bundle** (full qualified term preserved).

See [`NOTICE`](NOTICE) for complete statutory attribution and licensing terms under Apache License 2.0 Section 4(d).

---

## License

AsWish is released under the [Apache-2.0 License](LICENSE).  
Copyright 2026 付毅 (Fuyi) and BetterCiv Contributors.
