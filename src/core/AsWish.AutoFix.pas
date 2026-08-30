{ ============================================================================
  AsWish.AutoFix
  ---------------------------------------------------------------------------
  Moat abstraction for AutoFix and self-healing subsystem.
  Provides interfaces and fallbacks for open-source standalone builds:
  - In standalone mode: fails open gracefully with explicit trace logging
  - In closed-source environment: hooks to the proprietary AutoFix engine
  ============================================================================ }

unit AsWish.AutoFix;

interface

uses
  System.SysUtils,
  System.Classes,
  AsWish.Logger;

type
  IAsWishAutoFixHandler = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A014}']
    procedure RegisterScenario(const AName: string; AProc: TProc);
    procedure RecordError(const AErrorCode, ADetails: string);
    procedure SendHealthSignal(const ASignalName: string; AValue: Integer);
  end;

  TAsWishAutoFix = class
  private
    class var FHandler: IAsWishAutoFixHandler;
  public
    class procedure Install; static;
    class procedure RegisterScenario(const AName: string; AProc: TProc); static;
    class procedure RecordError(const AErrorCode, ADetails: string); static;
    class procedure SendHealthSignal(const ASignalName: string; AValue: Integer); static;
    class procedure SetHandler(const AHandler: IAsWishAutoFixHandler); static;
  end;

  TAutoFix = TAsWishAutoFix;

  TAutoFixVclHook = class
  public
    class procedure Install; static;
  end;

procedure InstallAIErrorHandler;

implementation

{ TAsWishAutoFix }

class procedure TAsWishAutoFix.Install;
begin
  Logger.Info('AutoFix subsystem initialized (open-source mode)', 'AutoFix');
end;

class procedure TAsWishAutoFix.SetHandler(const AHandler: IAsWishAutoFixHandler);
begin
  FHandler := AHandler;
  if FHandler <> nil then
    Logger.Info('Attached closed-source AutoFix engine', 'AutoFix');
end;

class procedure TAsWishAutoFix.RegisterScenario(const AName: string; AProc: TProc);
begin
  if FHandler <> nil then
    FHandler.RegisterScenario(AName, AProc)
  else
    Logger.Debug('Registered scenario: ' + AName + ' (standalone mode)', 'AutoFix');
end;

class procedure TAsWishAutoFix.RecordError(const AErrorCode, ADetails: string);
begin
  if FHandler <> nil then
    FHandler.RecordError(AErrorCode, ADetails)
  else
    Logger.Warn(Format('AutoFix error recorded: [%s] %s', [AErrorCode, ADetails]), 'AutoFix');
end;

class procedure TAsWishAutoFix.SendHealthSignal(const ASignalName: string; AValue: Integer);
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
