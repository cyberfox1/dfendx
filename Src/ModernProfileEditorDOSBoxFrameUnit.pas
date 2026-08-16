unit ModernProfileEditorDOSBoxFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, GameDBUnit, ModernProfileEditorFormUnit, StdCtrls, ExtCtrls, Buttons,
  ComCtrls, PrgConsts, System.TypInfo;

type
  TModernProfileEditorDOSBoxFrame = class(TFrame, IModernProfileEditorFrame)
    CloseDOSBoxOnExitCheckBox: TCheckBox;
    DefaultDOSBoxInstallationRadioButton: TRadioButton;
    CustomDOSBoxInstallationRadioButton: TRadioButton;
    CustomDOSBoxInstallationEdit: TEdit;
    CustomDOSBoxInstallationButton: TSpeedButton;
    CustomSetsClearButton: TBitBtn;
    CustomSetsLoadButton: TBitBtn;
    CustomSetsSaveButton: TBitBtn;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    CustomSetsMemo: TRichEdit;
    CustomSetsLabel: TLabel;
    DOSBoxInstallationComboBox: TComboBox;
    UserLanguageCheckBox: TCheckBox;
    UserLanguageComboBox: TComboBox;
    DOSBoxForegroundPriorityComboBox: TComboBox;
    DOSBoxBackgroundPriorityComboBox: TComboBox;
    DOSBoxForegroundPriorityLabel: TLabel;
    DOSBoxBackgroundPriorityLabel: TLabel;
    UserConsoleCheckBox: TCheckBox;
    UserConsoleComboBox: TComboBox;
    RunAsAdminCheckBox: TCheckBox;
    DBKindIcon: TImage;
    lbInstallChangeWarning: TLabel;
    procedure CustomDOSBoxInstallationButtonClick(Sender: TObject);
    procedure CustomDOSBoxInstallationEditChange(Sender: TObject);
    procedure ButtonWork(Sender: TObject);
    procedure DOSBoxInstallationComboBoxChange(Sender: TObject);
    procedure DOSBoxInstallationTypeClick(Sender: TObject);
    procedure UserLanguageCheckBoxClick(Sender: TObject);
    procedure UserConsoleCheckBoxClick(Sender: TObject);
  private
    { Private-Deklarationen }
    FTempGame : TGame;
    DosBoxLang : TStringList;
    ProfileName,ProfileExe,ProfileSetup,ProfileCaptureDir : PString;
    FOnProfileNameChange : TTextEvent;
    Procedure UpdateLanguageList;
    Procedure SelectInLanguageList(const LangName : String);
    Procedure SelectInConsoleList;
    Procedure UpdateDOSBoxInstallationString;
    Procedure UpdateDBKindIcon(const Kind: TDOSBoxKind);
    Procedure UpdateDBKindIconFromSelection;
    Procedure ShowFrame(Sender: TObject);
    { Debug helpers — call DumpDosBoxKindDebug from combo-change when needed. }
    Procedure DumpDosBoxKindDebug;
    Function DebugGetExeFileDescription(const ExePath: String): String;
  public
    { Public-Deklarationen }
    Constructor Create(AOwner : TComponent); override;
    Destructor Destroy; override;
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, CommonTools, PrgSetupUnit, GameDBToolsHelpers,
     GameDBToolsUnit, GameDBHelpers, HelpConsts, IconLoaderUnit, TextEditPopupUnit, System.UITypes;

{$R *.dfm}

const FPriority : Array[0..3] of String = ('lower','normal','higher','highest');
const BPriority : Array[0..4] of String = ('pause','lower','normal','higher','highest');

{ TModernProfileEditorDOSBoxFrame }

constructor TModernProfileEditorDOSBoxFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
  DosBoxLang:=TStringList.Create;
end;

destructor TModernProfileEditorDOSBoxFrame.Destroy;
begin
  DosBoxLang.Free;
  inherited Destroy;
end;

procedure TModernProfileEditorDOSBoxFrame.InitGUI(var InitData : TModernProfileEditorInitData);
Var I : Integer;
    S : String;
