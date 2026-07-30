[CmdletBinding()]
param(
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$NativeSourcePath = Join-Path $AppRoot 'Engine\ConsoleNative.cs'

$ModulePaths = @(
    (Join-Path $AppRoot 'Engine\ConsoleUI.psm1')
    (Join-Path $AppRoot 'Engine\ConsoleInput.psm1')
    (Join-Path $AppRoot 'Engine\Animations.psm1')
    (Join-Path $AppRoot 'Engine\D100.psm1')
    (Join-Path $AppRoot 'Engine\SaveGame.psm1')
    (Join-Path $AppRoot 'Engine\CharacterPreview.psm1')
    (Join-Path $AppRoot 'Screens\MainMenu.psm1')
    (Join-Path $AppRoot 'Screens\CharacterCreator.psm1')
    (Join-Path $AppRoot 'Screens\TagSkills.psm1')
    (Join-Path $AppRoot 'Screens\CharacterConfirmation.psm1')
    (Join-Path $AppRoot 'Screens\LoadGame.psm1')
)

$RaceDataPath = Join-Path $AppRoot 'Data\Races.psd1'
$SkillDataPath = Join-Path $AppRoot 'Data\Skills.psd1'
$GameRulesPath = Join-Path $AppRoot 'Data\GameRules.psd1'
$CombatRulesPath = Join-Path $AppRoot 'Data\CombatRules.psd1'
$ProgressionRulesPath = Join-Path $AppRoot 'Data\ProgressionRules.psd1'

$RequiredFiles = @(
    $NativeSourcePath
    $RaceDataPath
    $SkillDataPath
    $GameRulesPath
    $CombatRulesPath
    $ProgressionRulesPath
) + $ModulePaths

foreach ($RequiredFile in $RequiredFiles) {
    if (-not (Test-Path -LiteralPath $RequiredFile -PathType Leaf)) {
        throw "Required application file is missing: $RequiredFile"
    }
}

if (-not ('DungeonConsoleNative' -as [type])) {
    $NativeSource = [System.IO.File]::ReadAllText($NativeSourcePath)
    Add-Type -TypeDefinition $NativeSource
}

foreach ($ModulePath in $ModulePaths) {
    Import-Module -Name $ModulePath -Force -Global -DisableNameChecking -ErrorAction Stop
}

$RaceData = Import-PowerShellDataFile -LiteralPath $RaceDataPath
$SkillData = Import-PowerShellDataFile -LiteralPath $SkillDataPath
$GameRules = Import-PowerShellDataFile -LiteralPath $GameRulesPath
$CombatRules = Import-PowerShellDataFile -LiteralPath $CombatRulesPath
$ProgressionRules = Import-PowerShellDataFile -LiteralPath $ProgressionRulesPath

function Assert-GameData {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Races,

        [Parameter(Mandatory = $true)]
        [hashtable]$Skills,

        [Parameter(Mandatory = $true)]
        [hashtable]$Rules
    )

    foreach ($RequiredRaceKey in @('RaceOrder', 'Races')) {
        if (-not $Races.ContainsKey($RequiredRaceKey)) {
            throw "Races.psd1 is missing key: $RequiredRaceKey"
        }
    }

    foreach ($RequiredSkillKey in @('SkillOrder', 'Categories')) {
        if (-not $Skills.ContainsKey($RequiredSkillKey)) {
            throw "Skills.psd1 is missing key: $RequiredSkillKey"
        }
    }

    foreach ($RequiredRuleKey in @(
        'Attributes'
        'AttributeDescriptions'
        'GenderOptions'
        'SkillMinimum'
        'SkillMaximum'
        'RacialProficiencyStart'
        'MinorTagSkillStart'
        'MinorTagSkillCount'
        'CharacterCreation'
    )) {
        if (-not $Rules.ContainsKey($RequiredRuleKey)) {
            throw "GameRules.psd1 is missing key: $RequiredRuleKey"
        }
    }

    if ($Races.RaceOrder.Count -ne 6) {
        throw 'Exactly six playable races are required.'
    }

    if ($Rules.Attributes.Count -ne 6) {
        throw 'Exactly six character attributes are required.'
    }

    if ($Skills.SkillOrder.Count -ne 28) {
        throw "The current design requires exactly 28 skills. Found: $($Skills.SkillOrder.Count)"
    }

    $UniqueSkills = @($Skills.SkillOrder | Sort-Object -Unique)
    if ($UniqueSkills.Count -ne $Skills.SkillOrder.Count) {
        throw 'Skills.psd1 contains duplicate skills.'
    }

    if ($Skills.SkillOrder -notcontains 'Defense') {
        throw 'Skills.psd1 must contain the Defense skill.'
    }

    if (-not $Skills.Categories.ContainsKey('Combat')) {
        throw 'Skills.psd1 must contain the Combat category.'
    }

    if (@($Skills.Categories.Combat) -notcontains 'Defense') {
        throw 'The Defense skill must be in the Combat category.'
    }

    foreach ($Attribute in $Rules.Attributes) {
        if (-not $Rules.AttributeDescriptions.ContainsKey($Attribute)) {
            throw "Missing attribute description: $Attribute"
        }
    }

    foreach ($RaceId in $Races.RaceOrder) {
        if (-not $Races.Races.ContainsKey($RaceId)) {
            throw "Race data is missing for: $RaceId"
        }

        $Race = $Races.Races[$RaceId]

        foreach ($RequiredRaceProperty in @(
            'DisplayName'
            'Description'
            'FavoredAttribute'
            'Proficiencies'
            'BaseAttributes'
        )) {
            if (-not $Race.ContainsKey($RequiredRaceProperty)) {
                throw "Race '$RaceId' is missing property: $RequiredRaceProperty"
            }
        }

        if ($Race.Proficiencies.Count -ne 3) {
            throw "Race '$RaceId' must have exactly three proficiencies."
        }

        if ($Rules.Attributes -notcontains $Race.FavoredAttribute) {
            throw "Race '$RaceId' has an unknown favored attribute: $($Race.FavoredAttribute)"
        }

        foreach ($Proficiency in $Race.Proficiencies) {
            if ($Skills.SkillOrder -notcontains $Proficiency) {
                throw "Race '$RaceId' references an unknown skill: $Proficiency"
            }
        }

        $AttributeTotal = 0

        foreach ($Attribute in $Rules.Attributes) {
            if (-not $Race.BaseAttributes.ContainsKey($Attribute)) {
                throw "Race '$RaceId' is missing base attribute: $Attribute"
            }

            $Value = [int]$Race.BaseAttributes[$Attribute]
            if ($Value -lt 0) {
                throw "Race '$RaceId' has a negative base attribute: $Attribute = $Value"
            }

            $AttributeTotal += $Value
        }

        if ($AttributeTotal -ne [int]$Rules.CharacterCreation.BaseAttributeTotal) {
            throw "Race '$RaceId' has base attribute total $AttributeTotal instead of $($Rules.CharacterCreation.BaseAttributeTotal)."
        }
    }

    if ($Rules.SkillMinimum -ne 0) {
        throw 'SkillMinimum must currently be 0.'
    }

    if ($Rules.SkillMaximum -ne 100) {
        throw 'SkillMaximum must currently be 100.'
    }

    if ($Rules.RacialProficiencyStart -ne 10) {
        throw 'RacialProficiencyStart must currently be 10.'
    }

    if ($Rules.MinorTagSkillStart -ne 5) {
        throw 'MinorTagSkillStart must currently be 5.'
    }

    if ($Rules.MinorTagSkillCount -ne 3) {
        throw 'MinorTagSkillCount must currently be 3.'
    }

    if ($Rules.CharacterCreation.SpendableAttributePoints -ne 5) {
        throw 'Character creation must currently provide five points.'
    }

    if ($Rules.CharacterCreation.AllowReducingBaseAttributes) {
        throw 'Base attributes must not be reducible during creation.'
    }
}

