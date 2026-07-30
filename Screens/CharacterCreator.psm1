Set-StrictMode -Version Latest

function Get-CharacterCreatorRaceButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData
    )

    $Rows = @(3, 7, 11, 15, 19, 23)
    $Buttons =
        [System.Collections.Generic.List[object]]::new()

    for (
        $Index = 0;
        $Index -lt $RaceData.RaceOrder.Count;
        $Index++
    ) {
        $RaceId = $RaceData.RaceOrder[$Index]
        $Race = $RaceData.Races[$RaceId]

        [void]$Buttons.Add(
            [pscustomobject]@{
                Name = $RaceId
                Label =
                    $Race.DisplayName.ToUpperInvariant()

                X = 4
                Y = $Rows[$Index]
                Width = 20
            }
        )
    }

    return $Buttons.ToArray()
}

function Clear-CharacterCreatorPanel {
    [CmdletBinding()]
    param()

    for ($Y = 2; $Y -le 27; $Y++) {
        ConsoleUI\Write-At -X 29 -Y $Y -Text (' ' * 48)
    }
}

function Write-CreatorWrappedText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [int]$Width,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [System.ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    $Words = @($Text -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $CurrentLine = ''
    $CurrentY = $Y

    foreach ($Word in $Words) {
        if ([string]::IsNullOrWhiteSpace($CurrentLine)) {
            $Candidate = $Word
        }
        else {
            $Candidate = "$CurrentLine $Word"
        }

        if ($Candidate.Length -gt $Width) {
            ConsoleUI\Write-At -X $X -Y $CurrentY -Text $CurrentLine -Color $Color
            $CurrentY++
            $CurrentLine = $Word
        }
        else {
            $CurrentLine = $Candidate
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($CurrentLine)) {
        ConsoleUI\Write-At -X $X -Y $CurrentY -Text $CurrentLine -Color $Color
        $CurrentY++
    }

    return $CurrentY
}

function Get-CreatorTargetAt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$RaceButtons,

        [Parameter(Mandatory = $true)]
        [object[]]$ActionButtons,

        [Parameter(Mandatory = $true)]
        [string[]]$Attributes,

        [AllowNull()]
        [string]$SelectedRaceId,

        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y
    )

    $RaceTarget = ConsoleUI\Get-ButtonAt `
        -Buttons $RaceButtons `
        -X $X `
        -Y $Y

    if (-not [string]::IsNullOrWhiteSpace($RaceTarget)) {
        return "Race:$RaceTarget"
    }

    $ActionTarget = ConsoleUI\Get-ButtonAt `
        -Buttons $ActionButtons `
        -X $X `
        -Y $Y

    if (-not [string]::IsNullOrWhiteSpace($ActionTarget)) {
        return $ActionTarget
    }

    if ([string]::IsNullOrWhiteSpace($SelectedRaceId)) {
        return $null
    }

    if (
        ConsoleUI\Test-PointInRect `
            -PointX $X `
            -PointY $Y `
            -X 37 `
            -Y 6 `
            -Width 20
    ) {
        return 'Name'
    }

    if (
        ConsoleUI\Test-PointInRect `
            -PointX $X `
            -PointY $Y `
            -X 38 `
            -Y 8 `
            -Width 8
    ) {
        return 'Gender:Male'
    }

    if (
        ConsoleUI\Test-PointInRect `
            -PointX $X `
            -PointY $Y `
            -X 48 `
            -Y 8 `
            -Width 10
    ) {
        return 'Gender:Female'
    }

    for ($Index = 0; $Index -lt $Attributes.Count; $Index++) {
        $Attribute = $Attributes[$Index]
        $Row = 12 + $Index

        if (
            ConsoleUI\Test-PointInRect `
                -PointX $X `
                -PointY $Y `
                -X 30 `
                -Y $Row `
                -Width 5
        ) {
            return "Minus:$Attribute"
        }

        if (
            ConsoleUI\Test-PointInRect `
                -PointX $X `
                -PointY $Y `
                -X 59 `
                -Y $Row `
                -Width 5
        ) {
            return "Plus:$Attribute"
        }

        if (
            ConsoleUI\Test-PointInRect `
                -PointX $X `
                -PointY $Y `
                -X 37 `
                -Y $Row `
                -Width 20
        ) {
            return "Attribute:$Attribute"
        }
    }

    return $null
}

function Get-CreatorControlColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [bool]$Selected = $false,

        [bool]$Disabled = $false
    )

    if ($Disabled) {
        return [ConsoleColor]::DarkGray
    }

    if ($PressedTarget -eq $Target) {
        return [ConsoleColor]::White
    }

    if ($Selected) {
        return [ConsoleColor]::Yellow
    }

    if ($HoverTarget -eq $Target) {
        return [ConsoleColor]::DarkYellow
    }

    return [ConsoleColor]::Gray
}

