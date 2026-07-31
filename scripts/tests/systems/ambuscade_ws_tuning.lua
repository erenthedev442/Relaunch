local weapons = require('modules/custom/lua/ambuscade_weapons_catalog')
local tuning  = require('modules/custom/lua/ambuscade_ws_tuning_catalog')
require('modules/custom/lua/AmbuscadeWeaponskillTuning')

describe('Final Ambuscade weaponskill tuning', function()
    local target = {
        getStatusEffect = function()
            return nil
        end,
    }

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
        assert(tuning.LINKED_DAMAGE_CAP == 149999)
        assert(tuning.AOE_DAMAGE_CAP == 99999)
        assert(tuning.LINKED_AOE_DAMAGE_CAP == 149999)
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
            assert(tuning.isFinalWeapon(entry.itemId, entry.slot))
        end

        for itemId, mapped in pairs(finalIds) do
            assert(mapped, string.format('Final Ambuscade weapon %d has no tuning entry', itemId))
        end

        assert(tuning.getEntry(22218, xi.weaponskill.BLACK_HALO, xi.slot.MAIN) == nil)
        assert(not tuning.isFinalWeapon(22218, xi.slot.MAIN))
    end)

    it('applies the 99,999 soft ceiling to every WS on a final Ambuscade weapon', function()
        local player = makePlayer({ [xi.slot.MAIN] = 21621 })

        xi.ambuscadeWsTuning.withAmbuscadeEffects(
            player, target, xi.weaponskill.BLACK_HALO, xi.slot.MAIN,
            function()
                assert(player:getLocalVar(tuning.BASE_DAMAGE_CAP_LOCAL_VAR) == 99999)
                assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 99999)
                assert(player:getLocalVar('StandardWsDamageCap') == 99999)
                assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 0)
            end)

        assert(player:getLocalVar(tuning.BASE_DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getLocalVar('StandardWsDamageCap') == 0)
    end)

    it('scopes the linked 10% boost and 149,999 hard cap to the exact weapon and WS', function()
        local player = makePlayer({ [xi.slot.MAIN] = 21621 })
        local called = false

        xi.ambuscadeWsTuning.withAmbuscadeEffects(
            player, target, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            function()
                called = true
                assert(player:getLocalVar(tuning.BASE_DAMAGE_CAP_LOCAL_VAR) == 99999)
                assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 149999)
                assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 110)
                assert(player:getLocalVar('StandardWsDamageCap') == 149999)
            end)

        assert(called)
        assert(player:getLocalVar(tuning.BASE_DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 0)
        assert(player:getLocalVar('StandardWsDamageCap') == 0)
    end)

    it('raises and restores the AoE cap for a linked final Ambuscade WS', function()
        local player = makePlayer({ [xi.slot.MAIN] = 21779 })
        player:setLocalVar('AoEWsDamageCap', 79999)

        xi.ambuscadeWsTuning.withAmbuscadeEffects(
            player, target, xi.weaponskill.STEEL_CYCLONE, xi.slot.MAIN,
            function()
                assert(player:getLocalVar('AoEWsDamageCap') == 149999)
            end)

        assert(player:getLocalVar('AoEWsDamageCap') == 79999)
    end)

    it('restores prior tuning state when the WS calculation errors', function()
        local player = makePlayer({ [xi.slot.RANGED] = 22107 })
        player:setLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR, 123)
        player:setLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR, 104)
        player:setLocalVar(tuning.BASE_DAMAGE_CAP_LOCAL_VAR, 77)
        player:setLocalVar('StandardWsDamageCap', 55)

        local ok = pcall(function()
            xi.ambuscadeWsTuning.withAmbuscadeEffects(
                player, target, xi.weaponskill.EMPYREAL_ARROW, xi.slot.RANGED,
                function()
                    error('expected test failure')
                end)
        end)

        assert(not ok)
        assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 123)
        assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 104)
        assert(player:getLocalVar(tuning.BASE_DAMAGE_CAP_LOCAL_VAR) == 77)
        assert(player:getLocalVar('StandardWsDamageCap') == 55)
    end)

    it('applies Dolichenus WS damage from prior skillchain links', function()
        local player = makePlayer({ [xi.slot.MAIN] = tuning.ITEM.DOLICHENUS })
        local chainedTarget = {
            getStatusEffect = function(_, effectId)
                if effectId == xi.effect.SKILLCHAIN then
                    return { getSubPower = function() return 2 end }
                end
            end,
        }

        -- Non-linked WS: Dolichenus mult only, still soft/hard capped at 99,999.
        xi.ambuscadeWsTuning.withAmbuscadeEffects(
            player, chainedTarget, xi.weaponskill.RAGING_AXE, xi.slot.MAIN,
            function()
                assert(player:getLocalVar(tuning.BASE_DAMAGE_CAP_LOCAL_VAR) == 99999)
                assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 99999)
                assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 106)
            end)

        assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 0)

        -- Linked Decimation: 110% * Dolichenus skillchain bonus, hard-capped 149,999.
        xi.ambuscadeWsTuning.withAmbuscadeEffects(
            player, chainedTarget, xi.weaponskill.DECIMATION, xi.slot.MAIN,
            function()
                assert(player:getLocalVar(tuning.DAMAGE_MULT_LOCAL_VAR) == 116)
                assert(player:getLocalVar(tuning.DAMAGE_CAP_LOCAL_VAR) == 149999)
            end)
    end)
end)