begin
  NoFlicker(DOSBoxForegroundPriorityComboBox);
  NoFlicker(DOSBoxBackgroundPriorityComboBox);
  NoFlicker(CloseDOSBoxOnExitCheckBox);
  NoFlicker(DefaultDOSBoxInstallationRadioButton);
  NoFlicker(DOSBoxInstallationComboBox);
  NoFlicker(CustomDOSBoxInstallationRadioButton);
  NoFlicker(CustomDOSBoxInstallationEdit);
  NoFlicker(UserLanguageCheckBox);
  NoFlicker(UserLanguageComboBox);
  NoFlicker(UserConsoleCheckBox);
  NoFlicker(UserConsoleComboBox);
  {NoFlicker(CustomSetsMemo); - will hide text in Memo}
  NoFlicker(CustomSetsClearButton);
  NoFlicker(CustomSetsLoadButton);
  NoFlicker(CustomSetsSaveButton);

  SetRichEditPopup(CustomSetsMemo);

  DOSBoxForegroundPriorityLabel.Caption:=LanguageSetup.GamePriorityForeground;
  with DOSBoxForegroundPriorityComboBox.Items do begin
    Clear;
    Add(LanguageSetup.GamePriorityLower);
    Add(LanguageSetup.GamePriorityNormal);
    Add(LanguageSetup.GamePriorityHigher);
    Add(LanguageSetup.GamePriorityHighest);
  end;
  DOSBoxBackgroundPriorityLabel.Caption:=LanguageSetup.GamePriorityBackground;
  with DOSBoxBackgroundPriorityComboBox.Items do begin
    Clear;
    Add(LanguageSetup.GamePriorityPause);
    Add(LanguageSetup.GamePriorityLower);
    Add(LanguageSetup.GamePriorityNormal);
    Add(LanguageSetup.GamePriorityHigher);
    Add(LanguageSetup.GamePriorityHighest);
  end;
  CloseDOSBoxOnExitCheckBox.Caption:=LanguageSetup.GameCloseDosBoxAfterGameExit;
  RunAsAdminCheckBox.Caption:=LanguageSetup.ProfileEditorRunAsAdmin;
  RunAsAdminCheckBox.Visible:=PrgSetup.OfferRunAsAdmin;
  DefaultDOSBoxInstallationRadioButton.Caption:=LanguageSetup.GameDOSBoxVersionDefault;
  CustomDOSBoxInstallationRadioButton.Caption:=LanguageSetup.GameDOSBoxVersionCustom;
  lbInstallChangeWarning.Caption:=LanguageSetup.ProfileEditorInstallChangeWarning;
  CustomDOSBoxInstallationButton.Hint:=LanguageSetup.ChooseFolder;
  UserLanguageCheckBox.Caption:=LanguageSetup.GameDOSBoxLanguageCustom;
  UserConsoleCheckBox.Caption:=LanguageSetup.GameDOSBoxConsole;
  with UserConsoleComboBox.Items do begin
    Clear;
    Add(LanguageSetup.GameDOSBoxConsoleHide);
    Add(LanguageSetup.GameDOSBoxConsoleShow);
  end;
  CustomSetsLabel.Caption:=LanguageSetup.ProfileEditorCustomSetsSheet;
  CustomSetsMemo.Font.Name:='Courier New';
  CustomSetsClearButton.Caption:=LanguageSetup.Del;
  CustomSetsLoadButton.Caption:=LanguageSetup.Load;
  CustomSetsSaveButton.Caption:=LanguageSetup.Save;
  UserIconLoader.DialogImage(DI_SelectFolder,CustomDOSBoxInstallationButton);
  UserIconLoader.DialogImage(DI_Clear,CustomSetsClearButton);
  UserIconLoader.DialogImage(DI_Load,CustomSetsLoadButton);
  UserIconLoader.DialogImage(DI_Save,CustomSetsSaveButton);

  For I:=0 to PrgSetup.DOSBoxSettingsCount-1 do begin
    If I=0 then S:=LanguageSetup.Default else S:=PrgSetup.DOSBoxSettings[I].Name;
    DOSBoxInstallationComboBox.Items.Add(S+' ('+MakeRelPath(PrgSetup.DOSBoxSettings[I].DosBoxDir,PrgSetup.BaseDir,True)+')');
  end;
  DOSBoxInstallationComboBox.ItemIndex:=0;

  ProfileName:=InitData.CurrentProfileName;
  ProfileExe:=InitData.CurrentProfileExe;
  ProfileSetup:=InitData.CurrentProfileSetup;
  ProfileCaptureDir:=InitData.CurrentCaptureDir;
  FOnProfileNameChange:=InitData.OnProfileNameChange;
  { Page is created hidden; refresh kind icon when the user opens this tree node. }
  InitData.OnShowFrame:=ShowFrame;

  HelpContext:=ID_ProfileEditDOSBox;
