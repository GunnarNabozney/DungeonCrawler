# BatchRegistry 1.0

BatchRegistry is a project-agnostic typed state registry for Windows batch files. State is held in the caller environment and remains available across component calls until a registry is released or the component is shut down.

It uses only `cmd.exe` behavior and standard Windows commands. Public commands are readable instructions; compact colon-prefixed commands form the stable ABI.

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
call "Engine\BatchRegistry\RunTests.bat" --no-pause
```

The suite covers lifecycle, registry ownership, dotted keys, all value types, integer boundaries, Boolean normalization, stable entry counts, type immutability, reads, existence checks, removal, clearing, listing, structured errors, reserved outputs, and owner-based cleanup.

## Readable commands

Initialize and shut down:

```bat
call "!Registry!" initialize registry
call "!Registry!" shutdown registry
```

Create registries with explicit owners:

```bat
call "!Registry!" create registry Session owned by Game
call "!Registry!" create registry ScreenState owned by InventoryScreen
```

Set typed values. Setting a missing key creates it; setting an existing key updates it. An existing key cannot change type unless it is removed first.

```bat
call "!Registry!" set Int key Player.Health in registry Session to 42
call "!Registry!" set UInt key Player.Gold in registry Session to 150
call "!Registry!" set Bool key Player.Alive in registry Session to true
call "!Registry!" set Id key Player.Class in registry Session to RuneKnight
call "!Registry!" set String key Player.Title in registry Session to "Keeper of Keys"
```

Read values and types:

```bat
call "!Registry!" read key Player.Health from registry Session into Health
call "!Registry!" read type Player.Health from registry Session into HealthType
```

Check, remove, and clear:

```bat
call "!Registry!" check key Player.Health in registry Session into HasHealth
call "!Registry!" remove key Player.Health from registry Session
call "!Registry!" clear registry Session
```

Release one registry or every registry owned by a subsystem:

```bat
call "!Registry!" release registry Session
call "!Registry!" release registries owned by InventoryScreen
```

Inspect state:

```bat
call "!Registry!" show registries
call "!Registry!" show keys in registry Session
call "!Registry!" get statistic RegistryCount into RegistryCount
call "!Registry!" get statistic EntryCount for registry Session into EntryCount
```

Inspect errors:

```bat
call "!Registry!" show last error
call "!Registry!" read last error Kind into ErrorKind
call "!Registry!" clear last error
```

## Names and keys

Registry names and owners are identifiers: a letter followed by letters, digits, or underscores. They are limited to 64 characters.

Keys are case-insensitive dotted identifiers such as:

```text
Player.Health
World.CurrentRoom
Inventory.Slots.Primary
```

Each segment follows identifier rules. Keys cannot begin or end with a dot, contain consecutive dots, or exceed 128 characters.

Registry names and keys use Windows environment-variable semantics and are therefore case-insensitive. Their original spelling is retained for listing.

## Types

- `String`: command-line-safe single-line text
- `Int`: normalized signed decimal integer from `-2147483648` through `2147483647`
- `UInt`: normalized non-negative decimal integer from `0` through `2147483647`
- `Bool`: `1`, `0`, `true`, `false`, `yes`, `no`, `on`, or `off`, normalized to `1` or `0`
- `Id`: a letter followed by letters, digits, or underscores

`String` is intended for normal command-safe scalar text. Arbitrary multiline text and data containing expansion-sensitive exclamation marks belong in the later BatchText component and should be referenced by handles.

## Ownership

Every registry has an owner identifier. Ownership gives screens, modules, sessions, and other subsystems a deterministic cleanup seam:

```bat
call "!Registry!" release registries owned by InventoryScreen
```

Registry and entry sequence numbers are monotonic during a component session. Removed entries and released registries are not reused, so enumeration remains stable.

## Structured errors

The latest error is available through these fields:

```text
Code
Kind
Message
Registry
Key
Type
Expected
Actual
```

Exit-code families:

- `0`: success
- `10`: readable syntax or unsafe output variable
- `20`: invalid name, key, type, or value
- `30`: missing or conflicting registry state
- `50`: lifecycle failure
- `61`: delayed expansion is not enabled

Successful public operations clear the previous error before performing their work. Error inspection commands do not clear it.

## Compact ABI

The compact commands remain available for engine integration:

```bat
call "!Registry!" :Initialize
call "!Registry!" :Create Session Game
call "!Registry!" :Set Session Player.Health Int 42
call "!Registry!" :Get Session Player.Health Health
call "!Registry!" :GetType Session Player.Health HealthType
call "!Registry!" :Has Session Player.Health HasHealth
call "!Registry!" :Remove Session Player.Health
call "!Registry!" :Clear Session
call "!Registry!" :Release Session
call "!Registry!" :ReleaseOwner Game
call "!Registry!" :Shutdown
```
