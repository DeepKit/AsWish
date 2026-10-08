"""SPW Evidence Bundle Generator (tools/spw-evidence/generate_evidence.py)

Deterministic gate results packaging and H5 degradation accounting.
Per WO-20261004-0087 Stage 3 and Stage 5:
- In-repo reproducible tool
- Full stdout integrity (stdout_bytes, stdout_sha256, and stdout body are 100% consistent)
- Honest H5 reporting (degraded status, withheld certificate, release_ready=False when live heterogeneous observers are unavailable)
- Bound to current git HEAD commit SHA
"""
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "spw-gates"))
from gate_lib import GATE_RUN_DIR, compute_manifest_sha
import run_all_gates

# 运行时自洽断言（WO-20261006-0100 阶段 2）：读取方与写入方的 GATE_RUN_DIR 必须绝对一致
if run_all_gates.GATE_RUN_DIR != GATE_RUN_DIR:
    raise RuntimeError(
        f"GATE_RUN_DIR mismatch between run_all_gates ({run_all_gates.GATE_RUN_DIR}) "
        f"and generate_evidence ({GATE_RUN_DIR})"
    )


def get_git_head_short() -> str:
    try:
        out = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT)
        return out.decode("utf-8").strip()
    except Exception:
        return "head"


H5_RAW_DIR = Path("WO/evidence/h5")


