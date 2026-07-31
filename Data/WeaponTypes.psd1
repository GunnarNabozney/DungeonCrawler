@{
    DesignStatus = 'ApprovedDefaultsWithPendingHitCounts'

    WeaponTypeOrder = @(
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

    IndividualWeaponRequiredProperties = @(
        'Id'
        'Name'
        'WeaponType'
        'BaseDamage'
    )

    TypeDefaultProperties = @(
        'WeaponSkill'
        'AssociatedAttribute'
        'DamageType'
        'HitsPerAttack'
    )

    OverrideContainer = 'Overrides'

    AllowedOverrideProperties = @(
        'WeaponSkill'
        'AssociatedAttribute'
        'DamageType'
        'HitsPerAttack'
    )

    ResolutionPrecedence = @(
        'IndividualWeaponOverride'
        'WeaponTypeDefault'
    )

    PendingTypeAssignments = @(
        'HitsPerAttack'
    )

    WeaponTypes = @{
        'One-Handed Sword' = @{
            WeaponSkill = 'Swords'
            AssociatedAttribute = 'Strength'
            DamageType = 'Slicing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'Two-Handed Sword' = @{
            WeaponSkill = 'Swords'
            AssociatedAttribute = 'Strength'
            DamageType = 'Slicing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'Finesse Sword' = @{
            WeaponSkill = 'Swords'
            AssociatedAttribute = 'Agility'
            DamageType = 'Stabbing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'One-Handed Axe' = @{
            WeaponSkill = 'Axes'
            AssociatedAttribute = 'Strength'
            DamageType = 'Slicing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'Two-Handed Axe' = @{
            WeaponSkill = 'Axes'
            AssociatedAttribute = 'Strength'
            DamageType = 'Slicing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'One-Handed Hammer' = @{
            WeaponSkill = 'Hammers'
            AssociatedAttribute = 'Strength'
            DamageType = 'Blunt'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'Two-Handed Hammer' = @{
            WeaponSkill = 'Hammers'
            AssociatedAttribute = 'Strength'
            DamageType = 'Blunt'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        Dagger = @{
            WeaponSkill = 'Daggers'
            AssociatedAttribute = 'Agility'
            DamageType = 'Stabbing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        Bow = @{
            WeaponSkill = 'Archery'
            AssociatedAttribute = 'Agility'
            DamageType = 'Stabbing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        Crossbow = @{
            WeaponSkill = 'Archery'
            AssociatedAttribute = 'Agility'
            DamageType = 'Stabbing'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'Unarmed Strike' = @{
            WeaponSkill = 'Unarmed'
            AssociatedAttribute = 'Strength'
            DamageType = 'Blunt'
            HitsPerAttack = $null
            RequiredOverrides = @()
        }

        'Natural Weapon' = @{
            WeaponSkill = 'Unarmed'
            AssociatedAttribute = 'Strength'
            DamageType = $null
            HitsPerAttack = $null
            RequiredOverrides = @(
                'DamageType'
            )
        }
    }
}