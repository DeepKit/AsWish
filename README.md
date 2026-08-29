# DeepSpec

DeepSpec is an open-source, AI-native specification tool that provides a **"What You See Is What You Get" (WYSIWYG)** requirement and architecture model for software development.

It transforms project materials (code, documentation, user stories, UI forms) into structured, traceable, and verifiable multi-projection trees (`.deepspec/`) so humans and AI agents share a single source of truth before and during code generation.

```text
Project materials (code / docs / UI)
        ↓
    DeepSpec CTF Analysis
        ↓
  .deepspec/ Structured Projections
    ├── function-tree.yaml (Behavior)
    ├── module-tree.yaml   (Architecture)
    ├── view-tree.yaml     (UI/UX)
    └── data-tree.yaml     (Data & Persistence)
        ↓
  Interactive HTML Visualizer & JS Bridge Review
        ↓
  Frozen Spec Snapshot / SPW Acceptance Baseline
```

---

## Key Features

- **Four Projections**:
  - `function-tree`: What the system should do (capabilities, sub-features, requirements).
  - `module-tree`: Where the behavior lives (units, components, namespaces).
  - `view-tree`: What users interact with (forms, windows, visual controls).
  - `data-tree`: What data exists, persists, moves, and migrates (models, tables, DTOs).
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
SPEC.md                           DeepSpec protocol specification overview
protocol/                         Machine-readable JSON Schemas and conformance tests
src/                              Delphi/VCL desktop GUI and services implementation
  ├── app/                        Shell form, main window, commands, localization
  ├── controllers/                Workflow coordination and state transitions
  ├── core/                       Parsers, hash, validation, config, logger, UI contracts
  ├── models/                     Domain entities, nodes, issues, enums
  ├── providers/                  Structure, MainView, Inspector providers
  └── services/                   Scanner, tree builder, spec store, render, LLM
cli/                              Headless CLI executable (DeepSpec.CLI.dpr)
tests/                            DUnitX automated test suite (113 test cases)
docs/                             Methodology, protocol, and design guides
```

---

## Desktop Application (Delphi / Win64)

### Prerequisites

- Embarcadero Delphi / RAD Studio 13.1 (or 12.x / 11.x) with `dcc64` (Win64 target).
- Microsoft Edge WebView2 Runtime (for interactive HTML preview).

### Build Instructions

```bat
:: 1. Build Main GUI application -> bin\DeepSpec.exe
_build.bat

:: 2. Build and run automated test suite (113 unit tests)
cd tests && _build_tests.bat && DeepSpec.Tests.exe

:: 3. Build Headless CLI -> cli\bin\DeepSpec.CLI.exe
cd cli && _build_cli.bat
```

### First Run

1. Launch `bin\DeepSpec.exe` — the user interface automatically matches the system language (`zh-CN`, `zh-TW`, or `en-US`).
2. Go to **Tools → Setup LLM (ModelScope)** to configure your API key and preferred model.
3. Select a project folder from the directory panel and click **Visualize**.
4. The interactive dashboard (`index.html`) opens in the center view; spec trees and scan logs update in real time.

---

## Headless CLI Usage

```bat
DeepSpec.CLI init <dir>                      :: Initialize a fresh .deepspec directory
DeepSpec.CLI scan <dir>                      :: Scan project codebase and build 4 trees
DeepSpec.CLI generate <dir>                  :: Export AI generation prompt pack
DeepSpec.CLI validate <dir>                  :: Validate .deepspec YAML consistency
DeepSpec.CLI render <dir>                    :: Re-render HTML review pages
DeepSpec.CLI health <dir> [--json]           :: Output health metrics snapshot
DeepSpec.CLI decisions apply <dir>           :: Promote pending decisions to formal tree states
DeepSpec.CLI bundle apply <dir> <id> <act>   :: Batch accept or reject a bundle
DeepSpec.CLI ingest <dir> <candidate.yaml>   :: Validate and merge candidate nodes
```

---

## Protocol & Specification (L0 Layer)

The DeepSpec protocol is defined in `SPEC.md` and `protocol/`. It is licensed under Apache-2.0 and strictly language-agnostic. Any tool, editor, or autonomous agent can read, validate, or generate `.deepspec/` worktrees.

### Standalone Cold-Environment Initialization

In clean environments without Delphi compiler tools, initialize a conforming `.deepspec/` workspace directly using Python (standard library only, zero third-party dependencies):

```bash
python protocol/tools/init_workspace.py /path/to/project --project-name "MyProject"
```

Python readers are available in `protocol/readers/python/` for programmatic tree access.

---

## Theoretical Foundations & Statutory Attribution

DeepSpec and its `.deepspec/` specification protocol embody and implement proprietary theoretical architectures created and authored by **付毅 (Fuyi)**:

- **Differential Monism (DM, 差异一元论)**: Foundational ontology of difference replacing substance ontology. Academic DOI: [10.5281/zenodo.19852505](https://doi.org/10.5281/zenodo.19852505).
- **Attributive Set Transition Ontology (ASTO, 属集变迁存在论)**: Multi-state phase transitions, structural boundaries, and formal encoding. Academic DOI: [10.5281/zenodo.19856467](https://doi.org/10.5281/zenodo.19856467).
- **Output-Driven Development (ODD, 产出物驱动开发)**: Engineering and governance discipline mandating frozen specification deliverables and deterministic gates before production.
- **Problem Formulation Modeling (PFM, 前线显影层)**: Front-line intent modeling methodology that uncovers latent constraints and establishes verifiable acceptance criteria.

Canonical Theory Source Repository: `D:\_Progs\一元论\`  
Upstream Governance Contract: `PC-20260828-DeepSpec-OpenSource`

See [NOTICE](NOTICE) for complete statutory attribution and licensing terms under Apache License 2.0 Section 4(d).

---

## License

DeepSpec is released under the [Apache-2.0 License](LICENSE).
Copyright 2026 付毅 (Fuyi) and BetterCiv Contributors.
