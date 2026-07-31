@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Validator=%~dp0..\BatchValidate.bat"
set "BatchTest=%~dp0..\..\BatchTest\BatchTest.bat"

call "!BatchTest!" begin suite "BatchValidate 1.0 deterministic self-test"

call "!Validator!" initialize validation
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchValidate"

call "!Validator!" get statistic RuleCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Rule registry starts empty"

call "!Validator!" validate identifier Player_1 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Validate an identifier through readable syntax"
call "!BatchTest!" expect value "!Actual!" to equal Player_1 because "Identifier spelling is preserved"

set "Id64=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_A"
call "!Validator!" :Identifier "!Id64!" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Accept a 64-character identifier"

set "Id65=!Id64!B"
call "!Validator!" :Identifier "!Id65!" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a 65-character identifier"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal ValueTooLong because "Report identifier length failure"

call "!Validator!" :Identifier 2Player Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an identifier beginning with a digit"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal InvalidIdentifier because "Report invalid identifier syntax"

call "!Validator!" :Identifier Player-1 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject punctuation in an identifier"

call "!Validator!" :Identifier "" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject an empty identifier"

call "!Validator!" :DottedIdentifier Player.Stats.Health Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Validate a dotted identifier"
call "!BatchTest!" expect value "!Actual!" to equal Player.Stats.Health because "Preserve dotted identifier spelling"

for %%V in (.Leading Trailing. Double..Dot 2Invalid.Start) do (
    call "!Validator!" :DottedIdentifier "%%V" Actual
    call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject malformed dotted identifier %%V"
)

call "!Validator!" :Int32 00042 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Normalize a signed integer"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Strip signed integer leading zeroes"

call "!Validator!" :Int32 -0000 Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Normalize negative zero"

call "!Validator!" :Int32 -2147483648 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Accept the minimum signed integer"
call "!BatchTest!" expect value "!Actual!" to equal -2147483648 because "Preserve the minimum signed integer"

call "!Validator!" :Int32 2147483647 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Accept the maximum signed integer"

call "!Validator!" :Int32 2147483648 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a signed integer above maximum"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal IntegerOutOfRange because "Report signed integer overflow"

call "!Validator!" :Int32 -2147483649 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a signed integer below minimum"

for %%V in (+1 1.0 1x " 1") do (
    call "!Validator!" :Int32 "%%~V" Actual
    call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject malformed signed integer %%~V"
)

call "!Validator!" :UInt32 00017 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Normalize an unsigned integer"
call "!BatchTest!" expect value "!Actual!" to equal 17 because "Strip unsigned integer leading zeroes"

call "!Validator!" :UInt32 2147483647 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Accept the maximum unsigned integer"

call "!Validator!" :UInt32 -1 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a negative unsigned integer"

call "!Validator!" :UInt32 2147483648 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject an unsigned integer above maximum"

call "!Validator!" :Boolean YES Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Accept a true Boolean synonym"
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Normalize true Boolean values"

call "!Validator!" :Boolean off Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Accept a false Boolean synonym"
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Normalize false Boolean values"

call "!Validator!" :Boolean maybe Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an unknown Boolean"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal InvalidBoolean because "Report invalid Boolean input"

call "!Validator!" :Enum green "Red,Green,Blue" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate an enum value"
call "!BatchTest!" expect value "!Actual!" to equal Green because "Normalize enum values to schema spelling"

call "!Validator!" :Enum Yellow "Red,Green,Blue" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a value outside enum choices"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal EnumValueNotAllowed because "Report an enum membership failure"

call "!Validator!" :EnumChoices "Red,Green,Blue" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate enum choice schema"

for %%V in ("Red,,Blue" "Red,red" "Red,Bad-Choice") do (
    call "!Validator!" :EnumChoices "%%~V" Actual
    call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject malformed enum choices %%~V"
)

call "!Validator!" :SchemaType uint Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate a schema type"
call "!BatchTest!" expect value "!Actual!" to equal UInt because "Normalize schema type spelling"

call "!Validator!" :SchemaType String Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an unsupported schema type"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal InvalidSchemaType because "Report unsupported schema type"

call "!Validator!" :TypeId TestModule.Pair.Result Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate an object type identifier"

call "!Validator!" :TypeId TestModule..Result Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a malformed object type identifier"

call "!Validator!" :Handle O000001 O 6 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate a runtime object handle"
call "!BatchTest!" expect value "!Actual!" to equal O000001 because "Preserve a valid handle"

call "!Validator!" :Handle o000001 O 6 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Match handle prefixes case-insensitively"
call "!BatchTest!" expect value "!Actual!" to equal O000001 because "Normalize handle prefix spelling"

for %%V in (X000001 O00001 O00000A) do (
    call "!Validator!" :Handle "%%V" O 6 Actual
    call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject malformed handle %%V"
)

call "!Validator!" :Handle O000001 O 0 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a zero handle width"

set "TempRoot=%TEMP%\BatchValidate-!RANDOM!-!RANDOM!"
set "TempFile=!TempRoot!\sample.txt"
2>nul mkdir "!TempRoot!"
> "!TempFile!" echo BatchValidate path test
for %%P in ("!TempFile!") do set "ExpectedPath=%%~fP"
for %%P in ("!TempRoot!") do set "ExpectedDirectory=%%~fP"

call "!Validator!" :Path "!TempFile!" ExistingFile Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate an existing file path"
call "!BatchTest!" expect value "!Actual!" to equal "!ExpectedPath!" because "Normalize an existing file path"

