# AsWish 专项调研：开发前视觉契约与“所见即所得”的自动验证
> **调研目标**：探究业界如何将“Visual Intent”转化为“Visual Contract”，并对最终软件进行“Conformance Verification”。
> **日期**：2026-09-06

---

## 01. 问题定义
在传统开发中，UI 设计图只是一种**单向参考（Reference）**。设计师在 Figma 确认的“视觉意图（Visual Intent）”，经过程序员的大脑翻译后，变成代码。验证过程完全依赖肉眼（QA 或验收）。
AsWish 追求的路线是：将视觉意图转化为**机器可计算的约束契约（Visual Contract）**，在代码生成和运行后，通过自动化采集真实 UI（Observable Result），与契约进行**一致性比对（Conformance Verification）**，把“人眼找错”变成“机器算差异，人类判意图”。

## 02. 当前软件行业怎么解决“设计与实现一致”
当前行业主流闭环极度破碎：
1. **Design Handoff**：通过 Zeplin / Figma Dev Mode 交付标注。
2. **Component Driven**：用 Storybook 隔离开发 UI 组件。
3. **Visual Regression**：用 Chromatic / Percy 对最终页面截图比对。
**痛点**：它们全是在比对“代码的昨天和今天”，而不是“代码和最初的设计契约”。

## 03. Design System 能解决什么 / 不能解决什么
**能解决**：基础资产的同一性。通过 Design Tokens (颜色、间距) 和 Atomic Components 保证了“一块砖”是标准的。
**不能解决**：无法定义“这面墙”的逻辑。Design System 无法描述“搜索框必须在侧边栏顶部”这种上下文级结构契约。它约束了样式（Style），但不约束意图（Intent）和结构（Structure）。

## 04. Figma 与 Design-to-Code 现状
* **现状**：Figma 推出了 Dev Mode、Variables 和 Code Connect。可以把 Figma 的 Component 映射到 GitHub 里的 React Component 代码。
* **局限**：Figma 的节点树（Node Tree）包含大量为了排版而存在的冗余 Frame，无法直接作为工程结构的契约。目前 Figma 仍然是单向流（Design -> Code），不支持开发后的软件反向连接回 Figma 自动计算结构偏差（只能人为放个截图上去对比）。

## 05. Storybook / Component Contract
* **现状**：Storybook 是目前业界事实上的 **Component Contract（组件级契约）** 标准。它的 `Args` 约束了状态，`Play function` 约束了交互，结合 Chromatic 构成了视觉契约。
* **局限**：它只能验证“孤立组件”。当组件被拼装成复杂页面，注入真实业务状态时，Storybook 无能为力。它适合作为 AsWish 的原子库，但不适合作为全局 Visual Baseline。

## 06. Visual Regression Testing (像素级 vs 感知级)
* **Pixel Difference**（如 Playwright Snapshot, reg-suit）：逐像素异或（XOR）。
  * *缺点*：极其脆弱（Flaky）。抗锯齿差异、系统字体微调、GPU 渲染差异都会导致全盘飘红。绝对不适合作为跨环境的 Visual Contract。
* **Perceptual Difference**（如 Applitools Visual AI）：利用计算机视觉算法（SSIM 变种），模仿人眼忽略像素级抗锯齿，只关注布局和明显视觉变化。
  * *结论*：对于 Rendered Appearance 层的契约，必须使用 Perceptual Diff，禁止使用纯像素比对。

## 07. UI Tree / DOM / Accessibility Tree
要把视觉作为契约，必须结构化。
* **DOM Tree**：太脏，充满了 `<div>` 嵌套和技术实现细节，极不适合作为契约。
* **Accessibility Tree (A-Tree)**：**这是最接近 AsWish Semantic Contract 的原生结构**。浏览器过滤了无语义的 `div`，只暴露有意义的 `Role` (Button, Textbox)、`Name` 和 `State`。
* *结论*：将 UI 契约拆解，其骨架层应当基于类似于 A-Tree 的 Semantic Tree 进行比对。

## 08. Layout Constraint 技术
* **现状**：CSS Flex/Grid, Flutter Layout, VCL Anchors/Align。
* **对比**：`Button.Left = 842` (绝对像素契约) 在不同屏幕下立刻失效。真正高复用的契约是**关系契约（Relational Contract）**：“按钮位于容器末尾，且垂直居中”。
* *结论*：视觉 Baseline 决不能保存绝对坐标 Bounds，而必须保存基于 Layout Solver 的 Constraints。

