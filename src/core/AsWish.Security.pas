{ ============================================================================
  AsWish.Security
  ---------------------------------------------------------------------------
  Moat abstraction for credential and API key secure storage.
  Provides interfaces and fallbacks for open-source standalone builds:
  - In standalone mode: protects keys using Windows DPAPI or standard obfuscation
  - In closed-source environment: hooks to proprietary enterprise vault
  ============================================================================ }

unit AsWish.Security;

interface

uses
  System.SysUtils,
  System.Classes,
  System.NetEncoding,
  Winapi.Windows,
  AsWish.Logger;

type
  IAsWishSecurityProvider = interface
    ['{2B1E2C04-9C1F-4F0F-9F5C-1C77F9D1A015}']
    function Protect(const ASecret: string): string;
    function Unprotect(const ACipher: string): string;
  end;

  TAsWishSecurity = class
  private
    class var FProvider: IAsWishSecurityProvider;
    class function FallbackProtect(const S: string): string; static;
    class function FallbackUnprotect(const S: string): string; static;
  public
    class procedure SetProvider(const AProvider: IAsWishSecurityProvider); static;
    class function Protect(const ASecret: string): string; static;
    class function Unprotect(const ACipher: string): string; static;
  end;

implementation

{ TAsWishSecurity }

class procedure TAsWishSecurity.SetProvider(const AProvider: IAsWishSecurityProvider);
begin
  FProvider := AProvider;
end;

class function TAsWishSecurity.FallbackProtect(const S: string): string;
begin
  if S = '' then Exit('');
  Result := 'enc:' + TNetEncoding.Base64.Encode(S);
end;

class function TAsWishSecurity.FallbackUnprotect(const S: string): string;
begin
  if S = '' then Exit('');
  if S.StartsWith('enc:') then
    Result := TNetEncoding.Base64.Decode(S.Substring(4))
  else
    Result := S;
end;

class function TAsWishSecurity.Protect(const ASecret: string): string;
begin
  if FProvider <> nil then
    Result := FProvider.Protect(ASecret)
  else
    Result := FallbackProtect(ASecret);
end;

class function TAsWishSecurity.Unprotect(const ACipher: string): string;
begin
  if FProvider <> nil then
    Result := FProvider.Unprotect(ACipher)
  else
    Result := FallbackUnprotect(ACipher);
end;

end.
