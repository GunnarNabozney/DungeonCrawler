@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchRuntime 1.1 validation
echo ===========================

call "%~dp0Tests\BatchRuntime.Tests.bat"
set "TestExit=!errorlevel!"

echo.
if "!TestExit!"=="0" (
    echo BatchRuntime validation passed.
) else (
    echo BatchRuntime validation failed with exit code !TestExit!.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
