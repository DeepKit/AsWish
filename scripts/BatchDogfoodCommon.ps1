<#
.SYNOPSIS
  Common helper functions and runners for AsWish Batch Dogfood.
#>

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$global:LogLines = [System.Collections.Generic.List[string]]::new()

function Log-Msg {
  param([string]$Text)
  Write-Host $Text
  $global:LogLines.Add($Text)
}

function Run-Step {
  param(
    [string]$Title,
    [string]$CliExe,
    [string[]]$ArgsList
  )
  Log-Msg ""
  Log-Msg "========================================================"
  Log-Msg "[$Title]"
  Log-Msg "Command: $CliExe $($ArgsList -join ' ')"

  $pinfo = New-Object System.Diagnostics.ProcessStartInfo
  $pinfo.FileName = $CliExe
  $pinfo.Arguments = ($ArgsList | ForEach-Object {
    if ($_ -match '\s' -and -not ($_ -match '^".*"$')) { '"{0}"' -f $_ } else { $_ }
  }) -join ' '
  $pinfo.RedirectStandardOutput = $true
  $pinfo.RedirectStandardError = $true
  $pinfo.UseShellExecute = $false
  $pinfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
  $pinfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8

  $p = [System.Diagnostics.Process]::Start($pinfo)
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()

  Log-Msg "Exit code: $($p.ExitCode)"
  if ($stdout.Trim().Length -gt 0) {
    Log-Msg "Output:"
    Log-Msg $stdout.Trim()
  }
  if ($stderr.Trim().Length -gt 0) {
    Log-Msg "Stderr:"
    Log-Msg $stderr.Trim()
  }

  if ($p.ExitCode -ne 0) {
    throw "Command failed with exit code $($p.ExitCode): $CliExe $($ArgsList -join ' ')"
  }
  return $stdout
}

function Assert-Condition {
  param(
    [bool]$Condition,
    [string]$Message
  )
  if (-not $Condition) {
    throw "ASSERTION FAILED: $Message"
  }
  Log-Msg "[ASSERT PASS] $Message"
}
