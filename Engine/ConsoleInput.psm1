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

    return [DungeonConsoleNative]::ReadMouseEvent($InputHandle, $TimeoutMilliseconds)
}

function Stop-ConsoleMouseSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]$InputHandle
    )

    [DungeonConsoleNative]::EndMouseSession($InputHandle)
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

        $CursorOffset = [Math]::Min($DisplayValue.Length, $Width - 1)
        [Console]::SetCursorPosition($X + $CursorOffset, $Y)
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
                    $Value = $Value.Substring(0, $Value.Length - 1)
                    & $RenderValue
                }

                continue
            }

            if (-not [char]::IsControl($Key.KeyChar) -and $Value.Length -lt $MaximumLength) {
                $Character = [string]$Key.KeyChar

                if ($Character -match "^[A-Za-z0-9 '\-]$") {
                    $Value += $Character
                    & $RenderValue
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $OriginalCursorVisibility
        [Console]::ForegroundColor = $OriginalForeground
        [Console]::BackgroundColor = $OriginalBackground
    }
}

Export-ModuleMember -Function @(
    'Start-ConsoleMouseSession'
    'Read-ConsoleMouseSample'
    'Stop-ConsoleMouseSession'
    'Wait-ForAnyKey'
    'Read-ConsoleText'
)
