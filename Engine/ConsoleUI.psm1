Set-StrictMode -Version Latest

$script:ConsoleWidth = 80

function Write-At {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text,

        [System.ConsoleColor]$Color =
            [System.ConsoleColor]::Gray
    )

    if ($Y -lt 0 -or $Y -ge [Console]::BufferHeight) {
        return
    }

    if ($X -lt 0 -or $X -ge [Console]::BufferWidth) {
        return
    }

    $AvailableWidth = [Console]::BufferWidth - $X

    if ($Text.Length -gt $AvailableWidth) {
        $Text = $Text.Substring(0, $AvailableWidth)
    }

    [Console]::SetCursorPosition($X, $Y)
    [Console]::ForegroundColor = $Color
    [Console]::BackgroundColor = [ConsoleColor]::Black
    [Console]::Write($Text)
}

function Write-Centered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Y,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text,

        [System.ConsoleColor]$Color =
            [System.ConsoleColor]::Gray
    )

    $X = [Math]::Max(
        0,
        [int][Math]::Floor(
            ($script:ConsoleWidth - $Text.Length) / 2
        )
    )

    Write-At `
        -X $X `
        -Y $Y `
        -Text $Text `
        -Color $Color
}

function Clear-TextLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Y
    )

    Write-At `
        -X 2 `
        -Y $Y `
        -Text (' ' * 76) `
        -Color DarkGray
}

function Draw-Frame {
    [CmdletBinding()]
    param()

    Write-At `
        -X 1 `
        -Y 0 `
        -Text ('/' + ('=' * 76) + '\') `
        -Color DarkGray

    for ($Y = 1; $Y -le 28; $Y++) {
        Write-At `
            -X 1 `
            -Y $Y `
            -Text '|' `
            -Color DarkGray

        Write-At `
            -X 78 `
            -Y $Y `
            -Text '|' `
            -Color DarkGray
    }

    Write-At `
        -X 1 `
        -Y 29 `
        -Text ('\' + ('=' * 76) + '/') `
        -Color DarkGray
}

function Draw-Button {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Button,

        [ValidateSet(
            'Normal',
            'Hover',
            'HoverBright',
            'Selected',
            'Pressed',
            'Disabled'
        )]
        [string]$Style = 'Normal'
    )

    $InnerWidth = $Button.Width - 2

    switch ($Style) {
        'Hover' {
            $Top = '>' + ('=' * $InnerWidth) + '<'
            $Bottom = $Top
            $Side = '|'
            $Color = [ConsoleColor]::DarkYellow
        }

        'HoverBright' {
            $Top = '>' + ('=' * $InnerWidth) + '<'
            $Bottom = $Top
            $Side = '|'
            $Color = [ConsoleColor]::Yellow
        }

        'Selected' {
            $Top = '[' + ('=' * $InnerWidth) + ']'
            $Bottom = $Top
            $Side = '#'
            $Color = [ConsoleColor]::Yellow
        }

        'Pressed' {
            $Top = '[' + ('#' * $InnerWidth) + ']'
            $Bottom = $Top
            $Side = '#'
            $Color = [ConsoleColor]::White
        }

        'Disabled' {
            $Top = '+' + ('.' * $InnerWidth) + '+'
            $Bottom = $Top
            $Side = ':'
            $Color = [ConsoleColor]::DarkGray
        }

        default {
            $Top = '+' + ('-' * $InnerWidth) + '+'
            $Bottom = $Top
            $Side = '|'
            $Color = [ConsoleColor]::DarkGray
        }
    }

    $LeftPadding = [int][Math]::Floor(
        ($InnerWidth - $Button.Label.Length) / 2
    )

    $RightPadding =
        $InnerWidth -
        $Button.Label.Length -
        $LeftPadding

    $Middle =
        $Side +
        (' ' * $LeftPadding) +
        $Button.Label +
        (' ' * $RightPadding) +
        $Side

    Write-At `
        -X $Button.X `
        -Y $Button.Y `
        -Text $Top `
        -Color $Color

    Write-At `
        -X $Button.X `
        -Y ($Button.Y + 1) `
        -Text $Middle `
        -Color $Color

    Write-At `
        -X $Button.X `
        -Y ($Button.Y + 2) `
        -Text $Bottom `
        -Color $Color
}

function Clear-Button {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Button
    )

    for ($Row = 0; $Row -lt 3; $Row++) {
        Write-At `
            -X $Button.X `
            -Y ($Button.Y + $Row) `
            -Text (' ' * $Button.Width)
    }
}

function Draw-Buttons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Buttons,

        [AllowNull()]
        [string]$HoverName,

        [AllowNull()]
        [string]$PressedName,

        [AllowNull()]
        [string]$SelectedName,

        [bool]$Pulse = $false
    )

    foreach ($Button in $Buttons) {
        $Style = 'Normal'

        if (
            -not [string]::IsNullOrWhiteSpace($PressedName) -and
            $Button.Name -eq $PressedName
        ) {
            $Style = 'Pressed'
        }
        elseif (
            -not [string]::IsNullOrWhiteSpace($SelectedName) -and
            $Button.Name -eq $SelectedName
        ) {
            $Style = 'Selected'
        }
        elseif (
            -not [string]::IsNullOrWhiteSpace($HoverName) -and
            $Button.Name -eq $HoverName
        ) {
            $Style = if ($Pulse) {
                'HoverBright'
            }
            else {
                'Hover'
            }
        }

        Draw-Button `
            -Button $Button `
            -Style $Style
    }
}

function Get-ButtonAt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Buttons,

        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y
    )

    foreach ($Button in $Buttons) {
        $InsideHorizontal =
            $X -ge $Button.X -and
            $X -lt ($Button.X + $Button.Width)

        $InsideVertical =
            $Y -ge $Button.Y -and
            $Y -le ($Button.Y + 2)

        if ($InsideHorizontal -and $InsideVertical) {
            return $Button.Name
        }
    }

    return $null
}

function Set-Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text,

        [System.ConsoleColor]$Color =
            [System.ConsoleColor]::DarkGray
    )

    Clear-TextLine -Y 28

    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        Write-Centered `
            -Y 28 `
            -Text $Text `
            -Color $Color
    }
}

Export-ModuleMember -Function @(
    'Write-At'
    'Write-Centered'
    'Clear-TextLine'
    'Draw-Frame'
    'Draw-Button'
    'Clear-Button'
    'Draw-Buttons'
    'Get-ButtonAt'
    'Set-Status'
)
