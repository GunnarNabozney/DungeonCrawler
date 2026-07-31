# BatchMath 1.0

BatchMath is the project-agnostic signed 32-bit arithmetic component for the batch engine. The standalone implementation lives in `Engine/BatchMath/BatchMath.bat`; `Engine/BatchRuntime/Modules/Math.bat` is a thin BatchRuntime adapter.

It uses only `cmd.exe` behavior and standard Windows commands. Public commands are readable instructions, and compact colon-prefixed commands form the stable component ABI.

## Requirements

Callers enable command extensions and delayed expansion:

```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
```

Repository `.bat` files are checked out with CRLF line endings through the root `.gitattributes` rule.

## Validation

Double-click `RunTests.bat`, or run:

```bat
call "Engine\BatchMath\RunTests.bat" --no-pause
```

The suite covers lifecycle, integer normalization, every arithmetic operation, signed 32-bit boundaries, overflow rejection, divide-by-zero rejection, truncating and floor division semantics, range helpers, structured errors, output-variable safety, compact ABI calls, and the BatchRuntime adapter.

## Lifecycle

```bat
call "!Math!" initialize math
call "!Math!" shutdown math
```

The component is stateless apart from version and structured-error fields, but explicit lifecycle keeps it consistent with the other engine components.

## Arithmetic

```bat
call "!Math!" add 17 and 25 into Sum
call "!Math!" subtract 50 minus 8 into Difference
call "!Math!" multiply 6 by 7 into Product
call "!Math!" divide -7 by 3 into Quotient
call "!Math!" modulo -7 by 3 into Remainder
```

`divide` truncates toward zero, matching `cmd.exe` integer division. `modulo` returns the corresponding truncating remainder, whose sign follows the dividend.

## Mathematical floor operations

```bat
call "!Math!" floor divide -7 by 3 into Quotient
call "!Math!" floor modulo -7 by 3 into Remainder
```

Floor division rounds toward negative infinity. Floor modulo returns the remainder associated with that quotient, so a nonzero remainder has the divisor's sign.

Examples:

```text
-7 floor-divided by 3  = -3
-7 floor-modulo 3      = 2
 7 floor-divided by -3 = -3
 7 floor-modulo -3     = -2
```

## Selection and range helpers

```bat
call "!Math!" absolute -42 into Magnitude
call "!Math!" minimum 12 and 30 into Smaller
call "!Math!" maximum 12 and 30 into Larger
call "!Math!" clamp 150 between 0 and 100 into Clamped
call "!Math!" compare 12 with 30 into Comparison
call "!Math!" check 42 between 0 and 100 into IsInRange
call "!Math!" sign -42 into Sign
```

`compare` returns `-1`, `0`, or `1`. `check` uses inclusive bounds. `sign` returns `-1`, `0`, or `1`.

## Signed 32-bit contract

Every input is normalized as a decimal signed integer in this range:

```text
-2147483648 through 2147483647
```

Leading zeroes are accepted and removed before arithmetic, avoiding `set /a` octal interpretation. Results that cannot be represented are rejected instead of being returned as wrapped values.

Explicit arithmetic failures include:

- addition, subtraction, or multiplication overflow
- `-2147483648 / -1`
- `absolute -2147483648`
- division or modulo by zero
- inverted ranges where minimum exceeds maximum

## Structured errors

The latest error exposes these fields:

```text
Code
Kind
Message
Operation
Operand
Expected
Actual
```

Inspect or clear it with:

```bat
call "!Math!" show last error
call "!Math!" read last error Kind into ErrorKind
call "!Math!" clear last error
```

Exit-code families:

- `0`: success
- `10`: readable syntax or unsafe output variable
- `20`: invalid integer or range
- `30`: arithmetic failure such as overflow or divide by zero
- `50`: lifecycle failure
- `61`: delayed expansion is not enabled

## Compact ABI

```bat
call "!Math!" :Initialize
call "!Math!" :Add 17 25 Sum
call "!Math!" :Subtract 50 8 Difference
call "!Math!" :Multiply 6 7 Product
call "!Math!" :Divide -7 3 Quotient
call "!Math!" :Modulo -7 3 Remainder
call "!Math!" :FloorDivide -7 3 Quotient
call "!Math!" :FloorModulo -7 3 Remainder
call "!Math!" :Absolute -42 Magnitude
call "!Math!" :Minimum 12 30 Smaller
call "!Math!" :Maximum 12 30 Larger
call "!Math!" :Clamp 150 0 100 Clamped
call "!Math!" :Compare 12 30 Comparison
call "!Math!" :InRange 42 0 100 IsInRange
call "!Math!" :Sign -42 Sign
call "!Math!" :Shutdown
```

## BatchRuntime adapter

`Engine/BatchRuntime/Modules/Math.bat` preserves the existing `Math` import name and the original `Add`, `Clamp`, and `FloorDivide` contracts. It also exposes the remaining BatchMath operations through Runtime schemas and return objects.

The adapter contains no canonical arithmetic. It binds Runtime parameters, calls the standalone component, maps results into Runtime return objects, and propagates structured BatchMath failures back through the invocation frame.
