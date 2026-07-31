Set-StrictMode -Version Latest

$script:TerminalInitialized = $false
$script:TerminalCapabilities = $null
$script:TerminalWidth = 0
$script:TerminalHeight = 0
$script:CellCount = 0
$script:RedrawDepth = 0
$script:PendingCharacters = $null
$script:PendingForeground = $null
$script:PendingBackground = $null
$script:PendingSet = $null
$script:RenderedCharacters = $null
$script:RenderedForeground = $null
$script:RenderedBackground = $null
$script:RenderedKnown = $null
$script:DirtyStart = $null
$script:DirtyEnd = $null
$script:InputHandle = [IntPtr]::Zero
$script:InputSessionActive = $false
$script:InputMouseEnabled = $false
$script:TestMode = $false
$script:RunWriter = $null

function New-BatchTerminalError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Kind,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Exception = New-Object `
        -TypeName System.InvalidOperationException `
        -ArgumentList "BatchTerminal [$Kind]: $Message"

    return $Exception
}

function Assert-BatchTerminalInitialized {
    [CmdletBinding()]
    param()

    if (-not $script:TerminalInitialized) {
        throw (New-BatchTerminalError `
            -Kind 'NotInitialized' `
            -Message 'Call Initialize-BatchTerminal first.')
    }
}

function Import-BatchTerminalNative {
    [CmdletBinding()]
    param()

    $NativeType = 'DungeonConsoleNative' -as [type]

    if ($null -eq $NativeType) {
        $NativeSourcePath = Join-Path `
            (Split-Path -Parent $PSScriptRoot) `
            'ConsoleNative.cs'

        if (-not (Test-Path -LiteralPath $NativeSourcePath -PathType Leaf)) {
            throw (New-BatchTerminalError `
                -Kind 'NativeHelperMissing' `
                -Message "Required native helper is missing: $NativeSourcePath")
        }

        Add-Type `
            -Path $NativeSourcePath `
            -ErrorAction Stop

        $NativeType = 'DungeonConsoleNative' -as [type]
    }

    if ($null -eq $NativeType) {
        throw (New-BatchTerminalError `
            -Kind 'NativeHelperUnavailable' `
            -Message 'DungeonConsoleNative could not be loaded.')
    }

    $RequiredMethods = @(
        'DetectCapabilities'
        'TryEnableVirtualTerminalOutput'
        'BeginInputSession'
        'BeginMouseSession'
        'ReadInputEvent'
        'ReadMouseEvent'
        'EndInputSession'
        'EndMouseSession'
    )

    foreach ($RequiredMethod in $RequiredMethods) {
        if ($null -eq $NativeType.GetMethod($RequiredMethod)) {
            throw (New-BatchTerminalError `
                -Kind 'NativeHelperIncompatible' `
                -Message "DungeonConsoleNative is missing method: $RequiredMethod")
        }
    }
}

function New-BatchTerminalBuffers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1000)]
        [int]$Width,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1000)]
        [int]$Height
    )

    $script:TerminalWidth = $Width
    $script:TerminalHeight = $Height
    $script:CellCount = $Width * $Height

    $script:PendingCharacters =
        [char[]]::new($script:CellCount)

    $script:PendingForeground =
        [int[]]::new($script:CellCount)

    $script:PendingBackground =
        [int[]]::new($script:CellCount)

    $script:PendingSet =
        [bool[]]::new($script:CellCount)

    $script:RenderedCharacters =
        [char[]]::new($script:CellCount)

    $script:RenderedForeground =
        [int[]]::new($script:CellCount)

    $script:RenderedBackground =
        [int[]]::new($script:CellCount)

    $script:RenderedKnown =
        [bool[]]::new($script:CellCount)

    $script:DirtyStart =
        [int[]]::new($Height)

    $script:DirtyEnd =
        [int[]]::new($Height)

    Reset-BatchTerminalPending
    Reset-BatchTerminalRenderCache
}

function Reset-BatchTerminalPending {
    [CmdletBinding()]
    param()

    if ($null -eq $script:PendingSet) {
        return
    }

    [Array]::Clear(
        $script:PendingSet,
        0,
        $script:PendingSet.Length
    )

    for ($Y = 0; $Y -lt $script:TerminalHeight; $Y++) {
        $script:DirtyStart[$Y] = $script:TerminalWidth
        $script:DirtyEnd[$Y] = -1
    }
}

function Reset-BatchTerminalRenderCache {
    [CmdletBinding()]
    param()

    if ($null -eq $script:RenderedKnown) {
        return
    }

    [Array]::Clear(
        $script:RenderedKnown,
        0,
        $script:RenderedKnown.Length
    )
}

function Get-CurrentBatchTerminalSize {
    [CmdletBinding()]
    param()

    Assert-BatchTerminalInitialized

    if (-not $script:TerminalCapabilities.HasOutputConsole) {
        return [pscustomobject][ordered]@{
            Width = 0
            Height = 0
            BufferWidth = 0
            BufferHeight = 0
        }
    }

    $Width = [Math]::Min(
        [Console]::WindowWidth,
        [Console]::BufferWidth
    )

    $Height = [Math]::Min(
        [Console]::WindowHeight,
        [Console]::BufferHeight
    )

    if ($Width -lt 1 -or $Height -lt 1) {
        throw (New-BatchTerminalError `
            -Kind 'InvalidDimensions' `
            -Message "Console reported ${Width}x${Height}.")
    }

    if (
        $Width -ne $script:TerminalWidth -or
        $Height -ne $script:TerminalHeight
    ) {
        New-BatchTerminalBuffers `
            -Width $Width `
            -Height $Height
    }

    return [pscustomobject][ordered]@{
        Width = $Width
        Height = $Height
        BufferWidth = [Console]::BufferWidth
        BufferHeight = [Console]::BufferHeight
    }
}