function Assert-CombatRules {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Rules
    )

    foreach ($RequiredKey in @(
        'Initiative'
        'Round'
        'Turn'
        'Actions'
        'Movement'
        'StatusEffects'
        'Evasion'
        'Accuracy'
        'AttackResolution'
        'Defense'
    )) {
        if (-not $Rules.ContainsKey($RequiredKey)) {
            throw "CombatRules.psd1 is missing key: $RequiredKey"
        }
    }

    if ($Rules.Initiative.PrimaryAttribute -ne 'Agility') {
        throw 'Combat initiative must use Agility first.'
    }

    if ($Rules.Initiative.SecondaryAttribute -ne 'Wisdom') {
        throw 'Combat initiative must use Wisdom second.'
    }

    if ($Rules.Initiative.TieBreaker -ne 'D100') {
        throw 'Combat initiative ties must use D100.'
    }

    if (
        -not $Rules.Initiative.EnemyNumbering.AssignAfterInitiative -or
        -not $Rules.Initiative.EnemyNumbering.StableForEncounter -or
        $Rules.Initiative.EnemyNumbering.RenumberAfterDefeat -or
        $Rules.Initiative.EnemyNumbering.RenumberAfterInitiativeChange -or
        $Rules.Initiative.EnemyNumbering.ReinforcementAssignment -ne 'NextUnused' -or
        $Rules.Initiative.EnemyNumbering.ReuseNumbers
    ) {
        throw 'Enemy numbering rules do not match the approved design.'
    }

    if (
        $Rules.Round.Definition -ne 'OneCompleteInitiativePass' -or
        $Rules.Round.MechanicalRefresh
    ) {
        throw 'Round rules do not match the approved design.'
    }

    if (
        (@($Rules.Turn.AvailablePhases) -join ',') -ne
        'Movement,Action,Reaction'
    ) {
        throw 'Turn phases do not match the approved design.'
    }

    if (
        $Rules.Turn.MovementCanSplit -or
        $Rules.Turn.ActionCanSplit -or
        $Rules.Turn.UnusedMovementCarriesForward -or
        $Rules.Turn.UnusedActionCarriesForward
    ) {
        throw 'Movement and Action must remain indivisible and nonbanking.'
    }

    if (
        $Rules.Turn.MovementRefresh -ne 'StartOfOwnTurn' -or
        $Rules.Turn.ActionRefresh -ne 'StartOfOwnTurn' -or
        $Rules.Turn.ReactionRefresh -ne 'StartOfOwnTurn' -or
        [int]$Rules.Turn.ReactionUsesBeforeRefresh -ne 1
    ) {
        throw 'Turn refresh rules do not match the approved design.'
    }

    if (
        (@($Rules.Actions.Available) -join ',') -ne
        'Attack,Ability,Item,Defend,Interact'
    ) {
        throw 'Combat actions do not match the approved design.'
    }

    if (
        $Rules.Actions.ItemRequiredTag -ne 'Usable' -or
        -not $Rules.Actions.InteractIsContextual -or
        $Rules.Actions.DefendDuration -ne 'UntilNextTurn'
    ) {
        throw 'Combat action rules do not match the approved design.'
    }

    if (
        [int]$Rules.Movement.SquareFeet -ne 5 -or
        [int]$Rules.Movement.States.Slow -ne 10 -or
        [int]$Rules.Movement.States.Normal -ne 20 -or
        [int]$Rules.Movement.States.Fast -ne 30 -or
        $Rules.Movement.DefaultState -ne 'Normal' -or
        $Rules.Movement.DerivedFromAgility
    ) {
        throw 'Movement rules do not match the approved design.'
    }

    if (
        (@($Rules.StatusEffects.Types) -join ',') -ne
        'Continuous,Triggered'
    ) {
        throw 'Status effect types do not match the approved design.'
    }

    if (
        -not $Rules.StatusEffects.Continuous.PersistsOutsideCombat -or
        $Rules.StatusEffects.Continuous.TurnCountRequired -or
        -not $Rules.StatusEffects.Triggered.CombatOnly -or
        -not $Rules.StatusEffects.Triggered.TurnCountRequired -or
        (@($Rules.StatusEffects.Triggered.ResolutionPriority) -join ',') -ne
        'CC,Debuff,Buff'
    ) {
        throw 'Status effect timing rules do not match the approved design.'
    }

    if (
        [int]$Rules.Evasion.BaseChance -ne 10 -or
        [int]$Rules.Evasion.DifferenceStep -ne 5 -or
        [int]$Rules.Evasion.MinimumChance -ne 5 -or
        [int]$Rules.Evasion.MaximumChance -ne 40 -or
        $Rules.Evasion.Attack.AttackerAttribute -ne 'Agility' -or
        $Rules.Evasion.Attack.DefenderAttribute -ne 'Agility' -or
        $Rules.Evasion.PhysicalAbility.AttackerAttribute -ne 'Agility' -or
        $Rules.Evasion.PhysicalAbility.DefenderAttribute -ne 'Agility' -or
        $Rules.Evasion.MagicAbility.AttackerAttribute -ne 'Wisdom' -or
        $Rules.Evasion.MagicAbility.DefenderAttribute -ne 'Agility'
    ) {
        throw 'Evasion rules do not match the approved design.'
    }

    if (
        [int]$Rules.Accuracy.BaseChance -ne 70 -or
        [int]$Rules.Accuracy.DifferenceDivisor -ne 2 -or
        [int]$Rules.Accuracy.MinimumChance -ne 10 -or
        [int]$Rules.Accuracy.MaximumChance -ne 95 -or
        $Rules.Accuracy.DefenderSkill -ne 'Defense'
    ) {
        throw 'Accuracy rules do not match the approved design.'
    }

    $ExpectedAttackResolution = @(
        'ValidateTarget'
        'ConfirmAndSpendAction'
        'ResolveEvasion'
        'StopIfEvaded'
        'ResolveAccuracyForAttack'
        'StopIfAccuracyFails'
        'CheckEligibleReactions'
        'ResolveDamage'
        'ApplyAttachedEffects'
        'CheckDefeat'
    )

    $ActualAttackResolution = @($Rules.AttackResolution) -join ','
    $ExpectedAttackResolutionText = $ExpectedAttackResolution -join ','

    if (
        $ActualAttackResolution -ne
        $ExpectedAttackResolutionText
    ) {
        throw 'Attack resolution order does not match the approved design.'
    }

    if (
        $Rules.Defense.Skill -ne 'Defense' -or
        $Rules.Defense.Opposes -ne 'WeaponSkill' -or
        $Rules.Defense.ProgressionTrigger -ne 'TakingDamage'
    ) {
        throw 'Defense skill rules do not match the approved design.'
    }
}

