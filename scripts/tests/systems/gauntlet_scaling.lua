local catalog     = require('modules/custom/lua/gauntlet_catalog')
local remaCatalog = require('modules/custom/lua/rema_ws_tier_catalog')

describe('Gauntlet damage-ceiling rebalance', function()
    it('uses the flattened ten-level HP curve', function()
        local expected =
        {
            4500000,
            4711500,
            4932940,
            5164788,
            5407533,
            5661687,
            5927787,
            6206393,
            6498093,
            8803504,
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
        local expectedDef  = { 2100, 2140, 2180, 2220, 2260, 2300, 2340, 2380, 2420, 2460 }
        local expectedEva  = { 200, 210, 220, 230, 240, 250, 260, 270, 280, 290 }
        local expectedMdef = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
        for level = 1, 10 do
            local mods     = catalog.nmMods(level)
            local weakness = catalog.weakWindowMods(level)
            local holdFire = catalog.holdFireCfg(level)

            assert(mods[xi.mod.DEF] - weakness.defDown == expectedDef[level])
            assert(mods[xi.mod.EVA] - weakness.evaDown == expectedEva[level])
            assert(mods[xi.mod.MDEF] - weakness.mdefDown == expectedMdef[level])
            assert(holdFire.defDown == weakness.defDown)
            assert(holdFire.evaDown == weakness.evaDown)
            assert(holdFire.mdefDown == weakness.mdefDown)
            assert(holdFire.mevaDown == weakness.mevaDown)
            assert(holdFire.pressureDelaySec == 5)
            assert(mods[xi.mod.EVA] <= 535)
        end
    end)

    it('draws the runner in past 8 yalms on every Gauntlet kit', function()
        assert(catalog.DRAW_IN_YALMS == 8)
        assert(catalog.DRAW_IN_WAIT == 1)
        for level = 1, 10 do
            local cfg = catalog.mechCfg(level)
            assert(cfg.drawInYalms == 8)
            assert(cfg.drawInWait == 1)
            assert(cfg.drawInMsg ~= nil)
        end
    end)

    it('resumes the next uncleared boss per job and resets after a full clear', function()
        assert(catalog.nextAfterClear(1) == 2)
        assert(catalog.nextAfterClear(3) == 4)
        assert(catalog.nextAfterClear(9) == 10)
        assert(catalog.nextAfterClear(10) == 1)
        assert(catalog.clampStartLevel(0) == 1)
        assert(catalog.clampStartLevel(11) == 1)
        assert(catalog.jobSaveVar(16) == 'Gauntlet_Next_16')
        assert(catalog.LEVEL_REWARD(3).gil == 150000)
        assert(catalog.FINAL_REWARD.gil == 5000000)
        assert(catalog.FINAL_REWARD.pp == 500)
    end)

    it('eases Shinryu hit and TP rate while adding two million HP', function()
        assert(catalog.nmHp(9) == 6498093)
        assert(catalog.nmHp(10) == 8803504)
        assert(catalog.nmMods(10)[xi.mod.ATT] == 29200)
        assert(catalog.nmMods(10)[xi.mod.REGAIN] == 660)
        assert(catalog.nmMods(10)[xi.mod.MATT] == 15750)
        assert(catalog.nmMobMods(10)[xi.mobMod.WEAPON_BONUS] == 135)
        assert(catalog.nmMods(9)[xi.mod.ATT] == 29333)
        local shinryu = catalog.mechCfg(10)
        assert(shinryu.enrage.att == 8800)
        assert(shinryu.enrage.haste == 260)
        assert(shinryu.cc.periodSec == 16)
        assert(shinryu.phases[2].att == 6200)
        assert(shinryu.phases[2].haste == 175)
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

    -- 2026-09-07: 119 III Apocalypse Entropy/etc. hit the 99,999 ordinary
    -- ceiling in the Gauntlet while Catastrophe did vanilla 500-11k. Native
    -- REMA pairs must stay on that 13x curve unless RemaWsTuned is set.
    it('keeps relic Catastrophe wired and documents the DEF wall', function()
        local relic = remaCatalog.getFamilyTuning('RELIC')
        local entry = remaCatalog.getEntry(21808, xi.weaponskill.CATASTROPHE, xi.slot.MAIN)

        assert(entry ~= nil)
        assert(entry.family == 'RELIC')
        assert(remaCatalog.getTuning(xi.weaponskill.CATASTROPHE) == 8.60)
        assert(relic.ignoredDefense[3] == 0.15)
        assert(remaCatalog.getEntry(20881, xi.weaponskill.CATASTROPHE, xi.slot.MAIN) == nil)
        assert(remaCatalog.getEntry(20880, xi.weaponskill.CATASTROPHE, xi.slot.MAIN) == nil)
        assert(remaCatalog.getEntry(19753, xi.weaponskill.CATASTROPHE, xi.slot.MAIN) == nil)

        -- Relic only ignores 15% DEF. Closed-window Gauntlet DEF is still a
        -- wall (~7.7k-9.6k effective); hold-fire windows drop that to ~1.8k-2.1k.
        local closedEffective = {}
        local windowEffective = {}
        for level = 1, 10 do
            local def       = catalog.nmMods(level)[xi.mod.DEF]
            local windowDef = def - catalog.weakWindowMods(level).defDown
            closedEffective[level] = def * (1 - relic.ignoredDefense[3])
            windowEffective[level] = windowDef * (1 - relic.ignoredDefense[3])
            assert(windowEffective[level] < closedEffective[level] - 3000)
        end

        assert(math.abs(closedEffective[1] - 7650) < 1)
        assert(math.abs(closedEffective[10] - 9562.5) < 1)
        assert(windowEffective[1] < 2000)
        assert(windowEffective[10] < 2200)
    end)
end)
