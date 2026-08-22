unit DosBoxConfUnit;
interface

uses Classes, GameDBUnit;

Procedure GenerateGraphicsConf(const Game: TGame; const Dest: TStrings);
Procedure GenerateMidiConf(const Game: TGame; const Dest: TStrings; const DOSBoxVersion: Double; const IsStaging, IsOldStaging: Boolean);
Procedure GenerateSoundDeviceConf(const Game: TGame; const Dest: TStrings; const DOSBoxVersion: Double);
Procedure GenerateInnovaConf(const Game: TGame; const Dest: TStrings; const IsStaging, IsOldStaging: Boolean);
Procedure GenerateSDLConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer; const BuildForArchivePackage: Boolean);
Procedure GenerateCoreDOSBoxConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer; const DOSBoxVersion: Double; const BuildForArchivePackage: Boolean; const DeleteOnExit: TStringList);
Procedure GenerateGlideConf(const Game: TGame; const Dest: TStrings);
Procedure GeneratePureGlideCfg(const Game: TGame; const Cfg: TStrings);
Procedure GenerateNetworkConf(const Game: TGame; const Dest: TStrings);
Procedure GenerateMSDOSConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer);
Procedure GenerateSpecialMachineConf(const Game: TGame; const Dest: TStrings);
Procedure GenerateCPUConf(const Game: TGame; const Dest: TStrings; const DOSBoxVersion: Double);
Procedure GenerateAutoExecKeyboardConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer);
Procedure GenerateAutoExecDOSVerConf(const Game: TGame; const Dest: TStrings);

implementation

uses SysUtils, Windows, PrgSetupUnit, PrgConsts, CommonHelpers, CommonTools, DosBoxHelpers, DOSBoxShadersHelpers, DOSBoxUnitHelpers, MIDITools, LanguageSetupUnit;

Procedure GenerateCoreMidiConf(const Game: TGame; const Dest: TStrings; const IsStaging: Boolean); forward;
Procedure GenerateFluidMidiConf(const Game: TGame; const Dest: TStrings; const IsStaging, IsOldStaging: Boolean); forward;
Procedure GenerateMT32MidiConf(const Game: TGame; const Dest: TStrings; const IsStaging: Boolean); forward;

Function ProfileShaderSelected(const Game: TGame): Boolean;
Var S: String;
begin
  If not PrgSetup.AllowPixelShader then begin result:=False; exit; end;
  S:=Trim(Game.PixelShader);
  result:=(S<>'') and (ExtUpperCase(S)<>'NONE');
end;

Procedure GenerateGraphicsConf(const Game: TGame; const Dest: TStrings);
Var S, OutputVal, ShaderVal: String;
    I: Integer;
