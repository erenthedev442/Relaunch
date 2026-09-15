local dedupe = require('modules/custom/lua/rema_stage_dedupe')
local forge  = require('modules/custom/lua/weapon_forge_catalog')

describe('REMA leftover-stage dedupe', function()
    it('includes Mandau as a four-stage relic family', function()
        local mandau
        for _, fam in ipairs(dedupe.families()) do
            if fam.family == 'relic' and fam.name == 'Mandau' then
                mandau = fam
                break
            end
        end
        assert.is_truthy(mandau)
        assert.are.same({ 19747, 20555, 20556, 20583 }, mandau.stages)
        assert.equals(20583, mandau.finalId)
    end)

    it('keeps the highest stage and an active pilgrimage piece', function()
        local stages = { 19747, 20555, 20556, 20583 }
        local keepHighest = dedupe.planKeep(stages, 4, 0)
        assert.equals('all', keepHighest[20583])
        assert.is_nil(keepHighest[20556])

        local keepWorking = dedupe.planKeep(stages, 4, 20556)
        assert.equals('all', keepWorking[20583])
        assert.equals(1, keepWorking[20556])
        assert.is_nil(keepWorking[20555])

        local keepMid = dedupe.planKeep(stages, 3, 0)
        assert.equals(1, keepMid[20556])
        assert.is_nil(keepMid[20583])
    end)

    it('covers every relic, empyrean, mythic, prime, and aeonic chain', function()
        local counts = { relic = 0, empyrean = 0, mythic = 0, prime = 0, aeonic = 0 }
        for _, fam in ipairs(dedupe.families()) do
            counts[fam.family] = (counts[fam.family] or 0) + 1
            assert.is_true(#fam.stages >= 2)
            assert.are_not.equals(19973, fam.finalId)
        end
        assert.equals(#forge.relicChains, counts.relic)
        assert.equals(#forge.empyreanChains, counts.empyrean)
        assert.equals(#forge.mythicChains, counts.mythic)
        assert.equals(#forge.chains, counts.prime)
        assert.equals(#forge.chains, counts.aeonic)
    end)
end)
