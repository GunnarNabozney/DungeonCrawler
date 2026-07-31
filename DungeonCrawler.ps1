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
$WeaponTypeDataPath = Join-Path $AppRoot 'Data\WeaponTypes.psd1'
$ProgressionRulesPath = Join-Path $AppRoot 'Data\ProgressionRules.psd1'

$RequiredFiles = @(
    $NativeSourcePath
    $RaceDataPath
    $SkillDataPath
    $GameRulesPath
    $CombatRulesPath
    $WeaponTypeDataPath
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
$WeaponTypeData = Import-PowerShellDataFile -LiteralPath $WeaponTypeDataPath
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

function Assert-AttackAndArmorRules {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Rules
    )

    foreach ($RequiredKey in @(
        'PhysicalDamage'
        'DamagePayload'
        'DamageResult'
        'Attack'
        'Armor'
    )) {
        if (-not $Rules.ContainsKey($RequiredKey)) {
            throw "CombatRules.psd1 is missing attack or armor key: $RequiredKey"
        }
    }

    if ($Rules.Accuracy.Rounding -ne 'FloorBeforeClamp') {
        throw 'Accuracy must round down before applying its chance limits.'
    }

    $ExpectedDamageTypes = 'Blunt,Slicing,Stabbing'
    $ActualDamageTypes = @($Rules.PhysicalDamage.Types) -join ','

    if ($ActualDamageTypes -ne $ExpectedDamageTypes) {
        throw 'Physical damage types must be Blunt, Slicing, and Stabbing.'
    }

    if (
        $Rules.PhysicalDamage.GenericPhysicalTypeAllowed -or
        $Rules.PhysicalDamage.AutomaticStatusEffects -or
        -not $Rules.PhysicalDamage.MatchingArmorProfileRequired
    ) {
        throw 'Physical damage-type behavior does not match the approved design.'
    }

    $ExpectedPayloadFields = @(
        'SourceCombatantId'
        'TargetCombatantId'
        'TargetBodyLocation'
        'SourceKind'
        'SourceId'
        'HitNumber'
        'HitCount'
        'DamageComponents'
        'AttachedEffects'
    ) -join ','

    $ActualPayloadFields =
        @($Rules.DamagePayload.RequiredFields) -join ','

    if (
        -not $Rules.DamagePayload.OnePayloadPerHit -or
        -not $Rules.DamagePayload.ContainsResolvedRawDamage -or
        $Rules.DamagePayload.ContainsDamageFormula -or
        $ActualPayloadFields -ne $ExpectedPayloadFields
    ) {
        throw 'Damage payload rules do not match the approved design.'
    }

    $ExpectedComponentFields = 'DamageType,RawAmount'
    $ActualComponentFields =
        @($Rules.DamagePayload.DamageComponentFields) -join ','

    if ($ActualComponentFields -ne $ExpectedComponentFields) {
        throw 'Damage component fields do not match the approved design.'
    }

    $ExpectedResultFields = @(
        'RawDamage'
        'DamageType'
        'ArmorValue'
        'MitigationPercent'
        'PreventedDamage'
        'FinalDamage'
        'HealthBefore'
        'HealthAfter'
        'TargetDefeated'
    ) -join ','

    $ActualResultFields =
        @($Rules.DamageResult.RequiredFields) -join ','

    if (
        -not $Rules.DamageResult.PreservePerComponentResults -or
        $ActualResultFields -ne $ExpectedResultFields
    ) {
        throw 'Damage result rules do not match the approved design.'
    }

    $Attack = $Rules.Attack
    $ExpectedLocations =
        'Head,Chest,Left Arm,Right Arm,Left Leg,Right Leg'
    $ActualLocations =
        @($Attack.Targeting.BodyLocations) -join ','

    if (
        -not $Attack.Targeting.BodyLocationRequired -or
        -not $Attack.Targeting.MultiHitKeepsSelectedLocation -or
        $ActualLocations -ne $ExpectedLocations
    ) {
        throw 'Attack body-location targeting does not match the approved design.'
    }

    $ExpectedSubtotalComponents =
        'WeaponBaseDamage,CurrentEffectiveAssociatedAttribute'
    $ActualSubtotalComponents =
        @($Attack.RawDamage.WeaponSubtotalComponents) -join ','

    if (
        $ActualSubtotalComponents -ne $ExpectedSubtotalComponents -or
        [int]$Attack.RawDamage.AttributeContributionRatio -ne 1 -or
        $Attack.RawDamage.WeaponSkillContributesByDefault
    ) {
        throw 'Weapon raw-damage inputs do not match the approved design.'
    }

    $PerkContribution = $Attack.RawDamage.PerkContribution

    if (
        -not $PerkContribution.PercentageOnly -or
        -not $PerkContribution.StoredAsWholeNumber -or
        $PerkContribution.Combination -ne 'Add' -or
        $PerkContribution.AppliedTo -ne 'WeaponSubtotal' -or
        -not $PerkContribution.AppliedOncePerAttack -or
        $PerkContribution.Rounding -ne 'Floor'
    ) {
        throw 'Perk damage contribution rules do not match the approved design.'
    }

    $MultiHit = $Attack.MultiHit

    if (
        $MultiHit.MechanicalProperty -ne 'HitsPerAttack' -or
        $MultiHit.PropertyOwner -ne 'WeaponType' -or
        -not $MultiHit.IndividualWeaponOverrideAllowed -or
        [int]$MultiHit.MinimumHits -ne 1 -or
        [int]$MultiHit.MaximumHits -ne 3 -or
        $MultiHit.SpeedLabels['1'] -ne 'Slow' -or
        $MultiHit.SpeedLabels['2'] -ne 'Normal' -or
        $MultiHit.SpeedLabels['3'] -ne 'Fast' -or
        -not $MultiHit.TotalRawDamageCalculatedOnce -or
        -not $MultiHit.AttributeAppliedOncePerAttack -or
        -not $MultiHit.PerksAppliedOncePerAttack -or
        $MultiHit.Division -ne 'EvenWithEarliestRemainder' -or
        $MultiHit.FailedHitDamageRedistributed -or
        $MultiHit.WeaponBaseDamageMinimumRule -ne 'HitsPerAttack'
    ) {
        throw 'Multi-hit rules do not match the approved design.'
    }

    $ReactionTiming = $Attack.ReactionTiming

    if (
        $ReactionTiming.OfferOn -ne
            'FirstSuccessfulEligibleTrigger' -or
        $ReactionTiming.DeclineConsumesReaction -or
        -not $ReactionTiming.ReofferAfterDecline -or
        -not $ReactionTiming.UseConsumesReaction -or
        $ReactionTiming.Refresh -ne 'StartOfOwnTurn' -or
        $ReactionTiming.FailedEvasionCreatesOffer -or
        $ReactionTiming.FailedAccuracyCreatesOffer
    ) {
        throw 'Reaction offer timing does not match the approved design.'
    }

    $ExpectedHitResolution = @(
        'ResolveEvasion'
        'StopHitIfEvaded'
        'ResolveAccuracyAgainstDefense'
        'StopHitIfAccuracyFails'
        'OfferEligibleReaction'
        'ResolveMatchingArmorMitigation'
        'ApplyFinalDamage'
        'ApplyEligibleAttachedEffects'
        'CheckDefeat'
        'StopRemainingHitsIfDefeated'
    ) -join ','

    $ActualHitResolution =
        @($Attack.HitResolution) -join ','

    if ($ActualHitResolution -ne $ExpectedHitResolution) {
        throw 'Per-hit Attack resolution does not match the approved design.'
    }

    if (
        -not $Attack.Defeat.CheckAfterEveryHit -or
        -not $Attack.Defeat.StopRemainingHits -or
        -not $Attack.Defeat.UnresolvedHitDamageIsLost -or
        $Attack.Defeat.DefaultRetargeting -or
        -not $Attack.Defeat.ExplicitRuleMayPermitRetargeting
    ) {
        throw 'Multi-hit defeat handling does not match the approved design.'
    }

    $Armor = $Rules.Armor
    $ActualArmorSlots = @($Armor.Slots) -join ','
    $ActualArmorRatings = @($Armor.Ratings) -join ','

    if (
        $Armor.DesignStatus -ne 'WorkingConcept' -or
        $Armor.ExactArmorProfilesFinalized -or
        -not $Armor.UsesRawArmorValues -or
        -not $Armor.HigherRawValueIsBetter -or
        $ActualArmorSlots -ne $ExpectedLocations -or
        $ActualArmorRatings -ne $ExpectedDamageTypes -or
        [int]$Armor.EmptySlotArmor -ne 0 -or
        -not $Armor.NaturalArmorMayApply -or
        -not $Armor.MatchingDamageTypeOnly -or
        -not $Armor.ResolvePerSuccessfulHit
    ) {
        throw 'Armor targeting and identity rules do not match the approved design.'
    }

    $Mitigation = $Armor.Mitigation

    if (
        $Mitigation.Model -ne 'DiminishingReturns' -or
        [int]$Mitigation.ArmorScale -ne 100 -or
        $Mitigation.Formula -ne 'ArmorDividedByArmorPlusScale' -or
        [int]$Mitigation.MaximumMitigationPercent -ne 80 -or
        $Mitigation.FinalDamageRounding -ne 'Floor' -or
        [int]$Mitigation.MinimumFinalDamage -ne 1 -or
        [int]$Mitigation.RecommendedNormalMaximumArmor -ne 300
    ) {
        throw 'Physical armor mitigation does not match the approved design.'
    }
}

