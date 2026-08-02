; NSI SCRIPT TOOLS FOR DFENDX
; ============================================================

; Define VER_MAYOR, VER_MINOR1, VER_MINOR2 and INST_FILENAME before including this file !
; Define "Update" (without content) if update installer.



; Include used librarys
; ============================================================

; NSIS 3 defaults to Unicode. Keep ANSI for now: Languages\*.nsi and
; ioFile*.ini are still legacy codepage sources. Unicode is a follow-up.
Unicode false

!addplugindir ".\Plugins"
!include "MUI.nsh"
!include "Sections.nsh"
!include "WinMessages.nsh"
!include "Plugins\GameExplorer.nsh"



; Define program name and version information
; ============================================================

!define PrgName "DFendX ${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}"
OutFile "DFendX-${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}-${INST_FILENAME}"

VIAddVersionKey "ProductName" "DFendX"
VIAddVersionKey "ProductVersion" "${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}"
VIAddVersionKey "Comments" "${PrgName} is a Frontend for DOSBox"
VIAddVersionKey "CompanyName" "The DFendX Team"
VIAddVersionKey "LegalCopyright" "Licensed under the GPL v3"
!ifdef Update
  VIAddVersionKey "FileDescription" "Update installer for ${PrgName}"
!else
  VIAddVersionKey "FileDescription" "Installer for ${PrgName}"
!endif
VIAddVersionKey "FileVersion" "${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}"
VIProductVersion "${VER_MAYOR}.${VER_MINOR1}.${VER_MINOR2}.0"



; Global variables
; ============================================================

Var DataInstDir
Var InstallDataType
Var AdminOK
Var PrgNameAddOn
Var GEGUID



; Initial settings
; ============================================================

Name "${PrgName}"
BrandingText "${PrgName} $PrgNameAddOn"

SetCompressor /solid lzma
; Do NOT UPX-pack the NSIS exehead. UPX 3.x/5.x on modern NSIS 3 Unicode
; stubs commonly produces an installer that exits immediately with no UI
; (exit code 2). Payload packing of DFend.exe below is separate and OK.
; !packhdr "$%TEMP%\exehead.tmp" 'upx-prefer-path.bat "$%TEMP%\exehead.tmp"'

; Native elevation (Vista+): OS shows UAC from the EXE manifest.
; XP ignores this; UserInfo in .onInit still gates Program Files mode.
RequestExecutionLevel admin
XPStyle on

InstallDir "$PROGRAMFILES\DFendX\"
InstallDirRegKey HKLM "Software\DFendX" "ProgramFolder"

!insertmacro MUI_RESERVEFILE_LANGDLL

ShowInstDetails show
ShowUninstDetails nevershow



; Pack program file (PATH upx first; ignore non-zero if already packed)
; ============================================================

!system 'cmd /c "upx-prefer-path.bat ..\DFend.exe & exit /b 0"'
!system 'cmd /c "upx-prefer-path.bat ..\Bin\oggenc2.exe & exit /b 0"'



; Settings for the modern user interface (MUI)
; ============================================================

!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\win.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "Images\1035.bmp"
!ifdef Update
  !define MUI_WELCOMEFINISHPAGE_BITMAP "Images\DFendX - Update Installer.bmp"
!else
  !define MUI_WELCOMEFINISHPAGE_BITMAP "Images\DFendX - Installer.bmp"
!endif
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "Images\27.bmp"

!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE_3LINES
!ifdef Update
  !define MUI_WELCOMEPAGE_TEXT "$(LANGNAME_WelcomeTextUpdate)"
!else
  !define MUI_WELCOMEPAGE_TEXT "$(LANGNAME_WelcomeText)"
  !define MUI_LICENSEPAGE_HEADER_TEXT "$(LANGNAME_LICENSE_TITLE)"
  !define MUI_LICENSEPAGE_HEADER_SUBTEXT "$(LANGNAME_LICENSE_SUBTITLE)"
  !define MUI_LICENSEPAGE_TEXT_TOP "$(LANGNAME_LICENSE_TOP)"
  !define MUI_LICENSEPAGE_TEXT_BOTTOM "$(LANGNAME_LICENSE_BOTTOM)"
  !define MUI_LICENSEPAGE_BUTTON "$(LANGNAME_Next) >"
  !define MUI_COMPONENTSPAGE_SMALLDESC
