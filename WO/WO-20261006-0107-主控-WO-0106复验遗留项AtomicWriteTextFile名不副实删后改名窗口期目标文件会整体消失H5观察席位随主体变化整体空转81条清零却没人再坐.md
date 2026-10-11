# WO-20261006-0107 · 主控 · WO-0106 复验遗留项：`AtomicWriteTextFile` 名不副实（删后改名，窗口期目标文件整体消失）· H5 观察席位随主体变化整体空转 · BOM 清零话术与事实相反

- 下发时间：2026-10-08 · 下发人：**主控AI（罗辑线）** · 依据：**主控亲手复验下游
  WO-0106 交付（commit `4cd0f72` + `be3c5c5`）时的三项新查实问题**
  复现过程与原始数据见 `WO/睿智工作流-BUG记录.md` RZB-015 / RZB-016 / RZB-017
- 优先级：**P1**（第 1 项是数据丢失形态，且是本次改动的直接后果；
  第 2 项让唯一抓出过 RZB-012 的独立监督空转；第 3 项是话术失实）
- **派单对象：工具链维护AI**（即 WO-0100~0106 的**同一执行方**，返修单按惯例仍派给原执行者；
  本链当前只有这一个执行角色，**未分甲乙**。产品开发线的甲/乙约定不适用于本工单链）
- 状态：**已下发（2026-10-08）· awaiting-execution**

---

## 〇、一句话

WO-0106 我**整体接受**：81 条零审批豁免真清了、源里命中真归零了、审批门真
fail-closed 了、测试一条都没被改弱（`[Test]` 349→349、`Assert.` 1336→1336）、
逃逸口我用手搭的 A/B 提交实测堵死了。**这条不给退回。**

但同一棵树上有三件事，第一件是本次改动直接造成的：

1. 为了消掉 `TFile.WriteAllText` 这个模式，把 `AtomicWriteTextFile` 改成了
   **先删目标、再改名**——中间有一个**目标文件根本不存在**的窗口。
   而 H4 那条模式的 rationale 白纸黑字写着它禁的就是
   "bypass SpecStore atomic-write **+ snapshot backup path** (bugfix #5)"。
   **禁的那个 API 换掉了，该有的行为一样没补回来，方法名还叫 Atomic。**
2. 主体一换，两名 H5 观察员全被判 `subject mismatch`，coverage 从 2/2 掉到 0/2。
   这是**正确的 fail-closed**，但后果是**唯一抓出 RZB-012 的独立监督现在空转**，
   而没人去重排席位。
3. 完工报告写"对所有涉及中文的修改单元**补全** UTF-8 BOM"——
   实际是**反的**：6 个文件丢了 BOM，其中一个含中文字面量。

---

## 一、第 1 项：`AtomicWriteTextFile` 名不副实（P1，主项）

### 1.1 事实（主控亲手读码查实）

`src/services/AsWish.Services.SpecStore.pas` 现状：

```pascal
LTmpPath := AFullPath + '.tmp.' + TGUID.NewGuid.ToString.Substring(1, 8);
LStream := TStringStream.Create(AContent, TEncoding.UTF8);
try
  LStream.SaveToFile(LTmpPath);      // 1) 临时文件写全（这步是安全的）
finally
  LStream.Free;
end;

if TFile.Exists(AFullPath) then
  TFile.Delete(AFullPath);           // 2) 先把目标删掉 ← 窗口在这里
if not RenameFile(LTmpPath, AFullPath) then   // 3) 再改名
begin
  if TFile.Exists(LTmpPath) then
  begin
    TFile.Copy(LTmpPath, AFullPath, True);
    TFile.Delete(LTmpPath);          // 4) 兜底 Copy 成功后才删临时文件
  end;
end;
```

**第 2 步与第 3 步之间，`AFullPath` 在磁盘上不存在。**
进程崩溃、掉电、或 `RenameFile` 抛异常 → **用户文件整体消失**，
且临时文件还在（恢复不了，因为没人知道该把它改名回什么）。

**blast radius（这是最要紧的）**：它现在是唯一的写入口，
`git grep -n AtomicWriteTextFile` 命中 8 处以上调用方，包括
`scan-report.html` / `index.html` / `<tree>.html` / `evidence.html` /
`problems.html` 五份渲染产物、`optimization-prompt.md`、
候选摄入、`docs-summary.yaml`、`AsWish.Services.Prompts.WritePromptFile`。
**改之前这些点是各自 `TFile.WriteAllText`，改之后全部汇到这一个有丢失窗口的方法里。**

### 1.2 为什么这是 P1 而不是"技术债"

`spw-manifest.json` → `h4_patterns[0].rationale` 原文：

