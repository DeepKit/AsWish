@echo off
REM ============================================================================
REM  AsWish installer build script (Inno Setup 6)
REM  Detects ISCC.exe, compiles AsWish.iss, prints the artifact path.
REM    ISCC - env override for a custom Inno Setup install location
REM ============================================================================

set "ISCC_DEFAULT=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if "%ISCC%"=="" set "ISCC=%ISCC_DEFAULT%"

if not exist "%ISCC%" (
  echo [ERROR] Inno Setup 6 compiler not found at "%ISCC%"
  echo         Install it from: https://jrsoftware.org/isdl.php
  echo         Or point the ISCC environment variable to ISCC.exe
  exit /b 1
)

set "ROOT=%~dp0"
cd /d "%ROOT%"

echo [installer] compiling AsWish.iss ...
"%ISCC%" AsWish.iss
if errorlevel 1 (
  echo [ERROR] ISCC compilation failed
  exit /b 1
)

echo [installer] done -^> ..\bin\installer\AsWish-Setup-0.1.0.0.exe
exit /b 0
