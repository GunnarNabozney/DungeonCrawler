@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchMath 1.0 validation
echo ========================

call "%~dp0Tests\BatchMath.Tests.bat"
set "TestExit=!errorlevel!"

echo.
if "!TestExit!"=="0" (
    echo BatchMath validation passed.
) else (
    echo BatchMath validation failed with exit code !TestExit!.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
