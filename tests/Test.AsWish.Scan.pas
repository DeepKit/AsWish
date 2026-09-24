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
    procedure TsxOnlyProject_IsNotRecognisedAsCode;
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
      TFile.WriteAllText(TPath.Combine(LDir, LName), '// fixture');
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

// A React app written entirely in .tsx files. ".tsx" is classified fcUI, not
// fcCode, and DetectProjectType only looks at fcCode -- so the ".tsx" half of
// the React check can never fire and this project is not a code project at all.
// Recorded as the current (wrong) answer so the fix cannot land silently.
procedure TScanProjectTypeTests.TsxOnlyProject_IsNotRecognisedAsCode;
var
  LScan: TAsWishScanService;
begin
  LScan := ScanProjectWith(TArray<string>.Create('App.tsx', 'index.tsx'));
  try
    Assert.AreEqual('unknown', LScan.DetectProjectType,
      'expected "unknown" while .tsx is classified fcUI; see WO-20260925-0054');
  finally
    LScan.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TScanProjectTypeTests);

end.
