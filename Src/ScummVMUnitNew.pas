unit ScummVMUnitNew;
interface

uses Classes, GameDBUnit, IniFiles, Windows, CommonTools;

{DEFINE AddDFRPrefixInRunMode}

{
  ScummVM launcher unit for D-Fend Reloaded / dfendx.

  Approach: write a temporary scummvm.ini for the profile (BuildScummVMIniFile)
  and launch with a short command line that only points at that config:

    scummvm.exe --config="<temp>\scummvm.ini" [--no-console] [extra…] <target>

  All game settings (paths, volumes, music_driver, mt32_device, gm_device,
  soundfont, native_mt32, enable_gs, multi_midi, gfx/scaler, render_mode,
  platform, etc.) live in the generated config — not as CLI flags.

  Updated for modern ScummVM (2.7+ through 2026.x) ConfMan keys.
}

Procedure RunScummVMGame(const Game : TGame);

Function BuildScummVMIniFile(const Game : TGame; const RunMode : Boolean = False) : TStringList;

{ Minimal argv after the executable: optional user extras, --config, --no-console, target.
  RenderMode / DataPlatform are accepted for API compatibility with callers that still
  pass them; they are already written into the config by BuildScummVMIniFile and are
  not re-emitted on the command line. }
Function GetScummVMCommandLine(const INIFile, GameName, AdditionalCommandLine,
  RenderMode, DataPlatform : String; const ScreenshotPath : String = '';
  const GamePath : String = ''; const Game : TGame = nil) : String;

Function FindScummVMIni(UseSecondOne : Boolean = False) : String;

Procedure AddKeysFromDefaultScummVMIni(const St1, St2 : TStringList; const Ini : TIniFile; const GameName : String);
Function FindTheme(const ScummVMPath : String) : String;
Function RunScummVM(const INIFile, GameName, AdditionalCommandLine : String;
  const FullScreen : Boolean; const GameDir, ScreenshotDir, RenderMode,
  DataPlatform : String; const asAdmin : Boolean; const Game : TGame = nil) : THandle;

{ Helpers exported for profile UI / tests }
Function ScummVMExtractOptionValue(const S : String) : String;
Function ScummVMBoolStr(const B : Boolean) : String;
Procedure ScummVMSplitGameId(const Stored : String; out Engine, GameId : String);

Var MinimizedAtScummVMStart : Boolean = False;

implementation

uses Forms, Dialogs, SysUtils, ShellAPI, ShlObj, PrgSetupUnit,
     CommonHelpers, PrgConsts, GameDBToolsUnit, LanguageSetupUnit,
     ScummVMToolsUnit, ZipManagerUnit, DOSBoxCountUnit, RunPrgManagerUnit,
     HistoryUnit, System.UITypes, BassMedia,
     ModernProfileEditorScummVMSettingsHelpers, ScummVMGameOptions;

{=========== helpers ==========================================================}

Function ScummVMBoolStr(const B : Boolean) : String;
begin
  if B then Result := 'true' else Result := 'false';
end;

Procedure ScummVMSplitGameId(const Stored : String; out Engine, GameId : String);
Var P : Integer;
begin
  Engine := '';
  GameId := Trim(Stored);
  P := Pos(':', GameId);
  If P > 0 then begin
    Engine := Copy(GameId, 1, P - 1);
    GameId := Copy(GameId, P + 1, MaxInt);
  end;
end;

Function ScummVMExtractOptionValue(const S : String) : String;
{ Turns "FluidSynth MIDI emulation (fluidsynth)" into "fluidsynth".
  Bare values ("auto", "default", "CGA") are returned trimmed as-is. }
Var T : String;
    P, Q : Integer;
begin
  T := Trim(S);
  if T = '' then begin Result := ''; exit; end;

  P := LastDelimiter('(', T);
  if P > 0 then begin
    Q := Pos(')', Copy(T, P + 1, MaxInt));
    if Q > 0 then begin
      Result := Trim(Copy(T, P + 1, Q - 1));
      exit;
    end;
    if T[Length(T)] = ')' then begin
      SetLength(T, Length(T) - 1);
      Result := Trim(T);
      exit;
    end;
  end;

  Result := T;
end;

Procedure ScummVMAddKey(const St : TStringList; const Key, Value : String);
begin
  if Key = '' then exit;
  St.Add(Key + '=' + Value);
end;

Procedure ScummVMAddBoolKey(const St : TStringList; const Key : String; const B : Boolean);
begin
  ScummVMAddKey(St, Key, ScummVMBoolStr(B));
end;

Procedure ScummVMMapGfxFilter(const FilterRaw : String; out GfxMode, Scaler : String; out ScaleFactor : Integer); forward;
Procedure ScummVMAddProfileGraphicsKeys(const St : TStringList; const Game : TGame); forward;

