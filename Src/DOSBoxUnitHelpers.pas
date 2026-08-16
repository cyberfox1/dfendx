unit DOSBoxUnitHelpers;

interface

uses
  SysUtils, Classes, CommonHelpers;

function IsWindowsExe(const FileName: String): Boolean;
function IsDOSExe(const FileName: String): Boolean;
function DeepWindowsCheck(const FSt: TFileStream): Boolean;
function IsDosZipHybridExe(const FileName: String): Boolean;

{ Normalize PE ProductVersion e.g. "0, 83, 0, 0" → "0.83.0.0". }
function NormalizeProductVersionString(const Raw: String): String;

{ Numeric multi-part compare of normalized (or dotted) versions.
  Missing parts count as 0. Returns -1 if A<B, 0 if equal, 1 if A>B.
  Example: CompareDOSBoxVersion('1.2','0.8.2.3') = 1. }
function CompareDOSBoxVersion(const VersionA, VersionB: String): Integer;

{ Appends integer parts as Pointer-sized integers into Parts (TList of Integer). }
procedure ParseVersionParts(const Version: String; Parts: TList);

{ First two numeric parts as "X.Y" for legacy float conf gates.
  Accepts dotted and comma/space-separated forms (via ParseVersionParts).
  Fewer than two parts → ''. }
function ShortDOSBoxVersion(const Version: String): String;

{ DOSBox Staging conf value maps (0.82+ and 0.83). Pure; no I/O.
  Section names and keys match across current Staging trees, so callers may
  gate with DosBoxKind=dbkStaging only (no version split needed for these). }

{ Classic "higher,normal" → Staging space form "higher normal". }
function StagingMapPriority(const Priority: string): string;

{ Map classic cycles string to [cpu] cpu_cycles value.
  Bare integer / "fixed N" → "N"; "max" → "max".
  "auto" and other unmapped forms → '' (caller keeps classic cycles=). }
function StagingMapCpuCycles(const Cycles: string): string;

{ Profile PC speaker on → "impulse"; off → "none". }
function StagingMapPCSpeaker(const Enabled: Boolean): string;

implementation

uses
  Windows;

function DeepWindowsCheck(const FSt: TFileStream): Boolean;
const SearchString = 'Microsoft Windows';
var I, J: Integer;
    A: array[0..$400] of Char;
begin
  Result := False;
  FSt.Seek(0, soBeginning); FSt.ReadBuffer(A, SizeOf(A));
  J := 1;
  for I := 0 to $400 do
    if A[I] <> SearchString[J] then J := 1
    else begin
      Inc(J);
      if J = Length(SearchString) then begin Result := True; Exit; end;
    end;
end;

function IsDosZipHybridExe(const FileName: String): Boolean;
begin
  Result := False;
  if ExtUpperCase(ExtractFileName(FileName)) <> 'DZ.EXE' then Exit;
  if not FileExists(ChangeFileExt(FileName, '.DOS')) then Exit;
  Result := True;
end;

function IsWindowsExe(const FileName: String): Boolean;
var FSt: TFileStream;
    I: Integer;
    C: array[0..3] of Char;
    W: Word;
