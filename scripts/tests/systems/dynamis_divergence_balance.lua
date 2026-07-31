require('scripts/globals/dynamis_divergence')
require('modules/custom/lua/Augment_Moogle')

local instances =
{
    require('scripts/zones/Dynamis-San_dOria_[D]/instances/dynamis_san_doria_d'),
    require('scripts/zones/Dynamis-Bastok_[D]/instances/dynamis_bastok_d'),
    require('scripts/zones/Dynamis-Windurst_[D]/instances/dynamis_windurst_d'),
    require('scripts/zones/Dynamis-Jeuno_[D]/instances/dynamis_jeuno_d'),
}

describe('Dynamis Divergence T3 solo balance', function()
    it('uses the intended boss stat ladder', function()
        local balance = xi.divergence.balance

        assert(balance.mid.hp == 200000)
        assert(balance.mega.hp == 900000)
        assert(balance.disjoined.hp == 1400000)
        assert(balance.mid.mods[xi.mod.ATT] == 3500)
        assert(balance.mega.mods[xi.mod.ATT] == 5200)
        assert(balance.disjoined.mods[xi.mod.ATT] == 6000)
        assert(balance.mega.mods[xi.mod.ACC] == 1500)
        assert(balance.disjoined.mods[xi.mod.ACC] == 1700)
    end)

    it('limits sustain and removes mandatory execute pressure', function()
        for _, cfg in pairs(xi.divergence.bossMechCfgs) do
            assert(cfg.drain.healPct <= 0.5)
            assert(cfg.drain.periodSec >= 10)
            assert(cfg.doom == nil)

            if cfg.aoe then
                assert(cfg.aoe.dmgPct <= 15)
                assert(cfg.aoe.periodSec >= 17)
            end
        end
    end)

    it('activates the same solo corridor density in every city', function()
        local balance = xi.divergence.balance

        for _, instance in ipairs(instances) do
            assert(#instance.config.wave1Mobs == balance.activeWaveTrash)
            assert(#instance.config.wave2Mobs == balance.activeWaveTrash)
            assert(#instance.config.statues == balance.activeStatues)
            assert(xi.divergence.bossMechCfgs[instance.config.midBoss] ~= nil)
            assert(xi.divergence.bossMechCfgs[instance.config.megaBoss] ~= nil)
            assert(xi.divergence.bossMechCfgs[instance.config.disjoined] ~= nil)
        end
    end)

    it('keeps the Windurst mega-boss in its registered custom entity range', function()
        local windurst = instances[3].config
        assert(windurst.megaBoss == 17990606)
        assert(xi.divergence.bossMechCfgs[windurst.megaBoss] ~= nil)
    end)

    it('never treats a preloaded but unspawned boss as defeated', function()
        local originalGetMobByID = GetMobByID
        local vars = {}
        local alive = false
        local mob =
        {
            isAlive = function() return alive end,
        }
        local instance =
        {
            getLocalVar = function(_, key) return vars[key] or 0 end,
            setLocalVar = function(_, key, value) vars[key] = value end,
        }

        local ok, err = xpcall(function()
            GetMobByID = function() return mob end

            assert(xi.divergence.isBossDefeated(instance, 1234, 'Mega') == false)

            alive = true
            assert(xi.divergence.isBossDefeated(instance, 1234, 'Mega') == false)
            assert(vars.divBossSeenMega == 1)

            alive = false
            assert(xi.divergence.isBossDefeated(instance, 1234, 'Mega') == false)

            vars.divBossKilledMega = 1
            GetMobByID = function() return nil end
            assert(xi.divergence.isBossDefeated(instance, 1234, 'Mega') == true)

            vars.divBossSeenMega = 0
            assert(xi.divergence.isBossDefeated(instance, 1234, 'Mega') == false)
        end, debug.traceback)

        GetMobByID = originalGetMobByID
        assert(ok, err)
    end)

    it('requires Hunt Rank 4 completion and a full city clear for T4', function()
        local vars = {
            HL_Tier = 4,
            NMKilled_11358 = 1,
            NMKilled_11359 = 1,
            NMKilled_11360 = 1,
            NMKilled_11361 = 1,
            NMKilled_11362 = 1,
            NMKilled_11363 = 1,
            NMKilled_11364 = 1,
            NMKilled_11365 = 1,
            NMKilled_11366 = 1,
            Voidspire_Best_Floor = 10,
            GM_Wave_Clears = 15,
            DivergenceMegaSlots = 1,
        }
        local player =
        {
            getJobLevel = function() return 99 end,
            getCharVar = function(_, name) return vars[name] or 0 end,
        }

        assert(xi.augmentTiers.tierOf(player) == 3)

        vars.DivergenceSlots = 1
        assert(xi.augmentTiers.tierOf(player) == 4)

        vars.NMKilled_11366 = 0
        assert(xi.augmentTiers.tierOf(player) == 3)
    end)

    it('joins an in-progress party instance for the same city', function()
        local liveInstance =
        {
            getID = function() return 29400 end,
            completed = function() return false end,
            failed = function() return false end,
        }
        local leader =
        {
            getID = function() return 1 end,
            getInstance = function() return liveInstance end,
        }
        local follower =
        {
            getID = function() return 2 end,
            getInstance = function() return nil end,
            getParty = function() return { leader, follower } end,
        }

        assert(xi.divergence.findPartyInstance(follower, 29400) == liveInstance)
        assert(xi.divergence.findPartyInstance(follower, 29500) == nil)
    end)
end)
