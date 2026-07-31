@echo off

rem BatchRegistry.bat
rem Project-agnostic typed registry for Windows batch files.
rem Version 1.0.0 - protocol 1
rem Requirement: caller must enable command extensions and delayed expansion.

set "BR.Internal.DelayedProbe=1"
if not "!BR.Internal.DelayedProbe!"=="1" (
    echo BatchRegistry requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="create" goto :Readable.Create
if /i "%~1"=="set" goto :Readable.Set
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="check" goto :Readable.Check
if /i "%~1"=="remove" goto :Readable.Remove
if /i "%~1"=="clear" goto :Readable.Clear
if /i "%~1"=="release" goto :Readable.Release
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="get" goto :Readable.Get
if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":Create" goto :Create
if /i "%~1"==":Set" goto :Set
if /i "%~1"==":Get" goto :Get
if /i "%~1"==":GetType" goto :GetType
if /i "%~1"==":Has" goto :Has
if /i "%~1"==":Remove" goto :Remove
if /i "%~1"==":Clear" goto :Clear
if /i "%~1"==":Release" goto :Release
if /i "%~1"==":ReleaseOwner" goto :ReleaseOwner
if /i "%~1"==":List" goto :List
if /i "%~1"==":ListKeys" goto :ListKeys
if /i "%~1"==":GetStat" goto :GetStat
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :SetError 10 UnknownRegistryCommand "Unknown BatchRegistry command." "" "" "" "Known registry command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="registry" goto :Readable.Syntax
call "%~f0" :Initialize
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="registry" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Create
if /i not "%~2"=="registry" goto :Readable.Syntax
if /i not "%~4"=="owned" goto :Readable.Syntax
if /i not "%~5"=="by" goto :Readable.Syntax
call "%~f0" :Create "%~3" "%~6"
exit /b !errorlevel!

:Readable.Set
if /i not "%~3"=="key" goto :Readable.Syntax
if /i not "%~5"=="in" goto :Readable.Syntax
if /i not "%~6"=="registry" goto :Readable.Syntax
if /i not "%~8"=="to" goto :Readable.Syntax
call "%~f0" :Set "%~7" "%~4" "%~2" "%~9"
exit /b !errorlevel!

:Readable.Read
if /i "%~2"=="key" goto :Readable.ReadKey
if /i "%~2"=="type" goto :Readable.ReadType
if /i "%~2"=="last" goto :Readable.ReadLastError
goto :Readable.Syntax

:Readable.ReadKey
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~5"=="registry" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :Get "%~6" "%~3" "%~8"
exit /b !errorlevel!

:Readable.ReadType
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~5"=="registry" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :GetType "%~6" "%~3" "%~8"
exit /b !errorlevel!

:Readable.ReadLastError
if /i not "%~3"=="error" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :ReadLastError "%~4" "%~6"
exit /b !errorlevel!

:Readable.Check
if /i not "%~2"=="key" goto :Readable.Syntax
if /i not "%~4"=="in" goto :Readable.Syntax
if /i not "%~5"=="registry" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :Has "%~6" "%~3" "%~8"
exit /b !errorlevel!

:Readable.Remove
if /i not "%~2"=="key" goto :Readable.Syntax
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~5"=="registry" goto :Readable.Syntax
call "%~f0" :Remove "%~6" "%~3"
exit /b !errorlevel!

:Readable.Clear
if /i "%~2"=="registry" (
    call "%~f0" :Clear "%~3"
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    call "%~f0" :ClearLastError
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Release
if /i "%~2"=="registry" (
    call "%~f0" :Release "%~3"
    exit /b !errorlevel!
)
if /i "%~2"=="registries" if /i "%~3"=="owned" if /i "%~4"=="by" (
    call "%~f0" :ReleaseOwner "%~5"
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Show
if /i "%~2"=="registries" (
    call "%~f0" :List
    exit /b !errorlevel!
)
if /i "%~2"=="keys" if /i "%~3"=="in" if /i "%~4"=="registry" (
    call "%~f0" :ListKeys "%~5"
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    call "%~f0" :PrintLastError
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Get
if /i not "%~2"=="statistic" goto :Readable.Syntax
if /i "%~3"=="RegistryCount" (
    if /i not "%~4"=="into" goto :Readable.Syntax
    call "%~f0" :GetStat RegistryCount "" "%~5"
    exit /b !errorlevel!
)
if /i "%~3"=="EntryCount" (
    if /i not "%~4"=="for" goto :Readable.Syntax
    if /i not "%~5"=="registry" goto :Readable.Syntax
    if /i not "%~7"=="into" goto :Readable.Syntax
    call "%~f0" :GetStat EntryCount "%~6" "%~8"
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Syntax
call :SetError 10 InvalidRegistrySyntax "BatchRegistry command syntax is invalid." "" "" "" "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BR.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)
call :ClearPrefix "BR."
set "BR.Initialized=1"
set "BR.Version=1.0.0"
set "BR.Protocol=1"
set "BR.Registry.Count=0"
set "BR.Registry.Sequence=0"
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BR."
exit /b 0

:Create
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.Create.Name=%~2"
set "BR.Internal.Create.Owner=%~3"
call :ValidateId "!BR.Internal.Create.Name!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryName "Registry names must be identifiers." "!BR.Internal.Create.Name!" "" "Id" "Letter followed by letters, digits, or underscores" "!BR.Internal.Create.Name!"
    exit /b 20
)
call :ValidateId "!BR.Internal.Create.Owner!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryOwner "Registry owners must be identifiers." "!BR.Internal.Create.Name!" "" "Id" "Letter followed by letters, digits, or underscores" "!BR.Internal.Create.Owner!"
    exit /b 20
)
for %%R in ("!BR.Internal.Create.Name!") do set "BR.Internal.Create.Exists=!BR.R.%%~R.__Exists!"
if "!BR.Internal.Create.Exists!"=="1" (
    call :SetError 30 RegistryAlreadyExists "A registry with this name already exists." "!BR.Internal.Create.Name!" "" "" "Unused registry name" "Existing registry"
    exit /b 30
)
set /a BR.Registry.Sequence+=1
set /a BR.Registry.Count+=1
set "BR.Internal.Create.Index=!BR.Registry.Sequence!"
set "BR.Registry.Index.!BR.Internal.Create.Index!.Name=!BR.Internal.Create.Name!"
set "BR.Registry.Index.!BR.Internal.Create.Index!.Active=1"
set "BR.R.!BR.Internal.Create.Name!.__Exists=1"
set "BR.R.!BR.Internal.Create.Name!.Index=!BR.Internal.Create.Index!"
set "BR.R.!BR.Internal.Create.Name!.Owner=!BR.Internal.Create.Owner!"
set "BR.R.!BR.Internal.Create.Name!.Entry.Count=0"
set "BR.R.!BR.Internal.Create.Name!.Entry.Sequence=0"
exit /b 0

:Set
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.Set.Registry=%~2"
set "BR.Internal.Set.Key=%~3"
set "BR.Internal.Set.Type=%~4"
set "BR.Internal.Set.Value=%~5"
call :RequireRegistry "!BR.Internal.Set.Registry!"
if errorlevel 1 exit /b !errorlevel!
call :ValidateKey "!BR.Internal.Set.Key!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryKey "Registry keys must be dotted identifiers." "!BR.Internal.Set.Registry!" "!BR.Internal.Set.Key!" "" "Identifier segments separated by dots" "!BR.Internal.Set.Key!"
    exit /b 20
)
call :NormalizeValue "!BR.Internal.Set.Type!" "!BR.Internal.Set.Value!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryValue "The value is invalid for the requested registry type." "!BR.Internal.Set.Registry!" "!BR.Internal.Set.Key!" "!BR.Internal.Set.Type!" "Valid typed value" "!BR.Internal.Set.Value!"
    exit /b 20
)
set "BR.Internal.Set.CanonicalType=!BR.Internal.NormalizedType!"
set "BR.Internal.Set.Normalized=!BR.Internal.NormalizedValue!"
for %%R in ("!BR.Internal.Set.Registry!") do for %%K in ("!BR.Internal.Set.Key!") do (
    set "BR.Internal.Set.Exists=!BR.R.%%~R.K.%%~K.__Exists!"
    set "BR.Internal.Set.ExistingType=!BR.R.%%~R.K.%%~K.Type!"
)
if "!BR.Internal.Set.Exists!"=="1" (
    if /i not "!BR.Internal.Set.ExistingType!"=="!BR.Internal.Set.CanonicalType!" (
        call :SetError 20 RegistryTypeMismatch "An existing registry key cannot change type." "!BR.Internal.Set.Registry!" "!BR.Internal.Set.Key!" "!BR.Internal.Set.CanonicalType!" "!BR.Internal.Set.ExistingType!" "!BR.Internal.Set.CanonicalType!"
        exit /b 20
    )
    set "BR.R.!BR.Internal.Set.Registry!.K.!BR.Internal.Set.Key!.Value=!BR.Internal.Set.Normalized!"
    exit /b 0
)
for %%R in ("!BR.Internal.Set.Registry!") do set "BR.Internal.Set.EntrySequence=!BR.R.%%~R.Entry.Sequence!"
set /a BR.Internal.Set.EntrySequence+=1
set "BR.R.!BR.Internal.Set.Registry!.Entry.Sequence=!BR.Internal.Set.EntrySequence!"
for %%R in ("!BR.Internal.Set.Registry!") do set "BR.Internal.Set.EntryCount=!BR.R.%%~R.Entry.Count!"
set /a BR.Internal.Set.EntryCount+=1
set "BR.R.!BR.Internal.Set.Registry!.Entry.Count=!BR.Internal.Set.EntryCount!"
set "BR.R.!BR.Internal.Set.Registry!.Entry.Index.!BR.Internal.Set.EntrySequence!.Key=!BR.Internal.Set.Key!"
set "BR.R.!BR.Internal.Set.Registry!.Entry.Index.!BR.Internal.Set.EntrySequence!.Active=1"
set "BR.R.!BR.Internal.Set.Registry!.K.!BR.Internal.Set.Key!.__Exists=1"
set "BR.R.!BR.Internal.Set.Registry!.K.!BR.Internal.Set.Key!.Index=!BR.Internal.Set.EntrySequence!"
set "BR.R.!BR.Internal.Set.Registry!.K.!BR.Internal.Set.Key!.Type=!BR.Internal.Set.CanonicalType!"
set "BR.R.!BR.Internal.Set.Registry!.K.!BR.Internal.Set.Key!.Value=!BR.Internal.Set.Normalized!"
exit /b 0

:Get
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.Get.Registry=%~2"
set "BR.Internal.Get.Key=%~3"
set "BR.Internal.Get.Output=%~4"
call :ValidateOutputVariable "!BR.Internal.Get.Output!"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "!BR.Internal.Get.Registry!" "!BR.Internal.Get.Key!" "" "Non-reserved identifier" "!BR.Internal.Get.Output!"
    exit /b 10
)
call :RequireRegistry "!BR.Internal.Get.Registry!"
if errorlevel 1 exit /b !errorlevel!
call :RequireKey "!BR.Internal.Get.Registry!" "!BR.Internal.Get.Key!"
if errorlevel 1 exit /b !errorlevel!
for %%R in ("!BR.Internal.Get.Registry!") do for %%K in ("!BR.Internal.Get.Key!") do set "BR.Internal.Get.Value=!BR.R.%%~R.K.%%~K.Value!"
set "!BR.Internal.Get.Output!=!BR.Internal.Get.Value!"
exit /b 0

