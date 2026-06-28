-----------------------------------
-- htbf.lua  -- High-Tier Mission Battlefield registrar (relaunch)
--
-- One call per tier from a tiny battlefield file:
--   return require('modules/custom/lua/htbf').register('trial_by_fire', 2)
--
-- Builds a Battlefield (the engine needs no change): a unique battlefieldId +
-- a unique menu `index` on the existing entrance NPC, gated on the fight's
-- Phantom Gem (consumed on entry), reusing the base boss and scaling it
-- per-instance in setupBattlefield. Data lives in htbf_catalog.lua.
--
-- Loaded from scripts/battlefields/<Zone>/<key>_ht{1,2,3}.lua, so the global
-- Battlefield class + xi.* are already available.
-----------------------------------
local catalog = require('modules/custom/lua/htbf_catalog')

local htbf = {}

function htbf.register(fightKey, tier)
    local f     = catalog.fights[fightKey]
    local scale = catalog.tierScale[tier]
    local rew   = catalog.tierReward[tier]
    if not f or not scale then
        print(string.format('[HTBF] register: bad args (%s, %s)', tostring(fightKey), tostring(tier)))
        return nil
    end

    local content = Battlefield:new({
        zoneId           = f.zone,
        battlefieldId    = f.baseBattlefieldId + (tier - 1),
        index            = f.baseIndex + (tier - 1),
        entryNpc         = f.entryNpc,
        exitNpc          = f.exitNpc,
        exitNpcs         = f.exitNpcs,
        allowedAreas     = f.allowedAreas,
        maxPlayers       = f.maxPlayers or 6,
        timeLimit        = f.timeLimit or utils.minutes(30),
        canLoseExp       = false,
        requiredKeyItems = { f.gem },   -- consumed on entry (no keep); HTBF is gem-gated
    })

    -- Groups. Simple single-boss fights name the boss (f.mobs). Complex fights
    -- (multi-group, per-arena mobIds, skillchain AI, phase sections) instead
    -- REUSE the base battlefield's full definition via f.reuseBaseId (the base's
    -- xi.battlefield.id) -- we copy its groups + tick/section logic so the fight
    -- runs identically; we only re-gate it (gem) + scale it. The base script
    -- loads alphabetically before <key>_ht*.lua, so it is registered by now.
    if f.reuseBaseId then
        local base = xi.battlefield.contents[f.reuseBaseId]
        if base then
            content.groups = base.groups
            if base.onBattlefieldTick then content.onBattlefieldTick = base.onBattlefieldTick end
            if base.sections          then content.sections          = base.sections          end
        else
            print(string.format('[HTBF] %s tier %d: base id %s not registered (load order?)',
                tostring(fightKey), tier, tostring(f.reuseBaseId)))
            content.groups = {}
        end
    else
        content.groups =
        {
            {
                mobs = f.mobs,
                allDeath = function(battlefield, mob)
                    battlefield:setStatus(xi.battlefield.status.WON)
                end,
            },
        }
    end

    -- Per-instance tier scaling of the reused base boss(es). Runs after the mobs
    -- are spawned for THIS battlefield instance, so concurrent tiers scale
    -- independently. Silent (no player-visible multiplier). int16 mod cap honored
    -- by the catalog values; HP is the int32 lever.
    function content:setupBattlefield(battlefield)
        for _, mob in ipairs(battlefield:getMobs(true, true)) do
            pcall(function()
                if scale.lvl and scale.lvl > 1.0 then
                    mob:setMobLevel(math.min(math.floor(mob:getMainLvl() * scale.lvl), 255))
                end
                if scale.hp and scale.hp > 1.0 then
                    local hp = math.floor(mob:getMaxHP() * scale.hp)
                    mob:setMaxHP(hp)
                    mob:setHP(hp)
                end
                if scale.att  and scale.att  > 0 then mob:addMod(xi.mod.ATT,  scale.att)  end
                if scale.def  and scale.def  > 0 then mob:addMod(xi.mod.DEF,  scale.def)  end
                if scale.macc and scale.macc > 0 then mob:addMod(xi.mod.MACC, scale.macc) end
                if scale.meva and scale.meva > 0 then mob:addMod(xi.mod.MEVA, scale.meva) end
            end)
        end
    end

    -- Reward on win. Placeholder gil per tier; the real retail per-fight LOOT
    -- table goes in catalog.fights[key].loot[tier] (armoury-crate mechanism) as
    -- it is sourced from bg-wiki.
    function content:onEventFinishWin(player, csid, option, npc)
        if rew and rew.gil and rew.gil > 0 then
            pcall(function() player:addGil(rew.gil) end)
        end
    end

    if f.loot and f.loot[tier] then
        content.loot = f.loot[tier]
    end

    return content:register()
end

return htbf
