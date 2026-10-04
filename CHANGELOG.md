# Changelog

All notable changes to the **AsWish** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-10-04

### Added
- **Visual Capture Content Guard (WO-0076, WO-0079)**:
  - Runtime monochromatic / pure-color blank rejection guard (`SaveBitmapWithContentGuard` in `AsWish.UI.Types.pas`).
  - Emits clear diagnostic warnings (`[CAPTURE-WARN]`) and discards blank PNG evidence, preventing false-positive passes on silent capture failures.
  - Unit tests in `Test.AsWish.GUIDecisions.pas` asserting single-color rejection and multi-color acceptance.
- **GUI Smoke Verification Gate (WO-0071, WO-0073, WO-0074, WO-0077, WO-0078, WO-0087)**:
  - Added `H3.gui-verify-smoke` (`tools/spw-gates/gate_gui_verify_smoke.py`) as a mandatory SPW gate.
  - Directly launches the GUI binary with `--gui-verify` in a clean environment, verifying WebView2 initialization, DOM recovery, and visual capture execution.
  - Hardened with Windows Job Object (`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`) to eliminate lingering orphan processes, safe truncate cleanup avoiding environment delete guards, and configurable 180s timeout.
- **Static Anti-Bypass Pattern Gate (WO-0087)**:
  - Added `H4.bypass-patterns` (`tools/spw-gates/gate_bypass_patterns.py`) and waiver registry (`tools/spw-gates/h4_waivers.json`) to statically audit source code against bypass patterns.
- **In-Repo Reproducible Evidence Generator (WO-0087)**:
  - Added in-repo evidence generation tool (`tools/spw-evidence/generate_evidence.py`) ensuring 100% integrity across stdout text, byte length, and SHA-256 hashes.
- **External Release Boundary Guard (WO-0084, WO-0086, WO-0087)**:
  - Added `H3.external-boundary` (`tools/spw-gates/gate_external_boundary.py`) to prevent internal governance markers or paths from entering release exports.
- **Delayed Readiness Test Fixture (WO-0069, WO-0070, WO-0072)**:
  - Standalone `Sleeper.dpr` fixture and generator script (`tools/gui-verify-fixture/make-fixture.ps1`) for deterministic testing of WebView2 delay switches and timeout handling.

- **Master Quality Gates Runner (WO-0088)**:
  - Added in-repo master quality gate runner (`tools/spw-gates/run_all_gates.py`) dynamically executing all 12 gates registered in `spw-manifest.json`.
  - Built-in guard against unmanaged gate scripts in `tools/spw-gates/` preventing gate drift.
  - Aligned CI pipeline (`.github/workflows/build.yml`) to invoke the master gate runner directly.
- **H4 Bypass Waiver Governance (WO-0089)**:
  - Upgraded waiver ledger (`tools/spw-gates/h4_waivers.json`) with governance metadata (`scope`, `approved_by`, `approved_at`, `expires_at`).
  - Added strict anti-stale assertions (verifying file existence, line bounds, and pattern hit matching), unapproved ongoing waiver rejection, and expiration checks in `gate_bypass_patterns.py`.
- **Open-Source Export & Vendor Drift Gate Registration (WO-0088)**:
  - Formally registered `G.open-source-build` (`gate_open_source_build.py`) and `G.vendored-upstream-drift` (`gate_ehai_vendor_drift.py`) in `spw-manifest.json`.
  - Added `tools/spw-evidence/README.md` and authorized it in `gate_open_source_build.py`.

### Fixed
- **Fail-Closed Progress Logging (WO-0075, WO-0080, WO-0081)**:
  - In `AsWish.MainForm.pas`, step-by-step state progress is flushed to `gui-verify-progress.txt` upon entering and exiting each verification step.
  - Safe truncation and write failure handling: truncate failures fail-closed to prevent mixing stale logs with new runs, and write errors alert without crashing or hanging.
- **Visual Evidence Diagnostics & Encoding (WO-0079)**:
  - Preserved distinct color count in visual diagnostic logs across all screenshot paths.
  - Stripped hidden UTF-8 BOM from progress log files.
- **Console Error Output & Error Codes (WO-0066, WO-0068)**:
  - Output explicit console error messages on `--gui-verify` failure with parent console attachment fallback.
  - Differentiated WebView2 timeout and initialization failure exit codes.
- **CI Workflow Working Directory (WO-0083)**:
  - Fixed relative path traversal in `.github/workflows/build.yml` by explicitly setting `working-directory: ${{ github.workspace }}`.
  - Added pre-flight validation verifying all required manifest gate scripts exist before executing pipeline gates.
- **Project Path Canonicalization (WO-0071)**:
  - Standardized project paths with `TPath.GetFullPath` in `AsWish.Services.Project.pas`.

### Changed
- **Required Gate Coverage (WO-0082, WO-0086, WO-0088)**:
  - `spw-manifest.json` expanded to 12 mandatory gates (`H1.resource-locks`, `H2.compile-build`, `H2.compile-tests`, `H2.unit-tests`, `H3.encoding-guard`, `H3.runtime-autofix`, `H3.deep-ui-test`, `H3.gui-verify-smoke`, `H3.external-boundary`, `H4.bypass-patterns`, `G.open-source-build`, `G.vendored-upstream-drift`).
  - Open-source export gate (`gate_open_source_build.py`) now validates manifest gate script completeness and enforces consistency between working tree and commit HEAD.
- **Ignore Rules Hardening (WO-0084, WO-0086)**:
  - Updated `.gitignore` and `.gitattributes` to explicitly ignore and export-ignore internal governance structures (`.AsWish/`, `.ai-workbench/`, `_repro/`, `_audit_*`).

### Security
- **Credential Sanitization & GitHub PAT Sentinel (WO-0090)**:
  - Sanitized git remote URL to eliminate embedded plaintext PAT tokens and configured Git Credential Manager.
  - Added fail-closed PAT detection sentinel in `gate_external_boundary.py` scanning git configuration and repository text for `ghp_` and `github_pat_` tokens, outputting masked diagnostics without echoing secret keys.
- **Release Boundary Hardening (WO-0084, WO-0086, WO-0087)**:
  - Hardened repository boundary gate (`H3.external-boundary`) to prevent internal governance markers or unexported paths from leaking into open-source release distributions.

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
