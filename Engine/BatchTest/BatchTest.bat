@echo off

rem BatchTest.bat
rem Standalone engine-wide test framework for Windows batch suites.
rem Version 1.0.0 - protocol 1.
rem
rem State is intentionally stored in the caller environment.
rem Callers must enable command extensions and delayed expansion.

set "BT.Internal.DelayedProbe=1"
if not "!BT.Internal.DelayedProbe!"=="1" (
    echo BatchTest requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="begin" goto :Readable.Begin
if /i "%~1"=="finish" goto :Readable.Finish
if /i "%~1"=="expect" goto :Readable.Expect
if /i "%~1"=="record" goto :Readable.Record
if /i "%~1"=="configure" goto :Readable.Configure
if /i "%~1"=="run" goto :Readable.Run
if /i "%~1"=="create" goto :Readable.Create
if /i "%~1"=="get" goto :Readable.Get
if /i "%~1"=="import" goto :Readable.Import

echo BatchTest command not understood: %*
exit /b 2

:Readable.Begin
if /i "%~2"=="suite" (
    if "%~3"=="" goto :Syntax
    call :BeginSuite "%~3"
    exit /b !errorlevel!
)
if /i "%~2"=="case" (
    if "%~3"=="" goto :Syntax
    call :BeginCase "%~3"
    exit /b !errorlevel!
)
goto :Syntax

:Readable.Finish
if /i "%~2"=="suite" (
    call :FinishSuite
    exit /b !errorlevel!
)
if /i "%~2"=="case" (
    call :FinishCase
    exit /b !errorlevel!
)
goto :Syntax

:Readable.Expect
if /i "%~2"=="exit" goto :ExpectExit
if /i "%~2"=="value" goto :ExpectValue
if /i "%~2"=="error" goto :ExpectError
if /i "%~2"=="variable" goto :ExpectVariable
if /i "%~2"=="file" goto :ExpectFile
if /i "%~2"=="directory" goto :ExpectDirectory
if /i "%~2"=="files" goto :ExpectFiles
goto :Syntax

:Readable.Record
if /i "%~2"=="pass" goto :RecordPassReadable
if /i "%~2"=="failure" goto :RecordFailureReadable
if /i "%~2"=="skip" goto :RecordSkipReadable
goto :Syntax

:Readable.Configure
if /i "%~2"=="setup" (
    call :ConfigureHook Setup "%~3"
    exit /b !errorlevel!
)
if /i "%~2"=="teardown" (
    call :ConfigureHook Teardown "%~3"
    exit /b !errorlevel!
)
goto :Syntax

:Readable.Run
if /i not "%~2"=="case" goto :Syntax
if "%~3"=="" goto :Syntax
if /i "%~4"=="because" (
    call :RunCase "%~3" "0" "%~5"
    exit /b !errorlevel!
)
if /i "%~4"=="expecting" (
    if /i not "%~5"=="exit" goto :Syntax
    if /i not "%~7"=="because" goto :Syntax
    call :RunCase "%~3" "%~6" "%~8"
    exit /b !errorlevel!
)
goto :Syntax

:Readable.Create
if /i "%~2"=="temporary" (
    if /i "%~3"=="file" (
        if /i not "%~4"=="into" goto :Syntax
        call :CreateTemporary File "%~5"
        exit /b !errorlevel!
    )
    if /i "%~3"=="directory" (
        if /i not "%~4"=="into" goto :Syntax
        call :CreateTemporary Directory "%~5"
        exit /b !errorlevel!
    )
)
if /i "%~2"=="fixture" (
    if /i not "%~3"=="from" goto :Syntax
    if /i not "%~5"=="into" goto :Syntax
    call :CreateFixture "%~4" "%~6"
    exit /b !errorlevel!
)
goto :Syntax

:Readable.Get
if /i "%~2"=="fixture" (
    if /i not "%~3"=="root" goto :Syntax
    if /i not "%~4"=="into" goto :Syntax
    call :GetFixtureRoot "%~5"
    exit /b !errorlevel!
)
if /i "%~2"=="statistic" (
    if /i not "%~4"=="into" goto :Syntax
    call :GetStatistic "%~3" "%~5"
    exit /b !errorlevel!
)
goto :Syntax

:Readable.Import
if /i not "%~2"=="summary" goto :Syntax
if /i not "%~3"=="from" goto :Syntax
call :ImportSummary "%~4"
exit /b !errorlevel!

:BeginSuite
if defined BT.Active (
    echo BatchTest cannot begin a suite while another suite is active.
    exit /b 30
)

for %%V in (
    BT.Name
    BT.Tests
    BT.Passed
    BT.Failed
    BT.Skipped
    BT.Abort
    BT.Active
    BT.Root
    BT.Temp.Sequence
    BT.Case.Sequence
    BT.Case.Active
    BT.Case.Name
    BT.Case.Root
    BT.Setup
    BT.Teardown
    BT.HookPhase
) do set "%%V="

set "BT.Name=%~1"
set "BT.Tests=0"
set "BT.Passed=0"
set "BT.Failed=0"
set "BT.Skipped=0"
set "BT.Temp.Sequence=0"
set "BT.Case.Sequence=0"
set "BT.Root=%TEMP%\BatchTest-!RANDOM!-!RANDOM!-!RANDOM!"

2>nul mkdir "!BT.Root!"
if not exist "!BT.Root!\" (
    echo BatchTest could not create the suite fixture root: !BT.Root!
    set "BT.Root="
    exit /b 50
)

