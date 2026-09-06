unit ModernProfileEditorDrivesFrameUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Buttons, ComCtrls, GameDBUnit, ModernProfileEditorFormUnit,
  Menus, ImgList, System.ImageList;

type
  TModernProfileEditorDrivesFrame = class(TFrame, IModernProfileEditorFrame)
    AutoMountCheckBox: TCheckBox;
    MountingListView: TListView;
    MountingAddButton: TBitBtn;
    MountingEditButton: TBitBtn;
    MountingDelButton: TBitBtn;
    MountingDeleteAllButton: TBitBtn;
    MountingAutoCreateButton: TBitBtn;
    SecureModeCheckBox: TCheckBox;
    HardDiskOptionsGroupBox: TGroupBox;
    FloppyOptionsGroupBox: TGroupBox;
    HardDiskSpeedLabel: TLabel;
    FloppyDiskSpeedLabel: TLabel;
    HardDiskNoiseLabel: TLabel;
    FloppyDiskNoiseLabel: TLabel;
    HardDiskSpeedComboBox: TComboBox;
    FloppyDiskSpeedComboBox: TComboBox;
    HardDiskNoiseComboBox: TComboBox;
    FloppyDiskNoiseComboBox: TComboBox;
    PopupMenu: TPopupMenu;
    PopupAdd: TMenuItem;
    PopupEdit: TMenuItem;
    PopupDelete: TMenuItem;
    ImageList: TImageList;
    procedure ButtonWork(Sender: TObject);
    procedure MountingListViewDblClick(Sender: TObject);
    procedure MountingListViewKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private-Deklarationen }
    FTempGame : TGame;
    Mounting : TStringList;
    ProfileExe, ProfileSetup, ProfileName : PString;
    FGetFrame : TGetFrameFunction;
    GameDB : TGameDB;
    FDiskSpeedConfOpt : String;
    FDiskNoiseConfOpt : String;
    Procedure LoadMountingList;
    function CanReachFile(const FileName: String): Boolean;
    function IsNewStaging: Boolean;
    procedure SelectDiskCombo(Combo: TComboBox; const GameValue: String);
    procedure ApplyKindEnable;
    procedure ShowFrame(Sender: TObject);
    procedure Invalidate(Sender: TObject);
  public
    { Public-Deklarationen }
    Constructor Create(AOwner : TComponent); override;
    Destructor Destroy; override;
    Procedure InitGUI(var InitData : TModernProfileEditorInitData);
    Procedure SetGame(const Game : TGame; const LoadFromTemplate : Boolean);
    Procedure GetGame(const Game : TGame);
  end;

implementation

uses Math, VistaToolsUnit, LanguageSetupUnit, CommonHelpers, PrgSetupUnit,
     ProfileMountEditorFormUnit, HelpConsts, GameDBToolsUnit, IconLoaderUnit,
     ModernProfileEditorBaseFrameUnit, PrgConsts, System.UITypes,
     ModernProfileEditorDrivesFrameHelpers;

{$R *.dfm}

{ TModernProfileEditorDrivesFrame }

constructor TModernProfileEditorDrivesFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTempGame:=TModernProfileEditorForm(AOwner).TempGame;
  Mounting:=nil;
end;

