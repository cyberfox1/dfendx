unit PackageBuilderHelpers;

interface

uses SysUtils, Classes, XMLDoc;

function MultiFileSize(const FileName: String): Int64;
function GetNormalLastFileVersion(const Major, Minor, Release: Integer): String;
function AddPackageDataFooter(const Doc: TXMLDocument): TStringList;

implementation

uses CommonTools, CommonHelpers, PrgConsts, PackageDBToolsUnit;

function MultiFileSize(const FileName: String): Int64;
Var Rec : TSearchRec;
    I : Integer;
begin
  result:=0;
  I:=FindFirst(FileName+'.part*',faAnyFile,Rec);
  try
    While I=0 do begin
      result:=result+Rec.Size;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

function GetNormalLastFileVersion(const Major, Minor, Release: Integer): String;
Var A,B,C : Integer;
begin
  A:=Major;
  B:=Minor;
  C:=Release;
  If C>0 then dec(C) else begin
    C:=99;
    If B>0 then dec(B) else begin
      B:=9;
      dec(A);
    end;
  end;
  result:=Format('%d.%d.%d',[A,B,C]);
end;

function AddPackageDataFooter(const Doc: TXMLDocument): TStringList;
begin
  result:=SaveXMLDoc(Doc,['<!DOCTYPE DFRPackagesFile SYSTEM "'+DFRHomepage+'Packages/DFRPackagesFile.dtd">'],False);
end;

end.
