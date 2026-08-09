unit ScreenshotsDBUnit;

interface

uses
  Classes, SysUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Phys.SQLite,
  FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.Stan.Error;

type
  TScreenshotsDB = class
  private
    FDBPath: String;
    FConn: TFDConnection;
    FStoreCount: Integer;
    procedure OpenConnection;
    procedure ApplyPRAGMAs;
    procedure InitSchema;
    procedure ValidateDB;
    procedure DeleteDBFiles;
    function IsLockError(E: Exception): Boolean;
  public
    constructor Create(const ADBPath: String);
    destructor Destroy; override;
    function Lookup(const Key: String; var FileSize: Int64; var FileDate: TDateTime;
      var OrigW, OrigH: Integer): Boolean;
    procedure Store(const Key: String; FileSize: Int64; FileDate: TDateTime;
      OrigW, OrigH: Integer; const Data: TMemoryStream);
    function Fetch(const Key: String): TMemoryStream;
    procedure Remove(const Key: String);
    procedure RemoveLike(const KeyPattern: String);
  end;

function GetSQLiteUserVersion(AConn: TFDConnection): Integer;

implementation

uses
  Windows, FireDACSilentUnit, LoggingUnit, CommonHelpers, PrgSetupUnit;

const
  cWalCheckpointEvery = 50;
  cStoreMaxAttempts = 3;

{ TScreenshotsDB }

constructor TScreenshotsDB.Create(const ADBPath: String);
var
  Dir: String;
begin
  inherited Create;
  FDBPath := ADBPath;
  FStoreCount := 0;
  FConn := nil;

  Dir := ExtractFilePath(FDBPath);
  if (Dir <> '') and (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);

  EnsureFireDACSilent;

  { Same pattern as ExoDOSDBUnit: set DriverName then Add Database.
    Do not Params.Clear after DriverName — that drops DriverID and raises EFDException -340. }
  try
    FConn := TFDConnection.Create(nil);
    FConn.LoginPrompt := False;
    FConn.DriverName := 'SQLite';
    FConn.ResourceOptions.SilentMode := True;
    FConn.Params.Add('Database=' + FDBPath);

    { One connect attempt only — vendor-lib / open failure propagates once. }
    OpenConnection;
    ApplyPRAGMAs;
    InitSchema;
    ValidateDB;
  except
    if FConn <> nil then begin
      try
        if FConn.Connected then
          FConn.Connected := False;
      except
        on E: Exception do
          LogInfo('ScreenshotsDB: disconnect after create fail: '+E.ClassName+': '+E.Message);
      end;
      FreeAndNil(FConn);
    end;
    raise;
  end;
end;

destructor TScreenshotsDB.Destroy;
begin
  if FConn <> nil then begin
    try
      if FConn.Connected then
        FConn.Connected := False;
    except
      on E: Exception do
        LogInfo('ScreenshotsDB: disconnect on destroy: '+E.ClassName+': '+E.Message);
    end;
    FreeAndNil(FConn);
  end;
  inherited Destroy;
end;

procedure TScreenshotsDB.OpenConnection;
begin
  if FConn = nil then
    raise Exception.Create('ScreenshotsDB: connection not created');
  { No AutoReconnect / no second try here — caller handles failure once. }
  FConn.Connected := True;
end;

procedure TScreenshotsDB.ApplyPRAGMAs;
begin
  FConn.ExecSQL('PRAGMA journal_mode = WAL');
  FConn.ExecSQL('PRAGMA synchronous = NORMAL');
  FConn.ExecSQL('PRAGMA busy_timeout = 50');
  FConn.ExecSQL('PRAGMA temp_store = MEMORY');
  FConn.ExecSQL('PRAGMA cache_size = -64000');
end;

function GetSQLiteUserVersion(AConn: TFDConnection): Integer;
var
  Q: TFDQuery;
begin
  Result := 0;
  if AConn = nil then
    Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'PRAGMA user_version';
    Q.Open;
    try
      if not Q.Eof then
        Result := Q.Fields[0].AsInteger;
    finally
      Q.Close;
    end;
  finally
    Q.Free;
  end;
