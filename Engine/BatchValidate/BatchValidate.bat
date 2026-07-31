@echo off

rem BatchValidate.bat
rem Project-agnostic validation and normalization for Windows batch files.
rem Version 1.0.0 - protocol 1
rem Requirement: caller must enable command extensions and delayed expansion.

set "BV.Internal.DelayedProbe=1"
if not "!BV.Internal.DelayedProbe!"=="1" (
    echo BatchValidate requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="validate" goto :Readable.Validate
if /i "%~1"=="apply" goto :Readable.Apply
if /i "%~1"=="define" goto :Readable.Define
if /i "%~1"=="compose" goto :Readable.Compose
if /i "%~1"=="release" goto :Readable.Release
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="clear" goto :Readable.Clear
if /i "%~1"=="get" goto :Readable.Get
if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":Identifier" goto :Identifier
if /i "%~1"==":DottedIdentifier" goto :DottedIdentifier
if /i "%~1"==":Int32" goto :Int32
if /i "%~1"==":UInt32" goto :UInt32
if /i "%~1"==":Boolean" goto :Boolean
if /i "%~1"==":Enum" goto :Enum
if /i "%~1"==":EnumChoices" goto :EnumChoices
if /i "%~1"==":Path" goto :Path
if /i "%~1"==":Handle" goto :Handle
if /i "%~1"==":SchemaType" goto :SchemaType
if /i "%~1"==":TypeId" goto :TypeId
if /i "%~1"==":Apply" goto :Apply
if /i "%~1"==":DefineRule" goto :DefineRule
if /i "%~1"==":ComposeRule" goto :ComposeRule
if /i "%~1"==":ValidateWith" goto :ValidateWith
if /i "%~1"==":ReleaseRule" goto :ReleaseRule
if /i "%~1"==":ListRules" goto :ListRules
if /i "%~1"==":GetStat" goto :GetStat
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :EnsureInitialized
call :SetError 10 UnknownValidationCommand "Unknown BatchValidate command." "" Command "Known validation command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="validation" goto :Readable.Syntax
call "%~f0" :Initialize
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="validation" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Validate
if /i "%~2"=="identifier" goto :Readable.ValidateSimple.Identifier
if /i "%~2"=="dotted" goto :Readable.ValidateSimple.Dotted
if /i "%~2"=="integer" goto :Readable.ValidateSimple.Int32
if /i "%~2"=="unsigned" goto :Readable.ValidateSimple.UInt32
if /i "%~2"=="boolean" goto :Readable.ValidateSimple.Boolean
if /i "%~2"=="schema-type" goto :Readable.ValidateSimple.SchemaType
if /i "%~2"=="type-id" goto :Readable.ValidateSimple.TypeId
if /i "%~2"=="enum" goto :Readable.ValidateEnum
if /i "%~2"=="path" goto :Readable.ValidatePath
if /i "%~2"=="handle" goto :Readable.ValidateHandle
if /i "%~2"=="value" goto :Readable.ValidateRule
goto :Readable.Syntax

:Readable.ValidateSimple.Identifier
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :Identifier "%~3" "%~5"
exit /b !errorlevel!

:Readable.ValidateSimple.Dotted
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :DottedIdentifier "%~3" "%~5"
exit /b !errorlevel!

:Readable.ValidateSimple.Int32
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :Int32 "%~3" "%~5"
exit /b !errorlevel!

:Readable.ValidateSimple.UInt32
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :UInt32 "%~3" "%~5"
exit /b !errorlevel!

:Readable.ValidateSimple.Boolean
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :Boolean "%~3" "%~5"
exit /b !errorlevel!

:Readable.ValidateSimple.SchemaType
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :SchemaType "%~3" "%~5"
exit /b !errorlevel!

:Readable.ValidateSimple.TypeId
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :TypeId "%~3" "%~5"
exit /b !errorlevel!

:Readable.ValidateEnum
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :Enum "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.ValidatePath
if /i not "%~4"=="as" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :Path "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.ValidateHandle
if /i not "%~4"=="with" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :Handle "%~3" "%~5" "%~6" "%~8"
exit /b !errorlevel!

:Readable.ValidateRule
if /i not "%~4"=="with" goto :Readable.Syntax
if /i not "%~5"=="rule" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :ValidateWith "%~6" "%~3" "%~8"
exit /b !errorlevel!

:Readable.Apply
if /i not "%~2"=="validation" goto :Readable.Syntax
if /i not "%~4"=="to" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :Apply "%~5" "%~3" "%~7"
exit /b !errorlevel!

:Readable.Define
if /i not "%~2"=="validation" goto :Readable.Syntax
if /i not "%~3"=="rule" goto :Readable.Syntax
if /i not "%~5"=="as" goto :Readable.Syntax
call "%~f0" :DefineRule "%~4" "%~6"
exit /b !errorlevel!

:Readable.Compose
if /i not "%~2"=="validation" goto :Readable.Syntax
if /i not "%~3"=="rule" goto :Readable.Syntax
if /i not "%~5"=="from" goto :Readable.Syntax
if /i not "%~7"=="and" goto :Readable.Syntax
call "%~f0" :ComposeRule "%~4" "%~6" "%~8"
exit /b !errorlevel!

:Readable.Release
if /i not "%~2"=="validation" goto :Readable.Syntax
if /i not "%~3"=="rule" goto :Readable.Syntax
call "%~f0" :ReleaseRule "%~4"
exit /b !errorlevel!

:Readable.Show
if /i "%~2"=="validation" if /i "%~3"=="rules" (
    call "%~f0" :ListRules
    exit /b !errorlevel!
)
if /i "%~2"=="last" if /i "%~3"=="error" (
    call "%~f0" :PrintLastError
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Read
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :ReadLastError "%~4" "%~6"
exit /b !errorlevel!

:Readable.Clear
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
call "%~f0" :ClearLastError
exit /b !errorlevel!

:Readable.Get
if /i not "%~2"=="statistic" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :GetStat "%~3" "%~5"
exit /b !errorlevel!

:Readable.Syntax
call :EnsureInitialized
call :SetError 10 InvalidValidationSyntax "BatchValidate command syntax is invalid." "" Syntax "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BV.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)
call :ClearPrefix "BV."
set "BV.Initialized=1"
set "BV.Version=1.0.0"
set "BV.Protocol=1"
set "BV.Rule.Count=0"
set "BV.Rule.Sequence=0"
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :EnsureInitialized
call :ClearPrefix "BV."
exit /b 0

:Identifier
call :BeginValidation Identifier "%~3"
if errorlevel 1 exit /b !errorlevel!
call :IdentifierCore "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:DottedIdentifier
call :BeginValidation DottedIdentifier "%~3"
if errorlevel 1 exit /b !errorlevel!
call :DottedIdentifierCore "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:Int32
call :BeginValidation Int32 "%~3"
if errorlevel 1 exit /b !errorlevel!
call :Int32Core "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:UInt32
call :BeginValidation UInt32 "%~3"
if errorlevel 1 exit /b !errorlevel!
call :UInt32Core "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:Boolean
call :BeginValidation Boolean "%~3"
if errorlevel 1 exit /b !errorlevel!
call :BooleanCore "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:Enum
call :BeginValidation Enum "%~4"
if errorlevel 1 exit /b !errorlevel!
call :EnumCore "%~2" "%~3"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~4" "!BV.Internal.Normalized!"
exit /b 0

:EnumChoices
call :BeginValidation EnumChoices "%~3"
if errorlevel 1 exit /b !errorlevel!
call :EnumChoicesCore "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:Path
call :BeginValidation Path "%~4"
if errorlevel 1 exit /b !errorlevel!
call :PathCore "%~2" "%~3"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~4" "!BV.Internal.Normalized!"
exit /b 0

:Handle
call :BeginValidation Handle "%~5"
if errorlevel 1 exit /b !errorlevel!
call :HandleCore "%~2" "%~3" "%~4"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~5" "!BV.Internal.Normalized!"
exit /b 0

:SchemaType
call :BeginValidation SchemaType "%~3"
if errorlevel 1 exit /b !errorlevel!
call :SchemaTypeCore "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:TypeId
call :BeginValidation TypeId "%~3"
if errorlevel 1 exit /b !errorlevel!
call :TypeIdCore "%~2"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~3" "!BV.Internal.Normalized!"
exit /b 0

:Apply
call :BeginValidation Apply "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BV.Internal.Operation=Apply"
call :ApplySpecCore "%~2" "%~3"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~4" "!BV.Internal.Normalized!"
exit /b 0

:DefineRule
call :EnsureInitialized
call :ClearPrefix "BV.Internal."
call :ClearLastErrorInternal
call :IdentifierCore "%~2"
if errorlevel 1 (
    call :SetError 20 InvalidRuleName "Validation rule names must be identifiers." "%~2" Name "Identifier" "%~2"
    exit /b 20
)
set "BV.Internal.Rule.Name=!BV.Internal.Normalized!"
if defined BV.Rule.!BV.Internal.Rule.Name!.Spec (
    call :SetError 30 ValidationRuleAlreadyExists "A validation rule with this name already exists." "!BV.Internal.Rule.Name!" Name "Unused validation rule name" "Existing rule"
    exit /b 30
)
call :RuleSpecCore "%~3"
if errorlevel 1 (
    call :SetError 20 "!BV.Internal.Failure.Kind!" "!BV.Internal.Failure.Message!" "!BV.Internal.Rule.Name!" "!BV.Internal.Failure.Constraint!" "!BV.Internal.Failure.Expected!" "!BV.Internal.Failure.Actual!"
    exit /b 20
)
set /a BV.Rule.Sequence+=1
set /a BV.Rule.Count+=1
set "BV.Rule.Index.!BV.Rule.Sequence!.Name=!BV.Internal.Rule.Name!"
set "BV.Rule.Index.!BV.Rule.Sequence!.Active=1"
set "BV.Rule.!BV.Internal.Rule.Name!.Index=!BV.Rule.Sequence!"
set "BV.Rule.!BV.Internal.Rule.Name!.Spec=%~3"
exit /b 0

:ComposeRule
call :EnsureInitialized
call :ClearPrefix "BV.Internal."
call :ClearLastErrorInternal
call :IdentifierCore "%~2"
if errorlevel 1 (
    call :SetError 20 InvalidRuleName "Validation rule names must be identifiers." "%~2" Name "Identifier" "%~2"
    exit /b 20
)
set "BV.Internal.Compose.Name=!BV.Internal.Normalized!"
call :RequireRule "%~3"
if errorlevel 1 exit /b !errorlevel!
set "BV.Internal.Compose.Left=!BV.Internal.Rule.Spec!"
call :RequireRule "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BV.Internal.Compose.Right=!BV.Internal.Rule.Spec!"
call "%~f0" :DefineRule "!BV.Internal.Compose.Name!" "!BV.Internal.Compose.Left!+!BV.Internal.Compose.Right!"
exit /b !errorlevel!

:ValidateWith
call :EnsureInitialized
call :ClearPrefix "BV.Internal."
call :ClearLastErrorInternal
call :PrepareOutput "%~4" ValidateWith
if errorlevel 1 exit /b !errorlevel!
call :RequireRule "%~2"
if errorlevel 1 exit /b !errorlevel!
set "BV.Internal.Operation=%~2"
call :ApplySpecCore "%~3" "!BV.Internal.Rule.Spec!"
if errorlevel 1 goto :ValidationFailure
call :ExportResult "%~4" "!BV.Internal.Normalized!"
exit /b 0

:ReleaseRule
call :EnsureInitialized
call :ClearPrefix "BV.Internal."
call :ClearLastErrorInternal
call :RequireRule "%~2"
if errorlevel 1 exit /b !errorlevel!
set "BV.Internal.Release.Name=!BV.Internal.Rule.Name!"
for %%R in ("!BV.Internal.Release.Name!") do set "BV.Internal.Release.Index=!BV.Rule.%%~R.Index!"
call :ClearPrefix "BV.Rule.!BV.Internal.Release.Name!."
set "BV.Rule.Index.!BV.Internal.Release.Index!.Active=0"
set "BV.Rule.Index.!BV.Internal.Release.Index!.Name="
set /a BV.Rule.Count-=1
exit /b 0

:ListRules
call :EnsureInitialized
call :ClearLastErrorInternal
if "!BV.Rule.Count!"=="0" (
    echo No BatchValidate rules.
    exit /b 0
)
set "BV.Internal.List.Index=1"
:ListRules.Next
if !BV.Internal.List.Index! GTR !BV.Rule.Sequence! exit /b 0
for %%I in (!BV.Internal.List.Index!) do (
    set "BV.Internal.List.Active=!BV.Rule.Index.%%I.Active!"
    set "BV.Internal.List.Name=!BV.Rule.Index.%%I.Name!"
)
if "!BV.Internal.List.Active!"=="1" (
    for %%R in ("!BV.Internal.List.Name!") do set "BV.Internal.List.Spec=!BV.Rule.%%~R.Spec!"
    echo !BV.Internal.List.Name! = !BV.Internal.List.Spec!
)
set /a BV.Internal.List.Index+=1
goto :ListRules.Next

:GetStat
call :EnsureInitialized
call :ClearLastErrorInternal
call :PrepareOutput "%~3" GetStat
if errorlevel 1 exit /b !errorlevel!
if /i "%~2"=="RuleCount" (
    call :ExportResult "%~3" "!BV.Rule.Count!"
    exit /b 0
)
call :SetError 20 UnknownValidationStatistic "Unknown BatchValidate statistic." GetStat Statistic "RuleCount" "%~2"
exit /b 20

:ReadLastError
call :EnsureInitialized
set "BV.Internal.ReadError.Field=%~2"
set "BV.Internal.ReadError.Output=%~3"
call :ValidateErrorField "!BV.Internal.ReadError.Field!"
if errorlevel 1 (
    call :SetError 20 UnknownErrorField "Unknown BatchValidate error field." ReadLastError Field "Code, Kind, Message, Operation, Constraint, Expected, or Actual" "!BV.Internal.ReadError.Field!"
    exit /b 20
)
call :PrepareOutput "!BV.Internal.ReadError.Output!" ReadLastError
if errorlevel 1 exit /b !errorlevel!
for %%F in ("!BV.Internal.ReadError.Field!") do set "BV.Internal.ReadError.Value=!BV.LastError.%%~F!"
call :ExportResult "!BV.Internal.ReadError.Output!" "!BV.Internal.ReadError.Value!"
exit /b 0

:PrintLastError
call :EnsureInitialized
echo Code: !BV.LastError.Code!
echo Kind: !BV.LastError.Kind!
echo Message: !BV.LastError.Message!
echo Operation: !BV.LastError.Operation!
echo Constraint: !BV.LastError.Constraint!
echo Expected: !BV.LastError.Expected!
echo Actual: !BV.LastError.Actual!
exit /b 0

:ClearLastError
call :EnsureInitialized
call :ClearLastErrorInternal
exit /b 0

:ValidationFailure
call :SetError 20 "!BV.Internal.Failure.Kind!" "!BV.Internal.Failure.Message!" "!BV.Internal.Operation!" "!BV.Internal.Failure.Constraint!" "!BV.Internal.Failure.Expected!" "!BV.Internal.Failure.Actual!"
exit /b 20

:BeginValidation
call :EnsureInitialized
call :ClearPrefix "BV.Internal."
call :ClearLastErrorInternal
set "BV.Internal.Operation=%~1"
call :PrepareOutput "%~2" "%~1"
exit /b !errorlevel!

:PrepareOutput
call :IdentifierCore "%~1"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "%~2" Output "Non-reserved identifier" "%~1"
    exit /b 10
)
set "BV.Internal.Output.Name=!BV.Internal.Normalized!"
if /i "!BV.Internal.Output.Name:~0,3!"=="BV." (
    call :SetError 10 InvalidOutputVariable "Output variables cannot use the BatchValidate namespace." "%~2" Output "Non-reserved identifier" "%~1"
    exit /b 10
)
for %%V in (PATH ERRORLEVEL RANDOM TEMP TMP COMSPEC CD CMDEXTVERSION CMDCMDLINE DATE TIME PATHEXT) do if /i "!BV.Internal.Output.Name!"=="%%V" (
    call :SetError 10 InvalidOutputVariable "Output variable name is reserved by cmd.exe." "%~2" Output "Non-reserved identifier" "%~1"
    exit /b 10
)
exit /b 0

:RequireRule
call :IdentifierCore "%~1"
if errorlevel 1 (
    call :SetError 20 InvalidRuleName "Validation rule names must be identifiers." "%~1" Name "Identifier" "%~1"
    exit /b 20
)
set "BV.Internal.Rule.Name=!BV.Internal.Normalized!"
for %%R in ("!BV.Internal.Rule.Name!") do set "BV.Internal.Rule.Spec=!BV.Rule.%%~R.Spec!"
if defined BV.Internal.Rule.Spec exit /b 0
call :SetError 30 ValidationRuleNotFound "The requested validation rule does not exist." "!BV.Internal.Rule.Name!" Name "Existing validation rule" "Missing rule"
exit /b 30

:IdentifierCore
call :ClearFailure
set "BV.Internal.Id.Value=%~1"
if not defined BV.Internal.Id.Value (
    call :SetFailure EmptyValue "Identifier cannot be empty." Identifier "Letter followed by letters, digits, or underscores" "%~1"
    exit /b 1
)
if not "!BV.Internal.Id.Value:~64,1!"=="" (
    call :SetFailure ValueTooLong "Identifier exceeds 64 characters." Identifier "At most 64 characters" "%~1"
    exit /b 1
)
set "BV.Internal.Id.Character=!BV.Internal.Id.Value:~0,1!"
call :AlphaCharacterCore "!BV.Internal.Id.Character!"
if errorlevel 1 (
    call :SetFailure InvalidIdentifier "Identifier must begin with a letter." Identifier "Leading ASCII letter" "%~1"
    exit /b 1
)
set "BV.Internal.Id.Work=!BV.Internal.Id.Value:~1!"
:IdentifierCore.Next
if not defined BV.Internal.Id.Work (
    set "BV.Internal.Normalized=!BV.Internal.Id.Value!"
    exit /b 0
)
set "BV.Internal.Id.Character=!BV.Internal.Id.Work:~0,1!"
call :AlphaCharacterCore "!BV.Internal.Id.Character!"
if not errorlevel 1 goto :IdentifierCore.Advance
call :DigitCharacterCore "!BV.Internal.Id.Character!"
if not errorlevel 1 goto :IdentifierCore.Advance
if "!BV.Internal.Id.Character!"=="_" goto :IdentifierCore.Advance
call :SetFailure InvalidIdentifier "Identifier contains an invalid character." Identifier "Letters, digits, or underscore" "%~1"
exit /b 1
:IdentifierCore.Advance
set "BV.Internal.Id.Work=!BV.Internal.Id.Work:~1!"
goto :IdentifierCore.Next

:DottedIdentifierCore
call :ClearFailure
set "BV.Internal.Dotted.Value=%~1"
if not defined BV.Internal.Dotted.Value (
    call :SetFailure EmptyValue "Dotted identifier cannot be empty." DottedIdentifier "Identifier segments separated by dots" "%~1"
    exit /b 1
)
if not "!BV.Internal.Dotted.Value:~128,1!"=="" (
    call :SetFailure ValueTooLong "Dotted identifier exceeds 128 characters." DottedIdentifier "At most 128 characters" "%~1"
    exit /b 1
)
if "!BV.Internal.Dotted.Value:~0,1!"=="." goto :DottedIdentifierCore.Invalid
if "!BV.Internal.Dotted.Value:~-1!"=="." goto :DottedIdentifierCore.Invalid
if not "!BV.Internal.Dotted.Value:..=!"=="!BV.Internal.Dotted.Value!" goto :DottedIdentifierCore.Invalid
set "BV.Internal.Dotted.Work=!BV.Internal.Dotted.Value!"
:DottedIdentifierCore.Next
set "BV.Internal.Dotted.Segment="
set "BV.Internal.Dotted.Rest="
for /f "tokens=1,* delims=." %%A in ("!BV.Internal.Dotted.Work!") do (
    set "BV.Internal.Dotted.Segment=%%~A"
    set "BV.Internal.Dotted.Rest=%%~B"
)
call :IdentifierCore "!BV.Internal.Dotted.Segment!"
if errorlevel 1 (
    set "BV.Internal.Failure.Constraint=DottedIdentifier"
    exit /b 1
)
if not defined BV.Internal.Dotted.Rest (
    set "BV.Internal.Normalized=!BV.Internal.Dotted.Value!"
    exit /b 0
)
set "BV.Internal.Dotted.Work=!BV.Internal.Dotted.Rest!"
goto :DottedIdentifierCore.Next
:DottedIdentifierCore.Invalid
call :SetFailure InvalidDottedIdentifier "Dotted identifier syntax is invalid." DottedIdentifier "Identifier segments separated by single dots" "%~1"
exit /b 1

:Int32Core
call :ClearFailure
set "BV.Internal.Int.Input=%~1"
set "BV.Internal.Int.Negative=0"
if not defined BV.Internal.Int.Input (
    call :SetFailure EmptyValue "Signed integer cannot be empty." Int32 "-2147483648 through 2147483647" "%~1"
    exit /b 1
)
if "!BV.Internal.Int.Input:~0,1!"=="-" (
    set "BV.Internal.Int.Negative=1"
    set "BV.Internal.Int.Digits=!BV.Internal.Int.Input:~1!"
) else (
    set "BV.Internal.Int.Digits=!BV.Internal.Int.Input!"
)
if not defined BV.Internal.Int.Digits goto :Int32Core.Invalid
call :DigitsCore "!BV.Internal.Int.Digits!"
if errorlevel 1 goto :Int32Core.Invalid
call :StripLeadingZeroesCore "!BV.Internal.Int.Digits!"
set "BV.Internal.Int.Digits=!BV.Internal.StrippedDigits!"
if "!BV.Internal.Int.Negative!"=="1" (
    set "BV.Internal.Int.Limit=2147483648"
) else (
    set "BV.Internal.Int.Limit=2147483647"
)
call :DecimalWithinLimitCore "!BV.Internal.Int.Digits!" "!BV.Internal.Int.Limit!"
if errorlevel 1 (
    call :SetFailure IntegerOutOfRange "Signed integer is outside the supported range." Int32 "-2147483648 through 2147483647" "%~1"
    exit /b 1
)
if "!BV.Internal.Int.Digits!"=="0" (
    set "BV.Internal.Normalized=0"
) else (
    if "!BV.Internal.Int.Negative!"=="1" (
        set "BV.Internal.Normalized=-!BV.Internal.Int.Digits!"
    ) else (
        set "BV.Internal.Normalized=!BV.Internal.Int.Digits!"
    )
)
exit /b 0
:Int32Core.Invalid
call :SetFailure InvalidInteger "Value is not a signed decimal integer." Int32 "Optional minus sign followed by digits" "%~1"
exit /b 1

:UInt32Core
call :ClearFailure
set "BV.Internal.UInt.Input=%~1"
if not defined BV.Internal.UInt.Input (
    call :SetFailure EmptyValue "Unsigned integer cannot be empty." UInt32 "0 through 2147483647" "%~1"
    exit /b 1
)
call :DigitsCore "!BV.Internal.UInt.Input!"
if errorlevel 1 (
    call :SetFailure InvalidUnsignedInteger "Value is not an unsigned decimal integer." UInt32 "Digits only" "%~1"
    exit /b 1
)
call :StripLeadingZeroesCore "!BV.Internal.UInt.Input!"
set "BV.Internal.UInt.Digits=!BV.Internal.StrippedDigits!"
call :DecimalWithinLimitCore "!BV.Internal.UInt.Digits!" "2147483647"
if errorlevel 1 (
    call :SetFailure IntegerOutOfRange "Unsigned integer is outside the supported range." UInt32 "0 through 2147483647" "%~1"
    exit /b 1
)
set "BV.Internal.Normalized=!BV.Internal.UInt.Digits!"
exit /b 0

:BooleanCore
call :ClearFailure
set "BV.Internal.Bool.Input=%~1"
if /i "!BV.Internal.Bool.Input!"=="1" (
    set "BV.Internal.Normalized=1"
    exit /b 0
)
if /i "!BV.Internal.Bool.Input!"=="true" (
    set "BV.Internal.Normalized=1"
    exit /b 0
)
if /i "!BV.Internal.Bool.Input!"=="yes" (
    set "BV.Internal.Normalized=1"
    exit /b 0
)
if /i "!BV.Internal.Bool.Input!"=="on" (
    set "BV.Internal.Normalized=1"
    exit /b 0
)
if /i "!BV.Internal.Bool.Input!"=="0" (
    set "BV.Internal.Normalized=0"
    exit /b 0
)
if /i "!BV.Internal.Bool.Input!"=="false" (
    set "BV.Internal.Normalized=0"
    exit /b 0
)
if /i "!BV.Internal.Bool.Input!"=="no" (
    set "BV.Internal.Normalized=0"
    exit /b 0
)
if /i "!BV.Internal.Bool.Input!"=="off" (
    set "BV.Internal.Normalized=0"
    exit /b 0
)
call :SetFailure InvalidBoolean "Value is not a recognized Boolean." Boolean "1, true, yes, on, 0, false, no, or off" "%~1"
exit /b 1

:EnumChoicesCore
call :ClearFailure
set "BV.Internal.Enum.Choices=%~1"
if not defined BV.Internal.Enum.Choices goto :EnumChoicesCore.Invalid
if "!BV.Internal.Enum.Choices:~0,1!"=="," goto :EnumChoicesCore.Invalid
if "!BV.Internal.Enum.Choices:~-1!"=="," goto :EnumChoicesCore.Invalid
if not "!BV.Internal.Enum.Choices:,,=!"=="!BV.Internal.Enum.Choices!" goto :EnumChoicesCore.Invalid
set "BV.Internal.Enum.Remaining=!BV.Internal.Enum.Choices!"
set "BV.Internal.Enum.Count=0"
:EnumChoicesCore.Next
set "BV.Internal.Enum.Choice="
set "BV.Internal.Enum.Rest="
for /f "tokens=1,* delims=," %%A in ("!BV.Internal.Enum.Remaining!") do (
    set "BV.Internal.Enum.Choice=%%~A"
    set "BV.Internal.Enum.Rest=%%~B"
)
call :IdentifierCore "!BV.Internal.Enum.Choice!"
if errorlevel 1 goto :EnumChoicesCore.Invalid
set /a BV.Internal.Enum.Count+=1
if !BV.Internal.Enum.Count! GTR 64 (
    call :ClearPrefix "BV.Internal.Enum.Stored."
    call :SetFailure TooManyEnumChoices "Enum choice list exceeds 64 entries." EnumChoices "One through 64 unique identifiers" "%~1"
    exit /b 1
)
set "BV.Internal.Enum.Duplicate="
for /l %%I in (1,1,!BV.Internal.Enum.Count!) do if %%I LSS !BV.Internal.Enum.Count! (
    if /i "!BV.Internal.Enum.Stored.%%I!"=="!BV.Internal.Enum.Choice!" set "BV.Internal.Enum.Duplicate=1"
)
if defined BV.Internal.Enum.Duplicate (
    call :ClearPrefix "BV.Internal.Enum.Stored."
    call :SetFailure DuplicateEnumChoice "Enum choice list contains a duplicate." EnumChoices "Unique identifiers" "!BV.Internal.Enum.Choice!"
    exit /b 1
)
set "BV.Internal.Enum.Stored.!BV.Internal.Enum.Count!=!BV.Internal.Enum.Choice!"
if not defined BV.Internal.Enum.Rest (
    call :ClearPrefix "BV.Internal.Enum.Stored."
    set "BV.Internal.Normalized=!BV.Internal.Enum.Choices!"
    exit /b 0
)
set "BV.Internal.Enum.Remaining=!BV.Internal.Enum.Rest!"
goto :EnumChoicesCore.Next
:EnumChoicesCore.Invalid
call :ClearPrefix "BV.Internal.Enum.Stored."
call :SetFailure InvalidEnumChoices "Enum choices must be a comma-separated list of unique identifiers." EnumChoices "One through 64 unique identifiers" "%~1"
exit /b 1

:EnumCore
call :ClearFailure
set "BV.Internal.Enum.Input=%~1"
set "BV.Internal.Enum.Choices=%~2"
call :EnumChoicesCore "!BV.Internal.Enum.Choices!"
if errorlevel 1 exit /b 1
set "BV.Internal.Enum.Remaining=!BV.Internal.Enum.Choices!"
:EnumCore.Next
set "BV.Internal.Enum.Choice="
set "BV.Internal.Enum.Rest="
for /f "tokens=1,* delims=," %%A in ("!BV.Internal.Enum.Remaining!") do (
    set "BV.Internal.Enum.Choice=%%~A"
    set "BV.Internal.Enum.Rest=%%~B"
)
if /i "!BV.Internal.Enum.Input!"=="!BV.Internal.Enum.Choice!" (
    set "BV.Internal.Normalized=!BV.Internal.Enum.Choice!"
    exit /b 0
)
if not defined BV.Internal.Enum.Rest (
    call :SetFailure EnumValueNotAllowed "Value is not one of the allowed enum choices." Enum "!BV.Internal.Enum.Choices!" "%~1"
    exit /b 1
)
set "BV.Internal.Enum.Remaining=!BV.Internal.Enum.Rest!"
goto :EnumCore.Next

:SchemaTypeCore
call :ClearFailure
if /i "%~1"=="Int" (
    set "BV.Internal.Normalized=Int"
    exit /b 0
)
if /i "%~1"=="UInt" (
    set "BV.Internal.Normalized=UInt"
    exit /b 0
)
if /i "%~1"=="Bool" (
    set "BV.Internal.Normalized=Bool"
    exit /b 0
)
if /i "%~1"=="Id" (
    set "BV.Internal.Normalized=Id"
    exit /b 0
)
if /i "%~1"=="Enum" (
    set "BV.Internal.Normalized=Enum"
    exit /b 0
)
if /i "%~1"=="Object" (
    set "BV.Internal.Normalized=Object"
    exit /b 0
)
call :SetFailure InvalidSchemaType "Schema type is not supported." SchemaType "Int, UInt, Bool, Id, Enum, or Object" "%~1"
exit /b 1

:TypeIdCore
call :DottedIdentifierCore "%~1"
if errorlevel 1 (
    set "BV.Internal.Failure.Kind=InvalidTypeId"
    set "BV.Internal.Failure.Message=Type identifiers must contain valid dotted identifier segments."
    set "BV.Internal.Failure.Constraint=TypeId"
    exit /b 1
)
exit /b 0

:PathCore
call :ClearFailure
set "BV.Internal.Path.Input=%~1"
set "BV.Internal.Path.Mode=%~2"
set "BV.Internal.Path.CanonicalMode="
if /i "!BV.Internal.Path.Mode!"=="Any" set "BV.Internal.Path.CanonicalMode=Any"
if /i "!BV.Internal.Path.Mode!"=="File" set "BV.Internal.Path.CanonicalMode=File"
if /i "!BV.Internal.Path.Mode!"=="Directory" set "BV.Internal.Path.CanonicalMode=Directory"
if /i "!BV.Internal.Path.Mode!"=="ExistingFile" set "BV.Internal.Path.CanonicalMode=ExistingFile"
if /i "!BV.Internal.Path.Mode!"=="ExistingDirectory" set "BV.Internal.Path.CanonicalMode=ExistingDirectory"
if not defined BV.Internal.Path.CanonicalMode (
    call :SetFailure InvalidPathMode "Path validation mode is not supported." PathMode "Any, File, Directory, ExistingFile, or ExistingDirectory" "%~2"
    exit /b 1
)
if not defined BV.Internal.Path.Input (
    call :SetFailure EmptyValue "Path cannot be empty." Path "Non-empty Windows path" "%~1"
    exit /b 1
)
if not "!BV.Internal.Path.Input:~2048,1!"=="" (
    call :SetFailure ValueTooLong "Path exceeds 2048 characters." Path "At most 2048 characters" "%~1"
    exit /b 1
)
if not "!BV.Internal.Path.Input:**=!"=="!BV.Internal.Path.Input!" goto :PathCore.InvalidCharacter
if not "!BV.Internal.Path.Input:?=!"=="!BV.Internal.Path.Input!" goto :PathCore.InvalidCharacter
if not "!BV.Internal.Path.Input:<=!"=="!BV.Internal.Path.Input!" goto :PathCore.InvalidCharacter
if not "!BV.Internal.Path.Input:>=!"=="!BV.Internal.Path.Input!" goto :PathCore.InvalidCharacter
if not "!BV.Internal.Path.Input:|=!"=="!BV.Internal.Path.Input!" goto :PathCore.InvalidCharacter
set "BV.Internal.Path.ColonWork=!BV.Internal.Path.Input!"
set "BV.Internal.Path.First=!BV.Internal.Path.Input:~0,1!"
set "BV.Internal.Path.Second=!BV.Internal.Path.Input:~1,1!"
call :AlphaCharacterCore "!BV.Internal.Path.First!"
if not errorlevel 1 if "!BV.Internal.Path.Second!"==":" set "BV.Internal.Path.ColonWork=!BV.Internal.Path.Input:~2!"
if not "!BV.Internal.Path.ColonWork::=!"=="!BV.Internal.Path.ColonWork!" (
    call :SetFailure InvalidPath "Path contains an invalid colon." Path "Optional drive-letter colon only" "%~1"
    exit /b 1
)
if /i "!BV.Internal.Path.CanonicalMode!"=="File" goto :PathCore.FileShape
if /i "!BV.Internal.Path.CanonicalMode!"=="ExistingFile" goto :PathCore.FileShape
goto :PathCore.Normalize
:PathCore.FileShape
if "!BV.Internal.Path.Input:~-1!"=="\" (
    call :SetFailure InvalidPath "File path cannot end with a directory separator." Path "File path" "%~1"
    exit /b 1
)
if "!BV.Internal.Path.Input:~-1!"=="/" (
    call :SetFailure InvalidPath "File path cannot end with a directory separator." Path "File path" "%~1"
    exit /b 1
)
:PathCore.Normalize
for %%P in ("!BV.Internal.Path.Input!") do set "BV.Internal.Path.Full=%%~fP"
if not defined BV.Internal.Path.Full (
    call :SetFailure InvalidPath "Windows could not normalize the path." Path "Valid Windows path" "%~1"
    exit /b 1
)
set "BV.Internal.Path.Exists=0"
set "BV.Internal.Path.IsDirectory=0"
if exist "!BV.Internal.Path.Full!" (
    set "BV.Internal.Path.Exists=1"
    for %%P in ("!BV.Internal.Path.Full!") do set "BV.Internal.Path.Attributes=%%~aP"
    if /i "!BV.Internal.Path.Attributes:~0,1!"=="d" set "BV.Internal.Path.IsDirectory=1"
)
if /i "!BV.Internal.Path.CanonicalMode!"=="ExistingFile" (
    if "!BV.Internal.Path.Exists!"=="0" goto :PathCore.Missing
    if "!BV.Internal.Path.IsDirectory!"=="1" goto :PathCore.ExpectedFile
)
if /i "!BV.Internal.Path.CanonicalMode!"=="ExistingDirectory" (
    if "!BV.Internal.Path.Exists!"=="0" goto :PathCore.Missing
    if "!BV.Internal.Path.IsDirectory!"=="0" goto :PathCore.ExpectedDirectory
)
if /i "!BV.Internal.Path.CanonicalMode!"=="File" if "!BV.Internal.Path.Exists!"=="1" if "!BV.Internal.Path.IsDirectory!"=="1" goto :PathCore.ExpectedFile
if /i "!BV.Internal.Path.CanonicalMode!"=="Directory" if "!BV.Internal.Path.Exists!"=="1" if "!BV.Internal.Path.IsDirectory!"=="0" goto :PathCore.ExpectedDirectory
set "BV.Internal.Normalized=!BV.Internal.Path.Full!"
exit /b 0
:PathCore.InvalidCharacter
call :SetFailure InvalidPath "Path contains an invalid Windows path character." Path "Path without wildcard or redirection characters" "%~1"
exit /b 1
:PathCore.Missing
call :SetFailure PathNotFound "Required path does not exist." Path "!BV.Internal.Path.CanonicalMode!" "!BV.Internal.Path.Full!"
exit /b 1
:PathCore.ExpectedFile
call :SetFailure PathTypeMismatch "Path resolves to a directory instead of a file." Path File "!BV.Internal.Path.Full!"
exit /b 1
:PathCore.ExpectedDirectory
call :SetFailure PathTypeMismatch "Path resolves to a file instead of a directory." Path Directory "!BV.Internal.Path.Full!"
exit /b 1

