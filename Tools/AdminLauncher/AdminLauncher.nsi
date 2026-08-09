Name "DFendX - launch program as admin helper"

VIAddVersionKey "ProductName" "DFendX - launch program as admin helper"
VIAddVersionKey "Comments" "DFendX is a Frontend for DOSBox"
VIAddVersionKey "CompanyName" "The DFendX Team"
VIAddVersionKey "LegalCopyright" "Licensed under the GPL v3"
VIAddVersionKey "FileDescription" "DFendX - launch program as admin helper"
VIProductVersion "1.0.0.0"
VIAddVersionKey "FileVersion" "1.0.0.0"

RequestExecutionLevel admin
SetCompressor /solid lzma

OutFile "AdminLauncher.exe"
Icon "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"

!include FileFunc.nsh
!insertmacro GetParameters
!insertmacro GetOptions

Function .onInit
  SetSilent silent
  SetAutoClose true

  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 /run= $2
  ${GetOptions} $R0 /dir= $1
  ${GetOptions} $R0 /driver= $3
FunctionEnd

Section "-InstallCodec"
  SectionIn RO

  StrLen $4 $3
  IntCmp $4 2 noEnv noEnv
  System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("SDL_VIDEODRIVER", "$3").r0'
  noEnv:
  
  SetOutPath $1
  Exec '$2'
SectionEnd