function Initialize-BatchTerminal {
    [CmdletBinding()]
    param(
        [switch]$EnableVirtualTerminal
    )

    Import-BatchTerminalNative

    if ($EnableVirtualTerminal) {
        [void][DungeonConsoleNative]::TryEnableVirtualTerminalOutput()
    }

    $script:TerminalCapabilities =
        [DungeonConsoleNative]::DetectCapabilities()

    $script:TerminalInitialized = $true

    if ($script:TerminalCapabilities.HasOutputConsole) {
        [void](Get-CurrentBatchTerminalSize)
    }

    if ($null -eq $script:RunWriter) {
        $script:RunWriter = {
            param(
                [int]$X,
                [int]$Y,
                [string]$Text,
                [ConsoleColor]$Foreground,
                [ConsoleColor]$Background
            )

            [Console]::SetCursorPosition($X, $Y)
            [Console]::ForegroundColor = $Foreground
            [Console]::BackgroundColor = $Background
            [Console]::Write($Text)
        }
    }

    $Capabilities = Get-BatchTerminalCapabilities
    return $Capabilities
}

function Get-BatchTerminalCapabilities {
    [CmdletBinding()]
    param()

    Assert-BatchTerminalInitialized

    return [pscustomobject][ordered]@{
        IsWindows = [bool]$script:TerminalCapabilities.IsWindows
        HasInputConsole = [bool]$script:TerminalCapabilities.HasInputConsole
        HasOutputConsole = [bool]$script:TerminalCapabilities.HasOutputConsole
        SupportsKeyboard = [bool]$script:TerminalCapabilities.SupportsKeyboard
        SupportsMouse = [bool]$script:TerminalCapabilities.SupportsMouse
        SupportsWindowEvents = [bool]$script:TerminalCapabilities.SupportsWindowEvents
        SupportsCursor = [bool]$script:TerminalCapabilities.SupportsCursor
        SupportsColor = [bool]$script:TerminalCapabilities.SupportsColor
        SupportsBufferedRedraw = [bool]$script:TerminalCapabilities.SupportsBufferedRedraw
        VirtualTerminalOutputEnabled = [bool]$script:TerminalCapabilities.VirtualTerminalOutputEnabled
        Width = [int]$script:TerminalCapabilities.Width
        Height = [int]$script:TerminalCapabilities.Height
        Failure = [string]$script:TerminalCapabilities.Failure
        NativeInput = 'ReadConsoleInputW'
        PureBatchMouse = $false
    }
}

function Get-BatchTerminalSize {
    [CmdletBinding()]
    param()

    $Size = Get-CurrentBatchTerminalSize
    return $Size
}

function Set-BatchTerminalCursor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [bool]$Visible = $true
    )

    Assert-BatchTerminalInitialized

    if (-not $script:TestMode) {
        if (-not $script:TerminalCapabilities.SupportsCursor) {
            throw (New-BatchTerminalError `
                -Kind 'CursorUnavailable' `
                -Message 'Standard output is not attached to a console.')
        }

        [void](Get-CurrentBatchTerminalSize)
    }

    if (
        $X -lt 0 -or
        $Y -lt 0 -or
        $X -ge $script:TerminalWidth -or
        $Y -ge $script:TerminalHeight
    ) {
        throw (New-BatchTerminalError `
            -Kind 'CursorOutOfRange' `
            -Message "Cursor ${X},${Y} is outside ${script:TerminalWidth}x${script:TerminalHeight}.")
    }

    if (-not $script:TestMode) {
        [Console]::SetCursorPosition($X, $Y)
        [Console]::CursorVisible = $Visible
    }
}

function Set-BatchTerminalColor {
    [CmdletBinding()]
    param(
        [ConsoleColor]$Foreground = [ConsoleColor]::Gray,
        [ConsoleColor]$Background = [ConsoleColor]::Black
    )

    Assert-BatchTerminalInitialized

    if (-not $script:TestMode) {
        if (-not $script:TerminalCapabilities.SupportsColor) {
            throw (New-BatchTerminalError `
                -Kind 'ColorUnavailable' `
                -Message 'Standard output is not attached to a console.')
        }

        [Console]::ForegroundColor = $Foreground
        [Console]::BackgroundColor = $Background
    }
}

function Set-BatchTerminalRenderCacheText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [ConsoleColor]$Foreground,

        [Parameter(Mandatory = $true)]
        [ConsoleColor]$Background
    )

    for ($Index = 0; $Index -lt $Text.Length; $Index++) {
        $CellX = $X + $Index
        $CellIndex = ($Y * $script:TerminalWidth) + $CellX
        $script:RenderedCharacters[$CellIndex] = $Text[$Index]
        $script:RenderedForeground[$CellIndex] = [int]$Foreground
        $script:RenderedBackground[$CellIndex] = [int]$Background
        $script:RenderedKnown[$CellIndex] = $true
    }
}

