unit PrgConsts;
interface

type
  TDOSBoxKind = (dbkNone, dbkStandard, dbkX, dbkStaging, dbkUnknown);
  { Media extension type aliases — reserved for future use }

  { Staging [sdl] inactive-window behaviour (profile + UI radio). }
  TScreenInactiveMode = (
    simDoNothing = 0,
    simMute = 1,
    simPause = 2
  );

  { Indices into MainUnit.ImageList for Sounds / Videos list items.
    Must match the glyphs at those slots (also referenced from MainUnit.dfm). }
  TMediaListImageIndex = (
    mliSound = 33,
    mliVideo = 38
  );

  { Application log verbosity (PrgSetup.LogLevel / [ProgramSets] LogLevel). }
  TLogLevel = (
    llOff = 0,
    llInfo = 1,
    llWarning = 2,
    llCritical = 3
  );

const
  { INI string values for TLogLevel / PrgSetup.LogLevel. }
  LogLevelOff = 'OFF';
  LogLevelInfo = 'INFO';
  LogLevelWarning = 'WARNING';
  LogLevelCritical = 'CRITICAL';

  DosBoxKindStandard = 'standard';
  DosBoxKindX        = 'x';
  DosBoxKindStaging  = 'staging';
  DosBoxKindUnknown  = 'unknown';

  { DOSBox Staging shader resource subdirs (under resource parents). }
  DosBoxStagingShadersDirLegacy = 'glshaders'; { empty version or < 0.83.0.0 }
  DosBoxStagingShadersDir       = 'shaders';   { 0.83.0.0+ }
  DosBoxStagingShaderPresetsDir = 'shader-presets';

  { DOSBox-X shader resource subdirs (under exe / config / res parents). }
  DosBoxXGlShadersDir = 'glshaders'; { OpenGL GLSL }
  DosBoxXShadersDir   = 'shaders';   { Direct3D .fx }

  { DOS / DOSBox short-name allow-list (8.3-style guest names), not Windows Unicode paths.
    Shared by FileNameHelpers.HasForbiddenChars and DOSBoxShortNameUnit.PathNameOK. }
  DosBoxShortNameAllowedChars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
    'abcdefghijklmnopqrstuvwxyz' +
    '0123456789' +
    '$#@()' +
    '!%{}`~' +
    '_-.&''+^' +
    #246#255#$A0#$E5;

const DosBoxFileName='DOSBOX.EXE';
      DosBoxConfFileName='DOSBOX.CONF';
      MakeDOSFilesystemFileName='mkdosfs.exe';

      ConfOptFile='ConfOpt.dat';
      ScummVMConfOptFile='ScummVM.dat';
      HistoryFileName='History.dat';
      IconsConfFile='Icons.ini';
      DosBoxDOSProfile='DOSBox DOS';
      RenderTestTempFile='Output.txt';
      ScreenshotsCacheFileName='ScreenshotsThumbnailCache.dat';
      ScreenshotsCacheDBFileName='ScreenshotsCache.db';

      GameListSubDir='Confs';
      IconsSubDir='IconLibrary';
      CaptureSubDir='Capture';
      LanguageSubDir='Lang';
      CustomConfigsSubDir='CustomConfigs';
      TemplateSubDir='Templates';
      AutoSetupSubDir='AutoSetup';
      NewUserDataSubDir='NewUserData';
      PhysFSDefaultWriteDir='PhysWrite';
      ZipTempDir='ZipTemp'; {Subdir of BaseDataDir; ment as base directory for extracting zip file for mounting}
      TempSubFolder='DFendX zip package'; {Subdir fo TempDir; ment for internal use when building/extracting zip packages}
      BinFolder='Bin';
      SettingsFolder='Settings';
      IconSetsFolder='IconSets';

      ImageExtensions : array[0..4] of String = ('.png','.jpg','.jpeg','.gif','.bmp');
      VideoExtensions : array[0..5] of String = ('.mp4','.avi','.mpeg','.mpg','.wmv','.asf');
      DocumentExtensions : array[0..4] of String = ('.pdf','.txt','.html','.htm','.chm');
      AudioExtensions : array[0..5] of String = ('.mp3','.ogg','.wav','.flac','.mid','.midi');

      NSIInstallerHelpFile='DFendX DataInstaller.nsi';

      DFRHomepage='https:/'+'/github.com/cyberfox1/dfendx/';

      OggEncPrgFile='oggenc2.exe';
      LamePrgFile='lame.exe';
      ScummPrgFile='scummvm.exe';
      ScummVMConfFileName='scummvm.ini';
      QBasicPrgFile='QBasic.exe';
      QB45PrgFile='QB.exe';
      QB71PrgFile='QBX.exe';

      PackageDBSubFolder='Settings\Packages';
      PackageDBCacheSubFolder='Settings\Packages\Cache';
      PackageDBMainFileURL=DFRHomepage+'Packages/DFR.xml?version=%s';
      PackageDBTempFile='DFRTemp.xml';
      PackageDBMainFile='DFR.xml';
      PackageDBUserFile='User.xml';
      PackageDBCacheFile='Cache.xml';

      CacheVersionString='DFRCacheFile-FileVersion=005';
      CacheInfoString=#13+#13+'This is just a cache file for the profiles in the current directory. You can'+#13+
                      'ignore or delete this file. DFendX will only load data from this file'+#13+
                      'if the .prof file on disk has not changed. If you delete or change one of the'+#13+
                      '.prof files manually the cache will not be used for this profile. So just'+#13+
                      'ignore this file, you can still do what ever you want in this folder. This'+#13+
                      'cache will never mess up your database.'+#13+#13+
                      'You can turn off the creation of this cache files by setting "BinaryCache=0" in'+#13+
                      'the [ProgramSets] section of the DFendX.ini.'+#13+#13+#13+
                      '===Start of binary cache==='+#13;
      CacheFile='Cache.dfr';

      DataReaderUpdateURL=DFRHomepage+'DataReader/DataReader.xml';
      DataReaderConfigFile='DataReader.xml';

      CheatDBFile='Cheats.xml';
      CheatDBSearchSubFolder='Settings\AddressSearch';
      CheatDBUpdateURL=DFRHomepage+'Cheats/Cheats.xml';

      DBGLPackageInfoFile='profiles.xml';

      MinSupportedDOSBoxVersion=0.73;

      DefaultFreeHDSize=250;


