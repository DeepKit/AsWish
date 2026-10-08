"""Shared helpers for AsWish SPW gates. Self-locating: repo root is parent of parent."""
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = json.loads((ROOT / "spw-manifest.json").read_text(encoding="utf-8"))

# 门禁凭据与运行日志目录的唯一定义源（WO-20261006-0100 单一真值）
GATE_RUN_DIR = ROOT / "tools" / "spw-gates" / "gate-run"


def compute_manifest_sha(manifest_bytes: bytes) -> str:
    """Computes manifest configuration digest (WO-20261006-0104).
    Excludes gate_run_sha256 to break the cyclic hash dependency between
    the gate execution ledger (which records manifest_sha256) and the
    manifest (which pins gate_run_sha256).
    """
    try:
        obj = json.loads(manifest_bytes.decode("utf-8"))
        if isinstance(obj, dict) and "gate_run_sha256" in obj:
            filtered = {k: v for k, v in obj.items() if k != "gate_run_sha256"}
            return hashlib.sha256(json.dumps(filtered, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()
    except Exception:
        pass
    return hashlib.sha256(manifest_bytes).hexdigest()


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
