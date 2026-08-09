unit HashCalc;
{ Thin adapter over System.Hash.THashMD5 for file MD5s.
  Preserves historical GetMD5Sum contract: empty string on missing/unreadable
  files; uppercase hex (matches stored profile/kernel checksums).
  SmallFile is ignored (same digest either way). }

interface

Function GetMD5Sum(const FileName : String; const SmallFile : Boolean) : String;

implementation

uses
  SysUtils, System.Hash;

Function GetMD5Sum(const FileName : String; const SmallFile : Boolean) : String;
begin
  Result := '';
  if (Trim(FileName) = '') or (not FileExists(FileName)) then
    Exit;
  try
    { Uppercase: legacy inttohex and constants like FD10KernelSys. }
    Result := AnsiUpperCase(THashMD5.GetHashStringFromFile(FileName));
  except
    Result := '';
  end;
end;

end.
