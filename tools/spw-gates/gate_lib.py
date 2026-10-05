"""Shared helpers for AsWish SPW gates. Self-locating: repo root is parent of parent."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = json.loads((ROOT / "spw-manifest.json").read_text(encoding="utf-8"))

SRC_DIRS = ["src", "cli", "tests"]


def read(path: Path) -> str:
    return path.read_bytes().decode("utf-8", errors="replace")


def source_files(patterns=("*.pas", "*.dpr", "*.inc")):
    for d in SRC_DIRS:
        base = ROOT / d
        if not base.is_dir():
            continue
        for pat in patterns:
            yield from base.rglob(pat)


def fail(gate_id: str, findings):
    print(f"[{gate_id}] FAIL")
    for f in findings:
        print(f"  - {f}")
    sys.exit(1)


def ok(gate_id: str, note: str = "", claims: list = None):
    for c in (claims or []):
        print(f"[CLAIM_ASSERTED] {c}")
    print(f"[{gate_id}] PASS {note}".rstrip())
    sys.exit(0)
