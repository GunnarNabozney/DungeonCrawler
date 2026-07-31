@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchText 1.0 validation
echo ========================

call "%~dp0Tests\BatchText.Tests.bat"
set "TestExit=!errorlevel!"

echo.
if "!TestExit!"=="0" (
    echo BatchText validation passed.
) else (
    echo BatchText validation failed with exit code !TestExit!.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