Function ScummVMResolveSoundFont(const Game : TGame) : String;
Var S : String;
begin
  Result := '';
  if Game = nil then exit;
  S := Trim(Game.FluidSoundFont);
  if S = '' then exit;
  Result := MakeAbsPath(S, PrgSetup.BaseDir);
end;

Function ScummVMResolveExtraPath(const Game : TGame) : String;
Var S : String;
begin
  Result := '';
  if Game = nil then exit;
  S := Trim(Game.MIDIMT32RomDir);
  if S = '' then S := Trim(Game.ScummVMExtraPath);
  if S = '' then exit;
  Result := MakeAbsPath(S, PrgSetup.BaseDir);
end;

Procedure ScummVMMapGfxFilter(const FilterRaw : String; out GfxMode, Scaler : String; out ScaleFactor : Integer);
{ Map legacy D-Fend filter tokens to modern scaler + scale_factor.
  GfxMode is kept for older ScummVM that still accept filter names there. }
Var F : String;
begin
  F := LowerCase(ScummVMExtractOptionValue(FilterRaw));
  GfxMode := F;
  Scaler := '';
  ScaleFactor := -1;

  if (F = '') or (F = 'default') or (F = 'normal') then begin
    GfxMode := 'normal';
    Scaler := 'normal';
    ScaleFactor := 1;
    exit;
  end;

  if F = '1x' then begin Scaler := 'normal'; ScaleFactor := 1; GfxMode := 'normal'; exit; end;
  if F = '2x' then begin Scaler := 'normal'; ScaleFactor := 2; GfxMode := 'normal'; exit; end;
  if F = '3x' then begin Scaler := 'normal'; ScaleFactor := 3; GfxMode := 'normal'; exit; end;

  if F = '2xsai' then begin Scaler := 'sai'; ScaleFactor := 2; exit; end;
  if F = 'super2xsai' then begin Scaler := 'supersai'; ScaleFactor := 2; exit; end;
  if F = 'supereagle' then begin Scaler := 'supereagle'; ScaleFactor := 2; exit; end;
  if F = 'advmame2x' then begin Scaler := 'advmame'; ScaleFactor := 2; exit; end;
  if F = 'advmame3x' then begin Scaler := 'advmame'; ScaleFactor := 3; exit; end;
  if F = 'hq2x' then begin Scaler := 'hq'; ScaleFactor := 2; exit; end;
  if F = 'hq3x' then begin Scaler := 'hq'; ScaleFactor := 3; exit; end;
  if F = 'tv2x' then begin Scaler := 'tv'; ScaleFactor := 2; exit; end;
  if (F = 'dotmatrix') or (F = 'dot-matrix') then begin Scaler := 'dotmatrix'; ScaleFactor := 2; exit; end;
  if F = '4x' then begin Scaler := 'normal'; ScaleFactor := 4; GfxMode := 'normal'; exit; end;
  if F = 'advmame4x' then begin Scaler := 'advmame'; ScaleFactor := 4; exit; end;
  if F = 'edge2x' then begin Scaler := 'edge'; ScaleFactor := 2; exit; end;
  if F = 'edge3x' then begin Scaler := 'edge'; ScaleFactor := 3; exit; end;
  if F = 'pm2x' then begin Scaler := 'pm'; ScaleFactor := 2; exit; end;
  if F = 'opengl' then begin GfxMode := 'opengl'; Scaler := ''; ScaleFactor := -1; exit; end;

  GfxMode := F;
end;

Procedure ScummVMAddProfileGraphicsKeys(const St : TStringList; const Game : TGame);
Var S, GfxMode, Scaler : String;
    ScaleFactor : Integer;
begin
  ScummVMMapGfxFilter(Game.ScummVMFilter, GfxMode, Scaler, ScaleFactor);
  S := LowerCase(ScummVMExtractOptionValue(Game.ScummVMGfxMode));
  if (S <> '') and (S <> 'default') then GfxMode := S;
  S := LowerCase(ScummVMExtractOptionValue(Game.ScummVMScaler));
  if (S <> '') and (S <> 'default') then Scaler := S;
  S := Trim(ScummVMExtractOptionValue(Game.ScummVMScaleFactor));
  if (S <> '') and (not SameText(S, 'default')) then ScaleFactor := StrToIntDef(S, ScaleFactor);
  if GfxMode <> '' then ScummVMAddKey(St, 'gfx_mode', GfxMode);
  if Scaler <> '' then ScummVMAddKey(St, 'scaler', Scaler);
  if ScaleFactor > 0 then ScummVMAddKey(St, 'scale_factor', IntToStr(ScaleFactor));

  S := LowerCase(ScummVMExtractOptionValue(Game.ScummVMStretchMode));
  if (S <> '') and (S <> 'default') then ScummVMAddKey(St, 'stretch_mode', S);
  S := Trim(ScummVMExtractOptionValue(Game.ScummVMShader));
  if (S <> '') and (not SameText(S, 'none')) and (not SameText(S, 'default')) then
    ScummVMAddKey(St, 'shader', S);
  ScummVMAddBoolKey(St, 'filtering', Game.ScummVMFiltering);
  S := LowerCase(Trim(ScummVMExtractOptionValue(Game.ScummVMVSync)));
  if (S = '1') or (S = '-1') or (S = 'true') or (S = 'on') then
    ScummVMAddKey(St, 'vsync', 'true')
  else if (S = '0') or (S = 'false') or (S = 'off') then
    ScummVMAddKey(St, 'vsync', 'false');
  S := LowerCase(ScummVMExtractOptionValue(Game.ScummVMRenderer));
  if (S <> '') and (S <> 'default') then ScummVMAddKey(St, 'renderer', S);
  S := Trim(ScummVMExtractOptionValue(Game.ScummVMAntialiasing));
  if (S <> '') and (not SameText(S, 'default')) then ScummVMAddKey(St, 'antialiasing', S);
