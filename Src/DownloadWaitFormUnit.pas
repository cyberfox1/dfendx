unit DownloadWaitFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Buttons;

type
  TDownloadWaitForm = class(TForm)
    ProgressBar: TProgressBar;
    AbortButton: TButton;
    procedure AbortButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
    FWorkEvent1WorkSize : Int64;
    Procedure ApplyByteProgress(const AWorkCount: Int64);
  public
    { Public-Deklarationen }
    Canceled : Boolean;
  end;

var
  DownloadWaitForm: TDownloadWaitForm = nil;

Procedure InitDownloadWaitForm(const AOwner : TComponent; const MaxPos : Integer);
Function StepDownloadWaitForm(const Pos : Integer) : Boolean;
Procedure DoneDownloadWaitForm;

Type TDownloadResult=(drSuccess, drFail, drCancel);

Function DownloadFileWithDialog(const AOwner : TComponent; const Size : Int64; const AbsBase, URL, Referer, DestFile : String) : TDownloadResult;
Function DownloadFileWithOutDialog(const AOwner : TComponent; const Size : Int64; const AbsBase, URL, Referer, DestFile : String) : TDownloadResult;
Function MetaLinkDownload(const AOwner : TComponent; const ASize : Integer; const AbsBase, MetaLinkURL, Referer, DestFile : String) : TDownloadResult;

implementation

uses XMLDoc, XMLIntf, Math,
     CommonHelpers, CommonTools, VistaToolsUnit, LanguageSetupUnit, PackageDBToolsUnit,
     PrgConsts, PrgSetupUnit, GameDBToolsUnit, GameDBToolsHelpers, HTTPDownloadHelpers;

{$R *.dfm}

{ TDownloadWaitForm }

procedure TDownloadWaitForm.FormCreate(Sender: TObject);
begin
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);

  Canceled:=False;
  FWorkEvent1WorkSize:=0;

  AbortButton.DoubleBuffered:=True;
  AbortButton.Caption:=LanguageSetup.MsgDlgAbort;
end;

procedure TDownloadWaitForm.AbortButtonClick(Sender: TObject);
begin
  Canceled:=True;
  AbortButton.Enabled:=False;
end;

procedure TDownloadWaitForm.ApplyByteProgress(const AWorkCount: Int64);
begin
  { UI only. Cancel is Canceled + helper OnCancelQuery (no Indy Disconnect/Abort). }
  ProgressBar.Position:=AWorkCount;
  If DownloadWaitForm.ProgressBar.Max>1 then begin
    If FWorkEvent1WorkSize>100000000 then begin
      ProgressBar.Position:=AWorkCount div 100000;
      Caption:=LanguageSetup.PackageManagerDownloading+' ['+GetNiceFileSize(AWorkCount)+', '+IntToStr(AWorkCount div 1000 div Int64(ProgressBar.Max))+'%]';
    end else begin
      ProgressBar.Position:=AWorkCount;
      Caption:=LanguageSetup.PackageManagerDownloading+' ['+GetNiceFileSize(AWorkCount)+', '+IntToStr(100*AWorkCount div Int64(ProgressBar.Max))+'%]';
    end;
  end else begin
    Caption:=LanguageSetup.PackageManagerDownloading+' ['+GetNiceFileSize(AWorkCount)+']';
  end;
  Invalidate;
  Paint;
  Application.ProcessMessages;
end;

{ global }

Procedure InitDownloadWaitForm(const AOwner : TComponent; const MaxPos : Integer);
begin
  If not Assigned(DownloadWaitForm) then DownloadWaitForm:=TDownloadWaitForm.Create(AOwner);
  DownloadWaitForm.ProgressBar.Position:=0;
  DownloadWaitForm.ProgressBar.Max:=Max(1,MaxPos);
  DownloadWaitForm.Caption:=LanguageSetup.PackageManagerDownloading;
  DownloadWaitForm.Show;
  DownloadWaitForm.Invalidate;
  DownloadWaitForm.Paint;
  Application.ProcessMessages;
end;

Function StepDownloadWaitForm(const Pos : Integer) : Boolean;
begin
  result:=True;
  If not Assigned(DownloadWaitForm) then exit;
  If DownloadWaitForm.ProgressBar.Max>1 then begin
    DownloadWaitForm.ProgressBar.Position:=Pos;
    DownloadWaitForm.Caption:=LanguageSetup.PackageManagerDownloading+' ['+IntToStr(100*Int64(Pos) div Int64(DownloadWaitForm.ProgressBar.Max))+'%]';
  end;
  DownloadWaitForm.Invalidate;
  DownloadWaitForm.Paint;
  Application.ProcessMessages;
  result:=not DownloadWaitForm.Canceled;
