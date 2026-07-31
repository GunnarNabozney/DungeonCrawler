@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "BatchTest=%~dp0..\BatchTest.bat"
set "Compatibility=%~dp0..\..\BatchRuntime\BatchTest.bat"
set "Probe=%~dp0BatchTest.Probe.bat"
set "Hook=%~dp0BatchTest.Hook.bat"
set "CaseScript=%~dp0BatchTest.Case.bat"

call "!BatchTest!" begin suite "BatchTest 1.0 deterministic self-test"

call "!BatchTest!" expect file "!BatchTest!" to exist because "Standalone BatchTest framework exists"
call "!BatchTest!" expect file "!Compatibility!" to exist because "Runtime compatibility helper exists"

call "!BatchTest!" get fixture root into FixtureRoot
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Read the isolated suite fixture root"
call "!BatchTest!" expect directory "!FixtureRoot!" to exist because "Suite fixture root exists"

call "!BatchTest!" create temporary file into TempFile
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a temporary file"
call "!BatchTest!" expect file "!TempFile!" to exist because "Temporary file exists"

call "!BatchTest!" create temporary directory into TempDirectory
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a temporary directory"
call "!BatchTest!" expect directory "!TempDirectory!" to exist because "Temporary directory exists"

call "!BatchTest!" create fixture from "%~f0" into FixtureCopy
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Copy a binary fixture"
call "!BatchTest!" expect file "!FixtureCopy!" to exist because "Fixture copy exists"
call "!BatchTest!" expect files "%~f0" and "!FixtureCopy!" to match because "Fixture copy preserves source bytes"

set "DefinedProbe=Ready"
call "!BatchTest!" expect variable DefinedProbe to be defined because "Defined-variable assertions succeed"
call "!BatchTest!" expect variable UndefinedProbe to be undefined because "Undefined-variable assertions succeed"
call "!BatchTest!" expect value Alpha not to equal Beta because "Negative value assertions succeed"
call "!BatchTest!" expect error Kind value DuplicateRecord equals DuplicateRecord because "Structured-error assertions compare named fields"

call "!BatchTest!" configure setup "!Hook!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Configure a setup hook"
call "!BatchTest!" configure teardown "!Hook!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Configure a teardown hook"

call "!BatchTest!" run case "!CaseScript!" expecting exit 7 because "Run an isolated case with expected exit code"
call "!BatchTest!" expect value "!BT.Probe.Setup!" to equal 1 because "Case setup runs"
call "!BatchTest!" expect value "!BT.Probe.Case!" to equal 1 because "Case body runs"
call "!BatchTest!" expect value "!BT.Probe.Teardown!" to equal 1 because "Case teardown runs"

call "!BatchTest!" configure setup none
call "!BatchTest!" configure teardown none

call "!BatchTest!" create temporary file into LegacyOutput
call "!Probe!" legacy-pass > "!LegacyOutput!" 2>&1
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Runtime-local helper forwards legacy commands"

findstr.exe /l /c:"RESULT: PASS" "!LegacyOutput!" >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Compatibility probe prints the standard passing summary"

call "!BatchTest!" create temporary file into FailureOutput
call "!Probe!" failure > "!FailureOutput!" 2>&1
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 1 because "Failing suites return exit code one"

findstr.exe /l /c:"[FAIL] Intentional failure is reported" "!FailureOutput!" >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Failing assertions use the standard output format"

findstr.exe /l /c:"RESULT: FAIL" "!FailureOutput!" >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Failing suites print the standard failing summary"

call "!BatchTest!" create temporary file into ImportOutput
call "!Probe!" import-summary > "!ImportOutput!" 2>&1
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Import a valid external summary"

findstr.exe /l /c:"Skipped: 1" "!ImportOutput!" >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Imported summaries preserve skipped counts"

call "!BatchTest!" get statistic CaseCount into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Read framework statistics"
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Case statistics count isolated cases"

:Summary
call "!BatchTest!" finish suite
exit /b !errorlevel!
