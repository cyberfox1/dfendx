unit MultipleProfilesEditorFormHelpers;

interface

uses SysUtils, Classes, GameDBUnit, GameDBToolsUnit;

Function GetAllUserInfoKeys(const GameDB : TGameDB) : TStringList;
Procedure SetUserInfo(const G : TGame; const Key, Value : String);
Procedure DelUserInfo(const G : TGame; const Key : String);
Procedure ChangeMountSetting(const G : TGame; const SetDefault : Boolean);
Function GetReplaceFolderList(const GameDB : TGameDB) : TStringList;
procedure ReplaceFolderWork(const G: TGame; const FromValue, ToValue : String);

implementation

uses CommonHelpers, CommonTools, PrgSetupUnit;

Function GetAllUserInfoKeys(const GameDB : TGameDB) : TStringList;
Var I,J,K : Integer;
    St, Upper : TStringList;
    S : String;
begin
  Upper:=TStringList.Create;
  result:=TStringList.Create;
  try
    try
      For I:=0 to GameDB.Count-1 do begin
        St:=nil;
        St:=StringToStringList(GameDB[I].UserInfo);
        try
          For J:=0 to St.Count-1 do begin
            S:=Trim(St[J]);
            K:=Pos('=',S); If K=0 then continue;
            S:=Trim(Copy(S,1,K-1));
            If S='' then continue;
            If Upper.IndexOf(ExtUpperCase(S))<0 then begin
              result.Add(S);
              Upper.Add(ExtUpperCase(S));
            end;
          end;
        finally
          if St <> nil then St.Free;
        end;
      end;
    except
      result.Free;
      raise;
    end;
  finally
    Upper.Free;
  end;
end;

Procedure SetUserInfo(const G : TGame; const Key, Value : String);
Var St : TStringList;
    ValueFound : Boolean;
    I,J : Integer;
    KeyUpper, S : String;
begin
  KeyUpper:=Trim(ExtUpperCase(Key));
  St:=StringToStringList(G.UserInfo);
  try
    ValueFound:=False;
    For I:=0 to St.Count-1 do begin
      S:=Trim(St[I]);
      J:=Pos('=',S); If J=0 then continue;
      S:=Trim(Copy(S,1,J-1));
      If ExtUpperCase(S)=KeyUpper then begin St[I]:=Key+'='+Value; ValueFound:=True; break; end;
    end;
    If not ValueFound then St.Add(Key+'='+Value);
    G.UserInfo:=StringListToString(St);
  finally
    St.Free;
  end;
end;

Procedure DelUserInfo(const G : TGame; const Key : String);
Var St : TStringList;
    KeyUpper,S : String;
    I,J : Integer;
begin
  KeyUpper:=Trim(ExtUpperCase(Key));
  St:=StringToStringList(G.UserInfo);
  try
    I:=0;
    while I<St.Count do begin
      S:=Trim(St[I]);
      J:=Pos('=',S); If J=0 then begin inc(I); continue; end;
      S:=Trim(Copy(S,1,J-1));
      If ExtUpperCase(S)=KeyUpper then begin St.Delete(I); continue; end;
      inc(I);
    end;
    G.UserInfo:=StringListToString(St);
  finally
    St.Free;
  end;
end;

Procedure ChangeMountSetting(const G : TGame; const SetDefault : Boolean);
Var I : Integer;
    AllGamesDir,GameDir,S : String;
    St : TStringList;
begin
  {Only process if normal start (not booting from image}
  If Trim(G.AutoexecBootImage)<>'' then exit;

  {Exit if mounting not used}
  If G.AutoexecOverrideMount then exit;

  AllGamesDir:=IncludeTrailingPathDelimiter(MakeAbsPath(PrgSetup.GameDir,PrgSetup.BaseDir));
  If (Trim(G.GameExe)='') or (Copy(Trim(ExtUpperCase(G.GameExe)),1,7)='DOSBOX:') then GameDir:='' else GameDir:=IncludeTrailingPathDelimiter(MakeAbsPath(ExtractFilePath(G.GameExe),PrgSetup.BaseDir));

  For I:=0 to G.NrOfMounts-1 do begin
    St:=ValueToList(G.Mount[I]);
    try
      {RealFolder;DRIVE;Letter;False;;FreeSpace}
      If (St.Count<3) or (Trim(ExtUpperCase(St[1]))<>'DRIVE') or (Trim(ExtUpperCase(St[2]))<>'C')  then continue;
      S:=IncludeTrailingPathDelimiter(MakeAbsPath(St[0],PrgSetup.BaseDir));
      If SetDefault then begin
        If Trim(ExtUpperCase(GameDir))=Trim(ExtUpperCase(S)) then begin
          St[0]:=MakeRelPath(PrgSetup.GameDir,PrgSetup.BaseDir);
          G.Mount[I]:=ListToValue(St);
          G.StoreAllValues;
          exit;
        end;
      end else begin
        If (Trim(ExtUpperCase(AllGamesDir))=Trim(ExtUpperCase(S))) and (GameDir<>'') then begin
          St[0]:=MakeRelPath(GameDir,PrgSetup.BaseDir);
          G.Mount[I]:=ListToValue(St);
          G.StoreAllValues;
          exit;
        end;
      end;  
    finally
      St.Free;
    end;
  end;
end;

Function GetReplaceFolderList(const GameDB : TGameDB) : TStringList;
Var I,J : Integer;
    G : TGame;
    St,St2 : TStringList;
begin
  result:=TStringList.Create;
  St:=TStringList.Create;
  try
    For I:=0 to GameDB.Count-1 do begin
      G:=GameDB[I];
      If ScummVMMode(G) or WindowsExeMode(G) then continue;
      For J:=0 to G.NrOfMounts-1 do begin
        {RealFolder;Type;Letter;IO;Label;FreeSpace; Type=DRIVE}
        St2:=ValueToList(G.Mount[J]);
        try
          If St2.Count<2 then continue;
          If Trim(ExtUpperCase(St2[1]))<>'DRIVE' then continue;
          If St.IndexOf(ExtUpperCase(IncludeTrailingPathDelimiter(St2[0])))>=0 then continue;
          St.Add(ExtUpperCase(IncludeTrailingPathDelimiter(St2[0])));
          result.Add(IncludeTrailingPathDelimiter(St2[0]));
        finally
          St2.Free;
        end;
      end;
    end;
  finally
    St.Free;
  end;
end;

procedure ReplaceFolderWork(const G: TGame; const FromValue, ToValue : String);
Var I : Integer;
    St : TStringList;
    S : String;
begin
  S:=IncludeTrailingPathDelimiter(Trim(ExtUpperCase(FromValue)));

  For I:=0 to G.NrOfMounts-1 do begin
    {RealFolder;Type;Letter;IO;Label;FreeSpace; Type=DRIVE}
    St:=ValueToList(G.Mount[I]);
    try
      If St.Count<2 then continue;
      If Trim(ExtUpperCase(St[1]))<>'DRIVE' then continue;
      If IncludeTrailingPathDelimiter(Trim(ExtUpperCase(St[0])))=S then begin
        St[0]:=ToValue;
        G.Mount[I]:=ListToValue(St);
      end;
    finally
      St.Free;
    end;
  end;
end;

end.
