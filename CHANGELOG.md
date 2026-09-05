# Changelog

All notable changes to the **AsWish** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-05

### Added
- **First Closed Loop Complete Cycle**:
  - Full end-to-end flow: Human Intent -> Candidate Ingest -> ChangeSet Review & Decision -> Accepted Baseline -> External Coding Agent / Implementation -> Implementation Evidence -> Structural Difference -> Human Judgment -> Revision / Evolution Dual Exits.
- **Intent Layer & ChangeSet Ingest (WO-20260903-0027A - 0027E)**:
  - Natural-language intent recording (`AsWish.CLI intent`).
  - Structured ChangeSet generation and review (`AsWish.CLI changeset`).
  - Candidate node validation and merging (`AsWish.CLI ingest`).
  - Decision logging in `.AsWish/decisions/requirement-decisions.yaml`.
- **Accepted Baseline & Integrity Dual Gates (WO-20260903-0027E)**:
  - Multi-projection baseline snapshot freezing (`B-0001`, `B-0002`, `B-0003`).
  - SHA-256 hash verification on content and relation trees (Gate 1).
  - Multi-tree consistency, reference integrity, and orphan detection validation (Gate 2).
  - CLI commands `baseline list` and `baseline verify`.
- **Visual Baseline Preview & Confirmation (WO-20260830-0028)**:
  - Visual Preview wireframe generation (`visual-preview.html`).
  - Accepted Visual Baseline confirmation (`AsWish.CLI visual confirm`).
- **Implementation Evidence Collection (WO-20260903-0027F)**:
  - Codebase AST scanning (Delphi `.pas`/`.dfm` parser + multi-language heuristic parser).
  - Build artifact and automated test execution log collection.
  - Evidence serialization to `.AsWish/evidence/implementation-evidence.yaml` with source file checksums.
  - CLI command `AsWish.CLI evidence collect`.
- **Structural Difference Engine (WO-20260903-0027G)**:
  - Deterministic difference calculation comparing Accepted Baseline against Implementation Evidence.
  - Structural categorization: Added, Modified, Removed, and Unmatched items across Function, Module, View, and Data projections.
  - Generation of `.AsWish/difference/difference.yaml` and interactive `.AsWish/html/difference.html`.
  - CLI command `AsWish.CLI difference`.
- **Revision / Evolution Dual Exits (WO-20260903-0027H, 0027R1 - 0027R3)**:
  - Human judgment recording (`acceptable`, `unacceptable`, `unresolved`) with monotonic decision IDs (`dec-0001` .. `dec-0005`).
  - Revision workflow on `unacceptable`: Rejected difference prompts B' user intent, triggering change set and baseline iteration.
  - Evolution workflow on `acceptable`: Freezes current implementation reality into next baseline (`B-0003`) with rigorous `parent_baseline_id: "B-0002"` lineage tracking.
  - CLI commands `AsWish.CLI judge` and `AsWish.CLI evolve`.
- **Multi-Project Batch Dogfood Automation (WO-20260905-1130-0029 P1)**:
  - Automated PowerShell test harness (`scripts/run_batch_dogfood.ps1`, `scripts/TestProjects.ps1`, `scripts/BatchDogfoodCommon.ps1`).
  - Headless batch execution across 3 heterogeneous domain projects (`proj_calc_tool`, `proj_task_service`, `proj_data_pipeline`) with 100% pass rate and physical sites retained.
- **GUI Decision Surface & WebView2 Integration (WO-20260905-1130-0029 P2)**:
  - Thin controller pass-through methods in `TAsWishController` for difference, judge, evolve, and decisions.
  - Interactive difference review and action buttons (`acceptable` / `unacceptable` / `evolve`) in WebView2 interface.
  - Read-only Requirement Decisions audit trail (`.AsWish/html/decisions.html`).
  - 100% byte-for-byte isomorphic state and file structure with Headless CLI.
- **Single Source of Version & Packaging (WO-20260905-1130-0029 P3)**:
  - Version single source in `src/core/AsWish.Version.pas` (`ASWISH_VERSION = '0.1.0'`).
  - CLI `--version` and `-v` flags.
  - Automated release packaging script `scripts/package_release.ps1` producing `dist/AsWish-v0.1.0-win64.zip`.
