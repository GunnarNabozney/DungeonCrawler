@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchRandom 1.0 validation
echo ==========================

call "%~dp0Tests\BatchRandom.Tests.bat"
set "TestExit=!errorlevel!"

echo.
if "!TestExit!"=="0" (
    echo BatchRandom validation passed.
) else (
    echo BatchRandom validation failed with exit code !TestExit!.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
