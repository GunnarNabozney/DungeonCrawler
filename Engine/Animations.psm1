Set-StrictMode -Version Latest

$script:TitleStartY = 3

$script:TitleLines = @(
    ' ____  _   _ _   _  ____ _____ ___  _   _'
    '|  _ \| | | | \ | |/ ___| ____/ _ \| \ | |'
    '| | | | | | |  \| | |  _|  _|| | | |  \| |'
    '| |_| | |_| | |\  | |_| | |__| |_| | |\  |'
    '|____/ \___/|_| \_|\____|_____\___/|_| \_|'
    ''
    '  ____ ____      ___        ____ ____ ____'
    ' / ___|  _ \    / \ \      / / | ____|  _ \'
    '| |   | |_) |  / _ \ \ /\ / /| |  _| | |_) |'
    '| |___|  _ <  / ___ \ V  V / | | |___|  _ <'
    ' \____|_| \_\/_/   \_\_/\_/  |_|_____|_| \_\'
)

$script:TitleWidth = [int](
    $script:TitleLines |
        Measure-Object -Property Length -Maximum
).Maximum

$script:TorchFrames = @(
    @(
        '   .   '
        '  ( )  '
        '   )   '
        '  /|\  '
        ' /_|_\ '
        '   |   '
    ),
    @(
        '   (   '
        '  ( )  '
        '   .   '
        '  /|\  '
        ' /_|_\ '
        '   |   '
    ),
    @(
        '   )   '
        '  ( )  '
        '   (   '
        '  /|\  '
        ' /_|_\ '
        '   |   '
    ),
    @(
        '  ( )  '
        '   )   '
        '   .   '
        '  /|\  '
        ' /_|_\ '
        '   |   '
    )
)

function Get-TorchFrameCount {
    [CmdletBinding()]
    param()

    return $script:TorchFrames.Count
}

function Draw-Torches {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Frame
    )

    ConsoleUI\Invoke-ConsoleRedraw {
        $SelectedFrame =
            $script:TorchFrames[
                $Frame % $script:TorchFrames.Count
            ]
    
        for (
            $Index = 0;
            $Index -lt $SelectedFrame.Count;
            $Index++
        ) {
            $Color = if ($Index -le 2) {
                [ConsoleColor]::Yellow
            }
            else {
                [ConsoleColor]::DarkYellow
            }
    
            ConsoleUI\Write-At `
                -X 5 `
                -Y (5 + $Index) `
                -Text $SelectedFrame[$Index] `
                -Color $Color
    
            ConsoleUI\Write-At `
                -X 68 `
                -Y (5 + $Index) `
                -Text $SelectedFrame[$Index] `
                -Color $Color
        }
    }
}

function Clear-Torches {
    [CmdletBinding()]
    param()

    ConsoleUI\Invoke-ConsoleRedraw {
        for ($Index = 0; $Index -lt 6; $Index++) {
            ConsoleUI\Write-At `
                -X 5 `
                -Y (5 + $Index) `
                -Text (' ' * 7)
    
            ConsoleUI\Write-At `
                -X 68 `
                -Y (5 + $Index) `
                -Text (' ' * 7)
        }
    }
}

function Draw-FullTitle {
    [CmdletBinding()]
    param()

    for (
        $Index = 0;
        $Index -lt $script:TitleLines.Count;
        $Index++
    ) {
        ConsoleUI\Write-Centered `
            -Y ($script:TitleStartY + $Index) `
            -Text (
                $script:TitleLines[$Index].PadRight(
                    $script:TitleWidth
                )
            ) `
            -Color Gray
    }
}

function Show-TitleReveal {
    [CmdletBinding()]
    param()

    $MaximumLength = $script:TitleWidth

    $MaximumRadius =
        [int][Math]::Ceiling($MaximumLength / 2)

    for (
        $Radius = 0;
        $Radius -le $MaximumRadius;
        $Radius += 2
    ) {
        for (
            $Index = 0;
            $Index -lt $script:TitleLines.Count;
            $Index++
        ) {
            $Line = $script:TitleLines[$Index]

            if ($Line.Length -eq 0) {
                ConsoleUI\Clear-TextLine `
                    -Y ($script:TitleStartY + $Index)

                continue
            }

            $Center =
                [int][Math]::Floor($Line.Length / 2)

            $Start =
                [Math]::Max(0, $Center - $Radius)

            $End =
                [Math]::Min(
                    $Line.Length,
                    $Center + $Radius + 1
                )

            $VisibleLength = $End - $Start

            $VisibleLine =
                (' ' * $Start) +
                $Line.Substring($Start, $VisibleLength) +
                (' ' * ($Line.Length - $End))

            ConsoleUI\Write-Centered `
                -Y ($script:TitleStartY + $Index) `
                -Text (
                    $VisibleLine.PadRight(
                        $MaximumLength
                    )
                ) `
                -Color Gray
        }

        Draw-Torches `
            -Frame ([int]($Radius / 2))

        Start-Sleep -Milliseconds 35
    }

    Draw-FullTitle
}

