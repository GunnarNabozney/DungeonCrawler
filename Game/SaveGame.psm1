Set-StrictMode -Version Latest

$script:SaveSchemaVersion = 1

function Get-PrimarySavePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppRoot
    )

    $SaveDirectory = Join-Path $AppRoot 'Saves'
    return Join-Path $SaveDirectory 'slot-1.json'
}

function Get-SavePropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    $Property = $InputObject.PSObject.Properties[$Name]

    if ($null -eq $Property) {
        return $null
    }

    return $Property.Value
}

function ConvertTo-IntegerMap {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value
    )

    $Result = [ordered]@{}

    if ($null -eq $Value) {
        return $Result
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($Key in $Value.Keys) {
            $Result[[string]$Key] = [int]$Value[$Key]
        }

        return $Result
    }

    foreach ($Property in $Value.PSObject.Properties) {
        $Result[$Property.Name] = [int]$Property.Value
    }

    return $Result
}

function Assert-CharacterSaveData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft
    )

    $RequiredProperties = @(
        'Name'
        'Gender'
        'RaceId'
        'Race'
        'FavoredAttribute'
        'BaseAttributes'
        'AddedAttributes'
        'Attributes'
        'RacialProficiencies'
        'MinorTaggedSkills'
        'Skills'
    )

    foreach ($PropertyName in $RequiredProperties) {
        $HasProperty = (
            $CharacterDraft.PSObject.Properties.Name -contains
            $PropertyName
        )

        if (-not $HasProperty) {
            throw (
                'Character draft is missing property: ' +
                $PropertyName
            )
        }
    }
}

function Save-PrimaryCharacter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppRoot,

        [Parameter(Mandatory = $true)]
        [object]$CharacterDraft
    )

    Assert-CharacterSaveData -CharacterDraft $CharacterDraft

    $SavePath = Get-PrimarySavePath -AppRoot $AppRoot
    $SaveDirectory = Split-Path -Parent $SavePath

    if (-not (Test-Path -LiteralPath $SaveDirectory -PathType Container)) {
        [void](
            New-Item `
                -ItemType Directory `
                -Path $SaveDirectory `
                -Force
        )
    }

    $Character = [ordered]@{
        Name = [string]$CharacterDraft.Name
        Gender = [string]$CharacterDraft.Gender
        RaceId = [string]$CharacterDraft.RaceId
        Race = [string]$CharacterDraft.Race
        FavoredAttribute = [string]$CharacterDraft.FavoredAttribute
        BaseAttributes = ConvertTo-IntegerMap -Value $CharacterDraft.BaseAttributes
        AddedAttributes = ConvertTo-IntegerMap -Value $CharacterDraft.AddedAttributes
        Attributes = ConvertTo-IntegerMap -Value $CharacterDraft.Attributes
        RacialProficiencies = @($CharacterDraft.RacialProficiencies)
        MinorTaggedSkills = @($CharacterDraft.MinorTaggedSkills)
        Skills = ConvertTo-IntegerMap -Value $CharacterDraft.Skills
    }

    $Envelope = [ordered]@{
        SchemaVersion = $script:SaveSchemaVersion
        SavedAtUtc = [DateTime]::UtcNow.ToString('o')
        Character = $Character
    }

    $Json = ConvertTo-Json -InputObject $Envelope -Depth 8
    $Utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false

    [System.IO.File]::WriteAllText(
        $SavePath,
        $Json + [Environment]::NewLine,
        $Utf8NoBom
    )

    return [pscustomobject]@{
        Path = $SavePath
        SchemaVersion = $script:SaveSchemaVersion
        SavedAtUtc = $Envelope.SavedAtUtc
        CharacterDraft = $CharacterDraft
    }
}

function Get-PrimarySaveGame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppRoot
    )

    $SavePath = Get-PrimarySavePath -AppRoot $AppRoot

    if (-not (Test-Path -LiteralPath $SavePath -PathType Leaf)) {
        return $null
    }

    $Json = [System.IO.File]::ReadAllText($SavePath)

    try {
        $Envelope = ConvertFrom-Json -InputObject $Json -ErrorAction Stop
    }
    catch {
        throw (
            'Save slot 1 contains invalid JSON: ' +
            $_.Exception.Message
        )
    }

    $SchemaVersion = Get-SavePropertyValue `
        -InputObject $Envelope `
        -Name 'SchemaVersion'

    if ([int]$SchemaVersion -ne $script:SaveSchemaVersion) {
        throw (
            'Save slot 1 uses unsupported schema version: ' +
            [string]$SchemaVersion
        )
    }

    $SavedAtUtc = Get-SavePropertyValue `
        -InputObject $Envelope `
        -Name 'SavedAtUtc'

    $Character = Get-SavePropertyValue `
        -InputObject $Envelope `
        -Name 'Character'

    if ($null -eq $Character) {
        throw 'Save slot 1 has no character data.'
    }

    $RequiredProperties = @(
        'Name'
        'Gender'
        'RaceId'
        'Race'
        'FavoredAttribute'
        'BaseAttributes'
        'AddedAttributes'
        'Attributes'
        'RacialProficiencies'
        'MinorTaggedSkills'
        'Skills'
    )

    foreach ($PropertyName in $RequiredProperties) {
        $PropertyValue = Get-SavePropertyValue `
            -InputObject $Character `
            -Name $PropertyName

        if ($null -eq $PropertyValue) {
            throw (
                'Save slot 1 character is missing property: ' +
                $PropertyName
            )
        }
    }

    $RacialProficiencies = Get-SavePropertyValue `
        -InputObject $Character `
        -Name 'RacialProficiencies'

    $MinorTaggedSkills = Get-SavePropertyValue `
        -InputObject $Character `
        -Name 'MinorTaggedSkills'

    $CharacterDraft = [pscustomobject]@{
        Name = [string](Get-SavePropertyValue -InputObject $Character -Name 'Name')
        Gender = [string](Get-SavePropertyValue -InputObject $Character -Name 'Gender')
        RaceId = [string](Get-SavePropertyValue -InputObject $Character -Name 'RaceId')
        Race = [string](Get-SavePropertyValue -InputObject $Character -Name 'Race')
        FavoredAttribute = [string](Get-SavePropertyValue -InputObject $Character -Name 'FavoredAttribute')
        BaseAttributes = ConvertTo-IntegerMap -Value (Get-SavePropertyValue -InputObject $Character -Name 'BaseAttributes')
        AddedAttributes = ConvertTo-IntegerMap -Value (Get-SavePropertyValue -InputObject $Character -Name 'AddedAttributes')
        Attributes = ConvertTo-IntegerMap -Value (Get-SavePropertyValue -InputObject $Character -Name 'Attributes')
        RacialProficiencies = @($RacialProficiencies)
        MinorTaggedSkills = @($MinorTaggedSkills)
        Skills = ConvertTo-IntegerMap -Value (Get-SavePropertyValue -InputObject $Character -Name 'Skills')
    }

    return [pscustomobject]@{
        Path = $SavePath
        SchemaVersion = [int]$SchemaVersion
        SavedAtUtc = [string]$SavedAtUtc
        CharacterDraft = $CharacterDraft
    }
}

Export-ModuleMember -Function @(
    'Get-PrimarySavePath'
    'Get-PrimarySaveGame'
    'Save-PrimaryCharacter'
)
