@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Math=%~dp0..\BatchMath.bat"
set "BatchTest=%~dp0..\..\BatchRuntime\BatchTest.bat"
set "Runtime=%~dp0..\..\BatchRuntime\BatchRuntime.bat"
set "MathModule=%~dp0..\..\BatchRuntime\Modules\Math.bat"

call "!BatchTest!" begin suite "BatchMath 1.0 human-readable self-test"

call "!Math!" initialize math
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchMath"
if defined BT.Abort goto :Summary

call "!Math!" add 17 and 25 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add signed integers"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Addition returns 42"

call "!Math!" add 00017 and 00025 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Normalize leading zeroes"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Normalized addition remains decimal"

call "!Math!" add 2147483647 and 0 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 2147483647 because "Accept the maximum signed integer"

set "Actual=unchanged"
call "!Math!" add 2147483647 and 1 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject positive addition overflow"
call "!BatchTest!" expect value "!Actual!" to equal unchanged because "Overflow does not publish a wrapped result"
call "!Math!" read last error Kind into ErrorKind
call "!BatchTest!" expect value "!ErrorKind!" to equal IntegerOverflow because "Report addition overflow"

call "!Math!" add -2147483648 and -1 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject negative addition overflow"

call "!Math!" subtract 50 minus 8 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Subtract signed integers"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Subtraction returns 42"

call "!Math!" subtract 2147483647 minus -1 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject positive subtraction overflow"

call "!Math!" subtract -2147483648 minus 1 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject negative subtraction overflow"

call "!Math!" multiply 6 by 7 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Multiply signed integers"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Multiplication returns 42"

call "!Math!" multiply -6 by 7 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -42 because "Multiplication preserves sign"

call "!Math!" multiply 2147483647 by 0 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Multiplication by zero succeeds"

call "!Math!" multiply 50000 by 50000 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject multiplication overflow"
call "!Math!" read last error Kind into ErrorKind
call "!BatchTest!" expect value "!ErrorKind!" to equal IntegerOverflow because "Report multiplication overflow"

call "!Math!" multiply -2147483648 by -1 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject minimum integer negation by multiplication"

call "!Math!" divide 7 by 3 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Divide signed integers"
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Integer division truncates positive fractions"

call "!Math!" divide -7 by 3 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -2 because "Integer division truncates toward zero"

call "!Math!" divide 7 by -3 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -2 because "Truncating division handles a negative divisor"

call "!Math!" divide 1 by 0 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject division by zero"
call "!Math!" read last error Kind into ErrorKind
call "!BatchTest!" expect value "!ErrorKind!" to equal DivideByZero because "Report division by zero"

call "!Math!" divide -2147483648 by -1 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject overflowing division"

call "!Math!" modulo -7 by 3 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Calculate truncating remainder"
call "!BatchTest!" expect value "!Actual!" to equal -1 because "Truncating remainder follows the dividend sign"

call "!Math!" modulo 7 by -3 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Truncating remainder supports a negative divisor"

call "!Math!" modulo 1 by 0 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject modulo by zero"

call "!Math!" floor divide -7 by 3 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Calculate mathematical floor division"
call "!BatchTest!" expect value "!Actual!" to equal -3 because "Floor division rounds negative fractions downward"

call "!Math!" floor divide 7 by -3 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -3 because "Floor division handles a negative divisor"

call "!Math!" floor divide -7 by -3 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Floor division preserves positive quotients"

call "!Math!" floor modulo -7 by 3 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Calculate mathematical floor remainder"
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Floor remainder follows a positive divisor"

call "!Math!" floor modulo 7 by -3 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -2 because "Floor remainder follows a negative divisor"

call "!Math!" floor modulo -2147483648 by 2147483647 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 2147483646 because "Floor remainder avoids intermediate multiplication overflow"

call "!Math!" absolute -42 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Calculate absolute value"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Absolute value removes a negative sign"

call "!Math!" absolute -2147483648 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject the unrepresentable absolute minimum"