end;

procedure TModernProfileEditorDOSBoxFrame.ShowFrame(Sender: TObject);
begin
  { Paint only from whatever is already on the controls after SetGame.
    Does not toggle radios, rewrite Profile* strings, or treat this as a user pick. }
  UpdateDBKindIconFromSelection;
end;

procedure TModernProfileEditorDOSBoxFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
Var St : TStringList;
    S,T : String;
    I : Integer;
begin
  St:=ValueToList(Game.Priority,',');
  try
    If (St.Count>=1) and (St[0]<>'') then S:=St[0] else S:=FPriority[2];
    If (St.Count>=2) and (St[1]<>'') then T:=St[1] else T:=BPriority[2];
  finally
    St.Free;
  end;
  S:=Trim(ExtUpperCase(S));
  DOSBoxForegroundPriorityComboBox.ItemIndex:=1;
  For I:=0 to DOSBoxForegroundPriorityComboBox.Items.Count-1 do If ExtUpperCase(FPriority[I])=S then begin
    DOSBoxForegroundPriorityComboBox.ItemIndex:=I;
    break;
  end;
  T:=Trim(ExtUpperCase(T));
  DOSBoxBackgroundPriorityComboBox.ItemIndex:=2;
  For I:=0 to DOSBoxBackgroundPriorityComboBox.Items.Count-1 do If ExtUpperCase(BPriority[I])=T then begin
    DOSBoxBackgroundPriorityComboBox.ItemIndex:=I;
    break;
  end;

  CloseDOSBoxOnExitCheckBox.Checked:=Game.CloseDosBoxAfterGameExit;
  RunAsAdminCheckBox.Checked:=Game.RunAsAdmin;

  { Empty CustomDOSBoxDir = no choice yet. Do not auto-select install 0 just
    because installs exist; profile is unchanged until the user picks one. }
  S:=Trim(Game.CustomDOSBoxDir);
  If S='' then begin
    DefaultDOSBoxInstallationRadioButton.Checked:=True;
    DOSBoxInstallationComboBox.ItemIndex:=-1;
    CustomDOSBoxInstallationEdit.Text:='';
  end else begin
    I:=ResolveDOSBoxInstallIndex(S);
    If I>=0 then begin
      DefaultDOSBoxInstallationRadioButton.Checked:=True;
      DOSBoxInstallationComboBox.ItemIndex:=I;
    end else begin
      CustomDOSBoxInstallationRadioButton.Checked:=True;
      CustomDOSBoxInstallationEdit.Text:=Game.CustomDOSBoxDir;
    end;
  end;

  Case Game.ShowConsoleWindow of
    0 : begin UserConsoleCheckBox.Checked:=True; UserConsoleComboBox.ItemIndex:=0; end;
    2 : begin UserConsoleCheckBox.Checked:=True; UserConsoleComboBox.ItemIndex:=1; end;
    else {1 :} UserConsoleCheckBox.Checked:=False;
  End;
  UserConsoleCheckBoxClick(self);
  If not UserConsoleCheckBox.Checked then SelectInConsoleList;

  UpdateLanguageList;
  S:=Trim(ExtUpperCase(Game.CustomDOSBoxLanguage));
  If (S='') or (S='DEFAULT') then begin
    UserLanguageCheckBox.Checked:=False;
    SelectInLanguageList('');
  end else begin
    UserLanguageCheckBox.Checked:=True;
    SelectInLanguageList(ChangeFileExt(ExtractFileName(Game.CustomDOSBoxLanguage),''));
  end;
  UserLanguageCheckBoxClick(self);

  St:=StringToStringList(Game.CustomSettings);
  try
    CustomSetsMemo.Lines.Assign(St);
  finally
    St.Free;
  end;

  { Icon only — do not run combo-change handlers or write profile fields.
    Kind comes from the loaded profile (SetDosBoxKind); combo/edit were set above. }
  UpdateDBKindIcon(Game.DosBoxKind);
