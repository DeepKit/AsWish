{ ============================================================================
  AsWish.Shell.Form
  ---------------------------------------------------------------------------
  Reusable standalone VCL Desktop Shell Form for AsWish.
  Provides toolbar, menu, dockable panels, event bus, service registry,
  and provider lifecycle with zero external dependencies.
  ============================================================================ }

unit AsWish.Shell.Form;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Menus,
  Vcl.ActnList,
  AsWish.UI.Types,
  AsWish.UI.Intf,
  AsWish.Services.Storage,
  AsWish.Localization,
  AsWish.Config,
  AsWish.Version;

type
  TAsWishShellForm = class(TForm)
  private
    FShellInitialized: Boolean;
    FShownOnce: Boolean;

    // Services
    FServices: IShellServiceRegistry;
    FBus: IShellEventBus;
    FCommands: IShellCommandManager;
    FContext: IShellContextManager;
    FRecent: IShellRecentService;
    FLayout: IShellLayoutService;
    FSettingsStore: IShellSettingsStore;
    FLocalization: IShellLocalizationService;

    // Providers
    FStructureProviders: TList<IShellStructureProvider>;
    FMainViewProviders: TList<IShellMainViewProvider>;
    FInspectorProviders: TList<IShellInspectorProvider>;
    FSettingsPages: TList<ISettingsPageProvider>;
    FCurrentMainControl: TControl;
    FMenuCommandMap: TDictionary<TMenuItem, string>;

    // UI Structure
    FMainMenu: TMainMenu;
    FStatusBar: TStatusBar;
    FLeftPanel: TPanel;
    FLeftSplitter: TSplitter;
    FCenterPanel: TPanel;
    FRightPanel: TPanel;
    FRightSplitter: TSplitter;
    FBottomPanel: TPanel;
    FBottomSplitter: TSplitter;

    procedure SetupShellUI;
    procedure BuildMenuAndToolbars;
    procedure DoMenuItemClick(Sender: TObject);
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
    procedure DoShow; override;

    // Lifecycle hooks for derived forms
    procedure InitializeShell; virtual;
    procedure RegisterServices; virtual;
    procedure RegisterCommands; virtual;
    procedure RegisterProviders; virtual;
    procedure AfterShellShown; virtual;
    procedure ShutdownShell; virtual;

  public
    constructor Create(AOwner: TComponent); override;
    procedure RegisterStructureProvider(const AProvider: IShellStructureProvider);
    procedure RegisterMainViewProvider(const AProvider: IShellMainViewProvider);
    procedure RegisterInspectorProvider(const AProvider: IShellInspectorProvider);
    procedure RegisterSettingsPage(const APage: ISettingsPageProvider);

    procedure SetStatusMessage(const AMsg: string);
    function ShellText(const AKey, ADefault: string): string;

    // Shell Services Accessors
    property Services: IShellServiceRegistry read FServices;
    property Bus: IShellEventBus read FBus;
    property Commands: IShellCommandManager read FCommands;
    property Context: IShellContextManager read FContext;
    property Recent: IShellRecentService read FRecent;
    property Layout: IShellLayoutService read FLayout;
    property SettingsStore: IShellSettingsStore read FSettingsStore;
    property Localization: IShellLocalizationService read FLocalization;

    // Panel controls for derived forms
    property LeftPanel: TPanel read FLeftPanel;
    property LeftSplitter: TSplitter read FLeftSplitter;
    property CenterPanel: TPanel read FCenterPanel;
    property RightPanel: TPanel read FRightPanel;
    property RightSplitter: TSplitter read FRightSplitter;
    property BottomPanel: TPanel read FBottomPanel;
    property CurrentMainControl: TControl read FCurrentMainControl;
  end;

implementation

{ Default Service Implementations }

