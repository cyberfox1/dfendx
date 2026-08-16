; NSI SCRIPT FOR DFENDX
; ============================================================

!include VersionSettings.nsi
!insertmacro VersionData
!define INST_FILENAME "Setup.exe"

!include CommonTools.nsi



; Register custom page definitions for different languages
; ============================================================

!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
ReserveFile "Languages\ioFileBrazilian_Portuguese.ini"
ReserveFile "Languages\ioFileCzech.ini"
ReserveFile "Languages\ioFileDanish.ini"
ReserveFile "Languages\ioFileDutch.ini"
ReserveFile "Languages\ioFileEnglish.ini"
ReserveFile "Languages\ioFileFrench.ini"
ReserveFile "Languages\ioFileGerman.ini"
ReserveFile "Languages\ioFileItalian.ini"
ReserveFile "Languages\ioFilePolish.ini"
ReserveFile "Languages\ioFileRussian.ini"
ReserveFile "Languages\ioFileSimplified_Chinese.ini"
ReserveFile "Languages\ioFileSpanish.ini"
ReserveFile "Languages\ioFileTraditional_Chinese.ini"
ReserveFile "Languages\ioFileTurkish.ini"

ReserveFile "Languages\ioFile2Brazilian_Portuguese.ini"
ReserveFile "Languages\ioFile2Czech.ini"
ReserveFile "Languages\ioFile2Danish.ini"
ReserveFile "Languages\ioFile2Dutch.ini"
ReserveFile "Languages\ioFile2English.ini"
ReserveFile "Languages\ioFile2French.ini"
ReserveFile "Languages\ioFile2German.ini"
ReserveFile "Languages\ioFile2Italian.ini"
ReserveFile "Languages\ioFile2Polish.ini"
ReserveFile "Languages\ioFile2Russian.ini"
ReserveFile "Languages\ioFile2Simplified_Chinese.ini"
ReserveFile "Languages\ioFile2Spanish.ini"
ReserveFile "Languages\ioFile2Traditional_Chinese.ini"
ReserveFile "Languages\ioFile2Turkish.ini"



; Settings for the modern user interface (MUI)
; ============================================================

Var FastInstallationMode

Function AbortIfFastMode
  IntCmp $FastInstallationMode 1 AbortPage ShowPage
  AbortPage:
  Abort
  ShowPage:
FunctionEnd

!insertmacro MUI_PAGE_WELCOME
; !insertmacro MUI_PAGE_LICENSE $(LANGNAME_License)
Page custom InstallMode
Page custom InstallType 
!define MUI_PAGE_CUSTOMFUNCTION_PRE AbortIfFastMode
!insertmacro MUI_PAGE_COMPONENTS
!define MUI_PAGE_CUSTOMFUNCTION_PRE AbortIfFastMode
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro UninstallerPages
!insertmacro LanguageSetup



; Definition of install sections
; ============================================================

!insertmacro CommonSections

