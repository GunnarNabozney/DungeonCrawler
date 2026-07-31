@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchRegistry 1.0 validation
echo ============================

call "%~dp0Tests\BatchRegistry.Tests.bat"
set "TestExit=!errorlevel!"

echo.
if "!TestExit!"=="0" (
    echo BatchRegistry validation passed.
) else (
    echo BatchRegistry validation failed with exit code !TestExit!.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
