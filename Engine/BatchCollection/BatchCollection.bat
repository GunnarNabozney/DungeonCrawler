@echo off

rem BatchCollection.bat
rem Project-agnostic ordered collections, quantities, slots, constraints, and transfers.
rem Version 1.0.0 - protocol 1.
rem Requirement: caller must enable command extensions and delayed expansion.
rem
rem Values are restricted metadata tokens. Arbitrary text belongs in BatchText handles.
rem Collection entry records are owned by this component; external payload handles remain caller-owned.

set "BC.Internal.DelayedProbe=1"
if not "!BC.Internal.DelayedProbe!"=="1" (
    echo BatchCollection requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="create" goto :Readable.Create
if /i "%~1"=="set" goto :Readable.Set
if /i "%~1"=="add" goto :Readable.Add
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="get" goto :Readable.Get
if /i "%~1"=="remove" goto :Readable.Remove
if /i "%~1"=="transfer" goto :Readable.Transfer
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="clear" goto :Readable.Clear
if /i "%~1"=="release" goto :Readable.Release

if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":Create" goto :Create
if /i "%~1"==":SetPolicy" goto :SetPolicy
if /i "%~1"==":Add" goto :Add
if /i "%~1"==":Insert" goto :Insert
if /i "%~1"==":GetAt" goto :GetAt
if /i "%~1"==":Find" goto :Find
if /i "%~1"==":Contains" goto :Contains
if /i "%~1"==":Move" goto :Move
if /i "%~1"==":ReadEntry" goto :ReadEntry
if /i "%~1"==":ReadCollection" goto :ReadCollection
if /i "%~1"==":SetQuantity" goto :SetQuantity
if /i "%~1"==":RemoveQuantity" goto :RemoveQuantity
if /i "%~1"==":RemoveEntry" goto :RemoveEntry
if /i "%~1"==":Split" goto :Split
if /i "%~1"==":Merge" goto :Merge
if /i "%~1"==":TransferEntry" goto :TransferEntry
if /i "%~1"==":TransferQuantity" goto :TransferQuantity
if /i "%~1"==":DefineSlot" goto :DefineSlot
if /i "%~1"==":AssignSlot" goto :AssignSlot
if /i "%~1"==":UnassignSlot" goto :UnassignSlot
if /i "%~1"==":GetSlot" goto :GetSlot
if /i "%~1"==":ListEntries" goto :ListEntries
if /i "%~1"==":ListSlots" goto :ListSlots
if /i "%~1"==":ClearCollection" goto :ClearCollection
if /i "%~1"==":Release" goto :Release
if /i "%~1"==":GetStat" goto :GetStat
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :EnsureInitialized
call :SetError 10 UnknownCollectionCommand "Unknown BatchCollection command." Dispatch "" "" Command "Known BatchCollection command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="collections" goto :Readable.Syntax
call "%~f0" :Initialize
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="collections" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Create
if /i not "%~2"=="collection" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :Create "%~3" "%~5"
exit /b !errorlevel!

:Readable.Set
if /i not "%~2"=="collection" goto :Readable.Syntax
if /i not "%~4"=="policy" goto :Readable.Syntax
if /i not "%~6"=="to" goto :Readable.Syntax
call "%~f0" :SetPolicy "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.Add
if /i not "%~2"=="value" goto :Readable.Syntax
if /i not "%~4"=="to" goto :Readable.Syntax
if /i not "%~5"=="collection" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :Add "%~6" Value "%~3" "" 1 0 "%~8"
exit /b !errorlevel!

:Readable.Read
if /i "%~2"=="entry" goto :Readable.ReadEntry
if /i "%~2"=="collection" goto :Readable.ReadCollection
if /i "%~2"=="last" goto :Readable.ReadLastError
goto :Readable.Syntax

:Readable.ReadEntry
if /i not "%~4"=="field" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :ReadEntry "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.ReadCollection
if /i not "%~4"=="field" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :ReadCollection "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.ReadLastError
if /i not "%~3"=="error" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :ReadLastError "%~4" "%~6"
exit /b !errorlevel!

:Readable.Get
if /i "%~2"=="entry" goto :Readable.GetEntry
if /i "%~2"=="statistic" goto :Readable.GetStatistic
goto :Readable.Syntax

:Readable.GetEntry
if /i not "%~3"=="at" goto :Readable.Syntax
if /i not "%~5"=="from" goto :Readable.Syntax
if /i not "%~6"=="collection" goto :Readable.Syntax
if /i not "%~8"=="into" goto :Readable.Syntax
call "%~f0" :GetAt "%~7" "%~4" "%~9"
exit /b !errorlevel!

:Readable.GetStatistic
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :GetStat "%~3" "%~5"
exit /b !errorlevel!

:Readable.Remove
if /i not "%~2"=="entry" goto :Readable.Syntax
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~5"=="collection" goto :Readable.Syntax
call "%~f0" :RemoveEntry "%~6" "%~3"
exit /b !errorlevel!

:Readable.Transfer
if /i not "%~2"=="entry" goto :Readable.Syntax
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~5"=="collection" goto :Readable.Syntax
if /i not "%~7"=="to" goto :Readable.Syntax
if /i not "%~8"=="collection" goto :Readable.Syntax
call "%~f0" :TransferEntry "%~6" "%~3" "%~9" BCReadableTransfer
exit /b !errorlevel!

:Readable.Show
if /i "%~2"=="entries" (
    if /i not "%~3"=="in" goto :Readable.Syntax
    if /i not "%~4"=="collection" goto :Readable.Syntax
    call "%~f0" :ListEntries "%~5"
    exit /b !errorlevel!
)
if /i "%~2"=="slots" (
    if /i not "%~3"=="in" goto :Readable.Syntax
    if /i not "%~4"=="collection" goto :Readable.Syntax
    call "%~f0" :ListSlots "%~5"
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    call "%~f0" :PrintLastError
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Clear
if /i "%~2"=="collection" (
    call "%~f0" :ClearCollection "%~3"
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    call "%~f0" :ClearLastError
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Release
if /i not "%~2"=="collection" goto :Readable.Syntax
call "%~f0" :Release "%~3"
exit /b !errorlevel!

:Readable.Syntax
call :EnsureInitialized
call :SetError 10 InvalidCollectionSyntax "BatchCollection command syntax is invalid." Readable "" "" Syntax "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BC.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)

call :ClearPrefix "BC."
set "BC.Validator=%~dp0..\BatchValidate\BatchValidate.bat"
set "BC.Math=%~dp0..\BatchMath\BatchMath.bat"

if not exist "!BC.Validator!" (
    call :SetError 50 ValidationDependencyMissing "BatchValidate is required by BatchCollection." Initialize "" "" Dependency "Existing BatchValidate component" "Missing"
    exit /b 50
)

if not exist "!BC.Math!" (
    call :SetError 50 MathDependencyMissing "BatchMath is required by BatchCollection." Initialize "" "" Dependency "Existing BatchMath component" "Missing"
    exit /b 50
)

call "!BC.Math!" :Initialize
if errorlevel 1 (
    call :SetError 50 MathDependencyFailed "BatchMath could not be initialized." Initialize "" "" Dependency "Initialized BatchMath" "Initialization failed"
    exit /b 50
)

set "BC.Initialized=1"
set "BC.Version=1.0.0"
set "BC.Protocol=1"
set "BC.Collection.Sequence=0"
set "BC.Collection.Count=0"
set "BC.Entry.Sequence=0"
set "BC.Entry.Count=0"
set "BC.Slot.Count=0"
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BC."
exit /b 0

:Create
call :BeginOperation Create
if errorlevel 1 exit /b !errorlevel!
call :ValidateIdentifier "%~2" Name
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Create.Name=!BC.Internal.Validated!"
if defined BC.Name.!BC.Internal.Create.Name! (
    call :SetError 30 CollectionNameAlreadyExists "A collection with this name already exists." Create "" "" Name "Unused collection name" "!BC.Internal.Create.Name!"
    exit /b 30
)
call :PrepareOutput "%~3" Create
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Create.Output=!BC.Internal.Output!"

set /a BC.Collection.Sequence+=1
set /a BC.Collection.Count+=1
set "BC.Internal.Create.Handle=BC!BC.Collection.Sequence!"

set "BC.C.!BC.Internal.Create.Handle!.__Exists=1"
set "BC.C.!BC.Internal.Create.Handle!.Name=!BC.Internal.Create.Name!"
set "BC.C.!BC.Internal.Create.Handle!.EntryKind=Any"
set "BC.C.!BC.Internal.Create.Handle!.Duplicates=Allow"
set "BC.C.!BC.Internal.Create.Handle!.Comparison=CaseSensitive"
set "BC.C.!BC.Internal.Create.Handle!.MergePolicy=Never"
set "BC.C.!BC.Internal.Create.Handle!.CountLimit=0"
set "BC.C.!BC.Internal.Create.Handle!.MeasureLimit=0"
set "BC.C.!BC.Internal.Create.Handle!.Entry.Count=0"
set "BC.C.!BC.Internal.Create.Handle!.TotalQuantity=0"
set "BC.C.!BC.Internal.Create.Handle!.TotalMeasure=0"
set "BC.C.!BC.Internal.Create.Handle!.Slot.Count=0"
set "BC.C.!BC.Internal.Create.Handle!.Slot.Sequence=0"
set "BC.C.!BC.Internal.Create.Handle!.ReferenceCount=0"
set "BC.Name.!BC.Internal.Create.Name!=!BC.Internal.Create.Handle!"

for %%O in ("!BC.Internal.Create.Output!") do set "%%~O=!BC.Internal.Create.Handle!"
exit /b 0

:SetPolicy
call :BeginOperation SetPolicy
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" SetPolicy
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Policy.Collection=%~2"
call :ValidateEnum "%~3" "EntryKind,Duplicates,Comparison,MergePolicy,CountLimit,MeasureLimit" Policy
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Policy.Name=!BC.Internal.Validated!"
set "BC.Internal.Policy.Value=%~4"

if /i "!BC.Internal.Policy.Name!"=="EntryKind" goto :SetPolicy.EntryKind
if /i "!BC.Internal.Policy.Name!"=="Duplicates" goto :SetPolicy.Duplicates
if /i "!BC.Internal.Policy.Name!"=="Comparison" goto :SetPolicy.Comparison
if /i "!BC.Internal.Policy.Name!"=="MergePolicy" goto :SetPolicy.MergePolicy
if /i "!BC.Internal.Policy.Name!"=="CountLimit" goto :SetPolicy.CountLimit
if /i "!BC.Internal.Policy.Name!"=="MeasureLimit" goto :SetPolicy.MeasureLimit

call :SetError 20 InvalidPolicy "The collection policy is not supported." SetPolicy "!BC.Internal.Policy.Collection!" "" Policy "Supported policy" "!BC.Internal.Policy.Name!"
exit /b 20

:SetPolicy.EntryKind
call :RequireEmptyForPolicy "!BC.Internal.Policy.Collection!" EntryKind
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "!BC.Internal.Policy.Value!" "Any,Value,Object,Collection" EntryKind
if errorlevel 1 exit /b !errorlevel!
set "BC.C.!BC.Internal.Policy.Collection!.EntryKind=!BC.Internal.Validated!"
exit /b 0

:SetPolicy.Duplicates
call :RequireEmptyForPolicy "!BC.Internal.Policy.Collection!" Duplicates
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "!BC.Internal.Policy.Value!" "Allow,Reject" Duplicates
if errorlevel 1 exit /b !errorlevel!
set "BC.C.!BC.Internal.Policy.Collection!.Duplicates=!BC.Internal.Validated!"
exit /b 0

:SetPolicy.Comparison
call :RequireEmptyForPolicy "!BC.Internal.Policy.Collection!" Comparison
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "!BC.Internal.Policy.Value!" "CaseSensitive,CaseInsensitive" Comparison
if errorlevel 1 exit /b !errorlevel!
set "BC.C.!BC.Internal.Policy.Collection!.Comparison=!BC.Internal.Validated!"
exit /b 0

:SetPolicy.MergePolicy
call :RequireEmptyForPolicy "!BC.Internal.Policy.Collection!" MergePolicy
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "!BC.Internal.Policy.Value!" "Never,SameValue,SameDefinition" MergePolicy
if errorlevel 1 exit /b !errorlevel!
set "BC.C.!BC.Internal.Policy.Collection!.MergePolicy=!BC.Internal.Validated!"
exit /b 0

:SetPolicy.CountLimit
call :ValidateUnsigned "!BC.Internal.Policy.Value!" CountLimit
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Policy.Normalized=!BC.Internal.Validated!"
if not "!BC.Internal.Policy.Normalized!"=="0" (
    if !BC.C.%~2.Entry.Count! GTR !BC.Internal.Policy.Normalized! (
        call :SetError 30 CapacityBelowUsage "The count limit cannot be lower than current usage." SetPolicy "%~2" "" CountLimit "!BC.C.%~2.Entry.Count! or greater" "!BC.Internal.Policy.Normalized!"
        exit /b 30
    )
)
set "BC.C.%~2.CountLimit=!BC.Internal.Policy.Normalized!"
exit /b 0

:SetPolicy.MeasureLimit
call :ValidateUnsigned "!BC.Internal.Policy.Value!" MeasureLimit
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Policy.Normalized=!BC.Internal.Validated!"
if not "!BC.Internal.Policy.Normalized!"=="0" (
    if !BC.C.%~2.TotalMeasure! GTR !BC.Internal.Policy.Normalized! (
        call :SetError 30 CapacityBelowUsage "The measure limit cannot be lower than current usage." SetPolicy "%~2" "" MeasureLimit "!BC.C.%~2.TotalMeasure! or greater" "!BC.Internal.Policy.Normalized!"
        exit /b 30
    )
)
set "BC.C.%~2.MeasureLimit=!BC.Internal.Policy.Normalized!"
exit /b 0

:Add
call "%~f0" :Insert "%~2" 0 "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
exit /b !errorlevel!

:Insert
call :BeginOperation Insert
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" Insert
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.Collection=%~2"

call :ValidateUnsigned "%~3" Index
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.Index=!BC.Internal.Validated!"
set "BC.Internal.Insert.Count=!BC.C.%~2.Entry.Count!"

if "!BC.Internal.Insert.Index!"=="0" (
    set /a BC.Internal.Insert.Index=BC.Internal.Insert.Count+1
)

set /a BC.Internal.Insert.Maximum=BC.Internal.Insert.Count+1
if !BC.Internal.Insert.Index! LSS 1 (
    call :SetError 20 IndexOutOfRange "The insertion index is outside the collection." Insert "%~2" "" Index "1 through !BC.Internal.Insert.Maximum!" "!BC.Internal.Insert.Index!"
    exit /b 20
)
if !BC.Internal.Insert.Index! GTR !BC.Internal.Insert.Maximum! (
    call :SetError 20 IndexOutOfRange "The insertion index is outside the collection." Insert "%~2" "" Index "1 through !BC.Internal.Insert.Maximum!" "!BC.Internal.Insert.Index!"
    exit /b 20
)

call :ValidateEnum "%~4" "Value,Object,Collection" EntryKind
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.Kind=!BC.Internal.Validated!"

call :ValidateDotted "%~5" Value
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.Value=!BC.Internal.Validated!"

set "BC.Internal.Insert.Definition="
if not "%~6"=="" (
    call :ValidateDotted "%~6" Definition
    if errorlevel 1 exit /b !errorlevel!
    set "BC.Internal.Insert.Definition=!BC.Internal.Validated!"
)

call :ValidatePositive "%~7" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.Quantity=!BC.Internal.Validated!"

call :ValidateUnsigned "%~8" Measure
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.Measure=!BC.Internal.Validated!"

call :PrepareOutput "%~9" Insert
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.Output=!BC.Internal.Output!"

set "BC.Internal.PolicyKind=!BC.C.%~2.EntryKind!"
if /i not "!BC.Internal.PolicyKind!"=="Any" (
    if /i not "!BC.Internal.PolicyKind!"=="!BC.Internal.Insert.Kind!" (
        call :SetError 20 EntryKindRejected "The entry kind is not accepted by this collection." Insert "%~2" "" EntryKind "!BC.Internal.PolicyKind!" "!BC.Internal.Insert.Kind!"
        exit /b 20
    )
)

if /i "!BC.Internal.Insert.Kind!"=="Collection" (
    if not "!BC.Internal.Insert.Quantity!"=="1" (
        call :SetError 20 InvalidNestedQuantity "Nested collection entries must have quantity one." Insert "%~2" "" Quantity "1" "!BC.Internal.Insert.Quantity!"
        exit /b 20
    )
    call :RequireCollection "!BC.Internal.Insert.Value!" Insert
    if errorlevel 1 exit /b !errorlevel!
    call :WouldCreateCycle "%~2" "!BC.Internal.Insert.Value!"
    if errorlevel 1 exit /b !errorlevel!
)

call :FindMergeTarget "%~2" "!BC.Internal.Insert.Kind!" "!BC.Internal.Insert.Value!" "!BC.Internal.Insert.Definition!" "!BC.Internal.Insert.Measure!"
if errorlevel 1 exit /b !errorlevel!

if defined BC.Internal.Match.Entry (
    call :IncreaseEntryQuantity "%~2" "!BC.Internal.Match.Entry!" "!BC.Internal.Insert.Quantity!" Insert
    if errorlevel 1 exit /b !errorlevel!
    for %%O in ("!BC.Internal.Insert.Output!") do set "%%~O=!BC.Internal.Match.Entry!"
    exit /b 0
)

if /i "!BC.C.%~2.Duplicates!"=="Reject" (
    call :FindSameValue "%~2" "!BC.Internal.Insert.Kind!" "!BC.Internal.Insert.Value!"
    if errorlevel 1 exit /b !errorlevel!
    if defined BC.Internal.Match.Entry (
        call :SetError 30 DuplicateEntry "The collection rejects duplicate entry values." Insert "%~2" "!BC.Internal.Match.Entry!" Duplicates "Unique kind and value" "!BC.Internal.Insert.Kind!:!BC.Internal.Insert.Value!"
        exit /b 30
    )
)

call :CheckCapacity "%~2" 1 "!BC.Internal.Insert.Quantity!" "!BC.Internal.Insert.Measure!" Insert
if errorlevel 1 exit /b !errorlevel!

set /a BC.Entry.Sequence+=1
set /a BC.Entry.Count+=1
set "BC.Internal.Insert.Entry=BCE!BC.Entry.Sequence!"

for /l %%I in (!BC.Internal.Insert.Count!,-1,!BC.Internal.Insert.Index!) do (
    set /a BC.Internal.Shift.Target=%%I+1
    for %%T in (!BC.Internal.Shift.Target!) do (
        set "BC.Internal.Shift.Entry=!BC.C.%~2.At.%%I!"
        set "BC.C.%~2.At.%%T=!BC.Internal.Shift.Entry!"
        if defined BC.Internal.Shift.Entry set "BC.E.!BC.Internal.Shift.Entry!.Position=%%T"
    )
)

set "BC.C.%~2.At.!BC.Internal.Insert.Index!=!BC.Internal.Insert.Entry!"
set "BC.E.!BC.Internal.Insert.Entry!.__Exists=1"
set "BC.E.!BC.Internal.Insert.Entry!.Collection=%~2"
set "BC.E.!BC.Internal.Insert.Entry!.Position=!BC.Internal.Insert.Index!"
set "BC.E.!BC.Internal.Insert.Entry!.Kind=!BC.Internal.Insert.Kind!"
set "BC.E.!BC.Internal.Insert.Entry!.Value=!BC.Internal.Insert.Value!"
set "BC.E.!BC.Internal.Insert.Entry!.Definition=!BC.Internal.Insert.Definition!"
set "BC.E.!BC.Internal.Insert.Entry!.Quantity=!BC.Internal.Insert.Quantity!"
set "BC.E.!BC.Internal.Insert.Entry!.Measure=!BC.Internal.Insert.Measure!"
set "BC.E.!BC.Internal.Insert.Entry!.AssignedSlots=0"

set /a BC.C.%~2.Entry.Count+=1
call :MathAdd "!BC.C.%~2.TotalQuantity!" "!BC.Internal.Insert.Quantity!" Insert "%~2" "!BC.Internal.Insert.Entry!" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.C.%~2.TotalQuantity=!BC.Internal.MathResult!"

call :MathMultiply "!BC.Internal.Insert.Quantity!" "!BC.Internal.Insert.Measure!" Insert "%~2" "!BC.Internal.Insert.Entry!" Measure
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Insert.DeltaMeasure=!BC.Internal.MathResult!"
call :MathAdd "!BC.C.%~2.TotalMeasure!" "!BC.Internal.Insert.DeltaMeasure!" Insert "%~2" "!BC.Internal.Insert.Entry!" Measure
if errorlevel 1 exit /b !errorlevel!
set "BC.C.%~2.TotalMeasure=!BC.Internal.MathResult!"

if /i "!BC.Internal.Insert.Kind!"=="Collection" (
    set /a BC.C.!BC.Internal.Insert.Value!.ReferenceCount+=1
)

for %%O in ("!BC.Internal.Insert.Output!") do set "%%~O=!BC.Internal.Insert.Entry!"
exit /b 0

:GetAt
call :BeginOperation GetAt
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" GetAt
if errorlevel 1 exit /b !errorlevel!
call :ValidatePositive "%~3" Index
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetAt.Index=!BC.Internal.Validated!"
if !BC.Internal.GetAt.Index! GTR !BC.C.%~2.Entry.Count! (
    call :SetError 20 IndexOutOfRange "The entry index is outside the collection." GetAt "%~2" "" Index "1 through !BC.C.%~2.Entry.Count!" "!BC.Internal.GetAt.Index!"
    exit /b 20
)
call :PrepareOutput "%~4" GetAt
if errorlevel 1 exit /b !errorlevel!
for %%I in (!BC.Internal.GetAt.Index!) do set "BC.Internal.GetAt.Entry=!BC.C.%~2.At.%%I!"
for %%O in ("!BC.Internal.Output!") do set "%%~O=!BC.Internal.GetAt.Entry!"
exit /b 0

:Find
call :BeginOperation Find
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" Find
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~3" "Value,Object,Collection" EntryKind
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Find.Kind=!BC.Internal.Validated!"
call :ValidateDotted "%~4" Value
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Find.Value=!BC.Internal.Validated!"
call :PrepareOutput "%~5" Find
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Find.OutputEntry=!BC.Internal.Output!"
call :PrepareOutput "%~6" Find
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Find.OutputIndex=!BC.Internal.Output!"

call :FindSameValue "%~2" "!BC.Internal.Find.Kind!" "!BC.Internal.Find.Value!"
if errorlevel 1 exit /b !errorlevel!
for %%O in ("!BC.Internal.Find.OutputEntry!") do set "%%~O=!BC.Internal.Match.Entry!"
for %%O in ("!BC.Internal.Find.OutputIndex!") do set "%%~O=!BC.Internal.Match.Index!"
exit /b 0

:Contains
call :BeginOperation Contains
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" Contains
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~3" "Value,Object,Collection" EntryKind
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Contains.Kind=!BC.Internal.Validated!"
call :ValidateDotted "%~4" Value
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Contains.Value=!BC.Internal.Validated!"
call :PrepareOutput "%~5" Contains
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Contains.Output=!BC.Internal.Output!"
call :FindSameValue "%~2" "!BC.Internal.Contains.Kind!" "!BC.Internal.Contains.Value!"
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Contains.Result=0"
if defined BC.Internal.Match.Entry set "BC.Internal.Contains.Result=1"
for %%O in ("!BC.Internal.Contains.Output!") do set "%%~O=!BC.Internal.Contains.Result!"
exit /b 0

:Move
call :BeginOperation Move
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" Move
if errorlevel 1 exit /b !errorlevel!
call :ValidatePositive "%~3" FromIndex
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Move.From=!BC.Internal.Validated!"
call :ValidatePositive "%~4" ToIndex
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Move.To=!BC.Internal.Validated!"
set "BC.Internal.Move.Count=!BC.C.%~2.Entry.Count!"

if !BC.Internal.Move.From! GTR !BC.Internal.Move.Count! (
    call :SetError 20 IndexOutOfRange "The source index is outside the collection." Move "%~2" "" FromIndex "1 through !BC.Internal.Move.Count!" "!BC.Internal.Move.From!"
    exit /b 20
)
if !BC.Internal.Move.To! GTR !BC.Internal.Move.Count! (
    call :SetError 20 IndexOutOfRange "The target index is outside the collection." Move "%~2" "" ToIndex "1 through !BC.Internal.Move.Count!" "!BC.Internal.Move.To!"
    exit /b 20
)
if "!BC.Internal.Move.From!"=="!BC.Internal.Move.To!" exit /b 0

for %%I in (!BC.Internal.Move.From!) do set "BC.Internal.Move.Entry=!BC.C.%~2.At.%%I!"

if !BC.Internal.Move.From! LSS !BC.Internal.Move.To! (
    set /a BC.Internal.Move.Last=BC.Internal.Move.To-1
    for /l %%I in (!BC.Internal.Move.From!,1,!BC.Internal.Move.Last!) do (
        set /a BC.Internal.Move.Next=%%I+1
        for %%N in (!BC.Internal.Move.Next!) do (
            set "BC.Internal.Move.Shift=!BC.C.%~2.At.%%N!"
            set "BC.C.%~2.At.%%I=!BC.Internal.Move.Shift!"
            if defined BC.Internal.Move.Shift set "BC.E.!BC.Internal.Move.Shift!.Position=%%I"
        )
    )
) else (
    set /a BC.Internal.Move.Last=BC.Internal.Move.To+1
    for /l %%I in (!BC.Internal.Move.From!,-1,!BC.Internal.Move.Last!) do (
        set /a BC.Internal.Move.Previous=%%I-1
        for %%P in (!BC.Internal.Move.Previous!) do (
            set "BC.Internal.Move.Shift=!BC.C.%~2.At.%%P!"
            set "BC.C.%~2.At.%%I=!BC.Internal.Move.Shift!"
            if defined BC.Internal.Move.Shift set "BC.E.!BC.Internal.Move.Shift!.Position=%%I"
        )
    )
)

set "BC.C.%~2.At.!BC.Internal.Move.To!=!BC.Internal.Move.Entry!"
set "BC.E.!BC.Internal.Move.Entry!.Position=!BC.Internal.Move.To!"
exit /b 0

:ReadEntry
call :BeginOperation ReadEntry
if errorlevel 1 exit /b !errorlevel!
call :RequireEntry "%~2" ReadEntry
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~3" "Collection,Position,Kind,Value,Definition,Quantity,Measure,TotalMeasure,AssignedSlots" Field
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.ReadEntry.Field=!BC.Internal.Validated!"
call :PrepareOutput "%~4" ReadEntry
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.ReadEntry.Output=!BC.Internal.Output!"

if /i "!BC.Internal.ReadEntry.Field!"=="TotalMeasure" (
    call :MathMultiply "!BC.E.%~2.Quantity!" "!BC.E.%~2.Measure!" ReadEntry "!BC.E.%~2.Collection!" "%~2" TotalMeasure
    if errorlevel 1 exit /b !errorlevel!
    set "BC.Internal.ReadEntry.Value=!BC.Internal.MathResult!"
) else (
    for %%F in (!BC.Internal.ReadEntry.Field!) do set "BC.Internal.ReadEntry.Value=!BC.E.%~2.%%F!"
)

for %%O in ("!BC.Internal.ReadEntry.Output!") do set "%%~O=!BC.Internal.ReadEntry.Value!"
exit /b 0

:ReadCollection
call :BeginOperation ReadCollection
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" ReadCollection
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~3" "Name,EntryKind,Duplicates,Comparison,MergePolicy,CountLimit,MeasureLimit,EntryCount,TotalQuantity,TotalMeasure,SlotCount,ReferenceCount" Field
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.ReadCollection.Field=!BC.Internal.Validated!"
call :PrepareOutput "%~4" ReadCollection
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.ReadCollection.Output=!BC.Internal.Output!"

set "BC.Internal.ReadCollection.Storage=!BC.Internal.ReadCollection.Field!"
if /i "!BC.Internal.ReadCollection.Field!"=="EntryCount" set "BC.Internal.ReadCollection.Storage=Entry.Count"
if /i "!BC.Internal.ReadCollection.Field!"=="SlotCount" set "BC.Internal.ReadCollection.Storage=Slot.Count"

for %%F in (!BC.Internal.ReadCollection.Storage!) do set "BC.Internal.ReadCollection.Value=!BC.C.%~2.%%F!"
for %%O in ("!BC.Internal.ReadCollection.Output!") do set "%%~O=!BC.Internal.ReadCollection.Value!"
exit /b 0

:SetQuantity
call :BeginOperation SetQuantity
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~3" SetQuantity
if errorlevel 1 exit /b !errorlevel!
call :ValidatePositive "%~4" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.SetQuantity.New=!BC.Internal.Validated!"
set "BC.Internal.SetQuantity.Old=!BC.E.%~3.Quantity!"
if /i "!BC.E.%~3.Kind!"=="Collection" if not "!BC.Internal.SetQuantity.New!"=="1" (
    call :SetError 20 InvalidNestedQuantity "Nested collection entries must have quantity one." SetQuantity "%~2" "%~3" Quantity "1" "!BC.Internal.SetQuantity.New!"
    exit /b 20
)
if "!BC.Internal.SetQuantity.New!"=="!BC.Internal.SetQuantity.Old!" exit /b 0

call :CheckSlotQuantityValue "%~2" "%~3" "!BC.Internal.SetQuantity.New!" SetQuantity
if errorlevel 1 exit /b !errorlevel!

call :MathSubtract "!BC.Internal.SetQuantity.New!" "!BC.Internal.SetQuantity.Old!" SetQuantity "%~2" "%~3" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.SetQuantity.Delta=!BC.Internal.MathResult!"

if !BC.Internal.SetQuantity.Delta! GTR 0 (
    call :CheckCapacity "%~2" 0 "!BC.Internal.SetQuantity.Delta!" "!BC.E.%~3.Measure!" SetQuantity
    if errorlevel 1 exit /b !errorlevel!
)

call :ApplyQuantityDelta "%~2" "%~3" "!BC.Internal.SetQuantity.Delta!" SetQuantity
if errorlevel 1 exit /b !errorlevel!
set "BC.E.%~3.Quantity=!BC.Internal.SetQuantity.New!"
exit /b 0

:RemoveQuantity
call :BeginOperation RemoveQuantity
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~3" RemoveQuantity
if errorlevel 1 exit /b !errorlevel!
call :ValidatePositive "%~4" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.RemoveQuantity.Amount=!BC.Internal.Validated!"
set "BC.Internal.RemoveQuantity.Current=!BC.E.%~3.Quantity!"

if !BC.Internal.RemoveQuantity.Amount! GTR !BC.Internal.RemoveQuantity.Current! (
    call :SetError 30 QuantityUnavailable "The requested quantity exceeds the entry quantity." RemoveQuantity "%~2" "%~3" Quantity "At most !BC.Internal.RemoveQuantity.Current!" "!BC.Internal.RemoveQuantity.Amount!"
    exit /b 30
)

if "!BC.Internal.RemoveQuantity.Amount!"=="!BC.Internal.RemoveQuantity.Current!" (
    call "%~f0" :RemoveEntry "%~2" "%~3"
    exit /b !errorlevel!
)

call :MathSubtract "!BC.Internal.RemoveQuantity.Current!" "!BC.Internal.RemoveQuantity.Amount!" RemoveQuantity "%~2" "%~3" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.RemoveQuantity.New=!BC.Internal.MathResult!"
call :ApplyQuantityDelta "%~2" "%~3" "-!BC.Internal.RemoveQuantity.Amount!" RemoveQuantity
if errorlevel 1 exit /b !errorlevel!
set "BC.E.%~3.Quantity=!BC.Internal.RemoveQuantity.New!"
exit /b 0

:RemoveEntry
call :BeginOperation RemoveEntry
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~3" RemoveEntry
if errorlevel 1 exit /b !errorlevel!
call :DeleteEntry "%~2" "%~3" RemoveEntry
exit /b !errorlevel!

:Split
call :BeginOperation Split
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~3" Split
if errorlevel 1 exit /b !errorlevel!
call :ValidatePositive "%~4" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Split.Amount=!BC.Internal.Validated!"
call :PrepareOutput "%~5" Split
if errorlevel 1 exit /b !errorlevel!

if /i not "!BC.C.%~2.Duplicates!"=="Allow" (
    call :SetError 30 SplitRejected "Splitting would violate the duplicate policy." Split "%~2" "%~3" Duplicates "Allow" "!BC.C.%~2.Duplicates!"
    exit /b 30
)
if /i not "!BC.C.%~2.MergePolicy!"=="Never" (
    call :SetError 30 SplitRejected "Splitting requires merge policy Never." Split "%~2" "%~3" MergePolicy "Never" "!BC.C.%~2.MergePolicy!"
    exit /b 30
)
if /i "!BC.E.%~3.Kind!"=="Collection" (
    call :SetError 30 SplitRejected "Nested collection entries cannot be split." Split "%~2" "%~3" EntryKind "Value or Object" "Collection"
    exit /b 30
)
if !BC.Internal.Split.Amount! GEQ !BC.E.%~3.Quantity! (
    call :SetError 30 InvalidSplitQuantity "The split quantity must be less than the source quantity." Split "%~2" "%~3" Quantity "1 through quantity minus one" "!BC.Internal.Split.Amount!"
    exit /b 30
)

call :CheckCapacity "%~2" 1 0 0 Split
if errorlevel 1 exit /b !errorlevel!

call :MathSubtract "!BC.E.%~3.Quantity!" "!BC.Internal.Split.Amount!" Split "%~2" "%~3" Quantity
if errorlevel 1 exit /b !errorlevel!

set "BC.Work.Split.Collection=%~2"
set "BC.Work.Split.Entry=%~3"
set "BC.Work.Split.Amount=!BC.Internal.Split.Amount!"
set "BC.Work.Split.Remaining=!BC.Internal.MathResult!"
set "BC.Work.Split.Output=!BC.Internal.Output!"
set "BC.Work.Split.Kind=!BC.E.%~3.Kind!"
set "BC.Work.Split.Value=!BC.E.%~3.Value!"
set "BC.Work.Split.Definition=!BC.E.%~3.Definition!"
set "BC.Work.Split.Measure=!BC.E.%~3.Measure!"
set /a BC.Work.Split.Index=BC.E.%~3.Position+1

call :ApplyQuantityDelta "!BC.Work.Split.Collection!" "!BC.Work.Split.Entry!" "-!BC.Work.Split.Amount!" Split
if errorlevel 1 goto :Split.CleanupFailure
set "BC.E.!BC.Work.Split.Entry!.Quantity=!BC.Work.Split.Remaining!"

call "%~f0" :Insert "!BC.Work.Split.Collection!" "!BC.Work.Split.Index!" "!BC.Work.Split.Kind!" "!BC.Work.Split.Value!" "!BC.Work.Split.Definition!" "!BC.Work.Split.Amount!" "!BC.Work.Split.Measure!" BCSplitEntry
set "BC.Work.Split.Exit=!errorlevel!"
if not "!BC.Work.Split.Exit!"=="0" (
    call :ApplyQuantityDelta "!BC.Work.Split.Collection!" "!BC.Work.Split.Entry!" "!BC.Work.Split.Amount!" SplitRollback
    call :MathAdd "!BC.Work.Split.Remaining!" "!BC.Work.Split.Amount!" SplitRollback "!BC.Work.Split.Collection!" "!BC.Work.Split.Entry!" Quantity
    if not errorlevel 1 set "BC.E.!BC.Work.Split.Entry!.Quantity=!BC.Internal.MathResult!"
    set "BC.Work.Split.Return=!BC.Work.Split.Exit!"
    goto :Split.Cleanup
)

for %%O in ("!BC.Work.Split.Output!") do set "%%~O=!BCSplitEntry!"
set "BC.Work.Split.Return=0"
goto :Split.Cleanup

:Split.CleanupFailure
set "BC.Work.Split.Return=!errorlevel!"

:Split.Cleanup
set "BC.Work.Split.Collection="
set "BC.Work.Split.Entry="
set "BC.Work.Split.Amount="
set "BC.Work.Split.Remaining="
set "BC.Work.Split.Output="
set "BC.Work.Split.Kind="
set "BC.Work.Split.Value="
set "BC.Work.Split.Definition="
set "BC.Work.Split.Measure="
set "BC.Work.Split.Index="
set "BC.Work.Split.Exit="
set "BC.Internal.Split.Return=!BC.Work.Split.Return!"
set "BC.Work.Split.Return="
exit /b !BC.Internal.Split.Return!

:Merge
call :BeginOperation Merge
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~3" Merge
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~4" Merge
if errorlevel 1 exit /b !errorlevel!
if /i "%~3"=="%~4" (
    call :SetError 20 SameEntry "Source and target entries must differ." Merge "%~2" "%~3" Entry "Different target entry" "%~4"
    exit /b 20
)
if /i "!BC.E.%~3.Kind!"=="Collection" (
    call :SetError 30 EntriesNotMergeable "Nested collection entries cannot be merged." Merge "%~2" "%~3" EntryKind "Value or Object" "Collection"
    exit /b 30
)

call :EntriesCompatible "%~3" "%~4"
if errorlevel 1 (
    call :SetError 30 EntriesNotMergeable "The entries do not have compatible kind, value, definition, and measure." Merge "%~2" "%~3" TargetEntry "Compatible entry" "%~4"
    exit /b 30
)

call :MathAdd "!BC.E.%~4.Quantity!" "!BC.E.%~3.Quantity!" Merge "%~2" "%~4" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Merge.Quantity=!BC.Internal.MathResult!"
call :CheckSlotQuantityValue "%~2" "%~4" "!BC.Internal.Merge.Quantity!" Merge
if errorlevel 1 exit /b !errorlevel!
set "BC.E.%~4.Quantity=!BC.Internal.Merge.Quantity!"
call :DeleteEntryPreserveTotals "%~2" "%~3" Merge
if errorlevel 1 exit /b !errorlevel!
exit /b 0

:TransferEntry
call :BeginOperation TransferEntry
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~3" TransferEntry
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~4" TransferEntry
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~5" TransferEntry
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Transfer.Output=!BC.Internal.Output!"

if /i "%~2"=="%~4" (
    for %%O in ("!BC.Internal.Transfer.Output!") do set "%%~O=%~3"
    exit /b 0
)

call :PreflightTransfer "%~2" "%~3" "!BC.E.%~3.Quantity!" "%~4" TransferEntry
if errorlevel 1 exit /b !errorlevel!

if defined BC.Internal.Transfer.MergeEntry (
    call :IncreaseEntryQuantity "%~4" "!BC.Internal.Transfer.MergeEntry!" "!BC.E.%~3.Quantity!" TransferEntry
    if errorlevel 1 exit /b !errorlevel!
    call :DeleteEntry "%~2" "%~3" TransferEntry
    if errorlevel 1 exit /b !errorlevel!
    for %%O in ("!BC.Internal.Transfer.Output!") do set "%%~O=!BC.Internal.Transfer.MergeEntry!"
    exit /b 0
)

call :MoveEntryBetweenCollections "%~2" "%~3" "%~4" TransferEntry
if errorlevel 1 exit /b !errorlevel!
for %%O in ("!BC.Internal.Transfer.Output!") do set "%%~O=%~3"
exit /b 0

:TransferQuantity
call :BeginOperation TransferQuantity
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~3" TransferQuantity
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~5" TransferQuantity
if errorlevel 1 exit /b !errorlevel!
call :ValidatePositive "%~4" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.TransferQuantity.Amount=!BC.Internal.Validated!"
call :PrepareOutput "%~6" TransferQuantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.TransferQuantity.Output=!BC.Internal.Output!"

if !BC.Internal.TransferQuantity.Amount! GTR !BC.E.%~3.Quantity! (
    call :SetError 30 QuantityUnavailable "The requested transfer quantity exceeds the source quantity." TransferQuantity "%~2" "%~3" Quantity "At most !BC.E.%~3.Quantity!" "!BC.Internal.TransferQuantity.Amount!"
    exit /b 30
)

if "!BC.Internal.TransferQuantity.Amount!"=="!BC.E.%~3.Quantity!" (
    call "%~f0" :TransferEntry "%~2" "%~3" "%~5" "!BC.Internal.TransferQuantity.Output!"
    exit /b !errorlevel!
)

if /i "%~2"=="%~5" (
    call :SetError 20 SameCollection "A partial transfer requires different source and target collections." TransferQuantity "%~2" "%~3" TargetCollection "Different collection" "%~5"
    exit /b 20
)

if /i "!BC.E.%~3.Kind!"=="Collection" (
    call :SetError 30 PartialNestedTransferRejected "Nested collection entries cannot be partially transferred." TransferQuantity "%~2" "%~3" EntryKind "Value or Object" "Collection"
    exit /b 30
)

call :PreflightTransfer "%~2" "%~3" "!BC.Internal.TransferQuantity.Amount!" "%~5" TransferQuantity
if errorlevel 1 exit /b !errorlevel!

if defined BC.Internal.Transfer.MergeEntry (
    call :IncreaseEntryQuantity "%~5" "!BC.Internal.Transfer.MergeEntry!" "!BC.Internal.TransferQuantity.Amount!" TransferQuantity
    if errorlevel 1 exit /b !errorlevel!
    call :ApplyQuantityDelta "%~2" "%~3" "-!BC.Internal.TransferQuantity.Amount!" TransferQuantity
    if errorlevel 1 exit /b !errorlevel!
    call :MathSubtract "!BC.E.%~3.Quantity!" "!BC.Internal.TransferQuantity.Amount!" TransferQuantity "%~2" "%~3" Quantity
    if errorlevel 1 exit /b !errorlevel!
    set "BC.E.%~3.Quantity=!BC.Internal.MathResult!"
    for %%O in ("!BC.Internal.TransferQuantity.Output!") do set "%%~O=!BC.Internal.Transfer.MergeEntry!"
    exit /b 0
)

call :MathSubtract "!BC.E.%~3.Quantity!" "!BC.Internal.TransferQuantity.Amount!" TransferQuantity "%~2" "%~3" Quantity
if errorlevel 1 exit /b !errorlevel!

set "BC.Work.Transfer.Source=%~2"
set "BC.Work.Transfer.Entry=%~3"
set "BC.Work.Transfer.Amount=!BC.Internal.TransferQuantity.Amount!"
set "BC.Work.Transfer.Target=%~5"
set "BC.Work.Transfer.Output=!BC.Internal.TransferQuantity.Output!"
set "BC.Work.Transfer.Remaining=!BC.Internal.MathResult!"
set "BC.Work.Transfer.Kind=!BC.E.%~3.Kind!"
set "BC.Work.Transfer.Value=!BC.E.%~3.Value!"
set "BC.Work.Transfer.Definition=!BC.E.%~3.Definition!"
set "BC.Work.Transfer.Measure=!BC.E.%~3.Measure!"

call "%~f0" :Insert "!BC.Work.Transfer.Target!" 0 "!BC.Work.Transfer.Kind!" "!BC.Work.Transfer.Value!" "!BC.Work.Transfer.Definition!" "!BC.Work.Transfer.Amount!" "!BC.Work.Transfer.Measure!" BCTransferNewEntry
set "BC.Work.Transfer.Exit=!errorlevel!"
if not "!BC.Work.Transfer.Exit!"=="0" (
    set "BC.Internal.TransferQuantity.Return=!BC.Work.Transfer.Exit!"
    goto :TransferQuantity.Cleanup
)

call :ApplyQuantityDelta "!BC.Work.Transfer.Source!" "!BC.Work.Transfer.Entry!" "-!BC.Work.Transfer.Amount!" TransferQuantity
if errorlevel 1 (
    set "BC.Internal.TransferQuantity.Return=!errorlevel!"
    goto :TransferQuantity.Cleanup
)
set "BC.E.!BC.Work.Transfer.Entry!.Quantity=!BC.Work.Transfer.Remaining!"
for %%O in ("!BC.Work.Transfer.Output!") do set "%%~O=!BCTransferNewEntry!"
set "BC.Internal.TransferQuantity.Return=0"

:TransferQuantity.Cleanup
set "BC.Work.Transfer.Source="
set "BC.Work.Transfer.Entry="
set "BC.Work.Transfer.Amount="
set "BC.Work.Transfer.Target="
set "BC.Work.Transfer.Output="
set "BC.Work.Transfer.Remaining="
set "BC.Work.Transfer.Kind="
set "BC.Work.Transfer.Value="
set "BC.Work.Transfer.Definition="
set "BC.Work.Transfer.Measure="
set "BC.Work.Transfer.Exit="
exit /b !BC.Internal.TransferQuantity.Return!

:DefineSlot
call :BeginOperation DefineSlot
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" DefineSlot
if errorlevel 1 exit /b !errorlevel!
call :ValidateIdentifier "%~3" Slot
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Slot.Name=!BC.Internal.Validated!"
call :ValidateEnum "%~4" "Any,Value,Object,Collection" AllowedKind
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Slot.Kind=!BC.Internal.Validated!"
call :ValidateUnsigned "%~5" MaximumQuantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Slot.Maximum=!BC.Internal.Validated!"

if defined BC.C.%~2.Slot.!BC.Internal.Slot.Name!.Exists (
    call :SetError 30 SlotAlreadyExists "A slot with this name already exists." DefineSlot "%~2" "" Slot "Unused slot name" "!BC.Internal.Slot.Name!"
    exit /b 30
)

set /a BC.C.%~2.Slot.Sequence+=1
set /a BC.C.%~2.Slot.Count+=1
set /a BC.Slot.Count+=1
set "BC.Internal.Slot.Index=!BC.C.%~2.Slot.Sequence!"
set "BC.C.%~2.Slot.Index.!BC.Internal.Slot.Index!.Name=!BC.Internal.Slot.Name!"
set "BC.C.%~2.Slot.Index.!BC.Internal.Slot.Index!.Active=1"
set "BC.C.%~2.Slot.!BC.Internal.Slot.Name!.Exists=1"
set "BC.C.%~2.Slot.!BC.Internal.Slot.Name!.AllowedKind=!BC.Internal.Slot.Kind!"
set "BC.C.%~2.Slot.!BC.Internal.Slot.Name!.MaximumQuantity=!BC.Internal.Slot.Maximum!"
set "BC.C.%~2.Slot.!BC.Internal.Slot.Name!.Entry="
exit /b 0

:AssignSlot
call :BeginOperation AssignSlot
if errorlevel 1 exit /b !errorlevel!
call :RequireMembership "%~2" "%~4" AssignSlot
if errorlevel 1 exit /b !errorlevel!
call :RequireSlot "%~2" "%~3" AssignSlot
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Assign.Slot=!BC.Internal.Slot.Name!"
for %%S in ("!BC.Internal.Assign.Slot!") do set "BC.Internal.Assign.Current=!BC.C.%~2.Slot.%%~S.Entry!"

if defined BC.Internal.Assign.Current (
    if /i "!BC.Internal.Assign.Current!"=="%~4" exit /b 0
    call :SetError 30 SlotOccupied "The slot already contains another entry." AssignSlot "%~2" "%~4" Slot "Unassigned slot" "!BC.Internal.Assign.Current!"
    exit /b 30
)

for %%S in ("!BC.Internal.Assign.Slot!") do set "BC.Internal.Assign.Allowed=!BC.C.%~2.Slot.%%~S.AllowedKind!"
if /i not "!BC.Internal.Assign.Allowed!"=="Any" (
    if /i not "!BC.Internal.Assign.Allowed!"=="!BC.E.%~4.Kind!" (
        call :SetError 30 SlotKindRejected "The entry kind is not accepted by the slot." AssignSlot "%~2" "%~4" AllowedKind "!BC.Internal.Assign.Allowed!" "!BC.E.%~4.Kind!"
        exit /b 30
    )
)

for %%S in ("!BC.Internal.Assign.Slot!") do set "BC.Internal.Assign.Maximum=!BC.C.%~2.Slot.%%~S.MaximumQuantity!"
if not "!BC.Internal.Assign.Maximum!"=="0" (
    if !BC.E.%~4.Quantity! GTR !BC.Internal.Assign.Maximum! (
        call :SetError 30 SlotQuantityRejected "The entry quantity exceeds the slot maximum." AssignSlot "%~2" "%~4" MaximumQuantity "!BC.Internal.Assign.Maximum!" "!BC.E.%~4.Quantity!"
        exit /b 30
    )
)

set "BC.C.%~2.Slot.!BC.Internal.Assign.Slot!.Entry=%~4"
set /a BC.E.%~4.AssignedSlots+=1
exit /b 0

:UnassignSlot
call :BeginOperation UnassignSlot
if errorlevel 1 exit /b !errorlevel!
call :RequireSlot "%~2" "%~3" UnassignSlot
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Unassign.Slot=!BC.Internal.Slot.Name!"
for %%S in ("!BC.Internal.Unassign.Slot!") do set "BC.Internal.Unassign.Entry=!BC.C.%~2.Slot.%%~S.Entry!"
if defined BC.Internal.Unassign.Entry (
    set /a BC.E.!BC.Internal.Unassign.Entry!.AssignedSlots-=1
)
set "BC.C.%~2.Slot.!BC.Internal.Unassign.Slot!.Entry="
exit /b 0

:GetSlot
call :BeginOperation GetSlot
if errorlevel 1 exit /b !errorlevel!
call :RequireSlot "%~2" "%~3" GetSlot
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~4" GetSlot
if errorlevel 1 exit /b !errorlevel!
for %%S in ("!BC.Internal.Slot.Name!") do set "BC.Internal.GetSlot.Entry=!BC.C.%~2.Slot.%%~S.Entry!"
for %%O in ("!BC.Internal.Output!") do set "%%~O=!BC.Internal.GetSlot.Entry!"
exit /b 0

:ListEntries
call :BeginOperation ListEntries
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" ListEntries
if errorlevel 1 exit /b !errorlevel!
echo Collection %~2 ^(!BC.C.%~2.Name!^) - !BC.C.%~2.Entry.Count! entries
if "!BC.C.%~2.Entry.Count!"=="0" exit /b 0
for /l %%I in (1,1,!BC.C.%~2.Entry.Count!) do (
    set "BC.Internal.List.Entry=!BC.C.%~2.At.%%I!"
    for %%E in (!BC.Internal.List.Entry!) do (
        echo %%I: %%E kind=!BC.E.%%E.Kind! value=!BC.E.%%E.Value! definition=!BC.E.%%E.Definition! quantity=!BC.E.%%E.Quantity! measure=!BC.E.%%E.Measure!
    )
)
exit /b 0

:ListSlots
call :BeginOperation ListSlots
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" ListSlots
if errorlevel 1 exit /b !errorlevel!
echo Collection %~2 ^(!BC.C.%~2.Name!^) - !BC.C.%~2.Slot.Count! slots
if "!BC.C.%~2.Slot.Sequence!"=="0" exit /b 0
for /l %%I in (1,1,!BC.C.%~2.Slot.Sequence!) do (
    if "!BC.C.%~2.Slot.Index.%%I.Active!"=="1" (
        set "BC.Internal.List.Slot=!BC.C.%~2.Slot.Index.%%I.Name!"
        for %%S in (!BC.Internal.List.Slot!) do (
            echo %%S: kind=!BC.C.%~2.Slot.%%S.AllowedKind! maximum=!BC.C.%~2.Slot.%%S.MaximumQuantity! entry=!BC.C.%~2.Slot.%%S.Entry!
        )
    )
)
exit /b 0

:ClearCollection
call :BeginOperation ClearCollection
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" ClearCollection
if errorlevel 1 exit /b !errorlevel!

:ClearCollection.Loop
if "!BC.C.%~2.Entry.Count!"=="0" exit /b 0
set "BC.Internal.Clear.Entry=!BC.C.%~2.At.1!"
call :DeleteEntry "%~2" "!BC.Internal.Clear.Entry!" ClearCollection
if errorlevel 1 exit /b !errorlevel!
goto :ClearCollection.Loop

:Release
call :BeginOperation Release
if errorlevel 1 exit /b !errorlevel!
call :RequireCollection "%~2" Release
if errorlevel 1 exit /b !errorlevel!

if not "!BC.C.%~2.ReferenceCount!"=="0" (
    call :SetError 30 CollectionReferenced "The collection is referenced by another collection." Release "%~2" "" ReferenceCount "0" "!BC.C.%~2.ReferenceCount!"
    exit /b 30
)

set "BC.Work.Release.Name=!BC.C.%~2.Name!"
call "%~f0" :ClearCollection "%~2"
if errorlevel 1 exit /b !errorlevel!

if not "!BC.C.%~2.Slot.Sequence!"=="0" (
    for /l %%I in (1,1,!BC.C.%~2.Slot.Sequence!) do (
        if "!BC.C.%~2.Slot.Index.%%I.Active!"=="1" (
            set "BC.Internal.Release.Slot=!BC.C.%~2.Slot.Index.%%I.Name!"
            set "BC.C.%~2.Slot.!BC.Internal.Release.Slot!.Exists="
            set "BC.C.%~2.Slot.!BC.Internal.Release.Slot!.AllowedKind="
            set "BC.C.%~2.Slot.!BC.Internal.Release.Slot!.MaximumQuantity="
            set "BC.C.%~2.Slot.!BC.Internal.Release.Slot!.Entry="
            set "BC.C.%~2.Slot.Index.%%I.Name="
            set "BC.C.%~2.Slot.Index.%%I.Active="
            set /a BC.Slot.Count-=1
        )
    )
)

set "BC.Name.!BC.Work.Release.Name!="
set "BC.Work.Release.Name="
for /f "tokens=1 delims==" %%V in ('set BC.C.%~2. 2^>nul') do set "%%V="
set /a BC.Collection.Count-=1
exit /b 0

:GetStat
call :BeginOperation GetStat
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~2" "CollectionCount,EntryCount,SlotCount" Statistic
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Stat.Name=!BC.Internal.Validated!"
call :PrepareOutput "%~3" GetStat
if errorlevel 1 exit /b !errorlevel!
if /i "!BC.Internal.Stat.Name!"=="CollectionCount" set "BC.Internal.Stat.Value=!BC.Collection.Count!"
if /i "!BC.Internal.Stat.Name!"=="EntryCount" set "BC.Internal.Stat.Value=!BC.Entry.Count!"
if /i "!BC.Internal.Stat.Name!"=="SlotCount" set "BC.Internal.Stat.Value=!BC.Slot.Count!"
for %%O in ("!BC.Internal.Output!") do set "%%~O=!BC.Internal.Stat.Value!"
exit /b 0

:ReadLastError
call :EnsureInitialized
call :ValidateEnum "%~2" "Code,Kind,Message,Operation,Collection,Entry,Constraint,Expected,Actual" ErrorField
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Error.Field=!BC.Internal.Validated!"
call :PrepareOutput "%~3" ReadLastError
if errorlevel 1 exit /b !errorlevel!
for %%F in (!BC.Internal.Error.Field!) do set "BC.Internal.Error.Value=!BC.LastError.%%F!"
for %%O in ("!BC.Internal.Output!") do set "%%~O=!BC.Internal.Error.Value!"
exit /b 0

:PrintLastError
call :EnsureInitialized
if not defined BC.LastError.Kind (
    echo BatchCollection has no current error.
    exit /b 0
)
echo BatchCollection error !BC.LastError.Code!: !BC.LastError.Kind!
echo Message: !BC.LastError.Message!
if defined BC.LastError.Operation echo Operation: !BC.LastError.Operation!
if defined BC.LastError.Collection echo Collection: !BC.LastError.Collection!
if defined BC.LastError.Entry echo Entry: !BC.LastError.Entry!
if defined BC.LastError.Constraint echo Constraint: !BC.LastError.Constraint!
if defined BC.LastError.Expected echo Expected: !BC.LastError.Expected!
if defined BC.LastError.Actual echo Actual: !BC.LastError.Actual!
exit /b 0

:ClearLastError
call :EnsureInitialized
call :ClearLastErrorInternal
exit /b 0

:BeginOperation
call :EnsureInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BC.Internal."
call :ClearLastErrorInternal
set "BC.Internal.Operation=%~1"
exit /b 0

:EnsureInitialized
if defined BC.Initialized exit /b 0
call "%~f0" :Initialize
exit /b !errorlevel!

:RequireInitialized
if defined BC.Initialized exit /b 0
call :SetError 50 CollectionNotInitialized "BatchCollection is not initialized." RequireInitialized "" "" State "Initialized component" "Not initialized"
exit /b 50

:RequireCollection
if defined BC.C.%~1.__Exists exit /b 0
call :SetError 30 CollectionNotFound "The collection handle does not exist." "%~2" "%~1" "" Collection "Live collection handle" "%~1"
exit /b 30

:RequireEntry
if defined BC.E.%~1.__Exists exit /b 0
call :SetError 30 EntryNotFound "The entry handle does not exist." "%~2" "" "%~1" Entry "Live entry handle" "%~1"
exit /b 30

:RequireMembership
call :RequireCollection "%~1" "%~3"
if errorlevel 1 exit /b !errorlevel!
call :RequireEntry "%~2" "%~3"
if errorlevel 1 exit /b !errorlevel!
if /i "!BC.E.%~2.Collection!"=="%~1" exit /b 0
call :SetError 30 EntryNotInCollection "The entry does not belong to the collection." "%~3" "%~1" "%~2" Collection "%~1" "!BC.E.%~2.Collection!"
exit /b 30

:RequireSlot
call :RequireCollection "%~1" "%~3"
if errorlevel 1 exit /b !errorlevel!
call :ValidateIdentifier "%~2" Slot
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Slot.Name=!BC.Internal.Validated!"
if defined BC.C.%~1.Slot.!BC.Internal.Slot.Name!.Exists exit /b 0
call :SetError 30 SlotNotFound "The collection slot does not exist." "%~3" "%~1" "" Slot "Defined slot" "!BC.Internal.Slot.Name!"
exit /b 30

:RequireEmptyForPolicy
if "!BC.C.%~1.Entry.Count!"=="0" exit /b 0
call :SetError 30 PolicyLocked "This policy can change only while the collection is empty." SetPolicy "%~1" "" "%~2" "Empty collection" "!BC.C.%~1.Entry.Count! entries"
exit /b 30

:PrepareOutput
call :ValidateIdentifier "%~1" OutputVariable
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Output=!BC.Internal.Validated!"
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
    RANDOM
    CMDEXTVERSION
    CMDCMDLINE
) do (
    if /i "!BC.Internal.Output!"=="%%R" (
        call :SetError 20 ReservedOutputVariable "The output variable name is reserved." "%~2" "" "" OutputVariable "Non-reserved identifier" "!BC.Internal.Output!"
        exit /b 20
    )
)
if /i "!BC.Internal.Output:~0,3!"=="BC." (
    call :SetError 20 ReservedOutputVariable "The output variable name uses the BatchCollection namespace." "%~2" "" "" OutputVariable "Caller-owned identifier" "!BC.Internal.Output!"
    exit /b 20
)
exit /b 0

:ValidateIdentifier
set "BC.Internal.Validation.Value=%~1"
set "BC.Internal.Validation.Constraint=%~2"
call "!BC.Validator!" :Identifier "!BC.Internal.Validation.Value!" BCValidated
if errorlevel 1 (
    call :SetError 20 InvalidIdentifier "The value must be an identifier." "!BC.Internal.Operation!" "" "" "!BC.Internal.Validation.Constraint!" "Letter followed by letters, digits, or underscores" "!BC.Internal.Validation.Value!"
    exit /b 20
)
set "BC.Internal.Validated=!BCValidated!"
exit /b 0

:ValidateDotted
set "BC.Internal.Validation.Value=%~1"
set "BC.Internal.Validation.Constraint=%~2"
call "!BC.Validator!" :DottedIdentifier "!BC.Internal.Validation.Value!" BCValidated
if errorlevel 1 (
    call :SetError 20 InvalidDottedIdentifier "The value must be a dotted identifier." "!BC.Internal.Operation!" "" "" "!BC.Internal.Validation.Constraint!" "Identifier or dotted identifier" "!BC.Internal.Validation.Value!"
    exit /b 20
)
set "BC.Internal.Validated=!BCValidated!"
exit /b 0

:ValidateUnsigned
set "BC.Internal.Validation.Value=%~1"
set "BC.Internal.Validation.Constraint=%~2"
call "!BC.Validator!" :UInt32 "!BC.Internal.Validation.Value!" BCValidated
if errorlevel 1 (
    call :SetError 20 InvalidUnsignedInteger "The value must be a normalized unsigned 32-bit integer." "!BC.Internal.Operation!" "" "" "!BC.Internal.Validation.Constraint!" "0 through 2147483647" "!BC.Internal.Validation.Value!"
    exit /b 20
)
set "BC.Internal.Validated=!BCValidated!"
exit /b 0

:ValidatePositive
call :ValidateUnsigned "%~1" "%~2"
if errorlevel 1 exit /b !errorlevel!
if not "!BC.Internal.Validated!"=="0" exit /b 0
call :SetError 20 PositiveIntegerRequired "The value must be greater than zero." "!BC.Internal.Operation!" "" "" "%~2" "1 through 2147483647" "0"
exit /b 20

:ValidateEnum
set "BC.Internal.Validation.Value=%~1"
set "BC.Internal.Validation.Choices=%~2"
set "BC.Internal.Validation.Constraint=%~3"
call "!BC.Validator!" :Enum "!BC.Internal.Validation.Value!" "!BC.Internal.Validation.Choices!" BCValidated
if errorlevel 1 (
    call :SetError 20 InvalidEnumValue "The value is not one of the allowed choices." "!BC.Internal.Operation!" "" "" "!BC.Internal.Validation.Constraint!" "!BC.Internal.Validation.Choices!" "!BC.Internal.Validation.Value!"
    exit /b 20
)
set "BC.Internal.Validated=!BCValidated!"
exit /b 0

:CheckCapacity
set "BC.Internal.Capacity.Collection=%~1"
set "BC.Internal.Capacity.EntryDelta=%~2"
set "BC.Internal.Capacity.QuantityDelta=%~3"
set "BC.Internal.Capacity.Measure=%~4"
set "BC.Internal.Capacity.Operation=%~5"

call :MathAdd "!BC.C.%~1.Entry.Count!" "!BC.Internal.Capacity.EntryDelta!" "!BC.Internal.Capacity.Operation!" "%~1" "" Count
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Capacity.NewCount=!BC.Internal.MathResult!"
set "BC.Internal.Capacity.CountLimit=!BC.C.%~1.CountLimit!"
if not "!BC.Internal.Capacity.CountLimit!"=="0" (
    if !BC.Internal.Capacity.NewCount! GTR !BC.Internal.Capacity.CountLimit! (
        call :SetError 30 CountCapacityExceeded "The operation would exceed the collection count limit." "!BC.Internal.Capacity.Operation!" "%~1" "" CountLimit "!BC.Internal.Capacity.CountLimit!" "!BC.Internal.Capacity.NewCount!"
        exit /b 30
    )
)

call :MathMultiply "!BC.Internal.Capacity.QuantityDelta!" "!BC.Internal.Capacity.Measure!" "!BC.Internal.Capacity.Operation!" "%~1" "" Measure
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Capacity.DeltaMeasure=!BC.Internal.MathResult!"
call :MathAdd "!BC.C.%~1.TotalMeasure!" "!BC.Internal.Capacity.DeltaMeasure!" "!BC.Internal.Capacity.Operation!" "%~1" "" Measure
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Capacity.NewMeasure=!BC.Internal.MathResult!"
set "BC.Internal.Capacity.MeasureLimit=!BC.C.%~1.MeasureLimit!"
if not "!BC.Internal.Capacity.MeasureLimit!"=="0" (
    if !BC.Internal.Capacity.NewMeasure! GTR !BC.Internal.Capacity.MeasureLimit! (
        call :SetError 30 MeasureCapacityExceeded "The operation would exceed the collection measure limit." "!BC.Internal.Capacity.Operation!" "%~1" "" MeasureLimit "!BC.Internal.Capacity.MeasureLimit!" "!BC.Internal.Capacity.NewMeasure!"
        exit /b 30
    )
)
exit /b 0

:ApplyQuantityDelta
set "BC.Internal.Delta.Collection=%~1"
set "BC.Internal.Delta.Entry=%~2"
set "BC.Internal.Delta.Quantity=%~3"
set "BC.Internal.Delta.Operation=%~4"

call :MathAdd "!BC.C.%~1.TotalQuantity!" "!BC.Internal.Delta.Quantity!" "!BC.Internal.Delta.Operation!" "%~1" "%~2" TotalQuantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Delta.NewQuantity=!BC.Internal.MathResult!"

call :MathMultiply "!BC.Internal.Delta.Quantity!" "!BC.E.%~2.Measure!" "!BC.Internal.Delta.Operation!" "%~1" "%~2" TotalMeasure
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Delta.Measure=!BC.Internal.MathResult!"
call :MathAdd "!BC.C.%~1.TotalMeasure!" "!BC.Internal.Delta.Measure!" "!BC.Internal.Delta.Operation!" "%~1" "%~2" TotalMeasure
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Delta.NewMeasure=!BC.Internal.MathResult!"

set "BC.C.%~1.TotalQuantity=!BC.Internal.Delta.NewQuantity!"
set "BC.C.%~1.TotalMeasure=!BC.Internal.Delta.NewMeasure!"
exit /b 0

:IncreaseEntryQuantity
call :MathAdd "!BC.E.%~2.Quantity!" "%~3" "%~4" "%~1" "%~2" Quantity
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Increase.New=!BC.Internal.MathResult!"
call :CheckSlotQuantityValue "%~1" "%~2" "!BC.Internal.Increase.New!" "%~4"
if errorlevel 1 exit /b !errorlevel!
call :CheckCapacity "%~1" 0 "%~3" "!BC.E.%~2.Measure!" "%~4"
if errorlevel 1 exit /b !errorlevel!
call :ApplyQuantityDelta "%~1" "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BC.E.%~2.Quantity=!BC.Internal.Increase.New!"
exit /b 0

:CheckSlotQuantityValue
if "!BC.E.%~2.AssignedSlots!"=="0" exit /b 0
if "!BC.C.%~1.Slot.Sequence!"=="0" exit /b 0
for /l %%I in (1,1,!BC.C.%~1.Slot.Sequence!) do (
    if "!BC.C.%~1.Slot.Index.%%I.Active!"=="1" (
        set "BC.Internal.SlotCheck.Name=!BC.C.%~1.Slot.Index.%%I.Name!"
        for %%S in (!BC.Internal.SlotCheck.Name!) do (
            if /i "!BC.C.%~1.Slot.%%S.Entry!"=="%~2" (
                set "BC.Internal.SlotCheck.Maximum=!BC.C.%~1.Slot.%%S.MaximumQuantity!"
                if not "!BC.Internal.SlotCheck.Maximum!"=="0" (
                    if %~3 GTR !BC.Internal.SlotCheck.Maximum! (
                        call :SetError 30 SlotQuantityRejected "The updated quantity exceeds an assigned slot maximum." "%~4" "%~1" "%~2" MaximumQuantity "!BC.Internal.SlotCheck.Maximum!" "%~3"
                        exit /b 30
                    )
                )
            )
        )
    )
)
exit /b 0

:FindSameValue
set "BC.Internal.Match.Entry="
set "BC.Internal.Match.Index="
if "!BC.C.%~1.Entry.Count!"=="0" exit /b 0
for /l %%I in (1,1,!BC.C.%~1.Entry.Count!) do (
    set "BC.Internal.Match.Candidate=!BC.C.%~1.At.%%I!"
    for %%E in (!BC.Internal.Match.Candidate!) do (
        if /i "!BC.E.%%E.Kind!"=="%~2" (
            call :ValuesEqual "%~1" "!BC.E.%%E.Value!" "%~3"
            if "!BC.Internal.Equal!"=="1" if not defined BC.Internal.Match.Entry (
                set "BC.Internal.Match.Entry=%%E"
                set "BC.Internal.Match.Index=%%I"
            )
        )
    )
)
exit /b 0

:FindMergeTarget
set "BC.Internal.Match.Entry="
set "BC.Internal.Match.Index="
set "BC.Internal.Merge.Policy=!BC.C.%~1.MergePolicy!"
if /i "%~2"=="Collection" exit /b 0
if /i "!BC.Internal.Merge.Policy!"=="Never" exit /b 0
if "!BC.C.%~1.Entry.Count!"=="0" exit /b 0

for /l %%I in (1,1,!BC.C.%~1.Entry.Count!) do (
    set "BC.Internal.Merge.Candidate=!BC.C.%~1.At.%%I!"
    for %%E in (!BC.Internal.Merge.Candidate!) do (
        if /i "!BC.E.%%E.Kind!"=="%~2" (
            if "!BC.E.%%E.Measure!"=="%~5" (
                if /i "!BC.Internal.Merge.Policy!"=="SameValue" (
                    call :ValuesEqual "%~1" "!BC.E.%%E.Value!" "%~3"
                    if "!BC.Internal.Equal!"=="1" (
                        call :DefinitionsEqual "!BC.E.%%E.Definition!" "%~4"
                        if "!BC.Internal.Equal!"=="1" if not defined BC.Internal.Match.Entry (
                            set "BC.Internal.Match.Entry=%%E"
                            set "BC.Internal.Match.Index=%%I"
                        )
                    )
                )
                if /i "!BC.Internal.Merge.Policy!"=="SameDefinition" (
                    if not "%~4"=="" (
                        call :DefinitionsEqual "!BC.E.%%E.Definition!" "%~4"
                        if "!BC.Internal.Equal!"=="1" if not defined BC.Internal.Match.Entry (
                            set "BC.Internal.Match.Entry=%%E"
                            set "BC.Internal.Match.Index=%%I"
                        )
                    )
                )
            )
        )
    )
)
exit /b 0

:ValuesEqual
set "BC.Internal.Equal=0"
if /i "!BC.C.%~1.Comparison!"=="CaseInsensitive" (
    if /i "%~2"=="%~3" set "BC.Internal.Equal=1"
    exit /b 0
)
if "%~2"=="%~3" set "BC.Internal.Equal=1"
exit /b 0

:DefinitionsEqual
set "BC.Internal.Equal=0"
if /i "%~1"=="%~2" set "BC.Internal.Equal=1"
exit /b 0

:EntriesCompatible
if /i not "!BC.E.%~1.Kind!"=="!BC.E.%~2.Kind!" exit /b 1
if not "!BC.E.%~1.Measure!"=="!BC.E.%~2.Measure!" exit /b 1
call :DefinitionsEqual "!BC.E.%~1.Definition!" "!BC.E.%~2.Definition!"
if not "!BC.Internal.Equal!"=="1" exit /b 1
call :ValuesEqual "!BC.E.%~1.Collection!" "!BC.E.%~1.Value!" "!BC.E.%~2.Value!"
if not "!BC.Internal.Equal!"=="1" exit /b 1
exit /b 0

:DeleteEntry
set "BC.Internal.Delete.Quantity=!BC.E.%~2.Quantity!"
set "BC.Internal.Delete.Measure=!BC.E.%~2.Measure!"
call :ApplyQuantityDelta "%~1" "%~2" "-!BC.Internal.Delete.Quantity!" "%~3"
if errorlevel 1 exit /b !errorlevel!
call :DeleteEntryPreserveTotals "%~1" "%~2" "%~3"
exit /b !errorlevel!

:DeleteEntryPreserveTotals
set "BC.Internal.Delete.Position=!BC.E.%~2.Position!"
set "BC.Internal.Delete.Kind=!BC.E.%~2.Kind!"
set "BC.Internal.Delete.Value=!BC.E.%~2.Value!"
set "BC.Internal.Delete.Count=!BC.C.%~1.Entry.Count!"

call :ClearEntrySlots "%~1" "%~2"

if /i "!BC.Internal.Delete.Kind!"=="Collection" (
    set /a BC.C.!BC.Internal.Delete.Value!.ReferenceCount-=1
)

set /a BC.Internal.Delete.Start=BC.Internal.Delete.Position+1
if !BC.Internal.Delete.Start! LEQ !BC.Internal.Delete.Count! (
    for /l %%I in (!BC.Internal.Delete.Start!,1,!BC.Internal.Delete.Count!) do (
        set /a BC.Internal.Delete.Target=%%I-1
        for %%T in (!BC.Internal.Delete.Target!) do (
            set "BC.Internal.Delete.Shift=!BC.C.%~1.At.%%I!"
            set "BC.C.%~1.At.%%T=!BC.Internal.Delete.Shift!"
            if defined BC.Internal.Delete.Shift set "BC.E.!BC.Internal.Delete.Shift!.Position=%%T"
        )
    )
)

set "BC.C.%~1.At.!BC.Internal.Delete.Count!="
set /a BC.C.%~1.Entry.Count-=1
set /a BC.Entry.Count-=1
for /f "tokens=1 delims==" %%V in ('set BC.E.%~2. 2^>nul') do set "%%V="
exit /b 0

:ClearEntrySlots
if "!BC.E.%~2.AssignedSlots!"=="0" exit /b 0
if "!BC.C.%~1.Slot.Sequence!"=="0" exit /b 0
for /l %%I in (1,1,!BC.C.%~1.Slot.Sequence!) do (
    if "!BC.C.%~1.Slot.Index.%%I.Active!"=="1" (
        set "BC.Internal.ClearSlot.Name=!BC.C.%~1.Slot.Index.%%I.Name!"
        for %%S in (!BC.Internal.ClearSlot.Name!) do (
            if /i "!BC.C.%~1.Slot.%%S.Entry!"=="%~2" (
                set "BC.C.%~1.Slot.%%S.Entry="
            )
        )
    )
)
set "BC.E.%~2.AssignedSlots=0"
exit /b 0

:PreflightTransfer
set "BC.Internal.Transfer.Source=%~1"
set "BC.Internal.Transfer.Entry=%~2"
set "BC.Internal.Transfer.Quantity=%~3"
set "BC.Internal.Transfer.Target=%~4"
set "BC.Internal.Transfer.Operation=%~5"
set "BC.Internal.Transfer.MergeEntry="

set "BC.Internal.Transfer.Kind=!BC.E.%~2.Kind!"
set "BC.Internal.Transfer.Value=!BC.E.%~2.Value!"
set "BC.Internal.Transfer.Definition=!BC.E.%~2.Definition!"
set "BC.Internal.Transfer.Measure=!BC.E.%~2.Measure!"

set "BC.Internal.Transfer.PolicyKind=!BC.C.%~4.EntryKind!"
if /i not "!BC.Internal.Transfer.PolicyKind!"=="Any" (
    if /i not "!BC.Internal.Transfer.PolicyKind!"=="!BC.Internal.Transfer.Kind!" (
        call :SetError 20 EntryKindRejected "The target collection rejects the entry kind." "%~5" "%~4" "%~2" EntryKind "!BC.Internal.Transfer.PolicyKind!" "!BC.Internal.Transfer.Kind!"
        exit /b 20
    )
)

if /i "!BC.Internal.Transfer.Kind!"=="Collection" (
    call :WouldCreateCycle "%~4" "!BC.Internal.Transfer.Value!"
    if errorlevel 1 exit /b !errorlevel!
)

call :FindMergeTarget "%~4" "!BC.Internal.Transfer.Kind!" "!BC.Internal.Transfer.Value!" "!BC.Internal.Transfer.Definition!" "!BC.Internal.Transfer.Measure!"
if errorlevel 1 exit /b !errorlevel!
if defined BC.Internal.Match.Entry set "BC.Internal.Transfer.MergeEntry=!BC.Internal.Match.Entry!"

if not defined BC.Internal.Transfer.MergeEntry (
    if /i "!BC.C.%~4.Duplicates!"=="Reject" (
        call :FindSameValue "%~4" "!BC.Internal.Transfer.Kind!" "!BC.Internal.Transfer.Value!"
        if errorlevel 1 exit /b !errorlevel!
        if defined BC.Internal.Match.Entry (
            call :SetError 30 DuplicateEntry "The target collection rejects duplicate entry values." "%~5" "%~4" "%~2" Duplicates "Unique kind and value" "!BC.Internal.Transfer.Kind!:!BC.Internal.Transfer.Value!"
            exit /b 30
        )
    )
)

set "BC.Internal.Transfer.EntryDelta=1"
if defined BC.Internal.Transfer.MergeEntry set "BC.Internal.Transfer.EntryDelta=0"
call :CheckCapacity "%~4" "!BC.Internal.Transfer.EntryDelta!" "%~3" "!BC.Internal.Transfer.Measure!" "%~5"
exit /b !errorlevel!

:MoveEntryBetweenCollections
set "BC.Internal.MoveBetween.Source=%~1"
set "BC.Internal.MoveBetween.Entry=%~2"
set "BC.Internal.MoveBetween.Target=%~3"
set "BC.Internal.MoveBetween.Quantity=!BC.E.%~2.Quantity!"
set "BC.Internal.MoveBetween.Measure=!BC.E.%~2.Measure!"
set "BC.Internal.MoveBetween.Position=!BC.E.%~2.Position!"
set "BC.Internal.MoveBetween.SourceCount=!BC.C.%~1.Entry.Count!"

call :ClearEntrySlots "%~1" "%~2"

call :ApplyQuantityDelta "%~1" "%~2" "-!BC.Internal.MoveBetween.Quantity!" "%~4"
if errorlevel 1 exit /b !errorlevel!

set /a BC.Internal.MoveBetween.Start=BC.Internal.MoveBetween.Position+1
if !BC.Internal.MoveBetween.Start! LEQ !BC.Internal.MoveBetween.SourceCount! (
    for /l %%I in (!BC.Internal.MoveBetween.Start!,1,!BC.Internal.MoveBetween.SourceCount!) do (
        set /a BC.Internal.MoveBetween.TargetIndex=%%I-1
        for %%T in (!BC.Internal.MoveBetween.TargetIndex!) do (
            set "BC.Internal.MoveBetween.Shift=!BC.C.%~1.At.%%I!"
            set "BC.C.%~1.At.%%T=!BC.Internal.MoveBetween.Shift!"
            if defined BC.Internal.MoveBetween.Shift set "BC.E.!BC.Internal.MoveBetween.Shift!.Position=%%T"
        )
    )
)
set "BC.C.%~1.At.!BC.Internal.MoveBetween.SourceCount!="
set /a BC.C.%~1.Entry.Count-=1

set /a BC.Internal.MoveBetween.NewPosition=BC.C.%~3.Entry.Count+1
set "BC.C.%~3.At.!BC.Internal.MoveBetween.NewPosition!=%~2"
set /a BC.C.%~3.Entry.Count+=1
set "BC.E.%~2.Collection=%~3"
set "BC.E.%~2.Position=!BC.Internal.MoveBetween.NewPosition!"

call :ApplyQuantityDelta "%~3" "%~2" "!BC.Internal.MoveBetween.Quantity!" "%~4"
exit /b !errorlevel!

:WouldCreateCycle
set "BC.Internal.Cycle.Parent=%~1"
set "BC.Internal.Cycle.Child=%~2"
call :ClearPrefix "BC.Internal.Visit."
set "BC.Internal.Cycle.Found=0"
call :TraverseCollections "!BC.Internal.Cycle.Child!" "!BC.Internal.Cycle.Parent!"
call :ClearPrefix "BC.Internal.Visit."
if "!BC.Internal.Cycle.Found!"=="0" exit /b 0
call :SetError 30 CollectionCycle "Adding this nested collection would create a cycle." "!BC.Internal.Operation!" "%~1" "" NestedCollection "Acyclic relationship" "%~2"
exit /b 30

:TraverseCollections
if "!BC.Internal.Cycle.Found!"=="1" exit /b 0
if /i "%~1"=="%~2" (
    set "BC.Internal.Cycle.Found=1"
    exit /b 0
)
if defined BC.Internal.Visit.%~1 exit /b 0
set "BC.Internal.Visit.%~1=1"
if not defined BC.C.%~1.__Exists exit /b 0
if "!BC.C.%~1.Entry.Count!"=="0" exit /b 0

for /l %%I in (1,1,!BC.C.%~1.Entry.Count!) do (
    set "BC.Internal.Traverse.Entry=!BC.C.%~1.At.%%I!"
    for %%E in (!BC.Internal.Traverse.Entry!) do (
        if /i "!BC.E.%%E.Kind!"=="Collection" (
            call :TraverseCollections "!BC.E.%%E.Value!" "%~2"
        )
    )
)
exit /b 0

:MathAdd
call "!BC.Math!" :Add "%~1" "%~2" BCTempMath
if errorlevel 1 (
    call :SetError 30 CollectionArithmeticOverflow "Checked addition failed." "%~3" "%~4" "%~5" "%~6" "Signed 32-bit result" "%~1 + %~2"
    exit /b 30
)
set "BC.Internal.MathResult=!BCTempMath!"
exit /b 0

:MathSubtract
call "!BC.Math!" :Subtract "%~1" "%~2" BCTempMath
if errorlevel 1 (
    call :SetError 30 CollectionArithmeticOverflow "Checked subtraction failed." "%~3" "%~4" "%~5" "%~6" "Signed 32-bit result" "%~1 - %~2"
    exit /b 30
)
set "BC.Internal.MathResult=!BCTempMath!"
exit /b 0

:MathMultiply
call "!BC.Math!" :Multiply "%~1" "%~2" BCTempMath
if errorlevel 1 (
    call :SetError 30 CollectionArithmeticOverflow "Checked multiplication failed." "%~3" "%~4" "%~5" "%~6" "Signed 32-bit result" "%~1 * %~2"
    exit /b 30
)
set "BC.Internal.MathResult=!BCTempMath!"
exit /b 0

:ClearLastErrorInternal
for /f "tokens=1 delims==" %%V in ('set BC.LastError. 2^>nul') do set "%%V="
exit /b 0

:SetError
set "BC.LastError.Code=%~1"
set "BC.LastError.Kind=%~2"
set "BC.LastError.Message=%~3"
set "BC.LastError.Operation=%~4"
set "BC.LastError.Collection=%~5"
set "BC.LastError.Entry=%~6"
set "BC.LastError.Constraint=%~7"
set "BC.LastError.Expected=%~8"
set "BC.LastError.Actual=%~9"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
