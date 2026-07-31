@echo off

rem BatchMath.bat
rem Project-agnostic signed 32-bit arithmetic for Windows batch files.
rem Version 1.0.0 - protocol 1
rem Requirement: caller must enable command extensions and delayed expansion.

set "BM.Internal.DelayedProbe=1"
if not "!BM.Internal.DelayedProbe!"=="1" (
    echo BatchMath requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="add" goto :Readable.Add
if /i "%~1"=="subtract" goto :Readable.Subtract
if /i "%~1"=="multiply" goto :Readable.Multiply
if /i "%~1"=="divide" goto :Readable.Divide
if /i "%~1"=="modulo" goto :Readable.Modulo
if /i "%~1"=="floor" goto :Readable.Floor
if /i "%~1"=="absolute" goto :Readable.Absolute
if /i "%~1"=="minimum" goto :Readable.Minimum
if /i "%~1"=="maximum" goto :Readable.Maximum
if /i "%~1"=="clamp" goto :Readable.Clamp
if /i "%~1"=="compare" goto :Readable.Compare
if /i "%~1"=="check" goto :Readable.Check
if /i "%~1"=="sign" goto :Readable.Sign
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="clear" goto :Readable.Clear
if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":Add" goto :Add
if /i "%~1"==":Subtract" goto :Subtract
if /i "%~1"==":Multiply" goto :Multiply
if /i "%~1"==":Divide" goto :Divide
if /i "%~1"==":Modulo" goto :Modulo
if /i "%~1"==":FloorDivide" goto :FloorDivide
if /i "%~1"==":FloorModulo" goto :FloorModulo
if /i "%~1"==":Absolute" goto :Absolute
if /i "%~1"==":Minimum" goto :Minimum
if /i "%~1"==":Maximum" goto :Maximum
if /i "%~1"==":Clamp" goto :Clamp
if /i "%~1"==":Compare" goto :Compare
if /i "%~1"==":InRange" goto :InRange
if /i "%~1"==":Sign" goto :Sign
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :SetError 10 UnknownMathCommand "Unknown BatchMath command." "" "" "Known math command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="math" goto :Readable.Syntax
call "%~f0" :Initialize
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="math" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Add
if /i not "%~3"=="and" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Add "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Subtract
if /i not "%~3"=="minus" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Subtract "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Multiply
if /i not "%~3"=="by" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Multiply "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Divide
if /i not "%~3"=="by" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Divide "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Modulo
if /i not "%~3"=="by" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Modulo "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Floor
if /i "%~2"=="divide" goto :Readable.FloorDivide
if /i "%~2"=="modulo" goto :Readable.FloorModulo
goto :Readable.Syntax

:Readable.FloorDivide
if /i not "%~4"=="by" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :FloorDivide "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.FloorModulo
if /i not "%~4"=="by" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :FloorModulo "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.Absolute
if /i not "%~3"=="into" goto :Readable.Syntax
call "%~f0" :Absolute "%~2" "%~4"
exit /b !errorlevel!

:Readable.Minimum
if /i not "%~3"=="and" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Minimum "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Maximum
if /i not "%~3"=="and" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Maximum "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Clamp
if /i not "%~3"=="between" goto :Readable.Syntax
if /i not "%~5"=="and" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :Clamp "%~2" "%~4" "%~6" "%~8"
exit /b !errorlevel!

:Readable.Compare
if /i not "%~3"=="with" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Compare "%~2" "%~4" "%~6"
exit /b !errorlevel!

:Readable.Check
if /i not "%~3"=="between" goto :Readable.Syntax
if /i not "%~5"=="and" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :InRange "%~2" "%~4" "%~6" "%~8"
exit /b !errorlevel!

:Readable.Sign
if /i not "%~3"=="into" goto :Readable.Syntax
call "%~f0" :Sign "%~2" "%~4"
exit /b !errorlevel!

:Readable.Read
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :ReadLastError "%~4" "%~6"
exit /b !errorlevel!

:Readable.Show
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
call "%~f0" :PrintLastError
exit /b !errorlevel!

:Readable.Clear
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
call "%~f0" :ClearLastError
exit /b !errorlevel!

:Readable.Syntax
call :SetError 10 InvalidMathSyntax "BatchMath command syntax is invalid." "" "" "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BM.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)
call :ClearPrefix "BM."
set "BM.Initialized=1"
set "BM.Version=1.0.0"
set "BM.Protocol=1"
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BM."
exit /b 0

:Add
call :BeginBinary Add "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
set /a BM.Internal.Result=BM.Internal.Left+BM.Internal.Right
if !BM.Internal.Left! GTR 0 if !BM.Internal.Right! GTR 0 if !BM.Internal.Result! LSS 0 goto :Add.Overflow
if !BM.Internal.Left! LSS 0 if !BM.Internal.Right! LSS 0 if !BM.Internal.Result! GEQ 0 goto :Add.Overflow
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0
:Add.Overflow
call :SetError 30 IntegerOverflow "Signed 32-bit addition overflowed." Add Both "-2147483648 through 2147483647" "!BM.Internal.Left! + !BM.Internal.Right!"
exit /b 30

:Subtract
call :BeginBinary Subtract "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
set /a BM.Internal.Result=BM.Internal.Left-BM.Internal.Right
if !BM.Internal.Left! GEQ 0 if !BM.Internal.Right! LSS 0 if !BM.Internal.Result! LSS 0 goto :Subtract.Overflow
if !BM.Internal.Left! LSS 0 if !BM.Internal.Right! GTR 0 if !BM.Internal.Result! GEQ 0 goto :Subtract.Overflow
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0
:Subtract.Overflow
call :SetError 30 IntegerOverflow "Signed 32-bit subtraction overflowed." Subtract Both "-2147483648 through 2147483647" "!BM.Internal.Left! - !BM.Internal.Right!"
exit /b 30

:Multiply
call :BeginBinary Multiply "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
if "!BM.Internal.Left!"=="0" (
    call :ExportResult "!BM.Internal.Output!" 0
    exit /b 0
)
if "!BM.Internal.Right!"=="0" (
    call :ExportResult "!BM.Internal.Output!" 0
    exit /b 0
)
if "!BM.Internal.Left!"=="-2147483648" if "!BM.Internal.Right!"=="-1" goto :Multiply.Overflow
if "!BM.Internal.Right!"=="-2147483648" if "!BM.Internal.Left!"=="-1" goto :Multiply.Overflow
set /a BM.Internal.Result=BM.Internal.Left*BM.Internal.Right
set /a BM.Internal.Check=BM.Internal.Result/BM.Internal.Right
if not "!BM.Internal.Check!"=="!BM.Internal.Left!" goto :Multiply.Overflow
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0
:Multiply.Overflow
call :SetError 30 IntegerOverflow "Signed 32-bit multiplication overflowed." Multiply Both "-2147483648 through 2147483647" "!BM.Internal.Left! * !BM.Internal.Right!"
exit /b 30

:Divide
call :BeginBinary Divide "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
call :RequireDivisor Divide "!BM.Internal.Left!" "!BM.Internal.Right!"
if errorlevel 1 exit /b !errorlevel!
set /a BM.Internal.Result=BM.Internal.Left/BM.Internal.Right
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:Modulo
call :BeginBinary Modulo "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
call :RequireDivisor Modulo "!BM.Internal.Left!" "!BM.Internal.Right!"
if errorlevel 1 exit /b !errorlevel!
set /a BM.Internal.Result=BM.Internal.Left%%BM.Internal.Right
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:FloorDivide
call :BeginBinary FloorDivide "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
call :RequireDivisor FloorDivide "!BM.Internal.Left!" "!BM.Internal.Right!"
if errorlevel 1 exit /b !errorlevel!
set /a BM.Internal.Result=BM.Internal.Left/BM.Internal.Right
set /a BM.Internal.Remainder=BM.Internal.Left%%BM.Internal.Right
if not "!BM.Internal.Remainder!"=="0" (
    if !BM.Internal.Left! LSS 0 if !BM.Internal.Right! GTR 0 set /a BM.Internal.Result-=1
    if !BM.Internal.Left! GTR 0 if !BM.Internal.Right! LSS 0 set /a BM.Internal.Result-=1
)
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:FloorModulo
call :BeginBinary FloorModulo "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
call :RequireDivisor FloorModulo "!BM.Internal.Left!" "!BM.Internal.Right!"
if errorlevel 1 exit /b !errorlevel!
set /a BM.Internal.Result=BM.Internal.Left%%BM.Internal.Right
if not "!BM.Internal.Result!"=="0" (
    if !BM.Internal.Left! LSS 0 if !BM.Internal.Right! GTR 0 set /a BM.Internal.Result+=BM.Internal.Right
    if !BM.Internal.Left! GTR 0 if !BM.Internal.Right! LSS 0 set /a BM.Internal.Result+=BM.Internal.Right
)
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:Absolute
call :BeginUnary Absolute "%~2" "%~3"
if errorlevel 1 exit /b !errorlevel!
if "!BM.Internal.Value!"=="-2147483648" (
    call :SetError 30 IntegerOverflow "The absolute value exceeds signed 32-bit range." Absolute Value "0 through 2147483647" "!BM.Internal.Value!"
    exit /b 30
)
set "BM.Internal.Result=!BM.Internal.Value!"
if !BM.Internal.Result! LSS 0 set /a BM.Internal.Result=0-BM.Internal.Result
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:Minimum
call :BeginBinary Minimum "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Result=!BM.Internal.Left!"
if !BM.Internal.Right! LSS !BM.Internal.Left! set "BM.Internal.Result=!BM.Internal.Right!"
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:Maximum
call :BeginBinary Maximum "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Result=!BM.Internal.Left!"
if !BM.Internal.Right! GTR !BM.Internal.Left! set "BM.Internal.Result=!BM.Internal.Right!"
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:Clamp
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareInt "%~2" Value Clamp
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Value=!BM.Internal.Prepared!"
call :PrepareInt "%~3" Minimum Clamp
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Minimum=!BM.Internal.Prepared!"
call :PrepareInt "%~4" Maximum Clamp
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Maximum=!BM.Internal.Prepared!"
call :PrepareOutput "%~5" Clamp
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Output=%~5"
call :RequireRange Clamp "!BM.Internal.Minimum!" "!BM.Internal.Maximum!"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Result=!BM.Internal.Value!"
if !BM.Internal.Result! LSS !BM.Internal.Minimum! set "BM.Internal.Result=!BM.Internal.Minimum!"
if !BM.Internal.Result! GTR !BM.Internal.Maximum! set "BM.Internal.Result=!BM.Internal.Maximum!"
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:Compare
call :BeginBinary Compare "%~2" "%~3" "%~4"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Result=0"
if !BM.Internal.Left! LSS !BM.Internal.Right! set "BM.Internal.Result=-1"
if !BM.Internal.Left! GTR !BM.Internal.Right! set "BM.Internal.Result=1"
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:InRange
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareInt "%~2" Value InRange
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Value=!BM.Internal.Prepared!"
call :PrepareInt "%~3" Minimum InRange
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Minimum=!BM.Internal.Prepared!"
call :PrepareInt "%~4" Maximum InRange
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Maximum=!BM.Internal.Prepared!"
call :PrepareOutput "%~5" InRange
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Output=%~5"
call :RequireRange InRange "!BM.Internal.Minimum!" "!BM.Internal.Maximum!"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Result=0"
if !BM.Internal.Value! GEQ !BM.Internal.Minimum! if !BM.Internal.Value! LEQ !BM.Internal.Maximum! set "BM.Internal.Result=1"
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:Sign
call :BeginUnary Sign "%~2" "%~3"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Result=0"
if !BM.Internal.Value! LSS 0 set "BM.Internal.Result=-1"
if !BM.Internal.Value! GTR 0 set "BM.Internal.Result=1"
call :ExportResult "!BM.Internal.Output!" "!BM.Internal.Result!"
exit /b 0

:ReadLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.ErrorField=%~2"
set "BM.Internal.ErrorOutput=%~3"
call :ValidateErrorField "!BM.Internal.ErrorField!"
if errorlevel 1 exit /b 20
call :ValidateOutputVariable "!BM.Internal.ErrorOutput!"
if errorlevel 1 exit /b 10
for %%F in ("!BM.Internal.ErrorField!") do set "BM.Internal.ErrorValue=!BM.LastError.%%~F!"
for %%O in ("!BM.Internal.ErrorOutput!") do set "%%~O=!BM.Internal.ErrorValue!"
exit /b 0

:PrintLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
echo Code: !BM.LastError.Code!
echo Kind: !BM.LastError.Kind!
echo Message: !BM.LastError.Message!
echo Operation: !BM.LastError.Operation!
echo Operand: !BM.LastError.Operand!
echo Expected: !BM.LastError.Expected!
echo Actual: !BM.LastError.Actual!
exit /b 0

:ClearLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
exit /b 0

:BeginBinary
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BM.Internal.Operation=%~1"
call :PrepareInt "%~2" Left "!BM.Internal.Operation!"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Left=!BM.Internal.Prepared!"
call :PrepareInt "%~3" Right "!BM.Internal.Operation!"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Right=!BM.Internal.Prepared!"
call :PrepareOutput "%~4" "!BM.Internal.Operation!"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Output=%~4"
exit /b 0

:BeginUnary
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BM.Internal.Operation=%~1"
call :PrepareInt "%~2" Value "!BM.Internal.Operation!"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Value=!BM.Internal.Prepared!"
call :PrepareOutput "%~3" "!BM.Internal.Operation!"
if errorlevel 1 exit /b !errorlevel!
set "BM.Internal.Output=%~3"
exit /b 0

:PrepareInt
call :NormalizeInt32 "%~1"
if errorlevel 1 (
    call :SetError 20 InvalidIntegerOperand "An operand is not a signed 32-bit integer." "%~3" "%~2" "-2147483648 through 2147483647" "%~1"
    exit /b 20
)
set "BM.Internal.Prepared=!BM.Internal.NumberNormalized!"
exit /b 0

:PrepareOutput
call :ValidateOutputVariable "%~1"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "%~2" Output "Non-reserved identifier" "%~1"
    exit /b 10
)
exit /b 0