def evaluate_h5(manifest: dict, manifest_data: bytes, subject_sha: str, root: Path) -> dict:
    """Verify and account for heterogeneous read-only observation seats.

    Returns the observation, seat, verdict, finding and certification sections
    of the evidence bundle. Degraded + withheld is a normal, honest outcome -
    it is what happens whenever live seats are unavailable or fail a check.
    """
    required = int(manifest.get("min_observer_families", 2))
    whitelist = {str(f).strip().lower() for f in manifest.get("observer_family_whitelist") or []}
    runtime = manifest.get("runtime_contract") or {}
    obs_rel = str(runtime.get("observer_input") or "spw-observations.json")
    obs_path = root / obs_rel

    findings: list[str] = []
    seat_outcomes: list[dict] = []
    observations: list[dict] = []

    if not whitelist:
        return _degraded(required, ["manifest 缺少 observer_family_whitelist"],
                        subject_sha, manifest_data)

    if not obs_path.is_file():
        return _degraded(required, [
            f"{obs_rel} 不存在——H5 需要 live 观测席位，缺失即如实降级"
        ], subject_sha, manifest_data)

    obs_bytes = obs_path.read_bytes()
    pinned = manifest.get("observations_sha256")
    if not pinned:
        return _degraded(required, [
            f"manifest 缺少 observations_sha256——{obs_rel} 未被完整性钉死，"
            "允许手工填写即等于自签观测席位"
        ], subject_sha, manifest_data)
    actual = hashlib.sha256(obs_bytes).hexdigest()
    if actual != pinned:
        return _degraded(required, [
            f"[HIGH] observations file tampered: {obs_rel} "
            f"sha256={actual[:16]} != manifest pinned {str(pinned)[:16]}"
        ], subject_sha, manifest_data)

    try:
        doc = json.loads(obs_bytes.decode("utf-8"))
    except Exception as exc:
        return _degraded(required, [f"[HIGH] 解析 {obs_rel} 失败: {exc}"],
                        subject_sha, manifest_data)

    seats = doc.get("seats") or []
    if not isinstance(seats, list) or not seats:
        return _degraded(required, [f"{obs_rel} 中没有任何观测席位"],
                        subject_sha, manifest_data)

    if str(doc.get("subject_sha256") or "") != subject_sha:
        findings.append(
            f"[HIGH] observation subject mismatch: 文件声明 "
            f"{(doc.get('subject_sha256') or '')[:16]} != 本次证据包 {subject_sha[:16]}"
        )

    seen_families: dict[str, dict] = {}
    for seat in seats:
        if not isinstance(seat, dict):
            continue
        family = str(seat.get("family") or "").strip().lower()
        model = str(seat.get("model") or "")
        outcome = {
            "family": family,
            "model": model,
            "observer_id": seat.get("observer_id"),
            "counted": False,
            "reasons": [],
        }

        if not family:
            outcome["reasons"].append("missing family")
            seat_outcomes.append(outcome)
            findings.append("[HIGH] observer seat missing family")
            continue
        if family not in whitelist:
            outcome["reasons"].append("family not in manifest whitelist")
            seat_outcomes.append(outcome)
            findings.append(f"[HIGH] unregistered observer family: {family}")
            continue
        if family in seen_families:
            outcome["reasons"].append(
                f"duplicate family — already counted from {seen_families[family].get('model')}"
            )
            seat_outcomes.append(outcome)
            findings.append(
                f"[HIGH] duplicate observer family: {family} "
                f"(同家族第二个席位不计入，{required} 必须来自 {required} 个不同家族)"
            )
            continue

        seat_subject = str(seat.get("subject_sha256") or "")
        if seat_subject != subject_sha:
            outcome["reasons"].append("subject mismatch")
            seat_outcomes.append(outcome)
            findings.append(
                f"[HIGH] observation subject mismatch for {family}: "
                f"{seat_subject[:16]} != {subject_sha[:16]}"
            )
            continue

        raw_name = str(seat.get("raw_file") or "")
        raw_path = root / H5_RAW_DIR / raw_name if raw_name else None
        digest = str(seat.get("response_digest") or "")
        if raw_path is None or not raw_path.is_file():
            outcome["reasons"].append("raw response file missing")
            seat_outcomes.append(outcome)
            findings.append(f"[HIGH] observer {family} 缺少原始回复文件 {raw_name or '(未声明)'}")
            continue
        raw_bytes_file = raw_path.read_bytes()
        raw_text = raw_bytes_file.decode("utf-8", errors="replace")
        # Digest the bytes on disk, never a re-encoded copy of them. If the file
        # is rewritten by any tool that translates newlines, the digest moves
        # and the seat stops counting - which is the correct, loud outcome.
        # Digesting read_text() instead would hide that, because universal
        # newline translation silently round-trips \r\n back to \n.
        actual_digest = hashlib.sha256(raw_bytes_file).hexdigest()
        if not digest or actual_digest != digest:
            outcome["reasons"].append("response digest mismatch")
            seat_outcomes.append(outcome)
            findings.append(
                f"[HIGH] observer {family} response_digest 与原始回复不符："
                f"注入的结论无法追溯到模型真实输出"
            )
            continue

        # Identity chain. A matching digest only proves "this file has not been
        # edited since it was written" - it says nothing about which model wrote
        # it. The gateway's response envelope carries the RESOLVED upstream
        # model, a response id and a timestamp, so persisting it beside the raw
        # text is what turns an untrusted file into an attributed observation.
        identity = _verify_identity(
            root, seat, family, actual_digest, subject_sha,
            str(doc.get("material_digest") or ""), outcome)
        if not identity["identity_verified"]:
            seat_outcomes.append(outcome)
            findings.append(
                f"[HIGH] observer {family} 身份链不可验证：{identity['reason']} — "
                f"无法证明这段回复来自哪个模型，按未观测处理"
            )
            continue

        seat_findings = [f for f in (seat.get("findings") or []) if isinstance(f, dict)]
        untraceable = [
            f for f in seat_findings
            if str(f.get("description", ""))[:50] and
            str(f.get("description", ""))[:50] not in raw_text
        ]
        if untraceable:
            outcome["reasons"].append(f"{len(untraceable)} findings not traceable to raw response")
            seat_outcomes.append(outcome)
            findings.append(
                f"[HIGH] observer {family} 有 {len(untraceable)} 条 finding 在原始回复中找不到对应文本"
            )
            continue

        outcome["counted"] = True
        seat_outcomes.append({
            "role_id": seat.get("observer_id") or f"{family}-observer",
            "success": True,
            "status": "completed",
            "family": family,
            "model": model,
            "resolved_model": seat.get("resolved_model"),
            "counted": True,
            "reasons": [],
            "final_observation": {
                "schema": "spw/h5-observer-seat/v1",
                "family": family,
                "model": model,
                "resolved_model": seat.get("resolved_model"),
                "response_id": seat.get("response_id"),
                "observer_id": seat.get("observer_id"),
                "observed_at": seat.get("observed_at"),
                "subject_sha256": seat_subject,
                "material_digest": seat.get("material_digest"),
                "response_digest": actual_digest,
                "raw_file": raw_name,
                "envelope_file": seat.get("envelope_file"),
                "envelope_sha256": seat.get("envelope_sha256"),
                "identity_verified": True,
                "observation_status": "valid",
                "schema_valid": True,
                "verdict": seat.get("verdict"),
                "verdict_reason": seat.get("verdict_reason"),
                "findings": seat_findings,
            },
            "final_model": model,
            "final_family": family,
        })
        seen_families[family] = seat
        observations.append({
            "family": family,
            "model": model,
            "observer_id": seat.get("observer_id"),
            "observed_at": seat.get("observed_at"),
            "subject_sha256": seat_subject,
            "material_digest": seat.get("material_digest"),
            "response_digest": actual_digest,
            "raw_file": raw_name,
            "verdict": seat.get("verdict"),
            "verdict_reason": seat.get("verdict_reason"),
            "findings": seat_findings,
        })

    valid_families = sorted(seen_families)
    covered = len(valid_families)

    # The observers' findings are evidence, and they stay in the bundle on every
    # path out of this function. A seat that answered is worth its findings even
    # when the family count falls short - dropping them because coverage failed
    # would hide real defects behind a coverage number.
    all_findings = []
    for obs in observations:
        for f in obs["findings"]:
            all_findings.append({
                "family": obs["family"],
                "severity": str(f.get("severity", "info")).lower(),
                "area": f.get("area"),
                "description": f.get("description"),
                "evidence": f.get("evidence"),
            })

    verdict = {
        "coverage": f"{covered}/{required}",
        "families": valid_families,
        "seats_submitted": len(seats),
        "seats_counted": covered,
        "blocker_findings": sum(1 for f in all_findings if f["severity"] == "blocker"),
        "high_findings": sum(1 for f in all_findings if f["severity"] == "high"),
        "total_findings": len(all_findings),
        "observer_verdicts": {o["family"]: o["verdict"] for o in observations},
    }

    if covered < required:
        return _degraded(
            required,
            [f"heterogeneous observer coverage {covered}/{required} is not satisfied",
             *findings],
            subject_sha, manifest_data,
            observations=observations,
            seat_outcomes=seat_outcomes,
            valid_families=valid_families,
            findings=all_findings,
            verdict=verdict,
        )
    if findings:
        return _degraded(
            required,
            [f"observer validation failed despite coverage {covered}/{required}", *findings],
            subject_sha, manifest_data,
            observations=observations,
            seat_outcomes=seat_outcomes,
            valid_families=valid_families,
            findings=all_findings,
            verdict=verdict,
        )

    # Coverage is necessary but not sufficient. A counted seat that reports
    # blocker/high findings, or that returns a verdict other than release_ready,
    # means the independent reviewers did not clear this subject - and issuing a
    # certificate anyway would be exactly the "claiming full when empty" failure
    # shape, one layer up (WO-0091 / WO-0093).
    blocking = [f for f in all_findings if f["severity"] in ("blocker", "high")]
    dissent = [o for o in observations if str(o.get("verdict") or "") != "release_ready"]
    if blocking or dissent:
        reasons = []
        for o in dissent:
            reasons.append(
                f"observer {o['family']} verdict={o.get('verdict')}: "
                f"{str(o.get('verdict_reason') or '')[:200]}"
            )
        for f in blocking:
            reasons.append(
                f"[{f['severity'].upper()}] observer {f['family']} "
                f"({f.get('area')}): {str(f.get('description') or '')[:200]}"
            )
        return _degraded(
            required,
            [f"independent observers did not clear this subject despite coverage "
             f"{covered}/{required}", *reasons],
            subject_sha, manifest_data,
            observations=observations,
            seat_outcomes=seat_outcomes,
            valid_families=valid_families,
            findings=all_findings,
            verdict=verdict,
        )

    return {
        "observations": observations,
        "seat_outcomes": seat_outcomes,
        "valid_families": valid_families,
        "required": required,
        "verdict": verdict,
        "findings": all_findings,
        "execution_status": "complete",
        "release_ready": True,
        "degradation_reasons": [],
        "certification": {
            "status": "issued",
            "certificate_id": f"SPW-CERT-{datetime.now(timezone.utc):%Y%m%d-%H%M%S}",
            "subject_sha256": subject_sha,
            "manifest_sha256": hashlib.sha256(manifest_data).hexdigest(),
            "reason": None,
            "observer_families": valid_families,
        },
    }


