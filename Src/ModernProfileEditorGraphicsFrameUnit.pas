unit ModernProfileEditorGraphicsFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Spin, ExtCtrls, GameDBUnit, ModernProfileEditorFormUnit,
  PrgConsts, DOSBoxShadersHelpers;

type
  TModernProfileEditorGraphicsFrame = class(TFrame, IModernProfileEditorFrame)
    WindowResolutionLabel: TLabel;
    WindowResolutionComboBox: TComboBox;
    FullscreenResolutionLabel: TLabel;
    FullscreenResolutionComboBox: TComboBox;
    StartFullscreenCheckBox: TCheckBox;
    DoublebufferingCheckBox: TCheckBox;
    KeepAspectRatioCheckBox: TCheckBox;
    RenderLabel: TLabel;
    RenderComboBox: TComboBox;
    VideoCardLabel: TLabel;
    VideoCardComboBox: TComboBox;
    ScaleLabel: TLabel;
    ScaleComboBox: TComboBox;
    FrameSkipLabel: TLabel;
    FrameSkipEdit: TSpinEdit;
    TextModeLinesRadioGroup: TRadioGroup;
    VGASettingsGroupBox: TGroupBox;
    VGAChipsetLabel: TLabel;
    VGAChipsetComboBox: TComboBox;
    VideoRamLabel: TLabel;
    VideoRamComboBox: TComboBox;
    VGASettingsLabel: TLabel;
    FullscreenInfoLabel: TLabel;
    PixelShaderComboBox: TComboBox;
    PixelShaderLabel: TLabel;
    ResolutionInfoLabel: TLabel;
    GlideEmulationLabel: TLabel;
    GlideEmulationComboBox: TComboBox;
    GlideEmulationPortLabel: TLabel;
    GlideEmulationPortComboBox: TComboBox;
    GlideEmulationLFBLabel: TLabel;
    GlideEmulationLFBComboBox: TComboBox;
    ShaderPresetComboBox: TComboBox;
    ShaderPresetLabel: TLabel;
    VSyncComboBox: TComboBox;
    VSyncLabel: TLabel;
    rgScreenInactive: TRadioGroup;
    procedure PixelShaderComboBoxChange(Sender: TObject);
    procedure PixelShaderComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PixelShaderComboBoxKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ShaderPresetComboBoxChange(Sender: TObject);
    procedure ShaderPresetComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ShaderPresetComboBoxKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure VSyncComboBoxChange(Sender: TObject);
  private
    { Private-Deklarationen }
    ProfileDOSBoxInstallation : PString;
    { DOSBox install key last used for shader UI (CustomDOSBoxDir / live pointer). }
    FShaderInstallKey : String;
    LastPixelShader : String;
    LastShaderPreset : String;
    LastVSync : String;
    LastRender : String;
    LastVideoCard : String;
    FScaleConfOpt : String;
    FRenderConfOpt : String;
    FRenderStagingConfOpt : String;
    FRenderXConfOpt : String;
    FVSyncStagingConfOpt : String;
    FVSyncStagingOldConfOpt : String;
    FVSyncXConfOpt : String;
    VSyncComboBoxChanged : Boolean;
    PixelShaderChanged :  Boolean;
    ShaderPresetChanged : Boolean;
    FAllPixelShaders : TStringList;
    FAllPresets : TStringList;
    FBackendMaps : TDOSBoxShaderBackendMaps; { owns OpenGL + Direct3D maps }
    FShaderMap : TStringList; { active backend map; not owned (points into FBackendMaps) }
    FFilteringPixelShaders : Boolean;
    FFilteringPresets : Boolean;
    Function GetDOSBoxDir : String;
    Function GetSelectedDosBoxKind : TDOSBoxKind;
    { True when Render is a backend that can use shaders (opengl/openglnb or direct3d). }
    Function RenderSupportsShaders : Boolean;
    Function ActiveShaderMap : TStringList;
    Procedure FreeBackendMaps;
    Procedure ReloadPixelShaderList;
    Procedure FillShaderListFromActiveMap;
    Procedure ApplyShaderControlsEnabled;
    Procedure ApplyPixelShaderFilter;
    Procedure ApplyShaderPresetFilter;
    Procedure RefreshPresetComboForCurrentShader(const ApplyLastPreset : Boolean);
    { Staging/X only: fill combo values and visibility for current install kind. }
    Procedure ApplyVSyncControls;
    { Staging only: mute/pause when inactive. }
    Procedure ApplyInactiveControls;
    Procedure ApplyScalerControls;
    Procedure ApplyFrameSkipControls;
    { Fill render combo from ConfOpt for current kind, then select PreferredValue. }
    Procedure ApplyRenderList(const PreferredValue : String = '');
    { X only: PC-98 / DOS/V / Olivetti / 3270PC entries; PreferredValue re-selected after list update. }
    Procedure ApplyXMachineTypesToVideoList(const PreferredValue : String = '');
    Function MapKeyToDisplay(const Key : String) : String;
    Function DisplayToMapKey(const Display : String) : String;
    Function NormalizeShaderDisplay(const S : String) : String;
    Function ShaderMapIndexOfDisplay(const Display : String) : Integer;
    Procedure ShowFrame(Sender : TObject);
    Procedure RenderComboBoxChange(Sender : TObject);
  public
    { Public-Deklarationen }
    Constructor Create(AOwner : TComponent); override;
    Destructor Destroy; override;
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools, PrgSetupUnit,
     HelpConsts, GameDBToolsUnit, GameDBToolsHelpers, GameDBHelpers, DOSBoxUnitHelpers;

{$R *.dfm}

{ TModernProfileEditorGraphicsFrame }

constructor TModernProfileEditorGraphicsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAllPixelShaders:=TStringList.Create;
  FAllPresets:=TStringList.Create;
  FBackendMaps.OpenGL:=nil;
  FBackendMaps.Direct3D:=nil;
  FShaderMap:=nil;
  FFilteringPixelShaders:=False;
  FFilteringPresets:=False;
end;

destructor TModernProfileEditorGraphicsFrame.Destroy;
begin
  FreeBackendMaps;
  FreeAndNil(FAllPixelShaders);
  FreeAndNil(FAllPresets);
  inherited Destroy;
end;

