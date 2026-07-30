@{
    Attributes = @(
        'Strength'
        'Intelligence'
        'Wisdom'
        'Agility'
        'Fortitude'
        'Charisma'
    )

    AttributeDescriptions = @{
        Strength = 'Physical power, melee damage, and carrying capacity.'
        Intelligence = 'Maximum mana and offensive spell power.'
        Wisdom = 'Mana recovery, healing, protective magic, and resistance to magical effects.'
        Agility = 'Accuracy, attack speed, evasion, and critical strikes.'
        Fortitude = 'Maximum health and resistance to poison or disease.'
        Charisma = 'Buying and selling prices and improved quest rewards.'
    }

    GenderOptions = @(
        'Male'
        'Female'
    )

    SkillMinimum = 0
    SkillMaximum = 100
    RacialProficiencyStart = 10
    MinorTagSkillCount = 3
    MinorTagSkillStart = 5

    CharacterCreation = @{
        BaseAttributeTotal = 30
        SpendableAttributePoints = 5
        AllowReducingBaseAttributes = $false
        AddedAttributeMaximum = $null
        NameMaximumLength = 20
    }
}
