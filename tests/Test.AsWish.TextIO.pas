{ ============================================================================
  Test.AsWish.TextIO

  Verifies that text reading survives the encodings a real repository
  actually contains. Before AsWish.TextIO existed, a single non-UTF-8 doc file
  raised EEncodingError and aborted the whole scan.
  ============================================================================ }

unit Test.AsWish.TextIO;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  DUnitX.TestFramework,
  AsWish.TextIO;

type
  [TestFixture]
  TTextIOTests = class
  public
    [Test]
    procedure ReadLines_PlainUtf8_ReturnsContent;
    [Test]
    procedure ReadLines_Utf8WithBom_StripsBomOnly;
    [Test]
    procedure ReadLines_Utf16LeWithBom_DecodesAndStripsBom;
    [Test]
    procedure ReadLines_Utf16BeWithBom_DecodesAndStripsBom;
    [Test]
    procedure ReadLines_BomlessUtf16Le_DecodesWithoutDroppingFirstChar;
    [Test]
    procedure ReadLines_GbkEncoded_FallsBackInsteadOfRaising;
    [Test]
    procedure ReadLines_CrlfAndLoneCr_SplitIntoLines;
    [Test]
    procedure ReadLines_MissingFile_ReturnsEmptyArray;
    [Test]
    procedure ReadLines_TrailingNewline_DoesNotAddEmptyLine;
  end;

implementation

function NewTextIOTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'aswish-textio-' +
    TGuid.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(Result);
end;

function ConcatBytes(const ALeft, ARight: TBytes): TBytes;
begin
  SetLength(Result, Length(ALeft) + Length(ARight));
  if Length(ALeft) > 0 then
    Move(ALeft[0], Result[0], Length(ALeft));
  if Length(ARight) > 0 then
    Move(ARight[0], Result[Length(ALeft)], Length(ARight));
end;

procedure WriteBytes(const APath: string; const AContent: TBytes);
begin
  TFile.WriteAllBytes(APath, AContent);
end;

procedure TTextIOTests.ReadLines_PlainUtf8_ReturnsContent;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.md');
    WriteBytes(LPath, TEncoding.UTF8.GetBytes('# 标题' + sLineBreak + 'body'));

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(2, LCount);
    Assert.AreEqual('# 标题', LLines[0]);
    Assert.AreEqual('body', LLines[1]);
    Assert.AreEqual(Ord(teUtf8), Ord(LEnc), 'Plain UTF-8 must not be reported as degraded');
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTextIOTests.ReadLines_Utf8WithBom_StripsBomOnly;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
  LBom: TBytes;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.md');
    // BOM is three bytes; dropping a fourth byte silently eats the first char.
    LBom := TEncoding.UTF8.GetPreamble;
    WriteBytes(LPath, ConcatBytes(LBom, TEncoding.UTF8.GetBytes('# 标题' + sLineBreak + 'body')));

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(2, LCount);
    Assert.AreEqual('# 标题', LLines[0],
      'The BOM must be stripped without consuming the first character');
    Assert.AreEqual(Ord(teUtf8), Ord(LEnc), 'A UTF-8 BOM is still UTF-8, not a fallback');
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTextIOTests.ReadLines_Utf16LeWithBom_DecodesAndStripsBom;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.txt');
    WriteBytes(LPath, ConcatBytes(TEncoding.Unicode.GetPreamble,
      TEncoding.Unicode.GetBytes('# 标题' + sLineBreak + 'body')));

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(2, LCount);
    Assert.AreEqual('# 标题', LLines[0]);
    Assert.AreEqual(Ord(teUtf16Le), Ord(LEnc));
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTextIOTests.ReadLines_Utf16BeWithBom_DecodesAndStripsBom;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.txt');
    WriteBytes(LPath, ConcatBytes(TEncoding.BigEndianUnicode.GetPreamble,
      TEncoding.BigEndianUnicode.GetBytes('# 标题' + sLineBreak + 'body')));

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(2, LCount);
    Assert.AreEqual('# 标题', LLines[0]);
    Assert.AreEqual(Ord(teUtf16Be), Ord(LEnc));
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTextIOTests.ReadLines_BomlessUtf16Le_DecodesWithoutDroppingFirstChar;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.txt');
    // No BOM at all: a heuristic must detect UTF-16 and must NOT strip bytes,
    // because here the first two bytes are the character '#', not a BOM.
    WriteBytes(LPath, TEncoding.Unicode.GetBytes('# 标题' + sLineBreak + 'body'));

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(2, LCount);
    Assert.AreEqual('# 标题', LLines[0],
      'A heuristic-detected UTF-16 file has no BOM to strip');
    Assert.AreEqual(Ord(teUtf16Le), Ord(LEnc));
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTextIOTests.ReadLines_GbkEncoded_FallsBackInsteadOfRaising;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.md');
    // GBK literal bytes: "# 标题" + CRLF + "body" in code page 936.
    // Written as constants because TEncoding.GetEncoding(936) can hand back
    // UTF-8 bytes on a machine whose ANSI code page is not 936, which would
    // make this test silently assert nothing about GBK at all.
    WriteBytes(LPath, [$23, $20, $B1, $EA, $CC, $E2, $0D, $0A,
      $62, $6F, $64, $79]);

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(2, LCount, 'A code-page fallback must still yield lines');
    Assert.AreEqual('#', LLines[0].Substring(0, 1),
      'The heading marker must survive the fallback');
    Assert.AreEqual(Ord(teAnsi), Ord(LEnc), 'The degraded encoding must be reported, not hidden');
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTextIOTests.ReadLines_CrlfAndLoneCr_SplitIntoLines;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.md');
    WriteBytes(LPath, TEncoding.UTF8.GetBytes('a' + #13#10 + 'b' + #13 + 'c' + #10 + 'd'));

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(4, LCount);
    Assert.AreEqual('a', LLines[0]);
    Assert.AreEqual('b', LLines[1]);
    Assert.AreEqual('c', LLines[2]);
    Assert.AreEqual('d', LLines[3]);
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

procedure TTextIOTests.ReadLines_MissingFile_ReturnsEmptyArray;
var
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LLines := ReadTextLinesTolerant(
    TPath.Combine(TPath.GetTempPath, 'aswish-does-not-exist-' +
    TGuid.NewGuid.ToString + '.md'), LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(0, LCount, 'A missing file must not raise');
end;

procedure TTextIOTests.ReadLines_TrailingNewline_DoesNotAddEmptyLine;
var
  LDir, LPath: string;
  LLines: TArray<string>;
  LEnc: TAsWishTextEncoding;
  LCount: Integer;
begin
  LDir := NewTextIOTempDir;
  try
    LPath := TPath.Combine(LDir, 'a.md');
    WriteBytes(LPath, TEncoding.UTF8.GetBytes('a' + sLineBreak + 'b' + sLineBreak));

    LLines := ReadTextLinesTolerant(LPath, LEnc);

    LCount := Length(LLines);
    Assert.AreEqual(2, LCount,
      'A trailing newline terminates the last line; it does not open an empty one');
    Assert.AreEqual('b', LLines[1]);
  finally
    if TDirectory.Exists(LDir) then
      TDirectory.Delete(LDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTextIOTests);

end.
