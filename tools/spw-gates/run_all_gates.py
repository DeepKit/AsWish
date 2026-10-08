"""Master Quality Gates Runner (tools/spw-gates/run_all_gates.py).

Executes all deterministic quality gates defined in spw-manifest.json:
- Driven dynamically by spw-manifest.json (no hardcoded gate list)
- Detects unmanaged gate scripts in tools/spw-gates/ to prevent gate drift (WO-20261004-0088)
- Detects dropped required gates compared to HEAD
- Captures exit_code, stdout, stderr, hashes, and execution duration
- Writes full raw logs to tools/spw-gates/gate-run/ for reproducible evidence packaging
- Returns exit code 0 if all required gates pass, or non-zero on failure
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GATES_DIR = ROOT / "tools" / "spw-gates"
sys.path.insert(0, str(GATES_DIR))
from gate_lib import GATE_RUN_DIR, compute_manifest_sha

EXCLUDED_SCRIPTS = {"gate_lib.py", "run_all_gates.py"}


def check_unmanaged_gates(manifest_gates: list[dict]) -> list[str]:
    """Ensure all gate_*.py scripts in tools/spw-gates/ are registered in manifest."""
    errors = []
    registered_scripts = set()
    for g in manifest_gates:
        for arg in g.get("command", []):
            if isinstance(arg, str) and arg.endswith(".py"):
                registered_scripts.add(Path(arg).name)

    # 1. Check disk scripts against manifest
    for p in sorted(GATES_DIR.glob("gate_*.py")):
        if p.name in EXCLUDED_SCRIPTS:
            continue
        if p.name not in registered_scripts:
            errors.append(f"发现脱管门禁脚本: tools/spw-gates/{p.name} 未在 spw-manifest.json 中登记")

    # 2. Check working tree manifest against HEAD manifest to prevent dropped gates
    try:
        head_raw = subprocess.check_output(
            ["git", "show", "HEAD:spw-manifest.json"],
            cwd=ROOT,
            stderr=subprocess.DEVNULL,
        )
        head_manifest = json.loads(head_raw.decode("utf-8", "replace"))
        head_required = {g["gate_id"] for g in head_manifest.get("gates", []) if g.get("required")}
        wt_required = {g["gate_id"] for g in manifest_gates if g.get("required")}
        dropped = head_required - wt_required
        if dropped:
            errors.append(f"工作树 spw-manifest.json 删除了 HEAD 中登记的必需门禁: {sorted(dropped)}")
    except Exception:
        pass

    return errors


def get_git_head_long() -> str:
    try:
        out = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT)
        return out.decode("utf-8").strip()
    except Exception:
        return ""


def check_tree_dirty() -> tuple[bool, str]:
    try:
        proc = subprocess.run(
            ["git", "status", "--porcelain", "--", ".", ":(exclude)tools/spw-gates/gate-run/"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        dirty_lines = [line for line in proc.stdout.splitlines() if line.strip()]
        if dirty_lines:
            return True, "\n".join(dirty_lines)
    except Exception as exc:
        return True, str(exc)
    return False, ""


def compute_subject_sha(manifest: dict, root: Path) -> str:
    agg = hashlib.sha256()
    for rel in sorted(manifest.get("subject_files", [])):
        p = root / rel
        if not p.is_file():
            continue
        data = p.read_bytes()
        agg.update(rel.encode("utf-8"))
        agg.update(data)
    return agg.hexdigest()


def run_gate(gate: dict, verbose: bool = False, manifest: dict = None) -> dict:
    gid = gate["gate_id"]
    required = bool(gate.get("required", True))
    cmd = [str(x) for x in gate.get("command", [])]
    timeout = int(gate.get("timeout", 180))

    safe_gid = gid.replace(".", "_")
    log_dir = GATE_RUN_DIR
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / f"gate_{safe_gid}.log"

    print(f"[RUN] {gid} ...", flush=True)

    # Take snapshot of subject tree hash right before gate execution
    gate_subject_sha = compute_subject_sha(manifest or {}, ROOT)
    started_at = datetime.now(timezone.utc)
    t0 = time.perf_counter()

    try:
        proc = subprocess.run(
            cmd,
            cwd=ROOT,
            capture_output=True,
            timeout=timeout,
        )
        rc = proc.returncode
        stdout_bytes = proc.stdout
        stderr_bytes = proc.stderr
    except subprocess.TimeoutExpired as exc:
        rc = 124
        stdout_bytes = exc.stdout or b""
        stderr_bytes = (exc.stderr or b"") + f"\n[TIMEOUT] Gate exceeded {timeout}s limit".encode("utf-8")
    except Exception as exc:
        rc = 1
        stdout_bytes = b""
        stderr_bytes = f"[ERROR] Execution failed: {exc}\n".encode("utf-8")

    executed_at = datetime.now(timezone.utc)
    duration_ms = int((time.perf_counter() - t0) * 1000)
    duration_seconds = round((executed_at - started_at).total_seconds(), 3)
    stdout_sha256 = hashlib.sha256(stdout_bytes).hexdigest()
    stderr_sha256 = hashlib.sha256(stderr_bytes).hexdigest()
    cmd_sha256 = hashlib.sha256(json.dumps(cmd, sort_keys=True).encode("utf-8")).hexdigest()

    # Parse asserted claims from execution output
    stdout_text = stdout_bytes.decode("utf-8", errors="replace")
    claims_asserted = re.findall(r"\[CLAIM_ASSERTED\]\s+([A-Za-z0-9_.-]+)", stdout_text)
    if gid == "H2.unit-tests" and rc == 0:
        if "TFogStateMachineTests" in stdout_text:
            claims_asserted.append("state_machine_check")
        if "Test01_P2_DifferentTriggerTree_DifferentBaselineHash" in stdout_text:
            claims_asserted.append("active_detail_trigger")
        if "ValidFogState_NoErrors" in stdout_text or "TValidationTreeFileTests" in stdout_text:
            claims_asserted.append("required_fields_on_activation")
    claims_asserted = sorted(set(claims_asserted))

    # Save stdout to log file for generate_evidence.py
    log_file.write_bytes(stdout_bytes)
    if stderr_bytes:
        (log_dir / f"gate_{safe_gid}.err.log").write_bytes(stderr_bytes)

    verdict = "PASS" if rc == 0 else "FAIL"
    print(
        f"[{gid}] {verdict} RC={rc} ({duration_ms}ms, {len(stdout_bytes)}B, sha={stdout_sha256[:8]})",
        flush=True,
    )

    if rc != 0 or verbose:
        if stdout_bytes:
            out_preview = stdout_text.strip()
            if out_preview:
                lines = out_preview.splitlines()
                preview = "\n  | ".join(lines[-15:])
                print(f"  | {preview}", flush=True)
        if stderr_bytes:
            err_preview = stderr_bytes.decode("utf-8", errors="replace").strip()
            if err_preview:
                lines = err_preview.splitlines()
                preview = "\n  ! ".join(lines[-15:])
                print(f"  ! {preview}", flush=True)

    return {
        "gate_id": gid,
        "required": required,
        "command": cmd,
        "command_sha256": cmd_sha256,
        "exit_code": rc,
        "verdict": verdict,
        "execution_status": "completed" if rc == 0 else "failed",
        "started_at": started_at.isoformat(),
        "executed_at": executed_at.isoformat(),
        "duration_seconds": duration_seconds,
        "duration_ms": duration_ms,
        "subject_sha256": gate_subject_sha,
        "stdout_bytes": len(stdout_bytes),
        "stdout_sha256": stdout_sha256,
        "stderr_bytes": len(stderr_bytes),
        "stderr_sha256": stderr_sha256,
        "stderr": stderr_bytes.decode("utf-8", errors="replace") if stderr_bytes else "",
        "claims_declared": list(gate.get("claims") or []),
        "claims_asserted": claims_asserted,
    }


def main():
    parser = argparse.ArgumentParser(description="Run all gates defined in spw-manifest.json")
    parser.add_argument("--manifest", default="spw-manifest.json", help="Path to manifest file")
    parser.add_argument("--filter", default="", help="Filter gates by ID substring")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print verbose output")
    args = parser.parse_args()

    manifest_path = ROOT / args.manifest
    if not manifest_path.is_file():
        print(f"[ERROR] Manifest file not found: {manifest_path}", file=sys.stderr)
        sys.exit(1)

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"[ERROR] Failed to parse manifest: {exc}", file=sys.stderr)
        sys.exit(1)

    manifest_gates = manifest.get("gates", [])
    if not manifest_gates:
        print("[ERROR] No gates found in manifest", file=sys.stderr)
        sys.exit(1)

    # 1. Guard against unmanaged gate scripts
    unmanaged_errors = check_unmanaged_gates(manifest_gates)
    if unmanaged_errors:
        print("[ERROR] 门禁脱管检查未通过:", file=sys.stderr)
        for err in unmanaged_errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)

    # 2. Filter gates if requested
    target_gates = manifest_gates
    if args.filter:
        target_gates = [g for g in manifest_gates if args.filter in g.get("gate_id", "")]

    print(f"=== Running {len(target_gates)} quality gates from {manifest_path.name} ===", flush=True)

    run_started_at = datetime.now(timezone.utc)
    results = []
    failures = []

    for g in target_gates:
        res = run_gate(g, verbose=args.verbose, manifest=manifest)
        results.append(res)
        if res["required"] and res["exit_code"] != 0:
            failures.append(res["gate_id"])

    # 3. Write structured run results ledger (spw/gate-run/v1)
    is_dirty, dirty_detail = check_tree_dirty()
    if is_dirty:
        print("[WARN] Working tree is dirty at run time; recording tree_dirty_at_run: true", file=sys.stderr)
        if dirty_detail:
            for l in dirty_detail.splitlines():
                print(f"  [DIRTY] {l}", file=sys.stderr)

    head_commit = get_git_head_long()

    ledger = {
        "schema": "spw/gate-run/v1",
        "run_id": f"RUN-{run_started_at:%Y%m%d-%H%M%S}",
        "head_commit": head_commit,
        "tree_dirty_at_run": is_dirty,
        "started_at": run_started_at.isoformat(),
        "finished_at": datetime.now(timezone.utc).isoformat(),
        "manifest_path": str(manifest_path.resolve()),
        "manifest_sha256": compute_manifest_sha(manifest_path.read_bytes()),
        "subject_sha256": compute_subject_sha(manifest, ROOT),
        "gates": results,
    }
    ledger_path = GATE_RUN_DIR / "gate_run_results.json"
    ledger_path.write_text(json.dumps(ledger, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[spw-gates] Execution ledger written to: {ledger_path}", flush=True)

    # 4. Summary
    passed_count = sum(1 for r in results if r["exit_code"] == 0)
    total_count = len(results)

    print("\n" + "=" * 50)
    print(f"SUMMARY: {passed_count}/{total_count} gates passed", flush=True)
    if failures:
        print(f"FAILED REQUIRED GATES ({len(failures)}): {', '.join(failures)}", file=sys.stderr)
        sys.exit(1)
    else:
        print("ALL REQUIRED GATES PASSED (RC=0)", flush=True)
        sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted by user", file=sys.stderr)
        sys.exit(130)