procedure TModernProfileEditorDrivesFrame.InitGUI(var InitData : TModernProfileEditorInitData);
begin
  NoFlicker(MountingListView);
  NoFlicker(MountingAddButton);
  NoFlicker(MountingEditButton);
  NoFlicker(MountingDelButton);
  NoFlicker(MountingDeleteAllButton);
  NoFlicker(MountingAutoCreateButton);
  NoFlicker(AutoMountCheckBox);
  NoFlicker(SecureModeCheckBox);
  NoFlicker(HardDiskSpeedComboBox);
  NoFlicker(FloppyDiskSpeedComboBox);
  NoFlicker(HardDiskNoiseComboBox);
  NoFlicker(FloppyDiskNoiseComboBox);

  MountingAddButton.Caption:=LanguageSetup.ProfileEditorMountingAdd;
  MountingEditButton.Caption:=LanguageSetup.ProfileEditorMountingEdit;
  MountingDelButton.Caption:=LanguageSetup.ProfileEditorMountingDel;
  MountingDeleteAllButton.Caption:=LanguageSetup.ProfileEditorMountingDelAll;
  MountingAutoCreateButton.Caption:=LanguageSetup.ProfileEditorMountingAutoCreate;
  InitMountingListView(MountingListView);
  AutoMountCheckBox.Caption:=LanguageSetup.ProfileEditorMountingAutoMountCDs;
  SecureModeCheckBox.Caption:=LanguageSetup.ProfileEditorMountingSecureMode;
  HardDiskOptionsGroupBox.Caption:=LanguageSetup.ProfileEditorMountingHardDiskOptions;
  FloppyOptionsGroupBox.Caption:=LanguageSetup.ProfileEditorMountingFloppyOptions;
  HardDiskSpeedLabel.Caption:=LanguageSetup.ProfileEditorMountingHardDiskSpeed;
  FloppyDiskSpeedLabel.Caption:=LanguageSetup.ProfileEditorMountingFloppyDiskSpeed;
  HardDiskNoiseLabel.Caption:=LanguageSetup.ProfileEditorMountingHardDiskNoise;
  FloppyDiskNoiseLabel.Caption:=LanguageSetup.ProfileEditorMountingFloppyDiskNoise;
  FDiskSpeedConfOpt:=InitData.GameDB.ConfOpt.DiskSpeedStaging;
  FDiskNoiseConfOpt:=InitData.GameDB.ConfOpt.DiskNoiseStaging;
  RebuildComboFromConfOpt(HardDiskSpeedComboBox,FDiskSpeedConfOpt,'');
  RebuildComboFromConfOpt(FloppyDiskSpeedComboBox,FDiskSpeedConfOpt,'');
  RebuildComboFromConfOpt(HardDiskNoiseComboBox,FDiskNoiseConfOpt,'');
  RebuildComboFromConfOpt(FloppyDiskNoiseComboBox,FDiskNoiseConfOpt,'');
  InitData.OnShowFrame:=ShowFrame;
  InitData.OnInvalidate:=Invalidate;
  UserIconLoader.DialogImage(DI_Add,MountingAddButton);
  UserIconLoader.DialogImage(DI_Edit,MountingEditButton);
  UserIconLoader.DialogImage(DI_Delete,MountingDelButton);
  UserIconLoader.DialogImage(DI_Wizard,MountingAutoCreateButton);

  PopupAdd.Caption:=LanguageSetup.ProfileEditorMountingAdd;
  PopupEdit.Caption:=LanguageSetup.ProfileEditorMountingEdit;
  PopupDelete.Caption:=LanguageSetup.ProfileEditorMountingDel;
  PopupEdit.ShortCut:=ShortCut(VK_Return,[]);
  UserIconLoader.DialogImage(DI_Add,ImageList,0);
  UserIconLoader.DialogImage(DI_Edit,ImageList,1);
  UserIconLoader.DialogImage(DI_Delete,ImageList,2);

  ProfileExe:=InitData.CurrentProfileExe;
  ProfileSetup:=InitData.CurrentProfileSetup;
  ProfileName:=InitData.CurrentProfileName;

  FGetFrame:=InitData.GetFrame;

  GameDB:=InitData.GameDB;

  HelpContext:=ID_ProfileEditDrives;
end;

procedure TModernProfileEditorDrivesFrame.SetGame(const Game: TGame; const LoadFromTemplate: Boolean);
Var I : Integer;
begin
  if Assigned(Mounting) then FreeAndNil(Mounting);
  Mounting:=TStringList.Create;
  For I:=0 to 9 do
    If Game.NrOfMounts>=I+1 then Mounting.Add(Game.Mount[I]) else break;
  LoadMountingList;
  AutoMountCheckBox.Checked:=Game.AutoMountCDs;
  SecureModeCheckBox.Checked:=Game.SecureMode;
  SelectDiskCombo(HardDiskSpeedComboBox,Game.HardDiskSpeed);
  SelectDiskCombo(FloppyDiskSpeedComboBox,Game.FloppyDiskSpeed);
  SelectDiskCombo(HardDiskNoiseComboBox,Game.HardDiskNoise);
  SelectDiskCombo(FloppyDiskNoiseComboBox,Game.FloppyDiskNoise);
  ApplyKindEnable;
end;

procedure TModernProfileEditorDrivesFrame.LoadMountingList;
begin
  LoadMountingListView(MountingListView,Mounting);
end;

function TModernProfileEditorDrivesFrame.CanReachFile(const FileName: String): Boolean;
Var S,FilePath : String;
    St : TStringList;
    I : Integer;