:GetType
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.GetType.Registry=%~2"
set "BR.Internal.GetType.Key=%~3"
set "BR.Internal.GetType.Output=%~4"
call :ValidateOutputVariable "!BR.Internal.GetType.Output!"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "!BR.Internal.GetType.Registry!" "!BR.Internal.GetType.Key!" "" "Non-reserved identifier" "!BR.Internal.GetType.Output!"
    exit /b 10
)
call :RequireRegistry "!BR.Internal.GetType.Registry!"
if errorlevel 1 exit /b !errorlevel!
call :RequireKey "!BR.Internal.GetType.Registry!" "!BR.Internal.GetType.Key!"
if errorlevel 1 exit /b !errorlevel!
for %%R in ("!BR.Internal.GetType.Registry!") do for %%K in ("!BR.Internal.GetType.Key!") do set "BR.Internal.GetType.Value=!BR.R.%%~R.K.%%~K.Type!"
set "!BR.Internal.GetType.Output!=!BR.Internal.GetType.Value!"
exit /b 0

:Has
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.Has.Registry=%~2"
set "BR.Internal.Has.Key=%~3"
set "BR.Internal.Has.Output=%~4"
call :ValidateOutputVariable "!BR.Internal.Has.Output!"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "!BR.Internal.Has.Registry!" "!BR.Internal.Has.Key!" "" "Non-reserved identifier" "!BR.Internal.Has.Output!"
    exit /b 10
)
call :RequireRegistry "!BR.Internal.Has.Registry!"
if errorlevel 1 exit /b !errorlevel!
call :ValidateKey "!BR.Internal.Has.Key!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryKey "Registry keys must be dotted identifiers." "!BR.Internal.Has.Registry!" "!BR.Internal.Has.Key!" "" "Identifier segments separated by dots" "!BR.Internal.Has.Key!"
    exit /b 20
)
for %%R in ("!BR.Internal.Has.Registry!") do for %%K in ("!BR.Internal.Has.Key!") do set "BR.Internal.Has.Exists=!BR.R.%%~R.K.%%~K.__Exists!"
if "!BR.Internal.Has.Exists!"=="1" (
    set "!BR.Internal.Has.Output!=1"
) else (
    set "!BR.Internal.Has.Output!=0"
)
exit /b 0

