{ ============================================================================
  AsWish.Providers.Inspector

  Inspector provider - shows properties of the selected node in the
  right tool window.
  ============================================================================ }

unit AsWish.Providers.Inspector;

interface

uses
  System.SysUtils,
  AsWish.UI.Intf,
  AsWish.UI.Types,
  AsWish.Models;

type
  TNodeLookupFunc = reference to function(const ANodeId: string): TSpecNode;

  TAsWishInspectorProvider = class(TInterfacedObject, IShellInspectorProvider)
  private
    FNodeLookup: TNodeLookupFunc;
  public
    constructor Create(ALookup: TNodeLookupFunc);
    function ProviderId: string;
    function CanInspect(const ARef: TShellObjectRef): Boolean;
    function GetProperties(const ARef: TShellObjectRef): TArray<TShellProperty>;
    function GetRelations(const ARef: TShellObjectRef): TArray<TShellRelation>;
    function GetIssues(const ARef: TShellObjectRef): TArray<TShellIssue>;
  end;

implementation

constructor TAsWishInspectorProvider.Create(ALookup: TNodeLookupFunc);
begin
  inherited Create;
  FNodeLookup := ALookup;
end;

function TAsWishInspectorProvider.ProviderId: string;
begin
  Result := 'aswish.inspector';
end;

function TAsWishInspectorProvider.CanInspect(const ARef: TShellObjectRef): Boolean;
begin
  Result := ARef.ProviderId = 'aswish';
end;

function TAsWishInspectorProvider.GetProperties(const ARef: TShellObjectRef): TArray<TShellProperty>;
var
  LNode: TSpecNode;
begin
  SetLength(Result, 3);

  Result[0].Name := 'ID';
  Result[0].Value := ARef.Id;

  Result[1].Name := 'Kind';
  Result[1].Value := ARef.Kind;

  Result[2].Name := 'Status';
  if Assigned(FNodeLookup) then
  begin
    LNode := FNodeLookup(ARef.Id);
    if LNode.Id <> '' then
      Result[2].Value := TSpecEnums.NodeStatusToStr(LNode.Status)
    else
      Result[2].Value := '(unknown)';
  end
  else
    Result[2].Value := '(no lookup)';
end;

function TAsWishInspectorProvider.GetRelations(const ARef: TShellObjectRef): TArray<TShellRelation>;
begin
  Result := [];
end;

function TAsWishInspectorProvider.GetIssues(const ARef: TShellObjectRef): TArray<TShellIssue>;
begin
  Result := [];
end;

end.
