@echo off
REM ============================================================================
REM  AsWish tests build script (Delphi 13.1 / Win64)
REM ============================================================================

if "%BDS%"=="" set "BDS=d:\Program Files (x86)\Embarcadero\Studio\37.0"
set "PATH=%BDS%\bin;%PATH%"

set "ROOT=%~dp0"
cd /d "%ROOT%"
if not exist dcu mkdir dcu

dcc64 -B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -U"..\src\app;..\src\services;..\src\providers;..\src\controllers;..\src\core;..\src\models;..\..\DeepBase\Core;..\..\DeepBase\VCL;." -E. -N.\dcu -DDEBUG AsWish.Tests.dpr
