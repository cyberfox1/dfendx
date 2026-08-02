unit BassMedia;

interface

uses
  Windows, BASS;

var
  { Current sound stream; 0 = none. Used by later Phase 2 steps. }
  BassSoundChannel : HSTREAM = 0;
  AmbientSoundtrackFile : String = '';
  { Path of last BassLoadMediaFile (for silence scan on play). }
  BassMediaFilePath : String = '';

function InitBassMedia(const BinPath : String; Win : HWND) : Boolean;
procedure FreeBassMedia;
function BassMediaReady : Boolean;

{ Phase 2.3 — same signatures as MediaInterface sound load (full String path for BASS_UNICODE) }
function BassLoadMediaFile(FileName : String; aHandle : THandle) : String; stdcall;
function BassMediaStreamAvailable : boolean; stdcall;

{ Phase 2.4 — play / pause / stop (play always skips leading silence) }
function BassPlayMediaStream : BOOL; stdcall;
function BassPauseMediaStream : BOOL; stdcall;
function BassStopMediaStream : BOOL; stdcall;
function BassMediaStreamPlayed : boolean; stdcall;

{ Phase 2.5 — position / duration (same scale as PlaySoundForm: /1000/10000 → seconds) }
function BassGetMediaStreamDuration : int64; stdcall;
function BassGetMediaStreamPos : int64; stdcall;
function BassSetMediaStreamPos(pos : int64) : BOOL; stdcall;

{ Phase 2.6 — free / reset stream }
function BassFreeMediaStream : BOOL; stdcall;
function BassResetMediaStream : BOOL; stdcall;

{ Ambient always skips leading silence and sets loop start so wraps skip too. }
function PlayAmbientSoundtrack(const FileName : String) : Boolean;
function PauseAmbientSoundtrack : Boolean; { True if a playing stream was paused }
procedure ResumeAmbientSoundtrack;
procedure StopAmbientSoundtrack;

implementation

uses
  SysUtils, LoggingUnit;

const
  { DirectShow-style 100ns units; form displays pos/1000/10000 as seconds. }
  MediaTimePerSecond = 10000000;
  SilenceScanFloatCount = 2048;
  { Linear amplitude threshold for float samples (~ -60 dB). }
  SilenceThreshold = Single(0.001);
  MaxSilenceScanSeconds = 30.0;

var
  BassInited : Boolean = False;
  BassDllHandle : THandle = 0;

function FindLeadingSilenceBytes(const FileName : String) : QWORD;
{ Decode-only scan: byte offset of first non-silent float sample. 0 if none. }
var
  Dec : HSTREAM;
  Path : UnicodeString;
  Buf : array[0..SilenceScanFloatCount-1] of Single;
  Got : DWORD;
  I, N : Integer;
  StartPos, MaxBytes, FrameBytes : QWORD;
  AbsV : Single;
begin
  result:=0;
  if (not BassInited) or (FileName='') or (not FileExists(FileName)) then exit;

  Path:=UnicodeString(FileName);
  Dec:=BASS_StreamCreateFile(0, PWideChar(Path), 0, 0,
    BASS_UNICODE or BASS_STREAM_DECODE);
  if Dec=0 then begin
    LogInfo('BASS: silence scan open failed path='+FileName+
      ' error='+IntToStr(BASS_ErrorGetCode));
    exit;
  end;
  try
    MaxBytes:=BASS_ChannelSeconds2Bytes(Dec, MaxSilenceScanSeconds);
    if MaxBytes=QWORD(-1) then
      MaxBytes:=BASS_ChannelGetLength(Dec, BASS_POS_BYTE);
    if MaxBytes=QWORD(-1) then
      MaxBytes:=High(QWORD) div 4;

    while True do begin
      StartPos:=BASS_ChannelGetPosition(Dec, BASS_POS_BYTE);
      if StartPos=QWORD(-1) then StartPos:=0;
      if StartPos>=MaxBytes then break;

      Got:=BASS_ChannelGetData(Dec, @Buf[0],
        (SilenceScanFloatCount*SizeOf(Single)) or BASS_DATA_FLOAT);
      if (Got=0) or (Got=DWORD(-1)) then break;

      N:=Integer(Got div SizeOf(Single));
      if N<=0 then break;
      FrameBytes:=BASS_ChannelGetPosition(Dec, BASS_POS_BYTE);
      if FrameBytes=QWORD(-1) then
        FrameBytes:=StartPos+Got
      else if FrameBytes>StartPos then
        FrameBytes:=FrameBytes-StartPos
      else
        FrameBytes:=Got;

      for I:=0 to N-1 do begin
        AbsV:=Buf[I];
        if AbsV<0 then AbsV:=-AbsV;
        if AbsV>SilenceThreshold then begin
          result:=StartPos+QWORD((Int64(FrameBytes)*Int64(I)) div Int64(N));
          exit;
        end;
      end;
    end;
    result:=0;
  finally
    BASS_StreamFree(Dec);
  end;