function Draw-CreatorInlineButton {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [int]$Width,

        [Parameter(Mandatory = $true)]
        [System.ConsoleColor]$Color
    )

    $DisplayText = $Text
    if ($DisplayText.Length -gt $Width) {
        $DisplayText = $DisplayText.Substring(0, $Width)
    }

    ConsoleUI\Write-At -X $X -Y $Y -Text $DisplayText.PadRight($Width) -Color $Color
}


function Get-CreatorRaceIdFromTarget {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Target
    )

    if (
        [string]::IsNullOrWhiteSpace($Target) -or
        -not $Target.StartsWith('Race:')
    ) {
        return $null
    }

    return $Target.Split(':', 2)[1]
}

function Get-CreatorAttributeFromTarget {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Target
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        return $null
    }

    $SupportedPrefixes = @(
        'Minus:'
        'Plus:'
        'Attribute:'
    )

    foreach ($Prefix in $SupportedPrefixes) {
        if ($Target.StartsWith($Prefix)) {
            return $Target.Split(':', 2)[1]
        }
    }

    return $null
}

function Draw-CreatorRaceButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$RaceButtons,

        [AllowNull()]
        [string]$SelectedRaceId,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    $HoverRaceId = Get-CreatorRaceIdFromTarget -Target $HoverTarget
    $PressedRaceId = Get-CreatorRaceIdFromTarget -Target $PressedTarget

    ConsoleUI\Draw-Buttons `
        -Buttons $RaceButtons `
        -HoverName $HoverRaceId `
        -PressedName $PressedRaceId `
        -SelectedName $SelectedRaceId `
        -Pulse $false
}

function Clear-CreatorAttributeDescription {
    [CmdletBinding()]
    param()

    for ($Y = 19; $Y -le 22; $Y++) {
        ConsoleUI\Write-At -X 30 -Y $Y -Text (' ' * 44)
    }
}

function Draw-CreatorRacePreview {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$RaceId,

        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    Clear-CharacterCreatorPanel

    if ([string]::IsNullOrWhiteSpace($RaceId)) {
        ConsoleUI\Write-At -X 30 -Y 4 -Text 'CHOOSE YOUR RACE' -Color Yellow

        $PreviewText = 'Move the mouse over a race to examine its heritage, favored attribute, starting skills, and base attributes.'
        [void](Write-CreatorWrappedText -X 30 -Y 7 -Width 44 -Text $PreviewText -Color Gray)

        ConsoleUI\Write-At -X 30 -Y 18 -Text 'Click a race to select it.' -Color DarkYellow
        return
    }

    $Race = $RaceData.Races[$RaceId]

    ConsoleUI\Write-At -X 30 -Y 2 -Text $Race.DisplayName.ToUpperInvariant() -Color Yellow
    [void](Write-CreatorWrappedText -X 30 -Y 4 -Width 44 -Text $Race.Description -Color Gray)

    ConsoleUI\Write-At -X 30 -Y 10 -Text "Favored: $($Race.FavoredAttribute)" -Color DarkYellow
    ConsoleUI\Write-At -X 30 -Y 12 -Text 'Starting Proficiencies:' -Color DarkGray
    ConsoleUI\Write-At -X 32 -Y 13 -Text ($Race.Proficiencies -join ', ') -Color Gray
    ConsoleUI\Write-At -X 30 -Y 16 -Text 'BASE ATTRIBUTES' -Color DarkGray

    $Base = $Race.BaseAttributes

    $FirstLine = 'STR {0,2}   INT {1,2}   WIS {2,2}' -f $Base.Strength, $Base.Intelligence, $Base.Wisdom
    $SecondLine = 'AGI {0,2}   FOR {1,2}   CHA {2,2}' -f $Base.Agility, $Base.Fortitude, $Base.Charisma

    ConsoleUI\Write-At -X 30 -Y 18 -Text $FirstLine -Color Gray
    ConsoleUI\Write-At -X 30 -Y 19 -Text $SecondLine -Color Gray
    ConsoleUI\Write-At -X 30 -Y 22 -Text 'Click this race to select it.' -Color DarkYellow
}

function Test-CharacterCreatorReady {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$SelectedRaceId,

        [AllowEmptyString()]
        [string]$CharacterName,

        [AllowNull()]
        [string]$Gender,

        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining
    )

    return (
        -not [string]::IsNullOrWhiteSpace($SelectedRaceId) -and
        -not [string]::IsNullOrWhiteSpace($CharacterName) -and
        -not [string]::IsNullOrWhiteSpace($Gender) -and
        $PointsRemaining -eq 0
    )
}

function Get-CharacterCreatorStatus {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$SelectedRaceId,

        [AllowEmptyString()]
        [string]$CharacterName,

        [AllowNull()]
        [string]$Gender,

        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining,

        [AllowNull()]
        [string]$HoverTarget
    )

    if ($HoverTarget -eq 'Name') {
        return 'Click the name field to type. Mouse controls stay active.'
    }

    if ([string]::IsNullOrWhiteSpace($SelectedRaceId)) {
        return 'Choose a race.'
    }

    if ([string]::IsNullOrWhiteSpace($CharacterName)) {
        return 'Click the name field and enter a name.'
    }

    if ([string]::IsNullOrWhiteSpace($Gender)) {
        return 'Select a gender.'
    }

    if ($PointsRemaining -gt 0) {
        return "Spend the remaining $PointsRemaining attribute point(s)."
    }

    return 'Your adventurer is ready.'
}

function Draw-CreatorNameControl {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$CharacterName,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [bool]$IsFocused = $false
    )

    $NameSelected =
        -not [string]::IsNullOrWhiteSpace(
            $CharacterName
        )

    $NameColor = Get-CreatorControlColor `
        -Target 'Name' `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget `
        -Selected $NameSelected

    ConsoleUI\Draw-TextBox `
        -X 36 `
        -Y 6 `
        -Width 20 `
        -Value $CharacterName `
        -Color $NameColor `
        -Focused $IsFocused
}

