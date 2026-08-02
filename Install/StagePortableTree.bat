@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Stage a portable-like DFendX tree for BuildZips (no NSIS GUI).
REM Layout mirrors DFendX-Setup.nsi InstallDataType=2 (PORTABLEMODE):
REM   - same core folders and product files
REM   - no DFendGameExplorerData.dll (Setup skips it for portable)
REM   - Bin is an explicit file list (not full xcopy of repo Bin\)
REM   - Cheats.xml only under Settings\ (not left in Bin\)
REM Destination (required for BuildZips): first argument.
REM   StagePortableTree.bat "G:\...\Install\stagingportable"
REM If omitted: DFENDX_PORTABLE_ROOT, else %~dp0stagingportable
REM BuildZips always passes Install\stagingportable.

set "DEST=%~1"
if "%DEST%"=="" set "DEST=%DFENDX_PORTABLE_ROOT%"
if "%DEST%"=="" set "DEST=%~dp0stagingportable"
if "%DEST:~-1%"=="\" set "DEST=%DEST:~0,-1%"

if not exist "..\DFend.exe" (
  echo ERROR: ..\DFend.exe not found. Build the app in RAD first.
  exit /b 1
)

echo Staging portable tree to:
echo   %DEST%

if exist "%DEST%\" (
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

copy /y "..\DFend.exe" "%DEST%\" >nul
if errorlevel 1 exit /b 1
REM PE-import + BASS plugins: next to DFend.exe (source is Bin\)
if not exist "..\Bin\bass.dll" (
  echo ERROR: missing ..\Bin\bass.dll
  exit /b 1
)
copy /y "..\Bin\bass.dll" "%DEST%\" >nul
if errorlevel 1 exit /b 1
if not exist "..\Bin\bassflac.dll" (
  echo ERROR: missing ..\Bin\bassflac.dll
  exit /b 1
)
copy /y "..\Bin\bassflac.dll" "%DEST%\" >nul
if errorlevel 1 exit /b 1
REM FireDAC SQLite vendor lib: next to DFend.exe (same as bass)
call "%~dp0EnsureSqlite3Dll.bat"
if errorlevel 1 exit /b 1
if not exist "..\Bin\sqlite3.dll" (
  echo ERROR: missing ..\Bin\sqlite3.dll
  exit /b 1
)
copy /y "..\Bin\sqlite3.dll" "%DEST%\" >nul
if errorlevel 1 exit /b 1

REM Bin: same explicit list as Setup (portable omits DFendGameExplorerData.dll)
call :CopyBin "mkdosfs.exe" || exit /b 1
call :CopyBin "oggenc2.exe" || exit /b 1
call :CopyBin "License.txt" || exit /b 1
call :CopyBin "LicenseComponents.txt" || exit /b 1
call :CopyBin "Links.txt" || exit /b 1
call :CopyBin "SearchLinks.txt" || exit /b 1
call :CopyBin "ChangeLog.txt" || exit /b 1
call :CopyBin "DFendX DataInstaller.nsi" || exit /b 1
call :CopyBin "UpdateCheck.exe" || exit /b 1
call :CopyBin "SetInstallerLanguage.exe" || exit /b 1
call :CopyBin "7za.dll" || exit /b 1
call :CopyBin "DelZip179.dll" || exit /b 1
call :CopyBin "LicenseBASS.txt" || exit /b 1
call :CopyBin "InstallVideoCodec.exe" || exit /b 1
call :CopyBin "AdminLauncher.exe" || exit /b 1
call :CopyBin "dfxvalidator.exe" || exit /b 1

xcopy /y /q "..\Lang\*.ini" "%DEST%\Lang\" >nul
xcopy /y /q "..\Lang\*.chm" "%DEST%\Lang\" >nul
if exist "..\Lang\Readme_OperationMode.txt" copy /y "..\Lang\Readme_OperationMode.txt" "%DEST%\Lang\" >nul

REM IconSets: same tree as Setup; strip Thumbs.db (Setup uses /x Thumbs.db)
xcopy /y /e /q /i "..\IconSets" "%DEST%\IconSets\" >nul
if exist "%DEST%\IconSets\Modern\Thumbs.db" del /q "%DEST%\IconSets\Modern\Thumbs.db" >nul 2>nul
del /s /q "%DEST%\IconSets\Thumbs.db" >nul 2>nul

REM DOSBox is not bundled; install separately. App discovers path at first run.

if exist "..\NewUserData\Templates" xcopy /y /q "..\NewUserData\Templates\*.prof" "%DEST%\Templates\" >nul
if exist "..\NewUserData\AutoSetup" xcopy /y /q "..\NewUserData\AutoSetup\*.prof" "%DEST%\AutoSetup\" >nul
if exist "..\NewUserData\IconLibrary" xcopy /y /e /q /i "..\NewUserData\IconLibrary" "%DEST%\IconLibrary\" >nul
if exist "..\NewUserData\Icons.ini" copy /y "..\NewUserData\Icons.ini" "%DEST%\Settings\" >nul
REM Cheats.xml only under Settings (Setup does not install it into Bin for the product tree)
if exist "..\Bin\Cheats.xml" copy /y "..\Bin\Cheats.xml" "%DEST%\Settings\" >nul
if exist "..\NewUserData\Capture" xcopy /y /e /q /i "..\NewUserData\Capture" "%DEST%\Capture\" >nul
if exist "..\NewUserData\DOSZIP" xcopy /y /e /q /i "..\NewUserData\DOSZIP" "%DEST%\VirtualHD\DOSZIP\" >nul
if exist "..\NewUserData\FREEDOS" xcopy /y /e /q /i "..\NewUserData\FREEDOS" "%DEST%\VirtualHD\FREEDOS\" >nul
if exist "..\Tools\DataReaderServer\DataReader.xml" copy /y "..\Tools\DataReaderServer\DataReader.xml" "%DEST%\Settings\" >nul

REM Portable operation mode marker (same as Setup InstallDataType=2)
> "%DEST%\DFend.dat" echo PORTABLEMODE

echo.
echo Staged OK: %DEST%
echo DFend.dat = PORTABLEMODE
echo Bin list matches Setup portable ^(no GameExplorer DLL; no Bin lang leftovers^)
echo Next: run BuildZips^(x86^).bat or BuildZips^(x64^).bat
exit /b 0

:CopyBin
if not exist "..\Bin\%~1" (
  echo ERROR: missing ..\Bin\%~1
  exit /b 1
)
copy /y "..\Bin\%~1" "%DEST%\Bin\" >nul
if errorlevel 1 (
  echo ERROR: failed to copy ..\Bin\%~1
  exit /b 1
)
exit /b 0
