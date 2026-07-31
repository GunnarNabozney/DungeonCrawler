@echo off

rem BatchTest.bat
rem Human-readable assertion helper for Windows batch test suites.
rem State is intentionally stored in the caller environment.

if /i "%~1"=="begin" goto :Begin
if /i "%~1"=="expect" goto :Expect
if /i "%~1"=="record" goto :Record
if /i "%~1"=="finish" goto :Finish

echo BatchTest command not understood: %*
exit /b 2

:Begin
if /i not "%~2"=="suite" goto :Syntax
set "BT.Name=%~3"
set "BT.Tests=0"
set "BT.Passed=0"
set "BT.Failed=0"
set "BT.Abort="
echo !BT.Name!
echo =================================
exit /b 0

:Expect
if /i "%~2"=="exit" goto :ExpectExit
if /i "%~2"=="value" goto :ExpectValue
goto :Syntax

:ExpectExit
if /i not "%~4"=="to" goto :Syntax
if /i not "%~5"=="equal" goto :Syntax
if /i not "%~7"=="because" goto :Syntax
call :Compare "%~3" "%~6" "%~8"
if errorlevel 1 set "BT.Abort=1"
exit /b 0

:ExpectValue
if /i not "%~4"=="to" goto :Syntax
if /i not "%~5"=="equal" goto :Syntax
if /i not "%~7"=="because" goto :Syntax
call :Compare "%~3" "%~6" "%~8"
exit /b 0

:Record
if /i "%~2"=="pass" goto :RecordPass
if /i "%~2"=="failure" goto :RecordFailure
goto :Syntax

:RecordPass
if /i not "%~3"=="because" goto :Syntax
set /a BT.Tests+=1
set /a BT.Passed+=1
echo [PASS] %~4
exit /b 0

:RecordFailure
if /i not "%~3"=="because" goto :Syntax
set /a BT.Tests+=1
set /a BT.Failed+=1
echo [FAIL] %~4
exit /b 0

:Compare
set /a BT.Tests+=1
if "%~1"=="%~2" (
    set /a BT.Passed+=1
    echo [PASS] %~3
    exit /b 0
)
set /a BT.Failed+=1
echo [FAIL] %~3 - expected "%~2", received "%~1"
exit /b 1

:Finish
if /i not "%~2"=="suite" goto :Syntax
echo.
echo =================================
echo Tests: !BT.Tests!
echo Passed: !BT.Passed!
echo Failed: !BT.Failed!
if !BT.Failed! GTR 0 (
    echo RESULT: FAIL
    exit /b 1
)
echo RESULT: PASS
exit /b 0

:Syntax
echo BatchTest command syntax is invalid: %*
exit /b 2
