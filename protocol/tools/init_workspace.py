#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AsWish Protocol L0: Standalone Workspace Initializer (Cold Environment Rebuilder).

Zero dependencies outside Python 3 standard library. Creates a valid, conforming
.AsWish/ workspace according to AsWish Protocol v1.2-draft.

Usage:
    python init_workspace.py <target_dir> [--project-name <name>] [--force]
"""

from __future__ import annotations

import argparse
import datetime
import os
import sys
from pathlib import Path


def create_aswish_workspace(
    target_dir: Path | str,
    project_name: str | None = None,
    force: bool = False,
) -> Path:
    """Create a pristine .AsWish/ workspace in target_dir."""
    target = Path(target_dir).resolve()
    target.mkdir(parents=True, exist_ok=True)

    ds_dir = target / ".AsWish"
    if ds_dir.exists() and not force:
        raise FileExistsError(f".AsWish directory already exists in {target}. Use --force to overwrite.")

    p_name = project_name or target.name or "UntitledProject"
    iso_now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # 1. Create subdirectories
    subdirs = ["trees", "bundles", "relations", "evidence", "issues", "decisions", "agents"]
    for sd in subdirs:
        (ds_dir / sd).mkdir(parents=True, exist_ok=True)

    # 2. project-spec.yaml
    project_spec = f"""version: "1.2"
project:
  name: "{p_name}"
  root: "."
  description: "AsWish specification workspace for {p_name}"
  primary_language: "agnostic"
  initialized_at: "{iso_now}"
summary:
  function_count: 0
  module_count: 0
  view_count: 0
  data_count: 0
trees:
  function_tree: "trees/function-tree.yaml"
  module_tree: "trees/module-tree.yaml"
  view_tree: "trees/view-tree.yaml"
  data_tree: "trees/data-tree.yaml"
"""
    (ds_dir / "project-spec.yaml").write_text(project_spec, encoding="utf-8")

    # 3. Four projection trees
    projections = [
        ("function", "Behavioral capabilities, requirements, and user stories"),
        ("module", "Code organization, units, packages, and architecture"),
        ("view", "User interfaces, pages, forms, and interaction surfaces"),
        ("data", "Data models, entities, fields, relations, and persistence"),
    ]

    for tree_type, desc in projections:
        tree_content = f"""version: "1.2"
tree: "{tree_type}"
generated_at: "{iso_now}"
generator: "AsWish-L0-Init/1.0"
description: "{desc}"
nodes: []
"""
        (ds_dir / "trees" / f"{tree_type}-tree.yaml").write_text(tree_content, encoding="utf-8")

    # 4. Auxiliary fact files
    (ds_dir / "relations" / "requirement-relations.yaml").write_text(
        f'version: "1.2"\ngenerated_at: "{iso_now}"\nrelations: []\n', encoding="utf-8"
    )
    (ds_dir / "evidence" / "source-evidence.yaml").write_text(
        f'version: "1.2"\ngenerated_at: "{iso_now}"\nevidence: []\n', encoding="utf-8"
    )
    (ds_dir / "issues" / "doc-issues.yaml").write_text(
        f'version: "1.2"\ngenerated_at: "{iso_now}"\nissues: []\n', encoding="utf-8"
    )
    (ds_dir / "decisions" / "review-decisions.yaml").write_text(
        f'version: "1.2"\ngenerated_at: "{iso_now}"\ndecisions: []\n', encoding="utf-8"
    )

    return ds_dir


def main() -> int:
    parser = argparse.ArgumentParser(description="AsWish Protocol L0: Standalone Workspace Initializer")
    parser.add_argument("target_dir", help="Project directory to initialize .AsWish/ in")
    parser.add_argument("--project-name", help="Name of the project")
    parser.add_argument("--force", action="store_true", help="Overwrite existing .AsWish directory")
    args = parser.parse_args()

    try:
        ds = create_aswish_workspace(args.target_dir, args.project_name, args.force)
        print(f"[OK] Initialized AsWish workspace at: {ds}")
        return 0
    except Exception as exc:
        print(f"[ERROR] Failed to initialize AsWish workspace: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
