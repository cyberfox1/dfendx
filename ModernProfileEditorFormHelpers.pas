unit ModernProfileEditorFormHelpers;

interface

uses SysUtils;

function FormatMultiLineHint(const InputString: String): String;

implementation

function FormatMultiLineHint(const InputString: String): String;
var
  I: Integer;
begin
  result := InputString;
  if length(result) > 80 then
    for I := 80 downto 1 do
      if result[I] = #32 then
      begin
        result[I] := #13;
        break;
      end;
end;

end.
