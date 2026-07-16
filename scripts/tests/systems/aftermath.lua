require('scripts/globals/aftermath')

describe('REMA and Prime aftermath handling', function()
    local function makePlayer(aftermathId, slot)
        local applied
        local weapon =
        {
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

            getStatusEffect = function()
                return nil
            end,

            delStatusEffect = function()
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

        assert(added[xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED] == 50)
        assert(added[xi.mod.REM_OCC_DO_TRIPLE_DMG] == nil)
    end)

    it('applies full tier-three ranged Mythic and Aeonic proc packages', function()
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

        assert(mythicMods[xi.mod.RACC] ~= nil)
        assert(mythicMods[xi.mod.RATT] ~= nil)
        assert(mythicMods[xi.mod.REM_OCC_DO_DOUBLE_DMG_RANGED] == 40)
        assert(mythicMods[xi.mod.REM_OCC_DO_TRIPLE_DMG_RANGED] == 20)

        local aeonicMods = {}
        local aeonicEffect =
        {
            getPower = function()
                return 49
            end,
            getTier = function()
                return xi.aftermath.type.AEONIC
            end,
            addMod = function(_, modId, value)
                aeonicMods[modId] = value
            end,
        }

        xi.aftermath.onEffectGain(target, aeonicEffect)

        assert(aeonicMods[xi.mod.REM_OCC_DO_DOUBLE_DMG] == 500)
        assert(aeonicMods[xi.mod.REM_OCC_DO_TRIPLE_DMG] == 250)
    end)
end)