function Draw-CreatorGenderControls {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Gender,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    $MaleColor = Get-CreatorControlColor `
        -Target 'Gender:Male' `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget `
        -Selected ($Gender -eq 'Male')

    $FemaleColor = Get-CreatorControlColor `
        -Target 'Gender:Female' `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget `
        -Selected ($Gender -eq 'Female')

    Draw-CreatorInlineButton -X 38 -Y 8 -Text '[ MALE ]' -Width 8 -Color $MaleColor
    Draw-CreatorInlineButton -X 48 -Y 8 -Text '[ FEMALE ]' -Width 10 -Color $FemaleColor
}

function Draw-CreatorPointsSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining
    )

    if ($PointsRemaining -eq 0) {
        $PointsColor = [ConsoleColor]::Yellow
    }
    else {
        $PointsColor = [ConsoleColor]::DarkYellow
    }

    $PointsText = "CREATION POINTS REMAINING: $PointsRemaining"
    ConsoleUI\Write-At -X 30 -Y 10 -Text $PointsText.PadRight(40) -Color $PointsColor
}

function Draw-CreatorAttributeRows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedRaceId,

        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$AddedAttributes,

        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    $Race = $RaceData.Races[$SelectedRaceId]

    for ($Index = 0; $Index -lt $GameRules.Attributes.Count; $Index++) {
        $Attribute = $GameRules.Attributes[$Index]
        $Row = 12 + $Index
        $BaseValue = [int]$Race.BaseAttributes[$Attribute]
        $AddedValue = [int]$AddedAttributes[$Attribute]
        $TotalValue = $BaseValue + $AddedValue

        $MinusTarget = "Minus:$Attribute"
        $PlusTarget = "Plus:$Attribute"
        $MinusDisabled = $AddedValue -le 0
        $PlusDisabled = $PointsRemaining -le 0

        $MinusColor = Get-CreatorControlColor `
            -Target $MinusTarget `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -Disabled $MinusDisabled

        $PlusColor = Get-CreatorControlColor `
            -Target $PlusTarget `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -Disabled $PlusDisabled

        Draw-CreatorInlineButton -X 30 -Y $Row -Text '[ - ]' -Width 5 -Color $MinusColor

        if ($Attribute -eq $Race.FavoredAttribute) {
            $AttributeColor = [ConsoleColor]::DarkYellow
        }
        else {
            $AttributeColor = [ConsoleColor]::Gray
        }

        ConsoleUI\Write-At -X 37 -Y $Row -Text $Attribute.PadRight(13) -Color $AttributeColor

        if ($AddedValue -gt 0) {
            $ValueColor = [ConsoleColor]::Yellow
            $AddedDisplay = "(+$AddedValue)"
        }
        else {
            $ValueColor = [ConsoleColor]::Gray
            $AddedDisplay = '    '
        }

        ConsoleUI\Write-At -X 53 -Y $Row -Text ('{0,3}' -f $TotalValue) -Color $ValueColor
        Draw-CreatorInlineButton -X 59 -Y $Row -Text '[ + ]' -Width 5 -Color $PlusColor
        ConsoleUI\Write-At -X 67 -Y $Row -Text $AddedDisplay.PadRight(5) -Color DarkYellow
    }
}