end;

Procedure FindAndAddLngFiles(const Dir : String; const St, St2 : TStrings);
Var Rec : TSearchRec;
    I : Integer;
begin
  I:=FindFirst(Dir+'*.lng',faAnyFile,Rec);
  try
    while I=0 do begin
      St.Add(ChangeFileExt(Rec.Name,''));
      St2.Add(Dir+Rec.Name);
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

function DOSBoxComboInstallValue(const Combo: TComboBox): String;
begin
  { Map UI selection to stored CustomDOSBoxDir. ItemIndex -1 → leave unset ('').
    Index 0 → 'default' so empty stays distinct from "use primary install". }
  Result:='';
  if Combo.ItemIndex<0 then Exit;
  if Combo.ItemIndex=0 then begin
    Result:='default';
    Exit;
  end;
  if Combo.ItemIndex<PrgSetup.DOSBoxSettingsCount then
    Result:=PrgSetup.DOSBoxSettings[Combo.ItemIndex].Name;
end;

procedure TModernProfileEditorDOSBoxFrame.UpdateDOSBoxInstallationString;
Var S : String;
    TG : TGame;
    OldKind : TDOSBoxKind;
begin
  TG:=TModernProfileEditorForm(Owner).TempGame;
  OldKind:=TG.DosBoxKind;
  If DefaultDOSBoxInstallationRadioButton.Checked then
    S:=DOSBoxComboInstallValue(DOSBoxInstallationComboBox)
  else
    S:=CustomDOSBoxInstallationEdit.Text;
  TG.CustomDOSBoxDir:=S;
  If TG.DosBoxKind<>OldKind then
    TModernProfileEditorForm(Owner).InvalidateFrames;
end;

procedure TModernProfileEditorDOSBoxFrame.UpdateLanguageList;
Var Save,DosBoxDir : String;
    Idx : Integer;
