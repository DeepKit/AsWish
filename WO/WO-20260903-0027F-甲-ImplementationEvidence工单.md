# WO-20260903-0027F · 甲（开发AI）· Implementation Evidence v0（实现证据采集）

- 下发时间：2026-09-03 (GMT+8)
- 下发人：主控AI
- 承接方：**甲（开发AI，AsWish 仓库）**
- 工作仓库：`D:\_Progs\02Business\AsWish`
- 优先级：P0
- 依赖：`0027E` / `0028` 已入 `main`（Accepted Baseline 存在，作为证据关联回填的参照起点）
- 依据：`docs/07.工程-工程路线与Dogfood验收.md` §6.8b.2（Q2 结论，已裁定）
- 门禁：非睿智轻量门禁；双闸门（Engineering Green + Dogfood Green）；单 commit ≤200 行；build/test 原始输出存档；主控 APPROVED/RETURNED，未过不得 CLOSE

---

## 一、目标

对**真实工作区**采集「实现证据」：被节点 `source_refs` 指向的文件，计算文件哈希 + 结构抽样，落成 `implementation-evidence.yaml`，并与 Accepted Baseline 节点建立关联（`ReferencedBy`），作为 0027G Difference 比对的 Evidence 侧输入。

> 一句话：**证明"实现里到底有什么"不是靠 AI 嘴说，而是可采集、可哈希、可回溯的落盘证据。**

## 二、现状（已核实，勿重造）

- `TSpecEvidence` 模型已含全字段（`src/models/AsWish.Models.pas:218`，含 `Path / Lines / Excerpt / ContentHash / SourceFileHash / IsStale / ReferencedBy`）；
- `TAsWishStoreService.WriteEvidenceFile` 已存在（`src/services/AsWish.Services.SpecStore.pas:382`），YAML 写出含 `source_file_hash`（`src/core/AsWish.Yaml.Writer.pas:313`）；
- `TSpecHash.FileSha256Hex` 已存在（`src/core/AsWish.Hash.pas:73`）；
- `source-evidence.yaml` 已有完整样例（`protocol/examples/*/`）——Implementation Evidence 与之**同构**，只改 `source_layer` 语义。

## 三、采集机制（Q2 结论，三件套）

1. **文件哈希**：对节点 `source_refs` 指向的真实文件，用 `FileSha256Hex` 计算 → 填 `SourceFileHash`；
2. **结构抽样**：定位到文件中的具体符号/方法，取行号 + excerpt → 填 `Lines` / `Excerpt`；
3. **关联回填**：采集到的 Evidence 与 Baseline 节点经 `ReferencedBy` 关联，供 0027G 做结构差异比对。

## 四、落盘与 CLI

- 落盘：`.AsWish/evidence/implementation-evidence.yaml`（与 source-evidence.yaml 同级，不建第二套目录）；
- CLI 新增子命令（仿现有 `baseline list/verify` 分发模式，`cli/AsWish.CLI.dpr`）：

```text
aswish evidence collect <project-dir> [baseline-id]
```

不指定 `baseline-id` 时取最新 Accepted Baseline 作为关联参照。

## 五、红线

- **不做 AST 语法级解析**（成本高、收益低，Q2 明确排除）；
- **LLM 自我总结不得作为证据**（`docs/05.协议-AsWish协议基线.md` §5.1：Agent Claim ≠ Implementation Evidence）；
- 不新建平行 Evidence 实体/状态机，全部复用 `TSpecEvidence` 及现有 Evidence 基础设施。

## 六、最小测试清单（DUnitX）

1. 对真实文件采集 → `SourceFileHash` = 手工 `FileSha256Hex` 复算值；
2. 文件内容变化 → 重新采集后 `SourceFileHash` 变化、旧记录标 `IsStale`；
3. 结构抽样 → `Lines` / `Excerpt` 非空且行号在文件范围内；
4. `ReferencedBy` 正确回填到 Baseline 节点 id；
5. `implementation-evidence.yaml` 写出后可被现有 Evidence 读取链路回读；
6. `source_refs` 指向不存在文件 → fail-closed（报错，不产出半截证据）；
7. 指定不存在的 `baseline-id` → 明确报错退出。

> 全 PASS 且 `172/172` 基线不回退（新增用例计入后总数递增）。原始 build/test 输出存档 `WO/evidence/`。

## 七、验收

### Engineering Acceptance
- 测试全绿；build 0 Error/0 Warning 原始输出存档。

### Dogfood Acceptance
- 用 **AsWish 自身真实工作区**（`src/` 下被 `source_refs` 引用的真实文件）跑一次 `evidence collect`，产出真实 `implementation-evidence.yaml`，含至少一个真实 Baseline 节点关联。

### OJP Acceptance
- 本票不涉 Human 判断对象，OJP 项不适用；但证据链须可被 0027G 独立消费（格式即契约）。

## 八、非目标

不做：Difference（0027G）、Human Confirmation（0027H）、AST 解析、git 集成、GUI、Conversation Surface。

## 九、完成后进入

`0027G`（Structural Difference v0，本票 Evidence 为其输入）。

## 完成定义

> 对一个有 Accepted Baseline 的真实工作区，一条命令能采集出文件哈希 + 结构抽样 + Baseline 节点关联俱全的 `implementation-evidence.yaml`；文件变了证据会如实变旧（IsStale）；没有任何一步依赖 AI 的自我宣称。
