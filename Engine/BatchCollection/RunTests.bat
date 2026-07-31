@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchCollection 1.0 validation
echo ==============================

call "%~dp0Tests\BatchCollection.Tests.bat"
set "TestExit=!errorlevel!"

if "!TestExit!"=="0" (
    echo.
    echo BatchCollection validation passed.
) else (
    echo.
    echo BatchCollection validation failed.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
