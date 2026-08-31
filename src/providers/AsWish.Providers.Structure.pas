{ ============================================================================
  AsWish.Providers.Structure

  Structure provider for the left tool window tree.
  Shows file classification tree and spec trees (function/module/view/data)
  populated from real scan results.
  ============================================================================ }

unit AsWish.Providers.Structure;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  AsWish.UI.Intf,
  AsWish.UI.Types,
  AsWish.Services.Scan,
  AsWish.Services.TreeBuilder,
  AsWish.Models;

type
  TAsWishStructureProvider = class(TInterfacedObject, IShellStructureProvider)
  private
    FScanService: TAsWishScanService;
    FTreeBuilder: TAsWishTreeBuilder;
    function CategoryToRef(ACat: TFileCategory): TShellObjectRef;
    function SpecNodeToRef(const ANode: TSpecNode): TShellObjectRef;
    function FindChildNodes(const AParentId: string;
      ANodes: TList<TSpecNode>): TArray<TShellObjectRef>;
  public
    constructor Create(AScanService: TAsWishScanService;
      ATreeBuilder: TAsWishTreeBuilder);
    function ProviderId: string;
    function GetTreeNames: TArray<string>;
    function GetRootNodes(const ATreeName: string): TArray<TShellObjectRef>;
    function HasChildren(const ANode: TShellObjectRef): Boolean;
    function GetChildren(const ANode: TShellObjectRef): TArray<TShellObjectRef>;
    function GetDisplayText(const ANode: TShellObjectRef): string;
  end;

implementation

{ TAsWishStructureProvider }

constructor TAsWishStructureProvider.Create(
  AScanService: TAsWishScanService;
  ATreeBuilder: TAsWishTreeBuilder);
begin
  inherited Create;
  FScanService := AScanService;
  FTreeBuilder := ATreeBuilder;
end;

function TAsWishStructureProvider.ProviderId: string;
begin
  Result := 'aswish.structure';
end;

function TAsWishStructureProvider.GetTreeNames: TArray<string>;
begin
  Result := ['Files', 'Function Tree', 'Module Tree', 'View Tree', 'Data Tree'];
end;

function TAsWishStructureProvider.CategoryToRef(ACat: TFileCategory): TShellObjectRef;
const
  CAT_NAMES: array[TFileCategory] of string = (
    'Ignored', 'AI Rules', 'Documents', 'UI', 'Code', 'Config', 'Unknown'
  );
begin
  Result := TShellObjectRef.Make(
    'cat-' + CAT_NAMES[ACat].ToLower,
    'category',
    ProviderId,
    CAT_NAMES[ACat]);
end;

function TAsWishStructureProvider.SpecNodeToRef(const ANode: TSpecNode): TShellObjectRef;
begin
  Result := TShellObjectRef.Make(
    ANode.Id,
    ANode.Kind,
    ProviderId,
    ANode.Title);
end;

function TAsWishStructureProvider.FindChildNodes(const AParentId: string;
  ANodes: TList<TSpecNode>): TArray<TShellObjectRef>;
var
  LList: TList<TShellObjectRef>;
begin
  LList := TList<TShellObjectRef>.Create;
  try
    for var LNode in ANodes do
      if LNode.ParentId = AParentId then
        LList.Add(SpecNodeToRef(LNode));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TAsWishStructureProvider.GetRootNodes(
  const ATreeName: string): TArray<TShellObjectRef>;
var
  LList: TList<TShellObjectRef>;
