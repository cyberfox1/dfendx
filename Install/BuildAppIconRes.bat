@echo off
REM Wrapper — full icon asset build.
call "%~dp0BuildIconAssetsRes.bat"
exit /b %ERRORLEVEL%