:HandleCore
call :ClearFailure
set "BV.Internal.Handle.Value=%~1"
set "BV.Internal.Handle.Prefix=%~2"
set "BV.Internal.Handle.WidthInput=%~3"
call :IdentifierCore "!BV.Internal.Handle.Prefix!"
if errorlevel 1 (
    call :SetFailure InvalidHandlePrefix "Handle prefix must be an identifier." Handle "Identifier prefix" "%~2"
    exit /b 1
)
set "BV.Internal.Handle.Prefix=!BV.Internal.Normalized!"
if not "!BV.Internal.Handle.Prefix:~8,1!"=="" (
    call :SetFailure InvalidHandlePrefix "Handle prefix exceeds eight characters." Handle "Prefix of one through eight characters" "%~2"
    exit /b 1
)
call :UInt32Core "!BV.Internal.Handle.WidthInput!"
if errorlevel 1 (
    call :SetFailure InvalidHandleWidth "Handle width must be an unsigned integer." Handle "Width from 1 through 16" "%~3"
    exit /b 1
)
set "BV.Internal.Handle.Width=!BV.Internal.Normalized!"
if !BV.Internal.Handle.Width! LSS 1 goto :HandleCore.BadWidth
if !BV.Internal.Handle.Width! GTR 16 goto :HandleCore.BadWidth
set "BV.Internal.Handle.PrefixLength=0"
set "BV.Internal.Handle.Work=!BV.Internal.Handle.Prefix!"
:HandleCore.PrefixLength
if not defined BV.Internal.Handle.Work goto :HandleCore.Check
set /a BV.Internal.Handle.PrefixLength+=1
set "BV.Internal.Handle.Work=!BV.Internal.Handle.Work:~1!"
goto :HandleCore.PrefixLength
:HandleCore.Check
for %%N in (!BV.Internal.Handle.PrefixLength!) do (
    set "BV.Internal.Handle.ActualPrefix=!BV.Internal.Handle.Value:~0,%%N!"
    set "BV.Internal.Handle.Digits=!BV.Internal.Handle.Value:~%%N!"
)
if /i not "!BV.Internal.Handle.ActualPrefix!"=="!BV.Internal.Handle.Prefix!" (
    call :SetFailure InvalidHandle "Handle prefix does not match." Handle "!BV.Internal.Handle.Prefix! followed by !BV.Internal.Handle.Width! digits" "%~1"
    exit /b 1
)
set "BV.Internal.Handle.DigitLength=0"
set "BV.Internal.Handle.Work=!BV.Internal.Handle.Digits!"
:HandleCore.DigitLength
if not defined BV.Internal.Handle.Work goto :HandleCore.DigitLengthDone
set /a BV.Internal.Handle.DigitLength+=1
set "BV.Internal.Handle.Work=!BV.Internal.Handle.Work:~1!"
goto :HandleCore.DigitLength
:HandleCore.DigitLengthDone
if not "!BV.Internal.Handle.DigitLength!"=="!BV.Internal.Handle.Width!" (
    call :SetFailure InvalidHandle "Handle has the wrong number of digits." Handle "!BV.Internal.Handle.Prefix! followed by !BV.Internal.Handle.Width! digits" "%~1"
    exit /b 1
)
call :DigitsCore "!BV.Internal.Handle.Digits!"
if errorlevel 1 (
    call :SetFailure InvalidHandle "Handle suffix must contain digits only." Handle "!BV.Internal.Handle.Prefix! followed by !BV.Internal.Handle.Width! digits" "%~1"
    exit /b 1
)
set "BV.Internal.Normalized=!BV.Internal.Handle.Prefix!!BV.Internal.Handle.Digits!"
exit /b 0
:HandleCore.BadWidth
call :SetFailure InvalidHandleWidth "Handle width is outside the supported range." Handle "Width from 1 through 16" "%~3"
exit /b 1