## 09. Design Node ↔ Implementation Node Identity
* **难点**：如何知道真实界面的按钮就是设计稿上的那个按钮？
* **解法**：业界目前唯一成熟的解法是 **Stable Semantic IDs**（如 Web 中的 `data-testid` 或自动化测试中的 `AutomationId`）。
* *结论*：AsWish 在从 Visual Preview 生成契约时，必须为每个关键节点打上唯一的 UUID（或语义 ID），并在最终 AI 生成代码时强制注入该 ID。这使 Node-to-Node 结构比对成为可能。

## 10. Runtime UI Evidence Capture
* **Web**：使用 Playwright / Puppeteer 提取 DOM + CSSOM，同时利用 Chrome DevTools Protocol (CDP) 直接拉取 Accessibility Tree 和精确的 BoundingClientRect。
* **Windows Desktop**：通过 Microsoft UI Automation (UIA) 提取结构。
* **Delphi VCL**：利用 RTTI 或 FindWindowEx 遍历 `TWinControl` 树，可以直接读取 BoundsRect, Align, Visible 等属性。
* *结论*：真实运行软件的 UI Evidence 完全可以被自动化、结构化地反向提取。

## 11. 多层 Visual Difference (AsWish 核心模型推荐)
比对绝不能只用一张截图，业界前沿已趋向分层：
* **Layer 1: Structure (结构)** -> 比较 A-Tree / Widget Tree 的拓扑增删改。
* **Layer 2: Layout (布局)** -> 提取 Runtime Bounding Boxes，转换为相对拓扑关系（如 A 是否在 B 内部/左侧）进行比对。
* **Layer 3: Style (样式)** -> 比较运行时计算出的 Computed Styles (字体、颜色色值)。
* **Layer 4: Pixel/Perceptual (视觉)** -> 最终的渲染外观比对。
* *价值*：分层比对能告诉用户：“按钮确实还在那里（L1 Pass），但在右边（L2 Fail），颜色是对的（L3 Pass）。”这才是真正人类可判断的 Difference。

## 12. Deterministic Rendering (确定性渲染)
为了让 Layer 4 (截图) 契约成立，必须固定 Environment Contract。
* *解法*：固定 Viewport Size, 锁定容器 (如统一用 WebView2 头文件), 禁用系统字体缩放 (Font Scaling), 锁定 Theme (强行 Light Mode)。允许极小范围的 SSIM 容差 (Tolerance)。

## 13. AI Visual Verification (大模型视觉验证)
* **最新方向**：GPT-4o, Claude 3.5 Sonnet, 结合 WebVoyager 等 GUI Agent 论文。
* **能力**：AI 能一眼看出“这还是个登录框”，即使按钮从左边移到了右边。
* **致命缺陷**：不可审计、缺乏确定性。AI 今天说 Pass，明天可能说 Fail。
* *结论*：AI 不适合做 Visual Contract 的“最终裁判（Judge）”。AI 适合用来把像素**解释（Explain）**成相对关系，但两棵树的 Difference 对比必须由传统的确定性算法（Tree Diff）完成。

## 14. 商业产品对照表
| 产品名称 | 解决问题 | Baseline 是什么 | 如何比较 | 自动化 | 对 AsWish 的价值 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Applitools** | 跨设备视觉测试 | 历史云端截图 | Perceptual AI Diff | 是 | 感知比较算法的标杆 |
| **Chromatic** | 组件视觉回归 | Storybook 产物 | 像素级/DOM级 | 是 | Component Contract 的事实标准 |
| **Percy** | CI 截图测试 | 历史渲染 DOM | 冻结 DOM 重新渲染比对 | 是 | 捕获 DOM+CSS 渲染的思路 |
| **Zeplin** | Handoff | 设计稿 | 人眼比对 | 否 | 设计与代码 Token 映射机制 |
| **Builder.io** | Design to Code | Figma | AI 直接翻译为代码 | 半自动 | 提供了从设计生成代码的参考，但不具备双向契约 |
| **Figma DevMode**| 交付标注 | 设计图 | 标尺和人类比对 | 否 | 缺乏逆向验证闭环 |
| **Datadog Synthetics**| 线上监控 | 元素选择器 | 运行态 DOM | 是 | 提供了基于语义找元素的生产经验 |
| **Playwright** | E2E 测试 | 测试脚本 | 断言与像素比对 | 是 | 强大的多浏览器 Runtime 提取器 |
| **Cypress** | E2E 测试 | 测试脚本 | 断言 | 是 | 稳定的 DOM 状态拦截 |
| **Locofy** | Figma to Code| Figma 树 | 自动转换 | 半自动 | 证明了设计树到 DOM 树直译的不可靠性 |

