@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchCodec 1.0 validation
echo ==========================

call "%~dp0Tests\BatchCodec.Tests.bat"
set "TestExit=!errorlevel!"

if "!TestExit!"=="0" (
    echo.
    echo BatchCodec validation passed.
) else (
    echo.
    echo BatchCodec validation failed.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
