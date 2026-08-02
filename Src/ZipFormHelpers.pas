unit ZipFormHelpers;

interface

uses Classes, SevenZipVCL;

function AvoidSomeNames(const St: TStringList; const SetupNumber: Integer): String;
function CheckExtension(Extension: String): String;
function CheckExtensionsList(Extensions: String): String;
function ExtensionInList(Extension, List: String): Boolean;
function ProcessFileNameFilter(Filter, ArchiveFiles: String): String;
function GetCompressStrengthFromPrgSetup: TCompressStrength;
function StripAllSuffixes(const FileName: String): String;

implementation

uses SysUtils, CommonHelpers, PrgSetupUnit, PrgConsts;

function StripAllSuffixes(const FileName: String): String;
begin
  result := Copy(FileName, 1, Pos('.', FileName + '.') - 1);
end;

function AvoidSomeNames(const St: TStringList; const SetupNumber: Integer): String;
var I,J : Integer;
    OK : Boolean;
    S : String;
begin
  result:='';

  For I:=0 to St.Count-1 do if I<>SetupNumber then begin
    OK:=True; S:=ExtUpperCase(StripAllSuffixes(St[I]));
    For J:=Low(IgnoreGameExeFilesIgnore) to High(IgnoreGameExeFilesIgnore) do if S=IgnoreGameExeFilesIgnore[J] then begin OK:=False; break; end;
    if not OK then continue;

    for J:=Low(ProgramExeFiles) to High(ProgramExeFiles) do if S=ProgramExeFiles[J] then begin
      result:=St[I]; exit;
    end;
  end;

  For I:=0 to St.Count-1 do if I<>SetupNumber then begin
    OK:=True; S:=ExtUpperCase(StripAllSuffixes(St[I]));
    For J:=Low(IgnoreGameExeFilesIgnore) to High(IgnoreGameExeFilesIgnore) do if S=IgnoreGameExeFilesIgnore[J] then begin OK:=False; break; end;
    If OK then result:=St[I];

    If OK then for J:=Low(SetupExeFilesLevel1) to High(SetupExeFilesLevel1) do if S=SetupExeFilesLevel1[J] then begin OK:=False; break; end;
    If OK then for J:=Low(SetupExeFilesLevel2) to High(SetupExeFilesLevel2) do if S=SetupExeFilesLevel2[J] then begin OK:=False; break; end;
    If OK then for J:=Low(SetupExeFilesLevel3) to High(SetupExeFilesLevel3) do if S=SetupExeFilesLevel3[J] then begin OK:=False; break; end;
    If OK then for J:=Low(SetupExeFilesLevel4) to High(SetupExeFilesLevel4) do if S=SetupExeFilesLevel4[J] then begin OK:=False; break; end;

    If OK then exit;
  end;
  If result<>'' then exit;

  For I:=0 to St.Count-1 do if I<>SetupNumber then begin result:=St[I]; exit; end;

  If St.Count>0 then result:=St[0];
end;

function CheckExtension(Extension: String): String;
begin
  while (Extension <> '') and (Extension[1] in ['*', '.']) do
    Delete(Extension, 1, 1);
  result := Extension;
end;

function CheckExtensionsList(Extensions: String): String;
Var I : Integer;
    S : String;
begin
  result:='';
  Extensions:=Trim(Extensions);

  repeat
    I:=Pos(';',Extensions);
    If I>0 then begin
      S:=CheckExtension(Trim(Copy(Extensions,1,I-1)));
      Extensions:=Trim(Copy(Extensions,I+1,MaxInt));
    end else begin
      S:=CheckExtension(Extensions);
      Extensions:='';
    end;
    If S<>'' then begin
      If result<>'' then result:=result+';';
      result:=result+S;
    end;
  until I=0;
end;

function ExtensionInList(Extension, List: String): Boolean;
Var I : Integer;
    S : String;
begin
  result:=False;
  Extension:=Trim(ExtUpperCase(CheckExtension(Extension)));

  List:=Trim(List);
  repeat
    I:=Pos(';',List);
    If I>0 then begin
      S:=CheckExtension(Trim(Copy(List,1,I-1)));
      List:=Trim(Copy(List,I+1,MaxInt));
    end else begin
      S:=CheckExtension(List);
      List:='';
    end;
    If Trim(ExtUpperCase(S))=Extension then begin result:=True; exit; end;
  until I=0;
end;

function ProcessFileNameFilter(Filter, ArchiveFiles: String): String;
Var I,J : Integer;
    St : TStringList;
    S,T,U : String;
begin
  result:=Filter;
  If PrgSetup = nil then exit;

  I:=Pos('%s',Filter); If I=0 then exit;
  S:=Copy(Filter,I+2,MaxInt); I:=Pos('%s',S); If I=0 then exit;
  S:=Copy(S,I+2,MaxInt); I:=Pos('%s',S); If I=0 then exit;

  St:=TStringList.Create;
  try
    For I:=0 to PrgSetup.PackerSettingsCount-1 do begin
      S:=Trim(PrgSetup.PackerSettings[I].FileExtensions);
      while S<>'' do begin
        J:=Pos(';',S);
        If J>0 then begin T:=Copy(S,1,J-1); S:=Copy(S,J+1,MaxInt); end else begin T:=S; S:=''; end;
        T:=ExtUpperCase(T);
        If St.IndexOf(T)<0 then St.Add(T);
      end;
    end;
    S:=''; For I:=0 to St.Count-1 do S:=S+', *.'+ExtLowerCase(St[I]);
    U:=''; For I:=0 to St.Count-1 do U:=U+';*.'+ExtLowerCase(St[I]);
    T:=''; For I:=0 to St.Count-1 do T:=T+Format(ArchiveFiles,[ExtLowerCase(St[I])])+' (*.'+ExtLowerCase(St[I])+')|*.'+ExtLowerCase(St[I])+'|';
    result:=Format(Filter,[S,U,T]);
  finally
    St.Free;
  end;
end;

function GetCompressStrengthFromPrgSetup: TCompressStrength;
begin
  Case PrgSetup.CompressionLevel of
    0 : result:=SAVE;
    1 : result:=FAST;
    2 : result:=NORMAL;
    3 : result:=MAXIMUM;
    4 : result:=ULTRA;
    else result:=MAXIMUM;
  end;
end;

end.