begin
  Result := False;
  if not FileExists(FileName) then Exit;
  if Trim(ExtUpperCase(ExtractFileExt(FileName))) <> '.EXE' then Exit;
  try FSt := TFileStream.Create(FileName, fmOpenRead); except Exit; end;
  try
    try
      if FSt.Size < 4 then Exit;
      FSt.Read(C, 4);
      if (C[0] <> 'M') or (C[1] <> 'Z') then Exit;
      if $3C > FSt.Size - 4 then Exit;
      {$O-}
      FSt.Read(W, 2);

      {Detect win32 PE header}
      FSt.Seek($3C, soBeginning);
      FSt.Read(I, 4);
      if (I < 0) or (I > FSt.Size - 4) then Exit;
      FSt.Seek(I, soBeginning);
      FSt.Read(C, 4);
      if (C[0] = 'P') and (C[1] = 'E') and (C[2] = #0) and (C[3] = #0) then begin
        if IsDosZipHybridExe(FileName) then begin Result := False; Exit; end;
        Result := True;
        Exit;
      end;

      {Detect win16 NE header}
      FSt.Seek($3C, soBeginning);
      FSt.Read(W, 2);
      if W > FSt.Size - 2 then Exit;
      FSt.Seek(W, soBeginning);
      FSt.Read(C, 2);
      if (C[0] = 'N') and (C[1] = 'E') then begin Result := DeepWindowsCheck(FSt); Exit; end;
    finally
      FSt.Free;
    end;
  except Result := False; end;
end;

function IsDOSExe(const FileName: String): Boolean;
var FSt: TFileStream;
    I: Integer;
    C: array[0..3] of Char;
begin
  Result := False;
  if not FileExists(FileName) then Exit;
  if Trim(ExtUpperCase(ExtractFileExt(FileName))) <> '.EXE' then Exit;
  try FSt := TFileStream.Create(FileName, fmOpenRead); except Exit; end;
  try
    try
      if FSt.Size < 4 then Exit;
      FSt.Read(C, 4);
      if (C[0] <> 'M') or (C[1] <> 'Z') then Exit;
      if $3C > FSt.Size - 4 then Exit;
      FSt.Seek($3C, soBeginning);
      FSt.Read(I, 4);
      if (I < 0) or (I > FSt.Size - 4) then begin Result := True; Exit; end;
      FSt.Seek(I, soBeginning);
      FSt.Read(C, 4);
      Result := not ((C[0] = 'P') and (C[1] = 'E') and (C[2] = #0) and (C[3] = #0));
    finally
      FSt.Free;
    end;
  except Result := False; end;
end;

function NormalizeProductVersionString(const Raw: String): String;
var
  I: Integer;
  Part: String;
  C: Char;
  HasDigit: Boolean;

  procedure FlushPart;
  begin
    if Part = '' then
      Exit;
    if Result <> '' then
      Result := Result + '.';
    Result := Result + Part;
    Part := '';
  end;

begin
  Result := '';
  Part := '';
  for I := 1 to Length(Raw) do begin
    C := Raw[I];
    if (C >= '0') and (C <= '9') then
      Part := Part + C
    else if (C = ',') or (C = '.') or (C = ' ') or (C = #9) then
      FlushPart
    else
      FlushPart;
  end;
  FlushPart;

  HasDigit := False;
  for I := 1 to Length(Result) do
    if (Result[I] >= '0') and (Result[I] <= '9') then begin
      HasDigit := True;
      Break;
    end;
  if not HasDigit then
    Result := '';
end;

procedure ParseVersionParts(const Version: String; Parts: TList);
var
  S, Part: String;
  I, V: Integer;
  C: Char;
begin
  Parts.Clear;
  S := Trim(Version);
  Part := '';
  for I := 1 to Length(S) do begin
    C := S[I];
    if (C >= '0') and (C <= '9') then
      Part := Part + C
    else if (C = '.') or (C = ',') or (C = ' ') or (C = #9) then begin
      if Part <> '' then begin
        if not TryStrToInt(Part, V) then
          V := 0;
        Parts.Add(Pointer(V));
        Part := '';
      end;
    end else begin
      if Part <> '' then begin
        if not TryStrToInt(Part, V) then
          V := 0;
        Parts.Add(Pointer(V));
        Part := '';
      end;
    end;
  end;
  if Part <> '' then begin
    if not TryStrToInt(Part, V) then
      V := 0;
    Parts.Add(Pointer(V));
  end;
end;

function ShortDOSBoxVersion(const Version: String): String;
var
  Parts: TList;
begin
  Result := '';
  Parts := TList.Create;
  try
    ParseVersionParts(Version, Parts);
    if Parts.Count < 2 then
      Exit;
    Result := IntToStr(Integer(Parts[0])) + '.' + IntToStr(Integer(Parts[1]));
  finally
    Parts.Free;
  end;
end;

function CompareDOSBoxVersion(const VersionA, VersionB: String): Integer;
var
  A, B: TList;
  I, N, VA, VB: Integer;
begin
  A := TList.Create;
  B := TList.Create;
  try
    ParseVersionParts(VersionA, A);
    ParseVersionParts(VersionB, B);
    if A.Count > B.Count then
      N := A.Count
    else
      N := B.Count;
    for I := 0 to N - 1 do begin
      if I < A.Count then
        VA := Integer(A[I])
      else
        VA := 0;
      if I < B.Count then
        VB := Integer(B[I])
      else
        VB := 0;
      if VA < VB then begin
        Result := -1;
        Exit;
      end;
      if VA > VB then begin
        Result := 1;
        Exit;
      end;
    end;
    Result := 0;
  finally
    A.Free;
    B.Free;
  end;
end;

function StagingMapPriority(const Priority: string): string;
var
  S: string;
begin
  S := Trim(Priority);
  S := StringReplace(S, ',', ' ', [rfReplaceAll]);
  while Pos('  ', S) > 0 do
    S := StringReplace(S, '  ', ' ', [rfReplaceAll]);
  Result := Trim(S);
end;

function StagingMapCpuCycles(const Cycles: string): string;
var
  S, Rest: string;
  N: Integer;
begin
  Result := '';
  S := Trim(Cycles);
  if S = '' then
    Exit;
  if SameText(S, 'max') then begin
    Result := 'max';
    Exit;
  end;
  if SameText(S, 'auto') then
    Exit;
  if TryStrToInt(S, N) then begin
    Result := IntToStr(N);
    Exit;
  end;
  if (Length(S) >= 5) and (ExtUpperCase(Copy(S, 1, 5)) = 'FIXED') then begin
    Rest := Trim(Copy(S, 6, MaxInt));
    if TryStrToInt(Rest, N) then
      Result := IntToStr(N);
  end;
end;

function StagingMapPCSpeaker(const Enabled: Boolean): string;
begin
  if Enabled then
    Result := 'impulse'
  else
    Result := 'none';
end;

end.