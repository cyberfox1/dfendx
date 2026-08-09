unit ImageTools;
interface

Function GetGeometryFromFile(const FileName : String) : String;
Function GetGeometryFromMB(const Size : Integer) : String;
{ Pure selection: UseShort + OSShortNameOK → OSShortName, else LongName. No FS. }
Function SelectShortName(const LongName, OSShortName: String;
  const UseShortFolderNames, OSShortNameOK: Boolean): String;
Function ShortName(const LongName : String) : String;

Function CheckCDImage(const FileName : String) : Boolean;
Function SearchCueSheetKeyWords(const FileName : String) : Boolean;
Function CheckISOImage(const FileName : String) : Boolean;

implementation

uses Windows, SysUtils, Classes, Math, PrgSetupUnit, CommonHelpers;

Function GetGeometryFromFile(const FileName : String) : String;
Var hFile : THandle;
    LoDWORD, HiDWORD : DWORD;
    LoI, HiI : Int64;
begin
  hFile:=CreateFile(PChar(FileName),GENERIC_READ,0,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  If hFile=INVALID_HANDLE_VALUE then begin
    result:='';
  end else begin
    try
      LoDWORD:=Windows.GetFileSize(hFile,@HiDWORD);
      LoI:=LoDWORD; HiI:=HiDWORD;
      LoI:=LoI+$100000000*HiI;
      LoI:=LoI div 512 div 63 div 16;
      result:='512,63,16,'+IntToStr(LoI);
    finally
      CloseHandle(hFile);
    end;
  end;
end;

Function GetGeometryFromMB(const Size : Integer) : String;
begin
  {Correct way for calculating the size (512*63*16*X=Bytes => X=MBytes*128/63)
  but not the way mkdosfs works:
  I:=Size*128 div 63;
  result:='512,63,16,'+IntToStr(I);}

  {mkdosfs simply does this:}
  result:='512,63,16,'+IntToStr(Int64(Size)*2);
end;

Function SelectShortName(const LongName, OSShortName: String;
  const UseShortFolderNames, OSShortNameOK: Boolean): String;
begin
  if UseShortFolderNames and OSShortNameOK then
    Result := OSShortName
  else
    Result := LongName;
end;

Function ShortName(const LongName : String) : String;
Var
  Buf: String;
  OK: Boolean;
begin
  if not PrgSetup.UseShortFolderNames then begin
    Result := SelectShortName(LongName, '', False, False);
    Exit;
  end;
  SetLength(Buf, MAX_PATH + 10);
  OK := GetShortPathName(PChar(LongName), PChar(Buf), MAX_PATH) <> 0;
  if OK then
    SetLength(Buf, StrLen(PChar(Buf)))
  else
    Buf := '';
  Result := SelectShortName(LongName, Buf, True, OK);
end;

Function SearchCueSheetKeyWords(const FileName : String) : Boolean;
const KeyWords : Array[0..12] of String = ('CATALOG','CDTEXTFILE','FILE','FLAGS','INDEX','ISRC','PERFORMER','POSTGAP','PREGAP','REM','SONGWRITER','TITLE','TRACK');
Var FSt : TFileStream;
    St : TStringList;
    I,J : Integer;
    S : String;
begin
  result:=False;
  FSt:=TFileStream.Create(FileName,fmOpenRead);
  try
    If FSt.Size>500*1024 then exit;
    St:=TStringList.Create;
    try
      St.LoadFromStream(FSt);
      For I:=0 to Min(50,St.Count-1) do begin
        S:=ExtUpperCase(St[I]);
        For J:=Low(KeyWords) to High(KeyWords) do if Pos(KeyWords[J],S)>0 then begin result:=True; exit; end;
      end;
    finally
      St.Free;
    end;
  finally
    FSt.Free;
  end;
end;

Function CheckISOImage(const FileName : String) : Boolean;
{ISO volume descriptor signature is 7 raw bytes. Compare as bytes, not as
 String/UnicodeString: ReadBuffer count is in bytes while Length(String) is
 in characters (2 bytes each on Delphi Unicode).}
const
  ISOID: array[0..6] of Byte = (1, Ord('C'), Ord('D'), Ord('0'), Ord('0'), Ord('1'), 1);
  Offsets: array[0..3] of Integer = ($8000, $8018, $9310, $9318);
Var FSt : TFileStream;
    Buf: array[0..6] of Byte;
    I: Integer;
begin
  result:=False;
  FSt:=TFileStream.Create(FileName,fmOpenRead);
  try
    If FSt.Size<$9400 then exit;
    For I:=Low(Offsets) to High(Offsets) do begin
      FSt.Position:=Offsets[I];
      FSt.ReadBuffer(Buf[0], SizeOf(Buf));
      If CompareMem(@Buf[0], @ISOID[0], SizeOf(ISOID)) then begin
        result:=True;
        exit;
      end;
    end;
  finally
    FSt.Free;
  end;
end;

Function CheckCDImage(const FileName : String) : Boolean;
Var Ext : String;
begin
  result:=False;
  If not FileExists(FileName) then exit;

  Ext:=ExtUpperCase(ExtractFileExt(FileName));
  If Ext='.BIN' then begin result:=True; exit; end;
  If Ext='.CUE' then begin result:=SearchCueSheetKeyWords(FileName); exit; end;
  if Ext='.ISO' then begin result:=CheckISOImage(FileName); exit; end;

  result:=SearchCueSheetKeyWords(FileName); If result then exit;
  result:=CheckISOImage(FileName);
end;

end.
