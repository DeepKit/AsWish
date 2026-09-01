# DeepSpec · HB 视觉优化指南（独立版）

> **母本**：`D:\_Progs\02Business\DeepBase\docs\28.ui.HB视觉基础设施-下游软件集成统一指南.md`（v1.1）
> **生成**：2026-08-25（Amy 批量下发）| **决策权**：本产品开发人员自行决定是否/何时换皮——本指南只给映射与建议，不下指令
> **编译器**：Delphi 13.1 Win64（`D:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc64.exe`），门禁 0 Error / 0 Warning

---

## 1. 本产品适用判定

| 项 | 值 |
|---|---|
| 架构 | VCL |
| 推荐主题 | graphite / indigo-academic |
| 推荐控件组合 | THbSummaryBar(四投影审阅) + THbStreamBlock + THbBadge(review decision) |
| 典型场景映射 | 规格审阅、语义束跨树、decision 存证展示 |

## 2. 三步快速接入

```pascal
// (1) 包依赖（.dpk/.dproj requires）
DeepBaseCore,
  DeepBaseVCL;

// (2) 启动时初始化（Application.Initialize 后）
uses DeepBase.HB.Core, DeepBase.HB.Palettes;
THbTheme.Initialize;
THbTheme.ApplyTheme('graphite', hdComfortable); // 密度按本产品建议调整

// (3) 控件即用（自动响应主题切换广播）
uses DeepBase.VCL.HB.Controls; // FMX 端改用: DeepBase.FMX.HB.Controls
```

完整组件范例（THbDialog / THbVoiceDialog / THbStreamBlock / THbSummaryBar / THbToastHost / THbShareCardRenderer / THbMotionKit）**见母本第 4 节**，本文件不重复。

## 3. 本产品立即替换点建议（由开发人员裁量）

规格审阅、语义束跨树、decision 存证展示——建议先选一个低风险窗体/面板试点，跑通第 5 节七项门禁后再放量。

## 4. 本产品专属注意事项

protocol 已 Apache-2.0；GUI/CLI 收费需差异化理由；113 单测基线保持

## 5. 门禁与军规（PR 验收必过）

- [ ] 编译门禁：dcc64(37.0) 0 Error / 0 Warning / 0 Leaked DCU
- [ ] 反事实门禁：CF-VOICE-01..06 六大断言通过（涉语音/写库时）
- [ ] 令牌门禁：全文无硬编码色值（`$00FFFFFF`、`clRed` 等），一律经 `THbTheme.Tokens` 取色
- [ ] DPI：100 / 125 / 150 / 200% 四档无文本截断、无图标模糊、无布局重叠
- [ ] 五态：Normal / Hover / Pressed / Disabled / Focus 齐备
- [ ] 对比度：WCAG 2.1 AA（正文 ≥ 4.5:1，大字 ≥ 3.0:1）
- [ ] Fail-Closed：所有入库/覆写具备人类确认态 + 取消回滚

**军规摘要**：UI 线程禁 Sleep；跨线程必须 `TThread.ForceQueue`（严禁 Queue）；音频句柄 try..finally 确定性释放；含中文源文件必须 UTF-8 BOM；统一 Command ID 防绕审计。

## 6. 决策记录（开发人员填写）

- [ ] 是否接入 HB：____（是 / 部分 / 暂缓）　决定人：________　日期：________
- [ ] 首批替换窗体/面板：________________
- [ ] 预计批次：____　门禁结果：____