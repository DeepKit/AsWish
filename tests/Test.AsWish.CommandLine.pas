{ ============================================================================
  Test.AsWish.CommandLine
  Unit tests for command line parsing and validation on GUI and CLI (WO-20260930-0064).
  ============================================================================ }
unit Test.AsWish.CommandLine;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  Winapi.Windows, AsWish.CommandLine;

type
  [TestFixture]
  TTestAsWishCommandLine = class
  private
    FTempDir: string;
  public
    [Setup]
    procedure SetUp;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test01_GuiArgs_EmptyArgs_IsValid;
    [Test]
    procedure Test02_GuiArgs_ExistingDirectory_IsValid;
    [Test]
    procedure Test03_GuiArgs_GuiVerifyWithDirectory_IsValid;
    [Test]
    procedure Test04_GuiArgs_UnknownArguments_FailsClosed;
    [Test]
    procedure Test05_GuiArgs_CliCommandPassedToGui_FailsClosed;
    [Test]
    procedure Test06_GuiArgs_GuiVerifyWithoutDirectory_FailsClosed;
    [Test]
    procedure Test07_CliDir_PositionalFlag_FailsClosed;
    [Test]
    procedure Test08_CliDir_SlashFlag_FailsClosed;
    [Test]
    procedure Test09_CliDir_ValidDirectory_Passes;
    [Test]
    procedure Test10_OutputConsoleError_InvalidHandles_AttachesConsoleAndWrites;
    [Test]
    procedure Test11_OutputConsoleError_ValidHandle_DoesNotAttachConsole;
  end;

implementation

var
  GStubAttachConsoleCalled: Boolean = False;
  GStubWriteFileCalled: Boolean = False;
  GStubWrittenHandle: THandle = 0;
  GStubWrittenText: string = '';

function StubGetStdHandle_Invalid(nStdHandle: DWORD): THandle; stdcall;
begin
  if not GStubAttachConsoleCalled then
    Result := 0
  else
    Result := 42;
end;

function StubGetStdHandle_Valid(nStdHandle: DWORD): THandle; stdcall;
begin
  Result := 99;
end;

function StubAttachConsole(dwProcessId: DWORD): BOOL; stdcall;
begin
  GStubAttachConsoleCalled := True;
  Result := True;
end;

function StubWriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD;
  var lpNumberOfBytesWritten: DWORD; lpOverlapped: Pointer): BOOL; stdcall;
begin
  GStubWriteFileCalled := True;
  GStubWrittenHandle := hFile;
  SetString(GStubWrittenText, PAnsiChar(@Buffer), nNumberOfBytesToWrite);
  lpNumberOfBytesWritten := nNumberOfBytesToWrite;
  Result := True;
end;

procedure TTestAsWishCommandLine.SetUp;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'aswish_cmdline_test_' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(FTempDir);
end;

procedure TTestAsWishCommandLine.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    try
      TDirectory.Delete(FTempDir, True);
    except
    end;
end;

procedure TTestAsWishCommandLine.Test01_GuiArgs_EmptyArgs_IsValid;
var
  LRes: TAsWishParsedArgs;
begin
  LRes := TAsWishCommandLine.ParseGui([]);
  Assert.IsTrue(LRes.IsValid, 'Empty args should be valid for GUI default launch');
  Assert.IsFalse(LRes.IsGuiVerify, 'Default launch is not gui verify');
  Assert.AreEqual('', LRes.ProjectDir, 'Default launch has no project dir');
end;

procedure TTestAsWishCommandLine.Test02_GuiArgs_ExistingDirectory_IsValid;
var
  LRes: TAsWishParsedArgs;
begin
  LRes := TAsWishCommandLine.ParseGui([FTempDir]);
  Assert.IsTrue(LRes.IsValid, 'Existing directory arg should be valid');
  Assert.IsFalse(LRes.IsGuiVerify, 'Single dir arg is not gui verify');
  Assert.AreEqual(FTempDir, LRes.ProjectDir);
end;

procedure TTestAsWishCommandLine.Test03_GuiArgs_GuiVerifyWithDirectory_IsValid;
var
  LRes: TAsWishParsedArgs;
begin
  LRes := TAsWishCommandLine.ParseGui(['--gui-verify', FTempDir]);
  Assert.IsTrue(LRes.IsValid, '--gui-verify with directory should be valid');
  Assert.IsTrue(LRes.IsGuiVerify, 'IsGuiVerify must be true');
  Assert.AreEqual(FTempDir, LRes.ProjectDir);
end;

procedure TTestAsWishCommandLine.Test04_GuiArgs_UnknownArguments_FailsClosed;
var
  LRes: TAsWishParsedArgs;
