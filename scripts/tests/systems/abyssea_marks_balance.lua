local balance = require('modules/custom/lua/abyssea_marks_balance')

describe('Abyssea marks Relic-led balance contract', function()
    local function within(value, band)
        return value >= band[1] and value <= band[2]
    end

    it('records the pre-Abyssea defensive calibration sheet', function()
        local target = balance.targetPlayer
        assert(target.accuracy == 3000)
        assert(target.evasion == 1000)
        assert(target.defense == 3400)
        assert(target.damageTakenPct == -35)
        assert(target.regen == 700)
    end)

    it('starts soft pressure inside each expected clear-time band', function()
        assert(balance.tiers[1].pressureMinutes == 4)
        assert(balance.tiers[2].pressureMinutes == 6)
        assert(balance.tiers[3].pressureMinutes == 8)
    end)

    it('puts T1 Relic throughput in the 5-7 minute band', function()
        local cfg = balance.tiers[1]
        assert(within(balance.expectedMinutes(1, 1, cfg.relicDpsPerMinute[1]), cfg.targetSoloMinutes))
        assert(within(balance.expectedMinutes(1, 1, cfg.relicDpsPerMinute[2]), cfg.targetSoloMinutes))
    end)

    it('makes representative pre-Relic T1 throughput lose to pressure', function()
        local cfg = balance.tiers[1]
        assert(balance.expectedMinutes(1, 1, cfg.preRelicDpsPerMinute) > cfg.pressureMinutes)
    end)

    it('puts T2 Relic plus one Atma in the 7-10 minute band', function()
        local cfg = balance.tiers[2]
        assert(within(balance.expectedMinutes(2, 1, cfg.relicDpsPerMinute[1]), cfg.targetSoloMinutes))
        assert(within(balance.expectedMinutes(2, 1, cfg.relicDpsPerMinute[2]), cfg.targetSoloMinutes))
    end)

    it('puts T3 Relic plus two Atma in the 10-14 minute solo band', function()
        local cfg = balance.tiers[3]
        assert(within(balance.expectedMinutes(3, 1, cfg.relicDpsPerMinute[1]), cfg.targetSoloMinutes))
        assert(within(balance.expectedMinutes(3, 1, cfg.relicDpsPerMinute[2]), cfg.targetSoloMinutes))
    end)

    it('keeps skilled T3 group clears near the documented band', function()
        local cfg = balance.tiers[3]
        assert(balance.expectedMinutes(3, 2, 1300000) < 10)
        assert(balance.expectedMinutes(3, 3, 1200000) < 10)
    end)

    it('splits T3 gil across the alliance instead of copying it per character', function()
        assert(balance.gilPayout(750000, 1.0, 1) == 750000)
        assert(balance.gilPayout(750000, 1.5, 1) == 1125000)
        assert(balance.gilPayout(750000, 1.0, 6) == 125000)
        assert(balance.gilPayout(750000, 1.5, 6) == 187500)
        assert(balance.gilPayout(750000, 1.0, 6) * 6 == 750000)
    end)

    it('uses the shared party-size HP curve', function()
        assert(balance.hpScale(1) == 1.00)
        assert(balance.hpScale(2) == 1.70)
        assert(balance.hpScale(3) == 2.40)
        assert(balance.hpScale(6) == 5.00)
    end)
end)
