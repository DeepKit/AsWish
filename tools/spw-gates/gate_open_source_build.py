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
3. Reverse direction: exported code referencing an internal file by its repo
   path. WO-20260925-0056 excluded WO/ and only then found that six anchors
   under WO/evidence/ were what the seeded Commons lessons pointed at - the
   clean clone built fine and failed 6 tests. A reference to an ignored path
   is invisible to the build, so it is checked statically here.
"""
import io
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

GATE = "G.open-source-build"
ROOT = Path(__file__).resolve().parents[2]

BUILD_SCRIPTS = ["_build.bat", "cli/_build_cli.bat", "tests/_build_tests.bat"]
VENDOR_PATH = "vendor\\deepbase-ehai"

# Extensions the build, the compiler and the test runner actually consume. A
# reference found here is a broken dependency in the released source and fails
# the gate.
CONSUMES_EXT = {".pas", ".dpr", ".inc", ".bat", ".yaml", ".yml", ".json", ".cfg", ".py", ".txt"}

# Prose only. The public docs under docs/ cite their sources under docs/归档/ and
# WO/ as provenance; those links dangle in a release but the citations are why
# the docs can be trusted, so they are reported, not blocked on.
PROSE_EXT = {".md"}

# A path-shaped token ending in an extension. Backslash is in the class on
# purpose: Delphi string literals carry Windows separators.
PATH_TOKEN = re.compile(r"[A-Za-z0-9_.\-/\\一-鿿]+\.[A-Za-z0-9]{1,6}")

# Matched against the *exported* path list. A missing entry here means internal
# material shipped; that is a release blocker, not a warning.
INTERNAL_PATTERNS = [
    (r"(^|/)WO/", "work-order / governance directory"),
    (r"(^|/)\.workbuddy/", "daily working logs"),
    (r"(^|/)\.AsWish/", "protocol workspace state"),
    (r"(^|/)\.ai-workbench/", "workbench state"),
    (r"(^|/)\.claude/", "local agent state"),
    (r"(^|/)_repro/", "internal repro directory"),
    (r"(^|/)_audit_(out|err)\.txt$", "internal audit log"),
    (r"(^|/)(err_file|out_file)$", "internal temp runner output"),
    (r"(^|/)AUDIT-REQUEST-", "internal audit request"),
    (r"(^|/)AUDIT-VERDICT-", "internal audit verdict"),
    (r"(^|/)\.env", "environment / secrets"),
    (r"(^|/)(id_rsa|.*\.pem|.*\.p12|.*\.key)$", "key material"),
]

REQUIRED_EXPORT_IGNORE = [
    "WO/",
    ".workbuddy/",
    ".AsWish/",
    ".ai-workbench/",
    "_repro/",
    "_audit_out.txt",
    "_audit_err.txt",
    "err_file",
    "out_file",
]
RELEASE_ESSENTIALS = ["README.md", "LICENSE", "NOTICE"]


def read(p: Path) -> str:
    return p.read_bytes().decode("utf-8", errors="replace")


def exported_archive() -> tuple[set[str], bytes | None]:
    """Names and manifest inside `git archive HEAD`, read via zipfile.

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
        names = {n.rstrip("/") for n in zf.namelist() if not n.endswith("/")}
        manifest_bytes = zf.read("spw-manifest.json") if "spw-manifest.json" in names else None
        return names, manifest_bytes


def exported_files() -> set[str]:
    names, _ = exported_archive()
    return names


def tree_paths() -> set[str]:
    """Every path committed in HEAD. `-z` because quoting of the non-ASCII names
    under docs/ makes the default output unusable for a set difference."""
    out = subprocess.run(
        ["git", "ls-tree", "-r", "-z", "--name-only", "HEAD"],
        cwd=ROOT,
        capture_output=True,
        check=True,
    ).stdout
    return {n.decode("utf-8", "replace") for n in out.split(b"\0") if n}


