@echo off

if not exist "%~1\setup.marker" exit /b 9
set "BT.Probe.Case=1"
> "%~1\case.marker" echo case
exit /b 7
