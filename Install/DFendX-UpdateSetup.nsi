; NSI SCRIPT FOR DFENDX (UPDATE)
; ============================================================

!include VersionSettings.nsi
!insertmacro VersionData
!define INST_FILENAME "UpdateSetup.exe"
!define Update
!include CommonTools.nsi



; Settings for the modern user interface (MUI)
; ============================================================

!include FileFunc.nsh
!insertmacro GetParameters
!insertmacro GetOptions
!include WordFunc.nsh
!insertmacro VersionCompare
!include TextFunc.nsh
!insertmacro TrimNewLines

!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageIfAutoUpdate
!insertmacro MUI_PAGE_WELCOME
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageIfAutoUpdate
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageAndCloseIfAutoUpdate
!insertmacro MUI_PAGE_FINISH

!insertmacro UninstallerPages
!insertmacro LanguageSetup

Function SkipPageIfAutoUpdate
	${GetParameters} $R0
    ClearErrors
    ${GetOptions} $R0 /A $R0
    IfErrors +2 0
	Abort
FunctionEnd

Function SkipPageAndCloseIfAutoUpdate
	${GetParameters} $R0
    ClearErrors
    ${GetOptions} $R0 /A $R0
    IfErrors ShowFinishPage 0
    ; Silent/auto update (/A): skip finish page and restart the app.
    ExecShell "open" "$INSTDIR\DFend.exe"
	Abort
	ShowFinishPage:
FunctionEnd



; Definition of install sections
; ============================================================

!insertmacro CommonSections

