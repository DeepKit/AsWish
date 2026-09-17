program FreezeBaseline;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, System.IOUtils,
  AsWish.Models in '..\..\src\models\AsWish.Models.pas',
  AsWish.Hash in '..\..\src\core\AsWish.Hash.pas',
  AsWish.Yaml.Parser in '..\..\src\core\AsWish.Yaml.Parser.pas',
  AsWish.Yaml.Writer in '..\..\src\core\AsWish.Yaml.Writer.pas',
  AsWish.Services.Snapshot in '..\..\src\services\AsWish.Services.Snapshot.pas',
  AsWish.Services.Storage in '..\..\src\app\AsWish.Services.Storage.pas';

var
  LStore: TAsWishStoreService;
  LSnapSvc: TAsWishSnapshotService;
  LDecision: TAsWishDecision;
  LChangeSet: TAsWishChangeSet;
  LBaseId: string;
begin
  try
    LStore := TAsWishStoreService.Create;
    try
      LStore.InitializeDirect(GetCurrentDir);
      LSnapSvc := TAsWishSnapshotService.Create(LStore);
      try
        LDecision := Default(TAsWishDecision);
        LDecision.Id := 'DEC-20260906-1234';
        
        LChangeSet := Default(TAsWishChangeSet);
        LChangeSet.Id := 'CS-20260906-1234';
        LChangeSet.IntentNodeId := 'INT-20260906-1234';

        ForceDirectories('.AsWish\trees');
        TFile.Copy('Spikes\WO-0030-VCL-HighFidelity\fixture\view-tree.yaml', '.AsWish\trees\view-tree.yaml', True);

        LBaseId := LSnapSvc.CreateBaseline(LDecision, LChangeSet, '', 
                     'view', 'WO-0030-Spike-Baseline', 
                     'vcl_profile_v1', 'visual_binding_v1');
                     
        Writeln('SUCCESS:', LBaseId);
      finally
        LSnapSvc.Free;
      end;
    finally
      LStore.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
