unit CommonComponents;
interface

uses Windows, Classes, IniFiles, Math, Variants, CommonHelpers;

Type TFileChangeStatus=(fcsNoChange,fcsChanged,fcsDeleted);

Type TBasePrgSetup=class(TBasePrgSetupH)
  private
    FSetupFile : String;
    FFirstRun : Boolean;
    Ini : TMemIniFile;
    FOwnINI : Boolean;
    FStoreConfigOnExit : Boolean;
    FOnChanged : TNotifyEvent;
    Procedure ReadStringFromINI(const I : Integer);
    Procedure LoadIniNow;
    Function GetIni : TMemIniFile;
  protected
    function GetBoolean(const Index: Integer): Boolean; override;
    function GetInteger(const Index: Integer): Integer; override;
    procedure SetBoolean(const Index: Integer; const Value: Boolean);
    procedure SetInteger(const Index, Value: Integer);
    procedure SetString(const Index: Integer; const Value: String);
  public
    Constructor Create(const ASetupFile : String); overload;
    constructor CreateNoTimeStampCheck(const ASetupFile: String);
    Constructor Create(const ABasePrgSetup : TBasePrgSetup); overload;
    Destructor Destroy; override;
    Procedure UpdateFile; virtual;
    Procedure AssignFrom(const ABasePrgSetup : TBasePrgSetup);
    Procedure AssignFromPartially(const ABasePrgSetup : TBasePrgSetup; const SettingsToKeep : Array of Integer);
    Procedure StoreAllValues;
    Procedure ResetToDefault;
    Function CheckAndUpdateTimeStamp : TFileChangeStatus;
    Procedure ReloadINI; virtual;
    Procedure RenameINI(const NewFile : String); virtual;
    function GetString(const Index: Integer): String; override;
    Procedure CacheAllStrings;
    property SetupFile : String read FSetupFile;
    property FirstRun : Boolean read FFirstRun;
    property StoreConfigOnExit : Boolean read FStoreConfigOnExit write FStoreConfigOnExit;
    property OnChanged : TNotifyEvent read FOnChanged write FOnChanged;
    property OwnINI : Boolean read FOwnINI;
    property MemIni : TMemIniFile read GetIni;
end;

Function GetSimpleFileTime(const FileName : String) : DWord;

implementation

uses SysUtils;

{ TBasePrgSetup }

Function GetSimpleFileTime(const FileName : String) : DWord;
Var hFile : THandle;
    FileTime1, FileTime2, FileTime3 : TFileTime;
    FatDate, FatTime : Word;
