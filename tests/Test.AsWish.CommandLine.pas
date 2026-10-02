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
    [Test]
    procedure Test12_SelectTargetHandle_OriginalValidDisk_SelectsOriginal;
    [Test]
    procedure Test13_SelectTargetHandle_OriginalInvalid_FallbackToCurrent;
    [Test]
    procedure Test14_OutputConsoleError_OriginalDiskHandle_WritesToOriginalHandle;
    [Test]
    procedure Test15_FormatNoWebViewMessage_DifferentiatesZeroAndErrorCode;
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

function StubGetFileType_Disk(hFile: THandle): DWORD; stdcall;
begin
  if hFile = 100 then
    Result := 1 // FILE_TYPE_DISK
  else
    Result := 2; // FILE_TYPE_CHAR
end;

function StubGetFileType_Pipe(hFile: THandle): DWORD; stdcall;
begin
  if hFile = 100 then
    Result := 3 // FILE_TYPE_PIPE
  else
    Result := 2; // FILE_TYPE_CHAR
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

procedure TTestAsWishCommandLine.Test12_SelectTargetHandle_OriginalValidDisk_SelectsOriginal;
var
  LRes: THandle;
begin
  LRes := TAsWishCommandLine.SelectTargetHandle(100, 200, StubGetFileType_Disk);
  Assert.AreEqual(THandle(100), LRes, 'Valid original handle with DISK type must be selected over current handle');

  LRes := TAsWishCommandLine.SelectTargetHandle(100, 200, StubGetFileType_Pipe);
  Assert.AreEqual(THandle(100), LRes, 'Valid original handle with PIPE type must be selected over current handle');
end;

procedure TTestAsWishCommandLine.Test13_SelectTargetHandle_OriginalInvalid_FallbackToCurrent;
var
  LRes: THandle;
begin
  LRes := TAsWishCommandLine.SelectTargetHandle(0, 200, StubGetFileType_Disk);
  Assert.AreEqual(THandle(200), LRes, 'Invalid original handle (0) must fall back to current handle');

  LRes := TAsWishCommandLine.SelectTargetHandle(INVALID_HANDLE_VALUE, 200, StubGetFileType_Disk);
  Assert.AreEqual(THandle(200), LRes, 'Invalid original handle (-1) must fall back to current handle');
end;

procedure TTestAsWishCommandLine.Test14_OutputConsoleError_OriginalDiskHandle_WritesToOriginalHandle;
var
  LRes: Boolean;
begin
  GStubAttachConsoleCalled := False;
  GStubWriteFileCalled := False;
  GStubWrittenHandle := 0;
  GStubWrittenText := '';

  LRes := TAsWishCommandLine.OutputConsoleErrorEx(
    'redirected error payload',
    100,
    StubGetStdHandle_Valid,
    StubAttachConsole,
    StubWriteFile,
    StubGetFileType_Disk
  );

  Assert.IsTrue(LRes, 'OutputConsoleErrorEx must return True');
  Assert.IsFalse(GStubAttachConsoleCalled, 'AttachConsole must not be called when original handle is valid disk');
  Assert.IsTrue(GStubWriteFileCalled, 'WriteFile must be called');
  Assert.AreEqual(THandle(100), GStubWrittenHandle, 'WriteFile must write to original handle 100');
  Assert.IsTrue(GStubWrittenText.Contains('redirected error payload'));
end;

procedure TTestAsWishCommandLine.Test15_FormatNoWebViewMessage_DifferentiatesZeroAndErrorCode;
var
  LMsg0, LMsgErr: string;
begin
  LMsg0 := TAsWishCommandLine.FormatNoWebViewMessage(0);
  LMsgErr := TAsWishCommandLine.FormatNoWebViewMessage($80070002);

  Assert.IsTrue(LMsg0.Contains('GUI-VERIFY-NO-WEBVIEW'), 'Msg0 must contain GUI-VERIFY-NO-WEBVIEW');
  Assert.IsTrue(LMsg0.Contains('LastErrorCode: $00000000'), 'Msg0 must mention code 0');
  Assert.IsTrue(LMsg0.Contains('did not complete within timeout'), 'Msg0 must explain timeout/not reported');

  Assert.IsTrue(LMsgErr.Contains('GUI-VERIFY-NO-WEBVIEW'), 'MsgErr must contain GUI-VERIFY-NO-WEBVIEW');
  Assert.IsTrue(LMsgErr.Contains('LastErrorCode: $80070002'), 'MsgErr must contain real code');
  Assert.IsFalse(LMsgErr.Contains('did not complete within timeout'), 'MsgErr must not claim timeout when code is non-zero');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishCommandLine);
end.
