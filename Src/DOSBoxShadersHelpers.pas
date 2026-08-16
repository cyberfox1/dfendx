unit DOSBoxShadersHelpers;

interface

uses
  Classes, PrgConsts;

{ Per-backend inventory map:
  - Strings[i]  = relative shader id under that backend's dir (no extension, PathDelim)
  - Objects[i]  = TStringList of preset names (no extension); empty for DOSBox-X

  TDOSBoxShaderBackendMaps holds OpenGL and Direct3D maps. Caller frees with
  FreeShaderBackendMaps (frees every Objects[i] then each map). }
type
  TDOSBoxShaderBackendMaps = record
    OpenGL: TStringList;
    Direct3D: TStringList;
  end;

function CreateEmptyShaderBackendMaps: TDOSBoxShaderBackendMaps;
procedure FreeShaderBackendMaps(var Maps: TDOSBoxShaderBackendMaps);
procedure FreeShaderMap(var Map: TStringList);

{ FileExt includes the leading dot (e.g. '.glsl', '.fx').
  CollectPresets: Staging 0.83+ shader-presets under parents; off for X. }
function GatherDOSBoxShaders(const ParentPaths: TStrings;
  const ShadersDir, FileExt: string;
  CollectPresets: Boolean): TStringList;

{ Staging: OpenGL filled; Direct3D empty. }
function GetDOSBoxStagingShaders(const DosBoxPath: string;
  IsOldStaging: Boolean): TDOSBoxShaderBackendMaps;

{ X: OpenGL from glshaders\*.glsl; Direct3D from shaders\*.fx. }
function GetDOSBoxXShaders(const DosBoxPath: string): TDOSBoxShaderBackendMaps;

{ Standard / unknown: old DFend + D3D-fork style under install\Shaders\ (*.fx).
  Root files → "name"; one category level → "category-name" (hyphen).
  Same list on both OpenGL and Direct3D maps (conf always uses pixelshader). }
function GetDOSBoxStandardShaders(const DosBoxPath: string): TDOSBoxShaderBackendMaps;

{ Kind switch: Staging / X / standard-style. }
function GetDOSBoxShaders(const DosBoxPath: string; Kind: TDOSBoxKind;
  IsOldStaging: Boolean): TDOSBoxShaderBackendMaps;

function JoinRelPath(const Prefix, Name: string): string;
function IsShaderFileName(const FileName: string): Boolean;
function IsFxFileName(const FileName: string): Boolean;
function IsPresetFileName(const FileName: string): Boolean;
function EnsureShaderEntry(Map: TStringList; const Key: string): TStringList;

procedure CollectPresetsFromResourceParents(const ParentPaths: TStrings;
  const ShaderId: string; Presets: TStringList);
procedure CollectPresetsInDir(const PresetDir: string; Presets: TStringList);

procedure ScanShadersDir(const AbsDir, RelPrefix: string; Depth: Integer;
  Map: TStringList; const FileExt: string);
function StagingIsLegacyGlShaders(const Version: string): Boolean;

function StagingShaderConfKey(const Version: string): string;
function FormatStagingShaderConfValue(const ShaderDisplay, PresetDisplay: string;
  ApplyPreset: Boolean): string;

procedure MaybeAddParentPath(Parents: TStringList; const Path: string);
function LocalAppDataDOSBoxDir: string;
function LocalAppDataDOSBoxXDir: string;
procedure BuildStagingShaderParents(const ExeDir: string; Parents: TStringList);
procedure BuildDOSBoxXShaderParents(const ExeDir: string; Parents: TStringList);

implementation

uses
  Windows, SysUtils, ShlObj, DOSBoxUnitHelpers;

const
  MaxShaderDirDepth = 3;
  ShaderFileExt = '.glsl';
  FxFileExt = '.fx';
  PresetFileExt = '.preset';
  InternalShaderDirName = '_internal';
  { DOSBox-X default res root on Win32 (Cross::GetPlatformResDir). }
  DosBoxXDefaultResDir = 'C:\DOSBox-X';

function CreateEmptyShaderBackendMaps: TDOSBoxShaderBackendMaps;
begin
  Result.OpenGL := TStringList.Create;
  Result.OpenGL.CaseSensitive := False;
  Result.OpenGL.Duplicates := dupIgnore;
  Result.Direct3D := TStringList.Create;
  Result.Direct3D.CaseSensitive := False;
  Result.Direct3D.Duplicates := dupIgnore;
end;

procedure FreeShaderMap(var Map: TStringList);
var
  I: Integer;
begin
  if Map = nil then
    Exit;
  for I := 0 to Map.Count - 1 do
    TStringList(Map.Objects[I]).Free;
  FreeAndNil(Map);
end;

