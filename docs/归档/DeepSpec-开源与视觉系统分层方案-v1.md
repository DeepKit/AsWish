# DeepSpec 开源与视觉系统分层方案（决策底稿）

> 版本：v1.0 | 2026-08-28 | 起草：主控 AI（Codex 席，代 Amy）
> 性质：决策底稿，待老板拍板。三处「决策点」留空，老板填写后即为正式决议底稿。
> 法源对齐：`DeepSpec/docs/DeepSpec-定位升级-所见即所得开发文档优化器-v1.md`、`DeepSpec/SPEC.md`、`DeepBase/docs/28.ui.HB视觉基础设施-下游软件集成统一指南.md`

---

## 一、三个既定事实（核实结论，非假设）

| # | 事实 | 证据 |
|---|---|---|
| F1 | DeepSpec 是独立软件，要对外开源 | Delphi GUI(MainForm) + CLI + protocol 层，架构清晰 src/{app,core,models,providers,services} |
| F2 | DeepSpec 依赖 DeepBase | `DeepSpec.dpr` "Based on DeepBase/DeepShell"，引用 DeepBase.Manager / Persistence.Manager.FireDAC / AutoFix / VclHook |
| F3 | HB 视觉系统住在 DeepBase 内 | DeepBase.HB.Core / HB.Palettes / VCL.HB.Controls（THbTheme/THbSummaryBar/THbBadge 等） |

由此推出一个贯穿本方案的核心矛盾：

> **DeepSpec 开源 → 要抽掉 DeepBase 依赖；但适配 HB 视觉系统 → 又加深 DeepBase 依赖。二者方向相反。**

---

## 二、三个战略判断

### 判断一：DeepSpec 分层开源（不开整仓）

**结论：开"产品层"，关"内部治理层"。**

| 层 | 内容 | 开源？ |
|---|---|---|
| 开源层 | `protocol/`（协议，Apache-2.0 已就位）、`src/`（解析器/模型/核心）、`docs/`（公开文档）、README/LICENSE | ✅ 开 |
| 闭源/内部层 | `boundary.json`、`bugfix.md`、`workorders/`、`发散讨论/`、`DeepSpecConfig.db`、`root.txt`、`installer/` 内部路径 | ❌ 留在 internal 或 gitignore |

### 判断二：DeepBase 护城河保留（整体不开源）

**结论：DeepBase 是 28 个产品的地基，AutoFix 自愈 / 浏览器自动化 / LLM 主备兜底 / 治理是独门设计，整体开源=送掉产品层护城河。**

**附加硬伤（不因意愿而变）**：
- Delphi/RAD Studio 是商业 IDE，外人无 Studio 编译不了 → 开源 Delphi 项目本身门槛极高；
- FireDAC 是 RAD Studio 商业组件，开源包含 FireDAC 依赖的代码无法被自由再编译。

**结论：DeepBase 内核闭源；只开"薄接口 + 聚焦的 LLM facade 适配层"（见判断三）。**

### 判断三：HB 视觉系统「规范/实现」分层

**结论：HB 不是铁板一块，天然分两层，分开处理。**

| HB 层 | 内容 | 处置 |
|---|---|---|
| 设计军规/令牌 | 颜色令牌、WCAG 2.1 AA、DPI 四档、五态、Fail-Closed、军规 | ✅ DeepSpec 遵循（零代码依赖，开源品质底线） |
| 实现层 | THbTheme / THbSummaryBar / THbBadge 等 Delphi 控件 | ⏸ 暂缓接入（= DeepBase 代码，接入即焊死） |

---

## 三、DeepBase 依赖抽离：三选项（核心决策）

