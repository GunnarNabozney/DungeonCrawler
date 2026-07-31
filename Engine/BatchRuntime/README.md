# BatchRuntime 1.1

BatchRuntime is a project-agnostic function, object, validation, and safe-text runtime for Windows batch files.

It uses only Windows `cmd.exe` behavior and standard Windows commands. The public command language is deliberately written as readable instructions. The compact colon-prefixed commands remain available as the stable module ABI and for backward compatibility.

## Requirements

Callers enable command extensions and delayed expansion:

```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
```

## Run the complete validation

Double-click:

```text
RunTests.bat
```

The suite covers readable commands, module dependencies, strong schemas, named parameters, defaults, signed 32-bit integers, Booleans, enums, typed objects, cloning, nested success and failure propagation, maximum depth, frame-owned temporary cleanup, mathematical floor division, file-backed arbitrary text, introspection, and leak counters.

## Readable command language

Initialize and shut down:

```bat
call "!Runtime!" initialize runtime
call "!Runtime!" shutdown runtime
```

Import a module:

```bat
call "!Runtime!" import module Math from "!MathModule!"
```

Run a function:

```bat
call "!Runtime!" run Math Add into Result with Left 17 and Right 25
call "!Runtime!" run Math FloorDivide into Result with Dividend -3 and Divisor 2
```

Readable calls support up to eight named parameters. Boolean values are written explicitly:

```bat
call "!Runtime!" run Display Configure into Result with Bright true
```

Read, check, clone, show, and release objects:

```bat
call "!Runtime!" read field Sum from object "!Result!" into Sum
call "!Runtime!" check field Sum in object "!Result!" into HasSum
call "!Runtime!" clone object "!Result!" into Copy
call "!Runtime!" show object "!Result!"
call "!Runtime!" release object "!Result!"
```

Errors:

```bat
call "!Runtime!" show last error
call "!Runtime!" clear last error
```

Introspection:

```bat
call "!Runtime!" show modules
call "!Runtime!" show functions in module Math
call "!Runtime!" show schema for Math Add
call "!Runtime!" show runtime
call "!Runtime!" get statistic ObjectCount into ObjectCount
```

Call depth:

```bat
call "!Runtime!" set maximum call depth to 32
```

## Safe arbitrary text

Arbitrary text is represented by file-backed handles. Its bytes are never expanded as batch commands.

```bat
call "!Runtime!" load text from "C:\Input\message.txt" into Message
call "!Runtime!" save text "!Message!" to "C:\Output\message.txt"
call "!Runtime!" compare text "!Message!" with "!OtherMessage!" into Same
call "!Runtime!" show text "!Message!"
call "!Runtime!" release text "!Message!"
```

Text contents may contain percent signs, exclamation marks, pipes, command separators, redirects, carets, parentheses, quotes, empty lines, and multiple lines. File paths still need to be valid command-line paths.

## Module protocol

Modules use the compact protocol ABI:

```text
__BRT__ MANIFEST
__BRT__ DESCRIBE FunctionName
__BRT__ INVOKE FunctionName FrameHandle ReturnObjectHandle
```

Every function enters local scope before capturing its invocation handles:

```bat
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
```

Bind schema parameters:

```bat
call "!BRT.Runtime!" :BindParameters "!Frame!"
```

Forward runtime failures before leaving local scope:

```bat
if errorlevel 1 (
    call "!BRT.Runtime!" :ReturnError
    exit /b !errorlevel!
)
```

`:ReturnError` closes the module function's `setlocal`, preserves the innermost structured error on the active frame, and returns the original runtime exit code.

Export return fields on the `endlocal` line:

```bat
endlocal & set "BRT.O.%ReturnObject%.Value=%Value%"
```

## Manifest dependencies

Dependencies are aliases that must already be imported:

```bat
set "BRT.X.Manifest.Dependency.Count=1"
set "BRT.X.Manifest.Dependency.1=Math"
```

The runtime validates dependency names, duplicates, and presence before committing an import.

## Schema contract

Parameter properties:

```text
Name
Type
Required
Position
HasDefault
Default       when HasDefault is true
Choices       only for Enum
ObjectType    only for Object
```

Return properties:

```text
Name
Type
Required
Choices       only for Enum
ObjectType    only for Object
```

The runtime rejects unknown properties, duplicate parameter names, duplicate positions, duplicate return names, invalid defaults, empty or duplicate enum choices, reserved parameter names, and invalid object type identifiers.

## Types

- `Int`: normalized signed 32-bit decimal integer, `-2147483648` through `2147483647`
- `UInt`: normalized non-negative decimal integer, `0` through `2147483647`
- `Bool`: normalized to `0` or `1`
- `Id`: a letter followed by letters, digits, or underscores
- `Enum`: one identifier-safe value from a comma-delimited schema list
- `Object`: a live object handle, optionally restricted by dotted object type

## Frames and object ownership

Invocation state is stored on the frame. Objects created during a frame belong to that frame unless ownership is transferred.

- Successful return objects transfer to the parent frame.
- Top-level return objects transfer to the caller.
- Temporary nested objects are automatically released with their owning frame.
- Handles are monotonic and are not reused during a runtime session.
- Explicit release remains recommended for caller-owned objects.

## Output variable safety

Output variables must be identifiers and may not use runtime or command-environment names such as `BRT...`, `Frame`, `ReturnObject`, `PATH`, `ERRORLEVEL`, `RANDOM`, `TEMP`, or `COMSPEC`.

## Nested failure propagation

When a nested call fails, the module forwards the error with `:ReturnError`. The outer invocation reconstructs the innermost structured error and propagates its exit-code family instead of replacing it with a generic module error.

## Exit-code families

- `0`: success
- `10`: readable or invocation syntax
- `20`: parameter validation
- `30`: module or function failure
- `40`: return-object validation
- `50`: runtime, object, frame, text, or depth failure
- `60`: module protocol, dependency, or schema failure
- `61`: delayed expansion is not enabled
- `64` / `65`: module protocol rejection

## Legacy compatibility

The previous commands remain valid:

```bat
call "!Runtime!" :Initialize
call "!Runtime!" :Import Math "!MathModule!"
call "!Runtime!" :Invoke Math Add Result --Left 17 --Right 25
call "!Runtime!" :Object.Get "!Result!" Sum Sum
call "!Runtime!" :Object.Release "!Result!"
```

New game and engine code should prefer the readable command language.
