local catalog = require('modules/custom/lua/prestige_catalog')

local function rosterAttackRange(roster)
    local low, high
    for _, boss in pairs(roster.bosses) do
        local attack = boss.mods[xi.mod.ATT]
        low  = low and math.min(low, attack) or attack
        high = high and math.max(high, attack) or attack
    end

    return low, high
end

describe('Ascension Court progression curve', function()
    it('keeps the entry Court accessible for the base prestige gates', function()
        for _, boss in pairs(catalog.trialBosses) do
            assert(boss.hpBoost <= 34)
            assert(boss.mods[xi.mod.ATT] <= 5500)
            assert(boss.mods[xi.mod.REGEN] <= 160)
        end

        local mechanics = catalog.trialScaling.tierMechanics[0]
        assert(mechanics.enrage.sec == 360)
        assert(mechanics.cc.dur == 3)
    end)

    it('raises roster attack steadily without a P10 cliff', function()
        local expectedMinLevels = { 0, 10, 20, 30, 40, 60, 80, 90 }
        for index, minLevel in ipairs(expectedMinLevels) do
            assert(catalog.trialScaling.tiers[index].minLevel == minLevel)
        end

        local previousHigh = 5500
        for index = 2, 6 do
            local low, high = rosterAttackRange(catalog.trialScaling.tiers[index].roster)
            assert(low > previousHigh)
            assert(high <= previousHigh * 1.55)
            previousHigh = high
        end
    end)

    it('reserves final empowerment for the P80-P100 Aeonic climb', function()
        local empowered = catalog.trialScaling.tiers[7]
        local ascendant = catalog.trialScaling.tiers[8]

        assert(empowered.minLevel == 80)
        assert(empowered.mult == 1.12)
        assert(empowered.roster == nil)
        assert(ascendant.minLevel == 90)
        assert(ascendant.mult == 1.25)
        assert(ascendant.roster == nil)

        local wardens = catalog.trialScaling.tiers[6].roster
        local _, high = rosterAttackRange(wardens)
        assert(high * ascendant.mult == 31250)
    end)
end)
