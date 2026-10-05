# SPW Evidence Generator (`tools/spw-evidence`)

本目录包含 AsWish 运行时证据包生成工具，负责执行 `spw-manifest.json` 中登记的确定性门禁并生成符合规范的 SPW 证据包。

## 核心脚本

- `generate_evidence.py`:
  - 自动读取 `spw-manifest.json`，执行所有配置的门禁；
  - 记录各门禁命令的 `command`、`exit_code`、耗时 `duration_ms`；
  - 完整记录 `stdout`、`stdout_bytes` 以及 `stdout_sha256`，杜绝任何截断失真；
  - 诚实记录 H5 异构观察席位状态，当缺乏外部观察席位时如实申报 `degraded` 降级，避免违规发证；
  - 诚实保留 H4 反绕过历史欠账告警（81 项 baseline 豁免尚未经审核席位批准，以 WARN 形式如实落盘）；
  - 将证据包结构化输出至仓库根目录 `spw-evidence-<commit_sha>.json`，并通过 `spw.py verify` 进行规范性验证。

## 运行方式

```bash
python -X utf8 tools/spw-evidence/generate_evidence.py
```