:RequireDivisor
if "%~3"=="0" (
    call :SetError 30 DivideByZero "Division by zero is not defined." "%~1" Divisor "Non-zero signed 32-bit integer" "%~3"
    exit /b 30
)
if "%~2"=="-2147483648" if "%~3"=="-1" (
    call :SetError 30 IntegerOverflow "Division result exceeds signed 32-bit range." "%~1" Both "-2147483648 through 2147483647" "%~2 / %~3"
    exit /b 30
)
exit /b 0

:RequireRange
if %~2 GTR %~3 (
    call :SetError 20 InvalidRange "Minimum cannot be greater than maximum." "%~1" Range "Minimum less than or equal to maximum" "%~2 through %~3"
    exit /b 20
)
exit /b 0

:ExportResult
for %%O in ("%~1") do set "%%~O=%~2"
exit /b 0

:RequireInitialized
if defined BM.Initialized exit /b 0
call :SetError 50 MathNotInitialized "BatchMath has not been initialized." "" "" "initialize math" "Not initialized"
exit /b 50

:NormalizeInt32
set "BM.Internal.Number.Input=%~1"
set "BM.Internal.Number.Negative=0"
if not defined BM.Internal.Number.Input exit /b 1
if "!BM.Internal.Number.Input:~0,1!"=="-" (
    set "BM.Internal.Number.Negative=1"
    set "BM.Internal.Number.Digits=!BM.Internal.Number.Input:~1!"
) else (
    set "BM.Internal.Number.Digits=!BM.Internal.Number.Input!"
)
if not defined BM.Internal.Number.Digits exit /b 1
call :ValidateDigits "!BM.Internal.Number.Digits!"
if errorlevel 1 exit /b 1
call :StripLeadingZeroes "!BM.Internal.Number.Digits!"
set "BM.Internal.Number.Digits=!BM.Internal.StrippedDigits!"
if "!BM.Internal.Number.Negative!"=="1" (
    set "BM.Internal.Number.Limit=2147483648"
) else (
    set "BM.Internal.Number.Limit=2147483647"
)
call :CheckDecimalLimit "!BM.Internal.Number.Digits!" "!BM.Internal.Number.Limit!"
if errorlevel 1 exit /b 1
if "!BM.Internal.Number.Digits!"=="0" (
    set "BM.Internal.NumberNormalized=0"
) else (
    if "!BM.Internal.Number.Negative!"=="1" (
        set "BM.Internal.NumberNormalized=-!BM.Internal.Number.Digits!"
    ) else (
        set "BM.Internal.NumberNormalized=!BM.Internal.Number.Digits!"
    )
)
exit /b 0

