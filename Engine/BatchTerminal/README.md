# BatchTerminal 1.0

BatchTerminal centralizes console dimensions, cursor state, color, clearing, diff-based buffered redraws, keyboard events, mouse events, resize events, and capability detection for DungeonCrawler.

## Architecture

- `BatchTerminal.psm1` is the long-lived terminal API. Import it once in the process that owns the interactive screen loop.
- `../ConsoleNative.cs` is the approved, narrowly scoped Windows console interop seam. It owns raw input mode and `ReadConsoleInputW` event decoding.
- `BatchTerminal.bat` is a small command-line adapter for capability checks, dimensions, simple terminal operations, one-event diagnostics, and the deterministic self-test.

The native helper is source-only and is compiled in memory by Windows PowerShell through `Add-Type`. No executable is installed and no external runtime is introduced.

## Why raw input is native

Practical pure-batch approaches were evaluated:

- `set /p` is line-buffered and cannot report key-up, modifiers, mouse movement, button transitions, wheel events, or resize events.
- `choice` reads only a predefined character set and cannot provide arbitrary keys or mouse data.
- `pause` reports no key identity.
- `mode con` exposes dimensions but not input events, and parsing its localized output is unreliable.
- ANSI cursor, color, and clear sequences are useful only when virtual-terminal output is enabled. They do not give `cmd.exe` a reliable raw input stream.
- XTerm-style mouse reporting can emit escape sequences in some terminals, but `cmd.exe` has no dependable unbuffered byte reader for continuously decoding those sequences without another runtime.

Therefore cursor movement, color, clearing, and redraw buffering remain managed code using standard console APIs, while raw keyboard and mouse events reuse the approved `ConsoleNative.cs` seam. This preserves smooth mouse hover and click interaction without creating a second interop layer.

## Public module API

### Initialization and capabilities

- `Initialize-BatchTerminal [-EnableVirtualTerminal]`
- `Get-BatchTerminalCapabilities`
- `Get-BatchTerminalSize`

Capability results report console attachment, keyboard, mouse, resize, cursor, color, buffered redraw, virtual-terminal state, current dimensions, the native input strategy, and any detection failure.

### Output

- `Set-BatchTerminalCursor -X <int> -Y <int> [-Visible <bool>]`
- `Set-BatchTerminalColor [-Foreground <ConsoleColor>] [-Background <ConsoleColor>]`
- `Clear-BatchTerminal`
- `Clear-BatchTerminalRegion -X <int> -Y <int> -Width <int> [-Height <int>]`
- `Write-BatchTerminalText -X <int> -Y <int> -Text <string>`
- `Begin-BatchTerminalRedraw`
- `Complete-BatchTerminalRedraw`
- `Invoke-BatchTerminalRedraw { ... }`

Buffered redraws retain a cell cache and emit only changed contiguous runs with matching foreground and background colors. The cursor is hidden during the flush and restored afterward to reduce flicker.

Writes are clipped to the current visible console canvas. Multiline strings are rejected so every write has deterministic row semantics.

### Input

- `Start-BatchTerminalInput [-EnableMouse <bool>]`
- `Read-BatchTerminalInput [-TimeoutMilliseconds <uint32>]`
- `Read-BatchTerminalKey [-TimeoutMilliseconds <uint32>]`
- `Stop-BatchTerminalInput`

Normalized input events use `Kind` values `None`, `Key`, `Mouse`, `Resize`, or `Other`. Mouse events include coordinates, button state, left/right/middle convenience flags, event flags, wheel delta, and modifier state.

Always stop an active input session in `finally` so the original console input mode is restored.

## Batch adapter

```bat
Engine\BatchTerminal\BatchTerminal.bat capabilities
Engine\BatchTerminal\BatchTerminal.bat size
Engine\BatchTerminal\BatchTerminal.bat clear
Engine\BatchTerminal\BatchTerminal.bat cursor 10 5
Engine\BatchTerminal\BatchTerminal.bat color Yellow DarkBlue
Engine\BatchTerminal\BatchTerminal.bat input-once 2000
Engine\BatchTerminal\BatchTerminal.bat self-test
```

The one-event adapter is diagnostic. Smooth interactive loops should import the module once, start one input session, and reuse it until the screen exits.

## Error behavior

Unsupported or unavailable operations throw errors prefixed with `BatchTerminal [Kind]`. Capability detection itself does not throw for redirected handles; it reports the missing capability and a failure description. Operations that require an unavailable capability fail explicitly rather than silently degrading mouse behavior.

## Validation

`RunTests.bat` compiles the approved native seam, checks capability shape and compatibility methods, validates deterministic diff buffering, verifies clipping and nested redraws, checks cursor and multiline validation, and normalizes synthetic keyboard, mouse, resize, and timeout events. It does not require human input.