function Show-MainMenuIntro {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Buttons
    )

    ConsoleUI\Clear-ConsoleScreen

    ConsoleUI\Draw-Frame

    ConsoleUI\Write-Centered `
        -Y 1 `
        -Text 'THE DEPTHS ARE WAITING' `
        -Color DarkYellow

    ConsoleUI\Set-Status `
        -Text 'Something awakens beneath the stone...'

    for ($Frame = 0; $Frame -lt 4; $Frame++) {
        Draw-Torches -Frame $Frame
        Start-Sleep -Milliseconds 140
    }

    Show-TitleReveal

    $TorchFrame = 0

    foreach ($Button in $Buttons) {
        ConsoleUI\Draw-Button `
            -Button $Button `
            -Style Normal

        $TorchFrame =
            ($TorchFrame + 1) %
            $script:TorchFrames.Count

        Draw-Torches -Frame $TorchFrame

        Start-Sleep -Milliseconds 150
    }

    ConsoleUI\Set-Status `
        -Text 'Choose your fate.' `
        -Color DarkYellow
}

function Show-MenuSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Buttons,

        [Parameter(Mandatory)]
        [string]$Selection
    )

    ConsoleUI\Draw-Buttons `
        -Buttons $Buttons `
        -HoverName $Selection `
        -PressedName $Selection

    Start-Sleep -Milliseconds 110

    ConsoleUI\Draw-Buttons `
        -Buttons $Buttons `
        -HoverName $Selection `
        -PressedName $null `
        -Pulse $true

    if ($Selection -eq 'EXIT') {
        ConsoleUI\Set-Status `
            -Text 'The dungeon remembers your name...' `
            -Color DarkYellow
    }
    else {
        ConsoleUI\Set-Status `
            -Text 'The gate opens...' `
            -Color Yellow

        Start-Sleep -Milliseconds 260
    }
}

function Show-ExitAnimation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Buttons
    )

    foreach (
        $Button in (
            $Buttons |
                Sort-Object Y -Descending
        )
    ) {
        ConsoleUI\Clear-Button -Button $Button
        Start-Sleep -Milliseconds 90
    }

    ConsoleUI\Set-Status `
        -Text 'The torches fade...' `
        -Color DarkGray

    for ($Frame = 3; $Frame -ge 0; $Frame--) {
        Draw-Torches -Frame $Frame
        Start-Sleep -Milliseconds 130
    }

    Clear-Torches

    $TopIndex = 0
    $BottomIndex = $script:TitleLines.Count - 1

    while ($TopIndex -le $BottomIndex) {
        ConsoleUI\Clear-TextLine `
            -Y ($script:TitleStartY + $TopIndex)

        if ($BottomIndex -ne $TopIndex) {
            ConsoleUI\Clear-TextLine `
                -Y ($script:TitleStartY + $BottomIndex)
        }

        $TopIndex++
        $BottomIndex--

        Start-Sleep -Milliseconds 55
    }

    ConsoleUI\Set-Status -Text ''

    Start-Sleep -Milliseconds 160

    ConsoleUI\Clear-ConsoleScreen
}

Export-ModuleMember -Function @(
    'Get-TorchFrameCount'
    'Draw-Torches'
    'Clear-Torches'
    'Show-MainMenuIntro'
    'Show-MenuSelection'
    'Show-ExitAnimation'
)