function Invoke-BatchTerminalRunWriter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [ConsoleColor]$Foreground,

        [Parameter(Mandatory = $true)]
        [ConsoleColor]$Background
    )

    if ($Text.Length -eq 0) {
        return
    }

    & $script:RunWriter `
        $X `
        $Y `
        $Text `
        $Foreground `
        $Background
}

function Flush-BatchTerminalRedraw {
    [CmdletBinding()]
    param()

    $OriginalCursorVisible = $false
    $OriginalCursorLeft = 0
    $OriginalCursorTop = 0
    $OriginalForeground = [ConsoleColor]::Gray
    $OriginalBackground = [ConsoleColor]::Black
    $RestoreConsoleState = $false

    if (-not $script:TestMode) {
        if (-not $script:TerminalCapabilities.HasOutputConsole) {
            throw (New-BatchTerminalError `
                -Kind 'OutputUnavailable' `
                -Message 'Buffered redraw requires an attached console output.')
        }

        $OriginalCursorVisible = [Console]::CursorVisible
        $OriginalCursorLeft = [Console]::CursorLeft
        $OriginalCursorTop = [Console]::CursorTop
        $OriginalForeground = [Console]::ForegroundColor
        $OriginalBackground = [Console]::BackgroundColor
        [Console]::CursorVisible = $false
        $RestoreConsoleState = $true
    }

    try {
        for ($Y = 0; $Y -lt $script:TerminalHeight; $Y++) {
            $StartX = $script:DirtyStart[$Y]
            $EndX = $script:DirtyEnd[$Y]

            if ($EndX -lt $StartX) {
                continue
            }

            $RunX = -1
            $RunText = ''
            $RunForeground = [ConsoleColor]::Gray
            $RunBackground = [ConsoleColor]::Black

            for ($X = $StartX; $X -le $EndX; $X++) {
                $CellIndex = ($Y * $script:TerminalWidth) + $X

                if (-not $script:PendingSet[$CellIndex]) {
                    if ($RunText.Length -gt 0) {
                        Invoke-BatchTerminalRunWriter `
                            -X $RunX `
                            -Y $Y `
                            -Text $RunText `
                            -Foreground $RunForeground `
                            -Background $RunBackground

                        $RunText = ''
                    }

                    continue
                }

                $Character = $script:PendingCharacters[$CellIndex]
                $Foreground = [ConsoleColor]$script:PendingForeground[$CellIndex]
                $Background = [ConsoleColor]$script:PendingBackground[$CellIndex]

                $Changed = (
                    -not $script:RenderedKnown[$CellIndex] -or
                    $script:RenderedCharacters[$CellIndex] -cne $Character -or
                    $script:RenderedForeground[$CellIndex] -ne [int]$Foreground -or
                    $script:RenderedBackground[$CellIndex] -ne [int]$Background
                )

                $script:RenderedCharacters[$CellIndex] = $Character
                $script:RenderedForeground[$CellIndex] = [int]$Foreground
                $script:RenderedBackground[$CellIndex] = [int]$Background
                $script:RenderedKnown[$CellIndex] = $true

                if (-not $Changed) {
                    if ($RunText.Length -gt 0) {
                        Invoke-BatchTerminalRunWriter `
                            -X $RunX `
                            -Y $Y `
                            -Text $RunText `
                            -Foreground $RunForeground `
                            -Background $RunBackground

                        $RunText = ''
                    }

                    continue
                }

                $CanAppend = (
                    $RunText.Length -gt 0 -and
                    $X -eq ($RunX + $RunText.Length) -and
                    [int]$Foreground -eq [int]$RunForeground -and
                    [int]$Background -eq [int]$RunBackground
                )

                if (-not $CanAppend) {
                    if ($RunText.Length -gt 0) {
                        Invoke-BatchTerminalRunWriter `
                            -X $RunX `
                            -Y $Y `
                            -Text $RunText `
                            -Foreground $RunForeground `
                            -Background $RunBackground
                    }

                    $RunX = $X
                    $RunText = [string]$Character
                    $RunForeground = $Foreground
                    $RunBackground = $Background
                }
                else {
                    $RunText += [string]$Character
                }
            }

            if ($RunText.Length -gt 0) {
                Invoke-BatchTerminalRunWriter `
                    -X $RunX `
                    -Y $Y `
                    -Text $RunText `
                    -Foreground $RunForeground `
                    -Background $RunBackground
            }
        }
    }
    finally {
        Reset-BatchTerminalPending

        if ($RestoreConsoleState) {
            [Console]::ForegroundColor = $OriginalForeground
            [Console]::BackgroundColor = $OriginalBackground

            if (
                $OriginalCursorLeft -ge 0 -and
                $OriginalCursorTop -ge 0 -and
                $OriginalCursorLeft -lt [Console]::BufferWidth -and
                $OriginalCursorTop -lt [Console]::BufferHeight
            ) {
                [Console]::SetCursorPosition(
                    $OriginalCursorLeft,
                    $OriginalCursorTop
                )
            }

            [Console]::CursorVisible = $OriginalCursorVisible
        }
    }
}

function Begin-BatchTerminalRedraw {
    [CmdletBinding()]
    param()

    Assert-BatchTerminalInitialized

    if (-not $script:TestMode) {
        [void](Get-CurrentBatchTerminalSize)
    }

    if ($script:RedrawDepth -eq 0) {
        Reset-BatchTerminalPending
    }

    $script:RedrawDepth++
}

function Complete-BatchTerminalRedraw {
    [CmdletBinding()]
    param()

    Assert-BatchTerminalInitialized

    if ($script:RedrawDepth -le 0) {
        throw (New-BatchTerminalError `
            -Kind 'RedrawNotActive' `
            -Message 'Begin-BatchTerminalRedraw was not called.')
    }

    $script:RedrawDepth--

    if ($script:RedrawDepth -eq 0) {
        Flush-BatchTerminalRedraw
    }
}

function Invoke-BatchTerminalRedraw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Render
    )

    $RootRedraw = $script:RedrawDepth -eq 0
    Begin-BatchTerminalRedraw

    try {
        & $Render
    }
    catch {
        $script:RedrawDepth--

        if ($RootRedraw) {
            Reset-BatchTerminalPending
        }

        throw
    }

    Complete-BatchTerminalRedraw
}

function Write-BatchTerminalText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [ConsoleColor]$Foreground = [ConsoleColor]::Gray,
        [ConsoleColor]$Background = [ConsoleColor]::Black
    )

    Assert-BatchTerminalInitialized

    if ($Text.IndexOf("`r") -ge 0 -or $Text.IndexOf("`n") -ge 0) {
        throw (New-BatchTerminalError `
            -Kind 'MultilineWriteUnsupported' `
            -Message 'Write one terminal row at a time.')
    }

    if (-not $script:TestMode) {
        if (-not $script:TerminalCapabilities.HasOutputConsole) {
            throw (New-BatchTerminalError `
                -Kind 'OutputUnavailable' `
                -Message 'Standard output is not attached to a console.')
        }

        [void](Get-CurrentBatchTerminalSize)
    }

    if ($Y -lt 0 -or $Y -ge $script:TerminalHeight) {
        return
    }

    if ($Text.Length -eq 0) {
        return
    }

    $VisibleText = $Text
    $VisibleX = $X

    if ($VisibleX -lt 0) {
        $Skip = -$VisibleX

        if ($Skip -ge $VisibleText.Length) {
            return
        }

        $VisibleText = $VisibleText.Substring($Skip)
        $VisibleX = 0
    }

    if ($VisibleX -ge $script:TerminalWidth) {
        return
    }

    $AvailableWidth = $script:TerminalWidth - $VisibleX

    if ($VisibleText.Length -gt $AvailableWidth) {
        $VisibleText = $VisibleText.Substring(0, $AvailableWidth)
    }

    if ($script:RedrawDepth -gt 0) {
        for ($Index = 0; $Index -lt $VisibleText.Length; $Index++) {
            $CellX = $VisibleX + $Index
            $CellIndex = ($Y * $script:TerminalWidth) + $CellX
            $script:PendingCharacters[$CellIndex] = $VisibleText[$Index]
            $script:PendingForeground[$CellIndex] = [int]$Foreground
            $script:PendingBackground[$CellIndex] = [int]$Background
            $script:PendingSet[$CellIndex] = $true

            if ($CellX -lt $script:DirtyStart[$Y]) {
                $script:DirtyStart[$Y] = $CellX
            }

            if ($CellX -gt $script:DirtyEnd[$Y]) {
                $script:DirtyEnd[$Y] = $CellX
            }
        }

        return
    }

    Invoke-BatchTerminalRunWriter `
        -X $VisibleX `
        -Y $Y `
        -Text $VisibleText `
        -Foreground $Foreground `
        -Background $Background

    Set-BatchTerminalRenderCacheText `
        -X $VisibleX `
        -Y $Y `
        -Text $VisibleText `
        -Foreground $Foreground `
        -Background $Background
}

function Clear-BatchTerminalRegion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1000)]
        [int]$Width,

        [ValidateRange(1, 1000)]
        [int]$Height = 1,

        [ConsoleColor]$Foreground = [ConsoleColor]::Gray,
        [ConsoleColor]$Background = [ConsoleColor]::Black
    )

    Invoke-BatchTerminalRedraw {
        for ($Row = 0; $Row -lt $Height; $Row++) {
            Write-BatchTerminalText `
                -X $X `
                -Y ($Y + $Row) `
                -Text (' ' * $Width) `
                -Foreground $Foreground `
                -Background $Background
        }
    }
}

