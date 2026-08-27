-----------------------------------
-- Aftermath handling
-----------------------------------
xi = xi or {}

xi.aftermath = {}

xi.aftermath.type =
{
    RELIC    = 1,
    MYTHIC   = 2,
    EMPYREAN = 3,
    PRIME    = 4,
    AEONIC   = 5,
}

-----------------------------------
-- HELPERS : For aftermath eyes only
-----------------------------------
local getTier1RelicDuration = function(tp)
    return math.floor(tp * 0.02)
end

local getTier2RelicDuration = function(tp)
    return math.floor(tp * 0.06)
end

local getAftermathLevel = function(tp)
    return math.max(1, math.min(3, math.floor(tp / 1000)))
end

local getAeonicPotency = function(tp)
    if tp < 1500 then
        return 3
    elseif tp < 2000 then
        return 4
    elseif tp < 3000 then
        return math.min(9, 5 + math.floor((tp - 2000) / 200))
    end

    return 10
end

-- This server grants a few Aeonics custom linked WSs.  Keep those established
-- links while applying retail's rule that only the weapon's linked WS
-- activates aftermath; unrelated WSs merely benefit from an existing AM.
local aeonicWeaponSkills =
{
    [20515] = xi.weaponskill.SHIJIN_SPIRAL,
    [20594] = xi.weaponskill.EXENTERATOR,
    [20695] = xi.weaponskill.REQUIESCAT,
    [20843] = xi.weaponskill.UPHEAVAL,
    [20890] = xi.weaponskill.ENTROPY,
    [20935] = xi.weaponskill.STARDIVER,
    [20977] = xi.weaponskill.BLADE_SHUN,
    [21025] = xi.weaponskill.TACHI_SHOHA,
    [21082] = xi.weaponskill.REALMRAZER,
    [21147] = xi.weaponskill.SHATTERSOUL,
    [21694] = xi.weaponskill.DIMIDIATION,
    [21753] = xi.weaponskill.RUINATOR,
    [21485] = xi.weaponskill.LAST_STAND,
    [22117] = xi.weaponskill.APEX_ARROW,
}

