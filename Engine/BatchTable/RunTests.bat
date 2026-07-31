@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo BatchTable 1.0 validation
echo =========================

call "%~dp0Tests\BatchTable.Tests.bat"
set "TestExit=!errorlevel!"

if "!TestExit!"=="0" (
    echo.
    echo BatchTable validation passed.
) else (
    echo.
    echo BatchTable validation failed.
)

if /i not "%~1"=="--no-pause" pause
exit /b !TestExit!