begin
  If DefaultDOSBoxInstallationRadioButton.Checked then begin
    Idx:=DOSBoxInstallationComboBox.ItemIndex;
    If (Idx<0) or (Idx>=PrgSetup.DOSBoxSettingsCount) then
      DosBoxDir:=''
    else
      DosBoxDir:=IncludeTrailingPathDelimiter(PrgSetup.DOSBoxSettings[Idx].DosBoxDir);
    FOnProfileNameChange(self,ProfileName^,ProfileExe^,ProfileSetup^,'','',ProfileCaptureDir^);
  end else begin
    DosBoxDir:=IncludeTrailingPathDelimiter(CustomDOSBoxInstallationEdit.Text);
    FOnProfileNameChange(self,ProfileName^,ProfileExe^,ProfileSetup^,'','',ProfileCaptureDir^);
  end;

  If UserLanguageComboBox.ItemIndex>=0 then Save:=UserLanguageComboBox.Items[UserLanguageComboBox.ItemIndex] else Save:='';
  UserLanguageComboBox.Items.BeginUpdate;
  try
    UserLanguageComboBox.Items.Clear;
    DosBoxLang.Clear;

    UserLanguageComboBox.Items.Add('English');
    DosBoxLang.Add('English');

    FindAndAddLngFiles(IncludeTrailingPathDelimiter(DosBoxDir),UserLanguageComboBox.Items,DosBoxLang);
    FindAndAddLngFiles(PrgDir+LanguageSubDir+'\',UserLanguageComboBox.Items,DosBoxLang);
    UserLanguageComboBox.ItemIndex:=Max(0,UserLanguageComboBox.Items.IndexOf(Save));
  finally
    UserLanguageComboBox.Items.EndUpdate;
  end;

  SelectInLanguageList(Save);
end;

procedure TModernProfileEditorDOSBoxFrame.UserLanguageCheckBoxClick(Sender: TObject);
begin
  UserLanguageComboBox.Enabled:=UserLanguageCheckBox.Checked;
end;

procedure TModernProfileEditorDOSBoxFrame.UserConsoleCheckBoxClick(Sender: TObject);
begin
  UserConsoleComboBox.Enabled:=UserConsoleCheckBox.Checked;
end;

Procedure TModernProfileEditorDOSBoxFrame.SelectInLanguageList(const LangName : String);
Var I : Integer;
    S : String;
begin
  If Trim(LangName)<>'' then begin
    I:=UserLanguageComboBox.Items.IndexOf(LangName);
    If I>=0 then begin UserLanguageComboBox.ItemIndex:=I; exit; end;
  end;

  UserLanguageComboBox.ItemIndex:=0;
  If not DefaultDOSBoxInstallationRadioButton.Checked then exit;
  If DOSBoxInstallationComboBox.ItemIndex<0 then exit;
  If DOSBoxInstallationComboBox.ItemIndex>=PrgSetup.DOSBoxSettingsCount then exit;

  S:=ChangeFileExt(ExtractFileName(PrgSetup.DOSBoxSettings[DOSBoxInstallationComboBox.ItemIndex].DosBoxLanguage),'');
  UserLanguageComboBox.ItemIndex:=Max(0,UserLanguageComboBox.Items.IndexOf(S));
end;

procedure TModernProfileEditorDOSBoxFrame.SelectInConsoleList;
begin
  UserConsoleComboBox.ItemIndex:=0;
  If not DefaultDOSBoxInstallationRadioButton.Checked then exit;
  If DOSBoxInstallationComboBox.ItemIndex<0 then exit;
  If DOSBoxInstallationComboBox.ItemIndex>=PrgSetup.DOSBoxSettingsCount then exit;

  If PrgSetup.DOSBoxSettings[DOSBoxInstallationComboBox.ItemIndex].HideDosBoxConsole
    then UserConsoleComboBox.ItemIndex:=0
    else UserConsoleComboBox.ItemIndex:=1;
end;

procedure TModernProfileEditorDOSBoxFrame.GetGame(const Game: TGame);
begin
  Game.Priority:=FPriority[DOSBoxForegroundPriorityComboBox.ItemIndex]+','+BPriority[DOSBoxBackgroundPriorityComboBox.ItemIndex];
  Game.CloseDosBoxAfterGameExit:=CloseDOSBoxOnExitCheckBox.Checked;
  Game.RunAsAdmin:=RunAsAdminCheckBox.Checked;
  If DefaultDOSBoxInstallationRadioButton.Checked then begin
    { ItemIndex -1 → keep unset (''). Only an explicit combo pick writes a value. }
    Game.CustomDOSBoxDir:=DOSBoxComboInstallValue(DOSBoxInstallationComboBox);
  end else begin
    Game.CustomDOSBoxDir:=CustomDOSBoxInstallationEdit.Text;
  end;

  If UserLanguageCheckBox.Checked then Game.CustomDOSBoxLanguage:=ExtractFileName(DosBoxLang[UserLanguageComboBox.ItemIndex]) else Game.CustomDOSBoxLanguage:='default';
  If UserConsoleCheckBox.Checked then begin
    If UserConsoleComboBox.ItemIndex=1 then Game.ShowConsoleWindow:=2 else Game.ShowConsoleWindow:=0;
  end else Game.ShowConsoleWindow:=1;

  Game.CustomSettings:=StringListToString(CustomSetsMemo.Lines);
end;

procedure TModernProfileEditorDOSBoxFrame.CustomDOSBoxInstallationButtonClick(Sender: TObject);
Var S : String;
begin
  S:=Trim(CustomDOSBoxInstallationEdit.Text);
  If S='' then S:=PrgSetup.DOSBoxSettings[0].DosBoxDir;
  S:=MakeAbsPath(S,PrgSetup.BaseDir);
  if not SelectDirectory(Handle,LanguageSetup.ChooseFolder,S) then exit;
  S:=MakeRelPath(S,PrgSetup.BaseDir,True);
  If S='' then exit;
  CustomDOSBoxInstallationEdit.Text:=IncludeTrailingPathDelimiter(S);
end;

procedure TModernProfileEditorDOSBoxFrame.UpdateDBKindIcon(const Kind: TDOSBoxKind);
var
  Path: String;
  P: TPicture;
  K: TDOSBoxKind;
begin
  { Full-res PNG from IconSets\DOSBoxKind\ (standard / X / staging / unknown-sadmac). }
  DBKindIcon.Stretch := True;
  DBKindIcon.Proportional := True;
  DBKindIcon.Center := True;
  DBKindIcon.Picture.Assign(nil);
  { No install chosen → same missing art as invalid/unknown. }
  if Kind = dbkNone then
    K := dbkUnknown
  else
    K := Kind;
  Path := ResolveDOSBoxKindPreviewPath(K);
  if Path = '' then
    Path := ResolveDOSBoxKindIconPath(K);
  if Path = '' then Exit;
  P := LoadImageFromFile(Path);
  if P = nil then Exit;
  try
    try
      DBKindIcon.Picture.Assign(P);
    except
      { ignore assign failure }
    end;
  finally
    P.Free;
  end;
end;

procedure TModernProfileEditorDOSBoxFrame.UpdateDBKindIconFromSelection;
begin
  UpdateDBKindIcon(TModernProfileEditorForm(Owner).TempGame.DosBoxKind);
end;

procedure TModernProfileEditorDOSBoxFrame.DOSBoxInstallationTypeClick(Sender: TObject);
begin
  UpdateLanguageList;
  If not UserLanguageCheckBox.Checked then SelectInLanguageList('');
  If not UserConsoleCheckBox.Checked then SelectInConsoleList;
  UpdateDOSBoxInstallationString;
  UpdateDBKindIconFromSelection;
end;

procedure TModernProfileEditorDOSBoxFrame.DOSBoxInstallationComboBoxChange(Sender: TObject);
begin
  DefaultDOSBoxInstallationRadioButton.Checked:=True;
  UpdateLanguageList;
  If not UserLanguageCheckBox.Checked then SelectInLanguageList('');
  If not UserConsoleCheckBox.Checked then SelectInConsoleList;
  UpdateDOSBoxInstallationString;
  UpdateDBKindIconFromSelection;
  { Uncomment to dump kind detection into CustomSetsMemo: }
  { DumpDosBoxKindDebug; }
end;

function TModernProfileEditorDOSBoxFrame.DebugGetExeFileDescription(const ExePath: String): String;
var
  Size, Handle: DWORD;
  Buffer: Pointer;
  Len: UINT;
  Value: Pointer;
  Trans: PLongWord;
  LangCharset, Query, FileName: String;
begin
  Result := '';
  FileName := ExePath;
  UniqueString(FileName);
  Size := GetFileVersionInfoSize(PChar(FileName), Handle);
  if Size = 0 then
  begin
    Result := '(GetFileVersionInfoSize=0 err=' + IntToStr(GetLastError) + ')';
    Exit;
  end;
  GetMem(Buffer, Size);
  try
    if not GetFileVersionInfo(PChar(FileName), Handle, Size, Buffer) then
    begin
      Result := '(GetFileVersionInfo failed err=' + IntToStr(GetLastError) + ')';
      Exit;
    end;
    if not VerQueryValue(Buffer, '\VarFileInfo\Translation', Pointer(Trans), Len) then
    begin
      Result := '(no Translation block)';
      Exit;
    end;
    if (Trans = nil) or (Len < SizeOf(LongWord)) then
    begin
      Result := '(Translation nil/short len=' + IntToStr(Len) + ')';
      Exit;
    end;
    LangCharset := IntToHex(LoWord(Trans^), 4) + IntToHex(HiWord(Trans^), 4);
    Query := '\StringFileInfo\' + LangCharset + '\FileDescription';
    if VerQueryValue(Buffer, PChar(Query), Value, Len) and (Value <> nil) then
      Result := PChar(Value) + '  [lang=' + LangCharset + ' rawLen=' + IntToStr(Len) + ']'
    else
      Result := '(no FileDescription for lang=' + LangCharset + ')';
  finally
    FreeMem(Buffer);
  end;
end;

procedure TModernProfileEditorDOSBoxFrame.DumpDosBoxKindDebug;
var
  St: TStringList;
  Idx: Integer;
  Setting: TDOSBoxSetting;
  RawDir, AbsDir, ExeName, Desc, UpperDesc, Version: String;
  SR: TSearchRec;
  Kind: TDOSBoxKind;
  N: Integer;
begin
  St := TStringList.Create;
  try
    St.Add('=== DOSBox kind debug (combo change) ===');
    St.Add('Combo.ItemIndex=' + IntToStr(DOSBoxInstallationComboBox.ItemIndex));
    St.Add('Combo.Text=' + DOSBoxInstallationComboBox.Text);
    St.Add('PrgSetup.BaseDir=' + PrgSetup.BaseDir);
    St.Add('DOSBoxSettingsCount=' + IntToStr(PrgSetup.DOSBoxSettingsCount));
    St.Add('');

    Idx := DOSBoxInstallationComboBox.ItemIndex;
    if (Idx < 0) or (Idx >= PrgSetup.DOSBoxSettingsCount) then
    begin
      St.Add('ERROR: ItemIndex out of range');
      CustomSetsMemo.Lines.Assign(St);
      Exit;
    end;

    Setting := PrgSetup.DOSBoxSettings[Idx];
    RawDir := Setting.DosBoxDir;
    AbsDir := IncludeTrailingPathDelimiter(MakeAbsPath(RawDir, PrgSetup.BaseDir));

    St.Add('--- selected TDOSBoxSetting ---');
    St.Add('Name=' + Setting.Name);
    St.Add('DosBoxDir (raw)=' + RawDir);
    St.Add('DosBoxDir (abs)=' + AbsDir);
    St.Add('Setting.DosBoxKind enum Ord=' + IntToStr(Ord(Setting.DosBoxKind)) +
      ' display=' + DOSBoxKindToDisplay(Setting.DosBoxKind));
    St.Add('DirectoryExists(abs)=' + BoolToStr(DirectoryExists(AbsDir), True));
    St.Add('');

    St.Add('--- DetermineDosBoxKind(raw Dir) ---');
    Kind := DetermineDosBoxKind(RawDir, Version);
    St.Add('Result Ord=' + IntToStr(Ord(Kind)) + ' display=' + DOSBoxKindToDisplay(Kind) +
      ' Version=' + Version);
    St.Add('');

    St.Add('--- DetermineDosBoxKind(abs Dir) ---');
    Kind := DetermineDosBoxKind(AbsDir, Version);
    St.Add('Result Ord=' + IntToStr(Ord(Kind)) + ' display=' + DOSBoxKindToDisplay(Kind) +
      ' Version=' + Version);
    St.Add('');

    St.Add('--- dosbox*.exe scan (FindFirst order) ---');
    N := 0;
    if DirectoryExists(AbsDir) then
    begin
      if FindFirst(AbsDir + 'dosbox*.exe', faAnyFile, SR) = 0 then
      try
        repeat
          if (SR.Attr and faDirectory) = 0 then
          begin
            Inc(N);
            ExeName := SR.Name;
            Desc := DebugGetExeFileDescription(AbsDir + ExeName);
            UpperDesc := ExtUpperCase(Desc);
            St.Add(Format('[%d] name=%s', [N, ExeName]));
            St.Add('    full=' + AbsDir + ExeName);
            St.Add('    FileExists=' + BoolToStr(FileExists(AbsDir + ExeName), True));
            St.Add('    Description=' + Desc);
            St.Add('    ExtUpperCase(Desc)=' + UpperDesc);
            St.Add('    Pos DOSBOX-X=' + IntToStr(Pos('DOSBOX-X', UpperDesc)));
            St.Add('    Pos STAGING=' + IntToStr(Pos('STAGING', UpperDesc)));
            St.Add('    Pos DOSBOX=' + IntToStr(Pos('DOSBOX', UpperDesc)));
            St.Add('    SameText(name,dosbox.exe)=' + BoolToStr(SameText(ExeName, 'dosbox.exe'), True));
            if Pos('DOSBOX-X', UpperDesc) > 0 then
              St.Add('    => branch would be X')
            else if Pos('STAGING', UpperDesc) > 0 then
              St.Add('    => branch would be Staging')
            else if SameText(ExeName, 'dosbox.exe') and (Pos('DOSBOX', UpperDesc) > 0) then
              St.Add('    => branch would be Standard')
            else
              St.Add('    => branch would be Unknown');
          end;
        until FindNext(SR) <> 0;
      finally
        SysUtils.FindClose(SR);
      end;
    end;
    if N = 0 then
      St.Add('(no dosbox*.exe found)');
    St.Add('');
    St.Add('First match only is used by DetermineDosBoxKind.');
    St.Add('=== end debug ===');

    CustomSetsMemo.Lines.Assign(St);
  finally
    St.Free;
  end;
end;

procedure TModernProfileEditorDOSBoxFrame.CustomDOSBoxInstallationEditChange(Sender: TObject);
begin
  CustomDOSBoxInstallationRadioButton.Checked:=True;
  UpdateLanguageList;
  If not UserLanguageCheckBox.Checked then SelectInLanguageList('');
  UpdateDOSBoxInstallationString;
  UpdateDBKindIconFromSelection;
end;

procedure TModernProfileEditorDOSBoxFrame.ButtonWork(Sender: TObject);
begin
  Case (Sender as TComponent).Tag of
    0 : CustomSetsMemo.Lines.Clear;
    1 : begin
          ForceDirectories(PrgDataDir+CustomConfigsSubDir);

          OpenDialog.DefaultExt:='txt';
          OpenDialog.Filter:=LanguageSetup.ProfileEditorCustomSetsFilter;
          OpenDialog.Title:=LanguageSetup.ProfileEditorCustomSetsLoadTitle;
          OpenDialog.InitialDir:=PrgDataDir+CustomConfigsSubDir;
          if not OpenDialog.Execute then exit;
          try
            CustomSetsMemo.Lines.LoadFromFile(OpenDialog.FileName);
          except
            MessageDlg(Format(LanguageSetup.MessageCouldNotOpenFile,[OpenDialog.FileName]),mtError,[mbOK],0);
          end;
        end;
    2 : begin
          ForceDirectories(PrgDataDir+CustomConfigsSubDir);

          SaveDialog.DefaultExt:='txt';
          SaveDialog.Filter:=LanguageSetup.ProfileEditorCustomSetsFilter;
          SaveDialog.Title:=LanguageSetup.ProfileEditorCustomSetsSaveTitle;
          SaveDialog.InitialDir:=PrgDataDir+CustomConfigsSubDir;
          if not SaveDialog.Execute then exit;
          try
            CustomSetsMemo.Lines.SaveToFile(SaveDialog.FileName);
          except
            MessageDlg(Format(LanguageSetup.MessageCouldNotSaveFile,[SaveDialog.FileName]),mtError,[mbOK],0);
          end;
        end;
  end;
end;

end.
