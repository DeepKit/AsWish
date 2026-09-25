"""Gate: open-source build & export shape.

Guards what made AsWish unpublishable before WO-20260925-0056, plus the leak
this gate itself would otherwise have missed.

1. Build must not reach the private DeepBase repository: a clean clone used to
   resolve it through a relative dcc64 search path and died with F2613 on the
   MainForm and the EHAI binding tests. The type layer it needed is vendored
   under vendor/deepbase-ehai.
2. Internal material must not leave the repository in a source export. WO/ and
   .workbuddy/ are the known cases, but verifying the export list turned up
   internal audit reports and handover packs outside them - one audit request
   even sat at the repository root - so this gate matches by content pattern,
   not by a hardcoded prefix list it already knows about.
"""
import re
import subprocess
import sys
import zipfile
import io
from pathlib import Path

GATE = "G.open-source-build"
ROOT = Path(__file__).resolve().parents[2]

BUILD_SCRIPTS = ["_build.bat", "cli/_build_cli.bat", "tests/_build_tests.bat"]
VENDOR_PATH = "vendor\\deepbase-ehai"

# Matched against the *exported* path list. A missing entry here means internal
# material shipped; that is a release blocker, not a warning.
INTERNAL_PATTERNS = [
    (r"(^|/)WO/", "work-order / governance directory"),
    (r"(^|/)\.workbuddy/", "daily working logs"),
    (r"(^|/)\.AsWish/", "protocol workspace state"),
    (r"(^|/)\.ai-workbench/", "workbench state"),
    (r"(^|/)\.claude/", "local agent state"),
    (r"(^|/)AUDIT-REQUEST-", "internal audit request"),
    (r"(^|/)AUDIT-VERDICT-", "internal audit verdict"),
    (r"(^|/)\.env", "environment / secrets"),
    (r"(^|/)(id_rsa|.*\.pem|.*\.p12|.*\.key)$", "key material"),
]

REQUIRED_EXPORT_IGNORE = ["WO/", ".workbuddy/", ".AsWish/", ".ai-workbench/"]
RELEASE_ESSENTIALS = ["README.md", "LICENSE", "NOTICE"]


def read(p: Path) -> str:
    return p.read_bytes().decode("utf-8", errors="replace")


def exported_files() -> set[str]:
    """Names inside `git archive HEAD`, read via zipfile.

    Earlier revision parsed the tar stream by hand and stepped every 512 bytes,
    which treated file *content* as headers and invented 7648 bogus entries -
    the gate passed while checking almost nothing. zipfile does real parsing.
    """
    out = subprocess.run(
        ["git", "archive", "--format=zip", "HEAD"],
        cwd=ROOT,
        capture_output=True,
        check=True,
    ).stdout
    with zipfile.ZipFile(io.BytesIO(out)) as zf:
        return {n.rstrip("/") for n in zf.namelist() if not n.endswith("/")}


def main() -> None:
    findings = []

    for rel in BUILD_SCRIPTS:
        p = ROOT / rel
        if not p.is_file():
            findings.append(f"构建脚本缺失: {rel}")
            continue
        text = read(p)
        if "DeepBase" in text:
            findings.append(f"{rel} 仍引用 DeepBase（构建必须脱离私有仓）")
        if VENDOR_PATH not in text:
            findings.append(f"{rel} 的 dcc64 搜索路径缺少 vendored 目录 {VENDOR_PATH}")

    ga = ROOT / ".gitattributes"
    if not ga.is_file():
        findings.append("缺少 .gitattributes（export-ignore / eol 规范化都靠它）")
    else:
        text = read(ga)
        for entry in REQUIRED_EXPORT_IGNORE:
            if entry not in text:
                findings.append(f".gitattributes 缺少 {entry} 的 export-ignore")

    try:
        exported = exported_files()
    except (subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        findings.append(f"git archive HEAD 失败: {exc}")
        exported = set()

    # A {$R x.res} directive whose file is not version-controlled compiles fine
    # on a reused working directory and fails with E1026 on any clean checkout.
    # AsWish.res was ignored by *.res for exactly that reason.
    for dpr in [ROOT / "AsWish.dpr"] + sorted((ROOT / "cli").glob("*.dpr")) + \
               sorted((ROOT / "tests").glob("*.dpr")):
        if not dpr.is_file():
            continue
        rel = dpr.relative_to(ROOT).as_posix()
        for m in re.finditer(r"\{\$R\s+([^}]+)\}", read(dpr)):
            res = m.group(1).strip()
            # Delphi convention: the '*' in {$R *.res} is a placeholder for the
            # project file's base name, so AsWish.dpr + {$R *.res} -> AsWish.res.
            if "*" in res:
                res = res.replace("*", dpr.stem)
            if not res.startswith(("src/", "cli/", "tests/")):
                res = (dpr.parent / res).relative_to(ROOT).as_posix()
            if res not in exported:
                findings.append(
                    f"{rel} 引用了未入库的资源 {res}（干净克隆将 E1026 File not found）"
                )

    if exported:
        for pattern, label in INTERNAL_PATTERNS:
            hits = sorted(n for n in exported if re.search(pattern, n))
            if hits:
                findings.append(
                    f"导出清单泄漏{label}：{len(hits)} 个（例: {hits[0]}）"
                )
        for need in RELEASE_ESSENTIALS:
            if need not in exported:
                findings.append(f"导出清单缺少开源必备件 {need}")

    if findings:
        print(f"[{GATE}] FAIL")
        for f in findings:
            print(f"  - {f}")
        sys.exit(1)
    print(f"[{GATE}] PASS 构建不依赖私有仓、导出清单无内部材料（{len(exported)} 个文件）")
    sys.exit(0)


if __name__ == "__main__":
    main()