function Clear-BatchTerminal {
    [CmdletBinding()]
    param(
        [ConsoleColor]$Foreground = [ConsoleColor]::Gray,
        [ConsoleColor]$Background = [ConsoleColor]::Black
    )

    Assert-BatchTerminalInitialized

    if (-not $script:TerminalCapabilities.HasOutputConsole) {
        throw (New-BatchTerminalError `
            -Kind 'OutputUnavailable' `
            -Message 'Standard output is not attached to a console.')
    }

    Set-BatchTerminalColor `
        -Foreground $Foreground `
        -Background $Background

    [Console]::Clear()
    [void](Get-CurrentBatchTerminalSize)
    Reset-BatchTerminalPending
    Reset-BatchTerminalRenderCache
}

function ConvertFrom-BatchTerminalNativeSample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Sample
    )

    $Kind = 'None'

    if ($Sample.HasEvent) {
        if ($Sample.IsKeyEvent) {
            $Kind = 'Key'
        }
        elseif ($Sample.IsMouseEvent) {
            $Kind = 'Mouse'
        }
        elseif ($Sample.IsResizeEvent) {
            $Kind = 'Resize'
        }
        else {
            $Kind = 'Other'
        }
    }

    return [pscustomobject][ordered]@{
        HasEvent = [bool]$Sample.HasEvent
        Kind = $Kind
        KeyDown = [bool]$Sample.KeyDown
        KeyChar = [char]$Sample.KeyChar
        VirtualKeyCode = [int]$Sample.VirtualKeyCode
        VirtualScanCode = [int]$Sample.VirtualScanCode
        RepeatCount = [int]$Sample.RepeatCount
        X = [int]$Sample.X
        Y = [int]$Sample.Y
        ButtonState = [uint32]$Sample.ButtonState
        EventFlags = [uint32]$Sample.EventFlags
        MouseWheelDelta = [int]$Sample.MouseWheelDelta
        Width = [int]$Sample.Width
        Height = [int]$Sample.Height
        ControlKeyState = [uint32]$Sample.ControlKeyState
        LeftButtonDown = (([uint32]$Sample.ButtonState -band 0x0001) -ne 0)
        RightButtonDown = (([uint32]$Sample.ButtonState -band 0x0002) -ne 0)
        MiddleButtonDown = (([uint32]$Sample.ButtonState -band 0x0004) -ne 0)
    }
}

