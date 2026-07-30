Set-StrictMode -Version Latest

function Get-TagCategorySkills {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$CategoryValue
    )

    if ($null -eq $CategoryValue) {
        return @()
    }

    if ($CategoryValue -is [System.Collections.IDictionary]) {
        foreach ($CandidateKey in @('Skills', 'SkillOrder', 'Members')) {
            if ($CategoryValue.Contains($CandidateKey)) {
                return @($CategoryValue[$CandidateKey])
            }
        }

        return @()
    }

    if ($CategoryValue -is [string]) {
        return @([string]$CategoryValue)
    }

    if ($CategoryValue -is [System.Collections.IEnumerable]) {
        return @($CategoryValue)
    }

    return @()
}

function Get-TagSkillSections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SkillData
    )

    $Layout = @(
        [pscustomobject]@{
            Name = 'Combat'
            X = 3
            HeaderY = 4
        }
        [pscustomobject]@{
            Name = 'Armor'
            X = 3
            HeaderY = 13
        }
        [pscustomobject]@{
            Name = 'Utility'
            X = 3
            HeaderY = 18
        }
        [pscustomobject]@{
            Name = 'Magic'
            X = 41
            HeaderY = 4
        }
        [pscustomobject]@{
            Name = 'Professions'
            X = 41
            HeaderY = 12
        }
    )

    $Sections = @()

    foreach ($LayoutEntry in $Layout) {
        if (-not $SkillData.Categories.ContainsKey($LayoutEntry.Name)) {
            throw "Skills.psd1 is missing category: $($LayoutEntry.Name)"
        }

        $CategorySkills = @(
            Get-TagCategorySkills `
                -CategoryValue $SkillData.Categories[$LayoutEntry.Name]
        )

        if ($CategorySkills.Count -eq 0) {
            throw "Skill category '$($LayoutEntry.Name)' contains no skills."
        }

        $Sections += [pscustomobject]@{
            Name = [string]$LayoutEntry.Name
            X = [int]$LayoutEntry.X
            HeaderY = [int]$LayoutEntry.HeaderY
            Skills = @($CategorySkills)
        }
    }

    $FlattenedSkills = @(
        $Sections |
            ForEach-Object { $_.Skills }
    )

    $UniqueSkills = @(
        $FlattenedSkills |
            Sort-Object -Unique
    )

    if ($FlattenedSkills.Count -ne $SkillData.SkillOrder.Count) {
        throw (
            'Categorized Tag Skills layout does not contain the expected ' +
            "number of skills. Expected $($SkillData.SkillOrder.Count), " +
            "found $($FlattenedSkills.Count)."
        )
    }

    if ($UniqueSkills.Count -ne $SkillData.SkillOrder.Count) {
        throw 'Categorized Tag Skills layout contains duplicate skills.'
    }

    foreach ($Skill in $SkillData.SkillOrder) {
        if ($UniqueSkills -notcontains $Skill) {
            throw "Categorized Tag Skills layout is missing skill: $Skill"
        }
    }

    return $Sections
}

function Get-TagSkillButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillSections
    )

    $Buttons = @()

    foreach ($Section in $SkillSections) {
        for ($Row = 0; $Row -lt $Section.Skills.Count; $Row++) {
            $Buttons += [pscustomobject]@{
                Skill = [string]$Section.Skills[$Row]
                Category = [string]$Section.Name
                X = [int]$Section.X
                Y = [int]$Section.HeaderY + 1 + $Row
                Width = 35
            }
        }
    }

    return $Buttons
}

function Test-TagPointInRect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$PointX,

        [Parameter(Mandatory = $true)]
        [int]$PointY,

        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y,

        [Parameter(Mandatory = $true)]
        [int]$Width,

        [int]$Height = 1
    )

    return (
        $PointX -ge $X -and
        $PointX -lt ($X + $Width) -and
        $PointY -ge $Y -and
        $PointY -lt ($Y + $Height)
    )
}

function Get-TagSkillTargetAt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillButtons,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ContinueButton,

        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y
    )

    foreach ($Button in $SkillButtons) {
        $InsideButton = Test-TagPointInRect `
            -PointX $X `
            -PointY $Y `
            -X $Button.X `
            -Y $Button.Y `
            -Width $Button.Width

        if ($InsideButton) {
            return "Skill:$($Button.Skill)"
        }
    }

    $ActionTarget = ConsoleUI\Get-ButtonAt `
        -Buttons @($BackButton, $ContinueButton) `
        -X $X `
        -Y $Y

    return $ActionTarget
}

function Get-TagSkillFromTarget {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Target
    )

    if (
        [string]::IsNullOrWhiteSpace($Target) -or
        -not $Target.StartsWith('Skill:')
    ) {
        return $null
    }

    return $Target.Split(':', 2)[1]
}

function Get-TagSkillValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Skill,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [string[]]$RacialSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    if ($RacialSkills -contains $Skill) {
        return [int]$GameRules.RacialProficiencyStart
    }

    if ($SelectedSkills -contains $Skill) {
        return [int]$GameRules.MinorTagSkillStart
    }

    return [int]$GameRules.SkillMinimum
}

function Get-TagSkillButtonColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Skill,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [bool]$Selected,

        [bool]$Locked,

        [bool]$SelectionFull
    )

    $Target = "Skill:$Skill"

    if ($Locked) {
        if ($HoverTarget -eq $Target) {
            return [ConsoleColor]::Yellow
        }

        return [ConsoleColor]::DarkYellow
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

    if ($SelectionFull) {
        return [ConsoleColor]::DarkGray
    }

    return [ConsoleColor]::Gray
}

function Get-TagSkillButtonText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Skill,

        [Parameter(Mandatory = $true)]
        [int]$Value,

        [Parameter(Mandatory = $true)]
        [int]$Width,

        [bool]$Selected,

        [bool]$Locked
    )

    if ($Locked) {
        $Marker = '[R]'
    }
    elseif ($Selected) {
        $Marker = '[X]'
    }
    else {
        $Marker = '[ ]'
    }

    $DisplaySkill = $Skill
    $SkillWidth = 17

    if ($DisplaySkill.Length -gt $SkillWidth) {
        $DisplaySkill = $DisplaySkill.Substring(0, $SkillWidth)
    }

    $Text = '{0} {1,-17} {2:000} / 100' -f
        $Marker,
        $DisplaySkill,
        $Value

    if ($Text.Length -gt $Width) {
        return $Text.Substring(0, $Width)
    }

    return $Text.PadRight($Width)
}

function Draw-TagSkillHeaders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillSections
    )

    foreach ($Section in $SkillSections) {
        ConsoleUI\Write-At `
            -X $Section.X `
            -Y $Section.HeaderY `
            -Text $Section.Name.ToUpperInvariant().PadRight(35) `
            -Color DarkYellow
    }
}

function Draw-TagSkillButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillButtons,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [string[]]$RacialSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    $SelectionFull = (
        $SelectedSkills.Count -ge
        [int]$GameRules.MinorTagSkillCount
    )

    foreach ($Button in $SkillButtons) {
        $Selected = $SelectedSkills -contains $Button.Skill
        $Locked = $RacialSkills -contains $Button.Skill

        $Value = Get-TagSkillValue `
            -Skill $Button.Skill `
            -SelectedSkills $SelectedSkills `
            -RacialSkills $RacialSkills `
            -GameRules $GameRules

        $Color = Get-TagSkillButtonColor `
            -Skill $Button.Skill `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -Selected $Selected `
            -Locked $Locked `
            -SelectionFull $SelectionFull

        $Text = Get-TagSkillButtonText `
            -Skill $Button.Skill `
            -Value $Value `
            -Width $Button.Width `
            -Selected $Selected `
            -Locked $Locked

        ConsoleUI\Write-At `
            -X $Button.X `
            -Y $Button.Y `
            -Text $Text `
            -Color $Color
    }
}