## 15. 开源项目对照表
| 项目名称 | 解决问题 | 比较层级 | 能否作为视觉契约 |
| :--- | :--- | :--- | :--- |
| **Storybook** | 隔离开发与测试 | Component | 能，但仅限原子级 |
| **Playwright** | 自动化驱动 | 全层级 | 它是最好的执行器，但本身不是契约 |
| **BackstopJS** | 开源像素测试 | Pixel Layer | 否，过于脆弱 |
| **jest-image-snapshot** | 单元视觉测试 | Pixel Layer | 否 |
| **reg-suit** | 视觉回归套件 | Pixel Layer | 否 |
| **Appium** | 跨平台 UI 驱动 | Accessibility Tree | 是，极佳的跨端结构提取器 |
| **WinAppDriver** | Windows GUI 驱动 | UI Automation Tree | 是，Windows 版的 DOM 提取器 |
| **Selenium** | Web 驱动 | DOM | 逐渐被 Playwright 淘汰 |
| **Puppeteer** | Web 驱动 | DOM/CDP | Playwright 的前身 |
| **Testing Library** | 语义化测试 | Accessibility | 是，倡导按用户所见（Role/Text）找元素 |
| **OSWorld / WebArena**| AI Agent 测试场 | 多模态 | 用于评估 Agent，含有极高的 UI 验证论文价值 |
| **Loki** | 离线组件回归 | Pixel | 否 |
| **React Cosmos** | 组件沙盒 | Component | 类似于 Storybook |
| **Histoire** | Vue 组件库 | Component | 同上 |
| **Accessibility Insights**| A11y 检查 | Accessibility Tree | 提供极佳的结构化树解析思路 |

## 16. 论文与研究
1. *WebVoyager: Building an End-to-End Web Agent with Large Multimodal Models (2024)* - 证明了 VLM 可以理解 UI 树，但强调了 DOM 的噪点问题。
2. *Screen2Vec: Semantic Embedding of GUI Screens and GUI Components (2021)* - 将 GUI 转化为语义向量，对 AsWish 结构比对有启发。
3. *RICO: A Mobile App Dataset for Building Data-Driven Design Applications (2017)* - 包含了极具价值的视图层级（View Hierarchy）与视觉特征的映射。
4. *Understanding Web UI with Multimodal LLMs* - 论证了结合 Accessibility Tree 和截图的双通道比对是最准的。

## 17. 最接近 AsWish 的 Top 5 方案
1. **Playwright + Testing Library (A-Tree 断言)**：最接近结构层级的意图验证，缺了自动生成断言契约的一环。
2. **Storybook + Chromatic**：最接近 Component Contract，缺了 Page/App 级的全局逻辑。
3. **Applitools Visual AI**：最接近 Render Difference，缺了底层的 Semantic Structure 理解（它只能说图不一样，不能指出数据模型变了）。
4. **Figma Code Connect**：最接近 Design ↔ Code 的双向映射，缺了自动化拦截和差异运算机制。
5. **UI Automation (WinAppDriver/Appium)**：在端侧最接近将 Runtime 反向抽象为结构化 UI 树。

## 18. 当前行业仍未解决的问题
**没有一个系统实现了“自上而下”的视觉契约闭环**。
设计师的图是图，测试的断言是断言，程序员的代码是代码。当差异发生时，没有统一的标准说“到底谁违反了最开始确认的那个契约”。

## 19. 可直接复用的成熟技术
- 运行时采集：Playwright (Web), UIA (Windows)。
- 结构化过滤：Accessibility Tree API。
- 标识映射：`data-testid` 模式。
- 差异渲染算法：SSIM 或像素容差算法。

