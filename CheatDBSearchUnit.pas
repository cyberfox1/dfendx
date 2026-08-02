unit CheatDBSearchUnit;
interface

uses Classes, CheatDBHelpers;

Type TAddressSearcher=class(TMemorySearchBase)
  private
    FLastSavedGameFileName, FName : String;
    FSearchDataFileName : String;
  public
    Constructor Create;
    Destructor Destroy; override;
    Procedure Clear(const AKeepName : Boolean);
    Function LoadFromFile(const AFileName : String) : Boolean;
    Procedure SaveToFile(const AFileName : String);
    Function LoadSavedGameFile(const ASavedGameFile : String) : Boolean;
    Procedure SearchAddress(const ASavedGameFile : String; const AValue : Integer);
    Procedure SearchAddressIndirect(const ASavedGameFile : String; const AValueChangeType : TValueChangeType);
    Function NoResults : Boolean;
    Function GetResultNr(const ANr : Integer; var AAddress, ASize : Integer) : Boolean;
    Function GetList : TStringList;
    property Name : String read FName write FName;
    property LastSavedGameFileName : String read FLastSavedGameFileName write FLastSavedGameFileName;
    property SearchDataFileName : String read FSearchDataFileName;
end;

Procedure GetAddressSearchFiles(const AFiles, ANames : TStringList);
Function GetNewAddressSearchFile : String;
Function SearchFileOK(const AFileName : String; var AName : String) : Boolean;

implementation

uses SysUtils, Math, PrgSetupUnit, PrgConsts, LanguageSetupUnit;

const DFRSearch: AnsiString = 'DFRAddressSearchFile';

{On-disk strings are byte-oriented: length prefix + that many Ansi bytes.
 Stream via AnsiString so Delphi UnicodeString is not half-written.}

Function SearchFileOK(const AFileName : String; var AName : String) : Boolean;
Var FSt : TFileStream;
    S : AnsiString;
    I : Integer;
begin
  result:=False;
  try
    FSt:=TFileStream.Create(AFileName,fmOpenRead);
    try
      If FSt.Size<length(DFRSearch)+4 then exit;
      SetLength(S,length(DFRSearch));
      FSt.ReadBuffer(S[1],length(DFRSearch));
      result:=(S=DFRSearch);
      If result then begin
        FSt.ReadBuffer(I,4);
        SetLength(S,I);
        If I>0 then FSt.ReadBuffer(S[1],I);
        AName:=String(S);
      end;
    finally
      FSt.Free;
    end;
  except
    result:=False; exit;
  end;
end;

Procedure GetAddressSearchFiles(const AFiles, ANames : TStringList);
Var I : Integer;
    Rec : TSearchRec;
    S : String;