| 选项 | 做法 | 利 | 弊 | 建议 |
|---|---|---|---|---|
| **A. 接口层抽离** | DeepSpec 对 DeepBase 的调用抽成接口 + 开源一个参考实现，DeepBase 作可插拔后端 | 架构最干净；开源可独立跑；护城河保住 | 改造量最大 | ⭐ 长期首选 |
| B. DeepBase 一起开 | 连带开源 DeepBase | 最彻底 | 送掉地基护城河 + Delphi/FireDAC 硬伤 | ❌ 否 |
| C. DeepSpec 独立化 | 用标准库/开源驱动替代 FireDAC 等 DeepBase 单元 | 彻底摆脱 DeepBase | 重新造轮子，损失 AutoFix 等能力 | 视改造量定 |

**主控推荐：走 A**——先抽"DeepSpec 依赖 DeepBase 的最小接口集"，DeepBase 变可插拔后端；FireDAC 仅留在 DeepBase 后端内，DeepSpec 开源侧不暴露。

---

## 四、HB 视觉系统分层落地

1. **DeepSpec 应遵循**（即"设计军规"）：颜色不硬编码（令牌取色）、WCAG AA 对比度、DPI 100/125/150/200 四档、五态齐备、Fail-Closed 存证。
2. **DeepSpec 暂缓接入**：THbTheme/THbControls 控件实现（属 DeepBase 代码）。
3. **反向建议**：把 HB 的「设计令牌 + 军规」抽成一份**独立于 DeepBase 的规范**（可随 DeepSpec 一起开源），28 个产品共享同一设计语言、却不都背 DeepBase 依赖。

---

## 五、开源前清理清单（可执行，按序）

1. 根目录补 `LICENSE`（Apache-2.0，与 protocol/ 一致）
2. 恢复 `README.md`（开源门面，讲清"所见即所得规格层"定位）
3. 清出内部文件：`boundary.json / bugfix.md / workorders/ / 发散讨论/ / DeepSpecConfig.db / root.txt`
4. `.gitignore` 补全：`bin/ dcu/ *.exe *.db root.txt`
5. 先定决策点 D1（DeepBase 抽离方式），再定公开面
6. 收敛当前未提交大改（git 现存 README 已删、多文件 D/M 态）到一个稳定 commit

---

## 六、与睿智工作流的关系（承接"残次品"根因）

DeepSpec 开源不改变它在体系内的角色，反而坐实了它：

```
DeepSpec 冻结规格（开发前"所见即所得"，你点头）
        ↓
生产（Ruizi / 甲乙）
        ↓
SPW 验收 = 对着 DeepSpec 冻结规格逐条验（开发后"对图验"）
```

- DeepSpec 由"旁路工具"升级为**所有软件的统一前置门**（决策点 D4）；
- DeepSpec 的 review_status / accept_level 接成 **SPW H1–H5 验收基准**（决策点 D5），堵住"残次品"的验收端。

---

## 七、决策记录（老板填写）

| 决策点 | 内容 | 选项 | 老板裁定 |
|---|---|---|---|
| D1 | DeepBase 依赖抽离方式 | A 接口层抽离 / B 一起开 / C 独立化 | ＿＿＿ |
| D2 | DeepBase 是否整体开源 | 是 / 否 | ＿＿＿ |
| D3 | HB 实现层是否接入 DeepSpec | 接入 / 暂缓 | ＿＿＿ |
| D4 | DeepSpec 是否升级为统一前置门 | 是 / 旁路 | **是**（老板 2026-08-28 拍板） |
| D5 | DeepSpec 规格是否接 SPW 验收基准 | 是 / 否 | **是**（老板 2026-08-28 拍板） |
| D6 | 开源时机 | 立即清理后开 / 先抽依赖再开 | ＿＿＿ |

---

## 八、下一步（老板裁定 D1–D6 后按序执行）

1. 若 D1=A：先做 DeepSpec 依赖接口抽离改造（需先评估改造量，出实施工单）
2. 若 D6=清理后开：执行第五节清理清单，出干净公开仓
3. 若 D5=是：把 DeepSpec 冻结规格接入 SPW 验收基准（合入 G3/G4 收口工程）