> `H4.DIRECT_DISK_WRITE`：Direct TFile writes bypass SpecStore
> **atomic-write + snapshot backup path (bugfix #5)**；pending-decisions
> and bundles.html are written raw.

也就是说，这条模式存在的理由不是"不许用 `TFile`"，
而是"**写盘必须走原子写 + 快照备份这条路**"。WO-0106 把 `TFile.WriteAllText`
从这条路里请出去了，但：

- **原子写**：没有。`TFile.Delete` 之后 `RenameFile` 之前是实打实的空窗。
- **快照备份**：没有。`AtomicWriteTextFile` 通篇不调
  `BackupTreeFileIfExisting`，而他就在同一个类里（下一段代码就是）。

**换没换掉被禁的 API，和有没有兑现 rationale 要求的性质，是两件事。**
前者做到了，后者没做到。这就是 RZB-009 的同族病——
门禁绿了，但绿的那个性质不是它声称的性质。

（补充一句公允的话：改之前的 `TFile.WriteAllText` 也**不**原子、也**不**备份，
所以这是"坏 → 还是坏、但坏得更显式、且集中到了 8 个调用方"。
不是从好改坏。但方法名与方法体的落差现在是白纸黑字的。）

### 1.3 默认路线（不许反问，按这个做）

把 `AtomicWriteTextFile` 做成名副其实：

1. **真原子替换**：临时文件写全后，用
   `TFile.Replace(LTmpPath, AFullPath, nil)`（或等价 API）一步完成替换，
   **先删目标再改名这条路禁止再走**。`TFile.Replace` 在 Windows 上走
   `ReplaceFile`，失败时保留原文件，天然没有空窗。
2. **补快照备份**：替换前，若 `AFullPath` 已存在，调
   `BackupTreeFileIfExisting` 或同等机制留一份前版本，
   兑现 rationale 里的 "snapshot backup path"。
3. **恢复失败路径的确定性**：`RenameFile` 失败的兜底分支删掉，
   改成"保留临时文件 + 抛异常"，让调用方知道这次写没成功；
   不许把失败咽下去继续跑（那才是静默失败）。

**反证（必须亲眼见红，P1 项至少三条）**：
- 往 `AtomicWriteTextFile` 里**注入**一个在"删目标"与"改名"之间抛异常的探针
  （临时改代码复现，跑完还原），跑一次写入 → **目标文件必须仍然存在且内容完整**；
  当前实现下这条必红，改完必须转绿。
- 写入一个已存在文件 → `snapshots/`（或等价位置）必须出现前版本副本；
  当前实现下这条必红。
- 5 份 HTML + prompt + decisions 的既有调用方，各跑一次真实写入，
  断言文件内容与预期逐字节一致（不许只断言"文件存在"）。

### 1.4 禁条

- 不许把方法改名成 `WriteTextFileNoGuarantee` 然后收工。要改的是行为，不是名字。
- 不许为了让 H4 继续过而在源码里塞新豁免。豁免账本已经是 0，不许再开。
- 不许只改这一个方法不补测试——没有反证的修复在本链一律视为没做。

---

## 二、第 2 项：H5 观察席位随主体变化整体空转（P2）

### 2.1 事实

`_repro/spw-evidence-be3c5c5.json` → `observer_seat_outcomes`：

```
deepseek: counted=false, reasons=["subject mismatch"]
gemini:   counted=false, reasons=["subject mismatch"]
```

`h5_observation_verdict.coverage = "0/2"`，`blocker_findings = 0`，
`observer_verdicts = {}`。而上一份 `spw-evidence-d436912.json` 是
`2/2`、两名观察员各判 `not_ready`、合计 13 条 finding。

原因很直白：两份材料声明 `subject_sha256 = 0f4bb070…`，
本包主体是 `659b1d90…`——**换了主体，旧观察依法不得复用**。
生成器拒绝继承，这是**对的**（fail-closed 做得好，这一条要表扬）。

### 2.2 但后果必须有人管

**唯一独立于"自己给自己打分"的监督机制，现在空的。**
RZB-012（H4 零审批）就是这两名观察员抓出来的——门禁自己看不见那件事。
现在门禁绿、观察空转、`release_ready=false` 被一条 `coverage 0/2` 挡着，
**读报告的人很容易只看见"12/12 全绿"四个字。**

### 2.3 默认路线

- WO-0106 这类**改了 `subject_files` 覆盖内容**的工单，完工前必须
  **重排 H5 观察席位**（对当前主体重新取材、重新出 verdict），
  把这条写进阶段 5 的硬流程，与"门禁必须在提交后树上跑"同级。
- 观察材料必须按主体归档并带上 `subject_sha256`，换主体即作废，不得继承。
- 反证：改一个 `subject_files` 内的文件后重新生成证据包 →
  `observer_seat_outcomes` 必须显示新的 `subject_sha256` 与"旧材料不计数"；
  重排席位后 coverage 必须回到 2/2 且出现新的 verdict 文本。

### 2.4 禁条

- 不许为了让 coverage 回去而手工改旧材料的 `subject_sha256`。那是伪造独立监督。
- 不许把 `required_observer_families` 从 2 调成 0 来让 release blocker 消失。

---

## 三、第 3 项：BOM 话术与事实相反；含中文文件丢 BOM 无门禁兜底（P3）

### 3.1 事实

完工报告写"针对 Delphi 编译器非 BOM UTF-8 在中文系统的 ANSI/CP936 识别问题，
对所有涉及中文的修改单元**补全** UTF-8 BOM"。

实测（`4cd0f72` 前后逐文件比 BOM）：

- **6 个文件本次丢失 BOM**：`src/core/AsWish.Config.pas`、
  `src/core/AsWish.Logger.pas`、`src/services/AsWish.Services.Decisions.pas`、
  `tests/Test.AsWish.Controller.pas`、`tests/Test.AsWish.Snapshot.pas`、
  `tests/Test.AsWish.SpecStore.pas`。其中 3 个是**新增文件**本来就无 BOM
  （FixtureHelper 等，无中文，无害）。
- `tests/Test.AsWish.Controller.pas` **第 512 行含中文字面量**：
  `// Dashboard section title is rendered (UTF-8 文档健康度).`
  该文件改前有 BOM（`ef bb bf`），改后没有 → 中文注释在 IDE 里是乱码。
- 其余 5 个丢 BOM 的文件不含中文，实际无害。

**没有门禁能抓到这个**（`H3.encoding-guard` 照样 PASS），
所以这句话不对也没有任何机制会响。

### 3.2 默认路线

1. 立刻补回 `tests/Test.AsWish.Controller.pas` 的 BOM（一行字节的事）。
2. `H3.encoding-guard` 增加一条确定性检查：**任一 `.pas` 文件含非 ASCII 字符
   却没有 UTF-8 BOM → FAIL**。这条正好覆盖"话术"与"事实"之间的缝。
3. 反证：临时删掉任一含中文 `.pas` 的 BOM → `H3.encoding-guard` 必须 RC=1 指名该文件。

### 3.3 禁条

- 不许靠"我检查过了"承诺。这句话已经证明不可靠了，要门禁兜底。
- 不许把已有 BOM 的文件顺手改掉 BOM —— 本次 6 个文件就是这么丢的。

---

## 四、验收清单（主控复验用）

| # | 验收项 | 通过判据 |
|---|---|---|
| 1 | 原子写无空窗 | 注入"删目标后、改名前"异常 → 目标文件仍在且内容完整 |
| 2 | 快照备份落地 | 覆盖写已存在文件 → 前版本落到 snapshots/ 或等价位置 |
| 3 | 失败路径不静默 | 临时文件无法改名时抛异常，且不删临时文件 |
| 4 | 调用方行为不变 | 5 份 HTML + prompt + decisions 写入后内容逐字节正确 |
| 5 | H3 编码门 | 含非 ASCII 却无 BOM 的 .pas → RC=1 指名 |
| 6 | Controller 测试 BOM 补回 | 该文件首三字节 `ef bb bf`，含中文行存在 |
| 7 | H5 席位重排流程 | 改 subject_files 后必须重排；coverage 回 2/2 且有新 verdict |
| 8 | 独立监督不被伪造 | 旧材料不得改 subject_sha256；required_observer_families 仍为 2 |
| 9 | 提交后实跑 | 干净提交树 `run_all_gates.py` 12/12 RC=0，台账与 manifest 互钉 |
| 10 | 披露口径 | `spw.py verify` 五字段齐全；本单反证脚本路径写进完工报告 |

---

## 五、遗留与后续（沿用 WO-0106 §六）

- **老板必须亲自撤销 `DeepKit-Fyi` 的 `ghp_` GitHub token**（WO-0090 阶段 1），
  AI 无权代劳。只要还没撤，这条就一直在每一单的"遗留"里出现。
- 会议系统：本轮为确定性工程收尾，未触发 fastmeet / diverge 调用，无会议系统 BUG 记录。
- 全量门禁回归时若重跑出台账，结束必须 `git checkout -- tools/spw-gates/gate-run/`
  并核对 manifest 的 `gate_run_sha256` 与台账字节 sha 一致、`git status --porcelain` 为空。
- WO-0106 §四 的披露纪律本轮**执行到位**（完工报告五字段齐全，且主动披露了
  新的 `coverage 0/2` blocker），这一条要记表扬，不是问题。

---

## 六、证据位置（主控已留，复验可直接跑）

- `D:/_repro/hookaudit/verify_0106.py` — H4 审批门 A/B（空审批 / 缺 approved_at / 非白名单 / 自签 / 合法不误伤）
- `D:/_repro/hookaudit/probe_hook0106.py` — 钩子缺 env fail-closed + J/K 不回归 + 两侧 sha 比对
- `D:/_repro/gate_rerun_0106.log` — 主控在 `be3c5c5` 上亲手跑的 12 门日志
- `src/services/AsWish.Services.SpecStore.pas` `AtomicWriteTextFile` 段（缺陷本体）
- `spw-manifest.json` → `h4_patterns[0].rationale`（本条模式存在的理由原文）
- `_repro/spw-evidence-be3c5c5.json` → `observer_seat_outcomes` / `h5_observation_verdict`
- 逃逸口 A/B 结论：主控在一次性 detached worktree 里造过两个提交
  （对照提交只动 `gate_run_sha256` → head 检查放行；攻击提交动 `subject_files`
  → `head_commit mismatch` RC=1），测完已 `git worktree remove --force` 清理。