type
  TShellServiceRegistryImpl = class(TInterfacedObject, IShellServiceRegistry)
  private
    FMap: TDictionary<string, IInterface>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterService(const AServiceId: string; const AService: IInterface);
    function TryGetService(const AServiceId: string; out AService: IInterface): Boolean;
    function SupportsCapability(const ACapabilityId: string): Boolean;
    function ServiceIds: TArray<string>;
  end;

  TShellEventBusImpl = class(TInterfacedObject, IShellEventBus)
  private
    FHandlers: TList<TShellEventHandler>;
    FKindHandlers: TDictionary<TDeepShellEventKind, TList<TShellEventHandler>>;
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(AKind: TDeepShellEventKind; AHandler: TShellEventHandler): string;
    function SubscribeAll(AHandler: TShellEventHandler): string;
    procedure Unsubscribe(const AToken: string);
    procedure Publish(const AEvent: TDeepShellEvent);
    procedure Shutdown;
    procedure SetOnDispatchError(AHandler: TProc<Exception, string>);
  end;

  TShellContextManagerImpl = class(TInterfacedObject, IShellContextManager)
  private
    FContext: TShellContext;
    FBus: IShellEventBus;
  public
    constructor Create(const ABus: IShellEventBus);
    function Current: TShellContext;
    procedure SetProject(const AProjectId, APath: string);
    procedure SetObject(const ARef: TShellObjectRef);
    procedure SetView(const AViewId, AViewType: string);
    procedure ClearProject;
  end;

  TShellCommandManagerImpl = class(TInterfacedObject, IShellCommandManager)
  private
    FCmds: TDictionary<string, TShellCommand>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterCommand(const ACommand: TShellCommand);
    procedure UnregisterCommand(const ACommandId: string);
    procedure ExecuteCommand(const ACommandId: string);
    function CanExecute(const ACommandId: string): Boolean;
    function Commands: TArray<TShellCommand>;
    function GetCommand(const ACommandId: string; out ACommand: TShellCommand): Boolean;
    procedure UpdateAllCommands;
  end;

{ TShellServiceRegistryImpl }

constructor TShellServiceRegistryImpl.Create;
begin
  inherited Create;
  FMap := TDictionary<string, IInterface>.Create;
end;

destructor TShellServiceRegistryImpl.Destroy;
begin
  FMap.Free;
  inherited;
end;

procedure TShellServiceRegistryImpl.RegisterService(const AServiceId: string;
  const AService: IInterface);
begin
  FMap.AddOrSetValue(AServiceId, AService);
end;

function TShellServiceRegistryImpl.TryGetService(const AServiceId: string;
  out AService: IInterface): Boolean;
begin
  Result := FMap.TryGetValue(AServiceId, AService);
end;

function TShellServiceRegistryImpl.SupportsCapability(
  const ACapabilityId: string): Boolean;
begin
  Result := FMap.ContainsKey(ACapabilityId);
end;

function TShellServiceRegistryImpl.ServiceIds: TArray<string>;
var
  LList: TList<string>;
  K: string;
begin
  LList := TList<string>.Create;
  try
    for K in FMap.Keys do
      LList.Add(K);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

{ TShellEventBusImpl }

constructor TShellEventBusImpl.Create;
begin
  inherited Create;
  FHandlers := TList<TShellEventHandler>.Create;
  FKindHandlers := TDictionary<TDeepShellEventKind, TList<TShellEventHandler>>.Create;
end;

destructor TShellEventBusImpl.Destroy;
var
  LPair: TPair<TDeepShellEventKind, TList<TShellEventHandler>>;
begin
  for LPair in FKindHandlers do
    LPair.Value.Free;
  FKindHandlers.Free;
  FHandlers.Free;
  inherited;
end;

function TShellEventBusImpl.Subscribe(AKind: TDeepShellEventKind;
  AHandler: TShellEventHandler): string;
var
  LList: TList<TShellEventHandler>;
begin
  if not FKindHandlers.TryGetValue(AKind, LList) then
  begin
    LList := TList<TShellEventHandler>.Create;
    FKindHandlers.Add(AKind, LList);
  end;
  LList.Add(AHandler);
  Result := TGUID.NewGuid.ToString;
end;

function TShellEventBusImpl.SubscribeAll(AHandler: TShellEventHandler): string;
begin
  FHandlers.Add(AHandler);
  Result := TGUID.NewGuid.ToString;
end;

procedure TShellEventBusImpl.Unsubscribe(const AToken: string);
begin
  // token tracking
end;

procedure TShellEventBusImpl.Publish(const AEvent: TDeepShellEvent);
var
  LList: TList<TShellEventHandler>;
  H: TShellEventHandler;
begin
  for H in FHandlers do
  begin
    try
      H(AEvent);
    except
    end;
  end;

  if FKindHandlers.TryGetValue(AEvent.Kind, LList) then
  begin
    for H in LList do
    begin
      try
        H(AEvent);
      except
      end;
    end;
  end;