call "!Math!" minimum 42 and -7 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -7 because "Return the minimum value"

call "!Math!" maximum 42 and -7 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Return the maximum value"

call "!Math!" clamp 150 between 0 and 100 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Clamp a value above the range"
call "!BatchTest!" expect value "!Actual!" to equal 100 because "Clamp uses the maximum bound"

call "!Math!" clamp -10 between 0 and 100 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Clamp uses the minimum bound"

call "!Math!" clamp 42 between 0 and 100 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Clamp preserves an in-range value"

call "!Math!" clamp 42 between 100 and 0 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an inverted clamp range"
call "!Math!" read last error Kind into ErrorKind
call "!BatchTest!" expect value "!ErrorKind!" to equal InvalidRange because "Report an invalid clamp range"

call "!Math!" compare -1 with 0 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -1 because "Comparison reports less than"

call "!Math!" compare 42 with 42 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Comparison reports equality"

call "!Math!" compare 1 with 0 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Comparison reports greater than"

call "!Math!" check 42 between 0 and 100 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Check an inclusive range"
call "!BatchTest!" expect value "!Actual!" to equal 1 because "In-range values return true"

call "!Math!" check 0 between 0 and 100 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "The minimum endpoint is included"

call "!Math!" check 101 between 0 and 100 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Out-of-range values return false"

call "!Math!" check 42 between 100 and 0 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an inverted range check"

call "!Math!" sign -42 into Actual
call "!BatchTest!" expect value "!Actual!" to equal -1 because "Sign reports a negative value"

call "!Math!" sign 0 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Sign reports zero"

call "!Math!" sign 42 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Sign reports a positive value"

call "!Math!" :Add 20 22 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Use the compact addition ABI"
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Compact addition returns 42"

call "!Math!" add 2147483648 and 0 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an integer above signed range"

call "!Math!" add -2147483649 and 0 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an integer below signed range"

call "!Math!" add 1 and 2 into PATH
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 10 because "Reject a reserved output variable"

call "!Math!" shutdown math
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shut down BatchMath"

call "!Math!" add 1 and 2 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 50 because "Reject operations after shutdown"

call "!Runtime!" initialize runtime
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchRuntime for adapter tests"
if defined BT.Abort goto :Summary

call "!Runtime!" import module Math from "!MathModule!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Import the BatchMath runtime adapter"
if defined BT.Abort goto :Summary

call "!Runtime!" run Math Add into RuntimeResult with Left 17 and Right 25
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Run adapter addition"
call "!Runtime!" read field Sum from object "!RuntimeResult!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "Adapter addition returns 42"
call "!Runtime!" release object "!RuntimeResult!"

call "!Runtime!" run Math Clamp into RuntimeResult with Value 150
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Preserve adapter clamp defaults"
call "!Runtime!" read field Value from object "!RuntimeResult!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 100 because "Adapter clamp returns the default maximum"
call "!Runtime!" read field WasClamped from object "!RuntimeResult!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Adapter clamp reports a changed value"
call "!Runtime!" release object "!RuntimeResult!"

call "!Runtime!" run Math FloorModulo into RuntimeResult with Dividend -7 and Divisor 3
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Run floor modulo through the adapter"
call "!Runtime!" read field Remainder from object "!RuntimeResult!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Adapter floor modulo returns mathematical remainder"
call "!Runtime!" release object "!RuntimeResult!"

call "!Runtime!" run Math Multiply into ShouldNotExist with Left 50000 and Right 50000
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Propagate adapter arithmetic failure"
call "!Runtime!" read field Kind from object "!BRT.LastError!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal IntegerOverflow because "Preserve the BatchMath error kind"
call "!Runtime!" clear last error

call "!Runtime!" get statistic ObjectCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Adapter tests do not leak objects"

set "Actual=0"
if defined BM.Initialized set "Actual=1"
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Adapter initialization remains module-local"

call "!Runtime!" shutdown runtime
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shut down BatchRuntime after adapter tests"

:Summary
call "!BatchTest!" finish suite
exit /b !errorlevel!
