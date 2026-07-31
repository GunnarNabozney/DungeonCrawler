# BatchRuntime Version 1

BatchRuntime is a project-agnostic function and module runtime for Windows batch files.
It provides:

- Imported modules with explicit public exports
- Schema-driven named and positional parameters
- Parameter types and default values
- Function-local parameter binding
- Handle-based return objects
- Typed object parameters
- Structured error objects
- Nested function calls
- Runtime introspection and leak counters

It does not use PowerShell or any third-party executable.

## Requirements

- Windows `cmd.exe`
- Command extensions enabled
- Delayed expansion enabled in the caller

Start each caller with:

```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
```

Version 1 intentionally supports values that are safe under delayed expansion. Arbitrary text,
multiline strings, exclamation marks, and untrusted user input are deferred to a later text-handle
system.

## Run the self-test

Double-click:

```text
RunTests.bat
```

Or run the non-pausing test directly:

```bat
call Tests\BatchRuntime.Tests.bat
```

The suite exercises module import, manifests, schemas, named parameters, positional parameters,
defaults, signed integers, Booleans, enums, return objects, object parameters, nested calls,
structured failures, return validation, and leak detection.

## Basic use

```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Runtime=%~dp0BatchRuntime.bat"
set "MathModule=%~dp0Modules\Math.bat"

call "!Runtime!" :Initialize
if errorlevel 1 goto :Error

call "!Runtime!" :Import Math "!MathModule!"
if errorlevel 1 goto :Error

call "!Runtime!" :Invoke Math Add Result --Left 17 --Right 25
if errorlevel 1 goto :Error

call "!Runtime!" :Object.Get "!Result!" Sum Sum
if errorlevel 1 goto :Error

echo Result: !Sum!

call "!Runtime!" :Object.Release "!Result!"
exit /b 0

:Error
call "!Runtime!" :PrintLastError
exit /b 1
```

## Runtime commands

### Initialize

```bat
call "!Runtime!" :Initialize
```

Initialization is idempotent within the current `setlocal` environment.

### Import a module

```bat
call "!Runtime!" :Import Math "C:\Path\To\Math.bat"
```

The alias must be a batch-safe identifier. Modules expose a protocol manifest and an explicit
export list. Private labels cannot be invoked through the runtime.

### Invoke a function

Named parameters:

```bat
call "!Runtime!" :Invoke Math Add Result --Left 17 --Right 25
```

Positional parameters:

```bat
call "!Runtime!" :Invoke Math Add Result 17 25
```

Boolean switches may be bare:

```bat
call "!Runtime!" :Invoke Display Configure Result --Bright
```

The third invocation argument is the variable that receives the return-object handle.

### Read a return field

```bat
call "!Runtime!" :Object.Get "!Result!" Sum Sum
```

### Check for a field

```bat
call "!Runtime!" :Object.Has "!Result!" Sum HasSum
```

### Describe an object

```bat
call "!Runtime!" :Object.Describe "!Result!"
```

### Release an object

```bat
call "!Runtime!" :Object.Release "!Result!"
```

Return objects are explicit resources. Release them when no longer needed.

### Inspect errors

A nonzero `ERRORLEVEL` is authoritative. Detailed information is stored in `BRT.LastError`.

```bat
call "!Runtime!" :PrintLastError
```

Programmatic access:

```bat
call "!Runtime!" :Object.Get "!BRT.LastError!" Kind ErrorKind
call "!Runtime!" :Object.Get "!BRT.LastError!" Message ErrorMessage
```

Clear the error when finished:

```bat
call "!Runtime!" :ClearLastError
```

### Introspection

```bat
call "!Runtime!" :ListModules
call "!Runtime!" :Describe Math Add
call "!Runtime!" :RuntimeInfo
call "!Runtime!" :GetStat ObjectCount ObjectCount
call "!Runtime!" :GetStat FrameCount FrameCount
```

## Module protocol

A module accepts only these runtime operations:

```text
__BRT__ MANIFEST
__BRT__ DESCRIBE FunctionName
__BRT__ INVOKE FunctionName FrameHandle ReturnObjectHandle
```

Every function invocation should enter its own local scope:

```bat
setlocal EnableExtensions EnableDelayedExpansion
```

Capture `Frame` and `ReturnObject` only after entering that local scope. This prevents a nested invocation of the same module from overwriting the outer function's handles.
Parameters are then bound as local variables:

```bat
call "!BRT.Runtime!" :BindParameters "!Frame!"
```

A module writes only fields declared by its return schema. Because the function runs inside
`setlocal`, return fields are exported on the `endlocal` line:

```bat
endlocal & set "BRT.O.%ReturnObject%.Sum=%Sum%"
```

See `Templates\ModuleTemplate.bat` and `Modules\Math.bat`.

## Version 1 types

- `Int` - signed decimal integer syntax suitable for `set /a`
- `UInt` - non-negative decimal integer syntax
- `Bool` - normalized to `0` or `1`
- `Id` - begins with a letter; then letters, digits, or underscores
- `Enum` - one value from a comma-delimited list of identifier-safe choices
- `Object` - a live BatchRuntime object handle, optionally restricted by object type

Optional parameters without defaults are bound to `@NULL`.

## Exit-code families

- `0` - success
- `10` - invocation syntax
- `20` - parameter validation
- `30` - module or function failure
- `40` - return-object validation
- `50` - runtime state or object failure
- `60` - module protocol or schema failure
- `61` - delayed expansion is not enabled
- `64` / `65` - module protocol rejection

## Reserved namespace

All variables beginning with `BRT.` belong to the runtime. Project code should not use that
prefix except when implementing the documented module return protocol.

## Version 1 limitations

- Arbitrary user text is not safe yet.
- Values containing `!`, `%`, command separators, or line breaks are not supported.
- Integer syntax is validated, but arithmetic range remains the native `set /a` range.
- Module dependencies are imported manually.
- Asynchronous work, parallel calls, callbacks, and persistent objects are not implemented.
- A module must obey the function `setlocal` convention for nested-call isolation.

These constraints are intentional. The first version proves the calling convention and object
model before a dedicated safe-text layer is added.
