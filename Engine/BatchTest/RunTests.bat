@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchTest 1.0 validation
echo ========================

call "%~dp0Tests\BatchTest.Tests.bat"
set "TestExit=!errorlevel!"

if "!TestExit!"=="0" (
    echo.
    echo BatchTest validation passed.
) else (
    echo.
    echo BatchTest validation failed.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