end;

Procedure ScummVMMapMusicDevices(const MusicDriverRaw : String; const NativeMT32, EnableGS, MultiMIDI : Boolean;
  const SoundFontPath : String; out MusicDriver, Mt32Device, GmDevice, SoundFont : String;
  out NativeMT32Out, EnableGSOut, MultiMIDIOut : Boolean);
{ Translate D-Fend music driver selection into modern ScummVM device keys.

  Modern ScummVM separates:
    music_driver  – preferred music device type (auto/adlib/mt32/fluidsynth/…)
    mt32_device   – device used when a game wants MT-32 (default "null")
    gm_device     – device used when a game wants General MIDI
    soundfont     – FluidSynth / compatible SoftSynth SoundFont
    native_mt32   – true Roland MT-32 (disable GM emulation)
    enable_gs     – Roland GS mappings for MT-32 scores on GS hardware
    multi_midi    – mixed AdLib + native MIDI
}
Var D : String;
begin
  D := LowerCase(ScummVMExtractOptionValue(MusicDriverRaw));
  if D = '' then D := 'auto';

  MusicDriver := D;
  Mt32Device := 'null';
  GmDevice := 'auto';
  SoundFont := Trim(SoundFontPath);
  NativeMT32Out := NativeMT32;
  EnableGSOut := EnableGS;
  MultiMIDIOut := MultiMIDI;

  if (D = 'null') or (D = 'adlib') or (D = 'pcspk') or (D = 'pcjr') or (D = 'cms')
     or (D = 'towns') or (D = 'pc98') or (D = 'segacd') or (D = 'mac') or (D = 'amiga') then
    exit;

  { ScummVM plugin ids are case-sensitive for some softsynths. }
  if D = 'c64' then begin MusicDriver := 'C64'; exit; end;
  if D = 'appleiigs' then begin MusicDriver := 'appleIIgs'; exit; end;

  if D = 'mt32' then begin
    MusicDriver := 'mt32';
    Mt32Device := 'mt32';
    if not NativeMT32 then NativeMT32Out := False;
    exit;
  end;

  if (D = 'fluidsynth') or (D = 'fluid') then begin
    MusicDriver := 'fluidsynth';
    GmDevice := 'fluidsynth';
    exit;
  end;

  if (D = 'windows') or (D = 'windows_midi') then begin
    MusicDriver := 'windows';
    GmDevice := 'windows';
    if NativeMT32 then begin
      Mt32Device := 'windows';
      NativeMT32Out := True;
    end;
    exit;
  end;

  if D = 'timidity' then begin
    MusicDriver := 'timidity';
    GmDevice := 'timidity';
    exit;
  end;

  if D = 'auto' then begin
    MusicDriver := 'auto';
    if SoundFont <> '' then
      GmDevice := 'fluidsynth'
    else
      GmDevice := 'auto';
    exit;
  end;

  MusicDriver := D;
end;

Function ScummVMNormalizeRenderMode(const RenderMode : String) : String;
Var R : String;
begin
  R := ScummVMExtractOptionValue(RenderMode);
  if (R = '') or (SameText(R, 'default')) then begin Result := ''; exit; end;
  if SameText(R, 'CGA') then Result := 'cga'
  else if SameText(R, 'EGA') then Result := 'ega'
  else if SameText(R, 'VGA') then Result := 'vga'
  else if SameText(R, 'Amiga') then Result := 'amiga'
  else if SameText(R, 'hercGreen') or SameText(R, 'Hercules green') then Result := 'hercGreen'
  else if SameText(R, 'hercAmber') or SameText(R, 'Hercules amber') then Result := 'hercAmber'
  else Result := R;
end;

