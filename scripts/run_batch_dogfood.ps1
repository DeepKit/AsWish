<#
.SYNOPSIS
  Batch Dogfood Orchestrator for WO-20260905-1130-0029-甲.
#>

[CmdletBinding()]
param(
  [string]$BaseDir = "D:\_Progs\02Business\AsWish\batch_dogfood",
  [string]$CliExe = "D:\_Progs\02Business\AsWish\cli\bin\AsWish.CLI.exe",
  [string]$LogFile = "D:\_Progs\02Business\AsWish\WO\evidence\batch-dogfood-20260905-0029-甲.txt"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "BatchDogfoodCommon.ps1")
. (Join-Path $scriptDir "TestProjects.ps1")

Log-Msg "######################################################################"
Log-Msg "AsWish Batch Dogfood Suite (WO-20260905-1130-0029-甲)"
Log-Msg "Start Time: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')"
Log-Msg "Target BaseDir: $BaseDir"
Log-Msg "CLI Executable: $CliExe"
Log-Msg "######################################################################"

if (Test-Path $BaseDir) {
  Remove-Item -Recurse -Force $BaseDir -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

function Execute-Project-Cycle {
  param(
    [string]$ProjName,
    [string]$ProjDir,
    [scriptblock]$SetupBlock,
    [string]$Intent1,
    [string]$UnsafeCode,
    [string]$UnsafeFilePath,
    [string]$RejectReason,
    [string]$Intent2,
    [string]$EvolveCode,
    [string]$EvolveFilePath,
    [string]$EvolveDoc,
    [string]$EvolveDocPath,
    [string]$AcceptReason
  )
  Log-Msg "`n>>> Starting Project: $ProjName <<<"
  & $SetupBlock $ProjDir

  Run-Step "$ProjName - 1.1: Init workspace" $CliExe @("init", $ProjDir)
  Run-Step "$ProjName - 1.2: Scan workspace" $CliExe @("scan", $ProjDir)

  Run-Step "$ProjName - 2.1: Express intent" $CliExe @("intent", $ProjDir, "func-root", "function", $Intent1)
  Run-Step "$ProjName - 2.2: Generate changeset" $CliExe @("changeset", $ProjDir, "func-root", "function", $Intent1)
  Run-Step "$ProjName - 2.3: Accept changeset & Freeze B-0001" $CliExe @("changeset", "accept", $ProjDir, "cs-func-root-01", "Approved initial baseline B-0001")
  Run-Step "$ProjName - 2.4: List baselines" $CliExe @("baseline", "list", $ProjDir)
  Run-Step "$ProjName - 2.5: Verify B-0001" $CliExe @("baseline", "verify", $ProjDir, "B-0001")
  Run-Step "$ProjName - 3.1: Collect evidence for B-0001" $CliExe @("evidence", "collect", $ProjDir, "B-0001")

  $UnsafeCode | Set-Content -Path (Join-Path $ProjDir $UnsafeFilePath) -Encoding utf8
  Run-Step "$ProjName - 4.1: Re-scan workspace" $CliExe @("scan", $ProjDir)
  Run-Step "$ProjName - 4.2: Re-collect evidence" $CliExe @("evidence", "collect", $ProjDir, "B-0001")
  Run-Step "$ProjName - 4.3: Compute difference against B-0001" $CliExe @("difference", $ProjDir, "B-0001")
  Run-Step "$ProjName - 5.1: Judge Unacceptable" $CliExe @("judge", $ProjDir, "B-0001", "unacceptable", $RejectReason)

  Run-Step "$ProjName - 6.1: Revision intent" $CliExe @("intent", $ProjDir, "func-root", "function", $Intent2)
  Run-Step "$ProjName - 6.2: Generate revision changeset" $CliExe @("changeset", $ProjDir, "func-root", "function", $Intent2)
  Run-Step "$ProjName - 6.3: Accept revision changeset & Freeze B-0002" $CliExe @("changeset", "accept", $ProjDir, "cs-func-root-02", "Revision accepted for B-0002")
  Run-Step "$ProjName - 6.4: List baselines" $CliExe @("baseline", "list", $ProjDir)
  Run-Step "$ProjName - 6.5: Verify B-0002" $CliExe @("baseline", "verify", $ProjDir, "B-0002")

  $EvolveCode | Set-Content -Path (Join-Path $ProjDir $EvolveFilePath) -Encoding utf8
  $EvolveDoc | Set-Content -Path (Join-Path $ProjDir $EvolveDocPath) -Encoding utf8

  Run-Step "$ProjName - 7.1: Re-scan for Evolution" $CliExe @("scan", $ProjDir)
  Run-Step "$ProjName - 7.2: Collect evidence for B-0002" $CliExe @("evidence", "collect", $ProjDir, "B-0002")
  Run-Step "$ProjName - 7.3: Compute difference against B-0002" $CliExe @("difference", $ProjDir, "B-0002")
  Run-Step "$ProjName - 7.4: Judge Acceptable" $CliExe @("judge", $ProjDir, "B-0002", "acceptable", $AcceptReason)
  Run-Step "$ProjName - 7.5: Evolve to B-0003" $CliExe @("evolve", $ProjDir, "B-0002", "Evolution to Baseline B-0003 from reality")
  Run-Step "$ProjName - 7.6: List baselines" $CliExe @("baseline", "list", $ProjDir)
  Run-Step "$ProjName - 7.7: Verify B-0003" $CliExe @("baseline", "verify", $ProjDir, "B-0003")

  # Validation assertions
  $decFile = Join-Path $ProjDir ".AsWish\decisions\requirement-decisions.yaml"
  $decText = Get-Content -Raw -Encoding utf8 $decFile
  Assert-Condition ($decText -match 'id: "dec-0001"') "$ProjName contains dec-0001"
  Assert-Condition ($decText -match 'id: "dec-0002"') "$ProjName contains dec-0002 (unacceptable)"
  Assert-Condition ($decText -match 'id: "dec-0003"') "$ProjName contains dec-0003"
  Assert-Condition ($decText -match 'id: "dec-0004"') "$ProjName contains dec-0004"
  Assert-Condition ($decText -match 'id: "dec-0005"') "$ProjName contains dec-0005 (evolve)"

  $b3Snap = Get-ChildItem (Join-Path $ProjDir ".AsWish\snapshots\*B-0003*\snapshot.yaml") | Select-Object -First 1
  $b3Text = Get-Content -Raw -Encoding utf8 $b3Snap.FullName
  Assert-Condition ($b3Text -match 'parent_baseline_id: "B-0002"') "$ProjName B-0003 snapshot has parent_baseline_id: B-0002"
  Assert-Condition (Test-Path (Join-Path $ProjDir ".AsWish\llm\change-set-cs-func-root-01.yaml")) "$ProjName cs-01 exists"
  Assert-Condition (Test-Path (Join-Path $ProjDir ".AsWish\llm\change-set-cs-func-root-02.yaml")) "$ProjName cs-02 exists"
}

# 1. Project 1: Small Utility
$p1DivCode = @"
unit CalcEngine;
interface
function AddInt(A, B: Integer): Integer;
function SubInt(A, B: Integer): Integer;
function MulInt(A, B: Integer): Integer;
function DivInt(A, B: Integer): Integer;
implementation
function AddInt(A, B: Integer): Integer; begin Result := A + B; end;
function SubInt(A, B: Integer): Integer; begin Result := A - B; end;
function MulInt(A, B: Integer): Integer; begin Result := A * B; end;
function DivInt(A, B: Integer): Integer; begin Result := A div B; end;
end.
"@
$p1SciCode = "unit ScientificCalc; interface function PowerInt(ABase, AExp: Integer): Int64; implementation function PowerInt(ABase, AExp: Integer): Int64; begin Result := 1; end; end."
$p1SciDoc = "# Scientific Extension`nPower operations."
Execute-Project-Cycle -ProjName "proj_calc_tool" -ProjDir (Join-Path $BaseDir "proj_calc_tool") `
  -SetupBlock ${function:Setup-Project1-Calc} `
  -Intent1 "Add safe integer division with DivZero validation" `
  -UnsafeCode $p1DivCode -UnsafeFilePath "src\CalcEngine.pas" `
  -RejectReason "Missing DivZero error handling; reject for Revision" `
  -Intent2 "Revise division specification to explicitly require EDivByZero check" `
  -EvolveCode $p1SciCode -EvolveFilePath "src\ScientificCalc.pas" `
  -EvolveDoc $p1SciDoc -EvolveDocPath "docs\Scientific.md" `
  -AcceptReason "Scientific calculations and documentation approved"

# 2. Project 2: Medium Task Service
$p2ItemCode = "unit TaskItem; interface type TTaskItem = record Id: string; Title: string; Status, Priority: Integer; end; implementation end."
$p2ExpCode = "unit TaskExport; interface function ExportTasksToCsv: string; implementation function ExportTasksToCsv: string; begin Result := 'id,title,status,priority'; end; end."
$p2ExpDoc = "# Task Export Spec`nBatch CSV export."
Execute-Project-Cycle -ProjName "proj_task_service" -ProjDir (Join-Path $BaseDir "proj_task_service") `
  -SetupBlock ${function:Setup-Project2-Task} `
  -Intent1 "Implement task priority levels and tag filtering" `
  -UnsafeCode $p2ItemCode -UnsafeFilePath "src\models\TaskItem.pas" `
  -RejectReason "Tag filtering is completely missing; reject for Revision" `
  -Intent2 "Add tag list field and filter query parameters to task domain" `
  -EvolveCode $p2ExpCode -EvolveFilePath "src\services\TaskExport.pas" `
  -EvolveDoc $p2ExpDoc -EvolveDocPath "docs\ExportSpec.md" `
  -AcceptReason "Task export service and documentation approved"

# 3. Project 3: Edge Structure with Views
$p3SchemaCode = "unit PipelineSchema; interface type TPipelineRecord = record StreamId: string; PayloadBytes, Timestamp: Int64; RetryCount: Integer; end; function ValidateStreamRecord(const ARecord: TPipelineRecord): Boolean; implementation function ValidateStreamRecord(const ARecord: TPipelineRecord): Boolean; begin Result := True; end; end."
$p3MetricsCode = "unit MetricsView; interface uses System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls; type TMetricsForm = class(TForm) lblThroughput: TLabel; end; implementation end."
$p3MetricsDoc = "# Throughput Spec`nIngress monitoring."
Execute-Project-Cycle -ProjName "proj_data_pipeline" -ProjDir (Join-Path $BaseDir "proj_data_pipeline") `
  -SetupBlock ${function:Setup-Project3-Pipeline} `
  -Intent1 "Add automatic retry policy with exponential backoff" `
  -UnsafeCode $p3SchemaCode -UnsafeFilePath "src\data\PipelineSchema.pas" `
  -RejectReason "Exponential backoff calculation missing; reject for Revision" `
  -Intent2 "Add MaxRetries and BackoffBaseSeconds parameters to retry policy" `
  -EvolveCode $p3MetricsCode -EvolveFilePath "src\views\MetricsView.pas" `
  -EvolveDoc $p3MetricsDoc -EvolveDocPath "docs\ThroughputSpec.md" `
  -AcceptReason "Throughput metrics UI and documentation approved"

Log-Msg "`n========================================================"
Log-Msg "BATCH DOGFOOD COMPLETED: All 3 projects passed with 100% integrity!"
Log-Msg "End Time: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')"

New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
$global:LogLines | Set-Content -Path $LogFile -Encoding utf8
Log-Msg "Log evidence successfully saved to: $LogFile"