function Draw-TagSkillHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [string[]]$RacialSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget
    )

    ConsoleUI\Clear-TextLine -Y 25

    $HoveredSkill = Get-TagSkillFromTarget -Target $HoverTarget

    if ([string]::IsNullOrWhiteSpace($HoveredSkill)) {
        $HelpText = '[R] Racial 010 / 100   [X] Tagged 005 / 100   [ ] Available 000 / 100'
        $Color = [ConsoleColor]::DarkGray
    }
    elseif ($RacialSkills -contains $HoveredSkill) {
        $HelpText = (
            '{0}: racial proficiency, locked at {1:000} / 100.' -f
            $HoveredSkill,
            [int]$GameRules.RacialProficiencyStart
        )
        $Color = [ConsoleColor]::DarkYellow
    }
    elseif ($SelectedSkills -contains $HoveredSkill) {
        $HelpText = (
            '{0}: tagged at {1:000} / 100. Click again to remove the tag.' -f
            $HoveredSkill,
            [int]$GameRules.MinorTagSkillStart
        )
        $Color = [ConsoleColor]::Yellow
    }
    elseif (
        $SelectedSkills.Count -ge
        [int]$GameRules.MinorTagSkillCount
    ) {
        $HelpText = 'All three tags are assigned. Remove an [X] before choosing another skill.'
        $Color = [ConsoleColor]::DarkGray
    }
    else {
        $HelpText = (
            '{0}: click to tag this skill at {1:000} / 100.' -f
            $HoveredSkill,
            [int]$GameRules.MinorTagSkillStart
        )
        $Color = [ConsoleColor]::Gray
    }

    ConsoleUI\Write-Centered `
        -Y 25 `
        -Text $HelpText `
        -Color $Color
}

function Test-TagSkillsReady {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    return (
        $SelectedSkills.Count -eq
        [int]$GameRules.MinorTagSkillCount
    )
}

function Draw-TagActionButtons {
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

    if ($PressedTarget -eq 'BACK') {
        $BackStyle = 'Pressed'
    }
    elseif ($HoverTarget -eq 'BACK') {
        $BackStyle = 'HoverBright'
    }
    else {
        $BackStyle = 'Normal'
    }

    if (-not $CanContinue) {
        $ContinueStyle = 'Disabled'
    }
    elseif ($PressedTarget -eq 'CONTINUE') {
        $ContinueStyle = 'Pressed'
    }
    elseif ($HoverTarget -eq 'CONTINUE') {
        $ContinueStyle = 'HoverBright'
    }
    else {
        $ContinueStyle = 'Normal'
    }

    ConsoleUI\Draw-Button -Button $BackButton -Style $BackStyle
    ConsoleUI\Draw-Button -Button $ContinueButton -Style $ContinueStyle
}

function Draw-TagSkillStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    # Bottom status intentionally unused; progress is shown in the header.
    return
}
function Draw-TagSkillsScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillSections,

        [Parameter(Mandatory = $true)]
        [object[]]$SkillButtons,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ContinueButton,

        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [string[]]$RacialSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [switch]$ClearScreen
    )

    ConsoleUI\Invoke-ConsoleRedraw {
        if ($ClearScreen) {
            ConsoleUI\Clear-ConsoleScreen
        }
    
        ConsoleUI\Draw-Frame
        ConsoleUI\Write-Centered -Y 1 -Text 'TAG YOUR MINOR SKILLS' -Color DarkYellow
    
        $SummaryText = '{0} the {1}   |   TAG SKILLS: {2} / {3}' -f
            $CharacterDraft.Name,
            $CharacterDraft.Race,
            $SelectedSkills.Count,
            $GameRules.MinorTagSkillCount
    
        ConsoleUI\Write-Centered -Y 2 -Text $SummaryText -Color Gray
    
        Draw-TagSkillHeaders -SkillSections $SkillSections
    
        Draw-TagSkillButtons `
            -SkillButtons $SkillButtons `
            -SelectedSkills $SelectedSkills `
            -RacialSkills $RacialSkills `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget
    
        Draw-TagSkillHelp `
            -SelectedSkills $SelectedSkills `
            -RacialSkills $RacialSkills `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget
    
        $CanContinue = Test-TagSkillsReady `
            -SelectedSkills $SelectedSkills `
            -GameRules $GameRules
    
        Draw-TagActionButtons `
            -BackButton $BackButton `
            -ContinueButton $ContinueButton `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -CanContinue $CanContinue
    
        Draw-TagSkillStatus `
            -SelectedSkills $SelectedSkills `
            -GameRules $GameRules
    }
}

function Update-TagSkillsRendering {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillButtons,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ContinueButton,

        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [string[]]$RacialSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    ConsoleUI\Invoke-ConsoleRedraw {
        $SummaryText = '{0} the {1}   |   TAG SKILLS: {2} / {3}' -f
            $CharacterDraft.Name,
            $CharacterDraft.Race,
            $SelectedSkills.Count,
            $GameRules.MinorTagSkillCount
    
        ConsoleUI\Clear-TextLine -Y 2
        ConsoleUI\Write-Centered -Y 2 -Text $SummaryText -Color Gray
    
        Draw-TagSkillButtons `
            -SkillButtons $SkillButtons `
            -SelectedSkills $SelectedSkills `
            -RacialSkills $RacialSkills `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget
    
        Draw-TagSkillHelp `
            -SelectedSkills $SelectedSkills `
            -RacialSkills $RacialSkills `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget
    
        $CanContinue = Test-TagSkillsReady `
            -SelectedSkills $SelectedSkills `
            -GameRules $GameRules
    
        Draw-TagActionButtons `
            -BackButton $BackButton `
            -ContinueButton $ContinueButton `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -CanContinue $CanContinue
    
        Draw-TagSkillStatus `
            -SelectedSkills $SelectedSkills `
            -GameRules $GameRules
    }
}

function Set-CharacterDraftMinorSkills {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$SkillData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    if ($CharacterDraft.Skills -isnot [System.Collections.IDictionary]) {
        throw 'Character draft skill data is not writable.'
    }

    foreach ($Skill in $SkillData.SkillOrder) {
        if ($CharacterDraft.RacialProficiencies -contains $Skill) {
            $CharacterDraft.Skills[$Skill] = [int]$GameRules.RacialProficiencyStart
        }
        else {
            $CharacterDraft.Skills[$Skill] = [int]$GameRules.SkillMinimum
        }
    }

    foreach ($Skill in $SelectedSkills) {
        $CharacterDraft.Skills[$Skill] = [int]$GameRules.MinorTagSkillStart
    }

    $CharacterDraft.MinorTaggedSkills = @($SelectedSkills)

    return $CharacterDraft
}

function Show-CharacterCreationComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft
    )

    ConsoleUI\Clear-ConsoleScreen
    ConsoleUI\Draw-Frame
    ConsoleUI\Write-Centered -Y 1 -Text 'CHARACTER CREATION COMPLETE' -Color Yellow

    ConsoleUI\Write-At -X 7 -Y 4 -Text "Name:   $($CharacterDraft.Name)" -Color Gray
    ConsoleUI\Write-At -X 7 -Y 5 -Text "Race:   $($CharacterDraft.Race)" -Color Gray
    ConsoleUI\Write-At -X 7 -Y 6 -Text "Gender: $($CharacterDraft.Gender)" -Color Gray

    ConsoleUI\Write-At -X 7 -Y 9 -Text 'ATTRIBUTES' -Color DarkYellow

    $AttributeLayout = @(
        @('Strength', 11, 7)
        @('Intelligence', 12, 7)
        @('Wisdom', 13, 7)
        @('Agility', 11, 36)
        @('Fortitude', 12, 36)
        @('Charisma', 13, 36)
    )

    foreach ($Entry in $AttributeLayout) {
        $Attribute = [string]$Entry[0]
        $Y = [int]$Entry[1]
        $X = [int]$Entry[2]

        ConsoleUI\Write-At `
            -X $X `
            -Y $Y `
            -Text ('{0,-13} {1,2}' -f $Attribute, $CharacterDraft.Attributes[$Attribute]) `
            -Color Gray
    }

    ConsoleUI\Write-At -X 7 -Y 16 -Text 'RACIAL PROFICIENCIES' -Color DarkYellow
    ConsoleUI\Write-At -X 9 -Y 18 -Text ($CharacterDraft.RacialProficiencies -join ', ') -Color Yellow

    ConsoleUI\Write-At -X 7 -Y 20 -Text 'TAG SKILLS' -Color DarkYellow
    ConsoleUI\Write-At -X 9 -Y 22 -Text ($CharacterDraft.MinorTaggedSkills -join ', ') -Color Yellow

    ConsoleUI\Write-Centered `
        -Y 26 `
        -Text 'Press any key to return to the main menu...' `
        -Color DarkYellow

    ConsoleInput\Wait-ForAnyKey
}

