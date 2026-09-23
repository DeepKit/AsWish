"""H3.deep-ui-test (static bridge dispatch audit; deep UI runtime is the GUI test's job)
counterfactual_6: every rendered data-action must have a host handler (dead-button class)
counterfactual_7: orphan host handlers reported (warning only, not a fail)
counterfactual_8: bridge dispatch audit deterministic (stable set on repeated extraction)"""
import re
import sys
from pathlib import Path
from gate_lib import ROOT, read, fail, ok

RENDER_FILES = [
    ROOT / "src/services/AsWish.Services.Render.pas",
    ROOT / "src/services/AsWish.Services.RenderDiff.pas",
]
MAINVIEW = ROOT / "src/providers/AsWish.Providers.MainView.pas"

# actions emitted by HTML/JS templates: data-action="X" or post({ action: "X" ... })
RENDERED_RE = re.compile(r'(?:data-action="|action:\s*")([a-z0-9][a-z0-9-]*)')
# host side: AAction = 'X' comparisons / case labels
HOST_RE = re.compile(r"(?:AAction|LAction|action)\s*=\s*'([a-z0-9][a-z0-9-]*)'")


def rendered_actions():
    out = set()
    for f in RENDER_FILES:
        if f.is_file():
            out.update(RENDERED_RE.findall(read(f)))
    return out


def host_actions():
    if not MAINVIEW.is_file():
        return set()
    return set(HOST_RE.findall(read(MAINVIEW)))


findings = []
r1, h1 = rendered_actions(), host_actions()
r2, h2 = rendered_actions(), host_actions()
if (r1, h1) != (r2, h2):
    findings.append("bridge audit not deterministic (counterfactual_8)")

dead = sorted(r1 - h1)
if dead:
    findings.append(f"dead buttons (rendered action without host handler): {dead}")

orphans = sorted(h1 - r1)  # reported, not failed (some handlers serve other surfaces)
if orphans:
    print(f"[H3.deep-ui-test] note: orphan host handlers (no rendered button): {orphans}")

if findings:
    fail("H3.deep-ui-test", findings)
ok("H3.deep-ui-test", f"rendered={len(r1)} handlers={len(h1)}")