Function ScummVMNormalizePlatform(const DataPlatform : String) : String;
Var P : String;
begin
  P := LowerCase(Trim(ScummVMExtractOptionValue(DataPlatform)));
  if (P = '') or (P = 'auto') or (P = 'default') then Result := ''
  else Result := P;
end;

{=========== ini discovery ====================================================}

Function FindScummVMIni(UseSecondOne : Boolean) : String;
Var S : String;
begin
  result := '';

  If not UseSecondOne then begin
    S := IncludeTrailingPathDelimiter(GetSpecialFolder(Application.Handle, CSIDL_APPDATA)) + 'ScummVM\';
    If FileExists(S + ScummVMConfFileName) then begin result := S + ScummVMConfFileName; exit; end;

    { %LOCALAPPDATA%\ScummVM (some portable / newer installs) }
    S := IncludeTrailingPathDelimiter(GetSpecialFolder(Application.Handle, $001c {CSIDL_LOCAL_APPDATA})) + 'ScummVM\';
    If FileExists(S + ScummVMConfFileName) then begin result := S + ScummVMConfFileName; exit; end;

    SetLength(S, 520); GetWindowsDirectory(PChar(S), 512); SetLength(S, StrLen(PChar(S))); S := IncludeTrailingPathDelimiter(S);
    If FileExists(S + ScummVMConfFileName) then begin result := S + ScummVMConfFileName; exit; end;
  end;

  S := IncludeTrailingPathDelimiter(PrgSetup.ScummVMPath);
  If FileExists(S + ScummVMConfFileName) then begin result := S + ScummVMConfFileName; exit; end;
end;

Procedure AddKeysFromDefaultScummVMIni(const St1, St2 : TStringList; const Ini : TIniFile; const GameName : String);
Var KnownKeys, Section : TStringList;
    I, J : Integer;
    S : String;
begin
  KnownKeys := TStringList.Create;
  Section := TStringList.Create;
  try
    For I := 0 to St1.Count - 1 do begin
      S := Trim(ExtUpperCase(St1[I]));
      J := Pos('=', S);
      If (S <> '') and (S[1] <> '[') and (J > 0) then KnownKeys.Add(Trim(Copy(S, 1, J - 1)));
    end;
    For I := 0 to St2.Count - 1 do begin
      S := Trim(ExtUpperCase(St2[I]));
      J := Pos('=', S);
      If (S <> '') and (S[1] <> '[') and (J > 0) then KnownKeys.Add(Trim(Copy(S, 1, J - 1)));
    end;

    Section.Clear;
    Ini.ReadSection('scummvm', Section);
    For I := 0 to Section.Count - 1 do begin
      If KnownKeys.IndexOf(ExtUpperCase(Section[I])) >= 0 then continue;
      St1.Add(Section[I] + '=' + Ini.ReadString('scummvm', Section[I], ''));
      KnownKeys.Add(ExtUpperCase(Section[I]));
    end;

  finally
    KnownKeys.Free;
    Section.Free;
  end;
end;

Function FindTheme(const ScummVMPath : String) : String;
Var Rec : TSearchRec;
    I : Integer;
    Path : String;
begin
  result := '';
  Path := IncludeTrailingPathDelimiter(ScummVMPath);
  I := FindFirst(Path + '*.zip', faAnyFile, Rec);
  try
    While I = 0 do begin
      If FileExists(Path + ChangeFileExt(Rec.Name, '.ini')) then begin
        result := ChangeFileExt(Rec.Name, '');
        exit;
      end;
      I := FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

{=========== config builder (primary place for all settings) ==================}

Procedure ScummVMApplyGameOptionsBlob(const St : TStringList; const OptionsBlob, HasSpecialOptions : String); forward;

Function BuildScummVMIniFile(const Game : TGame; const RunMode : Boolean) : TStringList;
Var S, MusicDriver, Mt32Device, GmDevice, SoundFont : String;
    NativeMT32, EnableGS, MultiMIDI : Boolean;
    Ini, Ini2 : TIniFile;
    St1, St2, St3 : TStringList;
    GameId, Engine : String;
