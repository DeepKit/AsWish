
{ ============================================================================
  AsWish.Services.Render

  HTML rendering service. Generates static HTML from .AsWish data
  for human review in WebView2 (P2) or external browser (P1).
  ============================================================================ }

unit AsWish.Services.Render;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.Services.Scan,
  AsWish.Models;

type
  /// <summary>Health metrics for the index dashboard (BUG-9 §2.2).
  /// Pure computation over node lists (+ optional issues).</summary>
  THealthMetrics = record
    TotalNodes: Integer;
    ConfirmedNodes: Integer;   // GenStatus = gsConfirmed
    CoveragePct: Double;       // ConfirmedNodes / TotalNodes * 100 (0 if none)
    AvgConfidence: Double;     // low=0.3 / medium=0.7 / high=1.0, mean
    DecisionBacklog: Integer;  // issues with Status = issOpen
    FogCount: Integer;         // nodes with HasFogState and FogState <> fsClear
    HighRiskOpen: Integer;     // issues Status=issOpen and Severity in (isCritical,isHigh)
  end;

  TAsWishRenderService = class(TInterfacedObject)
  private
    FBasePath: string;
    FLocale: string;
    function HtmlEscape(const S: string): string;
    function PageHeader(const ATitle: string): string;
    function PageFooter: string;
    function StatusBadge(const AStatus: string): string;
    function ConfidenceBadge(const AConf: string): string;
    function SourceLayerBadge(const ALayer: string): string;
    // CSS slug for a fog state: underscores -> hyphens (bugfix.md BUG-12),
    // so badge-fog-unknown-unknowns matches the hyphen style of badge-fog-misty.
    function FogStateCssClass(AFog: AsWish.Models.TFogState): string;
    /// <summary>Locale-aware UI text: returns AZh when the review pages are
    ///  rendered for a Chinese Windows locale, else AEn. Only used for
    ///  human-visible chrome (titles/buttons/hints), never for YAML keys.</summary>
    function T(const AEn, AZh: string): string;
    function YamlEscape(const S: string): string;
  public
    procedure Initialize(const AAsWishPath: string);
    procedure RenderScanReport(AScan: TAsWishScanService;
      const AProjectName, AProjectType: string);
    procedure RenderIndex(const AProjectName: string; ATotalFiles: Integer;
      AFunc, AModule, AView, AData: TList<TSpecNode>;
      AIssues: TList<TSpecIssue>; AHasDataTree: Boolean = True);
    procedure RenderTree(const ATreeName, ATreeTitle: string;
      ANodes: System.Generics.Collections.TList<AsWish.Models.TSpecNode>);
    procedure RenderProblemsPage(
      AFuncNodes, AModuleNodes, AViewNodes, ADataNodes: TList<TSpecNode>;
      AIssues: TList<TSpecIssue>);
    procedure RenderBundlesPage(
      ABundles: TList<TSemanticBundle>;
      AFuncNodes, AModuleNodes, AViewNodes, ADataNodes: TList<TSpecNode>);
    /// <summary>Render a single-node detail page (node-detail.html) shown
    ///  in the main view when the user clicks a tree node.</summary>
    procedure RenderNodeDetail(const ANode: TSpecNode);
    /// <summary>Render the 4-layer ChangeSet review surface (changeset-review.html)
    ///  implementing 0-9 universal choice protocol and decision actions.</summary>
    procedure RenderChangeSetReviewPage(const AChangeSet: TChangeSet;
      ANodes: TList<TSpecNode>; const AProjectName: string = '');
    /// <summary>Compute health metrics over 4 trees (+ optional issues).
    /// nil lists are treated as empty. Pure — no IO.</summary>
    class function ComputeHealthMetrics(AFunc, AModule, AView, AData: TList<TSpecNode>;
      AIssues: TList<TSpecIssue> = nil): THealthMetrics; static;
    /// <summary>Count broken cross-tree references (orphan refs).
    /// Shared by RenderIndex summary and RenderProblemsPage detail.</summary>
    class function CountCrossTreeConflicts(AFunc, AModule, AView, AData: TList<TSpecNode>): Integer; static;
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  System.StrUtils,
  System.Generics.Defaults,
  Winapi.Windows;

procedure TAsWishRenderService.Initialize(const AAsWishPath: string);
begin
  FBasePath := TPath.Combine(AAsWishPath, 'html');
  if not TDirectory.Exists(FBasePath) then
    TDirectory.CreateDirectory(FBasePath);

  // Detect the Windows UI language once so review pages render localized
  // chrome (titles/buttons/hints). Same normalization as the desktop shell.
  FLocale := 'en-US';
  var LLocale: array[0..84] of WideChar;
  if GetUserDefaultLocaleName(LLocale, Length(LLocale)) > 1 then
  begin
    var LL := string(PWideChar(@LLocale[0])).ToLower;
    if LL.StartsWith('zh-hans') or LL.StartsWith('zh-cn')
       or LL.StartsWith('zh-sg') or (LL = 'zh') then
      FLocale := 'zh-CN'
    else if LL.StartsWith('zh-hant') or LL.StartsWith('zh-tw')
            or LL.StartsWith('zh-hk') or LL.StartsWith('zh-mo') then
      FLocale := 'zh-TW';
  end;
end;

function TAsWishRenderService.T(const AEn, AZh: string): string;
begin
  if FLocale = 'zh-CN' then
    Result := AZh
  else
    Result := AEn;
end;

function TAsWishRenderService.HtmlEscape(const S: string): string;
begin
  Result := S
    .Replace('&', '&amp;')
    .Replace('<', '&lt;')
    .Replace('>', '&gt;')
    .Replace('"', '&quot;');
end;

function TAsWishRenderService.YamlEscape(const S: string): string;
begin
  Result := '"' + S.Replace('\', '\\').Replace('"', '\"').Replace(#13, ' ').Replace(#10, ' ') + '"';
end;

function TAsWishRenderService.PageHeader(const ATitle: string): string;
begin
  Result :=
    '<!DOCTYPE html>' + sLineBreak +
    '<html lang="en">' + sLineBreak +
    '<head>' + sLineBreak +
    '  <meta charset="UTF-8">' + sLineBreak +
    '  <title>' + HtmlEscape(ATitle) + ' - AsWish</title>' + sLineBreak +
    '  <style>' + sLineBreak +
    '    :root {' + sLineBreak +
    '      --bg-color: #ffffff; --text-color: #1e293b; --card-bg: #f8fafc; --card-border: #e2e8f0;' + sLineBreak +
    '      --choice-opt-bg: #eff6ff; --choice-opt-text: #1e40af; --choice-opt-border: #bfdbfe;' + sLineBreak +
    '      --choice-rec-border: #2563eb; --choice-regen-bg: #f5f3ff; --choice-regen-text: #6b21a8;' + sLineBreak +
    '      --choice-regen-border: #ddd6fe; --choice-input-bg: #ecfdf5; --choice-input-text: #065f46;' + sLineBreak +
    '      --choice-input-border: #a7f3d0; --choice-back-bg: #f8fafc; --choice-back-text: #475569;' + sLineBreak +
    '      --choice-back-border: #cbd5e1; --badge-explicit-bg: #dbeafe; --badge-explicit-text: #1e40af;' + sLineBreak +
    '      --badge-inferred-bg: #fef3c7; --badge-inferred-text: #92400e; --badge-unknown-bg: #f3f4f6;' + sLineBreak +
    '      --badge-unknown-text: #4b5563;' + sLineBreak +
    '    }' + sLineBreak +
    '    @media (prefers-color-scheme: dark) {' + sLineBreak +
    '      :root {' + sLineBreak +
    '        --bg-color: #0f172a; --text-color: #f1f5f9; --card-bg: #1e293b; --card-border: #334155;' + sLineBreak +
    '        --choice-opt-bg: #1e293b; --choice-opt-text: #93c5fd; --choice-opt-border: #3b82f6;' + sLineBreak +
    '        --choice-rec-border: #60a5fa; --choice-regen-bg: #2e1065; --choice-regen-text: #c084fc;' + sLineBreak +
    '        --choice-regen-border: #7c3aed; --choice-input-bg: #064e3b; --choice-input-text: #34d399;' + sLineBreak +
    '        --choice-input-border: #059669; --choice-back-bg: #1e293b; --choice-back-text: #94a3b8;' + sLineBreak +
    '        --choice-back-border: #475569; --badge-explicit-bg: #1e3a8a; --badge-explicit-text: #bfdbfe;' + sLineBreak +
    '        --badge-inferred-bg: #78350f; --badge-inferred-text: #fde68a; --badge-unknown-bg: #374151;' + sLineBreak +
    '        --badge-unknown-text: #d1d5db;' + sLineBreak +
    '      }' + sLineBreak +
    '    }' + sLineBreak +
    '    body { font-family: -apple-system, "Segoe UI", sans-serif; margin: 2em; color: var(--text-color); background: var(--bg-color); }' + sLineBreak +
    '    h1 { border-bottom: 2px solid #4a90e2; padding-bottom: 0.5em; }' + sLineBreak +
    '    h2 { color: #4a90e2; margin-top: 1.5em; }' + sLineBreak +
    '    .stat { display: inline-block; margin: 0.5em 1em 0.5em 0; padding: 0.5em 1em;' + sLineBreak +
    '            background: var(--card-bg); border-left: 3px solid #4a90e2; border-radius: 4px; }' + sLineBreak +
    '    .stat strong { display: block; font-size: 1.5em; color: #4a90e2; }' + sLineBreak +
    '    .file-list { background: var(--card-bg); padding: 1em; border-radius: 4px; max-height: 400px; overflow-y: auto; }' + sLineBreak +
    '    .file-list code { display: block; padding: 0.2em 0; font-size: 0.9em; }' + sLineBreak +
    '    .badge { display: inline-block; padding: 0.2em 0.6em; border-radius: 3px;' + sLineBreak +
    '             font-size: 0.85em; margin-right: 0.5em; }' + sLineBreak +
    '    .badge-doc { background: #e3f2fd; color: #1976d2; }' + sLineBreak +
    '    .badge-code { background: #f3e5f5; color: #7b1fa2; }' + sLineBreak +
    '    .badge-ui { background: #fff3e0; color: #f57c00; }' + sLineBreak +
    '    .badge-config { background: #e8f5e9; color: #388e3c; }' + sLineBreak +
    '    .badge-ai { background: #fce4ec; color: #c2185b; }' + sLineBreak +
    '    .badge-source-explicit { background: var(--badge-explicit-bg); color: var(--badge-explicit-text); font-weight: bold; }' + sLineBreak +
    '    .badge-source-inferred { background: var(--badge-inferred-bg); color: var(--badge-inferred-text); font-weight: bold; }' + sLineBreak +
    '    .badge-source-unknown  { background: var(--badge-unknown-bg); color: var(--badge-unknown-text); font-weight: bold; }' + sLineBreak +
    '    .card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 8px; padding: 1.2em; margin-bottom: 1.2em; }' + sLineBreak +
    '    .card-i-said { border-left: 4px solid #3b82f6; }' + sLineBreak +
    '    .card-ai-understood { border-left: 4px solid #8b5cf6; }' + sLineBreak +
    '    .card-changes { border-left: 4px solid #10b981; }' + sLineBreak +
    '    .card-decision { border-left: 4px solid #f59e0b; }' + sLineBreak +
    '    .intent-box { background: rgba(59, 130, 246, 0.08); padding: 1em; border-radius: 6px; }' + sLineBreak +
    '    .intent-text { font-size: 1.15em; font-style: italic; margin: 0 0 0.5em 0; }' + sLineBreak +
    '    .intent-meta { font-size: 0.85em; color: #64748b; display: flex; gap: 1.5em; }' + sLineBreak +
    '    .changes-table { width: 100%; border-collapse: collapse; margin-top: 0.8em; }' + sLineBreak +
    '    .changes-table th, .changes-table td { border: 1px solid var(--card-border); padding: 0.6em 0.8em; text-align: left; }' + sLineBreak +
    '    .changes-table th { background: rgba(0,0,0,0.03); }' + sLineBreak +
    '    .diff-before { background: #fee2e2; color: #991b1b; padding: 0.2em 0.4em; border-radius: 3px; text-decoration: line-through; }' + sLineBreak +
    '    .diff-after  { background: #dcfce7; color: #166534; padding: 0.2em 0.4em; border-radius: 3px; font-weight: 600; }' + sLineBreak +
    '    .choice-container { display: flex; flex-direction: column; gap: 0.5em; margin-top: 0.8em; }' + sLineBreak +
    '    .btn-choice { display: flex; align-items: center; width: 100%; text-align: left; padding: 0.8em 1em; border-radius: 6px; font-size: 0.95em; cursor: pointer; transition: all 0.15s ease; border: 1px solid transparent; }' + sLineBreak +
    '    .btn-choice-opt { background: var(--choice-opt-bg); color: var(--choice-opt-text); border-color: var(--choice-opt-border); }' + sLineBreak +
    '    .btn-choice-rec { border: 2px solid var(--choice-rec-border); font-weight: bold; }' + sLineBreak +
    '    .btn-choice-danger { background: #fef2f2; color: #991b1b; border-color: #fecaca; }' + sLineBreak +
    '    .btn-choice-regen { background: var(--choice-regen-bg); color: var(--choice-regen-text); border-color: var(--choice-regen-border); }' + sLineBreak +
    '    .btn-choice-input { background: var(--choice-input-bg); color: var(--choice-input-text); border-color: var(--choice-input-border); }' + sLineBreak +
    '    .btn-choice-back { background: var(--choice-back-bg); color: var(--choice-back-text); border-color: var(--choice-back-border); }' + sLineBreak +
    '    .choice-key { font-family: monospace; font-weight: bold; margin-right: 0.8em; font-size: 1.1em; }' + sLineBreak +
    '    .choice-divider { height: 1px; background: var(--card-border); margin: 0.5em 0; }' + sLineBreak +
    '    .rec-badge { margin-left: auto; background: #2563eb; color: #fff; font-size: 0.75em; padding: 0.2em 0.5em; border-radius: 4px; }' + sLineBreak +
    '    .form-panel { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 6px; padding: 1em; margin-top: 1em; }' + sLineBreak +
    '    .form-textarea { width: 100%; min-height: 80px; padding: 0.6em; border-radius: 4px; border: 1px solid var(--card-border); font-family: inherit; font-size: 0.95em; box-sizing: border-box; }' + sLineBreak +
    '    .form-actions { margin-top: 0.6em; display: flex; gap: 0.6em; }' + sLineBreak +
    '    .btn-primary { background: #2563eb; color: #fff; border: none; padding: 0.5em 1em; border-radius: 4px; cursor: pointer; font-weight: 500; }' + sLineBreak +
    '    .btn-secondary { background: #64748b; color: #fff; border: none; padding: 0.5em 1em; border-radius: 4px; cursor: pointer; }' + sLineBreak +
    '    .status-banner { margin-top: 1em; padding: 0.8em 1.2em; border-radius: 6px; font-weight: 500; }' + sLineBreak +
    '    .status-success { background: #dcfce7; color: #166534; border: 1px solid #86efac; }' + sLineBreak +
    '    .status-danger { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }' + sLineBreak +
    '    .status-info { background: #e0f2fe; color: #075985; border: 1px solid #7dd3fc; }' + sLineBreak +
    '    footer { margin-top: 3em; padding-top: 1em; border-top: 1px solid var(--card-border);' + sLineBreak +
    '             color: #999; font-size: 0.85em; }' + sLineBreak +
    '  </style>' + sLineBreak +
    '</head>' + sLineBreak +
    '<body>' + sLineBreak;
end;

function TAsWishRenderService.PageFooter: string;
begin
  Result :=
    '<footer>' + sLineBreak +
    '  Generated by AsWish at ' +
    HtmlEscape(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)) + sLineBreak +
    '</footer>' + sLineBreak +
    '</body>' + sLineBreak +
    '</html>' + sLineBreak;