!endif

!define MUI_DIRECTORYPAGE_TEXT_TOP "$(LANGNAME_DIRECTORYPAGE_TEXT_TOP)"

!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_UNABORTWARNING

!define MUI_LANGDLL_REGISTRY_ROOT "HKLM" 
!define MUI_LANGDLL_REGISTRY_KEY "Software\DFendX" 
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

!macro UninstallerPages
  !define MUI_WELCOMEPAGE_TITLE_3LINES
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !define MUI_FINISHPAGE_TITLE_3LINES
  !insertmacro MUI_UNPAGE_FINISH
!macroend



; Main settings for different languages
; ============================================================

!macro LanguageSetup
  !insertmacro MUI_LANGUAGE "English"

  !insertmacro MUI_LANGUAGE "PortugueseBR"
  !insertmacro MUI_LANGUAGE "Czech"
  !insertmacro MUI_LANGUAGE "Danish"
  !insertmacro MUI_LANGUAGE "Dutch"
  !insertmacro MUI_LANGUAGE "French"
  !insertmacro MUI_LANGUAGE "German"
  !insertmacro MUI_LANGUAGE "Italian"
  !insertmacro MUI_LANGUAGE "Polish"
  !insertmacro MUI_LANGUAGE "Russian"
  !insertmacro MUI_LANGUAGE "SimpChinese"
  !insertmacro MUI_LANGUAGE "Spanish"
  !insertmacro MUI_LANGUAGE "TradChinese"
  !insertmacro MUI_LANGUAGE "Turkish"

  !include "Languages\DFendX-Setup-Lang-BrazilianPortuguese.nsi"
  !include "Languages\DFendX-Setup-Lang-Czech.nsi"
  !include "Languages\DFendX-Setup-Lang-Danish.nsi"
  !include "Languages\DFendX-Setup-Lang-Dutch.nsi"
  !include "Languages\DFendX-Setup-Lang-English.nsi"
  !include "Languages\DFendX-Setup-Lang-French.nsi"
  !include "Languages\DFendX-Setup-Lang-German.nsi"
  !include "Languages\DFendX-Setup-Lang-Italian.nsi"
  !include "Languages\DFendX-Setup-Lang-Polish.nsi"
  !include "Languages\DFendX-Setup-Lang-Russian.nsi"
  !include "Languages\DFendX-Setup-Lang-Simplified_Chinese.nsi"
  !include "Languages\DFendX-Setup-Lang-Spanish.nsi"
  !include "Languages\DFendX-Setup-Lang-Traditional_Chinese.nsi"
  !include "Languages\DFendX-Setup-Lang-Turkish.nsi"
!macroend



; Definition of install sections
; ============================================================

Function GameExplorerUninstall
  ClearErrors
  ReadRegStr $GEGUID HKLM "Software\DFendX" "GameExplorerGUID"	
  IfErrors NoGameExplorerUninstall

  ; Remove regular way
  SetShellVarContext all
  ${GameExplorer_RemoveGame} $GEGUID  
  ClearErrors

  ; Remove via deleting registry keys
  StrCpy $0 0
  CheckNextGameExplorerKey:
  EnumRegKey $1 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\GameUX\Games\" $0
  StrCmp $1 "" NoGameExplorerUninstall
  ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\GameUX\Games\$1" "Title"
  StrCmp $2 "DFendX" 0 DoNotDeleteGameExplorerRegKey
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\GameUX\Games\$1"
  Goto CheckNextGameExplorerKey
  DoNotDeleteGameExplorerRegKey:
  IntOp $0 $0 + 1
  Goto CheckNextGameExplorerKey
	
  NoGameExplorerUninstall:
FunctionEnd

Function un.GameExplorerUninstall
  ClearErrors
  ReadRegStr $GEGUID HKLM "Software\DFendX" "GameExplorerGUID"	
  IfErrors unNoGameExplorerUninstall
	
  ; Remove regular way
  SetShellVarContext all
  ${GameExplorer_RemoveGame} $GEGUID  
  ClearErrors

  ; Remove via deleting registry keys
  StrCpy $0 0
  unCheckNextGameExplorerKey:
  EnumRegKey $1 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\GameUX\Games\" $0
  StrCmp $1 "" unNoGameExplorerUninstall
  ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\GameUX\Games\$1" "Title"
  StrCmp $2 "DFendX" 0 unDoNotDeleteGameExplorerRegKey
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\GameUX\Games\$1"
  Goto unCheckNextGameExplorerKey
  unDoNotDeleteGameExplorerRegKey:
  IntOp $0 $0 + 1
  Goto unCheckNextGameExplorerKey
	
  unNoGameExplorerUninstall:
