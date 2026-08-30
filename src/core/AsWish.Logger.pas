{ ============================================================================
  AsWish.Logger
  ---------------------------------------------------------------------------
  Lightweight standalone logger for AsWish.
  Logs lifecycle, scan progress and operational diagnostics.
  Outputs to console, memory buffer and log file.
  Zero external dependencies.
  ============================================================================ }

unit AsWish.Logger;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.IOUtils;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError);

  TLogCallback = reference to procedure(ALevel: TLogLevel; const AMsg, ACat: string);

  TAsWishLogger = class
  private
    class var FInstance: TAsWishLogger;
    class var FLock: TCriticalSection;
  private
    FLogPath: string;
    FCallback: TLogCallback;
    procedure WriteLine(ALevel: TLogLevel; const AMsg, ACat: string);
  public
    constructor Create;
    destructor Destroy; override;

    class function Instance: TAsWishLogger;
    class procedure Finalize;

    procedure Debug(const AMsg: string; const ACat: string = 'General');
    procedure Info(const AMsg: string; const ACat: string = 'General');
    procedure Warn(const AMsg: string; const ACat: string = 'General');
    procedure Error(const AMsg: string; const ACat: string = 'General');

    property Callback: TLogCallback read FCallback write FCallback;
    property LogPath: string read FLogPath write FLogPath;
  end;

function Logger: TAsWishLogger;

implementation

{ TAsWishLogger }

constructor TAsWishLogger.Create;
var
  LDir: string;
begin
  inherited Create;
  LDir := TPath.Combine(TPath.GetHomePath, 'AsWish');
  if not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);
  FLogPath := TPath.Combine(LDir, 'aswish.log');
end;

destructor TAsWishLogger.Destroy;
begin
  inherited;
end;

class function TAsWishLogger.Instance: TAsWishLogger;
begin
  if FLock = nil then
    FLock := TCriticalSection.Create;
  FLock.Enter;
  try
    if FInstance = nil then
      FInstance := TAsWishLogger.Create;
    Result := FInstance;
  finally
    FLock.Leave;
  end;
end;

class procedure TAsWishLogger.Finalize;
begin
  if FLock <> nil then
  begin
    FLock.Enter;
    try
      FreeAndNil(FInstance);
    finally
      FLock.Leave;
      FreeAndNil(FLock);
    end;
  end;
end;

procedure TAsWishLogger.WriteLine(ALevel: TLogLevel; const AMsg, ACat: string);
var
  LPrefix, LLine: string;
begin
  case ALevel of
    llDebug: LPrefix := '[DEBUG]';
    llInfo:  LPrefix := '[INFO] ';
    llWarn:  LPrefix := '[WARN] ';
    llError: LPrefix := '[ERROR]';
  end;

  LLine := Format('%s %s [%s] %s', [
    FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
    LPrefix,
    ACat,
    AMsg
  ]);

  if Assigned(FCallback) then
  begin
    try
      FCallback(ALevel, AMsg, ACat);
    except
    end;
  end;

  if FLogPath <> '' then
  begin
    try
      TFile.AppendAllText(FLogPath, LLine + sLineBreak, TEncoding.UTF8);
    except
    end;
  end;
end;

procedure TAsWishLogger.Debug(const AMsg, ACat: string);
begin
  WriteLine(llDebug, AMsg, ACat);
end;

procedure TAsWishLogger.Info(const AMsg, ACat: string);
begin
  WriteLine(llInfo, AMsg, ACat);
end;

procedure TAsWishLogger.Warn(const AMsg, ACat: string);
begin
  WriteLine(llWarn, AMsg, ACat);
end;

procedure TAsWishLogger.Error(const AMsg, ACat: string);
begin
  WriteLine(llError, AMsg, ACat);
end;

function Logger: TAsWishLogger;
begin
  Result := TAsWishLogger.Instance;
end;

initialization

finalization
  TAsWishLogger.Finalize;

end.
