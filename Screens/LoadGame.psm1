Set-StrictMode -Version Latest

function Get-SaveDisplayTime {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$SavedAtUtc
    )

    if ([string]::IsNullOrWhiteSpace($SavedAtUtc)) {
        return 'UNKNOWN TIME'
    }

    try {
        $SavedAt = [DateTimeOffset]::Parse($SavedAtUtc)
        return $SavedAt.ToLocalTime().ToString('yyyy-MM-dd HH:mm')
    }
    catch {
        return 'UNKNOWN TIME'
    }
}

function Draw-LoadGameButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [AllowNull()]
        [object]$LoadButton,

        [Parameter(Mandatory = $true)]
        [bool]$HasSave,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    if ($HasSave) {
        ConsoleUI\Draw-ActionButtons `
            -BackButton $BackButton `
            -ContinueButton $LoadButton `
            -HoverName $HoverTarget `
            -PressedName $PressedTarget `
            -ContinueEnabled $true

        return
    }

    $BackStyle = 'Normal'

    if ($PressedTarget -eq 'BACK') {
        $BackStyle = 'Pressed'
    }
    elseif ($HoverTarget -eq 'BACK') {
        $BackStyle = 'HoverBright'
    }

    ConsoleUI\Draw-Button `
        -Button $BackButton `
        -Style $BackStyle
}

function Draw-LoadGameScreen {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$SaveGame,

        [AllowEmptyString()]
        [string]$LoadError,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [AllowNull()]
        [object]$LoadButton,

        [Parameter(Mandatory = $true)]
        [bool]$HasSave,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    ConsoleUI\Clear-ConsoleScreen
    ConsoleUI\Draw-Frame

    ConsoleUI\Write-Centered `
        -Y 1 `
        -Text 'THE HALL OF ECHOES' `
        -Color Yellow

    if ($HasSave) {
        $SavedTime = Get-SaveDisplayTime `
            -SavedAtUtc $SaveGame.SavedAtUtc

        ConsoleUI\Write-Centered `
            -Y 2 `
            -Text ('SAVE SLOT 1   |   ' + $SavedTime) `
            -Color DarkGray

        CharacterPreview\Draw-CharacterPreview `
            -CharacterDraft $SaveGame.CharacterDraft

        $StatusText = (
            'LOAD restores this character to the current session.'
        )
    }
    elseif (-not [string]::IsNullOrWhiteSpace($LoadError)) {
        ConsoleUI\Write-Centered `
            -Y 8 `
            -Text 'SAVE SLOT 1 COULD NOT BE READ' `
            -Color Yellow

        $ErrorText = $LoadError

        if ($ErrorText.Length -gt 68) {
            $ErrorText = $ErrorText.Substring(0, 68)
        }

        ConsoleUI\Write-Centered `
            -Y 11 `
            -Text $ErrorText `
            -Color DarkGray

        $StatusText = 'Select BACK to return to the main menu.'
    }
    else {
        ConsoleUI\Write-Centered `
            -Y 9 `
            -Text 'No forgotten adventurers have been recorded yet.' `
            -Color Gray

        ConsoleUI\Write-Centered `
            -Y 12 `
            -Text 'Confirm a new character to create save slot 1.' `
            -Color DarkGray

        $StatusText = 'Select BACK to return to the main menu.'
    }

    Draw-LoadGameButtons `
        -BackButton $BackButton `
        -LoadButton $LoadButton `
        -HasSave $HasSave `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget

    ConsoleUI\Set-Status `
        -Text $StatusText `
        -Color DarkYellow
}

function Invoke-LoadGameScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppRoot
    )

    [Console]::CursorVisible = $false

    $SaveGame = $null
    $LoadError = ''

    try {
        $SaveGame = SaveGame\Get-PrimarySaveGame `
            -AppRoot $AppRoot
    }
    catch {
        $LoadError = $_.Exception.Message
    }

    $HasSave = $null -ne $SaveGame

    if ($HasSave) {
        $BackButton = [pscustomobject]@{
            Name = 'BACK'
            Label = 'BACK'
            X = 3
            Y = 25
            Width = 22
        }

        $LoadButton = [pscustomobject]@{
            Name = 'LOAD'
            Label = 'LOAD'
            X = 54
            Y = 25
            Width = 22
        }

        $Buttons = @(
            $BackButton
            $LoadButton
        )
    }
    else {
        $BackButton = [pscustomobject]@{
            Name = 'BACK'
            Label = 'BACK'
            X = 29
            Y = 25
            Width = 22
        }

        $LoadButton = $null
        $Buttons = @($BackButton)
    }

    $HoverTarget = $null
    $PressedTarget = $null
    $LeftButtonDown = $false
    $InputHandle = [IntPtr]::Zero

    Draw-LoadGameScreen `
        -SaveGame $SaveGame `
        -LoadError $LoadError `
        -BackButton $BackButton `
        -LoadButton $LoadButton `
        -HasSave $HasSave `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget

    try {
        $InputHandle = ConsoleInput\Start-ConsoleMouseSession

        while ($true) {
            $Sample = ConsoleInput\Read-ConsoleMouseSample `
                -InputHandle $InputHandle `
                -TimeoutMilliseconds 120

            if (-not $Sample.HasEvent) {
                continue
            }

            $CurrentTarget = ConsoleUI\Get-ButtonAt `
                -Buttons $Buttons `
                -X $Sample.X `
                -Y $Sample.Y

            if ($CurrentTarget -ne $HoverTarget) {
                $HoverTarget = $CurrentTarget

                Draw-LoadGameButtons `
                    -BackButton $BackButton `
                    -LoadButton $LoadButton `
                    -HasSave $HasSave `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget
            }

            $IsLeftButtonDown = (
                $Sample.ButtonState -band 0x0001
            ) -ne 0

            if ($IsLeftButtonDown -and -not $LeftButtonDown) {
                $PressedTarget = $CurrentTarget

                Draw-LoadGameButtons `
                    -BackButton $BackButton `
                    -LoadButton $LoadButton `
                    -HasSave $HasSave `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget
            }
            elseif (-not $IsLeftButtonDown -and $LeftButtonDown) {
                $ReleasedTarget = $CurrentTarget
                $ActivatedTarget = $null

                if (
                    -not [string]::IsNullOrWhiteSpace($PressedTarget) -and
                    $ReleasedTarget -eq $PressedTarget
                ) {
                    $ActivatedTarget = $PressedTarget
                }

                $PressedTarget = $null

                Draw-LoadGameButtons `
                    -BackButton $BackButton `
                    -LoadButton $LoadButton `
                    -HasSave $HasSave `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget

                if ($ActivatedTarget -eq 'BACK') {
                    return [pscustomobject]@{
                        NextState = 'MAIN_MENU'
                    }
                }

                if ($ActivatedTarget -eq 'LOAD' -and $HasSave) {
                    ConsoleUI\Set-Status `
                        -Text (
                            'Loaded ' +
                            [string]$SaveGame.CharacterDraft.Name +
                            ' from slot 1.'
                        ) `
                        -Color Yellow

                    Start-Sleep -Milliseconds 500

                    return [pscustomobject]@{
                        NextState = 'MAIN_MENU'
                        CharacterDraft = $SaveGame.CharacterDraft
                        Loaded = $true
                    }
                }
            }

            $LeftButtonDown = $IsLeftButtonDown
        }
    }
    finally {
        if ($InputHandle -ne [IntPtr]::Zero) {
            ConsoleInput\Stop-ConsoleMouseSession `
                -InputHandle $InputHandle
        }
    }
}

Export-ModuleMember -Function @(
    'Invoke-LoadGameScreen'
)