FunctionEnd

!macro CommonSections
  !define TO_MS 2000
  
  # Not working well
  #Section -AllowCancel
  #  SectionIn RO
  #  GetDlgItem $0 $HWNDPARENT 2
  #  EnableWindow $0 1
  #SectionEnd

  Section "-CloseDFend"
    SectionIn RO	

    Push $0
    FindWindow $0 'TDFendReloadedMainform' ''
    IntCmp $0 0 DoneCloseDFend
    SendMessage $0 ${WM_CLOSE} 0 0 /TIMEOUT=${TO_MS}
    Sleep 2000
    DoneCloseDFend:
    Pop $0
  SectionEnd

  Section "Uninstall"
    SetDetailsPrint none
  
    Push $0
    FindWindow $0 'TDFendReloadedMainform' ''
    IntCmp $0 0 DoneCloseDFendUninstall
    SendMessage $0 ${WM_CLOSE} 0 0 /TIMEOUT=${TO_MS}
    Sleep 2000
    DoneCloseDFendUninstall:
    Pop $0  
  
    ClearErrors
    FileOpen $0 $INSTDIR\DFend.dat r
    IfErrors UninstallUserDataEnd
    FileRead $0 $1
    FileClose $0
    StrCmp $1 "USERDIRMODE" AskForUserDataDel
    Goto UninstallUserDataEnd
  
    AskForUserDataDel:
    ReadRegStr $DataInstDir HKLM "Software\DFendX" "DataFolder"
    StrCmp $DataInstDir "" UninstallUserDataEnd
	
	IfFileExists $DataInstDir 0 UninstallUserDataEnd
    MessageBox MB_YESNO "$(LANGNAME_ConfirmDelUserData)" IDYES DelUserData IDNO UninstallUserDataEnd
    DelUserData:  
    RmDir /r $DataInstDir  
    UninstallUserDataEnd:
	
    Delete $INSTDIR\mediaplr.dll
    Delete $INSTDIR\Bin\mediaplr.dll
    Delete $INSTDIR\bass.dll
    Delete $INSTDIR\bassflac.dll
    Delete $INSTDIR\sqlite3.dll
    Delete $INSTDIR\Bin\bass.dll
    Delete $INSTDIR\Bin\bassflac.dll
    Delete $INSTDIR\Bin\sqlite3.dll
    RmDir /r $INSTDIR\Bin
	RmDir /r $INSTDIR\DOSBox
	RmDir /r $INSTDIR\IconSets
	RmDir /r $INSTDIR\Lang
	RmDir /r $INSTDIR\NewUserData
	Delete $INSTDIR\DFend.dat
	Delete $INSTDIR\DFend.exe
	Delete $INSTDIR\Readme_OperationMode.txt
	Delete $INSTDIR\Uninstall.exe
    Delete $INSTDIR\ConfOpt.dat
    Delete $INSTDIR\ScummVM.dat
    Delete $INSTDIR\History.dat
    Delete $INSTDIR\Icons.ini  
    Delete $INSTDIR\DFend.ini
    Delete $INSTDIR\Links.txt;
    Delete $INSTDIR\SearchLinks.txt
    Delete "$INSTDIR\DFendX DataInstaller.nsi"
	
    Push "$INSTDIR"
    Call un.isEmptyDir
    Pop $0
    StrCmp $0 1 RemoveInstDir
	MessageBox MB_YESNO "$(LANGNAME_ConfirmDelPrgDir)" IDYES RemoveInstDir IDNO RemoveInstDirDone
	RemoveInstDir:
	RmDir /r $INSTDIR
	RemoveInstDirDone:
  
    StrCmp $1 "PORTABLEMODE" NoUninstallFromStartMenu
	
    Call un.GameExplorerUninstall

	SetShellVarContext all
    RmDir /r "$SMPROGRAMS\DFendX"
    Delete "$DESKTOP\DFendX.lnk"
    SetShellVarContext current
    RmDir /r "$SMPROGRAMS\DFendX"
    Delete "$DESKTOP\DFendX.lnk"
    DeleteRegKey HKLM "${MUI_LANGDLL_REGISTRY_KEY}"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DFendX"
    
	NoUninstallFromStartMenu:
	
  SectionEnd
  
