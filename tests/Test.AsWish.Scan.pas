{ ============================================================================
  Test.AsWish.Scan

  Covers the one thing the scan service decides on its own: what stack the
  project is written in. Both entry points used to carry their own copy of
  that decision and disagreed, so the same repository was recorded as a
  different type depending on which one scanned it.
  ============================================================================ }

unit Test.AsWish.Scan;

interface

uses
  System.SysUtils,
  System.IOUtils,
  DUnitX.TestFramework,
  Test.AsWish.FixtureHelper,
  AsWish.Services.Scan;

type
  [TestFixture]
  TScanProjectTypeTests = class
  public
    [Test]
    procedure NoCodeFiles_IsUnknown;
    [Test]
    procedure DelphiSource_Wins;
    [Test]
    procedure TypeScript_IsWebReact;
    [Test]
    procedure Python_IsPythonBackend;
    [Test]
    procedure Go_IsMixed;
    [Test]
    procedure UnrecognizedCode_IsMixed;
    [Test]
    procedure LanguagePriority_DoesNotDependOnFileOrder;
    [Test]
    procedure TsxOnlyProject_IsRecognisedAsWebReact;
    [Test]
    procedure MixedTsAndTsxProject_IsRecognisedAsWebReact;
  end;

implementation

function ScanProjectWith(const AFileNames: TArray<string>): TAsWishScanService;
var
  LDir: string;
begin
  LDir := TPath.Combine(TPath.GetTempPath, 'aswish-scan-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(LDir);
  try
    for var LName in AFileNames do
      WriteFixtureText(TPath.Combine(LDir, LName), '// fixture');
  except
    TDirectory.Delete(LDir, True);
    raise;
  end;

  Result := TAsWishScanService.Create;
  try
    Result.ScanDirectory(LDir);
  finally
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TScanProjectTypeTests.NoCodeFiles_IsUnknown;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('readme.md', 'config.yaml'));
  try
    Assert.AreEqual('unknown', LScan.DetectProjectType,
      'a repository holding no code at all has no stack to name');
  finally
    LScan.Free;
  end;
end;

procedure TScanProjectTypeTests.DelphiSource_Wins;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('app.py', 'main.pas'));
  try
    Assert.AreEqual('delphi_vcl', LScan.DetectProjectType,
      'Delphi source outranks every other code file in the project');
  finally
    LScan.Free;
  end;
end;

procedure TScanProjectTypeTests.TypeScript_IsWebReact;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('index.ts'));
  try
    Assert.AreEqual('web_react', LScan.DetectProjectType);
  finally
    LScan.Free;
  end;
end;

procedure TScanProjectTypeTests.Python_IsPythonBackend;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('app.py'));
  try
    Assert.AreEqual('python_backend', LScan.DetectProjectType);
  finally
    LScan.Free;
  end;
end;

procedure TScanProjectTypeTests.Go_IsMixed;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('main.go'));
  try
    Assert.AreEqual('mixed', LScan.DetectProjectType,
      'Go has no dedicated type name in the taxonomy, and both previous ' +
      'implementations answered "mixed" for it');
  finally
    LScan.Free;
  end;
end;

procedure TScanProjectTypeTests.UnrecognizedCode_IsMixed;
var
  LScan: TAsWishScanService;
begin
  // This is the case the two copies actually disagreed on: the CLI said
  // "mixed", the desktop app said "unknown". "mixed" is the settled answer --
  // code we cannot name is still a code project.
  LScan := ScanProjectWith(TArray<string>.Create('lib.rs'));
  try
    Assert.AreEqual('mixed', LScan.DetectProjectType);
  finally
    LScan.Free;
  end;
end;

procedure TScanProjectTypeTests.LanguagePriority_DoesNotDependOnFileOrder;
var
  LScan: TAsWishScanService;
begin
  // a.py sorts before z.ts, so an implementation that answered from whichever
  // file it saw first would call this a Python project. The classification
  // must not change when an unrelated file is added.
  LScan := ScanProjectWith(TArray<string>.Create('a.py', 'z.ts'));
  try
    Assert.AreEqual('web_react', LScan.DetectProjectType);
  finally
    LScan.Free;
  end;
end;

// A React app written entirely in .tsx files. Historically, ".tsx" was classified
// under fcUI while DetectProjectType only checked fcCode, causing pure .tsx
// React projects to be categorized as "unknown".
// This test pins the corrected behavior: projects with only .tsx files are
// recognized as web_react (WO-0057 1.1).
procedure TScanProjectTypeTests.TsxOnlyProject_IsRecognisedAsWebReact;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('App.tsx', 'index.tsx'));
  try
    Assert.AreEqual('web_react', LScan.DetectProjectType,
      'tsx-only project should be recognised as web_react; see WO-0057 1.1');
  finally
    LScan.Free;
  end;
end;

// A React project mixing .ts files (fcCode) and .tsx files (fcUI).
// Pinned by WO-0058 R-2 to ensure the .ts half of HasAnyReactFile/HasAnyExt
// and the fcUI .tsx half cooperate to classify the project as web_react.
procedure TScanProjectTypeTests.MixedTsAndTsxProject_IsRecognisedAsWebReact;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('App.tsx', 'api.ts'));
  try
    Assert.AreEqual('web_react', LScan.DetectProjectType,
      'Mixed .ts and .tsx project should be recognised as web_react');
  finally
    LScan.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TScanProjectTypeTests);

end.
