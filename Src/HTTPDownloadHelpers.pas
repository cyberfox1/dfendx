unit HTTPDownloadHelpers;

{ Pure, non-VCL HTTP helpers.

  Core document/API fetch: HTTPRequestToStream / HTTPRequestToString /
  HTTPRequestToStringStream — the only place that creates THTTPClient for
  non-file-download GETs (and used by file Execute for the actual Get).

  THTTPDownloadHelper.Execute: file download + magic bytes + progress.
  ftp:// is refused (no FTP stack). }

{$H+}

interface

uses
  SysUtils, Classes, Math,
  System.Net.HttpClient, System.Net.URLClient;

type
  THTTPDownloadResult = (drSuccess, drFail, drCancel);

  { Progress: Current = bytes so far, Total = expected/known size (>=1), Msg = label }
  THTTPProgressEvent = procedure(const Current, Total: Int64; const Msg: string) of object;
  { Return True to abort the in-flight transfer. }
  THTTPCancelQuery = function: Boolean of object;

  THTTPDownloadHelper = class
  private
    FURL, FReferer, FDestFile, FUserAgent: string;
    FExpectedSize: Int64;
    FOnProgress: THTTPProgressEvent;
    FOnCancelQuery: THTTPCancelQuery;
    FWorkSize: Int64;
    procedure DoProgress(const Cur: Int64; const Msg: string);
    function Canceled: Boolean;
    procedure ReceiveDataEvent(const Sender: TObject; AContentLength: Int64;
      AReadCount: Int64; var Abort: Boolean);
    function HTTPGetToStream(const AURL: string; AStream: TStream): Boolean;
  public
    constructor Create(const AURL, AReferer, ADestFile, AUserAgent: string; const AExpectedSize: Int64);
    destructor Destroy; override;

    { Synchronous file download. Returns drSuccess/drFail/drCancel. }
    function Execute: THTTPDownloadResult;

    property OnProgress: THTTPProgressEvent read FOnProgress write FOnProgress;
    property OnCancelQuery: THTTPCancelQuery read FOnCancelQuery write FOnCancelQuery;

    { --- core HTTP (only THTTPClient.Get for document/API/fetch paths) --- }
    class function BuildRequestURL(const URL: string; QueryArgs: TStrings): string; static;
    class function HTTPRequestToStream(
      const Method, URL: string;
      QueryArgs: TStrings;
      const UserAgent, Referer: string;
      ConnectionTimeoutMS, ResponseTimeoutMS: Integer;
      ResponseStream: TStream;
      out StatusCode: Integer;
      AOnReceiveData: TReceiveDataEvent = nil
    ): Boolean; static;
    class function HTTPRequestToString(
      const Method, URL: string;
      QueryArgs: TStrings;
      const UserAgent, Referer: string;
      ConnectionTimeoutMS, ResponseTimeoutMS: Integer;
      out Body: string;
      out StatusCode: Integer
    ): Boolean; static;
    class function HTTPRequestToStringStream(
      const Method, URL: string;
      QueryArgs: TStrings;
      const UserAgent, Referer: string;
      ConnectionTimeoutMS, ResponseTimeoutMS: Integer;
      out StatusCode: Integer
    ): TStringStream; static;

    { --- pure, network-free helpers (the primary FPC-testable surface) --- }
    class function HTTPStatusOK(const StatusCode: Integer): Boolean; static;
    class function SimpleUpper(const S: string): string; static;
    class function IsInternetURL(const URL: string): Boolean; static;
    class function IsFTPURL(const URL: string): Boolean; static;
    class function BuildAbsURL(const AbsBase, URL: string): string; static;
    class function CalcReferer(const URL, Referer: string): string; static;
    class function CheckMagicBytes(const Stream: TStream; const DestFile: string): Boolean; static;
    class procedure MergeFiles(const SourceFiles: TStrings; const DestFile: string); static;
    class function DomainOnly(const S: string): string; static;
  end;

implementation

uses LoggingUnit;

{ --- pure helpers --------------------------------------------------------- }

class function THTTPDownloadHelper.HTTPStatusOK(const StatusCode: Integer): Boolean;
begin
  Result := (StatusCode >= 200) and (StatusCode <= 299);
end;

class function THTTPDownloadHelper.SimpleUpper(const S: string): string;
begin
  { ASCII upcasing is all the URL-scheme comparisons need; avoid the
    VCL-tainted ExtUpperCase from CommonHelpers. }
  Result := UpperCase(Trim(S));
end;

class function THTTPDownloadHelper.IsInternetURL(const URL: string): Boolean;
var
  URI: TURI;
  Sch: string;
begin
  Result := False;
  if Trim(URL) = '' then Exit;
  try
    URI := TURI.Create(URL);
    Sch := SimpleUpper(URI.Scheme);
    Result := (Sch = 'HTTP') or (Sch = 'HTTPS') or (Sch = 'FTP');
  except
    Result := False;
  end;
end;

class function THTTPDownloadHelper.IsFTPURL(const URL: string): Boolean;
var
  URI: TURI;
begin
  Result := False;
  if Trim(URL) = '' then Exit;
  try
    URI := TURI.Create(URL);
    Result := SimpleUpper(URI.Scheme) = 'FTP';
  except
    Result := False;
  end;
end;

class function THTTPDownloadHelper.BuildAbsURL(const AbsBase, URL: string): string;
var
  Base: TURI;
  Path: string;
  I: Integer;
  Sch: string;
begin
  { Absolute network URL → done. Relative http(s) resolve against AbsBase only. }
  if IsInternetURL(URL) then begin
    Result := URL;
    Exit;
  end;

  try
    Base := TURI.Create(AbsBase);
    Sch := SimpleUpper(Base.Scheme);
    if (Base.Scheme = '') or ((Sch <> 'HTTP') and (Sch <> 'HTTPS')) then begin
      Result := URL;
      Exit;
    end;

    Base.Query := '';  { relative file next to list, not list query }

    { Resolve relative URL against AbsBase (package list base + entry path).
      - URL starts with '/': same host, path is absolute from site root
        e.g. base https://h/a/list.xml + /x.zip → https://h/x.zip
      - otherwise: drop the last path segment of the base (the list file name),
        keep the directory, append the relative name
        e.g. base https://h/a/list.xml + x.zip → https://h/a/x.zip
      Then Base.ToString rebuilds scheme/host/port/path. }
    if (URL <> '') and (URL[1] = '/') then
      Base.Path := URL
    else begin
      Path := Base.Path;
      if Path = '' then
        Path := '/';
      I := Length(Path);
      while (I > 1) and (Path[I] <> '/') do
        Dec(I);
      SetLength(Path, I);  { keeps trailing '/' }
      if Path = '' then
        Path := '/';
      if Path[Length(Path)] <> '/' then
        Path := Path + '/';
      Base.Path := Path + URL;
    end;

    Result := Base.ToString;
  except
    Result := URL;
  end;
end;

class function THTTPDownloadHelper.CalcReferer(const URL, Referer: string): string;
var
  URI: TURI;
begin
  if SimpleUpper(Referer) <> 'AUTOMATIC' then begin
    Result := Referer;
    Exit;
  end;
  try
    URI := TURI.Create(URL);
    if URI.Scheme = '' then begin
      Result := '';
      Exit;
    end;
    { Host origin: keep "/" only if the original URL had a path. }
    if URI.Path = '' then
      { no path }
    else
      URI.Path := '/';
    URI.Query := '';
    Result := URI.ToString;
  except
    Result := '';
  end;
end;

class function THTTPDownloadHelper.CheckMagicBytes(const Stream: TStream; const DestFile: string): Boolean;
type
  TMagic = array[0..1] of AnsiChar;
var
  Ext: string;
  MSt: TMemoryStream;
  FSt: TFileStream;
  C: array[0..1] of AnsiChar;
  SavePos: Int64;
begin
  { Only .ZIP and .EXE are sanity-checked; anything else passes through.
    Uses AnsiChar so the comparison is byte-exact under Unicode (fixes the
    Char-based bug in the original SimpleFileCheck). }
  Result := True;
  Ext := Trim(UpperCase(ExtractFileExt(DestFile)));
  if (Ext <> '.ZIP') and (Ext <> '.EXE') then exit;

  if Stream is TMemoryStream then begin
    MSt := TMemoryStream(Stream);
    if MSt.Size < 2 then begin Result := False; exit; end;
    if Ext = '.ZIP' then
      Result := (TMagic(MSt.Memory^)[0] = 'P') and (TMagic(MSt.Memory^)[1] = 'K');
    if Ext = '.EXE' then
      Result := (TMagic(MSt.Memory^)[0] = 'M') and (TMagic(MSt.Memory^)[1] = 'Z');
    exit;
  end;

  if Stream is TFileStream then begin
    FSt := TFileStream(Stream);
    if FSt.Size < 2 then begin Result := False; exit; end;
    SavePos := FSt.Position;
    FSt.Position := 0;
    try
      FSt.ReadBuffer(C, 2);
    finally
      FSt.Position := SavePos;
    end;
    if Ext = '.ZIP' then
      Result := (C[0] = 'P') and (C[1] = 'K');
    if Ext = '.EXE' then
      Result := (C[0] = 'M') and (C[1] = 'Z');
  end;
end;

class procedure THTTPDownloadHelper.MergeFiles(const SourceFiles: TStrings; const DestFile: string);
var
  Input, Output: TFileStream;
  I: Integer;
begin
  Output := TFileStream.Create(DestFile, fmCreate);
  try
    for I := 0 to SourceFiles.Count - 1 do begin
      Input := TFileStream.Create(SourceFiles[I], fmOpenRead);
      try
        Output.CopyFrom(Input, 0);
      finally
        Input.Free;
      end;
    end;
  finally
    Output.Free;
  end;
end;

{ --- core HTTP request ---------------------------------------------------- }

class function THTTPDownloadHelper.BuildRequestURL(const URL: string; QueryArgs: TStrings): string;
var
  URI: TURI;
  I: Integer;
  N, V: string;
begin
  { Delphi TURI builds path/query; AddParameter URL-encodes values (do not double-encode). }
  if (QueryArgs = nil) or (QueryArgs.Count = 0) then begin
    Result := URL;
    Exit;
  end;
  URI := TURI.Create(URL);
  for I := 0 to QueryArgs.Count - 1 do begin
    N := QueryArgs.Names[I];
    if N <> '' then begin
      V := QueryArgs.ValueFromIndex[I];
      URI.AddParameter(N, V);
    end;
  end;
  Result := URI.ToString;
end;

class function THTTPDownloadHelper.HTTPRequestToStream(
  const Method, URL: string;
  QueryArgs: TStrings;
  const UserAgent, Referer: string;
  ConnectionTimeoutMS, ResponseTimeoutMS: Integer;
  ResponseStream: TStream;
  out StatusCode: Integer;
  AOnReceiveData: TReceiveDataEvent
): Boolean;
var
  HTTP: THTTPClient;
  Resp: IHTTPResponse;
  FinalURL, M: string;
begin
  Result := False;
  StatusCode := -1;
  if ResponseStream = nil then Exit;
  FinalURL := BuildRequestURL(URL, QueryArgs);
  M := SimpleUpper(Method);
  if M = '' then M := 'GET';
  if M <> 'GET' then begin
    LogInfo('HTTPRequest: unsupported method="'+Method+'" url="'+FinalURL+'"');
    Exit;
  end;

  HTTP := THTTPClient.Create;
  try
    HTTP.UserAgent := UserAgent;
    HTTP.HandleRedirects := True;
    HTTP.ConnectionTimeout := ConnectionTimeoutMS;
    HTTP.ResponseTimeout := ResponseTimeoutMS;
    if Assigned(AOnReceiveData) then
      HTTP.OnReceiveData := AOnReceiveData;
    if Trim(Referer) <> '' then
      HTTP.CustomHeaders['Referer'] := Referer;
    HTTP.CustomHeaders['Accept-Language'] := 'en';
    LogInfo('HTTPRequest: User-Agent="'+UserAgent+'" method='+M+' url="'+FinalURL+'"');
    try
      Resp := HTTP.Get(FinalURL, ResponseStream);
      if Resp <> nil then StatusCode := Resp.StatusCode else StatusCode := -1;
      if not HTTPStatusOK(StatusCode) then begin
        LogInfo('HTTPRequest: bad status url="'+FinalURL+'" status='+IntToStr(StatusCode));
        Exit;
      end;
      ResponseStream.Position := 0;
      Result := True;
    except
      on E: Exception do begin
        LogInfo('HTTPRequest: exception url="'+FinalURL+'" '+E.ClassName+': '+E.Message);
        StatusCode := -1;
        Result := False;
      end;
    end;
  finally
    HTTP.Free;
  end;
end;

class function THTTPDownloadHelper.HTTPRequestToString(
  const Method, URL: string;
  QueryArgs: TStrings;
  const UserAgent, Referer: string;
  ConnectionTimeoutMS, ResponseTimeoutMS: Integer;
  out Body: string;
  out StatusCode: Integer
): Boolean;
var
  SS: TStringStream;
begin
  Body := '';
  SS := HTTPRequestToStringStream(Method, URL, QueryArgs, UserAgent, Referer,
    ConnectionTimeoutMS, ResponseTimeoutMS, StatusCode);
  Result := SS <> nil;
  if not Result then Exit;
  try
    Body := SS.DataString;
  finally
    SS.Free;
  end;
end;

class function THTTPDownloadHelper.HTTPRequestToStringStream(
  const Method, URL: string;
  QueryArgs: TStrings;
  const UserAgent, Referer: string;
  ConnectionTimeoutMS, ResponseTimeoutMS: Integer;
  out StatusCode: Integer
): TStringStream;
begin
  Result := TStringStream.Create('');
  try
    if not HTTPRequestToStream(Method, URL, QueryArgs, UserAgent, Referer,
      ConnectionTimeoutMS, ResponseTimeoutMS, Result, StatusCode, nil) then
      FreeAndNil(Result);
  except
    FreeAndNil(Result);
    StatusCode := -1;
  end;
end;

{ --- instance / transfer logic ------------------------------------------- }

constructor THTTPDownloadHelper.Create(const AURL, AReferer, ADestFile, AUserAgent: string; const AExpectedSize: Int64);
begin
  inherited Create;
  FURL := AURL;
  FReferer := AReferer;
  FDestFile := ADestFile;
  FUserAgent := AUserAgent;
  FExpectedSize := AExpectedSize;
  FWorkSize := 0;
end;

destructor THTTPDownloadHelper.Destroy;
begin
  inherited Destroy;
end;

class function THTTPDownloadHelper.DomainOnly(const S: string): string;
var
  URI: TURI;
  Sch: string;
  DefaultPort: Integer;
begin
  Result := '';
  if Trim(S) = '' then Exit;
  try
    URI := TURI.Create(S);
    if URI.Host = '' then
      URI := TURI.Create('http://' + S);
    Result := URI.Host;
    if Result = '' then Exit;
    Sch := SimpleUpper(URI.Scheme);
    if Sch = 'HTTPS' then DefaultPort := 443
    else if Sch = 'HTTP' then DefaultPort := 80
    else if Sch = 'FTP' then DefaultPort := 21
    else DefaultPort := 0;
    if (URI.Port > 0) and ((DefaultPort = 0) or (URI.Port <> DefaultPort)) then
      Result := Result + ':' + IntToStr(URI.Port);
  except
    Result := '';
  end;
end;

procedure THTTPDownloadHelper.DoProgress(const Cur: Int64; const Msg: string);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Cur, Max(Int64(1), FWorkSize), Msg);
end;