:Remove
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.Remove.Registry=%~2"
set "BR.Internal.Remove.Key=%~3"
call :RequireRegistry "!BR.Internal.Remove.Registry!"
if errorlevel 1 exit /b !errorlevel!
call :RequireKey "!BR.Internal.Remove.Registry!" "!BR.Internal.Remove.Key!"
if errorlevel 1 exit /b !errorlevel!
for %%R in ("!BR.Internal.Remove.Registry!") do for %%K in ("!BR.Internal.Remove.Key!") do set "BR.Internal.Remove.Index=!BR.R.%%~R.K.%%~K.Index!"
set "BR.R.!BR.Internal.Remove.Registry!.Entry.Index.!BR.Internal.Remove.Index!.Active=0"
set "BR.R.!BR.Internal.Remove.Registry!.Entry.Index.!BR.Internal.Remove.Index!.Key="
set "BR.R.!BR.Internal.Remove.Registry!.K.!BR.Internal.Remove.Key!.__Exists="
set "BR.R.!BR.Internal.Remove.Registry!.K.!BR.Internal.Remove.Key!.Index="
set "BR.R.!BR.Internal.Remove.Registry!.K.!BR.Internal.Remove.Key!.Type="
set "BR.R.!BR.Internal.Remove.Registry!.K.!BR.Internal.Remove.Key!.Value="
for %%R in ("!BR.Internal.Remove.Registry!") do set "BR.Internal.Remove.Count=!BR.R.%%~R.Entry.Count!"
set /a BR.Internal.Remove.Count-=1
set "BR.R.!BR.Internal.Remove.Registry!.Entry.Count=!BR.Internal.Remove.Count!"
exit /b 0

