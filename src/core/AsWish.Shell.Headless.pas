{ ============================================================================
  AsWish.Shell.Headless
  ---------------------------------------------------------------------------
  Implementations of the shell contracts that need no window: a status manager
  that writes to the console, an in-memory context, and an event bus that
  dispatches in-process.

  These exist because the orchestration in TAsWishController was only ever
  driven by the desktop shell. The CLI wanted to reuse that orchestration
  instead of keeping a second copy, but the only implementations of these
  three interfaces lived in a VCL form unit, so a console program could not
  build a Controller at all.
  ============================================================================ }

unit AsWish.Shell.Headless;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  AsWish.UI.Types,
  AsWish.UI.Intf;

type
  /// <summary>Status channel that writes one line per event to the console.
  ///  Pass ASilent to keep the entries without printing them, which is what
  ///  the tests use so a scan does not flood the test output.</summary>
  TConsoleStatusManager = class(TInterfacedObject, IShellStatusManager)
  private
    FSilent: Boolean;
    FEntries: TList<TShellStatusEntry>;
    FSanitizer: TShellStatusSanitizer;
    procedure AddEntry(AKind: TShellStatusKind; const ASource, AMessage: string;
      APercent: Integer = 0; const ATaskId: string = '';
      const ADetail: string = '');
    function Sanitize(const ASource, AMessage: string): string;
  public
    constructor Create(ASilent: Boolean = False);
    destructor Destroy; override;
    procedure Info(const ASource, AMessage: string);
    procedure Warning(const ASource, AMessage: string);
    procedure LogError(const ASource, AMessage, ADetail: string);
    procedure ShellError(const ASource, AMessage, ADetail: string);
    procedure Progress(const ATaskId, ASource: string; APercent: Integer;
      const AMessage: string);
    procedure TaskStart(const ATaskId, ASource, AMessage: string);
    procedure TaskFinish(const ATaskId, AMessage: string);
    procedure Diagnostic(const ASource, AMessage: string);
    function GetEntries: TArray<TShellStatusEntry>;
    procedure ClearEntries;
    procedure SetSanitizer(ASanitizer: TShellStatusSanitizer);
  end;

  /// <summary>Context that only remembers: the desktop shell also drives
  ///  views and selections, but a headless run has nothing to select.</summary>
  THeadlessContextManager = class(TInterfacedObject, IShellContextManager)
  private
    FContext: TShellContext;
  public
    function Current: TShellContext;
    procedure SetProject(const AProjectId, APath: string);
    procedure SetObject(const ARef: TShellObjectRef);
    procedure SetView(const AViewId, AViewType: string);
    procedure ClearProject;
  end;

  /// <summary>Event bus that dispatches to in-process subscribers. Nobody is
  ///  required to subscribe: with no listeners Publish is a no-op, which is
  ///  what a CLI run does with the scan-complete event.</summary>
  THeadlessEventBus = class(TInterfacedObject, IShellEventBus)
  private
    FKindHandlers: TDictionary<string, TPair<TDeepShellEventKind, TShellEventHandler>>;
    FAllHandlers: TDictionary<string, TShellEventHandler>;
    FNextToken: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(AKind: TDeepShellEventKind;
      AHandler: TShellEventHandler): string;
    function SubscribeAll(AHandler: TShellEventHandler): string;
    procedure Unsubscribe(const AToken: string);
    procedure Publish(const AEvent: TDeepShellEvent);
    procedure Shutdown;
    procedure SetOnDispatchError(AHandler: TProc<Exception, string>);
  end;

implementation

{ TConsoleStatusManager }

constructor TConsoleStatusManager.Create(ASilent: Boolean = False);
begin
  inherited Create;
  FSilent := ASilent;
  FEntries := TList<TShellStatusEntry>.Create;
end;

destructor TConsoleStatusManager.Destroy;
begin
  FEntries.Free;
  inherited;
end;

function TConsoleStatusManager.Sanitize(const ASource, AMessage: string): string;
begin
  if Assigned(FSanitizer) then
    Result := FSanitizer(ASource, AMessage)
  else
    Result := AMessage;
end;

procedure TConsoleStatusManager.AddEntry(AKind: TShellStatusKind;
  const ASource, AMessage: string; APercent: Integer = 0;
  const ATaskId: string = ''; const ADetail: string = '');
begin
  var LEntry: TShellStatusEntry;
  LEntry.Kind := AKind;
  LEntry.Source := ASource;
  LEntry.MessageText := AMessage;
  LEntry.PercentComplete := APercent;
  LEntry.TaskId := ATaskId;
  LEntry.Detail := ADetail;
  LEntry.Timestamp := Now;
  FEntries.Add(LEntry);
end;

procedure TConsoleStatusManager.Info(const ASource, AMessage: string);
begin
  var LText := Sanitize(ASource, AMessage);
  AddEntry(sskInfo, ASource, LText);
  if not FSilent then
    Writeln(Format('[%s] %s', [ASource, LText]));
end;

procedure TConsoleStatusManager.Warning(const ASource, AMessage: string);
begin
  var LText := Sanitize(ASource, AMessage);
  AddEntry(sskWarning, ASource, LText);
  if not FSilent then
    Writeln(Format('[%s] warning: %s', [ASource, LText]));