end;

procedure TAsWishRenderService.RenderScanReport(AScan: TAsWishScanService;
  const AProjectName, AProjectType: string);
var
  LSb: TStringBuilder;

  procedure AppendCategory(const ATitle, ABadgeClass: string;
    AFiles: TArray<string>);
  begin
    LSb.AppendLine('<h2><span class="badge ' + ABadgeClass + '">' +
      HtmlEscape(ATitle) + '</span> ' + Length(AFiles).ToString + '</h2>');
    if Length(AFiles) = 0 then
      LSb.AppendLine('<p><em>' + T('No files in this category.', '此类别没有文件。') +
        '</em></p>')
    else
    begin
      LSb.AppendLine('<div class="file-list">');
      for var LFile in AFiles do
        LSb.AppendLine('<code>' + HtmlEscape(LFile) + '</code>');
      LSb.AppendLine('</div>');
    end;
  end;

begin
  LSb := TStringBuilder.Create;
  try
    LSb.Append(PageHeader(T('Scan Report', '扫描报告')));

    LSb.AppendLine('<h1>' + T('Scan Report', '扫描报告') + ': ' +
      HtmlEscape(AProjectName) + '</h1>');
    LSb.AppendLine('<p>' + T('Project type:', '项目类型：') +
      ' <strong>' + HtmlEscape(AProjectType) + '</strong></p>');

    LSb.AppendLine('<h2>' + T('Summary', '汇总') + '</h2>');
    LSb.AppendLine('<div class="stat"><strong>' + AScan.TotalFiles.ToString +
      '</strong>' + T('Total files', '文件总数') + '</div>');
    LSb.AppendLine('<div class="stat"><strong>' + AScan.CategoryCount(fcDocuments).ToString +
      '</strong>' + T('Documents', '文档') + '</div>');
    LSb.AppendLine('<div class="stat"><strong>' + AScan.CategoryCount(fcCode).ToString +
      '</strong>' + T('Code', '代码') + '</div>');
    LSb.AppendLine('<div class="stat"><strong>' + AScan.CategoryCount(fcUI).ToString +
      '</strong>' + T('UI', '界面') + '</div>');
    LSb.AppendLine('<div class="stat"><strong>' + AScan.CategoryCount(fcConfig).ToString +
      '</strong>' + T('Config', '配置') + '</div>');
    LSb.AppendLine('<div class="stat"><strong>' + AScan.CategoryCount(fcAiRules).ToString +
      '</strong>' + T('AI Rules', 'AI 规则') + '</div>');

    AppendCategory(T('Documents', '文档'), 'badge-doc',
      AScan.GetFilesByCategory(fcDocuments));
    AppendCategory(T('Code', '代码'), 'badge-code',
      AScan.GetFilesByCategory(fcCode));
    AppendCategory(T('UI', '界面'), 'badge-ui',
      AScan.GetFilesByCategory(fcUI));
    AppendCategory(T('Config', '配置'), 'badge-config',
      AScan.GetFilesByCategory(fcConfig));
    AppendCategory(T('AI Rules', 'AI 规则'), 'badge-ai',
      AScan.GetFilesByCategory(fcAiRules));

    LSb.Append(PageFooter);

    TFile.WriteAllText(TPath.Combine(FBasePath, 'scan-report.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
  end;
end;

procedure TAsWishRenderService.RenderIndex(const AProjectName: string;
  ATotalFiles: Integer; AFunc, AModule, AView, AData: TList<TSpecNode>;
  AIssues: TList<TSpecIssue>; AHasDataTree: Boolean);
var
  LSb: TStringBuilder;
  LM: THealthMetrics;
  LConflicts: Integer;
  LHighShown, LIdx: Integer;
  LI: TSpecIssue;
  LSorted: TList<TSpecIssue>;
  LCovStr, LConfStr: string;
begin
  LSb := TStringBuilder.Create;
  LSorted := nil;
  try
    LSb.Append(PageHeader(T('Index', '索引')));
    LSb.AppendLine('<h1>AsWish: ' + HtmlEscape(AProjectName) + '</h1>');
    LSb.AppendLine('<p>项目规格健康度看板（BUG-9）。</p>');

    // --- §2.3.1 文档健康度（4 stat 卡片）---
    LM := ComputeHealthMetrics(AFunc, AModule, AView, AData, AIssues);
    LConflicts := CountCrossTreeConflicts(AFunc, AModule, AView, AData);
    LCovStr := FormatFloat('0.0', LM.CoveragePct);
    LConfStr := FormatFloat('0', LM.AvgConfidence * 100.0);

    LSb.AppendLine('<h2>文档健康度</h2>');
    LSb.AppendLine('<div class="stat"><strong>' + LCovStr + '%</strong>覆盖率' +
      '<small style="display:block;color:#6c757d;">已确认节点占比。文档够不够 AI 开发用。</small></div>');
    LSb.AppendLine('<div class="stat"><strong>' + LConfStr + '%</strong>平均置信度' +
      '<small style="display:block;color:#6c757d;">low=30 / medium=70 / high=100</small></div>');
    LSb.AppendLine('<div class="stat"><strong>' + LM.DecisionBacklog.ToString +
      '</strong>决策积压<small style="display:block;color:#6c757d;">未决 issue 数（status=open）</small></div>');
    LSb.AppendLine('<div class="stat"><strong>' + LM.FogCount.ToString +
      '</strong>雾区数<small style="display:block;color:#6c757d;">处于迷雾中的节点（fog≠clear）</small></div>');

    // --- §2.3.2 高风险问题（top 5）---
    LSb.AppendLine('<h2>高风险问题</h2>');
    LSorted := TList<TSpecIssue>.Create;
    if AIssues <> nil then
      for LI in AIssues do
        if (LI.Status = issOpen) and ((LI.Severity = isCritical) or (LI.Severity = isHigh)) then
          LSorted.Add(LI);
    // sort by severity asc (critical=0 < high=1) so most severe first
    LSorted.Sort(TComparer<TSpecIssue>.Construct(
      function(const A, B: TSpecIssue): Integer
      begin
        Result := Ord(A.Severity) - Ord(B.Severity);
      end));
    LHighShown := 0;
    LSb.AppendLine('<ul style="padding-left: 0;">');
    for LIdx := 0 to LSorted.Count - 1 do
    begin
      if LHighShown >= 5 then Break;
      LI := LSorted[LIdx];
      Inc(LHighShown);
      LSb.AppendLine('<li class="problem"><span class="badge badge-conf-low">' +
        HtmlEscape(TSpecEnums.IssueSeverityToStr(LI.Severity)) + '</span> ' +
        '<a href="problems.html">' + HtmlEscape(LI.Title) + '</a>' +
        ' <code>' + HtmlEscape(LI.Id) + '</code></li>');
    end;
    LSb.AppendLine('</ul>');
    if LHighShown = 0 then
      LSb.AppendLine('<p><em>当前无高风险未决问题。</em></p>');

    // --- §2.3.3 冲突摘要 ---
    LSb.AppendLine('<h2>冲突摘要</h2>');
    LSb.AppendLine('<p>跨树断引用：' + LConflicts.ToString + ' 处。' +
      ' <a href="problems.html">查看详情</a></p>');

    // --- §2.3.4 优化 Prompt 入口 ---
    LSb.AppendLine('<h2>优化 Prompt</h2>');
    LSb.AppendLine('<p>依据当前健康度导出一段优化 Prompt，拷给原 AI 工具优化底层文件（旁路工具原则）。</p>');
    LSb.AppendLine('<button class="btn-ticket" data-action="export-optimization-prompt">' +
      '导出优化 Prompt</button>');

    // --- 原有页面列表 ---
    LSb.AppendLine('<h2>Pages</h2>');
    LSb.AppendLine('<ul>');
    LSb.AppendLine('  <li><a href="scan-report.html">Scan Report</a> (' +
      ATotalFiles.ToString + ' files)</li>');
    LSb.AppendLine('  <li><a href="problems.html">Problems</a></li>');
    LSb.AppendLine('  <li><a href="bundles.html">Bundles</a></li>');
    LSb.AppendLine('  <li><a href="changeset-review.html"><strong>' +
      T('ChangeSet Review (I said &rarr; AI understood &rarr; Decision)', '意图审阅与裁决（我说 &rarr; AI 理解 &rarr; 裁决）') + '</strong></a></li>');
    LSb.AppendLine('  <li><a href="function-tree.html">Function Tree</a></li>');
    LSb.AppendLine('  <li><a href="module-tree.html">Module Tree</a></li>');
    LSb.AppendLine('  <li><a href="view-tree.html">View Tree</a></li>');
    // Only link data-tree.html when it was actually rendered; otherwise the
    // link 404s on non-Delphi projects (bugfix.md BUG-10).
    if AHasDataTree then
      LSb.AppendLine('  <li><a href="data-tree.html">Data Tree</a></li>');
    LSb.AppendLine('</ul>');

    // JS Bridge: forward export-optimization-prompt clicks to the WebView2 host.
    // (Index page has no other data-action buttons, so a focused script suffices.
    // Falls back to a visible alert when opened in a regular browser.)
    LSb.AppendLine('<script>');
    LSb.AppendLine('(function() {');
    LSb.AppendLine('  var hasBridge = !!(window.chrome && window.chrome.webview && window.chrome.webview.postMessage);');
    LSb.AppendLine('  document.addEventListener("click", function(e) {');
    LSb.AppendLine('    var t = e.target;');
    LSb.AppendLine('    if (!(t instanceof HTMLElement)) return;');
    LSb.AppendLine('    if (t.getAttribute("data-action") !== "export-optimization-prompt") return;');
    LSb.AppendLine('    if (t.classList.contains("posted")) return;');
    LSb.AppendLine('    if (hasBridge) {');
    LSb.AppendLine('      try { window.chrome.webview.postMessage(JSON.stringify({action: "export-optimization-prompt"})); }');
    LSb.AppendLine('      catch (err) { console.error("AsWish bridge:", err); return; }');
    LSb.AppendLine('      t.classList.add("posted");');
    LSb.AppendLine('      t.textContent = "✓ Prompt 已导出 (见 prompts/optimization-prompt.md)";');
    LSb.AppendLine('    } else {');
    LSb.AppendLine('      alert("AsWish bridge unavailable. Open this page inside AsWish to export the prompt.");');
    LSb.AppendLine('    }');
    LSb.AppendLine('  });');
    LSb.AppendLine('})();');
    LSb.AppendLine('</script>');

    LSb.Append(PageFooter);

    TFile.WriteAllText(TPath.Combine(FBasePath, 'index.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
    if LSorted <> nil then LSorted.Free;
  end;
end;

function TAsWishRenderService.StatusBadge(const AStatus: string): string;
begin
  Result := '<span class="badge badge-' + AStatus + '">' +
    HtmlEscape(AStatus) + '</span>';
end;

function TAsWishRenderService.ConfidenceBadge(const AConf: string): string;
begin
  Result := '<span class="badge badge-conf-' + AConf + '">' +
    HtmlEscape(AConf) + '</span>';
end;

function TAsWishRenderService.SourceLayerBadge(const ALayer: string): string;
begin
  Result := '<span class="badge badge-source">' + HtmlEscape(ALayer) + '</span>';
end;

function TAsWishRenderService.FogStateCssClass(
  AFog: AsWish.Models.TFogState): string;
begin
  // FogStateToStr returns YAML-style 'unknown_unknowns'; CSS class slugs use
  // hyphens to match badge-fog-misty / badge-fog-foggy.
  Result := AsWish.Models.TSpecEnums.FogStateToStr(AFog).Replace('_', '-');
end;

procedure TAsWishRenderService.RenderTree(const ATreeName, ATreeTitle: string;
  ANodes: System.Generics.Collections.TList<AsWish.Models.TSpecNode>);
var
  LSb: TStringBuilder;
  LNodeMap: TDictionary<string, AsWish.Models.TSpecNode>;

  procedure RenderNode(const ANodeId: string; ADepth: Integer);
  begin
    var LNode: AsWish.Models.TSpecNode;
    if not LNodeMap.TryGetValue(ANodeId, LNode) then Exit;

    var LStatus := AsWish.Models.TSpecEnums.NodeStatusToStr(LNode.Status);

    LSb.AppendLine('<li class="node node-depth-' + ADepth.ToString + '" data-node-id="' +
      HtmlEscape(LNode.Id) + '">');
    LSb.Append('<div class="node-header">');
    LSb.Append('<span class="node-title">' + HtmlEscape(LNode.Title) + '</span> ');
    LSb.Append('<span class="node-kind">' + HtmlEscape(LNode.Kind) + '</span> ');
    LSb.Append(StatusBadge(LStatus));
    LSb.Append(' <span class="badge badge-gen-' +
      AsWish.Models.TSpecEnums.GenStatusToStr(LNode.GenStatus) + '">gen:' +
      HtmlEscape(AsWish.Models.TSpecEnums.GenStatusToStr(LNode.GenStatus)) + '</span>');
    LSb.Append(' <span class="badge badge-review-' +
      AsWish.Models.TSpecEnums.ReviewStatusToStr(LNode.ReviewStatus) + '">rev:' +
      HtmlEscape(AsWish.Models.TSpecEnums.ReviewStatusToStr(LNode.ReviewStatus)) + '</span>');
    LSb.Append(' ');
    LSb.Append(ConfidenceBadge(AsWish.Models.TSpecEnums.ConfidenceToStr(LNode.Confidence)));
    LSb.Append(' ');
    LSb.Append(SourceLayerBadge(AsWish.Models.TSpecEnums.SourceLayerToStr(LNode.SourceLayer)));

    // Fog badge (only when fog_state is explicitly set and not clear)
    if LNode.HasFogState and (LNode.FogState <> AsWish.Models.fsClear) then
    begin
      var LFog := AsWish.Models.TSpecEnums.FogStateToStr(LNode.FogState);
      LSb.Append(' <span class="badge badge-fog-' + FogStateCssClass(LNode.FogState) +
        '" title="Requirement endpoint is in the fog">fog: ' +
        HtmlEscape(LFog) + '</span>');
    end;

    // Decision buttons for candidate nodes (JS Bridge writes back via WebView2 postMessage)
    if LStatus = 'candidate' then
    begin
      LSb.Append(' <span class="decision-toolbar">');
      LSb.Append('<button class="btn-confirm" data-action="node-confirm" data-node-id="' +
        HtmlEscape(LNode.Id) + '" data-node-title="' + HtmlEscape(LNode.Title) +
        '" title="Confirm this node">'#$2713' Confirm</button>');
      LSb.Append('<button class="btn-reject" data-action="node-reject" data-node-id="' +
        HtmlEscape(LNode.Id) + '" data-node-title="' + HtmlEscape(LNode.Title) +
        '" title="Reject this node">'#$2715' Reject</button>');
      LSb.Append('</span>');
    end;

    LSb.AppendLine('</div>');

    if LNode.Summary <> '' then
      LSb.AppendLine('<div class="node-summary">' + HtmlEscape(LNode.Summary) + '</div>');

    // Data-tree specific badges
    if LNode.Tree = ttData then
    begin
      if LNode.DataType <> '' then
        LSb.AppendLine('<div class="node-data-type"><span class="badge badge-data-type">' +
          HtmlEscape(LNode.DataType) + '</span></div>');
      if LNode.HasRiskScore then
        LSb.AppendLine('<div class="node-risk"><span class="badge badge-risk-' +
          AsWish.Models.TSpecEnums.RiskLevelToStr(LNode.RiskScore) + '">' +
          'risk: ' + HtmlEscape(AsWish.Models.TSpecEnums.RiskLevelToStr(LNode.RiskScore)) +
          '</span></div>');
      if LNode.Persistence <> '' then
        LSb.AppendLine('<div class="node-persistence"><span class="badge badge-persistence">' +
          HtmlEscape(LNode.Persistence) + '</span></div>');
    end;

    if Length(LNode.AcceptanceCriteria) > 0 then
    begin
      LSb.AppendLine('<details class="node-criteria"><summary>Acceptance Criteria</summary><ul>');
      for var LCrit in LNode.AcceptanceCriteria do
        LSb.AppendLine('<li>' + HtmlEscape(LCrit) + '</li>');
      LSb.AppendLine('</ul></details>');
    end;

    // Trust signals (collapsible)
    if (Length(LNode.SourceRefs) > 0) or (Length(LNode.DecisionRefs) > 0) or
      (Length(LNode.RelatedFunctions) > 0) or (Length(LNode.RelatedModules) > 0) or
      (Length(LNode.RelatedViews) > 0) or (Length(LNode.RelatedData) > 0) then
    begin
      LSb.AppendLine('<details class="trust-signals"><summary>Trust Signals</summary>');
      LSb.AppendLine('<div class="trust-signal-body">');

      // Evidence sources
      if Length(LNode.SourceRefs) > 0 then
      begin
        LSb.AppendLine('<div class="trust-section"><strong>Evidence:</strong>');
        for var LRef in LNode.SourceRefs do
        begin
          LSb.Append('<span class="trust-item trust-ref">');
          LSb.Append(HtmlEscape(LRef.RefId));
          if LRef.Relevance <> '' then
            LSb.Append(' <span class="trust-relevance">' + HtmlEscape(LRef.Relevance) + '</span>');
          LSb.AppendLine('</span>');
        end;
        LSb.AppendLine('</div>');
      end;

      // Cross-tree references
      var LHasCross := False;
      if Length(LNode.RelatedFunctions) > 0 then begin LHasCross := True;
        LSb.AppendLine('<div class="trust-section"><strong>Functions:</strong>');
        for var LRef in LNode.RelatedFunctions do
          LSb.Append('<span class="trust-item trust-func">' + HtmlEscape(LRef) + '</span>');
        LSb.AppendLine('</div>');
      end;
      if Length(LNode.RelatedModules) > 0 then begin
        LSb.AppendLine('<div class="trust-section"><strong>Modules:</strong>');
        for var LRef in LNode.RelatedModules do
          LSb.Append('<span class="trust-item trust-mod">' + HtmlEscape(LRef) + '</span>');
        LSb.AppendLine('</div>');
      end;
      if Length(LNode.RelatedViews) > 0 then begin
        LSb.AppendLine('<div class="trust-section"><strong>Views:</strong>');
        for var LRef in LNode.RelatedViews do
          LSb.Append('<span class="trust-item trust-view">' + HtmlEscape(LRef) + '</span>');
        LSb.AppendLine('</div>');
      end;
      if Length(LNode.RelatedData) > 0 then begin
        LSb.AppendLine('<div class="trust-section"><strong>Data:</strong>');
        for var LRef in LNode.RelatedData do
          LSb.Append('<span class="trust-item trust-data">' + HtmlEscape(LRef) + '</span>');
        LSb.AppendLine('</div>');
      end;

      // Decision history
      if Length(LNode.DecisionRefs) > 0 then
      begin
        LSb.AppendLine('<div class="trust-section"><strong>Decisions:</strong>');
        for var LRef in LNode.DecisionRefs do
          LSb.Append('<span class="trust-item trust-dec">' + HtmlEscape(LRef) + '</span>');
        LSb.AppendLine('</div>');
      end;

      LSb.AppendLine('</div></details>');
    end;

    if Length(LNode.Children) > 0 then
    begin
      LSb.AppendLine('<ul class="node-children">');
      for var LChildId in LNode.Children do
        RenderNode(LChildId, ADepth + 1);
      LSb.AppendLine('</ul>');
    end;

    LSb.AppendLine('</li>');
  end;

begin
  LSb := TStringBuilder.Create;
  LNodeMap := TDictionary<string, AsWish.Models.TSpecNode>.Create;
  try
    for var LNode in ANodes do
      LNodeMap.AddOrSetValue(LNode.Id, LNode);

    // Localize the tree page title by file key (function-tree/module-tree/...)
    var LTitle := ATreeTitle;
    if FLocale = 'zh-CN' then
    begin
      if ATreeName = 'function-tree' then LTitle := '功能树'
      else if ATreeName = 'module-tree' then LTitle := '模块树'
      else if ATreeName = 'view-tree' then LTitle := '界面树'
      else if ATreeName = 'data-tree' then LTitle := '数据树';
    end;
    LSb.Append(PageHeader(LTitle));

    // Tree-specific styles
    LSb.AppendLine('<style>');
    LSb.AppendLine('  .node { list-style: none; margin: 0.5em 0; }');
    LSb.AppendLine('  .node-header { padding: 0.4em; border-radius: 4px;');
    LSb.AppendLine('                 background: #f8f9fa; cursor: pointer; }');
    LSb.AppendLine('  .node-header:hover { background: #e9ecef; }');
    LSb.AppendLine('  .node-title { font-weight: 600; }');
    LSb.AppendLine('  .node-kind { color: #6c757d; font-size: 0.9em; font-style: italic; }');
    LSb.AppendLine('  .node-summary { padding: 0.3em 0.4em; color: #495057; font-size: 0.95em; }');
    LSb.AppendLine('  .node-children { padding-left: 1.5em; border-left: 2px solid #dee2e6; }');
    LSb.AppendLine('  .badge-candidate { background: #fff3cd; color: #856404; }');
    LSb.AppendLine('  .badge-confirmed { background: #d4edda; color: #155724; }');
    LSb.AppendLine('  .badge-uncertain { background: #f8d7da; color: #721c24; }');
    LSb.AppendLine('  .badge-rejected { background: #d6d8db; color: #383d41; }');
    LSb.AppendLine('  .badge-superseded { background: #d6d8db; color: #383d41; }');
    LSb.AppendLine('  .badge-conf-low { background: #f8d7da; color: #721c24; }');
    LSb.AppendLine('  .badge-conf-medium { background: #fff3cd; color: #856404; }');
    LSb.AppendLine('  .badge-conf-high { background: #d4edda; color: #155724; }');
    LSb.AppendLine('  .badge-fog-misty { background: #fff3cd; color: #856404; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-fog-foggy { background: #ffe0b2; color: #e65100; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-fog-unknown-unknowns { background: #455a64; color: #fff; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-source { background: #cce5ff; color: #004085; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-gen-draft { background: #e2e3e5; color: #383d41; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-gen-generated { background: #cce5ff; color: #004085; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-gen-confirmed { background: #d4edda; color: #155724; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-gen-skipped { background: #d6d8db; color: #6c757d; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-review-unreviewed { background: #e2e3e5; color: #383d41; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-review-accepted { background: #d4edda; color: #155724; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-review-rejected { background: #f8d7da; color: #721c24; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-review-deferred { background: #fff3cd; color: #856404; font-size: 0.75em; }');
    LSb.AppendLine('  .badge-data-type { background: #e2d9f3; color: #4a2d8a; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-risk-low { background: #d4edda; color: #155724; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-risk-medium { background: #fff3cd; color: #856404; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-risk-high { background: #f8d7da; color: #721c24; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-risk-critical { background: #721c24; color: #fff; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-persistence { background: #d1ecf1; color: #0c5460; font-size: 0.8em; }');
    LSb.AppendLine('  details summary { cursor: pointer; color: #4a90e2; padding: 0.3em 0.4em; }');
    LSb.AppendLine('  .decision-toolbar { margin-left: 0.5em; }');
    LSb.AppendLine('  .decision-toolbar button { font-size: 0.8em; margin-left: 0.25em;');
    LSb.AppendLine('    padding: 0.15em 0.5em; border: 1px solid #ced4da; border-radius: 3px;');
    LSb.AppendLine('    background: #fff; cursor: pointer; }');
    LSb.AppendLine('  .decision-toolbar .btn-confirm { color: #155724; border-color: #c3e6cb; }');
    LSb.AppendLine('  .decision-toolbar .btn-confirm:hover { background: #d4edda; }');
    LSb.AppendLine('  .decision-toolbar .btn-reject { color: #721c24; border-color: #f5c6cb; }');
    LSb.AppendLine('  .decision-toolbar .btn-reject:hover { background: #f8d7da; }');
    LSb.AppendLine('  .decision-toolbar button.posted { opacity: 0.5; cursor: default; }');
    LSb.AppendLine('  .trust-signals summary { cursor: pointer; color: #6c757d; font-size: 0.85em;');
    LSb.AppendLine('    padding: 0.2em 0.4em; border-top: 1px solid #dee2e6; margin-top: 0.3em; }');
    LSb.AppendLine('  .trust-signal-body { padding: 0.4em; font-size: 0.9em; }');
    LSb.AppendLine('  .trust-section { margin: 0.3em 0; }');
    LSb.AppendLine('  .trust-section strong { color: #495057; font-size: 0.85em; }');
    LSb.AppendLine('  .trust-item { display: inline-block; margin: 0.1em 0.3em;');
    LSb.AppendLine('    padding: 0.1em 0.4em; border-radius: 3px; font-size: 0.85em; }');
    LSb.AppendLine('  .trust-ref { background: #d1ecf1; color: #0c5460; }');
    LSb.AppendLine('  .trust-func { background: #d4edda; color: #155724; }');
    LSb.AppendLine('  .trust-mod { background: #cce5ff; color: #004085; }');
    LSb.AppendLine('  .trust-view { background: #fff3cd; color: #856404; }');
    LSb.AppendLine('  .trust-data { background: #e2d9f3; color: #4a2d8a; }');
    LSb.AppendLine('  .trust-dec { background: #f5d0e8; color: #8b4572; }');
    LSb.AppendLine('  .trust-relevance { color: #6c757d; font-size: 0.9em; }');
    LSb.AppendLine('</style>');

    LSb.AppendLine('<h1>' + HtmlEscape(LTitle) + '</h1>');
    LSb.AppendLine('<p><a href="index.html">'#$2190' Back to index</a></p>');

    if ANodes.Count = 0 then
      LSb.AppendLine('<p><em>This tree is empty. Run LLM generation to populate.</em></p>')
    else
    begin
      LSb.AppendLine('<ul class="tree-root" style="padding-left: 0;">');
      // Render roots first (no parent_id)
      for var LRoot in ANodes do
        if LRoot.ParentId = '' then
          RenderNode(LRoot.Id, 0);
      LSb.AppendLine('</ul>');
    end;

    // JS Bridge: forward decision-button clicks to the WebView2 host.
    // Falls back to a no-op (with visible warning) when opened in a regular browser.
    LSb.AppendLine('<script>');
    LSb.AppendLine('(function() {');
    LSb.AppendLine('  var hasBridge = !!(window.chrome && window.chrome.webview && window.chrome.webview.postMessage);');
    LSb.AppendLine('  document.addEventListener("click", function(e) {');
    LSb.AppendLine('    var t = e.target;');
    LSb.AppendLine('    if (!(t instanceof HTMLElement)) return;');
    LSb.AppendLine('    var action = t.getAttribute("data-action");');
    LSb.AppendLine('    if (!action) return;');
    LSb.AppendLine('    if (t.classList.contains("posted")) return;');
    LSb.AppendLine('    var msg = {');
    LSb.AppendLine('      action: action,');
    LSb.AppendLine('      node_id: t.getAttribute("data-node-id") || "",');
    LSb.AppendLine('      node_title: t.getAttribute("data-node-title") || ""');
    LSb.AppendLine('    };');
    LSb.AppendLine('    if (hasBridge) {');
    LSb.AppendLine('      try { window.chrome.webview.postMessage(JSON.stringify(msg)); }');
    LSb.AppendLine('      catch (err) { console.error("AsWish bridge:", err); return; }');
    LSb.AppendLine('      t.classList.add("posted");');
    LSb.AppendLine('      t.textContent = (action === "node-confirm" ? "'#$2713' posted" : "'#$2715' posted");');
    LSb.AppendLine('    } else {');
    LSb.AppendLine('      alert("AsWish bridge unavailable. Open this page inside AsWish to record decisions.");');
    LSb.AppendLine('    }');
    LSb.AppendLine('  });');
    LSb.AppendLine('})();');
    LSb.AppendLine('</script>');

    LSb.Append(PageFooter);

    TFile.WriteAllText(TPath.Combine(FBasePath, ATreeName + '.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
    LNodeMap.Free;
  end;
end;

procedure TAsWishRenderService.RenderProblemsPage(
  AFuncNodes, AModuleNodes, AViewNodes, ADataNodes: TList<TSpecNode>;
  AIssues: TList<TSpecIssue>);
var
  LSb: TStringBuilder;
  LAllIds: TDictionary<string, Boolean>;

  procedure ScanNodes(const ATreeLabel: string; ANodes: TList<TSpecNode>);
  begin
    if ANodes = nil then Exit;
    for var LNode in ANodes do
    begin
      // Low confidence
      if LNode.Confidence = clLow then
        LSb.AppendLine('<li class="problem problem-low-confidence">' +
          '<span class="badge badge-conf-low">' + T('low confidence', '低置信度') + '</span> ' +
          HtmlEscape(LNode.Title) +
          ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span>' +
          ' <code>' + HtmlEscape(LNode.Id) + '</code>' +
          '</li>');

      // No evidence (no source_refs and not generated/confirmed)
      if (Length(LNode.SourceRefs) = 0)
        and (LNode.GenStatus in [gsDraft, gsGenerated])
        and (LNode.SourceLayer = slAiInferred) then
        LSb.AppendLine('<li class="problem problem-no-evidence">' +
          '<span class="badge badge-prob-no-evidence">' + T('no evidence', '无证据') + '</span> ' +
          HtmlEscape(LNode.Title) +
          ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span>' +
          ' <code>' + HtmlEscape(LNode.Id) + '</code>' +
          '</li>');

      // Candidate/unreviewed node (needs human review)
      if (LNode.Status = nsCandidate) and (LNode.ReviewStatus = rsUnreviewed) then
        LSb.AppendLine('<li class="problem problem-unreviewed">' +
          '<span class="badge badge-prob-unreviewed">' + T('unreviewed', '未审阅') + '</span> ' +
          HtmlEscape(LNode.Title) +
          ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span>' +
          ' <code>' + HtmlEscape(LNode.Id) + '</code>' +
          '</li>');

      // Uncertain node
      if LNode.Status = nsUncertain then
        LSb.AppendLine('<li class="problem problem-uncertain">' +
          '<span class="badge badge-uncertain">' + T('uncertain', '不确定') + '</span> ' +
          HtmlEscape(LNode.Title) +
          ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span>' +
          ' <code>' + HtmlEscape(LNode.Id) + '</code>' +
          '</li>');

      // Fog: node whose requirement endpoint is in the fog (foggy or unknown_unknowns)
      if LNode.HasFogState and (LNode.FogState in [
        AsWish.Models.fsFoggy, AsWish.Models.fsUnknownUnknowns]) then
      begin
        var LFog := AsWish.Models.TSpecEnums.FogStateToStr(LNode.FogState);
        LSb.AppendLine('<li class="problem problem-fog">' +
          '<span class="badge badge-fog-' + FogStateCssClass(LNode.FogState) + '">fog: ' + HtmlEscape(LFog) + '</span> ' +
          HtmlEscape(LNode.Title) +
          ' <a href="#fog-map" class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</a>' +
          ' <code>' + HtmlEscape(LNode.Id) + '</code>' +
          '</li>');
      end;

      // Orphan: has parent_id but parent not found in any tree
      if LNode.ParentId <> '' then
      begin
        var LFound := False;
        for var LN in AFuncNodes do
          if LN.Id = LNode.ParentId then begin LFound := True; Break; end;
        if not LFound then
          for var LN in AModuleNodes do
            if LN.Id = LNode.ParentId then begin LFound := True; Break; end;
        if not LFound then
          for var LN in AViewNodes do
            if LN.Id = LNode.ParentId then begin LFound := True; Break; end;
        if not LFound then
          for var LN in ADataNodes do
            if LN.Id = LNode.ParentId then begin LFound := True; Break; end;
        if not LFound then
          LSb.AppendLine('<li class="problem problem-orphan">' +
            '<span class="badge badge-prob-orphan">' + T('orphan', '孤立') + '</span> ' +
            HtmlEscape(LNode.Title) +
            ' — parent <code>' + HtmlEscape(LNode.ParentId) + '</code> not found' +
            ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span>' +
            '</li>');
      end;
    end;
  end;

  procedure CheckNodeRefs(const ATreeLabel: string; ANodes: TList<TSpecNode>);
  begin
    if ANodes = nil then Exit;
    for var LN in ANodes do
    begin
      for var LRef in LN.RelatedFunctions do
        if (LAllIds <> nil) and not LAllIds.ContainsKey(LRef) then
          LSb.AppendLine('<li class="problem problem-orphan">' +
            '<span class="badge badge-prob-orphan">' + T('broken ref', '断裂引用') + '</span> ' +
            HtmlEscape(LN.Title) + ' '#8594' func <code>' + HtmlEscape(LRef) + '</code> (not found)' +
            ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span></li>');
      for var LRef in LN.RelatedModules do
        if (LAllIds <> nil) and not LAllIds.ContainsKey(LRef) then
          LSb.AppendLine('<li class="problem problem-orphan">' +
            '<span class="badge badge-prob-orphan">' + T('broken ref', '断裂引用') + '</span> ' +
            HtmlEscape(LN.Title) + ' '#8594' mod <code>' + HtmlEscape(LRef) + '</code> (not found)' +
            ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span></li>');
      for var LRef in LN.RelatedViews do
        if (LAllIds <> nil) and not LAllIds.ContainsKey(LRef) then
          LSb.AppendLine('<li class="problem problem-orphan">' +
            '<span class="badge badge-prob-orphan">' + T('broken ref', '断裂引用') + '</span> ' +
            HtmlEscape(LN.Title) + ' '#8594' view <code>' + HtmlEscape(LRef) + '</code> (not found)' +
            ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span></li>');
      for var LRef in LN.RelatedData do
        if (LAllIds <> nil) and not LAllIds.ContainsKey(LRef) then
          LSb.AppendLine('<li class="problem problem-orphan">' +
            '<span class="badge badge-prob-orphan">' + T('broken ref', '断裂引用') + '</span> ' +
            HtmlEscape(LN.Title) + ' '#8594' data <code>' + HtmlEscape(LRef) + '</code> (not found)' +
            ' <span class="problem-tree">(' + HtmlEscape(ATreeLabel) + ')</span></li>');
    end;
  end;

  // Emit nodes whose fog_state equals AFogTarget into the current Fog Map group.
  // Captures LSb, LFoundAny, LHasFog from the enclosing scope.
  procedure EmitFogNodes(const ALabel: string; ANodes: TList<TSpecNode>;
    AFogTarget: AsWish.Models.TFogState; var LFoundAny, LHasFogOut: Boolean);
  begin
    if ANodes = nil then Exit;
    for var LN in ANodes do
      if LN.HasFogState and (LN.FogState = AFogTarget) then
      begin
        LFoundAny := True;
        LHasFogOut := True;
        LSb.AppendLine('<div class="fog-node">' +
          '<span class="problem-tree">(' + HtmlEscape(ALabel) + ')</span> ' +
          HtmlEscape(LN.Title) + ' <code>' + HtmlEscape(LN.Id) + '</code>' +
          ' <button class="btn-ticket" data-action="ticket-create"' +
          ' data-node-id="' + HtmlEscape(LN.Id) + '"' +
          ' data-node-title="' + HtmlEscape(LN.Title) + '">＋ ' + T('ticket', '开票') + '</button></div>');
      end;
  end;

begin
  LSb := TStringBuilder.Create;
  LAllIds := nil;
  try
    LSb.Append(PageHeader(T('Problems', '问题')));

    LSb.AppendLine('<style>');
    LSb.AppendLine('  .problem { list-style: none; padding: 0.4em 0.6em; margin: 0.3em 0;' +
      ' border-radius: 4px; border-left: 3px solid #dc3545; background: #fff5f5; }');
    LSb.AppendLine('  .problem-low-confidence { border-left-color: #ffc107; background: #fffdf5; }');
    LSb.AppendLine('  .problem-no-evidence { border-left-color: #17a2b8; background: #f5fdff; }');
    LSb.AppendLine('  .problem-unreviewed { border-left-color: #6c757d; background: #f8f9fa; }');
    LSb.AppendLine('  .problem-uncertain { border-left-color: #dc3545; background: #fff5f5; }');
    LSb.AppendLine('  .problem-orphan { border-left-color: #e83e8c; background: #fdf5ff; }');
    LSb.AppendLine('  .problem-fog { border-left-color: #e65100; background: #fff8f0; }');
    LSb.AppendLine('  .problem-tree { color: #6c757d; font-size: 0.85em; }');
    LSb.AppendLine('  .problem code { font-size: 0.85em; color: #495057; }');
    LSb.AppendLine('  .badge-prob-no-evidence { background: #d1ecf1; color: #0c5460; }');
    LSb.AppendLine('  .badge-prob-unreviewed { background: #e2e3e5; color: #383d41; }');
    LSb.AppendLine('  .badge-prob-orphan { background: #f5d0e8; color: #8b4572; }');
    LSb.AppendLine('  .badge-fog-misty { background: #fff3cd; color: #856404; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-fog-foggy { background: #ffe0b2; color: #e65100; font-size: 0.8em; }');
    LSb.AppendLine('  .badge-fog-unknown-unknowns { background: #455a64; color: #fff; font-size: 0.8em; }');
    LSb.AppendLine('  .fog-group { margin: 0.5em 0; }');
    LSb.AppendLine('  .fog-group-title { font-weight: 600; color: #495057; margin-bottom: 0.3em; }');
    LSb.AppendLine('  .fog-node { padding: 0.3em 0.6em; margin: 0.2em 0; border-radius: 3px; background: #f8f9fa; }');
    LSb.AppendLine('  .ticket { padding: 0.4em 0.6em; margin: 0.3em 0; border-radius: 4px;' +
      ' border-left: 3px solid #4a90e2; background: #f0f4f8; }');
    LSb.AppendLine('  .ticket code { font-size: 0.85em; color: #495057; }');
    LSb.AppendLine('  .btn-ticket { font-size: 0.8em; margin-left: 0.5em; cursor: pointer;' +
      ' background: #e3f2fd; border: 1px solid #90caf9; color: #1565c0; border-radius: 3px; }');
    LSb.AppendLine('  .btn-ticket:hover { background: #bbdefb; }');
    LSb.AppendLine('  .ticket-meta { color: #6c757d; font-size: 0.85em; margin-left: 0.5em; }');
    LSb.AppendLine('  .prob-section { margin-top: 1.5em; }');
    LSb.AppendLine('  .prob-summary { display: inline-block; margin: 0.5em 1em 0.5em 0;' +
      ' padding: 0.5em 1em; background: #f0f4f8; border-left: 3px solid #4a90e2; }');
    LSb.AppendLine('  .prob-summary strong { display: block; font-size: 1.5em; color: #4a90e2; }');
    LSb.AppendLine('</style>');

    LSb.AppendLine('<h1>' + T('Problems', '问题') + '</h1>');
    LSb.AppendLine('<p><a href="index.html">'#$2190' ' +
      T('Back to index', '返回索引') + '</a></p>');

    // Summary
    LSb.AppendLine('<h2>' + T('Summary', '汇总') + '</h2>');
    var LFC: Integer := 0; if AFuncNodes <> nil then LFC := AFuncNodes.Count;
    var LMC: Integer := 0; if AModuleNodes <> nil then LMC := AModuleNodes.Count;
    var LVC: Integer := 0; if AViewNodes <> nil then LVC := AViewNodes.Count;
    var LDC: Integer := 0; if ADataNodes <> nil then LDC := ADataNodes.Count;
    LSb.AppendLine('<div class="prob-summary"><strong>' + LFC.ToString +
      '</strong>' + T('Function nodes', '功能节点') + '</div>');
    LSb.AppendLine('<div class="prob-summary"><strong>' + LMC.ToString +
      '</strong>' + T('Module nodes', '模块节点') + '</div>');
    LSb.AppendLine('<div class="prob-summary"><strong>' + LVC.ToString +
      '</strong>' + T('View nodes', '界面节点') + '</div>');
    LSb.AppendLine('<div class="prob-summary"><strong>' + LDC.ToString +
      '</strong>' + T('Data nodes', '数据节点') + '</div>');

    // Problem list
    LSb.AppendLine('<h2>' + T('Issues', '问题列表') + '</h2>');
    LSb.AppendLine('<ul style="padding-left: 0;">');
    ScanNodes(T('Function', '功能'), AFuncNodes);
    ScanNodes(T('Module', '模块'), AModuleNodes);
    ScanNodes(T('View', '界面'), AViewNodes);
    ScanNodes(T('Data', '数据'), ADataNodes);
    LSb.AppendLine('</ul>');

    // Cross-tree consistency: detect broken cross-tree references
    LSb.AppendLine('<h2>Cross-Tree Consistency</h2>');
    // 总数复用共享 helper（DRY，与 index.html 看板一致）
    LSb.AppendLine('<p>跨树断引用共 ' +
      CountCrossTreeConflicts(AFuncNodes, AModuleNodes, AViewNodes, ADataNodes).ToString +
      ' 处：</p>');
    LAllIds := TDictionary<string, Boolean>.Create;
    try
      if AFuncNodes <> nil then for var LN in AFuncNodes do LAllIds.AddOrSetValue(LN.Id, True);
      if AModuleNodes <> nil then for var LN in AModuleNodes do LAllIds.AddOrSetValue(LN.Id, True);
      if AViewNodes <> nil then for var LN in AViewNodes do LAllIds.AddOrSetValue(LN.Id, True);
      if ADataNodes <> nil then for var LN in ADataNodes do LAllIds.AddOrSetValue(LN.Id, True);

      LSb.AppendLine('<ul style="padding-left: 0;">');
      CheckNodeRefs(T('Function', '功能'), AFuncNodes);
      CheckNodeRefs(T('Module', '模块'), AModuleNodes);
      CheckNodeRefs(T('View', '界面'), AViewNodes);
      CheckNodeRefs(T('Data', '数据'), ADataNodes);
      LSb.AppendLine('</ul>');
    finally
      LAllIds.Free;
      LAllIds := nil;
    end;

    // Fog Map: nodes grouped by fog_state (the growing/shrinking map of foggy endpoints)
    LSb.AppendLine('<h2 id="fog-map">' + T('Fog Map', '雾区地图') + '</h2>');
    LSb.AppendLine('<p>Requirement endpoints still in the fog. Converges one-way: ' +
      '<code>unknown_unknowns</code> '#8594' <code>foggy</code> '#8594' ' +
      '<code>misty</code> '#8594' <code>clear</code>. ' +
      'Resolve each via an open exploration ticket.</p>');

    var LHasFog := False;
    for var LState in [AsWish.Models.fsUnknownUnknowns,
                       AsWish.Models.fsFoggy,
                       AsWish.Models.fsMisty] do
    begin
      var LStateStr := AsWish.Models.TSpecEnums.FogStateToStr(LState);
      var LFoundAny := False;
      LSb.AppendLine('<div class="fog-group">');
      LSb.AppendLine('<div class="fog-group-title"><span class="badge badge-fog-' +
        FogStateCssClass(LState) + '">fog: ' + HtmlEscape(LStateStr) + '</span></div>');

      EmitFogNodes(T('Function', '功能'), AFuncNodes, LState, LFoundAny, LHasFog);
      EmitFogNodes(T('Module', '模块'), AModuleNodes, LState, LFoundAny, LHasFog);
      EmitFogNodes(T('View', '界面'), AViewNodes, LState, LFoundAny, LHasFog);
      EmitFogNodes(T('Data', '数据'), ADataNodes, LState, LFoundAny, LHasFog);

      LSb.AppendLine('</div>');
    end;

    if not LHasFog then
      LSb.AppendLine('<p><em>No nodes in the fog. All requirement endpoints are clear.</em></p>');

    // Open Tickets: exploration tickets persisted in issues/doc-issues.yaml.
    // Only open tickets of the four exploration types are shown here.
    LSb.AppendLine('<h2 id="open-tickets">' + T('Open Tickets', '开放 Ticket') + '</h2>');
    var LTicketCount := 0;
    if AIssues <> nil then
    begin
      for var LI in AIssues do
      begin
        if LI.Status <> AsWish.Models.issOpen then Continue;
        if not (LI.IssueType in [AsWish.Models.itResearchTicket,
                                 AsWish.Models.itPrototypeTicket,
                                 AsWish.Models.itGrillingTicket,
                                 AsWish.Models.itFogUnknown]) then Continue;
        Inc(LTicketCount);
        var LTypeStr := AsWish.Models.TSpecEnums.IssueTypeToStr(LI.IssueType);
        var LSevStr := AsWish.Models.TSpecEnums.IssueSeverityToStr(LI.Severity);
        LSb.AppendLine('<div class="ticket">' +
          '<span class="badge">' + HtmlEscape(LTypeStr) + '</span> ' +
          '<span class="badge">' + HtmlEscape(LSevStr) + '</span> ' +
          HtmlEscape(LI.Title) +
          ' <code>' + HtmlEscape(LI.Id) + '</code>');
        if Length(LI.AffectedNodes) > 0 then
        begin
          LSb.Append(' <span class="ticket-meta">affects: ');
          for var J := 0 to High(LI.AffectedNodes) do
          begin
            if J > 0 then LSb.Append(', ');
            LSb.Append('<code>' + HtmlEscape(LI.AffectedNodes[J]) + '</code>');
          end;
          LSb.AppendLine('</span>');
        end
        else
          LSb.AppendLine('');
        if LI.HasRequiresHuman then
        begin
          var LHumanity := 'AFK';
          if LI.RequiresHuman then LHumanity := 'HITL';
          LSb.AppendLine(' <span class="ticket-meta">' + LHumanity + '</span>');
        end;
        LSb.AppendLine('</div>');
      end;
    end;
    if LTicketCount = 0 then
      LSb.AppendLine('<p><em>No open exploration tickets. Open one from a fog node above.</em></p>');

    // JS Bridge: forward ticket-create button clicks to the WebView2 host.
    // Mirrors the tree-page handler. Ticket buttons are NOT greyed-out after a
    // click (a node may open multiple tickets), so the handler skips the
    // .posted swap for data-action="ticket-create".
    LSb.AppendLine('<script>');
    LSb.AppendLine('(function() {');
    LSb.AppendLine('  var hasBridge = !!(window.chrome && window.chrome.webview && window.chrome.webview.postMessage);');
    LSb.AppendLine('  document.addEventListener("click", function(e) {');
    LSb.AppendLine('    var t = e.target;');
    LSb.AppendLine('    if (!(t instanceof HTMLElement)) return;');
    LSb.AppendLine('    var action = t.getAttribute("data-action");');
    LSb.AppendLine('    if (!action) return;');
    LSb.AppendLine('    if (t.classList.contains("posted")) return;');
    LSb.AppendLine('    var msg = {');
    LSb.AppendLine('      action: action,');
    LSb.AppendLine('      node_id: t.getAttribute("data-node-id") || "",');
    LSb.AppendLine('      node_title: t.getAttribute("data-node-title") || ""');
    LSb.AppendLine('    };');
    LSb.AppendLine('    if (hasBridge) {');
    LSb.AppendLine('      try { window.chrome.webview.postMessage(JSON.stringify(msg)); }');
    LSb.AppendLine('      catch (err) { console.error("AsWish bridge:", err); return; }');
    LSb.AppendLine('      // Ticket buttons stay re-clickable; only decision buttons grey out.');
    LSb.AppendLine('      if (action !== "ticket-create") {');
    LSb.AppendLine('        t.classList.add("posted");');
    LSb.AppendLine('        t.textContent = (action === "node-confirm" ? "'#$2713' posted" : "'#$2715' posted");');
    LSb.AppendLine('      }');
    LSb.AppendLine('    } else {');
    LSb.AppendLine('      alert("AsWish bridge unavailable. Open this page inside AsWish to create tickets.");');
    LSb.AppendLine('    }');
    LSb.AppendLine('  });');
    LSb.AppendLine('})();');
    LSb.AppendLine('</script>');

    LSb.Append(PageFooter);

    TFile.WriteAllText(TPath.Combine(FBasePath, 'problems.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
  end;
end;

procedure TAsWishRenderService.RenderBundlesPage(
  ABundles: TList<TSemanticBundle>;
  AFuncNodes, AModuleNodes, AViewNodes, ADataNodes: TList<TSpecNode>);
var
  LSb: TStringBuilder;
  LAllNodes: TDictionary<string, TSpecNode>;
begin
  LAllNodes := TDictionary<string, TSpecNode>.Create;
  LSb := TStringBuilder.Create;
  try
    // Build node lookup
    if AFuncNodes <> nil then for var N in AFuncNodes do LAllNodes.AddOrSetValue(N.Id, N);
    if AModuleNodes <> nil then for var N in AModuleNodes do LAllNodes.AddOrSetValue(N.Id, N);
    if AViewNodes <> nil then for var N in AViewNodes do LAllNodes.AddOrSetValue(N.Id, N);
    if ADataNodes <> nil then for var N in ADataNodes do LAllNodes.AddOrSetValue(N.Id, N);

    LSb.Append(PageHeader(T('Semantic Bundles', '语义束')));

    LSb.AppendLine('<style>');
    LSb.AppendLine('  .bundle { margin: 1em 0; padding: 0.8em; border: 1px solid #dee2e6; border-radius: 6px; }');
    LSb.AppendLine('  .bundle-title { font-size: 1.1em; font-weight: 600; margin-bottom: 0.3em; }');
    LSb.AppendLine('  .bundle-desc { color: #6c757d; font-size: 0.9em; margin-bottom: 0.5em; }');
    LSb.AppendLine('  .bundle-nodes { list-style: none; padding-left: 0; }');
    LSb.AppendLine('  .bundle-node { padding: 0.3em 0.5em; margin: 0.2em 0; border-radius: 3px; background: #f8f9fa; }');
    LSb.AppendLine('  .bundle-actions { margin-top: 0.5em; }');
    LSb.AppendLine('  .bundle-actions button { margin-right: 0.5em; padding: 0.3em 0.8em; cursor: pointer; }');
    LSb.AppendLine('  .btn-accept-all { background: #d4edda; border-color: #c3e6cb; color: #155724; }');
    LSb.AppendLine('  .btn-reject-all { background: #f8d7da; border-color: #f5c6cb; color: #721c24; }');
    LSb.AppendLine('</style>');

    LSb.AppendLine('<h1>Semantic Bundles</h1>');
    LSb.AppendLine('<p><a href="index.html">'#$2190' Back to index</a></p>');

    if (ABundles = nil) or (ABundles.Count = 0) then
      LSb.AppendLine('<p><em>' + T('No bundles defined. Bundles group related nodes for batch review.', '未定义语义束。语义束将相关节点分组供批量审阅。') + '</em></p>')
    else
    begin
      for var I := 0 to ABundles.Count - 1 do
      begin
        var LB := ABundles[I];
        LSb.AppendLine('<div class="bundle">');
        LSb.AppendLine('<div class="bundle-title">' + HtmlEscape(LB.Title) + '</div>');
        if LB.Description <> '' then
          LSb.AppendLine('<div class="bundle-desc">' + HtmlEscape(LB.Description) + '</div>');
        LSb.AppendLine('<ul class="bundle-nodes">');

        for var NId in LB.NodeIds do
        begin
          var LNode: TSpecNode;
          if LAllNodes.TryGetValue(NId, LNode) then
            LSb.AppendLine('<li class="bundle-node">' +
              StatusBadge(AsWish.Models.TSpecEnums.NodeStatusToStr(LNode.Status)) + ' ' +
              ConfidenceBadge(AsWish.Models.TSpecEnums.ConfidenceToStr(LNode.Confidence)) + ' ' +
              HtmlEscape(LNode.Title) +
              ' <code>' + HtmlEscape(NId) + '</code></li>')
          else
            LSb.AppendLine('<li class="bundle-node" style="color:#dc3545;">' +
              HtmlEscape(NId) + ' (not found)</li>');
        end;

        LSb.AppendLine('</ul>');
        LSb.AppendLine('<div class="bundle-actions">');
        LSb.AppendLine('<button class="btn-accept-all" data-action="bundle-accept" data-bundle-id="' +
          HtmlEscape(LB.Id) + '">' + T('Accept All', '全部接受') + '</button>');
        LSb.AppendLine('<button class="btn-reject-all" data-action="bundle-reject" data-bundle-id="' +
          HtmlEscape(LB.Id) + '">' + T('Reject All', '全部拒绝') + '</button>');
        LSb.AppendLine('</div>');
        LSb.AppendLine('</div>');
      end;
    end;

    // JS Bridge for bundle actions
    LSb.AppendLine('<script>');
    LSb.AppendLine('(function() {');
    LSb.AppendLine('  var hasBridge = !!(window.chrome && window.chrome.webview && window.chrome.webview.postMessage);');
    LSb.AppendLine('  document.addEventListener("click", function(e) {');
    LSb.AppendLine('    var t = e.target;');
    LSb.AppendLine('    if (!(t instanceof HTMLElement)) return;');
    LSb.AppendLine('    var action = t.getAttribute("data-action");');
    LSb.AppendLine('    if (!action) return;');
    LSb.AppendLine('    var bundleId = t.getAttribute("data-bundle-id") || "";');
    LSb.AppendLine('    var msg = {');
    LSb.AppendLine('      action: action,');
    LSb.AppendLine('      bundle_id: bundleId');
    LSb.AppendLine('    };');
    LSb.AppendLine('    if (hasBridge) {');
    LSb.AppendLine('      try { window.chrome.webview.postMessage(JSON.stringify(msg)); }');
    LSb.AppendLine('      catch (err) { console.error("AsWish bridge:", err); return; }');
    LSb.AppendLine('      t.textContent = "posted"; t.disabled = true;');
    LSb.AppendLine('    } else {');
    LSb.AppendLine('      alert("AsWish bridge unavailable.");');
    LSb.AppendLine('    }');
    LSb.AppendLine('  });');
    LSb.AppendLine('})();');
    LSb.AppendLine('</script>');

    LSb.Append(PageFooter);

    TFile.WriteAllText(TPath.Combine(FBasePath, 'bundles.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
    LAllNodes.Free;
  end;
end;

procedure TAsWishRenderService.RenderNodeDetail(const ANode: TSpecNode);
var
  LSb: TStringBuilder;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.Append(PageHeader(ANode.Title));
    LSb.AppendLine('<p><a href="index.html">'#$2190' ' +
      T('Back to index', '返回索引') + '</a></p>');
    LSb.AppendLine('<h1>' + HtmlEscape(ANode.Title) + '</h1>');

    LSb.AppendLine('<div class="stat"><strong>' + HtmlEscape(ANode.Id) +
      '</strong>' + T('Node ID', '节点 ID') + '</div>');
    LSb.AppendLine('<div class="stat"><strong>' + HtmlEscape(
      AsWish.Models.TSpecEnums.NodeStatusToStr(ANode.Status)) +
      '</strong>' + T('Status', '状态') + '</div>');
    LSb.AppendLine('<div class="stat"><strong>' + HtmlEscape(
      AsWish.Models.TSpecEnums.ConfidenceToStr(ANode.Confidence)) +
      '</strong>' + T('Confidence', '置信度') + '</div>');

    if ANode.Summary <> '' then
    begin
      LSb.AppendLine('<h2>' + T('Summary', '摘要') + '</h2>');
      LSb.AppendLine('<p>' + HtmlEscape(ANode.Summary) + '</p>');
    end;

    if (ANode.GenStatus <> gsDraft) or (ANode.ReviewStatus <> rsUnreviewed) then
    begin
      LSb.AppendLine('<h2>' + T('Review state', '审阅状态') + '</h2>');
      LSb.AppendLine('<p><span class="badge">gen: ' + HtmlEscape(
        AsWish.Models.TSpecEnums.GenStatusToStr(ANode.GenStatus)) +
        '</span><span class="badge">rev: ' + HtmlEscape(
        AsWish.Models.TSpecEnums.ReviewStatusToStr(ANode.ReviewStatus)) +
        '</span></p>');
    end;

    if Length(ANode.SourceRefs) > 0 then
    begin
      LSb.AppendLine('<h2>' + T('Evidence', '证据') + '</h2>');
      LSb.AppendLine('<ul>');
      for var LR in ANode.SourceRefs do
        LSb.AppendLine('<li><code>' + HtmlEscape(LR.RefId) + '</code> (' +
          HtmlEscape(LR.Relevance) + ')</li>');
      LSb.AppendLine('</ul>');
    end;

    if ANode.HasFogState then
    begin
      LSb.AppendLine('<h2>' + T('Fog state', '雾状态') + '</h2>');
      LSb.AppendLine('<p>' + HtmlEscape(
        AsWish.Models.TSpecEnums.FogStateToStr(ANode.FogState)) + '</p>');
    end;

    // Natural Language intent input for this node (0-9 Standard Input)
    LSb.AppendLine('<h2>' + T('Natural Language Revision (I said)', '人类自然语言修订（我说）') + '</h2>');
    LSb.AppendLine('<div class="card card-i-said">');
    LSb.AppendLine('  <p>' + T('Express your revision intent for this node in plain natural language:', '使用自然语言提出你对该节点的修改意图：') + '</p>');
    LSb.AppendLine('  <textarea id="node-intent-input" class="form-textarea" placeholder="' +
      T('e.g., Update summary to support dark mode and keep existing settings compatible...',
        '例如：修改功能摘要，支持深色模式并保持现有配置兼容...') + '"></textarea>');
    LSb.AppendLine('  <div class="form-actions" style="margin-top: 0.8em;">');
    LSb.AppendLine('    <button class="btn-choice btn-choice-input" onclick="submitNodeIntent()">' +
      '<span class="choice-key">[9]</span> ' + T('Submit Intent for AI Interpretation', '提交意图并让 AI 生成理解') + '</button>');
    LSb.AppendLine('  </div>');
    LSb.AppendLine('</div>');

    LSb.AppendLine('<script>');
    LSb.AppendLine('  var hasBridge = !!(window.chrome && window.chrome.webview && window.chrome.webview.postMessage);');
    LSb.AppendLine('  function submitNodeIntent() {');
    LSb.AppendLine('    var txt = document.getElementById("node-intent-input").value.trim();');
    LSb.AppendLine('    if (!txt) { alert("Please enter your intent."); return; }');
    LSb.AppendLine('    if (hasBridge) {');
    LSb.AppendLine('      window.chrome.webview.postMessage(JSON.stringify({');
    LSb.AppendLine('        action: "changeset-submit",');
    LSb.AppendLine('        node_id: ' + YamlEscape(ANode.Id) + ',');
    LSb.AppendLine('        intent_text: txt');
    LSb.AppendLine('      }));');
    LSb.AppendLine('    } else {');
    LSb.AppendLine('      alert("Action: changeset-submit for " + ' + YamlEscape(ANode.Id) + ');');
    LSb.AppendLine('    }');
    LSb.AppendLine('  }');
    LSb.AppendLine('</script>');

    LSb.Append(PageFooter);
    TFile.WriteAllText(TPath.Combine(FBasePath, 'node-detail.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
  end;
end;

procedure TAsWishRenderService.RenderChangeSetReviewPage(
  const AChangeSet: TChangeSet; ANodes: TList<TSpecNode>;
  const AProjectName: string);
var
  LSb: TStringBuilder;
  LTargetTitle: string;
  I: Integer;
  LItem: TChangeItem;
  LSourceText, LSourceBadgeClass: string;
  LTreeName: string;
begin
  LTargetTitle := AChangeSet.IntentNodeId;
  if ANodes <> nil then
    for var LN in ANodes do
      if LN.Id = AChangeSet.IntentNodeId then
      begin
        LTargetTitle := LN.Title + ' (' + LN.Id + ')';
        Break;
      end;

  LSb := TStringBuilder.Create;
  try
    LSb.Append(PageHeader(T('Review AI Interpretation', '审阅 AI 理解与提议')));

    // Top navigation
    LSb.AppendLine('<div style="margin-bottom: 1.5em; display: flex; justify-content: space-between; align-items: center;">');
    LSb.AppendLine('  <a href="index.html">&#8592; ' + T('Back to Project Dashboard', '返回项目概览') + '</a>');
    LSb.AppendLine('  <span class="badge badge-doc">' + T('ChangeSet ID: ', '变更集编号：') + HtmlEscape(AChangeSet.Id) + '</span>');
    LSb.AppendLine('</div>');

    LSb.AppendLine('<h1>' + T('AI Understanding & Proposed Changes', 'AI 理解与变更提议') + '</h1>');
    LSb.AppendLine('<p style="color: #64748b; margin-top: -0.5em;">' +
      T('Review the 4-layer information model below. Only your explicit Decision can modify the Canonical Spec.',
        '请审阅下方四层信息模型。只有你的明确裁决才能写入正式规范。') + '</p>');

    // -------------------------------------------------------------
    // ① I said (我说)
    // -------------------------------------------------------------
    LSb.AppendLine('<div class="card card-i-said">');
    LSb.AppendLine('  <h2>' + T('1. I said (Your Original Intent)', '1. 我说（你的原始意图）') + '</h2>');
    LSb.AppendLine('  <div class="intent-box">');
    LSb.AppendLine('    <p class="intent-text">&ldquo;' + HtmlEscape(AChangeSet.RawUserIntent) + '&rdquo;</p>');
    LSb.AppendLine('    <div class="intent-meta">');
    LSb.AppendLine('      <span><strong>' + T('Target Node: ', '目标节点：') + '</strong><code>' + HtmlEscape(LTargetTitle) + '</code></span>');
    LSb.AppendLine('      <span><strong>' + T('Author: ', '提出方：') + '</strong>' + HtmlEscape(AChangeSet.Author) + '</span>');
    if AChangeSet.CreatedAt <> 0 then
      LSb.AppendLine('      <span><strong>' + T('Time: ', '时间：') + '</strong>' + HtmlEscape(FormatDateTime('yyyy-mm-dd hh:nn:ss', AChangeSet.CreatedAt)) + '</span>');
    LSb.AppendLine('    </div>');
    LSb.AppendLine('  </div>');
    LSb.AppendLine('</div>');

    // -------------------------------------------------------------
    // ② AI understood (AI 理解)
    // -------------------------------------------------------------
    LSb.AppendLine('<div class="card card-ai-understood">');
    LSb.AppendLine('  <h2>' + T('2. AI understood (AI Interpretation)', '2. AI 理解（意图解析与提议）') + '</h2>');
    LSb.AppendLine('  <p>' + T('Based on your intent, the AI interpreted the following structural changes. This is a proposal and has <strong>NOT</strong> modified the Canonical Spec.',
      '根据你的意图，AI 提议了以下具体变更。这是待审阅的理解提议，<strong>尚未</strong>写入正式规范。') + '</p>');
    LSb.AppendLine('</div>');

    // -------------------------------------------------------------
    // ③ Changes (准备改变什么)
    // -------------------------------------------------------------
    LSb.AppendLine('<div class="card card-changes">');
    LSb.AppendLine('  <h2>' + T('3. Changes & Affected Projections', '3. 准备改变什么（变更明细与受影响范围）') + '</h2>');

    // Changes table
    LSb.AppendLine('  <table class="changes-table">');
    LSb.AppendLine('    <thead><tr>');
    LSb.AppendLine('      <th>#</th>');
    LSb.AppendLine('      <th>' + T('Target / Tree', '目标 / 投影') + '</th>');
    LSb.AppendLine('      <th>' + T('Field', '变更字段') + '</th>');
    LSb.AppendLine('      <th>' + T('Before (Current)', '变更前 (当前)') + '</th>');
    LSb.AppendLine('      <th>' + T('After (Proposed)', '变更后 (提议)') + '</th>');
    LSb.AppendLine('      <th>' + T('Source', '来源性质') + '</th>');
    LSb.AppendLine('      <th>' + T('Reason', '提议理由') + '</th>');
    LSb.AppendLine('    </tr></thead>');
    LSb.AppendLine('    <tbody>');

    if Length(AChangeSet.Items) = 0 then
    begin
      LSb.AppendLine('    <tr><td colspan="7"><em>' + T('No change items in this ChangeSet.', '此变更集无具体变更项。') + '</em></td></tr>');
    end
    else
    begin
      for I := 0 to Length(AChangeSet.Items) - 1 do
      begin
        LItem := AChangeSet.Items[I];
        case LItem.TargetTree of
          ttFunction: LTreeName := T('Function Tree', '功能树');
          ttModule:   LTreeName := T('Module Tree', '模块树');
          ttView:     LTreeName := T('View Tree', '视图树');
          ttData:     LTreeName := T('Data Tree', '数据树');
        else
          LTreeName := 'Tree';
        end;

        case LItem.SourceType of
          cstExplicit:
          begin
            LSourceText := T('Explicitly Requested', '你明确提出');
            LSourceBadgeClass := 'badge-source-explicit';
          end;
          cstInferred:
          begin
            LSourceText := T('AI Inferred', 'AI 推断');
            LSourceBadgeClass := 'badge-source-inferred';
          end;
        else
          LSourceText := T('Uncertain / Unknown', '尚未确定');
          LSourceBadgeClass := 'badge-source-unknown';
        end;

        LSb.AppendLine('    <tr>');
        LSb.AppendLine('      <td><strong>' + IntToStr(I + 1) + '</strong></td>');
        LSb.AppendLine('      <td><code>' + HtmlEscape(LItem.TargetNodeId) + '</code><br><small style="color:#64748b;">' + HtmlEscape(LTreeName) + '</small></td>');
        LSb.AppendLine('      <td><code>' + HtmlEscape(LItem.Field) + '</code></td>');
        LSb.AppendLine('      <td><div class="diff-before">' + HtmlEscape(LItem.BeforeValue) + '</div></td>');
        LSb.AppendLine('      <td><div class="diff-after">' + HtmlEscape(LItem.AfterValue) + '</div></td>');
        LSb.AppendLine('      <td><span class="badge ' + LSourceBadgeClass + '">' + HtmlEscape(LSourceText) + '</span></td>');
        LSb.AppendLine('      <td>' + HtmlEscape(LItem.Reason) + '</td>');
        LSb.AppendLine('    </tr>');
      end;
    end;
    LSb.AppendLine('    </tbody>');
    LSb.AppendLine('  </table>');

    // Affected Projections
    if Length(AChangeSet.AffectedProjections) > 0 then
    begin
      LSb.AppendLine('  <div style="margin-top: 1em;">');
      LSb.AppendLine('    <strong>' + T('Affected Projections (via Semantic Bundles): ', '受影响投影（根据语义束计算）：') + '</strong>');
      for var LP in AChangeSet.AffectedProjections do
      begin
        case LP of
          ttFunction: LSb.AppendLine('<span class="badge badge-doc">Function</span>');
          ttModule:   LSb.AppendLine('<span class="badge badge-code">Module</span>');
          ttView:     LSb.AppendLine('<span class="badge badge-ui">View</span>');
          ttData:     LSb.AppendLine('<span class="badge badge-config">Data</span>');
        end;
      end;
      LSb.AppendLine('  </div>');
    end;
    LSb.AppendLine('</div>');

    // -------------------------------------------------------------
    // ④ Decision & 0–9 Action Surface (你是否同意这个理解)
    // -------------------------------------------------------------
    LSb.AppendLine('<div class="card card-decision">');
    LSb.AppendLine('  <h2>' + T('4. Decision (0–9 Universal Choice)', '4. 你的裁决（0–9 统一选择交互）') + '</h2>');
    LSb.AppendLine('  <p>' + T('Choose your decision below using mouse or press number keys (1–4, 8, 9, 0):', '使用鼠标点击或按键盘数字键 (1–4, 8, 9, 0) 作出裁决：') + '</p>');

    LSb.AppendLine('  <div class="choice-container">');

    // 1: Accept
    LSb.AppendLine('    <button id="btn-1" class="btn-choice btn-choice-opt btn-choice-rec" onclick="doAccept()">');
    LSb.AppendLine('      <span class="choice-key">[1]</span> ' + T('Accept this interpretation and apply to Canonical Spec', '接受这个理解并写入规范 (Accept)') + ' <span class="rec-badge">' + T('Recommended', '推荐') + '</span>');
    LSb.AppendLine('    </button>');

    // 2: Itemized review
    LSb.AppendLine('    <button id="btn-2" class="btn-choice btn-choice-opt" onclick="toggleItemized()">');
    LSb.AppendLine('      <span class="choice-key">[2]</span> ' + T('Itemized review (Confirm each change item individually)', '逐项分项确认 (Itemized Review)') + '');
    LSb.AppendLine('    </button>');

    // 3: Clarify
    LSb.AppendLine('    <button id="btn-3" class="btn-choice btn-choice-opt" onclick="toggleClarifyForm()">');
    LSb.AppendLine('      <span class="choice-key">[3]</span> ' + T('Refine detail / Request clarification before accept (Clarify)', '修改细节 / 补充说明后接受 (Clarify)') + '');
    LSb.AppendLine('    </button>');

    // 4: Reject
    LSb.AppendLine('    <button id="btn-4" class="btn-choice btn-choice-opt btn-choice-danger" onclick="doReject()">');
    LSb.AppendLine('      <span class="choice-key">[4]</span> ' + T('Reject this interpretation (Canonical Spec remains untouched)', '拒绝这个理解 (Reject，规范保持不变)') + '');
    LSb.AppendLine('    </button>');

    // Divider
    LSb.AppendLine('    <div class="choice-divider"></div>');

    // 8: Regenerate
    LSb.AppendLine('    <button id="btn-8" class="btn-choice btn-choice-regen" onclick="doRegenerate()">');
    LSb.AppendLine('      <span class="choice-key">[8]</span> ' + T('Regenerate interpretation (AI re-interprets intent, not a Decision)', '让 AI 重新生成理解 (Regenerate，非决策)') + '');
    LSb.AppendLine('    </button>');

    // 9: Human override
    LSb.AppendLine('    <button id="btn-9" class="btn-choice btn-choice-input" onclick="toggleEscapeHatch()">');
    LSb.AppendLine('      <span class="choice-key">[9]</span> ' + T('Describe myself / New natural language (Escape Hatch)', '我自己说明 / 输入新意图 (Escape Hatch)') + '');
    LSb.AppendLine('    </button>');

    // 0: Back
    LSb.AppendLine('    <button id="btn-0" class="btn-choice btn-choice-back" onclick="doBack()">');
    LSb.AppendLine('      <span class="choice-key">[0]</span> ' + T('Back to Dashboard (Navigation only, does NOT reject)', '返回上一步 (Back，纯导航不裁决)') + '');
    LSb.AppendLine('    </button>');

    LSb.AppendLine('  </div>');

    // Clarify inline form
    LSb.AppendLine('  <div id="clarify-panel" class="form-panel" style="display:none;">');
    LSb.AppendLine('    <h3>' + T('Clarification & Detail Refinement', '补充细节与澄清说明') + '</h3>');
    LSb.AppendLine('    <p style="color:#64748b;">' + T('Describe what specific adjustment you want AI to take into account:', '请填写你想调整或补充的具体细节：') + '</p>');
    LSb.AppendLine('    <textarea id="clarify-input" class="form-textarea" placeholder="' + T('e.g., Only enable dark mode for main dashboard, keep sidebar theme unchanged...', '例如：仅对主仪表盘启用深色模式，侧边栏保持不变...') + '"></textarea>');
    LSb.AppendLine('    <div class="form-actions">');
    LSb.AppendLine('      <button class="btn-primary" onclick="submitClarify()">' + T('Submit Clarification', '提交澄清') + '</button>');
    LSb.AppendLine('      <button class="btn-secondary" onclick="toggleClarifyForm()">' + T('Cancel', '取消') + '</button>');
    LSb.AppendLine('    </div>');
    LSb.AppendLine('  </div>');

    // Escape hatch inline form
    LSb.AppendLine('  <div id="escape-panel" class="form-panel" style="display:none;">');
    LSb.AppendLine('    <h3>' + T('New Intent (Human Override)', '输入新意图（人类自主表达）') + '</h3>');
    LSb.AppendLine('    <textarea id="new-intent-input" class="form-textarea" placeholder="' + T('Type your revision intent in natural language...', '使用自然语言输入新的意图...') + '"></textarea>');
    LSb.AppendLine('    <div class="form-actions">');
    LSb.AppendLine('      <button class="btn-primary" onclick="submitNewIntent()">' + T('Submit New Intent', '提交新意图') + '</button>');
    LSb.AppendLine('      <button class="btn-secondary" onclick="toggleEscapeHatch()">' + T('Cancel', '取消') + '</button>');
    LSb.AppendLine('    </div>');
    LSb.AppendLine('  </div>');

    // Status banner
    LSb.AppendLine('  <div id="status-banner" class="status-banner" style="display:none;"></div>');
    LSb.AppendLine('</div>');

    // Embedded JavaScript
    LSb.AppendLine('<script>');
    LSb.AppendLine('  var changeSetId = ' + YamlEscape(AChangeSet.Id) + ';');
    LSb.AppendLine('  var targetNodeId = ' + YamlEscape(AChangeSet.IntentNodeId) + ';');
    LSb.AppendLine('  var rawIntent = ' + YamlEscape(AChangeSet.RawUserIntent) + ';');
    LSb.AppendLine('  var hasBridge = !!(window.chrome && window.chrome.webview && window.chrome.webview.postMessage);');
    LSb.AppendLine('');
    LSb.AppendLine('  function post(msg) {');
    LSb.AppendLine('    if (hasBridge) {');
    LSb.AppendLine('      try { window.chrome.webview.postMessage(JSON.stringify(msg)); }');
    LSb.AppendLine('      catch (e) { console.error(e); }');
    LSb.AppendLine('    } else {');
    LSb.AppendLine('      alert("Action: " + msg.action + " (WebView2 bridge offline)");');
    LSb.AppendLine('    }');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function doAccept() {');
    LSb.AppendLine('    post({ action: "changeset-accept", changeset_id: changeSetId, rationale: "Accepted via Review UI" });');
    LSb.AppendLine('    showBanner("Accept decision recorded. Applying to Canonical Spec...", "success");');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function doReject() {');
    LSb.AppendLine('    post({ action: "changeset-reject", changeset_id: changeSetId, rationale: "Rejected via Review UI" });');
    LSb.AppendLine('    showBanner("Reject decision recorded. Canonical Spec remains untouched.", "danger");');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function toggleClarifyForm() {');
    LSb.AppendLine('    var p = document.getElementById("clarify-panel");');
    LSb.AppendLine('    p.style.display = (p.style.display === "none") ? "block" : "none";');
    LSb.AppendLine('    if (p.style.display === "block") { document.getElementById("clarify-input").focus(); }');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function submitClarify() {');
    LSb.AppendLine('    var val = document.getElementById("clarify-input").value.trim();');
    LSb.AppendLine('    if (!val) { alert("Please enter clarification text."); return; }');
    LSb.AppendLine('    post({ action: "changeset-clarify", changeset_id: changeSetId, clarification: val });');
    LSb.AppendLine('    showBanner("Clarification recorded. Canonical Spec remains untouched.", "info");');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function doRegenerate() {');
    LSb.AppendLine('    post({ action: "changeset-regenerate", node_id: targetNodeId, intent_text: rawIntent });');
    LSb.AppendLine('    showBanner("Re-generating interpretation with AI...", "info");');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function toggleEscapeHatch() {');
    LSb.AppendLine('    var p = document.getElementById("escape-panel");');
    LSb.AppendLine('    p.style.display = (p.style.display === "none") ? "block" : "none";');
    LSb.AppendLine('    if (p.style.display === "block") { document.getElementById("new-intent-input").focus(); }');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function submitNewIntent() {');
    LSb.AppendLine('    var val = document.getElementById("new-intent-input").value.trim();');
    LSb.AppendLine('    if (!val) { alert("Please enter your intent."); return; }');
    LSb.AppendLine('    post({ action: "changeset-submit", node_id: targetNodeId, intent_text: val });');
    LSb.AppendLine('    showBanner("Submitted new intent. Interpreting...", "info");');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function doBack() {');
    LSb.AppendLine('    window.location.href = "index.html";');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function toggleItemized() {');
    LSb.AppendLine('    alert("All change items are displayed in the table above with Before/After details.");');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  function showBanner(text, type) {');
    LSb.AppendLine('    var b = document.getElementById("status-banner");');
    LSb.AppendLine('    b.className = "status-banner status-" + type;');
    LSb.AppendLine('    b.innerHTML = text;');
    LSb.AppendLine('    b.style.display = "block";');
    LSb.AppendLine('  }');
    LSb.AppendLine('');
    LSb.AppendLine('  // Keyboard shortcuts for 0..9 standard');
    LSb.AppendLine('  document.addEventListener("keydown", function(e) {');
    LSb.AppendLine('    var tag = (e.target && e.target.tagName) ? e.target.tagName.toUpperCase() : "";');
    LSb.AppendLine('    if (tag === "INPUT" || tag === "TEXTAREA") return;');
    LSb.AppendLine('    switch(e.key) {');
    LSb.AppendLine('      case "1": doAccept(); break;');
    LSb.AppendLine('      case "2": toggleItemized(); break;');
    LSb.AppendLine('      case "3": toggleClarifyForm(); break;');
    LSb.AppendLine('      case "4": doReject(); break;');
    LSb.AppendLine('      case "8": doRegenerate(); break;');
    LSb.AppendLine('      case "9": toggleEscapeHatch(); break;');
    LSb.AppendLine('      case "0": doBack(); break;');
    LSb.AppendLine('    }');
    LSb.AppendLine('  });');
    LSb.AppendLine('</script>');

    LSb.Append(PageFooter);

    TFile.WriteAllText(TPath.Combine(FBasePath, 'changeset-review.html'),
      LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
  end;
end;

class function TAsWishRenderService.ComputeHealthMetrics(AFunc, AModule, AView,
  AData: TList<TSpecNode>; AIssues: TList<TSpecIssue>): THealthMetrics;
var
  LConfSum: Double;
  LCount: Integer;
  LI: TSpecIssue;

  procedure Scan(ANodes: TList<TSpecNode>);
  var
    LN2: TSpecNode;
    LCV: Double;
  begin
    if ANodes = nil then Exit;
    for LN2 in ANodes do
    begin
      Inc(Result.TotalNodes);
      case LN2.Confidence of
        clLow:    LCV := 0.3;
        clMedium: LCV := 0.7;
        clHigh:   LCV := 1.0;
      else
        LCV := 0.7;
      end;
      LConfSum := LConfSum + LCV;
      Inc(LCount);
      if LN2.GenStatus = gsConfirmed then
        Inc(Result.ConfirmedNodes);
      if LN2.HasFogState and (LN2.FogState <> fsClear) then
        Inc(Result.FogCount);
    end;
  end;

begin
  Result := Default(THealthMetrics);
  LConfSum := 0; LCount := 0;
  Scan(AFunc);
  Scan(AModule);
  Scan(AView);
  Scan(AData);
  if LCount > 0 then
    Result.AvgConfidence := LConfSum / LCount;
  if Result.TotalNodes > 0 then
    Result.CoveragePct := (Result.ConfirmedNodes / Result.TotalNodes) * 100.0;
  if AIssues <> nil then
    for LI in AIssues do
    begin
      if LI.Status = issOpen then
      begin
        Inc(Result.DecisionBacklog);
        if (LI.Severity = isCritical) or (LI.Severity = isHigh) then
          Inc(Result.HighRiskOpen);
      end;
    end;
end;

class function TAsWishRenderService.CountCrossTreeConflicts(AFunc, AModule,
  AView, AData: TList<TSpecNode>): Integer;
var
  LAllIds: TDictionary<string, Boolean>;

  procedure ScanRefs(ANodes: TList<TSpecNode>);
  var
    LN: TSpecNode;
    LRef: string;
  begin
    if ANodes = nil then Exit;
    for LN in ANodes do
    begin
      for LRef in LN.RelatedModules do
        if not LAllIds.ContainsKey(LRef) then Inc(Result);
      for LRef in LN.RelatedViews do
        if not LAllIds.ContainsKey(LRef) then Inc(Result);
      for LRef in LN.RelatedData do
        if not LAllIds.ContainsKey(LRef) then Inc(Result);
    end;
  end;

var
  LN: TSpecNode;
begin
  Result := 0;
  LAllIds := TDictionary<string, Boolean>.Create;
  try
    if AFunc   <> nil then for LN in AFunc   do LAllIds.AddOrSetValue(LN.Id, True);
    if AModule <> nil then for LN in AModule do LAllIds.AddOrSetValue(LN.Id, True);
    if AView   <> nil then for LN in AView   do LAllIds.AddOrSetValue(LN.Id, True);
    if AData   <> nil then for LN in AData   do LAllIds.AddOrSetValue(LN.Id, True);
    ScanRefs(AFunc);
    ScanRefs(AModule);
    ScanRefs(AView);
    ScanRefs(AData);
  finally
    LAllIds.Free;
  end;
end;

end.
