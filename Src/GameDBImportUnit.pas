unit GameDBImportUnit;
interface

uses Classes, GameDBUnit;

Procedure ImportConfData(const AGameDB : TGameDB; const AGame : TGame; const Lines : String); overload;
Procedure ImportConfData(const AGameDB : TGameDB; const AGame : TGame; const St : TStringList); overload;
Procedure ImportConfFileData(const AGameDB : TGameDB; const AGame : TGame; const AFileName : String);

implementation

uses SysUtils, IniFiles, CommonHelpers, CommonTools, PrgSetupUnit;

Function StrToBool(S : String) : Boolean;
begin
  S:=Trim(ExtUpperCase(S));
  result:=(S='TRUE') or (S='T') or (S='1') or (S='YES') or (S='Y') or (S='ON');
end;

Procedure AddDrive(const Game : TGame; const RealFolder, Letter, FreeSpace : String);
Var S : String;
begin
  S:=MakeRelPath(RealFolder,PrgSetup.BaseDir,True)+';Drive;'+Letter+';;'+FreeSpace;
  Game.Mount[Game.NrOfMounts]:=S;
  Game.NrOfMounts:=Game.NrOfMounts+1;
end;

Procedure AddCDImageDrive(const Game : TGame; const RealFolder, Letter : String);
Var S : String;
begin
  S:=MakeRelPath(RealFolder,PrgSetup.BaseDir,True)+';CDRomImage;'+Letter+';;';
  Game.Mount[Game.NrOfMounts]:=S;
  Game.NrOfMounts:=Game.NrOfMounts+1;
end;

