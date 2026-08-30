unit ModernProfileEditorScummVMGraphicsFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, GameDBUnit, ModernProfileEditorFormUnit;

type
  TModernProfileEditorScummVMGraphicsFrame = class(TFrame, IModernProfileEditorFrame)
    FilterLabel: TLabel;
    FilterComboBox: TComboBox;
    StartFullscreenCheckBox: TCheckBox;
    KeepAspectRatioCheckBox: TCheckBox;
    RenderModeLabel: TLabel;
    RenderModeComboBox: TComboBox;
    GfxModeLabel: TLabel;
    GfxModeComboBox: TComboBox;
    ScalerLabel: TLabel;
    ScalerComboBox: TComboBox;
    ScaleFactorLabel: TLabel;
    ScaleFactorComboBox: TComboBox;
    StretchModeLabel: TLabel;
    StretchModeComboBox: TComboBox;
    ShaderLabel: TLabel;
    ShaderEdit: TEdit;
    ShaderButton: TButton;
    ShaderOpenDialog: TOpenDialog;
    FilteringCheckBox: TCheckBox;
    VSyncLabel: TLabel;
    VSyncComboBox: TComboBox;
    RendererLabel: TLabel;
    RendererComboBox: TComboBox;
    AntialiasingLabel: TLabel;
    AntialiasingComboBox: TComboBox;
    procedure ShaderButtonClick(Sender: TObject);
    procedure ModernScalerChange(Sender: TObject);
    procedure FilterChange(Sender: TObject);
  private
    Procedure SelectComboValue(const Combo: TComboBox; const Value: String; const AllowBare: Boolean);
    Function ComboStoredValue(const Combo: TComboBox; const AllowBare: Boolean): String;
    Function GraphicsComboToken(const Combo: TComboBox; const S: String): String;
  public
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses VistaToolsUnit, LanguageSetupUnit, CommonHelpers, HelpConsts;

{$R *.dfm}

{ TModernProfileEditorScummVMGraphicsFrame }

function TModernProfileEditorScummVMGraphicsFrame.GraphicsComboToken(const Combo: TComboBox; const S: String): String;
Var T : String;
    P : Integer;
