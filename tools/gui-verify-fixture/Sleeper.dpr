program Sleeper;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Registry, IOUtils;

function GetDelayMs: Integer;
var
  P, S: string;
  V: Integer;
begin
  P := ExtractFilePath(ParamStr(0)) + 'delay.txt';
  if not FileExists(P) then
  begin
    Writeln(ErrOutput, 'Sleeper: delay=1500 source=default');
    Exit(1500);
  end;
  try
    S := Trim(TFile.ReadAllText(P));
    if (Length(S) > 0) and (S[1] = #$FEFF) then Delete(S, 1, 1);
    if not TryStrToInt(Trim(S), V) or (V < 0) or (V > 30000) then raise Exception.Create('');
    Writeln(ErrOutput, 'Sleeper: delay=' + IntToStr(V) + ' source=file');
    Result := V;
  except
    Writeln(ErrOutput, 'Sleeper: invalid delay in delay.txt');
    Halt(2);
  end;
end;

function GetRealBrowserExe: string;
var
  Folder, Pv, RegPath: string;
  Reg: TRegistry;
begin
  Folder := GetEnvironmentVariable('ASWISH_REAL_BROWSER_FOLDER');
  Pv := '';
  Reg := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    RegPath := 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
    if Reg.OpenKeyReadOnly(RegPath) then
    begin
      if Reg.ValueExists('pv') then Pv := Reg.ReadString('pv');
      if (Folder = '') and Reg.ValueExists('location') then Folder := Reg.ReadString('location');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  if Folder = '' then Folder := 'C:\Program Files (x86)\Microsoft\EdgeWebView\Application';
  if FileExists(IncludeTrailingPathDelimiter(Folder) + 'msedgewebview2.exe') then
    Exit(IncludeTrailingPathDelimiter(Folder) + 'msedgewebview2.exe');
  if Pv <> '' then Folder := IncludeTrailingPathDelimiter(Folder) + Pv;
  Result := IncludeTrailingPathDelimiter(Folder) + 'msedgewebview2.exe';
end;

function GetCmdTail: string;
var
  Cmd: string;
  InQuote: Boolean;
  I: Integer;
begin
  Cmd := GetCommandLine;
  InQuote := False;
  I := 1;
  while (I <= Length(Cmd)) do
  begin
    if Cmd[I] = '"' then
      InQuote := not InQuote
    else if (Cmd[I] = ' ') and not InQuote then
      Break;
    Inc(I);
  end;
  while (I <= Length(Cmd)) and (Cmd[I] = ' ') do
    Inc(I);
  Result := Copy(Cmd, I, MaxInt);
end;

var
  SI: TStartupInfo;
  PI: TProcessInformation;
  RealExe, FullCmd, Tail: string;
  ExitCode: DWORD;
begin
  Sleep(GetDelayMs);
  RealExe := GetRealBrowserExe;
  if not FileExists(RealExe) then
  begin
    Writeln(ErrOutput, 'Sleeper: real browser exe not found: ' + RealExe);
    Halt(1);
  end;

  Tail := GetCmdTail;
  if Tail <> '' then
    FullCmd := '"' + RealExe + '" ' + Tail
  else
    FullCmd := '"' + RealExe + '"';

  FillChar(SI, SizeOf(SI), 0);
  GetStartupInfo(SI);
  SI.cb := SizeOf(SI);
  FillChar(PI, SizeOf(PI), 0);
  UniqueString(FullCmd);

  if not CreateProcess(nil, PChar(FullCmd), nil, nil, True, 0, nil, nil, SI, PI) then
  begin
    Writeln(ErrOutput, 'Sleeper: CreateProcess failed: ' + SysErrorMessage(GetLastError));
    Halt(GetLastError);
  end;

  CloseHandle(PI.hThread);
  WaitForSingleObject(PI.hProcess, INFINITE);
  ExitCode := 0;
  GetExitCodeProcess(PI.hProcess, ExitCode);
  CloseHandle(PI.hProcess);
  Halt(ExitCode);
end.
