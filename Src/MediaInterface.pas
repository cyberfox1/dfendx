// Copyright(C) Lord Dr. Andrei J. Sagura II von Orechov. All rights reserved.
// Dynamic bind extension by A. Herzog
unit MediaInterface;

interface

uses Windows, Messages;

{ Point sound APIs at BASS; video exports are safe stubs (Phase 2.3–2.7). }
procedure BindBassSoundLoad;

Var  aboutMediaPlayer : function : shortString; stdcall;
     loadMediaFile : function (FileName : String; aHandle : THandle) : String; stdcall;
     MediaStreamAvailable : function : boolean; stdcall;
     VideoAvailable : function : boolean; stdcall;
     MediaStreamPlayed : function : boolean; stdcall;
     getCoupledVideoHeight : function (Width : integer) : integer; stdcall;
     getVideoWidth : function : integer; stdcall;
     getVideoHeight : function : integer; stdcall;
     getMediaStreamDuration : function : int64; stdcall;
     setVideoPos : function (aLeft, aTop, aWidth, aHeight : integer) : BOOL; stdcall;
     playMediaStream : function : BOOL; stdcall;
     pauseMediaStream : function : BOOL; stdcall;
     stopMediaStream : function : BOOL; stdcall;
     setMediaStreamPos : function (pos : int64) : BOOL; stdcall;
     getMediaStreamPos : function : int64; stdcall;
     freeMediaStream : function : BOOL; stdcall;
     resetMediaStream : function : BOOL; stdcall;
     setFullScreenVideo : function (Full : BOOL) : BOOL; stdcall;
     getFullScreenVideo : function : BOOL; stdcall;
     registerFileType : procedure (aFileType, key, desc, icon, aApplication : shortString); stdcall;
     deregisterFileType : procedure (aFileType : shortString); stdcall;
     getSpecialFolderName : function (aHandle : THandle; nFolder : integer) : shortString; stdcall;
     SoundChipAvailable : function : boolean; stdcall;
     getWaveOutVolume : function : integer; stdcall;
     setWaveOutVolume : procedure (Volume : cardinal); stdcall;
     lnVolume : function (aVolume : integer; aDecades : integer = 1) : integer; stdcall;
     expVolume : function (aVolume : integer; aDecades : integer = 1) : integer; stdcall;
     NotifyOwnerMessage : function (aHandle : THandle; aMsg : TMessage): HResult; stdcall;

implementation

uses BassMedia;

{ Video exports unused (no in-process player); stubs stay non-nil for safety. }
function StubVideoAvailable : boolean; stdcall;
begin
  result:=False;
end;

function StubGetVideoWidth : integer; stdcall;
begin
  result:=0;
end;

function StubGetVideoHeight : integer; stdcall;
begin
  result:=0;
end;

function StubGetCoupledVideoHeight(Width : integer) : integer; stdcall;
begin
  result:=0;
end;

function StubSetVideoPos(aLeft, aTop, aWidth, aHeight : integer) : BOOL; stdcall;
begin
  result:=False;
end;

function StubSetFullScreenVideo(Full : BOOL) : BOOL; stdcall;
begin
  result:=False;
end;

function StubGetFullScreenVideo : BOOL; stdcall;
begin
  result:=False;
end;

procedure BindBassSoundLoad;
begin
  loadMediaFile:=@BassLoadMediaFile;
  MediaStreamAvailable:=@BassMediaStreamAvailable;
  MediaStreamPlayed:=@BassMediaStreamPlayed;
  playMediaStream:=@BassPlayMediaStream;
  pauseMediaStream:=@BassPauseMediaStream;
  stopMediaStream:=@BassStopMediaStream;
  getMediaStreamDuration:=@BassGetMediaStreamDuration;
  getMediaStreamPos:=@BassGetMediaStreamPos;
  setMediaStreamPos:=@BassSetMediaStreamPos;
  freeMediaStream:=@BassFreeMediaStream;
  resetMediaStream:=@BassResetMediaStream;

  VideoAvailable:=@StubVideoAvailable;
  getVideoWidth:=@StubGetVideoWidth;
  getVideoHeight:=@StubGetVideoHeight;
  getCoupledVideoHeight:=@StubGetCoupledVideoHeight;
  setVideoPos:=@StubSetVideoPos;
  setFullScreenVideo:=@StubSetFullScreenVideo;
  getFullScreenVideo:=@StubGetFullScreenVideo;
end;

initialization
  aboutMediaPlayer:=nil;
  loadMediaFile:=nil;
  MediaStreamAvailable:=nil;
  VideoAvailable:=nil;
  MediaStreamPlayed:=nil;
  getCoupledVideoHeight:=nil;
  getVideoWidth:=nil;
  getVideoHeight:=nil;
  getMediaStreamDuration:=nil;
  setVideoPos:=nil;
  playMediaStream:=nil;
  pauseMediaStream:=nil;
  stopMediaStream:=nil;
  setMediaStreamPos:=nil;
  getMediaStreamPos:=nil;
  freeMediaStream:=nil;
  resetMediaStream:=nil;
  setFullScreenVideo:=nil;
  getFullScreenVideo:=nil;
  registerFileType:=nil;
  deregisterFileType:=nil;
  getSpecialFolderName:=nil;
  SoundChipAvailable:=nil;
  getWaveOutVolume:=nil;
  setWaveOutVolume:=nil;
  lnVolume:=nil;
  expVolume:=nil;
  NotifyOwnerMessage:=nil;
finalization
  aboutMediaPlayer:=nil; loadMediaFile:=nil;
  MediaStreamAvailable:=nil; VideoAvailable:=nil;
  MediaStreamPlayed:=nil; getCoupledVideoHeight:=nil;
  getVideoWidth:=nil; getVideoHeight:=nil;
  getMediaStreamDuration:=nil; setVideoPos:=nil;
  playMediaStream:=nil; pauseMediaStream:=nil;
  stopMediaStream:=nil; setMediaStreamPos:=nil;
  getMediaStreamPos:=nil; freeMediaStream:=nil;
  resetMediaStream:=nil; setFullScreenVideo:=nil;
  getFullScreenVideo:=nil; registerFileType:=nil;
  deregisterFileType:=nil; getSpecialFolderName:=nil;
  SoundChipAvailable:=nil; getWaveOutVolume:=nil;
  setWaveOutVolume:=nil; lnVolume:=nil;
  expVolume:=nil; NotifyOwnerMessage:=nil;

end.