set "BT.Active=1"
echo(!BT.Name!
echo =================================
exit /b 0

:FinishSuite
call :RequireSuite
if errorlevel 1 exit /b 2

if defined BT.Case.Active (
    call :FinishCase
)

if defined BT.Root if exist "!BT.Root!\" (
    2>nul rmdir /s /q "!BT.Root!"
    if exist "!BT.Root!\" (
        call :RecordFailure "Remove the suite fixture root"
    )
)

echo.
echo =================================
echo Tests: !BT.Tests!
echo Passed: !BT.Passed!
echo Failed: !BT.Failed!
if !BT.Skipped! GTR 0 echo Skipped: !BT.Skipped!

set "BT.Internal.FinishExit=0"
if !BT.Failed! GTR 0 (
    echo RESULT: FAIL
    set "BT.Internal.FinishExit=1"
) else (
    echo RESULT: PASS
)

set "BT.Active="
set "BT.Case.Active="
set "BT.Case.Name="
set "BT.Case.Root="
set "BT.Setup="
set "BT.Teardown="
set "BT.HookPhase="
exit /b !BT.Internal.FinishExit!

:BeginCase
call :RequireSuite
if errorlevel 1 exit /b 2

if defined BT.Case.Active (
    echo BatchTest cannot begin a case while another case is active.
    exit /b 30
)

set /a BT.Case.Sequence+=1
set "BT.Case.Name=%~1"
set "BT.Case.Root=!BT.Root!\case-!BT.Case.Sequence!"
set "BT.Case.Active=1"

2>nul mkdir "!BT.Case.Root!"
if not exist "!BT.Case.Root!\" (
    call :RecordFailure "Create fixture state for case !BT.Case.Name!"
    set "BT.Abort=1"
    set "BT.Case.Active="
    exit /b 50
)

if defined BT.Setup (
    set "BT.HookPhase=Setup"
    call "!BT.Setup!" "!BT.Case.Root!" "!BT.Case.Name!"
    set "BT.Internal.HookExit=!errorlevel!"
    set "BT.HookPhase="

    if not "!BT.Internal.HookExit!"=="0" (
        call :RecordFailure "Setup for case !BT.Case.Name! exited !BT.Internal.HookExit!"
        set "BT.Abort=1"
        exit /b 1
    )
)

exit /b 0

:FinishCase
call :RequireSuite
if errorlevel 1 exit /b 2

if not defined BT.Case.Active (
    echo BatchTest cannot finish a case because no case is active.
    exit /b 30
)

