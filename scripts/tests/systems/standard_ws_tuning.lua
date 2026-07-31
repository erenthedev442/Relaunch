local catalog = require('modules/custom/lua/standard_ws_tuning_catalog')
require('modules/custom/lua/StandardWeaponskillTuning')

describe('Level-scaled ordinary weaponskill tuning', function()
    local function makePlayer(equipment, level, spentJobPoints)
        local mods      = {}
        local localVars = {}
        local player    = { equipment = equipment or {} }

        player.isPC = function()
            return true
        end

        player.getEquipID = function(self, slot)
            local equipped = self.equipment[slot]
            return type(equipped) == 'table' and equipped.id or equipped or 0
        end

        player.getEquippedItem = function(self, slot)
            local equipped = self.equipment[slot]
            if not equipped then
                return nil
            end

            local details = type(equipped) == 'table' and equipped or
                { id = equipped, ilvl = 119, reqLvl = 99 }
            return
            {
                getILvl = function()
                    return details.ilvl or 0
                end,
                getReqLvl = function()
                    return details.reqLvl or 0
                end,
            }
        end

        player.getMainLvl = function()
            return level or 99
        end

        player.getSpentJobPoints = function()
            return spentJobPoints or 0
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

    it('uses mastery-scaled multipliers at level 99', function()
        local target = makeTarget(155, 120000)
        local weapon = { [xi.slot.MAIN] = { id = 1, ilvl = 119, reqLvl = 99 } }
        assert(catalog.DAMAGE_CAP == 79999)
        assert(catalog.getWeaponskillMultiplier(makePlayer(weapon, 99, 0), target) == 8)
        assert(catalog.getWeaponskillMultiplier(makePlayer(weapon, 99, 1050), target) == 10.5)
        assert(catalog.getWeaponskillMultiplier(makePlayer(weapon, 99, 2100), target) == 13)
        assert(catalog.getPetDamageMultiplier(makePlayer({}, 99, 0), target) == 7)
        assert(catalog.getPetDamageMultiplier(makePlayer({}, 99, 2100), target) == 11)
        assert(catalog.applyMultiplier(1500, 11, 79999) == 16500)
        assert(catalog.applyMultiplier(8000, 11, 79999) == 79999)
        assert(catalog.applyMultiplier(1500, 13, 79999) == 19500)
        assert(catalog.applyMultiplier(6150, 13, 79999) == 79950)
        assert(catalog.applyMultiplier(10000, 13, 79999) == 79999)
    end)

    it('keeps the full level-99 multiplier on low-HP farming targets', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = { id = 1, ilvl = 119, reqLvl = 99 } }, 99, 2100)

        assert(catalog.getWeaponskillMultiplier(
            player, makeTarget(76, 8000), xi.slot.MAIN) == 13)
    end)

    it('scales custom bonuses by weapon level and caps non-item-level weapons', function()
        local onionSword = makePlayer(
            { [xi.slot.MAIN] = { id = 2, ilvl = 0, reqLvl = 1 } }, 99, 0)
        local level99Sword = makePlayer(
            { [xi.slot.MAIN] = { id = 3, ilvl = 0, reqLvl = 99 } }, 99, 0)
        local itemLevel119Sword = makePlayer(
            { [xi.slot.MAIN] = { id = 4, ilvl = 119, reqLvl = 99 } }, 99, 0)
        local target = makeTarget(155, 120000)

        assert(math.abs(catalog.getWeaponskillMultiplier(
            onionSword, target, xi.slot.MAIN) - 1.070707) < 0.000001)
        assert(catalog.getWeaponskillMultiplier(
            level99Sword, target, xi.slot.MAIN) == 8)
        assert(catalog.getWeaponskillCap(onionSword, xi.slot.MAIN) == 40000)
        assert(catalog.getWeaponskillCap(level99Sword, xi.slot.MAIN) == 40000)
        assert(catalog.getWeaponskillCap(itemLevel119Sword, xi.slot.MAIN) == 79999)
    end)

    it('adds a progressive accuracy penalty only beyond the grace band', function()
        assert(catalog.getAccuracyPenalty(50, 53) == 0)
        assert(catalog.getAccuracyPenalty(50, 58) == 40)
        assert(catalog.getAccuracyPenalty(50, 75) == 176)
        assert(catalog.getAccuracyPenalty(99, 155) == 0)
    end)

    it('exposes ordinary WS multiplier, cap, and underlevel accuracy synchronously', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = { id = 20819, ilvl = 0, reqLvl = 50 } }, 50)
        local target = makeTarget(58, 10000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.RAGING_RUSH, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 2250)
                assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 40000)
                assert(player:getMod(xi.mod.WSACC) == -40)
            end)

        assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 0)
        assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getMod(xi.mod.WSACC) == 0)
    end)

    it('raises ordinary AoE caps for final main-hand Ambuscade, REMA, and Prime weapons', function()
        local target = makeTarget(150, 1000000)
        local cases =
        {
            { item = 21621, cap =  99999 }, -- Naegling
            { item = 20695, cap = 149999 }, -- Sequence
            { item = 21646, cap = 199999 }, -- Caliburnus
        }

        for _, case in ipairs(cases) do
            local player = makePlayer({ [xi.slot.MAIN] = case.item }, 99)
            player:setLocalVar('AoEWsDamageCap', 79999)

            xi.standardWsTuning.withStandardEffects(
                player, target, xi.weaponskill.CIRCLE_BLADE, xi.slot.MAIN,
                {}, false,
                function()
                    assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == case.cap)
                    assert(player:getLocalVar('AoEWsDamageCap') == case.cap)
                end)

            assert(player:getLocalVar('AoEWsDamageCap') == 79999)
        end
    end)

    it('excludes exact REMA and Prime native WS pairs', function()
        local target = makeTarget(150, 1000000)
        local cases =
        {
            { item = 20509, ws = xi.weaponskill.FINAL_HEAVEN },
            { item = 21646, ws = xi.weaponskill.IMPERATOR },
        }

        for _, case in ipairs(cases) do
            local player = makePlayer({ [xi.slot.MAIN] = case.item }, 99)
            xi.standardWsTuning.withStandardEffects(
                player, target, case.ws, xi.slot.MAIN, {}, false,
                function()
                    assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 0)
                    assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
                end)
        end
    end)

    it('keeps standard progression on final Ambuscade linked WSs with a 99,999 ceiling', function()
        local player = makePlayer({ [xi.slot.MAIN] = 21621 }, 99)
        local target = makeTarget(150, 1000000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
                assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 99999)
            end)
    end)

    it('still tunes ordinary WSs used with a special weapon', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 }, 99)
        local target = makeTarget(155, 120000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.RAGING_FISTS, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
            end)
    end)

    it('restores local variables and accuracy after a calculation error', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20819 }, 50)
        local target = makeTarget(58, 10000)
        player:setLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR, 17)
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
        assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 17)
        assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 23)
        assert(player:getMod(xi.mod.WSACC) == 11)
    end)
end)
