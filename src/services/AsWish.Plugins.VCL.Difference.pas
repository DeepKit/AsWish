unit AsWish.Plugins.VCL.Difference;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  AsWish.Models, AsWish.Hash, AsWish.Services.Difference;

type
  /// <summary>
  /// Official VCL Platform Difference Comparator (WO-0031).
  /// Implements IPlatformDifferenceComparator for Delphi VCL desktop profile.
  /// Resolves platform identities to canonical node.id via IPlatformIdentityResolver.
  /// Performs L2 relational layout comparison and L3 appearance/style comparison.
  /// Note: L3 difference is mapped to daContent as temporary backward compatibility.
  /// </summary>
  TAsWishVCLDifferenceComparator = class(TInterfacedObject, IPlatformDifferenceComparator)
  public
    function GetPlatformName: string;
    function CanHandle(const AContext: TPlatformComparisonContext; const ABaseline: TAsWishBaseline): Boolean;
    function CompareL2L3(const AContext: TPlatformComparisonContext; const ABaseline: TAsWishBaseline): TArray<TSpecDifferenceItem>;
  end;

implementation

type
  TVCLObservedControl = record
    PlatformName, ClassName: string;
    Left, Top, Width, Height, FontColor: Integer;
    FontColorKnown: Boolean;
  end;

function MakeDiffItem(const ANodeId: string; AKind: TDifferenceKind; AAspect: TDifferenceAspect;
  const ABaseHash, AEvHash, ANote: string): TSpecDifferenceItem;
begin
  Result := Default(TSpecDifferenceItem);
  Result.NodeId := ANodeId; Result.Kind := AKind; Result.ChangedAspect := AAspect;
  Result.BaselineHash := ABaseHash; Result.EvidenceHash := AEvHash; Result.Note := ANote;
end;

function ParseColorValue(const AVal: TJSONValue): Integer;
begin
  Result := 0;
  if AVal is TJSONNumber then Exit(TJSONNumber(AVal).AsInt);
  if AVal is TJSONString then
  begin
    var S := AVal.Value.ToLower;
    if S = 'clnavy' then Exit(8388608); if S = 'clred' then Exit(255);
    if S = 'clblue' then Exit(16711680); if S = 'clblack' then Exit(0);
    if S = 'clwhite' then Exit(16777215); if S = 'clhighlight' then Exit(-1);
    Exit(StrToIntDef(AVal.Value, 0));
  end;
end;

function TAsWishVCLDifferenceComparator.GetPlatformName: string;
begin
  Result := 'vcl';
end;

function TAsWishVCLDifferenceComparator.CanHandle(const AContext: TPlatformComparisonContext; const ABaseline: TAsWishBaseline): Boolean;
begin
  Result := (AContext.TreeType = 'view') or (AContext.ObservationJson <> '') or
    (ABaseline.TreeType = 'view') or (Pos('vcl', LowerCase(ABaseline.RendererVersion)) > 0) or
    (Pos('vcl', LowerCase(ABaseline.VisualBinding)) > 0);
end;

function TAsWishVCLDifferenceComparator.CompareL2L3(const AContext: TPlatformComparisonContext;
  const ABaseline: TAsWishBaseline): TArray<TSpecDifferenceItem>;
var
  LObsJson, LConstraintsJson, LStylesJson, LName, LNodeId, LTargetId, LRel, LToken, LColorName: string;
  LObsRoot, LConstraintsRoot, LStylesRoot, LSpecObj, LStyleObj: TJSONObject;
  LObsArray: TJSONArray;
  LObservedMap: TDictionary<string, TVCLObservedControl>;
  LDiffList: TList<TSpecDifferenceItem>;
  LObsCtrl, LObsA, LObsB: TVCLObservedControl;
  LExpectedGap, LObsGap, LExpectedColor: Integer;
