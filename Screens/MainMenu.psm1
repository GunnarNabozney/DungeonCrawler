Set-StrictMode -Version Latest

function Get-MainMenuButtons {
    [CmdletBinding()]
    param()

    return @(
        [pscustomobject]@{
            Name  = 'NEW'
            Label = 'NEW'
            X     = 23
            Y     = 16
            Width = 34
        }
        [pscustomobject]@{
            Name  = 'LOAD'
            Label = 'LOAD'
            X     = 23
            Y     = 20
            Width = 34
        }
        [pscustomobject]@{
            Name  = 'EXIT'
            Label = 'EXIT'
            X     = 23
            Y     = 24
            Width = 34
        }
    )
}

function Invoke-MainMenu {
    [CmdletBinding()]
    param()

    [Console]::CursorVisible = $false

    $Buttons = @(Get-MainMenuButtons)

    Animations\Show-MainMenuIntro `
        -Buttons $Buttons

    $InputHandle = [IntPtr]::Zero
    $Selection = $null

    try {
        $InputHandle =
            ConsoleInput\Start-ConsoleMouseSession

        $HoverName = $null
        $PressedName = $null
        $LeftButtonDown = $false
        $TorchFrame = 0
        $PulseState = $false

        $TorchFrameCount =
            Animations\Get-TorchFrameCount

        while ([string]::IsNullOrWhiteSpace($Selection)) {
            $Sample =
                ConsoleInput\Read-ConsoleMouseSample `
                    -InputHandle $InputHandle `
                    -TimeoutMilliseconds 120

            if (-not $Sample.HasEvent) {
                $TorchFrame =
                    ($TorchFrame + 1) %
                    $TorchFrameCount

                $PulseState = -not $PulseState

                Animations\Draw-Torches `
                    -Frame $TorchFrame

                ConsoleUI\Draw-Buttons `
                    -Buttons $Buttons `
                    -HoverName $HoverName `
                    -PressedName $PressedName `
                    -Pulse $PulseState

                continue
            }

            $CurrentButton =
                ConsoleUI\Get-ButtonAt `
                    -Buttons $Buttons `
                    -X $Sample.X `
                    -Y $Sample.Y

            if ($CurrentButton -ne $HoverName) {
                $HoverName = $CurrentButton

                ConsoleUI\Draw-Buttons `
                    -Buttons $Buttons `
                    -HoverName $HoverName `
                    -PressedName $PressedName `
                    -Pulse $true
            }

            $IsLeftButtonDown =
                ($Sample.ButtonState -band 0x0001) -ne 0

            if (
                $IsLeftButtonDown -and
                -not $LeftButtonDown
            ) {
                $PressedName = $CurrentButton

                ConsoleUI\Draw-Buttons `
                    -Buttons $Buttons `
                    -HoverName $HoverName `
                    -PressedName $PressedName
            }
            elseif (
                -not $IsLeftButtonDown -and
                $LeftButtonDown
            ) {
                $ReleasedName = $CurrentButton

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        $PressedName
                    ) -and
                    $ReleasedName -eq $PressedName
                ) {
                    $Selection = $PressedName
                }

                $PressedName = $null

                ConsoleUI\Draw-Buttons `
                    -Buttons $Buttons `
                    -HoverName $HoverName `
                    -PressedName $null `
                    -Pulse $true
            }

            $LeftButtonDown = $IsLeftButtonDown
        }

        Animations\Show-MenuSelection `
            -Buttons $Buttons `
            -Selection $Selection

        if ($Selection -eq 'EXIT') {
            Animations\Show-ExitAnimation `
                -Buttons $Buttons
        }

        return $Selection
    }
    finally {
        if ($InputHandle -ne [IntPtr]::Zero) {
            ConsoleInput\Stop-ConsoleMouseSession `
                -InputHandle $InputHandle
        }
    }
}

Export-ModuleMember -Function @(
    'Invoke-MainMenu'
)