procedure FreeShaderBackendMaps(var Maps: TDOSBoxShaderBackendMaps);
begin
  FreeShaderMap(Maps.OpenGL);
  FreeShaderMap(Maps.Direct3D);
end;

function JoinRelPath(const Prefix, Name: string): string;
begin
  if Prefix = '' then
    Result := Name
  else
    Result := Prefix + PathDelim + Name;
end;

function IsShaderFileName(const FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), ShaderFileExt);
end;

function IsFxFileName(const FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), FxFileExt);
end;

function IsPresetFileName(const FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), PresetFileExt);
end;

function IsInternalShaderPath(const RelPath: string): Boolean;
var
  S: string;
begin
  S := RelPath;
  while (S <> '') and ((S[1] = PathDelim) or (S[1] = '/')) do
    Delete(S, 1, 1);
  Result := SameText(Copy(S, 1, Length(InternalShaderDirName)), InternalShaderDirName)
    and ((Length(S) = Length(InternalShaderDirName))
      or (S[Length(InternalShaderDirName) + 1] = PathDelim)
      or (S[Length(InternalShaderDirName) + 1] = '/'));
end;

function EnsureShaderEntry(Map: TStringList; const Key: string): TStringList;
var
  Idx: Integer;
begin
  Idx := Map.IndexOf(Key);
  if Idx >= 0 then
    Result := TStringList(Map.Objects[Idx])
  else begin
    Result := TStringList.Create;
    Result.CaseSensitive := False;
    Map.AddObject(Key, Result);
  end;
end;

procedure CollectPresetsInDir(const PresetDir: string; Presets: TStringList);
var
  Root: string;
  Rec: TSearchRec;
  I: Integer;
  Name: string;
begin
  if Presets = nil then
    Exit;
  Root := IncludeTrailingPathDelimiter(PresetDir);
  if not DirectoryExists(Root) then
    Exit;

  I := FindFirst(Root + '*.*', faAnyFile, Rec);
  if I <> 0 then
    Exit;
  try
    while I = 0 do begin
      if (Rec.Name <> '.') and (Rec.Name <> '..') and
         ((Rec.Attr and faDirectory) = 0) and
         IsPresetFileName(Rec.Name) then begin
        Name := ChangeFileExt(Rec.Name, '');
        if (Name <> '') and (Presets.IndexOf(Name) < 0) then
          Presets.Add(Name);
      end;
      I := FindNext(Rec);
    end;
  finally
    SysUtils.FindClose(Rec);
  end;
end;

procedure CollectPresetsFromResourceParents(const ParentPaths: TStrings;
  const ShaderId: string; Presets: TStringList);
var
  I: Integer;
  Parent, PresetRoot, Id: string;
begin
  if (ParentPaths = nil) or (Presets = nil) or (Trim(ShaderId) = '') then
    Exit;
  Id := StringReplace(Trim(ShaderId), '/', PathDelim, [rfReplaceAll]);

  for I := 0 to ParentPaths.Count - 1 do begin
    Parent := Trim(ParentPaths[I]);
    if Parent = '' then
      Continue;
    PresetRoot := IncludeTrailingPathDelimiter(Parent) + DosBoxStagingShaderPresetsDir +
      PathDelim + Id;
    CollectPresetsInDir(PresetRoot, Presets);
  end;
end;

procedure ScanShadersDir(const AbsDir, RelPrefix: string; Depth: Integer;
  Map: TStringList; const FileExt: string);
var
  Rec: TSearchRec;
  I: Integer;
  Root: string;
  Leaf: string;
  Key: string;
  Ext: string;
begin
  if Depth > MaxShaderDirDepth then
    Exit;

  Ext := FileExt;
  if (Ext <> '') and (Ext[1] <> '.') then
    Ext := '.' + Ext;

  Root := IncludeTrailingPathDelimiter(AbsDir);
  if not DirectoryExists(Root) then
    Exit;

  I := FindFirst(Root + '*.*', faAnyFile, Rec);
  if I <> 0 then
    Exit;
  try
    while I = 0 do begin
      if (Rec.Name <> '.') and (Rec.Name <> '..') then begin
        if (Rec.Attr and faDirectory) <> 0 then begin
          if not SameText(Rec.Name, InternalShaderDirName) then
            if Depth < MaxShaderDirDepth then
              ScanShadersDir(Root + Rec.Name, JoinRelPath(RelPrefix, Rec.Name),
                Depth + 1, Map, Ext);
        end else if SameText(ExtractFileExt(Rec.Name), Ext) then begin
          Leaf := ChangeFileExt(Rec.Name, '');
          if Leaf <> '' then begin
            Key := JoinRelPath(RelPrefix, Leaf);
            if not IsInternalShaderPath(Key) then
              EnsureShaderEntry(Map, Key);
          end;
        end;
      end;
      I := FindNext(Rec);
    end;
  finally
    SysUtils.FindClose(Rec);
  end;
