@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "BTERM_Module=%~dp0..\BatchTerminal.psm1"
set "BTERM_PowerShell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "BatchTest=%~dp0..\..\BatchTest\BatchTest.bat"

call "!BatchTest!" begin suite "BatchTerminal 1.0 deterministic self-test"

if not exist "!BTERM_Module!" (
    call "!BatchTest!" record failure because "BatchTerminal module exists"
    goto :Summary
)

if not exist "!BTERM_PowerShell!" (
    call "!BatchTest!" record failure because "Windows PowerShell 5.1 exists"
    goto :Summary
)

call "!BatchTest!" create temporary file into BTERM_Summary
if errorlevel 1 (
    call "!BatchTest!" record failure because "Create BatchTerminal summary fixture"
    goto :Summary
)

"!BTERM_PowerShell!" ^
    -NoLogo ^
    -NoProfile ^
    -NonInteractive ^
    -ExecutionPolicy Bypass ^
    -Command "$ErrorActionPreference = 'Stop'; Import-Module -Name $env:BTERM_Module -Force; $Result = Invoke-BatchTerminalSelfTest; foreach ($Test in $Result.Results) { $Line = '[' + $Test.Status + '] ' + $Test.Name; if (-not [string]::IsNullOrWhiteSpace($Test.Detail)) { $Line += ' - ' + $Test.Detail }; [Console]::WriteLine($Line) }; $NewLine = [Environment]::NewLine; $SummaryText = 'Tests=' + [string]$Result.Total + $NewLine + 'Passed=' + [string]$Result.Passed + $NewLine + 'Failed=' + [string]$Result.Failed + $NewLine + 'Skipped=0' + $NewLine; [System.IO.File]::WriteAllText($env:BTERM_Summary, $SummaryText, [System.Text.Encoding]::ASCII); exit 0"

set "BTERM.Exit=!errorlevel!"

if not "!BTERM.Exit!"=="0" (
    call "!BatchTest!" record failure because "Run the BatchTerminal PowerShell self-test - exit !BTERM.Exit!"
    goto :Summary
)

call "!BatchTest!" import summary from "!BTERM_Summary!"
if errorlevel 1 (
    call "!BatchTest!" record failure because "Import the BatchTerminal test summary"
)

:Summary
call "!BatchTest!" finish suite
exit /b !errorlevel!