begin
  if (FScanService = nil) or (FScanService.TotalFiles = 0) then
  begin
    // No scan data yet
    SetLength(Result, 1);
    if ATreeName = 'Files' then
      Result[0] := TShellObjectRef.Make('no-scan', 'folder', ProviderId,
        '(no project scanned)')
    else
      Result[0] := TShellObjectRef.Make('no-scan', 'tree', ProviderId,
        '(scan a project to populate)');
    Exit;
  end;

  if ATreeName = 'Files' then
  begin
    // Show category groups: Documents, Code, UI, Config, AI Rules
    LList := TList<TShellObjectRef>.Create;
    try
      if FScanService.CategoryCount(fcDocuments) > 0 then
        LList.Add(CategoryToRef(fcDocuments));
      if FScanService.CategoryCount(fcCode) > 0 then
        LList.Add(CategoryToRef(fcCode));
      if FScanService.CategoryCount(fcUI) > 0 then
        LList.Add(CategoryToRef(fcUI));
      if FScanService.CategoryCount(fcConfig) > 0 then
        LList.Add(CategoryToRef(fcConfig));
      if FScanService.CategoryCount(fcAiRules) > 0 then
        LList.Add(CategoryToRef(fcAiRules));
      Result := LList.ToArray;
    finally
      LList.Free;
    end;
  end
  else if ATreeName = 'Function Tree' then
    Result := FindChildNodes('', FTreeBuilder.FunctionNodes)
  else if ATreeName = 'Module Tree' then
    Result := FindChildNodes('', FTreeBuilder.ModuleNodes)
  else if ATreeName = 'View Tree' then
    Result := FindChildNodes('', FTreeBuilder.ViewNodes)
  else if ATreeName = 'Data Tree' then
    Result := FindChildNodes('', FTreeBuilder.DataNodes)
  else
    Result := [];
end;

function TAsWishStructureProvider.HasChildren(const ANode: TShellObjectRef): Boolean;
begin
  if ANode.Kind = 'category' then
  begin
    // Categories always have children (files)
    Result := True;
    Exit;
  end;

  // Spec nodes: check if any node has this one as parent
  if FTreeBuilder <> nil then
  begin
    for var LNode in FTreeBuilder.FunctionNodes do
      if LNode.ParentId = ANode.Id then Exit(True);
    for var LNode in FTreeBuilder.ModuleNodes do
      if LNode.ParentId = ANode.Id then Exit(True);
    for var LNode in FTreeBuilder.ViewNodes do
      if LNode.ParentId = ANode.Id then Exit(True);
    for var LNode in FTreeBuilder.DataNodes do
      if LNode.ParentId = ANode.Id then Exit(True);
  end;

  Result := False;
end;

function TAsWishStructureProvider.GetChildren(
  const ANode: TShellObjectRef): TArray<TShellObjectRef>;
var
  LList: TList<TShellObjectRef>;
  LCat: TFileCategory;
  LFiles: TArray<string>;
begin
  if ANode.Kind = 'category' then
  begin
    // Map display name back to category
    LCat := fcUnknown;
    if ANode.DisplayName = 'Documents' then LCat := fcDocuments
    else if ANode.DisplayName = 'Code' then LCat := fcCode
    else if ANode.DisplayName = 'UI' then LCat := fcUI
    else if ANode.DisplayName = 'Config' then LCat := fcConfig
    else if ANode.DisplayName = 'AI Rules' then LCat := fcAiRules;

    LFiles := FScanService.GetFilesByCategory(LCat);
    LList := TList<TShellObjectRef>.Create;
    try
      for var LFile in LFiles do
        LList.Add(TShellObjectRef.Make(
          'file:' + LFile, 'file', ProviderId, LFile));
      Result := LList.ToArray;
    finally
      LList.Free;
    end;
    Exit;
  end;

  // Spec node children
  LList := TList<TShellObjectRef>.Create;
  try
    if FTreeBuilder <> nil then
    begin
      for var LNode in FTreeBuilder.FunctionNodes do
        if LNode.ParentId = ANode.Id then
          LList.Add(SpecNodeToRef(LNode));
      for var LNode in FTreeBuilder.ModuleNodes do
        if LNode.ParentId = ANode.Id then
          LList.Add(SpecNodeToRef(LNode));
      for var LNode in FTreeBuilder.ViewNodes do
        if LNode.ParentId = ANode.Id then
          LList.Add(SpecNodeToRef(LNode));
      for var LNode in FTreeBuilder.DataNodes do
        if LNode.ParentId = ANode.Id then
          LList.Add(SpecNodeToRef(LNode));
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TAsWishStructureProvider.GetDisplayText(const ANode: TShellObjectRef): string;
begin
  Result := ANode.DisplayName;
end;

end.
