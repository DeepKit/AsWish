"""H3.runtime-autofix
counterfactual_3: dpr must install InstallAIErrorHandler/AutoFix.Install/TAutoFixVclHook.Install
counterfactual_4: AutoFix scenario registration must exist in MainForm
counterfactual_5: boundary.json must be valid JSON with allowed/blocked paths"""
import json
import re
import sys
from pathlib import Path
from gate_lib import ROOT, read, fail, ok

findings = []

dpr = ROOT / "AsWish.dpr"
if not dpr.is_file():
    findings.append("AsWish.dpr not found")
else:
    text = read(dpr)
    for token in ("InstallAIErrorHandler", "AutoFix.Install", "TAutoFixVclHook"):
        if token not in text:
            findings.append(f"AsWish.dpr missing required install: {token}")

mf = ROOT / "src/app/AsWish.MainForm.pas"
if not mf.is_file():
    findings.append("MainForm not found")
elif "RegisterScenario" not in read(mf):
    findings.append("MainForm has no RegisterScenario (runtime autofix scenarios missing)")

bj = ROOT / "boundary.json"
if not bj.is_file():
    findings.append("boundary.json missing at repo root")
else:
    try:
        data = json.loads(bj.read_text(encoding="utf-8"))
        for key in ("allowed_paths", "blocked_paths"):
            if key not in data:
                findings.append(f"boundary.json missing '{key}' section")
    except json.JSONDecodeError as e:
        findings.append(f"boundary.json invalid JSON: {e}")

if findings:
    fail("H3.runtime-autofix", findings)
ok("H3.runtime-autofix")