end;

function GatherDOSBoxShaders(const ParentPaths: TStrings;
  const ShadersDir, FileExt: string;
  CollectPresets: Boolean): TStringList;
var
  I: Integer;
  Parent, ShaderRoot: string;
  DirName: string;
  Presets: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;
  if (ParentPaths = nil) or (ParentPaths.Count = 0) then
    Exit;

  DirName := ExcludeTrailingPathDelimiter(Trim(ShadersDir));
  if DirName = '' then
    Exit;

  for I := 0 to ParentPaths.Count - 1 do begin
    Parent := Trim(ParentPaths[I]);
    if Parent = '' then
      Continue;
    ShaderRoot := IncludeTrailingPathDelimiter(Parent) + DirName;
    if not DirectoryExists(ShaderRoot) then
      Continue;
    ScanShadersDir(ShaderRoot, '', 0, Result, FileExt);
  end;

  if CollectPresets then
    for I := 0 to Result.Count - 1 do begin
      Presets := TStringList(Result.Objects[I]);
      if Presets <> nil then
        CollectPresetsFromResourceParents(ParentPaths, Result[I], Presets);
    end;
end;

function StagingIsLegacyGlShaders(const Version: string): Boolean;
begin
  if Trim(Version) = '' then
    Result := True
  else
    Result := CompareDOSBoxVersion(Version, '0.83.0.0') < 0;
end;

function StagingShaderConfKey(const Version: string): string;
begin
  if StagingIsLegacyGlShaders(Version) then
    Result := 'glshader'
  else
    Result := 'shader';
end;

function FormatStagingShaderConfValue(const ShaderDisplay, PresetDisplay: string;
  ApplyPreset: Boolean): string;
var
  Shader, Preset: string;
