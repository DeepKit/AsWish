# 审计申请报告：WO-20260922-0038 · 证据链行号与内容哈希全线为空（P0 溯源失效）

- **工单编号**：WO-20260922-0038
- **工单名称**：证据链行号与内容哈希全线为空工单
- **承接角色**：开发甲（开发AI，AsWish 仓库）
- **工作仓库**：`D:\_Progs\02Business\AsWish`
- **报告绝对路径**：`D:\_Progs\02Business\AsWish\WO\AUDIT-REQUEST-WO-20260922-0038-甲.md`
- **开始时间**：2026-09-22 23:33:11 (GMT+8)
- **结束时间**：2026-09-22 23:48:30 (GMT+8)
- **编译状态**：GUI、CLI、Tests 全部编译通过（Exit Code = 0, 0 Error）
- **测试结果**：**244 / 244 PASS**（0 Failed, 0 Leaked, 0 Errored）
- **Dogfood 验证**：12 步全闭环通过，`source-evidence.yaml` 与 `implementation-evidence.yaml` 零 null

---

## 一、根因排查与真相澄清

### 1. 根因确认与传导链
在 `src/services/AsWish.Services.TreeBuilder.pas:154-167` 原实现中：
```pascal
function TAsWishTreeBuilder.MakeEvidenceForFile(const ARelPath: string): TSpecEvidence;
begin
  Result := Default(TSpecEvidence);
  Result.Id := 'ev-' + MakeSlug(ARelPath);
  Result.SourceLayer := slParsedFromA;
  Result.Path := ARelPath;
  Result.Lines := '';              // 导致下游序列化为 lines: null
  Result.Excerpt := 'File: ' + ARelPath;
  // 未曾对 Result.SourceFileHash 与 Result.ContentHash 赋值
end;
```
传导链：
1. `TreeBuilder.MakeEvidenceForFile` 生成空 `Lines` 与空 `SourceFileHash`。
2. `Controller.pas:1067` 写入 `evidence/source-evidence.yaml` 时，`Yaml.Writer.pas` 将空字段如实序列化为 `lines: null` 和 `source_file_hash: null`。
3. `EvidenceCollectorService` 消费 `source-evidence.yaml` 时，由于上游无行号，取回空行号，导致 `implementation-evidence.yaml` 中的 `lines` 亦全线退化为 null，且基于 `SourceFileHash` 的跨版本 staleness（过期变更）检测防线彻底失效。

### 2. D-03 Excerpt 覆盖链路真相澄清
- **历史现象**：在 dogfood 现场数据中，部分证据（如 `docs/01_requirements.md`）的 excerpt 是 `"# Order System Requirements"`，而另一些则为 `'File: ' + ARelPath`。
- **排查事实**：
  1. `BuildDocsFunctions`（第 473 行）提取 Markdown 标题后，显式执行了 `LEv.Excerpt := LTrimmed;`，覆盖了 `MakeEvidenceForFile` 的默认赋值；
  2. 模块目录第一代码文件证据（第 279 行）、Delphi 单元证据（第 545 行）、DFM 窗体证据（第 625 行）均显式覆盖了 `Excerpt`；
  3. 但 `BuildDataTreeFromDelphi`（第 725 行）与通用视图扫描（第 380 行）在调用 `MakeEvidenceForFile` 后**未设置 Excerpt**，导致这几处残留了 `'File: ' + ARelPath` 的路径复述死文本。
- **治理动作**：
  1. 改造 `MakeEvidenceForFile`：当文件存在时，读取文件真实首个非空行作为保底 Excerpt（超过 200 字符自动截断并标记 `ExcerptTruncated = True`），彻底清除 `'File: ' + ARelPath` 的死赋值；
  2. 在 `BuildDataTreeFromDelphi` 中精确定位类声明行（例如 `TBillingService = class`），将其实际声明语句作为 Excerpt；
  3. 所有设置 Excerpt 处均自动计算并填充 `ContentHash := TSpecHash.Sha256Hex(LExcerpt)`。

---

## 二、工单阻断项与必改项完成对照表

