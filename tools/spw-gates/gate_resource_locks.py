"""H1.resource-locks: controlled_entry_only
Checks every locked resource in the manifest actually exists, and that
DeepBase units referenced from AsWish sources resolve inside the canonical
DeepBase tree (no stale/broken cross-tree references)."""
import re
import sys
from pathlib import Path
from gate_lib import MANIFEST, ROOT, read, source_files, fail, ok

findings = []
for lock in MANIFEST.get("resource_locks", []):
    cp = Path(lock["canonical_path"])
    if not cp.is_dir():
        findings.append(f"resource lock missing on disk: {lock['id']} -> {cp}")

core = Path(MANIFEST["resource_locks"][0]["canonical_path"]) if MANIFEST.get("resource_locks") else None
if core:
    blob = "\n".join(read(f) for f in source_files())
    # strip unit names; tolerate trailing .pas/.dcr captured by the greedy regex
    units = {u.split(".pas")[0] for u in re.findall(r"\b(DeepBase\.[A-Za-z0-9_.]+)", blob)}
    for u in sorted(units):
        hits = [p for p in core.rglob(u + ".pas")
                if not any(part.startswith(".") for part in p.relative_to(core).parts)]
        if not hits:
            findings.append(f"DeepBase unit referenced but not found in locked tree: {u}")

if findings:
    fail("H1.resource-locks", findings)
ok("H1.resource-locks")
