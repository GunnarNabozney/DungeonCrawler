@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Runtime=%~dp0..\BatchRuntime.bat"
set "BatchTest=%~dp0..\BatchTest.bat"
set "TestModule=%~dp0TestModule.bat"
set "BadSchemaModule=%~dp0BadSchemaModule.bat"
set "DependencyModule=%~dp0DependencyModule.bat"
set "MissingDependencyModule=%~dp0MissingDependencyModule.bat"
set "MathModule=%~dp0..\Modules\Math.bat"

call "!BatchTest!" begin suite "BatchRuntime 1.1 human-readable self-test"

call "!Runtime!" initialize runtime
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize runtime"
if defined BT.Abort goto :Summary

call "!Runtime!" import module MissingDependency from "!MissingDependencyModule!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 60 because "Reject a module whose dependency is missing"
call "!Runtime!" clear last error

call "!Runtime!" import module Test from "!TestModule!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Import the reference module"
if defined BT.Abort goto :Summary

call "!Runtime!" import module Dependency from "!DependencyModule!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Import a module after its dependency"

call "!Runtime!" import module BadSchema from "!BadSchemaModule!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Import the invalid-schema test module"

call "!Runtime!" import module Math from "!MathModule!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Import the reusable math module"

call "!Runtime!" get statistic ModuleCount into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Read module count"
call "!BatchTest!" expect value "!Actual!" to equal 4 because "Four modules are imported"

call "!Runtime!" run Test Add into Result with Left 17 and Right 25
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Run a function with readable named parameters"
if defined BT.Abort goto :Summary
call "!Runtime!" read field Sum from object "!Result!" into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Read a field with readable object syntax"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Add returns 42"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Test Add into Result with Left 00017 and Right 00025
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Normalize leading zeroes"
call "!Runtime!" read field Sum from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Normalized integers remain numeric"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Test Add into Result with Left 1073741824 and Right 0
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Validate a ten-digit integer return"
call "!Runtime!" read field Sum from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1073741824 because "Ten-digit return validation preserves its caller field loop"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Test Clamp into Result with Value 150
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Apply default parameter values"
call "!Runtime!" read field Value from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 100 because "Default maximum clamps to 100"
call "!Runtime!" read field WasClamped from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Clamp reports a changed value"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Test ChooseColor into Result with Color green and Bright true
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Run enum and Boolean parameters"
call "!Runtime!" read field Color from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal Green because "Enum values use schema spelling"
call "!Runtime!" read field Bright from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Boolean values normalize to one"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Test MakePair into PairResult with Left 12 and Right 30
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a typed return object"
call "!Runtime!" run Test SumPair into SumResult with Pair "!PairResult!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Pass a typed object as a parameter"
call "!Runtime!" read field Sum from object "!SumResult!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Object parameters preserve typed fields"

call "!Runtime!" clone object "!PairResult!" into PairClone
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Clone an object"
call "!Runtime!" run Test SumPair into CloneSum with Pair "!PairClone!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Use the cloned object"
call "!Runtime!" read field Sum from object "!CloneSum!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Cloned object fields match"
call "!Runtime!" release object "!CloneSum!"
call "!Runtime!" release object "!PairClone!"
call "!Runtime!" release object "!SumResult!"
call "!Runtime!" release object "!PairResult!"

call "!Runtime!" run Test NestedAdd into Result with Left 20 and Right 22
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Run a successful nested invocation"
call "!Runtime!" read field Sum from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Nested invocation returns 42"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Test NestedFailure into ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Propagate a nested parameter failure"
call "!Runtime!" read field Kind from object "!BRT.LastError!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal MissingRequiredParameter because "Preserve the innermost parameter error"
call "!Runtime!" clear last error

call "!Runtime!" run Test NestedBrokenReturn into ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 40 because "Propagate a nested return validation failure"
call "!Runtime!" read field Kind from object "!BRT.LastError!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal MissingReturnField because "Preserve the innermost return error"
call "!Runtime!" clear last error

