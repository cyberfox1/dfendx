unit ResHookHelpers;

interface

uses SysUtils;

function StrToMonth(const AMonth: string): Byte;
function StrToDay(const ADay: string): Byte;
function GmtOffsetStrToDateTime(S: string): TDateTime;
function NewRawStrInternetToDateTime(var Value: string): TDateTime;

implementation

uses IdGlobal, IdGlobalProtocols;

function StrToMonth(const AMonth: string): Byte;
begin
  Result := Succ(PosInStrArray(Uppercase(AMonth),
    ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']));
end;

function StrToDay(const ADay: string): Byte;
begin
  Result := Succ(PosInStrArray(Uppercase(ADay),
    ['SUN','MON','TUE','WED','THU','FRI','SAT']));
end;

function GmtOffsetStrToDateTime(S: string): TDateTime;
begin
  Result := 0.0;
  S := Copy(Trim(s), 1, 5);
  if Length(S) > 0 then
  begin
    if s[1] in ['-', '+'] then
    begin
      try
        Result := EncodeTime(StrToInt(Copy(s, 2, 2)), StrToInt(Copy(s, 4, 2)), 0, 0);
        if s[1] = '-' then
        begin
          Result := -Result;
        end;
      except
        Result := 0.0;
      end;
    end;
  end;
end;

function NewRawStrInternetToDateTime(var Value: string): TDateTime;
var
  i: Integer;
  Dt, Mo, Yr, Ho, Min, Sec: Word;
  sTime: String;
  ADelim: string;
  SaveValue : String;

  Procedure ParseDayOfMonth;
  begin
    Dt :=  StrToIntDef( Fetch(Value, ADelim), 1);
    Value := TrimLeft(Value);
  end;

  Procedure ParseMonth;
  begin
    Mo := StrToMonth( Fetch ( Value, ADelim )  );
    Value := TrimLeft(Value);
  end;
begin

  If Pos('/',Value)>0 Then
  Begin
    if Pos(',', Value) > 0 then begin
      sTime := Fetch(Value);
    end else begin
      sTime := '';
    end;
    Dt := StrToIntDef(Fetch(Value, '/'), 1);
    Mo := StrToIntDef(Fetch(Value, '/'), 1);
    Yr := StrToIntDef(Fetch(Value, '/'), 1900);
    if sTime <> '' then
      Value := Trim(sTime) + ' ' + IntToStr(Dt) + ' ' + FormatSettings.ShortMonthNames[Mo] + ' ' + IntToStr(Yr)
    else
      Value := IntToStr(Dt) + ' ' + FormatSettings.ShortMonthNames[Mo] + ' ' + IntToStr(Yr);
  End;

  Result := 0.0;
  Value := Trim(Value);
  if Length(Value) = 0 then begin
    Exit;
  end;

  try
    {Day of Week}
    if StrToDay(Copy(Value, 1, 3)) > 0 then begin
      if (Copy(Value,4,1)=',') and (Copy(Value,5,1)<>' ') then
      begin
        System.Insert(' ',Value,5);
      end;
      Fetch(Value);
      Value := TrimLeft(Value);
    end;

    { Workaround for some buggy web servers which use '-' to separate the date parts.}
    if (IndyPos('-', Value) > 1) and ((IndyPos(' ', Value) = 0) or (IndyPos('-', Value) < IndyPos(' ', Value))) then begin
      ADelim := '-';
    end
    else begin
      ADelim := ' ';
    end;
    {workaround for improper dates such as 'Fri, Sep 7 2001'}
    if (StrToMonth(Fetch(Value, ADelim,False)) > 0) then
    begin
      {Month}
      ParseMonth;
      {Day of Month}
      ParseDayOfMonth;
    end
    else
    begin
      {Day of Month}
      ParseDayOfMonth;
      {Month}
      SaveValue:=Value;
      ParseMonth;
      If Mo=0 then begin
        Value:=SaveValue;
        ADelim := '-';
        ParseDayOfMonth;
        ParseMonth;
      end;
    end;
    {Year}
    sTime := Fetch(Value);
    Yr := StrToIntDef(sTime, 1900);
    if Yr = 1900 then begin
      Yr := StrToIntDef(Value, 1900);
      Value := sTime;
    end;
    if Yr < 80 then begin
      Inc(Yr, 2000);
    end else if Yr < 100 then begin
      Inc(Yr, 1900);
    end;

    if Mo = 0 then begin
      Result := 0.0;
      Exit;
    end;
    Result := EncodeDate(Yr, Mo, Dt);
    i := IndyPos(':', Value);
    if i > 0 then begin
      Ho  := StrToIntDef( Fetch ( Value,':'), 0);
      Min := StrToIntDef( Fetch ( Value,':'), 0);
      Sec := StrToIntDef( Fetch ( Value ), 0);
      Result := Result + EncodeTime(Ho, Min, Sec, 0);
    end;
    Value := TrimLeft(Value);
  except
    Result := 0.0;
  end;
end;

end.
