{ ============================================================================
  Test.AsWish.Prompts

  DUnitX tests for the grilling_ticket prompt export.
  ============================================================================ }

unit Test.AsWish.Prompts;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TGrillingPromptTests = class
  public
    [Test]
    procedure GrillingTicket_WritesStructuredPrompt;
    [Test]
    procedure NonGrillingIssue_DoesNotWritePrompt;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  AsWish.Models,
  AsWish.Services.Prompts;

function NewTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-prompt-test-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
end;

procedure TGrillingPromptTests.GrillingTicket_WritesStructuredPrompt;
var
  LDir, LPath, LContent: string;
  LService: TAsWishPromptService;
  LNodes: TList<TSpecNode>;
  LNode: TSpecNode;
  LIssue: TSpecIssue;
begin
  LDir := NewTempDir;
  LService := TAsWishPromptService.Create;
  LNodes := TList<TSpecNode>.Create;
  try
    TDirectory.CreateDirectory(LDir);
    LService.Initialize(LDir);

    LNode := TSpecNode.MakeNew('func-checkout', ttFunction, 'Checkout', 'capability');
    LNode.Summary := 'Completes an order checkout';
    LNode.FogState := fsFoggy;
    LNode.HasFogState := True;
    LNodes.Add(LNode);

    LIssue := Default(TSpecIssue);
    LIssue.Id := 'issue-grill-checkout';
    LIssue.IssueType := itGrillingTicket;
    LIssue.Severity := isHigh;
    LIssue.Title := 'Clarify checkout outcome';
    LIssue.Description := 'The desired checkout outcome and scope are not explicit.';
    LIssue.AffectedNodes := TArray<string>.Create(LNode.Id);
    LIssue.Status := issOpen;

    LPath := LService.WriteGrillingPrompt(LIssue, LNodes);
    LContent := TFile.ReadAllText(LPath, TEncoding.UTF8);

    Assert.AreEqual<string>(
      TPath.Combine(LDir, 'prompts\grilling-ticket-issue-grill-checkout.md'),
      LPath, 'grilling prompt path must be stable and issue-specific');
    Assert.IsTrue(TFile.Exists(LPath), 'grilling prompt must be written');
    Assert.IsTrue(LContent.Contains(#$51B3#$7B56#$6811#$62C6#$89E3),
      'prompt must contain decision-tree decomposition');
    Assert.IsTrue(LContent.Contains(#$76EE#$6807) and
      LContent.Contains(#$8FB9#$754C) and
      LContent.Contains(#$9A8C#$6536), 'prompt must contain the three questions');
    Assert.IsTrue(LContent.Contains(#$63A8#$8350#$7B54#$6848),
      'each clarification question must offer a recommended answer');
    Assert.IsTrue(LContent.Contains('func-checkout') and
      LContent.Contains('foggy') and
      LContent.Contains(#$5F85#$89E3#$95EE#$9898),
      'prompt must include the affected fog node and pending question');
    Assert.IsTrue(LContent.Contains(#$4F9D#$8D56) and
      LContent.Contains(#$5148#$95EE),
      'decision branches must declare dependencies and order');
  finally
    LNodes.Free;
    LService.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

procedure TGrillingPromptTests.NonGrillingIssue_DoesNotWritePrompt;
var
  LDir, LPath: string;
  LService: TAsWishPromptService;
  LIssue: TSpecIssue;
begin
  LDir := NewTempDir;
  LService := TAsWishPromptService.Create;
  try
    TDirectory.CreateDirectory(LDir);
    LService.Initialize(LDir);

    LIssue := Default(TSpecIssue);
    LIssue.Id := 'issue-ambiguity';
    LIssue.IssueType := itAmbiguity;
    LPath := LService.WriteGrillingPrompt(LIssue, nil);

    Assert.AreEqual<string>('', LPath,
      'non-grilling issues must not produce a grilling prompt');
    Assert.IsFalse(TFile.Exists(TPath.Combine(LDir,
      'prompts\grilling-ticket-issue-ambiguity.md')),
      'non-grilling issues must not write a grilling prompt');
  finally
    LService.Free;
    TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGrillingPromptTests);

end.
