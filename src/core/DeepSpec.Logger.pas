{ ============================================================================
  DeepSpec.Logger
  ---------------------------------------------------------------------------
  Lightweight standalone logger for DeepSpec.
  Logs lifecycle, scan progress and operational diagnostics.
  Outputs to console, memory buffer and log file.
  Zero external dependencies.
  ============================================================================ }

unit DeepSpec.Logger;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.IOUtils;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError);

  TLogCallback = reference to procedure(ALevel: TLogLevel; const AMsg, ACat: string);

  TDeepSpecLogger = class
  private
    class var FInstance: TDeepSpecLogger;
    class var FLock: TCriticalSection;
  private
    FLogPath: string;
    FCallback: TLogCallback;
    procedure WriteLine(ALevel: TLogLevel; const AMsg, ACat: string);
  public
    constructor Create;
    destructor Destroy; override;

    class function Instance: TDeepSpecLogger;
    class procedure Finalize;

    procedure Debug(const AMsg: string; const ACat: string = 'General');
    procedure Info(const AMsg: string; const ACat: string = 'General');
    procedure Warn(const AMsg: string; const ACat: string = 'General');
    procedure Error(const AMsg: string; const ACat: string = 'General');

    property Callback: TLogCallback read FCallback write FCallback;
    property LogPath: string read FLogPath write FLogPath;
  end;

function Logger: TDeepSpecLogger;

implementation

{ TDeepSpecLogger }

constructor TDeepSpecLogger.Create;
var
  LDir: string;
begin
  inherited Create;
  LDir := TPath.Combine(TPath.GetHomePath, 'DeepSpec');
  if not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);
  FLogPath := TPath.Combine(LDir, 'deepspec.log');
end;

destructor TDeepSpecLogger.Destroy;
begin
  inherited;
end;

class function TDeepSpecLogger.Instance: TDeepSpecLogger;
begin
  if FLock = nil then
    FLock := TCriticalSection.Create;
  FLock.Enter;
  try
    if FInstance = nil then
      FInstance := TDeepSpecLogger.Create;
    Result := FInstance;
  finally
    FLock.Leave;
  end;
end;

class procedure TDeepSpecLogger.Finalize;
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

procedure TDeepSpecLogger.WriteLine(ALevel: TLogLevel; const AMsg, ACat: string);
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

procedure TDeepSpecLogger.Debug(const AMsg, ACat: string);
begin
  WriteLine(llDebug, AMsg, ACat);
end;

procedure TDeepSpecLogger.Info(const AMsg, ACat: string);
begin
  WriteLine(llInfo, AMsg, ACat);
end;

procedure TDeepSpecLogger.Warn(const AMsg, ACat: string);
begin
  WriteLine(llWarn, AMsg, ACat);
end;

procedure TDeepSpecLogger.Error(const AMsg, ACat: string);
begin
  WriteLine(llError, AMsg, ACat);
end;

function Logger: TDeepSpecLogger;
begin
  Result := TDeepSpecLogger.Instance;
end;

initialization

finalization
  TDeepSpecLogger.Finalize;

end.
