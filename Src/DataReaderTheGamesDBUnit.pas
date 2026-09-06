unit DataReaderTheGamesDBUnit;

{ TheGamesDB REST API client (https://api.thegamesdb.net/).
  Legacy thegamesdb.net/api/*.php XML endpoints are not used.
  Requires PrgSetup.TheGamesDBAPIKey (ProgramSets/TheGamesDBAPIKey in INI).
  Cover download is not implemented yet (GetGameCover returns False). }

interface

uses Classes, System.JSON, DataReaderBaseUnit;

type
  TTheGamesDBDataReader = class(TDataReader)
  private
    FGenreNames: TStringList;      { id -> name }
    FDeveloperNames: TStringList;
    FPublisherNames: TStringList;
    function APIKey: String;
    function APIGet(const PathAndQuery: String; out Body: String): Boolean;
    function LoadIdNameMap(const Path: String; const DataKey: String; Map: TStringList): Boolean;
    procedure EnsureIdsLoaded(const ByIdPath, DataKey: String; const Arr: TJSONArray; Map: TStringList);
    function ResolveIds(const Arr: TJSONArray; Map: TStringList): String;
    function YearFromReleaseDate(const S: String): String;
  public
    constructor Create;
    destructor Destroy; override;
    function ReadList(const ASearchString: String): Boolean; override;
    function GetListURL(const all: Boolean): String; override;
    function GetGameData(const Nr: Integer; out Meta: TGameMetadata): Boolean; override;
    function GetGameCover(const CoverPageURL: String; var ImageURL: String; const MaxImages: Integer): Boolean; override;
  end;

implementation

uses
  SysUtils, Windows,
  PrgSetupUnit, DataReaderToolsUnit, LoggingUnit, HTTPDownloadHelpers;

const
  { TGDB platform id for PC (DOS-era titles are usually under PC). }
  TGDBPlatformPC = 1;
  TGDBAPIBase = 'https://api.thegamesdb.net';

var
  TGDBLastCalledAt: UInt64 = 0;

procedure WaitTGDBRateLimit;
var
  PT, CT, Elapsed: UInt64;
begin
  PT := TGDBLastCalledAt;
  CT := GetTickCount64;
  TGDBLastCalledAt := CT;
  if PT = 0 then Exit;
  if CT >= PT then
    Elapsed := CT - PT
  else
    Elapsed := High(UInt64) - PT + CT + 1;
  if Elapsed < 1000 then
    Sleep(1000 - Elapsed);
end;

{ TTheGamesDBDataReader }

constructor TTheGamesDBDataReader.Create;
begin
  inherited Create;
  FDataDomain := 'api.thegamesdb.net';
  FBrowserURLAll := 'https://thegamesdb.net/';
  FBrowserURLDOS := 'https://thegamesdb.net/';
  FGenreNames := TStringList.Create;
  FDeveloperNames := TStringList.Create;
  FPublisherNames := TStringList.Create;
  FGenreNames.NameValueSeparator := '=';
  FDeveloperNames.NameValueSeparator := '=';
  FPublisherNames.NameValueSeparator := '=';
end;

destructor TTheGamesDBDataReader.Destroy;
begin
  FGenreNames.Free;
  FDeveloperNames.Free;
  FPublisherNames.Free;
  inherited Destroy;
end;

function TTheGamesDBDataReader.APIKey: String;
begin
  Result := Trim(PrgSetup.TheGamesDBAPIKey);
end;

function TTheGamesDBDataReader.APIGet(const PathAndQuery: String; out Body: String): Boolean;
var
  URL, Key: String;
  Status: Integer;
  Q: TStringList;
begin
  Result := False;
  Body := '';
  Key := APIKey;
  if Key = '' then begin
    LogInfo('TGDB.APIGet: empty TheGamesDBAPIKey');
    Exit;
  end;

  URL := TGDBAPIBase + PathAndQuery;
  Q := TStringList.Create;
  try
    Q.Values['apikey'] := Key;
    try
      Result := THTTPDownloadHelper.HTTPRequestToString('GET', URL, Q,
        PrgSetup.HTTPUserAgent, '', 30000, 60000, Body, Status);
      if not Result then
        LogInfo('TGDB.APIGet: request failed url=' + URL + ' status=' + IntToStr(Status));
      Result := Result and (Body <> '');
    except
      on E: Exception do begin
        LogInfo('TGDB.APIGet: exception ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Q.Free;
  end;
end;

function TTheGamesDBDataReader.LoadIdNameMap(const Path: String; const DataKey: String; Map: TStringList): Boolean;
var
  Body: String;
  Root, DataObj, MapObj, Item: TJSONObject;
  Pair: TJSONPair;
  I, Added: Integer;
  IdStr, NameStr: String;
  V: TJSONValue;
begin
  Result := False;
  Added := 0;
  if not APIGet(Path, Body) then Exit;
  Root := TJSONObject.ParseJSONValue(Body) as TJSONObject;
  if Root = nil then Exit;
  try
    DataObj := Root.Values['data'] as TJSONObject;
    if DataObj = nil then Exit;
    MapObj := DataObj.Values[DataKey] as TJSONObject;
    if MapObj = nil then Exit;
    for I := 0 to MapObj.Count - 1 do begin
      Pair := MapObj.Pairs[I];
      if Pair.JsonValue is TJSONObject then begin
        Item := TJSONObject(Pair.JsonValue);
        IdStr := '';
        NameStr := '';
        V := Item.Values['id'];
        if V <> nil then IdStr := V.Value;
        V := Item.Values['name'];
        if V <> nil then NameStr := V.Value;
        if IdStr = '' then IdStr := Pair.JsonString.Value;
        if (IdStr <> '') and (NameStr <> '') then begin
          Map.Values[IdStr] := NameStr;
          Inc(Added);
        end;
      end;
    end;
    Result := Added > 0;
  finally
    Root.Free;
  end;
end;

procedure TTheGamesDBDataReader.EnsureIdsLoaded(const ByIdPath, DataKey: String; const Arr: TJSONArray; Map: TStringList);
var
  I: Integer;
  IdStr, Missing: String;
begin
  if (Arr = nil) or (Arr.Count = 0) then Exit;
  Missing := '';
  for I := 0 to Arr.Count - 1 do begin
    IdStr := Trim(Arr.Items[I].Value);
    if IdStr = '' then Continue;
    if Map.Values[IdStr] <> '' then Continue;
    if Missing <> '' then Missing := Missing + ',';
    Missing := Missing + IdStr;
  end;
  if Missing = '' then Exit;
  LoadIdNameMap(ByIdPath+'?id='+Missing, DataKey, Map);
end;

function TTheGamesDBDataReader.ResolveIds(const Arr: TJSONArray; Map: TStringList): String;
var
  I: Integer;
  IdStr, Name: String;
begin
  Result := '';
  if (Arr = nil) or (Arr.Count = 0) then Exit;
  for I := 0 to Arr.Count - 1 do begin
    IdStr := Arr.Items[I].Value;
    Name := Map.Values[IdStr];
    if Name = '' then Name := IdStr;
    if Name = '' then Continue;
    if Result <> '' then Result := Result + '; ';
    Result := Result + Name;
  end;
end;

function TTheGamesDBDataReader.YearFromReleaseDate(const S: String): String;
var
  T: String;
  I: Integer;
begin
  T := Trim(S);
  Result := '';
  if T = '' then Exit;
  I := Pos('-', T);
  if I > 1 then
    Result := Copy(T, 1, I - 1)
  else if Length(T) >= 4 then
    Result := Copy(T, 1, 4)
  else
    Result := T;
end;

function TTheGamesDBDataReader.GetListURL(const all: Boolean): String;
begin
  { Browser open only — not used for API. }
  if all then
    Result := 'https://thegamesdb.net/search.php?name=%s'
  else
    Result := 'https://thegamesdb.net/search.php?name=%s&platform_id=' + IntToStr(TGDBPlatformPC);
end;

function TTheGamesDBDataReader.ReadList(const ASearchString: String): Boolean;
var
  Body, Path, Title, IdStr: String;
  Root, DataObj, GameObj: TJSONObject;
  Games: TJSONArray;
  I: Integer;
  V: TJSONValue;
begin
  FGameNames.Clear;
  FGameURLs.Clear;
  FLastListRequest := '';
  Result := False;

  if APIKey = '' then begin
    LogInfo('TGDB.ReadList: TheGamesDBAPIKey not set');
    Exit;
  end;

  WaitTGDBRateLimit;

  Path := '/v1.1/Games/ByGameName?name=' + EncodeName(ASearchString) +
    '&fields=overview,genres,developers,publishers,platform';
  if not PrgSetup.DataReaderAllPlatforms then
    Path := Path + '&filter[platform]=' + IntToStr(TGDBPlatformPC);

  if not APIGet(Path, Body) then Exit;

  Root := TJSONObject.ParseJSONValue(Body) as TJSONObject;
  if Root = nil then Exit;
  try
    DataObj := Root.Values['data'] as TJSONObject;
    if DataObj = nil then Exit;
    Games := DataObj.Values['games'] as TJSONArray;
    if Games = nil then Exit;

    for I := 0 to Games.Count - 1 do begin
      if not (Games.Items[I] is TJSONObject) then Continue;
      GameObj := TJSONObject(Games.Items[I]);
      Title := '';
      IdStr := '';
      V := GameObj.Values['game_title'];
      if V <> nil then Title := V.Value;
      V := GameObj.Values['id'];
      if V <> nil then IdStr := V.Value;
      if (Title <> '') and (IdStr <> '') then begin
        FGameNames.Add(Title);
        FGameURLs.Add(IdStr);
      end;
    end;
    FLastListRequest := Path;
    Result := True;
  finally
    Root.Free;
  end;
end;

function TTheGamesDBDataReader.GetGameData(const Nr: Integer; out Meta: TGameMetadata): Boolean;
var
  Id, Path, Body: String;
  Root, DataObj, GameObj: TJSONObject;
  Games: TJSONArray;
  Genre, Developer, Publisher, Year, Notes: String;
  V: TJSONValue;
begin
  Result := False;
  Meta := nil;
  Genre := '';
  Developer := '';
  Publisher := '';
  Year := '';
  Notes := '';

  if (Nr < 0) or (Nr >= FGameURLs.Count) then Exit;
  Id := FGameURLs[Nr];
  if Id = '' then Exit;
  if APIKey = '' then Exit;

  WaitTGDBRateLimit;

  Path := '/v1/Games/ByGameID?id=' + EncodeName(Id) +
    '&fields=overview,genres,developers,publishers,platform';
  if not APIGet(Path, Body) then Exit;

  Root := TJSONObject.ParseJSONValue(Body) as TJSONObject;
  if Root = nil then Exit;
  try
    DataObj := Root.Values['data'] as TJSONObject;
    if DataObj = nil then Exit;
    Games := DataObj.Values['games'] as TJSONArray;
    if (Games = nil) or (Games.Count = 0) then Exit;
    if not (Games.Items[0] is TJSONObject) then Exit;
    GameObj := TJSONObject(Games.Items[0]);

    V := GameObj.Values['overview'];
    if V <> nil then Notes := V.Value;

    V := GameObj.Values['release_date'];
    if V <> nil then Year := YearFromReleaseDate(V.Value);

    V := GameObj.Values['genres'];
    if V is TJSONArray then begin
      EnsureIdsLoaded('/v1/Genres/ByGenreID','genres',TJSONArray(V),FGenreNames);
      Genre := ResolveIds(TJSONArray(V), FGenreNames);
    end;

    V := GameObj.Values['developers'];
    if V is TJSONArray then begin
      EnsureIdsLoaded('/v1/Developers/ByDeveloperID','developers',TJSONArray(V),FDeveloperNames);
      Developer := ResolveIds(TJSONArray(V), FDeveloperNames);
    end;

    V := GameObj.Values['publishers'];
    if V is TJSONArray then begin
      EnsureIdsLoaded('/v1/Publishers/ByPublisherID','publishers',TJSONArray(V),FPublisherNames);
      Publisher := ResolveIds(TJSONArray(V), FPublisherNames);
    end;

    { ImagePageURL empty until cover phase. }
    Meta := TGameMetadata.Create(Genre, Developer, Publisher, Year, Notes, '');
    Result := True;
  finally
    Root.Free;
  end;
end;

function TTheGamesDBDataReader.GetGameCover(const CoverPageURL: String; var ImageURL: String; const MaxImages: Integer): Boolean;
begin
  { Cover download deferred — metadata-only TGDB API path. }
  ImageURL := '';
  Result := False;
end;

end.
