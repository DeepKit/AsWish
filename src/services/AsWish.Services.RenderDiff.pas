unit AsWish.Services.RenderDiff;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  AsWish.Models;

type
  TAsWishDiffRenderHelper = class
  private
    class function HtmlEscape(const S: string): string; static;
    class function T(const ALocale, AEn, AZh: string): string; static;
  public
    class procedure RenderDifferencePage(const ABasePath, ALocale: string;
      const AReport: TSpecDifferenceReport; const AProjectName: string = ''); static;
    class procedure RenderDecisionsPage(const ABasePath, ALocale: string;
      const ADecisions: TArray<TSpecDecision>; const AProjectName: string = ''); static;
  end;

implementation

class function TAsWishDiffRenderHelper.HtmlEscape(const S: string): string;
begin
  Result := S
    .Replace('&', '&amp;')
    .Replace('<', '&lt;')
    .Replace('>', '&gt;')
    .Replace('"', '&quot;');
end;

class function TAsWishDiffRenderHelper.T(const ALocale, AEn, AZh: string): string;
begin
  if ALocale = 'zh-CN' then
    Result := AZh
  else
    Result := AEn;
end;

class procedure TAsWishDiffRenderHelper.RenderDifferencePage(
  const ABasePath, ALocale: string; const AReport: TSpecDifferenceReport;
  const AProjectName: string);
var
  LSb: TStringBuilder;
  LItem: TSpecDifferenceItem;
  LTitle, LProj, LKindStr, LAspectStr: string;
