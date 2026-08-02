unit GameDBUnit;
interface

{DEFINE SpeedTest}

uses Classes, CommonComponents, GameDBHelpers;

Type TConfOpt=class(TConfOptH)
  public
    Constructor Create;
    Destructor Destroy; override;
end;




Type TGameDB=class;

     TGame=class(TGameH)
  private
    function GetGameDB: TGameDB;
    procedure SetGameDB(const Value: TGameDB);
  public
    Procedure CreateConfFile; override;

    property GameDB : TGameDB read GetGameDB write SetGameDB;
end;

      TGameDB=class(TGameDBH)
  private
    function GetConfOpt: TConfOpt;
    function GetGame(I: Integer): TGame;
    Procedure LoadGameFromFile(const FileName : String; const DOSFileDate : Integer);
    Procedure LoadList;
  public
    Constructor Create(const ADir : String; const ATimeStampCheck : Boolean = True);
    Function Add(const AName : String) : Integer; overload;
    Function Delete(const Index : Integer) : Boolean; overload;
    Function Delete(const AGame : TGame) : Boolean; overload;
    property Game[I : Integer] : TGame read GetGame; default;
    property ConfOpt : TConfOpt read GetConfOpt;
end;

implementation

uses Windows, SysUtils, Messages, Forms, Dialogs, Math, CommonTools, CommonHelpers, PrgConsts,
     PrgSetupUnit, LanguageSetupUnit, GameDBToolsUnit, WaitFormUnit, DOSBoxUnit,
     LoggingUnit, System.UITypes;

{ TConfOpt }

constructor TConfOpt.Create;
begin
  inherited Create;

  AddStringRec(0,'resolution','value',DefaultValuesResolutionFullscreen);
  AddStringRec(1,'resolutionWindow','value',DefaultValuesResolutionWindow);
  AddStringRec(2,'joysticks','value',DefaultValuesJoysticks);
  AddStringRec(3,'scale','value',DefaultValuesScale);
  AddStringRec(4,'render','value',DefaultValueRender);
  AddStringRec(5,'cycles','value',DefaultValueCycles);
  AddStringRec(6,'video','value',DefaultValuesVideo);
  AddStringRec(7,'memory','value',DefaultValuesMemory);
  AddStringRec(8,'frameskip','value',DefaultValuesFrameSkip);
  AddStringRec(9,'core','value',DefaultValuesCore);
  AddStringRec(10,'sblaster','value',DefaultValuesSBlaster);
  AddStringRec(11,'oplmode','value',DefaultValuesOPLModes);
  AddStringRec(12,'keyboardlayout','value',DefaultValuesKeyboardLayout);
  AddStringRec(13,'codepage','value',DefaultValuesCodepage);
  AddStringRec(14,'ReportedDOSVersion','value',DefaultValuesReportedDOSVersion);
  AddStringRec(15,'MIDIDevice','value',DefaultValuesMIDIDevice);
  AddStringRec(16,'Blocksize','value',DefaultValuesBlocksize);
  AddStringRec(17,'CyclesDown','value',DefaultValuesCyclesDown);
  AddStringRec(18,'CyclesUp','value',DefaultValuesCyclesUp);
  AddStringRec(19,'DMA','value',DefaultValuesDMA);
  AddStringRec(20,'DMA1','value',DefaultValuesDMA1);
  AddStringRec(21,'GUSBase','value',DefaultValuesGUSBase);
  AddStringRec(22,'GUSRate','value',DefaultValuesGUSRate);
  AddStringRec(23,'HDMA','value',DefaultValuesHDMA);
  AddStringRec(24,'IRQ','value',DefaultValuesIRQ);
  AddStringRec(25,'IRQ1','value',DefaultValuesIRQ1);
  AddStringRec(26,'MPU401','value',DefaultValuesMPU401);
  AddStringRec(27,'OPLRate','value',DefaultValuesOPLRate);
  AddStringRec(28,'PCRate','value',DefaultValuesPCRate);
  AddStringRec(29,'Rate','value',DefaultValuesRate);
  AddStringRec(30,'SBBase','value',DefaultValuesSBBase);
  AddStringRec(31,'MouseSensitivity','value',DefaultValuesMouseSensitivity);
  AddStringRec(32,'TandyRate','value',DefaultValuesTandyRate);
  AddStringRec(33,'ScummVMFilter','value',DefaultValuesScummVMFilter);
  AddStringRec(34,'ScummVMMusicDriver','value',DefaultValuesScummVMMusicDriver);
  AddStringRec(35,'VGAChipsets','value',DefaultValuesVGAChipsets);
  AddStringRec(36,'VGAVideoRAM','value',DefaultValuesVGAVideoRAM);
  AddStringRec(37,'ScummVMRenderMode','value',DefaultValuesScummVMRenderMode);
  AddStringRec(38,'ScummVMPlatform','value',DefaultValuesScummVMPlatform);
  AddStringRec(39,'ScummVMLanguages','value',DefaultValuesScummVMLanguages);
  AddStringRec(40,'CPUType','value',DefaultValuesCPUType);
  AddStringRec(41,'SBOplEmu','value',DefaultValuesOplEmu);
  AddStringRec(42,'GlideEmulation','value',DefaultValuesGlideEmulation);
  AddStringRec(43,'GlideEmulationPort','value',DefaultValuesGlideEmulationPort);
  AddStringRec(44,'GlideEmulationLFB','value',DefaultValuesGlideEmulationLFB);
  AddStringRec(45,'InnovaEmulationSampleRate','value',DefaultValuesInnovaEmulationSampleRate);
  AddStringRec(46,'InnovaEmulationBaseAddress','value',DefaultValuesInnovaEmulationBaseAddress);
  AddStringRec(47,'InnovaEmulationQuality','value',DefaultValuesInnovaEmulationQuality);
  AddStringRec(48,'NE2000EmulationBaseAddress','value',DefaultValuesNE2000EmulationBaseAddress);
  AddStringRec(49,'NE2000EmulationInterrupt','value',DefaultValuesNE2000EmulationInterrupt);
  AddStringRec(50,'MT32ReverbMode','value',DefaultValuesMT32ReverbMode);
  AddStringRec(51,'MT32ReverbTime','value',DefaultValuesMT32ReverbTime);
  AddStringRec(52,'MT32ReverbLevel','value',DefaultValuesMT32ReverbLevel);
  AddStringRec(53,'renderStaging','value',DefaultValueRenderStaging);
  AddStringRec(54,'renderX','value',DefaultValueRenderX);
  AddStringRec(55,'vsyncStaging','value',DefaultValueVSyncStaging);
  AddStringRec(56,'vsyncStagingOld','value',DefaultValueVSyncStagingOld);
  AddStringRec(57,'vsyncX','value',DefaultValueVSyncX);

  CacheAllStrings;