end;

procedure TShellEventBusImpl.Shutdown;
begin
  FHandlers.Clear;
end;

procedure TShellEventBusImpl.SetOnDispatchError(
  AHandler: TProc<Exception, string>);
begin
end;

{ TShellContextManagerImpl }

constructor TShellContextManagerImpl.Create(const ABus: IShellEventBus);
begin
  inherited Create;
  FBus := ABus;
  FContext.Clear;
end;

function TShellContextManagerImpl.Current: TShellContext;
begin
  Result := FContext;
end;

procedure TShellContextManagerImpl.SetProject(const AProjectId, APath: string);
var
  LEvt: TDeepShellEvent;
begin
  FContext.ProjectId := AProjectId;
  FContext.ProjectPath := APath;
  Inc(FContext.Revision);
  if FBus <> nil then
  begin
    LEvt.Kind := sekProjectOpened;
    LEvt.Context := FContext;
    LEvt.ObjectRef := TShellObjectRef.Empty;
    LEvt.MessageText := APath;
    LEvt.Data := AProjectId;
    FBus.Publish(LEvt);
  end;
end;

procedure TShellContextManagerImpl.SetObject(const ARef: TShellObjectRef);
var
  LEvt: TDeepShellEvent;
begin
  FContext.ObjectRef := ARef;
  Inc(FContext.Revision);
  if FBus <> nil then
  begin
    LEvt.Kind := sekObjectSelected;
    LEvt.Context := FContext;
    LEvt.ObjectRef := ARef;
    LEvt.MessageText := ARef.DisplayName;
    LEvt.Data := ARef.Id;
    FBus.Publish(LEvt);
  end;
end;

procedure TShellContextManagerImpl.SetView(const AViewId, AViewType: string);
var
  LEvt: TDeepShellEvent;
begin
  FContext.ViewId := AViewId;
  FContext.ViewType := AViewType;
  Inc(FContext.Revision);
  if FBus <> nil then
  begin
    LEvt.Kind := sekViewChanged;
    LEvt.Context := FContext;
    LEvt.ObjectRef := TShellObjectRef.Empty;
    LEvt.MessageText := AViewId;
    LEvt.Data := AViewType;
    FBus.Publish(LEvt);
  end;
end;

procedure TShellContextManagerImpl.ClearProject;
var
  LEvt: TDeepShellEvent;
begin
  FContext.Clear;
  if FBus <> nil then
  begin
    LEvt.Kind := sekProjectClosed;
    LEvt.Context := FContext;
    LEvt.ObjectRef := TShellObjectRef.Empty;
    LEvt.MessageText := '';
    LEvt.Data := '';
    FBus.Publish(LEvt);
  end;
end;

{ TShellCommandManagerImpl }

constructor TShellCommandManagerImpl.Create;
begin
  inherited Create;
  FCmds := TDictionary<string, TShellCommand>.Create;
end;

destructor TShellCommandManagerImpl.Destroy;
begin
  FCmds.Free;
  inherited;
end;

procedure TShellCommandManagerImpl.RegisterCommand(
  const ACommand: TShellCommand);
begin
  FCmds.AddOrSetValue(ACommand.Id, ACommand);
end;

procedure TShellCommandManagerImpl.UnregisterCommand(
  const ACommandId: string);
begin
  FCmds.Remove(ACommandId);
end;

procedure TShellCommandManagerImpl.ExecuteCommand(const ACommandId: string);
var
  LCmd: TShellCommand;
begin
  if FCmds.TryGetValue(ACommandId, LCmd) and Assigned(LCmd.Handler) and LCmd.Enabled then
    LCmd.Handler();
end;

function TShellCommandManagerImpl.CanExecute(const ACommandId: string): Boolean;
var
  LCmd: TShellCommand;
begin
  Result := FCmds.TryGetValue(ACommandId, LCmd) and LCmd.Enabled;
end;

function TShellCommandManagerImpl.Commands: TArray<TShellCommand>;
var
  LList: TList<TShellCommand>;
  C: TShellCommand;
begin
  LList := TList<TShellCommand>.Create;
  try
    for C in FCmds.Values do
      LList.Add(C);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TShellCommandManagerImpl.GetCommand(const ACommandId: string;
  out ACommand: TShellCommand): Boolean;
