{ ============================================================================
  AsWish.Services.Commons
  Difference Commons Service (WO-20260923-0041).
  ============================================================================ }
unit AsWish.Services.Commons;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  AsWish.Models, AsWish.Services.SpecStore;

type
  TAsWishCommonsService = class
  private
    FStore: TAsWishStoreService;
    function MatchPattern(const APattern, AText: string): Boolean;
  public
    constructor Create(AStore: TAsWishStoreService);
    class function GetSeedLessons: TArray<TSpecCommonsLesson>; static;
    function SeedCommonsLessonsIfEmpty: Integer;
    function ListLessons: TArray<TSpecCommonsLesson>;
    function FindMatchingLessons(const AText: string; const ANodes: TArray<string> = nil): TArray<TSpecCommonsLesson>;
    function ExtractLessonFromChangeSet(const AChangeSet: TChangeSet; const ADecision: TSpecDecision;
      const ADiffReport: TSpecDifferenceReport; const ATakeaway: string = ''): TSpecCommonsLesson;
    function SaveLessonDraft(const ALesson: TSpecCommonsLesson): string;
  end;

implementation

uses
  System.IOUtils, System.StrUtils, System.DateUtils;

constructor TAsWishCommonsService.Create(AStore: TAsWishStoreService);
begin
  inherited Create;
  FStore := AStore;
end;

class function TAsWishCommonsService.GetSeedLessons: TArray<TSpecCommonsLesson>;
  procedure Add(AIdx: Integer; const AId, ATit, ATak, APat, AWr, ARi, ABase, ADiff, ADom, AStory: string);
  begin
    Result[AIdx] := TSpecCommonsLesson.CreateNew(AId, ATit, ATak, APat, AWr, ARi, ABase, ADiff, ADom, 'seed:aswish-dogfood', AStory);
  end;