end;

destructor TConfOpt.Destroy;
begin
  StoreAllValues;
  inherited Destroy;
end;

{ TGame }

function TGame.GetGameDB: TGameDB;
begin
  result:=TGameDB(FGameDB);
end;

procedure TGame.SetGameDB(const Value: TGameDB);
begin
  FGameDB:=Value;
end;

Procedure TGame.CreateConfFile;
Var St : TStringList;
begin
  If not DOSBoxMode(self) then exit;

  St:=BuildConfFile(self,False,False,-1,nil,false);
  try
    St.SaveToFile(ChangeFileExt(SetupFile,'.conf'));
  finally
    St.Free;
  end;
end;

{ TGameDB }

constructor TGameDB.Create(const ADir : String; const ATimeStampCheck : Boolean);
Var Msg : tagMSG;
    B : Boolean;
begin
  FCreateConfFilesOnSave:=False;
  FGameList:=TList.Create;
  FConfOpt:=TConfOpt.Create;
  If ATimeStampCheck then FConfOpt.CacheAllStrings;
  FDir:=IncludeTrailingPathDelimiter(ADir);
  FTimeStampCheck:=ATimeStampCheck;
  B:=False;
  If Application.MainForm<>nil then begin
    B:=Application.MainForm.Enabled;
    Application.MainForm.Enabled:=False;
  end;
  try
    LoadList;
  finally
    If Application.MainForm<>nil then begin
      While PeekMessage(Msg,Application.MainForm.Handle,WM_INPUT,WM_INPUT,1) do ;
      Application.MainForm.Enabled:=B;
    end;
  end;
  DeleteOldFiles;
end;

function TGameDB.GetConfOpt: TConfOpt;
begin
  result:=TConfOpt(FConfOpt);
end;

function TGameDB.GetGame(I: Integer): TGame;
begin
  result:=TGame(inherited GetGame(I));
end;

