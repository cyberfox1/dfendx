@echo off
REM Package output dir relative to the REPO ROOT: ..\DFendX-Packages\<shortgitref>\
REM (sibling of the repo, not inside it). Install\ is %~dp0; repo is %~dp0..;
REM so from repo root that is %~dp0..\..\DFendX-Packages\...
REM Call after a successful build (use "call" so PKG_DIR is visible):
REM   call "%~dp0PackageOutput.bat"
REM   copy /Y "artifact.exe" "%PKG_DIR%\"
REM
REM Do not use setlocal here — PKG_DIR must remain in the caller's environment.

set "GITREF="
for /f "usebackq delims=" %%i in (`git -C "%~dp0.." rev-parse --short HEAD 2^>nul`) do set "GITREF=%%i"
if not defined GITREF (
  echo WARNING: git short ref unavailable; using nogit
  set "GITREF=nogit"
)

set "PKG_DIR=%~dp0..\..\DFendX-Packages\%GITREF%"
if "%PKG_DIR:~-1%"=="\" set "PKG_DIR=%PKG_DIR:~0,-1%"

if not exist "%PKG_DIR%\" (
  mkdir "%PKG_DIR%" 2>nul
)
if not exist "%PKG_DIR%\" (
  echo ERROR: could not create package dir: "%PKG_DIR%"
  exit /b 1
)

echo Package output dir: %PKG_DIR%
exit /b 0
