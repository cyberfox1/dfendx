unit DosBoxHelpers;

interface

uses Classes;

function BoolToStr(const B: Boolean): String;
function AllSameDir(const St: TStringList): Boolean;
procedure MultiLineAdd(const St: TStringList; NewLines: String);
function ShortName(const LongName: String): String;
function LongPath(const ShortPath: String): String;

implementation

uses SysUtils, Windows, CommonHelpers, PrgSetupUnit, FileNameConvertor;

function BoolToStr(const B: Boolean): String;
begin
  If B then result:='true' else result:='false';
end;

function AllSameDir(const St: TStringList): Boolean;
Var I : Integer;
    S : String;
begin
  result:=False;
  If St.Count<2 then exit;
  S:=Trim(ExtUpperCase(IncludeTrailingPathDelimiter(ExtractFilePath(St[0]))));
  For I:=1 to St.Count-1 do if S<>Trim(ExtUpperCase(IncludeTrailingPathDelimiter(ExtractFilePath(St[I])))) then exit;
  result:=True;
end;

procedure MultiLineAdd(const St: TStringList; NewLines: String);
Var I : Integer;
begin
  I:=Pos(#13,NewLines);
  while I<>0 do begin
    St.Add(Copy(NewLines,1,I-1)); NewLines:=Copy(NewLines,I+1,MaxInt);
    I:=Pos(#13,NewLines);
  end;
  St.Add(NewLines);
end;

function ShortName(const LongName: String): String;
begin
  If PrgSetup.UseShortFolderNames then begin
    SetLength(result,MAX_PATH+10);
    if GetShortPathName(PChar(LongName),PChar(result),MAX_PATH)=0
      then result:=LongName
      else SetLength(result,StrLen(PChar(result)));
  end else begin
    result:=LongName;
  end;
end;

function LongPath(const ShortPath: String): String;
Var S,T : String;
    I : Integer;
begin
  result:=Copy(ShortPath,1,3);
  S:=ExcludeTrailingPathDelimiter(Copy(ShortPath,4,MaxInt));
  while S<>'' do begin
    I:=Pos('\',S);
    If I=0 then begin T:=S; S:=''; end else begin T:=Copy(S,1,I-1); S:=Copy(S,I+1,MaxInt); end;
    result:=result+WinExpandLongPathName(result,T)+'\';
  end;
end;

end.