const FD10KernelSys='18D296F40F06C8A26EDA606C0031F677';
      FD11KernelSys='A9076CA70EAD7463354B3E4248ECBC21';
      FD10Dos32aExe='A5F5195B509B10228EFE61C47427CA54';
      FD10HimemExe='E3F9A56A9C1BA2656B10E5FE29A37D56';
      FD10Emm386Exe='250C47587506265FBBEA62AE2981BB28';
     

const DefaultInstallerNames : String = 'INSTALL;SETUP;INSTHD;INST;INSTALAR;INSTALLE';
      DefaultArchiveIDFiles : String = 'FILE_ID.DIZ';
      ProgramExts : Array[1..3] of String = ('EXE','COM','BAT');

      IgnoreGameExeFilesIgnore : Array[1..50] of String = (
        'README','DECIDE','DEICE','CATALOG','FACTORY','LIST','LHARC','ARJ',
        'UNARJ','UNZIP','HELPME','ORDER','DEALERS','ULTRAMID','PRINTME',
        'UNIVBE','SWCBBS','INSTHELP','COMMIT','SETMAIN','BOOTMKR','IMUSE',
        'KEYCONFI','32RTM','LOADPATS','MAKESWP','XPHELP','IBMSND','MIDPAK',
        'SBLASTER','ALIVECAT','READDOC','CWSDPMI','PSETD','PSETM','ADLIB',
        'ADLIBG','CMIDPAK','CVXSND','DIGISP','DIGVESA','LANTSND','MULTISND',
        'NOSOUND','PAUDIO','SBCLONE','SMSND','SNDSYS','VMSND',
        'READTHIS'
      );

      SetupExeFilesLevel1 : Array[1..2] of String = ('SETUP','CONFIG');
      SetupExeFilesLevel2 : Array[1..4] of String = ('SETSOUND','SETSND','SETBLAST','SOUND');
      SetupExeFilesLevel3 : Array[1..6] of String = ('XINSTALL','SETUPAQ','SETUPDP','SETUPVC','MSETUP','DSETUP32');
      SetupExeFilesLevel4 : Array[1..1] of String = ('INSTALL');

      ProgramExeFiles : Array[1..1] of String = ('GO');

      AdditionalChecksumDataGoodFileExt : Array[0..11] of String = (
        'EXE','COM','DAT','ICO','HLP','DRV','DLL','PAK','PIC','LFL','BIN','OVL'
      );
      AdditionalChecksumDataExcludeFiles : Array[0..32] of String = (
        'SCORE','DOS4GW','CATALOG','LHARC','ARJ','UNARJ','UNZIP','ORDER',
        'DEALERS','ULTRAMID','UNIVBE','SWCBBS','COMMIT','SETMAIN','IMUSE',
        'CWSDPMI','PSETD','PSETM','ADLIB','ADLIBG','CMIDPAK','CVXSND','DIGISP',
        'DIGVESA','LANTSND','MULTISND','NOSOUND','PAUDIO','SBCLONE','SBLASTER',
        'SMSND','SNDSYS','VMSND'
      );

var MainSetupFile : String;
    OperationModeConfig : String;

    { ExtUpperCase/ExtLowerCase specials (CommonHelpers). LanguageSetupUnit
      overwrites these when a language file is loaded. }
    LanguageSpecialLowerCase: String = #228#246#252;
    LanguageSpecialUpperCase: String = #196#214#220;

implementation

{$IFDEF FPC}
uses SysUtils;
{$ELSE}
uses SysUtils;
{$ENDIF}

initialization
{$IFDEF FPC}
  MainSetupFile:='DFend.ini';
  OperationModeConfig:='DFend.dat';
{$ELSE}
  MainSetupFile:=ChangeFileExt(ExtractFileName(ParamStr(0)),'.ini');
  OperationModeConfig:=ChangeFileExt(ExtractFileName(ParamStr(0)),'.dat');
{$ENDIF}
end.
