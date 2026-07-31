Set-StrictMode -Version Latest

$script:ConsoleWidth = 80

$script:ConsoleHeight = 30
$script:CellCount =
    $script:ConsoleWidth * $script:ConsoleHeight

$script:RedrawDepth = 0

$script:PendingCharacters =
    [char[]]::new($script:CellCount)

$script:PendingColors =
    [int[]]::new($script:CellCount)

$script:PendingSet =
    [bool[]]::new($script:CellCount)

$script:RenderedCharacters =
    [char[]]::new($script:CellCount)

$script:RenderedColors =
    [int[]]::new($script:CellCount)

$script:RenderedKnown =
    [bool[]]::new($script:CellCount)

$script:DirtyStart =
    [int[]]::new($script:ConsoleHeight)

$script:DirtyEnd =
    [int[]]::new($script:ConsoleHeight)

for ($Y = 0; $Y -lt $script:ConsoleHeight; $Y++) {
    $script:DirtyStart[$Y] = $script:ConsoleWidth
    $script:DirtyEnd[$Y] = -1
}

function Reset-PendingConsoleRedraw {
    [Array]::Clear(
        $script:PendingSet,
        0,
        $script:PendingSet.Length
    )

    for ($Y = 0; $Y -lt $script:ConsoleHeight; $Y++) {
        $script:DirtyStart[$Y] =
            $script:ConsoleWidth

        $script:DirtyEnd[$Y] = -1
    }
}

function Reset-ConsoleRenderCache {
    [Array]::Clear(
        $script:RenderedKnown,
        0,
        $script:RenderedKnown.Length
    )
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
        $CellIndex =
            ($Y * $script:ConsoleWidth) + $CellX

        $script:RenderedCharacters[$CellIndex] =
            $Text[$Index]

        $script:RenderedColors[$CellIndex] =
            [int]$Color

        $script:RenderedKnown[$CellIndex] =
            $true
    }
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
    [Console]::BackgroundColor =
        [ConsoleColor]::Black

    [Console]::Write($Text)
}

function Flush-ConsoleRedraw {
    for ($Y = 0; $Y -lt $script:ConsoleHeight; $Y++) {
        $StartX = $script:DirtyStart[$Y]
        $EndX = $script:DirtyEnd[$Y]

        if ($EndX -lt $StartX) {
            continue
        }

        $RunX = -1
        $RunColor = [ConsoleColor]::Gray
        $RunText = ''

        for ($X = $StartX; $X -le $EndX; $X++) {
            $CellIndex =
                ($Y * $script:ConsoleWidth) + $X

            if (-not $script:PendingSet[$CellIndex]) {
                if ($RunText.Length -gt 0) {
                    Write-ConsoleRun `
                        -X $RunX `
                        -Y $Y `
                        -Text $RunText `
                        -Color $RunColor

                    $RunText = ''
                }

                continue
            }

            $Character =
                $script:PendingCharacters[$CellIndex]

            $Color =
                [ConsoleColor]$script:PendingColors[
                    $CellIndex
                ]

            $Changed = (
                -not $script:RenderedKnown[$CellIndex] -or
                $script:RenderedCharacters[$CellIndex] -cne
                    $Character -or
                $script:RenderedColors[$CellIndex] -ne
                    [int]$Color
            )

            $script:RenderedCharacters[$CellIndex] =
                $Character

            $script:RenderedColors[$CellIndex] =
                [int]$Color

            $script:RenderedKnown[$CellIndex] =
                $true

            if (-not $Changed) {
                if ($RunText.Length -gt 0) {
                    Write-ConsoleRun `
                        -X $RunX `
                        -Y $Y `
                        -Text $RunText `
                        -Color $RunColor

                    $RunText = ''
                }

                continue
            }

            $CanAppend = (
                $RunText.Length -gt 0 -and
                $X -eq ($RunX + $RunText.Length) -and
                [int]$Color -eq [int]$RunColor
            )

            if (-not $CanAppend) {
                if ($RunText.Length -gt 0) {
                    Write-ConsoleRun `
                        -X $RunX `
                        -Y $Y `
                        -Text $RunText `
                        -Color $RunColor
                }

                $RunX = $X
                $RunColor = $Color
                $RunText = [string]$Character
            }
            else {
                $RunText += [string]$Character
            }
        }

        if ($RunText.Length -gt 0) {
            Write-ConsoleRun `
                -X $RunX `
                -Y $Y `
                -Text $RunText `
                -Color $RunColor
        }
    }

    Reset-PendingConsoleRedraw
}

