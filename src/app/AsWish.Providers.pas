{ ============================================================================
  AsWish.Providers
  ---------------------------------------------------------------------------
  Registers AsWish providers (Structure, MainView, Inspector) into the shell.
  Zero external dependencies.
  ============================================================================ }

unit AsWish.Providers;

interface

uses
  AsWish.Shell.Form,
  AsWish.UI.Intf,
  AsWish.Services.Project,
  AsWish.Services.Scan,
  AsWish.Services.TreeBuilder,
  AsWish.Controller;

procedure RegisterAllProviders(AForm: TAsWishShellForm;
  AProjectService: TAsWishProjectService;
  AScanService: TAsWishScanService;
  ATreeBuilder: TAsWishTreeBuilder;
  AController: TAsWishController);

implementation

uses
  AsWish.Models,
  AsWish.Providers.Structure,
  AsWish.Providers.MainView,
  AsWish.Providers.Inspector;

procedure RegisterAllProviders(AForm: TAsWishShellForm;
  AProjectService: TAsWishProjectService;
  AScanService: TAsWishScanService;
  ATreeBuilder: TAsWishTreeBuilder;
  AController: TAsWishController);
begin
  AForm.RegisterStructureProvider(
    TAsWishStructureProvider.Create(AScanService, ATreeBuilder));
  AForm.RegisterMainViewProvider(
    TAsWishMainViewProvider.Create(AProjectService,
      // BUG-11 step 2: JS Bridge ticket-create → Controller.CreateTicket
      // (defog one step + validate + persist + re-render).
      procedure(const ANodeId, ANodeTitle: string)
      begin
        AController.CreateTicket(ANodeId, ANodeTitle);
      end,
      // BUG-9 §2.3.4: JS Bridge export-optimization-prompt → Controller.
      procedure
      begin
        AController.ExportOptimizationPrompt;
      end,
      // Bundle batch review: Accept All / Reject All on bundles.html →
      // one formal decision + state transitions on all anchored nodes.
      procedure(const AAction, ABundleId: string)
      begin
        AController.ApplyBundleDecisions(AAction, ABundleId);
      end,
      // Natural language intent submit -> Controller.SubmitUserIntent
      procedure(const ANodeId, AIntentText: string)
      begin
        AController.SubmitUserIntent(ANodeId, AIntentText);
      end,
      // ChangeSet decisions -> Controller.Accept/Reject/Clarify
      procedure(const AAction, AChangeSetId, AParam: string)
      begin
        if AAction = 'changeset-accept' then
          AController.AcceptChangeSet(AChangeSetId, AParam)
        else if AAction = 'changeset-reject' then
          AController.RejectChangeSet(AChangeSetId, AParam)
        else if AAction = 'changeset-clarify' then
          AController.ClarifyChangeSet(AChangeSetId, AParam);
      end));
  AForm.RegisterInspectorProvider(
    TAsWishInspectorProvider.Create(
      function(const ANodeId: string): TSpecNode
      begin
        Result := ATreeBuilder.FindNodeById(ANodeId);
      end));
end;

end.
