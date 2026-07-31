@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "BT_Module=%~dp0BatchTerminal.psm1"
set "BT_PowerShell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "BT_Command=%~1"
set "BT_Argument1=%~2"
set "BT_Argument2=%~3"
set "BT_Argument3=%~4"

if not defined BT_Command set "BT_Command=capabilities"

if not exist "%BT_Module%" (
    echo BatchTerminal module is missing: %BT_Module%
    exit /b 50
)

if not exist "%BT_PowerShell%" (
    echo Windows PowerShell 5.1 is unavailable: %BT_PowerShell%
    exit /b 50
)

"%BT_PowerShell%" ^
    -NoLogo ^
    -NoProfile ^
    -NonInteractive ^
    -ExecutionPolicy Bypass ^
    -Command "$ErrorActionPreference = 'Stop'; Import-Module -Name $env:BT_Module -Force; Invoke-BatchTerminalCommand -CommandName $env:BT_Command -Argument1 $env:BT_Argument1 -Argument2 $env:BT_Argument2 -Argument3 $env:BT_Argument3"

set "BT_Exit=%errorlevel%"
exit /b %BT_Exit%