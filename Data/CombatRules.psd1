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
        Rounding = 'FloorBeforeClamp'
        AttackerSkill = 'WeaponSkill'
        DefenderSkill = 'Defense'
    }

    PhysicalDamage = @{
        Types = @(
            'Blunt'
            'Slicing'
            'Stabbing'
        )

        GenericPhysicalTypeAllowed = $false
        AutomaticStatusEffects = $false
        MatchingArmorProfileRequired = $true
    }

    DamagePayload = @{
        OnePayloadPerHit = $true
        ContainsResolvedRawDamage = $true
        ContainsDamageFormula = $false

        RequiredFields = @(
            'SourceCombatantId'
            'TargetCombatantId'
            'TargetBodyLocation'
            'SourceKind'
            'SourceId'
            'HitNumber'
            'HitCount'
            'DamageComponents'
            'AttachedEffects'
        )

        DamageComponentFields = @(
            'DamageType'
            'RawAmount'
        )

        SourceKinds = @(
            'Attack'
            'Ability'
        )
    }

    DamageResult = @{
        PreservePerComponentResults = $true

        RequiredFields = @(
            'RawDamage'
            'DamageType'
            'ArmorValue'
            'MitigationPercent'
            'PreventedDamage'
            'FinalDamage'
            'HealthBefore'
            'HealthAfter'
            'TargetDefeated'
        )
    }

    Attack = @{
        Targeting = @{
            BodyLocationRequired = $true
            BodyLocations = @(
                'Head'
                'Chest'
                'Left Arm'
                'Right Arm'
                'Left Leg'
                'Right Leg'
            )

            MultiHitKeepsSelectedLocation = $true
        }

        RawDamage = @{
            WeaponSubtotalComponents = @(
                'WeaponBaseDamage'
                'CurrentEffectiveAssociatedAttribute'
            )

            AttributeContributionRatio = 1
            WeaponSkillContributesByDefault = $false

            PerkContribution = @{
                PercentageOnly = $true
                StoredAsWholeNumber = $true
                Combination = 'Add'
                AppliedTo = 'WeaponSubtotal'
                AppliedOncePerAttack = $true
                Rounding = 'Floor'
            }
        }

        MultiHit = @{
            MechanicalProperty = 'HitsPerAttack'
            PropertyOwner = 'WeaponType'
            IndividualWeaponOverrideAllowed = $true
            MinimumHits = 1
            MaximumHits = 3

            SpeedLabels = @{
                '1' = 'Slow'
                '2' = 'Normal'
                '3' = 'Fast'
            }

            TotalRawDamageCalculatedOnce = $true
            AttributeAppliedOncePerAttack = $true
            PerksAppliedOncePerAttack = $true
            Division = 'EvenWithEarliestRemainder'
            FailedHitDamageRedistributed = $false
            WeaponBaseDamageMinimumRule = 'HitsPerAttack'
        }

        ReactionTiming = @{
            OfferOn = 'FirstSuccessfulEligibleTrigger'
            DeclineConsumesReaction = $false
            ReofferAfterDecline = $true
            UseConsumesReaction = $true
            Refresh = 'StartOfOwnTurn'
            FailedEvasionCreatesOffer = $false
            FailedAccuracyCreatesOffer = $false
        }

        HitResolution = @(
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
        )

        Defeat = @{
            CheckAfterEveryHit = $true
            StopRemainingHits = $true
            UnresolvedHitDamageIsLost = $true
            DefaultRetargeting = $false
            ExplicitRuleMayPermitRetargeting = $true
        }

        Deferred = @{
            TargetRangeAndLineOfSight = $true
            AttachedEffectEligibility = $true
            IndividualReactionOutcomes = $true
            PoisonSpecifics = $true
        }
    }

    Armor = @{
        DesignStatus = 'WorkingConcept'
        ExactArmorProfilesFinalized = $false
        UsesRawArmorValues = $true
        HigherRawValueIsBetter = $true

        Slots = @(
            'Head'
            'Chest'
            'Left Arm'
            'Right Arm'
            'Left Leg'
            'Right Leg'
        )

        Ratings = @(
            'Blunt'
            'Slicing'
            'Stabbing'
        )

        EmptySlotArmor = 0
        NaturalArmorMayApply = $true
        MatchingDamageTypeOnly = $true
        ResolvePerSuccessfulHit = $true

        Mitigation = @{
            Model = 'DiminishingReturns'
            ArmorScale = 100
            Formula = 'ArmorDividedByArmorPlusScale'
            MaximumMitigationPercent = 80
            FinalDamageRounding = 'Floor'
            MinimumFinalDamage = 1
            RecommendedNormalMaximumArmor = 300
        }
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