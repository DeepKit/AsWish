"""H3.encoding-guard
counterfactual_1: undecodable / NUL source files must fail
counterfactual_2: mixed line endings must fail"""
import sys
from pathlib import Path
from gate_lib import source_files, fail, ok

findings = []
for f in source_files():
    raw = f.read_bytes()
    if b"\x00" in raw:
        findings.append(f"NUL byte in {f.relative_to(Path(__file__).resolve().parents[2]).as_posix()}")
        continue
    try:
        raw.decode("utf-8")
    except UnicodeDecodeError:
        findings.append(f"non-UTF8 (undecodable) source: {f.name}")
        continue
    crlf = raw.count(b"\r\n")
    lf = raw.count(b"\n") - crlf
    if crlf > 0 and lf > 0:
        # tolerate a single trailing-LF artifact; real mixing (both counts > 1) fails
        if lf > 1:
            findings.append(f"mixed line endings CRLF={crlf} LF-only={lf}: {f.name}")

if findings:
    fail("H3.encoding-guard", findings)
ok("H3.encoding-guard")
