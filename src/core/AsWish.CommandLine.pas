{ ============================================================================
  AsWish.CommandLine
  Command line argument parsing and validation for GUI and CLI surfaces.
  Decoupled from Vcl.Forms for deterministic unit testing (WO-20260930-0064).
  ============================================================================ }
unit AsWish.CommandLine;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils{$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF};

type
  TAsWishParsedArgs = record
    IsValid: Boolean;
    IsGuiVerify: Boolean;
    ProjectDir: string;
    UnknownArg: string;
    ErrorMessage: string;
  end;

  TGetStdHandleFunc = function(nStdHandle: DWORD): THandle; stdcall;
  TAttachConsoleFunc = function(dwProcessId: DWORD): BOOL; stdcall;
  TWriteFileFunc = function(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD;
    var lpNumberOfBytesWritten: DWORD; lpOverlapped: Pointer): BOOL; stdcall;

  TAsWishCommandLine = class
  public
    class function ParseGui(const AArgs: array of string): TAsWishParsedArgs; static;
    class function CheckCliDir(const ADir: string; out AErrorMsg: string): Boolean; static;
    class procedure OutputConsoleError(const AMessage: string); static;
    class function OutputConsoleErrorEx(
      const AMessage: string;
      AGetStdHandle: TGetStdHandleFunc = nil;
      AAttachConsole: TAttachConsoleFunc = nil;
      AWriteFile: TWriteFileFunc = nil
    ): Boolean; static;
  end;

implementation

{$IFDEF MSWINDOWS}
function AttachConsole(dwProcessId: DWORD): BOOL; stdcall; external 'kernel32.dll';

function DefaultWriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD;
  var lpNumberOfBytesWritten: DWORD; lpOverlapped: Pointer): BOOL; stdcall;
begin
  Result := Winapi.Windows.WriteFile(hFile, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, POverlapped(lpOverlapped));
end;
{$ENDIF}

class function TAsWishCommandLine.OutputConsoleErrorEx(
  const AMessage: string;
  AGetStdHandle: TGetStdHandleFunc;
  AAttachConsole: TAttachConsoleFunc;
  AWriteFile: TWriteFileFunc
): Boolean;
const
  ATTACH_PARENT_PROCESS: DWORD = DWORD(-1);
var
  LStdErr, LStdOut: THandle;
  LUtf8: UTF8String;
  LWritten: DWORD;
begin
  Result := False;
  {$IFDEF MSWINDOWS}
  if not Assigned(AGetStdHandle) then
    AGetStdHandle := Winapi.Windows.GetStdHandle;
  if not Assigned(AAttachConsole) then
    AAttachConsole := AttachConsole;
  if not Assigned(AWriteFile) then
    AWriteFile := DefaultWriteFile;

  LUtf8 := UTF8Encode(AMessage + #13#10);
  LStdErr := AGetStdHandle(STD_ERROR_HANDLE);
  LStdOut := AGetStdHandle(STD_OUTPUT_HANDLE);

  if ((LStdErr = 0) or (LStdErr = INVALID_HANDLE_VALUE)) and
     ((LStdOut = 0) or (LStdOut = INVALID_HANDLE_VALUE)) then
  begin
    AAttachConsole(ATTACH_PARENT_PROCESS);
    LStdErr := AGetStdHandle(STD_ERROR_HANDLE);
    LStdOut := AGetStdHandle(STD_OUTPUT_HANDLE);
  end;

  if (LStdErr <> 0) and (LStdErr <> INVALID_HANDLE_VALUE) then
  begin
    AWriteFile(LStdErr, PAnsiChar(LUtf8)^, Length(LUtf8), LWritten, nil);
    Result := True;
  end
  else if (LStdOut <> 0) and (LStdOut <> INVALID_HANDLE_VALUE) then
  begin
    AWriteFile(LStdOut, PAnsiChar(LUtf8)^, Length(LUtf8), LWritten, nil);
    Result := True;
  end;
  {$ELSE}
  Writeln(ErrOutput, AMessage);
  Result := True;
  {$ENDIF}
end;

class procedure TAsWishCommandLine.OutputConsoleError(const AMessage: string);
begin
  OutputConsoleErrorEx(AMessage);
end;

class function TAsWishCommandLine.ParseGui(const AArgs: array of string): TAsWishParsedArgs;
var
  I: Integer;
  LArg: string;
begin
  Result.IsValid := True;
  Result.IsGuiVerify := False;
  Result.ProjectDir := '';
  Result.UnknownArg := '';
  Result.ErrorMessage := '';

  if Length(AArgs) = 0 then
    Exit;

  for I := Low(AArgs) to High(AArgs) do
  begin
    LArg := AArgs[I];
    if (LArg = '--gui-verify') or (LArg = '-gui-verify') then
    begin
      Result.IsGuiVerify := True;
    end
    else if TDirectory.Exists(LArg) then
    begin
      if Result.ProjectDir = '' then
        Result.ProjectDir := LArg
      else
      begin
        Result.IsValid := False;
        Result.UnknownArg := LArg;
        Result.ErrorMessage := Format('Multiple project directories specified: "%s" and "%s"', [Result.ProjectDir, LArg]);
        Exit;
      end;
    end
    else
    begin
      Result.IsValid := False;
      Result.UnknownArg := LArg;
      if (LArg = 'validate') or (LArg = 'scan') or (LArg = 'init') or (LArg = 'diff') or
         (LArg = 'difference') or (LArg = 'judge') or (LArg = 'evolve') or (LArg = 'bundle') or
         (LArg = 'health') or (LArg = 'render') or (LArg = 'generate') or (LArg = 'changeset') then
        Result.ErrorMessage := Format('Unknown argument "%s". AsWish.exe is the GUI application and does not accept CLI commands. Please use cli\bin\AsWish.CLI.exe for headless operations.', [LArg])
      else
        Result.ErrorMessage := Format('Unknown argument or directory not found: "%s"', [LArg]);
      Exit;
    end;
  end;

  if Result.IsGuiVerify and (Result.ProjectDir = '') then
  begin
    Result.IsValid := False;
    Result.ErrorMessage := '--gui-verify requires a target project directory.';
  end;
end;

class function TAsWishCommandLine.CheckCliDir(const ADir: string; out AErrorMsg: string): Boolean;
begin
  AErrorMsg := '';
  if (ADir <> '') and (ADir.StartsWith('-') or ADir.StartsWith('/')) then
  begin
    AErrorMsg := Format('project-dir parsed as "%s"; CLI only accepts positional arguments, not --flags', [ADir]);
    Result := False;
  end
  else
    Result := True;
end;

end.
