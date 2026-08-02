unit DataReaderBaseUnit;
interface

uses Classes;

type
  {Create with field values, use once, Free when done.}
  TGameMetadata = class
  public
    Genre : String;
    Developer : String;
    Publisher : String;
    Year : String;
    Notes : String;
    ImagePageURL : String;
    constructor Create(const AGenre, ADeveloper, APublisher, AYear, ANotes, AImagePageURL : String);
  end;

  TDataReader=class
  protected
    FGameNames, FGameURLs : TStringList;
    FLastListRequest : String;
    FLastUpdateCheckOK : Boolean;
    FBrowserURLDOS, FBrowserURLAll, FDataDomain : String;
  public
    Constructor Create;
    Destructor Destroy; override;
    Function LoadConfig(const AConfigFile : String; const UpdateCheck : Boolean) : Boolean; virtual;
    Procedure OpenListPage(const ASearchString : String);
    Function ReadList(const ASearchString : String) : Boolean; virtual; abstract;
    Function GetListURL(const all : Boolean) : String; virtual; abstract;
    {On success Meta is created; caller frees. On failure Meta is nil.}
    Function GetGameData(const Nr : Integer; out Meta : TGameMetadata) : Boolean; virtual; abstract;
    Function GetGameCover(const CoverPageURL : String; var ImageURL : String; const MaxImages : Integer) : Boolean; virtual; abstract;
    property GameNames : TStringList read FGameNames;
    property LastUpdateCheckOK : Boolean read FLastUpdateCheckOK;
    property DataDomain : String read FDataDomain;
  end;

implementation

uses Forms, Windows, SysUtils, ShellAPI, PrgSetupUnit, DataReaderToolsUnit;

constructor TGameMetadata.Create(const AGenre, ADeveloper, APublisher, AYear, ANotes, AImagePageURL : String);
begin
  inherited Create;
  Genre:=AGenre;
  Developer:=ADeveloper;
  Publisher:=APublisher;
  Year:=AYear;
  Notes:=ANotes;
  ImagePageURL:=AImagePageURL;
end;

{ TDataReader }

constructor TDataReader.Create;
begin
  inherited Create;
  FGameNames:=TStringList.Create;
  FGameURLs:=TStringList.Create;
  FLastListRequest:='';
  FLastUpdateCheckOK:=True;

end;

destructor TDataReader.Destroy;
begin
  FGameNames.Free;
  FGameURLs.Free;
  inherited Destroy;
end;

function TDataReader.LoadConfig(const AConfigFile: String; const UpdateCheck: Boolean): Boolean;
begin
  result:=true;
end;

procedure TDataReader.OpenListPage(const ASearchString: String);
Var URL : String;
begin
  If PrgSetup.DataReaderAllPlatforms then URL:=FBrowserURLDOS else URL:=FBrowserURLAll;
  if URL='' then exit;
  ShellExecute(Application.Handle,'open',PChar(Format(URL,[EncodeName(ASearchString)])),nil,nil,SW_SHOW);
end;

end.