end;

procedure TScreenshotsDB.InitSchema;
begin
  { No user_version (or 0): wipe Thumbnails so CREATE rebuilds current schema. }
  if GetSQLiteUserVersion(FConn) = 0 then begin
    LogInfo('Screenshots cache: user_version is 0, dropping Thumbnails table for rebuild');
    FConn.ExecSQL('DROP TABLE IF EXISTS Thumbnails');
  end;

  FConn.ExecSQL(
    'CREATE TABLE IF NOT EXISTS Thumbnails (' +
    '  Key       TEXT    NOT NULL PRIMARY KEY,' +
    '  FileSize  INTEGER NOT NULL,' +
    '  FileDate  REAL    NOT NULL,' +
    '  ImageData BLOB    NOT NULL,' +
    '  CreatedAt REAL    NOT NULL DEFAULT (julianday(''now'')),' +
    '  orig_w    INTEGER NOT NULL DEFAULT 0,' +
    '  orig_h    INTEGER NOT NULL DEFAULT 0' +
    ')'
  );

  FConn.ExecSQL('PRAGMA user_version = '+IntToStr(VersionToInt(PrgSetup.DFendVersion)));
end;

procedure TScreenshotsDB.DeleteDBFiles;
begin
  SysUtils.DeleteFile(FDBPath);
  SysUtils.DeleteFile(FDBPath + '-wal');
  SysUtils.DeleteFile(FDBPath + '-shm');
end;

procedure TScreenshotsDB.ValidateDB;
var
  Q: TFDQuery;
  CheckResult: String;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'PRAGMA quick_check';
    Q.Open;
    try
      if Q.Eof then
        CheckResult := ''
      else
        CheckResult := Q.Fields[0].AsString;
    finally
      Q.Close;
    end;
  finally
    Q.Free;
  end;

  if SameText(CheckResult, 'ok') then
    Exit;

  { Corrupt cache: recreate once. Do not loop if reopen fails. }
  try
    FConn.Connected := False;
  except
    on E: Exception do
      LogInfo('ScreenshotsDB: disconnect before recreate: '+E.ClassName+': '+E.Message);
  end;
  DeleteDBFiles;
  OpenConnection;
  ApplyPRAGMAs;
  InitSchema;
end;

function TScreenshotsDB.IsLockError(E: Exception): Boolean;
var
  S: String;
begin
  Result := False;
  if E = nil then
    Exit;
  S := LowerCase(E.Message);
  Result := (Pos('busy', S) > 0) or (Pos('locked', S) > 0) or (Pos('lock', S) > 0);
  if (not Result) and (E is EFDDBEngineException) then
    Result := (EFDDBEngineException(E).ErrorCode = 5) or
              (EFDDBEngineException(E).ErrorCode = 6);
end;

function TScreenshotsDB.Lookup(const Key: String; var FileSize: Int64; var FileDate: TDateTime;
  var OrigW, OrigH: Integer): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  FileSize := 0;
  FileDate := 0;
  OrigW := 0;
  OrigH := 0;
  if (FConn = nil) or (not FConn.Connected) then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT FileSize, FileDate, orig_w, orig_h FROM Thumbnails WHERE Key = :K';
    Q.ParamByName('K').AsString := Key;
    try
      Q.Open;
      Result := not Q.Eof;
      if Result then begin
        FileSize := Q.FieldByName('FileSize').AsLargeInt;
        FileDate := Q.FieldByName('FileDate').AsFloat;
        OrigW := Q.FieldByName('orig_w').AsInteger;
        OrigH := Q.FieldByName('orig_h').AsInteger;
      end;
      Q.Close;
    except
      on E: Exception do begin
        LogInfo('ScreenshotsDB: Lookup failed key="'+Key+'" '+E.ClassName+': '+E.Message);
        Result := False;
        FileSize := 0;
        FileDate := 0;
        OrigW := 0;
        OrigH := 0;
      end;
    end;
  finally
    Q.Free;
  end;
end;

procedure TScreenshotsDB.Store(const Key: String; FileSize: Int64; FileDate: TDateTime;
  OrigW, OrigH: Integer; const Data: TMemoryStream);
