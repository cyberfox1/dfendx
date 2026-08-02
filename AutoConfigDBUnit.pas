unit AutoConfigDBUnit;

interface

uses
  Windows, SysUtils, Classes, FireDAC.Comp.Client, FireDAC.Phys.SQLite,
  FireDAC.Stan.Def, FireDAC.Stan.Intf, FireDAC.Stan.Async, FireDAC.VCLUI.Wait,
  FireDAC.DApt, Data.DB;

type
  TAutoConfigDB = class
  private
    FConnection : TFDConnection;
    FDBPath : String;
  public
    constructor Create(const ADBPath : String);
    destructor Destroy; override;

    function HasMD5(const MD5 : String) : Boolean;

    { Returns a TStringList where each entry is pipe-delimited:
      Name|GameExe|GameExeMD5|ProfFile  for profiles whose EXE filename
      matches AExeName (case-insensitive comparison on ExtractFileName). }
    function FindProfilesByExe(const AExeName : String) : TStringList;

    { Returns ProfFile names (one per line) for profiles whose
      GameExeMD5 equals AMD5. }
    function FindProfilesByMD5(const AMD5 : String) : TStringList;

    { Runs the existing FindGameByNameOrChecksum logic against this DB:
      matches by Name (case-insensitive) with optional MD5 validation. }
    function MatchByNameOrChecksum(const AName, AChecksum : String) : Boolean;

    { Returns duplicate-MD5 diagnostic lines. For pairs whose extended
      checksums differ, loads the .prof files from ASetupDir to avoid
      false-positive reports. }
    function CheckDuplicates(const ASetupDir : String) : TStringList;

    property DBPath : String read FDBPath;
  end;

implementation

uses FireDACSilentUnit, LoggingUnit;

constructor TAutoConfigDB.Create(const ADBPath : String);
begin
  FDBPath := ADBPath;
  FConnection := nil;
  EnsureFireDACSilent;
  try
    FConnection := TFDConnection.Create(nil);
    FConnection.LoginPrompt := False;
    FConnection.DriverName := 'SQLite';
    FConnection.ResourceOptions.SilentMode := True;
    FConnection.Params.Add('Database=' + FDBPath);
    FConnection.Connected := True;
  except
    if FConnection <> nil then begin
      try
        if FConnection.Connected then
          FConnection.Connected := False;
      except
        on E: Exception do
          LogInfo('AutoConfigDB: disconnect after create fail: '+E.ClassName+': '+E.Message);
      end;
      FreeAndNil(FConnection);
    end;
    raise;
  end;
end;

destructor TAutoConfigDB.Destroy;
begin
  if FConnection <> nil then begin
    try
      if FConnection.Connected then
        FConnection.Connected := False;
    except
      on E: Exception do
        LogInfo('AutoConfigDB: disconnect on destroy: '+E.ClassName+': '+E.Message);
    end;
    FreeAndNil(FConnection);
  end;
  inherited Destroy;
end;

function TAutoConfigDB.HasMD5(const MD5 : String) : Boolean;
var Q : TFDQuery;
begin
  result := False;
  if Trim(MD5) = '' then exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT 1 FROM Profiles WHERE GameExeMD5 = :md5 LIMIT 1';
    Q.ParamByName('md5').AsString := MD5;
    Q.Open;
    result := not Q.Eof;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TAutoConfigDB.FindProfilesByExe(const AExeName : String) : TStringList;
var Q : TFDQuery;
    Exe, Name, MD5, Prof : String;
begin
  result := TStringList.Create;
  if Trim(AExeName) = '' then exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT Name, GameExe, GameExeMD5, ProfFile FROM Profiles '+
      'WHERE GameExe = :exe COLLATE NOCASE';
    Q.ParamByName('exe').AsString := AExeName;
    Q.Open;
    while not Q.Eof do begin
      Name := Q.FieldByName('Name').AsString;
      Exe  := Q.FieldByName('GameExe').AsString;
      MD5  := Q.FieldByName('GameExeMD5').AsString;
      Prof := Q.FieldByName('ProfFile').AsString;
      result.Add(Name + '|' + Exe + '|' + MD5 + '|' + Prof);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TAutoConfigDB.FindProfilesByMD5(const AMD5 : String) : TStringList;
var Q : TFDQuery;
begin
  result := TStringList.Create;
  if Trim(AMD5) = '' then exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT ProfFile FROM Profiles WHERE GameExeMD5 = :md5';
    Q.ParamByName('md5').AsString := AMD5;
    Q.Open;
    while not Q.Eof do begin
      result.Add(Q.FieldByName('ProfFile').AsString);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TAutoConfigDB.MatchByNameOrChecksum(const AName, AChecksum : String) : Boolean;
var Q : TFDQuery;
    S, DBName, DBMD5 : String;
    Found : Boolean;
begin
  result := False;
  S := ExtUpperCase(AName);
  if Trim(S) = '' then exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT Name, GameExeMD5 FROM Profiles '+
      'WHERE Name = :name COLLATE NOCASE';
    Q.ParamByName('name').AsString := AName;
    Q.Open;

    Found := False;
    while not Q.Eof do begin
      DBName := Q.FieldByName('Name').AsString;
      DBMD5  := Q.FieldByName('GameExeMD5').AsString;
      if ExtUpperCase(DBName) = S then begin
        if AChecksum = '' then begin result := True; Q.Close; exit; end;
        if DBMD5 = '' then begin Found := True; end
        else if DBMD5 = AChecksum then begin result := True; Q.Close; exit; end
        else begin if Found then Found := False; end;
      end;
      Q.Next;
    end;

    if Found then result := True;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TAutoConfigDB.CheckDuplicates(const ASetupDir : String) : TStringList;
var Q : TFDQuery;
    PrevExe, PrevMD5, PrevName, PrevProf : String;
    Exe, MD5, Name, Prof : String;
begin
  result := TStringList.Create;
  PrevExe := ''; PrevMD5 := ''; PrevName := ''; PrevProf := '';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT GameExe, GameExeMD5, Name, ProfFile FROM Profiles '+
      'WHERE GameExe != "" AND GameExeMD5 != "" '+
      'ORDER BY GameExe, GameExeMD5';
    Q.Open;
    while not Q.Eof do begin
      Exe := Q.FieldByName('GameExe').AsString;
      MD5 := Q.FieldByName('GameExeMD5').AsString;
      Name := Q.FieldByName('Name').AsString;
      Prof := Q.FieldByName('ProfFile').AsString;
      if (Exe = PrevExe) and (MD5 = PrevMD5) then
        result.Add(PrevName + ' <-> ' + Name);
      PrevExe := Exe; PrevMD5 := MD5; PrevName := Name; PrevProf := Prof;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

end.
