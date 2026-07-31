@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Runtime=%~dp0..\BatchRuntime.bat"
set "TestModule=%~dp0TestModule.bat"
set "Tests=0"
set "Passed=0"
set "Failed=0"
set "Abort="

echo BatchRuntime Version 1 self-test
echo =================================

call "!Runtime!" :Initialize
call :RequireExit "Initialize runtime" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Import Test "!TestModule!"
call :RequireExit "Import module" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :GetStat ModuleCount Actual
call :RequireExit "Read module count" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "One module imported" "!Actual!" "1"

call "!Runtime!" :Invoke Test Add Result --Left 17 --Right 25
call :RequireExit "Named parameter invocation" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Get "!Result!" Sum Actual
call :RequireExit "Read named result" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Named Add returns 42" "!Actual!" "42"
call "!Runtime!" :Object.Release "!Result!"
call :RequireExit "Release named result" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test Add Result 9 6
call :RequireExit "Positional parameter invocation" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Get "!Result!" Sum Actual
call :RequireExit "Read positional result" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Positional Add returns 15" "!Actual!" "15"
call "!Runtime!" :Object.Release "!Result!"
call :RequireExit "Release positional result" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test Clamp Result --Value 150
call :RequireExit "Default parameter invocation" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Get "!Result!" Value Actual
call :RequireExit "Read clamped value" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Default maximum clamps to 100" "!Actual!" "100"
call "!Runtime!" :Object.Get "!Result!" WasClamped Actual
call :RequireExit "Read clamp flag" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Clamp flag is true" "!Actual!" "1"
call "!Runtime!" :Object.Release "!Result!"
call :RequireExit "Release clamp result" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test Clamp Result -5 -10 10
call :RequireExit "Signed integer invocation" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Get "!Result!" Value Actual
call :RequireExit "Read signed result" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Signed value remains -5" "!Actual!" "-5"
call "!Runtime!" :Object.Get "!Result!" WasClamped Actual
call :RequireExit "Read unclamped flag" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Unclamped flag is false" "!Actual!" "0"
call "!Runtime!" :Object.Release "!Result!"
call :RequireExit "Release signed result" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test ChooseColor Result --Color green --Bright
call :RequireExit "Enum and bare Boolean invocation" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Get "!Result!" Color Actual
call :RequireExit "Read enum result" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Enum is normalized to schema spelling" "!Actual!" "Green"
call "!Runtime!" :Object.Get "!Result!" Bright Actual
call :RequireExit "Read Boolean result" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Bare Boolean switch becomes true" "!Actual!" "1"
call "!Runtime!" :Object.Release "!Result!"
call :RequireExit "Release enum result" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test MakePair PairResult --Left 12 --Right 30
call :RequireExit "Create return object" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Invoke Test SumPair SumResult --Pair "!PairResult!"
call :RequireExit "Pass object as parameter" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Get "!SumResult!" Sum Actual
call :RequireExit "Read object-parameter result" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Object parameter preserves typed fields" "!Actual!" "42"
call "!Runtime!" :Object.Release "!SumResult!"
call :RequireExit "Release object-parameter result" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Release "!PairResult!"
call :RequireExit "Release pair object" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test NestedAdd Result --Left 20 --Right 22
call :RequireExit "Nested module invocation" "!errorlevel!" "0"
if defined Abort goto :Summary
call "!Runtime!" :Object.Get "!Result!" Sum Actual
call :RequireExit "Read nested result" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Nested invocation returns 42" "!Actual!" "42"
call "!Runtime!" :Object.Release "!Result!"
call :RequireExit "Release nested result" "!errorlevel!" "0"
if defined Abort goto :Summary

set "ShouldNotExist="
call "!Runtime!" :Invoke Test Add ShouldNotExist --Left 1
set "ActualExit=!errorlevel!"
call :AssertEqual "Missing required parameter returns 20" "!ActualExit!" "20"
call "!Runtime!" :Object.Get "!BRT.LastError!" Kind Actual
call :RequireExit "Inspect missing-parameter error" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "Missing parameter error kind" "!Actual!" "MissingRequiredParameter"
call "!Runtime!" :ClearLastError
call :RequireExit "Clear missing-parameter error" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test Add ShouldNotExist --Left banana --Right 2
set "ActualExit=!errorlevel!"
call :AssertEqual "Invalid integer returns 20" "!ActualExit!" "20"
call "!Runtime!" :ClearLastError
call :RequireExit "Clear invalid-integer error" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test Add ShouldNotExist --Left 1 --Right 2 --Third 3
set "ActualExit=!errorlevel!"
call :AssertEqual "Unknown parameter returns 20" "!ActualExit!" "20"
call "!Runtime!" :ClearLastError
call :RequireExit "Clear unknown-parameter error" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test ChooseColor ShouldNotExist --Color Orange
set "ActualExit=!errorlevel!"
call :AssertEqual "Invalid enum returns 20" "!ActualExit!" "20"
call "!Runtime!" :ClearLastError
call :RequireExit "Clear invalid-enum error" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test PrivateFunction ShouldNotExist
set "ActualExit=!errorlevel!"
call :AssertEqual "Private function invocation returns 30" "!ActualExit!" "30"
call "!Runtime!" :ClearLastError
call :RequireExit "Clear private-function error" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :Invoke Test BrokenReturn ShouldNotExist
set "ActualExit=!errorlevel!"
call :AssertEqual "Missing return field returns 40" "!ActualExit!" "40"
call "!Runtime!" :ClearLastError
call :RequireExit "Clear return-validation error" "!errorlevel!" "0"
if defined Abort goto :Summary

call "!Runtime!" :GetStat FrameCount Actual
call :RequireExit "Read final frame count" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "No frames leaked" "!Actual!" "0"

call "!Runtime!" :GetStat ObjectCount Actual
call :RequireExit "Read final object count" "!errorlevel!" "0"
if defined Abort goto :Summary
call :AssertEqual "No objects leaked" "!Actual!" "0"

goto :Summary

:RequireExit
set /a Tests+=1
if "%~2"=="%~3" (
    set /a Passed+=1
    echo [PASS] %~1
    exit /b 0
)
set /a Failed+=1
set "Abort=1"
echo [FAIL] %~1 - expected exit %~3, received %~2
call "!Runtime!" :PrintLastError
exit /b 0

:AssertEqual
set /a Tests+=1
if "%~2"=="%~3" (
    set /a Passed+=1
    echo [PASS] %~1
    exit /b 0
)
set /a Failed+=1
echo [FAIL] %~1 - expected "%~3", received "%~2"
exit /b 0

:Summary
echo.
echo =================================
echo Tests: !Tests!
echo Passed: !Passed!
echo Failed: !Failed!
if !Failed! GTR 0 (
    echo RESULT: FAIL
    exit /b 1
)
echo RESULT: PASS
exit /b 0
