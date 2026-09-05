# 复核裁定：WO-20260905-1130-0029-甲（主控终审）

- 审计时间：2026-09-05 12:30 (GMT+8)
- 审计人：主控AI
- 对象：`WO/evidence/AUDIT-REQUEST-WO-20260905-0029-甲.md`
- **裁定：RETURNED（退回——仅 P2 一处阻断：GUI 真实环境验证缺失 + 证据冒充；P1/P3 通过，禁止返工）**

## 一、独立复核确认属实（认可，禁止返工）

| # | 事项 | 复核方式 | 结果 |
|---|---|---|---|
| 1 | 全量测试 206/206 | 主控独立复跑 `AsWish.Tests.exe`，0 Failed/0 Errored/0 Leaked | ✅ |
| 2 | P1 批量 Dogfood | 3 项目现场直查：各 5 条决策（dec-0001~0005 单调）；B-0003 `parent_baseline_id: "B-0002"` 均物理落盘；`baseline verify B-0003` 主控复跑 3/3 PASS | ✅ |
| 3 | P1 跑批证据 | 日志 0 个非零 Exit code，含逐步 ASSERT PASS 与终态汇总 | ✅ |
| 4 | P3 版本单一源 | `src/core/AsWish.Version.pas` 存在；主控跑 `AsWish.CLI.exe --version` ➔ `AsWish v0.1.0` | ✅ |
| 5 | P3 发布包 | `dist/AsWish-v0.1.0-win64.zip` 在盘；SHA-256 主控复算 = `A660…6458` 与报告一致 | ✅ |
| 6 | P3 git tag | `v0.1.0` 存在，message 含 WO-0029 范围 | ✅ |
| 7 | P2 代码接线 | `Controller.ComputeDifference/RecordDifferenceDecision/EvolveBaseline/CollectEvidence/ListDecisions` 真实存在；`Render.pas:1967` → `RenderDiff`；`MainView.pas:296/309` 派发 `difference-judge`/`baseline-evolve`；`AsWish.Providers.pas:81-91` 桥接 Controller | ✅（代码层） |
| 8 | `Render.pas` 1976 行 < 2000 | 直查 | ✅ |

## 二、退回理由（唯一阻断，P2）

### D01 · GUI 真实环境验证缺失，CLI 冒充 GUI 证据（阻断 + 虚假声称）

**事实**（主控直查铁证）：

1. `WO/evidence/gui-decisions-20260905-0029-甲.txt` 标题写 "GUI Decision Surface Real Environment Verification"，但**全部 15 步命令均为 `AsWish.CLI.exe`**（init/scan/intent/changeset/accept/difference/judge/evolve/baseline）——零条 GUI 操作记录；
2. `dogfood_gui_site_final/` 系纯 CLI 产物现场：`.AsWish/html/` 仅含 scan 渲染页，**无 `difference.html`、无 `decisions.html`**（主控全仓递归搜索两文件：0 命中）——而报告 §三声称 ComputeDifference「刷新渲染 difference.html 与 decisions.html」并以该现场作证；
3. 报告 §三.3「与 CLI 产物逐字节同构」的核验对象本身就是 CLI 产物——同构命题未被任何 GUI 实操证据支持。

**影响**：P2 验收硬标准明确要求「GUI 实操一轮 difference → judge(reject) → accept → evolve」。桌面端（VCL + WebView2 + JS 桥）的决策入口从未被真实启动过。代码接线存在且单测覆盖，但**真实环境测试缺位 + 证据冒充**违反 G4/G5。

## 三、重审要求（对开发甲，范围极窄——只补 GUI 真实环境验证）

1. **真实启动 Desktop `AsWish.exe`**，打开 `dogfood_gui_site_final/`（或新现场），在真实 GUI 中实操：打开差异页（difference.html 由 Controller 通道渲染落盘）→ Unacceptable 拒绝 → Accept 接受 → Evolve 演进；确认 `.AsWish/html/difference.html` 与 `decisions.html` 真实生成、WebView2 按钮事件走通、产物与 CLI 同构（snapshot/decisions 逐项一致）；
2. 留痕：GUI 实操截图（每步一张）+ 操作原始记录存档 `WO/evidence/`；产物现场保留并在报告中列出 difference.html/decisions.html 的实际路径；
3. **更正审计报告**：CLI 产生的证据不得标注为 GUI 验证；报告声称逐条对应现场文件；方法签名、tag 指向（实际指向 f1ef684）等表述与实物一致；
4. 顺带（非阻断，下轮起生效）：代码/测试类单 commit ≤200 行（本轮 2814354=250 行、a192bf0=203 行超限；docs/evidence 类不追溯）；
5. 全量测试 206 不回退；**P1/P3 全部成果与 tag 禁止重做**（若 GUI 实操产生新决策/基线，按追加演进处理，ID 顺延单调）。

## 四、P1/P3 结论

- P1 批量 Dogfood：APPROVED；
- P3 发布通道：APPROVED（v0.1.0 tag 保留有效，GUI 补验后如需重打包再议）。

---
*裁定依据：0029 工单 P2 验收硬标准、非睿智轻量门禁 G4（真实环境）/G5（零虚假声称）。*
