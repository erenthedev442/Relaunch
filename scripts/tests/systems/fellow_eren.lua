-- Hidden Fellow name "Eren" raises DPS/Magus ceilings, tank DT, and Oracle
-- Cure Potency II. Any other name keeps the stock 99,999 / 50-70k profile.

describe('Eren fellow role bonuses', function()
    local fellow

    before_each(function()
        require('modules/custom/lua/fellow_companion')
        fellow = xi.fellow
    end)

    it('keeps stock outgoing and endgame caps when the Fellow is not named Eren', function()
        assert(fellow.outgoingCap(false, 'vanguard', 1.0) == 99999)
        assert(fellow.outgoingCap(false, 'magus', 1.0) == 99999)
        assert(fellow.aoeCap(false, 'magus') == 0)

        local floor, cap = fellow.endgameDamageBand(false, 'vanguard', 400000, 1.0)
        assert(floor == 50000)
        assert(cap == 70000)
    end)

    it('lets Eren DPS and Magus single-target break the 99,999 fellow ceiling', function()
        assert(fellow.outgoingCap(true, 'vanguard', 1.0) == 149999)
        assert(fellow.outgoingCap(true, 'berserker', 1.0) == 149999)
        assert(fellow.outgoingCap(true, 'hunter', 1.0) == 149999)
        assert(fellow.outgoingCap(true, 'mastered', 1.0) == 149999)
        assert(fellow.outgoingCap(true, 'magus', 1.0) == 149999)

        local floor, cap = fellow.endgameDamageBand(true, 'vanguard', 400000, 1.0)
        assert(floor == 50000)
        assert(cap == 149999)
    end)

    it('caps Eren Magus AoE at 99,999 while leaving tank and oracle outgoing stock', function()
        assert(fellow.aoeCap(true, 'magus') == 99999)
        assert(fellow.aoeCap(true, 'vanguard') == 0)
        assert(fellow.outgoingCap(true, 'bulwark', 1.0) == 99999)
        assert(fellow.outgoingCap(true, 'oracle', 1.0) == 99999)

        local _, magusCap = fellow.endgameDamageBand(true, 'magus', 400000, 1.0)
        local _, tankCap = fellow.endgameDamageBand(true, 'bulwark', 400000, 1.0)
        assert(magusCap == 149999)
        assert(tankCap == 70000)
    end)

    it('still HP-limits the Eren DPS band so it cannot one-shot a 100k mob', function()
        local floor, cap = fellow.endgameDamageBand(true, 'berserker', 100000, 1.0)
        assert(floor == 50000)
        assert(cap == 50000)
    end)

    it('gives Eren tank 50% DT and extra HP, and Oracle +20 Cure Potency II', function()
        assert(fellow.eren.tankDt == -5000)
        assert(fellow.eren.tankHpMult == 1.50)
        assert(fellow.eren.oracleCurePotencyII == 20)
        assert(fellow.eren.oracleHealMult == 1.20)
    end)
end)
