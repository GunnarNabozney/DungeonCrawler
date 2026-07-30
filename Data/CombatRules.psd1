@{
    Initiative = @{
        PrimaryAttribute = 'Agility'
        SecondaryAttribute = 'Wisdom'
        TieBreaker = 'D100'

        EnemyNumbering = @{
            AssignAfterInitiative = $true
            StableForEncounter = $true
            RenumberAfterDefeat = $false
            RenumberAfterInitiativeChange = $false
            ReinforcementAssignment = 'NextUnused'
            ReuseNumbers = $false
        }
    }

    Round = @{
        Definition = 'OneCompleteInitiativePass'
        MechanicalRefresh = $false
        Purposes = @(
            'UI'
            'CombatLog'
        )
    }

    Turn = @{
        AvailablePhases = @(
            'Movement'
            'Action'
            'Reaction'
        )

        AllowedMovementActionOrders = @(
            'MovementThenAction'
            'ActionThenMovement'
        )

        MovementCanSplit = $false
        ActionCanSplit = $false
        UnusedMovementCarriesForward = $false
        UnusedActionCarriesForward = $false
        MovementRefresh = 'StartOfOwnTurn'
        ActionRefresh = 'StartOfOwnTurn'
        ReactionUsesBeforeRefresh = 1
        ReactionRefresh = 'StartOfOwnTurn'
        ReactionMayFollowActionAgainstCombatant = $true
        ReactionMayOccurDuringOwnTurnWhenPermitted = $true
    }

    Actions = @{
        Available = @(
            'Attack'
            'Ability'
            'Item'
            'Defend'
            'Interact'
        )

        ItemRequiredTag = 'Usable'
        InteractIsContextual = $true
        DefendDuration = 'UntilNextTurn'
    }

    Movement = @{
        SquareFeet = 5
        DefaultState = 'Normal'
        DerivedFromAgility = $false

        States = @{
            Slow = 10
            Normal = 20
            Fast = 30
        }

        StatusMappings = @{
            ContinuousSlow = @{
                Type = 'Continuous'
                State = 'Slow'
            }

            ContinuousFast = @{
                Type = 'Continuous'
                State = 'Fast'
            }

            TemporarySlow = @{
                Type = 'Triggered'
                Category = 'CC'
                State = 'Slow'
            }

            TemporaryFast = @{
                Type = 'Triggered'
                Category = 'Buff'
                State = 'Fast'
            }
        }
    }

    StatusEffects = @{
        Types = @(
            'Continuous'
            'Triggered'
        )

        Continuous = @{
            PersistsOutsideCombat = $true
            TurnCountRequired = $false
            PersistsUntilRemovedByRule = $true
        }

        Triggered = @{
            CombatOnly = $true
            TurnCountRequired = $true
            ResolutionPriority = @(
                'CC'
                'Debuff'
                'Buff'
            )
        }
    }

    Evasion = @{
        Roll = 'D100'
        BaseChance = 10
        DifferenceStep = 5
        MinimumChance = 5
        MaximumChance = 40

        Attack = @{
            AttackerAttribute = 'Agility'
            DefenderAttribute = 'Agility'
        }

        PhysicalAbility = @{
            AttackerAttribute = 'Agility'
            DefenderAttribute = 'Agility'
        }

        MagicAbility = @{
            AttackerAttribute = 'Wisdom'
            DefenderAttribute = 'Agility'
        }
    }

    Accuracy = @{
        AppliesTo = @(
            'Attack'
        )

        Roll = 'D100'
        BaseChance = 70
        DifferenceDivisor = 2
        MinimumChance = 10
        MaximumChance = 95
        AttackerSkill = 'WeaponSkill'
        DefenderSkill = 'Defense'
    }

    AttackResolution = @(
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

    Defense = @{
        Skill = 'Defense'
        Opposes = 'WeaponSkill'
        ProgressionTrigger = 'TakingDamage'
    }
}