function Draw-CreatorAttributeDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget
    )

    Clear-CreatorAttributeDescription

    $HoveredAttribute = Get-CreatorAttributeFromTarget -Target $HoverTarget

    if ([string]::IsNullOrWhiteSpace($HoveredAttribute)) {
        return
    }

    if (-not $GameRules.AttributeDescriptions.ContainsKey($HoveredAttribute)) {
        return
    }

    ConsoleUI\Write-At -X 30 -Y 19 -Text "${HoveredAttribute}:" -Color DarkYellow

    [void](
        Write-CreatorWrappedText `
            -X 30 `
            -Y 20 `
            -Width 44 `
            -Text $GameRules.AttributeDescriptions[$HoveredAttribute] `
            -Color DarkGray
    )
}

function Draw-CreatorCharacterSheet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedRaceId,

        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$AddedAttributes,

        [AllowEmptyString()]
        [string]$CharacterName,

        [AllowNull()]
        [string]$Gender,

        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [bool]$NameFocused = $false
    )

    Clear-CharacterCreatorPanel

    $Race = $RaceData.Races[$SelectedRaceId]

    ConsoleUI\Write-At -X 30 -Y 2 -Text $Race.DisplayName.ToUpperInvariant() -Color Yellow
    ConsoleUI\Write-At -X 30 -Y 3 -Text "Favored: $($Race.FavoredAttribute)" -Color DarkYellow
    ConsoleUI\Write-At -X 30 -Y 4 -Text ($Race.Proficiencies -join ', ') -Color Gray
    ConsoleUI\Write-At -X 30 -Y 6 -Text 'Name:' -Color DarkGray
    ConsoleUI\Write-At -X 30 -Y 8 -Text 'Gender:' -Color DarkGray

    Draw-CreatorNameControl `
        -CharacterName $CharacterName `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget `
        -IsFocused $NameFocused

    Draw-CreatorGenderControls `
        -Gender $Gender `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget

    Draw-CreatorPointsSummary -PointsRemaining $PointsRemaining

    Draw-CreatorAttributeRows `
        -SelectedRaceId $SelectedRaceId `
        -RaceData $RaceData `
        -GameRules $GameRules `
        -AddedAttributes $AddedAttributes `
        -PointsRemaining $PointsRemaining `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget

    Draw-CreatorAttributeDescription `
        -GameRules $GameRules `
        -HoverTarget $HoverTarget
}

function Draw-CreatorActionButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ContinueButton,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [bool]$CanContinue
    )

    ConsoleUI\Draw-ActionButtons `
        -BackButton $BackButton `
        -ContinueButton $ContinueButton `
        -HoverName $HoverTarget `
        -PressedName $PressedTarget `
        -ContinueEnabled $CanContinue
}

function Draw-CreatorStatus {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$SelectedRaceId,

        [AllowEmptyString()]
        [string]$CharacterName,

        [AllowNull()]
        [string]$Gender,

        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining,

        [AllowNull()]
        [string]$HoverTarget
    )

    $CanContinue = Test-CharacterCreatorReady `
        -SelectedRaceId $SelectedRaceId `
        -CharacterName $CharacterName `
        -Gender $Gender `
        -PointsRemaining $PointsRemaining

    $Status = Get-CharacterCreatorStatus `
        -SelectedRaceId $SelectedRaceId `
        -CharacterName $CharacterName `
        -Gender $Gender `
        -PointsRemaining $PointsRemaining `
        -HoverTarget $HoverTarget

    if ($CanContinue) {
        $StatusColor = [ConsoleColor]::Yellow
    }
    else {
        $StatusColor = [ConsoleColor]::DarkYellow
    }

    ConsoleUI\Set-Status -Text $Status -Color $StatusColor
}

