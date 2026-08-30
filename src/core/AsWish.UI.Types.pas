{ ============================================================================
  AsWish.UI.Types
  ---------------------------------------------------------------------------
  Decoupled UI and desktop shell data types for AsWish.
  Contains no dependency on external or closed-source frameworks.
  ============================================================================ }

unit AsWish.UI.Types;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Menus;

type
  // ---------------------------------------------------------------------------
  // Stable references and context
  // ---------------------------------------------------------------------------

  TShellObjectRef = record
    Id: string;
    Kind: string;
    ProviderId: string;
    DisplayName: string;
    class function Empty: TShellObjectRef; static;
    function IsEmpty: Boolean;
    class function Make(const AId, AKind, AProviderId, ADisplayName: string): TShellObjectRef; static;
  end;

  TShellContext = record
    ProjectId: string;
    ProjectPath: string;
    ObjectRef: TShellObjectRef;
    ViewId: string;
    ViewType: string;
    Revision: Int64;
    class function Empty: TShellContext; static;
    function HasProject: Boolean;
    procedure Clear;
  end;

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  TShellRiskLevel = type Integer;

const
  rlReadOnly  = 0;
  rlLow       = 1;
  rlMedium    = 2;
  rlHigh      = 3;

type
  TShellCommandCategory = (
    sccFile,
    sccEdit,
    sccView,
    sccProject,
    sccTools,
    sccHelp,
    sccCustom
  );

  TShellCommand = record
    Id: string;
    Caption: string;
    Hint: string;
    Category: string;
    ShortcutText: string;
    Visible: Boolean;
    Enabled: Boolean;
    Checked: Boolean;
    CapabilityId: string;
    GateKey: string;
    RiskLevel: TShellRiskLevel;
    PurposeKey: string;
    RequiresEvidence: Boolean;
    Handler: TProc;
    class function Make(const AId, ACaption: string): TShellCommand; static;
  end;

  // ---------------------------------------------------------------------------
  // Shell Events
  // ---------------------------------------------------------------------------

  TDeepShellEventKind = (
    sekProjectOpened,
    sekProjectClosed,
    sekContextChanged,
    sekObjectSelected,
    sekViewChanged,
    sekLayoutChanged,
    sekLogAdded,
    sekIssueAdded,
    sekTaskStarted,
    sekTaskProgress,
    sekTaskFinished,
    sekServiceStatusChanged,
    sekCommandExecuted,
    sekCommandRejected,
    sekCommandStateChanged
  );

  TDeepShellEvent = record
    Kind: TDeepShellEventKind;
    Context: TShellContext;
    ObjectRef: TShellObjectRef;
    MessageText: string;
    Data: string;
  end;

  TShellEventHandler = reference to procedure(const AEvent: TDeepShellEvent);

  // ---------------------------------------------------------------------------
  // Layout / Panels
  // ---------------------------------------------------------------------------

  TShellPanelState = record
    PanelId: string;
    Visible: Boolean;
    Collapsed: Boolean;
    Size: Integer;
    LastExpandedSize: Integer;
    ActiveTabId: string;
    class function Make(const APanelId: string): TShellPanelState; static;
  end;

  TShellToolWindowState = record
    WindowId: string;
    Visible: Boolean;
    Pinned: Boolean;
    Locked: Boolean;
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
    ActiveTabId: string;
    class function Make(const AWindowId: string): TShellToolWindowState; static;
  end;

  TShellLayoutState = record
    LayoutKey: string;
    UpdatedAt: TDateTime;
    Sequence: Int64;
    WriterInstanceId: string;
    MainLeft: Integer;
    MainTop: Integer;
    MainWidth: Integer;
    MainHeight: Integer;
    Maximized: Boolean;
    TopPanel: TShellPanelState;
    MiddlePanel: TShellPanelState;
    BottomPanel: TShellPanelState;
    LeftToolWindow: TShellToolWindowState;
    RightToolWindow: TShellToolWindowState;
    CurrentViewId: string;
    CurrentTabId: string;
    class function Empty: TShellLayoutState; static;
  end;

  // ---------------------------------------------------------------------------
  // Recent / MRU
  // ---------------------------------------------------------------------------

  TShellRecentKind = (rkProject, rkFile, rkView, rkCommand);

  TShellRecentItem = record
    Kind: TShellRecentKind;
    ItemKey: string;
    ProjectId: string;
    Path: string;
    DisplayName: string;
    LayoutKey: string;
    LastOpenedAt: TDateTime;
    Invalid: Boolean;
  end;

  // ---------------------------------------------------------------------------
  // Views
  // ---------------------------------------------------------------------------

  TShellViewKind = (
    svkControl,
    svkFrame,
    svkHtml,
    svkMarkdown,
    svkText,
    svkExternal
  );

  TShellViewInfo = record
    ViewId: string;
    ViewKind: TShellViewKind;
    Title: string;
    Content: string;
    class function Make(const AViewId: string; AKind: TShellViewKind;
      const ATitle, AContent: string): TShellViewInfo; static;
  end;

  // ---------------------------------------------------------------------------
  // Inspector Data
  // ---------------------------------------------------------------------------

  TShellProperty = record
    Name: string;
    Value: string;
    Group: string;
    ReadOnly: Boolean;
  end;

  TShellRelation = record
    Name: string;
    TargetRef: TShellObjectRef;
    Kind: string;
  end;

  TShellIssueSeverity = (sisInfo, sisWarning, sisError);

  TShellIssue = record
    Id: string;
    Message: string;
    Severity: TShellIssueSeverity;
    Location: string;
  end;

  // ---------------------------------------------------------------------------
  // Status Entries
  // ---------------------------------------------------------------------------

  TShellStatusKind = (sskInfo, sskWarning, sskError, sskProgress, sskDiagnostic);

  TShellStatusEntry = record
    Kind: TShellStatusKind;
    Source: string;
    MessageText: string;
    Detail: string;
    PercentComplete: Integer;
    TaskId: string;
    Timestamp: TDateTime;
  end;

