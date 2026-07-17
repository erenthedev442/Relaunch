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
    -- Removed 2026-07-16: xi.mobMod.DRAW_IN does not exist in scripts/enum/mob_mod.lua,
    -- so setMobMod(nil, 0) threw "expected number, received nil" on every urchin spawn
    -- (4 urchins per instance = 4 errors per pop; 75+ in the log window). Urchins have
    -- no draw-in behavior by default anyway, so no replacement needed.
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
