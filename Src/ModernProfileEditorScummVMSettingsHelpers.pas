unit ModernProfileEditorScummVMSettingsHelpers;

interface

uses
  Classes, SysUtils, ScummVMGameOptions;

{ Pure helpers for the DOSBox-profile ScummVM settings page.

  Profile storage:
    ScummVMGame / GameName = gameid  or  gameid[variant]
    ScummGameOptions = comma list:
      selected bool keys as bare names
      integer keys as key=value
      e.g. opt_one,opt_two=5,opt_three=1,opt_four
}

type
  TScummVMSettingsData = record
    GameId: String;
    Variant: String;
    ExtraOptions: String;
  end;

procedure ScummVMSettingsParseGameToken(const Stored: String; out GameId, Variant: String);
function ScummVMSettingsFormatGameToken(const GameId, Variant: String): String;
function ScummVMSettingsBareGameId(const GameId: String): String;

procedure ScummVMSettingsLoadData(const StoredGameToken, ScummGameOptions: String; out Data: TScummVMSettingsData);

procedure ScummVMSettingsSaveData(
  const Data: TScummVMSettingsData;
  const ComboGameId: String;
  const ComboResolved: Boolean;
  const ComboVariant: String;
  const Opts: TScummVMGameOptionArray;
  const BoolValues: array of Boolean;
  const IntValues: array of Integer;
  out OutData: TScummVMSettingsData;
  out OutGameToken: String
);

procedure ScummVMSettingsCollectVariants(const GameId: String; const Dest: TStrings);
function ScummVMSettingsLoadOptions(const GameId: String; const Variant: String = ''): TScummVMGameOptionArray;

{ Bool on -> "key"; integer -> "key=value". Unchecked bools omitted. }
function ScummVMSettingsEncodeOptions(
  const Opts: TScummVMGameOptionArray;
  const BoolValues: array of Boolean;
  const IntValues: array of Integer
): String;

function ScummVMSettingsIsSelected(const Stored: String; const IniKey: String): Boolean;
function ScummVMSettingsReadInt(const Stored: String; const IniKey: String; const DefaultInt: Integer): Integer;

procedure ScummVMSettingsValuesFromStored(
  const Opts: TScummVMGameOptionArray;
  const Stored: String;
  var BoolValues: array of Boolean;
  var IntValues: array of Integer
);

procedure ScummVMSettingsRoundTripValues(
  const Opts: TScummVMGameOptionArray;
  const InBool: array of Boolean;
  const InInt: array of Integer;
  var OutBool: array of Boolean;
  var OutInt: array of Integer
);

implementation

uses
  CommonHelpers;

function ScummVMSettingsBareGameId(const GameId: String): String;
var
  S: String;
  P: Integer;
begin
  S := Trim(GameId);
  P := Pos(':', S);
  if P > 0 then
    Result := Copy(S, P + 1, MaxInt)
  else
    Result := S;
end;

procedure ScummVMSettingsParseGameToken(const Stored: String; out GameId, Variant: String);
var
  S: String;
  P, Q: Integer;
begin
  GameId := '';
  Variant := '';
  S := Trim(Stored);
  if S = '' then Exit;
  P := Pos('[', S);
  if P <= 0 then begin
    GameId := ScummVMSettingsBareGameId(S);
    Exit;
  end;
  GameId := ScummVMSettingsBareGameId(Copy(S, 1, P - 1));
  Q := Length(S);
  if (Q > P) and (S[Q] = ']') then
    Variant := Copy(S, P + 1, Q - P - 1)
  else
    Variant := Copy(S, P + 1, MaxInt);
  Variant := Trim(Variant);
end;

function ScummVMSettingsFormatGameToken(const GameId, Variant: String): String;
var
  Id, VarTok: String;
begin
  Id := ScummVMSettingsBareGameId(GameId);
  VarTok := Trim(Variant);
  if Id = '' then begin
    Result := '';
    Exit;
  end;
  if VarTok = '' then
    Result := Id
  else
    Result := Id + '[' + VarTok + ']';
end;

procedure ScummVMSettingsLoadData(const StoredGameToken, ScummGameOptions: String; out Data: TScummVMSettingsData);
begin
  ScummVMSettingsParseGameToken(StoredGameToken, Data.GameId, Data.Variant);
  Data.ExtraOptions := Trim(ScummGameOptions);
end;

procedure ScummVMSettingsCollectVariants(const GameId: String; const Dest: TStrings);
begin
  GetScummVMGameIdVariants(ScummVMSettingsBareGameId(GameId), Dest);
end;

function ScummVMSettingsLoadOptions(const GameId: String; const Variant: String = ''): TScummVMGameOptionArray;
begin
  Result := GetScummVMGameOptionsCoreThenVariant(ScummVMSettingsBareGameId(GameId), Trim(Variant));
end;

function ScummVMSettingsEncodeOptions(
  const Opts: TScummVMGameOptionArray;
  const BoolValues: array of Boolean;
  const IntValues: array of Integer
): String;
var
  I: Integer;
  Parts: TStringList;
  On: Boolean;
  IntVal: Integer;