:Clear
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.Clear.Registry=%~2"
call :RequireRegistry "!BR.Internal.Clear.Registry!"
if errorlevel 1 exit /b !errorlevel!
for %%R in ("!BR.Internal.Clear.Registry!") do set "BR.Internal.Clear.Sequence=!BR.R.%%~R.Entry.Sequence!"
call :ClearPrefix "BR.R.!BR.Internal.Clear.Registry!.Entry."
call :ClearPrefix "BR.R.!BR.Internal.Clear.Registry!.K."
set "BR.R.!BR.Internal.Clear.Registry!.Entry.Count=0"
set "BR.R.!BR.Internal.Clear.Registry!.Entry.Sequence=!BR.Internal.Clear.Sequence!"
exit /b 0

:Release
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.Release.Registry=%~2"
call :RequireRegistry "!BR.Internal.Release.Registry!"
if errorlevel 1 exit /b !errorlevel!
call :ReleaseRegistryInternal "!BR.Internal.Release.Registry!"
exit /b 0

:ReleaseOwner
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.ReleaseOwner.Owner=%~2"
call :ValidateId "!BR.Internal.ReleaseOwner.Owner!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryOwner "Registry owners must be identifiers." "" "" "Id" "Letter followed by letters, digits, or underscores" "!BR.Internal.ReleaseOwner.Owner!"
    exit /b 20
)
set "BR.Internal.ReleaseOwner.Index=1"
:ReleaseOwner.Next
if !BR.Internal.ReleaseOwner.Index! GTR !BR.Registry.Sequence! exit /b 0
for %%I in (!BR.Internal.ReleaseOwner.Index!) do (
    set "BR.Internal.ReleaseOwner.Active=!BR.Registry.Index.%%I.Active!"
    set "BR.Internal.ReleaseOwner.Name=!BR.Registry.Index.%%I.Name!"
)
if not "!BR.Internal.ReleaseOwner.Active!"=="1" goto :ReleaseOwner.Advance
for %%R in ("!BR.Internal.ReleaseOwner.Name!") do set "BR.Internal.ReleaseOwner.Candidate=!BR.R.%%~R.Owner!"
if /i "!BR.Internal.ReleaseOwner.Candidate!"=="!BR.Internal.ReleaseOwner.Owner!" call :ReleaseRegistryInternal "!BR.Internal.ReleaseOwner.Name!"
:ReleaseOwner.Advance
set /a BR.Internal.ReleaseOwner.Index+=1
goto :ReleaseOwner.Next

:List
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
if "!BR.Registry.Count!"=="0" (
    echo No registries.
    exit /b 0
)
set "BR.Internal.List.Index=1"
:List.Next
if !BR.Internal.List.Index! GTR !BR.Registry.Sequence! exit /b 0
for %%I in (!BR.Internal.List.Index!) do (
    set "BR.Internal.List.Active=!BR.Registry.Index.%%I.Active!"
    set "BR.Internal.List.Name=!BR.Registry.Index.%%I.Name!"
)
if not "!BR.Internal.List.Active!"=="1" goto :List.Advance
for %%R in ("!BR.Internal.List.Name!") do (
    set "BR.Internal.List.Owner=!BR.R.%%~R.Owner!"
    set "BR.Internal.List.Count=!BR.R.%%~R.Entry.Count!"
)
echo !BR.Internal.List.Name! [owner=!BR.Internal.List.Owner!, entries=!BR.Internal.List.Count!]
:List.Advance
set /a BR.Internal.List.Index+=1
goto :List.Next

