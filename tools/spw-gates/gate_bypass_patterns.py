"""H4.bypass-patterns: Static anti-bypass pattern verification gate.

Scans Pascal source files against h4_patterns configured in spw-manifest.json:
- H4.DIRECT_DISK_WRITE: TFile direct disk writes bypassing SpecStore
- H4.SILENT_INIT_FAILURE: OutputDebugString silent error handling
- H4.HARDCODED_ABS_PATH: Hardcoded absolute machine paths

Enforces that every occurrence is tracked, audited, and explicitly justified in
h4_waivers.json. Un-waived violations cause fail-closed rejection.
Per WO-20261004-0089 & WO-20261004-0091:
- Validates governance fields (scope, approved_by, approved_at, expires_at)
- Blocks unapproved ongoing waivers (scope=ongoing requires valid approved_by)
- Blocks expired waivers (expires_at past today)
- Blocks stale waivers (target file/line does not exist or target code doesn't match pattern)
- Rejects impersonated approver roles (WO-0091: forbidden impersonation patterns from manifest)
- Enforces approver role whitelist via tools/spw-gates/h4_approvers.json (fail-closed if missing/unauthorized)
- Rejects self-signed waivers (submitted_by == approved_by)
- Historical debt without authentic approver emits [WARN] baseline waiver without approver and passes
"""
from datetime import date, datetime
import json
import re
import subprocess
import sys
from pathlib import Path
from gate_lib import fail, ok, ROOT

GATE_ID = "H4.bypass-patterns"


def load_manifest_config() -> tuple[list[dict], int, list[str]]:
    manifest_path = ROOT / "spw-manifest.json"
    if not manifest_path.is_file():
        fail(GATE_ID, ["spw-manifest.json not found"])
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        patterns = manifest.get("h4_patterns", [])
        policy = manifest.get("h4_policy", {})
        max_ongoing = policy.get("max_ongoing_waivers", 0)
        impersonation_patterns = policy.get("impersonation_patterns", [])
        return patterns, max_ongoing, impersonation_patterns
    except Exception as e:
        fail(GATE_ID, [f"failed to parse spw-manifest.json: {e}"])
        return [], 0, []


def load_approvers(impersonation_rx_list: list[re.Pattern]) -> set[str]:
    """Load authorized approvers whitelist from h4_approvers.json (WO-0091 Stage 2)."""
    approvers_path = ROOT / "tools" / "spw-gates" / "h4_approvers.json"
    if not approvers_path.is_file():
        fail(GATE_ID, ["[HIGH] h4_approvers.json missing (fail-closed: approver whitelist required)"])
    try:
        data = json.loads(approvers_path.read_text(encoding="utf-8"))
        approvers = set(data.get("authorized_approvers", []))
        if not approvers:
            fail(GATE_ID, ["[HIGH] h4_approvers.json contains empty authorized_approvers (fail-closed)"])
        for app in approvers:
            for imp_rx in impersonation_rx_list:
                if imp_rx.search(app):
                    fail(
                        GATE_ID,
                        [f"[HIGH] h4_approvers.json contains forbidden impersonated role: '{app}'"],
                    )
        return approvers
    except SystemExit:
        raise
    except Exception as exc:
        fail(GATE_ID, [f"[HIGH] failed to parse h4_approvers.json: {exc}"])
        return set()


def load_waiver_data() -> list[dict]:
    waiver_path = ROOT / "tools" / "spw-gates" / "h4_waivers.json"
    if not waiver_path.is_file():
        return []
    try:
        data = json.loads(waiver_path.read_text(encoding="utf-8"))
        return data.get("waivers", [])
    except Exception as e:
        fail(GATE_ID, [f"failed to parse h4_waivers.json: {e}"])
        return []


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
        return []