xi.aftermath.effects =
{
    -----------------------------------
    -- Tier 1 Relic
    -----------------------------------
    [1]  = { mods = { xi.mod.SUBTLE_BLOW, 10 }, duration = getTier1RelicDuration, includePets = true }, -- Spharai
    [2]  = { mods = { xi.mod.CRITHITRATE, 5 }, duration = getTier1RelicDuration }, -- Mandau
    [3]  = { mods = { xi.mod.REGEN, 10 }, duration = getTier1RelicDuration }, -- Excalibur
    [4]  = { mods = { xi.mod.CRITHITRATE, 5 }, duration = getTier1RelicDuration }, -- Ragnarok
    [5]  = { mods = { xi.mod.ATTP, 10 }, duration = getTier1RelicDuration }, -- Guttler
    [6]  = { mods = { xi.mod.DMG, -2000 }, duration = getTier1RelicDuration }, -- Bravura
    [7]  = { mods = { xi.mod.HASTE_GEAR, 1000 }, duration = getTier1RelicDuration }, -- Apocalypse
    [8]  = { mods = { xi.mod.SPIKES, xi.subEffect.SHOCK_SPIKES, xi.mod.SPIKES_DMG, 10 }, duration = getTier1RelicDuration }, -- Gungnir
    [9]  = { mods = { xi.mod.SUBTLE_BLOW, 10 }, duration = getTier1RelicDuration }, -- Kikoku
    [10] = { mods = { xi.mod.STORETP, 7 }, duration = getTier1RelicDuration }, -- Amanomurakumo
    [11] = { mods = { xi.mod.ACC, 20 }, duration = getTier1RelicDuration }, -- Mjollnir
    [12] = { mods = { xi.mod.REFRESH, 8 }, duration = getTier1RelicDuration }, -- Claustrum
    [13] = { mods = { xi.mod.RACC, 20 }, duration = getTier1RelicDuration }, -- Yoichinoyumi
    [14] = { mods = { xi.mod.ENMITY, -20 }, duration = getTier1RelicDuration }, -- Annihilator

    -----------------------------------
    -- Tier 2 Relic
    -----------------------------------
    [15] = { mods = { xi.mod.SUBTLE_BLOW, 10, xi.mod.KICK_ATTACK_RATE, 15 }, duration = getTier2RelicDuration, includePets = true }, -- Spharai
    [16] = { mods = { xi.mod.CRITHITRATE, 5, xi.mod.CRIT_DMG_INCREASE, 5 }, duration = getTier2RelicDuration }, -- Mandau
    [17] = { mods = { xi.mod.REGEN, 30, xi.mod.REFRESH, 3 }, duration = getTier2RelicDuration }, -- Excalibur
    [18] = { mods = { xi.mod.CRITHITRATE, 10, xi.mod.ACC, 15 }, duration = getTier2RelicDuration }, -- Ragnarok
    [19] = { mods = { xi.mod.ATTP, 10 }, duration = getTier2RelicDuration, includePets = true }, -- Guttler
    [20] = { mods = { xi.mod.DMG, -2000, xi.mod.REGEN, 15 }, duration = getTier2RelicDuration }, -- Bravura
    [21] = { mods = { xi.mod.HASTE_ABILITY, 1000, xi.mod.ACC, 15 }, duration = getTier2RelicDuration }, -- Apocalypse
    [22] = { mods = { xi.mod.SPIKES, xi.subEffect.SHOCK_SPIKES, xi.mod.SPIKES_DMG, 19, xi.mod.ATTP, 5, xi.mod.DOUBLE_ATTACK, 5 }, duration = getTier2RelicDuration }, -- Gungnir
    [23] = { mods = { xi.mod.SUBTLE_BLOW, 10, xi.mod.ATTP, 10 }, duration = getTier2RelicDuration }, -- Kikoku
    [24] = { mods = { xi.mod.STORETP, 10, xi.mod.ZANSHIN, 10 }, duration = getTier2RelicDuration }, -- Amanomurakumo
    [25] = { mods = { xi.mod.ACC, 20, xi.mod.MACC, 20, xi.mod.REFRESH, 5 }, duration = getTier2RelicDuration }, -- Mjollnir
    [26] = { mods = { xi.mod.REFRESH, 15, xi.mod.DMG, -2000 }, duration = getTier2RelicDuration }, -- Claustrum
    [27] = { mods = { xi.mod.RACC, 30, xi.mod.SNAPSHOT, 5 }, duration = getTier2RelicDuration }, -- Yoichinoyumi
    [28] = { mods = { xi.mod.ENMITY, -25, xi.mod.RATTP, 10 }, duration = getTier2RelicDuration }, -- Annihilator

    -----------------------------------
    -- Tier 1 Mythic
    -----------------------------------
    [29] = -- Conqueror, Glanzfaust, Vajra, Burtgang, Liberator, Aymur, Kogarasumaru, Nagi, Ryunohige, Nirvana, Kenkonken, Terpsichore
    {
        mods =
        {
            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(tp / 100)
                end
            },

            {
                xi.mod.ATT,
                function(tp)
                    return math.floor(2 * tp / 50 - 60)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end
            }
        },

        duration = { 60, 90, 120 },
    },

    [30] = -- Yagrush, Carnwenhan
    {
        mods =
        {
            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(tp / 100)
                end
            },

            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(tp / 100 - 10)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end
            },
        },

        duration = { 180, 90, 120 },
    },

    [31] = -- Laevateinn, Murgleis, Tupsimati
    {
        mods =
        {
            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(tp / 100)
                end
            },

            {
                xi.mod.MATT,
                function(tp)
                    return math.floor(tp / 100)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end
            }
        },

        duration = { 180, 180, 120 },
    },

    [32] = -- Tizona
    {
        mods =
        {
            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(tp / 100)
                end
            },

            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(tp / 100 - 10)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end
            }
        },

        duration = { 60, 90, 120 },
    },

    [33] = -- Gastraphetes, Death Penalty
    {
        mods =
        {
            {
                xi.mod.RACC,
                function(tp)
                    return math.floor(tp / 100)
                end
            },

            {
                xi.mod.RATT,
                function(tp)
                    return math.floor(2 * tp / 50 - 60)
                end
            },

            {
                xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED,
                function(tp)
                    return 400
                end
            }
        },

        duration = { 60, 90, 120 },
    },

    -----------------------------------
    -- Tier 2 Mythic
    -----------------------------------
    [34] = -- Conqueror, Glanzfaust, Vajra, Burtgang, Liberator, Aymur, Kogarasumaru, Nagi, Ryunohige, Nirvana, Kenkonken, Terpsichore
    {
        mods =
        {
            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(3 * tp / 200)
                end
            },

            {
                xi.mod.ATT,
                function(tp)
                    return math.floor(3 * tp / 50 - 90)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 60
                end
            }
        },

        duration = { 90, 120, 180 },
    },

    [35] = -- Yagrush, Carnwenhan
    {
        mods =
        {
            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(3 * tp / 200)
                end
            },

            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(3 * tp / 200 - 15)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 60
                end
            }
        },

        duration = { 270, 120, 180 },
    },

    [36] = -- Laevateinn, Murgleis, Tupsimati
    {
        mods =
        {
            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(3 * tp / 200)
                end
            },

            {
                xi.mod.MATT,
                function(tp)
                    return math.floor(tp / 50 - 20)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 60
                end
            }
        },

        duration = { 270, 270, 180 },
    },

    [37] = -- Tizona
    {
        mods =
        {
            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(3 * tp / 200)
                end
            },

            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(3 * tp / 200 - 15)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 60
                end
            }
        },

        duration = { 90, 120, 180 },
    },

    [38] = -- Gastraphetes, Death Penalty
    {
        mods =
        {
            {
                xi.mod.RACC,
                function(tp)
                    return math.floor(tp / 50)
                end
            },

            {
                xi.mod.RATT,
                function(tp)
                    return math.floor(3 * tp / 50 - 90)
                end
            },

            {
                xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED,
                function(tp)
                    return 600
                end
            }
        },

        duration = { 90, 120, 180 },
    },

    -----------------------------------
    -- Tier 3 Mythic
    -----------------------------------
    [39] = -- Conqueror, Glanzfaust, Vajra, Burtgang, Liberator, Aymur, Kogarasumaru, Nagi, Ryunohige, Nirvana, Kenkonken, Terpsichore
    {
        mods =
        {
            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(tp / 50 + 10)
                end
            },

            {
                xi.mod.ATT,
                function(tp)
                    return math.floor(tp * 0.6 - 80)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end,

                xi.mod.MYTHIC_OCC_ATT_THRICE,
                function(tp)
                    return 20
                end
            }
        },

        duration = { 90, 120, 180 },
    },

    [40] = -- Yagrush, Carnwenhan
    {
        mods =
        {
            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(tp / 50 + 10)
                end
            },

            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(tp / 50 - 10)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end,

                xi.mod.MYTHIC_OCC_ATT_THRICE,
                function(tp)
                    return 20
                end
            }
        },

        duration = { 270, 120, 180 },
    },

    [41] = -- Laevateinn, Murgleis, Tupsimati
    {
        mods =
        {
            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(tp / 50 + 10)
                end
            },

            {
                xi.mod.MATT,
                function(tp)
                    return math.floor(tp / 50 - 10)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end,

                xi.mod.MYTHIC_OCC_ATT_THRICE,
                function(tp)
                    return 20
                end
            }
        },

        duration = { 270, 270, 180 },
    },

    [42] = -- Tizona
    {
        mods =
        {
            {
                xi.mod.ACC,
                function(tp)
                    return math.floor(tp / 50 + 10)
                end
            },

            {
                xi.mod.MACC,
                function(tp)
                    return math.floor(tp / 50 - 10)
                end
            },

            {
                xi.mod.MYTHIC_OCC_ATT_TWICE,
                function(tp)
                    return 40
                end,

                xi.mod.MYTHIC_OCC_ATT_THRICE,
                function(tp)
                    return 20
                end
            }
        },

        duration = { 90, 120, 180 },
    },

    [43] = -- Gastraphetes, Death Penalty
    {
        mods =
        {
            {
                xi.mod.RACC,
                function(tp)
                    return math.floor(tp / 50 + 10)
                end
            },

            {
                xi.mod.RATT,
                function(tp)
                    return math.floor(tp * 0.6 - 80)
                end
            },

            {
                xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED,
                function(tp)
                    return 400
                end,

                xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED,
                function(tp)
                    return 200
                end
            }
        },

        duration = { 90, 120, 180 },
    },

    -----------------------------------
    -- Tier 1 Empyrean
    -----------------------------------
    [44] =
    {
        mod       = xi.mod.REM_OCC_DO_DOUBLE_DMG,
        rangedMod = xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED, -- ranged Empyreans (Gandiva/Armageddon) proc on shots, not melee
        power = { 300, 400, 500 },
        duration = { 30, 60, 90 },
    },

    -----------------------------------
    -- Tier 2 Empyrean
    -----------------------------------
    [45] =
    {
        mod       = xi.mod.REM_OCC_DO_TRIPLE_DMG,
        rangedMod = xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED, -- ranged Empyreans (Gandiva/Armageddon) proc on shots, not melee
        power = { 300, 400, 500 },
        duration = { 60, 120, 180 },
    },

    -----------------------------------
    -- Prime  (FJB custom -- faithful to retail Prime Aftermath,
    --         bg-wiki.com/ffxi/Prime_Aftermath). TP-tiered like Empyrean:
    --         Lv.1/2/3 at 1000/2000/3000 TP, applied by the weapon's own Prime
    --         weaponskill (imperator/oshala/dagda/...). Values are Stage 5.
    --         `mods` is a list of { modId, { Lv1, Lv2, Lv3 } } applied in
    --         onEffectGain (Prime case). NOTE: the physical Damage Limit entry
    --         is largely INERT on this server's raised 131,071 damage cap --
    --         only the Staff/Club magic aftermaths are felt here.
    -----------------------------------
    [46] = -- Physical Primes: Imperator, Disaster, Origin, Diarmuid, Dragon Blow, Sarv, Terminus
    {
        mods     = { { xi.mod.DAMAGE_LIMITP, { 6, 9, 12 } } }, -- +6/9/12% (wiki Stage 5 range 6-12%; mid interpolated)
        duration = { 120, 180, 240 },
    },

    [47] = -- Prime Club / Lorg Mor (Dagda WS): Magic Damage + Cure potency  (WHM)
    {
        mods =
        {
            { xi.mod.MAGIC_DAMAGE, { 30, 50, 80 } },
            { xi.mod.CURE_POTENCY, { 30, 50, 80 } }, -- gear cure-potency caps at +50; AM may share that cap
        },
        duration = { 120, 180, 240 },
    },

    [48] = -- Prime Staff / Opashoro (Oshala WS): Magic Attack Bonus + Magic Damage  (BLM)
    {
        mods =
        {
            { xi.mod.MATT,         { 20, 30, 40 } }, -- MAB (3000-TP endpoint 40 documented; lower tiers interpolated)
            { xi.mod.MAGIC_DAMAGE, { 40, 60, 80 } }, -- M.Dmg (3000-TP endpoint 80 documented; lower tiers interpolated)
        },
        duration = { 120, 180, 240 },
    },

    -----------------------------------
    -- Aeonic: linked WS activation grants 3-10% skillchain and magic burst
    -- damage based on the actual TP spent.  All tiers last 180 seconds.
    -- Radiance/Umbra eligibility and consumption are handled in the core
    -- skillchain path, using the TP retained in the effect's subPower.
    -----------------------------------
    [49] = -- Aeonic melee
    {
        duration = { 180, 180, 180 },
    },

    [50] = -- Aeonic ranged
    {
        duration = { 180, 180, 180 },
    }
}

