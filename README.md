# AsWish

**As I Wish** is an open, free, theory-driven empirical system for AI-native software development. This repository is **AsWish** — its engineering implementation (Delphi/VCL Desktop + headless CLI), with **`.AsWish/`** as the project-level protocol workspace.

Core research questions:

> **Are we still building the same thing?**
> **Where did the difference enter?**

AI agents can build software faster than humans can continuously understand it. As I Wish makes what should be built visible *before* the agent builds it, and makes what was built directly comparable against what was confirmed *afterward*. Its goal is not to eliminate difference, but to make the key differences in software development **discoverable, perceivable, traceable, and confirmable**.

It transforms project materials (code, documentation, user stories, UI forms) into structured, traceable, and verifiable multi-projection trees (`.AsWish/`) so humans and AI agents share a single source of truth before and during code generation.

### Identity Layers

```text
Difference Monism        Theory
        ↓ theory system
As We Wish               narrative / co-construction engine
        ↓ theory-derived
As I Wish                empirical product
        ↓
AsWish                   engineering implementation (this repo)
        ↓
.AsWish/                 project workspace / protocol carrier
        ↓
Actual Software
```

### Product Main Chain

```text
Problem Manifestation → Decision Confirmation → Shared Construction → Specification
→ Visual Representation → Human Confirmation → Agent Development → Implementation
→ Implementation Evidence → Difference Detection → Difference Confirmation → Feedback
```

Compressed: **显影 → 确认 → 建构 → 看见 → 生产 → 验证**

---

## Key Features

- **Four Projections**: the same software intent projected across four dimensions — not four requirement documents:
  - `function-tree`: What the system should do (behavior projection).
  - `module-tree`: Where the behavior lives (architecture projection).
  - `view-tree`: What users interact with (interface projection).
  - `data-tree`: What data exists, persists, moves, and migrates (data projection).
- **Visual Continuity from intent to implementation**: the visual object confirmed before development and the actual product delivered after development should be directly comparable, with the human judging whether they are still the same thing. This is *not* a WYSIWYG editor — humans never directly edit the spec; they communicate in natural language.
- **Fog of War Exploration (CTF Method)**: Clear separation between verified facts, AI-inferred candidates, and foggy/unknown requirement frontiers.
- **Interactive Visualizer**: Built-in HTML renderer (WebView2) with responsive dashboards, interactive trees, and JS Bridge for human decision confirmation.
- **Standalone & Lightweight**: Zero external database dependencies; configuration and state persist locally in standard JSON format.
- **OpenAI-Compatible LLM Integration**: Directly connects to ModelScope, OpenAI, DeepSeek, Qwen, Ollama, and other compatible LLM endpoints.
- **Headless CLI & VCL Desktop GUI**: Run scans, validation, and rendering headlessly in CI/CD or interactively on the desktop.

---

## Repository Map

```text
LICENSE                           Apache-2.0 License
README.md                         Public project documentation
SPEC.md                           AsWish protocol specification overview
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
```

---

## Desktop Application (Delphi / Win64)

### Prerequisites

- Embarcadero Delphi / RAD Studio 13.1 (or 12.x / 11.x) with `dcc64` (Win64 target).
- Microsoft Edge WebView2 Runtime (for interactive HTML preview).

### Build Instructions

```bat
:: 1. Build Main GUI application -> bin\AsWish.exe
_build.bat

:: 2. Build and run automated test suite
cd tests && _build_tests.bat && AsWish.Tests.exe

:: 3. Build Headless CLI -> cli\bin\AsWish.CLI.exe
cd cli && _build_cli.bat
```

### First Run

Follow [`docs/AsWish-用户上手说明-v1.md`](docs/AsWish-用户上手说明-v1.md) for the complete first-run path, LLM setup, four-projection review, and headless CLI workflow.

---

## Headless CLI Usage

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

---

## Protocol & Specification (L0 Layer)

The AsWish protocol is defined in `SPEC.md` and `protocol/`. It is licensed under Apache-2.0 and strictly language-agnostic. Any tool, editor, or autonomous agent can read, validate, or generate `.AsWish/` worktrees.

### Standalone Cold-Environment Initialization

In clean environments without Delphi compiler tools, initialize a conforming `.AsWish/` workspace directly using Python (standard library only, zero third-party dependencies):

```bash
python protocol/tools/init_workspace.py /path/to/project --project-name "MyProject"
```

Python readers are available in `protocol/readers/python/` for programmatic tree access.

---

## Theoretical Foundations & Statutory Attribution

**As I Wish is a theory-driven empirical product — it is not a proof of any theory.** Real usage, real projects, real failures, implementation deviations, and external feedback are all research evidence, and reality is allowed to challenge the theory back.

### Identity Layers

- **Difference Monism (DM)**: the theoretical body — difference, non-arbitrary constraint, structure, boundary, inherited traces.
- **As We Wish**: the narrative / co-construction engine derived from DM. "述事" here means organizing human problems, intents, decisions, and shared understanding into structures that can keep being developed — not story generation.
- **As I Wish**: the empirical product.
- **AsWish / `.AsWish/`**: the engineering implementation and its project workspace.

### Theoretical Sources

AsWish and its `.AsWish/` specification protocol embody and implement proprietary theoretical architectures created and authored by **付毅 (Fuyi)**:

- **Difference Monism (DM, 差异一元论)**: Foundational ontology of difference replacing substance ontology. Academic DOI: [10.5281/zenodo.19852505](https://doi.org/10.5281/zenodo.19852505).
- **Attributive Set Transition Ontology (ASTO, 属集变迁存在论)**: Multi-state phase transitions, structural boundaries, and formal encoding. Academic DOI: [10.5281/zenodo.19856467](https://doi.org/10.5281/zenodo.19856467).
- **Output-Driven Development (ODD, 产出物驱动开发)**: Engineering and governance discipline mandating frozen specification deliverables and deterministic gates before production. Academic DOI: [10.5281/zenodo.20024964](https://doi.org/10.5281/zenodo.20024964).
- **Constructive Traceable Fallibilist Specification (CTF, 建构追溯可谬规格方法论)**: Pre-specification layer of ODD (theory source `ODD.P03`) converting unstable human-machine requirements into traceable, reviewable, defeasible, freezable specification snapshots. Academic DOI pending (preprint prepared 2026-08-29). Claim strength C2.
- **Problem Manifestation Methodology (PFM, 前线显影层)**: Front-line intent modeling methodology that uncovers latent constraints and establishes verifiable acceptance criteria. Prior public record: [10.5281/zenodo.19856528](https://doi.org/10.5281/zenodo.19856528) (LMM v1.0, 2026-04-28).

Canonical Theory Source Repository: `D:\_Progs\一元论\`  
Upstream Governance Contract: `PC-20260828-AsWish-OpenSource`

### Terminology

- **Decision Confirmation** is the product mechanism for resolving unresolved gaps one key decision at a time, evidence-first. External practices (Wayfinder / Grill-me) are inspirations and compatible working styles — not native theory of Difference Monism, and not the product's formal name for this mechanism.
- `fog_state` remains a pending-attribution engineering construct; protocol `invariants` remain weakly anchored / pending confirmation.
- Cross-projection links are carried by the **CTF Semantic Bundle** (full qualified term preserved).

See [NOTICE](NOTICE) for complete statutory attribution and licensing terms under Apache License 2.0 Section 4(d).

---

## License

AsWish is released under the [Apache-2.0 License](LICENSE).
Copyright 2026 付毅 (Fuyi) and BetterCiv Contributors.
