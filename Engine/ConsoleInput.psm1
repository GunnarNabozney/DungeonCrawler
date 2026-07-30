Set-StrictMode -Version Latest

function Start-ConsoleMouseSession {
    [CmdletBinding()]
    param()

    return [DungeonConsoleNative]::BeginMouseSession()
}

function Read-ConsoleMouseSample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]$InputHandle,

        [Parameter(Mandatory = $true)]
        [uint32]$TimeoutMilliseconds
    )

    return [DungeonConsoleNative]::ReadMouseEvent(
        $InputHandle,
        $TimeoutMilliseconds
    )
}

function Read-ConsoleInputSample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]$InputHandle,

        [Parameter(Mandatory = $true)]
        [uint32]$TimeoutMilliseconds
    )

    return [DungeonConsoleNative]::ReadInputEvent(
        $InputHandle,
        $TimeoutMilliseconds
    )
}

function Stop-ConsoleMouseSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]$InputHandle
    )

    [DungeonConsoleNative]::EndMouseSession($InputHandle)
}

function New-ConsoleTextBoxState {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$InitialValue = '',

        [ValidateRange(1, 60)]
        [int]$MaximumLength = 20,

        [Parameter(Mandatory = $true)]
        [string]$AllowedCharacterPattern
    )

    $Value = $InitialValue

    if ($Value.Length -gt $MaximumLength) {
        $Value = $Value.Substring(0, $MaximumLength)
    }

    return [pscustomobject]@{
        Value = $Value
        OriginalValue = $Value
        MaximumLength = $MaximumLength
        AllowedCharacterPattern = $AllowedCharacterPattern
    }
}

function Complete-ConsoleTextBoxState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$State,

        [switch]$Cancel
    )

    if ($Cancel) {
        $State.Value = [string]$State.OriginalValue
    }
    else {
        $State.Value = ([string]$State.Value).Trim()
        $State.OriginalValue = [string]$State.Value
    }

    return [string]$State.Value
}

function Update-ConsoleTextBoxState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$State,

        [Parameter(Mandatory = $true)]
        [object]$InputSample
    )

    $Result = [ordered]@{
        Value = [string]$State.Value
        Changed = $false
        Completed = $false
        Cancelled = $false
    }

    if (
        -not $InputSample.HasEvent -or
        -not $InputSample.IsKeyEvent -or
        -not $InputSample.KeyDown
    ) {
        return [pscustomobject]$Result
    }

    $VirtualKeyCode = [int]$InputSample.VirtualKeyCode
    $RepeatCount = [Math]::Max(
        1,
        [int]$InputSample.RepeatCount
    )

    if ($VirtualKeyCode -eq 13) {
        $PreviousValue = [string]$State.Value
        $Result.Value = Complete-ConsoleTextBoxState `
            -State $State

        $Result.Changed =
            $PreviousValue -cne [string]$Result.Value

        $Result.Completed = $true
        return [pscustomobject]$Result
    }

    if ($VirtualKeyCode -eq 27) {
        $PreviousValue = [string]$State.Value
        $Result.Value = Complete-ConsoleTextBoxState `
            -State $State `
            -Cancel

        $Result.Changed =
            $PreviousValue -cne [string]$Result.Value

        $Result.Completed = $true
        $Result.Cancelled = $true
        return [pscustomobject]$Result
    }

    if ($VirtualKeyCode -eq 8) {
        for ($Index = 0; $Index -lt $RepeatCount; $Index++) {
            if ($State.Value.Length -eq 0) {
                break
            }

            $State.Value = $State.Value.Substring(
                0,
                $State.Value.Length - 1
            )

            $Result.Changed = $true
        }

        $Result.Value = [string]$State.Value
        return [pscustomobject]$Result
    }

    $Character = [string]$InputSample.KeyChar

    if (
        $Character.Length -eq 0 -or
        [char]::IsControl($InputSample.KeyChar) -or
        $Character -notmatch $State.AllowedCharacterPattern
    ) {
        return [pscustomobject]$Result
    }

    for ($Index = 0; $Index -lt $RepeatCount; $Index++) {
        if ($State.Value.Length -ge $State.MaximumLength) {
            break
        }

        $State.Value += $Character
        $Result.Changed = $true
    }

    $Result.Value = [string]$State.Value
    return [pscustomobject]$Result
}

function Wait-ForAnyKey {
    [CmdletBinding()]
    param()

    while ([Console]::KeyAvailable) {
        [void][Console]::ReadKey($true)
    }

    [void][Console]::ReadKey($true)
}

function Read-ConsoleText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 60)]
        [int]$Width,

        [AllowEmptyString()]
        [string]$InitialValue = '',

        [ValidateRange(1, 60)]
        [int]$MaximumLength = 20
    )

    while ([Console]::KeyAvailable) {
        [void][Console]::ReadKey($true)
    }

    $OriginalCursorVisibility = [Console]::CursorVisible
    $OriginalForeground = [Console]::ForegroundColor
    $OriginalBackground = [Console]::BackgroundColor

    $Value = $InitialValue
    if ($Value.Length -gt $MaximumLength) {
        $Value = $Value.Substring(0, $MaximumLength)
    }

    $RenderValue = {
        [Console]::SetCursorPosition($X, $Y)
        [Console]::ForegroundColor = [ConsoleColor]::Yellow
        [Console]::BackgroundColor = [ConsoleColor]::Black

        $DisplayValue = $Value
        if ($DisplayValue.Length -gt $Width) {
            $DisplayValue = $DisplayValue.Substring(0, $Width)
        }

        [Console]::Write($DisplayValue.PadRight($Width))

        $CursorOffset = [Math]::Min(
            $DisplayValue.Length,
            $Width - 1
        )

        [Console]::SetCursorPosition(
            $X + $CursorOffset,
            $Y
        )
    }

    try {
        [Console]::CursorVisible = $true
        & $RenderValue

        while ($true) {
            $Key = [Console]::ReadKey($true)

            if ($Key.Key -eq [ConsoleKey]::Enter) {
                return $Value.Trim()
            }

            if ($Key.Key -eq [ConsoleKey]::Escape) {
                return $InitialValue
            }

            if ($Key.Key -eq [ConsoleKey]::Backspace) {
                if ($Value.Length -gt 0) {
                    $Value = $Value.Substring(
                        0,
                        $Value.Length - 1
                    )

                    & $RenderValue
                }

                continue
            }

            if (
                -not [char]::IsControl($Key.KeyChar) -and
                $Value.Length -lt $MaximumLength
            ) {
                $Character = [string]$Key.KeyChar

                if ($Character -match "^[A-Za-z0-9 '\-]$") {
                    $Value += $Character
                    & $RenderValue
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible =
            $OriginalCursorVisibility

        [Console]::ForegroundColor =
            $OriginalForeground

        [Console]::BackgroundColor =
            $OriginalBackground
    }
}

Export-ModuleMember -Function @(
    'Start-ConsoleMouseSession'
    'Read-ConsoleMouseSample'
    'Read-ConsoleInputSample'
    'Stop-ConsoleMouseSession'
    'New-ConsoleTextBoxState'
    'Complete-ConsoleTextBoxState'
    'Update-ConsoleTextBoxState'
    'Wait-ForAnyKey'
    'Read-ConsoleText'
)