Procedure TGameDB.LoadGameFromFile(const FileName: String; const DOSFileDate : Integer);
Var Game : TGame;
begin
  LogInfo('Loading profile '+FileName);
  If PrgSetup.BinaryCache and GetLoadBinCacheOffset(FileName,DOSFileDate) then begin
    LogInfo('Trying to load from cache');
    Game:=TGame.CreateDelayed(FileName,FTimeStampCheck);
    try
      Game.InitData;
      Game.LoadFromStream(BinLoadCache);
      Game.LoadCache;
    except
      LogInfo('Cache failed, burning cache for all profiles and loading from prof file');
      Game.Free;
      Game:=TGame.Create(FileName);
      BurnLoadBinCache;
    end;
    If Game.GameExeMD5='' then begin
      LogInfo('No game exe MD5 sum. May be there is just no MD5 sum stored but may be also this cached profile is damaged. Loading this profile from prof file for safety reasons.');
      Game.Free;
      Game:=TGame.Create(FileName);
    end;
  end else begin
    LogInfo('Loading profile from prof file');
    Game:=TGame.Create(FileName);
  end;

  LogInfo('Adding profile to data base list');
  Game.OnChanged:=GameChanged;
  Game.GameDB:=self;
  FGameList.Add(Game);
end;

function TGameDB.Add(const AName: String): Integer;
Var Game : TGame;
begin
  Game:=TGame.Create(MakePROFFileName(AName,FDir,True));
  result:=inherited Add(Game, AName);
end;

procedure TGameDB.LoadList;
Var I : Integer;
    List : TStringList;
    {$IFDEF SpeedTest}C0,{$ENDIF}C1,C2 : UInt64;
    T0 : UInt64;
begin
  T0:=GetTickCount64;
  Clear;
  ForceDirectories(FDir);

  If PrgSetup.BinaryCache then begin
    InitLoadBinCache;
  end;

  {$IFDEF SpeedTest}C0:=GetTickCount; {$ENDIF}
  List:=GetProfilesListFromDrive;
  WaitForm:=nil;

    try
      LogInfo('LoadList: '+FDir+' count='+IntToStr(List.Count)+' cache='+BoolToStr(PrgSetup.BinaryCache,True));

      FGameList.Capacity:=List.Count;
      C1:=GetTickCount64;

      For I:=0 to Min(List.Count,100)-1 do begin
        LoadGameFromFile(FDir+List[I],Integer(List.Objects[I]));
        If (I mod 10)=0 then Application.ProcessMessages;
      end;

      If List.Count>100 then begin
        C2:=GetTickCount64;
        LogInfo('LoadList: first 100 took '+FloatToStrF(Double(C2-C1),ffFixed,8,0)+'ms estimated total '+IntToStr(Integer(C2-C1)*List.Count div 100)+'ms');
        If Integer(C2-C1)*List.Count div 100>150 then begin
          LogInfo('LoadList: showing WaitForm');
          WaitForm:=CreateWaitForm(nil,LanguageSetup.MessageLoadingDataBase,List.Count);
        end;
        For I:=100 to List.Count-1 do begin
          If (WaitForm<>nil) and ((I mod 50)=0) then WaitForm.Step(I);
          LoadGameFromFile(FDir+List[I],Integer(List.Objects[I]));
          If (I mod 10)=0 then Application.ProcessMessages;
        end;
      end;

      {$IFDEF SpeedTest}C2:=GetTickCount; If List.Count>100 then ShowMessage(IntToStr(C1-C0)+#13+IntToStr(C2-C1)+#13+FDir);{$ENDIF}

  finally
    List.Free;
    If Assigned(WaitForm) then FreeAndNil(WaitForm);
  end;

  LogInfo('LoadList: done in '+FloatToStrF(Double(GetTickCount64-T0),ffFixed,8,0)+'ms');

  If PrgSetup.BinaryCache then begin
    DoneLoadBinCache;
  end;

  If Application.MainForm<>nil then ForceForegroundWindow(Application.MainForm.Handle);
end;

function TGameDB.Delete(const Index: Integer): Boolean;
Var FileName : String;
begin
  result:=(Index>=0) and (Index<FGameList.Count);
  if not result then exit;
  FileName:=TGame(FGameList[Index]).SetupFile;
  TGame(FGameList[Index]).Free;
  FGameList.Delete(Index);

  If FileExists(FileName) then begin
    If not ExtDeleteFile(FileName,ftProfile) then MessageDlg(Format(LanguageSetup.MessageCouldNotDeleteFile,[FileName]),mtError,[mbOK],0);
  end;
  If FileExists(ChangeFileExt(FileName,'.conf')) then begin
    If not ExtDeleteFile(ChangeFileExt(FileName,'.conf'),ftProfile) then MessageDlg(Format(LanguageSetup.MessageCouldNotDeleteFile,[ChangeFileExt(FileName,'.conf')]),mtError,[mbOK],0);
  end;
end;

function TGameDB.Delete(const AGame: TGame): Boolean;
begin
  result:=Delete(IndexOf(AGame));
end;
end.
