unit InstallationSupportFormHelpers;

interface

uses Classes, SysUtils;

procedure FindProgramFiles(const Dir: String; const St: TStringList);
function TestInstallationSupportNeeded(const AFolder: String): Boolean;

implementation

uses
  CommonHelpers, PrgConsts, PrgSetupUnit;

procedure FindProgramFiles(const Dir: String; const St: TStringList);
Var Rec : TSearchRec;
    I,J : Integer;
begin
  For J:=Low(ProgramExts) to high(ProgramExts) do begin
     I:=FindFirst(Dir+'*.'+ProgramExts[J],faAnyFile,Rec);
     try While I=0 do begin If ((Rec.Attr and faDirectory)=0) then St.Add(ExtUpperCase(ChangeFileExt(Rec.Name,''))); I:=FindNext(Rec); end;
     finally FindClose(Rec); end;
  end;
end;

function TestInstallationSupportNeeded(const AFolder: String): Boolean;
Var St,Names : TStringList;
    I,J : Integer;
    B : Boolean;
begin
  St:=TStringList.Create;
  try
    result:=False;
    FindProgramFiles(IncludeTrailingPathDelimiter(AFolder),St);
    I:=0; while I<St.Count do begin
      B:=True; For J:=Low(IgnoreGameExeFilesIgnore) to High(IgnoreGameExeFilesIgnore) do If St[I]=IgnoreGameExeFilesIgnore[J] then begin B:=False; break; end;
      If B then inc(I) else St.Delete(I);
    end;
    if St.Count<>1 then exit;
    Names:=ValueToList(PrgSetup.InstallerNames);
    try
      For I:=0 to Names.Count-1 do If ExtUpperCase(Names[I])=St[0] then begin result:=True; exit; end;
    finally
      Names.Free;
    end;
  finally
    St.Free;
  end;
end;

end.
