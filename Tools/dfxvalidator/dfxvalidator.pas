{ DFendX install validator — console helper for Setup/Update and manual checks.

  Usage:
    dfxvalidator.exe [path-to-exe] [version-out-file]

  Default exe if omitted: ..\DFend.exe relative to this program (install root
  when the tool lives in Bin\).

  Default version-out-file if omitted: %TEMP%\dfxvalidator.version

  On success (DFendX File Description match + readable PE version):
    - writes version as plain text "major.minor.patch.build" (one line) to
      version-out-file for NSIS VersionCompare
    - prints "OK: DFendX <version>" and exits 0

  Invalid: prints nothing; exit 1 (no match) or 2 (missing/unreadable)
}
program dfxvalidator;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Windows, SysUtils;

function GetFileDescription(const AFileName: string): string;
var
  Handle: DWORD;
  Size: DWORD;
  Buffer: Pointer;
  Value: Pointer;
  ValueLen: UINT;
  TransPtr: Pointer;
  TransLen: UINT;
  Lang, CodePage: Word;
  SubBlock: string;
begin
  Result := '';
  Size := GetFileVersionInfoSize(PChar(AFileName), Handle);
  if Size = 0 then
    Exit;
  GetMem(Buffer, Size);
  try
    if not GetFileVersionInfo(PChar(AFileName), Handle, Size, Buffer) then
      Exit;
    if not VerQueryValue(Buffer, '\VarFileInfo\Translation', TransPtr, TransLen) then
      Exit;
    if TransLen < 4 then
      Exit;
    Lang := PWord(TransPtr)^;
    CodePage := PWord(Pointer(PtrUInt(TransPtr) + 2))^;
    SubBlock := Format('\StringFileInfo\%.4x%.4x\FileDescription', [Lang, CodePage]);
    if not VerQueryValue(Buffer, PChar(SubBlock), Value, ValueLen) then
      Exit;
    if (Value = nil) or (ValueLen = 0) then
      Exit;
    Result := PChar(Value);
  finally
    FreeMem(Buffer);
  end;
end;

function GetFileVersionString(const AFileName: string): string;
var
  Handle: DWORD;
  Size: DWORD;
  Buffer: Pointer;
  Value: Pointer;
  ValueLen: UINT;
  Fixed: PVSFixedFileInfo;
begin
  Result := '';
  Size := GetFileVersionInfoSize(PChar(AFileName), Handle);
  if Size = 0 then
    Exit;
  GetMem(Buffer, Size);
  try
    if not GetFileVersionInfo(PChar(AFileName), Handle, Size, Buffer) then
      Exit;
    if not VerQueryValue(Buffer, '\', Value, ValueLen) then
      Exit;
    if (Value = nil) or (ValueLen < SizeOf(TVSFixedFileInfo)) then
      Exit;
    Fixed := PVSFixedFileInfo(Value);
    if Fixed^.dwSignature <> $FEEF04BD then
      Exit;
    Result := Format('%d.%d.%d.%d', [
      HiWord(Fixed^.dwFileVersionMS),
      LoWord(Fixed^.dwFileVersionMS),
      HiWord(Fixed^.dwFileVersionLS),
      LoWord(Fixed^.dwFileVersionLS)]);
  finally
    FreeMem(Buffer);
  end;
end;

function DefaultVersionOutFile: string;
var
  Buf: array[0..MAX_PATH] of Char;
  N: DWORD;
begin
  N := GetTempPath(MAX_PATH, Buf);
  if N = 0 then
    Result := 'dfxvalidator.version'
  else
    Result := IncludeTrailingPathDelimiter(string(Buf)) + 'dfxvalidator.version';
end;

function WriteVersionFile(const APath, AVersion: string): Boolean;
var
  F: TextFile;
begin
  Result := False;
  try
    AssignFile(F, APath);
    Rewrite(F);
    try
      Write(F, AVersion);
    finally
      CloseFile(F);
    end;
    Result := True;
  except
    Result := False;
  end;
end;

var
  Target, Desc, Ver, VerOut: string;
begin
  try
    if ParamCount >= 1 then
      Target := ExpandFileName(ParamStr(1))
    else
      Target := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + '..\DFend.exe');

    if ParamCount >= 2 then
      VerOut := ExpandFileName(ParamStr(2))
    else
      VerOut := DefaultVersionOutFile;

    if not FileExists(Target) then
      Halt(2);

    Desc := GetFileDescription(Target);

    if Pos('DFendX', Desc) = 0 then
      Halt(1);

    Ver := GetFileVersionString(Target);
    if Ver = '' then
      Halt(2);

    if not WriteVersionFile(VerOut, Ver) then
      Halt(2);

    WriteLn('OK: DFendX ', Ver);
    Halt(0);
  except
    on E: Exception do
      Halt(2);
  end;
end.
