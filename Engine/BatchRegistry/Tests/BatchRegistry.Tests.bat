@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Registry=%~dp0..\BatchRegistry.bat"
set "BatchTest=%~dp0..\..\BatchRuntime\BatchTest.bat"

call "!BatchTest!" begin suite "BatchRegistry 1.0 human-readable self-test"

call "!Registry!" initialize registry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize registry"
if defined BT.Abort goto :Summary

call "!Registry!" get statistic RegistryCount into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Read initial registry count"
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Registry count starts at zero"

call "!Registry!" create registry Session owned by Game
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a registry"

call "!Registry!" create registry session owned by Game
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a case-insensitive duplicate registry"
call "!Registry!" read last error Kind into Actual
call "!BatchTest!" expect value "!Actual!" to equal RegistryAlreadyExists because "Report duplicate registry error"
call "!Registry!" clear last error

call "!Registry!" create registry Config owned by Game
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a second registry"
call "!Registry!" get statistic RegistryCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Registry count tracks active registries"

call "!Registry!" set Int key Player.Health in registry Session to 00042
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Set a signed integer key"
call "!Registry!" read key Player.Health from registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Normalize signed integers"
call "!Registry!" read type Player.Health from registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal Int because "Preserve the key type"
call "!Registry!" read key player.health from registry session into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Resolve registry names and keys case-insensitively"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Case-insensitive reads preserve the value"

call "!Registry!" set Int key Player.Health in registry Session to 7
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Update a key with its declared type"
call "!Registry!" read key Player.Health from registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 7 because "Read the updated value"
call "!Registry!" get statistic EntryCount for registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Updating does not create a duplicate entry"

call "!Registry!" set UInt key Player.Health in registry Session to 7
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a key type change"
call "!Registry!" read last error Kind into Actual
call "!BatchTest!" expect value "!Actual!" to equal RegistryTypeMismatch because "Report the type mismatch"
call "!Registry!" clear last error

call "!Registry!" set Int key Limits.Maximum in registry Session to 2147483647
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Accept the maximum signed integer"
call "!Registry!" set Int key Limits.Minimum in registry Session to -2147483648
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Accept the minimum signed integer"
call "!Registry!" set Int key Limits.TooHigh in registry Session to 2147483648
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an integer above the signed range"
call "!Registry!" clear last error
call "!Registry!" set Int key Limits.TooLow in registry Session to -2147483649
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an integer below the signed range"
call "!Registry!" clear last error

call "!Registry!" set UInt key Counters.High in registry Session to 2147483647
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Accept the maximum unsigned registry integer"
call "!Registry!" set UInt key Counters.Invalid in registry Session to -1
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a negative unsigned value"
call "!Registry!" clear last error

call "!Registry!" set Bool key Flags.Enabled in registry Session to true
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Set a Boolean key"
call "!Registry!" read key Flags.Enabled from registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Normalize true to one"
call "!Registry!" set Bool key Flags.Enabled in registry Session to off
call "!Registry!" read key Flags.Enabled from registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Normalize off to zero"

call "!Registry!" set Id key Player.Class in registry Session to RuneKnight_2
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Set an identifier key"
call "!Registry!" set Id key Player.InvalidClass in registry Session to 2Knight
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an invalid identifier value"
call "!Registry!" clear last error

call "!Registry!" set String key Player.Title in registry Session to "Keeper of Keys"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Set a command-safe string"
call "!Registry!" read key Player.Title from registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal "Keeper of Keys" because "Preserve spaces in a string"

call "!Registry!" check key Player.Title in registry Session into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Check an existing key"
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Existing keys report true"
call "!Registry!" check key Player.Missing in registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Missing keys report false"

for %%K in (.Leading Trailing. Double..Dot 2Invalid.Start) do (
    call "!Registry!" set String key %%K in registry Session to value
    set "ActualExit=!errorlevel!"
    call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject malformed key %%K"
    call "!Registry!" clear last error
)

call "!Registry!" read key Player.Missing from registry Session into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject reading a missing key"
call "!Registry!" read last error Kind into Actual
call "!BatchTest!" expect value "!Actual!" to equal RegistryKeyNotFound because "Report the missing key error"
call "!Registry!" clear last error

call "!Registry!" remove key Player.Title from registry Session
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Remove an existing key"
call "!Registry!" check key Player.Title in registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Removed keys are absent"
call "!Registry!" remove key Player.Title from registry Session
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject removing a missing key"
call "!Registry!" clear last error

call "!Registry!" show registries >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "List registries"
call "!Registry!" show keys in registry Session >nul
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "List registry keys"

call "!Registry!" clear registry Session
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Clear a registry"
call "!Registry!" get statistic EntryCount for registry Session into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Clearing removes every entry"

call "!Registry!" release registries owned by Game
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Release registries by owner"
call "!Registry!" get statistic RegistryCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Owner cleanup releases matching registries"

call "!Registry!" :Create Compact Engine
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create through the compact ABI"
call "!Registry!" :Set Compact Smoke.Value Int 42
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Set through the compact ABI"
call "!Registry!" :Get Compact Smoke.Value Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Read through the compact ABI"
call "!Registry!" :Release Compact
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Release through the compact ABI"

call "!Registry!" create registry Global owned by Engine
call "!Registry!" create registry Temporary owned by Screen
call "!Registry!" release registries owned by Screen
call "!Registry!" get statistic RegistryCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Owner cleanup preserves other owners"
call "!Registry!" set String key Status.Mode in registry Global to Ready
call "!Registry!" read key Status.Mode from registry Global into PATH
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 10 because "Reject a reserved output variable"
call "!Registry!" clear last error
call "!Registry!" release registry Global
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Release a registry explicitly"

call "!Registry!" shutdown registry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shutdown registry"
call "!Registry!" get statistic RegistryCount into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 50 because "Reject operations after shutdown"

:Summary
call "!BatchTest!" finish suite
exit /b !errorlevel!