begin
  I:=FindFirst(PrgDataDir+CheatDBSearchSubFolder+'\*.dat',faAnyFile,Rec);
  try
    While I=0 do begin
      If SearchFileOK(PrgDataDir+CheatDBSearchSubFolder+'\'+Rec.Name,S) then begin
        AFiles.Add(PrgDataDir+CheatDBSearchSubFolder+'\'+Rec.Name);
        ANames.Add(S);
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

Function GetNewAddressSearchFile : String;
Var I : Integer;
begin
  I:=0;
  While FileExists(PrgDataDir+CheatDBSearchSubFolder+'\Search'+IntToStr(I)+'.dat') do inc(I);
  result:=PrgDataDir+CheatDBSearchSubFolder+'\Search'+IntToStr(I)+'.dat';
end;

{ TAddressSearcher }

constructor TAddressSearcher.Create;
begin
  inherited Create;
  FName:='';
  FLastSavedGameFileName:='';
  FCompleteFile:=nil;
  FAddressList:=nil;
  FAddressSizeList:=nil;
  FAddressLastValue:=nil;
  FSearchDataFileName:='';
end;

destructor TAddressSearcher.Destroy;
begin
  Clear(False);
  inherited Destroy;
end;

procedure TAddressSearcher.Clear(const AKeepName : Boolean);
begin
  If Assigned(FCompleteFile) then FreeAndNil(FCompleteFile);
  If Assigned(FAddressList) then FreeAndNil(FAddressList);
  If Assigned(FAddressSizeList) then FreeAndNil(FAddressSizeList);
  If Assigned(FAddressLastValue) then FreeAndNil(FAddressLastValue);
  If not AKeepName then begin FName:=''; FLastSavedGameFileName:=''; end;
end;

function TAddressSearcher.LoadFromFile(const AFileName: String): Boolean;
Var FSt : TFileStream;
    S : AnsiString;
    I,J,K : Integer;
    Mode : Byte;
begin
  result:=False;
  Clear(False);
  FSearchDataFileName:=AFileName;

  try
    FSt:=TFileStream.Create(AFileName,fmOpenRead);
    try
      If FSt.Size<length(DFRSearch)+5 then exit;
      SetLength(S,length(DFRSearch));
      FSt.ReadBuffer(S[1],length(DFRSearch));
      If S<>DFRSearch then exit;
      FSt.ReadBuffer(I,4); SetLength(S,I); If I>0 then FSt.ReadBuffer(S[1],I); FName:=String(S);
      FSt.ReadBuffer(I,4); SetLength(S,I); If I>0 then FSt.ReadBuffer(S[1],I); FLastSavedGameFileName:=String(S);
      FSt.ReadBuffer(Mode,1);
      If Mode=0 then begin
        {Whole saved game stored}
        FCompleteFile:=TMemoryStream.Create;
        FCompleteFile.CopyFrom(FSt,FSt.Size-FSt.Position);
      end else begin
        {Load address list}
        FAddressList:=TList.Create;
        FAddressSizeList:=TList.Create;
        FAddressLastValue:=TList.Create;
        FSt.ReadBuffer(I,4);
        FAddressList.Capacity:=Max(FAddressList.Capacity,I);
        FAddressSizeList.Capacity:=Max(FAddressSizeList.Capacity,I);
        FAddressLastValue.Capacity:=Max(FAddressLastValue.Capacity,I);
        For J:=0 to I-1 do begin FSt.ReadBuffer(K,4); FAddressList.Add(Pointer(K)); end;
        For J:=0 to I-1 do begin FSt.ReadBuffer(K,4); FAddressSizeList.Add(Pointer(K)); end;
        For J:=0 to I-1 do begin FSt.ReadBuffer(K,4); FAddressLastValue.Add(Pointer(K)); end;
      end;
    finally
      FSt.Free;
    end;
  except
    result:=False; exit;
  end;
  result:=True;
end;

procedure TAddressSearcher.SaveToFile(const AFileName: String);
Var FSt : TFileStream;
    S : AnsiString;
    I,J : Integer;
    Mode : Byte;
begin
  try
    If Trim(AFileName)='' then begin
      If Trim(FSearchDataFileName)='' then FSearchDataFileName:=GetNewAddressSearchFile;
      ForceDirectories(ExtractFilePath(FSearchDataFileName));
      FSt:=TFileStream.Create(FSearchDataFileName,fmCreate);
    end else begin
      ForceDirectories(ExtractFilePath(AFileName));
      FSt:=TFileStream.Create(AFileName,fmCreate);
    end;
    try
      S:=DFRSearch; FSt.WriteBuffer(S[1],length(DFRSearch));
      S:=AnsiString(FName); I:=length(S); FSt.WriteBuffer(I,4); If I>0 then FSt.WriteBuffer(S[1],I);
      S:=AnsiString(FLastSavedGameFileName); I:=length(S); FSt.WriteBuffer(I,4); If I>0 then FSt.WriteBuffer(S[1],I);
      If Assigned(FCompleteFile) then begin
        {Store whole saved game}
        Mode:=0; FSt.WriteBuffer(Mode,1);
        FSt.CopyFrom(FCompleteFile,0);
      end else begin
        {Store address list}
        Mode:=1; FSt.WriteBuffer(Mode,1);
        I:=FAddressList.Count; FSt.WriteBuffer(I,4);
        For I:=0 to FAddressList.Count-1 do begin J:=Integer(FAddressList[I]); FSt.WriteBuffer(J,4); end;
        For I:=0 to FAddressSizeList.Count-1 do begin J:=Integer(FAddressSizeList[I]); FSt.WriteBuffer(J,4); end;
        For I:=0 to FAddressLastValue.Count-1 do begin J:=Integer(FAddressLastValue[I]); FSt.WriteBuffer(J,4); end;
      end;
    finally
      FSt.Free;
    end;
  except
    exit;
  end;
end;

function TAddressSearcher.LoadSavedGameFile(const ASavedGameFile: String) : Boolean;
begin
  result:=False;
  Clear(True);

  If not FileExists(ASavedGameFile) then exit;
  FCompleteFile:=TMemoryStream.Create;
  try
    FCompleteFile.LoadFromFile(ASavedGameFile);
  except
    FreeAndNil(FCompleteFile); result:=False; exit;
  end;
  FLastSavedGameFileName:=ASavedGameFile;
  result:=True;
end;



procedure TAddressSearcher.SearchAddress(const ASavedGameFile: String; const AValue: Integer);
Var MSt : TMemoryStream;
begin
  MSt:=TMemoryStream.Create;
  try
    try MSt.LoadFromFile(ASavedGameFile); except exit; end;
    If Assigned(FCompleteFile) then FreeAndNil(FCompleteFile); {Complete old file is useless on exact value search}
    If Assigned(FAddressList) then begin
      {Only search on already found addresses}
      SearchAddressInList(MSt,AValue);
    end else begin
      {Search whole file}
      FAddressList:=TList.Create;
      FAddressSizeList:=TList.Create;
      FAddressLastValue:=TList.Create;
      SearchAddressWholeFile(MSt,AValue);
    end;
  finally
    MSt.Free;
  end;
  FLastSavedGameFileName:=ASavedGameFile;
end;



procedure TAddressSearcher.SearchAddressIndirect(const ASavedGameFile: String; const AValueChangeType: TValueChangeType);
Var MSt : TMemoryStream;
begin
  MSt:=TMemoryStream.Create;
  try
    try MSt.LoadFromFile(ASavedGameFile); except exit; end;
    If Assigned(FCompleteFile) then begin
      {Match changes against whole file}
      FAddressList:=TList.Create;
      FAddressSizeList:=TList.Create;
      FAddressLastValue:=TList.Create;
      SearchAddressIndirectAgainstWholeFile(MSt,AValueChangeType);
      FreeAndNil(FCompleteFile);
    end else begin
      {Match changes against adress list}
      SearchAddressIndirectAgainstAddressList(MSt,AValueChangeType);
    end;
  finally
    MSt.Free;
  end;
  FLastSavedGameFileName:=ASavedGameFile;
end;

function TAddressSearcher.NoResults: Boolean;
begin
  result:=not Assigned(FAddressList) or (FAddressList.Count=0);
end;

Function TAddressSearcher.GetResultNr(const ANr : Integer; var AAddress, ASize : Integer) : Boolean;
begin
  result:=False;
  if (not Assigned(FAddressList)) or (FAddressList.Count=0) or (ANr<0) or (ANr>=FAddressList.Count) then exit;
  ASize:=Integer(FAddressSizeList[ANr]);
  AAddress:=Integer(FAddressList[ANr]);
  result:=True;
end;

function TAddressSearcher.GetList: TStringList;
Var I : Integer;
    Addresses : TList;
begin
  result:=TStringList.Create;
  If not Assigned(FAddressList) then exit;
  Addresses:=TList.Create;
  try
    For I:=0 to FAddressList.Count-1 do begin
      If Addresses.IndexOf(FAddressList[I])>=0 then continue;
      Addresses.Add(FAddressList[I]);
      result.AddObject(
        IntToHex(Integer(FAddressList[I]),1)+'h='+IntToStr(Integer(FAddressList[I]))+'d '+
        '('+IntToStr(Integer(FAddressSizeList[I]))+' '+LanguageSetup.Bytes+', '+
        LanguageSetup.SearchAddressResultMessageMultipleAddressesCurrentValue+': '+IntToStr(Integer(FAddressLastValue[I]))+')',TObject(I));
    end;
  finally
    Addresses.Free;
  end;
end;

end.