var
  Attempt: Integer;
  Q: TFDQuery;
begin
  if (FConn = nil) or (not FConn.Connected) or (Data = nil) then
    Exit;

  for Attempt := 1 to cStoreMaxAttempts do begin
    Q := TFDQuery.Create(nil);
    try
      try
        Q.Connection := FConn;
        Q.SQL.Text :=
          'INSERT OR REPLACE INTO Thumbnails (Key, FileSize, FileDate, ImageData, CreatedAt, orig_w, orig_h) ' +
          'VALUES (:K, :FS, :FD, :ID, julianday(''now''), :OW, :OH)';
        Q.ParamByName('K').AsString := Key;
        Q.ParamByName('FS').AsLargeInt := FileSize;
        Q.ParamByName('FD').AsFloat := FileDate;
        Q.ParamByName('OW').AsInteger := OrigW;
        Q.ParamByName('OH').AsInteger := OrigH;
        Data.Position := 0;
        { ExecSQL(SQL, [..]) has no TMemoryStream / blob overload in FireDAC. }
        Q.ParamByName('ID').LoadFromStream(Data, ftBlob);
        Q.ExecSQL;
        Inc(FStoreCount);
        if (FStoreCount mod cWalCheckpointEvery) = 0 then begin
          try
            FConn.ExecSQL('PRAGMA wal_checkpoint(PASSIVE)');
          except
            on E: Exception do
              LogInfo('ScreenshotsDB: wal_checkpoint failed: '+E.ClassName+': '+E.Message);
          end;
        end;
        Exit;
      except
        on E: Exception do begin
          if (Attempt < cStoreMaxAttempts) and IsLockError(E) then
            Sleep(Attempt * 50)
          else begin
            LogInfo('ScreenshotsDB: Store failed key="'+Key+'" '+E.ClassName+': '+E.Message);
            Exit; { disposable cache: fail silently rather than raise into UI }
          end;
        end;
      end;
    finally
      Q.Free;
    end;
  end;
end;

function TScreenshotsDB.Fetch(const Key: String): TMemoryStream;
var
  Q: TFDQuery;
begin
  Result := nil;
  if (FConn = nil) or (not FConn.Connected) then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT ImageData FROM Thumbnails WHERE Key = :K';
    Q.ParamByName('K').AsString := Key;
    try
      Q.Open;
      if not Q.Eof then begin
        Result := TMemoryStream.Create;
        try
          { No AsBlobSize on TField in this RAD version; SaveToStream grows the stream. }
          (Q.FieldByName('ImageData') as TBlobField).SaveToStream(Result);
          Result.Position := 0;
        except
          on E: Exception do begin
            LogInfo('ScreenshotsDB: Fetch blob failed key="'+Key+'" '+E.ClassName+': '+E.Message);
            FreeAndNil(Result);
          end;
        end;
      end;
      Q.Close;
    except
      on E: Exception do begin
        LogInfo('ScreenshotsDB: Fetch failed key="'+Key+'" '+E.ClassName+': '+E.Message);
        FreeAndNil(Result);
      end;
    end;
  finally
    Q.Free;
  end;
end;

procedure TScreenshotsDB.Remove(const Key: String);
begin
  if (FConn = nil) or (not FConn.Connected) then
    Exit;
  try
    FConn.ExecSQL('DELETE FROM Thumbnails WHERE Key = :K', [Key]);
  except
    on E: Exception do
      LogInfo('ScreenshotsDB: Remove failed key="'+Key+'" '+E.ClassName+': '+E.Message);
  end;
end;

procedure TScreenshotsDB.RemoveLike(const KeyPattern: String);
begin
  if (FConn = nil) or (not FConn.Connected) then
    Exit;
  try
    FConn.ExecSQL('DELETE FROM Thumbnails WHERE Key LIKE :P', [KeyPattern]);
  except
    on E: Exception do
      LogInfo('ScreenshotsDB: RemoveLike failed pattern="'+KeyPattern+'" '+E.ClassName+': '+E.Message);
  end;
end;

end.
