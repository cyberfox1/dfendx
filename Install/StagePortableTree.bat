@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Stage a portable-like DFendX tree for BuildZips (no NSIS GUI).
REM Layout mirrors DFendX-Setup.nsi InstallDataType=2 (PORTABLEMODE).
REM Destination (required for BuildZips): first argument.
REM   StagePortableTree.bat "G:\...\Install\stagingportable"
REM If omitted: DFENDX_PORTABLE_ROOT, else %~dp0stagingportable
REM NOTE: Never end a quoted path with a backslash (breaks cmd parenthesis parsing).

set "DEST=%~1"
if "%DEST%"=="" set "DEST=%DFENDX_PORTABLE_ROOT%"
if "%DEST%"=="" set "DEST=%~dp0stagingportable"
if "%DEST:~-1%x"=="\x" set "DEST=%DEST:~0,-1%"

if not exist "..\DFend.exe" (
  echo ERROR: ..\DFend.exe not found. Build the app in RAD first ^(Src\DFend.dproj -^> repo root^).
  exit /b 1
)

echo Staging portable tree to:
echo   %DEST%

if exist "%DEST%" (
  echo Removing existing tree...
  rd /s /q "%DEST%"
)
mkdir "%DEST%" 2>nul
mkdir "%DEST%\Bin" 2>nul
mkdir "%DEST%\Lang" 2>nul
mkdir "%DEST%\IconSets" 2>nul
mkdir "%DEST%\VirtualHD" 2>nul
mkdir "%DEST%\GameData" 2>nul
mkdir "%DEST%\Capture" 2>nul
mkdir "%DEST%\Confs" 2>nul
mkdir "%DEST%\Templates" 2>nul
mkdir "%DEST%\AutoSetup" 2>nul
mkdir "%DEST%\IconLibrary" 2>nul
mkdir "%DEST%\Settings" 2>nul

copy /y "..\DFend.exe" "%DEST%" >nul
if errorlevel 1 exit /b 1
REM PE-import + BASS/sqlite next to DFend.exe (from Install\staging\Bin)
set "STBIN=%~dp0staging\Bin"
if not exist "%STBIN%\bass.dll" (
  echo ERROR: missing %STBIN%\bass.dll
  exit /b 1
)
copy /y "%STBIN%\bass.dll" "%DEST%" >nul
if errorlevel 1 exit /b 1
if not exist "%STBIN%\bassflac.dll" (
  echo ERROR: missing %STBIN%\bassflac.dll
  exit /b 1
)
copy /y "%STBIN%\bassflac.dll" "%DEST%" >nul
if errorlevel 1 exit /b 1
call "%~dp0EnsureSqlite3Dll.bat"
if errorlevel 1 exit /b 1
if not exist "%STBIN%\sqlite3.dll" (
  echo ERROR: missing %STBIN%\sqlite3.dll
  exit /b 1
)
copy /y "%STBIN%\sqlite3.dll" "%DEST%" >nul
if errorlevel 1 exit /b 1

REM Single project LICENSE + CHANGES at tree root
if not exist "..\LICENSE" (
  echo ERROR: missing ..\LICENSE
  exit /b 1
)
copy /y "..\LICENSE" "%DEST%" >nul
if errorlevel 1 exit /b 1
if not exist "..\CHANGES" (
  echo ERROR: missing ..\CHANGES
  exit /b 1
)
copy /y "..\CHANGES" "%DEST%" >nul
if errorlevel 1 exit /b 1

REM Bin: same explicit list as Setup
call :CopyBin "mkdosfs.exe" || exit /b 1
call :CopyBin "LicenseMTOOLS.txt" || exit /b 1
call :CopyBin "oggenc2.exe" || exit /b 1
call :CopyBin "libFLAC.dll" || exit /b 1

call :CopyBin "LicenseComponents.txt" || exit /b 1
call :CopyBin "Links.txt" || exit /b 1
call :CopyBin "SearchLinks.txt" || exit /b 1
call :CopyBin "7za.dll" || exit /b 1
call :CopyBin "DelZip179.dll" || exit /b 1
call :CopyBin "LicenseBASS.txt" || exit /b 1
call :CopyBin "AdminLauncher.exe" || exit /b 1
call :CopyBin "SetInstallerLanguage.exe" || exit /b 1
call :CopyBin "dfxvalidator.exe" || exit /b 1