begin
  SetLength(Result, 10);
  Add(0, 'lesson-0001', 'Disable vs Delete 混淆',
    '停用是状态迁移，删除是物理抹除；AI 倾向用删除代替停用，必须以领域契约约束生命周期边界。',
    'status=disabled vs action=delete|停用 vs 删除|disable vs delete',
    'delete_user(id) / nodes.remove(id) 直接物理删除',
    'status := "disabled"; is_active := false; 保留溯源历史 [dec-lifecycle-001]',
    'bl-user-lifecycle-001', 'diff-20260901-001', 'domain-lifecycle', 'anti_pattern');
  Add(1, 'lesson-0002', '意图改写与盲目断言陷阱 (c8d8113→ee66b35)',
    '未完整阅读上下文就下断言是 AI 典型幻觉；证据必须精确到行号与内容哈希，而非盲目推测。',
    '从未赋值|never assigned|partially read|evidence empty',
    '读了半个函数直接断言变量从未被赋值，并在文档中写死虚假结论',
    '遍历 AST 全路径与调用流，通过 SourceRef 精确行号与内容哈希佐证 [dec-provenance-0038]',
    'bl-provenance-0038', 'diff-c8d8113-ee66b35', 'evidence-provenance', 'cautionary');
  Add(2, 'lesson-0003', '样本时效与旧构建污染陷阱',
    '旧二进制产物的 PASS 不是当前代码的真实状态；必须隔离构建与真实执行以拆穿虚假安全感。',
    'stale artifact|cached build|旧产物|build bypass',
    '直接复用历史 build 产物跑测试，忽略新增改动引发的潜在失效',
    'Clean build 强制重编译，并比对构建时间戳与源码 hash 保证同步 [dec-build-0033]',
    'bl-build-isolation-0033', 'diff-20260902-stale', 'build-discipline', 'cautionary');
  Add(3, 'lesson-0004', '未锚定降级与单点阻断陷阱',
    '缺少降级路径的硬编码会导致整链瘫痪；必须设计可恢复分级防护与 L1 本地降级。',
    'hard abort on missing remote|无降级|single point failure',
    '远端服务或外部模型不可达时直接抛未捕获异常中断主流程',
    '优雅降级至本地规则引擎与离线缓存，确保最小可用体验 [dec-resilience-0027]',
    'bl-resilience-0027', 'diff-20260903-fallback', 'fault-tolerance', 'boundary_defense');
  Add(4, 'lesson-0005', '框架否决与意图替换混淆',
    'FrameRejection 是对提案边界的彻底否决，不是微调参数；切勿把结构性重构降级为补丁打补丁。',
    'frame rejection treated as patch|否决当微调',
    '人类否决设计架构后，AI 依然在错误框架内做就地打补丁修复',
    '彻底回滚至前置决策点，重选架构分支并显式记录否决原因 [dec-frame-0030]',
    'bl-frame-reject-0030', 'diff-20260906-frame', 'ehai-contract', 'anti_pattern');
  Add(5, 'lesson-0006', '承诺边界偷跑陷阱',
    'Commitment Gate 之前严禁产生外部副作用；所有中间试错必须限制在沙盒暂存区内。',
    'unauthorized commit|pre-gate side effect|偷跑副作用',
    '未通过人类最终 Gate 校验即向真实环境发出写操作或状态提交',
    '所有候选项保留在 ChangeSet 暂存区，仅在显式 Commit 门禁通过后落地 [dec-gate-0001]',
    'bl-gate-boundary-001', 'diff-20260914-gate', 'security-gate', 'boundary_defense');
  Add(6, 'lesson-0007', '来源粒度退化陷阱',
    '缺乏行号和内容哈希的来源引用不是证据，只是口头声明；溯源信息必须机器可验。',
    'empty line numbers|missing content hash|证据链行号为空',
    'SourceRef 仅保留文件相对路径，StartLine/EndLine 与 ContentHash 均为空字符串',
    '精确提取行区间与 SHA-256 摘要，实现字节级机器复核 [dec-sourceref-0038]',
    'bl-sourceref-0038', 'diff-20260922-0038', 'evidence-provenance', 'divergence_resolved');
  Add(7, 'lesson-0008', '视觉线框与物理控件漂移陷阱',
    '高保真线框的视觉层次与坐标必须精确绑定物理组件，切忌逻辑树与渲染树脱节。',
    'visual wireframe z-order drift|物理控件脱节|visual coordinate mismatch',
    '渲染层根据估算位置绘制组件，未与实际 VCL 宿主层次和坐标基准对齐',
    '引入 TAsWishBaseline 视觉契约与归一化坐标系统严格对齐 [dec-visual-0030]',
    'bl-visual-0030', 'diff-20260906-visual', 'visual-workflow', 'clarification_triumph');
  Add(8, 'lesson-0009', '业务重试策略死循环陷阱',
    '缺少退避算法与最大尝试限制的重试是系统雪崩主因；必须严格限定重试次数与幂等键。',
    'func-payment-retry|retry without backoff|payment loop|支付重试',
    '支付失败直接无脑递归重试，导致渠道风控拦截与订单重复扣款',
    '引入指数退避、幂等 Token 校验及 3 次熔断限制 [dec-payment-0002]',
    'bl-payment-retry-002', 'diff-payment-retry-loop', 'business-logic', 'anti_pattern');
  Add(9, 'lesson-0010', '现实漂移顺势接受陷阱',
    '不可把 AI 引入的无意漂移当成基线演进；变更审计必须区分人类主动决策与 AI 静默偏航。',
    'silent baseline drift|unintended deviation|顺势接受漂移',
    '变更审查中盲目批量 Approve 所有字段改动，顺从了 AI 的隐蔽语义偷换',
    '显式比对三方差异视图，对偏航项执行 HumanOverride 或 FrameRejection [dec-drift-0036]',
    'bl-drift-audit-0036', 'diff-20260909-drift', 'semantic-audit', 'cautionary');
end;

