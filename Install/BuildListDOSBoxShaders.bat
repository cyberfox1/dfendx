@echo off
setlocal
cd /d "%~dp0"
if not exist "..\Tools" mkdir "..\Tools"
set "PATH=g:\dev\fpc322\bin\i386-win32\;%PATH%"
fpc -Mdelphi -TWin32 -Pi386 -Fu".." -FE"..\Tools" -FU"..\Tools" -o"..\Tools\listdosboxshaders.exe" "..\ListDOSBoxShaders.lpr"
exit /b %ERRORLEVEL%