def references_to_internal(exported: set[str]) -> tuple[list[str], int]:
    """Exported text that names a committed-but-excluded file by its repo path.

    tree - archive is exactly what export-ignore removed, so any hit is a
    reference the released source cannot satisfy. Comparing to a set instead of
    matching prefixes is what keeps doc comments that merely mention "WO/0056"
    from failing the gate: such a token is not a committed path.

    Returns (blocking findings, count of prose-only citations).
    """
    try:
        ignored = tree_paths() - exported
    except subprocess.CalledProcessError:
        return [], 0
    if not ignored:
        return [], 0

    findings = []
    prose_hits = 0
    for rel in sorted(exported):
        suffix = Path(rel).suffix.lower()
        if suffix not in CONSUMES_EXT and suffix not in PROSE_EXT:
            continue
        p = ROOT / rel
        if not p.is_file():
            continue
        hits = set()
        for m in PATH_TOKEN.finditer(read(p)):
            token = m.group(0).rstrip(".,;:)").replace("\\", "/")
            if token in ignored:
                hits.add(token)
        if suffix in PROSE_EXT:
            prose_hits += len(hits)
            continue
        for h in sorted(hits):
            findings.append(f"{rel} 引用了导出清单外的内部文件 {h}（干净克隆里它不存在）")
    return findings, prose_hits


def check_no_python_command_in_pascal() -> list[str]:
    """Ensure Pascal code in src/ and cli/ does not invoke python commands (WO-20260930-0062)."""
    findings = []
    cmd_pattern = re.compile(r"""['"]\s*python(\.exe)?\s+[^'"]*['"]""", re.IGNORECASE)
    for ext in ("*.pas", "*.dpr", "*.inc"):
        for base in ("src", "cli"):
            for p in sorted((ROOT / base).rglob(ext)):
                rel = p.relative_to(ROOT).as_posix()
                for idx, line in enumerate(read(p).splitlines(), start=1):
                    stripped = line.strip()
                    if stripped.startswith("//") or stripped.startswith("{*") or stripped.startswith("(*"):
                        continue
                    if cmd_pattern.search(line):
                        findings.append(f"{rel}:{idx} 存在运行时 Python 命令调用: {stripped}")
    return findings


