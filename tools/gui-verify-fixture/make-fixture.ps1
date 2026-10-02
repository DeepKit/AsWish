param(
    [string]$TargetDir = "$PSScriptRoot\mirror"
)
$ErrorActionPreference = "Stop"

# 1. Resolve real installation directory from registry
$regKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
$pv = (Get-ItemProperty -Path $regKey -Name pv -ErrorAction SilentlyContinue).pv
$loc = (Get-ItemProperty -Path $regKey -Name location -ErrorAction SilentlyContinue).location
if (-not $loc) { $loc = "C:\Program Files (x86)\Microsoft\EdgeWebView\Application" }
$sourceDir = Join-Path $loc $pv
if (-not (Test-Path $sourceDir)) { throw "Source WebView2 directory not found: $sourceDir" }

# 2. Compile Sleeper.dpr if missing or outdated
$sleeperSrc = "$PSScriptRoot\Sleeper.dpr"
$sleeperExe = "$PSScriptRoot\Sleeper.exe"
if (-not (Test-Path $sleeperExe) -or ((Get-Item $sleeperSrc).LastWriteTime -gt (Get-Item $sleeperExe).LastWriteTime)) {
    Write-Host "[make-fixture] Compiling Sleeper.dpr ..."
    $bds = $env:BDS
    if (-not $bds) { $bds = "d:\Program Files (x86)\Embarcadero\Studio\37.0" }
    $dcc = "$bds\bin\dcc64.exe"
    & $dcc -B "-NSSystem;Winapi;System.Win" -E"$PSScriptRoot" "$sleeperSrc"
    if ($LASTEXITCODE -ne 0) { throw "dcc64 failed with exit code $LASTEXITCODE" }
}

# 3. Create mirror structure
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

$sourceItems = Get-ChildItem -Path $sourceDir
foreach ($item in $sourceItems) {
    $destPath = Join-Path $TargetDir $item.Name
    if ($item.Name -ieq "msedgewebview2.exe") {
        Copy-Item -Path $sleeperExe -Destination $destPath -Force
    } elseif ($item.PSIsContainer) {
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Junction -Path $destPath -Target $item.FullName | Out-Null
        }
    } else {
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType SymbolicLink -Path $destPath -Target $item.FullName | Out-Null
        }
    }
}
$delayPath = Join-Path $TargetDir "delay.txt"
[System.IO.File]::WriteAllText($delayPath, "1500")

# 4. Self-check
$sourceCount = $sourceItems.Count
$mirrorItems = Get-ChildItem -Path $TargetDir
$mirrorCount = $mirrorItems.Count
$sleeperExists = Test-Path (Join-Path $TargetDir "msedgewebview2.exe")
$delayVal = 0
$delayValid = (Test-Path $delayPath) -and [int]::TryParse((Get-Content $delayPath -Raw).Trim(), [ref]$delayVal) -and ($delayVal -ge 0) -and ($delayVal -le 30000)

Write-Host "[make-fixture] Real item count: $sourceCount"
Write-Host "[make-fixture] Mirror item count: $mirrorCount"
Write-Host "[make-fixture] msedgewebview2.exe exists: $sleeperExists"
Write-Host "[make-fixture] delay.txt valid: $delayValid (val=$delayVal)"

if (($mirrorCount -ne ($sourceCount + 1)) -or (-not $sleeperExists) -or (-not $delayValid)) {
    throw "Verification failed: mirror ($mirrorCount) != source+1 ($($sourceCount + 1)), sleeper missing, or invalid delay.txt"
}
Write-Host "[make-fixture] Mirror fixture ready."
