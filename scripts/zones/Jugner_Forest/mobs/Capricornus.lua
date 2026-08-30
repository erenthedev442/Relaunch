-----------------------------------
-- Area: Jugner Forest
--   NM: Capricornus
-- Hunt Guild AF T2: visible 30-minute camp at !huntwarp capricornus.
-- Other-zone Capricornus copies stay Voidwalker /heal pops.
-----------------------------------
mixins = { require('scripts/mixins/job_special') }
-----------------------------------
---@type TMobEntity
local entity = {}

-- y = 0 matches the walkable Voidwalker pad next to this camp.
-- y = -5 buried the NM under the F-10 floor.
entity.spawnPoints =
{
    { x = 240.000, y = 0.000, z = 40.000 }
}

entity.onMobInitialize = function(mob)
    xi.mob.updateNMSpawnPoint(mob)
end

entity.onMobSpawn = function(mob)
    local camp = entity.spawnPoints[1]
    mob:setPos(camp.x, camp.y, camp.z)
    mob:setStatus(xi.status.UPDATE)
    mob:hideName(false)
    mob:hideHP(false)
    mob:setUntargetable(false)
end

entity.onMobFight = function(mob, target)
    xi.voidwalker.applyCombatBehavior(mob)
end

entity.onMobDespawn = function(mob)
    xi.mob.updateNMSpawnPoint(mob)
end

entity.onMobDeath = function(mob, player, optParams)
    xi.voidwalker.onMobDeath(mob, player, optParams, xi.keyItem.BLUE_ABYSSITE)
    xi.hunts.checkHunt(mob, player, 546)
    xi.magian.onMobDeath(mob, player, optParams, set{ 157, 371, 585 })
end

return entity
