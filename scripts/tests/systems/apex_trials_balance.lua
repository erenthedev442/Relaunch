local catalog = require('modules/custom/lua/apex_catalog')

local function modAt(tier, modId)
    return catalog.bossMods(tier)[modId]
end

describe('Apex Trials progression curve', function()
    it('uses the intended Relic, Prime, and elite anchors', function()
        assert(catalog.bossLevel(1) == 135)
        assert(catalog.bossLevel(50) == 145)
        assert(catalog.bossLevel(100) == 150)
        assert(catalog.bossLevel(500) == 150)

        assert(catalog.bossHp(1) == 1500000)
        assert(catalog.bossHp(50) >= 7538000 and catalog.bossHp(50) <= 7539000)
        assert(catalog.bossHp(100) >= 20291000 and catalog.bossHp(100) <= 20292000)
        assert(catalog.bossHp(500) >= 67266000 and catalog.bossHp(500) <= 67267000)

        assert(modAt(1, xi.mod.ATT) == 4500)
        assert(modAt(50, xi.mod.ATT) == 10000)
        assert(modAt(100, xi.mod.ATT) == 18000)
        assert(modAt(500, xi.mod.ATT) == 24000)

        assert(modAt(1, xi.mod.DEF) == 1500)
        assert(modAt(50, xi.mod.DEF) == 5000)
        assert(modAt(100, xi.mod.DEF) == 8000)
        assert(modAt(500, xi.mod.DEF) == 11200)
    end)

    it('grows smoothly without a tier boundary cliff', function()
        local previousHp = 0
        local previousAtt = 0
        for tier = 1, 500 do
            local hp = catalog.bossHp(tier)
            local att = modAt(tier, xi.mod.ATT)

            assert(hp > previousHp)
            assert(att >= previousAtt)
            assert(catalog.bossLevel(tier) <= 150)

            previousHp = hp
            previousAtt = att
        end

        assert(catalog.bossHp(51) / catalog.bossHp(50) < 1.021)
        assert(catalog.bossHp(101) / catalog.bossHp(100) < 1.02)
        assert(modAt(51, xi.mod.ATT) - modAt(50, xi.mod.ATT) <= 160)
        assert(modAt(101, xi.mod.ATT) - modAt(100, xi.mod.ATT) <= 50)
    end)

    it('keeps direct and worst-case affix modifiers int16-safe', function()
        local checkedTiers = { 1, 50, 100, 200, 300, 500, 1000, 10000 }
        for _, tier in ipairs(checkedTiers) do
            local totals = catalog.bossMods(tier)
            for _, affix in ipairs(catalog.AFFIX_DEFS) do
                for modId, value in pairs(catalog.affixMods(affix.key, tier)) do
                    totals[modId] = (totals[modId] or 0) + value
                end
            end

            assert((totals[xi.mod.ATT] or 0) < 32000)
            assert((totals[xi.mod.DEF] or 0) < 32000)
            assert((totals[xi.mod.ACC] or 0) < 32000)
            assert((totals[xi.mod.EVA] or 0) < 32000)
        end
    end)

    it('introduces affixes and mechanic kits at progression milestones', function()
        local expectedAffixes =
        {
            [24] = 0, [25] = 1,
            [49] = 1, [50] = 2,
            [74] = 2, [75] = 3,
            [99] = 3, [100] = 4,
            [199] = 4, [200] = 5,
            [299] = 5, [300] = 6,
            [500] = 6,
        }
        for tier, expected in pairs(expectedAffixes) do
            assert(catalog.affixCount(tier) == expected)
        end

        assert(catalog.mechCfg(1).name == 'Apex Challenger')
        assert(catalog.mechCfg(24).name == 'Apex Challenger')
        assert(catalog.mechCfg(25).name == 'Apex Champion')
        assert(catalog.mechCfg(50).name == 'Apex Conqueror')
        assert(catalog.mechCfg(75).name == 'Apex Warlord')
        assert(catalog.mechCfg(100).name == 'Apex Imperator')
        assert(catalog.mechCfg(200).name == 'Apex Absolute')
    end)

    it('ramps scripted pulse damage from entry to elite tiers', function()
        assert(catalog.pulseDamagePct(1) == 5)
        assert(catalog.pulseDamagePct(25) >= 8)
        assert(catalog.pulseDamagePct(50) >= 12)
        assert(catalog.pulseDamagePct(75) >= 16)
        assert(catalog.pulseDamagePct(99) == 20)
        assert(catalog.pulseDamagePct(100) == 20)
        assert(catalog.pulseDamagePct(150) == 25)
        assert(catalog.pulseDamagePct(200) == 30)
        assert(catalog.pulseDamagePct(10000) == 30)

        local previous = 0
        for tier = 1, 500 do
            local damage = catalog.pulseDamagePct(tier)
            assert(damage >= previous)
            assert(damage >= 5 and damage <= 30)
            assert(catalog.mechCfg(tier).aoe.dmgPct == damage)
            previous = damage
        end
    end)
end)
