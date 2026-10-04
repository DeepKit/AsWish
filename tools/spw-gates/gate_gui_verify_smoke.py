"""H3.gui-verify-smoke (runtime smoke test for --gui-verify pipeline)
counterfactual: 0ms wait guard or failed WebView2 causes verification to fail"""
import os
import sys
import ctypes
import ctypes.wintypes
from pathlib import Path
from gate_lib import ROOT, fail, ok

class STARTUPINFO(ctypes.Structure):
    _fields_ = [
        ("cb", ctypes.wintypes.DWORD),
        ("lpReserved", ctypes.c_wchar_p),
        ("lpDesktop", ctypes.c_wchar_p),
        ("lpTitle", ctypes.c_wchar_p),
        ("dwX", ctypes.wintypes.DWORD),
        ("dwY", ctypes.wintypes.DWORD),
        ("dwXSize", ctypes.wintypes.DWORD),
        ("dwYSize", ctypes.wintypes.DWORD),
        ("dwXCountChars", ctypes.wintypes.DWORD),
        ("dwYCountChars", ctypes.wintypes.DWORD),
        ("dwFillAttribute", ctypes.wintypes.DWORD),
        ("dwFlags", ctypes.wintypes.DWORD),
        ("wShowWindow", ctypes.wintypes.WORD),
        ("cbReserved2", ctypes.wintypes.WORD),
        ("lpReserved2", ctypes.c_void_p),
        ("hStdInput", ctypes.wintypes.HANDLE),
        ("hStdOutput", ctypes.wintypes.HANDLE),
        ("hStdError", ctypes.wintypes.HANDLE),
    ]

class PROCESS_INFORMATION(ctypes.Structure):
    _fields_ = [
        ("hProcess", ctypes.wintypes.HANDLE),
        ("hThread", ctypes.wintypes.HANDLE),
        ("dwProcessId", ctypes.wintypes.DWORD),
        ("dwThreadId", ctypes.wintypes.DWORD),
    ]

GATE_ID = "H3.gui-verify-smoke"
EXE = ROOT / "bin" / "AsWish.exe"
if not EXE.is_file():
    fail(GATE_ID, [f"binary not found: {EXE} (run build first)"])

project_dir = ROOT / "dogfood_gui_site_final"
if not project_dir.is_dir():
    fail(GATE_ID, [f"test project not found: {project_dir}"])

out_file = ROOT / "dogfood_gui" / "smoke_out.txt"
err_file = ROOT / "dogfood_gui" / "smoke_err.txt"
evidence_file = ROOT / "dogfood_gui" / "gui-dual-surface.txt"
out_file.parent.mkdir(parents=True, exist_ok=True)

# Clean previous outputs
for p in (out_file, err_file):
    if p.exists():
        try:
            p.unlink()
        except Exception:
            pass

cmd = f'cmd.exe /c "{EXE} --gui-verify {project_dir.name} > {out_file} 2> {err_file}"'

si = STARTUPINFO()
si.cb = ctypes.sizeof(STARTUPINFO)
si.lpDesktop = r"WinSta0\Default"
pi = PROCESS_INFORMATION()

res = ctypes.windll.kernel32.CreateProcessW(
    None, cmd, None, None, False, 0, None, str(ROOT), ctypes.byref(si), ctypes.byref(pi)
)
if not res:
    fail(GATE_ID, [f"CreateProcess failed with code {ctypes.GetLastError()}"])

ctypes.windll.kernel32.WaitForSingleObject(pi.hProcess, 30000)
exit_code = ctypes.wintypes.DWORD()
ctypes.windll.kernel32.GetExitCodeProcess(pi.hProcess, ctypes.byref(exit_code))
ctypes.windll.kernel32.CloseHandle(pi.hProcess)
ctypes.windll.kernel32.CloseHandle(pi.hThread)

findings = []
if exit_code.value != 0:
    err_text = err_file.read_text(encoding="utf-8", errors="replace") if err_file.exists() else ""
    findings.append(f"non-zero exit code: {exit_code.value} (stderr: {err_text.strip()[:200]})")

out_bytes = out_file.stat().st_size if out_file.exists() else 0
if out_bytes < 800:
    findings.append(f"stdout file size below threshold: {out_bytes} bytes < 800 bytes")

out_text = out_file.read_text(encoding="utf-8", errors="replace") if out_file.exists() else ""
evidence_text = evidence_file.read_text(encoding="utf-8", errors="replace") if evidence_file.exists() else ""

# Count PASS entries in evidence
pass_count = evidence_text.count("[PASS]")
if pass_count < 11:
    findings.append(f"insufficient [PASS] entries: {pass_count} < 11")

if findings:
    fail(GATE_ID, findings)

ok(GATE_ID, f"RC=0 stdout={out_bytes}B [PASS]={pass_count}")