:ListKeys
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.ListKeys.Registry=%~2"
call :RequireRegistry "!BR.Internal.ListKeys.Registry!"
if errorlevel 1 exit /b !errorlevel!
for %%R in ("!BR.Internal.ListKeys.Registry!") do (
    set "BR.Internal.ListKeys.Count=!BR.R.%%~R.Entry.Count!"
    set "BR.Internal.ListKeys.Sequence=!BR.R.%%~R.Entry.Sequence!"
)
if "!BR.Internal.ListKeys.Count!"=="0" (
    echo No keys in registry !BR.Internal.ListKeys.Registry!.
    exit /b 0
)
set "BR.Internal.ListKeys.Index=1"
:ListKeys.Next
if !BR.Internal.ListKeys.Index! GTR !BR.Internal.ListKeys.Sequence! exit /b 0
for %%I in (!BR.Internal.ListKeys.Index!) do for %%R in ("!BR.Internal.ListKeys.Registry!") do (
    set "BR.Internal.ListKeys.Active=!BR.R.%%~R.Entry.Index.%%I.Active!"
    set "BR.Internal.ListKeys.Key=!BR.R.%%~R.Entry.Index.%%I.Key!"
)
if not "!BR.Internal.ListKeys.Active!"=="1" goto :ListKeys.Advance
for %%R in ("!BR.Internal.ListKeys.Registry!") do for %%K in ("!BR.Internal.ListKeys.Key!") do (
    set "BR.Internal.ListKeys.Type=!BR.R.%%~R.K.%%~K.Type!"
    set "BR.Internal.ListKeys.Value=!BR.R.%%~R.K.%%~K.Value!"
)
echo !BR.Internal.ListKeys.Key! [!BR.Internal.ListKeys.Type!]=!BR.Internal.ListKeys.Value!
:ListKeys.Advance
set /a BR.Internal.ListKeys.Index+=1
goto :ListKeys.Next

:GetStat
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BR.Internal.GetStat.Name=%~2"
set "BR.Internal.GetStat.Registry=%~3"
set "BR.Internal.GetStat.Output=%~4"
call :ValidateOutputVariable "!BR.Internal.GetStat.Output!"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "!BR.Internal.GetStat.Registry!" "" "" "Non-reserved identifier" "!BR.Internal.GetStat.Output!"
    exit /b 10
)
if /i "!BR.Internal.GetStat.Name!"=="RegistryCount" (
    set "!BR.Internal.GetStat.Output!=!BR.Registry.Count!"
    exit /b 0
)
if /i "!BR.Internal.GetStat.Name!"=="EntryCount" (
    call :RequireRegistry "!BR.Internal.GetStat.Registry!"
    if errorlevel 1 exit /b !errorlevel!
    for %%R in ("!BR.Internal.GetStat.Registry!") do set "BR.Internal.GetStat.Value=!BR.R.%%~R.Entry.Count!"
    set "!BR.Internal.GetStat.Output!=!BR.Internal.GetStat.Value!"
    exit /b 0
)
call :SetError 20 UnknownRegistryStatistic "Unknown BatchRegistry statistic." "!BR.Internal.GetStat.Registry!" "" "" "RegistryCount or EntryCount" "!BR.Internal.GetStat.Name!"
exit /b 20

:ReadLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BR.Internal.ReadError.Field=%~2"
set "BR.Internal.ReadError.Output=%~3"
call :ValidateOutputVariable "!BR.Internal.ReadError.Output!"
if errorlevel 1 exit /b 10
call :ValidateErrorField "!BR.Internal.ReadError.Field!"
if errorlevel 1 exit /b 20
for %%F in ("!BR.Internal.ReadError.Field!") do set "BR.Internal.ReadError.Value=!BR.LastError.%%~F!"
set "!BR.Internal.ReadError.Output!=!BR.Internal.ReadError.Value!"
exit /b 0

:PrintLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
if "!BR.LastError.Code!"=="0" (
    echo No BatchRegistry error.
    exit /b 0
)
echo BatchRegistry error !BR.LastError.Code!: !BR.LastError.Kind!
echo Message: !BR.LastError.Message!
if defined BR.LastError.Registry echo Registry: !BR.LastError.Registry!
if defined BR.LastError.Key echo Key: !BR.LastError.Key!
if defined BR.LastError.Type echo Type: !BR.LastError.Type!
if defined BR.LastError.Expected echo Expected: !BR.LastError.Expected!
if defined BR.LastError.Actual echo Actual: !BR.LastError.Actual!
exit /b 0

:ClearLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
exit /b 0

:ReleaseRegistryInternal
set "BR.Internal.ReleaseData.Name=%~1"
for %%R in ("!BR.Internal.ReleaseData.Name!") do set "BR.Internal.ReleaseData.Index=!BR.R.%%~R.Index!"
call :ClearPrefix "BR.R.!BR.Internal.ReleaseData.Name!."
set "BR.Registry.Index.!BR.Internal.ReleaseData.Index!.Active=0"
set "BR.Registry.Index.!BR.Internal.ReleaseData.Index!.Name="
set /a BR.Registry.Count-=1
exit /b 0