call "!Runtime!" run Test DeepNest into Result with Depth 3
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Support more than three invocation levels"
call "!Runtime!" read field Sum from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Deep nesting returns the base result"
call "!Runtime!" release object "!Result!"

call "!Runtime!" set maximum call depth to 3
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Configure maximum call depth"
call "!Runtime!" run Test DeepNest into ShouldNotExist with Depth 5
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 50 because "Reject nesting beyond the configured maximum"
call "!Runtime!" read field Kind from object "!BRT.LastError!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal MaximumCallDepthExceeded because "Report the maximum depth failure"
call "!Runtime!" clear last error
call "!Runtime!" set maximum call depth to 32

call "!Runtime!" run Test LeakTemporary into Result
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Run a function that leaves a nested temporary object"
call "!Runtime!" release object "!Result!"
call "!Runtime!" get statistic ObjectCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Frame ownership releases abandoned temporary objects"

call "!Runtime!" run Math FloorDivide into Result with Dividend -3 and Divisor 2
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Run mathematical floor division"
call "!Runtime!" read field Quotient from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal -2 because "Floor division rounds toward negative infinity"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Test Add into ShouldNotExist with Left 2147483648 and Right 0
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an integer above the signed 32-bit range"
call "!Runtime!" clear last error

call "!Runtime!" run Test Add into ShouldNotExist with Left -2147483649 and Right 0
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an integer below the signed 32-bit range"
call "!Runtime!" clear last error

call "!Runtime!" run Test Add into PATH with Left 1 and Right 2
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 10 because "Reject a reserved output variable"
call "!Runtime!" clear last error

for %%F in (
    DuplicateNames
    DuplicatePositions
    BadDefault
    EmptyEnum
    DuplicateEnum
    UnknownProperty
) do (
    call "!Runtime!" run BadSchema %%F into ShouldNotExist
    set "ActualExit=!errorlevel!"
    call "!BatchTest!" expect exit "!ActualExit!" to equal 60 because "Reject invalid schema %%F"
    call "!Runtime!" clear last error
)

set "TextSource=%TEMP%\BatchRuntime-Readable-Source-!RANDOM!.txt"
set "TextCopy=%TEMP%\BatchRuntime-Readable-Copy-!RANDOM!.txt"
setlocal DisableDelayedExpansion
> "%TextSource%" (
    echo Percent %% and bang !
    echo Pipe ^| ampersand ^& redirects ^< ^> caret ^^ parentheses ^( ^)
    echo Quotes "remain data"
)
endlocal

call "!Runtime!" load text from "!TextSource!" into TextOne
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load arbitrary text through a file-backed handle"
call "!Runtime!" load text from "!TextSource!" into TextTwo
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load the same text twice"
call "!Runtime!" compare text "!TextOne!" with "!TextTwo!" into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Compare two text handles"
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Identical text handles compare equal"
call "!Runtime!" save text "!TextOne!" to "!TextCopy!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Save a text handle without expanding its content"
fc /b "!TextSource!" "!TextCopy!" >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Saved arbitrary text matches the source bytes"
call "!Runtime!" release text "!TextOne!"
call "!Runtime!" release text "!TextTwo!"
del /q "!TextSource!" "!TextCopy!" >nul 2>nul

call "!Runtime!" show modules >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "List imported modules"
call "!Runtime!" show functions in module Test >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "List module functions"
call "!Runtime!" show schema for Test Add >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Describe a function schema"
call "!Runtime!" show runtime >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Show runtime state"

call "!Runtime!" get statistic FrameCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "No frames are leaked"
call "!Runtime!" get statistic ObjectCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "No objects are leaked"
call "!Runtime!" get statistic TextCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "No text handles are leaked"

:Summary
call "!BatchTest!" finish suite
set "TestExit=!errorlevel!"
call "!Runtime!" shutdown runtime >nul 2>nul
exit /b !TestExit!