begin
  result := TStringList.Create;

  St1 := TStringList.Create;
  St2 := TStringList.Create;
  try
    {----- global [scummvm] --------------------------------------------------}
    St1.Add('[scummvm]');
    St1.Add('updates_check=0');

    ScummVMAddProfileGraphicsKeys(St1, Game);

    ScummVMAddBoolKey(St1, 'fullscreen', Game.StartFullscreen);
    ScummVMAddBoolKey(St1, 'aspect_ratio', Game.AspectCorrection);
    ScummVMAddBoolKey(St1, 'confirm_exit', Game.ScummVMConfirmExit);
    If PrgSetup.HideScummVMConsole then
      ScummVMAddBoolKey(St1, 'console', False);

    { Screenshots → profile capture folder when set }
    If Trim(Game.CaptureFolder) <> '' then begin
      S := MakeAbsPath(Game.CaptureFolder, PrgSetup.BaseDir);
      If S <> '' then ScummVMAddKey(St1, 'screenshotpath', IncludeTrailingPathDelimiter(S));
    end;

    {----- per-game target section -------------------------------------------}
    {$IFDEF AddDFRPrefixInRunMode} If RunMode then S := 'DFR' else {$ENDIF} S := '';
    ScummVMSplitGameId(Game.ScummVMGame, Engine, GameId);
    St2.Add('[' + S + GameId + ']');
    St2.Add('gameid=' + GameId);
    If Engine <> '' then St2.Add('engineid=' + Engine);
    St2.Add('description=' + Game.Name);
    S := Trim(Game.ScummVMExtraVariant);
    If S <> '' then St2.Add('extra=' + S);

    If Trim(Game.ScummVMPath) = '' then S := '' else S := IncludeTrailingPathDelimiter(MakeAbsPath(Game.ScummVMPath, PrgSetup.BaseDir));
    St2.Add('path=' + S);

    If Trim(Game.ScummVMSavePath) <> '' then
      S := IncludeTrailingPathDelimiter(MakeAbsPath(Game.ScummVMSavePath, PrgSetup.BaseDir))
    else begin
      If Trim(Game.ScummVMPath) = '' then S := '' else S := IncludeTrailingPathDelimiter(MakeAbsPath(Game.ScummVMPath, PrgSetup.BaseDir));
    end;
    St2.Add('savepath=' + S);

    St2.Add('autosave_period=' + IntToStr(Game.ScummVMAutosave));
    If Trim(Game.ScummVMLanguage) <> '' then St2.Add('language=' + LowerCase(Trim(Game.ScummVMLanguage)));

    St2.Add('music_volume=' + IntToStr(Game.ScummVMMusicVolume));
    St2.Add('speech_volume=' + IntToStr(Game.ScummVMSpeechVolume));
    St2.Add('sfx_volume=' + IntToStr(Game.ScummVMSFXVolume));
    St2.Add('midi_gain=' + IntToStr(Game.ScummVMMIDIGain));
    St2.Add('output_rate=' + IntToStr(Game.ScummVMSampleRate));

    ScummVMAddBoolKey(St2, 'aspect_ratio', Game.AspectCorrection);
    ScummVMAddBoolKey(St2, 'fullscreen', Game.StartFullscreen);

    { Music / MIDI / MT-32 / GM soft synth — all in config, not CLI }
    ScummVMMapMusicDevices(
      Game.ScummVMMusicDriver,
      Game.ScummVMNativeMT32,
      Game.ScummVMEnableGS,
      Game.ScummVMMultiMIDI,
      ScummVMResolveSoundFont(Game),
      MusicDriver, Mt32Device, GmDevice, SoundFont,
      NativeMT32, EnableGS, MultiMIDI
    );

    ScummVMAddKey(St2, 'music_driver', MusicDriver);
    ScummVMAddKey(St2, 'mt32_device', Mt32Device);
    ScummVMAddKey(St2, 'gm_device', GmDevice);
    if (MusicDriver = 'mt32') or (MusicDriver = 'windows') then
      ScummVMAddBoolKey(St2, 'native_mt32', NativeMT32)
    else
      ScummVMAddKey(St2, 'native_mt32', 'false');
    ScummVMAddBoolKey(St2, 'enable_gs', EnableGS);
    ScummVMAddBoolKey(St2, 'multi_midi', MultiMIDI);
    if SoundFont <> '' then
      ScummVMAddKey(St2, 'soundfont', SoundFont);
    S := LowerCase(ScummVMExtractOptionValue(Game.ScummVMOplDriver));
    if (S <> '') and (S <> 'default') then
      ScummVMAddKey(St2, 'opl_driver', S);

    St2.Add('talkspeed=' + IntToStr(Game.ScummVMTalkSpeed));
    ScummVMAddBoolKey(St2, 'speech_mute', Game.ScummVMSpeechMute);
    ScummVMAddBoolKey(St2, 'subtitles', Game.ScummVMSubtitles);
    St2.Add('cdrom=' + IntToStr(Game.ScummVMCDROM));
    St2.Add('joystick_num=' + IntToStr(Game.ScummVMJoystickNum));

    S := ScummVMResolveExtraPath(Game);
    If (S <> '') and (MusicDriver = 'mt32') then
      St2.Add('extrapath=' + S);

    S := ScummVMNormalizeRenderMode(Game.ScummVMRenderMode);
    if S <> '' then St2.Add('render_mode=' + S);

    S := ScummVMNormalizePlatform(Game.ScummVMPlatform);
    if S <> '' then St2.Add('platform=' + S);

    { Game-engine specific keys }
    S := Trim(LowerCase(GameId));

    If (S = 'sky') or (S = 'queen') then
      ScummVMAddBoolKey(St2, 'alt_intro', Game.ScummVMAltIntro);

    If S = 'sword2' then begin
      St2.Add('gfx_details=' + IntToStr(Game.ScummVMGFXDetails));
      ScummVMAddBoolKey(St2, 'music_mute', Game.ScummVMMusicMute);
      ScummVMAddBoolKey(St2, 'object_labels', Game.ScummVMObjectLabels);
      ScummVMAddBoolKey(St2, 'reverse_stereo', Game.ScummVMReverseStereo);
      ScummVMAddBoolKey(St2, 'sfx_mute', Game.ScummVMSFXMute);
    end;

    If (S = 'queen') or (S = 'simon1') or (S = 'simon2') then begin
      ScummVMAddBoolKey(St2, 'music_mute', Game.ScummVMMusicMute);
      ScummVMAddBoolKey(St2, 'sfx_mute', Game.ScummVMSFXMute);
    end;

    If S = 'kyra1' then
      St2.Add('walkspeed=' + IntToStr(Game.ScummVMWalkspeed));

    { Options from ScummVM settings page (opt,opt=5,...) }
    ScummVMApplyGameOptionsBlob(St2, Game.ScummGameOptions, Game.ScummVMHasSpecialOptions);

    { Merge themepath / gui_theme / extrapath / soundfont from installed ScummVM }
    S := FindScummVMIni;
    If S <> '' then begin
      Ini := TIniFile.Create(S);
      try
        S := FindScummVMIni(True); If S <> '' then Ini2 := TIniFile.Create(S) else Ini2 := nil;
        try
          S := Ini.ReadString('scummvm', 'themepath', '');
          If (S = '') and Assigned(Ini2) then S := Ini2.ReadString('scummvm', 'themepath', '');
          If S = '' then S := IncludeTrailingPathDelimiter(PrgSetup.ScummVMPath);
          St1.Add('themepath=' + S);

          S := Ini.ReadString('scummvm', 'gui_theme', '');
          If (S = '') and Assigned(Ini2) then S := Ini2.ReadString('scummvm', 'gui_theme', '');
          If S = '' then S := FindTheme(IncludeTrailingPathDelimiter(PrgSetup.ScummVMPath));
          If S <> '' then St1.Add('gui_theme=' + S);

          S := Ini.ReadString('scummvm', 'extrapath', '');
          If (S = '') and Assigned(Ini2) then S := Ini2.ReadString('scummvm', 'extrapath', '');
          If S = '' then S := IncludeTrailingPathDelimiter(PrgSetup.ScummVMPath);
          St1.Add('extrapath=' + S);

          if SoundFont = '' then begin
            S := Ini.ReadString('scummvm', 'soundfont', '');
            If (S = '') and Assigned(Ini2) then S := Ini2.ReadString('scummvm', 'soundfont', '');
            If S <> '' then St2.Add('soundfont=' + S);
          end;
        finally
          If Assigned(Ini2) then Ini2.Free;
        end;
        AddKeysFromDefaultScummVMIni(St1, St2, Ini, GameId);
      finally
        Ini.Free;
      end;
    end else begin
      St1.Add('themepath=' + IncludeTrailingPathDelimiter(PrgSetup.ScummVMPath));
    end;

    result.AddStrings(St1);
    result.Add('');
    result.AddStrings(St2);

    result.Add('');
    If Trim(Game.CustomSettings) <> '' then begin
      St3 := StringToStringList(Game.CustomSettings);
      try
        result.AddStrings(St3);
      finally
        St3.Free;
      end;
    end;
  finally
    St1.Free;
    St2.Free;
  end;
