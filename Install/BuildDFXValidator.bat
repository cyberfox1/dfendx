@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Build Tools\dfxvalidator\dfxvalidator.pas -> Bin\dfxvalidator.exe (32-bit).
REM Free Pascal i386-Win32. Same resolution order as test\runTests.bat (PATH not required).

set "FPC_EXE="
if defined FPC if exist "%FPC%" set "FPC_EXE=%FPC%"
if not defined FPC_EXE if defined FPC if exist "%FPC%.exe" set "FPC_EXE=%FPC%.exe"
if not defined FPC_EXE if exist "G:\Dev\fpc322\bin\i386-win32\fpc.exe" set "FPC_EXE=G:\Dev\fpc322\bin\i386-win32\fpc.exe"
if not defined FPC_EXE if exist "G:\Dev\fpc322\bin\i386-Win32\fpc.exe" set "FPC_EXE=G:\Dev\fpc322\bin\i386-Win32\fpc.exe"
if not defined FPC_EXE (
  where fpc >nul 2>&1
  if not errorlevel 1 for /f "delims=" %%I in ('where fpc') do (
    set "FPC_EXE=%%I"
    goto :have_fpc
  )
)
:have_fpc
if not defined FPC_EXE (
  echo ERROR: fpc not found.
  echo Set FPC to fpc.exe, put fpc on PATH, or install at G:\Dev\fpc322\bin\i386-win32\
  exit /b 1
)

if not exist "..\Tools\dfxvalidator\dfxvalidator.pas" (
  echo ERROR: ..\Tools\dfxvalidator\dfxvalidator.pas not found.
  exit /b 1
)

if not exist "..\Bin" mkdir "..\Bin"

set "UNITDIR=%TEMP%\dfxvalidator-units"
if exist "%UNITDIR%" rd /s /q "%UNITDIR%"
mkdir "%UNITDIR%" 2>nul

echo === fpc dfxvalidator -^> Bin\dfxvalidator.exe ===
echo Using fpc: %FPC_EXE%
"%FPC_EXE%" -TWin32 -Pi386 -O2 -Xs -XX -FE"..\Bin" -FU"%UNITDIR%" "..\Tools\dfxvalidator\dfxvalidator.pas"
if errorlevel 1 (
  echo ERROR: fpc failed.
  exit /b 1
)

if not exist "..\Bin\dfxvalidator.exe" (
  echo ERROR: Bin\dfxvalidator.exe was not produced.
  exit /b 1
)

rd /s /q "%UNITDIR%" 2>nul

echo Built: ..\Bin\dfxvalidator.exe
for %%A in ("..\Bin\dfxvalidator.exe") do echo Size: %%~zA bytes
exit /b 0
