{ ============================================================================
  AsWish.UI.Intf
  ---------------------------------------------------------------------------
  Decoupled UI and desktop shell interface contracts for AsWish.
  All providers, commands and services interact with the shell through these
  interfaces, allowing AsWish to run with any pluggable shell implementation
  without concrete dependencies on closed-source frameworks.
  ============================================================================ }

unit AsWish.UI.Intf;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  AsWish.UI.Types;

const
  CAP_SHELL_RECENT = 'shell.recent';
  CAP_SHELL_SETTINGS = 'shell.settings';
  CAP_SHELL_LAYOUT = 'shell.layout';

type
  // ---------------------------------------------------------------------------
  // Service Registry
  // ---------------------------------------------------------------------------
  IShellServiceRegistry = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A001}']
    procedure RegisterService(const AServiceId: string; const AService: IInterface);
    function TryGetService(const AServiceId: string; out AService: IInterface): Boolean;
    function SupportsCapability(const ACapabilityId: string): Boolean;
    function ServiceIds: TArray<string>;
  end;

  // ---------------------------------------------------------------------------
  // Event Bus
  // ---------------------------------------------------------------------------
  IShellEventBus = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A002}']
    function Subscribe(AKind: TDeepShellEventKind; AHandler: TShellEventHandler): string;
    function SubscribeAll(AHandler: TShellEventHandler): string;
    procedure Unsubscribe(const AToken: string);
    procedure Publish(const AEvent: TDeepShellEvent);
    procedure Shutdown;
    procedure SetOnDispatchError(AHandler: TProc<Exception, string>);
  end;

  // ---------------------------------------------------------------------------
  // Context Manager
  // ---------------------------------------------------------------------------
  IShellContextManager = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A003}']
    function Current: TShellContext;
    procedure SetProject(const AProjectId, APath: string);
    procedure SetObject(const ARef: TShellObjectRef);
    procedure SetView(const AViewId, AViewType: string);
    procedure ClearProject;
  end;

  // ---------------------------------------------------------------------------
  // Command Manager
  // ---------------------------------------------------------------------------
  IShellCommandManager = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A004}']
    procedure RegisterCommand(const ACommand: TShellCommand);
    procedure UnregisterCommand(const ACommandId: string);
    procedure ExecuteCommand(const ACommandId: string);
    function CanExecute(const ACommandId: string): Boolean;
    function Commands: TArray<TShellCommand>;
    function GetCommand(const ACommandId: string; out ACommand: TShellCommand): Boolean;
    procedure UpdateAllCommands;
  end;

  // ---------------------------------------------------------------------------
  // Status Manager
  // ---------------------------------------------------------------------------
  TShellStatusSanitizer = reference to function(const ASource, AMessage: string): string;

  IShellStatusManager = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A005}']
    procedure Info(const ASource, AMessage: string);
    procedure Warning(const ASource, AMessage: string);
    procedure LogError(const ASource, AMessage, ADetail: string);
    procedure ShellError(const ASource, AMessage, ADetail: string);
    procedure Progress(const ATaskId, ASource: string; APercent: Integer; const AMessage: string);
    procedure TaskStart(const ATaskId, ASource, AMessage: string);
    procedure TaskFinish(const ATaskId, AMessage: string);
    procedure Diagnostic(const ASource, AMessage: string);
    function GetEntries: TArray<TShellStatusEntry>;
    procedure ClearEntries;
    procedure SetSanitizer(ASanitizer: TShellStatusSanitizer);
  end;

  // ---------------------------------------------------------------------------
  // Structure Provider (Left tree)
  // ---------------------------------------------------------------------------
  IShellStructureProvider = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A006}']
    function ProviderId: string;
    function GetTreeNames: TArray<string>;
    function GetRootNodes(const ATreeName: string): TArray<TShellObjectRef>;
    function HasChildren(const ANode: TShellObjectRef): Boolean;
    function GetChildren(const ANode: TShellObjectRef): TArray<TShellObjectRef>;
    function GetDisplayText(const ANode: TShellObjectRef): string;
  end;

  // ---------------------------------------------------------------------------
  // Main View Provider (Center view)
  // ---------------------------------------------------------------------------
  IShellMainViewProvider = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A007}']
    function ProviderId: string;
    function CanOpen(const ARef: TShellObjectRef): Boolean;
    function GetViewForObject(const ARef: TShellObjectRef): TShellViewInfo;
    function CreateViewControl(AOwner: TComponent;
      const ARef: TShellObjectRef; const AInfo: TShellViewInfo): TControl;
  end;

  IShellViewProvider = IShellMainViewProvider;

  // ---------------------------------------------------------------------------
  // Inspector Provider (Right properties)
  // ---------------------------------------------------------------------------
  IShellInspectorProvider = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A008}']
    function ProviderId: string;
    function CanInspect(const ARef: TShellObjectRef): Boolean;
    function GetProperties(const ARef: TShellObjectRef): TArray<TShellProperty>;
    function GetRelations(const ARef: TShellObjectRef): TArray<TShellRelation>;
    function GetIssues(const ARef: TShellObjectRef): TArray<TShellIssue>;
  end;

  // ---------------------------------------------------------------------------
  // Settings Page Provider (Preferences dialog)
  // ---------------------------------------------------------------------------
  ISettingsPageProvider = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A009}']
    function PageId: string;
    function Caption: string;
    function GroupName: string;
    function CreatePage(AOwner: TComponent): TControl;
    procedure Apply;
    procedure Cancel;
    procedure RestoreDefaults;
  end;

  // ---------------------------------------------------------------------------
  // Settings Store
  // ---------------------------------------------------------------------------
  IShellSettingsStore = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A00A}']
    function ReadString(const AKey, ADefault: string): string;
    procedure WriteString(const AKey, AValue: string);
    function ReadBool(const AKey: string; ADefault: Boolean): Boolean;
    procedure WriteBool(const AKey: string; AValue: Boolean);
    function ReadInteger(const AKey: string; ADefault: Integer): Integer;
    procedure WriteInteger(const AKey: string; AValue: Integer);
    procedure RemoveKey(const AKey: string);
  end;

  // ---------------------------------------------------------------------------
  // Recent Service (MRU)
  // ---------------------------------------------------------------------------
  IShellRecentService = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A00B}']
    procedure AddRecent(const AItem: TShellRecentItem);
    procedure AddRecentProject(const AProjectId, APath, ADisplayName, ALayoutKey: string);
    function GetRecent(AKind: TShellRecentKind): TArray<TShellRecentItem>;
    function GetRecentProjects: TArray<TShellRecentItem>;
    procedure MarkInvalid(AKind: TShellRecentKind; const AItemKey: string);
    procedure Remove(AKind: TShellRecentKind; const AItemKey: string);
    procedure Clear;
  end;

  // ---------------------------------------------------------------------------
  // Layout Service
  // ---------------------------------------------------------------------------
  IShellLayoutService = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A00C}']
    procedure SaveGlobalLayout(const AState: TShellLayoutState);
    function TryLoadGlobalLayout(out AState: TShellLayoutState): Boolean;
    procedure SaveProjectLayout(const AProjectId: string; const AState: TShellLayoutState);
    function TryLoadProjectLayout(const AProjectId: string; out AState: TShellLayoutState): Boolean;
    procedure ResetGlobalLayout;
    procedure ResetProjectLayout(const AProjectId: string);
  end;

  // ---------------------------------------------------------------------------
  // Localization Service
  // ---------------------------------------------------------------------------
  IShellLocalizationService = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A00D}']
    function CurrentLocale: string;
    procedure SetLocale(const ALocale: string);
    function GetText(const AKey: string; const ADefault: string = ''): string;
    procedure RegisterText(const ALocale, AKey, AValue: string);
    function SupportedLocales: TArray<string>;
  end;

implementation

end.