:RuleSpecCore
call :ClearFailure
set "BV.Internal.Spec.Value=%~1"
if not defined BV.Internal.Spec.Value (
    call :SetFailure EmptyRuleSpec "Validation rule specification cannot be empty." RuleSpec "One or more constraints separated by plus signs" "%~1"
    exit /b 1
)
if "!BV.Internal.Spec.Value:~0,1!"=="+" goto :RuleSpecCore.Invalid
if "!BV.Internal.Spec.Value:~-1!"=="+" goto :RuleSpecCore.Invalid
if not "!BV.Internal.Spec.Value:++=!"=="!BV.Internal.Spec.Value!" goto :RuleSpecCore.Invalid
set "BV.Internal.Spec.Remaining=!BV.Internal.Spec.Value!"
set "BV.Internal.Spec.Count=0"
:RuleSpecCore.Next
set "BV.Internal.Spec.Token="
set "BV.Internal.Spec.Rest="
for /f "tokens=1,* delims=+" %%A in ("!BV.Internal.Spec.Remaining!") do (
    set "BV.Internal.Spec.Token=%%~A"
    set "BV.Internal.Spec.Rest=%%~B"
)
set /a BV.Internal.Spec.Count+=1
if !BV.Internal.Spec.Count! GTR 32 (
    call :SetFailure TooManyConstraints "Validation rule contains more than 32 constraints." RuleSpec "One through 32 constraints" "%~1"
    exit /b 1
)
call :ConstraintDefinitionCore "!BV.Internal.Spec.Token!"
if errorlevel 1 exit /b 1
if not defined BV.Internal.Spec.Rest (
    set "BV.Internal.Normalized=!BV.Internal.Spec.Value!"
    exit /b 0
)
set "BV.Internal.Spec.Remaining=!BV.Internal.Spec.Rest!"
goto :RuleSpecCore.Next
:RuleSpecCore.Invalid
call :SetFailure InvalidRuleSpec "Validation rule specification has invalid separator syntax." RuleSpec "Constraints separated by single plus signs" "%~1"
exit /b 1

