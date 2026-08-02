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
function GetExeProductVersion(const ExePath: String): String;
{ ProductVersion of first dosbox*.exe under DOSBoxPath, normalized. }
function GetDOSBoxVersionFromProductVersion(const DOSBoxPath: String): String;
{ Prefer PE ProductVersion; fall back to README/manual .txt scrape.
  Path: DOSBox install directory (caller resolves install index → path). }
function CheckDOSBoxVersion(const Path: String): String;

{ Numeric multi-part compare of normalized (or dotted) versions.
  Missing parts count as 0. Returns -1 if A<B, 0 if equal, 1 if A>B.
  Example: CompareDOSBoxVersion('1.2','0.8.2.3') = 1. }
function CompareDOSBoxVersion(const VersionA, VersionB: String): Integer;

function FindManual(const Path: String): TStringList;
function GetVersionFromDOSBoxReadmeFile(const FileName: String): String;
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

{ Map mididevice only when profile value is default (or empty) → "auto".
  Any other selection is returned unchanged. }
function StagingMapMidiDevice(const Device: string): string;

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

function GetExeProductVersion(const ExePath: String): String;
var
  Size, Handle: DWORD;
  Buffer: Pointer;
  Len: UINT;
  Value: Pointer;
  Trans: PLongWord;
  LangCharset, Query: String;
  FileName: String;
begin
  Result := '';
  FileName := ExePath;
  UniqueString(FileName);
  Size := GetFileVersionInfoSize(PChar(FileName), Handle);
  if Size = 0 then
    Exit;
  GetMem(Buffer, Size);
  try
    if not GetFileVersionInfo(PChar(FileName), Handle, Size, Buffer) then
      Exit;
    if not VerQueryValue(Buffer, '\VarFileInfo\Translation', Pointer(Trans), Len) then
      Exit;
    if (Trans = nil) or (Len < SizeOf(LongWord)) then
      Exit;
    LangCharset := IntToHex(LoWord(Trans^), 4) + IntToHex(HiWord(Trans^), 4);
    Query := '\StringFileInfo\' + LangCharset + '\ProductVersion';
    if VerQueryValue(Buffer, PChar(Query), Value, Len) and (Value <> nil) then
      Result := PChar(Value);
  finally
    FreeMem(Buffer);
  end;
end;

function GetDOSBoxVersionFromProductVersion(const DOSBoxPath: String): String;
var
  AbsDir, ExeName: String;
  SR: TSearchRec;
  Found: Boolean;
begin
  Result := '';
  AbsDir := IncludeTrailingPathDelimiter(DOSBoxPath);
  if not DirectoryExists(AbsDir) then
    Exit;

  Found := False;
  ExeName := '';
  if FindFirst(AbsDir + 'dosbox*.exe', faAnyFile, SR) = 0 then
  try
    repeat
      if (SR.Attr and faDirectory) = 0 then begin
        ExeName := SR.Name;
        Found := True;
        Break;
      end;
    until FindNext(SR) <> 0;
  finally
    SysUtils.FindClose(SR);
  end;
  if not Found then
    Exit;

  Result := NormalizeProductVersionString(GetExeProductVersion(AbsDir + ExeName));
end;

function FindManual(const Path: String): TStringList;
var
  Rec: TSearchRec;
  I: Integer;
  S: String;
begin
  Result := TStringList.Create;
  I := FindFirst(Path + '*.txt', faAnyFile, Rec);
  try
    while I = 0 do begin
      S := Trim(ExtUpperCase(Rec.Name));
      if (S = 'README.TXT') or ((Pos('MANUAL', S) > 0) and (Pos('DOSBOX', S) > 0)) then
        Result.AddObject(Rec.Name, TObject(DateTimeToFileDate(Rec.TimeStamp)));
      I := FindNext(Rec);
    end;
  finally
    SysUtils.FindClose(Rec);
  end;
end;

function GetVersionFromDOSBoxReadmeFile(const FileName: String): String;
var
  S: String;
  St: TStringList;
  I: Integer;
  B: Boolean;
begin
  Result := '';
  S := '';
  St := TStringList.Create;
  try
    try
      St.LoadFromFile(FileName);
    except
      Exit;
    end;
    for I := 0 to St.Count - 1 do
      if Trim(St[I]) <> '' then begin
        S := St[I];
        Break;
      end;
  finally
    St.Free;
  end;

  B := True;
  for I := 1 to Length(S) do
    if ((S[I] >= '0') and (S[I] <= '9')) or (S[I] = '.') then begin
      if S[I] = '.' then begin
        if B then
          B := False
        else
          Continue;
      end;
      Result := Result + S[I];
    end;

  B := False;
  for I := 1 to Length(Result) do
    if (Result[I] >= '0') and (Result[I] <= '9') then begin
      B := True;
      Break;
    end;
  if not B then
    Result := '';
end;

function CheckDOSBoxVersion(const Path: String): String;
var
  DOSBoxPath: String;
  I, J, Date: Integer;
  FileNames: TStringList;
begin
  Result := '';
  if Trim(Path) = '' then
    Exit;

  DOSBoxPath := IncludeTrailingPathDelimiter(ExpandFileName(Path));

  Result := GetDOSBoxVersionFromProductVersion(DOSBoxPath);
  if Result <> '' then
    Exit;

  FileNames := FindManual(DOSBoxPath);
  try
    while FileNames.Count > 0 do begin
      Date := Integer(FileNames.Objects[0]);
      J := 0;
      for I := 1 to FileNames.Count - 1 do
        if Integer(FileNames.Objects[I]) > Date then begin
          Date := Integer(FileNames.Objects[I]);
          J := I;
        end;
      Result := GetVersionFromDOSBoxReadmeFile(DOSBoxPath + FileNames[J]);
      if Result <> '' then
        Exit;
      FileNames.Delete(J);
    end;
  finally
    FileNames.Free;
  end;
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

function StagingMapMidiDevice(const Device: string): string;
var
  S: string;
begin
  S := Trim(Device);
  if (S = '') or (ExtUpperCase(S) = 'DEFAULT') then
    Result := 'auto'
  else
    Result := S;
end;

function StagingMapPCSpeaker(const Enabled: Boolean): string;
begin
  if Enabled then
    Result := 'impulse'
  else
    Result := 'none';
end;

end.