begin
  LRes := TAsWishCommandLine.ParseGui(['foo', 'bar']);
  Assert.IsFalse(LRes.IsValid, 'Unknown args "foo bar" must fail closed');
  Assert.AreEqual('foo', LRes.UnknownArg, 'UnknownArg should capture first invalid argument');
  Assert.IsTrue(LRes.ErrorMessage <> '', 'ErrorMessage must not be empty');
end;

procedure TTestAsWishCommandLine.Test05_GuiArgs_CliCommandPassedToGui_FailsClosed;
var
  LRes: TAsWishParsedArgs;
begin
  LRes := TAsWishCommandLine.ParseGui(['validate', '--project', FTempDir]);
  Assert.IsFalse(LRes.IsValid, 'CLI commands passed to GUI must fail closed');
  Assert.AreEqual('validate', LRes.UnknownArg);
  Assert.IsTrue(LRes.ErrorMessage.Contains('validate'), 'ErrorMessage should mention invalid command');
end;

procedure TTestAsWishCommandLine.Test06_GuiArgs_GuiVerifyWithoutDirectory_FailsClosed;
var
  LRes: TAsWishParsedArgs;
begin
  LRes := TAsWishCommandLine.ParseGui(['--gui-verify']);
  Assert.IsFalse(LRes.IsValid, '--gui-verify without directory must fail closed');
  Assert.IsTrue(LRes.ErrorMessage <> '', 'ErrorMessage must explain missing directory');
end;

procedure TTestAsWishCommandLine.Test07_CliDir_PositionalFlag_FailsClosed;
var
  LMsg: string;
  LOk: Boolean;
begin
  LOk := TAsWishCommandLine.CheckCliDir('--project', LMsg);
  Assert.IsFalse(LOk, '--project passed as positional dir must fail closed');
  Assert.IsTrue(LMsg.Contains('--project'), 'Error message must mention --project');
  Assert.IsTrue(LMsg.Contains('positional'), 'Error message must mention positional argument requirement');
end;

procedure TTestAsWishCommandLine.Test08_CliDir_SlashFlag_FailsClosed;
var
  LMsg: string;
  LOk: Boolean;
begin
  LOk := TAsWishCommandLine.CheckCliDir('/p', LMsg);
  Assert.IsFalse(LOk, '/p passed as positional dir must fail closed');
  Assert.IsTrue(LMsg.Contains('/p'), 'Error message must mention /p');
end;

procedure TTestAsWishCommandLine.Test09_CliDir_ValidDirectory_Passes;
var
  LMsg: string;
  LOk: Boolean;
begin
  LOk := TAsWishCommandLine.CheckCliDir(FTempDir, LMsg);
  Assert.IsTrue(LOk, 'Valid directory should pass CLI dir check');
  Assert.AreEqual('', LMsg);
end;

procedure TTestAsWishCommandLine.Test10_OutputConsoleError_InvalidHandles_AttachesConsoleAndWrites;
var
  LRes: Boolean;
begin
  GStubAttachConsoleCalled := False;
  GStubWriteFileCalled := False;
  GStubWrittenHandle := 0;
  GStubWrittenText := '';

  LRes := TAsWishCommandLine.OutputConsoleErrorEx('test error payload',
    StubGetStdHandle_Invalid, StubAttachConsole, StubWriteFile);

  Assert.IsTrue(LRes, 'OutputConsoleErrorEx must return True on successful write');
  Assert.IsTrue(GStubAttachConsoleCalled, 'AttachConsole must be called when handles are initially 0');
  Assert.IsTrue(GStubWriteFileCalled, 'WriteFile must be called');
  Assert.AreEqual(THandle(42), GStubWrittenHandle, 'Handle after AttachConsole must be used');
  Assert.IsTrue(GStubWrittenText.Contains('test error payload'), 'Written text must contain message');
end;

procedure TTestAsWishCommandLine.Test11_OutputConsoleError_ValidHandle_DoesNotAttachConsole;
var
  LRes: Boolean;
begin
  GStubAttachConsoleCalled := False;
  GStubWriteFileCalled := False;
  GStubWrittenHandle := 0;
  GStubWrittenText := '';

  LRes := TAsWishCommandLine.OutputConsoleErrorEx('valid handle payload',
    StubGetStdHandle_Valid, StubAttachConsole, StubWriteFile);

  Assert.IsTrue(LRes, 'OutputConsoleErrorEx must return True');
  Assert.IsFalse(GStubAttachConsoleCalled, 'AttachConsole must not be called when handles are valid');
  Assert.IsTrue(GStubWriteFileCalled, 'WriteFile must be called');
  Assert.AreEqual(THandle(99), GStubWrittenHandle);
  Assert.IsTrue(GStubWrittenText.Contains('valid handle payload'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishCommandLine);
end.