end;

{=========== command line (minimal — config file holds the settings) ==========}

Function GetScummVMCommandLine(const INIFile, GameName, AdditionalCommandLine,
  RenderMode, DataPlatform : String; const ScreenshotPath : String;
  const GamePath : String; const Game : TGame) : String;
{ Intentionally does NOT re-pass music/gfx/volume/path options: those belong in
  the generated ini (see BuildScummVMIniFile). ScummVM loads them via --config.

  RenderMode, DataPlatform, ScreenshotPath, GamePath, Game are kept in the
  signature so existing callers compile; they are ignored here because the
  config already contains render_mode, platform, path, screenshotpath, etc. }
begin
  Result := '';

  { User / profile extra flags first (escape hatch for rare one-offs) }
  if Trim(AdditionalCommandLine) <> '' then
    Result := Trim(AdditionalCommandLine);

  { Point ScummVM at our generated profile config }
  if Result <> '' then Result := Result + ' ';
  Result := Result + '--config="' + INIFile + '"';

  { Console window (Windows): boolean invert of --console }
  if PrgSetup.HideScummVMConsole then
    Result := Result + ' --no-console';

  if Result <> '' then Result := Result + ' ';
  Result := Result + GameName;
end;

{=========== process launch ===================================================}

Function RunScummVM(const INIFile, GameName, AdditionalCommandLine : String;
  const FullScreen : Boolean; const GameDir, ScreenshotDir, RenderMode,
  DataPlatform : String; const asAdmin : Boolean; const Game : TGame) : THandle;