!macroend

!macro AddToGamesExplorer
  SetShellVarContext all
  IfFileExists "$APPDATA\Microsoft\Windows\GameExplorer\*.*" 0 AddToGamesExplorerDone
  ClearErrors
  Call GameExplorerUninstall ; Remove old DFendX Game Explorer records
  StrCpy $GEGUID "{C4CC218B-7E0A-4616-9ECB-500221826266}"  
  WriteRegStr HKLM "Software\DFendX" "GameExplorerGUID" "$GEGUID"
  ClearErrors
  ${GameExplorer_AddGame} all $INSTDIR\Bin\DFendGameExplorerData.dll $INSTDIR $INSTDIR\DFend.exe $GEGUID
  AddToGamesExplorerDone:
!macroend



; Definition of NSIS functions
; ============================================================

; Init/uninit: native RequestExecutionLevel admin + UserInfo check.
; $AdminOK gates Program Files UI vs portable-only when the process
; is not actually admin (XP limited user, elevation disabled + non-admin).
!macro CommonInstallerInit
  Function .onInit
    !ifdef Update
      StrCpy $PrgNameAddOn "UPDATE"
    !else
      StrCpy $PrgNameAddOn ""
    !endif

    ; Built-in plugin; works XP through modern Windows.
    UserInfo::GetAccountType
    Pop $0
    StrCmp $0 "Admin" InitAdminOK
    StrCmp $0 "Power" InitAdminOK
    IntOp $AdminOK 0 + 0
    Goto InitAdminDone
    InitAdminOK:
    IntOp $AdminOK 1 + 0
    InitAdminDone:

    !define MUI_LANGDLL_ALLLANGUAGES
    !insertmacro MUI_LANGDLL_DISPLAY
    !insertmacro ExtractInstallOptionFiles

    IntCmp $AdminOK 1 InitReturn
    !ifdef Update
      MessageBox MB_OK|MB_ICONEXCLAMATION "$(LANGNAME_NeedAdminRightsUpdate)"
    !else
      MessageBox MB_OK|MB_ICONEXCLAMATION "$(LANGNAME_NeedAdminRights)"
    !endif

    InitReturn:
    !insertmacro BetaWarning
  FunctionEnd

  Function un.onInit
    StrCpy $PrgNameAddOn ""

    UserInfo::GetAccountType
    Pop $0
    StrCmp $0 "Admin" UnInitAdminOK
    StrCmp $0 "Power" UnInitAdminOK
    MessageBox MB_OK|MB_ICONSTOP "$(LANGNAME_NeedAdminRightsUpdate)"
    Abort
    UnInitAdminOK:
    !insertmacro MUI_UNGETLANGUAGE
  FunctionEnd
!macroend



; Check for not installing DFR directly into the program folder
; ============================================================

Function .onVerifyInstDir
  GetFullPathName $0 $INSTDIR
  
  GetFullPathName $1 $PROGRAMFILES
  StrCmp $0 $1 +1 DirCheck2
  Abort
  
  DirCheck2:
  GetFullPathName $1 $WINDIR
  StrCmp $0 $1 +1 DirCheckOK
  Abort
  
  DirCheckOK:
FunctionEnd



; Check if directory is empty
; ============================================================
Function un.isEmptyDir
  # Stack ->                    # Stack: <directory>
  Exch $0                       # Stack: $0
  Push $1                       # Stack: $1, $0
  FindFirst $0 $1 "$0\*.*"
  strcmp $1 "." 0 _notempty
    FindNext $0 $1
    strcmp $1 ".." 0 _notempty
      ClearErrors
      FindNext $0 $1
      IfErrors 0 _notempty
        FindClose $0
        Pop $1                  # Stack: $0
        StrCpy $0 1
        Exch $0                 # Stack: 1 (true)
        goto _end
     _notempty:
       FindClose $0
       Pop $1                   # Stack: $0
       StrCpy $0 0
       Exch $0                  # Stack: 0 (false)
  _end:
FunctionEnd