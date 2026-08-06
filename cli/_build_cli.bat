@echo off
REM ============================================================================
REM  DeepSpec CLI build script (Delphi 13.1 / Win64)
REM  Mirrors _build.bat / tests/_build_tests.bat parameterization (BUG-6).
REM ============================================================================

if "%BDS%"=="" set "BDS=d:\Program Files (x86)\Embarcadero\Studio\37.0"
if "%DEEPBASE_HOME%"=="" set "DEEPBASE_HOME=D:\_Progs\02Business\DeepBase"
set "PATH=%BDS%\bin;%PATH%"

set "ROOT=%~dp0"
cd /d "%ROOT%"
if not exist dcu mkdir dcu
if not exist bin mkdir bin

dcc64 -B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -U"..\src\core;..\src\models;..\src\services;..\dcu;%DEEPBASE_HOME%\Core;%DEEPBASE_HOME%\VCL;%DEEPBASE_HOME%\Persistence;%DEEPBASE_HOME%\Features;%DEEPBASE_HOME%\Governance;%DEEPBASE_HOME%\CloudServices;%DEEPBASE_HOME%\Libs;%DEEPBASE_HOME%\doQry;%DEEPBASE_HOME%\Tools;%DEEPBASE_HOME%\DeepFlow;%DEEPBASE_HOME%\ThirdParty" -E.\bin -N.\dcu -DDEBUG DeepSpec.CLI.dpr
