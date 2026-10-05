"""H1.resource-locks: controlled_entry_only
Checks every locked resource in the manifest actually exists, and that
DeepBase units referenced from AsWish sources resolve inside the canonical
DeepBase tree (no stale/broken cross-tree references)."""
import re
import sys
from pathlib import Path
from gate_lib import MANIFEST, ROOT, read, source_files, fail, ok

_COMMENT_BLOCK = re.compile(r"\{[^}]*\}|\(\*.*?\*\)", re.DOTALL)
_COMMENT_LINE = re.compile(r"//[^\n]*")
_STRING_LITERAL = re.compile(r"'(?:[^']|'')*'")


def strip_literals_and_comments(text: str) -> str:
    """Unit names must come from code, not from prose.

    A negative assertion such as Assert.IsFalse(Content.Contains('DeepBase.EHAI'))
    is a test that the dependency is ABSENT; treating its string literal as a
    unit reference makes this gate report a violation that does not exist.

    Must be applied per file: a single apostrophe left unbalanced by comment
    stripping (e.g. 'http://x' inside a literal) shifts quote pairing across a
    concatenated blob and re-exposes the very literals we just removed.
    """
    text = _COMMENT_BLOCK.sub(" ", text)
    text = _COMMENT_LINE.sub(" ", text)
    return _STRING_LITERAL.sub(" ", text)


findings = []
for lock in MANIFEST.get("resource_locks", []):
    cp = Path(lock["canonical_path"])
    if not cp.is_dir():
        findings.append(f"resource lock missing on disk: {lock['id']} -> {cp}")

core = Path(MANIFEST["resource_locks"][0]["canonical_path"]) if MANIFEST.get("resource_locks") else None
if core:
    units: set[str] = set()
    for f in source_files():
        units |= {u.split(".pas")[0]
                  for u in re.findall(r"\b(DeepBase\.[A-Za-z0-9_.]+)",
                                      strip_literals_and_comments(read(f)))}
    for u in sorted(units):
        hits = [p for p in core.rglob(u + ".pas")
                if not any(part.startswith(".") for part in p.relative_to(core).parts)]
        if not hits:
            findings.append(f"DeepBase unit referenced but not found in locked tree: {u}")

if findings:
    fail("H1.resource-locks", findings)
ok("H1.resource-locks", claims=["controlled_entry_only"])
