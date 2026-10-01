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

echo.
echo ============================================================================
echo   bin/AsWish.exe          = GUI（桌面端，不要传 CLI 参数）
echo   cli/bin/AsWish.CLI.exe  = CLI（headless 命令行）
echo ============================================================================
