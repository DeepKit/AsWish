{ ============================================================================
  AsWish.Services

  Re-exports service types for convenience.
  Actual registration happens in TAsWishMainForm.RegisterServices.
  ============================================================================ }

unit AsWish.Services;

interface

uses
  AsWish.Services.Project,
  AsWish.Services.Scan,
  AsWish.Services.SpecStore;

type
  TProjectService = AsWish.Services.Project.TAsWishProjectService;
  TScanService = AsWish.Services.Scan.TAsWishScanService;
  TSpecStoreService = AsWish.Services.SpecStore.TAsWishStoreService;

implementation

end.
