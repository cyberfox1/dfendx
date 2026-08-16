@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Extra tools -> Bin\:
REM   Tools\dfxvalidator\dfxvalidator.pas -> Bin\dfxvalidator.exe (32-bit fpc)
REM   Tools\ConfigCom\config.asm          -> Bin\config.com (16-bit DOS, nasm)
REM Same tool resolution idea as test\runTests.bat (PATH not required).

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
echo.

REM ---------------------------------------------------------------------------
REM config.com (16-bit DOS COM)
REM ---------------------------------------------------------------------------
set "NASM_EXE="
if defined NASM if exist "%NASM%" set "NASM_EXE=%NASM%"
if not defined NASM_EXE if defined NASM if exist "%NASM%.exe" set "NASM_EXE=%NASM%.exe"
if not defined NASM_EXE if exist "C:\ProgramData\scoop\apps\mingw-winlibs\current\bin\nasm.exe" (
  set "NASM_EXE=C:\ProgramData\scoop\apps\mingw-winlibs\current\bin\nasm.exe"
)
if not defined NASM_EXE if exist "G:\Dev\scoop32\apps\mingw-winlibs\current\bin\nasm.exe" (
  set "NASM_EXE=G:\Dev\scoop32\apps\mingw-winlibs\current\bin\nasm.exe"
)
if not defined NASM_EXE (
  where nasm >nul 2>&1
  if not errorlevel 1 for /f "delims=" %%I in ('where nasm') do (
    set "NASM_EXE=%%I"
    goto :have_nasm
  )
)
:have_nasm
if not defined NASM_EXE (
  echo ERROR: nasm not found.
  echo Set NASM to nasm.exe or put nasm on PATH.
  exit /b 1
)

if not exist "..\Tools\ConfigCom\config.asm" (
  echo ERROR: ..\Tools\ConfigCom\config.asm not found.
  exit /b 1
)

echo === nasm config.asm -^> Bin\config.com ===
echo Using nasm: %NASM_EXE%
"%NASM_EXE%" -f bin -o "..\Bin\config.com" "..\Tools\ConfigCom\config.asm"
if errorlevel 1 (
  echo ERROR: nasm failed.
  exit /b 1
)

if not exist "..\Bin\config.com" (
  echo ERROR: Bin\config.com was not produced.
  exit /b 1
)

echo Built: ..\Bin\config.com
for %%A in ("..\Bin\config.com") do echo Size: %%~zA bytes
exit /b 0
