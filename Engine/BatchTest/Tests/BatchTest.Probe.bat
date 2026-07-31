@echo off
setlocal EnableExtensions EnableDelayedExpansion

for /f "tokens=1 delims==" %%V in ('set BT. 2^>nul') do set "%%V="

set "Framework=%~dp0..\BatchTest.bat"
set "Compatibility=%~dp0..\..\BatchRuntime\BatchTest.bat"

if /i "%~1"=="legacy-pass" goto :LegacyPass
if /i "%~1"=="failure" goto :Failure
if /i "%~1"=="import-summary" goto :ImportSummary

echo Unknown BatchTest probe mode: %~1
exit /b 2

:LegacyPass
call "!Compatibility!" begin suite "BatchTest Runtime compatibility probe"
call "!Compatibility!" expect exit 0 to equal 0 because "Legacy expected-exit syntax remains compatible"
call "!Compatibility!" expect value Same to equal Same because "Legacy expected-value syntax remains compatible"
call "!Compatibility!" finish suite
exit /b !errorlevel!

:Failure
call "!Framework!" begin suite "BatchTest failure probe"
call "!Framework!" expect value Left to equal Right because "Intentional failure is reported"
call "!Framework!" finish suite
exit /b !errorlevel!

:ImportSummary
call "!Framework!" begin suite "BatchTest imported summary probe"
call "!Framework!" create temporary file into SummaryFile
> "!SummaryFile!" (
    echo Tests=3
    echo Passed=2
    echo Failed=0
    echo Skipped=1
)
call "!Framework!" import summary from "!SummaryFile!"
if errorlevel 1 exit /b 2
call "!Framework!" finish suite
exit /b !errorlevel!
