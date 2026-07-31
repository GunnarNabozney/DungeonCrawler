@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Runtime=%~dp0..\BatchRuntime.bat"
set "MathModule=%~dp0..\Modules\Math.bat"

call "!Runtime!" :Initialize
if errorlevel 1 goto :Error

call "!Runtime!" :Import Math "!MathModule!"
if errorlevel 1 goto :Error

call "!Runtime!" :Invoke Math Add Result --Left 17 --Right 25
if errorlevel 1 goto :Error

call "!Runtime!" :Object.Get "!Result!" Sum Sum
if errorlevel 1 goto :Error

echo 17 + 25 = !Sum!

call "!Runtime!" :Object.Release "!Result!"
if errorlevel 1 goto :Error

exit /b 0

:Error
call "!Runtime!" :PrintLastError
exit /b 1