begin
  Shader := Trim(ShaderDisplay);
  if (Shader = '') or (CompareText(Shader, 'none') = 0) then begin
    Result := '';
    Exit;
  end;
  Shader := StringReplace(Shader, '\', '/', [rfReplaceAll]);
  if ApplyPreset then begin
    Preset := Trim(PresetDisplay);
    if Preset <> '' then
      Result := Shader + ':' + Preset
    else
      Result := Shader;
  end else
    Result := Shader;
end;

procedure MaybeAddParentPath(Parents: TStringList; const Path: string);
var
  P: string;
begin
  P := Trim(Path);
  if P = '' then
    Exit;
  if not DirectoryExists(P) then
    Exit;
  P := ExcludeTrailingPathDelimiter(ExpandFileName(P));
  if Parents.IndexOf(P) < 0 then
    Parents.Add(P);
end;

function LocalAppDataDOSBoxDir: string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  Result := '';
  FillChar(Buf, SizeOf(Buf), 0);
  if SHGetSpecialFolderPath(0, Buf, CSIDL_LOCAL_APPDATA, False) then
    Result := IncludeTrailingPathDelimiter(Buf) + 'DOSBox';
end;

function LocalAppDataDOSBoxXDir: string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  Result := '';
  FillChar(Buf, SizeOf(Buf), 0);
  if SHGetSpecialFolderPath(0, Buf, CSIDL_LOCAL_APPDATA, False) then
    Result := IncludeTrailingPathDelimiter(Buf) + 'DOSBox-X';
end;

procedure BuildStagingShaderParents(const ExeDir: string; Parents: TStringList);
var
  Base: string;
begin
  Base := ExcludeTrailingPathDelimiter(ExpandFileName(ExeDir));
  MaybeAddParentPath(Parents, Base + PathDelim + 'resources');
  MaybeAddParentPath(Parents, Base + PathDelim + '..' + PathDelim + 'resources');
  if FileExists(Base + PathDelim + 'dosbox-staging.conf') then
    MaybeAddParentPath(Parents, Base)
  else
    MaybeAddParentPath(Parents, LocalAppDataDOSBoxDir);
end;

procedure BuildDOSBoxXShaderParents(const ExeDir: string; Parents: TStringList);
var
  Base: string;
begin
  Base := Trim(ExeDir);
  if Base <> '' then
    MaybeAddParentPath(Parents, Base);
  MaybeAddParentPath(Parents, LocalAppDataDOSBoxXDir);
  MaybeAddParentPath(Parents, DosBoxXDefaultResDir);
end;

function GetDOSBoxStagingShaders(const DosBoxPath: string;
  IsOldStaging: Boolean): TDOSBoxShaderBackendMaps;
var
  Parents: TStringList;
  ShadersDir, Base: string;
begin
  Result := CreateEmptyShaderBackendMaps;
  FreeShaderMap(Result.OpenGL);

  if IsOldStaging then
    ShadersDir := DosBoxStagingShadersDirLegacy
  else
    ShadersDir := DosBoxStagingShadersDir;

  Parents := TStringList.Create;
  try
    Parents.CaseSensitive := False;
    Base := Trim(DosBoxPath);
    if Base <> '' then
      BuildStagingShaderParents(Base, Parents);
    Result.OpenGL := GatherDOSBoxShaders(Parents, ShadersDir, ShaderFileExt, True);
  finally
    Parents.Free;
  end;
end;

function GetDOSBoxXShaders(const DosBoxPath: string): TDOSBoxShaderBackendMaps;
var
  Parents: TStringList;
begin
  Result := CreateEmptyShaderBackendMaps;
  FreeShaderMap(Result.OpenGL);
  FreeShaderMap(Result.Direct3D);

  Parents := TStringList.Create;
  try
    Parents.CaseSensitive := False;
    BuildDOSBoxXShaderParents(DosBoxPath, Parents);
    Result.OpenGL := GatherDOSBoxShaders(Parents, DosBoxXGlShadersDir, ShaderFileExt, False);
    Result.Direct3D := GatherDOSBoxShaders(Parents, DosBoxXShadersDir, FxFileExt, False);
  finally
    Parents.Free;
  end;
end;

{ Old DFend (orig GetPixelShaders): install\Shaders\*.fx flat.
  Later DFend: also one category level → "category-name". Both here. }
function GatherStandardFxShaderIds(const DosBoxPath: string): TStringList;
var
  Root, CatName, CatPath, Id: string;
  Rec, Rec2: TSearchRec;
  I, J: Integer;
  Cats: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;

  Root := IncludeTrailingPathDelimiter(Trim(DosBoxPath)) + 'Shaders' + PathDelim;
  if not DirectoryExists(Root) then
    Exit;

  Cats := TStringList.Create;
  try
    I := FindFirst(Root + '*.*', faAnyFile, Rec);
    try
      while I = 0 do begin
        if (Rec.Name <> '.') and (Rec.Name <> '..') then begin
          if (Rec.Attr and faDirectory) <> 0 then
            Cats.Add(Rec.Name)
          else if IsFxFileName(Rec.Name) then begin
            Id := ChangeFileExt(Rec.Name, '');
            if Id <> '' then
              EnsureShaderEntry(Result, Id);
          end;
        end;
        I := FindNext(Rec);
      end;
    finally
      SysUtils.FindClose(Rec);
    end;

    for I := 0 to Cats.Count - 1 do begin
      CatName := Cats[I];
      CatPath := Root + CatName + PathDelim;
      J := FindFirst(CatPath + '*.*', faAnyFile, Rec2);
      try
        while J = 0 do begin
          if (Rec2.Name <> '.') and (Rec2.Name <> '..') and
             ((Rec2.Attr and faDirectory) = 0) and
             IsFxFileName(Rec2.Name) then begin
            Id := CatName + '-' + ChangeFileExt(Rec2.Name, '');
            if Id <> CatName + '-' then
              EnsureShaderEntry(Result, Id);
          end;
          J := FindNext(Rec2);
        end;
      finally
        SysUtils.FindClose(Rec2);
      end;
    end;
  finally
    Cats.Free;
  end;
end;

function CloneShaderMap(const Source: TStringList): TStringList;
var
  I: Integer;
  Presets: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;
  if Source = nil then
    Exit;
  for I := 0 to Source.Count - 1 do begin
    Presets := TStringList.Create;
    Presets.CaseSensitive := False;
    if Source.Objects[I] <> nil then
      Presets.AddStrings(TStringList(Source.Objects[I]));
    Result.AddObject(Source[I], Presets);
  end;
end;

function GetDOSBoxStandardShaders(const DosBoxPath: string): TDOSBoxShaderBackendMaps;
var
  Ids: TStringList;
begin
  Result := CreateEmptyShaderBackendMaps;
  FreeShaderMap(Result.OpenGL);
  FreeShaderMap(Result.Direct3D);

  Ids := GatherStandardFxShaderIds(DosBoxPath);
  { Same FX list on both backends: standard conf always pixelshader=;
    UI may show OpenGL or other output. Direct3D owns Ids; OpenGL is a clone. }
  Result.Direct3D := Ids;
  Result.OpenGL := CloneShaderMap(Ids);
end;

function GetDOSBoxShaders(const DosBoxPath: string; Kind: TDOSBoxKind;
  IsOldStaging: Boolean): TDOSBoxShaderBackendMaps;
begin
  case Kind of
    dbkStaging:
      Result := GetDOSBoxStagingShaders(DosBoxPath, IsOldStaging);
    dbkX:
      Result := GetDOSBoxXShaders(DosBoxPath);
  else
    { dbkStandard, dbkNone, dbkUnknown — old Shaders\*.fx discovery }
    Result := GetDOSBoxStandardShaders(DosBoxPath);
  end;
end;

end.
