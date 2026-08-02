unit CheatDBToolsUnit;
interface

uses Classes, Forms, CheatDBUnit, ProgramUpdateCheckUnit;

Function SmartLoadCheatsDB : TCheatDB;
Procedure SmartSaveCheatsDB(const ACheatDB : TCheatDB; const AForm : TForm);

Procedure BackupFileBeforeApplyingCheat(const FileName : String);

Function GetGameFolders(const BaseGameFolder : String; const Depth : Integer = 0) : TStringList;
Function FindMatchingGameRecords(const CheatDB : TCheatDB; const Folders : TStringList) : TStringList;

Procedure CheatsDBUpdateCheckIfSetup(const AForm : TForm);
Function CheatsDBUpdateCheck(const AForm : TForm; const Quite : Boolean) : TUpdateResult;

implementation

uses Windows, SysUtils, Dialogs, Math, CommonHelpers, CommonTools, PrgConsts, PrgSetupUnit,
     DownloadWaitFormUnit, LanguageSetupUnit, System.UITypes, CheatDBHelpers;

Function CheatsDBAvailable : Boolean;
begin
  result:=
    FileExists(PrgDataDir+SettingsFolder+'\'+CheatDBFile) or
    FileExists(PrgDir+BinFolder+'\'+CheatDBFile) or
    FileExists(PrgDir+CheatDBFile);
end;

Function SmartLoadCheatsDB : TCheatDB;
Var B : Boolean;
begin
  result:=TCheatDB.Create;

  If FileExists(PrgDataDir+SettingsFolder+'\'+CheatDBFile) then begin
    B:=result.LoadFromXML(PrgDataDir+SettingsFolder+'\'+CheatDBFile);
  end else begin
    B:=False;
  end;

  If not B then begin
    If FileExists(PrgDir+BinFolder+'\'+CheatDBFile) then begin
      B:=result.LoadFromXML(PrgDir+BinFolder+'\'+CheatDBFile);
    end else begin
      B:=False;
    end;
  end;

  If not B then begin
    If FileExists(PrgDir+CheatDBFile) then begin
      B:=result.LoadFromXML(PrgDir+CheatDBFile);
    end else begin
      B:=False;
    end;
  end;

  If not B then FreeAndNil(result);
end;

Procedure SmartSaveCheatsDB(const ACheatDB : TCheatDB; const AForm : TForm);
begin
  If not ACheatDB.Changed then exit;
  ForceDirectories(PrgDataDir+SettingsFolder);
  ACheatDB.SaveToXML(PrgDataDir+SettingsFolder+'\'+CheatDBFile,AForm);
end;

Procedure BackupFileBeforeApplyingCheat(const FileName : String);
Function BackupFile(const Nr : Integer) : String; begin result:=FileName+'.backup'+IntToStr(Nr); end;
Var I : Integer;
begin
  If FileExists(BackupFile(9)) then ExtDeleteFile(BackupFile(9),ftUninstall);
  For I:=8 downto 1 do begin
    If FileExists(BackupFile(I)) then begin
      If not MoveFileEx(PChar(BackupFile(I)),PChar(BackupFile(I+1)),MOVEFILE_REPLACE_EXISTING) then ExtDeleteFile(BackupFile(I),ftUninstall);
    end;
  end;
  CopyFile(PChar(FileName),PChar(BackupFile(1)),False);
end;

Function GetGameFolders(const BaseGameFolder : String; const Depth : Integer = 0) : TStringList;
Var I : Integer;
    Rec : TSearchRec;
    St : TStringList;
begin
  result:=TStringList.Create;
  If Depth>=3 then exit;
  result.Add(IncludeTrailingPathDelimiter(BaseGameFolder));
  I:=FindFirst(IncludeTrailingPathDelimiter(BaseGameFolder)+'*.*',faDirectory,Rec);
  try
    While I=0 do begin
      If ((Rec.Attr and faDirectory)=faDirectory) and (Rec.Name<>'.') and (Rec.Name<>'..') then begin
        St:=GetGameFolders(IncludeTrailingPathDelimiter(BaseGameFolder)+Rec.Name,Depth+1);
        try
          result.AddStrings(St);
        finally
          St.Free;
        end;
      end;
      I:=FindNext(Rec);
    end;
  finally
    FindClose(Rec);
  end;
end;

Function FindMatchingGameRecords(const CheatDB : TCheatDB; const Folders : TStringList) : TStringList;
Var I,J,K,L : Integer;
    Rec : TSearchRec;
    B : Boolean;
begin
  result:=TStringList.Create;
  For I:=0 to CheatDB.Count-1 do begin
    B:=False;
    For J:=0 to CheatDB[I].Count-1 do begin
      For K:=0 to Folders.Count-1 do begin
        L:=FindFirst(Folders[K]+CheatDB[I][J].FileMask,faAnyFile,Rec); FindClose(Rec);
        If L=0 then begin result.AddObject(CheatDB[I].Name,CheatDB[I]); B:=True; break; end;
      end;
      If B then break;
    end;
  end;
  result.Sort;
end;

Procedure CheatsDBUpdateCheckIfSetup(const AForm : TForm);
Var DoUpdateCheck : Boolean;
begin
  If not CheatsDBAvailable then DoUpdateCheck:=True else begin
    DoUpdateCheck:=False;
    Case PrgSetup.CheatsDBCheckForUpdates of
      0 : DoUpdateCheck:=False;
      1 : DoUpdateCheck:=(Round(Int(Date))>=PrgSetup.LastCheatsDBUpdateCheck+7);
      2 : DoUpdateCheck:=(Round(Int(Date))>=PrgSetup.LastCheatsDBUpdateCheck+1);
      3 : DoUpdateCheck:=True;
    End;
  end;
  If DoUpdateCheck then CheatsDBUpdateCheck(AForm,True);
end;

Procedure UpdateCheatsDB(const MainDB, TempDB : TCheatDB);
Var I,J,Nr1,Nr2 : Integer;
    G : TCheatGameRecord;
    A : TCheatAction;
begin
  MainDB.Version:=TempDB.Version;
  For I:=0 to TempDB.Count-1 do begin
    Nr1:=MainDB.IndexOf(TempDB[I].Name);
    If Nr1<0 then begin
      {Copy TempDB[I] to MainDB}
      G:=TCheatGameRecord.Create(nil);
      G.CopyFrom(TempDB[I]);
      MainDB.Add(G);
    end else begin
      For J:=0 to TempDB[I].Count-1 do begin
        Nr2:=MainDB[Nr1].IndexOf(TempDB[I][J].Name);
        If Nr2>=0 then continue;
        {Copy TempDB[I][J] to MainDB[Nr1]}
        A:=TCheatAction.Create(nil);
        A.CopyFrom(TempDB[I][J]);
        MainDB[Nr1].Add(A);
      end;
    end;
  end;
end;

Function CheatsDBUpdateCheck(const AForm : TForm; const Quite : Boolean) : TUpdateResult;
Var CheatDB, TempDB : TCheatDB;
    DefaultDBFile, TempDBFile : String;
    DR : TDownloadResult;
begin
  result:=urUpdateInstallCanceled;

  DefaultDBFile:=PrgDataDir+SettingsFolder+'\'+CheatDBFile;
  TempDBFile:=TempDir+CheatDBFile;

  CheatDB:=SmartLoadCheatsDB;
  try
    If CheatDB=nil then TempDBFile:=DefaultDBFile;
    If Quite then DR:=DownloadFileWithOutDialog(AForm,-1,'',CheatDBUpdateURL,'',TempDBFile)
             else DR:=DownloadFileWithDialog(AForm,-1,'',CheatDBUpdateURL,'',TempDBFile);
    If DR=drFail then begin
      MessageDlg(Format(LanguageSetup.PackageManagerDownloadFailed,[CheatDBUpdateURL]),mtError,[mbOK],0);
      exit;
    end;
    If CheatDB=nil then begin
      if DR=drSuccess then result:=urUpdateInstalled else result:=urUpdateInstallCanceled;
      exit;
    end;

    If DR<>drSuccess then begin
      result:=urUpdateInstallCanceled;
      exit;
    end;

    result:=urNoUpdatesAvailable;

    PrgSetup.LastCheatsDBUpdateCheck:=Round(Int(Date));

    TempDB:=TCheatDB.Create;
    try
      if not TempDB.LoadFromXML(TempDBFile) then exit;
      if TempDB.Version>CheatDB.Version then begin
        UpdateCheatsDB(CheatDB,TempDB);
        SmartSaveCheatsDB(CheatDB,AForm);
        result:=urUpdateInstalled;
      end;
    finally
      TempDB.Free;
      ExtDeleteFile(TempDBFile,ftTemp);
    end;
  finally
    If Assigned(CheatDB) then CheatDB.Free;
  end;
end;


end.
