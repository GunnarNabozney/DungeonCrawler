@echo off
setlocal EnableExtensions DisableDelayedExpansion

title Dungeon Crawler
mode con cols=80 lines=30
color 07

set "AppScript=%~dp0DungeonCrawler.ps1"

if not exist "%AppScript%" (
    cls
    color 0C
    echo.
    echo ERROR: DungeonCrawler.ps1 was not found.
    echo.
    echo Expected location:
    echo %AppScript%
    echo.
    pause
    exit /b 1
)

powershell.exe ^
    -NoLogo ^
    -NoProfile ^
    -ExecutionPolicy Bypass ^
    -File "%AppScript%"

set "AppExitCode=%ERRORLEVEL%"

if not "%AppExitCode%"=="0" (
    cls
    color 0C
    echo.
    echo Dungeon Crawler stopped with an error.
    echo.
    echo Exit code: %AppExitCode%
    echo.
    pause
)

endlocal & exit /b %AppExitCode%
