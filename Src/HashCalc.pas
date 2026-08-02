unit HashCalc;
interface

Function GetMD5Sum(const FileName : String; const SmallFile : Boolean) : String;

implementation

uses Classes, SysUtils, HashAlgMD5_U, HashValue_U;

Function GetMD5Sum(const FileName : String; const SmallFile : Boolean) : String;
Var FileStream : TFileStream;
    MemoryStream : TMemoryStream;
    LHashAlgMD5 : THashAlgMD5;
    LHashValue: THashValue;
begin
  result:='';
  if (Trim(FileName)='') or (not FileExists(FileName)) then exit;

  LHashAlgMD5:=THashAlgMD5.Create(nil);
  LHashValue:=THashValue.Create;
  try
    If SmallFile then begin
      FileStream:=nil;
      try MemoryStream:=TMemoryStream.Create; except exit; end;
    end else begin
      try FileStream:=TFileStream.Create(FileName,fmOpenRead); except exit; end;
      MemoryStream:=nil;
    end;
    try
      If SmallFile then MemoryStream.LoadFromFile(FileName);
      LHashAlgMD5.Init;
      If SmallFile then LHashAlgMD5.Update(MemoryStream) else LHashAlgMD5.Update(FileStream);
    finally
      FileStream.Free;
      MemoryStream.Free;
    end;
    LHashAlgMD5.Final(LHashValue);
    result:=LHashValue.ValueAsASCIIHex;
  finally
    LHashAlgMD5.Free;
    LHashValue.Free;
  end;
end;

end.
