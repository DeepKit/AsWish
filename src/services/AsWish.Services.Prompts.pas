
{ ============================================================================
  AsWish.Services.Prompts

  Generates LLM prompts: Context Pack, A→B generation, node review,
  decision write-back. Outputs to .AsWish/prompts/.
  ============================================================================ }

unit AsWish.Services.Prompts;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.Scan;

type
  TAsWishPromptService = class(TInterfacedObject)
  private
    FBasePath: string;
    procedure WritePromptFile(const ARelPath, AContent: string);
  public
    procedure Initialize(const AAsWishPath: string);
    procedure WriteContextPack(AScan: TAsWishScanService;
      const AProjectName, AProjectType: string);
    procedure WriteGenerationPrompt(const AProjectName, AProjectType: string);
    procedure WriteNodePrompt(const ANode: TSpecNode);
    procedure WriteDecisionRewritePrompt(const ADecisions: TList<TSpecDecision>);
    /// <summary>Write a user-facing grill-me clarification prompt for one
    ///  grilling_ticket. Returns the absolute output path; returns an empty
    ///  string for non-grilling issues.</summary>
    function WriteGrillingPrompt(const AIssue: TSpecIssue;
      const ANodes: TList<TSpecNode>): string;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils;

procedure TAsWishPromptService.Initialize(const AAsWishPath: string);
begin
  FBasePath := TPath.Combine(AAsWishPath, 'prompts');
  if not TDirectory.Exists(FBasePath) then
    TDirectory.CreateDirectory(FBasePath);
end;

procedure TAsWishPromptService.WritePromptFile(const ARelPath, AContent: string);
begin
  TFile.WriteAllText(TPath.Combine(FBasePath, ARelPath), AContent, TEncoding.UTF8);
end;

procedure TAsWishPromptService.WriteContextPack(AScan: TAsWishScanService;
  const AProjectName, AProjectType: string);
