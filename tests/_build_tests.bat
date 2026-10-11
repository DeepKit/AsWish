@echo off
REM ============================================================================
REM  AsWish tests build script (Delphi 13.1 / Win64)
REM ============================================================================

if "%BDS%"=="" set "BDS=d:\Program Files (x86)\Embarcadero\Studio\37.0"
set "PATH=%BDS%\bin;%PATH%"

set "ROOT=%~dp0"
cd /d "%ROOT%"
if not exist dcu mkdir dcu

dcc64 -B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -U"..\src\app;..\src\services;..\src\providers;..\src\controllers;..\src\core;..\src\models;..\vendor\deepbase-ehai;." -E. -N.\dcu -DDEBUG AsWish.Tests.dpr
if errorlevel 1 (
    echo [ERROR] Tests build failed.
    exit /b 1
)

if not exist "AsWish.Tests.exe" (
    echo [ERROR] Target binary AsWish.Tests.exe missing.
    exit /b 1
)

echo [CLAIM_ASSERTED] test_suite_compiled

REM Fast smoke fixture execution to discover and verify runnable tests
.\AsWish.Tests.exe -b -r:Test.AsWish.Yaml.Parser.TYamlParserTests
if errorlevel 1 (
    echo [ERROR] Smoke test discovery run failed.
    exit /b 1
)

echo [CLAIM_ASSERTED] test_cases_discovered