:ValidateDigits
set "BM.Internal.Digits.Work=%~1"
if not defined BM.Internal.Digits.Work exit /b 1
:ValidateDigits.Next
if not defined BM.Internal.Digits.Work exit /b 0
set "BM.Internal.Digits.Character=!BM.Internal.Digits.Work:~0,1!"
call :ValidateDigitCharacter "!BM.Internal.Digits.Character!"
if errorlevel 1 exit /b 1
set "BM.Internal.Digits.Work=!BM.Internal.Digits.Work:~1!"
goto :ValidateDigits.Next

:StripLeadingZeroes
set "BM.Internal.Strip.Work=%~1"
:StripLeadingZeroes.Next
if "!BM.Internal.Strip.Work!"=="0" goto :StripLeadingZeroes.Done
if not "!BM.Internal.Strip.Work:~0,1!"=="0" goto :StripLeadingZeroes.Done
set "BM.Internal.Strip.Work=!BM.Internal.Strip.Work:~1!"
goto :StripLeadingZeroes.Next
:StripLeadingZeroes.Done
set "BM.Internal.StrippedDigits=!BM.Internal.Strip.Work!"
exit /b 0

:CheckDecimalLimit
set "BM.Internal.Limit.Value=%~1"
set "BM.Internal.Limit.Maximum=%~2"
set "BM.Internal.Limit.Work=!BM.Internal.Limit.Value!"
set "BM.Internal.Limit.Length=0"
:CheckDecimalLimit.Length
if not defined BM.Internal.Limit.Work goto :CheckDecimalLimit.LengthDone
set /a BM.Internal.Limit.Length+=1
set "BM.Internal.Limit.Work=!BM.Internal.Limit.Work:~1!"
goto :CheckDecimalLimit.Length
:CheckDecimalLimit.LengthDone
if !BM.Internal.Limit.Length! LSS 10 exit /b 0
if !BM.Internal.Limit.Length! GTR 10 exit /b 1
set "BM.Internal.Limit.Work=!BM.Internal.Limit.Value!"
set "BM.Internal.Limit.MaxWork=!BM.Internal.Limit.Maximum!"
:CheckDecimalLimit.Compare
if not defined BM.Internal.Limit.Work exit /b 0
set "BM.Internal.Limit.Digit=!BM.Internal.Limit.Work:~0,1!"
set "BM.Internal.Limit.MaxDigit=!BM.Internal.Limit.MaxWork:~0,1!"
if !BM.Internal.Limit.Digit! LSS !BM.Internal.Limit.MaxDigit! exit /b 0
if !BM.Internal.Limit.Digit! GTR !BM.Internal.Limit.MaxDigit! exit /b 1
set "BM.Internal.Limit.Work=!BM.Internal.Limit.Work:~1!"
set "BM.Internal.Limit.MaxWork=!BM.Internal.Limit.MaxWork:~1!"
goto :CheckDecimalLimit.Compare