var
  LSb: TStringBuilder;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# Context Pack');
    LSb.AppendLine('');
    LSb.AppendLine('## 1. Project');
    LSb.AppendLine('');
    LSb.AppendLine('- Name: ' + AProjectName);
    LSb.AppendLine('- Type: ' + AProjectType);
    LSb.AppendLine('- Scan time: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    LSb.AppendLine('');
    LSb.AppendLine('## 2. File Statistics');
    LSb.AppendLine('');
    LSb.AppendLine('| Category | Count |');
    LSb.AppendLine('|----------|-------|');
    LSb.AppendLine(Format('| Documents | %d |', [AScan.CategoryCount(fcDocuments)]));
    LSb.AppendLine(Format('| Code | %d |', [AScan.CategoryCount(fcCode)]));
    LSb.AppendLine(Format('| UI | %d |', [AScan.CategoryCount(fcUI)]));
    LSb.AppendLine(Format('| Config | %d |', [AScan.CategoryCount(fcConfig)]));
    LSb.AppendLine(Format('| AI Rules | %d |', [AScan.CategoryCount(fcAiRules)]));
    LSb.AppendLine(Format('| Total | %d |', [AScan.TotalFiles]));
    LSb.AppendLine('');

    LSb.AppendLine('## 3. Key Documents');
    LSb.AppendLine('');
    var LDocCount := 0;
    for var LFile in AScan.GetFilesByCategory(fcDocuments) do
    begin
      if LDocCount >= 20 then
      begin
        LSb.AppendLine('- ... (truncated)');
        Break;
      end;
      LSb.AppendLine('- ' + LFile);
      Inc(LDocCount);
    end;
    LSb.AppendLine('');

    LSb.AppendLine('## 4. AI Rules Files');
    LSb.AppendLine('');
    for var LFile in AScan.GetFilesByCategory(fcAiRules) do
      LSb.AppendLine('- ' + LFile);
    LSb.AppendLine('');

    LSb.AppendLine('## 5. Code Structure (sample)');
    LSb.AppendLine('');
    var LCodeCount := 0;
    for var LFile in AScan.GetFilesByCategory(fcCode) do
    begin
      if LCodeCount >= 30 then
      begin
        LSb.AppendLine('- ... (truncated)');
        Break;
      end;
      LSb.AppendLine('- ' + LFile);
      Inc(LCodeCount);
    end;
    LSb.AppendLine('');

    LSb.AppendLine('## 6. Task');
    LSb.AppendLine('');
    LSb.AppendLine('Read the project material above and generate or update the AsWish B (specification facts).');
    LSb.AppendLine('');
    LSb.AppendLine('Required outputs (as YAML documents in ONE response stream — see §8):');
    LSb.AppendLine('- `trees/function-tree.yaml` - what the software does');
    LSb.AppendLine('- `trees/module-tree.yaml` - how it is structured');
    LSb.AppendLine('- `trees/view-tree.yaml` - what users see');
    LSb.AppendLine('- `trees/data-tree.yaml` - what data exists and persists');
    LSb.AppendLine('- `evidence/source-evidence.yaml` - traceable evidence for each node');
    LSb.AppendLine('- `issues/doc-issues.yaml` - gaps, conflicts, ambiguities');
    LSb.AppendLine('');
    LSb.AppendLine('The function-tree is the priority: its root node arrives as a fog stub');
    LSb.AppendLine('(`fog_state: unknown_unknowns`) awaiting your semantic content. Replacing');
    LSb.AppendLine('the stub summary with real capability semantics clears the fog.');
    LSb.AppendLine('');

    LSb.AppendLine('## 7. Constraints');
    LSb.AppendLine('');
    LSb.AppendLine('- Follow the AsWish Protocol v1.2-draft schema strictly.');
    LSb.AppendLine('- Use English snake_case for enum values (e.g., `ai_inferred`, not `B:AI推断`).');
    LSb.AppendLine('- Mark all AI-generated content with `status: candidate` and `source_layer: ai_inferred`.');
    LSb.AppendLine('- Do NOT set `decided_by: human` - that is reserved for AsWish UI writes.');
    LSb.AppendLine('- Do NOT set `review_status` to anything other than `unreviewed` (review is a human action).');
    LSb.AppendLine('- Do NOT set `gen_status: confirmed` (confirmation is a human action); use `generated`.');
    LSb.AppendLine('- Node `id` must match its tree prefix: `func-`/`mod-`/`view-`/`data-`.');
    LSb.AppendLine('- `parent_id` must reference a node that exists in the live tree or the same response.');
    LSb.AppendLine('- Provide `source_refs` for every node tracing back to a file or doc.');
    LSb.AppendLine('- Do not modify any files outside `.AsWish/`.');
    LSb.AppendLine('');

    LSb.AppendLine('## 8. Output Format');
    LSb.AppendLine('');
    LSb.AppendLine('Return ALL outputs as a single YAML multi-document stream in your text');
    LSb.AppendLine('response. Separate documents with a line containing only `---`. Each');
    LSb.AppendLine('document begins with a `# file:` comment naming its target path, then');
    LSb.AppendLine('`version: "1.0"` and the tree/evidence/issues body. Do NOT wrap output');
    LSb.AppendLine('in Markdown code fences. Do NOT write to the filesystem yourself — the');
    LSb.AppendLine('harness saves your full response to `llm/candidate-output.yaml` and parses it.');
    LSb.AppendLine('');
    LSb.AppendLine('Example skeleton (abbreviated — follow the full schema for real content):');
    LSb.AppendLine('');
    LSb.AppendLine('---');
    LSb.AppendLine('# file: trees/function-tree.yaml');
    LSb.AppendLine('version: "1.0"');
    LSb.AppendLine('tree: function');
    LSb.AppendLine('nodes:');
    LSb.AppendLine('  - id: func-myservice');
    LSb.AppendLine('    kind: capability');
    LSb.AppendLine('    summary: Real semantic summary replacing the stub...');
    LSb.AppendLine('    status: candidate');
    LSb.AppendLine('    gen_status: generated');
    LSb.AppendLine('    review_status: unreviewed');
    LSb.AppendLine('    source_layer: ai_inferred');
    LSb.AppendLine('    fog_state: foggy');
    LSb.AppendLine('    source_refs:');
    LSb.AppendLine('      - ref_id: src:cmd/main.go');
    LSb.AppendLine('        relevance: primary');
    LSb.AppendLine('---');
    LSb.AppendLine('# file: trees/module-tree.yaml');
    LSb.AppendLine('version: "1.0"');
    LSb.AppendLine('tree: module');
    LSb.AppendLine('nodes:');
    LSb.AppendLine('  - id: mod-myservice');
    LSb.AppendLine('    kind: module');
    LSb.AppendLine('    ...');
    LSb.AppendLine('');
    LSb.AppendLine('Emit documents for function-tree, module-tree, view-tree, data-tree (omit a tree');
    LSb.AppendLine('only if the source material gives no information for it). evidence and');
    LSb.AppendLine('issues documents are optional.');

    WritePromptFile('context-pack.md', LSb.ToString);
  finally
    LSb.Free;
  end;
end;

procedure TAsWishPromptService.WriteGenerationPrompt(const AProjectName,
  AProjectType: string);
var
  LSb: TStringBuilder;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# A '#$2192' B Generation Prompt');
    LSb.AppendLine('');
    LSb.AppendLine('You are generating the AsWish B (specification facts) for a ' +
      AProjectType + ' project: ' + AProjectName);
    LSb.AppendLine('');
    LSb.AppendLine('## Process');
    LSb.AppendLine('');
    LSb.AppendLine('1. Read the project material listed in `context-pack.md`.');
    LSb.AppendLine('2. Identify functional capabilities (what the software does).');
    LSb.AppendLine('3. Identify modular structure (how code is organized).');
    LSb.AppendLine('4. Identify visible UI elements (what the user sees).');
    LSb.AppendLine('5. Identify data entities, fields, relations, persistence, and migrations.');
    LSb.AppendLine('6. Cross-reference and find gaps, conflicts, ambiguities.');
    LSb.AppendLine('7. Output YAML files conforming to AsWish Protocol v1.2-draft.');
    LSb.AppendLine('');
    LSb.AppendLine('## Output Files');
    LSb.AppendLine('');
    LSb.AppendLine('Write ONLY these files (do not modify anything else):');
    LSb.AppendLine('');
    LSb.AppendLine('- `.AsWish/trees/function-tree.yaml`');
    LSb.AppendLine('- `.AsWish/trees/module-tree.yaml`');
    LSb.AppendLine('- `.AsWish/trees/view-tree.yaml`');
    LSb.AppendLine('- `.AsWish/trees/data-tree.yaml`');
    LSb.AppendLine('- `.AsWish/relations/requirement-relations.yaml`');
    LSb.AppendLine('- `.AsWish/evidence/source-evidence.yaml`');
    LSb.AppendLine('- `.AsWish/issues/doc-issues.yaml`');
    LSb.AppendLine('');
    LSb.AppendLine('## Quality Bar');
    LSb.AppendLine('');
    LSb.AppendLine('- Every node has at least one `source_refs[].ref_id`.');
    LSb.AppendLine('- Inferred content uses `confidence: low` and `status: candidate`.');
    LSb.AppendLine('- Do not invent features not supported by source material.');
    LSb.AppendLine('- Mark uncertain content as issues (type: low_confidence or no_source).');
    LSb.AppendLine('- Use stable IDs: `func-{slug}`, `mod-{slug}`, `view-{slug}`, `data-{slug}`.');

    WritePromptFile('doc-optimization-prompt.md', LSb.ToString);
  finally
    LSb.Free;
  end;
end;

procedure TAsWishPromptService.WriteNodePrompt(const ANode: TSpecNode);
var
  LSb: TStringBuilder;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# Node Review Task');
    LSb.AppendLine('');
    LSb.AppendLine('## Node');
    LSb.AppendLine('');
    LSb.AppendLine('- ID: `' + ANode.Id + '`');
    LSb.AppendLine('- Tree: ' + TSpecEnums.TreeTypeToStr(ANode.Tree));
    LSb.AppendLine('- Title: ' + ANode.Title);
    LSb.AppendLine('- Kind: ' + ANode.Kind);
    LSb.AppendLine('- Status: ' + TSpecEnums.NodeStatusToStr(ANode.Status));
    LSb.AppendLine('- Confidence: ' + TSpecEnums.ConfidenceToStr(ANode.Confidence));
    LSb.AppendLine('- Source layer: ' + TSpecEnums.SourceLayerToStr(ANode.SourceLayer));
    LSb.AppendLine('');
    if ANode.Summary <> '' then
    begin
      LSb.AppendLine('## Current Summary');
      LSb.AppendLine('');
      LSb.AppendLine(ANode.Summary);
      LSb.AppendLine('');
    end;

    LSb.AppendLine('## Task');
    LSb.AppendLine('');
    LSb.AppendLine('Review this node. If you can improve the summary, acceptance criteria,');
    LSb.AppendLine('or source evidence, write an updated YAML fragment for it.');
    LSb.AppendLine('');
    LSb.AppendLine('Do NOT change the `id`. Do NOT delete `decision_refs` if present.');

    WritePromptFile('node-prompt.md', LSb.ToString);
  finally
    LSb.Free;
  end;
end;

procedure TAsWishPromptService.WriteDecisionRewritePrompt(
  const ADecisions: TList<TSpecDecision>);
var
  LSb: TStringBuilder;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# Decision Write-Back Prompt');
    LSb.AppendLine('');
    LSb.AppendLine('The user has made the following decisions about the project specification.');
    LSb.AppendLine('Update the corresponding nodes in `.AsWish/trees/` to reflect these decisions.');
    LSb.AppendLine('');

    if ADecisions.Count = 0 then
      LSb.AppendLine('(No accepted decisions yet.)')
    else
    begin
      LSb.AppendLine('## Accepted Decisions');
      LSb.AppendLine('');
      for var LDec in ADecisions do
      begin
        if LDec.Status <> dsAccepted then Continue;
        LSb.AppendLine('### ' + LDec.Title);
        LSb.AppendLine('');
        LSb.AppendLine('- ID: `' + LDec.Id + '`');
        LSb.AppendLine('- Type: ' + TSpecEnums.DecisionTypeToStr(LDec.DecisionType));
        LSb.AppendLine('- Decision: ' + LDec.DecisionText);
        if LDec.Rationale <> '' then
          LSb.AppendLine('- Rationale: ' + LDec.Rationale);
        if LDec.AiInstruction <> '' then
        begin
          LSb.AppendLine('');
          LSb.AppendLine('**AI Instruction:** ' + LDec.AiInstruction);
        end;
        LSb.AppendLine('');
      end;
    end;

    LSb.AppendLine('## Constraints');
    LSb.AppendLine('');
    LSb.AppendLine('- Treat accepted decisions as authoritative facts.');
    LSb.AppendLine('- When source documents conflict with an accepted decision, the decision wins.');
    LSb.AppendLine('- Do not silently delete nodes that have `decision_refs` non-empty.');
    LSb.AppendLine('- Update affected nodes by adding the `decision_refs` and adjusting status to `confirmed`.');

    WritePromptFile('decision-rewrite-prompt.md', LSb.ToString);
  finally
    LSb.Free;
  end;
end;

function TAsWishPromptService.WriteGrillingPrompt(const AIssue: TSpecIssue;
  const ANodes: TList<TSpecNode>): string;
var
  LSb: TStringBuilder;
  LNodeCount: Integer;
  LAnchorTitle, LAnchorIds: string;

  function SafeIssueId(const AValue: string): string;
  var
    I: Integer;
    C: Char;
  begin
    Result := '';
    for I := 1 to Length(AValue) do
    begin
      C := AValue[I];
      if ((C >= 'a') and (C <= 'z')) or ((C >= 'A') and (C <= 'Z')) or
         ((C >= '0') and (C <= '9')) or (C = '-') or (C = '_') or
         (C = '.') then
        Result := Result + C
      else
        Result := Result + '_';
    end;
    if Result = '' then
      Result := 'unknown';
  end;

  function IsAffected(const ANodeId: string): Boolean;
  begin
    Result := False;
    for var LId in AIssue.AffectedNodes do
      if LId = ANodeId then
        Exit(True);
  end;

  function IsFogNode(const ANode: TSpecNode): Boolean;
  begin
    Result := ANode.HasFogState and
      (ANode.FogState in [fsMisty, fsFoggy]);
  end;

  function NodeTitle(const ANode: TSpecNode): string;
  begin
    Result := ANode.Title;
    if Result = '' then
      Result := ANode.Id;
    if Result = '' then
      Result := '未命名节点';
  end;

begin
  Result := '';
  if (AIssue.IssueType <> itGrillingTicket) or (AIssue.Id = '') then
    Exit;

  LAnchorTitle := AIssue.Title;
  if LAnchorTitle = '' then
    LAnchorTitle := '未命名 grilling ticket';
  LAnchorIds := '(none)';
  if Length(AIssue.AffectedNodes) > 0 then
  begin
    LAnchorIds := AIssue.AffectedNodes[0];
    for var I := 1 to High(AIssue.AffectedNodes) do
      LAnchorIds := LAnchorIds + ', ' + AIssue.AffectedNodes[I];
  end;

  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# Grill-me 追问任务');
    LSb.AppendLine;
    LSb.AppendLine('这是一个可直接粘贴给 Claude Code、Cursor 或 Codex 的 AsWish 旁路追问清单。');
    LSb.AppendLine('你必须一次只推进一个问题：先给出“推荐答案”，再等待用户选择、修改或自由作答。');
    LSb.AppendLine;

    LSb.AppendLine('## Ticket 上下文');
    LSb.AppendLine;
    LSb.AppendLine('- ID: `' + AIssue.Id + '`');
    LSb.AppendLine('- 类型: `grilling_ticket`');
    LSb.AppendLine('- 严重程度: `' + TSpecEnums.IssueSeverityToStr(AIssue.Severity) + '`');
    LSb.AppendLine('- 标题: ' + LAnchorTitle);
    LSb.AppendLine('- 受影响节点 ID: ' + LAnchorIds);
    if AIssue.Description <> '' then
      LSb.AppendLine('- 当前描述: ' + AIssue.Description);
    if AIssue.SuggestedAction <> '' then
      LSb.AppendLine('- 当前建议动作: ' + AIssue.SuggestedAction);
    if AIssue.SuggestedPrompt <> '' then
      LSb.AppendLine('- 已有提示: ' + AIssue.SuggestedPrompt);
    LSb.AppendLine;

    LSb.AppendLine('## 决策树拆解');
    LSb.AppendLine;
    LSb.AppendLine('先问第 1 条；得到用户答复后，按依赖关系逐条收敛，不要同时抛出全部问题。');
    LSb.AppendLine;
    LSb.AppendLine('1. **目标结果**');
    LSb.AppendLine('   - 依赖：无；顺序：先问。');
    LSb.AppendLine('   - 判断：用户最终要达成什么可观察结果？');
    LSb.AppendLine('2. **使用者与触发时机**');
    LSb.AppendLine('   - 依赖：目标结果；顺序：目标明确后再问。');
    LSb.AppendLine('   - 判断：谁在什么场景下触发这个结果？');
    LSb.AppendLine('3. **范围与非目标**');
    LSb.AppendLine('   - 依赖：目标结果、使用者；顺序：行为主体明确后再问。');
    LSb.AppendLine('   - 判断：本 ticket 必须覆盖什么，明确不覆盖什么？');
    LSb.AppendLine('4. **约束与依赖**');
    LSb.AppendLine('   - 依赖：范围与非目标；顺序：边界冻结后再问。');
    LSb.AppendLine('   - 判断：哪些已有节点、规则、数据或外部条件会限制方案？');
    LSb.AppendLine('5. **可验证结果**');
    LSb.AppendLine('   - 依赖：前 4 条；顺序：最后确认。');
    LSb.AppendLine('   - 判断：用什么例子、状态或用户动作证明已经达到目标？');
    LSb.AppendLine;

    LSb.AppendLine('## 目标 / 边界 / 验收三问');
    LSb.AppendLine;
    LSb.AppendLine('### 1. 目标');
    LSb.AppendLine('推荐答案：围绕“' + LAnchorTitle + '”明确一个用户可观察的最终结果，只解决本 ticket 暴露的不确定性。');
    LSb.AppendLine('请回答：接受、修改或自由描述你真正想达成的结果。');
    LSb.AppendLine;
    LSb.AppendLine('### 2. 边界');
    LSb.AppendLine('推荐答案：只澄清节点 `' + LAnchorIds + '` 及其直接依赖；不扩展到未受影响能力。');
    LSb.AppendLine('请回答：接受、修改或自由列出本次必须包含与明确不做的内容。');
    LSb.AppendLine;
    LSb.AppendLine('### 3. 验收');
    LSb.AppendLine('推荐答案：用 1–3 条可观察结果或用户动作判断目标已满足，并单列仍待决定的问题。');
    LSb.AppendLine('请回答：接受、修改或自由给出可复现的验收例子。');
    LSb.AppendLine;

    LSb.AppendLine('## 受影响雾区节点');
    LSb.AppendLine;
    LNodeCount := 0;
    if ANodes <> nil then
      for var LNode in ANodes do
      begin
        if not IsFogNode(LNode) or not IsAffected(LNode.Id) then
          Continue;
        Inc(LNodeCount);
        LSb.AppendLine('- `' + LNode.Id + '` · ' + NodeTitle(LNode) +
          ' · fog_state: `' + TSpecEnums.FogStateToStr(LNode.FogState) + '`');
        if LNode.Summary <> '' then
          LSb.AppendLine('  - 当前摘要: ' + LNode.Summary);
        if LNode.FogState = fsFoggy then
          LSb.AppendLine('  - 待解问题：终点仍在雾里，先明确该节点必须支持的用户结果与非目标。')
        else
          LSb.AppendLine('  - 待解问题：方向已有但仍有歧义，先确认边界和可验证的完成条件。');
      end;
    if LNodeCount = 0 then
      LSb.AppendLine('- 当前上下文未找到处于 `misty` 或 `foggy` 的受影响节点。待解问题：先确认 ticket 与雾区节点的对应关系。');
    LSb.AppendLine;

    LSb.AppendLine('## 来源与约束');
    LSb.AppendLine;
    if Length(AIssue.SourceRefs) = 0 then
      LSb.AppendLine('- 来源证据：当前 ticket 未提供 `source_refs`，不要把推断当成事实。')
    else
      for var LRef in AIssue.SourceRefs do
        LSb.AppendLine('- 来源证据: `' + LRef.RefId + '`' +
          IfThen(LRef.Note <> '', ' — ' + LRef.Note, ''));
    LSb.AppendLine('- 不要修改业务代码、HTML 或 AsWish 原始来源文件。');
    LSb.AppendLine('- 不要推翻已确认的人类决策；不确定内容必须保留为待用户确认项。');
    LSb.AppendLine;

    LSb.AppendLine('## 输出格式');
    LSb.AppendLine;
    LSb.AppendLine('回答结束时只汇总：已确认的目标、边界、验收、仍待确认的问题，以及建议推进的 fog_state 下一步。');
    LSb.AppendLine('Claude Code 请保留本节的“不修改”约束；Cursor 可用 `@file` 引用证据；Codex CLI 请保留本节 `## 约束` 与 `## 输出格式`。');

    Result := TPath.Combine(FBasePath,
      'grilling-ticket-' + SafeIssueId(AIssue.Id) + '.md');
    WritePromptFile(TPath.GetFileName(Result), LSb.ToString);
  finally
    LSb.Free;
  end;
end;

end.