function Start-BatchTerminalInput {
    [CmdletBinding()]
    param(
        [bool]$EnableMouse = $true
    )

    Assert-BatchTerminalInitialized

    if ($script:InputSessionActive) {
        if ($EnableMouse -and -not $script:InputMouseEnabled) {
            throw (New-BatchTerminalError `
                -Kind 'InputSessionModeMismatch' `
                -Message 'The active input session was started without mouse events.')
        }

        return $script:InputHandle
    }

    if (-not $script:TerminalCapabilities.HasInputConsole) {
        throw (New-BatchTerminalError `
            -Kind 'InputUnavailable' `
            -Message 'Standard input is not attached to a console.')
    }

    if ($EnableMouse -and -not $script:TerminalCapabilities.SupportsMouse) {
        throw (New-BatchTerminalError `
            -Kind 'MouseUnavailable' `
            -Message 'Raw console mouse events are unavailable.')
    }

    $script:InputHandle =
        [DungeonConsoleNative]::BeginInputSession($EnableMouse)

    $script:InputSessionActive = $true
    $script:InputMouseEnabled = $EnableMouse
    return $script:InputHandle
}

function Read-BatchTerminalInput {
    [CmdletBinding()]
    param(
        [ValidateRange(0, 60000)]
        [uint32]$TimeoutMilliseconds = 0
    )

    Assert-BatchTerminalInitialized

    if (-not $script:InputSessionActive) {
        throw (New-BatchTerminalError `
            -Kind 'InputSessionNotActive' `
            -Message 'Call Start-BatchTerminalInput first.')
    }

    $Sample = [DungeonConsoleNative]::ReadInputEvent(
        $script:InputHandle,
        $TimeoutMilliseconds
    )

    if ($Sample.IsResizeEvent) {
        $script:TerminalCapabilities =
            [DungeonConsoleNative]::DetectCapabilities()

        if ($script:TerminalCapabilities.HasOutputConsole) {
            [void](Get-CurrentBatchTerminalSize)
        }
    }

    $NormalizedSample = ConvertFrom-BatchTerminalNativeSample `
        -Sample $Sample

    return $NormalizedSample
}

function Read-BatchTerminalKey {
    [CmdletBinding()]
    param(
        [ValidateRange(0, 60000)]
        [uint32]$TimeoutMilliseconds = 0
    )

    Assert-BatchTerminalInitialized

    $StartedHere = -not $script:InputSessionActive

    if ($StartedHere) {
        [void](Start-BatchTerminalInput -EnableMouse $false)
    }

    try {
        $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
        $Remaining = $TimeoutMilliseconds

        while ($true) {
            $Sample = Read-BatchTerminalInput `
                -TimeoutMilliseconds $Remaining

            if (-not $Sample.HasEvent) {
                return $Sample
            }

            if ($Sample.Kind -eq 'Key') {
                return $Sample
            }

            if ($TimeoutMilliseconds -eq 0) {
                return [pscustomobject][ordered]@{
                    HasEvent = $false
                    Kind = 'None'
                    KeyDown = $false
                    KeyChar = [char]0
                    VirtualKeyCode = 0
                    VirtualScanCode = 0
                    RepeatCount = 0
                    X = 0
                    Y = 0
                    ButtonState = [uint32]0
                    EventFlags = [uint32]0
                    MouseWheelDelta = 0
                    Width = 0
                    Height = 0
                    ControlKeyState = [uint32]0
                    LeftButtonDown = $false
                    RightButtonDown = $false
                    MiddleButtonDown = $false
                }
            }

            $Elapsed = [int]$Stopwatch.ElapsedMilliseconds

            if ($Elapsed -ge $TimeoutMilliseconds) {
                return [pscustomobject][ordered]@{
                    HasEvent = $false
                    Kind = 'None'
                    KeyDown = $false
                    KeyChar = [char]0
                    VirtualKeyCode = 0
                    VirtualScanCode = 0
                    RepeatCount = 0
                    X = 0
                    Y = 0
                    ButtonState = [uint32]0
                    EventFlags = [uint32]0
                    MouseWheelDelta = 0
                    Width = 0
                    Height = 0
                    ControlKeyState = [uint32]0
                    LeftButtonDown = $false
                    RightButtonDown = $false
                    MiddleButtonDown = $false
                }
            }

            $Remaining = [uint32]($TimeoutMilliseconds - $Elapsed)
        }
    }
    finally {
        if ($StartedHere) {
            Stop-BatchTerminalInput
        }
    }
}

function Stop-BatchTerminalInput {
    [CmdletBinding()]
    param()

    if (-not $script:InputSessionActive) {
        return
    }

    try {
        [DungeonConsoleNative]::EndInputSession(
            $script:InputHandle
        )
    }
    finally {
        $script:InputHandle = [IntPtr]::Zero
        $script:InputSessionActive = $false
        $script:InputMouseEnabled = $false
    }
}