Var PrgFile, Params : String;
    StartupInfo : TStartupInfo;
    ProcessInformation : TProcessInformation;
    Waited : Boolean;
begin
  result := INVALID_HANDLE_VALUE;

  PrgFile := IncludeTrailingPathDelimiter(PrgSetup.ScummVMPath) + ScummPrgFile;
  if not FileExists(PrgFile) then begin
    Application.Restore;
    MessageDlg(Format(LanguageSetup.MessageCouldNotFindScummVM, [PrgFile]), mtError, [mbOK], 0);
    exit;
  end;

  Params := GetScummVMCommandLine(INIFile, GameName, AdditionalCommandLine,
    RenderMode, DataPlatform, ScreenshotDir, GameDir, Game);

  if asAdmin then begin
    ShellExecute(
      Application.MainForm.Handle,
      'open',
      PChar(PrgDir + BinFolder + '\AdminLauncher.exe'),
      PChar('/dir=' + ScreenshotDir + ' /run="' + PrgFile + '" ' + Params),
      PChar(ScreenshotDir),
      SW_SHOW
    );
    exit;
  end;

  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  with StartupInfo do begin
    cb := SizeOf(TStartupInfo);
  end;

  If ScreenshotDir <> '' then begin
    If not CreateProcess(
      PChar(PrgFile),
      PChar('"' + PrgFile + '" ' + Params),
      nil,
      nil,
      False,
      0,
      nil,
      PChar(ScreenshotDir),
      StartupInfo,
      ProcessInformation
    ) then begin
      Application.Restore;
      MessageDlg(Format(LanguageSetup.MessageCouldNotStartProgram, [PrgFile]), mtError, [mbOK], 0);
      result := INVALID_HANDLE_VALUE;
      exit;
    end;
  end else begin
    If not CreateProcess(
      PChar(PrgFile),
      PChar('"' + PrgFile + '" ' + Params),
      nil,
      nil,
      False,
      0,
      nil,
      PChar(ExtractFilePath(PrgFile)),
      StartupInfo,
      ProcessInformation
    ) then begin
      Application.Restore;
      MessageDlg(Format(LanguageSetup.MessageCouldNotStartProgram, [PrgFile]), mtError, [mbOK], 0);
      result := INVALID_HANDLE_VALUE;
      exit;
    end;
  end;

  result := ProcessInformation.hProcess;
  CloseHandle(ProcessInformation.hThread);

  If PrgSetup.CenterScummVMWindow and (not FullScreen) then begin
    Sleep(1000); Waited := True;
    CenterWindowFromProcessID(ProcessInformation.dwProcessId);
  end else begin
    Waited := False;
  end;

  If PrgSetup.MinimizeOnScummVMStart then begin
    If not Waited then begin
      Sleep(1000); Waited := True;
    end;
  end;

  If PrgSetup.HideScummVMConsole then begin
    If not Waited then begin
      Sleep(1000);
    end;
    HideWindowFromProcessIDAndTitle(ProcessInformation.dwProcessId, '\scummvm.exe');
  end;

  ScummVMCounter.Add(result);
end;

Procedure ScummVMApplyGameOptionsBlob(const St : TStringList; const OptionsBlob, HasSpecialOptions : String);
Var Parts, Specials : TStringList;
    I, P : Integer;
    Tok, Key, Val : String;
    HasEnhancementsSpecial, IsGroupKey : Boolean;
    G1, G2, G3, G4 : Boolean;
