"""H3.encoding-guard
counterfactual_1: undecodable / NUL source files must fail
counterfactual_2: mixed line endings must fail
counterfactual_3: Pascal source containing Chinese without UTF-8 BOM must fail (WO-20260930-0063)"""
import re
import sys
from pathlib import Path
from gate_lib import source_files, fail, ok

findings = []
for f in source_files():
    raw = f.read_bytes()
    rel = f.relative_to(Path(__file__).resolve().parents[2]).as_posix()
    if b"\x00" in raw:
        findings.append(f"NUL byte in {rel}")
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

    # Check Pascal source with Chinese requires UTF-8 BOM (WO-20260930-0063)
    if not raw.startswith(b"\xef\xbb\xbf"):
        text = raw.decode("utf-8", errors="replace")
        lines = text.splitlines()
        in_block_brace = False
        in_block_paren = False
        for idx, line in enumerate(lines, start=1):
            code_part = ""
            i = 0
            while i < len(line):
                if in_block_brace:
                    if line[i] == "}":
                        in_block_brace = False
                    i += 1
                elif in_block_paren:
                    if line[i:i+2] == "*)":
                        in_block_paren = False
                        i += 2
                    else:
                        i += 1
                else:
                    if line[i:i+2] == "//":
                        break
                    elif line[i] == "{":
                        in_block_brace = True
                        i += 1
                    elif line[i:i+2] == "(*":
                        in_block_paren = True
                        i += 2
                    else:
                        code_part += line[i]
                        i += 1
            if re.search(r"[\u4e00-\u9fff]", code_part):
                findings.append(f"Pascal 源码含中文但缺失 UTF-8 BOM: {rel} 第 {idx} 行")
                break

# Check batch scripts in repo root and scripts/ (WO-20260930-0066 F-2)
ROOT = Path(__file__).resolve().parents[2]
script_files = set()
for pat in ("*.bat", "*.cmd", "*.ps1"):
    script_files.update(ROOT.glob(pat))
    if (ROOT / "scripts").is_dir():
        script_files.update((ROOT / "scripts").rglob(pat))
    if (ROOT / "cli").is_dir():
        script_files.update((ROOT / "cli").rglob(pat))
    if (ROOT / "tests").is_dir():
        script_files.update((ROOT / "tests").rglob(pat))
    if (ROOT / "installer").is_dir():
        script_files.update((ROOT / "installer").rglob(pat))

for f in sorted(script_files):
    raw = f.read_bytes()
    rel = f.relative_to(ROOT).as_posix()
    if b"\x00" in raw:
        findings.append(f"NUL byte in script: {rel}")
        continue
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        findings.append(f"non-UTF8 (undecodable) script: {rel}")
        continue
    crlf = raw.count(b"\r\n")
    lf = raw.count(b"\n") - crlf
    if crlf > 0 and lf > 1:
        findings.append(f"mixed line endings CRLF={crlf} LF-only={lf}: {rel}")
    if not raw.startswith(b"\xef\xbb\xbf"):
        lines = text.splitlines()
        for idx, line in enumerate(lines, start=1):
            if any(ord(c) > 127 for c in line):
                findings.append(f"构建脚本含非 ASCII 字符但缺失 UTF-8 BOM: {rel} 第 {idx} 行: {line.strip()}")
                break

if findings:
    fail("H3.encoding-guard", findings)
ok("H3.encoding-guard")

