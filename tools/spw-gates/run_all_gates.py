"""Master Quality Gates Runner (tools/spw-gates/run_all_gates.py).

Executes all deterministic quality gates defined in spw-manifest.json:
- Driven dynamically by spw-manifest.json (no hardcoded gate list)
- Detects unmanaged gate scripts in tools/spw-gates/ to prevent gate drift (WO-20261004-0088)
- Detects dropped required gates compared to HEAD
- Captures exit_code, stdout, stderr, hashes, and execution duration
- Writes full raw logs to dogfood_gui/gate_<id>.log for reproducible evidence packaging
- Returns exit code 0 if all required gates pass, or non-zero on failure
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GATES_DIR = ROOT / "tools" / "spw-gates"
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


def run_gate(gate: dict, verbose: bool = False) -> dict:
    gid = gate["gate_id"]
    required = bool(gate.get("required", True))
    cmd = [str(x) for x in gate.get("command", [])]
    timeout = int(gate.get("timeout", 180))

    safe_gid = gid.replace(".", "_")
    log_dir = ROOT / "dogfood_gui"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / f"gate_{safe_gid}.log"

    print(f"[RUN] {gid} ...", flush=True)
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

    duration_ms = int((time.perf_counter() - t0) * 1000)
    stdout_sha256 = hashlib.sha256(stdout_bytes).hexdigest()
    stderr_sha256 = hashlib.sha256(stderr_bytes).hexdigest()

    # Save stdout to log file for generate_evidence.py
    log_file.write_bytes(stdout_bytes)

    verdict = "PASS" if rc == 0 else "FAIL"
    print(
        f"[{gid}] {verdict} RC={rc} ({duration_ms}ms, {len(stdout_bytes)}B, sha={stdout_sha256[:8]})",
        flush=True,
    )

    if rc != 0 or verbose:
        if stdout_bytes:
            out_preview = stdout_bytes.decode("utf-8", errors="replace").strip()
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
        "exit_code": rc,
        "verdict": verdict,
        "duration_ms": duration_ms,
        "stdout_bytes": len(stdout_bytes),
        "stdout_sha256": stdout_sha256,
        "stderr_bytes": len(stderr_bytes),
        "stderr_sha256": stderr_sha256,
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

    results = []
    failures = []

    for g in target_gates:
        res = run_gate(g, verbose=args.verbose)
        results.append(res)
        if res["required"] and res["exit_code"] != 0:
            failures.append(res["gate_id"])

    # 3. Summary
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