Function GetFolderAndDriveLetter(var Params, Letter, Folder : String) : Boolean;
Var J,K : Integer;
begin
  result:=False;
  J:=Pos(' ',Params); If J=0 then exit;
  Letter:=Trim(Copy(Params,1,J-1)); Params:=Trim(Copy(Params,J+1,MaxInt));
  If length(Letter)=3 then begin If (Letter[2]<>':') or (Letter[3]<>'\') then exit; Letter:=Letter[1]; end;
  If length(Letter)=2 then begin If Letter[2]<>':' then exit; Letter:=Letter[1]; end;
  Letter:=ExtUpperCase(Letter);
  If (Letter<'A') or (Letter>'Z') then exit;
  If Params[1]='"' then begin
    Params:=Trim(Copy(Params,2,MaxInt));
    K:=-1;
    For J:=1 to length(Params) do If Params[J]='"' then begin K:=J; break; end;
    If K=-1 then begin Folder:=''; Params:='"'+Params; end else begin Folder:=Trim(Copy(Params,1,K-1)); Params:=Trim(Copy(Params,K+1,MaxInt)); end;
  end else begin
    J:=Pos(' ',Params); If J>0 then begin Folder:=Trim(Copy(Params,1,J-1)); Params:=Trim(Copy(Params,J+1,MaxInt)); end else begin Folder:=Params; Params:=''; end;
  end;
  result:=True;
end;

Procedure MakeMountsFromAutoexec(const Game : TGame; const Autoexec : TStringList);
Var I : Integer;
    S,SUpper,Letter,Folder : String;
begin
  I:=0;
  while I<Autoexec.Count do begin
    If Game.NrOfMounts=10 then exit;
    S:=Trim(Autoexec[I]);
    If (S<>'') and (S[1]='@') then S:=Trim(Copy(S,2,MaxInt));
    SUpper:=ExtUpperCase(S);
    If (S='') or (Copy(SUpper,1,4)='ECHO') or (Copy(SUpper,1,3)='REM') or (Copy(SUpper,1,4)='SET ') or (Copy(SUpper,1,5)='KEYB ') then begin inc(I); continue; end;
    If Copy(SUpper,1,6)='MOUNT ' then begin
      S:=Trim(Copy(S,7,MaxInt));
      if not GetFolderAndDriveLetter(S,Letter,Folder) then begin inc(I); continue; end;
      If Trim(ExtUpperCase(Copy(S,1,9)))='-FREESIZE' then S:=Trim(Copy(S,10,MaxInt)) else S:='';
      AddDrive(Game,Folder,Letter,S);
      Autoexec.Delete(I);
      continue;
    end;
    If Copy(SUpper,1,9)='IMGMOUNT ' then begin
      S:=Trim(Copy(S,10,MaxInt));
      if not GetFolderAndDriveLetter(S,Letter,Folder) then begin inc(I); continue; end;
      S:=Trim(ExtUpperCase(S));
      if (S<>'-T ISO -FS ISO') and (S<>'-FS ISO -T ISO') then begin inc(I); continue; end;
      AddCDImageDrive(Game,Folder,Letter);
      Autoexec.Delete(I);
      continue;
    end;
    inc(I);
  end;
end;

Procedure LoadSpecialData(const Game : TGame; const FileName : String);
Var St,Autoexec : TStringList;
    I : Integer;
    Sec : Integer;
    S,T,U : String;
begin
  St:=TStringList.Create;
  Autoexec:=TStringList.Create;
  try
    St.LoadFromFile(FileName);
    Sec:=-1;
    For I:=0 to St.Count-1 do begin
      S:=Trim(ExtUpperCase(St[I]));
      If (S<>'') and (S[1]='[') and (Pos(']',S)>0) then begin
        S:=Trim(Copy(S,2,Pos(']',S)-2));
        If S='GENERAL' then Sec:=0 else begin
          If S='AUTOEXEC' then Sec:=1 else Sec:=-1;
        end;
        continue;
      end;
      If Sec=0 then begin
        S:=Trim(ExtUpperCase(St[I]));
        If (S='') or (S[1]<>'#') or (Pos('=',S)=0) then continue;
        S:=Trim(Copy(Trim(St[I]),2,MaxInt));
        T:=Trim(ExtUpperCase(Copy(S,1,Pos('=',S)-1)));
        U:=Trim(Copy(S,Pos('=',S)+1,MaxInt));
        If T='SNAPSHOTIMAGE' then Game.CaptureFolder:=U;
        If T='EXIT' then Game.CloseDosBoxAfterGameExit:=StrToBool(U);
        If T='MANUALFILE' then Game.DataDir:=ExtractFilePath(U);
        If T='WWWSITE' then Game.WWW[1]:=U;
      end;
      If Sec=1 then begin
        T:=ExtUpperCase(St[I]);
        if T='EXIT' then begin Game.CloseDosBoxAfterGameExit:=true; continue; end;
        if Copy(Trim(T),1,1)='#' then continue;
        Autoexec.Add(St[I]);
      end;
    end;
    MakeMountsFromAutoexec(Game,Autoexec);
    while (Autoexec.Count>0) and (Trim(Autoexec[0])='') do Autoexec.Delete(0);
    Game.Autoexec:=StringListToString(Autoexec);
  finally
    St.Free;
    Autoexec.Free;
  end;
end;

Procedure ImportConfData(const AGameDB : TGameDB; const AGame : TGame; const Lines : String);
Var St : TStringList;
begin
  St:=TStringList.Create;
  try
    St.Text:=Lines;
    ImportConfData(AGameDB,AGame,St);
  finally
    St.Free;
  end;
end;

Procedure ImportConfData(const AGameDB : TGameDB; const AGame : TGame; const St : TStringList);
Var FileName : String;
begin
  FileName:=TempDir+'DFRTempConfFile.conf';
  St.SaveToFile(FileName);
  try
    ImportConfFileData(AGameDB,AGame,FileName);
  finally
    ExtDeleteFile(FileName,ftProfile);
  end;
end;

Procedure ImportConfFileData(const AGameDB : TGameDB; const AGame : TGame; const AFileName : String);
Var INI : TINIFile;
    B : Boolean;
    I : Integer;
    S : String;
    St : TStringList;
begin
  INI:=TIniFile.Create(AFileName);
  try
    AGame.StartFullscreen:=StrToBool(INI.ReadString('sdl','fullscreen','false'));
    AGame.UseDoublebuffering:=StrToBool(INI.ReadString('sdl','fulldouble','false'));
    AGame.Render:=Ini.ReadString('sdl','output','surface');
    AGame.FullscreenResolution:=Ini.ReadString('sdl','fullresolution','original');
    AGame.WindowResolution:=Ini.ReadString('sdl','windowresolution','original');
    AGame.AutoLockMouse:=StrToBool(INI.ReadString('sdl','autolock','true'));
    AGame.MouseSensitivity:=INI.ReadInteger('sdl','sensitivity',100);
    AGame.Priority:=Ini.ReadString('sdl','priority','higher,normal');
    AGame.UseScanCodes:=StrToBool(INI.ReadString('sdl','usescancodes','true'));
    AGame.CustomKeyMappingFile:=INI.ReadString('sdl','mapperfile','');
    If Trim(AGame.CustomKeyMappingFile)<>'' then AGame.CustomKeyMappingFile:=MakeRelPath(AGame.CustomKeyMappingFile,PrgSetup.BaseDir);

    AGame.VideoCard:=Ini.ReadString('dosbox','machine','vga');
    AGame.Memory:=INI.ReadInteger('dosbox','memsize',16);
    AGame.CaptureFolder:=MakeRelPath(INI.ReadString('dosbox','captures',IncludeTrailingPathDelimiter(PrgSetup.CaptureDir)),PrgSetup.BaseDir,True);

    AGame.FrameSkip:=INI.ReadInteger('render','frameskip',0);
    AGame.AspectCorrection:=StrToBool(INI.ReadString('render','aspect','false'));
    AGame.Scale:=Ini.ReadString('render','scaler','normal2x');

    AGame.Core:=Ini.ReadString('cpu','core','auto');
    AGame.Cycles:=Ini.ReadString('cpu','cycles','auto');

    B:=TryStrToInt(AGame.Cycles,I);
    If not B then begin
      S:=Trim(ExtUpperCase(AGame.Cycles));
      St:=ValueToList(AGameDB.ConfOpt.Cycles,';,');
      try
        For I:=0 to St.Count-1 do If Trim(ExtUpperCase(St[I]))=S then begin B:=True; break; end;
      finally
        St.Free;
      end;
    end;
    If not B then AGame.Cycles:='auto';

    AGame.CyclesUp:=INI.ReadInteger('cpu','cycleup',500);
    AGame.CyclesDown:=INI.ReadInteger('cpu','cycledown',20);

    AGame.EMS:=StrToBool(INI.ReadString('dos','ems','true'));
    AGame.XMS:=StrToBool(INI.ReadString('dos','xms','true'));
    AGame.UMB:=StrToBool(INI.ReadString('dos','umb','true'));
    AGame.KeyboardLayout:=INI.ReadString('dos','keyboardlayout','none');
    If ExtUpperCase(AGame.KeyboardLayout)='AUTO' then AGame.KeyboardLayout:='default';
    S:=Trim(INI.ReadString('dos','lfn','auto'));
    If (S='') or SameText(S,'default') then S:='auto';
    AGame.LFN:=S;

    AGame.MixerNosound:=StrToBool(INI.ReadString('mixer','nosound','false'));
    AGame.MixerRate:=Ini.ReadInteger('mixer','rate',22050);
    AGame.MixerBlocksize:=Ini.ReadInteger('mixer','blocksize',2048);
    AGame.MixerPrebuffer:=Ini.ReadInteger('mixer','prebuffer',10);
    AGame.MixerSwapStereo:=StrToBool(INI.ReadString('mixer','swapstereo','false'));
    AGame.MixerSampleAccurate:=StrToBool(INI.ReadString('mixer','sample accurate','false'));
    AGame.MixerDCBiasCorrection:=StrToBool(INI.ReadString('mixer','dc bias correction','false'));
    AGame.MixerCompressor:=StrToBool(INI.ReadString('mixer','compressor','false'));
    AGame.MixerCrossfeed:=Ini.ReadString('mixer','crossfeed','');
    AGame.MixerReverb:=Ini.ReadString('mixer','reverb','');
    AGame.MixerChorus:=Ini.ReadString('mixer','chorus','');

    AGame.SBType:=Ini.ReadString('sblaster','sbtype','sb16');
    AGame.SBBase:=Ini.ReadString('sblaster','sbbase','220');
    AGame.SBIRQ:=Ini.ReadInteger('sblaster','irq',7);
    AGame.SBDMA:=Ini.ReadInteger('sblaster','dma',1);
    AGame.SBHDMA:=Ini.ReadInteger('sblaster','hdma',5);
    S:=Trim(INI.ReadString('sblaster','sbmixer',''));
    If S='' then S:=Trim(INI.ReadString('sblaster','mixer',''));
    If S='' then S:='true';
    AGame.SBMixer:=StrToBool(S);
    AGame.SBOplMode:=Ini.ReadString('sblaster','oplmode','auto');
    AGame.SBOplRate:=Ini.ReadInteger('sblaster','oplrate',22050);
    S:=Trim(Ini.ReadString('sblaster','cms',''));
    AGame.SBCMS:=SameText(S,'on') or SameText(S,'true');
    AGame.SBGoldplay:=StrToBool(INI.ReadString('sblaster','goldplay','false'));
    AGame.SBFilter:=Ini.ReadString('sblaster','sb_filter','modern');
    AGame.SBFilterAlwaysOn:=StrToBool(INI.ReadString('sblaster','sb_filter_always_on','false'));
    AGame.SBWarmup:=Ini.ReadInteger('sblaster','sbwarmup',100);

    AGame.GUS:=StrToBool(INI.ReadString('gus','gus','true'));
    AGame.GUSRate:=Ini.ReadInteger('gus','gusrate',22050);
    AGame.GUSBase:=Ini.ReadString('gus','gusbase','240');
    AGame.GUSIRQ:=Ini.ReadInteger('gus','irg1',5);
    AGame.GUSDMA:=Ini.ReadInteger('gus','dma1',3);
    AGame.GUSUltraDir:=Ini.ReadString('gus','ultradir','C:\ULTRASND');
    AGame.GUSFilter:=Ini.ReadString('gus','gus_filter','on');
    S:=Trim(Ini.ReadString('gus','gusmemsize',''));
    If (S='-1') or SameText(S,'default') then S:='';
    AGame.GUSMemSize:=S;
    AGame.GUSType:=Ini.ReadString('gus','gustype','classic');
    AGame.GUSMasterVolume:=Ini.ReadString('gus','gus master volume','0');

    AGame.MIDIType:=Ini.ReadString('midi','mpu401','intelligent');
    AGame.MIDIDevice:=Ini.ReadString('midi','device','default');
    AGame.MIDIConfig:=Ini.ReadString('midi','config','');
    AGame.FluidChorus:=Ini.ReadString('fluidsynth','fsynth_chorus','');
    If AGame.FluidChorus='' then AGame.FluidChorus:=Ini.ReadString('midi','fluid.chorus','');
    AGame.FluidReverb:=Ini.ReadString('fluidsynth','fsynth_reverb','');
    If AGame.FluidReverb='' then AGame.FluidReverb:=Ini.ReadString('midi','fluid.reverb','');
    AGame.FluidFilter:=Ini.ReadString('fluidsynth','fsynth_filter','');
    AGame.FluidDriver:=Ini.ReadString('midi','fluid.driver','');
    AGame.MIDIBase:=Ini.ReadString('midi','mpubase','');
    AGame.MIDIIRQ:=Ini.ReadString('midi','mpuirq','');
    AGame.MIDISampleRate:=Ini.ReadString('midi','samplerate','');
    AGame.ReelMagic:=Ini.ReadString('reelmagic','reelmagic','');
    AGame.ReelMagicKey:=Ini.ReadString('reelmagic','reelmagic_key','');
    AGame.ReelMagicFCode:=Ini.ReadString('reelmagic','reelmagic_fcode','');

    S:=INI.ReadString('speaker','pcspeaker','true');
    If SameText(S,'impulse') or SameText(S,'discrete') or SameText(S,'none') or SameText(S,'off') then begin
      AGame.SpeakerPCMode:=S;
      AGame.SpeakerPC:=not (SameText(S,'none') or SameText(S,'off'));
    end else
      AGame.SpeakerPC:=StrToBool(S);
    AGame.SpeakerRate:=Ini.ReadInteger('speaker','pcrate',22050);
    AGame.SpeakerTandy:=Ini.ReadString('speaker','tandy','auto');
    AGame.SpeakerTandyRate:=Ini.ReadInteger('speaker','tandyrate',22050);
    AGame.SpeakerLptDac:=Trim(INI.ReadString('speaker','lpt_dac',''));
    AGame.SpeakerDisney:=StrToBool(INI.ReadString('speaker','disney','true'));
    AGame.SpeakerPCFilter:=Ini.ReadString('speaker','pcspeaker_filter','');
    AGame.SpeakerLptDacFilter:=Ini.ReadString('speaker','lpt_dac_filter','');
    S:=Trim(Ini.ReadString('speaker','ps1audio',''));
    AGame.PS1Audio:=SameText(S,'on') or SameText(S,'true') or SameText(S,'auto');
    AGame.PS1AudioRate:=Ini.ReadString('speaker','ps1audiorate','');
    AGame.WSS:=StrToBool(INI.ReadString('wss','wss','false'));

    AGame.JoystickType:=Ini.ReadString('joystick','joysticktype','auto');
    AGame.JoystickTimed:=StrToBool(INI.ReadString('joystick','timed','true'));
    AGame.JoystickAutoFire:=StrToBool(INI.ReadString('joystick','autofire','false'));
    AGame.JoystickSwap34:=StrToBool(INI.ReadString('joystick','swap34','false'));
    AGame.JoystickButtonwrap:=StrToBool(INI.ReadString('joystick','buttonwrap','true'));

    AGame.Serial1:=INI.ReadString('serial','serial1','dummy');
    AGame.Serial2:=INI.ReadString('serial','serial2','dummy');
    AGame.Serial3:=INI.ReadString('serial','serial3','disabled');
    AGame.Serial4:=INI.ReadString('serial','serial4','disabled');

    AGame.IPX:=StrToBool(INI.ReadString('ipx','ipx','false'));
  finally
    Ini.Free;
  end;
  LoadSpecialData(AGame,AFileName);
end;

end.
