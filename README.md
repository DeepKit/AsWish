# AsWish

> **Are we still building the same thing?**  
> **Where did the difference enter?**

**As I Wish** is an open, free, theory-driven empirical system for AI-native software development. This repository is **AsWish** — its reference engineering implementation (Delphi/VCL Desktop + Headless CLI), with **`.AsWish/`** as the project-level protocol workspace.

AsWish is **not** a spec tool, spec editor, or AI coding tool. It is the open engineering layer between **Human ↔ AI Coding Agent ↔ Software Implementation**.

> **开发随心 · 六脉神剑**：AsWish 不帮你「避免一切差异」，而是让你在差异恒常存在的 AI Coding 世界里，**自由地开发、清楚地看见、自己地判断、随时地调整**。六脉（显影 → 对齐 → 结构化 → 差异 → 调整 → 积累）见 [`docs/17.产品-开发随心的六脉神剑与用户价值.md`](docs/17.产品-开发随心的六脉神剑与用户价值.md)。

> Authoritative product identity: [`docs/01.产品-AsWish产品身份与愿景蓝图.md`](docs/01.产品-AsWish产品身份与愿景蓝图.md)  
> Documentation governance: [`docs/13.治理-文档治理与工程纪律.md`](docs/13.治理-文档治理与工程纪律.md)  
> Protocol specification: [`docs/05.协议-AsWish协议基线.md`](docs/05.协议-AsWish协议基线.md) · Theory attribution: [`NOTICE`](NOTICE)

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

## 开发随心的六脉（能力，不是功能模块）

六脉是六种「随心开发能力」，不是六个软件模块。状态标注：**[FACT]** 已实现 · **[PLAN]** 计划中 · **[VISION]** 愿景。

| 六脉 | 你获得的能力 | 状态 |
|---|---|---|
| ① 显影 | 想说就说，不必先想清楚——「这里感觉不太对」也能被承载并逐渐显形 | [FACT] |
| ② 对齐 | 所见即所想——你说「简单一点」，AsWish 把它变成能看的东西供你确认 | [FACT] |
| ③ 结构化 | 机器承接的是你确认过的东西，不是你的只言片语 | [FACT] |
| ④ 差异 | 开发完看见「实际做的」与「你确认的」之间发生了什么变化，而不是猜 | [PLAN] 0027G |
| ⑤ 调整 | 差异出现，你可以说「我喜欢，不改」，或往别处调——主动权在你 | [PLAN] 0027H |
| ⑥ 积累 | 走过的路留下来，成为下一次的剑；别人的路也能帮你提前看清前路 | [VISION] |

底层工程事实 **[FACT]**：四投影树（function/module/view/data）、CTF Semantic Bundles、Fog 状态追踪（`clear`/`misty`/`foggy`/`unknown_unknowns`）、Decision 写回 `.AsWish/decisions/`、Accepted Baseline（内容/关系哈希）、Accepted Visual Baseline（结构线框）、Headless CLI + VCL Desktop GUI、Local-first 无账号、零外部数据库依赖。

> 能力与工程状态的权威对照见 [`docs/17.产品-开发随心的六脉神剑与用户价值.md`](docs/17.产品-开发随心的六脉神剑与用户价值.md) 与 [`docs/07.工程-工程路线与Dogfood验收.md`](docs/07.工程-工程路线与Dogfood验收.md)。

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
AGENTS.md                         AI engineering discipline entry point
protocol/                         Machine-readable JSON Schemas and conformance tests
docs/                             Current documents (9 files, NN.分类-文件名.md, odd numbering)
  ├── 01.产品-AsWish产品身份与愿景蓝图.md    Product identity / vision blueprint / first run
  ├── 03.规范-可见判断与交互规范.md          OJP / Dual-Surface / 0-9 interaction
  ├── 05.协议-AsWish协议基线.md              Protocol baseline (SPEC)
  ├── 07.工程-工程路线与Dogfood验收.md        Engineering roadmap / dual gates / work-order index
  ├── 09.实证-实证设施规程.md                Empirical facility (Test my claim)
  ├── 11.理论-理论归因与CTF.md               Theory attribution / CTF
  ├── 13.治理-文档治理与工程纪律.md           Doc governance / discipline / doc index
  ├── 15.参考-工程与外部参考资料.md           Non-UI impl / external practice / survey reports
  ├── 17.产品-开发随心的六脉神剑与用户价值.md  Product philosophy / six abilities / user value
  ├── AsWish-公众价值层与差异社区理念-v1.md     Future ecosystem (Difference Commons, VISION, unnumbered)
  └── 归档/                                 Pre-consolidation originals (retained, not deleted)
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
3. **First Run Guide**: Follow [`docs/01.产品-AsWish产品身份与愿景蓝图.md`](docs/01.产品-AsWish产品身份与愿景蓝图.md).

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
AsWish.CLI intent <dir> <node-id> <tree> <text>       :: Submit natural-language intent (0027A)
AsWish.CLI changeset <dir> <node-id> <tree> <intent>  :: Generate structured change set (0027B)
AsWish.CLI changeset accept <dir> <reason>            :: Accept change set, freeze Accepted Baseline (0027E)
AsWish.CLI baseline list <dir> / verify <dir> <id>    :: List / verify Accepted Baseline (0027E)
AsWish.CLI visual preview <dir> / confirm <dir> <note>:: Wireframe preview / confirm visual baseline (0028)
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
