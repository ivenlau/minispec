@echo off
REM minispec launcher (Windows cmd shim) — delegates to minispec.ps1.
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%minispec.ps1" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%minispec.ps1" %*
)
exit /b %ERRORLEVEL%