function Assert-ProgressionRules {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Rules,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules
    )

    foreach ($RequiredKey in @(
        'StartingLevel'
        'MaximumLevel'
        'PerkPointsPerGainedLevel'
        'FirstPerkAwardLevel'
        'TotalPerkPointsAtMaximumLevel'
        'SkillProgression'
    )) {
        if (-not $Rules.ContainsKey($RequiredKey)) {
            throw "ProgressionRules.psd1 is missing key: $RequiredKey"
        }
    }

    if (
        [int]$Rules.StartingLevel -ne 0 -or
        [int]$Rules.MaximumLevel -ne 50 -or
        [int]$Rules.PerkPointsPerGainedLevel -ne 1 -or
        [int]$Rules.FirstPerkAwardLevel -ne 1 -or
        [int]$Rules.TotalPerkPointsAtMaximumLevel -ne 50
    ) {
        throw 'Character level and perk rules do not match the approved design.'
    }

    $SkillProgression = $Rules.SkillProgression

    if (
        -not $SkillProgression.ImprovesThroughUse -or
        [int]$SkillProgression.FirstProgressionLevel -ne 1 -or
        [int]$SkillProgression.MaximumRanksPerSkillPerLevel -ne 3 -or
        -not $SkillProgression.IndependentPerSkill -or
        $SkillProgression.SharedSkillPointPool -or
        [int]$SkillProgression.MinimumRank -ne
            [int]$GameRules.SkillMinimum -or
        [int]$SkillProgression.MaximumRank -ne
            [int]$GameRules.SkillMaximum -or
        [int]$SkillProgression.EarliestMaximumLevelFromMinimum -ne 34
    ) {
        throw 'Skill progression rules do not match the approved design.'
    }

    $ProgressionWindowsNeeded = [int][Math]::Ceiling(
        (
            [double]$SkillProgression.MaximumRank -
            [double]$SkillProgression.MinimumRank
        ) /
        [double]$SkillProgression.MaximumRanksPerSkillPerLevel
    )

    $CalculatedEarliestMaximumLevel = (
        [int]$SkillProgression.FirstProgressionLevel +
        $ProgressionWindowsNeeded -
        1
    )

    if (
        $CalculatedEarliestMaximumLevel -ne
        [int]$SkillProgression.EarliestMaximumLevelFromMinimum
    ) {
        throw 'The stored earliest skill-mastery level is inconsistent.'
    }

    $CalculatedTotalPerkPoints = (
        [int]$Rules.MaximumLevel -
        [int]$Rules.FirstPerkAwardLevel +
        1
    ) * [int]$Rules.PerkPointsPerGainedLevel

    if (
        $CalculatedTotalPerkPoints -ne
        [int]$Rules.TotalPerkPointsAtMaximumLevel
    ) {
        throw 'The stored maximum perk-point total is inconsistent.'
    }
}

