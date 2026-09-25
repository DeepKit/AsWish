"""Gate: open-source build & export shape.

Guards the two things that made AsWish unpublishable before WO-20260925-0056:
  1. A clean clone had to resolve the private DeepBase repository via a relative
     search path, so `dcc64` died with F2613 on MainForm and on the EHAI binding
     tests. The type layer it needed is now vendored; no build script may point
     back at DeepBase.
  2. WO/ and .workbuddy/ are internal working artefacts (work orders, audit
     requests, another private project's paths, decisions awaiting the owner).
     They must be excluded from every source export while staying in the repo.

`git archive` honours `export-ignore` and is the path a source release is built
from, so that is what is checked here - not a hand-maintained copy list.
"""
import subprocess
import sys
from pathlib import Path

GATE = "G.open-source-build"
ROOT = Path(__file__).resolve().parents[2]

BUILD_SCRIPTS = ["_build.bat", "cli/_build_cli.bat", "tests/_build_tests.bat"]
VENDOR_PATH = "vendor\\deepbase-ehai"
REQUIRED_EXPORT_IGNORE = [
    "WO/",
    ".workbuddy/",
    ".AsWish/",
    ".ai-workbench/",
]


def read(p: Path) -> str:
    return p.read_bytes().decode("utf-8", errors="replace")


def archived_files() -> set[str]:
    out = subprocess.run(
        ["git", "archive", "HEAD"],
        cwd=ROOT,
        capture_output=True,
        check=True,
    ).stdout
    # tar listing, one header (512B) per entry; read names straight from headers
    # to avoid depending on tar's output format.
    names = set()
    for off in range(0, len(out), 512):
        block = out[off:off + 512]
        if block == b"\0" * 512:
            break
        name = block[:100].split(b"\0", 1)[0].decode("utf-8", errors="replace")
        if name:
            names.add(name)
    return names


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
        exported = archived_files()
    except subprocess.CalledProcessError as exc:
        findings.append(f"git archive HEAD 失败: {exc}")
        exported = set()

    if exported:
        for banned in ("WO/", ".workbuddy/"):
            leaked = sorted(n for n in exported if n.startswith(banned))
            if leaked:
                findings.append(
                    f"导出清单泄漏内部目录 {banned}（{len(leaked)} 个文件，"
                    f"例: {leaked[0]}）"
                )
        for needed in ("README.md", "LICENSE", "NOTICE"):
            if needed not in exported:
                findings.append(f"导出清单缺少开源必备件 {needed}")

    if findings:
        print(f"[{GATE}] FAIL")
        for f in findings:
            print(f"  - {f}")
        sys.exit(1)
    print(f"[{GATE}] PASS 构建不依赖私有仓、导出清单不含内部目录（{len(exported)} 个文件）")
    sys.exit(0)


if __name__ == "__main__":
    main()
