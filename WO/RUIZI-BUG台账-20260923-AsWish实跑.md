# 睿智工作流 / 会议系统 BUG 台账（AsWish 实跑记录）

- 记录人：甲（开发AI）via 睿智工作流
- 时间窗：2026-09-22 ~ 2026-09-23 两个会话
- 原则：只记**本会话亲手复现**的 BUG，每条含错误码与复现方式；未复现的传闻不录。

## A. 睿智 CLI / PG 工作身份

### BUG-R1 `ruizi` 直子命令与 CLI 契约不符
- 现象：按工作流文档跑 `ruizi ... readiness` → argparse 报 `--usage-intent, --request 必填`。
- 根因：CLI 无任何直子命令（只有 `--request <json>` 形态），路由结果里的 `direct_workflow_commands` 是虚假承诺。
- 建议：CLI 增加薄封装子命令，或 route 输出删除 direct_workflow_commands 误导项。

### BUG-R2 work_id 前缀规则未文档化
- 现象：手填 identity.json `work_id: "task-16"` → `WORK_ID_PREFIX_INVALID`（须 `rw_` 前缀），且提示未说明该 id 应由 `work-start` 自动生成。
- 建议：错误消息补 `recovery.use: trace_cli work-start`；skill 文档标注 id 不得手写。

### BUG-R3 query_kind 枚举未文档化
- 现象：`code_fix` → `QUERY_KIND_INVALID`，合法集 `{skill,status,internal_data,internal_document}` 无处可查（trace.py:56）。
- 建议：错误 details 里直接列出合法枚举。

### BUG-R4 `work-start --payload` 结构错误报误导性消息
- 现象：payload 嵌 `{"payload":{...}}` → `WORKSPACE_REQUIRED: workspace 必须是非空字符串`，真实原因是读取器把整个文件当 payload 平铺取键（trace_cli.py:109）。
- 建议：检测到 `payload` 嵌套键时报 `PAYLOAD_NESTED_NOT_ALLOWED` 并说明期望结构。

### BUG-R5 source_action 必须预先存在，新项目首单无处认领
- 现象：`require_source_action_exists: true`（model-roles.yaml:171），AsWish 无本线 action 可挂，只能借挂 DeepAxis 的 `BCW-A20260921-001`，造成台账语义错位（PG 留痕显示不相关归属）。
- 建议：提供受控 `action-register` 入口或在 work-start 支持 `--create-action`（写 action_registry），杜绝"借挂"。

### BUG-R6 escalation-check 对"有客观证据的纠错"误判灰区
- 现象：问"git 中误报是否追加更正记录"→ `no_objective_verdict` 判应上报；实际复现输出已构成客观判据（不更正=台账含假 P0）。
- 根因：纯函数只看问题文本，无"证据已具备"输入通道。
- 建议：增加 `--objective-evidence <path>` 入参，附可复现证据时降为自决。

## B. 会议系统（roundtable / six-hats / invoke）

### BUG-M1 roundtable-init `--task` 输入形态无提示
- 现象三连：传议题文本 → `TruthIntegrityError: task truth source does not exist: <整段文本被当路径>`；传工单 md → `JSONDecodeError`；只有传 dispatch 产出的 task.json 路径才成功。
- 建议：错误消息列出三种失败形态的正确输入示例；提供 `--task-id <AWT-...>` 自动定位。

### BUG-M2 默认 session-dir 与写边界法源自相矛盾（必失败）
- 现象：不传 `--session-dir` 时默认 `<task.json同级>/roundtable-session`（项目区），six-hats 后端按 BCW-D20260721-002 强制 `D:/BCW/runs/bcw/**` → **默认配置首跑必挂**（`assert_writable_dir verdict=unknown_namespace`）。
- 复现：roundtable-init 不带 session-dir → roundtable-step 即崩。
- 建议：默认值直接改 `D:/BCW/runs/bcw/roundtable/<task_id>`，两边共享同一常量。

