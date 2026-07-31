# BatchRandom 1.0

BatchRandom is a deterministic, project-agnostic random-number component for Windows batch files.

It uses the Park–Miller minimal-standard generator with Schrage arithmetic. The implementation does not use `%RANDOM%`, wall-clock time, process IDs, or another implicit entropy source. A saved generator state therefore resumes the same sequence on another compatible Windows `cmd.exe` session.

Public commands are readable instructions. Colon-prefixed commands form the compact engine ABI.

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
call "Engine\BatchRandom\RunTests.bat" --no-pause
```

The suite covers lifecycle behavior, published generator vectors, state restoration, unbiased rejection sampling, signed ranges, chances, dice, weighted choice, Fisher–Yates index shuffling, validation failures, deterministic distribution counts, and the BatchRuntime adapter.

## Deterministic state

Initialize with an explicit seed:

```bat
call "!Random!" initialize random with seed 12345
```

Valid seeds are `1` through `2147483646`.

Repeated initialization is idempotent and preserves the existing sequence. Use `reseed` when a new sequence is intended:

```bat
call "!Random!" reseed random with seed 9001
```

Read or restore the complete resumable state:

```bat
call "!Random!" read random state into SavedState and count into SavedDrawCount
call "!Random!" restore random with state "!SavedState!" and draw count "!SavedDrawCount!"
```

`State` determines the next generated value. `DrawCount` records the number of raw generator values consumed, including values discarded by rejection sampling.

## Raw values

Generate the next raw Park–Miller value:

```bat
call "!Random!" next random into RawValue
```

Raw values are between `1` and `2147483646`.

Seed `1` begins with these published regression values:

```text
16807
282475249
1622650073
984943658
1144108930
```

## Inclusive integer ranges

Generate an unbiased signed integer in an inclusive range:

```bat
call "!Random!" random integer from -5 to 5 into Offset
call "!Random!" random integer from 1 to 20 into Roll
```

Range mapping uses rejection sampling rather than a direct modulo reduction. Supported inclusive ranges contain at most `2147483646` distinct values.

## Percentage chances

```bat
call "!Random!" random chance 25 percent into DidTrigger
```

The result is normalized to `0` or `1`. Percentages range from `0` through `100`. Every chance call consumes random state, including the `0` and `100` edge cases.

## Dice

```bat
call "!Random!" roll 3 dice with 6 sides into Total
```

Dice count ranges from `1` through `1000`. Side count ranges from `1` through `2147483646`. BatchRandom rejects a dice expression before drawing when its maximum possible total would exceed signed 32-bit range.

## Choice helpers

Choose an unweighted one-based index:

```bat
call "!Random!" choose random index from 8 into ChoiceIndex
```

Choose a weighted one-based index:

```bat
call "!Random!" choose weighted index from "1,3,6" into ChoiceIndex
```

Weights are comma-separated positive unsigned integers. A list may contain up to 64 entries, and its total may not exceed `2147483646`.

## Index shuffling

Create a Fisher–Yates permutation of `1` through a requested count:

```bat
call "!Random!" shuffle 5 indices into Order
```

The result is a comma-separated index list such as:

```text
4,3,5,1,2
```

Shuffle count ranges from `1` through `256`. The component shuffles indices rather than arbitrary text so expansion-sensitive game data remains outside the command parser. Callers can apply the returned order to registry entries, objects, or later BatchText handles.

## Statistics and errors

```bat
call "!Random!" get statistic State into CurrentState
call "!Random!" get statistic DrawCount into DrawCount

call "!Random!" show last error
call "!Random!" read last error Kind into ErrorKind
call "!Random!" clear last error
```

Structured error fields:

```text
Code
Kind
Message
Operation
Parameter
Expected
Actual
```

Exit-code families:

- `0`: success
- `10`: readable syntax or unsafe output variable
- `20`: invalid seed, range, percentage, count, state, or weight data
- `30`: an operation could exceed signed 32-bit result range
- `50`: lifecycle failure
- `61`: delayed expansion is not enabled

## Compact ABI

```bat
call "!Random!" :Initialize 12345
call "!Random!" :Reseed 9001
call "!Random!" :Next RawValue
call "!Random!" :Integer -5 5 Offset
call "!Random!" :Chance 25 DidTrigger
call "!Random!" :Roll 3 6 Total
call "!Random!" :ChooseIndex 8 ChoiceIndex
call "!Random!" :WeightedIndex "1,3,6" ChoiceIndex
call "!Random!" :ShuffleIndices 5 Order
call "!Random!" :GetState SavedState SavedDrawCount
call "!Random!" :Restore "!SavedState!" "!SavedDrawCount!"
call "!Random!" :Shutdown
```

## BatchRuntime adapter

`Engine\BatchRuntime\Modules\Random.bat` is a thin Runtime-facing adapter. It contains schemas and state/error translation but no generator arithmetic.

The adapter exports:

```text
Initialize
Reseed
Next
Integer
Chance
Roll
ChooseIndex
GetState
Restore
```

Weighted lists and comma-separated shuffle output are intentionally direct-component operations because BatchRuntime protocol 1 does not expose an arbitrary scalar-string schema type. The canonical implementation remains `Engine\BatchRandom\BatchRandom.bat`.