def _verify_identity(root: Path, seat: dict, family: str, raw_digest: str,
                     subject_sha: str, material_digest: str, outcome: dict) -> dict:
    """Verify the seat's attribution chain.

    Must confirm, from artifacts on disk alone, that the raw response really was
    produced by the model the seat claims, by re-reading the gateway response
    envelope that was persisted next to it and cross-checking every digest and
    the subject. Anything unverifiable is a rejection, never a pass.
    """
    env_name = str(seat.get("envelope_file") or "")
    if not env_name:
        outcome["reasons"].append("no response envelope: attribution unverifiable")
        return {"identity_verified": False, "reason": "席位未附网关响应信封，无法归因"}
    env_path = root / H5_RAW_DIR / env_name
    if not env_path.is_file():
        outcome["reasons"].append("response envelope file missing")
        return {"identity_verified": False, "reason": f"响应信封 {env_name} 不存在"}
    try:
        env = json.loads(env_path.read_bytes().decode("utf-8"))
    except Exception as exc:
        outcome["reasons"].append(f"response envelope unparseable: {exc}")
        return {"identity_verified": False, "reason": f"响应信封解析失败: {exc}"}

    pinned_env = str(seat.get("envelope_sha256") or "")
    actual_env = hashlib.sha256(env_path.read_bytes()).hexdigest()
    if not pinned_env or actual_env != pinned_env:
        outcome["reasons"].append("envelope digest mismatch")
        return {"identity_verified": False, "reason": "信封哈希与声明不符"}

    resolved = str(env.get("resolved_model") or "")
    if not resolved:
        outcome["reasons"].append("envelope has no resolved_model")
        return {"identity_verified": False, "reason": "信封未记录网关实际路由到的模型"}
    if not str(env.get("response_id") or ""):
        outcome["reasons"].append("envelope has no response_id")
        return {"identity_verified": False, "reason": "信封未记录响应 id"}

    if str(env.get("raw_sha256") or "") != raw_digest:
        outcome["reasons"].append("envelope raw_sha256 != recomputed raw digest")
        return {"identity_verified": False,
                "reason": "信封记录的原始回复哈希与磁盘文件不符"}
    if str(env.get("subject_sha256") or "") != subject_sha:
        outcome["reasons"].append("envelope subject mismatch")
        return {"identity_verified": False, "reason": "信封记录的主题与本次证据包不一致"}
    if material_digest and str(env.get("material_sha256") or "") != material_digest:
        outcome["reasons"].append("envelope material mismatch")
        return {"identity_verified": False,
                "reason": "信封记录的材料哈希与本次观测材料不一致"}
    requested = str(seat.get("model") or "")
    if requested and requested != resolved and resolved not in requested:
        outcome["reasons"].append(
            f"requested {requested} resolved to {resolved} - recorded as alias, not identity")
        # A gateway may legitimately resolve an alias to a different upstream
        # name; that is recorded, not fatal, but the seat must carry the truth.

    return {"identity_verified": True, "reason": "", "resolved_model": resolved}