end;

Procedure DoneDownloadWaitForm;
begin
  If Assigned(DownloadWaitForm) then FreeAndNil(DownloadWaitForm);
end;

Type THTTPThread=class(TThread)
  private
    FURL, FReferer, FDestFile : String;
    FSuccess : TDownloadResult;
    FSize : Int64;
    FProgressCurrent, FProgressTotal : Int64;
    Procedure HelperProgress(const Current, Total : Int64; const Msg : String);
    Function HelperCancelQuery : Boolean;
    Procedure ApplyProgress;
  protected
    Procedure Execute; override;
  public
    Constructor Create(const AOwner : TComponent; const AURL, AReferer, ADestFile : String; const ASize : Int64; const ShowWaitDialog : Boolean);
    Destructor Destroy; override;
    property Success : TDownloadResult read FSuccess;
end;

Constructor THTTPThread.Create(const AOwner : TComponent; const AURL, AReferer, ADestFile : String; const ASize : Int64; const ShowWaitDialog : Boolean);
begin
  inherited Create(False);
  FURL:=AURL;
  FReferer:=AReferer;
  FDestFile:=ADestFile;
  FSuccess:=drFail;
  FSize:=ASize;
  If ShowWaitDialog then InitDownloadWaitForm(AOwner,ASize);
end;

Destructor THTTPThread.Destroy;
begin
  DoneDownloadWaitForm;
end;

{Called from the worker thread by THTTPDownloadHelper; marshals the progress
 values to the VCL thread via Synchronize.}
Procedure THTTPThread.HelperProgress(const Current, Total : Int64; const Msg : String);
begin
  FProgressCurrent:=Current;
  FProgressTotal:=Total;
  Synchronize(ApplyProgress);
end;

Procedure THTTPThread.ApplyProgress;
begin
  If not Assigned(DownloadWaitForm) then exit;
  If DownloadWaitForm.ProgressBar.Max=1 then begin
    If FProgressTotal>100000000
      then DownloadWaitForm.ProgressBar.Max:=FProgressTotal div 100000
      else DownloadWaitForm.ProgressBar.Max:=FProgressTotal;
    DownloadWaitForm.FWorkEvent1WorkSize:=FProgressTotal;
  end;
  DownloadWaitForm.ApplyByteProgress(FProgressCurrent);
end;

Function THTTPThread.HelperCancelQuery : Boolean;
begin
  result:=Assigned(DownloadWaitForm) and DownloadWaitForm.Canceled;
end;

Procedure THTTPThread.Execute;
Var Helper : THTTPDownloadHelper;
begin
  Helper:=THTTPDownloadHelper.Create(FURL,FReferer,FDestFile,PrgSetup.HTTPUserAgent,FSize);
  try
    Helper.OnProgress:=HelperProgress;
    Helper.OnCancelQuery:=HelperCancelQuery;
    {TDownloadResult and THTTPDownloadResult share the same members in the same
     order; map by ordinal.}
    FSuccess:=TDownloadResult(Ord(Helper.Execute));
  finally
    Helper.Free;
  end;
end;

Function DownloadSingleFileFromInternet(const AOwner : TComponent; const Size : Int64; const URL, Referer, DestFile : String; const ShowWaitDialog : Boolean) : TDownloadResult;
Var HTTPThread : THTTPThread;
begin
  HTTPThread:=THTTPThread.Create(AOwner,DecodeHTMLSymbols(URL, LanguageSetup.CharsetHTMLTranslate),DecodeHTMLSymbols(Referer, LanguageSetup.CharsetHTMLTranslate),DestFile,Size,ShowWaitDialog);
  try
    While WaitForSingleObject(HTTPThread.Handle,100)<>WAIT_OBJECT_0 do begin
      Application.ProcessMessages;
    end;
    result:=HTTPThread.Success;
  finally
    HTTPThread.Free;
  end;
end;

Procedure MergeFiles(const SourceFiles : TStringList; DestFile : String);
begin
  THTTPDownloadHelper.MergeFiles(SourceFiles,DestFile);
end;

Function DownloadFileFromInternet(const AOwner : TComponent; const Size : Int64; const URL, Referer, DestFile : String; const ShowWaitDialog : Boolean) : TDownloadResult;
Var LoadSize : Int64;
    I,Nr : Integer;
    Files : TStringList;
    S: String;
