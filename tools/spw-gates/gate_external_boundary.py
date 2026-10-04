"""H3.external-boundary: external boundary leak prevention.

Guards against accidental leakage of internal governance artifacts or markers
into the open source release (WO-20261004-0086 & WO-20261004-0087 Stage 0).

Assertion 1: Paths candidate for release (untracked/dry-run or in git archive HEAD)
must not match the REQUIRED_EXPORT_IGNORE blacklist.
Assertion 2: Content of files candidate for release must not contain internal
governance markers (主控, 开发AI, WorkBuddy, 工单, BCW, BetterCiv), reporting
filename, line number and matched term.
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

# Exact line-level statutory attribution triples (file, line_1_indexed, term)
# per WO-20261004-0087 Stage 0 requirement 3
STATUTORY_ALLOWLIST = {
    ("LICENSE", 178, "BetterCiv"),
    ("NOTICE", 2, "BetterCiv"),
    ("NOTICE", 57, "BCW"),
    ("README.md", 375, "BetterCiv"),
    ("installer/AsWish.iss", 12, "BetterCiv"),
    ("protocol/NOTICE", 2, "BetterCiv"),
    ("protocol/NOTICE", 57, "BCW"),
    ("protocol/README.md", 122, "BetterCiv"),
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
    r"(^|/)docs/07\..*",
    r"(^|/)docs/13\..*",
    r"(^|/)docs/15\..*",
    r"(^|/)docs/AsWish-Commons-PG.*",
    r"(^|/)AUDIT-REQUEST-",
    r"(^|/)AGENTS\.md$",
    r"(^|/)spw-evidence-.*\.json$",
    r"(^|/)gate_(external_boundary|open_source_build)\.py$",  # self and export gate marker definitions
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


def get_candidate_files() -> list[str]:
    """Get all candidate files from git ls-files and untracked unignored files.

    Per WO-20261004-0087 Stage 0: no hardcoded scan directory whitelist.
    Scans all tracked files plus untracked candidate files, filtering out
    internal/export-ignored assets and binary extensions.
    """
    candidates = set()
    try:
        raw_tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
        for b in raw_tracked.split(b"\0"):
            if b:
                rel = b.decode("utf-8", "replace").replace("\\", "/")
                if not is_internal(rel):
                    candidates.add(rel)
    except Exception:
        pass

    try:
        raw_untracked = subprocess.check_output(
            ["git", "ls-files", "--others", "--exclude-standard", "-z"],
            cwd=ROOT
        )
        for b in raw_untracked.split(b"\0"):
            if b:
                rel = b.decode("utf-8", "replace").replace("\\", "/")
                if not is_internal(rel):
                    candidates.add(rel)
    except Exception:
        pass

    return sorted(candidates)


def check_content_markers() -> list[str]:
    """Assert 2: Content of candidate files must not contain internal markers."""
    findings = []
    candidates = get_candidate_files()

    for rel in candidates:
        p = ROOT / rel
        if not p.is_file():
            continue
        if p.suffix.lower() in BINARY_EXTENSIONS:
            continue

        try:
            lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
        except Exception:
            continue

        for line_num, line in enumerate(lines, 1):
            for m in INTERNAL_MARKERS:
                if m in line:
                    if (rel, line_num, m) in STATUTORY_ALLOWLIST:
                        continue
                    findings.append(f"内容含内部治理标记: {rel}:{line_num} 命中 '{m}'")

    return findings


def main():
    findings = []

    # 1. Check dry-run leak risks
    dry_run_findings = check_git_add_dry_run()
    findings.extend(dry_run_findings)

    # 2. Check exported paths in git archive HEAD
    exported = get_exported_paths()
    if exported:
        export_findings = check_exported_paths(exported)
        findings.extend(export_findings)

    # 3. Check content markers across all candidate files
    content_findings = check_content_markers()
    findings.extend(content_findings)

    if findings:
        fail(GATE_ID, findings)

    ok(GATE_ID, "外部边界干净（检查通过）")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as e:
        print(f"[{GATE_ID}][ABORTED] {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)