xi.aftermath.addAeonicStatusEffect = function(player, tp, weaponSlot, wsId)
    if not player or player:getObjType() ~= xi.objType.PC then
        return
    end

    local weapon = player:getStorageItem(0, 0, weaponSlot)
    if
        not weapon or
        aeonicWeaponSkills[weapon:getID()] ~= wsId
    then
        return
    end

    xi.aftermath.addStatusEffect(player, tp, weaponSlot, xi.aftermath.type.AEONIC)
end

xi.aftermath.addStatusEffect = function(player, tp, weaponSlot, aftermathType)
    -- Players only!
    if player:getObjType() ~= xi.objType.PC then
        return
    end

    -- TP Bonus does not affect aftermath, and TP-draining interactions must
    -- not produce an invalid tier index.
    tp = utils.clamp(tp, 1000, 3000)

    local weapon = player:getStorageItem(0, 0, weaponSlot)
    if not weapon then
        return
    end

    local id = weapon:getMod(xi.mod.AFTERMATH)

    -- Verify the aftermath ID matches the aftermath Type
    local invalid = false
    switch (aftermathType) : caseof
    {
        -- Relic
        [1] = function(x)
            invalid = id > 28
        end,

        -- Mythic
        [2] = function(x)
            invalid = id < 29 or id > 43
        end,

        -- Empyrean
        [3] = function(x)
            invalid = id < 44 or id > 45
        end,

        -- Prime
        [4] = function(x)
            invalid = id < 46 or id > 48
        end,

        -- Aeonic
        [5] = function(x)
            invalid = id < 49 or id > 50
        end
    }

    if invalid then
        return
    end

    local aftermath = xi.aftermath.effects[id]
    if not aftermath then
        return
    end

    if not xi.aftermath.canOverwrite(player, tp, id, aftermathType) then
        return
    end

    player:delStatusEffect(xi.effect.AFTERMATH)
    switch (aftermathType) : caseof
    {
        -- Relic
        [1] = function(x)
            if id == 8 or id == 22 then
                -- Gungnir's aftermath supplies Shock Spikes. There is no
                -- xi.effectType.SPIKES enum; indexing it aborted Geirskogul
                -- before both aftermath application and damage calculation.
                player:delStatusEffect(xi.effect.BLAZE_SPIKES)
                player:delStatusEffect(xi.effect.ICE_SPIKES)
                player:delStatusEffect(xi.effect.SHOCK_SPIKES)
                player:delStatusEffect(xi.effect.DREAD_SPIKES)
            end

            player:addStatusEffect(xi.effect.AFTERMATH, { power = id, duration = aftermath.duration(tp), origin = player, subType = weaponSlot, subPower = tp, tier = aftermathType })
        end,

        -- Mythic
        [2] = function(x)
            local tier = getAftermathLevel(tp)
            local icon = xi.effect['AFTERMATH_LV'..tier]
            player:addStatusEffect(xi.effect.AFTERMATH, { power = id, duration = aftermath.duration[tier], origin = player, icon = icon, subType = weaponSlot, subPower = tp, tier = aftermathType })
        end,

        -- Empyrean
        [3] = function(x)
            local tier = getAftermathLevel(tp)
            local icon = xi.effect['AFTERMATH_LV'..tier]
            player:addStatusEffect(xi.effect.AFTERMATH, { power = id, duration = aftermath.duration[tier], origin = player, icon = icon, subType = weaponSlot, subPower = tp, tier = aftermathType })
        end,

        -- Prime (TP-tiered like Empyrean; the mods are applied in onEffectGain)
        [4] = function(x)
            local tier = getAftermathLevel(tp)
            local icon = xi.effect['AFTERMATH_LV'..tier]
            player:addStatusEffect(xi.effect.AFTERMATH, { power = id, duration = aftermath.duration[tier], origin = player, icon = icon, subType = weaponSlot, subPower = tp, tier = aftermathType })
        end,

        -- Aeonic
        [5] = function(x)
            local tier = getAftermathLevel(tp)
            local icon = xi.effect['AFTERMATH_LV'..tier]
            player:addStatusEffect(xi.effect.AFTERMATH, { power = id, duration = aftermath.duration[tier], origin = player, icon = icon, subType = weaponSlot, subPower = tp, tier = aftermathType })
        end
    }
