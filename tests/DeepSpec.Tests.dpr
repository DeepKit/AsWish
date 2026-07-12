{ ============================================================================
  DeepSpec.Tests.dpr

  DUnitX console test runner for DeepSpec unit tests.
  ============================================================================ }

program DeepSpec.Tests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  Test.DeepSpec.Yaml.Parser in 'Test.DeepSpec.Yaml.Parser.pas',
  Test.DeepSpec.Validation in 'Test.DeepSpec.Validation.pas',
  Test.DeepSpec.Models in 'Test.DeepSpec.Models.pas',
  Test.DeepSpec.CandidateIngest in 'Test.DeepSpec.CandidateIngest.pas',
  DeepSpec.Yaml.Parser in '..\src\core\DeepSpec.Yaml.Parser.pas',
  DeepSpec.Models in '..\src\models\DeepSpec.Models.pas',
  DeepSpec.Validation in '..\src\core\DeepSpec.Validation.pas',
  DeepSpec.Services.Scan in '..\src\services\DeepSpec.Services.Scan.pas',
  DeepSpec.Services.SpecStore in '..\src\services\DeepSpec.Services.SpecStore.pas',
  DeepSpec.Services.CandidateIngest in '..\src\services\DeepSpec.Services.CandidateIngest.pas';

var
  LRunner: ITestRunner;
  LResults: IRunResults;
  LLogger: ITestLogger;
  LNUnitLogger: ITestLogger;
begin
  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LLogger := TDUnitXConsoleLogger.Create(True);
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
