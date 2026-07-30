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

$RequiredFiles = @(
    $NativeSourcePath
    $RaceDataPath
    $SkillDataPath
    $GameRulesPath
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

    if ($Skills.SkillOrder.Count -ne 27) {
        throw "The current design requires exactly 27 skills. Found: $($Skills.SkillOrder.Count)"
    }

    $UniqueSkills = @($Skills.SkillOrder | Sort-Object -Unique)
    if ($UniqueSkills.Count -ne $Skills.SkillOrder.Count) {
        throw 'Skills.psd1 contains duplicate skills.'
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

Assert-GameData -Races $RaceData -Skills $SkillData -Rules $GameRules

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