def is_export_ignored(rel_path: str) -> bool:
    try:
        out = subprocess.check_output(
            ["git", "check-attr", "export-ignore", "--", rel_path],
            cwd=ROOT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        return ": export-ignore: set" in out
    except Exception:
        return False


def check_exported_python_files(exported: set[str]) -> list[str]:
    """Ensure all exported .py files belong to authorized and documented categories (WO-20260930-0062 / WO-20261004-0088)."""
    findings = []
    AUTHORIZED_PY_DIRS = {
        "protocol/": "protocol/README.md",
        "tools/spw-gates/": "tools/spw-gates/README.md",
        "tools/spw-evidence/": "tools/spw-evidence/README.md",
        "tools/vcl-observe/": "tools/vcl-observe/README.md",
    }
    candidates = set(exported)
    if (ROOT / "tools").is_dir():
        for p in (ROOT / "tools").rglob("*.py"):
            rel = p.relative_to(ROOT).as_posix()
            if not is_export_ignored(rel):
                candidates.add(rel)

    for rel in sorted(candidates):
        if rel.endswith(".py"):
            matched_doc = None
            for prefix, doc in AUTHORIZED_PY_DIRS.items():
                if rel.startswith(prefix):
                    matched_doc = doc
                    break
            if not matched_doc:
                findings.append(
                    f"未授权或未归属的导出 Python 文件: {rel}（仅允许 protocol/、tools/spw-gates/ 与 tools/spw-evidence/ 并在对应 README 中说明）"
                )
            elif matched_doc not in exported:
                doc_path = ROOT / matched_doc
                if doc_path.is_file() and not is_export_ignored(matched_doc):
                    continue
                findings.append(f"导出 Python 脚本 {rel} 缺少对应说明文档 {matched_doc}")
    return findings


def check_manifest_gates(exported: set[str], manifest_bytes: bytes | None) -> list[str]:
    """Verify manifest integrity and export self-sufficiency (WO-20261004-0082 / WO-0086 Stage 1)."""
    findings = []
    wt_manifest_path = ROOT / "spw-manifest.json"
    if not wt_manifest_path.is_file():
        findings.append("工作树缺少 spw-manifest.json")
        return findings

    try:
        wt_manifest = json.loads(read(wt_manifest_path))
    except Exception as exc:
        findings.append(f"解析工作树 spw-manifest.json 失败: {exc}")
        return findings

    wt_required = {g["gate_id"] for g in wt_manifest.get("gates", []) if g.get("required")}
    if len(wt_required) < 12:
        findings.append(
            f"必需门禁数量不足 12 道（当前 {len(wt_required)} 道，按 WO-0108 必须为 12 道全量门禁）: {sorted(wt_required)}"
        )

    try:
        head_raw = subprocess.check_output(
            ["git", "show", "HEAD:spw-manifest.json"],
            cwd=ROOT,
        )
        head_manifest = json.loads(head_raw.decode("utf-8", "replace"))
        head_required = {g["gate_id"] for g in head_manifest.get("gates", []) if g.get("required")}
    except Exception as exc:
        findings.append(f"读取 HEAD:spw-manifest.json 失败: {exc}")
        head_required = set()

    # Reverse assertion: working tree must not drop any required gates present in HEAD
    dropped = head_required - wt_required
    if dropped:
        findings.append(
            f"工作树 spw-manifest.json 较 HEAD 删除了必需门禁: {sorted(dropped)}（防提交时手改清单把门禁悄悄删掉）"
        )

    # When spw-manifest.json is clean in working tree, exact equality is required
    try:
        status_proc = subprocess.run(
            ["git", "status", "--porcelain", "--", "spw-manifest.json"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        manifest_dirty = bool(status_proc.stdout.strip())
    except Exception:
        manifest_dirty = False

    if not manifest_dirty and wt_required != head_required:
        findings.append(
            f"工作树与 HEAD 必需门禁集合不一致: 工作树={sorted(wt_required)}, HEAD={sorted(head_required)}"
        )

    # Check that all required gate scripts are present in exported archive
    target_manifest = wt_manifest
    if manifest_bytes:
        try:
            target_manifest = json.loads(manifest_bytes.decode("utf-8", "replace"))
        except Exception:
            target_manifest = wt_manifest

    root_posix = ROOT.as_posix()
    for g in target_manifest.get("gates", []):
        if not g.get("required"):
            continue
        gid = g.get("gate_id", "unknown")
        for arg in g.get("command", []):
            if arg.endswith(".py"):
                norm = arg.replace("\\", "/")
                if norm.startswith(root_posix + "/"):
                    rel = norm[len(root_posix) + 1:]
                elif norm.startswith("./"):
                    rel = norm[2:]
                elif Path(arg).is_absolute():
                    try:
                        rel = Path(arg).relative_to(ROOT).as_posix()
                    except ValueError:
                        rel = norm
                else:
                    rel = norm

                script_path = ROOT / rel
                if not script_path.is_file():
                    findings.append(
                        f"必需门禁 {gid} 的脚本 {rel} 在工作树中不存在（干净快照将无法执行该门禁）"
                    )
                elif rel not in exported:
                    findings.append(
                        f"必需门禁 {gid} 的脚本 {rel} 未包含在导出清单中（干净快照将无法执行该门禁）"
                    )

    return findings


def check_export_content_markers(exported: set[str]) -> list[str]:
    """Scan all exported files for internal governance markers (WO-20261004-0087 Stage 1 item 3)."""
    findings = []
    markers = ["主控", "开发AI", "WorkBuddy", "工单", "BCW", "BetterCiv"]
    statutory_triples = {
        ("LICENSE", 178, "BetterCiv"),
        ("NOTICE", 2, "BetterCiv"),
        ("NOTICE", 57, "BCW"),
        ("README.md", 375, "BetterCiv"),
        ("installer/AsWish.iss", 12, "BetterCiv"),
        ("protocol/NOTICE", 2, "BetterCiv"),
        ("protocol/NOTICE", 57, "BCW"),
        ("protocol/README.md", 122, "BetterCiv"),
    }
    binary_exts = {
        ".exe", ".dll", ".pak", ".png", ".ico", ".res", ".zip", ".dcu", ".data",
        ".identcache", ".local", ".tvsconfig", ".bpl"
    }

    try:
        out = subprocess.run(
            ["git", "archive", "--format=zip", "HEAD"],
            cwd=ROOT,
            capture_output=True,
            check=True,
        ).stdout
        internal_ignore_patterns = [
            r"(^|/)docs/07\.",
            r"(^|/)docs/13\.",
            r"(^|/)docs/15\.",
            r"(^|/)docs/AsWish-Commons-PG",
            r"(^|/)docs/归档/",
            r"(^|/)docs/_archive/",
            r"(^|/)docs/.*交接.*",
            r"(^|/)WO/",
            r"(^|/)\.workbuddy/",
            r"(^|/)\.AsWish/",
            r"(^|/)\.ai-workbench/",
            r"(^|/)_repro/",
        ]

        with zipfile.ZipFile(io.BytesIO(out)) as zf:
            for name in zf.namelist():
                if name.endswith("/") or name not in exported:
                    continue
                if Path(name).suffix.lower() in binary_exts:
                    continue
                if name.startswith("tools/spw-gates/"):
                    continue
                if any(re.search(pat, name) for pat in internal_ignore_patterns):
                    continue
                # If working tree has modified file, test working tree content
                p = ROOT / name
                if p.is_file():
                    try:
                        text = p.read_text(encoding="utf-8", errors="replace")
                    except Exception:
                        text = zf.read(name).decode("utf-8", errors="replace")
                else:
                    text = zf.read(name).decode("utf-8", errors="replace")

                for line_num, line in enumerate(text.splitlines(), 1):
                    for m in markers:
                        if m in line:
                            if (name, line_num, m) in statutory_triples:
                                continue
                            findings.append(f"导出文件内容含内部治理标记: {name}:{line_num} 命中 '{m}'")
    except Exception as e:
        findings.append(f"扫描导出文件内容标记异常: {e}")
    return findings


def check_tracked_internal_dirs() -> list[str]:
    """Assert git does not *track* any internal runtime directory (WO-20261005-0094).

    export-ignore only shapes `git archive`; a tracked internal directory is
    still fully visible to anyone who clones the repository, and its blobs stay
    reachable so no prune can reclaim them. Those are different leakage surfaces
    and both need their own assertion.
    """
    findings = []
    manifest_path = ROOT / "spw-manifest.json"
    if not manifest_path.is_file():
        return findings
    try:
        manifest = json.loads(read(manifest_path))
    except Exception as exc:
        return [f"解析工作树 spw-manifest.json 失败: {exc}"]

    forbidden = manifest.get("forbidden_tracked_paths") or []
    if not forbidden:
        findings.append("manifest 缺少 forbidden_tracked_paths（内部运行态目录清单）")
        return findings

    out = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        capture_output=True,
        check=True,
    ).stdout
    tracked = {n.decode("utf-8", "replace") for n in out.split(b"\0") if n}

    for entry in sorted(forbidden):
        norm = entry.replace("\\", "/")
        hits = sorted(n for n in tracked if n.startswith(norm))
        if hits:
            findings.append(
                f"git 跟踪了内部运行态目录 {norm}: {len(hits)} 个（例: {hits[0]}）"
                f"——export-ignore 只挡 git archive，挡不住 clone，必须 git rm --cached"
            )
    return findings


def main() -> None:
    findings = []
    findings.extend(check_tracked_internal_dirs())
    findings.extend(check_no_python_command_in_pascal())

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
        exported, manifest_bytes = exported_archive()
    except (subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        findings.append(f"git archive HEAD 失败: {exc}")
        exported = set()
        manifest_bytes = None

    findings.extend(check_manifest_gates(exported, manifest_bytes))

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
        ref_findings, prose_hits = references_to_internal(exported)
        findings.extend(ref_findings)
        findings.extend(check_exported_python_files(exported))
        findings.extend(check_export_content_markers(exported))
        if prose_hits and ("-v" in sys.argv or "--verbose" in sys.argv):
            print(f"[{GATE}] 注意: 公开文档有 {prose_hits} 处指向未导出出处"
                  f"（docs/归档/ 与 WO/ 的溯源引用，发布后成死链，不阻断）")

    if findings:
        print(f"[{GATE}] FAIL")
        for f in findings:
            print(f"  - {f}")
        sys.exit(1)
    print("[CLAIM_ASSERTED] counterfactual_export")
    print(f"[{GATE}] PASS 构建不依赖私有仓、导出清单无内部材料、无运行时Python依赖（{len(exported)} 个文件）")
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as e:
        print(f"[{GATE}][ABORTED] {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)
