@echo off

if /i "%BT.HookPhase%"=="Setup" (
    set "BT.Probe.Setup=1"
    > "%~1\setup.marker" echo setup
    exit /b 0
)

if /i "%BT.HookPhase%"=="Teardown" (
    if not exist "%~1\setup.marker" exit /b 9
    set "BT.Probe.Teardown=1"
    exit /b 0
)

exit /b 8