procedure TModernProfileEditorGraphicsFrame.FreeBackendMaps;
begin
  FShaderMap:=nil;
  FreeShaderBackendMaps(FBackendMaps);
end;

function TModernProfileEditorGraphicsFrame.RenderSupportsShaders: Boolean;
Var S : String;
begin
  { Matches GetDOSBoxShaders backends: "opengl" (openglnb counts as opengl) and "direct3d". }
  S:=Trim(ExtUpperCase(RenderComboBox.Text));
  Result:=(S='OPENGL') or (S='OPENGLNB') or (S='DIRECT3D');
end;

function TModernProfileEditorGraphicsFrame.ActiveShaderMap: TStringList;
begin
  { Combo text is the conf output value (e.g. opengl, openglnb, direct3d). }
  if not RenderSupportsShaders then
    Result:=nil
  else if SameText(Trim(RenderComboBox.Text),'direct3d') then
    Result:=FBackendMaps.Direct3D
  else
    Result:=FBackendMaps.OpenGL;
end;

procedure TModernProfileEditorGraphicsFrame.ApplyShaderControlsEnabled;
begin
  if not RenderSupportsShaders then begin
    PixelShaderComboBox.Enabled:=False;
    ShaderPresetComboBox.Enabled:=False;
  end else begin
    PixelShaderComboBox.Enabled:=FAllPixelShaders.Count>0;
    { Preset enable left to RefreshPresetComboForCurrentShader. }
  end;
end;

function TModernProfileEditorGraphicsFrame.MapKeyToDisplay(const Key : String) : String;
begin
  Result:=StringReplace(Key,PathDelim,'/',[rfReplaceAll]);
end;

function TModernProfileEditorGraphicsFrame.DisplayToMapKey(const Display : String) : String;
begin
  Result:=StringReplace(Trim(Display),'/',PathDelim,[rfReplaceAll]);
end;

function TModernProfileEditorGraphicsFrame.NormalizeShaderDisplay(const S : String) : String;
begin
  Result:=MapKeyToDisplay(DisplayToMapKey(S));
end;

function TModernProfileEditorGraphicsFrame.ShaderMapIndexOfDisplay(const Display : String) : Integer;
begin
  if FShaderMap=nil then begin Result:=-1; Exit; end;
  Result:=FShaderMap.IndexOf(DisplayToMapKey(Display));
end;

procedure TModernProfileEditorGraphicsFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var St : TStringList;
    I : Integer;
    S : String;
begin
  InitData.OnShowFrame:=ShowFrame;

  NoFlicker(WindowResolutionComboBox);
  NoFlicker(FullscreenResolutionComboBox);
  NoFlicker(StartFullscreenCheckBox);
  NoFlicker(DoublebufferingCheckBox);
  NoFlicker(KeepAspectRatioCheckBox);
  NoFlicker(GlideEmulationComboBox);
  NoFlicker(GlideEmulationPortComboBox);
  NoFlicker(GlideEmulationLFBComboBox);
  NoFlicker(RenderComboBox);
  NoFlicker(VideoCardComboBox);
  NoFlicker(PixelShaderComboBox);
  NoFlicker(ShaderPresetComboBox);
  NoFlicker(VSyncComboBox);
  NoFlicker(rgScreenInactive);
  NoFlicker(VGASettingsGroupBox);
  NoFlicker(VGAChipsetComboBox);
  NoFlicker(VideoRamComboBox);
  NoFlicker(ScaleComboBox);
  NoFlicker(FrameSkipEdit);
  NoFlicker(TextModeLinesRadioGroup);

  WindowResolutionLabel.Caption:=LanguageSetup.GameWindowResolution;
  FullscreenResolutionLabel.Caption:=LanguageSetup.GameFullscreenResolution;
  St:=ValueToList(InitData.GameDB.ConfOpt.ResolutionWindow,';,');
  try WindowResolutionComboBox.Items.AddStrings(St); finally St.Free; end;
  St:=ValueToList(InitData.GameDB.ConfOpt.ResolutionFullscreen,';,');
  try FullscreenResolutionComboBox.Items.AddStrings(St); finally St.Free; end;
  ResolutionInfoLabel.Caption:=LanguageSetup.GameResolutionInfo;
  StartFullscreenCheckBox.Caption:=LanguageSetup.GameStartFullscreen;
  FullscreenInfoLabel.Caption:='('+LanguageSetup.GameStartFullscreenInfo+')';
  DoublebufferingCheckBox.Caption:=LanguageSetup.GameUseDoublebuffering;
  KeepAspectRatioCheckBox.Caption:=LanguageSetup.GameAspectCorrection;
  GlideEmulationLabel.Caption:=LanguageSetup.GameGlideEmulation;
  GlideEmulationPortLabel.Caption:=LanguageSetup.GameGlideEmulationPort;
  GlideEmulationLFBLabel.Caption:=LanguageSetup.GameGlideEmulationLFB;

  St:=ValueToList(InitData.GameDB.ConfOpt.GlideEmulation,';,');
  try
    For I:=0 to St.Count-1 do begin
      S:=Trim(ExtUpperCase(St[I]));
      if S='FALSE' then St[I]:=LanguageSetup.Off;
      if S='TRUE' then St[I]:=LanguageSetup.On;
    end;
    GlideEmulationComboBox.Items.Clear;
    GlideEmulationComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;
  St:=ValueToList(InitData.GameDB.ConfOpt.GlideEmulationPort,';,');
  try
    GlideEmulationPortComboBox.Items.Clear;
    GlideEmulationPortComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;
  St:=ValueToList(InitData.GameDB.ConfOpt.GlideEmulationLFB,';,');
  try
    GlideEmulationLFBComboBox.Items.Clear;
    GlideEmulationLFBComboBox.Items.AddStrings(St);
  finally
    St.Free;
  end;
  RenderLabel.Caption:=LanguageSetup.GameRender;
  FRenderConfOpt:=InitData.GameDB.ConfOpt.Render;
  FRenderStagingConfOpt:=InitData.GameDB.ConfOpt.RenderStaging;
  FRenderXConfOpt:=InitData.GameDB.ConfOpt.RenderX;
  FVSyncStagingConfOpt:=InitData.GameDB.ConfOpt.VSyncStaging;
  FVSyncStagingOldConfOpt:=InitData.GameDB.ConfOpt.VSyncStagingOld;
  FVSyncXConfOpt:=InitData.GameDB.ConfOpt.VSyncX;
  St:=ValueToList(FRenderConfOpt,';,'); try RenderComboBox.Items.AddStrings(St); finally St.Free; end;
  RenderComboBox.OnChange:=RenderComboBoxChange;
  VideoCardLabel.Caption:=LanguageSetup.GameVideoCard;
  St:=ValueToList(InitData.GameDB.ConfOpt.Video,';,'); try VideoCardComboBox.Items.AddStrings(St); finally St.Free; end;
  VGASettingsGroupBox.Caption:=LanguageSetup.GameVGASettings;
  VGAChipsetLabel.Caption:=LanguageSetup.GameVGAChipset;
  St:=ValueToList(InitData.GameDB.ConfOpt.VGAChipsets,';,'); try VGAChipsetComboBox.Items.AddStrings(St); finally St.Free; end;
  VideoRamLabel.Caption:=LanguageSetup.GameVideoRam;
  St:=ValueToList(InitData.GameDB.ConfOpt.VGAVideoRAM,';,'); try VideoRamComboBox.Items.AddStrings(St); finally St.Free; end;
  VGASettingsLabel.Caption:=LanguageSetup.GameVGASettingsInfo;
  ScaleLabel.Caption:=LanguageSetup.GameScale;
  FScaleConfOpt:=InitData.GameDB.ConfOpt.Scale;
  St:=ValueToList(FScaleConfOpt,';,'); try ScaleComboBox.Items.AddStrings(St); finally St.Free; end;
  FrameSkipLabel.Caption:=LanguageSetup.GameFrameskip;
  TextModeLinesRadioGroup.Caption:=LanguageSetup.GameTextModeLines;
  PixelShaderLabel.Caption:=LanguageSetup.GamePixelShader;
  ShaderPresetLabel.Caption:=LanguageSetup.GameShaderPreset;
  VSyncLabel.Caption:=LanguageSetup.GameVSync;
  rgScreenInactive.Caption:=LanguageSetup.GameScreenInactive;
  rgScreenInactive.Items.BeginUpdate;
  try
    rgScreenInactive.Items.Clear;
    rgScreenInactive.Items.Add(LanguageSetup.GameScreenInactiveDoNothing);
    rgScreenInactive.Items.Add(LanguageSetup.GameScreenInactiveMute);
    rgScreenInactive.Items.Add(LanguageSetup.GameScreenInactivePause);
  finally
    rgScreenInactive.Items.EndUpdate;
  end;
  rgScreenInactive.ItemIndex:=0;
  PixelShaderComboBox.Style:=csDropDown;
  PixelShaderComboBox.AutoComplete:=False;
  PixelShaderComboBox.OnKeyDown:=PixelShaderComboBoxKeyDown;
  PixelShaderComboBox.OnKeyUp:=PixelShaderComboBoxKeyUp;
  ShaderPresetComboBox.Style:=csDropDown;
  ShaderPresetComboBox.AutoComplete:=False;
  ShaderPresetComboBox.OnChange:=ShaderPresetComboBoxChange;
  ShaderPresetComboBox.OnKeyDown:=ShaderPresetComboBoxKeyDown;
  ShaderPresetComboBox.OnKeyUp:=ShaderPresetComboBoxKeyUp;
  ShaderPresetComboBox.Enabled:=False;

  ProfileDOSBoxInstallation:=InitData.CurrentDOSBoxInstallation;

  AddDefaultValueHint(WindowResolutionComboBox);
  AddDefaultValueHint(FullscreenResolutionComboBox);
  AddDefaultValueHint(RenderComboBox);
  AddDefaultValueHint(VideoCardComboBox);
  AddDefaultValueHint(VGAChipsetComboBox);
  AddDefaultValueHint(VideoRamComboBox);
  AddDefaultValueHint(ScaleComboBox);

  HelpContext:=ID_ProfileEditGraphics;
