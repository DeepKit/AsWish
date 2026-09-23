# WO-20260923-0041 · 开发AI · Difference Commons 首批种子与设计（核心战场一落地）

- 下发时间：2026-09-23 (GMT+8)
- **独立性声明**：本票纯 AsWish 仓内工作（S-4 用规则匹配，不依赖模型网关），
  **可与 WO-0042 工具链修复完全并行**，无前置阻塞。
- 依据：`docs/AsWish-新产品经理交接包-v1.md` §四 核心战场一；`docs/AsWish-公众价值层与差异社区理念-v1.md`
- 优先级：P1（不阻塞工程链，产品价值主线）
- 规模边界：本单只做 **种子机制 + 首批内容 + 提取按钮设计**，不做社区服务端（另单）

## 一、要解决的问题

Day 1 用户装好 AsWish，第一次被 AI 坑的时候，系统里没有任何"历史经验"可言。
冷启动答案：**AsWish 自己就是第一个数据源**——本仓已有真实的人机分叉记录。

## 二、交付物

### S-1 种子 Schema（冻结契约）
`.AsWish/commons/lesson-<id>.yaml`，字段：
`trigger_pattern`（哪个语义雷区的机器可读判据，如"节点 Summary 被 AI 改写但人类原话是拒绝"）、
`wrong_expression`（AI 错法，脱敏后的结构差异快照引用）、`right_expression`（人类裁定形态 + DecisionId）、
`baseline_ref`/`difference_ref`（溯源锚，哈希校验）、`domain`（通用/领域标签）、
`contributed_by`（seed=aswish-dogfood 或人类贡献标记）、`story_mode`（沿用 Amy 内容治理词表）。

### S-2 首批种子：从既有 dogfood 提取 Top 10
来源（全部已存在、可复核）：
1. **Disable vs Delete 混淆**（交接包点名的语义雷区 #1）——构造一组对照 changeset 入库；
2. **意图改写陷阱**：`c8d8113→ee66b35` 事件本身（AI 读了半个函数就下"从未赋值"结论）——真实 dogfood 已留痕；
3. **样本时效陷阱**：本会话"旧构建产物当现状"虚警（含反例教学：如何用隔离复现拆穿）；
4. 7. 从 `WO/evidence/dogfood-0036/0038.log` 的 decisions/difference 记录再挖 5-7 条。
每条一个 lesson yaml + 人类一句话教训（这是与"错误日志库"的本质区别）。

### S-3 🚩 提取按钮（GUI 侧，衔接 WO-0036 的 HB Deck）
触发时机：**人类拒绝或改写 AI 提案并 Commitment Gate 通过的瞬间**（数据天然在手：
ChangeSet + Decision + Difference 三件套已持久化）。交互：Deck 状态行出现
`[🚩 存为避坑经验]`，一键把三件套按 S-1 schema 落成 `commons/` 草稿并打开预览；
**默认只存本地，不上传**（上传是社区单的事）。零弹窗打断。

### S-4 命中提示（Minimum Wow）
scan/ingest 时若节点意图匹配某 lesson 的 `trigger_pattern`（先做规则版，不上模型），
在 changeset review 页注入一行"历史经验：同类分叉曾错在 X（lesson-000N）"。
验收标准就是交接包那句话：**第一次安装就能感受到"历史经验帮我防坑"**。

## 三、验收

- 10 条种子 lesson yaml 全部可被 SpecStore 读写往返（哈希校验通过），进现有测试套件；
- 🚩 按钮 E2E：GUI 测试模拟 reject→commit 流，断言 lesson 草稿生成且含正确溯源锚；
- S-4 命中演示：func-payment-retry 场景注入提示成功；
- 全部改动 SPW 8/8 不回退，单 commit ≤200 行分主题提交。

## 四、明确不做

服务端、账号体系、上传协议、Top 50 的其余 40 条（等真实用户数据喂养，避免拍脑袋库存）。