function Update-CreatorInteractiveRendering {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$RaceButtons,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ContinueButton,

        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$AddedAttributes,

        [AllowNull()]
        [string]$SelectedRaceId,

        [AllowEmptyString()]
        [string]$CharacterName,

        [AllowNull()]
        [string]$Gender,

        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [bool]$NameFocused = $false,

        [AllowNull()]
        [string]$PreviousHoverTarget,

        [switch]$RefreshPreview
    )

    ConsoleUI\Invoke-ConsoleRedraw {
        Draw-CreatorRaceButtons `
            -RaceButtons $RaceButtons `
            -SelectedRaceId $SelectedRaceId `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget
    
        if ([string]::IsNullOrWhiteSpace($SelectedRaceId)) {
            if ($RefreshPreview) {
                $HoverRaceId = Get-CreatorRaceIdFromTarget -Target $HoverTarget
    
                Draw-CreatorRacePreview `
                    -RaceId $HoverRaceId `
                    -RaceData $RaceData `
                    -GameRules $GameRules
            }
        }
        else {
            Draw-CreatorNameControl `
                -CharacterName $CharacterName `
                -HoverTarget $HoverTarget `
                -PressedTarget $PressedTarget `
                -IsFocused $NameFocused
    
            Draw-CreatorGenderControls `
                -Gender $Gender `
                -HoverTarget $HoverTarget `
                -PressedTarget $PressedTarget
    
            Draw-CreatorPointsSummary -PointsRemaining $PointsRemaining
    
            Draw-CreatorAttributeRows `
                -SelectedRaceId $SelectedRaceId `
                -RaceData $RaceData `
                -GameRules $GameRules `
                -AddedAttributes $AddedAttributes `
                -PointsRemaining $PointsRemaining `
                -HoverTarget $HoverTarget `
                -PressedTarget $PressedTarget
    
            $PreviousHoveredAttribute = Get-CreatorAttributeFromTarget `
                -Target $PreviousHoverTarget
    
            $CurrentHoveredAttribute = Get-CreatorAttributeFromTarget `
                -Target $HoverTarget
    
            if ($PreviousHoveredAttribute -ne $CurrentHoveredAttribute) {
                Draw-CreatorAttributeDescription `
                    -GameRules $GameRules `
                    -HoverTarget $HoverTarget
            }
        }
    
        $CanContinue = Test-CharacterCreatorReady `
            -SelectedRaceId $SelectedRaceId `
            -CharacterName $CharacterName `
            -Gender $Gender `
            -PointsRemaining $PointsRemaining
    
        Draw-CreatorActionButtons `
            -BackButton $BackButton `
            -ContinueButton $ContinueButton `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -CanContinue $CanContinue
    
        Draw-CreatorStatus `
            -SelectedRaceId $SelectedRaceId `
            -CharacterName $CharacterName `
            -Gender $Gender `
            -PointsRemaining $PointsRemaining `
            -HoverTarget $HoverTarget
    }
}

function Draw-CharacterCreatorScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$RaceButtons,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ContinueButton,

        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$AddedAttributes,

        [AllowNull()]
        [string]$SelectedRaceId,

        [AllowEmptyString()]
        [string]$CharacterName,

        [AllowNull()]
        [string]$Gender,

        [Parameter(Mandatory = $true)]
        [int]$PointsRemaining,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [bool]$NameFocused = $false,

        [switch]$ClearScreen
    )

    ConsoleUI\Invoke-ConsoleRedraw {
        if ($ClearScreen) {
            ConsoleUI\Clear-ConsoleScreen
        }
    
        ConsoleUI\Draw-Frame
        ConsoleUI\Write-Centered -Y 1 -Text 'CREATE YOUR ADVENTURER' -Color DarkYellow
    
        Draw-CreatorRaceButtons `
            -RaceButtons $RaceButtons `
            -SelectedRaceId $SelectedRaceId `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget
    
        if ([string]::IsNullOrWhiteSpace($SelectedRaceId)) {
            $HoverRaceId = Get-CreatorRaceIdFromTarget -Target $HoverTarget
    
            Draw-CreatorRacePreview `
                -RaceId $HoverRaceId `
                -RaceData $RaceData `
                -GameRules $GameRules
        }
        else {
            Draw-CreatorCharacterSheet `
                -SelectedRaceId $SelectedRaceId `
                -RaceData $RaceData `
                -GameRules $GameRules `
                -AddedAttributes $AddedAttributes `
                -CharacterName $CharacterName `
                -Gender $Gender `
                -PointsRemaining $PointsRemaining `
                -HoverTarget $HoverTarget `
                -PressedTarget $PressedTarget `
                -NameFocused $NameFocused
        }
    
        $CanContinue = Test-CharacterCreatorReady `
            -SelectedRaceId $SelectedRaceId `
            -CharacterName $CharacterName `
            -Gender $Gender `
            -PointsRemaining $PointsRemaining
    
        Draw-CreatorActionButtons `
            -BackButton $BackButton `
            -ContinueButton $ContinueButton `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -CanContinue $CanContinue
    
        Draw-CreatorStatus `
            -SelectedRaceId $SelectedRaceId `
            -CharacterName $CharacterName `
            -Gender $Gender `
            -PointsRemaining $PointsRemaining `
            -HoverTarget $HoverTarget
    }
}