begin
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ',';
    Parts.QuoteChar := #0;
    for I := 0 to High(Opts) do begin
      if Opts[I].Kind = sgokInteger then begin
        if (I >= Low(IntValues)) and (I <= High(IntValues)) then
          IntVal := IntValues[I]
        else
          IntVal := Opts[I].DefaultInt;
        Parts.Add(Opts[I].IniKey + '=' + IntToStr(IntVal));
      end else begin
        if (I >= Low(BoolValues)) and (I <= High(BoolValues)) then
          On := BoolValues[I]
        else
          On := Opts[I].DefaultBool;
        if On then
          Parts.Add(Opts[I].IniKey);
      end;
    end;
    Result := Parts.DelimitedText;
  finally
    Parts.Free;
  end;
end;

function ScummVMSettingsTokenKey(const Token: String): String;
var
  P: Integer;
begin
  P := Pos('=', Token);
  if P <= 0 then
    Result := Trim(Token)
  else
    Result := Trim(Copy(Token, 1, P - 1));
end;

function ScummVMSettingsIsSelected(const Stored: String; const IniKey: String): Boolean;
var
  St: TStringList;
  I: Integer;
  Key: String;
begin
  Result := False;
  Key := Trim(IniKey);
  if (Key = '') or (Trim(Stored) = '') then Exit;
  St := TStringList.Create;
  try
    St.StrictDelimiter := True;
    St.Delimiter := ',';
    St.QuoteChar := #0;
    St.DelimitedText := Stored;
    for I := 0 to St.Count - 1 do
      if SameText(ScummVMSettingsTokenKey(St[I]), Key) then begin
        Result := True;
        Exit;
      end;
  finally
    St.Free;
  end;
end;

function ScummVMSettingsReadInt(const Stored: String; const IniKey: String; const DefaultInt: Integer): Integer;
var
  St: TStringList;
  I, P: Integer;
  Key, Tok, RHS: String;
begin
  Result := DefaultInt;
  Key := Trim(IniKey);
  if (Key = '') or (Trim(Stored) = '') then Exit;
  St := TStringList.Create;
  try
    St.StrictDelimiter := True;
    St.Delimiter := ',';
    St.QuoteChar := #0;
    St.DelimitedText := Stored;
    for I := 0 to St.Count - 1 do begin
      Tok := Trim(St[I]);
      P := Pos('=', Tok);
      if P <= 0 then Continue;
      if not SameText(Trim(Copy(Tok, 1, P - 1)), Key) then Continue;
      RHS := Trim(Copy(Tok, P + 1, MaxInt));
      if TryStrToInt(RHS, Result) then Exit;
      Result := DefaultInt;
      Exit;
    end;
  finally
    St.Free;
  end;
end;

procedure ScummVMSettingsValuesFromStored(
  const Opts: TScummVMGameOptionArray;
  const Stored: String;
  var BoolValues: array of Boolean;
  var IntValues: array of Integer
);
var
  I: Integer;
  HasStored: Boolean;
begin
  HasStored := Trim(Stored) <> '';
  for I := 0 to High(Opts) do begin
    if Opts[I].Kind = sgokInteger then begin
      if (I >= Low(IntValues)) and (I <= High(IntValues)) then begin
        if HasStored then
          IntValues[I] := ScummVMSettingsReadInt(Stored, Opts[I].IniKey, Opts[I].DefaultInt)
        else
          IntValues[I] := Opts[I].DefaultInt;
      end;
    end else begin
      if (I >= Low(BoolValues)) and (I <= High(BoolValues)) then begin
        if HasStored then
          BoolValues[I] := ScummVMSettingsIsSelected(Stored, Opts[I].IniKey)
        else
          BoolValues[I] := Opts[I].DefaultBool;
      end;
    end;
  end;
end;

procedure ScummVMSettingsSaveData(
  const Data: TScummVMSettingsData;
  const ComboGameId: String;
  const ComboResolved: Boolean;
  const ComboVariant: String;
  const Opts: TScummVMGameOptionArray;
  const BoolValues: array of Boolean;
  const IntValues: array of Integer;
  out OutData: TScummVMSettingsData;
  out OutGameToken: String
);
var
  Id: String;
begin
  if ComboResolved then
    Id := ScummVMSettingsBareGameId(ComboGameId)
  else
    Id := Data.GameId;
  OutData.GameId := Id;
  if ComboResolved then
    OutData.Variant := Trim(ComboVariant)
  else
    OutData.Variant := Data.Variant;
  OutData.ExtraOptions := ScummVMSettingsEncodeOptions(Opts, BoolValues, IntValues);
  OutGameToken := ScummVMSettingsFormatGameToken(OutData.GameId, OutData.Variant);
end;

procedure ScummVMSettingsRoundTripValues(
  const Opts: TScummVMGameOptionArray;
  const InBool: array of Boolean;
  const InInt: array of Integer;
  var OutBool: array of Boolean;
  var OutInt: array of Integer
);
var
  Encoded: String;
begin
  Encoded := ScummVMSettingsEncodeOptions(Opts, InBool, InInt);
  ScummVMSettingsValuesFromStored(Opts, Encoded, OutBool, OutInt);
end;

end.