function THTTPDownloadHelper.Canceled: Boolean;
begin
  Result := Assigned(FOnCancelQuery) and FOnCancelQuery;
end;

procedure THTTPDownloadHelper.ReceiveDataEvent(const Sender: TObject; AContentLength: Int64;
  AReadCount: Int64; var Abort: Boolean);
begin
  if AContentLength > 0 then
    FWorkSize := Max(Int64(1), AContentLength);
  DoProgress(AReadCount, 'Downloading');
  Abort := Canceled;
end;

function THTTPDownloadHelper.HTTPGetToStream(const AURL: string; AStream: TStream): Boolean;
var
  Status: Integer;
  Ref: string;
begin
  Ref := CalcReferer(AURL, FReferer);
  Result := HTTPRequestToStream('GET', AURL, nil, FUserAgent, Ref,
    10 * 1000, 10 * 1000, AStream, Status, ReceiveDataEvent);
end;

function THTTPDownloadHelper.Execute: THTTPDownloadResult;
var
  MSt: TMemoryStream;
  FSt: TFileStream;
  DeletePartialFile: Boolean;
begin
  Result := drFail;
  FWorkSize := FExpectedSize;

  if IsFTPURL(FURL) then begin
    LogInfo('HTTPDownload: FTP not supported url="'+FURL+'"');
    exit;
  end;

  if FExpectedSize < 1024 * 1024 then begin
    { Small file - download to memory stream }
    MSt := TMemoryStream.Create;
    try
      try
        if not HTTPGetToStream(FURL, MSt) then exit;
      except
        on E: Exception do begin
          LogInfo('HTTPDownload: HTTP Get(memory) failed url="'+FURL+'" '+E.ClassName+': '+E.Message);
          exit;
        end;
      end;
      if not CheckMagicBytes(MSt, FDestFile) then exit;
      if Canceled then begin Result := drCancel; exit; end;
      MSt.SaveToFile(FDestFile);
      Result := drSuccess;
    finally
      MSt.Free;
    end;
  end else begin
    { Large file - download to file }
    FSt := TFileStream.Create(FDestFile, fmCreate);
    DeletePartialFile := False;
    try
      try
        try
          if not HTTPGetToStream(FURL, FSt) then begin
            DeletePartialFile := True; exit;
          end;
        except
          on E: Exception do begin
            LogInfo('HTTPDownload: HTTP Get(file) failed url="'+FURL+'" '+E.ClassName+': '+E.Message);
            DeletePartialFile := True; Result := drFail; exit;
          end;
        end;
      except
        on E: Exception do begin
          LogInfo('HTTPDownload: HTTP Get/file post-process failed url="'+FURL+'" '+E.ClassName+': '+E.Message);
          DeletePartialFile := True; exit;
        end;
      end;
      if not CheckMagicBytes(FSt, FDestFile) then begin DeletePartialFile := True; exit; end;
      if Canceled then begin Result := drCancel; DeletePartialFile := True; exit; end;
      Result := drSuccess;
    finally
      FSt.Free;
      if DeletePartialFile then DeleteFile(FDestFile);
    end;
  end;
end;

end.