begin
  If St = nil then Exit;
  HasEnhancementsSpecial := False;
  Specials := TStringList.Create;
  try
    Specials.StrictDelimiter := True;
    Specials.Delimiter := ',';
    Specials.QuoteChar := #0;
    Specials.DelimitedText := Trim(HasSpecialOptions);
    For I := 0 to Specials.Count - 1 do
      If SameText(Trim(Specials[I]), 'enhancements') then
        HasEnhancementsSpecial := True;
  finally
    Specials.Free;
  end;
  If (Trim(OptionsBlob) = '') and not HasEnhancementsSpecial then Exit;

  If Trim(OptionsBlob) <> '' then begin
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := ',';
      Parts.QuoteChar := #0;
      Parts.DelimitedText := OptionsBlob;
      For I := 0 to Parts.Count - 1 do begin
        Tok := Trim(Parts[I]);
        If Tok = '' then Continue;
        P := Pos('=', Tok);
        If P <= 0 then
          Key := Tok
        else
          Key := Trim(Copy(Tok, 1, P - 1));
        IsGroupKey :=
          SameText(Key, 'enhancementGroup1') or
          SameText(Key, 'enhancementGroup2') or
          SameText(Key, 'enhancementGroup3') or
          SameText(Key, 'enhancementGroup4');
        If HasEnhancementsSpecial and (IsGroupKey or SameText(Key, 'enhancements')) then
          Continue;
        If P <= 0 then begin
          If SameText(Tok, 'enhancements') then
            St.Add('enhancements=7')
          else
            St.Add(Tok + '=true');
        end else begin
          Val := Trim(Copy(Tok, P + 1, MaxInt));
          If SameText(Key, 'enhancements') and SameText(Val, 'true') then
            Val := '7'
          else If SameText(Key, 'enhancements') and SameText(Val, 'false') then
            Val := '0';
          If Key <> '' then
            St.Add(Key + '=' + Val);
        end;
      end;
    finally
      Parts.Free;
    end;
  end;

  If HasEnhancementsSpecial then begin
    ScummVMSettingsReadEnhancementGroups(OptionsBlob, G1, G2, G3, G4);
    St.Add('enhancements=' + IntToStr(ScummVMSettingsPackScummEnhancements(G1, G2, G3, G4)));
  end;
end;


Procedure RunScummVMGame(const Game : TGame);
Var St : TStringList;
    Params, Dir, GameId, GameVariant, ShotDir : String;
    ZipRecNr : Integer;
    Error : Boolean;
    ScummVMHandle : THandle;
    AlreadyMinimized : Boolean;
    RunAsAdmin : Boolean;
begin
  AlreadyMinimized := False;

  ZipRecNr := ZipManager.AddGame(Game, Error);
  If Error then exit;

  try
    { 1) Generate a full profile config (all settings live here) }
    St := BuildScummVMIniFile(Game, True);
    try
      try
        St.SaveToFile(TempDir + ScummVMConfFileName);
      except
        Application.Restore;
        MessageDlg(Format(LanguageSetup.MessageCouldNotSaveFile, [TempDir + ScummVMConfFileName]), mtError, [mbOK], 0);
        exit;
      end;
      History.Add(Game.Name);

      ShotDir := '';
      If Trim(Game.CaptureFolder) <> '' then begin
        ShotDir := MakeAbsPath(Game.CaptureFolder, PrgSetup.BaseDir);
        If not ForceDirectories(ShotDir) then ShotDir := '';
      end;

      RunPrgManager.RunBeforeExecutionCommand(Game);

      If PrgSetup.MinimizeOnScummVMStart then begin
        AlreadyMinimized := (Application.MainForm.WindowState = wsMinimized);
        Application.Minimize;
      end;

      Params := Trim(PrgSetup.ScummVMAdditionalCommandLine);
      If Trim(Game.ScummVMParameters) <> '' then begin
        If Params <> '' then Params := Params + ' ';
        Params := Params + Trim(Game.ScummVMParameters);
      end;

      RunAsAdmin := False;
      if Game.RunAsAdmin and PrgSetup.OfferRunAsAdmin then begin
        if ZipRecNr < 0 then RunAsAdmin := True else MessageDlg(LanguageSetup.ProfileMountingZipAdminError, mtError, [mbOK], 0);
      end;

      If Trim(Game.ScummVMPath) = '' then Dir := '' else Dir := IncludeTrailingPathDelimiter(MakeAbsPath(Game.ScummVMPath, PrgSetup.BaseDir));
      PauseAmbientSoundtrack;

      ScummVMSettingsParseGameToken(Game.ScummVMGame, GameId, GameVariant);
      If Trim(GameId) = '' then GameId := Trim(Game.ScummVMGame);

      { 2) Launch with a short CLI that only points at that config }
      ScummVMHandle := RunScummVM(
        TempDir + ScummVMConfFileName,
        {$IFDEF AddDFRPrefixInRunMode}'DFR' + {$ENDIF} GameId,
        Params,
        Game.StartFullscreen,
        Dir,
        ShotDir,
        Game.ScummVMRenderMode,
        Game.ScummVMPlatform,
        RunAsAdmin,
        Game
      );
      try
        If ZipRecNr >= 0 then ZipManager.ActivateRepackCheck(ZipRecNr, ScummVMHandle);
        RunPrgManager.AddCommand(Game, ScummVMHandle);
      finally
        CloseHandle(ScummVMHandle);
      end;
    finally
      St.Free;
    end;
  finally
    If PrgSetup.MinimizeOnScummVMStart and (not AlreadyMinimized) then MinimizedAtScummVMStart := True;
  end;
end;

end.