begin
  If Size<=PackageMaxFileSize then begin
    result:=DownloadSingleFileFromInternet(AOwner,Size,URL,Referer,DestFile,ShowWaitDialog);
    exit;
  end;

  result:=drFail;
  Nr:=0;
  ForceDirectories(TempDir+TempSubFolder);

  Files:=TStringList.Create;
  try
    LoadSize:=Size;

    While LoadSize>0 do begin
      inc(Nr);
      S:=TempDir+TempSubFolder+'\'+ExtractFileName(DestFile)+'.part'+IntToStr(Nr);
      Files.Add(S);
      result:=DownloadFileFromInternet(AOwner,Min(PackageMaxFileSize,LoadSize),URL+'.part'+IntToStr(Nr),Referer,S,ShowWaitDialog);
      if result<>drSuccess then exit;
      LoadSize:=LoadSize-Min(PackageMaxFileSize,LoadSize);
    end;

    MergeFiles(Files,DestFile);

  finally
    For I:=0 to Files.Count-1 do DeleteFile(Files[I]);
    Files.Free;
  end;
end;

Function CopyFileWithDialog(const AOwner : TComponent; const SourceFile, DestinationFile : String) : TDownloadResult;
const BufSize=1024*1224;
Var FSt1, FSt2 : TFileStream;
    Buffer : Pointer;
    C,D : Int64;
    I : Integer;
begin
  result:=drFail;
  GetMem(Buffer,BufSize);
  try
    try FSt1:=TFileStream.Create(SourceFile,fmOpenRead); except exit; end;
    try
      try FSt2:=TFileStream.Create(DestinationFile,fmCreate); except exit; end;
      try
        C:=FSt1.Size; D:=0;
        InitDownloadWaitForm(AOwner,C);
        try
          While C>0 do begin
            I:=Min(C,BufSize);
            FSt1.ReadBuffer(Buffer^,I);
            FSt2.WriteBuffer(Buffer^,I);
            dec(C,I); inc(D,I);
            StepDownloadWaitForm(D);
            If Assigned(DownloadWaitForm) and DownloadWaitForm.Canceled then begin result:=drCancel; exit; end;
          end;
        except
          exit;
        end;
      finally
        DoneDownloadWaitForm;
        FSt2.Free;
      end;
    finally
      FSt1.Free;
    end;
  finally
    FreeMem(Buffer);
  end;
  result:=drSuccess;
end;

Function GetSingleLocalFile(const AOwner : TComponent; const URL, DestFile : String) : TDownloadResult;
Var C : Char;
    I, SaveErrorMode : Integer;
    AlternateURL : String;
