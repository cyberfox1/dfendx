@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Same as BuildZips(x86).bat — stages Install\stagingportable then packs.
REM Requires: 7z and makensis on PATH.

where 7z >nul 2>&1
if errorlevel 1 (
  echo ERROR: 7z not found on PATH.
  echo Install 7-Zip and ensure 7z is on PATH, then re-run.
  exit /b 1
)

where makensis >nul 2>&1
if errorlevel 1 (
  echo ERROR: makensis not found on PATH.
  exit /b 1
)

if not exist "..\DFend.exe" (
  echo ERROR: ..\DFend.exe not found. Build the app in RAD first.
  exit /b 1
)

rem Version from VersionSettings.nsi (same as installers / Source zip)
for /f "tokens=3" %%A in ('findstr /C:"!define VER_MAYOR" VersionSettings.nsi') do set VER_MAYOR=%%A
for /f "tokens=3" %%A in ('findstr /C:"!define VER_MINOR1" VersionSettings.nsi') do set VER_MINOR1=%%A
for /f "tokens=3" %%A in ('findstr /C:"!define VER_MINOR2" VersionSettings.nsi') do set VER_MINOR2=%%A
if not defined VER_MAYOR (
  echo ERROR: could not read version from VersionSettings.nsi
  exit /b 1
)
set "VER=%VER_MAYOR%.%VER_MINOR1%.%VER_MINOR2%"
set "ZIP_FULL=DFendX-%VER%.zip"
set "ZIP_MINI=DFendX-%VER%-Mini.zip"
echo Using version %VER%

set "PORTABLE_ROOT=%~dp0stagingportable"
if "%PORTABLE_ROOT:~-1%"=="\" set "PORTABLE_ROOT=%PORTABLE_ROOT:~0,-1%"

echo === Clean stagingportable ===
if exist "%PORTABLE_ROOT%\" (
  rd /s /q "%PORTABLE_ROOT%"
)

echo === StagePortableTree -^> stagingportable ===
call "%~dp0StagePortableTree.bat" "%PORTABLE_ROOT%"
if errorlevel 1 (
  echo ERROR: StagePortableTree.bat failed.
  exit /b 1
)
if not exist "%PORTABLE_ROOT%\DFend.exe" (
  echo ERROR: Staged tree missing DFend.exe: "%PORTABLE_ROOT%"
  exit /b 1
)
echo Using portable tree: %PORTABLE_ROOT%

rem Create main zip archive
if exist "%ZIP_FULL%" del /q "%ZIP_FULL%"
echo === 7z a main zip %ZIP_FULL% ===
7z a -tzip -r "%ZIP_FULL%" "%PORTABLE_ROOT%\*"
if errorlevel 1 exit /b 1

rem Create mini zip archive
set "MINI_ROOT=%PORTABLE_ROOT%_mini"
if exist "%MINI_ROOT%\" rd /s /q "%MINI_ROOT%"
md "%MINI_ROOT%" 2>nul
xcopy "%PORTABLE_ROOT%" "%MINI_ROOT%\" /E /Y /Q
if errorlevel 1 exit /b 1

REM Mini zip strips FreeDOS/DOSZip extras only (DOSBox is not staged).

del "%MINI_ROOT%\VirtualHD\DOSZip\*.*" /S /Q 2>nul
rd "%MINI_ROOT%\VirtualHD\DOSZip" /S /Q 2>nul

del "%MINI_ROOT%\VirtualHD\FREEDOS\*.*" /S /Q 2>nul
rd "%MINI_ROOT%\VirtualHD\FREEDOS" /S /Q 2>nul

if exist "%ZIP_MINI%" del /q "%ZIP_MINI%"
echo === 7z a mini zip %ZIP_MINI% ===
7z a -tzip -r "%ZIP_MINI%" "%MINI_ROOT%\*"
if errorlevel 1 exit /b 1

rd /s /q "%MINI_ROOT%"

rem Create portable apps package
xcopy "%PORTABLE_ROOT%" "..\Tools\PortableApps package\DFendX Portable\App\DFendX\" /E /Y /Q
if errorlevel 1 exit /b 1

echo === makensis PortableApps ===
makensis "..\Tools\PortableApps package\DFendX Portable\Other\Launcher Source\PortableAppsLauncher.nsi"
if errorlevel 1 exit /b 1
makensis "..\Tools\PortableApps package\DFendX Portable\Other\Installer Source\PortableApps.comInstaller.nsi"
if errorlevel 1 exit /b 1

copy "..\Tools\PortableApps package\*.exe" .
del "..\Tools\PortableApps package\*.exe"
del "..\Tools\PortableApps package\DFendX Portable\DFendX Portable.exe"

del "..\Tools\PortableApps package\DFendX Portable\App\DFendX\*.*" /S /Q
rd "..\Tools\PortableApps package\DFendX Portable\App\DFendX" /S /Q
md "..\Tools\PortableApps package\DFendX Portable\App\DFendX"

rem Source zip: whitelist only (BuildSourceZip.bat) — do not zip the whole tree with excludes.
echo === source zip (BuildSourceZip.bat) ===
call "%~dp0BuildSourceZip.bat"
if errorlevel 1 exit /b 1

rem Clean up staged portable tree after packaging
echo === Clean stagingportable ===
if exist "%PORTABLE_ROOT%\" rd /s /q "%PORTABLE_ROOT%"

echo.
echo === Copy zips/PAF to ^<repo^>\..\DFendX-Packages\^<shortgitref^>\ ===
call "%~dp0PackageOutput.bat"
if errorlevel 1 exit /b 1
copy /Y "%ZIP_FULL%" "%PKG_DIR%\"
if errorlevel 1 exit /b 1
copy /Y "%ZIP_MINI%" "%PKG_DIR%\"
if errorlevel 1 exit /b 1
copy /Y "DFendX-%VER%-Source.zip" "%PKG_DIR%\"
if errorlevel 1 exit /b 1
copy /Y "DFendX-%VER%-Portable.paf.exe" "%PKG_DIR%\"
if errorlevel 1 exit /b 1

echo.
echo BuildZips finished OK.
echo Copied to: %PKG_DIR%
exit /b 0
