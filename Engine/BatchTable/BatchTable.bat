@echo off

rem BatchTable.bat
rem Project-agnostic schema-controlled record tables with stable IDs and equality indexes.
rem Version 1.0.0 - protocol 1.
rem Requirement: caller must enable command extensions and delayed expansion.
rem
rem Scalar values remain restricted metadata. Arbitrary text belongs in BatchText handles.
rem Record IDs are stable, monotonic, table-scoped identifiers and are never reused.
rem BatchCollection owns ordered record lists, index buckets, and caller-owned query results.

set "BTAB.Internal.DelayedProbe=1"
if not "!BTAB.Internal.DelayedProbe!"=="1" (
    echo BatchTable requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="create" goto :Readable.Create
if /i "%~1"=="define" goto :Readable.Define
if /i "%~1"=="set" goto :Readable.Set
if /i "%~1"=="clear" goto :Readable.Clear
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="check" goto :Readable.Check
if /i "%~1"=="validate" goto :Readable.Validate
if /i "%~1"=="find" goto :Readable.Find
if /i "%~1"=="delete" goto :Readable.Delete
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="release" goto :Readable.Release
if /i "%~1"=="get" goto :Readable.Get

if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":CreateTable" goto :CreateTable
if /i "%~1"==":DefineField" goto :DefineField
if /i "%~1"==":ReadFieldSchema" goto :ReadFieldSchema
if /i "%~1"==":DefineIndex" goto :DefineIndex
if /i "%~1"==":ReadIndex" goto :ReadIndex
if /i "%~1"==":CreateRecord" goto :CreateRecord
if /i "%~1"==":SetField" goto :SetField
if /i "%~1"==":ClearField" goto :ClearField
if /i "%~1"==":ReadField" goto :ReadField
if /i "%~1"==":HasField" goto :HasField
if /i "%~1"==":ValidateRecord" goto :ValidateRecord
if /i "%~1"==":ReadRecord" goto :ReadRecord
if /i "%~1"==":GetRecordAt" goto :GetRecordAt
if /i "%~1"==":FindEqual" goto :FindEqual
if /i "%~1"==":FindUnique" goto :FindUnique
if /i "%~1"==":ListRecords" goto :ListRecords
if /i "%~1"==":ListIndexes" goto :ListIndexes
if /i "%~1"==":DeleteRecord" goto :DeleteRecord
if /i "%~1"==":ReleaseTable" goto :ReleaseTable
if /i "%~1"==":GetStat" goto :GetStat
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :EnsureInitialized
call :SetError 10 UnknownTableCommand "Unknown BatchTable command." Dispatch "" "" Command "Known BatchTable command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="tables" goto :Readable.Syntax
call "%~f0" :Initialize
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="tables" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Create
if /i "%~2"=="table" (
    if /i not "%~4"=="into" goto :Readable.Syntax
    call "%~f0" :CreateTable "%~3" "%~5"
    exit /b !errorlevel!
)
if /i "%~2"=="record" (
    if /i not "%~3"=="in" goto :Readable.Syntax
    if /i not "%~4"=="table" goto :Readable.Syntax
    if /i not "%~6"=="into" goto :Readable.Syntax
    call "%~f0" :CreateRecord "%~5" "%~7" ""
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Define
if /i "%~2"=="field" (
    if /i not "%~4"=="in" goto :Readable.Syntax
    if /i not "%~5"=="table" goto :Readable.Syntax
    if /i not "%~7"=="as" goto :Readable.Syntax
    call "%~f0" :DefineField "%~6" "%~3" "%~8" false false "" "" ""
    exit /b !errorlevel!
)
if /i "%~2"=="index" (
    if /i not "%~4"=="on" goto :Readable.Syntax
    if /i not "%~5"=="field" goto :Readable.Syntax
    if /i not "%~7"=="in" goto :Readable.Syntax
    if /i not "%~8"=="table" goto :Readable.Syntax
    call "%~f0" :DefineIndex "%~9" "%~3" "%~6" false CaseSensitive
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Set
if /i not "%~2"=="field" goto :Readable.Syntax
if /i not "%~4"=="in" goto :Readable.Syntax
if /i not "%~5"=="record" goto :Readable.Syntax
if /i not "%~7"=="to" goto :Readable.Syntax
call "%~f0" :SetField "%~6" "%~3" "%~8"
exit /b !errorlevel!

:Readable.Clear
if /i "%~2"=="field" (
    if /i not "%~4"=="in" goto :Readable.Syntax
    if /i not "%~5"=="record" goto :Readable.Syntax
    call "%~f0" :ClearField "%~6" "%~3"
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    call "%~f0" :ClearLastError
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Read
if /i "%~2"=="field" (
    if /i not "%~4"=="from" goto :Readable.Syntax
    if /i not "%~5"=="record" goto :Readable.Syntax
    if /i not "%~7"=="into" goto :Readable.Syntax
    call "%~f0" :ReadField "%~6" "%~3" "%~8"
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    if /i not "%~5"=="into" goto :Readable.Syntax
    call "%~f0" :ReadLastError "%~4" "%~6"
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Check
if /i not "%~2"=="field" goto :Readable.Syntax
if /i not "%~4"=="in" goto :Readable.Syntax
if /i not "%~5"=="record" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :HasField "%~6" "%~3" "%~8"
exit /b !errorlevel!

:Readable.Validate
if /i not "%~2"=="record" goto :Readable.Syntax
call "%~f0" :ValidateRecord "%~3"
exit /b !errorlevel!

:Readable.Find
if /i not "%~2"=="value" goto :Readable.Syntax
if /i not "%~4"=="in" goto :Readable.Syntax
if /i not "%~6"=="by" goto :Readable.Syntax
if /i not "%~8"=="into" goto :Readable.Syntax
call "%~f0" :FindEqual "%~5" "%~7" "%~3" "%~9"
exit /b !errorlevel!

:Readable.Delete
if /i not "%~2"=="record" goto :Readable.Syntax
call "%~f0" :DeleteRecord "%~3"
exit /b !errorlevel!

:Readable.Show
if /i "%~2"=="records" (
    if /i not "%~3"=="in" goto :Readable.Syntax
    if /i not "%~4"=="table" goto :Readable.Syntax
    call "%~f0" :ListRecords "%~5"
    exit /b !errorlevel!
)
if /i "%~2"=="indexes" (
    if /i not "%~3"=="in" goto :Readable.Syntax
    if /i not "%~4"=="table" goto :Readable.Syntax
    call "%~f0" :ListIndexes "%~5"
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    call "%~f0" :PrintLastError
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Release
if /i not "%~2"=="table" goto :Readable.Syntax
call "%~f0" :ReleaseTable "%~3"
exit /b !errorlevel!

:Readable.Get
if /i not "%~2"=="statistic" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :GetStat "%~3" "%~5"
exit /b !errorlevel!

:Readable.Syntax
call :EnsureInitialized
call :SetError 10 InvalidTableSyntax "BatchTable command syntax is invalid." Readable "" "" Syntax "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BTAB.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)

call :ClearPrefix "BTAB."
set "BTAB.Validator=%~dp0..\BatchValidate\BatchValidate.bat"
set "BTAB.Math=%~dp0..\BatchMath\BatchMath.bat"
set "BTAB.Collection=%~dp0..\BatchCollection\BatchCollection.bat"

if not exist "!BTAB.Validator!" (
    call :SetError 50 ValidationDependencyMissing "BatchValidate is required by BatchTable." Initialize "" "" Dependency "Existing BatchValidate component" "Missing"
    exit /b 50
)

if not exist "!BTAB.Math!" (
    call :SetError 50 MathDependencyMissing "BatchMath is required by BatchTable." Initialize "" "" Dependency "Existing BatchMath component" "Missing"
    exit /b 50
)

if not exist "!BTAB.Collection!" (
    call :SetError 50 CollectionDependencyMissing "BatchCollection is required by BatchTable." Initialize "" "" Dependency "Existing BatchCollection component" "Missing"
    exit /b 50
)

call "!BTAB.Math!" :Initialize
if errorlevel 1 (
    call :SetError 50 MathDependencyFailed "BatchMath could not be initialized." Initialize "" "" Dependency "Initialized BatchMath" "Initialization failed"
    exit /b 50
)

call "!BTAB.Collection!" :Initialize
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not be initialized." Initialize "" "" Dependency "Initialized BatchCollection" "Initialization failed"
    exit /b 50
)

set "BTAB.Initialized=1"
set "BTAB.Version=1.0.0"
set "BTAB.Protocol=1"
set "BTAB.Table.Sequence=0"
set "BTAB.Table.Count=0"
set "BTAB.Record.Count=0"
set "BTAB.Index.Count=0"
set "BTAB.Query.Sequence=0"
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
if not "!BTAB.Table.Count!"=="0" (
    call :SetError 30 ActiveTablesRemain "BatchTable cannot shut down while tables remain active." Shutdown "" "" TableCount "0" "!BTAB.Table.Count!"
    exit /b 30
)
call :ClearPrefix "BTAB."
exit /b 0

:CreateTable
call :BeginOperation CreateTable
if errorlevel 1 exit /b !errorlevel!
call :ValidateIdentifier "%~2" TableName
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.CreateTable.Name=!BTAB.Internal.Validated!"
if not "!BTAB.Internal.CreateTable.Name:~55,1!"=="" (
    call :SetError 20 TableNameTooLong "Table names must leave room for six-digit automatic record IDs." CreateTable "" "" TableName "At most 55 characters" "!BTAB.Internal.CreateTable.Name!"
    exit /b 20
)
if defined BTAB.Name.!BTAB.Internal.CreateTable.Name! (
    call :SetError 30 TableNameAlreadyExists "A table with this name already exists." CreateTable "" "" TableName "Unused table name" "!BTAB.Internal.CreateTable.Name!"
    exit /b 30
)
call :PrepareOutput "%~3" CreateTable
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.CreateTable.Output=!BTAB.Internal.Output!"

call :MathAdd "!BTAB.Table.Sequence!" 1 CreateTable "" "" TableSequence
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Table.Sequence=!BTAB.Internal.MathResult!"
set "BTAB.Internal.CreateTable.Handle=BTB!BTAB.Table.Sequence!"
set "BTAB.Internal.CreateTable.CollectionName=BTAB_!BTAB.Internal.CreateTable.Handle!_Records"

call "!BTAB.Collection!" :Create "!BTAB.Internal.CreateTable.CollectionName!" BTABTempCollection
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not create the ordered record list." CreateTable "!BTAB.Internal.CreateTable.Handle!" "" Dependency "Created internal record collection" "Creation failed"
    exit /b 50
)

call "!BTAB.Collection!" :SetPolicy "!BTABTempCollection!" Duplicates Reject
if errorlevel 1 goto :CreateTable.DependencyFailure
call "!BTAB.Collection!" :SetPolicy "!BTABTempCollection!" Comparison CaseInsensitive
if errorlevel 1 goto :CreateTable.DependencyFailure

set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.__Exists=1"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Name=!BTAB.Internal.CreateTable.Name!"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Field.Sequence=0"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Field.Count=0"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Record.Sequence=0"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Record.Count=0"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Records=!BTABTempCollection!"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Index.Sequence=0"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.Index.Count=0"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.SchemaLocked=0"
set "BTAB.T.!BTAB.Internal.CreateTable.Handle!.SchemaReferenceCount=0"
set "BTAB.Name.!BTAB.Internal.CreateTable.Name!=!BTAB.Internal.CreateTable.Handle!"
call :MathAdd "!BTAB.Table.Count!" 1 CreateTable "!BTAB.Internal.CreateTable.Handle!" "" TableCount
if errorlevel 1 goto :CreateTable.DependencyFailure
set "BTAB.Table.Count=!BTAB.Internal.MathResult!"

for %%O in ("!BTAB.Internal.CreateTable.Output!") do set "%%~O=!BTAB.Internal.CreateTable.Handle!"
exit /b 0

:CreateTable.DependencyFailure
call "!BTAB.Collection!" :Release "!BTABTempCollection!" >nul 2>nul
call :SetError 50 CollectionDependencyFailed "BatchCollection could not configure the ordered record list." CreateTable "!BTAB.Internal.CreateTable.Handle!" "" Dependency "Configured internal record collection" "Configuration failed"
exit /b 50

:DefineField
call :BeginOperation DefineField
if errorlevel 1 exit /b !errorlevel!
call :RequireTable "%~2" DefineField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineField.Table=%~2"

if "!BTAB.T.%~2.SchemaLocked!"=="1" (
    call :SetError 30 SchemaLocked "Fields cannot be added after the first record is created." DefineField "%~2" "" Schema "Unlocked table schema" "Locked"
    exit /b 30
)

call :ValidateIdentifier "%~3" FieldName
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineField.Name=!BTAB.Internal.Validated!"
for %%F in ("!BTAB.Internal.DefineField.Name!") do (
    if defined BTAB.T.%~2.F.%%~F.Exists (
        call :SetError 30 FieldAlreadyExists "The field is already defined." DefineField "%~2" "" FieldName "Unused field name" "%%~F"
        exit /b 30
    )
)

call :ValidateEnum "%~4" "Int,UInt,Bool,Id,DottedId,Enum,Reference,Text,Object,Collection" FieldType
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineField.Type=!BTAB.Internal.Validated!"

call :ValidateBoolean "%~5" Required
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineField.Required=!BTAB.Internal.Validated!"

call :ValidateBoolean "%~6" HasDefault
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineField.HasDefault=!BTAB.Internal.Validated!"
set "BTAB.Internal.DefineField.Default=%~7"
set "BTAB.Internal.DefineField.Choices=%~8"
set "BTAB.Internal.DefineField.ReferenceTable=%~9"

if /i "!BTAB.Internal.DefineField.Type!"=="Enum" (
    if "!BTAB.Internal.DefineField.Choices!"=="" (
        call :SetError 20 EnumChoicesRequired "Enum fields require one or more choices." DefineField "%~2" "" Choices "Comma-delimited identifier choices" "Empty"
        exit /b 20
    )
    call :ValidateEnumChoices "!BTAB.Internal.DefineField.Choices!" Choices
    if errorlevel 1 exit /b !errorlevel!
    set "BTAB.Internal.DefineField.Choices=!BTAB.Internal.Validated!"
) else (
    if not "!BTAB.Internal.DefineField.Choices!"=="" (
        call :SetError 20 UnexpectedChoices "Only Enum fields may define choices." DefineField "%~2" "" Choices "Empty" "!BTAB.Internal.DefineField.Choices!"
        exit /b 20
    )
)

if /i "!BTAB.Internal.DefineField.Type!"=="Reference" (
    call :RequireTable "!BTAB.Internal.DefineField.ReferenceTable!" DefineField
    if errorlevel 1 exit /b !errorlevel!
    if "!BTAB.Internal.DefineField.HasDefault!"=="1" (
        call :SetError 20 ReferenceDefaultUnsupported "Reference fields cannot define defaults in protocol 1." DefineField "%~2" "" Default "No reference default" "!BTAB.Internal.DefineField.Default!"
        exit /b 20
    )
) else (
    if not "!BTAB.Internal.DefineField.ReferenceTable!"=="" (
        call :SetError 20 UnexpectedReferenceTable "Only Reference fields may name a target table." DefineField "%~2" "" ReferenceTable "Empty" "!BTAB.Internal.DefineField.ReferenceTable!"
        exit /b 20
    )
)

if "!BTAB.Internal.DefineField.HasDefault!"=="1" (
    call :ValidateValueByType "!BTAB.Internal.DefineField.Type!" "!BTAB.Internal.DefineField.Default!" "!BTAB.Internal.DefineField.Choices!" "" 0
    if errorlevel 1 exit /b !errorlevel!
    set "BTAB.Internal.DefineField.Default=!BTAB.Internal.Validated!"
) else (
    if not "!BTAB.Internal.DefineField.Default!"=="" (
        call :SetError 20 UnexpectedDefault "A field without a default must provide an empty default value." DefineField "%~2" "" Default "Empty" "!BTAB.Internal.DefineField.Default!"
        exit /b 20
    )
)

call :MathAdd "!BTAB.T.%~2.Field.Sequence!" 1 DefineField "%~2" "" FieldSequence
if errorlevel 1 exit /b !errorlevel!
set "BTAB.T.%~2.Field.Sequence=!BTAB.Internal.MathResult!"
set "BTAB.Internal.DefineField.Sequence=!BTAB.Internal.MathResult!"
call :MathAdd "!BTAB.T.%~2.Field.Count!" 1 DefineField "%~2" "" FieldCount
if errorlevel 1 exit /b !errorlevel!
set "BTAB.T.%~2.Field.Count=!BTAB.Internal.MathResult!"

for %%F in ("!BTAB.Internal.DefineField.Name!") do (
    set "BTAB.T.%~2.F.%%~F.Exists=1"
    set "BTAB.T.%~2.F.%%~F.Sequence=!BTAB.Internal.DefineField.Sequence!"
    set "BTAB.T.%~2.F.%%~F.Type=!BTAB.Internal.DefineField.Type!"
    set "BTAB.T.%~2.F.%%~F.Required=!BTAB.Internal.DefineField.Required!"
    set "BTAB.T.%~2.F.%%~F.HasDefault=!BTAB.Internal.DefineField.HasDefault!"
    set "BTAB.T.%~2.F.%%~F.Default=!BTAB.Internal.DefineField.Default!"
    set "BTAB.T.%~2.F.%%~F.Choices=!BTAB.Internal.DefineField.Choices!"
    set "BTAB.T.%~2.F.%%~F.ReferenceTable=!BTAB.Internal.DefineField.ReferenceTable!"
    set "BTAB.T.%~2.Field.Index.!BTAB.Internal.DefineField.Sequence!=%%~F"
)
if /i "!BTAB.Internal.DefineField.Type!"=="Reference" (
    for %%T in ("!BTAB.Internal.DefineField.ReferenceTable!") do (
        set /a BTAB.T.%%~T.SchemaReferenceCount+=1
    )
)
exit /b 0

:ReadFieldSchema
call :BeginOperation ReadFieldSchema
if errorlevel 1 exit /b !errorlevel!
call :RequireField "%~2" "%~3" ReadFieldSchema
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadFieldSchema.Name=!BTAB.Internal.Field.Name!"
call :ValidateEnum "%~4" "Sequence,Type,Required,HasDefault,Default,Choices,ReferenceTable" Property
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadFieldSchema.Property=!BTAB.Internal.Validated!"
call :PrepareOutput "%~5" ReadFieldSchema
if errorlevel 1 exit /b !errorlevel!
for %%F in ("!BTAB.Internal.ReadFieldSchema.Name!") do (
    for %%P in ("!BTAB.Internal.ReadFieldSchema.Property!") do (
        set "BTAB.Internal.ReadFieldSchema.Value=!BTAB.T.%~2.F.%%~F.%%~P!"
    )
)
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.ReadFieldSchema.Value!"
exit /b 0

:DefineIndex
call :BeginOperation DefineIndex
if errorlevel 1 exit /b !errorlevel!
call :RequireTable "%~2" DefineIndex
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineIndex.Table=%~2"

call :ValidateIdentifier "%~3" IndexName
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineIndex.Name=!BTAB.Internal.Validated!"
for %%I in ("!BTAB.Internal.DefineIndex.Name!") do (
    if defined BTAB.T.%~2.I.%%~I.Exists (
        call :SetError 30 IndexAlreadyExists "The index is already defined." DefineIndex "%~2" "" IndexName "Unused index name" "%%~I"
        exit /b 30
    )
)

call :RequireField "%~2" "%~4" DefineIndex
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineIndex.Field=!BTAB.Internal.Field.Name!"
for %%F in ("!BTAB.Internal.DefineIndex.Field!") do set "BTAB.Internal.DefineIndex.Type=!BTAB.T.%~2.F.%%~F.Type!"
call :RequireIndexableType "!BTAB.Internal.DefineIndex.Type!" DefineIndex "%~2" "!BTAB.Internal.DefineIndex.Field!"
if errorlevel 1 exit /b !errorlevel!

call :ValidateBoolean "%~5" Unique
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineIndex.Unique=!BTAB.Internal.Validated!"
call :ValidateEnum "%~6" "CaseSensitive,CaseInsensitive" Comparison
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.DefineIndex.Comparison=!BTAB.Internal.Validated!"

call :MathAdd "!BTAB.T.%~2.Index.Sequence!" 1 DefineIndex "%~2" "" IndexSequence
if errorlevel 1 exit /b !errorlevel!
set "BTAB.T.%~2.Index.Sequence=!BTAB.Internal.MathResult!"
set "BTAB.Internal.DefineIndex.Sequence=!BTAB.Internal.MathResult!"

for %%I in ("!BTAB.Internal.DefineIndex.Name!") do (
    set "BTAB.T.%~2.I.%%~I.Exists=1"
    set "BTAB.T.%~2.I.%%~I.Sequence=!BTAB.Internal.DefineIndex.Sequence!"
    set "BTAB.T.%~2.I.%%~I.Field=!BTAB.Internal.DefineIndex.Field!"
    set "BTAB.T.%~2.I.%%~I.Unique=!BTAB.Internal.DefineIndex.Unique!"
    set "BTAB.T.%~2.I.%%~I.Comparison=!BTAB.Internal.DefineIndex.Comparison!"
    set "BTAB.T.%~2.I.%%~I.Bucket.Sequence=0"
    set "BTAB.T.%~2.I.%%~I.Bucket.Count=0"
    set "BTAB.T.%~2.Index.Index.!BTAB.Internal.DefineIndex.Sequence!=%%~I"
)

call :BuildIndex "%~2" "!BTAB.Internal.DefineIndex.Name!"
if errorlevel 1 (
    call :RollbackIndex "%~2" "!BTAB.Internal.DefineIndex.Name!"
    exit /b !errorlevel!
)

call :MathAdd "!BTAB.T.%~2.Index.Count!" 1 DefineIndex "%~2" "" IndexCount
if errorlevel 1 (
    call :RollbackIndex "%~2" "!BTAB.Internal.DefineIndex.Name!"
    exit /b !errorlevel!
)
set "BTAB.T.%~2.Index.Count=!BTAB.Internal.MathResult!"
call :MathAdd "!BTAB.Index.Count!" 1 DefineIndex "%~2" "" GlobalIndexCount
if errorlevel 1 (
    call :RollbackIndex "%~2" "!BTAB.Internal.DefineIndex.Name!"
    exit /b !errorlevel!
)
set "BTAB.Index.Count=!BTAB.Internal.MathResult!"
exit /b 0

:ReadIndex
call :BeginOperation ReadIndex
if errorlevel 1 exit /b !errorlevel!
call :RequireIndex "%~2" "%~3" ReadIndex
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadIndex.Name=!BTAB.Internal.Index.Name!"
call :ValidateEnum "%~4" "Sequence,Field,Unique,Comparison,BucketCount" Property
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadIndex.Property=!BTAB.Internal.Validated!"
call :PrepareOutput "%~5" ReadIndex
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadIndex.Storage=!BTAB.Internal.ReadIndex.Property!"
if /i "!BTAB.Internal.ReadIndex.Property!"=="BucketCount" set "BTAB.Internal.ReadIndex.Storage=Bucket.Count"
for %%I in ("!BTAB.Internal.ReadIndex.Name!") do (
    for %%P in ("!BTAB.Internal.ReadIndex.Storage!") do (
        set "BTAB.Internal.ReadIndex.Value=!BTAB.T.%~2.I.%%~I.%%~P!"
    )
)
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.ReadIndex.Value!"
exit /b 0

:CreateRecord
call :BeginOperation CreateRecord
if errorlevel 1 exit /b !errorlevel!
call :RequireTable "%~2" CreateRecord
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.CreateRecord.Table=%~2"
call :PrepareOutput "%~3" CreateRecord
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.CreateRecord.Output=!BTAB.Internal.Output!"

call :MathAdd "!BTAB.T.%~2.Record.Sequence!" 1 CreateRecord "%~2" "" RecordSequence
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.CreateRecord.Sequence=!BTAB.Internal.MathResult!"
if !BTAB.Internal.CreateRecord.Sequence! GTR 999999 (
    call :SetError 30 RecordIdSpaceExhausted "The table has exhausted its protocol 1 automatic ID space." CreateRecord "%~2" "" RecordSequence "1 through 999999" "!BTAB.Internal.CreateRecord.Sequence!"
    exit /b 30
)

set "BTAB.Internal.CreateRecord.Id=%~4"
if "!BTAB.Internal.CreateRecord.Id!"=="" (
    set "BTAB.Internal.CreateRecord.Padded=000000!BTAB.Internal.CreateRecord.Sequence!"
    set "BTAB.Internal.CreateRecord.Padded=!BTAB.Internal.CreateRecord.Padded:~-6!"
    set "BTAB.Internal.CreateRecord.Id=!BTAB.T.%~2.Name!_!BTAB.Internal.CreateRecord.Padded!"
)

call :ValidateIdentifier "!BTAB.Internal.CreateRecord.Id!" RecordId
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.CreateRecord.Id=!BTAB.Internal.Validated!"
if defined BTAB.R.!BTAB.Internal.CreateRecord.Id!.__Exists (
    call :SetError 30 RecordIdAlreadyExists "The stable record ID already exists." CreateRecord "%~2" "!BTAB.Internal.CreateRecord.Id!" RecordId "Unused record ID" "!BTAB.Internal.CreateRecord.Id!"
    exit /b 30
)

set "BTAB.T.%~2.Record.Sequence=!BTAB.Internal.CreateRecord.Sequence!"
set "BTAB.T.%~2.SchemaLocked=1"
set "BTAB.R.!BTAB.Internal.CreateRecord.Id!.__Exists=1"
set "BTAB.R.!BTAB.Internal.CreateRecord.Id!.Table=%~2"
set "BTAB.R.!BTAB.Internal.CreateRecord.Id!.Sequence=!BTAB.Internal.CreateRecord.Sequence!"
set "BTAB.R.!BTAB.Internal.CreateRecord.Id!.ReferenceCount=0"
set "BTAB.R.!BTAB.Internal.CreateRecord.Id!.Valid=0"

call "!BTAB.Collection!" :Add "!BTAB.T.%~2.Records!" Value "!BTAB.Internal.CreateRecord.Id!" "" 1 0 BTABTempEntry
if errorlevel 1 (
    call :ClearPrefix "BTAB.R.!BTAB.Internal.CreateRecord.Id!."
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not append the record ID." CreateRecord "%~2" "!BTAB.Internal.CreateRecord.Id!" Dependency "Appended record ID" "Append failed"
    exit /b 50
)

call :MathAdd "!BTAB.T.%~2.Record.Count!" 1 CreateRecord "%~2" "!BTAB.Internal.CreateRecord.Id!" RecordCount
if errorlevel 1 goto :CreateRecord.RollbackArithmetic
set "BTAB.T.%~2.Record.Count=!BTAB.Internal.MathResult!"
call :MathAdd "!BTAB.Record.Count!" 1 CreateRecord "%~2" "!BTAB.Internal.CreateRecord.Id!" GlobalRecordCount
if errorlevel 1 goto :CreateRecord.RollbackArithmetic
set "BTAB.Record.Count=!BTAB.Internal.MathResult!"

if not "!BTAB.T.%~2.Field.Sequence!"=="0" (
    for /l %%N in (1,1,!BTAB.T.%~2.Field.Sequence!) do (
        set "BTAB.Internal.CreateRecord.Field=!BTAB.T.%~2.Field.Index.%%N!"
        if defined BTAB.Internal.CreateRecord.Field (
            for %%F in ("!BTAB.Internal.CreateRecord.Field!") do (
                if "!BTAB.T.%~2.F.%%~F.HasDefault!"=="1" (
                    call :SetFieldCore "!BTAB.Internal.CreateRecord.Id!" "%%~F" "!BTAB.T.%~2.F.%%~F.Default!" CreateRecord
                    if errorlevel 1 goto :CreateRecord.Rollback
                )
            )
        )
    )
)

for %%O in ("!BTAB.Internal.CreateRecord.Output!") do set "%%~O=!BTAB.Internal.CreateRecord.Id!"
exit /b 0

:CreateRecord.RollbackArithmetic
call :SetError 30 TableArithmeticOverflow "Record counters exceeded the signed 32-bit range." CreateRecord "%~2" "!BTAB.Internal.CreateRecord.Id!" RecordCount "Signed 32-bit result" "Overflow"
goto :CreateRecord.Rollback

:CreateRecord.Rollback
set "BTAB.Work.Error.Code=!BTAB.LastError.Code!"
set "BTAB.Work.Error.Kind=!BTAB.LastError.Kind!"
set "BTAB.Work.Error.Message=!BTAB.LastError.Message!"
set "BTAB.Work.Error.Operation=!BTAB.LastError.Operation!"
set "BTAB.Work.Error.Table=!BTAB.LastError.Table!"
set "BTAB.Work.Error.Record=!BTAB.LastError.Record!"
set "BTAB.Work.Error.Constraint=!BTAB.LastError.Constraint!"
set "BTAB.Work.Error.Expected=!BTAB.LastError.Expected!"
set "BTAB.Work.Error.Actual=!BTAB.LastError.Actual!"
call :RemoveRecordCore "!BTAB.Internal.CreateRecord.Id!" Rollback
call :SetError "!BTAB.Work.Error.Code!" "!BTAB.Work.Error.Kind!" "!BTAB.Work.Error.Message!" "!BTAB.Work.Error.Operation!" "!BTAB.Work.Error.Table!" "!BTAB.Work.Error.Record!" "!BTAB.Work.Error.Constraint!" "!BTAB.Work.Error.Expected!" "!BTAB.Work.Error.Actual!"
exit /b !BTAB.LastError.Code!

:SetField
call :BeginOperation SetField
if errorlevel 1 exit /b !errorlevel!
call :SetFieldCore "%~2" "%~3" "%~4" SetField
exit /b !errorlevel!

:ClearField
call :BeginOperation ClearField
if errorlevel 1 exit /b !errorlevel!
call :RequireRecord "%~2" ClearField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ClearField.Record=%~2"
set "BTAB.Internal.ClearField.Table=!BTAB.R.%~2.Table!"
call :RequireField "!BTAB.Internal.ClearField.Table!" "%~3" ClearField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ClearField.Name=!BTAB.Internal.Field.Name!"

for %%F in ("!BTAB.Internal.ClearField.Name!") do (
    if not defined BTAB.R.%~2.F.%%~F.Set exit /b 0
    set "BTAB.Internal.ClearField.Old=!BTAB.R.%~2.F.%%~F.Value!"
    for %%T in ("!BTAB.Internal.ClearField.Table!") do (
        set "BTAB.Internal.ClearField.Type=!BTAB.T.%%~T.F.%%~F.Type!"
    )
)

call :UpdateIndexesForField "!BTAB.Internal.ClearField.Table!" "%~2" "!BTAB.Internal.ClearField.Name!" 1 "!BTAB.Internal.ClearField.Old!" 0 ""
if errorlevel 1 exit /b !errorlevel!

if /i "!BTAB.Internal.ClearField.Type!"=="Reference" (
    if defined BTAB.R.!BTAB.Internal.ClearField.Old!.__Exists (
        set /a BTAB.R.!BTAB.Internal.ClearField.Old!.ReferenceCount-=1
    )
)

for %%F in ("!BTAB.Internal.ClearField.Name!") do (
    set "BTAB.R.%~2.F.%%~F.Set="
    set "BTAB.R.%~2.F.%%~F.Value="
)
set "BTAB.R.%~2.Valid=0"
exit /b 0

:ReadField
call :BeginOperation ReadField
if errorlevel 1 exit /b !errorlevel!
call :RequireRecord "%~2" ReadField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadField.Table=!BTAB.R.%~2.Table!"
call :RequireField "!BTAB.Internal.ReadField.Table!" "%~3" ReadField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadField.Name=!BTAB.Internal.Field.Name!"
call :PrepareOutput "%~4" ReadField
if errorlevel 1 exit /b !errorlevel!

for %%F in ("!BTAB.Internal.ReadField.Name!") do (
    if not defined BTAB.R.%~2.F.%%~F.Set (
        call :SetError 30 FieldValueMissing "The record field is not set." ReadField "!BTAB.Internal.ReadField.Table!" "%~2" Field "Set field value" "%%~F"
        exit /b 30
    )
    set "BTAB.Internal.ReadField.Value=!BTAB.R.%~2.F.%%~F.Value!"
)

for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.ReadField.Value!"
exit /b 0

:HasField
call :BeginOperation HasField
if errorlevel 1 exit /b !errorlevel!
call :RequireRecord "%~2" HasField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.HasField.Table=!BTAB.R.%~2.Table!"
call :RequireField "!BTAB.Internal.HasField.Table!" "%~3" HasField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.HasField.Name=!BTAB.Internal.Field.Name!"
call :PrepareOutput "%~4" HasField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.HasField.Result=0"
for %%F in ("!BTAB.Internal.HasField.Name!") do (
    if defined BTAB.R.%~2.F.%%~F.Set set "BTAB.Internal.HasField.Result=1"
)
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.HasField.Result!"
exit /b 0

:ValidateRecord
call :BeginOperation ValidateRecord
if errorlevel 1 exit /b !errorlevel!
call :RequireRecord "%~2" ValidateRecord
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ValidateRecord.Table=!BTAB.R.%~2.Table!"

for %%T in ("!BTAB.Internal.ValidateRecord.Table!") do (
    if not "!BTAB.T.%%~T.Field.Sequence!"=="0" (
        for /l %%N in (1,1,!BTAB.T.%%~T.Field.Sequence!) do (
            set "BTAB.Internal.ValidateRecord.Field=!BTAB.T.%%~T.Field.Index.%%N!"
            if defined BTAB.Internal.ValidateRecord.Field (
                for %%F in ("!BTAB.Internal.ValidateRecord.Field!") do (
                    if "!BTAB.T.%%~T.F.%%~F.Required!"=="1" (
                        if not defined BTAB.R.%~2.F.%%~F.Set (
                            call :SetError 30 RequiredFieldMissing "A required record field is not set." ValidateRecord "%%~T" "%~2" RequiredField "Set value" "%%~F"
                            exit /b 30
                        )
                    )
                    if defined BTAB.R.%~2.F.%%~F.Set (
                        if /i "!BTAB.T.%%~T.F.%%~F.Type!"=="Reference" (
                            set "BTAB.Internal.ValidateRecord.Reference=!BTAB.R.%~2.F.%%~F.Value!"
                            for %%R in ("!BTAB.Internal.ValidateRecord.Reference!") do (
                                if not defined BTAB.R.%%~R.__Exists (
                                    call :SetError 30 DanglingReference "A reference field points to a missing record." ValidateRecord "%%~T" "%~2" Reference "Live record ID" "%%~R"
                                    exit /b 30
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

set "BTAB.R.%~2.Valid=1"
exit /b 0

:ReadRecord
call :BeginOperation ReadRecord
if errorlevel 1 exit /b !errorlevel!
call :RequireRecord "%~2" ReadRecord
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~3" "Table,Sequence,ReferenceCount,Valid" Property
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadRecord.Property=!BTAB.Internal.Validated!"
call :PrepareOutput "%~4" ReadRecord
if errorlevel 1 exit /b !errorlevel!
for %%P in ("!BTAB.Internal.ReadRecord.Property!") do set "BTAB.Internal.ReadRecord.Value=!BTAB.R.%~2.%%~P!"
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.ReadRecord.Value!"
exit /b 0

:GetRecordAt
call :BeginOperation GetRecordAt
if errorlevel 1 exit /b !errorlevel!
call :RequireTable "%~2" GetRecordAt
if errorlevel 1 exit /b !errorlevel!
call :ValidatePositive "%~3" Index
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.GetRecordAt.Index=!BTAB.Internal.Validated!"
call :PrepareOutput "%~4" GetRecordAt
if errorlevel 1 exit /b !errorlevel!
call "!BTAB.Collection!" :GetAt "!BTAB.T.%~2.Records!" "!BTAB.Internal.GetRecordAt.Index!" BTABTempEntry
if errorlevel 1 (
    call :SetError 20 RecordIndexOutOfRange "The record index is outside the table." GetRecordAt "%~2" "" Index "Existing record position" "!BTAB.Internal.GetRecordAt.Index!"
    exit /b 20
)
call "!BTAB.Collection!" :ReadEntry "!BTABTempEntry!" Value BTABTempValue
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not read the record ID." GetRecordAt "%~2" "" Dependency "Readable record entry" "Read failed"
    exit /b 50
)
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTABTempValue!"
exit /b 0

:FindEqual
call :BeginOperation FindEqual
if errorlevel 1 exit /b !errorlevel!
call :RequireIndex "%~2" "%~3" FindEqual
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.FindEqual.Index=!BTAB.Internal.Index.Name!"
for %%I in ("!BTAB.Internal.FindEqual.Index!") do (
    set "BTAB.Internal.FindEqual.Field=!BTAB.T.%~2.I.%%~I.Field!"
)
for %%F in ("!BTAB.Internal.FindEqual.Field!") do (
    set "BTAB.Internal.FindEqual.Type=!BTAB.T.%~2.F.%%~F.Type!"
    set "BTAB.Internal.FindEqual.Choices=!BTAB.T.%~2.F.%%~F.Choices!"
    set "BTAB.Internal.FindEqual.ReferenceTable=!BTAB.T.%~2.F.%%~F.ReferenceTable!"
)
call :ValidateValueByType "!BTAB.Internal.FindEqual.Type!" "%~4" "!BTAB.Internal.FindEqual.Choices!" "!BTAB.Internal.FindEqual.ReferenceTable!" 0
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.FindEqual.Value=!BTAB.Internal.Validated!"
call :PrepareOutput "%~5" FindEqual
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.FindEqual.Output=!BTAB.Internal.Output!"

call :MathAdd "!BTAB.Query.Sequence!" 1 FindEqual "%~2" "" QuerySequence
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Query.Sequence=!BTAB.Internal.MathResult!"
set "BTAB.Internal.FindEqual.QueryName=BTAB_Query_!BTAB.Query.Sequence!"

call "!BTAB.Collection!" :Create "!BTAB.Internal.FindEqual.QueryName!" BTABTempQuery
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not create the query result." FindEqual "%~2" "" Dependency "Created query collection" "Creation failed"
    exit /b 50
)
call "!BTAB.Collection!" :SetPolicy "!BTABTempQuery!" Duplicates Reject
if errorlevel 1 goto :FindEqual.QueryFailure
call "!BTAB.Collection!" :SetPolicy "!BTABTempQuery!" Comparison CaseInsensitive
if errorlevel 1 goto :FindEqual.QueryFailure

call :FindBucket "%~2" "!BTAB.Internal.FindEqual.Index!" "!BTAB.Internal.FindEqual.Value!"
if defined BTAB.Internal.Bucket.Members (
    call "!BTAB.Collection!" :ReadCollection "!BTAB.Internal.Bucket.Members!" EntryCount BTABTempCount
    if errorlevel 1 goto :FindEqual.QueryFailure
    if not "!BTABTempCount!"=="0" (
        for /l %%N in (1,1,!BTABTempCount!) do (
            call "!BTAB.Collection!" :GetAt "!BTAB.Internal.Bucket.Members!" %%N BTABTempEntry
            if errorlevel 1 goto :FindEqual.QueryFailure
            call "!BTAB.Collection!" :ReadEntry "!BTABTempEntry!" Value BTABTempRecord
            if errorlevel 1 goto :FindEqual.QueryFailure
            call "!BTAB.Collection!" :Add "!BTABTempQuery!" Value "!BTABTempRecord!" "" 1 0 BTABTempAdded
            if errorlevel 1 goto :FindEqual.QueryFailure
        )
    )
)

for %%O in ("!BTAB.Internal.FindEqual.Output!") do set "%%~O=!BTABTempQuery!"
exit /b 0

:FindEqual.QueryFailure
call "!BTAB.Collection!" :Release "!BTABTempQuery!" >nul 2>nul
call :SetError 50 CollectionDependencyFailed "BatchCollection could not materialize the query result." FindEqual "%~2" "" Dependency "Materialized query collection" "Operation failed"
exit /b 50

:FindUnique
call :BeginOperation FindUnique
if errorlevel 1 exit /b !errorlevel!
call :RequireIndex "%~2" "%~3" FindUnique
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.FindUnique.Index=!BTAB.Internal.Index.Name!"
for %%I in ("!BTAB.Internal.FindUnique.Index!") do (
    if not "!BTAB.T.%~2.I.%%~I.Unique!"=="1" (
        call :SetError 30 UniqueIndexRequired "FindUnique requires a unique index." FindUnique "%~2" "" Index "Unique index" "%%~I"
        exit /b 30
    )
    set "BTAB.Internal.FindUnique.Field=!BTAB.T.%~2.I.%%~I.Field!"
)
for %%F in ("!BTAB.Internal.FindUnique.Field!") do (
    set "BTAB.Internal.FindUnique.Type=!BTAB.T.%~2.F.%%~F.Type!"
    set "BTAB.Internal.FindUnique.Choices=!BTAB.T.%~2.F.%%~F.Choices!"
    set "BTAB.Internal.FindUnique.ReferenceTable=!BTAB.T.%~2.F.%%~F.ReferenceTable!"
)
call :ValidateValueByType "!BTAB.Internal.FindUnique.Type!" "%~4" "!BTAB.Internal.FindUnique.Choices!" "!BTAB.Internal.FindUnique.ReferenceTable!" 0
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.FindUnique.Value=!BTAB.Internal.Validated!"
call :PrepareOutput "%~5" FindUnique
if errorlevel 1 exit /b !errorlevel!

call :FindBucket "%~2" "!BTAB.Internal.FindUnique.Index!" "!BTAB.Internal.FindUnique.Value!"
set "BTAB.Internal.FindUnique.Record="
if defined BTAB.Internal.Bucket.Members (
    call "!BTAB.Collection!" :ReadCollection "!BTAB.Internal.Bucket.Members!" EntryCount BTABTempCount
    if errorlevel 1 (
        call :SetError 50 CollectionDependencyFailed "BatchCollection could not read the unique index bucket." FindUnique "%~2" "" Dependency "Readable index bucket" "Read failed"
        exit /b 50
    )
    if "!BTABTempCount!"=="1" (
        call "!BTAB.Collection!" :GetAt "!BTAB.Internal.Bucket.Members!" 1 BTABTempEntry
        if errorlevel 1 exit /b 50
        call "!BTAB.Collection!" :ReadEntry "!BTABTempEntry!" Value BTABTempRecord
        if errorlevel 1 exit /b 50
        set "BTAB.Internal.FindUnique.Record=!BTABTempRecord!"
    )
)
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.FindUnique.Record!"
exit /b 0

:ListRecords
call :BeginOperation ListRecords
if errorlevel 1 exit /b !errorlevel!
call :RequireTable "%~2" ListRecords
if errorlevel 1 exit /b !errorlevel!
echo Table !BTAB.T.%~2.Name! [%~2]
echo Records: !BTAB.T.%~2.Record.Count!
if "!BTAB.T.%~2.Record.Count!"=="0" exit /b 0
for /l %%N in (1,1,!BTAB.T.%~2.Record.Count!) do (
    call "!BTAB.Collection!" :GetAt "!BTAB.T.%~2.Records!" %%N BTABTempEntry
    if errorlevel 1 exit /b 50
    call "!BTAB.Collection!" :ReadEntry "!BTABTempEntry!" Value BTABTempRecord
    if errorlevel 1 exit /b 50
    echo %%N: !BTABTempRecord!
)
exit /b 0

:ListIndexes
call :BeginOperation ListIndexes
if errorlevel 1 exit /b !errorlevel!
call :RequireTable "%~2" ListIndexes
if errorlevel 1 exit /b !errorlevel!
echo Table !BTAB.T.%~2.Name! [%~2]
echo Indexes: !BTAB.T.%~2.Index.Count!
if "!BTAB.T.%~2.Index.Sequence!"=="0" exit /b 0
for /l %%N in (1,1,!BTAB.T.%~2.Index.Sequence!) do (
    set "BTAB.Internal.ListIndexes.Name=!BTAB.T.%~2.Index.Index.%%N!"
    if defined BTAB.Internal.ListIndexes.Name (
        for %%I in ("!BTAB.Internal.ListIndexes.Name!") do (
            if defined BTAB.T.%~2.I.%%~I.Exists (
                echo %%~I Field=!BTAB.T.%~2.I.%%~I.Field! Unique=!BTAB.T.%~2.I.%%~I.Unique! Comparison=!BTAB.T.%~2.I.%%~I.Comparison! Buckets=!BTAB.T.%~2.I.%%~I.Bucket.Count!
            )
        )
    )
)
exit /b 0

:DeleteRecord
call :BeginOperation DeleteRecord
if errorlevel 1 exit /b !errorlevel!
call :RequireRecord "%~2" DeleteRecord
if errorlevel 1 exit /b !errorlevel!
if not "!BTAB.R.%~2.ReferenceCount!"=="0" (
    call :SetError 30 RecordReferenced "The record cannot be deleted while reference fields point to it." DeleteRecord "!BTAB.R.%~2.Table!" "%~2" ReferenceCount "0" "!BTAB.R.%~2.ReferenceCount!"
    exit /b 30
)
call :RemoveRecordCore "%~2" DeleteRecord
exit /b !errorlevel!

:ReleaseTable
call :BeginOperation ReleaseTable
if errorlevel 1 exit /b !errorlevel!
call :RequireTable "%~2" ReleaseTable
if errorlevel 1 exit /b !errorlevel!
if not "!BTAB.T.%~2.Record.Count!"=="0" (
    call :SetError 30 TableNotEmpty "A table must be empty before release." ReleaseTable "%~2" "" RecordCount "0" "!BTAB.T.%~2.Record.Count!"
    exit /b 30
)

set "BTAB.Internal.ReleaseTable.SelfReferences=0"
if not "!BTAB.T.%~2.Field.Sequence!"=="0" (
    for /l %%N in (1,1,!BTAB.T.%~2.Field.Sequence!) do (
        set "BTAB.Internal.ReleaseTable.Field=!BTAB.T.%~2.Field.Index.%%N!"
        if defined BTAB.Internal.ReleaseTable.Field (
            for %%F in ("!BTAB.Internal.ReleaseTable.Field!") do (
                if /i "!BTAB.T.%~2.F.%%~F.Type!"=="Reference" (
                    if /i "!BTAB.T.%~2.F.%%~F.ReferenceTable!"=="%~2" (
                        set /a BTAB.Internal.ReleaseTable.SelfReferences+=1
                    )
                )
            )
        )
    )
)
set /a BTAB.Internal.ReleaseTable.ExternalReferences=BTAB.T.%~2.SchemaReferenceCount-BTAB.Internal.ReleaseTable.SelfReferences
if !BTAB.Internal.ReleaseTable.ExternalReferences! GTR 0 (
    call :SetError 30 TableSchemaReferenced "Another table schema still references this table." ReleaseTable "%~2" "" SchemaReferenceCount "Only self-references" "!BTAB.T.%~2.SchemaReferenceCount!"
    exit /b 30
)

if not "!BTAB.T.%~2.Index.Sequence!"=="0" (
    for /l %%N in (1,1,!BTAB.T.%~2.Index.Sequence!) do (
        set "BTAB.Internal.ReleaseTable.Index=!BTAB.T.%~2.Index.Index.%%N!"
        if defined BTAB.Internal.ReleaseTable.Index (
            for %%I in ("!BTAB.Internal.ReleaseTable.Index!") do (
                if defined BTAB.T.%~2.I.%%~I.Exists (
                    call :ReleaseIndexBuckets "%~2" "%%~I"
                    if errorlevel 1 exit /b !errorlevel!
                    set /a BTAB.Index.Count-=1
                )
            )
        )
    )
)

if not "!BTAB.T.%~2.Field.Sequence!"=="0" (
    for /l %%N in (1,1,!BTAB.T.%~2.Field.Sequence!) do (
        set "BTAB.Internal.ReleaseTable.Field=!BTAB.T.%~2.Field.Index.%%N!"
        if defined BTAB.Internal.ReleaseTable.Field (
            for %%F in ("!BTAB.Internal.ReleaseTable.Field!") do (
                if /i "!BTAB.T.%~2.F.%%~F.Type!"=="Reference" (
                    set "BTAB.Internal.ReleaseTable.Target=!BTAB.T.%~2.F.%%~F.ReferenceTable!"
                    for %%T in ("!BTAB.Internal.ReleaseTable.Target!") do (
                        if defined BTAB.T.%%~T.__Exists (
                            set /a BTAB.T.%%~T.SchemaReferenceCount-=1
                        )
                    )
                )
            )
        )
    )
)

call "!BTAB.Collection!" :Release "!BTAB.T.%~2.Records!"
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not release the ordered record list." ReleaseTable "%~2" "" Dependency "Released internal record collection" "Release failed"
    exit /b 50
)

set "BTAB.Internal.ReleaseTable.Name=!BTAB.T.%~2.Name!"
set "BTAB.Name.!BTAB.Internal.ReleaseTable.Name!="
call :ClearPrefix "BTAB.T.%~2."
set /a BTAB.Table.Count-=1
exit /b 0

:GetStat
call :BeginOperation GetStat
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~2" "TableCount,RecordCount,IndexCount" Statistic
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.GetStat.Name=!BTAB.Internal.Validated!"
call :PrepareOutput "%~3" GetStat
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.GetStat.Value="
if /i "!BTAB.Internal.GetStat.Name!"=="TableCount" set "BTAB.Internal.GetStat.Value=!BTAB.Table.Count!"
if /i "!BTAB.Internal.GetStat.Name!"=="RecordCount" set "BTAB.Internal.GetStat.Value=!BTAB.Record.Count!"
if /i "!BTAB.Internal.GetStat.Name!"=="IndexCount" set "BTAB.Internal.GetStat.Value=!BTAB.Index.Count!"
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.GetStat.Value!"
exit /b 0

:ReadLastError
call :EnsureInitialized
if errorlevel 1 exit /b !errorlevel!
call :ValidateEnum "%~2" "Code,Kind,Message,Operation,Table,Record,Constraint,Expected,Actual" ErrorField
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.ReadError.Field=!BTAB.Internal.Validated!"
call :PrepareOutput "%~3" ReadLastError
if errorlevel 1 exit /b !errorlevel!
for %%F in ("!BTAB.Internal.ReadError.Field!") do set "BTAB.Internal.ReadError.Value=!BTAB.LastError.%%~F!"
for %%O in ("!BTAB.Internal.Output!") do set "%%~O=!BTAB.Internal.ReadError.Value!"
exit /b 0

:PrintLastError
call :EnsureInitialized
if errorlevel 1 exit /b !errorlevel!
if not defined BTAB.LastError.Code (
    echo BatchTable has no recorded error.
    exit /b 0
)
echo BatchTable error !BTAB.LastError.Code! [!BTAB.LastError.Kind!]
echo Message: !BTAB.LastError.Message!
echo Operation: !BTAB.LastError.Operation!
if defined BTAB.LastError.Table echo Table: !BTAB.LastError.Table!
if defined BTAB.LastError.Record echo Record: !BTAB.LastError.Record!
if defined BTAB.LastError.Constraint echo Constraint: !BTAB.LastError.Constraint!
if defined BTAB.LastError.Expected echo Expected: !BTAB.LastError.Expected!
if defined BTAB.LastError.Actual echo Actual: !BTAB.LastError.Actual!
exit /b 0

:ClearLastError
call :EnsureInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
exit /b 0

:SetFieldCore
call :RequireRecord "%~1" "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.SetField.Record=%~1"
set "BTAB.Internal.SetField.Table=!BTAB.R.%~1.Table!"
call :RequireField "!BTAB.Internal.SetField.Table!" "%~2" "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.SetField.Name=!BTAB.Internal.Field.Name!"

for %%T in ("!BTAB.Internal.SetField.Table!") do (
    for %%F in ("!BTAB.Internal.SetField.Name!") do (
        set "BTAB.Internal.SetField.Type=!BTAB.T.%%~T.F.%%~F.Type!"
        set "BTAB.Internal.SetField.Choices=!BTAB.T.%%~T.F.%%~F.Choices!"
        set "BTAB.Internal.SetField.ReferenceTable=!BTAB.T.%%~T.F.%%~F.ReferenceTable!"
    )
)

call :ValidateValueByType "!BTAB.Internal.SetField.Type!" "%~3" "!BTAB.Internal.SetField.Choices!" "!BTAB.Internal.SetField.ReferenceTable!" 1
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.SetField.New=!BTAB.Internal.Validated!"
set "BTAB.Internal.SetField.OldSet=0"
set "BTAB.Internal.SetField.Old="
for %%F in ("!BTAB.Internal.SetField.Name!") do (
    if defined BTAB.R.%~1.F.%%~F.Set (
        set "BTAB.Internal.SetField.OldSet=1"
        set "BTAB.Internal.SetField.Old=!BTAB.R.%~1.F.%%~F.Value!"
    )
)

if "!BTAB.Internal.SetField.OldSet!"=="1" if "!BTAB.Internal.SetField.Old!"=="!BTAB.Internal.SetField.New!" exit /b 0

call :PreflightIndexesForField "!BTAB.Internal.SetField.Table!" "%~1" "!BTAB.Internal.SetField.Name!" "!BTAB.Internal.SetField.New!"
if errorlevel 1 exit /b !errorlevel!

call :UpdateIndexesForField "!BTAB.Internal.SetField.Table!" "%~1" "!BTAB.Internal.SetField.Name!" "!BTAB.Internal.SetField.OldSet!" "!BTAB.Internal.SetField.Old!" 1 "!BTAB.Internal.SetField.New!"
if errorlevel 1 exit /b !errorlevel!

if /i "!BTAB.Internal.SetField.Type!"=="Reference" (
    if "!BTAB.Internal.SetField.OldSet!"=="1" if defined BTAB.R.!BTAB.Internal.SetField.Old!.__Exists (
        set /a BTAB.R.!BTAB.Internal.SetField.Old!.ReferenceCount-=1
    )
    set /a BTAB.R.!BTAB.Internal.SetField.New!.ReferenceCount+=1
)

for %%F in ("!BTAB.Internal.SetField.Name!") do (
    set "BTAB.R.%~1.F.%%~F.Set=1"
    set "BTAB.R.%~1.F.%%~F.Value=!BTAB.Internal.SetField.New!"
)
set "BTAB.R.%~1.Valid=0"
exit /b 0

:PreflightIndexesForField
if "!BTAB.T.%~1.Index.Sequence!"=="0" exit /b 0
for /l %%N in (1,1,!BTAB.T.%~1.Index.Sequence!) do (
    set "BTAB.Internal.Preflight.Index=!BTAB.T.%~1.Index.Index.%%N!"
    if defined BTAB.Internal.Preflight.Index (
        for %%I in ("!BTAB.Internal.Preflight.Index!") do (
            if defined BTAB.T.%~1.I.%%~I.Exists (
                if /i "!BTAB.T.%~1.I.%%~I.Field!"=="%~3" (
                    if "!BTAB.T.%~1.I.%%~I.Unique!"=="1" (
                        call :CheckUniqueIndexValue "%~1" "%%~I" "%~4" "%~2"
                        if errorlevel 1 exit /b !errorlevel!
                    )
                )
            )
        )
    )
)
exit /b 0

:UpdateIndexesForField
if "!BTAB.T.%~1.Index.Sequence!"=="0" exit /b 0
for /l %%N in (1,1,!BTAB.T.%~1.Index.Sequence!) do (
    set "BTAB.Internal.UpdateIndexes.Index=!BTAB.T.%~1.Index.Index.%%N!"
    if defined BTAB.Internal.UpdateIndexes.Index (
        for %%I in ("!BTAB.Internal.UpdateIndexes.Index!") do (
            if defined BTAB.T.%~1.I.%%~I.Exists (
                if /i "!BTAB.T.%~1.I.%%~I.Field!"=="%~3" (
                    set "BTAB.Internal.UpdateIndexes.Same=0"
                    if "%~4"=="1" if "%~6"=="1" (
                        call :IndexValuesEqual "%~1" "%%~I" "%~5" "%~7"
                        if "!BTAB.Internal.Equal!"=="1" set "BTAB.Internal.UpdateIndexes.Same=1"
                    )
                    if "!BTAB.Internal.UpdateIndexes.Same!"=="0" (
                        if "%~4"=="1" (
                            call :RemoveRecordFromIndex "%~1" "%%~I" "%~5" "%~2"
                            if errorlevel 1 exit /b !errorlevel!
                        )
                        if "%~6"=="1" (
                            call :AddRecordToIndex "%~1" "%%~I" "%~7" "%~2"
                            if errorlevel 1 exit /b !errorlevel!
                        )
                    )
                )
            )
        )
    )
)
exit /b 0

:BuildIndex
set "BTAB.Internal.BuildIndex.Table=%~1"
set "BTAB.Internal.BuildIndex.Index=%~2"
for %%I in ("%~2") do set "BTAB.Internal.BuildIndex.Field=!BTAB.T.%~1.I.%%~I.Field!"
if "!BTAB.T.%~1.Record.Count!"=="0" exit /b 0

for /l %%N in (1,1,!BTAB.T.%~1.Record.Count!) do (
    call "!BTAB.Collection!" :GetAt "!BTAB.T.%~1.Records!" %%N BTABTempEntry
    if errorlevel 1 (
        call :SetError 50 CollectionDependencyFailed "BatchCollection could not read a record during index construction." DefineIndex "%~1" "" Dependency "Readable record list" "Read failed"
        exit /b 50
    )
    call "!BTAB.Collection!" :ReadEntry "!BTABTempEntry!" Value BTABTempRecord
    if errorlevel 1 exit /b 50
    for %%R in ("!BTABTempRecord!") do (
        for %%F in ("!BTAB.Internal.BuildIndex.Field!") do (
            if defined BTAB.R.%%~R.F.%%~F.Set (
                set "BTAB.Internal.BuildIndex.Value=!BTAB.R.%%~R.F.%%~F.Value!"
                call :CheckUniqueIndexValue "%~1" "%~2" "!BTAB.Internal.BuildIndex.Value!" "%%~R"
                if errorlevel 1 exit /b !errorlevel!
                call :AddRecordToIndex "%~1" "%~2" "!BTAB.Internal.BuildIndex.Value!" "%%~R"
                if errorlevel 1 exit /b !errorlevel!
            )
        )
    )
)
exit /b 0

:CheckUniqueIndexValue
for %%I in ("%~2") do (
    if not "!BTAB.T.%~1.I.%%~I.Unique!"=="1" exit /b 0
)
call :FindBucket "%~1" "%~2" "%~3"
if not defined BTAB.Internal.Bucket.Members exit /b 0
call "!BTAB.Collection!" :ReadCollection "!BTAB.Internal.Bucket.Members!" EntryCount BTABTempCount
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not read an index bucket." "!BTAB.Internal.Operation!" "%~1" "%~4" Dependency "Readable index bucket" "Read failed"
    exit /b 50
)
if "!BTABTempCount!"=="0" exit /b 0

for /l %%N in (1,1,!BTABTempCount!) do (
    call "!BTAB.Collection!" :GetAt "!BTAB.Internal.Bucket.Members!" %%N BTABTempEntry
    if errorlevel 1 exit /b 50
    call "!BTAB.Collection!" :ReadEntry "!BTABTempEntry!" Value BTABTempRecord
    if errorlevel 1 exit /b 50
    if /i not "!BTABTempRecord!"=="%~4" (
        call :SetError 30 UniqueIndexViolation "The indexed value already belongs to another record." "!BTAB.Internal.Operation!" "%~1" "%~4" UniqueIndex "%~2" "%~3"
        exit /b 30
    )
)
exit /b 0

:AddRecordToIndex
call :FindBucket "%~1" "%~2" "%~3"
if not defined BTAB.Internal.Bucket.Members (
    call :CreateBucket "%~1" "%~2" "%~3"
    if errorlevel 1 exit /b !errorlevel!
)
call "!BTAB.Collection!" :Add "!BTAB.Internal.Bucket.Members!" Value "%~4" "" 1 0 BTABTempEntry
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not add a record to an index bucket." "!BTAB.Internal.Operation!" "%~1" "%~4" Dependency "Indexed record membership" "Add failed"
    exit /b 50
)
exit /b 0

:RemoveRecordFromIndex
call :FindBucket "%~1" "%~2" "%~3"
if not defined BTAB.Internal.Bucket.Members exit /b 0
call "!BTAB.Collection!" :Find "!BTAB.Internal.Bucket.Members!" Value "%~4" BTABTempEntry BTABTempPosition
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not locate a record in an index bucket." "!BTAB.Internal.Operation!" "%~1" "%~4" Dependency "Indexed record membership" "Find failed"
    exit /b 50
)
if defined BTABTempEntry (
    call "!BTAB.Collection!" :RemoveEntry "!BTAB.Internal.Bucket.Members!" "!BTABTempEntry!"
    if errorlevel 1 (
        call :SetError 50 CollectionDependencyFailed "BatchCollection could not remove a record from an index bucket." "!BTAB.Internal.Operation!" "%~1" "%~4" Dependency "Removed indexed record membership" "Remove failed"
        exit /b 50
    )
)
call "!BTAB.Collection!" :ReadCollection "!BTAB.Internal.Bucket.Members!" EntryCount BTABTempCount
if errorlevel 1 exit /b 50
if "!BTABTempCount!"=="0" call :DeleteBucket "%~1" "%~2" "!BTAB.Internal.Bucket.Sequence!"
exit /b !errorlevel!

:CreateBucket
for %%I in ("%~2") do (
    call :MathAdd "!BTAB.T.%~1.I.%%~I.Bucket.Sequence!" 1 "!BTAB.Internal.Operation!" "%~1" "" BucketSequence
    if errorlevel 1 exit /b !errorlevel!
    set "BTAB.T.%~1.I.%%~I.Bucket.Sequence=!BTAB.Internal.MathResult!"
    set "BTAB.Internal.CreateBucket.Sequence=!BTAB.Internal.MathResult!"
    set "BTAB.Internal.CreateBucket.IndexSequence=!BTAB.T.%~1.I.%%~I.Sequence!"
    set "BTAB.Internal.CreateBucket.Name=BTAB_%~1_I!BTAB.Internal.CreateBucket.IndexSequence!_B!BTAB.Internal.CreateBucket.Sequence!"
)

call "!BTAB.Collection!" :Create "!BTAB.Internal.CreateBucket.Name!" BTABTempBucket
if errorlevel 1 (
    call :SetError 50 CollectionDependencyFailed "BatchCollection could not create an index bucket." "!BTAB.Internal.Operation!" "%~1" "" Dependency "Created index bucket" "Creation failed"
    exit /b 50
)
call "!BTAB.Collection!" :SetPolicy "!BTABTempBucket!" Duplicates Reject
if errorlevel 1 goto :CreateBucket.Failure
call "!BTAB.Collection!" :SetPolicy "!BTABTempBucket!" Comparison CaseInsensitive
if errorlevel 1 goto :CreateBucket.Failure

for %%I in ("%~2") do (
    set "BTAB.T.%~1.I.%%~I.Bucket.!BTAB.Internal.CreateBucket.Sequence!.Active=1"
    set "BTAB.T.%~1.I.%%~I.Bucket.!BTAB.Internal.CreateBucket.Sequence!.Key=%~3"
    set "BTAB.T.%~1.I.%%~I.Bucket.!BTAB.Internal.CreateBucket.Sequence!.Members=!BTABTempBucket!"
    call :MathAdd "!BTAB.T.%~1.I.%%~I.Bucket.Count!" 1 "!BTAB.Internal.Operation!" "%~1" "" BucketCount
    if errorlevel 1 goto :CreateBucket.Failure
    set "BTAB.T.%~1.I.%%~I.Bucket.Count=!BTAB.Internal.MathResult!"
)
set "BTAB.Internal.Bucket.Sequence=!BTAB.Internal.CreateBucket.Sequence!"
set "BTAB.Internal.Bucket.Members=!BTABTempBucket!"
exit /b 0

:CreateBucket.Failure
call "!BTAB.Collection!" :Release "!BTABTempBucket!" >nul 2>nul
call :SetError 50 CollectionDependencyFailed "BatchCollection could not configure an index bucket." "!BTAB.Internal.Operation!" "%~1" "" Dependency "Configured index bucket" "Configuration failed"
exit /b 50

:DeleteBucket
for %%I in ("%~2") do (
    for %%B in (%~3) do (
        set "BTAB.Internal.DeleteBucket.Members=!BTAB.T.%~1.I.%%~I.Bucket.%%B.Members!"
        if defined BTAB.Internal.DeleteBucket.Members (
            call "!BTAB.Collection!" :Release "!BTAB.Internal.DeleteBucket.Members!"
            if errorlevel 1 (
                call :SetError 50 CollectionDependencyFailed "BatchCollection could not release an empty index bucket." "!BTAB.Internal.Operation!" "%~1" "" Dependency "Released index bucket" "Release failed"
                exit /b 50
            )
        )
        set "BTAB.T.%~1.I.%%~I.Bucket.%%B.Active="
        set "BTAB.T.%~1.I.%%~I.Bucket.%%B.Key="
        set "BTAB.T.%~1.I.%%~I.Bucket.%%B.Members="
        set /a BTAB.T.%~1.I.%%~I.Bucket.Count-=1
    )
)
exit /b 0

:FindBucket
set "BTAB.Internal.Bucket.Sequence="
set "BTAB.Internal.Bucket.Members="
for %%I in ("%~2") do (
    set "BTAB.Internal.Bucket.Maximum=!BTAB.T.%~1.I.%%~I.Bucket.Sequence!"
)
if "!BTAB.Internal.Bucket.Maximum!"=="0" exit /b 0

for /l %%B in (1,1,!BTAB.Internal.Bucket.Maximum!) do (
    for %%I in ("%~2") do (
        if "!BTAB.T.%~1.I.%%~I.Bucket.%%B.Active!"=="1" (
            set "BTAB.Internal.Bucket.Candidate=!BTAB.T.%~1.I.%%~I.Bucket.%%B.Key!"
            call :IndexValuesEqual "%~1" "%%~I" "!BTAB.Internal.Bucket.Candidate!" "%~3"
            if "!BTAB.Internal.Equal!"=="1" if not defined BTAB.Internal.Bucket.Sequence (
                set "BTAB.Internal.Bucket.Sequence=%%B"
                set "BTAB.Internal.Bucket.Members=!BTAB.T.%~1.I.%%~I.Bucket.%%B.Members!"
            )
        )
    )
)
exit /b 0

:IndexValuesEqual
set "BTAB.Internal.Equal=0"
for %%I in ("%~2") do (
    if /i "!BTAB.T.%~1.I.%%~I.Comparison!"=="CaseInsensitive" (
        if /i "%~3"=="%~4" set "BTAB.Internal.Equal=1"
    ) else (
        if "%~3"=="%~4" set "BTAB.Internal.Equal=1"
    )
)
exit /b 0

:RollbackIndex
set "BTAB.Work.Error.Code=!BTAB.LastError.Code!"
set "BTAB.Work.Error.Kind=!BTAB.LastError.Kind!"
set "BTAB.Work.Error.Message=!BTAB.LastError.Message!"
set "BTAB.Work.Error.Operation=!BTAB.LastError.Operation!"
set "BTAB.Work.Error.Table=!BTAB.LastError.Table!"
set "BTAB.Work.Error.Record=!BTAB.LastError.Record!"
set "BTAB.Work.Error.Constraint=!BTAB.LastError.Constraint!"
set "BTAB.Work.Error.Expected=!BTAB.LastError.Expected!"
set "BTAB.Work.Error.Actual=!BTAB.LastError.Actual!"
call :ReleaseIndexBuckets "%~1" "%~2" >nul 2>nul
for %%I in ("%~2") do (
    set "BTAB.T.%~1.Index.Index.!BTAB.T.%~1.I.%%~I.Sequence!="
)
call :ClearPrefix "BTAB.T.%~1.I.%~2."
call :SetError "!BTAB.Work.Error.Code!" "!BTAB.Work.Error.Kind!" "!BTAB.Work.Error.Message!" "!BTAB.Work.Error.Operation!" "!BTAB.Work.Error.Table!" "!BTAB.Work.Error.Record!" "!BTAB.Work.Error.Constraint!" "!BTAB.Work.Error.Expected!" "!BTAB.Work.Error.Actual!"
exit /b !BTAB.LastError.Code!

:ReleaseIndexBuckets
for %%I in ("%~2") do set "BTAB.Internal.ReleaseBuckets.Maximum=!BTAB.T.%~1.I.%%~I.Bucket.Sequence!"
if "!BTAB.Internal.ReleaseBuckets.Maximum!"=="0" exit /b 0
for /l %%B in (1,1,!BTAB.Internal.ReleaseBuckets.Maximum!) do (
    for %%I in ("%~2") do (
        if "!BTAB.T.%~1.I.%%~I.Bucket.%%B.Active!"=="1" (
            set "BTAB.Internal.ReleaseBuckets.Members=!BTAB.T.%~1.I.%%~I.Bucket.%%B.Members!"
            if defined BTAB.Internal.ReleaseBuckets.Members (
                call "!BTAB.Collection!" :Release "!BTAB.Internal.ReleaseBuckets.Members!"
                if errorlevel 1 (
                    call :SetError 50 CollectionDependencyFailed "BatchCollection could not release an index bucket." "!BTAB.Internal.Operation!" "%~1" "" Dependency "Released index bucket" "Release failed"
                    exit /b 50
                )
            )
        )
    )
)
exit /b 0

:RemoveRecordCore
set "BTAB.Internal.RemoveRecord.Record=%~1"
set "BTAB.Internal.RemoveRecord.Table=!BTAB.R.%~1.Table!"

for %%T in ("!BTAB.Internal.RemoveRecord.Table!") do (
    if not "!BTAB.T.%%~T.Field.Sequence!"=="0" (
        for /l %%N in (1,1,!BTAB.T.%%~T.Field.Sequence!) do (
            set "BTAB.Internal.RemoveRecord.Field=!BTAB.T.%%~T.Field.Index.%%N!"
            if defined BTAB.Internal.RemoveRecord.Field (
                for %%F in ("!BTAB.Internal.RemoveRecord.Field!") do (
                    if defined BTAB.R.%~1.F.%%~F.Set (
                        set "BTAB.Internal.RemoveRecord.Value=!BTAB.R.%~1.F.%%~F.Value!"
                        call :UpdateIndexesForField "%%~T" "%~1" "%%~F" 1 "!BTAB.Internal.RemoveRecord.Value!" 0 ""
                        if errorlevel 1 exit /b !errorlevel!
                        if /i "!BTAB.T.%%~T.F.%%~F.Type!"=="Reference" (
                            for %%R in ("!BTAB.Internal.RemoveRecord.Value!") do (
                                if defined BTAB.R.%%~R.__Exists (
                                    set /a BTAB.R.%%~R.ReferenceCount-=1
                                )
                            )
                        )
                    )
                )
            )
        )
    )

    call "!BTAB.Collection!" :Find "!BTAB.T.%%~T.Records!" Value "%~1" BTABTempEntry BTABTempPosition
    if errorlevel 1 (
        call :SetError 50 CollectionDependencyFailed "BatchCollection could not locate a record in the ordered list." "%~2" "%%~T" "%~1" Dependency "Record membership" "Find failed"
        exit /b 50
    )
    if defined BTABTempEntry (
        call "!BTAB.Collection!" :RemoveEntry "!BTAB.T.%%~T.Records!" "!BTABTempEntry!"
        if errorlevel 1 (
            call :SetError 50 CollectionDependencyFailed "BatchCollection could not remove a record from the ordered list." "%~2" "%%~T" "%~1" Dependency "Removed record membership" "Remove failed"
            exit /b 50
        )
    )

    call :ClearPrefix "BTAB.R.%~1."
    set /a BTAB.T.%%~T.Record.Count-=1
)
set /a BTAB.Record.Count-=1
exit /b 0

:RequireTable
if defined BTAB.T.%~1.__Exists exit /b 0
call :SetError 30 TableNotFound "The table handle does not exist." "%~2" "%~1" "" Table "Live table handle" "%~1"
exit /b 30

:RequireRecord
if defined BTAB.R.%~1.__Exists exit /b 0
call :SetError 30 RecordNotFound "The record ID does not exist." "%~2" "" "%~1" Record "Live record ID" "%~1"
exit /b 30

:RequireField
call :RequireTable "%~1" "%~3"
if errorlevel 1 exit /b !errorlevel!
call :ValidateIdentifier "%~2" FieldName
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.Field.Name=!BTAB.Internal.Validated!"
for %%F in ("!BTAB.Internal.Field.Name!") do (
    if defined BTAB.T.%~1.F.%%~F.Exists exit /b 0
)
call :SetError 30 FieldNotFound "The table field does not exist." "%~3" "%~1" "" Field "Defined field" "!BTAB.Internal.Field.Name!"
exit /b 30

:RequireIndex
call :RequireTable "%~1" "%~3"
if errorlevel 1 exit /b !errorlevel!
call :ValidateIdentifier "%~2" IndexName
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.Index.Name=!BTAB.Internal.Validated!"
for %%I in ("!BTAB.Internal.Index.Name!") do (
    if defined BTAB.T.%~1.I.%%~I.Exists exit /b 0
)
call :SetError 30 IndexNotFound "The table index does not exist." "%~3" "%~1" "" Index "Defined index" "!BTAB.Internal.Index.Name!"
exit /b 30

:RequireIndexableType
for %%T in (Int UInt Bool Id DottedId Enum Reference) do (
    if /i "%~1"=="%%T" exit /b 0
)
call :SetError 20 FieldTypeNotIndexable "The field type does not support protocol 1 equality indexes." "%~2" "%~3" "" FieldType "Int, UInt, Bool, Id, DottedId, Enum, or Reference" "%~1"
exit /b 20

:ValidateValueByType
set "BTAB.Internal.Value.Type=%~1"
set "BTAB.Internal.Value.Raw=%~2"
set "BTAB.Internal.Value.Choices=%~3"
set "BTAB.Internal.Value.ReferenceTable=%~4"
set "BTAB.Internal.Value.RequireReference=%~5"

if /i "!BTAB.Internal.Value.Type!"=="Int" (
    call :ValidateInteger "!BTAB.Internal.Value.Raw!" FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="UInt" (
    call :ValidateUnsigned "!BTAB.Internal.Value.Raw!" FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="Bool" (
    call :ValidateBoolean "!BTAB.Internal.Value.Raw!" FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="Id" (
    call :ValidateIdentifier "!BTAB.Internal.Value.Raw!" FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="DottedId" (
    call :ValidateDotted "!BTAB.Internal.Value.Raw!" FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="Enum" (
    call :ValidateEnum "!BTAB.Internal.Value.Raw!" "!BTAB.Internal.Value.Choices!" FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="Text" (
    call :ValidateFixedHandle "!BTAB.Internal.Value.Raw!" TX 6 FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="Object" (
    call :ValidateVariableHandle "!BTAB.Internal.Value.Raw!" O FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="Collection" (
    call :ValidateVariableHandle "!BTAB.Internal.Value.Raw!" BC FieldValue
    exit /b !errorlevel!
)
if /i "!BTAB.Internal.Value.Type!"=="Reference" (
    call :ValidateIdentifier "!BTAB.Internal.Value.Raw!" FieldValue
    if errorlevel 1 exit /b !errorlevel!
    set "BTAB.Internal.Value.Reference=!BTAB.Internal.Validated!"
    if "!BTAB.Internal.Value.RequireReference!"=="1" (
        call :RequireRecord "!BTAB.Internal.Value.Reference!" "!BTAB.Internal.Operation!"
        if errorlevel 1 exit /b !errorlevel!
        for %%R in ("!BTAB.Internal.Value.Reference!") do (
            if /i not "!BTAB.R.%%~R.Table!"=="!BTAB.Internal.Value.ReferenceTable!" (
                call :SetError 20 ReferenceTableMismatch "The reference record belongs to a different table." "!BTAB.Internal.Operation!" "!BTAB.Internal.Value.ReferenceTable!" "%%~R" ReferenceTable "!BTAB.Internal.Value.ReferenceTable!" "!BTAB.R.%%~R.Table!"
                exit /b 20
            )
        )
    )
    set "BTAB.Internal.Validated=!BTAB.Internal.Value.Reference!"
    exit /b 0
)

call :SetError 20 UnsupportedFieldType "The field type is not supported." "!BTAB.Internal.Operation!" "" "" FieldType "Supported field type" "!BTAB.Internal.Value.Type!"
exit /b 20

:PrepareOutput
call :ValidateIdentifier "%~1" OutputVariable
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.Output=!BTAB.Internal.Validated!"
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
    if /i "!BTAB.Internal.Output!"=="%%R" (
        call :SetError 20 ReservedOutputVariable "The output variable name is reserved." "%~2" "" "" OutputVariable "Non-reserved identifier" "!BTAB.Internal.Output!"
        exit /b 20
    )
)
if /i "!BTAB.Internal.Output:~0,5!"=="BTAB." (
    call :SetError 20 ReservedOutputVariable "The output variable name uses the BatchTable namespace." "%~2" "" "" OutputVariable "Caller-owned identifier" "!BTAB.Internal.Output!"
    exit /b 20
)
if /i "!BTAB.Internal.Output:~0,8!"=="BTABTemp" (
    call :SetError 20 ReservedOutputVariable "The output variable name uses the BatchTable temporary namespace." "%~2" "" "" OutputVariable "Caller-owned identifier" "!BTAB.Internal.Output!"
    exit /b 20
)
if /i "!BTAB.Internal.Output!"=="BTABValidated" (
    call :SetError 20 ReservedOutputVariable "The output variable name is reserved by BatchTable validation." "%~2" "" "" OutputVariable "Caller-owned identifier" "!BTAB.Internal.Output!"
    exit /b 20
)
exit /b 0

:ValidateIdentifier
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Constraint=%~2"
call "!BTAB.Validator!" :Identifier "!BTAB.Internal.Validation.Value!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidIdentifier "The value must be an identifier." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "Letter followed by letters, digits, or underscores" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidateDotted
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Constraint=%~2"
call "!BTAB.Validator!" :DottedIdentifier "!BTAB.Internal.Validation.Value!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidDottedIdentifier "The value must be a dotted identifier." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "Identifier or dotted identifier" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidateInteger
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Constraint=%~2"
call "!BTAB.Validator!" :Int32 "!BTAB.Internal.Validation.Value!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidInteger "The value must be a signed 32-bit integer." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "-2147483648 through 2147483647" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidateUnsigned
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Constraint=%~2"
call "!BTAB.Validator!" :UInt32 "!BTAB.Internal.Validation.Value!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidUnsignedInteger "The value must be an unsigned 32-bit integer." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "0 through 2147483647" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidatePositive
call :ValidateUnsigned "%~1" "%~2"
if errorlevel 1 exit /b !errorlevel!
if not "!BTAB.Internal.Validated!"=="0" exit /b 0
call :SetError 20 PositiveIntegerRequired "The value must be greater than zero." "!BTAB.Internal.Operation!" "" "" "%~2" "1 through 2147483647" "0"
exit /b 20

:ValidateBoolean
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Constraint=%~2"
call "!BTAB.Validator!" :Boolean "!BTAB.Internal.Validation.Value!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidBoolean "The value must be a Boolean." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "true, false, 1, or 0" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidateEnum
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Choices=%~2"
set "BTAB.Internal.Validation.Constraint=%~3"
call "!BTAB.Validator!" :Enum "!BTAB.Internal.Validation.Value!" "!BTAB.Internal.Validation.Choices!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidEnumValue "The value is not one of the allowed choices." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "!BTAB.Internal.Validation.Choices!" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidateEnumChoices
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Constraint=%~2"
call "!BTAB.Validator!" :EnumChoices "!BTAB.Internal.Validation.Value!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidEnumChoices "The enum choice list is invalid." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "Unique comma-delimited identifiers" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidateFixedHandle
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Prefix=%~2"
set "BTAB.Internal.Validation.Width=%~3"
set "BTAB.Internal.Validation.Constraint=%~4"
call "!BTAB.Validator!" :Handle "!BTAB.Internal.Validation.Value!" "!BTAB.Internal.Validation.Prefix!" "!BTAB.Internal.Validation.Width!" BTABValidated
if errorlevel 1 (
    call :SetError 20 InvalidHandle "The value is not a valid fixed-width engine handle." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "!BTAB.Internal.Validation.Prefix! followed by !BTAB.Internal.Validation.Width! digits" "!BTAB.Internal.Validation.Value!"
    exit /b 20
)
set "BTAB.Internal.Validated=!BTABValidated!"
exit /b 0

:ValidateVariableHandle
set "BTAB.Internal.Validation.Value=%~1"
set "BTAB.Internal.Validation.Prefix=%~2"
set "BTAB.Internal.Validation.Constraint=%~3"
call :ValidateIdentifier "!BTAB.Internal.Validation.Value!" "!BTAB.Internal.Validation.Constraint!"
if errorlevel 1 exit /b !errorlevel!
set "BTAB.Internal.Validation.Identifier=!BTAB.Internal.Validated!"
set "BTAB.Internal.Validation.PrefixLength=0"
set "BTAB.Internal.Validation.Work=!BTAB.Internal.Validation.Prefix!"
:ValidateVariableHandle.PrefixLength
if not defined BTAB.Internal.Validation.Work goto :ValidateVariableHandle.Check
set /a BTAB.Internal.Validation.PrefixLength+=1
set "BTAB.Internal.Validation.Work=!BTAB.Internal.Validation.Work:~1!"
goto :ValidateVariableHandle.PrefixLength
:ValidateVariableHandle.Check
for %%N in (!BTAB.Internal.Validation.PrefixLength!) do (
    set "BTAB.Internal.Validation.ActualPrefix=!BTAB.Internal.Validation.Identifier:~0,%%N!"
    set "BTAB.Internal.Validation.Suffix=!BTAB.Internal.Validation.Identifier:~%%N!"
)
if /i not "!BTAB.Internal.Validation.ActualPrefix!"=="!BTAB.Internal.Validation.Prefix!" goto :ValidateVariableHandle.Invalid
if not defined BTAB.Internal.Validation.Suffix goto :ValidateVariableHandle.Invalid
call "!BTAB.Validator!" :UInt32 "!BTAB.Internal.Validation.Suffix!" BTABValidated
if errorlevel 1 goto :ValidateVariableHandle.Invalid
if "!BTABValidated!"=="0" goto :ValidateVariableHandle.Invalid
set "BTAB.Internal.Validation.Canonical=!BTAB.Internal.Validation.Prefix!!BTABValidated!"
if /i not "!BTAB.Internal.Validation.Canonical!"=="!BTAB.Internal.Validation.Identifier!" goto :ValidateVariableHandle.Invalid
set "BTAB.Internal.Validated=!BTAB.Internal.Validation.Canonical!"
exit /b 0
:ValidateVariableHandle.Invalid
call :SetError 20 InvalidHandle "The value is not a valid variable-width engine handle." "!BTAB.Internal.Operation!" "" "" "!BTAB.Internal.Validation.Constraint!" "!BTAB.Internal.Validation.Prefix! followed by a positive integer" "!BTAB.Internal.Validation.Value!"
exit /b 20

:MathAdd
call "!BTAB.Math!" :Add "%~1" "%~2" BTABTempMath
if errorlevel 1 (
    call :SetError 30 TableArithmeticOverflow "Checked addition failed." "%~3" "%~4" "%~5" "%~6" "Signed 32-bit result" "%~1 + %~2"
    exit /b 30
)
set "BTAB.Internal.MathResult=!BTABTempMath!"
exit /b 0

:BeginOperation
call :EnsureInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BTAB.Internal."
call :ClearLastErrorInternal
set "BTAB.Internal.Operation=%~1"
exit /b 0

:EnsureInitialized
if defined BTAB.Initialized exit /b 0
call "%~f0" :Initialize
exit /b !errorlevel!

:RequireInitialized
if defined BTAB.Initialized exit /b 0
call :SetError 50 TableNotInitialized "BatchTable is not initialized." RequireInitialized "" "" State "Initialized component" "Not initialized"
exit /b 50

:ClearLastErrorInternal
for /f "tokens=1 delims==" %%V in ('set BTAB.LastError. 2^>nul') do set "%%V="
exit /b 0

:SetError
set "BTAB.LastError.Code=%~1"
set "BTAB.LastError.Kind=%~2"
set "BTAB.LastError.Message=%~3"
set "BTAB.LastError.Operation=%~4"
set "BTAB.LastError.Table=%~5"
set "BTAB.LastError.Record=%~6"
set "BTAB.LastError.Constraint=%~7"
set "BTAB.LastError.Expected=%~8"
set "BTAB.LastError.Actual=%~9"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
