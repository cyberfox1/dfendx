unit ExoDOSDBUnit;

interface

uses
  Windows, SysUtils, Classes, FireDAC.Comp.Client, FireDAC.Phys.SQLite,
  FireDAC.Stan.Def, FireDAC.Stan.Intf, FireDAC.Stan.Async, FireDAC.VCLUI.Wait,
  FireDAC.DApt, Data.DB;

type
  TExoMediaCategory = (emcImages, emcVideos, emcManuals, emcMusic);

  TExoDOSDB=class
  private
    FConnection : TFDConnection;
    FQuery : TFDQuery;
    FDBPath : String;
    FQueryCount : Integer;
  public
    constructor Create(const ADBPath : String);
    destructor Destroy; override;
    procedure Initialize;
    procedure AddGame(const Title, Year : String; const DataBlob : String);
    procedure FinalizeLoad;
    function GetGameCount : Integer;
    function GetGamesAsTextList : TStringList;
    function GetGameDataByName(const Title : String; var Year, DataBlob : String) : Boolean;
    property DBPath : String read FDBPath;
  end;

  TExoDOSMediaDB=class
  private
    FConnection : TFDConnection;
    FInsertQuery : TFDQuery;
    FDBPath : String;
    FInsertCount : Integer;
    function  GetMediaPathsByCategory(const ANormalizedTitle : String; const ACategory : TExoMediaCategory; const ADirPrefix : String = '') : TStringList;
  public
    constructor Create(const ADBPath : String);
    destructor Destroy; override;
    procedure Initialize;
    procedure InsertMedia(const Title, Category, Kind, FilePath : String);
    procedure FinalizeLoad;

    function  GetImagePaths(const ANormalizedTitle : String) : TStringList;
    function  GetScreenshotPaths(const ANormalizedTitle : String) : TStringList;
    function  GetOtherImagePaths(const ANormalizedTitle : String) : TStringList;
    function  GetVideoPaths(const ANormalizedTitle : String) : TStringList;
    function  GetManualPaths(const ANormalizedTitle : String) : TStringList;
    function  GetAudioPaths(const ANormalizedTitle : String) : TStringList;

    property DBPath : String read FDBPath;
  end;

implementation

uses LoggingUnit, FireDACSilentUnit;

constructor TExoDOSDB.Create(const ADBPath : String);
begin
  FDBPath:=ADBPath;
  FQuery:=nil;
  FQueryCount:=0;
  FConnection:=nil;
  EnsureFireDACSilent;
  try
    FConnection:=TFDConnection.Create(nil);
    FConnection.LoginPrompt:=False;
    FConnection.DriverName:='SQLite';
    FConnection.ResourceOptions.SilentMode:=True;
    FConnection.Params.Add('Database='+FDBPath);
    { One connect attempt — missing sqlite3.dll raises once, no GUIx spam. }
    FConnection.Connected:=True;
  except
    if FConnection<>nil then begin
      try
        if FConnection.Connected then
          FConnection.Connected:=False;
      except
        on E: Exception do
          LogInfo('ExoDOSDB: disconnect after create fail: '+E.ClassName+': '+E.Message);
      end;
      FreeAndNil(FConnection);
    end;
    raise;
  end;
end;

destructor TExoDOSDB.Destroy;
begin
  FQuery.Free;
  if FConnection<>nil then begin
    try
      if FConnection.Connected then
        FConnection.Connected:=False;
    except
      on E: Exception do
        LogInfo('ExoDOSDB: disconnect on destroy: '+E.ClassName+': '+E.Message);
    end;
    FreeAndNil(FConnection);
  end;
  inherited Destroy;
end;

procedure TExoDOSDB.Initialize;
begin
  FConnection.ExecSQL('PRAGMA synchronous = OFF');
  FConnection.ExecSQL('PRAGMA journal_mode = MEMORY');
  FConnection.ExecSQL('PRAGMA temp_store = MEMORY');
  FConnection.ExecSQL('PRAGMA cache_size = -64000');
  FConnection.ExecSQL('DROP TABLE IF EXISTS Games');
  FConnection.ExecSQL('CREATE TABLE Games (ID INTEGER PRIMARY KEY, Title TEXT NOT NULL, Year TEXT, DataBlob TEXT)');
  FConnection.ExecSQL('BEGIN');
end;