function Invoke-TagSkillsScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RaceData,

        [Parameter(Mandatory = $true)]
        [hashtable]$SkillData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft
    )

    [Console]::CursorVisible = $false

    $SkillSections = @(
        Get-TagSkillSections -SkillData $SkillData
    )

    $SkillButtons = @(
        Get-TagSkillButtons -SkillSections $SkillSections
    )

    if ($SkillButtons.Count -ne $SkillData.SkillOrder.Count) {
        throw (
            'Tag Skills could not build one control per skill. ' +
            "Expected $($SkillData.SkillOrder.Count), found $($SkillButtons.Count)."
        )
    }

    $RacialSkills = @($CharacterDraft.RacialProficiencies)
    $SelectedSkills = @()

    foreach ($ExistingSkill in @($CharacterDraft.MinorTaggedSkills)) {
        $ValidExistingSkill =
            $SkillData.SkillOrder -contains $ExistingSkill -and
            $RacialSkills -notcontains $ExistingSkill -and
            $SelectedSkills -notcontains $ExistingSkill

        if (
            $ValidExistingSkill -and
            $SelectedSkills.Count -lt [int]$GameRules.MinorTagSkillCount
        ) {
            $SelectedSkills += [string]$ExistingSkill
        }
    }

    $BackButton = [pscustomobject]@{
        Name = 'BACK'
        Label = 'BACK'
        X = 3
        Y = 26
        Width = 22
    }

    $ContinueButton = [pscustomobject]@{
        Name = 'CONTINUE'
        Label = 'CONTINUE'
        X = 54
        Y = 26
        Width = 22
    }

    $HoverTarget = $null
    $PressedTarget = $null
    $LeftButtonDown = $false
    $InputHandle = [IntPtr]::Zero

    Draw-TagSkillsScreen `
        -SkillSections $SkillSections `
        -SkillButtons $SkillButtons `
        -BackButton $BackButton `
        -ContinueButton $ContinueButton `
        -CharacterDraft $CharacterDraft `
        -SelectedSkills $SelectedSkills `
        -RacialSkills $RacialSkills `
        -GameRules $GameRules `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget `
        -ClearScreen

    try {
        $InputHandle = ConsoleInput\Start-ConsoleMouseSession

        while ($true) {
            $Sample = ConsoleInput\Read-ConsoleMouseSample `
                -InputHandle $InputHandle `
                -TimeoutMilliseconds 120

            if (-not $Sample.HasEvent) {
                continue
            }

            $CurrentTarget = Get-TagSkillTargetAt `
                -SkillButtons $SkillButtons `
                -BackButton $BackButton `
                -ContinueButton $ContinueButton `
                -X $Sample.X `
                -Y $Sample.Y

            if ($CurrentTarget -ne $HoverTarget) {
                $HoverTarget = $CurrentTarget

                Update-TagSkillsRendering `
                    -SkillButtons $SkillButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -CharacterDraft $CharacterDraft `
                    -SelectedSkills $SelectedSkills `
                    -RacialSkills $RacialSkills `
                    -GameRules $GameRules `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget
            }

            $IsLeftButtonDown = ($Sample.ButtonState -band 0x0001) -ne 0

            if ($IsLeftButtonDown -and -not $LeftButtonDown) {
                $PressedTarget = $CurrentTarget

                Update-TagSkillsRendering `
                    -SkillButtons $SkillButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -CharacterDraft $CharacterDraft `
                    -SelectedSkills $SelectedSkills `
                    -RacialSkills $RacialSkills `
                    -GameRules $GameRules `
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

                if (-not [string]::IsNullOrWhiteSpace($ActivatedTarget)) {
                    $ActivatedSkill = Get-TagSkillFromTarget `
                        -Target $ActivatedTarget

                    if (-not [string]::IsNullOrWhiteSpace($ActivatedSkill)) {
                        if ($RacialSkills -notcontains $ActivatedSkill) {
                            if ($SelectedSkills -contains $ActivatedSkill) {
                                $SelectedSkills = @(
                                    $SelectedSkills |
                                        Where-Object { $_ -ne $ActivatedSkill }
                                )
                            }
                            elseif (
                                $SelectedSkills.Count -lt
                                [int]$GameRules.MinorTagSkillCount
                            ) {
                                $SelectedSkills += $ActivatedSkill
                            }
                        }
                    }
                    elseif ($ActivatedTarget -eq 'BACK') {
                        $CharacterDraft = Set-CharacterDraftMinorSkills `
                            -CharacterDraft $CharacterDraft `
                            -SelectedSkills $SelectedSkills `
                            -SkillData $SkillData `
                            -GameRules $GameRules

                        return [pscustomobject]@{
                            NextState = 'CHARACTER_CREATOR'
                            CharacterDraft = $CharacterDraft
                        }
                    }
                    elseif ($ActivatedTarget -eq 'CONTINUE') {
                        $Ready = Test-TagSkillsReady `
                            -SelectedSkills $SelectedSkills `
                            -GameRules $GameRules

                        if ($Ready) {
                            if ($InputHandle -ne [IntPtr]::Zero) {
                                ConsoleInput\Stop-ConsoleMouseSession `
                                    -InputHandle $InputHandle

                                $InputHandle = [IntPtr]::Zero
                            }

                            $CharacterDraft = Set-CharacterDraftMinorSkills `
                                -CharacterDraft $CharacterDraft `
                                -SelectedSkills $SelectedSkills `
                                -SkillData $SkillData `
                                -GameRules $GameRules

                            Show-CharacterCreationComplete `
                                -CharacterDraft $CharacterDraft

                            return [pscustomobject]@{
                                NextState = 'MAIN_MENU'
                                CharacterDraft = $CharacterDraft
                            }
                        }
                    }
                }

                Update-TagSkillsRendering `
                    -SkillButtons $SkillButtons `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -CharacterDraft $CharacterDraft `
                    -SelectedSkills $SelectedSkills `
                    -RacialSkills $RacialSkills `
                    -GameRules $GameRules `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget
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
    'Invoke-TagSkillsScreen'
)
