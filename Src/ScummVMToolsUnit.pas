unit ScummVMToolsUnit;
interface

uses Classes, PrgSetupUnit; {need to init PrgSetupUnit before init of this unit}

Type TScummVMGamesList=class
  private
    FName, FLongName : TStringList;
    Procedure LoadConfig;
    Procedure SaveConfig;
    function GetCount: Integer;
    Function LoadListFromScummVMFile(const ScummVMPrgFile : String) : Boolean;
    Function LoadListFromScummVMStringList(const St : TStringList) : Boolean;
  public
    Constructor Create;
    Destructor Destroy; override;
    Function LoadListFromScummVM(const WarnIfScummVMNotFound : Boolean; const CustomScummVMPath : String ='') : Boolean;
    Function NameFromDescription(const Description : String) : String;
    property Count : Integer read GetCount;
    property NamesList : TStringList read FName;
    property DescriptionList : TStringList read FLongName;
end;

Var ScummVMGamesList : TScummVMGamesList;

implementation

uses Windows, SysUtils, StrUtils, Dialogs, IniFiles, PrgConsts, LanguageSetupUnit,
     CommonTools, LoggingUnit;

{ TScummVMGamesList }

constructor TScummVMGamesList.Create;
begin
  inherited Create;

  FName:=TStringList.Create;
  FLongName:=TStringList.Create;
  LoadConfig;
end;

destructor TScummVMGamesList.Destroy;
begin
  SaveConfig;
  FName.Free;
  FLongName.Free;
  inherited Destroy;
end;

procedure TScummVMGamesList.LoadConfig;
Var Ini : TMemIniFile;
    I : Integer;
begin
  Ini:=TMemIniFile.Create(PrgDataDir+SettingsFolder+'\'+ScummVMConfOptFile, TEncoding.UTF8);
  try
    Ini.ReadSections(FName);
    For I:=0 to FName.Count-1 do FLongName.Add(Ini.ReadString(FName[I],'Description',''));
  finally
    Ini.Free;
  end;
end;

procedure TScummVMGamesList.SaveConfig;
Var Ini : TMemIniFile;
    I : Integer;
    DatFile : String;
begin
  DatFile:=PrgDataDir+SettingsFolder+'\'+ScummVMConfOptFile;
  LogInfo('ScummVM.dat: writing '+IntToStr(FName.Count)+' entries to '+DatFile);
  ExtDeleteFile(DatFile,ftProfile);
  If FName.Count=0 then begin
    LogInfo('ScummVM.dat: nothing to write');
    exit;
  end;

  Ini:=TMemIniFile.Create(DatFile, TEncoding.UTF8);
  try
    For I:=0 to FName.Count-1 do Ini.WriteString(FName[I],'Description',FLongName[I]);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
  LogInfo('ScummVM.dat: saved '+DatFile);
end;

function TScummVMGamesList.GetCount: Integer;
begin
  result:=FName.Count;
end;

Function TScummVMGamesList.LoadListFromScummVM(const WarnIfScummVMNotFound : Boolean; const CustomScummVMPath : String) : Boolean;
Var S : String;
begin
  result:=False;

  FName.Clear;
  FLongName.Clear;

  If Trim(CustomScummVMPath)<>'' then begin
    S:=IncludeTrailingPathDelimiter(Trim(CustomScummVMPath))+ScummPrgFile;
  end else begin
    S:=IncludeTrailingPathDelimiter(PrgSetup.ScummVMPath)+ScummPrgFile;
  end;
  If not FileExists(S) then begin
    if WarnIfScummVMNotFound then MessageDlg(Format(LanguageSetup.MessageFileNotFound,[S]),mtError,[mbOK],0);
    exit;
  end;

  result:=LoadListFromScummVMFile(S);
end;

function TScummVMGamesList.LoadListFromScummVMFile(const ScummVMPrgFile: String): Boolean;
Var St : TStringList;
begin
  result:=False;

  St:=RunAndGetOutput(ScummVMPrgFile,'-z',True);
  If St=nil then exit;
  try
    result:=LoadListFromScummVMStringList(St);
  finally
    St.Free;
  end;
end;

function TScummVMGamesList.LoadListFromScummVMStringList(const St: TStringList): Boolean;
Var I,Mode,J,ColonPos : Integer;
    Id, Engine, GameId : String;
begin
  Mode:=0; J:=10;
  For I:=0 to St.Count-1 do Case Mode of
    0 : begin
          If Copy(St[I],1,3)='---' then begin J:=Pos(' ',St[I]); Mode:=1; end;
        end;
    1 : begin
          If StartsText('director:',St[I]) or StartsText('glk:',St[I]) then Continue;
          Id:=Trim(Copy(St[I],1,J-1));
          ColonPos:=Pos(':',Id);
          If ColonPos<=0 then Continue;
          Engine:=Copy(Id,1,ColonPos-1);
          GameId:=Copy(Id,ColonPos+1,MaxInt);
          FName.Add(Engine+':'+GameId);
          FLongName.Add(Trim(Copy(St[I],J+1,MaxInt)));
        end;
  end;
  result:=(Mode=1);
end;

function TScummVMGamesList.NameFromDescription(const Description: String): String;
Var I : Integer;
    Fallback : String;
begin
  result:='';
  Fallback:='';
  For I:=0 to FLongName.Count-1 do
    If CompareText(FLongName[I],Description)=0 then begin
      If Pos(':',FName[I])>0 then begin result:=FName[I]; exit; end;
      If Fallback='' then Fallback:=FName[I];
    end;
  result:=Fallback;
end;

end.