procedure TExoDOSDB.AddGame(const Title, Year : String; const DataBlob : String);
begin
  if FQuery=nil then begin
    FQuery:=TFDQuery.Create(nil);
    FQuery.Connection:=FConnection;
    FQuery.SQL.Text:='INSERT INTO Games (Title, Year, DataBlob) VALUES (:Title, :Year, :DataBlob)';
    FQuery.Params[0].DataType:=ftString;
    FQuery.Params[0].Size:=255;
    FQuery.Params[1].DataType:=ftString;
    FQuery.Params[1].Size:=4;
    FQuery.Params[2].DataType:=ftString;
    FQuery.Params[2].Size:=65535;
    FQuery.Prepared:=True;
  end;
  FQuery.ParamByName('Title').AsString:=Title;
  FQuery.ParamByName('Year').AsString:=Year;
  FQuery.ParamByName('DataBlob').AsString:=DataBlob;
  FQuery.ExecSQL;
  Inc(FQueryCount);
  if (FQueryCount mod 100)=0 then begin
    FConnection.ExecSQL('COMMIT');
    FConnection.ExecSQL('BEGIN');
  end;
end;

procedure TExoDOSDB.FinalizeLoad;
begin
  FConnection.ExecSQL('COMMIT');
  FConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_title ON Games(Title)');
end;

function TExoDOSDB.GetGameCount : Integer;
Var Q : TFDQuery;
begin
  Q:=TFDQuery.Create(nil);
  try
    Q.Connection:=FConnection;
    Q.SQL.Text:='SELECT COUNT(*) FROM Games';
    Q.Open;
    result:=Q.Fields[0].AsInteger;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TExoDOSDB.GetGamesAsTextList : TStringList;
Var Q : TFDQuery;
    Title, Year : String;
begin
  result:=TStringList.Create;
  Q:=TFDQuery.Create(nil);
  try
    Q.Connection:=FConnection;
    Q.SQL.Text:='SELECT Title, Year FROM Games ORDER BY Title';
    Q.Open;
    while not Q.Eof do begin
      Title:=Q.FieldByName('Title').AsString;
      Year:=Q.FieldByName('Year').AsString;
      if Year<>'' then result.Add(Title+' ('+Year+')') else result.Add(Title);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TExoDOSDB.GetGameDataByName(const Title : String; var Year, DataBlob : String) : Boolean;
Var Q : TFDQuery;
begin
  Year:='';
  DataBlob:='';
  Q:=TFDQuery.Create(nil);
  try
    Q.Connection:=FConnection;
    { NOCASE: profile / eXo title case may differ }
    Q.SQL.Text:='SELECT Year, DataBlob FROM Games WHERE Title = :Title COLLATE NOCASE LIMIT 1';
    Q.ParamByName('Title').AsString:=Title;
    Q.Open;
    result:=not Q.Eof;
    if result then begin
      Year:=Q.FieldByName('Year').AsString;
      DataBlob:=Q.FieldByName('DataBlob').AsString;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

{ TExoDOSMediaDB }

constructor TExoDOSMediaDB.Create(const ADBPath : String);
begin
  FDBPath:=ADBPath;
  FInsertQuery:=nil;
  FInsertCount:=0;
  FConnection:=nil;
  EnsureFireDACSilent;
  try
    FConnection:=TFDConnection.Create(nil);
    FConnection.LoginPrompt:=False;
    FConnection.DriverName:='SQLite';
    FConnection.ResourceOptions.SilentMode:=True;
    FConnection.Params.Add('Database='+FDBPath);
    { One connect attempt — missing sqlite3.dll raises once, no GUIx spam. }
    FConnection.Connected:=True;
  except
    if FConnection<>nil then begin
      try
        if FConnection.Connected then
          FConnection.Connected:=False;
      except
        on E: Exception do
          LogInfo('ExoMediaDB: disconnect after create fail: '+E.ClassName+': '+E.Message);
      end;
      FreeAndNil(FConnection);
    end;
    raise;
  end;
end;

destructor TExoDOSMediaDB.Destroy;
begin
  FInsertQuery.Free;
  if FConnection<>nil then begin
    try
      if FConnection.Connected then
        FConnection.Connected:=False;
    except
      on E: Exception do
        LogInfo('ExoMediaDB: disconnect on destroy: '+E.ClassName+': '+E.Message);
    end;
    FreeAndNil(FConnection);
  end;
  inherited Destroy;
end;

procedure TExoDOSMediaDB.Initialize;
begin
  FConnection.ExecSQL('PRAGMA synchronous = OFF');
  FConnection.ExecSQL('PRAGMA journal_mode = MEMORY');
  FConnection.ExecSQL('PRAGMA temp_store = MEMORY');
  FConnection.ExecSQL('PRAGMA cache_size = -64000');
  FConnection.ExecSQL('DROP TABLE IF EXISTS Media');
  FConnection.ExecSQL('CREATE TABLE Media (ID INTEGER PRIMARY KEY, Title TEXT NOT NULL, Category TEXT NOT NULL, Kind TEXT NOT NULL, FilePath TEXT NOT NULL)');
  FConnection.ExecSQL('BEGIN');