:RequireInitialized
if defined BR.Initialized exit /b 0
call :SetError 50 RegistryNotInitialized "BatchRegistry is not initialized." "" "" "" "Initialized registry runtime" "Not initialized"
exit /b 50

:RequireRegistry
set "BR.Internal.RequireRegistry.Name=%~1"
call :ValidateId "!BR.Internal.RequireRegistry.Name!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryName "Registry names must be identifiers." "!BR.Internal.RequireRegistry.Name!" "" "Id" "Letter followed by letters, digits, or underscores" "!BR.Internal.RequireRegistry.Name!"
    exit /b 20
)
for %%R in ("!BR.Internal.RequireRegistry.Name!") do set "BR.Internal.RequireRegistry.Exists=!BR.R.%%~R.__Exists!"
if "!BR.Internal.RequireRegistry.Exists!"=="1" exit /b 0
call :SetError 30 RegistryNotFound "The requested registry does not exist." "!BR.Internal.RequireRegistry.Name!" "" "" "Existing registry" "Missing registry"
exit /b 30

:RequireKey
set "BR.Internal.RequireKey.Registry=%~1"
set "BR.Internal.RequireKey.Key=%~2"
call :ValidateKey "!BR.Internal.RequireKey.Key!"
if errorlevel 1 (
    call :SetError 20 InvalidRegistryKey "Registry keys must be dotted identifiers." "!BR.Internal.RequireKey.Registry!" "!BR.Internal.RequireKey.Key!" "" "Identifier segments separated by dots" "!BR.Internal.RequireKey.Key!"
    exit /b 20
)
for %%R in ("!BR.Internal.RequireKey.Registry!") do for %%K in ("!BR.Internal.RequireKey.Key!") do set "BR.Internal.RequireKey.Exists=!BR.R.%%~R.K.%%~K.__Exists!"
if "!BR.Internal.RequireKey.Exists!"=="1" exit /b 0
call :SetError 30 RegistryKeyNotFound "The requested registry key does not exist." "!BR.Internal.RequireKey.Registry!" "!BR.Internal.RequireKey.Key!" "" "Existing registry key" "Missing key"
exit /b 30

:NormalizeValue
set "BR.Internal.Normalize.RequestedType=%~1"
set "BR.Internal.Normalize.Input=%~2"
if /i "!BR.Internal.Normalize.RequestedType!"=="String" (
    set "BR.Internal.NormalizedType=String"
    set "BR.Internal.NormalizedValue=!BR.Internal.Normalize.Input!"
    exit /b 0
)
if /i "!BR.Internal.Normalize.RequestedType!"=="Int" (
    call :NormalizeInt32 "!BR.Internal.Normalize.Input!"
    if errorlevel 1 exit /b 1
    set "BR.Internal.NormalizedType=Int"
    set "BR.Internal.NormalizedValue=!BR.Internal.NumberNormalized!"
    exit /b 0
)
if /i "!BR.Internal.Normalize.RequestedType!"=="UInt" (
    call :NormalizeUInt32 "!BR.Internal.Normalize.Input!"
    if errorlevel 1 exit /b 1
    set "BR.Internal.NormalizedType=UInt"
    set "BR.Internal.NormalizedValue=!BR.Internal.NumberNormalized!"
    exit /b 0
)
if /i "!BR.Internal.Normalize.RequestedType!"=="Bool" (
    call :NormalizeBool "!BR.Internal.Normalize.Input!"
    if errorlevel 1 exit /b 1
    set "BR.Internal.NormalizedType=Bool"
    set "BR.Internal.NormalizedValue=!BR.Internal.BoolNormalized!"
    exit /b 0
)
if /i "!BR.Internal.Normalize.RequestedType!"=="Id" (
    call :ValidateId "!BR.Internal.Normalize.Input!"
    if errorlevel 1 exit /b 1
    set "BR.Internal.NormalizedType=Id"
    set "BR.Internal.NormalizedValue=!BR.Internal.Normalize.Input!"
    exit /b 0
)
exit /b 1

:NormalizeInt32
set "BR.Internal.Number.Input=%~1"
set "BR.Internal.Number.Negative=0"
if not defined BR.Internal.Number.Input exit /b 1
if "!BR.Internal.Number.Input:~0,1!"=="-" (
    set "BR.Internal.Number.Negative=1"
    set "BR.Internal.Number.Digits=!BR.Internal.Number.Input:~1!"
) else (
    set "BR.Internal.Number.Digits=!BR.Internal.Number.Input!"
)
if not defined BR.Internal.Number.Digits exit /b 1
call :ValidateDigits "!BR.Internal.Number.Digits!"
if errorlevel 1 exit /b 1
call :StripLeadingZeroes "!BR.Internal.Number.Digits!"
set "BR.Internal.Number.Digits=!BR.Internal.StrippedDigits!"
if "!BR.Internal.Number.Negative!"=="1" (
    set "BR.Internal.Number.Limit=2147483648"
) else (
    set "BR.Internal.Number.Limit=2147483647"
)
call :CheckDecimalLimit "!BR.Internal.Number.Digits!" "!BR.Internal.Number.Limit!"
if errorlevel 1 exit /b 1
if "!BR.Internal.Number.Digits!"=="0" (
    set "BR.Internal.NumberNormalized=0"
) else (
    if "!BR.Internal.Number.Negative!"=="1" (
        set "BR.Internal.NumberNormalized=-!BR.Internal.Number.Digits!"
    ) else (
        set "BR.Internal.NumberNormalized=!BR.Internal.Number.Digits!"
    )
)
exit /b 0

