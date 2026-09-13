require('scripts/globals/job_utils/thief')

describe('Larceny SP copy duration', function()
    it('does not turn 30s mob Invincible into 8 hours', function()
        local copied = xi.job_utils.thief.copiedEffectDurationSeconds

        -- Old bug: 30000 ms passed to addStatusEffect as seconds = 8h20m
        assert(copied(30000, 30000, 0) == 30)
        assert(copied(30000, 18000, 0) == 18)
        assert(copied(30000, 30000, 5) == 35)
        assert(copied(30000, 0, 0) == 30)
        assert(xi.job_utils.thief.copiedEffectTickSeconds(0) == 0)
        assert(xi.job_utils.thief.copiedEffectTickSeconds(3000) == 3)
    end)
end)