end

xi.aftermath.applyRangedMythicDamageProc = function(player, damage)
    if not player or damage <= 0 then
        return damage
    end

    local effect = player:getStatusEffect(xi.effect.AFTERMATH)
    if
        not effect or
        effect:getTier() ~= xi.aftermath.type.MYTHIC
    then
        return damage
    end

    local tripleRate = math.floor(player:getMod(xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED) / 10)
    local doubleRate = math.floor(player:getMod(xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED) / 10)
    local roll       = math.random(1, 100)

    if roll <= tripleRate then
        return damage * 3
    elseif roll <= tripleRate + doubleRate then
        return damage * 2
    end

    return damage
end

-----------------------------------
-- Effect Power = Aftermath ID
-- Effect SubPower = TP
-- Effect Tier = Aftermath Type
-----------------------------------
xi.aftermath.onEffectGain = function(target, effect)
    local aftermath = xi.aftermath.effects[effect:getPower()]
    switch (effect:getTier()) : caseof
    {
        -- Relic
        [1] = function(x)
            local pet = target:getPet()
            if
                pet and
                aftermath.includePets
            then
                -- pets gain same mods as the player, so give them the effect without a loss message
                pet:delStatusEffectSilent(xi.effect.AFTERMATH)
                pet:addStatusEffect(xi.effect.AFTERMATH, { power = effect:getPower(), duration = effect:getDuration() / 1000, origin = target, subType = effect:getSubType(), subPower = effect:getSubPower(), tier = effect:getTier() })
                pet:getStatusEffect(xi.effect.AFTERMATH):addEffectFlag(xi.effectFlag.NO_LOSS_MESSAGE)
            end

            for i = 1, #aftermath.mods, 2 do
                effect:addMod(aftermath.mods[i], aftermath.mods[i + 1])
            end
        end,

        -- Mythic
        [2] = function(x)
            local tp  = effect:getSubPower()
            -- Retail Mythic tiers are mutually exclusive: AM1 accuracy,
            -- AM2 attack, AM3 occasionally attacks twice/thrice.
            local mods = aftermath.mods[getAftermathLevel(tp)]
            for i = 1, #mods, 2 do
                effect:addMod(mods[i], mods[i + 1](tp))
            end

            -- Copy effect AND mods onto the pet. Previously the pet got a bare
            -- AFTERMATH status while OCC_ATT_TWICE/THRICE stayed on the master
            -- only — Aymur AM3 never multi-hit on jug autos.
            local pet = target:getPet()
            if pet then
                pet:delStatusEffectSilent(xi.effect.AFTERMATH)
                pet:addStatusEffect(xi.effect.AFTERMATH, { power = effect:getPower(), duration = effect:getDuration() / 1000, origin = target, subType = effect:getSubType(), subPower = effect:getSubPower(), tier = effect:getTier() })
                local petEffect = pet:getStatusEffect(xi.effect.AFTERMATH)
                if petEffect then
                    petEffect:addEffectFlag(xi.effectFlag.NO_LOSS_MESSAGE)
                    for i = 1, #mods, 2 do
                        petEffect:addMod(mods[i], mods[i + 1](tp))
                    end
                end
            end
        end,

        -- Empyrean
        [3] = function(x)
            local mod = aftermath.mod
            -- The source slot is stored on the status effect. Checking the
            -- currently equipped ranged weapon is ambiguous when a player has
            -- both melee and ranged Empyreans equipped (both use effect 44/45).
            if
                aftermath.rangedMod and
                effect:getSubType() == xi.slot.RANGED
            then
                mod = aftermath.rangedMod
            end
            effect:addMod(mod, aftermath.power[getAftermathLevel(effect:getSubPower())])
        end,

        -- Prime (multi-mod, TP-tiered): apply every mod at the current Lv tier
        [4] = function(x)
            local tier = getAftermathLevel(effect:getSubPower())
            for _, m in ipairs(aftermath.mods) do
                effect:addMod(m[1], m[2][tier])
            end

            -- Retail "Aftermath (Incl. Pets)" — copy DAMAGE_LIMITP etc. to jug/avatar.
            local pet = target:getPet()
            if pet then
                pet:delStatusEffectSilent(xi.effect.AFTERMATH)
                pet:addStatusEffect(xi.effect.AFTERMATH, { power = effect:getPower(), duration = effect:getDuration() / 1000, origin = target, subType = effect:getSubType(), subPower = effect:getSubPower(), tier = effect:getTier() })
                local petEffect = pet:getStatusEffect(xi.effect.AFTERMATH)
                if petEffect then
                    petEffect:addEffectFlag(xi.effectFlag.NO_LOSS_MESSAGE)
                    for _, m in ipairs(aftermath.mods) do
                        petEffect:addMod(m[1], m[2][tier])
                    end
                end
            end
        end,

        -- Aeonic
        [5] = function(x)
            local potency = getAeonicPotency(effect:getSubPower())
            effect:addMod(xi.mod.SKILLCHAINBONUS, potency)
            effect:addMod(xi.mod.MAGIC_BURST_BONUS_CAPPED, potency)
        end
    }
