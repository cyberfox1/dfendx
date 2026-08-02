unit SDUHelpers;

interface

uses SysUtils, Math;

type
  LARGE_INTEGER = record
    case Boolean of
      True: (QuadPart: Int64);
      False: (LowPart: LongWord; HighPart: Longint);
  end;

function SDUXOR(a: string; b: string): string;
function SDUFactorial(x: integer): LARGE_INTEGER;
function SDUFloatTrunc(X: double; decimalPlaces: integer): double;
function SDUFormatUnits(Value: int64; denominations: array of string; multiplier: integer = 1000; accuracy: integer = 2): string;
function SDUBoolToStr(value: boolean; strTrue: string = 'True'; strFalse: string = 'False'): string;
function SDUBooleanToStr(value: boolean; strTrue: string = 'True'; strFalse: string = 'False'): string;
function SDUBoolToChar(value: boolean; chars: string = 'TF'): char;
function SDUBooleanToChar(value: boolean; chars: string = 'TF'): char;
function SDUParseASCIIToData(ASCIIrep: string; var data: string): boolean;
function SDUCountCharInstances(theChar: char; theString: string): integer;
function SDUHexToInt(hex: string): integer;
function SDUTryHexToInt(hex: string; var Value: integer): boolean;
function SDUSplitString(wholeString: string; var firstItem: string; var theRest: string; splitOn: char = ' '): boolean;

implementation

function SDUCountCharInstances(theChar: char; theString: string): integer;
var
  i: integer;
  count: integer;
begin
  count := 0;
  for i:=1 to length(theString) do
    begin
    if theString[i]=theChar then
      begin
      inc(count);
      end;
    end;

  Result := count;
end;

function SDUHexToInt(hex: string): integer;
begin
  Result := StrToInt('$'+hex);
end;

function SDUTryHexToInt(hex: string; var Value: integer): boolean;
begin
  hex := StringReplace(hex, ' ', '', [rfReplaceAll]);

  if (Pos('0X', uppercase(hex)) = 1) then
    begin
    Delete(hex, 1, 2);
    end;

  Result := TryStrToInt('$'+hex, Value);
end;

function SDUXOR(a: string; b: string): string;
var
  retval: string;
  longest: integer;
  byteA: byte;
  byteB: byte;
  i: integer;
begin
  retval := '';

  longest := max(length(a), length(b));
  for i:=1 to longest do
    begin
    if (i > length(a)) then
      begin
      byteA := 0;
      end
    else
      begin
      byteA := ord(a[i]);
      end;

    if (i > length(b)) then
      begin
      byteB := 0;
      end
    else
      begin
      byteB := ord(b[i]);
      end;

    retval := retval + char(byteA XOR byteB);
    end;

  Result := retval;
end;

function SDUFloatTrunc(X: double; decimalPlaces: integer): double;
var
  multiplier: extended;
begin
  multiplier := Power(10, decimalPlaces);
  Result := (trunc(x * multiplier)) / multiplier;
end;

function SDUBooleanToStr(value: boolean; strTrue: string = 'True'; strFalse: string = 'False'): string;
var
  retVal: string;
begin
  retVal := strFalse;
  if value then
    begin
    retVal := strTrue;
    end;

  Result := retVal;
end;

function SDUBooleanToChar(value: boolean; chars: string = 'TF'): char;
var
  retVal: char;
begin
  if (length(chars) < 2) then
    begin
    raise Exception.Create('Exactly zero or two characters must be passed to BoolToChar');
    end;

  retVal := chars[2];
  if value then
    begin
    retVal := chars[1];
    end;

  Result := retVal;
end;

function SDUBoolToStr(value: boolean; strTrue: string = 'True'; strFalse: string = 'False'): string;
begin
  Result := SDUBooleanToStr(value, strTrue, strFalse);
end;

function SDUBoolToChar(value: boolean; chars: string = 'TF'): char;
begin
  Result := SDUBooleanToChar(value, chars);
end;

function SDUParseASCIIToData(ASCIIrep: string; var data: string): boolean;
var
  retval: boolean;
  tmpStr: string;
  i: integer;
  ASCIIStripped: string;
begin
  retval := FALSE;

  ASCIIrep := uppercase(ASCIIrep);

  ASCIIStripped := '';
  for i:=1 to length(ASCIIrep) do
    begin
    if (
         ((ord(ASCIIrep[i]) >= ord('0')) and (ord(ASCIIrep[i]) <= ord('9')))
         OR
         ((ord(ASCIIrep[i]) >= ord('A')) and (ord(ASCIIrep[i]) <= ord('F')))
       ) then
      begin
      ASCIIStripped := ASCIIStripped + ASCIIrep[i];
      end;
    end;

  if ((Length(ASCIIStripped) mod 2) < 1) then
    begin
    data := '';

    while (Length(ASCIIStripped) > 0) do
      begin
      tmpStr := Copy(ASCIIStripped, 1, 2);
      delete(ASCIIStripped, 1, 2);

      data := data + chr(SDUHexToInt(tmpStr));
      end;

    retval := TRUE;
    end;

  Result := retval;
end;

function SDUFormatUnits(Value: int64; denominations: array of string; multiplier: integer = 1000; accuracy: integer = 2): string;
var
  retVal: string;
  z: double;
  useUnits: string;
  unitsIdx: integer;
  absValue: int64;
  unitsDiv: int64;
begin
  absValue := abs(Value);

  unitsIdx := 0;
  unitsDiv := 1;
  while ((absValue >= (unitsDiv * multiplier)) and (unitsIdx < high(denominations))) do
    begin
    inc(unitsIdx);
    unitsDiv := unitsDiv * multiplier;
    end;

  useUnits := '';
  if ((unitsIdx > low(denominations)) and (unitsIdx < high(denominations))) then
  begin
    useUnits := denominations[unitsIdx];
  end;

  if (unitsIdx = 0) then
    begin
    accuracy := 0;
    end;

  z := SDUFloatTrunc((Value / unitsDiv), accuracy);

  retVal := Format('%.'+inttostr(accuracy)+'f', [z]) + ' ' + useUnits;

  Result := retVal;
end;

function SDUFactorial(x: integer): LARGE_INTEGER;
var
  retVal: LARGE_INTEGER;
  i: integer;
begin
  retVal.QuadPart := 1;

  for i:=1 to x do
    begin
    retVal.QuadPart := retVal.QuadPart * i;

{$IFOPT Q+}
    if (retVal.QuadPart <= 0) then
      begin
      raise EIntOverflow.Create('Overflow when calculating '+inttostr(i)+'!');
      end;
{$ENDIF}
    end;

  Result := retVal;
end;

function SDUSplitString(wholeString: string; var firstItem: string; var theRest: string; splitOn: char = ' '): boolean;
begin
  Result := FALSE;
  firstItem := wholeString;
  if pos(splitOn, wholeString)>0 then
    begin
    firstItem := copy(wholeString, 1, (pos(splitOn, wholeString)-1));
    theRest := copy(wholeString, length(firstItem)+length(splitOn)+1, (length(wholeString)-(length(firstItem)+length(splitOn))));
    Result := TRUE;
    end
  else
    begin
    theRest := '';
    end;
end;

end.
