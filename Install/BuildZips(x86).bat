@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Requires: 7z and makensis on PATH.
REM Stages a portable tree into Install\stagingportable via StagePortableTree.bat,
REM then packs zips / PortableApps from that tree.
REM NOTE: Never end a quoted path with a backslash (breaks cmd parenthesis parsing).

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
  echo ERROR: ..\DFend.exe not found. Build the app in RAD first ^(Src\DFend.dproj -^> repo root^).
  exit /b 1
)

rem Version from repo-root VERSION
if not exist "%~dp0..\VERSION" (
  echo ERROR: missing VERSION file at repo root
  exit /b 1
)
set /p VER=<"%~dp0..\VERSION"
if not defined VER (
  echo ERROR: VERSION file is empty
  exit /b 1
)
set "ZIP_FULL=DFendX-%VER%.zip"
echo Using version %VER%

set "PORTABLE_ROOT=%~dp0stagingportable"
if "%PORTABLE_ROOT:~-1%x"=="\x" set "PORTABLE_ROOT=%PORTABLE_ROOT:~0,-1%"

echo === Clean stagingportable ===
if exist "%PORTABLE_ROOT%" (
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

rem Create portable zip archive
if exist "%ZIP_FULL%" del /q "%ZIP_FULL%"
echo === 7z a zip %ZIP_FULL% ===
7z a -tzip -r "%ZIP_FULL%" "%PORTABLE_ROOT%\*"
if errorlevel 1 exit /b 1

rem Create portable apps package
set "PAF_NAME=DFendX-%VER%-Portable.paf.exe"
set "PAF_DIR=%~dp0..\Tools\PortableApps package"
set "PAF_APP=%PAF_DIR%\DFendX Portable\App\DFendX"
xcopy "%PORTABLE_ROOT%" "%PAF_APP%" /E /Y /I /Q
if errorlevel 1 exit /b 1

echo === makensis PortableApps launcher ===
makensis "%PAF_DIR%\DFendX Portable\Other\Launcher Source\PortableAppsLauncher.nsi"
if errorlevel 1 exit /b 1
echo === makensis PortableApps installer -^> %PAF_NAME% ===
makensis "%PAF_DIR%\DFendX Portable\Other\Installer Source\PortableApps.comInstaller.nsi"
if errorlevel 1 exit /b 1
if not exist "%PAF_DIR%\%PAF_NAME%" (
  echo ERROR: expected PAF not produced: "%PAF_DIR%\%PAF_NAME%"
  dir /b "%PAF_DIR%\*.exe" 2>nul
  exit /b 1
)
copy /Y "%PAF_DIR%\%PAF_NAME%" "%~dp0%PAF_NAME%"
if errorlevel 1 exit /b 1
if exist "%PAF_DIR%\DFendX Portable\DFendX Portable.exe" del "%PAF_DIR%\DFendX Portable\DFendX Portable.exe"
del "%PAF_DIR%\%PAF_NAME%" 2>nul

del "%PAF_APP%\*.*" /S /Q
rd "%PAF_APP%" /S /Q
md "%PAF_APP%"

rem Clean up staged portable tree after packaging
echo === Clean stagingportable ===
if exist "%PORTABLE_ROOT%" rd /s /q "%PORTABLE_ROOT%"

echo.
echo === Copy zips/PAF to package output dir ===
call "%~dp0PackageOutput.bat"
if errorlevel 1 exit /b 1
copy /Y "%ZIP_FULL%" "%PKG_DIR%"
if errorlevel 1 exit /b 1
copy /Y "%PAF_NAME%" "%PKG_DIR%"
if errorlevel 1 exit /b 1

echo.
echo BuildZips finished OK.
echo Copied to: %PKG_DIR%
exit /b 0
