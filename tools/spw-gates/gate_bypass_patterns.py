"""H4.bypass-patterns: Static anti-bypass pattern verification gate.

Scans Pascal source files against h4_patterns configured in spw-manifest.json:
- H4.DIRECT_DISK_WRITE: TFile direct disk writes bypassing SpecStore
- H4.SILENT_INIT_FAILURE: OutputDebugString silent error handling
- H4.HARDCODED_ABS_PATH: Hardcoded absolute machine paths

Enforces that every occurrence is tracked, audited, and explicitly justified in
h4_waivers.json. Un-waived violations cause fail-closed rejection.
"""
import json
import re
import subprocess
import sys
from pathlib import Path
from gate_lib import fail, ok, ROOT

GATE_ID = "H4.bypass-patterns"


def load_manifest_patterns() -> list[dict]:
    manifest_path = ROOT / "spw-manifest.json"
    if not manifest_path.is_file():
        fail(GATE_ID, ["spw-manifest.json not found"])
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        return manifest.get("h4_patterns", [])
    except Exception as e:
        fail(GATE_ID, [f"failed to parse spw-manifest.json: {e}"])


def load_waivers() -> dict[tuple[str, str, int], str]:
    """Return map of (pattern_id, file, line) -> rationale."""
    waiver_path = ROOT / "tools" / "spw-gates" / "h4_waivers.json"
    if not waiver_path.is_file():
        return {}
    try:
        data = json.loads(waiver_path.read_text(encoding="utf-8"))
        waivers = {}
        for w in data.get("waivers", []):
            key = (w["pattern_id"], w["file"].replace("\\", "/"), int(w["line"]))
            waivers[key] = w.get("rationale", "")
        return waivers
    except Exception:
        return {}


def get_pascal_source_files() -> list[str]:
    try:
        raw = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
        files = []
        for b in raw.split(b"\0"):
            if not b:
                continue
            rel = b.decode("utf-8", "replace").replace("\\", "/")
            if rel.endswith((".pas", ".dpr", ".inc")) and not ("归档" in rel or "_archive" in rel):
                files.append(rel)
        return sorted(files)
    except Exception as e:
        fail(GATE_ID, [f"git ls-files failed: {e}"])


def main():
    patterns = load_manifest_patterns()
    if not patterns:
        fail(GATE_ID, ["no h4_patterns defined in spw-manifest.json"])

    waivers = load_waivers()
    source_files = get_pascal_source_files()

    all_hits = []
    unwaived_findings = []
    summary_lines = []

    for p in patterns:
        pid = p["id"]
        sev = p.get("severity", "high")
        rx = re.compile(p["pattern"])
        pattern_hits = []

        for rel in source_files:
            file_path = ROOT / rel
            if not file_path.is_file():
                continue
            try:
                lines = file_path.read_text(encoding="utf-8", errors="replace").splitlines()
            except Exception:
                continue

            for line_no, line in enumerate(lines, 1):
                if rx.search(line):
                    pattern_hits.append((rel, line_no, line.strip()))
                    key = (pid, rel, line_no)
                    if key in waivers:
                        all_hits.append((pid, rel, line_no, "WAIVED", waivers[key]))
                    else:
                        unwaived_findings.append(
                            f"[{sev.upper()}] {pid} un-waived hit at {rel}:{line_no} -> {line.strip()[:80]}"
                        )
                        all_hits.append((pid, rel, line_no, "VIOLATION", ""))

        waived_count = sum(1 for h in all_hits if h[0] == pid and h[3] == "WAIVED")
        summary_lines.append(f"Pattern {pid}: {len(pattern_hits)} hits ({waived_count} waived)")

    for s in summary_lines:
        print(f"[{GATE_ID}] {s}")

    if unwaived_findings:
        fail(GATE_ID, unwaived_findings)

    ok(GATE_ID, f"verified {len(all_hits)} hits; all findings accounted for in h4_waivers.json")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as e:
        print(f"[{GATE_ID}][ABORTED] {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)