function Invoke-BatchTerminalSelfTest {
    [CmdletBinding()]
    param()

    $Results = New-Object 'System.Collections.Generic.List[object]'
    $Passed = 0
    $Failed = 0

    function Add-SelfTestResult {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,

            [Parameter(Mandatory = $true)]
            [bool]$Condition,

            [AllowEmptyString()]
            [string]$Detail = ''
        )

        if ($Condition) {
            $script:SelfTestPassed++
            $Status = 'PASS'
        }
        else {
            $script:SelfTestFailed++
            $Status = 'FAIL'
        }

        $script:SelfTestResults.Add(
            [pscustomobject][ordered]@{
                Status = $Status
                Name = $Name
                Detail = $Detail
            }
        )
    }

    $script:SelfTestResults = $Results
    $script:SelfTestPassed = $Passed
    $script:SelfTestFailed = $Failed

    $SavedState = [ordered]@{
        Width = $script:TerminalWidth
        Height = $script:TerminalHeight
        CellCount = $script:CellCount
        RedrawDepth = $script:RedrawDepth
        PendingCharacters = $script:PendingCharacters
        PendingForeground = $script:PendingForeground
        PendingBackground = $script:PendingBackground
        PendingSet = $script:PendingSet
        RenderedCharacters = $script:RenderedCharacters
        RenderedForeground = $script:RenderedForeground
        RenderedBackground = $script:RenderedBackground
        RenderedKnown = $script:RenderedKnown
        DirtyStart = $script:DirtyStart
        DirtyEnd = $script:DirtyEnd
        TestMode = $script:TestMode
        RunWriter = $script:RunWriter
        Initialized = $script:TerminalInitialized
        Capabilities = $script:TerminalCapabilities
    }

    try {
        $Capabilities = Initialize-BatchTerminal

        Add-SelfTestResult `
            -Name 'Load the approved native console seam' `
            -Condition ($null -ne ('DungeonConsoleNative' -as [type]))

        Add-SelfTestResult `
            -Name 'Expose capability detection' `
            -Condition ($null -ne $Capabilities.PSObject.Properties['SupportsMouse'])

        Add-SelfTestResult `
            -Name 'Report the native input strategy' `
            -Condition ($Capabilities.NativeInput -eq 'ReadConsoleInputW')

        Add-SelfTestResult `
            -Name 'Do not claim reliable pure-batch mouse input' `
            -Condition (-not $Capabilities.PureBatchMouse)

        $NativeType = 'DungeonConsoleNative' -as [type]

        foreach ($MethodName in @(
            'BeginMouseSession'
            'ReadMouseEvent'
            'EndMouseSession'
            'BeginInputSession'
            'ReadInputEvent'
            'EndInputSession'
        )) {
            Add-SelfTestResult `
                -Name "Expose native method $MethodName" `
                -Condition ($null -ne $NativeType.GetMethod($MethodName))
        }

        if (
            $Capabilities.HasInputConsole -and
            -not $script:InputSessionActive
        ) {
            $InputStarted = $false

            try {
                [void](Start-BatchTerminalInput -EnableMouse $true)
                $InputStarted = $true

                Add-SelfTestResult `
                    -Name 'Start the raw keyboard and mouse session' `
                    -Condition $true

                $PolledEvent = Read-BatchTerminalInput `
                    -TimeoutMilliseconds 0

                Add-SelfTestResult `
                    -Name 'Poll raw input without blocking' `
                    -Condition (
                        $null -ne $PolledEvent.PSObject.Properties['Kind']
                    )
            }
            catch {
                Add-SelfTestResult `
                    -Name 'Start the raw keyboard and mouse session' `
                    -Condition $false `
                    -Detail $_.Exception.Message
            }
            finally {
                if ($InputStarted) {
                    Stop-BatchTerminalInput
                }
            }

            Add-SelfTestResult `
                -Name 'Restore the console input mode after polling' `
                -Condition (-not $script:InputSessionActive)
        }
        elseif ($script:InputSessionActive) {
            Add-SelfTestResult `
                -Name 'Preserve an existing input session during self-test' `
                -Condition $true
        }
        else {
            Add-SelfTestResult `
                -Name 'Report redirected input without crashing' `
                -Condition (
                    -not [string]::IsNullOrWhiteSpace($Capabilities.Failure)
                )
        }

        $Writes = New-Object 'System.Collections.Generic.List[object]'
        $script:TestMode = $true
        $script:RunWriter = {
            param(
                [int]$X,
                [int]$Y,
                [string]$Text,
                [ConsoleColor]$Foreground,
                [ConsoleColor]$Background
            )

            $Writes.Add(
                [pscustomobject][ordered]@{
                    X = $X
                    Y = $Y
                    Text = $Text
                    Foreground = $Foreground
                    Background = $Background
                }
            )
        }

        New-BatchTerminalBuffers -Width 8 -Height 3

        Invoke-BatchTerminalRedraw {
            Write-BatchTerminalText `
                -X 1 `
                -Y 1 `
                -Text 'ABC' `
                -Foreground Yellow `
                -Background Black
        }

        Add-SelfTestResult `
            -Name 'Flush one contiguous buffered run' `
            -Condition ($Writes.Count -eq 1)

        Add-SelfTestResult `
            -Name 'Preserve buffered run coordinates' `
            -Condition (
                $Writes[0].X -eq 1 -and
                $Writes[0].Y -eq 1
            )

        Add-SelfTestResult `
            -Name 'Preserve buffered run colors' `
            -Condition (
                $Writes[0].Foreground -eq [ConsoleColor]::Yellow -and
                $Writes[0].Background -eq [ConsoleColor]::Black
            )

        $Writes.Clear()

        Invoke-BatchTerminalRedraw {
            Write-BatchTerminalText `
                -X 1 `
                -Y 1 `
                -Text 'ABC' `
                -Foreground Yellow `
                -Background Black
        }

        Add-SelfTestResult `
            -Name 'Skip unchanged cells on redraw' `
            -Condition ($Writes.Count -eq 0)

        Invoke-BatchTerminalRedraw {
            Write-BatchTerminalText `
                -X 1 `
                -Y 1 `
                -Text 'AXC' `
                -Foreground Yellow `
                -Background Black
        }

        Add-SelfTestResult `
            -Name 'Emit only the changed cell' `
            -Condition (
                $Writes.Count -eq 1 -and
                $Writes[0].X -eq 2 -and
                $Writes[0].Text -eq 'X'
            )

        $Writes.Clear()

        Invoke-BatchTerminalRedraw {
            Invoke-BatchTerminalRedraw {
                Write-BatchTerminalText `
                    -X -2 `
                    -Y 0 `
                    -Text 'HELLO' `
                    -Foreground Cyan `
                    -Background DarkBlue
            }
        }

        Add-SelfTestResult `
            -Name 'Support nested redraw transactions' `
            -Condition ($script:RedrawDepth -eq 0)

        Add-SelfTestResult `
            -Name 'Clip text at the left terminal edge' `
            -Condition (
                $Writes.Count -eq 1 -and
                $Writes[0].X -eq 0 -and
                $Writes[0].Text -eq 'LLO'
            )

        $Writes.Clear()

        Clear-BatchTerminalRegion `
            -X 6 `
            -Y 2 `
            -Width 5 `
            -Height 1

        Add-SelfTestResult `
            -Name 'Clip cleared regions at the right edge' `
            -Condition (
                $Writes.Count -eq 1 -and
                $Writes[0].Text.Length -eq 2
            )

        $MultilineRejected = $false

        try {
            Write-BatchTerminalText `
                -X 0 `
                -Y 0 `
                -Text "A`nB"
        }
        catch {
            $MultilineRejected =
                $_.Exception.Message -like '*MultilineWriteUnsupported*'
        }

        Add-SelfTestResult `
            -Name 'Reject multiline writes explicitly' `
            -Condition $MultilineRejected

        $CursorRejected = $false

        try {
            Set-BatchTerminalCursor -X 8 -Y 0
        }
        catch {
            $CursorRejected =
                $_.Exception.Message -like '*CursorOutOfRange*'
        }

        Add-SelfTestResult `
            -Name 'Reject cursor positions outside the canvas' `
            -Condition $CursorRejected

        $KeySample = [pscustomobject]@{
            HasEvent = $true
            IsKeyEvent = $true
            IsMouseEvent = $false
            IsResizeEvent = $false
            KeyDown = $true
            KeyChar = [char]'K'
            VirtualKeyCode = 75
            VirtualScanCode = 37
            RepeatCount = 2
            X = 0
            Y = 0
            ButtonState = [uint32]0
            EventFlags = [uint32]0
            MouseWheelDelta = 0
            Width = 0
            Height = 0
            ControlKeyState = [uint32]0
        }

        $KeyEvent = ConvertFrom-BatchTerminalNativeSample `
            -Sample $KeySample

        Add-SelfTestResult `
            -Name 'Normalize keyboard events' `
            -Condition (
                $KeyEvent.Kind -eq 'Key' -and
                $KeyEvent.KeyDown -and
                $KeyEvent.KeyChar -eq [char]'K' -and
                $KeyEvent.RepeatCount -eq 2
            )

        $MouseSample = [pscustomobject]@{
            HasEvent = $true
            IsKeyEvent = $false
            IsMouseEvent = $true
            IsResizeEvent = $false
            KeyDown = $false
            KeyChar = [char]0
            VirtualKeyCode = 0
            VirtualScanCode = 0
            RepeatCount = 0
            X = 4
            Y = 2
            ButtonState = [uint32]3
            EventFlags = [uint32]1
            MouseWheelDelta = 0
            Width = 0
            Height = 0
            ControlKeyState = [uint32]0
        }

        $MouseEvent = ConvertFrom-BatchTerminalNativeSample `
            -Sample $MouseSample

        Add-SelfTestResult `
            -Name 'Normalize mouse coordinates and buttons' `
            -Condition (
                $MouseEvent.Kind -eq 'Mouse' -and
                $MouseEvent.X -eq 4 -and
                $MouseEvent.Y -eq 2 -and
                $MouseEvent.LeftButtonDown -and
                $MouseEvent.RightButtonDown
            )

        $ResizeSample = [pscustomobject]@{
            HasEvent = $true
            IsKeyEvent = $false
            IsMouseEvent = $false
            IsResizeEvent = $true
            KeyDown = $false
            KeyChar = [char]0
            VirtualKeyCode = 0
            VirtualScanCode = 0
            RepeatCount = 0
            X = 0
            Y = 0
            ButtonState = [uint32]0
            EventFlags = [uint32]0
            MouseWheelDelta = 0
            Width = 120
            Height = 40
            ControlKeyState = [uint32]0
        }

        $ResizeEvent = ConvertFrom-BatchTerminalNativeSample `
            -Sample $ResizeSample

        Add-SelfTestResult `
            -Name 'Normalize resize events' `
            -Condition (
                $ResizeEvent.Kind -eq 'Resize' -and
                $ResizeEvent.Width -eq 120 -and
                $ResizeEvent.Height -eq 40
            )

        $NoEventSample = [pscustomobject]@{
            HasEvent = $false
            IsKeyEvent = $false
            IsMouseEvent = $false
            IsResizeEvent = $false
            KeyDown = $false
            KeyChar = [char]0
            VirtualKeyCode = 0
            VirtualScanCode = 0
            RepeatCount = 0
            X = 0
            Y = 0
            ButtonState = [uint32]0
            EventFlags = [uint32]0
            MouseWheelDelta = 0
            Width = 0
            Height = 0
            ControlKeyState = [uint32]0
        }

        $NoEvent = ConvertFrom-BatchTerminalNativeSample `
            -Sample $NoEventSample

        Add-SelfTestResult `
            -Name 'Represent input timeouts without an error' `
            -Condition (
                -not $NoEvent.HasEvent -and
                $NoEvent.Kind -eq 'None'
            )
    }
    catch {
        Add-SelfTestResult `
            -Name 'Complete BatchTerminal self-test execution' `
            -Condition $false `
            -Detail $_.Exception.Message
    }
    finally {
        $script:TerminalWidth = $SavedState.Width
        $script:TerminalHeight = $SavedState.Height
        $script:CellCount = $SavedState.CellCount
        $script:RedrawDepth = $SavedState.RedrawDepth
        $script:PendingCharacters = $SavedState.PendingCharacters
        $script:PendingForeground = $SavedState.PendingForeground
        $script:PendingBackground = $SavedState.PendingBackground
        $script:PendingSet = $SavedState.PendingSet
        $script:RenderedCharacters = $SavedState.RenderedCharacters
        $script:RenderedForeground = $SavedState.RenderedForeground
        $script:RenderedBackground = $SavedState.RenderedBackground
        $script:RenderedKnown = $SavedState.RenderedKnown
        $script:DirtyStart = $SavedState.DirtyStart
        $script:DirtyEnd = $SavedState.DirtyEnd
        $script:TestMode = $SavedState.TestMode
        $script:RunWriter = $SavedState.RunWriter
        $script:TerminalInitialized = $SavedState.Initialized
        $script:TerminalCapabilities = $SavedState.Capabilities
    }

    $Result = [pscustomobject][ordered]@{
        Total = $script:SelfTestPassed + $script:SelfTestFailed
        Passed = $script:SelfTestPassed
        Failed = $script:SelfTestFailed
        Results = $script:SelfTestResults.ToArray()
    }

    Remove-Variable `
        -Name SelfTestResults `
        -Scope Script `
        -ErrorAction SilentlyContinue

    Remove-Variable `
        -Name SelfTestPassed `
        -Scope Script `
        -ErrorAction SilentlyContinue

    Remove-Variable `
        -Name SelfTestFailed `
        -Scope Script `
        -ErrorAction SilentlyContinue

    return $Result
}

