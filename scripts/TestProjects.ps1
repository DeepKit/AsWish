<#
.SYNOPSIS
  Heterogeneous project fixtures generator for AsWish Batch Dogfood.
#>

function Setup-Project1-Calc {
  param([string]$ProjDir)
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "src") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "docs") -Force | Out-Null

  @"
# MiniCalc Tool
High-precision integer and rational calculator library.
"@ | Set-Content -Path (Join-Path $ProjDir "docs\Overview.md") -Encoding utf8

  @"
unit CalcEngine;

interface

function AddInt(A, B: Integer): Integer;
function SubInt(A, B: Integer): Integer;
function MulInt(A, B: Integer): Integer;

implementation

function AddInt(A, B: Integer): Integer;
begin
  Result := A + B;
end;

function SubInt(A, B: Integer): Integer;
begin
  Result := A - B;
end;

function MulInt(A, B: Integer): Integer;
begin
  Result := A * B;
end;

end.
"@ | Set-Content -Path (Join-Path $ProjDir "src\CalcEngine.pas") -Encoding utf8
}

function Setup-Project2-Task {
  param([string]$ProjDir)
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "src\models") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "src\services") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "src\storage") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "docs") -Force | Out-Null

  @"
# TaskCore Architecture
Multi-module domain service for distributed task management.
"@ | Set-Content -Path (Join-Path $ProjDir "docs\Architecture.md") -Encoding utf8

  @"
unit TaskItem;

interface

type
  TTaskItem = record
    Id: string;
    Title: string;
    Status: Integer;
  end;

implementation

end.
"@ | Set-Content -Path (Join-Path $ProjDir "src\models\TaskItem.pas") -Encoding utf8

  @"
unit TaskManager;

interface

uses TaskItem;

function CreateTask(const ATitle: string): TTaskItem;
function GetActiveTaskCount: Integer;

implementation

function CreateTask(const ATitle: string): TTaskItem;
begin
  Result.Id := 'TASK-1';
  Result.Title := ATitle;
  Result.Status := 0;
end;

function GetActiveTaskCount: Integer;
begin
  Result := 1;
end;

end.
"@ | Set-Content -Path (Join-Path $ProjDir "src\services\TaskManager.pas") -Encoding utf8

  @"
unit TaskStore;

interface

function SaveTaskCountToDisk(ACount: Integer): Boolean;

implementation

function SaveTaskCountToDisk(ACount: Integer): Boolean;
begin
  Result := True;
end;

end.
"@ | Set-Content -Path (Join-Path $ProjDir "src\storage\TaskStore.pas") -Encoding utf8
}

function Setup-Project3-Pipeline {
  param([string]$ProjDir)
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "src\data") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "src\views") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $ProjDir "docs") -Force | Out-Null

  @"
# DataStream Pipeline Specification
Defines streaming ingest, real-time transformations, and dashboard representations.
"@ | Set-Content -Path (Join-Path $ProjDir "docs\PipelineSpec.md") -Encoding utf8

  @"
unit PipelineSchema;

interface

type
  TPipelineRecord = record
    StreamId: string;
    PayloadBytes: Int64;
    Timestamp: Int64;
  end;

function ValidateStreamRecord(const ARecord: TPipelineRecord): Boolean;

implementation

function ValidateStreamRecord(const ARecord: TPipelineRecord): Boolean;
begin
  Result := ARecord.StreamId <> '';
end;

end.
"@ | Set-Content -Path (Join-Path $ProjDir "src\data\PipelineSchema.pas") -Encoding utf8

  @"
unit DashboardForm;

interface

uses System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls;

type
  TDashboardView = class(TForm)
    lblStatus: TLabel;
    btnStart: TButton;
  end;

implementation

end.
"@ | Set-Content -Path (Join-Path $ProjDir "src\views\DashboardForm.pas") -Encoding utf8

  @"
object DashboardView: TDashboardView
  Left = 0
  Top = 0
  Caption = 'Pipeline Dashboard'
  ClientHeight = 300
  ClientWidth = 500
  object lblStatus: TLabel
    Left = 24
    Top = 24
    Caption = 'Ready'
  end
  object btnStart: TButton
    Left = 24
    Top = 64
    Caption = 'Start'
  end
end
"@ | Set-Content -Path (Join-Path $ProjDir "src\views\DashboardForm.dfm") -Encoding utf8
}
