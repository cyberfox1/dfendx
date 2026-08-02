@echo off
REM Ensure Bin\sqlite3.dll exists for packaging (FireDAC SQLite vendor lib).
REM Prefers existing Bin\ copy; otherwise copies the 32-bit DLL from RAD Studio.
REM Optional: also copy next to repo root DFend.exe when arg is "root".
REM Usage:
REM   EnsureSqlite3Dll.bat
REM   EnsureSqlite3Dll.bat root

setlocal EnableExtensions
cd /d "%~dp0"

set "REPO=%~dp0.."
cd /d "%REPO%"
set "REPO=%CD%"

set "DEST_BIN=%REPO%\Bin\sqlite3.dll"

if exist "%DEST_BIN%" (
  echo OK: already have %DEST_BIN%
  goto :copy_root
)

set "SRC="
if defined BDS if exist "%BDS%\bin\sqlite3.dll" set "SRC=%BDS%\bin\sqlite3.dll"
if not defined SRC if exist "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\sqlite3.dll" (
  set "SRC=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\sqlite3.dll"
)
if not defined SRC if exist "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\sqlite3.dll" (
  set "SRC=C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\sqlite3.dll"
)
if not defined SRC if exist "C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\sqlite3.dll" (
  set "SRC=C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\sqlite3.dll"
)

if not defined SRC (
  echo ERROR: sqlite3.dll not found.
  echo Expected Bin\sqlite3.dll, or RAD Studio bin\sqlite3.dll ^(32-bit, not bin64^).
  echo Set BDS to your RAD Studio root, or copy sqlite3.dll into Bin\ manually.
  exit /b 1
)

echo Copying FireDAC SQLite vendor DLL:
echo   from: %SRC%
echo   to:   %DEST_BIN%
if not exist "%REPO%\Bin" mkdir "%REPO%\Bin"
copy /y "%SRC%" "%DEST_BIN%" >nul
if errorlevel 1 (
  echo ERROR: copy to Bin\sqlite3.dll failed
  exit /b 1
)
echo OK: Bin\sqlite3.dll

:copy_root
if /i not "%~1"=="root" exit /b 0
copy /y "%DEST_BIN%" "%REPO%\sqlite3.dll" >nul
if errorlevel 1 (
  echo ERROR: copy sqlite3.dll to repo root failed
  exit /b 1
)
echo OK: repo root sqlite3.dll
exit /b 0