set "BT.Internal.TeardownExit=0"

if defined BT.Teardown (
    set "BT.HookPhase=Teardown"
    call "!BT.Teardown!" "!BT.Case.Root!" "!BT.Case.Name!"
    set "BT.Internal.TeardownExit=!errorlevel!"
    set "BT.HookPhase="

    if not "!BT.Internal.TeardownExit!"=="0" (
        call :RecordFailure "Teardown for case !BT.Case.Name! exited !BT.Internal.TeardownExit!"
        set "BT.Abort=1"
    )
)

if defined BT.Case.Root if exist "!BT.Case.Root!\" (
    2>nul rmdir /s /q "!BT.Case.Root!"
    if exist "!BT.Case.Root!\" (
        call :RecordFailure "Remove fixture state for case !BT.Case.Name!"
        set "BT.Abort=1"
        set "BT.Internal.TeardownExit=1"
    )
)

set "BT.Case.Active="
set "BT.Case.Name="
set "BT.Case.Root="

if not "!BT.Internal.TeardownExit!"=="0" exit /b 1
exit /b 0

:RunCase
call :RequireSuite
if errorlevel 1 exit /b 2

set "BT.Internal.CaseScript=%~f1"
set "BT.Internal.CaseExpected=%~2"
set "BT.Internal.CaseReason=%~3"

if not exist "!BT.Internal.CaseScript!" (
    call :RecordFailure "!BT.Internal.CaseReason! - case script is missing"
    set "BT.Abort=1"
    exit /b 0
)

call :ValidateUnsignedInteger "!BT.Internal.CaseExpected!"
if errorlevel 1 (
    echo BatchTest expected exit code is invalid: !BT.Internal.CaseExpected!
    exit /b 2
)

call :BeginCase "!BT.Internal.CaseReason!"
if errorlevel 1 (
    if defined BT.Case.Active call :FinishCase
    exit /b 0
)

call "!BT.Internal.CaseScript!" "!BT.Case.Root!" "!BT.Case.Name!"
set "BT.Internal.CaseActual=!errorlevel!"

call :CompareValues ^
    "!BT.Internal.CaseActual!" ^
    "!BT.Internal.CaseExpected!" ^
    "!BT.Internal.CaseReason!"

if errorlevel 1 set "BT.Abort=1"

call :FinishCase
exit /b 0

:ExpectExit
if /i not "%~4"=="to" goto :Syntax
if /i not "%~5"=="equal" goto :Syntax
if /i not "%~7"=="because" goto :Syntax

call :CompareValues "%~3" "%~6" "%~8"
if errorlevel 1 set "BT.Abort=1"
exit /b 0

:ExpectValue
if /i "%~4"=="to" (
    if /i not "%~5"=="equal" goto :Syntax
    if /i not "%~7"=="because" goto :Syntax
    call :CompareValues "%~3" "%~6" "%~8"
    exit /b 0
)

if /i "%~4"=="not" (
    if /i not "%~5"=="to" goto :Syntax
    if /i not "%~6"=="equal" goto :Syntax
    if /i not "%~8"=="because" goto :Syntax
    call :CompareNotEqual "%~3" "%~7" "%~9"
    exit /b 0
)

goto :Syntax

:ExpectError
if "%~3"=="" goto :Syntax
if /i not "%~4"=="value" goto :Syntax
if /i not "%~6"=="equals" goto :Syntax
if /i not "%~8"=="because" goto :Syntax

call :CompareStructuredError "%~3" "%~5" "%~7" "%~9"
exit /b 0

:ExpectVariable
call :ValidateOutputName "%~3"
if errorlevel 1 goto :Syntax
if /i not "%~4"=="to" goto :Syntax
if /i not "%~5"=="be" goto :Syntax

if /i "%~6"=="defined" (
    if /i not "%~7"=="because" goto :Syntax
    if defined %~3 (
        call :RecordPass "%~8"
    ) else (
        call :RecordFailure "%~8 - variable %~3 is undefined"
    )
    exit /b 0
)

