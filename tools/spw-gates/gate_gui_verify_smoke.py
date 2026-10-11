"""H3.gui-verify-smoke (runtime smoke test for --gui-verify pipeline)
counterfactual: 0ms wait guard or failed WebView2 causes verification to fail"""
import json
import os
import sys
import ctypes
import ctypes.wintypes
import subprocess
from pathlib import Path
from gate_lib import ROOT, fail, ok

GATE_ID = "H3.gui-verify-smoke"

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

class IO_COUNTERS(ctypes.Structure):
    _fields_ = [
        ("ReadOperationCount", ctypes.c_uint64),
        ("WriteOperationCount", ctypes.c_uint64),
        ("OtherOperationCount", ctypes.c_uint64),
        ("ReadTransferCount", ctypes.c_uint64),
        ("WriteTransferCount", ctypes.c_uint64),
        ("OtherTransferCount", ctypes.c_uint64),
    ]

class JOBOBJECT_BASIC_LIMIT_INFORMATION(ctypes.Structure):
    _fields_ = [
        ("PerProcessUserTimeLimit", ctypes.c_int64),
        ("PerJobUserTimeLimit", ctypes.c_int64),
        ("LimitFlags", ctypes.wintypes.DWORD),
        ("MinimumWorkingSetSize", ctypes.c_size_t),
        ("MaximumWorkingSetSize", ctypes.c_size_t),
        ("ActiveProcessLimit", ctypes.wintypes.DWORD),
        ("Affinity", ctypes.c_size_t),
        ("PriorityClass", ctypes.wintypes.DWORD),
        ("SchedulingClass", ctypes.wintypes.DWORD),
    ]

class JOBOBJECT_EXTENDED_LIMIT_INFORMATION(ctypes.Structure):
    _fields_ = [
        ("BasicLimitInformation", JOBOBJECT_BASIC_LIMIT_INFORMATION),
        ("IoInfo", IO_COUNTERS),
        ("ProcessMemoryLimit", ctypes.c_size_t),
        ("JobMemoryLimit", ctypes.c_size_t),
        ("PeakProcessMemoryLimit", ctypes.c_size_t),
        ("PeakJobMemoryLimit", ctypes.c_size_t),
    ]

JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000
JobObjectExtendedLimitInformation = 9
WAIT_OBJECT_0 = 0x00000000
WAIT_TIMEOUT = 0x00000102


def create_kill_on_close_job() -> ctypes.wintypes.HANDLE:
    kernel32 = ctypes.windll.kernel32
    h_job = kernel32.CreateJobObjectW(None, None)
    if not h_job:
        return None
    info = JOBOBJECT_EXTENDED_LIMIT_INFORMATION()
    info.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    res = kernel32.SetInformationJobObject(
        h_job,
        JobObjectExtendedLimitInformation,
        ctypes.byref(info),
        ctypes.sizeof(info),
    )
    if not res:
        kernel32.CloseHandle(h_job)
        return None
    return h_job


def get_configured_timeout() -> int:
    timeout_sec = 180
    try:
        manifest_path = ROOT / "spw-manifest.json"
        if manifest_path.is_file():
            m_data = json.loads(manifest_path.read_text(encoding="utf-8"))
            for g in m_data.get("gates", []):
                if g.get("gate_id") == GATE_ID:
                    timeout_sec = int(g.get("timeout", timeout_sec))
                    break
    except Exception:
        pass
    return max(timeout_sec, 180)


def main():
    kernel32 = ctypes.windll.kernel32

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

    # Clean previous outputs using truncate rather than unlink (WO-0077/WO-0078 & Stage 4)
    for p in (out_file, err_file):
        try:
            with open(p, "w", encoding="utf-8") as f:
                pass
        except BaseException as e:
            fail(GATE_ID, [f"truncate/write failed on output file {p.name}: {e}"])

    cmd = f'cmd.exe /c "{EXE} --gui-verify {project_dir.name} > {out_file} 2> {err_file}"'

    si = STARTUPINFO()
    si.cb = ctypes.sizeof(STARTUPINFO)
    si.lpDesktop = r"WinSta0\Default"
    pi = PROCESS_INFORMATION()

    h_job = create_kill_on_close_job()

    res = kernel32.CreateProcessW(
        None, cmd, None, None, False, 0, None, str(ROOT), ctypes.byref(si), ctypes.byref(pi)
    )
    if not res:
        if h_job:
            kernel32.CloseHandle(h_job)
        fail(GATE_ID, [f"CreateProcess failed with code {ctypes.GetLastError()}"])

    if h_job:
        kernel32.AssignProcessToJobObject(h_job, pi.hProcess)

    timeout_sec = get_configured_timeout()
    timeout_ms = timeout_sec * 1000

    findings = []
    timed_out = False

    try:
        wait_res = kernel32.WaitForSingleObject(pi.hProcess, timeout_ms)
        if wait_res == WAIT_TIMEOUT:
            timed_out = True
            findings.append(f"process timed out (exceeded {timeout_sec}s limit)")
            if h_job:
                kernel32.TerminateJobObject(h_job, 1)
            kernel32.TerminateProcess(pi.hProcess, 1)
            subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(pi.dwProcessId)],
                capture_output=True,
                creationflags=0x08000000,
            )
        elif wait_res != WAIT_OBJECT_0:
            findings.append(f"WaitForSingleObject failed with code {wait_res}")
        else:
            exit_code = ctypes.wintypes.DWORD()
            kernel32.GetExitCodeProcess(pi.hProcess, ctypes.byref(exit_code))
            if exit_code.value != 0:
                err_text = err_file.read_text(encoding="utf-8", errors="replace") if err_file.exists() else ""
                findings.append(f"non-zero exit code: {exit_code.value} (stderr: {err_text.strip()[:200]})")
    finally:
        if timed_out or findings:
            if h_job:
                kernel32.TerminateJobObject(h_job, 1)
            if pi.hProcess:
                kernel32.TerminateProcess(pi.hProcess, 1)
        if pi.hProcess:
            kernel32.CloseHandle(pi.hProcess)
        if pi.hThread:
            kernel32.CloseHandle(pi.hThread)
        if h_job:
            kernel32.CloseHandle(h_job)

    out_bytes = out_file.stat().st_size if out_file.exists() else 0
    if out_bytes < 800:
        findings.append(f"stdout file size below threshold: {out_bytes} bytes < 800 bytes")

    evidence_text = evidence_file.read_text(encoding="utf-8", errors="replace") if evidence_file.exists() else ""

    # Count PASS entries in evidence
    pass_count = evidence_text.count("[PASS]")
    if pass_count < 11:
        findings.append(f"insufficient [PASS] entries: {pass_count} < 11")

    if findings:
        fail(GATE_ID, findings)

    ok(GATE_ID, f"RC=0 stdout={out_bytes}B gui_verify_checks={pass_count}", claims=["counterfactual_smoke"])


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as e:
        print(f"[{GATE_ID}][ABORTED] {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)