begin
  SetLength(Result, 0);
  LObsJson := AContext.ObservationJson;
  if LObsJson = '' then Exit;
  LObsRoot := TJSONObject.ParseJSONValue(LObsJson) as TJSONObject;
  if LObsRoot = nil then Exit;
  LObservedMap := TDictionary<string, TVCLObservedControl>.Create;
  LDiffList := TList<TSpecDifferenceItem>.Create;
  try
    LObsArray := LObsRoot.GetValue<TJSONArray>('Observations', nil);
    if LObsArray = nil then Exit;
    for var I := 0 to LObsArray.Count - 1 do
    begin
      if not (LObsArray.Items[I] is TJSONObject) then Continue;
      var LItemObj := TJSONObject(LObsArray.Items[I]);
      LName := LItemObj.GetValue<string>('Name', '');
      LObsCtrl.PlatformName := LName; LObsCtrl.ClassName := LItemObj.GetValue<string>('ClassName', '');
      LObsCtrl.Left := 0; LObsCtrl.Top := 0; LObsCtrl.Width := 0; LObsCtrl.Height := 0;
      var LBounds := LItemObj.GetValue<TJSONObject>('Bounds', nil);
      if LBounds <> nil then
      begin
        LObsCtrl.Left := LBounds.GetValue<Integer>('Left', 0);
        LObsCtrl.Top := LBounds.GetValue<Integer>('Top', 0);
        LObsCtrl.Width := LBounds.GetValue<Integer>('Width', 0);
        LObsCtrl.Height := LBounds.GetValue<Integer>('Height', 0);
      end;
      LObsCtrl.FontColor := 0;
      LObsCtrl.FontColorKnown := False;
      var LFontColorVal := LItemObj.GetValue<TJSONValue>('FontColor', nil);
      if (LFontColorVal <> nil) and not (LFontColorVal is TJSONNull) then
      begin
        LObsCtrl.FontColor := ParseColorValue(LFontColorVal);
        LObsCtrl.FontColorKnown := True;
      end;
      // Identity resolution via IPlatformIdentityResolver (Fail-Closed when resolver supplied, DFM convention fallback when nil)
      if (AContext.IdentityResolver <> nil) and
         AContext.IdentityResolver.TryResolveNodeId(LName, LNodeId) and (LNodeId <> '') then
        LObservedMap.AddOrSetValue(LNodeId, LObsCtrl)
      else if (AContext.IdentityResolver = nil) and (LName <> '') then
      begin
        if LName.StartsWith('view-ctrl-', True) then
          LNodeId := LowerCase(LName)
        else
          LNodeId := 'view-ctrl-' + LowerCase(LName);
        LObservedMap.AddOrSetValue(LNodeId, LObsCtrl);
      end
      else
        LDiffList.Add(MakeDiffItem('', dkChanged, daNone, '', TSpecHash.Sha256Hex(LName),
          Format('Missing identity mapping: platform element "%s" has no canonical node.id (fail-closed, unsupported)', [LName])));
    end;
    // L2 Relational Layout Comparison
    LConstraintsJson := AContext.ConstraintsJson;
    if LConstraintsJson <> '' then
    begin
      LConstraintsRoot := TJSONObject.ParseJSONValue(LConstraintsJson) as TJSONObject;
      if LConstraintsRoot <> nil then
      try
        for var I := 0 to LConstraintsRoot.Count - 1 do
        begin
          LNodeId := LConstraintsRoot.Pairs[I].JsonString.Value;
          if not (LConstraintsRoot.Pairs[I].JsonValue is TJSONObject) then Continue;
          LSpecObj := TJSONObject(LConstraintsRoot.Pairs[I].JsonValue);
          LRel := LSpecObj.GetValue<string>('relation', '');
          if LRel.StartsWith('left-of ') then
          begin
            LTargetId := LRel.Substring(8).Trim;
            if LObservedMap.TryGetValue(LNodeId, LObsA) and LObservedMap.TryGetValue(LTargetId, LObsB) then
            begin
              var LProvStr := '';
              var LProvObj := LSpecObj.GetValue<TJSONObject>('provenance', nil);
              if LProvObj <> nil then
              begin
                var LDecId := LProvObj.GetValue<string>('decision_id', '');
                if LDecId <> '' then
                  LProvStr := Format(' [provenance: %s]', [LDecId]);
              end;

              if LObsA.Left >= LObsB.Left then
                LDiffList.Add(MakeDiffItem(LTargetId, dkChanged, daRelation, TSpecHash.Sha256Hex(LRel),
                  TSpecHash.Sha256Hex(Format('Left=%d,Left=%d', [LObsB.Left, LObsA.Left])),
                  Format('L2 Layout Difference: Expected %s left-of %s%s, but Observed %s (Left=%d) left-of %s (Left=%d).',
                    [LNodeId, LTargetId, LProvStr, LTargetId, LObsB.Left, LNodeId, LObsA.Left])))
              else if LSpecObj.TryGetValue<Integer>('gap', LExpectedGap) then
              begin
                LObsGap := LObsB.Left - (LObsA.Left + LObsA.Width);
                if LObsGap <> LExpectedGap then
                  LDiffList.Add(MakeDiffItem(LTargetId, dkChanged, daRelation, TSpecHash.Sha256Hex(Format('gap=%d', [LExpectedGap])),
                    TSpecHash.Sha256Hex(Format('gap=%d', [LObsGap])),
                    Format('L2 Layout Difference: Expected gap %d between %s and %s, but Observed %d.',
                      [LExpectedGap, LNodeId, LTargetId, LObsGap])));
              end;
            end;
          end;
        end;
      finally
        LConstraintsRoot.Free;
      end;
    end;
    // L3 Appearance / Style Comparison (Temporary compatibility mapped to daContent)
    LStylesJson := AContext.ExpectedStylesJson;
    if LStylesJson <> '' then
    begin
      LStylesRoot := TJSONObject.ParseJSONValue(LStylesJson) as TJSONObject;
      if LStylesRoot <> nil then
      try
        for var I := 0 to LStylesRoot.Count - 1 do
        begin
          LNodeId := LStylesRoot.Pairs[I].JsonString.Value;
          if not (LStylesRoot.Pairs[I].JsonValue is TJSONObject) then Continue;
          LStyleObj := TJSONObject(LStylesRoot.Pairs[I].JsonValue);
          if LObservedMap.TryGetValue(LNodeId, LObsCtrl) then
          begin
            var LVal := LStyleObj.GetValue<TJSONValue>('FontColor', nil);
            if LVal = nil then LVal := LStyleObj.GetValue<TJSONValue>('color', nil);
            if LVal <> nil then
            begin
              LExpectedColor := ParseColorValue(LVal);
              LToken := LStyleObj.GetValue<string>('Token', '');
              if LToken = '' then LToken := LStyleObj.GetValue<string>('token', '');
              LColorName := LStyleObj.GetValue<string>('ColorName', '');
              if (LColorName = '') and (LVal is TJSONString) then LColorName := LVal.Value;
              if not LObsCtrl.FontColorKnown then
              begin
                // Unobservable property: do NOT emit false difference (no false red)
                // and do NOT assume match (no false green). Focus on L2 layout comparison.
              end
              else if LObsCtrl.FontColor <> LExpectedColor then
              begin
                var LNote := Format('L3 Appearance Difference: Expected %s (%d), but Observed %d.', [LColorName, LExpectedColor, LObsCtrl.FontColor]);
                if LToken <> '' then
                  LNote := Format('L3 Appearance Difference: Expected %s (%d) from token %s, but Observed %d.', [LColorName, LExpectedColor, LToken, LObsCtrl.FontColor]);
                // Temporary compatibility mapping: daContent used for L3 appearance differences (WO-0031)
                LDiffList.Add(MakeDiffItem(LNodeId, dkChanged, daContent,
                  TSpecHash.Sha256Hex(IntToStr(LExpectedColor)), TSpecHash.Sha256Hex(IntToStr(LObsCtrl.FontColor)), LNote));
              end;
            end;
          end;
        end;
      finally
        LStylesRoot.Free;
      end;
    end;
    Result := LDiffList.ToArray;
  finally
    LDiffList.Free;
    LObservedMap.Free;
    LObsRoot.Free;
  end;
end;

end.
