-----------------------------------
-- Dynamis procs mixin
-----------------------------------
require('scripts/globals/mixins')
require('scripts/globals/dynamis')
-----------------------------------
g_mixins = g_mixins or {}

-- RELAUNCH (2026-07-09, report Spyro): stock Dynamis floods inventory with AF /
-- Relic gear that nobody uses (players start at lvl 109), so every run ends in
-- throwing the loot away. Block ALL droplist drops on Dynamis beastmen so only
-- the CURRENCY remains -- currency is awarded below via killer:addTreasure(),
-- which is INDEPENDENT of the mob's droplist, so zeroing the droplist keeps the
-- currency economy (relic grind) fully intact while cutting the clutter.
-- Scope: this mixin is used ONLY by the stock Dynamis zones; the Divergence
-- instances (Dynamis-*_[D]) do NOT use it, so their medal droplists are untouched.
-- Toggle off to restore vanilla gear drops.
local BLOCK_GEAR_DROPS = true

g_mixins.dynamis_beastmen = function(dynamisBeastmenMob)
    dynamisBeastmenMob:addListener('SPAWN', 'PARTY_HP_SCALE_PREPARE', function(mob)
        require('modules/custom/lua/party_hp_scale').prepare(mob)
    end)

    if BLOCK_GEAR_DROPS then
        -- setDropID(0) => no droplist roll at death. Runs each spawn so it's set
        -- well before the death-time drop roll. Currency (addTreasure) is unaffected.
        dynamisBeastmenMob:addListener('SPAWN', 'DYNAMIS_BLOCK_GEAR_DROPS', function(mob)
            mob:setDropID(0)
        end)
    end

    local procjobs =
    {
        [xi.job.WAR] = 'ws',
        [xi.job.MNK] = 'ja',
        [xi.job.WHM] = 'ma',
        [xi.job.BLM] = 'ma',
        [xi.job.RDM] = 'ma',
        [xi.job.THF] = 'ja',
        [xi.job.PLD] = 'ws',
        [xi.job.DRK] = 'ws',
        [xi.job.BST] = 'ja',
        [xi.job.BRD] = 'ma',
        [xi.job.RNG] = 'ja',
        [xi.job.SAM] = 'ws',
        [xi.job.NIN] = 'ja',
        [xi.job.DRG] = 'ws',
        [xi.job.SMN] = 'ma',
    }

    local familyCurrency =
    {
        [xi.mobSuperFamily.ORC   ] = xi.item.ORDELLE_BRONZEPIECE, -- Orc
        [xi.mobSuperFamily.QUADAV] = xi.item.ONE_BYNE_BILL,       -- Quadav
        [xi.mobSuperFamily.YAGUDO] = xi.item.TUKUKU_WHITESHELL,   -- Yagudo
    }

    -- With Treasure Hunter on every procced monster, you can expect approximately 1.7 coins per kill on average.
    -- Without Treasure Hunter, you can expect about 1.25 coins per kill on average.
    -- Without a proc, the coin drop rate is very low (~10%)
    local thCurrency =
    {
        [0] = { single = 100, hundred =  5 },
        [1] = { single = 115, hundred = 10 },
        [2] = { single = 145, hundred = 20 },
        [3] = { single = 190, hundred = 35 },
        [4] = { single = 250, hundred = 50 },
    }

    dynamisBeastmenMob:addListener('MAGIC_TAKE', 'DYNAMIS_MAGIC_PROC_CHECK', function(target, caster, spell)
        if
            procjobs[target:getMainJob()] == 'ma' and
            math.random(1, 100) <= 8 and
            target:getLocalVar('dynamis_proc') == 0
        then
            xi.dynamis.procMonster(target, caster)
        end
    end)

    dynamisBeastmenMob:addListener('WEAPONSKILL_TAKE', 'DYNAMIS_WS_PROC_CHECK', function(user, target, skill, tp, action)
        if
            procjobs[target:getMainJob()] == 'ws' and
            math.random(1, 100) <= 25 and
            target:getLocalVar('dynamis_proc') == 0
        then
            xi.dynamis.procMonster(target, user)
        end
    end)

    dynamisBeastmenMob:addListener('ABILITY_TAKE', 'DYNAMIS_ABILITY_PROC_CHECK', function(user, target, skill, action)
        if
            procjobs[target:getMainJob()] == 'ja' and
            math.random(1, 100) <= 20 and
            target:getLocalVar('dynamis_proc') == 0
        then
            xi.dynamis.procMonster(target, user)
        end
    end)

    dynamisBeastmenMob:addListener('DEATH', 'DYNAMIS_ITEM_DISTRIBUTION', function(mob, killer)
        if not killer then
            return
        end

        local th            = thCurrency[math.min(mob:getTHlevel(), 4)]
        local currency      = familyCurrency[mob:getSuperFamily()] or xi.item.TUKUKU_WHITESHELL + math.random(0, 2) * 3
        local singleChance  = mob:getMainLvl() > 90 and math.floor(th.single * 1.5) or th.single
        local hundredChance = th.hundred

        -- White (special) adds 100% hundred slot
        if mob:getLocalVar('dynamis_proc') >= 4 then
            killer:addTreasure(currency + 1, mob)
        end

        -- Base hundred slot
        if mob:isNM() then
            killer:addTreasure(currency + 1, mob, hundredChance)
        end

        -- red (high) adds 100% single slot
        if mob:getLocalVar('dynamis_proc') >= 3 then
            killer:addTreasure(currency, mob)
        end

        -- yellow (medium) adds single slot
        if mob:getLocalVar('dynamis_proc') >= 2 then
            killer:addTreasure(currency, mob, singleChance)
        end

        -- blue (low) adds single slot
        if mob:getLocalVar('dynamis_proc') >= 1 then
            killer:addTreasure(currency, mob, singleChance)
        end

        killer:addTreasure(currency, mob, singleChance) -- base single slot
    end)
end

return g_mixins.dynamis_beastmen