:NormalizeUInt32
set "BR.Internal.Number.Input=%~1"
if not defined BR.Internal.Number.Input exit /b 1
if "!BR.Internal.Number.Input:~0,1!"=="-" exit /b 1
set "BR.Internal.Number.Digits=!BR.Internal.Number.Input!"
call :ValidateDigits "!BR.Internal.Number.Digits!"
if errorlevel 1 exit /b 1
call :StripLeadingZeroes "!BR.Internal.Number.Digits!"
set "BR.Internal.Number.Digits=!BR.Internal.StrippedDigits!"
call :CheckDecimalLimit "!BR.Internal.Number.Digits!" "2147483647"
if errorlevel 1 exit /b 1
set "BR.Internal.NumberNormalized=!BR.Internal.Number.Digits!"
exit /b 0

:NormalizeBool
set "BR.Internal.Bool.Input=%~1"
if /i "!BR.Internal.Bool.Input!"=="1" (
    set "BR.Internal.BoolNormalized=1"
    exit /b 0
)
if /i "!BR.Internal.Bool.Input!"=="true" (
    set "BR.Internal.BoolNormalized=1"
    exit /b 0
)
if /i "!BR.Internal.Bool.Input!"=="yes" (
    set "BR.Internal.BoolNormalized=1"
    exit /b 0
)
if /i "!BR.Internal.Bool.Input!"=="on" (
    set "BR.Internal.BoolNormalized=1"
    exit /b 0
)
if /i "!BR.Internal.Bool.Input!"=="0" (
    set "BR.Internal.BoolNormalized=0"
    exit /b 0
)
if /i "!BR.Internal.Bool.Input!"=="false" (
    set "BR.Internal.BoolNormalized=0"
    exit /b 0
)
if /i "!BR.Internal.Bool.Input!"=="no" (
    set "BR.Internal.BoolNormalized=0"
    exit /b 0
)
if /i "!BR.Internal.Bool.Input!"=="off" (
    set "BR.Internal.BoolNormalized=0"
    exit /b 0
)
exit /b 1

:ValidateDigits
set "BR.Internal.Digits.Work=%~1"
if not defined BR.Internal.Digits.Work exit /b 1
:ValidateDigits.Next
if not defined BR.Internal.Digits.Work exit /b 0
set "BR.Internal.Digits.Character=!BR.Internal.Digits.Work:~0,1!"
call :ValidateDigitCharacter "!BR.Internal.Digits.Character!"
if errorlevel 1 exit /b 1
set "BR.Internal.Digits.Work=!BR.Internal.Digits.Work:~1!"
goto :ValidateDigits.Next

:StripLeadingZeroes
set "BR.Internal.Strip.Work=%~1"
:StripLeadingZeroes.Next
if "!BR.Internal.Strip.Work!"=="0" goto :StripLeadingZeroes.Done
if not "!BR.Internal.Strip.Work:~0,1!"=="0" goto :StripLeadingZeroes.Done
set "BR.Internal.Strip.Work=!BR.Internal.Strip.Work:~1!"
goto :StripLeadingZeroes.Next
:StripLeadingZeroes.Done
set "BR.Internal.StrippedDigits=!BR.Internal.Strip.Work!"
exit /b 0

:CheckDecimalLimit
set "BR.Internal.Limit.Value=%~1"
set "BR.Internal.Limit.Maximum=%~2"
set "BR.Internal.Limit.Work=!BR.Internal.Limit.Value!"
set "BR.Internal.Limit.Length=0"
:CheckDecimalLimit.Length
if not defined BR.Internal.Limit.Work goto :CheckDecimalLimit.LengthDone
set /a BR.Internal.Limit.Length+=1
set "BR.Internal.Limit.Work=!BR.Internal.Limit.Work:~1!"
goto :CheckDecimalLimit.Length
:CheckDecimalLimit.LengthDone
if !BR.Internal.Limit.Length! LSS 10 exit /b 0
if !BR.Internal.Limit.Length! GTR 10 exit /b 1
set "BR.Internal.Limit.Work=!BR.Internal.Limit.Value!"
set "BR.Internal.Limit.MaxWork=!BR.Internal.Limit.Maximum!"
:CheckDecimalLimit.Compare
if not defined BR.Internal.Limit.Work exit /b 0
set "BR.Internal.Limit.Digit=!BR.Internal.Limit.Work:~0,1!"
set "BR.Internal.Limit.MaxDigit=!BR.Internal.Limit.MaxWork:~0,1!"
if !BR.Internal.Limit.Digit! LSS !BR.Internal.Limit.MaxDigit! exit /b 0
if !BR.Internal.Limit.Digit! GTR !BR.Internal.Limit.MaxDigit! exit /b 1
set "BR.Internal.Limit.Work=!BR.Internal.Limit.Work:~1!"
set "BR.Internal.Limit.MaxWork=!BR.Internal.Limit.MaxWork:~1!"
goto :CheckDecimalLimit.Compare

