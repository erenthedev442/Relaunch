-----------------------------------
-- Area: Rolanberry Fields (110)
--  HNM: Simurgh
-----------------------------------
mixins =
{
    require('scripts/mixins/rage'),
    require('scripts/mixins/job_special')
}
-----------------------------------
---@type TMobEntity
local entity = {}

-- Retail Simurgh is deleted; this file now owns the affinity camp only.
-- Keep it on the !affinitynm warp. The old 50-point roam table parked the
-- bird 80-100 yalms away, and setRespawnTime(1-2h) registered it with the
-- spawn handler so zone-boot TrySpawn skipped it.
entity.spawnPoints =
{
    { x = -681.000, y = -31.000, z = -447.000 },
}

entity.onMobInitialize = function(mob)
    mob:setSpawn(-681.000, -31.000, -447.000)
    mob:setMobMod(xi.mobMod.GIL_MIN, 20000)
    mob:setMobMod(xi.mobMod.GIL_MAX, 20000)
    mob:setMobMod(xi.mobMod.MUG_GIL, 2550) -- (https://ffxiclopedia.fandom.com/wiki/Simurgh)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    mob:addImmunity(xi.immunity.TERROR)
    mob:setMobMod(xi.mobMod.ALWAYS_AGGRO, 1)
end

entity.onMobSpawn = function(mob)
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, 250)
    mob:setMod(xi.mod.EVA, 400)
    mob:setMod(xi.mod.ACC, 519)
end

entity.onMobFight = function(mob, target)
    local drawInTable =
    {
        conditions =
        {
            target:checkDistance(mob) > mob:getMeleeRange(target),
        },
        position = mob:getPos(),
        offset = 5,
        degrees = 180,
        wait = 10,
    }
    utils.drawIn(target, drawInTable)
end

entity.onMobDeath = function(mob, player, optParams)
    if player then
        player:addTitle(xi.title.SIMURGH_POACHER)
    end
end

entity.onMobDespawn = function(mob)
    mob:setSpawn(-681.000, -31.000, -447.000)
    -- Affinity autopop overwrites this to 30s; keep a short fallback for tests.
    mob:setRespawnTime(30)
end

return entity