end;

procedure TModernProfileEditorGraphicsFrame.PixelShaderComboBoxChange(Sender: TObject);
begin
  if FFilteringPixelShaders then Exit;
  { Blank or exact id from full list => user selection; otherwise filter only. }
  if (Trim(PixelShaderComboBox.Text)='') or (FAllPixelShaders.IndexOf(PixelShaderComboBox.Text)>=0) then begin
    PixelShaderChanged:=True;
    { Presets are per-shader; changing shader invalidates the previous preset. }
    LastShaderPreset:='';
    ShaderPresetChanged:=True;
    RefreshPresetComboForCurrentShader(False);
  end else
    ApplyPixelShaderFilter;
end;

function PixelShaderIsAsciiFilterKey(Key: Word; Shift: TShiftState): Boolean;
{ True only for plain ASCII filter typing — not Backspace/Del/Ctrl+X etc. }
begin
  Result:=False;
  if (ssCtrl in Shift) or (ssAlt in Shift) then Exit;
  if Key in [VK_BACK, VK_DELETE, VK_CLEAR, VK_RETURN, VK_ESCAPE, VK_TAB,
             VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_HOME, VK_END, VK_PRIOR, VK_NEXT,
             VK_SHIFT, VK_CONTROL, VK_MENU, VK_INSERT] then Exit;
  { Letters / digits (VK codes match ASCII for these) }
  if (Key>=Ord('A')) and (Key<=Ord('Z')) then begin Result:=True; Exit; end;
  if (Key>=Ord('0')) and (Key<=Ord('9')) then begin Result:=True; Exit; end;
  if (Key>=VK_NUMPAD0) and (Key<=VK_NUMPAD9) then begin Result:=True; Exit; end;
  { Hyphen / underscore / period / slash used in shader ids like crt/crt-hyllian }
  if Key in [VK_SPACE, VK_OEM_MINUS, VK_OEM_PERIOD, VK_SUBTRACT, VK_DECIMAL,
             VK_OEM_2, VK_DIVIDE] then
    Result:=True;
end;

procedure TModernProfileEditorGraphicsFrame.PixelShaderComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  { Open list only for ASCII filter chars, before the character is applied
    (matches open-with-mouse then type; avoids mouse hide). Do not open on
    Backspace/Del/Ctrl+X. }
  if FFilteringPixelShaders then Exit;
  if not PixelShaderIsAsciiFilterKey(Key,Shift) then Exit;
  if not PixelShaderComboBox.DroppedDown then
    PixelShaderComboBox.DroppedDown:=True;