:ConstraintDefinitionCore
set "BV.Internal.Constraint.Token=%~1"
set "BV.Internal.Constraint.Name="
set "BV.Internal.Constraint.Argument="
for /f "tokens=1,* delims==" %%A in ("!BV.Internal.Constraint.Token!") do (
    set "BV.Internal.Constraint.Name=%%~A"
    set "BV.Internal.Constraint.Argument=%%~B"
)
for %%C in (Identifier DottedIdentifier Int32 UInt32 Boolean SchemaType TypeId NonEmpty) do if /i "!BV.Internal.Constraint.Name!"=="%%C" (
    if defined BV.Internal.Constraint.Argument goto :ConstraintDefinitionCore.UnexpectedArgument
    exit /b 0
)
if /i "!BV.Internal.Constraint.Name!"=="Enum" (
    call :EnumChoicesCore "!BV.Internal.Constraint.Argument!"
    if errorlevel 1 exit /b 1
    exit /b 0
)
if /i "!BV.Internal.Constraint.Name!"=="Path" (
    call :PathModeCore "!BV.Internal.Constraint.Argument!"
    if errorlevel 1 exit /b 1
    exit /b 0
)
if /i "!BV.Internal.Constraint.Name!"=="Handle" (
    call :HandleDefinitionCore "!BV.Internal.Constraint.Argument!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.Constraint.Name!"=="MaxLength" (
    call :UInt32Core "!BV.Internal.Constraint.Argument!"
    if errorlevel 1 goto :ConstraintDefinitionCore.BadArgument
    if !BV.Internal.Normalized! LSS 1 goto :ConstraintDefinitionCore.BadArgument
    if !BV.Internal.Normalized! GTR 8191 goto :ConstraintDefinitionCore.BadArgument
    exit /b 0
)
if /i "!BV.Internal.Constraint.Name!"=="Min" (
    call :Int32Core "!BV.Internal.Constraint.Argument!"
    if errorlevel 1 goto :ConstraintDefinitionCore.BadArgument
    exit /b 0
)
if /i "!BV.Internal.Constraint.Name!"=="Max" (
    call :Int32Core "!BV.Internal.Constraint.Argument!"
    if errorlevel 1 goto :ConstraintDefinitionCore.BadArgument
    exit /b 0
)
if /i "!BV.Internal.Constraint.Name!"=="Not" (
    call :NonEmptyListCore "!BV.Internal.Constraint.Argument!" Not
    exit /b !errorlevel!
)
if /i "!BV.Internal.Constraint.Name!"=="NotPrefix" (
    call :NonEmptyListCore "!BV.Internal.Constraint.Argument!" NotPrefix
    exit /b !errorlevel!
)
call :SetFailure UnknownConstraint "Validation rule contains an unknown constraint." "!BV.Internal.Constraint.Name!" "Known BatchValidate constraint" "!BV.Internal.Constraint.Token!"
exit /b 1
:ConstraintDefinitionCore.UnexpectedArgument
call :SetFailure UnexpectedConstraintArgument "Constraint does not accept an argument." "!BV.Internal.Constraint.Name!" "Constraint without equals sign" "!BV.Internal.Constraint.Token!"
exit /b 1
:ConstraintDefinitionCore.BadArgument
call :SetFailure InvalidConstraintArgument "Constraint argument is invalid." "!BV.Internal.Constraint.Name!" "Valid constraint argument" "!BV.Internal.Constraint.Argument!"
exit /b 1

:PathModeCore
set "BV.Internal.PathMode.Input=%~1"
for %%M in (Any File Directory ExistingFile ExistingDirectory) do if /i "!BV.Internal.PathMode.Input!"=="%%M" exit /b 0
call :SetFailure InvalidPathMode "Path validation mode is not supported." Path "Any, File, Directory, ExistingFile, or ExistingDirectory" "%~1"
exit /b 1

:HandleDefinitionCore
set "BV.Internal.HandleDef.Argument=%~1"
set "BV.Internal.HandleDef.Prefix="
set "BV.Internal.HandleDef.Width="
for /f "tokens=1,* delims=," %%A in ("!BV.Internal.HandleDef.Argument!") do (
    set "BV.Internal.HandleDef.Prefix=%%~A"
    set "BV.Internal.HandleDef.Width=%%~B"
)
if not defined BV.Internal.HandleDef.Prefix goto :HandleDefinitionCore.Invalid
if not defined BV.Internal.HandleDef.Width goto :HandleDefinitionCore.Invalid
if not "!BV.Internal.HandleDef.Width:,=!"=="!BV.Internal.HandleDef.Width!" goto :HandleDefinitionCore.Invalid
call :IdentifierCore "!BV.Internal.HandleDef.Prefix!"
if errorlevel 1 goto :HandleDefinitionCore.Invalid
call :UInt32Core "!BV.Internal.HandleDef.Width!"
if errorlevel 1 goto :HandleDefinitionCore.Invalid
if !BV.Internal.Normalized! LSS 1 goto :HandleDefinitionCore.Invalid
if !BV.Internal.Normalized! GTR 16 goto :HandleDefinitionCore.Invalid
exit /b 0
:HandleDefinitionCore.Invalid
call :SetFailure InvalidHandleConstraint "Handle constraint requires a prefix and width." Handle "Handle=Prefix,Width" "%~1"
exit /b 1

:NonEmptyListCore
set "BV.Internal.ListCheck.Value=%~1"
set "BV.Internal.ListCheck.Constraint=%~2"
if not defined BV.Internal.ListCheck.Value goto :NonEmptyListCore.Invalid
if "!BV.Internal.ListCheck.Value:~0,1!"=="," goto :NonEmptyListCore.Invalid
if "!BV.Internal.ListCheck.Value:~-1!"=="," goto :NonEmptyListCore.Invalid
if not "!BV.Internal.ListCheck.Value:,,=!"=="!BV.Internal.ListCheck.Value!" goto :NonEmptyListCore.Invalid
exit /b 0
:NonEmptyListCore.Invalid
call :SetFailure InvalidConstraintArgument "Constraint requires a comma-separated list without empty entries." "!BV.Internal.ListCheck.Constraint!" "Non-empty comma-separated list" "%~1"
exit /b 1

:ApplySpecCore
set "BV.Internal.Apply.Value=%~1"
set "BV.Internal.Apply.Spec=%~2"
call :RuleSpecCore "!BV.Internal.Apply.Spec!"
if errorlevel 1 exit /b 1
set "BV.Internal.Apply.Current=!BV.Internal.Apply.Value!"
set "BV.Internal.Apply.Remaining=!BV.Internal.Apply.Spec!"
:ApplySpecCore.Next
set "BV.Internal.Apply.Token="
set "BV.Internal.Apply.Rest="
for /f "tokens=1,* delims=+" %%A in ("!BV.Internal.Apply.Remaining!") do (
    set "BV.Internal.Apply.Token=%%~A"
    set "BV.Internal.Apply.Rest=%%~B"
)
call :ApplyConstraintCore "!BV.Internal.Apply.Current!" "!BV.Internal.Apply.Token!"
if errorlevel 1 exit /b 1
set "BV.Internal.Apply.Current=!BV.Internal.Normalized!"
if not defined BV.Internal.Apply.Rest (
    set "BV.Internal.Normalized=!BV.Internal.Apply.Current!"
    exit /b 0
)
set "BV.Internal.Apply.Remaining=!BV.Internal.Apply.Rest!"
goto :ApplySpecCore.Next

:ApplyConstraintCore
set "BV.Internal.ApplyConstraint.Value=%~1"
set "BV.Internal.ApplyConstraint.Token=%~2"
set "BV.Internal.ApplyConstraint.Name="
set "BV.Internal.ApplyConstraint.Argument="
for /f "tokens=1,* delims==" %%A in ("!BV.Internal.ApplyConstraint.Token!") do (
    set "BV.Internal.ApplyConstraint.Name=%%~A"
    set "BV.Internal.ApplyConstraint.Argument=%%~B"
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="Identifier" (
    call :IdentifierCore "!BV.Internal.ApplyConstraint.Value!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="DottedIdentifier" (
    call :DottedIdentifierCore "!BV.Internal.ApplyConstraint.Value!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="Int32" (
    call :Int32Core "!BV.Internal.ApplyConstraint.Value!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="UInt32" (
    call :UInt32Core "!BV.Internal.ApplyConstraint.Value!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="Boolean" (
    call :BooleanCore "!BV.Internal.ApplyConstraint.Value!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="Enum" (
    call :EnumCore "!BV.Internal.ApplyConstraint.Value!" "!BV.Internal.ApplyConstraint.Argument!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="Path" (
    call :PathCore "!BV.Internal.ApplyConstraint.Value!" "!BV.Internal.ApplyConstraint.Argument!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="Handle" (
    call :HandleDefinitionCore "!BV.Internal.ApplyConstraint.Argument!"
    if errorlevel 1 exit /b 1
    call :HandleCore "!BV.Internal.ApplyConstraint.Value!" "!BV.Internal.HandleDef.Prefix!" "!BV.Internal.HandleDef.Width!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="SchemaType" (
    call :SchemaTypeCore "!BV.Internal.ApplyConstraint.Value!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="TypeId" (
    call :TypeIdCore "!BV.Internal.ApplyConstraint.Value!"
    exit /b !errorlevel!
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="NonEmpty" (
    if defined BV.Internal.ApplyConstraint.Value (
        set "BV.Internal.Normalized=!BV.Internal.ApplyConstraint.Value!"
        exit /b 0
    )
    call :SetFailure EmptyValue "Value cannot be empty." NonEmpty "Non-empty value" "%~1"
    exit /b 1
)
if /i "!BV.Internal.ApplyConstraint.Name!"=="MaxLength" goto :ApplyConstraintCore.MaxLength
if /i "!BV.Internal.ApplyConstraint.Name!"=="Min" goto :ApplyConstraintCore.Min
if /i "!BV.Internal.ApplyConstraint.Name!"=="Max" goto :ApplyConstraintCore.Max
if /i "!BV.Internal.ApplyConstraint.Name!"=="Not" goto :ApplyConstraintCore.Not
if /i "!BV.Internal.ApplyConstraint.Name!"=="NotPrefix" goto :ApplyConstraintCore.NotPrefix
call :SetFailure UnknownConstraint "Validation rule contains an unknown constraint." "!BV.Internal.ApplyConstraint.Name!" "Known BatchValidate constraint" "!BV.Internal.ApplyConstraint.Token!"
exit /b 1

:ApplyConstraintCore.MaxLength
call :UInt32Core "!BV.Internal.ApplyConstraint.Argument!"
if errorlevel 1 exit /b 1
set "BV.Internal.ApplyConstraint.Limit=!BV.Internal.Normalized!"
set "BV.Internal.ApplyConstraint.Length=0"
set "BV.Internal.ApplyConstraint.Work=!BV.Internal.ApplyConstraint.Value!"
:ApplyConstraintCore.MaxLength.Next
if not defined BV.Internal.ApplyConstraint.Work goto :ApplyConstraintCore.MaxLength.Done
set /a BV.Internal.ApplyConstraint.Length+=1
set "BV.Internal.ApplyConstraint.Work=!BV.Internal.ApplyConstraint.Work:~1!"
goto :ApplyConstraintCore.MaxLength.Next
:ApplyConstraintCore.MaxLength.Done
if !BV.Internal.ApplyConstraint.Length! GTR !BV.Internal.ApplyConstraint.Limit! (
    call :SetFailure ValueTooLong "Value exceeds the maximum length constraint." MaxLength "At most !BV.Internal.ApplyConstraint.Limit! characters" "%~1"
    exit /b 1
)
set "BV.Internal.Normalized=!BV.Internal.ApplyConstraint.Value!"
exit /b 0

:ApplyConstraintCore.Min
call :Int32Core "!BV.Internal.ApplyConstraint.Argument!"
if errorlevel 1 exit /b 1
set "BV.Internal.ApplyConstraint.Limit=!BV.Internal.Normalized!"
call :Int32Core "!BV.Internal.ApplyConstraint.Value!"
if errorlevel 1 exit /b 1
set "BV.Internal.ApplyConstraint.Numeric=!BV.Internal.Normalized!"
if !BV.Internal.ApplyConstraint.Numeric! LSS !BV.Internal.ApplyConstraint.Limit! (
    call :SetFailure ValueBelowMinimum "Value is below the minimum constraint." Min "At least !BV.Internal.ApplyConstraint.Limit!" "!BV.Internal.ApplyConstraint.Numeric!"
    exit /b 1
)
set "BV.Internal.Normalized=!BV.Internal.ApplyConstraint.Numeric!"
exit /b 0

:ApplyConstraintCore.Max
call :Int32Core "!BV.Internal.ApplyConstraint.Argument!"
if errorlevel 1 exit /b 1
set "BV.Internal.ApplyConstraint.Limit=!BV.Internal.Normalized!"
call :Int32Core "!BV.Internal.ApplyConstraint.Value!"
if errorlevel 1 exit /b 1
set "BV.Internal.ApplyConstraint.Numeric=!BV.Internal.Normalized!"
if !BV.Internal.ApplyConstraint.Numeric! GTR !BV.Internal.ApplyConstraint.Limit! (
    call :SetFailure ValueAboveMaximum "Value exceeds the maximum constraint." Max "At most !BV.Internal.ApplyConstraint.Limit!" "!BV.Internal.ApplyConstraint.Numeric!"
    exit /b 1
)
set "BV.Internal.Normalized=!BV.Internal.ApplyConstraint.Numeric!"
exit /b 0

:ApplyConstraintCore.Not
set "BV.Internal.ApplyConstraint.Remaining=!BV.Internal.ApplyConstraint.Argument!"
:ApplyConstraintCore.Not.Next
set "BV.Internal.ApplyConstraint.Item="
set "BV.Internal.ApplyConstraint.Rest="
for /f "tokens=1,* delims=," %%A in ("!BV.Internal.ApplyConstraint.Remaining!") do (
    set "BV.Internal.ApplyConstraint.Item=%%~A"
    set "BV.Internal.ApplyConstraint.Rest=%%~B"
)
if /i "!BV.Internal.ApplyConstraint.Value!"=="!BV.Internal.ApplyConstraint.Item!" (
    call :SetFailure ForbiddenValue "Value is explicitly forbidden." Not "Value outside the forbidden list" "%~1"
    exit /b 1
)
if not defined BV.Internal.ApplyConstraint.Rest (
    set "BV.Internal.Normalized=!BV.Internal.ApplyConstraint.Value!"
    exit /b 0
)
set "BV.Internal.ApplyConstraint.Remaining=!BV.Internal.ApplyConstraint.Rest!"
goto :ApplyConstraintCore.Not.Next

:ApplyConstraintCore.NotPrefix
set "BV.Internal.ApplyConstraint.Remaining=!BV.Internal.ApplyConstraint.Argument!"
:ApplyConstraintCore.NotPrefix.Next
set "BV.Internal.ApplyConstraint.Item="
set "BV.Internal.ApplyConstraint.Rest="
for /f "tokens=1,* delims=," %%A in ("!BV.Internal.ApplyConstraint.Remaining!") do (
    set "BV.Internal.ApplyConstraint.Item=%%~A"
    set "BV.Internal.ApplyConstraint.Rest=%%~B"
)
set "BV.Internal.ApplyConstraint.PrefixLength=0"
set "BV.Internal.ApplyConstraint.Work=!BV.Internal.ApplyConstraint.Item!"
:ApplyConstraintCore.NotPrefix.Length
if not defined BV.Internal.ApplyConstraint.Work goto :ApplyConstraintCore.NotPrefix.Compare
set /a BV.Internal.ApplyConstraint.PrefixLength+=1
set "BV.Internal.ApplyConstraint.Work=!BV.Internal.ApplyConstraint.Work:~1!"
goto :ApplyConstraintCore.NotPrefix.Length
:ApplyConstraintCore.NotPrefix.Compare
for %%N in (!BV.Internal.ApplyConstraint.PrefixLength!) do set "BV.Internal.ApplyConstraint.ActualPrefix=!BV.Internal.ApplyConstraint.Value:~0,%%N!"
if /i "!BV.Internal.ApplyConstraint.ActualPrefix!"=="!BV.Internal.ApplyConstraint.Item!" (
    call :SetFailure ForbiddenPrefix "Value begins with a forbidden prefix." NotPrefix "Value without a forbidden prefix" "%~1"
    exit /b 1
)
if not defined BV.Internal.ApplyConstraint.Rest (
    set "BV.Internal.Normalized=!BV.Internal.ApplyConstraint.Value!"
    exit /b 0
)
set "BV.Internal.ApplyConstraint.Remaining=!BV.Internal.ApplyConstraint.Rest!"
goto :ApplyConstraintCore.NotPrefix.Next

:DigitsCore
set "BV.Internal.Digits.Work=%~1"
if not defined BV.Internal.Digits.Work exit /b 1
:DigitsCore.Next
if not defined BV.Internal.Digits.Work exit /b 0
set "BV.Internal.Digits.Character=!BV.Internal.Digits.Work:~0,1!"
call :DigitCharacterCore "!BV.Internal.Digits.Character!"
if errorlevel 1 exit /b 1
set "BV.Internal.Digits.Work=!BV.Internal.Digits.Work:~1!"
goto :DigitsCore.Next

:StripLeadingZeroesCore
set "BV.Internal.Strip.Work=%~1"
:StripLeadingZeroesCore.Next
if "!BV.Internal.Strip.Work!"=="0" goto :StripLeadingZeroesCore.Done
if not "!BV.Internal.Strip.Work:~0,1!"=="0" goto :StripLeadingZeroesCore.Done
set "BV.Internal.Strip.Work=!BV.Internal.Strip.Work:~1!"
goto :StripLeadingZeroesCore.Next
:StripLeadingZeroesCore.Done
set "BV.Internal.StrippedDigits=!BV.Internal.Strip.Work!"
exit /b 0

:DecimalWithinLimitCore
set "BV.Internal.Decimal.Value=%~1"
set "BV.Internal.Decimal.Maximum=%~2"
set "BV.Internal.Decimal.Work=!BV.Internal.Decimal.Value!"
set "BV.Internal.Decimal.Length=0"
:DecimalWithinLimitCore.Length
if not defined BV.Internal.Decimal.Work goto :DecimalWithinLimitCore.LengthDone
set /a BV.Internal.Decimal.Length+=1
set "BV.Internal.Decimal.Work=!BV.Internal.Decimal.Work:~1!"
goto :DecimalWithinLimitCore.Length
:DecimalWithinLimitCore.LengthDone
set "BV.Internal.Decimal.MaxWork=!BV.Internal.Decimal.Maximum!"
set "BV.Internal.Decimal.MaxLength=0"
:DecimalWithinLimitCore.MaxLength
if not defined BV.Internal.Decimal.MaxWork goto :DecimalWithinLimitCore.CompareLength
set /a BV.Internal.Decimal.MaxLength+=1
set "BV.Internal.Decimal.MaxWork=!BV.Internal.Decimal.MaxWork:~1!"
goto :DecimalWithinLimitCore.MaxLength
:DecimalWithinLimitCore.CompareLength
if !BV.Internal.Decimal.Length! LSS !BV.Internal.Decimal.MaxLength! exit /b 0
if !BV.Internal.Decimal.Length! GTR !BV.Internal.Decimal.MaxLength! exit /b 1
set "BV.Internal.Decimal.LeftWork=!BV.Internal.Decimal.Value!"
set "BV.Internal.Decimal.RightWork=!BV.Internal.Decimal.Maximum!"
:DecimalWithinLimitCore.Compare
if not defined BV.Internal.Decimal.LeftWork exit /b 0
set "BV.Internal.Decimal.LeftDigit=!BV.Internal.Decimal.LeftWork:~0,1!"
set "BV.Internal.Decimal.RightDigit=!BV.Internal.Decimal.RightWork:~0,1!"
if !BV.Internal.Decimal.LeftDigit! LSS !BV.Internal.Decimal.RightDigit! exit /b 0
if !BV.Internal.Decimal.LeftDigit! GTR !BV.Internal.Decimal.RightDigit! exit /b 1
set "BV.Internal.Decimal.LeftWork=!BV.Internal.Decimal.LeftWork:~1!"
set "BV.Internal.Decimal.RightWork=!BV.Internal.Decimal.RightWork:~1!"
goto :DecimalWithinLimitCore.Compare

:AlphaCharacterCore
set "BV.Internal.Character=%~1"
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" %%A in ("!BV.Internal.Character!") do exit /b 1
exit /b 0

:DigitCharacterCore
set "BV.Internal.Character=%~1"
for /f "delims=0123456789" %%A in ("!BV.Internal.Character!") do exit /b 1
exit /b 0

:EnsureInitialized
if defined BV.Initialized exit /b 0
call :Initialize
exit /b !errorlevel!

:ValidateErrorField
for %%F in (Code Kind Message Operation Constraint Expected Actual) do if /i "%~1"=="%%F" exit /b 0
exit /b 1

:ClearFailure
set "BV.Internal.Failure.Kind="
set "BV.Internal.Failure.Message="
set "BV.Internal.Failure.Constraint="
set "BV.Internal.Failure.Expected="
set "BV.Internal.Failure.Actual="
exit /b 0

:SetFailure
set "BV.Internal.Failure.Kind=%~1"
set "BV.Internal.Failure.Message=%~2"
set "BV.Internal.Failure.Constraint=%~3"
set "BV.Internal.Failure.Expected=%~4"
set "BV.Internal.Failure.Actual=%~5"
exit /b 0

:ClearLastErrorInternal
set "BV.LastError.Code=0"
set "BV.LastError.Kind=None"
set "BV.LastError.Message="
set "BV.LastError.Operation="
set "BV.LastError.Constraint="
set "BV.LastError.Expected="
set "BV.LastError.Actual="
exit /b 0

:SetError
set "BV.LastError.Code=%~1"
set "BV.LastError.Kind=%~2"
set "BV.LastError.Message=%~3"
set "BV.LastError.Operation=%~4"
set "BV.LastError.Constraint=%~5"
set "BV.LastError.Expected=%~6"
set "BV.LastError.Actual=%~7"
exit /b 0

:ExportResult
for %%O in ("%~1") do set "%%~O=%~2"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