function Invoke-BatchTerminalCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [AllowEmptyString()]
        [string]$Argument1 = '',

        [AllowEmptyString()]
        [string]$Argument2 = '',

        [AllowEmptyString()]
        [string]$Argument3 = ''
    )

    $Capabilities = Initialize-BatchTerminal -EnableVirtualTerminal

    switch ($CommandName.ToLowerInvariant()) {
        'capabilities' {
            foreach ($Property in $Capabilities.PSObject.Properties) {
                [Console]::WriteLine(
                    $Property.Name + '=' + [string]$Property.Value
                )
            }

            return
        }

        'size' {
            $Size = Get-BatchTerminalSize
            [Console]::WriteLine(
                [string]$Size.Width + 'x' + [string]$Size.Height
            )
            return
        }

        'clear' {
            Clear-BatchTerminal
            return
        }

        'cursor' {
            $X = 0
            $Y = 0

            if (
                -not [int]::TryParse($Argument1, [ref]$X) -or
                -not [int]::TryParse($Argument2, [ref]$Y)
            ) {
                throw (New-BatchTerminalError `
                    -Kind 'InvalidCursorArguments' `
                    -Message 'cursor requires integer X and Y arguments.')
            }

            Set-BatchTerminalCursor -X $X -Y $Y
            return
        }

        'color' {
            $Foreground = [ConsoleColor]::Gray
            $Background = [ConsoleColor]::Black

            try {
                if (-not [string]::IsNullOrWhiteSpace($Argument1)) {
                    $Foreground = [ConsoleColor][Enum]::Parse(
                        [ConsoleColor],
                        $Argument1,
                        $true
                    )
                }

                if (-not [string]::IsNullOrWhiteSpace($Argument2)) {
                    $Background = [ConsoleColor][Enum]::Parse(
                        [ConsoleColor],
                        $Argument2,
                        $true
                    )
                }
            }
            catch {
                throw (New-BatchTerminalError `
                    -Kind 'InvalidColor' `
                    -Message $_.Exception.Message)
            }

            Set-BatchTerminalColor `
                -Foreground $Foreground `
                -Background $Background
            return
        }

        'input-once' {
            $Timeout = 1000

            if (
                -not [string]::IsNullOrWhiteSpace($Argument1) -and
                -not [int]::TryParse($Argument1, [ref]$Timeout)
            ) {
                throw (New-BatchTerminalError `
                    -Kind 'InvalidTimeout' `
                    -Message 'input-once timeout must be an integer.')
            }

            [void](Start-BatchTerminalInput -EnableMouse $true)

            try {
                $Event = Read-BatchTerminalInput `
                    -TimeoutMilliseconds ([uint32]$Timeout)

                foreach ($Property in $Event.PSObject.Properties) {
                    [Console]::WriteLine(
                        $Property.Name + '=' + [string]$Property.Value
                    )
                }
            }
            finally {
                Stop-BatchTerminalInput
            }

            return
        }

        'self-test' {
            $TestResult = Invoke-BatchTerminalSelfTest

            foreach ($Test in $TestResult.Results) {
                $Line = '[' + $Test.Status + '] ' + $Test.Name

                if (-not [string]::IsNullOrWhiteSpace($Test.Detail)) {
                    $Line += ' - ' + $Test.Detail
                }

                [Console]::WriteLine($Line)
            }

            [Console]::WriteLine('')
            [Console]::WriteLine('Tests: ' + $TestResult.Total)
            [Console]::WriteLine('Passed: ' + $TestResult.Passed)
            [Console]::WriteLine('Failed: ' + $TestResult.Failed)

            if ($TestResult.Failed -ne 0) {
                throw (New-BatchTerminalError `
                    -Kind 'SelfTestFailed' `
                    -Message "$($TestResult.Failed) assertion(s) failed.")
            }

            return
        }

        default {
            throw (New-BatchTerminalError `
                -Kind 'UnknownCommand' `
                -Message "Unknown command: $CommandName")
        }
    }
}

Export-ModuleMember -Function @(
    'Initialize-BatchTerminal'
    'Get-BatchTerminalCapabilities'
    'Get-BatchTerminalSize'
    'Set-BatchTerminalCursor'
    'Set-BatchTerminalColor'
    'Clear-BatchTerminal'
    'Clear-BatchTerminalRegion'
    'Begin-BatchTerminalRedraw'
    'Complete-BatchTerminalRedraw'
    'Invoke-BatchTerminalRedraw'
    'Write-BatchTerminalText'
    'Start-BatchTerminalInput'
    'Read-BatchTerminalInput'
    'Read-BatchTerminalKey'
    'Stop-BatchTerminalInput'
    'Invoke-BatchTerminalSelfTest'
    'Invoke-BatchTerminalCommand'
)