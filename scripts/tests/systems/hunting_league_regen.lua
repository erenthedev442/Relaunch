local catalog   = require('modules/custom/lua/hunting_league_catalog')
local mechanics = require('modules/custom/lua/mob_mechanics_library')

describe('Hunting League damage-ceiling regen balance', function()
    it('uses reduced flat regen by rank', function()
        local expectedByTier = { 12, 24, 40, 70, 120 }

        for _, tier in ipairs(catalog.tiers) do
            for _, mob in ipairs(tier.mobs) do
                local expected = mob.groupId == 11369 and 175 or expectedByTier[tier.tier]
                assert(mob.mods[xi.mod.REGEN] == expected)
            end
        end
    end)

    it('limits every hunt drain pulse to one quarter percent', function()
        for groupId = 11355, 11369 do
            local drain = catalog.mechCfgs[groupId].drain
            assert(drain.healPct == 0.25)
        end
    end)

    it('keeps Shinryu healing below 10k per second at 19.2M HP', function()
        local shinryu = catalog.mechCfgs[11369].drain
        local drainPerSecond = mechanics.calculateDrainHeal(19200000, shinryu) / shinryu.periodSec
        local regenPerSecond = 175 / 3

        assert(drainPerSecond == 8000)
        assert(drainPerSecond + regenPerSecond < 10000)
    end)

    it('honors fixed drain healing before percentage healing', function()
        assert(mechanics.calculateDrainHeal(19918515, { heal = 10000, healPct = 50 }) == 10000)
        assert(mechanics.calculateDrainHeal(19200000, { healPct = 0.25 }) == 48000)
    end)
end)