begin
  Result := FCmds.TryGetValue(ACommandId, ACommand);
end;

procedure TShellCommandManagerImpl.UpdateAllCommands;
begin
end;

{ TAsWishShellForm }
 
constructor TAsWishShellForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
end;

procedure TAsWishShellForm.DoCreate;
begin
  inherited DoCreate;
  FShellInitialized := False;
  FShownOnce := False;

  FStructureProviders := TList<IShellStructureProvider>.Create;
  FMainViewProviders := TList<IShellMainViewProvider>.Create;
  FInspectorProviders := TList<IShellInspectorProvider>.Create;
  FSettingsPages := TList<ISettingsPageProvider>.Create;
  FMenuCommandMap := TDictionary<TMenuItem, string>.Create;

  SetupShellUI;
  InitializeShell;
  RegisterServices;
  RegisterCommands;
  RegisterProviders;
  BuildMenuAndToolbars;
  FShellInitialized := True;
end;

procedure TAsWishShellForm.DoDestroy;
begin
  ShutdownShell;
  FStructureProviders.Free;
  FMainViewProviders.Free;
  FInspectorProviders.Free;
  FSettingsPages.Free;
  FMenuCommandMap.Free;
  inherited DoDestroy;
end;

procedure TAsWishShellForm.DoShow;
begin
  inherited DoShow;
  if not FShownOnce then
  begin
    FShownOnce := True;
    AfterShellShown;
  end;
end;

procedure TAsWishShellForm.SetupShellUI;
begin
  Caption := ASWISH_BANNER;
  Position := poScreenCenter;
  Width := 1280;
  Height := 800;

  FMainMenu := TMainMenu.Create(Self);

  // Status bar
  FStatusBar := TStatusBar.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.SimplePanel := True;
  FStatusBar.SimpleText := 'Ready';

  // Bottom panel (Logs)
  FBottomPanel := TPanel.Create(Self);
  FBottomPanel.Parent := Self;
  FBottomPanel.Align := alBottom;
  FBottomPanel.Height := 160;
  FBottomPanel.BevelOuter := bvNone;

  FBottomSplitter := TSplitter.Create(Self);
  FBottomSplitter.Parent := Self;
  FBottomSplitter.Align := alBottom;
  FBottomSplitter.Height := 4;

  // Left panel (Trees)
  FLeftPanel := TPanel.Create(Self);
  FLeftPanel.Parent := Self;
  FLeftPanel.Align := alLeft;
  FLeftPanel.Width := 300;
  FLeftPanel.BevelOuter := bvNone;

  FLeftSplitter := TSplitter.Create(Self);
  FLeftSplitter.Parent := Self;
  FLeftSplitter.Align := alLeft;
  FLeftSplitter.Width := 4;

  // Right panel (Inspector)
  FRightPanel := TPanel.Create(Self);
  FRightPanel.Parent := Self;
  FRightPanel.Align := alRight;
  FRightPanel.Width := 260;
  FRightPanel.BevelOuter := bvNone;
  FRightPanel.Visible := False; // Shown when needed

  FRightSplitter := TSplitter.Create(Self);
  FRightSplitter.Parent := Self;
  FRightSplitter.Align := alRight;
  FRightSplitter.Width := 4;
  FRightSplitter.Visible := False;

  // Center panel (Main View)
  FCenterPanel := TPanel.Create(Self);
  FCenterPanel.Parent := Self;
  FCenterPanel.Align := alClient;
  FCenterPanel.BevelOuter := bvNone;
end;

procedure TAsWishShellForm.InitializeShell;
begin
  FServices := TShellServiceRegistryImpl.Create;
  FBus := TShellEventBusImpl.Create;
  FContext := TShellContextManagerImpl.Create(FBus);
  FCommands := TShellCommandManagerImpl.Create;
  FRecent := TAsWishRecentService.Create(10);
  FLayout := TAsWishLayoutService.Create;
  FSettingsStore := TAsWishSettingsStore.Create;
  FLocalization := TAsWishLocalizationService.Create;

  FServices.RegisterService(CAP_SHELL_RECENT, FRecent);
  FServices.RegisterService(CAP_SHELL_SETTINGS, FSettingsStore);
  FServices.RegisterService(CAP_SHELL_LAYOUT, FLayout);