begin
  result:=drCancel;
  If (length(URL)<2) or (URL[2]<>':') then exit;

  AlternateURL:=Replace(URL,'%20',' ');

  repeat
    For C:='A' to 'Z' do begin
      I:=GetDriveType(PChar(C+':\'));
      If (I<>DRIVE_REMOVABLE) and (I<>DRIVE_FIXED) and (I<>DRIVE_CDROM) and (I<>DRIVE_RAMDISK) then continue;
      SaveErrorMode:=SetErrorMode(SEM_FAILCRITICALERRORS);
      try
        If FileExists(C+Copy(URL,2,MaxInt)) then begin
          result:=CopyFileWithDialog(AOwner,C+Copy(URL,2,MaxInt),DestFile);
          If result=drSuccess then exit;
        end;
        If FileExists(C+Copy(AlternateURL,2,MaxInt)) then begin
          result:=CopyFileWithDialog(AOwner,C+Copy(AlternateURL,2,MaxInt),DestFile);
          If result=drSuccess then exit;
        end;
      finally
        SetErrorMode(SaveErrorMode);
      end;
    end;
    if MessageDlg(Format(LanguageSetup.PackageManagerMenuUpdateListsLocal,[ExtractFileName(URL)]),mtInformation,[mbOK,mbCancel],0)<>mrOK then exit;
  until False;
end;

Function GetLocalFile(const AOwner : TComponent; const Size : Int64; const URL, DestFile : String) : TDownloadResult;
Var LoadSize : Int64;
    I,Nr : Integer;
    Files : TStringList;
    S: String;
begin
  If Size<=PackageMaxFileSize then begin
    result:=GetSingleLocalFile(AOwner,URL,DestFile);
    exit;
  end;

  result:=drFail;
  Nr:=0;
  ForceDirectories(TempDir+TempSubFolder);

  Files:=TStringList.Create;
  try
    LoadSize:=Size;

    While LoadSize>0 do begin
      inc(Nr);
      S:=TempDir+TempSubFolder+'\'+ExtractFileName(DestFile)+'.part'+IntToStr(Nr);
      Files.Add(S);
      result:=GetSingleLocalFile(AOwner,URL+'.part'+IntToStr(Nr),S);
      if result<>drSuccess then exit;
      LoadSize:=LoadSize-Min(PackageMaxFileSize,LoadSize);
    end;
    MergeFiles(Files,DestFile);

  finally
    For I:=0 to Files.Count-1 do DeleteFile(Files[I]);
    Files.Free;
  end;
end;

Function DownloadFileWithDialog(const AOwner : TComponent; const Size : Int64; const AbsBase, URL, Referer, DestFile : String) : TDownloadResult;
Var S : String;
begin
  If THTTPDownloadHelper.IsInternetURL(URL) or THTTPDownloadHelper.IsInternetURL(AbsBase) then begin
    S:=THTTPDownloadHelper.BuildAbsURL(AbsBase,URL);
    result:=DownloadFileFromInternet(AOwner,Size,S,Referer,DestFile,True);
  end else begin
    S:=MakeAbsPath(URL,IncludeTrailingPathDelimiter(ExtractFilePath(AbsBase)));
    result:=GetLocalFile(AOwner,Size,S,DestFile);
  end;
end;

Function DownloadFileWithOutDialog(const AOwner : TComponent; const Size : Int64; const AbsBase, URL, Referer, DestFile : String) : TDownloadResult;
Var S : String;
begin
  If THTTPDownloadHelper.IsInternetURL(URL) or THTTPDownloadHelper.IsInternetURL(AbsBase) then begin
    S:=THTTPDownloadHelper.BuildAbsURL(AbsBase,URL);
    result:=DownloadFileFromInternet(AOwner,Size,S,Referer,DestFile,False);
  end else begin
    S:=MakeAbsPath(URL,IncludeTrailingPathDelimiter(ExtractFilePath(AbsBase)));
    result:=GetLocalFile(AOwner,Size,S,DestFile);
  end;
end;

Function GetDownloadLinksFromMetaLink(const XMLFileName : String) : TStringList;
Var XML : TXMLDocument;
    N1,N2 : IXMLNode;
    I : Integer;
begin
  result:=TStringList.Create;
  XML:=LoadXMLDoc(XMLFileName); If XML=nil then exit;
  try
    N1:=XML.DocumentElement;
    If N1.NodeName<>'metalink' then exit;

    N2:=nil;
    For I:=0 to N1.ChildNodes.Count-1 do If N1.ChildNodes[I].NodeName='files' then begin N2:=N1.ChildNodes[I]; break; end;
    If N2=nil then exit;

    N1:=nil;
    For I:=0 to N2.ChildNodes.Count-1 do If N2.ChildNodes[I].NodeName='file' then begin N1:=N2.ChildNodes[I]; break; end;
    If N1=nil then exit;

    N2:=nil;
    For I:=0 to N1.ChildNodes.Count-1 do If N1.ChildNodes[I].NodeName='resources' then begin N2:=N1.ChildNodes[I]; break; end;
    If N2=nil then exit;

    For I:=0 to N2.ChildNodes.Count-1 do If N2.ChildNodes[I].NodeName='url' then result.Add(N2.ChildNodes[I].NodeValue);
  finally
    XML.Free;
  end;
end;

Function MetaLinkProcessor(const AOwner : TComponent; const ASize : Integer; const XMLFileName, DestFile : String) : TDownloadResult;
Var St : TStringList;
    I : Integer;
begin
  result:=drFail;
  St:=GetDownloadLinksFromMetaLink(XMLFileName);
  try
    While St.Count>0 do begin
      I:=Random(St.Count);
      result:=DownloadFileWithDialog(AOwner,ASize,'',St[I],'',DestFile);
      if result<>drFail then exit;
      St.Delete(I);
    end;
  finally
    St.Free;
  end;
end;

Function MetaLinkDownload(const AOwner : TComponent; const ASize : Integer; const AbsBase, MetaLinkURL, Referer, DestFile : String) : TDownloadResult;
Var TempXMLFile : String;
begin
  TempXMLFile:=TempDir+PackageDBTempFile;
  result:=DownloadFileWithDialog(AOwner,0,AbsBase,MetaLinkURL,Referer,TempXMLFile);
  If result<>drSuccess then exit;
  try
    result:=MetaLinkProcessor(AOwner,ASize,TempXMLFile,DestFile);
  finally
    ExtDeleteFile(TempXMLFile,ftTemp);
  end;
end;

end.

