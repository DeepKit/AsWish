{ ============================================================================
  AsWish.Tests.dpr

  DUnitX console test runner for AsWish unit tests.
  ============================================================================ }

program AsWish.Tests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  Test.AsWish.FixtureHelper in 'Test.AsWish.FixtureHelper.pas',
  Test.AsWish.Yaml.Parser in 'Test.AsWish.Yaml.Parser.pas',
  Test.AsWish.Validation in 'Test.AsWish.Validation.pas',
  Test.AsWish.Models in 'Test.AsWish.Models.pas',
  Test.AsWish.Scan in 'Test.AsWish.Scan.pas',
  Test.AsWish.CandidateIngest in 'Test.AsWish.CandidateIngest.pas',
  Test.AsWish.Decisions in 'Test.AsWish.Decisions.pas',
  Test.AsWish.SpecStore in 'Test.AsWish.SpecStore.pas',
  Test.AsWish.TreeBuilder in 'Test.AsWish.TreeBuilder.pas',
  Test.AsWish.TextIO in 'Test.AsWish.TextIO.pas',
  Test.AsWish.Render in 'Test.AsWish.Render.pas',
  Test.AsWish.Prompts in 'Test.AsWish.Prompts.pas',
  Test.AsWish.Controller in 'Test.AsWish.Controller.pas',
  Test.AsWish.Snapshot in 'Test.AsWish.Snapshot.pas',
  Test.AsWish.Baseline in 'Test.AsWish.Baseline.pas',
  Test.AsWish.VisualBaseline in 'Test.AsWish.VisualBaseline.pas',
  Test.AsWish.Evidence in 'Test.AsWish.Evidence.pas',
  Test.AsWish.Difference in 'Test.AsWish.Difference.pas',
  Test.AsWish.Difference.L2L3 in 'Test.AsWish.Difference.L2L3.pas',
  Test.AsWish.RevisionEvolution in 'Test.AsWish.RevisionEvolution.pas',
  Test.AsWish.GUIDecisions in 'Test.AsWish.GUIDecisions.pas',
  Test.AsWish.VisualWorkflow in 'Test.AsWish.VisualWorkflow.pas',
  Test.AsWish.VisualWorkflow.Evolution in 'Test.AsWish.VisualWorkflow.Evolution.pas',
  Test.AsWish.VisualWorkflow.Provenance in 'Test.AsWish.VisualWorkflow.Provenance.pas',
  Test.AsWish.VisualWorkflow.Provenance.Diff in 'Test.AsWish.VisualWorkflow.Provenance.Diff.pas',
  Test.AsWish.VisualWorkflow.Provenance.Compliant in 'Test.AsWish.VisualWorkflow.Provenance.Compliant.pas',
  Test.AsWish.EHAI.Binding in 'Test.AsWish.EHAI.Binding.pas',
  Test.AsWish.Commons in 'Test.AsWish.Commons.pas',
  Test.AsWish.Encoding in 'Test.AsWish.Encoding.pas',
  Test.AsWish.CommandLine in 'Test.AsWish.CommandLine.pas',
  AsWish.CommandLine in '..\src\core\AsWish.CommandLine.pas',
  AsWish.UI.Types in '..\src\core\AsWish.UI.Types.pas',
  AsWish.UI.Intf in '..\src\core\AsWish.UI.Intf.pas',
  AsWish.Config in '..\src\core\AsWish.Config.pas',
  AsWish.Security in '..\src\core\AsWish.Security.pas',
  AsWish.Logger in '..\src\core\AsWish.Logger.pas',
  AsWish.Yaml.Parser in '..\src\core\AsWish.Yaml.Parser.pas',
  AsWish.Models in '..\src\models\AsWish.Models.pas',
  AsWish.Validation in '..\src\core\AsWish.Validation.pas',
  AsWish.Services.Scan in '..\src\services\AsWish.Services.Scan.pas',
  AsWish.Services.SpecStore in '..\src\services\AsWish.Services.SpecStore.pas',
  AsWish.Services.Decisions in '..\src\services\AsWish.Services.Decisions.pas',
  AsWish.Services.Project in '..\src\services\AsWish.Services.Project.pas',
  AsWish.Services.TreeBuilder in '..\src\services\AsWish.Services.TreeBuilder.pas',
  AsWish.Services.Render in '..\src\services\AsWish.Services.Render.pas',
  AsWish.Services.Prompts in '..\src\services\AsWish.Services.Prompts.pas',
  AsWish.Services.Settings in '..\src\services\AsWish.Services.Settings.pas',
  AsWish.Services.LLM in '..\src\services\AsWish.Services.LLM.pas',
  AsWish.Services.Snapshot in '..\src\services\AsWish.Services.Snapshot.pas',
  AsWish.Services.Context in '..\src\services\AsWish.Services.Context.pas',
  AsWish.Controller in '..\src\controllers\AsWish.Controller.pas',
  AsWish.Services.CandidateIngest in '..\src\services\AsWish.Services.CandidateIngest.pas',
  AsWish.Services.EvidenceCollector in '..\src\services\AsWish.Services.EvidenceCollector.pas',
  AsWish.Services.Difference in '..\src\services\AsWish.Services.Difference.pas',
  AsWish.Services.VisualWorkflow in '..\src\services\AsWish.Services.VisualWorkflow.pas',
  AsWish.Plugins.VCL.Difference in '..\src\services\AsWish.Plugins.VCL.Difference.pas',
  AsWish.Binding.HB in '..\src\services\AsWish.Binding.HB.pas',
  AsWish.Services.Commons in '..\src\services\AsWish.Services.Commons.pas';

var
  LRunner: ITestRunner;
  LResults: IRunResults;
  LLogger: ITestLogger;
  LNUnitLogger: ITestLogger;
begin
  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LLogger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
    LRunner.AddLogger(LLogger);

    LNUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LNUnitLogger);

    // FailsOnNoAsserts=True: every [Test] must contain a real Assert.
  // Previously False, which let 7 zero-assert tests pass vacuously
  // (bugfix.md BUG-4). All such tests now carry real assertions.
  LRunner.FailsOnNoAsserts := True;
    LResults := LRunner.Execute;

    if not LResults.AllPassed then
      System.ExitCode := 1;
  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
