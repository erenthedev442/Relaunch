-----------------------------------
-- Area: Sauromugue Champaign (120)
--  HNM: Roc
-----------------------------------
mixins =
{
    require('scripts/mixins/rage'),
    require('scripts/mixins/job_special')
}
-----------------------------------
---@type TMobEntity
local entity = {}

-- Retail Roc is deleted; this file now owns the affinity camp only.
-- Keep it on the !affinitynm warp. The old roam table parked the bird
-- away from 232, -0.01, -327, and setRespawnTime(1-2h) registered it
-- with the spawn handler so zone-boot TrySpawn skipped it.
entity.spawnPoints =
{
    { x = 232.000, y = -0.010, z = -327.000 },
}

entity.onMobInitialize = function(mob)
    mob:setSpawn(232.000, -0.010, -327.000)
    mob:setMobMod(xi.mobMod.GIL_MIN, 20000)
    mob:setMobMod(xi.mobMod.GIL_MAX, 20000)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    mob:addImmunity(xi.immunity.TERROR)
    mob:setMobMod(xi.mobMod.ALWAYS_AGGRO, 1)
end

entity.onMobSpawn = function(mob)
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, 250)
    mob:setMod(xi.mod.EVA, 400)
    mob:setMod(xi.mod.ATT, 325)
    mob:setMod(xi.mod.ACC, 525)
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
        player:addTitle(xi.title.ROC_STAR)
    end
end

entity.onMobDespawn = function(mob)
    mob:setSpawn(232.000, -0.010, -327.000)
    -- Affinity autopop overwrites this to 30s; keep a short fallback for tests.
    mob:setRespawnTime(30)
end

return entity
