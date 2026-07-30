Set-StrictMode -Version Latest

$script:ConsoleWidth = 80

$script:RedrawDepth = 0
$script:PendingCells = @{}
$script:RenderedCells = @{}

function Get-ConsoleCellKey {
    param(
        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y
    )

    return "$Y`:$X"
}

function Set-ConsoleRenderCacheText {
    param(
        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory)]
        [System.ConsoleColor]$Color
    )

    for ($Index = 0; $Index -lt $Text.Length; $Index++) {
        $CellX = $X + $Index
        $Key = Get-ConsoleCellKey -X $CellX -Y $Y

        $script:RenderedCells[$Key] = [pscustomobject]@{
            Character = [string]$Text[$Index]
            Color = [int]$Color
        }
    }
}

function Test-ConsoleCellChanged {
    param(
        [Parameter(Mandatory)]
        [object]$Cell
    )

    $Key = Get-ConsoleCellKey -X $Cell.X -Y $Cell.Y

    if (-not $script:RenderedCells.ContainsKey($Key)) {
        return $true
    }

    $RenderedCell = $script:RenderedCells[$Key]

    return (
        [string]$RenderedCell.Character -cne
            [string]$Cell.Character -or
        [int]$RenderedCell.Color -ne
            [int]$Cell.Color
    )
}

function Write-ConsoleRun {
    param(
        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory)]
        [System.ConsoleColor]$Color
    )

    if ($Text.Length -eq 0) {
        return
    }

    [Console]::SetCursorPosition($X, $Y)
    [Console]::ForegroundColor = $Color
    [Console]::BackgroundColor = [ConsoleColor]::Black
    [Console]::Write($Text)
}

function Flush-ConsoleRedraw {
    $ChangedCells = @(
        @(
            foreach ($Cell in $script:PendingCells.Values) {
                if (Test-ConsoleCellChanged -Cell $Cell) {
                    $Cell
                }
            }
        ) |
            Sort-Object -Property Y, X
    )

    $RunX = -1
    $RunY = -1
    $RunColor = [ConsoleColor]::Gray
    $RunText = ''

    foreach ($Cell in $ChangedCells) {
        $CanAppend = (
            $RunText.Length -gt 0 -and
            $Cell.Y -eq $RunY -and
            $Cell.X -eq ($RunX + $RunText.Length) -and
            [int]$Cell.Color -eq [int]$RunColor
        )

        if (-not $CanAppend) {
            if ($RunText.Length -gt 0) {
                Write-ConsoleRun `
                    -X $RunX `
                    -Y $RunY `
                    -Text $RunText `
                    -Color $RunColor
            }

            $RunX = [int]$Cell.X
            $RunY = [int]$Cell.Y
            $RunColor = [ConsoleColor]$Cell.Color
            $RunText = [string]$Cell.Character
        }
        else {
            $RunText += [string]$Cell.Character
        }
    }

    if ($RunText.Length -gt 0) {
        Write-ConsoleRun `
            -X $RunX `
            -Y $RunY `
            -Text $RunText `
            -Color $RunColor
    }

    foreach ($Cell in $script:PendingCells.Values) {
        $Key = Get-ConsoleCellKey -X $Cell.X -Y $Cell.Y

        $script:RenderedCells[$Key] = [pscustomobject]@{
            Character = [string]$Cell.Character
            Color = [int]$Cell.Color
        }
    }

    $script:PendingCells = @{}
}

function Invoke-ConsoleRedraw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Render
    )

    $IsRootRedraw = $script:RedrawDepth -eq 0

    if ($IsRootRedraw) {
        $script:PendingCells = @{}
    }

    $script:RedrawDepth++

    try {
        & $Render
    }
    catch {
        $script:RedrawDepth--

        if ($IsRootRedraw) {
            $script:PendingCells = @{}
        }

        throw
    }

    $script:RedrawDepth--

    if ($IsRootRedraw) {
        Flush-ConsoleRedraw
    }
}

function Clear-ConsoleScreen {
    [CmdletBinding()]
    param()

    [Console]::Clear()
    $script:PendingCells = @{}
    $script:RenderedCells = @{}
}

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

    if ($script:RedrawDepth -gt 0) {
        for ($Index = 0; $Index -lt $Text.Length; $Index++) {
            $CellX = $X + $Index
            $Key = Get-ConsoleCellKey -X $CellX -Y $Y

            $script:PendingCells[$Key] = [pscustomobject]@{
                X = $CellX
                Y = $Y
                Character = [string]$Text[$Index]
                Color = [int]$Color
            }
        }

        return
    }

    [Console]::SetCursorPosition($X, $Y)
    [Console]::ForegroundColor = $Color
    [Console]::BackgroundColor = [ConsoleColor]::Black
    [Console]::Write($Text)

    Set-ConsoleRenderCacheText `
        -X $X `
        -Y $Y `
        -Text $Text `
        -Color $Color
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

    ConsoleUI\Invoke-ConsoleRedraw {
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

    ConsoleUI\Invoke-ConsoleRedraw {
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
}

function Clear-Button {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Button
    )

    ConsoleUI\Invoke-ConsoleRedraw {
        for ($Row = 0; $Row -lt 3; $Row++) {
            Write-At `
                -X $Button.X `
                -Y ($Button.Y + $Row) `
                -Text (' ' * $Button.Width)
        }
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

    ConsoleUI\Invoke-ConsoleRedraw {
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

    ConsoleUI\Invoke-ConsoleRedraw {
        Clear-TextLine -Y 28
    
        if (-not [string]::IsNullOrWhiteSpace($Text)) {
            Write-Centered `
                -Y 28 `
                -Text $Text `
                -Color $Color
        }
    }
}

Export-ModuleMember -Function @(
    'Write-At'
    'Write-Centered'
    'Clear-TextLine'
    'Clear-ConsoleScreen'
    'Invoke-ConsoleRedraw'
    'Draw-Frame'
    'Draw-Button'
    'Clear-Button'
    'Draw-Buttons'
    'Get-ButtonAt'
    'Set-Status'
)