implementation

{ TShellObjectRef }

class function TShellObjectRef.Empty: TShellObjectRef;
begin
  Result.Id := '';
  Result.Kind := '';
  Result.ProviderId := '';
  Result.DisplayName := '';
end;

function TShellObjectRef.IsEmpty: Boolean;
begin
  Result := (Id = '') and (ProviderId = '');
end;

class function TShellObjectRef.Make(const AId, AKind, AProviderId,
  ADisplayName: string): TShellObjectRef;
begin
  Result.Id := AId;
  Result.Kind := AKind;
  Result.ProviderId := AProviderId;
  Result.DisplayName := ADisplayName;
end;

{ TShellContext }

class function TShellContext.Empty: TShellContext;
begin
  Result.ProjectId := '';
  Result.ProjectPath := '';
  Result.ObjectRef := TShellObjectRef.Empty;
  Result.ViewId := '';
  Result.ViewType := '';
  Result.Revision := 0;
end;

function TShellContext.HasProject: Boolean;
begin
  Result := (ProjectId <> '') or (ProjectPath <> '');
end;

procedure TShellContext.Clear;
begin
  ProjectId := '';
  ProjectPath := '';
  ObjectRef := TShellObjectRef.Empty;
  ViewId := '';
  ViewType := '';
  Revision := 0;
end;

{ TShellCommand }

class function TShellCommand.Make(const AId, ACaption: string): TShellCommand;
begin
  Result.Id := AId;
  Result.Caption := ACaption;
  Result.Hint := '';
  Result.Category := '';
  Result.ShortcutText := '';
  Result.Visible := True;
  Result.Enabled := True;
  Result.Checked := False;
  Result.CapabilityId := '';
  Result.GateKey := '';
  Result.RiskLevel := rlReadOnly;
  Result.PurposeKey := '';
  Result.RequiresEvidence := False;
  Result.Handler := nil;
end;

{ TShellPanelState }

class function TShellPanelState.Make(const APanelId: string): TShellPanelState;
begin
  Result.PanelId := APanelId;
  Result.Visible := True;
  Result.Collapsed := False;
  Result.Size := 200;
  Result.LastExpandedSize := 200;
  Result.ActiveTabId := '';
end;

{ TShellToolWindowState }

class function TShellToolWindowState.Make(
  const AWindowId: string): TShellToolWindowState;
begin
  Result.WindowId := AWindowId;
  Result.Visible := True;
  Result.Pinned := True;
  Result.Locked := False;
  Result.Left := 0;
  Result.Top := 0;
  Result.Width := 250;
  Result.Height := 400;
  Result.ActiveTabId := '';
end;

{ TShellLayoutState }

class function TShellLayoutState.Empty: TShellLayoutState;
begin
  Result.LayoutKey := '';
  Result.UpdatedAt := 0;
  Result.Sequence := 0;
  Result.WriterInstanceId := '';
  Result.MainLeft := 100;
  Result.MainTop := 100;
  Result.MainWidth := 1200;
  Result.MainHeight := 800;
  Result.Maximized := False;
  Result.TopPanel := TShellPanelState.Make('top');
  Result.MiddlePanel := TShellPanelState.Make('middle');
  Result.BottomPanel := TShellPanelState.Make('bottom');
  Result.LeftToolWindow := TShellToolWindowState.Make('left');
  Result.RightToolWindow := TShellToolWindowState.Make('right');
  Result.CurrentViewId := '';
  Result.CurrentTabId := '';
end;

{ TShellViewInfo }

class function TShellViewInfo.Make(const AViewId: string; AKind: TShellViewKind;
  const ATitle, AContent: string): TShellViewInfo;
begin
  Result.ViewId := AViewId;
  Result.ViewKind := AKind;
  Result.Title := ATitle;
  Result.Content := AContent;
end;

end.