def validate_waiver_governance(
    waiver: dict,
    pattern_regexes: dict[str, re.Pattern],
    today_str: str,
    impersonation_rx_list: list[re.Pattern],
    authorized_approvers: set[str],
) -> tuple[str | None, str | None]:
    """Validate a waiver entry for stale target, governance fields, approver authorization, and expiration."""
    pid = waiver.get("pattern_id")
    file_rel = waiver.get("file", "").replace("\\", "/")
    line_no = waiver.get("line")
    scope = waiver.get("scope")
    approved_by = waiver.get("approved_by")
    approved_at = waiver.get("approved_at")
    expires_at = waiver.get("expires_at")
    submitted_by = waiver.get("submitted_by")

    loc = f"{file_rel}:{line_no}"

    # 1. Stale waiver check: file existence, line bounds, and pattern match
    p = ROOT / file_rel
    if not p.is_file():
        return f"[HIGH] stale waiver: file {file_rel} does not exist", None

    try:
        lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
    except Exception as exc:
        return f"[HIGH] stale waiver: unable to read {file_rel}: {exc}", None

    if not isinstance(line_no, int) or line_no < 1 or line_no > len(lines):
        return f"[HIGH] stale waiver: {loc} line number invalid or out of bounds (file has {len(lines)} lines)", None

    rx = pattern_regexes.get(pid)
    target_line = lines[line_no - 1]
    if not rx or not rx.search(target_line):
        return f"[HIGH] stale waiver: {loc} pattern {pid} does not match code '{target_line.strip()[:60]}'", None

    # 2. Scope validation
    if scope not in ("baseline", "ongoing"):
        return f"[HIGH] invalid waiver scope: {loc} scope='{scope}' (must be 'baseline' or 'ongoing')", None

    app_str = str(approved_by).strip() if approved_by is not None else ""

    # 3. Approver anti-impersonation, whitelist, and anti-self-signing (WO-0091)
    if app_str:
        for imp_rx in impersonation_rx_list:
            if imp_rx.search(app_str):
                return (
                    f"[HIGH] impersonated approver: {loc} approved_by='{app_str}' matches forbidden pattern '{imp_rx.pattern}'",
                    None,
                )
        if app_str not in authorized_approvers:
            return (
                f"[HIGH] unauthorized approver: {loc} approved_by='{app_str}' not in h4_approvers.json",
                None,
            )
        if submitted_by and str(submitted_by).strip() == app_str:
            return f"[HIGH] self-signed waiver: {loc} submitted_by matches approved_by", None

    # 4. Governance field validation based on scope
    if scope == "ongoing":
        if not app_str:
            return f"[HIGH] unapproved ongoing waiver: {loc} pattern {pid} missing approved_by", None
        if not approved_at or not str(approved_at).strip():
            return f"[HIGH] unapproved ongoing waiver: {loc} pattern {pid} missing approved_at", None
    elif scope == "baseline":
        if not app_str:
            # Honest historical debt warning (WO-0089/WO-0091)
            warn = f"[WARN] baseline waiver without approver (historical debt): {loc}"
            return None, warn

    # 5. Expiration check
    if expires_at and str(expires_at).strip():
        exp_val = str(expires_at).strip()
        try:
            exp_date = datetime.strptime(exp_val, "%Y-%m-%d").date()
            today_date = datetime.strptime(today_str, "%Y-%m-%d").date()
            if exp_date <= today_date:
                return f"[HIGH] waiver expired: {loc} pattern {pid} expired on {exp_val}", None
        except ValueError:
            return f"[HIGH] invalid expires_at format: {loc} '{exp_val}' (expected YYYY-MM-DD)", None

    return None, None


def main():
    patterns, max_ongoing, impersonation_patterns = load_manifest_config()
    if not patterns:
        fail(GATE_ID, ["no h4_patterns defined in spw-manifest.json"])

    impersonation_rx_list = [re.compile(p) for p in impersonation_patterns]
    authorized_approvers = load_approvers(impersonation_rx_list)

    waivers_raw = load_waiver_data()
    source_files = get_pascal_source_files()

    pattern_regexes = {p["id"]: re.compile(p["pattern"]) for p in patterns}
    pattern_severities = {p["id"]: p.get("severity", "high") for p in patterns}

    today_str = date.today().isoformat()
    findings = []
    warnings = []
    valid_waivers = {}
    ongoing_waivers = []

    # 1. Audit all waiver entries in h4_waivers.json
    for w in waivers_raw:
        err, warn = validate_waiver_governance(
            w, pattern_regexes, today_str, impersonation_rx_list, authorized_approvers
        )
        if err:
            findings.append(err)
        else:
            key = (w["pattern_id"], w["file"].replace("\\", "/"), int(w["line"]))
            valid_waivers[key] = w
            if w.get("scope") == "ongoing":
                ongoing_waivers.append(w)
        if warn:
            warnings.append(warn)

    for warn in warnings:
        print(f"[{GATE_ID}] {warn}")

    if len(ongoing_waivers) > max_ongoing:
        findings.append(
            f"[HIGH] ongoing waivers ({len(ongoing_waivers)}) exceed policy threshold ({max_ongoing})"
        )

    # 2. Scan Pascal files against patterns
    all_hits = []
    summary_lines = []

    for p in patterns:
        pid = p["id"]
        sev = pattern_severities.get(pid, "high")
        rx = pattern_regexes[pid]
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
                    if key in valid_waivers:
                        all_hits.append((pid, rel, line_no, "WAIVED", valid_waivers[key].get("rationale", "")))
                    else:
                        findings.append(
                            f"[{sev.upper()}] {pid} un-waived hit at {rel}:{line_no} -> {line.strip()[:80]}"
                        )
                        all_hits.append((pid, rel, line_no, "VIOLATION", ""))

        waived_count = sum(1 for h in all_hits if h[0] == pid and h[3] == "WAIVED")
        summary_lines.append(f"Pattern {pid}: {len(pattern_hits)} hits ({waived_count} waived)")

    for s in summary_lines:
        print(f"[{GATE_ID}] {s}")

    if findings:
        fail(GATE_ID, findings)

    ok(GATE_ID, f"verified {len(all_hits)} hits; all {len(valid_waivers)} waivers governed and accounted for ({len(warnings)} baseline debt warnings emitted)")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as e:
        print(f"[{GATE_ID}][ABORTED] {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)