:ValidateKey
set "BR.Internal.Key.Value=%~1"
if not defined BR.Internal.Key.Value exit /b 1
if not "!BR.Internal.Key.Value:~128,1!"=="" exit /b 1
if "!BR.Internal.Key.Value:~0,1!"=="." exit /b 1
if "!BR.Internal.Key.Value:~-1!"=="." exit /b 1
if not "!BR.Internal.Key.Value:..=!"=="!BR.Internal.Key.Value!" exit /b 1
set "BR.Internal.Key.Work=!BR.Internal.Key.Value!"
:ValidateKey.Next
set "BR.Internal.Key.Segment="
set "BR.Internal.Key.Rest="
for /f "tokens=1,* delims=." %%A in ("!BR.Internal.Key.Work!") do (
    set "BR.Internal.Key.Segment=%%~A"
    set "BR.Internal.Key.Rest=%%~B"
)
if not defined BR.Internal.Key.Segment exit /b 1
call :ValidateId "!BR.Internal.Key.Segment!"
if errorlevel 1 exit /b 1
if not defined BR.Internal.Key.Rest exit /b 0
set "BR.Internal.Key.Work=!BR.Internal.Key.Rest!"
goto :ValidateKey.Next

:ValidateId
set "BR.Internal.Id.Value=%~1"
if not defined BR.Internal.Id.Value exit /b 1
if not "!BR.Internal.Id.Value:~64,1!"=="" exit /b 1
set "BR.Internal.Id.Character=!BR.Internal.Id.Value:~0,1!"
call :ValidateAlphaCharacter "!BR.Internal.Id.Character!"
if errorlevel 1 exit /b 1
set "BR.Internal.Id.Work=!BR.Internal.Id.Value:~1!"
:ValidateId.Next
if not defined BR.Internal.Id.Work exit /b 0
set "BR.Internal.Id.Character=!BR.Internal.Id.Work:~0,1!"
call :ValidateAlphaCharacter "!BR.Internal.Id.Character!"
if not errorlevel 1 goto :ValidateId.Advance
call :ValidateDigitCharacter "!BR.Internal.Id.Character!"
if not errorlevel 1 goto :ValidateId.Advance
if "!BR.Internal.Id.Character!"=="_" goto :ValidateId.Advance
exit /b 1
:ValidateId.Advance
set "BR.Internal.Id.Work=!BR.Internal.Id.Work:~1!"
goto :ValidateId.Next

:ValidateAlphaCharacter
set "BR.Internal.Character=%~1"
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" %%A in ("!BR.Internal.Character!") do exit /b 1
exit /b 0

:ValidateDigitCharacter
set "BR.Internal.Character=%~1"
for /f "delims=0123456789" %%A in ("!BR.Internal.Character!") do exit /b 1
exit /b 0

:ValidateOutputVariable
set "BR.Internal.Output.Value=%~1"
call :ValidateId "!BR.Internal.Output.Value!"
if errorlevel 1 exit /b 1
if /i "!BR.Internal.Output.Value:~0,3!"=="BR." exit /b 1
for %%V in (PATH ERRORLEVEL RANDOM TEMP TMP COMSPEC CD CMDEXTVERSION DATE TIME) do if /i "!BR.Internal.Output.Value!"=="%%V" exit /b 1
exit /b 0

:ValidateErrorField
for %%F in (Code Kind Message Registry Key Type Expected Actual) do if /i "%~1"=="%%F" exit /b 0
exit /b 1

:ClearLastErrorInternal
set "BR.LastError.Code=0"
set "BR.LastError.Kind=None"
set "BR.LastError.Message="
set "BR.LastError.Registry="
set "BR.LastError.Key="
set "BR.LastError.Type="
set "BR.LastError.Expected="
set "BR.LastError.Actual="
exit /b 0

:SetError
set "BR.LastError.Code=%~1"
set "BR.LastError.Kind=%~2"
set "BR.LastError.Message=%~3"
set "BR.LastError.Registry=%~4"
set "BR.LastError.Key=%~5"
set "BR.LastError.Type=%~6"
set "BR.LastError.Expected=%~7"
set "BR.LastError.Actual=%~8"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
