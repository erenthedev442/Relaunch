require('scripts/globals/aftermath')

describe('retail REMA and Prime aftermath handling', function()
    local function makePlayer(aftermathId, slot, options)
        options = options or {}
        local applied
        local weapon =
        {
            getID = function()
                return options.itemId or 0
            end,

            getMod = function(_, modId)
                if modId == xi.mod.AFTERMATH then
                    return aftermathId
                end

                return 0
            end,
        }

        local player =
        {
            getObjType = function()
                return xi.objType.PC
            end,

            getStorageItem = function(_, _, _, requestedSlot)
                if requestedSlot == slot then
                    return weapon
                end

                return nil
            end,

            getStatusEffect = function(_, effectId)
                if effectId == xi.effect.AFTERMATH then
                    return options.existingEffect
                end

                return nil
            end,

            delStatusEffect = function()
            end,

            delStatusEffectsByType = function()
            end,

            addStatusEffect = function(_, effectId, params)
                applied = { effectId = effectId, params = params }
            end,
        }

        return player, function()
            return applied
        end
    end

    it('rejects an aftermath ID from the wrong REMA family', function()
        local player, getApplied = makePlayer(49, xi.slot.MAIN)

        xi.aftermath.addStatusEffect(player, 3000, xi.slot.MAIN, xi.aftermath.type.MYTHIC)

        assert(getApplied() == nil)
    end)

    it('clamps family levels so effect tables are always indexed safely', function()
        local empyrean, getEmpyrean = makePlayer(45, xi.slot.MAIN)
        xi.aftermath.addStatusEffect(
            empyrean, 999, xi.slot.MAIN, xi.aftermath.type.EMPYREAN)

        assert(getEmpyrean().params.duration == 60)
        assert(getEmpyrean().params.icon == xi.effect.AFTERMATH_LV1)
        assert(getEmpyrean().params.subType == xi.slot.MAIN)

        local mythic, getMythic = makePlayer(39, xi.slot.MAIN)
        xi.aftermath.addStatusEffect(
            mythic, 4000, xi.slot.MAIN, xi.aftermath.type.MYTHIC)

        assert(getMythic().params.duration == 180)
        assert(getMythic().params.icon == xi.effect.AFTERMATH_LV3)
    end)

    it('routes ranged Empyrean aftermath to ranged proc modifiers', function()
        local added = {}
        local rangedWeapon =
        {
            getMod = function(_, modId)
                return modId == xi.mod.AFTERMATH and 45 or 0
            end,
        }
        local target =
        {
            getStorageItem = function(_, _, _, slot)
                return slot == xi.slot.RANGED and rangedWeapon or nil
            end,
            getPet = function()
                return nil
            end,
        }
        local effect =
        {
            getPower = function()
                return 45
            end,
            getTier = function()
                return xi.aftermath.type.EMPYREAN
            end,
            getSubPower = function()
                return 3000
            end,
            getSubType = function()
                return xi.slot.RANGED
            end,
            addMod = function(_, modId, value)
                added[modId] = value
            end,
        }

        xi.aftermath.onEffectGain(target, effect)

        assert(added[xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED] == 500)
        assert(added[xi.mod.REM_OCC_DO_TRIPLE_DMG] == nil)
    end)

    it('applies only the selected Mythic tier', function()
        local function getMods(tp)
            local added = {}
            local effect =
            {
                getPower = function()
                    return 39
                end,
                getTier = function()
                    return xi.aftermath.type.MYTHIC
                end,
                getSubPower = function()
                    return tp
                end,
                addMod = function(_, modId, value)
                    added[modId] = value
                end,
            }
            local target =
            {
                getPet = function()
                    return nil
                end,
            }

            xi.aftermath.onEffectGain(target, effect)
            return added
        end

        local am1 = getMods(1000)
        assert(am1[xi.mod.ACC] ~= nil)
        assert(am1[xi.mod.ATT] == nil)
        assert(am1[xi.mod.MYTHIC_OCC_ATT_TWICE] == nil)

        local am2 = getMods(2000)
        assert(am2[xi.mod.ACC] == nil)
        assert(am2[xi.mod.ATT] ~= nil)
        assert(am2[xi.mod.MYTHIC_OCC_ATT_TWICE] == nil)

        local am3 = getMods(3000)
        assert(am3[xi.mod.ACC] == nil)
        assert(am3[xi.mod.ATT] == nil)
        assert(am3[xi.mod.MYTHIC_OCC_ATT_TWICE] == 40)
        assert(am3[xi.mod.MYTHIC_OCC_ATT_THRICE] == 20)
    end)

    it('applies retail tier-three ranged Mythic rates', function()
        local mythicMods = {}
        local mythicEffect =
        {
            getPower = function()
                return 43
            end,
            getTier = function()
                return xi.aftermath.type.MYTHIC
            end,
            getSubPower = function()
                return 3000
            end,
            addMod = function(_, modId, value)
                mythicMods[modId] = value
            end,
        }
        local target =
        {
            getPet = function()
                return nil
            end,
        }

        xi.aftermath.onEffectGain(target, mythicEffect)

        assert(mythicMods[xi.mod.RACC] == nil)
        assert(mythicMods[xi.mod.RATT] == nil)
        assert(mythicMods[xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED] == 400)
        assert(mythicMods[xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED] == 200)
    end)

    it('applies Aeonic skillchain and magic burst potency instead of damage procs', function()
        local aeonicMods = {}
        local target = {}
        local aeonicEffect =
        {
            getPower = function()
                return 49
            end,
            getTier = function()
                return xi.aftermath.type.AEONIC
            end,
            getSubPower = function()
                return 2800
            end,
            addMod = function(_, modId, value)
                aeonicMods[modId] = value
            end,
        }

        xi.aftermath.onEffectGain(target, aeonicEffect)

        assert(aeonicMods[xi.mod.SKILLCHAINBONUS] == 9)
        assert(aeonicMods[xi.mod.MAGIC_BURST_BONUS_CAPPED] == 9)
        assert(aeonicMods[xi.mod.REM_OCC_DO_DOUBLE_DMG] == nil)
        assert(aeonicMods[xi.mod.REM_OCC_DO_TRIPLE_DMG] == nil)
    end)

    it('uses retail tier overwrite rules and protects level three', function()
        local function existingEffect(tp, aftermathType)
            return {
                getTier = function()
                    return aftermathType
                end,
                getSubPower = function()
                    return tp
                end,
            }
        end

        local player = makePlayer(39, xi.slot.MAIN,
            { existingEffect = existingEffect(3000, xi.aftermath.type.MYTHIC) })

        assert(not xi.aftermath.canOverwrite(
            player, 1000, 39, xi.aftermath.type.MYTHIC))
        assert(not xi.aftermath.canOverwrite(
            player, 2000, 39, xi.aftermath.type.MYTHIC))
        assert(not xi.aftermath.canOverwrite(
            player, 3000, 39, xi.aftermath.type.MYTHIC))

        player = makePlayer(39, xi.slot.MAIN,
            { existingEffect = existingEffect(1000, xi.aftermath.type.MYTHIC) })
        assert(xi.aftermath.canOverwrite(
            player, 1000, 39, xi.aftermath.type.MYTHIC))
        assert(xi.aftermath.canOverwrite(
            player, 2000, 39, xi.aftermath.type.MYTHIC))

        player = makePlayer(49, xi.slot.MAIN,
            { existingEffect = existingEffect(3000, xi.aftermath.type.AEONIC) })
        assert(not xi.aftermath.canOverwrite(
            player, 1000, 49, xi.aftermath.type.AEONIC))
        assert(not xi.aftermath.canOverwrite(
            player, 3000, 49, xi.aftermath.type.AEONIC))
    end)

    it('always refreshes Relic aftermath as on retail', function()
        local player = makePlayer(15, xi.slot.MAIN,
            {
                existingEffect =
                {
                    getTier = function()
                        return xi.aftermath.type.RELIC
                    end,
                },
            })

        assert(xi.aftermath.canOverwrite(
            player, 1000, 15, xi.aftermath.type.RELIC))
    end)

    it('activates Aeonic aftermath only from the linked WS', function()
        local player, getApplied = makePlayer(49, xi.slot.MAIN,
            { itemId = 20515 })

        xi.aftermath.addAeonicStatusEffect(
            player, 3000, xi.slot.MAIN, xi.weaponskill.UPHEAVAL)
        assert(getApplied() == nil)

        xi.aftermath.addAeonicStatusEffect(
            player, 3000, xi.slot.MAIN, xi.weaponskill.SHIJIN_SPIRAL)
        assert(getApplied().params.duration == 180)
        assert(getApplied().params.icon == xi.effect.AFTERMATH_LV3)
    end)

    it('applies one retail ranged Mythic damage distribution', function()
        local oldRandom = math.random
        local effect =
        {
            getTier = function()
                return xi.aftermath.type.MYTHIC
            end,
        }
        local player =
        {
            getStatusEffect = function()
                return effect
            end,
            getMod = function(_, modId)
                if modId == xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED then
                    return 200
                elseif modId == xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED then
                    return 400
                end

                return 0
            end,
        }

        math.random = function()
            return 20
        end
        assert(xi.aftermath.applyRangedMythicDamageProc(player, 100) == 300)

        math.random = function()
            return 60
        end
        assert(xi.aftermath.applyRangedMythicDamageProc(player, 100) == 200)

        math.random = function()
            return 61
        end
        assert(xi.aftermath.applyRangedMythicDamageProc(player, 100) == 100)
        math.random = oldRandom
    end)
end)
