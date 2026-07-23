local weapons = require('modules/custom/lua/ambuscade_weapons_catalog')
local tuning  = require('modules/custom/lua/ambuscade_ws_tuning_catalog')
require('modules/custom/lua/AmbuscadeWeaponskillTuning')

describe('Final Ambuscade weaponskill tuning', function()
    local function makePlayer(equipment)
        local localVars = {}
        local player    = { equipment = equipment or {} }

        player.isPC = function()
            return true
        end

        player.getEquipID = function(self, slot)
            return self.equipment[slot] or 0
        end

        player.getLocalVar = function(_, name)
            return localVars[name] or 0
        end

        player.setLocalVar = function(_, name, value)
            localVars[name] = value
        end

        return player
    end

    it('maps every final damage weapon and excludes the grip', function()
        assert(#tuning.entries == 13)
        assert(tuning.DAMAGE_CAP == 99999)
        assert(tuning.DAMAGE_MULTIPLIER == 110)

        local finalIds = {}
        for index, chain in ipairs(weapons.CHAINS) do
            if index < #weapons.CHAINS then
                finalIds[chain.stages[5]] = false
            end
        end

        for _, entry in ipairs(tuning.entries) do
            assert(finalIds[entry.itemId] ~= nil, string.format(
                '%s is not a final Ambuscade weapon', entry.name))
            finalIds[entry.itemId] = true
            assert(tuning.getEntry(entry.itemId, entry.wsId, entry.slot) == entry)
            assert(tuning.getEntry(entry.itemId, entry.wsId + 1, entry.slot) == nil)
        end

        for itemId, mapped in pairs(finalIds) do
            assert(mapped, string.format('Final Ambuscade weapon %d has no tuning entry', itemId))
        end

        assert(tuning.getEntry(22218, xi.weaponskill.BLACK_HALO, xi.slot.MAIN) == nil)
    end)

    it('scopes the final damage multiplier and cap to the exact weapon and WS', function()
        local player = makePlayer({ [xi.slot.MAIN] = 21621 })
        local called = false

        xi.ambuscadeWsTuning.withAmbuscadeEffects(
            player, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            function()
                called = true
                assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 99999)
                assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 110)
            end)

        assert(called)
        assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 0)

        xi.ambuscadeWsTuning.withAmbuscadeEffects(
            player, xi.weaponskill.BLACK_HALO, xi.slot.MAIN,
            function()
                assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 0)
                assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 0)
            end)
    end)

    it('restores prior tuning state when the WS calculation errors', function()
        local player = makePlayer({ [xi.slot.RANGED] = 22107 })
        player:setLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR, 123)
        player:setLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR, 104)

        local ok = pcall(function()
            xi.ambuscadeWsTuning.withAmbuscadeEffects(
                player, xi.weaponskill.EMPYREAL_ARROW, xi.slot.RANGED,
                function()
                    error('expected test failure')
                end)
        end)

        assert(not ok)
        assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 123)
        assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 104)
    end)
end)
