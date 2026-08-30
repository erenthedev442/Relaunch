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

entity.spawnPoints =
{
    { x = 240.000, y = -5.000, z = 40.000 }
}

entity.onMobInitialize = function(mob)
    xi.mob.updateNMSpawnPoint(mob)
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