REM Working-copy language tree (same as Setup File "..\Lang\*.ini" / "*.chm").
dir /b "..\Lang\*.ini" >nul 2>&1
if errorlevel 1 (
  echo ERROR: missing ..\Lang\*.ini
  exit /b 1
)
dir /b "..\Lang\*.chm" >nul 2>&1
if errorlevel 1 (
  echo ERROR: missing ..\Lang\*.chm ^(run BuildHelp.bat first^)
  exit /b 1
)
xcopy /y /q "..\Lang\*.ini" "%DEST%\Lang" >nul
if errorlevel 1 (
  echo ERROR: failed to copy ..\Lang\*.ini
  exit /b 1
)
xcopy /y /q "..\Lang\*.chm" "%DEST%\Lang" >nul
if errorlevel 1 (
  echo ERROR: failed to copy ..\Lang\*.chm
  exit /b 1
)
dir /b "%DEST%\Lang\*.ini" >nul 2>&1
if errorlevel 1 (
  echo ERROR: staged tree has no Lang\*.ini
  exit /b 1
)
dir /b "%DEST%\Lang\*.chm" >nul 2>&1
if errorlevel 1 (
  echo ERROR: staged tree has no Lang\*.chm
  exit /b 1
)
if exist "..\Lang\Readme_OperationMode.txt" copy /y "..\Lang\Readme_OperationMode.txt" "%DEST%\Lang" >nul

REM IconSets: same tree as Setup; strip Thumbs.db
xcopy /y /e /q /i "..\IconSets" "%DEST%\IconSets" >nul
if exist "%DEST%\IconSets\Modern\Thumbs.db" del /q "%DEST%\IconSets\Modern\Thumbs.db" >nul 2>nul
del /s /q "%DEST%\IconSets\Thumbs.db" >nul 2>nul

REM DOSBox is not bundled; install separately. App discovers path at first run.

if exist "..\NewUserData\Templates" xcopy /y /q /i "..\NewUserData\Templates\*.prof" "%DEST%\Templates" >nul
if exist "..\NewUserData\AutoSetup" xcopy /y /q /i "..\NewUserData\AutoSetup\*.prof" "%DEST%\AutoSetup" >nul
if exist "..\NewUserData\IconLibrary" xcopy /y /e /q /i "..\NewUserData\IconLibrary" "%DEST%\IconLibrary" >nul
if exist "..\NewUserData\Icons.ini" copy /y "..\NewUserData\Icons.ini" "%DEST%\Settings" >nul
REM Cheats.xml only under Settings
if exist "%STBIN%\Cheats.xml" copy /y "%STBIN%\Cheats.xml" "%DEST%\Settings" >nul
if exist "..\NewUserData\Capture" xcopy /y /e /q /i "..\NewUserData\Capture" "%DEST%\Capture" >nul
if exist "..\NewUserData\DOSZIP" xcopy /y /e /q /i "..\NewUserData\DOSZIP" "%DEST%\VirtualHD\DOSZIP" >nul
if exist "..\NewUserData\FREEDOS" xcopy /y /e /q /i "..\NewUserData\FREEDOS" "%DEST%\VirtualHD\FREEDOS" >nul
REM Legacy DataReader.xml no longer shipped; strip if left from older stage/tree
if exist "%DEST%\Settings\DataReader.xml" del /q "%DEST%\Settings\DataReader.xml" >nul 2>nul
if exist "%DEST%\NewUserData\DataReader.xml" del /q "%DEST%\NewUserData\DataReader.xml" >nul 2>nul

REM Portable operation mode marker (same as Setup InstallDataType=2)
> "%DEST%\DFend.dat" echo PORTABLEMODE

echo.
echo Staged OK: %DEST%
echo DFend.dat = PORTABLEMODE
echo Bin list matches Setup ^(no Bin lang leftovers^)
echo Next: run BuildZips^(x86^).bat or BuildZips^(x64^).bat
exit /b 0

:CopyBin
if not exist "%STBIN%\%~1" (
  echo ERROR: missing %STBIN%\%~1
  exit /b 1
)
copy /y "%STBIN%\%~1" "%DEST%\Bin" >nul
if errorlevel 1 (
  echo ERROR: failed to copy %STBIN%\%~1
  exit /b 1
)
exit /b 0