Section "$(LANGNAME_DFendReloaded)" ID_DFend
  SectionIn RO
  
  SetDetailsPrint none
  
  ; Read installation type
  ; ($InstallDataType=0 <=> Prg dir mode, $InstallDataType=1 <=> User dir mode; in user dir mode $DataInstDir will contain the data directory otherwise $INSTDIR)
  ;
  ; Require a DFendX install (not classic D-Fend Reloaded):
  ;   DFend.dat, DFend.exe, Bin\dfxvalidator.exe, and validator exit 0 on DFend.exe.
  ;   Optional: if validator wrote $TEMP\dfxvalidator.version, refuse when that
  ;   installed PE version is newer than this update package.
  
  IfFileExists "$INSTDIR\DFend.dat" +3
  MessageBox MB_OK "$(LANGNAME_NoInstallationFound)"
  Quit

  IfFileExists "$INSTDIR\DFend.exe" +3
  MessageBox MB_OK "$(LANGNAME_NoInstallationFound)"
  Quit

  IfFileExists "$INSTDIR\Bin\dfxvalidator.exe" +3
  MessageBox MB_OK "$(LANGNAME_NotDFendXInstallation)"
  Quit

  Delete "$TEMP\dfxvalidator.version"
  ClearErrors
  ExecWait '"$INSTDIR\Bin\dfxvalidator.exe" "$INSTDIR\DFend.exe" "$TEMP\dfxvalidator.version"' $0
  IntCmp $0 0 DfxValidOk
  MessageBox MB_OK "$(LANGNAME_NotDFendXInstallation)"
  Quit

  DfxValidOk:
  ; Version file is optional — only used to block older updater on newer install.
  IfFileExists "$TEMP\dfxvalidator.version" 0 StartCheck
  FileOpen $0 "$TEMP\dfxvalidator.version" r
  IfErrors DfxVerSkip
  FileRead $0 $R8
  FileClose $0
  Delete "$TEMP\dfxvalidator.version"
  ${TrimNewLines} "$R8" $R8
  StrCmp $R8 "" DfxVerSkip
  ; VersionCompare: 0=equal, 1=first newer, 2=second newer
  ${VersionCompare} "$R8" "${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}.0" $0
  IntCmp $0 1 DfxTooNew
  Goto StartCheck

  DfxVerSkip:
  Delete "$TEMP\dfxvalidator.version"
  Goto StartCheck

  DfxTooNew:
  Delete "$TEMP\dfxvalidator.version"
  MessageBox MB_OK "$(LANGNAME_InstalledVersionNewer)"
  Quit

  StartCheck:  
  StrCpy $DataInstDir $INSTDIR  
  ClearErrors
  FileOpen $0 $INSTDIR\DFend.dat r
  IfErrors ReadInstTypeEnd
  FileRead $0 $1
  FileClose $0
  StrCmp $1 "USERDIRMODE" InstUserMode
  IntOp $InstallDataType 0 + 0
  Goto ReadInstTypeEnd
  InstUserMode:
  IntOp $InstallDataType 0 + 1
  strcpy $DataInstDir "$PROFILE\DFendX"
  ReadInstTypeEnd:
  
  ; Update main files
  
  SetDetailsPrint both
  DetailPrint "$(LANGNAME_UpdateDFendReloaded)"

  SetDetailsPrint listonly
  SetOutPath "$INSTDIR"
  SetDetailsPrint none  
  File "..\DFend.exe"
  ; PE-import + LoadLibrary / BASS_PluginLoad: next to DFend.exe
  File "staging\Bin\bass.dll"
  File "staging\Bin\bassflac.dll"
  File "staging\Bin\sqlite3.dll"
  File "..\LICENSE"
  File "..\CHANGES"
  
  SetDetailsPrint listonly
  SetOutPath "$INSTDIR\Bin"  
  SetDetailsPrint none  
  File "staging\Bin\oggenc2.exe"
  File "staging\Bin\libFLAC.dll"
  File "staging\Bin\mkdosfs.exe"
  File "staging\Bin\LicenseMTOOLS.txt"
  File "staging\Bin\LicenseComponents.txt"
  File "staging\Bin\Links.txt"
  File "staging\Bin\SearchLinks.txt"
  File "staging\Bin\7za.dll"
  File "staging\Bin\DelZip179.dll"
  File "staging\Bin\LicenseBASS.txt"
  File "staging\Bin\AdminLauncher.exe"
  File "staging\Bin\SetInstallerLanguage.exe"
  File "staging\Bin\dfxvalidator.exe"
  
  SetDetailsPrint listonly
  SetOutPath "$INSTDIR\Lang"
  SetDetailsPrint none  
  File "..\Lang\*.ini"
  File "..\Lang\*.chm"
  File "..\Lang\Readme_OperationMode.txt"

  SetDetailsPrint listonly
  SetOutPath "$INSTDIR\IconSets"
  SetDetailsPrint none  
  File /r /x Thumbs.db "..\IconSets\*.*"
  Delete "$INSTDIR\IconSets\Modern\Thumbs.db"
  
  SetDetailsPrint listonly
  SetOutPath "$DataInstDir\Settings"
  SetDetailsPrint none
  File "staging\Bin\Cheats.xml"
  
  ; Remove legacy license/changelog paths (now only $INSTDIR\LICENSE and CHANGES)
   
  Delete "$INSTDIR\oggenc2.exe"
  Delete "$INSTDIR\LicenseComponents.txt"
  Delete "$INSTDIR\License.txt"
  Delete "$INSTDIR\Bin\License.txt"
  IntCmp $InstallDataType 0 KeepSettingsFilesIfPrgDirIsUserDir  
  Delete "$INSTDIR\Links.txt"
  Delete "$INSTDIR\SearchLinks.txt"
  KeepSettingsFilesIfPrgDirIsUserDir:
  Delete "$INSTDIR\ChangeLog.txt"
  Delete "$INSTDIR\Changelog.txt"
  Delete "$INSTDIR\Bin\ChangeLog.txt"
  Delete "$INSTDIR\Bin\Changelog.txt"
  Delete "$INSTDIR\DFendX DataInstaller.nsi"
  Delete "$INSTDIR\Bin\DFendX DataInstaller.nsi"
  Delete "$INSTDIR\AdminLauncher.exe"
  Delete "$INSTDIR\SetInstallerLanguage.exe"
  Delete "$INSTDIR\UpdateCheck.exe"
  Delete "$INSTDIR\7za.dll"
  Delete "$INSTDIR\DelZip179.dll"
  Delete "$INSTDIR\InstallVideoCodec.exe"
  Delete "$INSTDIR\Bin\UpdateCheck.exe"
  Delete "$INSTDIR\Bin\InstallVideoCodec.exe"
  Delete "$INSTDIR\mkdosfs.exe"
  Delete "$INSTDIR\LicenseMTOOLS.txt"
  Delete "$INSTDIR\mediaplr.dll"
  Delete "$INSTDIR\Bin\mediaplr.dll"
  Delete "$INSTDIR\Bin\bass.dll"
  Delete "$INSTDIR\Bin\bassflac.dll"
  Delete "$INSTDIR\Bin\sqlite3.dll"
  Delete "$INSTDIR\LicenseBASS.txt"
  Delete "$INSTDIR\Readme_OperationMode.txt"
  Delete "$INSTDIR\DFendGameExplorerData.dll"
  Delete "$INSTDIR\Bin\DFendGameExplorerData.dll"
  ; Legacy DataReader.xml (unused MobyGames scrape config; no longer shipped)
  Delete "$DataInstDir\Settings\DataReader.xml"
  Delete "$INSTDIR\Settings\DataReader.xml"
  Delete "$INSTDIR\NewUserData\DataReader.xml"
  
  ; Update templates

  IntCmp $InstallDataType 1 WriteNewUserDir
    ; Prg dir mode -> Update files directly

	SetDetailsPrint listonly
    SetOutPath "$DataInstDir\AutoSetup"
	SetDetailsPrint none
    File /nonfatal "..\NewUserData\AutoSetup\*.prof"	
	
    SetOutPath "$DataInstDir\Capture\DOSBox DOS"
    File /nonfatal "..\NewUserData\Capture\DOSBox DOS\*.*"

    SetOutPath "$DataInstDir\Templates"
    File /nonfatal "..\NewUserData\Templates\*.prof"

    SetOutPath "$DataInstDir\IconLibrary"
    File /nonfatal "..\NewUserData\IconLibrary\*.*"
	
    SetOutPath "$DataInstDir\Settings"
    File /nonfatal "..\NewUserData\Icons.ini"

  Goto TemplateWritingFinish
  WriteNewUserDir:  
    ; User dir mode -> Update files in NewUserData folder

	SetDetailsPrint listonly
    SetOutPath "$INSTDIR\NewUserData\AutoSetup"
	SetDetailsPrint none
    File /nonfatal "..\NewUserData\AutoSetup\*.prof"

    SetOutPath "$INSTDIR\NewUserData\Capture\DOSBox DOS"
    File /nonfatal "..\NewUserData\Capture\DOSBox DOS\*.*"

    SetOutPath "$INSTDIR\NewUserData\Templates"
    File /nonfatal "..\NewUserData\Templates\*.prof"

    SetOutPath "$INSTDIR\NewUserData\IconLibrary"
    File /nonfatal "..\NewUserData\IconLibrary\*.*"
	
    SetOutPath "$INSTDIR\NewUserData"
    File /nonfatal "..\NewUserData\Icons.ini"
	
  TemplateWritingFinish:
  
  ; FreeDOS / DOSZip are no longer packaged.

  IntCmp $InstallDataType 2 NoUninstallerUpdate
  
  ; Update uninstaller
  
  SetDetailsPrint both
  DetailPrint "$(LANGNAME_UpdateUninstaller)"
  SetDetailsPrint listonly
  SetOutPath "$INSTDIR"
  SetDetailsPrint none
  
  WriteUninstaller "Uninstall.exe"
  SetShellVarContext all
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "DisplayVersion" "${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}"
  
  Call GameExplorerUninstall
  
  NoUninstallerUpdate:

  ; Bundled DOSBox is no longer shipped or refreshed. Leftover
  ; $INSTDIR\DOSBox from older installs is left alone until uninstall.
SectionEnd



; Definition of NSIS functions
; ============================================================

!macro ExtractInstallOptionFiles
!macroend

!insertmacro CommonInstallerInit