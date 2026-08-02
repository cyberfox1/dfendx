@echo off
setlocal EnableExtensions
REM Prefer "upx" on PATH; fall back to Install\Tools\upx.exe (bundled 3.x).
REM Usage: upx-prefer-path.bat [upx args...] files...

where upx >nul 2>&1
if not errorlevel 1 (
  upx %*
  exit /b %ERRORLEVEL%
)

if exist "%~dp0Tools\upx.exe" (
  "%~dp0Tools\upx.exe" %*
  exit /b %ERRORLEVEL%
)

echo ERROR: upx not found on PATH and Install\Tools\upx.exe is missing.
exit /b 1