end;

procedure ApplySkipLeadingSilence(Chan : HSTREAM; const FileName : String;
  SetLoopStart : Boolean);
{ Seek past lead-in; if SetLoopStart, BASS_POS_LOOP so SAMPLE_LOOP wraps there. }
var
  Off : QWORD;
begin
  if (Chan=0) or (FileName='') then exit;
  Off:=FindLeadingSilenceBytes(FileName);
  if not BASS_ChannelSetPosition(Chan, Off, BASS_POS_BYTE) then
    LogInfo('BASS: seek past silence failed error='+IntToStr(BASS_ErrorGetCode));
  if SetLoopStart then begin
    if not BASS_ChannelSetPosition(Chan, Off, BASS_POS_LOOP) then
      LogInfo('BASS: set loop start past silence failed error='+
        IntToStr(BASS_ErrorGetCode));
  end;
end;

function InitBassMedia(const BinPath : String; Win : HWND) : Boolean;
Var DllPath, PluginPath, BassDir : String;
    Plug : HPLUGIN;
begin
  result:=False;
  if BassInited then begin
    result:=True;
    exit;
  end;

  { Installer places bass*.dll next to DFend.exe; also try BinPath (dev / older layouts). }
  DllPath:=IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'bass.dll';
  if not FileExists(DllPath) then
    DllPath:=IncludeTrailingPathDelimiter(BinPath)+'bass.dll';
  if FileExists(DllPath) then
    BassDllHandle:=LoadLibrary(PChar(DllPath))
  else begin
    DllPath:='bass.dll';
    BassDllHandle:=LoadLibrary(PChar(DllPath));
  end;
  if BassDllHandle=0 then begin
    LogInfo('BASS: LoadLibrary failed for '+DllPath);
    exit;
  end;

  if HIWORD(BASS_GetVersion)<>BASSVERSION then begin
    LogInfo('BASS: wrong version (need '+BASSVERSIONTEXT+')');
    FreeLibrary(BassDllHandle);
    BassDllHandle:=0;
    exit;
  end;

  if not BASS_Init(-1, 44100, 0, Win, nil) then begin
    LogInfo('BASS: BASS_Init failed, error='+IntToStr(BASS_ErrorGetCode));
    FreeLibrary(BassDllHandle);
    BassDllHandle:=0;
    exit;
  end;

  { Core bass.dll does not decode FLAC; bassflac.dll must be PluginLoad'd (same dir as bass.dll). }
  if ExtractFilePath(DllPath)<>'' then
    BassDir:=IncludeTrailingPathDelimiter(ExtractFilePath(DllPath))
  else
    BassDir:=IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  PluginPath:=BassDir+'bassflac.dll';
  if not FileExists(PluginPath) then
    PluginPath:=IncludeTrailingPathDelimiter(BinPath)+'bassflac.dll';
  if FileExists(PluginPath) then begin
    Plug:=BASS_PluginLoad(PChar(PluginPath), BASS_UNICODE);
    if Plug=0 then
      LogInfo('BASS: BASS_PluginLoad failed for '+PluginPath+
        ' error='+IntToStr(BASS_ErrorGetCode))
    else
      LogInfo('BASS: loaded plugin '+PluginPath);
  end else
    LogInfo('BASS: bassflac.dll not found (tried next to bass / Bin; FLAC disabled)');

  BassInited:=True;
  result:=True;
end;

procedure FreeBassMedia;
begin
  if BassSoundChannel<>0 then begin
    BASS_StreamFree(BassSoundChannel);
    BassSoundChannel:=0;
  end;
  AmbientSoundtrackFile:='';
  BassMediaFilePath:='';
  if BassInited then begin
    BASS_Free;
    BassInited:=False;
  end;
  { Leave bass.dll loaded; static imports may still reference it. }
end;

function BassMediaReady : Boolean;
begin
  result:=BassInited;
end;

function BassLoadMediaFile(FileName : String; aHandle : THandle) : String; stdcall;
var
  Path : UnicodeString;
  Chan : HSTREAM;
begin
  result:='';
  { aHandle unused for sound (historical video-window parameter). }
  if BassSoundChannel<>0 then begin
    BASS_StreamFree(BassSoundChannel);
    BassSoundChannel:=0;
  end;
  BassMediaFilePath:='';
  AmbientSoundtrackFile:='';
  if not BassInited then begin
    LogInfo('BASS: load failed (not initialized) path='+FileName);
    exit;
  end;
  { Same path handling as PlayAmbientSoundtrack — full String, no ShortString cap. }
  Path:=UnicodeString(FileName);
  Chan:=BASS_StreamCreateFile(0, PWideChar(Path), 0, 0, BASS_UNICODE);
  if Chan=0 then begin
    LogInfo('BASS: StreamCreateFile failed path='+FileName+
      ' error='+IntToStr(BASS_ErrorGetCode));
    exit;
  end;
  BassSoundChannel:=Chan;
  BassMediaFilePath:=FileName;
end;

function BassMediaStreamAvailable : boolean; stdcall;
begin
  result:=BassSoundChannel<>0;
end;

function BassPlayMediaStream : BOOL; stdcall;
begin
  result:=False;
  if BassSoundChannel=0 then exit;
  { Always skip leading silence before play (resume from pause keeps position). }
  if BASS_ChannelIsActive(BassSoundChannel)<>BASS_ACTIVE_PAUSED then
    ApplySkipLeadingSilence(BassSoundChannel, BassMediaFilePath, False);
  result:=BASS_ChannelPlay(BassSoundChannel, False);
  if not result then
    LogInfo('BASS: ChannelPlay failed error='+IntToStr(BASS_ErrorGetCode));
end;

function BassPauseMediaStream : BOOL; stdcall;
begin
  result:=False;
  if BassSoundChannel=0 then exit;
  result:=BASS_ChannelPause(BassSoundChannel);
  if not result then
    LogInfo('BASS: ChannelPause failed error='+IntToStr(BASS_ErrorGetCode));
end;

function BassStopMediaStream : BOOL; stdcall;
begin
  result:=False;
  if BassSoundChannel=0 then exit;
  result:=BASS_ChannelStop(BassSoundChannel);
  if not result then
    LogInfo('BASS: ChannelStop failed error='+IntToStr(BASS_ErrorGetCode));
end;

function BassMediaStreamPlayed : boolean; stdcall;
begin
  result:=(BassSoundChannel<>0) and
    (BASS_ChannelIsActive(BassSoundChannel)=BASS_ACTIVE_PLAYING);
end;

function BassGetMediaStreamDuration : int64; stdcall;
var
  Len : QWORD;
  Secs : Double;
begin
  result:=0;
  if BassSoundChannel=0 then exit;
  Len:=BASS_ChannelGetLength(BassSoundChannel, BASS_POS_BYTE);
  if Len=QWORD(-1) then exit;
  Secs:=BASS_ChannelBytes2Seconds(BassSoundChannel, Len);
  if Secs<0 then exit;
  result:=Round(Secs*MediaTimePerSecond);
end;

function BassGetMediaStreamPos : int64; stdcall;
var
  Pos : QWORD;
  Secs : Double;
begin
  result:=0;
  if BassSoundChannel=0 then exit;
  Pos:=BASS_ChannelGetPosition(BassSoundChannel, BASS_POS_BYTE);
  if Pos=QWORD(-1) then exit;
  Secs:=BASS_ChannelBytes2Seconds(BassSoundChannel, Pos);
  if Secs<0 then exit;
  result:=Round(Secs*MediaTimePerSecond);
end;

function BassSetMediaStreamPos(pos : int64) : BOOL; stdcall;
var
  Bytes : QWORD;
begin
  result:=False;
  if BassSoundChannel=0 then exit;
  if pos<0 then pos:=0;
  Bytes:=BASS_ChannelSeconds2Bytes(BassSoundChannel, pos/Double(MediaTimePerSecond));
  result:=BASS_ChannelSetPosition(BassSoundChannel, Bytes, BASS_POS_BYTE);
  if not result then
    LogInfo('BASS: ChannelSetPosition failed error='+IntToStr(BASS_ErrorGetCode));
end;

function BassFreeMediaStream : BOOL; stdcall;
begin
  result:=True;
  if BassSoundChannel=0 then exit;
  result:=BASS_StreamFree(BassSoundChannel);
  BassSoundChannel:=0;
  BassMediaFilePath:='';
  if not result then
    LogInfo('BASS: StreamFree failed error='+IntToStr(BASS_ErrorGetCode));
end;

function BassResetMediaStream : BOOL; stdcall;
begin
  { Same as free for sound: drop channel; next load creates a new stream. }
  result:=BassFreeMediaStream;
end;

function PlayAmbientSoundtrack(const FileName : String) : Boolean;
var
  Path : UnicodeString;
  Chan : HSTREAM;
begin
  result:=False;
  if BassSoundChannel<>0 then begin
    if (BASS_ChannelIsActive(BassSoundChannel)=BASS_ACTIVE_PAUSED)
      and (AmbientSoundtrackFile<>'') and SameText(AmbientSoundtrackFile, FileName) then begin
      ResumeAmbientSoundtrack;
      result:=True;
      exit;
    end;
    if (BASS_ChannelIsActive(BassSoundChannel)=BASS_ACTIVE_PLAYING)
      and (AmbientSoundtrackFile<>'') and SameText(AmbientSoundtrackFile, FileName) then begin
      result:=True;
      exit;
    end;
    BASS_StreamFree(BassSoundChannel);
    BassSoundChannel:=0;
  end;
  if not BassInited then begin
    LogInfo('BASS: ambient play failed (not initialized) path='+FileName);
    AmbientSoundtrackFile:='';
    exit;
  end;
  if FileName='' then begin
    LogInfo('BASS: ambient play failed (empty path)');
    AmbientSoundtrackFile:='';
    exit;
  end;
  if not FileExists(FileName) then begin
    LogInfo('BASS: ambient play failed (file missing) path='+FileName);
    AmbientSoundtrackFile:='';
    exit;
  end;
  Path:=UnicodeString(FileName);
  Chan:=BASS_StreamCreateFile(0, PWideChar(Path), 0, 0, BASS_UNICODE or BASS_SAMPLE_LOOP);
  if Chan=0 then begin
    LogInfo('BASS: ambient StreamCreateFile failed path='+FileName+
      ' error='+IntToStr(BASS_ErrorGetCode));
    AmbientSoundtrackFile:='';
    exit;
  end;
  BassSoundChannel:=Chan;
  BassMediaFilePath:=FileName;
  { Always skip lead-in; POS_LOOP so every wrap restarts after silence. }
  ApplySkipLeadingSilence(BassSoundChannel, FileName, True);
  if not BASS_ChannelPlay(BassSoundChannel, False) then begin
    LogInfo('BASS: ambient ChannelPlay failed error='+IntToStr(BASS_ErrorGetCode));
    BASS_StreamFree(BassSoundChannel);
    BassSoundChannel:=0;
    AmbientSoundtrackFile:='';
    BassMediaFilePath:='';
    exit;
  end;
  AmbientSoundtrackFile:=FileName;
  result:=True;
end;

function PauseAmbientSoundtrack : Boolean;
begin
  result:=False;
  if BassSoundChannel=0 then exit;
  if BASS_ChannelIsActive(BassSoundChannel)<>BASS_ACTIVE_PLAYING then exit;
  result:=BASS_ChannelPause(BassSoundChannel);
end;

procedure ResumeAmbientSoundtrack;
begin
  if BassSoundChannel=0 then exit;
  if BASS_ChannelIsActive(BassSoundChannel)=BASS_ACTIVE_PAUSED then
    BASS_ChannelPlay(BassSoundChannel,False);
end;

procedure StopAmbientSoundtrack;
begin
  if BassSoundChannel=0 then exit;
  BASS_StreamFree(BassSoundChannel);
  BassSoundChannel:=0;
  AmbientSoundtrackFile:='';
  BassMediaFilePath:='';
end;

end.
