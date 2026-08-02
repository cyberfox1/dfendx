unit HTTPDownloadHelpers;

{ Pure, non-VCL HTTP/FTP download logic extracted from DownloadWaitFormUnit.

  THTTPDownloadHelper performs a synchronous download (no TThread, no
  Application.ProcessMessages, no form access). Progress and cancellation are
  surfaced through callbacks so the caller (a VCL form, a console tool, or a
  unit test) decides how to react.

  HTTP/HTTPS uses THTTPClient (Windows SSL). FTP still uses Indy TIdFTP. }

{$H+}

interface

uses
  SysUtils, Classes, Math,
  IdFTP, IdComponent, System.Net.HttpClient, System.Net.URLClient;

type
  THTTPDownloadResult = (drSuccess, drFail, drCancel);

  { Progress: Current = bytes so far, Total = expected/known size (>=1), Msg = label }
  THTTPProgressEvent = procedure(const Current, Total: Int64; const Msg: string) of object;
  { Return True to abort the in-flight transfer. }
  THTTPCancelQuery = function: Boolean of object;

  THTTPDownloadHelper = class
  private
    FURL, FReferer, FDestFile: string;
    FExpectedSize: Int64;
    FOnProgress: THTTPProgressEvent;
    FOnCancelQuery: THTTPCancelQuery;
    FHTTP: THTTPClient;
    FFTP: TIdFTP;
    FWorkSize: Int64;
    FFTPHandled: Boolean;
    procedure DoProgress(const Cur: Int64; const Msg: string);
    function Canceled: Boolean;
    procedure WorkEvent(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    procedure ReceiveDataEvent(const Sender: TObject; AContentLength: Int64;
      AReadCount: Int64; var Abort: Boolean);
    procedure HandleFTP(const Dest: string);
    function FixSourceForge(const MSt: TMemoryStream): Boolean;
    function HTTPGetToStream(const AURL: string; AStream: TStream): Boolean;
  public
    constructor Create(const AURL, AReferer, ADestFile: string; const AExpectedSize: Int64);
    destructor Destroy; override;

    { Synchronous download. Returns drSuccess/drFail/drCancel. }
    function Execute: THTTPDownloadResult;

    property OnProgress: THTTPProgressEvent read FOnProgress write FOnProgress;
    property OnCancelQuery: THTTPCancelQuery read FOnCancelQuery write FOnCancelQuery;

    { --- pure, network-free helpers (the primary FPC-testable surface) --- }
    class function HTTPStatusOK(const StatusCode: Integer): Boolean; static;
    class function SimpleUpper(const S: string): string; static;
    class function IsInternetURL(const URL: string): Boolean; static;
    class function IsFTPURL(const URL: string): Boolean; static;
    class function BuildAbsURL(const AbsBase, URL: string): string; static;
    class function CalcReferer(const URL, Referer: string): string; static;
    class function CheckMagicBytes(const Stream: TStream; const DestFile: string): Boolean; static;
    class function ParseSourceForgeDirectURL(const Html: string): string; static;
    class procedure MergeFiles(const SourceFiles: TStrings; const DestFile: string); static;
    class function SplitFTPHostAndPort(const AHostPort: string; var Host: string; var Port: Integer): Boolean; static;
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
  S: string;
begin
  S := SimpleUpper(URL);
  Result := (Copy(S, 1, 7) = 'HTTP://') or
            (Copy(S, 1, 8) = 'HTTPS://') or
            (Copy(S, 1, 6) = 'FTP://');
end;

class function THTTPDownloadHelper.IsFTPURL(const URL: string): Boolean;
begin
  Result := Copy(SimpleUpper(URL), 1, 6) = 'FTP://';
end;

class function THTTPDownloadHelper.BuildAbsURL(const AbsBase, URL: string): string;
begin
  if not IsInternetURL(URL) then begin
    Result := AbsBase;
    while (Result <> '') and (Result[Length(Result)] <> '/') do
      SetLength(Result, Length(Result) - 1);
    if (URL <> '') and (URL[1] <> '/') then
      Result := Result + URL
    else
      Result := Result + Copy(URL, 2, MaxInt);
  end else begin
    Result := URL;
  end;
end;

class function THTTPDownloadHelper.CalcReferer(const URL, Referer: string): string;
var
  I: Integer;
  S, T: string;
begin
  if SimpleUpper(Referer) = 'AUTOMATIC' then begin
    if Pos('SOURCEFORGE', SimpleUpper(URL)) = 0 then begin
      I := Pos('//', URL);
      if I = 0 then begin
        S := ''; T := URL;
      end else begin
        S := Copy(URL, 1, I + 1);
        T := Copy(URL, I + 2, MaxInt);
      end;
      I := Pos('/', T);
      if I > 0 then T := Copy(T, 1, I);
      Result := S + T;
    end else begin
      Result := '';
    end;
  end else begin
    Result := Referer;
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

class function THTTPDownloadHelper.ParseSourceForgeDirectURL(const Html: string): string;
var
  I, J: Integer;
  S: string;
begin
  { Extract the direct-download URL SourceForge embeds in its interstitial page,
    then unescape &amp; back to &. Returns '' if no link is present. }
  Result := '';
  I := Pos('downloads.sourceforge.net/', Html);
  if I = 0 then exit;

  while (I > 1) and not CharInSet(Html[I - 1], ['"', '''']) do Dec(I);
  J := I;
  while (J <= Length(Html)) and not CharInSet(Html[J], ['"', '''', '>', ' ']) do Inc(J);
  S := Copy(Html, I, J - I);

  I := Pos('&amp;', S);
  while I > 0 do begin
    S := Copy(S, 1, I - 1) + '&' + Copy(S, I + 5, MaxInt);
    I := Pos('&amp;', S);
  end;
  Result := S;
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

{ --- instance / transfer logic ------------------------------------------- }

constructor THTTPDownloadHelper.Create(const AURL, AReferer, ADestFile: string; const AExpectedSize: Int64);
begin
  inherited Create;
  FURL := AURL;
  FReferer := AReferer;
  FDestFile := ADestFile;
  FExpectedSize := AExpectedSize;
  FWorkSize := 0;
  FFTPHandled := False;
  FHTTP := nil;
  FFTP := nil;
end;

destructor THTTPDownloadHelper.Destroy;
begin
  if Assigned(FHTTP) then FHTTP.Free;
  if Assigned(FFTP) then FFTP.Free;
  inherited Destroy;
end;

class function THTTPDownloadHelper.SplitFTPHostAndPort(const AHostPort: string; var Host: string; var Port: Integer): Boolean;
var
  S: string;
  I: Integer;
begin
  S := AHostPort;
  I := Pos(':', S);
  if I > 0 then begin
    Port := StrToIntDef(Copy(S, I + 1, MaxInt), 21);
    Delete(S, I, MaxInt);
  end else
    Port := 21;
  Host := S;
  Result := True;
end;

class function THTTPDownloadHelper.DomainOnly(const S: string): string;
var
  I: Integer;
begin
  Result := S;
  I := Pos('://', Result);
  if I > 0 then
    Result := Copy(Result, I + 3, MaxInt);
  I := Pos('@', Result);
  if I > 0 then
    Delete(Result, 1, I);
  I := Pos('/', Result);
  if I > 0 then
    Result := Copy(Result, 1, I - 1);
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

procedure THTTPDownloadHelper.WorkEvent(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
begin
  DoProgress(AWorkCount, 'Downloading');
  if Canceled then begin
    if Assigned(FFTP) then FFTP.Abort;
  end;
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
  Resp: IHTTPResponse;
begin
  Result := False;
  if not Assigned(FHTTP) then exit;
  Resp := FHTTP.Get(AURL, AStream);
  if (Resp = nil) or (not HTTPStatusOK(Resp.StatusCode)) then begin
    LogInfo('HTTPDownload: HTTP Get bad status url="'+AURL+'" status='+
      IntToStr(IfThen(Resp<>nil, Resp.StatusCode, -1)));
    exit;
  end;
  Result := True;
end;

function THTTPDownloadHelper.FixSourceForge(const MSt: TMemoryStream): Boolean;
var
  S: string;
  Raw: TBytes;
  I: Integer;
begin
  { Read the interstitial page bytes as text, extract the direct URL, re-GET.
    The page is single-byte ASCII; widen byte-by-byte so the read is correct
    under a 2-byte UnicodeString.
    Returns True if no SF link (keep original body) or re-GET succeeded. }
  Result := True;
  MSt.Position := 0;
  SetLength(Raw, MSt.Size);
  if MSt.Size > 0 then MSt.ReadBuffer(Raw[0], MSt.Size);
  SetLength(S, Length(Raw));
  for I := 0 to High(Raw) do
    S[I + 1] := Char(Raw[I]);
  S := ParseSourceForgeDirectURL(S);
  if S = '' then exit;

  MSt.Clear;
  Result := HTTPGetToStream(S, MSt);
end;

procedure THTTPDownloadHelper.HandleFTP(const Dest: string);
var
  MSt: TMemoryStream;
  FSt: TFileStream;
  S, S1: string;
  I: Integer;
  DeletePartialFile: Boolean;
begin
  if not IsFTPURL(Dest) then exit;

  FFTP := TIdFTP.Create(nil);
  try
    S := Copy(Dest, 7, MaxInt);
    I := Pos('/', S);
    if I > 0 then S := Copy(S, 1, I - 1);

    I := Pos('@', S);
    if I > 0 then begin
      S1 := Copy(S, 1, I - 1);
      Delete(S, 1, I);
      I := Pos(':', S1);
      if I > 0 then begin
        FFTP.Username := Copy(S1, 1, I - 1);
        FFTP.Password := Copy(S1, I + 1, MaxInt);
      end else begin
        FFTP.Username := S1;
        FFTP.Password := '';
      end;
    end else begin
      FFTP.Username := 'anonymous';
      FFTP.Password := 'sorry@nomail.com';
    end;

    SplitFTPHostAndPort(S, S, I);
    FFTP.Host := S;
    FFTP.Port := I;
    FFTP.Passive := True;
    FFTP.ConnectTimeout := 10 * 1000;
    FFTP.OnWork := WorkEvent;
    FFTP.Connect;

    S := Copy(Dest, 7, MaxInt);
    I := Pos('/', S);
    if I > 0 then S := Copy(S, I, MaxInt);
    FWorkSize := FFTP.Size(S);

    if FExpectedSize < 1024 * 1024 then begin
      MSt := TMemoryStream.Create;
      try
        try
          FFTP.Get(S, MSt);
        except
          on E: Exception do begin
            LogInfo('HTTPDownload: FTP Get(memory) failed url="'+Dest+'" '+E.ClassName+': '+E.Message);
            exit;
          end;
        end;
        if not CheckMagicBytes(MSt, FDestFile) then exit;
        if Canceled then exit;
        MSt.SaveToFile(FDestFile);
        FFTPHandled := True;
      finally
        MSt.Free;
      end;
    end else begin
      FSt := TFileStream.Create(FDestFile, fmCreate);
      DeletePartialFile := False;
      try
        try
          FFTP.Get(S, FSt);
        except
          on E: Exception do begin
            LogInfo('HTTPDownload: FTP Get(file) failed url="'+Dest+'" '+E.ClassName+': '+E.Message);
            DeletePartialFile := True;
            exit;
          end;
        end;
        if not CheckMagicBytes(FSt, FDestFile) then begin DeletePartialFile := True; exit; end;
        if Canceled then begin DeletePartialFile := True; exit; end;
        FFTPHandled := True;
      finally
        FSt.Free;
        if DeletePartialFile then DeleteFile(FDestFile);
      end;
    end;
  finally
    FFTP.Free;
    FFTP := nil;
  end;
end;

function THTTPDownloadHelper.Execute: THTTPDownloadResult;
var
  MSt: TMemoryStream;
  FSt: TFileStream;
  DeletePartialFile: Boolean;
  Ref: string;
begin
  Result := drFail;
  FFTPHandled := False;
  FWorkSize := FExpectedSize;

  if IsFTPURL(FURL) then begin
    HandleFTP(FURL);
    if FFTPHandled then
      Result := drSuccess
    else if Canceled then
      Result := drCancel;
    exit;
  end;

  FHTTP := THTTPClient.Create;
  try
    FHTTP.UserAgent := 'Mozilla/5.0 (Windows; U; Windows NT 6.0)';
    FHTTP.HandleRedirects := True;
    FHTTP.ConnectionTimeout := 10 * 1000;
    FHTTP.ResponseTimeout := 10 * 1000;
    FHTTP.OnReceiveData := ReceiveDataEvent;
    Ref := CalcReferer(FURL, FReferer);
    if Ref <> '' then
      FHTTP.CustomHeaders['Referer'] := Ref;
    FHTTP.CustomHeaders['Accept-Language'] := 'en';

    if FExpectedSize < 1024 * 1024 then begin
      { Small file - download to memory stream }
      MSt := TMemoryStream.Create;
      try
        try
          if not HTTPGetToStream(FURL, MSt) then exit;
          if (MSt.Size < 30000) and ((FExpectedSize <= 0) or (FExpectedSize <> MSt.Size)) then
            if not FixSourceForge(MSt) then exit;
        except
          on E: Exception do begin
            if not FFTPHandled then begin
              LogInfo('HTTPDownload: HTTP Get(memory) failed url="'+FURL+'" '+E.ClassName+': '+E.Message);
              exit;
            end;
          end;
        end;
        if not FFTPHandled then begin
          if not CheckMagicBytes(MSt, FDestFile) then exit;
          if Canceled then begin Result := drCancel; exit; end;
          MSt.SaveToFile(FDestFile);
        end;
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
          if (FSt.Size < 30000) and ((FExpectedSize <= 0) or (FExpectedSize <> FSt.Size)) then begin
            MSt := TMemoryStream.Create;
            try
              FSt.Position := 0;
              MSt.LoadFromStream(FSt);
              FreeAndNil(FSt); DeleteFile(FDestFile);
              if not FixSourceForge(MSt) then begin
                DeletePartialFile := True; exit;
              end;
              FSt := TFileStream.Create(FDestFile, fmCreate);
              FSt.CopyFrom(MSt, 0);
            finally
              MSt.Free;
            end;
          end;
        except
          on E: Exception do begin
            if not FFTPHandled then begin
              LogInfo('HTTPDownload: HTTP Get/file post-process failed url="'+FURL+'" '+E.ClassName+': '+E.Message);
              DeletePartialFile := True; exit;
            end;
          end;
        end;
        if not FFTPHandled then begin
          if not CheckMagicBytes(FSt, FDestFile) then begin DeletePartialFile := True; exit; end;
          if Canceled then begin Result := drCancel; DeletePartialFile := True; exit; end;
        end;
        Result := drSuccess;
      finally
        FSt.Free;
        if DeletePartialFile then DeleteFile(FDestFile);
      end;
    end;
  finally
    FHTTP.Free;
    FHTTP := nil;
  end;
end;

end.