end;

procedure TModernProfileEditorGraphicsFrame.PixelShaderComboBoxKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FFilteringPixelShaders then Exit;
  { Still refilter on delete keys (list already open or closed); just don't open. }
  if Key in [VK_RETURN, VK_ESCAPE, VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_TAB] then Exit;
  if (Trim(PixelShaderComboBox.Text)='') or (FAllPixelShaders.IndexOf(PixelShaderComboBox.Text)>=0) then begin
    PixelShaderChanged:=True;
    LastShaderPreset:='';
    ShaderPresetChanged:=True;
    RefreshPresetComboForCurrentShader(False);
    Exit;
  end;
  ApplyPixelShaderFilter;
end;

procedure TModernProfileEditorGraphicsFrame.ShaderPresetComboBoxChange(Sender: TObject);
begin
  if FFilteringPresets then Exit;
  if not ShaderPresetComboBox.Enabled then Exit;
  if (Trim(ShaderPresetComboBox.Text)='') or (FAllPresets.IndexOf(ShaderPresetComboBox.Text)>=0) then
    ShaderPresetChanged:=True
  else
    ApplyShaderPresetFilter;
end;

procedure TModernProfileEditorGraphicsFrame.ShaderPresetComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FFilteringPresets or (not ShaderPresetComboBox.Enabled) then Exit;
  if not PixelShaderIsAsciiFilterKey(Key,Shift) then Exit;
  if not ShaderPresetComboBox.DroppedDown then
    ShaderPresetComboBox.DroppedDown:=True;
end;

procedure TModernProfileEditorGraphicsFrame.ShaderPresetComboBoxKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FFilteringPresets or (not ShaderPresetComboBox.Enabled) then Exit;
  if Key in [VK_RETURN, VK_ESCAPE, VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_TAB] then Exit;
  if (Trim(ShaderPresetComboBox.Text)='') or (FAllPresets.IndexOf(ShaderPresetComboBox.Text)>=0) then begin
    ShaderPresetChanged:=True;
    Exit;
  end;
  ApplyShaderPresetFilter;
end;

function TModernProfileEditorGraphicsFrame.GetSelectedDosBoxKind: TDOSBoxKind;
begin
  Result:=DetermineDosBoxKind(GetDOSBoxDir, PrgSetup.BaseDir);
end;

procedure TModernProfileEditorGraphicsFrame.VSyncComboBoxChange(Sender: TObject);
begin
  VSyncComboBoxChanged:=True;
end;

procedure TModernProfileEditorGraphicsFrame.ApplyVSyncControls;
Var Kind: TDOSBoxKind;
    I: Integer;
    S, Version, ListSrc: String;
    ShowV, OldStaging: Boolean;
    St: TStringList;
begin
  Kind:=GetSelectedDosBoxKind;
  ShowV:=Kind in [dbkStaging,dbkX];
  VSyncLabel.Visible:=ShowV;
  VSyncComboBox.Visible:=ShowV;
  VSyncComboBox.Enabled:=ShowV;
  if not ShowV then begin
    VSyncComboBox.Items.Clear;
    Exit;
  end;

  Version:=CheckDOSBoxVersion(GetDOSBoxDir);
  OldStaging:=(Kind=dbkStaging) and (
    (Trim(Version)='') or (CompareDOSBoxVersion(Version,'0.83.0.0')<0));

  Case Kind of
    dbkStaging:
      if OldStaging then ListSrc:=FVSyncStagingOldConfOpt else ListSrc:=FVSyncStagingConfOpt;
    dbkX:
      ListSrc:=FVSyncXConfOpt;
    else
      ListSrc:='';
  end;

  St:=ValueToList(ListSrc,';,');
  try
    VSyncComboBox.Items.BeginUpdate;
    try
      VSyncComboBox.Items.Clear;
      VSyncComboBox.Items.AddStrings(St);
    finally
      VSyncComboBox.Items.EndUpdate;
    end;
  finally
    St.Free;
  end;

  S:=Trim(LastVSync);
  VSyncComboBox.ItemIndex:=-1;
  if S<>'' then
    for I:=0 to VSyncComboBox.Items.Count-1 do
      if SameText(VSyncComboBox.Items[I],S) then begin
        VSyncComboBox.ItemIndex:=I;
        break;
      end;

  VSyncComboBox.OnChange:=VSyncComboBoxChange;
  VSyncComboBoxChanged:=False;
end;

procedure EnableRadioGroupItem(const RG: TRadioGroup; const Index: Integer; const AEnabled: Boolean);
Var I, J: Integer;
begin
  If (RG=nil) or (Index<0) or (Index>=RG.Items.Count) then Exit;
  J:=0;
  For I:=0 to RG.ControlCount-1 do
    If RG.Controls[I] is TRadioButton then begin
      If J=Index then begin
        RG.Controls[I].Enabled:=AEnabled;
        Exit;
      end;
      Inc(J);
    end;
end;

procedure TModernProfileEditorGraphicsFrame.ApplyInactiveControls;
Var Kind: TDOSBoxKind;
begin
  Kind:=GetSelectedDosBoxKind;
  rgScreenInactive.Visible:=Kind in [dbkStaging,dbkX];
  { X has no mute-on-inactive; only do-nothing / pause via priority. }
  EnableRadioGroupItem(rgScreenInactive,Ord(simMute),Kind<>dbkX);
  If (Kind=dbkX) and (rgScreenInactive.ItemIndex=Ord(simMute)) then
    rgScreenInactive.ItemIndex:=Ord(simDoNothing);
end;

procedure TModernProfileEditorGraphicsFrame.ApplyScalerControls;
begin
  If GetSelectedDosBoxKind=dbkStaging then begin
    ScaleComboBox.Items.Clear;
    ScaleComboBox.Items.Add(LanguageSetup.GameScaleNotValidForStaging);
    ScaleComboBox.ItemIndex:=0;
    ScaleComboBox.Enabled:=False;
    ScaleLabel.Enabled:=False;
  end else begin
    ScaleComboBox.Enabled:=True;
    ScaleLabel.Enabled:=True;
  end;
end;

procedure TModernProfileEditorGraphicsFrame.ApplyFrameSkipControls;
Var Staging: Boolean;
begin
  Staging:=GetSelectedDosBoxKind=dbkStaging;
  FrameSkipEdit.Enabled:=not Staging;
  FrameSkipLabel.Enabled:=not Staging;
end;

procedure TModernProfileEditorGraphicsFrame.ApplyRenderList(const PreferredValue : String = '');
Var St: TStringList;
    Kind: TDOSBoxKind;
    I: Integer;
    Want, ListSrc: String;
    OldChange: TNotifyEvent;
begin
  Kind:=GetSelectedDosBoxKind;
  If Trim(PreferredValue)<>'' then Want:=Trim(PreferredValue)
  else Want:=Trim(RenderComboBox.Text);

  Case Kind of
    dbkStaging: ListSrc:=FRenderStagingConfOpt;
    dbkX:       ListSrc:=FRenderXConfOpt;
    else        ListSrc:=FRenderConfOpt;
  end;

  St:=ValueToList(ListSrc,';,');
  try
    { Load path only fills+selects. Do not fire OnChange (user change clears shaders). }
    OldChange:=RenderComboBox.OnChange;
    RenderComboBox.OnChange:=nil;
    try
      RenderComboBox.Items.BeginUpdate;
      try
        RenderComboBox.Items.Clear;
        RenderComboBox.Items.AddStrings(St);
      finally
        RenderComboBox.Items.EndUpdate;
      end;
      RenderComboBox.ItemIndex:=-1;
      For I:=0 to RenderComboBox.Items.Count-1 do
        If SameText(Trim(RenderComboBox.Items[I]),Want) then begin
          RenderComboBox.ItemIndex:=I;
          break;
        end;
    finally
      RenderComboBox.OnChange:=OldChange;
    end;
  finally
    St.Free;
  end;
end;

function VideoListHasMachineToken(const Items: TStrings; const Token: String): Boolean;
Var I: Integer;
    T: String;
begin
  Result:=False;
  for I:=0 to Items.Count-1 do begin
    T:=Trim(ExtUpperCase(Items[I]));
    If Pos('(',T)>0 then T:=Trim(Copy(T,1,Pos('(',T)-1));
    If T=ExtUpperCase(Token) then begin Result:=True; Exit; end;
  end;
end;

procedure RemoveVideoListMachineToken(Items: TStrings; const Token: String);
Var I: Integer;
    T: String;
begin
  for I:=Items.Count-1 downto 0 do begin
    T:=Trim(ExtUpperCase(Items[I]));
    If Pos('(',T)>0 then T:=Trim(Copy(T,1,Pos('(',T)-1));
    If T=ExtUpperCase(Token) then Items.Delete(I);
  end;
end;

procedure TModernProfileEditorGraphicsFrame.ApplyXMachineTypesToVideoList(const PreferredValue : String = '');
Var Kind: TDOSBoxKind;
    SelTok, Want, T: String;
    I: Integer;
begin
  Kind:=GetSelectedDosBoxKind;
  If Trim(PreferredValue)<>'' then
    Want:=Trim(PreferredValue)
  else begin
    Want:=Trim(VideoCardComboBox.Text);
    If Pos('(',Want)>0 then Want:=Trim(Copy(Want,1,Pos('(',Want)-1));
  end;
  SelTok:=Trim(ExtUpperCase(Want));
  { X-only machine tokens (also in DefaultValuesVideo). Strip then re-append so
    order is always classic list, then PC98, DOS/V, olivetti, pc3270. }
  RemoveVideoListMachineToken(VideoCardComboBox.Items,'PC98');
  RemoveVideoListMachineToken(VideoCardComboBox.Items,'DOS/V');
  RemoveVideoListMachineToken(VideoCardComboBox.Items,'olivetti');
  RemoveVideoListMachineToken(VideoCardComboBox.Items,'pc3270');
  If Kind=dbkX then begin
    VideoCardComboBox.Items.Add('PC98');
    VideoCardComboBox.Items.Add('DOS/V');
    VideoCardComboBox.Items.Add('olivetti (Olivetti M24 / AT&T 6300)');
    VideoCardComboBox.Items.Add('pc3270 (IBM 3270 PC)');
  end;
  { List first, then match profile / preferred token. }
  VideoCardComboBox.ItemIndex:=-1;
  For I:=0 to VideoCardComboBox.Items.Count-1 do begin
    T:=Trim(ExtUpperCase(VideoCardComboBox.Items[I]));
    If Pos('(',T)>0 then T:=Trim(Copy(T,1,Pos('(',T)-1));
    If T=SelTok then begin VideoCardComboBox.ItemIndex:=I; break; end;
  end;
  If (VideoCardComboBox.ItemIndex<0) and (VideoCardComboBox.Items.Count>0) then
    VideoCardComboBox.ItemIndex:=VideoCardComboBox.Items.Count-1;
end;

procedure TModernProfileEditorGraphicsFrame.FillShaderListFromActiveMap;
Var I: Integer;
begin
  FAllPixelShaders.Clear;
  FAllPresets.Clear;
  FShaderMap:=ActiveShaderMap;
  if FShaderMap=nil then Exit;
  for I:=0 to FShaderMap.Count-1 do
    FAllPixelShaders.Add(MapKeyToDisplay(FShaderMap[I]));
end;

procedure TModernProfileEditorGraphicsFrame.ReloadPixelShaderList;
Var Dir, Version: String;
    Kind: TDOSBoxKind;
begin
  FreeBackendMaps;
  Dir:=GetDOSBoxDir;
  Kind:=GetSelectedDosBoxKind;
  Version:=CheckDOSBoxVersion(Dir);
  FBackendMaps:=GetDOSBoxShaders(Dir,Kind,Version);
  FillShaderListFromActiveMap;
end;

procedure TModernProfileEditorGraphicsFrame.RenderComboBoxChange(Sender: TObject);
begin
  { Output backend changed → rebuild list from the matching map; drop selection. }
  LastShaderPreset:='';
  ShaderPresetChanged:=True;
  PixelShaderChanged:=True;
  FillShaderListFromActiveMap;

  FFilteringPixelShaders:=True;
  try
    PixelShaderComboBox.Items.BeginUpdate;
    try
      PixelShaderComboBox.Items.Clear;
      if RenderSupportsShaders then
        PixelShaderComboBox.Items.AddStrings(FAllPixelShaders);
    finally
      PixelShaderComboBox.Items.EndUpdate;
    end;
    PixelShaderComboBox.ItemIndex:=-1;
    PixelShaderComboBox.Text:='';
    ApplyShaderControlsEnabled;
  finally
    FFilteringPixelShaders:=False;
  end;
  RefreshPresetComboForCurrentShader(False);
end;

procedure TModernProfileEditorGraphicsFrame.ApplyPixelShaderFilter;
Var Filter, Item, Keep: String;
    I: Integer;
begin
  Keep:=PixelShaderComboBox.Text;
  Filter:=Trim(ExtUpperCase(Keep));
  FFilteringPixelShaders:=True;
  try
    PixelShaderComboBox.Items.BeginUpdate;
    try
      PixelShaderComboBox.Items.Clear;
      for I:=0 to FAllPixelShaders.Count-1 do begin
        Item:=FAllPixelShaders[I];
        if (Filter='') or (Pos(Filter,ExtUpperCase(Item))>0) then
          PixelShaderComboBox.Items.Add(Item);
      end;
    finally
      PixelShaderComboBox.Items.EndUpdate;
    end;
    { Clear/Text reset puts caret at 0; restore filter text and caret at end.
      Do not toggle DroppedDown here — that hides the mouse; KeyDown opens the
      list before the character is applied instead. }
    PixelShaderComboBox.Text:=Keep;
    PixelShaderComboBox.SelStart:=Length(Keep);
    PixelShaderComboBox.SelLength:=0;
  finally
    FFilteringPixelShaders:=False;
  end;
end;

procedure TModernProfileEditorGraphicsFrame.ApplyShaderPresetFilter;
Var Filter, Item, Keep: String;
    I: Integer;
begin
  Keep:=ShaderPresetComboBox.Text;
  Filter:=Trim(ExtUpperCase(Keep));
  FFilteringPresets:=True;
  try
    ShaderPresetComboBox.Items.BeginUpdate;
    try
      ShaderPresetComboBox.Items.Clear;
      for I:=0 to FAllPresets.Count-1 do begin
        Item:=FAllPresets[I];
        if (Filter='') or (Pos(Filter,ExtUpperCase(Item))>0) then
          ShaderPresetComboBox.Items.Add(Item);
      end;
    finally
      ShaderPresetComboBox.Items.EndUpdate;
    end;
    ShaderPresetComboBox.Text:=Keep;
    ShaderPresetComboBox.SelStart:=Length(Keep);
    ShaderPresetComboBox.SelLength:=0;
  finally
    FFilteringPresets:=False;
  end;
end;

procedure TModernProfileEditorGraphicsFrame.RefreshPresetComboForCurrentShader(const ApplyLastPreset : Boolean);
Var Idx, I: Integer;
    Presets: TStringList;
    Kind: TDOSBoxKind;
    Want: String;
begin
  FAllPresets.Clear;
  FFilteringPresets:=True;
  try
    ShaderPresetComboBox.Items.BeginUpdate;
    try
      ShaderPresetComboBox.Items.Clear;
    finally
      ShaderPresetComboBox.Items.EndUpdate;
    end;
    ShaderPresetComboBox.ItemIndex:=-1;
    ShaderPresetComboBox.Text:='';

    if not RenderSupportsShaders then begin
      ShaderPresetComboBox.Enabled:=False;
      Exit;
    end;

    Kind:=GetSelectedDosBoxKind;
    if Kind<>dbkStaging then begin
      ShaderPresetComboBox.Enabled:=False;
      Exit;
    end;

    Idx:=ShaderMapIndexOfDisplay(PixelShaderComboBox.Text);
    if (Idx<0) or (FShaderMap=nil) then begin
      ShaderPresetComboBox.Enabled:=False;
      Exit;
    end;

    Presets:=TStringList(FShaderMap.Objects[Idx]);
    if (Presets=nil) or (Presets.Count=0) then begin
      ShaderPresetComboBox.Enabled:=False;
      Exit;
    end;

    FAllPresets.Assign(Presets);
    ShaderPresetComboBox.Enabled:=True;
    ShaderPresetComboBox.Items.BeginUpdate;
    try
      ShaderPresetComboBox.Items.AddStrings(FAllPresets);
    finally
      ShaderPresetComboBox.Items.EndUpdate;
    end;

    if ApplyLastPreset then begin
      Want:=Trim(LastShaderPreset);
      if Want<>'' then
        for I:=0 to ShaderPresetComboBox.Items.Count-1 do
          if SameText(ShaderPresetComboBox.Items[I],Want) then begin
            ShaderPresetComboBox.ItemIndex:=I;
            break;
          end;
    end;
  finally
    FFilteringPresets:=False;
  end;
end;

procedure TModernProfileEditorGraphicsFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
Var I : Integer;
    S,T : String;
    St : TStringList;
begin
  S:=Trim(ExtUpperCase(Game.WindowResolution));
  WindowResolutionComboBox.ItemIndex:=0;
  For I:=0 to WindowResolutionComboBox.Items.Count-1 do If Trim(ExtUpperCase(WindowResolutionComboBox.Items[I]))=S then begin
    WindowResolutionComboBox.ItemIndex:=I; break;
  end;

  S:=Trim(ExtUpperCase(Game.FullscreenResolution));
  FullscreenResolutionComboBox.ItemIndex:=0;
  For I:=0 to FullscreenResolutionComboBox.Items.Count-1 do If Trim(ExtUpperCase(FullscreenResolutionComboBox.Items[I]))=S then begin
    FullscreenResolutionComboBox.ItemIndex:=I; break;
  end;

  StartFullscreenCheckBox.Checked:=Game.StartFullscreen;
  DoublebufferingCheckBox.Checked:=Game.UseDoublebuffering;
  KeepAspectRatioCheckBox.Checked:=Game.AspectCorrection;
  { Pause wins if both true in old profiles (matches Staging: pause overrides mute). }
  I:=Game.OnScreenInactive;
  If (I>=Ord(simDoNothing)) and (I<=Ord(simPause)) then
    rgScreenInactive.ItemIndex:=I
  else
    rgScreenInactive.ItemIndex:=-1;
  GlideEmulationLabel.Visible:=PrgSetup.AllowGlideSettings;
  GlideEmulationComboBox.Visible:=PrgSetup.AllowGlideSettings;
  GlideEmulationPortLabel.Visible:=PrgSetup.AllowGlideSettings;
  GlideEmulationPortComboBox.Visible:=PrgSetup.AllowGlideSettings;
  GlideEmulationLFBLabel.Visible:=PrgSetup.AllowGlideSettings;
  GlideEmulationLFBComboBox.Visible:=PrgSetup.AllowGlideSettings;
  If PrgSetup.AllowGlideSettings then begin
    S:=Trim(ExtUpperCase(Game.GlideEmulation));
    If (S='0') or (S='FALSE') then S:=LanguageSetup.Off;
    If (S='1') or (S='TRUE') then S:=LanguageSetup.On;
    S:=ExtUpperCase(S);
    GlideEmulationComboBox.ItemIndex:=0;
    For I:=0 to GlideEmulationComboBox.Items.Count-1 do If Trim(ExtUpperCase(GlideEmulationComboBox.Items[I]))=S then begin
      GlideEmulationComboBox.ItemIndex:=I; break;
    end;
    S:=Trim(ExtUpperCase(Game.GlidePort));
    GlideEmulationPortComboBox.ItemIndex:=0;
    For I:=0 to GlideEmulationPortComboBox.Items.Count-1 do If Trim(ExtUpperCase(GlideEmulationPortComboBox.Items[I]))=S then begin
      GlideEmulationPortComboBox.ItemIndex:=I; break;
    end;
    S:=Trim(ExtUpperCase(Game.GlideLFB));
    GlideEmulationLFBComboBox.ItemIndex:=0;
    For I:=0 to GlideEmulationLFBComboBox.Items.Count-1 do If Trim(ExtUpperCase(GlideEmulationLFBComboBox.Items[I]))=S then begin
      GlideEmulationLFBComboBox.ItemIndex:=I; break;
    end;
  end;

  { Store profile values first; finalize render/video before any shader UI. }
  LastRender:=Trim(Game.Render);
  LastVideoCard:=Trim(Game.VideoCard);
  FShaderInstallKey:=Trim(Game.CustomDOSBoxDir);
  LastPixelShader:=NormalizeShaderDisplay(Game.PixelShader);
  if SameText(LastPixelShader,'none') then LastPixelShader:='';
  LastShaderPreset:=Trim(Game.ShaderPreset);
  LastVSync:=Trim(Game.VSync);

  ApplyRenderList(LastRender);
  ApplyXMachineTypesToVideoList(LastVideoCard);

  PixelShaderComboBox.Items.Clear;
  ShaderPresetComboBox.Items.Clear;

  VGASettingsGroupBox.Visible:=PrgSetup.AllowVGAChipsetSettings;
  If PrgSetup.AllowVGAChipsetSettings then begin
    If VGAChipsetComboBox.Items.Count>0 then VGAChipsetComboBox.ItemIndex:=0;
    S:=Trim(ExtUpperCase(Game.VGAChipset));
    For I:=0 to VGAChipsetComboBox.Items.Count-1 do If Trim(ExtUpperCase(VGAChipsetComboBox.Items[I]))=S then begin
      VGAChipsetComboBox.ItemIndex:=I;
      break;
    end;
    If VideoRamComboBox.Items.Count>0 then VideoRamComboBox.ItemIndex:=0;
    S:=Trim(ExtUpperCase(IntToStr(Game.VideoRam)));
    For I:=0 to VideoRamComboBox.Items.Count-1 do begin
      T:=Trim(ExtUpperCase(VideoRamComboBox.Items[I]));
      If T=S then begin VideoRamComboBox.ItemIndex:=I; break; end;
      If T='2048' then VideoRamComboBox.ItemIndex:=I;
    end;
  end;  

  ScaleComboBox.Items.BeginUpdate;
  try
    ScaleComboBox.Items.Clear;
    St:=ValueToList(FScaleConfOpt,';,');
    try
      ScaleComboBox.Items.AddStrings(St);
    finally
      St.Free;
    end;
  finally
    ScaleComboBox.Items.EndUpdate;
  end;
  S:=Trim(ExtUpperCase(Game.Scale));
  ScaleComboBox.ItemIndex:=0;
  For I:=0 to ScaleComboBox.Items.Count-1 do begin
    T:=Trim(ExtUpperCase(ScaleComboBox.Items[I]));
    If Pos('(',T)=0 then continue;
    T:=Copy(T,Pos('(',T)+1,MaxInt);
    If Pos(')',T)=0 then continue;
    T:=Copy(T,1,Pos(')',T)-1);
    If Trim(T)=S then begin ScaleComboBox.ItemIndex:=I; break; end;
  end;
  ScaleComboBox.Enabled:=True;
  ScaleLabel.Enabled:=True;
  ApplyScalerControls;
  FrameSkipEdit.Value:=Game.FrameSkip;
  ApplyFrameSkipControls;
  ApplyInactiveControls;

  TextModeLinesRadioGroup.Visible:=PrgSetup.AllowTextModeLineChange;
  If PrgSetup.AllowTextModeLineChange then Case Game.TextModeLines of
    28 : TextModeLinesRadioGroup.ItemIndex:=1;
    50 : TextModeLinesRadioGroup.ItemIndex:=2;
    else TextModeLinesRadioGroup.ItemIndex:=0;
  end;

  PixelShaderChanged:=LoadFromTemplate;
  ShaderPresetChanged:=LoadFromTemplate;
end;

function TModernProfileEditorGraphicsFrame.GetDOSBoxDir: String;
begin
  result:=ResolveDOSBoxDir(ProfileDOSBoxInstallation^);
end;

procedure TModernProfileEditorGraphicsFrame.ShowFrame(Sender : TObject);
Var I : Integer;
    S, WantRender: String;
begin
  { Always visible (setup AllowPixelShader checkbox is forced on + disabled). }
  PixelShaderLabel.Visible:=True;
  PixelShaderComboBox.Visible:=True;
  ShaderPresetLabel.Visible:=True;
  ShaderPresetComboBox.Visible:=True;

  { Install changed while editor open → drop selection; inventory is install-specific. }
  if not SameText(Trim(ProfileDOSBoxInstallation^),FShaderInstallKey) then begin
    LastPixelShader:='';
    LastShaderPreset:='';
    FShaderInstallKey:=Trim(ProfileDOSBoxInstallation^);
  end else if PixelShaderComboBox.Items.Count>0 then
    LastPixelShader:=PixelShaderComboBox.Text;

  { 1) Finalize render (and other kind UI) before any shader/preset work. }
  if Trim(RenderComboBox.Text)<>'' then WantRender:=Trim(RenderComboBox.Text)
  else WantRender:=LastRender;
  ApplyRenderList(WantRender);
  if Trim(RenderComboBox.Text)<>'' then LastRender:=Trim(RenderComboBox.Text);

  if Trim(VideoCardComboBox.Text)<>'' then begin
    S:=Trim(VideoCardComboBox.Text);
    If Pos('(',S)>0 then S:=Trim(Copy(S,1,Pos('(',S)-1));
    LastVideoCard:=S;
  end;
  ApplyXMachineTypesToVideoList(LastVideoCard);
  ApplyVSyncControls;
  ApplyInactiveControls;
  ApplyScalerControls;
  ApplyFrameSkipControls;

  { 2) Shader inventory and restore against the finalized render backend. }
  ReloadPixelShaderList;

  FFilteringPixelShaders:=True;
  try
    PixelShaderComboBox.Items.BeginUpdate;
    try
      PixelShaderComboBox.Items.Clear;
      if RenderSupportsShaders then
        PixelShaderComboBox.Items.AddStrings(FAllPixelShaders);
    finally
      PixelShaderComboBox.Items.EndUpdate;
    end;

    PixelShaderComboBox.ItemIndex:=-1;
    PixelShaderComboBox.Text:='';
    if (not RenderSupportsShaders) or (FAllPixelShaders.Count=0) then begin
      ApplyShaderControlsEnabled;
    end else begin
      ApplyShaderControlsEnabled;
      S:=Trim(ExtUpperCase(LastPixelShader));
      if S<>'' then
        For I:=0 to PixelShaderComboBox.Items.Count-1 do
          If Trim(ExtUpperCase(PixelShaderComboBox.Items[I]))=S then begin
            PixelShaderComboBox.ItemIndex:=I;
            break;
          end;
    end;
  finally
    FFilteringPixelShaders:=False;
  end;

  RefreshPresetComboForCurrentShader(True);

  { Invalid conf values show blank for display only — not dirty. }
  PixelShaderChanged:=False;
  ShaderPresetChanged:=False;
