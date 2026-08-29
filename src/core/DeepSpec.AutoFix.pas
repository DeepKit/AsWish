{ ============================================================================
  DeepSpec.AutoFix
  ---------------------------------------------------------------------------
  Moat abstraction for AutoFix and self-healing subsystem.
  Provides interfaces and fallbacks for open-source standalone builds:
  - In standalone mode: fails open gracefully with explicit trace logging
  - In closed-source environment: hooks to the proprietary AutoFix engine
  ============================================================================ }

unit DeepSpec.AutoFix;

interface

uses
  System.SysUtils,
  System.Classes,
  DeepSpec.Logger;

type
  IDeepSpecAutoFixHandler = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A014}']
    procedure RegisterScenario(const AName: string; AProc: TProc);
    procedure RecordError(const AErrorCode, ADetails: string);
    procedure SendHealthSignal(const ASignalName: string; AValue: Integer);
  end;

  TDeepSpecAutoFix = class
  private
    class var FHandler: IDeepSpecAutoFixHandler;
  public
    class procedure Install; static;
    class procedure RegisterScenario(const AName: string; AProc: TProc); static;
    class procedure RecordError(const AErrorCode, ADetails: string); static;
    class procedure SendHealthSignal(const ASignalName: string; AValue: Integer); static;
    class procedure SetHandler(const AHandler: IDeepSpecAutoFixHandler); static;
  end;

  TAutoFix = TDeepSpecAutoFix;

  TAutoFixVclHook = class
  public
    class procedure Install; static;
  end;

procedure InstallAIErrorHandler;

implementation

{ TDeepSpecAutoFix }

class procedure TDeepSpecAutoFix.Install;
begin
  Logger.Info('AutoFix subsystem initialized (open-source mode)', 'AutoFix');
end;

class procedure TDeepSpecAutoFix.SetHandler(const AHandler: IDeepSpecAutoFixHandler);
begin
  FHandler := AHandler;
  if FHandler <> nil then
    Logger.Info('Attached closed-source AutoFix engine', 'AutoFix');
end;

class procedure TDeepSpecAutoFix.RegisterScenario(const AName: string; AProc: TProc);
begin
  if FHandler <> nil then
    FHandler.RegisterScenario(AName, AProc)
  else
    Logger.Debug('Registered scenario: ' + AName + ' (standalone mode)', 'AutoFix');
end;

class procedure TDeepSpecAutoFix.RecordError(const AErrorCode, ADetails: string);
begin
  if FHandler <> nil then
    FHandler.RecordError(AErrorCode, ADetails)
  else
    Logger.Warn(Format('AutoFix error recorded: [%s] %s', [AErrorCode, ADetails]), 'AutoFix');
end;

class procedure TDeepSpecAutoFix.SendHealthSignal(const ASignalName: string; AValue: Integer);
begin
  if FHandler <> nil then
    FHandler.SendHealthSignal(ASignalName, AValue)
  else
    Logger.Debug(Format('Health signal: %s=%d', [ASignalName, AValue]), 'AutoFix');
end;

{ TAutoFixVclHook }

class procedure TAutoFixVclHook.Install;
begin
  Logger.Debug('VCL exception hook installed', 'AutoFix');
end;

procedure InstallAIErrorHandler;
begin
  Logger.Debug('AI error handler initialized', 'AutoFix');
end;

end.
