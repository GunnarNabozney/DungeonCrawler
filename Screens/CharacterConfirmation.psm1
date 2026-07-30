Set-StrictMode -Version Latest

function Draw-CharacterConfirmationScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ConfirmButton,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    ConsoleUI\Clear-ConsoleScreen
    ConsoleUI\Draw-Frame

    ConsoleUI\Write-Centered `
        -Y 1 `
        -Text 'CONFIRM YOUR ADVENTURER' `
        -Color Yellow

    ConsoleUI\Write-Centered `
        -Y 2 `
        -Text 'Review your choices before creating save slot 1.' `
        -Color DarkGray

    CharacterPreview\Draw-CharacterPreview `
        -CharacterDraft $CharacterDraft

    ConsoleUI\Draw-ActionButtons `
        -BackButton $BackButton `
        -ContinueButton $ConfirmButton `
        -HoverName $HoverTarget `
        -PressedName $PressedTarget `
        -ContinueEnabled $true

    ConsoleUI\Set-Status `
        -Text 'BACK returns to Tag Skills. CONFIRM & SAVE writes slot 1.' `
        -Color DarkYellow
}

function Invoke-CharacterConfirmationScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppRoot,

        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft
    )

    [Console]::CursorVisible = $false

    $BackButton = [pscustomobject]@{
        Name = 'BACK'
        Label = 'BACK'
        X = 3
        Y = 25
        Width = 22
    }

    $ConfirmButton = [pscustomobject]@{
        Name = 'CONFIRM'
        Label = 'CONFIRM & SAVE'
        X = 47
        Y = 25
        Width = 29
    }

    $Buttons = @(
        $BackButton
        $ConfirmButton
    )

    $HoverTarget = $null
    $PressedTarget = $null
    $LeftButtonDown = $false
    $InputHandle = [IntPtr]::Zero

    Draw-CharacterConfirmationScreen `
        -CharacterDraft $CharacterDraft `
        -BackButton $BackButton `
        -ConfirmButton $ConfirmButton `
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

                ConsoleUI\Draw-ActionButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ConfirmButton `
                    -HoverName $HoverTarget `
                    -PressedName $PressedTarget `
                    -ContinueEnabled $true
            }

            $IsLeftButtonDown = (
                $Sample.ButtonState -band 0x0001
            ) -ne 0

            if ($IsLeftButtonDown -and -not $LeftButtonDown) {
                $PressedTarget = $CurrentTarget

                ConsoleUI\Draw-ActionButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ConfirmButton `
                    -HoverName $HoverTarget `
                    -PressedName $PressedTarget `
                    -ContinueEnabled $true
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

                ConsoleUI\Draw-ActionButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ConfirmButton `
                    -HoverName $HoverTarget `
                    -PressedName $PressedTarget `
                    -ContinueEnabled $true

                if ($ActivatedTarget -eq 'BACK') {
                    return [pscustomobject]@{
                        NextState = 'TAG_SKILLS'
                        CharacterDraft = $CharacterDraft
                    }
                }

                if ($ActivatedTarget -eq 'CONFIRM') {
                    [void](
                        SaveGame\Save-PrimaryCharacter `
                            -AppRoot $AppRoot `
                            -CharacterDraft $CharacterDraft
                    )

                    ConsoleUI\Set-Status `
                        -Text (
                            'Saved ' +
                            [string]$CharacterDraft.Name +
                            ' to slot 1.'
                        ) `
                        -Color Yellow

                    Start-Sleep -Milliseconds 500

                    return [pscustomobject]@{
                        NextState = 'MAIN_MENU'
                        CharacterDraft = $CharacterDraft
                        Saved = $true
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
    'Invoke-CharacterConfirmationScreen'
)
