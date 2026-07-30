Set-StrictMode -Version Latest

function Get-CharacterPreviewValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Map,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $Map) {
        return 0
    }

    if ($Map -is [System.Collections.IDictionary]) {
        if ($Map.Contains($Name)) {
            return [int]$Map[$Name]
        }

        return 0
    }

    $Property = $Map.PSObject.Properties[$Name]

    if ($null -eq $Property) {
        return 0
    }

    return [int]$Property.Value
}

function Draw-CharacterPreview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft
    )

    ConsoleUI\Write-At `
        -X 5 `
        -Y 4 `
        -Text ('NAME: ' + [string]$CharacterDraft.Name) `
        -Color Yellow

    ConsoleUI\Write-At `
        -X 5 `
        -Y 5 `
        -Text ('RACE: ' + [string]$CharacterDraft.Race) `
        -Color Gray

    ConsoleUI\Write-At `
        -X 5 `
        -Y 6 `
        -Text ('GENDER: ' + [string]$CharacterDraft.Gender) `
        -Color Gray

    ConsoleUI\Write-At `
        -X 40 `
        -Y 5 `
        -Text (
            'FAVORED: ' +
            [string]$CharacterDraft.FavoredAttribute
        ) `
        -Color DarkYellow

    ConsoleUI\Write-At `
        -X 5 `
        -Y 9 `
        -Text 'ATTRIBUTES' `
        -Color DarkYellow

    $AttributeLayout = @(
        @('Strength', 7, 11)
        @('Intelligence', 7, 12)
        @('Wisdom', 7, 13)
        @('Agility', 40, 11)
        @('Fortitude', 40, 12)
        @('Charisma', 40, 13)
    )

    foreach ($Entry in $AttributeLayout) {
        $AttributeName = [string]$Entry[0]
        $X = [int]$Entry[1]
        $Y = [int]$Entry[2]

        $Value = Get-CharacterPreviewValue `
            -Map $CharacterDraft.Attributes `
            -Name $AttributeName

        if (
            $AttributeName -eq
            [string]$CharacterDraft.FavoredAttribute
        ) {
            $Color = [ConsoleColor]::Yellow
        }
        else {
            $Color = [ConsoleColor]::Gray
        }

        $AttributeText = '{0,-13} {1,3}' -f `
            $AttributeName,
            $Value

        ConsoleUI\Write-At `
            -X $X `
            -Y $Y `
            -Text $AttributeText `
            -Color $Color
    }

    ConsoleUI\Write-At `
        -X 5 `
        -Y 16 `
        -Text 'RACIAL PROFICIENCIES' `
        -Color DarkYellow

    $RacialText = @(
        $CharacterDraft.RacialProficiencies
    ) -join ', '

    ConsoleUI\Write-At `
        -X 7 `
        -Y 18 `
        -Text $RacialText `
        -Color Yellow

    ConsoleUI\Write-At `
        -X 5 `
        -Y 20 `
        -Text 'TAG SKILLS' `
        -Color DarkYellow

    $TagSkillText = @(
        $CharacterDraft.MinorTaggedSkills
    ) -join ', '

    ConsoleUI\Write-At `
        -X 7 `
        -Y 22 `
        -Text $TagSkillText `
        -Color Yellow
}

Export-ModuleMember -Function @(
    'Draw-CharacterPreview'
)
