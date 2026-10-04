"""H3.external-boundary: external boundary leak prevention.

Guards against accidental leakage of internal governance artifacts or markers
into the open source release (WO-20261004-0086 Stage 0).

Assertion 1: Paths candidate for release (untracked/dry-run or in git archive HEAD)
must not match the REQUIRED_EXPORT_IGNORE blacklist.
Assertion 2: Content of files candidate for release must not contain internal
governance markers (主控, 开发AI, WorkBuddy, 工单, BCW, BetterCiv), reporting
filename and matched term.
"""
import io
import re
import subprocess
import sys
import zipfile
from pathlib import Path
from gate_lib import fail, ok, ROOT

GATE_ID = "H3.external-boundary"

REQUIRED_EXPORT_IGNORE = [
    "WO/",
    ".workbuddy/",
    ".AsWish/",
    ".ai-workbench/",
    "_repro/",
    "_audit_out.txt",
    "_audit_err.txt",
    "err_file",
    "out_file",
]

# Patterns that must never be in git add -A dry-run (untracked/leakable)
GIT_ADD_BLACKLIST = [
    r"(^|/)\.AsWish/",
    r"(^|/)\.ai-workbench/",
    r"(^|/)_repro/",
    r"(^|/)_audit_.*\.txt$",
    r"(^|/)err_file$",
    r"(^|/)out_file$",
]

# Internal governance markers that must not appear in exported code/spec files
INTERNAL_MARKERS = ["主控", "开发AI", "WorkBuddy", "工单", "BCW", "BetterCiv"]

# Statutory attribution files where BetterCiv/BCW are authorized as copyright holder
STATUTORY_ALLOWLIST = {
    "LICENSE",
    "NOTICE",
    "README.md",
    "installer/AsWish.iss",
    "protocol/NOTICE",
    "protocol/README.md",
}

# Internal files/dirs that are excluded from open source export
INTERNAL_PATTERNS = [
    r"(^|/)WO/",
    r"(^|/)\.workbuddy/",
    r"(^|/)\.AsWish/",
    r"(^|/)\.ai-workbench/",
    r"(^|/)_repro/",
    r"(^|/)\.claude/",
    r"(^|/)docs/归档/",
    r"(^|/)docs/_archive/",
    r"(^|/)docs/.*交接.*",
    r"(^|/)AUDIT-REQUEST-",
    r"(^|/)AGENTS\.md$",
    r"(^|/)spw-evidence-.*\.json$",
    r"(^|/)gate_external_boundary\.py$",  # self
]

BINARY_EXTENSIONS = {
    ".exe", ".dll", ".pak", ".png", ".ico", ".res", ".zip", ".dcu", ".data",
    ".identcache", ".local", ".tvsconfig", ".bpl"
}


def is_internal(rel_path: str) -> bool:
    norm = rel_path.replace("\\", "/")
    return any(re.search(pat, norm) for pat in INTERNAL_PATTERNS)


def check_git_add_dry_run() -> list[str]:
    """Ensure git add -A would not sweep in any blacklisted directories or files."""
    findings = []
    try:
        res = subprocess.run(
            ["git", "add", "-A", "--dry-run"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True
        )
        for line in res.stdout.splitlines():
            line = line.strip()
            if line.startswith("add '") and line.endswith("'"):
                staged = line[5:-1].replace("\\", "/")
                for pat in GIT_ADD_BLACKLIST:
                    if re.search(pat, staged):
                        findings.append(f"git add -A 将误扫进黑名单路径: {staged}")
                        break
    except Exception as e:
        findings.append(f"git add -A --dry-run 检查执行异常: {e}")
    return findings


def get_exported_paths() -> set[str]:
    """Get all paths in `git archive HEAD`."""
    try:
        out = subprocess.run(
            ["git", "archive", "--format=zip", "HEAD"],
            cwd=ROOT,
            capture_output=True,
            check=True,
        ).stdout
        with zipfile.ZipFile(io.BytesIO(out)) as zf:
            return {n.rstrip("/").replace("\\", "/") for n in zf.namelist() if not n.endswith("/")}
    except Exception:
        return set()


def check_exported_paths(exported: set[str]) -> list[str]:
    """Assert 1: Exported paths must not match REQUIRED_EXPORT_IGNORE."""
    findings = []
    for rel in sorted(exported):
        for ign in REQUIRED_EXPORT_IGNORE:
            ign_norm = ign.rstrip("/")
            if rel == ign_norm or rel.startswith(ign_norm + "/"):
                findings.append(f"导出清单命中 REQUIRED_EXPORT_IGNORE 黑名单: {rel}")
                break
    return findings


def check_content_markers() -> list[str]:
    """Assert 2: Content of all candidate files for release must not contain internal markers."""
    findings = []

    # Check all files in public candidate paths (src, cli, tests, protocol, tools, root)
    scan_roots = ["src", "cli", "tests", "tools", "protocol", "installer"]
    candidate_paths = []

    for sr in scan_roots:
        base = ROOT / sr
        if not base.is_dir():
            continue
        for p in base.rglob("*"):
            if p.is_file():
                rel = p.relative_to(ROOT).as_posix()
                if not is_internal(rel) and "mirror" not in p.parts:
                    candidate_paths.append((p, rel))

    # Also check tracked/unignored files at root
    for p in ROOT.iterdir():
        if p.is_file():
            rel = p.relative_to(ROOT).as_posix()
            if not is_internal(rel):
                ign = subprocess.run(
                    ["git", "check-ignore", "-q", rel],
                    cwd=ROOT,
                )
                if ign.returncode != 0:
                    candidate_paths.append((p, rel))

    for p, rel in candidate_paths:
        if p.suffix.lower() in BINARY_EXTENSIONS:
            continue
        try:
            content = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        for m in INTERNAL_MARKERS:
            if m in ("BetterCiv", "BCW") and rel in STATUTORY_ALLOWLIST:
                continue
            if m in content:
                findings.append(f"内容含内部治理标记: {rel} 命中 '{m}'")

    return findings


def main():
    findings = []

    # 1. Check git add dry-run for blacklisted paths
    findings.extend(check_git_add_dry_run())

    # 2. Check exported paths against blacklist
    exported = get_exported_paths()
    if exported:
        findings.extend(check_exported_paths(exported))

    # 3. Check content of candidate release files for markers
    findings.extend(check_content_markers())

    if findings:
        fail(GATE_ID, findings)
    ok(GATE_ID, f"外部边界干净（检查通过）")


if __name__ == "__main__":
    main()
