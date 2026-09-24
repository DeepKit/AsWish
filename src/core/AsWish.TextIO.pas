{ ============================================================================
  AsWish.TextIO

  Encoding-tolerant text reading.

  A difference tool must survive whatever bytes a real repository actually
  contains. Delphi's TFile.*(TEncoding.UTF8) helpers decode strictly and raise
  EEncodingError on the first invalid sequence, which kills an entire scan
  over one GBK- or UTF-16-encoded doc file. Everything here degrades instead
  of aborting, and reports which encoding was actually used so a degraded
  read can be surfaced rather than silently trusted.
  ============================================================================ }

unit AsWish.TextIO;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

type
  TAsWishTextEncoding = (teUnknown, teUtf8, teUtf8Bom, teUtf16Le, teUtf16Be, teAnsi);

const
  CAsWishTextEncodingNames: array[TAsWishTextEncoding] of string = (
    'unknown', 'utf8', 'utf8_bom', 'utf16le', 'utf16be', 'ansi');

/// Splits text the way TFile.ReadAllLines does: CRLF, LF and lone CR all end a
/// line, and a trailing newline terminates the last line instead of opening an
/// empty one.
function SplitTextLines(const AText: string): TArray<string>;

/// <summary>
/// Reads a text file into lines without ever raising. Encoding is detected
/// from the BOM (and a BOM-less UTF-16 heuristic); when the bytes do not decode
/// under the detected encoding, progressively looser fallbacks are tried and
/// AEncodingUsed reports what was actually applied. A missing or unreadable
/// file yields an empty array rather than an exception.
/// </summary>
function ReadTextLinesTolerant(const APath: string;
  out AEncodingUsed: TAsWishTextEncoding): TArray<string>;

implementation

function StartsWith(const ABytes: TBytes; const APrefix: TBytes): Boolean;
var
  I: Integer;
begin
  if Length(ABytes) < Length(APrefix) then Exit(False);
  for I := 0 to High(APrefix) do
    if ABytes[I] <> APrefix[I] then Exit(False);
  Result := True;
end;

// A BOM-less UTF-16 text file has a NUL high byte on every other character.
// Requiring it for a majority of positions keeps GBK/Shift-JIS files (which
// legitimately contain some 0x00-adjacent low bytes) from being misdetected.
function LooksLikeUtf16(const ABytes: TBytes; AHighByteAtEvenIndex: Boolean): Boolean;
var
  I, LTotal, LZeros: Integer;
begin
  Result := False;
  LTotal := Length(ABytes) div 2;
  if LTotal < 2 then Exit;
  LZeros := 0;
  for I := 0 to LTotal - 1 do
  begin
    if AHighByteAtEvenIndex then
      LZeros := LZeros + Ord(ABytes[I * 2] = 0)
    else
      LZeros := LZeros + Ord(ABytes[I * 2 + 1] = 0);
  end;
  Result := (LZeros * 100) div LTotal >= 60;
end;

// Reports both the encoding and whether a BOM was present. The caller must
// strip the BOM bytes, but must NOT strip anything for a heuristic-detected
// UTF-16 file: those bytes are real data, and dropping them turns a leading
// heading marker into an ordinary space.
function DetectTextEncoding(const ABytes: TBytes;
  out AHasBom: Boolean): TAsWishTextEncoding;
begin
  AHasBom := True;
  if StartsWith(ABytes, [$EF, $BB, $BF]) then Exit(teUtf8Bom);
  if StartsWith(ABytes, [$FF, $FE]) then Exit(teUtf16Le);
  if StartsWith(ABytes, [$FE, $FF]) then Exit(teUtf16Be);
  AHasBom := False;
  if LooksLikeUtf16(ABytes, False) then Exit(teUtf16Le);
  if LooksLikeUtf16(ABytes, True) then Exit(teUtf16Be);
  Result := teUtf8;
end;

function TryGetString(const ABytes: TBytes; AEncoding: TEncoding;
  out AText: string): Boolean;
