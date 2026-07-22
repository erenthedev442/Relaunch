local catalog = require('modules/custom/lua/gauntlet_catalog')

describe('Gauntlet damage-ceiling rebalance', function()
    it('uses the reduced ten-level HP curve', function()
        local expected =
        {
            5000000,
            5830000,
            6797779,
            7926211,
            9241962,
            10776128,
            12564965,
            14650749,
            17082774,
            19918515,
        }

        for level, hp in ipairs(expected) do
            assert(catalog.nmHp(level) == hp)
            if level > 1 then
                assert(catalog.nmHp(level) > catalog.nmHp(level - 1))
            end
        end
    end)

    it('scales self-healing with the reduced HP curve', function()
        for level = 1, 10 do
            local drain = catalog.mechCfg(level).drain
            assert(drain.periodSec == 15)
            assert(drain.heal == level * 1000)
        end
    end)

    it('makes hold-fire weakness windows materially vulnerable', function()
        local expectedDef = { 4400, 5444, 5889, 6333, 6778, 7222, 7667, 7400, 7045, 6200 }
        local expectedEva = { 1350, 1667, 1833, 2000, 2167, 2333, 2500, 2489, 2455, 2300 }

        assert(catalog.WEAK_WINDOW_EXTRA_DOWN == 1000)
        for level = 1, 10 do
            local mods     = catalog.nmMods(level)
            local weakness = catalog.weakWindowMods(level)
            local holdFire = catalog.holdFireCfg(level)

            assert(mods[xi.mod.DEF] - weakness.defDown == expectedDef[level])
            assert(mods[xi.mod.EVA] - weakness.evaDown == expectedEva[level])
            assert(holdFire.defDown == weakness.defDown)
            assert(holdFire.evaDown == weakness.evaDown)
            assert(holdFire.mdefDown == weakness.mdefDown)
            assert(holdFire.mevaDown == weakness.mevaDown)
        end
    end)

    it('caps Kirin earth magic and prevents native Terror overlap', function()
        assert(catalog.bossOverrides.kirinSpellCap.damageCap == 4500)
        assert(catalog.bossOverrides.absoluteTerror.recastSec == 45)
        assert(catalog.bossOverrides.vrtraTerror.recastSec == 60)
        assert(catalog.bossOverrides.vrtraTerror.terrorMaxSec == 8)

        -- Nidhogg and Vrtra already select Absolute Terror as a native TP move;
        -- they must not also receive the mechanics library's periodic Terror.
        assert(catalog.mechCfg(4).cc == nil)
        assert(catalog.mechCfg(6).cc == nil)
    end)
end)
