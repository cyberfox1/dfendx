unit PlaySoundFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ImgList, ComCtrls, ToolWin, Menus;

type
  TPlaySoundForm = class(TForm)
    ImageList: TImageList;
    PopupMenu: TPopupMenu;
    MenuSave: TMenuItem;
    MenuSaveMp3: TMenuItem;
    MenuSaveOgg: TMenuItem;
    SaveDialog: TSaveDialog;
    StatusBar: TStatusBar;
    TrackBar: TTrackBar;
    Timer: TTimer;
    CoolBar: TCoolBar;
    ToolBar: TToolBar;
    ToolButton1: TToolButton;
    SaveButton: TToolButton;
    ToolButton2: TToolButton;
    PreviousButton: TToolButton;
    NextButton: TToolButton;
    PlayPauseButton: TToolButton;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonWork(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    { Private-Deklarationen }
    JustChanging : Boolean;
  public
    { Public-Deklarationen }
    FileDamaged : Boolean;
    FileName : String;
    PrevSounds, NextSounds : TStringList;
  end;

type
  TAfterPlaySoundDialog = procedure of object;

var
  PlaySoundForm: TPlaySoundForm;
  AfterPlaySoundDialog: TAfterPlaySoundDialog;

Procedure PlaySoundDialog(const AOwner : TComponent; const AFileName : String; const APrevSounds, ANextSounds : TStringList);

implementation

uses ShellAPI, MediaInterface, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools,
     PrgConsts, PrgSetupUnit, SetupFrameWaveEncoderUnit, IconLoaderUnit, System.Types, System.UITypes,
     LoggingUnit, BassMedia;

{$R *.dfm}

procedure TPlaySoundForm.FormCreate(Sender: TObject);
begin
  SetVistaFonts(self);
  Font.Charset:=CharsetNameToFontCharSet(LanguageSetup.CharsetName);

  PreviousButton.Caption:=LanguageSetup.Previous;
  PreviousButton.Hint:=LanguageSetup.PreviousHintMediaViewer;
  NextButton.Caption:=LanguageSetup.Next;
  NextButton.Hint:=LanguageSetup.NextHintMediaViewer;
  SaveButton.Caption:=LanguageSetup.Save;
  SaveButton.Hint:=LanguageSetup.SaveHintSoundPlayer;
  PlayPauseButton.Caption:=LanguageSetup.SoundCapturePlayPause;
  PlayPauseButton.Hint:=LanguageSetup.SoundCapturePlayPauseHint;
  MenuSave.Caption:=LanguageSetup.ScreenshotPopupSave;
  MenuSaveMp3.Caption:=LanguageSetup.SoundsPopupSaveMp3;
  MenuSaveOgg.Caption:=LanguageSetup.SoundsPopupSaveOgg;

  UserIconLoader.DialogImage(DI_Save,ImageList,0);
  UserIconLoader.DialogImage(DI_Previous,ImageList,1);
  UserIconLoader.DialogImage(DI_Next,ImageList,2);
  UserIconLoader.DialogImage(DI_Run,ImageList,3);

  CoolBar.Font.Size:=PrgSetup.ToolbarFontSize;

  JustChanging:=False;

  PrevSounds:=TStringList.Create;
  NextSounds:=TStringList.Create;
end;

procedure TPlaySoundForm.FormShow(Sender: TObject);
Var S : String;
begin
  Timer.Enabled:=False;

  If Assigned(MediaStreamAvailable) and MediaStreamAvailable then begin
    If Assigned(stopMediaStream) then stopMediaStream;
    If Assigned(resetMediaStream) then resetMediaStream;
  end;

  PreviousButton.Enabled:=(PrevSounds<>nil) and (PrevSounds.Count>0);
  NextButton.Enabled:=(NextSounds<>nil) and (NextSounds.Count>0);

  Caption:=LanguageSetup.CaptureSounds+' ['+MakeRelPath(FileName,PrgSetup.BaseDir)+']';
  FileDamaged:=False;

  StatusBar.Panels[1].Text:=FileName;
  LogInfo('PlaySound FormShow: file="'+FileName+'" bassReady='+
    BoolToStr(BassMediaReady,True)+' loadBound='+BoolToStr(Assigned(loadMediaFile),True));
  If not Assigned(loadMediaFile) then begin
    LogInfo('PlaySound: loadMediaFile not bound');
    FileDamaged:=True;
  end else If not FileExists(FileName) then begin
    LogInfo('PlaySound: file missing '+FileName);
    FileDamaged:=True;
  end else begin
    LogInfo('PlaySound: calling loadMediaFile len='+IntToStr(Length(FileName)));
    loadMediaFile(FileName,Handle);
    FileDamaged:=not (Assigned(MediaStreamAvailable) and MediaStreamAvailable);
    If FileDamaged then
      LogInfo('PlaySound: stream not available after load '+FileName)
    else
      LogInfo('PlaySound: stream OK after load');
  end;

  SaveButton.Enabled:=not FileDamaged;
  PlayPauseButton.Enabled:=not FileDamaged;

  S:=ExtUpperCase(ExtractFileExt(FileName));
  MenuSaveMp3.Enabled:=(S='.WAV') and FileExists(PrgSetup.WaveEncMp3);
  MenuSaveOgg.Enabled:=(S='.WAV') and FileExists(PrgSetup.WaveEncOgg);

  If (not FileDamaged) and Assigned(MediaStreamAvailable) and MediaStreamAvailable then begin
    JustChanging:=True;
    try
      TrackBar.Position:=0;
    finally
      JustChanging:=False;
    end;
    ButtonWork(PlayPauseButton);
  end;

  Timer.Enabled:=True;
end;

procedure TPlaySoundForm.FormDestroy(Sender: TObject);
begin
  If Assigned(freeMediaStream) then freeMediaStream;
  PrevSounds.Free;
  NextSounds.Free;
end;

procedure TPlaySoundForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  If Shift=[] then Case Key of
    VK_LEFT, VK_UP, VK_PRIOR : ButtonWork(PreviousButton);
    VK_RIGHT, VK_DOWN, VK_NEXT : ButtonWork(NextButton);
    VK_ESCAPE : Close;
  end;
end;

procedure TPlaySoundForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  If Shift=[] then begin
    If WheelDelta>0 then ButtonWork(PreviousButton) else ButtonWork(NextButton);
  end;
end;

procedure TPlaySoundForm.TimerTimer(Sender: TObject);
begin
  If FileDamaged then exit;
  If not (Assigned(MediaStreamAvailable) and Assigned(getMediaStreamDuration) and Assigned(getMediaStreamPos)) then exit;
  JustChanging:=True;
  try
    try
      If MediaStreamAvailable and (getMediaStreamDuration>0) then begin
        TrackBar.Position:=Round(100*getMediaStreamPos/getMediaStreamDuration);
        StatusBar.Panels[0].Text:=FloatToStrF(getMediaStreamPos/1000/10000,ffFixed,15,3)+'/'+FloatToStrF(getMediaStreamDuration/1000/10000,ffFixed,15,3);
        If (getMediaStreamPos=getMediaStreamDuration) and Assigned(MediaStreamPlayed) and MediaStreamPlayed and Assigned(pauseMediaStream) then
          pauseMediaStream;
      end;
    except end;
  finally
    JustChanging:=False;
  end;
end;

procedure TPlaySoundForm.TrackBarChange(Sender: TObject);
begin
  If JustChanging or FileDamaged then exit;
  If not (Assigned(MediaStreamAvailable) and MediaStreamAvailable and Assigned(setMediaStreamPos) and Assigned(getMediaStreamDuration)) then exit;
  setMediaStreamPos(Round(TrackBar.Position*getMediaStreamDuration/100));
end;

procedure TPlaySoundForm.ButtonWork(Sender: TObject);
Var P : TPoint;
    S : String;
begin
  Case (Sender as TComponent).Tag of
    0 : If PrevSounds.Count>0 then begin
          Timer.Enabled:=False;
          NextSounds.Insert(0,FileName);
          FileName:=PrevSounds[PrevSounds.Count-1];
          PrevSounds.Delete(PrevSounds.Count-1);
          FormShow(Sender);
        end;
    1 : if NextSounds.Count>0 then begin
          Timer.Enabled:=False;
          PrevSounds.Add(FileName);
          FileName:=NextSounds[0];
          NextSounds.Delete(0);
          FormShow(Sender);
        end;
    2 : begin
          P:=ToolBar.ClientToScreen(Point(SaveButton.Left+5,SaveButton.Top+5));
          PopupMenu.Popup(P.X,P.Y);
        end;
    3 : begin
          S:=ExtractFileExt(FileName);
          If (S<>'') and (S[1]='.') then S:=Copy(S,2,MaxInt);
          SaveDialog.DefaultExt:=S;
          SaveDialog.Title:=LanguageSetup.SoundCaptureSaveTitle;
          S:=Trim(ExtUpperCase(S));
          SaveDialog.Filter:=LanguageSetup.SoundCaptureSaveWAVFilter;
          If S='MP3' then SaveDialog.Filter:=LanguageSetup.SoundCaptureSaveMP3Filter;
          If S='OGG' then SaveDialog.Filter:=LanguageSetup.SoundCaptureSaveOGGFilter;
          If (S='MID') or (S='MIDI') then SaveDialog.Filter:=LanguageSetup.SoundCaptureSaveMIDFilter;
          If not SaveDialog.Execute then exit;
          S:=SaveDialog.FileName;
          If not CopyFile(PChar(FileName),PChar(S),True) then MessageDlg(Format(LanguageSetup.MessageCouldNotCopyFile,[FileName,S]),mtError,[mbOK],0);
        end;
    4 : begin
          SaveDialog.DefaultExt:='mp3';
          SaveDialog.Title:=LanguageSetup.SoundCaptureSaveTitle;
          SaveDialog.Filter:=LanguageSetup.SoundCaptureSaveMP3Filter;
          If not SaveDialog.Execute then exit;
          S:=SaveDialog.FileName;
          ShellExecute(Handle,'open',PChar(PrgSetup.WaveEncMp3),PChar(ProcessEncoderParameters(PrgSetup.WaveEncMp3Parameters,FileName,S)),nil,SW_SHOW);
        end;
    5 : begin
          SaveDialog.DefaultExt:='ogg';
          SaveDialog.Title:=LanguageSetup.SoundCaptureSaveTitle;
          SaveDialog.Filter:=LanguageSetup.SoundCaptureSaveOGGFilter;
          If not SaveDialog.Execute then exit;
          S:=SaveDialog.FileName;
          ShellExecute(Handle,'open',PChar(PrgSetup.WaveEncOgg),PChar(ProcessEncoderParameters(PrgSetup.WaveEncOggParameters,FileName,S)),nil,SW_SHOW);
        end;
    6 : if Assigned(MediaStreamAvailable) and MediaStreamAvailable then begin
          If Assigned(MediaStreamPlayed) and MediaStreamPlayed and
             Assigned(getMediaStreamPos) and Assigned(getMediaStreamDuration) and
             (getMediaStreamPos<>getMediaStreamDuration) then begin
            If Assigned(pauseMediaStream) then pauseMediaStream;
          end else begin
            If Assigned(getMediaStreamPos) and Assigned(getMediaStreamDuration) and
               Assigned(setMediaStreamPos) and (getMediaStreamPos=getMediaStreamDuration) then
              setMediaStreamPos(0);
            If Assigned(playMediaStream) then playMediaStream;
          end;
        end;
  end;
end;

{ global }

function IsAudioExtensionAllowed(const Ext : String) : Boolean;
Var I : Integer;
    E : String;
begin
  result:=False;
  E:=ExtUpperCase(Ext);
  if (E<>'') and (E[1]<>'.') then E:='.'+E;
  for I:=Low(AudioExtensions) to High(AudioExtensions) do
    if E=ExtUpperCase(AudioExtensions[I]) then begin
      result:=True;
      exit;
    end;
end;

Procedure PlaySoundDialog(const AOwner : TComponent; const AFileName : String; const APrevSounds, ANextSounds : TStringList);
Var S : String;
begin
  LogInfo('PlaySoundDialog: file="'+AFileName+'" player="'+PrgSetup.SoundPlayer+'"');
  If OpenMediaFile(PrgSetup.SoundPlayer,AFileName) then begin
    LogInfo('PlaySoundDialog: handled by external OpenMediaFile');
    exit;
  end;

  S:=ExtUpperCase(ExtractFileExt(AFileName));
  { Same set as Sounds list fill: PrgConsts.AudioExtensions. }
  If not IsAudioExtensionAllowed(S) then begin
    LogInfo('PlaySoundDialog: abort unsupported extension "'+S+'" (not in AudioExtensions)');
    exit;
  end;

  LogInfo('PlaySoundDialog: opening internal player for '+S);
  PauseAmbientSoundtrack;
  PlaySoundForm:=TPlaySoundForm.Create(AOwner);
  try
    PlaySoundForm.FileName:=AFileName;
    If APrevSounds<>nil then PlaySoundForm.PrevSounds.Assign(APrevSounds);
    If ANextSounds<>nil then PlaySoundForm.NextSounds.Assign(ANextSounds);
    If (APrevSounds=nil) and (ANextSounds=nil) then begin
      PlaySoundForm.PreviousButton.Visible:=False;
      PlaySoundForm.NextButton.Visible:=False;
      PlaySoundForm.ToolButton1.Visible:=False;
    end;
    PlaySoundForm.ShowModal;
  finally
    PlaySoundForm.Free;
    PlaySoundForm:=nil;
    If Assigned(AfterPlaySoundDialog) then AfterPlaySoundDialog;
  end;
  LogInfo('PlaySoundDialog: internal player closed');
end;

end.