function New-CharacterDraft {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedRaceId,

        [Parameter(Mandatory = $true)]
        [string]$CharacterName,

        [Parameter(Mandatory = $true)]
        [string]$Gender,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$AddedAttributes,

        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$SkillData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    $Race = $RaceData.Races[$SelectedRaceId]

    $BaseAttributes = [ordered]@{}
    $AddedAttributeCopy = [ordered]@{}
    $FinalAttributes = [ordered]@{}

    foreach ($Attribute in $GameRules.Attributes) {
        $BaseValue = [int]$Race.BaseAttributes[$Attribute]
        $AddedValue = [int]$AddedAttributes[$Attribute]

        $BaseAttributes[$Attribute] = $BaseValue
        $AddedAttributeCopy[$Attribute] = $AddedValue
        $FinalAttributes[$Attribute] = $BaseValue + $AddedValue
    }

    $StartingSkills = [ordered]@{}
    foreach ($Skill in $SkillData.SkillOrder) {
        $StartingSkills[$Skill] = [int]$GameRules.SkillMinimum
    }

    foreach ($Proficiency in $Race.Proficiencies) {
        $StartingSkills[$Proficiency] = [int]$GameRules.RacialProficiencyStart
    }

    return [pscustomobject]@{
        Name = $CharacterName
        Gender = $Gender
        RaceId = $SelectedRaceId
        Race = $Race.DisplayName
        FavoredAttribute = $Race.FavoredAttribute
        BaseAttributes = $BaseAttributes
        AddedAttributes = $AddedAttributeCopy
        Attributes = $FinalAttributes
        RacialProficiencies = @($Race.Proficiencies)
        MinorTaggedSkills = @()
        Skills = $StartingSkills
    }
}