begin
  T:=Trim(S);
  P:=Pos('(',T);
  If P>0 then begin
    T:=Copy(T,P+1,MaxInt);
    If Pos(')',T)>0 then T:=Copy(T,1,Pos(')',T)-1);
    T:=Trim(T);
  end;
  If (T='') or SameText(T,'default') then begin Result:=''; exit; end;
  If Combo=VSyncComboBox then begin
    If SameText(T,'on') or SameText(T,'true') or (T='1') or (T='-1') then begin Result:='true'; exit; end;
    If SameText(T,'off') or SameText(T,'false') or (T='0') then begin Result:='false'; exit; end;
    Result:='';
    exit;
  end;
  If Combo=AntialiasingComboBox then begin
    If SameText(T,'none') or SameText(T,'0') then begin Result:='0'; exit; end;
    If SameText(T,'2x') or SameText(T,'2') then begin Result:='2'; exit; end;
    If SameText(T,'4x') or SameText(T,'4') then begin Result:='4'; exit; end;
    If SameText(T,'8x') or SameText(T,'8') then begin Result:='8'; exit; end;
  end;
  If SameText(T,'none') then begin Result:=''; exit; end;
  If SameText(T,'sdl surface') or SameText(T,'surfacesdl') then begin Result:='surfacesdl'; exit; end;
  If SameText(T,'opengl with shaders') or SameText(T,'opengl_shaders') then begin Result:='opengl_shaders'; exit; end;
  If SameText(T,'fit to window 4:3') or SameText(T,'fit_force_aspect') then begin Result:='fit_force_aspect'; exit; end;
  If SameText(T,'pixel-perfect scaling') or SameText(T,'pixel-perfect') then begin Result:='pixel-perfect'; exit; end;
  If SameText(T,'even pixels scaling') or SameText(T,'even-pixels') then begin Result:='even-pixels'; exit; end;
  If SameText(T,'fit to window') or SameText(T,'fit') then begin Result:='fit'; exit; end;
  If SameText(T,'stretch to window') or SameText(T,'stretch') then begin Result:='stretch'; exit; end;
  If SameText(T,'center') then begin Result:='center'; exit; end;
  If SameText(T,'software') then begin Result:='software'; exit; end;
  If SameText(T,'opengl') then begin Result:='opengl'; exit; end;
  If SameText(T,'hercules green') or SameText(T,'hercgreen') then begin Result:='hercGreen'; exit; end;
  If SameText(T,'hercules amber') or SameText(T,'hercamber') then begin Result:='hercAmber'; exit; end;
  If SameText(T,'cga composite') or SameText(T,'cgacomp') then begin Result:='cgaComp'; exit; end;
  If SameText(T,'cga b/w') or SameText(T,'cgabw') then begin Result:='cgaBW'; exit; end;
  If SameText(T,'fm-towns') or SameText(T,'fmtowns') then begin Result:='fmtowns'; exit; end;
  If SameText(T,'pc-9821 256 colors') or SameText(T,'pc98-256c') then begin Result:='pc98-256c'; exit; end;
  If SameText(T,'pc-9801 16 colors') or SameText(T,'pc98-16c') then begin Result:='pc98-16c'; exit; end;
  If SameText(T,'pc-9801 8 colors') or SameText(T,'pc98-8c') then begin Result:='pc98-8c'; exit; end;
  If SameText(T,'apple iigs') or SameText(T,'2gs') then begin Result:='2gs'; exit; end;
  If SameText(T,'atari st') then begin Result:='atari'; exit; end;
  If SameText(T,'macintosh b/w') or SameText(T,'macintoshbw') then begin Result:='macintoshbw'; exit; end;
  If SameText(T,'amstrad cpc') then begin Result:='cpc'; exit; end;
  If SameText(T,'zx spectrum') then begin Result:='zx'; exit; end;
  If SameText(T,'commodore 64') then begin Result:='c64'; exit; end;
  If SameText(T,'vga grey scale') or SameText(T,'vgagrey') then begin Result:='vgaGrey'; exit; end;
  If SameText(T,'windows 256 colors') or SameText(T,'win256c') then begin Result:='win256c'; exit; end;
  If SameText(T,'windows 16 colors') or SameText(T,'win16c') then begin Result:='win16c'; exit; end;
  Result:=T;
end;

procedure TModernProfileEditorScummVMGraphicsFrame.SelectComboValue(const Combo: TComboBox; const Value: String; const AllowBare: Boolean);
Var Want : String;
    I : Integer;
begin
  Combo.ItemIndex:=0;
  If Combo.Items.Count=0 then exit;
  Want:=GraphicsComboToken(Combo,Value);
  If Want='' then exit;
  For I:=0 to Combo.Items.Count-1 do begin
    If (not AllowBare) and (Pos('(',Combo.Items[I])=0) then continue;
    If SameText(GraphicsComboToken(Combo,Combo.Items[I]),Want) then begin Combo.ItemIndex:=I; exit; end;
  end;
end;

function TModernProfileEditorScummVMGraphicsFrame.ComboStoredValue(const Combo: TComboBox; const AllowBare: Boolean): String;
begin
  If (Pos('(',Combo.Text)=0) and (not AllowBare) then begin Result:=''; exit; end;
  Result:=GraphicsComboToken(Combo,Combo.Text);
end;

