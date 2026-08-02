@echo off
REM Build Lang\English.chm and Lang\German.chm from Help\ sources using Free Pascal chmcmd.
REM Includes full [MAP] + [ALIAS] so Application.HelpCommand(HELP_CONTEXT, id) works.
REM Called by BuildInstallers(x86|x64).bat before makensis.
REM Requires: chmcmd.exe (PATH, CHMCMD env, or same FPC bin as test\runTests.bat).
REM Requires: pwsh (PowerShell 7+).

setlocal EnableExtensions
cd /d "%~dp0"

REM Same FPC bin as test\runTests.bat (interactive shells often lack this on PATH)
if exist "g:\dev\fpc322\bin\i386-win32\chmcmd.exe" (
  set "PATH=g:\dev\fpc322\bin\i386-win32\;%PATH%"
)
if defined CHMCMD (
  if exist "%CHMCMD%" (
    for %%I in ("%CHMCMD%") do set "PATH=%%~dpI;%PATH%"
  )
)

where chmcmd >nul 2>&1
if errorlevel 1 (
  where chmcmd.exe >nul 2>&1
  if errorlevel 1 (
    echo ERROR: chmcmd.exe not found.
    echo Put Free Pascal bin on PATH, set CHMCMD to full path of chmcmd.exe,
    echo or install FPC at g:\dev\fpc322\bin\i386-win32\ ^(as used by test\runTests.bat^).
    exit /b 1
  )
)

where pwsh >nul 2>&1
if errorlevel 1 (
  echo ERROR: pwsh.exe not found on PATH.
  echo Install PowerShell 7+ ^(pwsh^) or put pwsh.exe on PATH, then re-run.
  exit /b 1
)

pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0BuildHelp.ps1" -RepoRoot "%~dp0.."
if errorlevel 1 exit /b 1
exit /b 0
