@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchValidate 1.0 validation
echo ============================

call "%~dp0Tests\BatchValidate.Tests.bat"
set "TestExit=!errorlevel!"

echo.
if "!TestExit!"=="0" (
    echo BatchValidate validation passed.
) else (
    echo BatchValidate validation failed with exit code !TestExit!.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