end;

procedure TExoDOSMediaDB.InsertMedia(const Title, Category, Kind, FilePath : String);
begin
  if FInsertQuery=nil then begin
    FInsertQuery:=TFDQuery.Create(nil);
    FInsertQuery.Connection:=FConnection;
    FInsertQuery.SQL.Text:='INSERT INTO Media (Title, Category, Kind, FilePath) VALUES (:Title, :Category, :Kind, :FilePath)';
    FInsertQuery.Params[0].DataType:=ftString;
    FInsertQuery.Params[0].Size:=255;
    FInsertQuery.Params[1].DataType:=ftString;
    FInsertQuery.Params[1].Size:=32;
    FInsertQuery.Params[2].DataType:=ftString;
    FInsertQuery.Params[2].Size:=32;
    FInsertQuery.Params[3].DataType:=ftWideString;
    FInsertQuery.Params[3].Size:=1024;
    FInsertQuery.Prepared:=True;
  end;
  FInsertQuery.ParamByName('Title').AsString:=Title;
  FInsertQuery.ParamByName('Category').AsString:=Category;
  FInsertQuery.ParamByName('Kind').AsString:=Kind;
  FInsertQuery.ParamByName('FilePath').AsWideString:=FilePath;
  FInsertQuery.ExecSQL;
  Inc(FInsertCount);
  if (FInsertCount mod 100)=0 then begin
    FConnection.ExecSQL('COMMIT');
    FConnection.ExecSQL('BEGIN');
  end;
end;

procedure TExoDOSMediaDB.FinalizeLoad;
begin
  FConnection.ExecSQL('COMMIT');
  FConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_media_title ON Media(Title)');
end;

{ Query methods }

function TExoDOSMediaDB.GetMediaPathsByCategory(const ANormalizedTitle : String; const ACategory : TExoMediaCategory; const ADirPrefix : String) : TStringList;
Var Q : TFDQuery;
    Cat, SQL, Prefix, Filter : String;
    ExcludeMode : Boolean;
begin
  result := TStringList.Create;
  if Trim(ANormalizedTitle) = '' then exit;

  case ACategory of
    emcImages: Cat := 'Images';
    emcVideos: Cat := 'Videos';
    emcManuals: Cat := 'manuals';
    emcMusic:  Cat := 'Music';
  else exit;
  end;

  SQL := 'SELECT FilePath FROM Media WHERE Title = :title AND Category = :cat';

  Prefix := ADirPrefix;
  ExcludeMode := False;
  if (Prefix <> '') and (Prefix[1] = '-') then begin
    ExcludeMode := True;
    Prefix := Copy(Prefix, 2, MaxInt);
  end;

  if Prefix <> '' then begin
    if ExcludeMode then
      SQL := SQL + ' AND NOT (Kind LIKE :filter)'
    else
      SQL := SQL + ' AND (Kind LIKE :filter)';
    Filter := Prefix + '%';
  end;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := SQL;
    Q.ParamByName('title').AsString := ANormalizedTitle;
    Q.ParamByName('cat').AsString := Cat;
    if Prefix <> '' then
      Q.ParamByName('filter').AsString := Filter;
    LogInfo('ExoMediaDB SQL: title="'+ANormalizedTitle+'" cat="'+Cat+'" filter="'+Filter+'" sql="'+SQL+'"');
    Q.Open;
    while not Q.Eof do begin
      result.Add(Q.FieldByName('FilePath').AsString);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TExoDOSMediaDB.GetImagePaths(const ANormalizedTitle : String) : TStringList;
begin
  result := GetMediaPathsByCategory(ANormalizedTitle, emcImages);
end;

function TExoDOSMediaDB.GetScreenshotPaths(const ANormalizedTitle : String) : TStringList;
begin
  result := GetMediaPathsByCategory(ANormalizedTitle, emcImages, 'Screenshot -');
end;

function TExoDOSMediaDB.GetOtherImagePaths(const ANormalizedTitle : String) : TStringList;
begin
  result := GetMediaPathsByCategory(ANormalizedTitle, emcImages, '-Screenshot -');
end;

function TExoDOSMediaDB.GetVideoPaths(const ANormalizedTitle : String) : TStringList;
begin
  result := GetMediaPathsByCategory(ANormalizedTitle, emcVideos);
end;

function TExoDOSMediaDB.GetManualPaths(const ANormalizedTitle : String) : TStringList;
begin
  result := GetMediaPathsByCategory(ANormalizedTitle, emcManuals);
end;

function TExoDOSMediaDB.GetAudioPaths(const ANormalizedTitle : String) : TStringList;
begin
  result := GetMediaPathsByCategory(ANormalizedTitle, emcMusic);
end;

end.