end

xi.aftermath.canOverwrite = function(player, tp, aftermathId, aftermathType)
    local effect = player:getStatusEffect(xi.effect.AFTERMATH)
    if not effect then
        return true
    end

    -- Empyrean > Mythic > Relic 'cause why not?
    if aftermathType < effect:getTier() then
        return false
    end

    local canOverwrite = false
    switch (aftermathType) : caseof
    {
        -- Relic
        [1] = function(x)
            canOverwrite = true
        end,

        -- Mythic
        [2] = function(x)
            local currentLevel = getAftermathLevel(effect:getSubPower())
            local newLevel = getAftermathLevel(tp)
            canOverwrite = currentLevel == 1 or currentLevel < newLevel
        end,

        -- Empyrean
        [3] = function(x)
            local currentLevel = getAftermathLevel(effect:getSubPower())
            local newLevel = getAftermathLevel(tp)
            canOverwrite = currentLevel == 1 or currentLevel < newLevel
        end,

        -- Prime (same TP-level overwrite rule as Empyrean)
        [4] = function(x)
            local currentLevel = getAftermathLevel(effect:getSubPower())
            local newLevel = getAftermathLevel(tp)
            canOverwrite = currentLevel == 1 or currentLevel < newLevel
        end,

        -- Aeonic (same retail tier overwrite hierarchy as Mythic/Empyrean)
        [5] = function(x)
            local currentLevel = getAftermathLevel(effect:getSubPower())
            local newLevel = getAftermathLevel(tp)
            canOverwrite = currentLevel == 1 or currentLevel < newLevel
        end,
    }

    return canOverwrite
end