Section "$(LANGNAME_DFendReloaded)" ID_DFend
  SectionIn RO
  
  SetDetailsPrint both
  DetailPrint "$(LANGNAME_InstallDFendReloaded)"
  SetDetailsPrint listonly
  SetOutPath "$INSTDIR"  
  SetDetailsPrint none
  
  ; Installation type
  ; ($InstallDataType=0 <=> Prg dir mode, $InstallDataType=1 <=> User dir mode; in user dir mode $DataInstDir will contain the data directory otherwise $INSTDIR)
  
  IntCmp $InstallDataType 1 UserDataDir
  strcpy $DataInstDir $INSTDIR
  Goto StartInstall
  UserDataDir:
  strcpy $DataInstDir "$PROFILE\DFendX"
  StartInstall:
  
  ; Store installation folder in registry if not portable installation
  
  IntCmp $InstallDataType 2 NoRegistryWhenUSBStickInstall
  WriteRegStr HKLM "Software\DFendX" "ProgramFolder" "$INSTDIR"
  WriteRegStr HKLM "Software\DFendX" "DataFolder" "$DataInstDir"
  NoRegistryWhenUSBStickInstall:
  
  ; Install main files

  SetOutPath "$INSTDIR"
  File "..\DFend.exe"
  ; PE-import + LoadLibrary / BASS_PluginLoad: next to DFend.exe
  File "staging\Bin\bass.dll"
  File "staging\Bin\bassflac.dll"
  File "staging\Bin\sqlite3.dll"
  File "..\LICENSE"
  File "..\CHANGES"
  
  SetOutPath "$INSTDIR\Bin"
  File "staging\Bin\mkdosfs.exe"
  File "staging\Bin\LicenseMTOOLS.txt"
  File "staging\Bin\oggenc2.exe"
  File "staging\Bin\libFLAC.dll"
  File "staging\Bin\LicenseComponents.txt"
  File "staging\Bin\Links.txt"
  File "staging\Bin\SearchLinks.txt"
  File "staging\Bin\7za.dll"
  File "staging\Bin\DelZip179.dll"
  File "staging\Bin\LicenseBASS.txt"
  File "staging\Bin\AdminLauncher.exe"
  File "staging\Bin\SetInstallerLanguage.exe"
  File "staging\Bin\dfxvalidator.exe"
  File "staging\Bin\config.com"

  SetOutPath "$INSTDIR\Lang"
  File "..\Lang\*.ini"
  File "..\Lang\*.chm"
  File "..\Lang\Readme_OperationMode.txt"

  SetOutPath "$INSTDIR\IconSets"
  File /r /x Thumbs.db "..\IconSets\*.*"
  Delete "$INSTDIR\IconSets\Modern\Thumbs.db"
  
  SetOutPath "$DataInstDir\Settings"
  File "staging\Bin\Cheats.xml"

  ; Remove legacy license/changelog locations (now only $INSTDIR\LICENSE and CHANGES)
  
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
  Delete "$INSTDIR\InstallVideoCodec.exe"
  Delete "$INSTDIR\7za.dll"
  Delete "$INSTDIR\DelZip179.dll"
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

  ; Install templates  
  
  IntCmp $InstallDataType 1 WriteNewUserDir
  
    SetOutPath "$DataInstDir\Capture\DOSBox DOS"
    File /nonfatal "..\NewUserData\Capture\DOSBox DOS\*.*"

    SetOutPath "$DataInstDir\Templates"
    File /nonfatal "..\NewUserData\Templates\*.prof"
	
    SetOutPath "$DataInstDir\AutoSetup"
    File /nonfatal "..\NewUserData\AutoSetup\*.prof"

    SetOutPath "$DataInstDir\IconLibrary"
    File /nonfatal "..\NewUserData\IconLibrary\*.*"
	
    SetOutPath "$DataInstDir\Settings"
    File /nonfatal "..\NewUserData\Icons.ini"
  
  Goto TemplateWritingFinish
  WriteNewUserDir:  

    SetOutPath "$INSTDIR\NewUserData\Capture\DOSBox DOS"
    File /nonfatal "..\NewUserData\Capture\DOSBox DOS\*.*"

    SetOutPath "$INSTDIR\NewUserData\Templates"
    File /nonfatal "..\NewUserData\Templates\*.prof"
	
    SetOutPath "$INSTDIR\NewUserData\AutoSetup"
    File /nonfatal "..\NewUserData\AutoSetup\*.prof"

    SetOutPath "$INSTDIR\NewUserData\IconLibrary"
    File /nonfatal "..\NewUserData\IconLibrary\*.*"
	
    SetOutPath "$INSTDIR\NewUserData"
    File /nonfatal "..\NewUserData\Icons.ini"

  TemplateWritingFinish:
  
  ; Write installation mode to DFend.dat
  
  ClearErrors
  FileOpen $0 $INSTDIR\DFend.dat w
  IfErrors InstTypeEnd
  IntCmp $InstallDataType 0 InstType0
  IntCmp $InstallDataType 1 InstType1
  FileWrite $0 "PORTABLEMODE"
  Goto InstTypeClose
  InstType0:
  FileWrite $0 "PRGDIRMODE"
  Goto InstTypeClose
  InstType1:
  FileWrite $0 "USERDIRMODE"
  InstTypeClose:
  FileClose $0
  InstTypeEnd:
  
  ; Create uninstaller and start menu entries
  
  IntCmp $InstallDataType 2 NoDFendStartMenuLinks
  
  SetDetailsPrint both
  DetailPrint "$(LANGNAME_InstallStartMenu)"
  SetDetailsPrint listonly
  SetShellVarContext all
  SetOutPath "$SMPROGRAMS"  
  SetDetailsPrint none  
  
  SetOutPath "$INSTDIR"
  WriteUninstaller "Uninstall.exe"
  
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\DFendX"
  CreateShortCut "$SMPROGRAMS\DFendX\$(LANGNAME_DFendReloaded).lnk" "$INSTDIR\DFend.exe" "" "$INSTDIR\DFend.exe"
  CreateShortCut "$SMPROGRAMS\DFendX\$(LANGNAME_Uninstall).lnk" "$INSTDIR\Uninstall.exe"
  CreateDirectory $DataInstDir\VirtualHD ; Has to be created before the start menu link is created otherwise the link will never work
  CreateShortCut "$SMPROGRAMS\DFendX\$(LANGNAME_GamesFolder).lnk" "$DataInstDir\VirtualHD\"
  CreateDirectory $DataInstDir\GameData ; Has to be created before the start menu link is created otherwise the link will never work
  CreateShortCut "$SMPROGRAMS\DFendX\$(LANGNAME_GameDataFolder).lnk" "$DataInstDir\GameData\"
  CreateDirectory $DataInstDir\Capture ; Has to be created before the start menu link is created otherwise the link will never work
  CreateShortCut "$SMPROGRAMS\DFendX\$(LANGNAME_CaptureFolder).lnk" "$DataInstDir\Capture\"  
  
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "DisplayName" "${PrgName} ($(LANGNAME_Deinstall))"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "UninstallString" '"$INSTDIR\Uninstall.exe"'  
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "DisplayIcon" "$INSTDIR\DFend.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "Publisher" "The DFendX Team"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "DisplayVersion" "${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}"
  WriteRegDWord HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "NoModify" 1
  WriteRegDWord HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX" "NoRepair" 1
  
  Call GameExplorerUninstall

  NoDFendStartMenuLinks:
