"""Gate: vendored-upstream drift (EHAI / HB type layer).

The two type units under vendor/deepbase-ehai are vendored copies of files whose
public semantics are frozen by the SSOT baseline registered in
src/services/AsWish.Binding.HB.pas (EHAI-DELPHI-SYMBOL-BASELINE-v1.0). Copying
them is only acceptable while we can still prove they have not silently drifted
from upstream.

Fingerprint convention (matches the baseline registration): SHA-256 over the
upstream file's content with the UTF-8 BOM stripped. The registered values in
AsWish.Binding.HB.pas were produced this way; hashing the raw bytes does NOT
reproduce them.

Outcomes:
  FAIL - upstream reachable and its fingerprint no longer matches the recorded
         value (upstream moved; re-vendor after review), or a vendored file was
         modified locally away from its recorded fingerprint.
  SKIP - upstream not reachable (any public clone). Reported, exit 0.
"""
import hashlib
import json
import os
import sys
from pathlib import Path

GATE = "G.vendored-upstream-drift"
ROOT = Path(__file__).resolve().parents[2]
VENDOR = ROOT / "vendor" / "deepbase-ehai"


def strip_bom(raw: bytes) -> bytes:
    return raw[3:] if raw[:3] == b"\xef\xbb\xbf" else raw


def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def upstream_root() -> Path | None:
    env = os.environ.get("DEEPBASE_HOME", "").strip()
    candidates = []
    if env:
        candidates.append(Path(env))
    candidates.append(ROOT.parent / "DeepBase")
    for c in candidates:
        if (c / "Core" / "DeepBase.EHAI.Types.pas").is_file():
            return c
    return None


def main() -> None:
    manifest_path = VENDOR / "upstream.json"
    if not manifest_path.is_file():
        print(f"[{GATE}] FAIL")
        print(f"  - 缺少收存清单 {manifest_path.relative_to(ROOT).as_posix()}")
        sys.exit(1)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    records = manifest.get("records", [])
    if not records:
        print(f"[{GATE}] FAIL")
        print("  - upstream.json 没有任何收存记录")
        sys.exit(1)

    findings = []
    for rec in records:
        name = rec["file"]
        vendored = VENDOR / name
        if not vendored.is_file():
            findings.append(f"收存文件缺失: vendor/deepbase-ehai/{name}")
            continue
        local = sha(vendored.read_bytes())
        if local != rec.get("vendored_sha256"):
            findings.append(
                f"{name}: 本仓副本被改动且未登记 "
                f"(当前 {local[:16]}… / 登记 {str(rec.get('vendored_sha256'))[:16]}…)"
            )

    upstream = upstream_root()
    if upstream is None:
        print(
            f"[{GATE}] SKIP 上游 DeepBase 不可达（公开克隆场景），"
            f"已改校验 {len(records)} 个本仓副本指纹"
        )
        if findings:
            print(f"[{GATE}] FAIL")
            for f in findings:
                print(f"  - {f}")
            sys.exit(1)
        print("[CLAIM_ASSERTED] upstream_vendor_drift")
        sys.exit(0)

    print(f"[{GATE}] 上游定位: {upstream}")
    for rec in records:
        name = rec["file"]
        up = upstream / "Core" / name
        if not up.is_file():
            findings.append(f"上游文件不存在: {up}")
            continue
        actual = sha(strip_bom(up.read_bytes()))
        recorded = rec.get("upstream_sha256_bom_stripped")
        if actual != recorded:
            findings.append(
                f"{name}: 上游已漂移 (当前 {actual[:16]}… / 登记 {recorded[:16]}…)；"
                f"须人工复核语义后重新收存并更新 upstream.json"
            )

    if findings:
        print(f"[{GATE}] FAIL")
        for f in findings:
            print(f"  - {f}")
        sys.exit(1)
    print("[CLAIM_ASSERTED] upstream_vendor_drift")
    print(f"[{GATE}] PASS 上游与登记值一致，本仓副本未被误改（{len(records)} 个文件）")
    sys.exit(0)


if __name__ == "__main__":
    main()