### BUG-M3 专家池席位不足仍静默开会（同根 BCW-TD20260811-002）
- 现象：白帽邀请 2 位，E16 主/备模型均报 `无法反查家族`（qoder-GLM-5.2 / qoder-Kimi-K3），实际仅 1 位产出，会议照跑不误、无 quorum 警告。
- 影响：会议"看起来在开"，实为空转，消耗时间与 token。
- 建议：开场前跑池探测，可用席位 < 配置下限直接 `MEETING_NO_QUORUM` fail-closed，不进入逐帽流程。

### BUG-M4 专家跑题与幻觉规范无事实校验
- 现象：Delphi 代码议题下，E16 输出域名 SEO 收录分析（asto.cc/heyue.fyi…）；E14 声称仓库存在"公共组件签名仅允许非侵入式新增参数"等规范，docs/ 检索无原文。
- 建议：白帽输出落盘前跑 ground-check（引用"规范/条款"必须给文件行号，否则自动标 `unverified`），主持摘要剔除与议题零词面交集的发言。

### BUG-M5 invoke→wisegateway 全档 422（请求体缺 channel）
- 现象：`invoke --provider wisegateway` 三档模型（fccy-gpt-5.6-sol / qoder-GLM-5.2 / stepfun-step-router-v1）全部 `HTTP 422 {"missing":"body.channel"}`；专业助手派发链经网关**完全不可用**。
- 根因：workbench 构造的 chat 请求体缺 WiseGateway 新契约必填的 `channel` 字段（网关侧已改契约，客户端未跟）。参照同类：BCW-TD20260813-005。
- 建议：invoke 请求体补 `channel`（按 workbench 身份固定值），并加一条网关契约回归测试。

### BUG-M6 invoke→claude-code 传未知参数 `--safe-mode`
- 现象：`invoke --provider claude-code` → `error: unknown option '--safe-mode'`，本机 claude CLI 不识别 workbench 拼的参数。
- 根因：参数拼装按旧版/他版 CLI；两条 provider 通道同时坏 = invoke 从未做过端到端冒烟。
- 建议：CLI 参数按 `claude --version` 探测生成；CI 加 invoke 双通道 e2e 冒烟。

### BUG-M7 会议异常中断后状态滞留，无错误码回写
- 现象：session-dir 被边界拒后，roundtable task 停留 `awaiting_human`、`backend_current:"单帽停止于白帽帽"`，改对目录后旧 session 进度不迁移，只能整体重开；日志只有一行提示无 blocker 码。
- 建议：异常路径写 `human_in_loop.state=blocked + blockers[]`（含错误码），resume 支持 session-dir 变更迁移。

### BUG-M8 spw runner 引号包裹 argv 使含 `&&` 的 cmd 门必挂（本轮实修，缺陷仍在 spw.py）
- 现象：`["cmd","/c","cd X && a.bat && ..."]` 被引号化传参后，cmd 对含 `&` 的整串启用引号保留，把命令链当程序名 → `不是内部或外部命令` exit=1。AsWish 因此全红两轮。
- 已修（AsWish 侧）：改单一路径参数直调（.bat 自定位）+ 拆独立 compile-tests 门 + exe 直调不经 cmd。
- 通用修法（spw.py 侧，转优化工单）：gate 执行支持 `cwd` 字段，或统一 `cmd /s /c` 语义并文档化。

## 影响汇总

| 通道 | 状态 |
|---|---|
| 正式六帽会议 | 可用但席位残缺（M3/M4），白帽实证价值≈0，结论需人核 |
| invoke→wisegateway 专业助手 | **不可用**（M5） |
| invoke→claude-code 专业助手 | **不可用**（M6） |
| ruizi 身份链 | 可用但文档缺位（R1-R4），首单认领无路（R5） |
| AsWish SPW 门禁 | 已修，8/8 PASS（B8 已解） |

> 处置：本台账交优化工单 `WO/WO-20260923-0039` 排期。
