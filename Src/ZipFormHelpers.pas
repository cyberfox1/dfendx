unit ZipFormHelpers;

interface

uses Classes;

function AvoidSomeNames(const St: TStringList; const SetupNumber: Integer): String;
function CheckExtension(Extension: String): String;
function CheckExtensionsList(Extensions: String): String;
function ExtensionInList(Extension, List: String): Boolean;
function ProcessFileNameFilter(Filter, ArchiveFiles: String): String;

function Bundled7zaPath: String;
function IsBundled7zaPath(const FileName: String): Boolean;
function CompressionLevelTo7zMx(Level: Integer): Integer;
procedure ApplyBundled7zaDefaults(out Name, FileName, Extensions, ExtractFile, CreateFile, UpdateFile: String; out TrailingBackslash: Boolean);
procedure EnsureBundled7zaPackerRow;

implementation

uses SysUtils, CommonHelpers, CommonTools, PrgSetupUnit, PrgConsts;

const
  Bundled7zaName = '7za';
  Bundled7zaExtensions = 'ZIP;7Z;TAR;GZ;GZIP;TGZ;BZ2;BZIP2;TBZ2;XZ;TXZ';
  Bundled7zaExtract = 'x "%1" -o"%2" -y';
  Bundled7zaCreate = 'a -mmt=on "%1" "%2*" -r -y';
  Bundled7zaUpdate = 'u -mmt=on "%1" "%2*" -r -y';

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

function Bundled7zaPath: String;
begin
  result:=PrgDir+BinFolder+'\'+Bundled7zaFileName;
end;

function IsBundled7zaPath(const FileName: String): Boolean;
begin
  result:=(Trim(FileName)<>'') and
    (AnsiSameText(ExpandFileName(FileName), ExpandFileName(Bundled7zaPath)));
end;

function CompressionLevelTo7zMx(Level: Integer): Integer;
begin
  Case Level of
    0 : result:=0;
    1 : result:=3;
    2 : result:=5;
    3 : result:=7;
    4 : result:=9;
    else result:=7;
  end;
end;

procedure ApplyBundled7zaDefaults(out Name, FileName, Extensions, ExtractFile, CreateFile, UpdateFile: String; out TrailingBackslash: Boolean);
begin
  Name:=Bundled7zaName;
  FileName:=Bundled7zaPath;
  Extensions:=Bundled7zaExtensions;
  ExtractFile:=Bundled7zaExtract;
  CreateFile:=Bundled7zaCreate;
  UpdateFile:=Bundled7zaUpdate;
  TrailingBackslash:=True;
end;

procedure EnsureBundled7zaPackerRow;
Var I, J : Integer;
    Name, FileName, Extensions, ExtractFile, CreateFile, UpdateFile : String;
    TrailingBackslash : Boolean;
begin
  If PrgSetup=nil then exit;
  If not FileExists(Bundled7zaPath) then exit;

  ApplyBundled7zaDefaults(Name, FileName, Extensions, ExtractFile, CreateFile, UpdateFile, TrailingBackslash);

  J:=-1;
  For I:=0 to PrgSetup.PackerSettingsCount-1 do
    If IsBundled7zaPath(PrgSetup.PackerSettings[I].ZipFileName) then begin
      If J<0 then J:=I
      else begin
        { Keep first shipped row; drop duplicates later if any appear }
      end;
    end;

  If J<0 then J:=PrgSetup.AddPackerSettings(Name);

  PrgSetup.PackerSettings[J].Name:=Name;
  PrgSetup.PackerSettings[J].ZipFileName:=FileName;
  PrgSetup.PackerSettings[J].FileExtensions:=Extensions;
  PrgSetup.PackerSettings[J].ExtractFile:=ExtractFile;
  PrgSetup.PackerSettings[J].CreateFile:=CreateFile;
  PrgSetup.PackerSettings[J].UpdateFile:=UpdateFile;
  PrgSetup.PackerSettings[J].TrailingBackslash:=TrailingBackslash;

  { Remove extra rows pointing at the same bundled exe }
  For I:=PrgSetup.PackerSettingsCount-1 downto 0 do
    If (I<>J) and IsBundled7zaPath(PrgSetup.PackerSettings[I].ZipFileName) then
      PrgSetup.DeletePackerSettings(I);
end;

end.