begin
  try
    AText := AEncoding.GetString(ABytes);
    Result := True;
  except
    AText := '';
    Result := False;
  end;
end;

// Last resort: every byte maps to a code point, so this cannot fail. Used only
// when the system code page itself rejects the bytes.
function DecodeLatin1(const ABytes: TBytes): string;
var
  LSb: TStringBuilder;
  I: Integer;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.Capacity := Length(ABytes);
    for I := 0 to High(ABytes) do
      LSb.Append(Char(ABytes[I]));
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

// Returns the decoded body and the encoding that actually worked. Candidates
// are tried most faithful first, each paired with the label to report on
// success; a byte-wise Latin-1 decode is the unreachable-in-practice last
// resort for when the system code page itself rejects the bytes.
function DecodeBody(const ABytes: TBytes;
  const ACandidates: TArray<TEncoding>;
  const ALabels: TArray<TAsWishTextEncoding>;
  out AUsed: TAsWishTextEncoding): string;
var
  I: Integer;
  LText: string;
begin
  Result := '';
  AUsed := teUnknown;
  for I := 0 to High(ACandidates) do
    if TryGetString(ABytes, ACandidates[I], LText) then
    begin
      Result := LText;
      AUsed := ALabels[I];
      Exit;
    end;
  Result := DecodeLatin1(ABytes);
end;

function SplitTextLines(const AText: string): TArray<string>;
var
  LNorm: string;
  LParts: TArray<string>;
begin
  if AText = '' then Exit(nil);
  LNorm := AText.Replace(#13#10, #10, [rfReplaceAll]).Replace(#13, #10, [rfReplaceAll]);
  if LNorm = '' then Exit(nil);
  LParts := LNorm.Split([#10]);
  if (Length(LParts) > 1) and (LParts[High(LParts)] = '') then
    SetLength(LParts, Length(LParts) - 1);
  Result := LParts;
end;

function ReadTextLinesTolerant(const APath: string;
  out AEncodingUsed: TAsWishTextEncoding): TArray<string>;
var
  LBytes, LBody: TBytes;
  LDetected: TAsWishTextEncoding;
  LHasBom: Boolean;
  LText: string;
  LUsed: TAsWishTextEncoding;
  LSkip: Integer;
begin
  Result := nil;
  AEncodingUsed := teUnknown;
  if not TFile.Exists(APath) then Exit;

  try
    LBytes := TFile.ReadAllBytes(APath);
  except
    Exit;
  end;

  LDetected := DetectTextEncoding(LBytes, LHasBom);
  LSkip := 0;
  if LHasBom then
    case LDetected of
      teUtf8Bom: LSkip := 3;
      teUtf16Le, teUtf16Be: LSkip := 2;
    end;

  // Copy on a dynamic array is zero-based, unlike Copy on a string.
  if LSkip > 0 then
    LBody := Copy(LBytes, LSkip, Length(LBytes) - LSkip)
  else
    LBody := LBytes;

  case LDetected of
    teUtf8Bom:
      begin
        LText := DecodeBody(LBody, [TEncoding.UTF8, TEncoding.ANSI],
          [teUtf8, teAnsi], LUsed);
        if LUsed = teUnknown then LUsed := teUtf8Bom;
      end;
    teUtf16Le, teUtf16Be:
      begin
        if LDetected = teUtf16Le then
          LText := DecodeBody(LBody, [TEncoding.Unicode, TEncoding.UTF8, TEncoding.ANSI],
            [teUtf16Le, teUtf8, teAnsi], LUsed)
        else
          LText := DecodeBody(LBody, [TEncoding.BigEndianUnicode, TEncoding.UTF8, TEncoding.ANSI],
            [teUtf16Be, teUtf8, teAnsi], LUsed);
        if LUsed = teUnknown then LUsed := LDetected;
      end;
  else
    LText := DecodeBody(LBody, [TEncoding.UTF8, TEncoding.ANSI],
      [teUtf8, teAnsi], LUsed);
  end;

  AEncodingUsed := LUsed;
  Result := SplitTextLines(LText);
end;

end.