if /i "%~6"=="undefined" (
    if /i not "%~7"=="because" goto :Syntax
    if defined %~3 (
        call :RecordFailure "%~8 - variable %~3 is defined"
    ) else (
        call :RecordPass "%~8"
    )
    exit /b 0
)

goto :Syntax

:ExpectFile
if /i not "%~4"=="to" goto :Syntax
if /i not "%~5"=="exist" goto :Syntax
if /i not "%~6"=="because" goto :Syntax

if exist "%~3" (
    for %%P in ("%~3") do set "BT.Internal.Attributes=%%~aP"
    if /i "!BT.Internal.Attributes:~0,1!"=="d" (
        call :RecordFailure "%~7 - expected a file but found a directory"
    ) else (
        call :RecordPass "%~7"
    )
) else (
    call :RecordFailure "%~7 - file is missing"
)
exit /b 0

:ExpectDirectory
if /i not "%~4"=="to" goto :Syntax
if /i not "%~5"=="exist" goto :Syntax
if /i not "%~6"=="because" goto :Syntax

if exist "%~3\" (
    call :RecordPass "%~7"
) else (
    call :RecordFailure "%~7 - directory is missing"
)
exit /b 0

:ExpectFiles
if /i not "%~4"=="and" goto :Syntax
if /i not "%~6"=="to" goto :Syntax
if /i not "%~7"=="match" goto :Syntax
if /i not "%~8"=="because" goto :Syntax

fc.exe /b "%~3" "%~5" >nul 2>nul
set "BT.Internal.CompareExit=!errorlevel!"

if "!BT.Internal.CompareExit!"=="0" (
    call :RecordPass "%~9"
) else (
    call :RecordFailure "%~9 - binary comparison exited !BT.Internal.CompareExit!"
)
exit /b 0

:RecordPassReadable
if /i not "%~3"=="because" goto :Syntax
call :RecordPass "%~4"
exit /b 0

:RecordFailureReadable
if /i not "%~3"=="because" goto :Syntax
call :RecordFailure "%~4"
exit /b 0

:RecordSkipReadable
if /i not "%~3"=="because" goto :Syntax
call :RecordSkip "%~4"
exit /b 0