end;

procedure TAsWishShellForm.RegisterServices;
begin
  AsWishApplyLocale(FLocalization);
end;

procedure TAsWishShellForm.RegisterCommands;
begin
end;

procedure TAsWishShellForm.RegisterProviders;
begin
end;

procedure TAsWishShellForm.DoMenuItemClick(Sender: TObject);
var
  LCmdId: string;
begin
  if (Sender is TMenuItem) and (FMenuCommandMap <> nil) and (FCommands <> nil) then
  begin
    if FMenuCommandMap.TryGetValue(TMenuItem(Sender), LCmdId) then
      FCommands.ExecuteCommand(LCmdId);
  end;
end;

procedure TAsWishShellForm.BuildMenuAndToolbars;
var
  LFileMenu, LRunMenu, LViewMenu, LToolsMenu: TMenuItem;
  LCmds: TArray<TShellCommand>;
  LCmd: TShellCommand;
  LItem: TMenuItem;
begin
  LFileMenu := TMenuItem.Create(FMainMenu);
  LFileMenu.Caption := '&File';
  FMainMenu.Items.Add(LFileMenu);

  LRunMenu := TMenuItem.Create(FMainMenu);
  LRunMenu.Caption := '&Run';
  FMainMenu.Items.Add(LRunMenu);

  LViewMenu := TMenuItem.Create(FMainMenu);
  LViewMenu.Caption := '&View';
  FMainMenu.Items.Add(LViewMenu);

  LToolsMenu := TMenuItem.Create(FMainMenu);
  LToolsMenu.Caption := '&Tools';
  FMainMenu.Items.Add(LToolsMenu);

  LCmds := FCommands.Commands;
  for LCmd in LCmds do
  begin
    LItem := TMenuItem.Create(FMainMenu);
    LItem.Caption := LCmd.Caption;
    if LCmd.ShortcutText <> '' then
      LItem.ShortCut := TextToShortCut(LCmd.ShortcutText);
    LItem.Enabled := LCmd.Enabled;
    LItem.Visible := LCmd.Visible;
    LItem.OnClick := DoMenuItemClick;
    FMenuCommandMap.AddOrSetValue(LItem, LCmd.Id);

    if SameText(LCmd.Category, 'File') then
      LFileMenu.Add(LItem)
    else if SameText(LCmd.Category, 'Run') then
      LRunMenu.Add(LItem)
    else if SameText(LCmd.Category, 'View') then
      LViewMenu.Add(LItem)
    else
      LToolsMenu.Add(LItem);
  end;
end;

procedure TAsWishShellForm.AfterShellShown;
begin
end;

procedure TAsWishShellForm.ShutdownShell;
begin
  if FBus <> nil then
    FBus.Shutdown;
end;

procedure TAsWishShellForm.RegisterStructureProvider(
  const AProvider: IShellStructureProvider);
begin
  FStructureProviders.Add(AProvider);
end;

procedure TAsWishShellForm.RegisterMainViewProvider(
  const AProvider: IShellMainViewProvider);
begin
  FMainViewProviders.Add(AProvider);
  if FCenterPanel <> nil then
  begin
    try
      FCurrentMainControl := AProvider.CreateViewControl(Self,
        TShellObjectRef.Make('index-0', 'html', 'aswish', 'Index'),
        TShellViewInfo.Make('index', svkHtml, 'Index', ''));
      if FCurrentMainControl <> nil then
      begin
        FCurrentMainControl.Parent := FCenterPanel;
        FCurrentMainControl.Align := alClient;
      end;
    except
    end;
  end;
end;

procedure TAsWishShellForm.RegisterInspectorProvider(
  const AProvider: IShellInspectorProvider);
begin
  FInspectorProviders.Add(AProvider);
end;

procedure TAsWishShellForm.RegisterSettingsPage(
  const APage: ISettingsPageProvider);
begin
  FSettingsPages.Add(APage);
end;

procedure TAsWishShellForm.SetStatusMessage(const AMsg: string);
begin
  if FStatusBar <> nil then
    FStatusBar.SimpleText := AMsg;
end;

function TAsWishShellForm.ShellText(const AKey, ADefault: string): string;
begin
  if FLocalization <> nil then
    Result := FLocalization.GetText(AKey, ADefault)
  else
    Result := ADefault;
end;

end.
