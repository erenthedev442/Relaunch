-----------------------------------
-- Bozzetto Urchin
-- Add mob that spawns alongside the Bozzetto Breadwinner.
-- Aggressive melee, links with other Urchins, no special abilities.
-- HP scaled by difficulty in onInstanceProgressUpdate (same logic as Breadwinner).
-----------------------------------
local entity = {}

entity.onMobInitialize = function(mob)
end

entity.onMobSpawn = function(mob)
    mob:setMobMod(xi.mobMod.DRAW_IN, 0)
end

entity.onMobEngage = function(mob, target)
end

entity.onMobFight = function(mob, target)
end

entity.onMobWeaponSkill = function(mob, target, skill, action)
end

entity.onMobDeath = function(mob, player, optParams)
end

return entity