SectionEnd



; Bundled DOSBox is no longer shipped. Users install DOSBox separately;
; DFend discovers it at first run (SearchDosBox). Uninstaller still
; removes any leftover $INSTDIR\DOSBox from older installs.
; FreeDOS / DOSZip components are no longer packaged.


Section "$(LANGNAME_DesktopShortcut)" ID_DesktopShortcut
  SetDetailsPrint both
  DetailPrint "$(LANGNAME_InstallDesktopShortcut)"
  SetDetailsPrint listonly
  SetShellVarContext all
  CreateShortCut "$DESKTOP\$(LANGNAME_DFendReloaded).lnk" "$INSTDIR\DFend.exe" "" "$INSTDIR\DFend.exe" 
SectionEnd



; Definition of NSIS functions
; ============================================================

!macro ExtractInstallOptionFiles
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileBrazilian_Portuguese.ini" "ioFileBrazilian_Portuguese.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileCzech.ini" "ioFileCzech.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileDanish.ini" "ioFileDanish.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileDutch.ini" "ioFileDutch.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileEnglish.ini" "ioFileEnglish.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileFrench.ini" "ioFileFrench.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileGerman.ini" "ioFileGerman.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileItalian.ini" "ioFileItalian.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFilePolish.ini" "ioFilePolish.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileRussian.ini" "ioFileRussian.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileSimplified_Chinese.ini" "ioFileSimplified_Chinese.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileSpanish.ini" "ioFileSpanish.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileTraditional_Chinese.ini" "ioFileTraditional_Chinese.ini"  
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFileTurkish.ini" "ioFileTurkish.ini"
 
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Brazilian_Portuguese.ini" "ioFile2Brazilian_Portuguese.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Czech.ini" "ioFile2Czech.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Danish.ini" "ioFile2Danish.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Dutch.ini" "ioFile2Dutch.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2English.ini" "ioFile2English.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2French.ini" "ioFile2French.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2German.ini" "ioFile2German.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Italian.ini" "ioFile2Italian.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Polish.ini" "ioFile2Polish.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Russian.ini" "ioFile2Russian.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Simplified_Chinese.ini" "ioFile2Simplified_Chinese.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Spanish.ini" "ioFile2Spanish.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Traditional_Chinese.ini" "ioFile2Traditional_Chinese.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "Languages\ioFile2Turkish.ini" "ioFile2Turkish.ini"
!macroend

!insertmacro CommonInstallerInit

Var FONT

!macro ActivateSection SectionID
  SectionGetFlags ${SectionID} $R0
  IntOp $R0 $R0 | 0x00000001
  SectionSetFlags ${SectionID} $R0
!macroend

!macro DeactivateSection SectionID
  SectionGetFlags ${SectionID} $R0
  IntOp $R0 $R0 & 0xFFFFFFFE
  SectionSetFlags ${SectionID} $R0
!macroend

