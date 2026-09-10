<#
.SYNOPSIS
  AsWish automated release packaging script.
  Builds Desktop, CLI, and Tests; validates tests; verifies CLI version;
  packages release bundle into dist/AsWish-v<version>-win64.zip.
#>

[CmdletBinding()]
param (
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
Set-Location $RepoRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AsWish Release Packaging Pipeline" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Resolve Version from SSOT
if (-not $Version) {
    $VersionFile = Join-Path $RepoRoot "src\core\AsWish.Version.pas"
    if (Test-Path $VersionFile) {
        $Match = Select-String -Path $VersionFile -Pattern "ASWISH_VERSION\s*=\s*'([^']+)'"
        if ($Match -and $Match.Matches.Count -gt 0) {
            $Version = $Match.Matches[0].Groups[1].Value
        }
    }
}

if (-not $Version) {
    $Version = "0.1.0"
}

Write-Host "Target Version: $Version" -ForegroundColor Green

# 2. Build Desktop Application
Write-Host "`n[1/5] Building Desktop Application (AsWish.exe)..." -ForegroundColor Yellow
$DesktopBuildProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "_build.bat" -WorkingDirectory $RepoRoot -NoNewWindow -PassThru -Wait
if ($DesktopBuildProc.ExitCode -ne 0) {
    Write-Error "Desktop build failed with exit code $($DesktopBuildProc.ExitCode)"
    exit 1
}
$DesktopExe = Join-Path $RepoRoot "bin\AsWish.exe"
if (-not (Test-Path $DesktopExe)) {
    Write-Error "Desktop executable not found at $DesktopExe"
    exit 1
}
Write-Host "  -> Desktop build OK: $DesktopExe" -ForegroundColor Green

# 3. Build Headless CLI
Write-Host "`n[2/5] Building Headless CLI (AsWish.CLI.exe)..." -ForegroundColor Yellow
$CliBuildProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cli\_build_cli.bat" -WorkingDirectory $RepoRoot -NoNewWindow -PassThru -Wait
if ($CliBuildProc.ExitCode -ne 0) {
    Write-Error "CLI build failed with exit code $($CliBuildProc.ExitCode)"
    exit 1
}
$CliExe = Join-Path $RepoRoot "cli\bin\AsWish.CLI.exe"
if (-not (Test-Path $CliExe)) {
    Write-Error "CLI executable not found at $CliExe"
    exit 1
}
Write-Host "  -> CLI build OK: $CliExe" -ForegroundColor Green

# 4. Build and Run Tests
Write-Host "`n[3/5] Building and Running Tests Suite..." -ForegroundColor Yellow
$TestsBuildProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "tests\_build_tests.bat" -WorkingDirectory $RepoRoot -NoNewWindow -PassThru -Wait
if ($TestsBuildProc.ExitCode -ne 0) {
    Write-Error "Tests build failed with exit code $($TestsBuildProc.ExitCode)"
    exit 1
}
$TestsExe = Join-Path $RepoRoot "tests\AsWish.Tests.exe"
if (-not (Test-Path $TestsExe)) {
    Write-Error "Tests executable not found at $TestsExe"
    exit 1
}

$TestsRunProc = Start-Process -FilePath $TestsExe -WorkingDirectory (Join-Path $RepoRoot "tests") -NoNewWindow -PassThru -Wait
if ($TestsRunProc.ExitCode -ne 0) {
    Write-Error "Tests suite failed with exit code $($TestsRunProc.ExitCode)"
    exit 1
}
Write-Host "  -> All tests PASSED (Exit code: 0)" -ForegroundColor Green

# 5. Verify CLI Version Flag
Write-Host "`n[4/5] Verifying CLI --version output..." -ForegroundColor Yellow
$CliVersionOutput = & $CliExe --version
Write-Host "  Output: $CliVersionOutput"
if (-not ($CliVersionOutput -like "*$Version*")) {
    Write-Error "CLI version output does not match target version ${Version}: $CliVersionOutput"
    exit 1
}
Write-Host "  -> CLI version verified OK" -ForegroundColor Green

# 6. Stage and Package Distribution
Write-Host "`n[5/5] Packaging Release Bundle..." -ForegroundColor Yellow
$DistDir = Join-Path $RepoRoot "dist"
$BundleName = "AsWish-v$Version-win64"
$StageDir = Join-Path $DistDir $BundleName
$ZipFile = Join-Path $DistDir "$BundleName.zip"

if (Test-Path $StageDir) {
    Remove-Item -Path $StageDir -Recurse -Force
}
if (Test-Path $ZipFile) {
    Remove-Item -Path $ZipFile -Force
}
New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

$FilesToCopy = @(
    @{ Src = $DesktopExe; Dst = "AsWish.exe" },
    @{ Src = (Join-Path $RepoRoot "bin\WebView2Loader.dll"); Dst = "WebView2Loader.dll" },
    @{ Src = $CliExe; Dst = "AsWish.CLI.exe" },
    @{ Src = (Join-Path $RepoRoot "README.md"); Dst = "README.md" },
    @{ Src = (Join-Path $RepoRoot "LICENSE"); Dst = "LICENSE" },
    @{ Src = (Join-Path $RepoRoot "NOTICE"); Dst = "NOTICE" },
    @{ Src = (Join-Path $RepoRoot "CHANGELOG.md"); Dst = "CHANGELOG.md" }
)

foreach ($Item in $FilesToCopy) {
    if (-not (Test-Path $Item.Src)) {
        Write-Error "Source file missing: $($Item.Src)"
        exit 1
    }
    Copy-Item -Path $Item.Src -Destination (Join-Path $StageDir $Item.Dst) -Force
    $Size = (Get-Item $Item.Src).Length
    Write-Host "  + Copied $($Item.Dst) ($([math]::Round($Size/1KB, 1)) KB)"
}

# Compress into zip
Compress-Archive -Path "$StageDir\*" -DestinationPath $ZipFile -CompressionLevel Optimal
$ZipSize = (Get-Item $ZipFile).Length
$ZipSha256 = (Get-FileHash -Path $ZipFile -Algorithm SHA256).Hash

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " Release Packaging Completed Successfully!" -ForegroundColor Green
Write-Host " Archive:   $ZipFile" -ForegroundColor Green
Write-Host " Size:      $([math]::Round($ZipSize/1MB, 2)) MB ($ZipSize bytes)" -ForegroundColor Green
Write-Host " SHA-256:   $ZipSha256" -ForegroundColor Green
Write-Host " Package Contents:" -ForegroundColor Green
Get-ChildItem -Path $StageDir | Select-Object Name, Length | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "============================================================" -ForegroundColor Cyan

exit 0
