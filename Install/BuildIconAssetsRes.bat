@echo off
REM Sources:  Install\IconSources\
REM Built:    IconSets\  (runtime + embed inputs)
REM           root *.res  (linked by DFend.dpr)
REM RC files: repo root
setlocal EnableExtensions
cd /d "%~dp0.."

set "RC=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rc.exe"
if not exist "%RC%" goto :no_rc
goto :have_rc
:no_rc
echo ERROR: rc.exe not found
exit /b 1
:have_rc

if not exist "Install\IconSources" (
  echo ERROR: missing Install\IconSources
  exit /b 1
)

echo === Sync IconSources -^> IconSets ===
if not exist "IconSets\DOSBoxKind" md "IconSets\DOSBoxKind"
if not exist "IconSets\Modern" md "IconSets\Modern"
if not exist "IconSets\Media" md "IconSets\Media"
if not exist "IconSets\App" md "IconSets\App"

REM Kind: copy PNGs; build white-bg multi-size ICOs into IconSets when PNG present
if exist "Install\IconSources\DOSBoxKind\*.png" copy /y "Install\IconSources\DOSBoxKind\*.png" "IconSets\DOSBoxKind\" >nul
if exist "Install\IconSources\DOSBoxKind\*.ico" copy /y "Install\IconSources\DOSBoxKind\*.ico" "IconSets\DOSBoxKind\" >nul
for %%F in ("Install\IconSources\DOSBoxKind\*.png") do (
  echo Building ICO from %%~nxF
  magick "%%F" -background white -alpha remove -alpha off -define icon:auto-resize=256,128,64,48,32,16 "IconSets\DOSBoxKind\%%~nF.ico"
  if errorlevel 1 exit /b 1
)

REM Modern UI ICOs
if exist "Install\IconSources\Modern\*" copy /y "Install\IconSources\Modern\*" "IconSets\Modern\" >nul

REM Media placeholder
if exist "Install\IconSources\Media\*" copy /y "Install\IconSources\Media\*" "IconSets\Media\" >nul

REM App icon
if exist "Install\IconSources\DFend_Icon.ico" copy /y "Install\IconSources\DFend_Icon.ico" "IconSets\App\DFend_Icon.ico" >nul

echo === Compile resources -^> root *.res ===
"%RC%" /fo icon_assets.res icon_assets.rc
if errorlevel 1 exit /b 1
"%RC%" /fo DFend_icon.res DFend_icon.rc
if errorlevel 1 exit /b 1
"%RC%" /fo toobig_thumb.res toobig_thumb.rc
if errorlevel 1 exit /b 1

for %%A in (icon_assets.res DFend_icon.res toobig_thumb.res) do echo OK: %%~nxA %%~zA bytes
exit /b 0
