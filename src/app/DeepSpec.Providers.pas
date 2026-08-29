{ ============================================================================
  DeepSpec.Providers
  ---------------------------------------------------------------------------
  Registers DeepSpec providers (Structure, MainView, Inspector) into the shell.
  Zero external dependencies.
  ============================================================================ }

unit DeepSpec.Providers;

interface

uses
  DeepSpec.Shell.Form,
  DeepSpec.UI.Intf,
  DeepSpec.Services.Project,
  DeepSpec.Services.Scan,
  DeepSpec.Services.TreeBuilder,
  DeepSpec.Controller;

procedure RegisterAllProviders(AForm: TDeepSpecShellForm;
  AProjectService: TDeepSpecProjectService;
  AScanService: TDeepSpecScanService;
  ATreeBuilder: TDeepSpecTreeBuilder;
  AController: TDeepSpecController);

implementation

uses
  DeepSpec.Models,
  DeepSpec.Providers.Structure,
  DeepSpec.Providers.MainView,
  DeepSpec.Providers.Inspector;

procedure RegisterAllProviders(AForm: TDeepSpecShellForm;
  AProjectService: TDeepSpecProjectService;
  AScanService: TDeepSpecScanService;
  ATreeBuilder: TDeepSpecTreeBuilder;
  AController: TDeepSpecController);
begin
  AForm.RegisterStructureProvider(
    TDeepSpecStructureProvider.Create(AScanService, ATreeBuilder));
  AForm.RegisterMainViewProvider(
    TDeepSpecMainViewProvider.Create(AProjectService,
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
      end));
  AForm.RegisterInspectorProvider(
    TDeepSpecInspectorProvider.Create(
      function(const ANodeId: string): TSpecNode
      begin
        Result := ATreeBuilder.FindNodeById(ANodeId);
      end));
end;

end.
