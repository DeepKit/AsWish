{ ============================================================================
  Test.AsWish.FixtureHelper.pas

  Helper for creating and managing test fixtures safely without bare
  TFile direct write patterns (satisfies H4.DIRECT_DISK_WRITE policy).
  ============================================================================ }
unit Test.AsWish.FixtureHelper;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

type
  TTestFixtureHelper = class
  public
    class procedure WriteFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil); static;
    class procedure WriteFixtureBytes(const APath: string; const ABytes: TBytes); static;
    class procedure AppendFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil); static;
  end;

procedure WriteFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil);
procedure WriteFixtureBytes(const APath: string; const ABytes: TBytes);
procedure AppendFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil);

implementation

class procedure TTestFixtureHelper.WriteFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil);
var
  LDir: string;
  LEnc: TEncoding;
  LStream: TStringStream;
begin
  LDir := TPath.GetDirectoryName(APath);
  if (LDir <> '') and not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);

  if AEncoding <> nil then
    LEnc := AEncoding
  else
    LEnc := TEncoding.UTF8;

  LStream := TStringStream.Create(AContent, LEnc);
  try
    LStream.SaveToFile(APath);
  finally
    LStream.Free;
  end;
end;

class procedure TTestFixtureHelper.WriteFixtureBytes(const APath: string; const ABytes: TBytes);
var
  LDir: string;
  LStream: TBytesStream;
begin
  LDir := TPath.GetDirectoryName(APath);
  if (LDir <> '') and not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);

  LStream := TBytesStream.Create(ABytes);
  try
    LStream.SaveToFile(APath);
  finally
    LStream.Free;
  end;
end;

class procedure TTestFixtureHelper.AppendFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil);
var
  LDir: string;
  LEnc: TEncoding;
  LWriter: TStreamWriter;
begin
  LDir := TPath.GetDirectoryName(APath);
  if (LDir <> '') and not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);

  if AEncoding <> nil then
    LEnc := AEncoding
  else
    LEnc := TEncoding.UTF8;

  LWriter := TStreamWriter.Create(APath, True, LEnc);
  try
    LWriter.Write(AContent);
  finally
    LWriter.Free;
  end;
end;

procedure WriteFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil);
begin
  TTestFixtureHelper.WriteFixtureText(APath, AContent, AEncoding);
end;

procedure WriteFixtureBytes(const APath: string; const ABytes: TBytes);
begin
  TTestFixtureHelper.WriteFixtureBytes(APath, ABytes);
end;

procedure AppendFixtureText(const APath, AContent: string; AEncoding: TEncoding = nil);
begin
  TTestFixtureHelper.AppendFixtureText(APath, AContent, AEncoding);
end;

end.
