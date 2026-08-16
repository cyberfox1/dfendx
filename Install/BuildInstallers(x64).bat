@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Requires: makensis and chmcmd.exe on PATH. Builds CHMs then Update + full Setup.
REM Same as BuildInstallers(x86).bat — both assume tools are on PATH (not Program Files paths).

where makensis >nul 2>&1
if errorlevel 1 (
  echo ERROR: makensis not found on PATH.
  echo Install NSIS and ensure makensis is on PATH, then re-run.
  exit /b 1
)

call BuildHelp.bat
if errorlevel 1 exit /b 1

echo.
echo === makensis DFendX-UpdateSetup.nsi ===
makensis DFendX-UpdateSetup.nsi
if errorlevel 1 exit /b 1

echo.
echo === makensis DFendX-Setup.nsi ===
makensis DFendX-Setup.nsi
if errorlevel 1 exit /b 1

echo.
echo === Copy installers to ^<repo^>\..\DFendX-Packages\^<shortgitref^>\ ===
call "%~dp0PackageOutput.bat"
if errorlevel 1 exit /b 1
copy /Y "DFendX-*-Setup.exe" "%PKG_DIR%\"
if errorlevel 1 exit /b 1
copy /Y "DFendX-*-UpdateSetup.exe" "%PKG_DIR%\"
if errorlevel 1 exit /b 1

echo.
echo Installers built OK.
echo Copied to: %PKG_DIR%
exit /b 0
