"""Observation Material Generator (tools/spw-evidence/build_obs_material.py).

Builds un-biased, non-self-referential observation material for H5 external review seats.
Per WO-20261005-0096:
- Gate verdicts originate exclusively from committed evidence bundle (no hardcoded PASS).
- Self-referential H5/certification keys are strictly excluded.
- Material generator verifies itself against exclusion list and bias phrases.
- Missing evidence bundle or unpopulated patterns causes fail-closed abort.
"""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

EXCLUDED_KEYS = {
    "valid_observer_families",
    "required_observer_families",
    "external_observations",
    "observer_seat_outcomes",
    "h5_observation_verdict",
    "certification",
    "pending_h5_findings",
    "observer_input",
    "observer_models",
    "observer_family_whitelist",
    "observations_sha256",
    "min_observer_families",
}

FORBIDDEN_PHRASES = ["已复核", "已批准", "结论是", "推荐答案", "既有共识"]


def get_git_head_short() -> str:
    import subprocess
    try:
        out = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT)
        return out.decode("utf-8").strip()
    except Exception:
        return "head"


def scan_for_excluded_keys(obj, path=""):
    """Recursively verify no excluded self-referential keys exist in data structure."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            curr_path = f"{path}.{k}" if path else k
            lower_k = str(k).lower()
            if lower_k in EXCLUDED_KEYS or any(
                p in lower_k for p in ("observ", "certif", "h5_")
            ):
                raise RuntimeError(f"Self-referential key '{k}' found at '{curr_path}'")
            scan_for_excluded_keys(v, curr_path)
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            scan_for_excluded_keys(item, f"{path}[{i}]")


def build_material(evidence_path: Path, output_path: Path = None) -> Path:
    if not evidence_path or not evidence_path.is_file():
        raise FileNotFoundError(f"Evidence bundle required but not found: {evidence_path}")

    bundle_data = json.loads(evidence_path.read_text(encoding="utf-8"))
    if bundle_data.get("schema") != "spw/evidence/v1":
        raise ValueError(f"Invalid evidence bundle schema: {bundle_data.get('schema')}")

    manifest_path = ROOT / "spw-manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    # Extract deterministic gates directly from evidence bundle
    raw_gates = bundle_data.get("deterministic_gates")
    if not isinstance(raw_gates, list) or not raw_gates:
        raise ValueError("Evidence bundle carries no deterministic_gates records")

    gate_verdicts = []
    for g in raw_gates:
        if not isinstance(g, dict) or "gate_id" not in g:
            continue
        gate_verdicts.append({
            "gate_id": g["gate_id"],
            "required": bool(g.get("required", True)),
            "verdict": str(g.get("verdict", "FAIL")),
            "exit_code": int(g.get("exit_code", 1)),
            "claims": list(g.get("claims") or []),
            "claims_asserted": list(g.get("claims_asserted") or []),
            "command": list(g.get("command") or []),
            "command_sha256": str(g.get("command_sha256") or ""),
            "executed_at": str(g.get("executed_at") or ""),
            "duration_seconds": float(g.get("duration_seconds", 0.0)),
            "subject_sha256": str(g.get("subject_sha256") or ""),
            "stdout_sha256": str(g.get("stdout_sha256") or ""),
            "stderr_sha256": str(g.get("stderr_sha256") or ""),
            "stdout_bytes": int(g.get("stdout_bytes", 0)),
            "stderr_bytes": int(g.get("stderr_bytes", 0)),
            "truncated": bool(g.get("truncated", False)),
        })

    # Validate h4_patterns is populated and not all-null (WO-0096 Phase 3)
    patterns = manifest.get("h4_patterns")
    if not patterns or not isinstance(patterns, list):
        raise ValueError("h4_patterns is missing or empty in manifest")
    if all(p is None for p in patterns):
        raise ValueError("h4_patterns contains only null elements")

    # Read waivers ledger
    waivers_file = ROOT / "tools" / "spw-gates" / "h4_waivers.json"
    waivers_ledger = {}
    if waivers_file.is_file():
        ledger_data = json.loads(waivers_file.read_text(encoding="utf-8"))
        waivers = ledger_data.get("waivers") or []
        waivers_ledger = {
            "path": "tools/spw-gates/h4_waivers.json",
            "schema": list(waivers[0].keys()) if waivers else [],
            "total": len(waivers),
            "with_approver": sum(1 for w in waivers if str(w.get("approved_by") or "").strip()),
            "without_approver": sum(1 for w in waivers if not str(w.get("approved_by") or "").strip()),
            "with_submitted_by": sum(1 for w in waivers if str(w.get("submitted_by") or "").strip()),
            "distinct_scopes": sorted({str(w.get("scope") or "") for w in waivers}),
            "authorized_approvers": ["MasterController", "ArchitectureReviewBoard"],
            "samples": [
                {k: w.get(k) for k in (
                    "pattern_id", "file", "line", "code", "rationale", "scope",
                    "approved_by", "approved_at", "expires_at", "submitted_by"
                )}
                for w in waivers[:3]
            ],
        }

    # Clean h4_policy to strip any self-referential keys
    h4_policy = {}
    for k, v in (manifest.get("h4_policy") or {}).items():
        if k not in EXCLUDED_KEYS and not any(p in k.lower() for p in ("observ", "certif", "h5_")):
            h4_policy[k] = v

    material = {
        "_note": (
            "This is the material provided to independent read-only reviewer seats. "
            "It deliberately contains NO fields describing external-observation "
            "or certification outcomes of the audit run, ensuring reviewers audit "
            "the software itself rather than the audit harness state."
        ),
        "subject_sha256": bundle_data.get("subject", {}).get("sha256", ""),
        "head_commit": get_git_head_short(),
        "manifest_declared_gates": [
            {"gate_id": g["gate_id"], "required": bool(g.get("required", True)),
             "claims": list(g.get("claims") or [])}
            for g in manifest.get("gates", [])
        ],
        "recorded_gate_verdicts": gate_verdicts,
        "h4_policy": h4_policy,
        "h4_patterns": patterns,
        "h4_waiver_ledger": waivers_ledger,
    }

    # Self-validation 1: Excluded keys scan
    scan_for_excluded_keys(material)

    serialized = json.dumps(material, ensure_ascii=False, indent=2) + "\n"

    # Self-validation 2: Forbidden conclusion bias scan
    for phrase in FORBIDDEN_PHRASES:
        if phrase in serialized:
            raise RuntimeError(f"Forbidden conclusion phrase found in material: '{phrase}'")

    raw_bytes = serialized.encode("utf-8")
    material_digest = hashlib.sha256(raw_bytes).hexdigest()

    if output_path is None:
        output_path = ROOT / "obs_material.json"

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(raw_bytes)
    return output_path, material_digest


def main():
    parser = argparse.ArgumentParser(description="Generate un-biased observation material for H5 reviewers")
    parser.add_argument("--evidence", required=True, help="Path to SPW evidence bundle JSON")
    parser.add_argument("--output", default=None, help="Output JSON path (default: obs_material.json)")
    args = parser.parse_args()

    evidence_path = Path(args.evidence).resolve()
    output_path = Path(args.output).resolve() if args.output else None

    try:
        out_file, digest = build_material(evidence_path, output_path)
        print(f"[obs-material] Generated: {out_file}")
        print(f"[obs-material] bytes={out_file.stat().st_size}")
        print(f"[obs-material] material_digest={digest}")
        data = json.loads(out_file.read_text(encoding="utf-8"))
        verdicts = data.get("recorded_gate_verdicts", [])
        pass_cnt = sum(1 for g in verdicts if g.get("verdict") == "PASS")
        fail_cnt = sum(1 for g in verdicts if g.get("verdict") == "FAIL")
        print(f"[obs-material] gates count: {len(verdicts)} ({pass_cnt} PASS, {fail_cnt} FAIL)")
    except Exception as e:
        print(f"[obs-material][FAIL] {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
