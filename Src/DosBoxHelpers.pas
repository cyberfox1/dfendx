unit DosBoxHelpers;

interface

uses Classes;

function BoolToStr(const B: Boolean): String;
function AllSameDir(const St: TStringList): Boolean;
procedure MultiLineAdd(const St: TStringList; NewLines: String);

type
  TPureMidiRomKind = (pmrkMT32, pmrkSC55);

function CollectPureMidiRoms(const Root: String; Kind: TPureMidiRomKind; Names: TStringList; const WantFile: String = ''): String;

implementation

uses SysUtils;

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
  S:=Trim(UpperCase(IncludeTrailingPathDelimiter(ExtractFilePath(St[0]))));
  For I:=1 to St.Count-1 do if S<>Trim(UpperCase(IncludeTrailingPathDelimiter(ExtractFilePath(St[I])))) then exit;
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

function CollectPureMidiRoms(const Root: String; Kind: TPureMidiRomKind; Names: TStringList; const WantFile: String = ''): String;
const
  MaxDepth = 32;
  ControlSuffix = '_CONTROL.ROM';
  Rom1Suffix = '_ROM1.BIN';
Var AbsRoot, WantU: String;

  procedure Walk(const Dir: String; Depth: Integer);
  Var Rec: TSearchRec;
      I: Integer;
      Full, EntryU, DeviceName, Stem, Rel: String;
      Match: Boolean;
  begin
    If Depth>=MaxDepth then exit;
    If (WantFile<>'') and (Result<>'') and (Names=nil) then exit;
    I:=FindFirst(Dir+'*.*',faAnyFile,Rec);
    If I<>0 then exit;
    try
      While I=0 do begin
        If (Rec.Name<>'') and (Rec.Name<>'.') and (Rec.Name<>'..') then begin
          Full:=Dir+Rec.Name;
          If (Rec.Attr and faDirectory)<>0 then
            Walk(Full+PathDelim,Depth+1)
          else begin
            EntryU:=UpperCase(Rec.Name);
            Match:=False;
            DeviceName:='';
            If Kind=pmrkMT32 then begin
              If (Length(EntryU)>Length(ControlSuffix)) and
                 (Copy(EntryU,Length(EntryU)-Length(ControlSuffix)+1,MaxInt)=ControlSuffix) then begin
                DeviceName:=Copy(Rec.Name,1,Length(Rec.Name)-Length(ControlSuffix));
                Match:=(DeviceName<>'') and FileExists(Dir+DeviceName+'_PCM.ROM');
              end;
            end else begin
              If (Length(EntryU)>Length(Rom1Suffix)) and
                 (Copy(EntryU,Length(EntryU)-Length(Rom1Suffix)+1,MaxInt)=Rom1Suffix) then begin
                DeviceName:=Copy(Rec.Name,1,Length(Rec.Name)-Length(Rom1Suffix));
                Stem:=Copy(Rec.Name,1,Length(Rec.Name)-8);
                Match:=(DeviceName<>'') and
                  (FileExists(Dir+Stem+'ROM2.BIN') or
                   FileExists(Dir+Stem+'ROM2_ST.BIN') or
                   FileExists(Dir+Stem+'ROM_SM.BIN'));
              end;
            end;
            If Match then begin
              If Names<>nil then
                Names.Add(DeviceName);
              If (WantFile<>'') and (Result='') and (EntryU=WantU) then begin
                Rel:=Copy(Full,Length(AbsRoot)+1,MaxInt);
                Rel:=StringReplace(Rel,'\','/',[rfReplaceAll]);
                Result:=Rel;
              end;
            end;
          end;
        end;
        I:=FindNext(Rec);
      end;
    finally
      FindClose(Rec);
    end;
  end;

begin
  Result:='';
  If Trim(Root)='' then exit;
  AbsRoot:=IncludeTrailingPathDelimiter(Root);
  WantU:=UpperCase(Trim(WantFile));
  Walk(AbsRoot,0);
end;

end.