procedure TModernProfileEditorScummVMGraphicsFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var St : TStringList;
begin
  NoFlicker(FilterComboBox);
  NoFlicker(RenderModeComboBox);
  NoFlicker(StartFullscreenCheckBox);
  NoFlicker(KeepAspectRatioCheckBox);
  NoFlicker(GfxModeComboBox);
  NoFlicker(ScalerComboBox);
  NoFlicker(ScaleFactorComboBox);
  NoFlicker(StretchModeComboBox);
  NoFlicker(ShaderEdit);
  NoFlicker(ShaderButton);
  NoFlicker(FilteringCheckBox);
  NoFlicker(VSyncComboBox);
  NoFlicker(RendererComboBox);
  NoFlicker(AntialiasingComboBox);

  FilterLabel.Caption:=LanguageSetup.ProfileEditorScummVMFilter;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMFilter,';,'); try FilterComboBox.Items.AddStrings(St); finally St.Free; end;
  RenderModeLabel.Caption:=LanguageSetup.ProfileEditorScummVMRenderMode;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMRenderMode,';,'); try RenderModeComboBox.Items.AddStrings(St); finally St.Free; end;

  AddDefaultValueHint(FilterComboBox);
  AddDefaultValueHint(RenderModeComboBox);

  StartFullscreenCheckBox.Caption:=LanguageSetup.GameStartFullscreen;
  KeepAspectRatioCheckBox.Caption:=LanguageSetup.GameAspectCorrection;

  GfxModeLabel.Caption:=LanguageSetup.ProfileEditorScummVMGfxMode;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMGfxMode,';,'); try GfxModeComboBox.Items.AddStrings(St); finally St.Free; end;
  ScalerLabel.Caption:=LanguageSetup.ProfileEditorScummVMScaler;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMScaler,';,'); try ScalerComboBox.Items.AddStrings(St); finally St.Free; end;
  ScaleFactorLabel.Caption:=LanguageSetup.ProfileEditorScummVMScaleFactor;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMScaleFactor,';,'); try ScaleFactorComboBox.Items.AddStrings(St); finally St.Free; end;
  StretchModeLabel.Caption:=LanguageSetup.ProfileEditorScummVMStretchMode;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMStretchMode,';,'); try StretchModeComboBox.Items.AddStrings(St); finally St.Free; end;
  ShaderLabel.Caption:=LanguageSetup.ProfileEditorScummVMShader;
  ShaderOpenDialog.Title:=LanguageSetup.ChooseFile;
  FilteringCheckBox.Caption:=LanguageSetup.ProfileEditorScummVMFiltering;
  VSyncLabel.Caption:='V-Sync';
  VSyncComboBox.Items.BeginUpdate;
  try
    VSyncComboBox.Items.Clear;
    VSyncComboBox.Items.Add('');
    VSyncComboBox.Items.Add('On');
    VSyncComboBox.Items.Add('Off');
  finally
    VSyncComboBox.Items.EndUpdate;
  end;
  VSyncComboBox.ItemIndex:=0;
  RendererLabel.Caption:=LanguageSetup.ProfileEditorScummVMRenderer;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMRenderer,';,'); try RendererComboBox.Items.AddStrings(St); finally St.Free; end;
  AntialiasingLabel.Caption:=LanguageSetup.ProfileEditorScummVMAntialiasing;
  St:=ValueToList(InitData.GameDB.ConfOpt.ScummVMAntialiasing,';,'); try AntialiasingComboBox.Items.AddStrings(St); finally St.Free; end;

  AddDefaultValueHint(GfxModeComboBox);
  AddDefaultValueHint(ScalerComboBox);
  AddDefaultValueHint(ScaleFactorComboBox);
  AddDefaultValueHint(StretchModeComboBox);
  AddDefaultValueHint(VSyncComboBox);
  AddDefaultValueHint(RendererComboBox);
  AddDefaultValueHint(AntialiasingComboBox);

  HelpContext:=ID_ProfileEditGraphics;
end;