function Invoke-CharacterCreatorScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$SkillData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [object]$ExistingDraft
    )

    [Console]::CursorVisible = $false

    $RaceButtons = @(
        Get-CharacterCreatorRaceButtons `
            -RaceData $RaceData
    )

    $BackButton = [pscustomobject]@{
        Name = 'BACK'
        Label = 'BACK'
        X = 30
        Y = 24
        Width = 18
    }

    $ContinueButton = [pscustomobject]@{
        Name = 'CONTINUE'
        Label = 'CONTINUE'
        X = 50
        Y = 24
        Width = 26
    }

    $ActionButtons = @(
        $BackButton
        $ContinueButton
    )

    $SelectedRaceId = $null
    $CharacterName = ''
    $Gender = $null
    $AddedAttributes = [ordered]@{}
    $SpentAttributePoints = 0

    foreach ($Attribute in $GameRules.Attributes) {
        $AddedValue = 0

        if (
            $null -ne $ExistingDraft -and
            $null -ne $ExistingDraft.AddedAttributes -and
            $ExistingDraft.AddedAttributes -is [System.Collections.IDictionary] -and
            $ExistingDraft.AddedAttributes.Contains(
                $Attribute
            )
        ) {
            $AddedValue =
                [int]$ExistingDraft.AddedAttributes[
                    $Attribute
                ]
        }

        $AddedAttributes[$Attribute] = $AddedValue
        $SpentAttributePoints += $AddedValue
    }

    if ($null -ne $ExistingDraft) {
        $SelectedRaceId =
            [string]$ExistingDraft.RaceId

        $CharacterName =
            [string]$ExistingDraft.Name

        $Gender =
            [string]$ExistingDraft.Gender
    }

    $PointsRemaining = [Math]::Max(
        0,
        [int]$GameRules.CharacterCreation.SpendableAttributePoints -
        $SpentAttributePoints
    )

    $NameMaximumLength =
        [int]$GameRules.CharacterCreation.NameMaximumLength

    $NameInputState =
        ConsoleInput\New-ConsoleTextBoxState `
            -InitialValue $CharacterName `
            -MaximumLength $NameMaximumLength `
            -AllowedCharacterPattern (
                '^[A-Za-z0-9 ''\-]$'
            )

    $NameFocused = $false
    $HoverTarget = $null
    $PressedTarget = $null
    $LeftButtonDown = $false
    $InputHandle = [IntPtr]::Zero

    Draw-CharacterCreatorScreen `
        -RaceButtons $RaceButtons `
        -BackButton $BackButton `
        -ContinueButton $ContinueButton `
        -RaceData $RaceData `
        -GameRules $GameRules `
        -AddedAttributes $AddedAttributes `
        -SelectedRaceId $SelectedRaceId `
        -CharacterName $CharacterName `
        -Gender $Gender `
        -PointsRemaining $PointsRemaining `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget `
        -NameFocused $NameFocused `
        -ClearScreen

    try {
        $InputHandle =
            ConsoleInput\Start-ConsoleMouseSession

        while ($true) {
            $Sample =
                ConsoleInput\Read-ConsoleInputSample `
                    -InputHandle $InputHandle `
                    -TimeoutMilliseconds 120

            if (-not $Sample.HasEvent) {
                continue
            }

            if ($Sample.IsKeyEvent) {
                if (-not $NameFocused) {
                    continue
                }

                $EditResult =
                    ConsoleInput\Update-ConsoleTextBoxState `
                        -State $NameInputState `
                        -InputSample $Sample

                if (
                    -not $EditResult.Changed -and
                    -not $EditResult.Completed
                ) {
                    continue
                }

                $CharacterName =
                    [string]$EditResult.Value

                if ($EditResult.Completed) {
                    $NameFocused = $false
                }

                Update-CreatorInteractiveRendering `
                    -RaceButtons $RaceButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -RaceData $RaceData `
                    -GameRules $GameRules `
                    -AddedAttributes $AddedAttributes `
                    -SelectedRaceId $SelectedRaceId `
                    -CharacterName $CharacterName `
                    -Gender $Gender `
                    -PointsRemaining $PointsRemaining `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget `
                    -NameFocused $NameFocused `
                    -PreviousHoverTarget $HoverTarget

                ConsoleUI\Set-TextBoxCursor `
                    -X 36 `
                    -Y 6 `
                    -Width 20 `
                    -Value $CharacterName `
                    -Visible $NameFocused

                continue
            }

            if (-not $Sample.IsMouseEvent) {
                continue
            }

            $CurrentTarget = Get-CreatorTargetAt `
                -RaceButtons $RaceButtons `
                -ActionButtons $ActionButtons `
                -Attributes $GameRules.Attributes `
                -SelectedRaceId $SelectedRaceId `
                -X $Sample.X `
                -Y $Sample.Y

            if ($CurrentTarget -ne $HoverTarget) {
                $PreviousHoverTarget = $HoverTarget
                $HoverTarget = $CurrentTarget

                Update-CreatorInteractiveRendering `
                    -RaceButtons $RaceButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -RaceData $RaceData `
                    -GameRules $GameRules `
                    -AddedAttributes $AddedAttributes `
                    -SelectedRaceId $SelectedRaceId `
                    -CharacterName $CharacterName `
                    -Gender $Gender `
                    -PointsRemaining $PointsRemaining `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget `
                    -NameFocused $NameFocused `
                    -PreviousHoverTarget $PreviousHoverTarget `
                    -RefreshPreview
            }

            $IsLeftButtonDown =
                ($Sample.ButtonState -band 0x0001) -ne 0

            if (
                $IsLeftButtonDown -and
                -not $LeftButtonDown
            ) {
                if (
                    $NameFocused -and
                    $CurrentTarget -ne 'Name'
                ) {
                    $CharacterName =
                        ConsoleInput\Complete-ConsoleTextBoxState `
                            -State $NameInputState

                    $NameFocused = $false
                }

                $PressedTarget = $CurrentTarget

                Update-CreatorInteractiveRendering `
                    -RaceButtons $RaceButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -RaceData $RaceData `
                    -GameRules $GameRules `
                    -AddedAttributes $AddedAttributes `
                    -SelectedRaceId $SelectedRaceId `
                    -CharacterName $CharacterName `
                    -Gender $Gender `
                    -PointsRemaining $PointsRemaining `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget `
                    -NameFocused $NameFocused `
                    -PreviousHoverTarget $HoverTarget
            }
            elseif (
                -not $IsLeftButtonDown -and
                $LeftButtonDown
            ) {
                $ReleasedTarget = $CurrentTarget
                $ActivatedTarget = $null
                $RaceSelectionChanged = $false

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        $PressedTarget
                    ) -and
                    $ReleasedTarget -eq $PressedTarget
                ) {
                    $ActivatedTarget = $PressedTarget
                }

                $PressedTarget = $null

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        $ActivatedTarget
                    )
                ) {
                    if (
                        $ActivatedTarget.StartsWith('Race:')
                    ) {
                        $SelectedRaceId =
                            $ActivatedTarget.Split(
                                ':',
                                2
                            )[1]

                        $RaceSelectionChanged = $true
                    }
                    elseif ($ActivatedTarget -eq 'Name') {
                        if (-not $NameFocused) {
                            $NameInputState =
                                ConsoleInput\New-ConsoleTextBoxState `
                                    -InitialValue $CharacterName `
                                    -MaximumLength $NameMaximumLength `
                                    -AllowedCharacterPattern (
                                        '^[A-Za-z0-9 ''\-]$'
                                    )
                        }

                        $NameFocused = $true
                    }
                    elseif (
                        $ActivatedTarget -eq
                            'Gender:Male'
                    ) {
                        $Gender = 'Male'
                    }
                    elseif (
                        $ActivatedTarget -eq
                            'Gender:Female'
                    ) {
                        $Gender = 'Female'
                    }
                    elseif (
                        $ActivatedTarget.StartsWith('Plus:')
                    ) {
                        $Attribute =
                            $ActivatedTarget.Split(
                                ':',
                                2
                            )[1]

                        if ($PointsRemaining -gt 0) {
                            $AddedAttributes[$Attribute] =
                                [int]$AddedAttributes[
                                    $Attribute
                                ] + 1

                            $PointsRemaining--
                        }
                    }
                    elseif (
                        $ActivatedTarget.StartsWith(
                            'Minus:'
                        )
                    ) {
                        $Attribute =
                            $ActivatedTarget.Split(
                                ':',
                                2
                            )[1]

                        if (
                            [int]$AddedAttributes[
                                $Attribute
                            ] -gt 0
                        ) {
                            $AddedAttributes[$Attribute] =
                                [int]$AddedAttributes[
                                    $Attribute
                                ] - 1

                            $PointsRemaining++
                        }
                    }
                    elseif ($ActivatedTarget -eq 'BACK') {
                        return [pscustomobject]@{
                            NextState = 'MAIN_MENU'
                            CharacterDraft = $null
                        }
                    }
                    elseif (
                        $ActivatedTarget -eq 'CONTINUE'
                    ) {
                        $Ready =
                            Test-CharacterCreatorReady `
                                -SelectedRaceId (
                                    $SelectedRaceId
                                ) `
                                -CharacterName (
                                    $CharacterName
                                ) `
                                -Gender $Gender `
                                -PointsRemaining (
                                    $PointsRemaining
                                )

                        if ($Ready) {
                            $CharacterDraft =
                                New-CharacterDraft `
                                    -SelectedRaceId (
                                        $SelectedRaceId
                                    ) `
                                    -CharacterName (
                                        $CharacterName
                                    ) `
                                    -Gender $Gender `
                                    -AddedAttributes (
                                        $AddedAttributes
                                    ) `
                                    -RaceData $RaceData `
                                    -SkillData $SkillData `
                                    -GameRules $GameRules

                            return [pscustomobject]@{
                                NextState = 'TAG_SKILLS'
                                CharacterDraft =
                                    $CharacterDraft
                            }
                        }
                    }
                }

                if ($RaceSelectionChanged) {
                    Draw-CharacterCreatorScreen `
                        -RaceButtons $RaceButtons `
                        -BackButton $BackButton `
                        -ContinueButton $ContinueButton `
                        -RaceData $RaceData `
                        -GameRules $GameRules `
                        -AddedAttributes $AddedAttributes `
                        -SelectedRaceId $SelectedRaceId `
                        -CharacterName $CharacterName `
                        -Gender $Gender `
                        -PointsRemaining $PointsRemaining `
                        -HoverTarget $HoverTarget `
                        -PressedTarget $PressedTarget `
                        -NameFocused $NameFocused
                }
                else {
                    Update-CreatorInteractiveRendering `
                        -RaceButtons $RaceButtons `
                        -BackButton $BackButton `
                        -ContinueButton $ContinueButton `
                        -RaceData $RaceData `
                        -GameRules $GameRules `
                        -AddedAttributes $AddedAttributes `
                        -SelectedRaceId $SelectedRaceId `
                        -CharacterName $CharacterName `
                        -Gender $Gender `
                        -PointsRemaining $PointsRemaining `
                        -HoverTarget $HoverTarget `
                        -PressedTarget $PressedTarget `
                        -NameFocused $NameFocused `
                        -PreviousHoverTarget $HoverTarget
                }
            }

            $LeftButtonDown = $IsLeftButtonDown

            ConsoleUI\Set-TextBoxCursor `
                -X 36 `
                -Y 6 `
                -Width 20 `
                -Value $CharacterName `
                -Visible $NameFocused
        }
    }
    finally {
        [Console]::CursorVisible = $false

        if ($InputHandle -ne [IntPtr]::Zero) {
            ConsoleInput\Stop-ConsoleMouseSession `
                -InputHandle $InputHandle
        }
    }
}

Export-ModuleMember -Function @(
    'Invoke-CharacterCreatorScreen'
)
