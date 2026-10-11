@echo off
REM ============================================================================
REM  AsWish build script (Delphi 13.1 / Win64)
REM  Decoupled open-source build with zero external framework dependencies.
REM ============================================================================

if "%BDS%"=="" set "BDS=d:\Program Files (x86)\Embarcadero\Studio\37.0"
set "PATH=%BDS%\bin;%PATH%"

set "ROOT=%~dp0"
cd /d "%ROOT%"
if not exist dcu mkdir dcu
if not exist bin mkdir bin

echo [1/2] Building GUI: bin\AsWish.exe ...
dcc64 -B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -U"src\app;src\services;src\providers;src\controllers;src\core;src\models;vendor\deepbase-ehai" -E.\bin -N.\dcu -DDEBUG AsWish.dpr
if errorlevel 1 (
    echo [ERROR] GUI build failed.
    exit /b 1
)
if not exist "bin\AsWish.exe" (
    echo [ERROR] GUI target binary bin\AsWish.exe missing.
    exit /b 1
)

echo [2/2] Building CLI: cli\bin\AsWish.CLI.exe ...
pushd cli
if not exist dcu mkdir dcu
if not exist bin mkdir bin
dcc64 -B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -U"..\src\core;..\src\models;..\src\services;..\src\controllers;..\vendor\deepbase-ehai;..\dcu" -E.\bin -N.\dcu -DDEBUG AsWish.CLI.dpr
set "CLI_ERR=%ERRORLEVEL%"
popd
if not "%CLI_ERR%"=="0" (
    echo [ERROR] CLI build failed.
    exit /b %CLI_ERR%
)
if not exist "cli\bin\AsWish.CLI.exe" (
    echo [ERROR] CLI target binary cli\bin\AsWish.CLI.exe missing.
    exit /b 1
)

echo.
echo ============================================================================
echo   bin/AsWish.exe          = GUI  (desktop; do NOT pass CLI arguments)
echo   cli/bin/AsWish.CLI.exe  = CLI  (headless command line)
echo ============================================================================
echo [CLAIM_ASSERTED] compile_gui_binary
echo [CLAIM_ASSERTED] compile_cli_binary
