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

    $Buttons =
        [System.Collections.Generic.List[object]]::new()

    foreach ($Section in $SkillSections) {
        for (
            $Row = 0;
            $Row -lt $Section.Skills.Count;
            $Row++
        ) {
            [void]$Buttons.Add(
                [pscustomobject]@{
                    Skill =
                        [string]$Section.Skills[$Row]

                    Category = [string]$Section.Name
                    X = [int]$Section.X
                    Y = [int]$Section.HeaderY + 1 + $Row
                    Width = 35
                }
            )
        }
    }

    return $Buttons.ToArray()
}

function Get-TagSkillTargetAt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillButtons,

        [Parameter(Mandatory = $true)]
        [object[]]$ActionButtons,

        [Parameter(Mandatory = $true)]
        [int]$X,

        [Parameter(Mandatory = $true)]
        [int]$Y
    )

    foreach ($Button in $SkillButtons) {
        if (
            ConsoleUI\Test-PointInRect `
                -PointX $X `
                -PointY $Y `
                -X $Button.X `
                -Y $Button.Y `
                -Width $Button.Width
        ) {
            return "Skill:$($Button.Skill)"
        }
    }

    return ConsoleUI\Get-ButtonAt `
        -Buttons $ActionButtons `
        -X $X `
        -Y $Y
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

function Draw-TagSkillButton {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Button,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedSkillSet,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$RacialSkillSet,

        [Parameter(Mandatory = $true)]
        [int]$SelectedCount,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    $Selected =
        $SelectedSkillSet.Contains($Button.Skill)

    $Locked =
        $RacialSkillSet.Contains($Button.Skill)

    if ($Locked) {
        $Value =
            [int]$GameRules.RacialProficiencyStart
    }
    elseif ($Selected) {
        $Value =
            [int]$GameRules.MinorTagSkillStart
    }
    else {
        $Value =
            [int]$GameRules.SkillMinimum
    }

    $SelectionFull = (
        $SelectedCount -ge
        [int]$GameRules.MinorTagSkillCount
    )

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

function Draw-TagSkillButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillButtons,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedSkillSet,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$RacialSkillSet,

        [Parameter(Mandatory = $true)]
        [int]$SelectedCount,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget
    )

    foreach ($Button in $SkillButtons) {
        Draw-TagSkillButton `
            -Button $Button `
            -SelectedSkillSet $SelectedSkillSet `
            -RacialSkillSet $RacialSkillSet `
            -SelectedCount $SelectedCount `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget
    }
}

function Draw-TagSkillHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedSkillSet,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$RacialSkillSet,

        [Parameter(Mandatory = $true)]
        [int]$SelectedCount,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget
    )

    ConsoleUI\Clear-TextLine -Y 25

    $HoveredSkill =
        Get-TagSkillFromTarget -Target $HoverTarget

    if ([string]::IsNullOrWhiteSpace($HoveredSkill)) {
        $HelpText =
            '[R] Racial 010 / 100   ' +
            '[X] Tagged 005 / 100   ' +
            '[ ] Available 000 / 100'

        $Color = [ConsoleColor]::DarkGray
    }
    elseif ($RacialSkillSet.Contains($HoveredSkill)) {
        $HelpText = (
            '{0}: racial proficiency, locked at ' +
            '{1:000} / 100.'
        ) -f
            $HoveredSkill,
            [int]$GameRules.RacialProficiencyStart

        $Color = [ConsoleColor]::DarkYellow
    }
    elseif ($SelectedSkillSet.Contains($HoveredSkill)) {
        $HelpText = (
            '{0}: tagged at {1:000} / 100. ' +
            'Click again to remove the tag.'
        ) -f
            $HoveredSkill,
            [int]$GameRules.MinorTagSkillStart

        $Color = [ConsoleColor]::Yellow
    }
    elseif (
        $SelectedCount -ge
        [int]$GameRules.MinorTagSkillCount
    ) {
        $HelpText =
            'All three tags are assigned. ' +
            'Remove an [X] before choosing another skill.'

        $Color = [ConsoleColor]::DarkGray
    }
    else {
        $HelpText = (
            '{0}: click to tag this skill at ' +
            '{1:000} / 100.'
        ) -f
            $HoveredSkill,
            [int]$GameRules.MinorTagSkillStart

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
        [int]$SelectedCount,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    return (
        $SelectedCount -eq
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

    ConsoleUI\Draw-ActionButtons `
        -BackButton $BackButton `
        -ContinueButton $ContinueButton `
        -HoverName $HoverTarget `
        -PressedName $PressedTarget `
        -ContinueEnabled $CanContinue
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
        [System.Collections.Generic.List[string]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedSkillSet,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$RacialSkillSet,

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

        ConsoleUI\Write-Centered `
            -Y 1 `
            -Text 'TAG YOUR MINOR SKILLS' `
            -Color DarkYellow

        $SummaryText =
            '{0} the {1}   |   TAG SKILLS: {2} / {3}' -f
                $CharacterDraft.Name,
                $CharacterDraft.Race,
                $SelectedSkills.Count,
                $GameRules.MinorTagSkillCount

        ConsoleUI\Write-Centered `
            -Y 2 `
            -Text $SummaryText `
            -Color Gray

        Draw-TagSkillHeaders `
            -SkillSections $SkillSections

        Draw-TagSkillButtons `
            -SkillButtons $SkillButtons `
            -SelectedSkillSet $SelectedSkillSet `
            -RacialSkillSet $RacialSkillSet `
            -SelectedCount $SelectedSkills.Count `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget

        Draw-TagSkillHelp `
            -SelectedSkillSet $SelectedSkillSet `
            -RacialSkillSet $RacialSkillSet `
            -SelectedCount $SelectedSkills.Count `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget

        $CanContinue = Test-TagSkillsReady `
            -SelectedCount $SelectedSkills.Count `
            -GameRules $GameRules

        Draw-TagActionButtons `
            -BackButton $BackButton `
            -ContinueButton $ContinueButton `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -CanContinue $CanContinue

    }
}

function Update-TagSkillsRendering {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SkillButtons,

        [Parameter(Mandatory = $true)]
        [hashtable]$SkillButtonMap,

        [Parameter(Mandatory = $true)]
        [object]$BackButton,

        [Parameter(Mandatory = $true)]
        [object]$ContinueButton,

        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedSkillSet,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$RacialSkillSet,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [AllowNull()]
        [string]$HoverTarget,

        [AllowNull()]
        [string]$PressedTarget,

        [AllowNull()]
        [string]$PreviousHoverTarget,

        [AllowNull()]
        [string]$PreviousPressedTarget,

        [switch]$StateChanged
    )

    ConsoleUI\Invoke-ConsoleRedraw {
        if ($StateChanged) {
            $SummaryText =
                '{0} the {1}   |   TAG SKILLS: {2} / {3}' -f
                    $CharacterDraft.Name,
                    $CharacterDraft.Race,
                    $SelectedSkills.Count,
                    $GameRules.MinorTagSkillCount

            ConsoleUI\Clear-TextLine -Y 2

            ConsoleUI\Write-Centered `
                -Y 2 `
                -Text $SummaryText `
                -Color Gray

            Draw-TagSkillButtons `
                -SkillButtons $SkillButtons `
                -SelectedSkillSet $SelectedSkillSet `
                -RacialSkillSet $RacialSkillSet `
                -SelectedCount $SelectedSkills.Count `
                -GameRules $GameRules `
                -HoverTarget $HoverTarget `
                -PressedTarget $PressedTarget
        }
        else {
            $TargetsToDraw = @{}

            foreach (
                $Target in @(
                    $PreviousHoverTarget
                    $HoverTarget
                    $PreviousPressedTarget
                    $PressedTarget
                )
            ) {
                $Skill = Get-TagSkillFromTarget `
                    -Target $Target

                if (
                    [string]::IsNullOrWhiteSpace($Skill) -or
                    $TargetsToDraw.ContainsKey($Skill) -or
                    -not $SkillButtonMap.ContainsKey($Skill)
                ) {
                    continue
                }

                $TargetsToDraw[$Skill] = $true

                Draw-TagSkillButton `
                    -Button $SkillButtonMap[$Skill] `
                    -SelectedSkillSet $SelectedSkillSet `
                    -RacialSkillSet $RacialSkillSet `
                    -SelectedCount $SelectedSkills.Count `
                    -GameRules $GameRules `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget
            }
        }

        Draw-TagSkillHelp `
            -SelectedSkillSet $SelectedSkillSet `
            -RacialSkillSet $RacialSkillSet `
            -SelectedCount $SelectedSkills.Count `
            -GameRules $GameRules `
            -HoverTarget $HoverTarget

        $CanContinue = Test-TagSkillsReady `
            -SelectedCount $SelectedSkills.Count `
            -GameRules $GameRules

        Draw-TagActionButtons `
            -BackButton $BackButton `
            -ContinueButton $ContinueButton `
            -HoverTarget $HoverTarget `
            -PressedTarget $PressedTarget `
            -CanContinue $CanContinue
    }
}