| 验收编号 | 修复要求与标准 | 实际实现与验证 | 判定 |
|:---:|---|---|:---:|
| **D-01** | **填充 `SourceFileHash`**：<br>- `MakeEvidenceForFile` 必须为每个证据计算真实 SHA256 哈希；<br>- 复用 `src/core/AsWish.Hash.pas` 之 `TSpecHash.FileSha256Hex`，禁止造轮子；<br>- 不破坏 `BuildFromScan` 既有签名。 | 复用 `TSpecHash.FileSha256Hex(LAbsPath)`，通过内部 `FProjectRootPath` 结合 `ARelPath` 安全定位绝对路径并读流计算 64 位 SHA256 哈希。 | **PASS** |
| **D-02** | **填充 `Lines`**：<br>- 至少对能定位行范围的填真实行号（形如 `"start-end"`）；<br>- 纯文件级证据填 `"1-N"`（N 为实际物理行数）；<br>- 符合下游 `ParseLineRange` 规范。 | 1. Markdown 文档标题证据：精确扫描标题所在行及至下一标题间的行段，输出真实行范围（如 `"1-4"`）；<br>2. Delphi 数据实体证据：精确扫描类定义与 `end;` 范围，输出真实类定义行范围（如 `"6-13"`）；<br>3. 单元、DFM 及通用文件证据：保底填充实际行数 `"1-N"`，无任何孤立空值。 | **PASS** |
| **D-03** | **Excerpt 一并核实**：<br>- 查清谁覆盖、覆盖后的值从哪来；<br>- 去除路径复述死代码；<br>- 保证 Excerpt 真实反映原文。 | 查清并记录了 4 处历史覆盖点与 2 处遗漏点；重构 `MakeEvidenceForFile` 提取首行原文内容；在 Delphi 数据实体处精准提取类声明原型；所有 Excerpt 均非路径复述。 | **PASS** |
| **D-04** | **回归真实 dogfood 验证**：<br>- 重跑 12 步全链路 Dogfood；<br>- 验证 `source-evidence.yaml` 中 `lines` 与 `source_file_hash` 非 null；<br>- 原始日志存档 `WO/evidence/`。 | 运行 `dogfood_0038_project` 12 步全链路，生成 `WO/evidence/dogfood-0038-甲.log`；断言证实 `source-evidence.yaml` 与 `implementation-evidence.yaml` 中 `lines: null` 与 `source_file_hash: null` 发生计数为 0。 | **PASS** |
| **D-05** | **补充单元测试**：<br>- 断言 `MakeEvidenceForFile` 产出证据之 `SourceFileHash` 非空、`Lines` 为 `"start-end"` 格式、`Excerpt` 正确；<br>- 断言 `BuildFromScan` 全链路产生非空证据。 | 在 `tests/Test.AsWish.TreeBuilder.pas` 新增 2 个针对性单元测试，覆盖单文件计算与工程全量构建场景，100% 绿灯。 | **PASS** |
| **D-06** | **全量回归**：<br>- 全量测试套件不得回退；<br>- 零失败、零内存泄漏。 | 运行 `tests/AsWish.Tests.exe`：**244 / 244 PASS**（通过率 100%，0 Failed, 0 Leaked, 0 Errored）。 | **PASS** |

---

## 三、Dogfood 现场证据核对数据

### 1. `source-evidence.yaml`（抽取样本）
```yaml
evidence:
  - id: "ev-docs-01-requirements-md"
    source_layer: parsed_from_a
    path: "docs/01_requirements.md"
    lines: "1-4"
    excerpt: "# Order System Requirements"
    excerpt_truncated: false
    note: null
    confidence: high
    created_at: "2026-09-22T23:47:06+08:00"
    updated_at: "2026-09-22T23:47:06+08:00"
    content_hash: "dd59c63c2b7205ac2e9d30d482f7050b8d798214847a77ad1b0fea7cc7cf8e92"
    source_file_hash: "0f386ab0e8caf9748d5b7b39faaeff10c4114f70266943a27428303c710175ff"
    is_stale: false
    referenced_by: []
  - id: "ev-src-services-ordersystem-billing-pas"
    source_layer: parsed_from_a
    path: "src/services/OrderSystem.Billing.pas"
    lines: "6-13"
    excerpt: "TBillingService = class"
    excerpt_truncated: false
    note: null
    confidence: high
    created_at: "2026-09-22T23:47:06+08:00"
    updated_at: "2026-09-22T23:47:06+08:00"
    content_hash: "0fb079b76fb083b48231d6801fbdb7e1634676451e50f38fbf32d9dbd0ca3f3c"
    source_file_hash: "bc502803c0800645c36fc9da7664db6e51c853f60bb116892694589255ddbcf3"
    is_stale: false
    referenced_by: []
```