:ValidateOutputVariable
set "BM.Internal.Output.Value=%~1"
call :ValidateId "!BM.Internal.Output.Value!"
if errorlevel 1 exit /b 1
if /i "!BM.Internal.Output.Value:~0,3!"=="BM." exit /b 1
if /i "!BM.Internal.Output.Value:~0,4!"=="BRT." exit /b 1
if /i "!BM.Internal.Output.Value:~0,3!"=="BR." exit /b 1
for %%V in (PATH ERRORLEVEL RANDOM TEMP TMP COMSPEC CD CMDEXTVERSION DATE TIME Frame ReturnObject) do if /i "!BM.Internal.Output.Value!"=="%%V" exit /b 1
exit /b 0

:ValidateId
set "BM.Internal.Id.Value=%~1"
if not defined BM.Internal.Id.Value exit /b 1
if not "!BM.Internal.Id.Value:~64,1!"=="" exit /b 1
set "BM.Internal.Id.Character=!BM.Internal.Id.Value:~0,1!"
call :ValidateAlphaCharacter "!BM.Internal.Id.Character!"
if errorlevel 1 exit /b 1
set "BM.Internal.Id.Work=!BM.Internal.Id.Value:~1!"
:ValidateId.Next
if not defined BM.Internal.Id.Work exit /b 0
set "BM.Internal.Id.Character=!BM.Internal.Id.Work:~0,1!"
call :ValidateAlphaCharacter "!BM.Internal.Id.Character!"
if not errorlevel 1 goto :ValidateId.Advance
call :ValidateDigitCharacter "!BM.Internal.Id.Character!"
if not errorlevel 1 goto :ValidateId.Advance
if "!BM.Internal.Id.Character!"=="_" goto :ValidateId.Advance
exit /b 1
:ValidateId.Advance
set "BM.Internal.Id.Work=!BM.Internal.Id.Work:~1!"
goto :ValidateId.Next

:ValidateAlphaCharacter
set "BM.Internal.Character=%~1"
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" %%A in ("!BM.Internal.Character!") do exit /b 1
exit /b 0

:ValidateDigitCharacter
set "BM.Internal.Character=%~1"
for /f "delims=0123456789" %%A in ("!BM.Internal.Character!") do exit /b 1
exit /b 0

:ValidateErrorField
for %%F in (Code Kind Message Operation Operand Expected Actual) do if /i "%~1"=="%%F" exit /b 0
exit /b 1

:ClearLastErrorInternal
set "BM.LastError.Code=0"
set "BM.LastError.Kind=None"
set "BM.LastError.Message="
set "BM.LastError.Operation="
set "BM.LastError.Operand="
set "BM.LastError.Expected="
set "BM.LastError.Actual="
exit /b 0

:SetError
set "BM.LastError.Code=%~1"
set "BM.LastError.Kind=%~2"
set "BM.LastError.Message=%~3"
set "BM.LastError.Operation=%~4"
set "BM.LastError.Operand=%~5"
set "BM.LastError.Expected=%~6"
set "BM.LastError.Actual=%~7"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
