unit DataReaderExoDOSUnit;
interface

uses Classes, DataReaderBaseUnit, ExoDOSDBUnit;

Type TExoDOSDataReader=class(TDataReader)
  private
    FDB : TExoDOSDB;
    FGameCache : TStringList;
  public
    Constructor Create;
    Destructor Destroy; override;
    Function ReadList(const ASearchString : String) : Boolean; override;
    Function GetListURL(const all : Boolean) : String; override;
    Function GetGameData(const Nr : Integer; out Meta : TGameMetadata) : Boolean; override;
    Function GetGameCover(const CoverPageURL : String; var ImageURL : String; const MaxImages : Integer) : Boolean; override;
end;

function ExoDOSTitleWithoutYear(const S : String) : String;

implementation

uses SysUtils, Windows, CommonHelpers, PrgSetupUnit, SetupFrameExoDOSUnit, ExoDOSHelpers;

function ExoDOSTitleWithoutYear(const S : String) : String;
Var L : Integer;
begin
  result:=S;
  L:=Length(S);
  if (L>=7) and (S[L]=')') and (S[L-5]='(') and (S[L-6]=' ') and
     (S[L-1] in ['0'..'9']) and (S[L-2] in ['0'..'9']) and (S[L-3] in ['0'..'9']) and (S[L-4] in ['0'..'9']) then
    result:=Copy(S,1,L-7);
end;

{ TExoDOSDataReader }

constructor TExoDOSDataReader.Create;
begin
  inherited Create;
  FDataDomain:='eXoDOS';
  FDB:=nil;
  FGameCache:=nil;
end;

destructor TExoDOSDataReader.Destroy;
begin
  FGameCache.Free;
  FDB.Free;
  inherited Destroy;
end;

function TExoDOSDataReader.ReadList(const ASearchString : String) : Boolean;
Var I : Integer;
    Line, UpperSearch : String;
begin
  FGameNames.Clear;
  FGameURLs.Clear;
  result:=False;

  if FGameCache=nil then begin
    FGameCache:=TStringList.Create;
    if FileExists(ExoDOSGamesList.CachePath) then
      FGameCache.LoadFromFile(ExoDOSGamesList.CachePath);
  end;
  if FDB=nil then
    FDB:=TExoDOSDB.Create(ExoDOSGamesList.DBPath);

  if FGameCache.Count=0 then exit;

  UpperSearch:=ExtUpperCase(ASearchString);
  for I:=0 to FGameCache.Count-1 do begin
    Line:=FGameCache[I];
    if (UpperSearch='') or (Pos(UpperSearch,ExtUpperCase(Line))>0) then begin
      FGameNames.Add(Line);
      FGameURLs.Add(Line);
    end;
  end;

  result:=True;
end;

function TExoDOSDataReader.GetListURL(const all : Boolean) : String;
begin
  result:='';
end;

function TExoDOSDataReader.GetGameData(const Nr : Integer; out Meta : TGameMetadata) : Boolean;
Var Title, DataBlob, Year : String;
begin
  result:=False;
  Meta:=nil;
  if (Nr<0) or (Nr>=FGameNames.Count) or (FDB=nil) then exit;

  Title:=ExoDOSTitleWithoutYear(FGameNames[Nr]);
  if not GetGameDataByName(FDB,Title,Year,DataBlob) then exit;
  Meta:=TGameMetadata.Create(
    ParseDataBlobValue(DataBlob,'Genre'),
    ParseDataBlobValue(DataBlob,'Developer'),
    ParseDataBlobValue(DataBlob,'Publisher'),
    Year,
    ParseDataBlobValue(DataBlob,'Notes'),
    '');
  result:=True;
end;

function TExoDOSDataReader.GetGameCover(const CoverPageURL : String; var ImageURL : String; const MaxImages : Integer) : Boolean;
begin
  ImageURL:='';
  result:=True;
end;

end.