begin
  result:=False;
  FilePath:=Trim(ExtUpperCase(IncludeTrailingPathDelimiter(ShortName(MakeAbsPath(ExtractFilePath(FileName),PrgSetup.BaseDir)))));
  For I:=0 to Mounting.Count-1 do begin
    St:=ValueToList(Mounting[I]);
    try
      {Types to check:
       RealFolder;DRIVE;Letter;False;;FreeSpace
       RealFolder;FLOPPY;Letter;False;;
       RealFolder;CDROM;Letter;IO;Label;
       all other are images}
      If St.Count<2 then continue;
      S:=Trim(ExtUpperCase(St[1]));
      If (S<>'DRIVE') and (S<>'FLOPPY') and (S<>'CDROM') then continue;
      S:=Trim(ExtUpperCase(IncludeTrailingPathDelimiter(ShortName(MakeAbsPath(St[0],PrgSetup.BaseDir)))));

      result:=(Copy(FilePath,1,length(S))=S);
      if result then exit;
    finally
      St.Free;
    end;
  end;
end;

procedure TModernProfileEditorDrivesFrame.ButtonWork(Sender: TObject);
Var S,InitialDir : String;
    I : Integer;
    St : TStringList;
    F : TModernProfileEditorBaseFrame;
begin
  F:=FGetFrame(TModernProfileEditorBaseFrame) as TModernProfileEditorBaseFrame;
  If F.GameRelPathCheckBox.Checked or (Trim(ProfileExe^)='')
    then InitialDir:=MakeAbsPath(PrgSetup.GameDir,PrgSetup.BaseDir)
    else InitialDir:=IncludeTrailingPathDelimiter(ExtractFilePath(ProfileExe^));

  Case (Sender as TComponent).Tag of
    0 : If Mounting.Count<10 then begin
          S:='';
          if not ShowProfileMountEditorDialog(self,S,UsedDriveLetters(Mounting),InitialDir,ProfileName^,GameDB,F,NextFreeDriveLetter(Mounting)) then exit;
          Mounting.Add(S);
          LoadMountingList;
          MountingListView.ItemIndex:=MountingListView.Items.Count-1;
        end;
    1 : begin
          I:=MountingListView.ItemIndex;
          If I<0 then exit;
          S:=Mounting[I];
          if not ShowProfileMountEditorDialog(self,S,UsedDriveLetters(Mounting, I),InitialDir,ProfileName^,GameDB,F) then exit;
          Mounting[I]:=S;
          LoadMountingList;
          MountingListView.ItemIndex:=I;
        end;
    2 : begin
          I:=MountingListView.ItemIndex;
          If I<0 then exit;
          Mounting.Delete(I);
          LoadMountingList;
          If Mounting.Count>0 then MountingListView.ItemIndex:=Max(0,I-1);
        end;
    3 : If (Mounting.Count>0) and (Messagedlg(LanguageSetup.ProfileEditorMountingDeleteAllMessage,mtConfirmation,[mbYes,mbNo],0)=mrYes) then begin
          Mounting.Clear;
          LoadMountingList;
        end;
    4 : begin
          I:=0;
          while I<Mounting.Count do begin
            St:=ValueToList(Mounting[I]);
            try
              If (St.Count>=3) and (St[2]='C') then begin Mounting.Delete(I); continue; end;
              inc(I);
            finally
              St.Free;
            end;
          end;
          {Add VirtualHD dir}
          If Mounting.Count<10 then Mounting.Insert(0,MakeRelPath(PrgSetup.GameDir,PrgSetup.BaseDir,True)+';Drive;C;false;');
          {Add game dir if needed}
          If (Mounting.Count<10) and (Trim(ProfileExe^)<>'') and (not CanReachFile(ProfileExe^)) and (ExtUpperCase(Copy(ProfileExe^,1,7))<>'DOSBOX:') then begin
            S:=IncludeTrailingPathDelimiter(MakeRelPath(ExtractFilePath(ProfileExe^),PrgSetup.BaseDir));
            Mounting.Add(S+';DRIVE;'+NextFreeDriveLetter(Mounting)+';False;;'+IntToStr(DefaultFreeHDSize));
          end;
          {Add setup dir if needed}
          If (Mounting.Count<10) and (Trim(ProfileSetup^)<>'') and (not CanReachFile(ProfileSetup^)) and (ExtUpperCase(Copy(ProfileSetup^,1,7))<>'DOSBOX:') then begin
            S:=IncludeTrailingPathDelimiter(MakeRelPath(ExtractFilePath(ProfileSetup^),PrgSetup.BaseDir));
            Mounting.Add(S+';DRIVE;'+NextFreeDriveLetter(Mounting)+';False;;'+IntToStr(DefaultFreeHDSize));
          end;
          LoadMountingList;
        end;
  end;
end;

procedure TModernProfileEditorDrivesFrame.MountingListViewDblClick(Sender: TObject);
begin
  ButtonWork(MountingEditButton);
end;

