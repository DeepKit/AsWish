{ ============================================================================
  Test.AsWish.Encoding
  Unit test guarding Pascal source UTF-8 BOM encoding invariants (WO-20260930-0063).
  Asserts that any Pascal source file containing Chinese text must have a UTF-8 BOM
  to prevent dcc64 ANSI/GBK misinterpretation and string mojibake at runtime.
  ============================================================================ }
unit Test.AsWish.Encoding;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils;

type
  [TestFixture]
  TTestAsWishEncoding = class
  public
    [Test]
    procedure Test01_PascalSourcesWithChinese_MustHaveUtf8Bom;
  end;

implementation

function HasChineseInCode(const AText: string): Boolean;
var
  LLines: TArray<string>;
  LLine: string;
  I, LLen: Integer;
  LInBrace, LInParen: Boolean;
  C: Char;
begin
  Result := False;
  LLines := AText.Split([#10]);
  LInBrace := False;
  LInParen := False;

  for LLine in LLines do
  begin
    I := 1;
    LLen := Length(LLine);
    while I <= LLen do
    begin
      C := LLine[I];
      if LInBrace then
      begin
        if C = '}' then
          LInBrace := False;
        Inc(I);
      end
      else if LInParen then
      begin
        if (C = '*') and (I < LLen) and (LLine[I + 1] = ')') then
        begin
          LInParen := False;
          Inc(I, 2);
        end
        else
          Inc(I);
      end
      else
      begin
        if (C = '/') and (I < LLen) and (LLine[I + 1] = '/') then
          Break // rest of line is comment
        else if (C = '{') and not ((I < LLen) and (LLine[I + 1] = '$')) then
        begin
          LInBrace := True;
          Inc(I);
        end
        else if (C = '(') and (I < LLen) and (LLine[I + 1] = '*') then
        begin
          LInParen := True;
          Inc(I, 2);
        end
        else
        begin
          if (Ord(C) >= $4E00) and (Ord(C) <= $9FFF) then
            Exit(True);
          Inc(I);
        end;
      end;
    end;
  end;
end;

procedure TTestAsWishEncoding.Test01_PascalSourcesWithChinese_MustHaveUtf8Bom;
var
  LRepoRoot, LSubDir, LFile, LRelPath: string;
  LDirs: array[0..2] of string;
  LFiles: TArray<string>;
  LBytes: TBytes;
  LHasBom: Boolean;
  LText: string;
  LMissingList: TStringList;
begin
  LRepoRoot := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..'));
  if not TDirectory.Exists(TPath.Combine(LRepoRoot, 'src')) then
    LRepoRoot := TPath.GetFullPath(TPath.Combine(LRepoRoot, '..'));

  Assert.IsTrue(TDirectory.Exists(TPath.Combine(LRepoRoot, 'src')), 'Repo root src/ must exist');

  LDirs[0] := 'src';
  LDirs[1] := 'cli';
  LDirs[2] := 'tests';

  LMissingList := TStringList.Create;
  try
    for LSubDir in LDirs do
    begin
      LFiles := TDirectory.GetFiles(TPath.Combine(LRepoRoot, LSubDir), '*.pas', TSearchOption.soAllDirectories);
      for LFile in LFiles do
      begin
        LBytes := TFile.ReadAllBytes(LFile);
        LHasBom := (Length(LBytes) >= 3) and
                   (LBytes[0] = $EF) and
                   (LBytes[1] = $BB) and
                   (LBytes[2] = $BF);

        LText := TEncoding.UTF8.GetString(LBytes);
        if HasChineseInCode(LText) and not LHasBom then
        begin
          LRelPath := ExtractRelativePath(LRepoRoot + PathDelim, LFile);
          LMissingList.Add(LRelPath);
        end;
      end;
    end;

    Assert.AreEqual(0, LMissingList.Count,
      'Pascal source files containing Chinese code must have UTF-8 BOM: ' + LMissingList.CommaText);
  finally
    LMissingList.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsWishEncoding);
end.