function Assert-WeaponTypeData {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$WeaponTypeData,

        [Parameter(Mandatory = $true)]
        [hashtable]$Skills,

        [Parameter(Mandatory = $true)]
        [hashtable]$GameRules,

        [Parameter(Mandatory = $true)]
        [hashtable]$CombatRules
    )

    foreach ($RequiredKey in @(
        'DesignStatus'
        'WeaponTypeOrder'
        'IndividualWeaponRequiredProperties'
        'TypeDefaultProperties'
        'OverrideContainer'
        'AllowedOverrideProperties'
        'ResolutionPrecedence'
        'PendingTypeAssignments'
        'WeaponTypes'
    )) {
        if (-not $WeaponTypeData.ContainsKey($RequiredKey)) {
            throw "WeaponTypes.psd1 is missing key: $RequiredKey"
        }
    }

    $ExpectedTypeOrder = @(
        'One-Handed Sword'
        'Two-Handed Sword'
        'Finesse Sword'
        'One-Handed Axe'
        'Two-Handed Axe'
        'One-Handed Hammer'
        'Two-Handed Hammer'
        'Dagger'
        'Bow'
        'Crossbow'
        'Unarmed Strike'
        'Natural Weapon'
    )

    if (
        (@($WeaponTypeData.WeaponTypeOrder) -join ',') -ne
        ($ExpectedTypeOrder -join ',')
    ) {
        throw 'Weapon type order does not match the approved taxonomy.'
    }

    if (
        $WeaponTypeData.DesignStatus -ne
            'ApprovedDefaultsWithPendingHitCounts' -or
        $WeaponTypeData.OverrideContainer -ne 'Overrides' -or
        (@($WeaponTypeData.PendingTypeAssignments) -join ',') -ne
            'HitsPerAttack'
    ) {
        throw 'Weapon type data status does not match the approved design.'
    }

    $ExpectedIndividualProperties =
        'Id,Name,WeaponType,BaseDamage'
    $ActualIndividualProperties =
        @($WeaponTypeData.IndividualWeaponRequiredProperties) -join ','

    $ExpectedDefaultProperties =
        'WeaponSkill,AssociatedAttribute,DamageType,HitsPerAttack'
    $ActualDefaultProperties =
        @($WeaponTypeData.TypeDefaultProperties) -join ','

    $ExpectedOverrideProperties =
        'WeaponSkill,AssociatedAttribute,DamageType,HitsPerAttack'
    $ActualOverrideProperties =
        @($WeaponTypeData.AllowedOverrideProperties) -join ','

    $ExpectedResolution =
        'IndividualWeaponOverride,WeaponTypeDefault'
    $ActualResolution =
        @($WeaponTypeData.ResolutionPrecedence) -join ','

    if (
        $ActualIndividualProperties -ne $ExpectedIndividualProperties -or
        $ActualDefaultProperties -ne $ExpectedDefaultProperties -or
        $ActualOverrideProperties -ne $ExpectedOverrideProperties -or
        $ActualResolution -ne $ExpectedResolution
    ) {
        throw 'Weapon property ownership or override rules are incorrect.'
    }

    $ExpectedDefaults = @{
        'One-Handed Sword' = @('Swords', 'Strength', 'Slicing')
        'Two-Handed Sword' = @('Swords', 'Strength', 'Slicing')
        'Finesse Sword' = @('Swords', 'Agility', 'Stabbing')
        'One-Handed Axe' = @('Axes', 'Strength', 'Slicing')
        'Two-Handed Axe' = @('Axes', 'Strength', 'Slicing')
        'One-Handed Hammer' = @('Hammers', 'Strength', 'Blunt')
        'Two-Handed Hammer' = @('Hammers', 'Strength', 'Blunt')
        Dagger = @('Daggers', 'Agility', 'Stabbing')
        Bow = @('Archery', 'Agility', 'Stabbing')
        Crossbow = @('Archery', 'Agility', 'Stabbing')
        'Unarmed Strike' = @('Unarmed', 'Strength', 'Blunt')
        'Natural Weapon' = @('Unarmed', 'Strength', $null)
    }

    $AllowedDamageTypes = @($CombatRules.PhysicalDamage.Types)

    foreach ($WeaponTypeName in $ExpectedTypeOrder) {
        if (-not $WeaponTypeData.WeaponTypes.ContainsKey($WeaponTypeName)) {
            throw "Weapon type is missing: $WeaponTypeName"
        }

        $WeaponType = $WeaponTypeData.WeaponTypes[$WeaponTypeName]

        foreach ($PropertyName in @(
            'WeaponSkill'
            'AssociatedAttribute'
            'DamageType'
            'HitsPerAttack'
            'RequiredOverrides'
        )) {
            if (-not $WeaponType.ContainsKey($PropertyName)) {
                throw "Weapon type '$WeaponTypeName' is missing: $PropertyName"
            }
        }

        $Expected = $ExpectedDefaults[$WeaponTypeName]

        if (
            $WeaponType.WeaponSkill -ne $Expected[0] -or
            $WeaponType.AssociatedAttribute -ne $Expected[1] -or
            $WeaponType.DamageType -ne $Expected[2]
        ) {
            throw "Weapon type defaults are incorrect: $WeaponTypeName"
        }

        if ($Skills.SkillOrder -notcontains $WeaponType.WeaponSkill) {
            throw "Weapon type '$WeaponTypeName' uses an unknown skill."
        }

        if (
            $GameRules.Attributes -notcontains
            $WeaponType.AssociatedAttribute
        ) {
            throw "Weapon type '$WeaponTypeName' uses an unknown attribute."
        }

        if (
            $null -ne $WeaponType.DamageType -and
            $AllowedDamageTypes -notcontains $WeaponType.DamageType
        ) {
            throw "Weapon type '$WeaponTypeName' uses an unknown damage type."
        }

        if ($null -ne $WeaponType.HitsPerAttack) {
            $HitsPerAttack = [int]$WeaponType.HitsPerAttack

            if ($HitsPerAttack -lt 1 -or $HitsPerAttack -gt 3) {
                throw "Weapon type '$WeaponTypeName' has invalid HitsPerAttack."
            }
        }
    }

    $NaturalWeapon =
        $WeaponTypeData.WeaponTypes['Natural Weapon']

    if (
        $null -ne $NaturalWeapon.DamageType -or
        @($NaturalWeapon.RequiredOverrides) -notcontains 'DamageType'
    ) {
        throw 'Natural Weapon must require an individual DamageType override.'
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
Assert-AttackAndArmorRules -Rules $CombatRules
Assert-WeaponTypeData `
    -WeaponTypeData $WeaponTypeData `
    -Skills $SkillData `
    -GameRules $GameRules `
    -CombatRules $CombatRules
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
