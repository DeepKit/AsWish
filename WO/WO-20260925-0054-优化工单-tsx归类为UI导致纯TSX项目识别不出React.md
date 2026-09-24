# WO-20260925-0054 · `.tsx` 被归为 UI 而非代码，纯 TSX 项目识别不出 React

| 项 | 内容 |
|---|---|
| 工单号 | WO-20260925-0054 |
| 母单 | WO-20260925-0052（scan 管线两份实现 CLI 与 GUI 分叉）执行中记录、未修 |
| 提出日期 | 2026-09-25 |
| 优先级 | P2 |
| 状态 | 已隔离复现，待修 |

---

## 1. 问题

`TAsWishScanService` 把 `.tsx` 放进 `UI_EXTS`，于是 `.tsx` 文件被分类为
`fcUI`；而 `DetectProjectType` **只看 `fcCode`** 的文件。

两个后果：

1. 一个只有 `.tsx`、没有 `.ts` 的 React 项目，`CategoryCount(fcCode) = 0`，
   `DetectProjectType` 返回 `'unknown'`——它既不"没有代码"也不是"混合"，
   就是一个 React 项目没被认出来。
2. `DetectProjectType` 里 `HasAnyExt(LCodeFiles, ['.ts', '.tsx'])` 的
   `.tsx` 这一半**永远不可能命中**，是死分支。留着它会让人误以为
   TSX 项目已被覆盖。

同类扩展名同在 `UI_EXTS` 的还有 `.jsx` / `.vue` / `.svelte` / `.astro` /
`.xaml` / `.qml`，同一个盲区，不止 `.tsx` 一个。

---

## 2. 复现（已跑）

`tests/Test.AsWish.Scan.pas` 新增
`TsxOnlyProject_IsNotRecognisedAsCode`：fixture 只放 `App.tsx` + `index.tsx`，
断言 `DetectProjectType = 'unknown'`。**通过**——即当前行为确实是错的。

固定版本：`24827d2`。全量 299/299。

---

## 3. 为什么当时没顺手修

WO-0052 的既定范围是"消除 CLI 与 GUI 的分叉"，改分类表会改变
**所有项目**的 `fcUI`/`fcCode` 归属，进而改变页面上的分类统计和
`project.yaml` 的 `type` 字段。那是一次有意的行为变更，不属于
"把两份实现合成一份"，塞进一个 fork 合并单里会污染改前改后对比。

---

## 4. 待裁定（修之前必须定）

**核心问题：`.tsx` 到底是代码还是 UI？**

| 选项 | 做法 | 影响 |
|---|---|---|
| A | 从 `UI_EXTS` 移到 `CODE_EXTS` | 最直接，`DetectProjectType` 无需改。但 `.tsx` 同时含有 UI 语义，UI 分类的统计会少一批文件 |
| B | 保留在 `UI_EXTS`，让 `DetectProjectType` 同时看 `fcUI` | 不动分类统计，只放大检测面。但 `fcUI` 里还有 `.html` / `.xaml` / `.qml`，只看扩展名白名单而非整个分类 |
| C | 引入 `fcUI` 与 `fcCode` 的双归属 | 最正确，但改的是分类模型本身，blast radius 最大，不推荐在本单做 |

**默认路线（无人异议时按此执行）：B。** 理由：分类表影响的是页面统计，
那是给老板看的口径，能不动就不动；而项目类型是纯元数据（`DetectProjectType`
的注释已说明"displayed and written into project.yaml, nothing branches on it"），
放大它的检测面不改变任何统计口径。做法是把 React 检查的输入从
"fcCode 文件"改成"fcCode 文件 + `UI_EXTS` 白名单里的文件"，只对
`['.ts', '.tsx', '.jsx']` 生效，不把 `.html` / `.xaml` 算成 React 源码。

---

## 5. 验收

1. `TsxOnlyProject_IsNotRecognisedAsCode` 的期望值从 `'unknown'` 改为
   `'web_react'`，亲眼看过转红再改实现。
2. 现有 7 条 `TScanProjectTypeTests` 全部仍通过（不因放宽检测面而翻转）。
3. `.jsx` / `.vue` / `.svelte` / `.astro` 是否一并覆盖，按裁定结论补测试；
   若只修 `.tsx`，在 `DetectProjectType` 的注释里写明为什么不全覆盖。
4. 全量测试通过，三构建 exit 0。