Function InstallMode
  IntOp $FastInstallationMode 0 + 0
  IntCmp $AdminOK 0 InstallModePageFinish
  
  !insertmacro MUI_HEADER_TEXT $(PAGE2_TITLE) $(PAGE2_SUBTITLE)
  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG  "$(LANGNAME_ioFile2)"  
  
  !insertmacro MUI_INSTALLOPTIONS_READ $9 "$(LANGNAME_ioFile2)" "Field 1" "HWND"
  CreateFont $FONT "$(^Font)" "$(^FontSize)" "600"
  SendMessage $9 ${WM_SETFONT} $FONT 0
  
  !insertmacro MUI_INSTALLOPTIONS_READ $9 "$(LANGNAME_ioFile2)" "Field 5" "HWND"
  CreateFont $FONT "$(^Font)" "$(^FontSize)" "600"
  SendMessage $9 ${WM_SETFONT} $FONT 0  

  !insertmacro MUI_INSTALLOPTIONS_SHOW

  !insertmacro MUI_INSTALLOPTIONS_READ $9 "$(LANGNAME_ioFile2)" "Field 5" "State"
  IntCmp $9 1 CreateShortCutFile2On
  !insertmacro DeactivateSection ${ID_DesktopShortcut}
  Goto CreateShortCutFile2Done
  CreateShortCutFile2On:
  !insertmacro ActivateSection ${ID_DesktopShortcut}
  CreateShortCutFile2Done:

  !insertmacro MUI_INSTALLOPTIONS_READ $9 "$(LANGNAME_ioFile2)" "Field 1" "State"
  IntCmp $9 1 FastMode
  Goto InstallModePageFinish
  FastMode:  
  StrCpy $INSTDIR "$PROGRAMFILES\DFendX\"
  IntOp $InstallDataType 1 + 0
  IntOp $FastInstallationMode 1 + 0
  InstallModePageFinish:
FunctionEnd

Function InstallType
  IntCmp $FastInstallationMode 1 EndSel

  !insertmacro MUI_HEADER_TEXT $(PAGE_TITLE) $(PAGE_SUBTITLE)
  
  IntCmp $AdminOK 1 NoInstallrestrictions 
  !insertmacro MUI_INSTALLOPTIONS_WRITE "$(LANGNAME_ioFile)" "Field 1" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "$(LANGNAME_ioFile)" "Field 3" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "$(LANGNAME_ioFile)" "Field 3" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "$(LANGNAME_ioFile)" "Field 5" "State" "1"
  NoInstallrestrictions:
  
  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG  "$(LANGNAME_ioFile)"  
  
  !insertmacro MUI_INSTALLOPTIONS_READ $9 "$(LANGNAME_ioFile)" "Field 3" "HWND"
  CreateFont $FONT "$(^Font)" "$(^FontSize)" "600"
  SendMessage $9 ${WM_SETFONT} $FONT 0  
  
  !insertmacro MUI_INSTALLOPTIONS_SHOW

  !insertmacro MUI_INSTALLOPTIONS_READ $9 "$(LANGNAME_ioFile)" "Field 1" "State"
  IntCmp $9 0 Next1
  IntOp $InstallDataType 0 + 0
  Goto EndSel
  
  Next1:
  !insertmacro MUI_INSTALLOPTIONS_READ $9 "$(LANGNAME_ioFile)" "Field 3" "State"
  IntCmp $9 0 Next2
  IntOp $InstallDataType 1 + 0
  Goto EndSel  
  
  Next2:
  IntOp $InstallDataType 2 + 0
  SectionGetFlags ${ID_DesktopShortcut} $R0
  IntOp $R0 $R0 & 0xFFFFFFFE
  SectionSetFlags ${ID_DesktopShortcut} $R0    

  StrCpy $INSTDIR "$DESKTOP\DFendX\"
  
  EndSel:
FunctionEnd

Function .onSelChange
  IntCmp $InstallDataType 2 NoDesktopShortcut
  Goto End
  
  NoDesktopShortcut:  
  
  SectionGetFlags ${ID_DesktopShortcut} $R0
  IntOp $R0 $R0 & 0xFFFFFFFE
  SectionSetFlags ${ID_DesktopShortcut} $R0
	
  End:
FunctionEnd



; Link between install sections and descriptions
; ============================================================

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${ID_DFend} $(DESC_DFend)
  !insertmacro MUI_DESCRIPTION_TEXT ${ID_DesktopShortcut} $(DESC_DesktopShortcut)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