call "!Validator!" :Path "!TempRoot!" ExistingDirectory Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate an existing directory path"
call "!BatchTest!" expect value "!Actual!" to equal "!ExpectedDirectory!" because "Normalize an existing directory path"

call "!Validator!" :Path "!TempRoot!\missing.txt" File Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Allow a non-existing file target"

call "!Validator!" :Path "!TempRoot!\missing.txt" ExistingFile Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a missing required file"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal PathNotFound because "Report a missing path"

call "!Validator!" :Path "!TempRoot!" File Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a directory where a file is required"

call "!Validator!" :Path "!TempFile!" Directory Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a file where a directory is required"

call "!Validator!" :Path "bad*path" Any Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject wildcard path characters"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal InvalidPath because "Report invalid path syntax"

call "!Validator!" :Apply Player_1 "Identifier+MaxLength=8" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Apply composed identifier constraints"

call "!Validator!" :Apply Player_123 "Identifier+MaxLength=8" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Enforce a composed maximum length"
call "!BatchTest!" expect value "!BV.LastError.Constraint!" to equal MaxLength because "Identify the failing composed constraint"

call "!Validator!" :Apply -3 "Int32+Min=-5+Max=5" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Apply composed numeric bounds"
call "!BatchTest!" expect value "!Actual!" to equal -3 because "Preserve a bounded numeric value"

call "!Validator!" :Apply -6 "Int32+Min=-5+Max=5" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a value below a composed minimum"

call "!Validator!" :Apply 6 "Int32+Min=-5+Max=5" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject a value above a composed maximum"

call "!Validator!" :Apply PATH "Identifier+Not=PATH,TEMP+NotPrefix=BV,BRT" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an explicitly forbidden value"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal ForbiddenValue because "Report a forbidden value"

call "!Validator!" :Apply BRTResult "Identifier+Not=PATH,TEMP+NotPrefix=BV,BRT" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a forbidden prefix"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal ForbiddenPrefix because "Report a forbidden prefix"

call "!Validator!" :Apply O000042 "Handle=O,6" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Apply a parameterized handle constraint"

call "!Validator!" :DefineRule ShortId "Identifier+MaxLength=8"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a reusable validation rule"

call "!Validator!" :DefineRule NoReserved "Identifier+Not=PATH,TEMP"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a second reusable rule"

call "!Validator!" :ComposeRule PublicName ShortId NoReserved
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Compose reusable validation rules"

call "!Validator!" :ValidateWith PublicName Hero_1 Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate with a composed named rule"
call "!BatchTest!" expect value "!Actual!" to equal Hero_1 because "Named rule returns the normalized value"

call "!Validator!" :ValidateWith PublicName PATH Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Named rule preserves composed exclusions"

call "!Validator!" :DefineRule ShortId "Identifier"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a duplicate validation rule"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal ValidationRuleAlreadyExists because "Report a duplicate validation rule"

call "!Validator!" :DefineRule Broken "Identifier++MaxLength=8"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject malformed rule separator syntax"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal InvalidRuleSpec because "Report malformed rule syntax"

call "!Validator!" :DefineRule Unknown "Identifier+Mystery"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an unknown validation constraint"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal UnknownConstraint because "Report an unknown constraint"

call "!Validator!" :GetStat RuleCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 3 because "Track active validation rules"

call "!Validator!" :ListRules >nul
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "List validation rules"

call "!Validator!" :ReleaseRule PublicName
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Release a validation rule"

call "!Validator!" :ValidateWith PublicName Hero Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a missing validation rule"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal ValidationRuleNotFound because "Report a missing validation rule"

call "!Validator!" :Int32 2147483648 Actual
call "!Validator!" :ReadLastError Kind ErrorKind
call "!Validator!" :ReadLastError Constraint ErrorConstraint
call "!Validator!" :ReadLastError Actual ErrorActual
call "!BatchTest!" expect value "!ErrorKind!" to equal IntegerOutOfRange because "Read a structured validation error kind"
call "!BatchTest!" expect value "!ErrorConstraint!" to equal Int32 because "Read a structured validation error constraint"
call "!BatchTest!" expect value "!ErrorActual!" to equal 2147483648 because "Read structured validation error input"

call "!Validator!" :ReadLastError Unknown Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Reject an unknown validation error field"

call "!Validator!" :Identifier Safe PATH
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 10 because "Reject a reserved output variable"
call "!BatchTest!" expect value "!BV.LastError.Kind!" to equal InvalidOutputVariable because "Report an unsafe output variable"

set "BV.Pwned=0"
set "Hostile=A&B"
call "!Validator!" :Identifier "!Hostile!" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Treat ampersand input as data"
call "!BatchTest!" expect value "!BV.Pwned!" to equal 0 because "Ampersand input cannot inject a command"

set "Hostile=A|B"
call "!Validator!" :Identifier "!Hostile!" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Treat pipe input as data"
call "!BatchTest!" expect value "!BV.Pwned!" to equal 0 because "Pipe input cannot inject a command"

set "Hostile=A(B)"
call "!Validator!" :Identifier "!Hostile!" Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 20 because "Treat parentheses input as data"

del /q "!TempFile!" >nul 2>nul
rmdir /q "!TempRoot!" >nul 2>nul

call "!Validator!" shutdown validation
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Shutdown BatchValidate"

call "!Validator!" :Identifier LazyInit Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Primitive validation lazily restores component state"
call "!BatchTest!" expect value "!Actual!" to equal LazyInit because "Lazy validation still returns a value"

call "!BatchTest!" finish suite
set "TestExit=!errorlevel!"
call "!Validator!" shutdown validation >nul 2>nul
exit /b !TestExit!
