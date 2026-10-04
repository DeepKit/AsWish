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
  Winapi.Windows,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Menus;

type
  // ---------------------------------------------------------------------------
  // GUI Visual Evidence & Screen Capture Modes (WO-0050 / WO-0057 1.3)
  // ---------------------------------------------------------------------------

  TCaptureMode = (
    cmWindowScreenshot,  // TCustomForm.GetFormImage (PaintTo). Fast; CANNOT reflect live TCheckBox check state.
    cmDirectControlDc    // Direct GetWindowDC + BitBlt on on-screen control. Reflects live TCheckBox check state.
  );

function CaptureModeReflectsLiveState(AMode: TCaptureMode): Boolean;
function BitmapDistinctColors(ABmp: Vcl.Graphics.TBitmap): Integer;
function BitmapDistinctColorsSampled(ABmp: Vcl.Graphics.TBitmap; AStep: Integer = 4): Integer;
function CaptureControlBitmapDirect(AControl: TWinControl; ABmp: Vcl.Graphics.TBitmap; var ADiag: string): Boolean;
function SaveBitmapWithContentGuard(ABmp: Vcl.Graphics.TBitmap; const AFilePath: string;
  var ADiag: string; AStep: Integer = 4): Boolean;

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

uses
  System.IOUtils,
  Vcl.Imaging.pngimage;

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

function CaptureModeReflectsLiveState(AMode: TCaptureMode): Boolean;
begin
  case AMode of
    cmDirectControlDc: Result := True;
  else
    Result := False;
  end;
end;

function BitmapDistinctColorsSampled(ABmp: Vcl.Graphics.TBitmap; AStep: Integer = 4): Integer;
var
  X, Y: Integer;
  LSeen: TStringList;
  LC: TColor;
begin
  Result := 0;
  if (ABmp = nil) or (ABmp.Width <= 0) or (ABmp.Height <= 0) then
    Exit;
  if AStep < 1 then
    AStep := 1;
  LSeen := TStringList.Create;
  try
    LSeen.Sorted := True;
    LSeen.Duplicates := TDuplicates.dupIgnore;
    Y := 0;
    while Y < ABmp.Height do
    begin
      X := 0;
      while X < ABmp.Width do
      begin
        LC := ABmp.Canvas.Pixels[X, Y];
        LSeen.Add(Format('%.6x', [ColorToRGB(LC)]));
        Inc(X, AStep);
      end;
      Inc(Y, AStep);
    end;
    Result := LSeen.Count;
  finally
    LSeen.Free;
  end;
end;

function BitmapDistinctColors(ABmp: Vcl.Graphics.TBitmap): Integer;
begin
  Result := BitmapDistinctColorsSampled(ABmp, 1);
end;

function SaveBitmapWithContentGuard(ABmp: Vcl.Graphics.TBitmap; const AFilePath: string;
  var ADiag: string; AStep: Integer = 4): Boolean;
var
  LDistinct: Integer;
  LPng: TPngImage;
begin
  Result := False;
  ADiag := '';
  if (ABmp = nil) or (ABmp.Width <= 0) or (ABmp.Height <= 0) then
    Exit;
  LDistinct := BitmapDistinctColorsSampled(ABmp, AStep);
  ADiag := Format('screenshot at (%d,%d) distinctColors=%d', [ABmp.Width, ABmp.Height, LDistinct]);
  if LDistinct <= 1 then
  begin
    ADiag := ADiag + '; no visual evidence emitted';
    Exit;
  end;
  TDirectory.CreateDirectory(TPath.GetDirectoryName(AFilePath));
  LPng := TPngImage.Create;
  try
    LPng.Assign(ABmp);
    LPng.SaveToFile(AFilePath);
    Result := True;
  finally
    LPng.Free;
  end;
end;

function CaptureControlBitmapDirect(AControl: TWinControl; ABmp: Vcl.Graphics.TBitmap; var ADiag: string): Boolean;
var
  Ldc: HDC;
begin
  Result := False;
  ADiag := '';
  if (AControl = nil) or (not AControl.HandleAllocated) or (not AControl.Visible) then
    Exit;
  ABmp.PixelFormat := pf32bit;
  ABmp.SetSize(AControl.Width, AControl.Height);
  ABmp.Canvas.Brush.Color := clBtnFace;
  ABmp.Canvas.FillRect(Rect(0, 0, ABmp.Width, ABmp.Height));

  Ldc := GetWindowDC(AControl.Handle);
  if Ldc = 0 then
  begin
    ADiag := Format('GetWindowDC(%s) failed, err=%d', [AControl.ClassName, GetLastError]);
    Exit;
  end;
  try
    if not BitBlt(ABmp.Canvas.Handle, 0, 0, AControl.Width, AControl.Height,
      Ldc, 0, 0, SRCCOPY) then
    begin
      ADiag := Format('BitBlt(%s) failed, err=%d', [AControl.ClassName, GetLastError]);
      Exit;
    end;
  finally
    ReleaseDC(AControl.Handle, Ldc);
  end;

  ADiag := Format('%s at (%d,%d,%d,%d) distinctColors=%d',
    [AControl.ClassName, AControl.Left, AControl.Top, AControl.Width,
     AControl.Height, BitmapDistinctColors(ABmp)]);
  if BitmapDistinctColors(ABmp) <= 1 then
    Exit;
  Result := True;
end;

end.
