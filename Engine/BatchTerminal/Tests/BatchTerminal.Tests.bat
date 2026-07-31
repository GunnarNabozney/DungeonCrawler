@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "BT_Module=%~dp0..\BatchTerminal.psm1"
set "BT_PowerShell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%BT_Module%" (
    echo [FAIL] BatchTerminal module exists
    exit /b 1
)

if not exist "%BT_PowerShell%" (
    echo [FAIL] Windows PowerShell 5.1 exists
    exit /b 1
)

"%BT_PowerShell%" ^
    -NoLogo ^
    -NoProfile ^
    -NonInteractive ^
    -ExecutionPolicy Bypass ^
    -Command "$ErrorActionPreference = 'Stop'; Import-Module -Name $env:BT_Module -Force; $Result = Invoke-BatchTerminalSelfTest; foreach ($Test in $Result.Results) { $Line = '[' + $Test.Status + '] ' + $Test.Name; if (-not [string]::IsNullOrWhiteSpace($Test.Detail)) { $Line += ' - ' + $Test.Detail }; [Console]::WriteLine($Line) }; [Console]::WriteLine(''); [Console]::WriteLine('================================='); [Console]::WriteLine('Tests: ' + $Result.Total); [Console]::WriteLine('Passed: ' + $Result.Passed); [Console]::WriteLine('Failed: ' + $Result.Failed); if ($Result.Failed -ne 0) { [Console]::WriteLine('RESULT: FAIL'); exit 1 }; [Console]::WriteLine('RESULT: PASS'); exit 0"

set "BT_Exit=%errorlevel%"
exit /b %BT_Exit%