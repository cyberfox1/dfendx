@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem Version from VersionSettings.nsi (same as installers: DFendX-X.Y.Z-*.exe)
for /f "tokens=3" %%A in ('findstr /C:"!define VER_MAYOR" VersionSettings.nsi') do set VER_MAYOR=%%A
for /f "tokens=3" %%A in ('findstr /C:"!define VER_MINOR1" VersionSettings.nsi') do set VER_MINOR1=%%A
for /f "tokens=3" %%A in ('findstr /C:"!define VER_MINOR2" VersionSettings.nsi') do set VER_MINOR2=%%A
if not defined VER_MAYOR (
  echo ERROR: could not read version from VersionSettings.nsi
  exit /b 1
)
set "VER=%VER_MAYOR%.%VER_MINOR1%.%VER_MINOR2%"
set "OUT=DFendX-%VER%-Source.zip"

cd /d "%~dp0\.."
if exist "Install\%OUT%" del /q "Install\%OUT%"

echo === source zip Install\%OUT% ===
7z a -tzip "Install\%OUT%" *.pas *.dfm *.dpr *.dproj *.rc LICENSE ATTRIBUTIONS.txt IconSets Lang Install\*.nsi Install\*.bat Install\*.txt Install\Images Install\IconSources Install\Languages Install\Plugins Bin\License*.txt
exit /b %ERRORLEVEL%
