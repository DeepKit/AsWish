# SPW Quality Gates (tools/spw-gates)

This directory contains development-side automated quality gates used by the Single Programmer Workflow (SPW) and CI pipelines to enforce project invariants.

## Gates Overview

- `gate_open_source_build.py`: Verifies export boundary isolation, clean clone self-containment, and prohibits runtime Python invocations in Pascal application code.
- `gate_encoding.py`: Ensures all source files are valid UTF-8 and have consistent line endings (CRLF).
- `gate_autofix.py`: Validates deterministic autofix patterns and invariants.
- `gate_ehai_vendor_drift.py`: Guards vendored DeepBase EHAI types against unwanted upstream drift.
- `gate_resource_locks.py`: Validates resource locks and concurrent editing protections.
- `gate_ui_bridge.py`: Enforces UI bridge and contract boundaries between the core engine and GUI surface.
