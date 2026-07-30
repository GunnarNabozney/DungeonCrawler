@{
    RaceOrder = @(
        'Human'
        'HighElf'
        'DarkElf'
        'Halfling'
        'Dwarf'
        'HalfOrc'
    )

    Races = @{
        Human = @{
            DisplayName = 'Human'
            Description = 'Adaptable and ambitious, Humans thrive through courage, wit, and determination. They are capable swordsmen, practical cooks, and shrewd traders.'
            FavoredAttribute = 'Charisma'
            Proficiencies = @('Bartering', 'Swords', 'Cooking')
            BaseAttributes = @{
                Strength = 5
                Intelligence = 5
                Wisdom = 4
                Agility = 4
                Fortitude = 5
                Charisma = 7
            }
        }

        HighElf = @{
            DisplayName = 'High Elf'
            Description = 'High Elves are disciplined, perceptive, and deeply attuned to sacred power. Their keen senses make them accomplished archers, healers, and lightly armored warriors.'
            FavoredAttribute = 'Wisdom'
            Proficiencies = @('Restoration', 'Light Armor', 'Archery')
            BaseAttributes = @{
                Strength = 4
                Intelligence = 6
                Wisdom = 8
                Agility = 5
                Fortitude = 3
                Charisma = 4
            }
        }

        DarkElf = @{
            DisplayName = 'Dark Elf'
            Description = 'Dark Elves are cunning scholars of forbidden knowledge who favor precision over brute force. Unholy rites, alchemy, and hidden blades are their preferred tools.'
            FavoredAttribute = 'Intelligence'
            Proficiencies = @('Unholy', 'Alchemy', 'Daggers')
            BaseAttributes = @{
                Strength = 4
                Intelligence = 8
                Wisdom = 5
                Agility = 6
                Fortitude = 3
                Charisma = 4
            }
        }

        Halfling = @{
            DisplayName = 'Halfling'
            Description = 'Small, agile, and remarkably resilient, Halflings survive through patience, instinct, and an intimate understanding of the natural world.'
            FavoredAttribute = 'Agility'
            Proficiencies = @('Druidry', 'Sneaking', 'Survival')
            BaseAttributes = @{
                Strength = 3
                Intelligence = 4
                Wisdom = 6
                Agility = 8
                Fortitude = 5
                Charisma = 4
            }
        }

        Dwarf = @{
            DisplayName = 'Dwarf'
            Description = 'Dwarves are steadfast warriors and master craftsmen shaped by stone, fire, and hard labor. They are formidable in heavy armor and deadly with hammers.'
            FavoredAttribute = 'Fortitude'
            Proficiencies = @('Smithing', 'Heavy Armor', 'Hammers')
            BaseAttributes = @{
                Strength = 6
                Intelligence = 4
                Wisdom = 5
                Agility = 4
                Fortitude = 8
                Charisma = 3
            }
        }

        HalfOrc = @{
            DisplayName = 'Half-Orc'
            Description = 'Half-Orcs possess immense physical strength and stubborn endurance. They favor direct combat and practical craftsmanship, relying on powerful axe blows, hardened leather, and their own fists.'
            FavoredAttribute = 'Strength'
            Proficiencies = @('Axes', 'Leatherworking', 'Unarmed')
            BaseAttributes = @{
                Strength = 8
                Intelligence = 3
                Wisdom = 4
                Agility = 5
                Fortitude = 6
                Charisma = 4
            }
        }
    }
}