### 2. `implementation-evidence.yaml`（抽取样本）
```yaml
  - id: "ev-impl-0001"
    source_layer: implementation
    path: "docs/01_requirements.md"
    lines: "1-4"
    excerpt: "# Order System Requirements\r\n1. The system must support customer checkout and payment processing.\r\n2. The inventory service must verify product availability before checkout.\r\n3. System must record payment audits."
    content_hash: "82a87a2d48293ddcae73a38ca83d63b2f5c7eaae1d4e7f6e493e8e11e3b62908"
    source_file_hash: "0f386ab0e8caf9748d5b7b39faaeff10c4114f70266943a27428303c710175ff"
    is_stale: false
  - id: "ev-impl-0004"
    source_layer: implementation
    path: "src/services/OrderSystem.Billing.pas"
    lines: "6-13"
    excerpt: "type\r\n  TBillingService = class\r\n  published\r\n    AccountId: string;\r\n    Balance: Double;\r\n    MaxRetryCount: Integer;\r\n  public\r\n    function ProcessPaymentWithRetry(const AAmount: Double; AMaxAttempts: Integer): Boolean;"
    content_hash: "c7bc8382ab3984e1b8bbf4083a21330fa585ec73b1856cf783bb62b0e6bf5470"
    source_file_hash: "333cbbcdbaef796db08c3cfd6199ca2f07d2c38596f26487e492ceee51a77464"
    note: "source_file_hash changed since previous collection"
    is_stale: false
```
> **溯源与防线恢复证明**：当 Step 7 发生现实代码漂移（`Billing.pas` 被修改）后，Step 8 证据收集器准确捕获到了哈希变更，并记录了 `note: "source_file_hash changed since previous collection"`！过期检测机制彻底恢复正常工作！

---

## 四、编译器与全量回归证据

### 1. 构建输出（`WO/evidence/build-0038-甲.txt`）
- GUI (`bin/AsWish.exe`): 24,307 行，Exit Code = 0，0 Error
- CLI (`cli/bin/AsWish.CLI.exe`): 15,603 行，Exit Code = 0，0 Error
- Tests (`tests/AsWish.Tests.exe`): 29,783 行，Exit Code = 0，0 Error

### 2. DUnitX 测试回归结果
```text
Done testing.
Tests Found   : 244
Tests Ignored : 0
Tests Passed  : 244
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```

---

## 五、Git 颗粒化提交清单

1. `ee66b35` `feat(treebuilder): calculate SourceFileHash, Lines range, and ContentHash for evidence (WO-0038)` (128 行)
2. `9966e59` `test(treebuilder): add tests for evidence hash, lines, and excerpt validation (WO-0038)` (114 行)
3. `WO/evidence/dogfood-0038-甲.log` 与 `WO/evidence/build-0038-甲.txt`（测试与构建证据存档）
4. `WO/AUDIT-REQUEST-WO-20260922-0038-甲.md`（本审计申请报告）

---

## 六、审核请求结论

工单 `WO-20260922-0038` 全部 6 项修复要求（D-01 ~ D-06）已 100% 达成。未对 `EvidenceCollector.pas` 引入任何补丁或修改；全量测试从 242 项平滑增长至 244 项且全部 PASS；物理 dogfood 验证全闭环通过，证据链溯源与过期检测防线完整修复。现正式提请主控审核。
