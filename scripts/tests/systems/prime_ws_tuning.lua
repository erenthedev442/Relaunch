local catalog = require('modules/custom/lua/prime_ws_tuning_catalog')
require('modules/custom/lua/PrimeWeaponskillTuning')

describe('Relaunch Prime weaponskill pinnacle tuning', function()
    local function makePlayer(equipment, mainJob)
        local mods      = {}
        local localVars = {}
        local player    = { equipment = equipment or {} }

        player.isPC = function()
            return true
        end

        player.getEquipID = function(self, slot)
            return self.equipment[slot] or 0
        end

        player.getMainJob = function()
            return mainJob or xi.job.WAR
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

    it('has complete pinnacle tuning for every damage-dealing Prime WS', function()
        assert(catalog.WS_DAMAGE_BONUS == 300)

        local count = 0
        for _, tuning in pairs(catalog.PRIME_WS_TUNING) do
            count = count + 1
            assert(tuning.itemId > 0)
            assert(tuning.ftpScale > 0)
            assert(tuning.wsDamageBonus > catalog.WS_DAMAGE_BONUS)
            assert(#tuning.ignoredDefense == 3)
            assert(tuning.ignoredDefense[1] >= 0 and tuning.ignoredDefense[1] <= 1)
            assert(tuning.ignoredDefense[2] >= tuning.ignoredDefense[1])
            assert(tuning.ignoredDefense[3] >= tuning.ignoredDefense[2] and
                tuning.ignoredDefense[3] <= 1)
            assert(tuning.slot == xi.slot.MAIN or tuning.slot == xi.slot.RANGED)
        end

        assert(count == 14)
    end)

    it('requires the exact approved final weapon, native WS and slot', function()
        assert(catalog.getEntry(
            21646, xi.weaponskill.IMPERATOR, xi.slot.MAIN) ~= nil)
        assert(catalog.getEntry(
            21642, xi.weaponskill.IMPERATOR, xi.slot.MAIN) == nil)
        assert(catalog.getEntry(
            21646, xi.weaponskill.KNIGHTS_OF_ROUND, xi.slot.MAIN) == nil)
        assert(catalog.getEntry(
            22163, xi.weaponskill.SARV, xi.slot.MAIN) == nil)
        assert(catalog.getEntry(
            21730, xi.weaponskill.BLITZ, xi.slot.MAIN) ~= nil)
        assert(catalog.getEntry(
            21730, xi.weaponskill.DECIMATION, xi.slot.MAIN) == nil)
        assert(catalog.getEntry(
            21932, xi.weaponskill.ZESHO_MEPPO, xi.slot.MAIN) ~= nil)
    end)

    it('scales a private fTP copy and preserves all other WS mechanics', function()
        local native =
        {
            numHits     = 1,
            ftpMod      = { 6.6, 13.35, 20.1 },
            dex_wsc     = 0.27,
            mnd_wsc     = 0.27,
            critVaries  = { 0.1, 0.2, 0.3 },
            multiHitfTP = false,
        }
        local tuned = xi.primeWsTuning.getTunedParams(
            makePlayer({ [xi.slot.MAIN] = 21646 }),
            xi.weaponskill.IMPERATOR,
            xi.slot.MAIN,
            native)

        assert(tuned ~= native and tuned.ftpMod ~= native.ftpMod)
        assert(tuned.numHits == native.numHits)
        assert(tuned.dex_wsc == native.dex_wsc and tuned.mnd_wsc == native.mnd_wsc)
        assert(tuned.critVaries == native.critVaries)
        assert(tuned.multiHitfTP == native.multiHitfTP)
        assert(math.abs(tuned.ftpMod[1] - 44.55) < 0.0001)
        assert(math.abs(tuned.ftpMod[2] - 90.1125) < 0.0001)
        assert(math.abs(tuned.ftpMod[3] - 135.675) < 0.0001)
        assert(tuned.ignoredDefense[1] == 0.60)
        assert(tuned.ignoredDefense[2] == 0.85)
        assert(tuned.ignoredDefense[3] == 1.00)
        assert(tuned.ignoredDefense ~= catalog.PRIME_WS_TUNING[xi.weaponskill.IMPERATOR].ignoredDefense)
        assert(native.ftpMod[3] == 20.1)
        assert(native.ignoredDefense == nil)
    end)

    it('does not tune intermediate, ordinary or mismatched weaponskills', function()
        local native = { ftpMod = { 6.6, 13.35, 20.1 } }

        assert(xi.primeWsTuning.getTunedParams(
            makePlayer({ [xi.slot.MAIN] = 21642 }),
            xi.weaponskill.IMPERATOR,
            xi.slot.MAIN,
            native) == native)
        assert(xi.primeWsTuning.getTunedParams(
            makePlayer({ [xi.slot.MAIN] = 21646 }),
            xi.weaponskill.KNIGHTS_OF_ROUND,
            xi.slot.MAIN,
            native) == native)
    end)

    it('keeps ranged tuning restricted to the ranged slot', function()
        local native = { ftpMod = { 2.75, 5.5, 8.25 } }
        local player = makePlayer(
            {
                [xi.slot.MAIN]   = 22163,
                [xi.slot.RANGED] = 22163,
            })

        assert(xi.primeWsTuning.getTunedParams(
            player, xi.weaponskill.SARV, xi.slot.MAIN, native) == native)
        assert(math.abs(xi.primeWsTuning.getTunedParams(
            player, xi.weaponskill.SARV, xi.slot.RANGED, native).ftpMod[3] - 70.125) < 0.0001)
    end)

    it('assigns the approved support, hybrid, and damage job caps', function()
        assert(catalog.getDamageCap(xi.job.PLD) == 1499999)
        assert(catalog.getDamageCap(xi.job.WHM) == 1499999)

        assert(catalog.getDamageCap(xi.job.BRD) == 1749999)
        assert(catalog.getDamageCap(xi.job.RDM) == 1749999)
        assert(catalog.getDamageCap(xi.job.DNC) == 1749999)
        assert(catalog.getDamageCap(xi.job.BLU) == 1749999)
        assert(catalog.getDamageCap(xi.job.COR) == 1749999)

        assert(catalog.getDamageCap(xi.job.WAR) == 1999999)
        assert(catalog.getDamageCap(xi.job.RNG) == 1999999)
        assert(catalog.getDamageCap(xi.job.SAM) == 1999999)
        assert(catalog.getDamageCap(xi.job.DRG) == 1999999)
        assert(catalog.getDamageCap(xi.job.DRK) == 1999999)
    end)

    it('applies the pinnacle damage layer and over-cap window only during an exact Prime WS', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = 21646 },
            xi.job.RDM)
        local modId  = xi.mod.WEAPONSKILL_DAMAGE_BASE + xi.weaponskill.IMPERATOR
        local capVar = catalog.DAMAGE_CAP_LOCAL_VAR

        local result = xi.primeWsTuning.withPrimeEffects(
            player, xi.weaponskill.IMPERATOR, xi.slot.MAIN,
            function()
                assert(player:getMod(modId) ==
                    catalog.PRIME_WS_TUNING[xi.weaponskill.IMPERATOR].wsDamageBonus)
                assert(player:getLocalVar(capVar) == 1749999)
                return 'prime'
            end)

        assert(result == 'prime')
        assert(player:getMod(modId) == 0)
        assert(player:getLocalVar(capVar) == 0)
    end)

    it('does not grant Prime damage or cap privileges to a mismatched WS', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = 21646 },
            xi.job.RDM)
        local called = false

        xi.primeWsTuning.withPrimeEffects(
            player, xi.weaponskill.CHANT_DU_CYGNE, xi.slot.MAIN,
            function()
                called = true
                assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
            end)

        assert(called)
    end)

    it('restores Prime damage and cap state when WS calculation errors', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = 21653 },
            xi.job.WAR)
        local modId  = xi.mod.WEAPONSKILL_DAMAGE_BASE + xi.weaponskill.RESOLUTION
        local capVar = catalog.DAMAGE_CAP_LOCAL_VAR

        player:setMod(modId, 17)
        player:setLocalVar(capVar, 23)

        local ok = pcall(function()
            xi.primeWsTuning.withPrimeEffects(
                player, xi.weaponskill.RESOLUTION, xi.slot.MAIN,
                function()
                    error('expected test failure')
                end)
        end)

        assert(not ok)
        assert(player:getMod(modId) == 17)
        assert(player:getLocalVar(capVar) == 23)
    end)

    it('does not register wrappers again when reloaded', function()
        local modulePath = 'modules/custom/lua/PrimeWeaponskillTuning'
        local original   = package.loaded[modulePath]

        package.loaded[modulePath] = nil
        local reloadGuard = require(modulePath)
        assert(#reloadGuard.overrides == 0)

        package.loaded[modulePath] = original
    end)
end)
