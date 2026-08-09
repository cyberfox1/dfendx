unit DataReaderThreadsUnit;
interface

{ Shared data-reader worker threads for InternetDataWaitForm.
  Copied from DataReaderMobyUnit; TMobyDataReader scraper removed. }

uses Classes, DataReaderBaseUnit;

Type TDataReaderThread=class(TThread)
  protected
    FDataReader : TDataReader;
    FSuccess : Boolean;
  public
    Constructor Create(const ADataReader : TDataReader);
    property Success : Boolean read FSuccess;
end;

Type TDataReaderLoadConfigThread=class(TDataReaderThread)
  private
    FForceUpdate : Boolean;
  protected
    Procedure Execute; override;
  public
    Constructor Create(const ADataReader : TDataReader; const AForceUpdate : Boolean);
end;

Type TDataReaderGameListThread=class(TDataReaderThread)
  private
    FName : String;
  protected
    Procedure Execute; override;
  public
    Constructor Create(const ADataReader : TDataReader; const AName : String);
end;

Type TDataReaderGameDataThread=class(TDataReaderThread)
  private
    FNr : Integer;
    FFullImages : Boolean;
    FMeta : TGameMetadata;
  protected
    Procedure Execute; override;
  public
    Constructor Create(const ADataReader : TDataReader; const ANr : Integer; const AFullImages : Boolean);
    property Meta : TGameMetadata read FMeta;
  end;

Type TDataReaderGameCoverThread=class(TDataReaderThread)
  private
    FDownloadURLs : TStringList;
    FDestFolder : String;
  protected
    Procedure Execute; override;
  public
    Constructor Create(const ADataReader : TDataReader; const ADownloadURL, ADestFolder : String); overload;
    Constructor Create(const ADataReader : TDataReader; const ADownloadURLs : TStringList; const ADestFolder : String); overload;
    Destructor Destroy; override;
end;

implementation

uses Windows, SysUtils, ActiveX, CommonTools, DataReaderToolsUnit,
     PrgConsts, PrgSetupUnit, LoggingUnit;

{ TDataReaderThread }

constructor TDataReaderThread.Create(const ADataReader: TDataReader);
begin
  FDataReader:=ADataReader;
  FSuccess:=False;
  inherited Create(False);
end;

{ TDataReaderLoadConfigThread }

constructor TDataReaderLoadConfigThread.Create(const ADataReader: TDataReader; const AForceUpdate : Boolean);
begin
  FForceUpdate:=AForceUpdate;
  inherited Create(ADataReader);
end;

procedure TDataReaderLoadConfigThread.Execute;
Var DoUpdateCheck : Boolean;
    ConfigPath : String;
begin
  CoInitialize(nil);
  If FForceUpdate then begin
    DoUpdateCheck:=True;
  end else begin
    DoUpdateCheck:=False;
    Case PrgSetup.DataReaderCheckForUpdates of
      0 : DoUpdateCheck:=False;
      1 : DoUpdateCheck:=(Round(Int(Date))>=PrgSetup.LastDataReaderUpdateCheck+7);
      2 : DoUpdateCheck:=(Round(Int(Date))>=PrgSetup.LastDataReaderUpdateCheck+1);
      3 : DoUpdateCheck:=True;
    end;
  end;
  ConfigPath:=PrgDataDir+SettingsFolder+'\'+DataReaderConfigFile;
  {Remote updates disabled: always UpdateCheck=false. Success = LoadConfig result.}
  FSuccess:=FDataReader.LoadConfig(ConfigPath,false);
  if not FSuccess then begin
    LogInfo('DataReader.LoadConfigThread: LoadConfig failed path='+ConfigPath);
    FSuccess:=FDataReader.LoadConfig(ConfigPath,false);
    if not FSuccess then
      LogInfo('DataReader.LoadConfigThread: retry LoadConfig failed path='+ConfigPath);
  end;
  If DoUpdateCheck and FSuccess then PrgSetup.LastDataReaderUpdateCheck:=Round(Int(Date));
end;

{ TDataReaderGameListThread }

constructor TDataReaderGameListThread.Create(const ADataReader: TDataReader; const AName: String);
begin
  FName:=AName;
  inherited Create(ADataReader);
end;

procedure TDataReaderGameListThread.Execute;
begin
  FSuccess:=FDataReader.ReadList(FName);
end;

{ TDataReaderGameDataThread }

constructor TDataReaderGameDataThread.Create(const ADataReader: TDataReader; const ANr: Integer; const AFullImages : Boolean);
begin
  FNr:=ANr;
  FFullImages:=AFullImages;
  FMeta:=nil;
  inherited Create(ADataReader);
end;

procedure TDataReaderGameDataThread.Execute;
Var S, ImageURL : String;
    MaxImageCount : Integer;
begin
  FSuccess:=FDataReader.GetGameData(FNr,FMeta);
  if not FSuccess then exit;
  S:=FMeta.ImagePageURL;
  if FFullImages then MaxImageCount:=PrgSetup.DataReaderMaxImages else MaxImageCount:=1;
  ImageURL:='';
  if FDataReader.GetGameCover(S,ImageURL,MaxImageCount) then
    FMeta.ImagePageURL:=ImageURL;
end;

{ TDataReaderGameCoverThread }

constructor TDataReaderGameCoverThread.Create(const ADataReader: TDataReader; const ADownloadURL, ADestFolder: String);
begin
  FDownloadURLs:=TStringList.Create;
  FDownloadURLs.Add(ADownloadURL);
  FDestFolder:=ADestFolder;
  inherited Create(ADataReader);
end;

constructor TDataReaderGameCoverThread.Create(const ADataReader: TDataReader; const ADownloadURLs: TStringList; const ADestFolder: String);
begin
  FDownloadURLs:=TStringList.Create;
  FDownloadURLs.AddStrings(ADownloadURLs);
  FDestFolder:=ADestFolder;
  inherited Create(ADataReader);
end;

destructor TDataReaderGameCoverThread.Destroy;
begin
  FDownloadURLs.Free;
  inherited Destroy;
end;

procedure TDataReaderGameCoverThread.Execute;
Var FileName,Path,S : String;
    I,J : Integer;
begin
  FSuccess:=True;

  For J:=0 to FDownloadURLs.Count-1 do begin
    FileName:=FDownloadURLs[J];

    I:=Pos('/',FileName); While I>0 do begin FileName:=Copy(FileName,I+1,MaxInt); I:=Pos('/',FileName); end;
    Path:=IncludeTrailingPathDelimiter(FDestFolder);
    If FileExists(Path+FileName) then continue;

    I:=Pos('/covers/small/',FDownloadURLs[J]);
    if (I<>0) then begin
      S:=Copy(FDownloadURLs[J],1,I-1)+'/covers/large/'+copy(FDownloadURLs[J],I+length('/covers/small/'),MaxInt);
      If DownloadFileToDisk(S,Path+FileName) then continue;
    end;

    If not DownloadFileToDisk(FDownloadURLs[J],Path+FileName) then FSuccess:=False;
  end;
end;

end.
