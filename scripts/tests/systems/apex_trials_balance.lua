local catalog = require('modules/custom/lua/apex_catalog')

local function modAt(tier, modId)
    return catalog.bossMods(tier)[modId]
end

describe('Apex Trials weapon-gate curve', function()
    it('uses Relic / Empy / Aeonic / Prime anchors', function()
        assert(catalog.bossLevel(1) == 99)
        assert(catalog.bossLevel(10) == 102)
        assert(catalog.bossLevel(11) == 105)
        assert(catalog.bossLevel(30) == 112)
        assert(catalog.bossLevel(31) == 115)
        assert(catalog.bossLevel(50) == 122)
        assert(catalog.bossLevel(51) == 125)
        assert(catalog.bossLevel(100) == 130)
        assert(catalog.bossLevel(500) == 130)

        assert(catalog.bossHp(1) == 1000000)
        assert(catalog.bossHp(10) == 1600000)
        assert(catalog.bossHp(11) == 1800000)
        assert(catalog.bossHp(30) == 3200000)
        assert(catalog.bossHp(31) == 3500000)
        assert(catalog.bossHp(50) == 5000000)
        assert(catalog.bossHp(51) == 5500000)
        assert(catalog.bossHp(100) == 9000000)
        assert(catalog.bossHp(200) == 14000000)

        assert(modAt(1, xi.mod.DEF) == 1400)
        assert(modAt(10, xi.mod.DEF) == 2600)
        assert(modAt(11, xi.mod.DEF) == 7500)
        assert(modAt(30, xi.mod.DEF) == 8500)
        assert(modAt(31, xi.mod.DEF) == 11500)
        assert(modAt(50, xi.mod.DEF) == 12500)
        assert(modAt(51, xi.mod.DEF) == 16500)
        assert(modAt(100, xi.mod.DEF) == 17500)
        assert(modAt(200, xi.mod.DEF) == 18000)
    end)

    it('puts a real DEF cliff at 11, 31, and 51', function()
        assert(modAt(11, xi.mod.DEF) - modAt(10, xi.mod.DEF) >= 4000)
        assert(modAt(31, xi.mod.DEF) - modAt(30, xi.mod.DEF) >= 2500)
        assert(modAt(51, xi.mod.DEF) - modAt(50, xi.mod.DEF) >= 3500)
        assert(catalog.bossHp(11) / catalog.bossHp(10) < 1.20)
        assert(catalog.bossHp(31) / catalog.bossHp(30) < 1.20)
        assert(catalog.bossHp(51) / catalog.bossHp(50) < 1.20)
    end)

    it('never exceeds the level cap and keeps mods int16-safe', function()
        local previousHp = 0
        for _, tier in ipairs({ 1, 10, 11, 30, 31, 50, 51, 100, 200, 500, 1000 }) do
            assert(catalog.bossLevel(tier) <= 130)
            assert(catalog.bossHp(tier) > previousHp)
            previousHp = catalog.bossHp(tier)

            local totals = catalog.bossMods(tier)
            for _, affix in ipairs(catalog.AFFIX_DEFS) do
                for modId, value in pairs(catalog.affixMods(affix.key, tier)) do
                    totals[modId] = (totals[modId] or 0) + value
                end
            end
            assert((totals[xi.mod.ATT] or 0) < 32000)
            assert((totals[xi.mod.DEF] or 0) < 32000)
            assert((totals[xi.mod.EVA] or 0) < 32000)
            assert((totals[xi.mod.REGEN] or 0) == 0)
        end
    end)

    it('aligns mechanics to weapon bands and never drains', function()
        assert(catalog.mechCfg(1).name == 'Apex Challenger')
        assert(catalog.mechCfg(10).name == 'Apex Challenger')
        assert(catalog.mechCfg(11).name == 'Apex Champion')
        assert(catalog.mechCfg(30).name == 'Apex Champion')
        assert(catalog.mechCfg(31).name == 'Apex Conqueror')
        assert(catalog.mechCfg(50).name == 'Apex Conqueror')
        assert(catalog.mechCfg(51).name == 'Apex Warlord')
        assert(catalog.mechCfg(99).name == 'Apex Warlord')
        assert(catalog.mechCfg(100).name == 'Apex Imperator')
        assert(catalog.mechCfg(200).name == 'Apex Absolute')

        for _, tier in ipairs({ 1, 11, 31, 50, 51, 75, 100, 200 }) do
            local cfg = catalog.mechCfg(tier)
            assert(cfg.drain == nil)
            assert(cfg.aoe == nil)
            for _, phase in ipairs(cfg.phases or {}) do
                assert(phase.action ~= 'nuke')
            end
            assert(catalog.affixMods('Vampiric', tier)[xi.mod.REGEN] == nil)
            assert(catalog.affixMods('Regenerating', tier)[xi.mod.REGEN] == nil)
        end
    end)
end)