end;

procedure TConsoleStatusManager.LogError(const ASource, AMessage, ADetail: string);
begin
  AddEntry(sskError, ASource, AMessage, 0, '', ADetail);
  if not FSilent then
  begin
    Writeln(Format('[%s] error: %s', [ASource, AMessage]));
    if ADetail <> '' then
      Writeln('  ' + ADetail);
  end;
end;

procedure TConsoleStatusManager.ShellError(const ASource, AMessage, ADetail: string);
begin
  LogError(ASource, AMessage, ADetail);
end;

procedure TConsoleStatusManager.Progress(const ATaskId, ASource: string;
  APercent: Integer; const AMessage: string);
begin
  var LText := Sanitize(ASource, AMessage);
  AddEntry(sskProgress, ASource, LText, APercent, ATaskId);
  if not FSilent then
    Writeln(Format('[%s] %3d%% %s', [ASource, APercent, LText]));
end;

procedure TConsoleStatusManager.TaskStart(const ATaskId, ASource, AMessage: string);
begin
  var LText := Sanitize(ASource, AMessage);
  AddEntry(sskProgress, ASource, LText, 0, ATaskId);
  if not FSilent then
    Writeln(Format('[%s] %s', [ASource, LText]));
end;

procedure TConsoleStatusManager.TaskFinish(const ATaskId, AMessage: string);
begin
  // TaskFinish carries no source of its own; the task id is the source here.
  AddEntry(sskProgress, ATaskId, AMessage, 100, ATaskId);
  if not FSilent then
    Writeln(Format('[%s] %s', [ATaskId, AMessage]));
end;

procedure TConsoleStatusManager.Diagnostic(const ASource, AMessage: string);
begin
  // Recorded but not printed: diagnostics belong to a diagnostics pane, and
  // a console run would otherwise be buried in them.
  AddEntry(sskDiagnostic, ASource, AMessage);
end;

function TConsoleStatusManager.GetEntries: TArray<TShellStatusEntry>;
begin
  Result := FEntries.ToArray;
end;

procedure TConsoleStatusManager.ClearEntries;
begin
  FEntries.Clear;
end;

procedure TConsoleStatusManager.SetSanitizer(ASanitizer: TShellStatusSanitizer);
begin
  FSanitizer := ASanitizer;
end;

{ THeadlessContextManager }

function THeadlessContextManager.Current: TShellContext;
begin
  Result := FContext;
end;

procedure THeadlessContextManager.SetProject(const AProjectId, APath: string);
begin
  FContext.ProjectId := AProjectId;
  FContext.ProjectPath := APath;
  Inc(FContext.Revision);
end;

procedure THeadlessContextManager.SetObject(const ARef: TShellObjectRef);
begin
  FContext.ObjectRef := ARef;
  Inc(FContext.Revision);
end;

procedure THeadlessContextManager.SetView(const AViewId, AViewType: string);
begin
  FContext.ViewId := AViewId;
  FContext.ViewType := AViewType;
  Inc(FContext.Revision);
end;

procedure THeadlessContextManager.ClearProject;
begin
  FContext.Clear;
  Inc(FContext.Revision);
end;

{ THeadlessEventBus }

constructor THeadlessEventBus.Create;
begin
  inherited Create;
  FKindHandlers := TDictionary<string,
    TPair<TDeepShellEventKind, TShellEventHandler>>.Create;
  FAllHandlers := TDictionary<string, TShellEventHandler>.Create;
  FNextToken := 0;
end;

destructor THeadlessEventBus.Destroy;
begin
  FKindHandlers.Free;
  FAllHandlers.Free;
  inherited;
end;

function THeadlessEventBus.Subscribe(AKind: TDeepShellEventKind;
  AHandler: TShellEventHandler): string;
begin
  Inc(FNextToken);
  Result := 'sub-' + FNextToken.ToString;
  FKindHandlers.Add(Result,
    TPair<TDeepShellEventKind, TShellEventHandler>.Create(AKind, AHandler));
end;

function THeadlessEventBus.SubscribeAll(AHandler: TShellEventHandler): string;
begin
  Inc(FNextToken);
  Result := 'all-' + FNextToken.ToString;
  FAllHandlers.Add(Result, AHandler);
end;

procedure THeadlessEventBus.Unsubscribe(const AToken: string);
begin
  FKindHandlers.Remove(AToken);
  FAllHandlers.Remove(AToken);
end;

procedure THeadlessEventBus.Publish(const AEvent: TDeepShellEvent);
begin
  // Copy the handler lists first: a handler may unsubscribe itself.
  for var LPair in FKindHandlers.ToArray do
    if LPair.Value.Key = AEvent.Kind then
      LPair.Value.Value(AEvent);
  for var LHandler in FAllHandlers.ToArray do
    LHandler.Value(AEvent);
end;

procedure THeadlessEventBus.Shutdown;
begin
  FKindHandlers.Clear;
  FAllHandlers.Clear;
end;

procedure THeadlessEventBus.SetOnDispatchError(AHandler: TProc<Exception, string>);
begin
  // Errors are not swallowed here; there is no dispatch thread to protect.
end;

end.
