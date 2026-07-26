local catalog = require('modules/custom/lua/standard_ws_tuning_catalog')
require('modules/custom/lua/StandardWeaponskillTuning')

describe('Level-scaled ordinary weaponskill tuning', function()
    local function makePlayer(equipment, level)
        local mods      = {}
        local localVars = {}
        local player    = { equipment = equipment or {} }

        player.isPC = function()
            return true
        end

        player.getEquipID = function(self, slot)
            return self.equipment[slot] or 0
        end

        player.getMainLvl = function()
            return level or 99
        end

        player.getMod = function(_, modId)
            return mods[modId] or 0
        end

        player.addMod = function(_, modId, amount)
            mods[modId] = (mods[modId] or 0) + amount
        end

        player.setMod = function(_, modId, amount)
            mods[modId] = amount
        end

        player.getLocalVar = function(_, name)
            return localVars[name] or 0
        end

        player.setLocalVar = function(_, name, value)
            localVars[name] = value
        end

        return player
    end

    local function makeTarget(level, maxHp)
        return
        {
            isMob = function()
                return true
            end,
            getMainLvl = function()
                return level
            end,
            getMaxHP = function()
                return maxHp
            end,
        }
    end

    it('scales its additive share with target HP and level gap', function()
        assert(catalog.getDamageBonus(99, 155, 120000) == 36000)
        assert(catalog.getDamageBonus(1, 1, 100) == 30)
        assert(catalog.getDamageBonus(50, 58, 10000) == 2100)
        assert(catalog.getDamageBonus(50, 75, 120000) == 1080)
    end)

    it('adds a progressive accuracy penalty only beyond the grace band', function()
        assert(catalog.getAccuracyPenalty(50, 53) == 0)
        assert(catalog.getAccuracyPenalty(50, 58) == 40)
        assert(catalog.getAccuracyPenalty(50, 75) == 176)
        assert(catalog.getAccuracyPenalty(99, 155) == 0)
    end)

    it('exposes ordinary WS bonus, cap, and underlevel accuracy synchronously', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20819 }, 50)
        local target = makeTarget(58, 10000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.RAGING_RUSH, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_BONUS_LOCAL_VAR) == 2100)
                assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 99999)
                assert(player:getMod(xi.mod.WSACC) == -40)
            end)

        assert(player:getLocalVar(catalog.DAMAGE_BONUS_LOCAL_VAR) == 0)
        assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getMod(xi.mod.WSACC) == 0)
    end)

    it('excludes exact REMA, Prime, and final Ambuscade native WS pairs', function()
        local target = makeTarget(150, 1000000)
        local cases =
        {
            { item = 20509, ws = xi.weaponskill.FINAL_HEAVEN },
            { item = 21646, ws = xi.weaponskill.IMPERATOR },
            { item = 21621, ws = xi.weaponskill.SAVAGE_BLADE },
        }

        for _, case in ipairs(cases) do
            local player = makePlayer({ [xi.slot.MAIN] = case.item }, 99)
            xi.standardWsTuning.withStandardEffects(
                player, target, case.ws, xi.slot.MAIN, {}, false,
                function()
                    assert(player:getLocalVar(catalog.DAMAGE_BONUS_LOCAL_VAR) == 0)
                    assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
                end)
        end
    end)

    it('still tunes ordinary WSs used with a special weapon', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 }, 99)
        local target = makeTarget(155, 120000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.RAGING_FISTS, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_BONUS_LOCAL_VAR) == 36000)
            end)
    end)

    it('restores local variables and accuracy after a calculation error', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20819 }, 50)
        local target = makeTarget(58, 10000)
        player:setLocalVar(catalog.DAMAGE_BONUS_LOCAL_VAR, 17)
        player:setLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR, 23)
        player:setMod(xi.mod.WSACC, 11)

        local ok = pcall(function()
            xi.standardWsTuning.withStandardEffects(
                player, target, xi.weaponskill.RAGING_RUSH, xi.slot.MAIN,
                {}, false,
                function()
                    error('expected test failure')
                end)
        end)

        assert(not ok)
        assert(player:getLocalVar(catalog.DAMAGE_BONUS_LOCAL_VAR) == 17)
        assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 23)
        assert(player:getMod(xi.mod.WSACC) == 11)
    end)
end)
