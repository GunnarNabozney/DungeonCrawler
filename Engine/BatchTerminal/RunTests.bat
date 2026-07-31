@echo off
setlocal EnableExtensions DisableDelayedExpansion

echo BatchTerminal 1.0 validation
echo ============================
echo BatchTerminal 1.0 deterministic self-test
echo =========================================

call "%~dp0Tests\BatchTerminal.Tests.bat"
set "BT.Exit=%errorlevel%"

echo.
if "%BT.Exit%"=="0" (
    echo BatchTerminal validation passed.
) else (
    echo BatchTerminal validation failed.
)

if /i not "%~1"=="--no-pause" pause
exit /b %BT.Exit%