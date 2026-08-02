unit XMLHelpers;

interface

uses XMLIntf;

function NodeHasAttributes(const N: IXMLNode; const Attr: array of string): Boolean;

implementation

function NodeHasAttributes(const N: IXMLNode; const Attr: array of string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(Attr) to High(Attr) do
    if not N.HasAttribute(Attr[I]) then
      Exit;
  Result := True;
end;

end.