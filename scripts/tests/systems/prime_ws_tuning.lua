local catalog = require('modules/custom/lua/prime_ws_tuning_catalog')
require('modules/custom/lua/PrimeWeaponskillTuning')

describe('Relaunch Prime weaponskill beta tuning', function()
    local function makePlayer(equipment)
        return
        {
            equipment = equipment or {},
            isPC = function()
                return true
            end,
            getEquipID = function(self, slot)
                return self.equipment[slot] or 0
            end,
        }
    end

    it('has an independent positive tuning value for every supported Prime WS', function()
        local count = 0
        for _, tuning in pairs(catalog.PRIME_WS_TUNING) do
            count = count + 1
            assert(tuning.itemId > 0)
            assert(tuning.ftpScale > 0)
            assert(tuning.slot == xi.slot.MAIN or tuning.slot == xi.slot.RANGED)
        end

        assert(count == 13)
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
        assert(math.abs(tuned.ftpMod[1] - 29.7) < 0.0001)
        assert(math.abs(tuned.ftpMod[2] - 60.075) < 0.0001)
        assert(math.abs(tuned.ftpMod[3] - 90.45) < 0.0001)
        assert(native.ftpMod[3] == 20.1)
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
            player, xi.weaponskill.SARV, xi.slot.RANGED, native).ftpMod[3] - 51.15) < 0.0001)
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