Assert-GameData -Races $RaceData -Skills $SkillData -Rules $GameRules
Assert-CombatRules -Rules $CombatRules
Assert-ProgressionRules `
    -Rules $ProgressionRules `
    -GameRules $GameRules

$RequiredCommands = @(
    'Invoke-MainMenu'
    'Invoke-CharacterCreatorScreen'
    'Invoke-TagSkillsScreen'
    'Invoke-CharacterConfirmationScreen'
    'Invoke-LoadGameScreen'
    'Invoke-D100Roll'
    'Get-PrimarySaveGame'
    'Save-PrimaryCharacter'
    'Draw-CharacterPreview'
    'Write-At'
    'Clear-ConsoleScreen'
    'Invoke-ConsoleRedraw'
    'Draw-TextBox'
    'Set-TextBoxCursor'
    'Test-PointInRect'
    'Draw-Frame'
    'Draw-Button'
    'Draw-ActionButtons'
    'Start-ConsoleMouseSession'
    'Read-ConsoleMouseSample'
    'Read-ConsoleInputSample'
    'Stop-ConsoleMouseSession'
    'New-ConsoleTextBoxState'
    'Complete-ConsoleTextBoxState'
    'Update-ConsoleTextBoxState'
    'Read-ConsoleText'
    'Show-MainMenuIntro'
    'Show-MenuSelection'
    'Show-ExitAnimation'
)