function Invoke-ConsoleRedraw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Render
    )

    $IsRootRedraw = $script:RedrawDepth -eq 0

    if ($IsRootRedraw) {
        Reset-PendingConsoleRedraw
    }

    $script:RedrawDepth++

    try {
        & $Render
    }
    catch {
        $script:RedrawDepth--

        if ($IsRootRedraw) {
            Reset-PendingConsoleRedraw
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
    Reset-PendingConsoleRedraw
    Reset-ConsoleRenderCache
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

    if (
        $Y -lt 0 -or
        $Y -ge [Console]::BufferHeight -or
        $Y -ge $script:ConsoleHeight
    ) {
        return
    }

    if (
        $X -lt 0 -or
        $X -ge [Console]::BufferWidth -or
        $X -ge $script:ConsoleWidth
    ) {
        return
    }

    $AvailableWidth = [Math]::Min(
        [Console]::BufferWidth,
        $script:ConsoleWidth
    ) - $X

    if ($Text.Length -gt $AvailableWidth) {
        $Text = $Text.Substring(0, $AvailableWidth)
    }

    if ($script:RedrawDepth -gt 0) {
        for ($Index = 0; $Index -lt $Text.Length; $Index++) {
            $CellX = $X + $Index
            $CellIndex =
                ($Y * $script:ConsoleWidth) + $CellX

            $script:PendingCharacters[$CellIndex] =
                $Text[$Index]

            $script:PendingColors[$CellIndex] =
                [int]$Color

            $script:PendingSet[$CellIndex] =
                $true

            if ($CellX -lt $script:DirtyStart[$Y]) {
                $script:DirtyStart[$Y] = $CellX
            }

            if ($CellX -gt $script:DirtyEnd[$Y]) {
                $script:DirtyEnd[$Y] = $CellX
            }
        }

        return
    }

    [Console]::SetCursorPosition($X, $Y)
    [Console]::ForegroundColor = $Color
    [Console]::BackgroundColor =
        [ConsoleColor]::Black

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

function Draw-TextBox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y,

        [Parameter(Mandatory)]
        [ValidateRange(1, 60)]
        [int]$Width,

        [AllowEmptyString()]
        [string]$Value = '',

        [System.ConsoleColor]$Color =
            [System.ConsoleColor]::Gray,

        [bool]$Focused = $false
    )

    $DrawColor = if ($Focused) {
        [ConsoleColor]::White
    }
    else {
        $Color
    }

    $DisplayValue = $Value

    if ($DisplayValue.Length -gt $Width) {
        $DisplayValue =
            $DisplayValue.Substring(0, $Width)
    }

    Invoke-ConsoleRedraw {
        Write-At `
            -X $X `
            -Y $Y `
            -Text '[' `
            -Color $DrawColor

        Write-At `
            -X ($X + 1) `
            -Y $Y `
            -Text $DisplayValue.PadRight($Width) `
            -Color $DrawColor

        Write-At `
            -X ($X + $Width + 1) `
            -Y $Y `
            -Text ']' `
            -Color $DrawColor
    }
}

function Set-TextBoxCursor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y,

        [Parameter(Mandatory)]
        [ValidateRange(1, 60)]
        [int]$Width,

        [AllowEmptyString()]
        [string]$Value = '',

        [bool]$Visible = $true
    )

    if (-not $Visible) {
        [Console]::CursorVisible = $false
        return
    }

    $DisplayLength = [Math]::Min(
        $Value.Length,
        $Width
    )

    $CursorOffset = [Math]::Min(
        $DisplayLength,
        $Width - 1
    )

    [Console]::SetCursorPosition(
        $X + 1 + $CursorOffset,
        $Y
    )

    [Console]::CursorVisible = $true
}

function Test-PointInRect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$PointX,

        [Parameter(Mandatory)]
        [int]$PointY,

        [Parameter(Mandatory)]
        [int]$X,

        [Parameter(Mandatory)]
        [int]$Y,

        [Parameter(Mandatory)]
        [int]$Width,

        [ValidateRange(1, 100)]
        [int]$Height = 1
    )

    return (
        $PointX -ge $X -and
        $PointX -lt ($X + $Width) -and
        $PointY -ge $Y -and
        $PointY -lt ($Y + $Height)
    )
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

function Draw-ActionButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$BackButton,

        [Parameter(Mandatory)]
        [object]$ContinueButton,

        [AllowNull()]
        [string]$HoverName,

        [AllowNull()]
        [string]$PressedName,

        [bool]$ContinueEnabled
    )

    if ($PressedName -eq $BackButton.Name) {
        $BackStyle = 'Pressed'
    }
    elseif ($HoverName -eq $BackButton.Name) {
        $BackStyle = 'HoverBright'
    }
    else {
        $BackStyle = 'Normal'
    }

    if (-not $ContinueEnabled) {
        $ContinueStyle = 'Disabled'
    }
    elseif ($PressedName -eq $ContinueButton.Name) {
        $ContinueStyle = 'Pressed'
    }
    elseif ($HoverName -eq $ContinueButton.Name) {
        $ContinueStyle = 'HoverBright'
    }
    else {
        $ContinueStyle = 'Normal'
    }

    Draw-Button `
        -Button $BackButton `
        -Style $BackStyle

    Draw-Button `
        -Button $ContinueButton `
        -Style $ContinueStyle
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
    'Draw-TextBox'
    'Set-TextBoxCursor'
    'Test-PointInRect'
    'Clear-ConsoleScreen'
    'Invoke-ConsoleRedraw'
    'Draw-Frame'
    'Draw-Button'
    'Clear-Button'
    'Draw-Buttons'
    'Draw-ActionButtons'
    'Get-ButtonAt'
    'Set-Status'
)
