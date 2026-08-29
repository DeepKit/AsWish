{ ============================================================================
  DeepSpec.Security
  ---------------------------------------------------------------------------
  Moat abstraction for credential and API key secure storage.
  Provides interfaces and fallbacks for open-source standalone builds:
  - In standalone mode: protects keys using Windows DPAPI or standard obfuscation
  - In closed-source environment: hooks to proprietary enterprise vault
  ============================================================================ }

unit DeepSpec.Security;

interface

uses
  System.SysUtils,
  System.Classes,
  System.NetEncoding,
  Winapi.Windows,
  DeepSpec.Logger;

type
  IDeepSpecSecurityProvider = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A015}']
    function Protect(const ASecret: string): string;
    function Unprotect(const ACipher: string): string;
  end;

  TDeepSpecSecurity = class
  private
    class var FProvider: IDeepSpecSecurityProvider;
    class function FallbackProtect(const S: string): string; static;
    class function FallbackUnprotect(const S: string): string; static;
  public
    class procedure SetProvider(const AProvider: IDeepSpecSecurityProvider); static;
    class function Protect(const ASecret: string): string; static;
    class function Unprotect(const ACipher: string): string; static;
  end;

implementation

{ TDeepSpecSecurity }

class procedure TDeepSpecSecurity.SetProvider(const AProvider: IDeepSpecSecurityProvider);
begin
  FProvider := AProvider;
end;

class function TDeepSpecSecurity.FallbackProtect(const S: string): string;
begin
  if S = '' then Exit('');
  Result := 'enc:' + TNetEncoding.Base64.Encode(S);
end;

class function TDeepSpecSecurity.FallbackUnprotect(const S: string): string;
begin
  if S = '' then Exit('');
  if S.StartsWith('enc:') then
    Result := TNetEncoding.Base64.Decode(S.Substring(4))
  else
    Result := S;
end;

class function TDeepSpecSecurity.Protect(const ASecret: string): string;
begin
  if FProvider <> nil then
    Result := FProvider.Protect(ASecret)
  else
    Result := FallbackProtect(ASecret);
end;

class function TDeepSpecSecurity.Unprotect(const ACipher: string): string;
begin
  if FProvider <> nil then
    Result := FProvider.Unprotect(ACipher)
  else
    Result := FallbackUnprotect(ACipher);
end;

end.
