unit DataReaderHelpers;

interface

uses SysUtils;

function ProcessGenre(const S: String): String;
function BuildHint(Text: String): String;

implementation

function ProcessGenre(const S: String): String;
var I: Integer;
begin
  result:=S;
  For I:=1 to length(result) do if result[I]=',' then result[I]:=';';
end;

function BuildHint(Text: String): String;
const MaxHint=1000;
const MaxLine=70;
var I,Count : Integer;
begin
  result:='';
  Text:=Trim(Text);
  Count:=0;
  For I:=1 to length(Text) do begin
    if Text[I]=#10 then continue;
    if (Text[I]=#13) or ((Count>MaxLine) and (Text[I]=' ')) then begin
      if length(result)>MaxHint then begin result:=result+'...'; exit; end;
      result:=result+#13; Count:=0;
      continue;
    end;
    if length(result)>=MaxHint then begin result:=result+'...'; exit; end;
    result:=result+Text[I];
    inc(Count);
  end;
end;

end.