:RecordPass
set /a BT.Tests+=1
set /a BT.Passed+=1
set "BT.Internal.Reason=%~1"
echo([PASS] !BT.Internal.Reason!
exit /b 0

:RecordFailure
set /a BT.Tests+=1
set /a BT.Failed+=1
set "BT.Internal.Reason=%~1"
echo([FAIL] !BT.Internal.Reason!
exit /b 0

:RecordSkip
set /a BT.Tests+=1
set /a BT.Skipped+=1
set "BT.Internal.Reason=%~1"
echo([SKIP] !BT.Internal.Reason!
exit /b 0

:CompareValues
set "BT.Internal.Actual=%~1"
set "BT.Internal.Expected=%~2"
set "BT.Internal.Reason=%~3"

if "!BT.Internal.Actual!"=="!BT.Internal.Expected!" (
    call :RecordPass "!BT.Internal.Reason!"
    exit /b 0
)

call :RecordFailure ^
    "!BT.Internal.Reason! - expected [!BT.Internal.Expected!], received [!BT.Internal.Actual!]"
exit /b 1

:CompareNotEqual
set "BT.Internal.Actual=%~1"
set "BT.Internal.Expected=%~2"
set "BT.Internal.Reason=%~3"

if not "!BT.Internal.Actual!"=="!BT.Internal.Expected!" (
    call :RecordPass "!BT.Internal.Reason!"
    exit /b 0
)

call :RecordFailure ^
    "!BT.Internal.Reason! - did not expect [!BT.Internal.Expected!]"
exit /b 1

:CompareStructuredError
set "BT.Internal.ErrorField=%~1"
set "BT.Internal.Actual=%~2"
set "BT.Internal.Expected=%~3"
set "BT.Internal.Reason=%~4"

if "!BT.Internal.Actual!"=="!BT.Internal.Expected!" (
    call :RecordPass "!BT.Internal.Reason!"
    exit /b 0
)

call :RecordFailure ^
    "!BT.Internal.Reason! - error !BT.Internal.ErrorField! expected [!BT.Internal.Expected!], received [!BT.Internal.Actual!]"
exit /b 1

:ConfigureHook
call :RequireSuite
if errorlevel 1 exit /b 2

set "BT.Internal.HookKind=%~1"
set "BT.Internal.HookPath=%~2"

if /i "!BT.Internal.HookPath!"=="none" (
    set "BT.!BT.Internal.HookKind!="
    exit /b 0
)

if not exist "!BT.Internal.HookPath!" (
    echo BatchTest !BT.Internal.HookKind! hook is missing: !BT.Internal.HookPath!
    exit /b 30
)

for %%P in ("!BT.Internal.HookPath!") do (
    set "BT.!BT.Internal.HookKind!=%%~fP"
)
exit /b 0

:CreateTemporary
call :RequireSuite
if errorlevel 1 exit /b 2

call :ValidateOutputName "%~2"
if errorlevel 1 (
    echo BatchTest output variable is invalid: %~2
    exit /b 2
)

set "BT.Internal.TempKind=%~1"
set "BT.Internal.TempRoot=!BT.Root!"
if defined BT.Case.Active set "BT.Internal.TempRoot=!BT.Case.Root!"

set /a BT.Temp.Sequence+=1

if /i "!BT.Internal.TempKind!"=="File" (
    set "BT.Internal.TempPath=!BT.Internal.TempRoot!\file-!BT.Temp.Sequence!.tmp"
    type nul > "!BT.Internal.TempPath!"
    if errorlevel 1 (
        echo BatchTest could not create a temporary file: !BT.Internal.TempPath!
        exit /b 50
    )
) else (
    set "BT.Internal.TempPath=!BT.Internal.TempRoot!\directory-!BT.Temp.Sequence!"
    2>nul mkdir "!BT.Internal.TempPath!"
    if not exist "!BT.Internal.TempPath!\" (
        echo BatchTest could not create a temporary directory: !BT.Internal.TempPath!
        exit /b 50
    )
)

set "%~2=!BT.Internal.TempPath!"
exit /b 0

:CreateFixture
call :RequireSuite
if errorlevel 1 exit /b 2

if not exist "%~1" (
    echo BatchTest fixture source is missing: %~1
    exit /b 30
)

for %%P in ("%~1") do set "BT.Internal.Attributes=%%~aP"
if /i "!BT.Internal.Attributes:~0,1!"=="d" (
    echo BatchTest fixture source must be a file: %~1
    exit /b 20
)

call :ValidateOutputName "%~2"
if errorlevel 1 (
    echo BatchTest output variable is invalid: %~2
    exit /b 2
)

set "BT.Internal.TempRoot=!BT.Root!"
if defined BT.Case.Active set "BT.Internal.TempRoot=!BT.Case.Root!"

set /a BT.Temp.Sequence+=1
for %%P in ("%~1") do set "BT.Internal.FixtureLeaf=%%~nxP"
set "BT.Internal.FixturePath=!BT.Internal.TempRoot!\fixture-!BT.Temp.Sequence!-!BT.Internal.FixtureLeaf!"

copy /b /y "%~1" "!BT.Internal.FixturePath!" >nul
if errorlevel 1 (
    echo BatchTest could not copy fixture: %~1
    exit /b 50
)

set "%~2=!BT.Internal.FixturePath!"
exit /b 0

:GetFixtureRoot
call :RequireSuite
if errorlevel 1 exit /b 2

call :ValidateOutputName "%~1"
if errorlevel 1 (
    echo BatchTest output variable is invalid: %~1
    exit /b 2
)

set "BT.Internal.SelectedRoot=!BT.Root!"
if defined BT.Case.Active set "BT.Internal.SelectedRoot=!BT.Case.Root!"
set "%~1=!BT.Internal.SelectedRoot!"
exit /b 0

:GetStatistic
call :RequireSuite
if errorlevel 1 exit /b 2

call :ValidateOutputName "%~2"
if errorlevel 1 (
    echo BatchTest output variable is invalid: %~2
    exit /b 2
)

set "BT.Internal.StatValue="

if /i "%~1"=="Tests" set "BT.Internal.StatValue=!BT.Tests!"
if /i "%~1"=="Passed" set "BT.Internal.StatValue=!BT.Passed!"
if /i "%~1"=="Failed" set "BT.Internal.StatValue=!BT.Failed!"
if /i "%~1"=="Skipped" set "BT.Internal.StatValue=!BT.Skipped!"
if /i "%~1"=="CaseCount" set "BT.Internal.StatValue=!BT.Case.Sequence!"

if not defined BT.Internal.StatValue (
    echo BatchTest statistic is unknown: %~1
    exit /b 30
)

set "%~2=!BT.Internal.StatValue!"
exit /b 0

:ImportSummary
call :RequireSuite
if errorlevel 1 exit /b 2

if not exist "%~1" (
    echo BatchTest summary file is missing: %~1
    exit /b 30
)

if not "!BT.Tests!"=="0" (
    echo BatchTest can import a summary only before recording local assertions.
    exit /b 30
)

set "BT.Internal.Import.Tests="
set "BT.Internal.Import.Passed="
set "BT.Internal.Import.Failed="
set "BT.Internal.Import.Skipped=0"

for /f "usebackq tokens=1,* delims==" %%A in ("%~1") do (
    if /i "%%A"=="Tests" set "BT.Internal.Import.Tests=%%B"
    if /i "%%A"=="Passed" set "BT.Internal.Import.Passed=%%B"
    if /i "%%A"=="Failed" set "BT.Internal.Import.Failed=%%B"
    if /i "%%A"=="Skipped" set "BT.Internal.Import.Skipped=%%B"
)

for %%V in (
    BT.Internal.Import.Tests
    BT.Internal.Import.Passed
    BT.Internal.Import.Failed
    BT.Internal.Import.Skipped
) do (
    if not defined %%V (
        echo BatchTest summary file is missing a required value: %%V
        exit /b 20
    )
    call :ValidateUnsignedInteger "!%%V!"
    if errorlevel 1 (
        echo BatchTest summary value is invalid: %%V=!%%V!
        exit /b 20
    )
)

set /a BT.Internal.Import.Calculated=BT.Internal.Import.Passed+BT.Internal.Import.Failed+BT.Internal.Import.Skipped
if not "!BT.Internal.Import.Calculated!"=="!BT.Internal.Import.Tests!" (
    echo BatchTest summary totals are inconsistent.
    exit /b 20
)

set "BT.Tests=!BT.Internal.Import.Tests!"
set "BT.Passed=!BT.Internal.Import.Passed!"
set "BT.Failed=!BT.Internal.Import.Failed!"
set "BT.Skipped=!BT.Internal.Import.Skipped!"
exit /b 0

:RequireSuite
if defined BT.Active exit /b 0
echo BatchTest suite is not active.
exit /b 1

:ValidateOutputName
if "%~1"=="" exit /b 1

for %%R in (
    PATH
    PATHEXT
    COMSPEC
    SYSTEMROOT
    TEMP
    TMP
    USERPROFILE
    CD
    ERRORLEVEL
    CMDEXTVERSION
    CMDCMDLINE
) do (
    if /i "%~1"=="%%R" exit /b 1
)

echo(%~1| %SystemRoot%\System32\findstr.exe /r /x "[A-Za-z_][A-Za-z0-9_.]*" >nul
exit /b !errorlevel!

:ValidateUnsignedInteger
if "%~1"=="" exit /b 1
for /f "delims=0123456789" %%N in ("%~1") do exit /b 1
exit /b 0

:Syntax
echo BatchTest command syntax is invalid: %*
exit /b 2