end;

procedure TModernProfileEditorGraphicsFrame.GetGame(const Game: TGame);
Var S : String;
begin
  Game.WindowResolution:=WindowResolutionComboBox.Text;
  Game.FullscreenResolution:=FullscreenResolutionComboBox.Text;

  Game.StartFullscreen:=StartFullscreenCheckBox.Checked;
  Game.UseDoublebuffering:=DoublebufferingCheckBox.Checked;
  Game.AspectCorrection:=KeepAspectRatioCheckBox.Checked;
  If VSyncComboBox.Visible and VSyncComboBoxChanged then begin
    If VSyncComboBox.ItemIndex>=0 then
      S:=Trim(VSyncComboBox.Items[VSyncComboBox.ItemIndex])
    else
      S:='';
    If S<>LastVSync then
      Game.VSync:=S;
  end;
  If rgScreenInactive.Visible then
    Game.OnScreenInactive:=rgScreenInactive.ItemIndex;
  If PrgSetup.AllowGlideSettings then begin
    S:=GlideEmulationComboBox.Items[GlideEmulationComboBox.ItemIndex];
    If S=LanguageSetup.On then S:='true';
    If S=LanguageSetup.Off then S:='false';
    Game.GlideEmulation:=S;
    Game.GlidePort:=GlideEmulationPortComboBox.Text;
    Game.GlideLFB:=GlideEmulationLFBComboBox.Items[max(0,GlideEmulationLFBComboBox.ItemIndex)];
  end;
  Game.Render:=RenderComboBox.Text;
  S:=Trim(VideoCardComboBox.Text);
  If Pos('(',S)<>0 then S:=Trim(Copy(S,1,Pos('(',S)-1));
  Game.VideoCard:=S;

  { Install changed since shader UI was last synced → force unset (do not re-apply
    dirty values from the previous install). DOSBox frame GetGame already ran. }
  if not SameText(Trim(Game.CustomDOSBoxDir),FShaderInstallKey) then begin
    Game.PixelShader:='';
    Game.ShaderPreset:='';
  end else begin
    { Only write when user changed the control. Blank from invalid match is not dirty. }
    If PixelShaderChanged then begin
      if Trim(PixelShaderComboBox.Text)='' then
        Game.PixelShader:=''
      else if FAllPixelShaders.IndexOf(PixelShaderComboBox.Text)>=0 then
        Game.PixelShader:=PixelShaderComboBox.Text;
      { Shader change always clears preset unless user also set a valid new one
        (ShaderPresetChanged + non-empty combo below). }
      if not ShaderPresetChanged then
        Game.ShaderPreset:='';
    end;
    If ShaderPresetChanged then begin
      if Trim(ShaderPresetComboBox.Text)='' then
        Game.ShaderPreset:=''
      else if FAllPresets.IndexOf(ShaderPresetComboBox.Text)>=0 then
        Game.ShaderPreset:=ShaderPresetComboBox.Text
      else
        Game.ShaderPreset:='';
    end;
  end;

  If PrgSetup.AllowVGAChipsetSettings then begin
    Game.VGAChipset:=VGAChipsetComboBox.Text;
    try Game.VideoRam:=StrToInt(VideoRamComboBox.Text); except Game.VideoRam:=2048; end;
  end;  

  If ScaleComboBox.Enabled then begin
    S:=ScaleComboBox.Text;
    If Pos('(',S)=0 then Game.Scale:='' else begin
      S:=Copy(S,Pos('(',S)+1,MaxInt);
      If Pos(')',S)=0 then Game.Scale:=''  else Game.Scale:=Copy(S,1,Pos(')',S)-1);
    end;
  end;
  If FrameSkipEdit.Enabled then
    Game.FrameSkip:=Min(100,Max(0,FrameSkipEdit.Value));

  If PrgSetup.AllowTextModeLineChange then Case TextModeLinesRadioGroup.ItemIndex of
    0 : Game.TextModeLines:=25;
    1 : Game.TextModeLines:=28;
    2 : Game.TextModeLines:=50;
  end;
end;

end.
