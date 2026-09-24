# WO-20260924-0047 · 开发AI · AsWish 真实项目实测（DeepAxis + DeepCompare）：UI 与实际结果的差距

- 下发时间：2026-09-24 (GMT+8) · 下发人：Amy（依老板指令"把它使用在 axis 和 compare 项目上"）
- 承接方：AsWish 测试AI（只读两目标项目，**禁止修改 DeepAxis/DeepCompare 任何文件**）
- 优先级：P1（发布门 gate3-realuse 的正式开考）
- 目的：**测差距**，不是测通过——凡是 AsWish 界面说的和实际发生的对不上，都是本单要抓的 bug

## 被测对象

- `D:\_Progs\02Business\DeepAxis`（Delphi 主仓，含 __history 等噪音目录——正好测 scan 鲁棒性）
- `D:\_Progs\02Business\DeepCompare`（混合布局：09_工程脚本/日志/代码混排——测文件归类）

## 执行脚本（每个项目独立走一遍，全程留原始输出）

1. **Scan 真实度**：`AsWish.CLI.exe scan <项目>` → 数四棵树节点；抽 10 节点人工比对
   标题/摘要/SourceRefs 行号与实际源码；错误归类、空引用、行号越界逐条记录。
2. **GUI 一致性**：`AsWish.exe <项目>` 起真机 → 走 RunGuiVerification 之外**新增断言**：
   - HTML 页每个 `data-action` 按钮真点一次（非 mock），验证宿主响应与页面提示一致；
   - 侧栏（0044 D-1）提交一条真实意图 → 树上是否真出现对应 ChangeSet；
   - Ghosts chips（D-2）在两项目上各触发一次，narrative 角标是否显示。
3. **全链闭环**：intent → changeset → review（含 Commons 警示注入）→ reject 一次 +
   accept 一次 → baseline verify → evidence collect → difference 对比**真实**代码改动
   （用 git 在 DeepAxis 工作副本外做临时 clone 改一行，验证 difference 抓到 dkChanged）。
4. **性能记录**：大目录 scan 耗时、内存；两项目数据进报告。

## 产出

- `WO/evidence/realuse-0047/`：原始日志 + 截图 + `差距清单.md`（每条含：现象、UI 说辞 vs
  实际行为、复现步骤、定级 P0~P2）
- 差距清单里 P0/P1 项 → **同回合**按规矩开出返修工单编号预留在报告尾部
- 两项目 `.AsWish/` 生成物目录保留供复核，列入两项目的 .gitignore（不改其代码，只加 ignore 一行，单独 commit）

## 红线

- 对 DeepAxis/DeepCompare 只读（clone 出去改除外）；
- 报告里 AsWish 的缺陷不许用"已知限制"话术软化——实测发现的问题按 0041 先例全部如实定级；
- 任何"通过"必须带可重放命令，遵守 BCW-D20260923-002。