foreach ($RequiredCommand in $RequiredCommands) {
    if (-not (Get-Command -Name $RequiredCommand -ErrorAction SilentlyContinue)) {
        throw "Required exported command is unavailable: $RequiredCommand"
    }
}

if ($ValidateOnly) {
    Write-Output '[PASS] Modular Dungeon Crawler validation'
    exit 0
}

$OriginalTitle = [Console]::Title
$OriginalForeground = [Console]::ForegroundColor
$OriginalBackground = [Console]::BackgroundColor
$OriginalCursorVisibility = [Console]::CursorVisible

try {
    [Console]::Title = 'Dungeon Crawler'
    [Console]::ForegroundColor = [ConsoleColor]::Gray
    [Console]::BackgroundColor = [ConsoleColor]::Black
    [Console]::CursorVisible = $false

    $ApplicationState = 'MAIN_MENU'
    $CharacterDraft = $null
    $Running = $true

    while ($Running) {
        switch ($ApplicationState) {
            'MAIN_MENU' {
                $MenuAction = Invoke-MainMenu

                switch ($MenuAction) {
                    'NEW' {
                        $CharacterDraft = $null
                        $ApplicationState = 'CHARACTER_CREATOR'
                    }

                    'LOAD' {
                        $ApplicationState = 'LOAD_GAME'
                    }

                    'EXIT' {
                        $Running = $false
                    }

                    default {
                        throw "Unknown main-menu action: $MenuAction"
                    }
                }
            }

            'CHARACTER_CREATOR' {
                $CreatorResult = Invoke-CharacterCreatorScreen `
                    -RaceData $RaceData `
                    -SkillData $SkillData `
                    -GameRules $GameRules `
                    -ExistingDraft $CharacterDraft

                if ($null -eq $CreatorResult) {
                    throw 'Character creator returned no result.'
                }

                if ($CreatorResult.PSObject.Properties.Name -notcontains 'NextState') {
                    throw 'Character creator result has no NextState.'
                }

                if ($CreatorResult.PSObject.Properties.Name -contains 'CharacterDraft') {
                    $CharacterDraft = $CreatorResult.CharacterDraft
                }

                $ApplicationState = $CreatorResult.NextState
            }

            'TAG_SKILLS' {
                if ($null -eq $CharacterDraft) {
                    throw 'Tag Skills requires a character draft.'
                }

                $TagResult = Invoke-TagSkillsScreen `
                    -RaceData $RaceData `
                    -SkillData $SkillData `
                    -GameRules $GameRules `
                    -CharacterDraft $CharacterDraft

                if ($null -eq $TagResult) {
                    throw 'Tag Skills returned no result.'
                }

                if ($TagResult -is [string]) {
                    $ApplicationState = $TagResult
                }
                else {
                    if ($TagResult.PSObject.Properties.Name -notcontains 'NextState') {
                        throw 'Tag Skills result has no NextState.'
                    }

                    if ($TagResult.PSObject.Properties.Name -contains 'CharacterDraft') {
                        $CharacterDraft = $TagResult.CharacterDraft
                    }

                    $ApplicationState = $TagResult.NextState
                }
            }

            'CHARACTER_CONFIRMATION' {
                if ($null -eq $CharacterDraft) {
                    throw 'Character confirmation requires a character draft.'
                }

                $ConfirmationResult = Invoke-CharacterConfirmationScreen `
                    -AppRoot $AppRoot `
                    -CharacterDraft $CharacterDraft

                if ($null -eq $ConfirmationResult) {
                    throw 'Character confirmation returned no result.'
                }

                $ConfirmationProperties = @(
                    $ConfirmationResult.PSObject.Properties.Name
                )

                if ($ConfirmationProperties -notcontains 'NextState') {
                    throw 'Character confirmation result has no NextState.'
                }

                if ($ConfirmationProperties -contains 'CharacterDraft') {
                    $CharacterDraft = $ConfirmationResult.CharacterDraft
                }

                $ApplicationState = [string]$ConfirmationResult.NextState
            }
            'LOAD_GAME' {
                $LoadResult = Invoke-LoadGameScreen `
                    -AppRoot $AppRoot

                if ($null -eq $LoadResult) {
                    throw 'Load Game returned no result.'
                }

                $LoadProperties = @(
                    $LoadResult.PSObject.Properties.Name
                )

                if ($LoadProperties -notcontains 'NextState') {
                    throw 'Load Game result has no NextState.'
                }

                if ($LoadProperties -contains 'CharacterDraft') {
                    $CharacterDraft = $LoadResult.CharacterDraft
                }

                $ApplicationState = [string]$LoadResult.NextState
            }

            default {
                throw "Unknown application state: $ApplicationState"
            }
        }
    }
}
finally {
    [Console]::ForegroundColor = $OriginalForeground
    [Console]::BackgroundColor = $OriginalBackground
    [Console]::CursorVisible = $OriginalCursorVisibility
    [Console]::Title = $OriginalTitle
}