begin
  OutputVal:=Trim(Game.Render);
  If not IsValidConfOptValue(Game.GameDB.ConfOpt.Render,OutputVal) then
    OutputVal:='opengl';
  ShaderVal:=Trim(Game.PixelShader);

  Dest.Add('');
  Dest.Add('[render]');
  If not Game.IsStaging then begin
    Dest.Add('frameskip='+IntToStr(Game.FrameSkip));
    Dest.Add('scaler='+Game.Scale);
  end;
  If not Game.IsPure then
    Dest.Add('aspect='+BoolToStr(Game.AspectCorrection));
  If ProfileShaderSelected(Game) and (Game.IsDBX or Game.IsStaging) then begin
    If Game.IsStaging then begin
      S:=FormatStagingShaderConfValue(ShaderVal,Trim(Game.ShaderPreset),
        not Game.IsOldStaging);
      If S<>'' then begin
        If Game.IsNewStaging then
          Dest.Add('shader='+S);
        Dest.Add('glshader='+S);
      end;
    end else if Game.IsDBX then begin
      S:=Trim(ShaderVal);
      S:=StringReplace(S,'\','/',[rfReplaceAll]);
      If ExtUpperCase(OutputVal)='DIRECT3D' then begin
        Dest.Add('pixelshader='+S+' forced');
        Dest.Add('glshader=none');
      end else begin
        Dest.Add('glshader='+S);
        Dest.Add('pixelshader=none');
      end;
    end;
  end;

  If Game.IsDBX then begin
    S:=Trim(Game.VSync);
    If S<>'' then begin
      Dest.Add('');
      Dest.Add('[vsync]');
      Dest.Add('vsyncmode='+S);
    end;
  end;

  If PrgSetup.AllowVGAChipsetSettings and Game.IsDBX then begin
    I:=Game.VideoRam;
    if (I mod 1024)<>0 then I:=(I div 1024)+1 else I:=I div 1024;
    Dest.Add('');
    Dest.Add('[video]');
    Dest.Add('vmemsize='+IntToStr(I));
  end;
end;

Procedure GenerateCoreMidiConf(const Game: TGame; const Dest: TStrings; const IsStaging: Boolean);
Var S: String;
    I: Integer;
begin
  if Game.IsStaging then begin
    S:=Game.GetValidMidiDevice;
    if SameText(S,'soundfont') then
      S:='fluidsynth';
  end else if Game.IsDBX and Game.MIDIDeviceIs('soundfont') then
    S:='fluidsynth'
  else
    S:=Game.MIDIDevice;
  Dest.Add('mididevice='+S);
  Dest.Add('midiconfig='+MakeDOSBoxMIDIString(Game.MIDIConfig));
  If Game.IsDBX and Game.MIDIDeviceIs('soundfont') then begin
    S:=Trim(Game.FluidSoundFont);
    If S<>'' then begin
      S:=MakeAbsPath(S,PrgSetup.BaseDir);
      S:=StringReplace(S,'\','/',[rfReplaceAll]);
      Dest.Add('fluid.soundfont='+S);
    end;
    If Game.GetValidMidiGain(I) then
      Dest.Add('fluid.gain='+FloatToStrF(I/100.0,ffGeneral,15,4));
  end;
  If Game.IsDBX and Game.MIDIDeviceIs('mt32') then begin
    S:=Trim(Game.MIDIMT32RomDir);
    If S<>'' then begin
      S:=MakeAbsPath(S,PrgSetup.BaseDir);
      S:=StringReplace(S,'\','/',[rfReplaceAll]);
      Dest.Add('mt32.romdir='+S);
    end;
    S:=Trim(Game.MIDIMT32Model);
    If S='' then S:='auto';
    Dest.Add('mt32.model='+S);
    S:=Trim(Game.MIDIMT32Mode);
    If S='' then S:='auto';
    Dest.Add('mt32.reverb.mode='+S);
    S:=Trim(Game.MIDIMT32Time);
    If S='' then S:='5';
    Dest.Add('mt32.reverb.time='+S);
    S:=Trim(Game.MIDIMT32Level);
    If S='' then S:='3';
    Dest.Add('mt32.reverb.level='+S);
    If Game.GetValidMidiGain(I) then
      Dest.Add('mt32.output.gain='+IntToStr(I));
  end;
end;

Procedure GenerateFluidMidiConf(const Game: TGame; const Dest: TStrings; const IsStaging, IsOldStaging: Boolean);
Var S: String;
    I: Integer;
begin
  { Staging: [fluidsynth] when profile device is soundfont.
      IsOldStaging: soundfont=path [percent]
      Staging 0.83+: soundfont=path + optional soundfont_volume=percent }
  If Game.IsStaging and Game.MIDIDeviceIs('soundfont') then begin
    S:=Trim(Game.FluidSoundFont);
    If S<>'' then begin
      S:=MakeAbsPath(S,PrgSetup.BaseDir);
      S:=StringReplace(S,'\','/',[rfReplaceAll]);
      Dest.Add('');
      Dest.Add('[fluidsynth]');
      If Game.IsOldStaging and Game.GetValidMidiGain(I) then
        S:=S+' '+IntToStr(I);
      Dest.Add('soundfont='+S);
      If (not Game.IsOldStaging) and Game.GetValidMidiGain(I) then
        Dest.Add('soundfont_volume='+IntToStr(I));
    end;
  end;
end;

Procedure GenerateMT32MidiConf(const Game: TGame; const Dest: TStrings; const IsStaging: Boolean);
Var S: String;
begin
  { Staging: [mt32] when mididevice=mt32 (old and new: model + optional romdir). }
  If Game.IsStaging and Game.MIDIDeviceIs('mt32') then begin
    Dest.Add('');
    Dest.Add('[mt32]');
    S:=Trim(Game.MIDIMT32Model);
    If S='' then S:='auto';
    Dest.Add('model='+S);
    S:=Trim(Game.MIDIMT32RomDir);
    If S<>'' then begin
      S:=MakeAbsPath(S,PrgSetup.BaseDir);
      S:=StringReplace(S,'\','/',[rfReplaceAll]);
      Dest.Add('romdir='+S);
    end;
  end;
end;

Procedure GenerateMidiConf(const Game: TGame; const Dest: TStrings; const DOSBoxVersion: Double; const IsStaging, IsOldStaging: Boolean);
begin
  Dest.Add('');
  Dest.Add('[midi]');
  Dest.Add('mpu401='+Game.MIDIType);
  If Game.IsPure then exit;
  If DOSBoxVersion>0.72 then
    GenerateCoreMidiConf(Game,Dest,IsStaging)
  else begin
    Dest.Add('device='+Game.MIDIDevice);
    Dest.Add('config='+MakeDOSBoxMIDIString(Game.MIDIConfig));
    If Game.MIDIDeviceIs('mt32') then begin
      Dest.Add('mt32reverb.mode='+Game.MIDIMT32Mode);
      Dest.Add('mt32reverb.time='+Game.MIDIMT32Time);
      Dest.Add('mt32reverb.level='+Game.MIDIMT32Level);
    end;
  end;

  GenerateFluidMidiConf(Game,Dest,IsStaging,IsOldStaging);
  GenerateMT32MidiConf(Game,Dest,IsStaging);
end;

Procedure GenerateSoundDeviceConf(const Game: TGame; const Dest: TStrings; const DOSBoxVersion: Double);
begin
  Dest.Add('');
  Dest.Add('[sblaster]');
  Dest.Add('sbtype='+Game.SBType);
  Dest.Add('sbbase='+Game.SBBase);
  Dest.Add('irq='+IntToStr(Game.SBIRQ));
  Dest.Add('dma='+IntToStr(Game.SBDMA));
  Dest.Add('hdma='+IntToStr(Game.SBHDMA));
  If DOSBoxVersion>0.72
    then Dest.Add('sbmixer='+BoolToStr(Game.SBMixer))
    else Dest.Add('mixer='+BoolToStr(Game.SBMixer));
  Dest.Add('oplmode='+Game.SBOplMode);
  { Staging: oplrate/oplemu deprecated — omit (old and new). }
  If not Game.IsStaging then begin
    Dest.Add('oplrate='+IntToStr(Game.SBOplRate));
    If DOSBoxVersion>0.72 then Dest.Add('oplemu='+Game.SBOplEmu);
  end;

  Dest.Add('');
  Dest.Add('[gus]');
  Dest.Add('gus='+BoolToStr(Game.GUS));
  { Staging: gusrate invalid — omit (old and new). }
  If not Game.IsStaging then
    Dest.Add('gusrate='+IntToStr(Game.GUSRate));
  Dest.Add('gusbase='+Game.GUSBase);
  If DOSBoxVersion>0.72 then begin
    Dest.Add('gusirq='+IntToStr(Game.GUSIRQ));
    Dest.Add('gusdma='+IntToStr(Game.GUSDMA));
  end
  else begin
    Dest.Add('irq1='+IntToStr(Game.GUSIRQ));
    Dest.Add('irq2='+IntToStr(Game.GUSIRQ));
    Dest.Add('dma1='+IntToStr(Game.GUSDMA));
    Dest.Add('dma2='+IntToStr(Game.GUSDMA));
  end;
  Dest.Add('ultradir='+Game.GUSUltraDir);

  Dest.Add('');
  Dest.Add('[speaker]');
  { Staging: pcspeaker is impulse/discrete/none (not true/false). }
  If Game.IsStaging
    then Dest.Add('pcspeaker='+StagingMapPCSpeaker(Game.SpeakerPC))
    else Dest.Add('pcspeaker='+BoolToStr(Game.SpeakerPC));
  { Staging: pcrate/tandyrate invalid — omit (old and new). }
  If not Game.IsStaging then
    Dest.Add('pcrate='+IntToStr(Game.SpeakerRate));
  Dest.Add('tandy='+Game.SpeakerTandy);
  If not Game.IsStaging then
    Dest.Add('tandyrate='+IntToStr(Game.SpeakerTandyRate));
  { Staging: disney moved to lpt_dac; only emit when Disney is enabled in profile. }
  If Game.IsStaging then begin
    If Game.SpeakerDisney then
      Dest.Add('lpt_dac=disney');
  end
  else
    Dest.Add('disney='+BoolToStr(Game.SpeakerDisney));
end;

Procedure GenerateInnovaConf(const Game: TGame; const Dest: TStrings; const IsStaging, IsOldStaging: Boolean);
Var I: Integer;
begin
  { Innova / Innovation SSI-2001. Profile fields unchanged (Innova / Rate / Base / Quality).
    Conf is kind-gated:
      standard/X → classic [innova] innova/samplerate/sidbase/quality
      Staging old (<0.83) → [innovation] sidmodel/sidclock/sidport + 6581/8580filter %
      Staging new (0.83+) → [innovation] innovation/innovation_sid_filter/innovation_filter
                   (InnovaRate has no Staging home → omit; port only on old Staging) }
  if PrgSetup.AllowInnova then begin
    If Game.IsStaging then begin
      Dest.Add('');
      Dest.Add('[innovation]');
      { Quality 0..3 → best-effort SID filter strength % (not classic reSID quality). }
      Case Game.InnovaQuality of
        0: I:=0;
        1: I:=33;
        2: I:=50;
        3: I:=100;
        else I:=50;
      end;
      If Game.IsOldStaging then begin
        If Game.Innova then begin
          Dest.Add('sidmodel=auto');
          Dest.Add('sidclock=default');
          Dest.Add('sidport='+Game.InnovaBase);
          Dest.Add('6581filter='+IntToStr(I));
          Dest.Add('8580filter='+IntToStr(I));
          Dest.Add('innovation_filter=off');
        end else
          Dest.Add('sidmodel=none');
      end
      else begin
        { 0.83+: innovation bool, innovation_sid_filter % (replaces 6581filter), filter off. }
        Dest.Add('innovation='+BoolToStr(Game.Innova));
        If Game.Innova then begin
          Dest.Add('innovation_sid_filter='+IntToStr(I));
          Dest.Add('innovation_filter=off');
        end;
      end;
    end
    else begin
      Dest.Add('');
      Dest.Add('[innova]');
      Dest.Add('innova='+BoolToStr(Game.Innova));
      Dest.Add('samplerate='+IntToStr(Game.InnovaRate));
      Dest.Add('sidbase='+Game.InnovaBase);
      Dest.Add('quality='+IntToStr(Game.InnovaQuality));
    end;
  end;
end;

Procedure GenerateSDLConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer; const BuildForArchivePackage: Boolean);
Var S, T, OutputVal, ShaderVal: String;
    I: Integer;
    ShaderActive: Boolean;
begin
  OutputVal:=Trim(Game.Render);
  If OutputVal='' then OutputVal:='opengl';
  ShaderActive:=ProfileShaderSelected(Game);
  ShaderVal:=Trim(Game.PixelShader);

  Dest.Add('[sdl]');
  { Pure host window is screen_* in DOSBoxPure.cfg, not [sdl] fullscreen/resolution. }
  If not Game.IsPure then
    Dest.Add('fullscreen='+BoolToStr(Game.StartFullscreen));
  { Staging (any): fulldouble/usescancodes never valid. }
  If not Game.IsStaging then
    Dest.Add('fulldouble='+BoolToStr(Game.UseDoublebuffering));
  { Staging 0.83+: fullresolution removed → fullscreen_mode; windowresolution
    deprecated → window_size. Old Staging / non-Staging keep classic keys. }
  If Game.IsNewStaging then begin
    S:=Trim(ExtLowerCase(Game.FullscreenResolution));
    If (S='forced-borderless') or (S='forced_borderless') then
      Dest.Add('fullscreen_mode=forced-borderless')
    else
      { desktop/original/0x0/WxH: no 0.83 resolution-mode equivalent. }
      Dest.Add('fullscreen_mode=standard');
    S:=Trim(Game.WindowResolution);
    If (S='') or SameText(S,'original') then
      Dest.Add('window_size=default')
    else
      Dest.Add('window_size='+S);
  end else If not Game.IsPure then begin
    Dest.Add('fullresolution='+Game.FullscreenResolution);
    S:=Trim(Game.WindowResolution);
    If Game.IsOldStaging and ((S='') or SameText(S,'original')) then
      S:='default';
    Dest.Add('windowresolution='+S);
  end;
  { Staging: window_position; X: windowposition. Trial placement keys. }
  If Game.IsStaging then
    Dest.Add('window_position=auto')
  else If Game.DosBoxKind=dbkX then
    Dest.Add('windowposition=centered');
  Dest.Add('output='+OutputVal);
  { Staging: autolock is invalid; mapped to [mouse] mouse_capture below. }
  If not Game.IsStaging then
    Dest.Add('autolock='+BoolToStr(Game.AutoLockMouse));
  { Staging: sensitivity moved to [mouse] mouse_sensitivity. }
  If not Game.IsStaging then
    Dest.Add('sensitivity='+IntToStr(Game.MouseSensitivity));
  { Staging (any): usescancodes invalid. }
  If not Game.IsStaging then
    Dest.Add('usescancodes='+BoolToStr(Game.UseScanCodes));
  { waitonerror/priority: still valid on old Staging; removed only on 0.83+. }
  If not Game.IsNewStaging then begin
    Dest.Add('waitonerror='+BoolToStr(PrgSetup.DOSBoxSettings[DOSBoxNr].WaitOnError));
    { Staging old: priority is space-separated active/inactive (not comma).
      X: inactive half from OnScreenInactive — pause or normal (no mute). }
    If Game.IsStaging then
      Dest.Add('priority='+StagingMapPriority(Game.Priority))
    else If Game.DosBoxKind=dbkX then begin
      S:=Trim(Game.Priority);
      I:=Pos(',',S);
      If I>0 then S:=Trim(Copy(S,1,I-1)) else If S='' then S:='higher';
      If S='' then S:='higher';
      If Game.OnScreenInactive=Ord(simPause) then
        Dest.Add('priority='+S+',pause')
      else
        Dest.Add('priority='+S+',normal');
    end else
      Dest.Add('priority='+Game.Priority);
  end;
  S:=Trim(Game.CustomKeyMappingFile);
  If (S='') or (ExtUpperCase(S)='DEFAULT') then S:=PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxMapperFile;
  T:=UnmapDrive(MakeAbsPath(S,PrgDataDir),ptMapper);
  if BuildForArchivePackage then T:=MakeRelPath(T,PrgDataDir);
  Dest.Add('mapperfile='+T);
  { Staging: [sdl] vsync=auto|on|adaptive|off|yield (not fulldouble).
    Empty profile value → omit key (emulator default). }
  If Game.IsStaging then begin
    S:=Trim(Game.VSync);
    If S<>'' then Dest.Add('vsync='+S);
    Case Game.OnScreenInactive of
      Ord(simMute): begin
        Dest.Add('mute_when_inactive=true');
        Dest.Add('pause_when_inactive=false');
      end;
      Ord(simPause): begin
        Dest.Add('mute_when_inactive=false');
        Dest.Add('pause_when_inactive=true');
      end;
      else begin
        Dest.Add('mute_when_inactive=false');
        Dest.Add('pause_when_inactive=false');
      end;
    end;
  end;
  { Standard DOSBox (and unknown): pixelshader under [sdl], with .fx suffix.
    Staging/X shaders go under [render] below. Pure uses interface_crtfilter in cfg.
    No selection → no key. }
  If ShaderActive and not (Game.DosBoxKind in [dbkX,dbkStaging,dbkPure]) then begin
    S:=ShaderVal;
    If ExtUpperCase(ExtractFileExt(S))<>'.FX' then S:=S+'.fx';
    Dest.Add('# Shader file extension (.fx) written explicitly for standard DOSBox');
    Dest.Add('pixelshader='+S);
  end;
end;

Procedure GenerateCoreDOSBoxConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer; const DOSBoxVersion: Double; const BuildForArchivePackage: Boolean; const DeleteOnExit: TStringList);
Var S, T, CapturePath: String;
    I: Integer;
begin
  Dest.Add('');
  Dest.Add('[dosbox]');
  S:=Trim(ExtUpperCase(Game.CustomDOSBoxLanguage));
  If S<>'ENGLISH' then begin
    If (S='') or (S='DEFAULT') then S:='' else begin
      T:=Game.GetDBInstallPath;
      If (T<>'') and FileExists(T+S) then S:=T+S else begin
        If not FileExists(S) then S:='';
      end;
    end;
    If S='' then S:=PrgSetup.DOSBoxSettings[DOSBoxNr].DosBoxLanguage;

    T:=ExtractFileName(S);
    If FileExists(PrgDataDir+LanguageSubDir+'\'+T) then S:=PrgDataDir+LanguageSubDir+'\'+T;
    {Check if language file is on network share (which DOSBox can't handle)}
    If Copy(S,1,2)='\\' then begin
      if Assigned(DeleteOnExit) then begin
        CopyFile(PChar(S),PChar(TempDir+ExtractFileName(S)),False);
        DeleteOnExit.Add(TempDir+ExtractFileName(S));
      end;
      S:=TempDir+ExtractFileName(S);
      T:=UnmapDrive(S,ptDOSBox);
      if BuildForArchivePackage then begin
        T:=MakeRelPath(T,PrgDataDir);
        if BuildForArchivePackage and (Copy(T,2,1)=':') then T:=ExtractFileName(T); {Completly remove path if its not possible to make the path realtive.}
      end;
      Dest.Add('language='+T);
    end else begin
      T:=UnmapDrive(S,ptDOSBox);
      if BuildForArchivePackage then begin
        T:=MakeRelPath(T,PrgDataDir);
        if BuildForArchivePackage and (Copy(T,2,1)=':') then T:=ExtractFileName(T); {Completly remove path if its not possible to make the path realtive.}
      end;
      If FileExists(S) then Dest.Add('language='+T);
    end;
  end;
  S:=Game.VideoCard; T:=Trim(ExtUpperCase((S)));
  { X synthetic VideoCard tokens. }
  If (Game.DosBoxKind=dbkX) and ((T='DOSV') or (T='DOS/V')) then
    S:='svga_s3'
  else If (Game.DosBoxKind=dbkX) and (T='PC98') then
    S:='pc98'
  else If DOSBoxVersion>0.72 then begin
    If T='VGA' then S:='svga_s3';
  end else begin
    If (T='VGAONLY') or (T='SVGA_S3') or (T='SVGA_ET3000') or (T='SVGA_ET4000') or (T='SVGA_PARADISE') or (T='VESA_NOLFB') or (T='VESA_OLDVBE') then S:='vga';
  end;
  Dest.Add('machine='+S);
  CapturePath:=UnmapDrive(MakeAbsPath(Game.CaptureFolder,PrgSetup.BaseDir),ptScreenshot);
  if BuildForArchivePackage then CapturePath:=MakeRelPath(CapturePath,PrgDataDir);
  { Staging: captures moved to [capture] capture_dir. }
  If not Game.IsStaging then
    Dest.Add('captures='+CapturePath);
  Dest.Add('memsize='+IntToStr(Game.Memory));
  { Video RAM (Game.VideoRam is KB → MB). Kind-gated homes:
      standard/Staging → [dosbox] vmemsize=
      X               → [video] vmemsize= (written later; not under [dosbox]) }
  If PrgSetup.AllowVGAChipsetSettings and (Game.DosBoxKind<>dbkX) then begin
    I:=Game.VideoRam;
    if (I mod 1024)<>0 then I:=(I div 1024)+1 else I:=I div 1024;
    Dest.Add('vmemsize='+IntToStr(I));
  end;
end;

Function NormalizeGlideEmulation(const Game: TGame): String;
Var S: String;
begin
  S:=Trim(ExtUpperCase(Game.GlideEmulation));
  If (S='TRUE') or (S='1') or (S='ON') then Result:='true'
  else If (S='FALSE') or (S='0') or (S='OFF') or (S='') or (S='-1') then Result:='false'
  else Result:=Trim(ExtLowerCase(Game.GlideEmulation));
end;

Function IsGlideOn(const Game: TGame): Boolean;
begin
  { Same for all kinds: Activate and emulation is true or emu. }
  Result:=Game.isGlideEnabled;
end;

Function GlideMemIs4(const Mem: String): Boolean;
begin
  Result:=(Trim(Mem)='4');
end;

Function GlideStagingMemSize(const Mem: String): String;
Var M: String;
begin
  M:=Trim(Mem);
  If M='12' then Result:='12' else Result:='4';
end;

Function GlidePureVoodooMem(const Mem: String): String;
Var M: String;
begin
  M:=Trim(Mem);
  If M='4' then Result:='4mb'
  else If M='12' then Result:='12mb'
  else Result:='8mb';
end;

Function GlideBoolFromProfile(const Value, DefaultTrue: String): String;
Var S: String;
begin
  S:=Trim(ExtLowerCase(Value));
  If (S='') or (S='-1') then S:=Trim(ExtLowerCase(DefaultTrue));
  If (S='false') or (S='0') or (S='off') then Result:='false' else Result:='true';
end;

Procedure GenerateGlideConf(const Game: TGame; const Dest: TStrings);
Var S, Mem, LFB, Card, Threads, Bilin: String;
    On: Boolean;
begin
  S:=NormalizeGlideEmulation(Game);
  On:=IsGlideOn(Game);
  Mem:=Trim(Game.GlideVoodooMem);
  If Mem='-1' then Mem:='';
  LFB:=Trim(Game.GlideLFB);
  If LFB='-1' then LFB:='';
  Card:=Trim(Game.GlideVoodooCard);
  If (Card='') or (Card='-1') then Card:='auto';
  Threads:=Trim(Game.GlideVoodooThreads);
  If (Threads='') or (Threads='-1') then Threads:='auto';
  Bilin:=GlideBoolFromProfile(Game.GlideBilinear,'true');

  Case Game.DosBoxKind of
    dbkX: begin
      Dest.Add('');
      Dest.Add('[voodoo]');
      If LFB='' then LFB:='full';
      If not On then begin
        Dest.Add('glide=false');
        Dest.Add('voodoo_card=false');
      end else If S='emu' then begin
        Dest.Add('glide=false');
        Dest.Add('voodoo_card='+Card);
        If GlideMemIs4(Mem) then
          Dest.Add('voodoo_maxmem=false')
        else
          Dest.Add('voodoo_maxmem=true');
      end else begin
        Dest.Add('glide=true');
        Dest.Add('voodoo_card='+Card);
        Dest.Add('lfb='+LFB);
        If GlideMemIs4(Mem) then
          Dest.Add('voodoo_maxmem=false')
        else
          Dest.Add('voodoo_maxmem=true');
      end;
    end;
    dbkStaging: begin
      Dest.Add('');
      Dest.Add('[voodoo]');
      If not On then
        Dest.Add('voodoo=false')
      else begin
        Dest.Add('voodoo=true');
        If Game.IsNewStaging then begin
          Dest.Add('voodoo_memsize='+GlideStagingMemSize(Mem));
          Dest.Add('voodoo_threads='+Threads);
          Dest.Add('voodoo_bilinear_filtering='+Bilin);
        end;
      end;
    end;
    dbkPure: begin
    end;
    else begin
      { Classic / unknown — ./orig when on: glide=S + grport + lfb; when off: glide=false only }
      Dest.Add('');
      Dest.Add('[glide]');
      If not On then
        Dest.Add('glide=false')
      else begin
        Dest.Add('glide='+S);
        Dest.Add('grport='+Game.GlidePort);
        Dest.Add('lfb='+Game.GlideLFB);
      end;
    end;
  end;
end;

Procedure GeneratePureGlideCfg(const Game: TGame; const Cfg: TStrings);
Var Mem, Perf, Scale, Gamma: String;
begin
  If not IsGlideOn(Game) then begin
    Cfg.Add('"dosbox_pure_voodoo" : "off"');
    exit;
  end;
  Mem:=GlidePureVoodooMem(Game.GlideVoodooMem);
  Cfg.Add('"dosbox_pure_voodoo" : "'+Mem+'"');
  Perf:=Trim(Game.GlidePurePerf);
  If (Perf='') or (Perf='-1') then Perf:='auto';
  Cfg.Add('"dosbox_pure_voodoo_perf" : "'+Perf+'"');
  Scale:=Trim(Game.GlideVoodooScale);
  If (Scale<>'') and (Scale<>'-1') then
    Cfg.Add('"dosbox_pure_voodoo_scale" : "'+Scale+'"');
  Gamma:=Trim(Game.GlideVoodooGamma);
  If (Gamma<>'') and (Gamma<>'-1') then
    Cfg.Add('"dosbox_pure_voodoo_gamma" : "'+Gamma+'"');
end;

Procedure GenerateNetworkConf(const Game: TGame; const Dest: TStrings);
Var S: String;
begin
  { Profile fields unchanged (NE2000 / Base / IRQ / MAC / RealInterface). Conf is kind-gated:
      standard → [ne2000] ne2000/nicbase/nicirq/macaddr/realnic (classic)
      Staging → [ethernet] ne2000/nicbase/nicirq/macaddr (slirp only; no realnic)
      X       → [ne2000] ne2000/nicbase/nicirq/macaddr;
                if RealInterface set → backend=pcap + [ethernet, pcap] realnic=
                (empty RealInterface → omit backend; X defaults to auto/slirp) }
  Case Game.DosBoxKind of
    dbkStaging: begin
      Dest.Add('');
      Dest.Add('[ethernet]');
      Dest.Add('ne2000='+BoolToStr(Game.NE2000));
      Dest.Add('nicbase='+Game.NE2000Base);
      Dest.Add('nicirq='+IntToStr(Game.NE2000IRQ));
      Dest.Add('macaddr='+Game.NE2000MACAddress);
    end;
    dbkX: begin
      Dest.Add('');
      Dest.Add('[ne2000]');
      Dest.Add('ne2000='+BoolToStr(Game.NE2000));
      Dest.Add('nicbase='+Game.NE2000Base);
      Dest.Add('nicirq='+IntToStr(Game.NE2000IRQ));
      Dest.Add('macaddr='+Game.NE2000MACAddress);
      S:=Trim(Game.NE2000RealInterface);
      If S<>'' then begin
        Dest.Add('backend=pcap');
        Dest.Add('');
        Dest.Add('[ethernet, pcap]');
        Dest.Add('realnic='+S);
      end;
    end;
    else begin
      Dest.Add('');
      Dest.Add('[ne2000]');
      Dest.Add('ne2000='+BoolToStr(Game.NE2000));
      Dest.Add('nicbase='+Game.NE2000Base);
      Dest.Add('nicirq='+IntToStr(Game.NE2000IRQ));
      Dest.Add('macaddr='+Game.NE2000MACAddress);
      Dest.Add('realnic='+Game.NE2000RealInterface);
    end;
  end;
end;

Procedure GenerateMSDOSConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer);
Var S, T: String;
begin
  Dest.Add('');
  Dest.Add('[dos]');
  Dest.Add('xms='+BoolToStr(Game.XMS));
  Dest.Add('ems='+BoolToStr(Game.EMS));
  Dest.Add('umb='+BoolToStr(Game.UMB));

  T:=Trim(ExtUpperCase(Game.KeyboardLayout));
  If (T='') or (T='DEFAULT') then begin
    T:=Trim(ExtUpperCase(PrgSetup.DOSBoxSettings[DOSBoxNr].KeyboardLayout));
    If (T='') or (T='DEFAULT') then
      If Game.IsStaging or (Game.DosBoxKind=dbkX) then T:='auto' else T:=LanguageSetup.GameKeyboardLayoutDefault;
  end;
  If Pos('(',T)>0 then begin
    S:=Copy(T,Pos('(',T)+1,MaxInt);
    If Pos(')',S)>0 then begin S:=Trim(Copy(S,1,Pos(')',S)-1)); If S<>'' then T:=S; end;
  end;
  If ExtUpperCase(T)='NONE' then T:='none'; {DOSBox keyb accepts GR and gr but not NONE}
  { Staging 0.83+: keyboardlayout renamed to keyboard_layout.
    Staging/X: always country with layout (auto or explicit); no autoexec keyb. }
  If Game.IsNewStaging then
    Dest.Add('keyboard_layout='+T)
  else
    Dest.Add('keyboardlayout='+T); {classic: also via keyb in autoexec if keyb fails on codepage}
  If Game.IsStaging or (Game.DosBoxKind=dbkX) then
    Dest.Add('country=auto');

  { Staging/X: modern [dos] ver= (same key both forks; 0.82 and 0.83 Staging).
    Standard keeps autoexec "ver set". Empty/default/auto → omit. }
  If Game.DosBoxKind in [dbkStaging,dbkX] then begin
    S:=Trim(Game.ReportedDOSVersion);
    If (S<>'') and not SameText(S,'default') and not SameText(S,'auto') then
      Dest.Add('ver='+S);
  end;

  {keyboardlayout can't handle layout+codepage -> moved to autoexec as keyb command
  S:=Trim(ExtUpperCase(Game.Codepage));
  If (S='') or (S='DEFAULT') then S:=LanguageSetup.GameKeyboardCodepageDefault;
  Dest.Add('keyboardlayout='+T+' '+S);}
end;

Procedure GenerateSpecialMachineConf(const Game: TGame; const Dest: TStrings);
Var T: String;
begin
  { DOSBox-X: PC98 / DOS/V synthetic machine defaults. }
  If Game.DosBoxKind=dbkX then begin
    T:=Trim(ExtUpperCase(Game.VideoCard));
    If T='PC98' then begin
      Dest.Add('');
      Dest.Add('[pc98]');
      Dest.Add('pc-98 fm board=auto');
      Dest.Add('pc-98 enable 256-color=true');
      Dest.Add('pc-98 enable 16-color=true');
      Dest.Add('pc-98 enable grcg=true');
      Dest.Add('pc-98 enable egc=true');
      Dest.Add('pc-98 bus mouse=true');
      Dest.Add('pc-98 force ibm keyboard layout=auto');
      Dest.Add('pc-98 force JIS keyboard layout=false');
      Dest.Add('pc-98 try font rom=true');
    end else If (T='DOSV') or (T='DOS/V') then begin
      Dest.Add('');
      Dest.Add('[dosv]');
      Dest.Add('dosv=jp');
      Dest.Add('getsysfont=true');
      Dest.Add('showdbcsnodosv=auto');
      Dest.Add('fepcontrol=both');
      Dest.Add('vtext1=svga');
      Dest.Add('vtext2=xga');
      Dest.Add('use20pixelfont=false');
      Dest.Add('j3100=off');
    end;
  end;
end;

Procedure GenerateCPUConf(const Game: TGame; const Dest: TStrings; const DOSBoxVersion: Double);
Var S: String;
    I: Integer;
begin
  Dest.Add('');
  Dest.Add('[cpu]');
  Dest.Add('core='+Game.Core);
  If Trim(Game.CPUType)<>'' then Dest.Add('cputype='+Game.CPUType);

  If Game.IsStaging then begin
    S:=Trim(Game.Cycles);
    If SameText(S,'auto') or (S='') then
      Dest.Add('# cycles=auto')
    else
      Dest.Add('cpu_cycles='+S);
  end else If DOSBoxVersion>0.72 then begin
    If TryStrToInt(Game.Cycles,I) then Dest.Add('cycles=fixed '+Game.Cycles) else Dest.Add('cycles='+Game.Cycles);
  end else begin
    Dest.Add('cycles='+Game.Cycles);
  end;
  Dest.Add('cycleup='+IntToStr(Game.CyclesUp));
  Dest.Add('cycledown='+IntToStr(Game.CyclesDown));
end;

Procedure GenerateAutoExecKeyboardConf(const Game: TGame; const Dest: TStrings; const DOSBoxNr: Integer);
Var S, T, U: String;
begin
  T:=Trim(ExtUpperCase(Game.KeyboardLayout));
  If (T='') or (T='DEFAULT') then begin
    T:=Trim(ExtUpperCase(PrgSetup.DOSBoxSettings[DOSBoxNr].KeyboardLayout));
    If (T='') or (T='DEFAULT') then
      If Game.DosBoxKind in [dbkStaging,dbkX] then T:='auto' else T:=LanguageSetup.GameKeyboardLayoutDefault;
  end;
  If Pos('(',T)>0 then begin
    S:=Copy(T,Pos('(',T)+1,MaxInt);
    If Pos(')',S)>0 then begin S:=Trim(Copy(S,1,Pos(')',S)-1)); If S<>'' then T:=S; end;
  end;

  S:=Trim(ExtUpperCase(Game.Codepage));
  If (S='') or (S='DEFAULT') then begin
    S:=Trim(ExtUpperCase(PrgSetup.DOSBoxSettings[DOSBoxNr].Codepage));
    If (S='') or (S='DEFAULT') then S:=LanguageSetup.GameKeyboardCodepageDefault;
  end;
  If Pos('(',S)>0 then begin
    S:=Copy(S,1,Pos('(',S)-1);
  end;

  If ExtUpperCase(T)='NONE' then T:='none'; {DOSBox keyb accepts GR and gr but not NONE}

  If (ExtUpperCase(T)='AUTO') and not (Game.DosBoxKind in [dbkStaging,dbkX]) then begin
    T:=Trim(ExtUpperCase(PrgSetup.DOSBoxSettings[DOSBoxNr].KeyboardLayout));
    If (T='') or (T='DEFAULT') then T:=LanguageSetup.GameKeyboardLayoutDefault;
    If Pos('(',T)>0 then begin
      U:=Copy(T,Pos('(',T)+1,MaxInt);
      If Pos(')',U)>0 then begin U:=Trim(Copy(U,1,Pos(')',U)-1)); If U<>'' then T:=U; end;
    end;
  end;

  { Staging/X: layout/country only via [dos]; never autoexec keyb (default or explicit). }
  If not (Game.DosBoxKind in [dbkStaging,dbkX]) then
    If ExtUpperCase(T)<>'AUTO' then
      Dest.Add('keyb '+T+' '+S{+' > nul'}); {no "> nul" to display possible error message if layout and codepage do not match}

  { Reported DOS version: Staging/X use [dos] ver= in BuildConfFile; classic keeps autoexec. }
end;

Procedure GenerateAutoExecDOSVerConf(const Game: TGame; const Dest: TStrings);
Var S, T: String;
begin
  If not (Game.DosBoxKind in [dbkStaging,dbkX]) then begin
    S:=Trim(ExtUpperCase(Game.ReportedDOSVersion));
    If (S<>'') and (S<>'DEFAULT') and (S<>'AUTO') then begin
      If Pos('.',S)<>0 then begin T:=Trim(Copy(S,Pos('.',S)+1,MaxInt)); S:=Trim(Copy(S,1,Pos('.',S)-1)); end else begin T:=''; end;
      Dest.Add('ver set '+S+' '+T);
    end;
  end;
end;

end.