procedure TModernProfileEditorScummVMGraphicsFrame.ShaderButtonClick(Sender: TObject);
begin
  ShaderOpenDialog.FileName:=Trim(ShaderEdit.Text);
  If ShaderOpenDialog.FileName<>'' then
    ShaderOpenDialog.InitialDir:=ExtractFilePath(ShaderOpenDialog.FileName);
  If not ShaderOpenDialog.Execute then exit;
  ShaderEdit.Text:=ShaderOpenDialog.FileName;
end;

procedure TModernProfileEditorScummVMGraphicsFrame.ModernScalerChange(Sender: TObject);
begin
  If not (Sender is TComboBox) then exit;
  If ComboStoredValue(TComboBox(Sender),True)='' then exit;
  FilterComboBox.ItemIndex:=-1;
end;

procedure TModernProfileEditorScummVMGraphicsFrame.FilterChange(Sender: TObject);
begin
  If ComboStoredValue(FilterComboBox,False)='' then exit;
  If ScalerComboBox.Items.Count>0 then ScalerComboBox.ItemIndex:=0;
  If ScaleFactorComboBox.Items.Count>0 then ScaleFactorComboBox.ItemIndex:=0;
end;

procedure TModernProfileEditorScummVMGraphicsFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
Var S : String;
begin
  SelectComboValue(FilterComboBox,Game.ScummVMFilter,False);
  SelectComboValue(RenderModeComboBox,Game.ScummVMRenderMode,True);

  StartFullscreenCheckBox.Checked:=Game.StartFullscreen;
  KeepAspectRatioCheckBox.Checked:=Game.AspectCorrection;

  SelectComboValue(GfxModeComboBox,Game.ScummVMGfxMode,True);
  SelectComboValue(ScalerComboBox,Game.ScummVMScaler,True);
  SelectComboValue(ScaleFactorComboBox,Game.ScummVMScaleFactor,True);
  SelectComboValue(StretchModeComboBox,Game.ScummVMStretchMode,True);
  ShaderEdit.Text:=Game.ScummVMShader;
  FilteringCheckBox.Checked:=Game.ScummVMFiltering;
  VSyncComboBox.ItemIndex:=0;
  S:=Trim(LowerCase(Game.ScummVMVSync));
  If (S='1') or (S='-1') or (S='true') or (S='on') then S:='true'
  else If (S='0') or (S='false') or (S='off') then S:='false'
  else S:='';
  If S<>'' then SelectComboValue(VSyncComboBox,S,True);
  SelectComboValue(RendererComboBox,Game.ScummVMRenderer,True);
  SelectComboValue(AntialiasingComboBox,Game.ScummVMAntialiasing,True);
end;

procedure TModernProfileEditorScummVMGraphicsFrame.GetGame(const Game: TGame);
begin
  Game.ScummVMFilter:=ComboStoredValue(FilterComboBox,False);
  Game.ScummVMRenderMode:=ComboStoredValue(RenderModeComboBox,True);

  Game.StartFullscreen:=StartFullscreenCheckBox.Checked;
  Game.AspectCorrection:=KeepAspectRatioCheckBox.Checked;

  Game.ScummVMGfxMode:=ComboStoredValue(GfxModeComboBox,True);
  Game.ScummVMScaler:=ComboStoredValue(ScalerComboBox,True);
  Game.ScummVMScaleFactor:=ComboStoredValue(ScaleFactorComboBox,True);
  Game.ScummVMStretchMode:=ComboStoredValue(StretchModeComboBox,True);
  Game.ScummVMShader:=Trim(ShaderEdit.Text);
  Game.ScummVMFiltering:=FilteringCheckBox.Checked;
  If VSyncComboBox.ItemIndex>0 then
    Game.ScummVMVSync:=ComboStoredValue(VSyncComboBox,True)
  else
    Game.ScummVMVSync:='';
  Game.ScummVMRenderer:=ComboStoredValue(RendererComboBox,True);
  Game.ScummVMAntialiasing:=ComboStoredValue(AntialiasingComboBox,True);
end;

end.