function TAsWishCommonsService.SeedCommonsLessonsIfEmpty: Integer;
var LSeeds: TArray<TSpecCommonsLesson>;
begin
  Result := 0;
  if (FStore = nil) or (Length(FStore.ListCommonsLessonFiles) > 0) then Exit;
  LSeeds := GetSeedLessons;
  for var LSeed in LSeeds do
  begin
    FStore.WriteCommonsLessonFile(TPath.Combine('commons', LSeed.Id + '.yaml'), LSeed);
    Inc(Result);
  end;
end;

function TAsWishCommonsService.ListLessons: TArray<TSpecCommonsLesson>;
begin
  if FStore <> nil then
  begin
    Result := FStore.ListCommonsLessons;
    if Length(Result) > 0 then Exit;
  end;
  Result := GetSeedLessons;
end;

function TAsWishCommonsService.MatchPattern(const APattern, AText: string): Boolean;
begin
  Result := False;
  if (APattern = '') or (AText = '') then Exit;
  for var LTerm in APattern.Split(['|']) do
    if (LTerm.Trim <> '') and ContainsText(AText, LTerm.Trim) then Exit(True);
end;

function TAsWishCommonsService.FindMatchingLessons(const AText: string;
  const ANodes: TArray<string>): TArray<TSpecCommonsLesson>;
var
  LMatches: TList<TSpecCommonsLesson>;
  LCombinedText: string;
begin
  LMatches := TList<TSpecCommonsLesson>.Create;
  try
    LCombinedText := AText;
    if ANodes <> nil then
      for var LNode in ANodes do
        LCombinedText := LCombinedText + ' ' + LNode;
    for var LLesson in ListLessons do
      if MatchPattern(LLesson.TriggerPattern, LCombinedText) then
        LMatches.Add(LLesson);
    Result := LMatches.ToArray;
  finally
    LMatches.Free;
  end;
end;

function TAsWishCommonsService.ExtractLessonFromChangeSet(
  const AChangeSet: TChangeSet; const ADecision: TSpecDecision;
  const ADiffReport: TSpecDifferenceReport; const ATakeaway: string): TSpecCommonsLesson;
var
  LId, LTitle, LTakeaway, LWrong, LRight, LMode: string;
begin
  if ADecision.Id <> '' then LId := 'lesson-' + ADecision.Id
  else LId := 'lesson-' + FormatDateTime('yyyymmdd-hhnnss', Now);
  LTitle := '经验提取: ' + IfThen(AChangeSet.IntentNodeId <> '', AChangeSet.IntentNodeId, ADecision.Title);
  if ATakeaway <> '' then LTakeaway := ATakeaway
  else if ADecision.Rationale <> '' then LTakeaway := ADecision.Rationale
  else LTakeaway := '人类裁定分叉教训: 原始意图为 "' + AChangeSet.RawUserIntent + '"';
  LWrong := Format('AI 提议变更: Node=%s, Intent="%s"', [AChangeSet.IntentNodeId, AChangeSet.RawUserIntent]);
  LRight := Format('人类裁定 [%s]: %s (决策=%s)', [ADecision.Id, ADecision.DecisionText,
    TSpecEnums.DecisionStatusToStr(ADecision.Status)]);
  if ADecision.Status = rsRejected then LMode := 'anti_pattern' else LMode := 'divergence_resolved';

  Result := TSpecCommonsLesson.CreateNew(LId, LTitle, LTakeaway,
    AChangeSet.IntentNodeId + '|' + AChangeSet.RawUserIntent, LWrong, LRight,
    ADiffReport.BaselineId, IfThen(ADiffReport.BaselineId <> '', ADiffReport.BaselineId + '-diff', 'diff-' + LId),
    'general', 'human:local', LMode);
end;

function TAsWishCommonsService.SaveLessonDraft(const ALesson: TSpecCommonsLesson): string;
var LRelPath: string;
begin
  Result := '';
  if FStore = nil then Exit;
  LRelPath := TPath.Combine('commons', ALesson.Id + '.yaml');
  FStore.WriteCommonsLessonFile(LRelPath, ALesson);
  Result := TPath.Combine(FStore.BasePath, LRelPath);
end;

end.