begin
  LSb := TStringBuilder.Create;
  try
    LTitle := T(ALocale, 'Structural Difference & Judgment', '结构差异与裁决');
    LProj := AProjectName;
    if LProj = '' then LProj := 'Project';

    LSb.AppendLine('<!DOCTYPE html>');
    LSb.AppendLine('<html><head><meta charset="UTF-8">');
    LSb.AppendLine('<title>' + HtmlEscape(LTitle) + ' - AsWish</title>');
    LSb.AppendLine('<style>');
    LSb.AppendLine('  body { font-family: -apple-system, "Segoe UI", sans-serif; margin: 2em; color: #1e293b; background: #ffffff; }');
    LSb.AppendLine('  h1 { border-bottom: 2px solid #4a90e2; padding-bottom: 0.5em; color: #1e293b; }');
    LSb.AppendLine('  .card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 1.2em; margin-bottom: 1.2em; }');
    LSb.AppendLine('  .meta-tag { display: inline-block; background: #e2e8f0; padding: 0.3em 0.8em; border-radius: 4px; margin-right: 1em; font-size: 0.9em; }');
    LSb.AppendLine('  table { width: 100%; border-collapse: collapse; margin-top: 1em; }');
    LSb.AppendLine('  th, td { border: 1px solid #cbd5e1; padding: 0.6em 0.8em; text-align: left; }');
    LSb.AppendLine('  th { background: #f1f5f9; }');
    LSb.AppendLine('  .kind-missing { color: #dc2626; font-weight: bold; }');
    LSb.AppendLine('  .kind-extra { color: #2563eb; font-weight: bold; }');
    LSb.AppendLine('  .kind-changed { color: #d97706; font-weight: bold; }');
    LSb.AppendLine('  .actions { margin-top: 1.5em; display: flex; gap: 1em; align-items: center; }');
    LSb.AppendLine('  .btn { padding: 0.6em 1.2em; border: none; border-radius: 6px; font-weight: 600; cursor: pointer; }');
    LSb.AppendLine('  .btn-accept { background: #16a34a; color: white; }');
    LSb.AppendLine('  .btn-reject { background: #dc2626; color: white; }');
    LSb.AppendLine('  .btn-evolve { background: #2563eb; color: white; }');
    LSb.AppendLine('  .rationale-input { width: 100%; height: 60px; padding: 0.5em; margin-top: 0.5em; border: 1px solid #cbd5e1; border-radius: 4px; }');
    LSb.AppendLine('</style></head><body>');

    LSb.AppendLine('<h1>' + HtmlEscape(LTitle) + ': ' + HtmlEscape(LProj) + '</h1>');
    LSb.AppendLine('<p><a href="index.html">&larr; ' + T(ALocale, 'Back to Index', '返回首页') + '</a> | <a href="decisions.html">' + T(ALocale, 'Decisions History', '决策历史留痕') + '</a></p>');

    LSb.AppendLine('<div class="card">');
    LSb.AppendLine('  <span class="meta-tag"><strong>Baseline:</strong> ' + HtmlEscape(AReport.BaselineId) + '</span>');
    LSb.AppendLine('  <span class="meta-tag"><strong>Tree:</strong> ' + HtmlEscape(AReport.TreeType) + '</span>');
    LSb.AppendLine('  <span class="meta-tag"><strong>Differences:</strong> ' + IntToStr(Length(AReport.Items)) + '</span>');
    LSb.AppendLine('</div>');

    if Length(AReport.Items) = 0 then
    begin
      LSb.AppendLine('<div class="card"><p style="color: #16a34a; font-weight: 600;">' +
        T(ALocale, 'No structural differences detected between baseline and current implementation reality.',
                   '基线与当前实现完全一致，未发现结构差异。') + '</p></div>');
    end
    else
    begin
      LSb.AppendLine('<table>');
      LSb.AppendLine('  <tr><th>Kind</th><th>Aspect</th><th>Node ID</th><th>Baseline Hash</th><th>Evidence Hash</th></tr>');
      for LItem in AReport.Items do
      begin
        LKindStr := TSpecEnums.DifferenceKindToStr(LItem.Kind);
        LAspectStr := '';
        if LItem.Kind = dkChanged then
          LAspectStr := TSpecEnums.DifferenceAspectToStr(LItem.ChangedAspect);

        LSb.AppendLine('  <tr>');
        LSb.AppendLine('    <td class="kind-' + LKindStr.ToLower + '">' + HtmlEscape(LKindStr) + '</td>');
        LSb.AppendLine('    <td>' + HtmlEscape(LAspectStr) + '</td>');
        LSb.AppendLine('    <td><code>' + HtmlEscape(LItem.NodeId) + '</code></td>');
        LSb.AppendLine('    <td><code>' + HtmlEscape(Copy(LItem.BaselineHash, 1, 12)) + '</code></td>');
        LSb.AppendLine('    <td><code>' + HtmlEscape(Copy(LItem.EvidenceHash, 1, 12)) + '</code></td>');
        LSb.AppendLine('  </tr>');
      end;
      LSb.AppendLine('</table>');

      LSb.AppendLine('<div class="card" style="margin-top: 1.5em;">');
      LSb.AppendLine('  <h3>' + T(ALocale, 'Human Judgment Decision', '人类裁决') + '</h3>');
      LSb.AppendLine('  <label><strong>Rationale / Reason:</strong></label>');
      LSb.AppendLine('  <textarea id="rationale" class="rationale-input" placeholder="' +
        T(ALocale, 'Enter rationale for acceptable / unacceptable judgment...', '输入裁决理由...') + '"></textarea>');
      LSb.AppendLine('  <div class="actions">');
      LSb.AppendLine('    <button class="btn btn-accept" onclick="doJudge(''acceptable'')">' +
        T(ALocale, 'Accept Difference', '接受差异 (Accept)') + '</button>');
      LSb.AppendLine('    <button class="btn btn-reject" onclick="doJudge(''unacceptable'')">' +
        T(ALocale, 'Reject Difference (Unacceptable)', '拒绝差异 (Unacceptable)') + '</button>');
      LSb.AppendLine('    <button class="btn btn-evolve" onclick="doEvolve()">' +
        T(ALocale, 'Evolve Baseline from Reality', '基线演进 (Evolve)') + '</button>');
      LSb.AppendLine('  </div>');
      LSb.AppendLine('</div>');
    end;

    // JavaScript bridge
    LSb.AppendLine('<script>');
    LSb.AppendLine('  var baseId = "' + AReport.BaselineId + '";');
    LSb.AppendLine('  function post(msg) {');
    LSb.AppendLine('    if (window.chrome && window.chrome.webview) {');
    LSb.AppendLine('      window.chrome.webview.postMessage(JSON.stringify(msg));');
    LSb.AppendLine('    } else {');
    LSb.AppendLine('      alert("Action: " + msg.action + " / " + (msg.judge_action || ""));');
    LSb.AppendLine('    }');
    LSb.AppendLine('  }');
    LSb.AppendLine('  function doJudge(action) {');
    LSb.AppendLine('    var r = document.getElementById("rationale").value.trim();');
    LSb.AppendLine('    post({ action: "difference-judge", baseline_id: baseId, judge_action: action, rationale: r });');
    LSb.AppendLine('  }');
    LSb.AppendLine('  function doEvolve() {');
    LSb.AppendLine('    var r = document.getElementById("rationale").value.trim();');
    LSb.AppendLine('    post({ action: "baseline-evolve", baseline_id: baseId, rationale: r });');
    LSb.AppendLine('  }');
    LSb.AppendLine('</script>');

    LSb.AppendLine('</body></html>');

    TFile.WriteAllText(TPath.Combine(ABasePath, 'difference.html'), LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
  end;
end;

class procedure TAsWishDiffRenderHelper.RenderDecisionsPage(
  const ABasePath, ALocale: string; const ADecisions: TArray<TSpecDecision>;
  const AProjectName: string);
var
  LSb: TStringBuilder;
  LDec: TSpecDecision;
  LTitle, LProj, LTypeStr, LStatusStr, LTargets: string;
begin
  LSb := TStringBuilder.Create;
  try
    LTitle := T(ALocale, 'Requirement Decisions History', '需求决策历史留痕');
    LProj := AProjectName;
    if LProj = '' then LProj := 'Project';

    LSb.AppendLine('<!DOCTYPE html>');
    LSb.AppendLine('<html><head><meta charset="UTF-8">');
    LSb.AppendLine('<title>' + HtmlEscape(LTitle) + ' - AsWish</title>');
    LSb.AppendLine('<style>');
    LSb.AppendLine('  body { font-family: -apple-system, "Segoe UI", sans-serif; margin: 2em; color: #1e293b; background: #ffffff; }');
    LSb.AppendLine('  h1 { border-bottom: 2px solid #4a90e2; padding-bottom: 0.5em; color: #1e293b; }');
    LSb.AppendLine('  table { width: 100%; border-collapse: collapse; margin-top: 1em; }');
    LSb.AppendLine('  th, td { border: 1px solid #cbd5e1; padding: 0.6em 0.8em; text-align: left; }');
    LSb.AppendLine('  th { background: #f1f5f9; }');
    LSb.AppendLine('  .badge { display: inline-block; padding: 0.2em 0.6em; border-radius: 4px; font-size: 0.85em; font-weight: bold; }');
    LSb.AppendLine('  .badge-accepted { background: #dcfce7; color: #166534; }');
    LSb.AppendLine('  .badge-rejected { background: #fee2e2; color: #991b1b; }');
    LSb.AppendLine('  .badge-pending  { background: #fef3c7; color: #92400e; }');
    LSb.AppendLine('</style></head><body>');

    LSb.AppendLine('<h1>' + HtmlEscape(LTitle) + ': ' + HtmlEscape(LProj) + '</h1>');
    LSb.AppendLine('<p><a href="index.html">&larr; ' + T(ALocale, 'Back to Index', '返回首页') + '</a> | <a href="difference.html">' + T(ALocale, 'View Difference', '查看差异') + '</a></p>');

    if Length(ADecisions) = 0 then
    begin
      LSb.AppendLine('<p><em>' + T(ALocale, 'No decisions recorded yet.', '暂无决策记录。') + '</em></p>');
    end
    else
    begin
      LSb.AppendLine('<table>');
      LSb.AppendLine('  <tr><th>ID</th><th>Type</th><th>Status</th><th>ChangeSet</th><th>Title</th><th>Rationale</th><th>Target Nodes</th><th>Date</th></tr>');
      for LDec in ADecisions do
      begin
        LTypeStr := TSpecEnums.DecisionTypeToStr(LDec.DecisionType);
        LStatusStr := TSpecEnums.DecisionStatusToStr(LDec.Status);
        LTargets := string.Join(', ', LDec.TargetNodes);

        LSb.AppendLine('  <tr>');
        LSb.AppendLine('    <td><strong><code>' + HtmlEscape(LDec.Id) + '</code></strong></td>');
        LSb.AppendLine('    <td>' + HtmlEscape(LTypeStr) + '</td>');
        LSb.AppendLine('    <td><span class="badge badge-' + LStatusStr.ToLower + '">' + HtmlEscape(LStatusStr) + '</span></td>');
        LSb.AppendLine('    <td><code>' + HtmlEscape(LDec.ChangeSetId) + '</code></td>');
        LSb.AppendLine('    <td>' + HtmlEscape(LDec.Title) + '</td>');
        LSb.AppendLine('    <td>' + HtmlEscape(LDec.Rationale) + '</td>');
        LSb.AppendLine('    <td><small>' + HtmlEscape(LTargets) + '</small></td>');
        LSb.AppendLine('    <td><small>' + HtmlEscape(DateToISO8601(LDec.CreatedAt, False)) + '</small></td>');
        LSb.AppendLine('  </tr>');
      end;
      LSb.AppendLine('</table>');
    end;

    LSb.AppendLine('</body></html>');

    TFile.WriteAllText(TPath.Combine(ABasePath, 'decisions.html'), LSb.ToString, TEncoding.UTF8);
  finally
    LSb.Free;
  end;
end;

end.
