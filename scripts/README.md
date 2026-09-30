# Engineering Scripts (scripts/)

This directory contains development-side PowerShell engineering and automation scripts.

## Scripts Overview

- `package_release.ps1`: Automated packaging pipeline. Compiles GUI, CLI, and test binaries, runs the test suite, verifies version metadata, and creates clean distribution archives (`dist/`).
- `run_batch_dogfood.ps1`: Automated batch runner for executing dogfooding verification across sample repositories.
- `BatchDogfoodCommon.ps1`: Common utility functions shared by dogfooding test scripts.
- `TestProjects.ps1`: Test fixture generation helper for local verification.