procedure TModernProfileEditorDrivesFrame.MountingListViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  If (Shift=[ssCtrl]) and (Key=VK_RETURN) then begin ButtonWork(MountingEditButton); exit; end;
  If Shift<>[] then exit;
  Case Key of
    VK_INSERT : ButtonWork(MountingAddButton);
    VK_RETURN : ButtonWork(MountingEditButton);
    VK_DELETE : ButtonWork(MountingDelButton);
  end;
end;

procedure TModernProfileEditorDrivesFrame.GetGame(const Game: TGame);
Var I : Integer;
begin
  Game.NrOfMounts:=Mounting.Count;
  For I:=0 to 9 do
    If Mounting.Count>I then Game.Mount[I]:=Mounting[I] else Game.Mount[I]:='';
  Game.AutoMountCDs:=AutoMountCheckBox.Checked;
  Game.SecureMode:=SecureModeCheckBox.Checked;
  if HardDiskSpeedComboBox.ItemIndex>=0 then
    Game.HardDiskSpeed:=Trim(HardDiskSpeedComboBox.Text);
  if FloppyDiskSpeedComboBox.ItemIndex>=0 then
    Game.FloppyDiskSpeed:=Trim(FloppyDiskSpeedComboBox.Text);
  if HardDiskNoiseComboBox.ItemIndex>=0 then
    Game.HardDiskNoise:=Trim(HardDiskNoiseComboBox.Text);
  if FloppyDiskNoiseComboBox.ItemIndex>=0 then
    Game.FloppyDiskNoise:=Trim(FloppyDiskNoiseComboBox.Text);
end;

procedure TModernProfileEditorDrivesFrame.SelectDiskCombo(Combo: TComboBox; const GameValue: String);
begin
  if ComboHasValue(Combo,GameValue) then
    SelectComboValue(Combo,GameValue)
  else
    SetComboNoSelect(Combo);
end;

function TModernProfileEditorDrivesFrame.IsNewStaging: Boolean;
begin
  Result:=(FTempGame<>nil) and FTempGame.IsNewStaging;
end;

procedure TModernProfileEditorDrivesFrame.ApplyKindEnable;
var
  OnNew: Boolean;
  CapColor: TColor;
begin
  OnNew:=IsNewStaging;
  if OnNew then CapColor:=clWindowText else CapColor:=clGrayText;
  HardDiskOptionsGroupBox.Enabled:=OnNew;
  HardDiskOptionsGroupBox.Font.Color:=CapColor;
  FloppyOptionsGroupBox.Enabled:=OnNew;
  FloppyOptionsGroupBox.Font.Color:=CapColor;
  HardDiskSpeedLabel.Enabled:=OnNew;
  HardDiskSpeedComboBox.Enabled:=OnNew;
  FloppyDiskSpeedLabel.Enabled:=OnNew;
  FloppyDiskSpeedComboBox.Enabled:=OnNew;
  HardDiskNoiseLabel.Enabled:=OnNew;
  HardDiskNoiseComboBox.Enabled:=OnNew;
  FloppyDiskNoiseLabel.Enabled:=OnNew;
  FloppyDiskNoiseComboBox.Enabled:=OnNew;
  if not OnNew then begin
    SetComboNoSelect(HardDiskSpeedComboBox);
    SetComboNoSelect(FloppyDiskSpeedComboBox);
    SetComboNoSelect(HardDiskNoiseComboBox);
    SetComboNoSelect(FloppyDiskNoiseComboBox);
  end else if FTempGame<>nil then begin
    if HardDiskSpeedComboBox.ItemIndex<0 then
      SelectDiskCombo(HardDiskSpeedComboBox,FTempGame.HardDiskSpeed);
    if FloppyDiskSpeedComboBox.ItemIndex<0 then
      SelectDiskCombo(FloppyDiskSpeedComboBox,FTempGame.FloppyDiskSpeed);
    if HardDiskNoiseComboBox.ItemIndex<0 then
      SelectDiskCombo(HardDiskNoiseComboBox,FTempGame.HardDiskNoise);
    if FloppyDiskNoiseComboBox.ItemIndex<0 then
      SelectDiskCombo(FloppyDiskNoiseComboBox,FTempGame.FloppyDiskNoise);
  end;
end;

procedure TModernProfileEditorDrivesFrame.ShowFrame(Sender: TObject);
begin
  ApplyKindEnable;
end;

procedure TModernProfileEditorDrivesFrame.Invalidate(Sender: TObject);
begin
  ApplyKindEnable;
end;

Destructor TModernProfileEditorDrivesFrame.Destroy;
begin
  if Assigned(Mounting) then Mounting.Free;
  inherited Destroy;
end;

end.