## 20. AsWish 可能需要原创的部分
**Multi-Layer Visual Contract Engine (多层视觉契约引擎)**：
必须原创一套能容纳 `[ Semantic Node ID -> Constraint Rule -> Computed Style -> Screenshot ]` 四位一体的协议。开发前，用户通过 Visual Preview 冻结这四层数据；开发后，系统反抽这四层，进行独立的 Tree Diff 和 Hash 比较。

## 21. 对“Visual Contract”是否成立的最终判断
**完全成立，且技术条件在 2026 年已彻底成熟。**
只要放弃“绝对像素还原”，转向“分层语义契约（结构相同 + 约束一致 + 视觉容差）”，这条路将彻底终结“设计还原度”这个长达二十年的行业毒瘤。

---

# 《给产品经理看的 2 页结论》

### 1. 这件事现在别人做到什么程度？
目前行业极度割裂。
- 设计端（Figma）只负责画图，图是“死”的，无法变成约束代码的法则。
- 测试端（Chromatic/Applitools）只负责“防回退”。它们比较的是“今天的代码和昨天的代码”，而不是“今天的代码和最开始定下的契约”。
- AI 编程生成端（Cursor/Copilot）主要靠猜。它们生成完代码后，根本不知道长出来的 UI 对不对。

### 2. 为什么今天仍然存在 Design ≠ Implementation？
核心原因是**语义断层与坐标迷信**。
设计稿画的是绝对坐标（Button X=10, Y=20），而现代开发用的是流式布局（Flex/Grid）。此外，UI 中的大量节点（如包裹层 div）在设计稿中不存在。由于缺少统一的 **Stable Semantic ID（语义主键）** 连接两端，机器根本无法自动对齐，只能靠人眼当裁判。

### 3. 哪些技术已经完全成熟可以直接拿来用？
* **Runtime 提取能力**：不管是 Web 的 DOM/Accessibility API，还是 Windows 的 UI Automation，反向提取真实运行软件的树状结构、坐标、颜色，技术已经非常成熟（如 Playwright）。
* **感知级比较（Perceptual Diff）**：忽略抗锯齿、字体渲染微小差异的计算机视觉算法已经非常稳定。

### 4. 哪些地方行业还没有解决？
行业尚未实现 **“前置契约化（Shift-Left Contract）”**。没有人把用户在开发前确认的那张 UI 草图，先一步翻译成“包含拓扑关系、相对约束、语义 ID 的机器断言树”，然后再让 AI 照着这棵树去写代码并自我验证。

### 5. 关键判断：AsWish 如何实现“开发前所见 ≈ 开发后所得”？
要打通这个体验，AsWish 绝不能把“一张截图”当成契约。
AsWish 真正需要建立的核心能力是**“四层结构化差异追踪体系”**：

**AsWish 路线推演（完全可行且必须采取）：**
1. **生成契约**：用户确认预览后，AsWish 不仅存下图，更要保存背后的 **UI 树状骨架（Semantic Tree）**，并为每个核心组件生成固定的 `automation-id`。
2. **AI 生成代码**：AI 被明确约束：必须将这些 `id` 埋入真实代码的 DOM/VCL 节点中，且必须满足对齐约束（Layout Constraints）。
3. **真实采集**：程序编译运行后，AsWish 通过自动化工具（Playwright/WinAppDriver）探入活的程序，拔出运行时的真实 UI 树，并截取真实截图。
4. **四层判定（核心创新）**：
   - **Layer 1 (结构)**：用 `id` 查找，东西还在吗？层级对吗？
   - **Layer 2 (布局)**：计算运行时坐标，按钮还在右边吗？
   - **Layer 3 (样式)**：读取真实色值，是约定的红色吗？
   - **Layer 4 (视觉)**：最终截图与预期是否存在重大崩坏？
5. **Human Judgment**：机器将这四层 Difference 客观地列给用户。用户最终决定：是接受差异，还是打回让 AI 修改。

**结论**：不要用 AI 去做视觉比对的裁判，AI 会幻觉；**用结构化的 UI 树去比对逻辑，用 SSIM 算法去比对像素容差，把最终的判断权，永远留在人类手中。** 这一技术路线目前已具备完全的落地条件。