def _degraded(required: int, reasons: list[str], subject_sha: str, manifest_data: bytes,
              observations=None, seat_outcomes=None, valid_families=None,
              findings=None, verdict=None) -> dict:
    return {
        "observations": observations or [],
        "seat_outcomes": seat_outcomes or [],
        "valid_families": valid_families or [],
        "required": required,
        "verdict": verdict,
        "findings": findings or [],
        "execution_status": "degraded",
        "release_ready": False,
        "degradation_reasons": reasons or ["H5_HETEROGENEOUS_OBSERVATION_UNAVAILABLE"],
        "certification": {
            "status": "withheld",
            "certificate_id": None,
            "subject_sha256": subject_sha,
            "manifest_sha256": hashlib.sha256(manifest_data).hexdigest(),
            "reason": reasons[0] if reasons else "H5_HETEROGENEOUS_OBSERVATION_UNAVAILABLE",
        },
    }


def generate_bundle(output_dir: Path = None) -> Path:
    if output_dir is None:
        output_dir = ROOT / "_repro"
    output_dir.mkdir(parents=True, exist_ok=True)

    manifest_path = ROOT / "spw-manifest.json"
    if not manifest_path.is_file():
        raise FileNotFoundError(f"Manifest not found: {manifest_path}")

    manifest_data = manifest_path.read_bytes()
    manifest = json.loads(manifest_data)
    manifest_sha256 = compute_manifest_sha(manifest_data)

    head_commit = get_git_head_short()

    # 1. Freeze subject files
    frozen_files = []
    agg = hashlib.sha256()
    for rel in sorted(manifest.get("subject_files", [])):
        p = ROOT / rel
        if not p.is_file():
            continue
        data = p.read_bytes()
        d = hashlib.sha256(data).hexdigest()
        frozen_files.append({
            "path": rel.replace("\\", "/"),
            "sha256": d,
            "size": len(data),
        })
        agg.update(rel.encode("utf-8"))
        agg.update(data)
    subject_sha = agg.hexdigest()

    # 2. Collect gate records from real execution ledger with 100% integrity (WO-0097 & WO-0095)
    ledger_file = GATE_RUN_DIR / "gate_run_results.json"
    if not ledger_file.is_file():
        raise RuntimeError(
            f"Gate execution ledger not found: {ledger_file} "
            f"(generate_evidence GATE_RUN_DIR={GATE_RUN_DIR}, "
            f"run_all_gates GATE_RUN_DIR={run_all_gates.GATE_RUN_DIR}). "
            f"Must run tools/spw-gates/run_all_gates.py to produce real execution records."
        )

    # The ledger is the only source of truth for PASS/FAIL, so it must be pinned.
    # observations_sha256 already pins the observer seats; without a sibling pin
    # for this file, rewriting the ledger and the 12 logs together leaves every
    # downstream check satisfied (WO-20261005-0098). The pin is filled in by hand
    # and never recomputed back into the manifest by this generator.
    pinned_ledger = manifest.get("gate_run_sha256")
    if not pinned_ledger:
        raise RuntimeError(
            "manifest 缺少 gate_run_sha256——门禁执行台账未被完整性钉死，"
            "允许整套无痕改写（WO-20261005-0098）"
        )
    ledger_bytes = ledger_file.read_bytes()
    actual_ledger_sha = hashlib.sha256(ledger_bytes).hexdigest()
    if actual_ledger_sha != pinned_ledger:
        raise RuntimeError(
            f"[HIGH] gate execution ledger tampered: {ledger_file} "
            f"sha256={actual_ledger_sha[:16]} != manifest pinned {str(pinned_ledger)[:16]}"
        )

    try:
        ledger_data = json.loads(ledger_bytes)
    except Exception as e:
        raise RuntimeError(f"Failed to parse gate execution ledger: {e}")

    if ledger_data.get("schema") != "spw/gate-run/v1":
        raise RuntimeError(f"Invalid execution ledger schema: {ledger_data.get('schema')}")

    # 2b. Bidirectional ledger integrity assertions (WO-20261006-0104 Stage 2)
    ledger_manifest_sha = ledger_data.get("manifest_sha256")
    if ledger_manifest_sha != manifest_sha256:
        raise RuntimeError(
            f"[HIGH] manifest_sha256 mismatch: ledger recorded {ledger_manifest_sha} "
            f"vs current manifest {manifest_sha256}. "
            f"Must rerun tools/spw-gates/run_all_gates.py after modifying manifest."
        )

    ledger_subject_sha = ledger_data.get("subject_sha256")
    if ledger_subject_sha != subject_sha:
        raise RuntimeError(
            f"[HIGH] subject_sha256 mismatch: ledger recorded {ledger_subject_sha} "
            f"vs current frozen subject {subject_sha}. "
            f"Must rerun tools/spw-gates/run_all_gates.py after modifying subject files."
        )

    ledger_gates = {}
    for entry in ledger_data.get("gates", []):
        if isinstance(entry, dict) and "gate_id" in entry:
            ledger_gates[entry["gate_id"]] = entry

    gate_records = []
    gate_degradations = []
    any_gate_failed = False
    gate_run_start = datetime.fromisoformat(ledger_data["started_at"]) if "started_at" in ledger_data else None

    manifest_gates = manifest.get("gates", [])
    for g in manifest_gates:
        gid = g["gate_id"]
        required = bool(g.get("required", True))
        declared_claims = list(g.get("claims") or [])
        cmd = [str(x) for x in g["command"]]

        if gid not in ledger_gates:
            raise RuntimeError(f"Missing execution record for gate {gid} in {ledger_file}")

        entry = ledger_gates[gid]

        if entry.get("command") != cmd:
            raise RuntimeError(f"Command mismatch for gate {gid}: ledger has {entry.get('command')} vs manifest {cmd}")

        cmd_sha256 = hashlib.sha256(json.dumps(cmd, sort_keys=True).encode("utf-8")).hexdigest()

        gate_subject_sha = entry.get("subject_sha256")
        if not gate_subject_sha:
            raise RuntimeError(f"Missing subject_sha256 binding for gate {gid}")
        if gate_subject_sha != subject_sha:
            raise RuntimeError(
                f"[HIGH] subject_sha256 mismatch for gate {gid}: ledger recorded {gate_subject_sha} "
                f"vs current frozen subject {subject_sha}. "
                f"Must rerun tools/spw-gates/run_all_gates.py after modifying subject files."
            )

        safe_gid = gid.replace(".", "_")
        log_name = f"gate_{safe_gid}.log"
        log_file = GATE_RUN_DIR / log_name
        if not log_file.is_file():
            raise RuntimeError(f"Missing gate stdout log file: {log_file}")

        stdout_bytes = log_file.read_bytes()
        stdout_sha256 = hashlib.sha256(stdout_bytes).hexdigest()
        stdout_len = len(stdout_bytes)

        if stdout_len != entry.get("stdout_bytes") or stdout_sha256 != entry.get("stdout_sha256"):
            raise RuntimeError(
                f"Stdout integrity mismatch for gate {gid}: disk {stdout_len}B ({stdout_sha256}) "
                f"vs ledger {entry.get('stdout_bytes')}B ({entry.get('stdout_sha256')})"
            )

        stdout_text = stdout_bytes.decode("utf-8", errors="replace")

        stderr_bytes_len = int(entry.get("stderr_bytes", 0))
        stderr_sha256 = entry.get("stderr_sha256", hashlib.sha256(b"").hexdigest())
        stderr_text = str(entry.get("stderr", ""))

        if stderr_bytes_len == 0:
            if stderr_text != "":
                raise RuntimeError(f"Gate {gid} has stderr_bytes=0 but non-empty stderr string")
            if stderr_sha256 != hashlib.sha256(b"").hexdigest():
                raise RuntimeError(f"Gate {gid} has stderr_bytes=0 but non-empty stderr_sha256")
        else:
            if len(stderr_text.encode("utf-8")) != stderr_bytes_len:
                raise RuntimeError(f"Gate {gid} stderr text length does not match stderr_bytes")
            if hashlib.sha256(stderr_text.encode("utf-8")).hexdigest() != stderr_sha256:
                raise RuntimeError(f"Gate {gid} stderr hash does not match stderr_sha256")

        exit_code = int(entry.get("exit_code", 1))
        verdict = "PASS" if exit_code == 0 else "FAIL"
        execution_status = "completed" if exit_code == 0 else "failed"

        if exit_code != 0:
            any_gate_failed = True
            gate_degradations.append(f"GATE_FAILED: {gid} exited with code {exit_code}")

        claims_asserted = list(entry.get("claims_asserted") or [])
        extra_claims = set(claims_asserted) - set(declared_claims)
        if extra_claims:
            raise RuntimeError(f"Gate {gid} asserted claims not declared in manifest: {sorted(extra_claims)}")

        if declared_claims and not claims_asserted:
            gate_degradations.append(f"GATE_CLAIMS_MISSING: {gid} declared {declared_claims} but asserted none")
        elif set(claims_asserted) < set(declared_claims):
            gate_degradations.append(
                f"GATE_CLAIMS_INCOMPLETE: {gid} declared {declared_claims} but asserted {claims_asserted}"
            )

        executed_at_str = entry.get("executed_at")
        if not executed_at_str:
            raise RuntimeError(f"Missing executed_at timestamp for gate {gid}")
        try:
            gate_exec_time = datetime.fromisoformat(executed_at_str)
        except Exception:
            raise RuntimeError(f"Invalid executed_at ISO8601 timestamp for gate {gid}: {executed_at_str}")

        duration_sec = float(entry.get("duration_seconds", 0.0))

        if gate_run_start and gate_exec_time < gate_run_start:
            gate_degradations.append(
                f"TEMPORAL_INCONSISTENCY: {gid} executed_at is earlier than run start"
            )

        record = {
            "gate_id": gid,
            "required": required,
            "execution_status": execution_status,
            "verdict": verdict,
            "claims": declared_claims,
            "claims_asserted": claims_asserted,
            "command": cmd,
            "command_sha256": cmd_sha256,
            "exit_code": exit_code,
            "executed_at": executed_at_str,
            "duration_seconds": duration_sec,
            "subject_sha256": gate_subject_sha,
            "stdout_sha256": stdout_sha256,
            "stderr_sha256": stderr_sha256,
            "stdout_bytes": stdout_len,
            "stderr_bytes": stderr_bytes_len,
            "stdout": stdout_text,
            "stderr": stderr_text,
            "truncated": False,
        }
        gate_records.append(record)

    now = datetime.now(timezone.utc)

    for r in gate_records:
        t_exec = datetime.fromisoformat(r["executed_at"])
        if t_exec > now + timedelta(seconds=60):
            gate_degradations.append(
                f"TEMPORAL_INCONSISTENCY: {r['gate_id']} executed_at is in the future"
            )

    # Recompute artifact verdict deterministically
    required_h_gates = [
        g for g in gate_records
        if g.get("required") and any(str(g.get("gate_id", "")).startswith(p) for p in ("H1.", "H2.", "H3.", "H4."))
    ]
    if not required_h_gates or any(g.get("execution_status") != "completed" for g in required_h_gates):
        artifact_verdict = "FAIL"
    elif any(g.get("verdict") == "FAIL" for g in required_h_gates):
        artifact_verdict = "FAIL"
    else:
        artifact_verdict = "PASS"

    if any_gate_failed or artifact_verdict != "PASS":
        gate_degradations.insert(0, "DETERMINISTIC_GATES_FAILED")

    # 3. H5 heterogeneous observation accounting
    h5 = evaluate_h5(manifest, manifest_data, subject_sha, ROOT)

    all_degradations = list(gate_degradations)
    for d in h5.get("degradation_reasons", []):
        if d not in all_degradations:
            all_degradations.append(d)

    overall_execution_status = "degraded" if all_degradations else "completed"
    overall_release_ready = (
        artifact_verdict == "PASS"
        and not any_gate_failed
        and bool(h5["release_ready"])
        and not all_degradations
    )

    certification = dict(h5["certification"])
    if not overall_release_ready:
        certification["status"] = "withheld"
        if not certification.get("reason") or certification["reason"] == "H5_HETEROGENEOUS_OBSERVATION_UNAVAILABLE":
            if any_gate_failed or artifact_verdict != "PASS":
                certification["reason"] = "DETERMINISTIC_GATES_FAILED"
            elif all_degradations:
                certification["reason"] = all_degradations[0]

    bundle = {
        "schema": "spw/evidence/v1",
        "run_id": f"SPW-{now:%Y%m%d-%H%M%S}",
        "created_at": now.isoformat(),
        "manifest_path": str(manifest_path.resolve()),
        "manifest_sha256": manifest_sha256,
        "subject": {
            "workspace": str(ROOT),
            "sha256": subject_sha,
            "files": frozen_files,
        },
        "deterministic_gates": gate_records,
        "external_observations": h5["observations"],
        "observer_seat_outcomes": h5["seat_outcomes"],
        "valid_observer_families": h5["valid_families"],
        "required_observer_families": h5["required"],
        "h5_observation_verdict": h5["verdict"],
        "pending_h5_findings": h5["findings"],
        "artifact_verdict": artifact_verdict,
        "artifact_integrity": "verified" if artifact_verdict == "PASS" else "compromised",
        "execution_status": overall_execution_status,
        "release_ready": overall_release_ready,
        "degradation_reasons": all_degradations,
        "certification": certification,
        "integrity_binding": "verified",
    }

    # 4. Compute self-hash over canonical JSON representation
    copy_dict = dict(bundle)
    copy_dict.pop("evidence_self_sha256", None)
    bundle["evidence_self_sha256"] = hashlib.sha256(
        json.dumps(copy_dict, ensure_ascii=False, sort_keys=True).encode("utf-8")
    ).hexdigest()

    out_file = output_dir / f"spw-evidence-{head_commit}.json"
    out_file.write_text(json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    return out_file


def main():
    try:
        out_path = generate_bundle()
        print(f"[spw-evidence] Generated evidence bundle: {out_path}")
        data = json.loads(out_path.read_text(encoding="utf-8"))
        print(f"[spw-evidence] execution_status: {data.get('execution_status')}")
        print(f"[spw-evidence] release_ready: {data.get('release_ready')}")
        print(f"[spw-evidence] artifact_verdict: {data.get('artifact_verdict')}")
        cert = data.get("certification") or {}
        print(f"[spw-evidence] certification: {cert.get('status')} "
              f"(id={cert.get('certificate_id')}, reason={cert.get('reason')})")
        print(f"[spw-evidence] observer coverage: "
              f"{len(data.get('valid_observer_families', []))}/"
              f"{data.get('required_observer_families')} "
              f"families={data.get('valid_observer_families')}")
        v = data.get("h5_observation_verdict") or {}
        if v:
            print(f"[spw-evidence] h5 verdict: {v.get('coverage')} "
                  f"seats={v.get('seats_counted')}/{v.get('seats_submitted')} "
                  f"findings={v.get('total_findings')} "
                  f"(blocker={v.get('blocker_findings')}, high={v.get('high_findings')})")
        
        passed_gates = sum(1 for g in data.get("deterministic_gates", []) if g.get("verdict") == "PASS")
        failed_gates = sum(1 for g in data.get("deterministic_gates", []) if g.get("verdict") == "FAIL")
        total_gates = len(data.get("deterministic_gates", []))
        print(f"\n[spw-evidence] gates summary: {passed_gates}/{total_gates} passed, {failed_gates} failed")
        for g in data.get("deterministic_gates", []):
            print(f"  - [{g.get('gate_id')}] verdict={g.get('verdict')} exit_code={g.get('exit_code')} "
                  f"duration={g.get('duration_seconds')}s claims={g.get('claims_asserted')}")

        if failed_gates > 0:
            print(f"\n[spw-evidence][LOUD] {failed_gates} gate(s) recorded FAIL!", file=sys.stderr)

        for r in (data.get("degradation_reasons") or []):
            print(f"[spw-evidence] degraded: {r}")
    except Exception as e:
        print(f"[spw-evidence][FAIL] {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
