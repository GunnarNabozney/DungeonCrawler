@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0Tests\BatchRuntime.Tests.bat"
set "TestExit=!errorlevel!"
echo.
if "!TestExit!"=="0" (
    echo BatchRuntime Version 1 passed its self-test.
) else (
    echo BatchRuntime Version 1 failed its self-test.
)
echo.
pause
exit /b !TestExit!