function Set-CharacterDraftMinorSkills {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$SelectedSkills,

        [Parameter(Mandatory = $true)]
        [hashtable]$SkillData,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    if (
        $CharacterDraft.Skills -isnot
            [System.Collections.IDictionary]
    ) {
        throw 'Character draft skill data is not writable.'
    }

    $RacialSkillSet =
        [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )

    foreach (
        $Skill in
        @($CharacterDraft.RacialProficiencies)
    ) {
        [void]$RacialSkillSet.Add([string]$Skill)
    }

    foreach ($Skill in $SkillData.SkillOrder) {
        if ($RacialSkillSet.Contains($Skill)) {
            $CharacterDraft.Skills[$Skill] =
                [int]$GameRules.RacialProficiencyStart
        }
        else {
            $CharacterDraft.Skills[$Skill] =
                [int]$GameRules.SkillMinimum
        }
    }

    foreach ($Skill in $SelectedSkills) {
        $CharacterDraft.Skills[$Skill] =
            [int]$GameRules.MinorTagSkillStart
    }

    $CharacterDraft.MinorTaggedSkills =
        $SelectedSkills.ToArray()

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
        Get-TagSkillButtons `
            -SkillSections $SkillSections
    )

    if (
        $SkillButtons.Count -ne
        $SkillData.SkillOrder.Count
    ) {
        throw (
            'Tag Skills could not build one control per skill. ' +
            "Expected $($SkillData.SkillOrder.Count), " +
            "found $($SkillButtons.Count)."
        )
    }

    $SkillButtonMap = @{}

    foreach ($SkillButton in $SkillButtons) {
        $SkillButtonMap[$SkillButton.Skill] =
            $SkillButton
    }

    $RacialSkills =
        @($CharacterDraft.RacialProficiencies)

    $RacialSkillSet =
        [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )

    foreach ($RacialSkill in $RacialSkills) {
        [void]$RacialSkillSet.Add(
            [string]$RacialSkill
        )
    }

    $SelectedSkills =
        [System.Collections.Generic.List[string]]::new()

    $SelectedSkillSet =
        [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )

    foreach (
        $ExistingSkill in
        @($CharacterDraft.MinorTaggedSkills)
    ) {
        $ValidExistingSkill = (
            $SkillData.SkillOrder -contains
                $ExistingSkill -and
            -not $RacialSkillSet.Contains(
                [string]$ExistingSkill
            ) -and
            -not $SelectedSkillSet.Contains(
                [string]$ExistingSkill
            )
        )

        if (
            $ValidExistingSkill -and
            $SelectedSkills.Count -lt
                [int]$GameRules.MinorTagSkillCount
        ) {
            $SkillName = [string]$ExistingSkill
            [void]$SelectedSkills.Add($SkillName)
            [void]$SelectedSkillSet.Add($SkillName)
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

    $ActionButtons = @(
        $BackButton
        $ContinueButton
    )

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
        -SelectedSkillSet $SelectedSkillSet `
        -RacialSkillSet $RacialSkillSet `
        -GameRules $GameRules `
        -HoverTarget $HoverTarget `
        -PressedTarget $PressedTarget `
        -ClearScreen

    try {
        $InputHandle =
            ConsoleInput\Start-ConsoleMouseSession

        while ($true) {
            $Sample =
                ConsoleInput\Read-ConsoleMouseSample `
                    -InputHandle $InputHandle `
                    -TimeoutMilliseconds 120

            if (-not $Sample.HasEvent) {
                continue
            }

            $CurrentTarget = Get-TagSkillTargetAt `
                -SkillButtons $SkillButtons `
                -ActionButtons $ActionButtons `
                -X $Sample.X `
                -Y $Sample.Y

            if ($CurrentTarget -ne $HoverTarget) {
                $PreviousHoverTarget = $HoverTarget
                $HoverTarget = $CurrentTarget

                Update-TagSkillsRendering `
                    -SkillButtons $SkillButtons `
                    -SkillButtonMap $SkillButtonMap `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -CharacterDraft $CharacterDraft `
                    -SelectedSkills $SelectedSkills `
                    -SelectedSkillSet $SelectedSkillSet `
                    -RacialSkillSet $RacialSkillSet `
                    -GameRules $GameRules `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget `
                    -PreviousHoverTarget $PreviousHoverTarget `
                    -PreviousPressedTarget $PressedTarget
            }

            $IsLeftButtonDown =
                ($Sample.ButtonState -band 0x0001) -ne 0

            if (
                $IsLeftButtonDown -and
                -not $LeftButtonDown
            ) {
                $PreviousPressedTarget = $PressedTarget
                $PressedTarget = $CurrentTarget

                Update-TagSkillsRendering `
                    -SkillButtons $SkillButtons `
                    -SkillButtonMap $SkillButtonMap `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -CharacterDraft $CharacterDraft `
                    -SelectedSkills $SelectedSkills `
                    -SelectedSkillSet $SelectedSkillSet `
                    -RacialSkillSet $RacialSkillSet `
                    -GameRules $GameRules `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget `
                    -PreviousHoverTarget $HoverTarget `
                    -PreviousPressedTarget $PreviousPressedTarget
            }
            elseif (
                -not $IsLeftButtonDown -and
                $LeftButtonDown
            ) {
                $PreviousPressedTarget = $PressedTarget
                $ReleasedTarget = $CurrentTarget
                $ActivatedTarget = $null
                $SelectionChanged = $false

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
                    $ActivatedSkill =
                        Get-TagSkillFromTarget `
                            -Target $ActivatedTarget

                    if (
                        -not [string]::IsNullOrWhiteSpace(
                            $ActivatedSkill
                        ) -and
                        -not $RacialSkillSet.Contains(
                            $ActivatedSkill
                        )
                    ) {
                        if (
                            $SelectedSkillSet.Contains(
                                $ActivatedSkill
                            )
                        ) {
                            [void]$SelectedSkillSet.Remove(
                                $ActivatedSkill
                            )

                            $SelectionChanged = $true

                            for (
                                $Index = 0;
                                $Index -lt $SelectedSkills.Count;
                                $Index++
                            ) {
                                if (
                                    $SelectedSkills[$Index] -ieq
                                    $ActivatedSkill
                                ) {
                                    $SelectedSkills.RemoveAt(
                                        $Index
                                    )

                                    break
                                }
                            }
                        }
                        elseif (
                            $SelectedSkills.Count -lt
                            [int]$GameRules.MinorTagSkillCount
                        ) {
                            [void]$SelectedSkills.Add(
                                $ActivatedSkill
                            )

                            [void]$SelectedSkillSet.Add(
                                $ActivatedSkill
                            )

                            $SelectionChanged = $true
                        }
                    }
                    elseif ($ActivatedTarget -eq 'BACK') {
                        $CharacterDraft =
                            Set-CharacterDraftMinorSkills `
                                -CharacterDraft (
                                    $CharacterDraft
                                ) `
                                -SelectedSkills (
                                    $SelectedSkills
                                ) `
                                -SkillData $SkillData `
                                -GameRules $GameRules

                        return [pscustomobject]@{
                            NextState = 'CHARACTER_CREATOR'
                            CharacterDraft =
                                $CharacterDraft
                        }
                    }
                    elseif (
                        $ActivatedTarget -eq 'CONTINUE'
                    ) {
                        $Ready = Test-TagSkillsReady `
                            -SelectedCount (
                                $SelectedSkills.Count
                            ) `
                            -GameRules $GameRules

                        if ($Ready) {
                            if (
                                $InputHandle -ne
                                [IntPtr]::Zero
                            ) {
                                ConsoleInput\Stop-ConsoleMouseSession `
                                    -InputHandle (
                                        $InputHandle
                                    )

                                $InputHandle =
                                    [IntPtr]::Zero
                            }

                            $CharacterDraft =
                                Set-CharacterDraftMinorSkills `
                                    -CharacterDraft (
                                        $CharacterDraft
                                    ) `
                                    -SelectedSkills (
                                        $SelectedSkills
                                    ) `
                                    -SkillData $SkillData `
                                    -GameRules $GameRules

                            Show-CharacterCreationComplete `
                                -CharacterDraft (
                                    $CharacterDraft
                                )

                            return [pscustomobject]@{
                                NextState = 'MAIN_MENU'
                                CharacterDraft =
                                    $CharacterDraft
                            }
                        }
                    }
                }

                Update-TagSkillsRendering `
                    -SkillButtons $SkillButtons `
                    -SkillButtonMap $SkillButtonMap `
                    -BackButton $BackButton `
                    -ContinueButton $ContinueButton `
                    -CharacterDraft $CharacterDraft `
                    -SelectedSkills $SelectedSkills `
                    -SelectedSkillSet $SelectedSkillSet `
                    -RacialSkillSet $RacialSkillSet `
                    -GameRules $GameRules `
                    -HoverTarget $HoverTarget `
                    -PressedTarget $PressedTarget `
                    -PreviousHoverTarget $HoverTarget `
                    -PreviousPressedTarget $PreviousPressedTarget `
                    -StateChanged:$SelectionChanged
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
