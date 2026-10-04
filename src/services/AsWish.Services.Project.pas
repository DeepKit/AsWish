{ ============================================================================
  AsWish.Services.Project

  Manages the currently open project: path, type, scan state.
  ============================================================================ }

unit AsWish.Services.Project;

interface

uses
  System.SysUtils,
  System.Classes;

type
  TAsWishProjectService = class(TInterfacedObject)
  private
    FProjectPath: string;
    FProjectName: string;
    FProjectType: string;
    FIsOpen: Boolean;
  public
    constructor Create;
    procedure OpenProject(const APath: string);
    procedure CloseProject;
    procedure SetProjectType(const AType: string);
    function AsWishPath: string;
    property ProjectPath: string read FProjectPath;
    property ProjectName: string read FProjectName;
    property ProjectType: string read FProjectType;
    property IsOpen: Boolean read FIsOpen;
  end;

implementation

uses
  System.IOUtils;

constructor TAsWishProjectService.Create;
begin
  inherited Create;
  FIsOpen := False;
end;

procedure TAsWishProjectService.OpenProject(const APath: string);
begin
  if not TDirectory.Exists(APath) then
    raise Exception.CreateFmt('Project path does not exist: %s', [APath]);

  FProjectPath := TPath.GetFullPath(APath);
  FProjectName := TPath.GetFileName(FProjectPath);
  FProjectType := 'unknown';
  FIsOpen := True;
end;

procedure TAsWishProjectService.CloseProject;
begin
  FProjectPath := '';
  FProjectName := '';
  FProjectType := '';
  FIsOpen := False;
end;

procedure TAsWishProjectService.SetProjectType(const AType: string);
begin
  FProjectType := AType;
end;

function TAsWishProjectService.AsWishPath: string;
begin
  Result := TPath.Combine(FProjectPath, '.AsWish');
end;

end.
