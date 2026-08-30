# AUDIT-VERDICT · WO-20260829-001

- 审核人：主控AI
- 审核时间：2026-08-30 00:36 (GMT+8)
- 审核对象：`WO-20260829-001-开发AI-DeepSpec用户视角收口工单.md`（T1–T3）
- 审核方式：独立复核代码 + 逐条核实 evidence 原始证据，不采信自报 PASS。

---

## 一、结论

| 任务 | 判定 |
|---|---|
| T1 data-tree 摄入闭环 | **通过** |
| T2 四投影口径统一 | **通过** |
| T3 用户上手收口 | **通过** |
| 整体 | **功能验收通过；暂不 CLOSE（存在一笔门禁脚本债务，见 §三）** |

## 二、复核证据

1. **T1 核心断裂已修复**：`CandidateIngest.pas` 已删除 `ttData` 无条件 drop 分支，改为 `Result.DataNodes.Add(LNode)`（`/247-252`），且已有 data 节点 id 纳入 known-id 集（`/203-204`）支持 parent 引用。
2. **通用 data 推导实现合格**：`TreeBuilder.pas` 新增 `BuildDataTreeFromGeneric`（`/825-1607`），含 `IsToolingFile`（排除 package.json 等）、`IsDataLikePath`、`Singularize` 归一化等防误报措施；无法推导时降级为 `fsFoggy` + `clLow` 占位（`/1575-1596`），符合工单要求，无过度兜底。
3. **测试真实**：`spw-H2-unit-tests-20260830.txt` 原始输出 `124 found / 124 passed / 0 failed / 0 leaked`（较基线 113 新增 11 例，覆盖 data 摄入/推导/校验/渲染）。
4. **CLI 实测真实**：`scan` 输出 `data 6`；`ingest` 输出 `accepted=1 rejected=0`（data 候选已可摄入）；`validate` 四树 + issues 全 `0 error / 0 warning`。
5. **编译通过**：`spw-H2-compile-build-20260830.txt` 显示 Delphi 37.0 exit 0（仅 1 条无关 Hint）。
6. **T2/T3 已核实**：CLI 头部 usage 已列 9 条命令；多份历史"三棵树"文档已加失效/四投影映射标注；`docs\DeepSpec-用户上手说明-v1.md` 已存在（3.3KB）。

## 三、未清债务（阻塞 CLOSE）

**SPW H3 runtime-autofix FAIL**（`spw-H3-autofix-20260830.txt`）：

- 现象：静态脚本要求 `AutoFix.Install` / `AutoFix.RegisterScenario`，报告 3 个 FAIL。
- 根因（主控已核实）：`DeepSpec.dpr:56/72` 实际调用 `TDeepSpecAutoFix.Install` / `TDeepSpecAutoFix.RegisterScenario`（类名带 `TDeepSpec` 前缀，见 `DeepSpec.AutoFix.pas:27-38`）。**脚本符号匹配规则未带前缀，误报**。
- 定性：门禁脚本规则缺陷，**非本单代码缺陷**。但按门禁纪律"存在未清债务禁止 CLOSE"，本单暂不关闭。

**建议处置**（待老板裁定，主控不擅自跨仓库改脚本）：
1. 修正 autofix 门禁脚本，使符号匹配兼容 `TDeepSpecAutoFix.*` / `TAutoFix.*` 前缀；或
2. 若该脚本属 `09_工程脚本/bgor/`（WO-20260827-0209 交付物），转其维护方修正。

## 四、开发AI提出的两个复核点

1. **data 通用推导误报取舍**：已内置防误报（工具文件排除 + data 路径识别 + 单数化归一），主控接受，后续以真实项目样本持续校准。
2. **data 字段是否纳入 content hash**：属协议层决策，留待下一协议版本处理，本单不改，已记录。

## 五、待办

- 老板裁定 §三 autofix 债务的修复归属后，主控跟进并补发对应工单，债务清零即宣告本单 CLOSE。