begin
  hFile:=CreateFile(PChar(FileName),GENERIC_READ,FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  If hFile=INVALID_HANDLE_VALUE then begin result:=0; exit; end;
  try
    GetFileTime(hFile,@FileTime1,@FileTime2,@FileTime3);
  finally
    CloseHandle(hFile)
  end;
  FileTimeToDosDateTime(FileTime3,FatDate,FatTime);
  result:=FatDate*65536+FatTime;
end;

constructor TBasePrgSetup.Create(const ASetupFile: String);
begin
  inherited Create;
  FSetupFile:=ASetupFile;
  FFirstRun:=not FileExists(ASetupFile);
  FOwnINI:=True;
  If ASetupFile<>'' then begin
    Ini:=nil;
    CheckAndUpdateTimeStamp;
  end;
  FStoreConfigOnExit:=True;
end;

constructor TBasePrgSetup.CreateNoTimeStampCheck(const ASetupFile: String);
begin
  inherited Create;
  FSetupFile:=ASetupFile;
  FFirstRun:=not FileExists(ASetupFile);
  FOwnINI:=True;
  If ASetupFile<>'' then begin
    Ini:=nil;
  end;
  FStoreConfigOnExit:=True;
end;

constructor TBasePrgSetup.Create(const ABasePrgSetup: TBasePrgSetup);
begin
  inherited Create;
  FOwnINI:=False;
  FFirstRun:=False;
  Ini:=ABasePrgSetup.MemIni;
  ClearLists;
  FStoreConfigOnExit:=True;
end;

destructor TBasePrgSetup.Destroy;
Var St,St2 : TStringList;
    I : Integer;
begin
  If FChanged and FStoreConfigOnExit then begin
    LoadIniNow;
    If OwnINI then begin
      St:=TStringList.Create;
      St2:=TStringList.Create;
      try
        Ini.ReadSections(St);
        For I:=0 to St.Count-1 do begin
          St2.Clear;
          Ini.ReadSection(St[I],St2);
          If St2.Count=0 then Ini.EraseSection(St[I]);
        end;
      finally
        St.Free;
        St2.Free;
      end;
    end;
    try
      If Ini<>nil then begin
        ForceDirectories(ExtractFilePath(Ini.FileName));
        UpdateFile;
      end;
    except end;
  end;

  If FOwnINI and (Ini<>nil) then Ini.Free;

  inherited Destroy;
end;

Procedure TBasePrgSetup.LoadIniNow;
begin
  If (Ini=nil) and FOwnINI then
    Ini:=TMemIniFile.Create(FSetupFile);
end;

Function TBasePrgSetup.GetIni : TMemIniFile;
begin
  LoadIniNow;
  result:=Ini;
end;

function TBasePrgSetup.CheckAndUpdateTimeStamp: TFileChangeStatus;
Var NewFileTime : DWord;
begin
  If FSetupFile='' then begin result:=fcsNoChange; exit; end;

  If not FileExists(FSetupFile) then begin result:=fcsDeleted; exit; end;

  NewFileTime:=GetSimpleFileTime(FSetupFile);
  If NewFileTime=FLastTimeStamp then result:=fcsNoChange else result:=fcsChanged;
  FLastTimeStamp:=NewFileTime;
end;

Procedure TBasePrgSetup.ReloadINI;
Var I : Integer;
begin
  If Ini<>nil then Ini.Free;
  Ini:=TMemIniFile.Create(FSetupFile);
  for I:=0 to length(BooleanList)-1 do BooleanList[I].Cached:=False;
  for I:=0 to length(IntegerList)-1 do IntegerList[I].Cached:=False;
  for I:=0 to length(StringList)-1 do StringList[I].Cached:=False;
end;

procedure TBasePrgSetup.RenameINI(const NewFile: String);
begin
  LoadIniNow;
  Ini.UpdateFile;
  Ini.Free;
  If FSetupFile<>NewFile then begin
    if RenameFile(FSetupFile,NewFile) then FSetupFile:=NewFile;
  end;
  Ini:=TMemIniFile.Create(FSetupFile);
end;

procedure TBasePrgSetup.AssignFrom(const ABasePrgSetup: TBasePrgSetup);
begin
  AssignFromPartially(ABasePrgSetup,[]);
end;

Procedure TBasePrgSetup.AssignFromPartially(const ABasePrgSetup : TBasePrgSetup; const SettingsToKeep : Array of Integer);
Var I,J : Integer;
    B : Boolean;
begin
  For I:=0 to length(BooleanList)-1 do begin
    B:=True;
    For J:=Low(SettingsToKeep) to High(SettingsToKeep) do if SettingsToKeep[J]=BooleanList[I].Nr then begin B:=False; break; end;
    If not B then continue;
    BooleanList[I].Cached:=True;
    BooleanList[I].CacheValueBool:=ABasePrgSetup.GetBoolean(BooleanList[I].Nr);
  end;
  For I:=0 to length(IntegerList)-1 do begin
    B:=True;
    For J:=Low(SettingsToKeep) to High(SettingsToKeep) do if SettingsToKeep[J]=IntegerList[I].Nr then begin B:=False; break; end;
    If not B then continue;
    IntegerList[I].Cached:=True;
    IntegerList[I].CacheValueInteger:=ABasePrgSetup.GetInteger(IntegerList[I].Nr);
  end;
  For I:=0 to length(StringList)-1 do begin
    B:=True;
    For J:=Low(SettingsToKeep) to High(SettingsToKeep) do if SettingsToKeep[J]=StringList[I].Nr then begin B:=False; break; end;
    If not B then continue;
    StringList[I].Cached:=True;
    StringList[I].CacheValueString:=ABasePrgSetup.GetString(StringList[I].Nr);
  end;

  StoreAllValues;
end;

procedure TBasePrgSetup.StoreAllValues;
Var I : Integer;
begin
  LoadIniNow;
  if Ini=nil then exit;

  For I:=0 to length(BooleanList)-1 do
    Ini.WriteBool(BooleanList[I].Section,BooleanList[I].Key,GetBoolean(BooleanList[I].Nr));

  For I:=0 to length(IntegerList)-1 do
    Ini.WriteInteger(IntegerList[I].Section,IntegerList[I].Key,GetInteger(IntegerList[I].Nr));

  For I:=0 to length(StringList)-1 do
    Ini.WriteString(StringList[I].Section,StringList[I].Key,GetString(StringList[I].Nr));

  If FChanged then UpdateFile;
  FChanged:=False;

  CheckAndUpdateTimeStamp;
end;

procedure TBasePrgSetup.UpdateFile;
begin
  LoadIniNow;
  try ForceDirectories(ExtractFilePath(Ini.FileName)); Ini.UpdateFile; except end; {Language Files may be read only in program foldes}
end;

procedure TBasePrgSetup.ResetToDefault;
Var I : Integer;
begin
  For I:=0 to length(BooleanList)-1 do
    SetBoolean(BooleanList[I].Nr,BooleanList[I].DefaultBool);

  For I:=0 to length(IntegerList)-1 do
    SetInteger(IntegerList[I].Nr,IntegerList[I].DefaultInteger);

  For I:=0 to length(StringList)-1 do
    SetString(StringList[I].Nr,StringList[I].DefaultString);

  UpdateFile;
  FChanged:=False;

  CheckAndUpdateTimeStamp;
end;

function TBasePrgSetup.GetBoolean(const Index: Integer): Boolean;
Var I : Integer;
    S : String;
    B : Boolean;
begin
  I:=IndexOf(Index,BooleanList,BooleanIndex);
  if I<0 then begin result:=False; exit; end;
  with BooleanList[I] do begin
    If Cached then begin result:=CacheValueBool; exit; end;

    If DefaultBool then S:='true' else S:='false';
    LoadIniNow;
    If Ini<>nil then S:=Trim(ExtUpperCase(Ini.ReadString(Section,Key,S)));
    B:=False; result:=False;
    If (S='0') or (S='FALSE') then begin result:=False; B:=True; end;
    If (S='1') or (S='TRUE') then begin result:=True; B:=True; end;
    If not B then result:=DefaultBool;

    Cached:=True;
    CacheValueBool:=result;
  end;
end;

function TBasePrgSetup.GetInteger(const Index: Integer): Integer;
Var I : Integer;
begin
  I:=IndexOf(Index,IntegerList,IntegerIndex);
  Assert(I>=0,'Es gibt keinen Eintrag in der Integer-Liste mit der Nummer '+IntToStr(Index));
  if I<0 then begin result:=0; exit; end;
  with IntegerList[I] do begin
    If Cached then begin result:=CacheValueInteger; exit; end;
    LoadIniNow;
    If Ini<>nil then result:=Ini.ReadInteger(Section,Key,DefaultInteger) else result:=DefaultInteger;
    Cached:=True;
    CacheValueInteger:=result;
  end;
end;

Procedure TBasePrgSetup.ReadStringFromINI(const I : Integer);
begin
  LoadIniNow;
  with StringList[I] do begin
    Cached:=True;
    if Ini<>nil then CacheValueString:=Ini.ReadString(Section,Key,DefaultString) else CacheValueString:=DefaultString;
  end;
end;

function TBasePrgSetup.GetString(const Index: Integer): String;
Var I : Integer;
begin
  I:=IndexOf(Index,StringList,StringIndex);
  if I<0 then begin result:=''; exit; end;
  with StringList[I] do begin
    If not Cached then ReadStringFromINI(I);
    result:=CacheValueString;
  end;
end;

procedure TBasePrgSetup.SetBoolean(const Index: Integer; const Value: Boolean);
Var I : Integer;
begin
  I:=IndexOf(Index,BooleanList,BooleanIndex);
  if I<0 then exit;
  with BooleanList[I] do begin
    LoadIniNow;
    If DefaultBool=Value then Ini.DeleteKey(Section,Key) else Ini.WriteBool(Section,Key,Value);
    Cached:=True;
    CacheValueBool:=Value;
    FChanged:=True;
    If Assigned(FOnChanged) then FOnChanged(self);
  end;
end;

procedure TBasePrgSetup.SetInteger(const Index, Value: Integer);
Var I : Integer;
begin
  I:=IndexOf(Index,IntegerList,IntegerIndex);
  if I<0 then exit;
  with IntegerList[I] do begin
    LoadIniNow;
    If DefaultInteger=Value then Ini.DeleteKey(Section,Key) else Ini.WriteInteger(Section,Key,Value);
    Cached:=True;
    CacheValueInteger:=Value;
    FChanged:=True;
    If Assigned(FOnChanged) then FOnChanged(self);
  end;
end;

procedure TBasePrgSetup.SetString(const Index: Integer; const Value: String);
Var I : Integer;
begin
  I:=IndexOf(Index,StringList,StringIndex);
  if I<0 then exit;
  with StringList[I] do begin
    LoadIniNow;
    If DefaultString=Value then Ini.DeleteKey(Section,Key) else Ini.WriteString(Section,Key,Value);
    Cached:=True;
    CacheValueString:=Value;
    FChanged:=True;
    If Assigned(FOnChanged) then FOnChanged(self);
  end;
end;

Procedure TBasePrgSetup.CacheAllStrings;
Var I : Integer;
begin
  For I:=0 to length(StringList)-1 do if not StringList[I].Cached then ReadStringFromINI(I);
end;

end.

